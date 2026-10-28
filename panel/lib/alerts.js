// Alertes automatiques : le client choisit un salon Discord et ce qui doit le prévenir (serveur hors ligne, pic d'erreurs, joueur très riche).
// evaluate() est pure (testée) : elle compare l'état actuel à l'état précédent pour n'envoyer chaque alerte qu'une fois.
const { db, now } = require('./db');
const OFFLINE_AFTER = 300, ERR_WINDOW = 600, ERR_REPEAT = 1800, RICH_REPEAT = 86400;
const doc = (lid, key) => { const d = db.prepare('SELECT value FROM docs WHERE license_id=? AND key=?').get(lid, key); return d ? JSON.parse(d.value) : null; };
const put = (lid, key, v) => db.prepare('INSERT INTO docs(license_id,key,value,version,updated_at) VALUES(?,?,?,?,?) ON CONFLICT(license_id,key) DO UPDATE SET value=excluded.value, version=docs.version+1, updated_at=excluded.updated_at').run(lid, key, JSON.stringify(v), 1, now());
const money = n => Math.round(n).toLocaleString('fr-FR').replace(/ | /g, ' ') + ' $';

function evaluate(i, st) {
  st = { offline: false, errAt: 0, rich: {}, ...(st || {}) }; const msgs = [], c = i.cfg;
  if (c.offline) {
    const down = i.lastSeen && i.at - i.lastSeen > OFFLINE_AFTER;
    if (down && !st.offline) { st.offline = true; msgs.push({ color: 0xf87171, title: '🔴  Serveur hors ligne', text: `**${i.server}** ne répond plus depuis ${Math.round((i.at - i.lastSeen) / 60)} min.` }); }
    if (!down && st.offline && i.lastSeen) { st.offline = false; msgs.push({ color: 0x4ade80, title: '🟢  Serveur de nouveau en ligne', text: `**${i.server}** répond de nouveau.` }); }
  }
  if (c.errors && +c.errorLimit > 0 && i.errors >= +c.errorLimit && i.at - st.errAt >= ERR_REPEAT) { st.errAt = i.at; msgs.push({ color: 0xfbbf24, title: '⚠️  Beaucoup d’erreurs', text: `**${i.errors} erreurs** en ${ERR_WINDOW / 60} minutes sur **${i.server}**. Regarde les Logs du panel.` }); }
  if (c.rich && +c.richLimit > 0) {
    for (const p of i.players) { const total = (+p.money || 0) + (+p.bank || 0); if (total >= +c.richLimit && i.at - (st.rich[p.identifier] || 0) >= RICH_REPEAT) { st.rich[p.identifier] = i.at; msgs.push({ color: 0xa78bfa, title: '💰  Joueur très riche', text: `**${String(p.name || '?').slice(0, 40)}** possède ${money(total)} (seuil : ${money(+c.richLimit)}).` }); } }
    for (const k of Object.keys(st.rich)) if (i.at - st.rich[k] > 7 * 86400) delete st.rich[k];
  }
  return { msgs: msgs.slice(0, 5), state: st };
}
async function run(send, at = now()) {
  let sent = 0;
  for (const l of db.prepare("SELECT id,server_name,last_seen FROM licenses WHERE status='active' AND (expires_at IS NULL OR expires_at>?)").all(at)) {
    const cfg = doc(l.id, 'alerts'); if (!cfg || !cfg.enabled || !cfg.channelId) continue;
    const ch = db.prepare('SELECT url FROM discord_channels WHERE id=? AND license_id=?').get(cfg.channelId, l.id); if (!ch) continue;
    const s = db.prepare('SELECT players FROM server_state WHERE license_id=?').get(l.id);
    const errors = db.prepare("SELECT COUNT(*) n FROM logs WHERE license_id=? AND level='error' AND at>?").get(l.id, at - ERR_WINDOW).n;
    const r = evaluate({ cfg, at, server: l.server_name, lastSeen: l.last_seen, errors, players: s ? JSON.parse(s.players || '[]') : [] }, doc(l.id, 'alerts_state'));
    put(l.id, 'alerts_state', r.state);
    for (const m of r.msgs) if (await send(ch.url, { username: 'AERO Panel', embeds: [{ title: m.title, description: m.text, color: m.color, timestamp: new Date(at * 1000).toISOString() }], allowed_mentions: { parse: [] } })) sent++;
  }
  return sent;
}
// Une plainte vient d'arriver : notification dans le salon d'alertes si le client l'a demandé (option « Plaintes »)
function reportAlert(l, rep, at, send) {
  try {
    const cfg = doc(l.id, 'alerts'); if (!cfg || !cfg.enabled || !cfg.channelId || cfg.reports === false) return;
    const ch = db.prepare('SELECT url FROM discord_channels WHERE id=? AND license_id=?').get(cfg.channelId, l.id); if (!ch) return;
    (send || realSend)(ch.url, { username: 'AERO Panel', embeds: [{ title: '📣  Nouvelle plainte', description: `**${rep.reporter}**${rep.target ? ` contre **${rep.target}**` : ''}\n${rep.message.slice(0, 300)}\n\nÀ traiter dans le panel → Plaintes.`, color: 0xfb923c, timestamp: new Date(at * 1000).toISOString() }], allowed_mentions: { parse: [] } });
  } catch (e) {}
}
const realSend = async (url, body) => { try { const r = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(body), signal: AbortSignal.timeout(10000) }); return r.ok; } catch (e) { return false; } };
function start() { setInterval(() => run(realSend).catch(() => {}), 60000).unref(); }
module.exports = { evaluate, run, start, reportAlert };
