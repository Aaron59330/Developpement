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
  store: '<path d="M4 9l1.5-5h13L20 9"/><path d="M4 9v11h16V9"/><path d="M9 20v-6h6v6"/>',
};
const ic = (n, s) => `<svg class="ic" viewBox="0 0 24 24"${s ? ` style="width:${s}px;height:${s}px"` : ''}>${IC[n] || IC.box}</svg>`;

const CATS = [
  { id: 'vehicle', label: 'Véhicules', sub: 'Voitures et SUV, livrés dans ton garage', icon: 'car', kind: 'Véhicule', color: 'var(--pk-accent,#00a4ff)' },
  { id: 'moto', label: 'Motos', sub: 'Deux-roues, sportives et tout-terrain', icon: 'moto', kind: 'Moto', color: '#fb923c' },
  { id: 'other', label: 'Air & mer', sub: 'Avions, hélicoptères et bateaux', icon: 'plane', kind: 'Véhicule', color: '#38bdf8' },
  { id: 'weapon', label: 'Armes', sub: 'Armes permanentes avec munitions', icon: 'gun', kind: 'Arme', color: '#f87171' },
  { id: 'crate', label: 'Caisses', sub: 'Caisses surprise : véhicules, armes et argent', icon: 'box', kind: 'Caisse', color: '#fbbf24' },
  { id: 'pack', label: 'Packs', sub: 'Packs de départ et bonus', icon: 'gift', kind: 'Pack', color: '#a78bfa' },
  { id: 'business', label: 'Entreprises', sub: 'Gangs et entreprises clés en main', icon: 'brief', kind: 'Entreprise', color: '#34d399' },
];
const S = { data: null, cat: 'vehicle', q: '', points: 0, sort: 'price' };

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
  const n = String(name || '').toLowerCase();
  if (/bronze/.test(n)) return ['#e2a266', '#8a5126']; if (/argent|silver/.test(n)) return ['#dfe5ee', '#7d8798']; if (/\bor\b|gold|dor/.test(n)) return ['#ffe08a', '#c98f10'];
  if (/diamant/.test(n)) return ['#a5f3fc', '#2a8aa0'];
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

function tagOf(it) {
  if (S.cat === 'other') return it.vtype === 'boat' ? 'Bateau' : it.vtype === 'aircraft' ? 'Avion' : 'Autre';
  if (S.cat === 'weapon') return 'Arme';
  return '';
}
function metaOf(it) {
  if (S.cat === 'weapon') return it.balle ? `${it.balle} munitions` : 'Arme';
  if (S.cat === 'vehicle' || S.cat === 'moto' || S.cat === 'other') return it.model;
  if (S.cat === 'pack') return `${(it.contents || []).length} éléments`;
  return (it.desc || '').split('\n')[0].slice(0, 60);
}

function render() {
  if (!S.data) return;
  const cats = CATS.filter(c => (S.data[c.id] || []).length);
  if (!cats.find(c => c.id === S.cat) && cats[0]) S.cat = cats[0].id;
  const c = cat(), items = filtered();
  const sorts = [['price', 'Prix croissant'], ['priceDesc', 'Prix décroissant'], ['name', 'Nom A-Z']];
  $root.style.setProperty('--cc', c.color);
  $root.innerHTML = `<aside class="side"><div class="brand"><div class="mark">${ic('bag', 20)}</div><div><b>Boutique</b><span>Paiement en coins</span></div></div>
    <div class="cap">Catégories</div>
    <nav class="nav">${cats.map(x => `<button class="${x.id === S.cat ? 'on' : ''}" data-a="cat" data-id="${x.id}" style="--cc:${x.color}"><span class="ico">${ic(x.icon, 19)}</span><span class="lb">${esc(x.label)}</span><span class="n">${(S.data[x.id] || []).length}</span></button>`).join('')}</nav>
    <div class="foot">${S.data.link ? `<button data-a="link"><span class="ico">${ic('link', 16)}</span> Acheter des coins</button>` : ''}${S.data.staff ? `<button data-a="classic"><span class="ico">${ic('gear', 16)}</span> Administration</button>` : ''}</div></aside>
    <section class="main"><div class="hero"><div class="wm">${ic(c.icon)}</div><div class="ht"><div class="hi">${ic(c.icon, 26)}</div><div><h1>${esc(c.label)}</h1><p>${esc(c.sub)}</p></div></div><div class="sp"></div>
      <div class="coins"><span class="c">C</span><div><small>Mon solde</small><b id="pts">${fmt(S.points)}</b></div></div><button class="xbtn" data-a="close" title="Fermer (Échap)">${ic('x')}</button></div>
      <div class="tools"><label class="search">${ic('search', 16)}<input id="q" placeholder="Rechercher un article…" value="${esc(S.q)}"></label>
        <div class="sort">${sorts.map(o => `<button class="${S.sort === o[0] ? 'on' : ''}" data-a="sort" data-v="${o[0]}">${o[1]}</button>`).join('')}</div><div class="sp"></div><span class="count">${items.length} article${items.length > 1 ? 's' : ''}</span></div>
      <div class="scroll"><div class="grid">${items.length ? items.map((it, n) => `<div class="card" data-a="open" data-i="${it.idx}" style="animation-delay:${Math.min(n, 12) * 0.03}s">${picHtml(S.cat, it, tagOf(it))}
        <div class="info"><h3>${esc(it.name)}</h3><div class="meta">${esc(metaOf(it))}</div><div class="price"><span class="pill ${S.points < it.price ? 'short' : ''}"><i></i>${fmt(it.price)}</span><span class="see">Voir ${ic('arrow', 14)}</span></div></div></div>`).join('') : '<div class="empty" style="grid-column:1/-1">Aucun article ne correspond à ta recherche.</div>'}</div></div></section>`;
}

