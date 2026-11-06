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
-- action = { settings = { group = 'Météo & heure', section = 'Météo' } } : ouvre l'éditeur de réglages en direct (pickax_settings) sur ce groupe / cette section.
-- Sans action, la carte affiche « bientôt disponible » (à brancher au fur et à mesure).
Config.HiddenKeys = {}   -- clés de réglages à ne jamais montrer dans le menu
Config.Categories = {
    { id = 'server', title = 'Serveur', tone = 'mint', wide = true, icon = 'server', sub = 'Maintenance, annonces, redémarrages, mode de jeu, performance, Discord…', cards = {
        { title = 'Maintenance',        desc = 'Refuser les nouveaux joueurs, message, identifiants autorisés', icon = 'shield', action = { settings = { group = 'Serveur', section = 'Maintenance' } } },
        { title = 'Annonces',           desc = 'Messages automatiques à intervalle régulier', icon = 'megaphone', action = { settings = { group = 'Serveur', section = 'Annonces automatiques' } } },
        { title = 'Redémarrages',       desc = 'Heures de redémarrage programmées', icon = 'refresh', action = { settings = { group = 'Serveur', section = 'Redémarrages programmés' } } },
        { title = 'Mode de jeu',        desc = 'Facile ou difficile : règle des dizaines de systèmes d\'un coup', icon = 'gauge', action = { settings = { group = 'Serveur', section = 'Mode de jeu' } } },
        { title = 'Performance',        desc = 'Mode performance des interfaces', icon = 'gauge', action = { settings = { group = 'Performance' } } },
        { title = 'Alertes Discord',    desc = 'Alertes automatiques et résumé quotidien', icon = 'chat', action = { settings = { group = 'Discord' } } },
        { title = 'Sauvegardes',        desc = 'Sauvegarder et restaurer les configurations', icon = 'save', action = { command = 'aerotools' } },
        { title = 'Santé de la base',   desc = 'Ressources, tables SQL, objets : score sur 100', icon = 'heart', action = { command = 'aerotools' } },
    } },
    { id = 'look', title = 'Apparence', tone = 'light', icon = 'brush', sub = 'Thème, écran de chargement, HUD, boussole, notifications', cards = {
        { title = 'Thème & logo',          desc = 'Couleur principale, nom, logo du serveur', icon = 'palette', action = { command = 'aerotools' } },
        { title = 'Écran de chargement',   desc = 'Messages, musique, liens, équipe', icon = 'image', action = { command = 'aerotools' } },
        { title = 'HUD',                   desc = 'Faim, soif, vie, armure', icon = 'gauge', action = { settings = { group = 'Interface', section = 'HUD (faim, soif, vie)' } } },
        { title = 'Cartes en haut à droite', desc = 'Serveur, métier, argent', icon = 'list', action = { settings = { group = 'Interface', section = 'Cartes en haut à droite' } } },
        { title = 'Boussole',              desc = 'Format, nom de la rue, position', icon = 'pin', action = { settings = { group = 'Interface', section = 'Boussole' } } },
        { title = 'Notifications',         desc = 'Position des notifications', icon = 'megaphone', action = { settings = { group = 'Interface', section = 'Notifications' } } },
    } },
    { id = 'players', title = 'Joueurs', tone = 'light', icon = 'users', sub = 'Arrivée, gameplay, combat, voix, carnet', cards = {
        { title = 'Nouveaux joueurs',      desc = 'Argent de départ, comportement à l\'arrivée', icon = 'user', action = { settings = { group = 'Nouveaux joueurs' } } },
        { title = 'Gameplay & combat',     desc = 'Dégâts, mort, réanimation, armes', icon = 'target', action = { settings = { group = 'Joueurs & combat' } } },
        { title = 'Voix',                  desc = 'Distances chuchoter, normal, crier', icon = 'music', action = { settings = { group = 'Voix' } } },
        { title = 'Carnet du joueur',      desc = 'Série de connexion, objectifs, récompenses', icon = 'list', action = { settings = { group = 'Carnet' } } },
    } },
    { id = 'economy', title = 'Économie', tone = 'light', icon = 'coins', sub = 'Gains, événements économiques', cards = {
        { title = 'Gains',                 desc = 'Bonus de week-end et revenus', icon = 'coins', action = { settings = { group = 'Économie' } } },
    } },
    { id = 'services', title = 'Services & activités', tone = 'white', icon = 'briefcase', sub = 'Gangs, drogues et labos, justice', cards = {
        { title = 'Gangs',                 desc = 'Territoires, guerres, saisons, QG, convois', icon = 'users', action = { settings = { group = 'Gangs' } } },
        { title = 'Drogues & labos',       desc = 'Labos, vente, quartiers, prison, marché noir', icon = 'skull', action = { settings = { group = 'Drogues & labos' } } },
    } },
    { id = 'world', title = 'Monde', tone = 'vivid', icon = 'globe', wide = true, sub = 'Le ciel, le décor et la carte, et ceux qui la peuplent : météo, heure, PNJ, circulation, police ambiante.', cards = {
        { title = 'Météo & heure',     desc = 'Météo fixe ou dynamique, panne de courant, heure figée', icon = 'cloud', action = { settings = { group = 'Météo & heure' } } },
        { title = 'Densité PNJ',       desc = 'Piétons, circulation, véhicules garés', icon = 'users', action = { settings = { group = 'Monde & PNJ', section = 'Population' } } },
        { title = 'Police & recherche', desc = 'Policiers PNJ, patrouilles, hélicoptères', icon = 'shield', action = { settings = { group = 'Monde & PNJ', section = 'Police et recherche' } } },
        { title = 'Transports ambiants', desc = 'Bateaux, trains, camions-poubelles PNJ', icon = 'building', action = { settings = { group = 'Monde & PNJ', section = 'Transports ambiants' } } },
        { title = 'Tout le monde & PNJ', desc = 'Tous les réglages du monde', icon = 'globe', action = { settings = { group = 'Monde & PNJ' } } },
        { title = 'Environnement',     desc = 'Panneaux Vinewood · Enseignes 3D', icon = 'mountain' },
        { title = 'Blips',             desc = 'Blips · Regroupements', icon = 'pin' },
        { title = 'Zones',             desc = 'Zones tracées sur la carte', icon = 'polygon' },
        { title = 'Doorlock',          desc = 'Verrouiller / déverrouiller la porte proche', icon = 'lock', action = { command = 'wbdoor' } },
        { title = 'Ascenseurs',        desc = 'Créer des ascenseurs avec le World Builder', icon = 'building', action = { command = 'worldbuilder' } },
    } },
    { id = 'allsettings', title = 'Tous les réglages', tone = 'light', icon = 'tool', sub = 'Les réglages du serveur, groupe par groupe (modifiés en direct)', cards = {
        { title = 'Serveur',          desc = 'Maintenance, annonces, redémarrages, mode de jeu', icon = 'server', action = { settings = { group = 'Serveur' } } },
        { title = 'Monde & PNJ',      desc = 'Population, police, transports', icon = 'globe', action = { settings = { group = 'Monde & PNJ' } } },
        { title = 'Météo & heure',    desc = 'Météo, panne de courant, heure', icon = 'cloud', action = { settings = { group = 'Météo & heure' } } },
        { title = 'Joueurs & combat', desc = 'Gameplay, dégâts, mort', icon = 'target', action = { settings = { group = 'Joueurs & combat' } } },
        { title = 'Nouveaux joueurs', desc = 'Arrivée des joueurs', icon = 'user', action = { settings = { group = 'Nouveaux joueurs' } } },
        { title = 'Interface',        desc = 'HUD, boussole, notifications', icon = 'palette', action = { settings = { group = 'Interface' } } },
        { title = 'Voix',             desc = 'Distances de la voix', icon = 'music', action = { settings = { group = 'Voix' } } },
        { title = 'Carnet',           desc = 'Récompenses du carnet', icon = 'list', action = { settings = { group = 'Carnet' } } },
        { title = 'Économie',         desc = 'Gains et bonus', icon = 'coins', action = { settings = { group = 'Économie' } } },
        { title = 'Gangs',            desc = '86 réglages : territoires, guerres, saisons…', icon = 'users', action = { settings = { group = 'Gangs' } } },
        { title = 'Drogues & labos',  desc = '108 réglages : labos, vente, prison, marché noir…', icon = 'skull', action = { settings = { group = 'Drogues & labos' } } },
        { title = 'Performance',      desc = 'Mode performance', icon = 'gauge', action = { settings = { group = 'Performance' } } },
        { title = 'Discord',          desc = 'Alertes et résumé quotidien', icon = 'chat', action = { settings = { group = 'Discord' } } },
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
