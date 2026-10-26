'use strict';
// Pages supplémentaires : dashboard, console, statistiques, webhooks, sauvegardes, modules, boutique, personnalisation, activité, support, patch notes, suggestions
const cur = () => curServer();
const needS = () => needServer();
const post = (u, b) => api('POST', u, b || {});
const stat2 = (l, v, sub) => el('div', { class: 'card stat' }, el('small', {}, l), el('b', {}, v), sub ? el('div', { class: 'muted', style: 'font-size:12px' }, sub) : null);
const actLabel = a => ({ 'file:write': 'Fichier modifié', 'file:create': 'Fichier créé', console: 'Commande console', rename: 'Serveur renommé', 'rotate-key': 'Clé régénérée', unbind: 'IP déliée', ai: 'Assistant IA', server_restart: 'Redémarrage demandé', server_stop: 'Arrêt demandé', webhooks: 'Webhooks modifiés', 'drive:upload': 'Image envoyée', 'backup:create': 'Sauvegarde créée', 'backup:restore': 'Sauvegarde restaurée', 'module:on': 'Module activé', 'module:off': 'Module désactivé' }[a] || (a.startsWith('cmd:') ? 'Action : ' + a.slice(4) : a.startsWith('doc:') ? 'Réglage modifié : ' + a.slice(4) : a));

// ───────── Dashboard ─────────
PAGES.overview = async function () {
  const s = cur(); if (!s) return needS();
  const [st, act, sum] = await Promise.all([api('GET', `/api/servers/${s.id}/stats?hours=24`), api('GET', `/api/servers/${s.id}/activity`), api('GET', '/api/support/summary')]);
  const link = (label, sub, to) => el('a', { href: '#/' + to, class: 'qa' }, el('div', {}, el('b', {}, label), el('div', { class: 'muted' }, sub)), el('span', {}, '→'));
  const power = (action, label, danger) => el('button', { class: 'btn ' + (danger ? 'd' : ''), disabled: !s.online, onclick: () => confirmBox(label, action === 'stop' ? 'Le serveur s’arrêtera dans 15 secondes. Il ne redémarrera que si ton hébergeur/txAdmin le relance.' : 'Les joueurs seront prévenus, puis le serveur s’arrêtera dans quelques secondes (txAdmin ou ton hébergeur doit le relancer).', async () => { const r = await post(`/api/servers/${s.id}/power`, { action }); toast(r.ok ? 'Demande envoyée' : r.error, r.ok ? 'ok' : 'bad'); }, danger) }, el('span', {}, label));
  return el('div', {}, el('div', { class: 'top' }, el('div', {}, el('h1', {}, 'Tableau de bord'), el('div', { class: 'muted' }, 'Gestion de ' + s.server_name)), el('div', { class: 'grow' }), statusPill(s)),
    el('div', { class: 'grid g4' }, stat2('Tickets ouverts', sum.open_tickets ?? 0), stat2('Version de la base', sum.version || '—', 'À jour'), stat2('Joueurs', `${s.players} / ${s.max_players || '—'}`), stat2('Licence', s.expires_at ? 'jusqu’au ' + fmtDay(s.expires_at) : 'À vie', s.plan)),
    el('div', { class: 'grid g2', style: 'align-items:start' }, el('div', {},
      el('div', { class: 'card' }, el('h2', {}, 'État du système'), el('div', { class: 'row' }, el('span', { class: 'dot ' + (s.online ? 'on' : '') }), el('b', {}, s.online ? 'Serveur actif' : 'Serveur hors ligne'), el('div', { class: 'grow' }), power('restart', 'Redémarrer le serveur'), power('stop', 'Arrêter le serveur', true)),
        el('p', { class: 'muted', style: 'margin-top:8px' }, s.online ? `En ligne depuis ${uptime(s.stats.uptime)} · ${s.stats.version || ''}` : 'Le panel ne reçoit plus de nouvelles : vérifie la ressource pickax_panel.')),
      el('div', { class: 'card' }, el('h2', {}, 'Joueurs connectés (24 h)'), lineChart(st.points || [])),
      el('div', { class: 'card' }, el('h2', {}, 'Actions rapides'), link('Modifier un fichier', 'Config, items, jobs… avec historique', 'files'), link('Annonce / redémarrer une ressource', 'Actions sur le serveur', 'actions'), link('Changer la couleur et le logo', 'Personnalisation', 'theme'), link('Créer une sauvegarde', 'Avant une grosse modification', 'backups'), link('Contacter le support', 'Ouvrir un ticket', 'support'))),
    el('div', { class: 'card' }, el('div', { class: 'row' }, el('h2', { style: 'margin:0' }, 'Journal d’activités'), el('div', { class: 'grow' }), el('a', { href: '#/activity' }, 'Voir tout →')),
      (act.rows || []).length ? el('div', { style: 'margin-top:10px' }, act.rows.slice(0, 8).map(a => el('div', { class: 'ev' }, el('b', {}, actLabel(a.action)), el('div', { class: 'muted' }, `${a.username || 'système'} · ${ago(a.at)}${a.detail ? ' · ' + a.detail.slice(0, 60) : ''}`)))) : el('div', { class: 'empty' }, 'Aucune activité'))));
};
PAGES.activity = async function () {
  const s = cur(); if (!s) return needS(); const r = await api('GET', `/api/servers/${s.id}/activity`);
  return el('div', {}, head('Journal d’activités'), el('div', { class: 'card tw' }, el('table', {}, el('thead', {}, el('tr', {}, ['Date', 'Utilisateur', 'Action', 'Détail'].map(h => el('th', {}, h)))), el('tbody', {}, (r.rows || []).map(a => el('tr', {}, el('td', {}, fmtDate(a.at)), el('td', {}, a.username || 'système'), el('td', {}, actLabel(a.action)), el('td', { class: 'mono' }, (a.detail || '').slice(0, 100))))))));
};

