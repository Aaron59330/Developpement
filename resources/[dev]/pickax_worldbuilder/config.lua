Config = {}
-- Taille des blips par défaut : celle de tout le serveur (pickax_core/config.lua → Config.GlobalBlip.Scale), sinon la valeur donnée.
-- Un blip réglé en jeu dans un builder garde sa taille.
local function PK_BSF(default) return (PickaxTheme and PickaxTheme.blipScale) or default end

-- ─────────────────────────────── Général ───────────────────────────────
Config.AllowedGroups   = { '_dev', 'admin', 'superadmin' }   -- groupes ESX autorisés à ouvrir le builder
Config.AcePermission   = 'worldbuilder.admin'                -- (optionnel) permission ACE alternative
Config.Command         = 'worldbuilder'                      -- /worldbuilder ouvre le builder
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
        ['impound.main']   = 'Bonjour, vous souhaitez payer pour récupérer un de vos véhicules dans la fourrière ?',
        ['garage.main']    = 'Bonjour, souhaitez-vous accéder à votre garage ?',
        ['rental.main']    = 'Bonjour, vous souhaitez louer un véhicule ?',
        ['bank.counter']   = 'Bonjour, souhaitez-vous accéder à votre compte bancaire ?',
        ['driving.desk']   = 'Bonjour, vous souhaitez passer votre permis de conduire ?',
        ['carlot.lot']     = 'Bonjour, souhaitez-vous consulter les annonces de véhicules ?',
        ['locksmith.shop'] = 'Bonjour, vous avez besoin d\'un service de serrurerie ?',
        ['pvp.lobby']      = 'Prêt pour le combat ? Souhaitez-vous rejoindre une zone PVP ?',
        ['chase.lobby']    = 'Envie d\'adrénaline ? Voulez-vous lancer une course poursuite ?',
        ['jobcenter.desk'] = 'Bonjour ! Vous cherchez du travail ? J\'ai plusieurs petits jobs à vous proposer.',
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
-- Marker par défaut : celui de tout le serveur (pickax_core/config.lua → Config.GlobalMarker) ; réglable ensuite en jeu (prioritaire)
local PK_MK = PickaxTheme and PickaxTheme.marker
Config.Marker = PK_MK and { type = PK_MK.type, color = { PK_MK.color[1], PK_MK.color[2], PK_MK.color[3] }, alpha = PK_MK.alpha, scale = { x = PK_MK.scale.x, y = PK_MK.scale.y, z = PK_MK.scale.z }, offset = -0.95 }
    or { type = 25, color = { 64, 224, 208 }, alpha = 140, scale = { x = 0.9, y = 0.9, z = 0.6 }, offset = -0.95 }
