// Stats détaillées, webhooks Discord, Drive, modules, sauvegardes, journal d'activité du serveur
const router = require('express').Router(); const crypto = require('crypto'), fs = require('fs'), path = require('path');
const { db, now, audit } = require('../lib/db'); const A = require('../lib/auth'); const C = require('../lib/commands'); const bus = require('../lib/bus'); const cfg = require('../lib/config'); const hooks = require('../lib/hooks');
const { own, active } = require('../lib/access');
router.use(A.needUser);
const queue = (l, uid, type, payload) => { const id = db.prepare('INSERT INTO commands(license_id,type,payload,created_at,by_user) VALUES(?,?,?,?,?)').run(l.id, type, JSON.stringify(payload), now(), uid).lastInsertRowid; bus.wake(l.id); return id; };

// ───────── réglages du serveur (schéma envoyé par pickax_settings) ─────────
const SET = require('../lib/settings');
const docOf = (lid, key) => { const d = db.prepare('SELECT value,version FROM docs WHERE license_id=? AND key=?').get(lid, key); return d ? { v: JSON.parse(d.value), version: d.version } : null; };
router.get('/:id/settings', (req, res) => { const l = own(req, res); if (!l) return; const sch = docOf(l.id, 'settings_schema'), ov = docOf(l.id, 'settings'); res.json({ ok: true, schema: sch ? sch.v : [], overrides: ov ? ov.v : {}, ready: !!sch }); });
// Enregistre les réglages modifiés d'un serveur et garde l'historique (qui, quand, avant → après) pour pouvoir revenir en arrière
function saveSettings(l, user, ip, overrides, source) {
  const prev = (docOf(l.id, 'settings') || { v: {} }).v || {};
  const changes = {};
  for (const k of new Set([...Object.keys(prev), ...Object.keys(overrides)])) if (JSON.stringify(prev[k]) !== JSON.stringify(overrides[k])) changes[k] = { from: prev[k] === undefined ? null : prev[k], to: overrides[k] === undefined ? null : overrides[k] };
  db.prepare('INSERT INTO docs(license_id,key,value,version,updated_at) VALUES(?,?,?,?,?) ON CONFLICT(license_id,key) DO UPDATE SET value=excluded.value, version=docs.version+1, updated_at=excluded.updated_at').run(l.id, 'settings', JSON.stringify(overrides), 1, now());
  if (Object.keys(changes).length) {
    db.prepare('INSERT INTO settings_history(license_id,user_id,at,source,changes,before) VALUES(?,?,?,?,?,?)').run(l.id, user.id, now(), source, JSON.stringify(changes), JSON.stringify(prev));
    db.prepare('DELETE FROM settings_history WHERE license_id=? AND id NOT IN (SELECT id FROM settings_history WHERE license_id=? ORDER BY id DESC LIMIT 200)').run(l.id, l.id);
  }
  audit(user.id, l.id, 'doc:settings', Object.keys(changes).join(',').slice(0, 200), ip); bus.wake(l.id);
  return Object.keys(changes).length;
}
router.put('/:id/settings', (req, res) => {
  const l = own(req, res); if (!l) return; const sch = docOf(l.id, 'settings_schema'); if (!sch) return res.json({ ok: false, error: 'Les réglages ne sont pas encore disponibles : la ressource pickax_settings doit tourner sur ton serveur.' });
  const { overrides, errors } = SET.validate(sch.v, (req.body || {}).values); if (errors.length) return res.json({ ok: false, error: 'Valeur invalide : ' + errors.slice(0, 3).join(', ') });
  saveSettings(l, req.user, A.ip(req), overrides, 'panel'); res.json({ ok: true, count: Object.keys(overrides).length });
});
// Profil de serveur : applique un ensemble de réglages par-dessus les réglages actuels (les clés inconnues du serveur sont ignorées)
router.post('/:id/settings/profile', (req, res) => {
  const l = own(req, res); if (!l) return; const sch = docOf(l.id, 'settings_schema'); if (!sch) return res.json({ ok: false, error: 'Les réglages ne sont pas encore disponibles : la ressource pickax_settings doit tourner sur ton serveur.' });
  const b = req.body || {}; const values = b.values && typeof b.values === 'object' ? b.values : {}; const known = new Set(sch.v.map(d => d.key));
  const merged = { ...((docOf(l.id, 'settings') || { v: {} }).v || {}) }; let skipped = 0;
  for (const [k, v] of Object.entries(values)) { if (!known.has(k)) { skipped++; continue; } merged[k] = v; }
  const { overrides, errors } = SET.validate(sch.v, merged); if (errors.length) return res.json({ ok: false, error: 'Valeur invalide : ' + errors.slice(0, 3).join(', ') });
  const n = saveSettings(l, req.user, A.ip(req), overrides, 'profil : ' + String(b.name || 'sans nom').slice(0, 40)); res.json({ ok: true, changed: n, skipped });
});
// Applique un profil de serveur sans requête HTTP (planificateur) : mêmes règles que POST /settings/profile
function applyProfile(licenseId, profileId, userId) {
  const l = db.prepare('SELECT * FROM licenses WHERE id=?').get(licenseId); const sch = docOf(licenseId, 'settings_schema'); const p = require('../lib/profiles').PROFILES.find(x => x.id === profileId);
  if (!l || !p) return { ok: false, error: 'Profil introuvable' }; if (!sch) return { ok: false, error: 'Réglages indisponibles : pickax_settings ne tourne pas' };
  const known = new Set(sch.v.map(d => d.key)); const merged = { ...((docOf(licenseId, 'settings') || { v: {} }).v || {}) };
  for (const [k, v] of Object.entries(p.values)) if (known.has(k)) merged[k] = v;
  const { overrides, errors } = SET.validate(sch.v, merged); if (errors.length) return { ok: false, error: 'Valeur invalide : ' + errors.slice(0, 3).join(', ') };
  const n = saveSettings(l, { id: userId || null }, 'planificateur', overrides, 'planificateur : ' + p.name); return { ok: true, id: 0, changed: n };
}
router.applyProfile = applyProfile;
// Export / import : un fichier JSON portable des réglages modifiés (les valeurs secrètes comme le webhook Discord ne sont jamais exportées)
router.get('/:id/settings/export', (req, res) => {
  const l = own(req, res); if (!l) return; const sch = (docOf(l.id, 'settings_schema') || { v: [] }).v; const secret = new Set(sch.filter(d => d.secret).map(d => d.key)); const ov = (docOf(l.id, 'settings') || { v: {} }).v || {};
  res.json({ ok: true, file: { format: 'aero-settings', version: 1, exported_at: now(), server: l.server_name, values: Object.fromEntries(Object.entries(ov).filter(([k]) => !secret.has(k))) } });
});
router.post('/:id/settings/import', (req, res) => {
  const l = own(req, res); if (!l) return; const sch = docOf(l.id, 'settings_schema'); if (!sch) return res.json({ ok: false, error: 'Les réglages ne sont pas encore disponibles : pickax_settings doit tourner sur ton serveur.' });
  const b = req.body || {}; const f = b.file; if (!f || f.format !== 'aero-settings' || !f.values || typeof f.values !== 'object' || Array.isArray(f.values)) return res.json({ ok: false, error: 'Ce fichier n’est pas un export de réglages AERO.' });
  const by = Object.fromEntries(sch.v.map(d => [d.key, d])); const cur = (docOf(l.id, 'settings') || { v: {} }).v || {}; const next = { ...cur }; const unknown = [], secret = [];
  for (const [k, v] of Object.entries(f.values).slice(0, 1000)) { if (!by[k]) { unknown.push(k); continue; } if (by[k].secret) { secret.push(k); continue; } next[k] = v; }
  const { overrides, errors } = SET.validate(sch.v, next); if (errors.length) return res.json({ ok: false, error: 'Valeur invalide : ' + errors.slice(0, 3).join(', ') });
  const diff = []; for (const k of new Set([...Object.keys(cur), ...Object.keys(overrides)])) if (JSON.stringify(cur[k]) !== JSON.stringify(overrides[k])) diff.push({ key: k, label: by[k] ? by[k].label : k, from: cur[k] === undefined ? null : cur[k], to: overrides[k] === undefined ? null : overrides[k], type: by[k] ? by[k].type : 'text' });
  if (!b.apply) return res.json({ ok: true, preview: true, diff, unknown, secret });
  const n = saveSettings(l, req.user, A.ip(req), overrides, 'import : ' + String(f.server || 'fichier').slice(0, 40)); res.json({ ok: true, changed: n, unknown, secret });
});
router.get('/:id/settings/profiles', (req, res) => {
  const l = own(req, res); if (!l) return; const sch = docOf(l.id, 'settings_schema'); const known = new Set(sch ? sch.v.map(d => d.key) : []);
  res.json({ ok: true, ready: !!sch, profiles: require('../lib/profiles').PROFILES.map(p => { const values = Object.fromEntries(Object.entries(p.values).filter(([k]) => known.has(k))); return { id: p.id, name: p.name, icon: p.icon, desc: p.desc, count: Object.keys(values).length, values }; }) });
});
router.get('/:id/diagnostic', (req, res) => {
  const l = own(req, res); if (!l) return; const st = db.prepare('SELECT * FROM server_state WHERE license_id=?').get(l.id);
  const logs = db.prepare("SELECT level,source,message,at FROM logs WHERE license_id=? AND level='error' AND at>? ORDER BY id DESC LIMIT 200").all(l.id, now() - 3600);
  const sch = docOf(l.id, 'settings_schema'), ov = docOf(l.id, 'settings'), th = docOf(l.id, 'theme');
  res.json(Object.assign({ ok: true }, require('../lib/diagnostic').run({ now: now(), license: l, lastSeen: l.last_seen, resources: st ? JSON.parse(st.resources || '[]') : [], players: st ? JSON.parse(st.players || '[]').length : 0, maxPlayers: st ? st.max_players : 0, stats: st ? JSON.parse(st.stats || '{}') : {}, settingsSchema: sch ? sch.v : [], overrides: ov ? ov.v : {}, logs, docs: { theme: th ? th.v : null } })));
});
// ───────── fiche joueur : recherche + statistiques + sanctions ─────────
router.get('/:id/players-db', (req, res) => {
  const l = own(req, res); if (!l) return; const q = String(req.query.q || '').trim().slice(0, 60).replace(/[%_]/g, '');
  const rows = q ? db.prepare("SELECT identifier,name,minutes,sessions,last_seen,last_job,online FROM player_stats WHERE license_id=? AND (name LIKE ? OR identifier LIKE ?) ORDER BY online DESC, last_seen DESC LIMIT 40").all(l.id, `%${q}%`, `%${q}%`)
    : db.prepare('SELECT identifier,name,minutes,sessions,last_seen,last_job,online FROM player_stats WHERE license_id=? ORDER BY online DESC, last_seen DESC LIMIT 40').all(l.id);
  res.json({ ok: true, total: db.prepare('SELECT COUNT(*) n FROM player_stats WHERE license_id=?').get(l.id).n, rows: rows.map(r => ({ ...r, minutes: Math.round(r.minutes) })) });
});
router.get('/:id/players-db/:ident', (req, res) => {
  const l = own(req, res); if (!l) return; const ident = String(req.params.ident).slice(0, 120);
  const p = db.prepare('SELECT * FROM player_stats WHERE license_id=? AND identifier=?').get(l.id, ident); if (!p) return res.json({ ok: false, error: 'Joueur inconnu' });
  const bans = (docOf(l.id, 'bans') || { v: [] }).v || [];
  const sanctions = [];
  for (const b of bans) if (b.identifier === ident) sanctions.push({ kind: 'ban', actif: true, reason: b.reason || '', at: b.at || b.created_at || null, by: b.by || '' });
  for (const c of db.prepare("SELECT type,payload,created_at,by_user FROM commands WHERE license_id=? AND type IN ('ban','unban','kick') AND payload LIKE ? ORDER BY id DESC LIMIT 20").all(l.id, `%${ident.replace(/[%_\\]/g, '')}%`)) {
    let pl = {}; try { pl = JSON.parse(c.payload); } catch (e) {}
    if (pl.identifier === ident || pl.name === p.name) sanctions.push({ kind: c.type, actif: false, reason: pl.reason || '', at: c.created_at });
  }
  res.json({ ok: true, player: { identifier: p.identifier, name: p.name, minutes: Math.round(p.minutes), sessions: p.sessions, first_seen: p.first_seen, last_seen: p.last_seen, last_job: p.last_job, money: p.last_money, bank: p.last_bank, max_money: p.max_money, online: !!p.online }, sanctions });
});
router.get('/:id/settings/history', (req, res) => {
  const l = own(req, res); if (!l) return; const sch = (docOf(l.id, 'settings_schema') || { v: [] }).v; const by = Object.fromEntries(sch.map(d => [d.key, d]));
  const users = {}; const rows = db.prepare('SELECT h.id,h.at,h.source,h.changes,h.user_id,u.username FROM settings_history h LEFT JOIN users u ON u.id=h.user_id WHERE h.license_id=? ORDER BY h.id DESC LIMIT 60').all(l.id);
  res.json({ ok: true, rows: rows.map(r => ({ id: r.id, at: r.at, source: r.source, user: r.username || '—', changes: Object.entries(JSON.parse(r.changes)).slice(0, 40).map(([k, c]) => ({ key: k, label: by[k] ? by[k].label : k, group: by[k] ? by[k].group : '', type: by[k] ? by[k].type : 'text', from: c.from, to: c.to })) })) });
});
router.post('/:id/settings/history/:hid/restore', (req, res) => {
  const l = own(req, res); if (!l) return; const sch = docOf(l.id, 'settings_schema'); if (!sch) return res.json({ ok: false, error: 'Réglages indisponibles' });
  const h = db.prepare('SELECT id,before FROM settings_history WHERE id=? AND license_id=?').get(+req.params.hid, l.id); if (!h) return res.json({ ok: false, error: 'Entrée introuvable' });
  const { overrides } = SET.validate(sch.v, JSON.parse(h.before)); const n = saveSettings(l, req.user, A.ip(req), overrides, 'restauration #' + h.id);
  res.json({ ok: true, changed: n });
});

