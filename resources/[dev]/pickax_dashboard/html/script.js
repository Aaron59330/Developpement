'use strict';
const $r = document.getElementById('root');
const inGame = typeof GetParentResourceName === 'function';
const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const post = (n, b) => { if (!inGame) return Promise.resolve({}); try { return fetch(`https://${GetParentResourceName()}/${n}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(b || {}) }).then(r => r.json()).catch(() => ({})); } catch (e) { return Promise.resolve({}); } };
const n = v => Number(v || 0).toLocaleString('fr-FR').replace(/ /g, ' ');

const P = {
  award: 'M12 15a6 6 0 1 0 0-12 6 6 0 0 0 0 12zM8.5 14l-1.5 7 5-3 5 3-1.5-7', wrench: 'M14.7 6.3a4 4 0 0 0-5.4 5.4L3 18l3 3 6.3-6.3a4 4 0 0 0 5.4-5.4l-3 3-2-2z',
  file: 'M7 3h7l5 5v13H7zM14 3v5h5M10 13h6M10 17h6', car: 'M4 14l2-6h12l2 6v5h-3v-2H7v2H4zM4 14h16M7.5 14.5h.01M16.5 14.5h.01', building: 'M5 21V4h9v17M14 9h5v12M8 8h3M8 12h3M8 16h3',
  paw: 'M12 20c-3 0-5-1.6-5-3.5S9 13 12 13s5 1.6 5 3.5S15 20 12 20zM5.5 11a1.5 2 0 1 0 0-4 1.5 2 0 0 0 0 4zM18.5 11a1.5 2 0 1 0 0-4 1.5 2 0 0 0 0 4zM9 8a1.5 2.2 0 1 0 0-4.4A1.5 2.2 0 0 0 9 8zM15 8a1.5 2.2 0 1 0 0-4.4A1.5 2.2 0 0 0 15 8z',
  bag: 'M5 7h14l-1 13H6zM9 7a3 3 0 0 1 6 0M9 11a3 3 0 0 0 6 0', gear: 'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z',
  x: 'M18 6L6 18M6 6l12 12', back: 'M19 12H5M12 19l-7-7 7-7', chev: 'M9 6l6 6-6 6', chevd: 'M6 9l6 6 6-6', star: 'M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z',
  trophy: 'M8 21h8M12 17v4M7 4h10v6a5 5 0 0 1-10 0zM17 5h3v2a3 3 0 0 1-3 3M7 5H4v2a3 3 0 0 0 3 3', gemi: 'M6 4h12l4 6-10 11L2 10zM2 10h20M9 4l-2 6 5 11 5-11-2-6',
  bell: 'M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9M13.7 21a2 2 0 0 1-3.4 0',
  pin: 'M12 21s7-6 7-11a7 7 0 0 0-14 0c0 5 7 11 7 11zM12 12a2 2 0 1 0 0-4 2 2 0 0 0 0 4z', search: 'M21 21l-4.3-4.3M17 10.5a6.5 6.5 0 1 1-13 0 6.5 6.5 0 0 1 13 0z', refresh: 'M21 12a9 9 0 1 1-3-6.7L21 8M21 3v5h-5',
  vol: 'M11 5L6 9H3v6h3l5 4zM15.5 8.5a5 5 0 0 1 0 7M18.5 5.5a9 9 0 0 1 0 13', eye: 'M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z',
  map: 'M3 6l6-2 6 2 6-2v14l-6 2-6-2-6 2zM9 4v14M15 6v14', target: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 16a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM12 12h.01', crosshair: 'M12 3v4M12 17v4M3 12h4M17 12h4M12 12h.01',
  chat: 'M4 5h16v11H9l-5 4z', clock: 'M12 7v5l3 2M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z', check: 'M5 12l5 5 9-10', lock: 'M5 11h14v10H5zM8 11V7a4 4 0 0 1 8 0v4', gift: 'M3 8h18v4H3zM5 12v9h14v-9M12 8v13M12 8a3 3 0 1 1 3-3c0 1.7-1.5 3-3 3zM12 8a3 3 0 1 0-3-3c0 1.7 1.5 3 3 3z',
  grid: 'M4 4h6v6H4zM14 4h6v6h-6zM14 14h6v6h-6zM4 14h6v6H4z', layers: 'M12 3l9 5-9 5-9-5zM3 13l9 5 9-5', ext: 'M14 4h6v6M20 4l-9 9M18 14v6H4V6h6', box: 'M12 3l9 5v8l-9 5-9-5V8zM3 8l9 5 9-5M12 13v8',
  fish: 'M3 12c3-5 9-6 13-3l5-2v10l-5-2c-4 3-10 2-13-3zM15 11h.01', pick: 'M14 4l6 6M3 21l9-9M10 5c4-2 9-1 11 1', axe: 'M14 10L3 21M14 4l6 6-3 3-6-6z', cube: 'M12 3l9 5v8l-9 5-9-5V8zM3 8l9 5 9-5M12 13v8', tri: 'M4 5h16l-8 14z',
  history: 'M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5M12 7v5l3 2', ban: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM5.6 5.6l12.8 12.8', book: 'M5 4h11a3 3 0 0 1 3 3v13H8a3 3 0 0 1-3-3zM5 17a3 3 0 0 1 3-3h11', dollar: 'M12 3v18M16 7.5c-.5-1.5-2-2.3-4-2.3-2.2 0-4 1-4 3s1.8 2.6 4 3 4 1 4 3-1.8 3-4 3c-2 0-3.5-.8-4-2.3',
  cartd: 'M3 4h3l2 12h11l2-8H7', plus: 'M12 5v14M5 12h14',
  phone: 'M7 3h10a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1zM11 18h2', game: 'M6 9h12a4 4 0 0 1 4 4v2a3 3 0 0 1-5 2l-1-1H8l-1 1a3 3 0 0 1-5-2v-2a4 4 0 0 1 4-4zM8 11v4M6 13h4',
  chart: 'M3 20h18M6 16V9M11 16V5M16 16v-6M21 16V8', gavel: 'M14 5l5 5M11 8l5 5M4 20l7-7M9 3l6 6-3 3-6-6z', dice: 'M5 4h14v16H5zM9 8h.01M15 8h.01M12 12h.01M9 16h.01M15 16h.01', tool: 'M14.7 6.3a4 4 0 0 0-5.4 5.4L3 18l3 3 6.3-6.3a4 4 0 0 0 5.4-5.4l-3 3-2-2z',
  heart: 'M12 20s-7-4.5-9-9a5 5 0 0 1 9-3 5 5 0 0 1 9 3c-2 4.5-9 9-9 9z', help: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.6.3-1 .8-1 1.5M12 17h.01', key: 'M14 10a4 4 0 1 0-3.5 4L21 14v-3h-3v-2zM7 10h.01',
  compass: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM15.5 8.5l-2 5-5 2 2-5z', users: 'M16 20v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 10a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM22 20v-2a4 4 0 0 0-3-3.9M16 2.1a4 4 0 0 1 0 7.8', list: 'M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01'
};
const ic = (nm, extra) => `<svg class="i ${extra || ''}" viewBox="0 0 24 24"><path d="${P[nm] || P.grid}"/></svg>`;
const gem = () => `<span class="gem">${ic('gemi')}</span>`;

const NAV = [['xp', 'Niveau', 'award', 'Votre niveau et vos récompenses'], ['carnet', 'Carnet', 'book', 'Série de connexion, objectifs du jour et de la semaine'], ['work', 'Métier & organisation', 'wrench', 'Votre métier, votre organisation et leurs actions'],
  ['bills', 'Factures', 'file', 'Vos factures en attente'], ['vehicles', 'Véhicules', 'car', 'Vos véhicules et leur état'], ['services', 'Services', 'grid', 'Tous les services du serveur'], ['shop', 'Boutique', 'bag', 'Découvrez nos articles disponibles à l’achat'], ['settings', 'Paramètres', 'gear', 'Personnalisez votre expérience de jeu']];

// ───────── données de démonstration (navigateur uniquement) ─────────
const SETTINGS = {
  prefs: [['Affichage', [['map', 'Minimap agrandie', 'Agrandit la minimap (environ 30 %).', 't', 'bigmap'], ['refresh', 'Réinitialiser mes réglages', 'Remet tous ces réglages à leur valeur d’origine.', 'rf']]],
    ['Réglages généraux', [['target', 'Activer la boussole directionnelle', 'Active ou désactive la boussole en haut de l’écran. Elle indique votre orientation en degrés et les points cardinaux.', 't', 'compass'], ['crosshair', 'Masquer les armes sur le corps', 'Masque l’affichage des armes sur votre personnage. Les autres joueurs ne verront plus vos armes attachées à votre corps.', 't', 'hidecarry']]],
    ['Son', [['vol', 'Couper les sirènes des autres véhicules', 'Rend silencieuses les sirènes des véhicules autour de vous (les vôtres restent actives).', 't', 'mutesiren'], ['vol', 'Couper les klaxons des autres véhicules', 'Désactive les klaxons des véhicules autour de vous.', 't', 'mutehorn'], ['vol', 'Radio des véhicules coupée', 'Éteint automatiquement la radio quand vous montez dans un véhicule.', 't', 'noradio']]]]
};
const TABS = [['daily', 'Daily Store', 'layers'], ['vehicle', 'Véhicule', 'car'], ['bundles', 'Bundles', 'grid'], ['weapons', 'Armes', 'crosshair'], ['items', 'Consommables', 'pin'], ['sub', 'S’abonner', 'clock', true]];
const DEMO = {
  lang: 'Français', name: 'Maly Pablo', charId: 55945, accountId: 60269, playtime: '2j 9h',
  bills: { count: 2, total: 1250, items: [{ label: 'Amende : excès de vitesse', amount: 750 }, { label: 'Réparation véhicule', amount: 500 }] },
  vehicles: { count: 2, out: 1, stored: 1, items: [{ name: 'Sanchez', sub: 'Plaque ABC 123', state: 'Rangé' }, { name: 'Sultan RS', sub: 'Plaque XYZ 987', state: 'Sorti' }] },
  xp: { ok: true, level: 7, max: 50, xp: 5120, floor: 4300, nextXp: 6200, playtime: { every: 10, xp: 15 }, daily: 40,
    rewards: [{ level: 5, items: [{ text: '2 500 $' }, { text: 'Lockpick x3' }], got: true, need: 2900 }, { level: 8, items: [{ text: '5 000 $' }], got: false, need: 6200 }, { level: 10, items: [{ text: 'Pack de bienvenue VIP' }, { text: '10 000 $' }], got: false, need: 9400 }],
    actions: [{ label: 'Acheter dans un magasin', txt: 'selon le prix' }, { label: 'Pêcher', txt: '+12 XP' }, { label: 'Livrer une commande', txt: '+30 XP' }] },
  carnet: { ok: true, streak: 5, best: 9, cycleDay: 5, rewards: [200, 300, 400, 500, 800, 1000, 1500], total: 38,
    goals: [{ label: 'Parcourir 5 km à pied', target: 5, progress: 3.2, done: false, reward: 400 }, { label: 'Passer 30 min avec d’autres joueurs', target: 30, progress: 30, done: true, reward: 600 }, { label: 'Vendre 10 objets', target: 10, progress: 4, done: false, reward: 500 }],
    bonus: { amount: 1000, done: false }, week: { label: 'Gagner 50 000 $', target: 50000, progress: 21500, done: false, reward: 4000 },
    community: { label: 'La ville : réaliser 1 000 actions', target: 1000, progress: 640, done: false, mine: 38, reward: 2000 },
    places: [{ label: 'Aéroport', seen: true }, { label: 'Plage de Vespucci', seen: true }, { label: 'Mont Chiliad', seen: false }], left: { day: 41000, week: 300000 } },
  job: { name: 'police', label: 'Police', gradeLabel: 'Sergent', salary: 1800 }, job2: { name: 'ballas', label: 'Ballas', gradeLabel: 'Chef', salary: 0 },
  actions: { job: [{ label: 'Menu du métier', icon: 'list', command: 'jobmenu' }, { label: 'Décorer ma propriété', icon: 'building', command: 'decorer' }], gang: [{ label: 'Menu de l’organisation', icon: 'list', command: 'gangmenu' }, { label: 'Tablette', icon: 'book', command: 'gangtablet' }] },
  services: [{ label: 'Téléphone', desc: 'Messages, appels, annonces, réseaux.', icon: 'phone', command: 'phone' }, { label: 'Mini-jeux', desc: 'Ton profil : niveau, défis, succès, classements.', icon: 'game', command: 'mgprofil' }, { label: 'Bourse', desc: 'Achète et vends des actions.', icon: 'chart', command: 'bourse' }, { label: 'Enchères', desc: 'Véhicules saisis mis aux enchères.', icon: 'gavel', command: 'encheres' }, { label: 'CarPlay', desc: 'Musique et navigation dans ton véhicule.', icon: 'car', command: 'carplay' }, { label: 'Mécanique', desc: 'Diagnostic et réparation du véhicule proche.', icon: 'tool', command: 'meca' }, { label: 'Tutoriel', desc: 'Revois le guide du serveur.', icon: 'help', command: 'tutoriel' }, { label: 'Mes touches', desc: 'Raccourcis clavier du serveur.', icon: 'key', command: 'touches' }],
  shop: { coins: 120, hasBoutique: true, tabs: TABS, items: [{ id: 1, tab: 'bundles', cat: 'BUNDLES', title: 'Pack de bienvenue', desc: 'Un pack de départ pour bien commencer sur le serveur : véhicule, argent et objets utiles.', price: 5500, badges: ['NOUVEAU', 'EDITION LIMITÉE'] }, { id: 2, tab: 'weapons', cat: 'ARMES', title: 'Pistolet Automatique Spectral', desc: 'Plongez dans les ténèbres avec le Pistolet Automatique Spectre, une arme au design unique mêlant une aura bleu spectral, des détails mystérieux et une finition glaciale.', price: 1450, badges: ['NOUVEAU', 'EDITION LIMITÉE'], stats: [['Dégâts', 35], ['Stock', 15]] }] },
  journal: [{ text: 'Votre facture « Réparation véhicule » (500 $) a été ajoutée.', ts: 1735000000, seen: 0 }], sanctions: [{ reason: 'Avertissement : conduite dangereuse', staff_name: 'Staff', ts: 1734000000 }],
  settings: SETTINGS
};
// Valeurs « vides » utilisées en jeu pour tout ce que le serveur ne fournit pas (jamais de données de démonstration en jeu)
const EMPTY = {
  lang: 'Français', name: '—', charId: 0, accountId: 0, playtime: '0h', bills: { count: 0, total: 0, items: [] }, vehicles: { count: 0, out: 0, stored: 0, items: [] },
  xp: null, carnet: null, job: null, job2: null, actions: { job: [], gang: [] }, services: [], shop: { coins: 0, tabs: TABS, items: [], hasBoutique: false }, settings: SETTINGS
};
let D = inGame ? EMPTY : DEMO, S = { page: 'dash', stack: [], shopTab: 'weapons', product: null, tab: {}, hist: 'offline', sets: {}, sel: 0 };
const left = sec => { sec = Math.max(0, Math.floor(sec || 0)); const h = Math.floor(sec / 3600), m = Math.floor(sec % 3600 / 60); return h ? `${h} h ${m} min` : `${m} min`; };

const bar2 = (cur, max, white) => `<div class="bar2 ${white ? 'w' : ''}"><i style="width:${max ? Math.min(100, cur / max * 100) : 0}%"></i></div>`;
const card = (icon, title, body, go, cls) => `<section class="card ${cls || ''} ${go ? 'link' : ''}" ${go ? `data-go="${go}"` : ''}><div class="ch">${ic(icon)}<span class="t">${esc(title)}</span>${go ? ic('chev', 'go') : ''}</div>${body}</section>`;

// ───────── tableau de bord ─────────
const noJob = j => !j || !j.name || /^unemployed/.test(j.name);
function dash() {
  const hl = D.shop.items.find(i => i.tab === 'bundles') || D.shop.items[0] || null;
  const x = D.xp, c = D.carnet, v = D.vehicles, b = D.bills;
  const vi = (v.items && v.items[0]) || null;
  const nextR = x && x.rewards ? x.rewards.find(r => !r.got) : null;
  const goalsDone = c ? c.goals.filter(g => g.done).length : 0;
  return `<section class="prof"><div class="av">${esc((D.name || '??').split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase())}</div>
    <div class="nm"><small>${esc(D.lang || 'Français')}</small><h1 class="ttl">${esc(D.name)}</h1><p>Personnage #${esc(D.charId)}, compte #${esc(D.accountId)}</p></div>
    <div class="st"><div class="stat"><small>Temps de jeu</small><b>${esc(D.playtime)}</b></div><div class="stat"><small>Factures</small><b>${n(b.count)}</b></div><div class="stat"><small>Véhicules</small><b>${n(v.count)}</b></div></div>
    <div class="sq x" data-close>${ic('x')}</div></section>
  <div class="grid">
    <section class="card hl"><div class="ch">${ic('star')}<span class="t">À la une</span><div class="dots"><i></i><i></i><i class="on"></i><i></i><i></i>${ic('chev', 'go')}</div></div>
      <div class="cb">${hl ? `<div class="l"><span class="cat">${esc(hl.cat)}</span><div class="badges">${(hl.badges || []).map((y, i) => `<span class="bd ${i ? 'p' : 'y'}">${esc(y)}</span>`).join('')}</div><h2 class="ttl">${esc(hl.title)}</h2><p class="ds">${esc(hl.desc)}</p>
        <div class="ft"><span class="price">${gem()} ${n(hl.price)}</span><button class="btn" data-open="${hl.id}">Voir l’offre ${ic('chev')}</button></div></div><div class="r"></div>`
        : `<div class="l"><span class="cat">BOUTIQUE</span><h2 class="ttl" style="margin-top:8px">Découvrez la boutique</h2><p class="ds">Packs, véhicules, armes et consommables : retrouve toutes les offres du serveur.</p><div class="ft"><button class="btn" data-go="shop">Ouvrir la boutique ${ic('chev')}</button></div></div><div class="r"></div>`}</div></section>
    ${card('award', 'Niveau', x ? `<div class="cb"><div class="big">Niv. ${n(x.level)}</div><div class="sub">${n(x.xp)} XP${x.nextXp ? ' · prochain niveau à ' + n(x.nextXp) + ' XP' : ' · niveau maximum'}</div>${bar2(x.xp - x.floor, (x.nextXp || x.xp) - x.floor, true).replace('class="bar2', 'style="margin-top:16px" class="bar2')}<div class="box"><small>Prochaine récompense</small><b>${nextR ? 'Niveau ' + nextR.level : 'Toutes obtenues'}</b><div class="row"><span>${nextR ? esc(nextR.items.map(i => i.text).join(' + ')) : ''}</span></div></div></div>` : `<div class="cb"><div class="big">—</div><div class="sub">Niveau indisponible</div></div>`, 'xp')}
    ${card('book', 'Carnet', c ? `<div class="cb"><div class="big">${n(c.streak)}<small>${c.streak > 1 ? 'jours' : 'jour'}</small></div><div class="sub">Série de connexion · record ${n(c.best)}</div><div style="margin-top:auto"><div class="qrow"><div class="a"><span>Objectifs du jour</span><span>${goalsDone} / ${c.goals.length}</span></div>${bar2(goalsDone, c.goals.length, true)}</div>${c.week ? `<div class="qrow"><div class="a"><span>Objectif de la semaine</span><span>${Math.min(100, Math.round(c.week.progress / c.week.target * 100))} %</span></div>${bar2(c.week.progress, c.week.target, true)}</div>` : ''}<div class="qrow"><div class="a"><span>Renouvelés dans</span><span>${left(c.left.day)}</span></div></div></div></div>` : `<div class="cb"><div class="big">—</div><div class="sub">Carnet indisponible</div></div>`, 'carnet')}
    ${card('file', 'Factures', `<div class="cb"><div class="big">${n(b.total)} $</div><div class="sub">${b.count ? n(b.count) + ' facture(s) en attente' : 'Aucune facture en attente'}</div><div class="note">${ic(b.count ? 'file' : 'check')}${b.count ? 'Des factures sont à régler.' : 'Votre compte est à jour.'}</div></div>`, 'bills')}
    ${card('car', 'Véhicules', `<div class="cb veh"><div class="l"><div class="big">${n(v.count)}</div><div class="sub">${n(v.out)} sorti, ${n(v.stored)} rangé</div>${vi ? `<span class="tag" style="align-self:flex-start">${esc(vi.state)}</span><div class="ttl" style="font-size:25px;font-weight:600">${esc(vi.name)}</div><div class="sub">${esc(vi.sub)}</div>` : ''}<div class="bt" data-go="vehicles">${ic('list')}Voir mes véhicules</div></div><div class="im">${ic('car')}</div></div>`, 'vehicles')}
    ${card('wrench', 'Métier', `<div class="cb">${noJob(D.job) ? `<div class="big">Sans emploi</div><div class="sub">Aucun métier pour le moment</div>` : `<div class="big">${esc(D.job.label)}</div><div class="sub">${esc(D.job.gradeLabel)}</div>`}<div class="note">${ic('wrench')}<span>${noJob(D.job) ? 'Rends-toi au pôle emploi pour trouver un métier.' : 'Salaire : ' + n(D.job.salary) + ' $ par paie'}</span></div></div>`, 'work')}
    ${card('users', 'Organisation', `<div class="cb">${noJob(D.job2) ? `<div class="big">Aucune</div><div class="sub">Pas d’organisation</div>` : `<div class="big">${esc(D.job2.label)}</div><div class="sub">${esc(D.job2.gradeLabel)}</div>`}<div class="note">${ic('users')}<span>${noJob(D.job2) ? 'Rejoins une organisation pour accéder à son menu.' : 'Menu et tablette de l’organisation disponibles.'}</span></div></div>`, 'work')}
  </div>
  <section class="svc"><h3>Services</h3><span class="c">${D.services.length}</span>${D.services.map(sv => `<span class="lg ok sv" data-cmd="${esc(sv.command)}" title="${esc(sv.label)}" style="background:#1b1b1d;cursor:pointer">${ic(sv.icon)}</span>`).join('')}
    <div class="rt"><div class="btn2" data-go="shop">${gem()}Boutique</div><div class="btn2" data-go="services">${ic('grid')}Tous les services</div><div class="btn2" style="width:40px;padding:0;justify-content:center" data-go="settings">${ic('gear')}</div></div></section>`;
}

// ───────── bandeau des sous-pages ─────────
function head(cur) {
  const nav = NAV.find(x => x[0] === cur);
  const first = NAV.slice(0, 6), shop = NAV[6], set = NAV[7];
  const btn = x => `<div class="navb ${x[0] === cur ? 'on' : 'sqn'}" data-go="${x[0]}" title="${esc(x[1])}">${ic(x[2])}${x[0] === cur ? esc(x[1]) : ''}</div>`;
  return `<div class="bar"><div class="sq" data-back>${ic('back')}</div><div class="crumb"><h1 class="ttl"><span class="p" style="cursor:pointer" data-go="dash">Tableau de bord</span>${ic('chev', 'chv')}${S.page === 'shop' && S.product ? `<span class="p" data-shoplist style="cursor:pointer">Boutique</span>${ic('chev', 'chv')}${esc(tabLabel(S.shopTab))}` : esc(nav[1])}</h1><p>${esc(nav[3])}</p></div>
    ${NAV.map(btn).join('').replace(/(<div class="navb[^>]*data-go="shop")/, '$1')}${cur === 'shop' ? '' : ''}<div class="sq" data-close>${ic('x')}</div></div>`;
}
const tabLabel = id => ((D.shop.tabs.find(t => t[0] === id) || [])[1]) || '';
function headShop() {
  // même bandeau, avec le solde de coins avant l'engrenage
  const nav = NAV.find(x => x[0] === 'shop');
  const btn = x => `<div class="navb ${x[0] === 'shop' ? 'on' : 'sqn'}" data-go="${x[0]}">${ic(x[2])}${x[0] === 'shop' ? 'Boutique' : ''}</div>`;
  const sub = S.product ? `<span class="p" data-shoplist style="cursor:pointer">Boutique</span>${ic('chev', 'chv')}<span class="p" data-shoplist style="cursor:pointer">${esc(tabLabel(S.shopTab))}</span>` : 'Boutique';
  return `<div class="bar"><div class="sq" data-back>${ic('back')}</div><div class="crumb"><h1 class="ttl"><span class="p" style="cursor:pointer" data-go="dash">Tableau de bord</span>${ic('chev', 'chv')}${S.product ? `<span class="p" style="cursor:pointer" data-shoplist>Boutique</span>${ic('chev', 'chv')}${esc(tabLabel(S.shopTab))}` : 'Boutique'}</h1><p>${esc(nav[3])}</p></div>
    ${NAV.slice(0, 6).map(btn).join('')}${btn(NAV[6])}${btn(NAV[7])}<div class="coins">${gem()}<b>${n(D.shop.coins)}</b><span class="plus" data-act="coins">${ic('plus')}</span></div><div class="sq" data-close>${ic('x')}</div></div>`;
}

// ───────── pages ─────────
function pageXp() {
  const x = D.xp;
  if (!x) return `<div class="cols"><section class="pn" style="flex:1"><div class="ph"><h2>Niveau et récompenses</h2></div><div class="empty" style="flex:1"><div><b>Indisponible</b><p>Le système de niveaux n’est pas actif sur ce serveur.</p></div></div></section></div>`;
  const pct = x.nextXp ? Math.round((x.xp - x.floor) / (x.nextXp - x.floor) * 100) : 100, tab = S.tab.xp || 'rewards';
  const got = (x.rewards || []).filter(r => r.got).length;
  return `<div class="cols"><section class="pn" style="width:400px"><div class="ph"><h2>Progression</h2><small>${pct} % vers le niveau ${x.level + 1}</small></div><div class="pb" style="display:flex;flex-direction:column">
      <div class="box" style="margin:0 0 14px;padding:18px"><small>Niveau actuel</small><div class="big" style="font-size:46px;margin:4px 0">${n(x.level)}<span style="font-size:20px;font-weight:500;color:var(--mu)"> / ${x.max}</span></div><small style="margin:0">${n(x.xp)} XP au total</small></div>
      <div class="qrow"><div class="a"><span>Vers le niveau ${x.level + 1}</span><b>${x.nextXp ? n(x.xp - x.floor) + ' / ' + n(x.nextXp - x.floor) + ' XP' : 'Maximum'}</b></div>${bar2(x.xp - x.floor, (x.nextXp || x.xp) - x.floor, true)}</div>
      <div class="qrow" style="margin-top:12px"><div class="a"><span>Récompenses obtenues</span><b>${got} / ${(x.rewards || []).length}</b></div>${bar2(got, (x.rewards || []).length, true)}</div>
      <div class="sect" style="margin-top:22px">Gagner de l’XP</div><p class="mu" style="font-size:14px;line-height:1.5">${x.playtime ? `+${x.playtime.xp} XP toutes les ${x.playtime.every} min de jeu.<br>` : ''}${x.daily ? `+${x.daily} XP à la première connexion du jour.<br>` : ''}Et en réalisant les actions listées à droite.</p></div></section>
    <section class="pn" style="flex:1"><div class="ph"><h2>Niveau et récompenses</h2></div>
      <div class="tabs">${[['rewards', 'Récompenses', 'gift'], ['actions', 'Gagner de l’XP', 'star']].map(t => `<div class="tab ${tab === t[0] ? 'on' : ''}" data-tab="xp:${t[0]}">${ic(t[2])}${t[1]}</div>`).join('')}</div>
      <div class="pb" style="padding:0"><div class="qgrid">${tab === 'rewards' ? (x.rewards || []).map(r => `<div class="qcard"><div class="qic">${ic(r.got ? 'check' : 'lock')}</div><div class="m"><h4>Niveau ${r.level}</h4><p>${r.got ? 'Récompense obtenue' : n(r.need) + ' XP requis'}</p><div class="rw">${r.items.map(i => `<span>${ic('gift')}${esc(i.text)}</span>`).join('')}</div></div><div class="en" style="top:14px;${r.got ? 'background:var(--green);color:#fff' : ''}">${r.got ? 'Obtenue' : 'Niv. ' + r.level}</div></div>`).join('') : (x.actions || []).map(a => `<div class="qcard" style="min-height:76px"><div class="qic">${ic('star')}</div><div class="m"><h4>${esc(a.label)}</h4><p>${esc(a.txt)}</p></div></div>`).join('')}</div></div></section></div>`;
}
function pageCarnet() {
  const c = D.carnet;
  if (!c) return `<div class="cols"><section class="pn" style="flex:1"><div class="ph"><h2>Carnet</h2></div><div class="empty" style="flex:1"><div><b>Indisponible</b><p>Le carnet n’est pas actif sur ce serveur.</p></div></div></section></div>`;
  const tab = S.tab.carnet || 'day', done = c.goals.filter(g => g.done).length;
  const goal = g => `<div class="qcard"><div class="qic">${ic(g.done ? 'check' : 'target')}</div><div class="m"><h4>${esc(g.label)}</h4>${bar2(g.progress, g.target, true).replace('class="bar2', 'style="margin:8px 96px 0 0" class="bar2')}<div class="rw"><span>$ ${n(g.reward)} $</span></div></div><div class="pg">${n(Math.floor(g.progress))} / ${n(g.target)}</div><div class="en" style="${g.done ? 'background:var(--green);color:#fff' : ''}">${g.done ? 'Terminé' : 'En cours'}</div></div>`;
  let body;
  if (tab === 'day') body = c.goals.map(goal).join('') + (c.bonus ? `<div class="qcard"><div class="qic">${ic('gift')}</div><div class="m"><h4>Bonus : tous les objectifs du jour</h4><p>Terminez les ${c.goals.length} objectifs pour le débloquer.</p><div class="rw"><span>$ ${n(c.bonus.amount)} $</span></div></div><div class="en" style="top:14px;${c.bonus.done ? 'background:var(--green);color:#fff' : ''}">${c.bonus.done ? 'Obtenu' : 'À débloquer'}</div></div>` : '');
  else if (tab === 'week') body = (c.week ? goal(c.week) : '') + (c.community ? `<div class="qcard"><div class="qic">${ic('users')}</div><div class="m"><h4>Défi de la ville</h4><p>${esc(c.community.label)} — votre contribution : ${n(c.community.mine)}</p>${bar2(c.community.progress, c.community.target, true).replace('class="bar2', 'style="margin:8px 96px 0 0" class="bar2')}<div class="rw"><span>$ ${n(c.community.reward)} $</span></div></div><div class="pg">${n(c.community.progress)} / ${n(c.community.target)}</div><div class="en" style="${c.community.done ? 'background:var(--green);color:#fff' : ''}">${c.community.done ? 'Réussi' : 'En cours'}</div></div>` : '');
  else body = (c.places || []).map(p => `<div class="qcard" style="min-height:76px"><div class="qic">${ic(p.seen ? 'check' : 'pin')}</div><div class="m"><h4>${esc(p.label)}</h4><p>${p.seen ? 'Déjà visité' : 'À découvrir'}</p></div></div>`).join('');
  return `<div class="cols"><section class="pn" style="width:400px"><div class="ph"><h2>Série</h2><small>${n(c.total)} jours au total</small></div><div class="pb" style="display:flex;flex-direction:column">
      <div class="box" style="margin:0 0 14px;padding:18px"><small>Série de connexion</small><div class="big" style="font-size:46px;margin:4px 0">${n(c.streak)}<span style="font-size:20px;font-weight:500;color:var(--mu)"> ${c.streak > 1 ? 'jours' : 'jour'}</span></div><small style="margin:0">Record : ${n(c.best)} jours</small></div>
      <div class="qrow"><div class="a"><span>Objectifs du jour</span><b>${done} / ${c.goals.length}</b></div>${bar2(done, c.goals.length, true)}</div>
      <div class="sect" style="margin-top:22px">Récompenses de la série</div><div style="display:grid;grid-template-columns:repeat(7,1fr);gap:4px">${(c.rewards || []).map((r, i) => `<div style="background:${i + 1 === c.cycleDay ? 'var(--green)' : '#161617'};padding:8px 2px;text-align:center;font-size:12px;font-weight:700"><span class="mu2" style="display:block;font-size:10px">J${i + 1}</span>${n(r)}</div>`).join('')}</div>
      <div style="margin-top:auto"><div class="a" style="display:flex;justify-content:space-between;align-items:center;font-weight:700;font-size:14px;margin-bottom:8px"><span>Aujourd’hui</span><span class="mu" style="display:flex;gap:8px;align-items:center;font-size:13px">${ic('clock')}Renouvelés dans ${left(c.left.day)}</span></div></div></div></section>
    <section class="pn" style="flex:1"><div class="ph"><h2>Carnet</h2></div>
      <div class="tabs">${[['day', 'Aujourd’hui', 'target'], ['week', 'Semaine', 'trophy'], ['places', 'Lieux', 'pin']].map(t => `<div class="tab ${tab === t[0] ? 'on' : ''}" data-tab="carnet:${t[0]}">${ic(t[2])}${t[1]}</div>`).join('')}</div>
      <div class="pb" style="padding:0"><div class="qgrid">${body}</div></div></section></div>`;
}
function pageWork() {
  const rows = [['wrench', 'Métier', D.job, 'job'], ['users', 'Organisation', D.job2, 'gang']];
  const sel = S.sel === 1 ? 1 : 0, cur = rows[sel], j = cur[2], acts = (D.actions || {})[cur[3]] || [];
  return `<div class="cols"><section class="pn" style="width:520px"><div class="ph"><h2>Vos postes</h2></div><div class="pb">${rows.map((r, i) => `<div class="jrow ${i === sel ? 'on' : ''}" data-sel="${i}"><div class="qic">${ic(r[0])}</div><div class="m"><div class="t1"><b>${r[1]}</b><span>${noJob(r[2]) ? 'Aucun' : esc(r[2].label)}</span></div><div class="t2"><span>${noJob(r[2]) ? '—' : esc(r[2].gradeLabel)}</span><span></span></div></div></div>`).join('')}</div></section>
    <div style="flex:1;display:flex;flex-direction:column;gap:12px;min-width:0"><section class="pn" style="flex:none"><div class="ph"><h2>${noJob(j) ? 'Aucun poste' : esc(j.label)}</h2><small>${cur[1]}</small></div>
      <div class="lvl"><div class="nv"><small>Grade</small><b style="font-size:34px">${noJob(j) ? '—' : esc(j.gradeLabel)}</b></div><div class="nv" style="margin-left:60px"><small>Salaire par paie</small><b style="font-size:34px">${noJob(j) ? '—' : n(j.salary) + ' $'}</b></div></div></section>
      <section class="pn" style="flex:1"><div class="ph"><h2>Actions</h2></div><div class="pb">${acts.length ? acts.map(a => `<div class="pref" style="cursor:pointer" data-cmd="${esc(a.command)}"><div class="qic">${ic(a.icon || 'list')}</div><div class="m"><b>${esc(a.label)}</b></div>${ic('chev', 'mu')}</div>`).join('') : '<div class="empty" style="height:100%"><div><b>Aucune action</b></div></div>'}</div></section></div></div>`;
}
function pageServices() {
  const L = D.services;
  return `<div class="cols"><section class="pn" style="flex:1"><div class="ph"><h2>Services</h2><small>${L.length} disponibles</small></div><div class="pb"><div class="sgrid">${L.map(s => `<div class="sc" data-cmd="${esc(s.command)}"><div class="qic">${ic(s.icon)}</div><div class="m"><b>${esc(s.label)}</b><p>${esc(s.desc)}</p></div><span class="tag" style="margin:0">Ouvrir</span></div>`).join('') || '<div class="empty" style="grid-column:1/-1"><div><b>Aucun service</b></div></div>'}</div></div></section></div>`;
}
function pageBills() {
  const b = D.bills.items || [];
  return `<div class="cols"><section class="pn" style="flex:1"><div class="ph"><h2>Factures</h2><small>${n(D.bills.total)} $ en attente</small></div><div class="pb">${b.length ? b.map(r => `<div class="pref"><div class="qic">${ic('file')}</div><div class="m"><b>${esc(r.label)}</b></div><b style="font-size:17px">${n(r.amount)} $</b></div>`).join('') : '<div class="empty" style="height:100%"><div><b>Aucune facture</b><p>Votre compte est à jour.</p></div></div>'}</div></section></div>`;
}
function pageVehicles() {
  const v = D.vehicles.items || [];
  return `<div class="cols"><section class="pn" style="flex:1"><div class="ph"><h2>Véhicules</h2><small>${n(D.vehicles.out)} sorti, ${n(D.vehicles.stored)} rangé</small></div><div class="pb">${v.length ? v.map(r => `<div class="pref"><div class="qic">${ic('car')}</div><div class="m"><b>${esc(r.name)}</b><p>${esc(r.sub)}</p></div><span class="tag" style="margin:0">${esc(r.state)}</span>${r.state === 'Sorti' ? `<div class="btn2" style="margin-left:10px" data-act="locate" data-plate="${esc(r.plate || '')}">${ic('pin')}Localiser</div>` : ''}</div>`).join('') : '<div class="empty" style="height:100%"><div><b>Aucun véhicule</b><p>Vos véhicules apparaîtront ici.</p></div></div>'}</div></section></div>`;
}
function pageSettings() {
  const st = D.settings;
  const q = (S.pq || '').toLowerCase();
  const prefs = st.prefs.map(([sec, rows]) => ({ sec, rows: rows.filter(r => !q || (r[1] + r[2]).toLowerCase().includes(q)) })).filter(s => s.rows.length);
  const ago = ts => { const d = new Date((ts || 0) * 1000); return d.toLocaleDateString('fr-FR') + ' ' + d.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }); };
  const jr = D.journal || [], sc = D.sanctions || [];
  const list = S.hist === 'offline'
    ? (jr.length ? jr.map(j => `<div class="pref"><div class="qic">${ic(j.seen ? 'file' : 'bell')}</div><div class="m"><b>${esc(j.text)}</b><p>${ago(j.ts)}${j.seen ? '' : ' · nouveau'}</p></div></div>`).join('') : '<div class="empty"><div><b>Journal vide</b><p>Aucun événement ne s’est produit en votre absence.</p></div></div>')
    : (sc.length ? sc.map(j => `<div class="pref"><div class="qic">${ic('ban')}</div><div class="m"><b>${esc(j.reason)}</b><p>${ago(j.ts)} · ${esc(j.staff_name || 'Staff')}</p></div></div>`).join('') : '<div class="empty"><div><b>Aucune sanction</b><p>Votre dossier est vierge.</p></div></div>');
  return `<div class="cols"><section class="pn" style="width:948px"><div class="ph" style="padding-right:0"><h2>Préférences</h2><div class="sch" style="width:300px">${ic('search')}<input id="ps" placeholder="Rechercher un réglage" value="${esc(S.pq || '')}"></div></div><div class="pb">${prefs.map(s => `<div class="sect">${esc(s.sec)}</div>${s.rows.map(r => `<div class="pref ${r[3] === 'rf' ? 'clk' : ''}" ${r[3] === 'rf' ? 'data-act="reset"' : ''}><div class="qic">${ic(r[0])}</div><div class="m"><b>${esc(r[1])}</b><p>${esc(r[2])}</p></div>${r[3] === 'rf' ? ic('refresh', 'mu') : `<div class="tgl ${S.sets[r[4]] ? 'on' : ''}" data-tgl="${esc(r[4])}"><i></i></div>`}</div>`).join('')}`).join('')}</div></section>
    <div style="flex:1;display:flex;flex-direction:column;gap:12px;min-width:0">
      <section class="pn hist" style="flex:1"><div class="ph"><h2>Historique</h2></div><div class="tabs">${[['offline', 'Journal hors ligne', 'file'], ['sanc', 'Sanctions', 'ban']].map(x => `<div class="tab ${S.hist === x[0] ? 'on' : ''}" data-hist="${x[0]}">${ic(x[2])}${x[1]}</div>`).join('')}</div><div class="pb" style="overflow:auto;flex:1">${list}</div></section></div></div>`;
}
function pageShop() {
  const tabs = `<div class="sub-tabs">${D.shop.tabs.map(t => `<div class="stab ${S.shopTab === t[0] ? 'on' : ''}" data-stab="${t[0]}">${ic(t[2])}${esc(t[1])}${t[3] ? ic('ext') : ''}</div>`).join('')}<div class="stab r" data-act="history">${ic('history')}Historique</div><div class="stab r2" data-act="inventory">${ic('box')}Inventaire</div></div>`;
  const items = D.shop.items.filter(i => i.tab === S.shopTab);
  const p = S.product != null ? D.shop.items.find(i => i.id === S.product) : null;
  if (p) return tabs + `<div class="shop"><div class="pimg" style="--img:${imgFor(p)}"><div class="bk" data-shoplist>${ic('back')}</div></div><div class="pinfo"><div class="badges" style="display:flex;gap:6px">${(p.badges || []).map((x, i) => `<span class="bd ${i ? 'p' : 'y'}">${esc(x)}</span>`).join('')}${(p.stats || []).map(s => `<span class="bd n">${ic('crosshair')}${esc(s[0])} <b>${esc(s[1])}</b></span>`).join('')}</div><h2 class="ttl">${esc(p.title)}</h2><p>${esc(p.desc)}</p><div class="pr"><span class="price" style="display:inline-flex;height:44px;font-size:18px">${gem()} ${n(p.price)}</span><div class="buy" data-buy="${p.id}">Acheter</div></div></div></div>`;
  if (!D.shop.items.length) return tabs + `<div class="shop" style="padding:0"><div class="empty" style="flex:1"><div><b>La boutique s’ouvre dans son propre écran</b><p class="mu" style="margin-bottom:16px">Retrouve tous les articles et tes coins dans la boutique du serveur.</p>${D.shop.hasBoutique !== false ? '<div class="btn" data-act="boutique" style="display:inline-flex">Ouvrir la boutique</div>' : ''}</div></div></div>`;
  return tabs + `<div class="shop" style="padding:0;gap:0"><div class="pg4">${items.map(i => `<div class="pc" data-open="${i.id}"><div class="im" style="--img:${imgFor(i)}"></div><div class="tx"><b>${esc(i.title)}</b><div class="pp">${gem()}${n(i.price)}</div></div></div>`).join('') || '<div class="empty" style="grid-column:1/-1"><div><b>Aucun article</b><p class="mu">Cette catégorie est vide pour le moment.</p></div></div>'}</div></div>`;
}
const imgFor = p => p.image ? `url(${p.image}) center/cover` : (p.tab === 'weapons' ? 'linear-gradient(135deg,#0a2d33,#0d7a82 55%,#38d4cf)' : 'linear-gradient(135deg,#2b1a05,#7a3b06 55%,#c4661a)');
// ───────── rendu ─────────
function keys() { return `<div class="keys">${S.page === 'dash' ? '' : '<kbd>Retour arrière</kbd><span>Tableau de bord</span>'}<kbd>Échap</kbd><span style="margin:0">Fermer</span></div>`; }
function fit() { const s = document.querySelector('.stage'); if (s) s.style.transform = `scale(${Math.min(innerWidth / 1920, innerHeight / 1080)})`; }
function draw() {
  let body;
  if (S.page === 'dash') body = dash();
  else {
    const h = S.page === 'shop' ? headShop() : head(S.page);
    body = h + ({ xp: pageXp, carnet: pageCarnet, work: pageWork, services: pageServices, bills: pageBills, vehicles: pageVehicles, settings: pageSettings, shop: pageShop }[S.page] || pageServices)();
  }
  const y = document.querySelector('.pb') ? document.querySelector('.pb').scrollTop : 0;
  $r.innerHTML = `<div class="stage"><div class="win">${body}</div>${keys()}</div>`;
  fit();
  const pb = document.querySelector('.pb'); if (pb && y) pb.scrollTop = y;
}
function go(p) { if (p === S.page) return; S.stack.push(S.page); S.page = p; S.product = null; draw(); }
function back() { if (S.page === 'shop' && S.product != null) { S.product = null; return draw(); } S.page = S.stack.pop() || 'dash'; S.product = null; draw(); }

$r.addEventListener('click', e => {
  const t = e.target.closest('[data-go],[data-back],[data-close],[data-open],[data-buy],[data-stab],[data-shoplist],[data-tab],[data-sel],[data-cmd],[data-hist],[data-tgl],[data-act]'); if (!t) return;
  const d = t.dataset;
  if ('close' in d) return post('close');
  if ('back' in d) return back();
  if ('go' in d) return go(d.go);
  if ('open' in d) { S.stack.push(S.page); S.page = 'shop'; const it = D.shop.items.find(i => i.id == d.open); if (it) S.shopTab = it.tab; S.product = it ? it.id : null; return draw(); }
  if ('shoplist' in d) { S.product = null; return draw(); }
  if ('stab' in d) { S.shopTab = d.stab; S.product = null; return draw(); }
  if ('buy' in d) return post('buy', { id: +d.buy });
  if ('tab' in d) { const [k, v] = d.tab.split(':'); S.tab[k] = v; return draw(); }
  if ('sel' in d) { S.sel = +d.sel; return draw(); }
  if ('cmd' in d) return post('cmd', { command: d.cmd });
  if ('hist' in d) { S.hist = d.hist; return draw(); }
  if ('tgl' in d) { S.sets[d.tgl] = !S.sets[d.tgl]; post('setting', { key: d.tgl, value: S.sets[d.tgl] }); return draw(); }
  if ('act' in d) return post('act', { a: d.act, plate: t.dataset.plate });
});
$r.addEventListener('input', e => {
  const t = e.target;
  if (t.id === 'qs') { S.q = t.value; const p = t.selectionStart; draw(); const i = document.getElementById('qs'); i.focus(); i.setSelectionRange(p, p); }
  else if (t.id === 'ps') { S.pq = t.value; const p = t.selectionStart; draw(); const i = document.getElementById('ps'); i.focus(); i.setSelectionRange(p, p); }
});
addEventListener('keydown', e => { if (!$r.classList.contains('hidden')) { if (e.key === 'Escape') post('close'); if (e.key === 'Backspace' && !/INPUT/.test((e.target || {}).tagName || '')) back(); } });
addEventListener('resize', fit);
addEventListener('message', ev => {
  const m = ev.data || {};
  if (m.a === 'coins') { D.shop.coins = m.coins; draw(); return; }
  if (m.a === 'prefs') { S.sets = m.prefs || {}; draw(); return; }
  if (m.a === 'open') { D = Object.assign({}, EMPTY, m.data || {}); if (!D.shop.tabs) D.shop.tabs = EMPTY.shop.tabs; if (!D.settings) D.settings = EMPTY.settings; S = { page: m.page || 'dash', stack: [], shopTab: (D.shop.tabs[0] || [])[0], product: null, tab: {}, hist: 'offline', sets: (m.data && m.data.prefs) || {}, sel: 0 }; $r.classList.remove('hidden'); draw(); }
  else if (m.a === 'close') $r.classList.add('hidden');
});
if (!inGame) { addEventListener('DOMContentLoaded', () => { $r.classList.remove('hidden'); const q = new URLSearchParams(location.search); if (q.get('page')) S.page = q.get('page'); if (q.get('p')) { S.shopTab = 'weapons'; S.product = 2; } draw(); }); }
