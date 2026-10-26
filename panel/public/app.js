'use strict';
// ───────── utilitaires ─────────
const $app = document.getElementById('app');
// 2 thèmes du panel : « sombre » (d'origine) et « clair » ; choix mémorisé dans ce navigateur
const getTheme = () => { try { return localStorage.getItem('aero_theme') === 'clair' ? 'clair' : 'sombre'; } catch (e) { return 'sombre'; } };
const setTheme = t => { document.documentElement.setAttribute('data-theme', t); try { localStorage.setItem('aero_theme', t); } catch (e) {} };
setTheme(getTheme());
function el(tag, attrs, ...kids) {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (v === false || v == null) continue;
    if (k === 'class') e.className = v; else if (k.startsWith('on')) e.addEventListener(k.slice(2), v); else if (k === 'value') e.value = v; else if (k === 'checked') e.checked = !!v; else e.setAttribute(k, v === true ? '' : v);
  }
  for (const c of kids.flat(Infinity)) { if (c == null || c === false) continue; e.append(c.nodeType ? c : document.createTextNode(String(c))); }
  return e;
}
const svg = d => { const s = document.createElementNS('http://www.w3.org/2000/svg', 'svg'); s.setAttribute('viewBox', '0 0 24 24'); const p = document.createElementNS('http://www.w3.org/2000/svg', 'path'); p.setAttribute('d', d); s.append(p); return s; };
const ICON = { home: 'M3 11l9-8 9 8v10a1 1 0 0 1-1 1h-5v-7H9v7H4a1 1 0 0 1-1-1z', users: 'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8M22 21v-2a4 4 0 0 0-3-3.9M16 3.1a4 4 0 0 1 0 7.8', bolt: 'M13 2L3 14h8l-1 8 10-12h-8z', term: 'M4 17l6-6-6-6M12 19h8', brush: 'M9 11l-6 6v4h4l6-6M14 6l4 4M20 4l-4 4-2-2 4-4z', shield: 'M12 2l8 3v6c0 5-3.5 9-8 11-4.5-2-8-6-8-11V5z', box: 'M21 8l-9-5-9 5v8l9 5 9-5zM3 8l9 5 9-5M12 13v8', key: 'M21 2l-2 2m-7.6 7.6a5 5 0 1 1-7 7 5 5 0 0 1 7-7zM15 8l3 3 3-3-3-3-3 3', user: 'M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2M12 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8', list: 'M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01', tag: 'M20 12l-8 8-9-9V3h8zM7 7h.01', out: 'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9', chart: 'M3 3v18h18M7 14l4-4 3 3 5-6', book: 'M4 19.5A2.5 2.5 0 0 1 6.5 17H20V3H6.5A2.5 2.5 0 0 0 4 5.5z', cart: 'M6 6h15l-2 9H8zM6 6L5 3H2M9 20a1 1 0 1 0 0-.01M18 20a1 1 0 1 0 0-.01', file: 'M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9zM14 3v6h6', db: 'M12 3c4.4 0 8 1.1 8 2.5S16.4 8 12 8 4 6.9 4 5.5 7.6 3 12 3zM4 5.5v13C4 19.9 7.6 21 12 21s8-1.1 8-2.5v-13M4 12c0 1.4 3.6 2.5 8 2.5s8-1.1 8-2.5', hook: 'M10 13a5 5 0 0 0 7 0l3-3a5 5 0 0 0-7-7l-1 1M14 11a5 5 0 0 0-7 0l-3 3a5 5 0 0 0 7 7l1-1', puzzle: 'M10 3a2 2 0 0 1 4 0v2h4a1 1 0 0 1 1 1v4h-2a2 2 0 0 0 0 4h2v4a1 1 0 0 1-1 1h-4v-2a2 2 0 0 0-4 0v2H6a1 1 0 0 1-1-1v-4h2a2 2 0 0 0 0-4H5V6a1 1 0 0 1 1-1h4z', bulb: 'M9 18h6M10 21h4M12 3a6 6 0 0 0-4 10.5c.8.8 1 1.5 1 2.5h6c0-1 .2-1.700 1-2.500A6 6 0 0 0 12 3z', sliders: 'M4 21v-7M4 10V3M12 21v-9M12 8V3M20 21v-5M20 12V3M1 14h6M9 8h6M17 16h6', help: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM9.500 9a2.500 2.500 0 1 1 3.500 2.300c-.6.300-1 .8-1 1.500M12 17h.01' };
function toast(msg, kind) { const t = el('div', { class: 'toast ' + (kind || '') }, msg); document.getElementById('toasts').append(t); setTimeout(() => t.remove(), 4200); }
async function api(method, url, body) {
  try { const r = await fetch(url, { method, headers: method === 'GET' ? {} : { 'content-type': 'application/json' }, body: method === 'GET' ? undefined : JSON.stringify(body || {}), credentials: 'same-origin' });
    if (r.status === 401 && !url.includes('/auth/')) { state.user = null; render(); return { ok: false, error: 'Session expirée' }; }
    return await r.json(); } catch (e) { return { ok: false, error: 'Connexion au panel impossible' }; }
}
const fmtDate = t => t ? new Date(t * 1000).toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'short' }) : '—';
const fmtDay = t => t ? new Date(t * 1000).toLocaleDateString('fr-FR') : 'Illimitée';
const ago = t => { if (!t) return 'jamais'; const s = Math.floor(Date.now() / 1000 - t); if (s < 60) return 'à l’instant'; if (s < 3600) return Math.floor(s / 60) + ' min'; if (s < 86400) return Math.floor(s / 3600) + ' h'; return Math.floor(s / 86400) + ' j'; };
const uptime = s => { s = +s || 0; const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60); return (d ? d + ' j ' : '') + h + ' h ' + m + ' min'; };
const money = n => (+n || 0).toLocaleString('fr-FR') + ' $';
function modal(title, body, actions) { const m = el('div', { class: 'modal', onclick: e => { if (e.target === m) m.remove(); } }, el('div', { class: 'box' }, el('h2', {}, title), body, el('div', { class: 'row', style: 'margin-top:16px;justify-content:flex-end' }, ...actions(() => m.remove())))); document.body.append(m); return m; }
function ask(title, fields, onOk, okLabel) {
  const inputs = fields.map(f => ({ f, i: f.type === 'select' ? el('select', {}, f.options.map(o => el('option', { value: o[0] }, o[1]))) : el('input', { type: f.type || 'text', value: f.value ?? '', placeholder: f.placeholder || '' }) }));
  modal(title, el('div', {}, inputs.map(({ f, i }) => [el('label', {}, f.label), i])), close => [el('button', { class: 'btn', onclick: close }, el('span', {}, 'Annuler')), el('button', { class: 'btn p', onclick: async () => { const v = {}; inputs.forEach(({ f, i }) => v[f.name] = i.value); if (await onOk(v) !== false) close(); } }, el('span', {}, okLabel || 'Valider'))]);
}
const confirmBox = (title, text, onOk, danger) => modal(title, el('p', {}, text), close => [el('button', { class: 'btn', onclick: close }, el('span', {}, 'Annuler')), el('button', { class: 'btn ' + (danger ? 'd' : 'p'), onclick: async () => { await onOk(); close(); } }, el('span', {}, 'Confirmer'))]);
const copy = async t => { try { await navigator.clipboard.writeText(t); toast('Copié', 'ok'); } catch (e) { toast('Copie impossible', 'bad'); } };

