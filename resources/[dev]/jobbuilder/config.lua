Config = {}

-- ─────────────────────────────── Général ───────────────────────────────
Config.AllowedGroups   = { '_dev' }      -- groupes ESX autorisés à ouvrir le builder
Config.AcePermission   = 'jobbuilder.admin' -- (optionnel) permission ACE alternative
Config.Command         = 'jobbuilder'    -- /jobbuilder ouvre le builder
Config.JobMenuCommand  = 'jobmenu'       -- menu métier (actions, facture)
Config.JobMenuKey      = 'F6'            -- touche par défaut du menu métier

Config.DrawDistance     = 12.0   -- distance d'affichage des markers
Config.InteractDistance = 1.6    -- distance pour interagir (E)
Config.ServerDistance   = 10.0   -- tolérance côté serveur (anti-triche)
Config.TargetDistance   = 4.0    -- distance max joueur -> joueur (menottes, soins, facture...)

Config.MaxGrades = 20
Config.MaxPoints = 80
Config.MaxItemsPerPoint = 100

Config.SocietyPrefix = 'society_'  -- compte société = society_<nomdujob> (compatible esx_society / esx_addonaccount)
Config.Inventory     = 'auto'      -- 'auto' | 'ox' | 'esx'

Config.PlatePrefixLength = 3       -- plaque véhicule job : 3 lettres du job + 5 chiffres
Config.ReviveEvent = 'esx_ambulancejob:revive' -- event client déclenché pour réanimer
Config.ActionDuration = { repair = 12000, clean = 6000 }

-- Ressources redémarrées automatiquement après la création / modification / suppression d'un job.
-- Utile si ton esx_society / esx_addonaccount (ou un esx_custom qui les regroupe) charge la liste des jobs et des comptes
-- société au DÉMARRAGE : sans redémarrage, ils ne connaissent pas les jobs créés en jeu. Ex : { 'esx_custom' }
Config.RestartResources = {}

Config.Webhook = ''  -- (optionnel) webhook Discord pour les logs (argent société, armurerie, gestion employés)

