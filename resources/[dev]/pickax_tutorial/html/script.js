const $root = document.getElementById('root');
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
async function post(name, body) {
  try { const r = await fetch(`https://${GetParentResourceName()}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) }); return await r.json(); }
  catch (e) { return { ok: false }; }
}
const T = { steps: [], i: 0, skippable: true, reward: false, done: null,
  open(d) { this.steps = d.steps || []; this.skippable = d.skippable !== false; this.reward = !!d.reward; this.i = 0; this.done = null; $root.classList.remove('hidden'); this.render(); },
  async close(skipped) { const r = this.done || await post('finish', { skipped }); $root.classList.add('hidden'); post('close'); return r; },
  render() {
    const s = this.steps[this.i]; if (!s) return;
    const last = this.i === this.steps.length - 1, n = this.steps.length;
    $root.innerHTML = `<div class="card"><div class="bar"><i style="width:${((this.i + 1) / n) * 100}%"></i></div>
      <div class="body"><div class="ico">${esc(s.icon)}</div><div><div class="step">ÉTAPE ${this.i + 1} / ${n}</div><h1>${esc(s.title)}</h1><p class="t">${esc(s.text)}</p>
        ${s.keys && s.keys.length ? `<div class="keys">${s.keys.map(k => `<div class="key"><kbd>${esc(k[0])}</kbd><span>${esc(k[1])}</span></div>`).join('')}</div>` : ''}
        ${s.bullets && s.bullets.length ? `<ul>${s.bullets.map(b => `<li>${esc(b)}</li>`).join('')}</ul>` : ''}
        ${last && this.done && this.done.reward ? `<div class="reward">🎁 Récompense reçue : ${this.rewardText(this.done.reward)}</div>` : ''}</div></div>
      <div class="foot"><div class="dots">${this.steps.map((_, k) => `<b class="${k === this.i ? 'on' : ''}"></b>`).join('')}</div>
        ${this.skippable && !last ? '<button class="ghost" data-a="skip">Passer</button>' : ''}${this.i > 0 ? '<button data-a="prev">Précédent</button>' : ''}
        <button class="primary" data-a="${last ? 'end' : 'next'}">${last ? (this.reward ? 'Terminer et recevoir ma récompense' : 'Commencer à jouer') : 'Suivant'}</button></div></div>`;
  },
  rewardText(r) { const p = []; if (r.money) p.push(r.money + ' $ en liquide'); if (r.bank) p.push(r.bank + ' $ en banque'); (r.items || []).forEach(i => p.push((i.count || 1) + '× ' + i.name)); return p.join(', ') || 'aucune'; },
};
document.addEventListener('click', async e => {
  const el = e.target.closest('[data-a]'); if (!el) return;
  const a = el.dataset.a;
  if (a === 'next') { T.i++; T.render(); }
  else if (a === 'prev') { T.i--; T.render(); }
  else if (a === 'skip') { await T.close(true); }
  else if (a === 'end') {
    if (T.done) return T.close(false);
    const r = await post('finish', { skipped: false }); T.done = r;
    if (r && r.reward) { T.render(); el.disabled = true; setTimeout(() => T.close(false), 3200); } else T.close(false);
  }
});
document.addEventListener('keydown', e => { if ($root.classList.contains('hidden')) return; if (e.key === 'ArrowRight' && T.i < T.steps.length - 1) { T.i++; T.render(); } else if (e.key === 'ArrowLeft' && T.i > 0) { T.i--; T.render(); } });
window.addEventListener('message', e => { const d = e.data || {}; if (d.action === 'open') T.open(d); else if (d.action === 'close') $root.classList.add('hidden'); });
