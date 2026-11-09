'use strict';
const IN_GAME = typeof GetParentResourceName === 'function';
const $ = s => document.querySelector(s);
const esc = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const stage = $('#stage');
function fit() { const k = Math.min(innerWidth / 1920, innerHeight / 1080); stage.style.transform = `scale(${k})`; stage.style.left = (innerWidth - 1920 * k) / 2 + 'px'; stage.style.top = (innerHeight - 1080 * k) / 2 + 'px'; }
addEventListener('resize', fit); fit();
function post(n, d) { if (!IN_GAME) return Promise.resolve(); return fetch(`https://${GetParentResourceName()}/${n}`, { method: 'POST', body: JSON.stringify(d || {}) }).catch(() => { }); }

const P = {
    left: '<svg viewBox="0 0 24 24"><path d="M19 12H5M11 6l-6 6 6 6"/></svg>', right: '<svg viewBox="0 0 24 24"><path d="M5 12h14M13 6l6 6-6 6"/></svg>',
    grid: '<svg viewBox="0 0 24 24"><rect x="4" y="4" width="6" height="6"/><rect x="14" y="4" width="6" height="6"/><rect x="4" y="14" width="6" height="6"/><rect x="14" y="14" width="6" height="6"/></svg>',
    food: '<svg viewBox="0 0 24 24"><path d="M7 3v8M5 3v5a2 2 0 004 0V3M7 11v10M16 3c-2 2-2 8 0 9v9"/></svg>',
    shirt: '<svg viewBox="0 0 24 24"><path d="M8 3l-5 4 3 3 2-1v12h8V9l2 1 3-3-5-4a4 4 0 01-8 0z"/></svg>',
    target: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="2"/></svg>',
    tool: '<svg viewBox="0 0 24 24"><path d="M14 6a4 4 0 00-5 5L3 17l4 4 6-6a4 4 0 005-5l-3 3-3-1-1-3z"/></svg>',
    search: '<svg viewBox="0 0 24 24"><circle cx="11" cy="11" r="6"/><path d="M20 20l-4-4"/></svg>',
    box: '<svg viewBox="0 0 24 24"><path d="M12 3l8 4.5v9L12 21l-8-4.5v-9z M12 12l8-4.5M12 12v9M12 12L4 7.5"/></svg>',
    x: '<svg viewBox="0 0 24 24"><path d="M6 6l12 12M18 6L6 18"/></svg>',
    sort: '<svg viewBox="0 0 24 24"><path d="M8 4v16M8 4L4 8M8 4l4 4M16 20V4M16 20l-4-4M16 20l4-4"/></svg>',
    heart: '<svg viewBox="0 0 24 24"><path d="M12 20s-8-5-8-11a4.5 4.5 0 018-2.5A4.5 4.5 0 0120 9c0 6-8 11-8 11z"/></svg>',
    drop: '<svg viewBox="0 0 24 24"><path d="M12 3s6 6.5 6 11a6 6 0 01-12 0c0-4.5 6-11 6-11z"/></svg>',
    shield: '<svg viewBox="0 0 24 24"><path d="M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6z"/></svg>',
    check: '<svg viewBox="0 0 24 24"><path d="M5 12l5 5 9-10"/></svg>',
    chev: '<svg viewBox="0 0 24 24"><path d="M6 9l6 6 6-6"/></svg>',
    eye: '<svg viewBox="0 0 24 24"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></svg>',
    chart: '<svg viewBox="0 0 24 24"><path d="M6 20V11M12 20V5M18 20v-6"/></svg>',
    paw: '<svg viewBox="0 0 24 24"><circle cx="6" cy="11" r="2"/><circle cx="10" cy="6" r="2"/><circle cx="15" cy="6" r="2"/><circle cx="19" cy="11" r="2"/><path d="M12 12c-4 0-6 4-5 6s3 1 5 1 4 1 5-1-1-6-5-6z"/></svg>',
    users: '<svg viewBox="0 0 24 24"><circle cx="9" cy="8" r="3.5"/><path d="M3 20c0-4 3-6 6-6s6 2 6 6M16 5a3.5 3.5 0 010 7M18 14c2 1 3 3 3 6"/></svg>',
    lock: '<svg viewBox="0 0 24 24"><rect x="5" y="11" width="14" height="9" rx="1"/><path d="M8 11V8a4 4 0 018 0v3"/></svg>',
    mouse: '<svg viewBox="0 0 24 24"><rect x="6" y="3" width="12" height="18" rx="6"/><path d="M12 3v6"/></svg>',
    hat: '<svg viewBox="0 0 24 24"><path d="M3 16h18M6 16c0-5 2-8 6-8s6 3 6 8"/></svg>',
    glasses: '<svg viewBox="0 0 24 24"><circle cx="7" cy="14" r="3.5"/><circle cx="17" cy="14" r="3.5"/><path d="M10.5 14h3"/></svg>',
    pants: '<svg viewBox="0 0 24 24"><path d="M7 3h10l1 18h-5l-1-10-1 10H6z"/></svg>',
    shoe: '<svg viewBox="0 0 24 24"><path d="M3 15c3 0 4-2 4-6h4c0 3 2 4 6 5s4 2 4 4H3z"/></svg>',
    gem: '<svg viewBox="0 0 24 24"><path d="M6 4h12l3 5-9 11L3 9z"/></svg>',
    watch: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="5"/><path d="M9 3h6l1 4M9 21h6l1-4M12 10v2l1.5 1"/></svg>',
    mask: '<svg viewBox="0 0 24 24"><path d="M4 8c0-2 4-3 8-3s8 1 8 3v4c0 5-4 8-8 8s-8-3-8-8z"/></svg>',
    bag: '<svg viewBox="0 0 24 24"><rect x="4" y="8" width="16" height="12" rx="2"/><path d="M9 8V6a3 3 0 016 0v2"/></svg>',
    chain: '<svg viewBox="0 0 24 24"><path d="M5 4c0 9 3 12 7 15 4-3 7-6 7-15"/></svg>',
    parachute: '<svg viewBox="0 0 24 24"><path d="M3 11a9 9 0 0118 0zM3 11l9 9 9-9M12 11v9"/></svg>',
    wig: '<svg viewBox="0 0 24 24"><path d="M5 20c-1-8 1-15 7-15s8 7 7 15c-2-1-3-3-3-6-3 0-6-1-8-4 0 4-1 8-3 10z"/></svg>',
    vest: '<svg viewBox="0 0 24 24"><path d="M8 3l-3 3v14h14V6l-3-3-4 3z"/></svg>',
};
const EQI = { Tenue: 'shirt', Parachute: 'parachute', Perruque: 'wig', Chapeau: 'hat', Lunettes: 'glasses', Accessoire: 'chain', Haut: 'shirt', Pantalon: 'pants', Chaussures: 'shoe', Masque: 'mask', Boucles: 'gem', Sac: 'bag', Gilet: 'vest', Bracelet: 'gem', Montre: 'watch' };

