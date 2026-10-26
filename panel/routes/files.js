// Éditeur de fichiers à distance (via la ressource pickax_panel) + historique des versions + assistant IA
const router = require('express').Router();
const { db, now, audit } = require('../lib/db'); const A = require('../lib/auth'); const C = require('../lib/commands'); const bus = require('../lib/bus'); const cfg = require('../lib/config');
const { own, active } = require('../lib/access');
router.use(A.needUser);
const MAXV = 30;
function guard(req, res) { const l = own(req, res); if (!l) return null; if (!active(l)) { res.json({ ok: false, error: 'Licence inactive ou expirée' }); return null; } return l; }
const lastOf = (lid, path) => db.prepare('SELECT * FROM file_versions WHERE license_id=? AND path=? ORDER BY id DESC LIMIT 1').get(lid, path);
function addVersion(lid, path, content, note, uid) {
  const prev = lastOf(lid, path); if (prev && prev.content === content) return prev.id;
  const id = db.prepare('INSERT INTO file_versions(license_id,path,content,size,note,by_user,at) VALUES(?,?,?,?,?,?,?)').run(lid, path, content, Buffer.byteLength(content), String(note || '').slice(0, 120), uid || null, now()).lastInsertRowid;
  db.prepare('DELETE FROM file_versions WHERE license_id=? AND path=? AND id NOT IN (SELECT id FROM file_versions WHERE license_id=? AND path=? ORDER BY id DESC LIMIT ?)').run(lid, path, lid, path, MAXV);
  return id;
}
router.get('/:id/fs/list', async (req, res) => {
  const l = guard(req, res); if (!l) return; const v = C.validateRpc('fs.list', { path: req.query.path || '' }); if (v.error) return res.json({ ok: false, error: v.error });
  res.json(await bus.rpc(l.id, 'fs.list', v.payload, req.user.id, 15000));
});
router.get('/:id/fs/read', async (req, res) => {
  const l = guard(req, res); if (!l) return; const v = C.validateRpc('fs.read', { path: req.query.path }); if (v.error) return res.json({ ok: false, error: v.error });
  const r = await bus.rpc(l.id, 'fs.read', v.payload, req.user.id, 15000); if (!r.ok) return res.json(r);
  const content = String((r.data && r.data.content) || ''); if (!lastOf(l.id, v.payload.path)) addVersion(l.id, v.payload.path, content, 'Version d’origine', null);
  res.json({ ok: true, content, size: Buffer.byteLength(content), versions: db.prepare('SELECT COUNT(*) n FROM file_versions WHERE license_id=? AND path=?').get(l.id, v.payload.path).n });
});
async function writeFile(req, res, l, path, content, note, create) {
  const v = C.validateRpc(create ? 'fs.create' : 'fs.write', { path, content }); if (v.error) return res.json({ ok: false, error: v.error });
  const r = await bus.rpc(l.id, create ? 'fs.create' : 'fs.write', v.payload, req.user.id, 20000); if (!r.ok) return res.json(r);
  if (!create && !lastOf(l.id, path)) { /* pas d'original connu : on garde au moins la nouvelle version */ }
  const vid = addVersion(l.id, path, content, note || (create ? 'Création' : ''), req.user.id);
  audit(req.user.id, l.id, create ? 'file:create' : 'file:write', path, A.ip(req)); db.prepare("INSERT INTO logs(license_id,level,source,message,at) VALUES(?,?,?,?,?)").run(l.id, 'staff', 'panel', `${req.user.username} a ${create ? 'créé' : 'modifié'} ${path}`, now());
  res.json({ ok: true, version: vid, message: r.data && r.data.message });
}
router.post('/:id/fs/write', async (req, res) => { const l = guard(req, res); if (!l) return; const b = req.body || {}; await writeFile(req, res, l, b.path, b.content, b.note, false); });
router.post('/:id/fs/create', async (req, res) => { const l = guard(req, res); if (!l) return; const b = req.body || {}; await writeFile(req, res, l, b.path, b.content || '', 'Création', true); });
router.get('/:id/fs/versions', (req, res) => { const l = own(req, res); if (!l) return; const path = C.cleanPath(String(req.query.path || '')); if (!path) return res.json({ ok: false, error: 'Chemin invalide' });
  res.json({ ok: true, versions: db.prepare('SELECT v.id,v.size,v.note,v.at,u.username by_name FROM file_versions v LEFT JOIN users u ON u.id=v.by_user WHERE v.license_id=? AND v.path=? ORDER BY v.id DESC').all(l.id, path) }); });
