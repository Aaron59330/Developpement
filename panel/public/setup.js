'use strict';
// ───────── Assistant d'installation, profils de serveur et historique des réglages ─────────
const fmtSetVal = (v, type) => v === null || v === undefined ? 'par défaut' : type === 'bool' ? (v ? 'activé' : 'désactivé') : Array.isArray(v) ? (v.length ? v.join(' · ').slice(0, 60) : 'vide') : String(v).slice(0, 60) || 'vide';
const fmtDate = t => new Date(t * 1000).toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });

// ── Historique des réglages ──
PAGES.history = async function () {
  const s = curServer(); if (!s) return needServer();
  const r = await api('GET', `/api/servers/${s.id}/settings/history`); if (!r.ok) return el('div', { class: 'card' }, r.error);
  return el('div', {}, head('Historique des réglages'),
    el('p', { class: 'muted', style: 'margin-bottom:14px' }, 'Chaque enregistrement de réglages est conservé : qui l’a fait, quand, et ce qui a changé. « Annuler ce changement » remet les réglages tels qu’ils étaient juste avant.'),
    r.rows.length ? r.rows.map(h => el('div', { class: 'card' },
      el('div', { class: 'row' }, el('b', {}, fmtDate(h.at)), el('span', { class: 'pill' }, h.source), el('span', { class: 'muted' }, 'par ', h.user), el('div', { class: 'grow' }),
        el('button', { class: 'btn s', onclick: () => confirmBox('Annuler ce changement ?', 'Les réglages reviendront à leur état d’avant cet enregistrement (l’annulation est elle-même enregistrée).', async () => { const x = await api('POST', `/api/servers/${s.id}/settings/history/${h.id}/restore`, {}); toast(x.ok ? `Réglages restaurés (${x.changed} modifié${x.changed > 1 ? 's' : ''})` : x.error, x.ok ? 'ok' : 'bad'); render(); }) }, el('span', {}, 'Annuler ce changement'))),
      el('div', { style: 'margin-top:8px;display:grid;gap:3px;font-size:13px' }, h.changes.map(c => el('div', { class: 'row', style: 'justify-content:space-between;gap:12px' }, el('span', {}, `${c.group ? c.group + ' · ' : ''}${c.label}`), el('span', { class: 'muted' }, `${fmtSetVal(c.from, c.type)} → `, el('b', {}, fmtSetVal(c.to, c.type)))))))) : el('div', { class: 'card empty' }, 'Aucun changement enregistré pour le moment.'));
};

