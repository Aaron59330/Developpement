'use strict';
var $ = function (id) { return document.getElementById(id); };
var COLORS = { r: '#f87171', g: '#4ade80', b: (window.PICKAX_ACCENT || '#00a4ff'), y: '#fbbf24', o: '#fb923c', p: '#c084fc', c: '#9ca3af', m: '#6b7280', u: '#000', w: '#fff', q: '#f472b6' };

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

var ICOMAP = [
  [/informations|profil/i,'<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-7 8-7s8 3 8 7"/>'],
  [/document|identit|permis/i,'<rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="9" cy="11" r="2"/><path d="M15 10h3M15 13h3M6 16c.5-1.5 1.7-2 3-2s2.5.5 3 2"/>'],
  [/v[ée]hicule|moteur|capot|coffre|portes|fen[êe]tre|limit/i,'<path d="M5 17h14M3 13l2-6h14l2 6v4H3zM7 17v2M17 17v2"/>'],
  [/pr[ée]f[ée]rence|r[ée]glage|apparence|hud|performance|style/i,'<circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 00-.1-1.3l2-1.5-2-3.4-2.3 1a7 7 0 00-2.2-1.3L14 3h-4l-.4 2.5a7 7 0 00-2.2 1.3l-2.3-1-2 3.4 2 1.5A7 7 0 005 12c0 .4 0 .9.1 1.3l-2 1.5 2 3.4 2.3-1a7 7 0 002.2 1.3L10 21h4l.4-2.5a7 7 0 002.2-1.3l2.3 1 2-3.4-2-1.5c.1-.4.1-.9.1-1.3z"/>'],
  [/touche|raccourci/i,'<rect x="3" y="6" width="18" height="12" rx="2"/><path d="M7 10h.01M11 10h.01M15 10h.01M7 14h10"/>'],
  [/commande/i,'<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M7 9l3 3-3 3M13 15h4"/>'],
  [/boussole|compass/i,'<circle cx="12" cy="12" r="9"/><path d="M15.5 8.5l-2 5-5 2 2-5z"/>'],
  [/m[ée]tier|argent|portefeuille/i,'<rect x="3" y="7" width="18" height="13" rx="2"/><path d="M9 7V5a2 2 0 012-2h2a2 2 0 012 2v2M3 13h18"/>'],
  [/discord/i,'<path d="M7 7c3-1 7-1 10 0l2 9c-2 1.5-4 2-7 2s-5-.5-7-2zM9.5 12h.01M14.5 12h.01"/>'],
  [/boutique/i,'<path d="M6 7h12l1 13H5zM9 7a3 3 0 016 0"/>'],
  [/serveur|joueur/i,'<rect x="3" y="4" width="18" height="7" rx="2"/><rect x="3" y="13" width="18" height="7" rx="2"/><path d="M7 7.5h.01M7 16.5h.01"/>'],
  [/facture/i,'<path d="M6 3h9l4 4v14H6zM14 3v5h5M9 13h7M9 17h7"/>'],
  [/crosse|radar|hud|jeu/i,'<rect x="2" y="7" width="20" height="11" rx="5"/><path d="M7 12h4M9 10v4M15.5 11h.01M18 13h.01"/>'],
  [/record|editor/i,'<rect x="3" y="6" width="13" height="12" rx="2"/><path d="M16 10l5-3v10l-5-3z"/>'],
  [/son|volume/i,'<path d="M3 9h5l5-4v14l-5-4H3zM16.5 8.5a5 5 0 010 7"/>'],
  [/couleur|bord|taille|banni/i,'<path d="M12 3a9 9 0 100 18c1.5 0 2-1 1.5-2.2-.5-1.3.3-2.3 1.6-2.3H17a4 4 0 004-4c0-5-4-9.5-9-9.5z"/>'],
  [/r[ée]initialiser/i,'<path d="M3 12a9 9 0 109-9M3 4v5h5"/>']
];
function icoFor(label){ var t=String(label||'').replace(/~[a-zA-Z]~/g,''); for(var i=0;i<ICOMAP.length;i++){ if(ICOMAP[i][0].test(t)) return '<span class="ico"><svg viewBox="0 0 24 24">'+ICOMAP[i][1]+'</svg></span>'; } return '<span class="ico"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="3"/></svg></span>'; }
function item(it) {
  if (it.k === 'ln') return '<div class="ln"></div>';
  if (it.k === 's') return '<div class="sep">' + (it.l ? '<span>' + gta(it.l) + '</span>' : '') + '</div>';
  var cls = 'it' + (it.act ? ' act' : '') + (it.en === false ? ' off' : '');
  var style = '';
  var col = it.act ? it.hl : it.bg;
  if (col) style = ' style="background:rgba(' + col[0] + ',' + col[1] + ',' + col[2] + ',.28);border-color:rgba(' + col[0] + ',' + col[1] + ',' + col[2] + ',.7)"';
  var h = '<div class="' + cls + '"' + style + '>';
  h += badge(it.lb) || icoFor(it.l);
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
  return m ? parseInt(m[1], 16) + ',' + parseInt(m[2], 16) + ',' + parseInt(m[3], 16) : (window.PICKAX_ACCENT_RGB || '0,164,255');
}

