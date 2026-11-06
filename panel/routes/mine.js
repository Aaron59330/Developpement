// Espace du client : ses licences
const router = require('express').Router();
const { db } = require('../lib/db'); const A = require('../lib/auth');
router.get('/licenses', A.needUser, (req, res) => res.json({ ok: true, licenses: db.prepare('SELECT l.id,l.key,l.server_name,l.status,l.expires_at,l.created_at,p.name plan FROM licenses l LEFT JOIN plans p ON p.id=l.plan_id WHERE l.user_id=? ORDER BY l.id DESC').all(req.user.id) }));
module.exports = router;
