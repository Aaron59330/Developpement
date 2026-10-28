// Page publique d'inscription à un événement (lien publié dans Discord) : sans compte, protégée par limite de débit
const router = require('express').Router(); const { db, now } = require('../lib/db'); const A = require('../lib/auth');
const hits = new Map();
const limited = ip => { const t = Date.now(), a = (hits.get(ip) || []).filter(x => t - x < 60000); a.push(t); hits.set(ip, a); if (hits.size > 5000) hits.clear(); return a.length > 6; };
const view = e => { const n = db.prepare('SELECT COUNT(*) n FROM dc_signups WHERE event_id=?').get(e.id).n; return { title: e.title, description: e.description, starts_at: e.starts_at, slots: e.slots, signed: n, full: e.slots > 0 && n >= e.slots, server: (db.prepare('SELECT server_name FROM licenses WHERE id=?').get(e.license_id) || {}).server_name || '' }; };
router.get('/event/:token', (req, res) => {
  const e = db.prepare('SELECT * FROM dc_events WHERE token=?').get(String(req.params.token).slice(0, 64));
  if (!e) return res.status(404).json({ ok: false, error: 'Événement introuvable ou terminé' }); res.json({ ok: true, event: view(e) });
});
router.post('/event/:token/signup', (req, res) => {
  const ip = A.ip(req); if (limited(ip)) return res.status(429).json({ ok: false, error: 'Trop de tentatives : réessaie dans une minute.' });
  const e = db.prepare('SELECT * FROM dc_events WHERE token=?').get(String(req.params.token).slice(0, 64)); if (!e) return res.status(404).json({ ok: false, error: 'Événement introuvable ou terminé' });
  const b = req.body || {}; const name = String(b.name || '').replace(/[\u0000-\u001f]/g, ' ').trim().slice(0, 40), discord = String(b.discord || '').replace(/[\u0000-\u001f]/g, ' ').trim().slice(0, 40);
  if (name.length < 2) return res.json({ ok: false, error: 'Indique ton pseudo (2 caractères minimum).' });
  if (e.starts_at && e.starts_at < now() - 6 * 3600) return res.json({ ok: false, error: 'Cet événement est terminé.' });
  const n = db.prepare('SELECT COUNT(*) n FROM dc_signups WHERE event_id=?').get(e.id).n;
  if (e.slots > 0 && n >= e.slots) return res.json({ ok: false, error: 'Il n’y a plus de place.' });
  if (db.prepare('SELECT 1 FROM dc_signups WHERE event_id=? AND lower(name)=lower(?)').get(e.id, name)) return res.json({ ok: false, error: 'Ce pseudo est déjà inscrit.' });
  db.prepare('INSERT INTO dc_signups(event_id,name,discord,at,ip) VALUES(?,?,?,?,?)').run(e.id, name, discord, now(), ip);
  res.json({ ok: true, event: view(e) });
});
module.exports = router;
