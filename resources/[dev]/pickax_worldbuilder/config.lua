Config = {}

-- ─────────────────────────────── Général ───────────────────────────────
Config.AllowedGroups   = { '_dev', 'admin', 'superadmin' }   -- groupes ESX autorisés à ouvrir le builder
Config.AcePermission   = 'worldbuilder.admin'                -- (optionnel) permission ACE alternative
Config.Command         = 'worldbuilder'                      -- /worldbuilder ouvre le builder
Config.OpenKey         = false                               -- touche pour ouvrir le builder sans taper la commande (ex : 'F6') — utile si un autre script bloque le chat

Config.DrawDistance     = 18.0   -- distance d'affichage des markers
Config.InteractDistance = 1.8    -- distance pour interagir (E)
Config.ServerDistance   = 14.0   -- tolérance côté serveur (anti-triche)
Config.PedDistance      = 60.0   -- distance d'apparition des PNJ

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

-- Table des véhicules des joueurs (ESX : owned_vehicles). Adapte les colonnes à ton serveur.
-- Mets `type = nil` / `job = nil` si ta table n'a pas ces colonnes.
Config.Vehicles = {
    table  = 'owned_vehicles',
    owner  = 'owner',
    plate  = 'plate',
    props  = 'vehicle',      -- JSON des propriétés (ESX.Game.GetVehicleProperties)
    stored = 'state',        -- 1 = garage, 0 = sorti, 2 = fourrière (colonne `state` d'owned_vehicles, comme CorePickax)
    forSale = 3,             -- valeur de `stored` d'un véhicule mis en vente (module Occasion) : ni garage ni fourrière
    type   = 'type',         -- 'car', 'boat', 'aircraft', 'bike'...
}

-- Au (re)démarrage du serveur, les véhicules « sortis » (stored = 0) sont :
--   'garage'  → remis au garage        'impound' → envoyés en fourrière        'none' → laissés tels quels (visibles en fourrière si introuvables)
Config.OnRestart = 'impound'

Config.VehicleTypes = {
    { id = 'car',      label = 'Voitures' },
    { id = 'bike',     label = 'Motos / vélos' },
    { id = 'boat',     label = 'Bateaux' },
    { id = 'aircraft', label = 'Aéronefs' },
}

-- Catalogue d'armes des zones PVP (le serveur refuse tout nom absent de cette liste)
Config.PvpWeapons = {
    -- Poing
    { name = 'WEAPON_PISTOL', label = 'Pistolet', category = 'Poing' }, { name = 'WEAPON_PISTOL_MK2', label = 'Pistolet Mk II', category = 'Poing' }, { name = 'WEAPON_COMBATPISTOL', label = 'Pistolet de combat', category = 'Poing' }, { name = 'WEAPON_APPISTOL', label = 'Pistolet automatique', category = 'Poing' }, { name = 'WEAPON_PISTOL50', label = 'Pistolet .50', category = 'Poing' }, { name = 'WEAPON_HEAVYPISTOL', label = 'Pistolet lourd', category = 'Poing' }, { name = 'WEAPON_REVOLVER', label = 'Revolver lourd', category = 'Poing' }, { name = 'WEAPON_DOUBLEACTION', label = 'Double action', category = 'Poing' }, { name = 'WEAPON_VINTAGEPISTOL', label = 'Pistolet vintage', category = 'Poing' }, { name = 'WEAPON_SNSPISTOL', label = 'Pétoire', category = 'Poing' },
    -- SMG
    { name = 'WEAPON_MICROSMG', label = 'Micro SMG', category = 'SMG' }, { name = 'WEAPON_SMG', label = 'SMG', category = 'SMG' }, { name = 'WEAPON_SMG_MK2', label = 'SMG Mk II', category = 'SMG' }, { name = 'WEAPON_ASSAULTSMG', label = 'SMG d\'assaut', category = 'SMG' }, { name = 'WEAPON_COMBATPDW', label = 'PDW de combat', category = 'SMG' }, { name = 'WEAPON_MACHINEPISTOL', label = 'Pistolet mitrailleur', category = 'SMG' },
    -- Assaut
    { name = 'WEAPON_ASSAULTRIFLE', label = 'AK-47', category = 'Assaut' }, { name = 'WEAPON_ASSAULTRIFLE_MK2', label = 'AK-47 Mk II', category = 'Assaut' }, { name = 'WEAPON_CARBINERIFLE', label = 'Carabine', category = 'Assaut' }, { name = 'WEAPON_CARBINERIFLE_MK2', label = 'Carabine Mk II', category = 'Assaut' }, { name = 'WEAPON_ADVANCEDRIFLE', label = 'Fusil avancé', category = 'Assaut' }, { name = 'WEAPON_SPECIALCARBINE', label = 'Carabine spéciale', category = 'Assaut' }, { name = 'WEAPON_BULLPUPRIFLE', label = 'Bullpup', category = 'Assaut' }, { name = 'WEAPON_COMPACTRIFLE', label = 'Fusil compact', category = 'Assaut' }, { name = 'WEAPON_MILITARYRIFLE', label = 'Fusil militaire', category = 'Assaut' },
    -- Pompe
    { name = 'WEAPON_PUMPSHOTGUN', label = 'Fusil à pompe', category = 'Pompe' }, { name = 'WEAPON_PUMPSHOTGUN_MK2', label = 'Fusil à pompe Mk II', category = 'Pompe' }, { name = 'WEAPON_SAWNOFFSHOTGUN', label = 'Canon scié', category = 'Pompe' }, { name = 'WEAPON_ASSAULTSHOTGUN', label = 'Pompe d\'assaut', category = 'Pompe' }, { name = 'WEAPON_HEAVYSHOTGUN', label = 'Pompe lourd', category = 'Pompe' }, { name = 'WEAPON_DBSHOTGUN', label = 'Double canon', category = 'Pompe' },
    -- Sniper
    { name = 'WEAPON_SNIPERRIFLE', label = 'Sniper', category = 'Sniper' }, { name = 'WEAPON_HEAVYSNIPER', label = 'Sniper lourd', category = 'Sniper' }, { name = 'WEAPON_HEAVYSNIPER_MK2', label = 'Sniper lourd Mk II', category = 'Sniper' }, { name = 'WEAPON_MARKSMANRIFLE', label = 'Fusil de précision', category = 'Sniper' }, { name = 'WEAPON_MUSKET', label = 'Mousquet', category = 'Sniper' },
    -- Lourd
    { name = 'WEAPON_MG', label = 'MG', category = 'Lourd' }, { name = 'WEAPON_COMBATMG', label = 'MG de combat', category = 'Lourd' },
    -- Mêlée
    { name = 'WEAPON_KNIFE', label = 'Couteau', category = 'Mêlée' }, { name = 'WEAPON_MACHETE', label = 'Machette', category = 'Mêlée' }, { name = 'WEAPON_BAT', label = 'Batte', category = 'Mêlée' }, { name = 'WEAPON_CROWBAR', label = 'Pied-de-biche', category = 'Mêlée' }, { name = 'WEAPON_HATCHET', label = 'Hachette', category = 'Mêlée' }, { name = 'WEAPON_KNUCKLE', label = 'Poing américain', category = 'Mêlée' },
    -- Lancer
    { name = 'WEAPON_GRENADE', label = 'Grenade', category = 'Lancer' }, { name = 'WEAPON_SMOKEGRENADE', label = 'Fumigène', category = 'Lancer' }, { name = 'WEAPON_MOLOTOV', label = 'Molotov', category = 'Lancer' }, { name = 'WEAPON_STICKYBOMB', label = 'Bombe collante', category = 'Lancer' },
}

-- Zones PVP : rendu des murs et événements de revive (ex : 'esx_ambulancejob:revive' ; les scripts d'ambulance doivent ignorer la mort quand LocalPlayer.state.inPvpZone est vrai)
-- Murs : GTA plante (« Pool Full, Size == 256 ») au-delà de ~256 appels de dessin par image. 24 segments ≈ 120 appels : ne dépasse pas 36.
Config.Pvp = { Wall = { height = 35.0, alpha = 70, drawDistance = 120.0, segments = 24 }, ReviveEvents = {} }

-- Portes : touche pour verrouiller / déverrouiller la porte la plus proche (rebindable par chaque joueur dans les paramètres FiveM). false = pas de touche.
Config.Doors = { Key = 'L', Distance = 3.0, Marker = false, Debug = false }   -- Marker = false : aucune porte n'affiche de marker (touche uniquement)

-- Course poursuite (module « chase ») : réglages techniques communs à toutes les parties
Config.Chase = { ShowBlips = false, TickMs = 200, UiTickMs = 500, EndDelay = 8, PrepareTimeout = 20, BucketBase = 5000 }

-- ─────────────────────────────── Apparence ───────────────────────────────
Config.Marker = { type = 25, color = { 64, 224, 208 }, alpha = 140, scale = { x = 0.9, y = 0.9, z = 0.6 }, offset = -0.95 }
Config.UI = { Accent = { 0, 164, 255 } }   -- couleur d'accentuation (modifiable en jeu : Paramètres → Apparence)

-- ─────────────────────────────── Types de modules ───────────────────────────────
Config.Types = {
    garage  = { label = 'Garages',             one = 'Garage',            icon = 'car',    sub = 'Véhicules des joueurs, garages de métier' },
    impound = { label = 'Fourrières',          one = 'Fourrière',         icon = 'truck',  sub = 'Récupération et mise en fourrière' },
    rental  = { label = 'Locations',           one = 'Location',          icon = 'key',    sub = 'Location de véhicules' },
    pvp     = { label = 'Zones PVP',           one = 'Zone PVP',          icon = 'target', sub = 'Zones de combat : armes, revive auto, classement' },
    chase   = { label = 'Courses poursuites',  one = 'Course poursuite',  icon = 'flag',   sub = 'Parties multijoueurs fugitif / poursuivants (lobbies, classement)' },
    carlot  = { label = 'Occasion',            one = 'Point de vente',    icon = 'car',    sub = 'Annonces de véhicules entre joueurs (type leboncoin)' },
    doorlock = { label = 'Portes',             one = 'Porte',             icon = 'lock',   sub = 'Portes verrouillables : métier, job2 / gang, item clé' },
    locksmith = { label = 'Serruriers',        one = 'Serrurier',         icon = 'key',    sub = 'Refaire des clés de véhicule' },
    carwash = { label = 'Stations de lavage',  one = 'Station de lavage', icon = 'drop',   sub = 'Lavage de véhicules (programmes payants)' },
    driving = { label = 'Auto-écoles',         one = 'Auto-école',        icon = 'book',   sub = 'Permis : code de la route (QCM) et conduite (parcours)' },
    bank    = { label = 'Banques',             one = 'Banque',            icon = 'dollar', sub = 'Guichets et distributeurs : dépôt, retrait, virement' },
    fuel    = { label = 'Stations essence',    one = 'Station essence',   icon = 'fuel',   sub = 'Pompes, carburant, jerricans' },
    drug    = { label = 'Drogues & labos',     one = 'Filière de drogue', icon = 'flask',  sub = 'Récolte, laboratoires, vente, blanchiment' },
    robbery = { label = 'Braquages',           one = 'Braquage',          icon = 'mask',   sub = 'Supérettes, banques, bijouteries...' },
}
Config.TypeOrder = { 'garage', 'impound', 'rental', 'pvp', 'chase', 'carlot', 'doorlock', 'fuel', 'carwash', 'locksmith', 'bank', 'driving', 'drug', 'robbery' }

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
    { id = 'search',   label = 'Fouiller',               dict = 'amb@prop_human_bum_bin@base', clip = 'base' },
    { id = 'fuel',     label = 'Faire le plein',         dict = 'timetable@gardener@filling_can', clip = 'gar_ig_5_filling_can' },
}

-- ─────────────────────────────── Hooks (adapter à ton serveur) ───────────────────────────────
if IsDuplicityVersion() then
    -- Alerte police : retourne true si tu gères toi-même l'alerte (ps-dispatch, cd_dispatch, qs-dispatch...). Sinon l'alerte intégrée est utilisée.
    -- Config.AlertHook = function(coords, title, message) exports['ps-dispatch']:CustomAlert({ coords = coords, message = title }) return true end
    Config.AlertHook = nil

    -- Remise d'une clé de véhicule (serrurier). Retourne true si tu gères toi-même la clé (ex : exports['qs-vehiclekeys']:GiveKeys(src, plate)).
    -- Sinon : item ox_inventory avec la plaque en métadonnée (si « Item clé » est défini sur le module), ou le hook client Config.GiveKeys.
    Config.GiveKey = nil

    -- Système de clés existant (ex : ton core `CorePickax` (script véhicule) avec la table open_car et l'export RegisterNewKeys).
    -- resource : nom de la ressource qui exporte RegisterNewKeys(source, plaque, 'no') ('' pour désactiver)
    -- table    : table des clés (colonnes identifier / value = plaque) : sert à DÉTECTER si le joueur a déjà la clé
    -- transferExport : true si tu as ajouté l'export TransferKeys (voir patches/vehicle) : les ventes d'occasion transfèrent alors proprement les clés
    Config.Keys = { resource = 'pickax_core', table = 'open_car', transferExport = true }

    -- Second métier (job2 / gang) des portes. Par défaut : xPlayer.job2 (ou xPlayer.getJob2()), de la forme { name = 'ballas', grade = 2 }.
    -- Config.GetJob2 = function(xPlayer) return { name = xPlayer.getMeta('gang'), grade = 0 } end
    Config.GetJob2 = nil

    -- Où lire la liste des job2 / gangs pour l'éditeur (adapte les noms de tables à ton serveur ; ESX.GetJobs2() est utilisé s'il existe)
    Config.Jobs2 = { table = 'jobs2', gradesTable = 'job2_grades', gradesNameCol = 'job2_name' }

    -- Vérifie une licence (non utilisé par défaut ; hook disponible pour tes extensions)
    Config.HasLicense = function(src, license)
        if GetResourceState('esx_license') ~= 'started' and GetResourceState('pickax_core') ~= 'started' then return true end
        local p = promise.new()
        TriggerEvent('esx_license:checkLicense', src, license, function(has) p:resolve(has == true) end)
        SetTimeout(500, function() p:resolve(false) end)
        return Citizen.Await(p)
    end
end

if not IsDuplicityVersion() then
    -- Clés du véhicule (appelé à chaque sortie de garage / location). Exemples :
    -- Config.GiveKeys = function(plate, vehicle) exports['qs-vehiclekeys']:GiveKeys(plate, GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))) end
    Config.GiveKeys = function(plate, vehicle)
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
    end

    -- Carburant : lecture / écriture. Par défaut : ox_fuel / LegacyFuel / natif.
    Config.GetFuel = function(veh)
        if GetResourceState('ox_fuel') == 'started' then return Entity(veh).state.fuel or GetVehicleFuelLevel(veh) end
        if GetResourceState('LegacyFuel') == 'started' then return exports['LegacyFuel']:GetFuel(veh) end
        return GetVehicleFuelLevel(veh)
    end
    Config.SetFuel = function(veh, level)
        level = math.max(0.0, math.min(100.0, level + 0.0))
        if GetResourceState('ox_fuel') == 'started' then Entity(veh).state.fuel = level end
        if GetResourceState('LegacyFuel') == 'started' then exports['LegacyFuel']:SetFuel(veh, level) end
        SetVehicleFuelLevel(veh, level)
    end
