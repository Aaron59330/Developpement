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
Config.LeaveKey         = 'F9'                            -- touche pour quitter une partie (réglable dans les touches FiveM)
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
        { key = 'ballModel',   label = 'Modèle de la fléchette',    kind = 'model', def = 'prop_golf_ball' },
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
