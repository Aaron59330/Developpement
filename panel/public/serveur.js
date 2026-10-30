'use strict';
// ───────── Gestion Serveur : tout ce qui concerne l'EXTÉRIEUR du serveur (liste FiveM, connexion) ─────────
const FV_COLORS = { 0: '#fff', 1: '#f55', 2: '#5f5', 3: '#ff5', 4: '#5af', 5: '#5df', 6: '#c7f', 7: '#fff', 8: '#f66', 9: '#aaa' };
function fivemText(str) {                       // convertit les codes couleur FiveM (^1 …) en texte coloré
  const out = []; let color = '#fff';
  String(str || '').split(/(\^\d)/).forEach(part => { const m = part.match(/^\^(\d)$/); if (m) color = FV_COLORS[m[1]]; else if (part) out.push(el('span', { style: 'color:' + color }, part)); });
  return out;
}
// Bloc « champ + explication » commun à toutes les pages de configuration
function helpField(label, help, control, example) {
  return el('div', { class: 'hf' }, el('div', { class: 'hf-l' }, label), control, help ? el('div', { class: 'hf-h' }, help) : null, example ? el('div', { class: 'hf-e' }, 'Exemple : ', el('code', {}, example)) : null);
}
PAGES.server = async function () {
  const s = curServer(); if (!s) return needServer();
  const sv = (await api('GET', `/api/servers/${s.id}/docs/server`)).value || {};
  const inp = (v, ph) => el('input', { value: v == null ? '' : v, placeholder: ph || '' });
  const f = { projectName: inp(sv.projectName, '^4MonServeur RP ^7| ^4Free-Access'), hostname: inp(sv.hostname, 'souvent identique au nom'), projectDesc: inp(sv.projectDesc, 'Free access, RP sérieux, contenu unique…'), tags: inp(sv.tags, 'roleplay, rp, fr, esx, economy…'), discord: inp(sv.discord, 'discord.gg/monserveur'),
    maxClients: el('input', { type: 'number', min: 0, max: 2048, value: sv.maxClients || '', placeholder: 'ex. 48', style: 'max-width:160px' }) };
  const bd = imageField(sv.bannerDetail || '', 'Lien d’image ou fichier .png / .jpg'), bc = imageField(sv.bannerConnecting || '', 'Lien d’image ou fichier .png / .jpg');
  const pv = el('div', { class: 'fv-prev' });
  const draw = () => {
    pv.replaceChildren(
      el('div', { class: 'fv-card' }, el('div', { class: 'fv-ban', style: bd.input.value.trim() ? `background-image:url('${bd.input.value.trim()}')` : '' }, bd.input.value.trim() ? null : el('span', {}, 'Bannière de la liste')),
        el('div', { class: 'fv-body' }, el('div', { class: 'fv-name' }, fivemText(f.projectName.value || 'Nom du serveur')), el('div', { class: 'fv-desc' }, f.projectDesc.value || 'Description du serveur'), el('div', { class: 'fv-meta' }, el('span', {}, '👥 0 / ' + (f.maxClients.value || '—')), f.discord.value ? el('span', {}, '💬 ' + f.discord.value) : null),
          el('div', { class: 'fv-tags' }, (f.tags.value || '').split(',').map(x => x.trim()).filter(Boolean).slice(0, 8).map(t => el('i', {}, t))))),
      el('div', { class: 'fv-conn', style: bc.input.value.trim() ? `background-image:linear-gradient(rgba(0,0,0,.35),rgba(0,0,0,.35)),url('${bc.input.value.trim()}')` : '' }, el('span', {}, bc.input.value.trim() ? '' : 'Bannière de connexion')));
  };
  [...Object.values(f), bd.input, bc.input].forEach(i => i.addEventListener('input', draw)); draw();
  const save = async () => {
    const val = { ...Object.fromEntries(Object.entries(f).map(([k, i]) => [k, i.value.trim()])), bannerDetail: bd.input.value.trim(), bannerConnecting: bc.input.value.trim() };
    val.maxClients = val.maxClients === '' ? 0 : Number(val.maxClients);
    const r = await api('PUT', `/api/servers/${s.id}/docs/server`, { value: val });
    toast(r.ok ? 'Enregistré : appliqué sur le serveur dans quelques secondes (nombre de places : au prochain redémarrage)' : r.error, r.ok ? 'ok' : 'bad');
  };
  const card = (n, title, intro, ...body) => el('div', { class: 'card cfgcard' }, el('div', { class: 'cfg-t' }, el('span', { class: 'cfg-n' }, n), el('h2', {}, title)), el('p', { class: 'cfg-i' }, intro), ...body);
  return el('div', {}, head('Gestion Serveur', el('button', { class: 'btn p', onclick: save }, el('span', {}, 'Enregistrer'))),
    el('div', { class: 'pg-intro' }, el('b', {}, 'À quoi sert cette page ? '), 'Elle règle ce que voient les joueurs ', el('u', {}, 'avant'), ' d’entrer dans le jeu : la fiche de ton serveur dans la liste FiveM et l’écran de connexion. Tout ce qui se passe à l’intérieur du jeu (couleurs, logo, menus, scripts) se règle dans ', el('b', {}, 'Gestion Base'), '.'),
    el('div', { class: 'grid g2', style: 'align-items:start' },
      el('div', {},
        card('1', 'Nom et description', 'C’est la première chose qu’un joueur lit dans la liste FiveM. Soigne-la : elle donne envie (ou pas) de cliquer.',
          helpField('Nom du serveur dans la liste', 'Peut contenir des couleurs : ^1 rouge, ^2 vert, ^3 jaune, ^4 bleu, ^5 cyan, ^6 violet, ^7 blanc. Pas de guillemets.', f.projectName, '^4MonServeur RP ^7| ^4Free-Access'),
          helpField('Nom complet (hostname)', 'Le nom technique du serveur. Le plus simple : le même que ci-dessus.', f.hostname),
          helpField('Description courte', 'Une phrase qui résume ton serveur (type de RP, ambiance, points forts).', f.projectDesc, 'RP sérieux, contenu unique, 150 fps'),
          helpField('Étiquettes (tags)', 'Des mots-clés séparés par des virgules : ils aident les joueurs à te trouver quand ils cherchent « roleplay », « fr », « esx »…', f.tags, 'roleplay, rp, fr, esx, economy'),
          helpField('Lien Discord', 'Affiché dans la fiche du serveur. Sans « https:// ».', f.discord, 'discord.gg/monserveur')),
        card('2', 'Nombre de places (slots)', 'Combien de joueurs peuvent être connectés en même temps.',
          helpField('Places', 'Modifie la ligne sv_maxclients du server.cfg (sauvegarde automatique du fichier). FiveM ne la lit qu’au démarrage : il faut donc redémarrer le serveur. Au-delà de 48 places, il faut l’abonnement Element Club (Cfx.re).', f.maxClients, '48'))),
      el('div', {},
        card('3', 'Bannières', 'Deux images différentes : celle de la liste de serveurs, et celle de l’écran qui s’affiche quand on se connecte. Lien https:// ou fichier .png / .jpg.',
          helpField('Bannière de la liste (banner_detail)', 'Affichée en grand sur la fiche de ton serveur. Format conseillé : 1024 × 256.', bd.node), helpField('Bannière de connexion (banner_connecting)', 'Affichée pendant que le joueur se connecte. Format conseillé : 1024 × 256.', bc.node)),
        card('4', 'Logo du serveur (icône)', 'La petite image carrée à côté du nom dans la liste FiveM.',
          el('div', { class: 'hf-h' }, 'FiveM exige un fichier PNG de 96 × 96 pixels nommé ', el('code', {}, 'logo.png'), ', placé à la racine du serveur, avec la ligne ', el('code', {}, 'load_server_icon "logo.png"'), ' dans le server.cfg. Cette icône ne peut pas être changée à distance : remplace le fichier puis redémarre le serveur. (Le logo utilisé DANS le jeu se règle dans Gestion Base → Couleurs & logos.)')),
        el('div', { class: 'card cfgcard' }, el('div', { class: 'cfg-t' }, el('span', { class: 'cfg-n' }, '👁'), el('h2', {}, 'Aperçu')), el('p', { class: 'cfg-i' }, 'Voilà à peu près ce que verront les joueurs. Se met à jour pendant que tu tapes.'), pv))));
};

// Explications affichées sous les champs de la page « Couleurs & logos »
const THEME_HELP = {
  AccentColor: 'LA couleur de ton serveur. Tous les menus, boutons, notifications, l’inventaire, le créateur de personnage et l’écran de chargement l’utilisent. Change-la ici et elle change partout en jeu.',
  InventoryColor: 'Facultatif : une autre couleur uniquement pour l’inventaire. Laisse vide pour garder la couleur principale.',
  ServerName: 'Le nom complet de ton serveur, écrit dans le menu pause, l’écran d’identité et les messages.',
  ServerShortName: 'Une version courte (quelques lettres) pour les endroits étroits : HUD, écran de connexion, Discord.',
  ServerTagline: 'Une phrase d’accroche affichée sous le nom du serveur.',
  ServerDiscord: 'Le lien d’invitation de ton Discord, sans « https:// ». Utilisé pour le bouton Discord de l’écran de chargement.',
};
