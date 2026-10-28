// Message Discord : salons (webhooks), modèles et envoi de messages avec embeds (style Discohook), par serveur
const router = require('express').Router();
const { db, now, audit } = require('../lib/db'); const A = require('../lib/auth');
const { own, active } = require('../lib/access'); const DM = require('../lib/discordmsg');
router.use(A.needUser);
const MAX_CH = 25, MAX_TPL = 60;
const mask = u => { const m = /\/webhooks\/(\d+)\/([\w-]+)/.exec(u); return m ? `…/webhooks/${m[1].slice(0, 4)}…/${'•'.repeat(6)}${m[2].slice(-4)}` : '—'; };   // l'adresse complète n'est jamais renvoyée au navigateur
const lastSend = new Map();

router.get('/:id/discord', (req, res) => {
  const l = own(req, res); if (!l) return;
  res.json({ ok: true,
    channels: db.prepare('SELECT id,name,url FROM discord_channels WHERE license_id=? ORDER BY name').all(l.id).map(c => ({ id: c.id, name: c.name, hint: mask(c.url) })),
    templates: db.prepare('SELECT id,name,updated_at FROM discord_templates WHERE license_id=? ORDER BY name').all(l.id) });
});

router.post('/:id/discord/channels', (req, res) => {
  const l = own(req, res); if (!l) return; const b = req.body || {};
  const name = String(b.name || '').trim().slice(0, 40), url = String(b.url || '').trim();
  if (!name) return res.json({ ok: false, error: 'Donne un nom au salon (ex : annonces).' });
  if (!DM.okHook(url)) return res.json({ ok: false, error: 'Adresse de webhook invalide : https://discord.com/api/webhooks/…' });
  if (db.prepare('SELECT COUNT(*) n FROM discord_channels WHERE license_id=?').get(l.id).n >= MAX_CH) return res.json({ ok: false, error: `Maximum ${MAX_CH} salons.` });
  const id = db.prepare('INSERT INTO discord_channels(license_id,name,url,created_at) VALUES(?,?,?,?)').run(l.id, name, url, now()).lastInsertRowid;
  audit(req.user.id, l.id, 'discord:channel', name, A.ip(req)); res.json({ ok: true, id });
});
router.delete('/:id/discord/channels/:cid', (req, res) => {
  const l = own(req, res); if (!l) return;
  db.prepare('DELETE FROM discord_channels WHERE id=? AND license_id=?').run(+req.params.cid, l.id); res.json({ ok: true });
});

router.get('/:id/discord/templates/:tid', (req, res) => {
  const l = own(req, res); if (!l) return;
  const t = db.prepare('SELECT id,name,data FROM discord_templates WHERE id=? AND license_id=?').get(+req.params.tid, l.id);
  if (!t) return res.json({ ok: false, error: 'Modèle introuvable' });
  let data = {}; try { data = JSON.parse(t.data); } catch (e) {}
  res.json({ ok: true, id: t.id, name: t.name, data });
});
router.post('/:id/discord/templates', (req, res) => {
  const l = own(req, res); if (!l) return; const b = req.body || {};
  const name = String(b.name || '').trim().slice(0, 60); if (!name) return res.json({ ok: false, error: 'Donne un nom au modèle.' });
  const c = DM.clean(b.data, {}); const data = c.message || { content: '', embeds: [] };    // brouillon vide autorisé : on garde ce qui est valide
  const json = JSON.stringify(b.data && typeof b.data === 'object' ? { content: String(b.data.content || '').slice(0, 2000), username: String(b.data.username || '').slice(0, 80), avatar_url: String(b.data.avatar_url || '').slice(0, 300), embeds: (Array.isArray(b.data.embeds) ? b.data.embeds : []).slice(0, 10) } : data);
  if (json.length > 60000) return res.json({ ok: false, error: 'Modèle trop volumineux.' });
  const ex = db.prepare('SELECT id FROM discord_templates WHERE license_id=? AND name=?').get(l.id, name);
  if (ex) { db.prepare('UPDATE discord_templates SET data=?, updated_at=? WHERE id=?').run(json, now(), ex.id); return res.json({ ok: true, id: ex.id, updated: true }); }
  if (db.prepare('SELECT COUNT(*) n FROM discord_templates WHERE license_id=?').get(l.id).n >= MAX_TPL) return res.json({ ok: false, error: `Maximum ${MAX_TPL} modèles.` });
  res.json({ ok: true, id: db.prepare('INSERT INTO discord_templates(license_id,name,data,updated_at) VALUES(?,?,?,?)').run(l.id, name, json, now()).lastInsertRowid });
});
router.delete('/:id/discord/templates/:tid', (req, res) => {
  const l = own(req, res); if (!l) return;
  db.prepare('DELETE FROM discord_templates WHERE id=? AND license_id=?').run(+req.params.tid, l.id); res.json({ ok: true });
});