// ───────── Console ─────────
PAGES.console = async function () {
  const s = cur(); if (!s) return needS(); let last = 0, level = '';
  const box = el('div', { class: 'console' }), sel = el('select', { style: 'max-width:200px', onchange: () => { level = sel.value; last = 0; box.replaceChildren(); load(); } }, [['', 'Tous les niveaux'], ['info', 'Info'], ['warn', 'Avertissements'], ['error', 'Erreurs'], ['staff', 'Actions staff']].map(o => el('option', { value: o[0] }, o[1])));
  const cmd = el('input', { placeholder: 'Commande (ensure, restart, start, stop, refresh, say, status)…', onkeydown: e => { if (e.key === 'Enter') run(); } });
  const run = async () => { if (!cmd.value.trim()) return; const r = await post(`/api/servers/${s.id}/console`, { cmd: cmd.value.trim() }); toast(r.ok ? 'Commande envoyée' : r.error, r.ok ? 'ok' : 'bad'); if (r.ok) cmd.value = ''; setTimeout(load, 1500); };
  const load = async () => { const r = await api('GET', `/api/servers/${s.id}/logs?after=${last}${level ? '&level=' + level : ''}`); if (!r.ok) return; const bottom = box.scrollTop + box.clientHeight >= box.scrollHeight - 30; for (const l of r.logs) { last = Math.max(last, l.id); box.append(el('div', { class: l.level }, el('span', { class: 't' }, new Date(l.at * 1000).toLocaleTimeString('fr-FR') + ' '), `[${l.source || l.level}] ${l.message}`)); } if (bottom || !last) box.scrollTop = box.scrollHeight; };
  await load(); state.timer = setInterval(load, 3000);
  return el('div', {}, head('Console', sel), el('div', { class: 'card' }, box, el('div', { class: 'row', style: 'margin-top:10px' }, el('div', { class: 'grow' }, cmd), el('button', { class: 'btn p', onclick: run }, el('span', {}, 'Exécuter'))), el('p', { class: 'muted', style: 'margin-top:8px' }, 'Les logs viennent de la ressource pickax_panel (connexions, erreurs, actions staff, modifications). Seules quelques commandes sûres sont autorisées.')));
};

