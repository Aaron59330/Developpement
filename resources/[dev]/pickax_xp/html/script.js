'use strict';
const $r = document.getElementById('root');
const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const fmt = n => Number(n || 0).toLocaleString('fr-FR');
const post = n => { try { fetch('https://pickax_xp/' + n, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' }); } catch (e) {} };
function draw(d) {
  const pct = d.nextXp ? Math.max(0, Math.min(100, (d.xp - d.floor) / (d.nextXp - d.floor) * 100)) : 100;
  const next = d.rewards.find(r => !r.got);
  const rw = d.rewards.map(r => `<div class="rw ${r.got ? 'got' : (next && next.level === r.level ? 'next' : '')}"><div class="n">${r.level}</div><div class="d"><small>Niveau ${r.level}${r.got ? '' : ' · ' + fmt(r.need) + ' XP'}</small>${r.items.map(i => `<div>${esc(i.text)}</div>`).join('')}</div><div class="st">${r.got ? '✓ obtenu' : (next && next.level === r.level ? 'prochain' : 'à venir')}</div></div>`).join('');
  const acts = d.actions.map(a => `<div class="row"><span>${esc(a.label)}</span><span>${esc(a.txt)}</span></div>`).join('');
  const extra = [d.playtime ? `<div class="row"><span>Temps de jeu</span><span>+${d.playtime.xp} XP / ${d.playtime.every} min</span></div>` : '', d.daily ? `<div class="row"><span>Connexion du jour</span><span>+${d.daily} XP</span></div>` : ''].join('');
  const log = (d.log || []).map(l => `<div class="row"><span>${esc(l.label)}</span><span>+${l.xp} XP</span></div>`).join('') || '<div class="mut">Aucun gain récent. Achète, travaille, cuisine, répare… tout rapporte de l\'XP.</div>';
  $r.innerHTML = `<div class="win"><div class="top"><img data-pk-logo alt="" onerror="this.style.display='none'"><div><h1>NIVEAU <em>ET RÉCOMPENSES</em></h1><small>Chaque action sur le serveur te fait progresser</small></div><div class="sp"></div><button class="x" id="x">✕</button></div>
  <div class="body"><div class="col"><div class="card"><div class="lvl"><div class="badge"><b>${d.level}</b><small>NIVEAU</small></div><div class="t"><b>${d.level >= d.max ? 'Niveau maximum' : 'Niveau ' + d.level}</b><span>${fmt(d.xp)} XP au total</span></div></div>
    ${d.nextXp ? `<div class="bar"><i style="width:${pct}%"></i></div><div class="xpl"><span>${fmt(d.xp - d.floor)} / ${fmt(d.nextXp - d.floor)} XP</span><span>niveau ${d.level + 1}</span></div>` : '<div class="bar"><i style="width:100%"></i></div>'}</div>
    <div class="card"><h2>Derniers gains</h2><div class="log">${log}</div></div></div>
  <div class="col"><div class="card"><h2>Récompenses <span>${d.rewards.filter(r => r.got).length} / ${d.rewards.length}</span></h2>${rw}</div></div>
  <div class="col"><div class="card"><h2>Comment gagner de l'XP</h2>${acts}${extra}</div></div></div></div>`;
  const img = $r.querySelector('img[data-pk-logo]'); if (img) img.src = window.PICKAX_LOGO || 'https://cfx-nui-pickax_theme/logo/logo.png';
  document.getElementById('x').onclick = () => post('close');
}
window.addEventListener('message', e => { const m = e.data || {}; if (m.a === 'open') { draw(m.d); $r.classList.remove('hidden'); } else if (m.a === 'close') { $r.classList.add('hidden'); $r.innerHTML = ''; } });
document.addEventListener('keydown', e => { if (e.key === 'Escape' && !$r.classList.contains('hidden')) post('close'); });
$r.addEventListener('mousedown', e => { if (e.target === $r) post('close'); });
