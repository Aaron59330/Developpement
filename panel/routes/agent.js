// Appelé par la ressource FiveM « pickax_panel » (pas par le navigateur).
const router = require('express').Router(); const express = require('express'); const rateLimit = require('express-rate-limit');
const { db, now } = require('../lib/db'); const A = require('../lib/auth'); const cfg = require('../lib/config'); const bus = require('../lib/bus'); const hooks = require('../lib/hooks');
const keyOf = (req) => String(req.headers['x-license-key'] || req.ip);
const lim = rateLimit({ windowMs: 60 * 1000, limit: 90, keyGenerator: keyOf, standardHeaders: true, legacyHeaders: false, message: { ok: false, error: 'rate' } });
router.use(express.json({ limit: '8mb' }), lim);
const lic = key => db.prepare('SELECT l.*, p.name plan_name, p.max_players plan_max FROM licenses l LEFT JOIN plans p ON p.id=l.plan_id WHERE l.key=?').get(key);
function check(req, res) {
  const l = lic(String(req.headers['x-license-key'] || '')); if (!l) { res.status(403).json({ ok: false, error: 'Clé de licence inconnue' }); return null; }
  const ip = A.ip(req); const expired = !!(l.expires_at && l.expires_at < now()); const valid = l.status === 'active' && !expired;
  if (valid && l.bound_ip && l.bound_ip !== ip) { res.json({ ok: false, error: 'Licence déjà utilisée depuis une autre adresse (' + l.bound_ip + '). Délie-la depuis le panel.', license: { valid: false, status: 'ip' } }); return null; }
  if (valid && !l.bound_ip) db.prepare('UPDATE licenses SET bound_ip=? WHERE id=?').run(ip, l.id);
  db.prepare('UPDATE licenses SET last_seen=?, last_ip=? WHERE id=?').run(now(), ip, l.id);
  l._valid = valid; l._license = { valid, status: expired ? 'expired' : l.status, expires_at: l.expires_at, plan: l.plan_name, max_players: l.plan_max || 0, server_name: l.server_name };
  return l;
}
function saveResults(l, results) {
  if (!Array.isArray(results)) return;
  const up = db.prepare('UPDATE commands SET status=?, result=?, done_at=? WHERE id=? AND license_id=?');
  for (const r of results.slice(0, 100)) { const ok = !!r.ok; up.run(ok ? 'done' : 'failed', String(r.result || '').slice(0, 300), now(), +r.id, l.id); bus.deliver(+r.id, ok, r.result, r.data); }
}
function takeCommands(l) {
  const cmds = db.prepare("SELECT id,type,payload FROM commands WHERE license_id=? AND (status='pending' OR (status='sent' AND sent_at<?)) ORDER BY id LIMIT 50").all(l.id, now() - 60);
  if (cmds.length) db.prepare(`UPDATE commands SET status='sent', sent_at=? WHERE id IN (${cmds.map(() => '?').join(',')})`).run(now(), ...cmds.map(c => c.id));
  return cmds.map(c => ({ id: c.id, type: c.type, payload: JSON.parse(c.payload) }));
}
function docsFor(l, known) { const out = {}; known = known && typeof known === 'object' ? known : {}; for (const d of db.prepare('SELECT key,value,version FROM docs WHERE license_id=?').all(l.id)) if (+known[d.key] !== d.version) out[d.key] = { version: d.version, value: JSON.parse(d.value) }; return out; }

router.post('/sync', (req, res) => {
  const l = check(req, res); if (!l) return; const b = req.body || {};
  db.prepare('UPDATE licenses SET version=? WHERE id=?').run(String(b.version || '').slice(0, 20), l.id);
  if (!l._valid) return res.json({ ok: true, license: l._license, interval: 60, commands: [], docs: {} });
  const out = db.transaction(() => {
    const players = Array.isArray(b.players) ? b.players.slice(0, 1024).map(p => ({ id: +p.id || 0, name: String(p.name || '').slice(0, 60), identifier: String(p.identifier || '').slice(0, 120), job: String(p.job || '').slice(0, 40), grade: String(p.grade == null ? '' : p.grade).slice(0, 40), group: String(p.group || '').slice(0, 30), money: +p.money || 0, bank: +p.bank || 0, ping: +p.ping || 0 })) : [];
    const resources = Array.isArray(b.resources) ? b.resources.slice(0, 1500).map(r => ({ name: String(r.name || '').slice(0, 60), state: String(r.state || '').slice(0, 15) })) : null;
    const stats = b.stats && typeof b.stats === 'object' ? { uptime: +b.stats.uptime || 0, version: String(b.stats.version || '').slice(0, 40), hostname: String(b.stats.hostname || '').slice(0, 80), memory: +b.stats.memory || 0 } : {};
    db.prepare(`INSERT INTO server_state(license_id,players,max_players,resources,stats,updated_at) VALUES(?,?,?,?,?,?) ON CONFLICT(license_id) DO UPDATE SET players=excluded.players,max_players=excluded.max_players,${resources ? 'resources=excluded.resources,' : ''}stats=excluded.stats,updated_at=excluded.updated_at`)
      .run(l.id, JSON.stringify(players), +b.maxPlayers || 0, JSON.stringify(resources || []), JSON.stringify(stats), now());
    const last = db.prepare('SELECT at FROM stats_hist WHERE license_id=? ORDER BY id DESC LIMIT 1').get(l.id);
    if (!last || now() - last.at >= 300) { db.prepare('INSERT INTO stats_hist(license_id,at,players) VALUES(?,?,?)').run(l.id, now(), players.length); db.prepare('DELETE FROM stats_hist WHERE license_id=? AND at<?').run(l.id, now() - 31 * 86400); }
    const newLogs = [];
    if (Array.isArray(b.logs) && b.logs.length) { const ins = db.prepare('INSERT INTO logs(license_id,level,source,message,at) VALUES(?,?,?,?,?)'); for (const x of b.logs.slice(0, 200)) { const lv = ['info', 'warn', 'error', 'staff'].includes(x.level) ? x.level : 'info'; const o = { level: lv, source: String(x.source || '').slice(0, 40), message: String(x.message || '').slice(0, 500), at: +x.at || now() }; ins.run(l.id, o.level, o.source, o.message, o.at); newLogs.push(o); } db.prepare('DELETE FROM logs WHERE license_id=? AND id<(SELECT COALESCE(MAX(id),0)-5000 FROM logs WHERE license_id=?)').run(l.id, l.id); }
    saveResults(l, b.results);
    return { newLogs, commands: takeCommands(l), docs: docsFor(l, b.docs) };
  })();
  hooks.logs(l, out.newLogs);
  res.json({ ok: true, license: l._license, interval: cfg.agentIntervalSec, commands: out.commands, docs: out.docs });
});
// Requête longue : répond dès qu'il y a une action à exécuter (max 25 s) → éditeur de fichiers instantané
router.post('/poll', (req, res) => {
  const l = check(req, res); if (!l) return; const b = req.body || {};
  if (!l._valid) return res.json({ ok: true, license: l._license, commands: [], docs: {}, retry: 30 });
  saveResults(l, b.results);
  const answer = () => { const cmds = takeCommands(l); res.json({ ok: true, license: l._license, commands: cmds, docs: docsFor(l, b.docs) }); };
  if (db.prepare("SELECT 1 FROM commands WHERE license_id=? AND status='pending' LIMIT 1").get(l.id)) return answer();
  let done = false; const fire = () => { if (done) return; done = true; if (!res.writableEnded) answer(); };
  const cancel = bus.wait(l.id, 25000, fire); req.on('close', () => { done = true; cancel(); });
});
module.exports = router;
