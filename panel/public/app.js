'use strict';
// Panel AERO : boutique, commandes, licences, support, administration. (Aucun réglage de la base ici.)
const $app = document.getElementById('app');
const state = { user: null, page: 'home', arg: null, regMode: false };
const fmtDay = t => t ? new Date(t * 1000).toLocaleDateString('fr-FR') : '—';
const money = n => (+n || 0).toLocaleString('fr-FR', { minimumFractionDigits: 0, maximumFractionDigits: 2 }) + ' €';
function el(tag, attrs, ...kids) {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) { if (v == null || v === false) continue; if (k.startsWith('on')) e.addEventListener(k.slice(2), v); else if (k === 'class') e.className = v; else e.setAttribute(k, v === true ? '' : v); }
  for (const c of kids.flat(9)) if (c != null && c !== false) e.append(c.nodeType ? c : document.createTextNode(c));
  return e;
}
async function api(method, url, body) {
  try { const r = await fetch('/api' + url, { method, headers: { 'Content-Type': 'application/json' }, body: body ? JSON.stringify(body) : undefined }); return await r.json(); }
  catch (e) { return { ok: false, error: 'Connexion au panel impossible' }; }
}
function toast(msg, kind) { const t = el('div', { class: 'toast ' + (kind || '') }, msg); document.getElementById('toasts').append(t); setTimeout(() => t.remove(), 3500); }
// fenêtre de saisie : fields = [{name,label,type,value,options}]
function ask(title, fields, onOk, okLabel) {
  const inputs = {}; const err = el('div', { class: 'err' });
  const rows = fields.map(f => {
    inputs[f.name] = f.type === 'select' ? el('select', {}, f.options.map(o => el('option', { value: o[0], selected: String(o[0]) === String(f.value) }, o[1])))
      : f.type === 'textarea' ? el('textarea', { placeholder: f.placeholder || '' }, f.value || '') : el('input', { type: f.type || 'text', value: f.value ?? '', placeholder: f.placeholder || '' });
    return [el('label', {}, f.label), inputs[f.name]];
  });
  const close = () => m.remove();
  const go = async () => { const v = {}; for (const k in inputs) v[k] = inputs[k].value; const r = await onOk(v); if (r === false) return; close(); };
  const m = el('div', { class: 'modal', onclick: e => { if (e.target === m) close(); } }, el('div', { class: 'box' }, el('h2', { style: 'font-size:18px;margin-bottom:6px' }, title), rows, err,
    el('div', { class: 'row', style: 'margin-top:12px' }, el('button', { class: 'btn p inline', onclick: go }, el('span', {}, okLabel || 'Valider')), el('button', { class: 'btn inline', onclick: close }, el('span', {}, 'Annuler')))));
  document.body.append(m); const f = m.querySelector('input,select,textarea'); if (f) f.focus();
}
const confirmBox = (title, text, onOk, danger) => { const m = el('div', { class: 'modal' }, el('div', { class: 'box' }, el('h2', { style: 'font-size:18px;margin-bottom:6px' }, title), el('p', { class: 'muted' }, text),
  el('div', { class: 'row', style: 'margin-top:14px' }, el('button', { class: 'btn p inline' + (danger ? ' d' : ''), onclick: async () => { m.remove(); await onOk(); } }, el('span', {}, 'Confirmer')), el('button', { class: 'btn inline', onclick: () => m.remove() }, el('span', {}, 'Annuler'))))); document.body.append(m); };
const head = (title, ...actions) => el('div', { class: 'row', style: 'margin-bottom:18px' }, el('h1', { style: 'margin:0' }, title), el('div', { class: 'grow' }), ...actions);
const table = (cols, rows) => el('div', { class: 'card tw' }, el('table', {}, el('thead', {}, el('tr', {}, cols.map(c => el('th', {}, c)))), el('tbody', {}, rows.length ? rows : el('tr', {}, el('td', { colspan: cols.length, class: 'muted' }, 'Rien pour le moment.')))));
const copy = t => { navigator.clipboard && navigator.clipboard.writeText(t); toast('Copié', 'ok'); };
const stPill = s => el('span', { class: 'pill ' + ({ active: 'ok', paid: 'ok', open: 'ok', pending: 'warn', suspended: 'warn', cancelled: 'bad', revoked: 'bad', closed: '' }[s] || '') }, { active: 'active', suspended: 'suspendue', revoked: 'révoquée', pending: 'en attente', paid: 'payée', cancelled: 'annulée', open: 'ouvert', closed: 'fermé' }[s] || s);

const brand = big => el('div', { class: 'brand' + (big ? ' big' : '') }, el('img', { src: 'img/logo.svg', alt: 'AERO' }), el('b', {}, 'AERO ', el('span', {}, 'PANEL')));

