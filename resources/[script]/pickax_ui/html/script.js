'use strict';
var $ = function (id) { return document.getElementById(id); };
var COLORS = { r: '#f87171', g: '#4ade80', b: '#60a5fa', y: '#fbbf24', o: '#fb923c', p: '#c084fc', c: '#9ca3af', m: '#6b7280', u: '#000', w: '#fff', q: '#f472b6' };

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
  if (it.r) h += '<span class="rt">' + gta(it.r) + '</span>';
  if (it.k === 'c') h += '<span class="box' + (it.ck ? ' on' : '') + (it.cs === 'cross' ? ' x' : '') + '"></span>';
  if (it.rb) h += badge(it.rb);
  if (it.en === false && !it.rb) h += ICONS.lock;
  if (it.sub && !it.r && !it.rb && it.en !== false) h += CHEV;
  return h + '</div>';
}

function hexRgb(h) {
  var m = /^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i.exec(h || '');
  return m ? parseInt(m[1], 16) + ',' + parseInt(m[2], 16) + ',' + parseInt(m[3], 16) : '0,164,255';
}

var STYLE_ALPHA = { noir: .94, verre: .62, clair: .97, neon: .95, bleu: .96 };
var OVERRIDES = ['--card-bg', '--text', '--text-2', '--muted', '--act-bg', '--act-border', '--act-text', '--r-btn', '--r-card'];

function applyCfg(c) {
  if (!c) return;
  var w = $('wrap'), st = w.style;
  w.setAttribute('data-style', c.style || 'noir');
  w.setAttribute('data-size', c.size || 'md');
  st.setProperty('--accent', c.accent || '#00a4ff');
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
  if (c.selbg) st.setProperty('--act-bg', 'rgba(' + hexRgb(c.selbg) + ',.3)');
  if (c.selborder) st.setProperty('--act-border', c.selborder);
  if (c.btnRadius !== undefined) st.setProperty('--r-btn', c.btnRadius + 'px');
  if (c.cardRadius !== undefined) st.setProperty('--r-card', c.cardRadius + 'px');
  $('banner').classList.toggle('hidden', c.banner === false);
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
