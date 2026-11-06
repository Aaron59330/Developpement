Config = {}

-- ═════════════════════════════ GÉNÉRAL ═══════════════════════
Config.Command = 'gestion'                      -- commande qui ouvre le menu
Config.Key = 'F10'                              -- touche par défaut (modifiable par le joueur dans les paramètres FiveM) ; '' = aucune
Config.AdminGroups = { 'admin', 'superadmin', 'owner' }   -- groupes ESX autorisés
Config.StaffGroups = { 'mod', 'admin', 'superadmin', 'owner' }  -- comptés comme « staff en service »
Config.Ace = 'pickax.manage'                    -- ou droit ACE
Config.RoleLabels = { owner = 'Fondateur', superadmin = 'Super admin', admin = 'Administrateur', mod = 'Modérateur' }

Config.Server = {
    Name = 'Bluebay Roleplay',
    Subtitle = 'Base FiveM premium',
    Version = 'v0.1.0',
    License = 'Licence à vie',
    Logo = '',                                  -- lien https:// ou fichier dans pickax_theme/logo/ ; vide = logo du thème du serveur
}
Config.Accent = '#3566a6'                       -- couleur principale du menu (bleu du panel). '' = couleur du thème du serveur
Config.RefreshSec = 5                           -- actualisation des chiffres en direct
Config.JournalMax = 60

-- ═════════════════════════════ CATÉGORIES ════════════════════
-- tone : 'mint' (teinte menthe) · 'light' (clair) · 'white' (blanc) · 'vivid' (vert vif)
-- Chaque carte : title, desc, icon, action = { command = 'nom' } | { event = 'nom' } | { export = { 'ressource', 'fonction' } }
-- Sans action, la carte affiche « bientôt disponible » (à brancher au fur et à mesure).
Config.Categories = {
    { id = 'server', title = 'Serveur', tone = 'mint', wide = true, icon = 'server', sub = 'Journal, annonces, redémarrages, sauvegardes…', cards = {
        { title = 'Journal',       desc = 'Actions du staff et événements du serveur', icon = 'list' },
        { title = 'Annonces',      desc = 'Messages à l\'écran, programmation', icon = 'megaphone' },
        { title = 'Redémarrages',  desc = 'Planifier et annoncer les redémarrages', icon = 'refresh' },
        { title = 'Whitelist',     desc = 'Identifiants autorisés, message de refus', icon = 'shield' },
        { title = 'Sauvegardes',   desc = 'Sauvegarder et restaurer les configurations', icon = 'save', action = { command = 'aerotools' } },
        { title = 'Santé de la base', desc = 'Ressources, tables SQL, objets : score sur 100', icon = 'heart', action = { command = 'aerotools' } },
    } },
    { id = 'look', title = 'Apparence', tone = 'light', icon = 'brush', sub = 'Écran de chargement, HUD, compteur, lieu et heure', cards = {
        { title = 'Thème & logo',          desc = 'Couleur principale, nom, logo du serveur', icon = 'palette', action = { command = 'aerotools' } },
        { title = 'Écran de chargement',   desc = 'Messages, musique, liens, équipe', icon = 'image', action = { command = 'aerotools' } },
        { title = 'HUD',                   desc = 'Barres de vie, faim, soif, position', icon = 'gauge' },
        { title = 'Compteur',              desc = 'Compteur de vitesse et carburant', icon = 'gauge' },
        { title = 'Lieu et heure',         desc = 'Affichage de la rue et de l\'heure', icon = 'clock' },
    } },
    { id = 'players', title = 'Joueurs', tone = 'light', icon = 'users', sub = 'Arrivée joueur, scènes de connexion, gameplay, armes', cards = {
        { title = 'Arrivée joueur',        desc = 'Création de personnage, point d\'apparition', icon = 'user' },
        { title = 'Scènes de connexion',   desc = 'Décors et caméras à l\'entrée', icon = 'camera' },
        { title = 'Gameplay',              desc = 'Soif, faim, mort, réanimation', icon = 'heart' },
        { title = 'Gestion des armes',     desc = 'Roue d\'armes, port d\'armes, munitions', icon = 'target' },
    } },
    { id = 'economy', title = 'Économie', tone = 'light', icon = 'coins', sub = 'Économie globale, surveillance', cards = {
        { title = 'Économie globale',      desc = 'Événements, inflation, remises', icon = 'coins' },
        { title = 'Surveillance',          desc = 'Argent total, transactions suspectes', icon = 'eye' },
    } },
    { id = 'services', title = 'Services & activités', tone = 'white', icon = 'briefcase', sub = 'Légal, illégal, graffitis', cards = {
        { title = 'Légal',                 desc = 'Métiers, entreprises, boutiques', icon = 'briefcase' },
        { title = 'Illégal',               desc = 'Gangs, drogues, braquages', icon = 'skull' },
        { title = 'Graffitis',             desc = 'Zones et styles de graffitis', icon = 'brush' },
    } },
    { id = 'world', title = 'Monde', tone = 'vivid', icon = 'globe', wide = true, sub = 'Le ciel, le décor et la carte, et ceux qui la peuplent : météo, zones, événements, PNJ, portes, ascenseurs.', cards = {
        { title = 'Météo & temps',     desc = 'Synchronisation · Zones d\'ambiance · Programmation & règles', icon = 'cloud' },
        { title = 'Environnement',     desc = 'Panneaux Vinewood · Enseignes 3D', icon = 'mountain' },
        { title = 'Blips',             desc = 'Blips · Regroupements', icon = 'pin' },
        { title = 'Zones',             desc = 'Zones tracées sur la carte', icon = 'polygon' },
        { title = 'Activités',         desc = 'Football (terrains, cages, matchs) et cinéma', icon = 'ball' },
        { title = 'Vie nocturne',      desc = 'Platine DJ des bars, boomboxs et lieux', icon = 'music' },
        { title = 'Chasse saisonnière', desc = 'Citrouilles d\'Halloween et nounours de Noël', icon = 'ghost' },
        { title = 'PNJ & dialogues',   desc = 'PNJ posés · Dialogues', icon = 'chat' },
        { title = 'Population',        desc = 'Population ambiante · Zones de population', icon = 'users' },
        { title = 'Doorlock',          desc = 'Toutes les portes verrouillées du serveur', icon = 'lock' },
        { title = 'Ascenseurs',        desc = 'Créer des ascenseurs : poser leurs étages, les nommer', icon = 'building' },
        { title = 'Interacts',         desc = 'Pastilles d\'interaction : image, couleur, règles', icon = 'hand' },
    } },
}

