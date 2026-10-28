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

// ── candidatures : formulaire public ouvert par le client ──
const license = lid => db.prepare('SELECT id,server_name FROM licenses WHERE id=?').get(lid);
function recruitByToken(token) {
  token = String(token || '').slice(0, 64); if (token.length < 8) return null;
  for (const d of db.prepare("SELECT license_id,value FROM docs WHERE key='recruit' AND value LIKE ?").all(`%${token.replace(/[%_"\\]/g, '')}%`)) { const c = JSON.parse(d.value); if (c.token === token) return { lid: d.license_id, c }; }
  return null;
}
router.get('/apply/:token', (req, res) => {
  const r = recruitByToken(req.params.token); if (!r || !r.c.open) return res.status(404).json({ ok: false, error: 'Les candidatures sont fermées.' });
  res.json({ ok: true, form: { title: r.c.title, intro: r.c.intro, jobs: r.c.jobs, questions: r.c.questions, server: (license(r.lid) || {}).server_name || '' } });
});
router.post('/apply/:token', async (req, res) => {
  const ip = A.ip(req); if (limited(ip)) return res.status(429).json({ ok: false, error: 'Trop de tentatives : réessaie dans une minute.' });
  const r = recruitByToken(req.params.token); if (!r || !r.c.open) return res.status(404).json({ ok: false, error: 'Les candidatures sont fermées.' });
  const b = req.body || {}; const clean = (v, n) => String(v == null ? '' : v).replace(/[\u0000-\u0008\u000b-\u001f]/g, ' ').trim().slice(0, n);
  const name = clean(b.name, 40), discord = clean(b.discord, 40), job = clean(b.job, 40);
  if (name.length < 2) return res.json({ ok: false, error: 'Indique le nom de ton personnage.' }); if (!r.c.jobs.includes(job)) return res.json({ ok: false, error: 'Choisis un poste.' });
  const answers = r.c.questions.map((q, i) => ({ q, a: clean((b.answers || [])[i], 1200) })); if (answers.some(x => x.a.length < 3)) return res.json({ ok: false, error: 'Réponds à toutes les questions.' });
  if (db.prepare("SELECT COUNT(*) n FROM applications WHERE license_id=? AND lower(name)=lower(?) AND job=? AND status IN ('new','interview')").get(r.lid, name, job).n) return res.json({ ok: false, error: 'Tu as déjà une candidature en cours pour ce poste.' });
  if (db.prepare("SELECT COUNT(*) n FROM applications WHERE license_id=? AND status='new'").get(r.lid).n >= 500) return res.json({ ok: false, error: 'Trop de candidatures en attente : réessaie plus tard.' });
  db.prepare('INSERT INTO applications(license_id,job,name,discord,answers,at,ip) VALUES(?,?,?,?,?,?,?)').run(r.lid, job, name, discord, JSON.stringify(answers), now(), ip);
  const ch = r.c.channelId ? db.prepare('SELECT url FROM discord_channels WHERE id=? AND license_id=?').get(r.c.channelId, r.lid) : null;
  if (ch) fetch(ch.url, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ username: 'AERO Panel', embeds: [{ title: '📝  Nouvelle candidature : ' + job, description: `**${name}**${discord ? ' · ' + discord : ''}\nÀ traiter dans le panel → Candidatures.`, color: 0xfdc27d }], allowed_mentions: { parse: [] } }), signal: AbortSignal.timeout(10000) }).catch(() => {});
  res.json({ ok: true });
});
module.exports = router;
