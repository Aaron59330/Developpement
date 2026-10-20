Config = {}

Config.Refresh       = 1000      -- ms entre deux mises à jour des armes visibles
Config.ShowToOthers  = true      -- les autres joueurs voient tes armes rangées (affichées chez eux via un état partagé)
Config.OthersDistance = 40.0     -- distance max pour afficher les armes des autres joueurs
Config.HideInVehicle = true      -- armes rangées masquées en véhicule (évite qu'elles traversent le siège)
Config.DefaultPlace  = 'hidden'  -- placement d'une arme jamais réglée : 'hidden' = invisible, comme dans le jeu de base
Config.TuneCommand   = 'wctune'  -- commande de réglage des positions en jeu (groupes ci-dessous) ; false pour la désactiver
Config.DevGroups     = { _dev = true }

-- Placements proposés dans le menu contextuel (Moi → Armes)
Config.Places = {
    back   = 'Dans le dos',
    front  = 'À la ceinture (devant)',
    pocket = 'Dans la poche',
    hidden = 'Cachée (invisible)',
}
Config.PlaceOrder = { 'back', 'front', 'pocket', 'hidden' }

-- Placements autorisés selon le type d'arme (pistolet dans la poche oui, fusil non…)
Config.Allowed = {
    pistol = { back = true, front = true, pocket = true, hidden = true },
    melee  = { back = true, front = true, hidden = true },
    smg    = { back = true, front = true, hidden = true },
    long   = { back = true, hidden = true },
}

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
    front = {
        pistol = { 11816,  0.19,   0.06, -0.05, -90.0,   0.0, 0.0 },
        smg    = { 24816,  0.22,   0.08, -0.10, -50.0,  80.0, 0.0 },
        melee  = { 11816,  0.22,   0.06,  0.04,   0.0, 100.0, 0.0 },
    },
    pocket = {
        pistol = { 51826,  0.12,   0.02,  0.02,  90.0,   0.0, 0.0 },
    },
}
