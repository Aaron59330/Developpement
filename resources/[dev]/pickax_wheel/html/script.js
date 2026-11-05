'use strict';
const $r = document.getElementById('root');
const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const post = (n, b) => { try { fetch('https://pickax_wheel/' + n, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(b || {}) }); } catch (e) {} };
const IMG = 'https://cfx-nui-ox_inventory/web/images/';
const C = 400, ROUT = 372, RIN = 218, GAP = 3.2, CR = 20, N = 6;
let S = { slots: [], hover: -1, sel: {}, open: false };

const P = (r, deg) => { const a = deg * Math.PI / 180; return [C + r * Math.sin(a), C - r * Math.cos(a)]; };
const f = p => p[0].toFixed(1) + ' ' + p[1].toFixed(1);
const ang = i => (180 + i * 60) % 360;   // le 0 (mains nues) est en bas, puis 1..5 dans le sens horaire
function sector(i) {
  const A = ang(i);
  const a0 = A - 30 + GAP / 2, a1 = A + 30 - GAP / 2;
  const dO = CR / ROUT * 180 / Math.PI, dI = CR / RIN * 180 / Math.PI;
  return `M${f(P(ROUT, a0 + dO))} A${ROUT} ${ROUT} 0 0 1 ${f(P(ROUT, a1 - dO))} Q${f(P(ROUT, a1))} ${f(P(ROUT - CR, a1))} `
    + `L${f(P(RIN + CR, a1))} Q${f(P(RIN, a1))} ${f(P(RIN, a1 - dI))} A${RIN} ${RIN} 0 0 0 ${f(P(RIN, a0 + dI))} `
    + `Q${f(P(RIN, a0))} ${f(P(RIN + CR, a0))} L${f(P(ROUT - CR, a0))} Q${f(P(ROUT, a0))} ${f(P(ROUT, a0 + dO))}Z`;
}
function arc(i) {
  const r = RIN + 20, a0 = ang(i) - 22, a1 = ang(i) + 22;
  return `M${f(P(r, a0))} A${r} ${r} 0 0 1 ${f(P(r, a1))}`;
}
const fist = (x, y) => `<image href="poing.png" x="${x - 52}" y="${y - 14}" width="104" height="74" preserveAspectRatio="xMidYMid meet"/>`;
const cur = (s, i) => { const n = s.list.length; if (!n) return null; const k = Math.min(S.sel[s.id] != null ? S.sel[s.id] : Math.max(0, s.list.findIndex(w => w.held)), n - 1); return Object.assign({ k, n }, s.list[k]); };
const heldIdx = () => S.slots.findIndex(s => s.held);

function draw() {
  if (!S.open) return;
  const parts = S.slots.map((s, i) => {
    const w = s.unarmed ? null : cur(s, i), empty = !s.unarmed && !w;
    const held = s.unarmed ? !!s.held : !!(w && w.held);
    const [ix, iy] = P(306, ang(i)), cls = `slot ${empty ? 'empty' : ''} ${held ? 'held' : ''} ${S.hover === i ? 'hover' : ''}`;
    let inner = '';
    if (empty) inner = `<text class="num" x="${ix}" y="${iy}">${i + 1}</text>`;
    else {
      const icon = s.unarmed ? s.icon : w.name;
      inner = s.unarmed ? fist(ix, iy - 20)
        : `<image href="${IMG}${esc(icon)}.png" x="${ix - 95}" y="${iy - 78}" width="190" height="104" preserveAspectRatio="xMidYMid meet" onerror="this.style.display='none'"/>`;
      if (!s.unarmed) {
        const txt = w.reserve != null ? `${w.ammo} <tspan class="r">/ ${w.reserve}</tspan>` : `${w.ammo}`;
        inner += `<text class="cnt" x="${ix}" y="${iy + 52}">${txt}</text>`;
        if (w.n > 1) inner += `<text class="multi" x="${ix}" y="${iy + 76}">${w.k + 1}/${w.n}</text>`;
      }
    }
    return `<g class="${cls}"><path class="seg" d="${sector(i)}"/><path class="wash" d="${sector(i)}"/><path class="arc" d="${arc(i)}"/>${inner}</g>`;
  }).join('');
  let title, sub;
  const hs = S.hover >= 0 ? S.slots[S.hover] : null, hi = hs ? S.hover : heldIdx();
  const t = hi >= 0 ? S.slots[hi] : S.slots.find(x => x.unarmed);
  if (!t || t.unarmed) { title = (t && t.label) || 'MAINS NUES'; sub = (t && t.sub) || 'CORPS À CORPS'; }
  else { const w = cur(t, hi); title = w ? w.label : t.label; sub = t.label; }
  const defs = `<defs>${['h', 'e'].map(k => `<radialGradient id="g${k}" gradientUnits="userSpaceOnUse" cx="400" cy="400" r="${ROUT}"><stop offset="${RIN / ROUT}" stop-color="var(--${k === 'h' ? 'hover' : 'eq'})" stop-opacity=".5"/><stop offset="${(RIN + 110) / ROUT}" stop-color="var(--${k === 'h' ? 'hover' : 'eq'})" stop-opacity="0"/></radialGradient>`).join('')}</defs>`;
  $r.innerHTML = `<svg viewBox="0 0 800 800">${defs}${parts}<text class="ctitle" x="400" y="398">${esc(String(title).toUpperCase())}</text><text class="csub" x="400" y="432">${esc(String(sub).toUpperCase())}</text></svg>`;
}

function pick(e) {
  const dx = e.clientX - innerWidth / 2, dy = e.clientY - innerHeight / 2, k = 800 / Math.min(innerWidth, innerHeight) / 0.94;
  if (Math.hypot(dx, dy) * k < 120) return -1;
  let a = Math.atan2(dx, -dy) * 180 / Math.PI; if (a < 0) a += 360;
  return (Math.floor(((a + 30) % 360) / 60) + 3) % 6;   // position écran -> emplacement (0 = bas)
}
addEventListener('mousemove', e => { if (!S.open) return; const h = pick(e); if (h !== S.hover) { S.hover = h; draw(); } });
addEventListener('wheel', e => {
  if (!S.open || S.hover < 0) return; const s = S.slots[S.hover]; if (!s || s.list.length < 2) return;
  const c = cur(s, S.hover); S.sel[s.id] = (c.k + (e.deltaY > 0 ? 1 : -1) + c.n) % c.n; draw();
});
addEventListener('mousedown', e => { if (S.open && e.button === 0) release(); });
addEventListener('keydown', e => { if (S.open && e.key === 'Escape') { post('cancel'); } });
function release() {
  if (!S.open) return;
  const s = S.hover >= 0 ? S.slots[S.hover] : null;
  if (!s) { post('cancel'); return; }
  if (s.unarmed) { post('select', { unarmed: true }); return; }
  const w = cur(s, S.hover); if (!w) { post('cancel'); return; }
  post('select', { slot: w.slot });
}
addEventListener('message', ev => {
  const d = ev.data || {};
  if (d.a === 'open') {
    S = { slots: d.slots || [], hover: -1, sel: {}, open: true };
    const c = d.colors || {}, st = document.documentElement.style;
    [['hover', 'hover'], ['equipped', 'eq'], ['glass', 'glass'], ['border', 'bd'], ['text', 'tx'], ['muted', 'mu']].forEach(([k, v]) => { if (c[k]) st.setProperty('--' + v, c[k]); });
    $r.classList.remove('hidden'); draw();
  } else if (d.a === 'close') { S.open = false; $r.classList.add('hidden'); }
  else if (d.a === 'release') release();
});