router.get('/:id/fs/version/:vid', (req, res) => { const l = own(req, res); if (!l) return; const v = db.prepare('SELECT id,path,content,note,at FROM file_versions WHERE id=? AND license_id=?').get(+req.params.vid, l.id); res.json(v ? { ok: true, version: v } : { ok: false, error: 'Version introuvable' }); });
router.post('/:id/fs/restore', async (req, res) => { const l = guard(req, res); if (!l) return; const v = db.prepare('SELECT * FROM file_versions WHERE id=? AND license_id=?').get(+(req.body || {}).vid, l.id); if (!v) return res.json({ ok: false, error: 'Version introuvable' });
  const cur = lastOf(l.id, v.path); await writeFile(req, res, l, v.path, v.content, 'Restauration de la version du ' + new Date(v.at * 1000).toLocaleString('fr-FR'), false); void cur; });
router.get('/:id/fs/tracked', (req, res) => { const l = own(req, res); if (!l) return; res.json({ ok: true, files: db.prepare('SELECT path, COUNT(*) versions, MAX(at) at FROM file_versions WHERE license_id=? GROUP BY path ORDER BY MAX(id) DESC LIMIT 100').all(l.id) }); });

// ───────── Assistant IA (Anthropic) ─────────
const SYSTEM = `Tu es l'assistant de configuration d'un serveur FiveM (ESX, fichiers Lua, JSON, meta, CFG, JS, HTML, CSS).
On te donne UN fichier et une demande en français. Applique la modification demandée avec le MINIMUM de changements, sans reformater le reste, sans supprimer de commentaires ni de licence, et sans inventer d'options inexistantes (si la demande est impossible ou ambiguë, ne modifie rien et explique pourquoi).
Réponds exactement ainsi :
<note>explication courte en français de ce que tu as changé (ou pourquoi tu n'as rien changé)</note>
<file>
contenu COMPLET du fichier modifié
</file>`;
router.get('/:id/ai/status', (req, res) => { const l = own(req, res); if (!l) return; const day = new Date().toISOString().slice(0, 10); const u = db.prepare('SELECT n FROM ai_usage WHERE license_id=? AND day=?').get(l.id, day); res.json({ ok: true, enabled: !!cfg.aiKey, limit: cfg.aiDaily, used: u ? u.n : 0 }); });
router.post('/:id/ai', async (req, res) => {
  const l = guard(req, res); if (!l) return; if (!cfg.aiKey) return res.json({ ok: false, error: 'Assistant IA non configuré sur ce panel' });
  const b = req.body || {}; const path = C.cleanPath(String(b.path || '')); const instruction = String(b.instruction || '').trim().slice(0, 1500); const content = typeof b.content === 'string' ? b.content : '';
  if (!path || !instruction) return res.json({ ok: false, error: 'Fichier et demande requis' }); if (content.length > 150000) return res.json({ ok: false, error: 'Fichier trop gros pour l’assistant (150 Ko max)' });
  const day = new Date().toISOString().slice(0, 10); const u = db.prepare('SELECT n FROM ai_usage WHERE license_id=? AND day=?').get(l.id, day); if ((u ? u.n : 0) >= cfg.aiDaily) return res.json({ ok: false, error: `Limite de ${cfg.aiDaily} demandes par jour atteinte` });
  db.prepare('INSERT INTO ai_usage(license_id,day,n) VALUES(?,?,1) ON CONFLICT(license_id,day) DO UPDATE SET n=n+1').run(l.id, day);
  try {
    const r = await fetch(cfg.aiBase + '/v1/messages', { method: 'POST', headers: { 'content-type': 'application/json', 'x-api-key': cfg.aiKey, 'anthropic-version': '2023-06-01' }, signal: AbortSignal.timeout(90000),
      body: JSON.stringify({ model: cfg.aiModel, max_tokens: 16000, system: SYSTEM, messages: [{ role: 'user', content: `Fichier : ${path}\n\nDemande : ${instruction}\n\n<current_file>\n${content}\n</current_file>` }] }) });
    const j = await r.json(); if (!r.ok) return res.json({ ok: false, error: 'Erreur du service IA : ' + ((j.error && j.error.message) || r.status) });
    const text = (j.content || []).map(x => x.text || '').join(''); const file = text.match(/<file>\n?([\s\S]*?)\n?<\/file>/); const note = (text.match(/<note>([\s\S]*?)<\/note>/) || [])[1] || '';
    if (!file) return res.json({ ok: false, error: 'Réponse inexploitable de l’IA', note: note.trim() });
    audit(req.user.id, l.id, 'ai', path + ' : ' + instruction.slice(0, 100), A.ip(req)); res.json({ ok: true, note: note.trim(), content: file[1], changed: file[1] !== content });
  } catch (e) { res.json({ ok: false, error: 'Service IA injoignable' }); }
});
module.exports = router;