let view = 'inv', SHOP = null;
let D = null, filter = 'all', query = '', sel = null, drag = null, tab = 0;
const CATS = { all: null, food: /water|bread|burger|sandwich|cola|food|drink|eau|pain|barre|candy|chocolat/i, shirt: /tenue|clothes|vest|mask|jacket|hat|gilet|veste/i, target: /^weapon_|ammo|munition|gun|akpixel/i, tool: /radio|phone|tool|kit|repair|talkie|lockpick|key|cle/i };

const hue = s => { let h = 0; for (const c of String(s)) h = (h * 31 + c.charCodeAt(0)) % 360; return h; };
function imgOf(it) {      // même ordre que ox_inventory : metadata.imageurl > metadata.image > image de l'objet > <nom>.png
    const base = (D.cfg.img || '').replace('/%s.png', '');
    if (it.imageurl) return it.imageurl;
    if (it.image) return `${base}/${it.image}.png`;
    if (it.defimg) return /^[\w]+:\/\//.test(it.defimg) ? it.defimg : `${base}/${it.defimg}`;
    return D.cfg.img.replace('%s', encodeURIComponent(it.name));
}
function icon(it, cls) {
    const g = `<div class="gl" style="background:hsl(${hue(it.name)} 40% 34%)">${esc(((it.label || it.name).match(/[A-Za-z0-9À-ÿ]/) || ['?'])[0].toUpperCase())}</div>`;
    if (!IN_GAME || !D.cfg.img) return g;
    const def = (D.cfg.img || '').replace('%s', '_default');
    const fb2 = `<img src="${def}" onerror="this.outerHTML=this.dataset.fb" data-fb='${g.replace(/'/g, '&#39;')}'>`;
    return `<img src="${imgOf(it)}" onerror="this.outerHTML=this.dataset.fb" data-fb='${fb2.replace(/'/g, '&#39;').replace(/&#39;/g, '&#39;')}'>`;
}
const kg = n => (Math.round(n * 100) / 100).toFixed(2).replace('.', ',');
const matches = it => (!query || (it.label || it.name).toLowerCase().includes(query)) && (!CATS[filter] || CATS[filter].test(it.name + ' ' + it.label));

