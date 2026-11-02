Config = {}
Config.Enabled = true

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
-- Poste de cuisine (E) : choisis une recette ; le mini-jeu de cuisson fixe la qualité du plat (métadonnée). Un plat raté est brûlé.
Config.Cooking = {
    Stations = { { label = 'Cuisine du Burger Shot', coords = vector3(-1196.0, -896.0, 13.9) }, { label = 'Cuisine du bar de plage', coords = vector3(-1393.0, -604.0, 30.3) } },
    Distance = 1.6,
    Min = 40,
    Burnt = 'burnt_food',
    Recipes = {
        { id = 'grilled_fish', label = 'Poisson grillé', needs = { { 'fish_carp', 1 }, { 'cooking_oil', 1 } }, out = 'dish_fish', seconds = 22, speed = 1.0 },
        { id = 'venison',      label = 'Ragoût de cerf', needs = { { 'meat_deer', 2 }, { 'cooking_oil', 1 } }, out = 'dish_venison', seconds = 26, speed = 1.2 },
        { id = 'sandwich',     label = 'Sandwich',       needs = { { 'bread', 1 }, { 'meat_boar', 1 } }, out = 'dish_sandwich', seconds = 18, speed = 0.9 },
    },
}

-- ═════════════════════════════ TAXI & LIVRAISON ═════════════════════════════
-- /course : démarre / arrête une série de courses. La rémunération et le pourboire dépendent de la distance, du temps et de la conduite (chocs, freinages).
Config.Runs = {
    Command = 'course',
    Jobs = { taxi = { 'taxi' }, delivery = { 'delivery', 'livreur', 'trucker' } },     -- noms de jobs ESX autorisés par type de course
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