// ───────── statistiques ─────────
router.get('/:id/stats-summary', (req, res) => {
  const l = own(req, res); if (!l) return; const days = Math.min(30, Math.max(1, +req.query.days || 7));
  const pts = db.prepare('SELECT at, players FROM stats_hist WHERE license_id=? AND at>? ORDER BY at').all(l.id, now() - days * 86400);
  const peak = pts.reduce((m, p) => Math.max(m, p.players), 0), avg = pts.length ? Math.round(pts.reduce((s, p) => s + p.players, 0) / pts.length * 10) / 10 : 0;
  const st = db.prepare('SELECT players FROM server_state WHERE license_id=?').get(l.id); const pl = st ? JSON.parse(st.players) : [];
  const jobs = {}; for (const p of pl) jobs[p.job || '—'] = (jobs[p.job || '—'] || 0) + 1;
  const byHour = Array(24).fill(0), cnt = Array(24).fill(0); for (const p of pts) { const h = new Date(p.at * 1000).getHours(); byHour[h] += p.players; cnt[h]++; }
  let activity = []; try { activity = (JSON.parse((db.prepare('SELECT stats FROM server_state WHERE license_id=?').get(l.id) || {}).stats || '{}').activity) || []; } catch (e) {}
  res.json({ ok: true, activity, points: pts, peak, avg, jobs: Object.entries(jobs).sort((a, b) => b[1] - a[1]).slice(0, 10), hours: byHour.map((v, i) => cnt[i] ? Math.round(v / cnt[i] * 10) / 10 : 0), total_money: pl.reduce((s, p) => s + p.money + p.bank, 0), count: pl.length });
});
router.get('/:id/activity', (req, res) => { const l = own(req, res); if (!l) return; res.json({ ok: true, rows: db.prepare('SELECT a.id,a.action,a.detail,a.at,u.username FROM audit a LEFT JOIN users u ON u.id=a.user_id WHERE a.license_id=? ORDER BY a.id DESC LIMIT 100').all(l.id) }); });

