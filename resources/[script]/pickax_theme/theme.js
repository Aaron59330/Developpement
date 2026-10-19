/* ═══════════════════════════════════════════════════════════════════════════════
   PICKAX — THÈME GÉNÉRAL
   ───────────────────────────────────────────────────────────────────────────────
   Change la couleur ci-dessous : elle s'applique à toutes les interfaces
   (HUD, menus, notifications, builders, tablette, pause, CarPlay, menu contextuel…)
   sans ouvrir aucun autre script.

   Après modification : `restart pickax_theme`, puis relance les ressources dont tu veux
   voir le changement tout de suite (ou reconnecte-toi).  Format : #RRGGBB
   ═══════════════════════════════════════════════════════════════════════════════ */

window.PICKAX_ACCENT = '#00a4ff';        // ← COULEUR PRINCIPALE (bleu Bluebay par défaut)

/* ─────────────────────────── ne rien modifier sous cette ligne ─────────────────────────── */
(function () {
  var hex = String(window.PICKAX_ACCENT || '').trim();
  if (!/^#[0-9a-f]{6}$/i.test(hex)) hex = window.PICKAX_ACCENT = '#00a4ff';
  var rgb = [1, 3, 5].map(function (i) { return parseInt(hex.slice(i, i + 2), 16); });
  var mix = function (to, t) {
    return '#' + rgb.map(function (v) { var n = Math.round(v + (to - v) * t); return (n < 16 ? '0' : '') + n.toString(16); }).join('');
  };
  window.PICKAX_ACCENT_RGB = rgb.join(',');
  window.PICKAX_ACCENT_LIGHT = mix(255, 0.14);   // survol / dégradé clair
  window.PICKAX_ACCENT_DARK = mix(0, 0.28);      // dégradé foncé
  var s = document.documentElement.style;
  s.setProperty('--pk-accent', hex);
  s.setProperty('--pk-accent-rgb', window.PICKAX_ACCENT_RGB);
  s.setProperty('--pk-accent-light', window.PICKAX_ACCENT_LIGHT);
  s.setProperty('--pk-accent-dark', window.PICKAX_ACCENT_DARK);
})();