Config.UI = { Accent = (PickaxTheme and PickaxTheme.rgb) or { 0, 164, 255 } }   -- couleur d'accentuation (modifiable en jeu : Paramètres → Apparence)

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
    jobcenter = { label = 'Pôles emploi',      one = 'Pôle emploi',       icon = 'users',  sub = 'Petits jobs en libre accès : un clic = embauché, puis des petites quêtes' },
}
Config.TypeOrder = { 'garage', 'impound', 'rental', 'pvp', 'chase', 'carlot', 'doorlock', 'fuel', 'carwash', 'locksmith', 'bank', 'driving', 'jobcenter' }

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
            blip = { enabled = true, sprite = 357, color = 3, scale = PK_BSF(0.8), label = 'Garage', shortRange = true } },
        points = { { label = 'Garage', blip = true, ped = ped('s_m_y_valet_01', 'WORLD_HUMAN_CLIPBOARD'), spawns = {} } },
    },
    boat = {
        label = 'Port / Marina', icon = 'boat',
        settings = { mode = 'owned', types = { 'boat' }, fee = 0, bound = false, payments = { cash = true, bank = true },
            blip = { enabled = true, sprite = 427, color = 3, scale = PK_BSF(0.8), label = 'Port', shortRange = true } },
        points = { { label = 'Port', blip = true, ped = noPed, spawns = {} } },
    },
    air = {
        label = 'Hangar', icon = 'plane',
        settings = { mode = 'owned', types = { 'aircraft' }, fee = 0, bound = false, payments = { cash = true, bank = true },
            blip = { enabled = true, sprite = 359, color = 3, scale = PK_BSF(0.8), label = 'Hangar', shortRange = true } },
        points = { { label = 'Hangar', blip = true, ped = noPed, spawns = {} } },
    },
    job = {
        label = 'Garage de métier (flotte)', icon = 'shield',
        settings = { mode = 'job', types = {}, fee = 0, bound = false, payments = { cash = true }, access = { jobs = { police = 0 } },
            blip = { enabled = true, sprite = 357, color = 38, scale = PK_BSF(0.8), label = 'Garage de service', shortRange = true },
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
        settings = { fee = 150, perDay = 20, maxFee = 600, types = {}, payments = { cash = true, bank = true }, society = '',
            impoundJobs = { police = 0, sheriff = 0, mechanic = 0 },
            blip = { enabled = true, sprite = 68, color = 47, scale = PK_BSF(0.8), label = 'Fourrière', shortRange = true } },
        points = { { label = 'Fourrière', blip = true, ped = ped('s_m_y_construct_01', 'WORLD_HUMAN_CLIPBOARD'), spawns = {} } },
    },
}

-- ─────────────────────────────── Locations de véhicules ───────────────────────────────
Config.Templates.rental = {
    cars = {
        label = 'Location de voitures', icon = 'key',
        settings = { minutes = 60, refundDamage = true, payments = { cash = true, bank = true }, society = '',
            blip = { enabled = true, sprite = 225, color = 5, scale = PK_BSF(0.8), label = 'Location', shortRange = true },
            fleet = {
                { model = 'faggio',  label = 'Scooter',        price = 30,  deposit = 100,  minGrade = 0 },
                { model = 'panto',   label = 'Citadine',       price = 40,  deposit = 150,  minGrade = 0 },
                { model = 'blista',  label = 'Compacte',       price = 55,  deposit = 200,  minGrade = 0 },
                { model = 'sultan',  label = 'Berline sport',  price = 150, deposit = 500, minGrade = 0 },
            } },
        points = { { label = 'Agence de location', blip = true, ped = ped('a_m_y_business_02'), spawns = {} } },
    },
    boats = {
        label = 'Location de bateaux', icon = 'boat',
        settings = { minutes = 60, refundDamage = true, payments = { cash = true, bank = true }, society = '',
            blip = { enabled = true, sprite = 427, color = 5, scale = PK_BSF(0.8), label = 'Location bateaux', shortRange = true },
            fleet = { { model = 'dinghy', label = 'Zodiac', price = 120, deposit = 300, minGrade = 0 }, { model = 'seashark', label = 'Jet-ski', price = 90, deposit = 250, minGrade = 0 } } },
        points = { { label = 'Location bateaux', blip = true, ped = ped('a_m_y_beach_01'), spawns = {} } },
    },
}

-- ─────────────────────────────── Stations essence ───────────────────────────────
Config.Templates.fuel = {
    station = {
        label = 'Station essence', icon = 'fuel',
        settings = { price = 2.0, tank = 5000, restockMinutes = 60, restockLiters = 200, payments = { cash = true, bank = true }, society = '',
            jerrycan = { enabled = true, price = 30, item = 'WEAPON_PETROLCAN' },
            blip = { enabled = true, sprite = 361, color = 1, scale = PK_BSF(0.7), label = 'Station essence', shortRange = true } },
        points = { { label = 'Pompe 1', kind = 'pump', blip = true, ped = noPed }, { label = 'Pompe 2', kind = 'pump', blip = false, ped = noPed } },
    },
}

