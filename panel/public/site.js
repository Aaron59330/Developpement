'use strict';
// ───────── site public (avant connexion), boutique et commandes ─────────
const fmtPrice = p => p.price > 0 ? (Number.isInteger(+p.price) ? +p.price : (+p.price).toFixed(2)) + ' €' : 'Gratuit';
const fmtDur = p => p.days ? (p.days % 30 === 0 && p.days >= 30 ? (p.days / 30) + ' mois' : p.days + ' jours') : 'à vie';
const PLAN_FEATURES = ['Base complète (HUD, menus, builders, économie)', 'Panel web personnel et licence', 'Mises à jour de la base', 'Support par tickets'];
const orderPill = s => el('span', { class: 'pill ' + (s === 'paid' ? 'ok' : s === 'pending' ? 'warn' : 'bad') }, s === 'paid' ? 'Payée' : s === 'pending' ? 'En attente de paiement' : 'Annulée');

function planCards(plans, onBuy, label) {
  return el('div', { class: 'plans' }, plans.map((p, i) => el('div', { class: 'plan' + (plans.length > 2 && i === 1 ? ' hot' : '') },
    plans.length > 2 && i === 1 ? el('div', { class: 'ribbon' }, 'Populaire') : null,
    el('h3', {}, p.name), el('div', { class: 'price' }, el('b', {}, fmtPrice(p)), el('span', {}, p.price > 0 ? ' / ' + fmtDur(p) : '')),
    p.description ? el('p', { class: 'muted' }, p.description) : null,
    el('ul', {}, PLAN_FEATURES.concat(p.max_players ? ['Jusqu’à ' + p.max_players + ' joueurs'] : ['Joueurs illimités']).map(f => el('li', {}, f))),
    el('button', { class: 'btn p', onclick: () => onBuy(p) }, el('span', {}, label || 'Choisir cette offre')))));
}

// ── page d'accueil publique ──
function publicView() {
  const [pg] = route();
  if (pg === 'login' || pg === 'register') return authView(pg);
  const wrap = el('div', { class: 'lp' });
  const sec = id => () => { const t = document.getElementById(id); if (t) t.scrollIntoView({ behavior: 'smooth' }); };
  const buy = p => { try { sessionStorage.setItem('aero_buy', p.id); } catch (e) {} go(state.cfg.allowRegister === false ? 'login' : 'register'); };
  const nav = el('header', { class: 'lp-nav' }, el('a', { class: 'lp-brand', href: '#/' }, el('img', { src: 'img/logo.png', alt: 'AERO' })),
    el('nav', {}, el('a', { href: '#', onclick: e => { e.preventDefault(); sec('fonctions')(); } }, 'Fonctionnalités'), el('a', { href: '#', onclick: e => { e.preventDefault(); sec('offres')(); } }, 'Offres'), el('a', { href: '#', onclick: e => { e.preventDefault(); sec('faq')(); } }, 'FAQ')),
    el('div', { class: 'grow' }),
    el('button', { class: 'btn s', title: 'Changer de thème', onclick: () => { setTheme(getTheme() === 'clair' ? 'sombre' : 'clair'); render(); } }, el('span', {}, getTheme() === 'clair' ? '☾' : '☀')),
    el('a', { class: 'btn p', href: '#/login' }, el('span', {}, 'Se connecter')));
  const feat = (t, d) => el('div', { class: 'card feat' }, el('h3', {}, t), el('p', { class: 'muted' }, d));
  const plansBox = el('div', { id: 'offres-list' }, el('p', { class: 'muted' }, 'Chargement des offres…'));
  api('GET', '/api/shop/plans').then(r => {
    if (!r.ok || !(r.plans || []).length) { plansBox.replaceChildren(el('p', { class: 'muted' }, 'Les offres arrivent bientôt. Crée ton compte pour être prévenu.')); return; }
    plansBox.replaceChildren(...[planCards(r.plans, buy, 'Acheter'), r.shop && r.shop.contact ? el('p', { class: 'muted', style: 'text-align:center;margin-top:16px' }, 'Une question avant d’acheter ? ', r.shop.contact) : null].filter(Boolean));
  });
  const faq = (q, a) => el('details', { class: 'card faq' }, el('summary', {}, q), el('p', { class: 'muted' }, a));
  wrap.append(nav,
    el('section', { class: 'hero' }, el('div', {}, el('span', { class: 'eyebrow' }, 'Base FiveM ESX clé en main'), el('h1', {}, 'Lance ton serveur FiveM avec une base complète et optimisée'),
      el('p', { class: 'lead' }, 'HUD et menus Arcade, builders sans code, économie réglable, anticheat, et un panel web pour tout gérer à distance : thème, joueurs, fichiers, sauvegardes.'),
      el('div', { class: 'row' }, el('button', { class: 'btn p', onclick: sec('offres') }, el('span', {}, 'Voir les offres')), el('a', { class: 'btn', href: '#/register' }, el('span', {}, 'Créer un compte')))),
      el('img', { class: 'hero-logo', src: 'img/logo.png', alt: '' })),
    el('section', { id: 'fonctions' }, el('h2', {}, 'Ce que tu obtiens'), el('div', { class: 'grid g3' },
      feat('Interface Arcade', 'HUD, notifications, inventaire et menus au même style, avec un bouton pour revenir à l’ancien design en un clic.'),
      feat('Builders sans code', 'Métiers, gangs, boutiques, activités illégales, mini-jeux, enchères, évènements et monde : tout se crée en jeu.'),
      feat('Économie réglable', 'Trois profils prêts à l’emploi (réaliste, équilibré, permissif) et des réglages fins depuis le panel.'),
      feat('Panel web personnel', 'Chaque client a son compte, sa licence et son panel : joueurs, bans, console, fichiers avec historique, webhooks, sauvegardes.'),
      feat('Personnalisation en direct', 'Couleur, logo, bannières, marqueurs, nom du serveur : change un réglage dans le panel, il s’applique partout.'),
      feat('Pensée pour les PC modestes', 'Boucles allégées et mode performance automatique qui retire les effets lourds quand les FPS baissent.'))),
    el('section', { id: 'etapes' }, el('h2', {}, 'Comment ça marche'), el('div', { class: 'grid g3' },
      el('div', { class: 'card feat' }, el('h3', {}, '1 · Crée ton compte'), el('p', { class: 'muted' }, 'Gratuit et sans engagement : tu accèdes à la boutique.')),
      el('div', { class: 'card feat' }, el('h3', {}, '2 · Choisis une offre'), el('p', { class: 'muted' }, 'Tu passes ta commande, puis tu la règles selon les instructions affichées.')),
      el('div', { class: 'card feat' }, el('h3', {}, '3 · Active ton panel'), el('p', { class: 'muted' }, 'Dès validation, ta licence est créée et ton panel s’ouvre automatiquement.')))),
    el('section', { id: 'offres' }, el('h2', {}, 'Offres'), plansBox),
    el('section', { id: 'faq' }, el('h2', {}, 'Questions fréquentes'),
      faq('Quand mon panel est-il disponible ?', 'Dès que ta commande est validée. Jusque-là, ton compte te donne accès à la boutique uniquement.'),
      faq('Comment je paie ?', 'Après ta commande, les instructions de paiement s’affichent dans ton espace. La commande est validée dès réception.'),
      faq('Puis-je changer de serveur ou d’hébergeur ?', 'Oui : tu peux délier l’adresse IP de ta licence depuis ton panel quand tu changes de machine.'),
      faq('Les mises à jour sont-elles incluses ?', 'Oui, pendant toute la durée de ton offre.')),
    el('footer', { class: 'lp-foot' }, el('span', { class: 'muted' }, '© AERO · Base FiveM'), el('a', { href: '#/login' }, 'Espace client')));
  return wrap;
}