end

-- ═══════════════════════════════ MODÈLES (templates) ═══════════════════════════════
-- Chaque modèle crée un module pré-rempli (modifiable ensuite à 100 % en jeu).
-- Les positions (coords) sont à définir en jeu : /worldbuilder → Emplacements → « Mode placement ».
-- Items inexistants sur ton serveur : un avertissement s'affiche dans le builder (ajuste les noms à ton inventaire).

local function ped(model, scenario) return { enabled = true, model = model, scenario = scenario or 'WORLD_HUMAN_STAND_IMPATIENT' } end
local noPed = { enabled = false, model = '', scenario = '' }

Config.Templates = {}

-- ─────────────────────────────── Garages ───────────────────────────────
Config.Templates.garage = {
    public = {
        label = 'Garage public', icon = 'car',
        settings = { mode = 'owned', types = { 'car', 'bike' }, fee = 0, bound = false, payments = { cash = true, bank = true },
            blip = { enabled = true, sprite = 357, color = 3, scale = 0.8, label = 'Garage', shortRange = true } },
        points = { { label = 'Garage', blip = true, ped = ped('s_m_y_valet_01', 'WORLD_HUMAN_CLIPBOARD'), spawns = {} } },
    },
    boat = {
        label = 'Port / Marina', icon = 'boat',
        settings = { mode = 'owned', types = { 'boat' }, fee = 0, bound = false, payments = { cash = true, bank = true },
            blip = { enabled = true, sprite = 427, color = 3, scale = 0.8, label = 'Port', shortRange = true } },
        points = { { label = 'Port', blip = true, ped = noPed, spawns = {} } },
    },
    air = {
        label = 'Hangar', icon = 'plane',
        settings = { mode = 'owned', types = { 'aircraft' }, fee = 0, bound = false, payments = { cash = true, bank = true },
            blip = { enabled = true, sprite = 359, color = 3, scale = 0.8, label = 'Hangar', shortRange = true } },
        points = { { label = 'Hangar', blip = true, ped = noPed, spawns = {} } },
    },
    job = {
        label = 'Garage de métier (flotte)', icon = 'shield',
        settings = { mode = 'job', types = {}, fee = 0, bound = false, payments = { cash = true }, access = { jobs = { police = 0 } },
            blip = { enabled = true, sprite = 357, color = 38, scale = 0.8, label = 'Garage de service', shortRange = true },
            fleet = {
                { model = 'police',  label = 'Voiture de patrouille', minGrade = 0, price = 0 },
                { model = 'police2', label = 'Interceptor',           minGrade = 2, price = 0 },
                { model = 'policeb', label = 'Moto de police',        minGrade = 1, price = 0 },
            } },
        points = { { label = 'Garage de service', blip = true, ped = noPed, spawns = {} } },
    },
}

