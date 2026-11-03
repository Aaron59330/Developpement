Config = {}
Config.Enabled = true
Config.UseCommands = false   -- true = active aussi /pecher, /depecer, /course (par défaut : objets (canne, couteau), menu contextuel sur la dépouille, menu F6 du job pour les courses)

-- ═════════════════════════════ PERMIS (pêche, chasse) ═════════════════════════════
-- Achetés au bureau : item remis au joueur. Sans permis, une activité est refusée.
Config.Licenses = {
    Office = { label = 'Bureau des permis', coords = vector3(-266.8, -963.6, 31.2), ped = 'a_f_y_business_01', pedHeading = 205.0, Distance = 2.0 },
    List = { { item = 'fishing_license', label = 'Permis de pêche', price = 250 }, { item = 'hunting_license', label = 'Permis de chasse', price = 600 } },
    Account = 'bank',
}

-- ═════════════════════════════ PÊCHE ═════════════════════════════
-- /pecher dans une zone de pêche. Le serveur tire l'espèce ; le mini-jeu « garde la jauge sur le poisson » décide de la prise.
Config.Fishing = {
    Command = 'pecher',
    Rod = 'fishing_rod', License = 'fishing_license', Bait = 'fishing_bait',     -- appât facultatif (consommé) : augmente la chance de belles prises. Bait = '' pour désactiver
    QuotaPerHour = 25,
    Min = 60,
    Spots = { { label = 'Jetée de Del Perro', coords = vector3(-1850.0, -1250.0, 8.6), radius = 40.0 }, { label = 'Lac d\'Alamo', coords = vector3(1310.0, 4220.0, 33.9), radius = 60.0 } },
    -- weight = chance relative ; difficulty : 1 facile … 4 très dur ; price = revente
    Fish = {
        { item = 'fish_sardine', label = 'Sardine', weight = 40, difficulty = 1, price = 18 },
        { item = 'fish_carp',    label = 'Carpe',   weight = 30, difficulty = 2, price = 45 },
        { item = 'fish_bass',    label = 'Bar',     weight = 18, difficulty = 3, price = 90 },
        { item = 'fish_tuna',    label = 'Thon',    weight = 9,  difficulty = 4, price = 210 },
        { item = 'fish_sword',   label = 'Espadon', weight = 3,  difficulty = 4, price = 480 },
    },
    BaitBoost = 1.6,             -- multiplicateur de chance des espèces difficiles avec appât
}

-- ═════════════════════════════ CHASSE ═════════════════════════════
-- Abats un animal dans une zone de chasse puis /depecer à côté de sa dépouille (couteau + permis) : mini-jeu de précision, viande et peau.
Config.Hunting = {
    Command = 'depecer',
    Knife = 'hunting_knife', License = 'hunting_license',
    QuotaPerHour = 12,
    Min = 55,
    Zones = { { label = 'Forêt de Chiliad', coords = vector3(-1200.0, 4750.0, 220.0), radius = 700.0 } },
    Animals = {
        [`a_c_deer`] = { label = 'Cerf', meat = 'meat_deer', skin = 'leather_deer', meatMax = 4, difficulty = 2 },
        [`a_c_boar`] = { label = 'Sanglier', meat = 'meat_boar', skin = 'leather_boar', meatMax = 3, difficulty = 2 },
        [`a_c_rabbit_01`] = { label = 'Lapin', meat = 'meat_rabbit', skin = nil, meatMax = 1, difficulty = 1 },
    },
}

-- ═════════════════════════════ ACHETEURS (pêche / chasse / cuisine) ═════════════════════════════
-- Les prix varient chaque jour (±Fluctuation %). Les acheteurs paient en espèces.
Config.Buyers = {
    { label = 'Poissonnerie du port', coords = vector3(-1037.5, -1396.0, 5.5), ped = 's_m_m_chemsec_01', pedHeading = 80.0, Account = 'money', Distance = 2.0, Fluctuation = 15,
      Items = { fish_sardine = 18, fish_carp = 45, fish_bass = 90, fish_tuna = 210, fish_sword = 480 } },
    { label = 'Boucherie / tannerie', coords = vector3(-1304.0, -1220.0, 4.6), ped = 's_m_m_chemsec_01', pedHeading = 270.0, Account = 'money', Distance = 2.0, Fluctuation = 15,
      Items = { meat_deer = 60, meat_boar = 45, meat_rabbit = 22, leather_deer = 85, leather_boar = 70 } },
}