// ───────── Statistiques ─────────
PAGES.stats = async function () {
  const s = cur(); if (!s) return needS(); const days = +(sessionStorage.getItem('aero_days') || 7); const r = await api('GET', `/api/servers/${s.id}/stats-summary?days=${days}`);
  const bars = (arr, max) => { const m = Math.max(1, max || Math.max(...arr.map(a => a[1]))); return el('div', {}, arr.map(([k, v]) => el('div', { class: 'bar-row' }, el('span', { class: 'bl' }, k), el('div', { class: 'bt' }, el('i', { style: `width:${v / m * 100}%` })), el('b', {}, v)))); };
  return el('div', {}, head('Statistiques', el('select', { style: 'max-width:160px', onchange: e => { sessionStorage.setItem('aero_days', e.target.value); render(); } }, [1, 7, 14, 30].map(d => el('option', { value: d, selected: d === days }, d === 1 ? '24 heures' : d + ' jours')))),
    el('div', { class: 'grid g4' }, stat2('Pic de joueurs', r.peak), stat2('Moyenne', r.avg), stat2('Joueurs en ligne', r.count), stat2('Argent en circulation', money(r.total_money), 'joueurs connectés')),
    el('div', { class: 'card' }, el('h2', {}, 'Fréquentation'), lineChart(r.points || [])),
    el('div', { class: 'grid g2' }, el('div', { class: 'card' }, el('h2', {}, 'Métiers en ligne'), (r.jobs || []).length ? bars(r.jobs) : el('div', { class: 'empty' }, 'Personne en ligne')), el('div', { class: 'card' }, el('h2', {}, 'Joueurs moyens par heure'), bars(r.hours.map((v, i) => [String(i).padStart(2, '0') + 'h', v]).filter((_, i) => i % 2 === 0)))));
};

// ───────── Webhooks ─────────
PAGES.webhooks = async function () {
  const s = cur(); if (!s) return needS(); const r = await api('GET', `/api/servers/${s.id}/webhooks`); const inputs = {};
  const labels = { staff: ['Actions staff', 'Kick, ban, argent donné, fichiers modifiés…'], error: ['Erreurs serveur', 'Erreurs de scripts signalées par le panel'], connexion: ['Connexions', 'Joueurs qui arrivent / partent'] };
  return el('div', {}, head('Webhooks Discord', el('button', { class: 'btn p', onclick: async () => { const body = {}; for (const k in inputs) body[k] = inputs[k].value; const x = await api('PUT', `/api/servers/${s.id}/webhooks`, body); toast(x.ok ? 'Webhooks enregistrés' : x.error, x.ok ? 'ok' : 'bad'); } }, el('span', {}, 'Enregistrer'))),
    el('p', { class: 'muted', style: 'margin-bottom:14px' }, 'Colle le lien d’un webhook Discord (Paramètres du salon → Intégrations → Webhooks). Laisse vide pour désactiver.'),
    r.events.map(ev => el('div', { class: 'card' }, el('div', { class: 'row' }, el('div', { class: 'grow' }, el('h2', { style: 'margin:0' }, labels[ev][0]), el('div', { class: 'muted' }, labels[ev][1])), el('button', { class: 'btn s', onclick: async () => { const x = await post(`/api/servers/${s.id}/webhooks/test`, { url: inputs[ev].value }); toast(x.ok ? 'Message de test envoyé' : x.error, x.ok ? 'ok' : 'bad'); } }, el('span', {}, 'Tester'))), (inputs[ev] = el('input', { value: r.hooks[ev] || '', placeholder: 'https://discord.com/api/webhooks/…', style: 'margin-top:10px' })))));
};

