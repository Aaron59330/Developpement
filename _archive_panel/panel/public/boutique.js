'use strict';
// ───────── Boutique à coins : tous les produits (véhicules, armes, caisses, packs, VIP…) réglés depuis le panel ─────────
// Document « boutique » : appliqué en direct dans le jeu par pickax_core (players/boutique/live_*.lua). Valeurs d'origine : boutique-defaults.js.
const B_TIERS = ['', 'Commun', 'Rare', 'Épique', 'Unique', 'Légendaire'];
function bRows(list, cols, blank, opts) {
  opts = opts || {}; const box = el('div', { class: 'bx-rows' });
  const draw = () => {
    box.replaceChildren(
      el('div', { class: 'bx-r bx-h' }, ...cols.map(c => el('div', { style: `flex:${c.w || 1}` }, c.label)), el('div', { style: 'width:104px' })),
      ...list.map((row, i) => el('div', { class: 'bx-r' }, ...cols.map(c => {
        let inp;
        if (c.type === 'select') inp = el('select', { onchange: e => { row[c.k] = e.target.value; if (opts.redraw) draw(); } }, c.opts.map(o => el('option', { value: o[0], selected: String(row[c.k] == null ? '' : row[c.k]) === String(o[0]) }, o[1])));
        else if (c.type === 'area') inp = el('textarea', { rows: 2, value: row[c.k] || '', placeholder: c.ph || '', oninput: e => { row[c.k] = e.target.value; } });
        else inp = el('input', { type: c.type === 'number' ? 'number' : 'text', value: row[c.k] == null ? '' : row[c.k], placeholder: c.ph || '', oninput: e => { row[c.k] = c.type === 'number' && e.target.value !== '' ? Number(e.target.value) : e.target.value; } });
        return el('div', { style: `flex:${c.w || 1}` }, inp);
      }), el('div', { class: 'bx-a' },
        el('button', { class: 'btn s', title: 'Monter', onclick: () => { if (i > 0) { [list[i - 1], list[i]] = [list[i], list[i - 1]]; draw(); } } }, el('span', {}, '↑')),
        el('button', { class: 'btn s', title: 'Descendre', onclick: () => { if (i < list.length - 1) { [list[i + 1], list[i]] = [list[i], list[i + 1]]; draw(); } } }, el('span', {}, '↓')),
        el('button', { class: 'btn s d', title: 'Supprimer', onclick: () => { list.splice(i, 1); draw(); } }, el('span', {}, '✕')))
      , opts.extra ? el('div', { class: 'bx-x' }, opts.extra(row, draw)) : null)),
      el('button', { class: 'btn', style: 'margin-top:8px', onclick: () => { list.push(JSON.parse(JSON.stringify(blank))); draw(); } }, el('span', {}, '+ Ajouter')));
  };
  draw(); return box;
}
const B_PRICE = { k: 'price', label: 'Prix (coins)', type: 'number', w: .6 };
const rewardTypes = [['item', 'Objet'], ['money', 'Argent ($)'], ['weapon', 'Arme'], ['vip', 'VIP']];
function bRewards(wins) {   // éditeur des récompenses d'un pack / VIP
  const box = el('div', { class: 'bx-rw' });
  const kind = w => w.item !== undefined ? 'item' : w.money !== undefined ? 'money' : w.weapon !== undefined ? 'weapon' : 'vip';
  const draw = () => box.replaceChildren(el('b', {}, 'Contenu du pack (ce que le joueur reçoit)'), ...wins.map((w, i) => {
    const k = kind(w);
    const sel = el('select', { onchange: e => { for (const key of Object.keys(w)) delete w[key]; if (e.target.value === 'item') Object.assign(w, { item: '', amount: 1 }); else if (e.target.value === 'money') w.money = 1000; else if (e.target.value === 'weapon') w.weapon = 'weapon_'; else Object.assign(w, { vip: 1, days: 31 }); draw(); } }, rewardTypes.map(o => el('option', { value: o[0], selected: o[0] === k }, o[1])));
    const f = (key, ph, num, wd) => el('input', { type: num ? 'number' : 'text', value: w[key] == null ? '' : w[key], placeholder: ph, style: wd ? `max-width:${wd}px` : '', oninput: e => { w[key] = num && e.target.value !== '' ? Number(e.target.value) : e.target.value; } });
    return el('div', { class: 'bx-rwr' }, sel, ...(k === 'item' ? [f('item', 'nom de l’objet (ex : bread)'), f('amount', 'quantité', true, 110)] : k === 'money' ? [f('money', 'montant en $', true)] : k === 'weapon' ? [f('weapon', 'weapon_pistol')] : [f('vip', 'niveau 1-3', true, 110), f('days', 'jours', true, 110)]), el('button', { class: 'btn s d', onclick: () => { wins.splice(i, 1); draw(); } }, el('span', {}, '✕')));
  }), el('button', { class: 'btn s', onclick: () => { wins.push({ item: '', amount: 1 }); draw(); } }, el('span', {}, '+ Ajouter une récompense')));
  draw(); return box;
}
const crateKinds = [['vehicle', 'Véhicule'], ['weapon', 'Arme'], ['Coins', 'Coins'], ['money', 'Argent ($)'], ['item', 'Objet']];
function bCrate(c) {      // contenu d'une caisse mystère
  const box = el('div', { class: 'bx-rw' });
  const kind = it => it.vehicle !== undefined ? 'vehicle' : it.weapon !== undefined ? 'weapon' : it.Coins !== undefined ? 'Coins' : it.money !== undefined ? 'money' : 'item';
  const draw = () => box.replaceChildren(el('b', {}, 'Ce que la caisse peut donner (le niveau règle la rareté)'), ...c.list.map((it, i) => {
    const k = kind(it);
    const sel = el('select', { onchange: e => { const keep = { name: it.name, tier: it.tier }; for (const key of Object.keys(it)) delete it[key]; Object.assign(it, keep); const v = e.target.value; if (v === 'vehicle') it.vehicle = ''; else if (v === 'weapon') Object.assign(it, { weapon: 'weapon_', amount: 1 }); else if (v === 'Coins') it.Coins = 500; else if (v === 'money') it.money = 50000; else Object.assign(it, { item: '', amount: 1 }); draw(); } }, crateKinds.map(o => el('option', { value: o[0], selected: o[0] === k }, o[1])));
    const f = (key, ph, num, wd) => el('input', { type: num ? 'number' : 'text', value: it[key] == null ? '' : it[key], placeholder: ph, style: wd ? `max-width:${wd}px` : '', oninput: e => { it[key] = num && e.target.value !== '' ? Number(e.target.value) : e.target.value; } });
    const tier = el('select', { onchange: e => { it.tier = +e.target.value; } }, [1, 2, 3, 4, 5].map(n => el('option', { value: n, selected: it.tier === n }, `Niveau ${n} · ${B_TIERS[n]}`)));
    return el('div', { class: 'bx-rwr' }, f('name', 'nom affiché'), sel, ...(k === 'vehicle' ? [f('vehicle', 'modèle (ex : adder)')] : k === 'weapon' ? [f('weapon', 'weapon_pistol'), f('amount', 'qté', true, 80)] : k === 'Coins' ? [f('Coins', 'nombre de coins', true)] : k === 'money' ? [f('money', 'montant $', true)] : [f('item', 'objet'), f('amount', 'qté', true, 80)]), tier, el('button', { class: 'btn s d', onclick: () => { c.list.splice(i, 1); draw(); } }, el('span', {}, '✕')));
  }), el('button', { class: 'btn s', onclick: () => { c.list.push({ name: '', vehicle: '', tier: 5 }); draw(); } }, el('span', {}, '+ Ajouter un lot')));
  draw(); return box;
}

