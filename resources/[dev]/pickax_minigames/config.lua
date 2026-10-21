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
