Config = {
    Framework = "es_extended",
    GiveIdCardItem = true, -- donne l'item id_card (ox_inventory) à la création du personnage
    CustomTrigger = false,--Mettre true puis mettre se qu'il faut dans la fonction en dessous
}

-- ───────────── Menu « Destination » : proposé une fois le personnage validé (création de personnage uniquement) ─────────────
-- Le joueur choisit l'un de ces lieux d'arrivée. Modifie / ajoute des lieux librement (3 recommandés pour une belle présentation).
-- coords = vector4(x, y, z, cap). icon (facultatif) : 'plane', 'city', 'beach', 'house', 'pin'.
-- image (facultatif) : fichier placé dans pickax_creator/html/places/ (jpg/png, 626×264 conseillé).
Config.Destinations = {
    Enabled = true,
    Title = 'Destination',
    Hint = 'Choisis où commencer ta vie',
    Spots = {
        { label = 'Aéroport de Los Santos', description = 'Arrive comme tout nouveau venu en ville.',  icon = 'plane', image = 'airport.jpg', coords = vector4(-1037.00, -2737.00, 20.17, 330.00) },
        { label = 'Legion Square',          description = 'Au cœur de la ville, près de tout.',        icon = 'city',  image = 'legion.jpg', coords = vector4(195.17, -933.77, 30.69, 144.00) },
        { label = 'Plage de Vespucci',      description = 'Un début de vie au bord de l\'océan.',      icon = 'beach', image = 'vespucci.jpg', coords = vector4(-1392.00, -1430.00, 4.00, 25.00) },
    },
}

function CustomEvent(src)
    --Mettre votre trigger ici:
    --[[
        Exemple : TriggerEvent('CorePickax:Creator:openSkinMenu', src)
    ]]--
end
