const $ = (s, r = document) => r.querySelector(s);
const h = (tag, a, ...kids) => { const [t, ...cl] = tag.split('.'); const e = document.createElement(t); if (cl.length) e.className = cl.join(' '); for (const k in (a || {})) { if (a[k] == null) continue; if (k === 'html') e.innerHTML = a[k]; else if (k.startsWith('on')) e.addEventListener(k.slice(2), a[k]); else e.setAttribute(k, a[k]); } kids.flat().forEach(c => c != null && e.append(c.nodeType ? c : document.createTextNode(c))); return e; };
const post = (n, d) => (typeof GetParentResourceName === 'function' ? fetch(`https://${GetParentResourceName()}/${n}`, { method: 'POST', body: JSON.stringify(d || {}) }).catch(() => 0) : Promise.resolve());
const money = n => '$' + Math.round(n || 0).toLocaleString('fr-FR');
const ICON = {
  home: '<path d="M3 11l9-8 9 8v10a1 1 0 01-1 1h-5v-7H9v7H4a1 1 0 01-1-1z"/>', briefcase: '<rect x="3" y="7" width="18" height="13" rx="2"/><path d="M9 7V5a2 2 0 012-2h2a2 2 0 012 2v2M3 13h18"/>',
  car: '<path d="M5 17h14M3 13l2-6h14l2 6v4H3zM7 17v2M17 17v2"/><circle cx="7.5" cy="13.5" r="1"/><circle cx="16.5" cy="13.5" r="1"/>', flag: '<path d="M5 21V4M5 4h12l-2 4 2 4H5"/>',
  server: '<rect x="3" y="4" width="18" height="7" rx="2"/><rect x="3" y="13" width="18" height="7" rx="2"/><path d="M7 7.5h.01M7 16.5h.01"/>', cog: '<circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 00-.1-1.3l2-1.5-2-3.4-2.3 1a7 7 0 00-2.2-1.3L14 3h-4l-.4 2.5a7 7 0 00-2.2 1.3l-2.3-1-2 3.4 2 1.5A7 7 0 005 12c0 .4 0 .9.1 1.3l-2 1.5 2 3.4 2.3-1a7 7 0 002.2 1.3L10 21h4l.4-2.5a7 7 0 002.2-1.3l2.3 1 2-3.4-2-1.5c.1-.4.1-.9.1-1.3z"/>',
  phone: '<path d="M5 3h4l2 5-2.5 1.5a11 11 0 006 6L16 13l5 2v4a2 2 0 01-2 2A16 16 0 013 5a2 2 0 012-2z"/>', shield: '<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/>',
  smile: '<circle cx="12" cy="12" r="9"/><path d="M8 14s1.5 2 4 2 4-2 4-2M9 9h.01M15 9h.01"/>', music: '<path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>',
  bag: '<path d="M6 7h12l1 13H5zM9 7a3 3 0 016 0"/>', pin: '<path d="M12 21s7-6.2 7-12a7 7 0 10-14 0c0 5.8 7 12 7 12z"/><circle cx="12" cy="9" r="2.5"/>', play: '<path d="M7 4l13 8-13 8z"/>'
};
const ic = n => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${ICON[n] || ICON.home}</svg>`;
const TABS = [['home', 'Accueil', 'home'], ['job', 'Métier', 'briefcase'], ['veh', 'Véhicules', 'car'], ['act', 'Activités', 'flag'], ['srv', 'Serveur', 'server'], ['set', 'Réglages', 'cog']];
let S = null, tab = 'home';

const fmtUp = s => { const m = Math.floor(s / 60); return m >= 60 ? Math.floor(m / 60) + ' h ' + (m % 60) + ' min' : m + ' min'; };

const views = {
  home() {
    const d = S.data, first = (d.name || '').split(' ')[0];
    const bank = d.accounts.find(a => a.name === 'bank'), cash = d.accounts.find(a => a.name === 'money');
    return h('div', null,
      h('div.stats', null,
        h('div.pk-card.stat', null, h('small', null, 'Banque'), h('b', null, money(bank && bank.money))),
        h('div.pk-card.stat', null, h('small', null, 'Espèces'), h('b', null, money(cash && cash.money))),
        h('div.pk-card.stat', null, h('small', null, 'Joueurs en ligne'), h('b', null, `${d.server.online}`, h('span', { style: 'font-size:14px;color:var(--pk-fg3);font-weight:500' }, ` / ${d.server.max}`)))),
      h('div.sec', null, 'Accès rapide'),
      S.shortcuts.length ? h('div.tiles', null, S.shortcuts.map(s => h('button.tile', { onclick: () => post('shortcut', { id: s.id }) }, h('div.ic', { html: ic(s.icon) }), h('b', null, s.label), h('small', null, s.desc)))) : h('div.empty', null, 'Aucun raccourci disponible.'));
  },
  job() {
    const j = S.data.job, hasJob = j && j.name && j.name !== 'unemployed';
    return h('div', null,
      h('div.kv', null,
        h('div.pk-card', null, h('div.pk-eyebrow', null, 'Métier'), h('div.big', { style: 'margin-top:8px' }, (j && j.label) || 'Sans emploi'), h('div.pk-muted', { style: 'font-size:13px;margin-top:4px' }, hasJob ? (j.grade || '') : 'Rendez-vous au pôle emploi')),
        h('div.pk-card', null, h('div.pk-eyebrow', null, 'Salaire'), h('div.big', { style: 'margin-top:8px' }, money(j && j.salary)), h('div.pk-muted', { style: 'font-size:13px;margin-top:4px' }, 'Versé à chaque paie'))),
      S.shortcuts.some(s => s.id === 'job') ? h('button.pk-btn.pri', { onclick: () => post('shortcut', { id: 'job' }) }, 'Ouvrir le menu métier') : h('div.pk-muted', null, 'Le menu métier n’est pas disponible.'));
  },
  veh() {
    const v = S.data.vehicles;
    if (!v.length) return h('div.empty', null, 'Vous ne possédez aucun véhicule.');
    return h('div', null, v.map(x => h('div.row', null, h('div.ic', { style: 'color:var(--pk-accent);width:22px', html: ic('car') }), h('div.grow', null, h('b', null, x.label || 'Véhicule'), h('small', null, 'Véhicule personnel')), h('span.plate', null, x.plate), h('button.pk-btn', { onclick: () => post('locate', { plate: x.plate }) }, 'Localiser'))));
  },
  act() {
    return h('div', null, S.activities.map((a, i) => h('div.row', null, h('div.grow', null, h('b', null, a.label), h('small', null, a.desc)), a.tag ? h('span.pk-tag', null, a.tag) : null,
      a.gps ? h('button.pk-btn.pri', { onclick: () => post('activity', { index: i + 1, what: 'gps' }) }, 'GPS') : null,
      a.cmd ? h('button.pk-btn', { onclick: () => post('activity', { index: i + 1, what: 'cmd' }) }, 'Ouvrir') : null)));
  },
  srv() {
    const d = S.data, sv = S.server || {};
    return h('div', null,
      h('div.stats', null, h('div.pk-card.stat', null, h('small', null, 'En ligne'), h('b', null, d.server.online)), h('div.pk-card.stat', null, h('small', null, 'Staff'), h('b', null, d.server.staff)), h('div.pk-card.stat', null, h('small', null, 'Actif depuis'), h('b', { style: 'font-size:20px' }, fmtUp(d.server.uptime)))),
      sv.discord ? h('div.row', null, h('div.grow', null, h('b', null, 'Discord'), h('small', null, sv.discord))) : null,
      h('div.sec', { style: 'margin-top:20px' }, 'Règles essentielles'), h('ol.rules', null, (d.rules || []).map(r => h('li', null, r))));
  },
  set() {
    return h('div', null,
      h('div.row', null, h('div.grow', null, h('b', null, 'Masquer / afficher le HUD'), h('small', null, 'Bascule l’affichage de l’interface')), h('button.pk-btn', { onclick: () => post('pref', { key: 'hidehud' }) }, 'Basculer')),
      h('div.row', null, h('div.grow', null, h('b', null, 'Raccourci du menu'), h('small', null, 'À modifier dans Paramètres FiveM › Raccourcis clavier › Menu central du serveur'))));
  },
};

function draw() {
  const root = $('#hub'); if (!S) return; root.innerHTML = '';
  const d = S.data, sv = S.server || {};
  const title = TABS.find(t => t[0] === tab)[1];
  const heading = tab === 'home' ? h('div', null, h('div.pk-eyebrow', null, sv.tagline || 'Bienvenue'), h('div.pk-h1', { style: 'margin-top:8px' }, `Bonjour, ${(d.name || '').split(' ')[0]}`),
    h('div.chips', null, h('span.pk-chip', null, (d.job && d.job.label) || 'Sans emploi'), h('span.pk-chip', null, `ID ${d.id}`), d.group && d.group !== 'user' ? h('span.pk-chip', null, d.group) : null))
    : h('div', null, h('div.pk-eyebrow', null, sv.short || 'Menu'), h('div.pk-h1', { style: 'margin-top:8px' }, title));
  root.append(h('div.shell.pk-panel', null,
    h('div.rail', null,
      h('div.brand', null, h('div.lg', null, (sv.short || 'PK').slice(0, 2).toUpperCase()), h('div', null, h('b', null, sv.name || 'Serveur'), h('small', null, 'Menu central'))),
      TABS.map(t => h('button.nav' + (tab === t[0] ? '.on' : ''), { onclick: () => { tab = t[0]; draw(); } }, h('span', { html: ic(t[2]) }), t[1])),
      h('div.sp'), h('div.hint', null, 'Ouvrir / fermer : ', h('kbd', null, 'F1'))),
    h('div.main', null, h('div.top', null, heading, h('button.x', { onclick: () => post('close') }, '✕')), views[tab]())));
}

window.addEventListener('message', e => {
  const m = e.data || {};
  if (m.action === 'open') { S = m; tab = 'home'; $('#hub').classList.remove('hidden'); draw(); }
  else if (m.action === 'close') $('#hub').classList.add('hidden');
});
document.addEventListener('keydown', e => { if ((e.key === 'Escape' || e.key === 'F1') && !$('#hub').classList.contains('hidden')) post('close'); });