-- ─────────────────────────────── Fourrières ───────────────────────────────
Config.Templates.impound = {
    impound = {
        label = 'Fourrière', icon = 'truck',
        settings = { fee = 500, perDay = 100, maxFee = 5000, types = {}, payments = { cash = true, bank = true }, society = '',
            impoundJobs = { police = 0, sheriff = 0, mechanic = 0 },
            blip = { enabled = true, sprite = 68, color = 47, scale = 0.8, label = 'Fourrière', shortRange = true } },
        points = { { label = 'Fourrière', blip = true, ped = ped('s_m_y_construct_01', 'WORLD_HUMAN_CLIPBOARD'), spawns = {} } },
    },
}

-- ─────────────────────────────── Locations de véhicules ───────────────────────────────
Config.Templates.rental = {
    cars = {
        label = 'Location de voitures', icon = 'key',
        settings = { minutes = 60, refundDamage = true, payments = { cash = true, bank = true }, society = '',
            blip = { enabled = true, sprite = 225, color = 5, scale = 0.8, label = 'Location', shortRange = true },
            fleet = {
                { model = 'faggio',  label = 'Scooter',        price = 80,  deposit = 150,  minGrade = 0 },
                { model = 'panto',   label = 'Citadine',       price = 150, deposit = 300,  minGrade = 0 },
                { model = 'blista',  label = 'Compacte',       price = 220, deposit = 450,  minGrade = 0 },
                { model = 'sultan',  label = 'Berline sport',  price = 450, deposit = 1000, minGrade = 0 },
            } },
        points = { { label = 'Agence de location', blip = true, ped = ped('a_m_y_business_02'), spawns = {} } },
    },
    boats = {
        label = 'Location de bateaux', icon = 'boat',
        settings = { minutes = 60, refundDamage = true, payments = { cash = true, bank = true }, society = '',
            blip = { enabled = true, sprite = 427, color = 5, scale = 0.8, label = 'Location bateaux', shortRange = true },
            fleet = { { model = 'dinghy', label = 'Zodiac', price = 250, deposit = 500, minGrade = 0 }, { model = 'seashark', label = 'Jet-ski', price = 180, deposit = 400, minGrade = 0 } } },
        points = { { label = 'Location bateaux', blip = true, ped = ped('a_m_y_beach_01'), spawns = {} } },
    },
}

