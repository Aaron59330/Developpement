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
  pin: 'M12 21s7-6 7-11a7 7 0 0 0-14 0c0 5 7 11 7 11zM12 12a2 2 0 1 0 0-4 2 2 0 0 0 0 4z', search: 'M21 21l-4.3-4.3M17 10.5a6.5 6.5 0 1 1-13 0 6.5 6.5 0 0 1 13 0z', refresh: 'M21 12a9 9 0 1 1-3-6.7L21 8M21 3v5h-5',
  vol: 'M11 5L6 9H3v6h3l5 4zM15.5 8.5a5 5 0 0 1 0 7M18.5 5.5a9 9 0 0 1 0 13', eye: 'M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z',
  map: 'M3 6l6-2 6 2 6-2v14l-6 2-6-2-6 2zM9 4v14M15 6v14', target: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 16a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM12 12h.01', crosshair: 'M12 3v4M12 17v4M3 12h4M17 12h4M12 12h.01',
  chat: 'M4 5h16v11H9l-5 4z', clock: 'M12 7v5l3 2M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z', check: 'M5 12l5 5 9-10', lock: 'M5 11h14v10H5zM8 11V7a4 4 0 0 1 8 0v4', gift: 'M3 8h18v4H3zM5 12v9h14v-9M12 8v13M12 8a3 3 0 1 1 3-3c0 1.7-1.5 3-3 3zM12 8a3 3 0 1 0-3-3c0 1.7 1.5 3 3 3z',
  grid: 'M4 4h6v6H4zM14 4h6v6h-6zM14 14h6v6h-6zM4 14h6v6H4z', layers: 'M12 3l9 5-9 5-9-5zM3 13l9 5 9-5', ext: 'M14 4h6v6M20 4l-9 9M18 14v6H4V6h6', box: 'M12 3l9 5v8l-9 5-9-5V8zM3 8l9 5 9-5M12 13v8',
  fish: 'M3 12c3-5 9-6 13-3l5-2v10l-5-2c-4 3-10 2-13-3zM15 11h.01', pick: 'M14 4l6 6M3 21l9-9M10 5c4-2 9-1 11 1', axe: 'M14 10L3 21M14 4l6 6-3 3-6-6z', cube: 'M12 3l9 5v8l-9 5-9-5V8zM3 8l9 5 9-5M12 13v8', tri: 'M4 5h16l-8 14z',
  history: 'M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5M12 7v5l3 2', ban: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM5.6 5.6l12.8 12.8', book: 'M5 4h11a3 3 0 0 1 3 3v13H8a3 3 0 0 1-3-3zM5 17a3 3 0 0 1 3-3h11', dollar: 'M12 3v18M16 7.5c-.5-1.5-2-2.3-4-2.3-2.2 0-4 1-4 3s1.8 2.6 4 3 4 1 4 3-1.8 3-4 3c-2 0-3.5-.8-4-2.3',
  cartd: 'M3 4h3l2 12h11l2-8H7', plus: 'M12 5v14M5 12h14'
};
const ic = (nm, extra) => `<svg class="i ${extra || ''}" viewBox="0 0 24 24"><path d="${P[nm] || P.grid}"/></svg>`;
const gem = () => `<span class="gem">${ic('gemi')}</span>`;

const NAV = [['quests', 'Quêtes', 'award', 'Complétez des quêtes pour gagner des récompenses'], ['jobs', 'Métiers d’intérim', 'wrench', 'Votre progression dans les métiers libres'], ['bills', 'Factures', 'file', 'Vos factures en attente et payées'],
  ['vehicles', 'Véhicules', 'car', 'Vos véhicules et leur état'], ['props', 'Propriétés', 'building', 'Vos biens immobiliers'], ['animals', 'Animaux', 'paw', 'Vos compagnons'], ['shop', 'Boutique', 'bag', 'Découvrez nos articles disponibles à l’achat'], ['settings', 'Paramètres', 'gear', 'Personnalisez votre expérience de jeu']];

