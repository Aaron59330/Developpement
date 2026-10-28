// Historique des réglages, profils, diagnostic, fiches joueurs, événements, rappels : node tools/selftest7.js
process.env.DATA_DIR = './data-test7'; process.env.ADMIN_EMAIL = 'admin@test.fr'; process.env.ADMIN_PASSWORD = 'AdminTest!123'; process.env.ALLOW_REGISTER = 'true';
const fs = require('fs'), http = require('http'), assert = require('assert'); fs.rmSync(__dirname + '/../data-test7', { recursive: true, force: true });
const realFetch = global.fetch; const sent = [];
global.fetch = (url, opts) => { if (String(url).startsWith('https://discord.com/api/webhooks/')) { sent.push({ url: String(url), body: JSON.parse(opts.body) }); return Promise.resolve({ status: 200, ok: true, json: async () => ({}) }); } return realFetch(url, opts); };
const app = require('../server'); const R = require('../lib/reminders'); const { db, now } = require('../lib/db'); const PS = require('../lib/playerstats'); const DG = require('../lib/diagnostic');
const srv = http.createServer(app).listen(0, async () => {
  const base = 'http://127.0.0.1:' + srv.address().port; let n = 0; const ok = (c, m) => { assert(c, m); n++; console.log('  ✓', m); };
  const mk = () => { let cookie = ''; return async (m, u, body, extra = {}) => { const r = await realFetch(base + u, { method: m, headers: { 'content-type': 'application/json', origin: base, cookie, ...extra }, body: m === 'GET' ? undefined : JSON.stringify(body || {}) }); const sc = r.headers.get('set-cookie'); if (sc) cookie = sc.split(';')[0]; return r.json(); }; };
  try {
    const admin = mk(), a = mk(), b = mk(), pub = mk(), ag = mk();
    await admin('POST', '/api/auth/login', { email: 'admin@test.fr', password: 'AdminTest!123' });
    await a('POST', '/api/auth/register', { email: 'a@t.fr', username: 'Alice', password: 'ClientTest!1' }); await b('POST', '/api/auth/register', { email: 'b@t.fr', username: 'Bob', password: 'ClientTest!1' });
    const users = (await admin('GET', '/api/admin/users')).users, plans = (await admin('GET', '/api/admin/plans')).plans;
    const lic = await admin('POST', '/api/admin/licenses', { user_id: users.find(u => u.email === 'a@t.fr').id, plan_id: plans[1].id, server_name: 'Mon serveur' }); const id = lic.id, H = { 'x-license-key': lic.key };
    // schéma envoyé par pickax_settings
    const SCH = [{ key: 'game_mode', group: 'Serveur', label: 'Mode', type: 'select', default: 'difficile', options: [['facile', 'Facile'], ['difficile', 'Difficile']] }, { key: 'npc_density', group: 'Serveur', label: 'PNJ', type: 'number', default: 1, min: 0, max: 1, step: 0.1 }, { key: 'friendly_fire', group: 'Serveur', label: 'Tir ami', type: 'bool', default: true }];
    let s = await ag('POST', '/api/agent/sync', { settingsSchema: SCH, players: [], resources: [{ name: 'pickax_core', state: 'started' }] }, H); ok(s.ok, 'schéma reçu');
    // ── historique ──
    ok((await a('GET', `/api/servers/${id}/settings/history`)).rows.length === 0, 'historique vide au départ');
    let r = await a('PUT', `/api/servers/${id}/settings`, { values: { npc_density: 0.5 } }); ok(r.ok, 'réglage enregistré');
    r = await a('PUT', `/api/servers/${id}/settings`, { values: { npc_density: 0.5 } }); let h = await a('GET', `/api/servers/${id}/settings/history`); ok(h.rows.length === 1, 'un enregistrement sans changement n’ajoute rien');
    await a('PUT', `/api/servers/${id}/settings`, { values: { npc_density: 0.2, friendly_fire: false } }); h = await a('GET', `/api/servers/${id}/settings/history`);
    ok(h.rows.length === 2 && h.rows[0].changes.length === 2 && h.rows[0].user === 'Alice', 'changements, auteur et date notés');
    ok((await b('GET', `/api/servers/${id}/settings/history`)).ok === false, 'historique privé');
    ok((await b('POST', `/api/servers/${id}/settings/history/${h.rows[0].id}/restore`)).ok === false, 'restauration refusée à un autre client');
    r = await a('POST', `/api/servers/${id}/settings/history/${h.rows[0].id}/restore`); ok(r.ok && r.changed === 2, 'dernier changement annulé');
    let cur = await a('GET', `/api/servers/${id}/settings`); ok(JSON.stringify(cur).includes('0.5') && !JSON.stringify(cur.overrides || cur.values || {}).includes('friendly_fire'), 'valeurs d’avant rétablies');
    ok((await a('GET', `/api/servers/${id}/settings/history`)).rows.length === 3, 'l’annulation est elle-même notée');
    // ── profils ──
    const pf = await a('GET', `/api/servers/${id}/settings/profiles`); ok(pf.ok && pf.ready && pf.profiles.length === 3 && pf.profiles.every(p => p.count > 0 && Object.keys(p.values).every(k => SCH.some(d => d.key === k))), '3 profils, limités aux réglages connus');
    r = await a('POST', `/api/servers/${id}/settings/profile`, { name: 'Débutant', values: { game_mode: 'facile', inconnu: 1 } }); ok(r.ok && r.changed === 1 && r.skipped === 1, 'profil appliqué, clé inconnue ignorée');
    r = await a('POST', `/api/servers/${id}/settings/profile`, { name: 'x', values: { game_mode: 'nimporte' } }); ok(r.ok === false, 'valeur invalide refusée');
    ok((await a('GET', `/api/servers/${id}/settings/history`)).rows[0].source.startsWith('profil'), 'profil noté dans l’historique');
    // ── diagnostic ──
    const d = await a('GET', `/api/servers/${id}/diagnostic`); ok(d.ok && Array.isArray(d.checks) && d.checks.length > 3 && typeof d.score === 'number', 'diagnostic rendu');
    ok((await b('GET', `/api/servers/${id}/diagnostic`)).ok === false, 'diagnostic privé');
    const d0 = DG.run({ now: now(), license: { status: 'active', expires_at: now() + 86400 * 2 }, lastSeen: 0, resources: [], players: 0, maxPlayers: 0, stats: {}, errors: [] }); ok(d0.bad > 0 && d0.score < 100, 'serveur hors ligne : problèmes détectés');
    // ── fiches joueurs ──
    const pl = (money) => ({ players: [{ id: 1, name: 'Jean', identifier: 'license:abc', job: 'police', grade: 1, money, bank: 100, ping: 30 }] });
    const t0 = now(); PS.track(id, pl(100).players, t0); PS.track(id, pl(500).players, t0 + 60); PS.track(id, pl(200).players, t0 + 120); PS.track(id, [], t0 + 130); PS.track(id, pl(1).players, t0 + 2000);
    let p = await a('GET', `/api/servers/${id}/players-db/license:abc`); ok(p.ok && p.player.minutes === 2 && p.player.sessions === 2 && p.player.max_money >= 500, 'temps de jeu, sessions et pic d’argent suivis');
    ok((await a('GET', `/api/servers/${id}/players-db?q=jea`)).rows.length === 1 && (await a('GET', `/api/servers/${id}/players-db?q=zzz`)).rows.length === 0, 'recherche de joueur');
    ok((await b('GET', `/api/servers/${id}/players-db/license:abc`)).ok === false, 'fiches privées');
    // ── événements ──
    const hook = 'https://discord.com/api/webhooks/123456789012345678/SecretTokenABCDEFGH';
    const ch = await a('POST', `/api/servers/${id}/discord/channels`, { name: 'events', url: hook }); ok(ch.ok, 'salon ajouté');
    ok((await a('POST', `/api/servers/${id}/discord/events`, { title: '', channelId: ch.id })).ok === false, 'titre obligatoire');
    ok((await a('POST', `/api/servers/${id}/discord/events`, { title: 'X', channelId: 999 })).ok === false, 'salon inconnu refusé');
    r = await a('POST', `/api/servers/${id}/discord/events`, { title: 'Braquage', description: 'Banque', slots: 2, starts_at: '2099-01-01T20:00', channelId: ch.id });
    ok(r.ok && sent.length === 1 && sent[0].body.embeds[0].fields.some(f => f.value.includes('/event.html?t=')) && sent[0].body.allowed_mentions.parse.length === 0, 'événement publié avec lien d’inscription');
    const tok = r.link.split('t=')[1];
    ok((await pub('GET', '/api/public/event/nimporte')).ok === false, 'jeton inconnu : introuvable');
    let e = await pub('GET', `/api/public/event/${tok}`); ok(e.ok && e.event.title === 'Braquage' && e.event.signed === 0 && !JSON.stringify(e).includes('license'), 'page publique sans données sensibles');
    ok((await pub('POST', `/api/public/event/${tok}/signup`, { name: 'a' })).ok === false, 'pseudo trop court');
    ok((await pub('POST', `/api/public/event/${tok}/signup`, { name: 'Jean', discord: 'jean#1' })).ok, 'inscription 1');
    ok((await pub('POST', `/api/public/event/${tok}/signup`, { name: 'jean' })).ok === false, 'doublon refusé');
    ok((await pub('POST', `/api/public/event/${tok}/signup`, { name: 'Luc' })).ok, 'inscription 2');
    r = await pub('POST', `/api/public/event/${tok}/signup`, { name: 'Max' }); ok(r.ok === false && /place/.test(r.error), 'complet : refusé');
    const list = await a('GET', `/api/servers/${id}/discord/events`); const eid = list.events[0].id; ok(list.events[0].signed === 2, 'compteur d’inscrits');
    ok((await a('GET', `/api/servers/${id}/discord/events/${eid}`)).signups.length === 2 && (await b('GET', `/api/servers/${id}/discord/events/${eid}`)).ok === false, 'liste des inscrits privée');
    await b('DELETE', `/api/servers/${id}/discord/events/${eid}`); ok((await a('GET', `/api/servers/${id}/discord/events`)).events.length === 1, 'un autre client ne peut pas supprimer');
    for (let i = 0; i < 8; i++) r = await pub('POST', `/api/public/event/${tok}/signup`, { name: 'Zed' + i }); ok(r.ok === false, 'limite de débit / complet sur abus');
    await a('DELETE', `/api/servers/${id}/discord/events/${eid}`); ok((await pub('GET', `/api/public/event/${tok}`)).ok === false, 'événement supprimé : lien mort');
    // ── rappels ──
    ok(R.dueStep(8 * 86400, null) === null && R.dueStep(6.5 * 86400, null) === 7 && R.dueStep(2 * 86400, 7) === 3 && R.dueStep(2 * 86400, 3) === null && R.dueStep(3600, 3) === 1 && R.dueStep(-5, null) === null, 'paliers 7 / 3 / 1 jour sans doublon');
    ok((await a('PUT', `/api/servers/${id}/discord/reminders`, { enabled: true })).ok === false, 'rappels : salon obligatoire');
    ok((await a('PUT', `/api/servers/${id}/discord/reminders`, { enabled: true, channelId: ch.id })).ok, 'rappels activés');
    const at = now(); db.prepare('UPDATE licenses SET expires_at=? WHERE id=?').run(at + 5 * 86400, id);
    const out = []; const send = async (u, body) => { out.push(body); return true; };
    ok(await R.run(send, at) === 1 && out[0].embeds[0].description.includes('Mon serveur'), 'rappel envoyé (7 jours)');
    ok(await R.run(send, at + 60) === 0, 'pas de doublon');
    ok(await R.run(send, at + 2.5 * 86400) === 1 && await R.run(send, at + 2.6 * 86400) === 0, 'rappel suivant (3 jours) une seule fois');
    db.prepare('UPDATE licenses SET expires_at=? WHERE id=?').run(at + 400 * 86400 + 4 * 86400, id); ok(await R.run(send, at + 400 * 86400) === 1, 'licence renouvelée : cycle relancé');
    await a('PUT', `/api/servers/${id}/discord/reminders`, { enabled: false }); ok(await R.run(send, at + 400 * 86400 + 3 * 86400) === 0, 'rappels désactivés : rien envoyé');
    // pages statiques
    const pg = await realFetch(base + '/event.html'); const html = await pg.text(); ok(pg.ok && !/<script(?![^>]*src)/.test(html), 'page d’inscription sans script en ligne (CSP)');
  } catch (e) { console.error('ÉCHEC :', e.stack); process.exitCode = 1; }
  console.log(process.exitCode ? '' : `\n${n} vérifications OK`); srv.close(); setTimeout(() => process.exit(process.exitCode || 0), 200);
});
