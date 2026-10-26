// Webhooks Discord : les logs reçus du serveur sont renvoyés vers les salons choisis par le client
const { db } = require('./db');
const COLORS = { staff: 0xfdc27d, error: 0xf87171, warn: 0xfbbf24, info: 0x7dd3fc };
const EVENT_OF = l => l.level === 'error' ? 'error' : l.level === 'staff' ? 'staff' : (l.source === 'connexion' ? 'connexion' : null);
const queue = []; let busy = false;
async function pump() { if (busy) return; busy = true; while (queue.length) { const j = queue.shift(); try { await fetch(j.url, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(j.body), signal: AbortSignal.timeout(6000) }); } catch (e) { /* salon supprimé, Discord injoignable : on ignore */ } await new Promise(r => setTimeout(r, 400)); } busy = false; }
function logs(l, list) {
  if (!list || !list.length) return; const hooks = db.prepare('SELECT event,url FROM webhooks WHERE license_id=?').all(l.id); if (!hooks.length) return;
  const by = Object.fromEntries(hooks.map(h => [h.event, h.url]));
  for (const x of list.slice(0, 20)) { const ev = EVENT_OF(x); if (!ev || !by[ev]) continue; if (queue.length > 100) break; queue.push({ url: by[ev], body: { username: 'AERO Panel', embeds: [{ title: ({ staff: 'Action staff', error: 'Erreur serveur', connexion: 'Connexion' })[ev], description: x.message.slice(0, 1800), color: COLORS[x.level] || COLORS.info, footer: { text: l.server_name }, timestamp: new Date(x.at * 1000).toISOString() }] } }); }
  pump();
}
const okUrl = u => typeof u === 'string' && /^https:\/\/(discord|discordapp)\.com\/api\/webhooks\/\d+\/[\w-]+$/.test(u);
module.exports = { logs, okUrl, EVENTS: ['staff', 'error', 'connexion'] };
