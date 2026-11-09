Config = {}

Config.Brand = 'Sensity'            -- texte du logo en haut à gauche
Config.Command = 'inv'             -- /inv ouvre / ferme l'inventaire
Config.Key = 'F3'                  -- touche d'ouverture (F2 est déjà prise par ox_inventory) ; '' = aucune
Config.Shortcuts = 5               -- nombre de raccourcis (emplacements 1 à N d'ox_inventory = touches Num 1…)
Config.Columns = 7                 -- colonnes de la grille
Config.Rows = 4                    -- lignes de l'inventaire
Config.WarnWeight = 0.85           -- au-delà de cette part du poids max : alerte « Inventaire presque plein »
Config.RecentCount = 3             -- objets affichés dans « Reçu récemment »
Config.ShopCommand = 'menuboutique' -- bouton « Inventaire boutique » ('' = bouton caché)
Config.ImagePath = 'nui://ox_inventory/web/images/%s.png' -- où trouver l'image d'un objet

-- Équipement affiché à gauche : composant GTA (ou prop) -> libellé. kind = 'comp' (vêtement) ou 'prop' (accessoire)
Config.Equipment = {
    top    = { { 'Tenue', 'comp', 11 }, { 'Parachute', 'comp', 5 }, { 'Perruque', 'comp', 2 } },
    left   = { { 'Chapeau', 'prop', 0 }, { 'Lunettes', 'prop', 1 }, { 'Accessoire', 'comp', 7 }, { 'Haut', 'comp', 8 }, { 'Pantalon', 'comp', 4 }, { 'Chaussures', 'comp', 6 } },
    right  = { { 'Masque', 'comp', 1 }, { 'Boucles', 'prop', 2 }, { 'Sac', 'comp', 3 }, { 'Gilet', 'comp', 9 }, { 'Bracelet', 'prop', 7 }, { 'Montre', 'prop', 6 } },
}
