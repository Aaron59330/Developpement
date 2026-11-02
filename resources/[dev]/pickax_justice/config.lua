Config = {}
Config.Enabled = true
Config.UseCommands = false   -- true = active aussi /mandat, /mandats, /saisie, /saisies, /alcootest, /papiers (par défaut : menu contextuel sur la personne contrôlée et menu F6 du job)

-- Rôles : noms de jobs ESX ET / OU types de job du Job Builder
Config.Judges  = { Jobs = { 'judge', 'justice' }, Types = { 'government' } }   -- type « government » du Job Builder = juges / gouvernement
Config.Police  = { Jobs = { 'police', 'sheriff' }, Types = { 'police' } }

-- ═════════════════════════════ MANDATS ═════════════════════════════
-- Un juge délivre un mandat (perquisition ou arrestation) visant une personne ; il expire après un délai. La police le consulte et l'exécute.
Config.Warrants = {
    Command = 'mandat',            -- /mandat : (juge) délivrer un mandat
    ListCommand = 'mandats',       -- /mandats : (juge, police) liste des mandats actifs
    ExpireHours = { search = 72, arrest = 168 },
    Max = 40,
}
-- Saisies : /saisie [id] [note] (police). Journalisées ; « sans mandat de perquisition valide » = contestable (visible des juges avec /saisies).
Config.Seizures = { Command = 'saisie', ListCommand = 'saisies', Distance = 4.0 }

-- ═════════════════════════════ ALCOOL ═════════════════════════════
-- Les boissons listées augmentent l'alcoolémie (g/L) quand on les consomme ; elle redescend avec le temps.
Config.Alcohol = {
    Command = 'alcootest', Distance = 3.0, Seconds = 5,
    Limit = 0.5,                    -- g/L : au-delà, infraction
    PerUnit = 0.15,                 -- g/L par unité d'alcool
    DecayPerHour = 0.15,            -- g/L éliminés par heure
    Items = { beer = 1.0, wine = 1.0, whisky = 2.0, vodka = 2.0, rhum = 2.0, tequila = 2.0, martini = 1.0, champagne = 1.0, mojito = 1.5 },
}

-- ═════════════════════════════ CONTRÔLE DES PAPIERS ═════════════════════════════
-- /papiers [id] : le contrôlé choisit le document présenté (vrai ou faux s'il en possède un). Un faux est détecté avec une probabilité qui diminue avec sa qualité.
Config.Papers = {
    Command = 'papiers', Distance = 3.0, AskSeconds = 20,
    RealItem = 'id_card', FakeItem = 'fake_id',
    DetectBase = 0.10,              -- probabilité minimale de détection (même pour un faux parfait)
    DetectMax = 0.95,               -- et maximale (faux grossier)
}