-- ─────────────────────────────── Stations essence ───────────────────────────────
Config.Templates.fuel = {
    station = {
        label = 'Station essence', icon = 'fuel',
        settings = { price = 3.0, tank = 5000, restockMinutes = 60, restockLiters = 200, payments = { cash = true, bank = true }, society = '',
            jerrycan = { enabled = true, price = 80, item = 'WEAPON_PETROLCAN' },
            blip = { enabled = true, sprite = 361, color = 1, scale = 0.7, label = 'Station essence', shortRange = true } },
        points = { { label = 'Pompe 1', kind = 'pump', blip = true, ped = noPed }, { label = 'Pompe 2', kind = 'pump', blip = false, ped = noPed } },
    },
}

-- ─────────────────────────────── Zones PVP ───────────────────────────────
Config.Templates.pvp = {
    arena = {
        label = 'Zones PVP', icon = 'target',
        settings = { note = 'Les zones se placent en jeu : position = centre', rewardAccount = 'bank',
            blip = { enabled = true, sprite = 311, color = 1, scale = 0.8, label = 'Zones PVP', shortRange = true } },
        points = { { kind = 'lobby', label = 'Zones PVP', blip = true, ped = ped('s_m_y_ammucity_01', 'WORLD_HUMAN_GUARD_STAND') },
            { kind = 'zone', label = 'Arène', blip = true, radius = 60, color = { 239, 68, 68 }, reviveEnabled = true, reviveDelay = 5, giveWeapons = true, removeOnExit = true, infiniteAmmo = false,
                healOnKill = true, armorOnRespawn = true, killReward = 100, spawnProtection = 3, spawns = {},
                weapons = { { name = 'WEAPON_PISTOL', ammo = 250 }, { name = 'WEAPON_CARBINERIFLE', ammo = 250 }, { name = 'WEAPON_PUMPSHOTGUN', ammo = 60 } } } },
    },
}

