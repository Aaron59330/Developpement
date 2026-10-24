Config = {}
-- Taille des blips par défaut : celle de tout le serveur (pickax_core/config.lua → Config.GlobalBlip.Scale), sinon la valeur donnée.
-- Un blip réglé en jeu dans un builder garde sa taille.
local function PK_BSF(default) return (PickaxTheme and PickaxTheme.blipScale) or default end
-- Marker de base : celui de tout le serveur (pickax_core/config.lua → Config.GlobalMarker : forme + couleur)
local PK_MK = PickaxTheme and PickaxTheme.marker
local PK_MKT = PK_MK and PK_MK.type or 23
local function PK_MKC() return PK_MK and { PK_MK.color[1], PK_MK.color[2], PK_MK.color[3] } or { 253, 194, 125 } end

-- ═══════════════════════════════════════════════════════════════════════════════════════════════
--  GANG BUILDER — config.lua
--  Tout ce qui est ici est un DÉFAUT. Presque tout est modifiable en jeu (/gangbuilder → Paramètres) :
--  les changements sont stockés en base (gangbuilder_settings), appliqués en direct sur le serveur et chez tous les joueurs.
--  « Réinitialiser cette section » (en jeu) revient aux valeurs de ce fichier.
--  Les gangs sont écrits dans TES tables job2 : jobs2 / job2_grades, et assignés dans users.job2 / users.job2_grade.
-- ═══════════════════════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────── Général ───────────────────────────────
Config.AllowedGroups   = { '_dev' }          -- groupes ESX autorisés à ouvrir le builder
Config.AcePermission   = 'gangbuilder.admin' -- (optionnel) permission ACE alternative
Config.Command         = 'gangbuilder'       -- /gangbuilder ouvre le builder
Config.GangMenuCommand = 'gangmenu'          -- menu du gang (actions, infos)
Config.GangMenuKey     = 'F7'                -- touche par défaut du menu gang (F6 = menu métier du jobbuilder)

Config.DrawDistance     = 12.0   -- distance d'affichage des markers
Config.InteractDistance = 1.6    -- distance pour interagir (E)
Config.ServerDistance   = 10.0   -- tolérance côté serveur (anti-triche)
Config.TargetDistance   = 4.0    -- distance max joueur -> joueur (menottes, recrutement...)

Config.MaxGangs         = 0      -- nombre max de gangs créés avec le builder (0 = illimité)
Config.MaxGrades        = 15
Config.MaxPoints        = 80
Config.MaxItemsPerPoint = 100

Config.Inventory         = 'auto'  -- 'auto' | 'ox' | 'esx'
Config.PlatePrefixLength = 3       -- plaque véhicule gang : 3 lettres du gang + 5 chiffres
Config.UseGangColor      = false   -- true : les markers des points prennent la couleur du gang (sinon : couleur de base du serveur / du type de point)

-- Ressources redémarrées automatiquement après la création / modification / suppression d'un gang.
-- Utile si ta ressource job2 charge la liste des jobs2 au DÉMARRAGE (voir Config.Job2.Refresh* plus bas). Ex : { 'pickax_core' }
Config.RestartResources = {}

-- ─────────────────────────────── Job2 (là où les gangs sont écrits) ───────────────────────────────
-- Un gang = une ligne dans `jobs2` + ses grades dans `job2_grades`. Les joueurs y sont rattachés via users.job2 / users.job2_grade.
-- Les noms de tables / colonnes ci-dessous ne sont modifiables que dans ce fichier (redémarrage requis).
Config.Job2 = {
    JobsTable    = 'jobs2',
    GradesTable  = 'job2_grades',
    UsersTable   = 'users',
    UserJobColumn   = 'job2',          -- users.job2        (varchar(20) → 20 caractères max pour le nom du gang)
    UserGradeColumn = 'job2_grade',    -- users.job2_grade
    IdentifierColumn = 'identifier',
    GradeColumns = { job = 'job_name', grade = 'grade', name = 'name', label = 'label', salary = 'salary', skinMale = 'skin_male', skinFemale = 'skin_female' },
    NameMaxLength = 20,

    Default = { name = 'unemployed2', grade = 0 },   -- job2 « sans gang » (membre viré / gang supprimé)

    -- Comment lire / écrire le job2 d'un joueur CONNECTÉ :
    --   'auto' : xPlayer.job2 si ton es_extended le gère, sinon directement la base (users)
    --   'esx'  : uniquement xPlayer.job2   |   'db' : uniquement la base
    Source       = 'auto',
    PlayerField  = 'job2',             -- champ du xPlayer : xPlayer.job2 = { name, grade, label, grade_label, ... }
    SetMethod    = 'setJob2',          -- méthode du xPlayer : xPlayer.setJob2(name, grade)
    ClientEvent  = 'esx:setJob2',      -- event client envoyé en cas de repli (écriture base)
    ServerEvent  = 'esx:setJob2',      -- event serveur déclenché en cas de repli
    SyncEvents   = { 'esx:setJob2' },  -- events serveur qui resynchronisent les joueurs du gang

    -- Après une création / modification de gang, ces fonctions de ES (ESX.<nom>) sont appelées pour recharger la liste des jobs2.
    RefreshFunctions = { 'RefreshJobs2', 'RefreshJob2', 'RefreshJobs' },
    RefreshEvents    = {},             -- events serveur déclenchés en plus (ex : { 'esx:refreshJobs2' })
    Refresh          = nil,            -- function() end : ton propre code de rechargement (optionnel)

    -- Noms refusés pour un nouveau gang : déjà utilisés dans ces tables (empêche tout mélange avec jobs / jobs2 / autres scripts de gangs)
    ConflictTables = {
        { table = 'jobs',         column = 'name' },
        { table = 'jobs2',        column = 'name' },
        { table = 'pgang_gangs',  column = 'name' },
        { table = 'fx_gangs',     column = 'name' },
    },
}

-- ─────────────────────────────── Argent sale ───────────────────────────────
Config.Dirty = {
    Mode = 'account',        -- 'account' : compte ESX (black_money)  |  'item' : objet d'inventaire
    Name = 'black_money',    -- nom du compte ou de l'objet
}

