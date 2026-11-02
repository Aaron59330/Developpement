const router = require('express').Router();
const { db, now, audit, genKey } = require('../lib/db'); const A = require('../lib/auth'); const C = require('../lib/commands'); const cfg = require('../lib/config');
router.use(A.needUser);
const ONLINE = 3 * cfg.agentIntervalSec + 5;
const { own } = require('../lib/access'); const bus = require('../lib/bus');
const view = l => { const st = db.prepare('SELECT * FROM server_state WHERE license_id=?').get(l.id); const pl = st ? JSON.parse(st.players) : [];
  return { id: l.id, key: l.key, server_name: l.server_name, status: l.status, expired: !!(l.expires_at && l.expires_at < now()), expires_at: l.expires_at, plan: l.plan_name, owner: l.owner, version: l.version, bound_ip: l.bound_ip, last_ip: l.last_ip, last_seen: l.last_seen,
    online: !!(l.last_seen && now() - l.last_seen < ONLINE), players: pl.length, max_players: st ? st.max_players : 0, stats: st ? JSON.parse(st.stats) : {}, updated_at: st && st.updated_at }; };
router.get('/', (req, res) => { const rows = db.prepare(`SELECT l.*, p.name plan_name, u.email owner FROM licenses l LEFT JOIN plans p ON p.id=l.plan_id LEFT JOIN users u ON u.id=l.user_id WHERE l.user_id=? ORDER BY l.id`).all(req.user.id); res.json({ ok: true, servers: rows.map(view) }); });
router.get('/:id', (req, res) => { const l = own(req, res); if (l) res.json({ ok: true, server: view(l) }); });
router.post('/:id/rename', (req, res) => { const l = own(req, res); if (!l) return; const n = String((req.body || {}).server_name || '').trim(); if (n.length < 2 || n.length > 60) return res.json({ ok: false, error: 'Nom : 2 à 60 caractères' }); db.prepare('UPDATE licenses SET server_name=? WHERE id=?').run(n, l.id); audit(req.user.id, l.id, 'rename', n, A.ip(req)); res.json({ ok: true }); });
router.post('/:id/rotate-key', (req, res) => { const l = own(req, res); if (!l) return; const k = genKey(); db.prepare('UPDATE licenses SET key=?, bound_ip=NULL WHERE id=?').run(k, l.id); audit(req.user.id, l.id, 'rotate-key', '', A.ip(req)); res.json({ ok: true, key: k }); });
router.post('/:id/unbind', (req, res) => { const l = own(req, res); if (!l) return; db.prepare('UPDATE licenses SET bound_ip=NULL WHERE id=?').run(l.id); audit(req.user.id, l.id, 'unbind', '', A.ip(req)); res.json({ ok: true }); });
router.get('/:id/players', (req, res) => { const l = own(req, res); if (!l) return; const st = db.prepare('SELECT * FROM server_state WHERE license_id=?').get(l.id); res.json({ ok: true, players: st ? JSON.parse(st.players) : [], updated_at: st && st.updated_at }); });
router.get('/:id/resources', (req, res) => { const l = own(req, res); if (!l) return; const st = db.prepare('SELECT resources FROM server_state WHERE license_id=?').get(l.id); res.json({ ok: true, resources: st ? JSON.parse(st.resources) : [] }); });
router.get('/:id/logs', (req, res) => { const l = own(req, res); if (!l) return; const after = +req.query.after || 0; const lv = ['info', 'warn', 'error', 'staff'].includes(req.query.level) ? req.query.level : null;
  const rows = lv ? db.prepare('SELECT id,level,source,message,at FROM logs WHERE license_id=? AND id>? AND level=? ORDER BY id DESC LIMIT 300').all(l.id, after, lv) : db.prepare('SELECT id,level,source,message,at FROM logs WHERE license_id=? AND id>? ORDER BY id DESC LIMIT 300').all(l.id, after); res.json({ ok: true, logs: rows.reverse() }); });