// ───────── Sauvegardes ─────────
PAGES.backups = async function () {
  const s = cur(); if (!s) return needS(); const [b, f] = await Promise.all([api('GET', `/api/servers/${s.id}/backups`), api('GET', `/api/servers/${s.id}/fs/tracked`)]);
  return el('div', {}, head('Sauvegardes', el('button', { class: 'btn p', onclick: () => ask('Nouvelle sauvegarde', [{ name: 'name', label: 'Nom (facultatif)', placeholder: 'Avant changement des prix' }], async v => { const x = await post(`/api/servers/${s.id}/backups`, v); toast(x.ok ? `Sauvegarde créée (${x.files} fichiers, ${x.docs} réglages)` : x.error, x.ok ? 'ok' : 'bad'); render(); }) }, el('span', {}, 'Créer une sauvegarde'))),
    el('p', { class: 'muted', style: 'margin-bottom:12px' }, 'Une sauvegarde contient la dernière version de chaque fichier modifié depuis le panel (' + (f.files || []).length + ' fichier(s) suivi(s)) et tes réglages (thème, bans, whitelist). Restaurer remet ces fichiers sur le serveur.'),
    el('div', { class: 'card tw' }, (b.backups || []).length ? el('table', {}, el('thead', {}, el('tr', {}, ['Nom', 'Date', 'Taille', 'Par', ''].map(h => el('th', {}, h)))), el('tbody', {}, b.backups.map(x => el('tr', {}, el('td', {}, x.name), el('td', {}, fmtDate(x.at)), el('td', {}, Math.round(x.size / 1024) + ' Ko'), el('td', {}, x.by_name || ''), el('td', {}, el('div', { class: 'row' }, el('button', { class: 'btn s', onclick: () => confirmBox('Restaurer', 'Remettre les fichiers de « ' + x.name + ' » sur le serveur ? Les fichiers actuels seront conservés dans l’historique.', async () => { const r = await post(`/api/servers/${s.id}/backups/${x.id}/restore`); toast(r.ok ? r.restored + ' fichier(s) restauré(s)' : r.error, r.ok ? 'ok' : 'bad'); }) }, el('span', {}, 'Restaurer')), el('button', { class: 'btn s d', onclick: async () => { await api('DELETE', `/api/servers/${s.id}/backups/${x.id}`); render(); } }, el('span', {}, 'Suppr.')))))))) : el('div', { class: 'empty' }, 'Aucune sauvegarde')));
};

