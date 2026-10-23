Config = {}

Config.Command = 'hub'
Config.Key     = 'F1'                 -- touche d'ouverture (modifiable par le joueur dans les paramètres FiveM)

-- Raccourcis de l'écran d'accueil : chaque entrée lance une commande. Les commandes qui n'existent pas sur le serveur sont masquées automatiquement.
Config.Shortcuts = {
    { id = 'phone',   label = 'Téléphone',      icon = 'phone',   command = 'phone',    desc = 'Appels, messages, banque' },
    { id = 'job',     label = 'Menu métier',    icon = 'briefcase', command = 'jobmenu', desc = 'Actions et factures du métier' },
    { id = 'gang',    label = 'Menu du gang',   icon = 'shield',  command = 'gangmenu', desc = 'Organisation et activités' },
    { id = 'emotes',  label = 'Animations',     icon = 'smile',   command = 'emoteui',  desc = 'Emotes et démarches' },
    { id = 'carplay', label = 'CarPlay',        icon = 'music',   command = 'carplay',  desc = 'Autoradio du véhicule' },
    { id = 'boutique',label = 'Boutique',       icon = 'bag',     command = 'menuboutique', desc = 'Véhicules, armes, packs' },
}

-- Activités (onglet « Activités ») : le bouton GPS pose un point sur la carte.
-- ⚠ Coordonnées à adapter à ta carte (commande /heistpos de pickax_heists pour les relever).
Config.Activities = {
    { label = 'Braquage : Le problème Bogdan', desc = 'Préparatifs, mises en place et finale à 2 équipes.', tag = 'Équipe 2-4', coords = vec3(-1267.2, -3013.1, 13.9) },
    { label = 'Mini-jeux',                      desc = 'Basket, football, paintball, laser game…',          tag = 'Arène' },
    { label = 'Événements du serveur',          desc = 'Largages, braquages de fourgon, épaves…',           tag = 'Aléatoire' },
}

Config.Rules = {                       -- onglet « Serveur »
    'Respecte les autres joueurs et le staff.',
    'Reste dans ton rôle : pas de métagaming ni de powergaming.',
    'Pas de RDM / VDM : une scène de violence doit avoir une raison RP.',
    'En cas de problème, ouvre un report plutôt que de te faire justice.',
}

Config.Accounts = { bank = 'Banque', money = 'Espèces', black_money = 'Argent sale' }
Config.ShowBlackMoney = false
