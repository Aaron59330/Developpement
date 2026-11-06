'use strict';
const $r = document.getElementById('root');
const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const post = (n, b) => { try { return fetch('https://pickax_context/' + n, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(b || {}) }).then(r => r.json()).catch(() => ({})); } catch (e) { return Promise.resolve({}); } };
// codes couleur GTA (~r~ ~g~ ~b~ ~y~ ~o~ ~p~ ~w~ ~s~ ~n~ …) -> texte coloré
const COL = { r: '#ff6b6b', g: '#5ee08a', b: '#6db3ff', y: '#ffd95a', o: '#ffa24d', p: '#c792ff', c: '#a8a8a8', m: '#7a7a7a', w: '', s: '' };
function colorize(t) {
  let out = '', cur = '', open = false;
  String(t == null ? '' : t).split(/(~[A-Za-z_0-9]+~)/).forEach(part => {
    const m = part.match(/^~([A-Za-z_0-9]+)~$/);
    if (!m) { out += esc(part); return; }
    const c = m[1];
    if (c === 'n') { out += ' '; return; }
    if (c in COL) { if (open) { out += '</span>'; open = false; } if (COL[c]) { out += `<span style="color:${COL[c]}">`; open = true; } }
  });
  return out + (open ? '</span>' : '');
}
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

const ROW = 36, PAD = 5;
const panels = [];
function itemsAt(level) { let items = S.menu; for (let i = 0; i < level; i++) items = items[S.path[i]].children; return items; }

function buildPanel(level) {
  const items = itemsAt(level), el = document.createElement('div');
  el.className = 'panel'; el.dataset.level = level;
  const hasIcons = items.some(i => i.icon);
  items.forEach((it, idx) => {
    const r = document.createElement('div');
    if (it.sep) { r.className = 'sep'; el.append(r); return; }
    r.className = 'row' + (it.disabled ? ' dis' : '');
    r.innerHTML = (hasIcons ? (it.icon ? `<span class="ic">${ic(it.icon)}</span>` : '<span class="noic"></span>') : '')
      + (it.box ? `<span class="bx${it.checked ? ' on' : ''}">${it.checked ? ic('check') : ''}</span>` : '')
      + `<span class="lb">${colorize(it.label)}</span>` + (it.right ? `<span class="rt">${colorize(it.right)}</span>` : '')
      + (it.children ? `<span class="chev">${ic('chev')}</span>` : (!it.box && it.checked ? `<span class="ck">${ic('check')}</span>` : ''));
    r.addEventListener('mouseenter', () => { if (!it.disabled) setPath(level, it.children ? idx : null); });
    r.addEventListener('click', () => {
      if (it.disabled || it.children || it.k == null) return;
      post('run', { k: it.k }).then(res => {
        if (res && typeof res.checked === 'boolean' && it.box) { it.checked = res.checked; const b = r.querySelector('.bx'); if (b) { b.classList.toggle('on', res.checked); b.innerHTML = res.checked ? ic('check') : ''; } }
      });
    });
    el.append(r);
  });
  return el;
}

// Ajoute un panneau sans toucher aux autres (pas de reconstruction : plus de clignotement)
function addPanel(level) {
  const el = buildPanel(level); el.style.visibility = 'hidden'; $r.append(el); panels[level] = el;
  const W = innerWidth, H = innerHeight, w = el.offsetWidth, h = el.offsetHeight;
  let x, y;
  if (level === 0) { x = S.x * W + S.off; y = S.y * H - 70; }
  else {
    const prev = panels[level - 1];
    x = prev.offsetLeft + prev.offsetWidth + 4; y = prev.offsetTop + prev.children[S.path[level - 1]].offsetTop - PAD;
    if (x + w > W - 8) x = Math.max(8, prev.offsetLeft - w - 4);
  }
  if (level === 0 && x + w > W - 8) x = Math.max(8, S.x * W - S.off - w);
  if (y + h > H - 8) y = Math.max(8, H - 8 - h);
  if (y < 8) y = 8;
  el.style.left = x + 'px'; el.style.top = y + 'px'; el.style.visibility = 'visible';
}
function drawAll() { $r.innerHTML = ''; panels.length = 0; addPanel(0); for (let L = 1; L <= S.path.length; L++) addPanel(L); markOn(); }
function markOn() { panels.forEach((p, L) => [...p.children].forEach((r, i) => r.classList.toggle('on', S.path[L] === i))); }
function setPath(level, idx) {
  if ((S.path[level] == null ? null : S.path[level]) === idx && S.path.length === level + (idx == null ? 0 : 1)) return;
  while (panels.length > level + 1) panels.pop().remove();
  S.path = S.path.slice(0, level);
  if (idx != null) { S.path.push(idx); addPanel(level + 1); }
  markOn();
}
// petit effet lumineux qui suit le curseur (ligne survolée + léger halo sur le panneau)
addEventListener('mousemove', e => {
  const p = e.target.closest && e.target.closest('.panel'); if (!p) return;
  const pr = p.getBoundingClientRect(); p.style.setProperty('--px', (e.clientX - pr.left) + 'px'); p.style.setProperty('--py', (e.clientY - pr.top) + 'px');
  const r = e.target.closest('.row'); if (r) { const rr = r.getBoundingClientRect(); r.style.setProperty('--mx', (e.clientX - rr.left) + 'px'); r.style.setProperty('--my', (e.clientY - rr.top) + 'px'); }
});
// en mode « maintenir » on ne ferme pas en cliquant à côté (c'est le relâchement de la touche qui ferme)
addEventListener('mousedown', e => { if (!S.open) return; if (e.button === 2 || (!S.hold && !e.target.closest('.panel'))) post('close'); });
addEventListener('contextmenu', e => e.preventDefault());
addEventListener('keydown', e => { if (!S.open) return; if (e.key === 'Escape') post('close'); if (e.key === 'Backspace') { if (S.path.length) setPath(S.path.length - 1, null); else post('close'); } });
addEventListener('resize', () => { if (S.open) drawAll(); });
addEventListener('message', ev => {
  const m = ev.data || {};
  if (m.a === 'open') { S = { menu: m.menu || [], path: [], x: m.x, y: m.y, off: m.offset || 70, hold: m.hold === true, open: true }; $r.classList.remove('hidden'); drawAll(); }
  else if (m.a === 'close') { S.open = false; $r.classList.add('hidden'); $r.innerHTML = ''; panels.length = 0; }
});
