// Événements programmés : annonces, redémarrages, événements d'économie… à une date précise, avec répétition et préavis
const router = require('express').Router();
const { db, now, audit } = require('../lib/db'); const A = require('../lib/auth'); const C = require('../lib/commands'); const { own, active } = require('../lib/access'); const { SCHEDULABLE } = require('../lib/scheduler');
router.use(A.needUser);
const WARN = [0, 5, 10, 15, 30, 60], EVERY = ['none', 'daily', 'weekly'];
const row = s => ({ id: s.id, name: s.name, type: s.type, payload: JSON.parse(s.payload), run_at: s.run_at, every: s.every, warn_min: s.warn_min, enabled: !!s.enabled, last_run: s.last_run, last_status: s.last_status });
function clean(b) {
  const name = String(b.name || '').trim().slice(0, 60); if (!name) return { error: 'Donne un nom à l’événement' };
  if (!SCHEDULABLE.includes(b.type)) return { error: 'Type d’action non programmable' };
  const v = C.validate(b.type, b.payload); if (v.error) return { error: v.error };
  const run = Math.floor(+b.run_at); if (!Number.isFinite(run) || run < now() - 60 || run > now() + 366 * 86400) return { error: 'Date invalide (dans le futur, moins d’un an)' };
  const every = EVERY.includes(b.every) ? b.every : 'none', warn = WARN.includes(+b.warn_min) ? +b.warn_min : 0;
  return { v: { name, type: b.type, payload: v.payload, run, every, warn } };
}
router.get('/:id/schedules', (req, res) => { const l = own(req, res); if (!l) return; res.json({ ok: true, now: now(), schedules: db.prepare('SELECT * FROM schedules WHERE license_id=? ORDER BY enabled DESC, run_at').all(l.id).map(row) }); });
router.post('/:id/schedules', (req, res) => {
  const l = own(req, res); if (!l) return; if (!active(l)) return res.json({ ok: false, error: 'Licence inactive ou expirée' });
  if (db.prepare('SELECT COUNT(*) n FROM schedules WHERE license_id=?').get(l.id).n >= 100) return res.json({ ok: false, error: '100 événements maximum' });
  const c = clean(req.body || {}); if (c.error) return res.json({ ok: false, error: c.error }); const v = c.v;
  const id = db.prepare('INSERT INTO schedules(license_id,name,type,payload,run_at,every,warn_min,by_user,created_at) VALUES(?,?,?,?,?,?,?,?,?)').run(l.id, v.name, v.type, JSON.stringify(v.payload), v.run, v.every, v.warn, req.user.id, now()).lastInsertRowid;
  audit(req.user.id, l.id, 'schedule:create', v.name, A.ip(req)); res.json({ ok: true, id });
});
router.patch('/:id/schedules/:sid', (req, res) => {
  const l = own(req, res); if (!l) return; const s = db.prepare('SELECT * FROM schedules WHERE id=? AND license_id=?').get(+req.params.sid, l.id); if (!s) return res.json({ ok: false, error: 'Introuvable' });
  const b = req.body || {};
  if (b.enabled !== undefined && Object.keys(b).length === 1) { if (b.enabled && s.every === 'none' && s.run_at < now()) return res.json({ ok: false, error: 'La date est passée : modifie-la pour réactiver' }); db.prepare('UPDATE schedules SET enabled=? WHERE id=?').run(b.enabled ? 1 : 0, s.id); return res.json({ ok: true }); }
  const c = clean({ name: s.name, type: s.type, payload: JSON.parse(s.payload), run_at: s.run_at, every: s.every, warn_min: s.warn_min, ...b }); if (c.error) return res.json({ ok: false, error: c.error }); const v = c.v;
  db.prepare('UPDATE schedules SET name=?,type=?,payload=?,run_at=?,every=?,warn_min=?,enabled=1,warned_for=NULL WHERE id=?').run(v.name, v.type, JSON.stringify(v.payload), v.run, v.every, v.warn, s.id);
  audit(req.user.id, l.id, 'schedule:edit', v.name, A.ip(req)); res.json({ ok: true });
});
router.delete('/:id/schedules/:sid', (req, res) => { const l = own(req, res); if (!l) return; db.prepare('DELETE FROM schedules WHERE id=? AND license_id=?').run(+req.params.sid, l.id); res.json({ ok: true }); });
router.clean = clean;
module.exports = router;
