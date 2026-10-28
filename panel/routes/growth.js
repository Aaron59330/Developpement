// Économie du serveur et candidatures (recrutement police / EMS / gangs) côté client connecté
const router = require('express').Router(); const { db, now, audit } = require('../lib/db'); const A = require('../lib/auth'); const { own } = require('../lib/access');
router.use(A.needUser);
router.get('/:id/economy', (req, res) => { const l = own(req, res); if (!l) return; res.json(Object.assign({ ok: true }, require('../lib/economy').summary(l.id, now()))); });

const DEFAULT = { open: false, title: 'Recrutement', intro: '', jobs: ['Police', 'EMS'], questions: ['Présente ton personnage en quelques lignes.', 'Pourquoi veux-tu rejoindre ce service ?'], channelId: null, token: null };
const cfgOf = lid => { const d = db.prepare("SELECT value FROM docs WHERE license_id=? AND key='recruit'").get(lid); return Object.assign({}, DEFAULT, d ? JSON.parse(d.value) : {}); };
const save = (lid, v) => db.prepare("INSERT INTO docs(license_id,key,value,version,updated_at) VALUES(?,?,?,1,?) ON CONFLICT(license_id,key) DO UPDATE SET value=excluded.value, version=docs.version+1, updated_at=excluded.updated_at").run(lid, 'recruit', JSON.stringify(v), now());
const list = (v, n, len) => (Array.isArray(v) ? v : []).map(x => String(x || '').replace(/[\u0000-\u001f]/g, ' ').trim().slice(0, len)).filter(Boolean).slice(0, n);
router.get('/:id/recruit', (req, res) => {
  const l = own(req, res); if (!l) return; const c = cfgOf(l.id);
  res.json({ ok: true, config: c, apps: db.prepare('SELECT id,job,name,discord,answers,status,at FROM applications WHERE license_id=? ORDER BY id DESC LIMIT 200').all(l.id).map(a => ({ ...a, answers: JSON.parse(a.answers) })) });
});
router.put('/:id/recruit', (req, res) => {
  const l = own(req, res); if (!l) return; const b = req.body || {}; const cur = cfgOf(l.id); const jobs = list(b.jobs, 12, 40), questions = list(b.questions, 10, 200);
  if (b.open && !jobs.length) return res.json({ ok: false, error: 'Ajoute au moins un poste.' });
  const ch = b.channelId ? db.prepare('SELECT id FROM discord_channels WHERE id=? AND license_id=?').get(+b.channelId, l.id) : null;
  const token = cur.token || require('crypto').randomBytes(12).toString('hex');
  save(l.id, { open: !!b.open, title: String(b.title || 'Recrutement').trim().slice(0, 80) || 'Recrutement', intro: String(b.intro || '').trim().slice(0, 800), jobs, questions, channelId: ch ? ch.id : null, token });
  audit(req.user.id, l.id, 'recruit:config', b.open ? 'ouvert' : 'fermé', A.ip(req)); res.json({ ok: true, token });
});
router.patch('/:id/recruit/:aid', (req, res) => {
  const l = own(req, res); if (!l) return; const st = (req.body || {}).status; if (!['new', 'accepted', 'refused', 'interview'].includes(st)) return res.json({ ok: false, error: 'Statut inconnu' });
  const r = db.prepare('UPDATE applications SET status=? WHERE id=? AND license_id=?').run(st, +req.params.aid, l.id); res.json({ ok: r.changes > 0 });
});
router.delete('/:id/recruit/:aid', (req, res) => { const l = own(req, res); if (!l) return; db.prepare('DELETE FROM applications WHERE id=? AND license_id=?').run(+req.params.aid, l.id); res.json({ ok: true }); });
module.exports = router;
