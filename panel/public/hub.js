'use strict';
/* ═════════ Design « Hub » : nouvelle coque (menu à sous-menus, barre du haut) + réglages en pages ═════════
   Actif quand html[data-design="hub"] (défaut) ; les autres designs gardent leur coque d'origine. Aucune fonction n'est modifiée : mêmes pages, même API. */
(() => {
  const origShell = window.shell;
  const isHub = () => document.documentElement.getAttribute('data-design') === 'hub';
  const GROUP_ICON = { 'Serveur': 'sliders', 'Monde & PNJ': 'map', 'Météo & heure': 'bolt', 'Joueurs & combat': 'shield', 'Nouveaux joueurs': 'user', 'Interface': 'brush', 'Voix': 'chat', 'Économie': 'chart', 'Carnet': 'book', 'Gangs': 'users', 'Drogues & labos': 'box', 'Discord': 'chat', 'Performance': 'bolt' };
  const GROUP_LABEL = { 'Drogues & labos': 'Illégal · Drogues & labos', 'Gangs': 'Gangs & territoires' };
  const CHEV = 'm9 6 6 6-6 6', SIDEBAR = 'M4 5h16v14H4zM9 5v14';
  const store = { get: k => { try { return sessionStorage.getItem(k); } catch (e) { return null; } }, set: (k, v) => { try { sessionStorage.setItem(k, v); } catch (e) {} } };
  const slug = g => encodeURIComponent(g);
  const curGroup = () => { const [p, sub] = route(); return p === 'settings' ? (sub ? decodeURIComponent(sub) : (store.get('aero_setcat') || SET_ORDER[0])) : null; };

  window.shell = function (content) {
    if (!isHub()) return origShell(content);
    const [page] = route(); const isAdmin = state.user.role === 'admin'; const srv = curServer(); const lonely = !isAdmin && !state.servers.length;
    const grpNow = curGroup();
    const link = (id, label, icon, cls) => el('a', { class: 'hub-nav' + (page === id && page !== 'settings' ? ' on' : '') + (cls ? ' ' + cls : ''), href: '#/' + id }, svg(ICON[icon]), el('span', {}, label));
    const anyOn = false;
    const group = (key, label, icon, items) => {
      const on = items.some(i => i.classList.contains('on')), open = on || (!anyOn && store.get('hub_open_' + key) === '1');
      const head = el('a', { class: 'hub-nav hub-gh' + (on ? ' on' : ''), href: '#', onclick: e => { e.preventDefault(); const w = e.currentTarget.parentElement; const o = !w.classList.contains('open'); document.querySelectorAll('.hub-grp').forEach(g => { if (g !== w) { g.classList.remove('open'); if (g.dataset.k) store.set('hub_open_' + g.dataset.k, '0'); } }); w.classList.toggle('open', o); store.set('hub_open_' + key, o ? '1' : '0'); } }, svg(ICON[icon]), el('span', {}, label), svg(CHEV));
      head.lastChild.setAttribute('class', 'chev');
      return el('div', { class: 'hub-grp' + (open ? ' open' : ''), 'data-k': key }, head, el('div', { class: 'hub-sub' }, items));
    };
    const settingsItems = SET_ORDER.map(g => el('a', { class: 'hub-nav' + (page === 'settings' && grpNow === g ? ' on' : ''), href: '#/settings/' + slug(g) }, svg(ICON[GROUP_ICON[g] || 'sliders']), el('span', {}, GROUP_LABEL[g] || g)));
    const sec = t => el('div', { class: 'hub-sec' }, t);
    const nav = lonely
      ? [sec('Mon espace'), link('offers', 'Boutique', 'cart'), link('patchnotes', 'Patch notes', 'book'), sec('Paramètres'), link('account', 'Compte', 'user'), link('support', 'Aide et support', 'help'), link('custom', 'Personnalisation', 'brush')]
      : [sec('Vue d’ensemble'), link('overview', 'Dashboard', 'home'), link('discord', 'Discord', 'chat'), link('resources', 'Ressources', 'box'), link('shop', 'Addons', 'cart', 'gold'), link('license', 'Clé de développement', 'key', 'violet'), link('assistant', 'Assistant IA', 'spark'),
        sec('Gestion'), link('activity', 'Logs', 'list'), link('players', 'Joueurs', 'users'), link('playersheet', 'Fiches joueurs', 'user'), link('console', 'Console', 'term'), link('reports', 'Plaintes', 'shield'), link('map', 'Carte live', 'map'), link('actions', 'Actions rapides', 'bolt'), link('access', 'Bans & whitelist', 'shield'), link('planner', 'Événements programmés', 'cal'),
        group('stats', 'Statistiques', 'chart', [link('stats', 'Joueurs & activité', 'chart'), link('economy', 'Économie', 'chart'), link('retention', 'Rétention', 'chart'), link('diag', 'Diagnostic', 'shield')]),
        sec('Configuration'),
        group('conf', 'Configuration', 'sliders', [link('theme', 'Général', 'brush'), link('loading', 'Écran d’accueil', 'film'), link('modules', 'Ressources', 'puzzle'), link('setup', 'Assistant d’installation', 'spark'), link('history', 'Historique des réglages', 'list')]),
        group('srv', 'Gestion Serveur', 'box', settingsItems),
        group('com', 'Communication', 'chat', [link('events', 'Événements & rappels', 'chat'), link('alerts', 'Alertes Discord', 'chat'), link('recruit', 'Candidatures', 'chat')]),
        group('bk', 'Backups', 'db', [link('backups', 'Sauvegardes', 'db'), link('dbbackups', 'Sauvegardes de la base', 'db')]),
        sec('Développement'), link('editor', 'Éditeur de base', 'edit'), link('files', 'Fichiers', 'file'), link('webhooks', 'Webhooks', 'hook'),
        sec('Paramètres'), link('account', 'Compte', 'user'), link('custom', 'Personnalisation', 'brush'), link('support', 'Team & support', 'users'), link('patchnotes', 'Guide', 'book'), link('suggestions', 'Suggestions', 'bulb'), isAdmin ? null : link('offers', 'Abonnements', 'tag'),
        isAdmin ? [sec('Administration'), link('a-overview', 'Vue d’ensemble', 'chart'), link('a-users', 'Clients', 'user'), link('a-licenses', 'Licences', 'key'), link('a-plans', 'Offres', 'tag'), link('a-orders', 'Commandes', 'cart'), link('a-modules', 'Modules', 'puzzle'), link('a-audit', 'Journal', 'list')] : null];
    const brand = el('div', { class: 'hub-brand' }, el('img', { src: 'img/logo.png', alt: '' }),
      state.servers.length > 1 ? el('select', { onchange: e => setSid(+e.target.value) }, state.servers.map(s => el('option', { value: s.id, selected: s.id === (srv && srv.id) }, s.server_name))) : el('div', {}, el('b', {}, (srv && srv.server_name) || 'AERO'), el('small', {}, 'AERO PANEL')));
    const foot = el('div', { class: 'hub-foot' }, el('div', { class: 'av' }, (state.user.username || '?')[0].toUpperCase()), el('div', {}, el('b', {}, state.user.username || ''), el('small', {}, isAdmin ? 'ADMIN' : 'CLIENT')),
      el('button', { title: 'Déconnexion', onclick: async () => { await api('POST', '/api/auth/logout', {}); state.user = null; state.servers = []; location.hash = '#/'; render(); } }, '⋯'));
    const side = el('aside', { class: 'side hub-side' }, brand, el('div', { class: 'hub-wrap' }, nav.flat(Infinity).filter(Boolean)), foot);
    // fil d'Ariane : section · page
    const on = side.querySelector('.hub-nav.on:not(.hub-gh)') || side.querySelector('.hub-nav.on'); let sectionName = '';
    if (on) { const grp = on.closest('.hub-grp'); if (grp) sectionName = grp.querySelector('.hub-gh span').textContent; else { for (let n = on.previousElementSibling; n; n = n.previousElementSibling) if (n.classList.contains('hub-sec')) { sectionName = n.textContent; break; } } }
    const layout = el('div', { class: 'layout' + (store.get('hub_collapsed') === '1' ? ' collapsed' : '') });
    const top = el('div', { class: 'hub-top' },
      el('button', { class: 'tg', title: 'Réduire / afficher le menu', onclick: () => { const c = layout.classList.toggle('collapsed'); store.set('hub_collapsed', c ? '1' : '0'); } }, svg(SIDEBAR)),
      el('div', { class: 'bc' }, 'AERO Panel', sectionName ? [el('i', {}, '/'), sectionName] : null, on ? [el('i', {}, '/'), el('b', {}, on.textContent)] : null),
      el('div', { class: 'grow' }),
      srv ? el('div', { class: 'pl' }, el('i', { class: srv.online ? '' : 'off' }), `${srv.players || 0} joueur${(srv.players || 0) > 1 ? 's' : ''}`) : null,
      el('button', { class: 'tg', title: 'Thème clair / sombre', onclick: () => savePrefs({ theme: (state.user.prefs && state.user.prefs.theme) === 'clair' ? 'sombre' : 'clair' }) }, svg('M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z')));
    layout.append(side, el('main', { class: 'main' }, top, el('div', { class: 'page' }, content)));
    return layout;
  };

  // Réglages : une page par catégorie (menu « Gestion Serveur »), titre « Gestion Serveur — Catégorie »
  const baseSettings = PAGES.settings;
  PAGES.settings = async function () {
    if (!isHub()) return baseSettings();
    const g = curGroup(); if (g) store.set('aero_setcat', g);
    const node = await baseSettings();
    try {
      // Mode de jeu, profils et texte d'intro : une seule fois, sur la première page (« Serveur ») — pas répétés sur chaque catégorie
      if (g && g !== SET_ORDER[0]) { [...node.children].forEach(c => { if (c.matches('.setlayout, .setbar, .top')) return; if (c.matches('.card, p.muted')) c.remove(); }); }
      // catégorie absente du serveur : message clair plutôt que les réglages d'une autre catégorie
      const rows0 = [...node.querySelectorAll('.setrow')];
      if (g && rows0.length && !rows0.some(r => (r.getAttribute('data-t') || '').endsWith(' ' + g.toLowerCase()))) { const lay = node.querySelector('.setlayout'); if (lay) lay.replaceChildren(el('div', { class: 'card empty' }, el('h2', {}, 'Aucun réglage dans cette catégorie'), el('p', { class: 'muted' }, 'Ton serveur n’expose pas encore de réglages « ' + g + ' ». Mets à jour la ressource pickax_settings si tu viens d’ajouter des systèmes.'))); }
      node.querySelectorAll('.setrow').forEach(r => { const k = r.getAttribute('data-k'), lab = r.firstElementChild; if (k && lab && !lab.querySelector('.hub-key')) { const c = el('code', { class: 'hub-key' }, k); lab.append(c); } });
      node.querySelectorAll('.setsec').forEach(h => { if (!h.querySelector('svg')) h.prepend(svg('M4 6h16M4 12h16M4 18h10')); });
      const h1 = node.querySelector && node.querySelector('.top h1');
      if (h1 && g) { h1.textContent = 'Gestion Serveur — ' + (GROUP_LABEL[g] || g); const sub = el('p', { class: 'hub-sub-title' }, 'Les changements sont appliqués en jeu en direct, sans redémarrage.'); h1.closest('.top').after(sub); }
      const save = node.querySelector('.setbar .btn.p span'); if (save) save.textContent = 'Enregistrer les modifications';
    } catch (e) {}
    return node;
  };

  // Design « Hub » proposé dans Personnalisation
  const baseCustom = PAGES.custom;
  PAGES.custom = function () {
    const node = baseCustom();
    try {
      const pr = state.user.prefs || {}; const opts = node.querySelector('.opts');
      if (opts && !opts.querySelector('[data-hub]')) {
        const b = el('button', { class: 'opt' + (pr.design !== 'v1' && pr.design !== 'v2' ? ' on' : ''), 'data-hub': '1', onclick: async () => { await savePrefs({ design: 'hub' }); toast('Design Hub activé'); render(); } },
          el('div', { class: 'opt-t' }, el('b', {}, 'Design Hub'), pr.design !== 'v1' && pr.design !== 'v2' ? el('span', { class: 'pill acc' }, 'Actuel') : null), el('small', { class: 'muted' }, 'Noir profond, menu à sous-menus, réglages en lignes, bouton d’enregistrement flottant.'));
        opts.prepend(b);
      }
    } catch (e) {}
    return node;
  };
})();
