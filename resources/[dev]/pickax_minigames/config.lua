Config = {}

Config.Command       = 'minigames'                        -- /minigames ouvre le builder (aussi accessible depuis /builders)
Config.OpenKey       = false                              -- touche pour l'ouvrir sans commande (ex : 'F10')
Config.AllowedGroups = { '_dev', 'admin', 'superadmin' }  -- groupes ESX autorisés à créer / modifier des mini-jeux
Config.AcePermission = 'minigames.admin'                  -- (optionnel) permission ACE alternative
Config.Webhook       = ''                                 -- (optionnel) webhook Discord : résultats des parties
Config.Currency      = '$'
Config.RewardAccount = 'money'                            -- compte crédité des gains : 'money' | 'bank' | 'black_money'
Config.PayAccount    = 'money'                            -- compte débité du prix d'entrée
Config.InteractDistance = 2.0                             -- distance pour ouvrir le lobby d'un mini-jeu (touche E)
Config.DrawDistance     = 25.0                            -- distance d'affichage du marker du lobby
Config.LeaveKey         = 'END'                           -- touche pour quitter une partie (réglable dans les touches FiveM)
Config.ReturnAfterEnd   = 6                               -- secondes avant le retour au point de départ après la fin d'une partie
Config.MaxTop           = 10                              -- lignes du classement
Config.LogLimit         = 200

-- Réglages communs à tous les mini-jeux (onglets « Règles » et « Récompenses » du builder)
Config.Common = {
    { key = 'minPlayers',    label = 'Joueurs minimum',            kind = 'number', min = 1, max = 16, def = 1,  tab = 'rules' },
    { key = 'maxPlayers',    label = 'Joueurs maximum',            kind = 'number', min = 1, max = 24, def = 1,  tab = 'rules' },
    { key = 'waitSeconds',   label = 'Attente avant le départ (s)', kind = 'number', min = 0, max = 300, def = 20, tab = 'rules', hint = 'Temps laissé aux autres joueurs pour rejoindre une fois le minimum atteint.' },
    { key = 'countdown',     label = 'Compte à rebours (s)',       kind = 'number', min = 1, max = 15, def = 3,  tab = 'rules' },
    { key = 'duration',      label = 'Durée de la partie (s)',     kind = 'number', min = 10, max = 3600, def = 90, tab = 'rules' },
    { key = 'arenaRadius',   label = 'Rayon de l\'arène (m)',      kind = 'number', min = 5, max = 400, def = 40, tab = 'rules', hint = 'Sortir de l\'arène ramène le joueur au centre.' },
    { key = 'cooldown',      label = 'Délai avant de rejouer (s)', kind = 'number', min = 0, max = 3600, def = 0,  tab = 'rules' },
    { key = 'entryFee',      label = 'Prix d\'entrée',             kind = 'number', min = 0, max = 100000, def = 0, tab = 'rewards' },
    { key = 'pot',           label = 'Le gagnant empoche les mises', kind = 'bool', def = false, tab = 'rewards', hint = 'Sinon, les gains sont versés par le serveur.' },
    { key = 'rewardWin',     label = 'Gain du gagnant',            kind = 'number', min = 0, max = 1000000, def = 0, tab = 'rewards' },
    { key = 'rewardLose',    label = 'Gain des perdants',          kind = 'number', min = 0, max = 1000000, def = 0, tab = 'rewards' },
    { key = 'rewardPerPoint', label = 'Gain par point marqué',     kind = 'number', min = 0, max = 10000, def = 0, tab = 'rewards' },
}

