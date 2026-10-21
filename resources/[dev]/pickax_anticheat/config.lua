-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════
--  PICKAX ANTICHEAT : configuration par défaut
--  Tout ce qui suit est modifiable EN JEU depuis le panneau (/anticheat → Règles). Les réglages faits en jeu sont enregistrés en base
--  et prennent le dessus sur ce fichier ; le bouton « Réinitialiser » du panneau revient à ces valeurs.
--
--  Principe anti-faux-bans : chaque détection ajoute des POINTS au joueur pour un module (le score retombe tout seul en `ScoreDecay`
--  secondes). Une sanction n'est appliquée que lorsque le score atteint le seuil `kick` ou `ban` du module (0 = jamais).
--  En mode « observe », rien n'est jamais sanctionné : tout est enregistré avec la mention « sanction simulée » (idéal pour calibrer).
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════
Config = {}

-- ─────────────────────────────── Accès au panneau ───────────────────────────────
Config.Panel = {
    Command    = 'anticheat',                 -- /anticheat ouvre le panneau
    Alias      = 'ac',                        -- /ac
    Key        = false,                       -- touche optionnelle (ex : 'F10')
    ViewGroups = { 'admin', 'superadmin', '_dev' },   -- groupes ESX qui voient le panneau (joueurs, détections, bans)
    BanGroups  = { 'superadmin', '_dev' },            -- groupes qui peuvent bannir / débannir / modifier les règles
    Ace        = 'pickax_anticheat.admin',    -- (optionnel) permission ACE alternative
}