// ── Assistant d'installation ──
PAGES.setup = async function () {
  const s = curServer(); if (!s) return needServer();
  const [th, pr] = await Promise.all([api('GET', `/api/servers/${s.id}/docs/theme`), api('GET', `/api/servers/${s.id}/settings/profiles`)]);
  const theme = th.value || null;
  const st = window.__setup = window.__setup || { step: 0, name: '', short: '', color: '', profile: '', hook: '' };
  if (!st.name && theme) { st.name = theme.ServerName || ''; st.short = theme.ServerShortName || ''; st.color = theme.AccentColor || '#fdc27d'; }
  const steps = ['Identité', 'Profil du serveur', 'Discord', 'Terminé'];
  const go = n => { st.step = n; render(); };
  const bar = el('div', { class: 'row', style: 'gap:8px;margin-bottom:18px;flex-wrap:wrap' }, steps.map((t, i) => el('span', { class: 'pill' + (i === st.step ? ' acc' : ''), style: i < st.step ? 'opacity:.7' : '' }, `${i < st.step ? '✓' : i + 1}  ${t}`)));
  const nav = (back, next, nextLabel, onNext) => el('div', { class: 'row', style: 'margin-top:18px;justify-content:space-between' }, back ? el('button', { class: 'btn', onclick: () => go(st.step - 1) }, el('span', {}, 'Retour')) : el('span'), next ? el('button', { class: 'btn p', onclick: async () => { if (onNext && (await onNext()) === false) return; go(st.step + 1); } }, el('span', {}, nextLabel || 'Continuer')) : null);
  let body;
  if (st.step === 0) {
    const nameI = el('input', { value: st.name, maxlength: 60, oninput: e => st.name = e.target.value }), shortI = el('input', { value: st.short, maxlength: 24, oninput: e => st.short = e.target.value });
    const col = el('input', { type: 'color', value: st.color || '#fdc27d', style: 'width:60px;height:42px;padding:3px', oninput: e => st.color = e.target.value });
    body = el('div', { class: 'card' }, el('h2', {}, '1 · L’identité de ton serveur'), el('p', { class: 'muted', style: 'margin-bottom:10px' }, 'Le nom et la couleur se retrouvent partout en jeu : HUD, menus, écran de chargement.'),
      theme ? [el('label', {}, 'Nom du serveur'), nameI, el('label', {}, 'Nom court (HUD, notifications)'), shortI, el('label', {}, 'Couleur principale'), el('div', { class: 'row' }, col, el('span', { class: 'muted' }, 'Sert d’accent à toutes les interfaces'))] : el('p', { class: 'muted' }, 'Ton serveur n’a pas encore envoyé ses données : démarre-le une fois, puis reviens ici.'),
      nav(false, true, 'Enregistrer et continuer', async () => {
        if (!theme) return true; const v = { ...theme, ServerName: st.name.trim() || theme.ServerName, ServerShortName: st.short.trim() || theme.ServerShortName, AccentColor: st.color || theme.AccentColor };
        const x = await api('PUT', `/api/servers/${s.id}/docs/theme`, { value: v }); if (!x.ok) { toast(x.error, 'bad'); return false; } return true; }));
  } else if (st.step === 1) {
    body = el('div', { class: 'card' }, el('h2', {}, '2 · Quel type de serveur ?'), el('p', { class: 'muted', style: 'margin-bottom:12px' }, 'Un profil règle des dizaines d’options d’un coup (difficulté, monde, combat, gangs). Tu pourras tout ajuster ensuite dans « Réglages du serveur ».'),
      pr.ready ? el('div', { class: 'opts' }, pr.profiles.map(p => el('button', { class: 'opt' + (st.profile === p.id ? ' on' : ''), onclick: () => { st.profile = p.id; render(); } }, el('div', { class: 'opt-t' }, el('b', {}, `${p.icon}  ${p.name}`), st.profile === p.id ? el('span', { class: 'pill acc' }, 'Choisi') : null), el('small', { class: 'muted' }, p.desc), el('small', { class: 'muted' }, `${p.count} réglages`)))) : el('p', { class: 'muted' }, 'Les réglages ne sont pas encore disponibles : la ressource pickax_settings doit tourner sur ton serveur. Tu peux passer cette étape.'),
      nav(true, true, st.profile ? 'Appliquer et continuer' : 'Passer', async () => {
        if (!st.profile || !pr.ready) return true; const p = pr.profiles.find(x => x.id === st.profile);
        const x = await api('POST', `/api/servers/${s.id}/settings/profile`, { name: p.name, values: p.values }); if (!x.ok) { toast(x.error, 'bad'); return false; } toast(`Profil « ${p.name} » appliqué`, 'ok'); return true; }));
  } else if (st.step === 2) {
    const hook = el('input', { value: st.hook, placeholder: 'https://discord.com/api/webhooks/…', oninput: e => st.hook = e.target.value });
    body = el('div', { class: 'card' }, el('h2', {}, '3 · Alertes Discord (facultatif)'), el('p', { class: 'muted', style: 'margin-bottom:10px' }, 'Reçois dans un salon les événements importants : guerres, territoires, tributs, saisies, accidents de laboratoire. Discord → Paramètres du salon → Intégrations → Webhooks → Copier l’URL.'), el('label', {}, 'Adresse du webhook'), hook,
      nav(true, true, st.hook.trim() ? 'Activer et continuer' : 'Passer', async () => {
        if (!st.hook.trim()) return true; const x = await api('POST', `/api/servers/${s.id}/settings/profile`, { name: 'assistant · Discord', values: { discord_alerts: true, discord_webhook: st.hook.trim(), discord_cat_gangs: true, discord_cat_police: true, discord_cat_labs: true } });
        if (!x.ok) { toast(x.error, 'bad'); return false; } toast('Alertes Discord activées', 'ok'); return true; }));
  } else {
    localStorage.setItem('aero_setup_' + s.id, '1');
    body = el('div', { class: 'card' }, el('h2', {}, '✅  Ton serveur est prêt'), el('p', { class: 'muted', style: 'margin-bottom:14px' }, 'Les réglages sont appliqués en direct sur ton serveur, sans redémarrage. Pour aller plus loin :'),
      el('div', { class: 'grid g2' }, [['#/settings', 'Réglages du serveur', 'Ajuster chaque système en détail'], ['#/theme', 'Identité & thème', 'Logo, bannières, couleurs'], ['#/loading', 'Écran de chargement', 'Messages, équipe, musique'], ['#/discord', 'Message Discord', 'Publier une annonce']].map(([h, t, d]) => el('a', { class: 'card', href: h, style: 'margin:0;display:block' }, el('b', {}, t), el('div', { class: 'muted', style: 'font-size:13px' }, d)))),
      el('div', { class: 'row', style: 'margin-top:14px' }, el('button', { class: 'btn', onclick: () => { window.__setup = null; go(0); } }, el('span', {}, 'Recommencer'))));
  }
  return el('div', {}, head('Assistant d’installation'), el('p', { class: 'muted', style: 'margin-bottom:12px' }, 'Configure ton serveur en 3 étapes : identité, type de serveur, alertes Discord.'), bar, body);
};

