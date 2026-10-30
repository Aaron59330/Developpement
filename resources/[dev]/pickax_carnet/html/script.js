'use strict';
const $root = document.getElementById('root');
const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const money = n => Number(n || 0).toLocaleString('fr-FR') + ' $';
const num = n => Number(n || 0).toLocaleString('fr-FR', { maximumFractionDigits: 1 });
const left = sec => { sec = Math.max(0, Math.floor(sec)); const d = Math.floor(sec / 86400), h = Math.floor(sec % 86400 / 3600), m = Math.floor(sec % 3600 / 60); return d ? `${d} j ${h} h` : h ? `${h} h ${String(m).padStart(2, '0')}` : `${m} min`; };
const TIER = { 1: ['Facile', 't1'], 2: ['Moyen', 't2'], 3: ['Difficile', 't3'] };
let D = null, timer = null, tick = null, t0 = 0;

function bar(p, t, done) { const pc = Math.min(100, t > 0 ? p / t * 100 : 0); return `<div class="bar"><i style="width:${done ? 100 : pc}%"></i></div><div class="sub"><span>${done ? 'Terminé' : num(p) + ' / ' + num(t)}</span><span>${Math.floor(done ? 100 : pc)} %</span></div>`; }

function render() {
  const sc = $root.querySelector('.cn') ? $root.querySelector('.cn').scrollTop : 0;
  paint();
  const cn = $root.querySelector('.cn'); if (cn && sc) cn.scrollTop = sc;
}
function paint() {
  const d = D, days = d.rewards.map((r, i) => {
    const n = i + 1, cls = n < d.cycleDay ? 'done' : n === d.cycleDay ? 'now' : '';
    const short = r >= 1000 ? (r / 1000).toLocaleString('fr-FR', { maximumFractionDigits: 1 }) + 'k' : r;
    return `<div class="day ${cls}" title="${money(r)}">J${n}<b>${n < d.cycleDay ? '✓' : short}</b></div>`;
  }).join('');
  const goals = d.goals.map(g => `<div class="goal ${g.done ? 'done' : ''}"><div class="row"><span class="chip ${TIER[g.tier][1]}">${TIER[g.tier][0]}</span><span class="t">${esc(g.label)}</span><span class="rw">+${money(g.reward)}</span></div>${bar(g.progress, g.target, g.done)}</div>`).join('');
  const week = d.week ? `<div class="card"><h2>Objectif de la semaine <span>reste <i data-lf="week" style="font-style:inherit">${left(d.left.week)}</i></span></h2><div class="big">${esc(d.week.label)}</div>${bar(d.week.progress, d.week.target, d.week.done)}<div class="mut" style="margin-top:6px">Récompense : <span class="rw">${money(d.week.reward)}</span></div></div>` : '';
  const c = d.community;
  const comm = c ? `<div class="card"><h2>Défi de la ville <span>reste <i data-lf="week" style="font-style:inherit">${left(d.left.week)}</i></span></h2><div class="big">${esc(c.label)}</div>${bar(c.progress, c.target, c.done)}
      <div class="mut" style="margin-top:6px">Ta contribution : <b style="color:#fff">${num(c.mine)}</b>${c.done ? (c.paid ? ' · récompense reçue ✓' : c.mine >= c.min ? '' : ` · il fallait ${c.min} pour participer`) : c.mine >= c.min ? ' · tu touches ta part si la ville réussit' : ` · encore ${num(c.min - c.mine)} pour toucher ta part (${money(c.reward)})`}</div>
      ${c.boost && c.boost.swing ? `<div class="boost">Si la ville réussit : <b>gains +${Math.round(c.boost.swing * 100)} % pendant ${c.boost.hours} h</b> pour tout le monde</div>` : ''}</div>` : '';
  const places = d.places.length ? `<div class="card"><h2>Lieux du jour <span>${d.places.filter(p => p.seen).length} / ${d.places.length}</span></h2><div class="places">${d.places.map(p => `<span class="pl ${p.seen ? 'seen' : ''}">${p.seen ? '✓ ' : ''}${esc(p.label)}</span>`).join('')}</div></div>` : '';
  const done = d.goals.filter(g => g.done).length;
  $root.innerHTML = `<div class="cn"><div class="cn-head"><div class="cn-logo"><img data-pk-logo src="${esc(window.PICKAX_LOGO || 'https://cfx-nui-pickax_theme/logo/logo.png')}" alt="" onerror="this.style.visibility='hidden'"></div><div><h1>Carnet</h1><small>Tes objectifs, ta série et ceux de toute la ville</small></div><div class="sp"></div><button class="cn-x" data-a="close" title="Fermer">✕</button></div>
    <div class="cn-body">
      <div class="cn-col"><div class="card"><h2>Série de connexion <span>record ${d.best}</span></h2><div class="flame"><b>${d.streak}</b><span>jour${d.streak > 1 ? 's' : ''} d'affilée</span></div><div class="mut">Reviens chaque jour : la récompense monte jusqu'au jour 7.</div><div class="days">${days}</div></div>${places}</div>
      <div class="cn-col"><div class="card"><h2>Objectifs du jour <span>${done} / ${d.goals.length} · nouveaux dans <i data-lf="day" style="font-style:inherit">${left(d.left.day)}</i></span></h2>${goals}
        <div class="bonus ${d.bonus.done ? 'done' : ''}"><span>${d.bonus.done ? '✓ Journée parfaite !' : 'Termine les 3 objectifs'}</span><span class="rw">+${money(d.bonus.amount)}</span></div></div></div>
      <div class="cn-col">${week}${comm}</div>
    </div><div class="foot">Les récompenses sont versées automatiquement sur ton compte. Touche ${esc(d.key)} pour ouvrir / fermer le carnet. ${d.total} objectif(s) terminé(s) au total.</div></div>`;
}

// les compteurs « nouveaux dans … » / « reste … » avancent chaque seconde sans redessiner
function tickLeft() { if (!D || !D.left) return; const el = $root.querySelectorAll('[data-lf]'); const dt = Math.floor((Date.now() - D._at) / 1000); el.forEach(e => { const base = D.left[e.dataset.lf]; e.textContent = left(Math.max(0, base - dt)); }); }
async function refresh() {
  try {
    const r = await fetch('https://pickax_carnet/refresh', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' }).then(x => x.json());
    if (r && r.ok) { D = r; D._at = Date.now(); render(); }
  } catch (e) {}
}
function close() { clearInterval(timer); clearInterval(tick); $root.classList.add('hidden'); $root.innerHTML = ''; }
function post(name) { try { fetch('https://pickax_carnet/' + name, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' }); } catch (e) {} }

window.addEventListener('message', e => {
  const m = e.data;
  if (m.action === 'open') { D = m.data; D._at = Date.now(); $root.classList.remove('hidden'); render(); clearInterval(timer); timer = setInterval(refresh, 8000); clearInterval(tick); tick = setInterval(tickLeft, 1000); }
  else if (m.action === 'update') { D = m.data; D._at = Date.now(); if (!$root.classList.contains('hidden')) render(); }
  else if (m.action === 'close') close();
});
$root.addEventListener('click', e => { if (e.target.closest('[data-a="close"]') || e.target === $root) post('close'); });
window.addEventListener('keydown', e => { if (e.key === 'Escape' || e.key === 'F3') post('close'); });
