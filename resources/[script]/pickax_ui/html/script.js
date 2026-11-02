'use strict';
var $ = function (id) { return document.getElementById(id); };
var COLORS = { r: '#f87171', g: '#4ade80', b: (window.PICKAX_ACCENT || '#fdc27d'), y: '#fbbf24', o: '#fb923c', p: '#c084fc', c: '#9ca3af', m: '#6b7280', u: '#000', w: '#fff', q: '#f472b6' };

function esc(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }

// Codes couleur GTA (~r~, ~s~, ~h~ ...) -> HTML
function gta(text) {
  if (text === null || text === undefined) return '';
  var s = esc(text).replace(/&lt;\/?C&gt;/g, '');
  var out = '', open = false, bold = false;
  var parts = s.split(/~([A-Za-z_0-9]+)~/);
  for (var i = 0; i < parts.length; i++) {
    if (i % 2 === 0) { out += parts[i]; continue; }
    var k = parts[i];
    if (COLORS[k]) { if (open) out += '</span>'; out += '<span style="color:' + COLORS[k] + '">'; open = true; }
    else if (k === 's') { if (open) { out += '</span>'; open = false; } }
    else if (k === 'h') { bold = !bold; out += bold ? '<b>' : '</b>'; }
    else if (k === 'n') { out += ' '; }
  }
  if (open) out += '</span>';
  if (bold) out += '</b>';
  return out;
}

var ICONS = {
  lock: '<svg class="badge" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>',
  tick: '<svg class="badge" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>',
  star: '<svg class="badge star" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z"/></svg>',
  dot: '<svg class="badge" viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="12" r="4"/></svg>'
};
var CHEV = '<svg class="chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l6 6-6 6"/></svg>';

// Flèches « → / →→ / →→→ / ↗ » des boutons : remplacées par une icône (chevron dans un rond, ou lien externe)
var ARROW_RE = /\s*(→+|⇒|▶|►|>>)\s*$/;
var ICON_ARROW = '<span class="arr"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l6 6-6 6"/></svg></span>';
var ICON_EXT = '<span class="arr"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 17L17 7M9 7h8v8"/></svg></span>';
function rightLabel(r) {
  var plain = String(r).replace(/~[a-zA-Z]~/g, '').trim();
  if (plain === '↗') return ICON_EXT;
  if (/^(→+|⇒|▶|►|>>)$/.test(plain)) return ICON_ARROW;
  if (ARROW_RE.test(plain)) {
    var text = String(r).replace(/\s*(→+|⇒|▶|►|>>)\s*$/, '');
    return '<span class="rt">' + gta(text) + '</span>' + ICON_ARROW;
  }
  return '<span class="rt">' + gta(r) + '</span>';
}

function badge(name) { return name ? (ICONS[name] || ICONS.dot) : ''; }

function item(it) {
  if (it.k === 'ln') return '<div class="ln"></div>';
  if (it.k === 's') return '<div class="sep">' + gta(it.l) + '</div>';
  var cls = 'it' + (it.act ? ' act' : '') + (it.en === false ? ' off' : '');
  var style = '';
  var col = it.act ? it.hl : it.bg;
  if (col) style = ' style="background:rgba(' + col[0] + ',' + col[1] + ',' + col[2] + ',.28);border-color:rgba(' + col[0] + ',' + col[1] + ',' + col[2] + ',.7)"';
  var h = '<div class="' + cls + '"' + style + '>';
  h += badge(it.lb);
  h += '<span class="lb">' + gta(it.l) + '</span>';
  if (it.k === 'l') h += '<span class="lst"><i>‹</i>' + gta(it.v) + '<i>›</i></span>';
  if (it.r) h += rightLabel(it.r);
  if (it.k === 'c') h += '<span class="box' + (it.ck ? ' on' : '') + (it.cs === 'cross' ? ' x' : '') + '"></span>';
  if (it.rb) h += badge(it.rb);
  if (it.en === false && !it.rb) h += ICONS.lock;
  if (it.sub && !it.r && !it.rb && it.en !== false) h += CHEV;
  return h + '</div>';
}

function hexRgb(h) {
  var m = /^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i.exec(h || '');
  return m ? parseInt(m[1], 16) + ',' + parseInt(m[2], 16) + ',' + parseInt(m[3], 16) : (window.PICKAX_ACCENT_RGB || '253,194,125');
}