// ───────── menu par catégories ─────────
const MENU = (admin) => [
  { sec: 'Mon espace', items: [['home', 'Accueil'], ['shop', 'Boutique'], ['orders', 'Mes commandes'], ['licenses', 'Mes licences'], ['custom', 'Personnalisation']] },
  { sec: 'Aide', items: [['support', 'Aide et support'], ['suggestions', 'Suggestions'], ['patchnotes', 'Patch notes']] },
  { sec: 'Compte', items: [['account', 'Paramètres du compte']] },
  ...(admin ? [{ sec: 'Administration', items: [['a_overview', 'Vue d’ensemble'], ['a_orders', 'Commandes'], ['a_clients', 'Clients'], ['a_licenses', 'Licences'], ['a_plans', 'Offres'], ['a_modules', 'Modules'], ['a_shop', 'Réglages boutique'], ['a_audit', 'Journal']] }] : []),
];
const go = (page, arg) => { state.page = page; state.arg = arg || null; location.hash = '#/' + page + (arg ? '/' + arg : ''); render(); };
function readHash() { const [p, a] = location.hash.replace('#/', '').split('/'); if (p) { state.page = p; state.arg = a || null; } }
addEventListener('hashchange', () => { readHash(); if (state.user) render(); });

// ───────── connexion / inscription ─────────
function authPage() {
  const reg = state.regMode, err = el('div', { class: 'err' });
  const email = el('input', { type: 'email', placeholder: 'E-mail', autocomplete: 'email' }), pass = el('input', { type: 'password', placeholder: 'Mot de passe', autocomplete: reg ? 'new-password' : 'current-password' }), name = el('input', { placeholder: 'Pseudo', autocomplete: 'username' });
  const submit = async () => {
    const r = await api('POST', reg ? '/auth/register' : '/auth/login', { email: email.value, password: pass.value, username: name.value });
    if (!r.ok) { err.textContent = r.error || 'Erreur'; return; } await boot();
  };
  [email, pass, name].forEach(i => i.addEventListener('keydown', e => { if (e.key === 'Enter') submit(); }));
  return el('div', { class: 'authwrap' }, el('section', { class: 'box' }, brand(true), el('h1', {}, reg ? 'Créer un compte' : 'Connexion'),
    el('p', { class: 'muted' }, 'Gère ton serveur FiveM depuis ton espace client.'), reg ? [el('label', {}, 'Pseudo'), name] : null, el('label', {}, 'E-mail'), email, el('label', {}, 'Mot de passe'), pass, err,
    el('button', { class: 'btn p', onclick: submit }, el('span', {}, reg ? 'S’inscrire' : 'Se connecter')),
    el('button', { class: 'link', onclick: () => { state.regMode = !reg; render(); } }, reg ? 'J’ai déjà un compte' : 'Créer un compte')));
}

// ───────── coque ─────────
async function shell() {
  const admin = state.user.role === 'admin';
  const side = el('aside', { class: 'side' }, brand(),
    MENU(admin).map(g => [el('div', { class: 'sec' }, g.sec), el('nav', {}, g.items.map(([id, label]) => el('a', { class: 'nav' + (state.page === id ? ' on' : ''), href: '#/' + id }, el('span', {}, label))))]),
    el('div', { class: 'bottom' }, el('a', { class: 'nav', href: '#', onclick: async e => { e.preventDefault(); await api('POST', '/auth/logout', {}); state.user = null; render(); } }, el('span', {}, 'Déconnexion (' + state.user.username + ')'))));
  const main = el('main', { class: 'main' });
  $app.replaceChildren(el('div', { class: 'layout' }, side, main));
  const page = PAGES[state.page] || PAGES.home;
  main.append(await page());
}
async function render() { if (!state.user) { $app.replaceChildren(authPage()); return; } await shell(); }

