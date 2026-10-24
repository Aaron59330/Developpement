Config = {}

-- ─────────────────────────────── Général ───────────────────────────────
Config.Account       = 'money'        -- compte crédité pour les missions : 'money' | 'bank'
Config.Interact      = 38             -- E
Config.AdminGroups   = { '_dev', 'admin', 'superadmin' }   -- qui peut placer les points (/ajpoint)
Config.DrawDistance  = 25.0
Config.InteractDistance = 2.0

-- Progression : chaque mission rapporte de l'XP ; le niveau augmente la paie et peut promouvoir au grade supérieur.
Config.XP = {
    PerLevel      = 150,              -- XP par niveau
    MaxLevel      = 20,
    PayPerLevel   = 3,                -- % de paie en plus par niveau
    Promotions    = { [5] = 1, [12] = 2 },   -- niveau → grade ESX (promotion automatique)
    VipPayBonus   = { [1] = 5, [2] = 10, [3] = 15 },   -- % de paie en plus selon le VIP (pickax_core)
}

-- ─────────────────────────────── Les métiers ───────────────────────────────
-- Chaque métier est créé tout seul dans la table `jobs` d'ESX au premier démarrage (grades et salaires modifiables ici).
-- Se recruter : PNJ du dépôt (touche E) → « Rejoindre ce métier ». Un admin peut aussi donner le job avec /setjob.
Config.Jobs = {
    garbage = {
        job = 'eboueur', label = 'Éboueur', icon = 'trash', ped = 's_m_y_garbage', blip = { sprite = 318, color = 25 },
        desc = 'Ramasse les poubelles de la ville et ramène-les au centre de tri. Chaque sac rapporte, la tournée complète donne une prime.',
        grades = { { name = 'recrue', label = 'Éboueur', salary = 90 }, { name = 'confirme', label = 'Éboueur confirmé', salary = 130 }, { name = 'chef', label = 'Chef d\'équipe', salary = 180 } },
        vehicle = 'trash', bags = { 8, 12 }, payPerBag = 45, bonus = 150, searchRadius = 90.0,
        zones = {
            { label = 'Davis', x = 100.0, y = -1700.0 }, { label = 'Strawberry', x = 250.0, y = -1400.0 }, { label = 'Rancho', x = 420.0, y = -1850.0 },
            { label = 'Mission Row', x = 380.0, y = -850.0 }, { label = 'Vinewood', x = 300.0, y = 200.0 }, { label = 'Mirror Park', x = 1050.0, y = -700.0 },
        },
    },
    towing = {
        job = 'depanneur', label = 'Dépanneur', icon = 'wrench', ped = 's_m_m_autoshop_01', blip = { sprite = 477, color = 47 },
        desc = 'Un automobiliste est en panne ? Charge sa voiture sur ta dépanneuse et dépose-la à la fourrière. Plus la distance est longue, plus tu gagnes.',
        grades = { { name = 'recrue', label = 'Dépanneur', salary = 110 }, { name = 'confirme', label = 'Dépanneur confirmé', salary = 150 }, { name = 'chef', label = 'Chef d\'atelier', salary = 200 } },
        vehicle = 'flatbed', payBase = 180, payPerKm = 90, searchRadius = 400.0, time = 1200,
        models = { 'blista', 'asea', 'premier', 'ingot', 'emperor', 'fugitive', 'sultan', 'felon', 'buffalo', 'ruiner' },
        zones = { { x = 250.0, y = -1000.0 }, { x = -600.0, y = -800.0 }, { x = 800.0, y = -1100.0 }, { x = 120.0, y = 600.0 }, { x = -1300.0, y = -400.0 }, { x = 1200.0, y = -500.0 } },
    },
    carwash = {
        job = 'laveurauto', label = 'Laveur auto', icon = 'drop', ped = 's_m_y_construct_02', blip = { sprite = 100, color = 3 },
        desc = 'Des clients arrivent avec des voitures sales : lave-les à la main, ils te paient et te laissent un pourboire selon leur état.',
        grades = { { name = 'recrue', label = 'Laveur', salary = 80 }, { name = 'confirme', label = 'Laveur confirmé', salary = 115 }, { name = 'chef', label = 'Responsable', salary = 160 } },
        payPerWash = 70, tipMax = 60, customers = 3, interval = 35, washSeconds = 14,
        models = { 'blista', 'asea', 'premier', 'ingot', 'emperor', 'fugitive', 'sultan', 'felon', 'prairie', 'primo' },
    },
    trucker = {
        job = 'camionneur', label = 'Camionneur', icon = 'truck', ped = 's_m_m_trucker_01', blip = { sprite = 477, color = 5 },
        desc = 'Récupère un semi-remorque au dépôt et livre ta cargaison dans une autre ville. Roule vite mais ne casse pas la marchandise.',
        grades = { { name = 'recrue', label = 'Chauffeur', salary = 130 }, { name = 'confirme', label = 'Chauffeur confirmé', salary = 175 }, { name = 'chef', label = 'Chef de convoi', salary = 230 } },
        truck = 'phantom', trailers = { 'trailers', 'trailers2', 'tanker', 'docktrailer' }, payBase = 250, payPerKm = 120, timePerKm = 75, returnBonus = 120,
    },
    farmer = {
        job = 'fermier', label = 'Fermier', icon = 'sprout', ped = 'a_m_m_farmer_01', blip = { sprite = 479, color = 2 },
        desc = 'Prépare ton champ : sème, arrose, laisse pousser puis récolte. Vends ta récolte au marché pour le meilleur prix.',
        grades = { { name = 'recrue', label = 'Ouvrier agricole', salary = 85 }, { name = 'confirme', label = 'Fermier', salary = 125 }, { name = 'chef', label = 'Exploitant', salary = 175 } },
        crops = {
            wheat = { label = 'Blé',    seedPrice = 6, seed = 'wheat_seed',  item = 'wheat',  grow = 12, yield = { 3, 5 }, price = 14, models = { 'prop_veg_crop_03_cab', 'prop_veg_crop_03_cab', 'prop_veg_crop_04' } },
            corn  = { label = 'Maïs',   seedPrice = 9, seed = 'corn_seed',   item = 'corn',   grow = 18, yield = { 3, 6 }, price = 20, models = { 'prop_veg_corn_01', 'prop_veg_corn_01', 'prop_veg_corn_01' } },
        },
        fieldRows = 3, fieldCols = 4, spacing = 3.2, waterFactor = 0.6, tractor = 'tractor2',
    },
    firefighter = {
        job = 'pompier', label = 'Pompier', icon = 'flame', ped = 's_m_y_fireman_01', blip = { sprite = 436, color = 1 },
        desc = 'Des incendies se déclarent dans la ville. Rends-toi sur place avec le camion, éteins les foyers avant qu\'ils ne se propagent.',
        grades = { { name = 'recrue', label = 'Sapeur', salary = 140 }, { name = 'confirme', label = 'Caporal', salary = 190 }, { name = 'chef', label = 'Capitaine', salary = 260 } },
        vehicle = 'firetruk', extinguisher = 'WEAPON_FIREEXTINGUISHER', interval = 420, minWorkers = 1, payPerFire = 60, bonus = 220, spread = 6.0, foyers = { 3, 6 }, timeLimit = 600,
        sites = {
            { label = 'Legion Square', x = 195.17, y = -933.77, z = 30.69 }, { label = 'Grove Street', x = 110.50, y = -1944.0, z = 20.80 },
            { label = 'Mission Row', x = 428.0, y = -984.0, z = 30.70 }, { label = 'Aéroport LSIA', x = -1037.5, y = -2737.8, z = 20.17 },
            { label = 'Del Perro', x = -1850.6, y = -1233.2, z = 13.02 }, { label = 'Maze Bank', x = -67.0, y = -801.0, z = 44.20 },
            { label = 'Downtown Cab', x = 909.0, y = -176.0, z = 74.20 }, { label = 'Sandy Shores', x = 1961.5, y = 3741.5, z = 32.34 },
        },
    },
    train = {
        job = 'conducteurtrain', label = 'Conducteur de train', icon = 'train', ped = 's_m_m_gentransport', blip = { sprite = 795, color = 38 },
        desc = 'Prends les commandes du métro : arrête-toi à chaque station, laisse monter les voyageurs puis repars. Ponctualité et arrêts précis = meilleure paie.',
        grades = { { name = 'recrue', label = 'Conducteur', salary = 150 }, { name = 'confirme', label = 'Conducteur confirmé', salary = 200 }, { name = 'chef', label = 'Chef de ligne', salary = 270 } },
        variation = 24, maxSpeed = 22.0, stopRadius = 28.0, stopSpeed = 1.5, dwell = 9, payPerStop = 80, bonusLine = 200,
    },
}
Config.JobOrder = { 'garbage', 'towing', 'carwash', 'trucker', 'farmer', 'firefighter', 'train' }

