Config = {}

Config.Theme = 'neon'             -- style du panel : 'neon' (vert néon, onglets en haut) ou 'classic' (ancien style). Bouton de bascule dans le panel.
Config.Command = 'staff'          -- /staff ouvre le panel (F11 l'ouvre aussi : touche du menu admin du core)

-- ─────────────── Droits : rang minimum pour chaque action ───────────────
-- 1 = Modérateur · 2 = Admin · 3 = Superadmin · 4 = _dev (toujours autorisé). Les grades personnalisés héritent du rang choisi à leur création.
-- Modifiable aussi en jeu (onglet Équipe → Droits, réservé au rang 4) : le réglage en jeu remplace cette valeur.
Config.Perm = {
    panel = 1, players = 1, viewinv = 2, notes = 1,
    -- téléportation
    gotoPlayer = 1, bringPlayer = 1, sendback = 1, tpcoords = 1,
    -- santé
    heal = 1, revive = 1, armor = 2, freeze = 1, kill = 2,
    -- communication / sanctions
    message = 1, warn = 1, spectate = 1, jail = 1, unjail = 1, kick = 2, ban = 3, warnDelete = 3,
    -- économie / inventaire
    giveMoney = 3, takeMoney = 3, giveItem = 3, takeItem = 3, giveWeapon = 3, clearInventory = 3,
    -- identité / métier
    setJob = 2, setJob2 = 2, resetIdentity = 3, setGrade = 4,
    -- moi
    self_heal = 1, self_revive = 1, self_armor = 1, tp_waypoint = 1, tp_coords = 1, tp_back = 1, self_clothes = 2,
    -- véhicules
    veh_spawn = 2, veh_repair = 1, veh_delete = 1, veh_clean = 1, veh_flip = 1, veh_max = 2, veh_plate = 2, veh_neon = 2, veh_unlock = 1, veh_fuel = 1, veh_give = 3,
    -- monde
    weather = 2, time = 2, announce = 2, cleanup = 2, reviveAll = 3, healAll = 3,
    -- équipe
    reports = 1, staffchat = 1, logs = 2, bookmarks = 2, perms = 4, legacy = 2, devtools = 4,
}

-- Les actions « sanction » ne peuvent pas viser un membre du staff de rang égal ou supérieur.
Config.Punitive = { warn = true, jail = true, unjail = true, kick = true, ban = true, freeze = true, kill = true, takeMoney = true, takeItem = true, clearInventory = true,
    setJob = true, setJob2 = true, resetIdentity = true }

-- ─────────────── Listes proposées dans le panel ───────────────
Config.BanDurations = { '1h', '6h', '1d', '3d', '7d', '30d', 'perm' }
Config.JailPresets  = { 5, 10, 20, 30, 60 }
Config.Reasons      = { 'RDM', 'VDM', 'Freekill', 'Troll', 'Insultes / irrespect', 'Metagaming', 'Powergaming', 'Fail RP', 'Abus de bug', 'Triche', 'Hors-RP en vocal' }
Config.Weather      = { 'EXTRASUNNY', 'CLEAR', 'NEUTRAL', 'SMOG', 'FOGGY', 'OVERCAST', 'CLOUDS', 'CLEARING', 'RAIN', 'THUNDER', 'SNOW', 'BLIZZARD', 'SNOWLIGHT', 'XMAS', 'HALLOWEEN' }

-- Points de téléportation rapide (ajoutables aussi en jeu : onglet Outils → Favoris)
Config.QuickTP = {
    { label = 'Commissariat central', x = 435.63, y = -974.47, z = 30.72 },
    { label = 'Hôpital central', x = 297.13, y = -601.71, z = 43.39 },
    { label = 'Fourrière', x = 401.65, y = -1627.99, z = 29.29 },
    { label = 'PC / place', x = 219.33, y = -811.19, z = 30.65 },
    { label = 'Sheriff Paleto', x = -432.19, y = 6009.74, z = 31.49 },
    { label = 'Aéroport LSIA', x = -1037.0, y = -2737.0, z = 20.17 },
}

-- ─────────────── Avertissements ───────────────
Config.Warn = {
    KickAt = 0,        -- expulsion automatique à N avertissements actifs (0 = désactivé)
    ExpireDays = 0,    -- les avertissements plus vieux ne comptent plus pour le seuil (0 = jamais)
}

Config.ChatMax        = 60        -- messages du chat staff conservés
Config.AnnounceMax    = 160       -- longueur max d'une annonce
Config.CleanupMaxRadius = 300.0   -- rayon max du nettoyage de zone
Config.LogDays        = 90        -- durée de conservation du journal staff

-- Libellés affichés dans Équipe → Droits : clé = { groupe, libellé }
Config.PermLabels = {
    panel = { 'Général', 'Ouvrir le panel' }, players = { 'Général', 'Voir la liste et les fiches joueurs' }, viewinv = { 'Général', 'Voir l\'inventaire d\'un joueur' }, notes = { 'Général', 'Ajouter des notes sur un joueur' },
    gotoPlayer = { 'Téléportation', 'Aller sur un joueur' }, bringPlayer = { 'Téléportation', 'Amener un joueur' }, sendback = { 'Téléportation', 'Renvoyer un joueur à sa position' }, tpcoords = { 'Téléportation', 'Téléporter à des coordonnées' },
    heal = { 'Santé', 'Soigner un joueur' }, revive = { 'Santé', 'Réanimer un joueur' }, armor = { 'Santé', 'Donner un gilet' }, freeze = { 'Santé', 'Geler / libérer un joueur' }, kill = { 'Santé', 'Tuer un joueur' },
    message = { 'Sanctions', 'Envoyer un message' }, warn = { 'Sanctions', 'Avertir' }, spectate = { 'Sanctions', 'Spectate' }, jail = { 'Sanctions', 'Mettre en prison' }, unjail = { 'Sanctions', 'Sortir de prison' },
    kick = { 'Sanctions', 'Expulser' }, ban = { 'Sanctions', 'Bannir' }, warnDelete = { 'Sanctions', 'Supprimer avertissements et notes' },
    giveMoney = { 'Économie', 'Donner de l\'argent' }, takeMoney = { 'Économie', 'Retirer de l\'argent' }, giveItem = { 'Économie', 'Donner un objet' }, takeItem = { 'Économie', 'Retirer un objet' },
    giveWeapon = { 'Économie', 'Donner une arme' }, clearInventory = { 'Économie', 'Vider l\'inventaire' },
    setJob = { 'Identité', 'Changer le métier' }, setJob2 = { 'Identité', 'Changer le gang / l\'orga' }, resetIdentity = { 'Identité', 'Réinitialiser l\'identité' }, setGrade = { 'Identité', 'Attribuer un grade staff' },
    self_heal = { 'Moi', 'Me soigner' }, self_revive = { 'Moi', 'Me réanimer' }, self_armor = { 'Moi', 'Me donner un gilet' }, tp_waypoint = { 'Moi', 'Téléportation sur le marqueur' },
    tp_coords = { 'Moi', 'Téléportation par coordonnées / favoris' }, tp_back = { 'Moi', 'Retour à ma position précédente' }, self_clothes = { 'Moi', 'Tenue staff' },
    veh_spawn = { 'Véhicules', 'Faire apparaître' }, veh_repair = { 'Véhicules', 'Réparer' }, veh_delete = { 'Véhicules', 'Supprimer' }, veh_clean = { 'Véhicules', 'Nettoyer' }, veh_flip = { 'Véhicules', 'Retourner' },
    veh_max = { 'Véhicules', 'Custom au maximum' }, veh_plate = { 'Véhicules', 'Changer la plaque' }, veh_neon = { 'Véhicules', 'Néons' }, veh_unlock = { 'Véhicules', 'Déverrouiller' }, veh_give = { 'Véhicules', 'Donner un véhicule avec clé (garage)' }, veh_fuel = { 'Véhicules', 'Faire le plein' },
    weather = { 'Monde', 'Changer la météo' }, time = { 'Monde', 'Changer l\'heure' }, announce = { 'Monde', 'Annonce serveur' }, cleanup = { 'Monde', 'Nettoyer une zone' },
    reviveAll = { 'Monde', 'Réanimer tout le monde' }, healAll = { 'Monde', 'Soigner tout le monde' },
    reports = { 'Équipe', 'Gérer les reports' }, staffchat = { 'Équipe', 'Chat staff' }, logs = { 'Équipe', 'Journal des actions staff' }, bookmarks = { 'Équipe', 'Gérer les favoris de téléportation' },
    perms = { 'Équipe', 'Modifier ces droits, grades et droits de l\'ancien menu (toujours rang 4)' }, devtools = { 'Équipe', 'Outils développeur (cutscenes, animations, intérieurs)' }, legacy = { 'Équipe', 'Ancien menu (outils développeur)' },
}