var STYLE_ALPHA = { dore: .86 };
var OVERRIDES = ['--card-bg', '--text', '--text-2', '--muted', '--act-bg', '--act-border', '--act-text', '--r-btn', '--r-card'];

function applyCfg(c) {
  if (!c) return;
  [$('wrap'), $('dlgwrap'), $('chwrap')].forEach(function (w) { applyCfgTo(w, c); });
  $('banner').classList.toggle('hidden', c.banner === false);
}

// Un seul style de menus : « Doré » (bandeau, lignes sombres arrondies, ligne active à la couleur du serveur)
function effStyle() { return 'dore'; }

function applyCfgTo(w, c) {
  var st = w.style;
  var es = effStyle();
  w.setAttribute('data-style', es);
  w.setAttribute('data-size', c.size || 'md');
  st.setProperty('--accent', c.accent || (window.PICKAX_ACCENT || '#fdc27d'));
  st.setProperty('--accent-rgb', hexRgb(c.accent));
  OVERRIDES.forEach(function (k) { st.removeProperty(k); });
  if (c.bg) st.setProperty('--card-bg', 'rgba(' + hexRgb(c.bg) + ',' + (STYLE_ALPHA[es] || .94) + ')');
  if (c.text) {
    var t = hexRgb(c.text);
    st.setProperty('--text', 'rgb(' + t + ')');
    st.setProperty('--text-2', 'rgba(' + t + ',.82)');
    st.setProperty('--muted', 'rgba(' + t + ',.5)');
    st.setProperty('--act-text', 'rgb(' + t + ')');
  }
  if (c.selbg) st.setProperty('--act-bg', 'rgba(' + hexRgb(c.selbg) + ',.3)');
  if (c.selborder) st.setProperty('--act-border', c.selborder);
  if (c.btnRadius !== undefined) st.setProperty('--r-btn', c.btnRadius + 'px');
  if (c.cardRadius !== undefined) st.setProperty('--r-card', c.cardRadius + 'px');
}

function render(d) {
  applyCfg(d.cfg);
  $('title').innerHTML = gta(d.t);
  $('sub').innerHTML = gta(d.s);
  $('count').textContent = d.c || '';
  $('count').classList.toggle('hidden', !d.c);
  $('items').innerHTML = (d.i || []).map(item).join('');
  var ds = $('desc');
  if (d.ds) { ds.innerHTML = '<span class="dt">' + gta(d.ds) + '</span>'; ds.classList.remove('hidden'); } else { ds.classList.add('hidden'); }
  var inf = $('info');
  if (d.inf) { inf.innerHTML = infoHtml(d.inf); inf.classList.remove('hidden'); } else { inf.classList.add('hidden'); }
}

// Panneau d'infos : "Libellé : valeur" -> ligne libellé / valeur ; "Titre :" -> intitulé ; reste -> paragraphe
function infoHtml(inf) {
  var out = inf.t ? '<h2>' + gta(inf.t) + '</h2>' : '';
  var body = '', gap = false;
  (inf.r || []).forEach(function (r) {
    var raw = String(r[0] == null ? '' : r[0]).replace(/~n~/g, '\n');
    var val = String(r[1] == null ? '' : r[1]).trim();
    var lines = raw.split(/\r?\n/);
    var filled = lines.filter(function (l) { return l.trim() !== ''; });
    if (val && filled.length <= 1) {
      body += '<div class="irow"><span class="k">' + gta(filled[0] || '') + '</span><span class="v">' + gta(val) + '</span></div>';
      gap = false;
      return;
    }
    lines.forEach(function (ln) {
      ln = ln.trim();
      if (!ln) { gap = true; return; }
      var cls = gap ? ' gap' : '';
      gap = false;
      var m = /^(.*?)\s*:\s*(.+)$/.exec(ln);
      if (m && m[1].replace(/~[A-Za-z_0-9]+~/g, '').trim() !== '') {
        body += '<div class="irow' + cls + '"><span class="k">' + gta(m[1]) + '</span><span class="v">' + gta(m[2].replace(/\.\s*$/, '')) + '</span></div>';
      } else if (/:\s*$/.test(ln)) {
        body += '<div class="ih' + cls + '">' + gta(ln.replace(/\s*:\s*$/, '')) + '</div>';
      } else {
        body += '<p class="ip' + cls + '">' + gta(ln) + '</p>';
      }
    });
  });
  return out + body;
}