-- ─────────────────────────────── Trésorerie du gang ───────────────────────────────
-- Argent propre + sale du gang, stockés dans gangbuilder_gangs (money / dirty). Gérés depuis le point « Gestion boss ».
Config.Treasury = {
    Enabled        = true,
    AllowDeposit   = true,        -- les membres du bureau peuvent déposer
    AllowWithdraw  = true,        -- les membres du bureau peuvent retirer
    DepositDirty   = true,        -- dépôt / retrait d'argent sale autorisé
    MaxTransaction = 10000000,    -- plafond d'une opération
    StartMoney     = 0,           -- argent propre offert à la création d'un gang
}

-- ─────────────────────────────── Règles des gangs ───────────────────────────────
Config.Gang = {
    MaxMembers   = 0,       -- membres max par gang (0 = illimité ; modifiable gang par gang)
    RecruitGrade = 0,       -- grade donné à un recrue
    AllowLeave   = true,    -- un membre peut quitter son gang via le menu (F7)
    ProtectBoss  = true,    -- le bureau ne peut pas modifier / virer un autre membre du bureau
    RecruitOnlyUnassigned = true,  -- on ne recrute que les joueurs « sans gang » (job2 par défaut) : jamais d'écrasement du job2 d'un autre métier
}

-- ─────────────────────────────── Salaires ───────────────────────────────
-- ⚠ Si ton es_extended paie déjà les salaires de job2 (xPlayer.job2.grade_salary), laisse Enabled = false pour ne pas payer deux fois.
Config.Salary = {
    Enabled         = false,
    IntervalMinutes = 30,
    Source          = 'treasury',  -- 'treasury' : payé par la trésorerie du gang  |  'system' : créé par le serveur
    Account         = 'bank',      -- compte crédité : 'money' | 'bank'
    SkipIfBroke     = true,        -- trésorerie insuffisante : personne n'est payé (sinon : payé partiellement dans l'ordre)
}

-- ─────────────────────────────── Affrontements de territoire ───────────────────────────────
-- Quand un gang fait une activité illégale (récolte, traitement, vente) sur le territoire d'un AUTRE gang, le propriétaire est
-- prévenu (notification + alerte sur la carte) et un affrontement commence : chaque kill dans la zone rapporte un point.
-- À la fin, le gang qui a le plus de points gagne ; s'il s'agit de l'intrus, il capture le territoire (WinnerCaptures).
Config.Conflicts = {
    Enabled         = true,
    Kinds           = { harvest = true, process = true, sell = true },   -- activités qui déclenchent un affrontement
    Duration        = 300,     -- durée d'un affrontement (s)
    Cooldown        = 900,     -- délai avant qu'un même gang puisse en redéclencher un sur le même territoire (s)
    WinnerCaptures  = true,    -- l'intrus qui gagne (au moins 1 kill de plus) capture le territoire
    MinKillsToWin   = 1,       -- kills minimum pour gagner
    RepWin          = 20,      -- réputation du gagnant
    RepLoss         = 0,       -- réputation retirée au perdant (0 = rien)
    AlertBlipSeconds = 90,     -- durée du clignotement de la zone sur la carte pour les deux gangs
}

-- ─────────────────────────────── Missions « colis » entre gangs ───────────────────────────────
-- Un colis apparaît dans une zone. Le premier gang qui le prend doit RESTER dans la zone `Hold` secondes avec le colis
-- (le compteur avance même si aucun gang adverse ne vient), puis le ramener à SON coffre de gang. Si le porteur meurt, le colis tombe
-- et n'importe quel gang peut le prendre (le gang qui le reprend doit alors refaire le temps de zone, ou la livraison si elle est en cours).
Config.Objectives = {
    Enabled         = true,
    AutoStart       = true,    -- lance une mission automatiquement
    Interval        = 45,      -- minutes entre deux missions automatiques
    MinGangsOnline  = 2,       -- gangs ayant au moins 1 membre connecté pour lancer une mission automatique
    Duration        = 40,      -- durée maximale d'une mission (min)
    Hold            = 180,     -- secondes à tenir dans la zone avec le colis (valeur par défaut)
    LeaveGrace      = 25,      -- secondes tolérées hors zone avant que le colis ne retourne au centre
    PickupDistance  = 3.0,     -- distance pour ramasser le colis
    DeliverDistance = 4.0,     -- distance au coffre du gang pour livrer
    RevealCarrier   = true,    -- les autres gangs voient le porteur sur la carte pendant la livraison
    RevealInterval  = 5,       -- secondes entre deux mises à jour de sa position
    RewardAccount   = 'dirty', -- 'dirty' | 'money'
    Reward          = 5000,    -- récompense versée à la trésorerie du gang (par défaut, modifiable par zone)
    RewardRep       = 40,
    Model           = 'prop_box_wood02a_pu',   -- objet affiché au sol
    -- Zones possibles (une au hasard par mission automatique ; /gbobjective <nom> pour en lancer une précise)
    -- `hold` et `reward` sont facultatifs par zone : sans eux, les réglages Hold / Reward ci-dessus (modifiables en jeu) s'appliquent.
    Zones = {
        { name = 'port',      label = 'Cargaison du port',      coords = vector3(1210.0, -3050.0, 5.9),  radius = 40.0 },
        { name = 'aerodrome', label = 'Largage de l\'aérodrome', coords = vector3(1740.0, 3290.0, 41.1),  radius = 45.0 },
        { name = 'entrepot',  label = 'Entrepôt abandonné',     coords = vector3(1000.0, -2180.0, 30.5), radius = 35.0 },
    },
}

-- ─────────────────────────────── Réputation ───────────────────────────────
Config.Rep = {
    Enabled         = true,
    PerCapture      = 25,    -- territoire capturé
    PerIncome       = 2,     -- chaque revenu de territoire
    PerSaleThousand = 1,     -- par tranche de 1 000 $ vendus (points de vente)
    PerLaunderThousand = 1,  -- par tranche de 1 000 $ blanchis
    PerProcess      = 1,     -- par fabrication
    PerHarvest      = 0,     -- par récolte
}

