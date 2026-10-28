// Plaintes, rétention, sauvegardes de la base : node tools/selftest9.js
process.env.DATA_DIR = './data-test9'; process.env.ADMIN_EMAIL = 'admin@test.fr'; process.env.ADMIN_PASSWORD = 'AdminTest!123'; process.env.ALLOW_REGISTER = 'true';
const fs = require('fs'), http = require('http'), assert = require('assert'), zlib = require('zlib'); fs.rmSync(__dirname + '/../data-test9', { recursive: true, force: true });
const realFetch = global.fetch; const sent = [];
global.fetch = (url, opts) => { if (String(url).startsWith('https://discord.com/api/webhooks/')) { sent.push(JSON.parse(opts.body)); return Promise.resolve({ status: 200, ok: true }); } return realFetch(url, opts); };
const app = require('../server'); const RT = require('../lib/retention'); const { db, now } = require('../lib/db');
const srv = http.createServer(app).listen(0, async () => {
  const base = 'http://127.0.0.1:' + srv.address().port; let n = 0; const ok = (c, m) => { assert(c, m); n++; console.log('  ✓', m); };
  const mk = () => { let cookie = ''; return async (m, u, body, extra = {}) => { const r = await realFetch(base + u, { method: m, headers: { 'content-type': 'application/json', origin: base, cookie, ...extra }, body: m === 'GET' ? undefined : JSON.stringify(body || {}) }); const sc = r.headers.get('set-cookie'); if (sc) cookie = sc.split(';')[0]; const ct = r.headers.get('content-type') || ''; return ct.includes('json') ? r.json() : { raw: Buffer.from(await r.arrayBuffer()), status: r.status }; }; };
  try {
    const admin = mk(), a = mk(), b = mk(), ag = mk();
    await admin('POST', '/api/auth/login', { email: 'admin@test.fr', password: 'AdminTest!123' });
    await a('POST', '/api/auth/register', { email: 'a@t.fr', username: 'Alice', password: 'ClientTest!1' }); await b('POST', '/api/auth/register', { email: 'b@t.fr', username: 'Bob', password: 'ClientTest!1' });
    const users = (await admin('GET', '/api/admin/users')).users, plans = (await admin('GET', '/api/admin/plans')).plans;
    const lic = await admin('POST', '/api/admin/licenses', { user_id: users.find(u => u.email === 'a@t.fr').id, plan_id: plans[1].id, server_name: 'Mon serveur' }); const id = lic.id, H = { 'x-license-key': lic.key };
    // ── plaintes ──
    const hook = 'https://discord.com/api/webhooks/123456789012345678/SecretTokenABCDEFGH'; const ch = await a('POST', `/api/servers/${id}/discord/channels`, { name: 'alertes', url: hook });
    await a('PUT', `/api/servers/${id}/discord/alerts`, { enabled: true, channelId: ch.id, offline: false, errors: false, rich: false, reports: true });
    sent.length = 0;
    await ag('POST', '/api/agent/sync', { players: [], reports: [{ at: now(), reporter: 'Jean', reporter_id: 5, reporter_ident: 'license:abc', target: 'Luc', target_ident: 'license:xyz', message: 'Il m\'a tué sans raison !', x: 120.55, y: -40.2 }, { reporter: 'Court', message: 'x' }, 'n\'importe quoi'] }, H);
    let rp = await a('GET', `/api/servers/${id}/reports`); ok(rp.ok && rp.rows.length === 1 && rp.newCount === 1 && rp.rows[0].target === 'Luc' && rp.rows[0].x === 120.6, 'plainte reçue du jeu (message trop court et données invalides ignorés)');
    await new Promise(r => setTimeout(r, 50)); ok(sent.length === 1 && /plainte/i.test(sent[0].embeds[0].title) && /Luc/.test(sent[0].embeds[0].description), 'notification Discord de la plainte');
    ok((await b('GET', `/api/servers/${id}/reports`)).ok === false && (await b('PATCH', `/api/servers/${id}/reports/${rp.rows[0].id}`, { status: 'handled' })).ok === false, 'plaintes privées à chaque client');
    ok((await a('PATCH', `/api/servers/${id}/reports/${rp.rows[0].id}`, { status: 'handled', note: 'Sanctionné : 3 jours' })).ok, 'plainte traitée avec une note');
    rp = await a('GET', `/api/servers/${id}/reports?status=new`); ok(rp.rows.length === 0 && rp.newCount === 0, 'filtre « à traiter »');
    rp = await a('GET', `/api/servers/${id}/reports`); ok(rp.rows[0].status === 'handled' && rp.rows[0].note === 'Sanctionné : 3 jours', 'statut et note enregistrés');
    await a('PUT', `/api/servers/${id}/discord/alerts`, { enabled: true, channelId: ch.id, offline: false, errors: false, rich: false, reports: false }); sent.length = 0;
    await ag('POST', '/api/agent/sync', { players: [], reports: [{ reporter: 'Jean', message: 'Deuxième plainte valide' }] }, H); await new Promise(r => setTimeout(r, 50));
    ok(sent.length === 0, 'option « plaintes » décochée : pas de notification Discord');
    await a('DELETE', `/api/servers/${id}/reports/${(await a('GET', `/api/servers/${id}/reports`)).rows[0].id}`); ok((await a('GET', `/api/servers/${id}/reports`)).rows.length === 1, 'plainte supprimée');
    // ── rétention (calcul pur) ──
    const at = 100 * 86400, D = 86400;
    const rows = [{ name: 'A', minutes: 600, sessions: 12, first_seen: at - 20 * D, last_seen: at - 1 * D }, { name: 'B', minutes: 30, sessions: 1, first_seen: at - 10 * D, last_seen: at - 10 * D + 600 }, { name: 'C', minutes: 200, sessions: 4, first_seen: at - 3 * D, last_seen: at - 2 * D }, { name: 'D', minutes: 5, sessions: 1, first_seen: at - 0.5 * D, last_seen: at - 0.4 * D }];
    ok(RT.returnRate(rows, 1, at).pct === 67 && RT.returnRate(rows, 1, at).cohort === 3, 'retour après 1 jour : 2 sur 3 (le joueur de moins d\'un jour n\'est pas compté)');
    ok(RT.returnRate(rows, 7, at).pct === 50 && RT.returnRate(rows, 7, at).cohort === 2, 'retour après 7 jours : 1 sur 2');
    ok(RT.returnRate(rows, 30, at).known === false, 'pas assez de recul : inconnu');
    const pts = [{ at: 3600 * 20, players: 10 }, { at: 3600 * 20 + 300, players: 20 }, { at: 3600 * 3, players: 4 }];
    const hr = RT.hourly(pts); ok(hr.length === 24 && hr[20] === 15 && hr[3] === 4 && hr[0] === 0, 'affluence par heure UTC (moyennes)');
    const nd = RT.newPerDay(rows, 14, at); ok(nd.length === 14 && nd.reduce((s, d) => s + d.n, 0) === 3 && nd[12].n === 1, 'nouveaux joueurs par jour (14 derniers jours seulement)');
    const sm = RT.summary(rows, pts, at); ok(sm.total === 4 && sm.active7 === 3 && sm.active30 === 4 && sm.top[0].name === 'A', 'synthèse : actifs 7 / 30 jours et plus assidus');
    // ── rétention (route) ──
    db.prepare("INSERT INTO player_stats(license_id,identifier,name,minutes,sessions,first_seen,last_seen,online) VALUES(?,?,?,?,?,?,?,0)").run(id, 'license:a1', 'Alpha', 120, 3, now() - 5 * D, now() - 1 * D);
    const rr = await a('GET', `/api/servers/${id}/retention`); ok(rr.ok && rr.total >= 1 && rr.hours.length === 24 && rr.newPerDay.length === 14, 'route rétention');
    ok((await b('GET', `/api/servers/${id}/retention`)).ok === false, 'rétention privée');
    // ── sauvegarde de la base : l'agent simulé répond aux RPC ──
    const answer = async () => { const s = await ag('POST', '/api/agent/sync', { players: [] }, H); const results = [];
      for (const c of s.commands || []) {
        if (c.type === 'db.tables') results.push({ id: c.id, ok: true, result: 'ok', data: { tables: [{ name: 'jobbuilder_jobs', rows: 2 }, { name: 'gangbuilder_gangs', rows: 1 }, { name: 'pickax_auctions', rows: 0 }] } });
        else if (c.type === 'db.export') results.push({ id: c.id, ok: true, result: 'ok', data: { tables: Object.fromEntries(c.payload.tables.map(t => [t, { rows: [{ name: 'x', t }] }])) } });
        else results.push({ id: c.id, ok: false, result: 'inattendu' });
      }
      if (results.length) await ag('POST', '/api/agent/sync', { results }, H); return results.length; };
    const pending = a('POST', `/api/servers/${id}/dbbackups`, { name: 'Test' }); let total = 0; for (let i = 0; i < 20 && total < 2; i++) { total += await answer(); await new Promise(r => setTimeout(r, 40)); }
    const bk = await pending; ok(bk.ok && bk.tables === 3, 'sauvegarde de la base créée via le serveur de jeu (3 tables)');
    const list = await a('GET', `/api/servers/${id}/dbbackups`); ok(list.backups.length === 1 && list.backups[0].name === 'Test' && list.backups[0].tables === 3, 'liste des sauvegardes');
    const dl = await a('GET', `/api/servers/${id}/dbbackups/${list.backups[0].id}/download`); const dump = JSON.parse(zlib.gunzipSync(dl.raw).toString());
    ok(dump.format === 'aero-db' && dump.tables.jobbuilder_jobs[0].name === 'x' && Object.keys(dump.tables).length === 3, 'fichier téléchargé : JSON compressé avec les tables');
    ok((await b('GET', `/api/servers/${id}/dbbackups/${list.backups[0].id}/download`)).status === 404 || (await b('GET', `/api/servers/${id}/dbbackups`)).ok === false, 'sauvegardes privées');
    ok((await a('POST', `/api/servers/${id}/dbbackups`, {})).error.includes('patiente'), 'une sauvegarde par minute au maximum');
    const C = require('../lib/commands'); ok(C.validateRpc('db.export', { tables: ['jobbuilder_jobs'] }).payload && C.validateRpc('db.export', { tables: ['a;DROP TABLE x'] }).error && C.validateRpc('db.export', { tables: [] }).error && C.validateRpc('db.export', { tables: Array.from({ length: 9 }, (_, i) => 't' + i) }).error, 'export : noms de tables validés (pas d\'injection, 8 max)');
    await a('DELETE', `/api/servers/${id}/dbbackups/${list.backups[0].id}`); ok((await a('GET', `/api/servers/${id}/dbbackups`)).backups.length === 0, 'sauvegarde supprimée');
  } catch (e) { console.error('ÉCHEC :', e.stack); process.exitCode = 1; }
  console.log(process.exitCode ? '' : `\n${n} vérifications OK`); srv.close(); setTimeout(() => process.exit(process.exitCode || 0), 200);
});
