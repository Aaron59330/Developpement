Config = {}

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
--  CARNET DU JOUEUR (touche F3 ou /carnet)
--  Simple : tout est récompensé AUTOMATIQUEMENT (argent sur le compte bancaire + notification), le carnet sert à voir où on en est.
--  Chaque joueur a chaque jour : une récompense de série de connexion + 3 objectifs (facile / moyen / difficile) adaptés à ce qu'il peut faire.
--  Chaque semaine : 1 gros objectif perso + 1 « défi de la ville » que TOUS les joueurs font avancer ensemble (bonus pour tout le serveur).
--  Les ressources du serveur alimentent le carnet via : exports.pickax_carnet:Report(src, 'job_task' | 'earn' | 'sell' | 'purchase' | 'minigame', quantité)
-- ═══════════════════════════════════════════════════════════════════════════════════════════════

Config.Command  = 'carnet'
Config.Key      = 'F3'
Config.Enabled  = true             -- modifiable depuis le panel web (Réglages → Carnet)
Config.Account  = 'bank'           -- compte crédité : 'bank' | 'money'
Config.RewardMultiplier = 1.0      -- multiplicateur de TOUTES les récompenses (aussi réglable depuis le panel web) ; l'économie du serveur (presets) s'applique en plus

-- Le jour change à ResetHour (heure du serveur = UTC + UtcOffset) ; la semaine commence le lundi à cette heure
Config.UtcOffset = 1
Config.ResetHour = 5

-- ─────────────── Série de connexion ───────────────
-- Récompense du jour n de la série (le cycle recommence après le dernier). Se connecter chaque jour fait monter la série.
Config.Streak = {
    Enabled   = true,
    Rewards   = { 500, 700, 900, 1200, 1500, 2000, 3500 },
    GraceDays = 1,                  -- jours d'absence tolérés avant de perdre la série (1 = on peut manquer UN jour)
}

-- ─────────────── Objectifs du jour ───────────────
Config.Daily = {
    Rewards  = { 400, 900, 1800 },  -- facile / moyen / difficile
    BonusAll = 1500,                -- bonus quand les 3 objectifs sont terminés
}

-- ─────────────── Objectif de la semaine ───────────────
Config.Weekly = { Reward = 6000 }

-- ─────────────── Défi de la ville (collectif) ───────────────
-- Chaque semaine, une activité est tirée au sort : toute la ville la fait avancer. Cible atteinte = bonus pour tout le monde
-- (économie : gains augmentés quelques heures, via pickax_economy) + une récompense à chaque participant (contribution minimale).
Config.Community = {
    Enabled = true,
    Reward  = 2500,
    Boost   = { swing = 0.15, hours = 3 },      -- +15 % de gains pendant 3 h (pickax_economy). swing = 0 : pas de bonus d'économie
    Challenges = {   -- cible : ce que la ville doit faire ; min : contribution minimale pour toucher la récompense
        { metric = 'job_task',  target = 400,  min = 5,  label = 'Effectuer {n} tâches de métier' },
        { metric = 'purchase',  target = 300,  min = 3,  label = 'Acheter {n} articles en boutique' },
        { metric = 'minigame',  target = 200,  min = 2,  label = 'Jouer {n} parties de mini-jeux' },
        { metric = 'distance',  target = 1500, min = 5,  label = 'Parcourir {n} km à travers la ville' },
        { metric = 'social',    target = 2500, min = 20, label = 'Passer {n} minutes ensemble (joueurs côte à côte)' },
    },
}

-- ─────────────── Catalogue des objectifs ───────────────
-- metric : ce qui fait avancer l'objectif · targets : cible facile / moyen / difficile · weekly : cible hebdomadaire (nil = pas proposé en hebdo)
-- needs : 'job' (avoir un métier) | 'gang' (être dans un gang) | nil (tout le monde)
-- Le jeu en choisit 3 par joueur et par jour (un de chaque difficulté, activités différentes) ; ça ne change pas si on se reconnecte.
Config.Goals = {
    { id = 'play',     metric = 'playtime', label = 'Jouer {n} minutes',                            targets = { 30, 60, 120 },        weekly = 600 },
    { id = 'walk',     metric = 'distance', label = 'Parcourir {n} km (à pied ou en véhicule)',     targets = { 3, 8, 20 },           weekly = 80 },
    { id = 'social',   metric = 'social',   label = 'Passer {n} min avec d\'autres joueurs',        targets = { 10, 25, 50 },         weekly = 240 },
    { id = 'visit',    metric = 'visit',    label = 'Visiter {n} lieux de la ville',                targets = { 2, 4, 7 } },
    { id = 'tasks',    metric = 'job_task', label = 'Effectuer {n} tâches de métier',               targets = { 3, 8, 15 },           weekly = 60,  needs = 'job' },
    { id = 'earn',     metric = 'earn',     label = 'Gagner {n} $ avec ton métier',                 targets = { 1500, 5000, 12000 }, weekly = 30000, needs = 'job' },
    { id = 'shop',     metric = 'purchase', label = 'Acheter {n} articles en boutique',             targets = { 2, 5, 10 },           weekly = 30 },
    { id = 'games',    metric = 'minigame', label = 'Jouer {n} parties de mini-jeux',               targets = { 1, 3, 6 },            weekly = 25 },
    { id = 'dealer',   metric = 'sell',     label = 'Vendre {n} marchandises illégales',            targets = { 5, 15, 40 },          weekly = 150, needs = 'gang' },
}

-- ─────────────── Lieux à visiter (objectif « Visiter des lieux ») ───────────────
Config.Places = {
    { id = 'legion',   label = 'Legion Square',      x = 195.0,   y = -934.0,  r = 60.0 },
    { id = 'vespucci', label = 'Plage de Vespucci',  x = -1330.0, y = -1530.0, r = 80.0 },
    { id = 'maze',     label = 'Maze Bank',          x = -75.0,   y = -818.0,  r = 50.0 },
    { id = 'vinewood', label = 'Vinewood Sign',      x = 710.0,   y = 1200.0,  r = 120.0 },
    { id = 'airport',  label = 'Aéroport de LS',     x = -1037.0, y = -2737.0, r = 150.0 },
    { id = 'port',     label = 'Port de Los Santos', x = 1000.0,  y = -3000.0, r = 150.0 },
    { id = 'sandy',    label = 'Sandy Shores',       x = 1850.0,  y = 3700.0,  r = 120.0 },
    { id = 'chiliad',  label = 'Mont Chiliad',       x = 450.0,   y = 5570.0,  r = 150.0 },
    { id = 'paleto',   label = 'Paleto Bay',         x = -120.0,  y = 6250.0,  r = 120.0 },
    { id = 'pier',     label = 'Jetée de Del Perro', x = -1850.0, y = -1230.0, r = 80.0 },
    { id = 'observ',   label = 'Observatoire',       x = -430.0,  y = 1100.0,  r = 120.0 },
    { id = 'prison',   label = 'Prison de Bolingbroke', x = 1700.0, y = 2600.0, r = 180.0 },
}
Config.PlaceCheckSeconds = 60       -- fréquence de la vérification serveur (temps de jeu, lieux, temps passé avec d'autres joueurs)

-- ─────────────── Temps passé ensemble ───────────────
Config.Social = { Distance = 20.0 }  -- deux joueurs à moins de X mètres comptent comme « ensemble »

-- ─────────────── Distance parcourue ───────────────
-- Mesurée côté client puis plafonnée côté serveur (anti-triche). Un saut de plus de MaxJump mètres en 5 s (téléportation) est ignoré.
Config.Distance = { MaxJump = 350.0, MaxPerReport = 1200.0 }
