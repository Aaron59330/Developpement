Config = {}

Config.Brand = 'Sensity'            -- texte du logo en haut à gauche
Config.Command = 'inv'             -- /inv ouvre / ferme l'inventaire
Config.Key = 'F3'                  -- touche d'ouverture (F2 est déjà prise par ox_inventory) ; '' = aucune
Config.Shortcuts = 5               -- nombre de raccourcis (emplacements 1 à N d'ox_inventory = touches Num 1…)
Config.Columns = 7                 -- colonnes de la grille
Config.Rows = 4                    -- lignes de l'inventaire
Config.WarnWeight = 0.85           -- au-delà de cette part du poids max : alerte « Inventaire presque plein »
Config.RecentCount = 3             -- objets affichés dans « Reçu récemment »
Config.ImagePath = 'nui://ox_inventory/web/images/%s.png' -- où trouver l'image d'un objet

-- Équipement affiché à gauche : composant GTA (ou prop) -> libellé. kind = 'comp' (vêtement) ou 'prop' (accessoire)
Config.Equipment = {
    top    = { { 'Tenue', 'comp', 11 }, { 'Parachute', 'comp', 5 }, { 'Perruque', 'comp', 2 } },
    left   = { { 'Chapeau', 'prop', 0 }, { 'Lunettes', 'prop', 1 }, { 'Accessoire', 'comp', 7 }, { 'Haut', 'comp', 8 }, { 'Pantalon', 'comp', 4 }, { 'Chaussures', 'comp', 6 } },
    right  = { { 'Masque', 'comp', 1 }, { 'Boucles', 'prop', 2 }, { 'Sac', 'comp', 3 }, { 'Gilet', 'comp', 9 }, { 'Bracelet', 'prop', 7 }, { 'Montre', 'prop', 6 } },
}

-- Inventaire boutique : coffre PRIVÉ de chaque joueur où arrivent les objets achetés / gagnés à la boutique (objets, armes-objets, caisses, roulette).
-- Il n'est lié qu'au joueur : personne ne peut le voir en le fouillant et aucun autre script ne l'ouvre.
Config.ShopStash = { Label = 'Inventaire boutique', Slots = 100, MaxWeight = 500000 }   -- poids en grammes (ox_inventory)
Config.ShopGroups = {      -- rangement par catégorie dans l'inventaire boutique (premier motif trouvé, sinon « Objets »)
    { 'Armes',   '^weapon_' },
    { 'Munitions', 'ammo' },
    { 'Caisses et packs', 'crate|caisse|pack|box' },
    { 'Véhicules et clés', 'key|cle|vehicle|veh' },
    { 'Consommables', 'water|bread|burger|cola|food|drink|medikit|bandage|pill' },
}
