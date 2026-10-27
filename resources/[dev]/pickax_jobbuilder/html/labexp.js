/* Laboratoire interactif : une fabrication en plusieurs étapes jouées à la souris (ajouter, gratter, mélanger, chauffer, transvaser, cadence…).
   La caméra du jeu montre la table de laboratoire ; cette couche dessine les accessoires, le HUD (étape, ingrédients, consigne, progression) et gère la souris.
   Message d'ouverture : { action:'labx', cmd:'start', session:{ lab, title, steps:[{ type, title, hint, ... }], inventory:[{ label, count, icon }] } } · 'abort' pour fermer.
   Résultat envoyé au jeu : labxDone { results:[{ ok, score, ms }] } ou labxAbort. Types d'étape : add, scrape, stir, heat, pour, timing. */
(function () {
  'use strict';
  var root = document.getElementById('labx');
  if (!root) return;
  var $ = function (s) { return root.querySelector(s); };
  var resName = function () { return typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pickax_jobbuilder'; };
  var post = function (name, body) { try { fetch('https://' + resName() + '/' + name, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) }).catch(function () {}); } catch (e) {} };
  var clamp = function (x, a, b) { return Math.min(b, Math.max(a, x == null ? a : x)); };
  var esc = function (s) { return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); };

  var ACC = '#fdc27d', ACCRGB = '253,194,125';
  var S = null;            // session en cours
  var cv, g, W = 0, H = 0, DPR = 1;
  var ptr = { x: 0, y: 0, down: false, inside: false, vx: 0, vy: 0, t: 0 };
  var run = null;          // exécutant de l'étape en cours
  var raf = 0, last = 0;
  var ICO = {
    flask: '<path d="M9 3h6M10 3v6l-5 9a2 2 0 0 0 2 3h10a2 2 0 0 0 2-3l-5-9V3"/><path d="M8 15h8"/>',
    hand: '<path d="M8 13V6a1.5 1.5 0 0 1 3 0v5M11 11V4.5a1.5 1.5 0 0 1 3 0V11M14 11V6a1.5 1.5 0 0 1 3 0v8a6 6 0 0 1-6 6h-1a6 6 0 0 1-5-3l-2-4a1.5 1.5 0 0 1 2.5-1.5L8 14"/>',
    box: '<path d="M3 8l9-5 9 5v8l-9 5-9-5zM3 8l9 5 9-5M12 13v8"/>',
  };
  var svg = function (p, s) { return '<svg viewBox="0 0 24 24" width="' + (s || 16) + '" height="' + (s || 16) + '" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">' + p + '</svg>'; };

  /* ───────────── géométrie de la scène ───────────── */
  var geo = function () { var R = Math.min(W * 0.22, H * 0.30); return { cx: W * 0.5, cy: H * 0.47, R: R }; };

  /* ───────────── dessin des accessoires ───────────── */
  function metal(x, y, r, tilt) {
    var grd = g.createRadialGradient(x - r * 0.3, y - r * 0.4, r * 0.1, x, y, r * 1.05);
    grd.addColorStop(0, '#8b9197'); grd.addColorStop(0.6, '#4a5056'); grd.addColorStop(1, '#2b2f33');
    g.fillStyle = grd; g.beginPath(); g.ellipse(x, y, r, r * tilt, 0, 0, Math.PI * 2); g.fill();
  }
  function pot(x, y, r, fill, tilt) {
    tilt = tilt || 0.9;
    metal(x, y + r * 0.04, r * 1.06, tilt);
    g.fillStyle = '#0c0d10'; g.beginPath(); g.ellipse(x, y, r * 0.93, r * 0.93 * tilt, 0, 0, Math.PI * 2); g.fill();
    if (fill) { g.fillStyle = fill; g.beginPath(); g.ellipse(x, y, r * 0.8, r * 0.8 * tilt, 0, 0, Math.PI * 2); g.fill(); }
  }
  function bowl(x, y, r, level, col) {
    var grd = g.createRadialGradient(x - r * 0.3, y - r * 0.35, r * 0.1, x, y, r);
    grd.addColorStop(0, '#9a9a95'); grd.addColorStop(1, '#4b4b48');
    g.fillStyle = grd; g.beginPath(); g.ellipse(x, y, r, r * 0.82, 0, 0, Math.PI * 2); g.fill();
    g.fillStyle = '#2a2a28'; g.beginPath(); g.ellipse(x, y, r * 0.78, r * 0.62, 0, 0, Math.PI * 2); g.fill();
    if (level > 0) { g.fillStyle = col || '#7c9a4b'; g.beginPath(); g.ellipse(x, y + r * 0.05 * (1 - level), r * 0.7 * Math.min(1, 0.35 + level), r * 0.54 * Math.min(1, 0.35 + level), 0, 0, Math.PI * 2); g.fill(); }
  }
  function leaf(x, y, s, rot, col) {
    g.save(); g.translate(x, y); g.rotate(rot); g.fillStyle = col || '#4c7a34';
    g.beginPath(); g.moveTo(0, -s); g.quadraticCurveTo(s * 0.55, -s * 0.2, 0, s); g.quadraticCurveTo(-s * 0.55, -s * 0.2, 0, -s); g.fill();
    g.strokeStyle = 'rgba(255,255,255,.25)'; g.lineWidth = 1.2; g.beginPath(); g.moveTo(0, -s * 0.9); g.lineTo(0, s * 0.9); g.stroke(); g.restore();
  }
  function ring(x, y, r, col, dash) {
    g.save(); g.strokeStyle = col || 'rgba(255,255,255,.85)'; g.lineWidth = 2; g.setLineDash(dash || [9, 7]); g.lineDashOffset = -(performance.now() / 60) % 16;
    g.beginPath(); g.arc(x, y, r, 0, Math.PI * 2); g.stroke(); g.restore();
  }
  function tag(x, y, text, strong) {
    g.save(); g.font = '600 13px Geist, Inter, sans-serif'; var w = g.measureText(text).width + 22, h = 26;
    g.fillStyle = strong ? ACC : 'rgba(14,14,17,.92)';
    g.beginPath(); g.roundRect ? g.roundRect(x, y - h / 2, w, h, 8) : g.rect(x, y - h / 2, w, h); g.fill();
    g.fillStyle = strong ? '#15110a' : '#f1f1f4'; g.textBaseline = 'middle'; g.fillText(text, x + 11, y + 1); g.restore();
  }

  /* ───────────── étapes ───────────── */
  var mistakeCool = 0;
  function mistake(r, label) {
    var now = performance.now(); if (now < mistakeCool) return;
    mistakeCool = now + 650; r.mistakes++; r.warn = { t: now + 900, text: label || 'Doucement' };
  }

  var TYPES = {};

  // Ajouter : maintiens le clic au-dessus du bol pour y verser l'ingrédient
  TYPES.add = {
    init: function (st) { var gg = geo(); return { prog: 0, rate: 1 / Math.max(1.5, st.seconds || 5), tx: gg.cx, ty: gg.cy, tr: gg.R * 0.5, leaves: [] }; },
    tick: function (r, st, dt) {
      var over = Math.hypot(ptr.x - r.tx, ptr.y - r.ty) <= r.tr;
      r.holding = ptr.down && over;
      if (r.holding) { r.prog = Math.min(1, r.prog + r.rate * dt); if (Math.random() < dt * 14) r.leaves.push({ x: r.tx + (Math.random() - .5) * r.tr * 0.6, y: r.ty - r.tr * 1.2, v: 0, a: Math.random() * 6 }); }
      else if (ptr.down && !over && r.prog > 0 && r.prog < 1) mistake(r, 'Au-dessus du bol');
      r.leaves = r.leaves.filter(function (l) { l.v += 900 * dt; l.y += l.v * dt; return l.y < r.ty + r.tr * 0.2; });
      return r.prog;
    },
    draw: function (r, st) {
      bowl(r.tx, r.ty + r.tr * 0.1, r.tr * 1.25, r.prog, st.color);
      r.leaves.forEach(function (l) { leaf(l.x, l.y, 12, l.a, st.color); });
      ring(r.tx, r.ty, r.tr, r.holding ? ACC : null);
      leaf(ptr.x, ptr.y - 26, 22, -0.6 + (ptr.down ? 0.5 : 0), st.color); tag(r.tx + r.tr + 14, r.ty, 'Dépose ici');
    },
    count: function (r, st) { return Math.floor(r.prog * (st.amount || 10)) + ' / ' + (st.amount || 10); },
    pct: function (r) { return r.prog; },
  };

  // Gratter : racle toute la pâte au fond de la casserole, sans aller trop vite
  TYPES.scrape = {
    init: function (st) {
      var gg = geo(), c = document.createElement('canvas'); c.width = c.height = 256; var x = c.getContext('2d');
      x.fillStyle = st.color || '#e8ece8'; x.beginPath(); x.arc(128, 128, 120, 0, 6.3); x.fill();
      x.globalAlpha = .12; for (var i = 0; i < 70; i++) { x.fillStyle = '#fff'; x.beginPath(); x.arc(30 + Math.random() * 196, 30 + Math.random() * 196, 3 + Math.random() * 7, 0, 6.3); x.fill(); } x.globalAlpha = 1;
      return { paste: c, px: x, cov: 0, total: 0, sample: 0, lx: null, ly: null, cx: gg.cx, cy: gg.cy, R: gg.R * 0.72 };
    },
    tick: function (r, st, dt) {
      if (ptr.down) {
        var d = Math.hypot(ptr.x - r.cx, ptr.y - r.cy);
        if (d < r.R * 1.02) {
          var k = 240 / (r.R * 2), ax = (ptr.x - r.cx) * k + 128, ay = (ptr.y - r.cy) * k + 128;
          r.px.globalCompositeOperation = 'destination-out'; r.px.lineCap = 'round'; r.px.lineWidth = 30; r.px.beginPath();
          r.px.moveTo(r.lx == null ? ax : r.lx, r.ly == null ? ay : r.ly); r.px.lineTo(ax, ay); r.px.stroke(); r.px.globalCompositeOperation = 'source-over';
          r.lx = ax; r.ly = ay;
          var sp = Math.hypot(ptr.vx, ptr.vy); if (sp > (st.speedLimit || 1400)) mistake(r, 'Doucement');
        } else { r.lx = r.ly = null; }
      } else { r.lx = r.ly = null; }
      r.sample -= dt;
      if (r.sample <= 0) {
        r.sample = 0.12; var data = r.px.getImageData(0, 0, 256, 256).data, cnt = 0, n = 0;
        for (var y = 8; y < 256; y += 8) for (var xx = 8; xx < 256; xx += 8) { if (Math.hypot(xx - 128, y - 128) < 118) { n++; if (data[(y * 256 + xx) * 4 + 3] > 40) cnt++; } }
        if (!r.total) r.total = cnt || 1; r.cov = clamp(1 - cnt / r.total, 0, 1);
      }
      return clamp(r.cov / (st.coverage || 0.93), 0, 1);
    },
    draw: function (r, st) {
      pot(r.cx, r.cy, r.R * 1.18, null, 0.96);
      g.drawImage(r.paste, r.cx - r.R, r.cy - r.R, r.R * 2, r.R * 2);
      ring(r.cx, r.cy, r.R * 1.0); if (r.warn && performance.now() < r.warn.t) tag(r.cx + r.R * 0.62, r.cy - r.R * 0.4, r.warn.text, true);
      g.strokeStyle = 'rgba(255,255,255,.9)'; g.lineWidth = 3; g.beginPath(); g.arc(ptr.x, ptr.y, 9, 0, 6.3); g.stroke();
    },
    count: function (r) { return Math.round(r.cov * 100) + ' / 100 %'; },
    pct: function (r, st) { return clamp(r.cov / (st.coverage || 0.93), 0, 1); },
  };

  // Mélanger : tourne autour de la casserole sans aller trop vite
  TYPES.stir = {
    init: function (st) { var gg = geo(); return { cx: gg.cx, cy: gg.cy, R: gg.R * 0.8, a0: null, turns: 0, swirl: 0 }; },
    tick: function (r, st, dt) {
      var d = Math.hypot(ptr.x - r.cx, ptr.y - r.cy);
      if (ptr.down && d > r.R * 0.18 && d < r.R * 1.05) {
        var a = Math.atan2(ptr.y - r.cy, ptr.x - r.cx);
        if (r.a0 != null) {
          var da = a - r.a0; if (da > Math.PI) da -= 2 * Math.PI; if (da < -Math.PI) da += 2 * Math.PI;
          if (Math.abs(da) / Math.max(dt, 0.001) > 14) mistake(r, 'Trop vite'); else r.turns += Math.abs(da) / (2 * Math.PI);
          r.swirl += da;
        }
        r.a0 = a;
      } else r.a0 = null;
      return clamp(r.turns / (st.turns || 6), 0, 1);
    },
    draw: function (r, st) {
      pot(r.cx, r.cy, r.R * 1.2, st.color || '#8a7a3b', 0.96);
      g.save(); g.translate(r.cx, r.cy); g.rotate(r.swirl); g.strokeStyle = 'rgba(255,255,255,.22)'; g.lineWidth = 6; g.lineCap = 'round';
      for (var i = 0; i < 3; i++) { g.beginPath(); g.arc(0, 0, r.R * (0.3 + i * 0.22), 0.4, 2.2); g.stroke(); } g.restore();
      ring(r.cx, r.cy, r.R * 0.95);
      if (ptr.down) { g.strokeStyle = '#d8d0c0'; g.lineWidth = 8; g.lineCap = 'round'; g.beginPath(); g.moveTo(ptr.x + 60, ptr.y - 110); g.lineTo(ptr.x, ptr.y); g.stroke(); }
      if (r.warn && performance.now() < r.warn.t) tag(r.cx + r.R * 0.7, r.cy - r.R * 0.5, r.warn.text, true);
    },
    count: function (r, st) { return Math.floor(r.turns) + ' / ' + (st.turns || 6) + ' tours'; },
    pct: function (r, st) { return clamp(r.turns / (st.turns || 6), 0, 1); },
  };

  // Chauffer : garde la température dans la zone verte (clic = chauffer, relâcher = refroidir)
  TYPES.heat = {
    init: function (st) { var gg = geo(); return { cx: gg.cx, cy: gg.cy, R: gg.R, temp: 0.1, ok: 0, lo: st.low || 0.45, hi: st.high || 0.7 }; },
    tick: function (r, st, dt) {
      r.temp = clamp(r.temp + (ptr.down ? 0.35 : -0.28) * dt, 0, 1);
      if (r.temp >= r.lo && r.temp <= r.hi) r.ok += dt;
      else if (r.temp > 0.96) { mistake(r, 'Trop chaud'); r.ok = Math.max(0, r.ok - 0.6); }
      return clamp(r.ok / (st.hold || 6), 0, 1);
    },
    draw: function (r, st) {
      pot(r.cx, r.cy, r.R * 0.85, st.color || '#7a5a2a', 0.96);
      var x = r.cx + r.R * 1.2, y0 = r.cy - r.R * 0.8, h = r.R * 1.6;
      g.fillStyle = 'rgba(14,14,17,.92)'; g.fillRect(x - 16, y0, 32, h);
      g.fillStyle = 'rgba(61,214,140,.35)'; g.fillRect(x - 16, y0 + h * (1 - r.hi), 32, h * (r.hi - r.lo));
      var inz = r.temp >= r.lo && r.temp <= r.hi;
      g.fillStyle = inz ? '#3dd68c' : (r.temp > r.hi ? '#f0654f' : '#9aa0a8'); g.fillRect(x - 10, y0 + h * (1 - r.temp), 20, h * r.temp);
      g.strokeStyle = 'rgba(255,255,255,.4)'; g.strokeRect(x - 16.5, y0 - .5, 33, h + 1);
      tag(x + 28, y0 + h * (1 - (r.lo + r.hi) / 2), 'Zone idéale');
      if (r.warn && performance.now() < r.warn.t) tag(r.cx - 40, r.cy - r.R, r.warn.text, true);
      var gl = r.temp * 0.6; g.fillStyle = 'rgba(255,140,40,' + gl + ')'; g.beginPath(); g.ellipse(r.cx, r.cy + r.R * 0.9, r.R * 0.7, r.R * 0.1, 0, 0, 6.3); g.fill();
    },
    count: function (r, st) { return r.ok.toFixed(1) + ' / ' + (st.hold || 6) + ' s'; },
    pct: function (r, st) { return clamp(r.ok / (st.hold || 6), 0, 1); },
  };

  // Transvaser : attrape chaque bol et verse-le dans sa casserole
  TYPES.pour = {
    init: function (st) {
      var gg = geo(), n = st.bowls || 2, R = gg.R, items = [];
      for (var i = 0; i < n; i++) {
        var side = i % 2 === 0 ? -1 : 1, row = Math.floor(i / 2);
        items.push({ potX: gg.cx + side * R * 0.62, potY: gg.cy - R * 0.15 - row * R * 0.2, bx: gg.cx + side * R * 1.45, by: gg.cy + R * 0.62, x: 0, y: 0, fill: 1, done: false, pour: 0 });
        items[i].x = items[i].bx; items[i].y = items[i].by;
      }
      return { items: items, cur: 0, drag: false, R: R };
    },
    tick: function (r, st, dt) {
      var it = r.items[r.cur]; if (!it) return 1;
      var rad = r.R * 0.42;
      if (ptr.down && !r.drag && Math.hypot(ptr.x - it.x, ptr.y - it.y) < rad) r.drag = true;
      if (r.drag) {
        if (ptr.down) { it.x = ptr.x; it.y = ptr.y; }
        var over = Math.hypot(it.x - it.potX, it.y - (it.potY - r.R * 0.3)) < r.R * 0.55;
        if (ptr.down && over) { it.pour = Math.min(1, it.pour + dt / (st.seconds || 3)); it.fill = 1 - it.pour; }
        if (!ptr.down) { r.drag = false; if (it.pour < 1) { if (!over) mistake(r, 'Au-dessus de la casserole'); it.x = it.bx; it.y = it.by; } }
        if (it.pour >= 1) { it.done = true; r.drag = false; it.x = it.bx; it.y = it.by; r.cur++; }
      }
      var tot = 0; r.items.forEach(function (i) { tot += i.done ? 1 : i.pour; });
      return tot / r.items.length;
    },
    draw: function (r, st) {
      r.items.forEach(function (it, i) {
        pot(it.potX, it.potY, r.R * 0.55, it.done || it.pour > 0 ? (st.color || '#8a7a3b') : null, 0.92);
      });
      r.items.forEach(function (it, i) {
        bowl(it.x, it.y, r.R * 0.4, it.done ? 0 : it.fill, st.color || '#8a7a3b');
        if (i === r.cur && !r.drag) { ring(it.x, it.y, r.R * 0.44, ACC); tag(it.x + (it.bx > geo().cx ? -r.R * 0.5 - 130 : r.R * 0.5), it.y, 'Attrape le bol', true); }
        if (i === r.cur) { var tx = it.potX, ty = it.potY - r.R * 0.3; ring(tx, ty, r.R * 0.5); if (r.drag) tag(tx + r.R * 0.55, ty, 'Verse ici'); }
      });
      if (r.warn && performance.now() < r.warn.t) tag(geo().cx - 60, geo().cy - r.R * 0.95, r.warn.text, true);
    },
    count: function (r) { var d = r.items.filter(function (i) { return i.done; }).length; return d + ' / ' + r.items.length + ' bols'; },
    pct: function (r) { var t = 0; r.items.forEach(function (i) { t += i.done ? 1 : i.pour; }); return t / r.items.length; },
  };

  // Cadence : clique quand le curseur est dans la zone
  TYPES.timing = {
    init: function (st) { var gg = geo(); return { x: 0.05, dir: 1, hits: 0, speed: st.speed || 0.7, zlo: 0.42, zhi: 0.58, w: gg.R * 2.2, cx: gg.cx, cy: gg.cy, flash: 0, wasDown: false }; },
    tick: function (r, st, dt) {
      r.x += r.dir * r.speed * dt; if (r.x > 1) { r.x = 1; r.dir = -1; } if (r.x < 0) { r.x = 0; r.dir = 1; }
      while (ptr.clicks > 0) {      // chaque clic compte, même très bref
        ptr.clicks--;
        if (r.x >= r.zlo && r.x <= r.zhi) { r.hits++; r.flash = 0.35; r.speed *= 1.08; var hw = Math.max(0.05, (r.zhi - r.zlo) / 2 * 0.9); r.zlo = clamp(Math.random() * (1 - 2 * hw), 0, 1 - 2 * hw); r.zhi = r.zlo + 2 * hw; }
        else mistake(r, 'Raté');
      }
      r.wasDown = ptr.down; r.flash = Math.max(0, r.flash - dt);
      return clamp(r.hits / (st.hits || 5), 0, 1);
    },
    draw: function (r, st) {
      var x0 = r.cx - r.w / 2, y = r.cy, h = 22;
      g.fillStyle = 'rgba(14,14,17,.92)'; g.beginPath(); g.roundRect ? g.roundRect(x0 - 8, y - h, r.w + 16, h * 2, 12) : g.rect(x0 - 8, y - h, r.w + 16, h * 2); g.fill();
      g.fillStyle = 'rgba(61,214,140,.45)'; g.fillRect(x0 + r.w * r.zlo, y - h + 6, r.w * (r.zhi - r.zlo), h * 2 - 12);
      g.fillStyle = r.flash > 0 ? '#3dd68c' : '#f4f4f5'; g.fillRect(x0 + r.w * r.x - 3, y - h - 6, 6, h * 2 + 12);
      if (r.warn && performance.now() < r.warn.t) tag(r.cx - 30, y - 56, r.warn.text, true);
    },
    count: function (r, st) { return r.hits + ' / ' + (st.hits || 5); },
    pct: function (r, st) { return clamp(r.hits / (st.hits || 5), 0, 1); },
  };

  /* ───────────── moteur ───────────── */
  function resize() {
    DPR = window.devicePixelRatio || 1; W = window.innerWidth; H = window.innerHeight;
    cv.width = W * DPR; cv.height = H * DPR; cv.style.width = W + 'px'; cv.style.height = H + 'px'; g.setTransform(DPR, 0, 0, DPR, 0, 0);
  }

  function buildHud() {
    var colA = getComputedStyle(document.documentElement).getPropertyValue('--pk-accent') || '#fdc27d';
    var rgb = getComputedStyle(document.documentElement).getPropertyValue('--pk-accent-rgb') || '253,194,125';
    ACC = (colA.trim() || '#fdc27d'); ACCRGB = (rgb.trim() || '253,194,125');
    root.style.setProperty('--lx-acc', ACC); root.style.setProperty('--lx-acc-rgb', ACCRGB);
    var inv = (S.inventory || []).map(function (i, k) {
      var img = i.icon ? '<img src="https://cfx-nui-ox_inventory/web/images/' + esc(i.icon) + '.png" onerror="this.remove()">' : '';
      return '<div class="lx-item"><span class="ic">' + img + svg(ICO.box, 18) + '</span><span class="nm">' + esc(i.label) + '<small>' + esc(i.sub || '') + '</small></span><b>' + esc(i.count) + '</b></div>';
    }).join('');
    root.innerHTML =
      '<canvas id="lx-c"></canvas>' +
      '<div class="lx-top"><div class="lx-badge">' + svg(ICO.flask, 14) + '<span>' + esc(S.lab || 'Laboratoire') + ' · ' + esc(S.title || '') + '</span></div>' +
      '<div class="lx-stepno"></div><h1 class="lx-title"></h1><div class="lx-pills"></div></div>' +
      (inv ? '<div class="lx-inv"><div class="lx-invh">Inventaire</div>' + inv + '</div>' : '') +
      '<div class="lx-card"><div class="lx-hint">' + svg(ICO.hand, 15) + '<span></span></div><div class="lx-body"><div class="lx-count"></div><div class="lx-bar"><i></i></div><small class="lx-pct"></small></div></div>' +
      '<div class="lx-quit"><kbd>Échap</kbd> Quitter</div><div class="lx-done hidden"></div>';
    cv = $('#lx-c'); g = cv.getContext('2d'); resize();
    cv.addEventListener('pointerdown', function (e) { ptr.down = true; ptr.clicks = (ptr.clicks || 0) + 1; mv(e); try { cv.setPointerCapture(e.pointerId); } catch (x) {} });
    cv.addEventListener('pointerup', function () { ptr.down = false; });
    cv.addEventListener('pointercancel', function () { ptr.down = false; });
    cv.addEventListener('pointermove', mv);
    cv.addEventListener('contextmenu', function (e) { e.preventDefault(); });
  }
  function mv(e) {
    var t = performance.now(), dt = Math.max(1, t - ptr.t);
    ptr.vx = (e.clientX - ptr.x) / dt * 1000; ptr.vy = (e.clientY - ptr.y) / dt * 1000; ptr.x = e.clientX; ptr.y = e.clientY; ptr.t = t;
  }

  function pills() {
    var el = $('.lx-pills'); if (!el) return;
    el.innerHTML = S.steps.map(function (st, i) {
      var cls = i < S.idx ? 'done' : (i === S.idx ? 'cur' : '');
      return '<span class="p ' + cls + '">' + (i === S.idx ? '<b>' + (i + 1) + '</b> ' + esc(st.label || st.type) : (i + 1)) + '</span>';
    }).join('');
  }

  function begin(i) {
    S.idx = i; var st = S.steps[i]; var T = TYPES[st.type] || TYPES.timing;
    run = T.init(st); run.mistakes = 0; run.T = T; run.st = st; run.t0 = performance.now(); run.finished = false; mistakeCool = 0; ptr.clicks = 0;
    $('.lx-stepno').textContent = 'Étape ' + (i + 1) + ' / ' + S.steps.length;
    $('.lx-title').textContent = st.title || '';
    $('.lx-hint span').textContent = st.hint || '';
    pills();
  }

  function finishStep() {
    run.finished = true;
    var ms = Math.round(performance.now() - run.t0), score = clamp(1 - run.mistakes * 0.12, 0.3, 1);
    S.results.push({ ok: true, score: Math.round(score * 100) / 100, ms: ms });
    root.classList.add('flash'); setTimeout(function () { root.classList.remove('flash'); }, 380);
    setTimeout(function () {
      if (!S) return;
      if (S.idx + 1 < S.steps.length) begin(S.idx + 1); else complete();
    }, 650);
  }

  function complete() {
    var q = S.results.reduce(function (a, r) { return a + r.score; }, 0) / Math.max(1, S.results.length);
    var d = $('.lx-done'); d.classList.remove('hidden');
    d.innerHTML = '<div class="ok">' + svg('<path d="M5 12l5 5 9-10"/>', 26) + '</div><h2>Fabrication terminée</h2><p>Qualité du produit : <b>' + Math.round(q * 100) + ' %</b></p>';
    var results = S.results; cancelAnimationFrame(raf);
    setTimeout(function () { var s = S; close(false); post('labxDone', { results: results }); }, 1600);
  }

  function loop(t) {
    raf = requestAnimationFrame(loop);
    if (!S || !run) return;
    var dt = Math.min(0.05, (t - last) / 1000 || 0.016); last = t;
    g.clearRect(0, 0, W, H);
    var wasDown = ptr.down; if (performance.now() - run.t0 < 450) ptr.down = false;      // le clic maintenu de l'étape précédente est ignoré un instant
    var p = run.finished ? 1 : run.T.tick(run, run.st, dt);
    ptr.down = wasDown;
    run.T.draw(run, run.st);
    var c = $('.lx-count'), b = $('.lx-bar i'), pc = $('.lx-pct');
    if (c) { c.innerHTML = run.T.count(run, run.st).replace(/^(\S+)(.*)$/, '<b>$1</b><span>$2</span>'); b.style.width = Math.round(p * 100) + '%'; pc.textContent = Math.round(p * 100) + ' %'; }
    if (!run.finished && p >= 1) finishStep();
  }

  function start(session) {
    close(true);
    S = session; S.idx = 0; S.results = [];
    root.classList.remove('hidden'); buildHud(); begin(0);
    last = performance.now(); cancelAnimationFrame(raf); raf = requestAnimationFrame(loop);
  }
  function close(silent) {
    cancelAnimationFrame(raf); S = null; run = null; ptr.down = false;
    root.classList.add('hidden'); root.innerHTML = '';
  }
  function abort() { if (!S) return; close(); post('labxAbort', {}); }

  window.addEventListener('keydown', function (e) { if (S && e.key === 'Escape') { e.preventDefault(); abort(); } });
  window.addEventListener('resize', function () { if (cv && S && run) { resize(); begin(S.idx); } });
  window.addEventListener('message', function (e) {
    var d = e.data || {}; if (d.action !== 'labx') return;
    if (d.cmd === 'start' && d.session && Array.isArray(d.session.steps) && d.session.steps.length) start(d.session);
    else if (d.cmd === 'abort') close();
  });
  window.LabX = { dbg: function () { return run; }, start: start, abort: abort, state: function () { return S && { idx: S.idx, results: S.results.slice() }; }, geo: geo };
})();
