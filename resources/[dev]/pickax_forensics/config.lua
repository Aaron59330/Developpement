Config = {}

-- ═════════════════════════════ POLICE SCIENTIFIQUE ═════════════════════════════
Config.Enabled    = true
Config.UseCommands = false   -- true = active aussi /prelever, /gsr, /balistique (par défaut : menu contextuel, tablette de police et laboratoire)
Config.PoliceJobs = { 'police', 'sheriff' }          -- métiers qui voient les douilles, les ramassent et les analysent
Config.AdminGroups = { _dev = true, superadmin = true, admin = true }   -- /laboici : affiche la position à copier dans Config.Labs

-- ═════════════════════════════ DOUILLES ═════════════════════════════
-- Chaque tir laisse une douille au sol (décidé par le SERVEUR : arme réellement équipée, position réelle du tireur). Seule la police les voit.
Config.Casings = {
    LifetimeMinutes = 45,        -- une douille disparaît du sol après ce délai (pluie, passants…)
    MinInterval     = 1200,      -- ms minimum entre deux douilles d'un même tireur (une rafale ne laisse pas une douille par balle)
    MaxPerShooter   = 12,        -- douilles au sol par tireur : au-delà, la plus ancienne disparaît
    MaxOnGround     = 250,       -- limite globale sur le serveur
    ScatterRadius   = 1.4,       -- les douilles tombent autour du tireur (mètres)
    PickupDistance  = 1.8,       -- distance pour ramasser
    DrawDistance    = 14.0,      -- distance d'affichage du repère (côté police)
    PickupSeconds   = 3,         -- durée du ramassage
    BagItem         = '',        -- item exigé pour ramasser (sachet de scellé) ; vide = aucun. Ex : 'evidence_bag' (consommé)
    Item            = 'evidence_casing',   -- item remis au policier (scellé : porte les infos de la douille)
    Ignored = {                  -- armes qui ne laissent pas de douille (revolvers, armes blanches, lancers, non létales…)
        'WEAPON_REVOLVER', 'WEAPON_REVOLVER_MK2', 'WEAPON_DOUBLEACTION', 'WEAPON_NAVYREVOLVER',
        'WEAPON_STUNGUN', 'WEAPON_STUNGUN_MP', 'WEAPON_FLAREGUN', 'WEAPON_MUSKET', 'WEAPON_FIREEXTINGUISHER', 'WEAPON_PETROLCAN', 'WEAPON_FIREWORK',
        'WEAPON_RPG', 'WEAPON_GRENADELAUNCHER', 'WEAPON_RAILGUN', 'WEAPON_COMPACTLAUNCHER', 'WEAPON_HOMINGLAUNCHER',
    },
}

-- ═════════════════════════════ LABORATOIRE ═════════════════════════════
-- Positions où un policier analyse ses scellés. Place-toi à l'endroit voulu et tape /laboici (admin) pour obtenir les coordonnées.
Config.Labs = {
    -- (aucun point créé automatiquement : renseigne tes coordonnées ici, ex. vector3(x, y, z))
    -- { label = 'Laboratoire', coords = vector3(0.0, 0.0, 0.0), blip = true },
}
Config.Analysis = {
    Seconds       = 20,          -- durée d'une analyse
    Command       = 'balistique',-- /balistique [n° de série ou signature BAL-xxxx] : fichier balistique (police)
    KeepDays      = 30,          -- les rapports et douilles sont conservés ce nombre de jours
    DrawDistance  = 12.0,
    InteractDistance = 1.8,
}