// ───────── console ─────────
router.post('/:id/console', (req, res) => {
  const l = own(req, res); if (!l) return; if (!active(l)) return res.json({ ok: false, error: 'Licence inactive ou expirée' }); const v = C.validate('console', req.body); if (v.error) return res.json({ ok: false, error: v.error });
  const id = queue(l, req.user.id, 'console', v.payload); audit(req.user.id, l.id, 'console', v.payload.cmd, A.ip(req)); res.json({ ok: true, id });
});
router.post('/:id/power', (req, res) => {
  const l = own(req, res); if (!l) return; if (!active(l)) return res.json({ ok: false, error: 'Licence inactive ou expirée' }); const t = (req.body || {}).action === 'stop' ? 'server_stop' : 'server_restart';
  queue(l, req.user.id, t, {}); audit(req.user.id, l.id, t, '', A.ip(req)); res.json({ ok: true });
});

// ───────── webhooks Discord ─────────
router.get('/:id/webhooks', (req, res) => { const l = own(req, res); if (!l) return; res.json({ ok: true, events: hooks.EVENTS, hooks: Object.fromEntries(db.prepare('SELECT event,url FROM webhooks WHERE license_id=?').all(l.id).map(h => [h.event, h.url])) }); });
// « salon:<id> » désigne un salon déjà ajouté dans Message Discord : une seule adresse à gérer pour tout le panel
const hookUrl = (l, v) => { v = String(v || '').trim(); const m = /^salon:(\d+)$/.exec(v); if (!m) return v; const c = db.prepare('SELECT url FROM discord_channels WHERE id=? AND license_id=?').get(+m[1], l.id); return c ? c.url : 'salon-inconnu'; };
router.put('/:id/webhooks', (req, res) => {
  const l = own(req, res); if (!l) return; const b = Object.fromEntries(Object.entries(req.body || {}).map(([k, v]) => [k, hookUrl(l, v)]));
  for (const ev of hooks.EVENTS) { const u = String(b[ev] || '').trim(); if (u && !hooks.okUrl(u)) return res.json({ ok: false, error: 'Lien de webhook Discord invalide pour « ' + ev + ' »' }); }
  for (const ev of hooks.EVENTS) { const u = String(b[ev] || '').trim(); if (u) db.prepare('INSERT INTO webhooks(license_id,event,url) VALUES(?,?,?) ON CONFLICT(license_id,event) DO UPDATE SET url=excluded.url').run(l.id, ev, u); else db.prepare('DELETE FROM webhooks WHERE license_id=? AND event=?').run(l.id, ev); }
  audit(req.user.id, l.id, 'webhooks', '', A.ip(req)); res.json({ ok: true });
});
router.post('/:id/webhooks/test', async (req, res) => {
  const l = own(req, res); if (!l) return; const u = hookUrl(l, (req.body || {}).url); if (!hooks.okUrl(u)) return res.json({ ok: false, error: 'Lien invalide' });
  try { const r = await fetch(u, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ username: 'AERO Panel', content: 'Test du webhook depuis le panel ✅' }), signal: AbortSignal.timeout(6000) }); res.json({ ok: r.ok, error: r.ok ? undefined : 'Discord a refusé (HTTP ' + r.status + ')' }); } catch (e) { res.json({ ok: false, error: 'Discord injoignable' }); }
});

