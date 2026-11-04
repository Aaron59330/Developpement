'use strict';
const $r = document.getElementById('root');
const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const post = (n, b) => { try { fetch('https://pickax_wheel/' + n, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(b || {}) }); } catch (e) {} };
const IMG = 'https://cfx-nui-ox_inventory/web/images/';
const R = 175, DEAD = 62, N = 8;   // rayon des cases, zone morte au centre, nombre de cases
let S = { tabs: [], t: 0, hover: -1, sel: {}, page: 0, key: 'TAB', open: false };

const imgTag = (name, cls) => `<img ${cls ? `class="${cls}"` : ''} src="${IMG}${esc(name)}.png" alt="" data-n="${esc(name)}" onerror="imgFallback(this)">`;
window.imgFallback = el => { const n = el.dataset.n, step = +(el.dataset.s || 0); const tries = [`${IMG}${n}.PNG`, `${IMG}${n.toLowerCase()}.png`, `${IMG}${n.toUpperCase()}.png`]; if (step < tries.length) { el.dataset.s = step + 1; el.src = tries[step]; } else el.style.visibility = 'hidden'; };

const tab = () => S.tabs[S.t];
// Cases affichées pour l'onglet courant : { label, icon?, glyph?, sub, tl, tr, held, empty, data }
function slots() {
  const T = tab(); if (!T) return [];
  if (T.id === 'weapons') {
    return T.slots.map(s => {
      const n = s.list.length;
      if (!n) return { label: s.label, empty: true, key: s.key };
      const i = Math.min(S.sel[s.key] != null ? S.sel[s.key] : Math.max(0, s.list.findIndex(w => w.held)), n - 1), w = s.list[i];
      return { label: w.label, icon: w.name, tl: w.reserve != null ? w.reserve : w.ammo, tr: n > 1 ? `${i + 1}/${n}` : null, held: w.held, sub: w.held ? 'En main' : (w.reserve != null ? `${w.reserve} munitions` : ''), key: s.key, data: { slot: w.slot }, n };
    });
  }
  const per = N, from = S.page * per, list = T.list.slice(from, from + per);
  const out = list.map(e => ({ label: e.label, icon: T.id === 'items' ? e.name : null, glyph: T.id !== 'items' ? (e.label || '?')[0] : null, tl: T.id === 'items' && e.count > 1 ? 'x' + e.count : null, held: T.id === 'outfit' && e.off, sub: T.id === 'outfit' ? (e.off ? 'Retiré · cliquer pour remettre' : 'Retirer') : (T.id === 'items' ? 'Utiliser' : 'Lancer'), data: T.id === 'items' ? { slot: e.slot } : { idx: e.idx } }));
  while (out.length < N) out.push({ empty: true, label: '' });
  return out;
}
const pages = () => { const T = tab(); return T && T.list ? Math.max(1, Math.ceil(T.list.length / N)) : 1; };
const heldWeapon = () => { const T = S.tabs.find(t => t.id === 'weapons'); if (!T) return null; for (const s of T.slots) for (const w of s.list) if (w.held) return w; return null; };

