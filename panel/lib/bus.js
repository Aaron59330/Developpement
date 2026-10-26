// Pont entre le navigateur et le serveur FiveM : réveil des requêtes longues (long-poll) et appels « RPC » (lire un fichier, etc.)
const { db, now } = require('./db');
const waiters = new Map();   // licenseId -> [{ res, timer }]
const rpcs = new Map();      // commandId -> { resolve, timer }
function wake(licenseId) { const w = waiters.get(licenseId); if (!w) return; waiters.delete(licenseId); for (const x of w) { clearTimeout(x.timer); x.fire(); } }
function wait(licenseId, ms, fire) { const t = setTimeout(() => { const l = waiters.get(licenseId) || []; waiters.set(licenseId, l.filter(x => x !== item)); fire(); }, ms); const item = { timer: t, fire }; const l = waiters.get(licenseId) || []; l.push(item); waiters.set(licenseId, l); return () => { clearTimeout(t); const cur = waiters.get(licenseId) || []; waiters.set(licenseId, cur.filter(x => x !== item)); }; }
// envoie une commande et attend la réponse du serveur (max timeoutMs)
function rpc(licenseId, type, payload, userId, timeoutMs = 20000) {
  const id = db.prepare('INSERT INTO commands(license_id,type,payload,created_at,by_user) VALUES(?,?,?,?,?)').run(licenseId, type, JSON.stringify(payload), now(), userId || null).lastInsertRowid;
  return new Promise(resolve => {
    const timer = setTimeout(() => { rpcs.delete(id); db.prepare("UPDATE commands SET status='failed', result='délai dépassé', done_at=? WHERE id=? AND status<>'done'").run(now(), id); resolve({ ok: false, error: 'Le serveur n’a pas répondu à temps (est-il en ligne ?)' }); }, timeoutMs);
    rpcs.set(id, { resolve, timer }); wake(licenseId);
  });
}
function deliver(id, ok, result, data) { const r = rpcs.get(+id); if (!r) return false; clearTimeout(r.timer); rpcs.delete(+id); r.resolve(ok ? { ok: true, data } : { ok: false, error: String(result || 'Échec') }); return true; }
module.exports = { wake, wait, rpc, deliver };
