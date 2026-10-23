Config = {}

-- ╔═══════════════════════════════════════════════════════════════════════════════════════════╗
-- ║  BRAQUAGES — réglages généraux (les missions sont dans missions/*.lua)                    ║
-- ╚═══════════════════════════════════════════════════════════════════════════════════════════╝

Config.Locale = 'fr'

-- Tableau de planification (là où le chef de braquage ouvre l'écran et lance les missions)
-- ⚠ Coordonnées à CALIBRER en jeu : tape /heistpos à l'endroit voulu, la console F8 affiche vector4(...)
Config.Board = {
    coords  = vec3(-1267.2, -3013.1, -45.5),   -- ← À CALIBRER (placeholder : zone des hangars de l'aéroport)
    radius  = 2.0,
    label   = 'Tableau de planification',
    blip    = { sprite = 473, color = 3, scale = 0.8, name = 'Braquage : Le problème Bogdan' },
}

Config.Crew = { min = 2, max = 4 }             -- joueurs pour LANCER le finale (les préparatifs peuvent se faire en solo si min=1)
Config.PrepMinPlayers = 1                      -- joueurs minimum pour un préparatif / mise en place
Config.Cooldown = 120                          -- minutes avant de pouvoir relancer le finale (par chef)
Config.MinPolice = 0                           -- policiers connectés requis pour lancer le FINALE (0 = désactivé)
Config.PoliceJobs = { 'lspd', 'police' }
Config.InviteDistance = 30.0                   -- distance max pour inviter un joueur (m)

-- Paiement : le jeu de base paie 1 282 500 $ (Normal) / 1 603 125 $ (Difficile). Adapte à ton économie.
Config.PayoutMultiplier = 0.02                 -- 0.02 = 2 % du montant GTA → ~25 650 $ en Normal
Config.PayoutAccount    = 'bank'               -- 'bank' | 'money' | 'black_money'
Config.LeaderCut        = 0.0                  -- part supplémentaire du chef (0.10 = +10 %), le reste est partagé à parts égales

Config.Difficulty = {                          -- sélectionnable par le chef sur le tableau
    normal = { label = 'Normal',    payout = 1282500, enemyHealth = 200, enemyAccuracy = 35 },
    hard   = { label = 'Difficile', payout = 1603125, enemyHealth = 300, enemyAccuracy = 60 },
}

Config.Enemy = {                               -- ennemis générés par les missions
    weapons = { `WEAPON_CARBINERIFLE`, `WEAPON_PISTOL`, `WEAPON_SMG` },
    relationGroup = 'PK_HEIST_ENEMY',
}

Config.Keys = { interact = 38 }                -- E

Config.Debug = false

Config.EliteBonus = 0.10                       -- bonus (+10 %) si le finale est réussi dans le temps de l'Élite sans mort