function slotHtml(it, i, kind, extra) {
    const dur = it && it.durability != null && it.durability <= 100 ? `<div class="dur"><i style="width:${Math.max(0, it.durability)}%"></i></div>` : '';
    const dim = it && !matches(it) ? ' dim' : '';
    return `<div class="sl${it ? ' has' : ''}${dim}${kind === 'hot' ? ' hot' : ''}${sel && it && sel.slot === it.slot ? ' sel' : ''}" data-i="${i}" data-k="${kind}">${extra || ''}${it ? icon(it) + (it.count > 1 ? `<span class="n">${it.count}</span>` : '') + dur : ''}</div>`;
}
const GRIDS = (c) => ({ cols: c.cols || 7 });

function render() {
    const d = D, c = d.cfg, cols = c.cols, rows = c.rows, hotN = c.shortcuts;
    const bySlot = {}; d.items.forEach(it => bySlot[it.slot] = it);
    const mainCount = cols * rows;
    const pct = d.maxWeight ? d.weight / d.maxWeight : 0;
    const tops = [...d.items].sort((a, b) => b.weight - a.weight).slice(0, 3);
    const warns = [];
    d.items.forEach(it => { if (/^weapon_/i.test(it.name) && it.ammo === 0) warns.push({ it, t: it.label, s: 'Aucune munition compatible dans votre inventaire ni dans votre sac.', r: 'Sans munitions' }); });
    if (pct >= c.warn) warns.push({ ico: P.box, t: 'Inventaire presque plein', s: `${kg(d.weight)} kg sur ${d.maxWeight} kg.`, r: Math.round(pct * 100) + ' %' });
    const rc = d.recent.slice(0, c.recentCount);
    const ago = s => s < 60 ? 'Il y a ' + Math.max(1, s) + ' s' : 'Il y a ' + Math.floor(s / 60) + ' min';
    const eq = (g, x0, y0, dx, dy) => d.equipment[g].map((e, i) => `<div class="eq${e.worn ? ' worn' : ''}" style="left:${x0 + i * dx}px;top:${y0 + i * dy}px"><span class="ic">${P[EQI[e.label]] || ''}</span>${esc(e.label)}</div>`).join('');
    const stat = (x, ic, l, v) => `<div class="stat" style="left:${x}px"><div class="r">${P[ic]}${l}<b>${v == null ? '–' : v}</b></div><div class="t"><i style="width:${v || 0}%"></i></div></div>`;
    const bag = d.bag;
    const cats = ['all', 'food', 'shirt', 'target', 'tool'];
    stage.innerHTML = `
<div class="abs logo">${esc(c.brand)}</div>
<div class="abs who"><b>${esc(d.name)}</b><i>${esc(d.money)} $</i><div class="x" id="cl">${P.x}</div></div>
<div class="abs bar"><div class="strip"></div>
  <div class="btn arrow" id="prev" title="Catégorie précédente" style="position:absolute;left:0;top:9px">${P.left}</div>
  <div class="btn on" id="c_all" style="position:absolute;left:42px;top:0;width:88px;height:44px">${P.grid}Tout</div>
  ${cats.slice(1).map((k, i) => `<div class="btn cat" data-cat="${k}" style="position:absolute;left:${130 + i * 50}px;top:0;width:50px;height:44px">${P[k]}</div>`).join('')}
  <div class="btn arrow" id="next" title="Catégorie suivante" style="position:absolute;left:343px;top:9px">${P.right}</div>
  <div class="search" style="left:400px">${P.search}<input id="q" placeholder="Rechercher un objet" autocomplete="off"></div>
  ${c.shop ? `<div class="shopbtn" id="shop">${P.box}Inventaire boutique</div>` : ''}</div>
${eq('top', 183, 162, 80, 0)}${eq('left', 88, 251, 0, 80)}${eq('right', 436, 251, 0, 80)}
${stat(88, 'heart', 'Vie', d.vitals.health)}${stat(232, 'food', 'Faim', d.vitals.hunger)}${stat(374, 'drop', 'Soif', d.vitals.thirst)}
<div class="vest">${P.shield}Gilet<div class="sel" style="margin-left:6px">Style <b>${d.vitals.armor ? 12 : 0}</b> / 45 ${P.chev}</div><div class="sel">Variation <b>1</b> / 5 ${P.chev}</div><div class="ok">${P.check}</div></div>

${view === 'shop' ? shopHtml() : `<div class="pn" style="left:520px;top:162px;width:650px;height:${58 + rows * 91 + 3}px">
  <div class="ph"><h3>Inventaire</h3><div class="wt"><div class="bar2${pct > .5 ? '' : ' ok'}"><i style="width:${Math.min(100, pct * 100)}%"></i></div><span><b>${kg(d.weight)}</b> / ${d.maxWeight} kg</span><div class="srt" id="sort">${P.sort}</div></div></div>
  <div class="grid" style="top:58px;grid-template-columns:repeat(${cols},85px)" id="g_main">${Array.from({ length: mainCount }, (_, i) => slotHtml(bySlot[hotN + 1 + i], hotN + 1 + i, 'main')).join('')}</div>
</div>
${bag ? `<div class="pn" style="left:520px;top:600px;width:650px;height:244px"><div class="ph"><h3>Sac</h3><div class="wt"><div class="bar2 ok"><i style="width:${bag.weight / bag.max * 100}%"></i></div><span><b>${kg(bag.weight)}</b> / ${bag.max} kg</span><div class="srt">${P.sort}</div></div></div>
  <div class="grid" style="top:58px;grid-template-columns:repeat(${cols},85px)">${Array.from({ length: cols * 2 }, (_, i) => slotHtml(bag.items[i], 1000 + i, 'bag')).join('')}</div></div>` : ''}`}
<div class="pn" style="left:520px;top:856px;width:650px;height:134px">
  <div class="ph" style="height:40px"><h3>Raccourcis</h3><span class="sub">Glissez un objet pour l'assigner</span></div>
  <div class="grid" style="top:40px;left:10px;display:flex;gap:6px;width:640px">${Array.from({ length: hotN }, (_, i) => slotHtml(bySlot[i + 1], i + 1, 'hot', `<span class="key">Num ${i + 1}</span>`)).join('')}</div>
</div>

<div class="tabs">${[['eye', 'Aperçu'], ['chart', 'Compétences'], ['paw', 'Mascottes'], ['users', 'Joueurs']].map((t, i) => `<div class="tab${i === tab ? ' on' : ''}" data-tab="${i}">${P[t[0]]}${t[1]}</div>`).join('')}</div>
${tab === 0 ? `
<div class="pn sec" style="left:1182px;top:218px;width:650px;height:${warns.length ? 54 + warns.length * 54 : 90}px"><div class="ph" style="height:50px"><h3>À surveiller</h3><span class="sub">${warns.length} point${warns.length > 1 ? 's' : ''}</span></div>
 ${warns.length ? warns.map(w => `<div class="row" style="height:54px"><div class="im">${w.it ? icon(w.it) : P.box.replace('<svg', '<svg style="font-size:22px;color:#cfcfcf"')}</div><div class="tt"><b>${esc(w.t)}</b><s>${esc(w.s)}</s></div><div class="rt w">${esc(w.r)}</div></div>`).join('') : '<div class="empty">Rien à signaler.</div>'}</div>
<div class="pn sec" style="left:1182px;top:395px;width:650px;height:${48 + Math.max(1, rc.length) * 43}px"><div class="ph" style="height:48px"><h3>Reçu récemment</h3></div>
 ${rc.length ? rc.map(r => `<div class="row" style="height:43px"><div class="im">${icon(r)}</div><div class="tt"><b>${esc(r.label)}${r.count > 1 ? ' ×' + r.count : ''}</b></div><div class="ago">${ago(r.ago)}</div></div>`).join('') : '<div class="empty">Rien reçu pour le moment.</div>'}</div>
<div class="pn sec" style="left:1182px;top:591px;width:650px;height:${48 + Math.max(1, tops.length) * 43}px"><div class="ph" style="height:48px"><h3>Ce qui pèse le plus</h3><span class="sub">${kg(d.weight)} kg sur ${d.maxWeight} kg</span></div>
 ${tops.map(t => `<div class="row hv"><div class="im" style="position:absolute;left:12px;top:3px;width:36px;height:36px">${icon(t)}</div><span class="nm">${esc(t.label)}</span><span class="kg" style="position:absolute;right:16px;top:7px;font-weight:600;font-size:14px">${kg(t.weight)} kg</span><div class="bt" style="right:100px"><i style="width:${Math.min(100, t.weight / (tops[0].weight || 1) * 100)}%"></i></div></div>`).join('') || '<div class="empty">Inventaire vide.</div>'}</div>` : `<div class="pn" style="left:1182px;top:218px;width:650px;height:120px"><div class="empty" style="padding:44px 0;text-align:center">Bientôt disponible.</div></div>`}
<div class="hint"><span><i class="mouse">${P.mouse}</i>Déplacer</span><span><i class="mouse">${P.mouse}</i>Actions</span><span><i class="kb">Maj</i>+<i class="mouse">${P.mouse}</i>Tout transférer</span><span><i class="kb">Tab</i>Fermer</span></div>`;
    stage.hidden = false;
    wire();
}


