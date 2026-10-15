'use strict';
/* ════════════════════════════ Utilitaires ════════════════════════════ */
const $root = document.getElementById('root');
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
let CUR = '$';
const money = n => Number(n || 0).toLocaleString('fr-FR') + ' ' + CUR;
const r2 = n => Math.round(n * 100) / 100;
const fmtDate = t => new Date(t * 1000).toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
const initials = n => String(n || '?').split(/\s+/).map(w => w[0]).join('').slice(0, 2).toUpperCase();
const resName = () => (typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'worldbuilder');
const clone = o => JSON.parse(JSON.stringify(o));

async function rpc(name, ...args) {
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort(), 10000);
  try {
    const r = await fetch(`https://${resName()}/rpc`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name, args }), signal: ctl.signal });
    return await r.json();
  } catch (e) {
    return { ok: false, error: ctl.signal.aborted ? `Le serveur ne répond pas à « ${name} » : vérifie que les fichiers sont à jour (refresh + restart worldbuilder)` : 'Erreur de communication' };
  } finally { clearTimeout(timer); }
}

function toast(msg, type = '') {
  const el = document.createElement('div');
  el.className = 'toast ' + type;
  el.textContent = msg;
  document.getElementById('toasts').appendChild(el);
  setTimeout(() => el.remove(), 4200);
}

function confirmBox(title, text, okLabel = 'Confirmer', danger = true) {
  return new Promise(resolve => {
    const c = document.getElementById('confirm');
    c.innerHTML = `<div class="box"><h2>${esc(title)}</h2><p>${esc(text)}</p><div class="row"><span class="spacer"></span><button id="c-no">Annuler</button><button class="${danger ? 'danger' : 'primary'}" id="c-yes">${esc(okLabel)}</button></div></div>`;
    c.classList.remove('hidden');
    const done = v => { c.classList.add('hidden'); c.innerHTML = ''; resolve(v); };
    document.getElementById('c-no').onclick = () => done(false);
    document.getElementById('c-yes').onclick = () => done(true);
  });
}

function setPath(obj, path, val) {
  const keys = path.split('.');
  let o = obj;
  for (let i = 0; i < keys.length - 1; i++) {
    if (o[keys[i]] == null || typeof o[keys[i]] !== 'object') o[keys[i]] = {};
    o = o[keys[i]];
  }
  o[keys[keys.length - 1]] = val;
}
const getPath = (obj, path) => path.split('.').reduce((o, k) => (o == null ? o : o[k]), obj);

/* ── Icônes (style trait fin) ── */
const P = {
  x: '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
  chevron: '<path d="m9 18 6-6-6-6"/>',
  left: '<path d="m15 18-6-6 6-6"/>',
  plus: '<path d="M5 12h14"/><path d="M12 5v14"/>',
  minus: '<path d="M5 12h14"/>',
  search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
  pin: '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/>',
  trash: '<path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/>',
  shirt: '<path d="M20.38 3.46 16 2a4 4 0 0 1-8 0L3.62 3.46a2 2 0 0 0-1.34 2.23l.58 3.47a1 1 0 0 0 .99.84H6v10c0 1.1.9 2 2 2h8a2 2 0 0 0 2-2V10h2.15a1 1 0 0 0 .99-.84l.58-3.47a2 2 0 0 0-1.34-2.23z"/>',
  box: '<path d="m7.5 4.27 9 5.15"/><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/>',
  cart: '<circle cx="8" cy="21" r="1"/><circle cx="19" cy="21" r="1"/><path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12"/>',
  store: '<path d="m2 7 4.41-4.41A2 2 0 0 1 7.83 2h8.34a2 2 0 0 1 1.42.59L22 7"/><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><path d="M15 22v-4a2 2 0 0 0-2-2h-2a2 2 0 0 0-2 2v4"/><path d="M2 7h20"/><path d="M22 7v3a2 2 0 0 1-2 2 2.7 2.7 0 0 1-1.6-.6.7.7 0 0 0-.8 0A2.7 2.7 0 0 1 16 12a2.7 2.7 0 0 1-1.6-.6.7.7 0 0 0-.8 0A2.7 2.7 0 0 1 12 12a2.7 2.7 0 0 1-1.6-.6.7.7 0 0 0-.8 0A2.7 2.7 0 0 1 8 12a2.7 2.7 0 0 1-1.6-.6.7.7 0 0 0-.8 0A2.7 2.7 0 0 1 4 12a2 2 0 0 1-2-2V7"/>',
  shield: '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>',
  user: '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
  users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
  lock: '<rect width="18" height="11" x="3" y="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
  wrench: '<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>',
  heart: '<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>',
  dollar: '<path d="M12 2v20"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>',
  grid: '<rect width="7" height="7" x="3" y="3" rx="1"/><rect width="7" height="7" x="14" y="3" rx="1"/><rect width="7" height="7" x="14" y="14" rx="1"/><rect width="7" height="7" x="3" y="14" rx="1"/>',
  check: '<path d="M20 6 9 17l-5-5"/>',
  target: '<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/>',
  edit: '<path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/>',
  clock: '<circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>',
  tag: '<path d="M12.59 2.59A2 2 0 0 0 11.17 2H4a2 2 0 0 0-2 2v7.17a2 2 0 0 0 .59 1.42l8.7 8.7a2.43 2.43 0 0 0 3.42 0l6.58-6.58a2.43 2.43 0 0 0 0-3.42z"/><circle cx="7.5" cy="7.5" r=".5"/>',
  list: '<path d="M8 6h13"/><path d="M8 12h13"/><path d="M8 18h13"/><path d="M3 6h.01"/><path d="M3 12h.01"/><path d="M3 18h.01"/>',
  percent: '<path d="M19 5 5 19"/><circle cx="6.5" cy="6.5" r="2.5"/><circle cx="17.5" cy="17.5" r="2.5"/>',
  utensils: '<path d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2"/><path d="M7 2v20"/><path d="M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7"/>',
  tablet: '<rect width="16" height="20" x="4" y="2" rx="2"/><path d="M12 18h.01"/>',
  sliders: '<path d="M4 21v-7"/><path d="M4 10V3"/><path d="M12 21v-9"/><path d="M12 8V3"/><path d="M20 21v-5"/><path d="M20 12V3"/><path d="M2 14h4"/><path d="M10 8h4"/><path d="M18 16h4"/>',
  copy: '<rect width="14" height="14" x="8" y="8" rx="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/>',
  chart: '<path d="M3 3v18h18"/><path d="M18 17V9"/><path d="M13 17V5"/><path d="M8 17v-3"/>',
  refresh: '<path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M8 16H3v5"/>',
  map: '<path d="m3 6 6-3 6 3 6-3v15l-6 3-6-3-6 3z"/><path d="M9 3v15"/><path d="M15 6v15"/>',
  settings: '<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>',
  gift: '<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M12 8v13"/><path d="M19 12v7a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-7"/><path d="M7.5 8a2.5 2.5 0 0 1 0-5A4.8 8 0 0 1 12 8a4.8 8 0 0 1 4.5-5 2.5 2.5 0 0 1 0 5"/>',
  card: '<rect width="20" height="14" x="2" y="5" rx="2"/><path d="M2 10h20"/>',
  car: '<path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"/><circle cx="7" cy="17" r="2"/><path d="M9 17h6"/><circle cx="17" cy="17" r="2"/>',
  truck: '<path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2"/><path d="M15 18H9"/><path d="M19 18h2a1 1 0 0 0 1-1v-3.65a1 1 0 0 0-.22-.624l-3.48-4.35A1 1 0 0 0 17.52 8H14"/><circle cx="17" cy="18" r="2"/><circle cx="7" cy="18" r="2"/>',
  key: '<path d="m15.5 7.5 2.3 2.3a1 1 0 0 0 1.4 0l2.1-2.1a1 1 0 0 0 0-1.4L19 4"/><path d="m21 2-9.6 9.6"/><circle cx="7.5" cy="15.5" r="5.5"/>',
  fuel: '<path d="M3 22h12"/><path d="M4 9h10"/><path d="M14 22V4a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v18"/><path d="M14 13h2a2 2 0 0 1 2 2v2a2 2 0 0 0 2 2 2 2 0 0 0 2-2V9.83a2 2 0 0 0-.59-1.42L18 5"/>',
  flask: '<path d="M10 2v7.527a2 2 0 0 1-.211.896L4.72 20.55a1 1 0 0 0 .9 1.45h12.76a1 1 0 0 0 .9-1.45l-5.069-10.127A2 2 0 0 1 14 9.527V2"/><path d="M8.5 2h7"/><path d="M7 16h10"/>',
  mask: '<path d="M18 11c-1.5 0-2.5.5-3 2"/><path d="M4 6a2 2 0 0 0-2 2v4a5 5 0 0 0 5 5 8 8 0 0 1 5 2 8 8 0 0 1 5-2 5 5 0 0 0 5-5V8a2 2 0 0 0-2-2h-3a8 8 0 0 0-5 2 8 8 0 0 0-5-2z"/><path d="M6 11c1.5 0 2.5.5 3 2"/>',
  leaf: '<path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"/><path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"/>',
  boat: '<path d="M2 21c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1 .6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/><path d="M19.38 20A11.6 11.6 0 0 0 21 14l-9-4-9 4c0 2.9.94 5.34 2.81 7.76"/><path d="M19 13V7a2 2 0 0 0-2-2H7a2 2 0 0 0-2 2v6"/><path d="M12 10v4"/><path d="M12 2v3"/>',
  plane: '<path d="M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z"/>',
  diamond: '<path d="M6 3h12l4 6-10 13L2 9Z"/><path d="M11 3 8 9l4 13 4-13-3-6"/><path d="M2 9h20"/>',
  book: '<path d="M12 7v14"/><path d="M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z"/>',
  drop: '<path d="M7 16.3c2.2 0 4-1.83 4-4.05 0-1.16-.57-2.26-1.71-3.19S7.29 6.75 7 5.3c-.29 1.45-1.14 2.84-2.29 3.76S3 11.1 3 12.25c0 2.22 1.8 4.05 4 4.05z"/><path d="M12.56 6.6A10.97 10.97 0 0 0 14 3.02c.5 2.5 2 4.9 4 6.5s3 3.5 3 5.5a6.98 6.98 0 0 1-11.91 4.97"/>',
  flag: '<path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><path d="M4 22v-7"/>',
  logout: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5"/><path d="M21 12H9"/>',
};
const ic = (n, s) => `<svg class="ic" viewBox="0 0 24 24" ${s ? `style="width:${s}px;height:${s}px"` : ''}>${P[n] || P.grid}</svg>`;
const PAY_ICON = { cash: 'dollar', bank: 'card', black_money: 'lock' };

/* ── Thème : couleur d'accentuation (modifiable en jeu) ── */
function applyTheme(rgb) {
  rgb = Array.isArray(rgb) && rgb.length === 3 ? rgb : [239, 68, 68];
  const [r, g, b] = rgb.map(n => Math.max(0, Math.min(255, Math.round(Number(n) || 0))));
  const st = document.documentElement.style;
  st.setProperty('--accent-rgb', `${r}, ${g}, ${b}`);
  st.setProperty('--on-accent', (0.299 * r + 0.587 * g + 0.114 * b) / 255 > 0.62 ? '#16171c' : '#ffffff');
}

/* ── Gabarits de coque ── */
const tile = (icon, cls = '') => `<div class="tile ${cls}">${ic(icon)}</div>`;
const closeBtn = `<button class="icon" data-a="close" title="Fermer">${ic('x', 16)}</button>`;
const fld = (label, input, extra = '') => `<label class="f" ${extra}><span>${label}</span>${input}</label>`;
const chip = (text, cls = '') => `<span class="chip ${cls}">${esc(text)}</span>`;

function header({ icon, title, sub, acts = '' }) {
  return `<div class="head">${tile(icon, 'lg')}<div class="ttl"><h1>${esc(title)}</h1>${sub ? `<p>${esc(sub)}</p>` : ''}</div><div class="acts">${acts}${closeBtn}</div></div>`;
}

function shellSide({ profile, nav, active, foot = '', head, body, bodyCls = '' }) {
  return `<div class="shell"><aside class="side">
    <div class="profile"><div class="avatar">${esc(profile.initials)}</div><div><b>${esc(profile.title)}</b><small>${esc(profile.sub)}</small></div></div>
    <div class="nav">${nav.map(sec => `${sec.label ? `<div class="nav-label">${esc(sec.label)}</div>` : ''}${sec.items.map(it => `<div class="nav-item ${it.id === active ? 'active' : ''}" data-a="nav" data-v="${esc(it.id)}">${ic(it.icon)}<span class="grow">${esc(it.text)}</span>${it.count != null ? `<span class="count">${esc(it.count)}</span>` : ''}</div>`).join('')}`).join('')}</div>
    <div class="side-foot">${foot}</div></aside>
    <section class="main">${header(head)}<div class="body ${bodyCls}">${body}</div></section></div>`;
}

function panel({ icon, title, sub, body, cls = '' }) {
  return `<div class="panel ${cls}">${header({ icon, title, sub })}<div class="pb">${body}</div></div>`;
}

const emptyState = (icon, title, text) => `<div class="empty">${tile(icon)}<h2>${esc(title)}</h2><p>${esc(text)}</p></div>`;

function coordField(path, c, { tp = false } = {}) {
  c = c || {};
  const f = (k, l) => fld(l, `<input type="number" step="0.01" data-path="${path}.${k}" data-t="n" value="${c[k] ?? ''}">`);
  return `<div class="coord ${tp ? 'tp' : ''}">${f('x', 'X')}${f('y', 'Y')}${f('z', 'Z')}${f('h', 'Cap')}
    <button data-a="coords" data-v="${path}">${ic('pin', 15)} Ma position</button>${tp ? `<button data-a="tp" data-v="${path}" ${c.x == null ? 'disabled' : ''}>TP</button>` : ''}</div>`;
}

async function grabCoords(root, path) {
  const p = await rpc('getCoords');
  setPath(root, path, Object.assign({}, getPath(root, path) || {}, { x: r2(p.x), y: r2(p.y), z: r2(p.z), h: r2(p.h) }));
  toast('Position enregistrée', 'ok');
}

const productImg = (path, name, cls = '') => path && name ? `<img class="pimg ${cls}" src="${esc(path.replace('%s', name))}" alt="" loading="lazy" onerror="this.replaceWith(Object.assign(document.createElement('span'),{className:'pimg-ph',innerHTML:window.__box}))">` : `<span class="pimg-ph">${ic('box', 22)}</span>`;
window.__box = ic('box', 22);

/* ════════════════════════════ Mode placement ════════════════════════════ */
const Placement = {
  on: false, targets: [], i: 0, mod: null,

  async start(mod) {
    const t = mod && mod.placementTargets ? mod.placementTargets() : [];
    if (!t.length) return toast('Rien à placer : ajoute d\'abord un emplacement', 'err');
    this.mod = mod; this.targets = t; this.on = true;
    const first = t.findIndex(x => { const c = getPath(x.root, x.path); return !c || c.x == null; });
    this.i = first >= 0 ? first : 0;
    $root.classList.add('hidden');
    this.render();
    await rpc('placement', true);
  },

  hide() { this.on = false; document.getElementById('placement').classList.add('hidden'); },

  render() {
    const el = document.getElementById('placement'), t = this.targets[this.i], c = getPath(t.root, t.path);
    const has = c && c.x != null;
    el.innerHTML = `<div class="eyebrow">Mode placement · ${this.i + 1}/${this.targets.length}</div><b>${esc(t.label)}</b>
      <div class="coords ${has ? 'ok' : ''}">${has ? `✔ ${c.x}, ${c.y}, ${c.z}` : '⚠ position non définie'}</div>
      <div class="dots">${this.targets.map((x, k) => { const cc = getPath(x.root, x.path); return `<i class="${cc && cc.x != null ? 'set' : ''} ${k === this.i ? 'cur' : ''}"></i>`; }).join('')}</div>
      <div class="keys"><span><kbd>Entrée</kbd> Enregistrer ma position ici</span><span><kbd>←</kbd><kbd>→</kbd> Changer de cible</span><span><kbd>Retour</kbd> Revenir au menu</span></div>`;
    el.classList.remove('hidden');
  },

  save(c) {
    if (!this.on) return;
    const t = this.targets[this.i];
    setPath(t.root, t.path, Object.assign({}, getPath(t.root, t.path) || {}, { x: r2(c.x), y: r2(c.y), z: r2(c.z), h: r2(c.h) }));
    if (this.mod) this.mod.dirty = true;
    toast(`${t.label} : position enregistrée`, 'ok');
    if (this.i < this.targets.length - 1) this.i++;
    this.render();
  },

  nav(d) { if (!this.on) return; this.i = (this.i + d + this.targets.length) % this.targets.length; this.render(); },

  end() {
    if (!this.on) return;
    this.hide();
    $root.classList.remove('hidden');
    if (this.mod && this.mod.render) this.mod.render();
  },
};

/* ── Visée d'une porte (builder) ── */
const DoorPick = {
  mod: null, path: null,
  async start(mod, path) { this.mod = mod; this.path = path; $root.classList.add('hidden'); await rpc('doorpick', true); },
  picked(door) {
    if (!this.mod || !this.path) return;
    setPath(this.mod.cur, this.path, { model: door.model, x: r2(door.x), y: r2(door.y), z: r2(door.z), h: r2(door.h) });
    this.mod.markDirty(); toast('Porte enregistrée', 'ok');
    rpc('doorpickEnd').then(() => this.end());
  },
  end() { $root.classList.remove('hidden'); if (this.mod) this.mod.render(); this.mod = null; },
};

/* ════════════════════════════ Routage global ════════════════════════════ */
let Mod = null;
const close = () => rpc('close');

document.addEventListener('keydown', e => {
  if (e.key !== 'Escape') return;
  const modal = document.getElementById('modal');
  if (modal && !modal.classList.contains('hidden')) { Modal.close(); return; }
  if (!document.getElementById('confirm').classList.contains('hidden')) return;
  close();
});
document.addEventListener('click', e => {
  const el = e.target.closest('[data-a]');
  if (!el) return;
  if (el.dataset.a === 'close') return close();
  if (el.dataset.a === 'placeStart') return Placement.start(Mod);
  if (Mod && Mod.onA) Mod.onA(el, e);
});
document.addEventListener('input', e => { if (Mod && Mod.onInput && e.target.dataset.path) Mod.onInput(e.target, false); });
document.addEventListener('change', e => { if (Mod && Mod.onInput) Mod.onInput(e.target, true); });

/* ── Fenêtre modale (sélecteur de produits) ── */
const Modal = {
  open(html) { const m = document.getElementById('modal'); m.innerHTML = html; m.classList.remove('hidden'); },
  close() { const m = document.getElementById('modal'); m.classList.add('hidden'); m.innerHTML = ''; if (Mod && Mod.onModalClose) Mod.onModalClose(); },
  get el() { return document.getElementById('modal'); },
};

/* ════════════════════════════ Messages du jeu ════════════════════════════ */
let progressTimer = null;
function showProgress(label, ms, hint) {
  const el = document.getElementById('progress');
  el.innerHTML = `<div class="plabel"><b>${esc(label)}</b><small>${esc(hint || '')}</small></div><div class="pbar"><i style="animation-duration:${ms}ms"></i></div>`;
  el.classList.remove('hidden');
}
const hideProgress = () => document.getElementById('progress').classList.add('hidden');