-- Types de mini-jeux : engine = moteur de jeu côté client ; fields = réglages propres ; points = emplacements à placer
-- Champs : number {min,max,step} · bool · text · model · weapon · select {options}
-- Points : single = un seul · team = équipe par point · radius / pts = rayon / points rapportés par la zone
Config.Types = {
    basket = {
        label = 'Basket', icon = 'basket', engine = 'shoot',
        desc = 'Tirs au panier : maintiens E pour charger, relâche dans la zone verte. 2 points, 3 points au-delà de la ligne.',
        fields = {
            { key = 'ballModel',   label = 'Modèle du ballon',        kind = 'model', def = 'prop_bskball_01' },
            { key = 'targetKind',  label = 'Type de cible',            kind = 'select', def = 'hoop', options = { { 'hoop', 'Panier (par le haut)' }, { 'goal', 'But (traverse la zone)' } } },
            { key = 'holdBall',    label = 'Ballon en main',           kind = 'bool', def = true },
            { key = 'hoopSpawn',   label = 'Afficher un panier (prop) au point « Panier »', kind = 'bool', def = true },
            { key = 'hoopModel',   label = 'Modèle du panier',         kind = 'model', def = 'prop_basketball_net' },
            { key = 'hoopOffsetZ', label = 'Hauteur du prop (décalage Z)', kind = 'number', min = -6, max = 6, step = .05, def = 0 },
            { key = 'hoopYaw',     label = 'Rotation du prop (°)',     kind = 'number', min = -180, max = 180, step = 1, def = 0 },
            { key = 'hoopRadius',  label = 'Rayon de détection (m)',   kind = 'number', min = .2, max = 3, step = .05, def = .55 },
            { key = 'threeDist',   label = 'Distance « 3 points » (m)', kind = 'number', min = 1, max = 30, step = .5, def = 6.5 },
            { key = 'points2',     label = 'Points d\'un tir proche',  kind = 'number', min = 1, max = 20, def = 2 },
            { key = 'points3',     label = 'Points d\'un tir lointain', kind = 'number', min = 1, max = 20, def = 3 },
            { key = 'meterSpeed',  label = 'Vitesse de la jauge',      kind = 'number', min = .4, max = 3, step = .1, def = 1.1 },
            { key = 'sweet',       label = 'Largeur de la zone verte', kind = 'number', min = .05, max = .5, step = .01, def = .16 },
            { key = 'scatter',     label = 'Dispersion max (m)',       kind = 'number', min = 0, max = 6, step = .1, def = 1.8 },
        },
        points = {
            { key = 'lobby',  label = 'Entrée du terrain', single = true },
            { key = 'spawns', label = 'Positions de départ', max = 8 },
            { key = 'hoop',   label = 'Panier', single = true },
        },
        templates = {
            { id = 'street', label = 'Panier de rue', desc = 'Tir au panier en solo, 60 secondes.', settings = { duration = 60, minPlayers = 1, maxPlayers = 1, arenaRadius = 30 } },
            { id = 'versus', label = 'Basket 1 contre 1', desc = 'Deux joueurs tirent en même temps, le meilleur score gagne.', settings = { duration = 90, minPlayers = 2, maxPlayers = 2, waitSeconds = 30, pot = true, entryFee = 100 } },
        },
    },
    football = {
        label = 'Football', icon = 'football', engine = 'shoot',
        desc = 'Tirs au but : le ballon est posé, vise avec la caméra, charge avec E et relâche. Chaque zone du but rapporte des points.',
        fields = {
            { key = 'ballModel',   label = 'Modèle du ballon',        kind = 'model', def = 'p_ld_soc_ball_01' },
            { key = 'targetKind',  label = 'Type de cible',            kind = 'select', def = 'goal', options = { { 'goal', 'But (traverse la zone)' }, { 'hoop', 'Panier (par le haut)' } } },
            { key = 'holdBall',    label = 'Ballon en main',           kind = 'bool', def = false },
            { key = 'balls',       label = 'Nombre de tirs',           kind = 'number', min = 1, max = 50, def = 10 },
            { key = 'meterSpeed',  label = 'Vitesse de la jauge',      kind = 'number', min = .4, max = 3, step = .1, def = 1.3 },
            { key = 'sweet',       label = 'Largeur de la zone verte', kind = 'number', min = .05, max = .5, step = .01, def = .14 },
            { key = 'scatter',     label = 'Dispersion max (m)',       kind = 'number', min = 0, max = 6, step = .1, def = 2.2 },
        },
        points = {
            { key = 'lobby',  label = 'Entrée du terrain', single = true },
            { key = 'spawns', label = 'Position du tireur', max = 8 },
            { key = 'ball',   label = 'Point de penalty (ballon)', single = true },
            { key = 'zones',  label = 'Zones du but', max = 12, radius = true, pts = true },
        },
        templates = {
            { id = 'penalty', label = 'Tirs au but', desc = '10 tirs au but, zones de points aux angles.', settings = { duration = 120, minPlayers = 1, maxPlayers = 1, balls = 10, arenaRadius = 40 } },
        },
    },
    tennis = {
        label = 'Tennis', icon = 'tennis', engine = 'rally',
        desc = 'Une machine envoie des balles : renvoie-les avec E vers les zones de la moitié adverse. Plus tu es précis, plus tu marques.',
        fields = {
            { key = 'ballModel',   label = 'Modèle de la balle',       kind = 'model', def = 'prop_tennis_ball' },
            { key = 'balls',       label = 'Nombre de balles',         kind = 'number', min = 1, max = 100, def = 12 },
            { key = 'feedInterval', label = 'Délai entre deux balles (s)', kind = 'number', min = 2, max = 15, step = .5, def = 4.5 },
            { key = 'feedTime',    label = 'Durée du vol de service (s)', kind = 'number', min = .6, max = 3, step = .1, def = 1.5 },
            { key = 'hitRadius',   label = 'Rayon de frappe (m)',      kind = 'number', min = 1, max = 5, step = .1, def = 2.4 },
            { key = 'returnTime',  label = 'Durée du vol de retour (s)', kind = 'number', min = .5, max = 3, step = .1, def = 1.2 },
            { key = 'scatter',     label = 'Dispersion max (m)',       kind = 'number', min = 0, max = 8, step = .1, def = 3 },
        },
        points = {
            { key = 'lobby',   label = 'Entrée du court', single = true },
            { key = 'spawns',  label = 'Position du joueur', max = 4 },
            { key = 'machine', label = 'Machine à balles', single = true },
            { key = 'zones',   label = 'Zones cibles (côté adverse)', max = 12, radius = true, pts = true },
        },
        templates = {
            { id = 'training', label = 'Entraînement', desc = '12 balles, zones à 10 / 20 / 30 points.', settings = { duration = 120, minPlayers = 1, maxPlayers = 1, balls = 12, arenaRadius = 35 } },
        },
    },
    boxing = {
        label = 'Boxe', icon = 'boxing', engine = 'fight',
        desc = 'Duel au poing dans un ring : jauge de vie, rounds, KO. Le premier à gagner la majorité des rounds l\'emporte.',
        fields = {
            { key = 'rounds',      label = 'Nombre de rounds',         kind = 'number', min = 1, max = 9, def = 3 },
            { key = 'roundTime',   label = 'Durée d\'un round (s)',    kind = 'number', min = 20, max = 600, def = 60 },
            { key = 'hp',          label = 'Points de vie',            kind = 'number', min = 20, max = 500, def = 100 },
            { key = 'damageMin',   label = 'Dégâts minimum d\'un coup', kind = 'number', min = 1, max = 100, def = 5 },
            { key = 'damageMax',   label = 'Dégâts maximum d\'un coup', kind = 'number', min = 1, max = 100, def = 10 },
            { key = 'hitDelay',    label = 'Délai mini entre deux coups (ms)', kind = 'number', min = 100, max = 2000, step = 50, def = 350 },
        },
        points = {
            { key = 'lobby',  label = 'Entrée / vestiaire', single = true },
            { key = 'spawns', label = 'Coins du ring (1 par boxeur)', max = 2, team = true },
            { key = 'center', label = 'Centre du ring', single = true },
        },
        templates = {
            { id = 'ring', label = 'Ring de boxe', desc = 'Duel 1 contre 1, 3 rounds, mise partagée.', settings = { minPlayers = 2, maxPlayers = 2, waitSeconds = 30, arenaRadius = 7, pot = true, entryFee = 100, duration = 600 } },
        },
    },
    paintball = {
        label = 'Paintball', icon = 'paintball', engine = 'tag',
        desc = 'Deux équipes, des touches validées par le serveur (pas de dégâts réels), réapparition rapide, limite de score.',
        fields = {
            { key = 'weapon',       label = 'Arme',                     kind = 'weapon', def = 'WEAPON_PISTOL' },
            { key = 'teams',        label = 'Mode',                     kind = 'select', def = '2', options = { { '2', 'Deux équipes' }, { '0', 'Chacun pour soi' } } },
            { key = 'scoreLimit',   label = 'Limite de score',          kind = 'number', min = 1, max = 500, def = 20 },
            { key = 'respawnSeconds', label = 'Réapparition (s)',       kind = 'number', min = 1, max = 30, def = 3 },
            { key = 'hitRange',     label = 'Portée d\'une touche (m)', kind = 'number', min = 5, max = 200, def = 70 },
            { key = 'fireDelay',    label = 'Délai mini entre deux touches (ms)', kind = 'number', min = 50, max = 2000, step = 50, def = 220 },
            { key = 'friendlyFire', label = 'Tirs amis',                kind = 'bool', def = false },
        },
        points = {
            { key = 'lobby',  label = 'Entrée / vestiaire', single = true },
            { key = 'spawns', label = 'Points d\'apparition', max = 24, team = true },
            { key = 'center', label = 'Centre de l\'arène', single = true },
        },
        templates = {
            { id = 'arena', label = 'Arène de paintball', desc = '2 équipes, 20 touches pour gagner.', settings = { minPlayers = 2, maxPlayers = 12, waitSeconds = 30, duration = 300, arenaRadius = 60, entryFee = 50 } },
        },
    },
    lasertag = {
        label = 'Laser game', icon = 'laser', engine = 'tag',
        desc = 'Chacun pour soi ou en équipes : touche tes adversaires, le plus de touches gagne.',
        fields = {
            { key = 'weapon',       label = 'Arme',                     kind = 'weapon', def = 'WEAPON_MICROSMG' },
            { key = 'teams',        label = 'Mode',                     kind = 'select', def = '0', options = { { '0', 'Chacun pour soi' }, { '2', 'Deux équipes' } } },
            { key = 'scoreLimit',   label = 'Limite de score',          kind = 'number', min = 1, max = 500, def = 25 },
            { key = 'respawnSeconds', label = 'Réapparition (s)',       kind = 'number', min = 1, max = 30, def = 2 },
            { key = 'hitRange',     label = 'Portée d\'une touche (m)', kind = 'number', min = 5, max = 200, def = 50 },
            { key = 'fireDelay',    label = 'Délai mini entre deux touches (ms)', kind = 'number', min = 50, max = 2000, step = 50, def = 160 },
            { key = 'friendlyFire', label = 'Tirs amis',                kind = 'bool', def = false },
        },
        points = {
            { key = 'lobby',  label = 'Entrée / vestiaire', single = true },
            { key = 'spawns', label = 'Points d\'apparition', max = 24, team = true },
            { key = 'center', label = 'Centre de l\'arène', single = true },
        },
        templates = {
            { id = 'ffa', label = 'Laser game', desc = 'Chacun pour soi, 25 touches.', settings = { minPlayers = 2, maxPlayers = 10, waitSeconds = 30, duration = 240, arenaRadius = 45, entryFee = 50 } },
        },
    },
    race = {
        label = 'Course', icon = 'race', engine = 'race',
        desc = 'Passe tous les checkpoints le plus vite possible : à pied, en vélo ou en voiture. Classement au temps.',
        fields = {
            { key = 'vehicle',      label = 'Véhicule (vide = à pied)', kind = 'model', def = '' },
            { key = 'laps',         label = 'Nombre de tours',         kind = 'number', min = 1, max = 20, def = 1 },
            { key = 'cpRadius',     label = 'Rayon des checkpoints (m)', kind = 'number', min = 2, max = 30, step = .5, def = 6 },
        },
        points = {
            { key = 'lobby',       label = 'Entrée / départ', single = true },
            { key = 'spawns',      label = 'Places de la grille', max = 24 },
            { key = 'checkpoints', label = 'Checkpoints (dans l\'ordre, le dernier = arrivée)', max = 60, radius = true },
        },
        templates = {
            { id = 'run', label = 'Course à pied', desc = 'Sprint chronométré à pied.', settings = { minPlayers = 1, maxPlayers = 8, waitSeconds = 20, duration = 240, arenaRadius = 400, vehicle = '' } },
            { id = 'bmx', label = 'Course de BMX', desc = 'Parcours en BMX.', settings = { minPlayers = 1, maxPlayers = 8, waitSeconds = 20, duration = 300, arenaRadius = 400, vehicle = 'bmx' } },
            { id = 'kart', label = 'Course de kart', desc = 'Parcours en kart.', settings = { minPlayers = 1, maxPlayers = 8, waitSeconds = 20, duration = 300, arenaRadius = 500, vehicle = 'veto' } },
        },
    },
}
Config.TypeOrder = { 'basket', 'football', 'tennis', 'boxing', 'paintball', 'lasertag', 'race' }