// ── Diagnostic du serveur ──
PAGES.diag = async function () {
  const s = curServer(); if (!s) return needServer();
  const r = await api('GET', `/api/servers/${s.id}/diagnostic`); if (!r.ok) return el('div', { class: 'card' }, r.error);
  const col = { ok: '#4ade80', warn: '#fbbf24', bad: '#f87171' }, ico = { ok: '✓', warn: '!', bad: '✕' };
  return el('div', {}, head('Diagnostic du serveur', el('button', { class: 'btn p', onclick: () => render() }, el('span', {}, 'Relancer le test'))),
    el('div', { class: 'card', style: `border-color:${r.bad ? col.bad : r.warn ? col.warn : col.ok}55` }, el('div', { class: 'row' }, el('div', { style: `font-size:42px;font-weight:700;color:${r.bad ? col.bad : r.warn ? col.warn : col.ok}` }, r.score + ' %'),
      el('div', {}, el('b', {}, r.bad ? `${r.bad} problème(s) à corriger` : r.warn ? `${r.warn} point(s) à surveiller` : 'Tout est en ordre'), el('div', { class: 'muted' }, 'Test fait avec les dernières informations envoyées par ton serveur.')))),
    el('div', { class: 'card' }, r.checks.map(c => el('div', { class: 'row', style: 'padding:10px 0;border-bottom:1px solid var(--line);align-items:flex-start;gap:12px' },
      el('span', { style: `flex:none;width:24px;height:24px;border-radius:50%;display:grid;place-items:center;font-weight:700;background:${col[c.level]}22;color:${col[c.level]}` }, ico[c.level]),
      el('div', {}, el('b', {}, c.label), el('div', { class: 'muted', style: 'font-size:13px' }, c.detail), c.fix ? el('div', { style: 'font-size:12.5px;margin-top:2px' }, '→ ', c.fix) : null)))));
};