// ───────── Drive (images hébergées, utilisables comme logo) ─────────
const MIME = { 'image/png': 'png', 'image/jpeg': 'jpg', 'image/webp': 'webp', 'image/gif': 'gif', 'image/svg+xml': 'svg', 'audio/mpeg': 'mp3', 'audio/ogg': 'ogg', 'audio/wav': 'wav' };
const isAudio = m => m.startsWith('audio/');
const driveDir = () => { const d = path.join(cfg.dataDir, 'drive'); fs.mkdirSync(d, { recursive: true }); return d; };
router.get('/:id/drive', (req, res) => { const l = own(req, res); if (!l) return; res.json({ ok: true, files: db.prepare('SELECT id,token,name,mime,size,at FROM drive WHERE license_id=? ORDER BY id DESC').all(l.id).map(f => ({ ...f, url: cfg.publicUrl ? `${cfg.publicUrl}/drive/${f.token}` : `${req.protocol}://${req.get('host')}/drive/${f.token}` })) }); });
router.post('/:id/drive', (req, res) => {
  const l = own(req, res); if (!l) return; const b = req.body || {}; const mime = String(b.mime || ''); if (!MIME[mime]) return res.json({ ok: false, error: 'Formats acceptés : PNG, JPG, WEBP, GIF, SVG (images) · MP3, OGG, WAV (musique)' });
  const buf = Buffer.from(String(b.data || ''), 'base64'); const maxSize = isAudio(mime) ? 6000000 : 1500000; if (!buf.length || buf.length > maxSize) return res.json({ ok: false, error: isAudio(mime) ? 'Fichier vide ou supérieur à 6 Mo' : 'Fichier vide ou supérieur à 1,5 Mo' });
  const used = db.prepare('SELECT COALESCE(SUM(size),0) n FROM drive WHERE license_id=?').get(l.id).n; if (used + buf.length > 20 * 1024 * 1024) return res.json({ ok: false, error: 'Drive plein (20 Mo)' });
  if (mime === 'image/svg+xml' && /<script|onload=|onerror=|javascript:/i.test(buf.toString('utf8'))) return res.json({ ok: false, error: 'SVG refusé (contenu actif)' });
  const token = crypto.randomBytes(16).toString('hex'); fs.writeFileSync(path.join(driveDir(), token), buf);
  const name = String(b.name || (isAudio(mime) ? 'musique' : 'image')).replace(/[^\w.\- ]/g, '').slice(0, 60) || 'image'; db.prepare('INSERT INTO drive(license_id,token,name,mime,size,at) VALUES(?,?,?,?,?,?)').run(l.id, token, name, mime, buf.length, now());
  audit(req.user.id, l.id, 'drive:upload', name, A.ip(req)); res.json({ ok: true, token });
});
router.delete('/:id/drive/:fid', (req, res) => { const l = own(req, res); if (!l) return; const f = db.prepare('SELECT * FROM drive WHERE id=? AND license_id=?').get(+req.params.fid, l.id); if (!f) return res.json({ ok: false, error: 'Introuvable' }); try { fs.unlinkSync(path.join(driveDir(), f.token)); } catch (e) {} db.prepare('DELETE FROM drive WHERE id=?').run(f.id); res.json({ ok: true }); });