Config.TeamColors = { { 59, 130, 246, 'Bleus' }, { 239, 68, 68, 'Rouges' } }

Config.Weapons = {
    { 'WEAPON_PISTOL', 'Pistolet' }, { 'WEAPON_COMBATPISTOL', 'Pistolet de combat' }, { 'WEAPON_MICROSMG', 'Micro-SMG' }, { 'WEAPON_SMG', 'SMG' },
    { 'WEAPON_ASSAULTRIFLE', 'Fusil d\'assaut' }, { 'WEAPON_CARBINERIFLE', 'Carabine' }, { 'WEAPON_PUMPSHOTGUN', 'Fusil à pompe' }, { 'WEAPON_STUNGUN', 'Taser' },
}

-- ─── Mini-jeux supplémentaires ───────────────────────────────────────────────
Config.Types.bowling = {
    label = 'Bowling', icon = 'bowling', engine = 'bowling',
    desc = 'Tes quilles se placent toutes seules : charge avec E, relâche dans la zone verte pour viser droit. 10 frames, 2 lancers, bonus strike et spare.',
    fields = {
        { key = 'pinModel',    label = 'Modèle des quilles',        kind = 'model', def = 'prop_bowling_pin' },
        { key = 'ballModel',   label = 'Modèle de la boule',        kind = 'model', def = 'prop_bowling_ball' },
        { key = 'frames',      label = 'Nombre de frames',          kind = 'number', min = 1, max = 10, def = 10 },
        { key = 'pinSpacing',  label = 'Écart entre les quilles (m)', kind = 'number', min = .15, max = 1, step = .01, def = .32 },
        { key = 'rollSpeed',   label = 'Vitesse de la boule (m/s)', kind = 'number', min = 5, max = 30, step = .5, def = 13 },
        { key = 'meterSpeed',  label = 'Vitesse de la jauge',       kind = 'number', min = .4, max = 3, step = .1, def = 1.2 },
        { key = 'sweet',       label = 'Largeur de la zone verte',  kind = 'number', min = .05, max = .5, step = .01, def = .2 },
        { key = 'scatter',     label = 'Déviation max (degrés)',    kind = 'number', min = 0, max = 25, step = .5, def = 7 },
        { key = 'strikeBonus', label = 'Bonus strike',              kind = 'number', min = 0, max = 50, def = 10 },
        { key = 'spareBonus',  label = 'Bonus spare',               kind = 'number', min = 0, max = 50, def = 5 },
    },
    points = {
        { key = 'lobby',   label = 'Entrée de la piste', single = true },
        { key = 'spawns',  label = 'Position du joueur', max = 4 },
        { key = 'ball',    label = 'Point de lancer de la boule', single = true },
        { key = 'pinhead', label = 'Quille de tête (les 9 autres se placent derrière)', single = true },
    },
    templates = {
        { id = 'lane', label = 'Piste de bowling', desc = '10 frames en solo, strikes et spares bonifiés.', settings = { minPlayers = 1, maxPlayers = 1, duration = 600, arenaRadius = 30 } },
    },
}

