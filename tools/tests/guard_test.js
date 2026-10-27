// Teste pickax_guard contre le VRAI panel (signatures Ed25519, nonce, IP, expiration) : node tools/tests/guard_test.js
const path = require('path'), fs = require('fs'), http = require('http'), crypto = require('crypto'), assert = require('assert'), { spawn } = require('child_process');
const ROOT = path.join(__dirname, '..', '..'); process.chdir(path.join(ROOT, 'panel'));
process.env.DATA_DIR = '/tmp/guard-test-data'; process.env.ADMIN_EMAIL = 'a@t.fr'; process.env.ADMIN_PASSWORD = 'AdminTest!123'; fs.rmSync('/tmp/guard-test-data', { recursive: true, force: true });
const app = require(path.join(ROOT, 'panel', 'server')); const { db } = require(path.join(ROOT, 'panel', 'lib', 'db')); const G = require(path.join(ROOT, 'panel', 'lib', 'guard'));
let n = 0; const ok = (c, m) => { assert(c, m); n++; console.log('  ✓', m); };
const runLua = (envv) => new Promise(res => { const dir = fs.mkdtempSync('/tmp/guard-run-'); const p = spawn('lua5.4', [path.join(__dirname, 'guard_harness.lua')], { env: { ...process.env, GUARD_DIR: dir, ...envv } }); let out = ''; p.stdout.on('data', d => out += d); p.stderr.on('data', d => out += d); p.on('close', () => { const m = out.match(/RESULT(.*)/); res(m ? { ...JSON.parse(m[1]), dir } : { error: out, dir }); }); });
const lic = (key, over = {}) => { const uid = db.prepare("SELECT id FROM users WHERE role='admin'").get().id; db.prepare('INSERT INTO licenses(key,user_id,plan_id,server_name,status,expires_at,created_at) VALUES(?,?,2,?,?,?,strftime(\'%s\',\'now\'))').run(key, uid, 'S', over.status || 'active', over.expires || null); if (over.bound) db.prepare('UPDATE licenses SET bound_ip=? WHERE key=?').run(over.bound, key); };
const srv = http.createServer(app).listen(0, async () => {
  const URL = 'http://127.0.0.1:' + srv.address().port, PUB = G.publicKey; const base = { CV_aero_panel_url: URL, PUBKEY: PUB };
  // faux panel : mêmes réponses mais signées par une AUTRE clé (ou rejouées)
  const other = crypto.generateKeyPairSync('ed25519'); const otherPub = other.publicKey.export({ type: 'spki', format: 'der' }).toString('base64');
  const hook = http.createServer((req, res) => { db.prepare("UPDATE licenses SET status='revoked' WHERE key='AERO-REVOKE'").run(); res.end('ok'); }).listen(0);
  let stubMode = 'forged'; let recorded = null;
  const fake = http.createServer((req, res) => { let b = ''; req.on('data', d => b += d); req.on('end', () => { const j = JSON.parse(b || '{}'); const key = String(req.headers['x-license-key']);
    const mk = (nonce, sigKey) => { const payload = JSON.stringify({ v: 1, valid: true, status: 'active', plan: 'Pirate', nonce, kh: G.keyHash(key), iat: Math.floor(Date.now() / 1000), grace: 86400 }); return { ok: true, payload, sig: crypto.sign(null, Buffer.from(payload), sigKey).toString('base64') }; };
    if (stubMode === 'forged') return res.end(JSON.stringify(mk(j.nonce, other.privateKey)));
    if (stubMode === 'replay') return res.end(JSON.stringify(recorded)); res.statusCode = 500; res.end('x'); }); }).listen(0);
  try {
    lic('AERO-GOOD-0001'); lic('AERO-EXPIRED', { expires: 1000 }); lic('AERO-SUSPENDED', { status: 'suspended' }); lic('AERO-BOUND', { bound: '9.9.9.9' });
    console.log('Licence valide');
    let r = await runLua({ ...base, CV_aero_panel_key: 'AERO-GOOD-0001' });
    ok(r.licensed === true && r.status.plan, 'clé valide : base autorisée (plan ' + (r.status.plan || '?') + ')');
    ok(r.cancelled.join() === 'pickax_ui,pickax_core,pickax_jobbuilder', 'démarrage retenu pendant la vérification : ' + r.cancelled.join(', '));
    ok(r.ensured.join() === 'pickax_ui,pickax_core,pickax_jobbuilder', 'puis relancées dans l’ordre d’origine : ' + r.ensured.join(', '));
    ok(r.states.pickax_core === 'started' && r.states.pickax_jobbuilder === 'started', 'ressources protégées démarrées');
    ok(!r.cancelled.includes('pickax_panel') && r.states.pickax_panel === 'started', 'pickax_panel n’est jamais retenu');
    ok(fs.existsSync(r.dir + '/cache.json'), 'réponse signée mémorisée pour tolérer une panne du panel');
    const cached = r.dir;
    r = await runLua({ ...base, CV_aero_panel_key: 'AERO-GOOD-0001', HOLD: '0', PRESTARTED: 'pickax_core,pickax_jobbuilder' });
    ok(r.licensed === true && r.cancelled.length === 0 && r.stopped.length === 0 && r.states.pickax_core === 'started', 'HoldStart=false : aucun démarrage annulé (console propre), tout démarre');
    r = await runLua({ ...base, CV_aero_panel_key: 'AERO-EXPIRED', HOLD: '0', PRESTARTED: 'pickax_core' });
    ok(r.licensed === false && r.cancelled.length === 0 && r.states.pickax_core === 'stopped', 'HoldStart=false + licence refusée : les ressources lancées sont arrêtées quand même');
    console.log('Licence refusée');
    r = await runLua({ ...base }); ok(r.licensed === false && r.states.pickax_core === 'stopped' && r.states.pickax_jobbuilder === 'stopped', 'aucune clé : rien ne démarre'); ok(r.prints.some(p => /Aucune clé de licence/.test(p)), 'message clair dans la console (clé absente)');
    r = await runLua({ ...base, CV_aero_panel_key: 'AERO-INCONNUE' }); ok(r.licensed === false && r.states.pickax_core === 'stopped' && r.prints.some(p => /inconnue/.test(p)), 'clé inconnue : refusé');
    r = await runLua({ ...base, CV_aero_panel_key: 'AERO-EXPIRED' }); ok(r.licensed === false && r.prints.some(p => /expirée/.test(p)), 'licence expirée : refusé');
    r = await runLua({ ...base, CV_aero_panel_key: 'AERO-SUSPENDED' }); ok(r.licensed === false && r.states.pickax_core === 'stopped', 'licence suspendue : refusé');
    r = await runLua({ ...base, CV_aero_panel_key: 'AERO-BOUND' }); ok(r.licensed === false && r.prints.some(p => /autre adresse IP/.test(p)), 'clé copiée sur un autre serveur (IP différente) : refusé');
    r = await runLua({ ...base, CV_aero_panel_key: 'AERO-GOOD-0001', PUBKEY: '' }); ok(r.licensed === false && r.states.pickax_core === 'stopped' && r.prints.some(p => /PublicKey/.test(p)), 'clé publique absente de la config : la base refuse de démarrer');
    r = await runLua({ ...base, CV_aero_panel_url: '', CV_aero_panel_key: 'AERO-GOOD-0001' }); ok(r.licensed === false, 'adresse du panel absente : refusé');
    console.log('Contournements');
    r = await runLua({ ...base, CV_aero_panel_url: 'http://127.0.0.1:' + fake.address().port, CV_aero_panel_key: 'AERO-PIRATE' }); ok(r.licensed === false && r.states.pickax_core === 'stopped' && r.prints.some(p => /authentique/.test(p)), 'faux panel qui répond « valide » avec une autre signature : refusé');
    // rejeu : on enregistre une vraie réponse puis on la rejoue (nonce différent)
    const real = await fetch(URL + '/api/agent/verify', { method: 'POST', headers: { 'content-type': 'application/json', 'x-license-key': 'AERO-GOOD-0001' }, body: JSON.stringify({ nonce: 'a'.repeat(24) }) }).then(x => x.json()); recorded = real; stubMode = 'replay';
    r = await runLua({ ...base, CV_aero_panel_url: 'http://127.0.0.1:' + fake.address().port, CV_aero_panel_key: 'AERO-GOOD-0001' }); ok(r.licensed === false && r.states.pickax_core === 'stopped', 'vraie réponse rejouée (autre nonce) : refusé');
    ok(JSON.parse(real.payload).kh === G.keyHash('AERO-GOOD-0001'), 'la réponse est liée à la clé (empreinte)');
    stubMode = 'down';
    console.log('Panel injoignable');
    r = await runLua({ ...base, CV_aero_panel_url: 'http://127.0.0.1:1', CV_aero_panel_key: 'AERO-GOOD-0001' }); ok(r.licensed === false && r.states.pickax_core === 'stopped', 'panel injoignable et aucune mémoire : refusé');
    r = await runLua({ ...base, CV_aero_panel_url: 'http://127.0.0.1:1', CV_aero_panel_key: 'AERO-GOOD-0001', GUARD_DIR: cached }); ok(r.licensed === true && r.status.reason === 'cache' && r.states.pickax_core === 'started', 'panel en panne mais vérifié récemment : la base démarre (tolérance de 24 h)');
    r = await runLua({ ...base, CV_aero_panel_url: 'http://127.0.0.1:1', CV_aero_panel_key: 'AERO-GOOD-0001', GUARD_DIR: cached, TIME_SHIFT: String(25 * 3600) }); ok(r.licensed === false && r.states.pickax_core === 'stopped', 'panel en panne depuis plus de 24 h : la base ne démarre plus');
    r = await runLua({ ...base, CV_aero_panel_url: 'http://127.0.0.1:1', CV_aero_panel_key: 'AERO-AUTRE-CLE', GUARD_DIR: cached }); ok(r.licensed === false, 'le cache d’une autre clé n’est pas accepté');
    r = await runLua({ ...base, CV_aero_panel_url: 'http://127.0.0.1:1', CV_aero_panel_key: 'AERO-GOOD-0001', GUARD_DIR: cached, PUBKEY: otherPub }); ok(r.licensed === false, 'cache falsifié ou mauvaise clé publique : refusé');
    console.log('En cours de route');
    // déjà démarrées avant le guard puis licence invalide : arrêtées
    r = await runLua({ ...base, CV_aero_panel_key: 'AERO-EXPIRED', PRESTARTED: 'pickax_core,pickax_jobbuilder' }); ok(r.states.pickax_core === 'stopped' && r.states.pickax_jobbuilder === 'stopped' && r.stopped.includes('pickax_core'), 'ressources déjà lancées avant le guard : arrêtées si la licence est invalide');
    // licence révoquée pendant que la base tourne
    const dirRun = fs.mkdtempSync('/tmp/guard-rt-'); const pr = runLua({ ...base, CV_aero_panel_key: 'AERO-GOOD-0001', INTERVAL: '60', RUN: '200', GUARD_DIR: dirRun });
    r = await pr; ok(r.licensed === true, 'vérification périodique : toujours valide');
    lic('AERO-REVOKE'); r = await runLua({ ...base, CV_aero_panel_key: 'AERO-REVOKE', INTERVAL: '60', RUN: '200', HOOK_AT: '100', HOOK_URL: 'http://127.0.0.1:' + hook.address().port + '/revoke' });
    ok(r.licensed === false && r.stopped.includes('pickax_core') && r.states.pickax_core === 'stopped', 'licence révoquée pendant que le serveur tourne : la base s’arrête');
  } catch (e) { console.error('ÉCHEC :', e.message); process.exitCode = 1; }
  console.log(process.exitCode ? '' : `\n${n} vérifications OK`); srv.close(); fake.close(); hook.close(); setTimeout(() => process.exit(process.exitCode || 0), 200);
});
