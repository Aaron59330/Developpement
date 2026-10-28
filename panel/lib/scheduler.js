// Planificateur : exécute à l'heure prévue les actions programmées (annonces, redémarrages, événements d'économie…)
const { db, now, audit } = require('./db'); const cfg = require('./config'); const { enqueue } = require('./enqueue');
const ONLINE = 3 * cfg.agentIntervalSec + 5, LATE = 15 * 60, STEP = { daily: 86400, weekly: 7 * 86400 };
const SCHEDULABLE = ['announce', 'restart_resource', 'server_restart', 'economy_event', 'economy_reset', 'settings_profile'];
function warnText(s, payload) {
  const m = s.warn_min, mins = m + (m > 1 ? ' minutes' : ' minute');
  if (s.type === 'server_restart') return `Redémarrage du serveur dans ${mins}.`;
  if (s.type === 'restart_resource') return `La ressource ${payload.resource} redémarre dans ${mins}.`;
  return `« ${s.name} » dans ${mins}.`;
}
function advance(s, t, status) {
  if (s.every === 'none') { db.prepare('UPDATE schedules SET enabled=0, last_run=?, last_status=?, warned_for=NULL WHERE id=?').run(t, status, s.id); return; }
  let next = s.run_at; while (next <= t) next += STEP[s.every]; db.prepare('UPDATE schedules SET run_at=?, last_run=?, last_status=?, warned_for=NULL WHERE id=?').run(next, t, status, s.id);
}
function tick() {
  const t = now();
  const rows = db.prepare('SELECT s.*, l.status lstatus, l.expires_at lexp, l.last_seen lseen FROM schedules s JOIN licenses l ON l.id=s.license_id WHERE s.enabled=1 AND s.run_at - s.warn_min*60 <= ?').all(t);
  for (const s of rows) {
    try {
      const active = s.lstatus === 'active' && !(s.lexp && s.lexp < t), online = !!(s.lseen && t - s.lseen < ONLINE), payload = JSON.parse(s.payload);
      if (s.warn_min > 0 && s.warned_for !== s.run_at && t < s.run_at && active && online) { enqueue(s.license_id, 'announce', { message: warnText(s, payload) }, s.by_user); db.prepare('UPDATE schedules SET warned_for=? WHERE id=?').run(s.run_at, s.id); }
      if (t < s.run_at) continue;
      if (!active) { advance(s, t, 'ignoré : licence inactive'); continue; }
      if (!online) { if (t - s.run_at <= LATE) continue; advance(s, t, 'manqué : serveur hors ligne'); continue; }
      if (t - s.run_at > LATE) { advance(s, t, 'manqué : retard de plus de 15 min'); continue; }
      const r = enqueue(s.license_id, s.type, payload, s.by_user);
      audit(s.by_user, s.license_id, 'schedule:run', s.name, 'planificateur');
      advance(s, t, r.ok ? 'envoyé' : 'échec : ' + r.error);
    } catch (e) { console.error('[scheduler]', e.message); }
  }
}
let timer = null;
function start() { if (timer) return; timer = setInterval(tick, 15000); timer.unref(); }
module.exports = { start, tick, SCHEDULABLE };
