Config = {}
Config.Enabled = true
Config.UseCommands = false   -- true = active aussi /crocheter et /desosser (par défaut : menu contextuel sur le véhicule, ou l'objet « crochet » utilisé près d'un véhicule)

-- Alerte police : utilise le dispatch de la tablette de police du Job Builder (target « police » = tous les jobs police)
Config.Alert = { Enabled = true, Target = 'police' }

-- ═════════════════════════════ CROCHETAGE DE VÉHICULES ═════════════════════════════
-- /crocheter près d'un véhicule verrouillé : mini-jeu à goupilles. Difficulté selon la classe du véhicule (1 facile … 5 très dur, 0 = impossible).
Config.Lockpick = {
    Command = 'crocheter',
    Item = 'lockpick',
    Distance = 3.0,
    BreakChance = 40,           -- % de casser le crochet en cas d'échec
    AlertChance = 25,           -- % d'alerte police après un échec
    Cooldown = 20,              -- secondes entre deux tentatives
    Min = 60,                   -- score minimal du mini-jeu
    ClassDifficulty = {         -- classes de véhicules GTA (0 compacte … 22 ouverts) : voir https://docs.fivem.net/natives/?_0x29439776AAA00A62
        [0] = 2, [1] = 3, [2] = 3, [3] = 3, [4] = 3, [5] = 4, [6] = 4, [7] = 5, [8] = 2, [9] = 3, [10] = 3, [11] = 3, [12] = 2, [13] = 1, [14] = 3, [15] = 0, [16] = 0, [17] = 3, [18] = 0, [19] = 0, [20] = 3, [21] = 0, [22] = 4,
    },
}

-- ═════════════════════════════ PIRATAGE DE TERMINAUX ═════════════════════════════
-- game : 'code' (mémoire) ou 'wires' (câbles). reward : argent sale et/ou items. Un échec déclenche une alerte police et bloque le terminal.
Config.Hack = {
    Item = 'hacking_laptop',     -- ordinateur de piratage exigé (non consommé) ; vide = aucun
    Min = 65,
    Terminals = {
        -- (aucun point créé automatiquement : renseigne tes coordonnées ici, ex. vector3(x, y, z))
        -- { label = 'Terminal bancaire', coords = vector3(0.0, 0.0, 0.0), game = 'code', length = 6, cooldown = 45, reward = { money = { 1500, 4000 } }, alert = 'Piratage d\'un terminal' },
    },
    Distance = 1.6,
}

-- ═════════════════════════════ FAUX PAPIERS ═════════════════════════════
-- Un faux document porte une QUALITÉ (score du mini-jeu). Lors d'un contrôle (pickax_justice → /papiers) la police le détecte d'autant plus facilement que la qualité est faible.
Config.Forgery = {
    Item = 'fake_id',
    Needs = { { 'blank_card', 1 }, { 'forgery_ink', 1 } },
    Seconds = 30,
    Workshops = {},   -- (aucun point créé automatiquement : renseigne tes coordonnées ici, ex. vector3(x, y, z))
    Distance = 1.6,
}

-- ═════════════════════════════ DÉSOSSAGE ═════════════════════════════
-- Amène un véhicule dans la zone puis /desosser : chaque pièce se démonte (mini-jeu) et devient un item à revendre au receleur. Véhicule entièrement démonté = détruit.
Config.Chop = {
    Command = 'desosser',
    Tool = 'chop_tools',          -- outils exigés (non consommés) ; vide = aucun
    Zones = {},   -- (aucun point créé automatiquement : renseigne tes coordonnées ici, ex. vector3(x, y, z))
    AllowOwned = false,           -- false = un véhicule appartenant à un joueur (table owned_vehicles) ne peut pas être désossé
    AlertChance = 15,             -- % d'alerte police à chaque pièce
    Min = 50,
    Parts = {
        { id = 'door',   label = 'Portière',        item = 'stolen_door',   game = { rounds = 2, difficulty = 1 }, seconds = 18 },
        { id = 'wheel',  label = 'Roues',           item = 'stolen_wheel',  game = { rounds = 2, difficulty = 1 }, seconds = 18 },
        { id = 'hood',   label = 'Capot',           item = 'stolen_hood',   game = { rounds = 3, difficulty = 2 }, seconds = 20 },
        { id = 'trunk',  label = 'Coffre',          item = 'stolen_trunk',  game = { rounds = 3, difficulty = 2 }, seconds = 20 },
        { id = 'engine', label = 'Moteur',          item = 'stolen_engine', game = { rounds = 4, difficulty = 3 }, seconds = 26 },
    },
    -- Receleur : rachète les pièces en argent sale ; les prix varient chaque jour (±Fluctuation %)
    Fence = { label = 'Receleur', coords = nil,   -- (aucun point créé automatiquement : renseigne tes coordonnées ici, ex. vector3(x, y, z))
       ped = 'a_m_m_hillbilly_01', pedHeading = 90.0, Fluctuation = 20, Account = 'black_money', Distance = 2.0,
        Prices = { stolen_door = 350, stolen_wheel = 280, stolen_hood = 420, stolen_trunk = 380, stolen_engine = 1500 } },
}
