Config = {}

Config.Command       = 'eventbuilder'                     -- /eventbuilder ouvre le builder (aussi accessible depuis /builders)
Config.OpenKey       = false                              -- touche pour l'ouvrir sans commande (ex : 'F9')
Config.AllowedGroups = { '_dev', 'admin', 'superadmin' }  -- groupes ESX autorisés à créer / lancer des événements
Config.AcePermission = 'eventbuilder.admin'               -- (optionnel) permission ACE alternative
Config.Webhook       = ''                                 -- (optionnel) webhook Discord : début / fin / butin des événements

Config.PoliceJobs    = { 'police', 'sheriff', 'gendarmerie' }   -- métiers prévenus des événements (alerte + comptage « minPolice »)
Config.Currency      = '$'
Config.InteractDistance = 2.2                              -- distance pour interagir (butin, portes…)
Config.StreamDistance   = 140.0                            -- distance à laquelle un client voit le butin / les props d'un événement
Config.LogLimit      = 200                                 -- lignes d'historique affichées dans le builder

-- Lancement automatique des événements marqués « Automatique » dans le builder
Config.Auto = {
    Enabled       = true,
    CheckSeconds  = 60,      -- fréquence de vérification
    Chance        = 0.35,    -- chance (0-1) de lancer UN événement à chaque vérification (si les conditions sont réunies)
    MaxConcurrent = 2,       -- événements automatiques simultanés maximum
    MinPlayers    = 1,       -- joueurs connectés minimum (en plus du « minPlayers » de chaque événement)
}