const PAGES = {
  // ── Mon espace ──
  async home() {
    const [o, l, s] = await Promise.all([api('GET', '/shop/orders'), api('GET', '/me/licenses'), api('GET', '/support/summary')]);
    const lic = l.licenses || [], act = lic.filter(x => x.status === 'active' && (!x.expires_at || x.expires_at * 1000 > Date.now()));
    return el('div', {}, el('section', { class: 'hero' }, el('small', {}, 'TON TABLEAU DE BORD'), el('h1', {}, 'Bonjour ' + state.user.username + '.'), el('span', {}, 'Boutique, commandes, licences et support au même endroit.')), el('div', { class: 'grid' },
      el('div', { class: 'card stat' }, el('b', {}, act.length), el('span', {}, 'Licence(s) active(s)')),
      el('div', { class: 'card stat' }, el('b', {}, (o.orders || []).filter(x => x.status === 'pending').length), el('span', {}, 'Commande(s) en attente')),
      el('div', { class: 'card stat' }, el('b', {}, s.open_tickets ?? 0), el('span', {}, 'Ticket(s) ouvert(s)')),
      el('div', { class: 'card stat' }, el('b', {}, s.version || '—'), el('span', {}, 'Dernière version'))),
      !lic.length ? el('section', { class: 'card empty', style: 'margin-top:18px' }, el('h2', {}, 'Pas encore de licence'), el('p', { class: 'muted' }, 'Choisis une offre dans la boutique pour commencer.'), el('a', { class: 'btn p', href: '#/shop' }, el('span', {}, 'Voir la boutique'))) : null);
  },
  async shop() {
    const [r, l] = await Promise.all([api('GET', '/shop/plans'), api('GET', '/me/licenses')]);
    const order = (plan, renew) => async () => { const x = await api('POST', '/shop/orders', { plan_id: plan.id, renew_license_id: renew || undefined }); if (!x.ok) return toast(x.error, 'bad'); toast(x.existing ? 'Commande déjà en attente' : 'Commande créée', 'ok'); go('orders'); };
    return el('div', {}, head('Boutique'), el('p', { class: 'hint' }, r.shop && r.shop.pay), el('div', { class: 'grid' }, (r.plans || []).map(p => el('div', { class: 'card offer' }, el('h3', {}, p.name),
      el('div', { class: 'price' }, money(p.price), el('small', {}, p.days ? ' / ' + p.days + ' j' : ' · à vie')), el('p', {}, p.description || ''), el('span', { class: 'muted' }, p.max_players ? p.max_players + ' joueurs max' : 'Joueurs illimités'),
      el('button', { class: 'btn p', onclick: order(p) }, el('span', {}, 'Commander')),
      (l.licenses || []).length ? el('button', { class: 'btn', style: 'margin-top:6px', onclick: () => ask('Renouveler une licence', [{ name: 'lic', label: 'Licence', type: 'select', options: l.licenses.map(x => [x.id, x.server_name + ' — ' + x.key.slice(0, 11) + '…']) }], v => order(p, +v.lic)()) }, el('span', {}, 'Renouveler une licence')) : null))),
      r.shop && r.shop.contact ? el('p', { class: 'hint', style: 'margin-top:16px' }, 'Contact : ' + r.shop.contact) : null);
  },
  async orders() {
    const r = await api('GET', '/shop/orders');
    return el('div', {}, head('Mes commandes'), r.shop ? el('p', { class: 'hint' }, r.shop.pay) : null, table(['#', 'Offre', 'Montant', 'Statut', 'Créée', 'Payée', ''], (r.orders || []).map(o => el('tr', {}, el('td', {}, o.id), el('td', {}, o.plan_name + (o.renew_license_id ? ' (renouvellement)' : '')), el('td', {}, money(o.amount)), el('td', {}, stPill(o.status)), el('td', {}, fmtDay(o.created_at)), el('td', {}, fmtDay(o.paid_at)),
      el('td', {}, o.status === 'pending' ? el('button', { class: 'btn s d', onclick: async () => { await api('POST', `/shop/orders/${o.id}/cancel`, {}); render(); } }, 'Annuler') : null)))));
  },
  async licenses() {
    const r = await api('GET', '/me/licenses');
    return el('div', {}, head('Mes licences'), table(['Serveur', 'Clé', 'Offre', 'Statut', 'Expire', ''], (r.licenses || []).map(l => el('tr', {}, el('td', {}, l.server_name), el('td', { class: 'mono' }, l.key), el('td', {}, l.plan || '—'), el('td', {}, stPill(l.status)), el('td', {}, l.expires_at ? fmtDay(l.expires_at) : 'À vie'),
      el('td', {}, el('button', { class: 'btn s', onclick: () => copy(l.key) }, 'Copier'))))));
  },
  async custom() {
    const l = await api('GET', '/me/licenses'); const lics = l.licenses || [];
    if (!lics.length) return el('div', {}, head('Personnalisation'), el('section', { class: 'card empty' }, el('h2', {}, 'Pas encore de licence'), el('p', { class: 'muted' }, 'La personnalisation s’applique à ton serveur : prends d’abord une licence.'), el('a', { class: 'btn p', href: '#/shop' }, el('span', {}, 'Voir la boutique'))));
    const cur = lics.find(x => String(x.id) === String(state.arg)) || lics[0];
    const t = (await api('GET', '/theme/' + cur.id)).theme || {};
    let accent = t.accent || '#fdc27d', pending = null;
    const prev = el('div', { class: 'prev' }), drop = el('div', { class: 'drop', tabindex: 0 }), file = el('input', { type: 'file', accept: 'image/png,image/jpeg', style: 'display:none' });
    const hex = el('input', { type: 'text', value: accent, maxlength: 7 }), pick = el('input', { type: 'color', value: accent });
    const drawPrev = () => { prev.replaceChildren(pending || t.has_logo ? el('img', { src: pending || ('/api/theme/' + cur.id + '/logo?v=' + t.version) }) : null, el('span', { class: 'pbtn', style: 'background:' + accent }, 'Aperçu du bouton')); };
    const drawDrop = () => { drop.replaceChildren(pending || t.has_logo ? el('img', { src: pending || ('/api/theme/' + cur.id + '/logo?v=' + t.version) }) : null, el('b', {}, pending || t.has_logo ? 'Glisse une autre image pour la remplacer' : 'Glisse ton logo ici'), el('small', {}, '.png ou .jpg · 2 Mo maximum · clique pour choisir un fichier')); };
    const setColor = c => { if (!/^#[0-9a-fA-F]{6}$/.test(c)) return; accent = c.toLowerCase(); hex.value = accent; pick.value = accent; drawPrev(); };
    pick.oninput = () => setColor(pick.value); hex.oninput = () => setColor(hex.value);
    const take = f => {
      if (!f) return; if (!/^image\/(png|jpeg)$/.test(f.type)) return toast('Image .png ou .jpg uniquement', 'bad'); if (f.size > 2 * 1024 * 1024) return toast('Image trop lourde (2 Mo maximum)', 'bad');
      const r = new FileReader(); r.onload = () => { pending = r.result; drawDrop(); drawPrev(); }; r.readAsDataURL(f);
    };
    drop.onclick = () => file.click(); file.onchange = () => take(file.files[0]);
    drop.ondragover = e => { e.preventDefault(); drop.classList.add('over'); }; drop.ondragleave = () => drop.classList.remove('over');
    drop.ondrop = e => { e.preventDefault(); drop.classList.remove('over'); take(e.dataTransfer.files[0]); };
    const save = async () => {
      let r = await api('PUT', '/theme/' + cur.id, { accent }); if (!r.ok) return toast(r.error, 'bad');
      if (pending) { r = await api('POST', `/theme/${cur.id}/logo`, { data: pending }); if (!r.ok) return toast(r.error, 'bad'); }
      toast('Enregistré : appliqué sur ton serveur d’ici une minute', 'ok'); go('custom', cur.id);
    };
    setColor(accent); drawDrop();
    return el('div', {}, head('Personnalisation', lics.length > 1 ? el('select', { style: 'width:auto', onchange: e => go('custom', e.target.value) }, lics.map(x => el('option', { value: x.id, selected: x.id === cur.id }, x.server_name))) : null),
      el('p', { class: 'hint' }, 'Couleur principale et logo de ton serveur. Ils s’appliquent à toutes les interfaces en jeu.'),
      el('div', { class: 'grid', style: 'grid-template-columns:repeat(auto-fit,minmax(320px,1fr));align-items:start' },
        el('div', { class: 'card' }, el('h2', {}, 'Couleur principale'), el('div', { class: 'colorrow', style: 'margin-top:12px' }, pick, hex),
          el('div', { class: 'swatches' }, ['#fdc27d', '#3566a6', '#00a4ff', '#45d5a0', '#ff747e', '#b388ff', '#ff9f43', '#e84393'].map(c => el('span', { class: 'sw', style: 'background:' + c, title: c, onclick: () => setColor(c) })))),
        el('div', { class: 'card' }, el('h2', {}, 'Logo principal'), el('div', { style: 'margin-top:12px' }, drop, file),
          t.has_logo ? el('button', { class: 'btn s d', style: 'margin-top:10px', onclick: async () => { await api('DELETE', `/theme/${cur.id}/logo`); go('custom', cur.id); } }, 'Retirer le logo') : null)),
      prev, el('button', { class: 'btn p', onclick: save }, el('span', {}, 'Enregistrer')));
  },
  // ── Aide ──
  async support() {
    if (state.arg) return ticketView(+state.arg);
    const r = await api('GET', '/support/tickets'), l = await api('GET', '/me/licenses');
    return el('div', {}, head('Aide et support', el('button', { class: 'btn p inline', onclick: () => ask('Nouveau ticket', [{ name: 'subject', label: 'Sujet' }, { name: 'body', label: 'Message', type: 'textarea' }], async v => { const x = await api('POST', '/support/tickets', v); if (!x.ok) { toast(x.error, 'bad'); return false; } go('support', x.id); }) }, el('span', {}, 'Nouveau ticket'))),
      table(['#', 'Sujet', state.user.role === 'admin' ? 'Client' : null, 'Statut', 'Messages', 'Mis à jour'].filter(Boolean), (r.tickets || []).map(t => el('tr', { style: 'cursor:pointer', onclick: () => go('support', t.id) }, el('td', {}, t.id), el('td', {}, t.subject), state.user.role === 'admin' ? el('td', {}, t.email) : null, el('td', {}, stPill(t.status)), el('td', {}, t.msgs), el('td', {}, fmtDay(t.updated_at))))));
  },
  async suggestions() {
    const r = await api('GET', '/support/suggestions'), adm = state.user.role === 'admin';
    const lab = { new: 'nouvelle', planned: 'prévue', done: 'faite', refused: 'refusée' };
    return el('div', {}, head('Suggestions', el('button', { class: 'btn p inline', onclick: () => ask('Nouvelle suggestion', [{ name: 'title', label: 'Titre' }, { name: 'body', label: 'Détail', type: 'textarea' }], async v => { const x = await api('POST', '/support/suggestions', v); if (!x.ok) { toast(x.error, 'bad'); return false; } render(); }) }, el('span', {}, 'Proposer'))),
      table(['Votes', 'Suggestion', 'Par', 'Statut', ''], (r.rows || []).map(s => el('tr', {}, el('td', {}, el('button', { class: 'btn s vote' + (s.voted ? ' p' : ''), onclick: async () => { await api('POST', `/support/suggestions/${s.id}/vote`, {}); render(); } }, '▲ ' + s.votes)), el('td', {}, el('b', {}, s.title), s.body ? el('div', { class: 'muted' }, s.body) : null), el('td', {}, s.username), el('td', {}, el('span', { class: 'pill' }, lab[s.status])),
        el('td', {}, adm ? el('select', { style: 'width:auto;padding:6px 10px', onchange: async e => { await api('POST', `/support/suggestions/${s.id}/status`, { status: e.target.value }); render(); } }, Object.keys(lab).map(k => el('option', { value: k, selected: k === s.status }, lab[k]))) : null)))));
  },
  async patchnotes() {
    const r = await api('GET', '/support/patchnotes'), adm = state.user.role === 'admin';
    return el('div', {}, head('Patch notes', adm ? el('button', { class: 'btn p inline', onclick: () => ask('Nouvelle note', [{ name: 'version', label: 'Version' }, { name: 'title', label: 'Titre' }, { name: 'body', label: 'Texte', type: 'textarea' }], async v => { const x = await api('POST', '/support/patchnotes', v); if (!x.ok) { toast(x.error, 'bad'); return false; } render(); }) }, el('span', {}, 'Ajouter')) : null),
      el('div', { class: 'card' }, (r.notes || []).map(n => el('div', { class: 'note' }, el('h2', {}, n.title, ' ', el('span', { class: 'pill' }, n.version || '')), el('small', {}, fmtDay(n.at)), el('p', { style: 'white-space:pre-wrap;margin-top:6px' }, n.body),
        adm ? el('button', { class: 'btn s d', style: 'margin-top:8px', onclick: async () => { await api('DELETE', '/support/patchnotes/' + n.id); render(); } }, 'Supprimer') : null))));
  },
  // ── Compte ──
  async account() {
    const cur = el('input', { type: 'password', placeholder: 'Mot de passe actuel' }), nw = el('input', { type: 'password', placeholder: 'Nouveau mot de passe (8 caractères min.)' });
    return el('div', {}, head('Paramètres du compte'), el('div', { class: 'card', style: 'max-width:480px' }, el('p', {}, el('b', {}, state.user.username), ' · ', state.user.email), el('p', { class: 'muted' }, 'Inscrit le ' + fmtDay(state.user.created_at)),
      el('h2', { style: 'margin-top:18px' }, 'Changer de mot de passe'), el('label', {}, 'Mot de passe actuel'), cur, el('label', {}, 'Nouveau mot de passe'), nw,
      el('button', { class: 'btn p', onclick: async () => { const r = await api('POST', '/auth/password', { current: cur.value, next: nw.value }); toast(r.ok ? 'Mot de passe modifié' : r.error, r.ok ? 'ok' : 'bad'); if (r.ok) cur.value = nw.value = ''; } }, el('span', {}, 'Modifier'))));
  },
  // ── Administration ──
  async a_overview() {
    const r = await api('GET', '/admin/overview'); if (!r.ok) return el('p', {}, r.error);
    const S = (n, t) => el('div', { class: 'card stat' }, el('b', {}, n), el('span', {}, t));
    return el('div', {}, head('Vue d’ensemble'), el('div', { class: 'grid' }, S(r.users, 'Clients'), S(r.licenses, 'Licences'), S(r.active, 'Actives'), S(r.expired, 'Expirées'), S(r.pending, 'Commandes en attente'), S(r.tickets, 'Tickets ouverts'), S(money(r.revenue), 'Encaissé')),
      el('div', { class: 'sec2' }, 'Expirent sous 7 jours'), table(['Serveur', 'Client', 'Expire'], (r.expiring || []).map(x => el('tr', {}, el('td', {}, x.server_name), el('td', {}, x.email || '—'), el('td', {}, fmtDay(x.expires_at))))));
  },
  async a_orders() {
    const r = await api('GET', '/shop/admin/orders');
    return el('div', {}, head('Commandes'), table(['#', 'Client', 'Offre', 'Montant', 'Statut', 'Créée', ''], (r.orders || []).map(o => el('tr', {}, el('td', {}, o.id), el('td', {}, o.email || '—'), el('td', {}, o.plan_name + (o.renew_license_id ? ' (renouv.)' : '')), el('td', {}, money(o.amount)), el('td', {}, stPill(o.status)), el('td', {}, fmtDay(o.created_at)),
      el('td', {}, o.status === 'pending' ? el('div', { class: 'row' }, el('button', { class: 'btn s p', onclick: async () => { const x = await api('POST', `/shop/admin/orders/${o.id}/validate`, {}); toast(x.ok ? 'Paiement validé, licence activée' : x.error, x.ok ? 'ok' : 'bad'); render(); } }, 'Valider le paiement'), el('button', { class: 'btn s d', onclick: async () => { await api('POST', `/shop/admin/orders/${o.id}/cancel`, {}); render(); } }, 'Annuler')) : null)))));
  },
  async a_clients() {
    const r = await api('GET', '/admin/users'); const act = (u, patch, msg) => async () => { const x = await api('PATCH', '/admin/users/' + u.id, patch); toast(x.ok ? msg : x.error, x.ok ? 'ok' : 'bad'); render(); };
    return el('div', {}, head('Clients', el('button', { class: 'btn p inline', onclick: () => ask('Nouveau client', [{ name: 'email', label: 'E-mail' }, { name: 'username', label: 'Pseudo' }, { name: 'password', label: 'Mot de passe (8 min.)', type: 'password' }], async v => { const x = await api('POST', '/admin/users', v); if (!x.ok) { toast(x.error, 'bad'); return false; } toast('Client créé', 'ok'); render(); }) }, el('span', {}, 'Nouveau client'))),
      table(['#', 'E-mail', 'Pseudo', 'Rôle', 'Licences', 'Inscrit', ''], (r.users || []).map(u => el('tr', {}, el('td', {}, u.id), el('td', {}, u.email), el('td', {}, u.username), el('td', {}, el('span', { class: 'pill ' + (u.role === 'admin' ? 'acc' : '') }, u.role), u.disabled ? el('span', { class: 'pill bad', style: 'margin-left:6px' }, 'désactivé') : null), el('td', {}, u.licenses), el('td', {}, fmtDay(u.created_at)),
        el('td', {}, el('div', { class: 'row' }, el('button', { class: 'btn s', onclick: act(u, { disabled: !u.disabled }, u.disabled ? 'Réactivé' : 'Désactivé') }, u.disabled ? 'Réactiver' : 'Désactiver'),
          el('button', { class: 'btn s', onclick: () => ask('Nouveau mot de passe', [{ name: 'password', label: 'Mot de passe', type: 'password' }], async v => { const x = await api('PATCH', '/admin/users/' + u.id, v); toast(x.ok ? 'Mot de passe changé' : x.error, x.ok ? 'ok' : 'bad'); return x.ok; }) }, 'Mot de passe'),
          el('button', { class: 'btn s', onclick: act(u, { role: u.role === 'admin' ? 'client' : 'admin' }, 'Rôle modifié') }, u.role === 'admin' ? 'Retirer admin' : 'Passer admin'),
          el('button', { class: 'btn s d', onclick: () => ask('Supprimer ' + u.email, [{ name: 'lic', label: 'Ses licences (' + u.licenses + ')', type: 'select', options: [['keep', 'Les conserver (sans propriétaire)'], ['del', 'Les supprimer aussi']] }], async v => { const x = await api('DELETE', '/admin/users/' + u.id, { delete_licenses: v.lic === 'del' }); toast(x.ok ? 'Compte supprimé' : x.error, x.ok ? 'ok' : 'bad'); if (x.ok) render(); return x.ok; }, 'Supprimer') }, 'Supprimer')))))));
  },
  async a_licenses() {
    const [r, u, p] = await Promise.all([api('GET', '/admin/licenses'), api('GET', '/admin/users'), api('GET', '/admin/plans')]);
    const patch = (l, b, msg) => async () => { const x = await api('PATCH', '/admin/licenses/' + l.id, b); toast(x.ok ? msg : x.error, x.ok ? 'ok' : 'bad'); render(); };
    return el('div', {}, head('Licences', el('button', { class: 'btn p inline', onclick: () => ask('Nouvelle licence', [{ name: 'user_id', label: 'Client', type: 'select', options: [['', '— aucun —'], ...(u.users || []).map(x => [x.id, x.email])] }, { name: 'plan_id', label: 'Offre', type: 'select', options: (p.plans || []).map(x => [x.id, `${x.name} (${x.price} €)`]) }, { name: 'server_name', label: 'Nom du serveur', value: 'Mon serveur' }, { name: 'days', label: 'Durée en jours (vide = selon l’offre, 0 = à vie)', type: 'number' }], async v => { const x = await api('POST', '/admin/licenses', v); if (!x.ok) { toast(x.error, 'bad'); return false; } toast('Licence créée : ' + x.key, 'ok'); render(); }) }, el('span', {}, 'Nouvelle licence'))),
      table(['#', 'Clé', 'Serveur', 'Client', 'Offre', 'Statut', 'Expire', ''], (r.licenses || []).map(l => el('tr', {}, el('td', {}, l.id), el('td', { class: 'mono' }, l.key), el('td', {}, l.server_name), el('td', {}, l.owner || '—'), el('td', {}, l.plan || '—'), el('td', {}, stPill(l.status)), el('td', {}, l.expires_at ? fmtDay(l.expires_at) : 'À vie'),
        el('td', {}, el('div', { class: 'row' }, el('button', { class: 'btn s', onclick: () => ask('Prolonger', [{ name: 'd', label: 'Jours à ajouter', type: 'number', value: 30 }], v => patch(l, { extend_days: +v.d }, 'Prolongée')()) }, '+ jours'),
          el('button', { class: 'btn s', onclick: patch(l, { status: l.status === 'active' ? 'suspended' : 'active' }, l.status === 'active' ? 'Suspendue' : 'Réactivée') }, l.status === 'active' ? 'Suspendre' : 'Réactiver'),
          el('button', { class: 'btn s', onclick: () => copy(l.key) }, 'Copier'),
          el('button', { class: 'btn s d', onclick: () => confirmBox('Supprimer', 'Supprimer définitivement la licence #' + l.id + ' ?', async () => { await api('DELETE', '/admin/licenses/' + l.id); render(); }, true) }, 'Suppr.')))))));
  },
  async a_plans() {
    const r = await api('GET', '/admin/plans');
    const form = p => [{ name: 'name', label: 'Nom', value: p ? p.name : '' }, { name: 'price', label: 'Prix (€)', type: 'number', value: p ? p.price : 0 }, { name: 'days', label: 'Durée en jours (0 = à vie)', type: 'number', value: p ? p.days : 30 }, { name: 'max_players', label: 'Joueurs max (0 = illimité)', type: 'number', value: p ? p.max_players : 0 }, { name: 'description', label: 'Description', value: p ? p.description : '' }];
    return el('div', {}, head('Offres', el('button', { class: 'btn p inline', onclick: () => ask('Nouvelle offre', form(), async v => { const x = await api('POST', '/admin/plans', v); if (!x.ok) { toast(x.error, 'bad'); return false; } render(); }) }, el('span', {}, 'Nouvelle offre'))),
      table(['Nom', 'Prix', 'Durée', 'Joueurs', 'Visible', ''], (r.plans || []).map(p => el('tr', {}, el('td', {}, el('b', {}, p.name), el('div', { class: 'muted' }, p.description)), el('td', {}, money(p.price)), el('td', {}, p.days ? p.days + ' j' : 'À vie'), el('td', {}, p.max_players || '∞'), el('td', {}, stPill(p.active ? 'active' : 'cancelled')),
        el('td', {}, el('div', { class: 'row' }, el('button', { class: 'btn s', onclick: () => ask('Modifier l’offre', form(p), async v => { const x = await api('PATCH', '/admin/plans/' + p.id, v); if (!x.ok) { toast(x.error, 'bad'); return false; } render(); }) }, 'Modifier'),
          el('button', { class: 'btn s', onclick: async () => { await api('PATCH', '/admin/plans/' + p.id, { active: !p.active }); render(); } }, p.active ? 'Masquer' : 'Afficher')))))));
  },
  async a_modules() {
    const r = await api('GET', '/admin/modules');
    const form = m => [{ name: 'name', label: 'Nom', value: m ? m.name : '' }, { name: 'description', label: 'Description', value: m ? m.description : '' }, { name: 'price', label: 'Prix (€)', type: 'number', value: m ? m.price : 0 }, { name: 'resources', label: 'Ressources (séparées par des virgules)', value: m ? m.resources.join(', ') : '' }];
    return el('div', {}, head('Modules', el('button', { class: 'btn p inline', onclick: () => ask('Nouveau module', form(), async v => { const x = await api('POST', '/admin/modules', v); if (!x.ok) { toast(x.error, 'bad'); return false; } render(); }) }, el('span', {}, 'Nouveau module'))),
      table(['Nom', 'Prix', 'Ressources', 'Visible', ''], (r.modules || []).map(m => el('tr', {}, el('td', {}, el('b', {}, m.name), el('div', { class: 'muted' }, m.description)), el('td', {}, money(m.price)), el('td', { class: 'mono' }, m.resources.join(', ') || '—'), el('td', {}, stPill(m.active ? 'active' : 'cancelled')),
        el('td', {}, el('div', { class: 'row' }, el('button', { class: 'btn s', onclick: () => ask('Modifier le module', form(m), async v => { const x = await api('PATCH', '/admin/modules/' + m.id, v); if (!x.ok) { toast(x.error, 'bad'); return false; } render(); }) }, 'Modifier'),
          el('button', { class: 'btn s', onclick: async () => { await api('PATCH', '/admin/modules/' + m.id, { active: !m.active }); render(); } }, m.active ? 'Masquer' : 'Afficher')))))));
  },
  async a_shop() {
    const r = await api('GET', '/shop/admin/orders'), s = r.shop || {};
    const name = el('input', { value: s.name || '' }), pay = el('textarea', {}, s.pay || ''), contact = el('input', { value: s.contact || '', placeholder: 'Discord, e-mail…' });
    return el('div', {}, head('Réglages boutique'), el('div', { class: 'card', style: 'max-width:560px' }, el('label', {}, 'Nom de la boutique'), name, el('label', {}, 'Message de paiement (affiché au client)'), pay, el('label', {}, 'Contact'), contact,
      el('button', { class: 'btn p', onclick: async () => { const x = await api('POST', '/shop/admin/settings', { name: name.value, pay: pay.value, contact: contact.value }); toast(x.ok ? 'Enregistré' : x.error, x.ok ? 'ok' : 'bad'); } }, el('span', {}, 'Enregistrer'))));
  },
  async a_audit() {
    const r = await api('GET', '/admin/audit');
    return el('div', {}, head('Journal'), table(['Date', 'Action', 'Détail', 'Par', 'IP'], (r.rows || []).map(a => el('tr', {}, el('td', {}, new Date(a.at * 1000).toLocaleString('fr-FR')), el('td', { class: 'mono' }, a.action), el('td', {}, a.detail), el('td', {}, a.email || '—'), el('td', { class: 'mono' }, a.ip || '')))));
  },
};
async function ticketView(id) {
  const r = await api('GET', '/support/tickets/' + id); if (!r.ok) return el('p', {}, r.error || 'Introuvable');
  const t = r.ticket, body = el('textarea', { placeholder: 'Ta réponse…' });
  return el('div', {}, head(t.subject, stPill(t.status), el('button', { class: 'btn s', onclick: () => go('support') }, '← Retour'), el('button', { class: 'btn s', onclick: async () => { await api('POST', `/support/tickets/${id}/close`, { open: t.status === 'closed' }); render(); } }, t.status === 'closed' ? 'Rouvrir' : 'Fermer')),
    r.messages.map(m => el('div', { class: 'msg' + (m.staff ? ' staff' : '') }, el('small', {}, (m.username || '?') + (m.staff ? ' · staff' : '') + ' · ' + new Date(m.at * 1000).toLocaleString('fr-FR')), m.body)),
    el('div', { class: 'card', style: 'margin-top:14px' }, body, el('button', { class: 'btn p', onclick: async () => { const x = await api('POST', `/support/tickets/${id}/reply`, { body: body.value }); if (!x.ok) return toast(x.error, 'bad'); render(); } }, el('span', {}, 'Répondre'))));
}
async function boot() { const r = await api('GET', '/auth/me'); state.user = r.ok ? r.user : null; readHash(); if (state.user && state.user.role !== 'admin' && state.page.startsWith('a_')) state.page = 'home'; render(); }
boot();