window.addEventListener('message', e => {
  const d = e.data;
  if (d.action === 'pvpHud' || d.action === 'pvpStats' || d.action === 'pvpFeed' || d.action === 'pvpRespawn') return PvpHud.handle(d);
  if (d.action === 'chaseState') return ChasePanel.setState(d.state);
  if (d.action === 'chaseHud' || d.action === 'chaseTick' || d.action === 'chaseCount' || d.action === 'chaseResult') return ChaseHud.handle(d);
  if (d.action === 'doorPicked') return DoorPick.picked(d.door);
  if (d.action === 'doorPickEnd') return DoorPick.end();
  if (d.action === 'progress') return showProgress(d.label, d.ms, d.hint);
  if (d.action === 'progressEnd') return hideProgress();
  if (d.action === 'close') { applyTheme(window.__theme); $root.classList.add('hidden'); $root.innerHTML = ''; Placement.hide(); Modal.close(); return; }
  if (d.action === 'placementSave') return Placement.save(d.coords);
  if (d.action === 'placementNav') return Placement.nav(d.dir);
  if (d.action === 'placementEnd') return Placement.end();
  if (d.action === 'theme') { window.__theme = d.accent; if ($root.classList.contains('hidden')) applyTheme(d.accent); return; }
  if (d.action !== 'open') return;
  if (d.theme) window.__theme = d.theme;                          // couleur globale (restaurée à la fermeture)
  if (d.moduleTheme || d.theme) applyTheme(d.moduleTheme || d.theme);   // couleur propre au module si définie
  const now = Date.now();
  if (!$root.classList.contains('hidden') && now - (window.__lastOpen || 0) < 600) return;   // double ouverture : ignorée
  window.__lastOpen = now;
  if ($root.classList.contains('hidden')) { $root.innerHTML = ''; $root.classList.add('fresh'); setTimeout(() => $root.classList.remove('fresh'), 260); }
  $root.classList.remove('hidden', 'corner');
  Placement.hide();
  if (d.kind === 'builder') { Mod = Builder; Builder.open(); }
  else if (Panels[d.kind]) { Mod = Panels[d.kind]; try { Mod.open(d.data); } catch (err) { toast('Erreur interface : ' + err.message, 'err'); console.error(err); rpc('close'); } }
  else { toast('Interface obsolète (« ' + d.kind + ' » inconnu) : refresh + restart worldbuilder', 'err'); rpc('close'); }
});

/* ════════════════════════════ Panneaux joueur ════════════════════════════ */
const payRow = (list, method) => !list || !list.length ? '' : `<div class="lbl">Paiement</div><div class="paygrid wrap">${list.map(p => `<button class="paybtn ${p.id === method ? 'on' : ''}" data-a="pay" data-v="${esc(p.id)}">${ic(PAY_ICON[p.id] || 'dollar', 16)}<span>${esc(p.label)}<small>${money(p.balance)}</small></span></button>`).join('')}</div>`;
const pctBar = (label, v, max) => { const pc = Math.max(0, Math.min(100, Math.round((Number(v) || 0) / max * 100))); return `<div class="mini"><span>${label}</span><div class="bar"><i style="width:${pc}%"></i></div><b>${pc}%</b></div>`; };
const itemImg = (path, name) => `<div class="thumb">${productImg(path, name)}</div>`;

/* Base commune : état, rendu, saisie simple (data-path → this[path]) */
class PanelBase {
  open(d) { this.d = d; this.busy = false; this.method = ((d.payments || [])[0] || {}).id; CUR = (window.__cur || CUR); this.init && this.init(d); this.render(); }
  onInput(el) { const p = el.dataset.path; if (p && !p.startsWith('__')) this[p] = (el.type === 'number' || el.type === 'range' || el.dataset.t === 'n') ? Number(el.value) : el.value; if (this.afterInput) this.afterInput(p, el); }
  async act(name, ...args) {
    if (this.busy) return null;
    this.busy = true;
    const r = await rpc(name, ...args);
    this.busy = false;
    if (!r || r.ok === false) toast((r && r.error) || 'Action impossible', 'err');
    return r;
  }
}

/* ── Garage ── */
const GaragePanel = new (class extends PanelBase {
  render() {
    const d = this.d, job = d.mode === 'job';
    const rows = job
      ? d.fleet.map(f => `<div class="item"><div class="tile">${ic('car')}</div><div class="grow"><b>${esc(f.name)}</b><small class="mono">${esc(f.model)}</small></div>${f.price ? `<span class="price">${money(f.price)}</span>` : chip('Gratuit', 'ok')}<button class="primary sm" data-a="take" data-v="${f.i}">Sortir</button></div>`).join('')
      : d.vehicles.map(v => `<div class="item"><div class="tile">${ic('car')}</div><div class="grow"><b>${esc(v.name)}</b><small class="mono">${esc(v.plate)}</small>
          <div class="minis">${pctBar('Moteur', v.engine ?? 1000, 1000)}${pctBar('Carrosserie', v.body ?? 1000, 1000)}${pctBar('Essence', v.fuel ?? 100, 100)}</div></div>
          <button class="primary sm" data-a="take" data-v="${esc(v.plate)}">Sortir${d.fee ? ` · ${money(d.fee)}` : ''}</button></div>`).join('');
    const empty = job ? 'Aucun véhicule de service disponible pour ton grade.' : 'Aucun véhicule rangé dans ce garage.';
    const needPay = job ? d.fleet.some(f => f.price > 0) : d.fee > 0;
    $root.innerHTML = panel({ icon: job ? 'shield' : 'car', title: d.label, sub: job ? 'Flotte de service' : `${d.vehicles.length} véhicule${d.vehicles.length > 1 ? 's' : ''} disponible${d.vehicles.length > 1 ? 's' : ''}`, cls: 'md',
      body: `${needPay ? payRow(d.payments, this.method) : ''}<div class="list">${rows || emptyState('car', 'Garage vide', empty)}</div>
        <button class="wide" data-a="store" ${d.inVehicle ? '' : 'disabled'}>${ic('logout', 16)} Ranger le véhicule${d.inVehicle ? '' : ' (aucun véhicule à proximité)'}</button>` });
  }
  async onA(el) {
    const a = el.dataset.a;
    if (a === 'pay') { this.method = el.dataset.v; return this.render(); }
    if (a === 'take') { const r = await this.act('garage:take', el.dataset.v, this.method); if (r && r.ok) $root.classList.add('hidden'); }
    if (a === 'store') { const r = await this.act('garage:store'); if (r && r.ok) $root.classList.add('hidden'); }
  }
})();

/* ── Fourrière ── */
const ImpoundPanel = new (class extends PanelBase {
  init() { this.reason = ''; this.fee = 0; }
  render() {
    const d = this.d;
    const rows = d.vehicles.map(v => `<div class="item"><div class="tile">${ic('truck')}</div><div class="grow"><b>${esc(v.name)}</b><small><span class="mono">${esc(v.plate)}</span>${v.reason ? ` · ${esc(v.reason)}` : ''}</small></div><span class="price">${money(v.fee)}</span><button class="primary sm" data-a="take" data-v="${esc(v.plate)}">Récupérer</button></div>`).join('');
    const seize = d.canImpound ? `<div class="card"><div class="card-h"><div class="t">${ic('shield', 17)} Mise en fourrière</div></div>
        <div class="grid2"><label class="f"><span>Raison</span><input data-path="reason" maxlength="150" placeholder="Stationnement gênant…" value="${esc(this.reason)}"></label>
        <label class="f"><span>Frais (${esc(CUR)})</span><input type="number" min="0" data-path="fee" value="${this.fee}"></label></div>
        <button class="primary wide mt-s" data-a="seize" ${d.hasVehicle ? '' : 'disabled'}>${ic('truck', 16)} Mettre le véhicule proche en fourrière</button></div>` : '';
    $root.innerHTML = panel({ icon: 'truck', title: d.label, sub: `${d.vehicles.length} véhicule${d.vehicles.length > 1 ? 's' : ''} à ton nom`, cls: 'md',
      body: `${d.vehicles.length ? payRow(d.payments, this.method) : ''}<div class="list">${rows || emptyState('truck', 'Rien en fourrière', 'Aucun de tes véhicules n\'est ici.')}</div>${seize}` });
  }
  async onA(el) {
    const a = el.dataset.a;
    if (a === 'pay') { this.method = el.dataset.v; return this.render(); }
    if (a === 'take') { const r = await this.act('impound:take', el.dataset.v, this.method); if (r && r.ok) $root.classList.add('hidden'); }
    if (a === 'seize') { const r = await this.act('impound:seize', this.reason, this.fee); if (r && r.ok) $root.classList.add('hidden'); }
  }
})();

/* ── Location ── */
const RentalPanel = new (class extends PanelBase {
  render() {
    const d = this.d;
    const cur = d.current ? `<div class="hint warn">Location en cours : <b>${esc(d.current.model)}</b> (${esc(d.current.plate)}). Ramène-la au point de retour pour récupérer ta caution.</div>` : '';
    const rows = d.fleet.map(f => `<div class="item"><div class="tile">${ic('key')}</div><div class="grow"><b>${esc(f.name)}</b><small>Location ${money(f.price)} + caution ${money(f.deposit)}${d.minutes ? ` · ${d.minutes} min` : ''}</small></div><span class="price">${money(f.price + f.deposit)}</span><button class="primary sm" data-a="rent" data-v="${f.i}" ${d.current ? 'disabled' : ''}>Louer</button></div>`).join('');
    $root.innerHTML = panel({ icon: 'key', title: d.label, sub: d.minutes ? `Durée : ${d.minutes} minutes` : 'Sans limite de durée', cls: 'md',
      body: `${cur}${payRow(d.payments, this.method)}<div class="list">${rows || emptyState('key', 'Aucun véhicule', 'Aucun véhicule disponible à la location.')}</div><div class="hint">La caution est <b>rendue</b> au retour du véhicule (réduite selon les dégâts).</div>` });
  }
  async onA(el) {
    const a = el.dataset.a;
    if (a === 'pay') { this.method = el.dataset.v; return this.render(); }
    if (a === 'rent') { const r = await this.act('rental:rent', Number(el.dataset.v), this.method); if (r && r.ok) $root.classList.add('hidden'); }
  }
})();

/* ── Station essence ── */
const FuelPanel = new (class extends PanelBase {
  init(d) { this.liters = Math.max(1, Math.min(100, 100 - (d.level || 0))); }
  cost() { return Math.ceil(this.liters * (this.d.price || 0)); }
  render() {
    const d = this.d, max = d.vehicle ? Math.max(1, 100 - (d.level || 0)) : 100;
    if (this.liters > max) this.liters = max;
    const tank = d.capacity > 0 ? `<div class="mini"><span>Cuve de la station</span><div class="bar"><i style="width:${Math.round(d.tank / d.capacity * 100)}%"></i></div><b>${Math.round(d.tank)} L</b></div>` : '';
    const veh = d.vehicle ? `<div class="card"><div class="row"><div class="tile">${ic('car')}</div><div class="grow-i"><b>${esc(d.vehicle)}</b><div class="mini"><span>Réservoir</span><div class="bar"><i style="width:${d.level}%"></i></div><b>${d.level}%</b></div></div></div></div>`
      : `<div class="hint warn">Aucun véhicule à proximité de la pompe.</div>`;
    $root.innerHTML = panel({ icon: 'fuel', title: d.label, sub: `${money(d.price)} le litre`, cls: 'md',
      body: `${veh}${tank}
        <div class="card"><label class="f"><span>Quantité : <b id="fl-l">${this.liters} L</b> — <b id="fl-c">${money(this.cost())}</b></span><input type="range" min="1" max="${max}" value="${this.liters}" data-path="liters" ${d.vehicle ? '' : 'disabled'}></label>
        <div class="row mt-s"><button class="sm" data-a="lit" data-v="10">10 L</button><button class="sm" data-a="lit" data-v="25">25 L</button><button class="sm" data-a="lit" data-v="${max}">Plein</button></div></div>
        ${payRow(d.payments, this.method)}
        <button class="primary wide" data-a="fill" ${d.vehicle ? '' : 'disabled'}>${ic('fuel', 16)} Faire le plein</button>
        ${d.jerrycan ? `<div class="card"><div class="row"><div class="tile">${ic('box')}</div><div class="grow-i"><b>Jerricane</b><small class="muted">Pour dépanner un véhicule en panne sèche</small></div><span class="price">${money(d.jerrycan.price)}</span><button class="sm" data-a="jerry">Acheter</button></div></div>` : ''}` });
  }
  afterInput(p) { if (p === 'liters') { document.getElementById('fl-l').textContent = this.liters + ' L'; document.getElementById('fl-c').textContent = money(this.cost()); } }
  async onA(el) {
    const a = el.dataset.a;
    if (a === 'pay') { this.method = el.dataset.v; return this.render(); }
    if (a === 'lit') { this.liters = Math.max(1, Number(el.dataset.v)); return this.render(); }
    if (a === 'fill') { const r = await this.act('fuel:fill', this.liters, this.method); if (r && r.ok) $root.classList.add('hidden'); }
    if (a === 'jerry') { const r = await this.act('fuel:jerrycan', this.d.eid, this.d.pi, this.method); if (r && r.ok) toast('Jerricane acheté', 'ok'); }
  }
})();

/* ── Laboratoire ── */
const LabPanel = new (class extends PanelBase {
  init(d) { this.qty = {}; d.recipes.forEach(r => { this.qty[r.i] = 1; }); }
  render() {
    const d = this.d, img = window.__img;
    const rows = d.recipes.map(r => {
      const can = r.max >= 1, q = Math.min(this.qty[r.i] || 1, Math.max(1, r.max));
      return `<div class="card"><div class="card-h"><div class="t">${ic('flask', 17)} ${esc(r.label)}</div>${r.failChance ? chip(`${r.failChance}% de raté`, 'warn') : ''}${chip(`${r.time}s / lot`, 'mute nodot')}</div>
        <div class="recipe"><div>${r.inputs.map(i => `<div class="rrow">${itemImg(img, i.item)}<b>${esc(i.item)}</b><span class="${i.have >= i.count * q ? 'ok-t' : 'bad'}">${i.have} / ${i.count * q}</span></div>`).join('')}</div>
        <div class="arrow">${ic('chevron', 22)}</div>
        <div>${r.outputs.map(o => `<div class="rrow">${itemImg(img, o.item)}<b>${esc(o.item)}</b><span>×${o.count * q}</span></div>`).join('')}</div></div>
        ${r.tool ? `<div class="hint mt-s">Outil requis : <b>${esc(r.tool)}</b></div>` : ''}
        <div class="row mt-s"><div class="stepper"><button class="icon" data-a="dec" data-v="${r.i}">${ic('minus', 13)}</button><span>${q}</span><button class="icon" data-a="inc" data-v="${r.i}">${ic('plus', 13)}</button></div><span class="spacer"></span>
        <button class="primary" data-a="craft" data-v="${r.i}" ${can ? '' : 'disabled'}>${ic('check', 16)} Fabriquer${can ? '' : ' (ingrédients manquants)'}</button></div></div>`;
    }).join('');
    $root.innerHTML = panel({ icon: 'flask', title: this.d.label, sub: 'Choisis une recette', cls: 'md', body: rows || emptyState('flask', 'Aucune recette', 'Ce poste de travail n\'a pas de recette configurée.') });
  }
  async onA(el) {
    const a = el.dataset.a, i = Number(el.dataset.v), r = this.d.recipes.find(x => x.i === i);
    if (a === 'inc' && r) { this.qty[i] = Math.min(10, Math.max(1, r.max), (this.qty[i] || 1) + 1); return this.render(); }
    if (a === 'dec' && r) { this.qty[i] = Math.max(1, (this.qty[i] || 1) - 1); return this.render(); }
    if (a === 'craft' && r) { const res = await this.act('lab:craft', i, Math.min(this.qty[i] || 1, Math.max(1, r.max))); if (res && res.ok) $root.classList.add('hidden'); }
  }
})();

/* ── Dealer ── */
const DealerPanel = new (class extends PanelBase {
  init(d) { this.qty = {}; }
  render() {
    const d = this.d, img = window.__img;
    const rows = d.items.map(it => {
      const q = Math.max(1, Math.min(this.qty[it.item] || 1, it.have || 1));
      return `<div class="item">${itemImg(img, it.item)}<div class="grow"><b>${esc(it.item)}</b><small>${it.min === it.max ? money(it.min) : `${money(it.min)} – ${money(it.max)}`} l'unité · tu en as ${it.have}</small></div>
        <input class="qty" type="number" min="1" max="${it.have}" value="${q}" data-q="${esc(it.item)}" ${it.have ? '' : 'disabled'}>
        <button class="primary sm" data-a="sell" data-v="${esc(it.item)}" ${it.have ? '' : 'disabled'}>Vendre</button><button class="sm" data-a="sellall" data-v="${esc(it.item)}" ${it.have ? '' : 'disabled'}>Tout</button></div>`;
    }).join('');
    $root.innerHTML = panel({ icon: 'dollar', title: d.label, sub: `Paiement : ${d.account === 'black_money' ? 'argent sale' : d.account === 'bank' ? 'banque' : 'espèces'}`, cls: 'md',
      body: `${d.left >= 0 ? `<div class="hint">Tu peux encore vendre <b>${d.left}</b> unité(s) cette heure.</div>` : ''}<div class="list">${rows || emptyState('dollar', 'Rien à vendre', 'Ce dealer n\'achète rien.')}</div>` });
    $root.querySelectorAll('input[data-q]').forEach(i => i.addEventListener('input', () => { this.qty[i.dataset.q] = Number(i.value); }));
  }
  async sell(item, qty) {
    const r = await this.act('drug:sell', this.d.eid, this.d.pi, item, qty);
    if (!r || !r.ok) return;
    toast(`Vendu ${r.qty} × ${item} pour ${money(r.total)}`, 'ok');
    const it = this.d.items.find(x => x.item === item); if (it) it.have -= r.qty;
    if (this.d.left >= 0) this.d.left = Math.max(0, this.d.left - r.qty);
    this.render();
  }
  onA(el) {
    const a = el.dataset.a, item = el.dataset.v, it = this.d.items.find(x => x.item === item);
    if (a === 'sell' && it) return this.sell(item, Math.max(1, Math.min(this.qty[item] || 1, it.have)));
    if (a === 'sellall' && it) return this.sell(item, it.have);
  }
})();

/* ── Blanchiment ── */
const LaunderPanel = new (class extends PanelBase {
  init(d) { this.amount = Math.max(d.min || 1, Math.min(d.have, d.max || d.have)); }
  recv() { return Math.floor(this.amount * this.d.rate / 100); }
  render() {
    const d = this.d;
    $root.innerHTML = panel({ icon: 'card', title: d.label, sub: `Commission : ${100 - d.rate}%`, cls: '',
      body: `<div class="card" style="text-align:center"><div class="eyebrow" style="justify-content:center">À blanchir (${esc(d.from)})</div><div class="big" style="margin:10px 0">${money(d.have)}</div><div class="hint">Min ${money(d.min)}${d.max ? ` · max ${money(d.max)}` : ''}${d.left >= 0 ? ` · reste ${money(d.left)} cette heure` : ''}</div></div>
        <label class="f"><span>Montant</span><input type="number" min="${d.min}" max="${d.have}" data-path="amount" value="${this.amount}"></label>
        <div class="kv"><span>Tu recevras (${esc(d.to === 'bank' ? 'banque' : d.to === 'money' ? 'espèces' : d.to)})</span><span id="lq-r" class="price">${money(this.recv())}</span></div>
        <button class="primary" data-a="go" ${d.have >= Math.max(1, d.min) ? '' : 'disabled'}>${ic('check', 16)} Blanchir</button>` });
  }
  afterInput(p) { if (p === 'amount') document.getElementById('lq-r').textContent = money(this.recv()); }
  async onA(el) {
    if (el.dataset.a !== 'go') return;
    const r = await this.act('drug:launder', this.d.eid, this.d.pi, this.amount);
    if (r && r.ok) { toast(`Blanchi : ${money(r.received)} reçus`, 'ok'); this.d.have -= r.given; if (this.d.left >= 0) this.d.left = Math.max(0, this.d.left - r.given); this.amount = Math.max(this.d.min || 1, Math.min(this.d.have, this.d.max || this.d.have)); this.render(); }
  }
})();

/* ── Zones PVP : HUD, kill-feed, réapparition ── */
const PvpHud = {
  stats: { kills: 0, deaths: 0, streak: 0 }, zone: '', color: '#ef4444',
  draw() {
    const s = this.stats, kd = s.deaths ? (s.kills / s.deaths).toFixed(2) : s.kills.toFixed(2);
    const el = document.getElementById('pvphud');
    el.style.setProperty('--pc', this.color);
    el.innerHTML = `<b>${esc(this.zone)}</b><div class="pvp-stats"><span>Kills <b>${s.kills}</b></span><span>Morts <b>${s.deaths}</b></span><span>K/D <b>${kd}</b></span><span>Série <b>${s.streak}</b></span></div>`;
  },
  handle(d) {
    const hud = document.getElementById('pvphud'), feed = document.getElementById('pvpfeed'), rs = document.getElementById('pvprespawn');
    if (d.action === 'pvpHud') {
      if (!d.show) { hud.classList.add('hidden'); return; }
      this.zone = d.zone; this.color = d.color || '#ef4444'; if (d.stats) this.stats = d.stats;
      this.draw(); hud.classList.remove('hidden'); return;
    }
    if (d.action === 'pvpStats') { this.stats = d.stats; if (!hud.classList.contains('hidden')) this.draw(); return; }
    if (d.action === 'pvpRespawn') {
      if (!d.show) { rs.classList.add('hidden'); return; }
      rs.innerHTML = `<div class="rs"><small>Tu es mort</small><b>${d.seconds}</b><span>Réapparition…</span></div>`; rs.classList.remove('hidden'); return;
    }
    if (d.action === 'pvpFeed') {
      const e = d.entry, row = document.createElement('div');
      row.className = 'pvp-feed-row';
      row.innerHTML = e.killer ? `<b>${esc(e.killer)}</b> <i>${ic('target', 13)}</i> ${esc(e.victim)}` : `${esc(e.victim)} est mort`;
      feed.prepend(row);
      while (feed.children.length > 5) feed.lastChild.remove();
      setTimeout(() => row.remove(), 6000);
    }
  },
};

