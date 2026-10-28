// Rappels de licence : un message Discord est envoyé au salon choisi par le client 7, 3 puis 1 jour avant l'expiration
const { db, now } = require('./db');
const STEPS = [7, 3, 1];
const doc = (lid, key) => { const d = db.prepare('SELECT value FROM docs WHERE license_id=? AND key=?').get(lid, key); return d ? JSON.parse(d.value) : null; };
const put = (lid, key, v) => db.prepare('INSERT INTO docs(license_id,key,value,version,updated_at) VALUES(?,?,?,?,?) ON CONFLICT(license_id,key) DO UPDATE SET value=excluded.value, version=docs.version+1, updated_at=excluded.updated_at').run(lid, key, JSON.stringify(v), 1, now());

// Palier à envoyer (7, 3 ou 1) selon le temps restant et le dernier palier déjà envoyé ; null si rien à envoyer
function dueStep(secondsLeft, lastSent) {
  if (secondsLeft <= 0) return null;
  const days = Math.ceil(secondsLeft / 86400);
  const step = STEPS.filter(s => days <= s).pop();       // le plus petit palier atteint
  if (!step) return null;
  return lastSent == null || step < lastSent ? step : null;
}
async function run(send, at = now()) {
  let sent = 0;
  for (const l of db.prepare("SELECT id,server_name,expires_at,status FROM licenses WHERE status='active' AND expires_at IS NOT NULL AND expires_at>?").all(at)) {
    const cfg = doc(l.id, 'reminders'); if (!cfg || !cfg.enabled || !cfg.channelId) continue;
    const ch = db.prepare('SELECT url,name FROM discord_channels WHERE id=? AND license_id=?').get(cfg.channelId, l.id); if (!ch) continue;
    const st = doc(l.id, 'reminders_state') || {}; const last = st.exp === l.expires_at ? st.sent : null;      // une licence renouvelée repart de zéro
    const step = dueStep(l.expires_at - at, last); if (step == null) continue;
    const ok = await send(ch.url, { username: 'AERO Panel', embeds: [{ title: '⏳  Ta licence expire bientôt', description: `La licence de **${l.server_name}** expire dans **${step} jour${step > 1 ? 's' : ''}** (le ${new Date(l.expires_at * 1000).toLocaleDateString('fr-FR')}).\nRenouvelle-la depuis le panel pour éviter l’arrêt du serveur.`, color: step === 1 ? 0xf87171 : 0xfbbf24, timestamp: new Date(at * 1000).toISOString() }], allowed_mentions: { parse: [] } });
    if (ok) { put(l.id, 'reminders_state', { exp: l.expires_at, sent: step }); sent++; }
  }
  return sent;
}
const realSend = async (url, body) => { try { const r = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(body), signal: AbortSignal.timeout(10000) }); return r.ok; } catch (e) { return false; } };
function start() { setTimeout(() => run(realSend).catch(() => {}), 60000).unref(); setInterval(() => run(realSend).catch(() => {}), 30 * 60 * 1000).unref(); }
module.exports = { run, dueStep, start, STEPS };
