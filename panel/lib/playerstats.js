// Suivi des joueurs d'un serveur : temps de jeu, sessions, dernière connexion… calculés à chaque synchronisation du jeu (toutes les ~60 s)
const { db } = require('./db');
const GAP = 300;   // au-delà de 5 minutes sans signe de vie, on considère une nouvelle session

function track(licenseId, players, at) {
  const seen = new Set();
  const get = db.prepare('SELECT * FROM player_stats WHERE license_id=? AND identifier=?');
  const ins = db.prepare('INSERT INTO player_stats(license_id,identifier,name,minutes,sessions,first_seen,last_seen,last_job,last_money,last_bank,max_money,online,last_tick) VALUES(?,?,?,?,?,?,?,?,?,?,?,1,?)');
  const upd = db.prepare('UPDATE player_stats SET name=?, minutes=?, sessions=?, last_seen=?, last_job=?, last_money=?, last_bank=?, max_money=?, online=1, last_tick=? WHERE license_id=? AND identifier=?');
  for (const p of players) {
    if (!p.identifier || seen.has(p.identifier)) continue; seen.add(p.identifier);
    const total = (p.money || 0) + (p.bank || 0), r = get.get(licenseId, p.identifier);
    if (!r) { ins.run(licenseId, p.identifier, p.name, 0, 1, at, at, p.job || '', p.money || 0, p.bank || 0, total, at); continue; }
    const cont = r.online === 1 && at - r.last_tick <= GAP;
    upd.run(p.name || r.name, r.minutes + (cont ? (at - r.last_tick) / 60 : 0), r.sessions + (cont ? 0 : 1), at, p.job || '', p.money || 0, p.bank || 0, Math.max(r.max_money || 0, total), at, licenseId, p.identifier);
  }
  // ceux qui ne sont plus dans la liste sont hors ligne
  for (const r of db.prepare('SELECT identifier FROM player_stats WHERE license_id=? AND online=1').all(licenseId)) if (!seen.has(r.identifier)) db.prepare('UPDATE player_stats SET online=0 WHERE license_id=? AND identifier=?').run(licenseId, r.identifier);
}
module.exports = { track, GAP };
