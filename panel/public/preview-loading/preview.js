// Aperçu : couleur et nom envoyés par le panel (localStorage de la même origine), barre figée à 62 %
(function () {
  var A = {}; try { A = JSON.parse(localStorage.getItem('pickax_preview_theme') || '{}'); } catch (e) {}
  var hex = /^#[0-9a-f]{6}$/i.test(A.accent || '') ? A.accent : '#fdc27d', rgb = [1, 3, 5].map(function (i) { return parseInt(hex.slice(i, i + 2), 16); });
  var mix = function (to, t) { return '#' + rgb.map(function (v) { var n = Math.round(v + (to - v) * t); return (n < 16 ? '0' : '') + n.toString(16); }).join(''); };
  var s = document.documentElement.style; s.setProperty('--pk-accent', hex); s.setProperty('--pk-accent-rgb', rgb.join(',')); s.setProperty('--pk-accent-light', mix(255, .14)); s.setProperty('--pk-accent-dark', mix(0, .28));
  var set = function (id, w) { var e = document.getElementById(id); if (e) e.style.width = w + '%'; };
  set('INIT_BEFORE_MAP_LOADED-bar', 14.9); set('MAP-bar', 39.6); set('INIT_AFTER_MAP_LOADED-bar', 7.2); set('INIT_SESSION-bar', 0);
})();
