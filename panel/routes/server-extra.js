// Stats détaillées, webhooks Discord, Drive, modules, sauvegardes, journal d'activité du serveur
const router = require('express').Router(); const crypto = require('crypto'), fs = require('fs'), path = require('path');
const { db, now, audit } = require('../lib/db'); const A = require('../lib/auth'); const C = require('../lib/commands'); const bus = require('../lib/bus'); const cfg = require('../lib/config'); const hooks = require('../lib/hooks');
const { own, active } = require('../lib/access');
router.use(A.needUser);
const queue = (l, uid, type, payload) => { const id = db.prepare('INSERT INTO commands(license_id,type,payload,created_at,by_user) VALUES(?,?,?,?,?)').run(l.id, type, JSON.stringify(payload), now(), uid).lastInsertRowid; bus.wake(l.id); return id; };

// ───────── statistiques ─────────
router.get('/:id/stats-summary', (req, res) => {
  const l = own(req, res); if (!l) return; const days = Math.min(30, Math.max(1, +req.query.days || 7));
  const pts = db.prepare('SELECT at, players FROM stats_hist WHERE license_id=? AND at>? ORDER BY at').all(l.id, now() - days * 86400);
  const peak = pts.reduce((m, p) => Math.max(m, p.players), 0), avg = pts.length ? Math.round(pts.reduce((s, p) => s + p.players, 0) / pts.length * 10) / 10 : 0;
  const st = db.prepare('SELECT players FROM server_state WHERE license_id=?').get(l.id); const pl = st ? JSON.parse(st.players) : [];
  const jobs = {}; for (const p of pl) jobs[p.job || '—'] = (jobs[p.job || '—'] || 0) + 1;
  const byHour = Array(24).fill(0), cnt = Array(24).fill(0); for (const p of pts) { const h = new Date(p.at * 1000).getHours(); byHour[h] += p.players; cnt[h]++; }
  res.json({ ok: true, points: pts, peak, avg, jobs: Object.entries(jobs).sort((a, b) => b[1] - a[1]).slice(0, 10), hours: byHour.map((v, i) => cnt[i] ? Math.round(v / cnt[i] * 10) / 10 : 0), total_money: pl.reduce((s, p) => s + p.money + p.bank, 0), count: pl.length });
});
router.get('/:id/activity', (req, res) => { const l = own(req, res); if (!l) return; res.json({ ok: true, rows: db.prepare('SELECT a.id,a.action,a.detail,a.at,u.username FROM audit a LEFT JOIN users u ON u.id=a.user_id WHERE a.license_id=? ORDER BY a.id DESC LIMIT 100').all(l.id) }); });

// ───────── console ─────────
router.post('/:id/console', (req, res) => {
  const l = own(req, res); if (!l) return; if (!active(l)) return res.json({ ok: false, error: 'Licence inactive ou expirée' }); const v = C.validate('console', req.body); if (v.error) return res.json({ ok: false, error: v.error });
  const id = queue(l, req.user.id, 'console', v.payload); audit(req.user.id, l.id, 'console', v.payload.cmd, A.ip(req)); res.json({ ok: true, id });
});
router.post('/:id/power', (req, res) => {
  const l = own(req, res); if (!l) return; if (!active(l)) return res.json({ ok: false, error: 'Licence inactive ou expirée' }); const t = (req.body || {}).action === 'stop' ? 'server_stop' : 'server_restart';
  queue(l, req.user.id, t, {}); audit(req.user.id, l.id, t, '', A.ip(req)); res.json({ ok: true });
});

// ───────── webhooks Discord ─────────
router.get('/:id/webhooks', (req, res) => { const l = own(req, res); if (!l) return; res.json({ ok: true, events: hooks.EVENTS, hooks: Object.fromEntries(db.prepare('SELECT event,url FROM webhooks WHERE license_id=?').all(l.id).map(h => [h.event, h.url])) }); });
router.put('/:id/webhooks', (req, res) => {
  const l = own(req, res); if (!l) return; const b = req.body || {};
  for (const ev of hooks.EVENTS) { const u = String(b[ev] || '').trim(); if (u && !hooks.okUrl(u)) return res.json({ ok: false, error: 'Lien de webhook Discord invalide pour « ' + ev + ' »' }); }
  for (const ev of hooks.EVENTS) { const u = String(b[ev] || '').trim(); if (u) db.prepare('INSERT INTO webhooks(license_id,event,url) VALUES(?,?,?) ON CONFLICT(license_id,event) DO UPDATE SET url=excluded.url').run(l.id, ev, u); else db.prepare('DELETE FROM webhooks WHERE license_id=? AND event=?').run(l.id, ev); }
  audit(req.user.id, l.id, 'webhooks', '', A.ip(req)); res.json({ ok: true });
});
router.post('/:id/webhooks/test', async (req, res) => {
  const l = own(req, res); if (!l) return; const u = String((req.body || {}).url || ''); if (!hooks.okUrl(u)) return res.json({ ok: false, error: 'Lien invalide' });
  try { const r = await fetch(u, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ username: 'AERO Panel', content: 'Test du webhook depuis le panel ✅' }), signal: AbortSignal.timeout(6000) }); res.json({ ok: r.ok, error: r.ok ? undefined : 'Discord a refusé (HTTP ' + r.status + ')' }); } catch (e) { res.json({ ok: false, error: 'Discord injoignable' }); }
});

