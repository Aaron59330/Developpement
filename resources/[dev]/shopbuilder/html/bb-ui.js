/* bb-ui : module commun à tous les builders (sons motion design, taille, bords, accès au panel Builders).
   Un seul fichier, copié dans chaque builder. Réglages mémorisés par builder (localStorage). */
(function () {
  'use strict';
  var KEY = 'bbui.v1';
  var cfg = { sound: true, vol: 60, size: 100, sq: false };
  try { var s = JSON.parse(localStorage.getItem(KEY) || 'null'); if (s && typeof s === 'object') { for (var k in cfg) if (k in s) cfg[k] = s[k]; } } catch (e) {}
  function save() { try { localStorage.setItem(KEY, JSON.stringify(cfg)); } catch (e) {} }

  var resName = function () { return typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'builder'; };

  /* ───────────────────────── Sons (synthétisés, aucun fichier) ───────────────────────── */
  var ctx = null, lastHover = 0;
  function audio() {
    if (!ctx) { try { ctx = new (window.AudioContext || window.webkitAudioContext)(); } catch (e) { return null; } }
    if (ctx.state === 'suspended') ctx.resume();
    return ctx;
  }
  function tone(freq, dur, type, vol, delay, slideTo) {
    var c = audio(); if (!c) return;
    var t0 = c.currentTime + (delay || 0), o = c.createOscillator(), g = c.createGain();
    o.type = type || 'sine';
    o.frequency.setValueAtTime(freq, t0);
    if (slideTo) o.frequency.exponentialRampToValueAtTime(slideTo, t0 + dur);
    var v = Math.max(0.0001, (vol || 0.1) * (cfg.vol / 100));
    g.gain.setValueAtTime(0.0001, t0);
    g.gain.exponentialRampToValueAtTime(v, t0 + 0.008);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    o.connect(g); g.connect(c.destination);
    o.start(t0); o.stop(t0 + dur + 0.02);
  }
  var SND = {
    click:   function () { tone(540, 0.06, 'sine', 0.10); tone(810, 0.08, 'sine', 0.07, 0.035); },
    confirm: function () { tone(520, 0.09, 'triangle', 0.11); tone(780, 0.09, 'triangle', 0.10, 0.07); tone(1040, 0.16, 'triangle', 0.09, 0.14); },
    warn:    function () { tone(320, 0.14, 'sawtooth', 0.06, 0, 200); },
    hover:   function () { tone(1250, 0.025, 'sine', 0.035); },
    tab:     function () { tone(420, 0.09, 'sine', 0.08, 0, 700); },
    on:      function () { tone(500, 0.07, 'sine', 0.09); tone(760, 0.1, 'sine', 0.09, 0.06); },
    off:     function () { tone(760, 0.07, 'sine', 0.08); tone(480, 0.1, 'sine', 0.08, 0.06); },
    open:    function () { tone(330, 0.12, 'sine', 0.09, 0, 520); tone(660, 0.16, 'sine', 0.08, 0.09); },
    close:   function () { tone(620, 0.1, 'sine', 0.08, 0, 330); },
    success: function () { tone(660, 0.1, 'triangle', 0.1); tone(990, 0.18, 'triangle', 0.09, 0.09); },
    error:   function () { tone(210, 0.18, 'square', 0.05); tone(170, 0.2, 'square', 0.05, 0.12); }
  };
  function play(name) { if (cfg.sound && SND[name]) { try { SND[name](); } catch (e) {} } }
  window.BBUI = { play: play, settings: cfg };

  // Tout élément cliquable (builder ET menus créés pour les joueurs) : bouton, lien, champ de choix, ou tout ce qui affiche un curseur « main »
  var NATIVE = 'button, select, a[href], label, input[type=checkbox], input[type=radio], [role=button], [data-a], [data-open], .nav-item, .tab, .card.click, .click';
  function interactive(el) {
    for (var n = el, i = 0; n && n.nodeType === 1 && n !== document.body && i < 8; n = n.parentElement, i++) {
      if (n.id === 'bbdock') return null;
      if (n.disabled || n.classList.contains('off')) return null;
      if (n.matches(NATIVE)) return n;
      try { if (getComputedStyle(n).cursor === 'pointer') return n; } catch (e) {}
    }
    return null;
  }
  var lastHoverEl = null;
  document.addEventListener('mouseover', function (e) {
    var t = interactive(e.target);
    if (!t) { lastHoverEl = null; return; }
    if (t === lastHoverEl) return;
    lastHoverEl = t;
    var now = Date.now();
    if (now - lastHover < 70) return;
    lastHover = now;
    play('hover');
  }, true);
  document.addEventListener('click', function (e) {
    var raw = e.target.closest && e.target.closest('#bbdock');
    if (raw) { var s = e.target.closest('[data-bb]'); if (s && s.matches('[data-bb=snd]')) return; play('click'); return; }
    var t = interactive(e.target);
    if (!t) return;
    var cb = t.matches('input[type=checkbox]') ? t : t.querySelector && t.querySelector('input[type=checkbox]');
    if (cb && (t.matches('label') || t === cb)) { play(cb.checked ? 'on' : 'off'); return; }
    if (t.matches('.nav-item, .tab, [role=tab]')) { play('tab'); return; }
    if (t.matches('button.danger, .danger')) { play('warn'); return; }
    if (t.matches('button.primary, .primary')) { play('confirm'); return; }
    play('click');
  }, true);

  /* ───────────────────────── Apparence commune ───────────────────────── */
  var style = document.createElement('style');
  style.textContent =
    'body.bb-sq *:not(#bbdock):not(#bbdock *) { border-radius: 0 !important; }' +
    '#bbdock { position: fixed; right: 12px; bottom: 8px; z-index: 99999; font-family: "Inter","Segoe UI",system-ui,sans-serif; font-size: 12px; color: #f4f4f5; }' +
    '#bbdock.hidden { display: none; }' +
    '#bbdock .bb-fab { display: inline-flex; align-items: center; gap: 7px; height: 32px; padding: 0 12px; border-radius: 999px; border: 1px solid rgba(255,255,255,.18); background: rgba(11,11,12,.92); color: #f4f4f5; cursor: pointer; font: inherit; font-weight: 600; box-shadow: 0 8px 24px rgba(0,0,0,.45); }' +
    '#bbdock .bb-fab:hover { background: rgba(30,30,33,.96); }' +
    '#bbdock svg { width: 15px; height: 15px; fill: none; stroke: currentColor; stroke-width: 1.9; stroke-linecap: round; stroke-linejoin: round; }' +
    '#bbdock .bb-pop { position: absolute; right: 0; bottom: 40px; width: 250px; padding: 14px; border-radius: 16px; border: 1px solid rgba(255,255,255,.12); background: rgba(11,11,12,.97); box-shadow: 0 24px 60px rgba(0,0,0,.6); display: none; }' +
    '#bbdock.open .bb-pop { display: block; animation: bbpop .14s ease-out; }' +
    '@keyframes bbpop { from { opacity: 0; transform: translateY(6px); } }' +
    '#bbdock .bb-row { display: flex; align-items: center; justify-content: space-between; gap: 10px; padding: 7px 0; }' +
    '#bbdock .bb-row + .bb-row { border-top: 1px solid rgba(255,255,255,.07); }' +
    '#bbdock .bb-lbl { font-size: 10px; text-transform: uppercase; letter-spacing: .12em; color: #7d7d85; font-weight: 700; }' +
    '#bbdock .bb-seg { display: inline-flex; border: 1px solid rgba(255,255,255,.14); border-radius: 9px; overflow: hidden; }' +
    '#bbdock .bb-seg button { all: unset; cursor: pointer; padding: 5px 9px; font-size: 11px; color: #c9c9ce; }' +
    '#bbdock .bb-seg button.on { background: #fff; color: #0b0b0c; font-weight: 700; }' +
    '#bbdock .bb-sw { width: 38px; height: 22px; border-radius: 999px; border: 1px solid rgba(255,255,255,.2); background: transparent; position: relative; cursor: pointer; }' +
    '#bbdock .bb-sw::after { content: ""; position: absolute; top: 2px; left: 2px; width: 16px; height: 16px; border-radius: 50%; background: #7d7d85; transition: transform .14s, background .14s; }' +
    '#bbdock .bb-sw.on { background: #fff; border-color: #fff; }' +
    '#bbdock .bb-sw.on::after { transform: translateX(16px); background: #0b0b0c; }' +
    '#bbdock input[type=range] { width: 120px; accent-color: #fff; height: 4px; }' +
    '#bbdock .bb-hub { width: 100%; margin-top: 8px; height: 34px; border-radius: 10px; border: 1px solid #fff; background: #fff; color: #0b0b0c; font: inherit; font-weight: 700; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 8px; }' +
    '#bbdock .bb-hub:hover { background: #e7e7ea; }';
  document.head.appendChild(style);

  function applyLook() {
    document.body.classList.toggle('bb-sq', !!cfg.sq);
    var root = document.getElementById('root');
    if (root) root.style.zoom = cfg.size === 100 ? '' : String(cfg.size / 100);
  }

  /* ───────────────────────── Dock (sons, taille, bords, accès Builders) ───────────────────────── */
  var ICON_SND = '<svg viewBox="0 0 24 24"><path d="M11 5L6 9H3v6h3l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7M18.5 5.5a9 9 0 0 1 0 13"/></svg>';
  var ICON_GRID = '<svg viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg>';
  var dock = document.createElement('div');
  dock.id = 'bbdock'; dock.className = 'hidden';

  function seg(name, opts, cur) {
    return '<span class="bb-seg">' + opts.map(function (o) { return '<button data-bb="' + name + '" data-v="' + o[0] + '" class="' + (String(cur) === String(o[0]) ? 'on' : '') + '">' + o[1] + '</button>'; }).join('') + '</span>';
  }
  function drawDock() {
    dock.innerHTML =
      '<div class="bb-pop">' +
      '<div class="bb-row"><span class="bb-lbl">Sons</span><button class="bb-sw' + (cfg.sound ? ' on' : '') + '" data-bb="snd" title="Activer / désactiver les sons"></button></div>' +
      '<div class="bb-row"><span class="bb-lbl">Volume</span><input type="range" min="10" max="100" step="5" value="' + cfg.vol + '" data-bb="vol"></div>' +
      '<div class="bb-row"><span class="bb-lbl">Taille</span>' + seg('size', [[90, '90%'], [100, '100%'], [110, '110%']], cfg.size) + '</div>' +
      '<div class="bb-row"><span class="bb-lbl">Bords</span>' + seg('sq', [['0', 'Arrondis'], ['1', 'Carrés']], cfg.sq ? 1 : 0) + '</div>' +
      (window.BBUI_NO_HUB ? '' : '<button class="bb-hub" data-bb="hub">' + ICON_GRID + ' Tous les builders</button>') +
      '</div>' +
      '<button class="bb-fab" data-bb="fab" title="Sons et apparence">' + ICON_SND + '<span>' + (cfg.sound ? 'Sons' : 'Muet') + '</span></button>';
  }
  dock.addEventListener('click', function (e) {
    var t = e.target.closest('[data-bb]'); if (!t) return;
    var a = t.getAttribute('data-bb');
    if (a === 'fab') { dock.classList.toggle('open'); return; }
    if (a === 'snd') { cfg.sound = !cfg.sound; save(); drawDock(); dock.classList.add('open'); if (cfg.sound) play('on'); return; }
    if (a === 'size') { cfg.size = Number(t.getAttribute('data-v')); save(); applyLook(); drawDock(); dock.classList.add('open'); return; }
    if (a === 'sq') { cfg.sq = t.getAttribute('data-v') === '1'; save(); applyLook(); drawDock(); dock.classList.add('open'); return; }
    if (a === 'hub') {
      fetch('https://' + resName() + '/rpc', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name: 'bbHub', args: [] }) }).catch(function () {});
    }
  });
  dock.addEventListener('input', function (e) {
    var t = e.target.closest('[data-bb=vol]'); if (!t) return;
    cfg.vol = Number(t.value); save();
    clearTimeout(dock._vt); dock._vt = setTimeout(function () { play('click'); }, 120);
  });

  function sync() {
    var root = document.getElementById('root');
    var visible = root && !root.classList.contains('hidden');
    dock.classList.toggle('hidden', !visible);
    if (!visible) dock.classList.remove('open');
    return visible;
  }

  function boot() {
    document.body.appendChild(dock);
    drawDock(); applyLook();
    var root = document.getElementById('root');
    var was = root && !root.classList.contains('hidden');
    if (root) {
      new MutationObserver(function () {
        var v = sync();
        if (v !== was) { play(v ? 'open' : 'close'); was = v; applyLook(); }
      }).observe(root, { attributes: true, attributeFilter: ['class'] });
    }
    sync();
    var toasts = document.getElementById('toasts');
    if (toasts) {
      new MutationObserver(function (list) {
        list.forEach(function (m) {
          Array.prototype.forEach.call(m.addedNodes, function (n) {
            if (n.nodeType !== 1) return;
            var c = (n.className || '') + '';
            play(/\b(err|error|bad|danger)\b/.test(c) ? 'error' : 'success');
          });
        });
      }).observe(toasts, { childList: true });
    }
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') dock.classList.remove('open'); });
  }
  if (document.body) boot(); else document.addEventListener('DOMContentLoaded', boot);
})();

