// Personnalisation du panel (design, thème, couleur) : node tools/selftest5.js
process.env.DATA_DIR = './data-test5'; process.env.ADMIN_EMAIL = 'admin@test.fr'; process.env.ADMIN_PASSWORD = 'AdminTest!123';
const fs = require('fs'), http = require('http'), assert = require('assert'); fs.rmSync(__dirname + '/../data-test5', { recursive: true, force: true });
const app = require('../server');
const srv = http.createServer(app).listen(0, async () => {
  const base = 'http://127.0.0.1:' + srv.address().port; let n = 0; const ok = (c, m) => { assert(c, m); n++; console.log('  ✓', m); };
  const mk = () => { let cookie = ''; return async (m, u, body) => { const r = await fetch(base + u, { method: m, headers: { 'content-type': 'application/json', origin: base, cookie }, body: m === 'GET' ? undefined : JSON.stringify(body || {}) }); const c = r.headers.get('set-cookie'); if (c) cookie = c.split(';')[0]; return r.json(); }; };
  try {
    const a = mk(), b = mk();
    await a('POST', '/api/auth/register', { email: 'a@t.fr', username: 'Alice', password: 'ClientTest!1' }); await b('POST', '/api/auth/register', { email: 'b@t.fr', username: 'Bob', password: 'ClientTest!1' });
    let me = await a('GET', '/api/auth/me'); ok(me.user.prefs.design === 'hub' && me.user.prefs.theme === 'sombre' && me.user.prefs.accent === null, 'préférences par défaut : design Hub, sombre, jaune AERO');
    let r = await a('PUT', '/api/auth/prefs', { design: 'v1' }); ok(r.ok && r.prefs.design === 'v1' && r.prefs.theme === 'sombre', 'retour à l’ancien design enregistré sans toucher au reste');
    r = await a('PUT', '/api/auth/prefs', { accent: '#60A5FA', theme: 'clair' }); ok(r.ok && r.prefs.accent === '#60a5fa' && r.prefs.theme === 'clair' && r.prefs.design === 'v1', 'couleur (normalisée) et thème enregistrés ensemble');
    me = await a('GET', '/api/auth/me'); ok(me.user.prefs.accent === '#60a5fa', 'les préférences reviennent à la connexion suivante');
    r = await a('PUT', '/api/auth/prefs', { accent: null }); ok(r.ok && r.prefs.accent === null, 'rétablir le jaune AERO');
    for (const bad of [{ accent: 'rouge' }, { accent: '#12345' }, { accent: 'red;}</style>' }, { design: 'v3' }, { theme: 'x' }]) { r = await a('PUT', '/api/auth/prefs', bad); ok(r.ok === false, 'valeur refusée : ' + JSON.stringify(bad)); }
    me = await b('GET', '/api/auth/me'); ok(me.user.prefs.design === 'hub' && me.user.prefs.accent === null, 'les préférences d’un client ne touchent pas celles des autres');
    const anon = mk(); r = await fetch(base + '/api/auth/prefs', { method: 'PUT', headers: { 'content-type': 'application/json', origin: base }, body: '{}' }); ok(r.status === 401 || r.status === 403, 'refusé sans connexion');
    const C = require('../lib/commands'); const th = { AccentColor: '#fdc27d', ServerName: 'AERO', ServerShortName: 'AERO', ServerTagline: 't', ServerDiscord: 'd', ServerLogo: 'logo.png', MenuBanner: '', LoadingBanner: '', MarkerType: 23, MarkerAlpha: 150, MarkerSize: 1, BlipScale: .5, BlipColor: -1, MarkerColor: '' };
    const des = d => { const x = C.validateDoc('theme', { ...th, Design: d }); return x.error ? x.error : (x.value || x.payload || x).Design; };
    ok(des('pinata') === 'pinata' && des('ancien') === 'ancien' && des('arcade') === 'arcade', 'style des interfaces : Piñata, ancien et Arcade acceptés');
    ok(des('autre') === 'arcade' && des(undefined) === 'arcade', 'style inconnu : retour à Arcade');
    const SET = require('../lib/settings'); const sch = SET.sanitizeSchema([{ key: 'game_mode', type: 'select', group: 'Serveur', default: 'difficile', options: [['difficile', 'D'], ['facile', 'F']] }, { key: 'cap', type: 'number', group: 'Gangs', default: 120, easy: 60 }, { key: 'bad', type: 'number', group: 'Gangs', default: 1, easy: 'x' }, { key: 'flag', type: 'bool', group: 'Gangs', default: true, easy: false }]);
    ok(sch[1].easy === 60 && sch[3].easy === false && sch[2].easy === undefined && sch[0].easy === undefined, 'schéma : la valeur « mode facile » est conservée seulement si son type est bon');
  } catch (e) { console.error('ÉCHEC :', e.message); process.exitCode = 1; }
  console.log(process.exitCode ? '' : `\n${n} vérifications OK`); srv.close(); setTimeout(() => process.exit(process.exitCode || 0), 200);
});