-- ─────────────────────────────── Territoires ───────────────────────────────
-- Zones circulaires créées dans le builder (onglet Territoires). Un gang les capture en restant dedans ; le propriétaire touche un revenu
-- dans sa trésorerie. Chaque territoire peut surcharger les valeurs ci-dessous (vide = valeur par défaut).
Config.Territories = {
    Enabled           = true,
    Tick              = 1,       -- secondes entre deux calculs de capture
    CaptureSeconds    = 120,     -- durée pour capturer (une seule équipe présente)
    MinMembers        = 1,       -- membres du gang attaquant requis dans la zone
    OwnerBlocks       = true,    -- la présence du propriétaire empêche la capture
    DecayFactor       = 1.0,     -- vitesse de retombée de la capture quand l'attaquant part (1 = même vitesse que la montée)
    ProtectionMinutes = 30,      -- protection après une capture
    IncomeInterval    = 15,      -- minutes entre deux revenus
    Reward            = 500,     -- revenu par période
    RewardAccount     = 'dirty', -- 'dirty' (argent sale du gang) | 'money' (argent propre)
    MaxTerritories    = 30,
    DefaultRadius     = 40.0,
    MaxRadius         = 300.0,
    AnnounceCapture   = true,    -- prévient les membres des gangs concernés
    AlertOwner        = true,    -- prévient le propriétaire dès qu'un gang commence à capturer son territoire
    AlertCooldown     = 120,     -- secondes entre deux alertes pour un même territoire et un même attaquant
    ShowBlips         = true,
    BlipSprite        = 310,     -- icône au centre de la zone
    BlipScale         = 0.8,
    NeutralColor      = 0,       -- couleur de blip d'un territoire libre
    BlipAlpha         = 120,     -- transparence de la zone (0-255)
    DrawZone          = true,    -- dessine la zone au sol quand on est proche
    ZoneAlpha         = 35,      -- transparence de la zone au sol
}

-- ─────────────────────────────── Activités illégales ───────────────────────────────
Config.Activities = {
    Grace       = 0.85,   -- part minimale de la durée à respecter côté serveur (anti-triche)
    MaxHarvest  = 30,     -- quantité max par récolte
    MaxBatch    = 10,     -- fabrications max d'un coup
    MaxRecipes  = 30,     -- recettes max par point Traitement
    MaxInputs   = 5,      -- ingrédients max par recette
    MaxSell     = 100,    -- quantité max par vente

    HarvestScenario = 'WORLD_HUMAN_GARDENER_PLANT',
    ProcessScenario = 'PROP_HUMAN_BBQ',
    LaunderScenario = 'PROP_HUMAN_PARKING_METER',

    SellAccount       = 'dirty',  -- compte crédité par défaut : 'dirty' | 'money' | 'bank'
    SellPriceVariance = 10,       -- variation aléatoire du prix à chaque vente (± %)
    SellGangCut       = 0,        -- part du prix reversée à la trésorerie du gang (%)
    SellCooldown      = 0,        -- secondes entre deux ventes d'un joueur (0 = aucune)
    PoliceAlert       = false,    -- alerte police lors d'une vente
    PoliceAlertChance = 30,       -- chance d'alerte (%)

    LaunderFee      = 20,         -- commission du blanchiment (%)
    LaunderGangCut  = 100,        -- part de la commission qui va à la trésorerie du gang (%)
    LaunderMin      = 100,
    LaunderMax      = 250000,
    LaunderSeconds  = 10,
}

