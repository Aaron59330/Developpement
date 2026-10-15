'use strict';
/* ════════════════════════════ Utilitaires ════════════════════════════ */
const $root = document.getElementById('root');
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const money = n => Number(n || 0).toLocaleString('fr-FR') + ' $';
const r2 = n => Math.round(n * 100) / 100;
const fmtDate = t => new Date(t * 1000).toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
const initials = n => String(n || '?').split(/\s+/).map(w => w[0]).join('').slice(0, 2).toUpperCase();
const resName = () => (typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_gangbuilder');

async function rpc(name, ...args) {
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort(), 10000);
  try {
    const r = await fetch(`https://${resName()}/rpc`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name, args }), signal: ctl.signal });
    return await r.json();
  } catch (e) {
    return { ok: false, error: ctl.signal.aborted ? `Le serveur ne répond pas à « ${name} » : vérifie que tous les fichiers sont à jour (refresh + restart pickax_core) et regarde la console serveur` : 'Erreur de communication' };
  } finally { clearTimeout(timer); }
}

// Si une ressource doit être redémarrée pour voir le gang (Config.RestartResources), on prévient
function compatToast(c) {
  if (c && c.restarted) toast(`Redémarrage de ${c.resources.join(', ')} dans quelques secondes pour prendre en compte le gang…`);
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
  plus: '<path d="M5 12h14"/><path d="M12 5v14"/>',
  search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
  home: '<path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/>',
  file: '<path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/><path d="M14 2v6h6"/><path d="M16 13H8"/><path d="M16 17H8"/><path d="M10 9H8"/>',
  pin: '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/>',
  trash: '<path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/>',
  car: '<path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"/><circle cx="7" cy="17" r="2"/><path d="M9 17h6"/><circle cx="17" cy="17" r="2"/>',
  shirt: '<path d="M20.38 3.46 16 2a4 4 0 0 1-8 0L3.62 3.46a2 2 0 0 0-1.34 2.23l.58 3.47a1 1 0 0 0 .99.84H6v10c0 1.1.9 2 2 2h8a2 2 0 0 0 2-2V10h2.15a1 1 0 0 0 .99-.84l.58-3.47a2 2 0 0 0-1.34-2.23z"/>',
  box: '<path d="m7.5 4.27 9 5.15"/><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="m3.3 7 8.7 5 8.7-5"/><path d="M12 22V12"/>',
  briefcase: '<path d="M16 20V4a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/><rect width="20" height="14" x="2" y="6" rx="2"/>',
  cart: '<circle cx="8" cy="21" r="1"/><circle cx="19" cy="21" r="1"/><path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12"/>',
  shield: '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>',
  user: '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
  users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
  key: '<path d="m21 2-9.6 9.6"/><circle cx="7.5" cy="15.5" r="5.5"/><path d="m15.5 7.5 3 3L22 7l-3-3"/>',
  lock: '<rect width="18" height="11" x="3" y="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
  wrench: '<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>',
  heart: '<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>',
  dollar: '<path d="M12 2v20"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>',
  grid: '<rect width="7" height="7" x="3" y="3" rx="1"/><rect width="7" height="7" x="14" y="3" rx="1"/><rect width="7" height="7" x="14" y="14" rx="1"/><rect width="7" height="7" x="3" y="14" rx="1"/>',
  check: '<path d="M20 6 9 17l-5-5"/>',
  up: '<path d="m5 12 7-7 7 7"/><path d="M12 19V5"/>',
  down: '<path d="M12 5v14"/><path d="m19 12-7 7-7-7"/>',
  link: '<path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>',
  bell: '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>',
  target: '<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/>',
  edit: '<path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/>',
  clock: '<circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>',
  droplet: '<path d="M12 22a7 7 0 0 0 7-7c0-2-1-3.9-3-5.5s-3.5-4-4-6.5c-.5 2.5-2 4.9-4 6.5C6 11.1 5 13 5 15a7 7 0 0 0 7 7z"/>',
  login: '<path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><path d="m10 17 5-5-5-5"/><path d="M15 12H3"/>',
  tag: '<path d="M12.59 2.59A2 2 0 0 0 11.17 2H4a2 2 0 0 0-2 2v7.17a2 2 0 0 0 .59 1.42l8.7 8.7a2.43 2.43 0 0 0 3.42 0l6.58-6.58a2.43 2.43 0 0 0 0-3.42z"/><circle cx="7.5" cy="7.5" r=".5"/>',
  building: '<rect width="16" height="20" x="4" y="2" rx="2"/><path d="M9 22v-4h6v4"/><path d="M8 6h.01"/><path d="M16 6h.01"/><path d="M12 6h.01"/><path d="M12 10h.01"/><path d="M12 14h.01"/><path d="M16 10h.01"/><path d="M16 14h.01"/><path d="M8 10h.01"/><path d="M8 14h.01"/>',
  tools: '<path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/>',
  list: '<path d="M8 6h13"/><path d="M8 12h13"/><path d="M8 18h13"/><path d="M3 6h.01"/><path d="M3 12h.01"/><path d="M3 18h.01"/>',
  plane: '<path d="M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z"/>',
  ship: '<path d="M2 21c.6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1 .6.5 1.2 1 2.5 1 2.5 0 2.5-2 5-2 1.3 0 1.9.5 2.5 1"/><path d="M19.38 20A11.6 11.6 0 0 0 21 14l-9-4-9 4c0 2.9.94 5.34 2.81 7.76"/><path d="M19 13V7a2 2 0 0 0-2-2H7a2 2 0 0 0-2 2v6"/><path d="M12 10v4"/><path d="M12 2v3"/>',
  bike: '<circle cx="18.5" cy="17.5" r="3.5"/><circle cx="5.5" cy="17.5" r="3.5"/><circle cx="15" cy="5" r="1"/><path d="M12 17.5V14l-3-3 4-3 2 3h2"/>',
  route: '<circle cx="6" cy="19" r="3"/><path d="M9 19h8.5a3.5 3.5 0 0 0 0-7h-11a3.5 3.5 0 0 1 0-7H15"/><circle cx="18" cy="5" r="3"/>',
  landmark: '<path d="M3 22h18"/><path d="M6 18v-7"/><path d="M10 18v-7"/><path d="M14 18v-7"/><path d="M18 18v-7"/><path d="M12 2 3 7h18z"/>',
  percent: '<path d="M19 5 5 19"/><circle cx="6.5" cy="6.5" r="2.5"/><circle cx="17.5" cy="17.5" r="2.5"/>',
  megaphone: '<path d="m3 11 18-5v12L3 14v-3z"/><path d="M11.6 16.8a3 3 0 1 1-5.8-1.6"/>',
  gift: '<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M12 8v13"/><path d="M19 12v7a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-7"/><path d="M7.5 8a2.5 2.5 0 0 1 0-5A4.8 8 0 0 1 12 8a4.8 8 0 0 1 4.5-5 2.5 2.5 0 0 1 0 5"/>',
  utensils: '<path d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2"/><path d="M7 2v20"/><path d="M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7"/>',
  sprout: '<path d="M7 20h10"/><path d="M10 20c5.5-2.5.8-6.4 3-10"/><path d="M9.5 9.4c1.1.8 1.8 2.2 2.3 3.7-2 .4-3.5.4-4.8-.3-1.2-.6-2.3-1.9-3-4.2 2.8-.5 4.4 0 5.5.8z"/><path d="M14.1 6a7 7 0 0 0-1.1 4c1.9-.1 3.3-.6 4.3-1.4 1-1 1.6-2.3 1.7-4.6-2.7.1-4 1-4.9 2z"/>',
  left: '<path d="m15 18-6-6 6-6"/>',
  sliders: '<path d="M4 21v-7"/><path d="M4 10V3"/><path d="M12 21v-9"/><path d="M12 8V3"/><path d="M20 21v-5"/><path d="M20 12V3"/><path d="M2 14h4"/><path d="M10 8h4"/><path d="M18 16h4"/>',
};
Object.assign(P, {
  skull: '<circle cx="9" cy="12" r="1"/><circle cx="15" cy="12" r="1"/><path d="M8 20v2h8v-2"/><path d="m12.5 17-.5-1-.5 1h1z"/><path d="M16 20a2 2 0 0 0 1.56-3.25 8 8 0 1 0-11.12 0A2 2 0 0 0 8 20"/>',
  flag: '<path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><path d="M4 22v-7"/>',
  coins: '<circle cx="8" cy="8" r="6"/><path d="M18.09 10.37A6 6 0 1 1 10.34 18"/><path d="M7 6h1v4"/><path d="m16.71 13.88.7.71-2.82 2.82"/>',
  flask: '<path d="M10 2v7.527a2 2 0 0 1-.211.896L4.72 20.55a1 1 0 0 0 .9 1.45h12.76a1 1 0 0 0 .9-1.45l-5.069-10.127A2 2 0 0 1 14 9.527V2"/><path d="M8.5 2h7"/><path d="M7 16h10"/>',
  leaf: '<path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"/><path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"/>',
  wash: '<path d="M3 6h18"/><path d="M5 6v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V6"/><path d="M9 10v8"/><path d="M15 10v8"/><path d="M9 2h6v4H9z"/>',
  door: '<path d="M13 4h3a2 2 0 0 1 2 2v14"/><path d="M2 20h3"/><path d="M13 20h9"/><path d="M10 12v.01"/><path d="M13 4.562v16.157a1 1 0 0 1-1.242.97L5 20V5.562a2 2 0 0 1 1.515-1.94l4-1A2 2 0 0 1 13 4.561Z"/>',
  crown: '<path d="m2 4 3 12h14l3-12-6 7-4-7-4 7-6-7z"/><path d="M5 20h14"/>',
  eye: '<path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/>',
});
const ic = (n, s) => `<svg class="ic" viewBox="0 0 24 24" ${s ? `style="width:${s}px;height:${s}px"` : ''}>${P[n] || P.grid}</svg>`;

const TYPE_ICON = { street: 'users', mafia: 'crown', biker: 'bike', cartel: 'skull', custom: 'flag' };
const KIND_ICON = { car: 'car', bike: 'bike', aircraft: 'plane', boat: 'ship' };
const POINT_ICON = { garage: 'car', cloakroom: 'shirt', armory: 'target', stash: 'box', boss: 'crown', shop: 'cart', harvest: 'leaf', process: 'flask', sell: 'coins', laundry: 'wash' };
const ACTION_ICON = { handcuff: 'link', escort: 'users', search: 'search', info: 'skull', leave: 'door' };
const ACCOUNT_LABEL = { '': 'Valeur par défaut (config)', dirty: 'Argent sale', money: 'Liquide', bank: 'Banque' };

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
const fld = (label, input) => `<label class="f"><span>${label}</span>${input}</label>`;
const chip = (text, cls = '') => `<span class="chip ${cls}">${esc(text)}</span>`;
const num = (path, label, v, extra = '') => fld(label, `<input type="number" step="any" data-path="${path}" data-t="n" value="${v ?? ''}" ${extra}>`);
const clone = o => (o === undefined ? undefined : JSON.parse(JSON.stringify(o)));
const rgbHex = c => '#' + (c || [255, 255, 255]).map(n => Math.max(0, Math.min(255, Number(n) || 0)).toString(16).padStart(2, '0')).join('');
const hexRgb = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16));
const fmtUntil = sec => { sec = Math.max(0, Math.floor(sec)); const m = Math.floor(sec / 60); return m >= 60 ? `${Math.floor(m / 60)} h ${m % 60} min` : m > 0 ? `${m} min ${sec % 60} s` : `${sec} s`; };

function header({ icon, title, sub, acts = '' }) {
  return `<div class="head">${tile(icon, 'lg')}<div class="ttl"><h1>${esc(title)}</h1>${sub ? `<p>${esc(sub)}</p>` : ''}</div><div class="acts">${acts}${window.GBBack ? `<button class="sm" data-a="back" title="Retour au menu du gang">${ic('left', 14)} Retour</button>` : ''}${closeBtn}</div></div>`;
}