// ───────── données de démonstration (navigateur) ─────────
const DEMO = {
  lang: 'Français', name: 'Maly Pablo', charId: 55945, accountId: 60269, playtime: '2j 9h', bills: { count: 0, total: 0 }, vehicles: { count: 1, out: 0, stored: 1, items: [{ name: 'Sanchez', sub: 'Sanchez, Mutuelle Mors', state: 'Rangé' }] },
  quests: { claim: 0, renew: '11 h 14 min', featured: [['Prises communes', 0, 20], ['Pêche : Poisson-cocher', 0, 5], ['Pêche : Poisson chirurgien', 0, 20]],
    tabs: { daily: [['fish', 'Prises communes', 'Attrapez 20 poissons communs.', 0, 20, 2000, 'Canne à pêche légendaire'], ['fish', 'Pêche : Poisson-cocher', 'Attrapez 5 poissons-cochers — Lac de Sandy Shores (niv. 1).', 0, 5, 9600, 'Canne à pêche légendaire'], ['fish', 'Pêche : Poisson chirurgien', 'Attrapez 20 poissons chirurgiens — Great Ocean Highway (niv. 20).', 0, 20, 6000, 'Canne à pêche légendaire'], ['fish', 'Pêche : Poisson-clown', 'Attrapez 15 poissons-clowns — Great Ocean Highway (niv. 20).', 0, 15, 7200, 'Canne à pêche légendaire'], ['pick', 'Extraction : Plomb', 'Extrayez 10 minerais de plomb (mineur niv. 20, pioche rare).', 0, 10, 2000, 'Pioche légendaire'], ['pick', 'Extraction : Néphrite', 'Extrayez 6 minerais de néphrite (mineur niv. 40, pioche épique).', 0, 6, 2000, 'Pioche légendaire']], perm: [], groups: [] },
    totals: { daily: [0, 6], perm: [13, 44], groups: [0, 4] }, percent: 24, renewHours: '10 h 41 min' },
  jobs: { level: 15, best: { label: 'Pizzaïolo', level: 10, pct: 49, rank: 125, of: 2413, xp: 1579, next: 1730 },
    list: [['fish', 'Pêcheur', 1, 0, 30, null], ['pick', 'Mineur', 1, 0, 30, null], ['axe', 'Bûcheron', 1, 0, 30, null], ['target', 'Chasseur', 1, 0, 30, null], ['cube', 'Postier', 1, 0, 30, null], ['tri', 'Pizzaïolo', 10, 1579, 1730, 125, 50]],
    board: [['ian salvatore', 72, 56452, 100], ['Franclin Sein', 69, 51820, 92], ['Albo Tequila', 43, 22467, 40], ['jojo kiki', 34, 15036, 27], ['Gaspard Gaspacho', 30, 11543, 20], ['emilo moretti', 28, 10088, 18], ['LosPolos Hermanos', 26, 8844, 16], ['nahil dossantos', 25, 8380, 15], ['Jolan Johnson', 25, 8256, 15]] },
  shop: { coins: 0, tabs: [['daily', 'Daily Store', 'layers'], ['vehicle', 'Véhicule', 'car'], ['bundles', 'Bundles', 'grid'], ['weapons', 'Armes', 'crosshair'], ['items', 'Consommables', 'pin'], ['sub', 'S’abonner', 'clock', true]],
    items: [{ id: 1, tab: 'bundles', cat: 'BUNDLES', title: 'Pack Citrouilles', desc: 'Pack Citrouilles, La nuit d’Halloween débarque à Los Santos, avec un arsenal enflammé et une…', price: 5500, badges: ['NOUVEAU', 'EDITION LIMITÉE'] },
      { id: 2, tab: 'weapons', cat: 'ARMES', title: 'Pistolet Automatique Spectral', desc: 'Plongez dans les ténèbres avec le Pistolet Automatique Spectre, une arme au design unique mêlant une aura bleu spectral, des détails mystérieux et une finition glaciale.', price: 1450, badges: ['NOUVEAU', 'EDITION LIMITÉE'], stats: [['Dégâts', 35], ['Stock', 15]] },
      { id: 3, tab: 'weapons', cat: 'ARMES', title: 'Fusil Fantôme', desc: 'Un fusil d’assaut à l’éclat spectral.', price: 2400, badges: ['NOUVEAU'] }] },
  settings: { prefs: [['Affichage', [['map', 'Personnaliser la minimap', 'Déplacez et redimensionnez la minimap où vous voulez sur l’écran.', 'go'], ['refresh', 'Réinitialiser la minimap', 'Remet la minimap à sa position et sa taille d’origine.', 'rf']]],
      ['Réglages généraux', [['building', 'Statuts d’entreprise', 'Cette option vous permet de masquer les notifications de disponibilité des entreprises, simplifiant ainsi votre interface et concentrant votre attention sur d’autres aspects du jeu.', 0], ['eye', 'Visualisation des véhicules', 'Permet de masquer la visualisation des véhicules dans les garages.', 0], ['car', 'Affichage étendu des véhicules stationnés', 'Affiche les véhicules stationnés à une plus grande distance lorsque cette option est activée.', 0], ['target', 'Activer la boussole directionnelle', 'Active ou désactive la boussole en haut de l’écran. Il indique votre orientation en degrés et les points cardinaux (N, NE, E, SE, S, SO, O, NO), ainsi que la direction et la distance de votre point GPS.', 0], ['crosshair', 'Masquer les armes sur le corps', 'Masque l’affichage des armes équipées sur votre personnage. Les autres joueurs ne verront plus vos armes attachées à votre corps.', 0], ['chat', 'Masquer l’ouverture des boîtes de nuit', 'Masque l’annonce envoyée à tout le serveur quand une boîte de nuit ouvre ses portes au public (son nom, son prix d’entrée et le GPS vers sa porte).', 0]]]],
    sounds: [['Pluie'], ['Vent et orage'], ['Ambiance'], ['Véhicules'], ['Sirènes'], ['Klaxons'], ['Armes et explosions'], ['Voix des passants'], ['Radios environnantes'], ['Bruitages']] },
  services: { have: 8, total: 29, list: [['ok', '#c0392b'], ['ok', '#8e2a2a'], ['ok', '#6c2a4d'], ['ok', '#1c3d6e'], ['ok', '#f2c200'], ['ok', '#2a79c4'], ['ok', '#b5322b'], ['ok', '#2f9e8f'], ['no', '#27394f'], ['no', '#8a8a8a'], ['no', '#a64b6b'], ['no', '#4b4b4b'], ['no', '#2a8ad4'], ['no', '#1c3d6e'], ['no', '#3b3b3b'], ['no', '#a8302f']], more: 13 }
};