/* ── Zones PVP : menu (PNJ) ── */
const PvpPanel = new (class extends PanelBase {
  init() { this.tab = 'zones'; }
  render() {
    const d = this.d, s = d.stats;
    const kd = s.deaths ? (s.kills / s.deaths).toFixed(2) : Number(s.kills).toFixed(2);
    const tabs = [['zones', 'Zones', 'target'], ['board', 'Classement', 'chart'], ['me', 'Mes stats', 'user']];
    let body;
    if (this.tab === 'board') {
      body = `<div class="card"><div class="card-h"><div class="t">${ic('chart', 17)} Classement (kills)</div></div>${d.leaderboard.map((r, i) => `<div class="kv"><span>${i + 1}. ${esc(r.name)}</span><span>${r.kills} kills <span class="muted">· ${r.deaths} morts · série max ${r.best_streak}</span></span></div>`).join('') || '<div class="hint">Aucun combat enregistré.</div>'}</div>`;
    } else if (this.tab === 'me') {
      const stat = (l, v) => `<div class="stat"><div class="eyebrow">${l}</div><div class="v">${v}</div></div>`;
      body = `<div class="grid4">${stat('Kills', s.kills)}${stat('Morts', s.deaths)}${stat('K/D', kd)}${stat('Meilleure série', s.best)}</div>`;
    } else {
      body = d.zones.map(z => `<div class="card"><div class="card-h"><div class="t">${ic('target', 17)} ${esc(z.label)}</div>${chip(`${z.players} joueur${z.players > 1 ? 's' : ''}`, z.players ? 'ok' : 'mute')}</div>
        <div class="hint">Rayon ${Math.round(z.radius)} m${z.giveWeapons ? ` · armes fournies : ${esc(z.weapons.join(', ') || 'aucune')}` : ''}${z.revive ? ' · revive automatique' : ''}${z.reward ? ` · ${money(z.reward)} par kill` : ''}</div>
        <div class="row mt-s"><button class="sm" data-a="gps" data-v="${z.pi}">${ic('map', 14)} Placer le GPS</button></div></div>`).join('') || emptyState('target', 'Aucune zone', 'Aucune zone PVP n\'est configurée.');
    }
    $root.innerHTML = panel({ icon: 'target', title: d.label, sub: `${s.kills} kills · ${s.deaths} morts`, cls: 'md', body: `<div class="seg wrap">${tabs.map(t => `<button class="${t[0] === this.tab ? 'active' : ''}" data-a="tab" data-v="${t[0]}">${ic(t[2], 15)} ${t[1]}</button>`).join('')}</div>${body}` });
  }
  onA(el) {
    const a = el.dataset.a;
    if (a === 'tab') { this.tab = el.dataset.v; return this.render(); }
    if (a === 'gps') rpc('pvp:waypoint', Number(el.dataset.v));
  }
})();

/* ── Course poursuite : HUD en partie ── */
const ChaseHud = {
  role: null, catchTime: 3000, headStart: 0, resultTimer: null,
  fmt(ms) { const s = Math.max(0, Math.ceil(ms / 1000)); return `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`; },
  handle(d) {
    const hud = document.getElementById('chasehud'), cnt = document.getElementById('chasecount'), res = document.getElementById('chaseresult');
    if (d.action === 'chaseHud') {
      if (!d.show) { hud.classList.add('hidden'); cnt.classList.add('hidden'); return; }
      this.role = d.role; this.catchTime = d.catchTime || 3000; this.headStart = d.headStart || 0;
      hud.className = `chase-${d.role}`;
      hud.innerHTML = `<div class="ch-head"><b>${d.role === 'runner' ? 'FUGITIF' : 'POURSUIVANT'}</b><span id="ch-time">--:--</span></div><div class="ch-msg" id="ch-msg"></div>
        <div class="ch-row"><span>Distance</span><b id="ch-dist">—</b></div><div class="ch-bar"><i id="ch-bar"></i></div><div class="ch-row"><span>Contact</span><b id="ch-contact">0.0 s</b></div>`;
      cnt.classList.add('hidden');
      return;
    }
    if (d.action === 'chaseCount') {
      cnt.innerHTML = `<div class="cc ${d.role || ''}"><small>${d.role === 'runner' ? 'Tu es le fugitif' : 'Tu es poursuivant'}</small><b>${esc(d.value)}</b></div>`;
      cnt.classList.remove('hidden');
      if (d.value === 'GO') setTimeout(() => cnt.classList.add('hidden'), 900);
      return;
    }
    if (d.action === 'chaseTick') {
      const t = d.tick, $ = id => document.getElementById(id);
      if (!$('ch-time')) return;
      $('ch-time').textContent = this.fmt(t.remaining);
      $('ch-dist').textContent = t.dist > 9000 ? '—' : `${Math.round(t.dist)} m`;
      const pc = Math.min(100, Math.round((t.contact / (t.catchTime || this.catchTime)) * 100));
      $('ch-bar').style.width = pc + '%'; $('ch-bar').className = pc > 66 ? 'hot' : pc > 33 ? 'warm' : '';
      $('ch-contact').textContent = `${(t.contact / 1000).toFixed(1)} s / ${(((t.catchTime || this.catchTime)) / 1000).toFixed(0)} s`;
      $('ch-msg').textContent = t.releaseIn > 0 ? (this.role === 'runner' ? `Avance : poursuivants libérés dans ${Math.ceil(t.releaseIn / 1000)} s` : `Départ dans ${Math.ceil(t.releaseIn / 1000)} s…`) : (this.role === 'runner' ? 'Fuis ! Ne te laisse pas coller.' : 'Colle le fugitif !');
      return;
    }
    if (d.action === 'chaseResult') {
      clearTimeout(this.resultTimer);
      if (!d.result) { res.classList.add('hidden'); return; }
      const r = d.result;
      res.innerHTML = `<div class="cr ${r.won ? 'won' : 'lost'}"><small>${r.winner === 'none' ? 'Course annulée' : r.winner === 'runner' ? 'Le fugitif gagne' : 'Les poursuivants gagnent'}</small><b>${r.winner === 'none' ? 'ANNULÉE' : r.won ? 'VICTOIRE' : 'DÉFAITE'}</b><p>${esc(r.reason || '')}</p>
        <div class="row" style="justify-content:center;gap:18px"><span>Durée : <b>${this.fmt(r.elapsed || 0)}</b></span>${r.winner === 'none' ? (r.reward ? `<span>Remboursé : <b>${money(r.reward)}</b></span>` : '') : r.won ? (r.reward ? `<span>Gain : <b>+${money(r.reward)}</b></span>` : '') : (r.lost ? `<span>Perdu : <b>-${money(r.lost)}</b></span>` : '')}</div></div>`;
      res.classList.remove('hidden');
      this.resultTimer = setTimeout(() => res.classList.add('hidden'), ((r.delay || 8) + 1) * 1000);
    }
  },
};

