Config = {}
-- Taille des blips par défaut : celle de tout le serveur (pickax_core/config.lua → Config.GlobalBlip.Scale), sinon la valeur donnée.
-- Un blip réglé en jeu dans un builder garde sa taille.
local function PK_BSF(default) return (PickaxTheme and PickaxTheme.blipScale) or default end

-- ─────────────────────────────── Général ───────────────────────────────
Config.AllowedGroups   = { '_dev', 'admin', 'superadmin' }   -- groupes ESX autorisés à ouvrir le builder
Config.AcePermission   = 'illegalbuilder.admin'                -- (optionnel) permission ACE alternative
Config.Command         = 'illegalbuilder'                      -- /illegalbuilder ouvre le builder
Config.OpenKey         = false                               -- touche pour ouvrir le builder sans taper la commande (ex : 'F6') — utile si un autre script bloque le chat

Config.DrawDistance     = 18.0   -- distance d'affichage des markers
Config.InteractDistance = 1.8    -- distance pour interagir (E)
Config.ServerDistance   = 14.0   -- tolérance côté serveur (anti-triche)
Config.PedDistance      = 60.0   -- distance d'apparition des PNJ

-- Dialogue du PNJ (ressource pickax_dialog) : quand un point a un PNJ, il écrit un message avec Accepter / Refuser avant d'ouvrir le service.
-- Activable pour tout le serveur ici, et point par point dans le builder (carte « PNJ » → « Dialogue du PNJ »).
Config.Dialog = {
    Enabled = true,          -- false = aucun dialogue nulle part
    Default = true,          -- état par défaut des points déjà créés avant cette option
    Texts = {                -- texte par défaut : 'type.kind' (modifiable par point dans le builder)
        ['drug.sell']      = 'Psst… tu as de la marchandise à me vendre ?',
        ['drug.launder']   = 'Tu veux blanchir de l\'argent ? Je prends ma commission.',
        default            = 'Bonjour, que puis-je faire pour vous ?',
    },
}

Config.Inventory   = 'auto'      -- 'auto' | 'ox' | 'esx'
Config.Target      = 'none'      -- 'none' (marker + touche E) | 'ox_target' (zone cliquable, en plus du marker)
Config.InteractKey = 38          -- E
Config.CancelKey   = 73          -- X : annule une action en cours (récolte, fabrication, braquage...)
Config.Currency    = '$'
Config.Webhook     = ''          -- webhook Discord (logs) — vide pour désactiver
Config.ImagePath   = 'nui://ox_inventory/web/images/%s.png'   -- images des items (vide pour désactiver)

-- Métiers considérés comme « police » (comptage pour les braquages / drogues + alertes)
Config.PoliceJobs = { 'police', 'sheriff' }

-- Limites (sécurité)
Config.Max = { Entities = 400, Points = 60, Fleet = 60, Recipes = 25, Items = 30 }

-- Mini-jeu (perçage, piratage...) : 'auto' = ox_lib skillCheck si démarré, 'none' = désactivé
Config.Minigame = 'auto'
Config.MinigameDifficulty = { 'easy', 'easy', 'medium' }

Config.Payments = {
    cash        = { label = 'Espèces',        account = 'money' },
    bank        = { label = 'Carte bancaire', account = 'bank' },
    black_money = { label = 'Argent sale',    account = 'black_money' },
}


-- ─────────────────────────────── Apparence ───────────────────────────────
-- Marker par défaut : celui de tout le serveur (pickax_core/config.lua → Config.GlobalMarker) ; réglable ensuite en jeu (prioritaire)
local PK_MK = PickaxTheme and PickaxTheme.marker
Config.Marker = PK_MK and { type = PK_MK.type, color = { PK_MK.color[1], PK_MK.color[2], PK_MK.color[3] }, alpha = PK_MK.alpha, scale = { x = PK_MK.scale.x, y = PK_MK.scale.y, z = PK_MK.scale.z }, offset = -0.95 }
    or { type = 25, color = { 64, 224, 208 }, alpha = 140, scale = { x = 0.9, y = 0.9, z = 0.6 }, offset = -0.95 }
Config.UI = { Accent = (PickaxTheme and PickaxTheme.rgb) or { 0, 164, 255 } }   -- couleur d'accentuation (modifiable en jeu : Paramètres → Apparence)

