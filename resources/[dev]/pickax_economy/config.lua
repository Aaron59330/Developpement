Config = {}

-- Modèle : chaque marché (clé) a une « pression » : les VENTES des joueurs (offre) la font monter → le prix baisse ; les ACHATS (demande) la font descendre → le prix monte.
-- prix = base × multiplicateur ; multiplicateur = 1 − Sensitivity × tanh(pression / Scale) + événement, borné entre Min et Max. La pression retombe seule.
Config.Tick        = 300      -- secondes entre deux mises à jour (retour à la normale, événements, sauvegarde)
Config.Recovery    = 0.10     -- part de la pression qui disparaît à chaque tick (10 % toutes les 5 min ≈ retour à la normale en ~1 h)
Config.Sensitivity = 0.35     -- amplitude maximale due aux échanges (0.35 = ±35 %)
Config.Scale       = 60       -- volume d'échanges qui donne ~76 % de l'effet maximal

-- Réglages par type de marché (préfixe de la clé) : bornes du multiplicateur et échelle de volume
Config.Defaults = {
    ['shop:'] = { min = 0.80, max = 1.30, scale = 80 },    -- boutiques du Shop Builder (clé : shop:<catégorie>)
    ['crop:'] = { min = 0.60, max = 1.60, scale = 40 },    -- récoltes du fermier (clé : crop:<culture>)
}
Config.Fallback = { min = 0.70, max = 1.50, scale = 60 }

-- Événements aléatoires de marché (pénurie = prix en hausse, surplus = prix en baisse), sur un marché déjà actif
Config.Events = {
    Enabled  = true,
    Chance   = 0.12,          -- probabilité à chaque tick qu'un événement démarre (0.12 ≈ un toutes les ~40 min en moyenne)
    Duration = { 2, 6 },      -- heures
    Swing    = { 0.10, 0.25 },-- ± de multiplicateur apporté par l'événement
    Max      = 3,             -- événements simultanés
}
