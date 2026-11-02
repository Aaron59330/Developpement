// Met une action validée dans la file du serveur FiveM (utilisé par le planificateur et l'assistant IA)
const { db, now } = require('./db'); const C = require('./commands'); const bus = require('./bus');
function enqueue(licenseId, type, payload, userId) {
  const v = C.validate(type, payload); if (v.error) return { ok: false, error: v.error };
  if (type === 'settings_profile') return require('../routes/server-extra').applyProfile(licenseId, v.payload.profile, userId);
  const pending = db.prepare("SELECT COUNT(*) n FROM commands WHERE license_id=? AND status='pending'").get(licenseId).n; if (pending > 100) return { ok: false, error: 'Trop de commandes en attente (serveur hors ligne ?)' };
  const id = db.prepare('INSERT INTO commands(license_id,type,payload,created_at,by_user) VALUES(?,?,?,?,?)').run(licenseId, type, JSON.stringify(v.payload), now(), userId || null).lastInsertRowid;
  bus.wake(licenseId); return { ok: true, id };
}
module.exports = { enqueue };
