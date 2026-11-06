Config = {}

Config.Enabled = true

-- ═════════════════════════════ RÈGLES DE TIR ═════════════════════════
Config.Rules = {
    -- Armes autorisées en véhicule : par groupe GTA (416676503 = pistolets, 3337201093 = pistolets-mitrailleurs, 860033945 = fusils à pompe, 970310034 = fusils d'assaut…)
    AllowedGroups = { 416676503, 3337201093 },
    AllowedNames  = {},                                   -- armes précises toujours autorisées, ex. 'WEAPON_SAWNOFFSHOTGUN'
    BlockedNames  = { 'WEAPON_STUNGUN' },                 -- armes toujours interdites
    -- Places autorisées (-1 = conducteur, 0 = passager avant, 1 = arrière gauche, 2 = arrière droit, 3+ = places suivantes)
    Seats = { [-1] = true, [0] = true, [1] = true, [2] = true, [3] = true, [4] = true },
    -- Vitesse maximale pour tirer (km/h, 0 = pas de limite), selon la place
    MaxSpeedKmh = { driver = 0, passenger = 0 },
    -- Classes de véhicules où le tir est interdit : 14 bateaux · 15 hélicoptères · 16 avions · 19 militaires · 20 utilitaires lourds · 21 trains
    BlockedClasses = { 14, 15, 16, 19, 20, 21 },
    ExemptJobs = {},     -- métiers non concernés par la restriction d'armes (ex. { 'police' } : fusils d'assaut autorisés en véhicule)
    Message = 'Tu ne peux pas tirer avec cette arme depuis un véhicule.',
}

-- ═════════════════════════════ SORTIR PAR LA FENÊTRE ═════════════════
-- Maintiens la touche : le joueur se penche à la fenêtre pour tirer (seulement si l'arme, la place et la vitesse sont autorisées).
Config.Lean = {
    Enabled = true,
    Key = 'LMENU',                 -- touche par défaut (Alt gauche) ; modifiable par le joueur dans les paramètres FiveM
    Seats = { [-1] = false, [0] = true, [1] = true, [2] = true, [3] = true, [4] = true },   -- le conducteur reste au volant
    MaxSpeedKmh = 140,             -- au-delà, impossible de se pencher (0 = pas de limite)
    -- Animation jouée pendant que le joueur est penché. Une par place (valeur 'default' = toutes les places).
    -- dict + clip : animation GTA (ou d'un pack d'animations de ton serveur). Laisse dict vide pour ne jouer aucune animation.
    Animations = {
        default = { dict = '', clip = '', flag = 49 },
        -- [0] = { dict = 'mon@pack@lean', clip = 'lean_right', flag = 49 },
        -- [1] = { dict = 'mon@pack@lean', clip = 'lean_left',  flag = 49 },
    },
    Notify = true,                 -- message à l'écran quand la touche est refusée
}
