/* Style « Atelier » : palette sombre dérivée de la couleur du serveur + tuiles d'icônes colorées. Actif par défaut ; bouton « Style » pour revenir à l'ancien. */
(function () {
  const KEY = 'bb.atelier';
  const on = () => { try { return localStorage.getItem(KEY) !== '0'; } catch (e) { return true; } };
  const root = document.documentElement;
  const hsl = (r, g, b) => { r /= 255; g /= 255; b /= 255; const M = Math.max(r, g, b), m = Math.min(r, g, b); let h = 0; if (M !== m) { const d = M - m; h = M === r ? (g - b) / d + (g < b ? 6 : 0) : M === g ? (b - r) / d + 2 : (r - g) / d + 4; h *= 60; } return h; };
  const hex = (h, s, l) => { s /= 100; l /= 100; const a = s * Math.min(l, 1 - l), f = n => { const k = (n + h / 30) % 12; return Math.round(255 * (l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1)))).toString(16).padStart(2, '0'); }; return '#' + f(0) + f(8) + f(4); };
  function palette() {
    const cs = getComputedStyle(root);
    let raw = (cs.getPropertyValue('--accent-rgb') || cs.getPropertyValue('--acc-rgb') || cs.getPropertyValue('--pk-accent-rgb') || '0,164,255').split(',').map(x => parseInt(x, 10));
    if (raw.length < 3 || raw.some(isNaN)) raw = [0, 164, 255];
    const [r, g, b] = raw, h = hsl(r, g, b), st = root.style, key = raw.join(',');
    if (palette.last === key) return; palette.last = key;
    st.setProperty('--atl-rgb', `${r}, ${g}, ${b}`);
    st.setProperty('--atl-hex', `rgb(${r}, ${g}, ${b})`);
    st.setProperty('--atl-on', (0.299 * r + 0.587 * g + 0.114 * b) / 255 > 0.62 ? '#16171c' : '#ffffff');
    [['bg', 5], ['p1', 8], ['p2', 11], ['p3', 14]].forEach(x => st.setProperty('--atl-' + x[0], hex(h, 16, x[1])));
    st.setProperty('--atl-ln', 'rgba(255,255,255,.07)'); st.setProperty('--atl-ln2', 'rgba(255,255,255,.13)');
  }
  /* couleur par type d'icône (nom lu dans la table d'icônes P/IC du builder ; repli : teinte stable selon le dessin) */
  const COL = { shield: '#3b82f6', heart: '#ef4444', cross: '#ef4444', wrench: '#f97316', tools: '#f97316', car: '#eab308', truck: '#f59e0b', home: '#14b8a6', building: '#14b8a6', store: '#22c55e', landmark: '#22c55e', utensils: '#b45309', briefcase: '#6366f1', users: '#8b5cf6', user: '#64748b', key: '#eab308', siren: '#ef4444', route: '#22c55e', fuel: '#e11d48', map: '#0ea5e9', pin: '#0ea5e9', box: '#a16207', gift: '#ec4899', trophy: '#eab308', flag: '#22c55e', clock: '#64748b', crown: '#eab308', skull: '#a3a3a3', bike: '#f97316', plane: '#0ea5e9', ship: '#0ea5e9', boat: '#0ea5e9', shirt: '#8b5cf6', target: '#ef4444', cart: '#f97316', tag: '#ec4899', sprout: '#22c55e', leaf: '#22c55e', droplet: '#0ea5e9', drop: '#0ea5e9', phone: '#22c55e', megaphone: '#f97316', tablet: '#6366f1', file: '#64748b', list: '#64748b', link: '#64748b', search: '#0ea5e9', plus: '#22c55e', lock: '#64748b', dollar: '#22c55e', coins: '#eab308', percent: '#ec4899', bell: '#eab308', edit: '#0ea5e9', zap: '#eab308', bolt: '#eab308', eye: '#8b5cf6', chart: '#0ea5e9', flask: '#a855f7', mask: '#a3a3a3', diamond: '#06b6d4', book: '#b45309', card: '#6366f1', chat: '#0ea5e9', settings: '#64748b', sliders: '#64748b', folder: '#eab308', login: '#22c55e', logout: '#ef4444', basket: '#f97316', football: '#22c55e', tennis: '#a3e635', boxing: '#ef4444', paintball: '#ec4899', laser: '#ef4444', bowling: '#8b5cf6', darts: '#ef4444', brawl: '#f97316', padel: '#0ea5e9', volley: '#eab308', kart: '#ef4444', moto: '#f97316', quad: '#84cc16', drag: '#ef4444', parkour: '#14b8a6', go: '#22c55e', grid: '#64748b', refresh: '#0ea5e9', copy: '#64748b', stop: '#ef4444', minus: '#ef4444', up: '#64748b', down: '#64748b', check: '#22c55e' };
  /* vraies icônes en couleur (émojis du système) à la place des pictogrammes au trait, dans les tuiles du style Atelier */
  const EMO = { shield: '👮', heart: '🚑', cross: '🏥', wrench: '🔧', tools: '🛠️', car: '🚗', truck: '🚚', home: '🏠', building: '🏢', store: '🏪', landmark: '🏛️', utensils: '🍸', briefcase: '💼', users: '👥', user: '👤', key: '🔑', siren: '🚨', route: '🧭', fuel: '⛽', map: '🗺️', pin: '📍', box: '📦', gift: '🎁', trophy: '🏆', flag: '🚩', clock: '⏱️', crown: '👑', skull: '💀', bike: '🏍️', plane: '✈️', ship: '🚢', boat: '⛵', shirt: '👕', target: '🎯', cart: '🛒', tag: '🏷️', sprout: '🌱', leaf: '🍃', droplet: '💧', drop: '💧', phone: '📱', megaphone: '📣', tablet: '📋', file: '🧾', list: '📝', link: '⛓️', search: '🔎', plus: '➕', lock: '🔒', dollar: '💵', coins: '🪙', percent: '💯', bell: '🔔', edit: '✏️', zap: '⚡', bolt: '⚡', eye: '👁️', chart: '📊', flask: '🧪', mask: '🎭', diamond: '💎', book: '📖', card: '💳', chat: '💬', settings: '⚙️', sliders: '🎚️', folder: '📁', login: '🚪', logout: '🚪', basket: '🏀', football: '⚽', tennis: '🎾', boxing: '🥊', paintball: '🔫', laser: '🔦', bowling: '🎳', darts: '🎯', brawl: '👊', padel: '🏓', volley: '🏐', kart: '🏎️', moto: '🏍️', quad: '🛻', drag: '🏁', parkour: '🧗', go: '▶️', refresh: '🔄', copy: '📄', stop: '⏹️', minus: '➖', check: '✅' };
  const FALL = ['#3b82f6', '#ef4444', '#f97316', '#eab308', '#14b8a6', '#22c55e', '#6366f1', '#8b5cf6', '#ec4899', '#0ea5e9'];
  const shade = (h, k) => { const f = i => Math.max(0, Math.min(255, Math.round(parseInt(h.slice(i, i + 2), 16) * k))); return `rgb(${f(1)},${f(3)},${f(5)})`; };
  let rev = null;
  function reverse() {
    rev = {};
    let T = null; try { T = (typeof P !== 'undefined') ? P : (typeof IC !== 'undefined' ? IC : null); } catch (e) {}
    if (T) { const tmp = document.createElementNS('http://www.w3.org/2000/svg', 'svg'); Object.keys(T).forEach(k => { tmp.innerHTML = T[k]; rev[tmp.innerHTML] = k; }); }
  }
  const rgbOf = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16)).join(',');
  function paint(t) {
    if (t.dataset.atl) return;
    const s = t.querySelector('svg'); if (!s) return;
    if (!rev) reverse();
    const m = s.innerHTML, name = rev[m];
    let c = COL[name];
    if (!c) { let h = 0; for (let i = 0; i < m.length; i++) h = (h * 31 + m.charCodeAt(i)) >>> 0; c = FALL[h % FALL.length]; }
    t.style.setProperty('--tc-a', shade(c, 1.2)); t.style.setProperty('--tc-b', shade(c, .72)); t.style.setProperty('--tc-rgb', rgbOf(c));
    t.dataset.atl = '1';
    if (EMO[name]) { t.dataset.emo = EMO[name]; t.__svg = s.outerHTML; }
  }
  /* émoji (style Atelier actif) ou pictogramme d'origine (ancien style) */
  function skin(t) {
    if (!t.dataset.emo) return;
    const want = document.body.classList.contains('atl');
    const cur = t.querySelector('.emo');
    if (want && !cur) { const w = t.offsetWidth || 44; t.innerHTML = '<span class="emo" style="font-size:' + Math.round(w * .56) + 'px">' + t.dataset.emo + '</span>'; }
    else if (!want && cur && t.__svg) t.innerHTML = t.__svg;
  }
  function sweep() { document.querySelectorAll('.tile:not([data-atl])').forEach(paint); document.querySelectorAll('.tile[data-emo]').forEach(skin); sw(); }
  function sw() {
    if (document.querySelector('.atl-sw')) return;
    const acts = document.querySelector('.head .acts'); if (!acts) return;
    const b = document.createElement('button'); b.className = 'sm atl-sw'; b.title = "Basculer entre le style Atelier et l'ancien style";
    b.textContent = 'Style'; b.addEventListener('click', e => { e.stopPropagation(); e.preventDefault(); try { localStorage.setItem(KEY, on() ? '0' : '1'); } catch (x) {} apply(); }, true);
    acts.insertBefore(b, acts.firstChild);
  }
  function apply() { palette(); document.body.classList.toggle('atl', on() && !document.body.classList.contains('neon')); document.querySelectorAll('.tile[data-emo]').forEach(skin); }
  function init() {
    apply(); sweep();
    new MutationObserver(() => { sweep(); }).observe(document.body, { childList: true, subtree: true });
    new MutationObserver(apply).observe(document.body, { attributes: true, attributeFilter: ['class'] });
    new MutationObserver(palette).observe(root, { attributes: true, attributeFilter: ['style'] });
    setTimeout(apply, 600); setTimeout(apply, 2000);
  }
  if (document.body) init(); else document.addEventListener('DOMContentLoaded', init);
})();