// ───────── Modules + Boutique ─────────
async function modulesPage(shop) {
  const s = cur(); if (!s) return needS(); const r = await api('GET', `/api/servers/${s.id}/modules`); const list = (r.modules || []).filter(m => shop ? !m.owned : true);
  return el('div', {}, head(shop ? 'Boutique' : 'Gestion des modules'), el('p', { class: 'muted', style: 'margin-bottom:14px' }, shop ? 'Modules supplémentaires pour ton serveur. Fais une demande : on te répond par ticket.' : 'Active ou désactive les modules de ta base (démarre / arrête les ressources associées).'),
    list.length ? el('div', { class: 'grid g3' }, list.map(m => el('div', { class: 'card' }, el('h2', {}, m.name), el('p', {}, m.description || ''), el('p', { class: 'muted mono' }, m.resources.join(', ')), el('div', { class: 'row', style: 'margin-top:10px' }, el('span', { class: 'pill ' + (m.price ? 'acc' : 'ok') }, m.price ? m.price + ' €' : 'Inclus'), m.owned ? el('span', { class: 'pill ' + (m.enabled ? 'ok' : '') }, m.enabled ? 'Activé' : 'Désactivé') : null, el('div', { class: 'grow' }),
      shop ? el('button', { class: 'btn s p', onclick: async () => { const x = await post(`/api/servers/${s.id}/modules/${m.id}/request`); if (x.ok) { toast('Demande envoyée', 'ok'); go('support/' + x.ticket); } } }, el('span', {}, 'Demander')) : (m.owned ? el('button', { class: 'btn s', onclick: async () => { const x = await post(`/api/servers/${s.id}/modules/${m.id}/toggle`, { enabled: !m.enabled }); toast(x.ok ? 'Action envoyée (quelques secondes)' : x.error, x.ok ? 'ok' : 'bad'); setTimeout(render, 2500); } }, el('span', {}, m.enabled ? 'Désactiver' : 'Activer')) : el('span', { class: 'muted' }, 'Non acquis')))))) : el('div', { class: 'card empty' }, shop ? 'Tous les modules disponibles sont déjà dans ta licence.' : 'Aucun module défini par l’administrateur.'));
}
PAGES.modules = () => modulesPage(false); PAGES.shop = () => modulesPage(true);
PAGES['a-modules'] = async function () {
  const r = await api('GET', '/api/admin/modules'); const form = m => [{ name: 'name', label: 'Nom', value: m ? m.name : '' }, { name: 'description', label: 'Description', value: m ? m.description : '' }, { name: 'price', label: 'Prix (€, 0 = inclus)', type: 'number', value: m ? m.price : 0 }, { name: 'resources', label: 'Ressources (séparées par des virgules)', value: m ? m.resources.join(', ') : '' }];
  return el('div', {}, head('Modules', el('button', { class: 'btn p', onclick: () => ask('Nouveau module', form(), async v => { const x = await post('/api/admin/modules', v); if (!x.ok) { toast(x.error, 'bad'); return false; } render(); }) }, el('span', {}, 'Nouveau module'))),
    el('div', { class: 'card tw' }, el('table', {}, el('thead', {}, el('tr', {}, ['Nom', 'Prix', 'Ressources', 'Actif', ''].map(h => el('th', {}, h)))), el('tbody', {}, (r.modules || []).map(m => el('tr', {}, el('td', {}, m.name), el('td', {}, m.price + ' €'), el('td', { class: 'mono' }, m.resources.join(', ')), el('td', {}, m.active ? 'oui' : 'non'), el('td', {}, el('div', { class: 'row' }, el('button', { class: 'btn s', onclick: () => ask('Modifier', form(m), async v => { await api('PATCH', '/api/admin/modules/' + m.id, v); render(); }) }, el('span', {}, 'Modifier')), el('button', { class: 'btn s', onclick: async () => { await api('PATCH', '/api/admin/modules/' + m.id, { active: !m.active }); render(); } }, el('span', {}, m.active ? 'Masquer' : 'Afficher'))))))))),
    el('p', { class: 'muted' }, 'Pour donner un module payant à un client : Licences → bouton « Modules » de sa licence.'));
};

