// Statistiques économiques : photo de la richesse des joueurs connectés toutes les 30 minutes + synthèse (totaux, top, signal d'inflation)
const { db } = require('./db');
const EVERY = 1800, KEEP = 60 * 86400;
function track(licenseId, players, at) {
  if (!Array.isArray(players) || !players.length) return;
  const last = db.prepare('SELECT at FROM econ_hist WHERE license_id=? ORDER BY id DESC LIMIT 1').get(licenseId); if (last && at - last.at < EVERY) return;
  let money = 0, bank = 0; for (const p of players) { money += Math.max(0, Math.floor(+p.money || 0)); bank += Math.max(0, Math.floor(+p.bank || 0)); }
  db.prepare('INSERT INTO econ_hist(license_id,at,players,money,bank) VALUES(?,?,?,?,?)').run(licenseId, at, players.length, money, bank);
  db.prepare('DELETE FROM econ_hist WHERE license_id=? AND at<?').run(licenseId, at - KEEP);
}
// Richesse moyenne par joueur, comparée à celle d'il y a ~7 jours : +25 % ou plus = inflation, -25 % ou moins = déflation
function inflation(rows, at) {
  const avg = r => r.players ? (r.money + r.bank) / r.players : 0;
  const recent = rows.filter(r => r.at > at - 86400), old = rows.filter(r => r.at <= at - 6 * 86400 && r.at > at - 9 * 86400);
  if (recent.length < 2 || old.length < 2) return { known: false };
  const m = a => a.reduce((s, r) => s + avg(r), 0) / a.length, now = m(recent), before = m(old); if (before <= 0) return { known: false };
  const pct = Math.round((now / before - 1) * 100); return { known: true, pct, level: pct >= 25 ? 'inflation' : pct <= -25 ? 'deflation' : 'stable', now: Math.round(now), before: Math.round(before) };
}
function summary(licenseId, at) {
  const rows = db.prepare('SELECT at,players,money,bank FROM econ_hist WHERE license_id=? AND at>? ORDER BY at').all(licenseId, at - 30 * 86400);
  const st = db.prepare('SELECT players FROM server_state WHERE license_id=?').get(licenseId); const online = st ? JSON.parse(st.players || '[]') : [];
  const wealth = online.map(p => ({ name: String(p.name || '?').slice(0, 30), money: Math.max(0, +p.money || 0), bank: Math.max(0, +p.bank || 0) })).map(p => ({ ...p, total: p.money + p.bank })).sort((a, b) => b.total - a.total);
  const total = wealth.reduce((s, p) => s + p.total, 0);
  const top = wealth.slice(0, 5); const topShare = total ? Math.round(top.reduce((s, p) => s + p.total, 0) / total * 100) : 0;
  return { online: wealth.length, money: wealth.reduce((s, p) => s + p.money, 0), bank: wealth.reduce((s, p) => s + p.bank, 0), total, avg: wealth.length ? Math.round(total / wealth.length) : 0, top, topShare, history: rows.map(r => ({ at: r.at, avg: r.players ? Math.round((r.money + r.bank) / r.players) : 0, total: r.money + r.bank, players: r.players })), inflation: inflation(rows, at) };
}
module.exports = { track, summary, inflation };