-- ─────────────────────────────── Types de modules ───────────────────────────────
Config.Types = {
    drug    = { label = 'Drogues & labos',     one = 'Filière de drogue', icon = 'flask',  sub = 'Récolte, laboratoires, vente, blanchiment' },
    robbery = { label = 'Braquages',           one = 'Braquage',          icon = 'mask',   sub = 'Supérettes, banques, bijouteries...' },
    gofast  = { label = 'Go Fast',             one = 'Go Fast',           icon = 'car',    sub = 'Livraison illégale en véhicule : départ, sortie du véhicule, points de livraison' },
}
Config.TypeOrder = { 'drug', 'robbery', 'gofast' }

-- ─────────────────────────────── PNJ ───────────────────────────────
Config.PedScenarios = {
    { id = 'WORLD_HUMAN_STAND_IMPATIENT', label = 'Debout, patient' },
    { id = 'WORLD_HUMAN_CLIPBOARD',       label = 'Bloc-notes' },
    { id = 'WORLD_HUMAN_AA_COFFEE',       label = 'Café' },
    { id = 'WORLD_HUMAN_SMOKING',         label = 'Fume' },
    { id = 'WORLD_HUMAN_GUARD_STAND',     label = 'Garde' },
    { id = 'WORLD_HUMAN_HANG_OUT_STREET', label = 'Appuyé' },
    { id = 'WORLD_HUMAN_DRUG_DEALER',     label = 'Dealer' },
    { id = '',                            label = 'Aucune animation' },
}

