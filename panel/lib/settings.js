// Validation des réglages du serveur d'après le schéma envoyé par la ressource pickax_settings
function clean(def, v) {
  switch (def.type) {
    case 'bool': return typeof v === 'boolean' ? { ok: true, v } : { ok: false };
    case 'number': { v = Number(v); if (!Number.isFinite(v)) return { ok: false }; const lo = def.min ?? -1e9, hi = def.max ?? 1e9; return { ok: true, v: Math.min(hi, Math.max(lo, v)) }; }
    case 'select': return (def.options || []).some(o => o[0] === v) ? { ok: true, v } : { ok: false };
    case 'text': return typeof v === 'string' && v.length <= 300 && !/[\u0000-\u001f]/.test(v) ? { ok: true, v } : { ok: false };
    case 'list': { if (!Array.isArray(v) || v.length > 20) return { ok: false }; const out = []; for (const x of v) { if (typeof x !== 'string' || x.length > 200 || /[\u0000-\u001f]/.test(x)) return { ok: false }; if (x.trim()) out.push(x.trim()); } return { ok: true, v: out }; }
    default: return { ok: false };
  }
}
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
// renvoie { overrides, errors } : seules les valeurs différentes de la valeur par défaut sont conservées
function validate(schema, values) {
  const by = Object.fromEntries((schema || []).map(d => [d.key, d])); const overrides = {}; const errors = [];
  for (const [k, v] of Object.entries(values || {})) { const def = by[k]; if (!def) { errors.push(k); continue; } if (v === null) continue; const c = clean(def, v); if (!c.ok) { errors.push(def.label || k); continue; } if (!same(c.v, def.default)) overrides[k] = c.v; }
  return { overrides, errors };
}
function sanitizeSchema(arr) {
  if (!Array.isArray(arr) || arr.length > 300) return null; const out = [];
  for (const d of arr) { if (!d || typeof d.key !== 'string' || !/^[a-z0-9_]{1,60}$/.test(d.key) || !['bool', 'number', 'select', 'text', 'list'].includes(d.type)) return null;
    out.push({ key: d.key, group: String(d.group || 'Général').slice(0, 40), section: d.section ? String(d.section).slice(0, 60) : undefined, label: String(d.label || d.key).slice(0, 120), type: d.type, default: d.default === undefined ? (d.type === 'list' ? [] : null) : d.default, min: d.min, max: d.max, step: d.step, options: Array.isArray(d.options) ? d.options.slice(0, 40).map(o => [String(o[0]), String(o[1])]) : undefined, hint: d.hint ? String(d.hint).slice(0, 300) : undefined, easy: d.easy !== undefined && d.type !== 'list' && typeof d.easy === typeof d.default ? d.easy : undefined }); }
  return out;
}
module.exports = { validate, sanitizeSchema };