-- ═════════════════════════════ CALIBRES ═════════════════════════════
-- Calibre affiché dans le rapport selon l'arme (nom de l'item ox_inventory). Arme absente de la liste : « calibre indéterminé ».
Config.Calibers = {
    WEAPON_PISTOL = '9 mm', WEAPON_PISTOL_MK2 = '9 mm', WEAPON_COMBATPISTOL = '9 mm', WEAPON_APPISTOL = '9 mm', WEAPON_PISTOL50 = '.50 AE',
    WEAPON_SNSPISTOL = '.380 ACP', WEAPON_SNSPISTOL_MK2 = '.380 ACP', WEAPON_HEAVYPISTOL = '.45 ACP', WEAPON_VINTAGEPISTOL = '.32 ACP', WEAPON_CERAMICPISTOL = '9 mm',
    WEAPON_MARKSMANPISTOL = '.22 LR', WEAPON_MICROSMG = '.45 ACP', WEAPON_SMG = '9 mm', WEAPON_SMG_MK2 = '9 mm', WEAPON_ASSAULTSMG = '9 mm', WEAPON_COMBATPDW = '5.7 mm',
    WEAPON_MACHINEPISTOL = '9 mm', WEAPON_MINISMG = '.32 ACP', WEAPON_GUSENBERG = '.45 ACP',
    WEAPON_ASSAULTRIFLE = '7.62 mm', WEAPON_ASSAULTRIFLE_MK2 = '7.62 mm', WEAPON_CARBINERIFLE = '5.56 mm', WEAPON_CARBINERIFLE_MK2 = '5.56 mm',
    WEAPON_ADVANCEDRIFLE = '5.56 mm', WEAPON_SPECIALCARBINE = '5.56 mm', WEAPON_SPECIALCARBINE_MK2 = '5.56 mm', WEAPON_BULLPUPRIFLE = '5.56 mm', WEAPON_BULLPUPRIFLE_MK2 = '5.56 mm',
    WEAPON_COMPACTRIFLE = '7.62 mm', WEAPON_MILITARYRIFLE = '5.56 mm', WEAPON_MG = '7.62 mm', WEAPON_COMBATMG = '7.62 mm', WEAPON_COMBATMG_MK2 = '7.62 mm',
    WEAPON_PUMPSHOTGUN = 'Calibre 12', WEAPON_PUMPSHOTGUN_MK2 = 'Calibre 12', WEAPON_SAWNOFFSHOTGUN = 'Calibre 12', WEAPON_ASSAULTSHOTGUN = 'Calibre 12',
    WEAPON_BULLPUPSHOTGUN = 'Calibre 12', WEAPON_HEAVYSHOTGUN = 'Calibre 12', WEAPON_DBSHOTGUN = 'Calibre 12', WEAPON_AUTOSHOTGUN = 'Calibre 12',
    WEAPON_SNIPERRIFLE = '.308 Win', WEAPON_HEAVYSNIPER = '.50 BMG', WEAPON_HEAVYSNIPER_MK2 = '.50 BMG', WEAPON_MARKSMANRIFLE = '7.62 mm', WEAPON_MARKSMANRIFLE_MK2 = '7.62 mm',
}


-- ═════════════════════════════ PROFILS ADN / EMPREINTES ═════════════════════════════
-- Un profil identifie une personne SEULEMENT si la police l'a prélevée avant (/prelever) : sans profil, une trace reste « individu inconnu ».
Config.Salt = 'change-moi'            -- graine secrète des codes ADN / empreintes : change-la (les codes deviennent imprévisibles hors du serveur)
Config.Profile = {
    Command  = 'prelever',            -- /prelever [id] : prélèvement ADN (salive) + empreintes d'un suspect proche
    Distance = 3.0,
    Seconds  = 6,
}

-- ═════════════════════════════ SANG (ADN) ═════════════════════════════
Config.Blood = {
    Enabled         = true,
    MinInterval     = 8,             -- secondes minimum entre deux traces d'un même blessé
    MaxPerPlayer    = 6,
    LifetimeMinutes = 60,
    PickupSeconds   = 4,
    Item            = 'evidence_blood',   -- prélèvement scellé
}

-- ═════════════════════════════ EMPREINTES ═════════════════════════════
-- Toute personne qui monte dans un véhicule sans gants y laisse ses empreintes. La police les relève au « poudrage » (mini-jeu).
Config.Prints = {
    Enabled         = true,
    GloveItem       = 'latex_gloves',     -- avec cet item dans l'inventaire : aucune empreinte (vide = pas de gants possibles)
    PerVehicleInterval = 600,             -- secondes minimum avant de re-laisser une empreinte sur le même véhicule
    MaxPerVehicle   = 5,
    LifetimeMinutes = 180,
    DustDistance    = 3.0,
    Item            = 'evidence_print',
    MinQuality      = 60,                 -- % de réussite du mini-jeu de poudrage sous lequel l'empreinte est inexploitable
}

-- ═════════════════════════════ RÉSIDUS DE TIR (GSR) ═════════════════════════════
Config.Gsr = {
    Enabled  = true,
    Command  = 'gsr',                -- /gsr [id] : test d'un suspect proche
    Minutes  = 30,                   -- durée pendant laquelle les résidus restent détectables
    WipeItem = 'gsr_wipes',          -- lingettes : effacent les résidus (consommées)
    Distance = 3.0,
    Seconds  = 5,
}

-- ═════════════════════════════ NETTOYAGE DE SCÈNE ═════════════════════════════
Config.Cleaning = {
    Enabled  = true,
    Item     = 'cleaning_kit',       -- efface sang, douilles et empreintes proches (consommé) après un mini-jeu de frottage
    Radius   = 4.0,
}

-- ═════════════════════════════ LABORATOIRE : mini-jeux ═════════════════════════════
Config.Lab = {
    MinSeconds  = 6,                 -- durée minimale d'une analyse (anti-triche : un résultat « instantané » est refusé)
    MaxRetries  = 2,                 -- échecs autorisés sur un même prélèvement avant qu'il soit dégradé
    DnaBases    = 10,                -- longueur du brin ADN du mini-jeu
    DnaSeconds  = 30,
    PrintRounds = 3,
    PrintSeconds = 20,
}