-- ─────────────────────────────── Course poursuite ───────────────────────────────
local function cv(model, label, category, speed, accel, handling) return { model = model, label = label, category = category, speed = speed, accel = accel, handling = handling } end
Config.Templates.chase = {
    course = {
        label = 'Course poursuite', icon = 'flag',
        settings = { note = 'Un fugitif contre des poursuivants : colle le fugitif assez longtemps pour gagner', catchDistance = 8, catchTime = 3, headStart = 10, countdown = 5,
            rewardAccount = 'bank', entryFee = 2000, rewardWin = 0, rewardLose = 0, maxChasers = 4, durationMin = 2, durationMax = 20, durationDefault = 8,
            requireVehicle = true, maxPerformance = true, runnerSeesChasers = true, traffic = true,
            blip = { enabled = true, sprite = 315, color = 3, scale = 0.8, label = 'Course poursuite', shortRange = true },
            vehicles = {
                cv('sultan', 'Karin Sultan', 'Sportive', 68, 66, 72), cv('elegy2', 'Annis Elegy RH8', 'Sportive', 74, 70, 78), cv('jester', 'Dinka Jester', 'Sportive', 78, 74, 75),
                cv('kuruma', 'Karin Kuruma', 'Sportive', 72, 70, 70), cv('comet2', 'Pfister Comet', 'Sportive', 76, 72, 77), cv('zentorno', 'Pegassi Zentorno', 'Super', 90, 88, 80),
                cv('adder', 'Truffade Adder', 'Super', 92, 82, 72), cv('t20', 'Progen T20', 'Super', 93, 90, 78), cv('vacca', 'Pegassi Vacca', 'Super', 86, 84, 78),
                cv('dominator', 'Vapid Dominator', 'Muscle', 74, 78, 55), cv('gauntlet', 'Bravado Gauntlet', 'Muscle', 72, 76, 52), cv('buffalo', 'Bravado Buffalo', 'Berline', 70, 68, 70),
                cv('schafter3', 'Benefactor Schafter V12', 'Berline', 70, 66, 68), cv('bati', 'Pegassi Bati 801', 'Moto', 84, 92, 82), cv('akuma', 'Dinka Akuma', 'Moto', 82, 90, 80),
                cv('sanchez', 'Maibatsu Sanchez', 'Moto', 62, 74, 78),
            } },
        points = { { kind = 'lobby', label = 'Course poursuite', blip = true, ped = ped('s_m_y_cop_01', 'WORLD_HUMAN_CLIPBOARD') },
            { kind = 'map', label = 'Vinewood Boulevard', desc = 'Grandes avenues et carrefours, trafic dense.', coords = { x = 293.1, y = 180.5, z = 104.2, h = 70.0 } },
            { kind = 'map', label = 'Del Perro Freeway', desc = 'Autoroute rapide, idéale pour les supercars.', coords = { x = -1105.0, y = -520.0, z = 34.0, h = 215.0 } },
            { kind = 'map', label = 'Route 68 – Sandy', desc = 'Longues lignes droites dans le désert.', coords = { x = 1583.0, y = 3584.0, z = 35.4, h = 300.0 } } },
    },
}

