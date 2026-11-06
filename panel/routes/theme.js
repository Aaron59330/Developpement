// Personnalisation du serveur : couleur principale + logo (png / jpg). Le serveur de jeu les récupère avec sa clé de licence.
const express = require('express');
const { db, now, audit } = require('../lib/db'); const A = require('../lib/auth');
const MAX = 2 * 1024 * 1024;
const isPng = b => b.length > 8 && b.slice(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]));
const isJpg = b => b.length > 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff;
const owned = (req, id) => db.prepare('SELECT * FROM licenses WHERE id=?').get(id) && db.prepare('SELECT * FROM licenses WHERE id=? AND (user_id=? OR ?)').get(id, req.user.id, req.user.role === 'admin' ? 1 : 0);
const info = id => { const t = db.prepare('SELECT accent,logo_type,version,updated_at,(logo IS NOT NULL) has_logo FROM themes WHERE license_id=?').get(id); return t ? { accent: t.accent, has_logo: !!t.has_logo, logo_type: t.logo_type, version: t.version, updated_at: t.updated_at } : { accent: null, has_logo: false, version: 0 }; };
function touch(id, patch) {
  db.prepare('INSERT OR IGNORE INTO themes(license_id,version,updated_at) VALUES(?,0,?)').run(id, now());
  for (const [k, v] of Object.entries(patch)) db.prepare(`UPDATE themes SET ${k}=? WHERE license_id=?`).run(v, id);
  db.prepare('UPDATE themes SET version=version+1, updated_at=? WHERE license_id=?').run(now(), id);
}

// ── côté client (connecté) ──
const user = express.Router(); user.use(A.needUser);
user.get('/:id', (req, res) => { const id = +req.params.id; if (!owned(req, id)) return res.status(404).json({ ok: false, error: 'Licence introuvable' }); res.json({ ok: true, theme: info(id) }); });
user.get('/:id/logo', (req, res) => { const id = +req.params.id; if (!owned(req, id)) return res.status(404).end(); const t = db.prepare('SELECT logo,logo_type FROM themes WHERE license_id=?').get(id); if (!t || !t.logo) return res.status(404).end(); res.type(t.logo_type).send(t.logo); });
user.put('/:id', (req, res) => {
  const id = +req.params.id; if (!owned(req, id)) return res.status(404).json({ ok: false, error: 'Licence introuvable' });
  const c = String((req.body || {}).accent || '').toLowerCase(); if (!/^#[0-9a-f]{6}$/.test(c)) return res.json({ ok: false, error: 'Couleur invalide (format #RRGGBB)' });
  touch(id, { accent: c }); audit(req.user.id, id, 'theme:color', c, A.ip(req)); res.json({ ok: true, theme: info(id) });
});
user.post('/:id/logo', (req, res) => {
  const id = +req.params.id; if (!owned(req, id)) return res.status(404).json({ ok: false, error: 'Licence introuvable' });
  const m = String((req.body || {}).data || '').match(/^data:(image\/(?:png|jpeg));base64,([A-Za-z0-9+/=]+)$/); if (!m) return res.json({ ok: false, error: 'Image .png ou .jpg uniquement' });
  const buf = Buffer.from(m[2], 'base64'); if (buf.length > MAX) return res.json({ ok: false, error: 'Image trop lourde (2 Mo maximum)' });
  const type = m[1] === 'image/png' ? 'image/png' : 'image/jpeg';
  if (type === 'image/png' ? !isPng(buf) : !isJpg(buf)) return res.json({ ok: false, error: 'Fichier image invalide' });
  touch(id, { logo: buf, logo_type: type }); audit(req.user.id, id, 'theme:logo', type + ' ' + buf.length, A.ip(req)); res.json({ ok: true, theme: info(id) });
});
user.delete('/:id/logo', (req, res) => { const id = +req.params.id; if (!owned(req, id)) return res.status(404).json({ ok: false }); touch(id, { logo: null, logo_type: null }); res.json({ ok: true, theme: info(id) }); });

// ── côté serveur de jeu (clé de licence) ──
const agent = express.Router();
function byKey(req, res) {
  const key = String(req.query.key || ''); const l = key ? db.prepare('SELECT * FROM licenses WHERE key=?').get(key) : null;
  if (!l || l.status !== 'active' || (l.expires_at && l.expires_at < now())) { res.status(403).json({ ok: false, error: 'Licence invalide' }); return null; }
  return l;
}
agent.get('/theme', (req, res) => { const l = byKey(req, res); if (!l) return; const t = info(l.id); res.json({ ok: true, version: t.version, accent: t.accent, logo: t.has_logo ? { type: t.logo_type, url: `/api/agent/logo?key=${encodeURIComponent(l.key)}&v=${t.version}` } : null }); });
agent.get('/logo', (req, res) => { const l = byKey(req, res); if (!l) return; const t = db.prepare('SELECT logo,logo_type FROM themes WHERE license_id=?').get(l.id); if (!t || !t.logo) return res.status(404).end(); res.type(t.logo_type).send(t.logo); });
module.exports = { user, agent };