/* ── Course poursuite : grand panel (lobbies) ── */
const ChasePanel = new (class extends PanelBase {
  init(d) { this.state = null; this.tab = 'lobbies'; this.board = null; this.pickEnd = 0; this.form = { name: '', map: d.maps[0] ? d.maps[0].id : null, duration: d.cfg.duration.default, maxChasers: Math.min(2, d.cfg.maxChasers), role: 'runner' }; this.vehCat = null; this.stopTimer(); }
  stopTimer() { if (this.timer) { clearInterval(this.timer); this.timer = null; } }
  setState(s) {
    if (Mod !== this || $root.classList.contains('hidden')) return;
    this.state = s;
    // fenêtre de choix du véhicule (10 s après l'arrivée d'un joueur) : le serveur envoie le temps restant
    this.pickEnd = (s.current && s.current.pickLeft > 0) ? Date.now() + s.current.pickLeft : 0;
    if (s.current) this.tab = 'lobby'; else if (this.tab === 'lobby') this.tab = 'lobbies';
    this.render();
    this.stopTimer();
    if (this.pickEnd) this.timer = setInterval(() => this.tick(), 200);
  }
  pickLeft() { return Math.max(0, this.pickEnd - Date.now()); }
  tick() {
    if (Mod !== this || $root.classList.contains('hidden')) return this.stopTimer();
    const left = this.pickLeft();
    if (left <= 0) { this.pickEnd = 0; this.stopTimer(); return this.render(); }
    const t = document.getElementById('pickcd'), b = document.getElementById('pickbar');
    if (t) t.textContent = Math.ceil(left / 1000);
    if (b) b.style.width = Math.min(100, left / (this.d.cfg.pickTime * 10)) + '%';
  }
  stats(s) { return s ? `${s.matches} parties · ${s.wins_runner + s.wins_chaser} victoires` : ''; }
  render() {
    const d = this.d, s = this.state, cur = s && s.current;
    const initials = ((s && s.name) || '?').split(' ').map(x => x[0]).join('').slice(0, 2).toUpperCase();
    let body;
    if (!s) body = '<div class="hint">Chargement…</div>';
    else if (this.tab === 'board') body = this.viewBoard();
    else if (this.tab === 'lobby' && cur) body = this.viewLobby(cur);
    else body = this.viewLobbies(s);
    const titles = { lobbies: ['Parties', 'Crée ou rejoins une course poursuite'], lobby: ['Mon lobby', cur ? cur.name : ''], board: ['Classement', 'Les meilleurs pilotes'] };
    const t = titles[this.tab] || titles.lobbies;
    $root.innerHTML = shellSide({
      profile: { initials, title: s ? s.name : '…', sub: s ? this.stats(s.stats) : '' },
      nav: [{ label: d.label, items: [
        { id: 'lobbies', icon: 'grid', text: 'Parties', count: s ? s.lobbies.length : null },
        ...(cur ? [{ id: 'lobby', icon: 'car', text: 'Mon lobby', count: `${cur.players.length}` }] : []),
        { id: 'board', icon: 'chart', text: 'Classement' }] }],
      active: this.tab,
      foot: `<small>Les poursuivants gagnent s'ils restent collés (${d.cfg.catchDistance} m) au fugitif pendant ${d.cfg.catchTime} s ; sinon le fugitif gagne au bout du temps.</small>`,
      head: { icon: 'flag', title: t[0], sub: t[1] }, body });
  }
  roleBtns(sel, act) { return `<div class="row">${[['runner', 'Fugitif'], ['chaser', 'Poursuivant']].map(r => `<button class="grow-i ${sel === r[0] ? 'primary' : ''}" data-a="${act}" data-v="${r[0]}">${r[1]}</button>`).join('')}</div>`; }
  viewLobbies(s) {
    const d = this.d, f = this.form;
    const lobbies = s.lobbies.map(l => `<div class="item"><div class="tile">${ic('flag')}</div><div class="grow"><b>${esc(l.name)}</b><small>${esc(l.mapLabel)} · ${l.duration} min · ${l.runners}/1 fugitif · ${l.chasers}/${l.maxChasers} poursuivants${l.fee > 0 ? ` · mise ${money(l.fee)}` : ''}</small></div>
      ${l.state === 'lobby' ? `<button class="sm" data-a="join" data-v="${l.id}:runner" ${l.runners >= 1 ? 'disabled' : ''}>Fugitif</button><button class="primary sm" data-a="join" data-v="${l.id}:chaser" ${l.chasers >= l.maxChasers ? 'disabled' : ''}>Poursuivant</button>` : chip('En cours', 'warn')}</div>`).join('');
    return `<div class="chase-cols"><div><div class="card"><div class="card-h"><div class="t">${ic('plus', 17)} Créer une partie</div></div>
        <div class="grid2"><label class="f"><span>Nom</span><input data-path="form.name" maxlength="28" placeholder="Course de ${esc(s.name)}" value="${esc(f.name)}"></label>
        <label class="f"><span>Carte</span><select data-path="form.map" data-t="n">${d.maps.map(m => `<option value="${m.id}" ${m.id === f.map ? 'selected' : ''}>${esc(m.label)}</option>`).join('')}</select></label>
        <label class="f"><span>Durée : <b>${f.duration} min</b></span><input type="range" min="${d.cfg.duration.min}" max="${d.cfg.duration.max}" value="${f.duration}" data-path="form.duration"></label>
        <label class="f"><span>Poursuivants max : <b>${f.maxChasers}</b></span><input type="range" min="1" max="${d.cfg.maxChasers}" value="${f.maxChasers}" data-path="form.maxChasers"></label></div>
        <div class="lbl mt-s">Ton rôle</div>${this.roleBtns(f.role, 'formRole')}
        <div class="hint mt-s">${d.cfg.reward.fee > 0 ? `Mise d'entrée : <b>${money(d.cfg.reward.fee)}</b> par joueur, débitée au lancement. Le gagnant empoche les mises, le perdant perd la sienne.` : 'Course gratuite.'}</div>
        <button class="primary wide mt-s" data-a="create" ${d.maps.length ? '' : 'disabled'}>${ic('check', 16)} Créer la partie</button></div></div>
      <div><div class="lbl">Parties ouvertes</div>${lobbies || emptyState('flag', 'Aucune partie', 'Crée la première partie à gauche.')}</div></div>`;
  }
  viewLobby(m) {
    const d = this.d, me = m.players.find(p => p.src === this.state.you) || {}, host = me.host;
    const cats = [...new Set(d.vehicles.map(v => v.category || 'Autre'))];
    const cat = this.vehCat || (d.vehicles.find(v => v.model === me.vehicle) || {}).category || cats[0];
    const bar = (l, v) => `<div class="mini"><span>${l}</span><div class="bar"><i style="width:${v}%"></i></div></div>`;
    const left = this.pickLeft(), picking = left > 0;
    const players = m.players.map(p => `<div class="item"><div class="tile">${ic(p.role === 'runner' ? 'target' : 'car')}</div><div class="grow"><b>${esc(p.name)}${p.host ? ' ★' : ''}</b><small>${esc((d.vehicles.find(v => v.model === p.vehicle) || {}).label || p.vehicle)}</small></div>${chip(p.role === 'runner' ? 'Fugitif' : 'Poursuivant', p.role === 'runner' ? 'warn' : 'info')}</div>`).join('');
    const banner = picking ? `<div class="pickbanner"><div><b>Choisis ton véhicule !</b><small>La partie ne peut pas être lancée pendant ce temps.</small></div><span id="pickcd">${Math.ceil(left / 1000)}</span><div class="pickbar"><i id="pickbar" style="width:${Math.min(100, left / (d.cfg.pickTime * 10))}%"></i></div></div>` : '';
    const canStart = m.runners === 1 && m.chasers >= 1 && !picking;
    return `${banner}<div class="chase-lobby"><div>
        <div class="card"><div class="card-h"><div class="t">${ic('flag', 17)} ${esc(m.name)}</div>${chip(m.state === 'lobby' ? 'En attente' : 'Lancement…', m.state === 'lobby' ? 'mute' : 'ok')}</div>
          <div class="hint">${esc(m.mapLabel)} · ${m.duration} min · ${m.runners}/1 fugitif · ${m.chasers}/${m.maxChasers} poursuivants${m.fee > 0 ? ` · mise ${money(m.fee)} / joueur (cagnotte ${money(m.fee * m.players.length)})` : ''}</div></div>
        <div class="lbl mt-s">Joueurs</div>${players}
        <div class="lbl">Ton rôle</div>${this.roleBtns(me.role, 'setRole')}
        <div class="row mt"><button class="danger" data-a="leave">Quitter</button><span class="spacer"></span>${host ? `<button class="primary" data-a="start" ${canStart ? '' : 'disabled'}>${ic('check', 16)} ${picking ? 'Choix du véhicule…' : 'Lancer la partie'}</button>` : '<span class="hint">En attente de l\'hôte…</span>'}</div>
      </div><div>
        <div class="lbl">Ton véhicule</div><div class="seg wrap" style="margin-bottom:10px">${cats.map(c => `<button class="${c === cat ? 'active' : ''}" data-a="vcat" data-v="${esc(c)}">${esc(c)}</button>`).join('')}</div>
        <div class="veh-grid">${d.vehicles.filter(v => (v.category || 'Autre') === cat).map(v => `<div class="item click" data-a="setVehicle" data-v="${esc(v.model)}" style="${v.model === me.vehicle ? 'border-color:var(--accent-line);background:var(--accent-soft)' : ''}"><div class="tile">${ic('car')}</div><div class="grow"><b>${esc(v.label)}</b><div class="minis">${bar('Vitesse', v.speed)}${bar('Accél.', v.accel)}${bar('Tenue', v.handling)}</div></div>${v.model === me.vehicle ? chip('Choisi', 'ok') : ''}</div>`).join('')}</div>
      </div></div>`;
  }
  viewBoard() {
    const rows = (this.board || []).map((r, i) => `<div class="kv"><span>${i + 1}. ${esc(r.name)}</span><span>${r.wins} victoire${r.wins > 1 ? 's' : ''} <span class="muted">· ${r.matches} parties (F ${r.wins_runner} / P ${r.wins_chaser})</span></span></div>`).join('');
    return `<div class="card"><div class="card-h"><div class="t">${ic('chart', 17)} Classement</div></div>${this.board ? (rows || '<div class="hint">Aucune partie jouée.</div>') : '<div class="hint">Chargement…</div>'}</div>`;
  }
  afterInput(p, el) {
    if (!p || !p.startsWith('form.')) return;
    const k = p.slice(5);
    this.form[k] = (k === 'name') ? el.value : Number(el.value);
    if (k === 'duration' || k === 'maxChasers') { const l = el.closest('label').querySelector('b'); if (l) l.textContent = k === 'duration' ? `${this.form.duration} min` : this.form.maxChasers; }
  }
  onInput(el) {
    const p = el.dataset.path;
    if (p && p.startsWith('form.')) return this.afterInput(p, el);
  }
  async onA(el) {
    const a = el.dataset.a, v = el.dataset.v;
    if (a === 'nav' || a === 'tab') {
      if (v === 'lobby' && !(this.state && this.state.current)) return;
      this.tab = v;
      if (v === 'board') { this.board = null; this.render(); const r = await rpc('chase:leaderboard'); this.board = (r && r.rows) || []; }
      return this.render();
    }
    if (a === 'formRole') { this.form.role = v; return this.render(); }
    if (a === 'create') { rpc('chase:create', { name: this.form.name, map: this.form.map, duration: this.form.duration, maxChasers: this.form.maxChasers, role: this.form.role }); return; }
    if (a === 'join') { const [id, role] = v.split(':'); rpc('chase:join', { id: Number(id), role }); return; }
    if (a === 'setRole') { rpc('chase:setRole', v); return; }
    if (a === 'setVehicle') { rpc('chase:setVehicle', v); return; }
    if (a === 'vcat') { this.vehCat = v; return this.render(); }
    if (a === 'leave') { rpc('chase:leave'); this.tab = 'lobbies'; return; }
    if (a === 'start') { rpc('chase:start'); return; }
  }
})();

/* ── Occasion ── */
const CarlotPanel = new (class extends PanelBase {
  init(d) { this.tab = d.focus ? 'focus' : 'buy'; this.sel = null; this.price = 0; this.desc = ''; this.phone = ''; this.edit = {}; }
  async call(name, ...a) {
    const r = await this.act(name, ...a);
    if (r && r.ok) { const keep = { eid: this.d.eid, pi: this.d.pi }; this.d = Object.assign(r, keep); if (this.tab === 'focus') this.tab = 'buy'; this.render(); }
    return r;
  }
  card(l, actions) {
    return `<div class="card"><div class="card-h"><div class="t">${ic('car', 17)} ${esc(l.name)}</div><span class="price">${money(l.price)}</span></div>
      ${l.desc ? `<div style="margin-bottom:8px;line-height:1.5">${esc(l.desc)}</div>` : '<div class="hint">Pas de description.</div>'}
      <div class="hint">Vendeur : <b>${esc(l.seller)}</b>${l.phone ? ` · Tel : <b>${esc(l.phone)}</b>` : ''}${l.plate ? ` · Plaque : <span class="mono">${esc(l.plate)}</span>` : ''}</div>${actions ? `<div class="row mt-s">${actions}</div>` : ''}</div>`;
  }
  render() {
    const d = this.d, sell = d.kind === 'lot';
    const tabs = [['buy', 'Annonces'], ...(sell ? [['sell', 'Vendre mon véhicule'], ['mine', 'Mes annonces']] : [])];
    const head = `<div class="seg wrap">${tabs.map(t => `<button class="${t[0] === (this.tab === 'focus' ? 'buy' : this.tab) ? 'active' : ''}" data-a="tab" data-v="${t[0]}">${t[1]}</button>`).join('')}</div>`;
    let body = '';
    if (this.tab === 'focus') {
      const l = d.listings.find(x => x.id === d.focus);
      body = (l ? this.card(l, l.mine ? `<button class="danger" data-a="cancel" data-v="${l.id}">Retirer mon annonce</button>` : `<button class="primary" data-a="buy" data-v="${l.id}">Acheter · ${money(l.price)}</button>`) : emptyState('car', 'Annonce introuvable', 'Elle vient peut-être d\'être vendue.')) + payRow(d.payments, this.method)
        + `<button class="wide" data-a="tab" data-v="buy">Voir toutes les annonces</button>`;
    } else if (this.tab === 'buy') {
      body = payRow(d.payments, this.method) + (d.listings.map(l => this.card(l, l.mine ? chip('Ton annonce', 'info') : `<button class="primary" data-a="buy" data-v="${l.id}">Acheter · ${money(l.price)}</button>`)).join('') || emptyState('car', 'Aucune annonce', 'Aucun véhicule en vente pour le moment.'));
    } else if (this.tab === 'sell') {
      const lim = [d.minPrice ? `min ${money(d.minPrice)}` : '', d.maxPrice ? `max ${money(d.maxPrice)}` : ''].filter(Boolean).join(' · ');
      body = `<div class="hint">Frais d'annonce : <b>${money(d.fee)}</b> · commission à la vente : <b>${d.commission}%</b> · ${d.days ? `durée : <b>${d.days} jour(s)</b>` : 'sans limite de durée'} · annonces : <b>${d.mineCount}/${d.maxListings}</b> · places libres : <b>${d.freeSlots}</b></div>
        <div class="lbl">1. Choisis un véhicule (rangé dans ton garage)</div>
        <div class="list">${d.vehicles.map(v => `<div class="item click ${v.plate === this.sel ? 'sel' : ''}" data-a="pick" data-v="${esc(v.plate)}" style="${v.plate === this.sel ? 'border-color:var(--accent-line);background:var(--accent-soft)' : ''}"><div class="tile">${ic('car')}</div><div class="grow"><b>${esc(v.name)}</b><small class="mono">${esc(v.plate)}</small></div>${v.plate === this.sel ? chip('Sélectionné', 'ok') : ''}</div>`).join('') || '<div class="hint warn">Aucun véhicule rangé dans ton garage : range-le d\'abord dans un garage.</div>'}</div>
        <div class="lbl">2. Prix et annonce</div>
        <div class="grid2"><label class="f"><span>Prix (${esc(CUR)})${lim ? ' — ' + lim : ''}</span><input type="number" min="1" data-path="price" value="${this.price || ''}"></label><label class="f"><span>Téléphone (optionnel)</span><input data-path="phone" maxlength="20" value="${esc(this.phone)}" placeholder="555-0123"></label></div>
        <label class="f"><span>Description (état, kilométrage, remarques…)</span><textarea data-path="desc" maxlength="140" placeholder="Ex : Très bon état, jamais accidentée, peinture refaite…">${esc(this.desc)}</textarea></label>
        ${payRow(d.payments, this.method)}
        <button class="primary wide" data-a="list" ${this.sel && this.price > 0 && d.freeSlots > 0 && d.mineCount < d.maxListings ? '' : 'disabled'}>${ic('check', 16)} Mettre en vente${d.fee ? ' · ' + money(d.fee) : ''}</button>
        ${d.freeSlots < 1 ? '<div class="hint warn">Aucune place d\'exposition libre pour le moment.</div>' : ''}`;
    } else {
      const mine = d.listings.filter(l => l.mine);
      body = mine.map(l => this.card(l, `<input class="qty" style="width:120px" type="number" min="1" data-edit="${l.id}" value="${this.edit[l.id] ?? l.price}"><button class="sm" data-a="reprice" data-v="${l.id}">Changer le prix</button><span class="spacer"></span><button class="danger sm" data-a="cancel" data-v="${l.id}">Retirer</button>`)).join('') || emptyState('car', 'Aucune annonce', 'Tu n\'as aucun véhicule en vente.');
    }
    $root.innerHTML = panel({ icon: 'car', title: d.label, sub: sell ? 'Annonces de véhicules' : 'Annonce', cls: 'md', body: head + body });
    $root.querySelectorAll('input[data-edit]').forEach(i => i.addEventListener('input', () => { this.edit[i.dataset.edit] = Number(i.value); }));
  }
  afterInput(p) { if (p === 'price') { const b = $root.querySelector('[data-a="list"]'); if (b) b.disabled = !(this.sel && this.price > 0 && this.d.freeSlots > 0 && this.d.mineCount < this.d.maxListings); } }
  async onA(el) {
    const a = el.dataset.a, v = el.dataset.v;
    if (a === 'pay') { this.method = v; return this.render(); }
    if (a === 'tab') { this.tab = v; return this.render(); }
    if (a === 'pick') { this.sel = v; return this.render(); }
    if (a === 'buy') { const r = await this.call('carlot:buy', Number(v), this.method); if (r && r.ok) toast('Véhicule acheté : il est dans ton garage', 'ok'); }
    if (a === 'list') { const r = await this.call('carlot:list', this.sel, this.price, this.desc, this.phone, this.method); if (r && r.ok) { this.sel = null; this.price = 0; this.desc = ''; this.tab = 'mine'; this.render(); toast('Annonce publiée', 'ok'); } }
    if (a === 'cancel') { const r = await this.call('carlot:cancel', Number(v)); if (r && r.ok) toast('Annonce retirée : véhicule rendu à ton garage', 'ok'); }
    if (a === 'reprice') { const r = await this.call('carlot:price', Number(v), this.edit[v] ?? 0); if (r && r.ok) toast('Prix modifié', 'ok'); }
  }
})();

/* ── Serrurier ── */
const LocksmithPanel = new (class extends PanelBase {
  render() {
    const d = this.d;
    const rows = d.vehicles.map(v => `<div class="item"><div class="tile">${ic('car')}</div><div class="grow"><b>${esc(v.name)}</b><small><span class="mono">${esc(v.plate)}</span> · ${v.nearby ? 'près de l\'atelier' : 'absent'}</small></div>${v.hasKey === true ? chip('Clé possédée', 'ok') : v.hasKey === false ? chip('Sans clé', 'warn') : ''}
      <span class="price">${money(d.price)}</span><button class="primary sm" data-a="make" data-v="${esc(v.plate)}" ${v.canMake ? '' : 'disabled'}>Refaire la clé</button></div>`).join('');
    $root.innerHTML = panel({ icon: 'key', title: d.label, sub: 'Duplicata de clés', cls: 'md',
      body: `${payRow(d.payments, this.method)}${d.requireNearby ? '<div class="hint">Amène ton véhicule près de l\'atelier pour en refaire la clé.</div>' : ''}<div class="list">${rows || emptyState('key', 'Aucun véhicule', 'Tu ne possèdes aucun véhicule.')}</div>` });
  }
  async onA(el) {
    const a = el.dataset.a;
    if (a === 'pay') { this.method = el.dataset.v; return this.render(); }
    if (a === 'make') { const r = await this.act('locksmith:make', this.d.eid, this.d.pi, el.dataset.v, this.method); if (r && r.ok) toast(`Clé refaite (${money(r.paid)})`, 'ok'); }
  }
})();

/* ── Station de lavage ── */
const CarwashPanel = new (class extends PanelBase {
  render() {
    const d = this.d;
    const rows = d.programs.map(g => `<div class="item"><div class="tile">${ic('drop')}</div><div class="grow"><b>${esc(g.label)}</b><small>${g.seconds} secondes</small></div><span class="price">${money(g.price)}</span><button class="primary sm" data-a="wash" data-v="${g.i}">Laver</button></div>`).join('');
    $root.innerHTML = panel({ icon: 'drop', title: d.label, sub: d.vehicle, cls: 'md',
      body: `<div class="card"><div class="mini"><span>Saleté du véhicule</span><div class="bar"><i style="width:${d.dirt}%"></i></div><b>${d.dirt}%</b></div></div>${payRow(d.payments, this.method)}<div class="list">${rows || emptyState('drop', 'Aucun programme', 'Cette station ne propose aucun lavage.')}</div>` });
  }
  async onA(el) {
    const a = el.dataset.a;
    if (a === 'pay') { this.method = el.dataset.v; return this.render(); }
    if (a === 'wash') { const r = await this.act('carwash:start', Number(el.dataset.v), this.method); if (r && r.ok) $root.classList.add('hidden'); }
  }
})();

/* ── Auto-école ── */
const DrivingPanel = new (class extends PanelBase {
  init() { this.view = 'list'; this.quiz = null; this.result = null; }
  render() {
    if (this.view === 'quiz') return this.renderQuiz();
    if (this.view === 'result') return this.renderResult();
    const d = this.d;
    const cards = d.licenses.map(l => `<div class="card"><div class="card-h"><div class="t">${ic('key', 17)} ${esc(l.label)}</div>${l.owned ? chip('Obtenu', 'ok') : l.lock ? chip('Verrouillé', 'warn') : l.theory && l.theory.done ? chip('Code réussi', 'info') : chip('Disponible', 'mute')}</div>
        ${l.lock ? `<div class="hint warn">${esc(l.lock)}</div>` : ''}
        <div class="row wrap">${l.theory ? `<button class="primary" data-a="theory" data-v="${esc(l.id)}" ${l.canTheory ? '' : 'disabled'}>Passer le code · ${money(l.theory.price)}</button>` : ''}
        ${l.practical ? `<button class="primary" data-a="practical" data-v="${esc(l.id)}" ${l.canPractical ? '' : 'disabled'}>Passer la conduite · ${money(l.practical.price)}</button>` : ''}</div>
        <div class="hint mt-s">${[l.theory ? `Code : ${l.theory.count} questions, ${l.theory.passPercent}% requis` : '', l.practical ? `Conduite : limite ${l.practical.speedLimit} km/h, ${l.practical.maxFaults} faute(s) max` : ''].filter(Boolean).join(' · ')}</div></div>`).join('');
    $root.innerHTML = panel({ icon: 'book', title: d.label, sub: 'Passe tes permis', cls: 'md', body: `${payRow(d.payments, this.method)}${cards || emptyState('book', 'Aucun permis', 'Cette auto-école ne propose aucun permis.')}` });
  }
  renderQuiz() {
    const q = this.quiz, cur = q.questions[q.i];
    $root.innerHTML = panel({ icon: 'book', title: q.label, sub: `Question ${q.i + 1} / ${q.questions.length}`, cls: 'md',
      body: `<div class="segs">${q.questions.map((_, k) => `<i class="${k <= q.i ? 'on' : ''}"></i>`).join('')}</div><div class="card"><b style="font-size:16px;line-height:1.4">${esc(cur.q)}</b></div>
        ${cur.answers.map((a, k) => `<button class="wide" style="justify-content:flex-start;height:auto;min-height:42px;padding:10px 14px;white-space:normal;text-align:left" data-a="answer" data-v="${k + 1}">${k + 1}. ${esc(a)}</button>`).join('')}` });
  }
  renderResult() {
    const r = this.result;
    $root.innerHTML = panel({ icon: 'book', title: r.passed ? 'Code réussi !' : 'Code raté', sub: `${r.right} / ${r.total} bonnes réponses (${r.percent}%) — ${r.need}% requis`, cls: '',
      body: `<div class="card" style="text-align:center"><div class="big">${r.percent}%</div>${r.passed ? chip(r.granted ? 'Permis délivré' : r.practical ? 'Tu peux passer la conduite' : 'Réussi', 'ok') : chip('Échec', 'bad')}</div><button class="primary" data-a="back">Retour</button>` });
  }
  async onA(el) {
    const a = el.dataset.a, v = el.dataset.v;
    if (a === 'pay') { this.method = v; return this.render(); }
    if (a === 'back') { this.view = 'list'; const r = await rpc('driving:info'); if (r && r.ok) Object.assign(this.d, r); return this.render(); }
    if (a === 'theory') {
      const r = await this.act('driving:theoryStart', this.d.eid, this.d.pi, v, this.method);
      if (r && r.ok) { this.quiz = { questions: r.questions, i: 0, answers: [], label: r.label }; this.view = 'quiz'; this.render(); }
    }
    if (a === 'answer') {
      const q = this.quiz; q.answers.push(Number(v)); q.i++;
      if (q.i < q.questions.length) return this.render();
      const r = await this.act('driving:theorySubmit', q.answers);
      if (r && r.ok) { this.result = r; this.view = 'result'; this.render(); }
    }
    if (a === 'practical') { const r = await this.act('driving:practicalStart', v, this.method); if (r && r.ok) $root.classList.add('hidden'); }
  }
})();

/* ── Banque ── */
const BankPanel = new (class extends PanelBase {
  init() { this.amount = 100; this.target = ''; }
  render() {
    const d = this.d, f = d.fees, atm = d.kind === 'atm';
    const note = (l, p) => p > 0 ? `${l} ${p}%` : '';
    $root.innerHTML = panel({ icon: atm ? 'card' : 'dollar', title: d.label, sub: atm ? 'Distributeur' : 'Guichet', cls: 'md',
      body: `<div class="grid2"><div class="card" style="text-align:center"><div class="eyebrow" style="justify-content:center">Espèces</div><div class="big" style="font-size:30px;margin:8px 0">${money(d.money)}</div></div>
        <div class="card" style="text-align:center"><div class="eyebrow" style="justify-content:center">Compte bancaire</div><div class="big" style="font-size:30px;margin:8px 0">${money(d.bank)}</div></div></div>
        <label class="f"><span>Montant</span><input type="number" min="1" data-path="amount" value="${this.amount}"></label>
        <div class="row wrap">${[100, 500, 1000, 5000].map(n => `<button class="sm" data-a="amt" data-v="${n}">${money(n)}</button>`).join('')}<button class="sm" data-a="amt" data-v="bank">Tout le compte</button>${d.canDeposit ? '<button class="sm" data-a="amt" data-v="cash">Toutes les espèces</button>' : ''}</div>
        <div class="row"><button class="primary grow-i" data-a="withdraw">Retirer</button>${d.canDeposit ? '<button class="primary grow-i" data-a="deposit">Déposer</button>' : ''}</div>
        <div class="hint">${[note('Frais de retrait', f.withdraw), d.canDeposit ? note('Frais de dépôt', f.deposit) : '', note('Frais de virement', f.transfer), d.max ? `Max par opération : ${money(d.max)}` : '', d.left >= 0 ? `Retrait restant aujourd'hui : ${money(d.left)}` : ''].filter(Boolean).join(' · ') || 'Aucun frais.'}</div>
        <div class="card"><div class="card-h"><div class="t">${ic('users', 17)} Virement</div></div><div class="row"><input type="number" min="1" placeholder="ID du joueur" data-path="target" value="${esc(this.target)}" style="width:150px"><button class="grow-i" data-a="transfer">Virer le montant ci-dessus</button></div></div>` });
  }
  async run(name, ...a) {
    const r = await this.act(name, this.d.eid, this.d.pi, ...a);
    if (r && r.ok) { Object.assign(this.d, r); toast('Opération effectuée', 'ok'); this.render(); }
  }
  onA(el) {
    const a = el.dataset.a, v = el.dataset.v;
    if (a === 'amt') { this.amount = v === 'bank' ? this.d.bank : v === 'cash' ? this.d.money : Number(v); return this.render(); }
    if (a === 'withdraw') return this.run('bank:withdraw', this.amount);
    if (a === 'deposit') return this.run('bank:deposit', this.amount);
    if (a === 'transfer') return this.run('bank:transfer', this.amount, this.target);
  }
})();

const Panels = { pvp: PvpPanel, chase: ChasePanel, carlot: CarlotPanel, locksmith: LocksmithPanel, carwash: CarwashPanel, driving: DrivingPanel, bank: BankPanel, garage: GaragePanel, impound: ImpoundPanel, rental: RentalPanel, fuel: FuelPanel, lab: LabPanel, dealer: DealerPanel, launder: LaunderPanel };
Object.values(Panels).forEach(p => { const open = p.open.bind(p); p.open = d => { window.__img = d.imagePath === undefined ? window.__img : d.imagePath; window.__cur = d.currency || window.__cur; open(d); }; });

/* ════════════════════════════ BUILDER (admin) ════════════════════════════ */
const ACTION_LABEL = { create: 'Création', save: 'Modification', delete: 'Suppression', duplicate: 'Duplication', toggle: 'Statut', take: 'Sortie garage', store: 'Rangement', release: 'Fourrière', seize: 'Saisie',
  rent: 'Location', return: 'Retour', fleet: 'Flotte', fuel: 'Plein', jerrycan: 'Jerricane', harvest: 'Récolte', process: 'Fabrication', sell: 'Vente', launder: 'Blanchiment',
  rob_start: 'Braquage lancé', rob_loot: 'Butin', rob_end: 'Braquage terminé' };
const STAT_LABEL = { kills: 'Kills', matches: 'Parties jouées', listed: 'Annonces déposées', sold: 'Véhicules vendus', uses: 'Utilisations', keys: 'Clés faites', washes: 'Lavages effectués', exams: 'Examens passés', passed: 'Permis délivrés', deposits: 'Total déposé', withdrawn: 'Total retiré', transfers: 'Total viré', revenue: 'Revenus générés', rentals: 'Locations', liters: 'Litres vendus', tank: 'Cuve (L)', released: 'Véhicules rendus', seized: 'Véhicules saisis', harvested: 'Unités récoltées',
  crafted: 'Lots fabriqués', sold: 'Unités vendues', laundered: 'Argent blanchi', attempts: 'Tentatives de braquage' };
const SWATCHES = [[239, 68, 68], [249, 115, 22], [245, 158, 11], [34, 197, 94], [20, 184, 166], [59, 130, 246], [99, 102, 241], [168, 85, 247], [236, 72, 153], [244, 244, 245]];

const KIND = {
  main: { label: 'Point', icon: 'pin' }, pump: { label: 'Pompe', icon: 'fuel' },
  lobby: { label: 'PNJ d\'accueil (ouvre le menu)', icon: 'user' }, zone: { label: 'Zone PVP (position = centre)', icon: 'target' }, map: { label: 'Carte (départs fugitif / poursuivants)', icon: 'map' },
  lot: { label: 'Bureau des annonces', icon: 'user' }, slot: { label: 'Place d\'exposition (véhicule en vente)', icon: 'car' },
  lock: { label: 'Porte verrouillable', icon: 'lock' },
  shop: { label: 'Atelier de serrurier', icon: 'key' },
  wash: { label: 'Baie de lavage', icon: 'drop' },
  desk: { label: 'Accueil (inscriptions)', icon: 'user' }, spawn: { label: 'Départ du véhicule d\'examen', icon: 'car' }, checkpoint: { label: 'Point de passage (parcours)', icon: 'pin' },
  counter: { label: 'Guichet (agent)', icon: 'user' }, atm: { label: 'Distributeur (ATM)', icon: 'card' },
  harvest: { label: 'Récolte', icon: 'leaf' }, process: { label: 'Laboratoire / traitement', icon: 'flask' }, sell: { label: 'Vente (dealer)', icon: 'dollar' },
  launder: { label: 'Blanchiment', icon: 'card' }, door: { label: 'Porte (entrée / sortie)', icon: 'lock' },
  clerk: { label: 'Vendeur (cible « en joue »)', icon: 'user' }, start: { label: 'Point de départ', icon: 'pin' }, register: { label: 'Caisse', icon: 'cart' },
  safe: { label: 'Coffre', icon: 'lock' }, vault: { label: 'Coffre-fort', icon: 'shield' }, loot: { label: 'Butin (vitrines…)', icon: 'gift' }, guard: { label: 'Garde armé', icon: 'target' },
};
const KIND_ORDER = { drug: ['harvest', 'process', 'sell', 'launder', 'door'], robbery: ['clerk', 'start', 'register', 'safe', 'vault', 'loot', 'guard'], garage: ['main'], impound: ['main'], rental: ['main'], fuel: ['pump'], bank: ['counter', 'atm'], driving: ['desk', 'spawn', 'checkpoint'], carwash: ['wash'], locksmith: ['shop'], doorlock: ['lock'], carlot: ['lot', 'slot'], chase: ['lobby', 'map'], pvp: ['lobby', 'zone'] };
const POINT_WORD = { garage: 'garage', impound: 'fourrière', rental: 'agence', fuel: 'pompe', bank: 'point', driving: 'point', carwash: 'baie', locksmith: 'atelier', doorlock: 'porte', carlot: 'point', chase: 'point', pvp: 'zone', drug: 'point', robbery: 'cible' };
const PED_KINDS = new Set(['main', 'pump', 'counter', 'desk', 'wash', 'shop', 'lot', 'lobby', 'harvest', 'process', 'sell', 'launder', 'door', 'clerk']);
const NO_BLIP = new Set(['map', 'slot', 'spawn', 'checkpoint', 'register', 'safe', 'vault', 'loot', 'guard']);
const NO_MARKER = new Set(['zone', 'map', 'clerk', 'guard', 'spawn', 'checkpoint']);
const TARGET_KINDS = new Set(['register', 'safe', 'vault', 'loot']);

const PED0 = () => ({ enabled: false, model: '', scenario: 'WORLD_HUMAN_STAND_IMPATIENT' });
const ACC0 = () => ({ jobs: {}, item: '' });
const TOOL0 = () => ({ item: '', consume: false });
const NEWROW = {
  stack: () => ({ item: '', count: 1 }),
  sellitem: () => ({ item: '', min: 50, max: 100 }),
  loot: () => ({ item: '', min: 1, max: 1, chance: 100 }),
  fleet: () => ({ model: '', label: '', minGrade: 0, price: 0, deposit: 0 }),
  pweapon: () => ({ name: '', ammo: 250 }),
  cvehicle: () => ({ model: '', label: '', category: 'Sportive', speed: 70, accel: 70, handling: 70 }),
  program: () => ({ label: 'Lavage', price: 50, seconds: 8 }),
  license: () => ({ id: '', label: 'Nouveau permis', requires: '', theoryPrice: 200, practicalPrice: 500, theory: { enabled: true, count: 10, passPercent: 80, questions: [] }, practical: { enabled: true, model: 'blista', speedLimit: 80, maxFaults: 5 } }),
  question: () => ({ q: '', answers: ['', '', '', ''], correct: 1 }),
  recipe: () => ({ label: 'Nouvelle recette', inputs: [{ item: '', count: 1 }], outputs: [{ item: '', count: 1 }], time: 8, anim: 'repair', failChance: 0, tool: TOOL0() }),
};
const NEWP = {
  main: () => ({ kind: 'main', label: '', blip: true, ped: PED0(), spawns: [] }),
  lobby: () => ({ kind: 'lobby', label: 'Course poursuite', blip: true, ped: { enabled: true, model: 's_m_y_cop_01', scenario: 'WORLD_HUMAN_CLIPBOARD' } }),
  zone: () => ({ kind: 'zone', label: 'Nouvelle zone', blip: true, radius: 60, color: [239, 68, 68], reviveEnabled: true, reviveDelay: 5, giveWeapons: true, removeOnExit: true, infiniteAmmo: false, healOnKill: true, armorOnRespawn: true, killReward: 0, spawnProtection: 3, weapons: [{ name: 'WEAPON_PISTOL', ammo: 250 }], spawns: [] }),
  map: () => ({ kind: 'map', label: 'Nouvelle carte', desc: '', blip: false }),
  lot: () => ({ kind: 'lot', label: 'Bureau des annonces', blip: true, ped: { enabled: true, model: 'a_m_y_business_03', scenario: 'WORLD_HUMAN_CLIPBOARD' } }),
  slot: () => ({ kind: 'slot', label: 'Place', blip: false }),
  lock: () => ({ kind: 'lock', label: 'Porte', blip: false, locked: true, useKey: true, showMarker: false, showText: true, autoLock: 0, access: { jobs: {}, jobs2: {}, item: '', mode: 'any' }, doors: [] }),
  shop: () => ({ kind: 'shop', label: 'Atelier de serrurier', blip: true, ped: { enabled: true, model: 's_m_y_construct_01', scenario: 'WORLD_HUMAN_CLIPBOARD' } }),
  wash: () => ({ kind: 'wash', label: 'Baie de lavage', blip: true, ped: PED0() }),
  desk: () => ({ kind: 'desk', label: 'Accueil', blip: true, ped: { enabled: true, model: 'a_f_y_business_01', scenario: 'WORLD_HUMAN_CLIPBOARD' } }),
  spawn: () => ({ kind: 'spawn', label: 'Départ véhicule d\'examen', blip: false }),
  checkpoint: () => ({ kind: 'checkpoint', label: 'Point de passage', blip: false }),
  counter: () => ({ kind: 'counter', label: 'Guichet', blip: true, ped: { enabled: true, model: 'ig_bankman', scenario: 'WORLD_HUMAN_CLIPBOARD' } }),
  atm: () => ({ kind: 'atm', label: 'Distributeur', blip: false, ped: PED0() }),
  pump: () => ({ kind: 'pump', label: 'Pompe', blip: false, ped: PED0() }),
  harvest: () => ({ kind: 'harvest', label: 'Point de récolte', blip: false, ped: PED0(), access: ACC0(), copsRequired: 0, alertChance: 0, harvest: { item: '', min: 1, max: 3, time: 6, anim: 'harvest', tool: TOOL0(), cooldown: 10, maxUses: 0, regen: 300 } }),
  process: () => ({ kind: 'process', label: 'Laboratoire', blip: false, ped: PED0(), access: ACC0(), copsRequired: 0, alertChance: 0, recipes: [NEWROW.recipe()] }),
  sell: () => ({ kind: 'sell', label: 'Dealer', blip: false, ped: { enabled: true, model: 'g_m_y_mexgoon_01', scenario: 'WORLD_HUMAN_DRUG_DEALER' }, access: ACC0(), copsRequired: 0, alertChance: 5, sell: { currency: 'black_money', maxPerHour: 0, items: [NEWROW.sellitem()] } }),
  launder: () => ({ kind: 'launder', label: 'Blanchiment', blip: false, ped: PED0(), access: ACC0(), copsRequired: 0, alertChance: 0, launder: { rate: 70, min: 500, max: 50000, from: 'black_money', to: 'money', maxPerHour: 0 } }),
  door: () => ({ kind: 'door', label: 'Entrée du laboratoire', blip: false, ped: PED0(), access: ACC0(), copsRequired: 0, alertChance: 0 }),
  clerk: () => ({ kind: 'clerk', label: 'Vendeur', blip: false, ped: { enabled: true, model: 'mp_m_shopkeep_01', scenario: 'WORLD_HUMAN_STAND_IMPATIENT' } }),
  start: () => ({ kind: 'start', label: 'Point de départ', blip: false }),
  guard: () => ({ kind: 'guard', label: 'Garde', blip: false }),
};
['register', 'safe', 'vault', 'loot'].forEach(k => { NEWP[k] = () => ({ kind: k, label: KIND[k].label, blip: false, time: 12, anim: k === 'safe' ? 'safe' : k === 'register' ? 'till' : k === 'vault' ? 'drill' : 'pickup', minigame: false, tool: TOOL0(), cash: { min: 0, max: 0 }, items: [] }); });

const Builder = {
  cat: null, list: [], cur: null, view: 'home', tab: 'general', dirty: false, sel: 0, newType: 'garage', newTpl: null, newLabel: '',
  homeLogs: [], logs: null, missing: [], rows: {}, accentDraft: null, jobSels: {}, jobGrades: {},

  async open() {
    this.cat = await rpc('catalog');
    if (!this.cat || !this.cat.ok) { toast('Accès refusé', 'err'); close(); return; }
    CUR = this.cat.currency || '$'; window.__img = this.cat.imagePath;
    await this.refreshList();
    const l = await rpc('logs', 0);
    this.homeLogs = (l && l.logs) || [];
    this.view = 'home'; this.cur = null; this.dirty = false; this.accentDraft = null;
    this.render(true);
  },

  async refreshList() { const l = await rpc('list'); this.list = Array.isArray(l) ? l : []; },
  type(id) { return (this.cat.types || []).find(t => t.id === id) || { id, label: id, one: id, icon: 'grid', templates: [] }; },
  jobLabel(name) { const j = (this.cat.jobs || []).find(x => x.name === name) || (this.cat.jobs2 || []).find(x => x.name === name); return j ? j.label : name; },
  v(path) { return getPath(this.cur, path); },
  markDirty() { this.dirty = true; const el = document.getElementById('dirty'); if (el) el.classList.remove('hidden'); },

  /* ── Navigation ── */
  async guard() {
    if (!this.dirty) return true;
    const ok = await confirmBox('Modifications non enregistrées', 'Si tu quittes ce module, tes changements seront perdus.', 'Abandonner');
    if (ok) this.dirty = false;
    return ok;
  },

  async go(view, id) {
    if (!(await this.guard())) return;
    this.view = view; this.logs = null;
    if (view === 'edit') {
      const r = await rpc('get', id);
      if (!r || !r.ok) { toast((r && r.error) || 'Module introuvable', 'err'); return; }
      this.cur = clone(r.entity); this.missing = r.missing || []; this.tab = 'general'; this.sel = 0; this.rows = {};
    } else this.cur = null;
    if (view === 'home') { const l = await rpc('logs', 0); this.homeLogs = (l && l.logs) || []; await this.refreshList(); }
    if (view === 'settings') this.accentDraft = clone(this.cat.accent);
    if (view === 'new') { const t = this.type(this.newType); this.newTpl = (t.templates[0] || {}).id; }
    this.render(true);
  },

  /* ── Rendu ── */
  render(resetScroll) {
    const body = $root.querySelector('.body'), nav = $root.querySelector('.nav');
    const sc = body ? body.scrollTop : 0, nsc = nav ? nav.scrollTop : 0;
    let head, html;
    if (this.view === 'edit' && this.cur) { head = this.editHead(); html = this.editBody(); }
    else if (this.view === 'new') { head = { icon: 'plus', title: 'Nouveau module', sub: 'Choisis un type et un modèle : tout reste modifiable ensuite' }; html = this.viewNew(); }
    else if (this.view === 'settings') { head = { icon: 'sliders', title: 'Paramètres', sub: 'Apparence et informations système' }; html = this.viewSettings(); }
    else { head = { icon: 'grid', title: 'World Builder', sub: `${this.list.length} module${this.list.length > 1 ? 's' : ''} · ${this.list.filter(s => s.enabled).length} actif${this.list.filter(s => s.enabled).length > 1 ? 's' : ''}` }; html = this.viewHome(); }
    const active = this.view === 'edit' && this.cur ? 'e:' + this.cur.id : this.view;
    const sections = this.cat.types.map(t => ({ label: t.label, items: this.list.filter(x => x.type === t.id).map(x => ({ id: 'e:' + x.id, icon: t.icon, text: x.label, count: x.enabled ? '' : 'off' })) })).filter(s => s.items.length);
    $root.innerHTML = shellSide({
      profile: { initials: 'WB', title: 'World Builder', sub: `${this.list.length} module(s)` },
      nav: [{ label: 'Général', items: [{ id: 'home', icon: 'grid', text: 'Vue d\'ensemble' }, { id: 'new', icon: 'plus', text: 'Nouveau module' }] }, ...sections, { label: 'Système', items: [{ id: 'settings', icon: 'sliders', text: 'Paramètres' }] }],
      active,
      foot: `<small>Réservé aux administrateurs. Les droits sont vérifiés côté serveur à chaque action.</small>`,
      head: { ...head, acts: head.acts || '' },
      body: html + `<datalist id="weapons-dl">${(this.cat.weapons || []).map(w => `<option value="${esc(w.name)}">${esc(w.label)}</option>`).join('')}</datalist>` + (this.cat.items.length < 6000 ? `<datalist id="items-dl">${this.cat.items.map(i => `<option value="${esc(i.name)}">${esc(i.label)}</option>`).join('')}</datalist>` : ''),
    });
    const nb = $root.querySelector('.body'), nn = $root.querySelector('.nav');
    if (nb && !resetScroll) nb.scrollTop = sc;
    if (nn) nn.scrollTop = nsc;
  },

  /* ── Vue d'ensemble ── */
  viewHome() {
    const L = this.list;
    const cards = this.cat.types.map(t => { const mine = L.filter(x => x.type === t.id); return `<div class="stat click" data-a="newOf" data-v="${t.id}"><div class="eyebrow">${esc(t.label)}</div><div class="v">${mine.length}</div><div class="s">${mine.filter(x => x.enabled).length} actif(s) · <span class="acc">+ créer</span></div></div>`; }).join('');
    const warn = L.filter(x => x.placed < x.points || x.points === 0);
    return `<div class="grid3 stats">${cards}</div>
      ${warn.length ? `<div class="card mt"><div class="card-h"><div class="t">${ic('pin', 17)} À finaliser</div></div>${warn.map(x => `<div class="item click" data-a="nav" data-v="e:${x.id}">${tile(this.type(x.type).icon)}<div class="grow"><b>${esc(x.label)}</b><small>${x.points === 0 ? 'Aucun point configuré' : `${x.points - x.placed} point(s) sans position`}</small></div>${chip('Incomplet', 'warn')}<span class="chev">${ic('chevron', 16)}</span></div>`).join('')}</div>` : ''}
      <div class="card mt"><div class="card-h"><div class="t">${ic('grid', 17)} Tous les modules</div><button class="primary sm" data-a="nav" data-v="new">${ic('plus', 14)} Nouveau</button></div>
        ${L.length ? L.map(x => `<div class="item click" data-a="nav" data-v="e:${x.id}">${tile(this.type(x.type).icon)}<div class="grow"><b>${esc(x.label)}</b><small>${esc(this.type(x.type).one)} · ${x.points} point${x.points > 1 ? 's' : ''}${x.stats.revenue ? ` · ${money(x.stats.revenue)} générés` : ''}</small></div>${chip(x.enabled ? 'Actif' : 'Désactivé', x.enabled ? 'ok' : 'mute')}<span class="chev">${ic('chevron', 16)}</span></div>`).join('')
        : emptyState('grid', 'Aucun module', 'Crée ton premier module : garage, fourrière, location, station essence, drogue, braquage…')}</div>
      <div class="card"><div class="card-h"><div class="t">${ic('list', 17)} Activité récente</div></div>${this.logHtml(this.homeLogs, true)}</div>`;
  },

  logHtml(list, withName) {
    if (!list || !list.length) return `<div class="hint">Aucune activité pour le moment.</div>`;
    return list.map(l => `<div class="logline"><b>${esc(l.player_name || 'système')}</b> · ${esc(ACTION_LABEL[l.action] || l.action)}${withName && l.entity_label ? ` · ${esc(l.entity_label)}` : ''}${l.detail ? ` — ${esc(l.detail)}` : ''} <span style="float:right">${fmtDate(l.t)}</span></div>`).join('');
  },

  /* ── Nouveau module ── */
  viewNew() {
    const t = this.type(this.newType);
    return `<div class="seg wrap">${this.cat.types.map(x => `<button class="${x.id === this.newType ? 'active' : ''}" data-a="newOf" data-v="${x.id}">${ic(x.icon, 15)} ${esc(x.label)}</button>`).join('')}</div>
      <div class="hint" style="margin:-8px 0 16px">${esc(t.sub || '')}</div>
      <div class="card"><div class="card-h"><div class="t">${ic('tag', 17)} Modèle</div></div>
        <div class="grid3">${t.templates.map(x => `<div class="tpl ${x.id === this.newTpl ? 'sel' : ''}" data-a="pickTpl" data-v="${esc(x.id)}">${ic(x.icon || t.icon, 24)}<span>${esc(x.label)}</span><small class="muted">${x.points ? `${x.points} point${x.points > 1 ? 's' : ''} pré-configuré${x.points > 1 ? 's' : ''}` : 'vide'}</small></div>`).join('')}</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('edit', 17)} Nom</div></div>
        <div class="row"><input data-path="__newLabel" placeholder="${esc((t.templates.find(x => x.id === this.newTpl) || {}).label || t.one)}" value="${esc(this.newLabel)}" maxlength="100"><button class="primary" data-a="create">${ic('plus', 16)} Créer</button></div>
        <div class="hint mt-s">Le module est créé <b>désactivé</b> : place ses points (mode placement), ajuste les réglages puis active-le. Les modèles contiennent déjà des réglages réalistes.</div></div>`;
  },

  /* ── Paramètres ── */
  viewSettings() {
    const c = this.accentDraft || this.cat.accent || [239, 68, 68];
    const hex = '#' + c.map(n => Math.round(n).toString(16).padStart(2, '0')).join('');
    return `<div class="card"><div class="card-h"><div class="t">${ic('sliders', 17)} Apparence</div></div>
        <div class="lbl" style="margin-bottom:10px">Couleur d'accentuation (tous les joueurs)</div>
        <div class="row wrap">${SWATCHES.map(s => `<button class="swatch-pick ${s.join() === c.join() ? 'on' : ''}" style="background:rgb(${s.join(',')})" data-a="swatch" data-v="${s.join(',')}"></button>`).join('')}
          <input type="color" data-path="__accent" value="${hex}" style="width:60px"><span class="spacer"></span><button class="primary" data-a="saveAccent">Enregistrer</button></div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('box', 17)} Système</div></div>
        <div class="kv"><span>Inventaire détecté</span><span>${esc(this.cat.inventory === 'ox' ? 'ox_inventory' : 'ESX (inventaire classique)')}</span></div>
        <div class="kv"><span>Items dans le catalogue</span><span>${this.cat.items.length}</span></div>
        <div class="kv"><span>Métiers ESX</span><span>${this.cat.jobs.length}</span></div>
        <div class="kv"><span>Métiers « police » (alertes, comptage)</span><span>${esc((this.cat.policeJobs || []).join(', ') || '—')}</span></div>
        <div class="kv"><span>Modules</span><span>${this.list.length}</span></div></div>`;
  },

  /* ── Édition d'un module ── */
  tabs() {
    const t = this.cur.type, out = [['general', 'Général', 'sliders']];
    if (t === 'robbery') out.push(['rules', 'Règles', 'target']);
    if (t === 'garage') out.push(['vehicles', 'Véhicules', 'car']);
    if (t === 'impound') out.push(['rules', 'Tarifs & droits', 'dollar']);
    if (t === 'rental') out.push(['fleet', 'Flotte', 'key']);
    if (t === 'fuel') out.push(['station', 'Station', 'fuel']);
    if (t === 'bank') out.push(['rules', 'Frais & limites', 'dollar']);
    if (t === 'driving') out.push(['licenses', 'Permis', 'key']);
    if (t === 'carwash') out.push(['programs', 'Programmes', 'drop']);
    if (t === 'locksmith') out.push(['keys', 'Clés', 'key']);
    if (t === 'carlot') out.push(['sale', 'Règles de vente', 'dollar']);
    if (t === 'chase') out.push(['rules', 'Règles & récompenses', 'target'], ['cars', 'Véhicules', 'car']);
    if (t === 'pvp') out.push(['rules', 'Réglages', 'dollar']);
    out.push(['points', t === 'robbery' ? 'Cibles & points' : t === 'drug' ? 'Points' : 'Emplacements', 'pin']);
    if (t !== 'doorlock') out.push(['access', 'Accès', 'users']);   // portes : les accès se règlent sur chaque porte (Emplacements)
    out.push(['stats', 'Stats & journal', 'chart']);
    return out;
  },

  editHead() {
    const c = this.cur, t = this.type(c.type);
    const placed = c.points.filter(p => p.coords && p.coords.x != null).length;
    return { icon: t.icon, title: c.label || t.one, sub: `${t.one} · ${placed}/${c.points.length} point${c.points.length > 1 ? 's' : ''} placé${placed > 1 ? 's' : ''}`,
      acts: `<span id="dirty" class="chip warn ${this.dirty ? '' : 'hidden'}">Non enregistré</span><button class="icon" data-a="dup" title="Dupliquer">${ic('copy', 16)}</button><button class="icon danger" data-a="del" title="Supprimer">${ic('trash', 16)}</button><button class="primary" data-a="save">${ic('check', 16)} Enregistrer</button>` };
  },

  editBody() {
    const tabs = this.tabs();
    if (!tabs.find(x => x[0] === this.tab)) this.tab = 'general';
    const warn = this.missing.length ? `<div class="hint warn" style="margin-bottom:14px">Items introuvables sur ton serveur : <b>${this.missing.map(esc).join(', ')}</b>. Corrige leur nom (ou crée-les dans ton inventaire) pour que ce module fonctionne.</div>` : '';
    const fn = { general: 'tabGeneral', rules: 'tabRules', vehicles: 'tabVehicles', fleet: 'tabFleet', station: 'tabStation', licenses: 'tabLicenses', programs: 'tabPrograms', keys: 'tabKeys', sale: 'tabSale', cars: 'tabCars', points: 'tabPoints', access: 'tabAccess', stats: 'tabStats' }[this.tab];
    return `${warn}<div class="seg wrap">${tabs.map(t => `<button class="${t[0] === this.tab ? 'active' : ''}" data-a="tab" data-v="${t[0]}">${ic(t[2], 15)} ${t[1]}</button>`).join('')}</div>${this[fn]()}`;
  },

  /* ── Briques de formulaire ── */
  fS(label, path, o = {}) { return fld(label, `<input data-path="${path}" maxlength="${o.max || 100}" placeholder="${esc(o.ph || '')}" value="${esc(this.v(path) ?? '')}" ${o.r ? 'data-r="1"' : ''}>`); },
  fN(label, path, o = {}) { return fld(label, `<input type="number" data-path="${path}" data-t="n" step="${o.step || 1}" ${o.min != null ? `min="${o.min}"` : ''} ${o.max != null ? `max="${o.max}"` : ''} value="${esc(this.v(path) ?? '')}">`); },
  fC(label, path, o = {}) { return `<label class="chk"><input type="checkbox" data-path="${path}" ${this.v(path) ? 'checked' : ''} ${o.r ? 'data-r="1"' : ''}> ${label}</label>`; },
  fSel(label, path, opts, o = {}) { const cur = this.v(path); return fld(label, `<select data-path="${path}" ${o.r ? 'data-r="1"' : ''}>${opts.map(x => `<option value="${esc(x[0])}" ${String(x[0]) === String(cur) ? 'selected' : ''}>${esc(x[1])}</option>`).join('')}</select>`); },
  known(name) { return !name || this.cat.items.some(i => i.name === name); },
  fItem(label, path) { const val = this.v(path) || ''; return fld(label + (val && !this.known(val) ? ' <span class="bad">· introuvable</span>' : ''), `<input list="items-dl" data-path="${path}" maxlength="64" placeholder="nom de l'item" value="${esc(val)}" autocomplete="off">`); },
  animSel(label, path) { return this.fSel(label, path, this.cat.animations.map(a => [a.id, a.label])); },
  scenSel(label, path) { return this.fSel(label, path, this.cat.scenarios.map(a => [a.id, a.label])); },

  payChecks(base) { return `<div class="lbl">Moyens de paiement acceptés</div><div class="row wrap" style="gap:18px;margin-top:8px">${this.cat.payments.map(p => this.fC(esc(p.label), `${base}.${p.id}`)).join('')}</div>`; },
  typeChecks(base, hint) { const cur = this.v(base) || []; return `<div class="lbl">${hint}</div><div class="row wrap" style="gap:18px;margin-top:8px">${this.cat.vehicleTypes.map(t => `<label class="chk"><input type="checkbox" data-a="vtype" data-v="${base}|${t.id}" ${cur.includes(t.id) ? 'checked' : ''}> ${esc(t.label)}</label>`).join('')}</div>`; },

  jobsEditor(path, title, src) {
    src = src || this.cat.jobs;
    const obj = this.v(path) || {};
    const chips = Object.entries(obj).map(([j, g]) => `<span class="chip info nodot">${esc(this.jobLabel(j))} · grade ≥ ${g}<button class="chipx" data-a="jobDel" data-v="${path}|${esc(j)}">${ic('x', 11)}</button></span>`).join('') || '<span class="muted sm-t">Aucun métier (ouvert à tous)</span>';
    return `<div class="lbl">${title}</div><div class="row wrap" style="margin:8px 0">${chips}</div>
      <div class="row">${src.length ? `<select data-path="__jobSel:${path}"><option value="">— choisir —</option>${src.map(j => `<option value="${esc(j.name)}" ${j.name === (this.jobSels[path] || '') ? 'selected' : ''}>${esc(j.label)} (${esc(j.name)})</option>`).join('')}</select>` : `<input data-path="__jobSel:${path}" maxlength="40" placeholder="nom du job2 / gang" value="${esc(this.jobSels[path] || '')}">`}
      <input type="number" min="0" style="width:90px" data-path="__jobGrade:${path}" value="${this.jobGrades[path] || 0}" title="Grade minimum"><button data-a="jobAdd" data-v="${path}">${ic('plus', 14)} Ajouter</button></div>`;
  },

  optCoord(label, path, hint) {
    const c = this.v(path);
    if (c && c.x != null) return `<div class="lbl" style="margin-top:12px">${label} <button class="sm" data-a="coordDel" data-v="${path}" style="margin-left:8px">Retirer</button></div>${coordField(path, c, { tp: true })}`;
    return `<div class="row" style="margin-top:12px"><button class="sm" data-a="coordAdd" data-v="${path}">${ic('plus', 14)} ${label}</button><span class="muted sm-t">${hint || ''}</span></div>`;
  },

  spawnsEditor(base, label, warn) {
    const arr = this.v(`${base}.spawns`) || [];
    return `<div class="lbl" style="margin-top:14px">${label || 'Places de sortie des véhicules'} (${arr.length})</div>
      ${arr.map((s, j) => `<div class="cat-row" style="grid-template-columns:1fr 34px"><div>${coordField(`${base}.spawns.${j}`, s, { tp: true })}</div><button class="icon danger" data-a="spawnDel" data-v="${base}|${j}">${ic('trash', 14)}</button></div>`).join('')}
      <button class="sm mt-s" data-a="spawnAdd" data-v="${base}">${ic('plus', 14)} Ajouter une place (ma position)</button>
      ${arr.length ? '' : `<div class="hint warn">${warn || 'Aucune place : les joueurs ne pourront pas sortir de véhicule.'}</div>`}`;
  },

  listEditor(path, cols, add, addLabel) {
    const arr = this.v(path) || [];
    const gt = `grid-template-columns:${cols.map(c => c.w || '1fr').join(' ')} 34px`;
    const cell = (c, row, i) => {
      const p = `${path}.${i}.${c.key}`, val = row[c.key] ?? '';
      if (c.kind === 'item') return `<input list="items-dl" data-path="${p}" maxlength="64" placeholder="${c.ph || 'item'}" value="${esc(val)}" class="${val && !this.known(val) ? 'bad-in' : ''}" autocomplete="off">`;
      if (c.kind === 'weapon') return `<input list="weapons-dl" data-path="${p}" maxlength="40" placeholder="WEAPON_PISTOL" value="${esc(val)}" autocomplete="off">`;
      if (c.kind === 'num') return `<input type="number" data-path="${p}" data-t="n" step="${c.step || 1}" min="${c.min ?? 0}" ${c.max != null ? `max="${c.max}"` : ''} value="${esc(val)}">`;
      if (c.kind === 'model') return `<input data-path="${p}" data-chk="model" maxlength="60" placeholder="${c.ph || 'modèle'}" value="${esc(val)}">`;
      return `<input data-path="${p}" maxlength="60" placeholder="${c.ph || ''}" value="${esc(val)}">`;
    };
    return `<div class="lrow lhead" style="${gt}">${cols.map(c => `<span>${c.label}</span>`).join('')}<span></span></div>
      ${arr.map((row, i) => `<div class="lrow" style="${gt}">${cols.map(c => cell(c, row, i)).join('')}<button class="icon danger" data-a="rowDel" data-v="${path}|${i}">${ic('x', 14)}</button></div>`).join('')}
      <button class="sm mt-s" data-a="rowAdd" data-v="${path}|${add}">${ic('plus', 14)} ${addLabel}</button>`;
  },

  blipCard() {
    return BBMap.blipCard({ base: 'settings.blip', b: this.v('settings.blip') || {}, hint: "Chaque point choisit lui-même s'il affiche un blip (onglet Points)." });
  },

  /* ── Onglet Général ── */
  tabGeneral() {
    const c = this.cur, col = c.settings.color, hex = col ? '#' + col.map(n => Math.round(n).toString(16).padStart(2, '0')).join('') : '#40e0d0';
    return `<div class="card"><div class="card-h"><div class="t">${ic('edit', 17)} Informations</div>${this.fC('Module actif', 'enabled')}</div>
        <div class="grid2">${this.fS('Nom', 'label', { max: 100 })}${this.fS('Note (interne)', 'settings.note', { max: 200 })}</div>
        <div class="hint mt-s">Type : <b>${esc(this.type(c.type).one)}</b>. Un module désactivé est invisible pour les joueurs.</div></div>
      ${this.blipCard()}
      ${this.uiColorCard()}
      ${BBMap.markerCard({ base: 'settings.marker', m: this.v('settings.marker') || {}, typeKey: 'type', colorHtml: fld('Couleur du marker', `<div class="row"><input type="color" data-path="__color" value="${hex}" style="width:60px"><span class="muted sm-t">${col ? 'personnalisée' : 'couleur par défaut'}</span>${col ? '<button class="sm" data-a="colorReset">Réinitialiser</button>' : ''}</div>`) })}`;
  },

  /* ── Couleur des menus (par module) ── */
  uiColorCard() {
    return `<div class="card"><div class="card-h"><div class="t">${ic('sliders', 17)} Couleur des menus</div></div>
      <div class="grid2">${this.colorField('Couleur des menus de ce module (joueurs)', 'settings.uiColor', this.cat.accent || [239, 68, 68])}
      <div class="hint" style="align-self:end">Les menus de ce module (garage, banque, annonces…) s'affichent avec cette couleur. Par défaut : la couleur globale (Paramètres → Apparence).</div></div></div>`;
  },

  /* ── Onglet Accès ── */
  tabAccess() {
    return `<div class="card"><div class="card-h"><div class="t">${ic('users', 17)} Qui voit ce module ?</div></div>
      ${this.jobsEditor('settings.access.jobs', 'Réservé à certains métiers (laisse vide pour tout le monde)')}
      <div class="mt">${this.fItem('Item « clé » requis pour utiliser le module (non consommé)', 'settings.access.item')}</div>
      <div class="hint mt-s">Les admins voient toujours les modules limités par métier. Les droits sont vérifiés côté serveur à chaque action.</div></div>`;
  },

  /* ── Garage : véhicules ── */
  tabVehicles() {
    const job = this.v('settings.mode') === 'job';
    return `<div class="card"><div class="card-h"><div class="t">${ic('car', 17)} Mode du garage</div></div>
        <div class="grid3">${this.fSel('Mode', 'settings.mode', [['owned', 'Véhicules des joueurs'], ['job', 'Flotte de métier (véhicules prêtés)']], { r: 1 })}${this.fN(`Frais de sortie (${CUR})`, 'settings.fee', { min: 0 })}${job ? this.fS('Préfixe de plaque', 'settings.plate', { max: 4 }) : this.fC('Garage « lié » (le véhicule ne ressort que d\'ici)', 'settings.bound')}</div>
        ${job ? '' : `<div class="mt">${this.typeChecks('settings.types', 'Types de véhicules acceptés (aucun coché = tous)')}</div>`}
        <div class="mt">${this.payChecks('settings.payments')}</div>
        <div class="mt">${this.fItem('Compte société crédité (esx_addonaccount, ex : society_police)', 'settings.society')}</div></div>
      ${job ? `<div class="card"><div class="card-h"><div class="t">${ic('shield', 17)} Flotte</div></div>${this.fleetEditor(false)}<div class="hint mt-s">Les véhicules sont prêtés (non enregistrés dans la base). Ils doivent être rangés ici pour disparaître.</div></div>` : ''}`;
  },

  fleetEditor(deposit) {
    const cols = [{ key: 'model', label: 'Modèle (nom spawn)', kind: 'model', w: '1.2fr', ph: 'sultan' }, { key: 'label', label: 'Libellé', w: '1.2fr', ph: 'Nom affiché' }, { key: 'minGrade', label: 'Grade min', kind: 'num', w: '80px' }, { key: 'price', label: `Prix (${CUR})`, kind: 'num', w: '100px' }];
    if (deposit) cols.push({ key: 'deposit', label: `Caution (${CUR})`, kind: 'num', w: '110px' });
    return this.listEditor('settings.fleet', cols, 'fleet', 'Ajouter un véhicule');
  },

  tabFleet() {
    return `<div class="card"><div class="card-h"><div class="t">${ic('key', 17)} Règles de location</div></div>
        <div class="grid3">${this.fN('Durée (minutes, 0 = illimitée)', 'settings.minutes', { min: 0 })}${this.fItem('Compte société crédité', 'settings.society')}<div style="align-self:end">${this.fC('Caution réduite selon les dégâts', 'settings.refundDamage')}</div></div>
        <div class="mt">${this.payChecks('settings.payments')}</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('car', 17)} Véhicules à louer</div></div>${this.fleetEditor(true)}
        <div class="hint mt-s">Prix = coût de la location ; caution = rendue au retour du véhicule au point de retour.</div></div>`;
  },

  tabRules() {
    const c = this.cur;
    if (c.type === 'pvp') return `<div class="card"><div class="card-h"><div class="t">${ic('dollar', 17)} Récompenses</div></div>${this.fSel('Récompense par kill versée sur', 'settings.rewardAccount', [['bank', 'Banque'], ['money', 'Espèces'], ['black_money', 'Argent sale']])}<div class="hint mt-s">Le montant par kill et les armes se règlent <b>par zone</b> (onglet Emplacements). Les scripts d'ambulance doivent ignorer la mort quand <code>LocalPlayer.state.inPvpZone</code> est vrai.</div></div>`;
    if (c.type === 'chase') return `<div class="card"><div class="card-h"><div class="t">${ic('target', 17)} Règle de victoire</div></div>
        <div class="grid3">${this.fN('Distance de contact (m)', 'settings.catchDistance', { min: 2, max: 50 })}${this.fN('Contact continu requis (s)', 'settings.catchTime', { min: 1, max: 30 })}<div style="align-self:end">${this.fC('Les deux joueurs doivent être en véhicule', 'settings.requireVehicle')}</div></div>
        <div class="hint mt-s">Un poursuivant reste « collé » au fugitif (≤ distance) pendant le temps requis : les poursuivants gagnent. Si le temps de la partie est écoulé, le fugitif gagne. Détection 100 % côté serveur.</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('clock', 17)} Déroulement</div></div>
        <div class="grid3">${this.fN('Compte à rebours (s)', 'settings.countdown', { min: 3, max: 15 })}${this.fN('Avance du fugitif (s)', 'settings.headStart', { min: 0, max: 120 })}${this.fN('Poursuivants max par partie', 'settings.maxChasers', { min: 1, max: 10 })}
        ${this.fN('Durée min (minutes)', 'settings.durationMin', { min: 1, max: 60 })}${this.fN('Durée max (minutes)', 'settings.durationMax', { min: 1, max: 120 })}${this.fN('Durée par défaut (minutes)', 'settings.durationDefault', { min: 1, max: 120 })}</div>
        <div class="row wrap mt" style="gap:22px">${this.fC('Véhicules full options (équité)', 'settings.maxPerformance')}${this.fC('Le fugitif voit les poursuivants sur la carte', 'settings.runnerSeesChasers')}${this.fC('Trafic PNJ dans la partie', 'settings.traffic')}</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('dollar', 17)} Mise & gains</div></div>
        <div class="grid3">${this.fSel('Compte débité / crédité', 'settings.rewardAccount', [['bank', 'Banque'], ['money', 'Espèces'], ['black_money', 'Argent sale']])}${this.fN(`Mise d'entrée par joueur (${CUR})`, 'settings.entryFee', { min: 0 })}${this.fN(`Bonus de victoire offert par le serveur (${CUR})`, 'settings.rewardWin', { min: 0 })}</div>
        <div class="hint mt-s">Chaque joueur paie la mise au lancement de la partie. Les gagnants se partagent toutes les mises (ils récupèrent la leur + celle des perdants), les perdants perdent leur mise. Course annulée (joueur sorti du véhicule) : tout le monde est remboursé. Mise à 0 = course gratuite.</div></div>`;
    if (c.type === 'bank') return `<div class="card"><div class="card-h"><div class="t">${ic('dollar', 17)} Frais (en % du montant)</div></div>
        <div class="grid3">${this.fN('Frais de dépôt (%)', 'settings.depositFee', { min: 0, max: 100, step: 0.1 })}${this.fN('Frais de retrait (%)', 'settings.withdrawFee', { min: 0, max: 100, step: 0.1 })}${this.fN('Frais de virement (%)', 'settings.transferFee', { min: 0, max: 100, step: 0.1 })}</div>
        <div class="mt">${this.fItem('Compte société crédité des frais (esx_addonaccount)', 'settings.society')}</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('lock', 17)} Limites</div></div>
        <div class="grid3">${this.fN(`Max par opération (${CUR}, 0 = illimité)`, 'settings.maxTransaction', { min: 0 })}${this.fN(`Retrait max par jour et par joueur (${CUR}, 0 = illimité)`, 'settings.dailyLimit', { min: 0 })}<div style="align-self:end">${this.fC('Dépôt possible aux distributeurs', 'settings.atmDeposit')}</div></div>
        <div class="hint mt-s">Les <b>guichets</b> permettent dépôt, retrait et virement ; les <b>distributeurs</b> permettent retrait et virement (dépôt si activé ci-dessus).</div></div>`;
    if (c.type === 'impound') return `<div class="card"><div class="card-h"><div class="t">${ic('dollar', 17)} Tarifs</div></div>
        <div class="grid3">${this.fN(`Frais de base (${CUR})`, 'settings.fee', { min: 0 })}${this.fN(`Frais par jour (${CUR})`, 'settings.perDay', { min: 0 })}${this.fN(`Plafond (${CUR}, 0 = aucun)`, 'settings.maxFee', { min: 0 })}</div>
        <div class="mt">${this.typeChecks('settings.types', 'Types de véhicules acceptés (aucun coché = tous)')}</div>
        <div class="mt">${this.payChecks('settings.payments')}</div><div class="mt">${this.fItem('Compte société crédité', 'settings.society')}</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('shield', 17)} Qui peut mettre un véhicule en fourrière ?</div></div>${this.jobsEditor('settings.impoundJobs', 'Métiers autorisés (police, dépanneur…)')}
        <div class="hint mt-s">Ces métiers voient un formulaire « Mise en fourrière » (raison + frais) au point de la fourrière. Les frais saisis remplacent le tarif de base.</div></div>`;
    return `<div class="card"><div class="card-h"><div class="t">${ic('target', 17)} Déclenchement & conditions</div></div>
        <div class="grid3">${this.fSel('Déclenchement', 'settings.trigger', [['aim', 'Viser le vendeur avec une arme'], ['interact', 'Touche E sur un point de départ']], { r: 1 })}${this.fN('Policiers requis', 'settings.copsRequired', { min: 0, max: 30 })}${this.fN('Cooldown (secondes)', 'settings.cooldown', { min: 0 })}
        ${this.fN('Durée max (secondes)', 'settings.duration', { min: 30 })}${this.fN('Distance max (m) avant annulation', 'settings.leaveDistance', { min: 5 })}${this.fSel('Butin versé en', 'settings.currency', [['black_money', 'Argent sale'], ['money', 'Espèces'], ['bank', 'Banque']])}</div>
        <div class="row wrap mt" style="gap:22px">${this.fC('Arme obligatoire en main', 'settings.weapon')}${this.fC('Braquage à plusieurs (coopératif)', 'settings.coop')}</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('lock', 17)} Matériel requis</div></div>
        <div class="grid3">${this.fItem('Item requis (vide = aucun)', 'settings.requireItem.item')}${this.fN('Quantité', 'settings.requireItem.count', { min: 1 })}<div style="align-self:end">${this.fC('Consommé au lancement', 'settings.requireItem.consume')}</div></div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('shield', 17)} Alerte police</div></div>
        <div class="grid2">${this.fN('Chance d\'alerte (%)', 'settings.alert.chance', { min: 0, max: 100 })}${this.fS('Message', 'settings.alert.label', { max: 80 })}</div>
        <div class="hint mt-s">Utilise <code>Config.AlertHook</code> pour brancher ps-dispatch / cd_dispatch.</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('target', 17)} Gardes armés</div>${this.fC('Activer', 'settings.guards.enabled')}</div>
        <div class="grid3">${this.fS('Modèle de PNJ', 'settings.guards.model', { max: 60 })}${this.fS('Arme', 'settings.guards.weapon', { max: 40 })}${this.fN('Nombre', 'settings.guards.count', { min: 0, max: 10 })}${this.fN('Précision (%)', 'settings.guards.accuracy', { min: 0, max: 100 })}${this.fN('Vie', 'settings.guards.health', { min: 100, max: 1000 })}</div>
        <div class="hint mt-s">Les gardes apparaissent aux points « Garde armé » (onglet Cibles & points) quand le braquage démarre.</div></div>`;
  },

  tabCars() {
    return `<div class="card"><div class="card-h"><div class="t">${ic('car', 17)} Véhicules sélectionnables (${(this.cur.settings.vehicles || []).length})</div></div>
        ${this.listEditor('settings.vehicles', [{ key: 'model', label: 'Modèle (spawn)', kind: 'model', w: '1.1fr', ph: 'sultan' }, { key: 'label', label: 'Nom affiché', w: '1.3fr', ph: 'Karin Sultan' }, { key: 'category', label: 'Catégorie', w: '1fr', ph: 'Sportive' }, { key: 'speed', label: 'Vitesse', kind: 'num', w: '78px', max: 100 }, { key: 'accel', label: 'Accél.', kind: 'num', w: '78px', max: 100 }, { key: 'handling', label: 'Tenue', kind: 'num', w: '78px', max: 100 }], 'cvehicle', 'Ajouter un véhicule')}
        <div class="hint mt-s">Stats indicatives de 0 à 100 affichées dans le menu. Le serveur valide le modèle choisi.</div></div>`;
  },

  tabSale() {
    return `<div class="card"><div class="card-h"><div class="t">${ic('dollar', 17)} Règles des annonces</div></div>
        <div class="grid3">${this.fN(`Frais de mise en annonce (${CUR})`, 'settings.listingFee', { min: 0 })}${this.fN('Commission sur la vente (%)', 'settings.commission', { min: 0, max: 100, step: 0.5 })}${this.fN('Annonces max par joueur', 'settings.maxListings', { min: 1, max: 30 })}
        ${this.fN('Durée d\'une annonce (jours, 0 = illimitée)', 'settings.durationDays', { min: 0 })}${this.fN(`Prix minimum (${CUR})`, 'settings.minPrice', { min: 0 })}${this.fN(`Prix maximum (${CUR}, 0 = aucun)`, 'settings.maxPrice', { min: 0 })}</div>
        <div class="row wrap mt" style="gap:22px">${this.fC('Afficher la plaque dans l\'annonce', 'settings.showPlate')}</div>
        <div class="mt">${this.payChecks('settings.payments')}</div><div class="mt">${this.fItem('Compte société crédité (frais + commissions)', 'settings.society')}</div>
        <div class="hint mt-s">Le véhicule mis en vente <b>quitte le garage</b> et est exposé sur une <b>place d'exposition</b> (onglet Emplacements : place avec le cap voulu). Une place = une annonce : ajoute autant de places que de véhicules à exposer. À la vente, le véhicule va dans le garage de l'acheteur et le vendeur reçoit le prix moins la commission sur son compte bancaire (même hors ligne). Si l'annonce expire ou est retirée, le véhicule retourne au garage du vendeur.</div></div>`;
  },

  tabKeys() {
    return `<div class="card"><div class="card-h"><div class="t">${ic('key', 17)} Duplicata de clé</div></div>
        <div class="grid3">${this.fN(`Prix d'une clé (${CUR})`, 'settings.price', { min: 0 })}${this.fN('Délai entre deux clés du même véhicule (s)', 'settings.cooldown', { min: 0 })}<div style="align-self:end">${this.fC('Le véhicule doit être près de l\'atelier', 'settings.requireNearby')}${this.fC('Refaire même si le joueur a déjà la clé', 'settings.allowIfHasKey')}</div></div>
        <div class="mt">${this.fItem('Item « clé » donné (ox_inventory : la plaque est ajoutée en métadonnée). Vide = hook Config.GiveKeys / Config.GiveKey', 'settings.keyItem')}</div>
        <div class="mt">${this.payChecks('settings.payments')}</div><div class="mt">${this.fItem('Compte société crédité', 'settings.society')}</div>
        <div class="hint mt-s">Le joueur ne peut refaire que la clé d'un véhicule <b>lui appartenant</b>. Avec « près de l'atelier », le véhicule doit se trouver à moins de 25 m (vérifié côté serveur).</div></div>`;
  },

  tabPrograms() {
    return `<div class="card"><div class="card-h"><div class="t">${ic('drop', 17)} Programmes de lavage</div></div>
        ${this.listEditor('settings.programs', [{ key: 'label', label: 'Nom', w: '1.4fr', ph: 'Lavage rapide' }, { key: 'price', label: `Prix (${CUR})`, kind: 'num', w: '110px' }, { key: 'seconds', label: 'Durée (s)', kind: 'num', w: '100px', min: 3, max: 120 }], 'program', 'Ajouter un programme')}
        <div class="mt">${this.payChecks('settings.payments')}</div><div class="mt">${this.fItem('Compte société crédité', 'settings.society')}</div>
        <div class="hint mt-s">Le joueur entre dans la baie au volant, choisit un programme ; le véhicule est immobilisé pendant le lavage puis nettoyé (saleté et traces).</div></div>`;
  },

  tabLicenses() {
    const lics = this.cur.settings.licenses || [];
    const rows = lics.map((l, i) => this.licenseEditor(`settings.licenses.${i}`, l, i)).join('') || '<div class="hint">Aucun permis : ajoute-en un.</div>';
    return `<div class="card"><div class="card-h"><div class="t">${ic('dollar', 17)} Réglages généraux</div></div>
        <div class="grid3">${this.fN('Délai avant de repasser un examen raté (minutes)', 'settings.cooldown', { min: 0 })}${this.fItem('Compte société crédité', 'settings.society')}</div>
        <div class="mt">${this.payChecks('settings.payments')}</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('key', 17)} Permis (${lics.length})</div><button class="sm" data-a="rowAdd" data-v="settings.licenses|license">${ic('plus', 14)} Permis</button></div>${rows}
        <div class="hint mt-s">Le <b>nom technique</b> est celui d'esx_license (<code>code</code>, <code>drive</code>, <code>drive_bike</code>, <code>drive_truck</code>…). Sans esx_license, les permis sont stockés par ce script. Un permis peut exiger un autre permis (ex : conduite après le code).</div></div>`;
  },

  licenseEditor(path, l, i) {
    const open = this.rows[path] !== false;
    const qs = (l.theory && l.theory.questions) || [];
    return `<div class="rcp"><div class="row"><b class="grow-i">${esc(l.label || l.id || 'Permis ' + (i + 1))}</b><button class="sm" data-a="toggleRow" data-v="${path}">${open ? 'Replier' : 'Déplier'}</button><button class="icon danger" data-a="rowDel" data-v="settings.licenses|${i}">${ic('trash', 14)}</button></div>
      ${open ? `<div class="grid3 mt-s">${this.fS('Nom affiché', `${path}.label`, { max: 60 })}${this.fS('Nom technique (esx_license)', `${path}.id`, { max: 40, ph: 'drive' })}${this.fS('Permis requis avant (optionnel)', `${path}.requires`, { max: 40, ph: 'code' })}</div>
      <div class="card mt"><div class="card-h"><div class="t">${ic('list', 17)} Code de la route (QCM)</div>${this.fC('Activé', `${path}.theory.enabled`, { r: 1 })}</div>
        ${l.theory.enabled ? `<div class="grid3">${this.fN(`Prix (${CUR})`, `${path}.theoryPrice`, { min: 0 })}${this.fN('Questions posées', `${path}.theory.count`, { min: 1, max: 50 })}${this.fN('Réussite (% de bonnes réponses)', `${path}.theory.passPercent`, { min: 1, max: 100 })}</div>
        <div class="lbl" style="margin-top:14px">Banque de questions (${qs.length}) — tirées au hasard, réponses mélangées</div>
        ${qs.map((q, k) => `<div class="cat-row" style="grid-template-columns:1fr"><div class="row"><input data-path="${path}.theory.questions.${k}.q" maxlength="200" placeholder="Question" value="${esc(q.q)}"><button class="icon danger" data-a="rowDel" data-v="${path}.theory.questions|${k}">${ic('x', 14)}</button></div>
          <div class="grid2">${[0, 1, 2, 3].map(a => `<input data-path="${path}.theory.questions.${k}.answers.${a}" maxlength="120" placeholder="Réponse ${a + 1}${a < 2 ? '' : ' (optionnelle)'}" value="${esc((q.answers || [])[a] || '')}">`).join('')}</div>
          <div class="row"><span class="muted sm-t">Bonne réponse :</span><select data-path="${path}.theory.questions.${k}.correct" data-t="n" style="width:140px">${[1, 2, 3, 4].map(n => `<option value="${n}" ${Number(q.correct) === n ? 'selected' : ''}>Réponse ${n}</option>`).join('')}</select></div></div>`).join('')}
        <button class="sm mt-s" data-a="rowAdd" data-v="${path}.theory.questions|question">${ic('plus', 14)} Ajouter une question</button>
        <div class="hint mt-s">Remplis les réponses dans l'ordre (sans trou). Au moins 2 réponses par question.</div>` : '<div class="hint">Pas de code pour ce permis.</div>'}</div>
      <div class="card"><div class="card-h"><div class="t">${ic('car', 17)} Conduite (parcours)</div>${this.fC('Activé', `${path}.practical.enabled`, { r: 1 })}</div>
        ${l.practical.enabled ? `<div class="grid3">${this.fN(`Prix (${CUR})`, `${path}.practicalPrice`, { min: 0 })}${fld('Véhicule d\'examen (nom spawn)', `<input data-path="${path}.practical.model" data-chk="model" maxlength="60" value="${esc(l.practical.model)}" placeholder="blista">`)}${this.fN('Limite de vitesse (km/h)', `${path}.practical.speedLimit`, { min: 20, max: 300 })}${this.fN('Fautes max autorisées', `${path}.practical.maxFaults`, { min: 0, max: 50 })}</div>
        <div class="hint mt-s">Fautes : excès de vitesse (5 s d'écart entre deux fautes) et collisions. Le parcours = points de passage de l'onglet <b>Emplacements</b>, dans l'ordre, depuis le point de départ.</div>` : '<div class="hint">Pas d\'épreuve de conduite : le permis est délivré après le code.</div>'}</div>` : ''}</div>`;
  },

  tabStation() {
    return `<div class="card"><div class="card-h"><div class="t">${ic('fuel', 17)} Carburant</div></div>
        <div class="grid3">${this.fN(`Prix du litre (${CUR})`, 'settings.price', { min: 0, step: 0.1 })}${this.fN('Capacité de la cuve (L, 0 = illimitée)', 'settings.tank', { min: 0 })}${this.fItem('Compte société crédité', 'settings.society')}
        ${this.fN('Réappro. toutes les (minutes, 0 = jamais)', 'settings.restockMinutes', { min: 0 })}${this.fN('Litres ajoutés par réappro.', 'settings.restockLiters', { min: 0 })}</div>
        <div class="mt">${this.payChecks('settings.payments')}</div>
        ${this.cur.stats && this.cur.stats.tank != null ? `<div class="hint mt-s">Niveau actuel de la cuve : <b>${Math.round(this.cur.stats.tank)} L</b></div>` : ''}</div>
      <div class="card"><div class="card-h"><div class="t">${ic('box', 17)} Jerricane</div>${this.fC('Vendre des jerricanes', 'settings.jerrycan.enabled')}</div>
        <div class="grid2">${this.fItem('Item vendu', 'settings.jerrycan.item')}${this.fN(`Prix (${CUR})`, 'settings.jerrycan.price', { min: 0 })}</div></div>`;
  },

  /* ── Stats & journal ── */
  tabStats() {
    const s = this.cur.stats || {}, keys = Object.keys(s).filter(k => STAT_LABEL[k] && k !== 'restockAt');
    return `<div class="card"><div class="card-h"><div class="t">${ic('chart', 17)} Statistiques</div><button class="sm" data-a="resetStats">Réinitialiser</button></div>
        ${keys.length ? keys.map(k => `<div class="kv"><span>${esc(STAT_LABEL[k])}</span><span>${k === 'revenue' ? money(s[k]) : Math.round(s[k])}</span></div>`).join('') : '<div class="hint">Aucune donnée pour le moment.</div>'}</div>
      <div class="card"><div class="card-h"><div class="t">${ic('list', 17)} Journal</div><button class="sm" data-a="loadLogs">${ic('refresh', 14)} Charger</button></div>${this.logs ? this.logHtml(this.logs, false) : '<div class="hint">Clique sur « Charger » pour afficher l\'activité de ce module.</div>'}</div>`;
  },

  /* ── Points ── */
  placementTargets() {
    if (this.view !== 'edit' || !this.cur) return [];
    const t = [], c = this.cur;
    c.points.forEach((p, i) => {
      const nm = p.label || KIND[p.kind || 'main'].label;
      t.push({ root: c, path: `points.${i}.coords`, label: `${nm} — position` });
      if (p.store) t.push({ root: c, path: `points.${i}.store`, label: `${nm} — rangement` });
      if (p.ret) t.push({ root: c, path: `points.${i}.ret`, label: `${nm} — retour` });
      if (p.inside) t.push({ root: c, path: `points.${i}.inside`, label: `${nm} — intérieur` });
      if (p.ped && p.ped.pos) t.push({ root: c, path: `points.${i}.ped.pos`, label: `${nm} — PNJ` });
      (p.spawns || []).forEach((s, j) => t.push({ root: c, path: `points.${i}.spawns.${j}`, label: `${nm} — place ${j + 1}` }));
    });
    return t;
  },

  tabPoints() {
    const c = this.cur, kinds = KIND_ORDER[c.type] || ['main'];
    const single = kinds.length === 1;
    const list = c.points.map((p, i) => { const k = p.kind || 'main', ok = p.coords && p.coords.x != null;
      return `<div class="pt ${i === this.sel ? 'active' : ''}" data-a="selPoint" data-v="${i}">${tile(KIND[k].icon)}<div><b>${esc(p.label || KIND[k].label)}</b><small>${esc(KIND[k].label)}${ok ? '' : ' · non placé'}</small></div></div>`; }).join('');
    const add = single ? `<button class="wide" data-a="addPoint" data-v="${kinds[0]}">${ic('plus', 15)} Ajouter ${POINT_WORD[c.type] === 'agence' ? 'une' : 'un'} ${POINT_WORD[c.type]}</button>`
      : `<div class="lbl" style="margin-bottom:6px">Ajouter</div><div class="addgrid">${kinds.map(k => `<button class="sm" data-a="addPoint" data-v="${k}">${ic(KIND[k].icon, 14)} ${esc(KIND[k].label)}</button>`).join('')}</div>`;
    const left = `<div>${add}<div style="margin-top:12px">${list || '<div class="hint">Aucun point.</div>'}</div>
      <button class="primary wide mt" data-a="placeStart" ${c.points.length ? '' : 'disabled'}>${ic('pin', 16)} Mode placement</button>
      <div class="hint mt-s">Mode placement : marche librement en jeu, <kbd>Entrée</kbd> enregistre ta position pour la cible suivante.</div></div>`;
    if (this.sel >= c.points.length) this.sel = Math.max(0, c.points.length - 1);
    const right = c.points[this.sel] ? this.pointEditor(this.sel) : emptyState('pin', 'Aucun point', 'Ajoute un point pour commencer.');
    return `<div class="pts">${left}<div>${right}</div></div>`;
  },

  pointEditor(i) {
    const c = this.cur, p = c.points[i], k = p.kind || 'main', base = `points.${i}`;
    let h = `<div class="card"><div class="card-h"><div class="t">${ic(KIND[k].icon, 17)} ${esc(KIND[k].label)}</div>${NO_BLIP.has(k) ? '' : this.fC('Blip', `${base}.blip`)}<button class="icon danger" data-a="delPoint" data-v="${i}" title="Supprimer ce point">${ic('trash', 15)}</button></div>
      ${this.fS('Nom', `${base}.label`, { max: 60 })}<div class="lbl" style="margin-top:12px">Position</div>${coordField(`${base}.coords`, p.coords, { tp: true })}`;
    if (c.type === 'garage') h += this.optCoord('Point de rangement séparé', `${base}.store`, 'Par défaut, on range au même endroit') + this.spawnsEditor(base);
    if (c.type === 'impound') h += this.spawnsEditor(base);
    if (c.type === 'rental') h += this.spawnsEditor(base) + this.optCoord('Point de retour séparé', `${base}.ret`, 'Par défaut, on rend au même endroit');
    if (k === 'door') h += this.optCoord('Intérieur (téléportation)', `${base}.inside`, 'Position à l\'intérieur du laboratoire');
    h += '</div>';
    if (k === 'map') h += `<div class="card"><div class="card-h"><div class="t">${ic('map', 17)} Carte</div></div>${this.fS('Description (affichée dans le menu)', `${base}.desc`, { max: 160 })}<div class="hint mt-s">La position ci-dessus identifie la carte. Sans réglage ci-dessous, le fugitif part de cette position (le cap compte) et les poursuivants sont placés automatiquement derrière lui.</div>
      ${this.optCoord('Départ du fugitif (position de la voiture)', `${base}.runner`, 'Place-toi à l\'endroit voulu, orienté dans le sens du départ')}
      ${this.spawnsEditor(base, 'Départs des poursuivants (1 par poursuivant, dans l\'ordre)', 'Aucun point : les poursuivants sont placés automatiquement derrière le fugitif. Sinon, ajoute autant de points que de poursuivants max (ils réutilisent les points s\'il y en a moins).')}</div>`;
    if (c.type === 'drug') h += this.drugAccess(base) + this.drugKind(base, p);
    if (c.type === 'doorlock') h += this.doorCard(base, p);
    if (c.type === 'pvp' && k === 'zone') h += this.zoneCard(base, p);
    if (TARGET_KINDS.has(k)) h += this.targetEditor(base, p);
    if (k === 'clerk' && !(p.ped && p.ped.enabled)) h += `<div class="hint warn" style="margin-bottom:12px">Le vendeur est la cible du braquage « en joue » : coche « Afficher un PNJ » ci-dessous.</div>`;
    if (!NO_MARKER.has(k)) h += this.markerCard(base, p);
    if (PED_KINDS.has(k)) h += this.pedCard(base);
    return h;
  },

  colorField(label, path, def) {
    const c = this.v(path), hex = '#' + (c || def).map(n => Math.round(n).toString(16).padStart(2, '0')).join('');
    return fld(label, `<div class="row"><input type="color" data-path="__pcolor:${path}" value="${hex}" style="width:60px"><span class="muted sm-t">${c ? 'personnalisée' : 'par défaut'}</span>${c ? `<button class="sm" data-a="coordDel" data-v="${path}">Réinitialiser</button>` : ''}</div>`);
  },

  markerCard(base, p) {
    const sec = p.store || p.ret || (p.kind === 'door' && p.inside);
    return `<div class="card"><div class="card-h"><div class="t">${ic('target', 17)} Couleur des markers</div></div><div class="grid2">${this.colorField('Marker principal', `${base}.color`, this.v('settings.color') || [64, 224, 208])}${sec ? this.colorField('Marker secondaire (rangement / retour / sortie)', `${base}.color2`, [255, 140, 60]) : ''}</div>
      <div class="hint mt-s">Par défaut, la couleur générale du module (onglet Général) est utilisée.</div></div>`;
  },

  zoneCard(base, p) {
    return `<div class="card"><div class="card-h"><div class="t">${ic('target', 17)} Zone PVP</div></div>
        <div class="grid3">${this.fN('Rayon (m)', `${base}.radius`, { min: 10, max: 500 })}${this.colorField('Couleur de la zone', `${base}.color`, [34, 197, 94])}${this.fN(`Récompense par kill (${CUR})`, `${base}.killReward`, { min: 0 })}
        ${this.fN('Délai de réapparition (s)', `${base}.reviveDelay`, { min: 0, max: 30 })}${this.fN('Invincibilité après réapparition (s)', `${base}.spawnProtection`, { min: 0, max: 10 })}</div>
        <div class="row wrap mt" style="gap:22px">${this.fC('Revive automatique', `${base}.reviveEnabled`)}${this.fC('Donner les armes à l\'entrée', `${base}.giveWeapons`)}${this.fC('Retirer les armes à la sortie', `${base}.removeOnExit`)}${this.fC('Munitions infinies', `${base}.infiniteAmmo`)}${this.fC('Soigner le tueur', `${base}.healOnKill`)}${this.fC('Gilet à la réapparition', `${base}.armorOnRespawn`)}</div>
        <div class="lbl" style="margin-top:14px">Armes de la zone</div>${this.listEditor(`${base}.weapons`, [{ key: 'name', label: 'Arme', kind: 'weapon', w: '1.6fr' }, { key: 'ammo', label: 'Munitions', kind: 'num', w: '110px', min: 1, max: 9999 }], 'pweapon', 'Ajouter une arme')}
        ${this.spawnsEditor(base, 'Points de réapparition', 'Aucun point : réapparition près du centre de la zone. Conseillé : ajoute 2 à 4 points, debout sur un sol dégagé (bouton ci-dessus).')}
        <div class="hint mt-s">Sans spawn défini, la réapparition se fait près du centre de la zone. Les armes retirées à la sortie sont remplacées par l'inventaire d'origine du joueur.</div></div>`;
  },

  doorCard(base, p) {
    const doors = p.doors || [];
    return `<div class="card"><div class="card-h"><div class="t">${ic('lock', 17)} Portes physiques (${doors.length})</div><button class="sm" data-a="doorPick" data-v="${base}.doors.${doors.length}">${ic('target', 14)} Viser une porte</button></div>
      ${doors.map((d, k) => `<div class="cat-row" style="grid-template-columns:1fr auto auto"><div><b class="mono">modèle ${esc(d.model)}</b><small class="muted" style="display:block">${r2(d.x)}, ${r2(d.y)}, ${r2(d.z)}</small></div><button class="sm" data-a="doorPick" data-v="${base}.doors.${k}">Re-viser</button><button class="icon danger" data-a="rowDel" data-v="${base}.doors|${k}">${ic('x', 14)}</button></div>`).join('') || '<div class="hint warn">Aucune porte : clique sur « Viser une porte » puis regarde la porte en jeu (Entrée pour valider). Ajoute les deux battants d\'une porte double.</div>'}
      <div class="hint mt-s">La position ci-dessus (marker) est l'endroit où l'on verrouille / déverrouille.</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('users', 17)} Qui peut ouvrir ?</div></div>
        ${this.jobsEditor(`${base}.access.jobs`, 'Métiers (job)')}<div class="mt">${this.jobsEditor(`${base}.access.jobs2`, 'Gangs / second métier (job2)', this.cat.jobs2 || [])}</div>
        <div class="mt">${this.fItem('Item clé requis en plus (non consommé)', `${base}.access.item`)}</div>
        <div class="mt">${this.fSel('Si métier ET gang sont remplis', `${base}.access.mode`, [['any', 'Un des deux suffit (métier OU gang)'], ['all', 'Les deux obligatoires (métier ET gang)']])}</div>
        <div class="hint mt-s">Tu peux ne remplir <b>qu'un seul</b> accès (métier seul ou gang seul). Vide partout = tout le monde peut verrouiller / déverrouiller.</div>
        <div class="grid2 mt">${this.fN('Reverrouillage automatique (secondes, 0 = jamais)', `${base}.autoLock`, { min: 0 })}<div style="align-self:end">${this.fC('Verrouillée par défaut', `${base}.locked`)}${this.fC('Ouvrable avec la touche (porte la plus proche)', `${base}.useKey`)}${this.fC('Afficher le marker (point d\'interaction E)', `${base}.showMarker`)}${this.fC('Texte « Appuie sur L… » sur la porte', `${base}.showText`)}</div></div>
        <div class="hint mt-s">La touche (par défaut <kbd>L</kbd>, modifiable dans les paramètres FiveM ou <code>Config.Doors</code>) verrouille / déverrouille la porte à portée, sans passer par le marker. Décoche « Afficher le marker » pour une porte 100 % à la touche (il faut alors cocher « Ouvrable avec la touche »). Les mêmes accès (métier, job2, item clé) sont exigés.</div></div>`;
  },

  pedCard(base) {
    return `<div class="card"><div class="card-h"><div class="t">${ic('user', 17)} PNJ</div>${this.fC('Afficher un PNJ', `${base}.ped.enabled`, { r: 1 })}</div>
      ${this.v(`${base}.ped.enabled`) ? `<div class="grid2">${this.fS('Modèle', `${base}.ped.model`, { max: 60, ph: 's_m_y_valet_01' })}${this.scenSel('Animation', `${base}.ped.scenario`)}</div>
      ${this.optCoord('Position du PNJ séparée', `${base}.ped.pos`, 'Par défaut, à côté du marker')}` : '<div class="hint">Aucun PNJ affiché.</div>'}</div>`;
  },

  drugAccess(base) {
    return `<div class="card"><div class="card-h"><div class="t">${ic('lock', 17)} Conditions</div></div>
      <div class="grid2">${this.fN('Policiers requis (en plus du réglage global)', `${base}.copsRequired`, { min: 0, max: 30 })}${this.fN('Chance d\'alerter la police (%)', `${base}.alertChance`, { min: 0, max: 100 })}</div>
      <div class="mt">${this.fItem('Item « clé » requis (non consommé)', `${base}.access.item`)}</div><div class="mt">${this.jobsEditor(`${base}.access.jobs`, 'Réservé à certains métiers / gangs (vide = tous)')}</div></div>`;
  },

  toolFields(base) { return `${this.fItem('Outil requis (vide = aucun)', `${base}.tool.item`)}<div style="align-self:end">${this.fC('Consommé', `${base}.tool.consume`)}</div>`; },

  drugKind(base, p) {
    const k = p.kind;
    if (k === 'harvest') return `<div class="card"><div class="card-h"><div class="t">${ic('leaf', 17)} Récolte</div></div>
      <div class="grid3">${this.fItem('Item récolté', `${base}.harvest.item`)}${this.fN('Quantité min', `${base}.harvest.min`, { min: 1 })}${this.fN('Quantité max', `${base}.harvest.max`, { min: 1 })}
      ${this.fN('Durée (secondes)', `${base}.harvest.time`, { min: 1 })}${this.animSel('Animation', `${base}.harvest.anim`)}${this.fN('Délai entre deux récoltes (s)', `${base}.harvest.cooldown`, { min: 0 })}
      ${this.fN('Récoltes avant épuisement (0 = ∞)', `${base}.harvest.maxUses`, { min: 0 })}${this.fN('Repousse (secondes)', `${base}.harvest.regen`, { min: 10 })}</div>
      <div class="grid2 mt">${this.toolFields(`${base}.harvest`)}</div></div>`;
    if (k === 'process') return `<div class="card"><div class="card-h"><div class="t">${ic('flask', 17)} Recettes (${(p.recipes || []).length})</div><button class="sm" data-a="rowAdd" data-v="${base}.recipes|recipe">${ic('plus', 14)} Recette</button></div>
      ${(p.recipes || []).map((r, j) => this.recipeEditor(`${base}.recipes.${j}`, r, j)).join('') || '<div class="hint">Aucune recette.</div>'}</div>`;
    if (k === 'sell') return `<div class="card"><div class="card-h"><div class="t">${ic('dollar', 17)} Achats du dealer</div></div>
      <div class="grid2">${this.fSel('Paiement', `${base}.sell.currency`, [['black_money', 'Argent sale'], ['money', 'Espèces'], ['bank', 'Banque']])}${this.fN('Limite par joueur et par heure (0 = aucune)', `${base}.sell.maxPerHour`, { min: 0 })}</div>
      <div class="mt">${this.listEditor(`${base}.sell.items`, [{ key: 'item', label: 'Item acheté', kind: 'item', w: '1.5fr' }, { key: 'min', label: 'Prix min', kind: 'num', w: '110px' }, { key: 'max', label: 'Prix max', kind: 'num', w: '110px' }], 'sellitem', 'Ajouter un item')}</div>
      <div class="hint mt-s">Le prix unitaire est tiré au hasard entre min et max à chaque vente.</div></div>`;
    if (k === 'launder') return `<div class="card"><div class="card-h"><div class="t">${ic('card', 17)} Blanchiment</div></div>
      <div class="grid3">${this.fN('Taux reversé (%)', `${base}.launder.rate`, { min: 1, max: 100 })}${this.fN('Montant min', `${base}.launder.min`, { min: 0 })}${this.fN('Montant max (0 = aucun)', `${base}.launder.max`, { min: 0 })}
      ${this.fS('Source (black_money / money / bank / item)', `${base}.launder.from`, { max: 64 })}${this.fSel('Versé en', `${base}.launder.to`, [['money', 'Espèces'], ['bank', 'Banque'], ['black_money', 'Argent sale']])}${this.fN('Limite par heure (0 = aucune)', `${base}.launder.maxPerHour`, { min: 0 })}</div></div>`;
    return '';
  },

  recipeEditor(path, r, j) {
    const open = this.rows[path] !== false;
    return `<div class="rcp"><div class="row"><b class="grow-i">${esc(r.label || 'Recette ' + (j + 1))}</b><button class="sm" data-a="toggleRow" data-v="${path}">${open ? 'Replier' : 'Déplier'}</button><button class="icon danger" data-a="rowDel" data-v="${path.replace(/\.\d+$/, '')}|${j}">${ic('trash', 14)}</button></div>
      ${open ? `<div class="grid3 mt-s">${this.fS('Nom', `${path}.label`, { max: 60 })}${this.fN('Durée par lot (s)', `${path}.time`, { min: 1 })}${this.animSel('Animation', `${path}.anim`)}${this.fN('Chance de raté (%)', `${path}.failChance`, { min: 0, max: 100 })}${this.toolFields(path)}</div>
      <div class="grid2 mt"><div><div class="lbl">Ingrédients</div>${this.listEditor(`${path}.inputs`, [{ key: 'item', label: 'Item', kind: 'item', w: '1.4fr' }, { key: 'count', label: 'Qté', kind: 'num', w: '70px', min: 1 }], 'stack', 'Ingrédient')}</div>
      <div><div class="lbl">Produits</div>${this.listEditor(`${path}.outputs`, [{ key: 'item', label: 'Item', kind: 'item', w: '1.4fr' }, { key: 'count', label: 'Qté', kind: 'num', w: '70px', min: 1 }], 'stack', 'Produit')}</div></div>` : ''}</div>`;
  },

  targetEditor(base, p) {
    return `<div class="card"><div class="card-h"><div class="t">${ic(KIND[p.kind].icon, 17)} Cible du braquage</div></div>
      <div class="grid3">${this.fN('Durée (secondes)', `${base}.time`, { min: 1 })}${this.animSel('Animation', `${base}.anim`)}<div style="align-self:end">${this.fC('Mini-jeu (ox_lib)', `${base}.minigame`)}</div>
      ${this.fN(`Butin min (${CUR})`, `${base}.cash.min`, { min: 0 })}${this.fN(`Butin max (${CUR})`, `${base}.cash.max`, { min: 0 })}</div>
      <div class="grid2 mt">${this.toolFields(base)}</div>
      <div class="lbl" style="margin-top:14px">Items en butin</div>${this.listEditor(`${base}.items`, [{ key: 'item', label: 'Item', kind: 'item', w: '1.5fr' }, { key: 'min', label: 'Min', kind: 'num', w: '70px', min: 1 }, { key: 'max', label: 'Max', kind: 'num', w: '70px', min: 1 }, { key: 'chance', label: 'Chance %', kind: 'num', w: '90px', min: 1, max: 100 }], 'loot', 'Ajouter un item')}</div>`;
  },

  /* ── Actions ── */
  delPath(path) {
    const keys = path.split('.'), last = keys.pop(), parent = keys.length ? getPath(this.cur, keys.join('.')) : this.cur;
    if (parent) delete parent[last];
  },

  async onA(el) {
    const a = el.dataset.a, v = el.dataset.v, c = this.cur;
    switch (a) {
      case 'nav':
        if (v === 'home' || v === 'new' || v === 'settings') return this.go(v);
        if (v.startsWith('e:')) return this.go('edit', Number(v.slice(2)));
        return;
      case 'newOf':
        this.newType = v;
        if (this.view !== 'new') return this.go('new');
        this.newTpl = (this.type(v).templates[0] || {}).id; this.render(); return;
      case 'pickTpl': this.newTpl = v; return this.render();
      case 'create': {
        const r = await rpc('create', this.newType, this.newTpl, this.newLabel);
        if (!r || !r.ok) return toast((r && r.error) || 'Création impossible', 'err');
        await this.refreshList();
        this.cur = clone(r.entity); this.missing = r.missing || []; this.view = 'edit'; this.tab = 'points'; this.sel = 0; this.dirty = false; this.newLabel = ''; this.rows = {};
        toast('Module créé : place ses points puis active-le', 'ok');
        return this.render(true);
      }
      case 'tab': this.tab = v; return this.render(true);
      case 'save': {
        for (const [path, sel] of Object.entries(this.jobSels)) {
          const o = sel && getPath(c, path);
          if (sel && o && typeof o === 'object' && !(sel in o) && /\.(jobs2?|access)/.test(path) && this.pendingJobs !== sel + path)
            { this.pendingJobs = sel + path; return toast(`« ${sel} » est choisi mais pas ajouté : clique sur « Ajouter » (ou ré-enregistre pour ignorer)`, 'err'); }
        }
        const r = await rpc('save', { id: c.id, label: c.label, enabled: c.enabled, settings: c.settings, points: c.points });
        if (!r || !r.ok) return toast((r && r.error) || 'Enregistrement impossible', 'err');
        this.cur = clone(r.entity); this.missing = r.missing || []; this.dirty = false;
        await this.refreshList(); this.render();
        return toast(this.missing.length ? 'Enregistré (items introuvables : voir l\'avertissement)' : 'Enregistré', this.missing.length ? '' : 'ok');
      }
      case 'del': {
        if (!(await confirmBox('Supprimer ce module ?', `« ${c.label} » sera supprimé définitivement.`, 'Supprimer'))) return;
        const r = await rpc('delete', c.id);
        if (!r || !r.ok) return toast((r && r.error) || 'Suppression impossible', 'err');
        this.dirty = false; toast('Module supprimé', 'ok'); return this.go('home');
      }
      case 'dup': {
        if (this.dirty && !(await confirmBox('Dupliquer la version enregistrée', 'Tes modifications non enregistrées ne seront pas copiées.', 'Dupliquer', false))) return;
        const r = await rpc('duplicate', c.id);
        if (!r || !r.ok) return toast((r && r.error) || 'Duplication impossible', 'err');
        this.dirty = false; await this.refreshList(); toast('Module dupliqué (désactivé, sans position)', 'ok'); return this.go('edit', r.entity.id);
      }
      case 'selPoint': this.sel = Number(v); return this.render();
      case 'addPoint': {
        if (c.points.length >= this.cat.limits.points) return toast('Nombre maximum de points atteint', 'err');
        c.points.push(NEWP[v]()); this.sel = c.points.length - 1; this.markDirty(); return this.render();
      }
      case 'delPoint': { c.points.splice(Number(v), 1); this.sel = Math.max(0, this.sel - 1); this.markDirty(); return this.render(); }
      case 'coords': await grabCoords(c, v); this.markDirty(); return this.render();
      case 'tp': { const r = await rpc('teleport', getPath(c, v)); if (!r || !r.ok) toast('Téléportation refusée', 'err'); return; }
      case 'coordAdd': { const p = await rpc('getCoords'); setPath(c, v, { x: r2(p.x), y: r2(p.y), z: r2(p.z), h: r2(p.h) }); this.markDirty(); return this.render(); }
      case 'coordDel': this.delPath(v); this.markDirty(); return this.render();
      case 'spawnAdd': {
        const p = await rpc('getCoords');
        const arr = getPath(c, `${v}.spawns`) || [];
        if (arr.length >= 12) return toast('12 places maximum', 'err');
        arr.push({ x: r2(p.x), y: r2(p.y), z: r2(p.z), h: r2(p.h) }); setPath(c, `${v}.spawns`, arr); this.markDirty(); return this.render();
      }
      case 'spawnDel': { const [b, j] = v.split('|'); getPath(c, `${b}.spawns`).splice(Number(j), 1); this.markDirty(); return this.render(); }
      case 'rowAdd': {
        const [path, key] = v.split('|');
        let arr = getPath(c, path); if (!Array.isArray(arr)) { arr = []; setPath(c, path, arr); }
        if (arr.length >= 60) return toast('Limite atteinte', 'err');
        arr.push(NEWROW[key]()); this.markDirty(); return this.render();
      }
      case 'rowDel': { const [path, i] = v.split('|'); getPath(c, path).splice(Number(i), 1); this.markDirty(); return this.render(); }
      case 'toggleRow': this.rows[v] = !(this.rows[v] !== false); return this.render();
      case 'jobAdd': {
        const sel = (this.jobSels[v] || '').trim();
        if (!sel) return toast('Choisis un métier', 'err');
        let o = getPath(c, v); if (!o || typeof o !== 'object' || Array.isArray(o)) { o = {}; setPath(c, v, o); }
        o[sel] = Math.max(0, Number(this.jobGrades[v]) || 0); this.markDirty(); return this.render();
      }
      case 'jobDel': { const [path, j] = v.split('|'); const o = getPath(c, path); if (o) delete o[j]; this.markDirty(); return this.render(); }
      case 'vtype': {
        const [path, id] = v.split('|');
        let arr = getPath(c, path); if (!Array.isArray(arr)) { arr = []; setPath(c, path, arr); }
        const i = arr.indexOf(id);
        if (el.checked && i < 0) arr.push(id); else if (!el.checked && i >= 0) arr.splice(i, 1);
        return this.markDirty();
      }
      case 'doorPick': DoorPick.start(this, v); return;
      case 'bbPreview': { await rpc('previewMarker', Object.assign({}, getPath(this.cur, v), { color: this.cur.settings.color })); toast('Aperçu affiché devant toi (8 s)'); return; }
      case 'colorReset': this.delPath('settings.color'); this.markDirty(); return this.render();
      case 'swatch': this.accentDraft = v.split(',').map(Number); applyTheme(this.accentDraft); return this.render();
      case 'saveAccent': {
        const r = await rpc('settings:save', this.accentDraft);
        if (!r || !r.ok) return toast((r && r.error) || 'Erreur', 'err');
        this.cat.accent = r.accent; window.__theme = r.accent; applyTheme(r.accent); return toast('Couleur enregistrée', 'ok');
      }
      case 'resetStats': {
        if (!(await confirmBox('Réinitialiser les statistiques ?', 'Les compteurs de ce module repartent de zéro.', 'Réinitialiser'))) return;
        const r = await rpc('resetStats', c.id);
        if (r && r.ok) { c.stats = {}; this.render(); }
        return;
      }
      case 'loadLogs': { const r = await rpc('logs', c.id); this.logs = (r && r.logs) || []; return this.render(); }
    }
  },

  /* ── Saisie ── */
  onInput(el, final) {
    const p = el.dataset.path;
    if (!p) return;
    if (p.startsWith('__')) return this.special(p, el, final);
    if (!this.cur) return;
    let val;
    if (el.type === 'checkbox') val = el.checked;
    else if (el.dataset.t === 'n') val = el.value === '' ? null : Number(el.value);
    else val = el.value;
    setPath(this.cur, p, val);
    this.markDirty();
    if (final && el.dataset.r) return this.render();
    if (p === 'label') { const h = $root.querySelector('.head h1'); if (h) h.textContent = val || this.type(this.cur.type).one; }
    if (final && el.dataset.chk === 'model' && val) rpc('checkModel', val).then(r => { if (r && r.valid === false) toast(`Modèle « ${val} » introuvable dans le jeu`, 'err'); });
  },

  special(p, el, final) {
    const v = el.value;
    if (p.startsWith('__pcolor:') && this.cur) {
      const n = parseInt(v.slice(1), 16);
      setPath(this.cur, p.slice(9), [(n >> 16) & 255, (n >> 8) & 255, n & 255]); this.markDirty();
      if (final) this.render();
      return;
    }
    if (p === '__newLabel') this.newLabel = v;
    else if (p.startsWith('__jobSel:')) this.jobSels[p.slice(9)] = v;
    else if (p.startsWith('__jobGrade:')) this.jobGrades[p.slice(11)] = Number(v) || 0;
    else if (p === '__color' && this.cur) {
      const n = parseInt(v.slice(1), 16);
      this.cur.settings.color = [(n >> 16) & 255, (n >> 8) & 255, n & 255]; this.markDirty();
      if (final) this.render();
    } else if (p === '__accent') {
      const n = parseInt(v.slice(1), 16);
      this.accentDraft = [(n >> 16) & 255, (n >> 8) & 255, n & 255]; applyTheme(this.accentDraft);
      if (final) this.render();
    }
  },
};