window.addEventListener('message', function (e) {
  var m = e.data || {};
  if (m.a === 'menu') {
    var w = $('wrap');
    if (w.classList.contains('hidden')) w.classList.remove('hidden');
    render(m.d || {});
  } else if (m.a === 'url') {
    if (window.invokeNative) window.invokeNative('openUrl', m.u);
  } else if (m.a === 'hide') {
    $('wrap').classList.add('hidden');
  }
});


/* ===== Fenêtre de saisie ===== */
var dlgOpen = false;
function nuiPost(name, body) {
  try { fetch('https://' + (window.GetParentResourceName ? GetParentResourceName() : 'pickax_ui') + '/' + name, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) }); } catch (e) {}
}
function dlgSound(n) { window.postMessage({ a: 'snd', n: n, v: window.__vol || 60 }, '*'); }
function dlgClose(value) {
  if (!dlgOpen) return;
  dlgOpen = false;
  $('dlgwrap').classList.add('hidden');
  nuiPost('inputDone', { value: value });
}
function dlgOpenWith(m) {
  var d = m.d || {};
  window.__vol = m.v;
  applyCfg(m.cfg || {});
  $('dl-title').textContent = d.title || 'Saisie';
  $('dl-hint').textContent = d.hint || '';
  var inp = $('dl-input');
  inp.value = d.default || '';
  // placeholder identique au titre = redondant : on propose une invite plus utile
  inp.placeholder = (d.placeholder && d.placeholder !== d.title) ? d.placeholder : 'Saisis ici puis valide…';
  inp.maxLength = d.max || 60;
  inp.setAttribute('inputmode', d.numeric ? 'numeric' : 'text');
  dlgOpen = true;
  $('dl-err').classList.add('hidden');
  dlgCount();
  $('dlgwrap').classList.remove('hidden');
  dlgSound('open');
  setTimeout(function () { inp.focus(); inp.select(); }, 30);
}
function dlgCount() {
  var inp = $('dl-input');
  $('dl-count').textContent = inp.value.length + '/' + inp.maxLength;
}
function dlgSubmit() {
  var inp = $('dl-input'), v = inp.value;
  if (inp.getAttribute('inputmode') === 'numeric' && v !== '' && !/^-?\d+$/.test(v)) {
    var e = $('dl-err'); e.textContent = 'Saisis uniquement des chiffres.'; e.classList.remove('hidden'); dlgSound('error'); return;
  }
  dlgSound('confirm');
  dlgClose(v);
}
$('dl-input').addEventListener('input', function () { dlgCount(); $('dl-err').classList.add('hidden'); });
$('dl-ok').addEventListener('click', dlgSubmit);
$('dl-cancel').addEventListener('click', function () { dlgSound('close'); dlgClose(null); });
document.addEventListener('keydown', function (e) {
  if (!dlgOpen) return;
  if (e.key === 'Enter') { e.preventDefault(); dlgSubmit(); }
  else if (e.key === 'Escape') { e.preventDefault(); dlgSound('close'); dlgClose(null); }
});
window.addEventListener('message', function (e) {
  var m = e.data || {};
  if (m.a === 'input') dlgOpenWith(m);
  else if (m.a === 'inputClose' && dlgOpen) { dlgOpen = false; $('dlgwrap').classList.add('hidden'); }
});


