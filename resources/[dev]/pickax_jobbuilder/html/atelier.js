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
  /* couleur par type d'icône (nom lu dans la table d'icônes P du builder ; repli : teinte stable selon le dessin) */
  const COL = { shield: '#3b82f6', heart: '#ef4444', wrench: '#f97316', car: '#eab308', home: '#14b8a6', landmark: '#22c55e', utensils: '#b45309', briefcase: '#6366f1', users: '#8b5cf6', user: '#64748b', key: '#eab308', siren: '#ef4444', route: '#22c55e', fuel: '#e11d48', map: '#0ea5e9', pin: '#0ea5e9', box: '#a16207', gift: '#ec4899', trophy: '#eab308', flag: '#22c55e', clock: '#64748b' };
  const FALL = ['#3b82f6', '#ef4444', '#f97316', '#eab308', '#14b8a6', '#22c55e', '#6366f1', '#8b5cf6', '#ec4899', '#0ea5e9'];
  const shade = (h, k) => { const f = i => Math.max(0, Math.min(255, Math.round(parseInt(h.slice(i, i + 2), 16) * k))); return `rgb(${f(1)},${f(3)},${f(5)})`; };
  let rev = null;
  function reverse() {
    rev = {};
    let T = null; try { T = (typeof P !== 'undefined') ? P : (typeof IC !== 'undefined' ? IC : null); } catch (e) {}
    if (T) { const tmp = document.createElementNS('http://www.w3.org/2000/svg', 'svg'); Object.keys(T).forEach(k => { tmp.innerHTML = T[k]; rev[tmp.innerHTML] = k; }); }
  }
  function paint(t) {
    if (t.dataset.atl) return;
    const s = t.querySelector('svg'); if (!s) return;
    if (!rev) reverse();
    const m = s.innerHTML, name = rev[m];
    let c = COL[name];
    if (!c) { let h = 0; for (let i = 0; i < m.length; i++) h = (h * 31 + m.charCodeAt(i)) >>> 0; c = FALL[h % FALL.length]; }
    t.style.setProperty('--tc-a', shade(c, 1.35)); t.style.setProperty('--tc-b', shade(c, .72)); t.style.setProperty('--tc-rgb', [1, 3, 5].map(i => parseInt(c.slice(i, i + 2), 16)).join(',')); t.dataset.atl = '1';
  }
  function sweep() { document.querySelectorAll('.tile:not([data-atl])').forEach(paint); sw(); }
  function sw() {
    if (document.querySelector('.atl-sw')) return;
    const acts = document.querySelector('.head .acts'); if (!acts) return;
    const b = document.createElement('button'); b.className = 'sm atl-sw'; b.title = "Basculer entre le style Atelier et l'ancien style";
    b.textContent = 'Style'; b.addEventListener('click', e => { e.stopPropagation(); e.preventDefault(); try { localStorage.setItem(KEY, on() ? '0' : '1'); } catch (x) {} apply(); }, true);
    acts.insertBefore(b, acts.firstChild);
  }
  function apply() { palette(); document.body.classList.toggle('atl', on() && !document.body.classList.contains('neon')); }
  function init() {
    apply(); sweep();
    new MutationObserver(() => { sweep(); }).observe(document.body, { childList: true, subtree: true });
    new MutationObserver(apply).observe(document.body, { attributes: true, attributeFilter: ['class'] });
    new MutationObserver(palette).observe(root, { attributes: true, attributeFilter: ['style'] });
    setTimeout(apply, 600); setTimeout(apply, 2000);
  }
  if (document.body) init(); else document.addEventListener('DOMContentLoaded', init);
})();