router.post('/:id/discord/send', async (req, res) => {
  const l = own(req, res); if (!l) return; const b = req.body || {};
  if (!active(l)) return res.json({ ok: false, error: 'Licence inactive ou expirée' });
  const ch = db.prepare('SELECT id,name,url FROM discord_channels WHERE id=? AND license_id=?').get(+b.channelId, l.id);
  if (!ch) return res.json({ ok: false, error: 'Choisis un salon.' });
  const k = l.id + ':' + req.user.id, t = Date.now();
  if (lastSend.get(k) && t - lastSend.get(k) < 2000) return res.json({ ok: false, error: 'Doucement : attends 2 secondes entre deux envois.' });
  const c = DM.clean(b.message, { mentions: ['none', 'users', 'all'].includes(b.mentions) ? b.mentions : 'none' });
  if (c.error) return res.json({ ok: false, error: c.error });
  lastSend.set(k, t);
  try {
    const r = await fetch(ch.url + '?wait=true', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(c.message), signal: AbortSignal.timeout(10000) });
    if (r.status === 429) { const j = await r.json().catch(() => ({})); return res.json({ ok: false, error: `Discord limite le débit : réessaie dans ${Math.ceil(j.retry_after || 5)} s.` }); }
    if (!r.ok) { const j = await r.json().catch(() => ({})); return res.json({ ok: false, error: r.status === 404 || r.status === 401 ? 'Webhook supprimé ou invalide : recrée-le dans Discord puis ajoute-le de nouveau.' : `Discord a refusé le message (${r.status}${j.message ? ' : ' + String(j.message).slice(0, 120) : ''}).` }); }
    audit(req.user.id, l.id, 'discord:send', ch.name, A.ip(req));
    res.json({ ok: true, channel: ch.name });
  } catch (e) { res.json({ ok: false, error: 'Impossible de joindre Discord : ' + (e.name === 'TimeoutError' ? 'délai dépassé' : 'erreur réseau') }); }
});

