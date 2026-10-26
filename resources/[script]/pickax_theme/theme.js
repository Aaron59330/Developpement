/* ═══════════════════════════════════════════════════════════════════════════════
   PICKAX — THÈME / IDENTITÉ DU SERVEUR
   ───────────────────────────────────────────────────────────────────────────────
   Le réglage se fait dans  pickax_core/config.lua  (AccentColor, ServerName, ServerShortName,
   ServerTagline, ServerDiscord, ServerLogo).  Les valeurs ci-dessous ne sont que des valeurs de
   SECOURS, utilisées si le fichier du core est illisible.

   Dans une page : [data-pk="name|short|tagline|discord"]  → texte remplacé
                   [data-pk-logo]                          → src de l'image remplacé
                   [data-pk-upper]                         → texte en majuscules
   Variables CSS : --pk-accent, --pk-accent-rgb, --pk-accent-light, --pk-accent-dark, --pk-logo (url)
   ═══════════════════════════════════════════════════════════════════════════════ */

window.PICKAX_ACCENT = '#fdc27d';
window.PICKAX_SERVER = { name: 'Bluebay Roleplay', short: 'BLUEBAY', tagline: 'RP sérieux · Free-Access', discord: 'discord.gg/bluebayrp', logo: 'logo.png', invColor: '' };

/* ─────────────────────────── ne rien modifier sous cette ligne ─────────────────────────── */
(function () {
  var KEY = 'pickax_theme_v2';
  var BASE = 'https://cfx-nui-pickax_theme/logo/';
  var def = { accent: window.PICKAX_ACCENT, server: window.PICKAX_SERVER };
  var okHex = function (h) { return /^#[0-9a-f]{6}$/i.test(String(h || '')); };

  var logoUrl = function (l) { l = String(l || 'logo.png'); return /^(https?:)?\/\//i.test(l) || /^(data|nui):/i.test(l) ? l : BASE + l.replace(/^\/+/, ''); };

  var fill = function () {
    var S = window.PICKAX_SERVER, root = document;
    var map = { name: S.name, short: S.short, tagline: S.tagline, discord: S.discord };
    [].forEach.call(root.querySelectorAll('[data-pk]'), function (el) {
      var v = map[el.getAttribute('data-pk')];
      if (v == null) return;
      el.textContent = el.hasAttribute('data-pk-upper') ? String(v).toUpperCase() : v;
    });
    [].forEach.call(root.querySelectorAll('[data-pk-logo]'), function (el) { el.setAttribute('src', window.PICKAX_LOGO); });
    [].forEach.call(root.querySelectorAll('[data-pk-title]'), function (el) { el.setAttribute('title', S.name); });
  };

  var apply = function (hex, server) {
    var rgb = [1, 3, 5].map(function (i) { return parseInt(hex.slice(i, i + 2), 16); });
    var mix = function (to, t) {
      return '#' + rgb.map(function (v) { var n = Math.round(v + (to - v) * t); return (n < 16 ? '0' : '') + n.toString(16); }).join('');
    };
    window.PICKAX_ACCENT = hex;
    window.PICKAX_ACCENT_RGB = rgb.join(',');
    window.PICKAX_ACCENT_LIGHT = mix(255, 0.14);
    window.PICKAX_ACCENT_DARK = mix(0, 0.28);
    window.PICKAX_SERVER = server;
    window.PICKAX_LOGO = logoUrl(server.logo);
    window.PICKAX_INV_COLOR = okHex(server.invColor) ? server.invColor : hex;     // couleur de l'inventaire (InventoryColor, sinon AccentColor)
    var s = document.documentElement.style;
    s.setProperty('--pk-accent', hex);
    s.setProperty('--pk-accent-rgb', window.PICKAX_ACCENT_RGB);
    s.setProperty('--pk-accent-light', window.PICKAX_ACCENT_LIGHT);
    s.setProperty('--pk-accent-dark', window.PICKAX_ACCENT_DARK);
    s.setProperty('--pk-logo', 'url("' + window.PICKAX_LOGO + '")');
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', fill); else fill();
  };

  var cached = null;
  try { cached = JSON.parse(localStorage.getItem(KEY) || 'null'); } catch (e) {}
  var cur = (cached && okHex(cached.accent) && cached.server) ? cached : def;
  apply(cur.accent, cur.server);                                   // immédiat : dernières valeurs connues (ou secours)

  // Applique des valeurs lues (et les mémorise pour les ouvertures suivantes)
  var finish = function (hex, server) {
    hex = hex.toLowerCase();
    var next = JSON.stringify({ accent: hex, server: server });
    try { localStorage.setItem(KEY, next); } catch (e) {}
    if (next !== JSON.stringify({ accent: window.PICKAX_ACCENT.toLowerCase(), server: window.PICKAX_SERVER })) {
      apply(hex, server);
      window.dispatchEvent(new Event('pickax-theme'));
    }
  };

  // Lecture de pickax_core/config.lua (source de secours)
  var fromConfig = function () {
    fetch('https://cfx-nui-pickax_core/config.lua').then(function (r) { return r.ok ? r.text() : ''; }).then(function (t) {
      t = String(t || '').replace(/--[^\n]*/g, '');
      var get = function (k, d) {
        var m = t.match(new RegExp('[\\s,{]' + k + "\\s*=\\s*(?:'([^'\\n]*)'|\"([^\"\\n]*)\")"));
        var v = m && (m[1] != null ? m[1] : m[2]);
        return v ? v : d;
      };
      var hex = get('AccentColor', ''); if (!okHex(hex)) return;
      finish(hex, {
        name: get('ServerName', def.server.name), short: get('ServerShortName', def.server.short),
        tagline: get('ServerTagline', def.server.tagline), discord: get('ServerDiscord', def.server.discord).replace(/^https?:\/\//i, ''),
        logo: get('ServerLogo', def.server.logo), invColor: get('InventoryColor', '')
      });
    }).catch(function () {});
  };

  // 1) thème modifié depuis les outils de la base ou le panel web : pickax_basetools/theme_live.json (écrit dans sa propre ressource, toujours autorisé)
  // 2) ancien emplacement pickax_theme/theme_live.json  3) pickax_core/config.lua
  var tryLive = function (url, next) {
    fetch(url + '?t=' + Date.now()).then(function (r) { return r.ok ? r.json() : null; }).catch(function () { return null; }).then(function (j) {
      if (j && okHex(j.accent) && j.server && typeof j.server === 'object') finish(j.accent, j.server); else next();
    });
  };
  try {
    tryLive('https://cfx-nui-pickax_basetools/theme_live.json', function () { tryLive('https://cfx-nui-pickax_theme/theme_live.json', fromConfig); });
  } catch (e) { fromConfig(); }
})();
