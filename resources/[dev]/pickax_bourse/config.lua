Config = {}

Config.Command = 'bourse'            -- ouvre la bourse (partout, ou aux points de Config.Spots si renseignés)
Config.Spots = {}                    -- optionnel : { { label = 'Bourse de Los Santos', coords = vector3(x, y, z), radius = 3.0 } } — vide = commande utilisable partout
Config.Account = 'bank'              -- compte débité / crédité
Config.TickMinutes = 10              -- durée entre deux mouvements de prix
Config.Fee = 1.0                     -- % prélevé à chaque achat ou vente
Config.FeeSociety = ''               -- société qui reçoit les frais ('' = personne)
Config.MaxPositionPerStock = 5000    -- actions maximum par joueur et par titre
Config.HistoryPoints = 24            -- points de l'historique affichés (tendance)
Config.Cooldown = 2                  -- secondes entre deux ordres d'un joueur

-- Actualités : de temps en temps, un titre reçoit une nouvelle qui fait bouger son prix (annoncée aux joueurs connectés qui ont des actions)
Config.News = { Enabled = true, ChancePerTick = 25, SwingMin = 4, SwingMax = 12 }   -- % de chance par mouvement ; variation en %

-- Titres : price = prix de départ ($), vol = volatilité par mouvement (%), drift = tendance (%) par mouvement (positif = monte en moyenne)
Config.Stocks = {
    { id = 'AERO', label = 'Aero Motors',       sector = 'Automobile', price = 120.0, vol = 3.0, drift = 0.05 },
    { id = 'LSPT', label = 'LS Petroleum',      sector = 'Énergie',    price = 85.0,  vol = 4.0, drift = 0.00 },
    { id = 'BNKR', label = 'Banker & Fils',     sector = 'Finance',    price = 200.0, vol = 1.8, drift = 0.04 },
    { id = 'WEED', label = 'Green Leaf Co.',    sector = 'Cannabis',   price = 40.0,  vol = 6.0, drift = -0.02 },
    { id = 'FOOD', label = 'Burger Shot Group', sector = 'Alimentaire', price = 60.0, vol = 2.2, drift = 0.03 },
}
