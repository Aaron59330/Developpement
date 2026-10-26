const router = require('express').Router(); const { db, now } = require('../lib/db'); const A = require('../lib/auth');
router.get('/plans', (req, res) => res.json({ ok: true, plans: db.prepare('SELECT id,name,price,days,max_players,description FROM plans WHERE active=1 ORDER BY price').all() }));
module.exports = router;