/* ───────────────────────── BBMap : cartes « Blip » et « Marker » communes à tous les builders ─────────────────────────
   Même mise en page, mêmes champs, mêmes valeurs par défaut partout (Job, Gang, Shop, World).
   Utilise les helpers globaux de chaque builder : fld(), ic(). Les champs utilisent data-path / data-t (supportés par tous). */
(function () {
  'use strict';
  var TYPES = [[0, 'Cône inversé'], [1, 'Cylindre'], [2, 'Chevron épais'], [3, 'Chevron fin'], [4, 'Drapeau à damier'], [5, 'Drapeau à damier (rond)'], [6, 'Cercle vertical'], [7, 'Avion'],
    [20, 'Chevron ×1'], [21, 'Chevron ×2'], [22, 'Chevron ×3'], [23, 'Cercle épais'], [24, 'Icône replay'], [25, 'Cercle fin'], [26, 'Cercle fin + flèche'], [27, 'Cercle + flèches'], [28, 'Sphère'],
    [29, 'Symbole dollar'], [30, 'Barres horizontales'], [31, 'Tête de loup'], [32, "Point d'interrogation"], [33, 'Symbole avion'], [34, 'Symbole hélico'], [35, 'Symbole bateau'], [36, 'Symbole voiture'],
    [37, 'Symbole moto'], [38, 'Symbole vélo'], [39, 'Symbole camion'], [40, 'Symbole parachute'], [41, 'Lame de scie']];
  function esc(s) { return String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); }
  function val(v) { return v === undefined || v === null ? '' : esc(v); }
  function num(path, v, extra, ph) { return '<input type="number" data-path="' + path + '" data-t="n" value="' + val(v) + '"' + (ph !== undefined ? ' placeholder="' + esc(ph) + '"' : '') + ' ' + (extra || '') + '>'; }
  function chk(path, label, on, rerender) { return '<label class="chk"><input type="checkbox" data-path="' + path + '" data-t="b"' + (rerender ? ' data-r="1"' : '') + (on ? ' checked' : '') + '> ' + label + '</label>'; }

  /* Carte « Blip sur la carte » : o = { base, b, title, labelHint, hint, extra } */
  function blipCard(o) {
    var b = o.b || {}, p = o.base;
    return '<div class="card"><div class="card-h"><div class="t">' + ic('pin', 17) + ' ' + (o.title || 'Blip sur la carte') + '</div>' + chk(p + '.enabled', 'Afficher', b.enabled, true) + '</div>' +
      '<div class="grid4">' +
      fld('Sprite', num(p + '.sprite', b.sprite, 'min="0" max="900"', o.defSprite)) +
      fld('Couleur', num(p + '.color', b.color, 'min="0" max="85"', o.defColor)) +
      fld('Taille', num(p + '.scale', b.scale, 'step="0.1" min="0.1" max="3"', o.defScale || 0.8)) +
      fld('Nom du blip', '<input data-path="' + p + '.label" value="' + val(b.label) + '" maxlength="60" placeholder="' + esc(o.labelHint || 'Par défaut : nom du module') + '">') +
      '</div><div class="row mt-s" style="gap:22px;flex-wrap:wrap">' + chk(p + '.shortRange', 'Visible uniquement à proximité', b.shortRange !== false) +
      (o.hint ? '<span class="hint">' + o.hint + '</span>' : '') + '</div>' + (o.extra || '') + '</div>';
  }

  /* Carte « Marker au sol » : o = { base, m, typeKey ('type' | 'marker'), colorHtml, title, withEnabled, inherit } — champs vides = hérités du style commun */
  function markerCard(o) {
    var m = o.m || {}, p = o.base, tk = o.typeKey || 'type', inh = o.inherit || {}, isc = inh.scale || {}, sc = m.scale || {};
    var t = Number(m[tk] != null ? m[tk] : inh[tk]);
    if (isNaN(t)) t = o.defType != null ? o.defType : 25;
    var known = TYPES.some(function (x) { return x[0] === t; });
    var sel = '<select data-path="' + p + '.' + tk + '" data-t="n">' + TYPES.map(function (x) { return '<option value="' + x[0] + '"' + (t === x[0] ? ' selected' : '') + '>' + x[0] + ' · ' + x[1] + '</option>'; }).join('') +
      (known || isNaN(t) ? '' : '<option value="' + t + '" selected>' + t + ' · (personnalisé)</option>') + '</select>';
    var d = function (v, def) { return v !== undefined && v !== null ? v : def; };
    return '<div class="card"><div class="card-h"><div class="t">' + ic('target', 17) + ' ' + (o.title || 'Marker au sol') + '</div>' +
      '<button class="sm" data-a="bbPreview" data-v="' + p + '">' + ic('target', 14) + ' Aperçu en jeu</button>' +
      (o.withEnabled === false ? '' : '<span style="margin-left:12px">' + chk(p + '.enabled', 'Afficher', m.enabled !== false, true) + '</span>') + '</div>' +
      '<div class="grid4">' + fld('Forme du marker', sel) + (o.colorHtml ? o.colorHtml : '<div></div>') +
      fld('Opacité (0-255)', num(p + '.alpha', m.alpha, 'min="0" max="255"', d(inh.alpha, 140))) +
      fld('Décalage vertical', num(p + '.offset', m.offset, 'step="0.05"', d(inh.offset, -0.95))) + '</div>' +
      '<div class="grid4 mt">' +
      fld('Taille X', num(p + '.scale.x', sc.x, 'step="0.05" min="0.05"', d(isc.x, 0.9))) +
      fld('Taille Y', num(p + '.scale.y', sc.y, 'step="0.05" min="0.05"', d(isc.y, 0.9))) +
      fld('Hauteur (Z)', num(p + '.scale.z', sc.z, 'step="0.05" min="0.05"', d(isc.z, 0.6))) +
      '<div class="row" style="align-items:flex-end;gap:22px;flex-wrap:wrap">' + chk(p + '.bob', 'Rebond', m.bob === true) + chk(p + '.rotate', 'Rotation', m.rotate === true) + chk(p + '.help', 'Aide « E »', m.help !== false) + '</div></div>' +
      '<div class="hint mt-s">Les champs vides reprennent le style commun (Paramètres → Marker). Même éditeur dans tous les builders.</div></div>';
  }

  window.BBMap = { markerTypes: TYPES, blipCard: blipCard, markerCard: markerCard };
})();