/* ===== Menu de choix ===== */
var CH_ICONS = {
  plane: '<path d="M10 14l-6.5 2.5v-2L10 11V5.5a2 2 0 0 1 4 0V11l6.5 3.5v2L14 14v4l2 1.5V21l-4-1-4 1v-1.5L10 18z"/>',
  city: '<path d="M4 21V9l6-3v15M10 21V4l6 2v15M16 21v-9l4 1.5V21M3 21h18"/>',
  beach: '<path d="M3 20h18M12 20V9M12 9c-3-4.5-7-3.5-8-2 3-1 5 0 8 2zM12 9c3-4.5 7-3.5 8-2-3-1-5 0-8 2z"/>',
  house: '<path d="M4 11l8-6.5 8 6.5M6 10v9.5h12V10M10 19.5v-5h4v5"/>',
  pin: '<path d="M12 21s7-6.2 7-11.5A7 7 0 0 0 5 9.5C5 14.8 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.6"/>'
};
var chOpen = false, chSel = 0, chCount = 0, chCancel = false;
function chRender() {
  var items = document.querySelectorAll('.ch-item');
  for (var i = 0; i < items.length; i++) items[i].classList.toggle('act', i === chSel);
}
function chClose(index) {
  if (!chOpen) return;
  chOpen = false;
  $('chwrap').classList.add('hidden');
  nuiPost('chooseDone', { index: index });
}
function chOpenWith(m) {
  var d = m.d || {};
  window.__vol = m.v;
  applyCfg(m.cfg || {});
  $('ch-title').textContent = d.title || 'Choix';
  $('ch-hint').textContent = d.hint || '';
  var opts = d.options || [];
  chCount = opts.length; chSel = 0; chCancel = d.cancellable === true;
  $('chwrap').classList.toggle('right', d.align === 'right');
  $('ch-list').innerHTML = opts.map(function (o, i) {
    var ic = CH_ICONS[o.icon] || CH_ICONS.pin;
    return '<div class="ch-item" data-i="' + i + '"><span class="ico"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' + ic + '</svg></span><span class="tx"><b>' + esc(o.label || '') + '</b>' + (o.description ? '<small>' + esc(o.description) + '</small>' : '') + '</span><span class="go"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l6 6-6 6"/></svg></span></div>';
  }).join('');
  Array.prototype.forEach.call(document.querySelectorAll('.ch-item'), function (el) {
    el.addEventListener('mouseenter', function () { var i = +el.dataset.i; if (i !== chSel) { chSel = i; chRender(); dlgSound('hover'); } });
    el.addEventListener('click', function () { dlgSound('confirm'); chClose(+el.dataset.i + 1); });
  });
  chOpen = true;
  chRender();
  $('chwrap').classList.remove('hidden');
  dlgSound('open');
}
document.addEventListener('keydown', function (e) {
  if (!chOpen) return;
  if (e.key === 'ArrowDown') { e.preventDefault(); chSel = (chSel + 1) % chCount; chRender(); dlgSound('hover'); }
  else if (e.key === 'ArrowUp') { e.preventDefault(); chSel = (chSel - 1 + chCount) % chCount; chRender(); dlgSound('hover'); }
  else if (e.key === 'Enter') { e.preventDefault(); dlgSound('confirm'); chClose(chSel + 1); }
  else if (e.key === 'Escape' && chCancel) { e.preventDefault(); dlgSound('close'); chClose(null); }
});
window.addEventListener('message', function (e) {
  var m = e.data || {};
  if (m.a === 'choose') chOpenWith(m);
});


// Barre d'aide des touches (exports KeysShow / KeysHide)
window.addEventListener('message', function (e) {
  var d = e.data || {};
  if (d.a !== 'keys') return;
  var bar = document.getElementById('keys');
  if (!d.items || !d.items.length) { bar.classList.add('hidden'); bar.innerHTML = ''; return; }
  var esc = function (s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); };
  bar.innerHTML = d.items.map(function (it) {
    var keys = Array.isArray(it.key) ? it.key : [it.key];
    return '<span class="kb"><span class="kk">' + keys.map(function (k) { return '<kbd>' + esc(k) + '</kbd>'; }).join('') + '</span><span class="kl">' + esc(it.label) + '</span></span>';
  }).join('');
  bar.classList.remove('hidden');
});