// ───────── état & routeur ─────────
const state = { user: null, servers: [], sid: +localStorage.getItem('aero_sid') || null, cfg: {}, timer: null };
const route = () => (location.hash.replace(/^#\/?/, '') || 'overview').split('/');
window.addEventListener('hashchange', render);
const go = p => { location.hash = '#/' + p; };
function curServer() { return state.servers.find(s => s.id === state.sid) || state.servers[0] || null; }
async function boot() {
  state.cfg = await api('GET', '/api/auth/config');
  const me = await api('GET', '/api/auth/me'); state.user = me.ok ? me.user : null;
  if (state.user) await loadServers();
  render();
}
async function openAsAdmin(id, page) { const r = await api('GET', '/api/servers/' + id); if (!r.ok) return toast(r.error, 'bad'); state.extraId = id; if (!state.servers.find(x => x.id === id)) state.servers.push(r.server); state.sid = id; localStorage.setItem('aero_sid', id); go(page || 'overview'); }
async function loadServers() {
  const r = await api('GET', '/api/servers'); state.servers = r.ok ? r.servers : [];
  if (state.extraId && !state.servers.find(x => x.id === state.extraId)) { const e = await api('GET', '/api/servers/' + state.extraId); if (e.ok) state.servers.push(e.server); }
  if (!state.servers.find(s => s.id === state.sid)) state.sid = state.servers[0] ? state.servers[0].id : null;
}
function setSid(id) { state.sid = id; localStorage.setItem('aero_sid', id); render(); }

// ───────── connexion / inscription ─────────
function authView(startMode) {
  let mode = startMode === 'register' && state.cfg.allowRegister !== false ? 'register' : 'login';
  const box = el('div', { class: 'box' });
  const draw = () => {
    const email = el('input', { type: 'email', placeholder: 'E-mail', autocomplete: 'email' }), pass = el('input', { type: 'password', placeholder: 'Mot de passe', autocomplete: mode === 'login' ? 'current-password' : 'new-password' }), name = el('input', { placeholder: 'Pseudo', autocomplete: 'username' });
    const err = el('div', { class: 'muted', style: 'color:var(--bad);min-height:20px;margin-top:8px' });
    const submit = async () => { const r = await api('POST', '/api/auth/' + mode, { email: email.value, password: pass.value, username: name.value }); if (!r.ok) { err.textContent = r.error || 'Erreur'; return; } const me = await api('GET', '/api/auth/me'); state.user = me.user; await loadServers(); go('overview'); render(); };
    const toggle = () => { mode = mode === 'login' ? 'register' : 'login'; history.replaceState(null, '', '#/' + mode); draw(); };
    [email, pass, name].forEach(i => i.addEventListener('keydown', e => { if (e.key === 'Enter') submit(); }));
    box.replaceChildren(...[el('img', { src: 'img/logo.png', alt: 'AERO' }), el('h1', {}, mode === 'login' ? 'Connexion' : 'Créer un compte'), el('p', { class: 'muted', style: 'margin:4px 0 14px' }, 'Gère ton serveur FiveM depuis ton espace client.'),
      mode === 'register' ? [el('label', {}, 'Pseudo'), name] : null, el('label', {}, 'E-mail'), email, el('label', {}, 'Mot de passe'), pass, err,
      el('div', { class: 'row', style: 'margin-top:10px' }, el('button', { class: 'btn p', onclick: submit }, el('span', {}, mode === 'login' ? 'Se connecter' : 'S’inscrire')),
        (state.cfg.allowRegister !== false || mode === 'register') ? el('a', { href: '#', onclick: e => { e.preventDefault(); toggle(); } }, mode === 'login' ? 'Créer un compte' : 'J’ai déjà un compte') : null)].flat().filter(Boolean));
    email.focus();
  };
  draw(); return el('div', { class: 'auth' }, el('a', { class: 'auth-back', href: '#/' }, '← Retour au site'), box);
}

// ───────── coque ─────────
function shell(content) {
  const [page] = route(); const isAdmin = state.user.role === 'admin'; const srv = curServer(); const lonely = !isAdmin && !state.servers.length;
  const item = (id, label, icon) => el('a', { class: 'nav' + (page === id ? ' on' : ''), href: '#/' + id }, svg(ICON[icon]), el('span', {}, label));
  const bottom = el('div', { class: 'bottom' }, item('account', 'Paramètres du compte', 'user'), item('support', 'Aide et support', 'help'), el('a', { class: 'nav', href: '#', onclick: e => { e.preventDefault(); setTheme(getTheme() === 'clair' ? 'sombre' : 'clair'); render(); } }, svg('M12 3a9 9 0 1 0 9 9 7 7 0 0 1-9-9z'), el('span', {}, getTheme() === 'clair' ? 'Thème : Clair → passer au sombre' : 'Thème : Sombre → passer au clair')), el('a', { class: 'nav', href: '#', onclick: async e => { e.preventDefault(); await api('POST', '/api/auth/logout', {}); state.user = null; state.servers = []; location.hash = '#/'; render(); } }, svg(ICON.out), el('span', {}, 'Déconnexion (' + state.user.username + ')')));
  const side = lonely ? el('aside', { class: 'side' }, el('img', { class: 'logo', src: 'img/logo.png', alt: 'AERO' }), el('div', { class: 'sec' }, 'Mon espace'), item('offers', 'Boutique', 'cart'), item('patchnotes', 'Patch notes', 'book'), bottom) : el('aside', { class: 'side' }, el('img', { class: 'logo', src: 'img/logo.png', alt: 'AERO' }),
    state.servers.length ? el('select', { onchange: e => setSid(+e.target.value), style: 'margin-bottom:6px' }, state.servers.map(s => el('option', { value: s.id, selected: s.id === (srv && srv.id) }, s.server_name + (s.online ? '' : ' (hors ligne)')))) : null,
    el('div', { class: 'sec' }, 'Général'), item('overview', 'Dashboard', 'home'), item('shop', 'Boutique', 'cart'), item('activity', 'Journal d’activités', 'list'), item('stats', 'Statistiques', 'chart'),
    el('div', { class: 'sec' }, 'Gestion'), item('theme', 'Personnalisation', 'brush'), item('settings', 'Réglages du serveur', 'sliders'), item('modules', 'Gestion des modules', 'puzzle'), item('players', 'Joueurs', 'users'), item('actions', 'Actions rapides', 'bolt'), item('access', 'Bans & whitelist', 'shield'), item('resources', 'Ressources', 'box'),
    el('div', { class: 'sec' }, 'Développement'), item('files', 'Fichiers', 'file'), item('backups', 'Sauvegardes', 'db'), item('console', 'Console', 'term'), item('webhooks', 'Webhooks', 'hook'),
    el('div', { class: 'sec' }, 'Informations'), item('patchnotes', 'Patch notes', 'book'), item('suggestions', 'Suggestions', 'bulb'), item('license', 'Licence & installation', 'key'), isAdmin ? null : item('offers', 'Offres & renouvellement', 'tag'),
    isAdmin ? [el('div', { class: 'sec' }, 'Administration'), item('a-overview', 'Vue d’ensemble', 'chart'), item('a-users', 'Clients', 'user'), item('a-licenses', 'Licences', 'key'), item('a-plans', 'Offres', 'tag'), item('a-orders', 'Commandes', 'cart'), item('a-modules', 'Modules', 'puzzle'), item('a-audit', 'Journal', 'list')] : null,
    bottom);
  return el('div', { class: 'layout' }, side, el('main', { class: 'main' }, content));
}
const needServer = () => {
  const box = el('div', { class: 'card empty' }, el('h2', {}, 'Ton compte est prêt'), el('p', {}, 'Il te manque encore ta licence : c’est elle qui relie ton serveur FiveM à ton panel personnel.'));
  if (state.user.role !== 'admin') box.append(el('p', { class: 'muted' }, 'L’équipe active ton serveur après ta demande. Tu recevras la réponse dans « Aide et support ».'),
    el('button', { class: 'btn p', onclick: async () => { const r = await api('POST', '/api/support/tickets', { subject: 'Activation de mon serveur', body: 'Bonjour, je viens de créer mon compte et je souhaite activer mon serveur (licence).' }); if (r.ok) { toast('Demande envoyée', 'ok'); go('support/' + r.id); } else toast(r.error, 'bad'); } }, el('span', {}, 'Demander l’activation de mon serveur')));
  else box.append(el('p', { class: 'muted' }, 'En tant qu’admin, crée une licence pour toi dans Administration → Licences, ou ouvre le panel d’un client depuis cette page.'));
  return box;
};
const statusPill = s => s.status !== 'active' ? el('span', { class: 'pill bad' }, s.status === 'suspended' ? 'Suspendue' : 'Révoquée') : s.expired ? el('span', { class: 'pill bad' }, 'Expirée') : s.online ? el('span', { class: 'pill ok' }, 'En ligne') : el('span', { class: 'pill warn' }, 'Hors ligne');
const head = (title, ...right) => el('div', { class: 'top' }, el('h1', {}, title), el('div', { class: 'grow' }), ...right);

// ───────── pages client ─────────
function lineChart(points) {
  const W = 800, H = 160, P = 24; const ns = 'http://www.w3.org/2000/svg'; const s = document.createElementNS(ns, 'svg'); s.setAttribute('viewBox', `0 0 ${W} ${H}`); s.setAttribute('class', 'chart'); s.setAttribute('preserveAspectRatio', 'none');
  if (points.length < 2) { const t = document.createElementNS(ns, 'text'); t.setAttribute('x', W / 2); t.setAttribute('y', H / 2); t.setAttribute('text-anchor', 'middle'); t.setAttribute('fill', '#8c93a3'); t.textContent = 'Pas encore assez de données'; s.append(t); return s; }
  const max = Math.max(5, ...points.map(p => p.players)), t0 = points[0].at, t1 = points[points.length - 1].at || t0 + 1;
  const xy = p => [P + (p.at - t0) / Math.max(1, t1 - t0) * (W - 2 * P), H - P - p.players / max * (H - 2 * P)];
  const d = points.map((p, i) => (i ? 'L' : 'M') + xy(p).map(n => n.toFixed(1)).join(' ')).join(' ');
  const area = document.createElementNS(ns, 'path'); area.setAttribute('d', d + ` L${xy(points[points.length - 1])[0]} ${H - P} L${P} ${H - P}Z`); area.setAttribute('fill', 'rgba(253,194,125,.14)');
  const line = document.createElementNS(ns, 'path'); line.setAttribute('d', d); line.setAttribute('fill', 'none'); line.setAttribute('stroke', '#fdc27d'); line.setAttribute('stroke-width', '2'); line.setAttribute('vector-effect', 'non-scaling-stroke');
  const lab = document.createElementNS(ns, 'text'); lab.setAttribute('x', 4); lab.setAttribute('y', 14); lab.setAttribute('fill', '#8c93a3'); lab.setAttribute('font-size', '11'); lab.textContent = 'max ' + max;
  s.append(area, line, lab); return s;
}
async function pOverview() {
  const s = curServer(); if (!s) return needServer();
  const [st, cm] = await Promise.all([api('GET', `/api/servers/${s.id}/stats?hours=24`), api('GET', `/api/servers/${s.id}/commands`)]);
  const stat = (l, v) => el('div', { class: 'card stat' }, el('small', {}, l), el('b', {}, v));
  return el('div', {}, head(s.server_name, statusPill(s)),
    el('div', { class: 'grid g4' }, stat('Joueurs', `${s.players} / ${s.max_players || '—'}`), stat('Uptime', s.online ? uptime(s.stats.uptime) : '—'), stat('Licence', s.expires_at ? 'jusqu’au ' + fmtDay(s.expires_at) : 'Illimitée'), stat('Dernier contact', ago(s.last_seen))),
    el('div', { class: 'card' }, el('h2', {}, 'Joueurs connectés (24 h)'), lineChart(st.points || [])),
    !s.online && s.status === 'active' ? el('div', { class: 'card' }, el('h2', {}, 'Serveur hors ligne'), el('p', {}, 'Le panel ne reçoit plus de nouvelles de ton serveur. Vérifie que la ressource ', el('b', {}, 'pickax_panel'), ' tourne et que la clé est correcte (page « Licence & installation »).')) : null,
    el('div', { class: 'card' }, el('h2', {}, 'Dernières actions'), commandsTable(cm.commands || [])));
}
function commandsTable(rows) {
  if (!rows.length) return el('div', { class: 'empty' }, 'Aucune action pour le moment');
  const pill = c => el('span', { class: 'pill ' + ({ done: 'ok', failed: 'bad', sent: 'warn', pending: '' }[c.status] || '') }, { done: 'Fait', failed: 'Échec', sent: 'Envoyé', pending: 'En attente' }[c.status] || c.status);
  return el('div', { class: 'tw' }, el('table', {}, el('thead', {}, el('tr', {}, ['Quand', 'Action', 'Détail', 'Par', 'Statut'].map(h => el('th', {}, h)))), el('tbody', {}, rows.map(c => el('tr', {}, el('td', {}, fmtDate(c.created_at)), el('td', {}, c.type), el('td', { class: 'mono' }, c.payload.slice(0, 80) + (c.result ? ' → ' + c.result : '')), el('td', {}, c.by_name || ''), el('td', {}, pill(c)))))));
}
async function sendCmd(type, payload, okMsg) { const s = curServer(); const r = await api('POST', `/api/servers/${s.id}/command`, { type, payload }); if (r.ok) toast(okMsg || 'Action envoyée (exécutée dans quelques secondes)', 'ok'); else toast(r.error, 'bad'); return r; }
async function pPlayers() {
  const s = curServer(); if (!s) return needServer();
  const r = await api('GET', `/api/servers/${s.id}/players`); const all = r.players || [];
  const q = el('input', { placeholder: 'Rechercher (nom, ID, job, identifiant)…', style: 'max-width:340px' }); const body = el('tbody');
  const draw = () => { const t = q.value.toLowerCase(); const rows = all.filter(p => !t || [p.name, p.id, p.job, p.identifier].join(' ').toLowerCase().includes(t));
    body.replaceChildren(...rows.map(p => el('tr', {}, el('td', {}, p.id), el('td', {}, p.name), el('td', {}, `${p.job} (${p.grade})`), el('td', {}, p.group), el('td', {}, money(p.money)), el('td', {}, money(p.bank)), el('td', {}, p.ping + ' ms'), el('td', {}, el('button', { class: 'btn s', onclick: () => playerMenu(p) }, el('span', {}, 'Gérer'))))));
    if (!rows.length) body.replaceChildren(el('tr', {}, el('td', { colspan: 8, class: 'empty' }, s.online ? 'Aucun joueur' : 'Serveur hors ligne')));
  };
  q.addEventListener('input', draw); draw();
  return el('div', {}, head('Joueurs', q, el('span', { class: 'pill acc' }, all.length + ' en ligne')), el('div', { class: 'card tw' }, el('table', {}, el('thead', {}, el('tr', {}, ['ID', 'Nom', 'Métier', 'Groupe', 'Liquide', 'Banque', 'Ping', ''].map(h => el('th', {}, h)))), body)));
}
function playerMenu(p) {
  const btn = (label, fn, cls) => el('button', { class: 'btn ' + (cls || ''), style: 'margin:4px', onclick: fn }, el('span', {}, label));
  const m = modal(`${p.name} (ID ${p.id})`, el('div', {}, el('p', { class: 'muted mono' }, p.identifier), el('div', { style: 'margin-top:10px' },
    btn('Expulser', () => { m.remove(); ask('Expulser', [{ name: 'reason', label: 'Raison', value: 'Expulsé par le staff' }], v => sendCmd('kick', { id: p.id, reason: v.reason })); }),
    btn('Bannir', () => { m.remove(); ask('Bannir ' + p.name, [{ name: 'reason', label: 'Raison', value: 'Banni' }, { name: 'days', label: 'Durée en jours (0 = définitif)', type: 'number', value: 0 }], v => sendCmd('ban', { id: p.id, identifier: p.identifier, name: p.name, reason: v.reason, days: +v.days }), 'Bannir'); }, 'd'),
    btn('Réanimer', () => { sendCmd('revive', { id: p.id }); m.remove(); }),
    btn('Message privé', () => { m.remove(); ask('Message à ' + p.name, [{ name: 'message', label: 'Message' }], v => sendCmd('message', { id: p.id, message: v.message })); }),
    btn('Changer de métier', () => { m.remove(); ask('Métier de ' + p.name, [{ name: 'job', label: 'Nom du job', value: p.job }, { name: 'grade', label: 'Grade', type: 'number', value: 0 }], v => sendCmd('setjob', { id: p.id, job: v.job, grade: +v.grade })); }),
    btn('Changer de groupe', () => { m.remove(); ask('Groupe de ' + p.name, [{ name: 'group', label: 'Groupe (user, admin…)', value: p.group }], v => sendCmd('setgroup', { id: p.id, group: v.group })); }),
    btn('Donner de l’argent', () => { m.remove(); ask('Argent pour ' + p.name, [{ name: 'account', label: 'Compte', type: 'select', options: [['money', 'Liquide'], ['bank', 'Banque'], ['black_money', 'Argent sale']] }, { name: 'amount', label: 'Montant (négatif = retirer)', type: 'number', value: 1000 }], v => sendCmd('givemoney', { id: p.id, account: v.account, amount: +v.amount })); }),
    btn('Donner un objet', () => { m.remove(); ask('Objet pour ' + p.name, [{ name: 'item', label: 'Nom de l’objet (ex : bread)' }, { name: 'count', label: 'Quantité', type: 'number', value: 1 }], v => sendCmd('giveitem', { id: p.id, item: v.item, count: +v.count })); }))),
    close => [el('button', { class: 'btn', onclick: close }, el('span', {}, 'Fermer'))]);
}
async function pActions() {
  const s = curServer(); if (!s) return needServer(); const motd = (await api('GET', `/api/servers/${s.id}/docs/motd`)).value || { text: '', enabled: false };
  const msg = el('input', { placeholder: 'Message à tous les joueurs…', maxlength: 200 }), res = el('input', { placeholder: 'Nom de la ressource (ex : pickax_jobbuilder)' });
  const mt = el('input', { value: motd.text, placeholder: 'Message affiché à la connexion', maxlength: 300 }), me = el('input', { type: 'checkbox', checked: motd.enabled });
  const ek = el('select', {}, [['', 'Toutes les ressources'], ['farm', 'Agriculture (farm)'], ['vehicules', 'Véhicules'], ['shop', 'Boutiques']].map(o => el('option', { value: o[0] }, o[1]))); const es = el('input', { type: 'number', value: -20, step: 5 }), eh = el('input', { type: 'number', value: 6 });
  return el('div', {}, head('Actions rapides'),
    el('div', { class: 'grid g2' },
      el('div', { class: 'card' }, el('h2', {}, 'Annonce à tous les joueurs'), msg, el('div', { style: 'margin-top:10px' }, el('button', { class: 'btn p', onclick: async () => { if ((await sendCmd('announce', { message: msg.value })).ok) msg.value = ''; } }, el('span', {}, 'Envoyer')))),
      el('div', { class: 'card' }, el('h2', {}, 'Redémarrer une ressource'), res, el('div', { style: 'margin-top:10px' }, el('button', { class: 'btn p', onclick: () => confirmBox('Redémarrer', 'Redémarrer « ' + res.value + ' » ? Les joueurs concernés peuvent être déconnectés de l’interface.', () => sendCmd('restart_resource', { resource: res.value })) }, el('span', {}, 'Redémarrer')))),
      el('div', { class: 'card' }, el('h2', {}, 'Message de bienvenue'), mt, el('div', { class: 'row', style: 'margin-top:10px' }, el('label', { style: 'margin:0;display:flex;gap:8px;align-items:center' }, me, 'Activé'), el('button', { class: 'btn p', onclick: async () => { const r = await api('PUT', `/api/servers/${s.id}/docs/motd`, { value: { text: mt.value, enabled: me.checked } }); toast(r.ok ? 'Enregistré' : r.error, r.ok ? 'ok' : 'bad'); } }, el('span', {}, 'Enregistrer')))),
      el('div', { class: 'card' }, el('h2', {}, 'Événement économique'), el('p', { class: 'muted' }, 'Fait varier les prix (ex : −20 % pendant 6 h).'), el('label', {}, 'Secteur'), ek, el('div', { class: 'row' }, el('div', { class: 'grow' }, el('label', {}, 'Variation en %'), es), el('div', { class: 'grow' }, el('label', {}, 'Durée (h)'), eh)),
        el('div', { class: 'row', style: 'margin-top:10px' }, el('button', { class: 'btn p', onclick: () => sendCmd('economy_event', { key: ek.value || 'all', swing: (+es.value) / 100, hours: +eh.value }) }, el('span', {}, 'Lancer')), el('button', { class: 'btn', onclick: () => sendCmd('economy_reset', { key: ek.value }) }, el('span', {}, 'Réinitialiser'))))),
    el('div', { class: 'card' }, el('h2', {}, 'Historique des actions'), commandsTable((await api('GET', `/api/servers/${s.id}/commands`)).commands || [])));
}
async function pConsole() {
  const s = curServer(); if (!s) return needServer(); let last = 0, level = '';
  const box = el('div', { class: 'console' }), sel = el('select', { style: 'max-width:180px', onchange: () => { level = sel.value; last = 0; box.replaceChildren(); load(); } }, [['', 'Tous les niveaux'], ['info', 'Info'], ['warn', 'Avertissements'], ['error', 'Erreurs'], ['staff', 'Actions staff']].map(o => el('option', { value: o[0] }, o[1])));
  const load = async () => { const r = await api('GET', `/api/servers/${s.id}/logs?after=${last}${level ? '&level=' + level : ''}`); if (!r.ok) return; const bottom = box.scrollTop + box.clientHeight >= box.scrollHeight - 30; for (const l of r.logs) { last = Math.max(last, l.id); box.append(el('div', { class: l.level }, el('span', { class: 't' }, new Date(l.at * 1000).toLocaleTimeString('fr-FR') + ' '), `[${l.source || l.level}] ${l.message}`)); } if (bottom || !last) box.scrollTop = box.scrollHeight; };
  await load(); state.timer = setInterval(load, 4000);
  return el('div', {}, head('Console & logs', sel), el('div', { class: 'card' }, box, el('p', { class: 'muted', style: 'margin-top:8px' }, 'Les logs sont envoyés par la ressource pickax_panel (erreurs, actions staff, connexions).')));
}
async function pTheme() {
  const s = curServer(); if (!s) return needServer(); const d = await api('GET', `/api/servers/${s.id}/docs/theme`); const v = d.value || { AccentColor: '#fdc27d', InventoryColor: '', ServerName: s.server_name, ServerShortName: 'AERO', ServerTagline: '', ServerDiscord: '', ServerLogo: 'logo.png' };
  const f = {}; const field = (k, label, type) => { f[k] = el('input', { type: type || 'text', value: v[k] || '' }); return [el('label', {}, label), f[k]]; };
  const prev = el('div', { class: 'card', style: 'margin:0' }); const drawPrev = () => { prev.style.borderLeftColor = f.AccentColor.value; prev.replaceChildren(el('h2', { style: 'color:' + f.AccentColor.value }, f.ServerShortName.value || 'Nom court'), el('p', {}, f.ServerName.value), el('p', { class: 'muted' }, f.ServerTagline.value), el('p', { class: 'muted' }, f.ServerDiscord.value)); };
  const col = [field('AccentColor', 'Couleur principale', 'color'), field('InventoryColor', 'Couleur de l’inventaire (vide = couleur principale)', 'color')];
  const dr = ((await api('GET', `/api/servers/${s.id}/drive`)).files || []);
  const MARKERS = [[23, 'Cercle plat épais (par défaut)'], [25, 'Cercle plat fin'], [27, 'Cercle fléché'], [1, 'Cylindre vertical'], [9, 'Anneau'], [2, 'Chevron épais'], [3, 'Chevron fin'], [20, 'Chevron vers le haut'], [29, 'Symbole dollar'], [36, 'Symbole voiture'], [0, 'Cône inversé']];
  const BLIPCOL = [[-1, 'Couleur propre à chaque catégorie'], [0, 'Blanc'], [1, 'Rouge'], [2, 'Vert'], [3, 'Bleu'], [5, 'Jaune'], [7, 'Violet'], [17, 'Orange']];
  const sel = (opts, cur) => el('select', {}, opts.map(o => el('option', { value: o[0], selected: String(o[0]) === String(cur) }, o[1])));
  const pick = (target) => el('select', { onchange: e => { if (e.target.value) f[target].value = e.target.value; e.target.value = ''; drawPrev(); } }, [el('option', { value: '' }, '— Choisir une image de mon Drive —'), ...dr.map(x => el('option', { value: x.url }, x.name))]);
  f.MenuBanner = el('input', { value: v.MenuBanner || '', placeholder: 'https://… (vide = bannière d’origine)' });
  f.LoadingBanner = el('input', { value: v.LoadingBanner || '', placeholder: 'https://… (vide = fond d’origine)' });
  f.MarkerType = sel(MARKERS, v.MarkerType ?? 23);
  const autoCol = el('input', { type: 'checkbox', checked: !v.MarkerColor }); const colIn = el('input', { type: 'color', value: v.MarkerColor || '#fdc27d' });
  f.MarkerColor = { get value() { return autoCol.checked ? '' : colIn.value; } };
  f.MarkerAlpha = el('input', { type: 'number', min: 0, max: 255, value: v.MarkerAlpha ?? 150 });
  f.MarkerSize = el('input', { type: 'number', min: 0.1, max: 5, step: 0.1, value: v.MarkerSize ?? 1 });
  f.BlipScale = el('input', { type: 'number', min: 0.1, max: 3, step: 0.1, value: v.BlipScale ?? 0.5 });
  f.BlipColor = sel(BLIPCOL, v.BlipColor ?? -1);
  f.Design = el('select', {}, [['arcade', 'Arcade (nouveau style)'], ['ancien', 'Classique (ancien style)']].map(o => el('option', { value: o[0], selected: o[0] === (v.Design || 'arcade') }, o[1])));
  const collect = () => { const val = {}; for (const k in f) val[k] = f[k].value; return val; };
  const save = async (core, msg) => { const r = await api('PUT', `/api/servers/${s.id}/docs/theme`, { value: collect() }); if (r.ok) await sendCmd('apply_theme', { core }, msg); else toast(r.error, 'bad'); };
  const isOld = (v.Design || 'arcade') === 'ancien';
  const page = el('div', {}, head('Thème & identité',
    el('button', { class: 'btn', title: 'Change le style de TOUS les menus, HUD, notifications, inventaire, builders…', onclick: () => confirmBox(isOld ? 'Passer au style Arcade' : 'Revenir à l’ancien style', isOld ? 'Tous les menus, HUD, notifications, builders et l’inventaire passent au nouveau style Arcade (reconnexion des joueurs pour tout voir).' : 'Tous les menus, HUD, notifications, builders et l’inventaire retrouvent leur style d’origine (reconnexion des joueurs pour tout voir). Tu peux revenir au nouveau style quand tu veux.', async () => { f.Design.value = isOld ? 'arcade' : 'ancien'; await save(false, 'Style changé : visible après reconnexion des joueurs'); setTimeout(render, 1500); }) }, el('span', {}, isOld ? 'Passer au style Arcade' : 'Revenir à l’ancien style')),
    el('button', { class: 'btn', title: 'Applique partout (loading, chat, markers…) en redémarrant pickax_core : coupe les menus ouverts quelques secondes', onclick: () => confirmBox('Appliquer partout', 'Le thème est enregistré puis pickax_core redémarre (écran de chargement, chat, markers, builders…). Les menus ouverts des joueurs sont coupés quelques secondes.', () => save(true, 'Thème enregistré : redémarrage du core dans quelques secondes')) }, el('span', {}, 'Enregistrer et appliquer partout')),
    el('button', { class: 'btn p', onclick: () => save(false, 'Thème enregistré : interfaces mises à jour (reconnexion pour tout voir)') }, el('span', {}, 'Enregistrer'))),
    el('div', { class: 'grid g2' }, el('div', { class: 'card' }, col, el('label', {}, 'Style des interfaces'), f.Design, field('ServerName', 'Nom du serveur'), field('ServerShortName', 'Nom court'), field('ServerTagline', 'Slogan'), field('ServerDiscord', 'Lien Discord'), field('ServerLogo', 'Logo (fichier dans pickax_theme/logo/ ou lien https)'), el('p', { class: 'muted', style: 'margin-top:10px' }, 'Pas de guillemets. Le thème est appliqué automatiquement à tous les menus, HUD, notifications et inventaire.')), el('div', {}, el('h2', {}, 'Aperçu'), prev)));
  page.append(el('div', { class: 'grid g2' },
    el('div', { class: 'card' }, el('h2', {}, 'Bannières'), el('p', { class: 'muted' }, 'Envoie tes images dans le Drive (plus bas), puis choisis-les ici. Le menu F5 et l’écran de chargement les affichent après reconnexion (redémarrage du core pour le chargement).'),
      el('label', {}, 'Bannière du menu F5'), f.MenuBanner, pick('MenuBanner'), el('label', {}, 'Image de l’écran de chargement'), f.LoadingBanner, pick('LoadingBanner')),
    el('div', { class: 'card' }, el('h2', {}, 'Markers et blips (tout le serveur d’un coup)'), el('p', { class: 'muted' }, 'S’applique à tous les markers et blips des builders et du core. Appliquer avec « Enregistrer et appliquer partout ».'),
      el('label', {}, 'Type de marker'), f.MarkerType, el('label', {}, 'Couleur des markers'), el('div', { class: 'row' }, colIn, el('label', { style: 'margin:0;display:flex;gap:6px;align-items:center;text-transform:none;letter-spacing:0' }, autoCol, 'Automatique (couleur principale)')),
      el('div', { class: 'row' }, el('div', { class: 'grow' }, el('label', {}, 'Opacité (0-255)'), f.MarkerAlpha), el('div', { class: 'grow' }, el('label', {}, 'Taille'), f.MarkerSize)),
      el('label', {}, 'Taille des blips (0.3 petit … 1.2 grand)'), f.BlipScale, el('label', {}, 'Couleur des blips'), f.BlipColor)));
  Object.values(f).forEach(i => i.addEventListener && i.addEventListener('input', drawPrev)); drawPrev(); return page;
}
async function pAccess() {
  const s = curServer(); if (!s) return needServer(); const [b, w] = await Promise.all([api('GET', `/api/servers/${s.id}/docs/bans`), api('GET', `/api/servers/${s.id}/docs/whitelist`)]);
  let bans = b.value || [], wl = w.value || [];
  const saveBans = async () => { const r = await api('PUT', `/api/servers/${s.id}/docs/bans`, { value: bans }); toast(r.ok ? 'Bans enregistrés' : r.error, r.ok ? 'ok' : 'bad'); };
  const saveWl = async () => { const r = await api('PUT', `/api/servers/${s.id}/docs/whitelist`, { value: wl }); toast(r.ok ? 'Whitelist enregistrée' : r.error, r.ok ? 'ok' : 'bad'); };
  const bb = el('tbody'), wb = el('tbody'); const drawB = () => bb.replaceChildren(...(bans.length ? bans.map((x, i) => el('tr', {}, el('td', {}, x.name || '—'), el('td', { class: 'mono' }, x.identifier), el('td', {}, x.reason), el('td', {}, x.until ? fmtDay(x.until) : 'Définitif'), el('td', {}, el('button', { class: 'btn s d', onclick: async () => { bans.splice(i, 1); drawB(); await saveBans(); } }, el('span', {}, 'Débannir'))))) : [el('tr', {}, el('td', { colspan: 5, class: 'empty' }, 'Aucun ban'))]));
  const drawW = () => wb.replaceChildren(...(wl.length ? wl.map((x, i) => el('tr', {}, el('td', { class: 'mono' }, x), el('td', {}, el('button', { class: 'btn s d', onclick: async () => { wl.splice(i, 1); drawW(); await saveWl(); } }, el('span', {}, 'Retirer'))))) : [el('tr', {}, el('td', { colspan: 2, class: 'empty' }, 'Whitelist vide (désactivée)'))]));
  drawB(); drawW();
  return el('div', {}, head('Bans & whitelist'), el('p', { class: 'muted', style: 'margin-bottom:14px' }, 'Les listes sont synchronisées sur ton serveur (identifiants license: / steam: / discord:). Whitelist vide = tout le monde peut entrer.'),
    el('div', { class: 'card' }, el('div', { class: 'row' }, el('h2', { style: 'margin:0' }, 'Bannis'), el('div', { class: 'grow' }), el('button', { class: 'btn p', onclick: () => ask('Ajouter un ban', [{ name: 'identifier', label: 'Identifiant (ex : license:abc…)' }, { name: 'name', label: 'Nom' }, { name: 'reason', label: 'Raison', value: 'Banni' }, { name: 'days', label: 'Jours (0 = définitif)', type: 'number', value: 0 }], async v => { if (!v.identifier.trim()) { toast('Identifiant requis', 'bad'); return false; } bans.push({ identifier: v.identifier.trim(), name: v.name, reason: v.reason, until: +v.days ? Math.floor(Date.now() / 1000) + v.days * 86400 : 0, at: Math.floor(Date.now() / 1000) }); drawB(); await saveBans(); }) }, el('span', {}, 'Ajouter'))), el('div', { class: 'tw' }, el('table', {}, el('thead', {}, el('tr', {}, ['Nom', 'Identifiant', 'Raison', 'Fin', ''].map(h => el('th', {}, h)))), bb))),
    el('div', { class: 'card' }, el('div', { class: 'row' }, el('h2', { style: 'margin:0' }, 'Whitelist'), el('div', { class: 'grow' }), el('button', { class: 'btn p', onclick: () => ask('Ajouter à la whitelist', [{ name: 'identifier', label: 'Identifiant (license:…)' }], async v => { if (!v.identifier.trim()) return false; if (!wl.includes(v.identifier.trim())) wl.push(v.identifier.trim()); drawW(); await saveWl(); }) }, el('span', {}, 'Ajouter'))), el('div', { class: 'tw' }, el('table', {}, el('thead', {}, el('tr', {}, el('th', {}, 'Identifiant'), el('th', {}, ''))), wb))));
}
async function pResources() {
  const s = curServer(); if (!s) return needServer(); const r = await api('GET', `/api/servers/${s.id}/resources`); const q = el('input', { placeholder: 'Filtrer…', style: 'max-width:300px' }); const body = el('tbody');
  const draw = () => body.replaceChildren(...(r.resources || []).filter(x => x.name.includes(q.value.toLowerCase())).map(x => el('tr', {}, el('td', {}, x.name), el('td', {}, el('span', { class: 'pill ' + (x.state === 'started' ? 'ok' : 'bad') }, x.state)), el('td', {}, el('button', { class: 'btn s', onclick: () => confirmBox('Redémarrer', 'Redémarrer ' + x.name + ' ?', () => sendCmd('restart_resource', { resource: x.name })) }, el('span', {}, 'Redémarrer'))))));
  q.addEventListener('input', draw); draw(); return el('div', {}, head('Ressources', q), el('div', { class: 'card tw' }, el('table', {}, el('thead', {}, el('tr', {}, ['Ressource', 'État', ''].map(h => el('th', {}, h)))), body)));
}
async function pLicense() {
  const s = curServer(); if (!s) return needServer(); const url = location.origin;
  return el('div', {}, head('Licence & installation', statusPill(s)),
    el('div', { class: 'card' }, el('h2', {}, 'Ma clé de licence'), el('div', { class: 'key' }, s.key), el('div', { class: 'row', style: 'margin-top:10px' },
      el('button', { class: 'btn', onclick: () => copy(s.key) }, el('span', {}, 'Copier')), el('button', { class: 'btn', onclick: () => ask('Renommer', [{ name: 'server_name', label: 'Nom du serveur', value: s.server_name }], async v => { const r = await api('POST', `/api/servers/${s.id}/rename`, v); if (!r.ok) { toast(r.error, 'bad'); return false; } await loadServers(); render(); }) }, el('span', {}, 'Renommer')),
      el('button', { class: 'btn', onclick: () => confirmBox('Délier l’adresse IP', 'La licence pourra être utilisée depuis une nouvelle machine (à faire lors d’un changement d’hébergeur).', async () => { await api('POST', `/api/servers/${s.id}/unbind`, {}); await loadServers(); toast('Licence déliée', 'ok'); render(); }) }, el('span', {}, 'Changer de machine')),
      el('button', { class: 'btn d', onclick: () => confirmBox('Régénérer la clé', 'L’ancienne clé cessera de fonctionner immédiatement. Pense à mettre à jour ton serveur.', async () => { const r = await api('POST', `/api/servers/${s.id}/rotate-key`, {}); if (r.ok) { await loadServers(); toast('Nouvelle clé générée', 'ok'); render(); } }, true) }, el('span', {}, 'Régénérer'))),
      el('p', { class: 'muted', style: 'margin-top:10px' }, `Plan : ${s.plan || '—'} · Expiration : ${fmtDay(s.expires_at)} · Adresse liée : ${s.bound_ip || 'aucune (se lie à la première connexion)'} · Version de la ressource : ${s.version || '—'}`)),
    el('div', { class: 'card' }, el('h2', {}, 'Installer la ressource sur ton serveur'), el('ol', { class: 'steps' },
      el('li', {}, 'Copie le dossier ', el('b', {}, 'pickax_panel'), ' dans ', el('span', { class: 'mono' }, 'resources/[dev]/'), '.'),
      el('li', {}, 'Ajoute ces deux lignes dans ton ', el('span', { class: 'mono' }, 'server.cfg'), ' (avant ', el('span', { class: 'mono' }, 'ensure pickax_panel'), ') :', el('pre', { class: 'code' }, `set aero_panel_url "${url}"\nset aero_panel_key "${s.key}"\nensure pickax_panel`)),
      el('li', {}, 'Redémarre le serveur : le statut passe sur « En ligne » en moins de 30 secondes.'))));
}
function pAccount() {
  const cur = el('input', { type: 'password', autocomplete: 'current-password' }), nw = el('input', { type: 'password', autocomplete: 'new-password' });
  return el('div', {}, head('Mon compte'), el('div', { class: 'card', style: 'max-width:480px' }, el('p', {}, el('b', {}, state.user.username), ' · ', state.user.email), el('p', { class: 'muted' }, 'Inscrit le ' + fmtDay(state.user.created_at)), el('h2', { style: 'margin-top:16px' }, 'Changer de mot de passe'), el('label', {}, 'Mot de passe actuel'), cur, el('label', {}, 'Nouveau mot de passe (8 caractères min.)'), nw,
    el('div', { style: 'margin-top:12px' }, el('button', { class: 'btn p', onclick: async () => { const r = await api('POST', '/api/auth/password', { current: cur.value, next: nw.value }); toast(r.ok ? 'Mot de passe modifié' : r.error, r.ok ? 'ok' : 'bad'); if (r.ok) { cur.value = nw.value = ''; } } }, el('span', {}, 'Modifier')))));
}

// ───────── pages admin ─────────
async function aOverview() {
  const o = await api('GET', '/api/admin/overview'); const stat = (l, v) => el('div', { class: 'card stat' }, el('small', {}, l), el('b', {}, v));
  return el('div', {}, head('Vue d’ensemble'), el('div', { class: 'grid g4' }, stat('Clients', o.users), stat('Licences actives', `${o.active} / ${o.licenses}`), stat('Serveurs en ligne', o.online), stat('Joueurs connectés', o.players)),
    el('div', { class: 'grid g2' }, el('div', { class: 'card' }, el('h2', {}, 'Licences qui expirent (7 jours)'), (o.expiring || []).length ? el('table', {}, el('tbody', {}, o.expiring.map(x => el('tr', {}, el('td', {}, x.server_name), el('td', { class: 'muted' }, x.email || '—'), el('td', {}, fmtDay(x.expires_at)))))) : el('div', { class: 'empty' }, 'Aucune')), el('div', { class: 'card' }, el('h2', {}, 'Chiffre d’affaires (selon les offres attribuées)'), el('div', { class: 'stat' }, el('b', {}, money(o.revenue).replace('$', '€'))))));
}
async function aUsers() {
  const r = await api('GET', '/api/admin/users');
  const act = (u, body, msg) => async () => { const x = await api('PATCH', '/api/admin/users/' + u.id, body); toast(x.ok ? msg : x.error, x.ok ? 'ok' : 'bad'); render(); };
  return el('div', {}, head('Clients', el('button', { class: 'btn p', onclick: () => ask('Nouveau client', [{ name: 'email', label: 'E-mail' }, { name: 'username', label: 'Pseudo' }, { name: 'password', label: 'Mot de passe (8 min.)', type: 'password' }], async v => { const x = await api('POST', '/api/admin/users', v); if (!x.ok) { toast(x.error, 'bad'); return false; } toast('Client créé', 'ok'); render(); }) }, el('span', {}, 'Nouveau client'))),
    el('div', { class: 'card tw' }, el('table', {}, el('thead', {}, el('tr', {}, ['#', 'E-mail', 'Pseudo', 'Rôle', 'Licences', 'Inscrit', 'Dernière connexion', ''].map(h => el('th', {}, h)))), el('tbody', {}, (r.users || []).map(u => el('tr', {}, el('td', {}, u.id), el('td', {}, u.email), el('td', {}, u.username), el('td', {}, el('span', { class: 'pill ' + (u.role === 'admin' ? 'acc' : '') }, u.role), u.disabled ? el('span', { class: 'pill bad', style: 'margin-left:6px' }, 'désactivé') : null), el('td', {}, u.licenses), el('td', {}, fmtDay(u.created_at)), el('td', {}, ago(u.last_login)),
      el('td', {}, el('div', { class: 'row' }, el('button', { class: 'btn s', onclick: act(u, { disabled: !u.disabled }, u.disabled ? 'Réactivé' : 'Désactivé') }, el('span', {}, u.disabled ? 'Réactiver' : 'Désactiver')), el('button', { class: 'btn s d', onclick: () => ask('Supprimer ' + u.email, [{ name: 'lic', label: 'Ses licences (' + (u.licenses || 0) + ')', type: 'select', options: [['keep', 'Les conserver (sans propriétaire)'], ['del', 'Les supprimer aussi']] }], async v => { const x = await api('DELETE', '/api/admin/users/' + u.id, { delete_licenses: v.lic === 'del' }); toast(x.ok ? 'Compte supprimé' : x.error, x.ok ? 'ok' : 'bad'); if (x.ok) render(); return x.ok; }, 'Supprimer définitivement') }, el('span', {}, 'Supprimer')), el('button', { class: 'btn s', onclick: () => ask('Nouveau mot de passe', [{ name: 'password', label: 'Mot de passe', type: 'password' }], async v => { const x = await api('PATCH', '/api/admin/users/' + u.id, v); toast(x.ok ? 'Mot de passe changé' : x.error, x.ok ? 'ok' : 'bad'); return x.ok; }) }, el('span', {}, 'Mot de passe')), el('button', { class: 'btn s', onclick: act(u, { role: u.role === 'admin' ? 'client' : 'admin' }, 'Rôle modifié') }, el('span', {}, u.role === 'admin' ? 'Retirer admin' : 'Passer admin'))))))))));
}
async function aLicenses() {
  const [r, p, u] = await Promise.all([api('GET', '/api/admin/licenses'), api('GET', '/api/admin/plans'), api('GET', '/api/admin/users')]);
  const patch = async (l, body, msg) => { const x = await api('PATCH', '/api/admin/licenses/' + l.id, body); toast(x.ok ? msg : x.error, x.ok ? 'ok' : 'bad'); render(); };
  const st = l => l.status !== 'active' ? el('span', { class: 'pill bad' }, l.status) : (l.expires_at && l.expires_at < Date.now() / 1000) ? el('span', { class: 'pill bad' }, 'expirée') : l.online ? el('span', { class: 'pill ok' }, 'en ligne') : el('span', { class: 'pill warn' }, 'hors ligne');
  return el('div', {}, head('Licences', el('button', { class: 'btn p', onclick: () => ask('Nouvelle licence', [{ name: 'user_id', label: 'Client', type: 'select', options: [['', '— aucun —'], ...(u.users || []).map(x => [x.id, x.email])] }, { name: 'plan_id', label: 'Offre', type: 'select', options: (p.plans || []).map(x => [x.id, `${x.name} (${x.price} €)`]) }, { name: 'server_name', label: 'Nom du serveur', value: 'Mon serveur' }, { name: 'days', label: 'Durée en jours (vide = selon l’offre, 0 = à vie)', type: 'number' }], async v => { const x = await api('POST', '/api/admin/licenses', v); if (!x.ok) { toast(x.error, 'bad'); return false; } toast('Licence créée : ' + x.key, 'ok'); render(); }) }, el('span', {}, 'Nouvelle licence'))),
    el('div', { class: 'card tw' }, el('table', {}, el('thead', {}, el('tr', {}, ['#', 'Serveur', 'Client', 'Offre', 'Clé', 'Expire', 'Statut', 'IP liée', ''].map(h => el('th', {}, h)))), el('tbody', {}, (r.licenses || []).map(l => el('tr', {}, el('td', {}, l.id), el('td', {}, l.server_name), el('td', { class: 'muted' }, l.owner || '—'), el('td', {}, l.plan || '—'), el('td', { class: 'mono' }, el('a', { href: '#', onclick: e => { e.preventDefault(); copy(l.key); } }, l.key.slice(0, 16) + '…')), el('td', {}, fmtDay(l.expires_at)), el('td', {}, st(l)), el('td', { class: 'mono' }, l.bound_ip || '—'),
      el('td', {}, el('div', { class: 'row' }, el('button', { class: 'btn s', onclick: () => ask('Prolonger', [{ name: 'd', label: 'Jours à ajouter', type: 'number', value: 30 }], v => patch(l, { extend_days: +v.d }, 'Prolongée')) }, el('span', {}, '+ jours')), el('button', { class: 'btn s', onclick: () => patch(l, { status: l.status === 'active' ? 'suspended' : 'active' }, l.status === 'active' ? 'Suspendue' : 'Réactivée') }, el('span', {}, l.status === 'active' ? 'Suspendre' : 'Réactiver')), el('button', { class: 'btn s', onclick: () => patch(l, { unbind: true }, 'IP déliée') }, el('span', {}, 'Délier IP')), el('button', { class: 'btn s d', onclick: () => confirmBox('Supprimer', 'Supprimer définitivement la licence #' + l.id + ' ?', async () => { await api('DELETE', '/api/admin/licenses/' + l.id); render(); }, true) }, el('span', {}, 'Suppr.'))))))))));
}
async function aPlans() {
  const r = await api('GET', '/api/admin/plans'); const form = (p) => [{ name: 'name', label: 'Nom', value: p ? p.name : '' }, { name: 'price', label: 'Prix (€)', type: 'number', value: p ? p.price : 0 }, { name: 'days', label: 'Durée en jours (0 = à vie)', type: 'number', value: p ? p.days : 30 }, { name: 'max_players', label: 'Joueurs max (0 = illimité)', type: 'number', value: p ? p.max_players : 0 }, { name: 'description', label: 'Description', value: p ? p.description : '' }];
  return el('div', {}, head('Offres', el('button', { class: 'btn p', onclick: () => ask('Nouvelle offre', form(), async v => { const x = await api('POST', '/api/admin/plans', v); if (!x.ok) { toast(x.error, 'bad'); return false; } render(); }) }, el('span', {}, 'Nouvelle offre'))),
    el('div', { class: 'grid g3' }, (r.plans || []).map(p => el('div', { class: 'card' }, el('h2', {}, p.name, p.active ? null : ' (désactivée)'), el('b', { style: 'font-size:26px;font-style:italic' }, p.price + ' €'), el('p', { class: 'muted' }, p.days ? p.days + ' jours' : 'À vie'), el('p', {}, p.description), el('p', { class: 'muted' }, p.max_players ? p.max_players + ' joueurs max' : 'Joueurs illimités'), el('div', { class: 'row', style: 'margin-top:10px' }, el('button', { class: 'btn s', onclick: () => ask('Modifier', form(p), async v => { await api('PATCH', '/api/admin/plans/' + p.id, v); render(); }) }, el('span', {}, 'Modifier')), el('button', { class: 'btn s', onclick: async () => { await api('PATCH', '/api/admin/plans/' + p.id, { active: !p.active }); render(); } }, el('span', {}, p.active ? 'Désactiver' : 'Activer')))))));
}
async function aAudit() { const r = await api('GET', '/api/admin/audit'); return el('div', {}, head('Journal d’activité'), el('div', { class: 'card tw' }, el('table', {}, el('thead', {}, el('tr', {}, ['Date', 'Utilisateur', 'Action', 'Détail', 'IP'].map(h => el('th', {}, h)))), el('tbody', {}, (r.rows || []).map(x => el('tr', {}, el('td', {}, fmtDate(x.at)), el('td', {}, x.email || '—'), el('td', {}, x.action), el('td', { class: 'mono' }, x.detail), el('td', { class: 'mono' }, x.ip))))))); }

const PAGES = window.PAGES = { overview: pOverview, players: pPlayers, actions: pActions, console: pConsole, theme: pTheme, access: pAccess, resources: pResources, license: pLicense, account: pAccount, 'a-overview': aOverview, 'a-users': aUsers, 'a-licenses': aLicenses, 'a-plans': aPlans, 'a-audit': aAudit };
let renderId = 0;
async function render() {
  clearInterval(state.timer); const id = ++renderId;
  if (!state.user) { $app.replaceChildren(window.publicView ? window.publicView() : authView()); return; }
  const [page] = route(); const lonely = state.user.role !== 'admin' && !state.servers.length;
  if (lonely && !['offers', 'support', 'account', 'patchnotes'].includes(page)) { go('offers'); return; }
  const fn = PAGES[page] || PAGES.overview;
  if (page.startsWith('a-') && state.user.role !== 'admin') { go('overview'); return; }
  let content; try { content = await fn(); } catch (e) { console.error(e); content = el('div', { class: 'card' }, 'Erreur d’affichage : ' + e.message); }
  if (id !== renderId) return; $app.replaceChildren(shell(content));
  if (['overview', 'players'].includes(page)) state.timer = setInterval(async () => { await loadServers(); if (id === renderId && !document.querySelector('.modal') && !document.activeElement.matches('input,select,textarea')) { const c = await fn(); if (id === renderId) $app.replaceChildren(shell(c)); } }, 15000);
}
window.addEventListener('load', boot);
