#!/usr/bin/env node
'use strict';
/*
 * Pickax Panel — panel web centralisé (sans dépendance, Node 18+).
 *
 *   node server.js            → http://localhost:3000
 *
 * Fonctionnement (comme un panel d'hébergeur de core) :
 *   1. Tu te connectes au panel, tu ajoutes un serveur ("Mes serveurs") → une CLÉ DE LIAISON est générée.
 *   2. Tu colles UNE ligne dans le server.cfg du serveur de jeu :  set pickax_panel_key "..."
 *   3. La ressource pickax_panel du serveur appelle le panel toutes les 15 s (sortant : aucun port à ouvrir),
 *      envoie la liste des réglages de TES scripts + leurs valeurs, et applique ce que tu enregistres sur le site.
 */
const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PORT = parseInt(process.env.PORT || '3000', 10);
const HOST = process.env.HOST || '0.0.0.0';
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'panel.json');
const PUBLIC_DIR = path.join(__dirname, 'public');
const PUBLIC_URL = (process.env.PUBLIC_URL || '').replace(/\/+$/, '');
const ONLINE_MS = 60 * 1000;

// ───────────── Stockage (fichier JSON, écriture atomique) ─────────────
fs.mkdirSync(DATA_DIR, { recursive: true });
let db = { secret: crypto.randomBytes(32).toString('hex'), users: [], servers: [] };
try { db = Object.assign(db, JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'))); } catch (e) { /* premier lancement */ }
let saveTimer = null;
function save() {
  if (saveTimer) return;
  saveTimer = setTimeout(function () {
    saveTimer = null;
    const tmp = DATA_FILE + '.tmp';
    fs.writeFileSync(tmp, JSON.stringify(db), { mode: 0o600 });
    fs.renameSync(tmp, DATA_FILE);
  }, 250);
}
save();
process.on('SIGINT', function () { try { fs.writeFileSync(DATA_FILE, JSON.stringify(db), { mode: 0o600 }); } catch (e) {} process.exit(0); });

// ───────────── Utilitaires ─────────────
const sha = function (s) { return crypto.createHash('sha256').update(s).digest('hex'); };
const rid = function (n) { return crypto.randomBytes(n).toString('hex'); };
function safeEq(a, b) {
  const x = Buffer.from(String(a)), y = Buffer.from(String(b));
  return x.length === y.length && crypto.timingSafeEqual(x, y);
}
function hashPass(pass, salt) { return crypto.scryptSync(pass, salt, 64).toString('hex'); }
function b64(s) { return Buffer.from(s).toString('base64url'); }
function sign(payload) { return b64(JSON.stringify(payload)) + '.' + crypto.createHmac('sha256', db.secret).update(b64(JSON.stringify(payload))).digest('base64url'); }
function unsign(token) {
  if (!token || token.indexOf('.') < 0) return null;
  const i = token.lastIndexOf('.'), body = token.slice(0, i);
  const good = crypto.createHmac('sha256', db.secret).update(body).digest('base64url');
  if (!safeEq(good, token.slice(i + 1))) return null;
  try { const p = JSON.parse(Buffer.from(body, 'base64url').toString()); return p.exp > Date.now() ? p : null; } catch (e) { return null; }
}
function cookies(req) {
  const out = {};
  String(req.headers.cookie || '').split(';').forEach(function (c) { const i = c.indexOf('='); if (i > 0) out[c.slice(0, i).trim()] = c.slice(i + 1).trim(); });
  return out;
}
function send(res, code, body, type, extra) {
  const h = Object.assign({
    'Content-Type': type || 'application/json; charset=utf-8', 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY', 'Referrer-Policy': 'no-referrer',
    'Content-Security-Policy': "default-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self'"
  }, extra || {});
  res.writeHead(code, h);
  res.end(typeof body === 'string' || Buffer.isBuffer(body) ? body : JSON.stringify(body));
}
const json = function (res, code, obj, extra) { send(res, code, JSON.stringify(obj), undefined, extra); };
function readBody(req, limit) {
  return new Promise(function (resolve, reject) {
    const chunks = []; let n = 0;
    req.on('data', function (c) { n += c.length; if (n > limit) { reject(new Error('trop gros')); req.destroy(); } else chunks.push(c); });
    req.on('end', function () {
      if (!n) return resolve({});
      try { const o = JSON.parse(Buffer.concat(chunks).toString('utf8')); resolve(o && typeof o === 'object' ? o : {}); } catch (e) { reject(new Error('JSON invalide')); }
    });
    req.on('error', reject);
  });
}
const fails = new Map();
function blocked(ip) { const f = fails.get(ip); return f && f.n >= 8 && Date.now() < f.t + 600000; }
function failed(ip) { let f = fails.get(ip); if (!f || Date.now() > f.t + 600000) f = { n: 0 }; f.n++; f.t = Date.now(); fails.set(ip, f); }
function baseUrl(req) {
  if (PUBLIC_URL) return PUBLIC_URL;
  const proto = String(req.headers['x-forwarded-proto'] || 'http').split(',')[0];
  return proto + '://' + (req.headers['x-forwarded-host'] || req.headers.host);
}

// ───────────── Validation des valeurs (même règles que la ressource du serveur) ─────────────
function validate(f, v) {
  const bad = function (m) { return { err: m }; };
  switch (f.type) {
    case 'bool': return typeof v === 'boolean' ? { v: v } : bad('booléen attendu');
    case 'number': {
      v = Number(v);
      if (!isFinite(v)) return bad('nombre attendu');
      if (f.min != null && v < f.min) return bad('minimum ' + f.min);
      if (f.max != null && v > f.max) return bad('maximum ' + f.max);
      return { v: f.int ? Math.round(v) : v };
    }
    case 'color': return typeof v === 'string' && /^#[0-9a-fA-F]{6}$/.test(v) ? { v: v.toLowerCase() } : bad('couleur #RRGGBB attendue');
    case 'rgba': {
      if (!Array.isArray(v)) return bad('couleur attendue');
      const n = f.alpha === false ? 3 : 4, out = [];
      for (let i = 0; i < n; i++) { const x = Number(v[i]); if (!isFinite(x)) return bad('couleur invalide'); out.push(Math.max(0, Math.min(255, Math.round(x)))); }
      return { v: out };
    }
    case 'text': case 'css': case 'url': {
      if (typeof v !== 'string') return bad('texte attendu');
      if (v.length > (f.max || 200)) return bad('trop long');
      if (/[\u0000-\u001f\u007f]/.test(v)) return bad('caractères de contrôle interdits');
      if (f.type === 'css' && !/^[\w\s.,\-%#()\/:]*$/.test(v)) return bad('valeur CSS invalide');
      if (f.type === 'url' && v !== '' && !/^https?:\/\/[^\s"'<>\\]+$/.test(v)) return bad('lien http(s) attendu');
      return { v: v };
    }
    case 'items': {
      if (!Array.isArray(v)) return bad('liste attendue');
      const out = [];
      for (const s of v) {
        if (typeof s !== 'string' || s.length > 140 || /[\u0000-\u001f\u007f]/.test(s)) return bad('ligne invalide');
        if (s !== '') out.push(s);
      }
      return out.length > 20 ? bad('20 lignes maximum') : { v: out };
    }
  }
  return bad('type inconnu');
}
const same = function (a, b) { return JSON.stringify(a) === JSON.stringify(b); };

// ───────────── Données serveur ─────────────
function findServer(id) { return db.servers.find(function (s) { return s.id === id; }); }
function logAdd(s, who, field, label, from, to, source) {
  s.log.unshift({ at: Date.now(), who: who, field: field, label: label, from: from, to: to, source: source });
  if (s.log.length > 200) s.log.length = 200;
}
function fieldIndex(s) {
  const idx = {};
  (s.catalog && s.catalog.groups || []).forEach(function (g) { g.fields.forEach(function (f) { idx[f.id] = f; f.group = g.id; }); });
  return idx;
}
function summary(s) {
  const online = s.lastSeen && Date.now() - s.lastSeen < ONLINE_MS;
  return {
    id: s.id, name: s.name, online: !!online, lastSeen: s.lastSeen || null, players: s.info && s.info.players, maxPlayers: s.info && s.info.maxPlayers,
    hostname: s.info && s.info.hostname, linked: !!s.catalog, changes: Object.keys(s.overrides).length,
    pending: Object.keys(s.overrides).filter(function (k) { return s.overrides[k].status !== 'applied'; }).length
  };
}
function detail(s) {
  const idx = fieldIndex(s), groups = [];
  ((s.catalog && s.catalog.groups) || []).forEach(function (g) {
    groups.push(Object.assign({}, g, {
      fields: g.fields.map(function (f) {
        const o = s.overrides[f.id], out = Object.assign({}, f);
        if (o) { out.serverValue = f.value; out.value = o.value; out.modified = true; out.original = o.original; out.status = o.status; out.statusError = o.error; }
        return out;
      })
    }));
  });
  return Object.assign(summary(s), { groups: groups, resources: (s.info && s.info.resources) || {}, pendingRestart: (s.pendingRestart || []), log: s.log.slice(0, 60) });
}

// ───────────── API panel (session) ─────────────
function session(req) {
  const p = unsign(cookies(req).px_s);
  return p && db.users.find(function (u) { return u.name === p.u; }) ? p : null;
}
async function api(req, res, url) {
  const ip = req.socket.remoteAddress;
  const parts = url.pathname.replace(/^\/api\//, '').split('/').filter(Boolean);
  const method = req.method;

  // ---- agent (serveur de jeu) ----
  if (parts[0] === 'agent' && parts[1] === 'sync' && method === 'POST') {
    if (blocked(ip)) return json(res, 429, { error: 'trop d\'essais' });
    const lic = String(req.headers['x-license'] || '');
    const h = sha(lic);
    const s = db.servers.find(function (x) { return safeEq(x.keyHash, h); });
    if (!s) { failed(ip); return json(res, 401, { error: 'licence invalide' }); }
    const body = await readBody(req, 2 * 1024 * 1024);
    s.lastSeen = Date.now();
    if (body.groups) s.catalog = { groups: body.groups, at: Date.now() };
    s.info = body.info || s.info || {};
    // accusés de réception
    const acks = body.acks || {};
    Object.keys(acks).forEach(function (id) {
      const o = s.overrides[id], a = acks[id];
      if (!o || !same(a.value, o.value)) return;           // accusé périmé (la valeur a changé depuis)
      if (a.ok) { if (o.clear) { delete s.overrides[id]; } else { o.status = 'applied'; o.error = undefined; o.restart = false; } }
      else { o.status = 'error'; o.error = String(a.err || 'erreur'); o.restart = false; }
    });
    s.pendingRestart = Array.isArray(body.pendingRestart) ? body.pendingRestart.map(String) : [];
    const desired = {};
    Object.keys(s.overrides).forEach(function (id) {
      const o = s.overrides[id];
      if (o.status === 'error') return;                    // on n'insiste pas tant que l'utilisateur ne corrige pas
      desired[id] = { value: o.value, restart: !!o.restart, clear: !!o.clear, status: o.status };
    });
    const restart = s.restartQueue || []; s.restartQueue = [];
    save();
    return json(res, 200, { desired: desired, restart: restart, interval: 15 });
  }

  // ---- compte ----
  if (parts[0] === 'me' && method === 'GET') {
    const p = session(req);
    return json(res, 200, { setup: db.users.length === 0, user: p ? p.u : null });
  }
  if (parts[0] === 'setup' && method === 'POST') {
    if (db.users.length) return json(res, 403, { error: 'déjà configuré' });
    const b = await readBody(req, 4096);
    if (!/^[\w.\-]{3,32}$/.test(b.user || '') || String(b.pass || '').length < 8) return json(res, 400, { error: 'Identifiant 3-32 caractères, mot de passe 8 caractères minimum.' });
    const salt = rid(16);
    db.users.push({ name: b.user, salt: salt, hash: hashPass(b.pass, salt) }); save();
    return loginOk(res, req, b.user);
  }
  if (parts[0] === 'login' && method === 'POST') {
    if (blocked(ip)) return json(res, 429, { error: 'Trop d\'essais, réessaie dans 10 minutes.' });
    const b = await readBody(req, 4096);
    const u = db.users.find(function (x) { return x.name === b.user; });
    const ok = u && safeEq(hashPass(String(b.pass || ''), u.salt), u.hash);
    if (!ok) { failed(ip); return json(res, 401, { error: 'Identifiant ou mot de passe incorrect.' }); }
    fails.delete(ip);
    return loginOk(res, req, u.name);
  }
  if (parts[0] === 'logout' && method === 'POST') {
    return json(res, 200, { ok: true }, { 'Set-Cookie': 'px_s=; Path=/; HttpOnly; SameSite=Strict; Max-Age=0' });
  }

  // ---- le reste exige une session + en-tête anti-CSRF ----
  const sess = session(req);
  if (!sess) return json(res, 401, { error: 'Non connecté' });
  if (method !== 'GET' && req.headers['x-requested-with'] !== 'px') return json(res, 403, { error: 'Requête refusée' });
  const who = sess.u;

  if (parts[0] === 'servers' && parts.length === 1) {
    if (method === 'GET') return json(res, 200, { servers: db.servers.map(summary) });
    if (method === 'POST') {
      const b = await readBody(req, 4096);
      const name = String(b.name || '').trim().slice(0, 60);
      if (!name) return json(res, 400, { error: 'Nom requis' });
      const secret = rid(20);
      const s = { id: rid(6), name: name, keyHash: sha(secret), createdAt: Date.now(), overrides: {}, log: [], restartQueue: [] };
      db.servers.push(s); save();
      return json(res, 200, { id: s.id, secret: secret, url: baseUrl(req) });
    }
  }
  if (parts[0] === 'servers' && parts[1]) {
    const s = findServer(parts[1]);
    if (!s) return json(res, 404, { error: 'Serveur introuvable' });
    const act = parts[2];

    if (!act && method === 'GET') return json(res, 200, detail(s));
    if (!act && method === 'DELETE') { db.servers = db.servers.filter(function (x) { return x !== s; }); save(); return json(res, 200, { ok: true }); }
    if (act === 'regenerate' && method === 'POST') {
      const secret = rid(20); s.keyHash = sha(secret); s.lastSeen = null; save();
      return json(res, 200, { secret: secret, url: baseUrl(req) });
    }
    if (act === 'rename' && method === 'POST') {
      const b = await readBody(req, 4096); const n = String(b.name || '').trim().slice(0, 60);
      if (!n) return json(res, 400, { error: 'Nom requis' });
      s.name = n; save(); return json(res, 200, { ok: true });
    }
    if (act === 'save' && method === 'POST') {
      const b = await readBody(req, 512 * 1024);
      if (!b.changes || typeof b.changes !== 'object') return json(res, 400, { error: 'Aucun changement' });
      const idx = fieldIndex(s);
      const staged = [];
      for (const id of Object.keys(b.changes)) {
        const f = idx[id];
        if (!f) return json(res, 400, { error: 'Réglage inconnu : ' + id });
        if (f.error) return json(res, 400, { error: f.label + ' : ' + f.error });
        const r = validate(f, b.changes[id]);
        if (r.err) return json(res, 400, { error: f.label + ' : ' + r.err });
        staged.push([f, r.v]);
      }
      let n = 0;
      staged.forEach(function (p) {
        const f = p[0], v = p[1], o = s.overrides[f.id];
        const current = o ? o.value : f.value;
        if (same(v, current) && (!o || o.status === 'applied')) return;
        n++;
        s.overrides[f.id] = { value: v, original: o ? o.original : f.value, status: 'pending', restart: b.apply === true, at: Date.now() };
        logAdd(s, who, f.id, f.label, current, v, 'panel');
      });
      save();
      return json(res, 200, { saved: n });
    }
    if (act === 'reset' && method === 'POST') {
      const b = await readBody(req, 64 * 1024);
      let n = 0;
      (Array.isArray(b.ids) ? b.ids : []).forEach(function (id) {
        const o = s.overrides[id]; if (!o) return;
        const f = fieldIndex(s)[id];
        logAdd(s, who, id, f ? f.label : id, o.value, o.original, 'restauration');
        s.overrides[id] = { value: o.original, original: o.original, status: 'pending', restart: b.apply === true, clear: true, at: Date.now() };
        n++;
      });
      save();
      return json(res, 200, { restored: n });
    }
    if (act === 'restart' && method === 'POST') {
      const b = await readBody(req, 4096);
      const known = ((s.catalog && s.catalog.groups) || []).some(function (g) { return g.resource === b.resource; });
      if (!known) return json(res, 400, { error: 'Ressource non gérée par le panel' });
      if (s.restartQueue.indexOf(b.resource) < 0) s.restartQueue.push(b.resource);
      save();
      return json(res, 200, { queued: b.resource });
    }
  }
  return json(res, 404, { error: 'Route inconnue' });
}
function loginOk(res, req, user) {
  const secure = /^https/.test(baseUrl(req)) ? '; Secure' : '';
  const token = sign({ u: user, exp: Date.now() + 7 * 24 * 3600 * 1000 });
  return json(res, 200, { user: user }, { 'Set-Cookie': 'px_s=' + token + '; Path=/; HttpOnly; SameSite=Strict; Max-Age=' + 7 * 24 * 3600 + secure });
}

// ───────────── Fichiers statiques ─────────────
const TYPES = { '.html': 'text/html; charset=utf-8', '.js': 'application/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.svg': 'image/svg+xml', '.png': 'image/png', '.ico': 'image/x-icon' };
function serveStatic(req, res, url) {
  let p = decodeURIComponent(url.pathname);
  if (p === '/') p = '/index.html';
  const full = path.normalize(path.join(PUBLIC_DIR, p));
  if (full.indexOf(PUBLIC_DIR) !== 0) return send(res, 403, 'interdit', 'text/plain');
  fs.readFile(full, function (err, data) {
    if (err) return send(res, 404, 'introuvable', 'text/plain');
    send(res, 200, data, TYPES[path.extname(full)] || 'application/octet-stream');
  });
}

http.createServer(function (req, res) {
  const url = new URL(req.url, 'http://x');
  if (url.pathname.indexOf('/api/') === 0) {
    api(req, res, url).catch(function (e) {
      if (!res.headersSent) json(res, 400, { error: e.message || 'Erreur' });
    });
  } else if (req.method === 'GET') {
    serveStatic(req, res, url);
  } else {
    send(res, 405, 'méthode non autorisée', 'text/plain');
  }
}).listen(PORT, HOST, function () {
  console.log('Pickax Panel : http://localhost:' + PORT + (db.users.length ? '' : '   (premier lancement : crée ton compte administrateur sur la page)'));
});
