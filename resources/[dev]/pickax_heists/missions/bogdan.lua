-- ═══════════════════════════════════════════════════════════════════════════════════════════
--  BRAQUAGE DOOMSDAY — ACTE II : LE PROBLÈME BOGDAN
--  Reproduit l'enchaînement du jeu : 3 préparatifs, 4 mises en place, puis le finale à deux
--  équipes (sous-marin / air). Les COORDONNÉES sont des repères à CALIBRER sur ta carte
--  (commande /heistpos), les objectifs et leur ordre suivent la mission d'origine.
--
--  Types d'étapes : goto · vehicle · kill · interact · photo · deliver · cutscene
-- ═══════════════════════════════════════════════════════════════════════════════════════════
Heists = Heists or {}

local FACILITY = vec3(-1267.2, -3013.1, 13.9)      -- ← À CALIBRER : point de livraison (« installation »)

Heists.bogdan = {
    id = 'bogdan',
    label = 'Le problème Bogdan',
    act = 'Braquage Doomsday · Acte II',
    brief = "Bogdan Dobrev a fait disparaître le contact de l'agence. Il faut trouver où il est détenu : un sous-marin russe au large. Préparez l'équipement, puis montez à bord.",
    elite = { time = 15 * 60, vehicleDamage = 5, noDeaths = true },

    missions = {
        -- ───────────── PRÉPARATIFS ─────────────
        {
            id = 'prep_keycards', kind = 'prep', label = "Cartes d'accès", players = { 1, 4 },
            brief = "Une station-service est le théâtre d'une fusillade entre la police et des braqueurs. Récupérez le fourgon antiémeute qui transporte les cartes d'accès du hangar.",
            steps = {
                { type = 'goto',    label = 'Aller à la station-service',            coords = vec3(-707.5, -914.3, 19.2), radius = 40.0 },
                { type = 'kill',    label = 'Éliminer les braqueurs',                coords = vec3(-707.5, -914.3, 19.2), count = 6, radius = 18.0 },
                { type = 'vehicle', label = 'Voler le fourgon antiémeute',           model = `riot`, spawn = vec4(-715.0, -925.0, 19.0, 90.0), guards = 3 },
                { type = 'deliver', label = "Livrer le fourgon à l'installation",    coords = FACILITY, radius = 8.0, vehicle = true },
            },
        },
        {
            id = 'setup_avenger', kind = 'setup', label = 'Avenger', requires = { 'prep_keycards' }, players = { 1, 4 },
            brief = "Les cartes ouvrent un hangar de l'aéroport international. L'Avenger y est stocké : récupérez-le.",
            steps = {
                { type = 'goto',    label = "Aller au hangar de l'aéroport",         coords = vec3(-1267.0, -3013.0, 13.9), radius = 50.0 },
                { type = 'kill',    label = 'Éliminer les gardes du hangar',         coords = vec3(-1267.0, -3013.0, 13.9), count = 8, radius = 25.0 },
                { type = 'interact',label = 'Couper les générateurs de secours',     coords = vec3(-1255.0, -3030.0, 13.9), text = 'Couper le générateur', duration = 6000 },
                { type = 'vehicle', label = "Voler l'Avenger",                       model = `avenger`, spawn = vec4(-1260.0, -3000.0, 14.0, 330.0) },
                { type = 'deliver', label = "Livrer l'Avenger à l'installation",     coords = FACILITY, radius = 25.0, vehicle = true },
            },
        },
        {
            id = 'prep_ulp', kind = 'prep', label = 'Renseignements ULP', players = { 1, 4 },
            brief = "Deux dealers savent où se cache un informateur de l'ULP. Faites-les parler, nettoyez l'appartement et rapportez le sac.",
            steps = {
                { type = 'goto',    label = 'Retrouver les dealers',                 coords = vec3(-1117.0, -1068.0, 2.2), radius = 40.0 },
                { type = 'kill',    label = 'Éliminer les dealers',                  coords = vec3(-1117.0, -1068.0, 2.2), count = 2, radius = 15.0 },
                { type = 'goto',    label = "Aller à l'appartement",                 coords = vec3(-1150.0, -1520.0, 10.6), radius = 25.0 },
                { type = 'kill',    label = "Nettoyer l'appartement",                coords = vec3(-1150.0, -1520.0, 10.6), count = 6, radius = 14.0 },
                { type = 'interact',label = 'Prendre le sac de renseignements',      coords = vec3(-1152.0, -1523.0, 10.6), text = 'Prendre le sac', duration = 4000 },
                { type = 'deliver', label = "Rapporter le sac à l'installation",     coords = FACILITY, radius = 12.0 },
            },
        },
        {
            id = 'setup_rescue', kind = 'setup', label = "Sauver l'agent de l'ULP", requires = { 'prep_ulp' }, players = { 2, 4 },
            brief = "L'agent est retenu dans une fonderie. Deux équipes : l'une donne l'assaut, l'autre couvre depuis un point en hauteur.",
            teamed = true,
            teams = {
                assault = { label = 'Assaut', steps = {
                    { type = 'goto',    label = 'Rejoindre la fonderie',             coords = vec3(1090.0, -1998.0, 31.0), radius = 40.0 },
                    { type = 'kill',    label = 'Éliminer les gardes',               coords = vec3(1090.0, -1998.0, 31.0), count = 10, radius = 28.0 },
                    { type = 'interact',label = "Libérer l'agent",                   coords = vec3(1088.0, -2005.0, 31.0), text = "Détacher l'agent", duration = 5000 },
                    { type = 'vehicle', label = "Monter dans le véhicule blindé",    model = `kuruma2`, spawn = vec4(1080.0, -1985.0, 31.0, 180.0) },
                    { type = 'deliver', label = "Ramener l'agent à l'installation",  coords = FACILITY, radius = 12.0, vehicle = true },
                } },
                cover = { label = 'Couverture', steps = {
                    { type = 'goto',    label = 'Gagner le point en hauteur',        coords = vec3(1120.0, -2040.0, 45.0), radius = 15.0 },
                    { type = 'kill',    label = "Couvrir l'assaut : éliminer les renforts", coords = vec3(1090.0, -1998.0, 31.0), count = 8, radius = 60.0 },
                    { type = 'deliver', label = "Rejoindre l'installation",          coords = FACILITY, radius = 12.0 },
                } },
            },
        },
        {
            id = 'prep_rcv', kind = 'prep', label = 'Camion antiémeute (RCV)', players = { 1, 4 },
            brief = "Provoquez une émeute : la sécurité privée envoie un camion antiémeute. Son canon à eau servira contre les agents qui détruisent des disques durs.",
            steps = {
                { type = 'goto',    label = "Aller sur le lieu de l'émeute",         coords = vec3(-47.0, -1757.0, 29.4), radius = 40.0 },
                { type = 'interact',label = "Déclencher l'émeute",                   coords = vec3(-47.0, -1757.0, 29.4), text = "Lancer l'émeute", duration = 3000 },
                { type = 'vehicle', label = 'Voler le camion antiémeute (RCV)',      model = `riot2`, spawn = vec4(-60.0, -1770.0, 29.0, 50.0), guards = 4 },
                { type = 'deliver', label = "Livrer le RCV à l'installation",        coords = FACILITY, radius = 8.0, vehicle = true },
            },
        },
        {
            id = 'prep_stromberg', kind = 'prep', label = 'Strombergs', requires = { 'setup_rescue' }, players = { 1, 4 },
            brief = "Un convoi transporte des Strombergs. Interceptez le camion et récupérez les véhicules.",
            steps = {
                { type = 'goto',    label = 'Rejoindre le convoi',                   coords = vec3(1550.0, 3400.0, 36.0), radius = 60.0 },
                { type = 'kill',    label = "Éliminer l'escorte",                    coords = vec3(1550.0, 3400.0, 36.0), count = 8, radius = 40.0 },
                { type = 'vehicle', label = 'Voler le camion et son Stromberg',      model = `phantom`, spawn = vec4(1555.0, 3405.0, 36.0, 120.0) },
                { type = 'deliver', label = "Livrer le Stromberg à l'installation",  coords = FACILITY, radius = 10.0, vehicle = true },
            },
        },
        {
            id = 'prep_torpedo', kind = 'prep', label = 'Calculateurs de torpilles', requires = { 'prep_stromberg' }, players = { 1, 4 },
            brief = "Les Strombergs ne sont armés qu'avec des calculateurs de torpilles. Récupérez-les sur un site sécurisé.",
            steps = {
                { type = 'goto',    label = 'Aller au site sécurisé',                coords = vec3(1013.0, -3057.0, 5.9), radius = 50.0 },
                { type = 'kill',    label = 'Éliminer les gardes',                   coords = vec3(1013.0, -3057.0, 5.9), count = 8, radius = 30.0 },
                { type = 'interact',label = 'Récupérer les calculateurs',            coords = vec3(1010.0, -3062.0, 5.9), text = 'Récupérer les calculateurs', duration = 5000 },
                { type = 'deliver', label = "Rapporter à l'installation",            coords = FACILITY, radius = 12.0 },
            },
        },
        {
            id = 'setup_recon', kind = 'setup', label = 'Reconnaissance du sous-marin', requires = { 'prep_torpedo', 'setup_avenger', 'prep_rcv' }, players = { 1, 4 },
            brief = "Repérez le sous-marin russe avant l'assaut final.",
            steps = {
                { type = 'vehicle', label = "Prendre l'Avenger",                     model = `avenger`, spawn = vec4(-1260.0, -3000.0, 14.0, 330.0) },
                { type = 'goto',    label = 'Survoler la zone de recherche',         coords = vec3(-3200.0, -1700.0, 120.0), radius = 120.0 },
                { type = 'photo',   label = 'Photographier le sous-marin',           coords = vec3(-3400.0, -1800.0, 0.0), radius = 400.0 },
                { type = 'deliver', label = "Retourner à l'installation",            coords = FACILITY, radius = 40.0, vehicle = true },
            },
        },

        -- ───────────── FINALE ─────────────
        {
            id = 'finale', kind = 'finale', label = 'Le problème Bogdan', requires = { 'setup_recon', 'prep_ulp', 'setup_rescue', 'setup_avenger', 'prep_rcv', 'prep_stromberg', 'prep_torpedo' },
            players = { 2, 4 }, teamed = true, finale = true,
            brief = "Assaut du sous-marin. L'équipe sous-marin monte à bord du Stromberg, l'équipe aérienne fait taire les hélicoptères ennemis depuis l'Avenger.",
            teams = {
                sub = { label = 'Équipe sous-marin', steps = {
                    { type = 'vehicle', label = 'Monter dans le Stromberg',                  model = `stromberg`, spawn = vec4(-1290.0, -3040.0, 0.0, 0.0), amphibious = true },
                    { type = 'goto',    label = 'Rejoindre le sous-marin',                   coords = vec3(-3400.0, -1800.0, 0.0), radius = 80.0 },
                    { type = 'kill',    label = 'Éliminer les soldats du passage',           coords = vec3(-3400.0, -1800.0, 0.0), count = 4, radius = 20.0 },
                    { type = 'interact',label = 'Trouver le contact détenu (niveau inférieur)', coords = vec3(-3402.0, -1802.0, -4.0), text = 'Interroger le contact', duration = 5000 },
                    { type = 'goto',    label = 'Rejoindre la salle de contrôle',            coords = vec3(-3398.0, -1798.0, 1.0), radius = 6.0 },
                    { type = 'photo',   label = 'Photographier la table de renseignements',  coords = vec3(-3398.0, -1798.0, 1.0), radius = 6.0 },
                    { type = 'interact',label = 'Brancher Clifford sur la console',          coords = vec3(-3397.0, -1799.0, 1.0), text = 'Brancher Clifford', duration = 8000 },
                    { type = 'cutscene',label = 'Les données sont copiées',                  duration = 6000 },
                    { type = 'deliver', label = "Rejoindre l'Avenger",                       coords = vec3(-3400.0, -1800.0, 120.0), radius = 60.0 },
                } },
                air = { label = 'Équipe aérienne', steps = {
                    { type = 'vehicle', label = "Monter dans l'Avenger",                     model = `avenger`, spawn = vec4(-1260.0, -3000.0, 14.0, 330.0) },
                    { type = 'goto',    label = 'Survoler le sous-marin',                    coords = vec3(-3400.0, -1800.0, 120.0), radius = 120.0 },
                    { type = 'kill',    label = 'Éliminer les hélicoptères ennemis',         coords = vec3(-3400.0, -1800.0, 120.0), count = 4, radius = 400.0, air = true },
                    { type = 'goto',    label = "Récupérer l'équipe sous-marin",             coords = vec3(-3400.0, -1800.0, 120.0), radius = 60.0 },
                    { type = 'deliver', label = "Livrer l'Avenger à l'installation",         coords = FACILITY, radius = 25.0, vehicle = true },
                } },
            },
        },
    },
}