-- ─────────────────────────────── Occasion (annonces) ───────────────────────────────
Config.Templates.carlot = {
    lot = {
        label = 'Parking d\'occasion', icon = 'car',
        settings = { listingFee = 100, commission = 5, maxListings = 3, durationDays = 7, minPrice = 500, maxPrice = 5000000, showPlate = false, payments = { cash = true, bank = true }, society = '',
            blip = { enabled = true, sprite = 225, color = 25, scale = 0.8, label = 'Occasion', shortRange = true } },
        points = { { kind = 'lot', label = 'Bureau des annonces', blip = true, ped = ped('a_m_y_business_03', 'WORLD_HUMAN_CLIPBOARD') },
            { kind = 'slot', label = 'Place 1' }, { kind = 'slot', label = 'Place 2' }, { kind = 'slot', label = 'Place 3' }, { kind = 'slot', label = 'Place 4' } },
    },
}

-- ─────────────────────────────── Portes ───────────────────────────────
local function lockPoint(label, jobs, jobs2)
    return { kind = 'lock', label = label, blip = false, locked = true, autoLock = 0, access = { jobs = jobs or {}, jobs2 = jobs2 or {}, item = '' }, doors = {} }
end
Config.Templates.doorlock = {
    job = {
        label = 'Portes de métier (ex : commissariat)', icon = 'shield',
        settings = { note = 'Réservées au métier choisi' },
        points = { lockPoint('Porte d\'entrée', { police = 0 }), lockPoint('Cellules', { police = 2 }) },
    },
    gang = {
        label = 'Portes de gang (job2)', icon = 'lock',
        settings = { note = 'Réservées au gang : renseigne le job2 dans chaque porte' },
        points = { lockPoint('Porte de la planque', {}, {}) },
    },
    custom = {
        label = 'Porte personnalisée', icon = 'lock',
        settings = { note = '' },
        points = {},
    },
}