function shopHtml() {
    const c = D.cfg, S = SHOP, items = S ? S.items.filter(matches) : [];
    const groups = {};
    items.forEach(it => (groups[it.group] = groups[it.group] || []).push(it));
    const order = Object.keys(groups).sort((a, b) => a === 'Objets' ? 1 : b === 'Objets' ? -1 : a.localeCompare(b));
    const pct = S && S.maxWeight ? S.weight / S.maxWeight : 0;
    const body = !S ? '<div class="empty">Chargement…</div>' : !S.items.length ? '<div class="empty" style="padding:60px 0;text-align:center">Ton inventaire boutique est vide.<br>Les objets achetés ou gagnés à la boutique arriveront ici.</div>'
        : order.map(g => `<div class="grp"><span>${esc(g)}</span><i>${groups[g].length}</i></div><div class="grid2" style="grid-template-columns:repeat(${c.cols},85px)">${groups[g].map(it => slotHtml(it, it.slot, 'shop')).join('')}</div>`).join('');
    return `<div class="pn" style="left:520px;top:162px;width:650px;height:682px"><div class="ph"><h3>Inventaire boutique</h3><span class="sub" style="display:flex;align-items:center;gap:6px">${P.lock}Privé : invisible en cas de fouille</span>
      <div class="wt"><span><b>${S ? kg(S.weight) : '0,00'}</b> / ${S ? kg(S.maxWeight).replace(',00', '') : ''} kg</span><div class="btn" id="back" style="height:32px">${P.left}Retour</div></div></div>
      <div class="shopbody">${body}</div></div>`;
}

