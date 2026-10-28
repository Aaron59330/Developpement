// Rétention des joueurs : combien reviennent après 1 jour / 7 jours, nouveaux joueurs par jour, affluence par heure (UTC), joueurs les plus assidus.
const DAY = 86400;

// Part de joueurs « revenus » : parmi ceux arrivés il y a au moins `days` jours, ceux dont la dernière visite est au moins `days` après la première
function returnRate(rows, days, at) {
  const cohort = rows.filter(r => r.first_seen && at - r.first_seen >= days * DAY);
  if (cohort.length < 1) return { known: false, cohort: 0 };
  const back = cohort.filter(r => (r.last_seen || 0) - r.first_seen >= days * DAY).length;
  return { known: true, cohort: cohort.length, back, pct: Math.round(back / cohort.length * 100) };
}

// Moyenne de joueurs connectés par heure UTC (24 valeurs) sur les points de stats_hist
function hourly(points) {
  const sum = Array(24).fill(0), cnt = Array(24).fill(0);
  for (const p of points) { const h = new Date(p.at * 1000).getUTCHours(); sum[h] += p.players; cnt[h]++; }
  return sum.map((s, i) => cnt[i] ? Math.round(s / cnt[i] * 10) / 10 : 0);
}

// Nouveaux joueurs par jour sur `days` jours (le plus ancien d'abord)
function newPerDay(rows, days, at) {
  const out = Array(days).fill(0), start = Math.floor(at / DAY) * DAY - (days - 1) * DAY;
  for (const r of rows) { if (!r.first_seen || r.first_seen < start) continue; const i = Math.floor((r.first_seen - start) / DAY); if (i >= 0 && i < days) out[i]++; }
  return out.map((n, i) => ({ day: start + i * DAY, n }));
}

function summary(rows, points, at) {
  return {
    total: rows.length,
    active7: rows.filter(r => at - (r.last_seen || 0) <= 7 * DAY).length,
    active30: rows.filter(r => at - (r.last_seen || 0) <= 30 * DAY).length,
    d1: returnRate(rows, 1, at), d7: returnRate(rows, 7, at), d30: returnRate(rows, 30, at),
    avgMinutes: rows.length ? Math.round(rows.reduce((s, r) => s + (r.minutes || 0), 0) / rows.length) : 0,
    avgSessions: rows.length ? Math.round(rows.reduce((s, r) => s + (r.sessions || 0), 0) / rows.length * 10) / 10 : 0,
    hours: hourly(points), newPerDay: newPerDay(rows, 14, at),
    top: rows.slice().sort((a, b) => (b.minutes || 0) - (a.minutes || 0)).slice(0, 8).map(r => ({ name: r.name, minutes: Math.round(r.minutes || 0), sessions: r.sessions || 0, last_seen: r.last_seen })),
  };
}
module.exports = { returnRate, hourly, newPerDay, summary };
