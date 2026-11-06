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