// ───────── Drive (images hébergées, utilisables comme logo) ─────────
const MIME = { 'image/png': 'png', 'image/jpeg': 'jpg', 'image/webp': 'webp', 'image/gif': 'gif', 'image/svg+xml': 'svg' };
const driveDir = () => { const d = path.join(cfg.dataDir, 'drive'); fs.mkdirSync(d, { recursive: true }); return d; };
router.get('/:id/drive', (req, res) => { const l = own(req, res); if (!l) return; res.json({ ok: true, files: db.prepare('SELECT id,token,name,mime,size,at FROM drive WHERE license_id=? ORDER BY id DESC').all(l.id).map(f => ({ ...f, url: cfg.publicUrl ? `${cfg.publicUrl}/drive/${f.token}` : `${req.protocol}://${req.get('host')}/drive/${f.token}` })) }); });
router.post('/:id/drive', (req, res) => {
  const l = own(req, res); if (!l) return; const b = req.body || {}; const mime = String(b.mime || ''); if (!MIME[mime]) return res.json({ ok: false, error: 'Formats acceptés : PNG, JPG, WEBP, GIF, SVG' });
  const buf = Buffer.from(String(b.data || ''), 'base64'); if (!buf.length || buf.length > 1500000) return res.json({ ok: false, error: 'Fichier vide ou supérieur à 1,5 Mo' });
  const used = db.prepare('SELECT COALESCE(SUM(size),0) n FROM drive WHERE license_id=?').get(l.id).n; if (used + buf.length > 20 * 1024 * 1024) return res.json({ ok: false, error: 'Drive plein (20 Mo)' });
  if (mime === 'image/svg+xml' && /<script|onload=|onerror=|javascript:/i.test(buf.toString('utf8'))) return res.json({ ok: false, error: 'SVG refusé (contenu actif)' });
  const token = crypto.randomBytes(16).toString('hex'); fs.writeFileSync(path.join(driveDir(), token), buf);
  const name = String(b.name || 'image').replace(/[^\w.\- ]/g, '').slice(0, 60) || 'image'; db.prepare('INSERT INTO drive(license_id,token,name,mime,size,at) VALUES(?,?,?,?,?,?)').run(l.id, token, name, mime, buf.length, now());
  audit(req.user.id, l.id, 'drive:upload', name, A.ip(req)); res.json({ ok: true, token });
});
router.delete('/:id/drive/:fid', (req, res) => { const l = own(req, res); if (!l) return; const f = db.prepare('SELECT * FROM drive WHERE id=? AND license_id=?').get(+req.params.fid, l.id); if (!f) return res.json({ ok: false, error: 'Introuvable' }); try { fs.unlinkSync(path.join(driveDir(), f.token)); } catch (e) {} db.prepare('DELETE FROM drive WHERE id=?').run(f.id); res.json({ ok: true }); });

// ───────── modules (catalogue admin, activation par le client) ─────────
router.get('/:id/modules', (req, res) => {
  const l = own(req, res); if (!l) return; const st = db.prepare('SELECT resources FROM server_state WHERE license_id=?').get(l.id); const rs = Object.fromEntries((st ? JSON.parse(st.resources) : []).map(r => [r.name, r.state]));
  const mine = Object.fromEntries(db.prepare('SELECT module_id,enabled FROM license_modules WHERE license_id=?').all(l.id).map(m => [m.module_id, m.enabled]));
  res.json({ ok: true, modules: db.prepare('SELECT * FROM modules WHERE active=1 ORDER BY price,name').all().map(m => { const r = JSON.parse(m.resources); return { id: m.id, name: m.name, description: m.description, price: m.price, resources: r, owned: m.price === 0 || m.id in mine, enabled: r.length > 0 && r.every(x => rs[x] === 'started'), known: r.some(x => x in rs) }; }) });
});
router.post('/:id/modules/:mid/toggle', (req, res) => {
  const l = own(req, res); if (!l) return; if (!active(l)) return res.json({ ok: false, error: 'Licence inactive ou expirée' }); const m = db.prepare('SELECT * FROM modules WHERE id=? AND active=1').get(+req.params.mid); if (!m) return res.json({ ok: false, error: 'Module introuvable' });
  if (m.price > 0 && !db.prepare('SELECT 1 FROM license_modules WHERE license_id=? AND module_id=?').get(l.id, m.id)) return res.json({ ok: false, error: 'Module non acquis : demande-le depuis la Boutique' });
  const on = !!(req.body || {}).enabled; for (const r of JSON.parse(m.resources)) queue(l, req.user.id, on ? 'resource_start' : 'resource_stop', { resource: r });
  audit(req.user.id, l.id, 'module:' + (on ? 'on' : 'off'), m.name, A.ip(req)); res.json({ ok: true });
});
router.post('/:id/modules/:mid/request', (req, res) => {
  const l = own(req, res); if (!l) return; const m = db.prepare('SELECT * FROM modules WHERE id=?').get(+req.params.mid); if (!m) return res.json({ ok: false, error: 'Module introuvable' });
  const t = db.prepare('INSERT INTO tickets(user_id,license_id,subject,status,created_at,updated_at) VALUES(?,?,?,?,?,?)').run(req.user.id, l.id, 'Demande du module « ' + m.name + ' »', 'open', now(), now()).lastInsertRowid;
  db.prepare('INSERT INTO ticket_msgs(ticket_id,user_id,staff,body,at) VALUES(?,?,?,?,?)').run(t, req.user.id, 0, `Je souhaite obtenir le module « ${m.name} » (${m.price} €) pour mon serveur « ${l.server_name} ».`, now()); res.json({ ok: true, ticket: t });
});