// ───────── Personnalisation = thème + Drive ─────────
const baseTheme = PAGES.theme;
PAGES.theme = async function () {
  const s = cur(); if (!s) return needS(); const page = await baseTheme(); const d = await api('GET', `/api/servers/${s.id}/drive`);
  const file = el('input', { type: 'file', accept: 'image/png,image/jpeg,image/webp,image/gif,image/svg+xml', style: 'max-width:320px' });
  const up = async () => { const f = file.files[0]; if (!f) return; if (f.size > 1500000) return toast('Image trop grosse (1,5 Mo max)', 'bad'); const data = await new Promise(res => { const fr = new FileReader(); fr.onload = () => res(String(fr.result).split(',')[1]); fr.readAsDataURL(f); }); const r = await post(`/api/servers/${s.id}/drive`, { name: f.name, mime: f.type, data }); toast(r.ok ? 'Image envoyée' : r.error, r.ok ? 'ok' : 'bad'); if (r.ok) render(); };
  page.append(el('div', { class: 'card' }, el('h2', {}, 'Drive : images hébergées'), el('p', { class: 'muted' }, 'Envoie ton logo ici puis copie son lien dans le champ « Logo » du thème.'), el('div', { class: 'row', style: 'margin:10px 0' }, file, el('button', { class: 'btn p', onclick: up }, el('span', {}, 'Envoyer'))),
    (d.files || []).length ? el('div', { class: 'grid g4' }, d.files.map(f => el('div', { class: 'card', style: 'margin:0;text-align:center' }, el('img', { src: f.url, style: 'max-width:100%;max-height:90px;object-fit:contain', alt: f.name }), el('div', { class: 'muted', style: 'font-size:12px;margin-top:6px;word-break:break-all' }, f.name), el('div', { class: 'row', style: 'justify-content:center;margin-top:6px' }, el('button', { class: 'btn s', onclick: () => copy(f.url) }, el('span', {}, 'Copier le lien')), el('button', { class: 'btn s d', onclick: async () => { await api('DELETE', `/api/servers/${s.id}/drive/${f.id}`); render(); } }, el('span', {}, '×')))))) : el('div', { class: 'empty' }, 'Aucune image')));
  const sv = (await api('GET', `/api/servers/${s.id}/docs/server`)).value || { projectName: '', projectDesc: '', hostname: '' }; const fs2 = {};
  const fld = (k, label, ph) => [el('label', {}, label), (fs2[k] = el('input', { value: sv[k] || '', placeholder: ph || '' }))];
  page.append(el('div', { class: 'card' }, el('h2', {}, 'Serveur dans la liste FiveM'), el('p', { class: 'muted' }, 'Nom et description affichés dans la liste des serveurs (remplace sv_projectName, sv_projectDesc et sv_hostname du server.cfg, sans le modifier). Codes couleur FiveM : ^1 rouge, ^2 vert, ^3 jaune, ^4 bleu, ^5 cyan, ^6 violet, ^7 blanc. Pas de guillemets.'),
    fld('projectName', 'Nom du serveur (sv_projectName)', '^4AERO RP ^7| ^4discord.gg/aero'), fld('projectDesc', 'Description (sv_projectDesc)', 'Free access, RP sérieux…'), fld('hostname', 'Nom complet (sv_hostname)', 'souvent le même que le nom du serveur'),
    el('p', { class: 'muted', style: 'margin-top:8px' }, 'Le nombre de places (sv_maxclients) et l’icône (load_server_icon) ne peuvent être changés qu’au démarrage du serveur : ils restent dans le server.cfg.'),
    el('div', { style: 'margin-top:10px' }, el('button', { class: 'btn p', onclick: async () => { const val = {}; for (const k in fs2) val[k] = fs2[k].value; const r = await api('PUT', `/api/servers/${s.id}/docs/server`, { value: val }); toast(r.ok ? 'Enregistré : appliqué sur le serveur dans quelques secondes' : r.error, r.ok ? 'ok' : 'bad'); } }, el('span', {}, 'Enregistrer')))));
  return page;
};