-- ─────────────────────────────── Points par défaut ───────────────────────────────
-- Ces positions sont des valeurs de départ (approximatives). Place les tiennes en jeu :
--   /ajpoint <métier> <type> [nom]   (admin) : ajoute un point à ta position ; dès qu'un type a au moins un point en base, il remplace les valeurs ci-dessous
--   /ajpoints <métier>               : liste les points      /ajdelpoint <id> : supprime un point
-- Types : depot (PNJ + menu), spawn (sortie du véhicule), scrap (fourrière : dépanneur), market (vente : fermier), field (centre du champ : fermier),
--         bay (baie de lavage), dest (destination : camionneur), fire (lieu d'incendie : pompier), station (arrêt, dans l'ordre : train)
Config.DefaultPoints = {
    garbage     = { depot = { { x = -321.7, y = -1545.9, z = 31.0, h = 270.0, label = 'Centre de tri' } } },
    towing      = { depot = { { x = 409.2, y = -1623.4, z = 29.3, h = 230.0, label = 'Garage de dépannage' } },
                    scrap = { { x = 401.0, y = -1631.0, z = 29.3, h = 320.0, label = 'Fourrière' } } },
    carwash     = { depot = { { x = 25.2, y = -1391.9, z = 29.3, h = 0.0, label = 'Lavage' } } },
    trucker     = { depot = { { x = -1037.5, y = -2737.8, z = 20.17, h = 330.0, label = 'Dépôt de transport' } },
                    dest  = { { x = 1961.5, y = 3741.5, z = 32.34, h = 300.0, label = 'Sandy Shores' }, { x = 549.0, y = 2671.0, z = 42.2, h = 100.0, label = 'Harmony' },
                              { x = 1698.0, y = 4924.0, z = 42.1, h = 320.0, label = 'Grapeseed' }, { x = -102.0, y = 6467.0, z = 31.6, h = 45.0, label = 'Paleto Bay' },
                              { x = -3040.0, y = 585.0, z = 7.9, h = 20.0, label = 'Chumash' } } },
    farmer      = { depot = { { x = 1698.0, y = 4924.0, z = 42.1, h = 320.0, label = 'Ferme' } },
                    field = { { x = 1725.0, y = 4950.0, z = 42.0, h = 0.0, label = 'Champ' } },
                    market = { { x = 1690.0, y = 4930.0, z = 42.1, h = 140.0, label = 'Marché' } } },
    firefighter = { depot = { { x = 199.8, y = -1642.6, z = 29.8, h = 230.0, label = 'Caserne de pompiers' } } },
    train       = { depot = { { x = 298.6, y = -584.4, z = 43.26, h = 70.0, label = 'Bureau du métro' } } },
}
-- Arrêts du métro (ordre de la ligne) : positions à vérifier / remplacer avec /ajpoint train station <nom> en te plaçant sur le quai.
Config.TrainStations = {
    { label = 'LSIA Terminal', x = -1095.0, y = -2714.0, z = -7.4 }, { label = 'LSIA Parking', x = -890.0, y = -2326.0, z = -11.7 },
    { label = 'Puerto del Sol', x = -537.0, y = -1286.0, z = 26.9 }, { label = 'Pillbox Hill', x = -214.0, y = -1031.0, z = 30.1 },
    { label = 'Strawberry', x = 270.0, y = -1209.0, z = 38.9 }, { label = 'Davis', x = 112.0, y = -1730.0, z = 30.1 },
}