// Valeurs « vides » utilisées en jeu pour tout ce que le serveur ne fournit pas (jamais de données de démonstration en jeu)
const EMPTY = {
  lang: 'Français', name: '—', charId: 0, accountId: 0, playtime: '0h', bills: { count: 0, total: 0 }, vehicles: { count: 0, out: 0, stored: 0, items: [] },
  quests: { claim: 0, renew: '—', featured: [], tabs: { daily: [], perm: [], groups: [] }, totals: { daily: [0, 0], perm: [0, 0], groups: [0, 0] }, percent: 0, renewHours: '—' },
  jobs: { level: 0, best: { label: '—', level: 0, pct: 0, rank: 0, of: 0, xp: 0, next: 0 }, list: [], board: [] },
  props: { count: 0 }, animals: { count: 0, max: 5 }, services: { have: 0, total: 0, list: [], more: 0 },
  shop: { coins: 0, tabs: DEMO.shop.tabs, items: [] }, settings: DEMO.settings
};
let D = inGame ? EMPTY : DEMO, S = { page: 'dash', stack: [], tab: 'daily', shopTab: 'weapons', product: null, qtab: 'daily', job: null, hist: 'offline', sets: {} };

const bar2 = (cur, max, white) => `<div class="bar2 ${white ? 'w' : ''}"><i style="width:${max ? Math.min(100, cur / max * 100) : 0}%"></i></div>`;
const card = (icon, title, body, go, cls) => `<section class="card ${cls || ''} ${go ? 'link' : ''}" ${go ? `data-go="${go}"` : ''}><div class="ch">${ic(icon)}<span class="t">${esc(title)}</span>${go ? ic('chev', 'go') : ''}</div>${body}</section>`;

