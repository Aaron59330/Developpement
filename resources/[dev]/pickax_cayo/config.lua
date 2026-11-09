Config = {}

-- ═════════════════════════════════════════════════════════════════
--  BRAQUAGE DE CAYO PERICO  — tout se règle ici
--  Les coordonnées de l'île sont celles de l'île de GTA Online, relevées « à vue » : vérifie-les en jeu avec /cayotp <point> (staff)
--  et corrige-les avec /cayopos (affiche tes coordonnées dans la console F8).
-- ═════════════════════════════════════════════════════════════════

Config.Command = 'cayo'                         -- ouvre la tablette quand on est au poste de planification (staff : partout, voir AdminGroups)
Config.AdminGroups = { admin = true, superadmin = true, mod = true }   -- groupes ESX pouvant utiliser /cayotp et /cayoreset

-- Poste de planification (la « table du Kosatka ») : tablette utilisable ici
Config.Planning = { coords = vec3(1196.6, -3253.5, 7.1), radius = 3.0, label = 'Planification — Cayo Perico', blip = { sprite = 760, colour = 3, scale = 0.8 } }
Config.ReturnPoint = vec4(1210.0, -3240.0, 5.6, 90.0)   -- où l'équipe revient à la fin (réussite, échec ou abandon)

Config.Players = { min = 1, max = 4 }
Config.Cooldown = 3600                          -- secondes avant qu'un chef puisse relancer un braquage
Config.MaxDuration = 2700                       -- durée maximum du braquage sur l'île (secondes)
Config.MinPolice = 0                            -- policiers en service minimum (job police)
Config.PoliceJob = 'police'
Config.LaunchFee = 25000                        -- frais de lancement payés par le chef (compte « money » puis « bank »)
Config.PayAccount = 'black_money'               -- compte ESX crédité des gains (black_money / money / bank)
Config.Fees = { pavel = 2, fence = 10 }         -- % retirés du butin : Pavel (pilote du Kosatka) et recel
Config.ScopeRequired = 2                        -- nombre de reconnaissances obligatoires avant le lancement
Config.HardBonus = 0.10                         -- +10 % de gains en mode difficile
Config.InviteSeconds = 30

-- ═════════════ CIBLES PRINCIPALES (valeur en $) ═════════════
Config.Targets = {
    { id = 'tequila',  label = 'Tequila Sinsimito',  value = 630000,  desc = 'Une bouteille rare dans le bureau d\'El Rubio.' },
    { id = 'ruby',     label = 'Collier de rubis',   value = 700000,  desc = 'Dans le coffre de la salle de sécurité.' },
    { id = 'bonds',    label = 'Bons au porteur',    value = 770000,  desc = 'Une mallette dans le coffre de la villa.' },
    { id = 'diamond',  label = 'Diamant rose',       value = 1300000, desc = 'Exposé dans la vitrine de la salle de réception.' },
    { id = 'files',    label = 'Dossiers Madrazo',   value = 1100000, desc = 'Archives compromettantes d\'El Rubio.' },
    { id = 'panther',  label = 'Statue de la panthère', value = 1900000, desc = 'La pièce maîtresse de la collection, dans le coffre-fort.' },
}

-- ═════════════ BUTIN SECONDAIRE ═════════════
-- units : place prise dans le sac · value : valeur de ce butin
Config.BagCapacity = 100
Config.Loot = {
    cash    = { label = 'Liquide',   units = 18, value = 90000 },
    weed    = { label = 'Cannabis',  units = 25, value = 140000 },
    coke    = { label = 'Cocaïne',   units = 25, value = 220000 },
    gold    = { label = 'Or',        units = 33, value = 330000 },
    art     = { label = 'Tableaux',  units = 20, value = 190000 },
}

