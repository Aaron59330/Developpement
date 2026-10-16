'use strict';
/* Interface CarPlay (autoradio) — l'état vient du serveur (state bag du véhicule), l'interface ne fait qu'envoyer des demandes. */
const $root = document.getElementById('root');
const $toast = document.getElementById('toast');
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const res = () => (typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_core');
const post = (name, body) => fetch(`https://${res()}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) }).then(r => r.json()).catch(() => ({}));
const cmd = (action, a, b) => post('cmd', { action, a, b });

const I = {
  music: '<path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>',
  radio: '<path d="M4 9h16a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-9a1 1 0 0 1 1-1z"/><path d="m4 9 14-6"/><circle cx="9" cy="14.5" r="2.5"/><path d="M15 13h3M15 16h3"/>',
  list: '<path d="M8 6h13M8 12h13M8 18h13"/><path d="M3 6h.01M3 12h.01M3 18h.01"/>',
  heart: '<path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 0 0-7.8 7.8l1 1.1L12 21l7.8-7.5 1-1.1a5.5 5.5 0 0 0 0-7.8z"/>',
  clock: '<circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>',
  search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
  gear: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>',
  play: '<polygon points="7 4 20 12 7 20 7 4" fill="currentColor"/>',
  pause: '<rect x="6" y="4" width="4" height="16" rx="1" fill="currentColor"/><rect x="14" y="4" width="4" height="16" rx="1" fill="currentColor"/>',
  next: '<polygon points="5 4 15 12 5 20 5 4" fill="currentColor"/><path d="M19 5v14"/>',
  prev: '<polygon points="19 20 9 12 19 4 19 20" fill="currentColor"/><path d="M5 19V5"/>',
  shuffle: '<path d="M16 3h5v5M4 20 21 3M21 16v5h-5M15 15l6 6M4 4l5 5"/>',
  loop: '<path d="m17 2 4 4-4 4"/><path d="M3 11v-1a4 4 0 0 1 4-4h14M7 22l-4-4 4-4"/><path d="M21 13v1a4 4 0 0 1-4 4H3"/>',
  vol: '<path d="M11 5 6 9H2v6h4l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7M18.5 5.5a9 9 0 0 1 0 13"/>',
  mute: '<path d="M11 5 6 9H2v6h4l5 4z"/><path d="m22 9-6 6M16 9l6 6"/>',
  x: '<path d="M18 6 6 18M6 6l12 12"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  power: '<path d="M18.4 6.6a9 9 0 1 1-12.8 0M12 2v10"/>',
  car: '<path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"/><circle cx="7" cy="17" r="2"/><path d="M9 17h6"/><circle cx="17" cy="17" r="2"/>',
  bt: '<path d="m7 7 10 10-5 5V2l5 5L7 17"/>',
  trash: '<path d="M3 6h18M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/>',
};
const ic = (n, s) => `<svg viewBox="0 0 24 24" class="ic" ${s ? `style="width:${s}px;height:${s}px"` : ''}>${I[n] || I.music}</svg>`;
const fmt = sec => { sec = Math.max(0, Math.floor(sec || 0)); const m = Math.floor(sec / 60), s = sec % 60; return `${m}:${String(s).padStart(2, '0')}`; };

const S = { open: false, netId: null, st: null, veh: {}, lib: { favorites: [], history: [] }, presets: [], canSearch: false, canControl: true, personal: { vol: 100, toast: true }, page: 'now', results: null, searching: false, maxQueue: 40 };

const current = () => (S.st && S.st.queue && S.st.queue[S.st.index - 1]) || null;   // index : 1 = premier titre (numérotation Lua)
const posNow = () => { const st = S.st; if (!st) return 0; return Math.max(0, st.playing ? Engine.cloud() - st.startedAt : st.pausedAt || 0); };
const isFav = t => t && S.lib.favorites.some(f => f.kind === t.kind && f.ref === t.ref);
const art = t => (t && t.thumb ? `<img src="${esc(t.thumb)}" alt="" onerror="this.style.display='none'">` : ic(t && t.kind === 'direct' ? 'radio' : 'music', 22));
const eq = `<span class="eq"><i></i><i></i><i></i><i></i></span>`;

function rescale() {
  const s = Math.min(window.innerWidth / 1160, window.innerHeight / 700, 1.3);
  document.documentElement.style.setProperty('--s', String(s));
}
window.addEventListener('resize', rescale); rescale();

/* ─────────────── squelette ─────────────── */
const PAGES = [['now', 'music', 'Lecture'], ['radios', 'radio', 'Radios'], ['queue', 'list', 'File'], ['favs', 'heart', 'Favoris'], ['hist', 'clock', 'Récents'], ['search', 'search', 'Recherche'], ['settings', 'gear', 'Réglages']];

function frame() {
  const t = current();
  $root.innerHTML = `<div class="cp-wrap"><div class="cp-screen">
    <div class="cp-bg" id="cp-bg">${t && t.thumb ? `<img src="${esc(t.thumb)}" alt="">` : ''}</div><div class="cp-shade"></div>
    <div class="cp-top"><div class="cp-car">${ic('car', 18)}<b>${esc(S.veh.label || 'Véhicule')}</b><small>${esc(S.veh.plate || '')}</small></div>
      <div class="cp-sp"></div><div class="cp-stat">${ic('bt', 14)}<span>Connecté</span></div><div class="cp-clock" id="cp-clock"></div>
      <button class="cp-x" data-a="close" title="Fermer (Échap)">${ic('x', 18)}</button></div>
    <nav class="cp-dock">${PAGES.filter(p => p[0] !== 'search' || S.canSearch).map(([id, icon, l]) => `<button class="cp-nav ${S.page === id ? 'on' : ''}" data-a="page" data-v="${id}">${ic(icon, 22)}<span>${l}</span></button>`).join('')}</nav>
    <main class="cp-main" id="cp-main"></main></div></div>`;
  page();
  clock();
}

function page() {
  const m = document.getElementById('cp-main');
  if (!m) return;
  m.dataset.page = S.page;
  m.innerHTML = ({ now: pNow, radios: pRadios, queue: pQueue, favs: () => pLib('favs'), hist: () => pLib('hist'), search: pSearch, settings: pSettings }[S.page] || pNow)();
  if (S.page === 'now') tick();
}

const lock = () => (S.canControl ? '' : 'disabled');

/* ─────────────── pages ─────────────── */
function pNow() {
  const st = S.st || {}, t = current(), on = st.on !== false;
  const dis = lock();
  return `<div class="np">
    <div class="np-art ${t ? '' : 'empty'}" id="np-art">${t && t.thumb ? art(t) : ic('music', 64)}${t && st.playing ? eq : ''}</div>
    <div class="np-info">
      <div class="np-kicker" id="np-kick">${t ? (t.kind === 'yt' ? 'YouTube' : 'Flux audio') : 'CarPlay'}${t && t.by ? ` · ajouté par ${esc(t.by)}` : ''}</div>
      <h1 id="np-title">${t ? esc(t.title) : 'Aucun titre'}</h1>
      <p id="np-author">${t ? esc(t.author || '') : 'Colle un lien ou choisis une radio.'}</p>
      <div class="np-bar"><span id="np-pos">0:00</span><input type="range" id="np-seek" min="0" max="1" step="1" value="0" ${dis} ${t ? '' : 'disabled'}><span id="np-dur">0:00</span></div>
      <div class="np-ctl">
        <button class="ct ${st.shuffle ? 'act' : ''}" data-a="shuffle" ${dis} title="Aléatoire">${ic('shuffle', 20)}</button>
        <button class="ct" data-a="prev" ${dis} title="Précédent">${ic('prev', 24)}</button>
        <button class="ct big" data-a="toggle" id="np-play" ${dis} title="Lecture / pause">${ic(st.playing ? 'pause' : 'play', 30)}</button>
        <button class="ct" data-a="next" ${dis} title="Suivant">${ic('next', 24)}</button>
        <button class="ct ${st.loop && st.loop !== 'off' ? 'act' : ''}" data-a="loop" ${dis} title="Répéter">${ic('loop', 20)}${st.loop === 'one' ? '<em>1</em>' : ''}</button>
      </div>
      <div class="np-vol">
        <button class="ct sm" data-a="mute" ${dis}>${ic((st.volume || 0) === 0 ? 'mute' : 'vol', 20)}</button>
        <button class="ct sm" data-a="vdown" ${dis}>−</button>
        <input type="range" id="np-vol" min="0" max="100" step="1" value="${st.volume ?? 50}" style="--p:${st.volume ?? 50}%" ${dis}>
        <button class="ct sm" data-a="vup" ${dis}>+</button>
        <b id="np-vv">${st.volume ?? 50}</b>
        <span class="sp"></span>
        <button class="ct sm ${isFav(t) ? 'fav' : ''}" data-a="fav" ${t ? '' : 'disabled'} title="Favori">${ic('heart', 20)}</button>
        <button class="ct sm ${on ? 'act' : ''}" data-a="power" ${dis} title="Autoradio">${ic('power', 20)}</button>
      </div>
      <div class="np-add">
        <input id="np-url" type="text" maxlength="300" placeholder="Colle un lien YouTube ou un flux audio (.mp3, radio…)" spellcheck="false">
        <button class="pri" data-a="playUrl" ${dis}>${ic('play', 16)} Lire</button>
        <button data-a="addUrl" ${dis}>${ic('plus', 16)} File</button>
      </div>
      ${S.canControl ? '' : '<p class="note">Seul le conducteur peut piloter la musique.</p>'}
    </div></div>`;
}

function trackRow(t, o = {}) {
  return `<div class="row ${o.cur ? 'cur' : ''}" ${o.click ? `data-a="${o.click}" data-i="${o.i}"` : ''}>
    <div class="th">${art(t)}${o.cur ? eq : ''}</div>
    <div class="g"><b>${esc(t.title)}</b><small>${esc(t.author || '')}${t.by ? ` · ${esc(t.by)}` : ''}</small></div>
    <div class="rb">${o.btns || ''}</div></div>`;
}

function pQueue() {
  const st = S.st || {}, q = st.queue || [];
  const dis = lock();
  return `<div class="pg-h"><h2>File d'attente</h2><small>${q.length} / ${S.maxQueue}</small><span class="sp"></span><button data-a="clear" ${dis} ${q.length ? '' : 'disabled'}>${ic('trash', 16)} Vider</button></div>
    <div class="list">${q.map((t, i) => trackRow(t, { click: 'playIndex', i: i + 1, cur: i + 1 === st.index, btns: `<button class="ib" data-a="remove" data-i="${i + 1}" ${dis} title="Retirer">${ic('x', 16)}</button>` })).join('') || '<p class="empty">La file est vide.<br>Ajoute un lien depuis « Lecture ».</p>'}</div>`;
}

function pLib(kind) {
  const list = kind === 'favs' ? S.lib.favorites : S.lib.history;
  const dis = lock();
  return `<div class="pg-h"><h2>${kind === 'favs' ? 'Favoris' : 'Récemment écoutés'}</h2><small>${list.length}</small></div>
    <div class="list">${list.map((t, i) => trackRow(t, { btns: `<button class="ib" data-a="libPlay" data-k="${kind}" data-i="${i}" ${dis} title="Lire maintenant">${ic('play', 16)}</button><button class="ib" data-a="libAdd" data-k="${kind}" data-i="${i}" ${dis} title="Ajouter à la file">${ic('plus', 16)}</button><button class="ib ${isFav(t) ? 'fav' : ''}" data-a="libFav" data-k="${kind}" data-i="${i}" title="Favori">${ic('heart', 16)}</button>` })).join('') || `<p class="empty">${kind === 'favs' ? 'Aucun favori.<br>Touche le cœur sur un titre pour le garder.' : 'Rien pour le moment.'}</p>`}</div>`;
}

function pRadios() {
  const dis = lock();
  return `<div class="pg-h"><h2>Radios & ambiances</h2><small>Un clic pour lancer</small></div>
    <div class="cards">${S.presets.map((p, i) => `<button class="card" data-a="preset" data-i="${i}" ${dis} style="--c:${esc(p.color || '#00a4ff')}"><span class="cic">${ic('radio', 26)}</span><b>${esc(p.label)}</b><small>${esc(p.sub || '')}</small></button>`).join('') || '<p class="empty">Aucune radio configurée.</p>'}</div>`;
}

function pSearch() {
  const dis = lock();
  const r = S.results;
  return `<div class="pg-h"><h2>Recherche YouTube</h2></div>
    <div class="np-add"><input id="se-q" type="text" maxlength="80" placeholder="Titre, artiste…" spellcheck="false"><button class="pri" data-a="doSearch">${ic('search', 16)} Chercher</button></div>
    <div class="list" id="se-res">${S.searching ? '<p class="empty">Recherche…</p>' : r ? (r.length ? r.map((t, i) => trackRow(t, { btns: `<button class="ib" data-a="resPlay" data-i="${i}" ${dis}>${ic('play', 16)}</button><button class="ib" data-a="resAdd" data-i="${i}" ${dis}>${ic('plus', 16)}</button><button class="ib ${isFav(t) ? 'fav' : ''}" data-a="resFav" data-i="${i}">${ic('heart', 16)}</button>` })).join('') : '<p class="empty">Aucun résultat.</p>') : '<p class="empty">Tape un titre puis Entrée.</p>'}</div>`;
}

function pSettings() {
  const st = S.st || {}, dis = lock();
  return `<div class="pg-h"><h2>Réglages</h2></div><div class="set">
    <div class="srow"><div><b>Mon volume d'écoute</b><small>Ne change que ce que TU entends (pas les autres passagers).</small></div><div class="sc"><input type="range" id="st-vol" min="0" max="100" value="${S.personal.vol}" style="--p:${S.personal.vol}%"><b id="st-vv">${S.personal.vol}</b></div></div>
    <div class="srow"><div><b>Bandeau « en cours de lecture »</b><small>Petite notification à chaque nouveau titre.</small></div><button class="sw ${S.personal.toast ? 'on' : ''}" data-a="toggleToast"><i></i></button></div>
    <div class="srow"><div><b>Haut-parleurs extérieurs</b><small>Les joueurs autour du véhicule entendent la musique (étouffée si portes et toit fermés).</small></div><button class="sw ${st.speakers !== false ? 'on' : ''}" data-a="speakers" ${dis}><i></i></button></div>
    <div class="srow"><div><b>Autoradio</b><small>Éteindre arrête la musique et vide la file.</small></div><button class="sw ${st.on !== false ? 'on' : ''}" data-a="power" ${dis}><i></i></button></div>
    <p class="note">La musique s'entend de la même façon pour tous les joueurs proches, synchronisée. Un titre YouTube dont le propriétaire a bloqué l'intégration est passé automatiquement.</p></div>`;
}

/* ─────────────── mises à jour dynamiques (page « Lecture ») ─────────────── */
function tick() {
  if (!S.open || S.page !== 'now') return;
  const st = S.st || {}, t = current();
  const pos = posNow(), dur = (t && t.dur) || 0;
  const seek = document.getElementById('np-seek');
  if (seek) {
    seek.max = String(dur > 0 ? dur : Math.max(60, Math.ceil(pos) + 30));
    if (!seek.dataset.drag) seek.value = String(Math.min(pos, Number(seek.max)));
    const p = dur > 0 ? Math.min(100, pos / dur * 100) : 0;
    seek.style.setProperty('--p', `${p}%`);
  }
  const a = document.getElementById('np-pos'), b = document.getElementById('np-dur');
  if (a) a.textContent = fmt(pos);
  if (b) b.textContent = t ? (t.dur === 0 ? 'EN DIRECT' : dur > 0 ? fmt(dur) : '—:—') : '0:00';
}
setInterval(tick, 400);

function clock() { const e = document.getElementById('cp-clock'); if (e) e.textContent = new Date().toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }); }
setInterval(clock, 5000);

let lastKey = '';
function onState() {
  const t = current(), st = S.st || {};
  const key = [t && t.id, t && t.title, t && t.author, st.playing, st.volume, st.loop, st.shuffle, st.on, st.speakers, (st.queue || []).length, st.index, isFav(t), S.canControl].join('|');
  const changedTrack = key.split('|').slice(0, 3).join('|') !== lastKey.split('|').slice(0, 3).join('|');
  const bg = document.getElementById('cp-bg');
  if (bg && changedTrack) bg.innerHTML = t && t.thumb ? `<img src="${esc(t.thumb)}" alt="">` : '';
  if (key === lastKey) return;
  lastKey = key;
  if (S.page === 'now' || S.page === 'queue' || S.page === 'settings') {
    const main = document.getElementById('cp-main');
    const keep = document.getElementById('np-url');
    const val = keep ? keep.value : '', focused = keep && document.activeElement === keep;
    const sc = main ? main.scrollTop : 0;
    page();
    const nu = document.getElementById('np-url');
    if (nu && val) { nu.value = val; if (focused) nu.focus(); }
    if (main) main.scrollTop = sc;
  }
}

/* ─────────────── bandeau de titre ─────────────── */
let toastT = null;
function showToast(t) {
  if (!t) return;
  $toast.innerHTML = `<div class="tt-art">${t.thumb ? `<img src="${esc(t.thumb)}" alt="" onerror="this.style.display='none'">` : ic('music', 22)}</div><div class="tt-i"><small>${ic('music', 12)} CarPlay</small><b>${esc(t.title)}</b><span>${esc(t.author || '')}</span></div>`;
  $toast.classList.remove('hidden');
  requestAnimationFrame(() => $toast.classList.add('in'));
  clearTimeout(toastT);
  toastT = setTimeout(() => { $toast.classList.remove('in'); setTimeout(() => $toast.classList.add('hidden'), 400); }, 4500);
}

/* ─────────────── actions ─────────────── */
function trackArgs(t) { return t.kind === 'yt' ? `https://www.youtube.com/watch?v=${t.ref}` : t.ref; }
let volT = null;
function sendVol(v) { clearTimeout(volT); volT = setTimeout(() => cmd('volume', v), 90); }

document.addEventListener('click', e => {
  const el = e.target.closest('[data-a]');
  if (!el || !S.open) return;
  const a = el.dataset.a, i = Number(el.dataset.i), st = S.st || {}, t = current();
  const lib = k => (k === 'favs' ? S.lib.favorites : S.lib.history)[i];
  switch (a) {
    case 'close': return post('close');
    case 'page': S.page = el.dataset.v; lastKey = ''; return frame();
    case 'toggle': return cmd(st.playing ? 'pause' : 'resume');
    case 'next': return cmd('next');
    case 'prev': return cmd('prev');
    case 'shuffle': return cmd('shuffle', !st.shuffle);
    case 'loop': return cmd('loop', st.loop === 'off' || !st.loop ? 'all' : st.loop === 'all' ? 'one' : 'off');
    case 'mute': return cmd('volume', (st.volume || 0) === 0 ? 50 : 0);
    case 'vdown': return cmd('volume', Math.max(0, (st.volume || 0) - 5));
    case 'vup': return cmd('volume', Math.min(100, (st.volume || 0) + 5));
    case 'power': return cmd('power', !(st.on !== false));
    case 'speakers': return cmd('speakers', !(st.speakers !== false));
    case 'playUrl': case 'addUrl': { const u = document.getElementById('np-url'); if (u && u.value.trim()) { cmd(a === 'playUrl' ? 'playNow' : 'add', u.value.trim()); u.value = ''; } return; }
    case 'fav': if (t) { post('fav', { op: isFav(t) ? 'remove' : 'add', kind: t.kind, ref: t.ref, title: t.title, author: t.author, thumb: t.thumb }); } return;
    case 'playIndex': return cmd('playIndex', i);
    case 'remove': e.stopPropagation(); return cmd('remove', i);
    case 'clear': return cmd('clear');
    case 'preset': return cmd('playNow', (S.presets[i] || {}).url);
    case 'libPlay': { const x = lib(el.dataset.k); if (x) cmd('playNow', trackArgs(x)); return; }
    case 'libAdd': { const x = lib(el.dataset.k); if (x) cmd('add', trackArgs(x)); return; }
    case 'libFav': { const x = lib(el.dataset.k); if (x) post('fav', { op: isFav(x) ? 'remove' : 'add', kind: x.kind, ref: x.ref, title: x.title, author: x.author, thumb: x.thumb }); return; }
    case 'resPlay': { const x = (S.results || [])[i]; if (x) cmd('playNow', trackArgs(x)); return; }
    case 'resAdd': { const x = (S.results || [])[i]; if (x) cmd('add', trackArgs(x)); return; }
    case 'resFav': { const x = (S.results || [])[i]; if (x) post('fav', { op: isFav(x) ? 'remove' : 'add', kind: x.kind, ref: x.ref, title: x.title, author: x.author, thumb: x.thumb }); return; }
    case 'doSearch': return doSearch();
    case 'toggleToast': S.personal.toast = !S.personal.toast; post('personal', { toast: S.personal.toast }); return page();
  }
});

async function doSearch() {
  const q = (document.getElementById('se-q') || {}).value || '';
  if (q.trim().length < 2) return;
  S.searching = true; S.results = null; page();
  const r = await post('search', { q });
  S.searching = false;
  if (r && r.ok) S.results = r.results || []; else { S.results = []; showToast({ title: 'Recherche impossible', author: (r && r.error) || 'Erreur' }); }
  page();
  const e = document.getElementById('se-q'); if (e) e.value = q;
}

// curseurs : position (envoyée au relâchement), volume du véhicule, volume perso
document.addEventListener('input', e => {
  const el = e.target;
  if (el.id === 'np-vol') { el.style.setProperty('--p', el.value + '%'); document.getElementById('np-vv').textContent = el.value; sendVol(Number(el.value)); }
  else if (el.id === 'np-seek') { el.dataset.drag = '1'; document.getElementById('np-pos').textContent = fmt(Number(el.value)); }
  else if (el.id === 'st-vol') { el.style.setProperty('--p', el.value + '%'); S.personal.vol = Number(el.value); document.getElementById('st-vv').textContent = el.value; clearTimeout(volT); volT = setTimeout(() => post('personal', { vol: S.personal.vol }), 120); }
});
document.addEventListener('change', e => {
  if (e.target.id === 'np-seek') { const v = Number(e.target.value); delete e.target.dataset.drag; cmd('seek', v); }
});
document.addEventListener('focusin', e => { if (e.target.matches && e.target.matches('input[type=text]')) post('inputFocus', { on: true }); });
document.addEventListener('focusout', e => { if (e.target.matches && e.target.matches('input[type=text]')) post('inputFocus', { on: false }); });
document.addEventListener('keydown', e => {
  if (!S.open) return;
  if (e.key === 'Enter' && e.target.id === 'np-url') { const v = e.target.value.trim(); if (v) { cmd('playNow', v); e.target.value = ''; } }
  else if (e.key === 'Enter' && e.target.id === 'se-q') doSearch();
  else if (e.key === 'Escape') { if (document.activeElement && document.activeElement.blur) document.activeElement.blur(); post('close'); }
});

/* ─────────────── messages du jeu ─────────────── */
window.addEventListener('message', ev => {
  const d = ev.data || {};
  if (d.now) Engine.sync(d.now);
  switch (d.t) {
    case 'ping': console.log('[carplay] interface chargée (ping reçu)'); return;
    case 'engine': return Engine.update(d.ch, d.now);
    case 'toast': return showToast(d.track);
    case 'open':
      Object.assign(S, { open: true, netId: d.netId, st: d.st || null, veh: d.veh || {}, lib: d.lib || S.lib, presets: d.presets || [], canSearch: !!d.canSearch, canControl: d.canControl !== false, personal: d.personal || S.personal, maxQueue: d.maxQueue || 40, page: 'now', results: null });
      lastKey = '';
      $root.classList.remove('hidden');
      frame();
      return;
    case 'state': S.st = d.st || null; return S.open && onState();
    case 'lib': S.lib = d.lib || S.lib; if (S.open && (S.page === 'favs' || S.page === 'hist' || S.page === 'now' || S.page === 'search')) { lastKey = ''; page(); } return;
    case 'caps': S.canSearch = !!d.canSearch; return S.open && frame();
    case 'close': S.open = false; $root.classList.add('hidden'); $root.innerHTML = ''; return;
  }
});
