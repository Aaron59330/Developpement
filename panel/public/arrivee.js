'use strict';
// ───────── Parcours d'arrivée (création du personnage) + apparence de l'écran de chargement ─────────
// Tout ce que voit un joueur : textes, images de fond, lieux d'apparition (photo, nom, coordonnées), musique, message de bienvenue.
// La couleur principale se règle dans « Général » et s'applique à toutes ces interfaces.

// Catalogue des textes modifiables : « texte d'origine » → nouveau texte (vide = inchangé)
const ARRIVEE_TEXTS = {
  'Identité': ['Enregistrement du Personnage', 'Prénom & Nom', 'Écrivez le prénom et le nom de votre personnage. Vous pouvez le générer aléatoirement.', 'Prénom', 'Nom', 'Date de Naissance', 'Sélectionnez la date de naissance de votre personnage.', 'Taille', 'Choisissez la taille de votre personnage (140 – 200 cm).', 'Nationalité', 'Choisissez la nationalité de votre personnage.', 'Genre', 'Homme', 'Femme', 'Aléatoire', 'Créer', 'Annuler'],
  'Apparence': ['Apparence', 'Coiffure', 'Vêtements', 'Visage', 'Créez votre personnage selon vos envies.', 'Couleur des yeux', 'Choisissez la couleur des yeux de votre personnage.', 'Traits', 'Ajustez les caractéristiques faciales de votre personnage.', 'Cheveux & pilosité', 'Style, couleur, barbe, sourcils et maquillage.', 'Haut, bas, chaussures et accessoires.', 'Sélectionnez un visage parmi les options disponibles.', 'Réinitialiser', 'Terminer'],
  'Point d’apparition': ['Point d\'apparition', 'Choisissez votre point d\'apparition sur la carte de Los Santos.', 'Apparaître ici'],
  'Bienvenue': ['Continuer'],
  'Animations': ['GESTIONNAIRE', 'ANIMATIONS', 'Tout', 'Animations', 'Objets', 'À deux', 'Expressions', 'Démarches', 'Favoris', 'Attribuez des touches', 'RACCOURCIS', 'Recherchez une animation', 'Trier :', 'De A à Z', 'De Z à A'],
};
const LOADING_TEXTS = ['Règlement', 'Discord', 'Boutique', 'Équipe', 'Mises à jour'];

// Éditeur de textes réutilisable : renvoie { node, get() } ; get() ne renvoie que les textes réellement modifiés
function arriveeTexts(groups, current) {
  const inputs = {}, node = el('div');
  for (const [g, list] of Object.entries(groups)) {
    node.append(el('h3', { style: 'margin:14px 0 6px;font-size:13px;opacity:.8' }, g));
    for (const t of list) {
      if (inputs[t]) continue;
      const i = el('input', { value: (current && current[t]) || '', placeholder: t });
      inputs[t] = i;
      node.append(el('div', { style: 'margin-bottom:6px' }, el('div', { class: 'muted', style: 'font-size:11px;margin-bottom:2px' }, t.length > 70 ? t.slice(0, 68) + '…' : t), i));
    }
  }
  return { node, get: () => Object.fromEntries(Object.entries(inputs).map(([k, i]) => [k, i.value.trim()]).filter(([, v]) => v)) };
}