Config.Types.darts = {
    label = 'Fléchettes', icon = 'darts', engine = 'shoot',
    desc = 'Lance tes fléchettes sur la cible : plus tu vises près du centre, plus tu marques. Place les anneaux de la cible comme zones à points.',
    fields = {
        { key = 'ballModel',   label = 'Modèle de la fléchette',    kind = 'model', def = 'prop_dart_1' },
        { key = 'targetKind',  label = 'Type de cible',             kind = 'select', def = 'goal', options = { { 'goal', 'Zones à points' }, { 'hoop', 'Panier (par le haut)' } } },
        { key = 'holdBall',    label = 'Fléchette en main',         kind = 'bool', def = true },
        { key = 'balls',       label = 'Nombre de fléchettes',      kind = 'number', min = 1, max = 60, def = 9 },
        { key = 'meterSpeed',  label = 'Vitesse de la jauge',       kind = 'number', min = .4, max = 3, step = .1, def = 1.4 },
        { key = 'sweet',       label = 'Largeur de la zone verte',  kind = 'number', min = .05, max = .5, step = .01, def = .12 },
        { key = 'scatter',     label = 'Dispersion max (m)',        kind = 'number', min = 0, max = 3, step = .05, def = .6 },
    },
    points = {
        { key = 'lobby',  label = 'Entrée', single = true },
        { key = 'spawns', label = 'Ligne de lancer', max = 4 },
        { key = 'zones',  label = 'Zones de la cible (centre, anneaux…)', max = 12, radius = true, pts = true },
    },
    templates = {
        { id = 'board', label = 'Cible classique', desc = '9 fléchettes, centre à 50 points.', settings = { minPlayers = 1, maxPlayers = 1, balls = 9, duration = 180, arenaRadius = 20 } },
    },
}

Config.Types.brawl = {
    label = 'Combat libre', icon = 'brawl', engine = 'fight',
    desc = 'Combat à mains nues plus brutal que la boxe : plus de vie, plus de dégâts, rounds longs.',
    fields = {
        { key = 'rounds',      label = 'Nombre de rounds',          kind = 'number', min = 1, max = 9, def = 3 },
        { key = 'roundTime',   label = 'Durée d\'un round (s)',     kind = 'number', min = 20, max = 600, def = 90 },
        { key = 'hp',          label = 'Points de vie',             kind = 'number', min = 20, max = 500, def = 150 },
        { key = 'damageMin',   label = 'Dégâts minimum d\'un coup', kind = 'number', min = 1, max = 100, def = 6 },
        { key = 'damageMax',   label = 'Dégâts maximum d\'un coup', kind = 'number', min = 1, max = 100, def = 14 },
        { key = 'hitDelay',    label = 'Délai mini entre deux coups (ms)', kind = 'number', min = 100, max = 2000, step = 50, def = 400 },
    },
    points = {
        { key = 'lobby',  label = 'Entrée / vestiaire', single = true },
        { key = 'spawns', label = 'Points de départ (1 par combattant)', max = 2, team = true },
        { key = 'center', label = 'Centre de l\'arène', single = true },
    },
    templates = {
        { id = 'cage', label = 'Cage', desc = 'Duel 3 rounds, mise partagée.', settings = { minPlayers = 2, maxPlayers = 2, waitSeconds = 30, arenaRadius = 10, pot = true, entryFee = 200, duration = 900 } },
    },
}