-- ─────────────────────────────── Valeurs par défaut (modifiables en jeu) ───────────────────────────────
Config.Defaults = {
    mode       = 'protect',        -- 'protect' = sanctions actives | 'observe' = rien n'est sanctionné (tout est journalisé « sanction simulée »)
    webhook    = '',               -- webhook Discord : kicks, bans, honeypots, actions du panneau
    scoreDecay = 120,              -- secondes pour qu'un score retombe à 0
    appeal     = 'Contestation : discord.gg/bluebayrp',   -- ajouté au message de ban
    banDurations = { '1h', '6h', '1d', '3d', '7d', '30d', 'perm' },   -- durées proposées dans le panneau

    -- Délais de grâce (secondes) pendant lesquels les contrôles de mouvement / santé / armes sont suspendus
    grace = { join = 60, spawn = 10, exempt = 8 },

    -- Contournement de ban : un compte qui partage un identifiant (Discord, Steam…) avec un joueur banni est expulsé (l'IP n'est pas utilisée par défaut : IP partagées = faux positifs)
    evasion = { enabled = true, discord = true, steam = true, fivem = true, live = true, xbl = true, ip = false, autoBan = false },

    -- Qui n'est jamais contrôlé
    exempt = {
        groups       = { 'admin', 'superadmin', '_dev' },       -- groupes ESX du staff
        adminModules = { 'honeypots', 'movement', 'teleport', 'godmode', 'health', 'weapon', 'weaponBlacklist', 'blacklistModels', 'entities', 'explosions', 'clientFlags' },
        -- (les admins restent contrôlés par défaut sur : events, honeypots, heartbeat)
        jobs         = {},                                      -- métiers exemptés de TOUS les contrôles d'armes (ex : { 'police' })
        states       = { 'inMinigame', 'inPvpZone', 'inGunfight', 'inGunFight', 'gunfight', 'inArena', 'inEvent', 'acExempt' },   -- statebags joueur qui suspendent les contrôles
        licenses     = {},                                      -- licences exemptées (ajoutables depuis le panneau)
    },

    -- Armes : par défaut une arme tenue doit venir de l'inventaire (ox_inventory) ou du loadout ESX
    weapons = {
        checkInventory = true,
        whitelist = { 'WEAPON_UNARMED', 'GADGET_PARACHUTE' },   -- toujours autorisées pour tout le monde (ajoute : 'WEAPON_FLASHLIGHT', …)
        jobs      = {},                                         -- { police = { 'WEAPON_STUNGUN', 'WEAPON_NIGHTSTICK' } } autorisées pour un métier même hors inventaire
        blacklist = { 'WEAPON_RAILGUN', 'WEAPON_RAILGUNXM3', 'WEAPON_MINIGUN', 'WEAPON_RPG', 'WEAPON_HOMINGLAUNCHER', 'WEAPON_COMPACTLAUNCHER', 'WEAPON_EMPLAUNCHER',
                      'WEAPON_STICKYBOMB', 'WEAPON_PROXMINE', 'WEAPON_GRENADELAUNCHER', 'WEAPON_FIREWORK' },
        -- blacklist : arme utilisée pour tirer / blesser (jamais autorisée aux joueurs non exemptés)
    },

    -- Modèles interdits à la création par un joueur (véhicules, PNJ, objets) : l'entité est annulée
    models = {
        vehicles = { 'rhino', 'hydra', 'lazer', 'khanjali', 'oppressor', 'oppressor2', 'deluxo', 'thruster', 'savage', 'hunter', 'buzzard', 'annihilator',
                     'valkyrie', 'akula', 'cargobob', 'cargobob2', 'cargobob3', 'cargobob4', 'apc', 'scarab', 'scarab2', 'scarab3', 'barrage', 'chernobog', 'insurgent3',
                     'halftrack', 'tampa3', 'technical', 'technical2', 'technical3', 'dune3', 'mule4', 'pounder2', 'menacer', 'minitank', 'bombushka', 'molotok', 'volatol',
                     'starling', 'seabreeze', 'nokota', 'strikeforce', 'tula', 'rogue', 'pyro', 'mogul', 'avenger', 'avenger2', 'stromberg', 'toreador', 'kosatka' },
        peds     = { 'u_m_y_juggernaut_01', 's_m_y_swat_01_hostile', 'u_m_y_zombie_01', 'a_c_mtlion', 'a_c_chop', 'a_c_rottweiler' },
        objects  = { 'prop_gascyl_01a', 'prop_barrel_01a', 'prop_ld_barrier_01', 'prop_logpile_07' },
    },

    -- Événements serveur
    events = {
        -- Honeypots : événements qu'aucun script de TON serveur ne déclenche ni n'enregistre (vérifié dans le dépôt). Un client qui les envoie utilise un menu de triche.
        honeypots = { 'esx_policejob:billPlayer', 'esx_dmvschool:addLicense', 'esx_truckerjob:pay', 'esx_garbagejob:pay', 'esx_pizza:pay', 'esx_taxijob:success',
                      'esx_gopostaljob:pay', 'esx_fueldelivery:pay', 'esx_carthief:pay', 'esx_blanchisseur:washMoney', 'esx_holdup:robberyOver', 'esx_vangelico_robbery:gioielli',
                      'esx_mechanicjob:onNPCJobCompleted', 'esx_drugs:startHarvestWeed', 'esx_lscustom:buyMod', 'esx_communityservice:endCommunityServiceCommand',
                      'esx_jail:sendToJail', 'esx_society:withdrawMoney', 'esx_society:depositMoney', 'esx_skin:responseSaveSkin', 'esx_atm:withdraw', 'esx_atm:deposit',
                      'esx_policejob:putInVehicle', 'esx_ambulancejob:setDeathStatus', 'esx_property:putItem' },
        -- Limites de fréquence : { event = 'nom', max = nombre, window = secondes, weight = points ajoutés à chaque dépassement }
        limits = {
            { event = 'minigames:shot',       max = 10, window = 5,  weight = 1 },
            { event = 'minigames:score',      max = 10, window = 5,  weight = 1 },
            { event = 'minigames:tagHit',     max = 25, window = 5,  weight = 1 },
            { event = 'minigames:fightHit',   max = 15, window = 5,  weight = 1 },
            { event = 'minigames:cp',         max = 15, window = 5,  weight = 1 },
            { event = 'minigames:splat',      max = 60, window = 5,  weight = 1 },
            { event = 'worldbuilder:server:fuelFinish',      max = 3, window = 20, weight = 1 },
            { event = 'worldbuilder:server:gazUnloadFinish', max = 3, window = 30, weight = 1 },
            { event = 'worldbuilder:server:gazReturn',       max = 3, window = 30, weight = 1 },
        },
    },

    -- Modules : enabled | weight = points par détection | kick / ban = seuil de score (0 = jamais) | paramètres propres au module
    modules = {
        movement        = { enabled = true, weight = 1, kick = 8, ban = 0, maxSpeed = 22.0, samples = 6 },     -- vitesse à pied soutenue (fly / noclip / speed)
        teleport        = { enabled = true, weight = 1, kick = 0, ban = 0, distance = 150.0, vehicleDistance = 400.0 },   -- saut de position en 1 s (journal seulement par défaut)
        godmode         = { enabled = true, weight = 1, kick = 6, ban = 0 },
        health          = { enabled = true, weight = 3, kick = 3, ban = 0, maxHealth = 200, maxArmor = 100 },
        weapon          = { enabled = true, weight = 1, kick = 5, ban = 0 },                                    -- arme tenue qui ne vient pas de l'inventaire
        weaponBlacklist = { enabled = true, weight = 3, kick = 3, ban = 6 },
        entities        = { enabled = true, weight = 1, kick = 6, ban = 0, vehicles = 8, peds = 8, objects = 0, window = 60 },   -- créations par un joueur / fenêtre (0 = pas de limite)
        blacklistModels = { enabled = true, weight = 3, kick = 3, ban = 6 },
        explosions      = { enabled = true, weight = 1, kick = 5, ban = 0, max = 6, window = 10, blockInvisible = true },
        events          = { enabled = true, weight = 1, kick = 6, ban = 0 },                                    -- dépassement des limites d'événements
        honeypots       = { enabled = true, weight = 10, kick = 1, ban = 10 },                                  -- un seul déclenchement suffit
        heartbeat       = { enabled = true, weight = 1, kick = 2, ban = 0, timeout = 120 },                     -- le client ne répond plus (script client coupé)
        clientFlags     = { enabled = true, weight = 1, kick = 4, ban = 0 },                                    -- signalements du client (modificateurs de dégâts, invisibilité, spectateur)
    },
}