-- ─────────────────────────────── Points ───────────────────────────────
-- Apparence de base des markers (modifiable en jeu : Paramètres → Markers des points)
Config.PointTypes = {
    garage    = { label = 'Garage',          color = PK_MKC(), marker = PK_MKT },
    garage_return = { label = 'Rangement véhicule', color = PK_MKC(), marker = PK_MKT, hidden = true },   -- le rangement est INTÉGRÉ au garage (carte « Rangement » de l'éditeur) ; ce type reste géré pour le point généré
    cloakroom = { label = 'Vestiaire',       color = PK_MKC(), marker = PK_MKT },
    armory    = { label = 'Armurerie',       color = PK_MKC(), marker = PK_MKT },
    stash     = { label = 'Coffre',          color = PK_MKC(), marker = PK_MKT },
    boss      = { label = 'Gestion du gang', color = PK_MKC(), marker = PK_MKT },
    shop      = { label = 'Marché noir',     color = PK_MKC(), marker = PK_MKT },
    harvest   = { label = 'Récolte',         color = PK_MKC(), marker = PK_MKT },
    process   = { label = 'Traitement',      color = PK_MKC(), marker = PK_MKT },
    sell      = { label = 'Point de vente',  color = PK_MKC(), marker = PK_MKT },
    laundry   = { label = 'Blanchiment',     color = PK_MKC(), marker = PK_MKT, hidden = true },   -- retiré : le blanchiment se fait avec la tablette (Builder Illégal) ; les anciens points sont supprimés au prochain enregistrement du gang
    -- Variantes de garage (hidden = non ajoutables directement : on choisit le « type » dans l'éditeur du garage)
    garage_bike     = { label = 'Garage motos',    color = PK_MKC(), marker = PK_MKT, hidden = true },
    garage_aircraft = { label = 'Garage aéronefs', color = PK_MKC(), marker = PK_MKT, hidden = true },
    garage_boat     = { label = 'Garage bateaux',  color = PK_MKC(), marker = PK_MKT, hidden = true },
}

Config.GarageKinds = {
    car      = { label = 'Voitures',              clear = 3.0 },
    bike     = { label = 'Motos & vélos',         clear = 2.5 },
    aircraft = { label = 'Avions & hélicoptères', clear = 9.0 },
    boat     = { label = 'Bateaux',               clear = 8.0 },
}

-- Type de garage proposé selon la catégorie de ta table vehicles (défaut : 'car')
Config.CategoryTypes = { motorcycles = 'bike', Motosimports = 'bike', velo = 'bike', boat = 'boat', subs = 'boat', aircraft = 'aircraft', helicopters = 'aircraft', planes = 'aircraft' }

-- ─────────────────────────────── Actions du menu gang (F7) ───────────────────────────────
-- 'info' (fiche du gang) et 'leave' (quitter) sont ajoutées automatiquement. Les autres sont cochées gang par gang dans le builder.
Config.Actions = {
    handcuff = { label = 'Menotter / Démenotter', icon = 'fa-handcuffs',       target = true },
    escort   = { label = 'Escorter',              icon = 'fa-people-arrows',   target = true },
    search   = { label = 'Fouiller',              icon = 'fa-magnifying-glass', target = true },
    info     = { label = 'Fiche du gang',         icon = 'fa-skull',           target = false },
    tablet   = { label = 'Tablette de gang',      icon = 'fa-tablet',          target = false },
    props    = { label = 'Props du gang',         icon = 'fa-road-barrier',    target = false },   -- poser des barrières, plots, sacs de sable… (limite par joueur, plus haute avec le VIP)
    leave    = { label = 'Quitter le gang',       icon = 'fa-door-open',       target = false },
}
-- ─────────────────────────────── Props du gang ───────────────────────────────
-- Menu gang (F7) → « Props du gang » : chaque membre pose des props cohérents avec un gang (barrières, plots, sacs de sable, tables…).
-- Limite PAR JOUEUR : BaseLimit, ou la valeur du niveau VIP (pickax_core, players/vip/config.lua) si elle est plus haute.
Config.Props = {
    Enabled            = true,
    BaseLimit          = 10,                                -- props par joueur sans VIP
    VipLimits          = { [1] = 15, [2] = 20, [3] = 30 },  -- props par joueur selon le niveau VIP (1 Bronze, 2 Argent, 3 Or)
    PlaceDistance      = 10.0,                              -- distance max entre le joueur et le prop posé (m)
    Lifetime           = 0,                                 -- durée de vie d'un prop en minutes (0 = jusqu'au retrait / redémarrage)
    RemoveOnDisconnect = true,                              -- les props d'un joueur disparaissent quand il se déconnecte
    Cooldown           = 1500,                              -- ms minimum entre deux poses
    Catalog = {
        { id = 'barrier1',  label = 'Barrière de chantier',      model = 'prop_barrier_work05',   cat = 'Barrières' },
        { id = 'barrier2',  label = 'Barrière rayée',            model = 'prop_barrier_work06a',  cat = 'Barrières' },
        { id = 'barrier3',  label = 'Barrière basse',            model = 'prop_barrier_work01a',  cat = 'Barrières' },
        { id = 'barrier4',  label = 'Barrière béton',            model = 'prop_mp_barrier_02b',   cat = 'Barrières' },
        { id = 'cone',      label = 'Plot orange',               model = 'prop_roadcone02a',      cat = 'Barrières' },
        { id = 'sandbag',   label = 'Sacs de sable',             model = 'prop_sandbag_01',       cat = 'Défense' },
        { id = 'light',     label = 'Projecteur de chantier',    model = 'prop_worklight_03a',    cat = 'Éclairage' },
        { id = 'box1',      label = 'Caisse en bois',            model = 'prop_box_wood02a',      cat = 'Caisses' },
        { id = 'box2',      label = 'Pile de caisses',           model = 'prop_boxpile_07d',      cat = 'Caisses' },
        { id = 'barrel',    label = 'Fût métallique',            model = 'prop_barrel_02a',       cat = 'Caisses' },
        { id = 'table',     label = 'Table',                     model = 'prop_table_03',         cat = 'Mobilier' },
        { id = 'chair',     label = 'Chaise',                    model = 'prop_chair_01a',        cat = 'Mobilier' },
        { id = 'bbq',       label = 'Barbecue',                  model = 'prop_bbq_3',            cat = 'Mobilier' },
    },
}

Config.ActionRules = {
    SearchRequiresCuffed = true,   -- on ne fouille qu'un joueur menotté
    EscortRequiresCuffed = true,   -- on n'escorte qu'un joueur menotté
}

-- ─────────────────────────────── Apparence des menus ───────────────────────────────
Config.UI = { Accent = (PickaxTheme and PickaxTheme.rgb) or { 253, 194, 125 } }   -- couleur d'accentuation de toute l'interface (modifiable en jeu)

-- ─────────────────────────────── Modèles de gangs ───────────────────────────────
-- Chaque modèle pré-remplit le builder (grades, blip, actions, points suggérés). Tout reste modifiable dans l'UI et ici.
Config.GangTypes = {
    street = {
        label = 'Gang de rue', color = '#22c55e', blip = { sprite = 310, color = 2, scale = PK_BSF(0.9) },
        actions = { 'handcuff', 'escort', 'search', 'props' },
        points = { 'garage', 'cloakroom', 'armory', 'stash', 'harvest', 'process', 'sell', 'boss' },
        grades = {
            { name = 'recrue',   label = 'Petit',       salary = 50 },
            { name = 'soldat',   label = 'Soldat',      salary = 100 },
            { name = 'capo',     label = 'Lieutenant',  salary = 200 },
            { name = 'boss',     label = 'Chef',        salary = 400 },
        },
    },
    mafia = {
        label = 'Mafia', color = '#a855f7', blip = { sprite = 310, color = 27, scale = PK_BSF(0.9) },
        actions = { 'handcuff', 'escort', 'search', 'props' },
        points = { 'garage', 'cloakroom', 'armory', 'stash', 'shop', 'boss' },
        grades = {
            { name = 'associe',  label = 'Associé',     salary = 100 },
            { name = 'soldat',   label = 'Soldat',      salary = 200 },
            { name = 'capo',     label = 'Capo',        salary = 350 },
            { name = 'consigliere', label = 'Consigliere', salary = 500 },
            { name = 'boss',     label = 'Parrain',     salary = 800 },
        },
    },
    biker = {
        label = 'Club de motards', color = '#f97316', blip = { sprite = 226, color = 17, scale = PK_BSF(0.9) },
        actions = { 'handcuff', 'escort', 'search', 'props' },
        points = { 'garage', 'cloakroom', 'armory', 'stash', 'harvest', 'process', 'boss' },
        grades = {
            { name = 'prospect', label = 'Prospect',    salary = 50 },
            { name = 'member',   label = 'Membre',      salary = 120 },
            { name = 'sergeant', label = 'Sergent d\'armes', salary = 250 },
            { name = 'vice',     label = 'Vice-président', salary = 400 },
            { name = 'boss',     label = 'Président',   salary = 600 },
        },
    },
    cartel = {
        label = 'Cartel', color = '#ef4444', blip = { sprite = 310, color = 1, scale = PK_BSF(0.9) },
        actions = { 'handcuff', 'escort', 'search', 'props' },
        points = { 'garage', 'cloakroom', 'armory', 'stash', 'harvest', 'process', 'sell', 'boss' },
        grades = {
            { name = 'halcon',   label = 'Halcón',      salary = 80 },
            { name = 'sicario',  label = 'Sicario',     salary = 180 },
            { name = 'jefe',     label = 'Jefe de plaza', salary = 350 },
            { name = 'capo',     label = 'Capo',        salary = 600 },
            { name = 'boss',     label = 'Patrón',      salary = 1000 },
        },
    },
    custom = {
        label = 'Personnalisé', color = '#ef4444', blip = { sprite = 310, color = 1, scale = PK_BSF(0.9) },
        actions = { 'handcuff', 'escort', 'search', 'props' },
        points = { 'garage', 'cloakroom', 'armory', 'stash', 'boss' },
        grades = {
            { name = 'recrue', label = 'Recrue', salary = 50 },
            { name = 'boss',   label = 'Chef',   salary = 300 },
        },
    },
}

-- Clés de vêtements capturées pour les tenues du vestiaire (skinchanger / esx_skin)
Config.ClothesKeys = {
    'tshirt_1', 'tshirt_2', 'torso_1', 'torso_2', 'decals_1', 'decals_2', 'arms', 'arms_2',
    'pants_1', 'pants_2', 'shoes_1', 'shoes_2', 'bags_1', 'bags_2', 'chain_1', 'chain_2',
    'helmet_1', 'helmet_2', 'glasses_1', 'glasses_2', 'mask_1', 'mask_2', 'bproof_1', 'bproof_2',
    'ears_1', 'ears_2', 'watches_1', 'watches_2', 'bracelets_1', 'bracelets_2',
}

-- ─────────────────────────────── Hooks (adapter à ton serveur) ───────────────────────────────
Config.Hooks = {}

if IsDuplicityVersion() then
    -- Notification serveur → joueur (remplace par ox_lib / ton système si tu veux)
    Config.Hooks.Notify = function(src, message)
        TriggerClientEvent('pickax_notify:notify', src, { description = message, icon = 'gang' })
    end
else
    -- Notification client (ex : exports['ox_lib']:notify({ description = message }))
    Config.Hooks.Notify = function(message)
        ESX.ShowNotification(message, nil, nil, 'gang')
    end

    -- Alerte police lors d'une vente (si Activities.PoliceAlert) : coords = position du joueur
    Config.Hooks.PoliceAlert = function(coords, message)
        -- ex: TriggerServerEvent('esx_outlawalert:drugsInProgress', { x = coords.x, y = coords.y, z = coords.z })
    end

    -- Récupère les vêtements actuels du joueur -> cb(table)
    Config.Hooks.GetClothes = function(cb)
        TriggerEvent('skinchanger:getSkin', function(skin) cb(skin) end)
    end

    -- Applique une tenue (table de clés ClothesKeys)
    Config.Hooks.ApplyClothes = function(clothes)
        TriggerEvent('skinchanger:getSkin', function(skin)
            TriggerEvent('skinchanger:loadClothes', skin, clothes)
        end)
    end

    -- Remet la tenue civile
    Config.Hooks.RestoreCivil = function()
        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
            TriggerEvent('skinchanger:loadSkin', skin)
        end)
    end

    -- Appelé après le spawn d'un véhicule de gang (donner les clés...)
    Config.Hooks.OnVehicleSpawned = function(vehicle, plate)
        -- ex: exports['vehicle_keys']:GiveKeys(plate)
    end
