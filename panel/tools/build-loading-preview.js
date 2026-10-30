// Régénère panel/public/preview-loading/ à partir de l'écran de chargement réel (resources/[script]/pickax_core/loading)
// pour que l'aperçu du panel soit identique à ce que voit un joueur. À relancer si l'écran de chargement change : node tools/build-loading-preview.js
const fs = require('fs'), path = require('path');
const SRC = path.join(__dirname, '..', '..', 'resources', '[script]', 'pickax_core', 'loading'), DST = path.join(__dirname, '..', 'public', 'preview-loading');
fs.mkdirSync(path.join(DST, 'fonts'), { recursive: true });
let html = fs.readFileSync(path.join(SRC, 'index.html'), 'utf8');
html = html.replace(/<script src="theme\.js"><\/script>\s*/, '').replace(/<link rel="stylesheet" href="https:\/\/cdnjs[^>]*>\s*/, '')
  .replace(/<script src="index\.js" defer><\/script>\s*/, '').replace('<script src="ui.js" defer></script>', '<script src="stub.js"></script>\n    <script src="ui.js" defer></script>\n    <script src="preview.js" defer></script>')
  .replace(/<!-- CONTROLE MUSIQUE -->[\s\S]*?<\/script>/, '').replace(/<audio[^>]*><\/audio>/, '');
fs.writeFileSync(path.join(DST, 'index.html'), html);
let css = fs.readFileSync(path.join(SRC, 'style.css'), 'utf8').replace(/@import url\([^)]*\);?/, [500, 600, 700, 800].map(w => `@font-face{font-family:'Montserrat';font-weight:${w};src:url('fonts/montserrat-${w}.woff2') format('woff2');font-display:swap}`).join('\n'));
fs.writeFileSync(path.join(DST, 'style.css'), css);
for (const f of ['ui.js', 'background.jpg']) fs.copyFileSync(path.join(SRC, f), path.join(DST, f));
// remplace le logo / les éléments qui dépendent du jeu
fs.writeFileSync(path.join(DST, 'stub.js'), "var play = false; var myAudio = { volume: .1, src: '', pause: function () {}, play: function () { return { catch: function () {} }; } }; function toggleMusic() {}\n");
fs.writeFileSync(path.join(DST, 'preview.js'), `// Aperçu : couleur et nom envoyés par le panel (localStorage de la même origine), barre figée à 62 %
(function () {
  var A = {}; try { A = JSON.parse(localStorage.getItem('pickax_preview_theme') || '{}'); } catch (e) {}
  var hex = /^#[0-9a-f]{6}$/i.test(A.accent || '') ? A.accent : '#fdc27d', rgb = [1, 3, 5].map(function (i) { return parseInt(hex.slice(i, i + 2), 16); });
  var mix = function (to, t) { return '#' + rgb.map(function (v) { var n = Math.round(v + (to - v) * t); return (n < 16 ? '0' : '') + n.toString(16); }).join(''); };
  var s = document.documentElement.style; s.setProperty('--pk-accent', hex); s.setProperty('--pk-accent-rgb', rgb.join(',')); s.setProperty('--pk-accent-light', mix(255, .14)); s.setProperty('--pk-accent-dark', mix(0, .28));
  var set = function (id, w) { var e = document.getElementById(id); if (e) e.style.width = w + '%'; };
  set('INIT_BEFORE_MAP_LOADED-bar', 14.9); set('MAP-bar', 39.6); set('INIT_AFTER_MAP_LOADED-bar', 7.2); set('INIT_SESSION-bar', 0);
})();
`);
console.log('aperçu régénéré');