-- Armes connues (liste de suggestions dans le panneau : tu peux saisir n'importe quel nom WEAPON_…)
Config.KnownWeapons = {
    'WEAPON_UNARMED', 'GADGET_PARACHUTE', 'WEAPON_KNIFE', 'WEAPON_NIGHTSTICK', 'WEAPON_HAMMER', 'WEAPON_BAT', 'WEAPON_CROWBAR', 'WEAPON_GOLFCLUB', 'WEAPON_FLASHLIGHT',
    'WEAPON_STUNGUN', 'WEAPON_FLAREGUN', 'WEAPON_PISTOL', 'WEAPON_PISTOL_MK2', 'WEAPON_COMBATPISTOL', 'WEAPON_APPISTOL', 'WEAPON_PISTOL50', 'WEAPON_SNSPISTOL', 'WEAPON_HEAVYPISTOL',
    'WEAPON_VINTAGEPISTOL', 'WEAPON_MICROSMG', 'WEAPON_SMG', 'WEAPON_SMG_MK2', 'WEAPON_ASSAULTSMG', 'WEAPON_MACHINEPISTOL', 'WEAPON_ASSAULTRIFLE', 'WEAPON_ASSAULTRIFLE_MK2',
    'WEAPON_CARBINERIFLE', 'WEAPON_CARBINERIFLE_MK2', 'WEAPON_ADVANCEDRIFLE', 'WEAPON_SPECIALCARBINE', 'WEAPON_BULLPUPRIFLE', 'WEAPON_COMPACTRIFLE', 'WEAPON_PUMPSHOTGUN',
    'WEAPON_SAWNOFFSHOTGUN', 'WEAPON_ASSAULTSHOTGUN', 'WEAPON_SNIPERRIFLE', 'WEAPON_MARKSMANRIFLE', 'WEAPON_FIREEXTINGUISHER', 'WEAPON_PETROLCAN', 'WEAPON_SNOWBALL', 'WEAPON_BALL',
    'WEAPON_GRENADE', 'WEAPON_SMOKEGRENADE', 'WEAPON_MOLOTOV', 'WEAPON_BZGAS', 'WEAPON_FLARE',
}

Config.Debug = false
