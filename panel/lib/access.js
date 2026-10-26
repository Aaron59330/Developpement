const { db } = require('./db');
// renvoie la licence si l'utilisateur en est propriétaire (ou admin), sinon répond 404
function own(req, res) {
  const l = db.prepare('SELECT l.*, p.name plan_name, p.max_players plan_max, u.email owner FROM licenses l LEFT JOIN plans p ON p.id=l.plan_id LEFT JOIN users u ON u.id=l.user_id WHERE l.id=?').get(+req.params.id);
  if (!l || (req.user.role !== 'admin' && l.user_id !== req.user.id)) { res.status(404).json({ ok: false, error: 'Serveur introuvable' }); return null; }
  return l;
}
const active = l => l.status === 'active' && !(l.expires_at && l.expires_at < Math.floor(Date.now() / 1000));
module.exports = { own, active };