// ───────────── Menu contextuel ─────────────
(function () {
  var host = document.getElementById('ctx');
  var P = function (d) { return '<svg viewBox="0 0 24 24">' + d + '</svg>'; };
  var IC = {
    user: P('<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7"/>'),
    card: P('<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M7 10h4M7 14h6M15 10h2"/>'),
    job: P('<rect x="3" y="7" width="18" height="13" rx="2"/><path d="M9 7V5h6v2M3 13h18"/>'),
    team: P('<circle cx="9" cy="8" r="3"/><path d="M3 20c0-3.3 2.7-6 6-6s6 2.7 6 6"/><circle cx="17" cy="9" r="2.5"/><path d="M16 14c3 0 5 2 5 5"/>'),
    car: P('<path d="M5 16V11l2-5h10l2 5v5M3 16h18M7 16v2M17 16v2"/><circle cx="8" cy="13" r="1"/><circle cx="16" cy="13" r="1"/>'),
    money: P('<circle cx="12" cy="12" r="9"/><path d="M14.5 9c-.5-1-1.5-1.5-2.5-1.5-1.5 0-2.5.8-2.5 2s1 1.7 2.5 2 2.5.8 2.5 2-1 2-2.5 2c-1.100 0-2.100-.6-2.500-1.500M12 6v1.500M12 16.500V18"/>'),
    shield: P('<path d="M12 3l8 3v6c0 5-3.500 8-8 9-4.500-1-8-4-8-9V6z"/>'),
    search: P('<circle cx="11" cy="11" r="6.500"/><path d="m16 16 5 5"/>'),
    lock: P('<rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>'),
    walk: P('<circle cx="13" cy="4.500" r="2"/><path d="M8 21l3-7-2-3 3-3 3 3 3 1M11 14l3 3v4"/>'),
    shirt: P('<path d="M8 3 3 6l2 4 3-1v12h8V9l3 1 2-4-5-3c-.5 1.500-2 2.500-4 2.500S8.500 4.500 8 3Z"/>'),
    phone: P('<rect x="7" y="3" width="10" height="18" rx="2"/><path d="M11 18h2"/>'),
    heal: P('<rect x="4" y="4" width="16" height="16" rx="3"/><path d="M12 8v8M8 12h8"/>'),
    key: P('<circle cx="8" cy="15" r="4"/><path d="m11 12 8-8M16 7l3 3"/>'),
    list: P('<path d="M8 6h12M8 12h12M8 18h12M4 6h.01M4 12h.01M4 18h.01"/>'),
    music: P('<path d="M9 18V5l11-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="17" cy="16" r="3"/>'),
    box: P('<path d="m12 3 8 4v10l-8 4-8-4V7z"/><path d="m4 7 8 4 8-4M12 11v10"/>'),
    gun: P('<path d="M3 8h15l3 2v3h-8l-1 4H7l1-4H3Z"/>'),
    dot: P('<circle cx="12" cy="12" r="3.500"/>')
  };
  var MAP = [
    [/arme|weapon|munition/, 'gun'], [/amende|facture|bill/, 'list'], [/fouill|cherch|recherche|poudre|test/, 'search'], [/menott|cuff|attach|corde|ligot/, 'lock'], [/escort|porter|traîn|suivre|marche/, 'walk'],
    [/identit|carte|papier|permis|licen/, 'card'], [/v[eê]tement|tenue|habit|masque|chapeau|lunette/, 'shirt'], [/argent|money|banque|payer|vendre|achat|prix|\$/, 'money'], [/v[eé]hicule|voiture|moto|garage|plaque|coffre|moteur|capot/, 'car'],
    [/police|fdo|lspd|justice|alerte|appel/, 'shield'], [/soin|r[eé]anim|heal|m[eé]decin|ems|sant[eé]|soigner|blessure/, 'heal'], [/t[eé]l[eé]phone|appeler|sms/, 'phone'], [/cl[eé]|verrou|serrure|ouvrir|fermer/, 'key'],
    [/entreprise|soci[eé]t[eé]|gang|organisation|recrut|promouvoir|r[eé]trograd|virer|patron/, 'team'], [/m[eé]tier|travail|job/, 'job'], [/interaction|emote|danse|animation|musique|son/, 'music'], [/inventaire|objet|item|give|donner/, 'box'], [/joueur|citoyen|personne|invit/, 'user']
  ];
  var strip = function (s) { return String(s == null ? '' : s).replace(/~[a-z]~/gi, '').replace(/\s+/g, ' ').trim(); };
  var icon = function (t) { var l = strip(t).toLowerCase(); for (var i = 0; i < MAP.length; i++) if (MAP[i][0].test(l)) return IC[MAP[i][1]]; return IC.dot; };
  var CHEV = '<svg class="ch" viewBox="0 0 24 24"><path d="m9 6 6 6-6 6"/></svg>';
  var esc = function (s) { return String(s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); };
  var last = '';
  window.addEventListener('message', function (e) {
    var d = e.data || {};
    if (d.a !== 'ctx') return;
    if (!d.menus || !d.menus.length) { host.classList.add('hidden'); host.innerHTML = ''; last = ''; return; }
    var sig = JSON.stringify(d.menus);
    if (sig === last) return;
    var fresh = host.classList.contains('hidden');
    last = sig;
    host.innerHTML = d.menus.map(function (m) {
      var rows = m.items.map(function (it) {
        var top = ((it.y - m.y) * 100) / 1 * (1) / (m.h || 1);
        var cls = 'cr' + (it.hovered && it.enabled ? ' hov' : '') + (it.open ? ' open' : '') + (it.enabled === false ? ' off' : '') + (it.kind === 'text' ? ' txt' : '');
        var lead = it.kind === 'check' ? '<span class="bx' + (it.checked ? ' on' : '') + '"></span>' : (it.kind === 'text' ? '' : icon(it.text));
        var html = '<div class="' + cls + '" style="top:calc(' + ((it.y - m.y) * 100) + 'vh + 0px);height:' + (it.h * 100) + 'vh">' + lead + '<span class="l">' + gta(it.text) + '</span>' + (it.right ? '<span class="rt">' + gta(it.right) + '</span>' : '') + (it.kind === 'sub' ? CHEV : '') + '</div>';
        if (it.sep) html += '<div class="sp" style="top:calc(' + ((it.y - m.y + it.h + 0.0055) * 100) + 'vh)"></div>';
        return html;
      }).join('');
      return '<div class="cm" style="left:' + (m.x * 100) + 'vw;top:' + (m.y * 100) + 'vh;width:' + (m.w * 100) + 'vw;height:' + (m.h * 100) + 'vh">' + (m.title ? '<div class="cm-t">' + esc(strip(m.title)) + '</div>' : '') + rows + '</div>';
    }).join('');
    host.classList.toggle('fresh', fresh);
    host.classList.remove('hidden');
  });
})();

