// Message Discord (éditeur, salons, modèles, envoi) : node tools/selftest6.js
process.env.DATA_DIR = './data-test6'; process.env.ADMIN_EMAIL = 'admin@test.fr'; process.env.ADMIN_PASSWORD = 'AdminTest!123'; process.env.ALLOW_REGISTER = 'true';
const fs = require('fs'), http = require('http'), assert = require('assert'); fs.rmSync(__dirname + '/../data-test6', { recursive: true, force: true });
const DM = require('../lib/discordmsg');
const realFetch = global.fetch; const sent = []; let discordReply = () => ({ status: 200, json: { id: '1' } });
global.fetch = (url, opts) => { if (String(url).startsWith('https://discord.com/api/webhooks/')) { sent.push({ url: String(url), body: JSON.parse(opts.body) }); const r = discordReply(); return Promise.resolve({ status: r.status, ok: r.status < 300, json: async () => r.json }); } return realFetch(url, opts); };
const app = require('../server');
const srv = http.createServer(app).listen(0, async () => {
  const base = 'http://127.0.0.1:' + srv.address().port; let n = 0; const ok = (c, m) => { assert(c, m); n++; console.log('  ✓', m); };
  const mk = () => { let cookie = ''; return async (m, u, body) => { const r = await realFetch(base + u, { method: m, headers: { 'content-type': 'application/json', origin: base, cookie }, body: m === 'GET' ? undefined : JSON.stringify(body || {}) }); const sc = r.headers.get('set-cookie'); if (sc) cookie = sc.split(',').map(x => x.split(';')[0]).join('; '); return r.json(); }; };
  try {
    // ── nettoyage du message (limites de Discord) ──
    let c = DM.clean({ content: 'x'.repeat(2500), username: 'u'.repeat(100), avatar_url: 'javascript:alert(1)', embeds: [{ title: 'T'.repeat(300), description: 'd', color: 16626301, url: 'http://insecure.fr', fields: [{ name: 'a', value: '' }, { name: 'b', value: 'v', inline: true }], thumbnail: { url: 'https://i.fr/x.png' }, timestamp: true }] });
    ok(c.message.content.length === 2000 && c.message.username.length === 80 && !c.message.avatar_url, 'texte tronqué aux limites de Discord, avatar non https refusé');
    ok(c.message.embeds[0].title.length === 256 && !c.message.embeds[0].url && c.message.embeds[0].fields.length === 1 && c.message.embeds[0].thumbnail.url && /T.*Z$/.test(c.message.embeds[0].timestamp), 'embed : titre tronqué, lien non https retiré, champ vide ignoré, date ISO');
    ok(DM.clean({}).error && DM.clean({ content: '   ' }).error && DM.clean(null).error, 'message vide refusé');
    ok(DM.clean({ embeds: Array.from({ length: 12 }, () => ({ title: 'x' })) }).message.embeds.length === 10, '10 embeds au maximum');
    ok(DM.clean({ embeds: [{ description: 'a'.repeat(4096) }, { description: 'b'.repeat(4096) }] }).error, 'plus de 6000 caractères d’embeds refusé');
    ok(DM.clean({ content: 'a' }).message.allowed_mentions.parse.length === 0 && DM.clean({ content: 'a' }, { mentions: 'all' }).message.allowed_mentions.parse.includes('everyone') && !DM.clean({ content: 'a' }, { mentions: 'users' }).message.allowed_mentions.parse.includes('everyone'), 'mentions : aucune par défaut, @everyone seulement si autorisé');
    ok(DM.okHook('https://discord.com/api/webhooks/123/abc-DEF_1') && !DM.okHook('http://discord.com/api/webhooks/123/abc') && !DM.okHook('https://evil.com/api/webhooks/123/abc') && !DM.okHook('https://discord.com.evil.com/api/webhooks/123/abc'), 'seuls les webhooks Discord en https sont acceptés');
    // ── routes ──
    const admin = mk(), a = mk(), b = mk();
    await admin('POST', '/api/auth/login', { email: 'admin@test.fr', password: 'AdminTest!123' });
    await a('POST', '/api/auth/register', { email: 'a@t.fr', username: 'Alice', password: 'ClientTest!1' }); await b('POST', '/api/auth/register', { email: 'b@t.fr', username: 'Bob', password: 'ClientTest!1' });
    const users = (await admin('GET', '/api/admin/users')).users, plans = (await admin('GET', '/api/admin/plans')).plans;
    const lic = await admin('POST', '/api/admin/licenses', { user_id: users.find(u => u.email === 'a@t.fr').id, plan_id: plans[1].id, server_name: 'S' }); const id = lic.id;
    const url = 'https://discord.com/api/webhooks/123456789012345678/SecretTokenABCDEFGH';
    ok((await a('POST', `/api/servers/${id}/discord/channels`, { name: 'annonces', url: 'https://evil.com/x' })).ok === false, 'webhook invalide refusé');
    ok((await a('POST', `/api/servers/${id}/discord/channels`, { name: '', url })).ok === false, 'nom obligatoire');
    const ch = await a('POST', `/api/servers/${id}/discord/channels`, { name: 'annonces', url }); ok(ch.ok, 'salon ajouté');
    let list = await a('GET', `/api/servers/${id}/discord`); ok(list.channels.length === 1 && !JSON.stringify(list).includes('SecretToken') && list.channels[0].hint.includes('•'), 'l’adresse complète du webhook n’est jamais renvoyée au navigateur');
    ok((await b('GET', `/api/servers/${id}/discord`)).ok === false && (await b('POST', `/api/servers/${id}/discord/send`, { channelId: ch.id, message: { content: 'x' } })).ok === false, 'un autre client n’a pas accès aux salons');
    let r = await a('POST', `/api/servers/${id}/discord/send`, { channelId: ch.id, message: { content: '' } }); ok(r.ok === false && /vide/.test(r.error), 'message vide refusé à l’envoi');
    r = await a('POST', `/api/servers/${id}/discord/send`, { channelId: 9999, message: { content: 'x' } }); ok(r.ok === false, 'salon inconnu refusé');
    await new Promise(r => setTimeout(r, 2100));
    r = await a('POST', `/api/servers/${id}/discord/send`, { channelId: ch.id, message: { content: 'Bonjour @everyone', embeds: [{ title: 'Titre', color: 16626301 }] } });
    ok(r.ok && sent.length === 1 && sent[0].url.startsWith(url + '?wait=true') && sent[0].body.embeds[0].title === 'Titre' && sent[0].body.allowed_mentions.parse.length === 0, 'message envoyé à Discord, sans mention par défaut');
    r = await a('POST', `/api/servers/${id}/discord/send`, { channelId: ch.id, message: { content: 'encore' } }); ok(r.ok === false && /2 secondes/.test(r.error), 'limite : 2 secondes entre deux envois');
    await new Promise(r => setTimeout(r, 2100)); discordReply = () => ({ status: 429, json: { retry_after: 3.2 } });
    r = await a('POST', `/api/servers/${id}/discord/send`, { channelId: ch.id, message: { content: 'x' } }); ok(r.ok === false && /4 s/.test(r.error), 'limitation de débit de Discord expliquée');
    await new Promise(r => setTimeout(r, 2100)); discordReply = () => ({ status: 404, json: { message: 'Unknown Webhook' } });
    r = await a('POST', `/api/servers/${id}/discord/send`, { channelId: ch.id, message: { content: 'x' } }); ok(r.ok === false && /supprimé/.test(r.error), 'webhook supprimé : message clair');
    // ── modèles ──
    const msg = { content: 'Salut', username: 'Bot', embeds: [{ title: 'T', color: 16626301, fields: [{ name: 'a', value: 'b', inline: true }] }] };
    r = await a('POST', `/api/servers/${id}/discord/templates`, { name: 'Annonce', data: msg }); ok(r.ok, 'modèle enregistré');
    const tid = r.id; r = await a('POST', `/api/servers/${id}/discord/templates`, { name: 'Annonce', data: { ...msg, content: 'Modifié' } }); ok(r.ok && r.updated && r.id === tid, 'même nom : le modèle est mis à jour');
    r = await a('GET', `/api/servers/${id}/discord/templates/${tid}`); ok(r.ok && r.data.content === 'Modifié' && r.data.embeds[0].fields[0].inline === true, 'modèle rechargé à l’identique');
    ok((await b('GET', `/api/servers/${id}/discord/templates/${tid}`)).ok === false, 'modèles privés à chaque serveur');
    ok((await a('GET', `/api/servers/${id}/discord`)).templates.length === 1, 'liste des modèles');
    await a('DELETE', `/api/servers/${id}/discord/templates/${tid}`); ok((await a('GET', `/api/servers/${id}/discord`)).templates.length === 0, 'modèle supprimé');
    await a('DELETE', `/api/servers/${id}/discord/channels/${ch.id}`); ok((await a('GET', `/api/servers/${id}/discord`)).channels.length === 0, 'salon retiré');
  } catch (e) { console.error('ÉCHEC :', e.message); process.exitCode = 1; }
  console.log(process.exitCode ? '' : `\n${n} vérifications OK`); srv.close(); setTimeout(() => process.exit(process.exitCode || 0), 200);
});
