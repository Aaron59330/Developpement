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
    or { type = 23, color = { 253, 194, 125 }, alpha = 150, scale = { x = 1.0, y = 1.0, z = 0.5 }, offset = -0.95 }
-- Tablettes (blanchiment, Go Fast, dealers à PNJ) : Required = false → les points à tablette sont accessibles sans tablette (mode de jeu « facile » du panel)
Config.Tablets = { Required = true }
Config.PedSales = { Enabled = true }   -- vente de drogue aux PNJ (dealers) : interrupteur général, modifiable en jeu (Paramètres → Vente aux PNJ)
-- ── Vente dans la rue : le joueur vend sa drogue à un PNJ de la rue avec le menu contextuel (clic sur le PNJ → « Vendre de la drogue ») ──
-- Tout est décidé côté serveur (acceptation, quantité, prix, paiement, limites). Activée seulement si Config.PedSales.Enabled l'est aussi.
Config.StreetSales = {
    Enabled        = true,
    RequireTablet  = true,            -- exige la tablette vendeur (en vente chez le marchand, avec les tablettes Go Fast et blanchiment)
    TabletItem     = 'dealer_tablet',
    AcceptChance   = 60,              -- % de PNJ qui acceptent
    QtyMin         = 1,               -- quantité vendue par PNJ (tirée au hasard, limitée à ce que le joueur possède)
    QtyMax         = 3,
    PriceFactor    = 0.8,             -- prix de rue = prix du dealer (Config.Drugs, pochon) × ce facteur
    Account        = 'black_money',   -- 'black_money' | 'money' | 'bank'
    Cooldown       = 8,               -- secondes minimum entre deux ventes d'un même joueur
    MaxPerHour     = 30,              -- unités vendues par joueur et par heure (0 = illimité)
    AlertChance    = 20,              -- % d'alerte police après une vente réussie
    RefuseAlertChance = 10,           -- % d'alerte police quand le PNJ refuse
    CopsRequired   = 0,               -- policiers en service requis (0 = aucun)
    Items          = {},              -- vide = toutes les drogues du catalogue (pochons) ; sinon { { item = 'weed_pooch', label = 'Cannabis', min = 70, max = 110 }, … }
}
-- ── Pureté : le produit fabriqué dans un laboratoire interactif porte une pureté (0-100 %, métadonnée du pochon) qui change son prix de vente ──
-- Prix final = prix tiré × facteur : MinFactor à 0 % de pureté, MaxFactor à 100 %. Un produit sans pureté (récolte, ancien stock) compte pour `Default` %.
Config.Purity = { Enabled = true, Default = 50, MinFactor = 0.6, MaxFactor = 1.4 }
-- ── Vente de rue : réputation de dealer et quartiers ──
-- Réputation (par joueur, en base) : chaque unité vendue en rapporte ; chaque niveau améliore l'acceptation des PNJ et le prix.
-- Quartiers : la rue est découpée en secteurs de `Cell` mètres (ou en zones nommées `Named`). Vendre beaucoup au même endroit SATURE le secteur (prix en baisse)
-- et le rend CHAUD (plus d'alertes, moins d'acceptation) ; les deux retombent avec le temps : il faut bouger.
Config.StreetRep = {
    Enabled = true, PerUnit = 1, Levels = { 0, 40, 120, 300, 700 }, Names = { 'Petit revendeur', 'Revendeur', 'Dealer', 'Caïd', 'Baron' },
    AcceptPerLevel = 4,       -- % d'acceptation en plus par niveau au-dessus du 1
    PricePerLevel = 0.04,     -- +4 % de prix par niveau au-dessus du 1
}
Config.StreetZones = {
    Enabled = true, Cell = 300,
    SatPerUnit = 4, SatDecay = 3, MaxPriceDrop = 0.4,     -- saturation (0-100) par unité vendue, retombée par minute, baisse de prix maximale à saturation 100
    HeatPerSale = 6, HeatPerRefuse = 3, HeatDecay = 2,    -- chaleur (0-100)
    HeatAlert = 0.3, HeatAccept = 0.25,                   -- % d'alerte en plus / % d'acceptation en moins par point de chaleur
    Named = {},               -- zones nommées facultatives : { { name = 'Grove Street', coords = vector3(0.0, 0.0, 0.0), radius = 150.0, demand = 1.2 } } (demand : prix ×)
}
-- ── Perquisitions et saisies : un policier fouille un joueur (menu contextuel → Perquisition) et saisit drogue + argent sale ──
-- Les drogues vont dans le casier de preuves (/preuves), l'argent sale est reversé à la société de police. Tout est enregistré (/saisies).
Config.Seizure = {
    Enabled = true,
    Distance = 3.0,                   -- distance maximale policier ↔ suspect
    Cooldown = 4,                     -- secondes entre deux saisies d'un même policier
    SeizeBlackMoney = true,           -- saisir aussi l'argent sale
    Society = 'society_police',       -- compte société qui reçoit l'argent sale saisi ('' = personne)
    SocietyShare = 100,               -- % de l'argent sale saisi reversé à la société
    Items = {},                       -- items illégaux en plus des drogues du catalogue (récolte + pochons) : { 'lockpick', 'weapon_switchblade' }
    Evidence = true,                  -- les objets saisis vont dans le casier de preuves (sinon : détruits)
    StashSlots = 200, StashWeight = 500000,
}
-- Marché noir : un vendeur change de lieu et de stock à chaque rotation (/marchenoir pour le trouver, /acheter <n°> [quantité])
Config.BlackMarket = {
    Enabled = true,
    RotationHours = 24,            -- durée d'une rotation (lieu + stock + prix)
    OffersPerRotation = 4,         -- produits proposés
    PriceMin = 0.8, PriceMax = 1.4,   -- le prix varie entre ces multiplicateurs
    PerPlayerLimit = 3,            -- quantité maximale par produit et par joueur et par rotation
    Account = 'black_money',       -- compte débité
    Radius = 4.0,
    AlertChance = 10,              -- % de chance qu'un achat alerte la police
    Locations = {
        { label = 'Entrepôt du port',      hint = 'près des conteneurs du port',          coords = { x = 1000.2, y = -2527.5, z = 28.3 } },
        { label = 'Casse auto',            hint = 'du côté de la casse de La Mesa',        coords = { x = 1127.6, y = -2024.9, z = 31.5 } },
        { label = 'Ruelle de Vinewood',    hint = 'dans une ruelle de Vinewood',           coords = { x = 357.6, y = 288.6, z = 103.2 } },
        { label = 'Parking de Sandy',      hint = 'sur un parking à Sandy Shores',         coords = { x = 1698.1, y = 3757.9, z = 34.7 } },
    },
    Items = {   -- price = prix de base ($ sale), stock = quantité maximale, rare = mis en avant
        { item = 'lockpick',      label = 'Crochet',          price = 400,  stock = 10 },
        { item = 'WEAPON_SWITCHBLADE', label = 'Couteau à cran', price = 1800, stock = 3 },
        { item = 'WEAPON_PISTOL', label = 'Pistolet',         price = 9000, stock = 2, rare = true },
        { item = 'armor',        label = 'Gilet pare-balles', price = 2500, stock = 4 },
        { item = 'radio',         label = 'Radio',            price = 600,  stock = 6 },
    },
}