-- ─────────────────────────────── Zones PVP ───────────────────────────────
Config.Templates.pvp = {
    arena = {
        label = 'Zones PVP', icon = 'target',
        settings = { note = 'Les zones se placent en jeu : position = centre', rewardAccount = 'bank',
            blip = { enabled = true, sprite = 311, color = 1, scale = PK_BSF(0.8), label = 'Zones PVP', shortRange = true } },
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
            blip = { enabled = true, sprite = 315, color = 3, scale = PK_BSF(0.8), label = 'Course poursuite', shortRange = true },
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
        settings = { listingFee = 20, commission = 5, maxListings = 3, durationDays = 7, minPrice = 500, maxPrice = 5000000, showPlate = false, payments = { cash = true, bank = true }, society = '',
            blip = { enabled = true, sprite = 225, color = 25, scale = PK_BSF(0.8), label = 'Occasion', shortRange = true } },
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
        settings = { price = 80, requireNearby = true, keyItem = '', cooldown = 60, payments = { cash = true, bank = true }, society = '',
            blip = { enabled = true, sprite = 402, color = 5, scale = PK_BSF(0.8), label = 'Serrurier', shortRange = true } },
        points = { { kind = 'shop', label = 'Atelier de serrurier', blip = true, ped = ped('s_m_y_construct_01', 'WORLD_HUMAN_CLIPBOARD') } },
    },
}

-- ─────────────────────────────── Stations de lavage ───────────────────────────────
Config.Templates.carwash = {
    station = {
        label = 'Station de lavage', icon = 'drop',
        settings = { payments = { cash = true, bank = true }, society = '',
            blip = { enabled = true, sprite = 100, color = 3, scale = PK_BSF(0.8), label = 'Station de lavage', shortRange = true },
            programs = { { label = 'Lavage rapide', price = 8, seconds = 6 }, { label = 'Lavage complet', price = 15, seconds = 12 }, { label = 'Lavage premium', price = 30, seconds = 20 } } },
        points = { { kind = 'wash', label = 'Baie de lavage 1', blip = true, ped = noPed }, { kind = 'wash', label = 'Baie de lavage 2', blip = false, ped = noPed } },
    },
}

