// Éditeur visuel de la base : métiers / grades / salaires (base de données ESX) et objets (ox_inventory/data/items.lua), sans ouvrir de fichier
const router = require('express').Router();
const { db, audit } = require('../lib/db'); const A = require('../lib/auth'); const C = require('../lib/commands'); const bus = require('../lib/bus');
const { own, active } = require('../lib/access'); const files = require('./files');
router.use(A.needUser);
const ITEMS_PATH = '[inventaire]/ox_inventory/data/items.lua';
const guard = (req, res) => { const l = own(req, res); if (!l) return null; if (!active(l)) { res.json({ ok: false, error: 'Licence inactive ou expirée' }); return null; } return l; };

// ── métiers ──
router.get('/:id/base/jobs', async (req, res) => { const l = guard(req, res); if (!l) return; const r = await bus.rpc(l.id, 'db.jobs', {}, req.user.id, 20000); res.json(r.ok ? { ok: true, jobs: (r.data && r.data.jobs) || [] } : r); });
router.post('/:id/base/jobs', async (req, res) => {
  const l = guard(req, res); if (!l) return; const v = C.validateRpc('db.job_save', { job: (req.body || {}).job }); if (v.error) return res.json({ ok: false, error: 'Métier invalide : nom en minuscules (a-z, 0-9, _), libellés non vides, grades uniques, salaire de 0 à 1 000 000' });
  const r = await bus.rpc(l.id, 'db.job_save', v.payload, req.user.id, 25000); if (!r.ok) return res.json(r);
  audit(req.user.id, l.id, 'base:job', v.payload.job.name, A.ip(req)); db.prepare("INSERT INTO logs(license_id,level,source,message,at) VALUES(?,?,?,?,?)").run(l.id, 'staff', 'panel', `${req.user.username} a modifié le métier ${v.payload.job.name}`, Math.floor(Date.now() / 1000));
  res.json({ ok: true, message: (r.data && r.data.message) || 'enregistré' });
});

// ── boutiques créées en jeu (pickax_shopbuilder) : liste, produits, prix, stocks, emplacements ──
const shopCall = async (l, req, fn, args, ms) => { const v = C.validateRpc('db.shop', { fn, args }); if (v.error) return { ok: false, error: 'Requête invalide' }; const r = await bus.rpc(l.id, 'db.shop', v.payload, req.user.id, ms || 20000); if (!r.ok) return r; return { ok: true, ...(r.data || {}) }; };
const sid = req => { const n = Math.floor(Number(req.params.sid)); return Number.isFinite(n) && n > 0 ? n : null; };
const shopLog = (req, l, what, detail) => { audit(req.user.id, l.id, 'shop:' + what, String(detail || '').slice(0, 120), A.ip(req)); db.prepare("INSERT INTO logs(license_id,level,source,message,at) VALUES(?,?,?,?,?)").run(l.id, 'staff', 'panel', `${req.user.username} : boutique en jeu (${what}) ${detail || ''}`.slice(0, 200), Math.floor(Date.now() / 1000)); };
router.get('/:id/shops', async (req, res) => { const l = guard(req, res); if (!l) return; res.json(await shopCall(l, req, 'list', [])); });
router.get('/:id/shops/catalog', async (req, res) => { const l = guard(req, res); if (!l) return; res.json(await shopCall(l, req, 'catalog', [])); });
router.get('/:id/shops/:sid', async (req, res) => { const l = guard(req, res); if (!l) return; const n = sid(req); if (!n) return res.json({ ok: false, error: 'Boutique invalide' }); res.json(await shopCall(l, req, 'get', [n])); });
router.post('/:id/shops', async (req, res) => { const l = guard(req, res); if (!l) return; const b = req.body || {}; const type = String(b.type || '').slice(0, 40), label = String(b.label || '').slice(0, 100); if (!/^[\w\-]{1,40}$/.test(type)) return res.json({ ok: false, error: 'Type de boutique invalide' }); const r = await shopCall(l, req, 'create', [type, label]); if (r.ok) shopLog(req, l, 'create', label); res.json(r); });
router.put('/:id/shops/:sid', async (req, res) => { const l = guard(req, res); if (!l) return; const n = sid(req); const d = (req.body || {}).shop; if (!n || !d || typeof d !== 'object') return res.json({ ok: false, error: 'Données invalides' }); d.id = n; const r = await shopCall(l, req, 'save', [d], 25000); if (r.ok) shopLog(req, l, 'save', `#${n} ${String(d.label || '').slice(0, 60)}`); res.json(r); });
router.delete('/:id/shops/:sid', async (req, res) => { const l = guard(req, res); if (!l) return; const n = sid(req); if (!n) return res.json({ ok: false, error: 'Boutique invalide' }); const r = await shopCall(l, req, 'delete', [n]); if (r.ok) shopLog(req, l, 'delete', '#' + n); res.json(r); });
router.post('/:id/shops/:sid/duplicate', async (req, res) => { const l = guard(req, res); if (!l) return; const n = sid(req); if (!n) return res.json({ ok: false, error: 'Boutique invalide' }); const r = await shopCall(l, req, 'duplicate', [n]); if (r.ok) shopLog(req, l, 'duplicate', '#' + n); res.json(r); });
router.post('/:id/shops/:sid/toggle', async (req, res) => { const l = guard(req, res); if (!l) return; const n = sid(req); if (!n) return res.json({ ok: false, error: 'Boutique invalide' }); const r = await shopCall(l, req, 'toggle', [n, (req.body || {}).state === true]); if (r.ok) shopLog(req, l, 'toggle', `#${n} ${(req.body || {}).state ? 'activée' : 'désactivée'}`); res.json(r); });
router.post('/:id/shops/:sid/restock', async (req, res) => { const l = guard(req, res); if (!l) return; const n = sid(req); const b = req.body || {}; if (!n || !['full', 'all'].includes(b.mode)) return res.json({ ok: false, error: 'Requête invalide' }); const r = await shopCall(l, req, 'restock', [n, b.mode, Math.floor(Number(b.amount) || 0)]); if (r.ok) shopLog(req, l, 'restock', `#${n} ${b.mode}`); res.json(r); });

