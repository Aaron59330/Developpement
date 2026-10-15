(function () {
'use strict';

// ───────────── Utilitaires ─────────────
var app = document.getElementById('app');

function h(tag, attrs) {
  var el = document.createElement(tag);
  for (var k in (attrs || {})) {
    var v = attrs[k];
    if (v == null || v === false) continue;
    if (k === 'class') el.className = v;
    else if (k === 'text') el.textContent = v;
    else if (k.slice(0, 2) === 'on') el.addEventListener(k.slice(2), v);
    else if (k === 'style') el.style.cssText = v;
    else el.setAttribute(k, v === true ? '' : v);
  }
  for (var i = 2; i < arguments.length; i++) {
    var c = arguments[i];
    if (c == null || c === false) continue;
    if (Array.isArray(c)) c.forEach(function (x) { if (x) el.appendChild(x); });
    else el.appendChild(typeof c === 'string' ? document.createTextNode(c) : c);
  }
  return el;
}
function svg(path) {
  var s = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  s.setAttribute('viewBox', '0 0 24 24');
  s.innerHTML = path; // chemins statiques définis dans ce fichier
  return s;
}
var ICONS = {
  logo: '<path d="M4 7l8-4 8 4v10l-8 4-8-4z"/><path d="M4 7l8 4 8-4M12 11v10"/>',
  loading: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  menu: '<rect x="4" y="4" width="16" height="16" rx="2"/><path d="M8 9h8M8 13h8M8 17h5"/>',
  marker: '<path d="M12 21s7-6.2 7-11a7 7 0 0 0-14 0c0 4.8 7 11 7 11z"/><circle cx="12" cy="10" r="2.5"/>',
  hud: '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M14 9h4M14 13h4M6 9h5v6H6z"/>',
  status: '<path d="M12 3s6 6 6 10.5a6 6 0 0 1-12 0C6 9 12 3 12 3z"/>',
  bell: '<path d="M6 16V11a6 6 0 0 1 12 0v5l2 2H4z"/><path d="M10 20a2 2 0 0 0 4 0"/>',
  queue: '<circle cx="9" cy="8" r="3"/><circle cx="17" cy="9" r="2.4"/><path d="M3 19c0-3.3 2.7-5.4 6-5.4s6 2.1 6 5.4M15.5 14c3 0 5.5 1.7 5.5 4.6"/>',
  undo: '<path d="M9 14L4 9l5-5"/><path d="M4 9h10a6 6 0 0 1 0 12h-3"/>',
  plus: '<path d="M12 5v14M5 12h14"/>', x: '<path d="M6 6l12 12M18 6L6 18"/>',
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  server: '<rect x="3" y="4" width="18" height="7" rx="2"/><rect x="3" y="13" width="18" height="7" rx="2"/><path d="M7 7.5h.01M7 16.5h.01"/>',
  back: '<path d="M15 5l-7 7 7 7"/>',
  home: '<path d="M4 11l8-7 8 7"/><path d="M6 10v10h12V10"/><path d="M10 20v-5h4v5"/>',
  out: '<path d="M10 4H5v16h5"/><path d="M15 8l4 4-4 4M19 12H9"/>'
};
function icon(name) { return svg(ICONS[name] || ICONS.menu); }
function clone(v) { return JSON.parse(JSON.stringify(v)); }
function same(a, b) { return JSON.stringify(a) === JSON.stringify(b); }
function hex2rgb(x) { return [1, 3, 5].map(function (i) { return parseInt(x.slice(i, i + 2), 16); }); }
function rgb2hex(r) { return '#' + r.slice(0, 3).map(function (n) { return ('0' + Math.round(n).toString(16)).slice(-2); }).join(''); }
function rgba(v) { return 'rgba(' + v[0] + ',' + v[1] + ',' + v[2] + ',' + ((v[3] == null ? 255 : v[3]) / 255).toFixed(3) + ')'; }

var toastT;
function toast(msg, kind) {
  var old = document.querySelector('.toast'); if (old) old.remove();
  var t = h('div', { class: 'toast ' + (kind || ''), text: msg }); document.body.appendChild(t);
  clearTimeout(toastT); toastT = setTimeout(function () { t.remove(); }, 4500);
}

function api(path, body) {
  return fetch((REMOTE ? SERVER + '/pickax_panel/' : '') + 'api/' + path, {
    method: body ? 'POST' : 'GET',
    headers: { 'X-Panel-Key': KEY, 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined
  }).then(function (r) { return r.json().then(function (j) { if (!r.ok) throw new Error(j.error || ('Erreur ' + r.status)); return j; }); });
}

// ───────────── État ─────────────
var S = { view: 'servers', sid: null, servers: [], groups: [], pending: [], vals: {}, base: {}, fields: {}, cur: 'home', q: '', st: null, user: null };

function api(path, body, method) {
  return fetch('/api/' + path, {
    method: method || (body ? 'POST' : 'GET'), credentials: 'same-origin',
    headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'px' },
    body: body ? JSON.stringify(body) : undefined
  }).then(function (r) {
    return r.json().then(function (j) {
      if (r.status === 401 && S.user && path !== 'login') { S.user = null; renderLogin('Session expirée, reconnecte-toi.'); }
      if (!r.ok) throw new Error(j.error || ('Erreur ' + r.status));
      return j;
    });
  });
}

function load() {
  return api('servers/' + S.sid).then(function (st) {
    S.st = st; S.groups = st.groups; S.pending = st.pendingRestart || [];
    S.vals = {}; S.base = {}; S.fields = {};
    st.groups.forEach(function (g) { g.fields.forEach(function (f) {
      S.fields[f.id] = f; f.group = g.id;
      if (f.value !== undefined && f.value !== null) { S.vals[f.id] = clone(f.value); S.base[f.id] = clone(f.value); }
    }); });
    if (S.cur !== 'home' && !S.groups.some(function (g) { return g.id === S.cur; })) S.cur = 'home';
  });
}
function dirtyIds(groupId) {
  return Object.keys(S.vals).filter(function (id) {
    return S.fields[id] && (!groupId || S.fields[id].group === groupId) && !same(S.vals[id], S.base[id]);
  });
}

// ───────────── Contrôles ─────────────
function control(f) {
  var id = f.id, wrap = h('div', { class: 'ctl' });
  function set(v) { S.vals[id] = v; refresh(id); }
  var v = S.vals[id];
  if (f.type === 'bool') {
    var cb = h('input', { type: 'checkbox' }); cb.checked = !!v;
    cb.addEventListener('change', function () { set(cb.checked); });
    wrap.appendChild(h('label', { class: 'switch' }, cb, h('i')));
  } else if (f.type === 'number') {
    var num = h('input', { type: 'number', step: f.int ? 1 : 0.05, min: f.min, max: f.max });
    num.value = v;
    var sl = null;
    if (f.min != null && f.max != null) {
      sl = h('input', { type: 'range', min: f.min, max: f.max, step: f.int ? 1 : (f.max - f.min) / 100 }); sl.value = v;
      sl.addEventListener('input', function () { num.value = sl.value; set(Number(sl.value)); });
      wrap.appendChild(sl);
    }
    num.addEventListener('input', function () { if (num.value === '') return; if (sl) sl.value = num.value; set(Number(num.value)); });
    wrap.appendChild(num);
    if (f.unit) wrap.appendChild(h('span', { class: 'sub', text: f.unit }));
  } else if (f.type === 'color') {
    var pick = h('input', { type: 'color' }); pick.value = v;
    var hx = h('input', { type: 'text', class: 'hex', maxlength: 7 }); hx.value = v;
    pick.addEventListener('input', function () { hx.value = pick.value; set(pick.value); });
    hx.addEventListener('input', function () { if (/^#[0-9a-fA-F]{6}$/.test(hx.value)) { pick.value = hx.value; set(hx.value.toLowerCase()); } });
    wrap.append(pick, hx);
  } else if (f.type === 'rgba') {
    var sw = h('div', { class: 'sw' }, h('i', { style: 'background:' + rgba(v) }));
    var cp = h('input', { type: 'color' }); cp.value = rgb2hex(v);
    sw.appendChild(cp);
    var al = null;
    function upd() { sw.firstChild.style.background = rgba(S.vals[id]); }
    cp.addEventListener('input', function () { var n = hex2rgb(cp.value); for (var i = 0; i < 3; i++) S.vals[id][i] = n[i]; upd(); refresh(id); });
    wrap.appendChild(sw);
    if (f.alpha !== false) {
      al = h('input', { type: 'range', min: 0, max: 255 }); al.value = v[3];
      var av = h('span', { text: Math.round(v[3] / 2.55) + '%' });
      al.addEventListener('input', function () { S.vals[id][3] = Number(al.value); av.textContent = Math.round(al.value / 2.55) + '%'; upd(); refresh(id); });
      wrap.appendChild(h('div', { class: 'alpha' }, 'Opacité', al, av));
    }
  } else if (f.type === 'items') {
    var box = h('div', { class: 'items' });
    var draw = function () {
      box.replaceChildren();
      S.vals[id].forEach(function (line, i) {
        var t = h('input', { type: 'text', maxlength: 140 }); t.value = line;
        t.addEventListener('input', function () { S.vals[id][i] = t.value; refresh(id); });
        box.appendChild(h('div', { class: 'row' }, t, h('button', { class: 'icon-btn', title: 'Supprimer', onclick: function () { S.vals[id].splice(i, 1); draw(); refresh(id); } }, icon('x'))));
      });
      box.appendChild(h('button', { class: 'btn sm', onclick: function () { if (S.vals[id].length < 20) { S.vals[id].push(''); draw(); refresh(id); } } }, icon('plus'), 'Ajouter une ligne'));
    };
    draw(); wrap.appendChild(box);
  } else {
    var t = h('input', { type: 'text', maxlength: f.max || 200, placeholder: f.type === 'url' ? 'https://…' : '' }); t.value = v;
    t.addEventListener('input', function () { set(t.value); });
    wrap.appendChild(t);
  }
  return wrap;
}

// ───────────── Aperçus ─────────────
var V = function (id, d) { var x = S.vals[id]; return x === undefined ? d : x; };
var PREVIEW = {
  general: function () {
    var g = function (k, d) { return V('general.' + k, d); };
    var ban = g('bannerDetail', '');
    return h('div', { class: 'pv-q', style: 'text-align:left;width:300px;padding:0;overflow:hidden' },
      h('div', { style: 'height:70px;background:#1b6fb0 center/cover' + (ban ? ";background-image:url('" + ban.replace(/'/g, '%27') + "')" : '') }),
      h('div', { style: 'padding:12px 14px' }, h('b', { text: String(g('name', '')).replace(/\^\d/g, '') }),
        h('div', { class: 'sub', style: 'margin:4px 0 8px;font-size:12px', text: String(g('desc', '')).slice(0, 120) }),
        h('div', { style: 'font-size:11px;color:#6fc8ff', text: String(g('tags', '')).split(',').slice(0, 6).join(' · ') })));
  },
  loading: function () {
    var acc = V('loading.accent', '#00a4ff'), tick = V('loading.ticker', [])[0] || '';
    return h('div', { class: 'pv-loading', style: '--pv-accent:' + acc },
      h('div', { class: 'top' }, h('div', { class: 'pill', text: '♪  ' + V('loading.volume', 10) + '%' }),
        h('div', { class: 'tabs' }, h('span', { text: 'Règlement' }), h('span', { text: 'Discord' }), h('span', { text: 'Boutique' }))),
      h('div', { class: 'bar' }, h('div', { class: 'm' }, h('span', { text: 'Chargement de la carte…' }), h('b', { text: '62%' })), h('div', { class: 't' }, h('i'))),
      h('div', { class: 'tick', text: tick }));
  },
  rageui: function () {
    var on = V('rageui.bannerOn', false), link = V('rageui.bannerLink', '');
    var ban = h('div', { class: 'ban', style: on && link ? "background-image:url('" + link.replace(/'/g, '%27') + "')" : '' }, V('rageui.hideTitle', false) && on ? '' : 'MENU');
    var c = function (k) { return rgba(V('rageui.' + k, [255, 255, 255, 255])); };
    return h('div', { class: 'pv-menu', style: 'background:' + c('background') + ';box-shadow:0 8px 30px ' + c('shadow') + ';color:' + c('text') },
      ban, h('div', { class: 'sub', style: 'color:' + c('subtitle') }, h('span', { text: 'Sous-titre' }), h('span', { text: '2 / 5', style: 'background:' + c('counterBg') + ';color:' + c('counterText') + ';padding:0 6px;border-radius:4px' })),
      h('div', { class: 'sep', style: 'color:' + c('separatorText') + ';border-color:' + c('separator') }, 'Catégorie'),
      h('div', { class: 'it', style: 'background:' + c('button') + ';color:' + c('selectedText') }, h('span', { text: 'Option sélectionnée' }), h('span', { text: '›' })),
      h('div', { class: 'it' }, h('span', { text: 'Option normale' })),
      h('div', { class: 'it', style: 'color:' + c('disabledText') }, h('span', { text: 'Option désactivée' })),
      h('div', { class: 'ds', style: 'background:' + c('descBg') + ';color:' + c('descText') }, 'Description de l\'option sélectionnée.'),
      h('div', { class: 'ds', style: 'background:' + c('infoBg') }, h('b', { style: 'color:' + c('infoTitle'), text: 'Informations' }),
        h('div', { class: 'nfo' }, h('span', { style: 'color:' + c('infoLabel'), text: 'Nom' }), h('span', { style: 'color:' + c('infoValue'), text: 'John Doe' }))));
  },
  hud2: function () {
    var st = 'color:' + V('hud2.text', '#fff') + ';background:' + V('hud2.bg', 'rgba(0,0,0,.6)') + ';border-radius:' + V('hud2.radius', 6) + 'px';
    var mk = function (extra, kids) { return h('div', { class: 'c', style: st + ';' + (extra || '') }, kids); };
    var main = V('hud2.main', '#00a4ff'), muted = V('hud2.muted', '#aaa');
    var box = h('div', { class: 'pv-hud', style: '--pv-main:' + main + ';transform:scale(' + V('hud2.scale', 100) / 100 + ')' });
    if (V('hud2.showServer', true)) box.appendChild(mk('', [h('div', { class: 'lg' }), h('div', { style: 'flex:1' }, h('div', { class: 'nm', style: 'color:' + main + ';text-shadow:0 0 8px ' + main, text: V('hud2.server', '') }), h('div', { class: 'sm', style: 'color:' + muted, text: V('hud2.discord', '') }))]));
    if (V('hud2.showJob', true)) box.appendChild(mk('', [h('div', { class: 'lg', style: 'background:rgba(0,164,255,.14);border:1px solid ' + main }), h('div', { style: 'flex:1' }, h('div', { class: 'nm', text: 'Policier' }), h('div', { class: 'sm', style: 'color:' + muted, text: 'Capitaine' })), h('span', { class: 'sm', style: 'color:' + V('hud2.ok', '#5be39a'), text: 'EN POSTE' })]));
    if (V('hud2.showMoney', true)) box.appendChild(mk('flex-direction:column;align-items:stretch', [
      h('div', { class: 'mr' }, h('em', { style: 'color:' + muted, text: 'Liquide' }), h('span', { style: 'color:' + V('hud2.ok', '#5be39a'), text: '12 500 $' })),
      h('div', { class: 'mr' }, h('em', { style: 'color:' + muted, text: 'Sale' }), h('span', { style: 'color:' + V('hud2.bad', '#ff7373'), text: '840 $' })),
      h('div', { class: 'mr' }, h('em', { style: 'color:' + muted, text: 'Banque' }), h('span', { text: '96 200 $' }))]));
    return box;
  },
  hud1: function () {
    var el = function (off, label) {
      var b = h('div', { class: 'e', style: 'background:' + V('hud1.bg', 'rgba(0,0,0,.6)') });
      b.innerHTML = '<svg viewBox="0 0 40 40"><circle cx="20" cy="20" r="15" fill="none" stroke="rgba(255,255,255,.2)" stroke-width="4"/><circle cx="20" cy="20" r="15" fill="none" stroke="#00a4ff" stroke-width="4" stroke-dasharray="94" stroke-dashoffset="' + off + '"/></svg>';
      b.appendChild(h('b', { text: label })); return b;
    };
    return h('div', { class: 'pv-circ', style: 'gap:' + V('hud1.gap', 8) + 'px' }, el(50, '💧'), el(30, '🍴'));
  },
  notify: function () {
    var g = function (k, d) { return V('notify.' + k, d); };
    var bg = hex2rgb(g('BackgroundColor', '#070707')), op = g('BackgroundTransparency', 0.4);
    var rad = g('BorderRadius', 0), main = g('MainColor', '#00a4ff');
    var w = /^\d+(px)?$/.test(String(g('Width', ''))) ? parseInt(g('Width'), 10) : 290;
    var box = h('div', { class: 'pv-notif', style: 'width:' + Math.min(w, 330) + 'px;min-height:' + g('MinHeight', 65) + 'px;padding:11px 13px 12px 16px;border-radius:' + rad + 'px;background:rgba(' + bg.join(',') + ',' + op + ');color:' + g('TextColor', '#fff') });
    if (g('SideLineEnabled', true)) box.appendChild(h('div', { style: 'position:absolute;left:0;top:0;bottom:0;width:' + g('SideLineWidth', 2) + 'px;background:' + main }));
    var ic = g('IconEnabled', true) ? h('div', { class: 'ic', style: 'width:' + g('IconBoxSize', 22) + 'px;height:' + g('IconBoxSize', 22) + 'px;border-radius:' + g('IconRadius', 0) + 'px;border-color:' + main + ';color:' + main + ';font-size:11px', text: '★' }) : null;
    box.append(
      h('div', { class: 'hd' }, ic, h('b', { style: 'color:' + main + ';font-size:' + g('TitleFontSize', 12.5) + 'px', text: 'Information' }), h('span', { style: 'margin-left:auto;color:' + g('SmallTextColor', '#aaa') + ';font-size:' + g('SmallTextFontSize', 10.5) + 'px', text: 'maintenant' })),
      h('div', { style: 'font-size:' + g('MessageFontSize', 12) + 'px;margin-top:6px' }, 'Vous avez reçu ', h('span', { style: 'color:' + g('SuccessColor', '#5be39a'), text: '+250 $' }), ' · ', h('span', { style: 'color:' + g('ErrorColor', '#f77'), text: 'erreur' }), ' · ', h('span', { style: 'color:' + g('WarningColor', '#fd6'), text: 'attention' }), ' · ', h('span', { style: 'color:' + g('BlueTextColor', '#7bf'), text: 'info' })));
    if (g('ProgressLineEnabled', true)) box.appendChild(h('div', { class: 'pl', style: 'height:2px;background:' + main }));
    if (g('CounterEnabled', true)) box.appendChild(h('div', { class: 'cn', style: 'background:' + main + ';border-radius:' + Math.min(rad, 8) + 'px', text: 'x2' }));
    return box;
  },
  markers: function () {
    var c = V('markers.color', [0, 150, 255, 150]);
    return h('div', { class: 'pv-mk' }, V('markers.enabled', true) ? h('i', { style: 'background:' + rgba(c) + ';box-shadow:0 0 30px ' + rgba(c) }) : h('span', { class: 'sub', text: 'Markers désactivés' }));
  },
  connect: function () {
    return h('div', { class: 'pv-q' }, h('b', { text: V('connect.name', '') }), h('div', { class: 'sub', style: 'margin-top:6px', text: V('connect.none', '') }),
      h('div', {}, h('span', { class: 'b', text: '🎮 Jouer' }), h('span', { class: 'b', text: '💬 Discord' }), h('span', { class: 'b', text: '🛒 Boutique' })));
  }
};
var previewHost;
function drawPreview() {
  if (!previewHost) return;
  var fn = PREVIEW[S.cur]; previewHost.replaceChildren(fn ? fn() : h('span', { class: 'sub', text: 'Pas d\'aperçu' }));
}

// ───────────── Rafraîchissement ciblé ─────────────
var rowEls = {}, dock = null;
function refresh(id) {
  var row = rowEls[id];
  if (row) row.classList.toggle('changed', !same(S.vals[id], S.base[id]));
  drawPreview(); updateBar();
}
function updateBar() {
  var n = dirtyIds().length;
  if (dock) {
    dock.classList.toggle('show', n > 0);
    dock.querySelector('.cnt').textContent = n + ' modification' + (n > 1 ? 's' : '') + ' non enregistrée' + (n > 1 ? 's' : '');
  }
  document.querySelectorAll('.nav[data-g]').forEach(function (b) {
    var d = dirtyIds(b.dataset.g).length, badge = b.querySelector('.dot');
    if (d && !badge) { badge = h('span', { class: 'dot' }); b.appendChild(badge); }
    if (badge) { if (d) badge.textContent = d; else badge.remove(); }
  });
}
function ago(ts) {
  if (!ts) return 'jamais';
  var s = Math.round((Date.now() - ts) / 1000);
  if (s < 10) return 'à l\'instant';
  if (s < 90) return 'il y a ' + s + ' s';
  if (s < 5400) return 'il y a ' + Math.round(s / 60) + ' min';
  if (s < 129600) return 'il y a ' + Math.round(s / 3600) + ' h';
  return 'il y a ' + Math.round(s / 86400) + ' j';
}
function copy(text, btn) {
  function done() { var old = btn.textContent; btn.textContent = 'Copié ✓'; setTimeout(function () { btn.textContent = old; }, 1500); }
  if (navigator.clipboard && window.isSecureContext) navigator.clipboard.writeText(text).then(done, function () {});
  else { var t = h('textarea', { style: 'position:fixed;opacity:0' }); t.value = text; document.body.appendChild(t); t.select(); try { document.execCommand('copy'); done(); } catch (e) {} t.remove(); }
}
function modal(title, kids, onClose) {
  var m = h('div', { class: 'modal', onclick: function (e) { if (e.target === m) { m.remove(); if (onClose) onClose(); } } },
    h('div', { class: 'card box' }, h('div', { class: 'hd' }, title), h('div', { class: 'mbody' }, kids)));
  document.body.appendChild(m); return m;
}
function keyModal(line, title) {
  var btn = h('button', { class: 'btn primary', text: 'Copier la ligne' });
  btn.addEventListener('click', function () { copy(line, btn); });
  var m = modal(title, [
    h('p', { class: 'mp', text: '1. Colle cette ligne dans le server.cfg de ton serveur de jeu (une seule ligne, aucune autre modification).' }),
    h('pre', { class: 'code', text: line }),
    h('p', { class: 'mp', text: '2. Redémarre le serveur (ou  restart pickax_panel). Il apparaît « en ligne » ici en quelques secondes.' }),
    h('p', { class: 'mp warn', text: 'Cette clé ne sera plus affichée : garde-la précieusement. Tu peux en régénérer une à tout moment.' }),
    h('div', { class: 'mact' }, btn, h('button', { class: 'btn', text: 'Fermer', onclick: function () { m.remove(); } }))
  ]);
}

// ───────────── Actions (serveur sélectionné) ─────────────
var base = function () { return 'servers/' + S.sid; };
function doSave(apply) {
  var changes = {}; dirtyIds().forEach(function (id) { changes[id] = S.vals[id]; });
  if (!Object.keys(changes).length) return;
  api(base() + '/save', { changes: changes, apply: apply }).then(function (r) {
    toast(r.saved + ' réglage(s) enregistré(s) — appliqué(s) sur le serveur sous ~15 s' + (apply ? ' (avec redémarrage des ressources)' : ''), 'ok');
    return load().then(renderApp);
  }).catch(function (e) { toast(e.message, 'bad'); });
}
function doCancel() { load().then(renderApp); }
function doReset(f) {
  if (!confirm('Restaurer la valeur d\'origine du script pour « ' + f.label + ' » ?')) return;
  api(base() + '/reset', { ids: [f.id], apply: false }).then(function () { toast('Valeur d\'origine envoyée au serveur', 'ok'); return load().then(renderApp); })
    .catch(function (e) { toast(e.message, 'bad'); });
}
function doRestart(name) {
  api(base() + '/restart', { resource: name }).then(function () { toast(name + ' : redémarrage demandé au serveur', 'ok'); return load().then(renderApp); })
    .catch(function (e) { toast(e.message, 'bad'); });
}
function showLog() {
  var rows = (S.st.log || []).map(function (l) {
    return h('div', { class: 'log-row' }, h('span', { text: new Date(l.at).toLocaleString('fr-FR') }),
      h('span', { text: l.label + ' (' + l.who + ')' }), h('code', { text: JSON.stringify(l.from) + '  →  ' + JSON.stringify(l.to) }));
  });
  modal('Historique des modifications', rows.length ? rows : h('div', { class: 'empty', text: 'Aucune modification pour le moment.' }));
}

// ───────────── Rendu : serveur ─────────────
function fieldRow(f, showGroup) {
  var broken = f.error || S.vals[f.id] === undefined;
  var tags = [];
  if (showGroup) tags.push(h('span', { class: 'tag', text: groupOf(f.group).label }));
  if (f.modified && f.status === 'pending') tags.push(h('span', { class: 'tag warn', text: 'en attente du serveur' }));
  else if (f.modified && f.status === 'error') tags.push(h('span', { class: 'tag bad', text: 'refusé : ' + (f.statusError || 'erreur') }));
  else if (f.modified) tags.push(h('span', { class: 'tag ok', text: 'appliqué' }));
  if (broken) tags.push(h('span', { class: 'tag bad', text: f.error || 'introuvable dans le fichier' }));
  var lb = h('div', { class: 'lb' }, h('b', { text: f.label }), f.hint ? h('small', { text: f.hint }) : null, h('div', { class: 'tags' }, tags));
  var ctl = h('div', { class: 'ctl' });
  if (!broken) {
    ctl = control(f);
    if (f.modified) ctl.appendChild(h('button', { class: 'icon-btn', title: 'Restaurer la valeur d\'origine du script', onclick: function () { doReset(f); } }, icon('undo')));
  }
  var row = h('div', { class: 'field' + (broken ? ' broken' : '') + (!broken && !same(S.vals[f.id], S.base[f.id]) ? ' changed' : '') }, lb, ctl);
  rowEls[f.id] = row; return row;
}
function groupOf(id) { return S.groups.filter(function (g) { return g.id === id; })[0]; }

function renderHome() {
  var st = S.st;
  var link = h('div', { class: 'card linkcard' },
    h('div', { class: 'lh' }, h('span', { class: 'chip ' + (st.online ? 'ok' : 'bad') }, h('i'), st.online ? 'Serveur en ligne' : 'Serveur hors ligne'),
      h('span', { class: 'sub', text: 'Dernière connexion : ' + ago(st.lastSeen) })),
    h('div', { class: 'lstats' },
      h('div', {}, h('b', { text: st.linked ? String(st.players == null ? '—' : st.players) + (st.maxPlayers ? ' / ' + st.maxPlayers : '') : '—' }), h('small', { text: 'joueurs connectés' })),
      h('div', {}, h('b', { text: String(st.changes) }), h('small', { text: 'réglages modifiés via le panel' })),
      h('div', {}, h('b', { text: String(st.pending) }), h('small', { text: 'en attente du serveur' }))),
    h('div', { class: 'lact' },
      h('button', { class: 'btn sm', text: 'Renommer', onclick: function () {
        var n = prompt('Nom du serveur :', st.name); if (!n) return;
        api(base() + '/rename', { name: n }).then(function () { return load(); }).then(renderApp).catch(function (e) { toast(e.message, 'bad'); }); } }),
      h('button', { class: 'btn sm', text: 'Régénérer la clé de liaison', onclick: function () {
        if (!confirm('Régénérer la clé ? L\'ancienne cessera de fonctionner : il faudra remplacer la ligne dans le server.cfg.')) return;
        api(base() + '/regenerate', {}).then(function (r) { keyModal(r.line, 'Nouvelle clé de liaison'); return load().then(renderApp); }).catch(function (e) { toast(e.message, 'bad'); }); } }),
      h('button', { class: 'btn sm danger', text: 'Supprimer ce serveur', onclick: function () {
        if (!confirm('Supprimer « ' + st.name + ' » du panel ? (les fichiers du serveur ne sont pas modifiés)')) return;
        api(base(), null, 'DELETE').then(function () { S.view = 'servers'; return loadServers(); }).then(renderServers).catch(function (e) { toast(e.message, 'bad'); }); } })));
  if (!st.linked) {
    return h('div', { class: 'home' }, link, h('div', { class: 'hero' }, h('h2', { text: 'En attente de la première connexion' }),
      h('p', { text: 'Colle la ligne  set pickax_panel_key "…"  dans le server.cfg de ton serveur, puis démarre-le (ressource pickax_panel). Les sections de configuration apparaîtront ici dès qu\'il se sera connecté. Clé perdue ? « Régénérer la clé de liaison ».' })));
  }
  var cards = S.groups.map(function (g) {
    var mod = g.fields.filter(function (f) { return f.modified; }).length;
    var ok = g.resource ? g.state === 'started' : true;
    return h('button', { class: 'tile', onclick: function () { S.cur = g.id; S.q = ''; renderApp(); } },
      h('div', { class: 'ti' }, icon(g.icon)),
      h('b', { text: g.label }),
      h('p', { text: g.desc.split('. ')[0] + '.' }),
      h('div', { class: 'ft' }, g.resource ? h('span', { class: 'chip ' + (ok ? 'ok' : 'bad') }, h('i'), ok ? 'démarrée' : g.state) : h('span', { class: 'chip ok' }, h('i'), 'en direct'),
        h('span', { class: 'sub', text: g.fields.length + ' réglages' + (mod ? ' · ' + mod + ' modifié' + (mod > 1 ? 's' : '') : '') })));
  });
  return h('div', { class: 'home' }, link,
    h('div', { class: 'hero' }, h('h2', { text: 'Configuration' }),
      h('p', { text: 'Choisis une section. « Enregistrer » envoie les réglages à ton serveur, qui les applique tout seul dans les fichiers de tes scripts (et les réapplique à chaque démarrage).' })),
    h('div', { class: 'tiles' }, cards));
}

function renderApp() {
  S.view = 'server';
  rowEls = {};
  var st = S.st, q = (S.q || '').trim().toLowerCase();
  var home = S.cur === 'home' && !q;
  var g = home ? null : (groupOf(S.cur) || S.groups[0]);

  var navItems = [h('button', { class: 'nav' + (home ? ' on' : ''), onclick: function () { S.cur = 'home'; S.q = ''; renderApp(); } }, icon('home'), 'Accueil')];
  if (S.groups.length) navItems.push(h('div', { class: 'navlbl', text: 'Configuration' }));
  S.groups.forEach(function (x) {
    navItems.push(h('button', { class: 'nav' + (!home && !q && x.id === S.cur ? ' on' : ''), 'data-g': x.id, onclick: function () { S.cur = x.id; S.q = ''; renderApp(); } }, icon(x.icon), x.label));
  });

  var main, title, sub, state = null;
  previewHost = null;
  if (home) {
    title = st.name; sub = S.groups.length ? S.groups.length + ' sections · ' + S.groups.reduce(function (n, x) { return n + x.fields.length; }, 0) + ' réglages' : 'Pas encore relié';
    main = renderHome();
  } else if (q) {
    var hits = [];
    S.groups.forEach(function (x) { x.fields.forEach(function (f) { if ((f.label + ' ' + (f.hint || '') + ' ' + x.label).toLowerCase().indexOf(q) >= 0) hits.push(f); }); });
    title = 'Recherche'; sub = hits.length + ' résultat' + (hits.length > 1 ? 's' : '') + ' pour « ' + S.q + ' »';
    main = h('div', { class: 'content one' }, h('div', { class: 'card' }, hits.length ? hits.map(function (f) { return fieldRow(f, true); }) : h('div', { class: 'empty', text: 'Aucun réglage ne correspond.' })));
  } else {
    title = g.label; sub = g.resource || 'Variables du serveur';
    if (g.resource) { var ok = g.state === 'started'; state = h('span', { class: 'chip ' + (ok ? 'ok' : 'bad') }, h('i'), ok ? g.resource + ' démarrée' : g.resource + ' : ' + g.state); }
    var cards = [], cur = null;
    g.fields.forEach(function (f) {
      if (!cur || f.section) { cur = h('div', { class: 'card sect' }, f.section ? h('div', { class: 'sh', text: f.section }) : null); cards.push(cur); }
      cur.appendChild(fieldRow(f));
    });
    previewHost = h('div', { class: 'stage' });
    main = h('div', { class: 'content' },
      h('div', { class: 'col' }, h('p', { class: 'desc', text: g.desc }), cards),
      h('div', { class: 'preview' }, h('div', { class: 'card' }, h('div', { class: 'hd' }, 'Aperçu', h('small', { text: 'approximatif' })), previewHost)));
  }

  var search = h('input', { type: 'search', class: 'search', placeholder: 'Rechercher un réglage…', value: S.q || '' });
  search.addEventListener('input', function () {
    S.q = search.value; var pos = search.selectionStart; renderApp();
    var again = document.querySelector('.search'); if (again) { again.focus(); again.setSelectionRange(pos, pos); }
  });

  var banners = [];
  if (st.linked && !st.online) banners.push(h('div', { class: 'banner off' }, h('span', { text: 'Le serveur est hors ligne (dernière connexion : ' + ago(st.lastSeen) + '). Tes modifications sont gardées et seront appliquées dès sa reconnexion.' })));
  if (S.pending.length) banners.push(h('div', { class: 'banner' }, h('span', { text: 'À redémarrer pour appliquer : ' + S.pending.join(', ') }),
    S.pending.map(function (r) { return h('button', { class: 'btn sm', onclick: function () { doRestart(r); }, text: 'Redémarrer ' + r }); })));

  dock = h('div', { class: 'dock' }, h('span', { class: 'cnt' }),
    h('button', { class: 'btn ghost', onclick: doCancel, text: 'Annuler' }),
    h('button', { class: 'btn', onclick: function () { doSave(false); }, text: 'Enregistrer' }),
    h('button', { class: 'btn primary', onclick: function () { doSave(true); }, text: 'Enregistrer et appliquer' }));

  var scrollTop = (document.querySelector('.scroll') || {}).scrollTop || 0;
  app.replaceChildren(h('div', { class: 'shell' },
    h('aside', { class: 'side' }, h('div', { class: 'logo' }, h('i', {}, icon('logo')), h('span', {}, 'Pickax', h('small', { text: 'Panel de configuration' }))),
      h('button', { class: 'nav back', onclick: function () { S.view = 'servers'; loadServers().then(renderServers); } }, icon('back'), 'Mes serveurs'),
      h('div', { class: 'srv' }, h('i', { class: st.online ? 'on' : 'off' }), h('div', {}, h('b', { text: st.name }), st.online ? (st.players == null ? 'en ligne' : st.players + ' joueur(s) connecté(s)') : 'hors ligne')),
      navItems, h('div', { class: 'grow' }),
      h('button', { class: 'nav', onclick: logout }, icon('out'), 'Se déconnecter (' + S.user + ')')),
    h('main', { class: 'main' },
      h('div', { class: 'top' }, h('div', { class: 'tt' }, h('h1', { text: title }), h('div', { class: 'sub', text: sub })), state,
        h('div', { class: 'sp' }), search, h('button', { class: 'btn', onclick: showLog }, icon('clock'), 'Historique')),
      banners, h('div', { class: 'scroll' }, main), dock)));
  var sc = document.querySelector('.scroll'); if (sc) sc.scrollTop = scrollTop;
  drawPreview(); updateBar();
}

// ───────────── Rendu : liste des serveurs ─────────────
function loadServers() { return api('servers').then(function (r) { S.servers = r.servers; }); }
function renderServers() {
  S.view = 'servers'; dock = null;
  var cards = S.servers.map(function (s) {
    return h('button', { class: 'tile srvcard', onclick: function () { openServer(s.id); } },
      h('div', { class: 'ti' }, icon('server')),
      h('b', { text: s.name }),
      h('p', { text: s.linked ? (s.hostname ? s.hostname.replace(/\^\d/g, '') : 'Relié') : 'En attente de la première connexion' }),
      h('div', { class: 'ft' }, h('span', { class: 'chip ' + (s.online ? 'ok' : 'bad') }, h('i'), s.online ? 'en ligne' : 'hors ligne'),
        h('span', { class: 'sub', text: s.online && s.players != null ? s.players + ' joueur(s)' : ago(s.lastSeen) + (s.pending ? ' · ' + s.pending + ' en attente' : '') })));
  });
  cards.push(h('button', { class: 'tile add', onclick: addServer }, h('div', { class: 'ti' }, icon('plus')), h('b', { text: 'Ajouter un serveur' }), h('p', { text: 'Génère une clé de liaison à coller dans le server.cfg.' })));
  app.replaceChildren(h('div', { class: 'shell' },
    h('aside', { class: 'side' }, h('div', { class: 'logo' }, h('i', {}, icon('logo')), h('span', {}, 'Pickax', h('small', { text: 'Panel de configuration' }))),
      h('button', { class: 'nav on' }, icon('server'), 'Mes serveurs'), h('div', { class: 'grow' }),
      h('button', { class: 'nav', onclick: logout }, icon('out'), 'Se déconnecter (' + S.user + ')')),
    h('main', { class: 'main' },
      h('div', { class: 'top' }, h('div', { class: 'tt' }, h('h1', { text: 'Mes serveurs' }), h('div', { class: 'sub', text: S.servers.length + ' licence' + (S.servers.length > 1 ? 's' : '') })), h('div', { class: 'sp' }),
        h('button', { class: 'btn primary', onclick: addServer }, icon('plus'), 'Ajouter un serveur')),
      h('div', { class: 'scroll' }, h('div', { class: 'home' },
        S.servers.length ? null : h('div', { class: 'hero' }, h('h2', { text: 'Bienvenue sur le panel' }), h('p', { text: 'Ajoute ton premier serveur : le panel te donne une ligne à coller dans le server.cfg, et c\'est tout.' })),
        h('div', { class: 'tiles' }, cards))))));
}
function addServer() {
  var input = h('input', { type: 'text', placeholder: 'Nom du serveur (ex : BlueBay RP)', maxlength: 60 });
  var go = h('button', { class: 'btn primary', text: 'Créer la licence' });
  var m = modal('Ajouter un serveur', [h('p', { class: 'mp', text: 'Donne un nom à ce serveur : une clé de liaison unique est générée.' }), h('div', { class: 'mfield' }, input), h('div', { class: 'mact' }, go)]);
  function create() {
    if (!input.value.trim()) return;
    api('servers', { name: input.value.trim() }).then(function (r) { m.remove(); keyModal(r.line, 'Clé de liaison — ' + input.value.trim()); return loadServers(); }).then(renderServers).catch(function (e) { toast(e.message, 'bad'); });
  }
  go.addEventListener('click', create); input.addEventListener('keydown', function (e) { if (e.key === 'Enter') create(); });
  setTimeout(function () { input.focus(); }, 30);
}
function openServer(id) { S.sid = id; S.cur = 'home'; S.q = ''; load().then(renderApp).catch(function (e) { toast(e.message, 'bad'); }); }

// ───────────── Connexion ─────────────
function authScreen(setup, msg) {
  var user = h('input', { type: 'text', placeholder: 'Identifiant', autocomplete: 'username', autofocus: true });
  var pass = h('input', { type: 'password', placeholder: setup ? 'Mot de passe (8 caractères minimum)' : 'Mot de passe', autocomplete: setup ? 'new-password' : 'current-password' });
  var err = h('div', { class: 'err', text: msg || '' });
  function go() {
    api(setup ? 'setup' : 'login', { user: user.value.trim(), pass: pass.value }).then(function (r) { S.user = r.user; return start(); }).catch(function (e) { err.textContent = e.message; });
  }
  [user, pass].forEach(function (i) { i.addEventListener('keydown', function (e) { if (e.key === 'Enter') go(); }); });
  app.replaceChildren(h('div', { class: 'login' }, h('div', { class: 'login-card' },
    h('div', { class: 'logo' }, h('i', {}, icon('logo')), 'Pickax Panel'),
    h('p', { text: setup ? 'Premier lancement : crée ton compte administrateur.' : 'Connecte-toi pour gérer tes serveurs.' }),
    h('div', { class: 'stack' }, user, pass), h('button', { class: 'btn primary', onclick: go, text: setup ? 'Créer le compte' : 'Se connecter' }), err)));
}
function renderLogin(msg) { authScreen(false, msg); }
function logout() { api('logout', {}).then(function () { S.user = null; renderLogin(); }); }

// ───────────── Rafraîchissement automatique (statut du serveur, accusés d'application) ─────────────
function signature(st) { return JSON.stringify([st.online, st.pendingRestart, st.players, st.groups.map(function (g) { return [g.state, g.fields.map(function (f) { return [f.value, f.status, f.statusError, f.modified]; })]; })]); }
setInterval(function () {
  if (!S.user) return;
  if (S.view === 'servers') {
    if (document.querySelector('.modal')) return;
    api('servers').then(function (r) { if (JSON.stringify(r.servers) !== JSON.stringify(S.servers) && S.view === 'servers') { S.servers = r.servers; renderServers(); } }).catch(function () {});
  } else if (S.view === 'server' && S.sid) {
    if (dirtyIds().length || document.querySelector('.modal') || (document.activeElement && /^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement.tagName))) return;
    api(base()).then(function (st) {
      if (S.view === 'server' && signature(st) !== signature(S.st)) { return load().then(renderApp); }
    }).catch(function () {});
  }
}, 6000);

// ───────────── Démarrage ─────────────
function start() { return loadServers().then(renderServers); }
api('me').then(function (r) {
  if (r.setup) return authScreen(true);
  if (!r.user) return renderLogin();
  S.user = r.user; return start();
}).catch(function (e) { app.replaceChildren(h('div', { class: 'login' }, h('div', { class: 'login-card' }, h('p', { text: 'Panel injoignable : ' + e.message })))); });
})();