// ───────── sauvegardes (documents + fichiers modifiés via le panel) ─────────
router.get('/:id/backups', (req, res) => { const l = own(req, res); if (!l) return; res.json({ ok: true, backups: db.prepare('SELECT b.id,b.name,b.size,b.at,u.username by_name FROM backups b LEFT JOIN users u ON u.id=b.by_user WHERE b.license_id=? ORDER BY b.id DESC LIMIT 30').all(l.id) }); });
router.post('/:id/backups', (req, res) => {
  const l = own(req, res); if (!l) return; const name = String((req.body || {}).name || '').trim().slice(0, 60) || 'Sauvegarde du ' + new Date().toLocaleString('fr-FR');
  const files = {}; for (const f of db.prepare('SELECT DISTINCT path FROM file_versions WHERE license_id=?').all(l.id)) { const v = db.prepare('SELECT content FROM file_versions WHERE license_id=? AND path=? ORDER BY id DESC LIMIT 1').get(l.id, f.path); files[f.path] = v.content; }
  const docs = {}; for (const d of db.prepare('SELECT key,value FROM docs WHERE license_id=?').all(l.id)) docs[d.key] = JSON.parse(d.value);
  const data = JSON.stringify({ files, docs }); if (data.length > 8 * 1024 * 1024) return res.json({ ok: false, error: 'Sauvegarde trop volumineuse' });
  db.prepare('DELETE FROM backups WHERE license_id=? AND id NOT IN (SELECT id FROM backups WHERE license_id=? ORDER BY id DESC LIMIT 19)').run(l.id, l.id);
  db.prepare('INSERT INTO backups(license_id,name,data,size,at,by_user) VALUES(?,?,?,?,?,?)').run(l.id, name, data, data.length, now(), req.user.id); audit(req.user.id, l.id, 'backup:create', name, A.ip(req)); res.json({ ok: true, files: Object.keys(files).length, docs: Object.keys(docs).length });
});
router.post('/:id/backups/:bid/restore', async (req, res) => {
  const l = own(req, res); if (!l) return; if (!active(l)) return res.json({ ok: false, error: 'Licence inactive ou expirée' }); const b = db.prepare('SELECT * FROM backups WHERE id=? AND license_id=?').get(+req.params.bid, l.id); if (!b) return res.json({ ok: false, error: 'Sauvegarde introuvable' });
  const d = JSON.parse(b.data); let ok = 0, fail = [];
  for (const [p, content] of Object.entries(d.files || {})) { const v = C.validateRpc('fs.write', { path: p, content }); if (v.error) { fail.push(p); continue; } const r = await bus.rpc(l.id, 'fs.write', v.payload, req.user.id, 20000); if (r.ok) { ok++; const prev = db.prepare('SELECT content FROM file_versions WHERE license_id=? AND path=? ORDER BY id DESC LIMIT 1').get(l.id, p); if (!prev || prev.content !== content) db.prepare('INSERT INTO file_versions(license_id,path,content,size,note,by_user,at) VALUES(?,?,?,?,?,?,?)').run(l.id, p, content, Buffer.byteLength(content), 'Restauration : ' + b.name, req.user.id, now()); } else fail.push(p); }
  for (const [k, val] of Object.entries(d.docs || {})) { const v = C.validateDoc(k, val); if (v && !v.error) db.prepare('INSERT INTO docs(license_id,key,value,version,updated_at) VALUES(?,?,?,?,?) ON CONFLICT(license_id,key) DO UPDATE SET value=excluded.value, version=docs.version+1, updated_at=excluded.updated_at').run(l.id, k, JSON.stringify(v.value), 1, now()); }
  audit(req.user.id, l.id, 'backup:restore', b.name, A.ip(req)); res.json({ ok: fail.length === 0, restored: ok, failed: fail, error: fail.length ? 'Fichiers non restaurés : ' + fail.join(', ') : undefined });
});
router.delete('/:id/backups/:bid', (req, res) => { const l = own(req, res); if (!l) return; db.prepare('DELETE FROM backups WHERE id=? AND license_id=?').run(+req.params.bid, l.id); res.json({ ok: true }); });
module.exports = router;
