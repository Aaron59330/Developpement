'use strict';
var root = document.getElementById('root');
var LIST = [];
var QUERY = '';

var IC = {
  job: '<svg class="ic" viewBox="0 0 24 24"><rect x="3" y="7" width="18" height="13" rx="2"/><path d="M9 7V5a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/><path d="M3 13h18"/></svg>',
  gang: '<svg class="ic" viewBox="0 0 24 24"><path d="M12 3l8 3v6c0 4.5-3.2 8-8 9-4.8-1-8-4.5-8-9V6z"/><path d="M9 12l2 2 4-4"/></svg>',
  shop: '<svg class="ic" viewBox="0 0 24 24"><path d="M6 7h12l1 13H5z"/><path d="M9 7a3 3 0 0 1 6 0"/></svg>',
  world: '<svg class="ic" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/><path d="M3 12h18"/><path d="M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18"/></svg>',
  event: '<svg class="ic" viewBox="0 0 24 24"><path d="M13 2L4 14h7l-1 8 9-12h-7z"/></svg>',
  minigames: '<svg class="ic" viewBox="0 0 24 24"><path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0zM17 5h3v2a3 3 0 0 1-3 3M7 5H4v2a3 3 0 0 0 3 3"/></svg>',
  grid: '<svg class="ic" viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg>',
  search: '<svg class="ic" viewBox="0 0 24 24"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>',
  close: '<svg class="ic" viewBox="0 0 24 24"><path d="M6 6l12 12M18 6L6 18"/></svg>',
  arrow: '<svg class="ic" viewBox="0 0 24 24" style="width:16px;height:16px"><path d="M5 12h14M13 6l6 6-6 6"/></svg>'
};

function esc(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); }
function post(name, data) {
  var res = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_builderhub';
  return fetch('https://' + res + '/' + name, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data || {}) }).catch(function () {});
}

function card(b) {
  var on = b.state === 'started';
  var chips = '';
  if (on && b.stats && b.stats.length) {
    b.stats.forEach(function (s) { chips += '<div class="chip"><b>' + esc(s[1]) + '</b><span>' + esc(s[0]) + '</span></div>'; });
  } else if (on) {
    chips = '<div class="chip empty">Aucune donnée pour le moment</div>';
  } else {
    chips = '<div class="chip empty">Ressource arrêtée : <code style="margin-left:8px">ensure ' + esc(b.id) + '</code></div>';
  }
  return '<div class="card' + (on ? '' : ' off') + '" data-id="' + esc(b.id) + '">' +
    '<div class="top"><div class="tile lg">' + (IC[b.icon] || IC.grid) + '</div>' +
    '<div class="grow"><h2>' + esc(b.label) + '</h2><span class="pill' + (on ? '' : ' off') + '">' + (on ? 'Actif' : 'Arrêté') + '</span></div></div>' +
    '<p class="desc">' + esc(b.desc) + '</p>' +
    '<div class="chips">' + chips + '</div>' +
    '<div class="foot"><code>/' + esc(b.command) + '</code><button class="primary"' + (on ? '' : ' disabled') + ' data-open="' + esc(b.id) + '">Ouvrir ' + IC.arrow + '</button></div>' +
    '</div>';
}

function render() {
  var q = QUERY.trim().toLowerCase();
  var shown = LIST.filter(function (b) { return !q || (b.label + ' ' + b.desc + ' ' + b.command).toLowerCase().indexOf(q) !== -1; });
  var active = LIST.filter(function (b) { return b.state === 'started'; }).length;
  var total = 0;
  LIST.forEach(function (b) { if (b.stats && b.stats[0]) total += Number(b.stats[0][1]) || 0; });
  root.innerHTML =
    '<div class="shell">' +
    '<div class="head"><img class="plogo" data-pk-logo src="' + (window.PICKAX_LOGO || 'https://cfx-nui-pickax_theme/logo/logo.png') + '" alt="" onerror="this.style.visibility=\'hidden\'"><div class="tile">' + IC.grid + '</div>' +
    '<div class="ttl"><h1>Builders</h1><p>Accès rapide à tous les builders du serveur</p></div>' +
    '<div class="search">' + IC.search + '<input id="q" placeholder="Rechercher un builder…" value="' + esc(QUERY) + '" autocomplete="off"></div>' +
    '<button class="icon" id="x" title="Fermer (Échap)">' + IC.close + '</button></div>' +
    '<div class="body">' +
    '<div class="sum">' +
    '<div class="box"><div class="eyebrow">Builders actifs</div><div class="val">' + active + '<small>/ ' + LIST.length + '</small></div></div>' +
    '<div class="box"><div class="eyebrow">Éléments créés</div><div class="val">' + total + '<small>au total</small></div></div>' +
    '<div class="box"><div class="eyebrow">Raccourci</div><div class="val" style="font-size:18px;padding-top:4px"><code>/builders</code></div></div>' +
    '</div>' +
    '<div class="grid">' + (shown.length ? shown.map(card).join('') : '<div class="empty-search">Aucun builder ne correspond à « ' + esc(QUERY) + ' ».</div>') + '</div>' +
    '</div>' +
    '<div class="bottom"><span>Clique sur un builder pour l\'ouvrir</span><span><kbd>Entrée</kbd> ouvre le premier résultat · <kbd>Échap</kbd> ferme</span></div>' +
    '</div>';
  var q2 = document.getElementById('q');
  if (q2) {
    q2.addEventListener('input', function () { QUERY = q2.value; var pos = q2.selectionStart; render(); var n = document.getElementById('q'); n.focus(); n.setSelectionRange(pos, pos); });
  }
}

function launch(id) { if (id) post('launch', { id: id }); }

root.addEventListener('click', function (e) {
  if (e.target.closest('#x')) return post('close');
  var btn = e.target.closest('[data-open]');
  if (btn) return launch(btn.getAttribute('data-open'));
  var c = e.target.closest('.card');
  if (c && !c.classList.contains('off')) launch(c.getAttribute('data-id'));
});

document.addEventListener('keydown', function (e) {
  if (root.classList.contains('hidden')) return;
  if (e.key === 'Escape') post('close');
  if (e.key === 'Enter') {
    var q = QUERY.trim().toLowerCase();
    var first = LIST.filter(function (b) { return b.state === 'started' && (!q || (b.label + ' ' + b.desc + ' ' + b.command).toLowerCase().indexOf(q) !== -1); })[0];
    if (first) launch(first.id);
  }
});

window.addEventListener('message', function (e) {
  var m = e.data || {};
  if (m.a === 'open') {
    LIST = m.list || [];
    QUERY = '';
    root.classList.remove('hidden');
    render();
    var q = document.getElementById('q'); if (q) q.focus();
  } else if (m.a === 'close') {
    root.classList.add('hidden');
    root.innerHTML = '';
  }
});