// ── Fiche joueur ──
const hm = m => m >= 60 ? `${Math.floor(m / 60)} h ${String(m % 60).padStart(2, '0')}` : `${m} min`;
PAGES.playersheet = async function () {
  const s = curServer(); if (!s) return needServer();
  const q = sessionStorage.getItem('aero_pq') || '', sel = sessionStorage.getItem('aero_psel') || '';
  const r = await api('GET', `/api/servers/${s.id}/players-db?q=${encodeURIComponent(q)}`);
  const detail = sel ? await api('GET', `/api/servers/${s.id}/players-db/${encodeURIComponent(sel)}`) : null;
  const search = el('input', { placeholder: 'Rechercher un joueur (pseudo ou identifiant)…', value: q, style: 'max-width:380px', onkeydown: e => { if (e.key === 'Enter') { sessionStorage.setItem('aero_pq', e.target.value); render(); } } });
  const card = detail && detail.ok ? (() => { const p = detail.player; return el('div', { class: 'card' }, el('div', { class: 'row' }, el('h2', { style: 'margin:0' }, p.name), el('span', { class: 'pill ' + (p.online ? 'ok' : '') }, p.online ? 'En ligne' : 'Hors ligne'), el('div', { class: 'grow' }), el('small', { class: 'muted' }, p.identifier)),
    el('div', { class: 'grid g4', style: 'margin-top:12px' }, stat2('Temps de jeu', hm(p.minutes), `${p.sessions} session${p.sessions > 1 ? 's' : ''}`), stat2('Argent actuel', money(p.money + p.bank), `${money(p.money)} en poche · ${money(p.bank)} en banque`), stat2('Pic de richesse', money(p.max_money)), stat2('Dernier métier', p.last_job || '—', 'vu ' + fmtDate(p.last_seen))),
    el('div', { class: 'muted', style: 'margin:10px 0 4px' }, 'Première connexion : ', fmtDate(p.first_seen)),
    el('h3', { style: 'margin-top:14px' }, 'Sanctions'), detail.sanctions.length ? detail.sanctions.map(x => el('div', { class: 'row', style: 'padding:6px 0;border-bottom:1px solid var(--line)' }, el('span', { class: 'pill ' + (x.kind === 'ban' ? 'bad' : '') }, ({ ban: 'Bannissement', unban: 'Débannissement', kick: 'Expulsion' })[x.kind] || x.kind), el('span', {}, x.reason || '—'), el('div', { class: 'grow' }), el('span', { class: 'muted' }, x.actif ? 'actif' : x.at ? fmtDate(x.at) : ''))) : el('div', { class: 'muted' }, 'Aucune sanction enregistrée.')); })() : null;
  return el('div', {}, head('Fiche joueur', search), el('p', { class: 'muted', style: 'margin-bottom:12px' }, `${r.total} joueur${r.total > 1 ? 's' : ''} suivi${r.total > 1 ? 's' : ''} : le temps de jeu se calcule à chaque synchronisation du serveur (environ 1 minute).`), card,
    el('div', { class: 'card' }, r.rows.length ? el('table', {}, el('thead', {}, el('tr', {}, ['Joueur', 'Statut', 'Temps de jeu', 'Sessions', 'Dernier métier', 'Vu'].map(h => el('th', {}, h)))), el('tbody', {}, r.rows.map(p => el('tr', { style: 'cursor:pointer' + (p.identifier === sel ? ';background:var(--on)' : ''), onclick: () => { sessionStorage.setItem('aero_psel', p.identifier); render(); } }, el('td', {}, el('b', {}, p.name)), el('td', {}, el('span', { class: 'pill ' + (p.online ? 'ok' : '') }, p.online ? 'En ligne' : 'Hors ligne')), el('td', {}, hm(p.minutes)), el('td', {}, p.sessions), el('td', {}, p.last_job || '—'), el('td', { class: 'muted' }, fmtDate(p.last_seen)))))) : el('div', { class: 'empty' }, 'Aucun joueur trouvé.')));
};