-- Contrats de livraison : /contrat donne une livraison chronométrée, payée en argent sale
Config.Contracts = {
    Enabled = true,
    Account = 'black_money',
    BaseReward = 600, PerKm = 900,   -- paiement = base + prime au kilomètre
    FastRatio = 0.6, FastBonus = 40, -- livré en moins de 60 % du temps → +40 %
    AvgSpeed = 18,                   -- m/s utilisés pour calculer le temps imparti
    TimeMargin = 1.5, MinSeconds = 90,
    MinDistance = 300,
    Radius = 15.0,
    Cooldown = 120,                  -- secondes entre deux contrats
    AlertChance = 25,                -- % de chance d'alerter la police au départ
    Destinations = {
        { label = 'Marina de Del Perro', coords = { x = -1850.3, y = -1236.4, z = 8.6 } },
        { label = 'Pont de Tataviam',    coords = { x = 1735.6, y = 4713.5, z = 42.0 } },
        { label = 'Raffinerie de Sandy', coords = { x = 2742.3, y = 3438.8, z = 55.5 } },
        { label = 'Quartier de Strawberry', coords = { x = 98.3, y = -1936.0, z = 20.8 } },
        { label = 'Gare de Davis',       coords = { x = 457.1, y = -1717.7, z = 29.1 } },
        { label = 'Parc de Mirror Park', coords = { x = 1086.2, y = -241.0, z = 69.1 } },
    },
}

-- Casier judiciaire : /casier <id> et /inculper <id> <amende> <motif> (police)
Config.Record = {
    Enabled = true,
    AutoSeizure = true,          -- chaque saisie ajoute une ligne au casier
    MaxFine = 50000,
    Distance = 6.0,              -- distance maximale policier ↔ suspect pour /inculper
    Society = 'society_police',  -- compte société qui reçoit les amendes ('' = personne)
    -- Récidive : chaque infraction récente aggrave les amendes et les peines de prison
    Recidive = { Enabled = true, PercentPerPrior = 20, MaxPercent = 100, WindowDays = 30 },
}

