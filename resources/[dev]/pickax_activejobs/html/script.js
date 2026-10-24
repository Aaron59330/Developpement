'use strict';
const $root = document.getElementById('root');
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const money = n => Number(n || 0).toLocaleString('fr-FR') + ' $';
const ICONS = {
  trash: '<path d="M3 6h18M8 6V4h8v2M6 6l1 14h10l1-14M10 10v6M14 10v6"/>', wrench: '<path d="M14.7 6.3a4 4 0 0 0 5 5L21 21l-3-3-9.7-9.7a4 4 0 0 0 5-5L12 6l2.7.3z"/><path d="M3 21l6-6"/>',
  drop: '<path d="M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11z"/>', truck: '<path d="M1 6h13v10H1zM14 10h5l3 3v3h-8"/><circle cx="6" cy="18" r="2"/><circle cx="18" cy="18" r="2"/>',
  sprout: '<path d="M7 20h10M12 20V10M12 10C12 6 9 4 5 4c0 4 2 6 7 6M12 12c0-3 2-5 6-5 0 3-2 5-6 5"/>', flame: '<path d="M12 3c1 4 5 6 5 11a5 5 0 0 1-10 0c0-2 1-3 2-4 0 2 1 3 2 3 0-4-1-6 1-10z"/>',
  train: '<rect x="5" y="3" width="14" height="14" rx="3"/><path d="M5 11h14M9 21l2-4M15 21l-2-4"/><circle cx="9" cy="14" r=".6"/><circle cx="15" cy="14" r=".6"/>',
};
const post = (name, body) => fetch(`https://${GetParentResourceName()}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) }).then(r => r.json()).catch(() => ({}));

function apply(rgb) {
  if (!Array.isArray(rgb)) return;
  document.documentElement.style.setProperty('--accent', `rgb(${rgb.join(',')})`);
  document.documentElement.style.setProperty('--accent-rgb', rgb.join(','));
}

function render(d) {
  const pct = Math.min(100, Math.round(d.xpInLevel / d.xpPerLevel * 100));
  const grades = d.grades.map((g, i) => `<div>${i === 0 ? '' : ''}<b>${esc(g.label)}</b> — ${money(g.salary)} / paie</div>`).join('');
  $root.innerHTML = `<div class="panel"><div class="head"><div class="ic"><svg viewBox="0 0 24 24">${ICONS[d.icon] || ICONS.wrench}</svg></div>
    <div><h1>${esc(d.label)}</h1><div class="sub">Grade : <b>${esc(d.gradeLabel || 'employé')}</b></div></div><button class="x" data-a="close">✕</button></div>
    <div class="body"><p class="desc">${esc(d.desc)}</p>
      <div class="card"><div class="row"><span class="lvl">Niveau ${d.level}${d.level >= d.maxLevel ? ' (max)' : ''}</span><span class="chip">+${d.payBonus}% de paie</span></div>
        <div class="bar"><i style="width:${d.level >= d.maxLevel ? 100 : pct}%"></i></div>
        <div class="grid3" style="margin-top:14px"><div><b>${d.done}</b><small>missions</small></div><div><b>${money(d.earned)}</b><small>gagnés</small></div><div><b>${d.xp}</b><small>XP</small></div></div></div>
      <div class="card grades">${grades}</div>
      ${d.active ? `<div class="row"><span class="chip ok">Activité en cours</span></div><button class="btn danger" data-a="stop">Terminer l'activité</button>` : `<button class="btn pri" data-a="start">Commencer l'activité</button>`}
    </div></div>`;
  $root.dataset.pid = d.pointId;
}

window.addEventListener('message', e => {
  const m = e.data;
  if (m.action === 'open') { apply(m.accent); $root.classList.remove('hidden'); render(m.data); }
  else if (m.action === 'close') { $root.classList.add('hidden'); $root.innerHTML = ''; }
});
$root.addEventListener('click', async e => {
  const b = e.target.closest('[data-a]'); if (!b) return;
  const a = b.dataset.a, pointId = Number($root.dataset.pid);
  if (a === 'close') return post('close');
  b.disabled = true;
  await post('act', { pointId, what: a });
});
document.addEventListener('keydown', e => { if (e.key === 'Escape' && !$root.classList.contains('hidden')) post('close'); });
