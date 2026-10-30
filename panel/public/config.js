'use strict';
// ───────── Configuration : Écran de chargement + Réglages du serveur (catégories, sections, recherche, export / import) ─────────

// ═══════════════ ÉCRAN DE CHARGEMENT ═══════════════
const LOADING_DEFAULT = {
  tips: ['Bon jeu sur notre serveur 🍹', 'N’hésitez pas à faire un tour sur notre boutique (F1)', 'Lisez le règlement pour éviter toute sanction', 'Merci de nous soutenir chaque jour ❤️'],
  links: { reglement: '', discord: '', boutique: '' },
  team: [{ name: 'Fondateur', role: 'Fondateur · Développeur' }, { name: 'Pseudo', role: 'Responsable staff' }],
  updates: [{ date: '', title: 'Nouveautés', items: ['Ajoute ici ce qui a changé sur le serveur'] }],
  stages: ['Initialisation…', 'Chargement de la carte…', 'Démarrage…', 'Connexion à la session…'],
  music: { enabled: true, url: '', volume: 10, autoplay: true }, showTeam: true, showUpdates: true,
};
PAGES.loading = async function () {
  const s = curServer(); if (!s) return needServer();
  const [d, th, dr] = await Promise.all([api('GET', `/api/servers/${s.id}/docs/loading`), api('GET', `/api/servers/${s.id}/docs/theme`), api('GET', `/api/servers/${s.id}/drive`)]);
  const v = JSON.parse(JSON.stringify({ ...LOADING_DEFAULT, ...(d.value || {}) })); v.links = { ...LOADING_DEFAULT.links, ...(v.links || {}) }; v.music = { ...LOADING_DEFAULT.music, ...(v.music || {}) };
  const theme = th.value || {}; if (!v.links.discord && theme.ServerDiscord) v.links.discord = 'https://' + String(theme.ServerDiscord).replace(/^https?:\/\//, '');
  while (v.stages.length < 4) v.stages.push(LOADING_DEFAULT.stages[v.stages.length]);
  const audios = (dr.files || []).filter(f => String(f.mime || '').startsWith('audio/'));
  const accent = theme.AccentColor || '#fdc27d';
  const prev = el('div', { class: 'ldprev' });
  const tips = el('textarea', { rows: 5, value: v.tips.join('\n'), placeholder: 'Un message par ligne (12 max)' }), tipsHint = el('span', { class: 'muted' });
  const mEn = el('input', { type: 'checkbox', checked: v.music.enabled, style: 'width:auto' }), mAuto = el('input', { type: 'checkbox', checked: v.music.autoplay, style: 'width:auto' });
  const mUrl = el('input', { value: v.music.url || '', placeholder: 'https://… (vide = musique d’origine du serveur)' }), mVol = el('input', { type: 'range', min: 0, max: 100, value: v.music.volume, style: 'padding:0' }), mVolT = el('b', {}, v.music.volume + ' %');
  const mPick = el('select', { onchange: e => { if (e.target.value) { mUrl.value = e.target.value; draw(); } e.target.value = ''; } }, [el('option', { value: '' }, audios.length ? '— Choisir une musique de mon Drive —' : '— Aucune musique dans ton Drive (envoie-en une dans Identité & thème → Drive) —'), ...audios.map(a => el('option', { value: a.url }, a.name))]);
  const player = el('audio', { controls: true, preload: 'none', style: 'width:100%;margin-top:8px', hidden: !v.music.url });
  const links = {}; for (const k of ['reglement', 'discord', 'boutique']) links[k] = el('input', { value: v.links[k] || '', placeholder: 'https://… (vide = bouton masqué)' });
  const stages = v.stages.slice(0, 4).map(t => el('input', { value: t, maxlength: 40 }));
  const showTeam = el('input', { type: 'checkbox', checked: v.showTeam, style: 'width:auto' }), showUp = el('input', { type: 'checkbox', checked: v.showUpdates, style: 'width:auto' });
  let team = v.team.map(x => ({ ...x })), ups = v.updates.map(x => ({ ...x, items: (x.items || []).slice() }));
  const teamBox = el('div'), upBox = el('div');
  const drawTeam = () => teamBox.replaceChildren(...team.map((m, i) => el('div', { class: 'row', style: 'margin-bottom:6px' }, el('input', { value: m.name, placeholder: 'Pseudo', style: 'max-width:200px', oninput: e => { m.name = e.target.value; draw(); } }), el('input', { value: m.role || '', placeholder: 'Rôle', class: 'grow', oninput: e => { m.role = e.target.value; draw(); } }), el('button', { class: 'btn s d', onclick: () => { team.splice(i, 1); drawTeam(); draw(); } }, el('span', {}, '×')))), el('button', { class: 'btn s', onclick: () => { if (team.length < 12) { team.push({ name: '', role: '' }); drawTeam(); } } }, el('span', {}, '+ Ajouter un membre')));
  const drawUps = () => upBox.replaceChildren(...ups.map((u, i) => el('div', { class: 'card', style: 'margin:0 0 8px' }, el('div', { class: 'row' }, el('input', { value: u.date || '', placeholder: 'Date', style: 'max-width:120px', oninput: e => { u.date = e.target.value; draw(); } }), el('input', { value: u.title, placeholder: 'Titre', class: 'grow', oninput: e => { u.title = e.target.value; draw(); } }), el('button', { class: 'btn s d', onclick: () => { ups.splice(i, 1); drawUps(); draw(); } }, el('span', {}, '×'))), el('textarea', { rows: 3, value: (u.items || []).join('\n'), placeholder: 'Un changement par ligne (6 max)', style: 'margin-top:6px', oninput: e => { u.items = e.target.value.split('\n'); draw(); } }))), el('button', { class: 'btn s', onclick: () => { if (ups.length < 8) { ups.unshift({ date: '', title: '', items: [] }); drawUps(); } } }, el('span', {}, '+ Ajouter une mise à jour')));
  const collect = () => ({
    tips: tips.value.split('\n').map(x => x.trim()).filter(Boolean).slice(0, 12), links: Object.fromEntries(Object.entries(links).map(([k, i]) => [k, i.value.trim()])),
    team: team.filter(m => m.name.trim()).map(m => ({ name: m.name.trim(), role: (m.role || '').trim() })), updates: ups.filter(u => u.title.trim()).map(u => ({ date: (u.date || '').trim(), title: u.title.trim(), items: (u.items || []).map(x => x.trim()).filter(Boolean).slice(0, 6) })),
    stages: stages.map(i => i.value.trim()), music: { enabled: mEn.checked, url: mUrl.value.trim(), volume: +mVol.value, autoplay: mAuto.checked }, showTeam: showTeam.checked, showUpdates: showUp.checked });
  function draw() {
    const c = collect(); tipsHint.textContent = `${c.tips.length} / 12 message(s)`; mVolT.textContent = mVol.value + ' %'; player.hidden = !c.music.url; if (c.music.url && player.getAttribute('src') !== c.music.url) player.setAttribute('src', c.music.url);
    const btn = k => c.links[k] ? `<span class="ldb">${{ reglement: 'Règlement', discord: 'Discord', boutique: 'Boutique' }[k]}</span>` : '';
    const esc = x => String(x).replace(/[&<>"]/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[ch]));
    prev.style.setProperty('--pa', accent);
    prev.innerHTML = `<div class="ldtop"><span class="ldb">♪ ${c.music.enabled ? c.music.volume + ' %' : 'coupée'}</span><span>${['reglement', 'discord', 'boutique'].map(btn).join('')}</span></div>
      <div class="ldmid"><div class="ldname">${esc(theme.ServerShortName || 'AERO')}</div>${(c.showTeam || c.showUpdates) ? `<div class="ldinfo"><b>${c.showTeam ? 'Équipe' : 'Mises à jour'}</b>${(c.showTeam ? c.team.slice(0, 3).map(m => esc(m.name) + ' · ' + esc(m.role)) : c.updates.slice(0, 2).map(u => esc(u.title))).map(x => `<small>${x}</small>`).join('')}</div>` : ''}</div>
      <div class="ldbar"><span>${esc(c.stages[1] || '')}</span><b>62 %</b></div><div class="ldtrack"><i style="width:62%"></i></div><div class="ldtick">${esc(c.tips[0] || '—')}</div>`;
  }
  [tips, mEn, mAuto, mUrl, mVol, showTeam, showUp, ...Object.values(links), ...stages].forEach(i => { i.addEventListener('input', draw); i.addEventListener('change', draw); });
  drawTeam(); drawUps(); draw();
  const save = async (core) => {
    const r = await api('PUT', `/api/servers/${s.id}/docs/loading`, { value: collect() }); if (!r.ok) return toast(r.error, 'bad');
    await sendCmd('apply_loading', { core }, core ? 'Écran de chargement enregistré : pickax_core redémarre pour le servir aux nouveaux joueurs' : 'Écran de chargement enregistré : visible après le prochain redémarrage de pickax_core');
  };
  const sec = (title, hint, ...body) => el('div', { class: 'card' }, el('h2', {}, title), hint ? el('p', { class: 'muted', style: 'margin:-6px 0 10px' }, hint) : null, ...body);
  const sw = (cb, text) => el('label', { style: 'display:flex;gap:8px;align-items:center;text-transform:none;letter-spacing:0;margin:8px 0' }, cb, text);
  return el('div', {}, head('Écran de chargement',
    el('button', { class: 'btn', title: 'Redémarre pickax_core (coupe les menus ouverts quelques secondes) pour que les joueurs qui se connectent voient le changement tout de suite', onclick: () => confirmBox('Appliquer maintenant', 'pickax_core va redémarrer : les menus ouverts seront coupés quelques secondes. Les joueurs qui se connecteront ensuite verront le nouvel écran de chargement.', () => save(true)) }, el('span', {}, 'Enregistrer et appliquer maintenant')),
    el('button', { class: 'btn p', onclick: () => save(false) }, el('span', {}, 'Enregistrer'))),
    el('p', { class: 'muted', style: 'margin-bottom:12px' }, 'Tout ce que voit un joueur pendant qu’il se connecte. L’image de fond, le logo et la couleur se règlent dans ', el('a', { href: '#/theme' }, 'Identité & thème'), '. Les changements sont servis aux joueurs après un redémarrage de pickax_core (bouton « appliquer maintenant »).'),
    el('div', { class: 'grid g2', style: 'align-items:start' },
      el('div', {},
        sec('Messages défilants', 'Le bandeau qui défile en bas de l’écran.', tips, tipsHint),
        sec('Musique', 'Jouée pendant le chargement ; le joueur peut la couper (barre d’espace) et régler le volume.', sw(mEn, 'Musique activée'), el('label', {}, 'Adresse de la musique'), mUrl, mPick, player, el('label', {}, 'Volume au démarrage ', mVolT), mVol, sw(mAuto, 'Lancer la musique automatiquement')),
        sec('Boutons de liens', 'Un bouton sans lien n’apparaît pas.', el('label', {}, 'Règlement'), links.reglement, el('label', {}, 'Discord'), links.discord, el('label', {}, 'Boutique'), links.boutique),
        sec('Textes de progression', 'Affichés sous la barre selon l’avancement du chargement.', ...['Début', 'Chargement de la carte', 'Démarrage', 'Connexion'].flatMap((l, i) => [el('label', {}, l), stages[i]]))),
      el('div', {},
        el('div', { class: 'card' }, el('h2', {}, 'Aperçu'), prev, el('p', { class: 'muted', style: 'margin-top:8px;font-size:12px' }, 'Aperçu simplifié : la mise en page réelle est celle de ton écran de chargement habituel.')),
        sec('Équipe', 'Présentée dans le panneau de gauche de l’écran.', sw(showTeam, 'Afficher l’équipe'), teamBox),
        sec('Mises à jour', 'Les dernières nouveautés du serveur (la plus récente en premier).', sw(showUp, 'Afficher les mises à jour'), upBox))));
};

// ═══════════════ RÉGLAGES DU SERVEUR ═══════════════
const SET_ORDER = ['Serveur', 'Monde & PNJ', 'Météo & heure', 'Joueurs & combat', 'Nouveaux joueurs', 'Interface', 'Voix', 'Économie', 'Carnet', 'Gangs', 'Drogues & labos', 'Discord', 'Performance'];
const SET_INFO = {
  'Serveur': ['Maintenance, annonces automatiques et redémarrages programmés.', 'M3 12h18M3 6h18M3 18h18'],
  'Monde & PNJ': ['Population, circulation, police et transports automatiques de GTA.', 'M12 21s-7-6.200-7-11a7 7 0 0 1 14 0c0 4.800-7 11-7 11z'],
  'Météo & heure': ['Météo fixe ou dynamique, heure figée, panne de courant.', 'M12 3v2M12 19v2M5 12H3M21 12h-2M7 7L5.500 5.500M18.500 18.500L17 17M17 7l1.500-1.500M5.500 18.500L7 17M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8z'],
  'Joueurs & combat': ['Dégâts, tir ami, santé, endurance.', 'M14 3l7 7-4 4-7-7zM3 21l6-6'],
  'Nouveaux joueurs': ['Message de bienvenue et argent bonus à la création du personnage.', 'M12 5v14M5 12h14'],
  'Interface': ['Notifications, boussole, HUD, cartes d’information, viseur.', 'M4 5h16v14H4zM4 9h16'],
  'Voix': ['Distances de la voix (chuchoter, normal, crier).', 'M12 3v10M8 7v2M16 7v2M5 11a7 7 0 0 0 14 0'],
  'Économie': ['Gains et prix de l’ensemble du serveur.', 'M12 3v18M16 7H10a3 3 0 0 0 0 6h4a3 3 0 0 1 0 6H8'],
  'Carnet': ['Série de connexion, objectifs du jour et défi de la ville.', 'M6 3h12v18H6zM9 8h6M9 12h6'],
  'Gangs': ['Territoires, racket, affrontements, guerres de zone, zones de tribut, missions colis et guerres entre gangs.', 'M4 22V4M4 4h13l-2 4 2 4H4'],
  'Drogues & labos': ['Laboratoire interactif (qualité, rendement, caméra 3D), intoxication, vente de drogue aux PNJ.', 'M9 3h6M10 3v6l-5 9a2 2 0 0 0 2 3h10a2 2 0 0 0 2-3l-5-9V3'],
  'Discord': ['Statut affiché sur le profil Discord des joueurs.', 'M8 8c2.600-1 5.400-1 8 0M7 17c3.300 1.300 6.700 1.300 10 0'],
  'Performance': ['Mode économie de ressources pour les PC modestes.', 'M13 2L3 14h8l-1 8 10-12h-8z'],
};
PAGES.settings = async function () {
  const s = curServer(); if (!s) return needServer(); const r = await api('GET', `/api/servers/${s.id}/settings`);
  if (!r.ok) return el('div', { class: 'card' }, r.error);
  if (!r.ready) return el('div', {}, head('Réglages du serveur'), el('div', { class: 'card empty' }, el('h2', {}, 'Réglages non disponibles'), el('p', {}, 'Ton serveur n’a pas encore envoyé la liste des réglages. Vérifie que la ressource ', el('b', {}, 'pickax_settings'), ' est démarrée (', el('span', { class: 'mono' }, 'ensure pickax_settings'), ' ou le dossier [dev]) puis redémarre ', el('b', {}, 'pickax_panel'), '.')));
  const schema = r.schema, ov = r.overrides || {}, by = Object.fromEntries(schema.map(d => [d.key, d]));
  const cats = SET_ORDER.filter(g => schema.some(d => d.group === g)).concat([...new Set(schema.map(d => d.group))].filter(g => !SET_ORDER.includes(g)));
  const saved = d => (d.key in ov ? ov[d.key] : d.default), norm = x => JSON.stringify(x);
  const cur = Object.fromEntries(schema.map(d => [d.key, JSON.parse(JSON.stringify(saved(d)))]));
  let active = sessionStorage.getItem('aero_setcat'); if (!cats.includes(active)) active = cats[0]; let query = '';
  const dirty = () => schema.filter(d => norm(cur[d.key]) !== norm(saved(d)));
  const changed = d => norm(cur[d.key]) !== norm(d.default);
  const main = el('div'), rail = el('div', { class: 'setrail' }), bar = el('div', { class: 'setbar', hidden: true });
  const ctl = {};   // key -> { set(v), badge }
  const row = d => {
    const v = cur[d.key]; let c; const set = x => { cur[d.key] = x; refresh(); };
    const badge = el('span', { class: 'pill acc', style: 'margin-left:8px' }, 'modifié'), reset = el('button', { class: 'btn s', title: 'Revenir à la valeur par défaut', onclick: () => { cur[d.key] = JSON.parse(JSON.stringify(d.default)); paint(d, c); refresh(); } }, el('span', {}, 'Par défaut'));
    const hasRange = d.type === 'number' && d.min != null && d.max != null && (d.max - d.min) / (d.step || 1) <= 200;
    if (d.type === 'bool') { c = el('input', { type: 'checkbox', checked: !!v, class: 'sw', onchange: e => set(e.target.checked) }); }
    else if (d.type === 'number') { c = el('input', { type: 'number', min: d.min, max: d.max, step: d.step || 1, value: v, oninput: e => { set(Number(e.target.value)); if (c._r) c._r.value = e.target.value; } }); if (hasRange) c._r = el('input', { type: 'range', min: d.min, max: d.max, step: d.step || 1, value: v, class: 'grow', oninput: e => { c.value = e.target.value; set(Number(e.target.value)); } }); }
    else if (d.type === 'select') c = el('select', { onchange: e => set(e.target.value) }, (d.options || []).map(o => el('option', { value: o[0], selected: o[0] === v }, o[1])));
    else if (d.type === 'list') c = el('textarea', { rows: 3, value: (v || []).join('\n'), oninput: e => set(e.target.value.split('\n').map(x => x.trim()).filter(Boolean)) });
    else c = el('input', { value: v == null ? '' : v, oninput: e => set(e.target.value) });
    const body = d.type === 'bool' ? el('div', { class: 'row' }, c, el('span', { class: 'muted' }, 'Activé')) : hasRange ? el('div', { class: 'row' }, c._r, c) : c;
    const w = el('div', { class: 'setrow', 'data-k': d.key, 'data-t': (d.label + ' ' + d.key + ' ' + (d.hint || '') + ' ' + d.group).toLowerCase() }, el('div', { class: 'row' }, el('b', {}, d.label), badge, el('div', { class: 'grow' }), reset), d.hint ? el('div', { class: 'muted', style: 'font-size:12px;margin:2px 0 6px' }, d.hint) : null, body);
    ctl[d.key] = { c, badge, reset, w }; return w;
  };
  const paint = (d, c) => { const v = cur[d.key]; if (d.type === 'bool') c.checked = !!v; else if (d.type === 'list') c.value = (v || []).join('\n'); else { c.value = v == null ? '' : v; if (c._r) c._r.value = v; } };
  function refresh() {
    for (const d of schema) { const k = ctl[d.key]; if (!k) continue; k.badge.style.display = changed(d) ? '' : 'none'; k.reset.style.visibility = changed(d) ? 'visible' : 'hidden'; k.w.classList.toggle('unsaved', norm(cur[d.key]) !== norm(saved(d))); }
    const n = dirty().length; bar.hidden = !n; bar.querySelector('b').textContent = `${n} modification${n > 1 ? 's' : ''} non enregistrée${n > 1 ? 's' : ''}`;
    for (const g of cats) { const b = rail.querySelector(`[data-g="${CSS.escape(g)}"] .cnt`); if (b) { const m = schema.filter(d => d.group === g && changed(d)).length; b.textContent = m || ''; b.style.display = m ? '' : 'none'; } }
  }
  const drawMain = () => {
    main.replaceChildren(); for (const k in ctl) delete ctl[k];
    const t = query.trim().toLowerCase();
    const groups = t ? cats : [active];
    let any = false;
    for (const g of groups) {
      const list = schema.filter(d => d.group === g && (!t || (d.label + ' ' + d.key + ' ' + (d.hint || '')).toLowerCase().includes(t))); if (!list.length) continue; any = true;
      const info = SET_INFO[g] || [''];
      const head2 = el('div', { class: 'sethead' }, el('h2', {}, g), el('div', { class: 'row' }, el('span', { class: 'muted' }, info[0]), el('div', { class: 'grow' }), t ? null : el('button', { class: 'btn s', onclick: () => confirmBox('Réinitialiser « ' + g + ' »', 'Tous les réglages de cette catégorie reviennent à leur valeur par défaut (après avoir cliqué sur Enregistrer).', () => { schema.filter(d => d.group === g).forEach(d => { cur[d.key] = JSON.parse(JSON.stringify(d.default)); }); drawMain(); }) }, el('span', {}, 'Réinitialiser la catégorie'))));
      main.append(head2);
      const secs = [...new Set(list.map(d => d.section || 'Général'))];
      for (const sc of secs) main.append(el('div', { class: 'card' }, secs.length > 1 || t ? el('h3', { class: 'setsec' }, sc) : null, ...list.filter(d => (d.section || 'Général') === sc).map(row)));
    }
    if (!any) main.append(el('div', { class: 'card empty' }, 'Aucun réglage ne correspond à « ' + query + ' »'));
    refresh();
  };
  const drawRail = () => rail.replaceChildren(...cats.map(g => el('a', { class: 'setcat' + (g === active && !query ? ' on' : ''), href: '#', 'data-g': g, onclick: e => { e.preventDefault(); active = g; query = ''; search.value = ''; sessionStorage.setItem('aero_setcat', g); drawRail(); drawMain(); } }, svg((SET_INFO[g] || ['', 'M4 6h16M4 12h16M4 18h16'])[1]), el('span', {}, g), el('i', { class: 'cnt pill acc' }))));
  const search = el('input', { placeholder: 'Rechercher un réglage…', style: 'max-width:300px', oninput: e => { query = e.target.value; drawRail(); drawMain(); } });
  const save = async () => { const x = await api('PUT', `/api/servers/${s.id}/settings`, { values: cur }); toast(x.ok ? `Réglages enregistrés (${x.count} modifié${x.count > 1 ? 's' : ''}) : appliqués sur le serveur dans quelques secondes` : x.error, x.ok ? 'ok' : 'bad'); if (x.ok) render(); };
  const exportJson = () => { const out = {}; schema.forEach(d => { if (norm(cur[d.key]) !== norm(d.default)) out[d.key] = cur[d.key]; }); const a = el('a', { href: URL.createObjectURL(new Blob([JSON.stringify(out, null, 2)], { type: 'application/json' })), download: 'reglages-' + s.server_name.replace(/\W+/g, '-') + '.json' }); document.body.append(a); a.click(); a.remove(); };
  const file = el('input', { type: 'file', accept: 'application/json', hidden: true, onchange: async e => { const f = e.target.files[0]; if (!f) return; try { const j = JSON.parse(await f.text()); let n = 0; for (const [k, v] of Object.entries(j)) if (by[k]) { cur[k] = v; n++; } drawMain(); toast(n + ' réglage(s) importé(s) : clique sur Enregistrer pour les appliquer', n ? 'ok' : 'bad'); } catch (err) { toast('Fichier invalide', 'bad'); } e.target.value = ''; } });
  bar.append(el('b', {}, ''), el('div', { class: 'grow' }), el('button', { class: 'btn', onclick: () => { schema.forEach(d => { cur[d.key] = JSON.parse(JSON.stringify(saved(d))); }); drawMain(); } }, el('span', {}, 'Annuler')), el('button', { class: 'btn p', onclick: save }, el('span', {}, 'Enregistrer')));
  drawRail(); drawMain();
  return el('div', {}, head('Réglages du serveur', search, el('button', { class: 'btn s', onclick: exportJson, title: 'Télécharge tes réglages modifiés (sauvegarde ou copie vers un autre serveur)' }, el('span', {}, 'Exporter')), el('button', { class: 'btn s', onclick: () => file.click() }, el('span', {}, 'Importer')), file),
    el('p', { class: 'muted', style: 'margin-bottom:14px' }, 'Un réglage ne change rien tant que tu ne l’as pas modifié : les valeurs d’origine de ta base restent en vigueur. Les changements sont appliqués en direct sur le serveur, sans redémarrage.'),
    modeCard(), profileCard(), el('div', { class: 'setlayout' }, rail, main), bar);
  // ── Profils de serveur : un clic règle des dizaines d'options ──
  function profileCard() {
    const box = el('div', { class: 'card' }, el('h2', {}, 'Profils de serveur'), el('p', { class: 'muted' }, 'Chargement…'));
    api('GET', `/api/servers/${s.id}/settings/profiles`).then(p => {
      if (!p.ok || !p.ready) return box.remove();
      box.replaceChildren(el('h2', {}, 'Profils de serveur'), el('p', { class: 'muted', style: 'margin:-6px 0 12px' }, 'Applique un ensemble de réglages d’un coup (tes autres réglages sont conservés). Tout reste modifiable ensuite, et l’historique permet d’annuler.'),
        el('div', { class: 'opts' }, p.profiles.map(x => el('button', { class: 'opt', onclick: () => confirmBox(`Appliquer « ${x.name} » ?`, `${x.count} réglages vont changer. Tu pourras annuler depuis « Historique des réglages ».`, async () => { const r = await api('POST', `/api/servers/${s.id}/settings/profile`, { name: x.name, values: x.values }); toast(r.ok ? `Profil « ${x.name} » appliqué (${r.changed} changement${r.changed > 1 ? 's' : ''})` : r.error, r.ok ? 'ok' : 'bad'); render(); }) }, el('div', { class: 'opt-t' }, el('b', {}, `${x.icon}  ${x.name}`)), el('small', { class: 'muted' }, x.desc)))));
    });
    return box;
  }
  // ── Mode de jeu : facile / difficile en un clic ──
  function modeCard() {
    if (!by.game_mode) return null;
    const easy = schema.filter(d => d.easy !== undefined && norm(d.easy) !== norm(d.default));
    const show = (d, v) => d.type === 'bool' ? (v ? 'Activé' : 'Désactivé') : String(v);
    const now = cur.game_mode === 'facile' ? 'facile' : 'difficile';
    const choice = (v, title, desc) => el('button', { class: 'opt' + (now === v ? ' on' : ''), onclick: async () => { if (now === v) return; cur.game_mode = v; await save(); render(); } },
      el('div', { class: 'opt-t' }, el('b', {}, title), now === v ? el('span', { class: 'pill acc' }, 'Actuel') : null), el('small', { class: 'muted' }, desc));
    return el('div', { class: 'card' }, el('h2', {}, 'Mode de jeu'),
      el('p', { class: 'muted', style: 'margin:-6px 0 12px' }, 'Un seul choix pour régler la difficulté de toute la base. Ensuite, tu peux ajuster n’importe quel système dans les catégories ci-dessous : un réglage modifié passe toujours avant le mode.'),
      el('div', { class: 'opts' },
        choice('difficile', 'Difficile · systèmes complets', 'Table de traitement en plusieurs étapes avec accidents et niveaux de laborantin, tablettes obligatoires, intoxication, réputation et quartiers pour la vente de rue, raids de QG, guerres de zone.'),
        choice('facile', 'Facile · systèmes simplifiés', 'Fabrication au labo avec une simple barre de progression, ni accident ni intoxication, aucune tablette exigée, ventes de rue plus faciles, captures de territoires rapides, ni raids ni guerres de zone.')),
      easy.length ? el('details', { style: 'margin-top:12px' }, el('summary', { class: 'muted', style: 'cursor:pointer' }, `Voir ce que change le mode facile (${easy.length} réglages)`),
        el('div', { style: 'margin-top:8px;display:grid;gap:4px' }, easy.map(d => el('div', { class: 'row', style: 'justify-content:space-between;gap:12px;font-size:13px' }, el('span', {}, `${d.group} · ${d.label}`), el('span', { class: 'muted' }, `${show(d, d.default)} → `, el('b', {}, show(d, d.easy))))))) : null);
  }
};

// ═══════════════ PERSONNALISATION DU PANEL (design, thème, couleur principale — propre à chaque compte) ═══════════════
PAGES['custom'] = function () {
  const PRESETS = [['#fdc27d', 'Jaune AERO'], ['#ff9f43', 'Orange'], ['#f87171', 'Rouge'], ['#f472b6', 'Rose'], ['#c084fc', 'Violet'], ['#818cf8', 'Indigo'], ['#60a5fa', 'Bleu'], ['#22d3ee', 'Cyan'], ['#4ade80', 'Vert'], ['#e5e7eb', 'Blanc']];
  const DEF = '#fdc27d';
  const root = el('div', {});
  const mock = kind => kind === 'v2'
    ? el('div', { class: 'mk mk2' }, el('div', { class: 'mk-side' }, el('i', {}), el('i', { class: 'on' }), el('i', {}), el('i', {})), el('div', { class: 'mk-frame' }, el('b', {}), el('div', { class: 'mk-cards' }, el('s', {}), el('s', {}), el('s', {})), el('em', {})))
    : el('div', { class: 'mk mk1' }, el('div', { class: 'mk-side' }, el('i', {}), el('i', { class: 'on' }), el('i', {}), el('i', {})), el('div', { class: 'mk-frame' }, el('b', {}), el('div', { class: 'mk-cards' }, el('s', {}), el('s', {}), el('s', {})), el('em', {})));
  const opt = (sel, title, desc, onclick, preview) => el('button', { class: 'opt' + (sel ? ' on' : ''), onclick }, preview, el('div', { class: 'opt-t' }, el('b', {}, title), sel ? el('span', { class: 'pill acc' }, 'Actuel') : null), el('small', { class: 'muted' }, desc));
  const themeMock = t => el('div', { class: 'mk mkt ' + t }, el('div', { class: 'mk-side' }, el('i', {}), el('i', { class: 'on' }), el('i', {})), el('div', { class: 'mk-frame' }, el('b', {}), el('s', {}), el('s', {})));
  const build = () => {
    const pr = state.user.prefs || { design: 'v2', theme: 'sombre', accent: null };
    const accent = (pr.accent || DEF).toLowerCase();
    const sw = PRESETS.map(([hex, name]) => el('button', { class: 'swc' + (accent === hex ? ' on' : ''), title: name, style: 'background:' + hex, onclick: async () => { await savePrefs({ accent: hex === DEF ? null : hex }); toast('Couleur « ' + name + ' » appliquée'); redraw(); } }));
    const picker = el('input', { type: 'color', value: accent, style: 'width:54px;height:42px;padding:3px', oninput: e => applyAccent(e.target.value), onchange: async e => { await savePrefs({ accent: e.target.value }); toast('Couleur enregistrée'); redraw(); } });
    const hex = el('input', { type: 'text', value: accent, maxlength: 7, style: 'max-width:130px;font-family:ui-monospace,Menlo,monospace', onkeydown: async e => { if (e.key !== 'Enter') return; const v = e.target.value.trim(); if (!/^#[0-9a-fA-F]{6}$/.test(v)) return toast('Code couleur invalide (ex. #fdc27d)', 'bad'); await savePrefs({ accent: v.toLowerCase() }); toast('Couleur enregistrée'); redraw(); } });
    return [head('Personnalisation du panel'),
      el('p', { class: 'muted', style: 'margin:-6px 0 18px' }, 'Ces choix ne concernent que ton compte : ils s’appliquent tout de suite et te suivent sur tous tes appareils.'),
      el('div', { class: 'card' }, el('h2', {}, 'Design du panel'), el('p', { class: 'muted', style: 'margin-bottom:12px' }, 'Garde le nouveau design ou reviens à l’ancien style.'),
        el('div', { class: 'opts' },
          opt(pr.design !== 'v1', 'Nouveau design', 'Cadre arrondi, boutons blancs, police Geist.', async () => { await savePrefs({ design: 'v2' }); toast('Nouveau design activé'); redraw(); }, mock('v2')),
          opt(pr.design === 'v1', 'Ancien design', 'Style incliné et italique d’origine.', async () => { await savePrefs({ design: 'v1' }); toast('Ancien design activé'); redraw(); }, mock('v1')))),
      el('div', { class: 'card' }, el('h2', {}, 'Thème'), el('div', { class: 'opts' },
        opt(pr.theme !== 'clair', 'Sombre', 'Fond sombre, reposant pour les yeux.', async () => { await savePrefs({ theme: 'sombre' }); toast('Thème sombre'); redraw(); }, themeMock('dark')),
        opt(pr.theme === 'clair', 'Clair', 'Contenu blanc, menu sombre.', async () => { await savePrefs({ theme: 'clair' }); toast('Thème clair'); redraw(); }, themeMock('light')))),
      el('div', { class: 'card' }, el('h2', {}, 'Couleur principale'), el('p', { class: 'muted', style: 'margin-bottom:12px' }, 'Change le jaune du panel : menu actif, pastilles, interrupteurs, graphiques, liens.'),
        el('div', { class: 'swrow' }, sw),
        el('div', { class: 'row', style: 'margin-top:14px' }, el('span', { class: 'muted' }, 'Couleur libre'), picker, hex, el('button', { class: 'btn', onclick: async () => { await savePrefs({ accent: null }); toast('Jaune AERO rétabli'); redraw(); } }, el('span', {}, 'Rétablir le jaune AERO'))),
        el('div', { class: 'cprev' }, el('span', { class: 'muted' }, 'Aperçu'), el('button', { class: 'btn p' }, el('span', {}, 'Bouton principal')), el('span', { class: 'pill acc' }, 'Pastille'), el('a', { href: '#' , onclick: e => e.preventDefault() }, 'Lien'), el('div', { class: 'bar-row', style: 'width:160px;margin:0' }, el('div', { class: 'bt' }, el('i', { style: 'display:block;height:100%;width:62%;background:var(--ac)' })))))];
  };
  const redraw = () => root.replaceChildren(...build().filter(Boolean));
  redraw();
  return root;
};
