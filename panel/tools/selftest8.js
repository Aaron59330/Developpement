// Alertes, économie, candidatures, export/import, planificateur de profils : node tools/selftest8.js
process.env.DATA_DIR = './data-test8'; process.env.ADMIN_EMAIL = 'admin@test.fr'; process.env.ADMIN_PASSWORD = 'AdminTest!123'; process.env.ALLOW_REGISTER = 'true';
const fs = require('fs'), http = require('http'), assert = require('assert'); fs.rmSync(__dirname + '/../data-test8', { recursive: true, force: true });
const realFetch = global.fetch; const sent = [];
global.fetch = (url, opts) => { if (String(url).startsWith('https://discord.com/api/webhooks/')) { sent.push(JSON.parse(opts.body)); return Promise.resolve({ status: 200, ok: true }); } return realFetch(url, opts); };
const app = require('../server'); const AL = require('../lib/alerts'); const EC = require('../lib/economy'); const { db, now } = require('../lib/db'); const SCHED = require('../lib/scheduler');
const srv = http.createServer(app).listen(0, async () => {
  const base = 'http://127.0.0.1:' + srv.address().port; let n = 0; const ok = (c, m) => { assert(c, m); n++; console.log('  ✓', m); };
  const mk = () => { let cookie = ''; return async (m, u, body, extra = {}) => { const r = await realFetch(base + u, { method: m, headers: { 'content-type': 'application/json', origin: base, cookie, ...extra }, body: m === 'GET' ? undefined : JSON.stringify(body || {}) }); const sc = r.headers.get('set-cookie'); if (sc) cookie = sc.split(';')[0]; return r.json(); }; };
  try {
    const admin = mk(), a = mk(), b = mk(), pub = mk(), ag = mk();
    await admin('POST', '/api/auth/login', { email: 'admin@test.fr', password: 'AdminTest!123' });
    await a('POST', '/api/auth/register', { email: 'a@t.fr', username: 'Alice', password: 'ClientTest!1' }); await b('POST', '/api/auth/register', { email: 'b@t.fr', username: 'Bob', password: 'ClientTest!1' });
    const users = (await admin('GET', '/api/admin/users')).users, plans = (await admin('GET', '/api/admin/plans')).plans;
    const lic = await admin('POST', '/api/admin/licenses', { user_id: users.find(u => u.email === 'a@t.fr').id, plan_id: plans[1].id, server_name: 'Mon serveur' }); const id = lic.id, H = { 'x-license-key': lic.key };
    const SCH = [{ key: 'game_mode', group: 'Serveur', label: 'Mode', type: 'select', default: 'difficile', options: [['facile', 'Facile'], ['difficile', 'Difficile']] }, { key: 'npc_density', group: 'Serveur', label: 'PNJ', type: 'number', default: 1, min: 0, max: 1, step: 0.1 }, { key: 'discord_webhook', group: 'Discord', label: 'Webhook', type: 'text', default: '', secret: true }];
    await ag('POST', '/api/agent/sync', { settingsSchema: SCH, players: [{ id: 1, name: 'Riche', identifier: 'license:r', money: 9000000, bank: 1000000 }, { id: 2, name: 'Pauvre', identifier: 'license:p', money: 100, bank: 50 }], resources: [] }, H);
    const hook = 'https://discord.com/api/webhooks/123456789012345678/SecretTokenABCDEFGH'; const ch = await a('POST', `/api/servers/${id}/discord/channels`, { name: 'alertes', url: hook });
    // ── alertes (logique pure) ──
    const cfg = { offline: true, errors: true, errorLimit: 10, rich: true, richLimit: 5000000 }; const t = 100000;
    let r = AL.evaluate({ cfg, at: t, server: 'S', lastSeen: t - 60, errors: 0, players: [] }, null); ok(r.msgs.length === 0, 'serveur en ligne : rien');
    r = AL.evaluate({ cfg, at: t, server: 'S', lastSeen: t - 900, errors: 0, players: [] }, r.state); ok(r.msgs.length === 1 && /hors ligne/.test(r.msgs[0].title), 'hors ligne détecté');
    r = AL.evaluate({ cfg, at: t + 60, server: 'S', lastSeen: t - 900, errors: 0, players: [] }, r.state); ok(r.msgs.length === 0, 'pas de doublon');
    r = AL.evaluate({ cfg, at: t + 120, server: 'S', lastSeen: t + 100, errors: 0, players: [] }, r.state); ok(r.msgs.length === 1 && /de nouveau en ligne/.test(r.msgs[0].title), 'retour en ligne signalé');
    r = AL.evaluate({ cfg, at: t + 200, server: 'S', lastSeen: t + 190, errors: 12, players: [] }, r.state); ok(r.msgs.length === 1 && /erreurs/.test(r.msgs[0].title), 'pic d’erreurs');
    r = AL.evaluate({ cfg, at: t + 300, server: 'S', lastSeen: t + 290, errors: 50, players: [] }, r.state); ok(r.msgs.length === 0, 'pic d’erreurs : pas de répétition avant 30 min');
    r = AL.evaluate({ cfg, at: t + 400, server: 'S', lastSeen: t + 390, errors: 0, players: [{ identifier: 'x', name: 'Z', money: 4000000, bank: 2000000 }] }, r.state); ok(r.msgs.length === 1 && /riche/.test(r.msgs[0].title), 'joueur très riche');
    r = AL.evaluate({ cfg, at: t + 500, server: 'S', lastSeen: t + 490, errors: 0, players: [{ identifier: 'x', name: 'Z', money: 4000000, bank: 2000000 }] }, r.state); ok(r.msgs.length === 0, 'joueur riche : une alerte par jour');
    r = AL.evaluate({ cfg: { ...cfg, offline: false, errors: false, rich: false }, at: t, server: 'S', lastSeen: 1, errors: 99, players: [{ identifier: 'x', money: 1e9 }] }, null); ok(r.msgs.length === 0, 'alertes désactivées individuellement');
    // ── alertes (routes + envoi) ──
    ok((await a('PUT', `/api/servers/${id}/discord/alerts`, { enabled: true })).ok === false, 'salon obligatoire');
    ok((await b('GET', `/api/servers/${id}/discord/alerts`)).ok === false, 'alertes privées');
    ok((await a('PUT', `/api/servers/${id}/discord/alerts`, { enabled: true, channelId: ch.id, offline: false, errors: false, rich: true, richLimit: 5000000 })).ok, 'alertes enregistrées');
    const out = []; ok(await AL.run(async (u, body) => { out.push(body); return true; }) === 1 && /Riche/.test(out[0].embeds[0].description), 'envoi : seul le joueur riche déclenche');
    ok(await AL.run(async () => true) === 0, 'envoi : pas de doublon au tour suivant');
    // ── économie ──
    EC.track(id, [{ money: 1000, bank: 2000 }, { money: 500, bank: 500 }], now()); EC.track(id, [{ money: 1, bank: 1 }], now() + 60);
    let e = await a('GET', `/api/servers/${id}/economy`); ok(e.ok && e.online === 2 && e.total === 10000000 + 150 && e.top[0].name === 'Riche' && e.topShare === 100, 'synthèse : totaux et plus riches');
    ok(e.history.length === 1 && e.history[0].players === 2, 'historique : une photo toutes les 30 min');
    ok((await b('GET', `/api/servers/${id}/economy`)).ok === false, 'économie privée');
    const T0 = 1e6; const rows = [...[0, 1].map(i => ({ at: T0 - 8 * 86400 + i * 3600, players: 10, money: 1000, bank: 0 })), ...[0, 1].map(i => ({ at: T0 - 3600 * i, players: 10, money: 2000, bank: 0 }))];
    ok(EC.inflation(rows, T0).level === 'inflation' && EC.inflation(rows, T0).pct === 100, 'inflation détectée (+100 %)'); ok(!EC.inflation(rows.slice(2), T0).known, 'pas assez de données : inconnu');
    // ── export / import ──
    await a('PUT', `/api/servers/${id}/settings`, { values: { npc_density: 0.5 } });
    const ex = await a('GET', `/api/servers/${id}/settings/export`); ok(ex.ok && ex.file.format === 'aero-settings' && ex.file.values.npc_density === 0.5, 'export des réglages');
    ok((await b('GET', `/api/servers/${id}/settings/export`)).ok === false, 'export privé');
    ok((await a('POST', `/api/servers/${id}/settings/import`, { file: { format: 'autre', values: {} } })).ok === false, 'fichier étranger refusé');
    const f = { ...ex.file, server: 'Autre', values: { npc_density: 0.2, game_mode: 'facile', inconnu: 1, discord_webhook: 'https://evil' } };
    let pv = await a('POST', `/api/servers/${id}/settings/import`, { file: f }); ok(pv.ok && pv.preview && pv.diff.length === 2 && pv.unknown[0] === 'inconnu' && pv.secret[0] === 'discord_webhook', 'aperçu : 2 changements, inconnus et secrets ignorés');
    ok((await a('GET', `/api/servers/${id}/settings`)).ok && JSON.stringify((await a('GET', `/api/servers/${id}/settings`))).includes('0.5'), 'l’aperçu ne change rien');
    ok((await a('POST', `/api/servers/${id}/settings/import`, { file: { ...f, values: { game_mode: 'nimporte' } } })).ok === false, 'valeur invalide refusée');
    pv = await a('POST', `/api/servers/${id}/settings/import`, { file: f, apply: true }); ok(pv.ok && pv.changed === 2, 'import appliqué');
    ok((await a('GET', `/api/servers/${id}/settings/history`)).rows[0].source.startsWith('import'), 'import noté dans l’historique');
    // ── planificateur : profil ──
    ok((await a('POST', `/api/servers/${id}/schedules`, { name: 'Mode RP', type: 'settings_profile', payload: { profile: 'inexistant' }, run_at: now() + 3600, every: 'none', warn_min: 0 })).ok === false, 'profil inconnu refusé');
    const sc = await a('POST', `/api/servers/${id}/schedules`, { name: 'Mode RP', type: 'settings_profile', payload: { profile: 'rp' }, run_at: now() + 3600, every: 'none', warn_min: 0 }); ok(sc.ok, 'changement de profil programmé');
    ok(require('../lib/enqueue').enqueue(id, 'settings_profile', { profile: 'debutant' }, 1).ok && JSON.stringify((await a('GET', `/api/servers/${id}/settings`))).includes('facile'), 'le profil est appliqué par le planificateur');
    // ── candidatures ──
    ok((await realFetch(base + '/api/public/apply/nimportequoi')).status === 404, 'formulaire inconnu : introuvable');
    ok((await a('PUT', `/api/servers/${id}/recruit`, { open: true, jobs: [] })).ok === false, 'au moins un poste');
    const rc = await a('PUT', `/api/servers/${id}/recruit`, { open: true, title: 'Police', jobs: ['Police', 'EMS'], questions: ['Pourquoi ?', 'Expérience ?'], channelId: ch.id }); ok(rc.ok && rc.token, 'formulaire ouvert');
    const P = (body) => pub('POST', `/api/public/apply/${rc.token}`, body);
    let g = await pub('GET', `/api/public/apply/${rc.token}`); ok(g.ok && g.form.jobs.length === 2 && !JSON.stringify(g).includes(rc.token) && !JSON.stringify(g).includes('license'), 'formulaire public sans données sensibles');
    ok((await P({ name: 'J', job: 'Police', answers: ['aaa', 'bbb'] })).ok === false, 'nom trop court');
    ok((await P({ name: 'Jean Dupont', job: 'Mafia', answers: ['aaa', 'bbb'] })).ok === false, 'poste inconnu refusé');
    ok((await P({ name: 'Jean Dupont', job: 'Police', answers: ['aaa', ''] })).ok === false, 'toutes les questions obligatoires');
    sent.length = 0; ok((await P({ name: 'Jean Dupont', discord: 'jean#1', job: 'Police', answers: ['Parce que', 'Oui beaucoup'] })).ok, 'candidature envoyée');
    await new Promise(r => setTimeout(r, 50)); ok(sent.length === 1 && /Nouvelle candidature/.test(sent[0].embeds[0].title), 'notification Discord');
    ok((await P({ name: 'jean dupont', job: 'Police', answers: ['aaa', 'bbb'] })).ok === false, 'doublon en cours refusé');
    let ls = await a('GET', `/api/servers/${id}/recruit`); ok(ls.apps.length === 1 && ls.apps[0].answers[0].q === 'Pourquoi ?', 'candidature visible dans le panel');
    ok((await b('GET', `/api/servers/${id}/recruit`)).ok === false && (await b('PATCH', `/api/servers/${id}/recruit/${ls.apps[0].id}`, { status: 'accepted' })).ok === false, 'candidatures privées');
    ok((await a('PATCH', `/api/servers/${id}/recruit/${ls.apps[0].id}`, { status: 'accepted' })).ok && (await a('GET', `/api/servers/${id}/recruit`)).apps[0].status === 'accepted', 'candidature acceptée');
    await a('PUT', `/api/servers/${id}/recruit`, { open: false, jobs: ['Police'], questions: [] }); ok((await P({ name: 'Autre', job: 'Police', answers: [] })).ok === false, 'formulaire fermé : refusé');
    const hh = await (await realFetch(base + '/apply.html')).text(); ok(!/<script(?![^>]*src)/.test(hh), 'page de candidature sans script en ligne (CSP)');
  } catch (e) { console.error('ÉCHEC :', e.stack); process.exitCode = 1; }
  console.log(process.exitCode ? '' : `\n${n} vérifications OK`); srv.close(); setTimeout(() => process.exit(process.exitCode || 0), 200);
});