PAGES.boutique = async function () {
  const s = curServer(); if (!s) return needServer();
  const d = await api('GET', `/api/servers/${s.id}/docs/boutique`), D = JSON.parse(JSON.stringify(window.BOUTIQUE_DEFAULT || {}));
  const v = Object.assign(D, d.value || {});
  for (const k of ['vehicle', 'Motos', 'Autres', 'weapon', 'caisse', 'pack', 'vip', 'Entreprise', 'boost']) if (!Array.isArray(v[k])) v[k] = [];
  v.ESXCustom = v.ESXCustom || {}; v.chance = Array.isArray(v.chance) && v.chance.length ? v.chance : [1, 2, 3, 4, 5].map(i => ({ name: B_TIERS[i], rate: 20 }));
  v.Autres.forEach(r => { r._sep = !!r.Separator; });
  const tabs = [['roue', 'Roulette du jour'], ['veh', 'Véhicules'], ['moto', 'Motos'], ['autres', 'Avions et bateaux'], ['arme', 'Armes'], ['caisse', 'Caisses'], ['pack', 'Packs'], ['vip', 'VIP'], ['ent', 'Entreprises'], ['reg', 'Réglages']];
  v.wheel = Object.assign({ enabled: true, spins: 1, resetHour: 0, account: 'money', prizes: [{ label: '10 coins', kind: 'coins', amount: 10, weight: 28 }, { label: '2 500 $', kind: 'money', amount: 2500, weight: 16 }, { label: '25 coins', kind: 'coins', amount: 25, weight: 20 }, { label: '5 pains', kind: 'item', item: 'bread', amount: 5, weight: 14 }, { label: '50 coins', kind: 'coins', amount: 50, weight: 8 }, { label: '10 000 $', kind: 'money', amount: 10000, weight: 6 }, { label: '100 coins', kind: 'coins', amount: 100, weight: 2 }, { label: '-20 % boutique', kind: 'discount', amount: 20, hours: 48, weight: 8 }, { label: 'Pas de chance', kind: 'none', weight: 4 }] }, v.wheel || {});
  let tab = sessionStorage.getItem('aero_btab') || 'veh'; const body = el('div'), bar = el('div', { class: 'ex-chips' });
  const intro = (t) => el('p', { class: 'cfg-i' }, t);
  const nameModel = [{ k: 'name', label: 'Nom affiché', w: 1.4 }, { k: 'model', label: 'Modèle (code du jeu)', w: 1.2, ph: 'ex : adder' }, B_PRICE];
  const draw = () => {
    sessionStorage.setItem('aero_btab', tab);
    bar.replaceChildren(...tabs.map(([k, l]) => el('button', { class: 'btn s' + (tab === k ? ' p' : ''), onclick: () => { tab = k; draw(); } }, el('span', {}, l))));
    const card = (...c) => el('div', { class: 'card cfgcard' }, ...c);
    if (tab === 'roue') {
      const W = v.wheel, num = (k, ph, w) => el('input', { type: 'number', value: W[k], placeholder: ph, style: `max-width:${w || 160}px`, oninput: e => { W[k] = Number(e.target.value); } });
      const odds = el('div', { class: 'wprizes', style: 'margin-top:10px' });
      const drawOdds = () => { const tot = W.prizes.reduce((a, p) => a + (Number(p.weight) > 0 ? Number(p.weight) : 0), 0) || 1; odds.replaceChildren(...W.prizes.map(p => el('div', { class: 'row', style: 'gap:8px' }, el('i', { style: `display:inline-block;width:12px;height:12px;border-radius:3px;background:${/^#[0-9a-f]{6}$/i.test(p.color || '') ? p.color : '#888'}` }), el('span', { style: 'flex:1' }, p.label || '—'), el('b', {}, ((Number(p.weight) > 0 ? Number(p.weight) : 0) / tot * 100).toFixed(1).replace('.', ',') + ' %')))); };
      body.replaceChildren(card(el('h2', {}, 'Roulette du jour'), intro('Chaque joueur peut tourner la roue gratuitement et gagner un petit lot (coins, argent ou objet). Le tirage se fait sur le serveur : impossible de tricher. Les tours sont rendus à l’heure choisie. Un menu « Roulette du jour » apparaît dans la boutique en jeu.'),
        el('label', { style: 'display:flex;gap:8px;align-items:center;text-transform:none;letter-spacing:0;margin:8px 0' }, el('input', { type: 'checkbox', checked: W.enabled !== false, style: 'width:auto', onchange: e => { W.enabled = e.target.checked; } }), 'Roulette activée'),
        el('div', { class: 'row', style: 'gap:18px;flex-wrap:wrap' }, helpField('Tours gratuits par jour', 'Pour chaque joueur (1 à 10).', num('spins', '1')), helpField('Heure du renouvellement', '0 = minuit (heure du serveur).', num('resetHour', '0')),
          helpField('Compte crédité pour l’argent gagné', 'Liquide ou banque.', el('select', { onchange: e => { W.account = e.target.value; } }, [['money', 'Liquide'], ['bank', 'Banque']].map(o => el('option', { value: o[0], selected: W.account === o[0] }, o[1]))))),
        el('h3', { style: 'margin:14px 0 4px;font-size:15px' }, 'Lots de la roue (2 à 12)'), el('p', { class: 'cfg-i' }, 'Le « poids » règle la fréquence : plus il est grand, plus le lot sort souvent (la chance réelle est affichée plus bas). Type « Réduction boutique » = un bon personnel de X % sur tout le panier (usage unique, valable le nombre d’heures indiqué). Type « Rien » = case perdante. Pour un objet, indique son code (ex : bread).'),
        bRows(W.prizes, [{ k: 'label', label: 'Nom affiché sur la roue', w: 1.3, ph: '25 coins' }, { k: 'kind', label: 'Type', type: 'select', w: .8, opts: [['coins', 'Coins'], ['money', 'Argent ($)'], ['item', 'Objet'], ['discount', 'Réduction boutique (%)'], ['none', 'Rien']] }, { k: 'amount', label: 'Quantité / montant / %', type: 'number', w: .8 }, { k: 'item', label: 'Code de l’objet', w: .8, ph: 'bread' }, { k: 'hours', label: 'Durée du bon (h)', type: 'number', w: .6 }, { k: 'weight', label: 'Poids', type: 'number', w: .5 }, { k: 'color', label: 'Couleur', w: .7, ph: '#3fb950' }], { label: '', kind: 'coins', amount: 10, item: '', hours: 48, weight: 10, color: '' }),
        el('h3', { style: 'margin:16px 0 4px;font-size:15px' }, 'Chances de gagner chaque lot'), odds, el('button', { class: 'btn s', style: 'margin-top:8px', onclick: drawOdds }, el('span', {}, 'Actualiser les chances')))); drawOdds();
    } else  if (tab === 'veh') body.replaceChildren(card(el('h2', {}, 'Véhicules'), intro('Les voitures vendues contre des coins. « Modèle » est le nom de spawn du jeu (adder, zentorno…). Un joueur qui achète reçoit le véhicule dans son garage.'), bRows(v.vehicle, nameModel, { name: '', model: '', price: 1000 })));
    else if (tab === 'moto') body.replaceChildren(card(el('h2', {}, 'Motos'), intro('Les deux-roues vendus contre des coins.'), bRows(v.Motos, nameModel, { name: '', model: '', price: 1000 })));
    else if (tab === 'autres') body.replaceChildren(card(el('h2', {}, 'Avions, hélicoptères et bateaux'), intro('Une ligne « séparateur » sert de titre de section dans le menu (cochée = titre sans prix).'),
      bRows(v.Autres, [{ k: 'name', label: 'Nom / titre', w: 1.4 }, { k: 'model', label: 'Modèle', w: 1, ph: 'ex : maverick' }, { k: 'type', label: 'Type', type: 'select', w: .8, opts: [['aircraft', 'Aérien'], ['boat', 'Bateau'], ['', 'Séparateur (titre)']] }, B_PRICE], { name: '', model: '', price: 2000, type: 'aircraft' }, { extra: null })));
    else if (tab === 'arme') body.replaceChildren(card(el('h2', {}, 'Armes'), intro('Armes permanentes vendues contre des coins. Le nom doit commencer par weapon_ (ex : weapon_pistol_mk2).'), bRows(v.weapon, [{ k: 'name', label: 'Nom affiché', w: 1.4 }, { k: 'model', label: 'Arme (code du jeu)', w: 1.4, ph: 'weapon_pistol_mk2' }, { k: 'balle', label: 'Munitions', type: 'number', w: .6 }, B_PRICE], { name: '', model: 'weapon_', balle: 250, price: 1500 })));
    else if (tab === 'caisse') {
      const crates = Object.keys(v.ESXCustom);
      body.replaceChildren(
        card(el('h2', {}, 'Caisses mystère'), intro('Le joueur achète une caisse et reçoit UN lot tiré au sort dans son contenu. « Identifiant du contenu » relie la caisse à une liste de lots plus bas.'),
          bRows(v.caisse, [{ k: 'name', label: 'Nom de la caisse', w: 1.2 }, { k: 'model', label: 'Identifiant du contenu', w: 1, ph: 'ex : caisse1' }, B_PRICE, { k: 'desc', label: 'Description', type: 'area', w: 2 }], { name: '', model: '', price: 1000, desc: '' })),
        ...crates.map(id => card(el('div', { class: 'row' }, el('h2', { style: 'margin:0' }, 'Contenu : ', el('code', {}, id)), el('div', { class: 'grow' }), el('input', { value: v.ESXCustom[id].name || '', placeholder: 'Nom (affiché à l’ouverture)', style: 'max-width:240px', oninput: e => { v.ESXCustom[id].name = e.target.value; } }), el('button', { class: 'btn s d', onclick: () => { delete v.ESXCustom[id]; v.caisse.forEach(c => { if (c.model === id) c.model = ''; }); draw(); } }, el('span', {}, 'Supprimer ce contenu'))), bCrate(v.ESXCustom[id]))),
        el('button', { class: 'btn', onclick: () => { let n = 1; while (v.ESXCustom['caisse' + n]) n++; v.ESXCustom['caisse' + n] = { name: 'Caisse ' + n, list: [] }; draw(); } }, el('span', {}, '+ Nouveau contenu de caisse')),
        card(el('h2', {}, 'Rareté des lots'), intro('Chance (en %) de tomber sur chaque niveau. Le total devrait faire 100.'), bRows(v.chance, [{ k: 'name', label: 'Nom du niveau', w: 1.2, ph: '~g~Commun~s~' }, { k: 'rate', label: 'Chance (%)', type: 'number', w: .6 }], { name: '', rate: 1 })));
    } else if (tab === 'pack') body.replaceChildren(card(el('h2', {}, 'Packs'), intro('Un pack donne plusieurs récompenses d’un coup (objets, argent, armes, VIP). Les codes couleur du jeu (~y~ jaune, ~g~ vert, ~p~ violet) fonctionnent dans la description.'), bRows(v.pack, [{ k: 'name', label: 'Nom du pack', w: 1.2 }, B_PRICE, { k: 'desc', label: 'Description', type: 'area', w: 2.4 }], { name: '', price: 1000, desc: '', Win: [] }, { extra: r => bRewards(r.Win = r.Win || []) })));
    else if (tab === 'vip') body.replaceChildren(card(el('h2', {}, 'Abonnements VIP'), intro('Chaque offre donne un niveau VIP (1 bronze, 2 argent, 3 or) pour un nombre de jours. Les avantages de chaque niveau se règlent dans le script VIP.'), bRows(v.vip, [{ k: 'name', label: 'Nom de l’offre', w: 1.2 }, B_PRICE, { k: 'desc', label: 'Description', type: 'area', w: 2.4 }], { name: '', price: 1000, desc: '', Win: [{ vip: 1, days: 31 }] }, { extra: r => bRewards(r.Win = r.Win || []) })));
    else if (tab === 'ent') body.replaceChildren(card(el('h2', {}, 'Entreprises'), intro('Services vendus contre des coins (création d’un gang, d’une entreprise…). Le joueur ouvre ensuite un ticket Discord.'), bRows(v.Entreprise, [{ k: 'name', label: 'Nom', w: 1.2 }, B_PRICE, { k: 'desc', label: 'Description', type: 'area', w: 2.4 }], { name: '', price: 5000, desc: '' })));
    else {
      const num = (k, ph) => el('input', { type: 'number', value: v[k] == null ? '' : v[k], placeholder: ph, style: 'max-width:200px', oninput: e => { v[k] = e.target.value === '' ? '' : Number(e.target.value); } });
      const wc = el('input', { type: 'checkbox', checked: v.weaponCustom !== false, style: 'width:auto', onchange: e => { v.weaponCustom = e.target.checked; } });
      body.replaceChildren(card(el('h2', {}, 'Réglages généraux'),
        el('label', { style: 'display:flex;gap:8px;align-items:center;text-transform:none;letter-spacing:0' }, wc, 'Proposer les améliorations d’armes (silencieux, viseur…)'),
        helpField('Prix d’une amélioration d’arme (coins)', 'Prix de chaque amélioration vendue à l’unité.', num('weaponCustomPrice', '500')),
        helpField('Munitions données avec une arme', 'Nombre de balles fournies à l’achat d’une arme.', num('WeaponAmmoInWeapon', '250')),
        helpField('Lien de la boutique Tebex', 'Ouvert par le bouton « Acheter des coins » en jeu.', el('input', { value: v.LinkShop || '', placeholder: 'https://monserveur.tebex.io', oninput: e => { v.LinkShop = e.target.value; } })),
        el('button', { class: 'btn d', style: 'margin-top:8px', onclick: () => confirmBox('Remettre la boutique d’origine', 'Tous les produits redeviennent ceux du fichier de configuration (rien n’est enregistré tant que tu ne cliques pas sur Enregistrer).', () => { const o = JSON.parse(JSON.stringify(window.BOUTIQUE_DEFAULT || {})); for (const k of Object.keys(v)) delete v[k]; Object.assign(v, o); v.Autres.forEach(r => { r._sep = !!r.Separator; }); draw(); toast('Valeurs d’origine rechargées : clique sur Enregistrer pour les appliquer', 'ok'); }) }, el('span', {}, 'Remettre les valeurs d’origine'))));
    }
  };
  const save = async () => {
    const out = JSON.parse(JSON.stringify(v));
    out.Autres = (out.Autres || []).map(r => (r.type === '' || r.Separator || r._sep) ? { Separator: true, name: r.name } : r);
    if (out.weaponCustomPrice === '') delete out.weaponCustomPrice; if (out.WeaponAmmoInWeapon === '') delete out.WeaponAmmoInWeapon;
    const r = await api('PUT', `/api/servers/${s.id}/docs/boutique`, { value: out }); if (!r.ok) return toast(r.error, 'bad');
    toast('Boutique enregistrée : appliquée en jeu dans quelques secondes (les joueurs qui ont le menu ouvert doivent le rouvrir)', 'ok');
  };
  draw();
  return el('div', {}, head('Boutique à coins', el('button', { class: 'btn p', onclick: save }, el('span', {}, 'Enregistrer'))),
    el('div', { class: 'pg-intro' }, el('b', {}, 'À quoi sert cette page ? '), 'Elle règle TOUS les produits de la boutique en jeu (la monnaie « coins » achetée sur Tebex) : véhicules, motos, avions, bateaux, armes, caisses mystère, packs, VIP et entreprises. Les noms, prix, descriptions et contenus se modifient ici et s’appliquent sans redémarrer le serveur. Les prix sont vérifiés côté serveur à chaque achat.'), bar, body);
};