-- Prison : /emprisonner <id> <minutes> <motif> (police), /liberer <id>. Le détenu peut travailler pour réduire sa peine.
Config.Prison = {
    Enabled = true,
    Coords = { x = 1690.0, y = 2591.0, z = 45.6 },
    ExitCoords = { x = 1848.0, y = 2586.0, z = 45.7 },
    Radius = 60.0,               -- au-delà, le détenu est ramené
    MaxMinutes = 60,
    Work = {
        Reduce = 30,             -- secondes retirées par travail effectué
        Cooldown = 45,           -- secondes entre deux travaux
        Spots = {
            { label = 'Cuisine', coords = { x = 1699.0, y = 2576.0, z = 45.6 } },
            { label = 'Atelier', coords = { x = 1706.0, y = 2606.0, z = 45.6 } },
            { label = 'Buanderie', coords = { x = 1676.0, y = 2600.0, z = 45.6 } },
        },
    },
    MaxReductionPercent = 50,    -- le travail ne peut retirer que cette part de la peine
    ArrestBonus = { Enabled = true, PerPrior = 150, Max = 1500, Account = 'bank' },   -- prime au policier qui arrête un récidiviste
}

-- Informateurs : des PNJ qui vendent des tuyaux (/indic puis /info <sujet>)
Config.Informants = {
    Enabled = true,
    Radius = 3.0,
    Locations = {
        { label = 'Ruelle de Davis',  coords = { x = 111.0, y = -1730.0, z = 30.1 } },
        { label = 'Bar de Sandy',     coords = { x = 1982.0, y = 3053.0, z = 47.2 } },
        { label = 'Port de Paleto',   coords = { x = -276.0, y = 6636.0, z = 7.5 } },
    },
    Offers = {
        blackmarket = { label = 'Où est le marché noir ?', price = 2500 },
        contract    = { label = 'Livraison suspecte en cours (police)', price = 1500, police = true },
    },
}

-- Planques : /planque (créer / ouvrir), /fouillerplanque (police)
Config.Stashes = {
    Enabled = true,
    Max = 2,                     -- planques par joueur
    Slots = 20, Weight = 50000,
    ExpireDays = 14,             -- une planque oubliée disparaît (0 = jamais)
    SearchRadius = 5.0,          -- rayon de fouille de la police
    FindChance = 35,             -- % de chance de base (diminue avec la distance)
    SearchCooldown = 20,
    MinCops = 0,
}

Config.UI = { Accent = (PickaxTheme and PickaxTheme.rgb) or { 253, 194, 125 } }   -- couleur d'accentuation (modifiable en jeu : Paramètres → Apparence)

-- ─────────────────────────────── Types de modules ───────────────────────────────
Config.Types = {
    drug    = { label = 'Drogues',     one = 'Filière de drogue', icon = 'flask',  sub = 'Récolte, laboratoires, vente, blanchiment' },
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
    return { kind = 'sell', reveal = { enabled = true, item = 'dealer_tablet' }, label = label, blip = false, ped = ped('g_m_y_mexgoon_01', 'WORLD_HUMAN_DRUG_DEALER'), access = { jobs = {}, item = '' }, copsRequired = 0, alertChance = 5,
        sell = { currency = currency or 'black_money', maxPerHour = 60, items = items } }
end
local launder = { kind = 'launder', reveal = { enabled = true, item = 'launder_tablet' }, label = 'Blanchiment', blip = false, ped = ped('a_m_m_business_01'), access = { jobs = {}, item = '' }, copsRequired = 0, alertChance = 0,
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
            sell('Dealer — cannabis', { { item = 'weed_pooch', min = 90, max = 140 } }),
        },
    },
    coke = {
        label = 'Cocaïne', icon = 'flask',
        settings = { note = 'Plantation → laboratoire (propriété) → vente' },
        points = {
            harvest('Plantation de coca', 'coke', 8, 'harvest', { max = 4, plant = { enabled = true, seed = 'coke_seed', seedCount = 1, growMinutes = 45, plantSeconds = 8, small = '', medium = '', large = '' } }),
            sell('Dealer — cocaïne', { { item = 'coke_pooch', min = 220, max = 320 } }),
        },
    },
    meth = {
        label = 'Méthamphétamine', icon = 'flask',
        settings = { note = 'Produits chimiques → laboratoire → vente' },
        points = {
            harvest('Entrepôt de produits chimiques', 'meth', 10, 'pickup', { max = 3 }),
            sell('Dealer — meth', { { item = 'meth_pooch', min = 320, max = 450 } }),
        },
    },
    opium = {
        label = 'Opium / Héroïne', icon = 'flask',
        settings = { note = 'Pavot → raffinage → vente' },
        points = {
            harvest('Champ de pavot', 'opium', 7, 'harvest'),
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
            alert = { chance = 60, delay = 20, label = 'Go Fast suspecté' }, tablet = { enabled = true, item = 'gofast_tablet' } },
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
