'use strict';
/* Adaptateur chargé EN PREMIER par chaque page d'interface intégrée à pickax_core (modules/<nom>/…).
 * Les pages d'origine appellent  https://<ressource>/<callback>  avec GetParentResourceName() ; une fois fusionnées dans pickax_core,
 * les callbacks NUI de chaque module sont préfixés (« jobbuilder:rpc ») pour ne pas se marcher dessus : on le fait ici, sans toucher aux pages. */
(() => {
  const RES = 'pickax_core';
  const m = location.pathname.match(/\/modules\/([^/]+)\//);
  const mod = m && m[1] !== '_hub' ? m[1] : '';
  window.GetParentResourceName = () => RES;
  try {
    if (!window.invokeNative && window.parent && window.parent !== window && typeof window.parent.invokeNative === 'function') {
      window.invokeNative = (...a) => window.parent.invokeNative(...a);
    }
  } catch (e) { /* page parente d'une autre origine (tests hors du jeu) : ignoré */ }
  const fix = u => {
    try {
      const x = new URL(u, location.href);
      if (mod && (x.protocol === 'https:' || x.protocol === 'http:') && x.hostname === RES) {
        x.pathname = '/' + mod + ':' + x.pathname.replace(/^\//, '');
        return x.toString();
      }
    } catch (e) { /* url invalide : inchangée */ }
    return u;
  };
  const f = window.fetch;
  if (f) window.fetch = (u, o) => f.call(window, typeof u === 'string' ? fix(u) : u, o);
  const open = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function (method, u, ...rest) { return open.call(this, method, typeof u === 'string' ? fix(u) : u, ...rest); };
})();