// ───────── modules (catalogue admin, activation par le client) ─────────
router.get('/:id/modules', (req, res) => {
  const l = own(req, res); if (!l) return; const st = db.prepare('SELECT resources FROM server_state WHERE license_id=?').get(l.id); const rs = Object.fromEntries((st ? JSON.parse(st.resources) : []).map(r => [r.name, r.state]));
  const mine = Object.fromEntries(db.prepare('SELECT module_id,enabled FROM license_modules WHERE license_id=?').all(l.id).map(m => [m.module_id, m.enabled]));
  res.json({ ok: true, modules: db.prepare('SELECT * FROM modules WHERE active=1 ORDER BY price,name').all().map(m => { const r = JSON.parse(m.resources); return { id: m.id, name: m.name, description: m.description, price: m.price, resources: r, owned: m.price === 0 || m.id in mine, enabled: r.length > 0 && r.every(x => rs[x] === 'started'), known: r.some(x => x in rs) }; }) });
});
router.post('/:id/modules/:mid/toggle', (req, res) => {
  const l = own(req, res); if (!l) return; if (!active(l)) return res.json({ ok: false, error: 'Licence inactive ou expirée' }); const m = db.prepare('SELECT * FROM modules WHERE id=? AND active=1').get(+req.params.mid); if (!m) return res.json({ ok: false, error: 'Module introuvable' });
  if (m.price > 0 && !db.prepare('SELECT 1 FROM license_modules WHERE license_id=? AND module_id=?').get(l.id, m.id)) return res.json({ ok: false, error: 'Module non acquis : demande-le depuis la Boutique' });
  const on = !!(req.body || {}).enabled; for (const r of JSON.parse(m.resources)) queue(l, req.user.id, on ? 'resource_start' : 'resource_stop', { resource: r });
  audit(req.user.id, l.id, 'module:' + (on ? 'on' : 'off'), m.name, A.ip(req)); res.json({ ok: true });
});
router.post('/:id/modules/:mid/request', (req, res) => {
  const l = own(req, res); if (!l) return; const m = db.prepare('SELECT * FROM modules WHERE id=?').get(+req.params.mid); if (!m) return res.json({ ok: false, error: 'Module introuvable' });
  const t = db.prepare('INSERT INTO tickets(user_id,license_id,subject,status,created_at,updated_at) VALUES(?,?,?,?,?,?)').run(req.user.id, l.id, 'Demande du module « ' + m.name + ' »', 'open', now(), now()).lastInsertRowid;
  db.prepare('INSERT INTO ticket_msgs(ticket_id,user_id,staff,body,at) VALUES(?,?,?,?,?)').run(t, req.user.id, 0, `Je souhaite obtenir le module « ${m.name} » (${m.price} €) pour mon serveur « ${l.server_name} ».`, now()); res.json({ ok: true, ticket: t });
});