// ── événements avec inscriptions : un embed avec un lien d'inscription est publié dans le salon choisi ──
const crypto = require('crypto');
async function post(url, body) { try { const r = await fetch(url + '?wait=true', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(body), signal: AbortSignal.timeout(10000) }); return r.status === 429 ? { ok: false, error: 'Discord limite le débit : réessaie dans quelques secondes.' } : r.ok ? { ok: true } : { ok: false, error: r.status === 404 || r.status === 401 ? 'Webhook supprimé ou invalide.' : `Discord a refusé le message (${r.status}).` }; } catch (e) { return { ok: false, error: 'Impossible de joindre Discord.' }; } }
router.get('/:id/discord/events', (req, res) => {
  const l = own(req, res); if (!l) return;
  res.json({ ok: true, events: db.prepare('SELECT e.id,e.title,e.starts_at,e.slots,e.token,e.created_at,(SELECT COUNT(*) FROM dc_signups s WHERE s.event_id=e.id) signed FROM dc_events e WHERE e.license_id=? ORDER BY e.id DESC LIMIT 30').all(l.id) });
});
router.post('/:id/discord/events', async (req, res) => {
  const l = own(req, res); if (!l) return; if (!active(l)) return res.json({ ok: false, error: 'Licence inactive ou expirée' }); const b = req.body || {};
  const title = String(b.title || '').trim().slice(0, 120), desc = String(b.description || '').trim().slice(0, 1500), slots = Math.max(0, Math.min(1000, Math.floor(+b.slots || 0)));
  const starts = b.starts_at ? Math.floor(new Date(b.starts_at).getTime() / 1000) : null; if (b.starts_at && !starts) return res.json({ ok: false, error: 'Date invalide.' });
  if (!title) return res.json({ ok: false, error: 'Donne un titre à l’événement.' });
  if (db.prepare('SELECT COUNT(*) n FROM dc_events WHERE license_id=?').get(l.id).n >= 100) return res.json({ ok: false, error: 'Trop d’événements : supprime les anciens.' });
  const ch = db.prepare('SELECT id,name,url FROM discord_channels WHERE id=? AND license_id=?').get(+b.channelId, l.id); if (!ch) return res.json({ ok: false, error: 'Choisis un salon.' });
  const origin = req.headers.origin || (req.protocol + '://' + req.headers.host); const token = crypto.randomBytes(12).toString('hex'); const link = `${origin}/event.html?t=${token}`;
  const fields = []; if (starts) fields.push({ name: '📅 Date', value: `<t:${starts}:F> (<t:${starts}:R>)`, inline: true }); fields.push({ name: '👥 Places', value: slots ? `${slots} places` : 'Illimité', inline: true }); fields.push({ name: '📝 Inscription', value: `[Clique ici pour t’inscrire](${link})`, inline: false });
  const r = await post(ch.url, { username: b.username ? String(b.username).slice(0, 80) : undefined, embeds: [{ title: '🎉  ' + title, description: desc || undefined, color: 0xfdc27d, fields, footer: { text: 'Inscription en ligne' }, timestamp: new Date().toISOString() }], allowed_mentions: { parse: [] } });
  if (!r.ok) return res.json(r);
  const id = db.prepare('INSERT INTO dc_events(license_id,title,description,starts_at,slots,token,channel,created_at) VALUES(?,?,?,?,?,?,?,?)').run(l.id, title, desc, starts, slots, token, ch.name, now()).lastInsertRowid;
  audit(req.user.id, l.id, 'discord:event', title, A.ip(req)); res.json({ ok: true, id, link });
});
router.get('/:id/discord/events/:eid', (req, res) => {
  const l = own(req, res); if (!l) return; const e = db.prepare('SELECT id,title,starts_at,slots FROM dc_events WHERE id=? AND license_id=?').get(+req.params.eid, l.id); if (!e) return res.json({ ok: false, error: 'Événement introuvable' });
  res.json({ ok: true, event: e, signups: db.prepare('SELECT name,discord,at FROM dc_signups WHERE event_id=? ORDER BY id').all(e.id) });
});
router.delete('/:id/discord/events/:eid', (req, res) => { const l = own(req, res); if (!l) return; db.prepare('DELETE FROM dc_events WHERE id=? AND license_id=?').run(+req.params.eid, l.id); res.json({ ok: true }); });

// ── rappels de licence ──
const putDoc = (lid, key, v) => db.prepare('INSERT INTO docs(license_id,key,value,version,updated_at) VALUES(?,?,?,?,?) ON CONFLICT(license_id,key) DO UPDATE SET value=excluded.value, version=docs.version+1, updated_at=excluded.updated_at').run(lid, key, JSON.stringify(v), 1, now());
router.get('/:id/discord/reminders', (req, res) => { const l = own(req, res); if (!l) return; const d = db.prepare("SELECT value FROM docs WHERE license_id=? AND key='reminders'").get(l.id); res.json({ ok: true, config: d ? JSON.parse(d.value) : { enabled: false, channelId: null }, expires_at: l.expires_at }); });
router.put('/:id/discord/reminders', (req, res) => {
  const l = own(req, res); if (!l) return; const b = req.body || {}; const ch = b.channelId ? db.prepare('SELECT id FROM discord_channels WHERE id=? AND license_id=?').get(+b.channelId, l.id) : null;
  if (b.enabled && !ch) return res.json({ ok: false, error: 'Choisis le salon qui recevra les rappels.' });
  putDoc(l.id, 'reminders', { enabled: !!b.enabled, channelId: ch ? ch.id : null }); res.json({ ok: true });
});

module.exports = router;
