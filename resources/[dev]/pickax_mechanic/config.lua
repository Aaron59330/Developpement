Config = {}

-- ═════════════════════════════ MÉCANICIEN RÉALISTE ═════════════════════════════
Config.Enabled = true
Config.UseCommands = false  -- true = active aussi /meca (par défaut : menu contextuel sur le véhicule et action « Réparer le véhicule » du menu F6)

-- Qui est mécanicien : noms de jobs ESX ET / OU type de job du Job Builder (« mecano »)
Config.Jobs     = { 'mechanic', 'mecano' }
Config.JobTypes = { 'mecano' }
Config.Command  = 'meca'          -- /meca : ouvre le diagnostic du véhicule le plus proche (aussi appelé par l'action « Réparer le véhicule » du Job Builder)
Config.MaxDistance = 5.0           -- distance maximale mécano ↔ véhicule
Config.Tool     = 'toolbox'       -- item exigé pour toute réparation (non consommé) ; vide = aucun outil requis

-- Atelier obligatoire ? false = on peut réparer n'importe où (dépanneuse) ; true = seulement dans un rayon d'un point de Config.Workshops
Config.RequireWorkshop = false
Config.Workshops = {
    -- { label = 'Atelier de Strawberry', coords = vector3(-347.0, -133.0, 39.0), radius = 25.0 },
}

-- ═════════════════════════════ MAGASIN DE PIÈCES (stock limité) ═════════════════════════════
-- Les mécaniciens DOIVENT venir acheter leurs pièces ici : sans pièce en inventaire, aucune réparation. Le stock est partagé par tous les mécaniciens
-- du serveur et se reconstitue lentement (livraisons) : s'il est vide, il faut attendre ou aller plus loin.
Config.Shops = {
    { label = 'Pièces détachées Los Santos', coords = vector3(-1171.2, -1767.9, 3.9), blip = true, ped = 's_m_y_garbage', pedHeading = 120.0 },
}
Config.Shop = {
    Account       = 'bank',           -- compte débité : 'bank' | 'money'
    Distance      = 2.0,
    MaxPerOrder   = 10,
    Parts = {   -- item (à avoir dans ox_inventory/data/items.lua), prix unitaire, stock maximum, réassort : `amount` pièces toutes les `every` minutes
        { item = 'engine_block',   label = 'Bloc moteur',           price = 2400, max = 6,  every = 45, amount = 1 },
        { item = 'spark_plugs',    label = 'Bougies d\'allumage',   price = 90,   max = 24, every = 15, amount = 4 },
        { item = 'engine_oil',     label = 'Huile moteur',          price = 60,   max = 30, every = 10, amount = 5 },
        { item = 'oil_filter',     label = 'Filtre à huile',        price = 45,   max = 30, every = 10, amount = 5 },
        { item = 'gearbox_kit',    label = 'Kit de boîte de vitesses', price = 1800, max = 5, every = 60, amount = 1 },
        { item = 'brake_pads',     label = 'Plaquettes de frein',   price = 220,  max = 16, every = 20, amount = 2 },
        { item = 'brake_fluid',    label = 'Liquide de frein',      price = 35,   max = 20, every = 15, amount = 4 },
        { item = 'tyre_set',       label = 'Jeu de pneus',          price = 640,  max = 8,  every = 30, amount = 1 },
        { item = 'suspension_kit', label = 'Kit de suspension',     price = 1100, max = 6,  every = 40, amount = 1 },
        { item = 'body_panel',     label = 'Panneau de carrosserie', price = 380, max = 14, every = 25, amount = 2 },
        { item = 'welding_wire',   label = 'Fil à souder',          price = 50,   max = 20, every = 15, amount = 4 },
        { item = 'toolbox',        label = 'Caisse à outils',       price = 350,  max = 10, every = 60, amount = 1 },
    },
}

-- ═════════════════════════════ ÉTAT DU VÉHICULE ═════════════════════════════
-- Chaque véhicule (par plaque) a un état par composant (0-100 %), enregistré en base. Le moteur et la carrosserie tiennent aussi compte des dégâts réels subis.
Config.Components = {
    engine       = { label = 'Moteur',           icon = '⚙' },
    oil          = { label = 'Huile / filtres',  icon = '🛢' },
    transmission = { label = 'Boîte de vitesses', icon = '⛓' },
    brakes       = { label = 'Freins',           icon = '◉' },
    tires        = { label = 'Pneus',            icon = '◯' },
    suspension   = { label = 'Suspension',       icon = '≋' },
    body         = { label = 'Carrosserie',      icon = '▭' },
}
Config.ComponentOrder = { 'engine', 'oil', 'transmission', 'brakes', 'tires', 'suspension', 'body' }

-- Usure pour 1 km parcouru (en %). Elle augmente avec la vitesse élevée (× SpeedFactor au-delà de 120 km/h) et les freinages brusques.
Config.Wear = {
    PerKm = { engine = 0.35, oil = 0.8, transmission = 0.18, brakes = 0.45, tires = 0.6, suspension = 0.2 },
    SpeedFactor   = 1.6,
    HardBrakeCost = { brakes = 0.25, tires = 0.15 },     -- par freinage brusque signalé
    ImpactCost    = { suspension = 4.0, body = 0 },      -- par choc violent (la carrosserie suit les dégâts natifs)
    ReportEvery   = 30,                                    -- secondes entre deux rapports du conducteur
    MaxSpeed      = 95.0,                                  -- m/s : au-delà le rapport est rejeté (anti-triche)
}

-- Effets d'un mauvais état (appliqués au conducteur) : seuils en %
Config.Effects = {
    EngineStall     = 25,        -- moteur sous ce seuil : calages aléatoires
    EnginePower     = 60,        -- sous ce seuil la puissance baisse (jusqu'à -45 % à 0 %)
    BrakeWeak       = 45,        -- sous ce seuil : freinage affaibli
    TyreBurst       = 18,        -- pneus sous ce seuil : éclatement possible à haute vitesse
    TyreGrip        = 50,        -- sous ce seuil : adhérence réduite
    TransmissionBad = 30,        -- boîte : à-coups et perte de couple
    SuspensionBad   = 30,        -- suspension : instabilité (adhérence en virage)
}

-- ═════════════════════════════ RÉPARATIONS ═════════════════════════════
-- Pour chaque composant : pièces consommées (en inventaire), mini-jeu, gain maximal (en %), durée minimale (s), animation.
-- Mini-jeux : bolts (serrage des boulons), timing (arrêt sur la zone), inflate (gonflage), dents (débosselage).
Config.Repairs = {
    engine       = { parts = { { 'engine_block', 1 }, { 'spark_plugs', 4 } }, game = 'bolts',   seed = 6, seconds = 40, gain = 100, label = 'Remplacer le moteur' },
    oil          = { parts = { { 'engine_oil', 2 }, { 'oil_filter', 1 } },     game = 'timing',  rounds = 2, seconds = 25, gain = 100, label = 'Vidange et filtres' },
    transmission = { parts = { { 'gearbox_kit', 1 } },                         game = 'bolts',   seed = 8, seconds = 45, gain = 100, label = 'Remplacer la boîte' },
    brakes       = { parts = { { 'brake_pads', 2 }, { 'brake_fluid', 1 } },    game = 'timing',  rounds = 3, seconds = 28, gain = 100, label = 'Changer plaquettes et liquide' },
    tires        = { parts = { { 'tyre_set', 1 } },                            game = 'inflate', rounds = 4, seconds = 40, gain = 100, label = 'Changer les pneus' },
    suspension   = { parts = { { 'suspension_kit', 1 } },                      game = 'bolts',   seed = 6, seconds = 35, gain = 100, label = 'Remplacer les amortisseurs' },
    body         = { parts = { { 'body_panel', 2 }, { 'welding_wire', 1 } },   game = 'dents',   seed = 8, seconds = 40, gain = 100, label = 'Débosseler et souder' },
}
Config.MinSeconds   = 8            -- durée minimale d'une réparation côté serveur (anti-triche)
Config.FailBelow    = 35           -- score (%) sous lequel la réparation est ratée : pièces perdues, rien n'est réparé
Config.QualityFloor = 0.5          -- un score juste suffisant répare ce coefficient du gain ; 100 % = gain complet

-- État initial d'un véhicule jamais vu (% tirés au hasard entre ces bornes) : un véhicule d'occasion n'est pas neuf
Config.Initial = { min = 70, max = 100 }
