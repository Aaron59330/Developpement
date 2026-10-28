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

// ── Rétention ──
router.get('/:id/retention', (req, res) => {
  const l = own(req, res); if (!l) return; const at = now();
  const rows = db.prepare('SELECT name,minutes,sessions,first_seen,last_seen FROM player_stats WHERE license_id=?').all(l.id);
  const points = db.prepare('SELECT at,players FROM stats_hist WHERE license_id=? AND at>? ORDER BY at').all(l.id, at - 14 * 86400);
  res.json(Object.assign({ ok: true }, require('../lib/retention').summary(rows, points, at)));
});

// ── Plaintes (envoyées en jeu avec /plainte) ──
router.get('/:id/reports', (req, res) => {
  const l = own(req, res); if (!l) return; const st = ['new', 'handled'].includes(req.query.status) ? req.query.status : null;
  const rows = db.prepare(`SELECT id,at,reporter,reporter_ident,target,target_ident,message,x,y,status,note FROM reports WHERE license_id=? ${st ? 'AND status=?' : ''} ORDER BY id DESC LIMIT 200`).all(...(st ? [l.id, st] : [l.id]));
  res.json({ ok: true, rows, newCount: db.prepare("SELECT COUNT(*) n FROM reports WHERE license_id=? AND status='new'").get(l.id).n });
});
router.patch('/:id/reports/:rid', (req, res) => {
  const l = own(req, res); if (!l) return; const b = req.body || {}; const st = ['new', 'handled'].includes(b.status) ? b.status : null;
  const note = b.note == null ? null : String(b.note).replace(/[\u0000-\u0008\u000b-\u001f]/g, ' ').trim().slice(0, 300);
  const r = db.prepare('UPDATE reports SET status=COALESCE(?,status), note=COALESCE(?,note) WHERE id=? AND license_id=?').run(st, note, +req.params.rid, l.id);
  if (r.changes) audit(req.user.id, l.id, 'report:update', String(req.params.rid), A.ip(req)); res.json({ ok: r.changes > 0 });
});
router.delete('/:id/reports/:rid', (req, res) => { const l = own(req, res); if (!l) return; db.prepare('DELETE FROM reports WHERE id=? AND license_id=?').run(+req.params.rid, l.id); res.json({ ok: true }); });

// ── Sauvegardes de la base (tables des builders, lecture seule côté jeu) ──
const zlib = require('zlib'), bus = require('../lib/bus'), { active } = require('../lib/access'), C = require('../lib/commands');
router.get('/:id/dbbackups', (req, res) => {
  const l = own(req, res); if (!l) return;
  res.json({ ok: true, backups: db.prepare('SELECT b.id,b.name,b.at,b.size,b.tables,u.username by_name FROM db_backups b LEFT JOIN users u ON u.id=b.by_user WHERE b.license_id=? ORDER BY b.id DESC').all(l.id) });
});
router.post('/:id/dbbackups', async (req, res) => {
  const l = own(req, res); if (!l) return; if (!active(l)) return res.json({ ok: false, error: 'Licence inactive ou expirée' });
  if (db.prepare("SELECT COUNT(*) n FROM db_backups WHERE license_id=? AND at>?").get(l.id, now() - 60).n) return res.json({ ok: false, error: 'Une sauvegarde vient d’être faite : patiente une minute.' });
  const name = String((req.body || {}).name || '').replace(/[\u0000-\u001f]/g, ' ').trim().slice(0, 60) || 'Sauvegarde ' + new Date().toLocaleString('fr-FR');
  const t = await bus.rpc(l.id, 'db.tables', {}, req.user.id, 20000); if (!t.ok) return res.json({ ok: false, error: t.error || 'Le serveur ne répond pas (est-il en ligne ?)' });
  const names = ((t.data && t.data.tables) || []).map(x => x.name).slice(0, 200); if (!names.length) return res.json({ ok: false, error: 'Aucune table de builder trouvée.' });
  const out = { format: 'aero-db', version: 1, at: now(), server: l.server_name, tables: {}, truncated: [] };
  for (let i = 0; i < names.length; i += 4) {
    const r = await bus.rpc(l.id, 'db.export', { tables: names.slice(i, i + 4) }, req.user.id, 30000); if (!r.ok) return res.json({ ok: false, error: 'Export interrompu : ' + (r.error || 'erreur') });
    for (const [k, v] of Object.entries((r.data && r.data.tables) || {})) { out.tables[k] = v.rows || []; if (v.truncated) out.truncated.push(k); }
  }
  const raw = zlib.gzipSync(Buffer.from(JSON.stringify(out))); if (raw.length > 25 * 1024 * 1024) return res.json({ ok: false, error: 'Sauvegarde trop volumineuse.' });
  db.prepare('INSERT INTO db_backups(license_id,name,at,by_user,size,tables,data) VALUES(?,?,?,?,?,?,?)').run(l.id, name, now(), req.user.id, raw.length, Object.keys(out.tables).length, raw);
  db.prepare('DELETE FROM db_backups WHERE license_id=? AND id NOT IN (SELECT id FROM db_backups WHERE license_id=? ORDER BY id DESC LIMIT 10)').run(l.id, l.id);
  audit(req.user.id, l.id, 'dbbackup:create', name, A.ip(req)); res.json({ ok: true, tables: Object.keys(out.tables).length, truncated: out.truncated });
});
router.get('/:id/dbbackups/:bid/download', (req, res) => {
  const l = own(req, res); if (!l) return; const b = db.prepare('SELECT name,data FROM db_backups WHERE id=? AND license_id=?').get(+req.params.bid, l.id); if (!b) return res.status(404).json({ ok: false, error: 'Sauvegarde introuvable' });
  res.set({ 'content-type': 'application/gzip', 'content-disposition': `attachment; filename="aero-base-${+req.params.bid}.json.gz"`, 'cache-control': 'no-store' }); res.send(b.data);
});
router.delete('/:id/dbbackups/:bid', (req, res) => { const l = own(req, res); if (!l) return; db.prepare('DELETE FROM db_backups WHERE id=? AND license_id=?').run(+req.params.bid, l.id); res.json({ ok: true }); });

module.exports = router;
