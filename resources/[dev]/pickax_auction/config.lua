Config = {}

Config.Command   = 'encheres'          -- ouvre l'hôtel des ventes
Config.Spots     = {}                  -- optionnel : lieux où l'on peut l'ouvrir { label = 'Hôtel des ventes', coords = vector3(x, y, z), radius = 3.0 } ; vide = partout
Config.Durations = { 1, 6, 24, 72 }    -- durées proposées (heures)
Config.ListingFee = 2                  -- % du prix de départ, non remboursé (frais de mise en vente)
Config.MinFee     = 25                 -- frais minimum ($)
Config.SaleTax    = 5                  -- % prélevé sur le prix final, payé par le vendeur
Config.MaxListings = 5                 -- enchères actives par joueur
Config.MinIncrementPct  = 5            -- surenchère minimale en % de l'enchère actuelle
Config.MinIncrementFlat = 10           -- ... et au moins ce montant ($)
Config.SnipeSeconds = 120              -- une enchère reçue dans les dernières secondes prolonge de ce délai
Config.MaxPrice  = 500000000
Config.PayoutAccount = 'bank'          -- compte crédité au vendeur
Config.AllowVehicles = true
Config.AllowWeapons  = false           -- les armes ont des numéros de série : désactivé par défaut
Config.BlockedItems  = { 'money', 'black_money', 'phone', 'id_card', 'driver_license', 'weapon_license' }

-- Table des véhicules possédés (même réglage que le concessionnaire du Job Builder)
Config.Vehicles = {
    Table = 'owned_vehicles',
    Cols  = { owner = 'owner', plate = 'plate', vehicle = 'vehicle', state = 'state', name = 'name' },
    StoredState = 1,                   -- valeur de la colonne state quand le véhicule est au garage (seuls ceux-là peuvent être mis en vente)
}

-- Véhicules de la fourrière vendus par l'État (voir pickax_worldbuilder : Config.ImpoundAuction)
Config.State = {
    Name = 'Fourrière',                -- nom du vendeur affiché
    Society = 'society_police',        -- compte société qui reçoit le produit des ventes ('' = personne)
    Unsold = 'owner',                  -- invendu : 'owner' = rendu à l'ancien propriétaire (toujours en fourrière) | 'scrap' = détruit
}

Config.Webhook = ''                    -- webhook Discord des ventes terminées (vide = désactivé)
