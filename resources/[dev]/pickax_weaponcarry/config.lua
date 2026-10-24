Config = {}

Config.Refresh       = 1000      -- ms entre deux mises à jour des armes visibles
Config.ShowToOthers  = true      -- les autres joueurs voient tes armes rangées (affichées chez eux via un état partagé)
Config.OthersDistance = 40.0     -- distance max pour afficher les armes des autres joueurs
Config.HideInVehicle = true      -- armes rangées masquées en véhicule (évite qu'elles traversent le siège)
Config.DefaultPlace  = 'hidden'  -- placement d'une arme jamais réglée : 'hidden' = invisible, comme dans le jeu de base
Config.TuneCommand   = 'wctune'  -- commande de réglage des positions en jeu (groupes ci-dessous) ; false pour la désactiver
Config.DevGroups     = { _dev = true }

-- Placements proposés dans le menu contextuel (Moi → Gestion armes)
Config.Places = {
    back     = 'Dans le dos',
    backlow  = 'Bas du dos (ceinture arrière)',
    front    = 'À la ceinture (devant)',
    hipR     = 'Hanche droite',
    hipL     = 'Hanche gauche',
    thighR   = 'Cuisse droite (holster)',
    thighL   = 'Cuisse gauche (holster)',
    chest    = 'Poitrine (bandoulière)',
    pocket   = 'Dans la poche',
    ankle    = 'Cheville',
    hidden   = 'Cachée (invisible)',
}
Config.PlaceOrder = { 'back', 'backlow', 'front', 'hipR', 'hipL', 'thighR', 'thighL', 'chest', 'pocket', 'ankle', 'hidden' }

-- Placements autorisés selon le type d'arme (pistolet dans la poche oui, fusil non…)
Config.Allowed = {
    pistol = { back = true, backlow = true, front = true, hipR = true, hipL = true, thighR = true, thighL = true, chest = true, pocket = true, ankle = true, hidden = true },
    melee  = { back = true, backlow = true, front = true, hipR = true, hipL = true, thighR = true, thighL = true, hidden = true },
    smg    = { back = true, backlow = true, front = true, hipR = true, hipL = true, chest = true, hidden = true },
    long   = { back = true, chest = true, hidden = true },
}

-- Style de visée (menu contextuel → Moi → Style de visée) : posture de l'arme en main, par arme.
-- `override` = nom passé à SetWeaponAnimationOverride ; `classes` = types d'armes concernés.
Config.AimStyles = {
    default = { label = 'Standard',                  override = 'Default' },
    gang    = { label = 'Gangster (arme penchée)',   override = 'Gang1H',    classes = { pistol = true } },
    hill    = { label = 'Campagnard (bras tendu)',   override = 'Hillbilly', classes = { pistol = true } },
    ballistic = { label = 'Tactique (position basse)', override = 'Ballistic', classes = { pistol = true, smg = true } },
}
Config.AimOrder = { 'default', 'gang', 'hill', 'ballistic' }
Config.AimCheck = 500     -- ms entre deux vérifications du style appliqué à l'arme en main

-- Groupe d'arme GTA → type
Config.Groups = {
    [416676503]  = 'pistol',   -- pistolets
    [690389602]  = 'pistol',   -- taser
    [3337201093] = 'smg',      -- pistolets-mitrailleurs
    [3566412244] = 'melee',    -- armes blanches
    [970310034]  = 'long',     -- fusils d'assaut
    [860033945]  = 'long',     -- fusils à pompe
    [3082541095] = 'long',     -- snipers
    [1159398588] = 'long',     -- mitrailleuses
    [2725924767] = 'long',     -- armes lourdes
}
Config.Override = { WEAPON_MACHINEPISTOL = 'pistol', WEAPON_MICROSMG = 'pistol' }   -- exceptions par nom d'arme

-- Position sur le corps : { os, x, y, z, rotX, rotY, rotZ } par placement puis par type d'arme.
-- Valeurs de départ à ajuster en jeu avec /wctune (voir README) ; os 24816 = colonne (dos), 11816 = bassin, 51826 = cuisse droite.
Config.Attach = {
    back = {
        long   = { 24816,  0.075, -0.15, -0.02,   0.0, 165.0, 0.0 },
        smg    = { 24816,  0.075, -0.15,  0.00,   0.0, 165.0, 0.0 },
        pistol = { 24816, -0.10,  -0.15, -0.13,   0.0, 165.0, 0.0 },
        melee  = { 24816,  0.00,  -0.18,  0.00,   0.0,  90.0, 0.0 },
    },
    -- Les placements ci-dessous sont des valeurs de départ à affiner en jeu avec /wctune (voir README)
    backlow = {
        pistol = { 11816, -0.15, -0.12,  0.04,   0.0,  90.0, 0.0 },
        smg    = { 11816, -0.10, -0.15,  0.00,   0.0, 120.0, 0.0 },
        melee  = { 11816, -0.12, -0.14,  0.03,   0.0,  90.0, 0.0 },
    },
    front = {
        pistol = { 11816,  0.19,   0.06, -0.05, -90.0,   0.0, 0.0 },
        smg    = { 24816,  0.22,   0.08, -0.10, -50.0,  80.0, 0.0 },
        melee  = { 11816,  0.22,   0.06,  0.04,   0.0, 100.0, 0.0 },
    },
    hipR = {
        pistol = { 11816,  0.07,   0.19, -0.03, -90.0,   0.0, 180.0 },
        smg    = { 11816,  0.07,   0.20, -0.06, -80.0,  10.0, 180.0 },
        melee  = { 11816,  0.05,   0.18,  0.00,   0.0,  80.0, 0.0 },
    },
    hipL = {
        pistol = { 11816,  0.07,  -0.19, -0.03, -90.0,   0.0,   0.0 },
        smg    = { 11816,  0.07,  -0.20, -0.06, -80.0, -10.0,   0.0 },
        melee  = { 11816,  0.05,  -0.18,  0.00,   0.0, -80.0, 0.0 },
    },
    thighR = {
        pistol = { 51826,  0.02,   0.06,  0.10, -100.0,  0.0, 0.0 },
        melee  = { 51826,  0.00,   0.09,  0.10,    0.0, 90.0, 0.0 },
    },
    thighL = {
        pistol = { 58271,  0.02,   0.06, -0.10,  100.0,  0.0, 0.0 },
        melee  = { 58271,  0.00,   0.09, -0.10,    0.0, 90.0, 0.0 },
    },
    chest = {
        long   = { 24818,  0.10,   0.12,  0.00,   0.0,  20.0, 0.0 },
        smg    = { 24818,  0.10,   0.12,  0.00,   0.0,  30.0, 0.0 },
        pistol = { 24818,  0.10,   0.10,  0.06,   0.0,  90.0, 0.0 },
    },
    pocket = {
        pistol = { 51826,  0.12,   0.02,  0.02,  90.0,   0.0, 0.0 },
    },
    ankle = {
        pistol = { 63931,  0.00,   0.00, -0.10,   0.0,  90.0, 0.0 },
    },
}