var STYLE_ALPHA = { noir: .94, verre: .62, clair: .97, neon: .95, bleu: .96 };
var OVERRIDES = ['--sel', '--sel-bd', '--card-bg', '--text', '--text-2', '--muted', '--act-bg', '--act-border', '--act-text', '--r-btn', '--r-card'];

var designClassic = false;
function applyCfg(c) {
  if (!c) return;
  [$('wrap'), $('dlgwrap'), $('chwrap')].forEach(function (w) { applyCfgTo(w, c); });
  $('banner').classList.toggle('hidden', c.banner === false);
  $('banner-old').classList.toggle('hidden', c.banner === false);
  var classic = c.design === 'classique';
  $('css-new').disabled = c.design === 'classique' || c.design === 'aqua';
  $('css-old').disabled = !classic;
  $('css-aqua').disabled = c.design !== 'aqua';
  designClassic = classic;
}

function applyCfgTo(w, c) {
  var st = w.style;
  w.setAttribute('data-style', c.style || 'noir');
  w.setAttribute('data-size', c.size || 'md');
  st.setProperty('--accent', c.accent || (window.PICKAX_ACCENT || '#00a4ff'));
  st.setProperty('--accent-rgb', hexRgb(c.accent));
  OVERRIDES.forEach(function (k) { st.removeProperty(k); });
  if (c.bg) st.setProperty('--card-bg', 'rgba(' + hexRgb(c.bg) + ',' + (STYLE_ALPHA[c.style] || .94) + ')');
  if (c.text) {
    var t = hexRgb(c.text);
    st.setProperty('--text', 'rgb(' + t + ')');
    st.setProperty('--text-2', 'rgba(' + t + ',.82)');
    st.setProperty('--muted', 'rgba(' + t + ',.5)');
    st.setProperty('--act-text', 'rgb(' + t + ')');
  }
  if (c.selbg) { st.setProperty('--act-bg', 'rgba(' + hexRgb(c.selbg) + ',.3)'); st.setProperty('--sel', hexRgb(c.selbg).split(',').length === 3 ? 'rgb(' + hexRgb(c.selbg) + ')' : ''); }
  if (c.selborder) { st.setProperty('--act-border', c.selborder); st.setProperty('--sel-bd', c.selborder); }
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
  var items = d.i || [], act = null;
  if (designClassic) {
    $('info').classList.toggle('hidden', !d.inf);
    if (d.inf) $('info').innerHTML = infoHtml(d.inf);
    var ds = $('desc');
    if (d.ds) { ds.innerHTML = '<span class="dt">' + gta(d.ds) + '</span>'; ds.classList.remove('hidden'); } else { ds.classList.add('hidden'); }
    return;
  }
  $('desc').classList.add('hidden');
  items.forEach(function (it) { if (it.act) act = it; });
  var p = '';
  if (act && act.k !== 's' && act.k !== 'ln') {
    p += '<div class="pico">' + icoFor(act.l) + '</div>';
    p += '<h2>' + gta(act.l) + '</h2>';
    if (act.k === 'c') p += '<div class="state ' + (act.ck ? 'on' : '') + '"><i></i>' + (act.ck ? 'Activé' : 'Désactivé') + '</div>';
    else if (act.k === 'l') p += '<div class="state on"><i></i>' + gta(act.v) + '</div>';
    else if (act.r && !/^(→+|⇒|▶|►|>>|↗)$/.test(plain(act.r))) p += '<div class="state on"><i></i>' + gta(act.r) + '</div>';
    if (d.ds) p += '<p class="pd">' + gta(d.ds) + '</p>';
    p += '<div class="hint">' + (act.k === 'c' ? 'Entrée pour activer / désactiver' : act.k === 'l' ? '← → pour changer la valeur' : (/↗/.test(String(act.r || '')) ? 'Entrée pour ouvrir le lien' : 'Entrée pour valider')) + '</div>';
  } else if (d.ds) {
    p += '<p class="pd" style="margin-top:20px">' + gta(d.ds) + '</p>';
  }
  if (d.inf) p += '<div class="infb">' + infoHtml(d.inf) + '</div>';
  var inf = $('info');
  if (p) { inf.innerHTML = p; inf.classList.remove('hidden'); } else { inf.classList.add('hidden'); }
  var a = document.querySelector('#items .it.act');
  if (a && a.scrollIntoView) a.scrollIntoView({ block: 'nearest' });
}

function plain(t) { return String(t || '').replace(/~[a-zA-Z_0-9]+~/g, '').trim(); }

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