function draw() {
  if (!S.open) return;
  const sl = slots();
  const hints = tab() && tab().id === 'weapons' ? 'Molette</b>Autre arme du même type' : 'Molette</b>Page suivante';
  const cells = sl.map((c, i) => { const a = i * 45 * Math.PI / 180, x = Math.sin(a) * R, y = -Math.cos(a) * R;
    return `<div class="slot ${c.empty ? 'empty' : ''} ${c.held ? 'held' : ''} ${S.hover === i ? 'hover' : ''}" style="left:${x}px;top:${y}px">${c.tl != null ? `<span class="tl">${esc(c.tl)}</span>` : ''}${c.tr ? `<span class="tr">${esc(c.tr)}</span>` : ''}${c.held && tab().id === 'weapons' ? '<span class="ck">✓</span>' : ''}${c.icon ? imgTag(c.icon) : (c.glyph ? `<span class="glyph">${esc(c.glyph)}</span>` : '')}<span class="nm">${esc(c.label)}</span></div>`; }).join('');
  const h = S.hover >= 0 && sl[S.hover] && !sl[S.hover].empty ? sl[S.hover] : null, hw = heldWeapon();
  const core = h ? `${h.icon ? imgTag(h.icon) : (h.glyph ? `<div class="glyph">${esc(h.glyph)}</div>` : '')}<b>${esc(h.label)}</b><small>${esc(h.sub || '')}</small>`
    : (tab().id === 'weapons' ? (hw ? `${imgTag(hw.name)}<b>${esc(hw.label)}</b><small>En main</small>` : '<b>Aucune arme</b><small>en main</small>') : `<b>${esc(tab().label)}</b><small>Survole puis relâche ${esc(S.key)}</small>`);
  $r.innerHTML = `<div class="tabs">${S.tabs.map((t, i) => `<button data-i="${i}" class="${i === S.t ? 'on' : ''}">${esc(t.label)}</button>`).join('')}</div>
    <div class="wheel"><div class="ring"></div>${cells}<div class="core">${core}</div>${pages() > 1 ? `<div class="page">${S.page + 1} / ${pages()}</div>` : ''}</div>
    <div class="hints"><span><b>Relâcher ${esc(S.key)}</b>Utiliser</span><span><b>Clic droit</b>Onglet suivant</span><span><b>${hints}</span></div>`;
}

function setTab(i) { S.t = (i + S.tabs.length) % S.tabs.length; S.page = 0; S.hover = -1; post('tab', { tabIndex: S.t + 1 }); draw(); }
function release(cancel) {
  if (!S.open) return;
  const sl = slots(), c = sl[S.hover], T = tab();
  S.open = false; $r.classList.add('hidden'); $r.innerHTML = '';
  if (cancel || !c || c.empty || !c.data) return post('cancel', { tabIndex: S.t + 1 });
  post('select', Object.assign({ tab: T.id, tabIndex: S.t + 1 }, c.data));
}

window.addEventListener('mousemove', e => {
  if (!S.open) return;
  const dx = e.clientX - innerWidth / 2, dy = e.clientY - innerHeight / 2, d = Math.hypot(dx, dy);
  let h = -1;
  if (d > DEAD) { const a = (Math.atan2(dx, -dy) * 180 / Math.PI + 360 + 22.5) % 360; h = Math.floor(a / 45) % N; }
  if (h !== S.hover) { S.hover = h; draw(); }
});
window.addEventListener('mousedown', e => { if (!S.open) return; if (e.button === 2) { e.preventDefault(); setTab(S.t + 1); } else if (e.button === 0) { release(false); } });
window.addEventListener('contextmenu', e => e.preventDefault());
window.addEventListener('wheel', e => {
  if (!S.open) return;
  const dir = e.deltaY > 0 ? 1 : -1, T = tab();
  if (T.id === 'weapons') {
    if (S.hover < 0) return;
    const s = T.slots[S.hover]; if (!s || s.list.length < 2) return;
    const cur = S.sel[s.key] != null ? S.sel[s.key] : Math.max(0, s.list.findIndex(w => w.held));
    S.sel[s.key] = (cur + dir + s.list.length) % s.list.length; draw();
  } else if (pages() > 1) { S.page = (S.page + dir + pages()) % pages(); S.hover = -1; draw(); }
}, { passive: true });
window.addEventListener('keyup', e => { if (S.open && (e.key.toUpperCase() === String(S.key).toUpperCase())) { e.preventDefault(); release(false); } });
window.addEventListener('keydown', e => { if (!S.open) return; if (e.key === 'Escape') release(true); if (e.key === 'ArrowRight') setTab(S.t + 1); if (e.key === 'ArrowLeft') setTab(S.t - 1); });
$r.addEventListener('click', e => { const b = e.target.closest('.tabs button'); if (b) setTab(+b.dataset.i); });

window.addEventListener('message', e => {
  const m = e.data || {};
  if (m.a === 'open') { S = { tabs: m.tabs || [], t: Math.max(0, Math.min((m.tab || 1) - 1, (m.tabs || []).length - 1)), hover: -1, sel: {}, page: 0, key: m.key || 'TAB', open: true }; $r.classList.remove('hidden'); draw(); }
  else if (m.a === 'close') { S.open = false; $r.classList.add('hidden'); $r.innerHTML = ''; }
  else if (m.a === 'release') release(false);
});