-- ─────────────────────────────── Serruriers ───────────────────────────────
Config.Templates.locksmith = {
    shop = {
        label = 'Serrurier', icon = 'key',
        settings = { price = 250, requireNearby = true, keyItem = '', cooldown = 60, payments = { cash = true, bank = true }, society = '',
            blip = { enabled = true, sprite = 402, color = 5, scale = 0.8, label = 'Serrurier', shortRange = true } },
        points = { { kind = 'shop', label = 'Atelier de serrurier', blip = true, ped = ped('s_m_y_construct_01', 'WORLD_HUMAN_CLIPBOARD') } },
    },
}

-- ─────────────────────────────── Stations de lavage ───────────────────────────────
Config.Templates.carwash = {
    station = {
        label = 'Station de lavage', icon = 'drop',
        settings = { payments = { cash = true, bank = true }, society = '',
            blip = { enabled = true, sprite = 100, color = 3, scale = 0.8, label = 'Station de lavage', shortRange = true },
            programs = { { label = 'Lavage rapide', price = 30, seconds = 6 }, { label = 'Lavage complet', price = 60, seconds = 12 }, { label = 'Lavage premium', price = 120, seconds = 20 } } },
        points = { { kind = 'wash', label = 'Baie de lavage 1', blip = true, ped = noPed }, { kind = 'wash', label = 'Baie de lavage 2', blip = false, ped = noPed } },
    },
}

-- ─────────────────────────────── Banques ───────────────────────────────
Config.Templates.bank = {
    branch = {
        label = 'Agence bancaire', icon = 'dollar',
        settings = { depositFee = 0, withdrawFee = 0, transferFee = 2, maxTransaction = 0, dailyLimit = 0, atmDeposit = false, society = '',
            blip = { enabled = true, sprite = 108, color = 2, scale = 0.8, label = 'Banque', shortRange = true } },
        points = { { kind = 'counter', label = 'Guichet', blip = true, ped = ped('ig_bankman', 'WORLD_HUMAN_CLIPBOARD') },
            { kind = 'atm', label = 'Distributeur', blip = false, ped = noPed } },
    },
    atm = {
        label = 'Distributeurs (ATM)', icon = 'card',
        settings = { depositFee = 0, withdrawFee = 1, transferFee = 2, maxTransaction = 5000, dailyLimit = 10000, atmDeposit = false, society = '',
            blip = { enabled = true, sprite = 277, color = 2, scale = 0.6, label = 'ATM', shortRange = true } },
        points = { { kind = 'atm', label = 'Distributeur', blip = true, ped = noPed } },
    },
}