local function rally2(label, icon, desc, ball, fields, tplLabel, tplDesc)
    return {
        label = label, icon = icon, engine = 'rally', desc = desc,
        fields = {
            { key = 'ballModel',    label = 'Modèle de la balle',            kind = 'model', def = ball },
            { key = 'balls',        label = 'Nombre de balles',              kind = 'number', min = 1, max = 100, def = fields.balls or 12 },
            { key = 'feedInterval', label = 'Délai entre deux balles (s)',   kind = 'number', min = 2, max = 15, step = .5, def = fields.interval or 4.5 },
            { key = 'feedTime',     label = 'Durée du vol de service (s)',   kind = 'number', min = .6, max = 3, step = .1, def = fields.feed or 1.5 },
            { key = 'hitRadius',    label = 'Rayon de frappe (m)',           kind = 'number', min = 1, max = 5, step = .1, def = 2.4 },
            { key = 'returnTime',   label = 'Durée du vol de retour (s)',    kind = 'number', min = .5, max = 3, step = .1, def = fields.ret or 1.2 },
            { key = 'scatter',      label = 'Dispersion max (m)',            kind = 'number', min = 0, max = 8, step = .1, def = 3 },
        },
        points = {
            { key = 'lobby',   label = 'Entrée du terrain', single = true },
            { key = 'spawns',  label = 'Position du joueur', max = 4 },
            { key = 'machine', label = 'Lanceur de balles', single = true },
            { key = 'zones',   label = 'Zones cibles (côté adverse)', max = 12, radius = true, pts = true },
        },
        templates = { { id = 'training', label = tplLabel, desc = tplDesc, settings = { duration = 120, minPlayers = 1, maxPlayers = 1, balls = fields.balls or 12, arenaRadius = 30 } } },
    }
end
Config.Types.padel  = rally2('Padel', 'padel', 'Comme le tennis mais en plus court : le lanceur envoie, tu renvoies avec E dans les zones.', 'prop_tennis_ball', { balls = 15, interval = 3.5, feed = 1.2, ret = 1.0 }, 'Entraînement de padel', '15 balles rapides, zones à points.')
Config.Types.volley = rally2('Volley-ball', 'volley', 'Renvoie les ballons du lanceur de l\'autre côté du filet, dans les zones cibles.', 'prop_beach_volball01', { balls = 10, interval = 5, feed = 1.8, ret = 1.4 }, 'Entraînement de volley', '10 ballons, zones à points.')

local function raceType(label, icon, desc, vehicle, tplLabel, tplDesc, extra)
    return {
        label = label, icon = icon, engine = 'race', desc = desc,
        fields = {
            { key = 'vehicle',  label = 'Véhicule (vide = à pied)',   kind = 'model', def = vehicle },
            { key = 'laps',     label = 'Nombre de tours',            kind = 'number', min = 1, max = 20, def = 3 },
            { key = 'cpRadius', label = 'Rayon des checkpoints (m)',  kind = 'number', min = 2, max = 30, step = .5, def = 7 },
        },
        points = {
            { key = 'lobby',       label = 'Entrée / départ', single = true },
            { key = 'spawns',      label = 'Places de la grille', max = 24 },
            { key = 'checkpoints', label = 'Checkpoints (dans l\'ordre, le dernier = arrivée)', max = 60, radius = true },
        },
        templates = { { id = 'circuit', label = tplLabel, desc = tplDesc, settings = extra } },
    }
end
Config.Types.karting = raceType('Karting', 'kart', 'Courses de karts sur circuit : grille de départ, tours, classement au meilleur temps.', 'veto2', 'Circuit de karting', '3 tours en kart, 8 pilotes maximum.', { minPlayers = 1, maxPlayers = 8, waitSeconds = 25, duration = 420, arenaRadius = 600, entryFee = 50, pot = true })
Config.Types.car     = raceType('Course auto', 'car', 'Courses de voitures de rue ou de circuit.', 'sultan', 'Course de voitures', '3 tours, mise partagée.', { minPlayers = 1, maxPlayers = 10, waitSeconds = 30, duration = 480, arenaRadius = 900, entryFee = 100, pot = true })
Config.Types.moto    = raceType('Course moto', 'moto', 'Course de motos sportives : trace, freine et gagne.', 'sanchez', 'Course de motos', '3 tours en moto.', { minPlayers = 1, maxPlayers = 10, waitSeconds = 30, duration = 420, arenaRadius = 900, entryFee = 100, pot = true })
Config.Types.quad    = raceType('Course quad', 'quad', 'Course tout-terrain en quad ou en buggy.', 'blazer', 'Cross en quad', '2 tours de cross.', { minPlayers = 1, maxPlayers = 8, waitSeconds = 25, duration = 420, arenaRadius = 900 })
Config.Types.boat    = raceType('Course bateau', 'boat', 'Course nautique : bouées en checkpoints, sur l\'eau.', 'seashark', 'Course de jet-ski', '2 tours en jet-ski.', { minPlayers = 1, maxPlayers = 8, waitSeconds = 25, duration = 420, arenaRadius = 1200 })