-- ═════════════════════════════ BUILDERS ══════════════════════
-- group = 'builders' : rangées dans la section « Builders » de la vue d'ensemble. Chaque carte lance la commande du builder (cf. Config.Command de chaque ressource).
local function builder(id, title, icon, sub, command, extra)
    local cards = { { title = 'Ouvrir le ' .. title, desc = 'Lance l\'éditeur en jeu (/' .. command .. ')', icon = icon, action = { command = command } } }
    for _, e in ipairs(extra or {}) do cards[#cards + 1] = e end
    return { id = id, group = 'builders', title = title, tone = 'white', icon = icon, sub = sub, cards = cards }
end
local more = {
    builder('b_hub',     'Panel des builders', 'layers',   'Tous les builders au même endroit', 'builders'),
    builder('b_world',   'World Builder',      'globe',    'Monde : zones, PNJ, portes, ascenseurs, quêtes, PVP', 'worldbuilder', {
        { title = 'Doorlock', desc = 'Verrouiller / déverrouiller la porte proche', icon = 'lock', action = { command = 'wbdoor' } },
        { title = 'PVP',      desc = 'Zones et événements PVP', icon = 'target', action = { command = 'wbpvp' } },
    }),
    builder('b_job',     'Job Builder',        'briefcase', 'Métiers, grades, actions, véhicules, propriétés', 'jobbuilder', {
        { title = 'Menu métier', desc = 'Actions et facturation (F6)', icon = 'list', action = { command = 'jobmenu' } },
        { title = 'Décorer',     desc = 'Meubles et déco des propriétés', icon = 'building', action = { command = 'decorer' } },
    }),
    builder('b_gang',    'Gang Builder',       'users',    'Gangs, territoires, guerres, tablette', 'gangbuilder', {
        { title = 'Menu du gang', desc = 'Actions et infos du gang', icon = 'list', action = { command = 'gangmenu' } },
        { title = 'Tablette',     desc = 'Tablette de gang', icon = 'image', action = { command = 'gangtablet' } },
    }),
    builder('b_illegal', 'Illegal Builder',    'skull',    'Drogues, armes, marché noir, contrats', 'illegalbuilder', {
        { title = 'Marché noir', desc = 'Stocks et prix du marché noir', icon = 'coins', action = { command = 'marchenoir' } },
        { title = 'Contrats',    desc = 'Contrats de livraison', icon = 'list', action = { command = 'contrat' } },
    }),
    builder('b_shop',    'Shop Builder',       'cart',     'Boutiques, catalogues, concessions', 'shopbuilder'),
    builder('b_event',   'Event Builder',      'calendar', 'Événements du serveur', 'eventbuilder'),
    builder('b_mini',    'Mini-jeux Builder',  'game',     'Mini-jeux, défis, classements', 'minigames', {
        { title = 'Profil', desc = 'Niveau, défis, succès, classements', icon = 'user', action = { command = 'mgprofil' } },
    }),
}
for _, c in ipairs(more) do Config.Categories[#Config.Categories + 1] = c end