router.get('/:id/stats', (req, res) => { const l = own(req, res); if (!l) return; const h = Math.min(168, +req.query.hours || 24); res.json({ ok: true, points: db.prepare('SELECT at, players FROM stats_hist WHERE license_id=? AND at>? ORDER BY at').all(l.id, now() - h * 3600) }); });
router.get('/:id/commands', (req, res) => { const l = own(req, res); if (!l) return; res.json({ ok: true, commands: db.prepare('SELECT c.id,c.type,c.payload,c.status,c.result,c.created_at,c.done_at,u.username AS by_name FROM commands c LEFT JOIN users u ON u.id=c.by_user WHERE c.license_id=? ORDER BY c.id DESC LIMIT 60').all(l.id) }); });
router.post('/:id/command', (req, res) => {
  const l = own(req, res); if (!l) return;
  if (l.status !== 'active' || (l.expires_at && l.expires_at < now())) return res.json({ ok: false, error: 'Licence inactive ou expirée' });
  const { type, payload } = req.body || {}; const v = C.validate(type, payload); if (v.error) return res.json({ ok: false, error: v.error });
  const pending = db.prepare("SELECT COUNT(*) n FROM commands WHERE license_id=? AND status='pending'").get(l.id).n; if (pending > 100) return res.json({ ok: false, error: 'Trop de commandes en attente (serveur hors ligne ?)' });
  const id = db.prepare('INSERT INTO commands(license_id,type,payload,created_at,by_user) VALUES(?,?,?,?,?)').run(l.id, type, JSON.stringify(v.payload), now(), req.user.id).lastInsertRowid;
  syncLists(l.id, type, v.payload); bus.wake(l.id);
  audit(req.user.id, l.id, 'cmd:' + type, JSON.stringify(v.payload), A.ip(req)); res.json({ ok: true, id });
});
// bans / whitelist : le panel garde la liste à jour (le serveur la reçoit aussi comme document)
function setDoc(lid, key, value) { db.prepare('INSERT INTO docs(license_id,key,value,version,updated_at) VALUES(?,?,?,?,?) ON CONFLICT(license_id,key) DO UPDATE SET value=excluded.value, version=docs.version+1, updated_at=excluded.updated_at').run(lid, key, JSON.stringify(value), 1, now()); }
function getDoc(lid, key, def) { const d = db.prepare('SELECT value FROM docs WHERE license_id=? AND key=?').get(lid, key); return d ? JSON.parse(d.value) : def; }
function syncLists(lid, type, p) {
  if (type === 'ban') {
    let ident = p.identifier, name = p.name || '';
    if (p.id) { const st = db.prepare('SELECT players FROM server_state WHERE license_id=?').get(lid); const pl = st ? JSON.parse(st.players).find(x => x.id === p.id) : null; if (pl) { ident = pl.identifier || ident; name = pl.name || name; } }
    if (!ident) return;
    const list = getDoc(lid, 'bans', []).filter(b => b.identifier !== ident); list.push({ identifier: ident, name, reason: p.reason, until: p.days ? now() + p.days * 86400 : 0, at: now() }); setDoc(lid, 'bans', list);
  } else if (type === 'unban') setDoc(lid, 'bans', getDoc(lid, 'bans', []).filter(b => b.identifier !== p.identifier));
  else if (type === 'whitelist_add') { const w = getDoc(lid, 'whitelist', []); if (!w.includes(p.identifier)) { w.push(p.identifier); setDoc(lid, 'whitelist', w); } }
  else if (type === 'whitelist_remove') setDoc(lid, 'whitelist', getDoc(lid, 'whitelist', []).filter(x => x !== p.identifier));
}
router.get('/:id/docs/:key', (req, res) => { const l = own(req, res); if (!l) return; if (!C.DOC_KEYS[req.params.key]) return res.json({ ok: false, error: 'Document inconnu' }); const d = db.prepare('SELECT value,version,updated_at FROM docs WHERE license_id=? AND key=?').get(l.id, req.params.key); res.json({ ok: true, value: d ? JSON.parse(d.value) : null, version: d ? d.version : 0, updated_at: d && d.updated_at }); });
router.put('/:id/docs/:key', (req, res) => {
  const l = own(req, res); if (!l) return; const v = C.validateDoc(req.params.key, (req.body || {}).value); if (!v || v.error) return res.json({ ok: false, error: (v && v.error) || 'Invalide' });
  db.prepare('INSERT INTO docs(license_id,key,value,version,updated_at) VALUES(?,?,?,?,?) ON CONFLICT(license_id,key) DO UPDATE SET value=excluded.value, version=docs.version+1, updated_at=excluded.updated_at').run(l.id, req.params.key, JSON.stringify(v.value), 1, now());
  audit(req.user.id, l.id, 'doc:' + req.params.key, '', A.ip(req)); res.json({ ok: true, version: db.prepare('SELECT version FROM docs WHERE license_id=? AND key=?').get(l.id, req.params.key).version });
});
module.exports = router;