-- ═════════════ APPROCHE (véhicule et point de départ en mer / en l'air) ═════════════
-- vehicle : modèle spawné pour l'équipe · skydive : largage en parachute à l'altitude donnée
Config.Approaches = {
    { id = 'kosatka',   label = 'Kosatka (sous-marin)',  desc = 'Insertion discrète à la nage depuis le sous-marin.', start = vec4(5420.0, -5440.0, 0.5, 300.0), vehicle = 'dinghy' },
    { id = 'longfin',   label = 'Longfin',               desc = 'Bateau rapide : accoste sur la plage.',               start = vec4(5300.0, -5190.0, 0.5, 280.0), vehicle = 'longfin' },
    { id = 'patrol',    label = 'Patrouilleur',          desc = 'Bateau armé : arrivée au port principal.',            start = vec4(5300.0, -5000.0, 0.5, 260.0), vehicle = 'patrolboat' },
    { id = 'annihilator', label = 'Annihilator Stealth', desc = 'Hélicoptère furtif : dépose sur les côtes.',          start = vec4(5500.0, -5300.0, 80.0, 280.0), vehicle = 'annihilator2' },
    { id = 'alkonost',  label = 'Alkonost',              desc = 'Avion : largage en parachute au-dessus de l\'île.',   start = vec4(4700.0, -5000.0, 650.0, 90.0), skydive = true },
    { id = 'velum',     label = 'Velum',                 desc = 'Avion léger : largage près de l\'aérodrome.',         start = vec4(4500.0, -4500.0, 600.0, 180.0), skydive = true },
}

-- Point d'infiltration : où l'équipe se pose une fois sur l'île (chaque point a ses gardes et son rythme)
Config.Infiltrations = {
    { id = 'airstrip', label = 'Aérodrome',         coords = vec4(4458.0, -4466.0, 4.3, 200.0) },
    { id = 'dock',     label = 'Port principal',    coords = vec4(5124.0, -5134.0, 2.0, 0.0) },
    { id = 'beach',    label = 'Plage',            coords = vec4(4886.0, -5176.0, 2.4, 90.0) },
    { id = 'drain',    label = 'Canal d\'évacuation', coords = vec4(5057.0, -5785.0, 1.5, 0.0) },
}
-- Point d'extraction
Config.Exfils = {
    { id = 'dock',     label = 'Port principal',  coords = vec3(5136.0, -5140.0, 2.0), radius = 25.0 },
    { id = 'airstrip', label = 'Aérodrome',       coords = vec3(4476.0, -4496.0, 4.3), radius = 30.0 },
    { id = 'beach',    label = 'Plage',           coords = vec3(4884.0, -5170.0, 2.4), radius = 25.0 },
}

-- ═════════════ ÉQUIPEMENT (nécessaire pour passer certains obstacles sur l'île) ═════════════
Config.Equipment = {
    { id = 'grapple', label = 'Grappin',               desc = 'Escalader la clôture et les toits.' },
    { id = 'cutters', label = 'Pince coupante',        desc = 'Couper les grillages et les portails.' },
    { id = 'torch',   label = 'Chalumeau',             desc = 'Découper la porte blindée du coffre.' },
    { id = 'cloner',  label = 'Cloneur d\'empreintes', desc = 'Ouvrir la salle de sécurité sans alarme.' },
    { id = 'uniform', label = 'Uniforme de garde',     desc = 'Les gardes mettent plus de temps à vous repérer.' },
    { id = 'silencer',label = 'Silencieux',            desc = 'Les tirs ne déclenchent pas l\'alarme.' },
}

-- ═════════════ ARMEMENT ═════════════
-- Donné au départ, retiré à la fin : items = { { nom_ox, quantité } }
Config.Loadouts = {
    { id = 'aggressor',  label = 'Agresseur',       desc = 'Carabine et fusil à pompe : puissance de feu.', items = { { 'WEAPON_CARBINERIFLE', 1 }, { 'ammo-rifle', 150 }, { 'WEAPON_PUMPSHOTGUN', 1 }, { 'ammo-shotgun', 40 } } },
    { id = 'conspirator',label = 'Conspirateur',    desc = 'SMG et pistolet : mobile et polyvalent.',      items = { { 'WEAPON_SMG', 1 }, { 'ammo-9', 180 }, { 'WEAPON_PISTOL', 1 }, { 'ammo-9', 60 } } },
    { id = 'crackshot',  label = 'Tireur d\'élite', desc = 'Fusil de précision et pistolet.',              items = { { 'WEAPON_SNIPERRIFLE', 1 }, { 'ammo-sniper', 40 }, { 'WEAPON_PISTOL', 1 }, { 'ammo-9', 60 } } },
    { id = 'saboteur',   label = 'Saboteur',        desc = 'Micro-SMG et explosifs légers.',               items = { { 'WEAPON_MICROSMG', 1 }, { 'ammo-9', 150 } } },
}

-- ═════════════ DIFFICULTÉ ═════════════
Config.Difficulties = {
    normal = { label = 'Normal',    guards = 1.0, health = 200, accuracy = 25, reinforce = 120 },
    hard   = { label = 'Difficile', guards = 1.5, health = 300, accuracy = 45, reinforce = 70 },
}

-- ═════════════ RECONNAISSANCES ET PRÉPARATIFS (sur le continent) ═════════════
-- Reconnaissance : se rendre au point et observer (maintenir E). Préparatif d'équipement : récupérer le matériel au point.
Config.Scope = {
    { id = 'airstrip', label = 'Aérodrome',          coords = vec3(1740.0, 3265.0, 41.2) },
    { id = 'dock',     label = 'Port principal',     coords = vec3(1355.0, -2540.0, 4.1) },
    { id = 'compound', label = 'Complexe d\'El Rubio', coords = vec3(-2316.0, 3405.0, 29.0) },
}
-- Un point de récupération par équipement choisi
Config.PrepPoints = {
    grapple  = vec3(1130.0, -3280.0, 5.9),
    cutters  = vec3(1005.0, -2530.0, 28.3),
    torch    = vec3(727.0, -1286.0, 26.3),
    cloner   = vec3(-1170.0, -2020.0, 13.2),
    uniform  = vec3(-1305.0, -2808.0, 13.9),
    silencer = vec3(809.0, -2159.0, 29.6),
}
Config.PrepSeconds = 6

-- ═════════════ ÎLE : POSITIONS ═════════════
Config.Island = {
    center = vec3(4840.57, -5174.42, 2.0),
    -- Coffre-fort du complexe : cible principale
    vault = vec3(5006.7, -5754.2, 15.5),
    -- Portes / obstacles : need = équipement requis (aucun = toujours ouvert)
    obstacles = {
        { id = 'gate',   label = 'Grillage du complexe', coords = vec3(4985.0, -5715.0, 19.9), need = 'cutters', seconds = 6 },
        { id = 'wall',   label = 'Mur d\'enceinte',      coords = vec3(5048.0, -5740.0, 20.0),  need = 'grapple', seconds = 5 },
        { id = 'secure', label = 'Salle de sécurité',    coords = vec3(5003.0, -5746.0, 28.8),  need = 'cloner',  seconds = 8, optional = true },
        { id = 'door',   label = 'Porte blindée du coffre', coords = vec3(5006.7, -5753.0, 15.5), need = 'torch', seconds = 12 },
    },
    -- Zones de gardes : count de base (multiplié par la difficulté)
    guards = {
        { coords = vec3(5006.0, -5745.0, 28.8), radius = 18.0, count = 5, label = 'Villa' },
        { coords = vec3(4985.0, -5715.0, 20.0), radius = 14.0, count = 3, label = 'Entrée' },
        { coords = vec3(5124.0, -5134.0, 2.0),  radius = 20.0, count = 4, label = 'Port principal' },
        { coords = vec3(4460.0, -4470.0, 4.3),  radius = 25.0, count = 4, label = 'Aérodrome' },
        { coords = vec3(4886.0, -5176.0, 2.4),  radius = 20.0, count = 3, label = 'Plage' },
        { coords = vec3(5057.0, -5785.0, 1.5),  radius = 15.0, count = 2, label = 'Canal' },
        { coords = vec3(5130.0, -5520.0, 12.0), radius = 18.0, count = 3, label = 'Entrepôts' },
        { coords = vec3(4510.0, -4560.0, 4.3),  radius = 18.0, count = 3, label = 'Hangar' },
    },
    guardModels = { 'g_m_m_cartelguards_01', 'g_m_m_cartelguards_02' },
    guardWeapons = { 'WEAPON_CARBINERIFLE', 'WEAPON_PISTOL', 'WEAPON_SMG' },
    reinforcementHeli = 'buzzard',
    -- Butin secondaire : chaque point peut être présent selon LootChance
    LootChance = 0.7,
    loot = {
        { id = 1,  type = 'cash', coords = vec3(5008.0, -5736.0, 28.8) },
        { id = 2,  type = 'cash', coords = vec3(5020.0, -5752.0, 28.8) },
        { id = 3,  type = 'gold', coords = vec3(5001.0, -5760.0, 15.5) },
        { id = 4,  type = 'art',  coords = vec3(5012.0, -5740.0, 28.8) },
        { id = 5,  type = 'art',  coords = vec3(4998.0, -5732.0, 28.8) },
        { id = 6,  type = 'coke', coords = vec3(5134.0, -5522.0, 12.0) },
        { id = 7,  type = 'weed', coords = vec3(5118.0, -5514.0, 12.0) },
        { id = 8,  type = 'cash', coords = vec3(5127.0, -5127.0, 2.0) },
        { id = 9,  type = 'gold', coords = vec3(5117.0, -5142.0, 2.0) },
        { id = 10, type = 'coke', coords = vec3(4504.0, -4556.0, 4.3) },
        { id = 11, type = 'weed', coords = vec3(4516.0, -4566.0, 4.3) },
        { id = 12, type = 'cash', coords = vec3(4462.0, -4478.0, 4.3) },
        { id = 13, type = 'art',  coords = vec3(4894.0, -5168.0, 2.4) },
        { id = 14, type = 'gold', coords = vec3(4879.0, -5186.0, 2.4) },
        { id = 15, type = 'cash', coords = vec3(5052.0, -5780.0, 2.0) },
        { id = 16, type = 'weed', coords = vec3(5100.0, -5700.0, 5.0) },
        { id = 17, type = 'coke', coords = vec3(4960.0, -5640.0, 9.0) },
        { id = 18, type = 'art',  coords = vec3(5030.0, -5690.0, 20.0) },
    },
}
Config.LootSeconds = 4