// ───────── Support, patch notes, suggestions ─────────
PAGES.support = async function () {
  const [, tid] = route(); const admin = state.user.role === 'admin';
  if (tid) { const r = await api('GET', '/api/support/tickets/' + +tid); if (!r.ok) return el('div', { class: 'card' }, r.error); const t = r.ticket; const body = el('textarea', { rows: 4, placeholder: 'Ta réponse…' });
    return el('div', {}, head('#' + t.id + ' · ' + t.subject, el('span', { class: 'pill ' + (t.status === 'open' ? 'warn' : '') }, t.status === 'open' ? 'Ouvert' : 'Fermé'), el('a', { class: 'btn', href: '#/support' }, el('span', {}, '← Retour'))),
      r.messages.map(m => el('div', { class: 'card msg' + (m.staff ? ' staff' : '') }, el('div', { class: 'muted', style: 'font-size:12px' }, `${m.username || '?'}${m.staff ? ' (support)' : ''} · ${fmtDate(m.at)}`), el('div', { style: 'white-space:pre-wrap;margin-top:4px' }, m.body))),
      el('div', { class: 'card' }, body, el('div', { class: 'row', style: 'margin-top:10px' }, el('button', { class: 'btn p', onclick: async () => { const x = await post(`/api/support/tickets/${t.id}/reply`, { body: body.value }); if (x.ok) render(); else toast(x.error, 'bad'); } }, el('span', {}, 'Répondre')), el('button', { class: 'btn', onclick: async () => { await post(`/api/support/tickets/${t.id}/close`, { open: t.status !== 'open' }); render(); } }, el('span', {}, t.status === 'open' ? 'Fermer le ticket' : 'Rouvrir')))));
  }
  const r = await api('GET', '/api/support/tickets'); const s = cur();
  return el('div', {}, head('Aide et support', el('button', { class: 'btn p', onclick: () => ask('Nouveau ticket', [{ name: 'subject', label: 'Sujet' }, { name: 'body', label: 'Décris ton problème' }], async v => { const x = await post('/api/support/tickets', { ...v, license_id: s && s.id }); if (!x.ok) { toast(x.error, 'bad'); return false; } go('support/' + x.id); }) }, el('span', {}, 'Nouveau ticket'))),
    el('div', { class: 'card tw' }, (r.tickets || []).length ? el('table', {}, el('thead', {}, el('tr', {}, ['#', 'Sujet', admin ? 'Client' : null, 'Messages', 'Mis à jour', 'Statut'].filter(Boolean).map(h => el('th', {}, h)))), el('tbody', {}, r.tickets.map(t => el('tr', { style: 'cursor:pointer', onclick: () => go('support/' + t.id) }, el('td', {}, t.id), el('td', {}, t.subject), admin ? el('td', { class: 'muted' }, t.email) : null, el('td', {}, t.msgs), el('td', {}, ago(t.updated_at)), el('td', {}, el('span', { class: 'pill ' + (t.status === 'open' ? 'warn' : '') }, t.status === 'open' ? 'Ouvert' : 'Fermé')))))) : el('div', { class: 'empty' }, 'Aucun ticket')));
};
PAGES.patchnotes = async function () {
  const r = await api('GET', '/api/support/patchnotes'); const admin = state.user.role === 'admin';
  return el('div', {}, head('Patch notes', admin ? el('button', { class: 'btn p', onclick: () => ask('Nouvelle note', [{ name: 'version', label: 'Version', placeholder: '1.1.0' }, { name: 'title', label: 'Titre' }, { name: 'body', label: 'Contenu' }], async v => { const x = await post('/api/support/patchnotes', v); if (!x.ok) { toast(x.error, 'bad'); return false; } render(); }) }, el('span', {}, 'Publier')) : null),
    (r.notes || []).map(n => el('div', { class: 'card' }, el('div', { class: 'row' }, el('span', { class: 'pill acc' }, 'v' + n.version), el('h2', { style: 'margin:0' }, n.title), el('div', { class: 'grow' }), el('span', { class: 'muted' }, fmtDay(n.at)), admin ? el('button', { class: 'btn s d', onclick: async () => { await api('DELETE', '/api/support/patchnotes/' + n.id); render(); } }, el('span', {}, '×')) : null), el('p', { style: 'white-space:pre-wrap;margin-top:8px' }, n.body))));
};
PAGES.suggestions = async function () {
  const r = await api('GET', '/api/support/suggestions'); const admin = state.user.role === 'admin'; const lab = { new: 'Nouvelle', planned: 'Prévue', done: 'Faite', refused: 'Refusée' };
  return el('div', {}, head('Suggestions', el('button', { class: 'btn p', onclick: () => ask('Proposer une idée', [{ name: 'title', label: 'Idée' }, { name: 'body', label: 'Détails (facultatif)' }], async v => { const x = await post('/api/support/suggestions', v); if (!x.ok) { toast(x.error, 'bad'); return false; } render(); }) }, el('span', {}, 'Nouvelle suggestion'))),
    (r.rows || []).length ? (r.rows || []).map(x => el('div', { class: 'card' }, el('div', { class: 'row' }, el('button', { class: 'btn s' + (x.voted ? ' p' : ''), onclick: async () => { await post(`/api/support/suggestions/${x.id}/vote`); render(); } }, el('span', {}, '▲ ' + x.votes)), el('div', { class: 'grow' }, el('b', {}, x.title), el('div', { class: 'muted' }, x.body || ''), el('div', { class: 'muted', style: 'font-size:12px' }, x.username + ' · ' + fmtDay(x.at))), admin ? el('select', { style: 'width:140px', onchange: async e => { await post(`/api/support/suggestions/${x.id}/status`, { status: e.target.value }); } }, Object.entries(lab).map(([k, v]) => el('option', { value: k, selected: k === x.status }, v))) : el('span', { class: 'pill ' + (x.status === 'done' ? 'ok' : x.status === 'planned' ? 'acc' : '') }, lab[x.status])))) : el('div', { class: 'card empty' }, 'Aucune suggestion pour le moment'));
};
// licence admin : bouton modules
const baseLic = PAGES['a-licenses'];
PAGES['a-licenses'] = async function () {
  const page = await baseLic(); const [r, m] = await Promise.all([api('GET', '/api/admin/licenses'), api('GET', '/api/admin/modules')]);
  const rows = page.querySelectorAll('tbody tr'); (r.licenses || []).forEach((l, i) => { const cell = rows[i] && rows[i].querySelector('td:last-child .row'); if (!cell) return;
    cell.prepend(el('button', { class: 'btn s', onclick: async () => { const o = (await api('GET', `/api/admin/licenses/${l.id}/modules`)).owned || []; ask('Modules de « ' + l.server_name + ' »', [{ name: 'module', label: 'Module', type: 'select', options: (m.modules || []).filter(x => x.price > 0).map(x => [x.id, x.name + (o.includes(x.id) ? ' (acquis)' : '')]) }, { name: 'grant', label: 'Action', type: 'select', options: [['1', 'Accorder'], ['', 'Retirer']] }], async v => { await post(`/api/admin/licenses/${l.id}/modules`, { module_id: +v.module, grant: !!v.grant }); toast('Modules mis à jour', 'ok'); }); } }, el('span', {}, 'Modules'))); });
  return page;
};

