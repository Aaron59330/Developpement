'use strict';
// ───────── Explications : chaque script de la base et chaque commande, en langage simple ─────────
// Données générées par tools/explications/build.py (window.EXPL).
const LVL = {
  essentiel: ['Obligatoire', '#e5484d', 'Sans lui, la base ne fonctionne pas.'],
  utile: ['Utile', '#3fb950', 'Apporte une vraie fonction aux joueurs ou au staff.'],
  facultatif: ['Facultatif', '#4aa8ff', 'Du confort ou un bonus : tu peux le retirer sans casser le reste.'],
  inutile: ['Inutile / test', '#8d8d96', 'Outil de test ou de dépannage : un joueur n’en a jamais besoin.'],
  desactive: ['Désactivé', '#e5a23c', 'Présent dans le dossier mais non démarré.'],
};
const lvlPill = l => el('span', { class: 'ex-pill', style: `--c:${LVL[l][1]}` }, LVL[l][0]);
const explBox = (title, text, cls) => text ? el('div', { class: 'ex-b ' + (cls || '') }, el('b', {}, title), el('p', {}, text)) : null;

PAGES.expl = async function () {
  const X = window.EXPL, cats = [...new Set(X.entries.map(e => e.cat))];
  let q = '', lv = '', open = null;
  const box = el('div'), search = el('input', { placeholder: 'Rechercher un script, une commande, un mot…', style: 'width:100%;max-width:520px' });
  const chips = el('div', { class: 'ex-chips' });
  const cmdTable = e => {
    const list = X.commands.filter(c => c.owner === e.id); if (!list.length) return null;
    return el('div', { class: 'ex-b' }, el('b', {}, 'Commandes et touches'), el('table', { class: 'ex-t' }, el('tbody', {}, list.map(c => el('tr', {}, el('td', {}, el('code', {}, '/' + c.name)), el('td', {}, c.who || '—'), el('td', {}, c.desc + (c.key ? ` (touche ${c.key})` : '')))))));
  };
  const card = e => {
    const isOpen = open === e.id;
    const head = el('div', { class: 'ex-h', onclick: () => { open = isOpen ? null : e.id; draw(); } }, el('div', {}, el('div', { class: 'ex-n' }, e.name), el('div', { class: 'ex-s' }, e.short)), lvlPill(e.level));
    return el('div', { class: 'card ex-card' + (isOpen ? ' on' : ''), id: 'ex-' + e.id.replace(/[^\w]/g, '_') }, head, isOpen ? el('div', { class: 'ex-body' },
      explBox('Ce que ça fait', e.what), explBox('Si on le retire', e.without, 'warn'), explBox('Où le régler', e.config), e.panel ? el('div', { class: 'ex-b' }, el('b', {}, 'Dans le panel'), el('p', {}, e.panel)) : null,
      e.deps ? explBox('Dépend de', e.deps) : null, cmdTable(e), el('div', { class: 'ex-id' }, 'Dossier : ' + e.id)) : null);
  };
  const draw = () => {
    const t = q.toLowerCase();
    const match = e => (!lv || e.level === lv) && (!t || (e.name + ' ' + e.short + ' ' + e.what + ' ' + e.id + ' ' + e.cmds.join(' ')).toLowerCase().includes(t));
    const parts = [];
    for (const c of cats) { const list = X.entries.filter(e => e.cat === c && match(e)); if (!list.length) continue; parts.push(el('h2', { class: 'ex-cat' }, c, el('span', {}, list.length)), ...list.map(card)); }
    box.replaceChildren(...(parts.length ? parts : [el('div', { class: 'card empty' }, 'Aucun résultat.')]));
    chips.replaceChildren(el('button', { class: 'btn s' + (!lv ? ' p' : ''), onclick: () => { lv = ''; draw(); } }, el('span', {}, 'Tous (' + X.entries.length + ')')), ...Object.keys(LVL).map(k => el('button', { class: 'btn s' + (lv === k ? ' p' : ''), title: LVL[k][2], onclick: () => { lv = lv === k ? '' : k; draw(); } }, el('span', {}, LVL[k][0] + ' (' + X.entries.filter(e => e.level === k).length + ')'))));
  };
  search.addEventListener('input', () => { q = search.value; draw(); }); draw();
  return el('div', {}, head('Explications — les scripts'),
    el('div', { class: 'pg-intro' }, el('b', {}, 'À quoi sert cette page ? '), 'Elle explique, script par script, ce que contient ta base : à quoi il sert, ce qui se passe si on le retire, où le régler et quelles commandes il ajoute. Même les petits scripts et les commandes de test y sont, avec un niveau d’importance : ', ...Object.keys(LVL).flatMap(k => [lvlPill(k), ' ']), el('br'), el('small', { class: 'muted' }, 'Clique sur un script pour l’ouvrir. Toutes les commandes sont aussi regroupées dans « Explications — les commandes ».')),
    el('div', { class: 'row', style: 'margin:0 0 12px;gap:10px;flex-wrap:wrap' }, search), chips, box);
};

PAGES.cmds = async function () {
  const X = window.EXPL; let q = '', who = '';
  const body = el('tbody'), search = el('input', { placeholder: 'Rechercher une commande ou un mot…', style: 'width:100%;max-width:420px' }), sel = el('select', { style: 'max-width:240px', onchange: e => { who = e.target.value; draw(); } }, el('option', { value: '' }, 'Tout le monde'), ...['Tous les joueurs', 'Staff', 'Développeur', 'Console serveur'].map(w => el('option', { value: w }, w)));
  const draw = () => {
    const t = q.toLowerCase(), list = X.commands.filter(c => (!who || c.who === who) && (!t || (c.name + ' ' + c.desc + ' ' + c.res).toLowerCase().includes(t)));
    body.replaceChildren(...list.map(c => el('tr', {}, el('td', {}, el('code', {}, '/' + c.name)), el('td', {}, c.who || '—'), el('td', {}, c.desc + (c.key ? ` (touche ${c.key})` : '')), el('td', { class: 'muted' }, c.res))));
    cnt.textContent = list.length + ' commande' + (list.length > 1 ? 's' : '');
  };
  const cnt = el('span', { class: 'muted' });
  search.addEventListener('input', () => { q = search.value; draw(); }); draw();
  return el('div', {}, head('Explications — les commandes'),
    el('div', { class: 'pg-intro' }, el('b', {}, 'Toutes les commandes de la base. '), 'Tape-les dans le chat avec « / » devant (ex : /me). « Staff » = réservé aux groupes admin ; « Développeur » = outils de dépannage ; « Console serveur » = uniquement depuis la console du serveur.'),
    el('div', { class: 'row', style: 'gap:10px;margin-bottom:12px;flex-wrap:wrap' }, search, sel, cnt),
    el('div', { class: 'card tw' }, el('table', { class: 'ex-t' }, el('thead', {}, el('tr', {}, ['Commande', 'Qui', 'Ce qu’elle fait', 'Script'].map(h => el('th', {}, h)))), body)));
};
