Config.Act = {}

-- ─────────────────────────────── Général ───────────────────────────────
Config.Act.Account       = 'money'        -- compte crédité pour les missions : 'money' | 'bank'
Config.Act.Interact      = 38             -- E
Config.Act.AdminGroups   = { '_dev', 'admin', 'superadmin' }   -- qui peut déclencher /ajfire (test des incendies)
Config.Act.DrawDistance  = 25.0
Config.Act.InteractDistance = 2.0

-- Progression : chaque mission rapporte de l'XP ; le niveau augmente la paie et peut promouvoir au grade supérieur.
Config.Act.XP = {
    PerLevel      = 150,              -- XP par niveau
    MaxLevel      = 20,
    PayPerLevel   = 3,                -- % de paie en plus par niveau
    Promotions    = { [5] = 1, [12] = 2 },   -- niveau → grade ESX (promotion automatique)
    VipPayBonus   = { [1] = 5, [2] = 10, [3] = 15 },   -- % de paie en plus selon le VIP (pickax_core)
}

-- Titres affichés selon le niveau (le plus haut niveau atteint s'applique)
Config.Act.XP.Titles = { [1] = 'Débutant', [3] = 'Apprenti', [5] = 'Confirmé', [8] = 'Professionnel', [12] = 'Expert', [16] = 'Maître', [20] = 'Légende' }

-- ─────────────────────────────── Succès ───────────────────────────────
-- job = clé du métier actif (garbage, towing, carwash, trucker, farmer, firefighter, train) ou '*' (tous métiers confondus)
-- stat : 'done' (missions) · 'earned' (argent gagné) · 'level' (niveau du métier) ; pour '*' : 'done' · 'earned' · 'jobs' (métiers essayés) · 'levels' (métiers au niveau `level` ou plus)
-- reward : money (versé sur Config.Act.Account) · xp (ajouté au métier, ignoré pour '*')
Config.Act.Achievements = {
    { id = 'first_mission', job = '*', stat = 'done',   target = 1,      label = 'Premier pas',          desc = 'Termine ta toute première mission',                 reward = { money = 150 } },
    { id = 'ten_missions',  job = '*', stat = 'done',   target = 25,     label = 'Bosseur',              desc = 'Termine 25 missions, tous métiers confondus',       reward = { money = 500 } },
    { id = 'hundred',       job = '*', stat = 'done',   target = 150,    label = 'Infatigable',          desc = 'Termine 150 missions, tous métiers confondus',      reward = { money = 2500 } },
    { id = 'rich',          job = '*', stat = 'earned', target = 50000,  label = 'Argent honnête',       desc = 'Gagne 50 000 $ avec les métiers actifs',            reward = { money = 1500 } },
    { id = 'tycoon',        job = '*', stat = 'earned', target = 250000, label = 'Magnat du travail',    desc = 'Gagne 250 000 $ avec les métiers actifs',           reward = { money = 7500 } },
    { id = 'tryall',        job = '*', stat = 'jobs',   target = 4,      label = 'Touche-à-tout',        desc = 'Essaie 4 métiers actifs différents',                reward = { money = 1000 } },
    { id = 'polyvalent',    job = '*', stat = 'levels', target = 3, level = 5, label = 'Polyvalent',     desc = 'Atteins le niveau 5 dans 3 métiers',                reward = { money = 3000 } },
}
-- Succès propres à chaque métier (générés : missions 10 / 50 / 200 et niveaux 5 / 10 / 20)
do
    local tiers = { { 10, 'Novice', 300 }, { 50, 'Habitué', 1200 }, { 200, 'Vétéran', 5000 } }
    local lvls  = { { 5, 'Confirmé', 400 }, { 10, 'Expert', 1500 }, { 20, 'Légende', 6000 } }
    local names = { garbage = 'des poubelles', towing = 'du dépannage', carwash = 'du lavage', trucker = 'du camion', farmer = 'de la ferme', firefighter = 'du feu', train = 'du rail' }
    for key, nm in pairs(names) do
        for _, t in ipairs(tiers) do
            Config.Act.Achievements[#Config.Act.Achievements + 1] = { id = key .. '_done_' .. t[1], job = key, stat = 'done', target = t[1],
                label = t[2] .. ' ' .. nm, desc = ('Termine %d missions'):format(t[1]), reward = { money = t[3], xp = t[1] } }
        end
        for _, l in ipairs(lvls) do
            Config.Act.Achievements[#Config.Act.Achievements + 1] = { id = key .. '_lvl_' .. l[1], job = key, stat = 'level', target = l[1],
                label = l[2] .. ' ' .. nm, desc = ('Atteins le niveau %d'):format(l[1]), reward = { money = l[3] } }
        end
    end
end

-- ─────────────────────────────── Les métiers ───────────────────────────────
-- Les métiers se CRÉENT DANS LE JOB BUILDER (/jobbuilder → nouveau job → type Éboueur, Dépanneur, Laveur auto, Camionneur, Fermier, Pompier ou
-- Conducteur de train) : grades, salaires, société, vestiaire, coffre, boss, service (F6). Ici : seulement le gameplay de chaque activité.
-- Dans le Job Builder, place un « Poste d'activité » (là où l'on démarre) puis des « Points d'activité » (zones, destinations, baies, champ, marché…).
Config.Act.Jobs = {
    garbage = {
        label = 'Éboueur', icon = 'trash',
        desc = 'Ramasse les poubelles de la ville et ramène-les au centre de tri. Chaque sac rapporte, la tournée complète donne une prime.',
        vehicle = 'trash', bags = { 8, 12 }, payPerBag = 45, bonus = 150, searchRadius = 90.0,
        zones = {
            { label = 'Davis', x = 100.0, y = -1700.0 }, { label = 'Strawberry', x = 250.0, y = -1400.0 }, { label = 'Rancho', x = 420.0, y = -1850.0 },
            { label = 'Mission Row', x = 380.0, y = -850.0 }, { label = 'Vinewood', x = 300.0, y = 200.0 }, { label = 'Mirror Park', x = 1050.0, y = -700.0 },
        },
    },
    towing = {
        label = 'Dépanneur', icon = 'wrench',
        desc = 'Un automobiliste est en panne ? Charge sa voiture sur ta dépanneuse et dépose-la à la fourrière. Plus la distance est longue, plus tu gagnes.',
        vehicle = 'flatbed', payBase = 180, payPerKm = 90, searchRadius = 400.0, time = 1200,
        models = { 'blista', 'asea', 'premier', 'ingot', 'emperor', 'fugitive', 'sultan', 'felon', 'buffalo', 'ruiner' },
        zones = { { x = 250.0, y = -1000.0 }, { x = -600.0, y = -800.0 }, { x = 800.0, y = -1100.0 }, { x = 120.0, y = 600.0 }, { x = -1300.0, y = -400.0 }, { x = 1200.0, y = -500.0 } },
    },
    carwash = {
        label = 'Laveur auto', icon = 'drop',
        desc = 'Des clients arrivent avec des voitures sales : lave-les à la main, ils te paient et te laissent un pourboire selon leur état.',
        payPerWash = 70, tipMax = 60, customers = 3, interval = 35, washSeconds = 14,
        models = { 'blista', 'asea', 'premier', 'ingot', 'emperor', 'fugitive', 'sultan', 'felon', 'prairie', 'primo' },
    },
    trucker = {
        label = 'Camionneur', icon = 'truck',
        desc = 'Récupère un semi-remorque au dépôt et livre ta cargaison dans une autre ville. Roule vite mais ne casse pas la marchandise.',
        truck = 'phantom', trailers = { 'trailers', 'trailers2', 'tanker', 'docktrailer' }, payBase = 250, payPerKm = 120, timePerKm = 75, returnBonus = 120,
    },
    farmer = {
        label = 'Fermier', icon = 'sprout',
        desc = 'Prépare ton champ : sème, arrose, laisse pousser puis récolte. Vends ta récolte au marché pour le meilleur prix.',
        crops = {
            wheat = { label = 'Blé',    seedPrice = 6, seed = 'wheat_seed',  item = 'wheat',  grow = 12, yield = { 3, 5 }, price = 14, models = { 'prop_veg_crop_03_cab', 'prop_veg_crop_03_cab', 'prop_veg_crop_04' } },
            corn  = { label = 'Maïs',   seedPrice = 9, seed = 'corn_seed',   item = 'corn',   grow = 18, yield = { 3, 6 }, price = 20, models = { 'prop_veg_corn_01', 'prop_veg_corn_01', 'prop_veg_corn_01' } },
        },
        fieldRows = 3, fieldCols = 4, spacing = 3.2, waterFactor = 0.6, tractor = 'tractor2',
    },
    firefighter = {
        label = 'Pompier', icon = 'flame',
        desc = 'Des incendies se déclarent dans la ville. Rends-toi sur place avec le camion, éteins les foyers avant qu\'ils ne se propagent.',
        vehicle = 'firetruk', extinguisher = 'WEAPON_FIREEXTINGUISHER', interval = 420, minWorkers = 1, payPerFire = 60, bonus = 220, spread = 6.0, foyers = { 3, 6 }, timeLimit = 600,
        sites = {
            { label = 'Legion Square', x = 195.17, y = -933.77, z = 30.69 }, { label = 'Grove Street', x = 110.50, y = -1944.0, z = 20.80 },
            { label = 'Mission Row', x = 428.0, y = -984.0, z = 30.70 }, { label = 'Aéroport LSIA', x = -1037.5, y = -2737.8, z = 20.17 },
            { label = 'Del Perro', x = -1850.6, y = -1233.2, z = 13.02 }, { label = 'Maze Bank', x = -67.0, y = -801.0, z = 44.20 },
            { label = 'Downtown Cab', x = 909.0, y = -176.0, z = 74.20 }, { label = 'Sandy Shores', x = 1961.5, y = 3741.5, z = 32.34 },
        },
    },
    train = {
        label = 'Conducteur de train', icon = 'train',
        desc = 'Prends les commandes du métro : arrête-toi à chaque station, laisse monter les voyageurs puis repars. Ponctualité et arrêts précis = meilleure paie.',
        variation = 24, maxSpeed = 22.0, stopRadius = 28.0, stopSpeed = 1.5, dwell = 9, payPerStop = 80, bonusLine = 200,
    },
}
Config.Act.JobOrder = { 'garbage', 'towing', 'carwash', 'trucker', 'farmer', 'firefighter', 'train' }

