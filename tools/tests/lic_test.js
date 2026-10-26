// Teste les points de contrôle de licence embarqués dans les ressources (protection contre le retrait/remplacement de pickax_guard) : node tools/tests/lic_test.js
const path = require('path'), crypto = require('crypto'), assert = require('assert'), { spawnSync } = require('child_process');
const ROOT = path.join(__dirname, '..', '..', 'resources'); const H = path.join(__dirname, 'lic_harness.lua');
let n = 0; const ok = (c, m) => { assert(c, m); n++; console.log('  ✓', m); };
const kp = crypto.generateKeyPairSync('ed25519'), other = crypto.generateKeyPairSync('ed25519');
const pk = kp.publicKey.export({ type: 'spki', format: 'der' }).toString('base64');
const KEY = 'AERO-TEST-KEY', kh = k => crypto.createHash('sha256').update(k).digest('hex').slice(0, 16);
const tok = (o = {}, signer = kp.privateKey) => { const now = Math.floor(Date.now() / 1000); const payload = JSON.stringify({ v: 1, valid: true, status: 'active', nonce: 'x', kh: kh(KEY), iat: now, grace: 86400, ...o }); return { PAYLOAD: payload, SIG: crypto.sign(null, Buffer.from(payload), signer).toString('base64') }; };
const run = (file, mode, env) => { const r = spawnSync('lua5.4', [H], { env: { ...process.env, FILE: path.join(ROOT, file), RES: path.basename(path.dirname(path.dirname(file))) === '' ? 'x' : file.split('/')[1], MODE: mode, PK: pk, KEY, LICNODE: path.join(ROOT, path.dirname(file).split('/').slice(0, 2).join('/'), 'lic.js'), ...env }, encoding: 'utf8' }); const m = (r.stdout || '').match(/RESULT(.*)/); if (!m) throw new Error(r.stdout + r.stderr); return JSON.parse(m[1]); };
const V = '[dev]/pickax_economy/server/main.lua', CORE = '[script]/pickax_core/init/server/sv_initESX.lua', HUB = '[dev]/pickax_auction/server/main.lua';
try {
  console.log('Ressource à vérification autonome (economy)');
  let r = run(V, 'v', { ...tok() }); ok(!r.topError && r.stopped.length === 0, 'jeton valide : la ressource tourne (et le recontrôle périodique passe)');
  r = run(V, 'v', { TOKEN: 'none', PAYLOAD: '', SIG: '', RUN: '60' }); ok(r.stopped.includes('pickax_economy'), 'pickax_guard retiré / faux (aucun jeton) : la ressource s’arrête');
  r = run(V, 'v', { TOKEN: 'absent', RUN: '60' }); ok(r.stopped.includes('pickax_economy'), 'ressource pickax_guard absente : la ressource s’arrête');
  r = run(V, 'v', { ...tok({}, other.privateKey) }); ok(r.topError && r.stopped.includes('pickax_economy'), 'jeton signé par une autre clé (faux guard/faux panel) : stop immédiat');
  r = run(V, 'v', { ...tok({ valid: false }) }); ok(r.topError && r.stopped.length === 1, 'jeton « licence refusée » : stop');
  r = run(V, 'v', { ...tok({ kh: kh('AUTRE') }) }); ok(r.topError && r.stopped.length === 1, 'jeton d’une autre clé de licence : stop');
  r = run(V, 'v', { ...tok({ iat: Math.floor(Date.now() / 1000) - 90000 }) }); ok(r.topError && r.stopped.length === 1, 'jeton plus vieux que 24 h : stop');
  r = run(V, 'v', { ...tok({ iat: Math.floor(Date.now() / 1000) + 5000 }) }); ok(r.topError && r.stopped.length === 1, 'jeton daté du futur : stop');
  r = run(V, 'v', { ...tok(), KEY: 'AERO-PIRATE' }); ok(r.topError && r.stopped.length === 1, 'clé du server.cfg différente de celle du jeton : stop');
  r = run(V, 'v', { ...tok(), PK: '' }); ok(r.topError && r.stopped.length === 1, 'clé publique non embarquée : stop');
  r = run(V, 'v', { ...tok(), NODE_READY_AFTER: '1500' }); ok(r.stopped.length === 0 && !r.topError, 'module Node pas encore prêt au chargement : la ressource attend puis démarre');
  console.log('Hub (pickax_core)');
  r = run(CORE, 'v', { ...tok() }); ok(r.licensedExport === true && r.stopped.length === 0, 'core : valide, expose Licensed() = true');
  r = run(CORE, 'v', { TOKEN: 'none', PAYLOAD: '', SIG: '', RUN: '60' }); ok(r.stopped.includes('pickax_core'), 'core : sans pickax_guard, s’arrête');
  console.log('Ressources dépendantes de pickax_core (auction)');
  r = run(HUB, 'hub', { CORE: 'ok' }); ok(r.stopped.length === 0, 'core licencié : la ressource tourne');
  r = run(HUB, 'hub', { CORE: 'bad' }); ok(r.stopped.includes('pickax_auction'), 'core non licencié : la ressource s’arrête');
  r = run(HUB, 'hub', { CORE: 'missing', RUN: '60' }); ok(r.stopped.includes('pickax_auction'), 'pickax_core retiré : la ressource s’arrête');
} catch (e) { console.error('ÉCHEC :', e.message); process.exitCode = 1; }
console.log(process.exitCode ? '' : `\n${n} vérifications OK`);