-- ─────────────────────────────── Animations des actions (récolte, fabrication, braquage...) ───────────────────────────────
-- scenario = animation « scénario » GTA ; dict/clip = animation classique (en boucle pendant l'action)
Config.Animations = {
    { id = 'none',     label = 'Aucune' },
    { id = 'harvest',  label = 'Récolte (plantation)',   scenario = 'WORLD_HUMAN_GARDENER_PLANT' },
    { id = 'pickup',   label = 'Ramasser',               dict = 'pickup_object', clip = 'pickup_low' },
    { id = 'inspect',  label = 'Inspecter (plantes)',    dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_crouch_checkingleaves_idle_01_inspector' },
    { id = 'repair',   label = 'Bricoler / mélanger',    dict = 'mini@repair', clip = 'fixing_a_ped' },
    { id = 'clipboard', label = 'Bloc-notes / emballer', scenario = 'WORLD_HUMAN_CLIPBOARD' },
    { id = 'cook',     label = 'Cuisiner',               scenario = 'PROP_HUMAN_BBQ' },
    { id = 'weld',     label = 'Soudure',                scenario = 'WORLD_HUMAN_WELDING' },
    { id = 'drill',    label = 'Perceuse',               scenario = 'WORLD_HUMAN_CONST_DRILL' },
    { id = 'hack',     label = 'Piratage',               dict = 'mp_prison_break', clip = 'hack_loop' },
    { id = 'lockpick', label = 'Crochetage',             dict = 'missheistfbisetup1', clip = 'hassle_intro_loop_f' },
    { id = 'till',     label = 'Vider la caisse',        dict = 'oddjobs@shop_robbery@rob_till', clip = 'loop' },
    { id = 'safe',     label = 'Coffre-fort',            dict = 'mini@safe_cracking', clip = 'idle_base' },
    { id = 'clean',    label = 'Nettoyer',               scenario = 'WORLD_HUMAN_MAID_CLEAN' },
    { id = 'hammer',   label = 'Marteler',               scenario = 'WORLD_HUMAN_HAMMERING' },
    { id = 'search',   label = 'Fouiller',               dict = 'amb@prop_human_bum_bin@base', clip = 'base' },
    { id = 'fuel',     label = 'Faire le plein',         dict = 'timetable@gardener@filling_can', clip = 'gar_ig_5_filling_can' },
}

-- ─────────────────────────────── Hooks (adapter à ton serveur) ───────────────────────────────
-- ─────────────────────────────── Hooks (adapter à ton serveur) ────────────────────────
if IsDuplicityVersion() then
    -- Alerte police : retourne true si tu gères toi-même l'alerte (ps-dispatch, cd_dispatch, qs-dispatch...). Sinon l'alerte intégrée est utilisée.
    -- Config.AlertHook = function(coords, title, message) exports['ps-dispatch']:CustomAlert({ coords = coords, message = title }) return true end
    Config.AlertHook = nil

    -- Où lire la liste des job2 / gangs pour l'éditeur (ESX.GetJobs2() est utilisé s'il existe)
    Config.Jobs2 = { table = 'jobs2', gradesTable = 'job2_grades', gradesNameCol = 'job2_name' }
end

-- ═══════════════════════════════ MODÈLES (templates) ═══════════════════════════════
-- Chaque modèle crée un module pré-rempli (modifiable ensuite à 100 % en jeu).
-- Les positions (coords) sont à définir en jeu : /illegalbuilder → Emplacements → « Mode placement ».
-- Items inexistants sur ton serveur : un avertissement s'affiche dans le builder (ajuste les noms à ton inventaire).

local function ped(model, scenario) return { enabled = true, model = model, scenario = scenario or 'WORLD_HUMAN_STAND_IMPATIENT' } end
local noPed = { enabled = false, model = '', scenario = '' }

Config.Templates = {}

-- ─────────────────────────────── Garages ───────────────────────────────

-- ─────────────────────────────── Fourrières ───────────────────────────────

-- ─────────────────────────────── Locations de véhicules ───────────────────────────────

-- ─────────────────────────────── Stations essence ───────────────────────────────

-- ─────────────────────────────── Zones PVP ───────────────────────────────

-- ─────────────────────────────── Course poursuite ───────────────────────────────

-- ─────────────────────────────── Occasion (annonces) ───────────────────────────────

-- ─────────────────────────────── Portes ───────────────────────────────

-- ─────────────────────────────── Serruriers ───────────────────────────────

-- ─────────────────────────────── Stations de lavage ───────────────────────────────

-- ─────────────────────────────── Banques ───────────────────────────────

-- ─────────────────────────────── Auto-écoles ───────────────────────────────


-- ─────────────────────────────── Drogues ───────────────────────────────
local function harvest(label, item, time, anim, extra)
    local p = { kind = 'harvest', label = label, blip = false, ped = noPed, access = { jobs = {}, item = '' }, copsRequired = 0, alertChance = 0,
        harvest = { item = item, min = 2, max = 5, time = time, anim = anim or 'harvest', tool = { item = '', consume = false }, cooldown = 10, maxUses = 0, regen = 300 } }
    for k, v in pairs(extra or {}) do p.harvest[k] = v end
    return p
end
local function process(label, recipes, anim)
    for _, r in ipairs(recipes) do r.anim = r.anim or anim or 'repair' r.failChance = r.failChance or 0 r.tool = r.tool or { item = '', consume = false } end
    return { kind = 'process', label = label, blip = false, ped = noPed, access = { jobs = {}, item = '' }, copsRequired = 0, alertChance = 0, recipes = recipes }
end
local function sell(label, items, currency)
    return { kind = 'sell', label = label, blip = false, ped = ped('g_m_y_mexgoon_01', 'WORLD_HUMAN_DRUG_DEALER'), access = { jobs = {}, item = '' }, copsRequired = 0, alertChance = 5,
        sell = { currency = currency or 'black_money', maxPerHour = 60, items = items } }
end
local launder = { kind = 'launder', label = 'Blanchiment', blip = false, ped = ped('a_m_m_business_01'), access = { jobs = {}, item = '' }, copsRequired = 0, alertChance = 0,
    launder = { rate = 70, min = 500, max = 50000, from = 'black_money', to = 'money', maxPerHour = 50000 } }

-- Catalogue des drogues : choisies d'un clic dans l'éditeur (plus besoin de taper les noms d'items).
-- raw = produit brut (récolte), pooch = produit fini (pochon), seed = graines (nil = pas de plantation), recipe = recette de base, price = prix du dealer.
Config.Drugs = {
    weed  = { label = 'Cannabis',          raw = 'weed',  pooch = 'weed_pooch',  seed = 'weed_seed',  grow = 30, plantSeconds = 6, recipe = { count = 3, time = 8,  fail = 0,  anim = 'inspect',  label = 'Pochon de cannabis' }, price = { raw = { 25, 45 },  pooch = { 90, 140 } } },
    coke  = { label = 'Cocaïne',           raw = 'coke',  pooch = 'coke_pooch',  seed = 'coke_seed',  grow = 45, plantSeconds = 8, recipe = { count = 3, time = 12, fail = 5,  anim = 'clipboard', label = 'Sachet de cocaïne' }, price = { raw = { 70, 110 }, pooch = { 220, 320 } } },
    meth  = { label = 'Méthamphétamine',   raw = 'meth',  pooch = 'meth_pooch',  seed = nil,          grow = 30, plantSeconds = 6, recipe = { count = 4, time = 15, fail = 10, anim = 'cook',      label = 'Sachet de meth' },      price = { raw = { 90, 140 }, pooch = { 320, 450 } } },
    opium = { label = 'Opium / Héroïne',   raw = 'opium', pooch = 'opium_pooch', seed = 'opium_seed', grow = 40, plantSeconds = 7, recipe = { count = 3, time = 12, fail = 0,  anim = 'repair',    label = 'Dose d\'héroïne' },     price = { raw = { 80, 120 }, pooch = { 280, 380 } } },
}
Config.DrugOrder = { 'weed', 'coke', 'meth', 'opium' }

Config.Templates.drug = {
    weed = {
        label = 'Cannabis', icon = 'leaf',
        settings = { note = 'Champ → séchage → vente' },
        points = {
            harvest('Champ de cannabis', 'weed', 6, 'harvest', { plant = { enabled = true, seed = 'weed_seed', seedCount = 1, growMinutes = 30, plantSeconds = 6, small = '', medium = '', large = '' } }),
            process('Séchage & conditionnement', { { label = 'Pochon de cannabis', inputs = { { item = 'weed', count = 3 } }, outputs = { { item = 'weed_pooch', count = 1 } }, time = 8 } }, 'inspect'),
            sell('Dealer — cannabis', { { item = 'weed_pooch', min = 90, max = 140 } }),
        },
    },
    coke = {
        label = 'Cocaïne', icon = 'flask',
        settings = { note = 'Feuilles de coca → laboratoire → vente' },
        points = {
            harvest('Plantation de coca', 'coke', 8, 'harvest', { max = 4, plant = { enabled = true, seed = 'coke_seed', seedCount = 1, growMinutes = 45, plantSeconds = 8, small = '', medium = '', large = '' } }),
            process('Laboratoire de cocaïne', { { label = 'Sachet de cocaïne', inputs = { { item = 'coke', count = 3 } }, outputs = { { item = 'coke_pooch', count = 1 } }, time = 12, failChance = 5 } }, 'clipboard'),
            sell('Dealer — cocaïne', { { item = 'coke_pooch', min = 220, max = 320 } }),
        },
    },
    meth = {
        label = 'Méthamphétamine', icon = 'flask',
        settings = { note = 'Produits chimiques → laboratoire → vente' },
        points = {
            harvest('Entrepôt de produits chimiques', 'meth', 10, 'pickup', { max = 3 }),
            process('Laboratoire de meth', { { label = 'Sachet de meth', inputs = { { item = 'meth', count = 4 } }, outputs = { { item = 'meth_pooch', count = 1 } }, time = 15, failChance = 10, anim = 'cook' } }, 'cook'),
            sell('Dealer — meth', { { item = 'meth_pooch', min = 320, max = 450 } }),
        },
    },
    opium = {
        label = 'Opium / Héroïne', icon = 'flask',
        settings = { note = 'Pavot → raffinage → vente' },
        points = {
            harvest('Champ de pavot', 'opium', 7, 'harvest'),
            process('Raffinerie', { { label = 'Dose d\'héroïne', inputs = { { item = 'opium', count = 3 } }, outputs = { { item = 'opium_pooch', count = 1 } }, time = 12 } }, 'repair'),
            sell('Dealer — héroïne', { { item = 'opium_pooch', min = 280, max = 380 } }),
        },
    },
    launder = {
        label = 'Blanchiment d\'argent', icon = 'dollar',
        settings = { note = 'Argent sale → argent propre (commission)' },
        points = { launder },
    },
    custom = {
        label = 'Filière personnalisée', icon = 'flask',
        settings = { note = '' },
        points = {},
    },
}

-- ─────────────────────────────── Braquages ───────────────────────────────
local function target(kind, label, time, anim, cash, items, extra)
    local p = { kind = kind, label = label, blip = false, time = time, anim = anim, minigame = false, tool = { item = '', consume = false }, cash = cash or { min = 0, max = 0 }, items = items or {} }
    for k, v in pairs(extra or {}) do p[k] = v end
    return p
end
local function clerk(model) return { kind = 'clerk', label = 'Vendeur', blip = false, ped = ped(model or 'mp_m_shopkeep_01', 'WORLD_HUMAN_STAND_IMPATIENT') } end
local function baseRob(extra)
    local s = { trigger = 'aim', weapon = true, copsRequired = 0, cooldown = 1800, duration = 240, leaveDistance = 30, coop = true, currency = 'black_money',
        requireItem = { item = '', count = 1, consume = false }, alert = { chance = 100, label = 'Braquage en cours' },
        guards = { enabled = false, model = 's_m_m_security_01', weapon = 'WEAPON_PISTOL', count = 0, accuracy = 30, health = 200 },
        blip = { enabled = false, sprite = 52, color = 1, scale = PK_BSF(0.8), label = '', shortRange = true } }
    for k, v in pairs(extra or {}) do s[k] = v end
    return s
end

Config.Templates.robbery = {
    store = {
        label = 'Supérette (24/7)', icon = 'cart',
        settings = baseRob({ copsRequired = 1, cooldown = 1200, duration = 180, note = 'Braque le vendeur en le menaçant avec une arme' }),
        points = { clerk(), target('register', 'Caisse 1', 12, 'till', { min = 300, max = 900 }), target('register', 'Caisse 2', 12, 'till', { min = 300, max = 900 }),
            target('safe', 'Coffre de l\'arrière-boutique', 45, 'safe', { min = 1500, max = 3500 }, {}, { minigame = true }) },
    },
    liquor = {
        label = 'Magasin d\'alcool', icon = 'utensils',
        settings = baseRob({ copsRequired = 1, cooldown = 1500, duration = 180 }),
        points = { clerk('s_m_m_linecook'), target('register', 'Caisse', 12, 'till', { min = 400, max = 1100 }), target('loot', 'Étagère de spiritueux', 8, 'pickup', { min = 0, max = 0 }, { { item = 'whisky', min = 1, max = 3, chance = 80 }, { item = 'vodka', min = 1, max = 3, chance = 80 } }) },
    },
    gas = {
        label = 'Station-service', icon = 'fuel',
        settings = baseRob({ copsRequired = 1, cooldown = 1500, duration = 180 }),
        points = { clerk('a_m_m_hillbilly_01'), target('register', 'Caisse', 12, 'till', { min = 250, max = 800 }), target('safe', 'Petit coffre', 40, 'safe', { min = 900, max = 2200 }, {}, { minigame = true }) },
    },
    bank = {
        label = 'Banque (coffre)', icon = 'lock',
        settings = baseRob({ trigger = 'interact', weapon = false, copsRequired = 4, cooldown = 5400, duration = 600, leaveDistance = 45,
            requireItem = { item = 'thermite', count = 1, consume = true }, alert = { chance = 100, label = 'Braquage de banque' },
            guards = { enabled = true, model = 's_m_m_security_01', weapon = 'WEAPON_PISTOL', count = 2, accuracy = 35, health = 250 },
            blip = { enabled = false, sprite = 108, color = 1, scale = PK_BSF(0.9), label = 'Banque', shortRange = true } }),
        points = { { kind = 'start', label = 'Porte du coffre', blip = false },
            target('vault', 'Coffre principal', 90, 'drill', { min = 8000, max = 15000 }, {}, { minigame = true, tool = { item = 'drill', consume = false } }),
            target('safe', 'Casiers', 40, 'lockpick', { min = 2000, max = 4500 }, {}, { minigame = true, tool = { item = 'lockpick', consume = true } }),
            target('loot', 'Liasses de billets', 15, 'pickup', { min = 0, max = 0 }, { { item = 'markedbills', min = 3, max = 8, chance = 100 } }),
            { kind = 'guard', label = 'Garde 1', blip = false }, { kind = 'guard', label = 'Garde 2', blip = false } },
    },
    jewelry = {
        label = 'Bijouterie', icon = 'diamond',
        settings = baseRob({ trigger = 'interact', weapon = false, copsRequired = 3, cooldown = 3600, duration = 360, leaveDistance = 40, alert = { chance = 100, label = 'Cambriolage de bijouterie' },
            requireItem = { item = 'WEAPON_CROWBAR', count = 1, consume = false } }),
        points = { { kind = 'start', label = 'Entrée de service', blip = false },
            target('loot', 'Vitrine 1', 10, 'pickup', { min = 0, max = 0 }, { { item = 'diamond', min = 1, max = 2, chance = 60 }, { item = 'goldbar', min = 1, max = 1, chance = 40 } }),
            target('loot', 'Vitrine 2', 10, 'pickup', { min = 0, max = 0 }, { { item = 'diamond', min = 1, max = 2, chance = 60 }, { item = 'goldbar', min = 1, max = 1, chance = 40 } }),
            target('safe', 'Coffre', 50, 'safe', { min = 3500, max = 7000 }, {}, { minigame = true }) },
    },
    custom = {
        label = 'Braquage personnalisé', icon = 'mask',
        settings = baseRob({}),
        points = {},
    },
}


-- ─────────────────────────────── Go Fast ───────────────────────────────
-- Le joueur parle au contact (point « Départ »), reçoit un véhicule à la « Sortie » et le livre à l'un des points de « Livraison » tirés au sort.
Config.Templates.gofast = {
    classic = {
        label = 'Go Fast classique', icon = 'car',
        settings = { note = '', copsRequired = 0, cooldown = 1800, stock = 3, regenMinutes = 30, model = 'sultan', plate = 'GOFAST', account = 'black_money',
            rewardMin = 2500, rewardMax = 4000, damageBonus = true, bonusMax = 1500, timeLimit = 30, deliverRadius = 8.0,
            alert = { chance = 60, delay = 20, label = 'Go Fast suspecté' } },
        points = {
            { kind = 'gfstart', label = 'Contact Go Fast', blip = false, ped = ped('g_m_y_mexgoon_01', 'WORLD_HUMAN_SMOKING') },
            { kind = 'gfspawn', label = 'Sortie du véhicule' },
            { kind = 'gfdrop', label = 'Livraison 1' }, { kind = 'gfdrop', label = 'Livraison 2' }, { kind = 'gfdrop', label = 'Livraison 3' },
        },
    },
    custom = { label = 'Go Fast vide', icon = 'car', settings = { note = '' }, points = {} },
}

Config.VehicleTypes = {
    { id = 'car',      label = 'Voitures' },
    { id = 'bike',     label = 'Motos / vélos' },
    { id = 'boat',     label = 'Bateaux' },
    { id = 'aircraft', label = 'Aéronefs' },
}

-- ─────────────────────────────── Intoxication des laboratoires ───────────────────────────────
-- Dans le rayon d'un laboratoire (poste de travail avec « tenue obligatoire »), un joueur sans la bonne tenue s'intoxique.
-- Le niveau d'intoxication (0-100) monte tant qu'il est exposé, puis continue de monter lentement tant qu'il n'est pas soigné.
-- À 100 : mort. UN SEUL item guérit : Config.Toxic.CureItem (rien d'autre : ni kit de soin, ni réanimation).
Config.Toxic = {
    Enabled       = true,
    CureItem      = 'antidote',   -- le seul item qui guérit l'intoxication (ajouté dans ox_inventory/data/items.lua)
    Tick          = 5,            -- secondes entre deux calculs
    ExposureGain  = 6,            -- niveau gagné à chaque tick passé dans le laboratoire sans la tenue
    SickGain      = 1,            -- niveau gagné à chaque tick quand on est malade (même hors du laboratoire)
    DamageFrom    = 60,           -- à partir de ce niveau : perte de vie à chaque tick
    DamageHealth  = 4,            -- points de vie perdus par tick au-dessus de DamageFrom
    KillAt        = 100,          -- niveau de mort
    WarnAt        = { 20, 50, 80 },   -- seuils des messages d'alerte
}
