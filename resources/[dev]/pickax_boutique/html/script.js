'use strict';
const $root = document.getElementById('root'), $modal = document.getElementById('modal'), $toasts = document.getElementById('toasts');
const res = () => (typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_boutique');
const post = (name, body) => fetch(`https://${res()}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) }).then(r => r.json()).catch(() => ({}));
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const fmt = n => Number(n || 0).toLocaleString('fr-FR');

const IC = {
  car: '<path d="M4 15.5V13l2-5.2A2 2 0 0 1 7.9 6.5h8.2A2 2 0 0 1 18 7.8L20 13v2.5"/><path d="M3.5 15.5h17V18a1 1 0 0 1-1 1H18a1 1 0 0 1-1-1v-.5H7V18a1 1 0 0 1-1 1H4.5a1 1 0 0 1-1-1z"/><path d="M6 13h12M7.5 16h.01M16.5 16h.01"/>',
  moto: '<circle cx="5.5" cy="16.5" r="3.2"/><circle cx="18.5" cy="16.5" r="3.2"/><path d="M5.5 16.5L9 9h5l2 3.5M14 9l1.5-2.5H18M9 9l-1.5-2H5"/><path d="M12 16.5l2-4h3"/>',
  plane: '<path d="M2 14l7-2 5-8h2l-2 8 6 1.5a1.5 1.5 0 0 1 0 3L14 18l2 3h-2l-4-3-8 .5z"/>',
  gun: '<path d="M3 8.5h13.5l1.5 2H21v3.5h-5.2l-.9 5H9.5l1-5H5a2 2 0 0 1-2-2z"/><path d="M7 11.5h4"/>',
  box: '<path d="M3 7.5l9-4.5 9 4.5v9l-9 4.5-9-4.5z"/><path d="M3 7.5l9 4.5 9-4.5M12 12v9M7.5 5.2l9 4.5"/>',
  gift: '<rect x="3.5" y="9" width="17" height="11.5" rx="2"/><path d="M12 9v11.5M3.5 13.5h17"/><path d="M12 9C9.5 9 7.2 8 7.2 6A2.2 2.2 0 0 1 11 4.6L12 9zM12 9c2.5 0 4.8-1 4.8-3A2.2 2.2 0 0 0 13 4.6L12 9z"/>',
  brief: '<rect x="3" y="7.5" width="18" height="12.5" rx="2.2"/><path d="M8.5 7.5V5.8A1.8 1.8 0 0 1 10.3 4h3.4a1.8 1.8 0 0 1 1.8 1.8v1.7"/><path d="M3 13h18M11 13h2v2h-2z"/>',
  search: '<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>', x: '<path d="M6 6l12 12M18 6L6 18"/>', arrow: '<path d="M5 12h14M13 6l6 6-6 6"/>',
  bag: '<path d="M6 8h12l1 12H5z"/><path d="M9 8a3 3 0 0 1 6 0"/>', link: '<path d="M10 13a5 5 0 0 0 7.5.5l3-3a5 5 0 0 0-7-7l-1.7 1.7"/><path d="M14 11a5 5 0 0 0-7.5-.5l-3 3a5 5 0 0 0 7 7l1.7-1.7"/>',
  gear: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>',
  cart: '<circle cx="9" cy="20" r="1.4"/><circle cx="18" cy="20" r="1.4"/><path d="M2.5 3.5h3l2.2 11h10.3l2-8H6.5"/>',
  hist: '<path d="M3.5 12a8.5 8.5 0 1 0 2.6-6.1L3.5 8.5"/><path d="M3.5 4v4.5H8M12 7.5V12l3 2"/>',
  tag: '<path d="M3 12.5V4h8.5L21 13.5 13.5 21z"/><circle cx="8" cy="8.5" r="1.3"/>',
  shield: '<path d="M12 3l8 3v6c0 4.5-3.2 8-8 9-4.8-1-8-4.5-8-9V6z"/><path d="M9 12l2 2 4-4"/>',
  trash: '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>', plus: '<path d="M12 5v14M5 12h14"/>', minus: '<path d="M5 12h14"/>',
  users: '<circle cx="9" cy="8" r="3.2"/><path d="M3 20a6 6 0 0 1 12 0M16 5a3.2 3.2 0 0 1 0 6M18 14a6 6 0 0 1 3 6"/>',
  store: '<path d="M4 9l1.5-5h13L20 9"/><path d="M4 9v11h16V9"/><path d="M9 20v-6h6v6"/>',
  _store: '<path d="M4 9l1.5-5h13L20 9"/><path d="M4 9v11h16V9"/><path d="M9 20v-6h6v6"/>',
};
IC.check = '<path d="M5 12.5l4.5 4.5L19 7"/>';
const ic = (n, s) => `<svg class="ic" viewBox="0 0 24 24"${s ? ` style="width:${s}px;height:${s}px"` : ''}>${IC[n] || IC.box}</svg>`;

const CATS = [
  { id: 'vehicle', label: 'Véhicules', sub: 'Voitures et SUV, livrés dans ton garage', icon: 'car', kind: 'Véhicule', color: 'var(--pk-accent,#00a4ff)' },
  { id: 'moto', label: 'Motos', sub: 'Deux-roues, sportives et tout-terrain', icon: 'moto', kind: 'Moto', color: 'var(--pk-accent,#00a4ff)' },
  { id: 'other', label: 'Air & mer', sub: 'Avions, hélicoptères et bateaux', icon: 'plane', kind: 'Véhicule', color: 'var(--pk-accent,#00a4ff)' },
  { id: 'weapon', label: 'Armes', sub: 'Armes permanentes avec munitions', icon: 'gun', kind: 'Arme', color: 'var(--pk-accent,#00a4ff)' },
  { id: 'crate', label: 'Caisses', sub: 'Caisses surprise : véhicules, armes et argent', icon: 'box', kind: 'Caisse', color: 'var(--pk-accent,#00a4ff)' },
  { id: 'pack', label: 'Packs', sub: 'Packs de départ et bonus', icon: 'gift', kind: 'Pack', color: 'var(--pk-accent,#00a4ff)' },
  { id: 'business', label: 'Entreprises', sub: 'Gangs et entreprises clés en main', icon: 'brief', kind: 'Entreprise', color: 'var(--pk-accent,#00a4ff)' },
];
const S = { data: null, view: 'shop', cat: 'vehicle', q: '', points: 0, sort: 'price', cart: [], code: '', pct: 0, promoMsg: '', history: null, overview: null, admin: null, paying: null };
try { S.cart = JSON.parse(localStorage.getItem('pb_cart') || '[]'); } catch (e) { S.cart = []; }
const saveCart = () => { try { localStorage.setItem('pb_cart', JSON.stringify(S.cart)); } catch (e) { } };
const rpc = (name, ...args) => post('rpc', { name, args });

/* ───── images : fichier du dossier images → docs.fivem.net / ox_inventory → illustration générée ───── */
function srcsFor(cat, it) {
  const m = String(it.model || '').trim(), low = m.toLowerCase();
  const loc = (dir, name) => (dir === 'vehicles' ? ['webp', 'png', 'jpg'] : ['png', 'webp', 'jpg']).map(e => `../images/${dir}/${name}.${e}`);
  if (cat === 'vehicle' || cat === 'moto' || cat === 'other') return [...loc('vehicles', low), `https://docs.fivem.net/vehicles/${low}.webp`, `https://docs.fivem.net/vehicles/${low}.png`];   // véhicules GTA de base : images officielles (internet requis)
  if (cat === 'weapon') return [...loc('weapons', low), `https://cfx-nui-ox_inventory/web/images/${m.toUpperCase()}.png`, `https://cfx-nui-ox_inventory/web/images/${m}.png`];
  if (cat === 'crate') return loc('caisses', low);
  if (cat === 'pack') return loc('packs', String(it.name || '').toLowerCase().replace(/[^a-z0-9]/g, ''));
  return [];
}
function tierColor(name) {
  return ['var(--pk-accent,#00a4ff)', 'var(--pk-accent-dark,#0076b8)'];
}
function art(cat, it) {
  const [a, b] = tierColor(it.name);
  const g = `<defs><linearGradient id="g${it.idx}${cat}" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${a}"/><stop offset="1" stop-color="${b}"/></linearGradient></defs>`;
  const f = `fill="url(#g${it.idx}${cat})"`;
  let body;
  if (cat === 'crate') body = `<path d="M10 34 60 10l50 24v52L60 112 10 86z" ${f}/><path d="M10 34l50 26 50-26M60 60v52" stroke="rgba(0,0,0,.28)" stroke-width="3" fill="none"/><rect x="52" y="52" width="16" height="12" rx="3" fill="rgba(0,0,0,.35)"/>`;
  else if (cat === 'pack') body = `<rect x="14" y="40" width="92" height="66" rx="10" ${f}/><rect x="14" y="40" width="92" height="22" rx="8" fill="rgba(255,255,255,.22)"/><rect x="54" y="40" width="12" height="66" fill="rgba(0,0,0,.25)"/><path d="M60 40c-14 0-26-6-26-16a10 10 0 0 1 18-6l8 22zM60 40c14 0 26-6 26-16a10 10 0 0 0-18-6l-8 22z" ${f}/>`;
  else body = `<rect x="14" y="36" width="92" height="64" rx="12" ${f}/><path d="M42 36v-8a8 8 0 0 1 8-8h20a8 8 0 0 1 8 8v8" stroke="${b}" stroke-width="6" fill="none"/><rect x="14" y="62" width="92" height="8" fill="rgba(0,0,0,.25)"/><rect x="52" y="56" width="16" height="20" rx="4" fill="rgba(255,255,255,.85)"/>`;
  return `<svg class="art" viewBox="0 0 120 120">${g}${body}</svg>`;
}
window.imgErr = img => {
  const list = (img.dataset.s || '').split('|').filter(Boolean);
  const i = Number(img.dataset.i || 0) + 1;
  if (i < list.length) { img.dataset.i = i; img.src = list[i]; }
  else { img.style.display = 'none'; const w = img.parentElement; if (w && w.querySelector('svg.art') == null) w.insertAdjacentHTML('beforeend', w.dataset.art || ''); }
};
const picHtml = (cat, it, tag) => {
  const srcs = srcsFor(cat, it), a = art(cat, it);
  const fallbackArt = (cat === 'vehicle' || cat === 'moto' || cat === 'other') ? `<svg class="art" viewBox="0 0 24 24" style="opacity:.55;color:var(--acc);fill:none;stroke:currentColor;stroke-width:1">${IC[cat === 'moto' ? 'moto' : (it.vtype ? 'plane' : 'car')]}</svg>` : (cat === 'weapon' ? `<svg class="art" viewBox="0 0 24 24" style="opacity:.55;color:var(--acc);fill:none;stroke:currentColor;stroke-width:1">${IC.gun}</svg>` : a);
  const hasImg = srcs.length > 0;
  return `<div class="pic" data-art="${esc(fallbackArt)}">${hasImg ? `<img data-s="${esc(srcs.join('|'))}" data-i="0" src="${esc(srcs[0])}" onerror="imgErr(this)" alt="">` : fallbackArt}${tag ? `<span class="tag">${esc(tag)}</span>` : ''}</div>`;
};

/* ───── rendu ───── */
const list = () => (S.data && S.data[S.cat]) || [];
const filtered = () => {
  const q = S.q.trim().toLowerCase();
  const l = list().filter(it => !q || String(it.name).toLowerCase().includes(q) || String(it.model || '').toLowerCase().includes(q));
  if (S.sort === 'priceDesc') l.sort((a, b) => b.price - a.price); else if (S.sort === 'name') l.sort((a, b) => String(a.name).localeCompare(String(b.name), 'fr')); else if (S.sort === 'price') l.sort((a, b) => a.price - b.price);
  return l;
};
const cat = () => CATS.find(c => c.id === S.cat) || CATS[0];
const itemIn = (c, i) => ((S.data && S.data[c]) || []).find(x => x.idx === Number(i));

function tagOf(it, c) {
  c = c || S.cat;
  if (c === 'other') return it.vtype === 'boat' ? 'Bateau' : it.vtype === 'aircraft' ? 'Avion' : 'Autre';
  if (c === 'weapon') return 'Arme';
  return '';
}
function metaOf(it, c) {
  c = c || S.cat;
  if (c === 'weapon') return it.balle ? `${it.balle} munitions` : 'Arme';
  if (c === 'vehicle' || c === 'moto' || c === 'other') return it.model;
  if (c === 'pack') return `${(it.contents || []).length} éléments`;
  return (it.desc || '').split('\n')[0].slice(0, 60);
}

/* ───── panier ───── */
const maxQty = c => (c === 'weapon' || c === 'business') ? 1 : 10;
const cartCount = () => S.cart.reduce((n, l) => n + l.qty, 0);
const cartLines = () => S.cart.map(l => ({ l, it: itemIn(l.cat, l.idx) })).filter(x => x.it);
const subtotal = () => cartLines().reduce((n, x) => n + x.it.price * x.l.qty, 0);
const discounted = p => Math.max(0, Math.floor(p * (100 - S.pct) / 100 + 0.5));
const finalTotal = () => cartLines().reduce((n, x) => n + discounted(x.it.price) * x.l.qty, 0);
function addToCart(c, idx) {
  const it = itemIn(c, idx); if (!it) return;
  const line = S.cart.find(l => l.cat === c && l.idx === it.idx);
  if (line) { if (line.qty >= maxQty(c)) return toast('Quantité maximale atteinte pour cet article'); line.qty++; } else S.cart.push({ cat: c, idx: it.idx, qty: 1 });
  saveCart(); toast(`${it.name} ajouté au panier`, 'ok'); refreshBadge();
}
const refreshBadge = () => { const b = document.getElementById('cartBadge'); if (b) { b.textContent = cartCount(); b.style.display = cartCount() ? '' : 'none'; } };

/* ───── navigation ───── */
// logo + nom du serveur (pickax_core/config.lua → ServerLogo / ServerName / ServerShortName)
function brand() {
  const sv = window.PICKAX_SERVER || {}, logo = window.PICKAX_LOGO;
  const mark = logo ? `<img src="${esc(logo)}" alt="" onerror="this.replaceWith(Object.assign(document.createElement('span'),{className:'fb',textContent:'${esc((sv.short || 'B')[0])}'}))">` : `<span class="fb">${esc((sv.short || 'B')[0])}</span>`;
  return `<div class="brand"><div class="mark">${mark}</div><div class="bt"><b>${esc(sv.name || 'Boutique')}</b><span>Boutique officielle</span></div></div>`;
}
function sidebar(cats) {
  const nav = (id, icon, label, extra, color) => `<button class="${S.view === id ? 'on' : ''}" data-a="view" data-v="${id}" style="--cc:${color || 'var(--pk-accent,#00a4ff)'}"><span class="ico">${ic(icon, 19)}</span><span class="lb">${label}</span>${extra || ''}</button>`;
  return `<aside class="side">${brand()}
    <div class="cap">Catégories</div>
    <nav class="nav">${cats.map(x => `<button class="${S.view === 'shop' && x.id === S.cat ? 'on' : ''}" data-a="cat" data-id="${x.id}" style="--cc:${x.color}"><span class="ico">${ic(x.icon, 19)}</span><span class="lb">${esc(x.label)}</span><span class="n">${(S.data[x.id] || []).length}</span></button>`).join('')}
      <div class="cap" style="margin-top:14px">Mon compte</div>
      ${nav('cart', 'cart', 'Panier', `<span class="n bd" id="cartBadge" style="${cartCount() ? '' : 'display:none'}">${cartCount()}</span>`, 'var(--pk-accent,#00a4ff)')}
      ${nav('history', 'hist', 'Historique', '', 'var(--pk-accent,#00a4ff)')}
      ${nav('codes', 'tag', 'Codes & parrainage', '', 'var(--pk-accent,#00a4ff)')}
      ${S.data.staff ? nav('admin', 'shield', 'Gestion', '', 'var(--pk-accent,#00a4ff)') : ''}</nav>
    <div class="foot">${S.data.boutiqueId ? `<div class="idcard"><small>Mon code boutique</small><b>#${esc(S.data.boutiqueId)}</b><span>Unique, lié à ton compte</span></div>` : ''}${S.data.link ? `<button data-a="link"><span class="ico">${ic('link', 16)}</span> Acheter des coins</button>` : ''}${S.data.staff ? `<button data-a="classic"><span class="ico">${ic('gear', 16)}</span> Ancien menu</button>` : ''}</div></aside>`;
}
const coinsBox = () => `<div class="coins"><span class="c">C</span><div><small>Mon solde</small><b id="pts">${fmt(S.points)}</b></div></div><button class="xbtn" data-a="close" title="Fermer (Échap)">${ic('x')}</button>`;
const heroBar = (icon, title, sub, color) => `<div class="hero"><div class="wm">${ic(icon)}</div><div class="ht"><div class="hi" style="--cc:${color}">${ic(icon, 26)}</div><div><h1>${esc(title)}</h1><p>${esc(sub)}</p></div></div><div class="sp"></div>${coinsBox()}</div>`;

function render() {
  if (!S.data) return;
  const cats = CATS.filter(c => (S.data[c.id] || []).length);
  if (!cats.find(c => c.id === S.cat) && cats[0]) S.cat = cats[0].id;
  let main;
  if (S.view === 'cart') main = viewCart();
  else if (S.view === 'history') main = viewHistory();
  else if (S.view === 'codes') main = viewCodes();
  else if (S.view === 'admin' && S.data.staff) main = viewAdmin();
  else main = viewShop();
  $root.innerHTML = sidebar(cats) + `<section class="main">${main}</section>` + (S.paying ? payOverlay() : '');
}

function viewShop() {
  const c = cat(), items = filtered();
  $root.style.setProperty('--cc', c.color);
  const sorts = [['price', 'Prix croissant'], ['priceDesc', 'Prix décroissant'], ['name', 'Nom A-Z']];
  return heroBar(c.icon, c.label, c.sub, c.color) +
    `<div class="tools"><label class="search">${ic('search', 16)}<input id="q" placeholder="Rechercher un article…" value="${esc(S.q)}"></label>
      <div class="sort">${sorts.map(o => `<button class="${S.sort === o[0] ? 'on' : ''}" data-a="sort" data-v="${o[0]}">${o[1]}</button>`).join('')}</div><div class="sp"></div><span class="count">${items.length} article${items.length > 1 ? 's' : ''}</span></div>
      <div class="scroll"><div class="grid">${items.length ? items.map((it, n) => `<div class="card" data-a="open" data-i="${it.idx}" style="animation-delay:${Math.min(n, 12) * 0.03}s">${picHtml(S.cat, it, tagOf(it))}
        <div class="info"><h3>${esc(it.name)}</h3><div class="meta">${esc(metaOf(it))}</div><div class="price"><span class="pill ${S.points < it.price ? 'short' : ''}"><i></i>${fmt(it.price)}</span>
        <span class="addq"><button class="mini" data-a="addcart" data-c="${S.cat}" data-i="${it.idx}" title="Ajouter au panier">${ic('cart', 16)}</button></span></div></div></div>`).join('') : '<div class="empty" style="grid-column:1/-1">Aucun article ne correspond à ta recherche.</div>'}</div></div>`;
}

function viewCart() {
  const lines = cartLines(), sub = subtotal(), fin = finalTotal(), lack = fin - S.points;
  return heroBar('cart', 'Mon panier', `${cartCount()} article${cartCount() > 1 ? 's' : ''}`, 'var(--pk-accent,#00a4ff)') +
    `<div class="scroll"><div class="cartwrap"><div class="cartlist">${lines.length ? lines.map(({ l, it }) => `<div class="row">
        <div class="thumb">${picHtml(l.cat, it, '')}</div><div class="rn"><b>${esc(it.name)}</b><span>${esc(metaOf(it, l.cat))}</span></div>
        <div class="qty">${maxQty(l.cat) > 1 ? `<button data-a="qminus" data-c="${l.cat}" data-i="${it.idx}">${ic('minus', 14)}</button><b>${l.qty}</b><button data-a="qplus" data-c="${l.cat}" data-i="${it.idx}">${ic('plus', 14)}</button>` : '<b>×1</b>'}</div>
        <div class="lp"><span class="pill"><i></i>${fmt(discounted(it.price) * l.qty)}</span>${S.pct ? `<s>${fmt(it.price * l.qty)}</s>` : ''}</div>
        <button class="xrm" data-a="rm" data-c="${l.cat}" data-i="${it.idx}" title="Retirer">${ic('trash', 16)}</button></div>`).join('')
      : `<div class="empty">Ton panier est vide.<br><button class="btn pri" data-a="view" data-v="shop" style="margin-top:16px;max-width:240px">Parcourir la boutique</button></div>`}</div>
      <aside class="summary"><h3>Récapitulatif</h3>
        <div class="line"><span>Sous-total</span><b>${fmt(sub)}</b></div>
        ${S.pct ? `<div class="line good"><span>Code ${esc(S.code)} (-${S.pct}%)</span><b>-${fmt(sub - fin)}</b></div>` : ''}
        <div class="promo"><input id="promo" placeholder="Code promo" value="${esc(S.code)}" maxlength="32"><button data-a="applyCode">${S.pct ? 'Retirer' : 'Appliquer'}</button></div>
        ${S.promoMsg ? `<div class="pmsg ${S.pct ? 'ok' : 'bad'}">${esc(S.promoMsg)}</div>` : ''}
        <div class="line tot"><span>Total</span><b><span class="pill ${lack > 0 ? 'short' : ''}"><i></i>${fmt(fin)}</span></b></div>
        <div class="line"><span>Mon solde</span><b>${fmt(S.points)}</b></div>
        ${lack > 0 && lines.length ? `<div class="warn">Il te manque ${fmt(lack)} coins.</div>` : ''}
        <button class="btn pri" data-a="pay" ${(!lines.length || lack > 0) ? 'disabled' : ''}>Payer ${lines.length ? fmt(fin) + ' coins' : ''}</button>
        ${lines.length ? '<button class="btn" data-a="clearCart" style="margin-top:8px">Vider le panier</button>' : ''}
      </aside></div></div>`;
}

const when = ts => new Date(ts * 1000).toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', year: '2-digit', hour: '2-digit', minute: '2-digit' });
const catLabel = c => (CATS.find(x => x.id === c) || {}).label || '';

function viewHistory() {
  const h = S.history;
  return heroBar('hist', 'Historique', 'Tes derniers achats en boutique', 'var(--pk-accent,#00a4ff)') +
    `<div class="scroll">${h == null ? '<div class="empty">Chargement…</div>' : h.length ? `<table class="tbl"><tr><th>Date</th><th>Article</th><th>Catégorie</th><th>Payé</th><th>Code</th></tr>${h.map(r => `<tr><td>${when(r.ts)}</td><td><b>${esc(r.item_name)}</b></td><td>${esc(catLabel(r.category))}</td>
      <td><span class="pill"><i></i>${fmt(r.price)}</span>${r.full_price > r.price ? ` <s class="old">${fmt(r.full_price)}</s>` : ''}</td><td>${r.code ? `<span class="chip">${esc(r.code)}</span>` : ''}</td></tr>`).join('')}</table>` : '<div class="empty">Aucun achat pour le moment.</div>'}</div>`;
}

function viewCodes() {
  const o = S.overview, r = o && o.referral;
  return heroBar('tag', 'Codes & parrainage', 'Utilise un code ou invite tes amis', 'var(--pk-accent,#00a4ff)') +
    `<div class="scroll"><div class="two">
      <div class="panel"><h3>${ic('tag', 18)} Utiliser un code</h3><p class="sub">Code cadeau (coins offerts) ou code de parrainage d'un ami. Les codes de réduction se saisissent dans le panier.</p>
        <div class="promo big"><input id="redeem" placeholder="Ex : CADEAU2025 ou REF-1234" maxlength="32"><button class="pri" data-a="redeem">Valider</button></div></div>
      <div class="panel"><h3>${ic('users', 18)} Parrainage</h3>${!r ? '<div class="empty">Chargement…</div>' : !r.enabled ? '<p class="sub">Le parrainage est désactivé pour le moment.</p>' : `
        <p class="sub">Partage ton code : ton ami reçoit <b>${fmt(r.filleulCoins)} coins</b> et toi <b>${fmt(r.parrainCoins)} coins</b> dès qu'il le saisit.</p>
        <div class="refcode"><span>${esc(r.code || 'indisponible')}</span></div>
        <div class="stats"><div><b>${fmt(r.count)}</b><small>filleul(s)</small></div><div><b>${fmt(r.earned)}</b><small>coins gagnés</small></div></div>
        ${r.hasParrain ? '<p class="sub" style="margin-top:12px">Tu as déjà été parrainé.</p>' : ''}`}</div></div></div>`;
}

function viewAdmin() {
  const a = S.admin;
  if (!a) return heroBar('shield', 'Gestion', 'Codes promo, parrainage et ventes', 'var(--pk-accent,#00a4ff)') + '<div class="scroll"><div class="empty">Chargement…</div></div>';
  const ref = a.referral;
  return heroBar('shield', 'Gestion', 'Codes promo, parrainage et ventes', 'var(--pk-accent,#00a4ff)') +
    `<div class="scroll"><div class="two">
      <div class="panel"><h3>${ic('plus', 18)} Créer un code</h3><div class="form">
        <label>Code (vide = aléatoire)<input id="nc" maxlength="32" placeholder="PROMO10"></label>
        <label>Type<select id="nk"><option value="percent">Réduction du panier (%)</option><option value="coins">Coins offerts</option></select></label>
        <label>Valeur (% ou coins)<input id="nv" type="number" min="1" value="10"></label>
        <label>Utilisations max (0 = illimité)<input id="nm" type="number" min="0" value="0"></label>
        <label>Par joueur<input id="np" type="number" min="1" value="1"></label>
        <label>Valide (jours, 0 = toujours)<input id="nd" type="number" min="0" value="0"></label>
        <label style="grid-column:1/-1">Note interne<input id="nn" maxlength="120" placeholder="Opération de lancement…"></label></div>
        <button class="btn pri" data-a="createCode" style="margin-top:12px">Créer le code</button></div>
      <div class="panel"><h3>${ic('users', 18)} Réglages du parrainage</h3><div class="form">
        <label class="chk2"><input id="re" type="checkbox" ${ref.Enabled ? 'checked' : ''}> Parrainage activé</label><span></span>
        <label>Coins pour le filleul<input id="rf" type="number" min="0" value="${ref.FilleulCoins}"></label>
        <label>Coins pour le parrain<input id="rp" type="number" min="0" value="${ref.ParrainCoins}"></label></div>
        <button class="btn pri" data-a="saveRef" style="margin-top:12px">Enregistrer</button>
        <p class="sub" style="margin-top:14px">Chaque joueur a un code unique « REF-<i>numéro boutique</i> » visible dans l'onglet Codes & parrainage.</p></div></div>
      <div class="panel wide"><h3>${ic('users', 18)} Give à tous les joueurs en ligne</h3><div class="form">
        <label>Coins par joueur<input id="ga" type="number" min="1" max="1000000" value="100"></label>
        <label>Motif (affiché au joueur)<input id="gr" maxlength="60" placeholder="Événement, compensation…"></label></div>
        <button class="btn pri" data-a="giveAll" style="margin-top:12px">Envoyer à tout le monde</button>
        <p class="sub" style="margin-top:10px">Chaque joueur connecté reçoit le montant indiqué, une notification et une ligne dans son historique.</p></div>
      <div class="panel wide"><h3>${ic('tag', 18)} Codes (${a.codes.length})</h3>${a.codes.length ? `<table class="tbl"><tr><th>Code</th><th>Type</th><th>Valeur</th><th>Utilisé</th><th>Par joueur</th><th>Expire</th><th>État</th><th></th></tr>${a.codes.map(c => `<tr><td><b>${esc(c.code)}</b>${c.note ? `<br><small>${esc(c.note)}</small>` : ''}</td>
        <td>${c.kind === 'percent' ? 'Réduction' : 'Coins'}</td><td>${c.kind === 'percent' ? c.value + ' %' : fmt(c.value) + ' coins'}</td><td>${c.uses}${c.max_uses ? ' / ' + c.max_uses : ''}</td><td>${c.per_player}</td><td>${c.expires ? when(c.expires) : '—'}</td>
        <td><span class="chip ${c.active ? 'ok' : 'off'}">${c.active ? 'Actif' : 'Désactivé'}</span></td><td style="text-align:right"><button class="mini2" data-a="toggleCode" data-id="${c.id}">${c.active ? 'Désactiver' : 'Activer'}</button> <button class="mini2 bad" data-a="delCode" data-id="${c.id}">${ic('trash', 14)}</button></td></tr>`).join('')}</table>` : '<p class="sub">Aucun code.</p>'}</div>
      <div class="panel wide"><h3>${ic('hist', 18)} Dernières ventes</h3>${a.sales.length ? `<table class="tbl"><tr><th>Date</th><th>Joueur</th><th>Article</th><th>Payé</th><th>Code</th></tr>${a.sales.map(r => `<tr><td>${when(r.ts)}</td><td>${esc(r.player_name)}</td><td>${esc(r.item_name)}</td><td>${fmt(r.price)}${r.full_price > r.price ? ` <s class="old">${fmt(r.full_price)}</s>` : ''}</td><td>${r.code ? esc(r.code) : ''}</td></tr>`).join('')}</table>` : '<p class="sub">Aucune vente.</p>'}</div>
      <div class="panel wide"><h3>${ic('users', 18)} Derniers parrainages</h3>${a.referrals.length ? `<table class="tbl"><tr><th>Date</th><th>Filleul</th><th>Coins filleul</th><th>Coins parrain</th></tr>${a.referrals.map(r => `<tr><td>${when(r.ts)}</td><td>${esc(r.filleul_name)}</td><td>${fmt(r.filleul_coins)}</td><td>${fmt(r.parrain_coins)}</td></tr>`).join('')}</table>` : '<p class="sub">Aucun parrainage.</p>'}</div></div></div>`;
}

function payOverlay() {
  const p = S.paying;
  return `<div class="payov"><div class="paybox"><div class="spin"></div><h2>${p.done ? 'Paiement terminé' : 'Livraison en cours…'}</h2><p>${p.done ? (p.failed ? `${p.failed} article(s) n'ont pas pu être livrés (déjà possédés ?).` : 'Tous tes articles ont été livrés !') : `${p.i} / ${p.n} — ${esc(p.name || '')}`}</p>
    <div class="pbar"><i style="width:${p.n ? Math.round((p.done ? p.n : p.i - 1) / p.n * 100) : 0}%"></i></div>${p.done ? '<button class="btn pri" data-a="payClose" style="margin-top:16px">Fermer</button>' : '<small>Ne quitte pas la boutique.</small>'}</div></div>`;
}

function sheet(it, confirm, c) {
  c = c || S.cat;
  const ct = CATS.find(x => x.id === c) || cat(), lack = it.price - S.points;
  $modal.innerHTML = `<div class="sheet">${picHtml(c, it, tagOf(it, c))}<div class="body"><span class="kind">${esc(ct.kind)}</span><h2>${esc(it.name)}</h2>
    <div class="desc ${it.desc ? '' : 'none'}">${it.desc ? esc(it.desc) : 'Aucun descriptif pour le moment.'}</div>
    ${S.data.dev ? `<div class="deved"><label>Descriptif (visible par tous les joueurs)<textarea id="descText" maxlength="800" rows="4" placeholder="Décris l'article : vitesse, places, particularités…">${esc(it.desc || '')}</textarea></label>
      <button class="btn" data-a="saveDesc" data-c="${c}" data-i="${it.idx}">${ic('check', 16)} Enregistrer le descriptif</button></div>` : ''}
    <div class="chips">${it.model && c !== 'pack' && c !== 'crate' && c !== 'business' ? `<span class="chip">Modèle : ${esc(it.model)}</span>` : ''}${it.balle ? `<span class="chip">${esc(it.balle)} munitions</span>` : ''}${it.vtype ? `<span class="chip">${it.vtype === 'boat' ? 'Bateau' : 'Avion'}</span>` : ''}</div>
    ${(it.contents && it.contents.length) ? `<div class="contents"><b>Contenu</b><ul>${it.contents.map(x => `<li>${esc(x)}</li>`).join('')}</ul></div>` : ''}
    <div class="buy">${lack > 0 ? `<div class="warn">Il te manque ${fmt(lack)} coins.</div>` : ''}<div class="total"><span class="pill ${lack > 0 ? 'short' : ''}"><i></i>${fmt(it.price)} coins</span><small>Solde : ${fmt(S.points)}</small></div>
      <div class="btns"><button class="btn" data-a="closeSheet">${confirm ? 'Annuler' : 'Fermer'}</button>${confirm ? `<button class="btn pri" data-a="buy" data-c="${c}" data-i="${it.idx}">Confirmer l'achat</button>` : `<button class="btn" data-a="addcart" data-c="${c}" data-i="${it.idx}" data-close="1">${ic('cart', 16)} Au panier</button><button class="btn pri" data-a="ask" data-c="${c}" data-i="${it.idx}" ${lack > 0 ? 'disabled' : ''}>Acheter</button>`}</div></div></div></div>`;
  $modal.classList.remove('hidden');
}
const closeSheet = () => { $modal.classList.add('hidden'); $modal.innerHTML = ''; };

function toast(msg, kind) {
  const t = document.createElement('div'); t.className = 'toast ' + (kind || ''); t.textContent = msg; $toasts.appendChild(t); setTimeout(() => t.remove(), 3400);
}
function countTo(el, to) {
  const from = Number((el.textContent || '0').replace(/[\s  ]/g, '')) || 0, t0 = performance.now();
  const step = n => { const k = Math.min(1, (n - t0) / 600); el.textContent = fmt(Math.round(from + (to - from) * (1 - Math.pow(1 - k, 3)))); if (k < 1) requestAnimationFrame(step); };
  requestAnimationFrame(step);
}
const val = id => (document.getElementById(id) || {}).value;

// couleur principale envoyée par le jeu (pickax_core/config.lua → AccentColor) : fonctionne même si theme.js n'a pas pu être chargé
function applyAccent(hex) {
  if (!/^#[0-9a-f]{6}$/i.test(String(hex || ''))) return;
  const rgb = [1, 3, 5].map(i => parseInt(hex.slice(i, i + 2), 16));
  const mix = (to, t) => '#' + rgb.map(v => { const n = Math.round(v + (to - v) * t); return (n < 16 ? '0' : '') + n.toString(16); }).join('');
  const st = document.documentElement.style;
  st.setProperty('--pk-accent', hex); st.setProperty('--pk-accent-rgb', rgb.join(','));
  st.setProperty('--pk-accent-light', mix(255, 0.14)); st.setProperty('--pk-accent-dark', mix(0, 0.28));
}

async function loadView(v) {
  if (v === 'history') { S.history = null; render(); const r = await rpc('history'); S.history = (r && r.list) || []; }
  else if (v === 'codes') { S.overview = null; render(); const r = await rpc('overview'); S.overview = r && r.ok ? r : { referral: { enabled: false } }; }
  else if (v === 'admin') { S.admin = null; render(); const r = await rpc('admin:data'); if (r && r.ok) S.admin = r; else { toast((r && r.error) || 'Accès refusé', 'bad'); S.view = 'shop'; } }
  render();
}

document.addEventListener('click', async e => {
  const el = e.target.closest('[data-a]'); if (!el) return;
  const a = el.dataset.a, c = el.dataset.c, i = el.dataset.i;
  if (a !== 'addcart' && a !== 'open' && el.closest('.card') && e.target.closest('.mini')) return;
  switch (a) {
    case 'close': return post('close');
    case 'cat': S.view = 'shop'; S.cat = el.dataset.id; S.q = ''; return render();
    case 'view': S.view = el.dataset.v; return S.view === 'shop' ? render() : loadView(S.view);
    case 'sort': S.sort = el.dataset.v; return render();
    case 'open': { if (e.target.closest('.mini')) return; const it = itemIn(S.cat, i); if (it) sheet(it, false, S.cat); return; }
    case 'closeSheet': return closeSheet();
    case 'ask': { const it = itemIn(c, i); if (it) sheet(it, true, c); return; }
    case 'saveDesc': {
      const it = itemIn(c, i); if (!it) return;
      const text = (document.getElementById('descText') || {}).value || '';
      const r = await rpc('saveDesc', { cat: c, key: it.model || it.name, text });
      if (r && r.ok) { it.desc = text.trim(); toast(text.trim() ? 'Descriptif enregistré' : 'Descriptif supprimé', 'ok'); sheet(it, false, c); }
      else toast((r && r.error) || 'Erreur', 'bad');
      return;
    }
    case 'addcart': e.stopPropagation(); addToCart(c, i); if (el.dataset.close) closeSheet(); return;
    case 'link': if (window.invokeNative) window.invokeNative('openUrl', S.data.link); else window.open(S.data.link, '_blank'); return;
    case 'classic': return post('classic');
    case 'buy': {
      const it = itemIn(c, i); if (!it) return;
      el.disabled = true;
      const r = await post('buy', { cat: c, idx: it.idx });
      closeSheet();
      if (r && r.ok) toast(`Achat envoyé : ${it.name}`, 'ok'); else toast((r && r.error) || 'Achat impossible', 'bad');
      return;
    }
    case 'qplus': { const l = S.cart.find(x => x.cat === c && x.idx === Number(i)); if (l && l.qty < maxQty(c)) l.qty++; saveCart(); return render(); }
    case 'qminus': { const l = S.cart.find(x => x.cat === c && x.idx === Number(i)); if (l && l.qty > 1) l.qty--; saveCart(); return render(); }
    case 'rm': S.cart = S.cart.filter(x => !(x.cat === c && x.idx === Number(i))); saveCart(); return render();
    case 'clearCart': S.cart = []; saveCart(); S.code = ''; S.pct = 0; S.promoMsg = ''; return render();
    case 'applyCode': {
      if (S.pct) { S.code = ''; S.pct = 0; S.promoMsg = ''; return render(); }
      const code = (val('promo') || '').trim(); if (!code) return;
      const r = await rpc('previewCode', code);
      if (r && r.ok) { S.code = r.code; S.pct = r.pct; S.promoMsg = `Réduction de ${r.pct}% appliquée`; } else { S.code = code.toUpperCase(); S.pct = 0; S.promoMsg = (r && r.error) || 'Code invalide'; }
      return render();
    }
    case 'pay': {
      if (S.paying) return;
      const lines = cartLines().map(x => ({ cat: x.l.cat, idx: x.it.idx, qty: x.l.qty }));
      el.disabled = true;
      const r = await post('checkout', { cart: lines, code: S.pct ? S.code : '' });
      if (!r || !r.ok) { toast((r && r.error) || 'Paiement impossible', 'bad'); return render(); }
      S.paying = { i: 1, n: r.count, name: '', done: false };
      return render();
    }
    case 'payClose': S.paying = null; S.cart = []; saveCart(); S.code = ''; S.pct = 0; S.promoMsg = ''; S.view = 'history'; return loadView('history');
    case 'redeem': {
      const code = (val('redeem') || '').trim(); if (!code) return;
      const r = await rpc('redeem', code);
      if (r && r.ok) { toast(r.message || 'Code accepté', 'ok'); S.overview = null; return loadView('codes'); }
      return toast((r && r.error) || 'Code invalide', 'bad');
    }
    case 'createCode': {
      const r = await rpc('admin:saveCode', { code: val('nc'), kind: val('nk'), value: val('nv'), maxUses: val('nm'), perPlayer: val('np'), days: val('nd'), note: val('nn') });
      if (r && r.ok) { toast(`Code créé : ${r.code}`, 'ok'); return loadView('admin'); }
      return toast((r && r.error) || 'Erreur', 'bad');
    }
    case 'toggleCode': { await rpc('admin:toggleCode', Number(el.dataset.id)); return loadView('admin'); }
    case 'delCode': { if (!confirm('Supprimer ce code ?')) return; await rpc('admin:deleteCode', Number(el.dataset.id)); return loadView('admin'); }
    case 'giveAll': {
      const n = Math.floor(Number(val('ga')) || 0);
      if (n < 1) return toast('Montant invalide', 'bad');
      if (!confirm(`Donner ${fmt(n)} coins à TOUS les joueurs en ligne ?`)) return;
      const r = await rpc('admin:giveAll', { amount: n, reason: val('gr') });
      if (r && r.ok) { toast(`${fmt(n)} coins envoyés à ${r.given} joueur(s)`, 'ok'); return loadView('admin'); }
      return toast((r && r.error) || 'Erreur', 'bad');
    }
    case 'saveRef': {
      const r = await rpc('admin:saveSettings', { Enabled: document.getElementById('re').checked, FilleulCoins: val('rf'), ParrainCoins: val('rp') });
      if (r && r.ok) { toast('Parrainage enregistré', 'ok'); return loadView('admin'); }
      return toast((r && r.error) || 'Erreur', 'bad');
    }
  }
});
document.addEventListener('input', e => {
  if (e.target.id !== 'q') return;
  S.q = e.target.value;
  const keep = e.target.selectionStart; render(); const q = document.getElementById('q'); q.focus(); q.setSelectionRange(keep, keep);
});
window.addEventListener('message', e => {
  const d = e.data || {};
  if (d.action === 'open') { applyAccent(d.data.accent); S.data = d.data; S.points = Number(d.data.points) || 0; S.q = ''; S.view = 'shop'; S.paying = null; $root.classList.remove('hidden'); render(); }
  else if (d.action === 'close') { $root.classList.add('hidden'); closeSheet(); }
  else if (d.action === 'points') { const prev = S.points; S.points = Number(d.points) || 0; const el = document.getElementById('pts'); if (el) countTo(el, S.points); if (prev !== S.points && !$modal.classList.contains('hidden')) closeSheet(); }
  else if (d.action === 'checkoutProgress') { S.paying = Object.assign(S.paying || {}, { i: d.i, n: d.n, name: d.name, done: false }); render(); }
  else if (d.action === 'checkoutDone') { S.paying = Object.assign(S.paying || { n: 0 }, { done: true, failed: d.failed || 0 }); render(); }
});
document.addEventListener('keydown', e => {
  if ($root.classList.contains('hidden')) return;
  if (e.key === 'Escape') { if (S.paying && !S.paying.done) return; if (!$modal.classList.contains('hidden')) closeSheet(); else post('close'); }
});
