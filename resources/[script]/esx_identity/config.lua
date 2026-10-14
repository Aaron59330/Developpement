Config = {
    Framework = "es_extended",
    GiveIdCardItem = true, -- donne l'item id_card (ox_inventory) à la création du personnage
    CustomTrigger = false,--Mettre true puis mettre se qu'il faut dans la fonction en dessous
}

-- ───────────── Menu « Destination » : proposé une fois le personnage validé (création de personnage uniquement) ─────────────
-- Le joueur choisit l'un de ces lieux d'arrivée. Modifie / ajoute des lieux librement (3 recommandés pour une belle présentation).
-- coords = vector4(x, y, z, cap). icon (facultatif) : 'plane', 'city', 'beach', 'house', 'pin'.
Config.Destinations = {
    Enabled = true,
    Title = 'Destination',
    Hint = 'Choisis où commencer ta vie',
    Spots = {
        { label = 'Aéroport de Los Santos', description = 'Arrive comme tout nouveau venu en ville.',  icon = 'plane', coords = vector4(-1037.00, -2737.00, 20.17, 330.00) },
        { label = 'Legion Square',          description = 'Au cœur de la ville, près de tout.',        icon = 'city',  coords = vector4(195.17, -933.77, 30.69, 144.00) },
        { label = 'Plage de Vespucci',      description = 'Un début de vie au bord de l\'océan.',      icon = 'beach', coords = vector4(-1392.00, -1430.00, 4.00, 25.00) },
    },
}

function CustomEvent(src)
    --Mettre votre trigger ici:
    --[[
        Exemple : TriggerEvent('CorePickax:Creator:openSkinMenu', src)
    ]]--
end

-- ───────────── Cinématique d'arrivée : un avion atterrit à l'aéroport avec le joueur à bord ─────────────
-- Jouée après le choix de la destination, avant l'apparition à la destination choisie.
-- Le joueur descend de l'avion, l'écran reste noir 1 seconde (BlackScreenMs), puis il apparaît à sa destination.
Config.Cinematic = {
    Enabled = true,
    Plane = 'luxor',                         -- modèle de l'avion (jet privé). Autres choix : 'shamal', 'nimbus', 'velum'
    -- ⚠ PISTE : ces deux valeurs sont à régler sur TA piste. Place-toi en jeu SUR la piste de l'aéroport, au point où l'avion doit toucher le sol,
    -- face à la direction dans laquelle il doit rouler, puis tape /pisteavion (admin) : copie ici les valeurs affichées dans la console F8.
    Touchdown = vector3(-1267.00, -3013.00, 13.94),  -- point où l'avion touche la piste (aéroport de Los Santos)
    Heading = 330.0,                         -- direction de la piste (cap de l'avion à l'atterrissage)
    ApproachSeconds = 16,                    -- durée de la descente
    RolloutSeconds = 7,                      -- durée du roulage jusqu'à l'arrêt
    ApproachDistance = 1900.0,               -- distance de départ avant la piste (m)
    StartAltitude = 260.0,                   -- altitude de départ au-dessus de la piste (m)
    RolloutDistance = 620.0,                 -- distance parcourue sur la piste après l'atterrissage (m)
    BlackScreenMs = 1000,                    -- écran noir entre la descente de l'avion et l'arrivée à destination
    AllowSkip = true,                        -- Retour arrière (Backspace) pour passer la cinématique
}