-- ─────────────────────────────── Points par défaut ───────────────────────────────
-- Utilisés seulement si le job n'a AUCUN point d'activité de ce rôle dans le Job Builder (valeurs de départ approximatives : pose les tiens).
-- Rôles : scrap (fourrière), bay (baie), dest (destination), field (champ), market (marché), zone (zone de ramassage / de panne), fire (incendie), station (train).
Config.Act.DefaultPoints = {
    garbage     = {},
    towing      = {
                    scrap = { { x = 401.0, y = -1631.0, z = 29.3, h = 320.0, label = 'Fourrière' } } },
    carwash     = {},
    trucker     = {
                    dest  = { { x = 1961.5, y = 3741.5, z = 32.34, h = 300.0, label = 'Sandy Shores' }, { x = 549.0, y = 2671.0, z = 42.2, h = 100.0, label = 'Harmony' },
                              { x = 1698.0, y = 4924.0, z = 42.1, h = 320.0, label = 'Grapeseed' }, { x = -102.0, y = 6467.0, z = 31.6, h = 45.0, label = 'Paleto Bay' },
                              { x = -3040.0, y = 585.0, z = 7.9, h = 20.0, label = 'Chumash' } } },
    farmer      = {
                    field = { { x = 1725.0, y = 4950.0, z = 42.0, h = 0.0, label = 'Champ' } },
                    market = { { x = 1690.0, y = 4930.0, z = 42.1, h = 140.0, label = 'Marché' } } },
    firefighter = {},
    train       = {},
}
-- Arrêts du métro (ordre de la ligne) : positions à vérifier / remplacer avec des points d'activité « Station » du Job Builder (sur le quai, dans l'ordre de la ligne).
Config.Act.TrainStations = {
    { label = 'LSIA Terminal', x = -1095.0, y = -2714.0, z = -7.4 }, { label = 'LSIA Parking', x = -890.0, y = -2326.0, z = -11.7 },
    { label = 'Puerto del Sol', x = -537.0, y = -1286.0, z = 26.9 }, { label = 'Pillbox Hill', x = -214.0, y = -1031.0, z = 30.1 },
    { label = 'Strawberry', x = 270.0, y = -1209.0, z = 38.9 }, { label = 'Davis', x = 112.0, y = -1730.0, z = 30.1 },
}