// ───────── tableau de bord ─────────
function dash() {
  const hl = (D.shop.items.find(i => i.tab === 'bundles') || D.shop.items[0]) || null;
  const q = D.quests, j = D.jobs, v = D.vehicles, b = D.bills, sv = D.services;
  const vi = (v.items && v.items[0]) || null;
  return `<section class="prof"><div class="av">${esc((D.name || '??').split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase())}</div>
    <div class="nm"><small>${esc(D.lang || 'Français')}</small><h1 class="ttl">${esc(D.name)}</h1><p>Personnage #${esc(D.charId)}, compte #${esc(D.accountId)}</p></div>
    <div class="st"><div class="stat"><small>Temps de jeu</small><b>${esc(D.playtime)}</b></div><div class="stat"><small>Factures</small><b>${n(b.count)}</b></div><div class="stat"><small>Véhicules</small><b>${n(v.count)}</b></div></div>
    <div class="sq x" data-close>${ic('x')}</div></section>
  <div class="grid">
    <section class="card hl"><div class="ch">${ic('star')}<span class="t">À la une</span><div class="dots"><i></i><i></i><i class="on"></i><i></i><i></i>${ic('chev', 'go')}</div></div>
      <div class="cb">${hl ? `<div class="l"><span class="cat">${esc(hl.cat)}</span><div class="badges">${(hl.badges || []).map((x, i) => `<span class="bd ${i ? 'p' : 'y'}">${esc(x)}</span>`).join('')}</div><h2 class="ttl">${esc(hl.title)}</h2><p class="ds">${esc(hl.desc)}</p>
        <div class="ft"><span class="price">${gem()} ${n(hl.price)}</span><button class="btn" data-open="${hl.id}">Voir l’offre ${ic('chev')}</button></div></div><div class="r"></div>` : '<div class="empty"><p class="mu">Aucune offre pour le moment.</p></div>'}</div></section>
    ${card('trophy', 'Quêtes', `<div class="cb"><div class="big">${n(q.claim)}<small>à réclamer</small></div><div class="sub">Renouvelées dans ${esc(q.renew)}</div><div style="margin-top:auto">${(q.featured || []).map(f => `<div class="qrow"><div class="a"><span>${esc(f[0])}</span><span>${f[1]} / ${f[2]}</span></div>${bar2(f[1], f[2], true)}</div>`).join('')}</div></div>`, 'quests')}
    ${card('wrench', 'Métiers d’intérim', `<div class="cb"><div class="big">Niv. ${n(j.level)}</div><div class="sub">Niveau cumulé de vos métiers</div><div class="box"><small>Meilleur métier</small><b>${esc(j.best.label)}</b><div class="row"><span>Niveau ${j.best.level}</span><span>${j.best.pct} % vers le niveau ${j.best.level + 1}</span></div>${bar2(j.best.pct, 100)}</div></div>`, 'jobs')}
    ${card('file', 'Factures', `<div class="cb"><div class="big">${n(b.total)} $</div><div class="sub">${b.count ? n(b.count) + ' facture(s) en attente' : 'Aucune facture en attente'}</div><div class="note">${ic(b.count ? 'file' : 'check')}${b.count ? 'Des factures sont à régler.' : 'Votre compte est à jour.'}</div></div>`, 'bills')}
    ${card('car', 'Véhicules', `<div class="cb veh"><div class="l"><div class="big">${n(v.count)}</div><div class="sub">${n(v.out)} sorti, ${n(v.stored)} rangé</div>${vi ? `<span class="tag" style="align-self:flex-start">${esc(vi.state)}</span><div class="ttl" style="font-size:25px;font-weight:600">${esc(vi.name)}</div><div class="sub">${esc(vi.sub)}</div>` : ''}<div class="bt" data-act="locate">${ic('pin')}Localiser</div></div><div class="im">${ic('car')}</div></div>`, 'vehicles')}
    ${card('building', 'Propriétés', `<div class="cb"><div class="big">${n((D.props || {}).count || 0)}<small>bien</small></div><div class="sub">Aucun bien</div><div class="note">${ic('building')}<span>Achetez ou louez un bien auprès de Dynasty 8.</span></div></div>`, 'props')}
    ${card('paw', 'Animaux', `<div class="cb"><div class="big">${n((D.animals || {}).count || 0)}<small>sur ${(D.animals || {}).max || 5}</small></div><div class="sub">Aucun compagnon sorti</div><div class="note">${ic('paw')}<span>Adoptez un compagnon à l’animalerie de Sandy Shores.</span></div></div>`, 'animals')}
  </div>
  <section class="svc"><h3>Services officiels</h3><span class="c">${sv.have} / ${sv.total}</span>${sv.list.map(l => `<span class="lg ${l[0]}" style="background:${l[1]}"></span>`).join('')}<span class="c">+${sv.more}</span>
    <div class="rt"><div class="btn2" data-go="shop">${gem()}Boutique</div><div class="btn2 dis">${ic('lock')}Abonnement</div><div class="btn2" style="width:40px;padding:0;justify-content:center" data-go="settings">${ic('gear')}</div></div></section>`;
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
function pageQuests() {
  const q = D.quests, t = q.tabs, list = (t[S.qtab] || []).filter(x => !S.q || x[1].toLowerCase().includes(S.q.toLowerCase()));
  const tot = q.totals;
  return `<div class="cols"><section class="pn" style="width:400px"><div class="ph"><h2>Progression</h2><small>${q.percent} % terminé</small></div><div class="pb" style="display:flex;flex-direction:column">
      <div class="box" style="margin:0 0 14px;padding:18px"><small>À réclamer</small><div class="big" style="font-size:46px;margin:4px 0">${n(q.claim)}</div><small style="margin:0">${q.claim ? 'Des récompenses vous attendent' : 'Rien en attente'}</small></div>
      ${[['Journalières', tot.daily], ['Permanentes', tot.perm], ['Défis groupés', tot.groups]].map(r => `<div class="qrow" style="margin-top:12px"><div class="a"><span>${r[0]}</span><b>${r[1][0]} / ${r[1][1]}</b></div>${bar2(r[1][0], r[1][1], true)}</div>`).join('')}
      <div class="sect" style="margin-top:22px">Prêtes à réclamer</div><p class="mu" style="font-size:14px">Terminez une quête pour en réclamer la récompense ici.</p>
      <div style="margin-top:auto"><div class="a" style="display:flex;justify-content:space-between;align-items:center;font-weight:700;font-size:14px;margin-bottom:8px"><span>Aujourd’hui</span><span class="mu" style="display:flex;gap:8px;align-items:center;font-size:13px">${ic('clock')}Renouvelées dans ${esc(q.renewHours)}</span></div><div style="display:grid;grid-template-columns:repeat(6,1fr);gap:4px">${Array.from({ length: 6 }, (_, i) => `<div class="bar2" style="margin:0;height:6px;background:${i < tot.daily[0] ? 'var(--greenl)' : '#2a2a2c'}"></div>`).join('')}</div></div></div></section>
    <section class="pn" style="flex:1"><div class="ph"><h2>Quêtes</h2><div class="sch">${ic('search')}<input id="qs" placeholder="Rechercher une quête" value="${esc(S.q || '')}"></div></div>
      <div class="tabs">${[['daily', 'Journalières', 'cube'], ['perm', 'Permanentes', 'file'], ['groups', 'Défis groupés', 'trophy']].map(x => `<div class="tab ${S.qtab === x[0] ? 'on' : ''}" data-qtab="${x[0]}">${ic(x[2])}${x[1]}<b>${(t[x[0]] || []).length || tot[x[0]][1]}</b></div>`).join('')}</div>
      <div class="pb" style="padding:0"><div class="qgrid">${list.map(x => `<div class="qcard"><div class="qic">${ic(x[0])}</div><div class="m"><h4>${esc(x[1])}</h4><p>${esc(x[2])}</p>${bar2(x[3], x[4], true).replace('class="bar2', 'style="margin-right:96px" class="bar2')}<div class="rw"><span>$ ${n(x[5])} $</span><span>${ic('gift')}${esc(x[6])}</span></div></div><div class="pg">${x[3]} / ${x[4]}</div><div class="en">En cours</div></div>`).join('') || '<div class="empty" style="grid-column:1/-1"><div><b>Aucune quête</b><p>Rien à afficher dans cette catégorie.</p></div></div>'}</div></div></section></div>`;
}
function pageJobs() {
  const j = D.jobs;
  if (!j.list.length) return `<div class="cols"><section class="pn" style="flex:1"><div class="ph"><h2>Vos métiers</h2></div><div class="empty" style="flex:1"><div><b>Aucun métier</b><p>Votre progression dans les métiers libres apparaîtra ici.</p></div></div></section></div>`;
  const sel = S.job == null ? j.list.length - 1 : S.job, cur = j.list[sel];
  return `<div class="cols"><section class="pn" style="width:520px"><div class="ph"><h2>Vos métiers</h2><small>Niveau cumulé ${j.level}</small></div><div class="pb">${j.list.map((x, i) => `<div class="jrow ${i === sel ? 'on' : ''}" data-job="${i}"><div class="qic">${ic(x[0])}</div><div class="m"><div class="t1"><b>${esc(x[1])}</b><span>${x[5] ? '#' + x[5] : 'Non classé'}</span></div>${bar2(x[3], x[4], true)}<div class="t2"><span>Niveau ${x[2]}</span><span>${n(x[3])} / ${n(x[4])} XP</span></div></div></div>`).join('')}</div></section>
    <div style="flex:1;display:flex;flex-direction:column;gap:12px;min-width:0"><section class="pn" style="flex:none"><div class="ph"><h2>${esc(cur[1])}</h2><small>${cur[5] ? `Rang ${cur[5]} sur ${n(j.best.of)}` : 'Non classé'}</small><div class="rst" style="margin-left:auto;height:32px" data-act="locate">${ic('pin')}Localiser le métier</div></div>
      <div class="lvl"><div class="nv"><small>Niveau</small><b>${cur[2]}</b></div><div class="pr"><div class="a"><span>${cur[6] ?? Math.round(cur[3] / cur[4] * 100)} % vers le niveau ${cur[2] + 1}</span><span>${n(cur[3])} / ${n(cur[4])} XP</span></div>${bar2(cur[3], cur[4], true)}</div></div></section>
      <section class="pn" style="flex:1"><div class="ph"><h2>Classement</h2><small>${n(j.best.of)} classés</small></div><div class="pb">${j.board.map((r, i) => `<div class="rk"><div class="n ${i < 3 ? 'g' : ''}">${i + 1}</div><div class="m"><b>${esc(r[0])}</b>${bar2(r[3], 100, true)}</div><div class="lv">Niv. ${r[1]}</div><div class="xp">${n(r[2])} XP</div></div>`).join('')}</div></section></div></div>`;
}
function pageSettings() {
  const st = D.settings;
  const q = (S.pq || '').toLowerCase();
  const prefs = st.prefs.map(([sec, rows]) => ({ sec, rows: rows.filter(r => !q || (r[1] + r[2]).toLowerCase().includes(q)) })).filter(s => s.rows.length);
  return `<div class="cols"><section class="pn" style="width:948px"><div class="ph" style="padding-right:0"><h2>Préférences</h2><div class="sch" style="width:300px">${ic('search')}<input id="ps" placeholder="Rechercher un réglage" value="${esc(S.pq || '')}"></div></div><div class="pb">${prefs.map(s => `<div class="sect">${esc(s.sec)}</div>${s.rows.map((r, i) => `<div class="pref"><div class="qic">${ic(r[0])}</div><div class="m"><b>${esc(r[1])}</b><p>${esc(r[2])}</p></div>${r[3] === 'go' ? ic('chev', 'mu') : r[3] === 'rf' ? ic('refresh', 'mu') : `<div class="tgl ${S.sets[r[1]] ? 'on' : ''}" data-tgl="${esc(r[1])}"><i></i></div>`}</div>`).join('')}`).join('')}</div></section>
    <div style="flex:1;display:flex;flex-direction:column;gap:12px;min-width:0"><section class="pn" style="flex:none"><div class="ph" style="padding-right:8px"><h2>Son</h2><small>Volume par catégorie</small><div class="rst" data-act="resetvol">${ic('refresh')}Rétablir</div></div><div class="vol">${st.sounds.map((s, i) => `<div class="v"><div class="vt">${ic('vol')}${esc(s[0])}</div><div class="sl"><input type="range" min="0" max="100" value="${S['v' + i] ?? 100}" data-vol="${i}"><span class="pc">${S['v' + i] ?? 100} %</span></div></div>`).join('')}</div></section>
      <section class="pn hist" style="flex:1"><div class="ph"><h2>Historique</h2></div><div class="tabs">${[['offline', 'Journal hors ligne', 'file'], ['sanc', 'Sanctions', 'ban']].map(x => `<div class="tab ${S.hist === x[0] ? 'on' : ''}" data-hist="${x[0]}">${ic(x[2])}${x[1]}</div>`).join('')}</div><div class="empty"><div><b>${S.hist === 'offline' ? 'Journal vide' : 'Aucune sanction'}</b><p>${S.hist === 'offline' ? 'Aucun événement ne s’est produit en votre absence.' : 'Votre dossier est vierge.'}</p></div></div></section></div></div>`;
}
function pageShop() {
  const tabs = `<div class="sub-tabs">${D.shop.tabs.map(t => `<div class="stab ${S.shopTab === t[0] ? 'on' : ''}" data-stab="${t[0]}">${ic(t[2])}${esc(t[1])}${t[3] ? ic('ext') : ''}</div>`).join('')}<div class="stab r" data-act="history">${ic('history')}Historique</div><div class="stab r2" data-act="inventory">${ic('box')}Inventaire</div></div>`;
  const items = D.shop.items.filter(i => i.tab === S.shopTab);
  const p = S.product != null ? D.shop.items.find(i => i.id === S.product) : null;
  if (p) return tabs + `<div class="shop"><div class="pimg" style="--img:${imgFor(p)}"><div class="bk" data-shoplist>${ic('back')}</div></div><div class="pinfo"><div class="badges" style="display:flex;gap:6px">${(p.badges || []).map((x, i) => `<span class="bd ${i ? 'p' : 'y'}">${esc(x)}</span>`).join('')}${(p.stats || []).map(s => `<span class="bd n">${ic('crosshair')}${esc(s[0])} <b>${esc(s[1])}</b></span>`).join('')}</div><h2 class="ttl">${esc(p.title)}</h2><p>${esc(p.desc)}</p><div class="pr"><span class="price" style="display:inline-flex;height:44px;font-size:18px">${gem()} ${n(p.price)}</span><div class="buy" data-buy="${p.id}">Acheter</div></div></div></div>`;
  return tabs + `<div class="shop" style="padding:0;gap:0"><div class="pg4">${items.map(i => `<div class="pc" data-open="${i.id}"><div class="im" style="--img:${imgFor(i)}"></div><div class="tx"><b>${esc(i.title)}</b><div class="pp">${gem()}${n(i.price)}</div></div></div>`).join('') || '<div class="empty" style="grid-column:1/-1"><div><b>Aucun article</b><p class="mu">Cette catégorie est vide pour le moment.</p></div></div>'}</div></div>`;
}
const imgFor = p => p.image ? `url(${p.image}) center/cover` : (p.tab === 'weapons' ? 'linear-gradient(135deg,#0a2d33,#0d7a82 55%,#38d4cf)' : 'linear-gradient(135deg,#2b1a05,#7a3b06 55%,#c4661a)');
function pageList(id) {
  const rows = { bills: [], vehicles: (D.vehicles.items || []).map(v => [v.name, v.sub, v.state]), props: [], animals: [] }[id] || [];
  const nav = NAV.find(x => x[0] === id);
  return `<div class="cols"><section class="pn" style="flex:1"><div class="ph"><h2>${esc(nav[1])}</h2></div><div class="pb">${rows.length ? rows.map(r => `<div class="pref"><div class="qic">${ic(nav[2])}</div><div class="m"><b>${esc(r[0])}</b><p>${esc(r[1])}</p></div><span class="tag" style="margin:0">${esc(r[2])}</span></div>`).join('') : `<div class="empty" style="height:100%"><div><b>Rien à afficher</b><p>${esc(nav[3])}.</p></div></div>`}</div></section></div>`;
}

// ───────── rendu ─────────
function keys() { return `<div class="keys">${S.page === 'dash' ? '' : '<kbd>Retour arrière</kbd><span>Tableau de bord</span>'}<kbd>Échap</kbd><span style="margin:0">Fermer</span></div>`; }
function fit() { const s = document.querySelector('.stage'); if (s) s.style.transform = `scale(${Math.min(innerWidth / 1920, innerHeight / 1080)})`; }
function draw() {
  let body;
  if (S.page === 'dash') body = dash();
  else {
    const h = S.page === 'shop' ? headShop() : head(S.page);
    body = h + (S.page === 'quests' ? pageQuests() : S.page === 'jobs' ? pageJobs() : S.page === 'settings' ? pageSettings() : S.page === 'shop' ? pageShop() : pageList(S.page));
  }
  const y = document.querySelector('.pb') ? document.querySelector('.pb').scrollTop : 0;
  $r.innerHTML = `<div class="stage"><div class="win">${body}</div>${keys()}</div>`;
  fit();
  const pb = document.querySelector('.pb'); if (pb && y) pb.scrollTop = y;
}
function go(p) { if (p === S.page) return; S.stack.push(S.page); S.page = p; S.product = null; draw(); }
function back() { if (S.page === 'shop' && S.product != null) { S.product = null; return draw(); } S.page = S.stack.pop() || 'dash'; S.product = null; draw(); }

$r.addEventListener('click', e => {
  const t = e.target.closest('[data-go],[data-back],[data-close],[data-open],[data-buy],[data-stab],[data-shoplist],[data-qtab],[data-job],[data-hist],[data-tgl],[data-act]'); if (!t) return;
  const d = t.dataset;
  if ('close' in d) return post('close');
  if ('back' in d) return back();
  if ('go' in d) return go(d.go);
  if ('open' in d) { S.stack.push(S.page); S.page = 'shop'; const it = D.shop.items.find(i => i.id == d.open); if (it) S.shopTab = it.tab; S.product = it ? it.id : null; return draw(); }
  if ('shoplist' in d) { S.product = null; return draw(); }
  if ('stab' in d) { S.shopTab = d.stab; S.product = null; return draw(); }
  if ('buy' in d) return post('buy', { id: +d.buy });
  if ('qtab' in d) { S.qtab = d.qtab; return draw(); }
  if ('job' in d) { S.job = +d.job; return draw(); }
  if ('hist' in d) { S.hist = d.hist; return draw(); }
  if ('tgl' in d) { S.sets[d.tgl] = !S.sets[d.tgl]; post('setting', { key: d.tgl, value: S.sets[d.tgl] }); return draw(); }
  if ('act' in d) return post('act', { a: d.act });
});
$r.addEventListener('input', e => {
  const t = e.target;
  if (t.id === 'qs') { S.q = t.value; const p = t.selectionStart; draw(); const i = document.getElementById('qs'); i.focus(); i.setSelectionRange(p, p); }
  else if (t.id === 'ps') { S.pq = t.value; const p = t.selectionStart; draw(); const i = document.getElementById('ps'); i.focus(); i.setSelectionRange(p, p); }
  else if (t.dataset && t.dataset.vol != null) { S['v' + t.dataset.vol] = +t.value; t.parentNode.querySelector('.pc').textContent = t.value + ' %'; post('volume', { i: +t.dataset.vol, v: +t.value }); }
});
addEventListener('keydown', e => { if (!$r.classList.contains('hidden')) { if (e.key === 'Escape') post('close'); if (e.key === 'Backspace' && !/INPUT/.test((e.target || {}).tagName || '')) back(); } });
addEventListener('resize', fit);
addEventListener('message', ev => {
  const m = ev.data || {};
  if (m.a === 'open') { D = Object.assign({}, EMPTY, m.data || {}); if (!D.shop.tabs) D.shop.tabs = EMPTY.shop.tabs; if (!D.settings) D.settings = EMPTY.settings; S = { page: m.page || 'dash', stack: [], tab: 'daily', shopTab: (D.shop.tabs[0] || [])[0], product: null, qtab: 'daily', job: null, hist: 'offline', sets: (m.data && m.data.prefs) || {} }; $r.classList.remove('hidden'); draw(); }
  else if (m.a === 'close') $r.classList.add('hidden');
});
if (!inGame) { addEventListener('DOMContentLoaded', () => { $r.classList.remove('hidden'); const q = new URLSearchParams(location.search); if (q.get('page')) S.page = q.get('page'); if (q.get('p')) { S.shopTab = 'weapons'; S.product = 2; } draw(); }); }
