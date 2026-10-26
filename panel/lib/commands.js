// Liste blanche des actions que le panel peut demander au serveur FiveM (validées ici ET dans la ressource pickax_panel)
const int = (v, min, max) => { v = Math.floor(Number(v)); return Number.isFinite(v) && v >= min && v <= max ? v : null; };
const str = (v, max, re) => { if (typeof v !== 'string') return null; v = v.trim(); if (!v || v.length > max) return null; if (re && !re.test(v)) return null; return v; };
const ID = /^[A-Za-z0-9_:\-\.]+$/;
const defs = {
  announce:   (p) => { const m = str(p.message, 200); return m && { message: m }; },
  kick:       (p) => { const id = int(p.id, 1, 65535); return id && { id, reason: str(p.reason || 'Expulsé par le staff', 120) || 'Expulsé par le staff' }; },
  ban:        (p) => { const id = p.id != null && p.id !== '' ? int(p.id, 1, 65535) : null; const ident = str(p.identifier || '', 120, ID); if (!id && !ident) return null; return { id, identifier: ident, name: str(p.name || '', 60) || '', reason: str(p.reason || 'Banni', 120) || 'Banni', days: int(p.days || 0, 0, 3650) || 0 }; },
  unban:      (p) => { const ident = str(p.identifier, 120, ID); return ident && { identifier: ident }; },
  setjob:     (p) => { const id = int(p.id, 1, 65535), job = str(p.job, 40, ID), grade = int(p.grade, 0, 99); return id && job && grade !== null && { id, job, grade }; },
  setgroup:   (p) => { const id = int(p.id, 1, 65535), group = str(p.group, 30, ID); return id && group && { id, group }; },
  givemoney:  (p) => { const id = int(p.id, 1, 65535), amount = int(p.amount, -10000000, 10000000), account = ['money', 'bank', 'black_money'].includes(p.account) ? p.account : null; return id && amount !== null && account && { id, amount, account }; },
  giveitem:   (p) => { const id = int(p.id, 1, 65535), item = str(p.item, 60, ID), count = int(p.count, 1, 10000); return id && item && count && { id, item, count }; },
  revive:     (p) => { const id = int(p.id, 1, 65535); return id && { id }; },
  message:    (p) => { const id = int(p.id, 1, 65535), m = str(p.message, 200); return id && m && { id, message: m }; },
  restart_resource: (p) => { const r = str(p.resource, 60, ID); return r && { resource: r }; },
  whitelist_add:    (p) => { const i = str(p.identifier, 120, ID); return i && { identifier: i }; },
  whitelist_remove: (p) => { const i = str(p.identifier, 120, ID); return i && { identifier: i }; },
  economy_event: (p) => { const k = str(p.key, 40, ID), s = Number(p.swing), h = int(p.hours, 1, 720); return k && Number.isFinite(s) && s >= -0.9 && s <= 3 && h && { key: k, swing: s, hours: h }; },
  economy_reset: (p) => ({ key: str(p.key || '', 40, ID) || '' }),
  console:    (p) => { const c = str(p.cmd, 200); return c && !/[\r\n;]/.test(c) && { cmd: c }; },
  server_restart: () => ({}),
  server_stop:    () => ({}),
  resource_start: (p) => { const r = str(p.resource, 60, ID); return r && { resource: r }; },
  resource_stop:  (p) => { const r = str(p.resource, 60, ID); return r && { resource: r }; },
  apply_theme: () => ({}),
  refresh_docs: () => ({}),
};
function validate(type, payload) { const f = defs[type]; if (!f) return { error: 'Action inconnue' }; const out = f(payload || {}); return out ? { payload: out } : { error: 'Paramètres invalides' }; }
const DOC_KEYS = { theme: 1, bans: 1, whitelist: 1, motd: 1 };
function validateDoc(key, v) {
  if (!DOC_KEYS[key]) return { error: 'Document inconnu' };
  if (v == null || typeof v !== 'object') return { error: 'Données invalides' };
  if (key === 'theme') {
    const hex = /^#[0-9a-fA-F]{6}$/; const t = {};
    if (!hex.test(v.AccentColor || '')) return { error: 'Couleur principale invalide (#RRGGBB)' };
    t.AccentColor = v.AccentColor.toLowerCase(); t.InventoryColor = hex.test(v.InventoryColor || '') ? v.InventoryColor.toLowerCase() : '';
    const txt = (x, max, req) => { x = String(x == null ? '' : x).trim(); if (x.length > max || /['"\\\r\n]/.test(x)) return null; if (req && !x) return null; return x; };
    t.ServerName = txt(v.ServerName, 60, true); t.ServerShortName = txt(v.ServerShortName, 24, true); t.ServerTagline = txt(v.ServerTagline, 80); t.ServerDiscord = txt(v.ServerDiscord, 80); t.ServerLogo = txt(v.ServerLogo, 200, true);
    if (Object.values(t).includes(null)) return { error: 'Un champ du thème est invalide (pas de guillemets, longueur limitée)' };
    return { value: t };
  }
  if (key === 'bans') { if (!Array.isArray(v)) return { error: 'Liste invalide' }; return { value: v.slice(0, 5000).map(b => ({ identifier: str(String(b.identifier || ''), 120, ID) || '', name: str(String(b.name || ''), 60) || '', reason: str(String(b.reason || ''), 120) || '', until: int(b.until || 0, 0, 4102444800) || 0, at: int(b.at || 0, 0, 4102444800) || 0 })).filter(b => b.identifier) }; }
  if (key === 'whitelist') { if (!Array.isArray(v)) return { error: 'Liste invalide' }; return { value: [...new Set(v.map(x => str(String(x), 120, ID)).filter(Boolean))].slice(0, 20000) }; }
  if (key === 'motd') { const m = str(String(v.text || ''), 300); return { value: { text: m || '', enabled: !!v.enabled } }; }
}
// Appels « RPC » : le navigateur attend la réponse du serveur FiveM (fichiers)
const PATH = /^[A-Za-z0-9_\-\.\[\] \/]{0,200}$/;
function cleanPath(p) { if (typeof p !== 'string' || !PATH.test(p) || p.includes('..') || p.startsWith('/') || /\/\//.test(p)) return null; return p.replace(/\/+$/, ''); }
const rpcDefs = {
  'fs.list':  (p) => { const path = cleanPath(p.path || ''); return path !== null && { path }; },
  'fs.read':  (p) => { const path = cleanPath(p.path || ''); return path && { path }; },
  'fs.write': (p) => { const path = cleanPath(p.path || ''); if (!path || typeof p.content !== 'string' || p.content.length > 1000000) return null; return { path, content: p.content }; },
  'fs.create': (p) => { const path = cleanPath(p.path || ''); return path && { path, content: typeof p.content === 'string' ? p.content.slice(0, 1000000) : '' }; },
};
function validateRpc(type, payload) { const f = rpcDefs[type]; if (!f) return { error: 'Appel inconnu' }; const out = f(payload || {}); return out ? { payload: out } : { error: 'Chemin ou contenu invalide' }; }
module.exports = { validate, validateDoc, validateRpc, cleanPath, DOC_KEYS };