-- ═════════════════════════════ CUISINE ═════════════════════════════
-- Vrai système de cuisine : ingrédients achetés au marché, recettes en plusieurs étapes (préparation → cuisson → finition) avec mini-jeux,
-- niveau de cuisinier (XP, recettes débloquées par niveau), qualité du plat (métadonnée), plats brûlés si raté, commandes de clients (paiement + bonus qualité).
Config.Cooking = {
    Distance = 1.6,
    Min = 40,                                  -- note minimale de l'étape de cuisson : en dessous, le plat est brûlé
    Burnt = 'burnt_food',
    -- Postes : type = 'prep' (plan de travail), 'stove' (cuisinière / friteuse), 'grill' (grill / barbecue), 'oven' (four)
    Stations = {
        { label = 'Cuisine du Burger Shot : plan de travail', type = 'prep',  coords = vector3(-1196.0, -896.0, 13.9) },
        { label = 'Cuisine du Burger Shot : grill',            type = 'grill', coords = vector3(-1198.4, -895.2, 13.9) },
        { label = 'Cuisine du Burger Shot : cuisinière',       type = 'stove', coords = vector3(-1194.0, -897.5, 13.9) },
        { label = 'Cuisine du bar de plage : tout-en-un',      type = 'all',   coords = vector3(-1393.0, -604.0, 30.3) },
    },
    StationLabel = { prep = 'Plan de travail', stove = 'Cuisinière', grill = 'Grill', oven = 'Four', all = 'Poste complet' },
    -- Niveau de cuisinier : XP cumulée nécessaire pour chaque niveau (le 1er commence à 0)
    Levels = { 0, 80, 220, 450, 800, 1300 },
    XP = { Dish = 14, Perfect = 8, Burnt = 3, Order = 10 },   -- XP par plat réussi / bonus qualité ≥ 90 / plat raté / commande livrée
    QualityBonusPerLevel = 2,                  -- points de qualité ajoutés par niveau de cuisinier
    -- Marché aux ingrédients (E)
    Market = {
        label = 'Marché aux ingrédients', coords = vector3(-1180.0, -887.0, 13.8), ped = 's_m_m_chemsec_01', pedHeading = 120.0, Distance = 2.0, Account = 'money',
        Items = { flour = 6, egg = 4, butter = 8, tomato = 5, lettuce = 5, cheese = 9, potato = 4, rice = 6, onion = 3, sugar = 5, pasta = 7, meat_beef = 22, chicken_raw = 18, cooking_oil = 10, bread = 4 },
    },
    -- Commandes de clients : une carte de commandes se renouvelle ; livre le plat demandé (qualité minimale) pour être payé
    Orders = { Enabled = true, Count = 4, RefreshMinutes = 40, PayMult = 1.7, MinQuality = 55, QualityBonus = 0.6, Account = 'money' },
    -- Étapes : game = 'timing' (découpe / assaisonnement précis), 'hold' (cuisson : garde la bonne température)
    Recipes = {
        { id = 'salad',    label = 'Salade composée', level = 1, station = 'prep',  needs = { { 'lettuce', 1 }, { 'tomato', 1 }, { 'cooking_oil', 1 } }, out = 'dish_salad',
          steps = { { game = 'timing', title = 'Découpe', sub = 'Coupe les légumes en rythme', rounds = 3 } }, value = 40 },
        { id = 'sandwich', label = 'Sandwich',        level = 1, station = 'prep',  needs = { { 'bread', 1 }, { 'meat_boar', 1 } }, out = 'dish_sandwich',
          steps = { { game = 'timing', title = 'Montage', sub = 'Tranche et assemble', rounds = 3 } }, value = 45 },
        { id = 'omelet',   label = 'Omelette au fromage', level = 1, station = 'stove', needs = { { 'egg', 2 }, { 'butter', 1 }, { 'cheese', 1 } }, out = 'dish_omelet',
          steps = { { game = 'timing', title = 'Battre les œufs', sub = 'Sois régulier', rounds = 2 }, { game = 'hold', title = 'Cuisson', sub = 'Feu doux', seconds = 16, size = 0.3, speed = 0.9 } }, value = 55 },
        { id = 'fries',    label = 'Frites maison',   level = 1, station = 'stove', needs = { { 'potato', 2 }, { 'cooking_oil', 1 } }, out = 'dish_fries',
          steps = { { game = 'timing', title = 'Éplucher et couper', sub = 'Coupe nette', rounds = 3 }, { game = 'hold', title = 'Friteuse', sub = 'Ni trop, ni trop peu', seconds = 16, size = 0.28, speed = 1.0 } }, value = 50 },
        { id = 'grilled_fish', label = 'Poisson grillé', level = 2, station = 'grill', needs = { { 'fish_carp', 1 }, { 'cooking_oil', 1 } }, out = 'dish_fish',
          steps = { { game = 'hold', title = 'Cuisson', sub = 'Garde la bonne température', seconds = 22, size = 0.26, speed = 1.0 } }, value = 70 },
        { id = 'burger',   label = 'Burger maison',  level = 2, station = 'grill', needs = { { 'bread', 1 }, { 'meat_beef', 1 }, { 'cheese', 1 }, { 'lettuce', 1 } }, out = 'dish_burger',
          steps = { { game = 'hold', title = 'Cuisson du steak', sub = 'À point', seconds = 20, size = 0.26, speed = 1.1 }, { game = 'timing', title = 'Montage', sub = 'Assemble vite', rounds = 3 } }, value = 85 },
        { id = 'steak',    label = 'Steak-frites',   level = 2, station = 'grill', needs = { { 'meat_beef', 1 }, { 'potato', 1 }, { 'butter', 1 } }, out = 'dish_steak',
          steps = { { game = 'hold', title = 'Cuisson du steak', sub = 'Saignant, à point ou bien cuit ?', seconds = 22, size = 0.24, speed = 1.15 }, { game = 'timing', title = 'Dressage', sub = 'Soigne l\'assiette', rounds = 2 } }, value = 110 },
        { id = 'pasta',    label = 'Pâtes à la tomate', level = 3, station = 'stove', needs = { { 'pasta', 1 }, { 'tomato', 2 }, { 'onion', 1 } }, out = 'dish_pasta',
          steps = { { game = 'timing', title = 'Sauce', sub = 'Émince et mélange', rounds = 3 }, { game = 'hold', title = 'Cuisson', sub = 'Al dente', seconds = 20, size = 0.25, speed = 1.1 } }, value = 95 },
        { id = 'venison',  label = 'Ragoût de cerf', level = 3, station = 'stove', needs = { { 'meat_deer', 2 }, { 'cooking_oil', 1 }, { 'onion', 1 } }, out = 'dish_venison',
          steps = { { game = 'timing', title = 'Découpe', sub = 'Taille les morceaux', rounds = 3 }, { game = 'hold', title = 'Mijotage', sub = 'Longtemps, à feu doux', seconds = 26, size = 0.26, speed = 1.2 } }, value = 130 },
        { id = 'rice',     label = 'Riz au poulet',  level = 4, station = 'stove', needs = { { 'rice', 1 }, { 'chicken_raw', 1 }, { 'onion', 1 }, { 'cooking_oil', 1 } }, out = 'dish_rice',
          steps = { { game = 'timing', title = 'Découpe', sub = 'Poulet et oignon', rounds = 3 }, { game = 'hold', title = 'Cuisson', sub = 'Tout en même temps', seconds = 24, size = 0.24, speed = 1.2 } }, value = 120 },
        { id = 'pizza',    label = 'Pizza',          level = 4, station = 'oven', needs = { { 'flour', 2 }, { 'tomato', 2 }, { 'cheese', 2 } }, out = 'dish_pizza',
          steps = { { game = 'timing', title = 'Pétrir la pâte', sub = 'Garde le rythme', rounds = 4 }, { game = 'timing', title = 'Garniture', sub = 'Répartis bien', rounds = 3 }, { game = 'hold', title = 'Four', sub = 'Surveille la cuisson', seconds = 22, size = 0.24, speed = 1.2 } }, value = 150 },
        { id = 'cake',     label = 'Gâteau maison',  level = 5, station = 'oven', needs = { { 'flour', 2 }, { 'egg', 2 }, { 'butter', 1 }, { 'sugar', 1 } }, out = 'dish_cake',
          steps = { { game = 'timing', title = 'Mélanger', sub = 'Sans grumeaux', rounds = 4 }, { game = 'hold', title = 'Four', sub = 'Température exacte', seconds = 26, size = 0.2, speed = 1.3 } }, value = 160 },
    },
}

