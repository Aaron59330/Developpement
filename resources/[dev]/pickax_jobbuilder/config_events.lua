-- ─────────────────────────────── Événements aléatoires liés aux métiers ───────────────────────────────
-- De temps en temps, un incident survient sur la carte : les employés EN SERVICE du métier concerné reçoivent une alerte + un blip.
-- Le premier qui arrive sur place et mène l'intervention à terme empoche la récompense (les autres sont prévenus).
-- Un événement n'est lancé que si au moins `MinWorkers` employés du bon type de métier sont en service.
Config.RandomEvents = {
    Enabled    = true,
    Interval   = { 600, 1500 },      -- délai aléatoire (secondes) entre deux événements
    MaxActive  = 2,                  -- événements simultanés
    MinWorkers = 1,
    Account    = 'bank',             -- compte crédité pour les métiers sans XP (police / EMS…)
    ClaimDistance = 25.0,            -- distance maximale (côté serveur) entre le joueur et l'incident au moment de la validation
    AdminCommand  = 'jbevent',       -- /jbevent <breakdown|accident|burglary|dump> : déclenche un événement (groupes Config.Act.AdminGroups)

    -- jobTypes : types de job du Job Builder · jobKey : métier actif (paie + XP + succès) ou nil (paie simple)
    -- visual : 'vehicle' (voiture en panne) · 'injured' (blessé + épave) · 'alarm' (marqueur + alarme) · 'dump' (sacs de déchets)
    Events = {
        breakdown = {
            label = 'Panne sur la route', jobTypes = { 'towing' }, jobKey = 'towing', visual = 'vehicle',
            announce = 'Un automobiliste est en panne à ~y~%s~s~. Va le dépanner !', interact = 'Dépanner le véhicule', progress = 'Dépannage en cours…',
            seconds = 10, reward = { 350, 650 }, xp = 25, timeout = 900,
            models = { 'blista', 'asea', 'premier', 'ingot', 'emperor', 'fugitive', 'sultan', 'felon' },
        },
        accident = {
            label = 'Accident de la route', jobTypes = { 'ems' }, visual = 'injured',
            announce = 'Accident de la route à ~y~%s~s~ : un blessé a besoin de secours !', interact = 'Soigner le blessé', progress = 'Soins en cours…',
            seconds = 12, reward = { 500, 900 }, timeout = 900,
            models = { 'blista', 'asea', 'premier' }, ped = 'a_m_m_business_01',
        },
        burglary = {
            label = 'Alarme de cambriolage', jobTypes = { 'police' }, visual = 'alarm',
            announce = 'Alarme de cambriolage déclenchée à ~y~%s~s~. Sécurisez les lieux !', interact = 'Sécuriser les lieux', progress = 'Inspection des lieux…',
            seconds = 10, reward = { 400, 800 }, timeout = 900,
        },
        dump = {
            label = 'Décharge sauvage', jobTypes = { 'garbage' }, jobKey = 'garbage', visual = 'dump',
            announce = 'Dépôt sauvage de déchets à ~y~%s~s~. Va nettoyer !', interact = 'Ramasser les déchets', progress = 'Nettoyage en cours…',
            seconds = 10, reward = { 250, 450 }, xp = 20, timeout = 1200,
            props = { 'prop_rub_binbag_03', 'prop_rub_binbag_04', 'prop_cs_rub_binbag_01' },
        },
    },

    -- Lieux possibles (x, y, z, cap) : routes et rues de Los Santos — à ajuster à ta carte
    Locations = {
        { label = 'Strawberry Avenue',  x = 125.0,  y = -1050.0, z = 29.2, h = 70.0 },
        { label = 'Davis',              x = 80.0,   y = -1690.0, z = 29.2, h = 140.0 },
        { label = 'Mission Row',        x = 370.0,  y = -780.0,  z = 29.3, h = 0.0 },
        { label = 'Vinewood Boulevard', x = 295.0,  y = 180.0,   z = 104.0, h = 250.0 },
        { label = 'Mirror Park',        x = 1050.0, y = -710.0,  z = 57.4, h = 90.0 },
        { label = 'Del Perro',          x = -1450.0, y = -520.0, z = 33.7, h = 30.0 },
        { label = 'Rockford Hills',     x = -620.0, y = -250.0,  z = 37.0, h = 120.0 },
        { label = 'La Mesa',            x = 840.0,  y = -1030.0, z = 27.9, h = 0.0 },
    },
}