// ── offres & commandes (espace client) ──
let buying = null;   // la commande choisie sur le site public est créée une seule fois, même si l'écran est dessiné deux fois de suite
function consumeBuy() {
  if (buying) return buying;
  let id = null; try { id = +sessionStorage.getItem('aero_buy') || null; sessionStorage.removeItem('aero_buy'); } catch (e) {}
  if (!id) return null;
  return (buying = api('POST', '/api/shop/orders', { plan_id: id }).then(r => { buying = null; if (r.ok) toast('Commande créée : suis les instructions de paiement ci-dessous', 'ok'); }));
}
async function pOffers() {
  const wait = consumeBuy(); if (wait) await wait;
  const [pl, od, sv] = await Promise.all([api('GET', '/api/shop/plans'), api('GET', '/api/shop/orders'), api('GET', '/api/servers')]);
  const lonely = state.user.role !== 'admin' && !(sv.servers || []).length;
  const renewable = (sv.servers || []);
  const order = async (p, renew) => { const r = await api('POST', '/api/shop/orders', { plan_id: p.id, renew_license_id: renew || undefined }); if (!r.ok) return toast(r.error || 'Erreur', 'bad'); toast(r.existing ? 'Commande déjà en attente' : 'Commande créée', 'ok'); render(); };
  const orders = od.orders || [], pending = orders.filter(o => o.status === 'pending'), shop = od.shop || pl.shop || {};
  if (lonely) state.timer = setInterval(async () => { const r = await api('GET', '/api/servers'); if ((r.servers || []).length) { clearInterval(state.timer); await loadServers(); toast('Ton serveur est activé : bienvenue !', 'ok'); go('overview'); render(); } }, 12000);
  return el('div', {}, head(lonely ? 'Boutique' : 'Offres & renouvellement'),
    lonely ? el('div', { class: 'card' }, el('h2', {}, 'Ton compte est créé'), el('p', {}, 'Ton panel s’ouvre dès que tu as pris une offre. Choisis-la ci-dessous : tu verras les instructions de paiement, et ton espace se débloque automatiquement après validation.')) : null,
    pending.length ? el('div', { class: 'card' }, el('h2', {}, 'Comment régler'), el('p', {}, shop.pay || ''), shop.contact ? el('p', {}, el('b', {}, 'Contact : '), shop.contact) : null,
      el('p', { class: 'muted' }, 'Indique ton e-mail ' + state.user.email + ' et le numéro de commande ' + pending.map(o => '#' + o.id).join(', ') + '.')) : null,
    (pl.plans || []).length ? planCards(pl.plans, p => order(p, null), 'Commander') : el('div', { class: 'card empty' }, 'Aucune offre disponible pour le moment.'),
    renewable.length ? el('div', { class: 'card', style: 'margin-top:16px' }, el('h2', {}, 'Prolonger un serveur existant'), el('div', { class: 'row' },
      (() => { const sel = el('select', {}, renewable.map(s => el('option', { value: s.id }, s.server_name + ' · expire ' + fmtDay(s.expires_at)))); const ps = el('select', {}, (pl.plans || []).map(p => el('option', { value: p.id }, p.name + ' · ' + fmtPrice(p)))); return [sel, ps, el('button', { class: 'btn p', onclick: () => order((pl.plans || []).find(p => p.id === +ps.value), +sel.value) }, el('span', {}, 'Commander la prolongation'))]; })())) : null,
    el('div', { class: 'card tw', style: 'margin-top:16px' }, el('h2', {}, 'Mes commandes'), orders.length ? el('table', {}, el('thead', {}, el('tr', {}, ['N°', 'Offre', 'Montant', 'Statut', 'Date', ''].map(h => el('th', {}, h)))), el('tbody', {}, orders.map(o => el('tr', {},
      el('td', {}, '#' + o.id), el('td', {}, o.plan_name + (o.renew_license_id ? ' (prolongation)' : '')), el('td', {}, fmtPrice({ price: o.amount })), el('td', {}, orderPill(o.status)), el('td', { class: 'muted' }, fmtDate(o.created_at)),
      el('td', {}, o.status === 'pending' ? el('button', { class: 'btn s d', onclick: async () => { await api('POST', `/api/shop/orders/${o.id}/cancel`, {}); render(); } }, el('span', {}, 'Annuler')) : null))))) : el('p', { class: 'muted' }, 'Aucune commande pour le moment.')));
}