-- ─────────────────────────────── Banques ───────────────────────────────
Config.Templates.bank = {
    branch = {
        label = 'Agence bancaire', icon = 'dollar',
        settings = { depositFee = 0, withdrawFee = 0, transferFee = 2, maxTransaction = 0, dailyLimit = 0, atmDeposit = false, society = '',
            blip = { enabled = true, sprite = 108, color = 2, scale = PK_BSF(0.8), label = 'Banque', shortRange = true } },
        points = { { kind = 'counter', label = 'Guichet', blip = true, ped = ped('ig_bankman', 'WORLD_HUMAN_CLIPBOARD') },
            { kind = 'atm', label = 'Distributeur', blip = false, ped = noPed } },
    },
    atm = {
        label = 'Distributeurs (ATM)', icon = 'card',
        settings = { depositFee = 0, withdrawFee = 1, transferFee = 2, maxTransaction = 500, dailyLimit = 1000, atmDeposit = false, society = '',
            blip = { enabled = true, sprite = 277, color = 2, scale = PK_BSF(0.6), label = 'ATM', shortRange = true } },
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
            blip = { enabled = true, sprite = 225, color = 3, scale = PK_BSF(0.8), label = 'Auto-école', shortRange = true },
            licenses = {
                license('code', 'Code de la route', '', 30, 0, true, nil),
                license('drive', 'Permis B (voiture)', 'code', 0, 900, false, 'blista', 80),
                license('drive_bike', 'Permis moto', 'code', 0, 700, false, 'sanchez', 80),
                license('drive_truck', 'Permis poids lourd', 'drive', 0, 1800, false, 'mule', 70),
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


-- ─────────────────────────────── Pôle emploi : petits jobs en libre accès ───────────────────────────────
-- Un module « Pôle emploi » (/worldbuilder → Nouveau module) place un guichet : le joueur clique sur un job et il est embauché (setJob).
-- Dès qu'un module Pôle emploi est enregistré, les jobs ci-dessous sont créés tout seuls dans la base (jobs + job_grades + fiche jobbuilder
-- pour le menu F6) puis rechargés. Chaque job a des petites quêtes (aller sur place, travailler avec une animation, être payé).
Config.JobCenter = {
    Enabled        = true,
    FreeJobs       = { 'unemployed' },     -- métiers dont on peut partir directement vers un petit job (en plus des petits jobs eux-mêmes)
    RewardAccount  = 'money',              -- compte crédité à la fin d'une quête
    Cooldown       = 45,                   -- secondes avant de refaire la même quête
    Tolerance      = 60.0,                 -- distance serveur tolérée autour d'une étape (m)
    Promotions     = { 10, 30 },           -- quêtes terminées pour passer au grade 1 puis 2 dans ce job (promotion automatique)
    GradeBonus     = { 0, 15, 30 },        -- % de gain supplémentaire par grade (0, 1, 2)
    Locations = {                          -- lieux tirés au hasard pour les quêtes (x, y, z, cap)
        { 'Legion Square',          195.17,  -933.77,  30.69, 160.0 },
        { 'Grove Street',           110.50, -1944.00,  20.80,  40.0 },
        { 'Jetée de Del Perro',   -1850.60, -1233.20,  13.02, 140.0 },
        { 'Mission Row',            428.00,  -984.00,  30.70,  90.0 },
        { 'Downtown Cab Co.',       909.00,  -176.00,  74.20, 240.0 },
        { 'Maze Bank',              -67.00,  -801.00,  44.20, 340.0 },
        { 'Hôpital Pillbox',        298.60,  -584.40,  43.26,  70.0 },
        { 'Aéroport LSIA',        -1037.50, -2737.80,  20.17, 330.0 },
        { 'Sandy Shores',          1961.50,  3741.50,  32.34, 300.0 },
        { 'Harmony',                549.00,  2671.00,  42.20, 100.0 },
        { 'Grapeseed',             1698.00,  4924.00,  42.10, 320.0 },
        { 'Paleto Bay',            -102.00,  6467.00,  31.60,  45.0 },
        { 'Chumash',              -3040.00,   585.00,   7.90,  20.0 },
    },
    -- Jobs : name = nom en base (libre accès, non whitelisté), 3 grades (salaire = paie ESX ; l'essentiel du gain vient des quêtes)
    -- Quête : spots = nombre de lieux visités, anim = animation de travail (Config.Animations), secs = durée par lieu
    Jobs = {
        { name = 'jardinier', label = 'Jardinier', icon = 'leaf', desc = 'Tondre, tailler et entretenir les jardins des particuliers.',
          grades = { { 'apprenti', 'Apprenti jardinier', 15 }, { 'confirme', 'Jardinier confirmé', 25 }, { 'maitre', 'Maître jardinier', 40 } },
          quests = {
            { id = 'tonte',   label = 'Tonte de pelouse',  desc = 'Un particulier veut sa pelouse tondue.',          spots = 2, anim = 'harvest', secs = 10, go = 'Rends-toi chez le client',     work = 'Tondre la pelouse',     reward = { 55, 85 } },
            { id = 'taille',  label = 'Taille de haies',   desc = 'Taille les haies d\'une propriété.',              spots = 2, anim = 'pickup',  secs = 9,  go = 'Rends-toi à la propriété',    work = 'Tailler la haie',       reward = { 60, 90 } },
            { id = 'plantes', label = 'Plantation',        desc = 'Plante des massifs de fleurs dans un parc.',      spots = 3, anim = 'harvest', secs = 8,  go = 'Rends-toi au parc',           work = 'Planter les fleurs',    reward = { 80, 120 } },
          } },
        { name = 'bricoleur', label = 'Bricoleur', icon = 'wrench', desc = 'Petites réparations et montages chez les particuliers.',
          grades = { { 'apprenti', 'Apprenti bricoleur', 15 }, { 'confirme', 'Bricoleur confirmé', 25 }, { 'maitre', 'Maître bricoleur', 40 } },
          quests = {
            { id = 'meuble',  label = 'Montage de meuble', desc = 'Monte un meuble en kit.',                         spots = 1, anim = 'repair',  secs = 14, go = 'Rends-toi chez le client',     work = 'Monter le meuble',      reward = { 50, 75 } },
            { id = 'etagere', label = 'Pose d\'étagères', desc = 'Fixe des étagères au mur.',                       spots = 2, anim = 'drill',   secs = 10, go = 'Rends-toi chez le client',     work = 'Percer et fixer',       reward = { 65, 95 } },
            { id = 'porte',   label = 'Réparation de porte', desc = 'Une porte ferme mal : répare-la.',              spots = 2, anim = 'hammer',  secs = 10, go = 'Rends-toi sur place',          work = 'Réparer la porte',      reward = { 70, 100 } },
          } },
        { name = 'electricien', label = 'Électricien', icon = 'bolt', desc = 'Installations et dépannages électriques.',
          grades = { { 'apprenti', 'Apprenti électricien', 18 }, { 'confirme', 'Électricien confirmé', 30 }, { 'maitre', 'Maître électricien', 45 } },
          quests = {
            { id = 'prises',  label = 'Changer des prises', desc = 'Remplace des prises défectueuses.',              spots = 2, anim = 'repair',  secs = 10, go = 'Rends-toi chez le client',     work = 'Changer la prise',      reward = { 65, 95 } },
            { id = 'panne',   label = 'Panne de courant',   desc = 'Un commerce n\'a plus de courant : dépanne-le.', spots = 1, anim = 'weld',    secs = 14, go = 'Rends-toi au commerce',        work = 'Réparer le tableau',    reward = { 75, 110 } },
            { id = 'lampes',  label = 'Éclairage public',   desc = 'Remplace des lampadaires en panne.',             spots = 3, anim = 'repair',  secs = 8,  go = 'Rends-toi au lampadaire',      work = 'Changer l\'ampoule',    reward = { 90, 130 } },
          } },
        { name = 'plombier', label = 'Plombier', icon = 'drop', desc = 'Fuites, canalisations et sanitaires.',
          grades = { { 'apprenti', 'Apprenti plombier', 18 }, { 'confirme', 'Plombier confirmé', 30 }, { 'maitre', 'Maître plombier', 45 } },
          quests = {
            { id = 'fuite',   label = 'Fuite d\'eau',      desc = 'Une fuite inonde une cuisine.',                  spots = 1, anim = 'repair',  secs = 12, go = 'Rends-toi chez le client',     work = 'Réparer la fuite',      reward = { 60, 90 } },
            { id = 'evier',   label = 'Évier bouché',      desc = 'Débouche des éviers chez deux clients.',         spots = 2, anim = 'pickup',  secs = 9,  go = 'Rends-toi chez le client',     work = 'Déboucher l\'évier',   reward = { 65, 95 } },
            { id = 'chaudiere', label = 'Entretien de chaudière', desc = 'Entretien annuel de chaudières.',        spots = 2, anim = 'weld',    secs = 12, go = 'Rends-toi chez le client',     work = 'Entretenir la chaudière', reward = { 85, 125 } },
          } },
        { name = 'demenageur', label = 'Déménageur', icon = 'box', desc = 'Porter cartons et meubles d\'un logement à l\'autre.',
          grades = { { 'apprenti', 'Porteur', 15 }, { 'confirme', 'Déménageur confirmé', 25 }, { 'maitre', 'Chef d\'équipe', 40 } },
          quests = {
            { id = 'cartons', label = 'Porter des cartons', desc = 'Charge des cartons dans le camion.',             spots = 2, anim = 'pickup',  secs = 8,  go = 'Rends-toi au logement',        work = 'Charger les cartons',   reward = { 50, 80 } },
            { id = 'canape',  label = 'Déplacer un canapé', desc = 'Un canapé doit changer d\'étage.',               spots = 1, anim = 'pickup',  secs = 14, go = 'Rends-toi chez le client',     work = 'Déplacer le canapé',    reward = { 55, 85 } },
            { id = 'grand',   label = 'Grand déménagement', desc = 'Vide entièrement un appartement.',               spots = 3, anim = 'pickup',  secs = 10, go = 'Rends-toi à l\'appartement',  work = 'Vider la pièce',        reward = { 90, 130 } },
          } },
        { name = 'laveurvitres', label = 'Laveur de vitres', icon = 'drop', desc = 'Vitres et vitrines des commerces et des bureaux.',
          grades = { { 'apprenti', 'Apprenti laveur', 15 }, { 'confirme', 'Laveur confirmé', 25 }, { 'maitre', 'Maître laveur', 40 } },
          quests = {
            { id = 'vitrine', label = 'Vitrines de commerce', desc = 'Nettoie les vitrines d\'une rue commerçante.', spots = 2, anim = 'clean',   secs = 9,  go = 'Rends-toi au commerce',        work = 'Nettoyer la vitrine',   reward = { 50, 80 } },
            { id = 'bureaux', label = 'Fenêtres de bureaux', desc = 'Lave les fenêtres d\'un immeuble de bureaux.', spots = 2, anim = 'clean',   secs = 11, go = 'Rends-toi à l\'immeuble',     work = 'Laver les fenêtres',    reward = { 60, 95 } },
            { id = 'tour',    label = 'Façade de tour',      desc = 'Façade complète d\'une grande tour.',           spots = 3, anim = 'clean',   secs = 10, go = 'Rends-toi à la tour',          work = 'Laver la façade',       reward = { 90, 130 } },
          } },
        { name = 'ouvrierbtp', label = 'Ouvrier de chantier', icon = 'tool', desc = 'Petits travaux sur les chantiers de la ville.',
          grades = { { 'manoeuvre', 'Manœuvre', 18 }, { 'confirme', 'Ouvrier qualifié', 30 }, { 'maitre', 'Chef de chantier', 45 } },
          quests = {
            { id = 'perforer', label = 'Perçage de dalle', desc = 'Perce la dalle d\'un chantier.',                  spots = 1, anim = 'drill',   secs = 14, go = 'Rends-toi sur le chantier',    work = 'Percer la dalle',       reward = { 60, 90 } },
            { id = 'soudure',  label = 'Soudure de poutres', desc = 'Soude des poutres métalliques.',                spots = 2, anim = 'weld',    secs = 11, go = 'Rends-toi sur le chantier',    work = 'Souder la poutre',      reward = { 75, 110 } },
            { id = 'coffrage', label = 'Coffrage',           desc = 'Assemble des coffrages en bois.',               spots = 3, anim = 'hammer',  secs = 9,  go = 'Rends-toi sur le chantier',    work = 'Assembler le coffrage', reward = { 90, 135 } },
          } },
        { name = 'gazoline', label = 'Gazoline', icon = 'tool', desc = 'Ravitaille les stations-service : charge une citerne au dépôt et livre le carburant (/gazdepot pour définir le dépôt).',
          grades = { { 'livreur', 'Livreur', 80 }, { 'chauffeur', 'Chauffeur citerne', 110 }, { 'chef', 'Chef de dépôt', 150 } },
          quests = {
            { id = 'pompes',  label = 'Contrôle des pompes', desc = 'Vérifie les pompes d\'une station.',            spots = 2, anim = 'clipboard', secs = 8,  go = 'Rends-toi à la station',      work = 'Contrôler les pompes', reward = { 40, 70 } },
            { id = 'jauges',  label = 'Relevé des cuves',    desc = 'Relève le niveau des cuves.',                    spots = 2, anim = 'clipboard', secs = 8,  go = 'Rends-toi à la station',      work = 'Relever les cuves',    reward = { 40, 70 } },
          } },
        { name = 'coursier', label = 'Coursier', icon = 'cart', desc = 'Livrer colis et courses aux particuliers.',
          grades = { { 'stagiaire', 'Coursier stagiaire', 15 }, { 'confirme', 'Coursier confirmé', 25 }, { 'maitre', 'Coursier expert', 40 } },
          quests = {
            { id = 'colis',   label = 'Livraison de colis', desc = 'Dépose un colis chez un particulier.',          spots = 2, anim = 'clipboard', secs = 6, go = 'Rends-toi chez le destinataire', work = 'Remettre le colis',     reward = { 45, 75 } },
            { id = 'courses', label = 'Livraison de courses', desc = 'Apporte des courses à domicile.',             spots = 2, anim = 'pickup',    secs = 6, go = 'Rends-toi chez le client',       work = 'Déposer les courses',   reward = { 50, 80 } },
            { id = 'express', label = 'Tournée express',    desc = 'Une tournée de plusieurs livraisons urgentes.',  spots = 4, anim = 'clipboard', secs = 5, go = 'Rends-toi au prochain client',   work = 'Remettre le colis',     reward = { 100, 150 } },
          } },
    },
}
Config.Templates.jobcenter = {
    office = {
        label = 'Pôle emploi', icon = 'users',
        settings = { blip = { enabled = true, sprite = 351, color = 3, scale = PK_BSF(0.8), label = 'Pôle emploi', shortRange = true } },
        points = { { kind = 'desk', label = 'Pôle emploi', blip = true, ped = ped('a_f_y_business_01', 'WORLD_HUMAN_CLIPBOARD') } },
    },
}

-- Jobs / quêtes / lieux au format modifiable dans le builder (module Pôle emploi → onglet « Jobs & quêtes »)
function Config.JobCenterDefaults()
    local jobs, locs = {}, {}
    for _, j in ipairs(Config.JobCenter.Jobs) do
        local g, q = {}, {}
        for _, x in ipairs(j.grades) do g[#g + 1] = { label = x[2], salary = x[3] } end
        for _, x in ipairs(j.quests) do q[#q + 1] = { id = x.id, label = x.label, desc = x.desc, spots = x.spots, anim = x.anim, secs = x.secs, go = x.go, work = x.work, min = x.reward[1], max = x.reward[2] } end
        jobs[#jobs + 1] = { name = j.name, label = j.label, icon = j.icon, desc = j.desc, grades = g, quests = q }
    end
    for _, l in ipairs(Config.JobCenter.Locations) do locs[#locs + 1] = { label = l[1], x = l[2], y = l[3], z = l[4], h = l[5] } end
    return { jobs = jobs, locations = locs }
end
do
    local d = Config.JobCenterDefaults()
    Config.Templates.jobcenter.office.settings.jobs, Config.Templates.jobcenter.office.settings.locations = d.jobs, d.locations
end

-- ─────────────────────────────── Job Gazoline : ravitaillement des stations essence ───────────────────────────────
-- Les stations (module « Station essence ») ont une cuve : elle se vide à chaque plein. Les livreurs du job « gazoline » chargent une citerne
-- au dépôt puis la livrent à la station qui en a le plus besoin. Il y a TOUJOURS au moins une station avec du carburant (réserve de secours).
-- Dépôt : place-toi à l'endroit voulu (idéalement devant un grand espace) et tape /gazdepot (groupe admin) ; le camion apparaît 10 m devant.
Config.Gazoline = {
    Enabled        = true,
    Job            = 'gazoline',                       -- nom du job (créé automatiquement dans la base s'il n'existe pas)
    Label          = 'Gazoline',
    Grades         = {                                 -- { nom interne, libellé, salaire }
        { 'livreur',   'Livreur',           80 },
        { 'chauffeur', 'Chauffeur citerne', 110 },
        { 'chef',      'Chef de dépôt',     150 },
    },
    Depot          = nil,                              -- { x =, y =, z =, h = } (sinon défini en jeu avec /gazdepot)
    Truck          = 'phantom',                        -- tracteur
    Trailer        = 'tanker2',                        -- citerne (tanker = Ron, tanker2 = Globe Oil)
    TankerLiters   = 10000,                            -- litres livrés par chargement (limités au besoin de la station)
    PayPerLiter    = 0.9,                              -- salaire par litre livré
    UrgentBonus    = 0.5,                              -- +50 % si la station est presque vide
    ReturnBonus    = 150,                              -- prime pour avoir rendu le camion au dépôt
    PayAccount     = 'money',                          -- compte crédité : money | bank
    OrderBelowPercent = 75,                            -- une station sous ce niveau (%) peut être livrée
    LowAlertPercent   = 20,                            -- sous ce niveau, les livreurs en service sont prévenus
    UnloadLitersPerSecond = 250,                       -- vitesse de déchargement (durée = litres / ce nombre, entre 8 et 40 s)
    MinSeconds     = 25,                               -- durée mini entre le chargement et la livraison (anti-abus)
    -- Garantie : au moins une station garde de l'essence
    ReservePercent = 15,                               -- niveau mini (%) maintenu sur la station de réserve
    CheckSeconds   = 30,
    Marker         = { r = 255, g = 180, b = 0 },
    DrawDistance   = 25.0,
    Blip           = { sprite = 361, color = 5, scale = 0.9, label = 'Dépôt Gazoline' },
}

-- ─────────────────────────────── Pré-placement : tout est déjà posé sur la carte ───────────────────────────────
-- Au premier démarrage, les stations essence et les agences bancaires de GTA V sont créées et activées automatiquement (une seule fois :
-- si tu en supprimes une, elle ne revient pas). Tu peux ensuite tout modifier dans le builder comme d'habitude.
-- /wbseed (groupe admin) recrée celles qui manquent. Les supérettes, armureries, vêtements, coiffeurs et quincailleries sont dans le Shop Builder.
Config.Preset = {
    Enabled = true,
    Auto    = false,            -- false = rien n'est créé tout seul au démarrage ; /wbseed (admin) crée stations essence et banques à la demande
    FuelRestockMinutes = 45,    -- ravitaillement naturel des cuves (0 = seulement par le job Gazoline) ; la réserve de secours reste garantie
    FuelRestockLiters  = 150,
    -- { x, y, z } : position de la pompe (le joueur s'y place pour faire le plein)
    FuelStations = {
        { 49.42, 2778.79, 58.04 }, { 263.89, 2606.46, 44.98 }, { 1039.96, 2671.13, 39.55 }, { 1207.26, 2660.18, 37.90 }, { 2539.69, 2594.19, 37.94 },
        { 2679.86, 3263.95, 55.24 }, { 2005.06, 3773.89, 32.40 }, { 1687.16, 4929.39, 42.08 }, { 1701.31, 6416.03, 32.76 }, { 179.86, 6602.84, 31.87 },
        { -94.46, 6419.59, 31.49 }, { -2555.00, 2334.40, 33.08 }, { -1800.38, 803.66, 138.65 }, { -1437.62, -276.75, 46.21 }, { -2096.24, -320.29, 13.17 },
        { -724.62, -935.16, 19.21 }, { -526.02, -1211.00, 18.18 }, { -70.21, -1761.79, 29.53 }, { 265.65, -1261.31, 29.29 }, { 819.65, -1028.85, 26.40 },
        { 1208.95, -1402.57, 35.22 }, { 1181.38, -330.85, 69.32 }, { 620.84, 269.10, 103.09 }, { 2581.32, 362.04, 108.47 }, { 176.63, -1562.03, 29.26 },
        { -319.29, -1471.72, 30.55 }, { 1784.32, 3330.55, 41.25 },
    },
    -- Agences bancaires (un seul module « Banque » avec toutes les agences)
    Banks = {
        { 149.05, -1041.30, 29.37 }, { 313.32, -280.03, 54.17 }, { -351.94, -50.72, 49.04 }, { -1212.68, -331.83, 37.78 },
        { -2961.67, 482.31, 15.70 }, { 1175.64, 2707.71, 38.09 }, { 247.65, 223.87, 106.29 }, { -111.98, 6470.56, 31.63 },
    },
}
