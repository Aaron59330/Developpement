/* ═══════════════════════════════════════════════════════════════════════════════
   PICKAX — THÈME GÉNÉRAL
   ───────────────────────────────────────────────────────────────────────────────
   Le réglage principal est Config.AccentColor dans pickax_core/config.lua (la ligne ci-dessous n'est qu'une valeur de secours,
   utilisée si le fichier du core est illisible).  Change la couleur dans l'un ou l'autre : elle s'applique à toutes les interfaces
   (HUD, menus, notifications, builders, tablette, pause, CarPlay, menu contextuel…)
   sans ouvrir aucun autre script.

   Après modification : `restart pickax_theme`, puis relance les ressources dont tu veux
   voir le changement tout de suite (ou reconnecte-toi).  Format : #RRGGBB
   ═══════════════════════════════════════════════════════════════════════════════ */

window.PICKAX_ACCENT = '#00a4ff';        // ← couleur de secours (la valeur de Config.AccentColor dans pickax_core/config.lua a la priorité)

/* ─────────────────────────── ne rien modifier sous cette ligne ─────────────────────────── */
(function () {
  var KEY = 'pickax_theme_accent';
  var ok = function (h) { return /^#[0-9a-f]{6}$/i.test(String(h || '')); };
  var apply = function (hex) {
    var rgb = [1, 3, 5].map(function (i) { return parseInt(hex.slice(i, i + 2), 16); });
    var mix = function (to, t) {
      return '#' + rgb.map(function (v) { var n = Math.round(v + (to - v) * t); return (n < 16 ? '0' : '') + n.toString(16); }).join('');
    };
    window.PICKAX_ACCENT = hex;
    window.PICKAX_ACCENT_RGB = rgb.join(',');
    window.PICKAX_ACCENT_LIGHT = mix(255, 0.14);   // survol / dégradé clair
    window.PICKAX_ACCENT_DARK = mix(0, 0.28);      // dégradé foncé
    var s = document.documentElement.style;
    s.setProperty('--pk-accent', hex);
    s.setProperty('--pk-accent-rgb', window.PICKAX_ACCENT_RGB);
    s.setProperty('--pk-accent-light', window.PICKAX_ACCENT_LIGHT);
    s.setProperty('--pk-accent-dark', window.PICKAX_ACCENT_DARK);
  };

  var fallback = ok(window.PICKAX_ACCENT) ? window.PICKAX_ACCENT : '#00a4ff';
  var cached = null;
  try { cached = localStorage.getItem(KEY); } catch (e) {}
  apply(ok(cached) ? cached : fallback);              // immédiat : dernière couleur connue (ou valeur de secours)

  // La couleur du core (pickax_core/config.lua → Config.AccentColor) est lue puis mémorisée pour les ouvertures suivantes
  try {
    fetch('https://cfx-nui-pickax_core/config.lua').then(function (r) { return r.ok ? r.text() : ''; }).then(function (t) {
      t = String(t || '').replace(/--[^\n]*/g, '');
      var m = t.match(/AccentColor\s*=\s*['"](#[0-9a-f]{6})['"]/i);
      if (!m) return;
      try { localStorage.setItem(KEY, m[1].toLowerCase()); } catch (e) {}
      if (m[1].toLowerCase() !== window.PICKAX_ACCENT.toLowerCase()) {
        apply(m[1].toLowerCase());
        window.dispatchEvent(new Event('pickax-theme'));
      }
    }).catch(function () {});
  } catch (e) {}
})();
