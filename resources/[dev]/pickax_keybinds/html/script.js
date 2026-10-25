const $root = document.getElementById('root');
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
async function post(name, body) {
  try { const r = await fetch(`https://${GetParentResourceName()}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) }); return await r.json(); }
  catch (e) { return null; }
}
const K = { data: { actions: [], conflicts: [] }, q: '', g: '',
  open(d) { this.data = d; this.q = ''; this.g = ''; $root.classList.remove('hidden'); this.render(); },
  close() { $root.classList.add('hidden'); post('close'); },
  render() {
    const d = this.data, q = this.q.toLowerCase();
    const groups = [...new Set(d.actions.map(a => a.group))];
    const list = d.actions.filter(a => (!this.g || a.group === this.g) && (!q || (a.label + ' ' + a.key + ' ' + a.cmd).toLowerCase().includes(q)));
    let html = '', last = '';
    list.forEach(a => {
      if (a.group !== last) { html += `<div class="grp">${esc(a.group)}</div>`; last = a.group; }
      html += `<div class="row ${a.conflict ? 'c' : ''}"><div class="n"><b>${esc(a.label)}</b><small>/${esc(a.cmd.replace(/^\+/, ''))}${a.default ? ' · par défaut ' + esc(a.default) : ''}</small></div>
        ${a.conflict ? '<span class="tag e">Conflit</span>' : ''}${a.changed ? '<span class="tag m">Personnalisée</span>' : ''}<kbd class="${a.key ? '' : 'none'}">${a.key ? esc(a.key) : 'Non attribuée'}</kbd></div>`;
    });
    $root.innerHTML = `<div class="panel"><div class="head"><div class="logo">⌨️</div><div><h2>Mes touches</h2><p>Les touches réellement attribuées sur ton jeu</p></div><div class="sp"></div><button data-a="refresh">Actualiser</button><button data-a="close">✕</button></div>
      <div class="tools"><input id="q" placeholder="Rechercher une action ou une touche…" value="${esc(this.q)}"><div class="chips"><span class="chip ${this.g ? '' : 'on'}" data-a="grp" data-g="">Tout</span>${groups.map(g => `<span class="chip ${this.g === g ? 'on' : ''}" data-a="grp" data-g="${esc(g)}">${esc(g)}</span>`).join('')}</div></div>
      ${d.conflicts.length ? `<div class="warn"><b>${d.conflicts.length} conflit(s) de touches</b> : ${d.conflicts.map(c => `<b>${esc(c.key)}</b> → ${c.names.map(esc).join(' + ')}`).join(' · ')}. Deux actions sur la même touche se déclenchent ensemble : change l'une des deux.</div>` : ''}
      <div class="list">${html || '<p style="color:var(--muted)">Aucun raccourci trouvé.</p>'}</div>
      <div class="help"><b>Changer une touche :</b> <b>Échap</b> → <b>Paramètres</b> → <b>Raccourcis clavier</b> → <b>FiveM</b>, cherche le nom de l'action puis clique et appuie sur la nouvelle touche. Reviens ici et clique sur <b>Actualiser</b> pour vérifier.</div></div>`;
    const q2 = document.getElementById('q'); if (q2 && this.focusQ) { q2.focus(); q2.setSelectionRange(this.pos, this.pos); }
  },
};
document.addEventListener('input', e => { if (e.target.id !== 'q') return; K.q = e.target.value; K.pos = e.target.selectionStart; K.focusQ = true; K.render(); });
document.addEventListener('click', async e => {
  const el = e.target.closest('[data-a]'); if (!el) return; K.focusQ = false;
  if (el.dataset.a === 'close') K.close();
  else if (el.dataset.a === 'grp') { K.g = el.dataset.g; K.render(); }
  else if (el.dataset.a === 'refresh') { const d = await post('refresh'); if (d) { K.data = d; K.render(); } }
});
document.addEventListener('keydown', e => { if (e.key === 'Escape' && !$root.classList.contains('hidden')) K.close(); });
window.addEventListener('message', e => { const d = e.data || {}; if (d.action === 'open') K.open(d); else if (d.action === 'close') $root.classList.add('hidden'); });
