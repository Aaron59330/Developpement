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

module.exports = router;
