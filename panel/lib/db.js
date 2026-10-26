const Database = require('better-sqlite3'), fs = require('fs'), path = require('path'), bcrypt = require('bcryptjs'), crypto = require('crypto');
const cfg = require('./config');
fs.mkdirSync(cfg.dataDir, { recursive: true });
const db = new Database(path.join(cfg.dataDir, 'panel.db'));
db.pragma('journal_mode = WAL'); db.pragma('foreign_keys = ON');
db.exec(`
CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY, email TEXT UNIQUE NOT NULL, username TEXT NOT NULL, pass_hash TEXT NOT NULL, role TEXT NOT NULL DEFAULT 'client', disabled INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL, last_login INTEGER);
CREATE TABLE IF NOT EXISTS sessions(token TEXT PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE, expires_at INTEGER NOT NULL, ip TEXT, ua TEXT);
CREATE TABLE IF NOT EXISTS plans(id INTEGER PRIMARY KEY, name TEXT NOT NULL, price REAL NOT NULL DEFAULT 0, days INTEGER NOT NULL DEFAULT 30, max_players INTEGER NOT NULL DEFAULT 0, description TEXT DEFAULT '', active INTEGER NOT NULL DEFAULT 1);
CREATE TABLE IF NOT EXISTS licenses(id INTEGER PRIMARY KEY, key TEXT UNIQUE NOT NULL, user_id INTEGER REFERENCES users(id) ON DELETE SET NULL, plan_id INTEGER REFERENCES plans(id) ON DELETE SET NULL, server_name TEXT NOT NULL DEFAULT 'Mon serveur', status TEXT NOT NULL DEFAULT 'active', expires_at INTEGER, created_at INTEGER NOT NULL, last_seen INTEGER, last_ip TEXT, bound_ip TEXT, version TEXT, note TEXT DEFAULT '');
CREATE TABLE IF NOT EXISTS server_state(license_id INTEGER PRIMARY KEY REFERENCES licenses(id) ON DELETE CASCADE, players TEXT NOT NULL DEFAULT '[]', max_players INTEGER DEFAULT 0, resources TEXT NOT NULL DEFAULT '[]', stats TEXT NOT NULL DEFAULT '{}', updated_at INTEGER);
CREATE TABLE IF NOT EXISTS stats_hist(id INTEGER PRIMARY KEY, license_id INTEGER NOT NULL REFERENCES licenses(id) ON DELETE CASCADE, at INTEGER NOT NULL, players INTEGER NOT NULL);
CREATE INDEX IF NOT EXISTS idx_stats ON stats_hist(license_id, at);
CREATE TABLE IF NOT EXISTS commands(id INTEGER PRIMARY KEY, license_id INTEGER NOT NULL REFERENCES licenses(id) ON DELETE CASCADE, type TEXT NOT NULL, payload TEXT NOT NULL DEFAULT '{}', status TEXT NOT NULL DEFAULT 'pending', result TEXT, created_at INTEGER NOT NULL, sent_at INTEGER, done_at INTEGER, by_user INTEGER);
CREATE INDEX IF NOT EXISTS idx_cmd ON commands(license_id, status);
CREATE TABLE IF NOT EXISTS logs(id INTEGER PRIMARY KEY, license_id INTEGER NOT NULL REFERENCES licenses(id) ON DELETE CASCADE, level TEXT NOT NULL DEFAULT 'info', source TEXT DEFAULT '', message TEXT NOT NULL, at INTEGER NOT NULL);
CREATE INDEX IF NOT EXISTS idx_logs ON logs(license_id, id);
CREATE TABLE IF NOT EXISTS docs(license_id INTEGER NOT NULL REFERENCES licenses(id) ON DELETE CASCADE, key TEXT NOT NULL, value TEXT NOT NULL, version INTEGER NOT NULL DEFAULT 1, updated_at INTEGER NOT NULL, PRIMARY KEY(license_id, key));
CREATE TABLE IF NOT EXISTS audit(id INTEGER PRIMARY KEY, user_id INTEGER, license_id INTEGER, action TEXT NOT NULL, detail TEXT DEFAULT '', ip TEXT, at INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS file_versions(id INTEGER PRIMARY KEY, license_id INTEGER NOT NULL REFERENCES licenses(id) ON DELETE CASCADE, path TEXT NOT NULL, content TEXT NOT NULL, size INTEGER NOT NULL, note TEXT DEFAULT '', by_user INTEGER, at INTEGER NOT NULL);
CREATE INDEX IF NOT EXISTS idx_fv ON file_versions(license_id, path, id);
CREATE TABLE IF NOT EXISTS tickets(id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE, license_id INTEGER, subject TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'open', created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS ticket_msgs(id INTEGER PRIMARY KEY, ticket_id INTEGER NOT NULL REFERENCES tickets(id) ON DELETE CASCADE, user_id INTEGER NOT NULL, staff INTEGER NOT NULL DEFAULT 0, body TEXT NOT NULL, at INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS patchnotes(id INTEGER PRIMARY KEY, version TEXT NOT NULL, title TEXT NOT NULL, body TEXT NOT NULL, at INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS suggestions(id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE, title TEXT NOT NULL, body TEXT DEFAULT '', status TEXT NOT NULL DEFAULT 'new', at INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS suggestion_votes(suggestion_id INTEGER NOT NULL REFERENCES suggestions(id) ON DELETE CASCADE, user_id INTEGER NOT NULL, PRIMARY KEY(suggestion_id, user_id));
CREATE TABLE IF NOT EXISTS webhooks(license_id INTEGER NOT NULL REFERENCES licenses(id) ON DELETE CASCADE, event TEXT NOT NULL, url TEXT NOT NULL, PRIMARY KEY(license_id, event));
CREATE TABLE IF NOT EXISTS drive(id INTEGER PRIMARY KEY, license_id INTEGER NOT NULL REFERENCES licenses(id) ON DELETE CASCADE, token TEXT UNIQUE NOT NULL, name TEXT NOT NULL, mime TEXT NOT NULL, size INTEGER NOT NULL, at INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS modules(id INTEGER PRIMARY KEY, name TEXT NOT NULL, description TEXT DEFAULT '', price REAL NOT NULL DEFAULT 0, resources TEXT NOT NULL DEFAULT '[]', active INTEGER NOT NULL DEFAULT 1);
CREATE TABLE IF NOT EXISTS license_modules(license_id INTEGER NOT NULL REFERENCES licenses(id) ON DELETE CASCADE, module_id INTEGER NOT NULL REFERENCES modules(id) ON DELETE CASCADE, enabled INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(license_id, module_id));
CREATE TABLE IF NOT EXISTS backups(id INTEGER PRIMARY KEY, license_id INTEGER NOT NULL REFERENCES licenses(id) ON DELETE CASCADE, name TEXT NOT NULL, data TEXT NOT NULL, size INTEGER NOT NULL, at INTEGER NOT NULL, by_user INTEGER);
CREATE TABLE IF NOT EXISTS orders(id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE, plan_id INTEGER REFERENCES plans(id) ON DELETE SET NULL, plan_name TEXT NOT NULL DEFAULT '', amount REAL NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'pending', renew_license_id INTEGER, license_id INTEGER, note TEXT DEFAULT '', created_at INTEGER NOT NULL, paid_at INTEGER);
CREATE TABLE IF NOT EXISTS schedules(id INTEGER PRIMARY KEY, license_id INTEGER NOT NULL REFERENCES licenses(id) ON DELETE CASCADE, name TEXT NOT NULL, type TEXT NOT NULL, payload TEXT NOT NULL, run_at INTEGER NOT NULL, every TEXT NOT NULL DEFAULT 'none', warn_min INTEGER NOT NULL DEFAULT 0, enabled INTEGER NOT NULL DEFAULT 1, warned_for INTEGER, last_run INTEGER, last_status TEXT DEFAULT '', by_user INTEGER, created_at INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS ai_usage(license_id INTEGER NOT NULL, day TEXT NOT NULL, n INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(license_id, day));
`);
const now = () => Math.floor(Date.now() / 1000);
function audit(userId, licenseId, action, detail, ip) { db.prepare('INSERT INTO audit(user_id,license_id,action,detail,ip,at) VALUES(?,?,?,?,?,?)').run(userId || null, licenseId || null, action, String(detail || '').slice(0, 500), ip || '', now()); }
function genKey() { const b = crypto.randomBytes(16).toString('hex').toUpperCase(); return 'AERO-' + [b.slice(0, 6), b.slice(6, 12), b.slice(12, 18), b.slice(18, 24)].join('-'); }
// données de départ
if (!db.prepare('SELECT 1 FROM patchnotes').get()) db.prepare('INSERT INTO patchnotes(version,title,body,at) VALUES(?,?,?,?)').run('1.0.0', 'Ouverture du panel', 'Gestion du serveur à distance, éditeur de fichiers avec historique, console, statistiques, webhooks et support.', now());
if (!db.prepare('SELECT 1 FROM plans').get()) {
  const ins = db.prepare('INSERT INTO plans(name,price,days,max_players,description) VALUES(?,?,?,?,?)');
  ins.run('Essai', 0, 7, 32, 'Découverte de la base pendant 7 jours');
  ins.run('Mensuel', 30, 30, 0, 'Base complète + mises à jour, sans limite de joueurs');
  ins.run('Licence à vie', 350, 0, 0, 'Paiement unique, mises à jour incluses');
}
if (!db.prepare("SELECT 1 FROM users WHERE role='admin'").get()) {
  db.prepare('INSERT INTO users(email,username,pass_hash,role,created_at) VALUES(?,?,?,?,?)').run(cfg.adminEmail.toLowerCase(), 'Admin', bcrypt.hashSync(cfg.adminPassword, 11), 'admin', now());
  console.log('[panel] Compte admin créé :', cfg.adminEmail, '(change le mot de passe dès la première connexion)');
}
module.exports = { db, now, audit, genKey };