// ───────── sauvegardes (documents + fichiers modifiés via le panel) ─────────
router.get('/:id/backups', (req, res) => { const l = own(req, res); if (!l) return; res.json({ ok: true, backups: db.prepare('SELECT b.id,b.name,b.size,b.at,u.username by_name FROM backups b LEFT JOIN users u ON u.id=b.by_user WHERE b.license_id=? ORDER BY b.id DESC LIMIT 30').all(l.id) }); });
router.post('/:id/backups', (req, res) => {
  const l = own(req, res); if (!l) return; const name = String((req.body || {}).name || '').trim().slice(0, 60) || 'Sauvegarde du ' + new Date().toLocaleString('fr-FR');
  const files = {}; for (const f of db.prepare('SELECT DISTINCT path FROM file_versions WHERE license_id=?').all(l.id)) { const v = db.prepare('SELECT content FROM file_versions WHERE license_id=? AND path=? ORDER BY id DESC LIMIT 1').get(l.id, f.path); files[f.path] = v.content; }
  const docs = {}; for (const d of db.prepare('SELECT key,value FROM docs WHERE license_id=?').all(l.id)) docs[d.key] = JSON.parse(d.value);
  const data = JSON.stringify({ files, docs }); if (data.length > 8 * 1024 * 1024) return res.json({ ok: false, error: 'Sauvegarde trop volumineuse' });
  db.prepare('DELETE FROM backups WHERE license_id=? AND id NOT IN (SELECT id FROM backups WHERE license_id=? ORDER BY id DESC LIMIT 19)').run(l.id, l.id);
  db.prepare('INSERT INTO backups(license_id,name,data,size,at,by_user) VALUES(?,?,?,?,?,?)').run(l.id, name, data, data.length, now(), req.user.id); audit(req.user.id, l.id, 'backup:create', name, A.ip(req)); res.json({ ok: true, files: Object.keys(files).length, docs: Object.keys(docs).length });
});
router.post('/:id/backups/:bid/restore', async (req, res) => {
  const l = own(req, res); if (!l) return; if (!active(l)) return res.json({ ok: false, error: 'Licence inactive ou expirée' }); const b = db.prepare('SELECT * FROM backups WHERE id=? AND license_id=?').get(+req.params.bid, l.id); if (!b) return res.json({ ok: false, error: 'Sauvegarde introuvable' });
  const d = JSON.parse(b.data); let ok = 0, fail = [];
  for (const [p, content] of Object.entries(d.files || {})) { const v = C.validateRpc('fs.write', { path: p, content }); if (v.error) { fail.push(p); continue; } const r = await bus.rpc(l.id, 'fs.write', v.payload, req.user.id, 20000); if (r.ok) { ok++; const prev = db.prepare('SELECT content FROM file_versions WHERE license_id=? AND path=? ORDER BY id DESC LIMIT 1').get(l.id, p); if (!prev || prev.content !== content) db.prepare('INSERT INTO file_versions(license_id,path,content,size,note,by_user,at) VALUES(?,?,?,?,?,?,?)').run(l.id, p, content, Buffer.byteLength(content), 'Restauration : ' + b.name, req.user.id, now()); } else fail.push(p); }
  for (const [k, val] of Object.entries(d.docs || {})) { const v = C.validateDoc(k, val); if (v && !v.error) db.prepare('INSERT INTO docs(license_id,key,value,version,updated_at) VALUES(?,?,?,?,?) ON CONFLICT(license_id,key) DO UPDATE SET value=excluded.value, version=docs.version+1, updated_at=excluded.updated_at').run(l.id, k, JSON.stringify(v.value), 1, now()); }
  audit(req.user.id, l.id, 'backup:restore', b.name, A.ip(req)); res.json({ ok: fail.length === 0, restored: ok, failed: fail, error: fail.length ? 'Fichiers non restaurés : ' + fail.join(', ') : undefined });
});
router.delete('/:id/backups/:bid', (req, res) => { const l = own(req, res); if (!l) return; db.prepare('DELETE FROM backups WHERE id=? AND license_id=?').run(+req.params.bid, l.id); res.json({ ok: true }); });
module.exports = router;
