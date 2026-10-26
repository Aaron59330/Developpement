// Boutique publique : offres visibles sans compte, commandes des clients, validation par l'admin (paiement manuel : virement, PayPal, Discord…)
const router = require('express').Router(); const rateLimit = require('express-rate-limit');
const { db, now, audit, genKey } = require('../lib/db'); const A = require('../lib/auth'); const cfg = require('../lib/config');
const lim = rateLimit({ windowMs: 10 * 60 * 1000, limit: 15, standardHeaders: true, legacyHeaders: false, message: { ok: false, error: 'Trop de demandes, réessaie dans quelques minutes' } });
const getSet = (k, d = '') => { const r = db.prepare('SELECT value FROM settings WHERE key=?').get(k); return r ? r.value : d; };
const setSet = (k, v) => db.prepare('INSERT INTO settings(key,value) VALUES(?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value').run(k, String(v));
const shopInfo = () => ({ pay: getSet('shop.pay', 'Contacte-nous pour régler ta commande : elle est activée dès réception du paiement.'), contact: getSet('shop.contact', ''), name: getSet('shop.name', 'AERO') });
const publicPlans = () => db.prepare("SELECT id,name,price,days,max_players,description FROM plans WHERE active=1 AND name<>'Essai' ORDER BY price, id").all();

// ── public ──
router.get('/plans', (req, res) => res.json({ ok: true, plans: publicPlans(), shop: shopInfo(), trialDays: cfg.trialDays, allowRegister: cfg.allowRegister }));

// ── client ──
router.get('/orders', A.needUser, (req, res) => res.json({ ok: true, shop: shopInfo(), orders: db.prepare('SELECT id,plan_id,plan_name,amount,status,renew_license_id,license_id,created_at,paid_at FROM orders WHERE user_id=? ORDER BY id DESC LIMIT 50').all(req.user.id) }));
router.post('/orders', A.needUser, lim, (req, res) => {
  const plan = db.prepare("SELECT * FROM plans WHERE id=? AND active=1 AND name<>'Essai'").get(+(req.body || {}).plan_id); if (!plan) return res.json({ ok: false, error: 'Offre introuvable' });
  let renew = null; const rid = +(req.body || {}).renew_license_id;
  if (rid) { renew = db.prepare('SELECT id FROM licenses WHERE id=? AND user_id=?').get(rid, req.user.id); if (!renew) return res.json({ ok: false, error: 'Licence introuvable' }); }
  const dup = db.prepare("SELECT id FROM orders WHERE user_id=? AND plan_id=? AND status='pending' AND COALESCE(renew_license_id,0)=?").get(req.user.id, plan.id, renew ? renew.id : 0);
  if (dup) return res.json({ ok: true, id: dup.id, existing: true });
  if (db.prepare("SELECT COUNT(*) n FROM orders WHERE user_id=? AND status='pending'").get(req.user.id).n >= 5) return res.json({ ok: false, error: 'Tu as déjà 5 commandes en attente' });
  const id = db.prepare('INSERT INTO orders(user_id,plan_id,plan_name,amount,renew_license_id,created_at) VALUES(?,?,?,?,?,?)').run(req.user.id, plan.id, plan.name, plan.price, renew ? renew.id : null, now()).lastInsertRowid;
  audit(req.user.id, null, 'order:create', `#${id} ${plan.name}`, A.ip(req)); res.json({ ok: true, id });
});
router.post('/orders/:id/cancel', A.needUser, (req, res) => {
  const r = db.prepare("UPDATE orders SET status='cancelled' WHERE id=? AND user_id=? AND status='pending'").run(+req.params.id, req.user.id); res.json({ ok: r.changes > 0 });
});

// ── admin ──
router.get('/admin/orders', A.needUser, A.needAdmin, (req, res) => res.json({ ok: true, shop: { ...shopInfo() }, orders: db.prepare('SELECT o.*,u.email FROM orders o LEFT JOIN users u ON u.id=o.user_id ORDER BY (o.status=\'pending\') DESC, o.id DESC LIMIT 200').all() }));
router.post('/admin/settings', A.needUser, A.needAdmin, (req, res) => {
  const b = req.body || {}; for (const k of ['pay', 'contact', 'name']) if (b[k] !== undefined) setSet('shop.' + k, String(b[k]).slice(0, 600)); audit(req.user.id, null, 'shop:settings', '', A.ip(req)); res.json({ ok: true });
});
router.post('/admin/orders/:id/validate', A.needUser, A.needAdmin, (req, res) => {
  const o = db.prepare('SELECT * FROM orders WHERE id=?').get(+req.params.id); if (!o) return res.json({ ok: false, error: 'Introuvable' }); if (o.status !== 'pending') return res.json({ ok: false, error: 'Commande déjà traitée' });
  const plan = db.prepare('SELECT * FROM plans WHERE id=?').get(o.plan_id); const days = plan ? plan.days : 30; let lid = null;
  const run = db.transaction(() => {
    const ren = o.renew_license_id ? db.prepare('SELECT * FROM licenses WHERE id=? AND user_id=?').get(o.renew_license_id, o.user_id) : null;
    if (ren) { lid = ren.id; db.prepare("UPDATE licenses SET status='active', plan_id=?, expires_at=? WHERE id=?").run(o.plan_id, days ? Math.max(now(), ren.expires_at || 0) + days * 86400 : null, ren.id); }
    else lid = db.prepare('INSERT INTO licenses(key,user_id,plan_id,server_name,status,expires_at,created_at) VALUES(?,?,?,?,?,?,?)').run(genKey(), o.user_id, o.plan_id, 'Mon serveur', 'active', days ? now() + days * 86400 : null, now()).lastInsertRowid;
    db.prepare("UPDATE orders SET status='paid', paid_at=?, license_id=? WHERE id=?").run(now(), lid, o.id);
  }); run();
  audit(req.user.id, lid, 'order:validate', `#${o.id}`, A.ip(req)); res.json({ ok: true, license_id: lid });
});
router.post('/admin/orders/:id/cancel', A.needUser, A.needAdmin, (req, res) => { const r = db.prepare("UPDATE orders SET status='cancelled' WHERE id=? AND status='pending'").run(+req.params.id); audit(req.user.id, null, 'order:cancel', '#' + req.params.id, A.ip(req)); res.json({ ok: r.changes > 0 }); });
module.exports = router;