/* ── Légende de la carte ── */
(function () {
  var host = document.getElementById('leg'), list = document.getElementById('lgl'), q = document.getElementById('lgq');
  var COL = { 0:'#e8e8e8',1:'#e5453b',2:'#71cb71',3:'#5db6e5',4:'#ffffff',5:'#f1c40f',6:'#e5453b',7:'#a45bd1',8:'#f06fb0',9:'#f0a050',10:'#4a8fe0',11:'#3fb53f',17:'#f0a050',25:'#3fb53f',29:'#4a8fe0',38:'#4a8fe0',46:'#f1c40f',47:'#f0a050',50:'#a45bd1',69:'#71cb71',70:'#f1c40f',73:'#f1c40f',81:'#f0a050' };
  // pictogrammes (viewBox 24) — GTA ne donne pas accès à ses textures de blips, ce sont des équivalents dessinés
  var P = {
    house: '<path d="M3 11.5 12 4l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
    car: '<path d="M4 12l2-5a2 2 0 0 1 2-1.4h8A2 2 0 0 1 18 7l2 5a2 2 0 0 1 1 1.7V18a1 1 0 0 1-1 1h-2v-2H6v2H4a1 1 0 0 1-1-1v-4.3A2 2 0 0 1 4 12zm3-.5h10l-1.4-3.6H8.4z"/>',
    boat: '<path d="M12 3l5 9H7zm-8 11h16l-2.2 5H6.2z"/>',
    fuel: '<path d="M5 4h8v16H5zm1.8 2v4h4.4V6zM14 8l3 2v7a1 1 0 0 0 2 0v-8l-2.5-3z"/>',
    gun: '<path d="M2 8h15l1-1h3v4h-2l-1 1h-3l-1 4H8l-1-4H3z"/>',
    shirt: '<path d="M8 3l-5 3 2 4 2-1v11h10V9l2 1 2-4-5-3a4 4 0 0 1-8 0z"/>',
    scissors: '<path d="M6 3a3 3 0 1 1 0 6 3 3 0 0 1 0-6zm0 12a3 3 0 1 1 0 6 3 3 0 0 1 0-6zM8 8.5 21 3v2L10.5 12 21 19v2L8 15.5z"/>',
    dollar: '<path d="M11 2h2v2.2c2.2.3 3.5 1.6 3.6 3.5h-2.3c-.1-.9-.8-1.5-2.3-1.5-1.4 0-2.2.6-2.2 1.4 0 .9.7 1.2 2.7 1.7 2.7.6 4.1 1.5 4.1 3.6 0 1.8-1.3 3-3.6 3.4V20h-2v-2.2c-2.4-.3-3.9-1.7-4-3.7h2.3c.1 1.1 1 1.8 2.6 1.8 1.5 0 2.3-.6 2.3-1.5 0-.8-.5-1.2-2.6-1.7C8.3 11.9 7 11 7 9.2c0-1.7 1.2-2.8 4-3.2z"/>',
    cross: '<path d="M9 3h6v6h6v6h-6v6H9v-6H3V9h6z"/>',
    star: '<path d="M12 2l2.9 6.3 6.9.7-5.2 4.6 1.5 6.8L12 17l-6.1 3.4 1.5-6.8L2.2 9l6.9-.7z"/>',
    wrench: '<path d="M21 7a5 5 0 0 1-6.6 4.7L7 19.1a2 2 0 0 1-3-3l7.4-7.4A5 5 0 0 1 17 3l-3 3 1 3 3 1z"/>',
    cart: '<path d="M2 3h3l.8 3H21l-2 8H8l.4 2H19v2H6.6L4 5H2zm6 16a1.6 1.6 0 1 1 0 3.2A1.6 1.6 0 0 1 8 19zm9 0a1.6 1.6 0 1 1 0 3.2A1.6 1.6 0 0 1 17 19z"/>',
    skull: '<path d="M12 2a8 8 0 0 0-8 8c0 2.6 1.2 4.4 3 5.5V20h3v-2h4v2h3v-4.5c1.800-1.100 3-2.900 3-5.500a8 8 0 0 0-8-8zM8.800 9a1.800 1.800 0 1 1 0 3.600 1.800 1.800 0 0 1 0-3.600zm6.400 0a1.800 1.800 0 1 1 0 3.600 1.800 1.800 0 0 1 0-3.600z"/>',
    suit: '<path d="M8 2h8l-1 4 1 3-4 12-4-12 1-3z"/>',
    pin: '<path d="M12 2a7 7 0 0 1 7 7c0 5-7 13-7 13S5 14 5 9a7 7 0 0 1 7-7zm0 4a3 3 0 1 0 0 6 3 3 0 0 0 0-6z"/>',
    chip: '<path d="M12 2a10 10 0 1 1 0 20 10 10 0 0 1 0-20zm0 4a6 6 0 1 0 0 12 6 6 0 0 0 0-12z"/>',
    gem: '<path d="M6 3h12l4 6-10 12L2 9zm1.500 6L12 17l4.500-8z"/>',
    paw: '<path d="M12 11c3 0 6 3 6 6 0 2-1.500 3-3 3-1.200 0-2-.5-3-.5s-1.800.5-3 .5c-1.500 0-3-1-3-3 0-3 3-6 6-6zM5 9a2 2 0 1 1 0-4 2 2 0 0 1 0 4zm14 0a2 2 0 1 1 0-4 2 2 0 0 1 0 4zM9 6.500a2 2 0 1 1 0-4 2 2 0 0 1 0 4zm6 0a2 2 0 1 1 0-4 2 2 0 0 1 0 4z"/>',
    pins: '<path d="M7 3h10l-1 7 3 3v2h-6v6h-2v-6H5v-2l3-3z"/>'
  };
  var KW = [[/garage bateau|bateau|marina|port/i,'boat'],[/fourri/i,'car'],[/garage|parking/i,'house'],[/essence|station|carbur/i,'fuel'],[/armur|ammunation|arme/i,'gun'],[/v[eê]tement|magasin v|boutique|clothes/i,'shirt'],[/coiff|barbier|barber/i,'scissors'],[/banque|bank|atm|distributeur/i,'dollar'],[/h[oô]pital|pillbox|m[eé]decin|pharma/i,'cross'],[/lspd|police|sheriff|gouvern|mairie/i,'star'],[/concession|pdm|auto-?[eé]cole|v[eé]hicule|location/i,'car'],[/custom|m[eé]cano|r[eé]para|atelier|garage m/i,'wrench'],[/super|march|[eé]picerie|shop|magasin|boucher|bowling|animalerie/i,'cart'],[/gang|ballas|families|vagos|illegal|dealer|drogue|cartel|mafia/i,'skull'],[/casino|jeu|poker/i,'chip'],[/bijou|joaill/i,'gem'],[/animal/i,'paw'],[/emploi|travail|job|p[oô]le/i,'suit']];
  var SP = { 357:'house',50:'house',524:'house',427:'boat',361:'fuel',110:'gun',73:'shirt',71:'scissors',107:'dollar',108:'dollar',61:'hospital',60:'star',225:'car',446:'wrench',52:'cart',59:'cart',121:'skull',679:'chip',617:'gem' };
  var plain = function (s) { return String(s == null ? '' : s).replace(/~[A-Za-z_0-9]+~/g, '').replace(/\s+/g, ' ').trim(); };
  var glyph = function (g) {
    var t = plain(g.name).split('|').pop().trim(), k = '';
    for (var i = 0; i < KW.length; i++) if (KW[i][0].test(t)) { k = KW[i][1]; break; }
    if (!k) k = SP[g.sprite] || 'pin';
    if (k === 'hospital') k = 'cross';
    return '<svg class="bi" viewBox="0 0 24 24" style="color:' + (COL[g.color] || '#fdc27d') + '">' + P[k] + '</svg>';
  };
  var G = [], sel = '', post = function (n, d) { fetch('https://pickax_ui/' + n, { method: 'POST', body: JSON.stringify(d || {}) }).then(function (r) { return r.json(); }).then(function (g) { if (Array.isArray(g)) { G = g; draw(); } }).catch(function () {}); };
  var EYE = '<svg viewBox="0 0 24 24"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></svg>';
  var PIN = '<svg viewBox="0 0 24 24"><path d="M12 22s7-6.5 7-12a7 7 0 0 0-14 0c0 5.5 7 12 7 12z"/><circle cx="12" cy="10" r="2.5"/></svg>';
  var esc2 = function (s) { return String(s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); };
  function draw() {
    var f = q.value.trim().toLowerCase(), h = '';
    G.filter(function (g) { return !f || plain(g.name).toLowerCase().indexOf(f) >= 0; }).forEach(function (g) {
      var on = g.key === sel;
      h += '<div class="lr' + (on ? ' sel' : '') + (g.hidden ? ' off' : '') + '" data-k="' + esc2(g.key) + '"><span class="ic">' + glyph(g) + '</span><span class="nm">' + gta(g.name) + '</span>' +
        (on ? '<span class="ab" data-a="eye" title="Afficher / masquer">' + EYE + '</span><span class="ab" data-a="go" title="Placer un repère">' + PIN + '</span>' : '') +
        '<span class="cn"><u data-a="p">‹</u>' + g.idx + '/' + g.n + '<u data-a="n">›</u></span></div>';
    });
    list.innerHTML = h || '<div class="lt">AUCUN RÉSULTAT</div>';
  }
  list.addEventListener('click', function (e) {
    var r = e.target.closest('.lr'); if (!r) return; var k = r.getAttribute('data-k'), a = (e.target.closest('[data-a]') || {}).getAttribute ? e.target.closest('[data-a]').getAttribute('data-a') : '';
    if (a === 'p') return post('legStep', { key: k, dir: -1 });
    if (a === 'n') return post('legStep', { key: k, dir: 1 });
    if (a === 'eye') return post('legToggle', { key: k });
    if (a === 'go') return post('legGo', { key: k });
    sel = k; draw(); post('legSelect', { key: k });
  });
  q.addEventListener('input', draw);
  document.getElementById('lgShow').onclick = function () { post('legAll', { hide: false }); };
  document.getElementById('lgHide').onclick = function () { post('legAll', { hide: true }); };
  document.addEventListener('keydown', function (e) {
    if (host.classList.contains('hidden')) return;
    var vis = Array.prototype.map.call(list.querySelectorAll('.lr'), function (n) { return n.getAttribute('data-k'); }), i = vis.indexOf(sel);
    if (e.key === 'Escape') { post('legClose'); }
    else if (e.key === 'ArrowDown') { sel = vis[Math.min(vis.length - 1, i + 1)] || sel; draw(); e.preventDefault(); }
    else if (e.key === 'ArrowUp') { sel = vis[Math.max(0, i - 1)] || sel; draw(); e.preventDefault(); }
    else if (e.key === 'ArrowRight' && sel && document.activeElement !== q) post('legStep', { key: sel, dir: 1 });
    else if (e.key === 'ArrowLeft' && sel && document.activeElement !== q) post('legStep', { key: sel, dir: -1 });
    else if (e.key === 'Enter' && sel) post('legGo', { key: sel });
  });
  window.addEventListener('message', function (e) {
    var d = e.data || {}; if (d.a !== 'leg') return;
    if (!d.open) { host.classList.add('hidden'); return; }
    G = d.groups || []; sel = G.length ? G[0].key : ''; q.value = ''; draw(); host.classList.remove('hidden');
  });
  window.__legTest = function (g) { G = g; sel = g[0].key; draw(); host.classList.remove('hidden'); };
})();
