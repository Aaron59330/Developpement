const crypto = require('crypto'), bcrypt = require('bcryptjs');
const { db, now } = require('./db'); const cfg = require('./config');
const COOKIE = 'aero_sid';
function ip(req) { return (req.ip || '').replace('::ffff:', ''); }
function startSession(req, res, user) {
  const token = crypto.randomBytes(32).toString('hex');
  db.prepare('INSERT INTO sessions(token,user_id,expires_at,ip,ua) VALUES(?,?,?,?,?)').run(token, user.id, now() + cfg.sessionDays * 86400, ip(req), String(req.headers['user-agent'] || '').slice(0, 200));
  db.prepare('UPDATE users SET last_login=? WHERE id=?').run(now(), user.id);
  res.cookie(COOKIE, token, { httpOnly: true, sameSite: 'lax', secure: req.secure, maxAge: cfg.sessionDays * 86400 * 1000, path: '/' });
}
function loadUser(req, _res, next) {
  const t = req.cookies && req.cookies[COOKIE];
  if (t) {
    const row = db.prepare('SELECT u.*, s.expires_at se FROM sessions s JOIN users u ON u.id=s.user_id WHERE s.token=?').get(t);
    if (row && row.se > now() && !row.disabled) { req.user = row; req.sid = t; }
  }
  next();
}
const needUser = (req, res, next) => req.user ? next() : res.status(401).json({ ok: false, error: 'Connexion requise' });
const needAdmin = (req, res, next) => req.user && req.user.role === 'admin' ? next() : res.status(403).json({ ok: false, error: 'Accès administrateur requis' });
// Protection CSRF : les requêtes qui modifient doivent venir du même site (Origin/Referer) et être en JSON
function csrf(req, res, next) {
  if (['GET', 'HEAD', 'OPTIONS'].includes(req.method) || req.path.startsWith('/api/agent/')) return next();
  const o = req.headers.origin || req.headers.referer;
  if (o) { try { if (new URL(o).host !== req.headers.host) return res.status(403).json({ ok: false, error: 'Origine refusée' }); } catch (e) { return res.status(403).json({ ok: false, error: 'Origine refusée' }); } }
  if (!req.is('application/json')) return res.status(415).json({ ok: false, error: 'JSON requis' });
  next();
}
// préférences d'affichage du panel (design, thème, couleur principale), propres à chaque compte
const DEFAULT_PREFS = { design: 'hub', theme: 'sombre', accent: null };
function getPrefs(uid) { try { const r = db.prepare('SELECT value FROM settings WHERE key=?').get('uprefs:' + uid); return { ...DEFAULT_PREFS, ...(r ? JSON.parse(r.value) : {}) }; } catch (e) { return { ...DEFAULT_PREFS }; } }
function cleanPrefs(b) {
  b = b || {}; const out = {};
  if (b.design !== undefined) { if (!['v1', 'v2', 'hub'].includes(b.design)) return null; out.design = b.design; }
  if (b.theme !== undefined) { if (!['sombre', 'clair'].includes(b.theme)) return null; out.theme = b.theme; }
  if (b.accent !== undefined) { if (b.accent !== null && !/^#[0-9a-fA-F]{6}$/.test(b.accent)) return null; out.accent = b.accent ? b.accent.toLowerCase() : null; }
  return out;
}
function setPrefs(uid, patch) { const next = { ...getPrefs(uid), ...patch }; db.prepare('INSERT INTO settings(key,value) VALUES(?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value').run('uprefs:' + uid, JSON.stringify(next)); return next; }
const publicUser = u => ({ id: u.id, email: u.email, username: u.username, role: u.role, created_at: u.created_at, prefs: getPrefs(u.id) });
module.exports = { getPrefs, setPrefs, cleanPrefs, COOKIE, startSession, loadUser, needUser, needAdmin, csrf, publicUser, ip, hash: p => bcrypt.hashSync(p, 11), check: (p, h) => bcrypt.compareSync(p, h) };
