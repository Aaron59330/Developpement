// Appelé par la ressource FiveM « pickax_panel » (pas par le navigateur).
const router = require('express').Router(); const rateLimit = require('express-rate-limit');
const { db, now } = require('../lib/db'); const A = require('../lib/auth'); const cfg = require('../lib/config');
const lim = rateLimit({ windowMs: 60 * 1000, limit: 30, keyGenerator: (req) => String(req.headers['x-license-key'] || req.ip), standardHeaders: true, legacyHeaders: false, message: { ok: false, error: 'rate' } });
router.post('/sync', lim, (req, res) => {
  const key = String(req.headers['x-license-key'] || ''); const l = db.prepare('SELECT l.*, p.name plan_name, p.max_players plan_max FROM licenses l LEFT JOIN plans p ON p.id=l.plan_id WHERE l.key=?').get(key);
  if (!l) return res.status(403).json({ ok: false, error: 'Clé de licence inconnue' });
  const ip = A.ip(req); const b = req.body || {};
  const expired = !!(l.expires_at && l.expires_at < now()); const valid = l.status === 'active' && !expired;
  // une licence = un serveur : la 1re IP qui se connecte est liée (le client peut délier depuis le panel)
  if (valid && l.bound_ip && l.bound_ip !== ip) return res.json({ ok: false, error: 'Licence déjà utilisée depuis une autre adresse (' + l.bound_ip + '). Délie-la depuis le panel.', license: { valid: false, status: 'ip' } });
  if (valid && !l.bound_ip) db.prepare('UPDATE licenses SET bound_ip=? WHERE id=?').run(ip, l.id);
  db.prepare('UPDATE licenses SET last_seen=?, last_ip=?, version=? WHERE id=?').run(now(), ip, String(b.version || '').slice(0, 20), l.id);
  const license = { valid, status: expired ? 'expired' : l.status, expires_at: l.expires_at, plan: l.plan_name, max_players: l.plan_max || 0, server_name: l.server_name };
  if (!valid) return res.json({ ok: true, license, interval: 60, commands: [], docs: {} });
  const out = db.transaction(() => {
    const players = Array.isArray(b.players) ? b.players.slice(0, 1024).map(p => ({ id: +p.id || 0, name: String(p.name || '').slice(0, 60), identifier: String(p.identifier || '').slice(0, 120), job: String(p.job || '').slice(0, 40), grade: String(p.grade == null ? '' : p.grade).slice(0, 40), group: String(p.group || '').slice(0, 30), money: +p.money || 0, bank: +p.bank || 0, ping: +p.ping || 0 })) : [];
    const resources = Array.isArray(b.resources) ? b.resources.slice(0, 1500).map(r => ({ name: String(r.name || '').slice(0, 60), state: String(r.state || '').slice(0, 15) })) : null;
    const stats = b.stats && typeof b.stats === 'object' ? { uptime: +b.stats.uptime || 0, version: String(b.stats.version || '').slice(0, 40), hostname: String(b.stats.hostname || '').slice(0, 80), memory: +b.stats.memory || 0 } : {};
    db.prepare(`INSERT INTO server_state(license_id,players,max_players,resources,stats,updated_at) VALUES(?,?,?,?,?,?) ON CONFLICT(license_id) DO UPDATE SET players=excluded.players,max_players=excluded.max_players,${resources ? 'resources=excluded.resources,' : ''}stats=excluded.stats,updated_at=excluded.updated_at`)
      .run(l.id, JSON.stringify(players), +b.maxPlayers || 0, JSON.stringify(resources || []), JSON.stringify(stats), now());
    const last = db.prepare('SELECT at FROM stats_hist WHERE license_id=? ORDER BY id DESC LIMIT 1').get(l.id);
    if (!last || now() - last.at >= 300) { db.prepare('INSERT INTO stats_hist(license_id,at,players) VALUES(?,?,?)').run(l.id, now(), players.length); db.prepare('DELETE FROM stats_hist WHERE license_id=? AND at<?').run(l.id, now() - 8 * 86400); }
    if (Array.isArray(b.logs) && b.logs.length) { const ins = db.prepare('INSERT INTO logs(license_id,level,source,message,at) VALUES(?,?,?,?,?)'); for (const x of b.logs.slice(0, 200)) ins.run(l.id, ['info', 'warn', 'error', 'staff'].includes(x.level) ? x.level : 'info', String(x.source || '').slice(0, 40), String(x.message || '').slice(0, 500), +x.at || now()); db.prepare('DELETE FROM logs WHERE license_id=? AND id<(SELECT COALESCE(MAX(id),0)-5000 FROM logs WHERE license_id=?)').run(l.id, l.id); }
    if (Array.isArray(b.results)) { const up = db.prepare('UPDATE commands SET status=?, result=?, done_at=? WHERE id=? AND license_id=?'); for (const r of b.results.slice(0, 100)) up.run(r.ok ? 'done' : 'failed', String(r.result || '').slice(0, 300), now(), +r.id, l.id); }
    const cmds = db.prepare("SELECT id,type,payload FROM commands WHERE license_id=? AND (status='pending' OR (status='sent' AND sent_at<?)) ORDER BY id LIMIT 50").all(l.id, now() - 60);
    if (cmds.length) db.prepare(`UPDATE commands SET status='sent', sent_at=? WHERE id IN (${cmds.map(() => '?').join(',')})`).run(now(), ...cmds.map(c => c.id));
    const known = b.docs && typeof b.docs === 'object' ? b.docs : {}; const docs = {};
    for (const d of db.prepare('SELECT key,value,version FROM docs WHERE license_id=?').all(l.id)) if (+known[d.key] !== d.version) docs[d.key] = { version: d.version, value: JSON.parse(d.value) };
    return { commands: cmds.map(c => ({ id: c.id, type: c.type, payload: JSON.parse(c.payload) })), docs };
  })();
  res.json({ ok: true, license, interval: cfg.agentIntervalSec, ...out });
});
module.exports = router;