function wire() {
    $('#cl').onclick = close;
    const q = $('#q'); q.value = query; q.oninput = () => { query = q.value.trim().toLowerCase(); softFilter(); };
    $('#c_all').onclick = () => { filter = 'all'; markCats(); softFilter(); };
    stage.querySelectorAll('[data-cat]').forEach(b => b.onclick = () => { filter = filter === b.dataset.cat ? 'all' : b.dataset.cat; markCats(); softFilter(); });
    stage.querySelectorAll('[data-tab]').forEach(b => b.onclick = () => { tab = +b.dataset.tab; render(); });
    const shop = $('#shop'); if (shop) shop.onclick = () => { view = 'shop'; SHOP = null; render(); post('shop'); };
    const back = $('#back'); if (back) back.onclick = () => { view = 'inv'; render(); };
    const sort = $('#sort'); if (sort) sort.onclick = () => post('sort');
    const ORD = ['all', 'food', 'shirt', 'target', 'tool'];
    const step = d => { const i = ORD.indexOf(filter); filter = ORD[Math.max(0, Math.min(ORD.length - 1, i + d))]; markCats(); softFilter(); };
    $('#prev').onclick = () => step(-1); $('#next').onclick = () => step(1);
    markCats();
    stage.querySelectorAll('.sl').forEach(el => {
        const it = itemOf(el);
        el.onmouseenter = e => it && showTip(it, e);
        el.onmousemove = e => it && moveTip(e);
        el.onmouseleave = hideTip;
        el.ondblclick = () => { if (!it) return; if (el.dataset.k === 'shop') withdraw(it, it.count); else post('use', { slot: it.slot }); };
        el.oncontextmenu = e => { e.preventDefault(); if (it && el.dataset.k === 'shop') withdraw(it, 1); };
        el.onclick = () => { if (it) { sel = it; stage.querySelectorAll('.sl.sel').forEach(s => s.classList.remove('sel')); el.classList.add('sel'); } };
        el.onmousedown = e => { if (e.button === 0 && it && el.dataset.k !== 'shop') startDrag(it, el, e); };
        el.addEventListener('click', e => { if (it && el.dataset.k === 'shop' && e.shiftKey) withdraw(it, it.count); });
    });
}
function markCats() {
    $('#c_all').classList.toggle('on', filter === 'all');
    const ORD = ['all', 'food', 'shirt', 'target', 'tool'], i = ORD.indexOf(filter);
    $('#prev').classList.toggle('off', i <= 0); $('#next').classList.toggle('off', i >= ORD.length - 1);
    stage.querySelectorAll('[data-cat]').forEach(b => b.classList.toggle('on', b.dataset.cat === filter));
}
function softFilter() {
    stage.querySelectorAll('.sl').forEach(el => { const it = itemOf(el); el.classList.toggle('dim', !!it && !matches(it)); });
}
function withdraw(it, n) { post('withdraw', { slot: it.slot, count: n }); }
function itemOf(el) {
    if (el.dataset.k === 'shop') return SHOP && SHOP.items.find(x => x.slot === +el.dataset.i); const i = +el.dataset.i; if (el.dataset.k === 'bag') return D.bag && D.bag.items[i - 1000]; return D.items.find(x => x.slot === i); }