-- ═══════════════════════ Types d'événements ═══════════════════════
-- Chaque type décrit son éditeur : `fields` = paramètres modifiables dans le builder (clé, libellé, type de champ, défaut).
-- Champs : number {min,max,step} · text · bool · select {options = { {v,l} }} · model (nom de modèle GTA)
Config.Types = {
    truck = {
        label = 'Braquage de fourgon blindé', icon = 'truck',
        desc = 'Un fourgon type Brinks, des gardes armés, puis des sacs de billets à récupérer autour des portes arrière.',
        trigger = 'auto',
        fields = {
            { key = 'truckModel',   label = 'Modèle du fourgon',      kind = 'model',  default = 'stockade' },
            { key = 'guards',       label = 'Gardes',                 kind = 'number', min = 0, max = 10, default = 3 },
            { key = 'guardModel',   label = 'Modèle des gardes',      kind = 'model',  default = 's_m_m_armoured_01' },
            { key = 'guardWeapon',  label = 'Arme des gardes',        kind = 'text',   default = 'WEAPON_CARBINERIFLE' },
            { key = 'guardAccuracy',label = 'Précision des gardes %', kind = 'number', min = 5, max = 100, default = 35 },
            { key = 'patrol',       label = 'Le fourgon roule d\'abord', kind = 'bool', default = true },
            { key = 'bags',         label = 'Sacs de billets',        kind = 'number', min = 1, max = 20, default = 6 },
            { key = 'bagModel',     label = 'Modèle des sacs',        kind = 'model',  default = 'prop_money_bag_01' },
            { key = 'breachSeconds',label = 'Durée de perçage (s)',   kind = 'number', min = 3, max = 120, default = 20 },
            { key = 'requiredItem', label = 'Objet requis (vide = aucun)', kind = 'text', default = '' },
            { key = 'consumeItem',  label = 'Consommer l\'objet',     kind = 'bool',   default = true },
            { key = 'lootSeconds',  label = 'Durée pour ramasser un sac (s)', kind = 'number', min = 0, max = 30, default = 3 },
        },
        reward = { kind = 'account', account = 'black_money', min = 700, max = 1500 },      -- par sac
        duration = 25, cooldown = 90, minPolice = 2,
    },
    drop = {
        label = 'Largage de ravitaillement', icon = 'box',
        desc = 'Des caisses tombent du ciel : une zone est annoncée, le contenu se déverrouille au bout de quelques secondes.',
        trigger = 'auto',
        fields = {
            { key = 'crates',       label = 'Caisses',                kind = 'number', min = 1, max = 10, default = 3 },
            { key = 'crateModel',   label = 'Modèle des caisses',     kind = 'model',  default = 'prop_box_wood02a_pu' },
            { key = 'spread',       label = 'Dispersion (m)',         kind = 'number', min = 1, max = 60, default = 8 },
            { key = 'unlockSeconds',label = 'Déverrouillage après (s)', kind = 'number', min = 0, max = 600, default = 90 },
            { key = 'openSeconds',  label = 'Durée d\'ouverture (s)', kind = 'number', min = 1, max = 60, default = 6 },
            { key = 'guards',       label = 'Mercenaires',            kind = 'number', min = 0, max = 10, default = 2 },
            { key = 'guardModel',   label = 'Modèle des mercenaires', kind = 'model',  default = 's_m_y_blackops_01' },
            { key = 'guardWeapon',  label = 'Arme des mercenaires',   kind = 'text',   default = 'WEAPON_ASSAULTRIFLE' },
            { key = 'guardAccuracy',label = 'Précision %',            kind = 'number', min = 5, max = 100, default = 30 },
        },
        reward = { kind = 'items', items = { { name = 'bandage', min = 2, max = 5, chance = 100 }, { name = 'water', min = 1, max = 4, chance = 100 } } },   -- par caisse
        duration = 20, cooldown = 120, minPolice = 0,
    },
    store = {
        label = 'Braquage de commerce', icon = 'store',
        desc = 'Menacer le vendeur (viser) pour qu\'il vide la caisse ; la police est prévenue. Se déclenche en interagissant avec le commerce.',
        trigger = 'interact',
        fields = {
            { key = 'clerkModel',    label = 'Modèle du vendeur',     kind = 'model',  default = 'mp_m_shopkeep_01' },
            { key = 'aimSeconds',    label = 'Visée nécessaire (s)',  kind = 'number', min = 1, max = 15, default = 3 },
            { key = 'registerSeconds', label = 'Vidage de la caisse (s)', kind = 'number', min = 3, max = 120, default = 20 },
            { key = 'requiredItem',  label = 'Objet requis (vide = aucun)', kind = 'text', default = '' },
            { key = 'consumeItem',   label = 'Consommer l\'objet',    kind = 'bool',   default = false },
        },
        reward = { kind = 'account', account = 'black_money', min = 600, max = 1800 },
        duration = 6, cooldown = 45, minPolice = 1,
    },
    crash = {
        label = 'Épave / crash à fouiller', icon = 'plane',
        desc = 'Une épave en flammes avec des caisses à fouiller autour, parfois gardée.',
        trigger = 'auto',
        fields = {
            { key = 'wreckModel',   label = 'Modèle de l\'épave',    kind = 'model',  default = 'cuban800' },
            { key = 'wreckType',    label = 'Type de l\'épave',      kind = 'select', default = 'plane',
              options = { { 'plane', 'Avion' }, { 'heli', 'Hélicoptère' }, { 'automobile', 'Voiture / camion' }, { 'boat', 'Bateau' } } },
            { key = 'fire',         label = 'Flammes',               kind = 'bool',   default = true },
            { key = 'crates',       label = 'Caisses à fouiller',    kind = 'number', min = 1, max = 12, default = 4 },
            { key = 'crateModel',   label = 'Modèle des caisses',    kind = 'model',  default = 'prop_mil_crate_01' },
            { key = 'spread',       label = 'Dispersion (m)',        kind = 'number', min = 2, max = 60, default = 12 },
            { key = 'openSeconds',  label = 'Durée de fouille (s)',  kind = 'number', min = 1, max = 60, default = 7 },
            { key = 'guards',       label = 'Gardes',                kind = 'number', min = 0, max = 10, default = 3 },
            { key = 'guardModel',   label = 'Modèle des gardes',     kind = 'model',  default = 'g_m_y_lost_01' },
            { key = 'guardWeapon',  label = 'Arme des gardes',       kind = 'text',   default = 'WEAPON_SMG' },
            { key = 'guardAccuracy',label = 'Précision %',           kind = 'number', min = 5, max = 100, default = 25 },
        },
        reward = { kind = 'items', items = { { name = 'bandage', min = 1, max = 3, chance = 80 }, { name = 'water', min = 1, max = 2, chance = 60 } } },
        duration = 20, cooldown = 120, minPolice = 0,
    },
    delivery = {
        label = 'Livraison illégale (véhicule)', icon = 'car',
        desc = 'Un véhicule est à récupérer puis à livrer à une destination avant la fin du temps imparti, avec la police aux trousses.',
        trigger = 'auto',
        fields = {
            { key = 'vehicleModel', label = 'Modèle du véhicule',    kind = 'model',  default = 'baller2' },
            { key = 'locked',       label = 'Véhicule verrouillé',   kind = 'bool',   default = false },
            { key = 'destX', label = 'Destination X', kind = 'number', min = -10000, max = 10000, step = 0.01, default = 0 },
            { key = 'destY', label = 'Destination Y', kind = 'number', min = -10000, max = 10000, step = 0.01, default = 0 },
            { key = 'destZ', label = 'Destination Z', kind = 'number', min = -1000, max = 2000, step = 0.01, default = 0 },
            { key = 'destRadius', label = 'Rayon de livraison (m)',  kind = 'number', min = 3, max = 50, default = 6 },
            { key = 'alertOnTake',  label = 'Alerte police à la prise du véhicule', kind = 'bool', default = true },
        },
        reward = { kind = 'account', account = 'black_money', min = 2500, max = 5000 },
        duration = 20, cooldown = 60, minPolice = 1, needsDest = true,
    },
    koth = {
        label = 'Contrôle de zone', icon = 'flag',
        desc = 'Une zone à tenir : le premier joueur qui cumule assez de secondes seul dans la zone remporte la récompense.',
        trigger = 'auto',
        fields = {
            { key = 'radius',       label = 'Rayon de la zone (m)',  kind = 'number', min = 5, max = 150, default = 25 },
            { key = 'holdSeconds',  label = 'Secondes à cumuler',    kind = 'number', min = 10, max = 1800, default = 120 },
            { key = 'tickReward',   label = 'Gain par palier de 30 s (0 = aucun)', kind = 'number', min = 0, max = 100000, default = 0 },
        },
        reward = { kind = 'account', account = 'black_money', min = 3000, max = 6000 },
        duration = 20, cooldown = 60, minPolice = 0,
    },
}

