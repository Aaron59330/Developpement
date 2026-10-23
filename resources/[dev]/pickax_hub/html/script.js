const $ = (s, r = document) => r.querySelector(s);
const h = (tag, a, ...kids) => { const [t, ...cl] = tag.split('.'); const e = document.createElement(t); if (cl.length) e.className = cl.join(' '); for (const k in (a || {})) { if (a[k] == null || a[k] === false) continue; if (k === 'html') e.innerHTML = a[k]; else if (k.startsWith('on')) e.addEventListener(k.slice(2), a[k]); else e.setAttribute(k, a[k]); } kids.flat().forEach(c => c != null && c !== false && e.append(c.nodeType ? c : document.createTextNode(c))); return e; };
const post = (n, d) => (typeof GetParentResourceName === 'function' ? fetch(`https://${GetParentResourceName()}/${n}`, { method: 'POST', body: JSON.stringify(d || {}) }).then(r => r.json()).catch(() => ({})) : Promise.resolve({}));
const money = n => '$' + Math.round(n || 0).toLocaleString('fr-FR');
const P = {
  user: '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-7 8-7s8 3 8 7"/>', id: '<rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="9" cy="11" r="2"/><path d="M6 16c.5-1.5 1.7-2 3-2s2.5.5 3 2M15 10h3M15 13h3"/>',
  car: '<path d="M5 17h14M3 13l2-6h14l2 6v4H3zM7 17v2M17 17v2"/><circle cx="7.5" cy="13.5" r="1"/><circle cx="16.5" cy="13.5" r="1"/>', cog: '<circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 00-.1-1.3l2-1.5-2-3.4-2.3 1a7 7 0 00-2.2-1.3L14 3h-4l-.4 2.5a7 7 0 00-2.2 1.3l-2.3-1-2 3.4 2 1.5A7 7 0 005 12c0 .4 0 .9.1 1.3l-2 1.5 2 3.4 2.3-1a7 7 0 002.2 1.3L10 21h4l.4-2.5a7 7 0 002.2-1.3l2.3 1 2-3.4-2-1.5c.1-.4.1-.9.1-1.3z"/>',
  key: '<circle cx="8" cy="15" r="4"/><path d="M11 12l9-9M16 7l3 3M14 9l2 2"/>', term: '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M7 9l3 3-3 3M13 15h4"/>', link: '<path d="M10 14a4 4 0 005.7 0l3-3a4 4 0 00-5.7-5.7l-1 1M14 10a4 4 0 00-5.7 0l-3 3A4 4 0 0011 18.7l1-1"/>',
  cash: '<rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="2.5"/>', bank: '<path d="M3 10l9-6 9 6M5 10v8M9 10v8M15 10v8M19 10v8M3 20h18"/>', skull: '<path d="M12 3a8 8 0 00-5 14v3h10v-3a8 8 0 00-5-14zM9.5 12h.01M14.5 12h.01"/>',
  doc: '<path d="M6 3h9l4 4v14H6zM14 3v5h5M9 13h7M9 17h7"/>', palette: '<path d="M12 3a9 9 0 100 18c1.5 0 2-1 1.5-2.2-.5-1.3.3-2.3 1.6-2.3H17a4 4 0 004-4c0-5-4-9.5-9-9.5z"/><circle cx="7.5" cy="11" r="1"/><circle cx="10" cy="7" r="1"/><circle cx="15" cy="7.5" r="1"/>',
  monitor: '<rect x="3" y="4" width="18" height="12" rx="2"/><path d="M8 20h8M12 16v4"/>', bolt: '<path d="M13 2L4 14h7l-1 8 9-12h-7z"/>', gamepad: '<rect x="2" y="7" width="20" height="11" rx="5"/><path d="M7 12h4M9 10v4M15.5 11h.01M18 13h.01"/>',
  video: '<rect x="3" y="6" width="13" height="12" rx="2"/><path d="M16 10l5-3v10l-5-3z"/>', music: '<path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>', discord: '<path d="M7 7c3-1 7-1 10 0l2 9c-2 1.5-4 2-7 2s-5-.5-7-2zM9.5 12h.01M14.5 12h.01"/>', bag: '<path d="M6 7h12l1 13H5zM9 7a3 3 0 016 0"/>',
  briefcase: '<rect x="3" y="7" width="18" height="13" rx="2"/><path d="M9 7V5a2 2 0 012-2h2a2 2 0 012 2v2M3 13h18"/>',
  check: '<circle cx="12" cy="12" r="9"/><path d="M8 12.5l3 3 5-6"/>',
  home: '<path d="M3 11l9-8 9 8v10a1 1 0 01-1 1h-5v-7H9v7H4a1 1 0 01-1-1z"/>'
};
const ic = n => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${P[n] || P.home}</svg>`;
const logoUrl = () => { const l = String((window.PICKAX_SERVER && window.PICKAX_SERVER.logo) || 'logo.png'); return /^(https?:)?\/\//i.test(l) || /^(data|nui):/i.test(l) ? l : 'https://cfx-nui-pickax_theme/logo/' + l.replace(/^\/+/, ''); };
const initials = n => (n || '?').split(' ').map(x => x[0]).slice(0, 2).join('').toUpperCase();

let S = null, tab = 'info', sub = 'menu';
const TABS = [['info', 'Informations', 'user'], ['docs', 'Documents', 'id'], ['veh', 'Véhicule', 'car'], ['prefs', 'Préférences', 'cog'], ['keys', 'Touches', 'key'], ['cmds', 'Commandes', 'term'], ['links', 'Liens', 'link']];

async function act(name, payload, redraw = true) {
  const patch = await post('act', Object.assign({ name }, payload || {}));
  if (patch && typeof patch === 'object') { Object.assign(S.data, patch); }
  if (redraw) draw();
}
const sw = (on, fn) => h('button.sw' + (on ? '.on' : ''), { onclick: fn });
const seg = (list, cur, fn) => h('div.pill', null, list.map(x => h('button.pb' + (String(x[0]) === String(cur) ? '.on' : ''), { onclick: () => fn(x[0]) }, x[1])));
const setRow = (title, desc, ctrl) => h('div.set', null, h('div.t', null, h('b', null, title), desc ? h('small', null, desc) : null), ctrl);
const hasNum = (list, v) => list.find(x => x[0] === v) ? v : list[0][0];

const views = {
  info() {
    const d = S.data, m = d.money, jobs = d.jobs || [], bills = d.bills || [];
    const total = m.cash + m.bank + (d.showDirty ? m.black : 0), dueTotal = bills.reduce((s, x) => s + x.amount, 0);
    const seg = (v, c) => total > 0 && v > 0 ? h('i', { style: `width:${(v / total) * 100}%;background:${c}` }) : null;
    const cell = (icon, label, val, c) => h('div', { style: `--c:${c || 'var(--ac)'}` }, h('small', { html: ic(icon) + label }), h('b', null, money(val)));
    const hero = h('div.card.herocard', null,
      h('div.hero', { style: 'margin:0' }, h('div.av', null, initials(d.name)), h('div', null, h('h2', null, d.name), h('div.chips', null, h('span.chip.ac', null, d.job.label), d.job.grade ? h('span.chip', null, d.job.grade) : null, h('span.chip', null, 'ID ' + d.id)))),
      h('div.worth', null, h('small', null, 'Patrimoine total'), h('b', null, money(total)), h('div.wbar', null, seg(m.cash, '#34d058'), seg(m.bank, 'var(--ac)'), d.showDirty ? seg(m.black, '#ff4d4d') : null)));
    const left = h('div.card', { style: 'display:flex;flex-direction:column;min-height:0' },
      h('div.h', null, h('span', { html: ic('cash') }), 'Portefeuille'),
      h('div.wal', null, cell('cash', 'Liquide', m.cash, '#34d058'), cell('bank', 'Banque', m.bank, 'var(--ac)'), d.showDirty ? cell('skull', 'Argent sale', m.black, '#ff4d4d') : null),
      h('div.h', { style: 'margin-top:20px' }, h('span', { html: ic('briefcase') }), `Entreprises · ${jobs.filter(c => c.online > 0).length} disponibles`),
      jobs.length ? h('div.jobs.scroll', null, jobs.map(c => h('div.co' + (c.online > 0 ? '.up' : ''), null, h('div.lt', null, (c.label || '?').slice(0, 2).toUpperCase()), h('div', null, h('b', null, c.label), h('small', null, c.online > 0 ? `Disponible · ${c.online} en service` : 'Indisponible')), h('span.dot')))) : h('div.empty', { style: 'padding:20px' }, 'Aucune entreprise.'));
    const right = h('div.card', { style: 'display:flex;flex-direction:column;min-height:0' },
      h('div.h', null, h('span', { html: ic('doc') }), `Factures (${bills.length})`, bills.length ? h('span', { style: 'margin-left:auto;color:var(--ac);letter-spacing:0;font-size:13px' }, money(dueTotal) + ' à payer') : null),
      bills.length ? h('div.scroll', { style: 'overflow:auto;min-height:0;flex:1;padding-right:6px' }, bills.map(b => h('div.bill', null, h('div', null, h('b', null, b.label), h('small', null, 'Facture n°' + b.id)), h('span.amt', null, money(b.amount)), h('button.btn.pri.sm', { onclick: () => act('payBill', { id: b.id }) }, 'Payer'))))
        : h('div.ok', null, h('span', { html: ic('check') }), h('b', null, 'Tout est à jour'), h('small', null, 'Aucune facture en attente.')));
    return h('div.info', null, hero, h('div.mid', null, left, right));
  },
  docs() {
    const d = S.data;
    const mk = (kind, title, desc, color, label) => h('div.card.doc', null,
      h('div.idc', { style: `--c:${color}` }, h('div.ph', { html: ic('user') }), h('div.ln', null, h('small', null, label), h('b', null, d.name), h('small', null, 'ID ' + d.id)), h('div.stripe')),
      h('h3', null, title), h('p', null, desc),
      h('div.b', null, h('button.btn.pri', { onclick: () => act('doc', { kind, mode: 'show' }, false) }, 'Montrer'), h('button.btn', { onclick: () => act('doc', { kind, mode: 'look' }, false) }, 'Regarder')));
    return h('div.grid2', null, mk('id', 'Carte d\u2019identité', 'Montrez-la au joueur le plus proche (moins de 3 m) ou regardez-la.', 'var(--ac)', 'CARTE D\u2019IDENTITÉ'), mk('driver', 'Permis de conduire', 'Présentez votre permis lors d\u2019un contrôle.', '#34d058', 'PERMIS DE CONDUIRE'), mk('weapon', 'Port d\u2019armes', 'Présentez votre permis de port d\u2019armes.', '#ff6b4a', 'PORT D\u2019ARMES'));
  },
  veh() {
    const v = S.data.vehicle;
    if (!v || !v.inVehicle) return h('div.card.bigempty', null, h('span', { html: ic('car') }), h('b', null, 'Aucun véhicule'), h('small', null, 'Montez dans un véhicule pour accéder aux portes, au moteur, au limitateur et à CarPlay.'));
    const kv = h('div.kv', null, h('div', null, h('small', null, 'Véhicule'), h('b', null, v.name)), h('div', null, h('small', null, 'Plaque'), h('b', null, v.plate)), h('div', null, h('small', null, 'État du moteur'), h('b', null, v.engine + '%')));
    const car = h('div', { style: 'margin-bottom:18px' }, h('button.btn.pri', { onclick: () => act('carplay', {}, false) }, 'Ouvrir CarPlay'));
    if (!v.driver) return h('div', null, kv, car, h('div.card', null, h('div.empty', null, 'Les actions sont réservées au conducteur.')));
    const b = (label, what, extra) => h('button.btn', { onclick: () => act('vehicle', Object.assign({ what }, extra || {})) }, label);
    const four = ['Avant gauche', 'Avant droite', 'Arrière gauche', 'Arrière droite'];
    return h('div', null, kv, car,
      h('div.card', null, h('div.h', null, 'Actions'), h('div.acts', null, b(v.engineOn ? 'Éteindre le moteur' : 'Allumer le moteur', 'engine'), b('Capot', 'hood'), b('Coffre', 'trunk'), b('Fermer toutes les portes', 'closeall')),
        setRow('Fenêtres', 'Ouvrir / fermer', h('div.pill', null, four.map((l, i) => h('button.pb', { onclick: () => act('vehicle', { what: 'window', index: i }) }, l)))),
        setRow('Portes', 'Ouvrir / fermer', h('div.pill', null, four.map((l, i) => h('button.pb', { onclick: () => act('vehicle', { what: 'door', index: i }) }, l)))),
        setRow('Limitateur de vitesse', 'Bloque la vitesse maximale', h('div.pill', null, (S.data.limiter || []).map(k => h('button.pb', { onclick: () => act('vehicle', { what: 'limit', value: k }) }, k + ' km/h')), h('button.pb', { onclick: () => act('vehicle', { what: 'limit', value: 0 }) }, 'Désactiver')))));
  },
  prefs() {
    const p = S.data.prefs, L = S.data.lists, ui = p.ui || {}, hud = p.hud || {};
    const NAV = [['menu', 'Type de menu', 'cog'], ['look', 'Apparence des menus', 'palette'], ['hud', 'Affichage du HUD', 'monitor'], ['perf', 'Performances (FPS)', 'bolt'], ['game', 'Jeu', 'gamepad'], ['rec', 'Rockstar Editor', 'video']];
    const nav = h('div.side', null, NAV.map(n => h('button.sn' + (sub === n[0] ? '.on' : ''), { onclick: () => { sub = n[0]; draw(); } }, h('span', { html: ic(n[2]) }), n[1])));
    const panes = {
      menu() {
        const mode = S.data.mode || 'new';
        const opt = (id, t, d) => h('button.mode' + (mode === id ? '.on' : ''), { onclick: () => act('mode', { value: id }) }, h('b', null, t), h('small', null, d));
        return h('div', null, h('div.modes', null, opt('new', 'Nouveau menu', 'Interface moderne (celle-ci)'), opt('classic', 'Ancien menu', 'Menu RageUI d\u2019origine (touche F5)')),
          h('div', { style: 'color:#8d8d99;font-size:12px;padding-top:12px' }, 'Votre choix est mémorisé. Vous pouvez revenir ici depuis l\u2019ancien menu (bouton « Passer au nouveau menu »).'));
      },
      look() {
        if (!p.hasUi) return h('div.empty', null, 'Module d’interface indisponible (pickax_ui).');
        const U = (k, v) => act('pref', { key: k, value: v });
        const colorRow = c => setRow(c.label, null, h('div.sw2', null, (c.def ? [h('button.pb' + (!ui[c.key] ? '.on' : ''), { onclick: () => U(c.key, '') }, 'Défaut')] : []),
          c.presets.map(x => h('button.sw3' + (ui[c.key] === x[0] ? '.on' : ''), { title: x[1], style: `background:${x[0]}`, onclick: () => U(c.key, x[0]) })),
          h('button.pb', { onclick: () => act('prefHex', { key: c.key }, false) }, 'Personnalisé')));
        return h('div', null,
          setRow('Afficher la bannière', 'En haut des menus', sw(ui.banner, () => U('banner', !ui.banner))),
          setRow('Style', 'Design de tous les menus', seg(L.styles, ui.style, v => U('style', v))),
          setRow('Taille', 'Taille de tous les menus', seg(L.sizes, ui.size, v => U('size', v))),
          setRow('Sons des menus', 'Toutes les interfaces', sw(ui.sound, () => U('sound', !ui.sound))),
          setRow('Volume des sons', null, seg([10, 20, 30, 40, 50, 60, 70, 80, 90, 100].map(x => [x, x + '%']), Math.round((ui.volume || 60) / 10) * 10, v => U('volume', v))),
          L.colors.map(colorRow),
          setRow('Bords des boutons', null, seg(L.btn, hasNum(L.btn, ui.btnRadius), v => U('btnRadius', v))),
          setRow('Bords des notifications', null, seg(L.notify, hasNum(L.notify, p.notifyRadius), v => act('notifyRadius', { value: v }))),
          setRow('Bords du menu', null, seg(L.card, hasNum(L.card, ui.cardRadius), v => U('cardRadius', v))),
          h('div', { style: 'padding-top:16px' }, h('button.btn', { onclick: () => act('prefReset') }, 'Réinitialiser l’apparence')));
      },
      hud() {
        if (!p.hasHud) return h('div.empty', null, 'Module HUD indisponible (pickax_hud2).');
        const H = (k) => act('hud', { key: k, value: !hud[k] });
        return h('div', null,
          setRow('Afficher le HUD', 'Tout le HUD en haut à droite', sw(hud.hud, () => H('hud'))),
          setRow('Carte serveur', 'Nom du serveur, votre ID, joueurs', sw(hud.server, () => H('server'))),
          setRow('Carte métier', 'Métier, grade et statut', sw(hud.job, () => H('job'))),
          setRow('Carte argent', 'Liquide, argent sale et banque', sw(hud.money, () => H('money'))),
          p.hasCompass ? setRow('Boussole', 'Cap, rue et quartier', sw(p.compass, () => act('compass', { value: !p.compass }))) : null,
          setRow('Taille du HUD', null, seg(L.hudScale, hasNum(L.hudScale, hud.scale), v => act('hud', { key: 'scale', value: v }))),
          setRow('Bords du HUD', null, seg(L.hudRadius, hasNum(L.hudRadius, hud.radius), v => act('hud', { key: 'radius', value: v }))),
          h('div', { style: 'padding-top:16px' }, h('button.btn', { onclick: () => act('hudReset') }, 'Réinitialiser le HUD')));
      },
      perf() {
        const pf = p.perf; if (!pf) return h('div.empty', null, 'Module de performances indisponible.');
        return h('div', null,
          setRow('Mode', (pf.presets.find(x => x.id === pf.preset) || {}).desc, seg(pf.presets.map(x => [x.id, x.name]), pf.preset, v => act('perf', { key: 'preset', value: v }))),
          setRow('Compteur de FPS', 'Affiché en haut à droite de l’écran', sw(pf.fps, () => act('perf', { key: 'fps', value: !pf.fps }))));
      },
      game() {
        const g = p.game, G = k => act('game', { key: k, value: !g[k] });
        return h('div', null, setRow('Désactiver les coups de crosse', null, sw(g.cross, () => G('cross'))), setRow('Désactiver le radar', null, sw(g.radar, () => G('radar'))), setRow('Désactiver l’HUD du jeu', null, sw(g.hud, () => G('hud'))));
      },
      rec() {
        return h('div', null, setRow('Enregistrer un clip', 'Lance l’enregistrement Rockstar Editor', h('button.btn.pri', { onclick: () => act('editor', { what: 'start' }, false) }, 'Lancer')),
          setRow('Arrêter et sauvegarder', 'Termine l’enregistrement en cours', h('button.btn', { onclick: () => act('editor', { what: 'stop' }, false) }, 'Arrêter')));
      },
    };
    return h('div.split', null, nav, h('div.card.scroll', { style: 'overflow:auto' }, panes[sub]()));
  },
  keys() {
    const k = S.data.keys || [];
    return h('div.card', null, h('div.h', null, h('span', { html: ic('key') }), 'Touches du serveur'), h('div.rows.two', null, k.map(x => h('div.r', null, h('span', null, x[0]), h('span.kbd', null, String(x[1] || '').toUpperCase())))));
  },
  cmds() {
    const c = S.data.commands || [];
    return h('div.card', null, h('div.h', null, h('span', { html: ic('term') }), 'Commandes du serveur'), h('div.rows.two', null, c.map(x => h('div.r', null, h('span', null, x[1]), h('span.kbd', null, '/' + x[0])))));
  },
  links() {
    const d = S.data.links;
    return h('div.links', null,
      d.discord ? h('button.card.link', { onclick: () => act('link', { which: 'discord' }, false) }, h('span', { style: 'color:var(--ac)', html: ic('discord').replace('<svg', '<svg width="30" height="30"') }), h('b', null, 'Serveur Discord'), h('small', null, 'Ouvre le lien dans votre navigateur')) : null,
      d.shop ? h('button.card.link', { onclick: () => act('link', { which: 'shop' }, false) }, h('span', { style: 'color:var(--ac)', html: ic('bag').replace('<svg', '<svg width="30" height="30"') }), h('b', null, 'Boutique du serveur'), h('small', null, 'Ouvre la boutique dans votre navigateur')) : null);
  },
};

function draw() {
  const root = $('#hub'); if (!S) return; root.innerHTML = '';
  const sv = S.server || {};
  const scroll = $('.body', root) ? $('.body', root).scrollTop : 0;
  root.append(h('div.shell', null,
    h('div.head', null, h('div.logo', null, h('img', { src: logoUrl(), alt: '', onerror: e => { e.target.replaceWith(h('div.lg', null, ((sv.short || 'PK') + '').slice(0, 2).toUpperCase())); } })),
      h('div.tabs', null, TABS.map(t => h('button.tab' + (tab === t[0] ? '.on' : ''), { onclick: () => { tab = t[0]; draw(); } }, h('span', { html: ic(t[2]) }), t[1]))),
      h('button.x', { onclick: () => post('close') }, '✕')),
    h('div.body', null, views[tab]())));
  const b = $('.body', root); if (b) b.scrollTop = scroll;
}

window.addEventListener('message', e => {
  const m = e.data || {};
  if (m.action === 'open') {
    S = m; tab = 'info'; sub = 'menu'; $('#hub').classList.remove('hidden');
    if (m.accent) { const r = document.documentElement.style; r.setProperty('--pk-accent', m.accent); r.setProperty('--pk-accent-rgb', [1, 3, 5].map(i => parseInt(m.accent.slice(i, i + 2), 16)).join(',')); }
    const hex = (getComputedStyle(document.documentElement).getPropertyValue('--pk-accent') || '#0a84ff').trim();
    const rgb = /^#[0-9a-f]{6}$/i.test(hex) ? [1, 3, 5].map(i => parseInt(hex.slice(i, i + 2), 16)) : [10, 132, 255];
    document.documentElement.style.setProperty('--onac', (0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]) > 150 ? '#12081a' : '#ffffff');
    draw();
    clearInterval(window.__jobsTimer); window.__jobsTimer = setInterval(() => { if (tab === 'info' && !$('#hub').classList.contains('hidden')) act('jobs'); }, 10000);
  } else if (m.action === 'close') { $('#hub').classList.add('hidden'); clearInterval(window.__jobsTimer); }
});
document.addEventListener('keydown', e => { if ((e.key === 'Escape' || e.key === 'F5') && !$('#hub').classList.contains('hidden')) post('close'); });
