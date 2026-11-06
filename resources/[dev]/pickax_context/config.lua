Config = {}

Config.Command = 'moi'             -- /moi ouvre le menu
Config.Key = 'LMENU'               -- Alt gauche (modifiable par le joueur dans les paramètres FiveM) ; '' = aucune
Config.HoldToShow = true           -- true : le menu reste affiché tant que la touche est maintenue (relâcher = fermer) ; false : appui = ouvrir / fermer
Config.OffsetPx = 70               -- décalage du menu à droite du personnage (pixels)

-- ═════════════ LE MENU ═════════════
-- Chaque entrée : label, icon (voir la liste dans html/script.js : phone, book, star, cart, briefcase, users, grid, target, list, tool, help, key, coins, game, car…)
--   action : command = 'nom' (sans /)  |  event = 'nom' (événement client)  |  serverEvent = 'nom'  |  export = { 'ressource', 'fonction' }
--   children = { … } : sous-menu (s'ouvre au survol, en cascade)
--   dynamic = 'weaponPlaces' | 'aimStyles' | 'streetSell' | 'seizure' : sous-menu construit en jeu (armes, passant proche, joueur proche) ; masqué si indisponible
Config.Menu = {
    { label = 'Emplacements des armes', icon = 'grid',   dynamic = 'weaponPlaces', empty = 'Aucune arme dans l\'inventaire' },
    { label = 'Style de visée',         icon = 'target', dynamic = 'aimStyles',    empty = 'Aucune arme avec un style de visée' },
    { label = 'Vendre de la drogue',    icon = 'coins',  dynamic = 'streetSell',   empty = 'Aucun passant à proximité' },   -- visible seulement si la vente de rue est active
    { label = 'Perquisition (drogue)',  icon = 'shield', dynamic = 'seizure',      empty = 'Aucun joueur à proximité' },    -- visible seulement pour la police
    { label = 'Mon téléphone',          icon = 'phone',  command = 'phone' },
    { label = 'Mon carnet',             icon = 'book',   command = 'carnet' },
    { label = 'Niveau et récompenses',  icon = 'star',   command = 'pickax_xp_ouvrir' },
    { label = 'Boutique',               icon = 'cart',   command = 'menuboutique' },
    { label = 'Métier', icon = 'briefcase', children = {
        { label = 'Menu du métier',        icon = 'list',  command = 'jobmenu' },
        { label = 'Décorer ma propriété',  icon = 'tool',  command = 'decorer' },
    } },
    { label = 'Gang', icon = 'users', children = {
        { label = 'Menu du gang',          icon = 'list',  command = 'gangmenu' },
        { label = 'Tablette de gang',      icon = 'book',  command = 'gangtablet' },
    } },
    { label = 'Activités', icon = 'game', children = {
        { label = 'Profil mini-jeux',      icon = 'game',  command = 'mgprofil' },
        { label = 'Bourse',                icon = 'coins', command = 'bourse' },
        { label = 'Enchères',              icon = 'coins', command = 'encheres' },
    } },
    { label = 'Aide', icon = 'help', children = {
        { label = 'Tutoriel',              icon = 'help',  command = 'tutoriel' },
        { label = 'Mes touches',           icon = 'key',   command = 'touches' },
    } },
}
