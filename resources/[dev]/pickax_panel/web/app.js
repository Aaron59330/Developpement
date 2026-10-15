(function () {
'use strict';

// ───────────── Utilitaires ─────────────
var app = document.getElementById('app');
var KEY = '', SERVER = '';
var meta = document.querySelector('meta[name=panel-remote]');
var REMOTE = !!meta && meta.content === 'yes';   // panel lancé en local (serve.py) : il parle à un serveur distant
try { KEY = sessionStorage.getItem('pxkey') || ''; SERVER = REMOTE ? (localStorage.getItem('pxserver') || '') : ''; } catch (e) {}

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
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>'
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
var S = { groups: [], pending: [], vals: {}, base: {}, fields: {}, cur: null, server: '', players: 0 };

function load() {
  return api('state').then(function (st) {
    S.groups = st.groups; S.pending = st.pending; S.server = st.server; S.players = st.players;
    S.vals = {}; S.base = {}; S.fields = {};
    st.groups.forEach(function (g) { g.fields.forEach(function (f) {
      S.fields[f.id] = f; f.group = g.id;
      if (f.value !== undefined && f.value !== null) { S.vals[f.id] = clone(f.value); S.base[f.id] = clone(f.value); }
    }); });
    if (!S.cur || !S.groups.some(function (g) { return g.id === S.cur; })) S.cur = S.groups[0].id;
  });
}
function dirtyIds(groupId) {
  return Object.keys(S.vals).filter(function (id) {
    return (!groupId || S.fields[id].group === groupId) && !same(S.vals[id], S.base[id]);
  });
}

// ───────────── Connexion ─────────────
function renderLogin(msg) {
  var input = h('input', { type: 'password', placeholder: 'Clé du panel', autocomplete: 'off', autofocus: true });
  var err = h('div', { class: 'err', text: msg || '' });
  var srv = REMOTE ? h('input', { type: 'text', placeholder: 'Adresse du serveur  ex : http://123.45.67.89:30120', value: SERVER, style: 'margin-bottom:10px' }) : null;
  function go() {
    KEY = input.value.trim();
    if (REMOTE) {
      SERVER = srv.value.trim().replace(/\/+$/, '').replace(/\/pickax_panel$/, '');
      if (!/^https?:\/\/[^\s]+$/.test(SERVER)) { err.textContent = 'Adresse du serveur invalide (http://IP:30120).'; return; }
    }
    load().then(function () { try { sessionStorage.setItem('pxkey', KEY); if (REMOTE) localStorage.setItem('pxserver', SERVER); } catch (e) {} renderApp(); })
      .catch(function (e) { err.textContent = e.message === 'Failed to fetch' ? 'Serveur injoignable (adresse, port 30120 ouvert, ressource pickax_panel démarrée ?)' : e.message; });
  }
  input.addEventListener('keydown', function (e) { if (e.key === 'Enter') go(); });
  app.replaceChildren(h('div', { class: 'login' }, h('div', { class: 'login-card' },
    h('div', { class: 'logo' }, h('i', {}, icon('logo')), 'Pickax Panel'),
    h('p', { text: REMOTE ? 'Saisis l\'adresse de ton serveur et la clé définie dans son server.cfg (pickax_panel_key).' : 'Saisis la clé définie dans le server.cfg (pickax_panel_key).' }), srv, input,
    h('button', { class: 'btn primary', onclick: go, text: 'Se connecter' }), err)));
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
var rowEls = {}, saveBtns = [];
function refresh(id) {
  var f = S.fields[id], row = rowEls[id];
  if (row) row.classList.toggle('changed', !same(S.vals[id], S.base[id]));
  drawPreview(); updateBar();
}
function updateBar() {
  var n = dirtyIds().length;
  saveBtns.forEach(function (b) { b.disabled = n === 0; });
  var c = document.getElementById('dirtyCount'); if (c) c.textContent = n ? n + ' modification' + (n > 1 ? 's' : '') + ' non enregistrée' + (n > 1 ? 's' : '') : 'Tout est enregistré';
  document.querySelectorAll('.nav').forEach(function (b) {
    var d = b.querySelector('.dot'); var has = dirtyIds(b.dataset.g).length > 0;
    if (has && !d) b.appendChild(h('span', { class: 'dot' })); if (!has && d) d.remove();
  });
}

// ───────────── Actions ─────────────
function doSave(apply) {
  var changes = {}; dirtyIds().forEach(function (id) { changes[id] = S.vals[id]; });
  if (!Object.keys(changes).length) return;
  api('save', { changes: changes, apply: apply }).then(function (r) {
    toast(r.saved + ' réglage(s) enregistré(s)' + (r.restarted && r.restarted.length ? ' · redémarrage : ' + r.restarted.join(', ') : ''), 'ok');
    return load().then(renderApp);
  }).catch(function (e) { toast(e.message, 'bad'); });
}
function doReset(f) {
  if (!confirm('Restaurer la valeur d\'origine du script pour « ' + f.label + ' » ?')) return;
  api('reset', { ids: [f.id], apply: false }).then(function () { toast('Valeur d\'origine restaurée', 'ok'); return load().then(renderApp); })
    .catch(function (e) { toast(e.message, 'bad'); });
}
function doRestart(name) {
  api('restart', { resource: name }).then(function () { toast(name + ' redémarré', 'ok'); return load().then(renderApp); })
    .catch(function (e) { toast(e.message, 'bad'); });
}
function showLog() {
  api('log').then(function (r) {
    var rows = r.log.map(function (l) {
      return h('div', { class: 'log-row' }, h('span', { text: new Date(l.at * 1000).toLocaleString('fr-FR') }),
        h('span', { text: (S.fields[l.field] ? S.fields[l.field].label : l.field) + ' (' + l.source + ')' }), h('code', { text: (l.old_value || '') + '  →  ' + (l.new_value || '') }));
    });
    var m = h('div', { class: 'modal', onclick: function (e) { if (e.target === m) m.remove(); } },
      h('div', { class: 'card box' }, h('div', { class: 'hd' }, 'Historique des modifications', h('small', { text: '60 dernières' })), rows.length ? rows : h('div', { class: 'field', text: 'Aucune modification pour le moment.' })));
    document.body.appendChild(m);
  }).catch(function (e) { toast(e.message, 'bad'); });
}

// ───────────── Rendu principal ─────────────
function renderApp() {
  rowEls = {}; saveBtns = [];
  var g = S.groups.filter(function (x) { return x.id === S.cur; })[0];
  var nav = S.groups.map(function (x) {
    return h('button', { class: 'nav' + (x.id === S.cur ? ' on' : ''), 'data-g': x.id, onclick: function () { S.cur = x.id; renderApp(); } }, icon(x.icon), x.label);
  });
  var rows = g.fields.map(function (f) {
    var broken = f.error || S.vals[f.id] === undefined;
    var lb = h('div', { class: 'lb' }, h('b', { text: f.label }), f.hint ? h('small', { text: f.hint }) : null,
      h('div', { class: 'tags' }, f.modified ? h('span', { class: 'tag', text: 'modifié via le panel' }) : null,
        broken ? h('span', { class: 'tag bad', text: f.error || 'introuvable dans le fichier' }) : null));
    var ctl = h('div', { class: 'ctl' });
    if (!broken) {
      ctl = control(f);
      if (f.modified) ctl.appendChild(h('button', { class: 'icon-btn', title: 'Restaurer la valeur d\'origine du script', onclick: function () { doReset(f); } }, icon('undo')));
    }
    var row = h('div', { class: 'field' + (broken ? ' broken' : '') + (!broken && !same(S.vals[f.id], S.base[f.id]) ? ' changed' : '') }, lb, ctl);
    rowEls[f.id] = row; return row;
  });
  var save = h('button', { class: 'btn', onclick: function () { doSave(false); }, text: 'Enregistrer' });
  var apply = h('button', { class: 'btn primary', onclick: function () { doSave(true); }, text: 'Enregistrer et appliquer' });
  saveBtns.push(save, apply);
  var state = g.state === 'started' ? ['ok', g.resource + ' démarrée'] : ['bad', g.resource + ' : ' + g.state];
  previewHost = h('div', { class: 'stage' });
  var pend = S.pending.length ? h('div', { class: 'banner' }, h('span', { text: 'À redémarrer pour appliquer : ' + S.pending.join(', ') }),
    S.pending.map(function (r) { return h('button', { class: 'btn sm', onclick: function () { doRestart(r); }, text: 'Redémarrer ' + r }); })) : null;

  app.replaceChildren(h('div', { class: 'shell' },
    h('aside', { class: 'side' }, h('div', { class: 'logo' }, h('i', {}, icon('logo')), 'Pickax Panel'), nav, h('div', { class: 'grow' }),
      h('div', { class: 'srv' }, h('b', { text: S.server.replace(/\^\d/g, '') || 'Serveur' }), S.players + ' joueur(s) connecté(s)'),
      h('button', { class: 'nav', onclick: function () { try { sessionStorage.removeItem('pxkey'); } catch (e) {} KEY = ''; renderLogin(); } }, 'Se déconnecter')),
    h('main', { class: 'main' },
      h('div', { class: 'top' }, h('div', {}, h('h1', { text: g.label }), h('div', { class: 'sub', id: 'dirtyCount' })), h('span', { class: 'chip ' + state[0] }, h('i'), state[1]),
        h('div', { class: 'sp' }), h('button', { class: 'btn', onclick: showLog }, icon('clock'), 'Historique'), save, apply),
      pend,
      h('div', { class: 'content' },
        h('div', {}, h('p', { class: 'desc', text: g.desc }), h('div', { class: 'card' }, rows)),
        h('div', { class: 'preview' }, h('div', { class: 'card' }, h('div', { class: 'hd' }, 'Aperçu', h('small', { text: 'approximatif' })), previewHost))))));
  drawPreview(); updateBar();
}

// ───────────── Démarrage ─────────────
if (KEY && (!REMOTE || SERVER)) load().then(renderApp).catch(function (e) { renderLogin(e.message); });
else renderLogin();
})();
