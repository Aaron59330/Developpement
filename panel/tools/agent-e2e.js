// Panel réel + ressource Lua simulée : node tools/agent-e2e.js
process.env.DATA_DIR = './data-e2e'; process.env.ADMIN_EMAIL = 'a@e.fr'; process.env.ADMIN_PASSWORD = 'AdminE2E!123';
const fs = require('fs'), { execFileSync } = require('child_process'); fs.rmSync(__dirname + '/../data-e2e', { recursive: true, force: true });
const app = require('../server'); const { db, now, genKey } = require('../lib/db'); const C = require('../lib/commands');
const qr = (lid, t, p) => { const v = C.validateRpc(t, p); if (v.error) throw new Error(t + ': ' + v.error); db.prepare('INSERT INTO commands(license_id,type,payload,created_at) VALUES(?,?,?,?)').run(lid, t, JSON.stringify(v.payload), now()); };
const srv = require('http').createServer(app).listen(0, () => {
  const lid = db.prepare('INSERT INTO licenses(key,plan_id,server_name,status,expires_at,created_at) VALUES(?,?,?,?,?,?)').run('AERO-E2E', 2, 'E2E', 'active', now() + 86400, now()).lastInsertRowid;
  const q = (t, p) => { const v = C.validate(t, p); if (v.error) throw new Error(t + ': ' + v.error); db.prepare('INSERT INTO commands(license_id,type,payload,created_at) VALUES(?,?,?,?)').run(lid, t, JSON.stringify(v.payload), now()); };
  qr(lid, 'fs.list', { path: '' }); qr(lid, 'fs.list', { path: 'pickax_core' }); qr(lid, 'fs.read', { path: 'pickax_core/config.lua' }); qr(lid, 'fs.write', { path: 'pickax_core/config.lua', content: 'A = 2\n' }); qr(lid, 'fs.write', { path: 'pickax_core/bad.lua', content: 'local = = 1' }); q('console', { cmd: 'refresh' }); q('console', { cmd: 'quit' }); q('resource_stop', { resource: 'pickax_jobbuilder' }); q('server_restart', {});
  qr(lid, 'db.jobs', {}); qr(lid, 'db.job_save', { job: { name: 'police', label: 'Police', whitelisted: true, grades: [{ grade: 0, name: 'recruit', label: 'Recrue', salary: 450 }, { grade: 1, name: 'officer', label: 'Officier', salary: 800 }] } }); q('teleport', { id: 7, x: 215.5, y: -810 }); q('jobs_refresh', {});
  q('announce', { message: 'Test annonce' }); q('setjob', { id: 7, job: 'mecano', grade: 3 }); q('givemoney', { id: 7, account: 'money', amount: 250 }); q('giveitem', { id: 7, item: 'bread', count: 2 });
  q('restart_resource', { resource: 'pickax_core' }); q('restart_resource', { resource: 'oxmysql' }); q('kick', { id: 99, reason: 'x' }); q('apply_theme', {});
  db.prepare('INSERT INTO docs(license_id,key,value,version,updated_at) VALUES(?,?,?,?,?)').run(lid, 'theme', JSON.stringify({ AccentColor: '#00ff88', ServerName: 'E2E RP' }), 1, now());
  db.prepare('INSERT INTO docs(license_id,key,value,version,updated_at) VALUES(?,?,?,?,?)').run(lid, 'bans', JSON.stringify([{ identifier: 'license:zzz', name: 'X', reason: 'r', until: 0, at: 1 }]), 1, now());
  db.prepare('INSERT INTO docs(license_id,key,value,version,updated_at) VALUES(?,?,?,?,?)').run(lid, 'server', JSON.stringify({ projectName: '^4E2E RP', projectDesc: 'desc', hostname: '^4E2E' }), 1, now());
  db.prepare('INSERT INTO docs(license_id,key,value,version,updated_at) VALUES(?,?,?,?,?)').run(lid, 'motd', JSON.stringify({ text: 'Bienvenue', enabled: true }), 1, now());
  const out = require('child_process').spawn('lua5.4', [__dirname + '/agent-harness.lua', 'http://127.0.0.1:' + srv.address().port, 'AERO-E2E', __dirname + '/../../resources/[dev]/pickax_panel'], { stdio: ['ignore', 'pipe', 'inherit'] });
  let buf = ''; out.stdout.on('data', d => buf += d); out.on('close', () => {
    console.log(buf);
    console.log('commandes :', db.prepare('SELECT type,status,result FROM commands ORDER BY id').all().map(c => `${c.type}=${c.status}(${c.result})`).join(' | '));
    console.log('joueurs vus par le panel :', db.prepare('SELECT players FROM server_state').get().players);
    srv.close(); fs.rmSync(__dirname + '/../data-e2e', { recursive: true, force: true }); process.exit(0);
  });
});