// ── objets : lecture / modification ciblée des lignes simples du fichier (le reste du fichier n'est jamais touché) ──
const LINE = /^(\s*)\[(['"])([^'"]+)\2\]\s*=\s*\{(.*)\},?\s*(--.*)?$/;
const strField = k => new RegExp(`(\\b${k}\\s*=\\s*)(?:'((?:[^'\\\\]|\\\\.)*)'|"((?:[^"\\\\]|\\\\.)*)")`);
const numField = k => new RegExp(`(\\b${k}\\s*=\\s*)(-?\\d+(?:\\.\\d+)?)`);
const boolField = k => new RegExp(`(\\b${k}\\s*=\\s*)(true|false)`);
const unesc = x => String(x).replace(/\\(.)/g, '$1');
const luaStr = x => "'" + String(x).replace(/\\/g, '\\\\').replace(/'/g, "\\'") + "'";
function parseItems(text) {
  const items = []; let other = 0;
  text.split(/\r?\n/).forEach((ln, i) => {
    const m = ln.match(LINE); if (!m) { if (/^\s*\[(['"])[^'"]+\1\]\s*=\s*\{/.test(ln)) other++; return; }
    const body = m[4], lab = body.match(strField('label')), w = body.match(numField('weight'));
    if (!lab || /=\s*\{/.test(body)) { other++; return; }
    const st = body.match(boolField('stack')), cl = body.match(boolField('close'));
    items.push({ name: m[3], label: unesc(lab[2] !== undefined ? lab[2] : lab[3]), weight: w ? +w[2] : 0, stack: st ? st[2] === 'true' : true, close: cl ? cl[2] === 'true' : true, line: i + 1 });
  });
  return { items, other };
}
function patchLine(ln, ch) {
  const m = ln.match(LINE); if (!m) return null; let body = m[4];
  const setStr = (k, v) => { if (strField(k).test(body)) body = body.replace(strField(k), (_, p) => p + luaStr(v)); else body = body.replace(/\s*$/, '') + `, ${k} = ${luaStr(v)} `; };
  const setNum = (k, v) => { if (numField(k).test(body)) body = body.replace(numField(k), (_, p) => p + v); else body = body.replace(/\s*$/, '') + `, ${k} = ${v} `; };
  const setBool = (k, v) => { if (boolField(k).test(body)) body = body.replace(boolField(k), (_, p) => p + v); else body = body.replace(/\s*$/, '') + `, ${k} = ${v} `; };
  if (ch.label !== undefined) setStr('label', ch.label); if (ch.weight !== undefined) setNum('weight', ch.weight); if (ch.stack !== undefined) setBool('stack', ch.stack); if (ch.close !== undefined) setBool('close', ch.close);
  return `${m[1]}[${m[2]}${m[3]}${m[2]}] = {${body}},${m[5] ? ' ' + m[5] : ''}`;
}
const NAME = /^[A-Za-z0-9_]{1,50}$/;
const okLabel = x => typeof x === 'string' && x.trim().length >= 1 && x.length <= 60 && !/[\u0000-\u001f]/.test(x);
const okWeight = x => Number.isFinite(+x) && +x >= 0 && +x <= 10000000;
router.get('/:id/base/items', async (req, res) => {
  const l = guard(req, res); if (!l) return; const r = await bus.rpc(l.id, 'fs.read', { path: ITEMS_PATH }, req.user.id, 20000); if (!r.ok) return res.json(r);
  const p = parseItems(String((r.data && r.data.content) || '')); res.json({ ok: true, items: p.items, other: p.other, path: ITEMS_PATH });
});
router.post('/:id/base/items', async (req, res) => {
  const l = guard(req, res); if (!l) return; const b = req.body || {}; const changes = Array.isArray(b.changes) ? b.changes.slice(0, 300) : [], adds = Array.isArray(b.add) ? b.add.slice(0, 50) : [];
  if (!changes.length && !adds.length) return res.json({ ok: false, error: 'Rien à enregistrer' });
  const r = await bus.rpc(l.id, 'fs.read', { path: ITEMS_PATH }, req.user.id, 20000); if (!r.ok) return res.json(r);
  const content = String((r.data && r.data.content) || ''); const eol = content.includes('\r\n') ? '\r\n' : '\n'; const lines = content.split(/\r?\n/); let n = 0;
  for (const ch of changes) {
    if (!ch || !NAME.test(String(ch.name))) return res.json({ ok: false, error: 'Nom d’objet invalide' });
    const c = {}; if (ch.label !== undefined) { if (!okLabel(ch.label)) return res.json({ ok: false, error: `Libellé invalide pour ${ch.name}` }); c.label = ch.label; }
    if (ch.weight !== undefined) { if (!okWeight(ch.weight)) return res.json({ ok: false, error: `Poids invalide pour ${ch.name}` }); c.weight = Math.round(+ch.weight); }
    if (ch.stack !== undefined) c.stack = !!ch.stack; if (ch.close !== undefined) c.close = !!ch.close;
    const idx = lines.findIndex(ln => { const m = ln.match(LINE); return m && m[3] === ch.name; }); if (idx < 0) return res.json({ ok: false, error: `Objet ${ch.name} introuvable (ligne modifiée à la main ?)` });
    const nl = patchLine(lines[idx], c); if (!nl) return res.json({ ok: false, error: `Ligne illisible pour ${ch.name}` }); if (nl !== lines[idx]) { lines[idx] = nl; n++; }
  }
  if (adds.length) {
    let end = -1; for (let i = lines.length - 1; i >= 0; i--) if (/^\}\s*$/.test(lines[i])) { end = i; break; } if (end < 0) return res.json({ ok: false, error: 'Fin du fichier items.lua introuvable' });
    const fresh = []; for (const a of adds) {
      if (!a || !NAME.test(String(a.name)) || !okLabel(a.label) || !okWeight(a.weight)) return res.json({ ok: false, error: 'Nouvel objet invalide (nom a-z/0-9/_, libellé, poids)' });
      if (lines.some(ln => ln.includes(`['${a.name}']`) || ln.includes(`["${a.name}"]`)) || fresh.some(x => x.includes(`['${a.name}']`))) return res.json({ ok: false, error: `L’objet ${a.name} existe déjà` });
      fresh.push(`    ['${a.name}'] = { label = ${luaStr(a.label)}, weight = ${Math.round(+a.weight)}, stack = ${a.stack === false ? 'false' : 'true'}, close = ${a.close === false ? 'false' : 'true'} },`); n++;
    }
    lines.splice(end, 0, ...fresh);
  }
  if (!n) return res.json({ ok: true, changed: 0, message: 'Aucune modification' });
  const out = await files.saveFile(req, l, ITEMS_PATH, lines.join(eol), `Éditeur d’objets : ${n} modification(s)`, false);
  res.json(out.ok ? { ok: true, changed: n, message: out.message || 'enregistré' } : out);
});
router.parseItems = parseItems; router.patchLine = patchLine;
module.exports = router;