end

-- ═══════════════════════════════ Réglages modifiables en jeu (/gangbuilder → Paramètres) ═══════════════════════════════
-- Description de chaque réglage : l'interface de Paramètres est générée à partir de cette liste (Config.Schema), et le serveur
-- valide chaque valeur avec les mêmes règles (type, min, max). Pour ajouter un réglage : ajoute-le ici, il apparaît tout seul en jeu.
--   t = 'int' | 'num' | 'bool' | 'str' | 'enum' (opts) | 'list' (liste de textes, pat = motif Lua) | 'color' (R, G, B)
--   server = true : réglage serveur (non envoyé aux clients)
local function opts(...) local o = {} for _, v in ipairs({ ... }) do o[#o + 1] = { v[1], v[2] } end return o end

Config.Schema = {
    { id = 'general', label = 'Général', fields = {
        { key = 'DrawDistance', label = 'Affichage des markers (m)', t = 'num', min = 3, max = 100 },
        { key = 'InteractDistance', label = 'Interaction (m)', t = 'num', min = 0.5, max = 6 },
        { key = 'ServerDistance', label = 'Tolérance serveur (m, anti-triche)', t = 'num', min = 2, max = 60, server = true },
        { key = 'TargetDistance', label = 'Joueur → joueur (m)', t = 'num', min = 1, max = 20 },
        { key = 'MaxGangs', label = 'Gangs max (0 = illimité)', t = 'int', min = 0, max = 500, server = true },
        { key = 'MaxGrades', label = 'Grades max par gang', t = 'int', min = 1, max = 50, server = true },
        { key = 'MaxPoints', label = 'Points max par gang', t = 'int', min = 1, max = 300, server = true },
        { key = 'MaxItemsPerPoint', label = 'Objets max par point', t = 'int', min = 1, max = 300, server = true },
        { key = 'PlatePrefixLength', label = 'Longueur préfixe plaque', t = 'int', min = 1, max = 4, server = true },
        { key = 'UseGangColor', label = 'Markers aux couleurs du gang', t = 'bool' },
        { key = 'Inventory', label = 'Inventaire', t = 'enum', server = true, opts = opts({ 'auto', 'Automatique' }, { 'ox', 'ox_inventory' }, { 'esx', 'ESX' }) },
        { key = 'AllowedGroups', label = 'Groupes autorisés (le builder)', t = 'list', pat = '^[%w_%-]+$', max = 10, server = true },
        { key = 'AcePermission', label = 'Permission ACE (optionnel)', t = 'str', max = 60, server = true },
        { key = 'RestartResources', label = 'Ressources à redémarrer après un changement de gang', t = 'list', pat = '^[%w_%-%.]+$', max = 8, server = true },
    } },
    { id = 'gang', label = 'Gangs', fields = {
        { key = 'Gang.MaxMembers', label = 'Membres max par gang (0 = illimité)', t = 'int', min = 0, max = 500, server = true },
        { key = 'Gang.RecruitGrade', label = 'Grade donné aux recrues', t = 'int', min = 0, max = 50, server = true },
        { key = 'Gang.AllowLeave', label = 'Un membre peut quitter son gang (F7)', t = 'bool', server = true },
        { key = 'Gang.RecruitOnlyUnassigned', label = 'Recruter uniquement des joueurs sans job2 (jamais d\'écrasement)', t = 'bool', server = true },
        { key = 'Gang.ProtectBoss', label = 'Le bureau ne peut pas toucher aux autres membres du bureau', t = 'bool', server = true },
        { key = 'ActionRules.SearchRequiresCuffed', label = 'Fouille : cible menottée obligatoire', t = 'bool', server = true },
        { key = 'ActionRules.EscortRequiresCuffed', label = 'Escorte : cible menottée obligatoire', t = 'bool', server = true },
    } },
    { id = 'treasury', label = 'Trésorerie', fields = {
        { key = 'Treasury.Enabled', label = 'Trésorerie de gang activée', t = 'bool', server = true },
        { key = 'Treasury.AllowDeposit', label = 'Dépôts autorisés', t = 'bool', server = true },
        { key = 'Treasury.AllowWithdraw', label = 'Retraits autorisés', t = 'bool', server = true },
        { key = 'Treasury.DepositDirty', label = 'Argent sale autorisé (dépôt / retrait)', t = 'bool', server = true },
        { key = 'Treasury.MaxTransaction', label = 'Plafond par opération ($)', t = 'int', min = 1, max = 1000000000, server = true },
        { key = 'Treasury.StartMoney', label = 'Argent offert à la création ($)', t = 'int', min = 0, max = 1000000000, server = true },
        { key = 'Dirty.Mode', label = 'Argent sale : type', t = 'enum', server = true, opts = opts({ 'account', 'Compte ESX' }, { 'item', 'Objet d\'inventaire' }) },
        { key = 'Dirty.Name', label = 'Argent sale : compte / objet', t = 'str', max = 40, server = true },
    } },
    { id = 'salary', label = 'Salaires', fields = {
        { key = 'Salary.Enabled', label = 'Payer les salaires de job2 (désactive si ton ES les paie déjà)', t = 'bool', server = true },
        { key = 'Salary.IntervalMinutes', label = 'Intervalle (minutes)', t = 'int', min = 1, max = 1440, server = true },
        { key = 'Salary.Source', label = 'Payé par', t = 'enum', server = true, opts = opts({ 'treasury', 'La trésorerie du gang' }, { 'system', 'Le serveur (argent créé)' }) },
        { key = 'Salary.Account', label = 'Compte crédité', t = 'enum', server = true, opts = opts({ 'bank', 'Banque' }, { 'money', 'Liquide' }) },
        { key = 'Salary.SkipIfBroke', label = 'Trésorerie insuffisante : personne n\'est payé', t = 'bool', server = true },
    } },
    { id = 'rep', label = 'Réputation', fields = {
        { key = 'Rep.Enabled', label = 'Réputation activée', t = 'bool', server = true },
        { key = 'Rep.PerCapture', label = 'Territoire capturé', t = 'int', min = 0, max = 100000, server = true },
        { key = 'Rep.PerIncome', label = 'Revenu de territoire', t = 'int', min = 0, max = 100000, server = true },
        { key = 'Rep.PerSaleThousand', label = 'Par 1 000 $ vendus', t = 'int', min = 0, max = 100000, server = true },
        { key = 'Rep.PerLaunderThousand', label = 'Par 1 000 $ blanchis', t = 'int', min = 0, max = 100000, server = true },
        { key = 'Rep.PerProcess', label = 'Par fabrication', t = 'int', min = 0, max = 100000, server = true },
        { key = 'Rep.PerHarvest', label = 'Par récolte', t = 'int', min = 0, max = 100000, server = true },
    } },
    { id = 'territories', label = 'Territoires', fields = {
        { key = 'Territories.Enabled', label = 'Territoires activés', t = 'bool' },
        { key = 'Territories.Tick', label = 'Calcul toutes les (s)', t = 'int', min = 1, max = 10, server = true },
        { key = 'Territories.CaptureSeconds', label = 'Durée de capture (s)', t = 'int', min = 10, max = 7200, server = true },
        { key = 'Territories.MinMembers', label = 'Membres min. pour capturer', t = 'int', min = 1, max = 50, server = true },
        { key = 'Territories.OwnerBlocks', label = 'Le propriétaire présent bloque la capture', t = 'bool', server = true },
        { key = 'Territories.DecayFactor', label = 'Vitesse de retombée de la capture', t = 'num', min = 0, max = 10, server = true },
        { key = 'Territories.ProtectionMinutes', label = 'Protection après capture (min)', t = 'int', min = 0, max = 10080, server = true },
        { key = 'Territories.IncomeInterval', label = 'Intervalle des revenus (min)', t = 'int', min = 1, max = 1440, server = true },
        { key = 'Territories.Reward', label = 'Revenu par période ($)', t = 'int', min = 0, max = 100000000, server = true },
        { key = 'Territories.RewardAccount', label = 'Compte crédité', t = 'enum', server = true, opts = opts({ 'dirty', 'Argent sale du gang' }, { 'money', 'Argent propre du gang' }) },
        { key = 'Territories.MaxTerritories', label = 'Territoires max', t = 'int', min = 1, max = 500, server = true },
        { key = 'Territories.DefaultRadius', label = 'Rayon par défaut (m)', t = 'num', min = 5, max = 1000, server = true },
        { key = 'Territories.MaxRadius', label = 'Rayon max (m)', t = 'num', min = 10, max = 1000, server = true },
        { key = 'Territories.AnnounceCapture', label = 'Prévenir les gangs lors d\'une capture', t = 'bool', server = true },
        { key = 'Territories.AlertOwner', label = 'Prévenir le propriétaire quand on attaque son territoire', t = 'bool', server = true },
        { key = 'Territories.AlertCooldown', label = 'Délai entre deux alertes (s)', t = 'int', min = 10, max = 3600, server = true },
        { key = 'Territories.ShowBlips', label = 'Afficher les blips', t = 'bool' },
        { key = 'Territories.BlipSprite', label = 'Sprite de l\'icône', t = 'int', min = 0, max = 900 },
        { key = 'Territories.BlipScale', label = 'Taille de l\'icône', t = 'num', min = 0.1, max = 3 },
        { key = 'Territories.NeutralColor', label = 'Couleur d\'un territoire libre', t = 'int', min = 0, max = 85 },
        { key = 'Territories.BlipAlpha', label = 'Transparence de la zone sur la carte', t = 'int', min = 0, max = 255 },
        { key = 'Territories.DrawZone', label = 'Dessiner la zone au sol', t = 'bool' },
        { key = 'Territories.ZoneAlpha', label = 'Transparence de la zone au sol', t = 'int', min = 0, max = 255 },
    } },
    { id = 'conflicts', label = 'Affrontements', fields = {
        { key = 'Conflicts.Enabled', label = 'Affrontements activés', t = 'bool', server = true },
        { key = 'Conflicts.Duration', label = 'Durée d\'un affrontement (s)', t = 'int', min = 30, max = 3600, server = true },
        { key = 'Conflicts.Cooldown', label = 'Délai avant un nouvel affrontement (s)', t = 'int', min = 0, max = 86400, server = true },
        { key = 'Conflicts.WinnerCaptures', label = 'L\'intrus vainqueur capture le territoire', t = 'bool', server = true },
        { key = 'Conflicts.MinKillsToWin', label = 'Kills minimum pour gagner', t = 'int', min = 1, max = 100, server = true },
        { key = 'Conflicts.RepWin', label = 'Réputation du gagnant', t = 'int', min = 0, max = 100000, server = true },
        { key = 'Conflicts.RepLoss', label = 'Réputation perdue par le perdant', t = 'int', min = 0, max = 100000, server = true },
    } },
    { id = 'objectives', label = 'Missions colis', fields = {
        { key = 'Objectives.Enabled', label = 'Missions activées', t = 'bool', server = true },
        { key = 'Objectives.AutoStart', label = 'Lancement automatique', t = 'bool', server = true },
        { key = 'Objectives.Interval', label = 'Intervalle entre deux missions (min)', t = 'int', min = 5, max = 1440, server = true },
        { key = 'Objectives.MinGangsOnline', label = 'Gangs connectés requis', t = 'int', min = 1, max = 20, server = true },
        { key = 'Objectives.Duration', label = 'Durée maximale (min)', t = 'int', min = 5, max = 240, server = true },
        { key = 'Objectives.Hold', label = 'Temps à tenir dans la zone (s)', t = 'int', min = 10, max = 3600, server = true },
        { key = 'Objectives.LeaveGrace', label = 'Tolérance hors zone (s)', t = 'int', min = 0, max = 300, server = true },
        { key = 'Objectives.RevealCarrier', label = 'Montrer le porteur aux autres gangs', t = 'bool', server = true },
        { key = 'Objectives.RewardAccount', label = 'Compte crédité', t = 'enum', server = true, opts = opts({ 'dirty', 'Argent sale du gang' }, { 'money', 'Argent propre du gang' }) },
        { key = 'Objectives.Reward', label = 'Récompense ($)', t = 'int', min = 0, max = 100000000, server = true },
        { key = 'Objectives.RewardRep', label = 'Réputation gagnée', t = 'int', min = 0, max = 100000, server = true },
    } },
    { id = 'activities', label = 'Activités', fields = {
        { key = 'Activities.Grace', label = 'Part de la durée à respecter (anti-triche, 0-1)', t = 'num', min = 0.3, max = 1, server = true },
        { key = 'Activities.MaxHarvest', label = 'Quantité max par récolte', t = 'int', min = 1, max = 500, server = true },
        { key = 'Activities.MaxBatch', label = 'Fabrications max d\'un coup', t = 'int', min = 1, max = 100, server = true },
        { key = 'Activities.MaxRecipes', label = 'Recettes max par point', t = 'int', min = 1, max = 100, server = true },
        { key = 'Activities.MaxInputs', label = 'Ingrédients max par recette', t = 'int', min = 1, max = 10, server = true },
        { key = 'Activities.MaxSell', label = 'Quantité max par vente', t = 'int', min = 1, max = 1000, server = true },
        { key = 'Activities.HarvestScenario', label = 'Animation de récolte', t = 'str', max = 60 },
        { key = 'Activities.ProcessScenario', label = 'Animation de traitement', t = 'str', max = 60 },
        { key = 'Activities.LaunderScenario', label = 'Animation de blanchiment', t = 'str', max = 60 },
        { key = 'Activities.SellAccount', label = 'Vente : compte crédité par défaut', t = 'enum', server = true, opts = opts({ 'dirty', 'Argent sale' }, { 'money', 'Liquide' }, { 'bank', 'Banque' }) },
        { key = 'Activities.SellPriceVariance', label = 'Vente : variation du prix (± %)', t = 'int', min = 0, max = 90, server = true },
        { key = 'Activities.SellGangCut', label = 'Vente : part reversée au gang (%)', t = 'int', min = 0, max = 100, server = true },
        { key = 'Activities.SellCooldown', label = 'Vente : délai entre deux ventes (s)', t = 'int', min = 0, max = 3600, server = true },
        { key = 'Activities.PoliceAlert', label = 'Vente : alerte police', t = 'bool' },
        { key = 'Activities.PoliceAlertChance', label = 'Vente : chance d\'alerte (%)', t = 'int', min = 0, max = 100 },
        { key = 'Activities.LaunderFee', label = 'Blanchiment : commission (%)', t = 'int', min = 0, max = 100, server = true },
        { key = 'Activities.LaunderGangCut', label = 'Blanchiment : part de la commission pour le gang (%)', t = 'int', min = 0, max = 100, server = true },
        { key = 'Activities.LaunderMin', label = 'Blanchiment : minimum ($)', t = 'int', min = 1, max = 100000000, server = true },
        { key = 'Activities.LaunderMax', label = 'Blanchiment : maximum ($)', t = 'int', min = 1, max = 1000000000, server = true },
        { key = 'Activities.LaunderSeconds', label = 'Blanchiment : durée (s)', t = 'int', min = 2, max = 300, server = true },
    } },
    { id = 'ui', label = 'Apparence', fields = {
        { key = 'UI.Accent', label = 'Couleur d\'accentuation', t = 'color' },
    } },
}

-- Sections à éditeur dédié (non générées depuis le Schema)
Config.CustomSections = { 'pointTypes', 'gangTypes' }

-- ─────────────────────────────── Outils partagés (lecture / écriture par chemin « A.B.C ») ───────────────────────────────
local function deepcopy(v)
    if type(v) ~= 'table' then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = deepcopy(x) end
    return out
end
GBDeepCopy = deepcopy

function GBGetPath(path)
    local o = Config
    for k in path:gmatch('[^%.]+') do
        if type(o) ~= 'table' then return nil end
        o = o[k]
    end
    return o
end

function GBSetPath(path, value)
    local keys = {}
    for k in path:gmatch('[^%.]+') do keys[#keys + 1] = k end
    local o = Config
    for i = 1, #keys - 1 do
        if type(o[keys[i]]) ~= 'table' then o[keys[i]] = {} end
        o = o[keys[i]]
    end
    if type(o[keys[#keys]]) == 'table' and type(value) == 'table' then
        local dst = o[keys[#keys]]
        for k in pairs(dst) do dst[k] = nil end
        for k, v in pairs(value) do dst[k] = deepcopy(v) end
    else
        o[keys[#keys]] = deepcopy(value)
    end
end

-- Valeurs courantes d'une section du Schema : { ['Chemin.Cle'] = valeur }
function GBGet(section, clientOnly)
    if section == 'pointTypes' then return deepcopy(Config.PointTypes) end
    if section == 'gangTypes' then return deepcopy(Config.GangTypes) end
    local t = {}
    for _, sec in ipairs(Config.Schema) do
        if sec.id == section then
            for _, f in ipairs(sec.fields) do
                if not (clientOnly and f.server) then t[f.key] = deepcopy(GBGetPath(f.key)) end
            end
        end
    end
    return t
end

-- Applique une section déjà validée (modification de Config EN PLACE)
function GBSet(section, v)
    if type(v) ~= 'table' then return end
    if section == 'pointTypes' then GBSetPath('PointTypes', v) return end
    if section == 'gangTypes' then GBSetPath('GangTypes', v) return end
    for _, sec in ipairs(Config.Schema) do
        if sec.id == section then
            for _, f in ipairs(sec.fields) do
                if v[f.key] ~= nil then GBSetPath(f.key, v[f.key]) end
            end
        end
    end
end

GB_SECTIONS = {}
for _, sec in ipairs(Config.Schema) do GB_SECTIONS[#GB_SECTIONS + 1] = sec.id end
for _, id in ipairs(Config.CustomSections) do GB_SECTIONS[#GB_SECTIONS + 1] = id end

GBDefaults = {}
for _, id in ipairs(GB_SECTIONS) do GBDefaults[id] = GBGet(id) end

-- ─────────────────────────────── Tablette de gang (F7 → Tablette, contexte → Organisation) ───────────────────────────────
-- Tableau de bord, territoires, quêtes (journalières / hebdomadaires), guerres entre gangs (défis avec mise), classement, actualités.
Config.Tablet = {
    Enabled      = true,
    Command      = 'gangtablet',     -- commande pour ouvrir la tablette ('' = aucune)
    NewsMax      = 30,               -- actualités gardées en mémoire (visibles par tous les gangs)
    -- Quêtes : tirées au sort par gang (même tirage pour tous les membres), progression automatique.
    -- metric : harvested | processed | sold ($) | laundered ($) | capture | conflict_win | objective | war_win
    Quests = {
        DailyCount = 3, WeeklyCount = 2, RewardAccount = 'dirty',
        Daily = {
            { id = 'd_harvest', label = 'Approvisionnement',   desc = 'Récolter 60 produits.',          metric = 'harvested', target = 60,    reward = 400,  rep = 4 },
            { id = 'd_process', label = 'Production',          desc = 'Fabriquer 30 produits.',         metric = 'processed', target = 30,    reward = 500,  rep = 5 },
            { id = 'd_sell',    label = 'Écouler la marchandise', desc = 'Vendre pour 3 000 $.',        metric = 'sold',      target = 3000,  reward = 600,  rep = 6 },
            { id = 'd_launder', label = 'Lessive',             desc = 'Blanchir 5 000 $.',              metric = 'laundered', target = 5000,  reward = 500,  rep = 5 },
            { id = 'd_capture', label = 'Prise de territoire', desc = 'Capturer 1 territoire.',         metric = 'capture',   target = 1,     reward = 900,  rep = 12 },
            { id = 'd_win',     label = 'Garder la rue',       desc = 'Gagner 1 affrontement de zone.', metric = 'conflict_win', target = 1,  reward = 800,  rep = 10 },
        },
        Weekly = {
            { id = 'w_capture', label = 'Expansion',           desc = 'Capturer 3 territoires.',        metric = 'capture',   target = 3,     reward = 4000, rep = 40 },
            { id = 'w_object',  label = 'Colis livrés',        desc = 'Livrer 2 colis à votre coffre.', metric = 'objective', target = 2,     reward = 5000, rep = 45 },
            { id = 'w_sell',    label = 'Gros trafic',         desc = 'Vendre pour 25 000 $.',          metric = 'sold',      target = 25000, reward = 5500, rep = 40 },
            { id = 'w_war',     label = 'Guerre gagnée',       desc = 'Gagner 1 guerre contre un gang.', metric = 'war_win',  target = 1,     reward = 6000, rep = 60 },
            { id = 'w_win',     label = 'Maîtres du quartier', desc = 'Gagner 3 affrontements de zone.', metric = 'conflict_win', target = 3, reward = 4500, rep = 40 },
        },
    },
    -- Guerres entre gangs : un gang du bureau défie un autre ; chacun mise de l'argent sale ; premier à N kills (ou le plus de kills au bout du temps).
    Wars = {
        Enabled = true, Targets = { 10, 15, 25 }, Durations = { 20, 40, 60 },      -- kills à atteindre / durée (min)
        MaxStake = 50000, ProposalSeconds = 300, Cooldown = 30,                    -- mise max ($ sale), validité de la proposition (s), délai avant de se rebattre contre le même gang (min)
        RepWin = 60, RepLoss = 15, MaxKillDistance = 250.0,
    },
}
