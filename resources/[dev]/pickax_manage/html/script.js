'use strict';
const $r = document.getElementById('root');
const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const post = (n, b) => { try { return fetch('https://pickax_manage/' + n, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(b || {}) }).then(r => r.json()).catch(() => ({})); } catch (e) { return Promise.resolve({}); } };
const P = {
  tool: 'M14.7 6.3a4 4 0 0 0-5.4 5.4L3 18l3 3 6.3-6.3a4 4 0 0 0 5.4-5.4l-3 3-2-2z', cart: 'M3 4h3l2 12h11l2-8H7M9 20h.01M18 20h.01', calendar: 'M4 6h16v14H4zM4 10h16M8 3v4M16 3v4', game: 'M6 9h12a4 4 0 0 1 4 4v2a3 3 0 0 1-5 2l-1-1H8l-1 1a3 3 0 0 1-5-2v-2a4 4 0 0 1 4-4zM8 11v4M6 13h4', layers: 'M12 3l9 5-9 5-9-5zM3 13l9 5 9-5',
  server: 'M3 5h18v6H3zM3 13h18v6H3zM7 8h.01M7 16h.01', list: 'M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01', megaphone: 'M3 11v2a1 1 0 0 0 1 1h2l5 4V6L6 10H4a1 1 0 0 0-1 1zM15 8a5 5 0 0 1 0 8',
  refresh: 'M21 12a9 9 0 1 1-3-6.7L21 8M21 3v5h-5', shield: 'M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z', save: 'M5 3h12l4 4v14H3V3zM7 3v6h8V3M7 21v-7h10v7', heart: 'M12 20s-7-4.5-9-9a5 5 0 0 1 9-3 5 5 0 0 1 9 3c-2 4.5-9 9-9 9z',
  brush: 'M18 3l3 3-9 9-3-3zM9 12c-3 0-4 2-4 4s-1 3-2 4c3 1 8 0 8-4', palette: 'M12 3a9 9 0 1 0 0 18c1.5 0 2-1 1.5-2s0-2 1.5-2H18a3 3 0 0 0 3-3c0-5-4-11-9-11zM7.5 11h.01M10 7.5h.01M15 7.5h.01',
  image: 'M3 5h18v14H3zM3 16l5-5 5 5 3-3 5 5M9 9h.01', gauge: 'M12 14l4-4M3.5 17a9 9 0 1 1 17 0', clock: 'M12 7v5l3 2M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z',
  users: 'M16 20v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 10a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM22 20v-2a4 4 0 0 0-3-3.9M16 2.1a4 4 0 0 1 0 7.8', user: 'M20 21a8 8 0 0 0-16 0M12 12a5 5 0 1 0 0-10 5 5 0 0 0 0 10z',
  camera: 'M4 7h3l2-3h6l2 3h3v13H4zM12 17a4 4 0 1 0 0-8 4 4 0 0 0 0 8z', target: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 16a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM12 12h.01',
  coins: 'M12 8c4.4 0 8-1.3 8-3s-3.6-3-8-3-8 1.3-8 3 3.6 3 8 3zM4 5v6c0 1.7 3.6 3 8 3s8-1.3 8-3V5M4 11v6c0 1.7 3.6 3 8 3s8-1.3 8-3v-6', eye: 'M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z',
  briefcase: 'M3 8h18v12H3zM8 8V5h8v3M3 14h18', skull: 'M12 3a8 8 0 0 0-5 14v3h10v-3a8 8 0 0 0-5-14zM9 12h.01M15 12h.01', globe: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18',
  cloud: 'M7 18a5 5 0 1 1 1-9.9A6 6 0 0 1 20 11a3.5 3.5 0 0 1-1 7z', mountain: 'M3 19l6-11 4 7 3-4 5 8z', pin: 'M12 21s7-6 7-11a7 7 0 0 0-14 0c0 5 7 11 7 11zM12 12a2 2 0 1 0 0-4 2 2 0 0 0 0 4z',
  polygon: 'M5 4l14 3 1 11-12 2-3-9z', ball: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 8l4 3-1.5 4.5h-5L8 11z', music: 'M9 18V5l11-2v13M9 18a3 3 0 1 1-3-3 3 3 0 0 1 3 3zM20 16a3 3 0 1 1-3-3 3 3 0 0 1 3 3z',
  ghost: 'M5 21V11a7 7 0 0 1 14 0v10l-3-2-2 2-2-2-2 2-2-2zM9.5 11h.01M14.5 11h.01', chat: 'M4 5h16v11H9l-5 4zM8 9h8M8 12h5', lock: 'M5 11h14v10H5zM8 11V7a4 4 0 0 1 8 0v4',
  building: 'M4 21V4h10v17M14 9h6v12M8 8h2M8 12h2M8 16h2', hand: 'M8 13V5a1.5 1.5 0 0 1 3 0v6M11 10V3.5a1.5 1.5 0 0 1 3 0V10M14 10V5.5a1.5 1.5 0 0 1 3 0V13c0 5-2 8-6 8-3 0-4-2-6-5l-1-2a1.5 1.5 0 0 1 2.5-1.5L8 13',
  home: 'M3 11l9-8 9 8M5 10v10h14V10', search: 'M21 21l-4.3-4.3M17 10.5a6.5 6.5 0 1 1-13 0 6.5 6.5 0 0 1 13 0z', hist: 'M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5M12 7v5l3 2',
  mute: 'M11 5L6 9H3v6h3l5 4zM22 9l-6 6M16 9l6 6', back: 'M15 18l-6-6 6-6', fwd: 'M9 18l6-6-6-6', grid: 'M3 3h7v7H3zM14 3h7v7h-7zM14 14h7v7h-7zM3 14h7v7H3z', x: 'M18 6L6 18M6 6l12 12'
};
const ic = n => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="${P[n] || P.grid}"/></svg>`;
let S = { view: null, set: null, open: false, d: null, server: {}, cats: [], cat: null, q: '', timer: null, clock: null, hist: [] };
const pad = n => String(n).padStart(2, '0');
const hms = s => `${pad(Math.floor(s / 3600))}:${pad(Math.floor(s % 3600 / 60))}:${pad(s % 60)}`;
const hm = d => `${pad(d.getHours())}:${pad(d.getMinutes())}`;
const toast = t => { const e = document.createElement('div'); e.className = 'toast'; e.textContent = t; document.body.append(e); setTimeout(() => e.remove(), 1800); };


// ───────── Éditeur de réglages en direct (pickax_settings) ─────────
const arr = v => Array.isArray(v) ? v : (v && typeof v === 'object' ? Object.values(v) : []);
async function loadSettings(force) {
  if (S.set && !force && !S.set.error) return;
  S.set = { loading: true }; draw();
  const d = await post('settings');
  S.set = d && d.schema ? { schema: d.schema, values: d.values || {}, over: d.over || {} } : { error: (d && d.error) || 'Réglages indisponibles.' };
  draw();
}
function openSettings(target, title) { S.view = { group: target.group, section: target.section || null, title: title || target.section || target.group }; S.q = ''; S.focusQ = false; loadSettings(); draw(); }
async function send(tbl) {
  const r = await post('set', { tbl });
  if (r && r.ok) { Object.assign(S.set.values, r.values); for (const k in tbl) { if (r.over && r.over[k]) S.set.over[k] = true; else delete S.set.over[k]; } toast('Enregistré · appliqué en direct'); }
  else toast('Échec de l’enregistrement');
  draw();
}
const fmtN = (d, v) => { const st = d.step || 1, dec = String(st).includes('.') ? String(st).split('.')[1].length : 0; return Number(v).toFixed(dec); };
function ctrl(d) {
  const val = S.set.values[d.key], k = esc(d.key);
  if (d.type === 'bool') return `<button class="tg ${val ? 'on' : ''}" data-tg="${k}" aria-label="${esc(d.label)}"><i></i></button>`;
  if (d.type === 'number') return `<input type="range" data-rg="${k}" min="${d.min ?? 0}" max="${d.max ?? 100}" step="${d.step || 1}" value="${val ?? d.default}"><input class="nm" type="number" data-nm="${k}" min="${d.min ?? 0}" max="${d.max ?? 100}" step="${d.step || 1}" value="${fmtN(d, val ?? d.default)}">`;
  if (d.type === 'select') return `<div class="chips2">${(d.options || []).map(o => `<button class="ch ${o[0] === val ? 'on' : ''}" data-sel="${k}" data-v="${esc(o[0])}">${esc(o[1])}</button>`).join('')}</div>`;
  if (d.type === 'text') return `<input class="tx" type="text" data-tx="${k}" value="${esc(val ?? '')}" maxlength="300">`;
  if (d.type === 'list') return `<textarea class="ls" data-ls="${k}" rows="3" placeholder="Un élément par ligne">${esc(arr(val).join('\n'))}</textarea>`;
  return '';
}
function editor() {
  const v = S.view, st = S.set;
  const bn = `<div class="banner tone-light"><button class="back" data-back2>${ic('back')} Retour</button><div><h2>${esc(v.title)}</h2><p>${esc(v.group)}${v.section ? ' · ' + esc(v.section) : ''} — les changements sont enregistrés et appliqués en direct.</p></div><span class="gl">${ic('tool')}</span></div>`;
  if (!st || st.loading) return bn + '<div class="empty">Chargement des réglages…</div>';
  if (st.error) return bn + `<div class="empty">${esc(st.error)}</div>`;
  const items = st.schema.filter(d => d.group === v.group && (!v.section || d.section === v.section));
  const secs = []; items.forEach(d => { let s = secs.find(x => x.n === d.section); if (!s) secs.push(s = { n: d.section, l: [] }); s.l.push(d); });
  let quick = '';
  if (v.group === 'Météo & heure' && !v.section) quick = `<section class="card ed"><h3>Raccourcis de l’heure</h3><div class="qk"><button class="btn dark" data-hr="9">Matin · 09:00</button><button class="btn dark" data-hr="12">Midi · 12:00</button><button class="btn dark" data-hr="18">Soir · 18:00</button><button class="btn dark" data-hr="23">Nuit · 23:00</button><button class="btn dark" data-hr="free">Heure normale</button></div></section>`;
  const rows = d => `<div class="er"><div class="rl"><b>${esc(d.label)}${st.over[d.key] ? ' <span class="md" title="Modifié">●</span>' : ''}</b>${d.hint ? `<small>${esc(d.hint)}</small>` : ''}</div><div class="rc ${d.type}">${ctrl(d)}${st.over[d.key] ? `<button class="rs2" data-rs="${esc(d.key)}" title="Remettre la valeur d’origine">${ic('refresh')}</button>` : ''}</div></div>`;
  return bn + quick + (secs.map(s => `<section class="card ed"><h3>${esc(s.n || '')}</h3>${s.l.map(rows).join('')}</section>`).join('') || '<div class="empty">Aucun réglage ici.</div>');
}
function journalView() {
  const l = S.d.journal;
  return `<div class="banner tone-light"><button class="back" data-back2>${ic('back')} Retour</button><div><h2>Journal</h2><p>Actions du staff depuis le démarrage de la ressource.</p></div><span class="gl">${ic('hist')}</span></div><section class="card ed">${l.length ? l.map(j => `<div class="er"><div class="rl"><b>${esc(j.who)}</b><small>${esc(j.text)}</small></div><div class="rc"><span class="k">${hm(new Date(j.t * 1000))}</span></div></div>`).join('') : '<div class="empty">Rien d’enregistré pour le moment.</div>'}</section>`;
}

const hmsHtml = s => { const h = pad(Math.floor(s / 3600)), m = pad(Math.floor(s % 3600 / 60)), x = pad(s % 60); return `${h}<em>:</em>${m}<em>:</em><b>${x}</b>`; };
function overview() {
  const st = S.d.stats, sv = S.server, pc = st.max ? Math.round(st.players / st.max * 100) : 0, tot = st.res.active + st.res.error + st.res.stopped || 1;
  const card = c => {
    const body = c.wide ? `<div class="tags">${c.cards.slice(0, 2).map(x => `<span>${esc(x.title)}</span>`).join('')}${c.cards.length > 2 ? `<span>+${c.cards.length - 2}</span>` : ''}</div>`
      : `<p>${esc(c.cards.slice(0, 4).map(x => x.title).join(', '))}${c.cards.length > 4 ? '…' : ''}</p>`;
    return `<button class="card cat tone-${c.tone} ${c.wide ? 'c-wide' : 'c-std'}" data-cat="${c.id}"><h3>${esc(c.title)}</h3>${body}<span class="ic">${ic(c.icon)}</span></button>`;
  };
  const cats = S.cats.filter(c => !c.group).map(card).join(''), bld = S.cats.filter(c => c.group === 'builders').map(card).join(''), tools = S.cats.filter(c => c.group === 'tools').map(card).join('');
  const log = S.d.journal.length ? `<div class="log">${S.d.journal.slice(0, 20).map(j => `<div><time>${hm(new Date(j.t * 1000))}</time><b>${esc(j.who)}</b><span>${esc(j.text)}</span></div>`).join('')}</div>` : `<div class="empty">${ic('hist')}Rien d’enregistré depuis l’ouverture.</div>`;
  return `<div class="hd"><div class="grow"><h1>Vue d’ensemble</h1><p>Le serveur en direct, et tous ses réglages</p></div><button class="btn black" data-refresh>${ic('refresh')} Actualiser</button></div>
  <div class="grid">
    <section class="card hero">${sv.logo ? `<img class="wm" src="${esc(sv.logo)}" alt="">` : ''}<div class="chips"><span class="chip"><i></i>En ligne</span><span class="chip">${esc(sv.version)}</span><span class="chip">${esc(sv.license)}</span></div>
      <h2>${esc(sv.name)}</h2><p>${esc(sv.subtitle)}</p><div class="row"><button class="btn white" data-cat="look">${ic('palette')} Personnaliser</button><button class="btn outline" data-j>${ic('hist')} Journal</button></div></section>
    <section class="card pl"><div class="ring" style="--p:${pc}"><span>${pc} %</span></div><div><div class="k">Joueurs</div><div class="v">${st.players} <small>/ ${st.max}</small></div><div class="k">${st.staff} staff en service</div></div></section>
    <section class="card up"><div class="k">En ligne depuis</div><div class="v" id="up">${hmsHtml(st.uptime)}</div><div class="k">Depuis le dernier démarrage</div></section>
    <section class="card rs"><div class="top2"><span class="k">Ressources</span><span class="num">${tot}</span></div><div class="bar"><i style="width:${st.res.active / tot * 100}%"></i><i class="e" style="width:${st.res.error / tot * 100}%"></i></div>
      <div class="leg"><span><b></b><strong>${st.res.active}</strong> actives</span><span><b class="e"></b><strong>${st.res.error}</strong> erreur</span><span><b class="s"></b><strong>${st.res.stopped}</strong> arrêtées</span></div></section>
    <div class="sec"><b>Catégories</b><span>Une famille de réglages par carte</span></div>
    ${cats}
    <section class="card sess"><div class="hdr"><span>Cette session <em>${S.d.journal.length}</em></span><a data-j>Journal complet →</a></div>${log}</section>
    ${tools ? `<div class="sec"><b>Réglages complets</b><span>Tous les réglages du serveur, groupe par groupe</span></div>${tools}` : ''}
    ${bld ? `<div class="sec"><b>Builders</b><span>Un builder par carte : un clic ouvre l’éditeur</span></div>${bld}` : ''}
  </div>`;
}
function category(c) {
  const q = S.q.trim().toLowerCase();
  const cards = c.cards.filter(x => !q || (x.title + ' ' + x.desc).toLowerCase().includes(q));
  return `<div class="banner tone-${c.tone}"><button class="back" data-home>${ic('back')} Catégories</button><div><h2>${esc(c.title)}</h2><p>${esc(c.sub || '')}</p></div><span class="gl">${ic(c.icon)}</span></div>
  <div class="cards">${cards.map((x, i) => `<button class="sub" data-card="${c.cards.indexOf(x)}"><h4>${esc(x.title)}</h4><p>${esc(x.desc)}</p><span class="ic">${ic(x.icon)}</span></button>`).join('') || '<div class="empty" style="grid-column:1/-1">Aucun résultat.</div>'}</div>`;
}
function search() {
  const q = S.q.trim().toLowerCase(), out = [];
  S.cats.forEach(c => c.cards.forEach((x, i) => { if ((x.title + ' ' + x.desc + ' ' + c.title).toLowerCase().includes(q)) out.push([c, x, i]); }));
  if (!S.set) loadSettings();
  const st = S.set && S.set.schema ? S.set.schema.filter(d => (d.label + ' ' + (d.hint || '') + ' ' + d.group + ' ' + (d.section || '')).toLowerCase().includes(q)).slice(0, 15) : [];
  return `<div class="hd"><div class="grow"><h1>Résultats</h1><p>${out.length + st.length} résultat(s) pour « ${esc(S.q)} »</p></div></div><div class="cards">${out.map(([c, x, i]) => `<button class="sub" data-cat="${c.id}" data-card="${i}"><h4>${esc(x.title)}</h4><p>${esc(c.title)} · ${esc(x.desc)}</p><span class="ic">${ic(x.icon)}</span></button>`).join('')}${st.map(d => `<button class="sub" data-sg="${esc(d.group)}" data-ss="${esc(d.section || '')}"><h4>${esc(d.label)}</h4><p>${esc(d.group)} · ${esc(d.section || '')}</p><span class="ic">${ic('tool')}</span></button>`).join('')}</div>`;
}
function fit() { const w = document.querySelector('.win'); if (!w) return; const s = Math.min(innerWidth / 1230, innerHeight / 700, 1.6); w.style.transform = `scale(${s})`; }
addEventListener('resize', fit);
function draw() {
  if (!S.open) return;
  const c = S.cats.find(x => x.id === S.cat), accent = S.server.accent;
  if (accent) document.documentElement.style.setProperty('--acc', accent);
  const wide = S.railWide ? 'wide' : '';
  const rail = [['grid', null, 'Vue d’ensemble'], ...S.cats.map(x => [x.icon, x.id, x.title])].map(([i, id, t]) => `<button class="ri ${(id === S.cat) || (!id && !S.cat && !S.q) ? 'on' : ''}" title="${esc(t)}" data-rail="${id || ''}">${ic(i)}<span>${esc(t)}</span></button>`).join('');
  const body = S.view ? (S.view.journal ? journalView() : editor()) : S.q.trim() ? search() : c ? category(c) : overview();
  const oldMain = $r.querySelector('.main'), keep = oldMain ? oldMain.scrollTop : 0, oldRail = $r.querySelector('.scroll'), keepR = oldRail ? oldRail.scrollTop : 0;
  const u = S.d.user, now = new Date();
  $r.innerHTML = `<div class="win">
    <header class="top"><div class="cap me"><span class="av">${esc((u.name || '?')[0].toUpperCase())}</span><div><b>Bonjour, ${esc(u.name)}</b><small>${esc(u.role)} · ID ${u.id}</small></div></div>
      <div class="cap nav"><button class="circ white" data-home title="Accueil">${ic('home')}</button><button class="circ ghost" data-back>${ic('back')}</button><button class="circ ghost" data-fwd>${ic('fwd')}</button></div>
      <label class="cap search">${ic('search')}<input id="q" placeholder="Rechercher un réglage, une page…" value="${esc(S.q)}" autocomplete="off"><kbd>Entrée</kbd></label>
      <div class="cap clock" id="clk">${hm(now)}</div>
      <div class="cap tools"><button class="circ" data-j title="Journal">${ic('hist')}</button><button class="circ pink" data-mute title="Sons">${ic('mute')}</button></div>
      <button class="cap closeb" data-close>Fermer <kbd>Échap</kbd></button></header>
    <div class="body"><aside class="rail ${wide}"><div class="rtop"><span class="rlogo">${S.server.logo ? `<img src="${esc(S.server.logo)}" alt="">` : ''}</span><b class="rname">${esc(S.server.short || S.server.name || '')}</b><button class="expand" data-expand>${ic(S.railWide ? 'back' : 'fwd')}</button></div><div class="scroll">${rail}</div></aside>
    <main class="main">${body}</main></div></div>`;
  fit();
  const nm = $r.querySelector('.main'); if (nm) nm.scrollTop = keep;
  const nr = $r.querySelector('.scroll'); if (nr) nr.scrollTop = keepR;
  const q = document.getElementById('q'); if (q && S.focusQ) { q.focus(); q.setSelectionRange(q.value.length, q.value.length); }
}
$r.addEventListener('click', e => {
  const t = e.target.closest('[data-cat],[data-home],[data-rail],[data-card],[data-j],[data-refresh],[data-close],[data-mute],[data-back2],[data-expand],[data-tg],[data-sel],[data-rs],[data-hr],[data-sg]'); if (!t) return;
  const ds = t.dataset;
  if ('close' in ds) return post('close');
  if ('expand' in ds) { S.railWide = !S.railWide; return draw(); }
  if ('back2' in ds) { S.view = null; return draw(); }
  if ('sg' in ds) return openSettings({ group: ds.sg, section: ds.ss || null }, ds.ss || ds.sg);
  if ('tg' in ds) return send({ [ds.tg]: !S.set.values[ds.tg] });
  if ('sel' in ds) return send({ [ds.sel]: ds.v });
  if ('rs' in ds) return send({ [ds.rs]: '__reset' });
  if ('hr' in ds) return send(ds.hr === 'free' ? { time_frozen: '__reset', time_hour: '__reset' } : { time_frozen: true, time_hour: +ds.hr });
  if ('refresh' in ds) return refresh(true);
  if ('mute' in ds) return toast('Sons : bientôt disponible');
  if ('j' in ds) { S.view = { journal: true }; return draw(); }
  if ('card' in ds) { const c = S.cats.find(x => x.id === (ds.cat || S.cat)); const card = c && c.cards[+ds.card]; if (!card) return;
    if (card.action && card.action.settings) { post('action', { title: card.title }); return openSettings(card.action.settings, card.title); }
    if (!card.action) { post('action', { title: card.title }); return toast('« ' + card.title + ' » : bientôt disponible'); }
    return post('action', { title: card.title, action: card.action }); }
  if ('cat' in ds) { S.view = null; S.cat = ds.cat; S.q = ''; S.focusQ = false; return draw(); }
  if ('rail' in ds) { S.view = null; S.cat = ds.rail || null; S.q = ''; S.focusQ = false; return draw(); }
  if ('home' in ds) { S.view = null; S.cat = null; S.q = ''; return draw(); }
});
$r.addEventListener('input', e => { const t = e.target; if (t.dataset && t.dataset.rg) { const d = S.set.schema.find(x => x.key === t.dataset.rg), n = t.parentNode.querySelector('.nm'); if (n) n.value = fmtN(d, t.value); } });
$r.addEventListener('change', e => {
  const t = e.target, ds = t.dataset || {};
  if (ds.rg || ds.nm) return send({ [ds.rg || ds.nm]: +t.value });
  if (ds.tx) return send({ [ds.tx]: t.value });
  if (ds.ls) return send({ [ds.ls]: t.value.split('\n').map(s => s.trim()).filter(Boolean) });
});
$r.addEventListener('input', e => { if (e.target.id === 'q') { S.q = e.target.value; S.focusQ = true; draw(); } });
addEventListener('keydown', e => { if (S.open && e.key === 'Escape') post('close'); });
async function refresh(manual) { const d = await post('refresh'); if (d && d.stats && S.open) { S.d.stats = d.stats; S.d.journal = d.journal || []; S.up = d.stats.uptime; if ((manual || !S.q) && !S.view) { const f = S.focusQ; draw(); S.focusQ = f; } } }
addEventListener('message', ev => {
  const m = ev.data || {};
  if (m.a === 'open') {
    S = Object.assign(S, { view: null, set: null, open: true, d: m.data, server: m.server || {}, cats: m.cats || [], cat: null, q: '', focusQ: false });
    $r.classList.remove('hidden'); draw();
    clearInterval(S.timer); clearInterval(S.clock);
    S.timer = setInterval(() => refresh(false), Math.max(2, m.refresh || 5) * 1000);
    S.clock = setInterval(() => { const c = document.getElementById('clk'); if (c) c.textContent = hm(new Date()); const u = document.getElementById('up'); if (u && S.d) { S.d.stats.uptime++; u.innerHTML = hmsHtml(S.d.stats.uptime); } }, 1000);
  } else if (m.a === 'close') { S.open = false; clearInterval(S.timer); clearInterval(S.clock); $r.classList.add('hidden'); }
});
