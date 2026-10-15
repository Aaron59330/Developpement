'use strict';
const $root = document.getElementById('root');
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const money = n => Number(n || 0).toLocaleString('fr-FR') + ' $';
const res = () => (typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_pause');
const post = (name, body) => fetch(`https://${res()}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) }).catch(() => { });

const I = {
  play: '<polygon points="6 4 20 12 6 20 6 4"/>',
  map: '<path d="m3 6 6-3 6 3 6-3v15l-6 3-6-3-6 3z"/><path d="M9 3v15M15 6v15"/>',
  gear: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>',
  out: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/>',
  power: '<path d="M18.4 6.6a9 9 0 1 1-12.8 0M12 2v10"/>',
  discord: '<path d="M8 12h.01M16 12h.01"/><path d="M7.5 7.5A14 14 0 0 1 12 7a14 14 0 0 1 4.5.5c1.5 2.2 2.5 4.6 3 8.5-1.4 1-2.9 1.6-4.5 2l-1-2c-1.3.4-2.7.4-4 0l-1 2c-1.6-.4-3.1-1-4.5-2 .5-3.9 1.5-6.3 3-8.5z"/>',
  book: '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20V3H6.5A2.5 2.5 0 0 0 4 5.5z"/><path d="M4 19.5V21h16"/>',
  cart: '<circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.7 13.4a2 2 0 0 0 2 1.6h9.7a2 2 0 0 0 2-1.6L23 6H6"/>',
  link: '<path d="M10 13a5 5 0 0 0 7.5.5l3-3a5 5 0 0 0-7-7l-1.7 1.7"/><path d="M14 11a5 5 0 0 0-7.5-.5l-3 3a5 5 0 0 0 7 7l1.7-1.7"/>',
  clock: '<circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>',
};
const ic = n => `<svg viewBox="0 0 24 24">${I[n] || I.link}</svg>`;
const initials = n => String(n || '?').split(/\s+/).map(w => w[0]).join('').slice(0, 2).toUpperCase();
const fmt = s => { s = Math.max(0, Math.floor(s)); const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60); return h > 0 ? `${h} h ${String(m).padStart(2, '0')}` : `${m} min`; };

let opened = 0, focusIdx = 0;

function build(d) {
  const p = d.player || {}, s = d.server || {}, c = d.cfg || {}, b = c.buttons || {};
  const items = [];
  const add = (key, icon, label, kbd) => { if (b[key] !== false) items.push({ key, icon, label, kbd }); };
  add('resume', 'play', 'Reprendre', 'ÉCHAP');
  add('map', 'map', 'Carte', 'M');
  add('settings', 'gear', 'Paramètres', 'P');
  const menu = items.map((it, i) => `<button class="btn" data-k="${it.key}" style="animation-delay:${i * 0.05}s"><span class="ico">${ic(it.icon)}</span>${esc(it.label)}<span class="k">${it.kbd}</span></button>`).join('');
  const exits = [];
  if (b.disconnect !== false) exits.push(`<button class="btn danger" data-k="disconnect" style="animation-delay:.2s"><span class="ico">${ic('out')}</span>Se déconnecter</button>`);
  if (b.quit !== false) exits.push(`<button class="btn danger" data-k="quit" style="animation-delay:.25s"><span class="ico">${ic('power')}</span>Quitter le jeu</button>`);
  const pct = s.max ? Math.min(100, Math.round((s.online || 0) / s.max * 100)) : 0;
  const links = (c.links || []).filter(l => l.url);
  $root.innerHTML = `<div class="left"><div class="brand"><img src="logo.png" alt=""><div><h1>${esc(c.name)}</h1><p>${esc(c.tagline)}</p></div></div>
      <div class="tag">Menu pause</div><div class="menu">${menu}${exits.length ? '<div class="sep"></div>' + exits.join('') : ''}</div>
      <div class="foot"><kbd>↑</kbd><kbd>↓</kbd> naviguer <kbd>Entrée</kbd> valider <kbd>Échap</kbd> reprendre</div></div>
    <div class="right">
      <div class="card"><div class="who"><div class="av">${esc(initials(p.name))}</div><div><h2>${esc(p.name)}</h2><small>ID ${esc(p.id)}</small></div></div>
        <div class="chips">${p.job ? `<span class="chip blue">Métier <b>${esc(p.job)}${p.grade ? ' · ' + esc(p.grade) : ''}</b></span>` : ''}${p.job2 ? `<span class="chip">Organisation <b>${esc(p.job2)}${p.grade2 ? ' · ' + esc(p.grade2) : ''}</b></span>` : ''}<span class="chip">${ic('clock')}<b id="sess">0 min</b> de session</span></div>
        <div class="money"><div class="m g"><span>Liquide</span><b>${money(p.money)}</b></div><div class="m b"><span>Banque</span><b>${money(p.bank)}</b></div><div class="m r"><span>Argent sale</span><b>${money(p.dirty)}</b></div></div></div>
      <div class="card"><div class="title">Serveur</div><div class="srv"><div class="s"><span>Joueurs</span><b>${s.online ?? '—'}<small style="font-size:14px;color:var(--muted)"> / ${s.max ?? '—'}</small></b></div><div class="s"><span>En ligne depuis</span><b style="font-size:20px">${s.uptime != null ? fmt(s.uptime) : '—'}</b></div><div class="s"><span>Heure</span><b style="font-size:20px" id="clk"></b></div></div><div class="bar"><i style="width:${pct}%"></i></div></div>
      ${links.length ? `<div class="card"><div class="title">Raccourcis</div><div class="links">${links.map(l => `<button class="lk" data-url="${esc(l.url)}">${ic(l.icon || 'link')}${esc(l.label)}</button>`).join('')}</div></div>` : ''}
    </div>`;
  setFocus(0);
}

function setFocus(i) {
  const btns = [...document.querySelectorAll('.btn')];
  if (!btns.length) return;
  focusIdx = (i + btns.length) % btns.length;
  btns.forEach((x, n) => x.classList.toggle('f', n === focusIdx));
}

const clock = () => {
  const e = document.getElementById('clk'); if (e) e.textContent = new Date().toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
  const s = document.getElementById('sess'); if (s) s.textContent = fmt((Date.now() - opened) / 1000);
};
setInterval(clock, 1000);

const act = key => (key === 'resume' ? post('close') : post(key));

document.addEventListener('click', e => {
  const b = e.target.closest('.btn'); if (b) return act(b.dataset.k);
  const l = e.target.closest('.lk');
  if (l && l.dataset.url) { if (window.invokeNative) window.invokeNative('openUrl', l.dataset.url); else window.open(l.dataset.url, '_blank'); }
});
document.addEventListener('mouseover', e => { const b = e.target.closest('.btn'); if (b) setFocus([...document.querySelectorAll('.btn')].indexOf(b)); });
document.addEventListener('keydown', e => {
  if ($root.classList.contains('hidden')) return;
  if (e.key === 'Escape' || e.key === 'Backspace') return post('close');
  if (e.key === 'ArrowDown') { e.preventDefault(); setFocus(focusIdx + 1); }
  else if (e.key === 'ArrowUp') { e.preventDefault(); setFocus(focusIdx - 1); }
  else if (e.key === 'Enter') { const b = document.querySelectorAll('.btn')[focusIdx]; if (b) act(b.dataset.k); }
  else if (e.key.toLowerCase() === 'm') post('map');
  else if (e.key.toLowerCase() === 'p') post('settings');
});

window.addEventListener('message', e => {
  const d = e.data || {};
  if (d.action === 'open') { opened = Date.now(); $root.classList.remove('hidden', 'out'); build(d); clock(); }
  else if (d.action === 'close') { $root.classList.add('out'); setTimeout(() => { $root.classList.add('hidden'); $root.innerHTML = ''; }, 180); }
});