-- Modèles prêts à l'emploi (bouton « Nouvel événement ») : surchargent les valeurs par défaut du type
Config.Templates = {
    { id = 'brinks', type = 'truck', label = 'Fourgon Brinks', desc = 'Fourgon blindé, 3 gardes, 6 sacs de billets.', params = {} },
    { id = 'brinks_hard', type = 'truck', label = 'Fourgon Brinks (convoi renforcé)', desc = '6 gardes, 10 sacs, perçage plus long.',
      params = { guards = 6, bags = 10, breachSeconds = 40, guardAccuracy = 55 }, reward = { min = 900, max = 1900 }, minPolice = 4 },
    { id = 'jewels', type = 'truck', label = 'Convoi de bijoux', desc = 'Moins de sacs, plus précieux.',
      params = { guards = 4, bags = 4, bagModel = 'prop_cs_package_01', breachSeconds = 30 }, reward = { min = 1600, max = 2800 }, minPolice = 3 },
    { id = 'airdrop', type = 'drop', label = 'Largage militaire', desc = 'Caisses d\'équipement et mercenaires.', params = {} },
    { id = 'medical', type = 'drop', label = 'Largage médical', desc = 'Caisses de soins, pas de gardes.', params = { guards = 0, unlockSeconds = 45 } },
    { id = 'store247', type = 'store', label = 'Braquage de supérette', desc = 'Caisse de la supérette.', params = {} },
    { id = 'jewelry', type = 'store', label = 'Braquage de bijouterie', desc = 'Plus de butin, vidage plus long.', params = { clerkModel = 'u_f_m_miranda', registerSeconds = 35 },
      reward = { min = 1800, max = 4200 }, minPolice = 3 },
    { id = 'plane', type = 'crash', label = 'Épave d\'avion', desc = 'Épave en flammes, 4 caisses, 3 gardes.', params = {} },
    { id = 'stolencar', type = 'delivery', label = 'Livraison de voiture volée', desc = 'Récupérer et livrer un SUV.', params = {} },
    { id = 'supercar', type = 'delivery', label = 'Livraison de supercar', desc = 'Véhicule de luxe verrouillé, gros gain.',
      params = { vehicleModel = 'zentorno', locked = true }, reward = { min = 6000, max = 11000 }, minPolice = 3 },
    { id = 'koth', type = 'koth', label = 'Contrôle de zone', desc = 'Tenir la zone 2 minutes.', params = {} },
}

-- Valeurs par défaut communes à tous les événements
Config.Defaults = {
    alert = { enabled = true, delay = 10, message = 'Activité suspecte signalée' },
    blip  = { enabled = true, sprite = 161, color = 1, scale = (PickaxTheme and PickaxTheme.blipScale) or 0.9, radius = 80.0, flash = true },   -- taille = Config.GlobalBlip.Scale du core
    announce = { start = '', finish = '' },
}
