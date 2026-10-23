const $ = (s, r = document) => r.querySelector(s);
const h = (tag, a, ...kids) => { const [t, ...cl] = tag.split('.'); const e = document.createElement(t); if (cl.length) e.className = cl.join(' '); for (const k in (a || {})) { if (a[k] == null) continue; if (k === 'html') e.innerHTML = a[k]; else if (k.startsWith('on')) e.addEventListener(k.slice(2), a[k]); else e.setAttribute(k, a[k]); } kids.flat().forEach(c => c != null && e.append(c.nodeType ? c : document.createTextNode(c))); return e; };
const post = (n, d) => (typeof GetParentResourceName === 'function' ? fetch(`https://${GetParentResourceName()}/${n}`, { method: 'POST', body: JSON.stringify(d || {}) }).then(r => r.json()).catch(() => 0) : Promise.resolve(1));
const money = n => '$' + Math.round(n || 0).toLocaleString('fr-FR');
const ICON = {
  home: '<path d="M3 11l9-8 9 8v10a1 1 0 01-1 1h-5v-7H9v7H4a1 1 0 01-1-1z"/>', doc: '<path d="M6 3h9l4 4v14H6zM14 3v5h5M9 13h7M9 17h7"/>',
  car: '<path d="M5 17h14M3 13l2-6h14l2 6v4H3zM7 17v2M17 17v2"/><circle cx="7.5" cy="13.5" r="1"/><circle cx="16.5" cy="13.5" r="1"/>', house: '<path d="M3 11l9-8 9 8M5 10v11h14V10M10 21v-6h4v6"/>',
  flag: '<path d="M5 21V4M5 4h12l-2 4 2 4H5"/>', server: '<rect x="3" y="4" width="18" height="7" rx="2"/><rect x="3" y="13" width="18" height="7" rx="2"/><path d="M7 7.5h.01M7 16.5h.01"/>',
  cog: '<circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 00-.1-1.3l2-1.5-2-3.4-2.3 1a7 7 0 00-2.2-1.3L14 3h-4l-.4 2.5a7 7 0 00-2.2 1.3l-2.3-1-2 3.4 2 1.5A7 7 0 005 12c0 .4 0 .9.1 1.3l-2 1.5 2 3.4 2.3-1a7 7 0 002.2 1.3L10 21h4l.4-2.5a7 7 0 002.2-1.3l2.3 1 2-3.4-2-1.5c.1-.4.1-.9.1-1.3z"/>',
  bag: '<path d="M6 7h12l1 13H5zM9 7a3 3 0 016 0"/>', phone: '<path d="M5 3h4l2 5-2.5 1.5a11 11 0 006 6L16 13l5 2v4a2 2 0 01-2 2A16 16 0 013 5a2 2 0 012-2z"/>',
  briefcase: '<rect x="3" y="7" width="18" height="13" rx="2"/><path d="M9 7V5a2 2 0 012-2h2a2 2 0 012 2v2M3 13h18"/>', shield: '<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/>',
  smile: '<circle cx="12" cy="12" r="9"/><path d="M8 14s1.5 2 4 2 4-2 4-2M9 9h.01M15 9h.01"/>', music: '<path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>',
  cash: '<rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="2.5"/>', bank: '<path d="M3 10l9-6 9 6M5 10v8M9 10v8M15 10v8M19 10v8M3 20h18"/>',
  skull: '<path d="M12 3a8 8 0 00-5 14v3h10v-3a8 8 0 00-5-14zM9.5 12h.01M14.5 12h.01"/>', star: '<path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z"/>',
  chart: '<path d="M4 20V8M10 20V4M16 20v-9M22 20H2"/>', info: '<circle cx="12" cy="12" r="9"/><path d="M12 8h.01M11 12h1v5h1"/>',
  wallet: '<path d="M3 7a2 2 0 012-2h13v4M3 7v11a2 2 0 002 2h15V9H5a2 2 0 01-2-2zM16 14.5h.01"/>', coins: '<ellipse cx="12" cy="6" rx="7" ry="3"/><path d="M5 6v6c0 1.7 3.1 3 7 3s7-1.3 7-3V6M5 12v6c0 1.7 3.1 3 7 3s7-1.3 7-3v-6"/>', grid: '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>',
  male: '<circle cx="10" cy="14" r="5"/><path d="M14 10l6-6M15 4h5v5"/>', female: '<circle cx="12" cy="9" r="5"/><path d="M12 14v8M9 19h6"/>'
};
const ic = n => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${ICON[n] || ICON.home}</svg>`;
const BASE_TABS = [['home', 'Accueil', 'home'], ['bills', 'Vos factures', 'doc'], ['veh', 'Vos véhicules', 'car'], ['props', 'Vos propriétés', 'house'], ['act', 'Activités', 'flag'], ['srv', 'Serveur', 'server'], ['set', 'Paramètres', 'cog'], ['shop', 'Boutique', 'bag']];
let S = null, tab = 'home';
const tabsFor = () => BASE_TABS.filter(t => t[0] !== 'props' || S.data.props != null);
const logoUrl = () => { const l = String((window.PICKAX_SERVER && window.PICKAX_SERVER.logo) || 'logo.png'); return /^(https?:)?\/\//i.test(l) || /^(data|nui):/i.test(l) ? l : 'https://cfx-nui-pickax_theme/logo/' + l.replace(/^\/+/, ''); };
const fmtUp = s => { const m = Math.floor(s / 60); return m >= 60 ? Math.floor(m / 60) + ' h ' + (m % 60) + ' min' : m + ' min'; };
const fmtPlay = s => { s = s || 0; const d = Math.floor(s / 86400), hh = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60); return (d ? d + ' j ' : '') + hh + ' h ' + String(m).padStart(2, '0') + ' min'; };
const wallet = (icon, label, val) => h('div.wal', null, h('div.ic', { html: ic(icon) }), h('span', null, label), h('b', null, val));

const views = {
  home() {
    const d = S.data, j = d.job || {};
    const left = h('div.col', null,
      h('div.who', null, h('div', null, h('h2', null, d.name || 'Citoyen'), h('div.chips', null, h('span.chip', null, j.label || 'Sans emploi'), j.grade ? h('span.chip', null, j.grade) : null, d.group && d.group !== 'user' ? h('span.chip', null, d.group) : null)),
        h('div.sex', { html: ic(d.sex === 'f' ? 'female' : 'male') })),
      h('div.kvs', null,
        h('div.kv', null, h('div.r', null, h('span', null, 'ID unique'), h('b', null, d.uid || '—')), h('div.r', null, h('span', null, 'ID temporaire'), h('b', null, d.id))),
        h('div.sep'),
        h('div.kv', null, h('div.r', null, h('span', null, 'Nationalité'), h('b', null, d.nationality || '—')), h('div.r', null, h('span', null, 'Salaire'), h('b', null, money(j.salary))))),
      h('div.kvs.two', null, h('div.r', null, h('span', null, 'Heures de jeu'), h('b', null, d.playtime != null ? fmtPlay(d.playtime) : '—')), h('div.r', null, h('span', null, 'Naissance'), h('b', null, d.dob || '—'))),
      h('div.ct.l', null, h('span', { html: ic('chart') }), 'Stats du personnage'),
      h('div.bars', null, (d.stats || []).map(s => h('div.bar', null, h('span.n', null, s.label), h('i', null, h('b', { style: `width:${Math.max(3, s.value)}%` }))))));
    const rows = [wallet('cash', 'Liquide', money(d.money.cash)), wallet('bank', 'Banque', money(d.money.bank))];
    if (d.money.black > 0 || S.showBlack) rows.push(wallet('bag', 'Argent sale', money(d.money.black)));
    rows.push(wallet('coins', 'Points boutique', (d.points || 0).toLocaleString('fr-FR')));
    const mid = h('div.col.card', null, h('div.ct', null, h('span', { html: ic('wallet') }), 'Portefeuille'), rows,
      h('div.ct', { style: 'margin-top:14px' }, h('span', { html: ic('grid') }), 'Accès rapide'),
      S.shortcuts.length ? h('div.short', null, S.shortcuts.map(s => h('button.sbtn', { onclick: () => post('shortcut', { id: s.id }) }, h('span', { html: ic(s.icon) }), s.label))) : h('div.empty', { style: 'padding:20px' }, 'Aucun raccourci.'));
    const right = h('div.col.card', null, h('div.ct', null, h('span', { html: ic('info') }), 'Entreprises actives'),
      h('div.list', null, (d.jobs || []).map(c => h('div.co' + (c.online > 0 ? '.up' : ''), null, h('div.lt', null, (c.label || '?').slice(0, 2).toUpperCase()), h('div', null, h('b', null, c.label), h('small', null, c.online > 0 ? `Disponible · ${c.online} en service` : 'Indisponible')), h('span.dot')))));
    return h('div.cols', null, left, mid, right);
  },
  bills() {
    const b = S.data.bills || [];
    if (!b.length) return h('div.empty', null, 'Aucune facture en attente. Vous êtes à jour !');
    const total = b.reduce((a, x) => a + x.amount, 0);
    return h('div', null, h('div.stats3', null, h('div', null, h('small', null, 'Factures'), h('b', null, b.length)), h('div', null, h('small', null, 'Total à payer'), h('b', null, money(total)))),
      b.map(x => { const row = h('div.row', null, h('div.grow', null, h('b', null, x.label), h('small', null, 'Émetteur : ' + x.sender)), h('span.amt', null, money(x.amount)),
        h('button.btn.pri', { onclick: async () => { const r = await post('payBill', { id: x.id }); if (r === 1) { S.data.bills = S.data.bills.filter(y => y.id !== x.id); draw(); } } }, 'Payer')); return row; }));
  },
  veh() {
    const v = S.data.vehicles;
    if (!v.length) return h('div.empty', null, 'Vous ne possédez aucun véhicule.');
    return h('div', null, v.map(x => h('div.row', null, h('div', { style: 'color:var(--pk-accent);width:22px', html: ic('car') }), h('div.grow', null, h('b', null, x.label || 'Véhicule'), h('small', null, 'Véhicule personnel')), h('span.plate', null, x.plate), h('button.btn', { onclick: () => post('locate', { plate: x.plate }) }, 'Localiser'))));
  },
  props() {
    const p = S.data.props || [];
    if (!p.length) return h('div.empty', null, 'Vous ne possédez aucune propriété.');
    return h('div', null, p.map(x => h('div.row', null, h('div', { style: 'color:var(--pk-accent);width:22px', html: ic('house') }), h('div.grow', null, h('b', null, x.label || 'Propriété'), h('small', null, x.info || '')))));
  },
  act() {
    return h('div', null, S.activities.map((a, i) => h('div.row', null, h('div.grow', null, h('b', null, a.label), h('small', null, a.desc)), a.tag ? h('span.tag', null, a.tag) : null,
      a.gps ? h('button.btn.pri', { onclick: () => post('activity', { index: i + 1, what: 'gps' }) }, 'GPS') : null,
      a.cmd ? h('button.btn', { onclick: () => post('activity', { index: i + 1, what: 'cmd' }) }, 'Ouvrir') : null)));
  },
  srv() {
    const d = S.data, sv = S.server || {};
    return h('div', null,
      h('div.stats3', null, h('div', null, h('small', null, 'En ligne'), h('b', null, `${d.server.online}`, h('span', { style: 'font-size:14px;color:var(--pk-fg3);font-weight:500' }, ` / ${d.server.max}`))), h('div', null, h('small', null, 'Staff'), h('b', null, d.server.staff)), h('div', null, h('small', null, 'Actif depuis'), h('b', { style: 'font-size:20px' }, fmtUp(d.server.uptime)))),
      sv.discord ? h('div.row', null, h('div.grow', null, h('b', null, 'Discord'), h('small', null, sv.discord))) : null,
      h('div.sec', null, 'Règles essentielles'), h('ol.rules', null, (d.rules || []).map(r => h('li', null, r))));
  },
  set() {
    return h('div', null,
      h('div.row', null, h('div.grow', null, h('b', null, 'Masquer / afficher le HUD'), h('small', null, 'Bascule l’affichage de l’interface')), h('button.btn', { onclick: () => post('pref', { key: 'hidehud' }) }, 'Basculer')),
      h('div.row', null, h('div.grow', null, h('b', null, 'Raccourci du menu'), h('small', null, 'À modifier dans Paramètres FiveM › Raccourcis clavier › Menu central du serveur'))));
  },
  shop() {
    const has = S.shortcuts.some(s => s.id === 'boutique');
    return h('div', null, h('div.stats3', null, h('div', null, h('small', null, 'Points boutique'), h('b', null, (S.data.points || 0).toLocaleString('fr-FR')))),
      has ? h('button.btn.pri', { onclick: () => post('shortcut', { id: 'boutique' }) }, 'Ouvrir la boutique') : h('div.pk-muted', null, 'La boutique n’est pas disponible.'));
  },
};

function draw() {
  const root = $('#hub'); if (!S) return; root.innerHTML = '';
  const sv = S.server || {}, tabs = tabsFor(); if (!tabs.some(t => t[0] === tab)) tab = 'home';
  root.append(h('div.shell', null,
    h('div.head', null,
      h('div.logo', null, h('img', { src: logoUrl(), alt: '', onerror: (e) => { const f = h('div.lg', null, (sv.short || 'PK').slice(0, 2).toUpperCase()); e.target.replaceWith(f); } })),
      h('div.tabs', null, tabs.map(t => h('button.tab' + (tab === t[0] ? '.on' : ''), { onclick: () => { tab = t[0]; draw(); } }, h('span', { html: ic(t[2]) }), t[1]))),
      h('button.x', { onclick: () => post('close') }, '✕')),
    h('div.body', null, views[tab]())));
}

window.addEventListener('message', e => {
  const m = e.data || {};
  if (m.action === 'open') { S = m; if (m.accent) { const r = document.documentElement.style; r.setProperty('--pk-accent', m.accent); r.setProperty('--pk-accent-rgb', [1, 3, 5].map(i => parseInt(m.accent.slice(i, i + 2), 16)).join(',')); } tab = 'home'; $('#hub').classList.remove('hidden'); draw(); }
  else if (m.action === 'close') $('#hub').classList.add('hidden');
});
document.addEventListener('keydown', e => { if ((e.key === 'Escape' || e.key === 'F1') && !$('#hub').classList.contains('hidden')) post('close'); });
