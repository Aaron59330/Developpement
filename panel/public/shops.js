'use strict';
// ───────── Boutiques créées en jeu (pickax_shopbuilder) : liste, produits, prix, stocks, emplacements, vendeur, carte ─────────
// Appelle les mêmes fonctions que le builder en jeu (/shopbuilder) : mêmes contrôles, même sauvegarde en base, appliqué tout de suite sur le serveur.
PAGES.shops = async function () {
  const s = curServer(); if (!s) return needServer();
  const root = el('div'); let cat = null;
  const API = (m, u, b) => api(m, `/api/servers/${s.id}/shops${u}`, b);
  const money = n => Number(n || 0).toLocaleString('fr-FR') + ' $';
  const err = r => el('div', { class: 'card empty' }, el('h2', {}, 'Impossible de charger les boutiques'), el('p', {}, r.error || 'Le serveur ne répond pas.'), el('p', { class: 'muted' }, 'Vérifie que le serveur est en ligne et que la ressource pickax_shopbuilder est démarrée.'));
  const setRoot = (...n) => root.replaceChildren(...n);

  // ─────────── liste ───────────
  const showList = async () => {
    setRoot(head('Boutiques en jeu'), el('div', { class: 'card empty' }, 'Chargement…'));
    const [r, c] = await Promise.all([API('GET', ''), cat ? Promise.resolve(cat) : API('GET', '/catalog')]);
    if (!r.ok) return setRoot(head('Boutiques en jeu'), err(r)); if (c.ok) cat = c;
    const list = Array.isArray(r.shops) ? r.shops : (Array.isArray(r) ? r : (r.list || []));
    const types = (cat && cat.types) || [];
    const newBtn = el('button', { class: 'btn p', onclick: () => ask('Nouvelle boutique', [{ name: 'label', label: 'Nom de la boutique' }, { name: 'type', label: 'Modèle (' + types.map(t => t.id).join(', ') + ')', value: (types[0] || {}).id || '' }], async v => { const x = await API('POST', '', { type: v.type, label: v.label }); if (!x.ok) { toast(x.error, 'bad'); return false; } toast('Boutique créée : place-la ensuite en jeu avec /shopbuilder ou ajoute ses emplacements ici', 'ok'); showList(); }) }, el('span', {}, '+ Nouvelle boutique'));
    setRoot(head('Boutiques en jeu', newBtn),
      el('div', { class: 'pg-intro' }, el('b', {}, 'À quoi sert cette page ? '), 'Toutes les boutiques créées avec le builder en jeu (supérettes, armureries, vêtements, pharmacies, marché noir…). Clique sur une boutique pour changer ses produits, ses prix, ses stocks, ses horaires, ses emplacements, son vendeur et son icône sur la carte. Tout s’applique tout de suite sur le serveur.'),
      list.length ? el('div', { class: 'grid g3' }, list.map(sh => el('div', { class: 'card', style: 'cursor:pointer;margin:0', onclick: () => showShop(sh.id) },
        el('div', { class: 'row' }, el('h2', { style: 'margin:0;flex:1' }, sh.label), el('span', { class: 'pill ' + (sh.enabled ? 'ok' : 'bad') }, sh.enabled ? 'Active' : 'Désactivée')),
        el('p', { class: 'muted', style: 'margin:6px 0' }, `${(types.find(t => t.id === sh.type) || {}).label || sh.type} · ${sh.items} produit(s) · ${sh.locations} emplacement(s)`),
        el('p', { class: 'muted', style: 'margin:0;font-size:12px' }, `${sh.sales || 0} vente(s) · ${money(sh.revenue)} encaissés`)))) : el('div', { class: 'card empty' }, 'Aucune boutique pour le moment : crée-en une avec le bouton ci-dessus.'));
  };

  // ─────────── édition d'une boutique ───────────
  const showShop = async id => {
    setRoot(head('Boutique'), el('div', { class: 'card empty' }, 'Chargement…'));
    const r = await API('GET', '/' + id); if (!r.ok) return setRoot(head('Boutique'), err(r));
    const shop = r.shop, S = shop.settings = shop.settings || {};
    S.hours = S.hours || { enabled: false, from: 8, to: 22 }; S.restock = S.restock || { minutes: 0, amount: 0 }; S.ped = S.ped || { enabled: false, model: '', scenario: '', dialog: { enabled: true, text: '' } }; S.ped.dialog = S.ped.dialog || { enabled: true, text: '' };
    S.blip = S.blip || { enabled: false, sprite: 52, color: 0, scale: .8, label: '' }; S.payments = S.payments || { cash: true, bank: true }; S.access = S.access || { jobs: {}, license: '' }; S.clothing = S.clothing || { price: 100, parts: [] };
    shop.items = (shop.items || []).map(it => ({ ...it, enabled: it.enabled === false ? 'false' : 'true' })); shop.locations = shop.locations || [];
    const catsTxt = el('textarea', { rows: 4, value: (S.categories || []).join('\n'), placeholder: 'Une catégorie par ligne', oninput: e => { S.categories = e.target.value.split('\n').map(x => x.trim()).filter(Boolean); } });
    const inp = (obj, k, ph, num, w) => el('input', { type: num ? 'number' : 'text', value: obj[k] == null ? '' : obj[k], placeholder: ph || '', style: w ? `max-width:${w}px` : '', oninput: e => { obj[k] = num && e.target.value !== '' ? Number(e.target.value) : e.target.value; } });
    const chk = (obj, k, text) => el('label', { style: 'display:flex;gap:8px;align-items:center;text-transform:none;letter-spacing:0;margin:6px 0' }, el('input', { type: 'checkbox', checked: !!obj[k], style: 'width:auto', onchange: e => { obj[k] = e.target.checked; } }), text);
    const enabled = el('input', { type: 'checkbox', checked: !!shop.enabled, style: 'width:auto', onchange: e => { shop.enabled = e.target.checked; } });
    const label = el('input', { value: shop.label || '', oninput: e => { shop.label = e.target.value; } });
    const dl = el('datalist', { id: 'shop-items' }, ((cat && cat.items) || []).slice(0, 4000).map(i => el('option', { value: i.name }, i.label)));
    let tab = 'prod'; const body = el('div'), bar = el('div', { class: 'ex-chips' });
    const clothing = S.mode === 'clothing';
    const tabs = [...(clothing ? [] : [['prod', 'Produits']]), ['gen', 'Général'], ['loc', 'Emplacements'], ['ped', 'Vendeur et carte'], ['act', 'Actions']]; if (clothing) tab = 'gen';
    const card = (...c) => el('div', { class: 'card cfgcard' }, ...c);
    const draw = () => {
      bar.replaceChildren(...tabs.map(([k, l]) => el('button', { class: 'btn s' + (tab === k ? ' p' : ''), onclick: () => { tab = k; draw(); } }, el('span', {}, l))));
      if (tab === 'prod') body.replaceChildren(card(el('h2', {}, 'Produits'), el('p', { class: 'cfg-i' }, 'Ce que vend la boutique. « Objet » est le code de l’objet dans l’inventaire (choisis dans la liste). Stock −1 = illimité. Promo = réduction en % sur ce produit. Désactiver un produit le masque sans le supprimer.'), dl,
        bRows(shop.items, [{ k: 'name', label: 'Objet (code)', w: 1.1, ph: 'ex : bread' }, { k: 'label', label: 'Nom affiché', w: 1.2 }, { k: 'price', label: 'Prix $', type: 'number', w: .6 }, { k: 'category', label: 'Catégorie', w: .8 }, { k: 'stock', label: 'Stock', type: 'number', w: .5 }, { k: 'max_stock', label: 'Stock max', type: 'number', w: .5 }, { k: 'max', label: 'Max / achat', type: 'number', w: .5 }, { k: 'promo', label: 'Promo %', type: 'number', w: .45 }, { k: 'enabled', label: 'Actif', type: 'select', w: .5, opts: [['true', 'Oui'], ['false', 'Non']] }], { name: '', label: '', price: 10, category: '', stock: -1, max_stock: 0, max: 20, promo: 0, license: '', jobs: [], ammo: 0, enabled: 'true' })));
      else if (tab === 'gen') body.replaceChildren(card(el('h2', {}, 'Général'),
        helpField('Nom de la boutique', 'Le nom affiché aux joueurs.', label), el('label', { style: 'display:flex;gap:8px;align-items:center;text-transform:none;letter-spacing:0;margin:6px 0 14px' }, enabled, 'Boutique active (visible et utilisable en jeu)'),
        clothing ? helpField('Prix d’une pièce de vêtement ($)', 'Prix de chaque vêtement essayé et acheté.', inp(S.clothing, 'price', '100', true, 200)) : null,
        helpField('Réduction générale (%)', 'S’applique à tous les produits.', inp(S, 'discount', '0', true, 160)),
        helpField('Société (compte qui encaisse)', 'Nom du compte société qui reçoit l’argent des ventes. Vide = l’argent disparaît.', inp(S, 'society', 'ex : society_police')),
        helpField('Note aux joueurs', 'Court message affiché dans la boutique.', inp(S, 'note', '')),
        helpField('Permis requis pour entrer', 'Nom d’un permis (ex : weapon). Vide = aucun.', inp(S.access, 'license', '')),
        el('div', { class: 'hf' }, el('div', { class: 'hf-l' }, 'Horaires d’ouverture'), chk(S.hours, 'enabled', 'Limiter les horaires'), el('div', { class: 'row', style: 'gap:8px' }, 'de', inp(S.hours, 'from', '8', true, 90), 'h à', inp(S.hours, 'to', '22', true, 90), 'h')),
        el('div', { class: 'hf' }, el('div', { class: 'hf-l' }, 'Moyens de paiement'), ...(((cat && cat.payments) || [{ id: 'cash', label: 'Liquide' }, { id: 'bank', label: 'Banque' }]).map(p => chk(S.payments, p.id, p.label)))),
        el('div', { class: 'hf' }, el('div', { class: 'hf-l' }, 'Réapprovisionnement automatique'), el('div', { class: 'hf-h' }, 'Toutes les X minutes, chaque produit à stock limité regagne Y unités (0 = désactivé).'), el('div', { class: 'row', style: 'gap:8px' }, 'toutes les', inp(S.restock, 'minutes', '0', true, 110), 'min, +', inp(S.restock, 'amount', '0', true, 110))),
        helpField('Catégories de produits', 'Les onglets de la boutique (une par ligne). Elles sont créées automatiquement à partir des produits.', catsTxt)));
      else if (tab === 'loc') body.replaceChildren(card(el('h2', {}, 'Emplacements'), el('p', { class: 'cfg-i' }, 'Les endroits où se trouve la boutique sur la carte. Copie les coordonnées en jeu avec ton menu staff (/coords). Un même magasin peut avoir plusieurs emplacements (par exemple toutes les supérettes).'),
        bRows(shop.locations.map(l => { l.x = l.coords.x; l.y = l.coords.y; l.z = l.coords.z; l.h = l.coords.h; return l; }), [{ k: 'label', label: 'Nom du lieu', w: 1.2 }, { k: 'x', label: 'X', type: 'number', w: .8 }, { k: 'y', label: 'Y', type: 'number', w: .8 }, { k: 'z', label: 'Z', type: 'number', w: .6 }, { k: 'h', label: 'Cap', type: 'number', w: .5 }], { label: '', x: 0, y: 0, z: 30, h: 0, coords: { x: 0, y: 0, z: 30, h: 0 } })));
      else if (tab === 'ped') {
        const scen = el('select', { onchange: e => { S.ped.scenario = e.target.value; } }, el('option', { value: '' }, '— aucune —'), ...((cat && cat.scenarios) || []).map(x => el('option', { value: typeof x === 'string' ? x : x.id, selected: (typeof x === 'string' ? x : x.id) === S.ped.scenario }, typeof x === 'string' ? x : (x.label || x.id))));
        body.replaceChildren(card(el('h2', {}, 'Vendeur (PNJ)'), chk(S.ped, 'enabled', 'Afficher un vendeur'), helpField('Modèle du PNJ', 'Le nom du personnage du jeu (ex : mp_m_shopkeep_01).', inp(S.ped, 'model', 'mp_m_shopkeep_01')), helpField('Animation', 'Ce que fait le vendeur quand il attend.', scen), chk(S.ped.dialog, 'enabled', 'Dialogue avant d’ouvrir la boutique'), helpField('Texte du dialogue', 'Phrase dite par le vendeur.', inp(S.ped.dialog, 'text', 'Bonjour, que puis-je faire pour vous ?'))),
          card(el('h2', {}, 'Icône sur la carte'), chk(S.blip, 'enabled', 'Afficher une icône sur la carte'), helpField('Nom sur la carte', 'Texte au survol de l’icône.', inp(S.blip, 'label', '')), el('div', { class: 'row', style: 'gap:8px' }, helpField('Icône (n°)', 'Numéro de l’icône du jeu.', inp(S.blip, 'sprite', '52', true, 120)), helpField('Couleur (n°)', '0 à 85.', inp(S.blip, 'color', '0', true, 120)), helpField('Taille', '0.1 à 3.', inp(S.blip, 'scale', '0.8', true, 120)))));
      } else body.replaceChildren(card(el('h2', {}, 'Actions'), el('div', { class: 'row', style: 'gap:8px;flex-wrap:wrap' },
        el('button', { class: 'btn', onclick: async () => { const x = await API('POST', `/${shop.id}/restock`, { mode: 'full' }); toast(x.ok ? 'Tous les produits sont remplis au maximum' : x.error, x.ok ? 'ok' : 'bad'); } }, el('span', {}, 'Remplir tous les stocks')),
        el('button', { class: 'btn', onclick: () => ask('Fixer tous les stocks', [{ name: 'amount', label: 'Quantité pour chaque produit', value: '50' }], async v => { const x = await API('POST', `/${shop.id}/restock`, { mode: 'all', amount: Number(v.amount) }); toast(x.ok ? 'Stocks mis à jour' : x.error, x.ok ? 'ok' : 'bad'); if (!x.ok) return false; }) }, el('span', {}, 'Fixer tous les stocks à…')),
        el('button', { class: 'btn', onclick: async () => { const x = await API('POST', `/${shop.id}/duplicate`, {}); if (x.ok) { toast('Boutique dupliquée', 'ok'); showList(); } else toast(x.error, 'bad'); } }, el('span', {}, 'Dupliquer la boutique')),
        el('button', { class: 'btn d', onclick: () => confirmBox('Supprimer la boutique', `« ${shop.label} » sera supprimée définitivement (produits, emplacements, statistiques).`, async () => { const x = await API('DELETE', `/${shop.id}`); if (x.ok) { toast('Boutique supprimée', 'ok'); showList(); } else toast(x.error, 'bad'); }) }, el('span', {}, 'Supprimer la boutique'))),
        el('p', { class: 'muted', style: 'margin-top:12px' }, `Statistiques : ${(shop.stats && shop.stats.sales) || 0} vente(s), ${money(shop.stats && shop.stats.revenue)} encaissés.`)));
    };
    const save = async () => {
      const out = JSON.parse(JSON.stringify(shop));
      out.items = out.items.map(it => { const o = { ...it, enabled: it.enabled !== 'false' }; ['price', 'stock', 'max_stock', 'max', 'promo', 'ammo'].forEach(k => { o[k] = Number(o[k]) || 0; }); if (it.stock === '' || it.stock == null) o.stock = -1; return o; });
      out.locations = out.locations.map(l => ({ label: l.label, tag: l.tag, ped: l.ped, coords: { x: Number(l.x), y: Number(l.y), z: Number(l.z), h: Number(l.h) || 0 } }));
      const x = await API('PUT', '/' + shop.id, { shop: out }); if (!x.ok) return toast(x.error, 'bad');
      toast('Boutique enregistrée : appliquée sur le serveur', 'ok');
    };
    draw();
    setRoot(head(shop.label || 'Boutique', el('button', { class: 'btn', onclick: showList }, el('span', {}, '← Toutes les boutiques')), el('button', { class: 'btn p', onclick: save }, el('span', {}, 'Enregistrer'))), bar, body);
  };
  showList(); return root;
};
