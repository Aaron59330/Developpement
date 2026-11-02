Config = {}

-- ═════════════════════════════ EMS AVANCÉ ═════════════════════════════
Config.Enabled  = true
Config.Jobs     = { 'ambulance', 'ems' }       -- métiers médicaux (noms ESX) ET / OU types du Job Builder
Config.JobTypes = { 'ems' }
Config.Command  = 'ems'                         -- /ems [id] : examen du patient le plus proche (ou de l'ID donné)
Config.Distance = 3.5

-- Hôpitaux : le bloc opératoire (chirurgie) et l'imagerie (radio) ne sont utilisables qu'ici. Vide = partout.
Config.Hospitals = {
    { label = 'Pillbox Hill', coords = vector3(311.2, -582.9, 43.3), radius = 40.0 },
}
Config.RequireHospitalFor = { xray = true, surgery = true }

-- ═════════════════════════════ BLESSURES ═════════════════════════════
Config.Zones = { head = 'Tête', torso = 'Torse', larm = 'Bras gauche', rarm = 'Bras droit', lleg = 'Jambe gauche', rleg = 'Jambe droite' }
-- niveau selon les dégâts d'un coup : 1 contusion · 2 plaie (saigne) · 3 grave (fracture / hémorragie interne / commotion)
Config.Severity = { wound = 10, severe = 28 }
Config.Bleed = {
    Tick        = 10,       -- secondes entre deux calculs
    PerLevel    = 0.9,      -- % de sang perdu par tick et par niveau de plaie
    Internal    = 2.2,      -- % par tick pour une hémorragie interne
    Regen       = 0.15,     -- % regagnés par tick sans saignement
    Weak        = 35,       -- sous ce % de sang : vision trouble, démarche lente
    Faint       = 15,       -- sous ce % : le blessé s'évanouit par moments
    DeathBelow  = 0,        -- à 0 % le blessé perd connaissance (mort : voir le système de mort du Job Builder)
}

-- ═════════════════════════════ SOINS ═════════════════════════════
-- item consommé, mini-jeu (pickax_skillgames), score minimal de réussite (%)
Config.Treatments = {
    bandage = { label = 'Bandage',        item = 'bandage',    game = 'wrap',   cfg = { turns = 4, seconds = 22 }, min = 50, only = 'bleeding' },
    suture  = { label = 'Suture',         item = 'suture_kit', game = 'suture', cfg = { stitches = 5, seconds = 32 }, min = 55, only = 'wound' },
    splint  = { label = 'Attelle',        item = 'splint',     game = 'timing', cfg = { rounds = 3, seconds = 24, difficulty = 1 }, min = 60, only = 'fracture' },
    surgery = { label = 'Chirurgie',      item = 'surgery_kit', game = 'suture', cfg = { stitches = 8, seconds = 40 }, min = 65, only = 'severe', hospital = true },
}
Config.Cpr = { cfg = { bpm = 110, beats = 30 }, min = 55, health = 35, healthBonus = 0.3, DefibItem = 'defibrillator', DefibBonus = 15 }
Config.Exam = {
    BloodTestItem = '',              -- item consommé pour une prise de sang (vide = aucun)
    XraySeconds   = 8,
}

-- ═════════════════════════════ TRANSFUSION ═════════════════════════════
Config.Blood = {
    BagItem  = 'blood_bag',
    Donation = 4,                     -- % de sang prélevé sur le donneur
    Min      = 70,                    -- le donneur doit avoir au moins ce % de sang
    Transfuse = 40,                   -- % de sang rendu par une poche compatible
    Reaction  = 25,                   -- % de sang perdu en cas de poche incompatible (réaction transfusionnelle)
    Salt     = 'change-moi',          -- graine secrète des groupes sanguins : change-la
}

-- ═════════════════════════════ TRIAGE ═════════════════════════════
Config.Triage = { Range = 35.0, Tags = { red = 'Urgence absolue', orange = 'Urgence relative', green = 'Soins différés', black = 'Décédé / dépassé' } }
