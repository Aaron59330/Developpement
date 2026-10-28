const express = require('express'), helmet = require('helmet'), cookieParser = require('cookie-parser'), path = require('path');
const cfg = require('./lib/config'); const { db, now } = require('./lib/db'); const A = require('./lib/auth');
const app = express();
if (cfg.trustProxy) app.set('trust proxy', 1);
app.disable('x-powered-by');
// En HTTP simple (test, accès par IP) il ne faut ni « upgrade-insecure-requests » ni HSTS, sinon le navigateur casse le site
const secureSite = cfg.publicUrl.startsWith('https://');
app.use(helmet({ hsts: secureSite, contentSecurityPolicy: { directives: { defaultSrc: ["'self'"], scriptSrc: ["'self'"], styleSrc: ["'self'", "'unsafe-inline'"], imgSrc: ["'self'", 'data:', 'https:', 'http:'], connectSrc: ["'self'"], objectSrc: ["'none'"], frameAncestors: ["'none'"], upgradeInsecureRequests: secureSite ? [] : null } }, crossOriginOpenerPolicy: secureSite ? undefined : false, originAgentCluster: secureSite ? undefined : false }));
app.use('/api/agent', require('./routes/agent'));
// corps JSON : 2 Mo, sauf l'envoi de fichiers au Drive (musique jusqu'à 6 Mo, en base64) réservé aux requêtes qui portent un cookie de session
const smallJson = express.json({ limit: '2mb' }), bigJson = express.json({ limit: '9mb' });
app.use((req, res, next) => (req.method === 'POST' && /^\/api\/servers\/\d+\/drive$/.test(req.path) && String(req.headers.cookie || '').includes(A.COOKIE + '=') ? bigJson : smallJson)(req, res, next));
app.use(cookieParser());
app.use(A.loadUser);
app.use(A.csrf);
app.use('/drive', require('./routes/drive-public'));
app.use('/api/auth', require('./routes/auth'));
app.use('/api/servers', require('./routes/servers'));
app.use('/api/servers', require('./routes/server-extra'));
app.use('/api/servers', require('./routes/discord'));
app.use('/api/servers', require('./routes/files'));
app.use('/api/servers', require('./routes/base'));
app.use('/api/servers', require('./routes/planner'));
app.use('/api/servers', require('./routes/assistant'));
app.use('/api/shop', require('./routes/shop'));
app.use('/api/support', require('./routes/support'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api', require('./routes/misc'));
app.use('/api', (req, res) => res.status(404).json({ ok: false, error: 'Route inconnue' }));
app.use(express.static(path.join(__dirname, 'public'), { extensions: ['html'], maxAge: '5m' }));
app.get('*', (req, res) => res.sendFile(path.join(__dirname, 'public', 'index.html')));
app.use((err, req, res, next) => { console.error('[panel]', err.message); res.status(err.status || 500).json({ ok: false, error: err.status === 400 ? 'Requête invalide' : 'Erreur serveur' }); });
// nettoyage périodique
setInterval(() => { db.prepare('DELETE FROM sessions WHERE expires_at<?').run(now()); db.prepare("DELETE FROM commands WHERE created_at<? AND status IN ('done','failed')").run(now() - 30 * 86400); }, 3600 * 1000).unref();
if (require.main === module) require('./lib/scheduler').start();
if (require.main === module) app.listen(cfg.port, () => console.log(`[panel] http://localhost:${cfg.port}`));
module.exports = app;