-- ═════════════════════════════ TAXI & LIVRAISON ═════════════════════════════
-- /course : démarre / arrête une série de courses. La rémunération et le pourboire dépendent de la distance, du temps et de la conduite (chocs, freinages).
Config.Runs = {
    Command = 'course',
    Jobs = { taxi = { 'taxi' }, delivery = { 'delivery', 'livreur', 'trucker' } },     -- noms de jobs ESX autorisés par type de course
    JobTypes = { taxi = { 'taxi' }, delivery = { 'trucker' } },                         -- types de job du Job Builder autorisés
    Rate = { taxi = 2.2, delivery = 1.8 },                                              -- $ par 100 m (hors pourboire)
    Base = { taxi = 60, delivery = 80 },
    TipMax = 0.4,                                                                       -- pourboire maximal (% du tarif) pour une conduite parfaite
    StopRadius = 14.0, MaxArriveSpeed = 8.0,
    Min = { taxi = 350.0, delivery = 300.0 },                                           -- distance minimale (m) entre deux points
    Account = 'money',
    DepotDelivery = vector3(1197.0, -3253.0, 5.5),                                      -- point de départ des livraisons (entrepôt)
    Locations = {
        vector3(-47.0, -1757.0, 29.4), vector3(-1037.0, -2733.0, 20.1), vector3(317.0, -1076.0, 29.4), vector3(-621.0, -231.0, 37.9), vector3(1135.0, -982.0, 46.2),
        vector3(-1305.0, -394.0, 36.7), vector3(-709.0, -153.0, 37.4), vector3(374.0, 2634.0, 44.5), vector3(1693.0, 3760.0, 34.7), vector3(-1693.0, -1043.0, 13.0),
    },
}