// ───── infobulle ─────
let tip = null;
function showTip(it, e) { hideTip(); tip = document.createElement('div'); tip.className = 'tip'; tip.innerHTML = `<b>${esc(it.label)}</b><em>${it.count > 1 ? '×' + it.count + ' · ' : ''}${kg(it.weight)} kg · ' + (SHOP && view === 'shop' && it.group ? 'double-clic : récupérer (clic droit : 1)' : 'double-clic : utiliser') + '</em>`; document.body.appendChild(tip); moveTip(e); }
function moveTip(e) { if (tip) { tip.style.left = e.clientX + 16 + 'px'; tip.style.top = e.clientY + 12 + 'px'; } }
function hideTip() { if (tip) tip.remove(); tip = null; }

// ───── glisser-déposer : l'échange se fait côté serveur ─────
function startDrag(it, el, e) {
    const sx = e.clientX, sy = e.clientY; let g = null;
    const mv = ev => {
        if (!g && Math.hypot(ev.clientX - sx, ev.clientY - sy) > 6) { hideTip(); g = document.createElement('div'); g.className = 'drag'; g.innerHTML = icon(it); document.body.appendChild(g); el.style.opacity = .35; }
        if (g) { g.style.left = ev.clientX - 35 + 'px'; g.style.top = ev.clientY - 35 + 'px'; stage.querySelectorAll('.sl.hit').forEach(s => s.classList.remove('hit')); const t = document.elementFromPoint(ev.clientX, ev.clientY); const s = t && t.closest('.sl'); if (s && s !== el && s.dataset.k !== 'bag') s.classList.add('hit'); }
    };
    const up = ev => {
        removeEventListener('mousemove', mv); removeEventListener('mouseup', up);
        if (!g) return;
        g.remove(); el.style.opacity = '';
        const t = document.elementFromPoint(ev.clientX, ev.clientY), s = t && t.closest('.sl');
        stage.querySelectorAll('.sl.hit').forEach(x => x.classList.remove('hit'));
        if (s && s !== el && s.dataset.k !== 'bag' && el.dataset.k !== 'bag') {
            const to = +s.dataset.i, other = D.items.find(x => x.slot === to);
            post('swap', { from: it.slot, to });
            if (other) other.slot = it.slot; it.slot = to;      // aperçu immédiat
            render(); setTimeout(() => post('refresh'), 500);
        }
    };
    addEventListener('mousemove', mv); addEventListener('mouseup', up);
}

function close() { stage.hidden = true; hideTip(); post('close'); }
addEventListener('keydown', e => { if ((e.key === 'Escape' || e.key === 'Tab') && !stage.hidden) { e.preventDefault(); close(); } });
addEventListener('message', e => {
    const m = e.data;
    if (m.a === 'open') { D = m.data; filter = 'all'; query = ''; tab = 0; sel = null; view = 'inv'; SHOP = null; render(); }
    else if (m.a === 'update') { D = m.data; if (!drag) render(); }
    else if (m.a === 'goshop') { view = 'shop'; SHOP = null; render(); }
    else if (m.a === 'shop') { SHOP = m.shop; render(); }
    else if (m.a === 'close') { stage.hidden = true; hideTip(); }
});