-- catégories + ordre d'affichage
local cats = {
    { 'Balles & raquettes', { 'basket', 'football', 'tennis', 'padel', 'volley' } },
    { 'Précision',          { 'bowling', 'darts' } },
    { 'Combat & tir',       { 'boxing', 'brawl', 'paintball', 'lasertag' } },
    { 'Courses',            { 'race', 'karting', 'car', 'moto', 'quad', 'boat' } },
}
Config.TypeOrder = {}
for _, c in ipairs(cats) do
    for _, k in ipairs(c[2]) do
        Config.Types[k].cat = c[1]
        Config.TypeOrder[#Config.TypeOrder + 1] = k
    end
end

-- ─── Nouveaux jeux simples (réutilisent les moteurs existants) ───────────────
Config.Types.golf = {
    label = 'Mini-golf', icon = 'golf', engine = 'shoot', cat = 'Précision',
    desc = 'Charge avec E, relâche dans la zone verte et envoie la balle dans le trou. Chaque trou à points est une zone.',
    fields = {
        { key = 'ballModel',  label = 'Modèle de la balle',        kind = 'model', def = 'prop_golf_ball' },
        { key = 'targetKind', label = 'Type de cible',             kind = 'select', def = 'goal', options = { { 'goal', 'Zones à points' }, { 'hoop', 'Panier (par le haut)' } } },
        { key = 'holdBall',   label = 'Balle en main',             kind = 'bool', def = false },
        { key = 'balls',      label = 'Nombre de coups',           kind = 'number', min = 1, max = 60, def = 9 },
        { key = 'meterSpeed', label = 'Vitesse de la jauge',       kind = 'number', min = .4, max = 3, step = .1, def = 1.1 },
        { key = 'sweet',      label = 'Largeur de la zone verte',  kind = 'number', min = .05, max = .5, step = .01, def = .16 },
        { key = 'scatter',    label = 'Dispersion max (m)',        kind = 'number', min = 0, max = 4, step = .1, def = 1.2 },
    },
    points = {
        { key = 'lobby',  label = 'Entrée du parcours', single = true },
        { key = 'spawns', label = 'Départ du joueur', max = 4 },
        { key = 'ball',   label = 'Point de départ de la balle', single = true },
        { key = 'zones',  label = 'Trous / zones à points', max = 12, radius = true, pts = true },
    },
    templates = { { id = 'hole', label = 'Parcours de golf', desc = '9 coups, trous à points.', settings = { minPlayers = 1, maxPlayers = 1, balls = 9, duration = 240, arenaRadius = 60 } } },
}
Config.Types.drag = raceType('Drag race', 'drag', 'Ligne droite : le premier à franchir l\'arrivée gagne. Place seulement le départ et l\'arrivée.', 'sultan', 'Drag 1 contre 1', '1 tour, 2 pilotes, mise partagée.', { minPlayers = 2, maxPlayers = 2, waitSeconds = 25, duration = 120, arenaRadius = 700, entryFee = 100, pot = true })
Config.Types.drag.cat = 'Courses'
Config.Types.parkour = raceType('Parcours', 'parkour', 'Course d\'obstacles à pied : saute, grimpe, passe tous les checkpoints au plus vite.', '', 'Parcours chronométré', 'À pied, 1 tour.', { minPlayers = 1, maxPlayers = 8, waitSeconds = 20, duration = 300, arenaRadius = 500 })
Config.Types.parkour.cat = 'Courses'
Config.Types.drag.fields[2].def = 1
Config.Types.parkour.fields[2].def = 1
Config.Types.parkour.fields[1].def = ''
for _, k in ipairs({ 'golf', 'drag', 'parkour' }) do Config.TypeOrder[#Config.TypeOrder + 1] = k end

-- Modèle « Time attack » (contre-la-montre en solo) pour toutes les courses
for _, k in ipairs(Config.TypeOrder) do
    local T = Config.Types[k]
    if T.engine == 'race' then
        T.templates[#T.templates + 1] = { id = 'timeattack', label = 'Contre-la-montre', desc = 'Solo, départ immédiat : bats le record du classement.', settings = { minPlayers = 1, maxPlayers = 1, waitSeconds = 0, duration = 600, arenaRadius = 1500, entryFee = 0, pot = false } }
    end
end

-- ─── Progression (XP, niveaux, défis, succès, saison) : valeurs par défaut ───
-- Tout est modifiable en jeu depuis le builder (bouton « Progression ») ; la base de données prend le dessus sur ces valeurs.
Config.ProfileCommand = 'mgprofil'      -- ouvre le profil joueur (niveau, défis, succès, classements)
Config.ProfileKey     = false           -- touche optionnelle (ex : 'F10')
Config.CoinsGrant     = true            -- crédite les coins de la boutique (pickax_core)

Config.Progress = {
    settings = {
        xp        = { enabled = true, perGame = 20, win = 40, perPoint = 1, maxPerGame = 250, streakPct = 10, streakMax = 5 },
        curve     = { base = 100, growth = 1.25, maxLevel = 50 },
        milestone = { enabled = true, xp = 2000, coins = 5, money = 0 },
        weekly    = { enabled = true, mode = 'random', gameId = '', mult = 2 },
        season    = { enabled = true, days = 30, rewards = { { rank = 1, money = 5000, coins = 50 }, { rank = 2, money = 3000, coins = 25 }, { rank = 3, money = 1500, coins = 10 } } },
        announce  = { records = true, levels = true },
    },
    levels = {
        { level = 2,  title = 'Débutant',  money = 0,     coins = 0 },
        { level = 5,  title = 'Amateur',   money = 500,   coins = 2 },
        { level = 10, title = 'Confirmé',  money = 1500,  coins = 5 },
        { level = 20, title = 'Expert',    money = 5000,  coins = 15 },
        { level = 35, title = 'Champion',  money = 10000, coins = 30 },
        { level = 50, title = 'Légende',   money = 25000, coins = 75 },
    },
    challenges = {
        { id = 'd_plays',  name = 'Joue 3 parties',        scope = 'daily',  kind = 'plays',  game = 'any', target = 3,   xp = 60,  money = 300,  coins = 0, enabled = true },
        { id = 'd_wins',   name = 'Gagne 1 partie',        scope = 'daily',  kind = 'wins',   game = 'any', target = 1,   xp = 80,  money = 400,  coins = 0, enabled = true },
        { id = 'd_points', name = 'Marque 50 points',      scope = 'daily',  kind = 'points', game = 'any', target = 50,  xp = 70,  money = 300,  coins = 0, enabled = true },
        { id = 'd_kart',   name = 'Fais 2 courses de karting', scope = 'daily', kind = 'plays', game = 'karting', target = 2, xp = 70, money = 300, coins = 0, enabled = true },
        { id = 'w_plays',  name = 'Joue 15 parties',       scope = 'weekly', kind = 'plays',  game = 'any', target = 15,  xp = 300, money = 2000, coins = 3, enabled = true },
        { id = 'w_wins',   name = 'Gagne 7 parties',       scope = 'weekly', kind = 'wins',   game = 'any', target = 7,   xp = 400, money = 3000, coins = 5, enabled = true },
        { id = 'w_points', name = 'Marque 500 points',     scope = 'weekly', kind = 'points', game = 'any', target = 500, xp = 350, money = 2500, coins = 4, enabled = true },
    },
    achievements = {
        { id = 'a_first',   name = 'Premier pas',      desc = 'Joue ta première partie',      kind = 'plays_total',  target = 1,   xp = 20,   money = 0,    coins = 0,  enabled = true },
        { id = 'a_win',     name = 'Première victoire', desc = 'Gagne une partie',            kind = 'wins_total',   target = 1,   xp = 50,   money = 200,  coins = 0,  enabled = true },
        { id = 'a_win25',   name = 'Habitué',          desc = 'Gagne 25 parties',             kind = 'wins_total',   target = 25,  xp = 300,  money = 2000, coins = 5,  enabled = true },
        { id = 'a_plays100', name = 'Accro',           desc = 'Joue 100 parties',             kind = 'plays_total',  target = 100, xp = 400,  money = 3000, coins = 5,  enabled = true },
        { id = 'a_pts1000', name = 'Marqueur',         desc = 'Marque 1000 points au total',  kind = 'points_total', target = 1000, xp = 400, money = 3000, coins = 5,  enabled = true },
        { id = 'a_streak5', name = 'Invincible',       desc = 'Enchaîne 5 victoires',         kind = 'best_streak',  target = 5,   xp = 500,  money = 4000, coins = 10, enabled = true },
        { id = 'a_lvl10',   name = 'Confirmé',         desc = 'Atteins le niveau 10',         kind = 'level',        target = 10,  xp = 0,    money = 1000, coins = 3,  enabled = true },
    },
}

-- ─── Armes, tints, props et modèles proposés dans le builder (liste de suggestions : tu peux aussi taper n'importe quel modèle) ───
Config.Weapons = {
    { 'WEAPON_PISTOL', 'Marqueur léger (pistolet)' }, { 'WEAPON_COMBATPISTOL', 'Marqueur combat (pistolet de combat)' }, { 'WEAPON_PISTOL50', 'Marqueur lourd (pistolet .50)' },
    { 'WEAPON_SNSPISTOL', 'Mini-marqueur (SNS)' }, { 'WEAPON_VINTAGEPISTOL', 'Marqueur rétro' }, { 'WEAPON_MARKSMANPISTOL', 'Marqueur de précision' },
    { 'WEAPON_MICROSMG', 'Marqueur rafale (micro-SMG)' }, { 'WEAPON_SMG', 'Marqueur SMG' }, { 'WEAPON_ASSAULTSMG', 'Marqueur SMG d\'assaut' }, { 'WEAPON_MACHINEPISTOL', 'Marqueur machine-pistolet' },
    { 'WEAPON_ASSAULTRIFLE', 'Marqueur fusil d\'assaut' }, { 'WEAPON_CARBINERIFLE', 'Marqueur carabine' }, { 'WEAPON_COMPACTRIFLE', 'Marqueur compact' }, { 'WEAPON_BULLPUPRIFLE', 'Marqueur bullpup' }, { 'WEAPON_SPECIALCARBINE', 'Marqueur carabine spéciale' },
    { 'WEAPON_MARKSMANRIFLE', 'Marqueur sniper léger' }, { 'WEAPON_SNIPERRIFLE', 'Marqueur sniper' },
    { 'WEAPON_PUMPSHOTGUN', 'Marqueur à pompe' }, { 'WEAPON_SAWNOFFSHOTGUN', 'Marqueur à canon scié' },
    { 'WEAPON_RAYPISTOL', 'Laser : pistolet (Up-n-Atomizer)' }, { 'WEAPON_RAYCARBINE', 'Laser : carabine' }, { 'WEAPON_RAYMINIGUN', 'Laser : minigun' },
    { 'WEAPON_STUNGUN', 'Taser' }, { 'WEAPON_FLAREGUN', 'Pistolet de détresse' },
}
-- Teintes d'armes (index natifs GTA)
Config.WeaponTints = { { '0', 'Aucune' }, { 'team', 'Couleur d\'équipe (bleu / orange)' }, { '1', 'Vert' }, { '2', 'Or' }, { '3', 'Rose' }, { '4', 'Armée' }, { '5', 'Bleu police' }, { '6', 'Orange' }, { '7', 'Platine' } }
Config.TeamTints = { 5, 6 }

-- Éclaboussures de peinture (paintball) : marqueurs colorés à l'impact, visibles par tous les joueurs de la partie
Config.Splat = { life = 25, max = 80, team = { { 59, 130, 246 }, { 255, 140, 0 } }, ffa = { { 255, 64, 129 }, { 0, 229, 255 }, { 124, 252, 0 }, { 255, 214, 10 } } }

-- Modèles suggérés (liste déroulante des champs « modèle ») — le bouton « Tester » vérifie qu'un modèle existe
Config.Models = {
    { 'prop_bskball_01', 'Ballon de basket' }, { 'p_ld_soc_ball_01', 'Ballon de foot' }, { 'prop_tennis_ball', 'Balle de tennis' }, { 'prop_golf_ball', 'Balle de golf' },
    { 'prop_beach_volball01', 'Ballon de volley' }, { 'prop_bowling_ball', 'Boule de bowling' }, { 'prop_bowling_pin', 'Quille de bowling' },
    { 'bmx', 'BMX' }, { 'cruiser', 'Vélo cruiser' }, { 'scorcher', 'VTT' }, { 'veto', 'Kart rétro' }, { 'veto2', 'Kart' }, { 'sultan', 'Sultan' }, { 'elegy', 'Elegy' }, { 'comet2', 'Comet' },
    { 'sanchez', 'Sanchez (moto cross)' }, { 'bati', 'Bati (moto sport)' }, { 'blazer', 'Blazer (quad)' }, { 'seashark', 'Jet-ski' }, { 'dinghy', 'Zodiac' },
}

-- Props décoratifs / obstacles placables dans une arène (catégories du sélecteur)
Config.Props = {
    { 'Terrains & paniers', {
        { 'prop_basketball_net', 'Panier de basket (filet)' }, { 'prop_goal_posts_01', 'Buts de foot' }, { 'prop_tennis_net_01', 'Filet de tennis' },
        { 'prop_dart_bd_01', 'Cible de fléchettes' }, { 'prop_bball_arcade_01', 'Borne d\'arcade basket' }, { 'prop_table_tennis', 'Table de ping-pong' },
        { 'prop_beachflag_01', 'Drapeau de plage' }, { 'bkr_prop_biker_target', 'Cible de tir' }, { 'bkr_prop_biker_target_small', 'Petite cible de tir' },
    } },
    { 'Barrières & obstacles', {
        { 'prop_barrier_work05', 'Barrière de chantier' }, { 'prop_barrier_work06a', 'Barrière de chantier (A)' }, { 'prop_barrier_work06b', 'Barrière de chantier (B)' },
        { 'prop_barrier_wat_03b', 'Barrière à eau' }, { 'prop_roadcone02a', 'Cône' }, { 'prop_roadcone01a', 'Cône (petit)' }, { 'prop_roadcone02b', 'Cône (large)' },
        { 'lts_prop_lts_ramp_01', 'Rampe (petite)' }, { 'lts_prop_lts_ramp_02', 'Rampe (moyenne)' }, { 'lts_prop_lts_ramp_03', 'Rampe (grande)' },
        { 'prop_skate_flatramp', 'Rampe de skate' }, { 'prop_jetski_ramp_01', 'Rampe de jet-ski' }, { 'prop_offroad_tyres02', 'Pneus' },
    } },
    { 'Abris & couverts (paintball / laser)', {
        { 'prop_skip_08a', 'Benne' }, { 'prop_bin_01a', 'Poubelle' }, { 'prop_conc_sacks_02a', 'Sacs de sable' }, { 'prop_pallet_01a', 'Palette' },
        { 'prop_boxpile_07d', 'Pile de cartons' }, { 'prop_cementbags01', 'Sacs de ciment' },
    } },
    { 'Balles & quilles', {
        { 'prop_bskball_01', 'Ballon de basket' }, { 'prop_tennis_ball', 'Balle de tennis' }, { 'prop_beach_volball01', 'Ballon de volley' }, { 'prop_golf_ball', 'Balle de golf' },
        { 'prop_bowling_ball', 'Boule de bowling' }, { 'prop_bowling_pin', 'Quille' }, { 'prop_dart_1', 'Fléchette' },
    } },
    { 'Éclairage & déco', {
        { 'prop_worklight_03b', 'Projecteur de chantier' }, { 'prop_worklight_01a', 'Projecteur' }, { 'prop_generator_03b', 'Groupe électrogène' },
        { 'prop_traffic_01a', 'Feu tricolore' }, { 'prop_beach_parasol_03', 'Parasol' }, { 'prop_table_03', 'Table' }, { 'prop_chair_01a', 'Chaise' },
    } },
}
Config.PropDefaults = { freeze = true, collision = true, mode = 'match' }   -- mode : 'match' = seulement pendant la partie, 'always' = toujours visible près du lobby
Config.PropStream = 120.0                                                  -- distance d'apparition des props « toujours visibles »

-- Réglages supplémentaires des mini-jeux de tir
for _, k in ipairs({ 'paintball', 'lasertag' }) do
    local f = Config.Types[k].fields
    f[#f + 1] = { key = 'tint', label = 'Teinte de l\'arme', kind = 'select', def = k == 'paintball' and 'team' or '0', options = Config.WeaponTints }
    f[#f + 1] = { key = 'splat', label = 'Éclaboussures de peinture à l\'impact', kind = 'bool', def = k == 'paintball' }
end

-- ─── Pré-placement : des mini-jeux déjà posés sur la carte ───────────────────────────────────────────────
-- Au premier démarrage, ces mini-jeux sont créés et ACTIVÉS (une seule fois : si tu en supprimes un, il ne revient pas).
-- Chaque terrain est calculé autour d'un point d'ancrage (x, y, z, cap) : le cap est la direction du terrain depuis l'entrée.
-- ⚠️ Positions APPROXIMATIVES (lieux connus de GTA V, disposition calculée) : certaines devront être décalées ou tournées :
--    ouvre le mini-jeu dans le builder → Emplacements / Props → mode placement (ou change simplement l'ancre ici et utilise /mgseed après suppression).
-- /mgseed (groupe admin) recrée ceux qui manquent. Config.AutoSeed = false pour désactiver.
Config.AutoSeed = false   -- false = aucun mini-jeu créé tout seul ; /mgseed (admin) les crée à la demande
Config.PresetGames = {
    { id = 'basket_legion',  layout = 'basket',    type = 'basket',    tpl = 'street', name = 'Basket · Legion Square', anchor = { x = 195.17, y = -933.77, z = 30.69, h = 70.0 } },
    { id = 'basket_grove',   layout = 'basket',    type = 'basket',    tpl = 'versus', name = 'Basket 1c1 · Grove Street', anchor = { x = 110.50, y = -1944.00, z = 20.80, h = 40.0 } },
    { id = 'penalty_beach',  layout = 'penalty',   type = 'football',  tpl = 'penalty', name = 'Tirs au but · Del Perro', anchor = { x = -1850.60, y = -1233.20, z = 13.02, h = 140.0 } },
    { id = 'darts_sandy',    layout = 'darts',     type = 'darts',     tpl = 'board',  name = 'Fléchettes · Sandy Shores', anchor = { x = 1961.50, y = 3741.50, z = 32.34, h = 300.0 } },
    { id = 'bowling_harmony', layout = 'bowling',  type = 'bowling',   tpl = 'lane',   name = 'Bowling · Harmony', anchor = { x = 549.00, y = 2671.00, z = 42.20, h = 100.0 } },
    { id = 'tennis_chumash', layout = 'tennis',    type = 'tennis',    tpl = 'training', name = 'Tennis · Chumash', anchor = { x = -3040.00, y = 585.00, z = 7.90, h = 20.0 } },
    { id = 'ring_downtown',  layout = 'ring',      type = 'boxing',    tpl = 'ring',   name = 'Ring de boxe · Downtown', anchor = { x = 909.00, y = -176.00, z = 74.20, h = 240.0 } },
    { id = 'paintball_grapeseed', layout = 'arena', type = 'paintball', tpl = 'arena', name = 'Paintball · Grapeseed', anchor = { x = 1698.00, y = 4924.00, z = 42.10, h = 320.0 } },
    { id = 'laser_paleto',   layout = 'ffa',       type = 'lasertag',  tpl = 'ffa',    name = 'Laser game · Paleto Bay', anchor = { x = -102.00, y = 6467.00, z = 31.60, h = 45.0 } },
    { id = 'sprint_pier',    layout = 'sprint',    type = 'race',      tpl = 'run',    name = 'Sprint 100 m · Jetée', anchor = { x = -1850.60, y = -1233.20, z = 13.02, h = 320.0 } },
}
