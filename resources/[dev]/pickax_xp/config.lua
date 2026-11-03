Config = {}

-- ═════════════════════════════ GÉNÉRAL ═════════════════════════════
Config.Key = 'F4'                 -- touche qui ouvre l'écran « Niveau et récompenses » (modifiable ensuite dans les paramètres FiveM)
Config.MaxLevel = 50
-- XP cumulée nécessaire pour atteindre le niveau n :  Base × (n − 1) ^ Exponent   (niveau 1 = 0 XP)
Config.Curve = { Base = 120, Exponent = 1.55 }

-- Temps de jeu et connexion quotidienne
Config.Playtime = { Enabled = true, EveryMinutes = 10, XP = 15 }
Config.DailyLogin = { Enabled = true, XP = 40 }

-- ═════════════════════════════ ACTIONS QUI RAPPORTENT DE L'XP ═════════════════════════════
-- xp          : XP fixe par action
-- perDollar   : XP par dollar dépensé (achats) ; min / max bornent le gain d'un seul achat
-- items       : XP par unité pour certains objets précis (achat en boutique) — prioritaire sur perDollar
-- cooldown    : secondes minimales entre deux gains de cette action pour un même joueur (0 = aucune)
-- dailyCap    : XP maximale gagnable par jour avec cette action (0 = illimitée)
Config.Actions = {
    buy_item     = { label = 'Acheter dans un magasin', perDollar = 0.05, min = 1, max = 60, dailyCap = 800,
                     items = { water = 3, bread = 3, burger = 5, sandwich = 5, bandage = 4 } },
    buy_vehicle  = { label = 'Acheter un véhicule', perDollar = 0.002, min = 60, max = 900 },
    buy_coins    = { label = 'Achat en boutique à coins', xp = 0 },
    cook         = { label = 'Cuisiner un plat', xp = 14, cooldown = 20, dailyCap = 400 },
    fish         = { label = 'Pêcher', xp = 10, cooldown = 15, dailyCap = 300 },
    hunt         = { label = 'Chasser et dépecer', xp = 14, cooldown = 20, dailyCap = 300 },
    run          = { label = 'Course taxi / livraison', xp = 25, cooldown = 30, dailyCap = 500 },
    repair       = { label = 'Réparer un véhicule', xp = 22, cooldown = 20, dailyCap = 500 },
    treat        = { label = 'Soigner un patient', xp = 20, cooldown = 15, dailyCap = 500 },
    forensics    = { label = 'Analyse de police scientifique', xp = 18, cooldown = 20, dailyCap = 400 },
    job_task     = { label = 'Tâche de métier', xp = 12, cooldown = 10, dailyCap = 600 },
    sell_vehicle = { label = 'Vendre un véhicule (concession)', perDollar = 0.001, min = 40, max = 500 },
    minigame     = { label = 'Réussir un mini-jeu', xp = 8, cooldown = 10, dailyCap = 200 },
    illegal      = { label = 'Activité illégale réussie', xp = 20, cooldown = 30, dailyCap = 400 },
}

-- ═════════════════════════════ RÉCOMPENSES PAR NIVEAU ═════════════════════════════
-- Données à l'atteinte du niveau (une seule fois). Types :
--   { type = 'money', amount = 500 }          argent liquide
--   { type = 'bank',  amount = 2000 }         argent en banque
--   { type = 'item',  item = 'water', count = 5 }   objet (doit exister dans ox_inventory)
--   { type = 'text',  label = 'Accès à ...' } simple mention affichée dans l'écran (à gérer toi-même : grade, permis, avantage…)
Config.Rewards = {
    [2]  = { { type = 'money', amount = 500 } },
    [3]  = { { type = 'item', item = 'water', count = 5 }, { type = 'item', item = 'bread', count = 5 } },
    [5]  = { { type = 'bank', amount = 2000 }, { type = 'item', item = 'bandage', count = 3 } },
    [8]  = { { type = 'money', amount = 3000 } },
    [10] = { { type = 'bank', amount = 7500 }, { type = 'text', label = 'Titre « Habitué »' } },
    [15] = { { type = 'bank', amount = 12000 }, { type = 'item', item = 'burger', count = 10 } },
    [20] = { { type = 'bank', amount = 20000 }, { type = 'text', label = 'Titre « Citoyen »' } },
    [25] = { { type = 'bank', amount = 30000 } },
    [30] = { { type = 'bank', amount = 50000 }, { type = 'text', label = 'Titre « Vétéran »' } },
    [40] = { { type = 'bank', amount = 90000 } },
    [50] = { { type = 'bank', amount = 200000 }, { type = 'text', label = 'Titre « Légende de la ville »' } },
}

-- Comptes ESX utilisés par les récompenses
Config.Accounts = { money = 'money', bank = 'bank' }
Config.Notify = { Batch = 3000 }   -- les gains d'XP sont regroupés dans une seule notification toutes les N millisecondes