// ───── démonstration (navigateur seulement) ─────
if (!IN_GAME) {
    const it = (slot, name, label, count, weight, extra) => Object.assign({ slot, name, label, count, weight }, extra || {});
    D = {
        name: 'Maly Pablo', money: 0, weight: 9.23, maxWeight: 10,
        items: [it(1, 'weapon_akpixel', 'AKPixel', 1, 3.3, { durability: 85, ammo: 0 }),
        it(6, 'phone', 'Téléphone', 1, .2), it(7, 'passport', 'Passeport', 1, .1), it(8, 'mask', 'Cagoule', 1, .1), it(9, 'radio', 'Talkie-walkie', 1, .3), it(10, 'outfit', 'Tenue', 1, .8), it(11, 'outfit2', 'Tenue', 1, .8), it(12, 'bag', 'f4', 1, 8.89),
        it(13, 'mask2', 'Cagoule', 1, .1), it(14, 'outfit3', 'Tenue', 1, .8), it(15, 'outfit4', 'Tenue', 1, .8), it(16, 'hat', 'Chapeau', 1, .1), it(18, 'water', 'Eau', 2, .5), it(19, 'ego', 'Barre Ego Chaser', 3, .3),
        it(20, 'radio', 'Talkie-walkie', 1, .3), it(21, 'radio', 'Talkie-walkie', 1, .3)],
        bag: { weight: 8.54, max: 80, items: [it(1, 'outfit', 'Tenue', 1, 0.8), it(2, 'necklace', 'Collier', 1, .1), it(3, 'outfit', 'Tenue', 1, .8), it(4, 'outfit', 'Tenue', 1, .8), it(5, 'outfit', 'Tenue', 1, .8), it(6, 'outfit', 'Tenue', 1, .8), it(7, 'outfit', 'Tenue', 1, .8), it(8, 'outfit', 'Tenue', 1, .8), it(9, 'toolbox', 'Caisse à outils', 2, 2)] },
        vitals: { health: 12, hunger: 3, thirst: 4, armor: 1 },
        equipment: {
            top: [{ label: 'Tenue', worn: true }, { label: 'Parachute' }, { label: 'Perruque' }],
            left: ['Chapeau', 'Lunettes', 'Accessoire', 'Haut', 'Pantalon', 'Chaussures'].map(l => ({ label: l })),
            right: ['Masque', 'Boucles', 'Sac', 'Gilet', 'Bracelet', 'Montre'].map(l => ({ label: l })),
        },
        recent: [{ name: 'ego', label: 'Barre Ego Chaser', count: 3, ago: 70 }, { name: 'radio', label: 'Talkie-walkie', count: 1, ago: 70 }, { name: 'radio', label: 'Talkie-walkie', count: 1, ago: 70 }],
        cfg: { brand: 'Sensity', shortcuts: 7, cols: 7, rows: 4, warn: .85, recentCount: 3, shop: true, img: null },
    };
    D.items.forEach(x => { if (x.name === 'weapon_akpixel') x.slot = 1; });
    SHOP = { weight: 4.2, maxWeight: 500, items: [
        { slot: 1, name: 'weapon_ak', label: 'AK-47', count: 1, weight: 3300, group: 'Armes' }, { slot: 2, name: 'weapon_pistol', label: 'Pistolet', count: 1, weight: 900, group: 'Armes' },
        { slot: 3, name: 'crate1', label: 'Caisse rare', count: 3, weight: 0, group: 'Caisses et packs' }, { slot: 4, name: 'pack1', label: 'Pack débutant', count: 1, weight: 0, group: 'Caisses et packs' },
        { slot: 5, name: 'medikit', label: 'Kit de soin', count: 5, weight: 0, group: 'Consommables' }, { slot: 6, name: 'water', label: 'Eau', count: 12, weight: 0, group: 'Consommables' }, { slot: 7, name: 'goldbar', label: 'Lingot', count: 2, weight: 0, group: 'Objets' }] };
    if (location.search.includes('shop')) view = 'shop';
    render();
}
