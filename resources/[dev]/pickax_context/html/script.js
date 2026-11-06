'use strict';
const $r = document.getElementById('root');
const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const post = (n, b) => { try { fetch('https://pickax_context/' + n, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(b || {}) }); } catch (e) {} };
const P = {
  phone: 'M7 3h10a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1zM11 18h2',
  book: 'M5 4h11a3 3 0 0 1 3 3v13H8a3 3 0 0 1-3-3zM5 17a3 3 0 0 1 3-3h11',
  star: 'M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z',
  cart: 'M3 4h3l2 12h11l2-8H7M9 20h.01M18 20h.01',
  briefcase: 'M3 8h18v12H3zM8 8V5h8v3M3 14h18',
  users: 'M16 20v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 10a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM22 20v-2a4 4 0 0 0-3-3.9M16 2.1a4 4 0 0 1 0 7.8',
  user: 'M20 21a8 8 0 0 0-16 0M12 12a5 5 0 1 0 0-10 5 5 0 0 0 0 10z',
  grid: 'M4 4h6v6H4zM14 4h6v6h-6zM14 14h6v6h-6zM4 14h6v6H4z',
  target: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 16a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM12 12h.01',
  list: 'M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01',
  tool: 'M14.7 6.3a4 4 0 0 0-5.4 5.4L3 18l3 3 6.3-6.3a4 4 0 0 0 5.4-5.4l-3 3-2-2z',
  help: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.6.3-1 .8-1 1.5M12 17h.01',
  key: 'M14 10a4 4 0 1 0-3.5 4L21 14v-3h-3v-2zM7 10h.01',
  coins: 'M12 8c4.4 0 8-1.3 8-3s-3.6-3-8-3-8 1.3-8 3 3.6 3 8 3zM4 5v6c0 1.7 3.6 3 8 3s8-1.3 8-3V5M4 11v6c0 1.7 3.6 3 8 3s8-1.3 8-3v-6',
  game: 'M6 9h12a4 4 0 0 1 4 4v2a3 3 0 0 1-5 2l-1-1H8l-1 1a3 3 0 0 1-5-2v-2a4 4 0 0 1 4-4zM8 11v4M6 13h4',
  car: 'M5 16h14M6 16l1.5-5h9L18 16M7 19h.01M17 19h.01M4 16v3h2v-3M18 16v3h2v-3',
  shield: 'M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z',
  chev: 'M9 6l6 6-6 6', check: 'M5 12l5 5 9-10'
};
const ic = (n, cls) => `<svg viewBox="0 0 24 24"><path d="${P[n] || P.grid}"/></svg>`;
let S = { menu: [], path: [], x: 0, y: 0, open: false };

function panelEl(level) {
  const items = level === 0 ? S.menu : itemsAt(level);
  const el = document.createElement('div'); el.className = 'panel'; el.dataset.level = level;
  const hasIcons = items.some(i => i.icon);
  items.forEach((it, idx) => {
    const r = document.createElement('div');
    r.className = 'row' + (it.disabled ? ' dis' : '') + (S.path[level] === idx ? ' on' : '');
    r.innerHTML = (hasIcons ? (it.icon ? `<span class="ic">${ic(it.icon)}</span>` : '<span class="noic"></span>') : '<span class="noic"></span>')
      + `<span class="lb">${esc(it.label)}</span>` + (it.children ? `<span class="chev">${ic('chev')}</span>` : it.checked ? `<span class="ck">${ic('check')}</span>` : '');
    r.addEventListener('mouseenter', () => { if (it.disabled) return; setPath(level, it.children ? idx : null); });
    r.addEventListener('click', () => { if (it.disabled || it.children) return; post('run', { k: it.k }); });
    el.append(r);
  });
  return el;
}
function itemsAt(level) { let items = S.menu; for (let i = 0; i < level; i++) items = items[S.path[i]].children; return items; }

function layout() {
  $r.innerHTML = '';
  const W = innerWidth, H = innerHeight;
  let left = S.x * W + S.off, top = S.y * H - 70, prevRight = 0, rowTop = top;
  for (let L = 0; L <= S.path.length; L++) {
    if (L > 0 && S.path[L - 1] == null) break;
    const el = panelEl(L); el.style.visibility = 'hidden'; $r.append(el);
    const w = el.offsetWidth, h = el.offsetHeight;
    let x = L === 0 ? left : prevRight + 4, y = L === 0 ? top : rowTop;
    if (x + w > W - 8) x = Math.max(8, (L === 0 ? left : $r.children[L - 1].offsetLeft) - w - 4);   // pas de place à droite : on ouvre à gauche
    if (y + h > H - 8) y = Math.max(8, H - 8 - h);
    if (y < 8) y = 8;
    el.style.left = x + 'px'; el.style.top = y + 'px'; el.style.visibility = 'visible';
    prevRight = x + w;
    const sel = S.path[L];
    rowTop = sel != null ? y + 5 + sel * 36 - 5 : y;
    if (L === S.path.length) break;
  }
}
function setPath(level, idx) {
  const np = S.path.slice(0, level); if (idx != null) np.push(idx);
  if (JSON.stringify(np) === JSON.stringify(S.path)) return;
  S.path = np; layout();
}
addEventListener('mousedown', e => { if (!S.open) return; if (e.button === 2 || !e.target.closest('.panel')) post('close'); });
addEventListener('contextmenu', e => e.preventDefault());
addEventListener('keydown', e => { if (!S.open) return; if (e.key === 'Escape') post('close'); if (e.key === 'Backspace') { if (S.path.length) { S.path.pop(); layout(); } else post('close'); } });
addEventListener('resize', () => { if (S.open) layout(); });
addEventListener('message', ev => {
  const m = ev.data || {};
  if (m.a === 'open') { S = { menu: m.menu || [], path: [], x: m.x, y: m.y, off: m.offset || 70, open: true }; $r.classList.remove('hidden'); layout(); }
  else if (m.a === 'close') { S.open = false; $r.classList.add('hidden'); $r.innerHTML = ''; }
});