function shellSide({ profile, nav, active, foot = '', head, body }) {
  return `<div class="shell"><aside class="side">
    <div class="profile"><div class="avatar">${esc(profile.initials)}</div><div><b>${esc(profile.title)}</b><small>${esc(profile.sub)}</small></div></div>
    <div class="nav">${nav.map(sec => `${sec.label ? `<div class="nav-label">${esc(sec.label)}</div>` : ''}${sec.items.map(it => `<div class="nav-item ${it.id === active ? 'active' : ''}" data-a="nav" data-v="${esc(it.id)}">${it.color ? `<span class="swatch" style="background:${esc(it.color)}"></span>` : ic(it.icon)}<span class="grow">${esc(it.text)}</span>${it.count != null ? `<span class="count">${it.count}</span>` : ''}</div>`).join('')}`).join('')}</div>
    <div class="side-foot">${foot}</div></aside>
    <section class="main">${header(head)}<div class="body">${body}</div></section></div>`;
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

// Trésorerie en direct : mise à jour sans re-render (on ne perd pas la saisie en cours)
function liveMoney(gang, money, dirty) {
  if ($root.classList.contains('hidden') || money == null) return;
  const cur = Mod === Runtime && Runtime.kind === 'boss' ? Runtime.data : null;
  if (!cur || cur.gang !== gang) return;
  cur.money = money; cur.dirty = dirty;
  document.querySelectorAll('[data-live=money]').forEach(n => { n.innerHTML = Number(money).toLocaleString('fr-FR') + '<small>$</small>'; });
  document.querySelectorAll('[data-live=dirty]').forEach(n => { n.innerHTML = Number(dirty).toLocaleString('fr-FR') + '<small>$</small>'; });
}
setInterval(async () => {
  if ($root.classList.contains('hidden') || typeof Mod === 'undefined' || !Mod) return;
  if (Mod === Runtime && Runtime.kind === 'boss') { const r = await rpc('boss:poll', Runtime.pointId); if (r && r.ok) liveMoney(r.gang, r.money, r.dirty); }
}, 2000);

/* ── Barre de progression (récolte, traitement, blanchiment) & HUD de capture de territoire ── */
const Hud = {
  progress(d) {
    const el = document.getElementById('progress');
    clearTimeout(this.pt);
    if (d.stop) { el.classList.add('hidden'); return; }
    el.innerHTML = `<div class="eyebrow">${esc(d.label)}</div><div class="bar"><i></i></div><small><kbd>X</kbd> pour annuler · reste immobile</small>`;
    el.classList.remove('hidden');
    const bar = el.querySelector('i');
    bar.style.transition = 'none'; bar.style.width = '0%';
    requestAnimationFrame(() => requestAnimationFrame(() => { bar.style.transition = `width ${d.duration}ms linear`; bar.style.width = '100%'; }));
    this.pt = setTimeout(() => el.classList.add('hidden'), d.duration + 800);
  },
  zone(d) {
    const el = document.getElementById('zonehud');
    if (!d) { el.classList.add('hidden'); return; }
    const status = { capturing: ['Capture en cours', 'warn'], contested: ['Zone contestée', 'bad'], protected: [`Protégé encore ${fmtUntil(d.protectedLeft)}`, 'info'], decaying: ['Capture en recul', 'mute'], idle: ['Zone libre d\'attaque', 'mute'], captured: ['Capturé !', 'ok'] }[d.status] || ['', 'mute'];
    el.style.setProperty('--zone', d.color || 'var(--accent)');
    el.innerHTML = `<div class="eyebrow">Territoire</div><b>${esc(d.label)}</b><small>${d.owner ? 'Propriétaire : ' + esc(d.owner) : 'Aucun propriétaire'}${d.attacker ? ' · Attaquant : ' + esc(d.attacker) : ''}</small>
      <div class="bar"><i style="width:${Math.min(100, d.progress || 0)}%"></i></div><div class="row" style="justify-content:space-between;margin-top:8px">${chip(status[0], status[1])}<span class="muted sm-t">${Math.floor(d.progress || 0)} %</span></div>`;
    el.classList.remove('hidden');
    if (d.conflict) {
      const c = d.conflict, m = Math.floor(c.left / 60), sec = String(c.left % 60).padStart(2, '0');
      el.insertAdjacentHTML('beforeend', `<div class="conf"><span>⚔ Affrontement · ${esc(c.ownerLabel)} <b>${c.owner}</b> – <b>${c.intruder}</b> ${esc(c.intruderLabel)}</span><span><b>${m}:${sec}</b></span></div>`);
    }
  },
  objective(d) {
    const el = document.getElementById('objhud');
    if (!d) { el.classList.add('hidden'); return; }
    const t = (n) => `${Math.floor(n / 60)}:${String(n % 60).padStart(2, '0')}`;
    let title, sub, pct = 0, warn = false;
    if (!d.carried) { title = 'Colis au sol'; sub = d.phase === 'deliver' ? 'Prends-le puis livre-le à ton coffre de gang' : `Prends-le puis tiens la zone ${t(d.holdTotal)}`; pct = 0; }
    else if (d.phase === 'hold') {
      pct = 100 - (d.holdLeft / Math.max(1, d.holdTotal)) * 100;
      if (d.me) { title = 'Restez dans la zone'; sub = d.outside > 0 ? `Hors zone ! Retourne vite (${Math.max(0, d.leaveGrace - d.outside)} s)` : `Encore ${t(d.holdLeft)} avec le colis`; warn = d.outside > 0; }
      else { title = `${esc(d.carrierGang)} tient la zone`; sub = `Encore ${t(d.holdLeft)} — élimine le porteur !`; }
    } else {
      pct = 100;
      if (d.me) { title = 'Livrez le colis'; sub = 'Ramène-le à ton coffre de gang (suis le GPS)'; }
      else { title = `${esc(d.carrierGang)} file vers son coffre`; sub = 'Stoppe le porteur avant la livraison !'; warn = true; }
    }
    el.classList.toggle('warn', warn);
    el.innerHTML = `<div class="eyebrow">Mission colis · ${esc(d.label)}</div><b>${title}</b><small>${sub}</small><div class="bar"><i style="width:${Math.min(100, pct)}%"></i></div><div class="row" style="justify-content:space-between;margin-top:8px"><span class="muted sm-t">Fin de mission</span><span class="muted sm-t">${t(d.left || 0)}</span></div>`;
    el.classList.remove('hidden');
  },
};

/* ════════════════════════════ Mode placement ════════════════════════════ */
const Placement = {
  on: false, targets: [], i: 0, mod: null,

  async start(mod) {
    const t = mod && mod.placementTargets ? mod.placementTargets() : [];
    if (!t.length) return toast('Rien à placer ici : ajoute d\'abord un point ou ouvre un formulaire', 'err');
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
    if (t.path === 'gang.blip.coords') t.root.gang.blip.enabled = true;
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


/* ════════════════════════════ Routage global ════════════════════════════ */
let Mod = null;
const close = () => rpc('close');

document.addEventListener('keydown', e => { if (e.key === 'Escape') close(); });
document.addEventListener('click', e => {
  const el = e.target.closest('[data-a]');
  if (!el) return;
  if (el.dataset.a === 'close') return close();
  if (el.dataset.a === 'back') return rpc('openGangMenu');          // retour au menu du gang (F7)
  if (el.dataset.a === 'placeStart') return Placement.start(Mod);
  if (Mod && Mod.onA) Mod.onA(el, e);
});
document.addEventListener('input', e => { if (Mod && Mod.onInput && (e.target.dataset.path || e.target.dataset.sk)) Mod.onInput(e.target, false); });
document.addEventListener('change', e => { if (Mod && Mod.onInput) Mod.onInput(e.target, true); });

window.addEventListener('message', e => {
  const d = e.data;
  if (d.action === 'close') { $root.classList.add('hidden'); $root.innerHTML = ''; if (typeof Tablet !== 'undefined') Tablet.stop(); Placement.hide(); return; }
  if (d.action === 'placementSave') return Placement.save(d.coords);
  if (d.action === 'placementNav') return Placement.nav(d.dir);
  if (d.action === 'placementEnd') return Placement.end();
  if (d.action === 'money') return liveMoney(d.gang, d.money, d.dirty);
  if (d.action === 'theme') return applyTheme(d.accent);
  if (d.action === 'progress') return Hud.progress(d);
  if (d.action === 'zone') return Hud.zone(d.data);
  if (d.action === 'objective') return Hud.objective(d.data);
  if (d.action !== 'open') return;
  if (d.theme) applyTheme(d.theme);
  window.GBBackFromMenu = !!d.back;
  window.GBBack = window.GBBackFromMenu && d.kind !== 'menu';
  const now = Date.now();
  if (!$root.classList.contains('hidden') && d.kind !== 'builder' && d.kind === (Mod && Mod.kind) && now - (window.__lastOpen || 0) < 600) return;   // double ouverture : ignorée
  window.__lastOpen = now;
  if ($root.classList.contains('hidden')) { $root.innerHTML = ''; $root.classList.add('fresh'); setTimeout(() => $root.classList.remove('fresh'), 260); }
  $root.classList.remove('hidden', 'corner');
  if (d.kind !== 'tablet' && typeof Tablet !== 'undefined') Tablet.stop();
  Placement.hide();
  if (d.kind === 'tablet') { Mod = Tablet; Tablet.open(d.data); }
  else if (d.kind === 'builder') { Mod = Builder; Builder.open(); }
  else { Mod = Runtime; Runtime.open(d.kind, d.data, d.pointId); }
});

/* ════════════════════════════ BUILDER ════════════════════════════ */
const Builder = {
  catalog: null, gangs: [], cur: null, tab: 'general', activePoint: 0, loaded: false, draftType: 'street', page: null, S: null, T: null, kind: 'builder',

  async open() {
    if (!this.loaded) {
      this.catalog = await rpc('catalog');
      if (!this.catalog || !this.catalog.gangTypes) { toast('Accès refusé', 'err'); close(); return; }
      this.loaded = true;
    }
    await this.refreshList();
    this.render();
  },

  async refreshList() { const l = await rpc('list'); this.gangs = Array.isArray(l) ? l : []; },

  async select(name) {
    if (this.cur && this.cur.isNew) this.draft = this.cur;
    const r = await rpc('get', name);
    if (!r || !r.gang) return toast('Gang introuvable', 'err');
    r.isNew = false; this.page = null;
    r.grades = r.grades.map(g => ({ name: g.name, label: g.label, salary: g.salary }));
    r.gang.blip = r.gang.blip || {}; r.gang.settings = r.gang.settings || {}; r.gang.settings.actions = r.gang.settings.actions || [];
    r.points.forEach(p => { p.data = p.data || {}; });
    this.cur = r; this.tab = 'general'; this.activePoint = 0;
    this.render();
  },

  newGangDialog() {
    const types = this.catalog.gangTypes;
    const c = document.getElementById('confirm');
    c.innerHTML = `<div class="box" style="width:720px"><h2>Nouveau gang</h2><p>Choisis un modèle : grades, couleur, blip, actions et points suggérés sont pré-remplis, tout reste modifiable.</p>
      <div class="grid4" style="margin-bottom:18px">${Object.entries(types).map(([k, t]) => `<div class="tpl ${k === this.draftType ? 'sel' : ''}" data-type="${k}">${tile(TYPE_ICON[k] || 'flag')}${esc(t.label)}</div>`).join('')}</div>
      <div class="grid2">${fld('Nom interne (job2)', `<input id="ng-name" placeholder="ex: ballas, vagos" maxlength="${this.catalog.nameMax}">`)}${fld('Label affiché', '<input id="ng-label" placeholder="Ballas" maxlength="50">')}</div>
      <div class="grid2 mt">${fld('Trésorerie de départ ($)', '<input id="ng-money" type="number" min="0" value="0">')}<p class="hint" style="align-self:end">Le nom est écrit dans <b>jobs2</b> (${this.catalog.nameMax} caractères max : <b>users.job2</b> est un varchar(20)).</p></div>
      <div class="row" style="margin-top:22px"><span class="spacer"></span><button id="ng-no">Annuler</button><button class="primary" id="ng-yes">Créer le brouillon</button></div></div>`;
    c.classList.remove('hidden');
    const closeDlg = () => { c.classList.add('hidden'); c.innerHTML = ''; };
    document.getElementById('ng-no').onclick = closeDlg;
    c.querySelectorAll('.tpl').forEach(el => el.onclick = () => { this.draftType = el.dataset.type; c.querySelectorAll('.tpl').forEach(t => t.classList.toggle('sel', t === el)); });
    document.getElementById('ng-yes').onclick = () => {
      const name = document.getElementById('ng-name').value.trim().toLowerCase();
      const label = document.getElementById('ng-label').value.trim();
      const re = new RegExp(`^[a-z][a-z0-9_]{1,${this.catalog.nameMax - 1}}$`);
      if (!re.test(name)) return toast(`Nom invalide : minuscules, chiffres, _ (2-${this.catalog.nameMax}), commence par une lettre`, 'err');
      if (!label) return toast('Label obligatoire', 'err');
      if (this.gangs.some(g => g.name === name)) return toast('Ce gang existe déjà', 'err');
      const money = Math.max(0, Number(document.getElementById('ng-money').value) || 0);
      closeDlg();
      this.create(name, label, this.draftType, money);
    };
  },

  create(name, label, type, money) {
    const t = this.catalog.gangTypes[type];
    const last = t.grades.length - 1;
    this.cur = {
      isNew: true,
      gang: {
        name, label, type, color: t.color || '#ef4444', boss_grade: last, start_money: money,
        blip: { enabled: false, label, sprite: t.blip.sprite, color: t.blip.color, scale: t.blip.scale, coords: null },
        settings: { actions: [...t.actions], plate_prefix: name.replace(/[^a-z0-9]/g, '').slice(0, 3).toUpperCase(), motd: '', max_members: -1, recruit_grade: 0, withdraw_grade: last, capture_grade: 0, salary_source: 'default', sell_cut: -1 },
      },
      grades: t.grades.map(g => ({ name: g.name, label: g.label, salary: g.salary })),
      points: [],
    };
    this.tab = 'general'; this.activePoint = 0; this.page = null; this.render();
  },

  render() {
    const dl = `<datalist id="dl-items">${(this.catalog.items || []).map(i => `<option value="${esc(i.name)}">${esc(i.label)}</option>`).join('')}</datalist>
      <datalist id="dl-veh">${(this.catalog.vehicles || []).map(v => `<option value="${esc(v.model)}">${esc(v.name)}</option>`).join('')}</datalist>
      ${['car', 'bike', 'aircraft', 'boat'].map(k => `<datalist id="dl-veh-${k}">${(this.catalog.vehicles || []).filter(v => ((this.catalog.categoryTypes || {})[v.category] || 'car') === k).map(v => `<option value="${esc(v.model)}">${esc(v.name)}</option>`).join('')}</datalist>`).join('')}`;
    const active = this.page === 'settings' ? '__settings' : this.page === 'terr' ? '__terr' : this.cur ? (this.cur.isNew ? '__new' : this.cur.gang.name) : '__home';
    const draft = this.cur && this.cur.isNew ? this.cur : this.draft;
    const nav = [
      { label: 'Général', items: [{ id: '__home', icon: 'grid', text: 'Accueil' }, { id: '__terr', icon: 'flag', text: 'Territoires' }, { id: '__settings', icon: 'sliders', text: 'Paramètres' }] },
      { label: 'Gangs', items: [...(draft ? [{ id: '__new', color: draft.gang.color, text: draft.gang.label + ' (brouillon)' }] : []),
        ...this.gangs.map(g => ({ id: g.name, color: g.color, text: g.label, count: g.online ? `${g.online} en ligne` : null }))] },
    ];
    const foot = `<button class="primary" data-a="newGang">${ic('plus', 16)} Nouveau gang</button><small>Échap pour fermer : ton brouillon reste en mémoire (pratique pour relever des coordonnées).</small>`;
    const profile = { initials: 'GB', title: 'Gang Builder', sub: 'Accès développeur' };
    const view = this.page === 'settings' ? this.renderSettings() : this.page === 'terr' ? this.renderTerr() : (this.cur ? this.renderGang() : this.renderHome());
    $root.innerHTML = dl + shellSide({ profile, nav, active, foot, head: view.head, body: view.body });
  },

  renderHome() {
    const pts = this.gangs.reduce((a, g) => a + g.points, 0), online = this.gangs.reduce((a, g) => a + g.online, 0), members = this.gangs.reduce((a, g) => a + g.members, 0);
    const terr = this.gangs.reduce((a, g) => a + g.territories, 0);
    return {
      head: { icon: 'grid', title: 'Accueil', sub: 'Vue d\'ensemble des gangs créés avec le builder (job2)' },
      body: `<div class="grid4" style="margin-bottom:20px">
        ${[['Gangs', this.gangs.length], ['Membres', members], ['En ligne', online], ['Territoires tenus', terr], ['Points', pts], ['Modèles', Object.keys(this.catalog.gangTypes).length]].slice(0, 4).map(([l, v]) => `<div class="stat"><div class="eyebrow">${l}</div><div class="v">${v}</div></div>`).join('')}</div>
        <div class="eyebrow" style="margin-bottom:12px">Tes gangs</div>
        ${this.gangs.map(g => `<div class="item click" data-a="selectGang" data-v="${esc(g.name)}"><div class="tile" style="background:${esc(g.color)}22;border-color:${esc(g.color)}88;color:${esc(g.color)}">${ic(TYPE_ICON[g.type] || 'flag')}</div><div class="grow"><b>${esc(g.label)}</b><small>${esc(g.name)} · ${g.members} membres (${g.online} en ligne) · ${g.grades} grades · ${g.points} points · ${g.territories} territoires · réputation ${g.rep}</small></div>
          <div style="text-align:right;line-height:1.4"><div class="price">${money(g.money)}</div><small class="muted">${money(g.dirty)} sale</small></div><span class="chev">${ic('chevron', 16)}</span></div>`).join('')
        || emptyState('flag', 'Aucun gang', 'Crée ton premier gang avec le bouton « Nouveau gang ».')}`,
    };
  },

  renderGang() {
    const c = this.cur, g = c.gang;
    const tabs = [['general', 'Général'], ['grades', `Grades · ${c.grades.length}`], ['points', `Points · ${c.points.length}`], ['blip', 'Blip']];
    const acts = (!c.isNew ? `<select id="test-grade" style="width:140px">${c.grades.map((x, i) => `<option value="${i}">${esc(x.label)}</option>`).join('')}</select><button data-a="testGang">Me mettre dans ce gang</button><button data-a="leaveGang">Me retirer</button><button class="danger" data-a="deleteGang">${ic('trash', 15)}</button>` : '')
      + `<button class="primary" data-a="save" style="height:38px">${c.isNew ? 'Créer le gang' : 'Enregistrer'}</button>`;
    return {
      head: { icon: TYPE_ICON[g.type] || 'flag', title: g.label, sub: c.isNew ? 'Brouillon — non enregistré' : `${g.name} · ${(this.catalog.gangTypes[g.type] || {}).label || g.type}`, acts },
      body: `<div class="seg">${tabs.map(([k, l]) => `<button class="${this.tab === k ? 'active' : ''}" data-a="tab" data-v="${k}">${l}</button>`).join('')}</div>${this['tab_' + this.tab]()}`,
    };
  },

  placementTargets() {
    const out = [];
    if (this.page === 'terr' && this.T && this.T.cur) {
      out.push({ root: this, path: 'T.cur.coords', label: `Centre de « ${this.T.cur.label || 'territoire'} »` });
      return out;
    }
    if (!this.cur || this.page) return out;
    out.push({ root: this.cur, path: 'gang.blip.coords', label: 'Blip du gang (active le blip)' });
    this.cur.points.forEach((p, i) => {
      const name = p.label || this.catalog.pointTypes[p.type].label;
      out.push({ root: this.cur, path: `points.${i}.coords`, label: `${name} — marker` });
      if (p.type === 'garage') out.push({ root: this.cur, path: `points.${i}.data.spawn`, label: `${name} — sortie véhicules` });
    });
    return out;
  },

  gradeSelect(path, value) {
    return `<select data-path="${path}" data-t="n">${this.cur.grades.map((g, i) => `<option value="${i}" ${Number(value) === i ? 'selected' : ''}>${i} · ${esc(g.label)}</option>`).join('')}</select>`;
  },

  tab_general() {
    const c = this.cur, g = c.gang, acts = this.catalog.actions, s = g.settings, d = this.catalog.defaults;
    const last = c.grades.length - 1;
    return `<div class="grid2">
      <div class="card"><div class="card-h"><div class="t">${ic('flag', 16)} Identité</div></div>
        <div class="grid2">${fld('Nom interne (job2)', `<input value="${esc(g.name)}" disabled>`)}${fld('Label', `<input data-path="gang.label" value="${esc(g.label)}" maxlength="50">`)}</div>
        <div class="grid3 mt">${fld('Modèle', `<input value="${esc((this.catalog.gangTypes[g.type] || {}).label || g.type)}" disabled>`)}
          ${fld('Couleur du gang', `<input type="color" data-path="gang.color" data-t="s" value="${esc(g.color || '#ef4444')}">`)}
          ${fld('Préfixe plaque (4 max)', `<input data-path="gang.settings.plate_prefix" value="${esc(s.plate_prefix || '')}" maxlength="4">`)}</div>
        <div class="mt">${fld('Message du jour (affiché dans la fiche du gang)', `<input data-path="gang.settings.motd" value="${esc(s.motd || '')}" maxlength="200" placeholder="ex : Réunion ce soir à 21h au garage">`)}</div>
        <p class="hint mt">La couleur sert aux markers du gang, à sa fiche et aux territoires qu'il détient.</p></div>
      <div class="card"><div class="card-h"><div class="t">${ic('users', 16)} Membres & grades</div></div>
        <div class="grid2">${fld('Grade « bureau » (accès gestion du gang)', this.gradeSelect('gang.boss_grade', g.boss_grade))}
          ${fld('Grade donné aux recrues', this.gradeSelect('gang.settings.recruit_grade', s.recruit_grade ?? 0))}
          ${fld('Grade min. pour retirer de la trésorerie', this.gradeSelect('gang.settings.withdraw_grade', s.withdraw_grade ?? last))}
          ${fld('Grade min. pour capturer les territoires', this.gradeSelect('gang.settings.capture_grade', s.capture_grade ?? 0))}</div>
        <div class="grid3 mt">${num('gang.settings.max_members', `Membres max (-1 = défaut : ${d.maxMembers || 'illimité'})`, s.max_members ?? -1, 'min="-1" max="500"')}
          ${fld('Salaires payés par', `<select data-path="gang.settings.salary_source" data-t="s"><option value="default" ${s.salary_source === 'default' || !s.salary_source ? 'selected' : ''}>Valeur par défaut (config)</option><option value="treasury" ${s.salary_source === 'treasury' ? 'selected' : ''}>La trésorerie du gang</option><option value="system" ${s.salary_source === 'system' ? 'selected' : ''}>Le serveur</option></select>`)}
          ${num('gang.settings.sell_cut', `Part des ventes pour le gang (% ; -1 = défaut : ${d.sellCut})`, s.sell_cut ?? -1, 'min="-1" max="100"')}</div>
        <p class="hint mt">Les salaires ne sont versés que si <b>Paramètres → Salaires</b> est activé.</p></div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('list', 16)} Actions du menu gang (F7)</div></div>
        <div style="display:flex;flex-direction:column;gap:13px">${Object.entries(acts).filter(([id]) => id !== 'info' && id !== 'leave' && id !== 'tablet').map(([id, a]) => `<label class="chk"><input type="checkbox" data-a="toggleAction" data-v="${id}" ${s.actions.includes(id) ? 'checked' : ''}> ${esc(a.label)}</label>`).join('')}</div>
        <p class="hint mt"><b>Fiche du gang</b> (infos, membres en ligne, territoires) et <b>Quitter le gang</b> sont toujours proposées. Fouille / escorte : voir <b>Paramètres → Gangs</b> (cible menottée ou non).</p></div>
      <div class="card"><div class="card-h"><div class="t">${ic('lock', 16)} Base de données</div></div><p class="hint">À l'enregistrement, le gang est écrit dans <b>${esc('jobs2')}</b> et <b>${esc('job2_grades')}</b> (les membres sont rattachés via <b>users.job2 / users.job2_grade</b>) et dans les tables <b>gangbuilder_*</b> (trésorerie, points, journal). Aucun job existant n'est touché : un nom déjà pris dans <b>jobs</b>, <b>jobs2</b> ou un autre système de gangs est refusé.</p></div></div>`;
  },

  tab_grades() {
    const g = this.cur.grades;
    return `<div class="card"><table><tr><th style="width:44px">#</th><th>Nom (interne)</th><th>Label</th><th style="width:140px">Salaire</th><th style="width:130px"></th></tr>
      ${g.map((x, i) => `<tr><td class="muted">${i}</td><td><input data-path="grades.${i}.name" value="${esc(x.name)}" maxlength="40"></td><td><input data-path="grades.${i}.label" value="${esc(x.label)}" maxlength="50"></td>
        <td><input type="number" min="0" data-path="grades.${i}.salary" data-t="n" value="${x.salary}"></td>
        <td><div class="row" style="gap:6px"><button class="icon" data-a="gradeUp" data-v="${i}">${ic('up', 15)}</button><button class="icon" data-a="gradeDown" data-v="${i}">${ic('down', 15)}</button><button class="icon danger" data-a="gradeDel" data-v="${i}">${ic('trash', 15)}</button></div></td></tr>`).join('')}</table>
      <div class="row mt"><button data-a="gradeAdd">${ic('plus', 15)} Ajouter un grade</button><span class="hint">L'ordre = niveau du grade (0 = plus bas) · ${this.catalog.maxGrades || 15} grades max · écrits dans <b>job2_grades</b>.</span></div></div>`;
  },

  tab_blip() {
    const b = this.cur.gang.blip;
    const status = b.enabled && !(b.coords && b.coords.x != null) ? chip('⚠ position manquante : le blip ne s\'affichera pas', 'bad nodot') : (b.enabled ? chip('Blip actif', 'ok') : chip('Désactivé', 'mute'));
    return BBMap.blipCard({ base: 'gang.blip', b, title: 'Blip du gang sur la carte (QG)', labelHint: 'Par défaut : nom du gang', hint: status, defSprite: 310,
      extra: `<p class="hint mt">La couleur du blip est aussi celle de la zone sur la carte quand le gang détient un territoire.</p><div class="mt">${coordField('gang.blip.coords', b.coords, { tp: true })}</div>` });
  },


  tab_points() {
    const pts = this.cur.points, types = this.catalog.pointTypes, sel = pts[this.activePoint];
    return `<div class="pts"><div><button data-a="placeStart" style="width:100%;margin-bottom:10px">${ic('pin', 15)} Mode placement</button><div class="addgrid">${Object.entries(types).filter(([, t]) => !t.hidden).map(([k, t]) => `<button class="sm" data-a="addPoint" data-v="${k}">${ic(POINT_ICON[k], 14)} ${esc(t.label)}</button>`).join('')}</div><p class="hint" style="margin-bottom:12px">Le menu se réduit : tu te déplaces librement et tu enregistres chaque position avec <b>Entrée</b>.</p>
      ${pts.map((p, i) => `<div class="pt ${i === this.activePoint ? 'active' : ''}" data-a="selPoint" data-v="${i}">${tile(p.type === 'garage' ? KIND_ICON[(p.data || {}).kind || 'car'] : POINT_ICON[p.type])}<div style="flex:1;min-width:0"><b>${esc(p.label || types[p.type].label)}</b><small>${esc(types[p.type].label)}${p.type === 'garage' ? ' · ' + esc(((this.catalog.garageKinds || {})[(p.data || {}).kind || 'car'] || {}).label || '') : ''}${p.coords && p.coords.x != null ? '' : ' · ⚠ position manquante'}</small></div></div>`).join('') || '<p class="hint">Aucun point. Ajoute un garage, vestiaire, armurerie, coffre, récolte, traitement, vente, blanchiment ou la gestion du gang.</p>'}</div>
      <div>${sel ? this.pointEditor(sel, this.activePoint) : emptyState('pin', 'Aucun point sélectionné', 'Sélectionne ou ajoute un point à gauche.')}</div></div>`;
  },

  accountSelect(path, value, withDefault) {
    const opts = withDefault ? ['', 'dirty', 'money', 'bank'] : ['money', 'dirty', 'bank'];
    return `<select data-path="${path}" data-t="s">${opts.map(o => `<option value="${o}" ${(value || '') === o ? 'selected' : ''}>${ACCOUNT_LABEL[o]}</option>`).join('')}</select>`;
  },

  pointEditor(p, i) {
    const base = `points.${i}`, d = p.data, T = this.catalog.pointTypes[p.type], df = this.catalog.defaults, A = this.catalog.activities;
    const rowDel = (path, k) => `<button class="icon danger" data-a="delRow" data-v="${path}" data-k="${k}">${ic('trash', 15)}</button>`;
    const addBtn = (path, tpl, label) => `<button class="sm" data-a="addRow" data-v="${path}" data-tpl="${tpl}">${ic('plus', 14)} ${label}</button>`;
    const itemRow = (path, extra) => `${fld('Item', `<input list="dl-items" data-path="${path}.name" data-item="${path}" value="${esc(getPath(this.cur, path + '.name') || '')}">`)}${fld('Label', `<input data-path="${path}.label" value="${esc(getPath(this.cur, path + '.label') || '')}">`)}${extra}`;
    let body = '';
    if (p.type === 'garage') {
      const kind = d.kind || 'car', kinds = this.catalog.garageKinds || { car: { label: 'Voitures' } };
      const cats = [...new Set((this.catalog.vehicles || []).filter(v => ((this.catalog.categoryTypes || {})[v.category] || 'car') === kind).map(v => v.category))];
      body = `<div class="card"><div class="card-h"><div class="t">${ic(KIND_ICON[kind], 16)} Type de garage</div></div>
        <div class="grid2">${fld('Type', `<select data-path="${base}.data.kind" data-t="s" data-kindsel="${i}">${Object.entries(kinds).map(([k, v]) => `<option value="${k}" ${kind === k ? 'selected' : ''}>${esc(v.label)}</option>`).join('')}</select>`)}
        <p class="hint" style="align-self:end">Les véhicules proposés et le rangement dépendent du type : un garage de bateaux n'accepte que des bateaux.</p></div></div>
        <div class="card"><div class="card-h"><div class="t">Sortie des véhicules</div></div>${coordField(base + '.data.spawn', d.spawn, { tp: true })}</div>
        <div class="card"><div class="card-h"><div class="t">Véhicules (${(d.vehicles || []).length})</div></div>
          ${cats.length ? `<div class="row" style="margin-bottom:14px"><select id="gk-cat-${i}" style="max-width:260px">${cats.map(c => `<option value="${esc(c)}">${esc(c)}</option>`).join('')}</select><button class="sm" data-a="addCat" data-v="${i}">${ic('plus', 14)} Ajouter toute la catégorie</button></div>` : ''}
          ${(d.vehicles || []).map((v, k) => `<div class="form-row" style="grid-template-columns:1.2fr 1.2fr 1fr 80px auto">
          ${fld('Modèle', `<input list="dl-veh-${kind}" placeholder="ex: faggio" data-path="${base}.data.vehicles.${k}.model" data-veh="${base}.data.vehicles.${k}" value="${esc(v.model)}">`)}
          ${fld('Label', `<input data-path="${base}.data.vehicles.${k}.label" value="${esc(v.label)}">`)}
          ${fld('Grade min.', this.gradeSelect(`${base}.data.vehicles.${k}.min_grade`, v.min_grade))}
          ${fld('Couleur', `<input type="number" min="0" max="160" placeholder="auto" data-path="${base}.data.vehicles.${k}.color" data-t="n" value="${v.color ?? ''}">`)}${rowDel(base + '.data.vehicles', k)}</div>`).join('')}
          ${addBtn(base + '.data.vehicles', 'vehicle', 'Véhicule')}</div>`;
    } else if (p.type === 'cloakroom') {
      body = `<div class="card"><div class="card-h"><div class="t">Tenues</div></div><p class="hint" style="margin-bottom:14px">Change de tenue sur ton perso (builder fermé avec Échap), rouvre le builder puis clique <b>Capturer</b> : la tenue est enregistrée pour le genre de ton perso. Capture aussi avec un perso de l'autre genre pour couvrir les deux.</p>
        ${(d.outfits || []).map((o, k) => `<div class="form-row" style="grid-template-columns:1.3fr 1fr auto auto">
          ${fld('Nom de la tenue', `<input data-path="${base}.data.outfits.${k}.label" value="${esc(o.label)}">`)}${fld('Grade min.', this.gradeSelect(`${base}.data.outfits.${k}.min_grade`, o.min_grade))}
          <button data-a="capture" data-v="${base}.data.outfits.${k}">Capturer ${chip((o.male ? 'H✓' : 'H✗') + ' ' + (o.female ? 'F✓' : 'F✗'), 'nodot mute')}</button>${rowDel(base + '.data.outfits', k)}</div>`).join('')}
        ${addBtn(base + '.data.outfits', 'outfit', 'Tenue')}</div>`;
    } else if (p.type === 'armory') {
      body = `<div class="card"><div class="card-h"><div class="t">Objets / armes disponibles</div></div>${(d.items || []).map((it, k) => `<div class="form-row" style="grid-template-columns:1.2fr 1.2fr 70px 90px 1fr auto">
          ${fld('Item', `<input list="dl-items" placeholder="WEAPON_PISTOL" data-path="${base}.data.items.${k}.name" data-item="${base}.data.items.${k}" value="${esc(it.name)}">`)}
          ${fld('Label', `<input data-path="${base}.data.items.${k}.label" value="${esc(it.label)}">`)}
          ${fld('Qté', `<input type="number" min="1" data-path="${base}.data.items.${k}.count" data-t="n" value="${it.count}">`)}
          ${fld('Munitions', `<input type="number" min="0" data-path="${base}.data.items.${k}.ammo" data-t="n" value="${it.ammo}">`)}
          ${fld('Grade min.', this.gradeSelect(`${base}.data.items.${k}.min_grade`, it.min_grade))}${rowDel(base + '.data.items', k)}</div>`).join('')}
        ${addBtn(base + '.data.items', 'armory', 'Objet')}</div>`;
    } else if (p.type === 'stash') {
      body = `<div class="card"><div class="card-h"><div class="t">Coffre (ox_inventory)</div></div><div class="grid2">${fld('Emplacements', `<input type="number" min="5" max="200" data-path="${base}.data.slots" data-t="n" value="${d.slots ?? 50}">`)}${fld('Poids max (kg)', `<input type="number" min="1" data-path="${base}.data.weight" data-t="n" value="${d.weight ?? 100}">`)}</div>
        <p class="hint mt">Ce coffre est propre au gang : seuls ses membres (job2 + grade du point) peuvent l'ouvrir (id <b>gangbuilder_&lt;id du point&gt;</b>).</p></div>`;
    } else if (p.type === 'shop') {
      body = `<div class="card"><div class="card-h"><div class="t">Marché noir</div></div><div class="grid2"><label class="chk" style="align-self:end;height:38px"><input type="checkbox" data-path="${base}.data.public" data-t="b" ${d.public ? 'checked' : ''}> Public — tout le monde peut acheter</label>${fld('Paiement', this.accountSelect(base + '.data.account', d.account || 'money', false))}</div>
        <p class="hint" style="margin:10px 0 14px">L'argent des achats va dans la trésorerie du gang (propre ou sale selon le paiement).</p>
        ${(d.items || []).map((it, k) => `<div class="form-row" style="grid-template-columns:1.2fr 1.2fr 110px 1fr auto">
          ${itemRow(`${base}.data.items.${k}`, `${fld('Prix ($)', `<input type="number" min="0" data-path="${base}.data.items.${k}.price" data-t="n" value="${it.price}">`)}${fld('Grade min.', this.gradeSelect(`${base}.data.items.${k}.min_grade`, it.min_grade))}`)}${rowDel(base + '.data.items', k)}</div>`).join('')}
        ${addBtn(base + '.data.items', 'shop', 'Article')}</div>`;
    } else if (p.type === 'harvest') {
      body = `<div class="card"><div class="card-h"><div class="t">${ic('leaf', 16)} Récolte</div></div>
        <div class="grid4">${fld('Objet récolté (item)', `<input list="dl-items" placeholder="ex: weed_leaf" data-path="${base}.data.name" data-item="${base}.data" value="${esc(d.name || '')}">`)}
        ${fld('Label', `<input data-path="${base}.data.label" value="${esc(d.label || '')}">`)}
        ${fld('Quantité par récolte', `<input type="number" min="1" max="${A.MaxHarvest}" data-path="${base}.data.count" data-t="n" value="${d.count ?? 1}">`)}
        ${fld('Durée (secondes)', `<input type="number" min="2" max="300" data-path="${base}.data.seconds" data-t="n" value="${d.seconds ?? 8}">`)}</div>
        <div class="grid2 mt">${fld('Délai avant de re-récolter (s, 0 = aucun)', `<input type="number" min="0" data-path="${base}.data.cooldown" data-t="n" value="${d.cooldown ?? 0}">`)}
        ${fld('Outil requis (item, non consommé — optionnel)', `<input list="dl-items" data-path="${base}.data.tool" value="${esc(d.tool || '')}" placeholder="ex: pickaxe">`)}</div>
        <p class="hint mt">Un point = un objet. Place plusieurs points pour plusieurs ingrédients. Le joueur reste sur place pendant la récolte (X pour annuler) ; la durée est contrôlée par le serveur.</p></div>`;
    } else if (p.type === 'process') {
      body = `<div class="card"><div class="card-h"><div class="t">${ic('flask', 16)} Recettes (${(d.recipes || []).length})</div></div>
        <p class="hint" style="margin-bottom:12px">Chaque recette transforme des ingrédients de l'inventaire du joueur en produit fini. La <b>chance de réussite</b> sous 100 % fait perdre les ingrédients en cas d'échec.</p>
        ${(d.recipes || []).map((r, k) => `<div class="card" style="background:rgba(255,255,255,.02);margin-bottom:12px">
          <div class="form-row" style="grid-template-columns:1.2fr 1.2fr 70px 90px 90px 1fr auto">
            ${fld('Produit fini (item)', `<input list="dl-items" placeholder="ex: weed_baggy" data-path="${base}.data.recipes.${k}.output.name" data-item="${base}.data.recipes.${k}.output" value="${esc((r.output || {}).name || '')}">`)}
            ${fld('Nom de la recette', `<input data-path="${base}.data.recipes.${k}.label" value="${esc(r.label || '')}">`)}
            ${fld('Qté', `<input type="number" min="1" max="1000" data-path="${base}.data.recipes.${k}.output.count" data-t="n" value="${(r.output || {}).count ?? 1}">`)}
            ${fld('Durée (s)', `<input type="number" min="2" max="300" data-path="${base}.data.recipes.${k}.seconds" data-t="n" value="${r.seconds ?? 10}">`)}
            ${fld('Réussite (%)', `<input type="number" min="1" max="100" data-path="${base}.data.recipes.${k}.chance" data-t="n" value="${r.chance ?? 100}">`)}
            ${fld('Grade min.', this.gradeSelect(`${base}.data.recipes.${k}.min_grade`, r.min_grade))}${rowDel(base + '.data.recipes', k)}</div>
          <div class="lbl" style="margin:8px 0 6px">Ingrédients</div>
          ${(r.inputs || []).map((inp, m) => `<div class="form-row" style="grid-template-columns:1.2fr 1.2fr 80px auto">
            ${fld('Item', `<input list="dl-items" data-path="${base}.data.recipes.${k}.inputs.${m}.name" data-item="${base}.data.recipes.${k}.inputs.${m}" value="${esc(inp.name)}">`)}
            ${fld('Label', `<input data-path="${base}.data.recipes.${k}.inputs.${m}.label" value="${esc(inp.label)}">`)}
            ${fld('Qté', `<input type="number" min="1" max="1000" data-path="${base}.data.recipes.${k}.inputs.${m}.count" data-t="n" value="${inp.count}">`)}${rowDel(base + '.data.recipes.' + k + '.inputs', m)}</div>`).join('')}
          ${addBtn(base + '.data.recipes.' + k + '.inputs', 'rin', 'Ingrédient')}</div>`).join('')}
        ${addBtn(base + '.data.recipes', 'recipe', 'Recette')}</div>`;
    } else if (p.type === 'sell') {
      body = `<div class="card"><div class="card-h"><div class="t">${ic('coins', 16)} Point de vente</div></div>
        <div class="grid2">${fld('Compte crédité au joueur', this.accountSelect(base + '.data.account', d.account || '', true))}
        ${num(base + '.data.gang_cut', `Part reversée au gang (% ; -1 = défaut)`, d.gang_cut ?? -1, 'min="-1" max="100"')}</div>
        <p class="hint" style="margin:10px 0 14px">Le prix varie de ± ${A.SellPriceVariance} % à chaque vente (Paramètres → Activités). Priorité de la part du gang : <b>ce point</b> › <b>le gang</b> › <b>la config</b> (${df.sellCut} %).</p>
        ${(d.items || []).map((it, k) => `<div class="form-row" style="grid-template-columns:1.2fr 1.2fr 110px 1fr auto">
          ${itemRow(`${base}.data.items.${k}`, `${fld('Prix unitaire ($)', `<input type="number" min="1" data-path="${base}.data.items.${k}.price" data-t="n" value="${it.price}">`)}${fld('Grade min.', this.gradeSelect(`${base}.data.items.${k}.min_grade`, it.min_grade))}`)}${rowDel(base + '.data.items', k)}</div>`).join('')}
        ${addBtn(base + '.data.items', 'sell', 'Produit')}</div>`;
    } else if (p.type === 'laundry') {
      body = `<div class="card"><div class="card-h"><div class="t">${ic('wash', 16)} Blanchiment</div></div>
        <div class="grid3">${num(base + '.data.fee', `Commission (% ; -1 = défaut : ${df.launderFee})`, d.fee ?? -1, 'min="-1" max="100"')}
        ${num(base + '.data.gang_cut', `Part de la commission pour le gang (% ; -1 = défaut : ${df.launderGangCut})`, d.gang_cut ?? -1, 'min="-1" max="100"')}
        ${num(base + '.data.seconds', `Durée (s ; 0 = défaut : ${df.launderSeconds})`, d.seconds ?? 0, 'min="0" max="300"')}</div>
        <div class="grid2 mt">${num(base + '.data.min', `Montant minimum ($ ; 0 = défaut : ${df.launderMin})`, d.min ?? 0, 'min="0"')}${num(base + '.data.max', `Montant maximum ($ ; 0 = défaut : ${df.launderMax})`, d.max ?? 0, 'min="0"')}</div>
        <p class="hint mt">Le joueur convertit son <b>argent sale</b> (${esc((this.catalog.dirty || {}).Name || 'black_money')}) en argent propre, moins la commission. La part de la commission indiquée va dans la trésorerie du gang.</p></div>`;
    } else if (p.type === 'boss') {
      body = `<div class="card"><div class="card-h"><div class="t">Gestion du gang</div></div><p class="hint">Trésorerie (argent propre + sale), recrutement, promotion, exclusion, salaires, journal. Accessible à partir du grade « bureau » défini dans l'onglet Général.</p></div>`;
    }
    return `<div class="card"><div class="card-h"><div class="t">${ic(POINT_ICON[p.type], 16)} ${esc(T.label)}</div><button class="sm danger" data-a="delPoint" data-v="${i}">${ic('trash', 14)} Supprimer</button></div>
      <div class="grid2">${fld('Nom du point', `<input data-path="${base}.label" value="${esc(p.label)}" maxlength="60">`)}${fld('Grade minimum', this.gradeSelect(base + '.min_grade', p.min_grade))}</div>
      <div class="mt"><div class="lbl" style="margin-bottom:6px">Position du marker</div>${coordField(base + '.coords', p.coords, { tp: true })}</div></div>${body}`;
  },

  newRow(tpl) {
    return ({
      vehicle: { model: '', label: '', min_grade: 0 }, outfit: { label: 'Tenue', min_grade: 0, male: null, female: null },
      armory: { name: '', label: '', count: 1, ammo: 0, min_grade: 0 }, shop: { name: '', label: '', price: 10, min_grade: 0 }, sell: { name: '', label: '', price: 10, min_grade: 0 },
      rin: { name: '', label: '', count: 1 },
      recipe: { label: '', seconds: 10, chance: 100, min_grade: 0, output: { name: '', label: '', count: 1 }, inputs: [{ name: '', label: '', count: 1 }] },
    })[tpl];
  },

  newPoint(type) {
    const data = { garage: { kind: 'car', spawn: null, vehicles: [] }, cloakroom: { outfits: [] }, armory: { items: [] }, stash: { slots: 50, weight: 100 }, boss: {}, shop: { public: false, account: 'money', items: [] },
      harvest: { name: '', label: '', count: 1, seconds: 8, cooldown: 0, tool: '' }, process: { recipes: [] }, sell: { account: '', gang_cut: -1, items: [] }, laundry: { fee: -1, gang_cut: -1, min: 0, max: 0, seconds: 0 } }[type];
    return { type, label: this.catalog.pointTypes[type].label, coords: null, min_grade: type === 'boss' ? this.cur.gang.boss_grade : 0, data };
  },

  async save() {
    const c = this.cur;
    const r = await rpc('save', { gang: c.gang, grades: c.grades, points: c.points });
    if (!r || !r.ok) return toast((r && r.error) || 'Erreur', 'err');
    toast(r.created ? 'Gang créé dans job2 (jobs2 / job2_grades)' : 'Gang enregistré', 'ok');
    compatToast(r.compat);
    this.cur = null; this.draft = null;
    await this.refreshList();
    await this.select(r.name);
  },

  async remove() {
    const g = this.cur.gang;
    if (!await confirmBox('Supprimer le gang ?', `« ${g.label} » (${g.name}) sera supprimé de jobs2, job2_grades, de ses points et de sa trésorerie. Les membres retombent sans gang.`, 'Supprimer')) return;
    const r = await rpc('delete', g.name);
    if (!r || !r.ok) return toast((r && r.error) || 'Erreur', 'err');
    if (r.warning) toast(r.warning, 'err'); else toast('Gang supprimé et nettoyé de la base de données', 'ok');
    compatToast(r.compat);
    this.cur = null; await this.refreshList(); this.render();
  },

  fixGrades() {
    const max = this.cur.grades.length - 1, g = this.cur.gang;
    if (g.boss_grade > max) g.boss_grade = max;
    ['recruit_grade', 'withdraw_grade', 'capture_grade'].forEach(k => { if (g.settings[k] > max) g.settings[k] = max; });
    this.cur.points.forEach(p => {
      if (p.min_grade > max) p.min_grade = max;
      (p.data.vehicles || []).concat(p.data.outfits || [], p.data.items || [], p.data.recipes || []).forEach(x => { if (x.min_grade > max) x.min_grade = max; });
    });
  },

  async onA(el) {
    const a = el.dataset.a, v = el.dataset.v, c = this.cur;
    if (this.settingsAction && await this.settingsAction(a, v, el)) return;
    if (this.terrAction && await this.terrAction(a, v, el)) return;
    switch (a) {
      case 'nav':
        if (v === '__settings') { if (c && c.isNew) { this.draft = c; this.cur = null; } return this.openSettings(); }
        if (v === '__terr') { if (c && c.isNew) { this.draft = c; this.cur = null; } return this.openTerr(); }
        if (v === '__home') { if (c && c.isNew) this.draft = c; this.cur = null; this.page = null; await this.refreshList(); return this.render(); }
        if (v === '__new') { this.page = null; if (this.draft) { this.cur = this.draft; this.draft = null; this.tab = 'general'; } return this.render(); }
        return this.select(v);
      case 'newGang': return this.newGangDialog();
      case 'selectGang': return this.select(v);
      case 'tab': this.tab = v; return this.render();
      case 'save': return this.save();
      case 'deleteGang': return this.remove();
      case 'testGang': { const r = await rpc('setMyJob', c.gang.name, Number(document.getElementById('test-grade').value)); return toast(r.ok ? 'Tu es maintenant dans ce gang (job2)' : r.error, r.ok ? 'ok' : 'err'); }
      case 'leaveGang': { const r = await rpc('leaveMyJob'); return toast(r.ok ? 'Tu n\'es plus dans aucun gang' : r.error, r.ok ? 'ok' : 'err'); }
      case 'addCat': {
        const p = c.points[+v], cat = document.getElementById('gk-cat-' + v).value;
        const have = new Set((p.data.vehicles || []).map(x => String(x.model).toLowerCase()));
        const room = Math.max(0, (this.catalog.maxItems || 100) - have.size);
        const add = (this.catalog.vehicles || []).filter(x => x.category === cat && !have.has(String(x.model).toLowerCase())).slice(0, room);
        p.data.vehicles = (p.data.vehicles || []).concat(add.map(x => ({ model: String(x.model).toLowerCase(), label: x.name, min_grade: 0 })));
        toast(add.length ? `${add.length} véhicule(s) ajouté(s)` : 'Rien à ajouter (déjà présents ou limite atteinte)', add.length ? 'ok' : 'err');
        return this.render();
      }
      case 'toggleAction': { const L = c.gang.settings.actions, i = L.indexOf(v); if (i >= 0) L.splice(i, 1); else L.push(v); return; }
      case 'gradeAdd': if (c.grades.length >= (this.catalog.maxGrades || 15)) return toast(`Maximum ${this.catalog.maxGrades || 15} grades`, 'err'); c.grades.push({ name: 'grade' + c.grades.length, label: 'Nouveau grade', salary: 100 }); return this.render();
      case 'gradeDel': if (c.grades.length <= 1) return toast('Il faut au moins un grade', 'err'); c.grades.splice(+v, 1); this.fixGrades(); return this.render();
      case 'gradeUp': if (+v > 0) [c.grades[v - 1], c.grades[v]] = [c.grades[v], c.grades[v - 1]]; return this.render();
      case 'gradeDown': if (+v < c.grades.length - 1) [c.grades[+v + 1], c.grades[v]] = [c.grades[v], c.grades[+v + 1]]; return this.render();
      case 'addPoint': c.points.push(this.newPoint(v)); this.activePoint = c.points.length - 1; return this.render();
      case 'selPoint': this.activePoint = +v; return this.render();
      case 'delPoint': c.points.splice(+v, 1); this.activePoint = Math.max(0, this.activePoint - 1); return this.render();
      case 'addRow': { const arr = getPath(c, v) || []; arr.push(this.newRow(el.dataset.tpl)); setPath(c, v, arr); return this.render(); }
      case 'delRow': getPath(c, v).splice(+el.dataset.k, 1); return this.render();
      case 'coords': {
        await grabCoords(this.page === 'terr' ? this : c, v);
        if (v === 'gang.blip.coords' && c) c.gang.blip.enabled = true;
        return this.render();
      }
      case 'tp': { const p = getPath(this.page === 'terr' ? this : c, v); if (p) rpc('teleport', p); return; }
      case 'capture': {
        const r = await rpc('captureOutfit'), o = getPath(c, v);
        o[r.sex === 'f' ? 'female' : 'male'] = r.clothes;
        toast(`Tenue ${r.sex === 'f' ? 'femme' : 'homme'} capturée`, 'ok'); return this.render();
      }
    }
  },

  async onInput(el, isChange) {
    if (el.closest('#confirm')) return;
    let val = el.value;
    if (el.dataset.t === 'b') val = el.checked;
    else if (el.dataset.t === 'n') val = val === '' ? null : Number(val);
    else if (el.dataset.t === 'c') val = hexRgb(val);
    else if (el.dataset.t === 'list') val = val.split(',').map(x => x.trim()).filter(Boolean);

    // Réglages du Schema : clé à points stockée à plat (data-sk="section|Chemin.Cle")
    if (el.dataset.sk) {
      if (!this.S) return;
      const [sec, key] = el.dataset.sk.split('|');
      this.S.draft[sec][key] = val;
      if (key === 'UI.Accent') applyTheme(val);
      if (isChange && (el.dataset.t === 'c')) this.render();
      return;
    }
    const path = el.dataset.path; if (!path) return;
    const isS = path.startsWith('S.'), isT = path.startsWith('T.');
    if (isS || isT) { setPath(this, path, val); if (isChange && (el.dataset.t === 'c' || el.dataset.t === 's')) this.render(); return; }
    if (!this.cur) return;
    setPath(this, 'cur.' + path, val);
    if (el.dataset.kindsel != null && isChange) {          // changement de type de garage : libellé par défaut + rafraîchissement
      const pt = this.cur.points[+el.dataset.kindsel], kinds = this.catalog.garageKinds || {};
      if (!pt.label || /^Garage/.test(pt.label)) pt.label = 'Garage ' + ((kinds[pt.data.kind] || {}).label || '').toLowerCase();
      return this.render();
    }
    if (!isChange) return;
    if (el.dataset.item) {
      const it = (this.catalog.items || []).find(i => i.name === el.value), obj = getPath(this.cur, el.dataset.item);
      if (it && (!obj.label || obj.label === obj.name)) obj.label = it.label;
      return this.render();
    }
    if (el.dataset.veh) {
      const m = String(el.value).toLowerCase(); setPath(this.cur, path, m);
      const r = await rpc('checkModel', m);
      if (!r.valid) toast(`Modèle « ${m} » introuvable dans le jeu`, 'err');
      const veh = (this.catalog.vehicles || []).find(x => x.model === m), obj = getPath(this.cur, el.dataset.veh);
      if (!obj.label || obj.label === obj.model) obj.label = veh ? veh.name : m;
      return this.render();
    }
  },
};

/* ════════════════════════════ PARAMÈTRES (config du script modifiable en jeu) ════════════════════════════ */
const MARKER_TYPES = [[0, 'Cône inversé'], [1, 'Cylindre'], [2, 'Chevron épais'], [3, 'Chevron fin'], [4, 'Drapeau à damier'], [5, 'Drapeau à damier (rond)'], [6, 'Cercle vertical'], [7, 'Avion'],
  [20, 'Chevron ×1'], [21, 'Chevron ×2'], [22, 'Chevron ×3'], [23, 'Cercle épais'], [24, 'Icône replay'], [25, 'Cercle fin'], [26, 'Cercle fin + flèche'], [27, 'Cercle + flèches'], [28, 'Sphère'],
  [29, 'Symbole dollar'], [30, 'Barres horizontales'], [31, 'Tête de loup'], [32, 'Point d\'interrogation'], [33, 'Symbole avion'], [34, 'Symbole hélico'], [35, 'Symbole bateau'], [36, 'Symbole voiture'],
  [37, 'Symbole moto'], [38, 'Symbole vélo'], [39, 'Symbole camion'], [40, 'Symbole parachute'], [41, 'Lame de scie']];
const ACCENT_PRESETS = [['Rouge', [239, 68, 68]], ['Orange', [249, 115, 22]], ['Jaune', [250, 204, 21]], ['Vert', [34, 197, 94]], ['Turquoise', [64, 224, 208]], ['Bleu', [59, 130, 246]], ['Violet', [168, 85, 247]], ['Rose', [236, 72, 153]], ['Blanc', [244, 244, 245]]];

Object.assign(Builder, {
  async openSettings() {
    const r = await rpc('settings:get');
    if (!r || !r.ok) return toast((r && r.error) || 'Accès refusé', 'err');
    const prev = this.S;
    this.S = { values: r.values, defaults: r.defaults, schema: r.schema, draft: {}, sec: prev ? prev.sec : r.schema[0].id, gt: prev ? prev.gt : null };
    Object.keys(r.values).forEach(k => { this.S.draft[k] = clone(r.values[k]); });
    this.page = 'settings';
    this.render();
  },

  setTabs() {
    return [...this.S.schema.map(s => [s.id, s.label]), ['pointTypes', 'Markers des points'], ['gangTypes', 'Modèles de gangs']];
  },

  renderSettings() {
    const S = this.S, sec = S.sec;
    const acts = `<button data-a="setReset">Réinitialiser cette section</button><button class="primary" data-a="setSave" style="height:38px">Enregistrer et appliquer</button>`;
    const body = sec === 'pointTypes' ? this.set_pointTypes() : sec === 'gangTypes' ? this.set_gangTypes() : this.set_schema(sec);
    return {
      head: { icon: 'sliders', title: 'Paramètres', sub: 'Configuration du script — appliquée en direct à tous les joueurs', acts },
      body: `<div class="seg" style="flex-wrap:wrap">${this.setTabs().map(([k, l]) => `<button class="${sec === k ? 'active' : ''}" data-a="setTab" data-v="${k}">${l}</button>`).join('')}</div>${body}`,
    };
  },

  // Formulaire généré depuis Config.Schema (config.lua) : un nouveau réglage ajouté dans le schéma apparaît ici tout seul
  schemaField(sec, f) {
    const v = this.S.draft[sec][f.key], sk = `data-sk="${sec}|${f.key}"`, label = esc(f.label);
    if (f.t === 'bool') return `<label class="chk"><input type="checkbox" ${sk} data-t="b" ${v ? 'checked' : ''}> ${label}</label>`;
    if (f.t === 'int' || f.t === 'num') return fld(label, `<input type="number" step="${f.t === 'int' ? 1 : 'any'}" ${f.min != null ? `min="${f.min}"` : ''} ${f.max != null ? `max="${f.max}"` : ''} ${sk} data-t="n" value="${v ?? ''}">`);
    if (f.t === 'enum') return fld(label, `<select ${sk} data-t="s">${(f.opts || []).map(o => `<option value="${esc(o[0])}" ${v === o[0] ? 'selected' : ''}>${esc(o[1])}</option>`).join('')}</select>`);
    if (f.t === 'list') return fld(label, `<input ${sk} data-t="list" value="${esc((v || []).join(', '))}" placeholder="séparés par des virgules">`);
    if (f.t === 'color') return fld(label, `<input type="color" ${sk} data-t="c" value="${rgbHex(v)}" style="max-width:200px">`);
    return fld(label, `<input ${sk} value="${esc(v ?? '')}" maxlength="${f.max || 100}">`);
  },

  set_schema(sec) {
    const def = this.S.schema.find(s => s.id === sec);
    if (!def) return emptyState('sliders', 'Section inconnue', 'Mets à jour les fichiers du script puis refresh + restart pickax_core.');
    const flat = def.fields.filter(f => f.t !== 'bool' && f.t !== 'color'), bools = def.fields.filter(f => f.t === 'bool'), colors = def.fields.filter(f => f.t === 'color');
    let extra = '';
    if (sec === 'ui') {
      const acc = this.S.draft.ui['UI.Accent'] || [239, 68, 68];
      extra = `<div class="grid2"><div class="card"><div class="card-h"><div class="t">${ic('sliders', 16)} Couleur d'accentuation</div></div>
          ${colors.map(f => this.schemaField('ui', f)).join('')}
          <div class="lbl" style="margin:16px 0 8px">Couleurs prédéfinies</div>
          <div class="row wrap">${ACCENT_PRESETS.map(([n, c]) => `<button class="swatch-pick ${c.join() === acc.join() ? 'on' : ''}" title="${n}" data-a="uiPreset" data-v="${c.join(',')}" style="background:rgb(${c.join(',')})"></button>`).join('')}</div>
          <p class="hint mt">S'applique à <b>tous les menus</b> (builder, F7, boss, activités) dès que tu enregistres. L'aperçu à droite est immédiat.</p></div>
        <div class="card"><div class="card-h"><div class="t">${ic('grid', 16)} Aperçu</div>${chip('Gang')}</div>
          <div class="profile" style="margin-bottom:12px"><div class="avatar">B</div><div><b>Ballas</b><small>Lieutenant</small></div></div>
          <div class="nav-item active" style="margin-bottom:10px">${ic('users')}<span class="grow">Membres</span></div>
          <div class="row wrap"><button class="primary">${ic('plus', 15)} Recruter</button><button>Quitter</button>${chip('Actif', 'ok')}${chip('Info', 'info')}</div>
          <div class="segs mt">${Array.from({ length: 10 }, (_, i) => `<i class="${i < 6 ? 'on' : ''}"></i>`).join('')}</div></div></div>`;
    }
    const hints = {
      general: 'La tolérance serveur est la distance maximale acceptée entre le joueur et un point (anti-triche). Tu ne peux pas retirer ton propre groupe de la liste. La touche F7 et les noms de commandes se changent dans <b>config.lua</b> (redémarrage requis).',
      territories: 'Chaque territoire peut surcharger ces valeurs (onglet <b>Territoires</b> du menu de gauche).',
      salary: 'Si ton es_extended paie déjà les salaires de job2, laisse cette option désactivée pour éviter un double paiement.',
      treasury: 'Argent propre et argent sale du gang. Les gangs peuvent déposer / retirer depuis leur point « Gestion du gang ».',
    };
    return `${extra}<div class="card"><div class="card-h"><div class="t">${ic('list', 16)} ${esc(def.label)}</div></div>
      ${flat.length ? `<div class="grid3" style="gap:14px 14px">${flat.map(f => this.schemaField(sec, f)).join('')}</div>` : ''}
      ${bools.length ? `<div style="display:flex;flex-direction:column;gap:13px;margin-top:${flat.length ? 18 : 0}px">${bools.map(f => this.schemaField(sec, f)).join('')}</div>` : ''}
      ${hints[sec] ? `<p class="hint mt">${hints[sec]}</p>` : ''}</div>`;
  },

  markerEditor(path, d, title, withLabel) {
    d = d || {};
    const sc = d.scale || { x: 0.9, y: 0.9, z: 0.6 }, hex = rgbHex(d.color);
    const known = MARKER_TYPES.some(([id]) => id === Number(d.marker));
    return `<div class="card"><div class="card-h"><div class="t"><span class="swatch" style="background:${hex}"></span>${esc(title)}</div><button class="sm" data-a="preview" data-v="${path}">${ic('target', 14)} Aperçu en jeu</button></div>
      <div class="grid4">${withLabel ? fld('Nom affiché', `<input data-path="${path}.label" value="${esc(d.label || '')}" maxlength="40">`) : '<div></div>'}
        ${fld('Type de marker', `<select data-path="${path}.marker" data-t="n">${MARKER_TYPES.map(([id, n]) => `<option value="${id}" ${Number(d.marker) === id ? 'selected' : ''}>${id} · ${n}</option>`).join('')}${known ? '' : `<option value="${d.marker}" selected>${d.marker} · (personnalisé)</option>`}</select>`)}
        ${fld('Couleur', `<input type="color" data-path="${path}.color" data-t="c" value="${hex}">`)}
        ${num(path + '.alpha', 'Opacité (0-255)', d.alpha ?? 140, 'min="0" max="255"')}</div>
      <div class="grid4 mt">${num(path + '.scale.x', 'Taille X', sc.x, 'step="0.05" min="0.05"')}${num(path + '.scale.y', 'Taille Y', sc.y, 'step="0.05" min="0.05"')}${num(path + '.scale.z', 'Hauteur (Z)', sc.z, 'step="0.05" min="0.05"')}${num(path + '.offset', 'Décalage vertical', d.offset ?? -0.95, 'step="0.05"')}</div>
      <div class="row mt" style="gap:26px"><label class="chk"><input type="checkbox" data-path="${path}.bob" data-t="b" ${d.bob ? 'checked' : ''}> Rebond (monte et descend)</label><label class="chk"><input type="checkbox" data-path="${path}.rotate" data-t="b" ${d.rotate ? 'checked' : ''}> Rotation</label><label class="chk"><input type="checkbox" data-path="${path}.help" data-t="b" ${d.help !== false ? 'checked' : ''}> Aide « E »</label></div></div>`;
  },

  set_pointTypes() {
    const t = this.S.draft.pointTypes;
    return `<p class="hint" style="margin-bottom:14px">Apparence de base des markers de chaque type de point. Avec « Markers aux couleurs du gang » (Paramètres → Général), la couleur du gang remplace la couleur ci-dessous. « Aperçu en jeu » affiche le marker devant toi pendant 8 secondes.</p>` +
      Object.keys(t).map(k => this.markerEditor(`S.draft.pointTypes.${k}`, t[k], `${t[k].label} (${k})`, true)).join('');
  },

  set_gangTypes() {
    const S = this.S, types = S.draft.gangTypes, keys = Object.keys(types).sort();
    if (!S.gt || !types[S.gt]) S.gt = keys[0];
    const k = S.gt, t = types[k], b = `S.draft.gangTypes.${k}`;
    const actions = Object.entries(this.catalog.actions).filter(([id]) => id !== 'info' && id !== 'leave' && id !== 'tablet');
    const pts = Object.entries(this.catalog.pointTypes).filter(([, p]) => !p.hidden);
    return `<p class="hint" style="margin-bottom:14px">Les modèles proposés à la création d'un gang : couleur, blip, grades, actions et points suggérés. Modifier un modèle n'altère pas les gangs déjà créés.</p>
      <div class="pts"><div>${keys.map(x => `<div class="pt ${x === k ? 'active' : ''}" data-a="gtSel" data-v="${esc(x)}"><span class="swatch" style="background:${esc(types[x].color)}"></span><div style="flex:1;min-width:0"><b>${esc(types[x].label)}</b><small>${esc(x)} · ${types[x].grades.length} grades</small></div></div>`).join('')}
        <div class="row mt"><input id="gt-key" placeholder="clé (ex: yakuza)" maxlength="20"><button class="icon" data-a="gtAdd">${ic('plus', 16)}</button></div></div>
        <div>${t ? `<div class="card"><div class="card-h"><div class="t"><span class="swatch" style="background:${esc(t.color)}"></span>${esc(t.label)}</div><button class="sm danger" data-a="gtDel">${ic('trash', 14)} Supprimer</button></div>
          <div class="grid3">${fld('Nom du modèle', `<input data-path="${b}.label" value="${esc(t.label)}" maxlength="40">`)}${fld('Couleur par défaut', `<input type="color" data-path="${b}.color" data-t="s" value="${esc(t.color)}">`)}${fld('Identifiant', `<input value="${esc(k)}" disabled>`)}</div>
          <div class="grid3 mt">${num(b + '.blip.sprite', 'Blip : sprite', t.blip.sprite)}${num(b + '.blip.color', 'Blip : couleur', t.blip.color)}${num(b + '.blip.scale', 'Blip : taille', t.blip.scale, 'step="0.1"')}</div></div>
          <div class="grid2"><div class="card"><div class="card-h"><div class="t">Actions cochées par défaut</div></div><div style="display:flex;flex-direction:column;gap:12px">${actions.map(([id, a]) => `<label class="chk"><input type="checkbox" data-a="gtAction" data-v="${id}" ${t.actions.includes(id) ? 'checked' : ''}> ${esc(a.label)}</label>`).join('')}</div></div>
            <div class="card"><div class="card-h"><div class="t">Points suggérés</div></div><div style="display:flex;flex-direction:column;gap:12px">${pts.map(([id, p]) => `<label class="chk"><input type="checkbox" data-a="gtPoint" data-v="${id}" ${t.points.includes(id) ? 'checked' : ''}> ${esc(p.label)}</label>`).join('')}</div></div></div>
          <div class="card"><div class="card-h"><div class="t">Grades (${t.grades.length})</div></div><table><tr><th style="width:44px">#</th><th>Nom</th><th>Label</th><th style="width:130px">Salaire</th><th style="width:130px"></th></tr>
            ${t.grades.map((g, i) => `<tr><td class="muted">${i}</td><td><input data-path="${b}.grades.${i}.name" value="${esc(g.name)}" maxlength="40"></td><td><input data-path="${b}.grades.${i}.label" value="${esc(g.label)}" maxlength="50"></td>
              <td><input type="number" min="0" data-path="${b}.grades.${i}.salary" data-t="n" value="${g.salary}"></td>
              <td><div class="row" style="gap:6px"><button class="icon" data-a="gtGradeUp" data-v="${i}">${ic('up', 15)}</button><button class="icon" data-a="gtGradeDown" data-v="${i}">${ic('down', 15)}</button><button class="icon danger" data-a="gtGradeDel" data-v="${i}">${ic('trash', 15)}</button></div></td></tr>`).join('')}</table>
            <div class="row mt"><button data-a="gtGradeAdd">${ic('plus', 15)} Ajouter un grade</button></div></div>` : ''}</div></div>`;
  },

  async settingsAction(a, v, el) {
    const S = this.S;
    const need = () => this.page === 'settings' && S;
    const gt = () => S.draft.gangTypes[S.gt];
    switch (a) {
      case 'uiPreset': { if (!need()) return false; S.draft.ui['UI.Accent'] = v.split(',').map(Number); applyTheme(S.draft.ui['UI.Accent']); this.render(); return true; }
      case 'setTab': if (!need()) return false; S.sec = v; this.render(); return true;
      case 'preview': { if (!need()) return false; await rpc('previewMarker', getPath(this, v)); toast('Aperçu affiché devant toi (8 s)'); return true; }
      case 'setSave': case 'setReset': {
        if (!need()) return false;
        const sec = S.sec;
        if (a === 'setReset' && !await confirmBox('Réinitialiser cette section ?', 'Les valeurs reviennent à celles de config.lua pour tous les joueurs.', 'Réinitialiser')) return true;
        const r = a === 'setSave' ? await rpc('settings:save', sec, S.draft[sec]) : await rpc('settings:reset', sec);
        if (!r || !r.ok) { toast((r && r.error) || 'Erreur', 'err'); return true; }
        S.values[sec] = r.value; S.draft[sec] = clone(r.value);
        if (sec === 'ui') applyTheme(r.value['UI.Accent']);
        this.catalog = await rpc('catalog');
        toast(a === 'setSave' ? 'Paramètres enregistrés et appliqués en direct' : 'Section réinitialisée', 'ok');
        this.render(); return true;
      }
      case 'gtSel': if (!need()) return false; S.gt = v; this.render(); return true;
      case 'gtAdd': {
        if (!need()) return false;
        const k = document.getElementById('gt-key').value.trim().toLowerCase();
        if (!/^[a-z0-9_]{2,20}$/.test(k)) { toast('Clé invalide (a-z, 0-9, _ ; 2-20 car.)', 'err'); return true; }
        if (S.draft.gangTypes[k]) { toast('Ce modèle existe déjà', 'err'); return true; }
        S.draft.gangTypes[k] = { label: k, color: '#ef4444', blip: { sprite: 310, color: 1, scale: 0.9 }, actions: ['handcuff', 'escort', 'search'], points: ['garage', 'cloakroom', 'armory', 'stash', 'boss'], grades: [{ name: 'recrue', label: 'Recrue', salary: 50 }, { name: 'boss', label: 'Chef', salary: 300 }] };
        S.gt = k; this.render(); return true;
      }
      case 'gtDel': if (!need()) return false; if (Object.keys(S.draft.gangTypes).length <= 1) { toast('Il faut au moins un modèle', 'err'); return true; } delete S.draft.gangTypes[S.gt]; S.gt = null; this.render(); return true;
      case 'gtAction': case 'gtPoint': {
        if (!need()) return false;
        const L = a === 'gtAction' ? gt().actions : gt().points, i = L.indexOf(v);
        if (i >= 0) L.splice(i, 1); else L.push(v);
        return true;
      }
      case 'gtGradeAdd': { if (!need()) return false; const g = gt().grades; if (g.length >= (this.catalog.maxGrades || 15)) { toast('Maximum de grades atteint', 'err'); return true; } g.push({ name: 'grade' + g.length, label: 'Nouveau grade', salary: 100 }); this.render(); return true; }
      case 'gtGradeDel': { if (!need()) return false; const g = gt().grades; if (g.length <= 1) { toast('Il faut au moins un grade', 'err'); return true; } g.splice(+v, 1); this.render(); return true; }
      case 'gtGradeUp': { if (!need()) return false; const g = gt().grades; if (+v > 0) [g[v - 1], g[v]] = [g[v], g[v - 1]]; this.render(); return true; }
      case 'gtGradeDown': { if (!need()) return false; const g = gt().grades; if (+v < g.length - 1) [g[+v + 1], g[v]] = [g[v], g[+v + 1]]; this.render(); return true; }
    }
    return false;
  },

  /* ──────────────── Territoires ──────────────── */
  async openTerr() {
    const list = await rpc('terr:list');
    const prev = this.T;
    this.T = { list: Array.isArray(list) ? list : [], cur: null, sel: prev ? prev.sel : null };
    if (this.T.sel != null) this.pickTerr(this.T.sel, true);
    this.page = 'terr';
    this.render();
  },

  pickTerr(id, keep) {
    const t = this.T.list.find(x => x.id === id);
    if (!t) return;
    this.T.sel = id;
    this.T.cur = clone(t);
    this.T.cur.settings = this.T.cur.settings || {};
    if (!keep) this.render();
  },

  renderTerr() {
    const T = this.T, c = T.cur, d = this.catalog.territories || {};
    const list = T.list.map(t => `<div class="pt ${t.id === T.sel ? 'active' : ''}" data-a="terrSel" data-v="${t.id}">${tile('flag')}<div style="flex:1;min-width:0"><b>${esc(t.label)}</b><small>${esc(t.name)} · ${esc(t.ownerLabel || 'libre')} · ${t.radius} m</small></div></div>`).join('');
    const ov = (key, label, def, extra = '') => num(`T.cur.settings.${key}`, `${label} (vide = défaut : ${def})`, c.settings[key] ?? '', `min="0" ${extra}`);
    const editor = !c ? emptyState('flag', 'Aucun territoire sélectionné', 'Sélectionne un territoire à gauche ou crée-en un nouveau.') : `
      <div class="card"><div class="card-h"><div class="t">${ic('flag', 16)} ${c.id ? esc(c.label || c.name) : 'Nouveau territoire'}</div>${c.id ? `<button class="sm danger" data-a="terrDel">${ic('trash', 14)} Supprimer</button>` : ''}</div>
        <div class="grid3">${fld('Nom interne', `<input data-path="T.cur.name" value="${esc(c.name || '')}" maxlength="50" placeholder="ex: grove_street" ${c.id ? 'disabled' : ''}>`)}${fld('Label affiché', `<input data-path="T.cur.label" value="${esc(c.label || '')}" maxlength="100">`)}
          ${fld(`Rayon (m, max ${d.MaxRadius || 300})`, `<input type="number" min="5" max="${d.MaxRadius || 300}" data-path="T.cur.radius" data-t="n" value="${c.radius ?? d.DefaultRadius ?? 40}">`)}</div>
        <div class="mt"><div class="lbl" style="margin-bottom:6px">Centre de la zone</div>${coordField('T.cur.coords', c.coords, { tp: true })}</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('sliders', 16)} Surcharges (laisse vide pour utiliser les valeurs de Paramètres → Territoires)</div></div>
        <div class="grid3">${ov('capture_seconds', 'Durée de capture (s)', d.CaptureSeconds)}${ov('min_members', 'Membres min.', d.MinMembers)}${ov('protection', 'Protection (min)', d.ProtectionMinutes)}
          ${ov('reward', 'Revenu ($)', d.Reward)}${ov('interval', 'Intervalle des revenus (min)', d.IncomeInterval)}</div></div>
      ${c.id ? `<div class="card"><div class="card-h"><div class="t">${ic('crown', 16)} Propriétaire</div>${c.owner ? chip(c.ownerLabel || c.owner, 'info') : chip('Libre', 'mute')}</div>
        <div class="row"><select id="terr-owner" style="max-width:280px"><option value="">— Libre —</option>${this.gangs.map(g => `<option value="${esc(g.name)}" ${c.owner === g.name ? 'selected' : ''}>${esc(g.label)}</option>`).join('')}</select><button data-a="terrOwner">Attribuer</button>
          ${c.protectedUntil && c.protectedUntil > Date.now() / 1000 ? chip('Protégé', 'info') : ''}</div>
        <p class="hint mt">Attribue ou libère le territoire à la main (test, évènement). Le propriétaire touche le revenu à chaque période.</p></div>` : ''}`;
    return {
      head: { icon: 'flag', title: 'Territoires', sub: `${T.list.length} zone(s) — capturées par présence, revenu dans la trésorerie du gang`, acts: `${c ? `<button data-a="placeStart">${ic('pin', 15)} Mode placement</button>` : ''}<button data-a="terrNew">${ic('plus', 15)} Nouveau</button>${c ? `<button class="primary" data-a="terrSave" style="height:38px">Enregistrer</button>` : ''}` },
      body: `<div class="pts"><div>${list || '<p class="hint">Aucun territoire.</p>'}</div><div>${editor}</div></div>`,
    };
  },

  async terrAction(a, v, el) {
    if (this.page !== 'terr' || !this.T) return false;
    const T = this.T;
    switch (a) {
      case 'terrSel': this.pickTerr(+v); return true;
      case 'terrNew': {
        const d = this.catalog.territories || {};
        T.sel = null; T.cur = { id: null, name: '', label: '', coords: null, radius: d.DefaultRadius || 40, settings: {} }; this.render(); return true;
      }
      case 'terrSave': {
        const r = await rpc('terr:save', T.cur);
        if (!r || !r.ok) { toast((r && r.error) || 'Erreur', 'err'); return true; }
        toast('Territoire enregistré', 'ok');
        T.sel = r.id; await this.openTerr(); return true;
      }
      case 'terrDel': {
        if (!await confirmBox('Supprimer le territoire ?', `« ${T.cur.label || T.cur.name} » sera supprimé.`, 'Supprimer')) return true;
        const r = await rpc('terr:delete', T.cur.id);
        if (!r || !r.ok) { toast((r && r.error) || 'Erreur', 'err'); return true; }
        toast('Territoire supprimé', 'ok'); T.sel = null; await this.openTerr(); return true;
      }
      case 'terrOwner': {
        const r = await rpc('terr:setOwner', T.cur.id, document.getElementById('terr-owner').value);
        if (!r || !r.ok) { toast((r && r.error) || 'Erreur', 'err'); return true; }
        toast('Propriétaire mis à jour', 'ok'); await this.refreshList(); await this.openTerr(); return true;
      }
    }
    return false;
  },
});

/* ════════════════════════════ RUNTIME : panneaux utilisés par les joueurs ════════════════════════════ */
const LOG_LABEL = {
  gang_created: 'Gang créé', gang_updated: 'Gang modifié', treasury_deposit: 'Dépôt (propre)', treasury_withdraw: 'Retrait (propre)', dirty_deposit: 'Dépôt (sale)', dirty_withdraw: 'Retrait (sale)',
  recruit: 'Recrutement', fire: 'Exclusion', leave: 'Départ', set_grade: 'Changement de grade', set_salary: 'Salaire modifié', vehicle_out: 'Véhicule sorti', vehicle_in: 'Véhicule rangé',
  armory_take: 'Armurerie', shop_buy: 'Achat marché noir', harvest: 'Récolte', process: 'Traitement', sell: 'Vente', launder: 'Blanchiment',
  territory_captured: 'Territoire capturé', territory_income: 'Revenu de territoire', salary_skipped: 'Salaires non versés',
  action_handcuff: 'Menottes', action_escort: 'Escorte', action_search: 'Fouille',
};

const Runtime = {
  kind: null, data: null, pointId: null, tab: 'treasury',

  open(kind, data, pointId) {
    this.kind = kind; this.data = data; this.pointId = pointId;
    if (kind === 'boss') this.tab = 'treasury';
    this.render();
  },

  render() {
    const d = this.data || {}, k = this.kind;
    $root.classList.toggle('corner', k === 'menu');
    const fn = this['view_' + k];
    $root.innerHTML = fn ? fn.call(this, d) : panel({ icon: 'grid', title: 'Gang Builder', body: emptyState('grid', 'Écran inconnu', 'Mets à jour les fichiers du script.') });
  },

  view_menu(d) {
    return panel({ icon: 'skull', title: d.gangLabel, sub: d.grade, cls: 'corner', body: d.actions.map(a => `<div class="item click" data-a="act" data-v="${esc(a.id)}">${tile(ACTION_ICON[a.id] || 'list')}<div class="grow"><b>${esc(a.label)}</b></div><span class="chev">${ic('chevron', 14)}</span></div>`).join('') });
  },

  view_garage(d) {
    const kind = d.garageKind || 'car';
    return panel({ icon: KIND_ICON[kind], title: d.label, sub: `${d.vehicles.length} véhicule(s) disponible(s)`, cls: 'md', body:
      `<button data-a="store">${ic('down', 15)} Ranger mon véhicule</button>` + (d.vehicles.map(v => `<div class="item">${tile(KIND_ICON[kind])}<div class="grow"><b>${esc(v.label)}</b><small>${esc(v.model)}</small></div><button class="primary sm" data-a="spawn" data-v="${v.idx}">Sortir</button></div>`).join('') || emptyState('car', 'Aucun véhicule', 'Ton grade ne donne accès à aucun véhicule ici.')) });
  },

  view_cloakroom(d) {
    return panel({ icon: 'shirt', title: d.label, sub: `${d.outfits.length} tenue(s)`, cls: 'md', body:
      `<button data-a="civil">${ic('user', 15)} Remettre ma tenue civile</button>` + (d.outfits.map(o => `<div class="item">${tile('shirt')}<div class="grow"><b>${esc(o.label)}</b></div><button class="primary sm" data-a="wear" data-v="${o.idx}">Porter</button></div>`).join('') || emptyState('shirt', 'Aucune tenue', 'Aucune tenue disponible pour ton grade.')) });
  },

  view_armory(d) {
    return panel({ icon: 'target', title: d.label, sub: `${d.items.length} objet(s)`, cls: 'md', body:
      d.items.map(i => `<div class="item">${tile('target')}<div class="grow"><b>${esc(i.label)}</b><small>${esc(i.name)}${i.ammo ? ` · ${i.ammo} munitions` : ''} · ×${i.count}</small></div><button class="primary sm" data-a="take" data-v="${i.idx}">Prendre</button></div>`).join('') || emptyState('target', 'Armurerie vide', 'Rien n\'est disponible pour ton grade.') });
  },

  view_shop(d) {
    const acc = d.account === 'dirty' ? 'argent sale' : d.account === 'bank' ? 'banque' : 'liquide';
    return panel({ icon: 'cart', title: d.label, sub: `Paiement : ${acc}`, cls: 'md', body:
      d.items.map(i => `<div class="item">${tile('box')}<div class="grow"><b>${esc(i.label)}</b><small>${esc(i.name)}</small></div><span class="price">${money(i.price)}</span><input class="qty" id="qty-${i.idx}" type="number" min="1" max="100" value="1"><button class="primary sm" data-a="buy" data-v="${i.idx}">Acheter</button></div>`).join('') || emptyState('cart', 'Rien à vendre', 'Aucun article disponible.') });
  },

  view_harvest(d) {
    const ready = !d.cooldownLeft && d.toolOk;
    return panel({ icon: 'leaf', title: d.label, sub: `${d.count}× ${d.item.label} · ${d.seconds} s`, cls: 'md', body: `
      <div class="card"><div class="kv"><span>Objet récolté</span><span>${esc(d.item.label)} (${esc(d.item.name)})</span></div>
        <div class="kv"><span>Quantité</span><span>${d.count}</span></div><div class="kv"><span>Durée</span><span>${d.seconds} s</span></div>
        <div class="kv"><span>Dans ton inventaire</span><span>${d.have}</span></div>
        ${d.tool ? `<div class="kv"><span>Outil requis</span><span>${esc(d.tool)} ${d.toolOk ? chip('Ok', 'ok') : chip('Manquant', 'bad')}</span></div>` : ''}
        ${d.cooldownLeft ? `<div class="kv"><span>Disponible dans</span><span>${fmtUntil(d.cooldownLeft)}</span></div>` : ''}</div>
      <button class="primary" data-a="harvest" ${ready ? '' : 'disabled'}>${ic('leaf', 16)} Récolter</button>
      <p class="hint">Tu restes sur place pendant la récolte (<b>X</b> pour annuler).</p>` });
  },

  view_process(d) {
    return panel({ icon: 'flask', title: d.label, sub: `${d.recipes.length} recette(s)`, cls: 'md', body:
      d.recipes.map(r => `<div class="card"><div class="card-h"><div class="t">${ic('flask', 16)} ${esc(r.label)}</div>${chip(`${r.seconds} s`, 'nodot mute')}${r.chance < 100 ? chip(`${r.chance} % de réussite`, 'warn') : ''}</div>
        <div class="hint" style="margin-bottom:10px">${r.inputs.map(i => `<span style="color:${i.have >= i.count ? 'var(--ok)' : 'var(--danger)'}">${i.count}× ${esc(i.label)} (${i.have})</span>`).join(' + ')} → <b>${r.output.count}× ${esc(r.output.label)}</b></div>
        <div class="row"><span class="muted sm-t">Quantité</span><select id="pq-${r.idx}" style="max-width:90px">${Array.from({ length: Math.max(1, r.make) }, (_, n) => `<option>${n + 1}</option>`).join('')}</select><span class="spacer"></span><button class="primary" data-a="cook" data-v="${r.idx}" ${r.make < 1 ? 'disabled' : ''}>Fabriquer</button></div></div>`).join('')
      || emptyState('flask', 'Aucune recette', 'Aucune recette disponible pour ton grade.') });
  },

  view_sell(d) {
    const acc = d.account === 'dirty' ? 'en argent sale' : d.account === 'bank' ? 'en banque' : 'en liquide';
    return panel({ icon: 'coins', title: d.label, sub: `Paiement ${acc}${d.cut ? ` · ${d.cut} % pour le gang` : ''}`, cls: 'md', body:
      (d.cooldownLeft ? `<div class="hint">Prochaine vente possible dans ${fmtUntil(d.cooldownLeft)}.</div>` : '') +
      (d.items.map(i => `<div class="item">${tile('coins')}<div class="grow"><b>${esc(i.label)}</b><small>${esc(i.name)} · tu en as ${i.have} · prix ≈ ${money(i.price)} (± ${d.variance} %)</small></div>
        <input class="qty" id="sq-${i.idx}" type="number" min="1" max="${d.maxSell}" value="${Math.min(Math.max(1, i.have), d.maxSell)}"><button class="sm" data-a="sellAll" data-v="${i.idx}" data-have="${i.have}">Tout</button><button class="primary sm" data-a="sell" data-v="${i.idx}" ${i.have < 1 ? 'disabled' : ''}>Vendre</button></div>`).join('')
        || emptyState('coins', 'Rien à vendre', 'Aucun produit disponible pour ton grade.')) });
  },

  view_laundry(d) {
    return panel({ icon: 'wash', title: d.label, sub: `Commission ${d.fee} % · ${d.seconds} s`, cls: 'md', body: `
      <div class="card"><div class="kv"><span>Argent sale sur toi</span><span>${money(d.dirty)}</span></div><div class="kv"><span>Montant autorisé</span><span>${money(d.min)} – ${money(d.max)}</span></div><div class="kv"><span>Commission</span><span>${d.fee} %</span></div></div>
      <div class="row">${fld('Montant à blanchir ($)', `<input id="launder-amount" type="number" min="${d.min}" max="${Math.min(d.max, d.dirty)}" value="${Math.min(d.max, d.dirty)}">`)}<button data-a="launderAll" style="align-self:end">Tout</button></div>
      <button class="primary" data-a="launder" ${d.dirty < d.min ? 'disabled' : ''}>${ic('wash', 16)} Blanchir</button>
      <p class="hint">Tu restes sur place pendant l'opération (<b>X</b> pour annuler). Tu reçois de l'argent propre, la commission est prélevée.</p>` });
  },

  view_leave(d) {
    return panel({ icon: 'door', title: 'Quitter le gang', sub: d.gangLabel, cls: 'md', body: `<p class="hint">Tu es sûr de vouloir quitter <b>${esc(d.gangLabel)}</b> ? Tu perds ton grade et l'accès à ses points, coffres et territoires.</p>
      <div class="row"><span class="spacer"></span><button data-a="close">Annuler</button><button class="danger" data-a="leaveConfirm">Quitter le gang</button></div>` });
  },

  view_info(d) {
    const terr = d.territories || [];
    const mine = terr.filter(t => t.mine).length;
    return panel({ icon: 'skull', title: d.label, sub: `${d.gradeLabel} · réputation ${d.rep}`, cls: 'lg', body: `
      ${d.motd ? `<div class="card" style="border-color:${esc(d.color)}66"><div class="eyebrow" style="margin-bottom:8px">Message du jour</div>${esc(d.motd)}</div>` : ''}
      <div class="grid4"><div class="stat"><div class="eyebrow">Réputation</div><div class="v">${d.rep}</div></div>
        <div class="stat"><div class="eyebrow">Membres</div><div class="v">${d.members}${d.maxMembers > 0 ? `<small class="muted"> / ${d.maxMembers}</small>` : ''}</div><div class="s">${d.online.length} en ligne</div></div>
        <div class="stat"><div class="eyebrow">Territoires</div><div class="v">${mine}</div><div class="s">sur ${terr.length}</div></div>
        <div class="stat"><div class="eyebrow">Trésorerie</div><div class="v">${d.money != null ? money(d.money) : '—'}</div><div class="s">${d.dirty != null ? money(d.dirty) + ' sale' : 'réservé au bureau'}</div></div></div>
      <div class="grid2"><div class="card"><div class="card-h"><div class="t">${ic('users', 16)} En ligne (${d.online.length})</div></div>
          ${d.online.map(m => `<div class="kv"><span style="color:var(--text)">${esc(m.name)}</span><span>${esc(m.gradeLabel)}</span></div>`).join('') || '<p class="hint">Personne d\'autre en ligne.</p>'}</div>
        <div class="card"><div class="card-h"><div class="t">${ic('flag', 16)} Territoires</div></div>
          ${terr.map(t => `<div class="kv"><span style="color:var(--text)">${esc(t.label)}</span><span>${t.mine ? chip('À nous', 'ok') : t.ownerLabel ? chip(t.ownerLabel, 'bad') : chip('Libre', 'mute')}${t.protectedUntil > d.now ? ' ' + chip('Protégé', 'info') : ''}</span></div>`).join('') || '<p class="hint">Aucun territoire sur le serveur.</p>'}</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('target', 16)} Mes statistiques</div></div>
        <div class="grid4">${[['Récolté', d.stats.harvested], ['Fabriqué', d.stats.processed], ['Vendu', money(d.stats.sold)], ['Blanchi', money(d.stats.laundered)]].map(([l, v]) => `<div class="stat"><div class="eyebrow">${l}</div><div class="v">${v}</div></div>`).join('')}</div>
        <p class="hint mt">Contribution à la trésorerie : <b>${money(d.stats.contribution)}</b></p></div>` });
  },

  view_boss(d) {
    const tabs = [['treasury', 'Trésorerie'], ['members', `Membres · ${d.members.length}`], ['grades', 'Grades & salaires'], ['log', 'Journal']];
    const g = d.grades;
    let body = '';
    if (this.tab === 'treasury') {
      const T = d.treasury, canW = d.myGrade >= d.withdraw_grade;
      body = `<div class="grid2"><div class="card"><div class="eyebrow">Argent propre</div><div class="money" data-live="money">${Number(d.money).toLocaleString('fr-FR')}<small>$</small></div></div>
          <div class="card"><div class="eyebrow">Argent sale</div><div class="money" data-live="dirty">${Number(d.dirty).toLocaleString('fr-FR')}<small>$</small></div></div></div>
        ${T.enabled ? `<div class="card mt"><div class="card-h"><div class="t">${ic('coins', 16)} Opération</div></div>
          <div class="grid3">${fld('Compte', `<select id="bm-kind"><option value="money">Argent propre</option>${T.dirty ? '<option value="dirty">Argent sale</option>' : ''}</select>`)}${fld('Montant ($)', `<input id="bm-amount" type="number" min="1" max="${T.max}" placeholder="0">`)}
            <div class="row" style="align-self:end"><button class="primary" data-a="bm" data-v="deposit" ${T.deposit ? '' : 'disabled'}>${ic('down', 15)} Déposer</button><button data-a="bm" data-v="withdraw" ${T.withdraw && canW ? '' : 'disabled'}>${ic('up', 15)} Retirer</button></div></div>
          <p class="hint mt">${canW ? 'Plafond par opération : ' + money(T.max) : `Retrait réservé au grade « ${esc((g[d.withdraw_grade] || {}).label || d.withdraw_grade)} » et plus.`}</p></div>` : '<p class="hint mt">La trésorerie est désactivée sur ce serveur.</p>'}
        <div class="grid3 mt"><div class="stat"><div class="eyebrow">Réputation</div><div class="v">${d.rep}</div></div><div class="stat"><div class="eyebrow">Membres</div><div class="v">${d.members.length}${d.maxMembers > 0 ? `<small class="muted"> / ${d.maxMembers}</small>` : ''}</div></div>
          <div class="stat"><div class="eyebrow">Ton grade</div><div class="v" style="font-size:18px">${esc((g[d.myGrade] || {}).label || d.myGrade)}</div></div></div>`;
    } else if (this.tab === 'members') {
      body = `<div class="row" style="margin-bottom:14px"><button class="primary" data-a="recruit">${ic('plus', 15)} Recruter le joueur le plus proche</button><span class="hint">Le joueur doit être à côté de toi et sans gang.</span></div>
        ${d.members.map(m => `<div class="item">${tile('user')}<div class="grow"><b>${esc(m.name || m.identifier.slice(-8))}</b><small>${m.online ? 'En ligne' : 'Hors ligne'}</small></div>
          <select style="width:180px" data-setgrade="${esc(m.identifier)}">${g.map((x, i) => `<option value="${i}" ${m.grade === i ? 'selected' : ''}>${i} · ${esc(x.label)}</option>`).join('')}</select><button class="icon danger" data-a="fire" data-v="${esc(m.identifier)}" title="Exclure">${ic('trash', 15)}</button></div>`).join('') || emptyState('users', 'Aucun membre', 'Recrute ton premier membre.')}`;
    } else if (this.tab === 'grades') {
      body = `<div class="card"><table><tr><th style="width:44px">#</th><th>Grade</th><th style="width:160px">Salaire ($)</th></tr>${g.map((x, i) => `<tr><td class="muted">${i}</td><td>${esc(x.label)}${i >= d.boss_grade ? ' ' + chip('Bureau', 'info') : ''}</td><td><input type="number" min="0" data-salary="${i}" value="${x.salary}"></td></tr>`).join('')}</table>
        <p class="hint mt">Le salaire est enregistré dans <b>job2_grades</b> dès que tu quittes le champ.</p></div>`;
    } else {
      body = `<div class="card">${d.logs.map(l => `<div class="logline"><b>${esc(LOG_LABEL[l.action] || l.action)}</b> · ${esc(l.player_name || 'système')}${l.detail ? ' — ' + esc(l.detail) : ''}<br><span style="color:#5d5d64">${fmtDate(l.t)}</span></div>`).join('') || '<p class="hint">Aucune entrée.</p>'}</div>`;
    }
    return panel({ icon: 'crown', title: d.label, sub: d.pointLabel, cls: 'lg', body: `<div class="seg" style="margin-bottom:0">${tabs.map(([k, l]) => `<button class="${this.tab === k ? 'active' : ''}" data-a="bossTab" data-v="${k}">${l}</button>`).join('')}</div>${body}` });
  },

  async reloadPoint() {
    const r = await rpc('openPoint', this.pointId);
    if (r && r.ok) { this.data = r; this.render(); }
  },

  async bossCall(name, ...args) {
    const r = await rpc(name, this.pointId, ...args);
    if (!r || !r.ok) return toast((r && r.error) || 'Erreur', 'err');
    this.data = r; this.render();
    return r;
  },

  async onA(el) {
    const a = el.dataset.a, v = el.dataset.v, pid = this.pointId;
    const done = r => { if (!r || !r.ok) toast((r && r.error) || 'Erreur', 'err'); return r && r.ok; };
    switch (a) {
      case 'act': return rpc('doAction', v);
      case 'spawn': return done(await rpc('garage:spawn', pid, +v));
      case 'store': return done(await rpc('garage:store', pid));
      case 'civil': await rpc('cloakCivil'); return toast('Tenue civile remise', 'ok');
      case 'wear': return done(await rpc('cloak:wear', pid, +v)) && toast('Tenue appliquée', 'ok');
      case 'take': return done(await rpc('armory:take', pid, +v)) && toast('Objet récupéré', 'ok');
      case 'buy': { const q = Number(document.getElementById('qty-' + v).value) || 1; if (done(await rpc('shop:buy', pid, +v, q))) toast('Achat effectué', 'ok'); return; }
      case 'harvest': return done(await rpc('act:run', 'harvest', pid));
      case 'cook': return done(await rpc('act:run', 'process', pid, +v, Number(document.getElementById('pq-' + v).value) || 1));
      case 'launderAll': { const i = document.getElementById('launder-amount'); i.value = i.max; return; }
      case 'launder': return done(await rpc('act:run', 'laundry', pid, Number(document.getElementById('launder-amount').value) || 0));
      case 'sellAll': document.getElementById('sq-' + v).value = Math.min(Number(el.dataset.have), this.data.maxSell); return;
      case 'sell': {
        const r = await rpc('sell:do', pid, +v, Number(document.getElementById('sq-' + v).value) || 0);
        if (!done(r)) return;
        toast(`Vendu : ${money(r.total)}${r.cut ? ` (gang : ${money(r.cut)})` : ''}`, 'ok');
        return this.reloadPoint();
      }
      case 'leaveConfirm': { const r = await rpc('leave'); if (done(r)) { toast('Tu as quitté le gang', 'ok'); close(); } return; }
      case 'bossTab': this.tab = v; return this.render();
      case 'bm': {
        const amount = Number(document.getElementById('bm-amount').value) || 0;
        const r = await this.bossCall('boss:money', v, document.getElementById('bm-kind').value, amount);
        if (r) toast(v === 'deposit' ? 'Dépôt effectué' : 'Retrait effectué', 'ok');
        return;
      }
      case 'recruit': { const r = await this.bossCall('boss:recruit', 0); if (r) toast('Joueur recruté', 'ok'); return; }
      case 'fire': {
        if (!await confirmBox('Exclure ce membre ?', 'Il perdra son grade et l\'accès au gang.', 'Exclure')) return;
        const r = await this.bossCall('boss:fire', v); if (r) toast('Membre exclu', 'ok'); return;
      }
    }
  },

  async onInput(el, isChange) {
    if (!isChange) return;
    if (el.dataset.setgrade) { const r = await this.bossCall('boss:setGrade', el.dataset.setgrade, Number(el.value)); if (r) toast('Grade modifié', 'ok'); else this.render(); }
    else if (el.dataset.salary != null && el.dataset.salary !== '') { const r = await this.bossCall('boss:salary', Number(el.dataset.salary), Number(el.value)); if (r) toast('Salaire enregistré', 'ok'); }
  },
};