-- ─────────────────────────────── Points ───────────────────────────────
-- Types de points disponibles dans le builder
-- Apparence de base commune à tous les points (modifiable en jeu : Paramètres → Markers des points) : marker 25, bleu clair turquoise
Config.PointTypes = {
    garage    = { label = 'Garage',          color = { 64, 224, 208 },  marker = 25 },
    garage_return = { label = 'Rangement véhicule', color = { 64, 224, 208 }, marker = 25, hidden = true },   -- désormais intégré au garage (carte « Rangement » de l'éditeur) ; ce type reste géré pour les anciens points
    cloakroom = { label = 'Vestiaire',       color = { 64, 224, 208 },  marker = 25 },
    armory    = { label = 'Armurerie',       color = { 64, 224, 208 },   marker = 25 },
    stash     = { label = 'Coffre',          color = { 64, 224, 208 },   marker = 25 },
    boss      = { label = 'Gestion boss',    color = { 64, 224, 208 },   marker = 25 },
    shop      = { label = 'Boutique',        color = { 64, 224, 208 },  marker = 25 },
    -- Variantes de garage (hidden = non ajoutables directement : on choisit le « type » dans l'éditeur du garage)
    garage_bike     = { label = 'Garage motos',     color = { 64, 224, 208 },  marker = 25, hidden = true },
    garage_aircraft = { label = 'Garage aéronefs',  color = { 64, 224, 208 }, marker = 25, hidden = true },
    garage_boat     = { label = 'Garage bateaux',   color = { 64, 224, 208 },   marker = 25, hidden = true },
    missions  = { label = 'Missions PNJ',    color = { 64, 224, 208 },  marker = 25 },
    showroom  = { label = 'Showroom',        color = { 64, 224, 208 },  marker = 25 },
    display   = { label = 'Véhicule expo',   color = { 64, 224, 208 }, marker = 25 },
    testdrive = { label = 'Essai routier',   color = { 64, 224, 208 },  marker = 25 },
    harvest   = { label = 'Récolte',         color = { 64, 224, 208 },  marker = 25 },
    kitchen   = { label = 'Cuisine / Bar',   color = { 64, 224, 208 },  marker = 25 },
    tuning    = { label = 'Atelier tuning',  color = { 64, 224, 208 },  marker = 25 },
}

-- Types de points réservés à certains métiers (absent = tous les jobs ; le type « Personnalisé » peut tout placer).
-- Ex. : un job EMS ne peut pas placer d'atelier tuning, de cuisine, de showroom…
JB_POINT_RULES = {
    armory = { 'police', 'ems' }, tuning = { 'mecano' }, harvest = { 'bar' }, kitchen = { 'bar' },
    showroom = { 'dealer' }, display = { 'dealer' }, testdrive = { 'dealer' },
}
function JBPointAllowed(pointType, jobType)
    local rule = JB_POINT_RULES[pointType]
    if not rule or jobType == 'custom' then return true end
    for _, t in ipairs(rule) do if t == jobType then return true end end
    return false
end

-- Types de garage : libellé + rayon de dégagement exigé à la sortie des véhicules
Config.GarageKinds = {
    car      = { label = 'Voitures',               clear = 3.0 },
    bike     = { label = 'Motos & vélos',          clear = 2.5 },
    aircraft = { label = 'Avions & hélicoptères',  clear = 9.0 },
    boat     = { label = 'Bateaux',                clear = 8.0 },
}

-- ─────────────────────────────── Actions métier (menu F6) ───────────────────────────────
Config.Actions = {
    handcuff = { label = 'Menotter / Démenotter', icon = 'fa-handcuffs',    target = true, types = { 'police' } },
    escort   = { label = 'Escorter',              icon = 'fa-people-arrows', target = true, types = { 'police' } },
    search   = { label = 'Fouiller',              icon = 'fa-magnifying-glass', target = true, types = { 'police' } },
    revive   = { label = 'Réanimer',              icon = 'fa-heart-pulse',  target = true, types = { 'ems' } },
    heal     = { label = 'Soigner',               icon = 'fa-kit-medical',  target = true, types = { 'ems' } },
    repair   = { label = 'Réparer le véhicule',   icon = 'fa-wrench',       target = false, types = { 'mecano' } },
    clean    = { label = 'Nettoyer le véhicule',  icon = 'fa-soap',         target = false, types = { 'mecano' } },
    invoice  = { label = 'Facturer',              icon = 'fa-file-invoice-dollar', target = true },
    properties = { label = 'Gestion immobilière', icon = 'fa-house',        target = false, auto = true }, -- auto pour les jobs de type realestate
    dealership = { label = 'Gestion concession',  icon = 'fa-car',          target = false, auto = true }, -- auto pour les jobs de type dealer
    government = { label = 'Gouvernement',        icon = 'fa-landmark',     target = false, auto = true }, -- auto pour les jobs de type government
    missions   = { label = 'Missions PNJ',        icon = 'fa-route',        target = false, auto = true }, -- auto si les missions sont activées pour le job
    serve      = { label = 'Vendre un produit',   icon = 'fa-utensils',     target = false, types = { 'bar' } }, -- vente directe au client (carte du job : onglet Général)
    emscalls   = { label = 'Appels EMS',          icon = 'fa-truck-medical', target = false, auto = true }, -- auto pour les jobs de type ems (liste des urgences)
    emstablet  = { label = 'Tablette médicale',   icon = 'fa-tablet',       target = false, auto = true }, -- auto pour les jobs de type ems (urgences, dossiers patients, soins, équipe)
    banktablet = { label = 'Tablette bancaire',   icon = 'fa-tablet',       target = false, auto = true }, -- auto pour les jobs de type bank (clients, prêts, guichet, frais, statistiques)
    tablet     = { label = 'Tablette',            icon = 'fa-tablet',       target = false, auto = true }, -- auto pour les jobs de type police (casiers, amendes, dispatch, carte)
    jobannounce = { label = 'Annonce entreprise', icon = 'fa-bullhorn',     target = false, auto = true }, -- auto (réglage « Annonces » du job)
}

-- ─────────────────────────────── Mort, appel des EMS, réanimation ───────────────────────────────
-- Quand un joueur meurt : écran d'inconscience, minuteur, [E] appeler les EMS (ils reçoivent un blip + une alerte à sa position), [G maintenu] réapparaître à l'hôpital.
-- Les EMS (jobs de type ems) répondent avec [Y] ou F6 → Appels EMS (GPS), puis F6 → Réanimer (massage cardiaque).
-- Mode : 'auto' = actif seulement si esx_ambulancejob n'est PAS démarré (évite deux systèmes) | 'on' = toujours | 'off' = jamais.
Config.Death = {
    Mode = 'auto',
    RespawnTime = 180,     -- secondes avant de pouvoir réapparaître à l'hôpital
    NoEmsRespawn = 45,     -- délai réduit si aucun EMS n'est en service
    CallCooldown = 30,     -- délai (s) entre deux appels d'EMS
    RespawnFee = 500,      -- frais de soins à l'hôpital ($) : soins complets (vie, faim, soif)
    UnpaidAllowed = true,  -- si le joueur n'a pas assez d'argent : on prend ce qu'il a et on le soigne quand même (false = refus)
    RestoreStatus = true,  -- remet faim et soif à 100 % à l'hôpital (esx_status)
    FeeAccount = 'bank',   -- 'bank' | 'money'
    ReviveHealth = 45,     -- % de vie rendu par une réanimation EMS
    RespawnHealth = 100,   -- % de vie rendu à la réapparition à l'hôpital
    CprSeconds = 8,        -- durée du massage cardiaque (s)
    ReviveAnim = true,     -- animation au réveil (le joueur se tord au sol puis se relève)
    OxygenHud = true,      -- petit HUD d'oxygène quand on nage sous l'eau
    OxygenWarn = 3,        -- le HUD devient rouge sous ce nombre de secondes d'air
    OxygenCustom = true,   -- réserve d'air gérée par le script (compte à rebours fiable + noyade) ; false = réserve native du jeu
    OxygenSeconds = 30,    -- durée d'air sous l'eau (s)
    OxygenDamage = 10,     -- points de vie perdus par seconde une fois l'air épuisé
    ReviveCommand = 'revive',                               -- /revive [id] : réanimer + soigner un joueur (soi-même sans id)
    ReviveGroups = { '_dev', 'admin', 'superadmin', 'mod' }, -- groupes ESX autorisés à utiliser la commande (en plus des _dev du builder)
    RevivePay = 0,         -- prime versée à l'EMS qui réanime ($, créée par le serveur)
    Hospitals = {
        { 'Hôpital Pillbox', 298.6, -584.4, 43.26, 70.0 },
        { 'Hôpital de Sandy Shores', 1839.6, 3672.9, 34.28, 210.0 },
        { 'Hôpital de Paleto Bay', -247.8, 6331.4, 32.43, 225.0 },
    },
}

-- Désactive le système de mort/EMS du builder là où un autre script gère déjà la mort (gunfight, arène, event…).  Le joueur n'a alors
-- AUCUN écran de mort du builder (le script en question garde le sien).  Chaque règle est indépendante ; une seule suffit.
Config.DeathBlock = {
    -- Exports booléens : { 'ressource', 'export' } -> true = joueur dans le gunfight.  Ex. { 'mon_gunfight', 'IsInGunfight' }
    Exports = { { 'worldbuilder', 'IsInPvpZone' } },     -- zones PVP de worldbuilder
    -- State bags du joueur (LocalPlayer.state.xxx) : s'il est vrai, la mort est ignorée.  Ex. 'inGunfight'
    StateBags = { 'inPvpZone', 'inGunfight', 'inGunFight', 'gunfight', 'inArena', 'inEvent' },
    -- Zones : { x, y, z, rayon } -> la mort dans ce rayon est ignorée.  Ex. { 100.0, -200.0, 30.0, 150.0 }
    Zones = {},
    -- Événements que ton script peut déclencher : TriggerEvent('jobbuilder:death:block', true/false)
    -- ou export : exports.jobbuilder:SetDeathBlocked(true/false)
}

-- ─────────────────────────────── Banque (jobs de type « bank ») ───────────────────────────────
-- F6 → Tablette bancaire : tableau de bord, clients (fiches, cote, notes), prêts (offre acceptée par le client, remboursement automatique),
-- guichet (dépôt / retrait avec l'accord du client), frais et services facturés, équipe.  Réglages par job : onglet Général du job.
Config.Bank = {
    MinLoan = 500, MaxLoan = 2000000,
    MinRate = 0, MaxRate = 60,          -- intérêt TOTAL en % du capital (ex. 10 % sur 10 000 $ = 1 000 $ d'intérêts)
    Terms = { 3, 5, 7, 10, 14, 21, 30 },-- nombre d'échéances proposées
    IntervalHours = 24,                 -- une échéance toutes les X heures (temps réel)
    RetryHours = 4,                     -- si le client n'a pas de quoi payer : nouvel essai après X heures
    LateFeePct = 5,                     -- pénalité (% de l'échéance) ajoutée à chaque échéance manquée
    DefaultAfter = 5,                   -- après X échéances manquées : prêt « en défaut »
    MaxActive = 2,                      -- prêts actifs maximum par client et par banque
    CheckSeconds = 60,                  -- fréquence de prélèvement des échéances (joueurs en ligne)
    MinOp = 1, MaxOp = 1000000,         -- dépôt / retrait guichet
    MinFee = 1, MaxFee = 100000,
    Ratings = { 'A', 'B', 'C', 'D', 'E' },
    RatingLimit = { A = 100, B = 70, C = 40, D = 20, E = 0 },    -- plafond d'emprunt selon la cote du client (% du plafond du job ; 0 = prêt refusé)
    Flags = { normal = 'Normal', vip = 'VIP', watch = 'Sous surveillance' },
    DefaultFees = {
        { label = 'Ouverture de compte', amount = 150 }, { label = 'Carte bancaire', amount = 80 }, { label = 'Chéquier', amount = 40 },
        { label = 'Coffre-fort personnel', amount = 500 }, { label = 'Conseil financier', amount = 200 }, { label = 'Frais de dossier', amount = 100 },
    },
}

-- ─────────────────────────────── Tablette médicale (jobs EMS) ───────────────────────────────
-- F6 → Tablette médicale : urgences en direct, dossiers patients, facturation des soins, équipe et statistiques. Réglages par job : onglet Général.
Config.Ems = {
    MinCare = 1, MaxCare = 100000,
    BloodTypes = { 'O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-' },
    DefaultCare = {
        { label = 'Consultation', amount = 150 }, { label = 'Pansement / premiers soins', amount = 250 }, { label = 'Perfusion', amount = 400 },
        { label = 'Radio / examen', amount = 500 }, { label = 'Opération', amount = 2500 }, { label = 'Transport en ambulance', amount = 600 },
    },
}

-- ─────────────────────────────── Atelier tuning (jobs mécano) ───────────────────────────────
-- Point « Atelier tuning » : le mécano ouvre la tablette devant un véhicule, prévisualise en direct et valide.
-- Facturation par job (onglet Général) : « client » (facture au joueur le plus proche, appliquée une fois payée), « société » (la société paie), « gratuit ».
-- Les modifications sont enregistrées dans owned_vehicles (propriétés ESX) pour les véhicules possédés.
Config.Tuning = {
    Radius = 6.0,          -- rayon de recherche du véhicule autour du point (par défaut, réglable par point)
    Prices = {             -- prix de base ($), multipliés par le coefficient du job (« Majoration »)
        engine = { 2000, 4000, 7000, 11000, 16000 }, brakes = { 800, 1600, 2600, 3800 }, transmission = { 1500, 3000, 5000, 7500 },
        suspension = { 600, 1200, 2000, 3000, 4200 }, armor = { 2500, 5000, 8000, 12000, 18000, 25000 },
        turbo = 4500, xenon = 450, cosmetic = 600, wheels = 900, paint = 500, pearl = 350, wheelColor = 300, neon = 700,
        tint = 300, plate = 200, smoke = 400, livery = 800, horn = 150,
    },
    -- clé de propriété ESX -> type de mod GTA
    Mods = {
        modSpoilers = 0, modFrontBumper = 1, modRearBumper = 2, modSideSkirt = 3, modExhaust = 4, modFrame = 5, modGrille = 6, modHood = 7, modFender = 8, modRightFender = 9,
        modRoof = 10, modEngine = 11, modBrakes = 12, modTransmission = 13, modHorns = 14, modSuspension = 15, modArmor = 16, modFrontWheels = 23, modBackWheels = 24,
        modPlateHolder = 25, modVanityPlate = 26, modTrimA = 27, modOrnaments = 28, modDashboard = 29, modDial = 30, modDoorSpeaker = 31, modSeats = 32, modSteeringWheel = 33,
        modShifterLeavers = 34, modAPlate = 35, modSpeakers = 36, modTrunk = 37, modHydrolic = 38, modEngineBlock = 39, modAirFilter = 40, modStruts = 41, modArchCover = 42,
        modAerials = 43, modTrimB = 44, modTank = 45, modWindows = 46, modLivery = 48,
    },
    Toggles = { modTurbo = 18, modSmokeEnabled = 20, modXenon = 22 },
}
Config.Tuning.Keys = {}   -- schéma de validation côté serveur : kind = int | bool | rgb | bool4
for k in pairs(Config.Tuning.Mods) do Config.Tuning.Keys[k] = { kind = 'int', min = -1, max = 255 } end
for k in pairs(Config.Tuning.Toggles) do Config.Tuning.Keys[k] = { kind = 'bool' } end
for _, k in ipairs({ 'plateIndex', 'color1', 'color2', 'pearlescentColor', 'wheelColor', 'wheels', 'windowTint', 'livery' }) do Config.Tuning.Keys[k] = { kind = 'int', min = -1, max = 255 } end
Config.Tuning.Keys.xenonColor = { kind = 'int', min = -1, max = 255 }
Config.Tuning.Keys.neonEnabled = { kind = 'bool4' }
Config.Tuning.Keys.neonColor = { kind = 'rgb' }
Config.Tuning.Keys.tyreSmokeColor = { kind = 'rgb' }

-- ─────────────────────────────── Tablette police ───────────────────────────────
-- Chaque job police a SA tablette (F6 → Tablette) : casiers, amendes, dispatch et carte en temps réel. Rien n'est partagé entre les jobs.
-- Valeurs modifiables en jeu : Paramètres → Police. Réglages par job : onglet Général du job (grades, catalogue d'amendes…).
Config.Police = {
    PursuitMax   = 900,      -- durée max d'une poursuite (secondes) avant arrêt automatique
    PursuitTrail = 40,       -- points de la traînée du fugitif sur la carte
    NearbyRange  = 80.0,     -- distance (m) dans laquelle un suspect peut être pris en poursuite
    RefreshMs    = 2000,     -- rafraîchissement de la carte / du dispatch (ms)
    CallCooldown = 30,       -- délai (s) entre deux appels d'un même citoyen
    MaxCalls     = 100,      -- appels gardés par job
    ClosedKeepMinutes = 30,  -- un appel clôturé disparaît de la liste après ce délai
    MinFine = 1, MaxFine = 50000,
    CallCommand  = 'appel',  -- /appel <message> : appel citoyen vers les jobs police
    PanicCommand = 'panic',  -- /panic : appel à l'aide d'un policier à ses collègues
    -- Amendes proposées par défaut aux nouveaux jobs police (modifiables ensuite par job dans le builder)
    DefaultFines = {
        { label = 'Excès de vitesse',          amount = 250 },
        { label = 'Conduite dangereuse',       amount = 600 },
        { label = 'Refus d\'obtempérer',       amount = 1500 },
        { label = 'Stationnement gênant',      amount = 150 },
        { label = 'Port d\'arme illégal',      amount = 2500 },
        { label = 'Trouble à l\'ordre public', amount = 800 },
    },
    -- Carte de la tablette : sans image, une carte schématique (grille + lieux) est dessinée.
    -- Pour une vraie carte en couleur : dépose le pack de tuiles « mapStyles » dans html/map/ (voir README) ou une image dans html/map/.
    -- Tiles : pyramide de tuiles standard « mapStyles » (styleAtlas = carte couleur, styleSatelite = satellite) déposée dans html/map/. Calage automatique.
    -- Image : à défaut, une seule image carrée (même calage) ; les limites ci-dessous sont celles de l'image / des tuiles standard.
    Map = { Tiles = 'map/mapStyles/styleAtlas/{z}/{x}/{y}.jpg', TileMaxZoom = 5, Image = '', LabelColor = { 255, 255, 255 }, LabelOutline = true, MinX = -5661.0, MaxX = 6693.9, MinY = -4058.5, MaxY = 8429.3 },
    Landmarks = {
        { 'Legion Square', 195.0, -933.0 }, { 'Hôpital Pillbox', 298.0, -584.0 }, { 'Mission Row', 428.0, -984.0 }, { 'Vinewood', 300.0, 200.0 },
        { 'Aéroport LSIA', -1037.0, -2737.0 }, { 'Del Perro', -1850.0, -1233.0 }, { 'Port de LS', 1000.0, -3000.0 }, { 'Mirror Park', 1050.0, -500.0 },
        { 'Sandy Shores', 1961.0, 3741.0 }, { 'Grapeseed', 2500.0, 4700.0 }, { 'Mont Chiliad', 450.0, 5600.0 }, { 'Paleto Bay', -140.0, 6240.0 },
        { 'Fort Zancudo', -2300.0, 3200.0 }, { 'Prison', 1700.0, 2600.0 }, { 'Raton Canyon', -1500.0, 4400.0 }, { 'Barrage', -300.0, 1900.0 },
    },
}

-- ─────────────────────────────── Annonces d'entreprise ───────────────────────────────
-- Chaque job peut diffuser une annonce à tous les joueurs (bandeau à l'écran). Réglages par job : onglet Général → Annonces.
Config.Announce = {
    Enabled = true,
    Cooldown = 120,      -- délai entre deux annonces d'un même job (par défaut, modifiable par job)
    Cost = 0,            -- coût prélevé sur la société (par défaut, modifiable par job)
    Duration = 12,       -- durée d'affichage (secondes)
    MaxTitle = 40, MaxText = 240,
    History = 15,        -- annonces gardées dans l'historique affiché
    ToggleCommand = 'annonces',   -- /annonces : un joueur masque / réaffiche les annonces d'entreprise
    Types = {
        { id = 'info',        label = 'Information',   color = { 64, 224, 208 } },
        { id = 'recruitment', label = 'Recrutement',   color = { 59, 130, 246 } },
        { id = 'promo',       label = 'Promotion',     color = { 245, 158, 11 } },
        { id = 'event',       label = 'Événement',     color = { 168, 85, 247 } },
        { id = 'urgent',      label = 'Urgent',        color = { 239, 68, 68 } },
    },
}

-- Une action n'est proposée qu'aux types de job concernés (ex. « Soigner » : ems uniquement). `types` absent = tous les jobs ; le type « Personnalisé »
-- (custom) peut tout prendre ; `auto = true` : ajoutée automatiquement selon le type de job (non cochable dans l'éditeur).
function JBActionAllowed(action, jobType)
    local a = Config.Actions[action]
    if not a then return false end
    if not a.types or jobType == 'custom' then return true end
    for _, t in ipairs(a.types) do if t == jobType then return true end end
    return false
end

-- ─────────────────────────────── Restaurant / bar : récolte → cuisine → vente ───────────────────────────────
-- Points « Récolte » (ex. potager : tomates), points « Cuisine / Bar » (recettes : ingrédients → plat), coffre « Frigo » (point Coffre),
-- puis F6 → « Vendre un produit » : l'employé propose un produit de la carte au client le plus proche, qui paie directement.
Config.Kitchen = {
    MaxRecipes   = 30,   -- recettes par point Cuisine
    MaxInputs    = 5,    -- ingrédients par recette
    MaxHarvest   = 20,   -- quantité max par récolte
    MaxBatch     = 10,   -- fabrications max d'un coup
    MaxServe     = 20,   -- quantité max par vente
    MaxMenu      = 60,   -- produits max sur la carte d'un job
    Grace        = 0.85, -- part minimale de la durée à respecter côté serveur (anti-triche)
    HarvestScenario = 'WORLD_HUMAN_GARDENER_PLANT',
    CookScenario    = 'PROP_HUMAN_BBQ',
}

-- ─────────────────────────────── Concession ───────────────────────────────
-- Les véhicules vendus sont ajoutés à ta table owned_vehicles (colonnes configurables ci-dessous).
Config.Dealer = {
    Table = 'owned_vehicles',
    Cols  = { owner = 'owner', plate = 'plate', vehicle = 'vehicle', type = 'type', state = 'state', name = 'name' }, -- '' = colonne ignorée
    Delivery = 'spawn',        -- 'spawn' : le véhicule sort devant le client | 'garage' : il est directement rangé au garage
    StateOut = 0,              -- valeur de la colonne state quand le véhicule est dehors
    StateStored = 1,           -- valeur de la colonne state quand le véhicule est au garage
    TestSeconds = 120,         -- durée d'un essai (par défaut)
    DefaultCommission = 10,    -- % de commission du vendeur
    MaxVehiclesPerPlayer = 0,  -- 0 = illimité
    DisplayDistance = 60.0,    -- distance d'affichage des véhicules d'exposition
    -- Type écrit dans owned_vehicles selon la catégorie de ta table vehicles (défaut : 'car')
    CategoryTypes = { motorcycles = 'bike', Motosimports = 'bike', velo = 'bike', boat = 'boat', subs = 'boat', aircraft = 'aircraft', helicopters = 'aircraft', planes = 'aircraft' },
}


-- ─────────────────────────────── Missions PNJ ───────────────────────────────
-- Chaque job peut proposer des missions thématiques (livraison de véhicule, patrouille, urgence, dépannage, course...).
-- Activation par job dans le builder (onglet Général). Tout est modifiable en jeu : Paramètres → Missions.
-- Étapes : spawn_vehicle | goto | interact | pickup_npc | dropoff_npc
--   where = 'start' (au point « Missions PNJ ») ou 'loc' (lieu tiré au hasard dans Config.Missions.Locations)
--   same  = réutilise le lieu de l'étape précédente
--   anim  = give | work | repair | heal | inspect | talk
Config.Missions = {
    Enabled = true,
    Cooldown = 60,            -- secondes entre deux missions d'un même joueur (par job)
    MinSeconds = 20,          -- durée minimale d'une mission (anti-triche)
    Tolerance = 70.0,         -- distance serveur tolérée autour des étapes (m)
    RewardAccount = 'money',  -- compte crédité quand la source est « système » : 'money' | 'bank'
    TimeBonus = 15,           -- % de bonus si la mission est terminée dans le temps imparti
    DamageMaxPenalty = 30,    -- % de pénalité max selon l'état du véhicule
    Peds = { 'a_m_y_business_01', 'a_f_y_business_02', 'a_m_m_skater_01', 'a_f_m_downtown_01', 'a_m_y_hipster_01', 'a_f_y_tourist_01' },
    Locations = {
        legion   = { label = 'Legion Square',            x = 195.17,  y = -933.77, z = 30.69,  h = 160.0 },
        pillbox  = { label = 'Hôpital Pillbox',          x = 298.60,  y = -584.40, z = 43.26,  h = 70.0 },
        mrpd     = { label = 'Mission Row',              x = 428.00,  y = -984.00, z = 30.70,  h = 90.0 },
        bank     = { label = 'Pacific Standard Bank',    x = 232.00,  y = 214.00,  z = 106.30, h = 30.0 },
        maze     = { label = 'Maze Bank Tower',          x = -67.00,  y = -801.00, z = 44.20,  h = 340.0 },
        lsia     = { label = 'Aéroport LSIA',            x = -1037.5, y = -2737.8, z = 20.17,  h = 330.0 },
        delperro = { label = 'Jetée de Del Perro',       x = -1850.6, y = -1233.2, z = 13.02,  h = 140.0 },
        grove    = { label = 'Grove Street',             x = 110.50,  y = -1944.0, z = 20.80,  h = 40.0 },
        cab      = { label = 'Downtown Cab Co.',         x = 909.00,  y = -176.00, z = 74.20,  h = 240.0 },
        sandy    = { label = 'Sandy Shores',             x = 1961.5,  y = 3741.5,  z = 32.34,  h = 300.0 },
        harmony  = { label = 'Harmony',                  x = 549.00,  y = 2671.0,  z = 42.20,  h = 100.0 },
        grapeseed= { label = 'Grapeseed',                x = 1698.0,  y = 4924.0,  z = 42.10,  h = 320.0 },
        paleto   = { label = 'Paleto Bay',               x = -102.0,  y = 6467.0,  z = 31.60,  h = 45.0 },
        chumash  = { label = 'Chumash',                  x = -3040.0, y = 585.0,   z = 7.90,   h = 20.0 },
    },
    Templates = {
        dealer = {
            { id = 'delivery', label = 'Livraison de véhicule', desc = 'Livre un véhicule neuf à un client en ville et remets-lui les clés.', minGrade = 0,
              reward = { min = 400, max = 900 }, cooldown = 60, timeLimit = 900, vehicle = { source = 'catalog', models = { 'sultan', 'asea' } }, peds = {},
              steps = {
                  { t = 'spawn_vehicle', where = 'start', label = 'Monte dans le véhicule à livrer' },
                  { t = 'goto', veh = true, label = 'Conduis le véhicule chez le client' },
                  { t = 'interact', same = true, anim = 'give', secs = 5, consume = true, label = 'Remettre les clés au client' },
              } },
            { id = 'prospect', label = 'Démarchage client', desc = 'Rends visite à un client potentiel et présente les offres de la concession.', minGrade = 0,
              reward = { min = 250, max = 500 }, cooldown = 60, timeLimit = 900, vehicle = { source = 'models', models = {} }, peds = {},
              steps = {
                  { t = 'goto', label = 'Rends-toi chez le client' },
                  { t = 'interact', same = true, anim = 'talk', secs = 8, label = 'Présenter les offres' },
              } },
        },
        police = {
            { id = 'patrol', label = 'Patrouille', desc = 'Contrôle deux secteurs de la ville.', minGrade = 0, reward = { min = 300, max = 600 }, cooldown = 60, timeLimit = 1200,
              vehicle = { source = 'models', models = {} }, peds = {},
              steps = {
                  { t = 'goto', label = 'Rends-toi dans le premier secteur' }, { t = 'interact', same = true, anim = 'inspect', secs = 6, npc = false, label = 'Contrôler la zone' },
                  { t = 'goto', label = 'Rends-toi dans le second secteur' }, { t = 'interact', same = true, anim = 'inspect', secs = 6, npc = false, label = 'Contrôler la zone' },
              } },
            { id = 'witness', label = 'Appel : témoin', desc = 'Un témoin a appelé le commissariat : va prendre sa déposition.', minGrade = 0, reward = { min = 250, max = 500 }, cooldown = 60, timeLimit = 900,
              vehicle = { source = 'models', models = {} }, peds = {},
              steps = { { t = 'goto', label = 'Rends-toi sur place' }, { t = 'interact', same = true, anim = 'talk', secs = 8, label = 'Prendre la déposition' } } },
            { id = 'evidence', label = 'Transport de preuves', desc = 'Récupère les scellés au commissariat et dépose-les au laboratoire.', minGrade = 1, reward = { min = 350, max = 700 }, cooldown = 90, timeLimit = 1200,
              vehicle = { source = 'models', models = {} }, peds = {},
              steps = {
                  { t = 'interact', where = 'start', anim = 'work', secs = 4, npc = false, label = 'Récupérer les scellés' },
                  { t = 'goto', label = 'Rejoins le laboratoire' }, { t = 'interact', same = true, anim = 'give', secs = 4, label = 'Remettre les scellés' },
              } },
        },
        ems = {
            { id = 'emergency', label = 'Urgence médicale', desc = 'Une personne est blessée : rends-toi sur place et soigne-la.', minGrade = 0, reward = { min = 400, max = 800 }, cooldown = 60, timeLimit = 600,
              vehicle = { source = 'models', models = {} }, peds = {},
              steps = { { t = 'goto', label = 'Rends-toi sur les lieux de l\'accident' }, { t = 'interact', same = true, anim = 'heal', patient = true, secs = 10, label = 'Soigner le patient' } } },
            { id = 'meds', label = 'Livraison de médicaments', desc = 'Charge les médicaments et livre-les à une pharmacie.', minGrade = 0, reward = { min = 250, max = 500 }, cooldown = 60, timeLimit = 900,
              vehicle = { source = 'models', models = {} }, peds = {},
              steps = {
                  { t = 'interact', where = 'start', anim = 'work', secs = 4, npc = false, label = 'Charger les médicaments' },
                  { t = 'goto', label = 'Rends-toi à la pharmacie' }, { t = 'interact', same = true, anim = 'give', secs = 4, label = 'Livrer les médicaments' },
              } },
        },
        bank = {
            { id = 'cashtransit', label = 'Transport de fonds', desc = 'Charge les sacs de billets et livre-les à une agence partenaire.', minGrade = 0, reward = { min = 400, max = 800 }, cooldown = 90, timeLimit = 1200,
              vehicle = { source = 'models', models = {} }, peds = {},
              steps = {
                  { t = 'interact', where = 'start', anim = 'work', secs = 4, npc = false, label = 'Charger les sacs de billets' },
                  { t = 'goto', label = 'Rends-toi à l\'agence partenaire' }, { t = 'interact', same = true, anim = 'give', secs = 4, label = 'Remettre les fonds' },
              } },
            { id = 'clientvisit', label = 'Visite client', desc = 'Un client important souhaite un rendez-vous à domicile.', minGrade = 1, reward = { min = 300, max = 600 }, cooldown = 60, timeLimit = 900,
              vehicle = { source = 'models', models = {} }, peds = {},
              steps = { { t = 'goto', label = 'Rends-toi chez le client' }, { t = 'interact', same = true, anim = 'talk', secs = 8, label = 'Présenter les offres de la banque' } } },
        },
        mecano = {
            { id = 'breakdown', label = 'Dépannage', desc = 'Un automobiliste est en panne : rejoins-le et répare son véhicule.', minGrade = 0, reward = { min = 350, max = 700 }, cooldown = 60, timeLimit = 900,
              vehicle = { source = 'models', models = { 'blista', 'asea', 'premier', 'ingot' } }, peds = {},
              steps = {
                  { t = 'spawn_vehicle', where = 'loc', broken = true, label = 'Cherche le véhicule en panne' },
                  { t = 'goto', same = true, label = 'Rejoins le véhicule en panne' },
                  { t = 'interact', same = true, anim = 'repair', secs = 12, npc = false, label = 'Réparer le véhicule' },
              } },
            { id = 'parts', label = 'Livraison de pièces', desc = 'Livre des pièces détachées à un garage partenaire.', minGrade = 0, reward = { min = 250, max = 500 }, cooldown = 60, timeLimit = 900,
              vehicle = { source = 'models', models = {} }, peds = {},
              steps = {
                  { t = 'interact', where = 'start', anim = 'work', secs = 4, npc = false, label = 'Charger les pièces' },
                  { t = 'goto', label = 'Rends-toi au garage partenaire' }, { t = 'interact', same = true, anim = 'give', secs = 4, label = 'Remettre les pièces' },
              } },
        },
        taxi = {
            { id = 'fare', label = 'Course client', desc = 'Prends un client et dépose-le à sa destination.', minGrade = 0, reward = { min = 200, max = 500 }, cooldown = 45, timeLimit = 900,
              vehicle = { source = 'models', models = {} }, peds = {},
              steps = { { t = 'pickup_npc', label = 'Va chercher le client' }, { t = 'dropoff_npc', label = 'Dépose le client à destination' } } },
        },
        realestate = {
            { id = 'visit', label = 'Visite avec un client', desc = 'Retrouve un client et fais-lui visiter un bien.', minGrade = 0, reward = { min = 300, max = 650 }, cooldown = 60, timeLimit = 900,
              vehicle = { source = 'models', models = {} }, peds = {},
              steps = { { t = 'goto', label = 'Rejoins le client devant le bien' }, { t = 'interact', same = true, anim = 'talk', secs = 12, label = 'Faire visiter le bien' } } },
            { id = 'signs', label = 'Pose de pancartes', desc = 'Installe des pancartes « à vendre » dans deux quartiers.', minGrade = 0, reward = { min = 200, max = 450 }, cooldown = 60, timeLimit = 1200,
              vehicle = { source = 'models', models = {} }, peds = {},
              steps = {
                  { t = 'goto', label = 'Rends-toi dans le premier quartier' }, { t = 'interact', same = true, anim = 'work', secs = 6, npc = false, label = 'Poser la pancarte' },
                  { t = 'goto', label = 'Rends-toi dans le second quartier' }, { t = 'interact', same = true, anim = 'work', secs = 6, npc = false, label = 'Poser la pancarte' },
              } },
        },
        bar = {
            { id = 'order', label = 'Livraison de commande', desc = 'Prépare une commande et livre-la à un client.', minGrade = 0, reward = { min = 150, max = 350 }, cooldown = 45, timeLimit = 900,
              vehicle = { source = 'models', models = {} }, peds = {},
              steps = {
                  { t = 'interact', where = 'start', anim = 'work', secs = 6, npc = false, label = 'Préparer la commande' },
                  { t = 'goto', label = 'Rends-toi chez le client' }, { t = 'interact', same = true, anim = 'give', secs = 4, label = 'Servir le client' },
              } },
        },
        government = {
            { id = 'inspection', label = 'Inspection de terrain', desc = 'Inspecte deux sites de la ville pour le compte du gouvernement.', minGrade = 0, reward = { min = 400, max = 800 }, cooldown = 90, timeLimit = 1500,
              vehicle = { source = 'models', models = {} }, peds = {},
              steps = {
                  { t = 'goto', label = 'Rends-toi sur le premier site' }, { t = 'interact', same = true, anim = 'inspect', secs = 8, npc = false, label = 'Inspecter le site' },
                  { t = 'goto', label = 'Rends-toi sur le second site' }, { t = 'interact', same = true, anim = 'inspect', secs = 8, npc = false, label = 'Inspecter le site' },
              } },
            { id = 'documents', label = 'Remise de documents officiels', desc = 'Remets un dossier officiel à un représentant.', minGrade = 0, reward = { min = 300, max = 600 }, cooldown = 60, timeLimit = 900,
              vehicle = { source = 'models', models = {} }, peds = {},
              steps = {
                  { t = 'interact', where = 'start', anim = 'work', secs = 4, npc = false, label = 'Récupérer le dossier' },
                  { t = 'goto', label = 'Rends-toi chez le représentant' }, { t = 'interact', same = true, anim = 'give', secs = 4, label = 'Remettre le dossier' },
              } },
        },
        custom = {
            { id = 'parcel', label = 'Livraison de colis', desc = 'Charge un colis et livre-le à un client.', minGrade = 0, reward = { min = 200, max = 450 }, cooldown = 60, timeLimit = 900,
              vehicle = { source = 'models', models = {} }, peds = {},
              steps = {
                  { t = 'interact', where = 'start', anim = 'work', secs = 4, npc = false, label = 'Charger le colis' },
                  { t = 'goto', label = 'Rends-toi chez le client' }, { t = 'interact', same = true, anim = 'give', secs = 4, label = 'Remettre le colis' },
              } },
        },
    },
}

-- ─────────────────────────────── Gouvernement ───────────────────────────────
Config.Gov = {
    Taxes = { dealer = 0, realestate = 0, shop = 0, invoice = 0 },  -- % prélevés au profit du trésor public
    AnnounceCooldown = 120,    -- secondes entre deux annonces
    AnnounceMax = 220,         -- longueur max d'une annonce
    GrantMax = 1000000,        -- subvention max par opération
    PrimeMax = 100000,         -- prime max par opération
}

-- ─────────────────────────────── Apparence des menus ───────────────────────────────
-- Couleur d'accentuation de toute l'interface (boutons, onglet actif, pastilles, icônes, bordures teintées).
-- Modifiable en direct par les _dev : /jobbuilder → Paramètres → Apparence (appliquée à tous les joueurs).
Config.UI = { Accent = { 239, 68, 68 } }   -- rouge par défaut

-- ─────────────────────────────── Immobilier ───────────────────────────────
Config.Real = {
    RentDays          = 7,      -- durée d'une période de loyer
    MaxRentAhead      = 3,      -- nombre max de périodes payées d'avance
    MaxPerPlayer      = 3,      -- propriétés max par joueur
    MaxKeys           = 4,      -- doubles de clés max par propriété
    MaxPointsPerProp  = 12,
    OutfitsPerPlayer  = 10,     -- tenues max par joueur et par propriété
    DefaultCommission = 10,     -- % du prix reversé à l'agent qui conclut (réglable par agence)
    BucketBase        = 20000,  -- routing bucket = BucketBase + id propriété (instances séparées)
    ShowBlips         = true,   -- blips des biens disponibles
    RentCheckMinutes  = 5,      -- fréquence de vérification des loyers impayés
    Blips = {
        sale = { sprite = 374, color = 2, scale = 0.65 },
        rent = { sprite = 374, color = 3, scale = 0.65 },
    },
    -- Markers des portes / sorties (base commune : type 25, turquoise ; éditables en jeu)
    Markers = {
        available = { marker = 25, color = { 64, 224, 208 } },    -- bien disponible
        access    = { marker = 25, color = { 64, 224, 208 } },   -- ta propriété / tes clés
        noaccess  = { marker = 25, color = { 64, 224, 208 } },  -- propriété occupée (visiteur)
        exit      = { marker = 25,  color = { 64, 224, 208 } },  -- sortie de l'intérieur
    },
    PointTypes = {
        stash    = { label = 'Coffre',   marker = 25, color = { 64, 224, 208 } },
        wardrobe = { label = 'Penderie', marker = 25, color = { 64, 224, 208 } },
    },
    -- Intérieurs prêts à l'emploi (TP). Coordonnées de sortie = où le joueur apparaît / où se trouve la porte.
    -- Vérifie-les en jeu ; "Intérieur personnalisé" te permet d'utiliser n'importe quel MLO / shell.
    Interiors = {
        low     = { label = 'Appartement Low End',    exit = { x = 261.4586, y = -998.8196, z = -99.0086, h = 0.0 } },
        medium  = { label = 'Appartement Medium End', exit = { x = 346.6677, y = -1013.1306, z = -99.1999, h = 0.0 } },
        modern1 = { label = 'Appartement Modern 1',   exit = { x = -786.8663, y = 315.7642, z = 217.6385, h = 0.0 } },
        modern2 = { label = 'Appartement Modern 2',   exit = { x = -774.0126, y = 342.0428, z = 196.6864, h = 0.0 } },
    },
}

-- ─────────────────────────────── Templates de jobs ───────────────────────────────
-- Chaque template pré-remplit le builder (grades, blip, actions). Tout reste modifiable dans l'UI.
Config.JobTypes = {
    police = {
        label = 'Police', blip = { sprite = 60, color = 29, scale = 0.9 },
        actions = { 'handcuff', 'escort', 'search', 'invoice' },
        points = { 'garage', 'garage_return', 'cloakroom', 'armory', 'stash', 'boss' },
        grades = {
            { name = 'recruit',    label = 'Recrue',     salary = 100 },
            { name = 'officer',    label = 'Agent',      salary = 200 },
            { name = 'sergeant',   label = 'Sergent',    salary = 300 },
            { name = 'lieutenant', label = 'Lieutenant', salary = 500 },
            { name = 'boss',       label = 'Commissaire', salary = 800 },
        },
    },
    ems = {
        label = 'EMS / Ambulance', blip = { sprite = 61, color = 1, scale = 0.9 },
        actions = { 'revive', 'heal', 'invoice' },
        points = { 'garage', 'garage_return', 'cloakroom', 'stash', 'shop', 'boss' },
        grades = {
            { name = 'ambulance',    label = 'Ambulancier',  salary = 350 },
            { name = 'doctor',       label = 'Médecin',      salary = 500 },
            { name = 'chief_doctor', label = 'Médecin-chef', salary = 700 },
            { name = 'boss',         label = 'Directeur',    salary = 900 },
        },
    },
    bank = {
        label = 'Banque', blip = { sprite = 108, color = 2, scale = 0.9 },
        actions = { 'invoice' },
        points = { 'cloakroom', 'stash', 'shop', 'boss' },
        grades = {
            { name = 'trainee',  label = 'Stagiaire',          salary = 200 },
            { name = 'teller',   label = 'Chargé de clientèle', salary = 350 },
            { name = 'advisor',  label = 'Conseiller financier', salary = 550 },
            { name = 'boss',     label = 'Directeur',          salary = 900 },
        },
    },
    mecano = {
        label = 'Mécano', blip = { sprite = 446, color = 5, scale = 0.9 },
        actions = { 'repair', 'clean', 'invoice' },
        points = { 'garage', 'garage_return', 'cloakroom', 'stash', 'tuning', 'shop', 'boss' },
        grades = {
            { name = 'recrue',   label = 'Apprenti',    salary = 150 },
            { name = 'novice',   label = 'Mécanicien',  salary = 250 },
            { name = 'chief',    label = 'Chef d\'atelier', salary = 400 },
            { name = 'boss',     label = 'Patron',      salary = 600 },
        },
    },
    taxi = {
        label = 'Taxi', blip = { sprite = 198, color = 5, scale = 0.9 },
        actions = { 'invoice' },
        points = { 'garage', 'garage_return', 'cloakroom', 'stash', 'boss' },
        grades = {
            { name = 'recrue', label = 'Chauffeur',  salary = 150 },
            { name = 'novice', label = 'Confirmé',   salary = 250 },
            { name = 'boss',   label = 'Patron',     salary = 500 },
        },
    },
    realestate = {
        label = 'Agence immobilière', blip = { sprite = 374, color = 2, scale = 0.9 },
        actions = { 'invoice' },   -- 'properties' (gestion immobilière) est ajoutée automatiquement
        points = { 'garage', 'garage_return', 'cloakroom', 'stash', 'boss' },
        grades = {
            { name = 'recrue', label = 'Stagiaire', salary = 150 },
            { name = 'agent',  label = 'Agent',     salary = 300 },
            { name = 'boss',   label = 'Directeur', salary = 700 },
        },
    },
    dealer = {
        label = 'Concessionnaire', blip = { sprite = 225, color = 3, scale = 0.9 },
        actions = { 'invoice' },   -- 'dealership' (gestion concession) est ajoutée automatiquement
        points = { 'showroom', 'display', 'testdrive', 'cloakroom', 'stash', 'boss' },
        grades = {
            { name = 'stagiaire', label = 'Stagiaire',        salary = 150 },
            { name = 'vendeur',   label = 'Vendeur',          salary = 300 },
            { name = 'chef',      label = 'Chef des ventes',  salary = 500 },
            { name = 'boss',      label = 'Directeur',        salary = 800 },
        },
    },
    government = {
        label = 'Gouvernement', blip = { sprite = 419, color = 5, scale = 0.9 },
        actions = { 'invoice' },   -- 'government' (trésor, taxes, subventions, annonces) est ajoutée automatiquement
        points = { 'cloakroom', 'stash', 'boss' },
        grades = {
            { name = 'attache',    label = 'Attaché',          salary = 400 },
            { name = 'ministre',   label = 'Ministre',         salary = 700 },
            { name = 'vice',       label = 'Vice-gouverneur',  salary = 1000 },
            { name = 'boss',       label = 'Gouverneur',       salary = 1500 },
        },
    },
    bar = {
        label = 'Bar / Restaurant', blip = { sprite = 93, color = 46, scale = 0.9 },
        actions = { 'invoice', 'serve' },
        points = { 'cloakroom', 'harvest', 'stash', 'kitchen', 'shop', 'boss' },
        grades = {
            { name = 'serveur', label = 'Serveur', salary = 120 },
            { name = 'barman',  label = 'Barman',  salary = 200 },
            { name = 'boss',    label = 'Gérant',  salary = 450 },
        },
    },
    custom = {
        label = 'Personnalisé', blip = { sprite = 478, color = 0, scale = 0.9 },
        actions = { 'invoice' },
        points = { 'garage', 'garage_return', 'cloakroom', 'armory', 'stash', 'boss', 'shop' },
        grades = {
            { name = 'recrue', label = 'Recrue', salary = 100 },
            { name = 'boss',   label = 'Patron', salary = 500 },
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

-- ─────────────────────────────── Hooks client (adapter à ton système) ───────────────────────────────
if not IsDuplicityVersion() then
    -- Récupère les vêtements actuels du joueur -> cb(table)
    Config.GetClothes = function(cb)
        TriggerEvent('skinchanger:getSkin', function(skin) cb(skin) end)
    end

    -- Applique une tenue (table de clés ClothesKeys)
    Config.ApplyClothes = function(clothes)
        TriggerEvent('skinchanger:getSkin', function(skin)
            TriggerEvent('skinchanger:loadClothes', skin, clothes)
        end)
    end

    -- Remet la tenue civile
    Config.RestoreCivil = function()
        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
            TriggerEvent('skinchanger:loadSkin', skin)
        end)
    end

    -- Appelé après le spawn d'un véhicule de job (donner les clés...)
    Config.OnVehicleSpawned = function(vehicle, plate)
        -- ex: exports['vehicle_keys']:GiveKeys(plate)
    end
end


-- ═══════════════════════════════ Réglages modifiables en jeu (/jobbuilder → Paramètres) ═══════════════════════════════
-- Les valeurs ci-dessus sont les DÉFAUTS. Les modifications faites en jeu sont stockées en base (jobbuilder_settings)
-- et appliquées en direct sur le serveur et chez tous les clients (modification "en place" de Config).
local function deepcopy(v)
    if type(v) ~= 'table' then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = deepcopy(x) end
    return out
end
JBDeepCopy = deepcopy

local function replace(dst, src)
    for k in pairs(dst) do dst[k] = nil end
    for k, v in pairs(src or {}) do dst[k] = deepcopy(v) end
end

JB_GENERAL_KEYS = { 'DrawDistance', 'InteractDistance', 'ServerDistance', 'TargetDistance', 'MaxGrades', 'MaxPoints', 'MaxItemsPerPoint',
    'PlatePrefixLength', 'ReviveEvent', 'Webhook', 'Inventory', 'AcePermission' }
JB_REAL_KEYS = { 'RentDays', 'MaxRentAhead', 'MaxPerPlayer', 'MaxKeys', 'MaxPointsPerProp', 'OutfitsPerPlayer', 'DefaultCommission',
    'RentCheckMinutes', 'ShowBlips' }

JB_DEALER_KEYS = { 'Delivery', 'StateOut', 'StateStored', 'TestSeconds', 'DefaultCommission', 'MaxVehiclesPerPlayer', 'DisplayDistance' }
JB_MISSION_KEYS = { 'Enabled', 'Cooldown', 'MinSeconds', 'Tolerance', 'RewardAccount', 'TimeBonus', 'DamageMaxPenalty' }
JB_GOV_KEYS = { 'AnnounceCooldown', 'AnnounceMax', 'GrantMax', 'PrimeMax' }
JB_POLICE_KEYS = { 'PursuitMax', 'PursuitTrail', 'NearbyRange', 'RefreshMs', 'CallCooldown', 'MaxCalls', 'ClosedKeepMinutes', 'MinFine', 'MaxFine', 'CallCommand', 'PanicCommand' }
JB_TUNING_KEYS = { 'Radius' }
JB_DEATH_KEYS = { 'Mode', 'RespawnTime', 'NoEmsRespawn', 'CallCooldown', 'RespawnFee', 'UnpaidAllowed', 'RestoreStatus', 'FeeAccount', 'ReviveHealth', 'RespawnHealth', 'CprSeconds', 'RevivePay', 'ReviveAnim', 'OxygenHud', 'OxygenWarn', 'OxygenCustom', 'OxygenSeconds', 'OxygenDamage' }
JB_ANNOUNCE_KEYS = { 'Enabled', 'Cooldown', 'Cost', 'Duration', 'MaxTitle', 'MaxText', 'History', 'ToggleCommand' }

function JBGet(section)
    local t = {}
    if section == 'general' then
        for _, k in ipairs(JB_GENERAL_KEYS) do t[k] = Config[k] end
        t.AllowedGroups, t.ActionDuration = deepcopy(Config.AllowedGroups), deepcopy(Config.ActionDuration)
        t.RestartResources = deepcopy(Config.RestartResources)
    elseif section == 'pointTypes' then
        t = deepcopy(Config.PointTypes)
    elseif section == 'real' then
        for _, k in ipairs(JB_REAL_KEYS) do t[k] = Config.Real[k] end
        t.Blips, t.PointTypes, t.Markers = deepcopy(Config.Real.Blips), deepcopy(Config.Real.PointTypes), deepcopy(Config.Real.Markers)
    elseif section == 'interiors' then
        t = deepcopy(Config.Real.Interiors)
    elseif section == 'jobTypes' then
        t = deepcopy(Config.JobTypes)
    elseif section == 'ui' then
        t.Accent = deepcopy(Config.UI.Accent)
    elseif section == 'police' then
        for _, k in ipairs(JB_POLICE_KEYS) do t[k] = Config.Police[k] end
        t.DefaultFines, t.Map, t.Landmarks = deepcopy(Config.Police.DefaultFines), deepcopy(Config.Police.Map), deepcopy(Config.Police.Landmarks)
    elseif section == 'announce' then
        for _, k in ipairs(JB_ANNOUNCE_KEYS) do t[k] = Config.Announce[k] end
        t.Types = deepcopy(Config.Announce.Types)
    elseif section == 'tuning' then
        for _, k in ipairs(JB_TUNING_KEYS) do t[k] = Config.Tuning[k] end
        t.Prices = deepcopy(Config.Tuning.Prices)
    elseif section == 'death' then
        for _, k in ipairs(JB_DEATH_KEYS) do t[k] = Config.Death[k] end
        t.Hospitals = deepcopy(Config.Death.Hospitals)
    elseif section == 'dealer' then
        for _, k in ipairs(JB_DEALER_KEYS) do t[k] = Config.Dealer[k] end
    elseif section == 'gov' then
        for _, k in ipairs(JB_GOV_KEYS) do t[k] = Config.Gov[k] end
        t.Taxes = deepcopy(Config.Gov.Taxes)
    elseif section == 'missions' then
        for _, k in ipairs(JB_MISSION_KEYS) do t[k] = Config.Missions[k] end
        t.Peds, t.Locations, t.Templates = deepcopy(Config.Missions.Peds), deepcopy(Config.Missions.Locations), deepcopy(Config.Missions.Templates)
    end
    return t
end

-- Applique une section (déjà validée côté serveur) en modifiant Config EN PLACE
function JBSet(section, v)
    if type(v) ~= 'table' then return end
    if section == 'general' then
        for _, k in ipairs(JB_GENERAL_KEYS) do if v[k] ~= nil then Config[k] = v[k] end end
        if v.AllowedGroups then replace(Config.AllowedGroups, v.AllowedGroups) end
        if v.ActionDuration then replace(Config.ActionDuration, v.ActionDuration) end
        if v.RestartResources then replace(Config.RestartResources, v.RestartResources) end
    elseif section == 'pointTypes' then
        replace(Config.PointTypes, v)
        for k, base in pairs(JBDefaults and JBDefaults.pointTypes or {}) do      -- nouveaux types ajoutés depuis la sauvegarde des réglages
            if Config.PointTypes[k] == nil then Config.PointTypes[k] = deepcopy(base) end
        end
    elseif section == 'real' then
        for _, k in ipairs(JB_REAL_KEYS) do if v[k] ~= nil then Config.Real[k] = v[k] end end
        if v.Blips then replace(Config.Real.Blips, v.Blips) end
        if v.PointTypes then replace(Config.Real.PointTypes, v.PointTypes) end
        if v.Markers then replace(Config.Real.Markers, v.Markers) end
    elseif section == 'interiors' then
        replace(Config.Real.Interiors, v)
    elseif section == 'jobTypes' then
        replace(Config.JobTypes, v)
    elseif section == 'ui' then
        if v.Accent then replace(Config.UI.Accent, v.Accent) end
    elseif section == 'police' then
        for _, k in ipairs(JB_POLICE_KEYS) do if v[k] ~= nil then Config.Police[k] = v[k] end end
        if v.DefaultFines then replace(Config.Police.DefaultFines, v.DefaultFines) end
        if v.Map then replace(Config.Police.Map, v.Map) end
        if v.Landmarks then replace(Config.Police.Landmarks, v.Landmarks) end
    elseif section == 'announce' then
        for _, k in ipairs(JB_ANNOUNCE_KEYS) do if v[k] ~= nil then Config.Announce[k] = v[k] end end
        if v.Types then replace(Config.Announce.Types, v.Types) end
    elseif section == 'death' then
        for _, k in ipairs(JB_DEATH_KEYS) do if v[k] ~= nil then Config.Death[k] = v[k] end end
        if v.Hospitals then replace(Config.Death.Hospitals, v.Hospitals) end
    elseif section == 'tuning' then
        for _, k in ipairs(JB_TUNING_KEYS) do if v[k] ~= nil then Config.Tuning[k] = v[k] end end
        if v.Prices then replace(Config.Tuning.Prices, v.Prices) end
    elseif section == 'dealer' then
        for _, k in ipairs(JB_DEALER_KEYS) do if v[k] ~= nil then Config.Dealer[k] = v[k] end end
    elseif section == 'gov' then
        for _, k in ipairs(JB_GOV_KEYS) do if v[k] ~= nil then Config.Gov[k] = v[k] end end
        if v.Taxes then replace(Config.Gov.Taxes, v.Taxes) end
    elseif section == 'missions' then
        for _, k in ipairs(JB_MISSION_KEYS) do if v[k] ~= nil then Config.Missions[k] = v[k] end end
        if v.Peds then replace(Config.Missions.Peds, v.Peds) end
        if v.Locations then replace(Config.Missions.Locations, v.Locations) end
        if v.Templates then replace(Config.Missions.Templates, v.Templates) end
    end
end

JB_SECTIONS = { 'general', 'pointTypes', 'real', 'interiors', 'jobTypes', 'dealer', 'gov', 'missions', 'police', 'announce', 'tuning', 'death', 'ui' }
JBDefaults = {}
for _, sec in ipairs(JB_SECTIONS) do JBDefaults[sec] = JBGet(sec) end
