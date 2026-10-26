// Carte live, éditeur de base (métiers / objets), événements programmés, assistant IA qui agit : node tools/selftest3.js
process.env.DATA_DIR = './data-test3'; process.env.ADMIN_EMAIL = 'admin@test.fr'; process.env.ADMIN_PASSWORD = 'AdminTest!123'; process.env.ANTHROPIC_API_KEY = 'sk-test'; process.env.AI_DAILY_LIMIT = '50';
const fs = require('fs'), http = require('http'), assert = require('assert'); fs.rmSync(__dirname + '/../data-test3', { recursive: true, force: true });
let aiReply = {};   // ce que la fausse IA répond au prochain appel
const ai = http.createServer((req, res) => { let b = ''; req.on('data', d => b += d); req.on('end', () => { ai.last = JSON.parse(b); res.setHeader('content-type', 'application/json'); res.end(JSON.stringify({ content: [{ type: 'text', text: typeof aiReply === 'string' ? aiReply : JSON.stringify(aiReply) }] })); }); }).listen(0);
process.env.AI_BASE_URL = 'http://127.0.0.1:' + ai.address().port;
const app = require('../server'); const { db } = require('../lib/db'); const sched = require('../lib/scheduler');
const ITEMS = `-- en-tête\nreturn {\n    ['money'] = { label = 'Argent', weight = 0, stack = true, close = false },\n    ['bread'] = { label = 'Pain', weight = 100, stack = true, close = true }, -- nourriture\n    ['water'] = { label = "L'eau", weight = 100, stack = true, close = true },\n    ['phone'] = { label = 'Téléphone', weight = 190, stack = false, close = true, client = { export = 'x.y' } },\n}\n`;
const srv = http.createServer(app).listen(0, async () => {
  const base = 'http://127.0.0.1:' + srv.address().port; const jar = {}; let n = 0;
  const mk = name => { jar[name] = ''; return async (m, u, body) => { const r = await fetch(base + u, { method: m, headers: { 'content-type': 'application/json', origin: base, cookie: jar[name] }, body: m === 'GET' ? undefined : JSON.stringify(body || {}) }); const c = r.headers.get('set-cookie'); if (c) jar[name] = c.split(';')[0]; return r.json(); }; };
  const admin = mk('a'), client = mk('c'), other = mk('o'); const ok = (c, m) => { assert(c, m); n++; console.log('  ✓', m); };
  const KEY = 'AERO-TEST3'; let items = ITEMS; const jobs = [{ name: 'police', label: 'Police', whitelisted: true, grades: [{ grade: 0, name: 'recruit', label: 'Recrue', salary: 300 }] }]; const got = []; let polling = true;
  const H = { 'content-type': 'application/json', 'x-license-key': KEY };
  const agent = (async () => { let results = []; while (polling) { const r = await fetch(base + '/api/agent/poll', { method: 'POST', headers: H, body: JSON.stringify({ results }) }).then(x => x.json()).catch(() => ({ commands: [] })); results = [];
    for (const c of r.commands || []) { const p = c.payload; got.push(c);
      if (c.type === 'fs.read') results.push({ id: c.id, ok: true, result: 'ok', data: { content: items } });
      else if (c.type === 'fs.write') { items = p.content; results.push({ id: c.id, ok: true, result: 'ok', data: { message: 'écrit' } }); }
      else if (c.type === 'db.jobs') results.push({ id: c.id, ok: true, result: 'ok', data: { jobs } });
      else if (c.type === 'db.job_save') { const i = jobs.findIndex(j => j.name === p.job.name); if (i >= 0) jobs[i] = p.job; else jobs.push(p.job); results.push({ id: c.id, ok: true, result: 'ok', data: { message: 'métier mis à jour' } }); }
      else results.push({ id: c.id, ok: true, result: 'ok' }); } } })();
  try {
    await admin('POST', '/api/auth/login', { email: 'admin@test.fr', password: 'AdminTest!123' }); await client('POST', '/api/auth/register', { email: 'c@test.fr', username: 'Cli', password: 'ClientTest!1' }); await other('POST', '/api/auth/register', { email: 'o@test.fr', username: 'Oth', password: 'ClientTest!1' });
    const cid = (await admin('GET', '/api/admin/users')).users.find(u => u.email === 'c@test.fr').id;
    db.prepare("INSERT INTO licenses(key,user_id,plan_id,server_name,status,expires_at,created_at) VALUES(?,?,2,'S3','active',NULL,strftime('%s','now'))").run(KEY, cid); const lid = db.prepare('SELECT id FROM licenses WHERE key=?').get(KEY).id;
    const sync = players => fetch(base + '/api/agent/sync', { method: 'POST', headers: H, body: JSON.stringify({ players, resources: [], settingsSchema: [{ key: 'announce_interval', group: 'Général', label: 'Annonces', type: 'number', default: 300, min: 30, max: 3600 }] }) }).then(r => r.json());
    await sync([{ id: 7, name: 'Maly', identifier: 'license:abc', job: 'police', grade: 0, ping: 30, x: 195.34, y: -934.2, h: 90.4, veh: true }, { id: 9, name: 'Sans pos', identifier: 'license:def' }]);

    console.log('Carte live');
    let pl = (await client('GET', `/api/servers/${lid}/players`)).players;
    ok(pl[0].x === 195.3 && pl[0].y === -934.2 && pl[0].h === 90 && pl[0].veh === true, 'les positions (x, y, cap, véhicule) sont conservées');
    ok(pl[1].x === null && pl[1].y === null, 'un joueur sans position reste valide');
    let t = await client('POST', `/api/servers/${lid}/command`, { type: 'teleport', payload: { id: 7, x: 215.5, y: -810 } }); ok(t.ok, 'téléportation vers un point de la carte acceptée');
    t = await client('POST', `/api/servers/${lid}/command`, { type: 'teleport', payload: { id: 7, x: 99999, y: 0 } }); ok(!t.ok, 'téléportation hors de la carte refusée');
    t = await client('POST', `/api/servers/${lid}/command`, { type: 'teleport', payload: { id: 'x', x: 1, y: 1 } }); ok(!t.ok, 'téléportation sans joueur valide refusée');

    console.log('Éditeur de base : objets');
    let it = await client('GET', `/api/servers/${lid}/base/items`); ok(it.ok && it.items.length === 3 && it.other === 1, `3 objets simples listés, 1 complexe laissé de côté (${it.items.length}/${it.other})`);
    ok(it.items.find(x => x.name === 'water').label === "L'eau", 'libellé entre guillemets lu correctement');
    let sv = await client('POST', `/api/servers/${lid}/base/items`, { changes: [{ name: 'bread', label: "Pain d'or", weight: 250 }, { name: 'money', close: true }] });
    ok(sv.ok && sv.changed === 2, 'modification enregistrée');
    ok(items.includes("['bread'] = { label = 'Pain d\\'or', weight = 250, stack = true, close = true }, -- nourriture") && items.includes('close = true },\n    [\'bread\']') && items.includes("client = { export = 'x.y' }") && items.startsWith('-- en-tête'), 'seule la ligne visée change (commentaire, objet complexe et en-tête intacts)');
    sv = await client('POST', `/api/servers/${lid}/base/items`, { add: [{ name: 'sandwich', label: 'Sandwich', weight: 150 }] });
    ok(sv.ok && /\['sandwich'\] = \{ label = 'Sandwich', weight = 150, stack = true, close = true \},\n\}\n$/.test(items), 'nouvel objet ajouté avant la fin du tableau');
    ok(!(await client('POST', `/api/servers/${lid}/base/items`, { add: [{ name: 'bread', label: 'x', weight: 1 }] })).ok, 'doublon refusé');
    ok(!(await client('POST', `/api/servers/${lid}/base/items`, { add: [{ name: "a'b", label: 'x', weight: 1 }] })).ok && !(await client('POST', `/api/servers/${lid}/base/items`, { changes: [{ name: 'bread', weight: -5 }] })).ok, 'noms et poids invalides refusés');
    ok(db.prepare("SELECT COUNT(*) n FROM file_versions WHERE license_id=? AND path LIKE '%items.lua'").get(lid).n >= 2, 'chaque enregistrement crée une version restaurable');

    console.log('Éditeur de base : métiers');
    const jb = await client('GET', `/api/servers/${lid}/base/jobs`); ok(jb.ok && jb.jobs[0].grades[0].salary === 300, 'métiers et salaires lus depuis le serveur');
    let js = await client('POST', `/api/servers/${lid}/base/jobs`, { job: { name: 'taxi', label: 'Taxi', whitelisted: false, grades: [{ grade: 0, name: 'driver', label: 'Chauffeur', salary: 450 }, { grade: 1, name: 'boss', label: 'Patron', salary: 900 }] } });
    ok(js.ok && jobs.find(j => j.name === 'taxi').grades.length === 2, 'nouveau métier créé avec ses grades');
    ok(!(await client('POST', `/api/servers/${lid}/base/jobs`, { job: { name: 'Bad Name', label: 'x', grades: [{ grade: 0, name: 'a', label: 'a', salary: 1 }] } })).ok, 'nom de métier invalide refusé');
    ok(!(await client('POST', `/api/servers/${lid}/base/jobs`, { job: { name: 'x', label: 'x', grades: [{ grade: 0, name: 'a', label: 'a', salary: 1 }, { grade: 0, name: 'b', label: 'b', salary: 2 }] } })).ok, 'grades en double refusés');
    ok(!(await client('POST', `/api/servers/${lid}/base/jobs`, { job: { name: 'x', label: 'x', grades: [{ grade: 0, name: 'a', label: 'a', salary: 99999999 }] } })).ok, 'salaire démesuré refusé');
    ok(!(await other('GET', `/api/servers/${lid}/base/jobs`)).ok && !(await other('POST', `/api/servers/${lid}/base/items`, { add: [{ name: 'z', label: 'z', weight: 1 }] })).ok, 'un autre client n’a accès à rien');

    console.log('Événements programmés');
    const now = () => Math.floor(Date.now() / 1000); const cm = () => db.prepare("SELECT type,payload FROM commands WHERE license_id=? AND type IN ('announce','server_restart') ORDER BY id").all(lid);
    ok(!(await client('POST', `/api/servers/${lid}/schedules`, { name: 'x', type: 'console', payload: { cmd: 'quit' }, run_at: now() + 600 })).ok, 'une action non programmable (console) est refusée');
    ok(!(await client('POST', `/api/servers/${lid}/schedules`, { name: 'passé', type: 'announce', payload: { message: 'a' }, run_at: now() - 7200 })).ok, 'une date passée est refusée');
    const s1 = await client('POST', `/api/servers/${lid}/schedules`, { name: 'Annonce du soir', type: 'announce', payload: { message: 'Bienvenue !' }, run_at: now() + 3600, every: 'daily', warn_min: 0 }); ok(s1.ok, 'annonce quotidienne créée');
    const s2 = await client('POST', `/api/servers/${lid}/schedules`, { name: 'Restart', type: 'server_restart', payload: {}, run_at: now() + 3600, every: 'none', warn_min: 10 }); ok(s2.ok, 'redémarrage avec préavis de 10 min créé');
    sched.tick(); ok(cm().length === 0, 'rien ne part avant l’heure');
    db.prepare('UPDATE schedules SET run_at=? WHERE id=?').run(now() + 300, s2.id); sched.tick(); const c1 = cm(); ok(c1.length === 1 && c1[0].type === 'announce' && /Redémarrage du serveur dans 10 minutes/.test(c1[0].payload), 'le préavis est annoncé automatiquement');
    sched.tick(); ok(cm().length === 1, 'le préavis n’est envoyé qu’une fois');
    db.prepare('UPDATE schedules SET run_at=? WHERE id=?').run(now() - 5, s1.id); sched.tick(); const c2 = cm(); ok(c2.some(c => c.type === 'announce' && /Bienvenue/.test(c.payload)), 'l’annonce part à l’heure');
    const r1 = db.prepare('SELECT * FROM schedules WHERE id=?').get(s1.id); ok(r1.enabled === 1 && r1.run_at > now() + 80000 && r1.last_status === 'envoyé', 'un événement quotidien est reprogrammé à J+1');
    db.prepare('UPDATE schedules SET run_at=? WHERE id=?').run(now() - 5, s2.id); sched.tick(); ok(cm().some(c => c.type === 'server_restart') && db.prepare('SELECT enabled FROM schedules WHERE id=?').get(s2.id).enabled === 0, 'un événement unique s’exécute puis se désactive');
    const s3 = await client('POST', `/api/servers/${lid}/schedules`, { name: 'Manqué', type: 'announce', payload: { message: 'm' }, run_at: now() + 600 }); db.prepare('UPDATE schedules SET run_at=? WHERE id=?').run(now() - 3600, s3.id);
    const before = cm().length; sched.tick(); ok(cm().length === before && /manqué/.test(db.prepare('SELECT last_status FROM schedules WHERE id=?').get(s3.id).last_status), 'un événement en retard de plus de 15 min est marqué « manqué » et non exécuté');
    const s4 = await client('POST', `/api/servers/${lid}/schedules`, { name: 'Hors ligne', type: 'announce', payload: { message: 'h' }, run_at: now() + 600 });
    const b4 = cm().length; db.prepare('UPDATE licenses SET last_seen=? WHERE id=?').run(now() - 600, lid); db.prepare('UPDATE schedules SET run_at=? WHERE id=?').run(now() - 30, s4.id); sched.tick(); ok(cm().length === b4 && db.prepare('SELECT enabled FROM schedules WHERE id=?').get(s4.id).enabled === 1, 'serveur hors ligne : l’événement attend son retour (15 min)');
    const pa = await client('PATCH', `/api/servers/${lid}/schedules/${s4.id}`, { enabled: false }); const de = await client('DELETE', `/api/servers/${lid}/schedules/${s4.id}`); ok(pa.ok && de.ok, 'désactivation et suppression');
    ok(!(await other('DELETE', `/api/servers/${lid}/schedules/${s1.id}`)).ok || db.prepare('SELECT 1 FROM schedules WHERE id=?').get(s1.id), 'un autre client ne peut pas supprimer ces événements');
    await sync([]);   // le serveur est de nouveau en ligne

    console.log('Assistant IA');
    const tz = -120;   // UTC+2 (getTimezoneOffset)
    const d10 = new Date(Date.now() + 10 * 86400000), Y = d10.getUTCFullYear(), M = d10.getUTCMonth(), D = d10.getUTCDate(), when = `${Y}-${String(M + 1).padStart(2, '0')}-${String(D).padStart(2, '0')} 20:00`;
    aiReply = { reply: 'Voilà.', actions: [
      { label: 'Annonce', type: 'announce', payload: { message: 'Double paie ce soir !' } },
      { label: 'Double paie', type: 'economy_event', payload: { key: 'all', swing: 1, hours: 4 } },
      { label: 'Programmer', type: 'schedule', payload: { name: 'Double paie samedi', type: 'economy_event', payload: { key: 'all', swing: 1, hours: 4 }, when, every: 'weekly', warn_min: 15 } },
      { label: 'Réglage', type: 'set_setting', payload: { key: 'announce_interval', value: 120 } },
      { label: 'DANGER', type: 'givemoney', payload: { id: 7, amount: 9999999, account: 'bank' } },
      { label: 'Réglage bidon', type: 'set_setting', payload: { key: 'inconnu', value: 1 } },
      { label: 'Valeur hors limites', type: 'set_setting', payload: { key: 'announce_interval', value: 99999 } }] };
    let a = await client('POST', `/api/servers/${lid}/assistant`, { message: 'fais une double paie', tz, local_now: '2099-01-05 18:00' });
    ok(a.ok && a.reply === 'Voilà.' && a.actions.length === 4, `4 actions valides gardées sur 7 (${a.actions && a.actions.length})`);
    ok(!a.actions.some(x => x.type === 'givemoney') && a.dropped.length === 2, 'les actions non autorisées ou invalides sont écartées (et seules les 6 premières sont étudiées)');
    ok(/2099-01-05 18:00/.test(ai.last.system) && /announce_interval/.test(ai.last.system), 'l’IA reçoit l’heure locale et la liste des réglages');
    const sch = a.actions.find(x => x.type === 'schedule'); ok(sch.payload.run_at === Date.UTC(Y, M, D, 20, 0) / 1000 - 2 * 3600, 'la date locale est convertie en heure serveur (fuseau pris en compte)');
    const cmds0 = db.prepare('SELECT COUNT(*) n FROM commands WHERE license_id=?').get(lid).n; ok(true, 'rien n’est exécuté tant que le client ne valide pas'); void cmds0;
    const ap = x => client('POST', `/api/servers/${lid}/assistant/apply`, { type: x.type, payload: x.payload });
    ok((await ap(a.actions[0])).ok && db.prepare("SELECT payload FROM commands WHERE license_id=? AND type='announce' ORDER BY id DESC").get(lid).payload.includes('Double paie'), 'appliquer une annonce l’envoie au serveur');
    ok((await ap(a.actions[1])).ok, 'appliquer un événement d’économie');
    ok((await ap(sch)).ok && db.prepare("SELECT every,warn_min FROM schedules WHERE license_id=? AND name='Double paie samedi'").get(lid).every === 'weekly', 'appliquer une programmation la crée dans le planning');
    ok((await ap(a.actions.find(x => x.type === 'set_setting'))).ok && JSON.parse(db.prepare("SELECT value FROM docs WHERE license_id=? AND key='settings'").get(lid).value).announce_interval === 120, 'appliquer un réglage le sauvegarde');
    ok(!(await client('POST', `/api/servers/${lid}/assistant/apply`, { type: 'givemoney', payload: { id: 7, amount: 1, account: 'bank' } })).ok && !(await client('POST', `/api/servers/${lid}/assistant/apply`, { type: 'set_setting', payload: { key: 'announce_interval', value: 5 } })).ok, 'une action trafiquée côté navigateur est refusée à l’application');
    ok(!(await other('POST', `/api/servers/${lid}/assistant`, { message: 'x' })).ok && !(await other('POST', `/api/servers/${lid}/assistant/apply`, { type: 'announce', payload: { message: 'x' } })).ok, 'un autre client ne peut ni demander ni appliquer');
    aiReply = 'Désolé, je ne comprends pas (texte libre).'; a = await client('POST', `/api/servers/${lid}/assistant`, { message: 'blabla' }); ok(a.ok && a.actions.length === 0 && /Désolé/.test(a.reply), 'une réponse libre sans JSON reste exploitable');
    aiReply = '```json\n{"reply":"ok","actions":[{"label":"x","type":"announce","payload":{"message":"yo"}}]}\n```'; a = await client('POST', `/api/servers/${lid}/assistant`, { message: 'annonce yo' }); ok(a.ok && a.actions.length === 1, 'un JSON entouré de balises de code est lu');
  } catch (e) { console.error('ÉCHEC :', e.message); process.exitCode = 1; }
  polling = false; console.log(process.exitCode ? '' : `\n${n} vérifications OK`); srv.close(); ai.close(); setTimeout(() => { fs.rmSync(__dirname + '/../data-test3', { recursive: true, force: true }); process.exit(process.exitCode || 0); }, 300);
});
