const router = require('express').Router(); const rateLimit = require('express-rate-limit');
const { db, now, audit, genKey } = require('../lib/db'); const A = require('../lib/auth'); const cfg = require('../lib/config');
const lim = rateLimit({ windowMs: 15 * 60 * 1000, limit: 20, standardHeaders: true, legacyHeaders: false, message: { ok: false, error: 'Trop de tentatives, réessaie dans 15 minutes' } });
const okMail = s => typeof s === 'string' && s.length <= 120 && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s);
const okPass = s => typeof s === 'string' && s.length >= 8 && s.length <= 100;
router.get('/config', (req, res) => res.json({ ok: true, allowRegister: cfg.allowRegister, trialDays: cfg.trialDays, publicUrl: cfg.publicUrl }));
router.post('/register', lim, (req, res) => {
  if (!cfg.allowRegister) return res.status(403).json({ ok: false, error: 'Les inscriptions sont fermées' });
  const { email, username, password } = req.body || {};
  if (!okMail(email)) return res.json({ ok: false, error: 'E-mail invalide' });
  if (typeof username !== 'string' || username.trim().length < 2 || username.length > 32) return res.json({ ok: false, error: 'Pseudo : 2 à 32 caractères' });
  if (!okPass(password)) return res.json({ ok: false, error: 'Mot de passe : 8 caractères minimum' });
  if (db.prepare('SELECT 1 FROM users WHERE email=?').get(email.toLowerCase())) return res.json({ ok: false, error: 'Cet e-mail est déjà utilisé' });
  const id = db.prepare('INSERT INTO users(email,username,pass_hash,role,created_at) VALUES(?,?,?,?,?)').run(email.toLowerCase(), username.trim(), A.hash(password), 'client', now()).lastInsertRowid;
  if (cfg.trialDays > 0) {
    const plan = db.prepare("SELECT id FROM plans WHERE name='Essai'").get();
    db.prepare('INSERT INTO licenses(key,user_id,plan_id,server_name,status,expires_at,created_at) VALUES(?,?,?,?,?,?,?)').run(genKey(), id, plan && plan.id, 'Mon serveur (essai)', 'active', now() + cfg.trialDays * 86400, now());
  }
  audit(id, null, 'register', email, A.ip(req));
  A.startSession(req, res, { id }); res.json({ ok: true });
});
router.post('/login', lim, (req, res) => {
  const { email, password } = req.body || {};
  const u = typeof email === 'string' ? db.prepare('SELECT * FROM users WHERE email=?').get(email.toLowerCase()) : null;
  if (!u || typeof password !== 'string' || !A.check(password, u.pass_hash)) return res.json({ ok: false, error: 'E-mail ou mot de passe incorrect' });
  if (u.disabled) return res.json({ ok: false, error: 'Compte désactivé' });
  A.startSession(req, res, u); audit(u.id, null, 'login', '', A.ip(req)); res.json({ ok: true });
});
router.post('/logout', (req, res) => { if (req.sid) db.prepare('DELETE FROM sessions WHERE token=?').run(req.sid); res.clearCookie(A.COOKIE); res.json({ ok: true }); });
router.get('/me', (req, res) => req.user ? res.json({ ok: true, user: A.publicUser(req.user) }) : res.json({ ok: false }));
router.put('/prefs', A.needUser, (req, res) => {
  const patch = A.cleanPrefs(req.body); if (!patch) return res.json({ ok: false, error: 'Préférence invalide' });
  res.json({ ok: true, prefs: A.setPrefs(req.user.id, patch) });
});
router.post('/password', A.needUser, lim, (req, res) => {
  const { current, next } = req.body || {};
  if (!A.check(String(current || ''), req.user.pass_hash)) return res.json({ ok: false, error: 'Mot de passe actuel incorrect' });
  if (!okPass(next)) return res.json({ ok: false, error: 'Nouveau mot de passe : 8 caractères minimum' });
  db.prepare('UPDATE users SET pass_hash=? WHERE id=?').run(A.hash(next), req.user.id);
  db.prepare('DELETE FROM sessions WHERE user_id=? AND token<>?').run(req.user.id, req.sid);
  audit(req.user.id, null, 'password', '', A.ip(req)); res.json({ ok: true });
});
module.exports = router;