function sheet(it, confirm) {
  const c = cat(), lack = it.price - S.points;
  $modal.innerHTML = `<div class="sheet">${picHtml(S.cat, it, tagOf(it))}<div class="body"><span class="kind">${esc(c.kind)}</span><h2>${esc(it.name)}</h2>
    ${it.desc ? `<div class="desc">${esc(it.desc)}</div>` : ''}
    <div class="chips">${it.model && S.cat !== 'pack' && S.cat !== 'crate' && S.cat !== 'business' ? `<span class="chip">Modèle : ${esc(it.model)}</span>` : ''}${it.balle ? `<span class="chip">${esc(it.balle)} munitions</span>` : ''}${it.vtype ? `<span class="chip">${it.vtype === 'boat' ? 'Bateau' : 'Avion'}</span>` : ''}</div>
    ${(it.contents && it.contents.length) ? `<div class="contents"><b>Contenu</b><ul>${it.contents.map(x => `<li>${esc(x)}</li>`).join('')}</ul></div>` : ''}
    <div class="buy">${lack > 0 ? `<div class="warn">Il te manque ${fmt(lack)} coins.</div>` : ''}<div class="total"><span class="pill ${lack > 0 ? 'short' : ''}"><i></i>${fmt(it.price)} coins</span><small>Solde : ${fmt(S.points)}</small></div>
      <div class="btns"><button class="btn" data-a="closeSheet">${confirm ? 'Annuler' : 'Fermer'}</button>${confirm ? `<button class="btn pri" data-a="buy" data-i="${it.idx}">Confirmer l'achat</button>` : `<button class="btn pri" data-a="ask" data-i="${it.idx}" ${lack > 0 ? 'disabled' : ''}>Acheter</button>`}</div></div></div></div>`;
  $modal.classList.remove('hidden');
}
const closeSheet = () => { $modal.classList.add('hidden'); $modal.innerHTML = ''; };
const itemOf = i => list().find(x => x.idx === Number(i));

function toast(msg, kind) {
  const t = document.createElement('div'); t.className = 'toast ' + (kind || ''); t.textContent = msg; $toasts.appendChild(t); setTimeout(() => t.remove(), 3400);
}

function countTo(el, to) {
  const from = Number((el.textContent || '0').replace(/\s/g, '').replace(/ /g, '')) || 0, t0 = performance.now();
  const step = n => { const k = Math.min(1, (n - t0) / 600); el.textContent = fmt(Math.round(from + (to - from) * (1 - Math.pow(1 - k, 3)))); if (k < 1) requestAnimationFrame(step); };
  requestAnimationFrame(step);
}

document.addEventListener('click', async e => {
  const el = e.target.closest('[data-a]'); if (!el) return;
  const a = el.dataset.a;
  if (a === 'close') return post('close');
  if (a === 'cat') { S.cat = el.dataset.id; S.q = ''; return render(); }
  if (a === 'sort') { S.sort = el.dataset.v; return render(); }
  if (a === 'open') { const it = itemOf(el.dataset.i); if (it) sheet(it, false); return; }
  if (a === 'closeSheet') return closeSheet();
  if (a === 'ask') { const it = itemOf(el.dataset.i); if (it) sheet(it, true); return; }
  if (a === 'link') { if (window.invokeNative) window.invokeNative('openUrl', S.data.link); else window.open(S.data.link, '_blank'); return; }
  if (a === 'classic') return post('classic');
  if (a === 'buy') {
    const it = itemOf(el.dataset.i); if (!it) return;
    el.disabled = true;
    const r = await post('buy', { cat: S.cat, idx: it.idx });
    closeSheet();
    if (r && r.ok) toast(`Achat envoyé : ${it.name}`, 'ok'); else toast((r && r.error) || 'Achat impossible', 'bad');
  }
});
document.addEventListener('input', e => {
  if (e.target.id !== 'q') return;
  S.q = e.target.value;
  const keep = e.target.selectionStart; render(); const q = document.getElementById('q'); q.focus(); q.setSelectionRange(keep, keep);
});
window.addEventListener('message', e => {
  const d = e.data || {};
  if (d.action === 'open') { S.data = d.data; S.points = Number(d.data.points) || 0; S.q = ''; $root.classList.remove('hidden'); render(); }
  else if (d.action === 'close') { $root.classList.add('hidden'); closeSheet(); }
  else if (d.action === 'points') { const prev = S.points; S.points = Number(d.points) || 0; const el = document.getElementById('pts'); if (el) countTo(el, S.points); if (prev !== S.points && !$modal.classList.contains('hidden')) closeSheet(); }
});
document.addEventListener('keydown', e => {
  if ($root.classList.contains('hidden')) return;
  if (e.key === 'Escape') { if (!$modal.classList.contains('hidden')) closeSheet(); else post('close'); }
});
