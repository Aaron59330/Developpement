'use strict';
/* ════════════════════════════ Utilitaires ════════════════════════════ */
const $root = document.getElementById('root');
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const money = n => Number(n || 0).toLocaleString('fr-FR') + ' $';
const r2 = n => Math.round(n * 100) / 100;
const fmtDate = t => new Date(t * 1000).toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
const initials = n => String(n || '?').split(/\s+/).map(w => w[0]).join('').slice(0, 2).toUpperCase();
const resName = () => (typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_jobbuilder');

async function rpc(name, ...args) {
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort(), 10000);
  try {
    const r = await fetch(`https://${resName()}/rpc`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name, args }), signal: ctl.signal });
    return await r.json();
  } catch (e) {
    return { ok: false, error: ctl.signal.aborted ? `Le serveur ne répond pas à « ${name} » : vérifie que tous les fichiers sont à jour (refresh + restart pickax_jobbuilder) et regarde la console serveur` : 'Erreur de communication' };
  } finally { clearTimeout(timer); }
}

// esx_society / esx_addonaccount (ou CorePickax) chargent les jobs au démarrage : on prévient ou on confirme le redémarrage
function compatToast(c) {
  if (!c) return;
  if (c.restarted) toast(`Redémarrage de ${c.resources.join(', ')} dans quelques secondes pour prendre en compte le job…`);
  else if (c.detected && c.detected.length) toast(`Redémarre ${c.detected.join(', ')} pour qu'il voie ce job (ou ajoute-le dans Paramètres → Général → Ressources à redémarrer).`, 'err');
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
  logout: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5"/><path d="M21 12H9"/>',
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
  map: '<path d="m3 6 6-3 6 3 6-3v15l-6 3-6-3-6 3z"/><path d="M9 3v15"/><path d="M15 6v15"/>',
  folder: '<path d="M4 20h16a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.93a2 2 0 0 1-1.66-.9l-.82-1.2A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13c0 1.1.9 2 2 2Z"/>',
  siren: '<path d="M7 18v-6a5 5 0 1 1 10 0v6"/><path d="M5 21a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-1a2 2 0 0 0-2-2H7a2 2 0 0 0-2 2z"/><path d="M21 12h1"/><path d="M18.5 4.5 18 5"/><path d="M2 12h1"/><path d="M12 2v1"/><path d="m4.929 4.929.707.707"/><path d="M12 12v6"/>',
  tablet: '<rect width="16" height="20" x="4" y="2" rx="2"/><path d="M12 18h.01"/>',
  cross: '<path d="M11 2a2 2 0 0 0-2 2v5H4a2 2 0 0 0-2 2v2c0 1.1.9 2 2 2h5v5c0 1.1.9 2 2 2h2a2 2 0 0 0 2-2v-5h5a2 2 0 0 0 2-2v-2a2 2 0 0 0-2-2h-5V4a2 2 0 0 0-2-2z"/>',
  sliders: '<path d="M4 21v-7"/><path d="M4 10V3"/><path d="M12 21v-9"/><path d="M12 8V3"/><path d="M20 21v-5"/><path d="M20 12V3"/><path d="M2 14h4"/><path d="M10 8h4"/><path d="M18 16h4"/>',
};
const ic = (n, s) => `<svg class="ic" viewBox="0 0 24 24" ${s ? `style="width:${s}px;height:${s}px"` : ''}>${P[n] || P.grid}</svg>`;

const TYPE_ICON = { police: 'shield', ems: 'heart', mecano: 'wrench', taxi: 'car', realestate: 'home', dealer: 'car', government: 'landmark', bank: 'landmark', bar: 'utensils', custom: 'briefcase' };
const KIND_ICON = { car: 'car', bike: 'bike', aircraft: 'plane', boat: 'ship' };
const PROP_CATS = { house: 'Maison', apartment: 'Appartement', villa: 'Villa', lab: 'Laboratoire', garage: 'Garage', warehouse: 'Entrepôt', office: 'Bureau', shop: 'Local commercial', hotel: 'Hôtel / Motel', other: 'Autre' };
const POINT_ICON = { garage: 'car', cloakroom: 'shirt', armory: 'target', stash: 'box', boss: 'briefcase', shop: 'cart', wardrobe: 'shirt', safe: 'briefcase', showroom: 'tag', display: 'car', testdrive: 'clock', missions: 'route', harvest: 'sprout', kitchen: 'utensils', tuning: 'wrench', garage_return: 'login' };
const ACTION_ICON = { handcuff: 'link', escort: 'users', search: 'search', revive: 'heart', heal: 'plus', repair: 'wrench', clean: 'droplet', invoice: 'file', properties: 'home', dealership: 'car', government: 'landmark', missions: 'route', serve: 'utensils', tablet: 'tablet', jobannounce: 'megaphone', emscalls: 'cross', emstablet: 'tablet', banktablet: 'tablet', leavejob: 'logout' };

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

function header({ icon, title, sub, acts = '' }) {
  return `<div class="head">${tile(icon, 'lg')}<div class="ttl"><h1>${esc(title)}</h1>${sub ? `<p>${esc(sub)}</p>` : ''}</div><div class="acts">${acts}${window.JBBack ? `<button class="sm" data-a="back" title="Retour au menu métier">${ic('left', 14)} Retour</button>` : ''}${closeBtn}</div></div>`;
}

function shellSide({ profile, nav, active, foot = '', head, body }) {
  return `<div class="shell"><aside class="side">
    <div class="profile"><div class="avatar">${esc(profile.initials)}</div><div><b>${esc(profile.title)}</b><small>${esc(profile.sub)}</small></div></div>
    <div class="nav">${nav.map(sec => `${sec.label ? `<div class="nav-label">${esc(sec.label)}</div>` : ''}${sec.items.map(it => `<div class="nav-item ${it.id === active ? 'active' : ''}" data-a="nav" data-v="${esc(it.id)}">${ic(it.icon)}<span class="grow">${esc(it.text)}</span>${it.count != null ? `<span class="count">${it.count}</span>` : ''}</div>`).join('')}`).join('')}</div>
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

// Solde société en direct : mis à jour sans re-render (on ne perd pas la saisie en cours)
function liveMoney(job, money) {
  if ($root.classList.contains('hidden') || money == null) return;
  const cur = Mod === Runtime ? Runtime.data : (Mod === Gov ? Gov.d : null);
  if (!cur || cur.job !== job) return;
  if (Mod === Runtime) cur.money = money; else cur.balance = money;
  document.querySelectorAll('[data-live=money]').forEach(n => { n.innerHTML = Number(money).toLocaleString('fr-FR') + '<small>$</small>'; });
}
setInterval(async () => {
  if ($root.classList.contains('hidden') || typeof Mod === 'undefined' || !Mod) return;
  if (Mod === Runtime && Runtime.kind === 'boss') { const r = await rpc('boss:poll', Runtime.pointId); if (r && r.ok) liveMoney(r.job, r.money); }
  else if (Mod === Gov) { const r = await rpc('gov:balance'); if (r && r.ok) liveMoney(r.job, r.balance); }
  else if (Mod === Tablet && Tablet.d) Tablet.poll();
  else if (Mod === Ems && Ems.d) Ems.poll();
  else if (Mod === Bank && Bank.d) Bank.poll();
}, 2000);

function showOxygen(d) {
  const el = document.getElementById('oxygen');
  el.classList.toggle('warn', !!d.warn);
  el.innerHTML = `<div class="ox-ic">${ic('droplet', 18)}</div><div class="ox-bar"><i style="width:${Math.max(0, Math.min(100, Math.round(d.pct * 100)))}%"></i></div><b>${Math.max(0, d.left).toFixed(1)}<small>s</small></b>`;
  el.classList.remove('hidden');
}

function showDeath(d) {
  const el = document.getElementById('death');
  const mm = s => `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`;
  const can = d.left <= 0;
  el.innerHTML = `<div class="death-card"><div class="d-ic">${ic('cross', 26)}</div><h2>Tu es inconscient</h2>
    <div class="d-timer ${can ? 'ok' : ''}">${can ? 'Tu peux réapparaître' : mm(d.left)}</div>
    <p class="d-status">${d.called ? (d.units > 0 ? `<b>${d.units}</b> médecin(s) en route vers toi` : 'Les EMS ont été prévenus, patiente…') : (d.ems > 0 ? `${d.ems} médecin(s) en service` : 'Aucun médecin en service')}</p>
    <div class="d-keys"><span class="${d.cooldown > 0 && d.called ? 'dim' : ''}"><kbd>E</kbd> Appeler les EMS</span><span class="${can ? '' : 'dim'}"><kbd>G</kbd> maintenir : réapparaître à l'hôpital${d.fee > 0 ? ` — <b>${d.fee} $</b> (soins complets)` : ''}</span></div>
    <div class="d-hold"><i style="width:${Math.round((d.hold || 0) * 100)}%"></i></div></div>`;
  el.classList.remove('hidden');
}

function showAnnounce(a) {
  const el = document.getElementById('announce');
  const col = Array.isArray(a.color) ? a.color.join(',') : '';
  const official = !a.jobLabel;                                   // annonce du gouvernement : pas de métier / type
  const org = official ? a.title : a.jobLabel;
  const kind = official ? 'Annonce officielle' : (a.kindLabel || 'Annonce');
  const chipStyle = col ? ` style="color:rgb(${col});background:rgba(${col},.14);border-color:rgba(${col},.45)"` : '';
  const dur = Math.max(3, a.duration || 12);
  const initial = (String(a.author || '?').trim()[0] || '?').toUpperCase();
  el.innerHTML = `<div class="an-line"></div>
    <div class="an-ico">${ic('megaphone', 26)}</div>
    <div class="an-body">
      <div class="an-top"><span class="an-org">${esc(org)}</span><span class="an-kind"${chipStyle}>${esc(kind)}</span></div>
      ${official ? '' : `<h3>${esc(a.title)}</h3>`}
      <p>${esc(a.text)}</p>
      <div class="an-foot"><span class="an-av">${esc(initial)}</span><span>${esc(a.author)}</span></div>
    </div>
    <div class="an-bar"><i style="animation-duration:${dur}s"></i></div>`;
  el.classList.remove('hidden', 'out');
  void el.offsetWidth;                                            // relance l'animation d'entrée
  el.classList.add('in');
  clearTimeout(showAnnounce.t); clearTimeout(showAnnounce.t2);
  showAnnounce.t = setTimeout(() => {
    el.classList.remove('in'); el.classList.add('out');
    showAnnounce.t2 = setTimeout(() => el.classList.add('hidden'), 380);
  }, dur * 1000);
}

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
    if (t.path === 'job.blip.coords') t.root.job.blip.enabled = true;
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
  if (el.dataset.a === 'back') {         // retour au menu métier (F6) : sous-écran du menu, ou panneau ouvert depuis une action
    if (Mod === Runtime && Runtime.menuData && ['invoiceForm', 'serve', 'jobannounce', 'emscalls'].includes(Runtime.kind)) { Runtime.data = Runtime.menuData; Runtime.kind = 'menu'; return Runtime.render(); }
    return rpc('openJobMenu');
  }
  if (el.dataset.a === 'placeStart') return Placement.start(Mod);
  if (Mod && Mod.onA) Mod.onA(el, e);
});
document.addEventListener('input', e => { if (Mod && Mod.onInput && e.target.dataset.path) Mod.onInput(e.target, false); });
document.addEventListener('change', e => { if (Mod && Mod.onInput) Mod.onInput(e.target, true); });

window.addEventListener('message', e => {
  const d = e.data;
  if (d.action === 'oxygen') return showOxygen(d);
  if (d.action === 'oxygenHide') { document.getElementById('oxygen').classList.add('hidden'); return; }
  if (d.action === 'death') return showDeath(d);
  if (d.action === 'deathHide') { document.getElementById('death').classList.add('hidden'); return; }
  if (d.action === 'tuningResult') return Tuning.result(d);
  if (d.action === 'close') { $root.classList.add('hidden', 'x'); $root.classList.remove('tuning', 'x'); $root.innerHTML = ''; Placement.hide(); return; }
  if (d.action === 'placementSave') return Placement.save(d.coords);
  if (d.action === 'placementNav') return Placement.nav(d.dir);
  if (d.action === 'placementEnd') return Placement.end();
  if (d.action === 'announce') return showAnnounce(d);
  if (d.action === 'money') return liveMoney(d.job, d.money);
  if (d.action === 'theme') return applyTheme(d.accent);
  if (d.action !== 'open') return;
  if (d.theme) applyTheme(d.theme);
  window.JBBackFromMenu = !!d.back;
  window.JBBack = window.JBBackFromMenu && d.kind !== 'menu';
  const now = Date.now();
  if (!$root.classList.contains('hidden') && d.kind !== 'builder' && d.kind === (Mod && Mod.kind) && now - (window.__lastOpen || 0) < 600) return;   // double ouverture : ignorée
  window.__lastOpen = now;
  if ($root.classList.contains('hidden')) { $root.innerHTML = ''; $root.classList.add('fresh'); setTimeout(() => $root.classList.remove('fresh'), 260); }
  $root.classList.remove('hidden', 'corner');
  $root.classList.toggle('tuning', d.kind === 'tuning');
  Placement.hide();
  if (d.kind === 'builder') { Mod = Builder; Builder.open(); }
  else if (d.kind === 'agency') { Mod = Agency; Agency.open(d.data); }
  else if (d.kind === 'dealer') { Mod = Dealer; Dealer.open(d.data); }
  else if (d.kind === 'gov') { Mod = Gov; Gov.open(d.data); }
  else if (d.kind === 'tuning') { Mod = Tuning; Tuning.open(d.data, d.pointId); }
  else { Mod = Runtime; Runtime.open(d.kind, d.data, d.pointId); }
});

/* ════════════════════════════ BUILDER ════════════════════════════ */
const Builder = {
  catalog: null, jobs: [], cur: null, tab: 'general', activePoint: 0, loaded: false, draftType: 'police',

  async open() {
    if (!this.loaded) {
      this.catalog = await rpc('catalog');
      if (!this.catalog || !this.catalog.jobTypes) { toast('Accès refusé', 'err'); close(); return; }
      this.loaded = true;
    }
    await this.refreshList();
    this.render();
  },

  async refreshList() { const l = await rpc('list'); this.jobs = Array.isArray(l) ? l : []; },

  async select(name) {
    if (this.cur && this.cur.isNew) this.draft = this.cur;
    const r = await rpc('get', name);
    if (!r || !r.job) return toast('Job introuvable', 'err');
    r.isNew = false; this.page = null;
    r.grades = r.grades.map(g => ({ name: g.name, label: g.label, salary: g.salary }));
    r.job.blip = r.job.blip || {}; r.job.settings = r.job.settings || {}; r.job.settings.actions = r.job.settings.actions || [];
    r.points.forEach(p => { p.data = p.data || {}; });
    this.cur = r; this.tab = 'general'; this.activePoint = 0;
    this.render();
  },

  newJobDialog() {
    const types = this.catalog.jobTypes;
    const c = document.getElementById('confirm');
    c.innerHTML = `<div class="box" style="width:700px"><h2>Nouveau job</h2><p>Choisis un modèle : grades, blip et actions sont pré-remplis, tout reste modifiable.</p>
      <div class="grid4" style="margin-bottom:18px">${Object.entries(types).map(([k, t]) => `<div class="tpl ${k === this.draftType ? 'sel' : ''}" data-type="${k}">${tile(TYPE_ICON[k] || 'briefcase')}${esc(t.label)}</div>`).join('')}</div>
      <div class="grid2">${fld('Nom interne', '<input id="nj-name" placeholder="ex: lspd2, taxi_ls" maxlength="20">')}${fld('Label affiché', '<input id="nj-label" placeholder="Los Santos Police" maxlength="50">')}</div>
      <div class="row" style="margin-top:22px"><span class="spacer"></span><button id="nj-no">Annuler</button><button class="primary" id="nj-yes">Créer le brouillon</button></div></div>`;
    c.classList.remove('hidden');
    const closeDlg = () => { c.classList.add('hidden'); c.innerHTML = ''; };
    document.getElementById('nj-no').onclick = closeDlg;
    c.querySelectorAll('.tpl').forEach(el => el.onclick = () => { this.draftType = el.dataset.type; c.querySelectorAll('.tpl').forEach(t => t.classList.toggle('sel', t === el)); });
    document.getElementById('nj-yes').onclick = () => {
      const name = document.getElementById('nj-name').value.trim().toLowerCase();
      const label = document.getElementById('nj-label').value.trim();
      if (!/^[a-z][a-z0-9_]{1,19}$/.test(name)) return toast('Nom invalide : minuscules, chiffres, _ (2-20), commence par une lettre', 'err');
      if (!label) return toast('Label obligatoire', 'err');
      if (this.jobs.some(j => j.name === name)) return toast('Ce job existe déjà', 'err');
      closeDlg();
      this.create(name, label, this.draftType);
    };
  },

  create(name, label, type) {
    const t = this.catalog.jobTypes[type];
    this.cur = {
      isNew: true,
      job: {
        name, label, type, whitelisted: true, society: true, boss_grade: t.grades.length - 1,
        blip: { enabled: false, label, sprite: t.blip.sprite, color: t.blip.color, scale: (this.catalog.blipScale ?? t.blip.scale), coords: null },
        settings: { actions: [...t.actions], plate_prefix: name.replace(/[^a-z0-9]/g, '').slice(0, 3).toUpperCase(), commission: 10, prop_grade: 0, prop_admin_grade: t.grades.length - 1, dealer_commission: 10, dealer_sell_grade: 0, dealer_admin_grade: t.grades.length - 1, dealer_self_service: false, dealer_auto: true, dealer_markup: 100, dealer_categories: [], gov_grade: 0, gov_admin_grade: t.grades.length - 1, treasury: true, menu: [], ems_tablet_enabled: true, ems_tablet_grade: 0, ems_admin_grade: t.grades.length - 1, care_grade: 0, care_custom: true, bank_tablet_enabled: true, bank_tablet_grade: 0, bank_loan_grade: Math.min(2, t.grades.length - 1), bank_fee_grade: 0, bank_admin_grade: t.grades.length - 1, bank_loans: true, bank_ops: true, bank_funding: 'society', bank_loan_max: 100000, bank_rate_min: 0, bank_rate_max: 25, bank_fees: type === 'bank' ? clone((this.catalog.bank || {}).DefaultFees || []) : [], care_prices: type === 'ems' ? clone((this.catalog.ems || {}).DefaultCare || []) : [], tuning_grade: 0, tuning_billing: 'customer', tuning_markup: 100, tablet_enabled: true, tablet_grade: 0, tablet_admin_grade: t.grades.length - 1, tablet_records: true, tablet_dispatch: true, tablet_map: true, fine_grade: 0, fine_custom: true, pursuit_grade: 0, fines: type === 'police' ? clone((this.catalog.police || {}).DefaultFines || []) : [], announce_enabled: true, announce_grade: t.grades.length - 1, announce_cooldown: (this.catalog.announce || {}).Cooldown ?? 120, announce_cost: (this.catalog.announce || {}).Cost ?? 0, announce_radius: 0, announce_duration: (this.catalog.announce || {}).Duration ?? 12, announce_types: [], missions_enabled: true, missions_source: 'system', missions_mult: 100 },
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
    const active = this.page === 'settings' ? '__settings' : this.cur ? (this.cur.isNew ? '__new' : this.cur.job.name) : '__home';
    const draft = this.cur && this.cur.isNew ? this.cur : this.draft;
    const nav = [
      { label: 'Général', items: [{ id: '__home', icon: 'grid', text: 'Accueil' }, { id: '__settings', icon: 'sliders', text: 'Paramètres' }] },
      { label: 'Jobs', items: [...(draft ? [{ id: '__new', icon: TYPE_ICON[draft.job.type], text: draft.job.label + ' (brouillon)' }] : []),
        ...this.jobs.map(j => ({ id: j.name, icon: TYPE_ICON[j.type] || 'briefcase', text: j.label, count: j.online ? `${j.online} en ligne` : null }))] },
    ];
    const foot = `<button class="primary" data-a="newJob">${ic('plus', 16)} Nouveau job</button><small>Échap pour fermer : ton brouillon reste en mémoire (pratique pour relever des coordonnées).</small>`;
    const profile = { initials: 'JB', title: 'Job Builder', sub: 'Accès développeur' };
    const view = this.page === 'settings' ? this.renderSettings() : (this.cur ? this.renderJob() : this.renderHome());
    $root.innerHTML = dl + shellSide({ profile, nav, active, foot, head: view.head, body: view.body });
  },

  renderHome() {
    const pts = this.jobs.reduce((a, j) => a + j.points, 0), online = this.jobs.reduce((a, j) => a + j.online, 0);
    return {
      head: { icon: 'grid', title: 'Accueil', sub: 'Vue d\'ensemble des jobs créés avec le builder' },
      body: `<div class="grid4" style="margin-bottom:20px">
        ${[['Jobs', this.jobs.length], ['Points', pts], ['Joueurs en service', online], ['Modèles', Object.keys(this.catalog.jobTypes).length]].map(([l, v]) => `<div class="stat"><div class="eyebrow">${l}</div><div class="v">${v}</div></div>`).join('')}</div>
        <div class="eyebrow" style="margin-bottom:12px">Tes jobs</div>
        ${this.jobs.map(j => `<div class="item click" data-a="selectJob" data-v="${esc(j.name)}">${tile(TYPE_ICON[j.type] || 'briefcase')}<div class="grow"><b>${esc(j.label)}</b><small>${esc(j.name)} · ${j.grades} grades · ${j.points} points · ${j.online} en ligne</small></div>${j.society ? chip('Société', 'info') : ''}<span class="chev">${ic('chevron', 16)}</span></div>`).join('')
        || emptyState('briefcase', 'Aucun job', 'Crée ton premier job avec le bouton « Nouveau job ».')}`,
    };
  },

  renderJob() {
    const c = this.cur, j = c.job;
    const tabs = [['general', 'Général'], ['grades', `Grades · ${c.grades.length}`], ['points', `Points · ${c.points.length}`], ['blip', 'Blip']];
    const acts = (!c.isNew ? `<select id="test-grade" style="width:140px">${c.grades.map((g, i) => `<option value="${i}">${esc(g.label)}</option>`).join('')}</select><button data-a="testJob">Me mettre dans ce job</button><button class="danger" data-a="deleteJob">${ic('trash', 15)}</button>` : '')
      + `<button class="primary" data-a="save" style="height:38px">${c.isNew ? 'Créer le job' : 'Enregistrer'}</button>`;
    return {
      head: { icon: TYPE_ICON[j.type] || 'briefcase', title: j.label, sub: c.isNew ? 'Brouillon — non enregistré' : `${j.name} · ${(this.catalog.jobTypes[j.type] || {}).label || j.type}`, acts },
      body: `<div class="seg">${tabs.map(([k, l]) => `<button class="${this.tab === k ? 'active' : ''}" data-a="tab" data-v="${k}">${l}</button>`).join('')}</div>${this['tab_' + this.tab]()}`,
    };
  },

  placementTargets() {
    const out = [];
    if (this.page === 'settings' && this.S && this.S.sec === 'missions') {
      Object.keys(this.S.draft.missions.Locations).sort().forEach(k => out.push({ root: this, path: `S.draft.missions.Locations.${k}`, label: `Lieu « ${this.S.draft.missions.Locations[k].label} »` }));
      return out;
    }
    if (this.page === 'settings' && this.S && this.S.sec === 'interiors') {
      Object.keys(this.S.draft.interiors).sort().forEach(k => out.push({ root: this, path: `S.draft.interiors.${k}.exit`, label: `Intérieur « ${this.S.draft.interiors[k].label} » — sortie` }));
      return out;
    }
    if (!this.cur) return out;
    out.push({ root: this.cur, path: 'job.blip.coords', label: 'Blip du job (active le blip)' });
    this.cur.points.forEach((p, i) => {
      const name = p.label || this.catalog.pointTypes[p.type].label;
      out.push({ root: this.cur, path: `points.${i}.coords`, label: `${name} — marker` });
      if (p.type === 'garage') out.push({ root: this.cur, path: `points.${i}.data.spawn`, label: `${name} — sortie véhicules` });
      if (p.type === 'garage' && p.data.store) out.push({ root: this.cur, path: `points.${i}.data.store.coords`, label: `${name} — rangement` });
      if (p.type === 'showroom') out.push({ root: this.cur, path: `points.${i}.data.spawn`, label: `${name} — livraison` });
      if (p.type === 'missions') out.push({ root: this.cur, path: `points.${i}.data.spawn`, label: `${name} — départ des véhicules` });
      if (p.type === 'testdrive') out.push({ root: this.cur, path: `points.${i}.data.spawn`, label: `${name} — départ de l'essai` });
    });
    return out;
  },

  gradeSelect(path, value) {
    return `<select data-path="${path}" data-t="n">${this.cur.grades.map((g, i) => `<option value="${i}" ${Number(value) === i ? 'selected' : ''}>${i} · ${esc(g.label)}</option>`).join('')}</select>`;
  },

  tab_general() {
    const c = this.cur, j = c.job, acts = this.catalog.actions, s = j.settings;
    const realestate = j.type === 'realestate';
    return `<div class="grid2">
      <div class="card"><div class="card-h"><div class="t">${ic('briefcase', 16)} Identité</div></div>
        <div class="grid2">${fld('Nom interne', `<input value="${esc(j.name)}" disabled>`)}${fld('Label', `<input data-path="job.label" value="${esc(j.label)}" maxlength="50">`)}</div>
        <div class="grid2 mt">${fld('Type', `<input value="${esc((this.catalog.jobTypes[j.type] || {}).label || j.type)}" disabled>`)}${fld('Préfixe plaque (4 max)', `<input data-path="job.settings.plate_prefix" value="${esc(s.plate_prefix || '')}" maxlength="4">`)}</div>
        <div class="mt" style="display:flex;flex-direction:column;gap:12px">
          <label class="chk"><input type="checkbox" data-path="job.whitelisted" data-t="b" ${j.whitelisted ? 'checked' : ''}> Whitelist — le job ne peut pas être pris librement</label>
          <label class="chk"><input type="checkbox" data-path="job.society" data-t="b" ${j.society ? 'checked' : ''}> Compte société (society_${esc(j.name)})</label></div>
        <div class="mt">${fld('Grade minimum « boss » (accès gestion)', this.gradeSelect('job.boss_grade', j.boss_grade))}</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('list', 16)} Actions du menu métier (F6)</div></div>
        <div style="display:flex;flex-direction:column;gap:13px">${Object.entries(acts).filter(([id, a]) => !a.auto && (!a.types || j.type === 'custom' || a.types.includes(j.type))).map(([id, a]) => `<label class="chk"><input type="checkbox" data-a="toggleAction" data-v="${id}" ${s.actions.includes(id) ? 'checked' : ''}> ${esc(a.label)}</label>`).join('')}</div>
        <p class="hint mt">Seules les actions adaptées au type de job (<b>${esc((this.catalog.jobTypes[j.type] || {}).label || j.type)}</b>) sont proposées : menottes / escorte / fouille pour la police, réanimer / soigner pour les EMS, réparer / nettoyer pour les mécanos, vendre un produit pour les bars. Facturer est ouvert à tous (paiement vers la société). Les outils propres à un métier (tablette, missions, annonces…) s'ajoutent automatiquement.</p></div></div>
      ${s.actions.includes('serve') || j.type === 'bar' ? this.menuCard(s) : ''}
      ${j.type === 'police' || s.actions.includes('tablet') ? this.tabletCard(s) : ''}
      ${j.type === 'ems' || s.actions.includes('emstablet') ? this.emsCard(s) : ''}
      ${j.type === 'bank' ? this.bankCard(s) : ''}
      ${this.appearanceCard(s)}
      <div style="grid-column:1/-1;margin:14px 0">${this.jobMarkerCard(s)}</div>
      ${j.type === 'mecano' || c.points.some(p => p.type === 'tuning') ? this.tuningCard(s) : ''}
      ${this.announceCard(s)}
      <div class="card"><div class="card-h"><div class="t">${ic('route', 16)} Missions PNJ</div>${chip(s.missions_enabled === false ? 'Désactivées' : 'Activées', s.missions_enabled === false ? 'mute' : 'ok')}</div>
        <div class="grid3"><label class="chk" style="align-self:end;height:38px"><input type="checkbox" data-path="job.settings.missions_enabled" data-t="b" ${s.missions_enabled === false ? '' : 'checked'}> Activer les missions pour ce job</label>
        ${fld('Paiement des missions', `<select data-path="job.settings.missions_source"><option value="system" ${s.missions_source !== 'society' ? 'selected' : ''}>Créé par le serveur (gratuit pour la société)</option><option value="society" ${s.missions_source === 'society' ? 'selected' : ''}>Payé par le compte société</option></select>`)}
        ${num('job.settings.missions_mult', 'Multiplicateur de gains (%)', s.missions_mult ?? 100, 'min="10" max="300"')}</div>
        <p class="hint mt">Ajoute un point <b>Missions PNJ</b> dans l'onglet Points : les employés y choisissent une mission adaptée au métier (livraison, patrouille, urgence, dépannage, course…). Missions et lieux modifiables dans <b>Paramètres → Missions PNJ</b>. <b>F6 → Missions PNJ</b> permet de suivre ou d'annuler la mission en cours (ou <code>/missionstop</code>).</p></div>
      ${realestate ? `<div class="card"><div class="card-h"><div class="t">${ic('home', 16)} Agence immobilière</div>${chip('Gestion des propriétés activée', 'ok')}</div>
        <div class="grid3">${fld('Commission de l\'agent (%)', `<input type="number" min="0" max="50" data-path="job.settings.commission" data-t="n" value="${s.commission ?? 10}">`)}
        ${fld('Grade min. pour créer / vendre', this.gradeSelect('job.settings.prop_grade', s.prop_grade ?? 0))}
        ${fld('Grade min. pour supprimer / reprendre', this.gradeSelect('job.settings.prop_admin_grade', s.prop_admin_grade ?? c.grades.length - 1))}</div>
        <p class="hint mt">Les agents ouvrent la gestion immobilière via le menu <b>F6 → Gestion immobilière</b> : création de biens (intérieur, prix/loyer, coffres, penderies), vente et location aux joueurs, suivi des revenus. La commission est reversée à l'agent qui conclut, le reste va à la société.</p></div>` : ''}
      ${j.type === 'dealer' ? `<div class="card"><div class="card-h"><div class="t">${ic('car', 16)} Concession</div>${chip('Gestion concession activée', 'ok')}</div>
        <div class="grid4">${fld('Commission du vendeur (%)', `<input type="number" min="0" max="50" data-path="job.settings.dealer_commission" data-t="n" value="${s.dealer_commission ?? 10}">`)}
        ${fld('Grade min. pour vendre', this.gradeSelect('job.settings.dealer_sell_grade', s.dealer_sell_grade ?? 0))}
        ${fld('Grade min. catalogue / prix', this.gradeSelect('job.settings.dealer_admin_grade', s.dealer_admin_grade ?? c.grades.length - 1))}
        <label class="chk" style="align-self:end;height:38px"><input type="checkbox" data-path="job.settings.dealer_self_service" data-t="b" ${s.dealer_self_service ? 'checked' : ''}> Libre-service (achat sans vendeur)</label></div>
        <div class="grid3 mt"><label class="chk" style="align-self:end;height:38px"><input type="checkbox" data-path="job.settings.dealer_auto" data-t="b" ${s.dealer_auto === false ? '' : 'checked'}> Catalogue automatique : vendre tous les véhicules de la table <b>vehicles</b></label>
        ${num('job.settings.dealer_markup', 'Marge sur les prix de la table (%)', s.dealer_markup ?? 100, 'min="10" max="500"')}
        <p class="hint" style="align-self:end">100 % = prix de la table · 120 % = +20 %. Un prix modifié dans le panel prime sur la marge.</p></div>
        <div class="mt"><div class="lbl" style="margin-bottom:8px">Catégories vendues (aucune cochée = toutes)</div>
          <div class="row wrap">${(this.catalog.vehicleCategories || []).map(cat => `<label class="chk" style="padding:6px 10px;border:1px solid var(--line);border-radius:9px"><input type="checkbox" data-a="toggleCat" data-v="${esc(cat.name)}" ${(s.dealer_categories || []).includes(cat.name) ? 'checked' : ''}> ${esc(cat.label)}</label>`).join('') || '<span class="hint">Aucune catégorie lue dans la table vehicles.</span>'}</div></div>
        <p class="hint mt">Les vendeurs ouvrent <b>F6 → Gestion concession</b> : tout le catalogue est vendable tout de suite ; la direction ajuste les prix, stocks, grades ou masque un véhicule. Ajoute des points <b>Showroom</b> (catalogue + livraison), <b>Véhicule expo</b> et <b>Essai routier</b>.</p></div>` : ''}
      ${j.type === 'government' ? `<div class="card"><div class="card-h"><div class="t">${ic('landmark', 16)} Gouvernement</div>${chip('Gestion gouvernementale activée', 'ok')}</div>
        <div class="grid3">${fld('Grade min. pour accéder (annonces, journal)', this.gradeSelect('job.settings.gov_grade', s.gov_grade ?? 0))}
        ${fld('Grade min. trésor / taxes / subventions', this.gradeSelect('job.settings.gov_admin_grade', s.gov_admin_grade ?? c.grades.length - 1))}
        <label class="chk" style="align-self:end;height:38px"><input type="checkbox" data-path="job.settings.treasury" data-t="b" ${s.treasury !== false ? 'checked' : ''}> Trésor public (reçoit les taxes)</label></div>
        <p class="hint mt">F6 → <b>Gouvernement</b> : trésor, taxes (concession, immobilier, boutiques, factures), subventions aux sociétés, primes aux citoyens, annonces officielles. Le compte société du job sert de trésor (le premier job « trésor public » par ordre alphabétique).</p></div>` : ''}
      <div class="card"><div class="card-h"><div class="t">${ic('lock', 16)} Base de données</div></div><p class="hint">À l'enregistrement, le job est écrit dans <b>jobs</b>, <b>job_grades</b>${j.society ? ', <b>addon_account(_data)</b>, <b>addon_inventory</b>, <b>datastore</b>' : ''} et les tables <b>jobbuilder_*</b>. Aucun autre job n'est touché.</p></div>`;
  },

  tabletCard(s) {
    const c = this.cur, last = c.grades.length - 1;
    s.fines = s.fines || [];
    const gs = (k, def, l) => fld(l, this.gradeSelect('job.settings.' + k, s[k] ?? def));
    const chk = (k, l) => `<label class="chk"><input type="checkbox" data-path="job.settings.${k}" data-t="b" ${s[k] === false ? '' : 'checked'}> ${l}</label>`;
    return `<div class="card"><div class="card-h"><div class="t">${ic('tablet', 16)} Tablette (F6 → Tablette)</div>${chip(s.tablet_enabled === false ? 'Désactivée' : 'Activée', s.tablet_enabled === false ? 'mute' : 'ok')}</div>
      <p class="hint" style="margin-bottom:12px">Casiers, amendes, dispatch et carte en direct, <b>propres à ce job</b> : les données d'un autre service ne sont jamais visibles. Les citoyens appellent avec <b>/${(this.catalog.police || {}).CallCommand || 'appel'}</b>.</p>
      <div class="row wrap" style="gap:22px;margin-bottom:14px">${chk('tablet_enabled', 'Tablette activée')}${chk('tablet_records', 'Casiers')}${chk('tablet_dispatch', 'Dispatch')}${chk('tablet_map', 'Carte en direct')}${chk('fine_custom', 'Amendes libres autorisées')}</div>
      <div class="grid4">${gs('tablet_grade', 0, 'Grade min. pour ouvrir')}${gs('fine_grade', 0, 'Grade min. pour amender')}${gs('pursuit_grade', 0, 'Grade min. pour poursuivre')}${gs('tablet_admin_grade', last, 'Grade min. pour supprimer')}</div>
      <div class="lbl" style="margin:16px 0 8px">Catalogue d'amendes</div>
      ${s.fines.map((f, k) => `<div class="form-row" style="grid-template-columns:2fr 140px auto">${fld('Motif', `<input data-path="job.settings.fines.${k}.label" value="${esc(f.label)}" maxlength="60">`)}${fld('Montant ($)', `<input type="number" min="1" data-path="job.settings.fines.${k}.amount" data-t="n" value="${f.amount}">`)}<button class="icon danger" data-a="delRow" data-v="job.settings.fines" data-k="${k}">${ic('trash', 15)}</button></div>`).join('')}
      <div class="row"><button class="sm" data-a="addRow" data-v="job.settings.fines" data-tpl="fine">${ic('plus', 14)} Amende</button><button class="sm" data-a="fineDefaults">Charger le catalogue par défaut</button></div></div>`;
  },

  bankCard(s) {
    const c = this.cur, last = c.grades.length - 1, B = this.catalog.bank || {};
    s.bank_fees = s.bank_fees || [];
    const chk = (k, l) => `<label class="chk"><input type="checkbox" data-path="job.settings.${k}" data-t="b" ${s[k] === false ? '' : 'checked'}> ${l}</label>`;
    const num = (k, l, min, max, def) => fld(l, `<input type="number" min="${min}" max="${max}" data-path="job.settings.${k}" data-t="n" value="${s[k] ?? def}">`);
    return `<div class="card"><div class="card-h"><div class="t">${ic('landmark', 16)} Banque (F6 → Tablette bancaire)</div>${chip(s.bank_tablet_enabled === false ? 'Désactivée' : 'Activée', s.bank_tablet_enabled === false ? 'mute' : 'ok')}</div>
      <p class="hint" style="margin-bottom:12px">Tableau de bord, fiches clients (cote, notes), <b>prêts</b> (offre acceptée par le client, remboursement automatique sur son compte bancaire), guichet dépôt/retrait avec accord du client, frais et services. Les prêts demandent un <b>compte société</b>.</p>
      <div class="row wrap" style="gap:22px;margin-bottom:14px">${chk('bank_tablet_enabled', 'Tablette activée')}${chk('bank_loans', 'Prêts autorisés')}${chk('bank_ops', 'Guichet (dépôt / retrait)')}</div>
      <div class="grid4">${fld('Grade min. pour ouvrir', this.gradeSelect('job.settings.bank_tablet_grade', s.bank_tablet_grade ?? 0))}${fld('Grade min. pour accorder un prêt', this.gradeSelect('job.settings.bank_loan_grade', s.bank_loan_grade ?? Math.min(2, last)))}${fld('Grade min. guichet & frais', this.gradeSelect('job.settings.bank_fee_grade', s.bank_fee_grade ?? 0))}${fld('Grade min. annuler / supprimer', this.gradeSelect('job.settings.bank_admin_grade', s.bank_admin_grade ?? last))}</div>
      <div class="grid4 mt">${num('bank_loan_max', 'Prêt maximum ($)', B.MinLoan ?? 500, B.MaxLoan ?? 2000000, 100000)}${num('bank_rate_min', 'Intérêt min. (%)', 0, B.MaxRate ?? 60, 0)}${num('bank_rate_max', 'Intérêt max. (%)', 0, B.MaxRate ?? 60, 25)}${fld('Origine de l\'argent prêté', `<select data-path="job.settings.bank_funding"><option value="society" ${s.bank_funding !== 'system' ? 'selected' : ''}>Compte de la société</option><option value="system" ${s.bank_funding === 'system' ? 'selected' : ''}>Créé par le serveur</option></select>`)}</div>
      <p class="hint mt">Échéance toutes les ${B.IntervalHours ?? 24} h, pénalité ${B.LateFeePct ?? 5} %, défaut après ${B.DefaultAfter ?? 5} impayés (réglages globaux : <code>Config.Bank</code> dans config.lua).</p>
      <div class="lbl" style="margin:16px 0 8px">Frais &amp; services (catalogue)</div>
      ${s.bank_fees.map((f, k) => `<div class="form-row" style="grid-template-columns:2fr 140px auto">${fld('Service', `<input data-path="job.settings.bank_fees.${k}.label" value="${esc(f.label)}" maxlength="60">`)}${fld('Prix ($)', `<input type="number" min="1" data-path="job.settings.bank_fees.${k}.amount" data-t="n" value="${f.amount}">`)}<button class="icon danger" data-a="delRow" data-v="job.settings.bank_fees" data-k="${k}">${ic('trash', 15)}</button></div>`).join('')}
      <div class="row"><button class="sm" data-a="addRow" data-v="job.settings.bank_fees" data-tpl="bankfee">${ic('plus', 14)} Service</button><button class="sm" data-a="bankDefaults">Charger le catalogue par défaut</button></div></div>`;
  },

  emsCard(s) {
    const c = this.cur, last = c.grades.length - 1;
    s.care_prices = s.care_prices || [];
    const chk = (k, l) => `<label class="chk"><input type="checkbox" data-path="job.settings.${k}" data-t="b" ${s[k] === false ? '' : 'checked'}> ${l}</label>`;
    return `<div class="card"><div class="card-h"><div class="t">${ic('cross', 16)} Tablette médicale (F6 → Tablette médicale)</div>${chip(s.ems_tablet_enabled === false ? 'Désactivée' : 'Activée', s.ems_tablet_enabled === false ? 'mute' : 'ok')}</div>
      <p class="hint" style="margin-bottom:12px">Urgences en direct, dossiers patients, facturation des soins, équipe et statistiques, <b>propres à ce job</b>. Les patients inconscients appellent les EMS avec <b>E</b> (système de mort : Paramètres → Mort &amp; EMS).</p>
      <div class="row wrap" style="gap:22px;margin-bottom:14px">${chk('ems_tablet_enabled', 'Tablette activée')}${chk('care_custom', 'Soins libres autorisés')}</div>
      <div class="grid3">${fld('Grade min. pour ouvrir', this.gradeSelect('job.settings.ems_tablet_grade', s.ems_tablet_grade ?? 0))}${fld('Grade min. pour facturer un soin', this.gradeSelect('job.settings.care_grade', s.care_grade ?? 0))}${fld('Grade min. pour supprimer', this.gradeSelect('job.settings.ems_admin_grade', s.ems_admin_grade ?? last))}</div>
      <div class="lbl" style="margin:16px 0 8px">Tarifs des soins</div>
      ${s.care_prices.map((f, k) => `<div class="form-row" style="grid-template-columns:2fr 140px auto">${fld('Soin', `<input data-path="job.settings.care_prices.${k}.label" value="${esc(f.label)}" maxlength="60">`)}${fld('Prix ($)', `<input type="number" min="1" data-path="job.settings.care_prices.${k}.amount" data-t="n" value="${f.amount}">`)}<button class="icon danger" data-a="delRow" data-v="job.settings.care_prices" data-k="${k}">${ic('trash', 15)}</button></div>`).join('')}
      <div class="row"><button class="sm" data-a="addRow" data-v="job.settings.care_prices" data-tpl="care">${ic('plus', 14)} Soin</button><button class="sm" data-a="careDefaults">Charger les tarifs par défaut</button></div></div>`;
  },

  // Une seule carte pour les markers du job : couleur en un clic + options avancées (forme, taille, animation) repliées
  jobMarkerCard(s) {
    const mk = s.marker && s.marker.color, m = s.marker, types = this.catalog.pointTypes || {};
    const presets = [['Rouge', [239, 68, 68]], ['Orange', [249, 115, 22]], ['Jaune', [250, 204, 21]], ['Vert', [34, 197, 94]], ['Turquoise', [64, 224, 208]], ['Bleu', [59, 130, 246]], ['Violet', [168, 85, 247]], ['Rose', [236, 72, 153]]];
    const base = Object.values(types)[0] || {};
    const adv = this.markerEditor('job.settings.marker', m || {}, 'Markers du job', false, base, { bare: true, noColor: true });
    return `<div class="card"><div class="card-h"><div class="t">${ic('target', 16)} Markers du job</div>${chip(m && Object.keys(m).length ? 'Personnalisés' : 'Style global', m && Object.keys(m).length ? 'ok' : 'mute')}</div>
      <p class="hint" style="margin-bottom:12px">Apparence de <b>tous les markers de ce job</b> (garage, coffre, boss…), sans toucher à chaque point. Chaque point peut garder son propre style (en bas de son éditeur, onglet Points).</p>
      <div class="lbl" style="margin-bottom:8px">Couleur</div>
      ${mk ? `<div class="row wrap" style="gap:10px"><input type="color" data-path="job.settings.marker.color" data-t="c" value="${rgbHex(mk)}" style="width:64px;height:38px;padding:0;border-radius:8px">${presets.map(([n, c]) => `<button class="swatch-pick ${c.join() === mk.join() ? 'on' : ''}" title="${n}" data-a="mkPick" data-v="${c.join(',')}" style="background:rgb(${c.join(',')})"></button>`).join('')}<button class="sm" data-a="mkOff">Couleur globale</button></div>`
        : `<button class="sm" data-a="mkOn">${ic('edit', 14)} Choisir une couleur de markers pour ce job</button>`}
      <details class="mt"${m && Object.keys(m).some(k => k !== 'color') ? ' open' : ''}><summary style="cursor:pointer;color:var(--text-2);font-weight:600;margin-bottom:12px">Forme, taille, animation (options avancées)</summary>${adv}
        ${m && Object.keys(m).length ? `<div class="row mt"><button class="sm danger" data-a="styleOff" data-v="job.settings.marker">Tout remettre au style global</button></div>` : ''}</details></div>`;
  },

  appearanceCard(s) {
    const acc = s.ui_accent, presets = [['Rouge', [239, 68, 68]], ['Orange', [249, 115, 22]], ['Jaune', [250, 204, 21]], ['Vert', [34, 197, 94]], ['Turquoise', [64, 224, 208]], ['Bleu', [59, 130, 246]], ['Violet', [168, 85, 247]], ['Rose', [236, 72, 153]]];
    return `<div class="card"><div class="card-h"><div class="t">${ic('sliders', 16)} Apparence du job</div>${chip(acc ? 'Couleur propre au job' : 'Couleur globale', acc ? 'ok' : 'mute')}</div>
      <p class="hint" style="margin-bottom:12px">Couleur des <b>menus de ce job</b> (F6, boss, tablette, atelier…) vue par ses employés, indépendante des autres jobs et de la couleur globale (Paramètres → Apparence). Les markers du job se règlent juste en dessous ; le style d'un point précis, en bas de son éditeur (onglet Points).</p>
      <div class="lbl" style="margin-bottom:8px">Couleur des menus</div>
      ${acc ? `<div class="row wrap" style="gap:10px"><input type="color" data-path="job.settings.ui_accent" data-t="c" value="${rgbHex(acc)}" style="width:64px;height:38px;padding:0;border-radius:8px">${presets.map(([n, c]) => `<button class="swatch-pick ${c.join() === acc.join() ? 'on' : ''}" title="${n}" data-a="accentPick" data-v="${c.join(',')}" style="background:rgb(${c.join(',')})"></button>`).join('')}<button class="sm" data-a="accentOff">Utiliser la couleur globale</button></div>`
        : `<button class="sm" data-a="accentOn">${ic('edit', 14)} Choisir une couleur pour ce job</button>`}
</div>`;
  },

  tuningCard(s) {
    return `<div class="card"><div class="card-h"><div class="t">${ic('wrench', 16)} Atelier tuning</div>${chip(this.cur.points.some(p => p.type === 'tuning') ? 'Point atelier placé' : 'Ajoute un point « Atelier tuning »', this.cur.points.some(p => p.type === 'tuning') ? 'ok' : 'warn')}</div>
      <div class="grid3">${fld('Grade min. pour utiliser l\'atelier', this.gradeSelect('job.settings.tuning_grade', s.tuning_grade ?? 0))}
        ${fld('Facturation', `<select data-path="job.settings.tuning_billing"><option value="customer" ${(s.tuning_billing || 'customer') === 'customer' ? 'selected' : ''}>Facturé au client (argent → société)</option><option value="society" ${s.tuning_billing === 'society' ? 'selected' : ''}>Payé par la société</option><option value="free" ${s.tuning_billing === 'free' ? 'selected' : ''}>Gratuit</option></select>`)}
        ${num('job.settings.tuning_markup', 'Majoration sur les prix (%)', s.tuning_markup ?? 100, 'min="10" max="500"')}</div>
      <p class="hint mt">100 % = prix de base (Paramètres → Tuning). Les modifications sont enregistrées dans <b>owned_vehicles</b> pour les véhicules possédés par un joueur.</p></div>`;
  },

  announceCard(s) {
    const c = this.cur, types = this.catalog.announceTypes || [], ann = (this.catalog.announce || {});
    s.announce_types = s.announce_types || [];
    return `<div class="card"><div class="card-h"><div class="t">${ic('megaphone', 16)} Annonces d'entreprise (F6 → Annonce entreprise)</div>${chip(s.announce_enabled === false ? 'Désactivées' : 'Activées', s.announce_enabled === false ? 'mute' : 'ok')}</div>
      <p class="hint" style="margin-bottom:12px">Un employé diffuse un bandeau à l'écran des joueurs (recrutement, promotion, événement…). Les joueurs peuvent masquer les annonces avec <b>/${ann.ToggleCommand || 'annonces'}</b>.</p>
      <div class="grid4"><label class="chk" style="align-self:end;height:38px"><input type="checkbox" data-path="job.settings.announce_enabled" data-t="b" ${s.announce_enabled === false ? '' : 'checked'}> Annonces activées</label>
        ${fld('Grade min. pour annoncer', this.gradeSelect('job.settings.announce_grade', s.announce_grade ?? c.grades.length - 1))}
        ${num('job.settings.announce_cooldown', 'Délai entre annonces (s)', s.announce_cooldown ?? ann.Cooldown ?? 120, 'min="0"')}
        ${num('job.settings.announce_cost', 'Coût par annonce ($, société)', s.announce_cost ?? ann.Cost ?? 0, 'min="0"')}</div>
      <div class="grid4 mt">${num('job.settings.announce_radius', 'Rayon de diffusion (m, 0 = tous)', s.announce_radius ?? 0, 'min="0"')}${num('job.settings.announce_duration', 'Durée d\'affichage (s)', s.announce_duration ?? ann.Duration ?? 12, 'min="3" max="60"')}</div>
      <div class="mt"><div class="lbl" style="margin-bottom:8px">Types autorisés (aucun coché = tous)</div><div class="row wrap">${types.map(t => `<label class="chk" style="padding:6px 10px;border:1px solid var(--line);border-radius:9px"><input type="checkbox" data-a="toggleAnnType" data-v="${esc(t.id)}" ${s.announce_types.includes(t.id) ? 'checked' : ''}> <span style="color:rgb(${(t.color || []).join(',')})">●</span> ${esc(t.label)}</label>`).join('')}</div></div></div>`;
  },

  menuCard(s) {
    s.menu = s.menu || [];
    return `<div class="card"><div class="card-h"><div class="t">${ic('utensils', 16)} Carte — vente directe aux clients</div>${chip(s.actions.includes('serve') ? 'Action « Vendre un produit » activée' : 'Coche « Vendre un produit » dans les actions F6', s.actions.includes('serve') ? 'ok' : 'bad nodot')}</div>
      <p class="hint" style="margin-bottom:12px">Chaîne simple : <b>Récolte</b> (potager, élevage…) → <b>Frigo</b> (point Coffre) → <b>Cuisine / Bar</b> (recettes) → vente. L'employé prépare le produit, puis <b>F6 → Vendre un produit</b> : il choisit un produit de cette carte, le client le plus proche reçoit l'offre et paie directement (argent → société).</p>
      ${s.menu.map((it, k) => `<div class="form-row" style="grid-template-columns:1.2fr 1.2fr 120px auto">
        ${fld('Produit (item)', `<input list="dl-items" data-path="job.settings.menu.${k}.name" data-item="job.settings.menu.${k}" value="${esc(it.name)}">`)}
        ${fld('Label', `<input data-path="job.settings.menu.${k}.label" value="${esc(it.label)}">`)}
        ${fld('Prix ($)', `<input type="number" min="1" data-path="job.settings.menu.${k}.price" data-t="n" value="${it.price}">`)}
        <button class="icon danger" data-a="delRow" data-v="job.settings.menu" data-k="${k}">${ic('trash', 15)}</button></div>`).join('')}
      <button class="sm" data-a="addRow" data-v="job.settings.menu" data-tpl="menu">${ic('plus', 14)} Produit à vendre</button></div>`;
  },

  tab_grades() {
    const g = this.cur.grades;
    return `<div class="card"><table><tr><th style="width:44px">#</th><th>Nom (interne)</th><th>Label</th><th style="width:140px">Salaire</th><th style="width:130px"></th></tr>
      ${g.map((x, i) => `<tr><td class="muted">${i}</td><td><input data-path="grades.${i}.name" value="${esc(x.name)}" maxlength="40"></td><td><input data-path="grades.${i}.label" value="${esc(x.label)}" maxlength="50"></td>
        <td><input type="number" min="0" data-path="grades.${i}.salary" data-t="n" value="${x.salary}"></td>
        <td><div class="row" style="gap:6px"><button class="icon" data-a="gradeUp" data-v="${i}">${ic('up', 15)}</button><button class="icon" data-a="gradeDown" data-v="${i}">${ic('down', 15)}</button><button class="icon danger" data-a="gradeDel" data-v="${i}">${ic('trash', 15)}</button></div></td></tr>`).join('')}</table>
      <div class="row mt"><button data-a="gradeAdd">${ic('plus', 15)} Ajouter un grade</button><span class="hint">L'ordre = niveau du grade (0 = plus bas) · 20 grades max.</span></div></div>`;
  },

  tab_blip() {
    const b = this.cur.job.blip;
    const status = b.enabled && !(b.coords && b.coords.x != null) ? chip('⚠ position manquante : le blip ne s\'affichera pas', 'bad nodot') : (b.enabled ? chip('Blip actif', 'ok') : chip('Désactivé', 'mute'));
    return BBMap.blipCard({ base: 'job.blip', b, title: 'Blip du job sur la carte', labelHint: 'Par défaut : nom du job', hint: status, defSprite: 478,
      extra: `<div class="mt">${coordField('job.blip.coords', b.coords, { tp: true })}</div>` });
  },


  tab_points() {
    const pts = this.cur.points, types = this.catalog.pointTypes, sel = pts[this.activePoint];
    return `<div class="pts"><div><button data-a="placeStart" style="width:100%;margin-bottom:10px">${ic('pin', 15)} Mode placement</button><div class="addgrid">${Object.entries(types).filter(([k, t]) => !t.hidden && this.pointAllowed(k)).map(([k, t]) => `<button class="sm" data-a="addPoint" data-v="${k}">${ic(POINT_ICON[k], 14)} ${esc(t.label)}</button>`).join('')}</div><p class="hint" style="margin-bottom:12px">Le menu se réduit : tu te déplaces librement et tu enregistres chaque position avec <b>Entrée</b>.</p>
      ${pts.map((p, i) => `<div class="pt ${i === this.activePoint ? 'active' : ''}" data-a="selPoint" data-v="${i}">${tile(p.type === 'garage' ? KIND_ICON[(p.data || {}).kind || 'car'] : POINT_ICON[p.type])}<div style="flex:1;min-width:0"><b>${esc(p.label || types[p.type].label)}</b><small>${esc(types[p.type].label)}${this.pointAllowed(p.type) ? '' : ' · ⚠ non disponible pour ce métier'}${p.type === 'garage' ? ' · ' + esc(((this.catalog.garageKinds || {})[(p.data || {}).kind || 'car'] || {}).label || '') : ''}${p.coords && p.coords.x != null ? '' : ' · ⚠ position manquante'}</small></div></div>`).join('') || '<p class="hint">Aucun point. Ajoute un garage, vestiaire, armurerie, coffre, boss ou boutique.</p>'}</div>
      <div>${sel ? this.pointEditor(sel, this.activePoint) : emptyState('pin', 'Aucun point sélectionné', 'Sélectionne ou ajoute un point à gauche.')}</div></div>
      <p class="hint" style="margin-top:14px">Style des markers de tout le job (forme, taille, animation) : onglet <b>Général → Apparence du job</b>. Chaque point peut en plus avoir son propre style, en bas de son éditeur.</p>`;
  },

  // Types de points réservés à certains métiers (même règle que le serveur)
  pointAllowed(type) {
    const rule = (this.catalog.pointRules || {})[type], jt = this.cur && this.cur.job.type;
    return !rule || jt === 'custom' || rule.includes(jt);
  },

  pointEditor(p, i) {
    const base = `points.${i}`, d = p.data, T = this.catalog.pointTypes[p.type];
    const rowDel = (path, k) => `<button class="icon danger" data-a="delRow" data-v="${path}" data-k="${k}">${ic('trash', 15)}</button>`;
    const addBtn = (path, tpl, label) => `<button class="sm" data-a="addRow" data-v="${path}" data-tpl="${tpl}">${ic('plus', 14)} ${label}</button>`;
    let body = '';
    if (p.type === 'garage') {
      const kind = d.kind || 'car', kinds = this.catalog.garageKinds || { car: { label: 'Voitures' } };
      const cats = (this.catalog.vehicleCategories || []).filter(c => ((this.catalog.categoryTypes || {})[c.name] || 'car') === kind);
      body = `<div class="card"><div class="card-h"><div class="t">${ic(KIND_ICON[kind], 16)} Type de garage</div></div>
        <div class="grid2">${fld('Type', `<select data-path="${base}.data.kind" data-t="s" data-kindsel="${i}">${Object.entries(kinds).map(([k, v]) => `<option value="${k}" ${kind === k ? 'selected' : ''}>${esc(v.label)}</option>`).join('')}</select>`)}
        <p class="hint" style="align-self:end">Les véhicules proposés et le rangement dépendent du type : un garage de bateaux n'accepte que des bateaux. Place la sortie dans l'eau pour les bateaux, sur une piste / un héliport pour les aéronefs.</p></div></div>
        <div class="card"><div class="card-h"><div class="t">Sortie des véhicules</div></div>${coordField(base + '.data.spawn', d.spawn, { tp: true })}</div>
        <div class="card"><div class="card-h"><div class="t">${ic('login', 16)} Rangement des véhicules</div>${d.store ? (d.store.coords && d.store.coords.x != null ? chip('Point de rangement placé', 'ok') : chip('⚠ position à placer', 'bad nodot')) : chip('⚠ obligatoire', 'bad nodot')}</div>
          ${d.store ? `<p class="hint" style="margin-bottom:12px">Le joueur arrive <b>au volant</b> sur ce marker et appuie sur <b>E</b> : le véhicule est rangé (type : ${esc((kinds[kind] || {}).label || '')}, comme le garage). Seuls les véhicules du service sont acceptés (plaque du job), sauf option contraire.</p>
            <div class="mb">${coordField(base + '.data.store.coords', d.store.coords, { tp: true })}</div>
            <div class="grid3 mt">${fld('Rayon du marker (m)', `<input type="number" min="2" max="20" step="0.5" data-path="${base}.data.store.radius" data-t="n" value="${d.store.radius ?? 5}">`)}
              <label class="chk" style="align-self:end;height:38px"><input type="checkbox" data-path="${base}.data.store.any" data-t="b" ${d.store.any ? 'checked' : ''}> Accepter tous les véhicules</label></div>`
            : `<p class="hint" style="margin-bottom:12px"><b>Obligatoire</b> : les véhicules ne se rangent plus depuis le menu du garage, uniquement à ce point de rangement (cour, parking, quai…). Il fait partie de ce garage.</p><button class="sm" data-a="storeOn" data-v="${i}">${ic('plus', 14)} Ajouter un point de rangement</button>`}</div>
        <div class="card"><div class="card-h"><div class="t">Véhicules (${(d.vehicles || []).length})</div></div>
          ${cats.length ? `<div class="row" style="margin-bottom:14px"><select id="gk-cat-${i}" style="max-width:260px">${cats.map(c => `<option value="${esc(c.name)}">${esc(c.label)}</option>`).join('')}</select><button class="sm" data-a="addCat" data-v="${i}">${ic('plus', 14)} Ajouter toute la catégorie</button></div>` : ''}
          ${(d.vehicles || []).map((v, k) => `<div class="form-row" style="grid-template-columns:1.2fr 1.2fr 1fr 80px auto">
          ${fld('Modèle', `<input list="dl-veh-${kind}" placeholder="ex: police" data-path="${base}.data.vehicles.${k}.model" data-veh="${base}.data.vehicles.${k}" value="${esc(v.model)}">`)}
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
        <p class="hint mt">Ce coffre est propre au job : aucun autre job ne peut l'ouvrir (id <b>jobbuilder_&lt;id du point&gt;</b>).</p></div>`;
    } else if (p.type === 'shop') {
      body = `<div class="card"><div class="card-h"><div class="t">Boutique</div></div><label class="chk" style="margin-bottom:14px"><input type="checkbox" data-path="${base}.data.public" data-t="b" ${d.public ? 'checked' : ''}> Publique — tout le monde peut acheter, l'argent va à la société</label>
        ${(d.items || []).map((it, k) => `<div class="form-row" style="grid-template-columns:1.2fr 1.2fr 110px 1fr auto">
          ${fld('Item', `<input list="dl-items" data-path="${base}.data.items.${k}.name" data-item="${base}.data.items.${k}" value="${esc(it.name)}">`)}
          ${fld('Label', `<input data-path="${base}.data.items.${k}.label" value="${esc(it.label)}">`)}
          ${fld('Prix ($)', `<input type="number" min="0" data-path="${base}.data.items.${k}.price" data-t="n" value="${it.price}">`)}
          ${fld('Grade min.', this.gradeSelect(`${base}.data.items.${k}.min_grade`, it.min_grade))}${rowDel(base + '.data.items', k)}</div>`).join('')}
        ${addBtn(base + '.data.items', 'shop', 'Article')}</div>`;
    } else if (p.type === 'garage_return') {
      const kinds = this.catalog.garageKinds || { car: { label: 'Voitures' } };
      body = `<div class="card"><div class="card-h"><div class="t">${ic('login', 16)} Rangement de véhicules</div></div>
        <div class="grid3">${fld('Type de véhicules rangés', `<select data-path="${base}.data.kind" data-t="s">${Object.entries(kinds).map(([k, v]) => `<option value="${k}" ${(d.kind || 'car') === k ? 'selected' : ''}>${esc(v.label)}</option>`).join('')}</select>`)}
          ${fld('Rayon du marker (m)', `<input type="number" min="2" max="20" step="0.5" data-path="${base}.data.radius" data-t="n" value="${d.radius ?? 5}">`)}
          <label class="chk" style="align-self:end;height:38px"><input type="checkbox" data-path="${base}.data.any" data-t="b" ${d.any ? 'checked' : ''}> Accepter tous les véhicules</label></div>
        <p class="hint mt">Un point <b>à part</b> du menu du garage : le joueur arrive au volant sur le marker et appuie sur <b>E</b>, le véhicule est rangé. Par défaut seuls les véhicules du service (plaque avec le préfixe du job) sont acceptés, pour ne jamais supprimer la voiture perso d'un joueur. Place-le où tu veux (parking, cour du poste, quai, piste…).</p></div>`;
    } else if (p.type === 'tuning') {
      body = `<div class="card"><div class="card-h"><div class="t">${ic('wrench', 16)} Atelier tuning</div></div><div style="max-width:260px">${fld('Rayon de recherche du véhicule (m)', `<input type="number" min="2" max="30" step="0.5" data-path="${base}.data.radius" data-t="n" value="${d.radius ?? ((this.catalog.tuning || {}).Radius || 6)}">`)}</div>
        <p class="hint mt">Le mécano gare le véhicule du client sur le marker (ou reste à son volant) et appuie sur <b>E</b> : la tablette s'ouvre avec aperçu en direct, caméra orbitale (glisser / molette) et devis. Facturation, grade minimum et majoration se règlent dans l'onglet <b>Général</b> du job ; les prix dans <b>Paramètres → Tuning</b>.</p></div>`;
    } else if (p.type === 'harvest') {
      body = `<div class="card"><div class="card-h"><div class="t">${ic('sprout', 16)} Récolte</div></div>
        <div class="grid4">${fld('Objet récolté (item)', `<input list="dl-items" placeholder="ex: tomato" data-path="${base}.data.name" data-item="${base}.data" value="${esc(d.name || '')}">`)}
        ${fld('Label', `<input data-path="${base}.data.label" value="${esc(d.label || '')}">`)}
        ${fld('Quantité par récolte', `<input type="number" min="1" max="${(this.catalog.kitchen || {}).MaxHarvest || 20}" data-path="${base}.data.count" data-t="n" value="${d.count ?? 1}">`)}
        ${fld('Durée (secondes)', `<input type="number" min="2" max="120" data-path="${base}.data.seconds" data-t="n" value="${d.seconds ?? 8}">`)}</div>
        <p class="hint mt">Un point = un objet (potager → tomates, élevage → viande…). Place plusieurs points pour plusieurs ingrédients. L'employé reste sur place pendant la récolte (X pour annuler).</p></div>`;
    } else if (p.type === 'kitchen') {
      body = `<div class="card"><div class="card-h"><div class="t">${ic('utensils', 16)} Recettes (${(d.recipes || []).length})</div></div>
        <p class="hint" style="margin-bottom:12px">Chaque recette transforme des ingrédients de l'inventaire de l'employé en produit fini (cuisson, préparation, cocktail…). Tu peux placer plusieurs points (cuisine, bar, four…) avec des recettes différentes.</p>
        ${(d.recipes || []).map((r, k) => `<div class="card" style="background:rgba(255,255,255,.02);margin-bottom:12px">
          <div class="form-row" style="grid-template-columns:1.2fr 1.2fr 70px 90px 1fr auto">
            ${fld('Produit fini (item)', `<input list="dl-items" placeholder="ex: burger" data-path="${base}.data.recipes.${k}.output.name" data-item="${base}.data.recipes.${k}.output" value="${esc((r.output || {}).name || '')}">`)}
            ${fld('Nom de la recette', `<input data-path="${base}.data.recipes.${k}.label" value="${esc(r.label || '')}">`)}
            ${fld('Qté', `<input type="number" min="1" max="100" data-path="${base}.data.recipes.${k}.output.count" data-t="n" value="${(r.output || {}).count ?? 1}">`)}
            ${fld('Durée (s)', `<input type="number" min="2" max="120" data-path="${base}.data.recipes.${k}.seconds" data-t="n" value="${r.seconds ?? 10}">`)}
            ${fld('Grade min.', this.gradeSelect(`${base}.data.recipes.${k}.min_grade`, r.min_grade))}${rowDel(base + '.data.recipes', k)}</div>
          <div class="lbl" style="margin:8px 0 6px">Ingrédients</div>
          ${(r.inputs || []).map((inp, m) => `<div class="form-row" style="grid-template-columns:1.2fr 1.2fr 80px auto">
            ${fld('Item', `<input list="dl-items" data-path="${base}.data.recipes.${k}.inputs.${m}.name" data-item="${base}.data.recipes.${k}.inputs.${m}" value="${esc(inp.name)}">`)}
            ${fld('Label', `<input data-path="${base}.data.recipes.${k}.inputs.${m}.label" value="${esc(inp.label)}">`)}
            ${fld('Qté', `<input type="number" min="1" max="100" data-path="${base}.data.recipes.${k}.inputs.${m}.count" data-t="n" value="${inp.count}">`)}${rowDel(base + '.data.recipes.' + k + '.inputs', m)}</div>`).join('')}
          ${addBtn(base + '.data.recipes.' + k + '.inputs', 'rin', 'Ingrédient')}</div>`).join('')}
        ${addBtn(base + '.data.recipes', 'recipe', 'Recette')}</div>`;
    } else if (p.type === 'missions') {
      body = `<div class="card"><div class="card-h"><div class="t">Missions PNJ</div></div><p class="hint" style="margin-bottom:12px">Les employés viennent ici choisir une mission. <b>Départ des véhicules</b> (optionnel) : où apparaissent les véhicules de mission (livraison…), sinon à côté du marker.</p>${coordField(base + '.data.spawn', d.spawn, { tp: true })}</div>`;
    } else if (p.type === 'showroom') {
      body = `<div class="card"><div class="card-h"><div class="t">Livraison des véhicules</div></div><p class="hint" style="margin-bottom:12px">Position où le véhicule apparaît après un achat. Le showroom est <b>public</b> : tout le monde voit le catalogue, les vendeurs vendent depuis ici.</p>${coordField(base + '.data.spawn', d.spawn, { tp: true })}</div>`;
    } else if (p.type === 'display') {
      body = `<div class="card"><div class="card-h"><div class="t">Véhicule exposé</div></div><div class="grid2">${fld('Modèle', `<input list="dl-veh" placeholder="ex: adder" data-path="${base}.data.model" data-veh2="1" value="${esc(d.model || '')}">`)}${fld('Couleur GTA (optionnel)', `<input type="number" min="0" max="160" data-path="${base}.data.color" data-t="n" value="${d.color ?? ''}">`)}</div><p class="hint mt">Le véhicule est affiché figé à la position et au cap du marker (cap = ta direction quand tu as pris la position). Appuyer sur E ouvre sa fiche.</p></div>`;
    } else if (p.type === 'testdrive') {
      body = `<div class="card"><div class="card-h"><div class="t">Essai routier</div></div>${coordField(base + '.data.spawn', d.spawn, { tp: true })}<div class="mt" style="max-width:240px">${fld('Durée (secondes)', `<input type="number" min="30" max="900" data-path="${base}.data.seconds" data-t="n" value="${d.seconds ?? 120}">`)}</div><p class="hint mt">Position de départ du véhicule d'essai. À la fin, le véhicule est supprimé et le client revient où il était.</p></div>`;
    } else if (p.type === 'boss') {
      body = `<div class="card"><div class="card-h"><div class="t">Gestion boss</div></div><p class="hint">Compte société, recrutement, promotion, licenciement, salaires, journal. Accessible à partir du grade « boss » défini dans l'onglet Général.</p></div>`;
    }
    return `<div class="card"><div class="card-h"><div class="t">${ic(POINT_ICON[p.type], 16)} ${esc(T.label)}</div><button class="sm danger" data-a="delPoint" data-v="${i}">${ic('trash', 14)} Supprimer</button></div>
      <div class="grid2">${fld('Nom du point', `<input data-path="${base}.label" value="${esc(p.label)}" maxlength="60">`)}${fld('Grade minimum', this.gradeSelect(base + '.min_grade', p.min_grade))}</div>
      <div class="mt"><div class="lbl" style="margin-bottom:6px">Position du marker</div>${coordField(base + '.coords', p.coords, { tp: true })}</div></div>${body}
      ${this.styleCard(base + '.data.style', 'Marker de ce point', { hint: 'Hérite du style du job, sinon du type de point. Personnalise pour ce point uniquement (couleur, forme, taille…).' })}`;
  },

  newRow(tpl) {
    return ({
      vehicle: { model: '', label: '', min_grade: 0 }, outfit: { label: 'Tenue', min_grade: 0, male: null, female: null },
      armory: { name: '', label: '', count: 1, ammo: 0, min_grade: 0 }, shop: { name: '', label: '', price: 10, min_grade: 0 },
      menu: { name: '', label: '', price: 10 }, bankfee: { label: '', amount: 100 }, fine: { label: '', amount: 100 }, care: { label: '', amount: 100 }, rin: { name: '', label: '', count: 1 },
      recipe: { label: '', seconds: 10, min_grade: 0, output: { name: '', label: '', count: 1 }, inputs: [{ name: '', label: '', count: 1 }] },
    })[tpl];
  },

  newPoint(type) {
    const data = { missions: { spawn: null }, showroom: { spawn: null }, display: { model: '', color: null }, testdrive: { spawn: null, seconds: 120 }, garage: { kind: 'car', spawn: null, vehicles: [], store: { coords: null, radius: 5, any: false } }, cloakroom: { outfits: [] }, armory: { items: [] }, stash: { slots: 50, weight: 100 }, boss: {}, shop: { public: false, items: [] }, harvest: { name: '', label: '', count: 1, seconds: 8 }, kitchen: { recipes: [] }, tuning: { radius: 6 }, garage_return: { kind: 'car', radius: 5, any: false } }[type];
    return { type, label: this.catalog.pointTypes[type].label, coords: null, min_grade: type === 'boss' ? this.cur.job.boss_grade : 0, data };
  },

  async save() {
    const c = this.cur;
    const r = await rpc('save', { job: c.job, grades: c.grades, points: c.points });
    if (!r || !r.ok) return toast((r && r.error) || 'Erreur', 'err');
    toast(r.created ? 'Job créé en base de données' : 'Job enregistré', 'ok');
    compatToast(r.compat);
    this.cur = null; this.draft = null;
    await this.refreshList();
    await this.select(r.name);
  },

  async remove() {
    const j = this.cur.job;
    if (!await confirmBox('Supprimer le job ?', `« ${j.label} » (${j.name}) sera supprimé de jobs, job_grades, société et points. Les joueurs deviennent chômeurs.`, 'Supprimer')) return;
    const r = await rpc('delete', j.name);
    if (!r || !r.ok) return toast((r && r.error) || 'Erreur', 'err');
    if (r.warning) toast(r.warning, 'err'); else toast('Job supprimé et nettoyé de la base de données', 'ok');
    compatToast(r.compat);
    this.cur = null; await this.refreshList(); this.render();
  },

  fixGrades() {
    const max = this.cur.grades.length - 1, j = this.cur.job;
    if (j.boss_grade > max) j.boss_grade = max;
    ['prop_grade', 'prop_admin_grade', 'dealer_sell_grade', 'dealer_admin_grade', 'gov_grade', 'gov_admin_grade'].forEach(k => { if (j.settings[k] > max) j.settings[k] = max; });
    this.cur.points.forEach(p => {
      if (p.min_grade > max) p.min_grade = max;
      (p.data.vehicles || []).concat(p.data.outfits || [], p.data.items || []).forEach(x => { if (x.min_grade > max) x.min_grade = max; });
    });
  },

  async onA(el) {
    const a = el.dataset.a, v = el.dataset.v, c = this.cur;
    if (this.settingsAction && await this.settingsAction(a, v, el)) return;
    switch (a) {
      case 'nav':
        if (v === '__settings') { if (c && c.isNew) { this.draft = c; this.cur = null; } return this.openSettings(); }
        if (v === '__home') { if (c && c.isNew) this.draft = c; this.cur = null; this.page = null; return this.render(); }
        if (v === '__new') { this.page = null; if (this.draft) { this.cur = this.draft; this.draft = null; this.tab = 'general'; } return this.render(); }
        return this.select(v);
      case 'newJob': return this.newJobDialog();
      case 'selectJob': return this.select(v);
      case 'tab': this.tab = v; return this.render();
      case 'save': return this.save();
      case 'deleteJob': return this.remove();
      case 'testJob': { const r = await rpc('setMyJob', c.job.name, Number(document.getElementById('test-grade').value)); return toast(r.ok ? 'Tu es maintenant dans ce job' : r.error, r.ok ? 'ok' : 'err'); }
      case 'addCat': {
        const p = c.points[+v], cat = document.getElementById('gk-cat-' + v).value;
        const have = new Set((p.data.vehicles || []).map(x => String(x.model).toLowerCase()));
        const room = Math.max(0, (this.catalog.maxItems || 100) - have.size);
        const add = (this.catalog.vehicles || []).filter(x => x.category === cat && !have.has(String(x.model).toLowerCase())).slice(0, room);
        p.data.vehicles = (p.data.vehicles || []).concat(add.map(x => ({ model: String(x.model).toLowerCase(), label: x.name, min_grade: 0 })));
        toast(add.length ? `${add.length} véhicule(s) ajouté(s)` : 'Rien à ajouter (déjà présents ou limite atteinte)', add.length ? 'ok' : 'err');
        return this.render();
      }
      case 'toggleCat': { const L = c.job.settings.dealer_categories = c.job.settings.dealer_categories || [], i = L.indexOf(v); if (i >= 0) L.splice(i, 1); else L.push(v); return; }
      case 'toggleAnnType': { const L = c.job.settings.announce_types = c.job.settings.announce_types || [], i = L.indexOf(v); if (i >= 0) L.splice(i, 1); else L.push(v); return; }
      case 'fineDefaults': c.job.settings.fines = clone((this.catalog.police || {}).DefaultFines || []); return this.render();
      case 'toggleAction': { const L = c.job.settings.actions, i = L.indexOf(v); if (i >= 0) L.splice(i, 1); else L.push(v); return; }
      case 'gradeAdd': if (c.grades.length >= 20) return toast('Maximum 20 grades', 'err'); c.grades.push({ name: 'grade' + c.grades.length, label: 'Nouveau grade', salary: 100 }); return this.render();
      case 'gradeDel': if (c.grades.length <= 1) return toast('Il faut au moins un grade', 'err'); c.grades.splice(+v, 1); this.fixGrades(); return this.render();
      case 'gradeUp': if (+v > 0) [c.grades[v - 1], c.grades[v]] = [c.grades[v], c.grades[v - 1]]; return this.render();
      case 'gradeDown': if (+v < c.grades.length - 1) [c.grades[+v + 1], c.grades[v]] = [c.grades[v], c.grades[+v + 1]]; return this.render();
      case 'addPoint': c.points.push(this.newPoint(v)); this.activePoint = c.points.length - 1; return this.render();
      case 'selPoint': this.activePoint = +v; return this.render();
      case 'styleOn': {      // initialise le style avec les valeurs actuelles du type de point (ou d'un marker standard pour un job)
        const ty = path => path.startsWith('points.') ? this.cur.points[+path.split('.')[1]].type : null, t = ty(v);
        const baseSt = (t && (this.catalog.pointTypes || {})[t]) || Object.values(this.catalog.pointTypes || {})[0] || {};
        setPath(this.cur, v, { marker: baseSt.marker ?? 25, color: [...(baseSt.color || [64, 224, 208])], alpha: baseSt.alpha ?? 140, scale: { ...(baseSt.scale || { x: 0.9, y: 0.9, z: 0.6 }) }, offset: baseSt.offset ?? -0.95, bob: !!baseSt.bob, rotate: !!baseSt.rotate, help: baseSt.help !== false });
        return this.render();
      }
      case 'storeOn': { const p = c.points[+v]; p.data.store = { coords: null, radius: 5, any: false }; return this.render(); }
      case 'storeOff': { delete c.points[+v].data.store; return this.render(); }
      case 'styleOff': setPath(this.cur, v, null); return this.render();
      case 'preview': await rpc('previewMarker', getPath(this.cur, v)); return toast('Aperçu affiché devant toi (8 s)');
      case 'mkOn': c.job.settings.marker = c.job.settings.marker || {}; c.job.settings.marker.color = [64, 224, 208]; return this.render();
      case 'mkPick': c.job.settings.marker = c.job.settings.marker || {}; c.job.settings.marker.color = v.split(',').map(Number); return this.render();
      case 'mkOff': { const m = c.job.settings.marker; if (m) { delete m.color; if (!Object.keys(m).length) c.job.settings.marker = null; } return this.render(); }
      case 'bankDefaults': c.job.settings.bank_fees = clone((this.catalog.bank || {}).DefaultFees || []); return this.render();
      case 'careDefaults': c.job.settings.care_prices = clone((this.catalog.ems || {}).DefaultCare || []); return this.render();
      case 'accentOn': c.job.settings.ui_accent = c.job.settings.ui_accent || [64, 224, 208]; return this.render();
      case 'accentOff': c.job.settings.ui_accent = null; return this.render();
      case 'accentPick': c.job.settings.ui_accent = v.split(',').map(Number); return this.render();
      case 'delPoint': c.points.splice(+v, 1); this.activePoint = Math.max(0, this.activePoint - 1); return this.render();
      case 'addRow': { const arr = getPath(c, v) || []; arr.push(this.newRow(el.dataset.tpl)); setPath(c, v, arr); return this.render(); }
      case 'delRow': getPath(c, v).splice(+el.dataset.k, 1); return this.render();
      case 'coords': await grabCoords(this.page === 'settings' ? this : c, v); if (v === 'job.blip.coords' && c) c.job.blip.enabled = true; return this.render();
      case 'tp': { const p = getPath(this.page === 'settings' ? this : c, v); if (p) rpc('teleport', p); return; }
      case 'capture': {
        const r = await rpc('captureOutfit'), o = getPath(c, v);
        o[r.sex === 'f' ? 'female' : 'male'] = r.clothes;
        toast(`Tenue ${r.sex === 'f' ? 'femme' : 'homme'} capturée`, 'ok'); return this.render();
      }
    }
  },

  async onInput(el, isChange) {
    const path = el.dataset.path; if (!path) return;
    const isS = path.startsWith('S.');
    if ((!this.cur && !isS) || el.closest('#confirm')) return;
    let val = el.value;
    if (el.dataset.t === 'b') val = el.checked;
    else if (el.dataset.t === 'n') val = val === '' ? null : Number(val);
    else if (el.dataset.t === 'c') val = hexRgb(val);
    else if (el.dataset.t === 'list') val = val.split(',').map(x => x.trim()).filter(Boolean);
    setPath(this, isS ? path : 'cur.' + path, val);
    if (path === 'S.draft.ui.Accent') applyTheme(val);
    if (isS) { if (isChange && (el.dataset.t === 'c' || el.dataset.t === 's')) this.render(); return; }
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
    if (el.dataset.veh2) {
      const m = String(el.value).toLowerCase(); setPath(this.cur, path, m);
      const r = await rpc('checkModel', m);
      if (!r.valid) toast(`Modèle « ${m} » introuvable dans le jeu`, 'err');
      return;
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
const clone = o => (o === undefined ? undefined : JSON.parse(JSON.stringify(o)));
const rgbHex = c => '#' + (c || [255, 255, 255]).map(n => Math.max(0, Math.min(255, Number(n) || 0)).toString(16).padStart(2, '0')).join('');
const hexRgb = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16));
const SET_TABS = [['general', 'Général'], ['pointTypes', 'Markers des points'], ['real', 'Immobilier'], ['interiors', 'Intérieurs'], ['dealer', 'Concession'], ['gov', 'Gouvernement'], ['missions', 'Missions PNJ'], ['police', 'Police'], ['announce', 'Annonces'], ['tuning', 'Tuning'], ['death', 'Mort & EMS'], ['jobTypes', 'Modèles de jobs'], ['ui', 'Apparence']];
const num = (path, label, v, extra = '') => fld(label, `<input type="number" step="any" data-path="${path}" data-t="n" value="${v ?? ''}" ${extra}>`);

Object.assign(Builder, {
  page: null, S: null,

  async openSettings() {
    const r = await rpc('settings:get');
    if (!r || !r.ok) return toast((r && r.error) || 'Accès refusé', 'err');
    const prev = this.S;
    this.S = { values: r.values, defaults: r.defaults, draft: {}, sec: prev ? prev.sec : 'general', jt: prev ? prev.jt : 'police' };
    SET_TABS.forEach(([k]) => { this.S.draft[k] = clone(r.values[k]); });
    const missing = SET_TABS.filter(([k]) => !r.values[k]).map(([, l]) => l);
    if (missing.length) toast(`Sections absentes côté serveur (${missing.join(', ')}) : mets à jour tous les fichiers du script puis refresh + restart pickax_jobbuilder`, 'err');
    SET_TABS.forEach(([k]) => { if (!this.S.draft[k]) this.S.draft[k] = {}; });
    this.page = 'settings';
    this.render();
  },

  renderSettings() {
    const S = this.S, sec = S.sec;
    const acts = `<button data-a="setReset">Réinitialiser cette section</button><button class="primary" data-a="setSave" style="height:38px">Enregistrer et appliquer</button>`;
    return {
      head: { icon: 'sliders', title: 'Paramètres', sub: 'Configuration du script — appliquée en direct à tous les joueurs', acts },
      body: `<div class="seg">${SET_TABS.map(([k, l]) => `<button class="${sec === k ? 'active' : ''}" data-a="setTab" data-v="${k}">${l}</button>`).join('')}</div>${this['set_' + sec]()}`,
    };
  },

  // Apparence propre à un job / à un point : case « personnaliser » + éditeur de marker (seuls les champs modifiés sont gardés, le reste est hérité)
  styleCard(path, title, base) {
    const d = getPath(this.cur, path);
    if (!d) return `<div class="card"><div class="card-h"><div class="t">${ic('target', 16)} ${esc(title)}</div>${chip('Hérité', 'mute')}</div>
      <p class="hint" style="margin-bottom:12px">${esc(base.hint)}</p><button class="sm" data-a="styleOn" data-v="${path}">${ic('edit', 14)} Personnaliser</button></div>`;
    const types = this.catalog.pointTypes || {}, m = path.match(/^points\.(\d+)\./), typeSt = m ? types[this.cur.points[+m[1]].type] : Object.values(types)[0];
    const inherited = Object.assign({}, typeSt || {}, m ? (this.cur.job.settings.marker || {}) : {});
    return this.markerEditor(path, d, title, false, inherited).replace('<button class="sm" data-a="preview"', `<button class="sm danger" data-a="styleOff" data-v="${path}" style="margin-right:8px">Revenir à l'héritage</button><button class="sm" data-a="preview"`);
  },

  markerEditor(path, d, title, withLabel, base, opts) {
    opts = opts || {};
    // `base` = style hérité : sert à afficher les valeurs effectives pour les champs non personnalisés (style « creux »)
    const own = d || {};
    d = Object.assign({}, base || {}, own);
    d.scale = Object.assign({ x: 0.9, y: 0.9, z: 0.6 }, (base || {}).scale || {}, own.scale || {});
    const sc = d.scale, hex = rgbHex(d.color);
    const known = MARKER_TYPES.some(([id]) => id === Number(d.marker));
    const head = opts.bare ? `<div class="row" style="justify-content:flex-end;margin-bottom:10px"><button class="sm" data-a="preview" data-v="${path}">${ic('target', 14)} Aperçu en jeu</button></div>` : `<div class="card-h"><div class="t"><span class="swatch" style="background:${hex}"></span>${esc(title)}</div><button class="sm" data-a="preview" data-v="${path}">${ic('target', 14)} Aperçu en jeu</button></div>`;
    const inner = `<div class="grid4">${withLabel ? fld('Nom affiché', `<input data-path="${path}.label" value="${esc(d.label || '')}" maxlength="40">`) : '<div></div>'}
        ${fld('Type de marker', `<select data-path="${path}.marker" data-t="n">${MARKER_TYPES.map(([id, n]) => `<option value="${id}" ${Number(d.marker) === id ? 'selected' : ''}>${id} · ${n}</option>`).join('')}${known ? '' : `<option value="${d.marker}" selected>${d.marker} · (personnalisé)</option>`}</select>`)}
        ${opts.noColor ? '<div></div>' : fld('Couleur', `<input type="color" data-path="${path}.color" data-t="c" value="${hex}">`)}
        ${num(path + '.alpha', 'Opacité (0-255)', d.alpha ?? 140, 'min="0" max="255"')}</div>
      <div class="grid4 mt">${num(path + '.scale.x', 'Taille X', sc.x, 'step="0.05" min="0.05"')}${num(path + '.scale.y', 'Taille Y', sc.y, 'step="0.05" min="0.05"')}${num(path + '.scale.z', 'Hauteur (Z)', sc.z, 'step="0.05" min="0.05"')}${num(path + '.offset', 'Décalage vertical', d.offset ?? -0.95, 'step="0.05"')}</div>
      <div class="row mt" style="gap:26px"><label class="chk"><input type="checkbox" data-path="${path}.bob" data-t="b" ${d.bob ? 'checked' : ''}> Rebond (monte et descend)</label><label class="chk"><input type="checkbox" data-path="${path}.rotate" data-t="b" ${d.rotate ? 'checked' : ''}> Rotation</label><label class="chk"><input type="checkbox" data-path="${path}.help" data-t="b" ${d.help !== false ? 'checked' : ''}> Aide « E »</label></div>`;
    return opts.bare ? head + inner : `<div class="card">${head}${inner}</div>`;
  },

  set_general() {
    const g = this.S.draft.general, b = 'S.draft.general';
    return `<div class="grid2"><div class="card"><div class="card-h"><div class="t">${ic('pin', 16)} Distances</div></div>
        <div class="grid2">${num(b + '.DrawDistance', 'Affichage des markers (m)', g.DrawDistance)}${num(b + '.InteractDistance', 'Interaction (m)', g.InteractDistance)}
        ${num(b + '.ServerDistance', 'Tolérance serveur (m)', g.ServerDistance)}${num(b + '.TargetDistance', 'Joueur → joueur (m)', g.TargetDistance)}</div>
        <p class="hint mt">La tolérance serveur est la distance maximale acceptée entre le joueur et un point (anti-triche).</p></div>
      <div class="card"><div class="card-h"><div class="t">${ic('list', 16)} Limites</div></div>
        <div class="grid2">${num(b + '.MaxGrades', 'Grades max par job', g.MaxGrades)}${num(b + '.MaxPoints', 'Points max par job', g.MaxPoints)}
        ${num(b + '.MaxItemsPerPoint', 'Objets max par point', g.MaxItemsPerPoint)}${num(b + '.PlatePrefixLength', 'Longueur préfixe plaque', g.PlatePrefixLength, 'min="1" max="4"')}</div></div></div>
      <div class="grid2"><div class="card"><div class="card-h"><div class="t">${ic('wrench', 16)} Actions métier</div></div>
        <div class="grid2">${num(b + '.ActionDuration.repair', 'Durée réparation (ms)', g.ActionDuration.repair)}${num(b + '.ActionDuration.clean', 'Durée nettoyage (ms)', g.ActionDuration.clean)}</div>
        <div class="mt">${fld('Event de réanimation (client)', `<input data-path="${b}.ReviveEvent" value="${esc(g.ReviveEvent)}" maxlength="80">`)}</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('lock', 16)} Accès & intégrations</div></div>
        ${fld('Groupes autorisés (séparés par des virgules)', `<input data-path="${b}.AllowedGroups" data-t="list" value="${esc((g.AllowedGroups || []).join(', '))}">`)}
        <div class="grid2 mt">${fld('Permission ACE (optionnel)', `<input data-path="${b}.AcePermission" value="${esc(g.AcePermission || '')}" maxlength="60">`)}
        ${fld('Inventaire', `<select data-path="${b}.Inventory">${['auto', 'ox', 'esx'].map(o => `<option value="${o}" ${g.Inventory === o ? 'selected' : ''}>${o === 'auto' ? 'Automatique' : o === 'ox' ? 'ox_inventory' : 'ESX'}</option>`).join('')}</select>`)}</div>
        <div class="mt">${fld('Webhook Discord (logs)', `<input data-path="${b}.Webhook" value="${esc(g.Webhook || '')}" maxlength="300" placeholder="https://discord.com/api/webhooks/…">`)}</div>
        <div class="mt">${fld('Ressources à redémarrer après un changement de job (ex : pickax_core)', `<input data-path="${b}.RestartResources" data-t="list" value="${esc((g.RestartResources || []).join(', '))}" placeholder="pickax_core, esx_society, esx_addonaccount">`)}</div>
        <p class="hint mt">Ton esx_society / esx_addonaccount charge les jobs et les comptes société <b>au démarrage</b> : sans redémarrage, un job créé en jeu provoque « Compte partagé introuvable ». Indique ici la ressource à redémarrer automatiquement. Tu ne peux pas retirer ton propre groupe de la liste. La touche F6 et les noms de commandes se changent dans <b>config.lua</b> (redémarrage requis).</p></div></div>`;
  },

  set_pointTypes() {
    const t = this.S.draft.pointTypes;
    return `<p class="hint" style="margin-bottom:14px">Apparence des markers des points de job (garage, vestiaire, armurerie…). « Aperçu en jeu » affiche le marker devant toi pendant 8 secondes.</p>` +
      Object.keys(t).map(k => this.markerEditor(`S.draft.pointTypes.${k}`, t[k], `${t[k].label} (${k})`, true)).join('');
  },

  set_real() {
    const r = this.S.draft.real, b = 'S.draft.real';
    const mk = { available: 'Porte — bien disponible', access: 'Porte — ta propriété / tes clés', noaccess: 'Porte — propriété occupée', exit: 'Sortie de l\'intérieur' };
    return `<div class="card"><div class="card-h"><div class="t">${ic('home', 16)} Règles</div></div>
        <div class="grid4">${num(b + '.RentDays', 'Durée d\'un loyer (jours)', r.RentDays)}${num(b + '.MaxRentAhead', 'Périodes payables d\'avance', r.MaxRentAhead)}${num(b + '.MaxPerPlayer', 'Biens max par joueur', r.MaxPerPlayer)}${num(b + '.MaxKeys', 'Doubles de clés max', r.MaxKeys)}</div>
        <div class="grid4 mt">${num(b + '.MaxPointsPerProp', 'Points max par bien', r.MaxPointsPerProp)}${num(b + '.OutfitsPerPlayer', 'Tenues max / joueur', r.OutfitsPerPlayer)}${num(b + '.DefaultCommission', 'Commission par défaut (%)', r.DefaultCommission)}${num(b + '.RentCheckMinutes', 'Vérif. loyers (min)', r.RentCheckMinutes)}</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('pin', 16)} Blips des biens disponibles</div></div>
        <label class="chk" style="margin-bottom:14px"><input type="checkbox" data-path="${b}.ShowBlips" data-t="b" ${r.ShowBlips ? 'checked' : ''}> Afficher les blips « à vendre / à louer »</label>
        <div class="grid2">${['sale', 'rent'].map(k => `<div><div class="lbl" style="margin-bottom:8px">${k === 'sale' ? 'À vendre' : 'À louer'}</div><div class="grid3">${num(`${b}.Blips.${k}.sprite`, 'Sprite', r.Blips[k].sprite)}${num(`${b}.Blips.${k}.color`, 'Couleur', r.Blips[k].color)}${num(`${b}.Blips.${k}.scale`, 'Taille', r.Blips[k].scale, 'step="0.05"')}</div></div>`).join('')}</div></div>
      ${Object.keys(mk).map(k => this.markerEditor(`${b}.Markers.${k}`, r.Markers[k], mk[k], false)).join('')}
      ${Object.keys(r.PointTypes).map(k => this.markerEditor(`${b}.PointTypes.${k}`, r.PointTypes[k], `Intérieur — ${r.PointTypes[k].label}`, true)).join('')}`;
  },

  set_missions() {
    const S = this.S, m = S.draft.missions, b = 'S.draft.missions';
    const types = [...new Set([...Object.keys(m.Templates), ...Object.keys(this.catalog.jobTypes)])].sort();
    if (!S.mt || !types.includes(S.mt)) S.mt = types[0];
    const list = m.Templates[S.mt] = m.Templates[S.mt] || [];
    if (S.mi == null || S.mi >= list.length) S.mi = 0;
    const t = list[S.mi], tb = `${b}.Templates.${S.mt}.${S.mi}`;
    const STEP_T = [['spawn_vehicle', 'Véhicule à conduire / en panne'], ['goto', 'Se rendre à un lieu'], ['interact', 'Interagir (animation + PNJ)'], ['pickup_npc', 'Prendre un client (taxi)'], ['dropoff_npc', 'Déposer le client']];
    const ANIMS = [['give', 'Remise (poignée de main)'], ['work', 'Travail manuel'], ['repair', 'Réparation'], ['heal', 'Soins'], ['inspect', 'Inspection (carnet)'], ['talk', 'Discussion']];
    const steps = !t ? '' : t.steps.map((st, i) => `<div class="cat-row" style="grid-template-columns:1.3fr 1.5fr 70px 100px;align-items:end">
        ${fld('Étape ' + (i + 1), `<select data-path="${tb}.steps.${i}.t" data-t="s">${STEP_T.map(([k, l]) => `<option value="${k}" ${st.t === k ? 'selected' : ''}>${l}</option>`).join('')}</select>`)}
        ${fld('Consigne affichée', `<input data-path="${tb}.steps.${i}.label" value="${esc(st.label)}" maxlength="60">`)}
        ${num(`${tb}.steps.${i}.secs`, 'Durée (s)', st.secs ?? 5, 'min="1" max="120"')}
        <div class="row" style="gap:6px;justify-content:flex-end"><button class="icon" data-a="mStepUp" data-v="${i}">${ic('up', 14)}</button><button class="icon" data-a="mStepDown" data-v="${i}">${ic('down', 14)}</button><button class="icon danger" data-a="mStepDel" data-v="${i}">${ic('trash', 14)}</button></div>
        <div style="grid-column:1/-1" class="row wrap" data-x="1">
          ${fld('Lieu', `<select data-path="${tb}.steps.${i}.where"><option value="loc" ${st.where !== 'start' ? 'selected' : ''}>Lieu tiré au hasard</option><option value="start" ${st.where === 'start' ? 'selected' : ''}>Point « Missions PNJ »</option></select>`)}
          ${st.t === 'interact' ? fld('Animation', `<select data-path="${tb}.steps.${i}.anim">${ANIMS.map(([k, l]) => `<option value="${k}" ${st.anim === k ? 'selected' : ''}>${l}</option>`).join('')}</select>`) : ''}
          <label class="chk"><input type="checkbox" data-path="${tb}.steps.${i}.same" data-t="b" ${st.same ? 'checked' : ''}> Même lieu que l'étape précédente</label>
          ${st.t === 'goto' ? `<label class="chk"><input type="checkbox" data-path="${tb}.steps.${i}.veh" data-t="b" ${st.veh ? 'checked' : ''}> Doit être dans le véhicule</label>` : ''}
          ${st.t === 'interact' ? `<label class="chk"><input type="checkbox" data-path="${tb}.steps.${i}.npc" data-t="b" ${st.npc !== false ? 'checked' : ''}> PNJ présent</label><label class="chk"><input type="checkbox" data-path="${tb}.steps.${i}.patient" data-t="b" ${st.patient ? 'checked' : ''}> PNJ blessé</label><label class="chk"><input type="checkbox" data-path="${tb}.steps.${i}.consume" data-t="b" ${st.consume ? 'checked' : ''}> Le véhicule est livré (supprimé)</label>` : ''}
          ${st.t === 'spawn_vehicle' ? `<label class="chk"><input type="checkbox" data-path="${tb}.steps.${i}.broken" data-t="b" ${st.broken ? 'checked' : ''}> Véhicule en panne</label>` : ''}</div></div>`).join('');
    return `<div class="card"><div class="card-h"><div class="t">${ic('route', 16)} Réglages généraux</div></div>
        <label class="chk" style="margin-bottom:14px"><input type="checkbox" data-path="${b}.Enabled" data-t="b" ${m.Enabled ? 'checked' : ''}> Missions PNJ activées sur le serveur (interrupteur général ; chaque job a aussi le sien)</label>
        <div class="grid4">${num(b + '.Cooldown', 'Délai entre missions (s)', m.Cooldown)}${num(b + '.MinSeconds', 'Durée minimale (s, anti-triche)', m.MinSeconds)}${num(b + '.Tolerance', 'Tolérance de position (m)', m.Tolerance)}
        ${fld('Compte crédité (paiement serveur)', `<select data-path="${b}.RewardAccount"><option value="money" ${m.RewardAccount === 'money' ? 'selected' : ''}>Argent liquide</option><option value="bank" ${m.RewardAccount === 'bank' ? 'selected' : ''}>Banque</option></select>`)}</div>
        <div class="grid3 mt">${num(b + '.TimeBonus', 'Bonus si dans les temps (%)', m.TimeBonus)}${num(b + '.DamageMaxPenalty', 'Pénalité max véhicule abîmé (%)', m.DamageMaxPenalty)}
        ${fld('Modèles de PNJ (séparés par des virgules)', `<input data-path="${b}.Peds" data-t="list" value="${esc((m.Peds || []).join(', '))}">`)}</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('pin', 16)} Lieux de mission (${Object.keys(m.Locations).length})</div><button class="sm" data-a="placeStart">${ic('pin', 14)} Mode placement</button></div>
        <p class="hint" style="margin-bottom:12px">Les destinations sont tirées au hasard dans cette liste. Le sol est détecté automatiquement. Place-toi à l'endroit voulu puis « Ma position ».</p>
        ${Object.keys(m.Locations).sort().map(k => `<div class="card" style="padding:12px;margin-bottom:8px"><div class="row" style="margin-bottom:10px"><div style="flex:1;max-width:320px">${fld('Lieu (' + k + ')', `<input data-path="${b}.Locations.${k}.label" value="${esc(m.Locations[k].label)}" maxlength="50">`)}</div><span class="spacer"></span><button class="icon danger" data-a="mLocDel" data-v="${esc(k)}">${ic('trash', 15)}</button></div>${coordField(`${b}.Locations.${k}`, m.Locations[k], { tp: true })}</div>`).join('')}
        <div class="row mt"><input id="ml-key" placeholder="nouvelle clé (ex: vinewood)" maxlength="24" style="max-width:260px"><button data-a="mLocAdd">${ic('plus', 15)} Ajouter un lieu</button></div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('briefcase', 16)} Missions par type de job</div></div>
        <div class="row wrap" style="margin-bottom:14px">${types.map(k => `<button class="sm ${k === S.mt ? 'primary' : ''}" data-a="mType" data-v="${esc(k)}">${esc((this.catalog.jobTypes[k] || {}).label || k)}${(m.Templates[k] || []).length ? ` · ${(m.Templates[k] || []).length}` : ''}</button>`).join('')}</div>
        <div class="pts"><div>${list.map((x, i) => `<div class="pt ${i === S.mi ? 'active' : ''}" data-a="mTplSel" data-v="${i}">${tile('route')}<div style="flex:1;min-width:0"><b>${esc(x.label)}</b><small>${x.steps.length} étapes · ${x.reward.min}–${x.reward.max} $</small></div></div>`).join('') || '<p class="hint">Aucune mission pour ce type (les jobs retombent sur « custom »).</p>'}
          <div class="row mt"><input id="mt-id" placeholder="id (ex: livraison2)" maxlength="30"><button class="icon" data-a="mTplAdd">${ic('plus', 16)}</button></div></div>
        <div>${t ? `<div class="card"><div class="card-h"><div class="t">${ic('route', 16)} ${esc(t.label)}</div><button class="sm danger" data-a="mTplDel">${ic('trash', 14)} Supprimer</button></div>
          <div class="grid2">${fld('Nom de la mission', `<input data-path="${tb}.label" value="${esc(t.label)}" maxlength="50">`)}${fld('Identifiant', `<input value="${esc(t.id)}" disabled>`)}</div>
          <div class="mt">${fld('Description', `<input data-path="${tb}.desc" value="${esc(t.desc)}" maxlength="220">`)}</div>
          <div class="grid4 mt">${num(tb + '.reward.min', 'Gain min ($)', t.reward.min)}${num(tb + '.reward.max', 'Gain max ($)', t.reward.max)}${num(tb + '.minGrade', 'Grade min.', t.minGrade)}${num(tb + '.cooldown', 'Délai avant de refaire (s)', t.cooldown)}</div>
          <div class="grid3 mt">${num(tb + '.timeLimit', 'Temps imparti (s, 0 = aucun)', t.timeLimit)}
            ${fld('Véhicule : source', `<select data-path="${tb}.vehicle.source"><option value="models" ${t.vehicle.source !== 'catalog' ? 'selected' : ''}>Liste de modèles</option><option value="catalog" ${t.vehicle.source === 'catalog' ? 'selected' : ''}>Catalogue de la concession</option></select>`)}
            ${fld('Véhicules (modèles, virgules)', `<input data-path="${tb}.vehicle.models" data-t="list" value="${esc((t.vehicle.models || []).join(', '))}">`)}</div>
          <div class="mt">${fld('PNJ spécifiques (modèles, virgules — vide = liste générale)', `<input data-path="${tb}.peds" data-t="list" value="${esc((t.peds || []).join(', '))}">`)}</div></div>
          <div class="card"><div class="card-h"><div class="t">${ic('list', 16)} Étapes</div><button class="sm" data-a="mStepAdd">${ic('plus', 14)} Ajouter une étape</button></div>${steps}</div>` : ''}</div></div></div>`;
  },

  set_ui() {
    const u = this.S.draft.ui, hex = rgbHex(u.Accent), b = 'S.draft.ui';
    const presets = [['Rouge', [239, 68, 68]], ['Orange', [249, 115, 22]], ['Jaune', [250, 204, 21]], ['Vert', [34, 197, 94]], ['Turquoise', [64, 224, 208]], ['Bleu', [59, 130, 246]], ['Violet', [168, 85, 247]], ['Rose', [236, 72, 153]], ['Blanc', [244, 244, 245]]];
    return `<div class="grid2"><div class="card"><div class="card-h"><div class="t">${ic('sliders', 16)} Couleur d'accentuation</div></div>
        ${fld('Couleur personnalisée', `<input type="color" data-path="${b}.Accent" data-t="c" value="${hex}" style="max-width:200px">`)}
        <div class="lbl" style="margin:16px 0 8px">Couleurs prédéfinies</div>
        <div class="row wrap">${presets.map(([n, c]) => `<button class="swatch-pick ${c.join() === (u.Accent || []).join() ? 'on' : ''}" title="${n}" data-a="uiPreset" data-v="${c.join(',')}" style="background:rgb(${c.join(',')})"></button>`).join('')}</div>
        <p class="hint mt">S'applique à <b>tous les menus</b> (builder, F6, boss, concession, agence, gouvernement, missions) et à tous les joueurs dès que tu enregistres. L'aperçu à droite est immédiat.</p></div>
      <div class="card"><div class="card-h"><div class="t">${ic('grid', 16)} Aperçu</div>${chip('Organisation')}</div>
        <div class="profile" style="margin-bottom:12px"><div class="avatar">P</div><div><b>Pickax</b><small>Chef</small></div></div>
        <div class="nav-item active" style="margin-bottom:10px">${ic('users')}<span class="grow">Membres</span></div>
        <div class="row wrap"><button class="primary">${ic('plus', 15)} Recruter</button><button>Quitter</button>${chip('Actif', 'ok')}${chip('Info', 'info')}</div>
        <div class="segs mt">${Array.from({ length: 10 }, (_, i) => `<i class="${i < 6 ? 'on' : ''}"></i>`).join('')}</div></div></div>`;
  },

  set_dealer() {
    const d = this.S.draft.dealer, b = 'S.draft.dealer';
    return `<div class="grid2"><div class="card"><div class="card-h"><div class="t">${ic('car', 16)} Ventes</div></div>
        <div class="grid2">${fld('Livraison', `<select data-path="${b}.Delivery"><option value="spawn" ${d.Delivery === 'spawn' ? 'selected' : ''}>Le véhicule sort devant le client</option><option value="garage" ${d.Delivery === 'garage' ? 'selected' : ''}>Directement au garage</option></select>`)}
        ${num(b + '.DefaultCommission', 'Commission par défaut (%)', d.DefaultCommission)}${num(b + '.MaxVehiclesPerPlayer', 'Véhicules max / joueur (0 = illimité)', d.MaxVehiclesPerPlayer)}${num(b + '.TestSeconds', 'Durée d\'un essai (s)', d.TestSeconds)}</div></div>
      <div class="card"><div class="card-h"><div class="t">${ic('box', 16)} Base de données & affichage</div></div>
        <div class="grid3">${num(b + '.StateOut', 'state « dehors »', d.StateOut)}${num(b + '.StateStored', 'state « au garage »', d.StateStored)}${num(b + '.DisplayDistance', 'Distance d\'affichage des expos (m)', d.DisplayDistance)}</div>
        <p class="hint mt">Les véhicules vendus sont ajoutés à ta table <b>owned_vehicles</b> (colonnes dans <b>config.lua → Config.Dealer.Cols</b>). Vérifie ce que signifie la colonne <b>state</b> dans ton système de garage et règle ces deux valeurs en conséquence.</p></div></div>`;
  },

  set_police() {
    const P = this.S.draft.police, b = 'S.draft.police', M = P.Map || {};
    return `<div class="card"><div class="card-h"><div class="t">${ic('siren', 16)} Poursuites, appels et amendes</div></div>
      <div class="grid4">${num(b + '.PursuitMax', 'Durée max d\'une poursuite (s)', P.PursuitMax)}${num(b + '.PursuitTrail', 'Traînée du fugitif (points)', P.PursuitTrail)}${num(b + '.NearbyRange', 'Portée de détection du suspect (m)', P.NearbyRange)}${num(b + '.RefreshMs', 'Rafraîchissement carte (ms)', P.RefreshMs)}</div>
      <div class="grid4 mt">${num(b + '.CallCooldown', 'Délai entre deux appels citoyens (s)', P.CallCooldown)}${num(b + '.MaxCalls', 'Appels gardés par job', P.MaxCalls)}${num(b + '.MinFine', 'Amende minimale ($)', P.MinFine)}${num(b + '.MaxFine', 'Amende maximale ($)', P.MaxFine)}</div>
      <div class="grid4 mt">${num(b + '.ClosedKeepMinutes', 'Appel clôturé conservé (min)', P.ClosedKeepMinutes)}${fld('Commande appel citoyen', `<input data-path="${b}.CallCommand" value="${esc(P.CallCommand)}" maxlength="30">`)}${fld('Commande panique', `<input data-path="${b}.PanicCommand" value="${esc(P.PanicCommand)}" maxlength="30">`)}</div>
      <p class="hint mt">Un changement de commande s'applique après un <b>restart pickax_jobbuilder</b>. Les grades, le catalogue d'amendes et les droits se règlent <b>par job</b> (onglet Général du job).</p></div>
      <div class="card"><div class="card-h"><div class="t">${ic('map', 16)} Carte de la tablette</div></div>
        <p class="hint" style="margin-bottom:12px">Pour la <b>vraie carte en couleur</b> : dépose le pack de tuiles « mapStyles » dans <b>html/map/</b> (dossiers <code>styleAtlas</code>, <code>styleSatelite</code>…), puis choisis un style ci-dessous. Le calage est automatique. À défaut de tuiles, une image unique ou la carte schématique est utilisée.</p>
        <div class="row wrap" style="margin-bottom:12px"><button class="sm" data-a="mapPreset" data-v="atlas">Atlas (couleur)</button><button class="sm" data-a="mapPreset" data-v="sat">Satellite</button><button class="sm" data-a="mapPreset" data-v="grid">Grille</button><button class="sm" data-a="mapPreset" data-v="none">Aucune tuile</button></div>
        <div class="grid2">${fld('Tuiles (modèle d\'URL dans html/ ou https)', `<input data-path="${b}.Map.Tiles" value="${esc(M.Tiles || '')}" placeholder="map/mapStyles/styleAtlas/{z}/{x}/{y}.jpg" maxlength="200">`)}${num(b + '.Map.TileMaxZoom', 'Zoom max des tuiles', M.TileMaxZoom ?? 5, 'min="1" max="8"')}</div>
        <div class="mt">${fld('Ou image unique (chemin dans html/)', `<input data-path="${b}.Map.Image" value="${esc(M.Image || '')}" placeholder="map/gta.jpg" maxlength="200">`)}</div>
        <div class="grid4 mt">${num(b + '.Map.MinX', 'X min (gauche)', M.MinX)}${num(b + '.Map.MaxX', 'X max (droite)', M.MaxX)}${num(b + '.Map.MinY', 'Y min (bas)', M.MinY)}${num(b + '.Map.MaxY', 'Y max (haut)', M.MaxY)}</div>
        <div class="grid4 mt">${fld('Couleur des noms sur la carte', `<input type="color" data-path="${b}.Map.LabelColor" data-t="c" value="${rgbHex(M.LabelColor || [255, 255, 255])}" style="max-width:200px">`)}<label class="chk" style="align-self:end;height:38px"><input type="checkbox" data-path="${b}.Map.LabelOutline" data-t="b" ${M.LabelOutline === false ? '' : 'checked'}> Contour autour des noms (opposé à la couleur)</label></div>
        <p class="hint mt">Chaque agent peut aussi changer la couleur et le contour depuis la carte de la tablette (retenu sur son PC). Les limites ne servent qu'à l'image unique (valeurs par défaut : carte carrée standard). Les tuiles sont calées automatiquement.</p></div>
      <div class="card"><div class="card-h"><div class="t">${ic('dollar', 16)} Catalogue d'amendes par défaut</div></div><p class="hint" style="margin-bottom:10px">Copié dans chaque nouveau job police (puis modifiable par job).</p>
        ${(P.DefaultFines || []).map((f, i) => `<div class="form-row" style="grid-template-columns:2fr 140px auto">${fld('Motif', `<input data-path="${b}.DefaultFines.${i}.label" value="${esc(f.label)}" maxlength="60">`)}${fld('Montant ($)', `<input type="number" min="1" data-path="${b}.DefaultFines.${i}.amount" data-t="n" value="${f.amount}">`)}<button class="icon danger" data-a="fnDel" data-v="${i}">${ic('trash', 15)}</button></div>`).join('')}
        <button class="sm" data-a="fnAdd">${ic('plus', 14)} Amende</button></div>
      <div class="card"><div class="card-h"><div class="t">${ic('pin', 16)} Lieux affichés sur la carte schématique</div></div>
        ${(P.Landmarks || []).map((l, i) => `<div class="form-row" style="grid-template-columns:2fr 1fr 1fr auto">${fld('Nom', `<input data-path="${b}.Landmarks.${i}.0" value="${esc(l[0])}" maxlength="40">`)}${fld('X', `<input type="number" step="any" data-path="${b}.Landmarks.${i}.1" data-t="n" value="${l[1]}">`)}${fld('Y', `<input type="number" step="any" data-path="${b}.Landmarks.${i}.2" data-t="n" value="${l[2]}">`)}<button class="icon danger" data-a="lmDel" data-v="${i}">${ic('trash', 15)}</button></div>`).join('')}
        <div class="row"><button class="sm" data-a="lmAdd">${ic('plus', 14)} Lieu (ma position)</button></div></div>`;
  },

  set_death() {
    const D = this.S.draft.death, b = 'S.draft.death';
    return `<div class="card"><div class="card-h"><div class="t">${ic('cross', 16)} Mort, appel des EMS et réanimation</div></div>
      <div class="grid3">${fld('Système de mort du script', `<select data-path="${b}.Mode"><option value="auto" ${D.Mode === 'auto' ? 'selected' : ''}>Auto (désactivé si esx_ambulancejob tourne)</option><option value="on" ${D.Mode === 'on' ? 'selected' : ''}>Toujours actif</option><option value="off" ${D.Mode === 'off' ? 'selected' : ''}>Désactivé</option></select>`)}
        ${num(b + '.RespawnTime', 'Délai avant de réapparaître (s)', D.RespawnTime)}${num(b + '.NoEmsRespawn', 'Délai si aucun EMS en service (s)', D.NoEmsRespawn)}</div>
      <div class="grid4 mt">${num(b + '.CallCooldown', 'Délai entre deux appels EMS (s)', D.CallCooldown)}${num(b + '.ReviveHealth', 'Vie rendue par un EMS (%)', D.ReviveHealth)}${num(b + '.RespawnHealth', 'Vie rendue à l\'hôpital (%)', D.RespawnHealth)}${num(b + '.CprSeconds', 'Durée du massage cardiaque (s)', D.CprSeconds)}</div>
      <div class="grid4 mt">${num(b + '.RespawnFee', 'Frais de soins à l\'hôpital ($)', D.RespawnFee)}${fld('Compte débité', `<select data-path="${b}.FeeAccount"><option value="bank" ${D.FeeAccount !== 'money' ? 'selected' : ''}>Banque</option><option value="money" ${D.FeeAccount === 'money' ? 'selected' : ''}>Liquide</option></select>`)}${num(b + '.RevivePay', 'Prime de l\'EMS qui réanime ($)', D.RevivePay)}<label class="chk" style="align-self:end;height:38px"><input type="checkbox" data-path="${b}.ReviveAnim" data-t="b" ${D.ReviveAnim === false ? '' : 'checked'}> Animation au réveil</label></div>
      <div class="grid4 mt"><label class="chk" style="align-self:end;height:38px"><input type="checkbox" data-path="${b}.RestoreStatus" data-t="b" ${D.RestoreStatus === false ? '' : 'checked'}> Faim et soif remises à 100 % à l'hôpital</label><label class="chk" style="align-self:end;height:38px"><input type="checkbox" data-path="${b}.UnpaidAllowed" data-t="b" ${D.UnpaidAllowed === false ? '' : 'checked'}> Soigner même sans assez d'argent</label></div>
      <div class="grid4 mt"><label class="chk" style="align-self:end;height:38px"><input type="checkbox" data-path="${b}.OxygenHud" data-t="b" ${D.OxygenHud === false ? '' : 'checked'}> HUD d'oxygène sous l'eau</label>${num(b + '.OxygenWarn', 'HUD rouge sous (s d\'air)', D.OxygenWarn ?? 3)}<label class="chk" style="align-self:end;height:38px"><input type="checkbox" data-path="${b}.OxygenCustom" data-t="b" ${D.OxygenCustom === false ? '' : 'checked'}> Réserve d'air gérée par le script</label>${num(b + '.OxygenSeconds', 'Durée d\'air (s)', D.OxygenSeconds ?? 30)}</div>
      <div class="grid4 mt">${num(b + '.OxygenDamage', 'Dégâts par seconde sans air (PV)', D.OxygenDamage ?? 10)}</div>
      <p class="hint mt">Le joueur inconscient voit un minuteur, appelle les EMS avec <b>E</b> (ils reçoivent une alerte et un blip à sa position) et réapparaît avec <b>G</b> maintenu une fois le délai écoulé. Les EMS prennent l'appel avec <b>Y</b> ou F6 → Appels EMS, puis F6 → Réanimer.</p></div>
      <div class="card"><div class="card-h"><div class="t">${ic('building', 16)} Hôpitaux de réapparition</div></div><p class="hint" style="margin-bottom:10px">Le joueur réapparaît à l'hôpital le plus proche de l'endroit où il est mort.</p>
        ${(D.Hospitals || []).map((h, i) => `<div class="form-row" style="grid-template-columns:2fr 1fr 1fr 1fr 90px auto">${fld('Nom', `<input data-path="${b}.Hospitals.${i}.0" value="${esc(h[0])}" maxlength="40">`)}${fld('X', `<input type="number" step="any" data-path="${b}.Hospitals.${i}.1" data-t="n" value="${h[1]}">`)}${fld('Y', `<input type="number" step="any" data-path="${b}.Hospitals.${i}.2" data-t="n" value="${h[2]}">`)}${fld('Z', `<input type="number" step="any" data-path="${b}.Hospitals.${i}.3" data-t="n" value="${h[3]}">`)}${fld('Cap', `<input type="number" step="any" data-path="${b}.Hospitals.${i}.4" data-t="n" value="${h[4] ?? 0}">`)}<button class="icon danger" data-a="hospDel" data-v="${i}">${ic('trash', 15)}</button></div>`).join('')}
        <button class="sm" data-a="hospAdd">${ic('plus', 14)} Hôpital (ma position)</button></div>`;
  },

  set_tuning() {
    const T = this.S.draft.tuning, b = 'S.draft.tuning', P = T.Prices || {};
    const arr = (k, l) => `<div class="card" style="padding:14px;margin-bottom:10px"><div class="lbl" style="margin-bottom:8px">${l} — prix par niveau</div><div class="row wrap">${(P[k] || []).map((v, i) => `<label class="f" style="width:110px"><span>Niveau ${i + 1}</span><input type="number" min="0" data-path="${b}.Prices.${k}.${i}" data-t="n" value="${v}"></label>`).join('')}</div></div>`;
    const one = [['turbo', 'Turbo'], ['xenon', 'Phares xénon'], ['cosmetic', 'Pièce de carrosserie (chacune)'], ['wheels', 'Jantes'], ['paint', 'Peinture (par couleur)'], ['pearl', 'Nacrage'], ['wheelColor', 'Couleur de jantes'], ['neon', 'Néons'], ['tint', 'Vitres teintées'], ['plate', 'Style de plaque'], ['smoke', 'Fumée de pneus'], ['livery', 'Livrée'], ['horn', 'Klaxon']];
    return `<div class="card"><div class="card-h"><div class="t">${ic('wrench', 16)} Atelier tuning</div></div><div style="max-width:260px">${num(b + '.Radius', 'Rayon de recherche par défaut (m)', T.Radius, 'min="2" max="30" step="0.5"')}</div>
      <p class="hint mt">Prix de base en $ ; chaque job applique sa propre majoration (onglet Général) et choisit qui paie (client, société ou gratuit).</p></div>
      ${arr('engine', 'Moteur')}${arr('brakes', 'Freins')}${arr('transmission', 'Transmission')}${arr('suspension', 'Suspension')}${arr('armor', 'Blindage')}
      <div class="card"><div class="card-h"><div class="t">Autres modifications</div></div><div class="grid4">${one.map(([k, l]) => num(`${b}.Prices.${k}`, l, P[k], 'min="0"')).join('')}</div></div>`;
  },

  set_announce() {
    const A = this.S.draft.announce, b = 'S.draft.announce';
    return `<div class="card"><div class="card-h"><div class="t">${ic('megaphone', 16)} Annonces d'entreprise — valeurs par défaut</div></div>
      <label class="chk" style="margin-bottom:14px"><input type="checkbox" data-path="${b}.Enabled" data-t="b" ${A.Enabled ? 'checked' : ''}> Système d'annonces activé sur le serveur</label>
      <div class="grid4">${num(b + '.Cooldown', 'Délai par défaut (s)', A.Cooldown)}${num(b + '.Cost', 'Coût par défaut ($)', A.Cost)}${num(b + '.Duration', 'Durée d\'affichage (s)', A.Duration)}${num(b + '.History', 'Historique affiché', A.History)}</div>
      <div class="grid4 mt">${num(b + '.MaxTitle', 'Longueur max du titre', A.MaxTitle)}${num(b + '.MaxText', 'Longueur max du message', A.MaxText)}${fld('Commande masquer / afficher', `<input data-path="${b}.ToggleCommand" value="${esc(A.ToggleCommand)}" maxlength="30">`)}</div>
      <p class="hint mt">Chaque job règle ensuite son grade, son délai, son coût, son rayon et ses types dans son onglet Général.</p></div>
      <div class="card"><div class="card-h"><div class="t">Types d'annonces</div></div>
        ${(A.Types || []).map((t, i) => `<div class="form-row" style="grid-template-columns:1fr 1.4fr 90px auto">${fld('Identifiant', `<input data-path="${b}.Types.${i}.id" value="${esc(t.id)}" maxlength="20">`)}${fld('Nom affiché', `<input data-path="${b}.Types.${i}.label" value="${esc(t.label)}" maxlength="30">`)}${fld('Couleur', `<input type="color" data-path="${b}.Types.${i}.color" data-t="c" value="${rgbHex(t.color)}">`)}<button class="icon danger" data-a="atDel" data-v="${i}">${ic('trash', 15)}</button></div>`).join('')}
        <button class="sm" data-a="atAdd">${ic('plus', 14)} Type</button></div>`;
  },

  set_gov() {
    const g = this.S.draft.gov, b = 'S.draft.gov';
    const names = { dealer: 'Ventes de véhicules', realestate: 'Immobilier (ventes & loyers)', shop: 'Boutiques', invoice: 'Factures' };
    return `<div class="card"><div class="card-h"><div class="t">${ic('percent', 16)} Taxes prélevées pour le trésor public (%)</div></div><div class="tax-grid">${Object.keys(g.Taxes).map(k => num(`${b}.Taxes.${k}`, names[k] || k, g.Taxes[k], 'min="0" max="50"')).join('')}</div>
        <p class="hint mt">Le gouverneur peut aussi régler les taxes en jeu (F6 → Gouvernement). Une taxe est déduite de la part de la société qui vend.</p></div>
      <div class="card"><div class="card-h"><div class="t">${ic('megaphone', 16)} Limites</div></div><div class="grid4">${num(b + '.AnnounceCooldown', 'Délai entre annonces (s)', g.AnnounceCooldown)}${num(b + '.AnnounceMax', 'Longueur max d\'une annonce', g.AnnounceMax)}${num(b + '.GrantMax', 'Subvention max ($)', g.GrantMax)}${num(b + '.PrimeMax', 'Prime max ($)', g.PrimeMax)}</div></div>`;
  },

  set_interiors() {
    const I = this.S.draft.interiors, keys = Object.keys(I).sort();
    return `<div class="card"><div class="card-h"><div class="t">${ic('building', 16)} Intérieurs disponibles pour les propriétés</div><button class="sm" data-a="placeStart">${ic('pin', 14)} Mode placement</button></div>
      <p class="hint" style="margin-bottom:14px">Position de <b>sortie</b> de chaque intérieur (où le joueur apparaît et où se trouve la porte). Place-toi à l'intérieur (ex : après un TP) puis « Ma position ». « Intérieur personnalisé » est toujours disponible dans le panel agence pour les MLO.</p>
      ${keys.map(k => `<div class="card" style="padding:14px;margin-bottom:10px"><div class="row" style="margin-bottom:12px"><div class="grow" style="flex:1"><div class="grid2">${fld('Clé', `<input value="${esc(k)}" disabled>`)}${fld('Nom affiché', `<input data-path="S.draft.interiors.${k}.label" value="${esc(I[k].label)}" maxlength="60">`)}</div><div class="grid2 mt">${fld('Catégorie', `<select data-path="S.draft.interiors.${k}.cat">${Object.entries(PROP_CATS).map(([ck, cl]) => `<option value="${ck}" ${(I[k].cat || 'other') === ck ? 'selected' : ''}>${esc(cl)}</option>`).join('')}</select>`)}${fld('IPL à charger (virgules)', `<input data-path="S.draft.interiors.${k}.ipl" data-t="list" value="${esc((I[k].ipl || []).join(', '))}" placeholder="facultatif">`)}</div></div><button class="icon danger" data-a="intDel" data-v="${esc(k)}">${ic('trash', 15)}</button></div>${coordField(`S.draft.interiors.${k}.exit`, I[k].exit, { tp: true })}</div>`).join('')}
      <div class="row mt"><input id="int-key" placeholder="nouvelle clé (ex: loft2)" maxlength="20" style="max-width:260px"><button data-a="intAdd">${ic('plus', 15)} Ajouter un intérieur</button></div></div>`;
  },

  set_jobTypes() {
    const T = this.S.draft.jobTypes, keys = Object.keys(T).sort();
    if (!T[this.S.jt]) this.S.jt = keys[0];
    const k = this.S.jt, t = T[k], b = `S.draft.jobTypes.${k}`;
    return `<div class="pts"><div><div class="row" style="margin-bottom:10px"><input id="jt-key" placeholder="nouveau modèle" maxlength="20"><button class="icon" data-a="jtAdd">${ic('plus', 16)}</button></div>
      ${keys.map(x => `<div class="pt ${x === k ? 'active' : ''}" data-a="jtSel" data-v="${esc(x)}">${tile(TYPE_ICON[x] || 'briefcase')}<div style="flex:1;min-width:0"><b>${esc(T[x].label)}</b><small>${esc(x)} · ${T[x].grades.length} grades</small></div></div>`).join('')}</div>
      <div><div class="card"><div class="card-h"><div class="t">${ic('briefcase', 16)} Modèle « ${esc(k)} »</div>${k !== 'custom' ? `<button class="sm danger" data-a="jtDel" data-v="${esc(k)}">${ic('trash', 14)} Supprimer</button>` : ''}</div>
        <div class="grid4">${fld('Nom du modèle', `<input data-path="${b}.label" value="${esc(t.label)}" maxlength="40">`)}${num(b + '.blip.sprite', 'Blip · sprite', t.blip.sprite)}${num(b + '.blip.color', 'Blip · couleur', t.blip.color)}${num(b + '.blip.scale', 'Blip · taille', Math.round((t.blip.scale ?? 0.9) * 100) / 100, 'step="0.1"')}</div></div>
        <div class="card"><div class="card-h"><div class="t">${ic('list', 16)} Actions par défaut</div></div><div class="grid2" style="gap:12px">${Object.entries(this.catalog.actions).filter(([id]) => id !== 'properties').map(([id, a]) => `<label class="chk"><input type="checkbox" data-a="jtAct" data-v="${id}" ${t.actions.includes(id) ? 'checked' : ''}> ${esc(a.label)}</label>`).join('')}</div></div>
        <div class="card"><div class="card-h"><div class="t">${ic('users', 16)} Grades par défaut</div></div><table><tr><th style="width:40px">#</th><th>Nom interne</th><th>Label</th><th style="width:130px">Salaire</th><th style="width:50px"></th></tr>
          ${t.grades.map((g, i) => `<tr><td class="muted">${i}</td><td><input data-path="${b}.grades.${i}.name" value="${esc(g.name)}" maxlength="40"></td><td><input data-path="${b}.grades.${i}.label" value="${esc(g.label)}" maxlength="50"></td><td><input type="number" min="0" data-path="${b}.grades.${i}.salary" data-t="n" value="${g.salary}"></td><td><button class="icon danger" data-a="jgDel" data-v="${i}">${ic('trash', 15)}</button></td></tr>`).join('')}</table>
          <div class="mt"><button data-a="jgAdd">${ic('plus', 15)} Ajouter un grade</button></div></div></div></div>`;
  },

  async settingsAction(a, v, el) {
    const S = this.S;
    const need = () => this.page === 'settings' && S;
    switch (a) {
      case 'uiPreset': { if (!need()) return false; S.draft.ui.Accent = v.split(',').map(Number); applyTheme(S.draft.ui.Accent); this.render(); return true; }
      case 'mapPreset': {
        if (!need()) return false;
        const m = S.draft.police.Map, P = { atlas: ['map/mapStyles/styleAtlas/{z}/{x}/{y}.jpg', 5], sat: ['map/mapStyles/styleSatelite/{z}/{x}/{y}.jpg', 8], grid: ['map/mapStyles/styleGrid/{z}/{x}/{y}.png', 5], none: ['', 5] }[v];
        m.Tiles = P[0]; m.TileMaxZoom = P[1]; this.render(); return true;
      }
      case 'hospAdd': { if (!need()) return false; const r = await rpc('getCoords'); S.draft.death.Hospitals.push(['Nouvel hôpital', Math.round((r.x || 0) * 100) / 100, Math.round((r.y || 0) * 100) / 100, Math.round((r.z || 0) * 100) / 100, Math.round(r.h || 0)]); this.render(); return true; }
      case 'hospDel': if (!need()) return false; S.draft.death.Hospitals.splice(Number(v), 1); this.render(); return true;
      case 'fnAdd': if (!need()) return false; S.draft.police.DefaultFines.push({ label: '', amount: 100 }); this.render(); return true;
      case 'fnDel': if (!need()) return false; S.draft.police.DefaultFines.splice(Number(v), 1); this.render(); return true;
      case 'lmAdd': { if (!need()) return false; const r = await rpc('getCoords'); const c = r && r.coords ? r.coords : (r || {}); S.draft.police.Landmarks.push(['Nouveau lieu', Math.round(c.x || 0), Math.round(c.y || 0)]); this.render(); return true; }
      case 'lmDel': if (!need()) return false; S.draft.police.Landmarks.splice(Number(v), 1); this.render(); return true;
      case 'atAdd': if (!need()) return false; S.draft.announce.Types.push({ id: 'type' + (S.draft.announce.Types.length + 1), label: 'Nouveau type', color: [64, 224, 208] }); this.render(); return true;
      case 'atDel': if (!need()) return false; S.draft.announce.Types.splice(Number(v), 1); this.render(); return true;
      case 'setTab': if (!need()) return false; S.sec = v; this.render(); return true;
      case 'preview': { if (!need()) return false; await rpc('previewMarker', getPath(this, v)); toast('Aperçu affiché devant toi (8 s)'); return true; }
      case 'setSave': case 'setReset': {
        if (!need()) return false;
        const sec = S.sec;
        if (a === 'setReset' && !await confirmBox('Réinitialiser cette section ?', 'Les valeurs reviennent à celles de config.lua pour tous les joueurs.', 'Réinitialiser')) return true;
        const r = a === 'setSave' ? await rpc('settings:save', sec, S.draft[sec]) : await rpc('settings:reset', sec);
        if (!r || !r.ok) { toast((r && r.error) || 'Erreur', 'err'); return true; }
        S.values[sec] = r.value; S.draft[sec] = clone(r.value);
        if (sec === 'ui') applyTheme(r.value.Accent);
        this.catalog = await rpc('catalog');
        toast(a === 'setSave' ? 'Paramètres enregistrés et appliqués en direct' : 'Section réinitialisée', 'ok');
        this.render(); return true;
      }
      case 'intAdd': {
        if (!need()) return false;
        const k = document.getElementById('int-key').value.trim().toLowerCase();
        if (!/^[a-z0-9_]{2,20}$/.test(k) || k === 'custom') { toast('Clé invalide (a-z, 0-9, _ ; 2-20 car.)', 'err'); return true; }
        if (S.draft.interiors[k]) { toast('Cette clé existe déjà', 'err'); return true; }
        S.draft.interiors[k] = { label: k, exit: null }; this.render(); return true;
      }
      case 'intDel': if (!need()) return false; delete S.draft.interiors[v]; this.render(); return true;
      case 'mType': if (!need()) return false; S.mt = v; S.mi = 0; this.render(); return true;
      case 'mTplSel': if (!need()) return false; S.mi = +v; this.render(); return true;
      case 'mLocDel': if (!need()) return false; delete S.draft.missions.Locations[v]; this.render(); return true;
      case 'mLocAdd': {
        if (!need()) return false;
        const k = document.getElementById('ml-key').value.trim().toLowerCase();
        if (!/^[a-z0-9_]{1,24}$/.test(k)) { toast('Clé invalide (a-z, 0-9, _)', 'err'); return true; }
        if (S.draft.missions.Locations[k]) { toast('Cette clé existe déjà', 'err'); return true; }
        S.draft.missions.Locations[k] = { label: k, x: null, y: null, z: null, h: 0 }; this.render(); return true;
      }
      case 'mTplAdd': {
        if (!need()) return false;
        const id = document.getElementById('mt-id').value.trim().toLowerCase();
        if (!/^[a-z0-9_]{2,30}$/.test(id)) { toast('Identifiant invalide (a-z, 0-9, _ ; 2-30)', 'err'); return true; }
        const L = S.draft.missions.Templates[S.mt] = S.draft.missions.Templates[S.mt] || [];
        if (L.some(x => x.id === id)) { toast('Cet identifiant existe déjà', 'err'); return true; }
        L.push({ id, label: id, desc: '', minGrade: 0, reward: { min: 200, max: 400 }, cooldown: 60, timeLimit: 900, vehicle: { source: 'models', models: [] }, peds: [],
          steps: [{ t: 'goto', where: 'loc', label: 'Rends-toi sur place', secs: 5, anim: 'talk', npc: true }, { t: 'interact', same: true, where: 'loc', anim: 'talk', secs: 6, npc: true, label: 'Interagir' }] });
        S.mi = L.length - 1; this.render(); return true;
      }
      case 'mTplDel': if (!need()) return false; S.draft.missions.Templates[S.mt].splice(S.mi, 1); S.mi = 0; this.render(); return true;
      case 'mStepAdd': { if (!need()) return false; const t = S.draft.missions.Templates[S.mt][S.mi]; if (t.steps.length >= 14) { toast('14 étapes max', 'err'); return true; } t.steps.push({ t: 'goto', where: 'loc', label: '', secs: 5, anim: 'talk', npc: true }); this.render(); return true; }
      case 'mStepDel': { if (!need()) return false; const t = S.draft.missions.Templates[S.mt][S.mi]; if (t.steps.length <= 1) { toast('Il faut au moins une étape', 'err'); return true; } t.steps.splice(+v, 1); this.render(); return true; }
      case 'mStepUp': { if (!need()) return false; const L = S.draft.missions.Templates[S.mt][S.mi].steps; if (+v > 0) [L[v - 1], L[v]] = [L[v], L[v - 1]]; this.render(); return true; }
      case 'mStepDown': { if (!need()) return false; const L = S.draft.missions.Templates[S.mt][S.mi].steps; if (+v < L.length - 1) [L[+v + 1], L[v]] = [L[v], L[+v + 1]]; this.render(); return true; }
      case 'jtSel': if (!need()) return false; S.jt = v; this.render(); return true;
      case 'jtAdd': {
        if (!need()) return false;
        const k = document.getElementById('jt-key').value.trim().toLowerCase();
        if (!/^[a-z][a-z0-9_]{1,19}$/.test(k)) { toast('Clé invalide (a-z, 0-9, _ ; commence par une lettre)', 'err'); return true; }
        if (S.draft.jobTypes[k]) { toast('Ce modèle existe déjà', 'err'); return true; }
        S.draft.jobTypes[k] = { label: k, blip: { sprite: 478, color: 0, scale: 0.9 }, actions: ['invoice'], grades: [{ name: 'recrue', label: 'Recrue', salary: 100 }, { name: 'boss', label: 'Patron', salary: 500 }] };
        S.jt = k; this.render(); return true;
      }
      case 'jtDel': if (!need()) return false; delete S.draft.jobTypes[v]; S.jt = 'custom'; this.render(); return true;
      case 'jtAct': { if (!need()) return false; const L = S.draft.jobTypes[S.jt].actions, i = L.indexOf(v); if (i >= 0) L.splice(i, 1); else L.push(v); return true; }
      case 'jgAdd': { if (!need()) return false; const g = S.draft.jobTypes[S.jt].grades; g.push({ name: 'grade' + g.length, label: 'Nouveau grade', salary: 100 }); this.render(); return true; }
      case 'jgDel': { if (!need()) return false; const g = S.draft.jobTypes[S.jt].grades; if (g.length <= 1) { toast('Il faut au moins un grade', 'err'); return true; } g.splice(+v, 1); this.render(); return true; }
    }
    return false;
  },
});

/* ════════════════════════════ AGENCE IMMOBILIÈRE ════════════════════════════ */
const Agency = {
  d: null, cat: 'all', view: 'home', sel: null, form: null, q: '', filter: 'all',

  open(data) {
    this.d = data;
    if (!(this.view === 'form' && this.form)) { this.view = 'home'; this.sel = null; this.form = null; }
    this.render();
  },

  prop(id) { return this.d.props.find(p => p.id === id); },
  catLabel(k) { return ((this.d.categories || []).find(c => c.key === k) || {}).label || 'Maison'; },
  placementTargets() {
    const f = this.form; if (this.view !== 'form' || !f) return [];
    const out = [{ root: this, path: 'form.entrance', label: 'Entrée du bien' }];
    if (f.interior === 'custom' && f.status !== 'owned') out.push({ root: this, path: 'form.exit', label: 'Sortie de l\'intérieur' });
    f.points.forEach((p, i) => out.push({ root: this, path: `form.points.${i}.coords`, label: `${p.label || ({ stash: 'Coffre', safe: 'Coffre-fort' }[p.type] || 'Penderie')} — position` }));
    return out;
  },
  interiorOptions(f) {
    const d = this.d, cats = [...(d.categories || []).map(c => [c.key, c.label]), ['other', 'Autres'], ['custom', 'Personnalisé']];
    return cats.map(([k, l]) => { const items = d.interiors.filter(i => (i.cat === k) || (k === 'other' && !(d.categories || []).some(c => c.key === i.cat) && i.cat !== 'custom')); return items.length ? `<optgroup label="${esc(l)}">${items.map(i => `<option value="${i.key}" ${f.interior === i.key ? 'selected' : ''}>${esc(i.label)}</option>`).join('')}</optgroup>` : ''; }).join('');
  },
  statusChip(p) {
    if (p.status === 'available') return chip('Disponible', 'ok');
    return p.deal === 'rent' ? chip('Loué', 'info') : chip('Vendu', 'warn');
  },
  dealLabel: p => (p.deal === 'rent' ? 'Location' : 'Vente'),
  priceLabel(p) { return p.deal === 'rent' ? `${money(p.price)} / sem.` : money(p.price); },

  render() {
    const d = this.d, nav = [
      { label: 'Général', items: [{ id: 'home', icon: 'grid', text: 'Tableau de bord' }] },
      { label: 'Portefeuille', items: [{ id: 'list', icon: 'building', text: 'Propriétés', count: d.stats.total }, { id: 'new', icon: 'plus', text: 'Nouvelle propriété' }] },
      { label: 'Activité', items: [{ id: 'history', icon: 'clock', text: 'Historique' }] },
    ];
    const active = this.view === 'detail' ? 'list' : this.view === 'form' ? (this.form && this.form.id ? 'list' : 'new') : this.view;
    const v = this['view_' + this.view]();
    $root.innerHTML = shellSide({
      profile: { initials: initials(d.agent), title: d.agent, sub: `${d.jobLabel} · ${d.gradeLabel || ''}` }, nav, active,
      foot: `<small>Commission agent : <b style="color:var(--text-2)">${d.commission}%</b> du prix · le reste va à la société de l'agence.</small>`,
      head: v.head, body: v.body,
    });
  },

  view_home() {
    const d = this.d, s = d.stats, pct = s.total ? Math.round((s.total - s.available) / s.total * 100) : 0;
    const segs = Array.from({ length: 10 }, (_, i) => `<i class="${i < Math.round(pct / 10) ? 'on' : ''}"></i>`).join('');
    return {
      head: { icon: 'home', title: 'Tableau de bord', sub: `${d.jobLabel} — gestion immobilière`, acts: `<button class="primary" data-a="nav" data-v="new">${ic('plus', 16)} Nouvelle propriété</button>` },
      body: `<div class="grid2" style="grid-template-columns:380px 1fr">
        <div class="card"><div class="eyebrow">Revenus · 30 jours</div><div class="big">${Number(s.revenue).toLocaleString('fr-FR')}<small>$</small></div>
          ${chip(`${s.available} bien(s) disponible(s)`, 'ok')}
          <div class="stat mt"><div class="eyebrow">Taux d'occupation</div><div class="v">${pct}%</div><div class="segs">${segs}</div><div class="s">${s.total - s.available} occupé(s) sur ${s.total}</div></div></div>
        <div><div class="grid4" style="grid-template-columns:repeat(4,1fr);margin-bottom:14px">
          ${[['Biens', s.total, 'au catalogue'], ['Disponibles', s.available, 'à proposer'], ['Vendus', s.sale, 'propriétaires'], ['Loués', s.rent, 'locataires']].map(([l, v, sub]) => `<div class="stat"><div class="eyebrow">${l}</div><div class="v">${v}</div><div class="s">${sub}</div></div>`).join('')}</div>
          <div class="card"><div class="card-h"><div class="t">${ic('clock', 16)} Activité récente</div><button class="sm" data-a="nav" data-v="history">Tout voir</button></div>
            ${d.history.slice(0, 6).map(h => this.histRow(h)).join('') || '<p class="hint">Aucune activité pour l\'instant.</p>'}</div></div></div>`,
    };
  },

  histLabel: { created: 'Bien créé', updated: 'Bien modifié', deleted: 'Bien supprimé', sold: 'Vente conclue', rented: 'Location conclue', rent_paid: 'Loyer payé', reset: 'Bien repris' },
  histRow(h) {
    return `<div class="logline"><b>${esc(this.histLabel[h.action] || h.action)}</b>${h.prop ? ' · ' + esc(h.prop) : ''}${h.amount ? ` · <span style="color:var(--ok)">+${money(h.amount)}</span>` : ''}<br>${esc(h.actor || '')} ${h.detail ? '· ' + esc(h.detail) : ''} · ${fmtDate(h.t)}</div>`;
  },

  view_history() {
    return {
      head: { icon: 'clock', title: 'Historique', sub: 'Ventes, locations, loyers et modifications' },
      body: `<div class="card">${this.d.history.map(h => this.histRow(h)).join('') || '<p class="hint">Aucune activité.</p>'}</div>`,
    };
  },

  view_list() {
    const q = this.q.toLowerCase();
    const list = this.d.props.filter(p => (this.cat === 'all' || p.category === this.cat) && (this.filter === 'all' || (this.filter === 'available' ? p.status === 'available' : p.status === 'owned' && p.deal === this.filter))
      && (!q || (p.label + ' ' + p.address + ' ' + (p.owner_name || '')).toLowerCase().includes(q)));
    return {
      head: { icon: 'building', title: 'Propriétés', sub: `${this.d.stats.total} bien(s) · ${this.d.stats.available} disponible(s)`, acts: `<button class="primary" data-a="nav" data-v="new">${ic('plus', 16)} Nouvelle propriété</button>` },
      body: `<div class="row" style="margin-bottom:16px"><div style="flex:1;position:relative"><input data-path="q" placeholder="Rechercher un bien, une adresse, un propriétaire…" value="${esc(this.q)}" style="padding-left:38px"><span style="position:absolute;left:12px;top:10px;color:var(--muted)">${ic('search', 16)}</span></div>
        <select data-path="cat" style="width:190px"><option value="all" ${this.cat === 'all' ? 'selected' : ''}>Toutes catégories</option>${(this.d.categories || []).map(c => `<option value="${c.key}" ${this.cat === c.key ? 'selected' : ''}>${esc(c.label)}</option>`).join('')}</select>
        <select data-path="filter" style="width:180px"><option value="all" ${this.filter === 'all' ? 'selected' : ''}>Tous</option><option value="available" ${this.filter === 'available' ? 'selected' : ''}>Disponibles</option><option value="sale" ${this.filter === 'sale' ? 'selected' : ''}>Vendus</option><option value="rent" ${this.filter === 'rent' ? 'selected' : ''}>Loués</option></select></div>
        ${list.map(p => `<div class="item click" data-a="open" data-v="${p.id}">${tile(p.status === 'available' ? 'home' : 'key')}<div class="grow"><b>${esc(p.label)}</b><small>${esc(this.catLabel(p.category))} · ${esc(p.address || 'Sans adresse')} · ${this.dealLabel(p)}${p.owner_name ? ' · ' + esc(p.owner_name) : ''}</small></div>
          <span class="price">${this.priceLabel(p)}</span>${this.statusChip(p)}<span class="chev">${ic('chevron', 16)}</span></div>`).join('')
        || emptyState('building', 'Aucune propriété', 'Crée ta première propriété avec « Nouvelle propriété ».')}`,
    };
  },

  view_detail() {
    const p = this.prop(this.sel), d = this.d;
    if (!p) { this.view = 'list'; return this.view_list(); }
    const avail = p.status === 'available';
    const actions = avail
      ? `<button class="primary" data-a="offer" data-v="${p.id}">${ic('tag', 16)} ${p.deal === 'rent' ? 'Louer' : 'Vendre'} au client le plus proche</button><button data-a="visit" data-v="${p.id}">${ic('login', 16)} Visiter</button>`
      : `<button data-a="gps" data-v="${p.id}">${ic('pin', 16)} GPS</button>`;
    return {
      head: { icon: avail ? 'home' : 'key', title: p.label, sub: p.address || 'Sans adresse', acts: `<button data-a="nav" data-v="list"><span style="display:inline-flex;transform:rotate(180deg)">${ic('chevron', 14)}</span> Retour</button>` },
      body: `<div class="grid2" style="grid-template-columns:1fr 380px">
        <div><div class="card"><div class="card-h"><div class="t">${ic('file', 16)} Informations</div>${this.statusChip(p)}</div>
          <div class="kv"><span>Type</span><span>${this.dealLabel(p)}</span></div>
          <div class="kv"><span>${p.deal === 'rent' ? 'Loyer (par semaine)' : 'Prix'}</span><span><b>${money(p.price)}</b></span></div>
          <div class="kv"><span>Catégorie</span><span>${esc(this.catLabel(p.category))}</span></div>
          <div class="kv"><span>Intérieur</span><span>${esc((d.interiors.find(i => i.key === p.interior) || {}).label || p.interior)}</span></div>
          ${p.description ? `<p class="hint" style="margin-top:10px">${esc(p.description)}</p>` : ''}
          ${avail ? '' : `<div class="kv"><span>${p.deal === 'rent' ? 'Locataire' : 'Propriétaire'}</span><span>${esc(p.owner_name || '—')}</span></div>
          ${p.deal === 'rent' && p.rent_until ? `<div class="kv"><span>Loyer payé jusqu'au</span><span>${fmtDate(p.rent_until)}</span></div>` : ''}
          <div class="kv"><span>Doubles de clés</span><span>${p.keys}</span></div>`}</div>
          <div class="card"><div class="card-h"><div class="t">${ic('box', 16)} Points intérieurs · ${p.points.length}</div></div>
            ${p.points.map(pt => `<div class="item">${tile(POINT_ICON[pt.type])}<div class="grow"><b>${esc(pt.label)}</b><small>${pt.type === 'stash' || pt.type === 'safe' ? `${pt.type === 'safe' ? 'Coffre-fort' : 'Coffre'} · ${pt.data.slots} empl. · ${pt.data.weight} kg` : 'Penderie'}</small></div></div>`).join('') || '<p class="hint">Aucun coffre ni penderie. Utilise « Modifier » pour en ajouter.</p>'}</div></div>
        <div><div class="card"><div class="card-h"><div class="t">Actions</div></div><div style="display:flex;flex-direction:column;gap:10px">${actions}
          <button data-a="edit" data-v="${p.id}">${ic('edit', 16)} Modifier</button>
          <button data-a="clone" data-v="${p.id}">${ic('plus', 16)} Dupliquer (autre appartement, même immeuble)</button>
          ${d.admin ? (avail ? `<button class="danger" data-a="del" data-v="${p.id}">${ic('trash', 16)} Supprimer</button>` : `<button class="danger" data-a="reset" data-v="${p.id}">Remettre en vente / expulser</button>`) : ''}</div>
          ${avail ? `<p class="hint mt">Le client doit se trouver à côté de toi : il reçoit l'offre à l'écran et paie directement. ${d.commission}% de commission pour toi.</p>` : ''}</div></div></div>`,
    };
  },

  blankForm() {
    return { id: null, label: '', address: '', description: '', category: 'house', ipl: '', deal: 'sale', price: 150000, interior: this.d.interiors[0].key, entrance: null, exit: null, status: 'available', points: [] };
  },

  view_new() { this.form = this.blankForm(); this.view = 'form'; return this.view_form(); },

  view_form() {
    const f = this.form, d = this.d, locked = f.status === 'owned', isNew = !f.id;
    const pt = (p, i) => `<div class="card" style="padding:14px"><div class="row" style="margin-bottom:12px">${tile(POINT_ICON[p.type])}<b style="flex:1">${{ stash: 'Coffre', safe: 'Coffre-fort' }[p.type] || 'Penderie'}</b><button class="icon danger" data-a="delPt" data-v="${i}">${ic('trash', 15)}</button></div>
      <div class="${p.type === 'stash' || p.type === 'safe' ? 'grid3' : ''}">${fld('Nom', `<input data-path="form.points.${i}.label" value="${esc(p.label)}" maxlength="60">`)}
      ${p.type === 'stash' || p.type === 'safe' ? fld('Emplacements', `<input type="number" min="5" max="200" data-path="form.points.${i}.data.slots" data-t="n" value="${p.data.slots ?? 50}">`) + fld('Poids max (kg)', `<input type="number" min="1" data-path="form.points.${i}.data.weight" data-t="n" value="${p.data.weight ?? 100}">`) : ''}</div>
      <div class="mt-s">${coordField(`form.points.${i}.coords`, p.coords)}</div></div>`;
    return {
      head: { icon: isNew ? 'plus' : 'edit', title: isNew ? 'Nouvelle propriété' : `Modifier · ${f.label}`, sub: 'Renseigne le bien, l\'intérieur et les points (coffres, penderies)',
        acts: `<button data-a="${isNew ? 'nav' : 'open'}" data-v="${isNew ? 'list' : f.id}">Annuler</button><button class="primary" data-a="saveProp" style="height:38px">${isNew ? 'Créer la propriété' : 'Enregistrer'}</button>` },
      body: `<div class="grid2"><div class="card"><div class="card-h"><div class="t">${ic('file', 16)} Le bien</div></div>
          <div class="grid2">${fld('Nom', `<input data-path="form.label" value="${esc(f.label)}" maxlength="80" placeholder="Villa Vinewood Hills">`)}${fld('Adresse', `<input data-path="form.address" value="${esc(f.address)}" maxlength="120" placeholder="12 Vinewood Hills Dr">`)}</div>
          <div class="grid2 mt">${fld('Catégorie du bien', `<select data-path="form.category">${(d.categories || []).map(c => `<option value="${c.key}" ${f.category === c.key ? 'selected' : ''}>${esc(c.label)}</option>`).join('')}</select>`)}${fld('Description', `<input data-path="form.description" value="${esc(f.description || '')}" maxlength="300" placeholder="3 chambres, piscine, vue sur la mer…">`)}</div>
          <div class="grid2 mt">${fld('Type', `<select data-path="form.deal" ${locked ? 'disabled' : ''}><option value="sale" ${f.deal === 'sale' ? 'selected' : ''}>Vente</option><option value="rent" ${f.deal === 'rent' ? 'selected' : ''}>Location (loyer / semaine)</option></select>`)}
          ${fld(f.deal === 'rent' ? 'Loyer ($ / semaine)' : 'Prix ($)', `<input type="number" min="1" data-path="form.price" data-t="n" value="${f.price ?? ''}" ${locked ? 'disabled' : ''}>`)}</div>
          <div class="mt">${fld('Intérieur', `<select data-path="form.interior" ${locked ? 'disabled' : ''}>${this.interiorOptions(f)}</select>`)}</div>
          ${locked ? '<p class="hint mt">Bien occupé : type, prix et intérieur sont verrouillés.</p>' : ''}</div>
        <div class="card"><div class="card-h"><div class="t">${ic('pin', 16)} Entrée</div></div><p class="hint" style="margin-bottom:12px">Place-toi devant la porte du bien (à l'extérieur) puis clique « Ma position ».</p>${coordField('form.entrance', f.entrance)}
          ${f.interior === 'custom' && !locked ? `<div class="lbl mt" style="margin-bottom:6px">Sortie de l'intérieur personnalisé</div><p class="hint" style="margin-bottom:12px">Place-toi à l'intérieur (MLO / shell), devant la porte, puis « Ma position ».</p>${coordField('form.exit', f.exit)}
          ${fld('IPL à charger (facultatif, séparés par des virgules)', `<input data-path="form.ipl" value="${esc(f.ipl || '')}" maxlength="300" placeholder="nom_ipl_1, nom_ipl_2">`)}` : ''}</div></div>
        <div class="card"><div class="card-h"><div class="t">${ic('box', 16)} Points intérieurs · ${f.points.length}/${d.maxPoints}</div>
          <button class="sm" data-a="placeStart">${ic('pin', 14)} Mode placement</button><button class="sm" data-a="addPt" data-v="stash">${ic('plus', 14)} Coffre</button><button class="sm" data-a="addPt" data-v="safe">${ic('plus', 14)} Coffre-fort</button><button class="sm" data-a="addPt" data-v="wardrobe">${ic('plus', 14)} Penderie</button></div>
          <p class="hint" style="margin-bottom:14px">Les positions se prennent <b>à l'intérieur</b> : enregistre le bien, clique <b>Visiter</b>, puis rouvre le menu F6 → <b>Modifier</b> et utilise « Ma position » pour chaque coffre / penderie. Ton brouillon est conservé quand tu fermes avec Échap.</p>
          ${f.points.map(pt).join('') || '<p class="hint">Aucun point pour l\'instant.</p>'}</div>`,
    };
  },

  async onA(el) {
    const a = el.dataset.a, v = el.dataset.v, f = this.form;
    const reply = (r, msg) => { if (!r || !r.ok) { toast((r && r.error) || 'Erreur', 'err'); return false; } if (msg) toast(msg, 'ok'); this.d = r; return true; };
    switch (a) {
      case 'nav':
        if (v === 'new') { this.form = this.blankForm(); this.view = 'form'; }
        else { this.view = v; if (v !== 'form') this.form = null; }
        return this.render();
      case 'open': this.sel = Number(v); this.view = 'detail'; this.form = null; return this.render();
      case 'edit': { const p = this.prop(Number(v)); this.form = JSON.parse(JSON.stringify({ id: p.id, label: p.label, address: p.address, description: p.description || '', category: p.category || 'house', ipl: p.ipl || '', deal: p.deal, price: p.price, interior: p.interior, entrance: p.entrance, exit: p.exit, status: p.status, points: p.points })); this.view = 'form'; return this.render(); }
      case 'clone': { const p = this.prop(Number(v)); this.form = JSON.parse(JSON.stringify({ id: null, label: p.label + ' (copie)', address: p.address, description: p.description || '', category: p.category || 'house', ipl: p.ipl || '', deal: p.deal, price: p.price, interior: p.interior, entrance: null, exit: p.exit, status: 'available', points: (p.points || []).map(pt => ({ type: pt.type, label: pt.label, coords: pt.coords, data: pt.data })) })); this.view = 'form'; toast('Copie créée : place la nouvelle entrée puis enregistre', ''); return this.render(); }
      case 'coords': await grabCoords(this, v); return this.render();
      case 'addPt': if (f.points.length >= this.d.maxPoints) return toast('Maximum de points atteint', 'err'); f.points.push({ type: v, label: { stash: 'Coffre', safe: 'Coffre-fort' }[v] || 'Penderie', coords: null, data: v === 'stash' ? { slots: 50, weight: 100 } : v === 'safe' ? { slots: 20, weight: 50 } : {} }); return this.render();
      case 'delPt': f.points.splice(+v, 1); return this.render();
      case 'saveProp': {
        const r = await rpc('prop:save', f);
        if (!reply(r, f.id ? 'Propriété enregistrée' : 'Propriété créée')) return;
        this.sel = r.savedId; this.view = 'detail'; this.form = null; this.render();
        if (!f.id) toast('Astuce : clique « Visiter » pour placer coffres et penderies à l\'intérieur', '');
        return;
      }
      case 'offer': { const r = await rpc('prop:offer', Number(v)); if (r && r.ok) { toast('Offre envoyée au client, en attente de sa réponse', 'ok'); close(); } else toast((r && r.error) || 'Erreur', 'err'); return; }
      case 'visit': { const r = await rpc('prop:enter', Number(v)); if (!r || !r.ok) toast((r && r.error) || 'Erreur', 'err'); return; }
      case 'gps': { const p = this.prop(Number(v)); rpc('waypoint', p.entrance); return toast('Point GPS défini', 'ok'); }
      case 'del': if (!await confirmBox('Supprimer cette propriété ?', 'Le bien et ses points seront supprimés définitivement.', 'Supprimer')) return; if (reply(await rpc('prop:delete', Number(v)), 'Propriété supprimée')) { this.view = 'list'; this.render(); } return;
      case 'reset': if (!await confirmBox('Reprendre ce bien ?', 'Le propriétaire/locataire perd l\'accès, les clés et le contenu des coffres sont effacés. Le bien redevient disponible.', 'Reprendre')) return; if (reply(await rpc('prop:reset', Number(v)), 'Bien remis en vente')) this.render(); return;
    }
  },

  onInput(el, isChange) {
    const path = el.dataset.path; if (!path) return;
    let val = el.value;
    if (el.dataset.t === 'n') val = val === '' ? null : Number(val);
    setPath(this, path, val);
    if (path === 'q') return;                       // la recherche se met à jour à chaque frappe sans perdre le focus ci-dessous
    if (isChange && (path === 'form.deal' || path === 'form.interior' || path === 'form.category' || path === 'filter' || path === 'cat')) this.render();
  },
};
// recherche live : on ne re-render que la liste pour garder le focus
document.addEventListener('input', e => {
  if (Mod === Agency && e.target.dataset.path === 'q') {
    const pos = e.target.selectionStart;
    Agency.render();
    const inp = document.querySelector('[data-path="q"]'); if (inp) { inp.focus(); inp.setSelectionRange(pos, pos); }
  }
});

/* ════════════════════════════ CONCESSION ════════════════════════════ */
const Dealer = {
  d: null, view: 'home', draft: [], resets: [], dirty: false, q: '', cat: '', limit: 60,

  prep(list) { return clone(list).map(v => ({ ...v, _o: false })); },

  open(data) {
    this.d = data;
    if (!this.dirty) { this.draft = this.prep(data.catalog); this.resets = []; this.view = 'home'; }
    this.render();
  },

  render() {
    const d = this.d;
    const nav = [{ label: 'Général', items: [{ id: 'home', icon: 'grid', text: 'Tableau de bord' }] },
      { label: 'Catalogue', items: [{ id: 'catalog', icon: 'car', text: d.admin ? 'Catalogue & prix' : 'Catalogue', count: d.catalog.length }] },
      { label: 'Activité', items: [{ id: 'sales', icon: 'clock', text: 'Ventes' }] }];
    const v = this['view_' + this.view]();
    $root.innerHTML = shellSide({ profile: { initials: initials(d.agent), title: d.agent, sub: `${d.jobLabel} · ${d.gradeLabel || ''}` }, nav, active: this.view,
      foot: `<small>Commission vendeur : <b style="color:var(--text-2)">${d.commission}%</b> · libre-service : <b style="color:var(--text-2)">${d.selfService ? 'oui' : 'non'}</b></small>`, head: v.head, body: v.body });
  },

  saleRow(h) {
    return `<div class="logline"><b>${esc(h.label)}</b> · ${esc(h.plate)} · <span style="color:var(--ok)">${money(h.price)}</span><br>${esc(h.buyer_name || '')} ← ${esc(h.seller_name || '')}${h.commission ? ` · commission ${money(h.commission)}` : ''}${h.tax ? ` · taxe ${money(h.tax)}` : ''} · ${fmtDate(h.t)}</div>`;
  },

  view_home() {
    const d = this.d, s = d.stats;
    return {
      head: { icon: 'car', title: 'Tableau de bord', sub: `${d.jobLabel} — concession`, acts: `<button class="primary" data-a="nav" data-v="catalog">${ic('car', 16)} Catalogue</button>` },
      body: `<div class="grid2" style="grid-template-columns:380px 1fr"><div class="card"><div class="eyebrow">Chiffre d'affaires · 30 jours</div><div class="big">${Number(s.revenue).toLocaleString('fr-FR')}<small>$</small></div>${chip(`${s.sales} vente(s)`, 'ok')}</div>
        <div><div class="grid4" style="margin-bottom:14px">${[['Au catalogue', s.vehicles, `${s.enabled} en vente${d.auto ? ' · auto' : ''}`], ['Ventes', s.sales, '30 jours'], ['Commissions', money(s.commission), 'versées aux vendeurs'], ['Taxes', money(s.tax), 'payées à l\'État']].map(([l, v, sub]) => `<div class="stat"><div class="eyebrow">${l}</div><div class="v">${v}</div><div class="s">${sub}</div></div>`).join('')}</div>
        <div class="card"><div class="card-h"><div class="t">${ic('clock', 16)} Dernières ventes</div><button class="sm" data-a="nav" data-v="sales">Tout voir</button></div>${d.sales.slice(0, 6).map(h => this.saleRow(h)).join('') || '<p class="hint">Aucune vente pour l\'instant.</p>'}</div></div></div>`,
    };
  },

  view_sales() {
    return { head: { icon: 'clock', title: 'Ventes', sub: 'Historique des 40 dernières ventes' }, body: `<div class="card">${this.d.sales.map(h => this.saleRow(h)).join('') || '<p class="hint">Aucune vente.</p>'}</div>` };
  },

  view_catalog() {
    const d = this.d, admin = d.admin, q = this.q.toLowerCase();
    const idx = [];
    this.draft.forEach((v, i) => { if ((!this.cat || v.category === this.cat) && (!q || (v.label + ' ' + v.model).toLowerCase().includes(q))) idx.push(i); });
    const shown = idx.slice(0, this.limit);
    const adjusted = this.draft.filter(v => v._o || v.src !== 'table').length;
    const gsel = (i, v) => `<select data-path="draft.${i}.min_grade" data-t="n" title="Grade min. pour vendre">${d.grades.map((g, k) => `<option value="${k}" ${Number(v) === k ? 'selected' : ''}>${k} · ${esc(g.label)}</option>`).join('')}</select>`;
    const cols = '1fr 1.4fr 110px 80px 1.2fr 80px 36px 118px';
    const rowAdmin = i => { const v = this.draft[i]; return `<div class="cat-row ${v.enabled ? '' : 'off'}" style="grid-template-columns:${cols};${v._o || v.src !== 'table' ? 'border-color:rgba(251,191,36,.45)' : ''}">
        <input placeholder="modèle" data-path="draft.${i}.model" value="${esc(v.model)}" ${v.src === 'custom' ? '' : 'disabled'}><input placeholder="Nom" data-path="draft.${i}.label" value="${esc(v.label)}">
        <input type="number" min="0" placeholder="Prix" data-path="draft.${i}.price" data-t="n" value="${v.price}"><input type="number" min="-1" title="-1 = illimité" data-path="draft.${i}.stock" data-t="n" value="${v.stock}">
        ${gsel(i, v.min_grade)}<select data-path="draft.${i}.vtype">${['car', 'bike', 'boat', 'aircraft'].map(t => `<option value="${t}" ${v.vtype === t ? 'selected' : ''}>${t}</option>`).join('')}</select>
        <input type="checkbox" data-path="draft.${i}.enabled" data-t="b" ${v.enabled ? 'checked' : ''} title="En vente">
        <div class="row" style="gap:6px"><button class="sm" data-a="sell" data-v="${esc(v.model)}">Vendre</button>${v.src === 'table' && !v._o ? '' : `<button class="icon" title="${v.src === 'custom' ? 'Supprimer' : 'Revenir au prix de la table'}" data-a="${v.src === 'custom' ? 'delVeh' : 'resetVeh'}" data-v="${i}">${ic(v.src === 'custom' ? 'trash' : 'x', 14)}</button>`}</div></div>`; };
    const rowRead = i => { const v = this.draft[i]; return `<div class="item">${tile('car')}<div class="grow"><b>${esc(v.label)}</b><small>${esc(v.category || 'Véhicule')} · ${v.stock < 0 ? 'stock illimité' : v.stock + ' en stock'}${v.enabled ? '' : ' · hors vente'}</small></div><span class="price">${money(v.price)}</span>${v.enabled && v.stock !== 0 ? `<button class="sm primary" data-a="sell" data-v="${esc(v.model)}">Vendre</button>` : ''}</div>`; };
    const filters = `<div class="row" style="margin-bottom:14px;flex-wrap:wrap"><div style="flex:1;min-width:220px;position:relative"><input data-path="q" id="dl-q" placeholder="Rechercher un véhicule…" value="${esc(this.q)}" style="padding-left:38px"><span style="position:absolute;left:12px;top:10px;color:var(--muted)">${ic('search', 16)}</span></div>
      <select data-path="cat" style="width:220px"><option value="">Toutes les catégories</option>${d.categories.map(c => `<option value="${esc(c.name)}" ${this.cat === c.name ? 'selected' : ''}>${esc(c.label)}</option>`).join('')}</select>
      ${admin ? `<button data-a="addBlank">${ic('plus', 15)} Véhicule personnalisé</button>` : ''}</div>`;
    return {
      head: { icon: 'car', title: admin ? 'Catalogue & prix' : 'Catalogue', sub: `${this.draft.length} véhicule(s) · ${adjusted} ajusté(s)${this.dirty ? ' — modifications non enregistrées' : ''}`,
        acts: admin ? `<button class="primary" data-a="saveCat" style="height:38px">Enregistrer les ajustements</button>` : '' },
      body: `${d.auto ? `<div class="card" style="margin-bottom:14px"><p class="hint">${ic('check', 14)} <b>Catalogue automatique</b> : tous les véhicules de ta table <b>vehicles</b> sont vendables${d.restricted.length ? ' (catégories : ' + esc(d.restricted.join(', ')) + ')' : ''} à <b>${d.markup}%</b> de leur prix. ${admin ? 'Modifie un prix, un stock, un grade ou masque un véhicule pour créer un <b>ajustement</b> (cadre jaune).' : ''}</p></div>` : `<div class="card" style="margin-bottom:14px"><p class="hint">Catalogue automatique désactivé : seuls les véhicules ajoutés par la direction sont en vente.</p></div>`}
        ${filters}
        ${admin ? `<div class="cat-row" style="grid-template-columns:${cols};background:none;border:0;padding:0 10px">${['Modèle', 'Nom', 'Prix', 'Stock', 'Grade min.', 'Type', 'Vente', ''].map(h => `<span class="lbl">${h}</span>`).join('')}</div>` : ''}
        ${shown.map(i => admin ? rowAdmin(i) : rowRead(i)).join('') || emptyState('car', 'Aucun véhicule', admin ? 'Aucun résultat : change le filtre ou ajoute un véhicule personnalisé.' : 'Aucun véhicule ne correspond.')}
        ${idx.length > shown.length ? `<div class="row" style="justify-content:center;margin-top:10px"><button data-a="more">Afficher plus (${idx.length - shown.length} restants)</button></div>` : ''}`,
    };
  },

  async onA(el) {
    const a = el.dataset.a, v = el.dataset.v;
    switch (a) {
      case 'nav': this.view = v; return this.render();
      case 'more': this.limit += 60; return this.render();
      case 'addBlank': this.draft.unshift({ model: '', label: '', category: '', vtype: 'car', price: 0, stock: -1, min_grade: 0, enabled: true, src: 'custom', _o: true }); this.dirty = true; this.cat = ''; this.q = ''; return this.render();
      case 'delVeh': { const r = this.draft[+v]; if (r.model) this.resets.push(r.model); this.draft.splice(+v, 1); this.dirty = true; return this.render(); }
      case 'resetVeh': {
        if (this.dirty) return toast('Enregistre d\'abord tes modifications, puis remets ce véhicule à zéro', 'err');
        const r = await rpc('dealer:saveCatalog', { rows: [], reset: [this.draft[+v].model] });
        if (!r || !r.ok) return toast((r && r.error) || 'Erreur', 'err');
        this.d = r; this.draft = this.prep(r.catalog); toast('Véhicule remis au prix de la table', 'ok'); return this.render();
      }
      case 'saveCat': {
        const rows = this.draft.filter(x => x._o || x.src === 'custom').map(({ model, label, category, vtype, price, stock, min_grade, enabled }) => ({ model, label, category, vtype, price, stock, min_grade, enabled }));
        const r = await rpc('dealer:saveCatalog', { rows, reset: this.resets });
        if (!r || !r.ok) return toast((r && r.error) || 'Erreur', 'err');
        this.d = r; this.draft = this.prep(r.catalog); this.resets = []; this.dirty = false; toast('Ajustements enregistrés', 'ok'); return this.render();
      }
      case 'sell': { const r = await rpc('dealer:offer', String(v)); if (r && r.ok) { toast('Offre envoyée au client, en attente de sa réponse', 'ok'); close(); } else toast((r && r.error) || 'Erreur', 'err'); return; }
    }
  },

  onInput(el, isChange) {
    const path = el.dataset.path; if (!path) return;
    if (path === 'q' || path === 'cat') {
      if (path === 'q' && isChange) return;
      const pos = el.selectionStart; this[path] = el.value; this.limit = 60; this.render();
      if (path === 'q') { const inp = document.getElementById('dl-q'); if (inp) { inp.focus(); inp.setSelectionRange(pos, pos); } }
      return;
    }
    let val = el.value;
    if (el.dataset.t === 'b') val = el.checked; else if (el.dataset.t === 'n') val = val === '' ? null : Number(val);
    setPath(this, path, val);
    const m = path.match(/^draft\.(\d+)\./);
    if (m) { const row = this.draft[+m[1]]; if (!row._o) { row._o = true; } this.dirty = true; }
  },
};

/* ════════════════════════════ GOUVERNEMENT ════════════════════════════ */
const Gov = {
  d: null, view: 'home', taxes: null,

  open(data) { this.d = data; this.taxes = clone(data.taxes); this.view = this.view || 'home'; this.render(); },
  set(r) { this.d = r; this.taxes = clone(r.taxes); this.render(); },

  logLabel: { tax: 'Taxe collectée', deposit: 'Dépôt', withdraw: 'Retrait', grant: 'Subvention', prime: 'Prime' },
  taxName: { dealer: 'Ventes de véhicules', realestate: 'Immobilier', shop: 'Boutiques', invoice: 'Factures' },

  logRow(l) {
    const pos = l.amount >= 0;
    return `<div class="logline"><b>${esc(this.logLabel[l.kind] || l.kind)}</b>${l.source ? ' · ' + esc(this.taxName[l.source] || l.source) : ''} · <span style="color:${pos ? 'var(--ok)' : 'var(--danger)'}">${pos ? '+' : ''}${money(l.amount)}</span><br>${esc(l.actor || '')} ${l.detail ? '· ' + esc(l.detail) : ''} · ${fmtDate(l.t)}</div>`;
  },

  render() {
    const d = this.d;
    const items = [{ id: 'home', icon: 'grid', text: 'Tableau de bord' }];
    const fin = d.admin ? [{ id: 'treasury', icon: 'dollar', text: 'Trésor public' }, { id: 'taxes', icon: 'percent', text: 'Taxes' }, { id: 'grants', icon: 'briefcase', text: 'Subventions' }, { id: 'primes', icon: 'gift', text: 'Primes' }] : [];
    const nav = [{ label: 'Général', items }, ...(fin.length ? [{ label: 'Finances', items: fin }] : []), { label: 'Communication', items: [{ id: 'announce', icon: 'megaphone', text: 'Annonce officielle' }, { id: 'journal', icon: 'clock', text: 'Journal' }] }];
    const v = this['view_' + this.view]();
    $root.innerHTML = shellSide({ profile: { initials: initials(d.agent), title: d.agent, sub: `${d.jobLabel} · ${d.gradeLabel || ''}` }, nav, active: this.view, foot: '', head: v.head, body: v.body });
  },

  view_home() {
    const d = this.d, s = d.stats;
    return {
      head: { icon: 'landmark', title: 'Tableau de bord', sub: `${d.jobLabel} — trésor public` },
      body: `<div class="grid2" style="grid-template-columns:380px 1fr"><div class="card"><div class="eyebrow">Solde du trésor</div><div class="big" data-live="money">${Number(d.balance).toLocaleString('fr-FR')}<small>$</small></div>${chip(`${money(s.taxTotal)} de taxes · 30 j`, 'ok')}</div>
        <div><div class="grid4" style="margin-bottom:14px">${Object.entries(d.taxes).map(([k, v]) => `<div class="stat"><div class="eyebrow">${esc(this.taxName[k] || k)}</div><div class="v">${v}%</div><div class="s">${money(s.tax[k] || 0)} perçus</div></div>`).join('')}</div>
        <div class="card"><div class="card-h"><div class="t">${ic('clock', 16)} Mouvements récents</div><button class="sm" data-a="nav" data-v="journal">Tout voir</button></div>${d.log.slice(0, 6).map(l => this.logRow(l)).join('') || '<p class="hint">Aucun mouvement.</p>'}</div></div></div>`,
    };
  },

  view_treasury() {
    const d = this.d;
    return { head: { icon: 'dollar', title: 'Trésor public', sub: d.jobLabel },
      body: `<div class="grid2"><div class="card"><div class="eyebrow">Solde</div><div class="big" data-live="money">${Number(d.balance).toLocaleString('fr-FR')}<small>$</small></div></div>
        <div class="card"><div class="eyebrow" style="margin-bottom:12px">Opération</div>${fld('Montant', '<input type="number" min="1" id="gm" placeholder="0">')}<div class="row mt"><button style="flex:1" data-a="gwd">Retirer</button><button class="primary" style="flex:1" data-a="gdep">Déposer</button></div></div></div>` };
  },

  view_taxes() {
    const t = this.taxes;
    return { head: { icon: 'percent', title: 'Taxes', sub: 'Prélevées sur les ventes des sociétés au profit du trésor', acts: `<button class="primary" data-a="saveTaxes" style="height:38px">Enregistrer</button>` },
      body: `<div class="card"><div class="tax-grid">${Object.keys(t).map(k => fld(this.taxName[k] || k, `<input type="number" min="0" max="50" data-path="taxes.${k}" data-t="n" value="${t[k]}">`)).join('')}</div>
        <p class="hint mt">Pourcentage de chaque transaction versé au trésor (0 = aucune taxe, 50 max). La part de la société qui vend est réduite d'autant. Les factures du gouvernement lui-même ne sont pas taxées.</p></div>` };
  },

  view_grants() {
    const d = this.d;
    return { head: { icon: 'briefcase', title: 'Subventions', sub: `Versement du trésor vers le compte d'une société — max ${money(d.limits.grantMax)}` },
      body: `<div class="card"><div class="grid3">${fld('Société', `<select id="gr-t">${d.societies.map(s => `<option value="${esc(s.name)}">${esc(s.label)}</option>`).join('')}</select>`)}${fld('Montant ($)', '<input type="number" min="1" id="gr-a">')}${fld('Motif', '<input id="gr-r" maxlength="120" placeholder="Budget annuel">')}</div>
        <div class="row mt"><button class="primary" data-a="grant" ${d.societies.length ? '' : 'disabled'}>Verser la subvention</button><span class="hint">Solde du trésor : <b>${money(d.balance)}</b></span></div></div>` };
  },

  view_primes() {
    const d = this.d;
    return { head: { icon: 'gift', title: 'Primes', sub: `Prime versée à un citoyen — max ${money(d.limits.primeMax)}` },
      body: `<div class="card"><p class="hint" style="margin-bottom:14px">Le citoyen <b>le plus proche</b> de toi reçoit la prime sur son compte bancaire.</p><div class="grid2">${fld('Montant ($)', '<input type="number" min="1" id="pr-a">')}${fld('Motif', '<input id="pr-r" maxlength="120" placeholder="Prime exceptionnelle">')}</div>
        <div class="row mt"><button class="primary" data-a="prime">Verser la prime</button><span class="hint">Solde du trésor : <b>${money(d.balance)}</b></span></div></div>` };
  },

  view_announce() {
    const d = this.d;
    return { head: { icon: 'megaphone', title: 'Annonce officielle', sub: 'Affichée à tous les joueurs pendant 12 secondes' },
      body: `<div class="card"><label class="f"><span>Message (${d.limits.announceMax} caractères max)</span><textarea id="an-t" maxlength="${d.limits.announceMax}" placeholder="Citoyens, …"></textarea></label>
        <div class="row mt"><button class="primary" data-a="announce">${ic('megaphone', 16)} Diffuser</button><span class="hint">Délai entre deux annonces : ${d.limits.cooldown} s${d.limits.cooldownLeft ? ` · encore ${d.limits.cooldownLeft} s` : ''}</span></div></div>` };
  },

  view_journal() {
    return { head: { icon: 'clock', title: 'Journal du trésor', sub: '40 derniers mouvements' }, body: `<div class="card">${this.d.log.map(l => this.logRow(l)).join('') || '<p class="hint">Journal vide.</p>'}</div>` };
  },

  async onA(el) {
    const a = el.dataset.a, v = el.dataset.v, val = id => document.getElementById(id).value;
    const done = (r, msg) => { if (!r || !r.ok) { toast((r && r.error) || 'Erreur', 'err'); return false; } toast(msg, 'ok'); this.set(r); return true; };
    switch (a) {
      case 'nav': this.view = v; return this.render();
      case 'gdep': case 'gwd': return done(await rpc('gov:money', a === 'gdep' ? 'deposit' : 'withdraw', Number(val('gm'))), 'Opération effectuée');
      case 'saveTaxes': return done(await rpc('gov:setTaxes', this.taxes), 'Taxes enregistrées');
      case 'grant': return done(await rpc('gov:grant', val('gr-t'), Number(val('gr-a')), val('gr-r')), 'Subvention versée');
      case 'prime': return done(await rpc('gov:prime', 0, Number(val('pr-a')), val('pr-r')), 'Prime versée');
      case 'announce': return done(await rpc('gov:announce', val('an-t')), 'Annonce diffusée');
    }
  },

  onInput(el) {
    const path = el.dataset.path; if (!path) return;
    let val = el.value; if (el.dataset.t === 'n') val = val === '' ? 0 : Number(val);
    setPath(this, path, val);
  },
};

/* ════════════════════════════ TABLETTE POLICE ════════════════════════════ */
const KIND_CHIP = { fine: ['Amende', 'warn'], arrest: ['Arrestation', 'bad'], warning: ['Avertissement', 'info'], note: ['Note', 'mute'], seizure: ['Saisie', 'info'], jail: ['Prison', 'bad'], wanted: ['Recherche', 'bad'] };
const CALL_STYLE = { citizen: ['Appel citoyen', 'info'], officer: ['Dispatch', 'info'], panic: ['PANIQUE', 'bad'], pursuit: ['Poursuite', 'warn'], alert: ['Alerte', 'warn'] };
const ago = t => { const s = Math.max(0, Math.floor(Date.now() / 1000 - t)); return s < 60 ? `il y a ${s} s` : s < 3600 ? `il y a ${Math.floor(s / 60)} min` : `il y a ${Math.floor(s / 3600)} h`; };

const Tablet = {
  d: null, tab: 'home', live: null, trail: [], recs: [], q: '', wantedOnly: false, sel: null, rec: null, form: null,
  fineIdx: 0, fineRec: null, nearby: null, callForm: false, callsAll: false,
  M: { cx: 0, cy: 0, scale: 0.35, layers: { units: true, calls: true, labels: true, grid: true }, img: null, imgOk: false, disp: {}, drag: null, follow: true, loaded: false },

  async open(d) {
    this.d = d; this.tab = 'home'; this.live = null; this.trail = []; this.sel = null; this.rec = null; this.form = null; this.q = ''; this.nearby = null; this.callForm = false;
    this.M.disp = {}; this.M.follow = true; this.M.loaded = false;
    const mp = d.map || {};
    let saved = null; try { saved = JSON.parse(localStorage.getItem('jb_tmap_label') || 'null'); } catch (e) {}
    this.M.label = { color: (saved && saved.color) || rgbHex(mp.LabelColor || [255, 255, 255]), outline: saved ? saved.outline !== false : mp.LabelOutline !== false };
    this.M.img = null; this.M.imgOk = false; this.M.tiles = {}; this.M.tileLoaded = 0; this.M.tileFailed = 0;
    if (mp.Image) { const im = new Image(); im.onload = () => { this.M.imgOk = true; }; im.onerror = () => { this.M.imgOk = false; }; im.src = mp.Image; this.M.img = im; }
    this.poll(true);
    this.render();
  },

  nav() {
    const p = this.d.perms, items = [{ id: 'home', icon: 'grid', text: 'Accueil' }];
    if (p.records) items.push({ id: 'records', icon: 'folder', text: 'Casiers' });
    if (p.fine) items.push({ id: 'fines', icon: 'dollar', text: 'Amendes' });
    if (p.dispatch) items.push({ id: 'dispatch', icon: 'siren', text: 'Dispatch' });
    if (p.map) items.push({ id: 'map', icon: 'map', text: 'Carte en direct' });
    return items;
  },

  render() {
    const d = this.d, t = this.tab;
    if (!this.nav().some(n => n.id === t)) this.tab = 'home';
    $root.classList.remove('corner');
    $root.innerHTML = shellSide({ profile: { initials: initials(d.jobLabel), title: 'Tablette', sub: `${d.jobLabel} · ${d.gradeLabel || ''}` }, nav: [{ label: 'Tablette', items: this.nav() }], active: this.tab,
      foot: `<small>${d.perms.admin ? 'Accès direction : suppressions autorisées.' : 'Les données de cette tablette appartiennent à ton service uniquement.'}</small>`,
      head: { icon: 'tablet', title: `Tablette — ${d.jobLabel}`, sub: ({ home: 'Vue d\'ensemble', records: 'Casiers judiciaires', fines: 'Amendes', dispatch: 'Dispatch', map: 'Carte en temps réel' })[this.tab] }, body: this['tab_' + this.tab]() });
    if (this.tab === 'map') this.mapStart();
  },

  /* ── Accueil ── */
  tab_home() {
    const d = this.d, s = d.stats;
    const live = this.live;
    return `<div class="grid4" style="margin-bottom:16px">${[['Casiers', s.records, 'enregistrés'], ['Recherchés', s.wanted, 'avis actifs'], ['Appels actifs', live ? live.calls.filter(c => c.status !== 'closed').length : s.calls, 'dispatch'], ['Unités', live && live.units.length ? live.units.length : s.units, 'en service']].map(([l, v, sub]) => `<div class="stat"><div class="eyebrow">${l}</div><div class="v">${v}</div><div class="s">${sub}</div></div>`).join('')}</div>
      ${live && live.pursuit ? `<div class="card" style="border-color:rgba(248,113,113,.5)"><div class="card-h"><div class="t">${ic('siren', 16)} Poursuite en cours</div>${chip('EN DIRECT', 'bad')}</div><p class="hint">Suspect : <b>${esc(live.pursuit.name)}</b> · ${live.pursuit.speed} km/h · lancée par ${esc(live.pursuit.by)}.</p><button class="primary" data-a="nav" data-v="map">${ic('map', 15)} Voir la carte</button></div>` : ''}
      <div class="grid2"><div class="card"><div class="card-h"><div class="t">Actions rapides</div></div><div style="display:flex;flex-direction:column;gap:10px">
        ${d.perms.records ? `<button data-a="newRec">${ic('plus', 15)} Nouveau casier</button>` : ''}${d.perms.fine ? `<button data-a="nav" data-v="fines">${ic('dollar', 15)} Donner une amende</button>` : ''}
        ${d.perms.dispatch ? `<button data-a="nav" data-v="dispatch">${ic('siren', 15)} Dispatch</button>` : ''}${d.perms.map ? `<button data-a="nav" data-v="map">${ic('map', 15)} Carte en direct</button>` : ''}</div>
        <p class="hint mt">Amendes des 30 derniers jours : <b style="color:var(--text)">${money(s.fines)}</b></p></div>
      <div class="card"><div class="card-h"><div class="t">Activité récente</div></div>${d.recent.length ? d.recent.map(e => `<div class="logline"><b>${esc(e.firstname + ' ' + e.lastname)}</b> · ${esc((KIND_CHIP[e.kind] || [e.kind])[0])} : ${esc(e.label)}${e.amount ? ' · ' + money(e.amount) : ''}<br>${esc(e.officer || '')} · ${fmtDate(e.t)}</div>`).join('') : '<p class="hint">Rien pour le moment.</p>'}</div></div>`;
  },

  /* ── Casiers ── */
  tab_records() {
    const R = this.rec, f = this.form;
    return `<div class="pts"><div>
      <div class="row" style="margin-bottom:10px"><input id="t-q" placeholder="Rechercher un nom…" value="${esc(this.q)}" style="flex:1"><button class="icon" data-a="recSearch">${ic('search', 16)}</button></div>
      <label class="chk" style="margin-bottom:10px"><input type="checkbox" data-a="wantedOnly" ${this.wantedOnly ? 'checked' : ''}> Recherchés uniquement</label>
      <button class="sm" data-a="newRec" style="width:100%;margin-bottom:10px">${ic('plus', 14)} Nouveau casier</button>
      ${this.recs.map(r => `<div class="pt ${this.sel === r.id ? 'active' : ''}" data-a="recOpen" data-v="${r.id}">${tile(r.wanted ? 'siren' : 'user')}<div style="flex:1;min-width:0"><b>${esc(r.name)}</b><small>${r.wanted ? '<span style="color:var(--danger)">RECHERCHÉ</span> · ' : ''}${r.n} entrée(s)</small></div></div>`).join('') || '<p class="hint">Aucun casier trouvé.</p>'}</div>
      <div>${f ? this.recForm() : R ? this.recDetail() : emptyState('folder', 'Aucun casier ouvert', 'Recherche une personne ou crée un nouveau casier.')}</div></div>`;
  },

  recDetail() {
    const R = this.rec.record, E = this.rec.entries, adm = this.d.perms.admin;
    return `<div class="card"><div class="card-h"><div class="t">${ic('user', 16)} ${esc(R.firstname + ' ' + R.lastname)}</div><div class="row" style="gap:8px">${R.wanted ? chip('Recherché', 'bad') : chip('Aucun avis', 'mute')}${R.online ? chip('En ligne', 'ok') : ''}</div></div>
      <div class="grid3"><div class="stat"><div class="eyebrow">Naissance</div><div class="s" style="font-size:14px;color:var(--text)">${esc(R.birthdate || '—')}</div></div>
        <div class="stat"><div class="eyebrow">Entrées</div><div class="v">${E.length}</div></div><div class="stat"><div class="eyebrow">Amendes payées</div><div class="v">${money(this.rec.fines)}</div></div></div>
      ${R.wanted ? `<p class="hint mt" style="color:var(--danger)">Avis de recherche : ${esc(R.wanted_reason || 'sans motif')}</p>` : ''}
      <p class="hint mt" style="white-space:pre-wrap">${esc(R.notes || 'Aucune note.')}</p>
      <div class="row wrap mt"><button data-a="recEdit">${ic('edit', 15)} Modifier</button>${this.d.perms.fine ? `<button data-a="recFine">${ic('dollar', 15)} Amender</button>` : ''}
        <button data-a="recWanted">${R.wanted ? 'Lever l\'avis de recherche' : 'Émettre un avis de recherche'}</button>${adm ? `<button class="danger" data-a="recDel">${ic('trash', 15)} Supprimer</button>` : ''}</div></div>
      <div class="card"><div class="card-h"><div class="t">Ajouter une entrée</div></div>
        <div class="form-row" style="grid-template-columns:150px 1.4fr 110px"><label class="f"><span>Type</span><select id="te-k">${['arrest', 'warning', 'fine', 'seizure', 'jail', 'note'].map(k => `<option value="${k}">${KIND_CHIP[k][0]}</option>`).join('')}</select></label>
          ${fld('Motif', '<input id="te-l" maxlength="120" placeholder="ex: Excès de vitesse">')}${fld('Montant ($)', '<input id="te-a" type="number" min="0" value="0">')}</div>
        ${fld('Détails (optionnel)', '<textarea id="te-d" maxlength="1000" style="min-height:60px"></textarea>')}
        <div class="row mt"><button class="primary" data-a="entryAdd">${ic('plus', 15)} Enregistrer</button></div></div>
      <div class="card"><div class="card-h"><div class="t">Historique</div></div>${E.length ? E.map(e => `<div class="item"><div class="grow"><b>${esc(e.label)}</b><small>${esc(e.officer || '')} · ${fmtDate(e.t)}${e.details ? ' · ' + esc(e.details) : ''}</small></div>
        ${e.amount ? `<span class="price">${money(e.amount)}</span>` : ''}${chip(...KIND_CHIP[e.kind] || [e.kind, 'mute'])}${adm ? `<button class="icon danger" data-a="entryDel" data-v="${e.id}">${ic('trash', 14)}</button>` : ''}</div>`).join('') : '<p class="hint">Aucune entrée.</p>'}</div>`;
  },

  recForm() {
    const f = this.form;
    return `<div class="card"><div class="card-h"><div class="t">${ic('edit', 16)} ${f.id ? 'Modifier le casier' : 'Nouveau casier'}</div></div>
      <div class="grid3">${fld('Prénom', `<input data-path="Tablet.form.firstname" value="${esc(f.firstname)}" maxlength="50">`)}${fld('Nom', `<input data-path="Tablet.form.lastname" value="${esc(f.lastname)}" maxlength="50">`)}${fld('Naissance', `<input data-path="Tablet.form.birthdate" value="${esc(f.birthdate)}" maxlength="20" placeholder="JJ/MM/AAAA">`)}</div>
      <div class="mt">${fld('Notes', `<textarea data-path="Tablet.form.notes" maxlength="2000">${esc(f.notes)}</textarea>`)}</div>
      <div class="grid2 mt"><label class="chk" style="align-self:end;height:38px"><input type="checkbox" data-path="Tablet.form.wanted" data-t="b" ${f.wanted ? 'checked' : ''}> Avis de recherche</label>${fld('Motif de la recherche', `<input data-path="Tablet.form.wanted_reason" value="${esc(f.wanted_reason)}" maxlength="200">`)}</div>
      <div class="row mt"><button class="primary" data-a="recSave">${ic('check', 15)} Enregistrer</button><button data-a="recCancel">Annuler</button>
        ${f.id ? '' : `<span class="spacer"></span><button data-a="recNearest">${ic('user', 15)} Personne en face</button>`}</div></div>`;
  },

  /* ── Amendes ── */
  tab_fines() {
    const d = this.d, list = d.fines;
    const cur = this.fineIdx > 0 ? list[this.fineIdx - 1] : null;
    return `<div class="grid2"><div class="card"><div class="card-h"><div class="t">${ic('dollar', 16)} Catalogue d'amendes</div></div>
      ${list.map((f, i) => `<div class="item click ${this.fineIdx === i + 1 ? 'sel' : ''}" data-a="fineSel" data-v="${i + 1}" style="${this.fineIdx === i + 1 ? 'border-color:var(--accent-line);background:var(--accent-soft)' : ''}"><div class="grow"><b>${esc(f.label)}</b></div><span class="price">${money(f.amount)}</span></div>`).join('') || '<p class="hint">Catalogue vide.</p>'}
      ${d.fineCustom ? `<div class="item click" data-a="fineSel" data-v="0" style="margin-top:6px;${this.fineIdx === 0 ? 'border-color:var(--accent-line);background:var(--accent-soft)' : ''}"><div class="grow"><b>Amende libre</b><small>Motif et montant au choix (${money(d.limits.min)} à ${money(d.limits.max)})</small></div></div>` : ''}</div>
      <div class="card"><div class="card-h"><div class="t">Envoyer l'amende</div></div>
        ${this.fineIdx === 0 && d.fineCustom ? `<div class="grid2">${fld('Motif', '<input id="tf-l" maxlength="60" placeholder="ex: Nuisances sonores">')}${fld('Montant ($)', `<input id="tf-a" type="number" min="${d.limits.min}" max="${d.limits.max}" value="${d.limits.min}">`)}</div>`
          : `<div class="stat"><div class="eyebrow">Amende choisie</div><div class="v" style="font-size:18px">${cur ? esc(cur.label) : '—'}</div><div class="s">${cur ? money(cur.amount) : 'Sélectionne une amende dans le catalogue'}</div></div>`}
        <div class="mt">${fld('Remarque (casier)', '<input id="tf-n" maxlength="200" placeholder="optionnel">')}</div>
        ${this.fineRec ? `<p class="hint mt">Casier lié : <b style="color:var(--text)">${esc(this.fineRec.name)}</b> <a data-a="fineUnlink" style="cursor:pointer;color:var(--accent)">(retirer)</a></p>` : '<p class="hint mt">Le casier de la personne sera créé ou mis à jour automatiquement.</p>'}
        <p class="hint mt">La <b>personne la plus proche</b> reçoit l'amende à l'écran et la règle directement (l'argent va à la société). Le résultat apparaît dans son casier.</p>
        <button class="primary mt" data-a="fineSend" ${this.fineIdx === 0 && !d.fineCustom ? 'disabled' : ''}>${ic('dollar', 15)} Envoyer l'amende</button></div></div>`;
  },

  /* ── Dispatch ── */
  tab_dispatch() {
    return `<div class="row" style="margin-bottom:14px"><div class="seg" style="margin:0"><button class="${this.callsAll ? '' : 'active'}" data-a="callsFilter" data-v="0">Actifs</button><button class="${this.callsAll ? 'active' : ''}" data-a="callsFilter" data-v="1">Tous</button></div>
      <span class="spacer"></span><button class="primary" data-a="callNew">${ic('plus', 15)} Nouvel appel</button></div>
      ${this.callForm ? `<div class="card"><div class="card-h"><div class="t">Nouvel appel (ta position actuelle)</div></div><div class="grid2">${fld('Titre', '<input id="tc-t" maxlength="60" placeholder="ex: Braquage en cours">')}${fld('Détails', '<input id="tc-m" maxlength="240">')}</div>
        <div class="row mt"><button class="primary" data-a="callSend">Diffuser aux unités</button><button data-a="callNew">Annuler</button></div></div>` : ''}
      <div id="t-calls">${this.callsHtml()}</div><p class="hint mt">Les citoyens peuvent appeler avec <b>/${this.d.commands.call}</b>, les policiers peuvent lancer <b>/${this.d.commands.panic}</b> en cas de danger. Les appels se mettent à jour en direct.</p>`;
  },

  callsHtml() {
    const me = this.d.me.src, adm = this.d.perms.admin;
    const list = ((this.live && this.live.calls) || []).filter(c => this.callsAll || c.status !== 'closed');
    return list.map(c => { const k = CALL_STYLE[c.kind] || CALL_STYLE.alert, mine = c.units.some(u => u.src === me);
      return `<div class="card" style="padding:14px;margin-bottom:10px;${c.kind === 'panic' && c.status !== 'closed' ? 'border-color:rgba(248,113,113,.6)' : ''}"><div class="row"><div class="grow" style="flex:1;min-width:0"><div class="row" style="gap:8px">${chip(k[0], k[1])}<b>#${c.id} · ${esc(c.title)}</b></div>
        <p class="hint" style="margin:6px 0 0">${esc(c.message || '')}</p><small style="color:var(--muted)">${esc(c.by)} · ${ago(c.t)}${c.units.length ? ' · Unités : ' + c.units.map(u => esc(u.name)).join(', ') : ''}</small></div>
        ${c.status === 'closed' ? chip('Clôturé', 'mute') : `<div class="row wrap" style="gap:6px;justify-content:flex-end"><button class="sm ${mine ? '' : 'primary'}" data-a="callTake" data-v="${c.id}">${mine ? 'Quitter' : 'Prendre'}</button><button class="sm" data-a="callGps" data-x="${c.x}" data-y="${c.y}">GPS</button><button class="sm" data-a="callMap" data-x="${c.x}" data-y="${c.y}">Carte</button><button class="sm" data-a="callClose" data-v="${c.id}">Clôturer</button></div>`}
        ${adm ? `<button class="icon danger" data-a="callDel" data-v="${c.id}">${ic('trash', 14)}</button>` : ''}</div></div>`; }).join('') || '<p class="hint">Aucun appel.</p>';
  },

  /* ── Carte ── */
  tab_map() {
    const p = this.d.perms, M = this.M;
    return `<div class="tmap"><div class="tmap-main"><canvas id="tmap"></canvas><div class="tmap-tools">
        ${[['units', 'Unités'], ['calls', 'Appels'], ['labels', 'Noms'], ['grid', 'Grille']].map(([k, l]) => `<label class="chk"><input type="checkbox" data-a="layer" data-v="${k}" ${M.layers[k] ? 'checked' : ''}> ${l}</label>`).join('')}
        <label class="chk" title="Couleur des noms sur la carte">Couleur <input type="color" data-path="Tablet.M.label.color" value="${M.label.color}" style="width:34px;height:26px;padding:0;border-radius:6px"></label>
        <label class="chk"><input type="checkbox" data-path="Tablet.M.label.outline" ${M.label.outline ? 'checked' : ''}> Contour</label>
        <button class="sm" data-a="mapMe">Me centrer</button><button class="sm" data-a="mapChase">Fugitif</button></div></div>
      <div class="tmap-side"><div class="card" id="t-chase">${this.chaseHtml()}</div><div class="card"><div class="card-h"><div class="t">Unités (<span id="t-ucount">${this.live ? this.live.units.length : 0}</span>)</div></div><div id="t-units">${this.unitsHtml()}</div></div></div></div>`;
  },

  chaseHtml() {
    const L = this.live, p = L && L.pursuit, perms = this.d.perms;
    if (p) return `<div class="card-h"><div class="t">${ic('siren', 16)} Poursuite</div>${chip('EN DIRECT', 'bad')}</div><b>${esc(p.name)}</b><p class="hint" style="margin:4px 0 10px">${p.speed} km/h · ${p.veh ? 'en véhicule' : 'à pied'} · fin auto dans ${Math.floor(p.left / 60)} min<br>Lancée par ${esc(p.by)}</p><button class="danger" data-a="chaseStop" style="width:100%">Terminer la poursuite</button>`;
    if (!perms.pursuit) return `<div class="card-h"><div class="t">${ic('siren', 16)} Poursuite</div></div><p class="hint">Aucune poursuite en cours. Ton grade ne permet pas d'en lancer.</p>`;
    return `<div class="card-h"><div class="t">${ic('siren', 16)} Lancer une poursuite</div></div>${this.nearby ? (this.nearby.length ? this.nearby.map(n => `<div class="item"><div class="grow"><b>${esc(n.name)}</b><small>${n.dist} m · ${n.veh ? 'véhicule' : 'à pied'}${n.mate ? ' · collègue' : ''}</small></div><button class="sm danger" data-a="chaseStart" data-v="${n.src}">Poursuivre</button></div>`).join('') : '<p class="hint">Personne à proximité.</p>') : '<p class="hint">Détecte les personnes autour de toi pour désigner le fugitif : sa position s\'affiche en direct pour tout le service.</p>'}<button class="mt" data-a="chaseScan" style="width:100%">${ic('search', 15)} Chercher autour de moi</button>`;
  },

  unitsHtml() {
    const U = (this.live && this.live.units) || [];
    return U.map(u => `<div class="item click" data-a="mapUnit" data-x="${u.x}" data-y="${u.y}" style="padding:8px 10px"><div class="grow"><b>${esc(u.name)}${u.me ? ' (toi)' : ''}</b><small>${esc(u.grade || '')} · ${u.veh ? u.speed + ' km/h' : 'à pied'}</small></div></div>`).join('') || '<p class="hint">Aucune unité.</p>';
  },

  /* ── Données en direct ── */
  async poll(first) {
    const r = await rpc('tablet:live');
    if (!r || !r.ok) return;
    this.live = r;
    const M = this.M, P = r.pursuit;
    if (P) { const last = this.trail[this.trail.length - 1]; if (!last || Math.hypot(last[0] - P.x, last[1] - P.y) > 4) this.trail.push([P.x, P.y]); if (this.trail.length > (this.d.trail || 40)) this.trail.shift(); } else this.trail = [];
    r.units.forEach(u => { const k = 'u' + u.src; if (!M.disp[k]) M.disp[k] = { x: u.x, y: u.y }; M.disp[k].tx = u.x; M.disp[k].ty = u.y; });
    if (P) { if (!M.disp.p) M.disp.p = { x: P.x, y: P.y }; M.disp.p.tx = P.x; M.disp.p.ty = P.y; } else delete M.disp.p;
    const me = r.units.find(u => u.me);
    if (me && !M.loaded) { M.cx = me.x; M.cy = me.y; M.loaded = true; }
    if (M.follow && P) { M.cx += (P.x - M.cx) * 0.2; M.cy += (P.y - M.cy) * 0.2; }
    if (this.tab === 'dispatch') { const el = document.getElementById('t-calls'); if (el) el.innerHTML = this.callsHtml(); }
    else if (this.tab === 'map') {
      const c = document.getElementById('t-chase'), u = document.getElementById('t-units'), n = document.getElementById('t-ucount');
      if (c && !(this.nearby && !P)) c.innerHTML = this.chaseHtml(); else if (c && P) c.innerHTML = this.chaseHtml();
      if (u) u.innerHTML = this.unitsHtml(); if (n) n.textContent = r.units.length;
    }
  },

  mapStart() {
    const cv = document.getElementById('tmap'); if (!cv) return;
    const M = this.M;
    cv.onmousedown = e => { M.drag = { x: e.clientX, y: e.clientY }; M.follow = false; };
    window.onmouseup = () => { M.drag = null; };
    cv.onmousemove = e => { if (!M.drag) return; M.cx -= (e.clientX - M.drag.x) / M.scale; M.cy += (e.clientY - M.drag.y) / M.scale; M.drag = { x: e.clientX, y: e.clientY }; };
    cv.onwheel = e => { e.preventDefault(); const k = e.deltaY < 0 ? 1.18 : 1 / 1.18; M.scale = Math.min(6, Math.max(0.02, M.scale * k)); };
    clearInterval(this.timer);
    this.timer = setInterval(() => { if (Mod !== Tablet || this.tab !== 'map' || !document.getElementById('tmap')) { clearInterval(this.timer); return; } this.draw(); }, 60);
    this.draw();
  },

  // Tuiles standard « mapStyles » (même calage que les cartes GTA V les plus courantes) ; renvoie false si aucune tuile n'est disponible
  drawTiles(g, W, H, sx, sy) {
    const M = this.M, mp = this.d.map || {};
    if (!mp.Tiles || M.tileDown) return false;
    const TA = 0.02072, TB = 117.3, TC = -0.0205, TD = 172.8, maxZ = mp.TileMaxZoom || 5;
    const z = Math.max(0, Math.min(maxZ, Math.round(Math.log2(12355 * M.scale / 384)))), n = 2 ** z;
    const xMin = M.cx - W / 2 / M.scale, xMax = M.cx + W / 2 / M.scale, yMax = M.cy + H / 2 / M.scale, yMin = M.cy - H / 2 / M.scale;
    const col = x => Math.floor(n * (TA * x + TB) / 256), row = y => Math.floor(n * (TC * y + TD) / 256);
    const tx0 = Math.max(0, col(xMin)), tx1 = Math.min(n - 1, col(xMax)), ty0 = Math.max(0, row(yMax)), ty1 = Math.min(n - 1, row(yMin));
    const X = (t, zz) => (t * 256 / 2 ** zz - TB) / TA, Y = (t, zz) => (t * 256 / 2 ** zz - TD) / TC;
    const get = (zz, tx, ty) => {
      const key = zz + '/' + tx + '/' + ty;
      let t = M.tiles[key];
      if (!t) {
        if (Object.keys(M.tiles).length > 500) M.tiles = {};
        t = M.tiles[key] = { img: new Image(), ok: false };
        t.img.onload = () => { t.ok = true; M.tileLoaded++; };
        t.img.onerror = () => { t.fail = true; M.tileFailed++; if (!M.tileLoaded && M.tileFailed >= 6) M.tileDown = true; };
        t.img.src = mp.Tiles.replace('{z}', zz).replace('{x}', tx).replace('{y}', ty);
      }
      return t;
    };
    if ((tx1 - tx0 + 1) * (ty1 - ty0 + 1) > 120) return M.tileLoaded > 0;
    let drew = false;
    g.imageSmoothingEnabled = true;
    for (let tx = tx0; tx <= tx1; tx++) for (let ty = ty0; ty <= ty1; ty++) {
      const px = sx(X(tx, z)), py = sy(Y(ty, z)), w = (X(tx + 1, z) - X(tx, z)) * M.scale + 1, h = (Y(ty, z) - Y(ty + 1, z)) * M.scale + 1;
      const t = get(z, tx, ty);
      if (t.ok) { g.drawImage(t.img, px, py, w, h); drew = true; continue; }
      for (let k = 1; k <= 3 && z - k >= 0; k++) {          // en attendant la tuile : on étire celle du niveau inférieur
        const a = M.tiles[(z - k) + '/' + (tx >> k) + '/' + (ty >> k)];
        if (a && a.ok) { const sz = 256 / 2 ** k; g.drawImage(a.img, (tx - ((tx >> k) << k)) * sz, (ty - ((ty >> k) << k)) * sz, sz, sz, px, py, w, h); drew = true; break; }
      }
    }
    if (z > 0) for (let tx = Math.max(0, col(xMin) >> 1), e = Math.min(n / 2 - 1, col(xMax) >> 1); tx <= e; tx++) for (let ty = Math.max(0, row(yMax) >> 1), f = Math.min(n / 2 - 1, row(yMin) >> 1); ty <= f; ty++) get(z - 1, tx, ty);
    return drew || M.tileLoaded > 0;
  },

  draw() {
    const cv = document.getElementById('tmap'); if (!cv) return;
    const par = cv.parentElement, W = par.clientWidth, H = par.clientHeight;
    if (cv.width !== W || cv.height !== H) { cv.width = W; cv.height = H; }
    const g = cv.getContext('2d'), M = this.M, mp = this.d.map, L = this.live || { units: [], calls: [] };
    const sx = x => W / 2 + (x - M.cx) * M.scale, sy = y => H / 2 - (y - M.cy) * M.scale;
    const acc = getComputedStyle(document.documentElement).getPropertyValue('--accent-rgb').trim() || '64,224,208';
    g.fillStyle = '#0b0d10'; g.fillRect(0, 0, W, H);
    const tilesOn = this.drawTiles(g, W, H, sx, sy);
    if (!tilesOn) {
      if (M.imgOk && M.img) g.drawImage(M.img, sx(mp.MinX), sy(mp.MaxY), (mp.MaxX - mp.MinX) * M.scale, (mp.MaxY - mp.MinY) * M.scale);
      else { g.fillStyle = '#12161b'; g.fillRect(sx(mp.MinX), sy(mp.MaxY), (mp.MaxX - mp.MinX) * M.scale, (mp.MaxY - mp.MinY) * M.scale); }
    }
    const real = tilesOn || (M.imgOk && M.img);
    const hx = M.label.color.replace('#', ''), lum = (0.299 * parseInt(hx.slice(0, 2), 16) + 0.587 * parseInt(hx.slice(2, 4), 16) + 0.114 * parseInt(hx.slice(4, 6), 16)) / 255;
    const label = (txt, x, y, font, align) => {          // texte lisible sur tous les fonds : couleur réglable + contour sombre
      g.font = font; g.textAlign = align || 'center'; g.lineJoin = 'round';
      if (M.label.outline) { g.lineWidth = 3.5; g.strokeStyle = lum > 0.55 ? 'rgba(0,0,0,.85)' : 'rgba(255,255,255,.92)'; g.strokeText(txt, x, y); }   // contour opposé à la couleur du texte
      g.fillStyle = M.label.color; g.fillText(txt, x, y);
    };
    if (M.layers.grid && !real) {
      const step = M.scale > 0.5 ? 250 : M.scale > 0.12 ? 500 : 1000;
      g.strokeStyle = 'rgba(255,255,255,.06)'; g.lineWidth = 1; g.beginPath();
      for (let x = Math.ceil((M.cx - W / 2 / M.scale) / step) * step; x < M.cx + W / 2 / M.scale; x += step) { g.moveTo(sx(x), 0); g.lineTo(sx(x), H); }
      for (let y = Math.ceil((M.cy - H / 2 / M.scale) / step) * step; y < M.cy + H / 2 / M.scale; y += step) { g.moveTo(0, sy(y)); g.lineTo(W, sy(y)); }
      g.stroke();
    }
    if (!real) { g.font = '11px sans-serif'; g.textAlign = 'left'; (this.d.landmarks || []).forEach(([n, x, y]) => { const px = sx(x), py = sy(y); g.fillStyle = 'rgba(255,255,255,.22)'; g.fillRect(px - 2, py - 2, 4, 4); label(n, px + 6, py + 3, '11px sans-serif', 'left'); }); }
    // appels
    if (M.layers.calls) (L.calls || []).filter(c => c.status !== 'closed').forEach(c => {
      const px = sx(c.x), py = sy(c.y), pulse = c.kind === 'panic' ? 8 + 5 * Math.abs(Math.sin(Date.now() / 250)) : 8;
      g.fillStyle = c.kind === 'panic' ? '#ef4444' : c.kind === 'pursuit' ? '#f59e0b' : (window.PICKAX_ACCENT || '#00a4ff'); g.globalAlpha = .9; g.beginPath(); g.arc(px, py, pulse, 0, 7); g.fill(); g.globalAlpha = 1;
      g.fillStyle = '#000'; g.font = 'bold 10px sans-serif'; g.textAlign = 'center'; g.fillText('#' + c.id, px, py + 3.5);
    });
    // traînée + fugitif
    const pd = M.disp.p;
    if (pd && this.trail.length > 1) { g.lineWidth = 3; for (let i = 1; i < this.trail.length; i++) { g.strokeStyle = `rgba(239,68,68,${i / this.trail.length})`; g.beginPath(); g.moveTo(sx(this.trail[i - 1][0]), sy(this.trail[i - 1][1])); g.lineTo(sx(this.trail[i][0]), sy(this.trail[i][1])); g.stroke(); } }
    // fluidité : on rapproche l'affichage de la dernière position reçue
    Object.values(M.disp).forEach(o => { if (o.tx != null) { o.x += (o.tx - o.x) * 0.18; o.y += (o.ty - o.y) * 0.18; } });
    if (M.layers.units) (L.units || []).forEach(u => {
      const o = M.disp['u' + u.src] || { x: u.x, y: u.y }, px = sx(o.x), py = sy(o.y);
      g.save(); g.translate(px, py); g.rotate((-u.h) * Math.PI / 180);
      g.fillStyle = u.me ? '#fff' : `rgb(${acc})`; g.beginPath(); g.moveTo(0, -9); g.lineTo(6.5, 7); g.lineTo(0, 3.5); g.lineTo(-6.5, 7); g.closePath(); g.fill(); g.restore();
      if (M.layers.labels) label(u.name, px, py - 14, '600 11px sans-serif');
    });
    if (pd && L.pursuit) {
      const px = sx(pd.x), py = sy(pd.y), r = 9 + 6 * Math.abs(Math.sin(Date.now() / 220));
      g.strokeStyle = 'rgba(239,68,68,.55)'; g.lineWidth = 2; g.beginPath(); g.arc(px, py, r + 6, 0, 7); g.stroke();
      g.fillStyle = '#ef4444'; g.beginPath(); g.arc(px, py, 8, 0, 7); g.fill();
      label(L.pursuit.name + ' · ' + L.pursuit.speed + ' km/h', px, py - 20, 'bold 12px sans-serif');
    }
    g.lineJoin = 'round'; g.fillStyle = 'rgba(255,255,255,.35)'; g.font = '10px sans-serif'; g.textAlign = 'right';
    g.fillText(real ? 'Glisser pour déplacer · molette : zoom' : 'Carte schématique · ajoute les tuiles « mapStyles » dans html/map (voir README) · glisser / molette', W - 10, H - 10);
  },

  /* ── Actions ── */
  async loadRecs() { const r = await rpc('records:search', this.q, this.wantedOnly); if (r && r.ok) this.recs = r.list; },
  async openRec(id) { const r = await rpc('records:get', id); if (!r || !r.ok) return toast((r && r.error) || 'Erreur', 'err'); this.sel = id; this.rec = r; this.form = null; },

  async onA(el) {
    const a = el.dataset.a, v = el.dataset.v, d = this.d, ok = (r, m) => { if (!r || !r.ok) { toast((r && r.error) || 'Erreur', 'err'); return false; } if (m) toast(m, 'ok'); return true; };
    const val = id => (document.getElementById(id) || {}).value || '';
    switch (a) {
      case 'nav': this.tab = v; this.callForm = false; if (v === 'records') await this.loadRecs(); if (v === 'dispatch' || v === 'home') await this.poll(true); if (v === 'map') this.nearby = null; return this.render();
      case 'recSearch': this.q = val('t-q').trim(); await this.loadRecs(); return this.render();
      case 'wantedOnly': this.wantedOnly = el.checked; await this.loadRecs(); return this.render();
      case 'recOpen': await this.openRec(Number(v)); return this.render();
      case 'newRec': this.tab = 'records'; await this.loadRecs(); this.form = { id: null, firstname: '', lastname: '', birthdate: '', notes: '', wanted: false, wanted_reason: '' }; this.rec = null; this.sel = null; return this.render();
      case 'recEdit': this.form = { ...this.rec.record }; return this.render();
      case 'recCancel': this.form = null; return this.render();
      case 'recSave': { const r = await rpc('records:save', this.form); if (!ok(r, 'Casier enregistré')) return; await this.loadRecs(); await this.openRec(r.id); return this.render(); }
      case 'recNearest': { const r = await rpc('records:fromNearest', 0); if (!ok(r)) return; await this.loadRecs(); await this.openRec(r.id); return this.render(); }
      case 'recWanted': {
        const R = this.rec.record;
        if (!R.wanted) { this.form = { ...R, wanted: true, wanted_reason: '' }; return this.render(); }
        const r = await rpc('records:save', { ...R, wanted: false, wanted_reason: '' }); if (!ok(r, 'Avis de recherche levé')) return;
        await this.loadRecs(); await this.openRec(R.id); return this.render();
      }
      case 'recDel': if (!await confirmBox('Supprimer ce casier ?', 'Toutes les entrées du casier seront supprimées définitivement.', 'Supprimer')) return; if (!ok(await rpc('records:delete', this.sel), 'Casier supprimé')) return; this.rec = null; this.sel = null; await this.loadRecs(); return this.render();
      case 'entryAdd': { const r = await rpc('records:addEntry', this.sel, val('te-k'), val('te-l').trim(), Number(val('te-a')) || 0, val('te-d').trim()); if (!ok(r, 'Entrée ajoutée')) return; await this.openRec(this.sel); await this.loadRecs(); return this.render(); }
      case 'entryDel': if (!ok(await rpc('records:delEntry', Number(v)))) return; await this.openRec(this.sel); return this.render();
      case 'recFine': this.fineRec = { id: this.sel, name: this.rec.record.firstname + ' ' + this.rec.record.lastname }; this.tab = 'fines'; return this.render();
      case 'fineSel': this.fineIdx = Number(v); return this.render();
      case 'fineUnlink': this.fineRec = null; return this.render();
      case 'fineSend': { const r = await rpc('fine:send', this.fineRec ? this.fineRec.id : 0, 0, this.fineIdx, val('tf-l').trim(), Number(val('tf-a')) || 0, val('tf-n').trim()); if (ok(r, 'Amende envoyée au citoyen')) { this.fineRec = null; } return; }
      case 'callsFilter': this.callsAll = v === '1'; return this.render();
      case 'callNew': this.callForm = !this.callForm; return this.render();
      case 'callSend': { const r = await rpc('dispatch:create', val('tc-t').trim(), val('tc-m').trim()); if (!ok(r, 'Appel diffusé')) return; this.callForm = false; await this.poll(); return this.render(); }
      case 'callTake': { const r = await rpc('dispatch:take', Number(v)); if (!ok(r)) return; if (r.joined) rpc('waypoint', { x: r.x, y: r.y }); await this.poll(); return this.render(); }
      case 'callClose': if (!ok(await rpc('dispatch:close', Number(v)))) return; await this.poll(); return this.render();
      case 'callDel': if (!ok(await rpc('dispatch:delete', Number(v)))) return; await this.poll(); return this.render();
      case 'callGps': rpc('waypoint', { x: Number(el.dataset.x), y: Number(el.dataset.y) }); return toast('Point GPS défini', 'ok');
      case 'callMap': this.M.cx = Number(el.dataset.x); this.M.cy = Number(el.dataset.y); this.M.scale = Math.max(this.M.scale, 0.8); this.M.follow = false; this.tab = 'map'; return this.render();
      case 'layer': this.M.layers[v] = el.checked; return;
      case 'mapMe': { const me = this.live && this.live.units.find(u => u.me); if (me) { this.M.cx = me.x; this.M.cy = me.y; } this.M.follow = false; return; }
      case 'mapChase': { const p = this.live && this.live.pursuit; if (p) { this.M.cx = p.x; this.M.cy = p.y; this.M.follow = true; } else toast('Aucune poursuite en cours', 'err'); return; }
      case 'mapUnit': this.M.cx = Number(el.dataset.x); this.M.cy = Number(el.dataset.y); this.M.follow = false; return;
      case 'chaseScan': { const r = await rpc('pursuit:nearby'); if (!ok(r)) return; this.nearby = r.list; document.getElementById('t-chase').innerHTML = this.chaseHtml(); return; }
      case 'chaseStart': { const r = await rpc('pursuit:start', Number(v)); if (!ok(r, 'Poursuite lancée : le suspect est suivi en direct')) return; this.nearby = null; this.M.follow = true; await this.poll(); return this.render(); }
      case 'chaseStop': if (!ok(await rpc('pursuit:stop'), 'Poursuite terminée')) return; await this.poll(); return this.render();
    }
  },

  onInput(el) {
    const path = el.dataset.path; if (!path || !path.startsWith('Tablet.')) return;
    let val = el.type === 'checkbox' ? el.checked : el.value;
    setPath(Tablet, path.slice(7), val);
    if (path.startsWith('Tablet.M.label')) { try { localStorage.setItem('jb_tmap_label', JSON.stringify(this.M.label)); } catch (e) {} }
  },
};

/* ════════════════════════════ ATELIER TUNING ════════════════════════════ */
const GTA_COLORS = [
  [0, 'Noir métal', '#0d1116'], [1, 'Graphite', '#1c1d21'], [2, 'Noir acier', '#32383d'], [3, 'Argent sombre', '#454b4f'], [4, 'Argent', '#999da0'], [5, 'Gris bleuté', '#c2c4c6'],
  [6, 'Gris acier', '#979a97'], [7, 'Gris ombre', '#637380'], [10, 'Gun metal', '#2d3239'], [11, 'Anthracite', '#2b2f33'], [12, 'Noir mat', '#14161a'], [13, 'Gris mat', '#4a4d51'], [14, 'Gris clair mat', '#8e9094'],
  [27, 'Rouge', '#c00e1a'], [28, 'Rouge Torino', '#da1918'], [29, 'Rouge Formula', '#b6111b'], [30, 'Rouge Blaze', '#a51e23'], [31, 'Rouge élégant', '#7b1a22'], [32, 'Grenat', '#8e1b1f'], [33, 'Rouge désert', '#6f1818'],
  [34, 'Cabernet', '#49111d'], [35, 'Rouge candy', '#b60f25'], [36, 'Orange lever', '#d44a17'], [37, 'Or classique', '#c2944f'], [38, 'Orange', '#f78616'], [39, 'Rouge mat', '#cf1f21'], [40, 'Rouge foncé mat', '#732021'], [41, 'Orange mat', '#f27d20'], [42, 'Jaune mat', '#ffc91f'],
  [49, 'Vert foncé', '#132428'], [50, 'Vert racing', '#122e2b'], [51, 'Vert mer', '#12383c'], [52, 'Vert olive', '#31423f'], [53, 'Vert', '#155c2d'], [54, 'Bleu-vert essence', '#1b6770'], [55, 'Citron mat', '#66b81f'],
  [61, 'Bleu minuit', '#1f2852'], [62, 'Bleu foncé', '#282c4d'], [63, 'Bleu Saxony', '#2354a1'], [64, 'Bleu', '#3b4e78'], [65, 'Bleu mariner', '#3b4c6b'], [66, 'Bleu harbor', '#2b3f5b'], [67, 'Bleu diamant', '#4f80b3'],
  [68, 'Bleu surf', '#4ca4c4'], [69, 'Bleu nautique', '#436a85'], [70, 'Bleu vif', '#0b9cf1'], [71, 'Bleu violet', '#2f2d52'], [73, 'Bleu ultra', '#2354a1'], [74, 'Bleu clair', '#6ea3c6'],
  [88, 'Jaune taxi', '#ffcf20'], [89, 'Jaune course', '#fbe212'], [90, 'Bronze', '#916532'], [91, 'Jaune oiseau', '#e0e13d'], [92, 'Lime', '#98d223'], [93, 'Champagne', '#9b8c78'], [94, 'Beige Pueblo', '#503218'],
  [96, 'Brun chocolat', '#291b13'], [97, 'Brun doré', '#4e3a26'], [98, 'Brun clair', '#6f5e4b'], [100, 'Brun mousse', '#3e3b2b'], [104, 'Orange chocolat', '#b84f04'], [105, 'Sable de plage', '#c2b79a'], [107, 'Crème', '#cfc8aa'],
  [111, 'Blanc', '#d6d6d6'], [112, 'Blanc givré', '#f0f0f0'], [120, 'Chrome', '#c9ccd1'], [135, 'Rose vif', '#f21f99'], [136, 'Saumon', '#fdd6cd'], [137, 'Rose vermillon', '#df5891'], [138, 'Orange vif', '#f6ae20'],
  [139, 'Vert vif', '#b0ee6e'], [140, 'Bleu électrique', '#08e9fa'], [141, 'Noir bleuté', '#0a0c17'], [142, 'Noir violet', '#0c0d18'], [143, 'Noir rouge', '#0e0d14'], [145, 'Violet', '#621276'], [150, 'Rouge lave', '#e0321b'],
];
const WHEEL_TYPES = [[0, 'Sport'], [1, 'Muscle'], [2, 'Lowrider'], [3, 'SUV'], [4, 'Tout-terrain'], [5, 'Tuner'], [7, 'High End'], [8, 'Benny\'s Original'], [9, 'Benny\'s Bespoke'], [10, 'Open Wheel'], [11, 'Street'], [12, 'Track']];
const TINTS = ['Aucune', 'Noir pur', 'Fumé foncé', 'Fumé léger', 'Stock', 'Limousine', 'Vert'];
const PLATE_STYLES = ['Bleu sur blanc', 'Jaune sur noir', 'Jaune sur bleu', 'Bleu sur blanc 2', 'Bleu sur blanc 3', 'Yankton'];
const XENON = [[255, 'Par défaut'], [0, 'Blanc'], [1, 'Bleu'], [2, 'Bleu électrique'], [3, 'Vert menthe'], [4, 'Vert citron'], [5, 'Jaune'], [6, 'Doré'], [7, 'Orange'], [8, 'Rouge'], [9, 'Rose'], [10, 'Rose vif'], [11, 'Violet'], [12, 'Lumière noire']];
const MOD_NAMES = { modSpoilers: 'Aileron', modFrontBumper: 'Pare-chocs avant', modRearBumper: 'Pare-chocs arrière', modSideSkirt: 'Bas de caisse', modExhaust: 'Échappement', modFrame: 'Arceau / cadre', modGrille: 'Calandre', modHood: 'Capot', modFender: 'Aile gauche', modRightFender: 'Aile droite', modRoof: 'Toit', modHorns: 'Klaxon', modPlateHolder: 'Support de plaque', modVanityPlate: 'Plaque décorative', modTrimA: 'Garnitures A', modOrnaments: 'Ornements', modDashboard: 'Tableau de bord', modDial: 'Cadrans', modDoorSpeaker: 'Haut-parleurs', modSeats: 'Sièges', modSteeringWheel: 'Volant', modShifterLeavers: 'Levier de vitesse', modAPlate: 'Plaque A', modSpeakers: 'Enceintes', modTrunk: 'Coffre', modHydrolic: 'Hydraulique', modEngineBlock: 'Bloc moteur', modAirFilter: 'Filtre à air', modStruts: 'Barres de renfort', modArchCover: 'Cache-arches', modAerials: 'Antennes', modTrimB: 'Garnitures B', modTank: 'Réservoir', modWindows: 'Vitres', modFrontWheels: 'Jantes avant', modBackWheels: 'Jantes arrière', modLivery: 'Livrée' };
const PERF_MODS = [['modEngine', 'Moteur', 'engine'], ['modBrakes', 'Freins', 'brakes'], ['modTransmission', 'Transmission', 'transmission'], ['modSuspension', 'Suspension', 'suspension'], ['modArmor', 'Blindage', 'armor']];
const BODY_MODS = ['modSpoilers', 'modFrontBumper', 'modRearBumper', 'modSideSkirt', 'modExhaust', 'modFrame', 'modGrille', 'modHood', 'modFender', 'modRightFender', 'modRoof', 'modHorns', 'modPlateHolder', 'modVanityPlate', 'modTrimA', 'modOrnaments', 'modDashboard', 'modDial', 'modDoorSpeaker', 'modSeats', 'modSteeringWheel', 'modShifterLeavers', 'modAPlate', 'modSpeakers', 'modTrunk', 'modHydrolic', 'modEngineBlock', 'modAirFilter', 'modStruts', 'modArchCover', 'modAerials', 'modTrimB', 'modTank', 'modWindows'];
const TUN_GROUP = { modFrontWheels: 'wheels', modBackWheels: 'wheels', wheels: 'wheels', neonEnabled: 'neon', neonColor: 'neon', modXenon: 'xenon', xenonColor: 'xenon', modSmokeEnabled: 'smoke', tyreSmokeColor: 'smoke', modLivery: 'livery', livery: 'livery', color1: 'paint', color2: 'paint', pearlescentColor: 'pearl', wheelColor: 'wheelColor', windowTint: 'tint', plateIndex: 'plate', modTurbo: 'turbo', modHorns: 'horn' };
const TUN_LEVELS = { modEngine: 'engine', modBrakes: 'brakes', modTransmission: 'transmission', modSuspension: 'suspension', modArmor: 'armor' };
const TUN_NAMES = { modEngine: 'Moteur', modBrakes: 'Freins', modTransmission: 'Transmission', modSuspension: 'Suspension', modArmor: 'Blindage', modTurbo: 'Turbo', modXenon: 'Phares xénon', xenonColor: 'Couleur des phares', color1: 'Peinture principale', color2: 'Peinture secondaire', pearlescentColor: 'Nacrage', wheelColor: 'Couleur des jantes', wheels: 'Type de jantes', neonEnabled: 'Néons', neonColor: 'Couleur des néons', windowTint: 'Vitres teintées', plateIndex: 'Style de plaque', modSmokeEnabled: 'Fumée de pneus', tyreSmokeColor: 'Couleur de la fumée', livery: 'Livrée', modLivery: 'Livrée' };
const TUN_CATS = { engine: 'Moteur', brakes: 'Freins', transmission: 'Transmission', suspension: 'Suspension', armor: 'Blindage', turbo: 'Turbo', xenon: 'Xénon', cosmetic: 'Carrosserie', wheels: 'Roues', paint: 'Peinture', pearl: 'Nacré', wheelColor: 'Couleur de jantes', neon: 'Néons', tint: 'Vitres teintées', plate: 'Plaque', smoke: 'Fumée de pneus', livery: 'Livrée', horn: 'Klaxon' };
const colName = id => (GTA_COLORS.find(c => c[0] === id) || [id, 'Couleur ' + id])[1];

const Tuning = {
  d: null, cur: null, tab: 'perf', waiting: false, drag: null, last: 0,

  open(d, pid) { this.d = d; this.pid = pid; this.cur = clone(d.state); this.tab = 'perf'; this.waiting = false; this.render(); },

  changes() {
    const out = [];
    for (const k of Object.keys(this.cur)) if (JSON.stringify(this.cur[k]) !== JSON.stringify(this.d.state[k])) out.push({ key: k, value: this.cur[k] });
    return out;
  },

  // Même calcul que le serveur (le serveur fait foi)
  quote() {
    const P = this.d.prices, mk = this.d.markup || 100, seen = {}, lines = [];
    let total = 0;
    for (const c of this.changes()) {
      let cat = TUN_LEVELS[c.key], amount = 0;
      if (cat) { const l = P[cat] || []; if (c.value >= 0 && l.length) amount = l[Math.min(c.value + 1, l.length) - 1]; }
      else {
        cat = TUN_GROUP[c.key] || 'cosmetic';
        if (cat === 'cosmetic') amount = c.value !== -1 ? (P.cosmetic || 0) : 0;
        else if (!seen[cat]) { seen[cat] = true; amount = P[cat] || 0; }
        if ((c.key === 'modTurbo' || c.key === 'modXenon' || c.key === 'modSmokeEnabled') && c.value === false) amount = 0;
      }
      if (amount > 0) { const a = Math.floor(amount * mk / 100); total += amount; lines.push({ cat, key: c.key, amount: a }); }
    }
    return { total: Math.floor(total * mk / 100), lines };
  },

  priceTag(key) { const P = this.d.prices, mk = (this.d.markup || 100) / 100; const g = TUN_GROUP[key]; const v = g ? P[g] : TUN_LEVELS[key] ? null : P.cosmetic; return v ? `<span class="price">${money(Math.floor(v * mk))}</span>` : ''; },

  async set(key, value, extra) {
    this.cur[key] = value;
    (extra || []).forEach(([k, v]) => { this.cur[k] = v; });
    this.render();
    await rpc('tuning:preview', key, value);
    for (const [k, v] of (extra || [])) await rpc('tuning:preview', k, v);
  },

  // « Sélecteur » avec flèches : liste de valeurs [valeur, libellé]
  stepper(key, label, list, opts = {}) {
    const i = Math.max(0, list.findIndex(x => x[0] === this.cur[key]));
    return `<div class="tun-row"><div class="tun-lbl"><b>${esc(label)}</b>${opts.price === false ? '' : this.priceTag(key)}</div>
      <div class="stepper"><button class="icon" data-a="step" data-k="${key}" data-d="-1">${ic('left', 16)}</button><div class="sv">${esc(list[i] ? list[i][1] : '—')}<small>${i + 1}/${list.length}</small></div><button class="icon" data-a="step" data-k="${key}" data-d="1">${ic('chevron', 16)}</button></div></div>`;
  },

  modList(key) {
    const m = this.d.mods[key]; if (!m) return null;
    const lvl = ['modEngine', 'modBrakes', 'modTransmission', 'modSuspension', 'modArmor'].includes(key);
    const list = [[-1, lvl ? 'Origine' : 'Origine']];
    for (let i = 0; i < m.n; i++) list.push([i, lvl ? `Niveau ${i + 1}` : (m.labels[i] || `Option ${i + 1}`)]);
    return list;
  },

  toggle(key, label) {
    return `<div class="tun-row"><div class="tun-lbl"><b>${esc(label)}</b>${this.priceTag(key)}</div><label class="sw-tg"><input type="checkbox" data-a="tog" data-k="${key}" ${this.cur[key] ? 'checked' : ''}><span></span></label></div>`;
  },

  palette(key, label) {
    return `<div class="tun-row col"><div class="tun-lbl"><b>${esc(label)}</b><small style="color:var(--muted)">${esc(colName(this.cur[key]))}</small>${this.priceTag(key)}</div>
      <div class="tun-grid">${GTA_COLORS.map(c => `<button class="sw ${this.cur[key] === c[0] ? 'on' : ''}" title="${esc(c[1])}" style="background:${c[2]}" data-a="setv" data-k="${key}" data-v="${c[0]}"></button>`).join('')}</div></div>`;
  },

  colorInput(key, label, enabledKey) {
    const c = this.cur[key] || [255, 255, 255], hex = rgbHex(c);
    return `<div class="tun-row"><div class="tun-lbl"><b>${esc(label)}</b></div><input type="color" data-path="tuning.color" data-tcolor="${key}" value="${hex}" style="width:64px;height:34px;padding:0;border-radius:8px"></div>`;
  },

  tabBody() {
    const d = this.d, c = this.cur, t = this.tab;
    if (t === 'perf') return `${PERF_MODS.filter(([k]) => d.mods[k]).map(([k, l]) => this.stepper(k, l, this.modList(k), { price: false }).replace('<div class="tun-lbl"><b>', `<div class="tun-lbl"><b>`)).join('')}
      ${this.toggle('modTurbo', 'Turbo')}<p class="hint">Les niveaux de performance sont facturés selon le niveau choisi.</p>`;
    if (t === 'body') {
      const rows = BODY_MODS.filter(k => d.mods[k]).map(k => this.stepper(k, MOD_NAMES[k], this.modList(k)));
      if (d.mods.modLivery) rows.push(this.stepper('modLivery', 'Livrée', this.modList('modLivery')));
      else if (d.mods.livery && d.mods.livery.n > 0) rows.push(this.stepper('livery', 'Livrée', Array.from({ length: d.mods.livery.n }, (_, i) => [i, `Livrée ${i + 1}`])));
      return rows.join('') || '<p class="hint">Aucune pièce de carrosserie disponible pour ce véhicule.</p>';
    }
    if (t === 'wheels') return `${this.stepper('wheels', 'Type de jantes', d.vehicle.bike ? [[6, 'Moto']] : WHEEL_TYPES)}
      ${this.stepper('modFrontWheels', d.vehicle.bike ? 'Jantes avant' : 'Jantes', this.modList('modFrontWheels') || [[-1, 'Origine']])}
      ${d.vehicle.bike ? this.stepper('modBackWheels', 'Jantes arrière', this.modList('modBackWheels') || [[-1, 'Origine']]) : ''}
      ${this.palette('wheelColor', 'Couleur des jantes')}${this.toggle('modSmokeEnabled', 'Fumée de pneus')}${c.modSmokeEnabled ? this.colorInput('tyreSmokeColor', 'Couleur de la fumée') : ''}`;
    if (t === 'paint') return `${this.palette('color1', 'Couleur principale')}${this.palette('color2', 'Couleur secondaire')}${this.palette('pearlescentColor', 'Nacrage')}`;
    if (t === 'lights') return `<div class="tun-row col"><div class="tun-lbl"><b>Néons</b>${this.priceTag('neonEnabled')}</div><div class="neon-grid">${['Gauche', 'Droite', 'Avant', 'Arrière'].map((n, i) => `<label class="chk"><input type="checkbox" data-a="neon" data-i="${i}" ${(c.neonEnabled || [])[i] ? 'checked' : ''}> ${n}</label>`).join('')}</div></div>
      ${this.colorInput('neonColor', 'Couleur des néons')}${this.toggle('modXenon', 'Phares xénon')}${c.modXenon ? this.stepper('xenonColor', 'Couleur des phares', XENON, { price: false }) : ''}
      ${this.stepper('windowTint', 'Vitres teintées', TINTS.map((n, i) => [i, n]))}${this.stepper('plateIndex', 'Style de plaque', PLATE_STYLES.map((n, i) => [i, n]))}`;
    const q = this.quote();
    return `<div class="card" style="padding:14px">${q.lines.length ? q.lines.map(l => `<div class="logline" style="display:flex;justify-content:space-between"><span>${esc(TUN_NAMES[l.key] || MOD_NAMES[l.key] || TUN_CATS[l.cat] || l.key)}</span><b>${money(l.amount)}</b></div>`).join('') : '<p class="hint">Aucune modification.</p>'}
      <div class="row mt" style="justify-content:space-between"><b>Total</b><span class="big" style="font-size:24px;margin:0">${money(q.total)}</span></div></div>
      <p class="hint mt">${({ customer: 'Le client le plus proche reçoit la facture : les modifications sont enregistrées une fois payée (sinon elles sont annulées).', society: 'Le montant est prélevé sur le compte société.', free: 'Atelier gratuit : aucune facturation.' })[this.d.billing]}</p>
      <button class="mt" data-a="revert" style="width:100%">Annuler toutes les modifications</button>`;
  },

  render() {
    const d = this.d, q = this.quote(), n = this.changes().length;
    const tabs = [['perf', 'wrench', 'Perf.'], ['body', 'car', 'Carrosserie'], ['wheels', 'bike', 'Roues'], ['paint', 'droplet', 'Peinture'], ['lights', 'sliders', 'Éclairage'], ['sum', 'file', 'Devis']];
    $root.classList.remove('corner'); $root.classList.add('tuning');
    $root.innerHTML = `<div class="tun-view" id="tun-view"></div><div class="tun-panel">
      <div class="tun-head">${tile('wrench', 'lg')}<div class="ttl"><h1>${esc(d.vehicle.name || 'Véhicule')}</h1><p>${esc(d.vehicle.plate)} · ${esc(d.jobLabel)}</p></div><button class="icon" data-a="close" title="Fermer">${ic('x', 16)}</button></div>
      <div class="tun-tabs">${tabs.map(([k, i, l]) => `<button class="${this.tab === k ? 'active' : ''}" data-a="tab" data-v="${k}">${ic(i, 15)}<span>${l}</span></button>`).join('')}</div>
      <div class="tun-body">${this.waiting ? `<div class="empty">${tile('clock')}<h2>En attente du client…</h2><p>Le client doit accepter et payer la facture à l'écran (60 s).</p></div>` : this.tabBody()}</div>
      <div class="tun-foot"><div><small>Total</small><b>${money(q.total)}</b><small>${n} modification(s)</small></div><button class="primary" data-a="validate" ${n === 0 || this.waiting ? 'disabled' : ''}>${ic('check', 15)} Valider</button></div></div>`;
    const v = document.getElementById('tun-view');
    v.onmousedown = e => { this.drag = { x: e.clientX, y: e.clientY }; };
    v.onmousemove = e => { if (!this.drag) return; const now = Date.now(); if (now - this.last < 35) return; this.last = now; rpc('tuning:cam', e.clientX - this.drag.x, e.clientY - this.drag.y, 0); this.drag = { x: e.clientX, y: e.clientY }; };
    v.onwheel = e => { rpc('tuning:cam', 0, 0, e.deltaY > 0 ? 8 : -8); };
    window.onmouseup = () => { this.drag = null; };
  },

  async onA(el) {
    const a = el.dataset.a, k = el.dataset.k, d = this.d;
    switch (a) {
      case 'tab': this.tab = el.dataset.v; return this.render();
      case 'step': {
        let list;
        if (k === 'wheels') list = d.vehicle.bike ? [[6, 'Moto']] : WHEEL_TYPES;
        else if (k === 'windowTint') list = TINTS.map((n, i) => [i, n]); else if (k === 'plateIndex') list = PLATE_STYLES.map((n, i) => [i, n]); else if (k === 'xenonColor') list = XENON;
        else if (k === 'livery') list = Array.from({ length: d.mods.livery.n }, (_, i) => [i, `Livrée ${i + 1}`]);
        else list = this.modList(k);
        const i = Math.max(0, list.findIndex(x => x[0] === this.cur[k])), nx = list[(i + Number(el.dataset.d) + list.length) % list.length][0];
        if (k === 'wheels') {           // changer de type de jantes recharge la liste des jantes
          this.cur.wheels = nx; await rpc('tuning:preview', 'wheels', nx); this.cur.modFrontWheels = -1; await rpc('tuning:preview', 'modFrontWheels', -1);
          if (d.vehicle.bike) { this.cur.modBackWheels = -1; await rpc('tuning:preview', 'modBackWheels', -1); }
          d.mods.modFrontWheels = await rpc('tuning:mods', 'modFrontWheels'); if (d.vehicle.bike) d.mods.modBackWheels = await rpc('tuning:mods', 'modBackWheels');
          return this.render();
        }
        return this.set(k, nx);
      }
      case 'setv': return this.set(k, Number(el.dataset.v));
      case 'tog': return this.set(k, el.checked);
      case 'neon': { const n = [...(this.cur.neonEnabled || [false, false, false, false])]; n[Number(el.dataset.i)] = el.checked; return this.set('neonEnabled', n); }
      case 'revert': { const r = await rpc('tuning:revert'); if (r && r.ok) { this.cur = clone(r.state); this.d.mods = r.mods; this.render(); toast('Modifications annulées', 'ok'); } return; }
      case 'validate': {
        const ch = this.changes(); if (!ch.length) return;
        const r = await rpc('tuning:validate', this.pid, 0, this.d.vehicle.plate, ch);
        if (!r || !r.ok) return toast((r && r.error) || 'Erreur', 'err');
        if (r.waiting) { this.waiting = true; await rpc('tuning:waiting', true); toast(`Facture de ${money(r.total)} envoyée au client`, 'ok'); return this.render(); }
        toast(r.saved ? 'Customisation enregistrée' : 'Appliquée (véhicule non enregistré en base)', 'ok');
        return rpc('tuning:finish');
      }
    }
  },

  onInput(el) {
    if (!el.dataset.tcolor) return;
    const key = el.dataset.tcolor, rgb = hexRgb(el.value);
    this.cur[key] = rgb;
    clearTimeout(this.tc);
    this.tc = setTimeout(() => {             // pas de re-rendu pendant le choix de couleur (le sélecteur se fermerait)
      rpc('tuning:preview', key, rgb);
      const q = this.quote(), n = this.changes().length, f = document.querySelector('.tun-foot');
      if (f) { f.querySelector('b').textContent = money(q.total); f.querySelector('small:last-child').textContent = n + ' modification(s)'; f.querySelector('button').disabled = n === 0; }
    }, 90);
  },

  result(m) {
    this.waiting = false;
    if (m.ok) { toast(m.msg || 'Terminé', 'ok'); return rpc('tuning:finish'); }
    toast(m.msg || 'Annulé', 'err');
    if (m.state) this.cur = clone(m.state);
    this.render();
  },
};

/* ════════════════════════════ TABLETTE MÉDICALE (EMS) ════════════════════════════ */
const MED_KINDS = { consult: ['Consultation', 'info'], care: ['Soin facturé', 'ok'], surgery: ['Opération', 'bad'], prescription: ['Ordonnance', 'warn'], observation: ['Observation', 'mute'], death: ['Décès', 'bad'] };

const Ems = {
  d: null, tab: 'calls', live: null, pats: [], q: '', sel: null, pat: null, form: null, careIdx: 1, carePat: null, callForm: false, stats: null,

  async open(d) {
    this.d = d; this.tab = 'calls'; this.live = null; this.sel = null; this.pat = null; this.form = null; this.q = ''; this.callForm = false; this.carePat = null; this.stats = null;
    await this.poll(true);
    this.render();
  },

  nav() { return [{ id: 'calls', icon: 'cross', text: 'Urgences' }, { id: 'patients', icon: 'folder', text: 'Patients' }, { id: 'care', icon: 'dollar', text: 'Soins' }, { id: 'team', icon: 'users', text: 'Équipe' }, { id: 'stats', icon: 'percent', text: 'Statistiques' }]; },

  render() {
    const d = this.d;
    $root.classList.remove('corner');
    $root.innerHTML = shellSide({ profile: { initials: initials(d.jobLabel), title: 'Tablette médicale', sub: `${d.jobLabel} · ${d.gradeLabel || ''}` }, nav: [{ label: 'Service', items: this.nav() }], active: this.tab,
      foot: `<small>${d.perms.admin ? 'Accès direction : suppressions autorisées.' : 'Dossiers réservés à ton service.'}</small>`,
      head: { icon: 'cross', title: `Tablette médicale — ${d.jobLabel}`, sub: ({ calls: 'Urgences en direct', patients: 'Dossiers patients', care: 'Facturation des soins', team: 'Équipe en service', stats: 'Statistiques (30 jours)' })[this.tab] }, body: this['tab_' + this.tab]() });
  },

  /* ── Urgences ── */
  tab_calls() {
    const n = this.live ? this.live.calls.length : 0;
    return `<div class="row" style="margin-bottom:14px"><div class="stat" style="flex:1"><div class="eyebrow">Urgences en cours</div><div class="v">${n}</div><div class="s">${n ? 'Prends un appel : le GPS se met en place' : 'Aucune urgence pour le moment'}</div></div>
        <div class="stat" style="flex:1"><div class="eyebrow">Collègues en service</div><div class="v">${this.live ? this.live.team.length : 0}</div><div class="s">${this.live ? this.live.team.filter(t => !t.busy).length : 0} disponible(s)</div></div>
        <button class="primary" data-a="callNew" style="align-self:stretch;padding:0 22px">${ic('plus', 15)} Urgence sur place</button></div>
      ${this.callForm ? `<div class="card"><div class="card-h"><div class="t">Nouvelle urgence à ta position</div></div><div class="row">${fld('Description', '<input id="ec-t" maxlength="60" placeholder="ex: Accident de la route, 2 blessés" style="min-width:380px">')}<button class="primary" data-a="callSend" style="align-self:end">Alerter l'équipe</button><button data-a="callNew" style="align-self:end">Annuler</button></div></div>` : ''}
      <div id="e-calls">${this.callsHtml()}</div>
      <p class="hint mt">Quand un joueur inconscient appelle les EMS, l'urgence apparaît ici et sur la carte du jeu de toute l'équipe. <b>Y</b> prend le dernier appel reçu.</p>`;
  },

  callsHtml() {
    const list = (this.live && this.live.calls) || [];
    return list.map(c => `<div class="card" style="padding:14px;margin-bottom:10px"><div class="row"><div class="grow" style="flex:1;min-width:0"><div class="row" style="gap:8px">${chip(c.manual ? 'Sur place' : 'Patient inconscient', c.manual ? 'warn' : 'bad')}<b>${esc(c.name)}</b></div>
        <small style="color:var(--muted)">${c.dist} m · ${ago(c.t)}${c.units.length ? ' · En route : ' + c.units.map(u => esc(u.name)).join(', ') : ' · Personne en route'}</small></div>
        <div class="row wrap" style="gap:6px;justify-content:flex-end"><button class="sm ${c.mine ? '' : 'primary'}" data-a="emsTake" data-id="${c.id}">${c.mine ? 'Quitter' : 'Prendre'}</button><button class="sm" data-a="emsGps" data-x="${c.x}" data-y="${c.y}">GPS</button><button class="sm" data-a="emsClose" data-id="${c.id}">Clôturer</button></div></div></div>`).join('') || emptyState('cross', 'Aucune urgence', 'Tout est calme. Les nouvelles urgences apparaîtront automatiquement.');
  },

  /* ── Patients ── */
  tab_patients() {
    return `<div class="pts"><div>
      <div class="row" style="margin-bottom:10px"><input id="e-q" placeholder="Rechercher un patient…" value="${esc(this.q)}" style="flex:1"><button class="icon" data-a="patSearch">${ic('search', 16)}</button></div>
      <button class="sm" data-a="patNew" style="width:100%;margin-bottom:10px">${ic('plus', 14)} Nouveau dossier</button>
      ${this.pats.map(p => `<div class="pt ${this.sel === p.id ? 'active' : ''}" data-a="patOpen" data-v="${p.id}">${tile('user')}<div style="flex:1;min-width:0"><b>${esc(p.name)}</b><small>${p.blood ? 'Groupe ' + esc(p.blood) + ' · ' : ''}${p.n} entrée(s)</small></div></div>`).join('') || '<p class="hint">Aucun dossier.</p>'}</div>
      <div>${this.form ? this.patForm() : this.pat ? this.patDetail() : emptyState('folder', 'Aucun dossier ouvert', 'Recherche un patient ou crée un dossier.')}</div></div>`;
  },

  patDetail() {
    const P = this.pat.patient, E = this.pat.entries, adm = this.d.perms.admin;
    return `<div class="card"><div class="card-h"><div class="t">${ic('user', 16)} ${esc(P.firstname + ' ' + P.lastname)}</div><div class="row" style="gap:8px">${P.blood ? chip('Groupe ' + P.blood, 'info') : chip('Groupe inconnu', 'mute')}</div></div>
      <div class="grid3"><div class="stat"><div class="eyebrow">Naissance</div><div class="s" style="font-size:14px;color:var(--text)">${esc(P.birthdate || '—')}</div></div><div class="stat"><div class="eyebrow">Entrées</div><div class="v">${E.length}</div></div><div class="stat"><div class="eyebrow">Soins payés</div><div class="v">${money(this.pat.paid)}</div></div></div>
      ${P.allergies ? `<p class="hint mt" style="color:var(--danger)">⚠ Allergies : ${esc(P.allergies)}</p>` : ''}
      <p class="hint mt" style="white-space:pre-wrap">${esc(P.notes || 'Aucune note.')}</p>
      <div class="row wrap mt"><button data-a="patEdit">${ic('edit', 15)} Modifier</button>${this.d.perms.care ? `<button data-a="patCare">${ic('dollar', 15)} Facturer un soin</button>` : ''}${adm ? `<button class="danger" data-a="patDel">${ic('trash', 15)} Supprimer</button>` : ''}</div></div>
      <div class="card"><div class="card-h"><div class="t">Ajouter une entrée</div></div>
        <div class="form-row" style="grid-template-columns:170px 1.4fr 110px"><label class="f"><span>Type</span><select id="ee-k">${['consult', 'surgery', 'prescription', 'observation', 'care', 'death'].map(k => `<option value="${k}">${MED_KINDS[k][0]}</option>`).join('')}</select></label>
          ${fld('Motif', '<input id="ee-l" maxlength="120" placeholder="ex: Fracture du bras">')}${fld('Montant ($)', '<input id="ee-a" type="number" min="0" value="0">')}</div>
        ${fld('Détails (optionnel)', '<textarea id="ee-d" maxlength="1000" style="min-height:60px"></textarea>')}<div class="row mt"><button class="primary" data-a="entryAdd">${ic('plus', 15)} Enregistrer</button></div></div>
      <div class="card"><div class="card-h"><div class="t">Historique médical</div></div>${E.length ? E.map(e => `<div class="item"><div class="grow"><b>${esc(e.label)}</b><small>${esc(e.officer || '')} · ${fmtDate(e.t)}${e.details ? ' · ' + esc(e.details) : ''}</small></div>${e.amount ? `<span class="price">${money(e.amount)}</span>` : ''}${chip(...(MED_KINDS[e.kind] || [e.kind, 'mute']))}${adm ? `<button class="icon danger" data-a="entryDel" data-v="${e.id}">${ic('trash', 14)}</button>` : ''}</div>`).join('') : '<p class="hint">Aucune entrée.</p>'}</div>`;
  },

  patForm() {
    const f = this.form, b = 'Ems.form';
    return `<div class="card"><div class="card-h"><div class="t">${ic('edit', 16)} ${f.id ? 'Modifier le dossier' : 'Nouveau dossier'}</div></div>
      <div class="grid3">${fld('Prénom', `<input data-path="${b}.firstname" value="${esc(f.firstname)}" maxlength="50">`)}${fld('Nom', `<input data-path="${b}.lastname" value="${esc(f.lastname)}" maxlength="50">`)}${fld('Naissance', `<input data-path="${b}.birthdate" value="${esc(f.birthdate)}" maxlength="20" placeholder="JJ/MM/AAAA">`)}</div>
      <div class="grid2 mt">${fld('Groupe sanguin', `<select data-path="${b}.blood"><option value="">Inconnu</option>${this.d.blood.map(x => `<option ${f.blood === x ? 'selected' : ''}>${x}</option>`).join('')}</select>`)}${fld('Allergies', `<input data-path="${b}.allergies" value="${esc(f.allergies)}" maxlength="300">`)}</div>
      <div class="mt">${fld('Antécédents / notes', `<textarea data-path="${b}.notes" maxlength="2000">${esc(f.notes)}</textarea>`)}</div>
      <div class="row mt"><button class="primary" data-a="patSave">${ic('check', 15)} Enregistrer</button><button data-a="patCancel">Annuler</button>${f.id ? '' : `<span class="spacer"></span><button data-a="patNearest">${ic('user', 15)} Patient en face</button>`}</div></div>`;
  },

  /* ── Soins ── */
  tab_care() {
    const d = this.d, cur = this.careIdx > 0 ? d.care[this.careIdx - 1] : null;
    return `<div class="grid2"><div class="card"><div class="card-h"><div class="t">${ic('dollar', 16)} Tarifs des soins</div></div>
      ${d.care.map((f, i) => `<div class="item click" data-a="careSel" data-v="${i + 1}" style="${this.careIdx === i + 1 ? 'border-color:var(--accent-line);background:var(--accent-soft)' : ''}"><div class="grow"><b>${esc(f.label)}</b></div><span class="price">${money(f.amount)}</span></div>`).join('')}
      ${d.careCustom ? `<div class="item click" data-a="careSel" data-v="0" style="margin-top:6px;${this.careIdx === 0 ? 'border-color:var(--accent-line);background:var(--accent-soft)' : ''}"><div class="grow"><b>Soin libre</b><small>Motif et montant au choix (${money(d.limits.min)} à ${money(d.limits.max)})</small></div></div>` : ''}</div>
      <div class="card"><div class="card-h"><div class="t">Facturer le patient</div></div>
        ${this.careIdx === 0 && d.careCustom ? `<div class="grid2">${fld('Motif', '<input id="ef-l" maxlength="60" placeholder="ex: Suture">')}${fld('Montant ($)', `<input id="ef-a" type="number" min="${d.limits.min}" max="${d.limits.max}" value="${d.limits.min}">`)}</div>`
          : `<div class="stat"><div class="eyebrow">Soin choisi</div><div class="v" style="font-size:18px">${cur ? esc(cur.label) : '—'}</div><div class="s">${cur ? money(cur.amount) : 'Choisis un tarif'}</div></div>`}
        <div class="mt">${fld('Remarque (dossier)', '<input id="ef-n" maxlength="200" placeholder="optionnel">')}</div>
        ${this.carePat ? `<p class="hint mt">Dossier lié : <b style="color:var(--text)">${esc(this.carePat.name)}</b> <a data-a="careUnlink" style="cursor:pointer;color:var(--accent)">(retirer)</a></p>` : '<p class="hint mt">Le dossier du patient sera créé ou mis à jour automatiquement.</p>'}
        <p class="hint mt">Le <b>patient le plus proche</b> reçoit la facture à l'écran et la règle directement (argent → société). Le soin est ajouté à son dossier une fois payé.</p>
        <button class="primary mt" data-a="careSend" ${this.careIdx === 0 && !d.careCustom ? 'disabled' : ''}>${ic('dollar', 15)} Envoyer la facture</button></div></div>`;
  },

  /* ── Équipe ── */
  tab_team() { return `<div id="e-team">${this.teamHtml()}</div>`; },
  teamHtml() {
    const T = (this.live && this.live.team) || [];
    return `<div class="grid3" style="margin-bottom:14px"><div class="stat"><div class="eyebrow">En service</div><div class="v">${T.length}</div></div><div class="stat"><div class="eyebrow">Disponibles</div><div class="v" style="color:var(--ok)">${T.filter(t => !t.busy).length}</div></div><div class="stat"><div class="eyebrow">En intervention</div><div class="v" style="color:var(--warn)">${T.filter(t => t.busy).length}</div></div></div>`
      + T.map(t => `<div class="item">${tile('user')}<div class="grow"><b>${esc(t.name)}${t.me ? ' (toi)' : ''}</b><small>${esc(t.grade || '')}${t.dist != null && !t.me ? ' · à ' + t.dist + ' m' : ''}</small></div>${chip(t.busy ? 'En intervention' : 'Disponible', t.busy ? 'warn' : 'ok')}</div>`).join('');
  },

  /* ── Statistiques ── */
  tab_stats() {
    const s = this.stats;
    if (!s) return '<p class="hint">Chargement…</p>';
    return `<div class="grid4" style="margin-bottom:16px">${[['Patients', s.patients, 'dossiers'], ['Réanimations', s.revives, '30 jours'], ['Urgences prises', s.responses, '30 jours'], ['Soins facturés', money(s.income), `${s.cares} soin(s)`]].map(([l, v, sub]) => `<div class="stat"><div class="eyebrow">${l}</div><div class="v">${v}</div><div class="s">${sub}</div></div>`).join('')}</div>
      <div class="card"><div class="card-h"><div class="t">Agents les plus actifs (30 jours)</div></div>${s.top.length ? s.top.map((t, i) => `<div class="item"><div class="grow"><b>${i + 1}. ${esc(t.name)}</b></div>${chip(t.n + ' intervention(s)', 'info')}</div>`).join('') : '<p class="hint">Pas encore d\'activité.</p>'}</div>`;
  },

  /* ── Données ── */
  async poll(first) {
    const r = await rpc('emstab:live');
    if (!r || !r.ok) return;
    this.live = r;
    if (first) return;
    if (this.tab === 'calls') { const el = document.getElementById('e-calls'); if (el) el.innerHTML = this.callsHtml(); }
    else if (this.tab === 'team') { const el = document.getElementById('e-team'); if (el) el.innerHTML = this.teamHtml(); }
  },
  async loadPats() { const r = await rpc('patients:search', this.q); if (r && r.ok) this.pats = r.list; },
  async openPat(id) { const r = await rpc('patients:get', id); if (!r || !r.ok) return toast((r && r.error) || 'Erreur', 'err'); this.sel = id; this.pat = r; this.form = null; },

  async onA(el) {
    const a = el.dataset.a, v = el.dataset.v, ok = (r, m) => { if (!r || !r.ok) { toast((r && r.error) || 'Erreur', 'err'); return false; } if (m) toast(m, 'ok'); return true; };
    const val = id => (document.getElementById(id) || {}).value || '';
    switch (a) {
      case 'nav': this.tab = v; this.callForm = false; if (v === 'patients') await this.loadPats(); if (v === 'calls' || v === 'team') await this.poll(true); if (v === 'stats') { const r = await rpc('emstab:stats'); this.stats = r && r.ok ? r : null; } return this.render();
      case 'callNew': this.callForm = !this.callForm; return this.render();
      case 'callSend': { if (!ok(await rpc('emstab:createCall', val('ec-t').trim()), 'Urgence diffusée à l\'équipe')) return; this.callForm = false; await this.poll(true); return this.render(); }
      case 'emsTake': { const r = await rpc('ems:take', Number(el.dataset.id)); if (!ok(r)) return; if (r.joined) rpc('waypoint', { x: r.x, y: r.y }); toast(r.joined ? 'Appel pris : GPS défini' : 'Appel quitté', 'ok'); await this.poll(true); return this.render(); }
      case 'emsGps': rpc('waypoint', { x: Number(el.dataset.x), y: Number(el.dataset.y) }); return toast('Point GPS défini', 'ok');
      case 'emsClose': { if (!ok(await rpc('ems:close', Number(el.dataset.id)), 'Urgence clôturée')) return; await this.poll(true); return this.render(); }
      case 'patSearch': this.q = val('e-q').trim(); await this.loadPats(); return this.render();
      case 'patOpen': await this.openPat(Number(v)); return this.render();
      case 'patNew': this.tab = 'patients'; await this.loadPats(); this.form = { id: null, firstname: '', lastname: '', birthdate: '', blood: '', allergies: '', notes: '' }; this.pat = null; this.sel = null; return this.render();
      case 'patEdit': this.form = { ...this.pat.patient }; return this.render();
      case 'patCancel': this.form = null; return this.render();
      case 'patSave': { const r = await rpc('patients:save', this.form); if (!ok(r, 'Dossier enregistré')) return; await this.loadPats(); await this.openPat(r.id); return this.render(); }
      case 'patNearest': { const r = await rpc('patients:fromNearest', 0); if (!ok(r)) return; await this.loadPats(); await this.openPat(r.id); return this.render(); }
      case 'patDel': if (!await confirmBox('Supprimer ce dossier ?', 'Toutes les entrées médicales seront supprimées définitivement.', 'Supprimer')) return; if (!ok(await rpc('patients:delete', this.sel), 'Dossier supprimé')) return; this.pat = null; this.sel = null; await this.loadPats(); return this.render();
      case 'entryAdd': { if (!ok(await rpc('patients:addEntry', this.sel, val('ee-k'), val('ee-l').trim(), Number(val('ee-a')) || 0, val('ee-d').trim()), 'Entrée ajoutée')) return; await this.openPat(this.sel); await this.loadPats(); return this.render(); }
      case 'entryDel': if (!ok(await rpc('patients:delEntry', Number(v)))) return; await this.openPat(this.sel); return this.render();
      case 'patCare': this.carePat = { id: this.sel, name: this.pat.patient.firstname + ' ' + this.pat.patient.lastname }; this.tab = 'care'; return this.render();
      case 'careSel': this.careIdx = Number(v); return this.render();
      case 'careUnlink': this.carePat = null; return this.render();
      case 'careSend': { const r = await rpc('care:send', this.carePat ? this.carePat.id : 0, 0, this.careIdx, val('ef-l').trim(), Number(val('ef-a')) || 0, val('ef-n').trim()); if (ok(r, 'Facture envoyée au patient')) this.carePat = null; return; }
    }
  },

  onInput(el) {
    const path = el.dataset.path; if (!path || !path.startsWith('Ems.')) return;
    setPath(Ems, path.slice(4), el.type === 'checkbox' ? el.checked : el.value);
  },
};

const durLeft = t => { const s = Math.max(0, Math.floor(t - Date.now() / 1000)); return s < 3600 ? Math.max(1, Math.floor(s / 60)) + ' min' : s < 172800 ? Math.floor(s / 3600) + ' h' : Math.floor(s / 86400) + ' j'; };
/* ════════════════════════════ TABLETTE BANCAIRE ════════════════════════════ */
const BANK_KINDS = { note: ['Note', 'mute'], fee: ['Frais', 'info'], loan: ['Prêt', 'ok'], payment: ['Échéance', 'ok'], late: ['Impayé', 'bad'], forgive: ['Prêt annulé', 'warn'], deposit: ['Dépôt', 'info'], withdraw: ['Retrait', 'info'], rating: ['Cote', 'warn'] };
const BANK_STATUS = { active: ['En cours', 'ok'], late: ['En retard', 'warn'], defaulted: ['En défaut', 'bad'], paid: ['Soldé', 'info'], forgiven: ['Annulé', 'mute'] };
const BANK_RATING_KIND = { A: 'ok', B: 'ok', C: 'info', D: 'warn', E: 'bad' };

const Bank = {
  d: null, tab: 'home', dash: null, live: null, clients: [], q: '', flag: '', sel: null, cl: null, form: null,
  loans: [], loanFilter: 'open', offer: { amount: 5000, rate: 10, n: 7, note: '' }, op: { kind: 'deposit', amount: 500 }, feeIdx: 1, noteText: '',

  async open(d) {
    this.d = d; this.tab = 'home'; this.dash = null; this.live = null; this.sel = null; this.cl = null; this.form = null; this.q = ''; this.flag = ''; this.loanFilter = 'open'; this.feeIdx = d.fees.length ? 1 : 0;
    const L = d.limits;
    this.offer = { amount: Math.min(Math.max(5000, L.minLoan), L.maxLoan), rate: Math.min(Math.max(10, L.minRate), L.maxRate), n: L.terms.includes(7) ? 7 : L.terms[0], note: '' };
    this.op = { kind: 'deposit', amount: 500 };
    await this.loadDash();
    this.render();
  },

  nav() {
    const p = this.d.perms, items = [{ id: 'home', icon: 'grid', text: 'Tableau de bord' }, { id: 'clients', icon: 'folder', text: 'Clients' }];
    if (this.d.society) items.push({ id: 'loans', icon: 'percent', text: 'Prêts' });
    if (p.ops) items.push({ id: 'counter', icon: 'dollar', text: 'Guichet' });
    if (p.fee) items.push({ id: 'fees', icon: 'file', text: 'Frais & services' });
    items.push({ id: 'team', icon: 'users', text: 'Équipe' });
    return items;
  },

  render() {
    const d = this.d;
    $root.classList.remove('corner');
    $root.innerHTML = shellSide({ profile: { initials: initials(d.jobLabel), title: 'Tablette bancaire', sub: `${d.jobLabel} · ${d.gradeLabel || ''}` }, nav: [{ label: 'Banque', items: this.nav() }], active: this.tab,
      foot: `<small>${d.perms.admin ? 'Accès direction : annulation de prêts et suppressions autorisées.' : 'Fiches et prêts réservés à ta banque.'}</small>`,
      head: { icon: 'landmark', title: `Tablette bancaire — ${d.jobLabel}`, sub: ({ home: 'Vue d\'ensemble', clients: 'Fiches clients', loans: 'Prêts & remboursements', counter: 'Guichet', fees: 'Frais & services', team: 'Équipe en service' })[this.tab] }, body: this['tab_' + this.tab]() });
  },

  /* ── Tableau de bord ── */
  tab_home() {
    const s = this.dash;
    if (!s) return '<p class="hint">Chargement…</p>';
    const st = (l, v, sub, col) => `<div class="stat"><div class="eyebrow">${l}</div><div class="v"${col ? ` style="color:var(--${col})"` : ''}>${v}</div><div class="s">${sub}</div></div>`;
    return `<div class="grid4" style="margin-bottom:14px">${st('Trésorerie', s.balance != null ? `<span data-live="money">${Number(s.balance).toLocaleString('fr-FR')}<small>$</small></span>` : '—', 'compte de la banque')}${st('Prêts en cours', s.active + s.late + s.defaulted, `${s.late} en retard · ${s.defaulted} en défaut`, s.defaulted ? 'danger' : '')}${st('Encours total', money(s.outstanding), 'reste à rembourser')}${st('Clients', s.clients, 'fiches enregistrées')}</div>
      <div class="grid3" style="margin-bottom:14px">${st('Remboursé (30 j)', money(s.collected), 'échéances prélevées', 'ok')}${st('Prêts accordés (30 j)', money(s.granted), 'capital versé')}${st('Frais encaissés (30 j)', money(s.fees), 'services facturés')}</div>
      <div class="grid2"><div class="card"><div class="card-h"><div class="t">${ic('clock', 16)} Prochaines échéances</div></div>${s.due.map(l => `<div class="item"><div class="grow"><b>${esc(l.client)}</b><small>Prêt #${l.id} · ${l.due > Date.now() / 1000 ? 'dans ' + durLeft(l.due) : 'à prélever'}</small></div><span class="price">${money(l.installment + l.penalties)}</span>${chip(...BANK_STATUS[l.status])}</div>`).join('') || '<p class="hint">Aucun prêt en cours.</p>'}</div>
      <div class="card"><div class="card-h"><div class="t">${ic('file', 16)} Activité récente</div></div>${s.recent.map(e => `<div class="item"><div class="grow"><b>${esc(e.client)}</b><small>${esc(e.label)} · ${ago(e.t)}</small></div>${e.amount ? `<span class="price">${money(e.amount)}</span>` : ''}${chip(...(BANK_KINDS[e.kind] || [e.kind, 'mute']))}</div>`).join('') || '<p class="hint">Aucune activité.</p>'}</div></div>
      <p class="hint mt">Les échéances sont prélevées <b>automatiquement</b> sur le compte bancaire du client (toutes les ${this.d.limits.interval} h). Impayé : pénalité de ${this.d.limits.lateFee} %, et prêt « en défaut » après ${this.d.limits.defaultAfter} échéances manquées.</p>`;
  },

  /* ── Clients ── */
  tab_clients() {
    return `<div class="pts"><div>
      <div class="row" style="margin-bottom:10px"><input id="b-q" placeholder="Rechercher un client…" value="${esc(this.q)}" style="flex:1"><button class="icon" data-a="bSearch">${ic('search', 16)}</button></div>
      <select id="b-flag" id="b-flag" style="width:100%;margin-bottom:10px"><option value="">Tous les statuts</option>${Object.entries(this.d.flags).map(([k, l]) => `<option value="${k}" ${this.flag === k ? 'selected' : ''}>${esc(l)}</option>`).join('')}</select>
      <button class="sm primary" data-a="bNearest" style="width:100%;margin-bottom:6px">${ic('user', 14)} Client en face</button><button class="sm" data-a="bNew" style="width:100%;margin-bottom:10px">${ic('plus', 14)} Nouvelle fiche</button>
      ${this.clients.map(c => `<div class="pt ${this.sel === c.id ? 'active' : ''}" data-a="bOpen" data-v="${c.id}">${tile('user')}<div style="flex:1;min-width:0"><b>${esc(c.name)}</b><small>${c.loans ? c.loans + ' prêt(s) en cours · ' : ''}${esc(this.d.flags[c.flag] || '')}</small></div>${chip(c.rating, BANK_RATING_KIND[c.rating])}</div>`).join('') || '<p class="hint">Aucune fiche.</p>'}</div>
      <div>${this.form ? this.clForm() : this.cl ? this.clDetail() : emptyState('folder', 'Aucune fiche ouverte', 'Recherche un client, ou clique sur « Client en face » pour ouvrir (ou créer) la fiche de la personne devant toi.')}</div></div>`;
  },

  clDetail() {
    const C = this.cl.client, E = this.cl.entries, L = this.cl.loans, adm = this.d.perms.admin, b = this.cl.balance;
    const open = L.filter(l => ['active', 'late', 'defaulted'].includes(l.status));
    return `<div class="card"><div class="card-h"><div class="t">${ic('user', 16)} ${esc(C.firstname + ' ' + C.lastname)}</div><div class="row" style="gap:8px">${chip('Cote ' + C.rating, BANK_RATING_KIND[C.rating])}${chip(this.d.flags[C.flag] || C.flag, C.flag === 'watch' ? 'bad' : C.flag === 'vip' ? 'ok' : 'mute')}</div></div>
      <div class="grid3"><div class="stat"><div class="eyebrow">Compte bancaire</div><div class="v" style="font-size:20px">${b ? money(b.bank) : '—'}</div><div class="s">${b ? 'visible : client en face de toi' : this.cl.online ? 'le client doit être en face de toi' : 'client hors ligne'}</div></div>
        <div class="stat"><div class="eyebrow">Espèces</div><div class="v" style="font-size:20px">${b ? money(b.cash) : '—'}</div></div>
        <div class="stat"><div class="eyebrow">Plafond d'emprunt</div><div class="v" style="font-size:20px">${this.cl.maxLoan > 0 ? money(this.cl.maxLoan) : 'Refusé'}</div><div class="s">selon la cote ${C.rating}</div></div></div>
      <p class="hint mt" style="white-space:pre-wrap">${esc(C.notes || 'Aucune note sur ce client.')}</p>
      <div class="row wrap mt"><button data-a="bEdit">${ic('edit', 15)} Modifier</button>${this.d.perms.loan ? `<button data-a="bGoLoan">${ic('percent', 15)} Proposer un prêt</button>` : ''}${adm ? `<button class="danger" data-a="bDel">${ic('trash', 15)} Supprimer</button>` : ''}</div></div>
      ${open.length ? `<div class="card"><div class="card-h"><div class="t">Prêts en cours</div></div>${open.map(l => this.loanRow(l, false)).join('')}</div>` : ''}
      <div class="card"><div class="card-h"><div class="t">Ajouter une note</div></div><div class="row"><input id="b-note" maxlength="120" placeholder="ex: Client fiable, a remboursé en avance" style="flex:1" value="${esc(this.noteText)}"><button class="primary" data-a="bNote">${ic('plus', 15)} Ajouter</button></div></div>
      <div class="card"><div class="card-h"><div class="t">Historique</div></div>${E.length ? E.map(e => `<div class="item"><div class="grow"><b>${esc(e.label)}</b><small>${esc(e.officer || '')} · ${fmtDate(e.t)}</small></div>${e.amount ? `<span class="price">${money(e.amount)}</span>` : ''}${chip(...(BANK_KINDS[e.kind] || [e.kind, 'mute']))}${adm ? `<button class="icon danger" data-a="bEntryDel" data-v="${e.id}">${ic('trash', 14)}</button>` : ''}</div>`).join('') : '<p class="hint">Aucune entrée.</p>'}</div>`;
  },

  clForm() {
    const f = this.form, b = 'Bank.form';
    return `<div class="card"><div class="card-h"><div class="t">${ic('edit', 16)} ${f.id ? 'Modifier la fiche' : 'Nouvelle fiche'}</div></div>
      <div class="grid2">${fld('Prénom', `<input data-path="${b}.firstname" value="${esc(f.firstname)}" maxlength="50">`)}${fld('Nom', `<input data-path="${b}.lastname" value="${esc(f.lastname)}" maxlength="50">`)}</div>
      <div class="grid2 mt">${fld('Cote de crédit', `<select data-path="${b}.rating">${this.d.ratings.map(r => `<option value="${r}" ${f.rating === r ? 'selected' : ''}>${r} — plafond ${this.d.ratingLimit[r] || 0} % du max</option>`).join('')}</select>`)}${fld('Statut', `<select data-path="${b}.flag">${Object.entries(this.d.flags).map(([k, l]) => `<option value="${k}" ${f.flag === k ? 'selected' : ''}>${esc(l)}</option>`).join('')}</select>`)}</div>
      <div class="mt">${fld('Notes internes', `<textarea data-path="${b}.notes" maxlength="2000">${esc(f.notes)}</textarea>`)}</div>
      <div class="row mt"><button class="primary" data-a="bSave">${ic('check', 15)} Enregistrer</button><button data-a="bCancel">Annuler</button></div></div>`;
  },

  /* ── Prêts ── */
  loanRow(l, withName = true) {
    const pct = Math.min(100, Math.round((l.installments - l.left) / l.installments * 100)), p = this.d.perms;
    const st = BANK_STATUS[l.status] || [l.status, 'mute'], openL = ['active', 'late', 'defaulted'].includes(l.status);
    return `<div class="card" style="padding:14px;margin-bottom:10px"><div class="row"><div class="grow" style="flex:1;min-width:0"><div class="row" style="gap:8px">${chip(...st)}<b>${withName ? esc(l.name) + ' · ' : ''}Prêt #${l.id}</b></div>
        <small style="color:var(--muted)">${money(l.principal)} à ${l.rate} % · ${l.installments} × ${money(l.installment)}${openL ? ' · reste ' + money(l.outstanding) + (l.penalties ? ' (dont ' + money(l.penalties) + ' de pénalités)' : '') : ''}${openL ? ' · échéance ' + (l.due > Date.now() / 1000 ? 'dans ' + durLeft(l.due) : 'à prélever') : ''}</small>
        <div style="height:6px;border-radius:99px;background:var(--surface-2,rgba(255,255,255,.08));margin-top:8px;overflow:hidden"><div style="height:100%;width:${pct}%;background:var(--accent)"></div></div></div>
        ${openL ? `<div class="row wrap" style="gap:6px;justify-content:flex-end">${p.loan ? `<button class="sm" data-a="bRemind" data-v="${l.id}">Rappel</button>` : ''}${p.admin ? `<button class="sm" data-a="bCollect" data-v="${l.id}">Prélever</button><button class="sm danger" data-a="bForgive" data-v="${l.id}">Annuler</button>` : ''}</div>` : ''}</div></div>`;
  },

  tab_loans() {
    const d = this.d, L = d.limits, o = this.offer, can = d.perms.loan;
    const total = Math.ceil(o.amount * (100 + o.rate) / 100), inst = Math.ceil(total / o.n);
    const filters = [['open', 'En cours'], ['late', 'En retard'], ['defaulted', 'En défaut'], ['paid', 'Soldés'], ['forgiven', 'Annulés']];
    return `<div class="grid2" style="align-items:start"><div>
        <div class="row wrap" style="gap:6px;margin-bottom:12px">${filters.map(([k, l]) => `<button class="sm ${this.loanFilter === k ? 'primary' : ''}" data-a="bFilter" data-v="${k}">${l}</button>`).join('')}</div>
        ${this.loans.map(l => this.loanRow(l)).join('') || emptyState('percent', 'Aucun prêt', 'Aucun prêt dans cette catégorie.')}</div>
      ${can ? `<div class="card"><div class="card-h"><div class="t">${ic('plus', 16)} Proposer un prêt</div></div>
        <div class="grid2">${fld(`Montant (${money(L.minLoan)} à ${money(L.maxLoan)})`, `<input type="number" min="${L.minLoan}" max="${L.maxLoan}" step="100" data-path="Bank.offer.amount" data-t="n" value="${o.amount}">`)}
          ${fld(`Intérêt total (${L.minRate} à ${L.maxRate} %)`, `<input type="number" min="${L.minRate}" max="${L.maxRate}" data-path="Bank.offer.rate" data-t="n" value="${o.rate}">`)}</div>
        <div class="grid2 mt">${fld('Nombre d\'échéances', `<select data-path="Bank.offer.n" data-t="n">${L.terms.map(t => `<option value="${t}" ${o.n === t ? 'selected' : ''}>${t} échéances (≈ ${Math.round(t * L.interval / 24 * 10) / 10} jours)</option>`).join('')}</select>`)}${fld('Note (dossier)', `<input data-path="Bank.offer.note" maxlength="200" value="${esc(o.note)}" placeholder="optionnel">`)}</div>
        <div class="grid3 mt" id="b-sum">${this.sum(total, inst)}</div>
        <p class="hint mt">Le <b>client en face de toi</b> reçoit l'offre à l'écran et doit l'accepter. ${d.funding === 'society' ? 'Le capital est prélevé sur le compte de la banque.' : 'Le capital est créé par le serveur.'} Plafond selon la cote du client (max ${L.maxActive} prêts à la fois).</p>
        <button class="primary mt" data-a="bOffer">${ic('percent', 15)} Proposer au client</button></div>`
        : `<div class="card"><p class="hint">Ton grade ne permet pas de proposer des prêts.</p></div>`}</div>`;
  },

  sum(total, inst) {
    const x = (l, v, s) => `<div class="stat"><div class="eyebrow">${l}</div><div class="v" style="font-size:18px">${v}</div><div class="s">${s}</div></div>`;
    return x('Échéance', money(inst), `× ${this.offer.n}`) + x('Total remboursé', money(inst * this.offer.n), 'capital + intérêts') + x('Gain banque', money(inst * this.offer.n - this.offer.amount), `${this.offer.rate} %`);
  },

  /* ── Guichet ── */
  tab_counter() {
    const o = this.op, L = this.d.limits;
    return `<div class="card" style="max-width:640px"><div class="card-h"><div class="t">${ic('dollar', 16)} Opération au guichet</div></div>
      <div class="row" style="gap:8px;margin-bottom:14px"><button class="${o.kind === 'deposit' ? 'primary' : ''}" data-a="bKind" data-v="deposit" style="flex:1">Dépôt (espèces → compte)</button><button class="${o.kind === 'withdraw' ? 'primary' : ''}" data-a="bKind" data-v="withdraw" style="flex:1">Retrait (compte → espèces)</button></div>
      ${fld(`Montant (${money(L.minOp)} à ${money(L.maxOp)})`, `<input type="number" min="${L.minOp}" max="${L.maxOp}" data-path="Bank.op.amount" data-t="n" value="${o.amount}">`)}
      <div class="row wrap mt" style="gap:6px">${[100, 500, 1000, 5000, 10000].map(v => `<button class="sm" data-a="bQuick" data-v="${v}">${money(v)}</button>`).join('')}</div>
      <p class="hint mt">Le <b>client en face de toi</b> voit l'opération à l'écran et doit la <b>confirmer</b> : rien n'est déplacé sans son accord. Elle est ajoutée à sa fiche.</p>
      <button class="primary mt" data-a="bOp">${ic('check', 15)} Proposer l'opération</button></div>`;
  },

  /* ── Frais & services ── */
  tab_fees() {
    const d = this.d, cur = this.feeIdx > 0 ? d.fees[this.feeIdx - 1] : null, L = d.limits;
    return `<div class="grid2"><div class="card"><div class="card-h"><div class="t">${ic('file', 16)} Services de la banque</div></div>
      ${d.fees.map((f, i) => `<div class="item click" data-a="bFeeSel" data-v="${i + 1}" style="${this.feeIdx === i + 1 ? 'border-color:var(--accent-line);background:var(--accent-soft)' : ''}"><div class="grow"><b>${esc(f.label)}</b></div><span class="price">${money(f.amount)}</span></div>`).join('')}
      <div class="item click" data-a="bFeeSel" data-v="0" style="margin-top:6px;${this.feeIdx === 0 ? 'border-color:var(--accent-line);background:var(--accent-soft)' : ''}"><div class="grow"><b>Frais libres</b><small>Motif et montant au choix (${money(L.minFee)} à ${money(L.maxFee)})</small></div></div></div>
      <div class="card"><div class="card-h"><div class="t">Facturer le client</div></div>
        ${this.feeIdx === 0 ? `<div class="grid2">${fld('Motif', '<input id="bf-l" maxlength="60" placeholder="ex: Frais de tenue de compte">')}${fld('Montant ($)', `<input id="bf-a" type="number" min="${L.minFee}" max="${L.maxFee}" value="${L.minFee}">`)}</div>`
          : `<div class="stat"><div class="eyebrow">Service choisi</div><div class="v" style="font-size:18px">${cur ? esc(cur.label) : '—'}</div><div class="s">${cur ? money(cur.amount) : 'Choisis un service'}</div></div>`}
        <p class="hint mt">Le <b>client en face de toi</b> reçoit la facture à l'écran et la règle directement (argent → compte de la banque). Le service est ajouté à sa fiche une fois payé.</p>
        <button class="primary mt" data-a="bFee">${ic('dollar', 15)} Envoyer la facture</button></div></div>`;
  },

  /* ── Équipe ── */
  tab_team() { return `<div id="b-team">${this.teamHtml()}</div>`; },
  teamHtml() {
    const T = (this.live && this.live.team) || [];
    return `<div class="grid3" style="margin-bottom:14px"><div class="stat"><div class="eyebrow">En service</div><div class="v">${T.length}</div></div></div>`
      + T.map(t => `<div class="item">${tile('user')}<div class="grow"><b>${esc(t.name)}${t.me ? ' (toi)' : ''}</b><small>${esc(t.grade || '')}${t.dist != null && !t.me ? ' · à ' + t.dist + ' m' : ''}</small></div></div>`).join('');
  },

  /* ── Données ── */
  async loadDash() { const r = await rpc('bank:dash'); if (r && r.ok) this.dash = r; },
  async loadClients() { const r = await rpc('bank:clients', this.q, this.flag); if (r && r.ok) this.clients = r.list; },
  async loadLoans() { const r = await rpc('bank:loans', this.loanFilter); if (r && r.ok) this.loans = r.list; },
  async openClient(id) { const r = await rpc('bank:client', id); if (!r || !r.ok) return toast((r && r.error) || 'Erreur', 'err'); this.sel = id; this.cl = r; this.form = null; },
  async poll(first) {
    const r = await rpc('bank:live');
    if (!r || !r.ok) return;
    this.live = r;
    if (first) return;
    if (this.tab === 'team') { const el = document.getElementById('b-team'); if (el) el.innerHTML = this.teamHtml(); }
    if (r.balance != null) document.querySelectorAll('[data-live=money]').forEach(n => { n.innerHTML = Number(r.balance).toLocaleString('fr-FR') + '<small>$</small>'; });
  },

  async onA(el) {
    const a = el.dataset.a, v = el.dataset.v, ok = (r, m) => { if (!r || !r.ok) { toast((r && r.error) || 'Erreur', 'err'); return false; } if (m) toast(m, 'ok'); return true; };
    const val = id => (document.getElementById(id) || {}).value || '';
    switch (a) {
      case 'nav': this.tab = v; this.form = null;
        if (v === 'home') await this.loadDash();
        if (v === 'clients') await this.loadClients();
        if (v === 'loans') await this.loadLoans();
        if (v === 'team') await this.poll(true);
        return this.render();
      case 'bSearch': this.q = val('b-q').trim(); await this.loadClients(); return this.render();
      case 'bFlag': this.flag = el.value; await this.loadClients(); return this.render();
      case 'bOpen': await this.openClient(Number(v)); return this.render();
      case 'bNew': this.form = { id: null, firstname: '', lastname: '', rating: 'C', flag: 'normal', notes: '' }; this.cl = null; this.sel = null; return this.render();
      case 'bEdit': this.form = { ...this.cl.client }; return this.render();
      case 'bCancel': this.form = null; return this.render();
      case 'bSave': { const r = await rpc('bank:saveClient', this.form); if (!ok(r, 'Fiche enregistrée')) return; await this.loadClients(); await this.openClient(r.id); return this.render(); }
      case 'bNearest': { const r = await rpc('bank:nearest', 0); if (!ok(r)) return; await this.loadClients(); await this.openClient(r.id); return this.render(); }
      case 'bDel': if (!await confirmBox('Supprimer cette fiche ?', 'L\'historique et les prêts soldés de ce client seront supprimés définitivement.', 'Supprimer')) return; if (!ok(await rpc('bank:deleteClient', this.sel), 'Fiche supprimée')) return; this.cl = null; this.sel = null; await this.loadClients(); return this.render();
      case 'bNote': { this.noteText = ''; if (!ok(await rpc('bank:note', this.sel, val('b-note').trim()), 'Note ajoutée')) return; await this.openClient(this.sel); return this.render(); }
      case 'bEntryDel': if (!ok(await rpc('bank:delEntry', Number(v)))) return; await this.openClient(this.sel); return this.render();
      case 'bGoLoan': this.tab = 'loans'; await this.loadLoans(); return this.render();
      case 'bFilter': this.loanFilter = v; await this.loadLoans(); return this.render();
      case 'bOffer': { const o = this.offer; if (!ok(await rpc('bank:offerLoan', 0, 0, o.amount, o.rate, o.n, o.note), 'Offre envoyée au client')) return; return; }
      case 'bRemind': return ok(await rpc('bank:remind', Number(v)), 'Rappel envoyé au client');
      case 'bCollect': if (!ok(await rpc('bank:collect', Number(v)), 'Échéance prélevée')) return; await this.loadLoans(); return this.render();
      case 'bForgive': if (!await confirmBox('Annuler ce prêt ?', 'Le solde restant est effacé : la banque ne récupérera pas cet argent.', 'Annuler le prêt')) return; if (!ok(await rpc('bank:forgive', Number(v)), 'Prêt annulé')) return; await this.loadLoans(); return this.render();
      case 'bKind': this.op.kind = v; return this.render();
      case 'bQuick': this.op.amount = Number(v); return this.render();
      case 'bOp': return ok(await rpc('bank:op', 0, 0, this.op.kind, this.op.amount), 'Opération proposée au client');
      case 'bFeeSel': this.feeIdx = Number(v); return this.render();
      case 'bFee': return ok(await rpc('bank:fee', 0, 0, this.feeIdx, val('bf-l').trim(), Number(val('bf-a')) || 0), 'Facture envoyée au client');
    }
  },

  async onInput(el, isChange) {
    if (el.id === 'b-flag' && isChange) { this.flag = el.value; await this.loadClients(); return this.render(); }
    const path = el.dataset.path; if (!path || !path.startsWith('Bank.')) return;
    setPath(Bank, path.slice(5), el.dataset.t === 'n' ? Number(el.value) : el.value);
    if (this.tab === 'loans' && path.startsWith('Bank.offer.')) {
      const o = this.offer, s = document.getElementById('b-sum');
      if (s) { const total = Math.ceil(o.amount * (100 + o.rate) / 100); s.innerHTML = this.sum(total, Math.ceil(total / o.n)); }
    }
  },
};

/* ════════════════════════════ RUNTIME (panneaux en jeu) ════════════════════════════ */
const Runtime = {
  kind: null, data: null, pointId: null, bossTab: 'money',

  open(kind, data, pointId) { if (kind === 'menu') this.menuData = data; this.kind = kind; this.data = data; this.pointId = pointId; this.bossTab = 'money'; this.q = ''; this.cat = ''; this.render(); },
  set(r) { this.data = { ...this.data, ...r }; this.render(); },

  render() {
    const d = this.data, k = this.kind;
    window.JBBack = ['invoiceForm', 'serve', 'jobannounce', 'emscalls'].includes(k) ? true : (!!window.JBBackFromMenu && k !== 'menu');
    const list = (arr, fn, empty) => arr.length ? arr.map(fn).join('') : `<p class="hint">${empty}</p>`;
    const row = (icon, title, sub, right) => `<div class="item">${tile(icon)}<div class="grow"><b>${esc(title)}</b>${sub ? `<small>${esc(sub)}</small>` : ''}</div>${right}</div>`;
    switch (k) {
      case 'garage': return $root.innerHTML = panel({ icon: KIND_ICON[d.garageKind || 'car'], title: d.label, sub: { car: 'Garage voitures', bike: 'Garage motos & vélos', aircraft: 'Hangar avions & hélicoptères', boat: 'Port — bateaux' }[d.garageKind || 'car'],
        body: `<p class="hint" style="margin-bottom:12px">Pour <b>ranger</b> un véhicule, rends-toi au point de rangement de ce garage (marker, touche E, au volant).</p>` + list(d.vehicles, v => row(KIND_ICON[d.garageKind || 'car'], v.label, v.model, `<button data-a="spawn" data-i="${v.idx}">Sortir</button>`), 'Aucun véhicule pour ton grade.') });
      case 'cloakroom': return $root.innerHTML = panel({ icon: 'shirt', title: d.label, sub: 'Vestiaire',
        body: `<button data-a="civil">${ic('user', 16)} Reprendre ma tenue civile</button>` + list(d.outfits, o => row('shirt', o.label, '', `<button data-a="wear" data-i="${o.idx}">Porter</button>`), 'Aucune tenue pour ton grade.') });
      case 'armory': return $root.innerHTML = panel({ icon: 'target', title: d.label, sub: 'Armurerie',
        body: list(d.items, it => row('target', it.label, it.name.toUpperCase().startsWith('WEAPON_') ? 'Arme' + (it.ammo ? ` · ${it.ammo} munitions` : '') : 'x' + it.count, `<button data-a="take" data-i="${it.idx}">Prendre</button>`), 'Rien de disponible pour ton grade.') });
      case 'shop': return $root.innerHTML = panel({ icon: 'cart', title: d.label, sub: 'Boutique',
        body: list(d.items, it => row('box', it.label, '', `<span class="price">${money(it.price)}</span><input class="qty" type="number" min="1" max="100" value="1" id="q${it.idx}"><button class="primary" style="height:38px" data-a="buy" data-i="${it.idx}">Acheter</button>`), 'Boutique vide.') });
      case 'boss': return this.renderBoss();
      case 'menu': $root.classList.add('corner'); return $root.innerHTML = panel({ icon: TYPE_ICON[d.type] || 'briefcase', title: d.jobLabel, sub: `Grade : ${d.grade}`, cls: 'corner',
        body: list(d.actions, a => `<div class="item click" data-a="act" data-id="${a.id}">${tile(ACTION_ICON[a.id] || 'grid')}<div class="grow"><b>${esc(a.label)}</b></div><span class="chev">${ic('chevron', 16)}</span></div>`, 'Aucune action.') });
      case 'leaveJob': $root.classList.add('corner'); return $root.innerHTML = panel({ icon: 'logout', title: 'Quitter le métier', sub: d.jobLabel, cls: 'corner',
        body: `<p class="hint">Tu es sûr de vouloir quitter <b>${esc(d.jobLabel)}</b> ? Tu perds ton grade et l'accès aux points, coffres et véhicules du métier.</p>
        <div class="row"><span class="spacer"></span><button data-a="leaveJobCancel">Annuler</button><button class="danger" data-a="leaveJobConfirm">Quitter le métier</button></div>` });
      case 'invoiceForm': $root.classList.add('corner'); return $root.innerHTML = panel({ icon: 'file', title: 'Facturer', sub: 'Le joueur le plus proche recevra la facture', cls: 'corner',
        body: `<div class="grid2">${fld('Motif', '<input id="iv-l" maxlength="60" placeholder="Prestation">')}${fld('Montant ($)', '<input id="iv-a" type="number" min="1" placeholder="500">')}</div><button class="primary" data-a="invSend">Envoyer la facture</button>` });
      case 'invoice': if (d.offer) return $root.innerHTML = panel({ icon: 'landmark', title: d.offer.title, sub: d.jobLabel,
        body: `<div class="card">${d.offer.lines.map(l => `<div class="item"><div class="grow"><small style="color:var(--muted)">${esc(l[0])}</small></div><b>${esc(l[1])}</b></div>`).join('')}</div><div class="row"><button class="danger" style="flex:1" data-a="invNo">${esc(d.offer.decline)}</button><button class="primary" style="flex:2" data-a="invPay">${ic('check', 16)} ${esc(d.offer.accept)}</button></div>` });
        return $root.innerHTML = panel({ icon: 'file', title: 'Facture reçue', sub: d.jobLabel,
        body: `<div class="card"><div class="eyebrow">Montant à régler</div><div class="big">${Number(d.amount).toLocaleString('fr-FR')}<small>$</small></div><p class="hint">${esc(d.label)}</p></div><div class="row"><button class="danger" style="flex:1" data-a="invNo">Refuser</button><button class="primary" style="flex:2" data-a="invPay">${ic('check', 16)} Payer ${money(d.amount)}</button></div>` });
      case 'harvest': return $root.innerHTML = panel({ icon: 'sprout', title: d.label, sub: 'Récolte',
        body: `<div class="card"><div class="eyebrow">À récolter</div><div class="big" style="font-size:30px">${d.count}× ${esc(d.item.label)}</div><p class="hint">${d.seconds} secondes sur place. Reste près du marker (X pour annuler).</p></div>
          <button class="primary" data-a="work" data-i="0">${ic('sprout', 16)} Récolter</button>` });
      case 'kitchen': return $root.innerHTML = panel({ icon: 'utensils', title: d.label, sub: 'Cuisine / préparation', cls: 'md',
        body: list(d.recipes, r => `<div class="item">${tile('utensils')}<div class="grow"><b>${esc(r.label)}</b><small>${r.inputs.map(x => `<span style="color:${x.have >= x.count ? 'var(--ok)' : 'var(--bad, #ef4444)'}">${x.count}× ${esc(x.label)} (${x.have})</span>`).join(' · ')} → <span style="color:var(--text)">${r.output.count}× ${esc(r.output.label)}</span> · ${r.seconds}s</small></div>
          <input class="qty" type="number" min="1" max="${d.maxBatch}" value="1" id="kq${r.idx}"><button class="primary" style="height:38px" data-a="work" data-i="${r.idx}" ${r.can ? '' : 'disabled'}>Préparer</button></div>`, 'Aucune recette pour ton grade.') });
      case 'emscalls': $root.classList.add('corner'); return $root.innerHTML = panel({ icon: 'cross', title: 'Appels EMS', sub: `${d.jobLabel} — urgences en cours`, cls: 'corner',
        body: list(d.list, c => `<div class="item" style="flex-wrap:wrap">${tile('cross')}<div class="grow" style="flex:1 1 150px;min-width:0"><b>${esc(c.name)}</b><small>${c.dist} m · ${ago(c.t)}${c.units.length ? ' · En route : ' + c.units.map(u => esc(u.name)).join(', ') : ''}</small></div>
          <div class="row" style="gap:6px;width:100%"><button class="sm ${c.mine ? '' : 'primary'}" style="flex:1" data-a="emsTake" data-id="${c.id}">${c.mine ? 'Quitter' : 'Prendre'}</button><button class="sm" data-a="emsGps" data-x="${c.x}" data-y="${c.y}">GPS</button><button class="sm" data-a="emsClose" data-id="${c.id}">Clôturer</button></div></div>`, 'Aucune urgence en cours. Quand un joueur appelle les EMS, tu reçois une alerte (touche Y pour prendre l\'appel).') });
      case 'jobannounce': $root.classList.add('corner'); return $root.innerHTML = panel({ icon: 'megaphone', title: 'Annonce entreprise', sub: `${d.jobLabel} — diffusée ${d.radius ? `dans un rayon de ${d.radius} m` : 'à tous les joueurs'}`, cls: 'corner',
        body: `<div class="grid2">${fld('Type', `<select id="an-k">${d.types.map(t => `<option value="${esc(t.id)}">${esc(t.label)}</option>`).join('')}</select>`)}${fld('Titre', `<input id="an-t" maxlength="${d.maxTitle}" placeholder="ex: Grande ouverture !">`)}</div>
          ${fld('Message', `<textarea id="an-m" maxlength="${d.maxText}" style="min-height:80px" placeholder="Ton annonce…"></textarea>`)}
          <p class="hint">${d.cost ? `Coût : <b style="color:var(--text)">${money(d.cost)}</b> prélevés sur la société${d.society != null ? ` (solde ${money(d.society)})` : ''}. ` : 'Gratuit. '}${d.cooldown ? `Délai entre deux annonces : ${d.cooldown} s${d.left ? ` — encore <b style="color:var(--text)">${d.left} s</b>` : ''}.` : ''}</p>
          <button class="primary" data-a="annSend">${ic('megaphone', 15)} Diffuser l'annonce</button>
          ${d.history.length ? `<div class="lbl" style="margin:14px 0 6px">Dernières annonces</div>${d.history.map(h => `<div class="logline"><b>${esc(h.title)}</b> — ${esc(h.text)}<br>${esc(h.author || '')} · ${fmtDate(h.t)}</div>`).join('')}` : ''}` });
      case 'serve': $root.classList.add('corner'); return $root.innerHTML = panel({ icon: 'utensils', title: 'Vendre un produit', sub: 'Le client le plus proche reçoit l\'offre et paie directement', cls: 'corner',
        body: list(d.items, it => `<div class="item">${tile('box')}<div class="grow"><b>${esc(it.label)}</b><small>${money(it.price)} · tu en as ${it.have}</small></div>
          <input class="qty" type="number" min="1" max="${d.maxServe}" value="1" id="sq${it.idx}"><button class="primary" style="height:38px" data-a="sell" data-i="${it.idx}" ${it.have > 0 ? '' : 'disabled'}>Proposer</button></div>`, 'La carte est vide : le patron ajoute des produits dans le builder (onglet Général).') });
      case 'missions': return this.renderMissions();
      case 'missionStatus': $root.classList.add('corner'); return this.renderMissionStatus();
      case 'showroom': return this.renderShowroom();
      case 'dealerOffer': return $root.innerHTML = panel({ icon: 'car', title: 'Offre d\'achat', sub: d.jobLabel,
        body: `<div class="card"><b style="font-size:16px">${esc(d.label)}</b><p class="hint mt-s">${esc(d.category || '')}</p><div class="eyebrow mt">Prix</div><div class="big">${Number(d.price).toLocaleString('fr-FR')}<small>$</small></div><p class="hint">Le véhicule est ajouté à ton garage / livré devant toi après le paiement.</p></div><div class="row"><button class="danger" style="flex:1" data-a="carNo">Refuser</button><button class="primary" style="flex:2" data-a="carYes">${ic('check', 16)} Acheter · ${money(d.price)}</button></div>` });
      case 'door': return this.renderDoor();
      case 'wardrobe': return this.renderWardrobe();
      case 'ring': return $root.innerHTML = panel({ icon: 'bell', title: 'Quelqu\'un sonne', sub: 'À la porte',
        body: `<div class="card"><b style="font-size:16px">${esc(d.name)}</b><p class="hint mt-s">sonne à ta porte. Le laisser entrer ?</p></div><div class="row"><button class="danger" style="flex:1" data-a="ringNo">Refuser</button><button class="primary" style="flex:2" data-a="ringYes">${ic('check', 16)} Ouvrir la porte</button></div>` });
      case 'propOffer': return $root.innerHTML = panel({ icon: 'home', title: d.deal === 'rent' ? 'Offre de location' : 'Offre d\'achat', sub: d.jobLabel,
        body: `<div class="card"><b style="font-size:16px">${esc(d.label)}</b><p class="hint mt-s">${esc(d.address || '')}</p><div class="eyebrow mt">${d.deal === 'rent' ? `Loyer · par semaine (${d.days} jours)` : 'Prix'}</div><div class="big">${Number(d.price).toLocaleString('fr-FR')}<small>$</small></div>${d.deal === 'rent' ? '<p class="hint">Le premier loyer est payé maintenant. Les suivants se règlent à la porte.</p>' : ''}</div><div class="row"><button class="danger" style="flex:1" data-a="offerNo">Refuser</button><button class="primary" style="flex:2" data-a="offerYes">${ic('check', 16)} ${d.deal === 'rent' ? 'Louer' : 'Acheter'} · ${money(d.price)}</button></div>` });
    }
  },

  renderMissions() {
    const d = this.data, mult = d.mult / 100;
    const row = t => {
      const reward = t.reward.min === t.reward.max ? money(Math.round(t.reward.min * mult)) : `${money(Math.round(t.reward.min * mult))} – ${money(Math.round(t.reward.max * mult))}`;
      const why = t.locked ? `Grade ${esc((d.grades[t.minGrade] || {}).label || t.minGrade)} requis` : (t.cooldownLeft ? `Disponible dans ${t.cooldownLeft} s` : '');
      return `<div class="item">${tile('route')}<div class="grow"><b>${esc(t.label)}</b><small>${esc(t.desc)}</small><small style="color:var(--text-2)">${t.steps} étapes${t.timeLimit ? ' · ' + Math.round(t.timeLimit / 60) + ' min' : ''} · <b style="color:var(--ok)">${reward}</b>${why ? ' · ' + why : ''}</small></div>
        <button class="sm primary" data-a="missionStart" data-id="${esc(t.id)}" ${t.locked || t.cooldownLeft || d.active ? 'disabled' : ''}>Démarrer</button></div>`;
    };
    $root.innerHTML = panel({ icon: 'route', title: d.label, sub: `${d.jobLabel} — missions`, cls: 'md',
      body: `<div class="grid2"><div class="stat"><div class="eyebrow">Missions réalisées</div><div class="v">${d.stats.done}</div></div><div class="stat"><div class="eyebrow">Total gagné</div><div class="v">${money(d.stats.earned)}</div></div></div>
        ${d.active ? `<div class="card"><div class="card-h"><div class="t">${ic('route', 16)} En cours : ${esc(d.active.label)}</div>${chip(`étape ${d.active.idx}/${d.active.total}`, 'info')}</div><button class="danger" data-a="missionCancel">Annuler la mission</button></div>` : ''}
        ${d.templates.map(row).join('') || '<p class="hint">Aucune mission pour ce métier.</p>'}
        <p class="hint">Gains ×${d.mult}% · ${d.source === 'society' ? 'payés par la société' : 'versés par le serveur'}.</p>` });
  },

  renderMissionStatus() {
    const d = this.data, a = d.active;
    $root.innerHTML = panel({ icon: 'route', title: 'Missions PNJ', sub: d.jobLabel, cls: 'corner',
      body: a ? `<div class="card" style="padding:12px"><b>${esc(a.label)}</b><p class="hint mt-s">Étape ${a.idx}/${a.total} — ${esc(a.stepLabel || '')}</p>${a.timeLimit ? `<p class="hint">Temps imparti : ${Math.round(a.timeLimit / 60)} min</p>` : ''}</div><button class="danger" data-a="missionCancel">Annuler la mission</button>`
        : `<p class="hint">Aucune mission en cours. Rends-toi au point <b>Missions PNJ</b> de ton métier pour en démarrer une.</p><div class="stat"><div class="eyebrow">Réalisées</div><div class="v">${d.stats.done}</div><div class="s">${money(d.stats.earned)} gagnés</div></div>` });
  },

  q: '',
  renderShowroom() {
    const d = this.data, q = (this.q || '').toLowerCase(), cat = this.cat || '';
    let list = d.vehicles.filter(v => (!cat || v.category === cat) && (!q || (v.label + ' ' + v.category + ' ' + v.model).toLowerCase().includes(q)));
    if (d.focus) list = [...list.filter(v => v.model === d.focus), ...list.filter(v => v.model !== d.focus)];
    const total = list.length;
    list = list.slice(0, 80);
    const row = v => `<div class="item">${tile('car')}<div class="grow"><b>${esc(v.label)}${d.focus === v.model ? ' ' + chip('Exposé', 'info nodot') : ''}</b><small>${esc(v.category || 'Véhicule')}${v.stock > 0 ? ' · ' + v.stock + ' en stock' : ''}</small></div><span class="price">${money(v.price)}</span>
      ${d.hasTest ? `<button class="sm" data-a="testCar" data-id="${esc(v.model)}">Essai</button>` : ''}
      ${d.canSell && d.grade >= v.min_grade ? `<button class="sm primary" data-a="sellCar" data-id="${esc(v.model)}">Vendre</button>` : ''}
      ${d.selfService ? `<button class="sm primary" data-a="buyCar" data-id="${esc(v.model)}">Acheter</button>` : ''}</div>`;
    $root.innerHTML = panel({ icon: 'car', title: d.label, sub: `${d.jobLabel} — catalogue (${d.vehicles.length})`, cls: 'md',
      body: `<div class="row"><div style="position:relative;flex:1"><input data-path="q" id="sr-q" placeholder="Rechercher un véhicule…" value="${esc(this.q || '')}" style="padding-left:38px"><span style="position:absolute;left:12px;top:10px;color:var(--muted)">${ic('search', 16)}</span></div>
        <select data-path="cat" style="width:190px"><option value="">Toutes catégories</option>${(d.categories || []).filter(c => d.vehicles.some(v => v.category === c.name)).map(c => `<option value="${esc(c.name)}" ${cat === c.name ? 'selected' : ''}>${esc(c.label)}</option>`).join('')}</select></div>
        ${d.canSell ? '<p class="hint">Vendre : le client le plus proche reçoit l\'offre à l\'écran.</p>' : (d.selfService ? '' : '<p class="hint">Demande à un vendeur pour acheter un véhicule.</p>')}
        ${list.map(row).join('') || '<p class="hint">Aucun véhicule disponible.</p>'}
        ${total > list.length ? `<p class="hint">${total - list.length} autres véhicules : affine ta recherche ou choisis une catégorie.</p>` : ''}` });
  },

  renderDoor() {
    const d = this.data, avail = d.status === 'available', owner = d.role === 'owner';
    const info = `<div class="card"><div class="card-h"><div class="t">${esc(d.address || 'Propriété')}</div>${avail ? chip('Disponible', 'ok') : (owner ? chip('Ta propriété', 'info') : d.role === 'key' ? chip('Tu as les clés', 'info') : chip('Occupée', 'mute'))}</div>
      <div class="kv"><span>Catégorie</span><span>${esc(d.categoryLabel || '')}</span></div>
      <div class="kv"><span>Agence</span><span>${esc(d.jobLabel)}</span></div>
      ${d.description ? `<p class="hint" style="margin:10px 0">${esc(d.description)}</p>` : ''}
      ${avail || owner ? `<div class="kv"><span>${d.deal === 'rent' ? 'Loyer / semaine' : 'Prix'}</span><span><b>${money(d.price)}</b></span></div>` : ''}
      ${owner && d.deal === 'rent' && d.rent_until ? `<div class="kv"><span>Loyer payé jusqu'au</span><span>${fmtDate(d.rent_until)}</span></div>` : ''}</div>`;
    let acts = '';
    if (d.role === 'owner' || d.role === 'key') acts += `<button class="primary" data-a="enter">${ic('login', 16)} Entrer</button>`;
    if (d.canVisit) acts += `<button class="primary" data-a="enter">${ic('login', 16)} Visiter le bien</button>`;
    if (d.role === 'visitor' && !avail) acts += `<button class="primary" data-a="ring">${ic('bell', 16)} Sonner</button>`;
    if (d.role === 'visitor' && avail) acts += `<p class="hint">Ce bien est ${d.deal === 'rent' ? 'à louer' : 'à vendre'} — contacte un agent de <b>${esc(d.jobLabel)}</b>.</p>`;
    if (owner && d.deal === 'rent') acts += `<button data-a="payRent">${ic('dollar', 16)} Payer le loyer · ${money(d.price)}</button>`;
    let keys = '';
    if (owner) {
      keys = `<div class="card"><div class="card-h"><div class="t">${ic('key', 16)} Clés · ${(d.keys || []).length}/${d.maxKeys}</div><button class="sm" data-a="giveKey">${ic('plus', 14)} Donner un double</button></div>
        ${(d.keys || []).map(k => `<div class="item" style="margin-bottom:6px">${tile('user')}<div class="grow"><b>${esc(k.name)}</b></div><button class="sm danger" data-a="rmKey" data-id="${esc(k.identifier)}">Retirer</button></div>`).join('') || '<p class="hint">Aucun double. « Donner un double » l\'offre au joueur le plus proche.</p>'}</div>`;
      if (d.deal === 'rent') keys += `<button class="danger" data-a="terminate">Résilier le bail</button>`;
    }
    $root.innerHTML = panel({ icon: 'home', title: d.label, sub: avail ? (d.deal === 'rent' ? 'À louer' : 'À vendre') : 'Propriété', body: info + (acts ? `<div style="display:flex;flex-direction:column;gap:10px">${acts}</div>` : '') + keys, cls: 'md' });
  },

  renderWardrobe() {
    const d = this.data;
    $root.innerHTML = panel({ icon: 'shirt', title: d.label, sub: `Penderie · ${d.outfits.length}/${d.max} tenues`, cls: 'md',
      body: `<div class="card"><div class="eyebrow" style="margin-bottom:12px">Enregistrer ma tenue actuelle</div><div class="row"><input id="wd-l" maxlength="60" placeholder="Nom de la tenue"><button class="primary" style="height:38px" data-a="wdSave">${ic('plus', 15)} Enregistrer</button></div></div>
        <button data-a="civil">${ic('user', 16)} Reprendre ma tenue civile</button>
        ${d.outfits.map(o => `<div class="item">${tile('shirt')}<div class="grow"><b>${esc(o.label)}</b></div><button class="sm" data-a="wdWear" data-id="${o.id}">Porter</button><button class="sm danger" data-a="wdDel" data-id="${o.id}">${ic('trash', 14)}</button></div>`).join('') || '<p class="hint">Aucune tenue enregistrée.</p>'}` });
  },

  renderBoss() {
    const d = this.data, tabs = [{ id: 'money', icon: 'dollar', text: 'Société' }, { id: 'staff', icon: 'users', text: 'Employés', count: d.employees.length }, { id: 'grades', icon: 'sliders', text: 'Salaires' }, { id: 'logs', icon: 'clock', text: 'Journal' }];
    let body = '';
    if (this.bossTab === 'money') {
      body = d.society ? `<div class="grid2" style="grid-template-columns:1fr 1fr"><div class="card"><div class="eyebrow">Solde de la société</div><div class="big" data-live="money">${Number(d.money).toLocaleString('fr-FR')}<small>$</small></div></div>
        <div class="card"><div class="eyebrow" style="margin-bottom:12px">Opération</div>${fld('Montant', '<input type="number" min="1" id="bm" placeholder="0">')}<div class="row mt"><button style="flex:1" data-a="wd">Retirer</button><button class="primary" style="flex:1" data-a="dep">Déposer</button></div></div></div>` : emptyState('dollar', 'Pas de compte société', 'Ce job n\'a pas de compte société.');
    } else if (this.bossTab === 'staff') {
      body = `<div class="row" style="margin-bottom:16px"><button class="primary" data-a="recruit">${ic('plus', 16)} Recruter le joueur le plus proche</button></div>` + (d.employees.map(e => {
        const locked = e.grade >= d.boss_grade;
        return `<div class="item">${tile('user')}<div class="grow"><b>${esc(e.name || 'Inconnu')}</b><small>${e.online ? 'En ligne' : 'Hors ligne'}</small></div>
          <select data-a="setgrade" data-id="${esc(e.identifier)}" style="width:190px" ${locked ? 'disabled' : ''}>${d.grades.map(g => `<option value="${g.grade}" ${g.grade === e.grade ? 'selected' : ''}>${esc(g.label)}</option>`).join('')}</select>
          <button class="sm danger" data-a="fire" data-id="${esc(e.identifier)}" ${locked ? 'disabled' : ''}>Virer</button></div>`;
      }).join('') || emptyState('users', 'Aucun employé', 'Recrute ton premier employé.'));
    } else if (this.bossTab === 'grades') {
      body = d.grades.map(g => `<div class="item">${tile('sliders')}<div class="grow"><b>${esc(g.label)}</b><small>Grade ${g.grade}</small></div><input type="number" min="0" style="width:130px" id="sal${g.grade}" value="${g.salary}"><button class="sm" data-a="salary" data-g="${g.grade}">Appliquer</button></div>`).join('');
    } else {
      body = `<div class="card">${d.logs.map(l => `<div class="logline"><b>${esc(l.action)}</b> · ${esc(l.player_name || '')} · ${esc(l.detail || '')}<br>${fmtDate(l.t)}</div>`).join('') || '<p class="hint">Journal vide.</p>'}</div>`;
    }
    const cur = tabs.find(t => t.id === this.bossTab);
    $root.innerHTML = shellSide({ profile: { initials: initials(d.jobLabel), title: d.jobLabel, sub: `Gestion · grade ${d.myGrade}` }, nav: [{ label: 'Direction', items: tabs }], active: this.bossTab,
      foot: '', head: { icon: cur.icon, title: cur.text, sub: d.jobLabel }, body });
  },

  async onA(el) {
    const a = el.dataset.a, i = Number(el.dataset.i), pid = this.pointId, d = this.data;
    const ok = (r, msg) => { if (!r || !r.ok) { toast((r && r.error) || 'Erreur', 'err'); return false; } if (msg) toast(msg, 'ok'); return true; };
    switch (a) {
      case 'nav': this.bossTab = el.dataset.v; return this.render();
      case 'spawn': return ok(await rpc('garage:spawn', pid, i));
      case 'wear': return ok(await rpc('cloak:wear', pid, i), 'Tenue enfilée');
      case 'civil': await rpc('cloakCivil'); return toast('Tenue civile', 'ok');
      case 'take': return ok(await rpc('armory:take', pid, i), 'Objet récupéré');
      case 'buy': return ok(await rpc('shop:buy', pid, i, Number(document.getElementById('q' + i).value)), 'Achat effectué');
      case 'leaveJobCancel': return this.open('menu', this.menuData);
      case 'leaveJobConfirm': { const r = await rpc('leaveJob'); if (!ok(r, 'Tu as quitté ton métier')) return; return close(); }
      case 'act':
        if (el.dataset.id === 'leavejob') { this.kind = 'leaveJob'; this.data = { jobLabel: (this.menuData || {}).jobLabel || '' }; return this.render(); }
        if (el.dataset.id === 'invoice') { this.kind = 'invoiceForm'; return this.render(); }
        if (el.dataset.id === 'tablet') { const r = await rpc('tablet:open'); if (!ok(r)) return; window.JBBackFromMenu = true; window.JBBack = true; Mod = Tablet; return Tablet.open(r); }
        if (el.dataset.id === 'emstablet') { const r = await rpc('emstab:open'); if (!ok(r)) return; window.JBBackFromMenu = true; window.JBBack = true; Mod = Ems; return Ems.open(r); }
        if (el.dataset.id === 'banktablet') { const r = await rpc('bank:open'); if (!ok(r)) return; window.JBBackFromMenu = true; window.JBBack = true; Mod = Bank; return Bank.open(r); }
        if (el.dataset.id === 'emscalls') { const r = await rpc('ems:list'); if (!ok(r)) return; this.data = r; this.kind = 'emscalls'; return this.render(); }
        if (el.dataset.id === 'jobannounce') { const r = await rpc('announce:open'); if (!ok(r)) return; this.data = r; this.kind = 'jobannounce'; this.annKind = null; return this.render(); }
        if (el.dataset.id === 'serve') { const r = await rpc('serve:menu'); if (!ok(r)) return; this.data = r; this.kind = 'serve'; return this.render(); }
        return rpc('doAction', el.dataset.id);
      case 'emsTake': { const r = await rpc('ems:take', Number(el.dataset.id)); if (!ok(r)) return; if (r.joined) rpc('waypoint', { x: r.x, y: r.y }); toast(r.joined ? 'Appel pris : GPS défini' : 'Appel quitté', 'ok'); const n = await rpc('ems:list'); if (n && n.ok) { this.data = n; this.render(); } return; }
      case 'emsGps': rpc('waypoint', { x: Number(el.dataset.x), y: Number(el.dataset.y) }); return toast('Point GPS défini', 'ok');
      case 'emsClose': { if (!ok(await rpc('ems:close', Number(el.dataset.id)), 'Appel clôturé')) return; const n = await rpc('ems:list'); if (n && n.ok) { this.data = n; this.render(); } return; }
      case 'annSend': {
        const r = await rpc('announce:send', document.getElementById('an-k').value, document.getElementById('an-t').value.trim(), document.getElementById('an-m').value.trim());
        if (!ok(r, 'Annonce diffusée')) return;
        const n = await rpc('announce:open'); if (n && n.ok) { this.data = n; this.render(); } return;
      }
      case 'work': { const q = document.getElementById('kq' + i); return ok(await rpc('kitchen:work', pid, i, q ? Number(q.value) : 1)); }
      case 'sell': {
        const q = Number(document.getElementById('sq' + i).value) || 1, r = await rpc('serve:offer', i, 0, q);
        if (ok(r, 'Offre envoyée au client, en attente de sa réponse')) close();
        return;
      }
      case 'invSend': return rpc('doAction', 'invoice', document.getElementById('iv-l').value.trim() || 'Facture', Number(document.getElementById('iv-a').value));
      case 'invPay': return rpc('invoiceAnswer', d.id, true);
      case 'invNo': return rpc('invoiceAnswer', d.id, false);
      case 'offerYes': return rpc('offerAnswer', d.id, true);
      case 'offerNo': return rpc('offerAnswer', d.id, false);
      case 'ringYes': return rpc('ringAnswer', d.ringer, d.propId, true);
      case 'ringNo': return rpc('ringAnswer', d.ringer, d.propId, false);
      /* immobilier : porte */
      case 'missionStart': { const r = await rpc('missions:start', pid, el.dataset.id); if (!r || !r.ok) toast((r && r.error) || 'Erreur', 'err'); return; }
      case 'missionCancel': { await rpc('missions:cancel'); toast('Mission annulée', 'ok'); return; }
      case 'sellCar': { const r = await rpc('dealer:offer', String(el.dataset.id)); if (ok(r, 'Offre envoyée au client')) close(); return; }
      case 'buyCar': { const v = d.vehicles.find(x => x.model === el.dataset.id); if (!await confirmBox('Acheter ce véhicule ?', `${v.label} — ${money(v.price)}`, 'Acheter', false)) return; const r = await rpc('dealer:buy', pid, v.model); if (ok(r, 'Achat effectué')) close(); return; }
      case 'testCar': { const r = await rpc('dealer:test', pid, String(el.dataset.id)); if (!r || !r.ok) toast((r && r.error) || 'Erreur', 'err'); return; }
      case 'carYes': return rpc('dealerAnswer', d.id, true);
      case 'carNo': return rpc('dealerAnswer', d.id, false);
      case 'enter': { const r = await rpc('prop:enter', d.id); if (!r || !r.ok) toast((r && r.error) || 'Erreur', 'err'); return; }
      case 'ring': { const r = await rpc('prop:ring', d.id); if (ok(r, 'Tu as sonné, patiente…')) close(); return; }
      case 'payRent': { const r = await rpc('prop:payRent', d.id); if (ok(r, 'Loyer payé')) this.set({ rent_until: r.rent_until }); return; }
      case 'giveKey': { const r = await rpc('prop:giveKey', d.id); if (ok(r, 'Double remis')) this.set({ keys: r.keys }); return; }
      case 'rmKey': { const r = await rpc('prop:removeKey', d.id, el.dataset.id); if (ok(r, 'Clé retirée')) this.set({ keys: r.keys }); return; }
      case 'terminate': if (!await confirmBox('Résilier le bail ?', 'Tu perds l\'accès au bien et le contenu des coffres est effacé.', 'Résilier')) return; if (ok(await rpc('prop:terminate', d.id), 'Bail résilié')) close(); return;
      /* immobilier : penderie */
      case 'wdSave': { const r = await rpc('wardrobeSave', d.propId, d.pointId, document.getElementById('wd-l').value.trim() || 'Tenue'); if (ok(r, 'Tenue enregistrée')) this.set({ outfits: r.outfits }); return; }
      case 'wdWear': return ok(await rpc('prop:wardrobe:wear', d.propId, d.pointId, Number(el.dataset.id)), 'Tenue enfilée');
      case 'wdDel': { const r = await rpc('prop:wardrobe:delete', d.propId, d.pointId, Number(el.dataset.id)); if (ok(r)) this.set({ outfits: r.outfits }); return; }
      /* boss */
      case 'dep': case 'wd': { const r = await rpc('boss:money', pid, a === 'dep' ? 'deposit' : 'withdraw', Number(document.getElementById('bm').value)); if (ok(r, 'Opération effectuée')) this.set(r); return; }
      case 'recruit': { const r = await rpc('boss:recruit', pid); if (ok(r, 'Employé recruté')) this.set(r); return; }
      case 'fire': { if (!await confirmBox('Virer cet employé ?', 'Il redeviendra chômeur.', 'Virer')) return; const r = await rpc('boss:fire', pid, el.dataset.id); if (ok(r, 'Employé viré')) this.set(r); return; }
      case 'salary': { const r = await rpc('boss:salary', pid, Number(el.dataset.g), Number(document.getElementById('sal' + el.dataset.g).value)); if (ok(r, 'Salaire mis à jour')) this.set(r); return; }
    }
  },

  async onInput(el, isChange) {
    if (el.dataset.path === 'cat') { this.cat = el.value; return this.render(); }
    if (el.dataset.path === 'q' && !isChange) {
      const pos = el.selectionStart; this.q = el.value; this.render();
      const inp = document.getElementById('sr-q'); if (inp) { inp.focus(); inp.setSelectionRange(pos, pos); }
      return;
    }
    if (!isChange || el.dataset.a !== 'setgrade') return;
    const r = await rpc('boss:setGrade', this.pointId, el.dataset.id, Number(el.value));
    if (r && r.ok) { toast('Grade modifié', 'ok'); this.set(r); } else { toast((r && r.error) || 'Erreur', 'err'); this.render(); }
  },
};