-- ─────────────────────────────── Auto-écoles ───────────────────────────────
local function Q(q, a, b, c, d, correct) return { q = q, answers = { a, b, c, d }, correct = correct } end
local CODE = {
    Q('Quelle est la vitesse maximale en agglomération ?', '30 km/h', '50 km/h', '70 km/h', '90 km/h', 2),
    Q('Que signifie un feu orange fixe ?', 'Accélérer', 'Je peux passer si je veux', 'Je dois m\'arrêter sauf si je ne peux plus le faire en sécurité', 'Le feu est en panne', 3),
    Q('À une intersection sans signalisation, qui est prioritaire ?', 'Le véhicule le plus rapide', 'Le véhicule venant de ma droite', 'Le véhicule venant de ma gauche', 'Le plus gros véhicule', 2),
    Q('Quelle est la distance de sécurité minimale recommandée ?', '2 secondes', '10 secondes', '0,5 seconde', 'Aucune', 1),
    Q('Que faire en voyant un piéton engagé sur un passage piéton ?', 'Klaxonner', 'Accélérer', 'M\'arrêter pour le laisser passer', 'Le contourner', 3),
    Q('Peut-on téléphoner en conduisant (sans kit mains libres) ?', 'Oui', 'Uniquement en ville', 'Non, c\'est interdit', 'Seulement à l\'arrêt au feu', 3),
    Q('Que signifie un panneau STOP ?', 'Ralentir', 'Marquer un arrêt complet', 'Céder le passage sans m\'arrêter', 'Stationnement interdit', 2),
    Q('Que faire à l\'approche d\'un véhicule d\'urgence sirène activée ?', 'Accélérer', 'Ne rien changer', 'Me ranger pour le laisser passer', 'Le suivre de près', 3),
    Q('La ceinture de sécurité est obligatoire :', 'À l\'avant uniquement', 'En ville uniquement', 'Pour tous les occupants', 'Sur autoroute seulement', 3),
    Q('Que faut-il faire avant de changer de voie ?', 'Rien de particulier', 'Mettre le clignotant et vérifier les angles morts', 'Klaxonner', 'Accélérer brusquement', 2),
    Q('Quelle est la conséquence d\'une conduite sous l\'emprise de l\'alcool ?', 'Aucune', 'Un avertissement', 'Amende, retrait de points voire de permis', 'Une simple remarque', 3),
    Q('Sur route mouillée, la distance de freinage est :', 'Identique', 'Plus courte', 'Beaucoup plus longue', 'Nulle', 3),
}
local function license(id, label, requires, tp, pp, theory, model, speed)
    return { id = id, label = label, requires = requires, theoryPrice = tp, practicalPrice = pp,
        theory = { enabled = theory, count = 10, passPercent = 80, questions = theory and CODE or {} },
        practical = { enabled = model ~= nil, model = model or '', speedLimit = speed or 80, maxFaults = 5 } }
end

Config.Templates.driving = {
    school = {
        label = 'Auto-école', icon = 'book',
        settings = { payments = { cash = true, bank = true }, society = '', cooldown = 5,
            blip = { enabled = true, sprite = 225, color = 3, scale = 0.8, label = 'Auto-école', shortRange = true },
            licenses = {
                license('code', 'Code de la route', '', 200, 0, true, nil),
                license('drive', 'Permis B (voiture)', 'code', 0, 500, false, 'blista', 80),
                license('drive_bike', 'Permis moto', 'code', 0, 400, false, 'sanchez', 80),
                license('drive_truck', 'Permis poids lourd', 'drive', 0, 900, false, 'mule', 70),
            } },
        points = { { kind = 'desk', label = 'Accueil', blip = true, ped = ped('a_f_y_business_01', 'WORLD_HUMAN_CLIPBOARD') },
            { kind = 'spawn', label = 'Départ voiture d\'examen' },
            { kind = 'checkpoint', label = 'Point 1' }, { kind = 'checkpoint', label = 'Point 2' }, { kind = 'checkpoint', label = 'Point 3' }, { kind = 'checkpoint', label = 'Arrivée' } },
    },
    custom = {
        label = 'Auto-école vide', icon = 'book',
        settings = { payments = { cash = true, bank = true }, society = '', cooldown = 5, licenses = {} },
        points = { { kind = 'desk', label = 'Accueil', blip = true, ped = noPed } },
    },
}

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

Config.Templates.drug = {
    weed = {
        label = 'Cannabis', icon = 'leaf',
        settings = { note = 'Champ → séchage → vente' },
        points = {
            harvest('Champ de cannabis', 'weed', 6, 'harvest'),
            process('Séchage & conditionnement', { { label = 'Pochon de cannabis', inputs = { { item = 'weed', count = 3 } }, outputs = { { item = 'weed_pooch', count = 1 } }, time = 8 } }, 'inspect'),
            sell('Dealer — cannabis', { { item = 'weed_pooch', min = 90, max = 140 } }),
        },
    },
    coke = {
        label = 'Cocaïne', icon = 'flask',
        settings = { note = 'Feuilles de coca → laboratoire → vente' },
        points = {
            harvest('Plantation de coca', 'coke', 8, 'harvest', { max = 4 }),
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
        blip = { enabled = false, sprite = 52, color = 1, scale = 0.8, label = '', shortRange = true } }
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
            blip = { enabled = false, sprite = 108, color = 1, scale = 0.9, label = 'Banque', shortRange = true } }),
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