// ───────── Champ image : lien https:// OU fichier .png / .jpg envoyé depuis l'ordinateur (rien d'autre) ─────────
// Renvoie { node, input } : input.value = lien final (https://…) ou nom de fichier d'une image déjà dans la ressource.
function imageField(value, placeholder) {
  const sid = () => (curServer() || {}).id;
  const input = el('input', { value: value || '', placeholder: placeholder || 'https://… lien d’image, ou envoie un fichier .png / .jpg' });
  const prev = el('img', { style: 'display:none;max-height:54px;max-width:96px;border-radius:6px;margin-left:8px;object-fit:cover' });
  const msg = el('div', { class: 'muted', style: 'font-size:11px;margin-top:2px;min-height:14px' });
  const file = el('input', { type: 'file', accept: '.png,.jpg,.jpeg,image/png,image/jpeg', style: 'display:none' });
  const show = () => {
    const v = input.value.trim(); const ok = !v || /^https:\/\//i.test(v) || /^[\w\- .\/]+\.(png|jpe?g)$/i.test(v);
    msg.textContent = ok ? '' : 'Lien invalide : il doit commencer par https:// (ou être un fichier .png / .jpg).'; msg.style.color = ok ? '' : '#e5484d';
    if (/^https:\/\//i.test(v)) { prev.src = v; prev.style.display = ''; } else prev.style.display = 'none';
  };
  input.addEventListener('input', show); prev.onerror = () => { prev.style.display = 'none'; }; show();
  file.onchange = async () => {
    const f = file.files[0]; file.value = ''; if (!f) return;
    if (!/\.(png|jpe?g)$/i.test(f.name) || !/^image\/(png|jpeg)$/.test(f.type)) { msg.textContent = 'Seuls les fichiers .png et .jpg sont acceptés.'; msg.style.color = '#e5484d'; return; }
    if (f.size > 1500000) { msg.textContent = 'Fichier trop lourd (1,5 Mo maximum).'; msg.style.color = '#e5484d'; return; }
    msg.textContent = 'Envoi…'; msg.style.color = '';
    const data = await new Promise(res => { const r = new FileReader(); r.onload = () => res(String(r.result).split(',')[1] || ''); r.readAsDataURL(f); });
    const up = await api('POST', `/api/servers/${sid()}/drive`, { name: f.name, mime: f.type, data });
    if (!up.ok) { msg.textContent = up.error || 'Envoi impossible'; msg.style.color = '#e5484d'; return; }
    const list = (await api('GET', `/api/servers/${sid()}/drive`)).files || []; const hit = list.find(x => x.token === up.token);
    if (!hit) { msg.textContent = 'Fichier envoyé mais lien introuvable : réessaie.'; msg.style.color = '#e5484d'; return; }
    input.value = hit.url; input.dispatchEvent(new Event('input')); toast('Image envoyée', 'ok');
  };
  const btn = el('button', { class: 'btn s', type: 'button', onclick: () => file.click() }, el('span', {}, 'Envoyer un fichier'));
  return { input, node: el('div', { style: 'margin-bottom:6px' }, el('div', { class: 'row', style: 'gap:6px;align-items:center' }, input, btn, prev), msg, file) };
}

const ARRIVEE_DEFAULT = {
  texts: {}, bg: { identity: '', skin: '', spawn: '', welcome: '', emotes: '', dim: 35 },
  music: { enabled: true, volume: 35, tracks: [] },
  studio: { enabled: true, x: 501.0, y: 5604.0, z: 797.9, h: 180, camDistance: 2.4, camHeight: 0.45 },
  spots: [
    { label: 'Aéroport de Los Santos', description: 'Arrive comme tout nouveau venu en ville.', icon: 'plane', image: 'airport.jpg', x: -1037, y: -2737, z: 20.17, h: 330 },
    { label: 'Legion Square', description: 'Au cœur de la ville, près de tout.', icon: 'city', image: 'legion.jpg', x: 195.17, y: -933.77, z: 30.69, h: 144 },
    { label: 'Plage de Vespucci', description: 'Un début de vie au bord de l\'océan.', icon: 'beach', image: 'vespucci.jpg', x: -1392, y: -1430, z: 4, h: 25 },
  ],
  map: { image: '', minX: -4100, maxX: 4500, minY: -4200, maxY: 8000 },
  welcome: { enabled: true, title: 'Bienvenue sur le', highlight: 'serveur', text: 'Afin de vous garantir une expérience optimale, nous vous invitons à lire le règlement et à profiter de votre aventure.', duration: 9000, logo: '' },
};

PAGES.creator = async function () {
  const s = curServer(); if (!s) return needServer();
  const [d, dr] = await Promise.all([api('GET', `/api/servers/${s.id}/docs/creator`), api('GET', `/api/servers/${s.id}/drive`)]);
  const raw = d.value || {}, D = ARRIVEE_DEFAULT;
  const v = {
    texts: raw.texts || {}, bg: { ...D.bg, ...(raw.bg || {}) }, music: { ...D.music, ...(raw.music || {}) },
    studio: raw.studio && raw.studio.x !== undefined ? { ...D.studio, ...raw.studio } : { ...D.studio },
    spots: (raw.spots && raw.spots.length ? raw.spots : D.spots).map(x => ({ ...x })), map: { ...D.map, ...(raw.map || {}) }, welcome: { ...D.welcome, ...(raw.welcome || {}) },
  };
  v.music.tracks = (v.music.tracks || []).map(x => ({ ...x }));
  const images = (dr.files || []).filter(f => String(f.mime || '').startsWith('image/')), audios = (dr.files || []).filter(f => String(f.mime || '').startsWith('audio/'));
  const sec = (title, hint, ...body) => el('div', { class: 'card' }, el('h2', {}, title), hint ? el('p', { class: 'muted', style: 'margin:-6px 0 10px' }, hint) : null, ...body);
  const lab = t => el('label', {}, t);
  const inp = (val, ph, extra) => el('input', { value: val == null ? '' : val, placeholder: ph || '', ...(extra || {}) });
  const num = (val, ph, step) => el('input', { type: 'number', value: val, placeholder: ph || '', step: step || 'any' });
  const pick = (list, target, label) => el('select', { onchange: e => { if (e.target.value) { target.value = e.target.value; target.dispatchEvent(new Event('input')); } e.target.value = ''; } }, el('option', { value: '' }, list.length ? label : '— Aucun fichier dans ton Drive (Identité & thème → Drive) —'), ...list.map(a => el('option', { value: a.url }, a.name)));
  const swc = (cb, text) => el('label', { style: 'display:flex;gap:8px;align-items:center;text-transform:none;letter-spacing:0;margin:8px 0' }, cb, text);

  // fonds d'écran
  const bgIn = {}; const bgBox = el('div');
  for (const [k, l] of [['identity', 'Création d’identité'], ['skin', 'Apparence / vêtements'], ['spawn', 'Point d’apparition (fond de carte)'], ['welcome', 'Message de bienvenue'], ['emotes', 'Gestionnaire d’animations']]) {
    const f = imageField(v.bg[k], 'Lien d’image ou fichier (vide = on voit le monde du jeu)'); bgIn[k] = f.input;
    bgBox.append(lab(l), f.node);
  }
  const dim = el('input', { type: 'range', min: 0, max: 100, value: v.bg.dim, style: 'padding:0' }), dimT = el('b', {}, v.bg.dim + ' %'); dim.oninput = () => { dimT.textContent = dim.value + ' %'; };
  // musique
  const mEn = el('input', { type: 'checkbox', checked: v.music.enabled, style: 'width:auto' }), mVol = el('input', { type: 'range', min: 0, max: 100, value: v.music.volume, style: 'padding:0' }), mVolT = el('b', {}, v.music.volume + ' %'); mVol.oninput = () => { mVolT.textContent = mVol.value + ' %'; };
  const tracksBox = el('div');
  const drawTracks = () => tracksBox.replaceChildren(...v.music.tracks.map((t, i) => {
    const f = inp(t.file, 'https://…mp3 ou nom de fichier dans pickax_creator/html/music', { oninput: e => { t.file = e.target.value; } });
    return el('div', { class: 'card', style: 'margin:0 0 8px' }, el('div', { class: 'row' }, inp(t.title, 'Titre', { oninput: e => { t.title = e.target.value; } }), inp(t.artist, 'Artiste', { oninput: e => { t.artist = e.target.value; } }), el('button', { class: 'btn s', onclick: () => { v.music.tracks.splice(i, 1); drawTracks(); } }, el('span', {}, 'Retirer'))), f, pick(audios, f, '— Choisir une musique de mon Drive —'), (() => { const cf = imageField(t.cover, 'Pochette (lien ou fichier .png / .jpg, facultatif)'); cf.input.addEventListener('input', () => { t.cover = cf.input.value; }); return cf.node; })());
  }));
  drawTracks();
  // studio
  const st = { enabled: el('input', { type: 'checkbox', checked: v.studio.enabled !== false, style: 'width:auto' }), x: num(v.studio.x), y: num(v.studio.y), z: num(v.studio.z), h: num(v.studio.h), camDistance: num(v.studio.camDistance, '', 0.1), camHeight: num(v.studio.camHeight, '', 0.05) };
  // lieux
  const spotsBox = el('div');
  const drawSpots = () => spotsBox.replaceChildren(...v.spots.map((p, i) => {
    const imf = imageField(p.image, 'Lien d’image ou fichier .png / .jpg'); const im = imf.input; im.addEventListener('input', () => { p.image = im.value; });
    const c = (k, ph) => num(p[k], ph, 'any'); const cs = ['x', 'y', 'z', 'h'].map(k => { const n = c(k, k.toUpperCase()); n.oninput = () => { p[k] = Number(n.value); }; return n; });
    return el('div', { class: 'card', style: 'margin:0 0 10px' }, el('div', { class: 'row' }, inp(p.label, 'Nom du lieu', { oninput: e => { p.label = e.target.value; } }), el('button', { class: 'btn s', onclick: () => { v.spots.splice(i, 1); drawSpots(); } }, el('span', {}, 'Retirer'))),
      inp(p.description, 'Description courte', { oninput: e => { p.description = e.target.value; } }), lab('Image de la carte'), imf.node,
      el('div', { class: 'row', style: 'gap:6px;margin-top:6px' }, ...cs), el('p', { class: 'muted', style: 'font-size:11px;margin:4px 0 0' }, 'Coordonnées X · Y · Z · cap (copie-les en jeu avec ton menu staff).'));
  }));
  drawSpots();
  const mapF = imageField(v.map.image, 'Image de la carte de Los Santos (vide = fond sombre)'); const map = { image: mapF.input, minX: num(v.map.minX), maxX: num(v.map.maxX), minY: num(v.map.minY), maxY: num(v.map.maxY) };
  // bienvenue
  const w = { enabled: el('input', { type: 'checkbox', checked: v.welcome.enabled !== false, style: 'width:auto' }), title: inp(v.welcome.title, 'Bienvenue sur le'), highlight: inp(v.welcome.highlight, 'serveur'), text: el('textarea', { rows: 3, value: v.welcome.text || '' }), duration: num(v.welcome.duration, '9000', 500), logo: null }; const wLogo = imageField(v.welcome.logo, 'Logo (vide = logo du serveur)'); w.logo = wLogo.input;
  const tx = arriveeTexts(ARRIVEE_TEXTS, v.texts);

  const collect = () => ({
    texts: tx.get(),
    bg: { ...Object.fromEntries(Object.entries(bgIn).map(([k, i]) => [k, i.value.trim()])), dim: +dim.value },
    music: { enabled: mEn.checked, volume: +mVol.value, tracks: v.music.tracks.filter(t => (t.file || '').trim()).map(t => ({ title: t.title || '', artist: t.artist || '', file: t.file.trim(), cover: (t.cover || '').trim() })) },
    studio: { enabled: st.enabled.checked, x: st.x.value, y: st.y.value, z: st.z.value, h: st.h.value, camDistance: st.camDistance.value, camHeight: st.camHeight.value },
    spots: v.spots.filter(p => (p.label || '').trim()).map(p => ({ label: p.label.trim(), description: p.description || '', icon: p.icon || '', image: (p.image || '').trim(), x: p.x, y: p.y, z: p.z, h: p.h })),
    map: { image: map.image.value.trim(), minX: map.minX.value, maxX: map.maxX.value, minY: map.minY.value, maxY: map.maxY.value },
    welcome: { enabled: w.enabled.checked, title: w.title.value.trim(), highlight: w.highlight.value.trim(), text: w.text.value.trim(), duration: w.duration.value, logo: w.logo.value.trim() },
  });
  const save = async () => {
    const r = await api('PUT', `/api/servers/${s.id}/docs/creator`, { value: collect() }); if (!r.ok) return toast(r.error, 'bad');
    toast('Parcours d’arrivée enregistré : pris en compte en jeu dans quelques secondes (sans redémarrage)', 'ok');
  };
  return el('div', {}, head('Parcours d’arrivée', el('button', { class: 'btn p', onclick: save }, el('span', {}, 'Enregistrer'))),
    el('p', { class: 'muted', style: 'margin-bottom:12px' }, 'Création d’identité, apparence, point d’apparition, bienvenue et animations : textes, images, lieux, musique. La couleur principale se règle dans ', el('a', { href: '#/theme' }, 'Couleurs & logos'), ' et s’applique partout. Aucun redémarrage nécessaire.'),
    el('div', { class: 'grid g2', style: 'align-items:start' },
      el('div', {},
        sec('Images de fond', 'Une image par écran (lien https:// ou fichier de ton Drive). Vide = on voit le jeu derrière.', bgBox, el('label', {}, 'Assombrissement ', dimT), dim),
        sec('Points d’apparition', 'Les lieux proposés après la création du personnage (photo, nom, texte, coordonnées).', spotsBox, el('button', { class: 'btn', onclick: () => { v.spots.push({ label: '', description: '', icon: 'pin', image: '', x: 0, y: 0, z: 30, h: 0 }); drawSpots(); } }, el('span', {}, '+ Ajouter un lieu')),
          el('h3', { style: 'margin:16px 0 6px;font-size:13px' }, 'Carte de fond'), mapF.node, el('div', { class: 'row', style: 'gap:6px;margin-top:6px' }, map.minX, map.maxX, map.minY, map.maxY), el('p', { class: 'muted', style: 'font-size:11px' }, 'Bornes du monde (X min · X max · Y min · Y max) : servent à placer les repères sur l’image.')),
        sec('Message de bienvenue', 'Affiché une fois arrivé au point choisi.', swc(w.enabled, 'Afficher le message'), lab('Début du titre'), w.title, lab('Mot mis en couleur (suivi du nom du serveur)'), w.highlight, lab('Texte'), w.text, lab('Durée (ms, 0 = reste jusqu’au clic)'), w.duration, lab('Logo'), wLogo.node)),
      el('div', {},
        sec('Musique', 'Jouée pendant l’identité et l’apparence ; le joueur peut la couper.', swc(mEn, 'Musique activée'), el('label', {}, 'Volume ', mVolT), mVol, tracksBox, el('button', { class: 'btn', onclick: () => { v.music.tracks.push({ title: '', artist: '', file: '', cover: '' }); drawTracks(); } }, el('span', {}, '+ Ajouter une musique'))),
        sec('Décor de création (studio)', 'Là où le personnage est placé pendant l’identité et l’apparence, puis renvoyé à son point de départ.', swc(st.enabled, 'Téléporter le joueur au studio'), el('div', { class: 'row', style: 'gap:6px' }, st.x, st.y, st.z, st.h), el('div', { class: 'row', style: 'gap:6px;margin-top:6px' }, el('div', {}, lab('Distance caméra'), st.camDistance), el('div', {}, lab('Hauteur de visée'), st.camHeight))),
        sec('Tous les textes', 'Remplace un texte de l’interface (laisse vide pour garder le texte d’origine).', tx.node))));
};

// ───────── Écran de chargement : apparence (fond, logo, textes, éléments masqués) ─────────
// Complète la page « Écran d’accueil » : voir PAGES.loading (config.js) qui appelle loadingAppearance().
function loadingAppearance(v) {
  const images = [];
  const bgF = imageField((v.bg && v.bg.image) || '', 'Image de fond (vide = image d’origine du serveur)'), bgImg = bgF.input;
  const dim = el('input', { type: 'range', min: 0, max: 100, value: (v.bg && v.bg.dim) || 0, style: 'padding:0' }), dimT = el('b', {}, ((v.bg && v.bg.dim) || 0) + ' %'); dim.oninput = () => { dimT.textContent = dim.value + ' %'; };
  const blur = el('input', { type: 'range', min: 0, max: 20, value: (v.bg && v.bg.blur) || 0, style: 'padding:0' }), blurT = el('b', {}, ((v.bg && v.bg.blur) || 0) + ' px'); blur.oninput = () => { blurT.textContent = blur.value + ' px'; };
  const logoF = imageField(v.logo || '', 'Logo (vide = logo du serveur)'), logo = logoF.input;
  const H = { logo: 'Logo', name: 'Nom du serveur', links: 'Boutons Règlement / Discord / Boutique', ticker: 'Bandeau défilant', progress: 'Barre de progression' };
  const hide = {}; const hideBox = el('div');
  for (const [k, l] of Object.entries(H)) { hide[k] = el('input', { type: 'checkbox', checked: !!(v.hide && v.hide[k]), style: 'width:auto' }); hideBox.append(el('label', { style: 'display:flex;gap:8px;align-items:center;text-transform:none;letter-spacing:0;margin:6px 0' }, hide[k], 'Masquer : ' + l)); }
  const tx = arriveeTexts({ 'Libellés': LOADING_TEXTS }, v.texts || {});
  return {
    node: el('div', { class: 'card' }, el('h2', {}, 'Apparence'), el('p', { class: 'muted', style: 'margin:-6px 0 10px' }, 'Fond, logo, libellés et éléments affichés. La couleur principale vient de « Couleurs & logos ».'),
      el('label', {}, 'Image de fond'), bgF.node, el('label', {}, 'Assombrissement ', dimT), dim, el('label', {}, 'Flou ', blurT), blur, el('label', {}, 'Logo'), logoF.node, hideBox, tx.node),
    get: () => ({ bg: { image: bgImg.value.trim(), dim: +dim.value, blur: +blur.value }, logo: logo.value.trim(), texts: tx.get(), hide: Object.fromEntries(Object.entries(hide).map(([k, i]) => [k, i.checked])) }),
  };
}