// ── administration : commandes + réglages de la boutique ──
async function aOrders() {
  const r = await api('GET', '/api/shop/admin/orders'); const shop = r.shop || {};
  const pay = el('textarea', { rows: 3 }, shop.pay || ''), contact = el('input', { value: shop.contact || '', placeholder: 'Ex. Discord : discord.gg/xxxx · PayPal : paypal.me/xxx' });
  const act = (o, kind) => async () => { const x = await api('POST', `/api/shop/admin/orders/${o.id}/${kind}`, {}); toast(x.ok ? (kind === 'validate' ? 'Commande validée : licence créée' : 'Commande annulée') : (x.error || 'Erreur'), x.ok ? 'ok' : 'bad'); render(); };
  return el('div', {}, head('Commandes'),
    el('div', { class: 'card' }, el('h2', {}, 'Instructions de paiement affichées aux clients'), el('label', {}, 'Texte'), pay, el('label', {}, 'Contact (Discord, PayPal…)'), contact,
      el('div', { style: 'margin-top:12px' }, el('button', { class: 'btn p', onclick: async () => { const x = await api('POST', '/api/shop/admin/settings', { pay: pay.value, contact: contact.value }); toast(x.ok ? 'Enregistré' : x.error, x.ok ? 'ok' : 'bad'); } }, el('span', {}, 'Enregistrer')))),
    el('div', { class: 'card tw' }, (r.orders || []).length ? el('table', {}, el('thead', {}, el('tr', {}, ['N°', 'Client', 'Offre', 'Montant', 'Statut', 'Date', ''].map(h => el('th', {}, h)))), el('tbody', {}, r.orders.map(o => el('tr', {},
      el('td', {}, '#' + o.id), el('td', {}, o.email || '—'), el('td', {}, o.plan_name + (o.renew_license_id ? ' (prolongation)' : '')), el('td', {}, fmtPrice({ price: o.amount })), el('td', {}, orderPill(o.status)), el('td', { class: 'muted' }, fmtDate(o.created_at)),
      el('td', {}, o.status === 'pending' ? el('div', { class: 'row' }, el('button', { class: 'btn s p', onclick: () => confirmBox('Valider la commande #' + o.id, 'Confirme que le paiement est reçu : la licence est créée et le panel du client s’ouvre.', act(o, 'validate')) }, el('span', {}, 'Valider')), el('button', { class: 'btn s d', onclick: act(o, 'cancel') }, el('span', {}, 'Annuler'))) : null))))) : el('p', { class: 'muted' }, 'Aucune commande.')));
}
Object.assign(window.PAGES, { offers: pOffers, 'a-orders': aOrders });