// Admin : ouvrir le panel d'un client + créer client et licence en une fois
const baseLic2 = PAGES['a-licenses'];
PAGES['a-licenses'] = async function () {
  const page = await baseLic2(); const [r, p] = await Promise.all([api('GET', '/api/admin/licenses'), api('GET', '/api/admin/plans')]);
  const rows = page.querySelectorAll('tbody tr'); (r.licenses || []).forEach((l, i) => { const cell = rows[i] && rows[i].querySelector('td:last-child .row'); if (cell) cell.prepend(el('button', { class: 'btn s p', onclick: () => openAsAdmin(l.id) }, el('span', {}, 'Ouvrir son panel'))); });
  const bar = page.querySelector('.top'); if (bar) bar.append(el('button', { class: 'btn p', onclick: () => ask('Nouveau client + licence', [{ name: 'email', label: 'E-mail du client' }, { name: 'username', label: 'Pseudo (facultatif)' }, { name: 'server_name', label: 'Nom de son serveur', value: 'Serveur de ' }, { name: 'plan_id', label: 'Offre', type: 'select', options: (p.plans || []).map(x => [x.id, `${x.name} (${x.price} €)`]) }, { name: 'days', label: 'Durée en jours (vide = selon l’offre, 0 = à vie)', type: 'number' }], async v => {
    const x = await post('/api/admin/onboard', v); if (!x.ok) { toast(x.error, 'bad'); return false; }
    const msg = `Voici ton accès au panel de ton serveur :\nAdresse : ${location.origin}\nE-mail : ${v.email}\n${x.new_account ? 'Mot de passe provisoire : ' + x.password : '(tu as déjà un compte : connecte-toi avec ton mot de passe)'}\n\nTa licence : ${x.key}\nDans ton panel : Licence & installation, tout est expliqué.`;
    modal('Accès créé : à envoyer au client', el('div', {}, el('p', { class: 'muted' }, 'Copie ce message et envoie-le au client (Discord, e-mail…).'), el('pre', { class: 'code', style: 'white-space:pre-wrap' }, msg)), close => [el('button', { class: 'btn p', onclick: () => copy(msg) }, el('span', {}, 'Copier le message')), el('button', { class: 'btn', onclick: () => { close(); render(); } }, el('span', {}, 'Fermer'))]);
    return true; }, 'Créer') }, el('span', {}, 'Nouveau client + licence')));
  return page;
};
const baseUsers = PAGES['a-users'];
