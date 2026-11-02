Config = {
    Framework = "es_extended",
    GiveIdCardItem = true, -- donne l'item id_card (ox_inventory) à la création du personnage
    CustomTrigger = false,--Mettre true puis mettre se qu'il faut dans la fonction en dessous
}

-- ───────────── Menu « Destination » ─────────────
-- Les lieux d'arrivée (et la scène / caméra de création) se règlent dans pickax_creator/config.lua (Config.Destinations, Config.Scene).
-- Ce repli ne sert que si pickax_creator n'est pas démarré.
Config.Destinations = { Enabled = false, Spots = {} }

function CustomEvent(src)
    --Mettre votre trigger ici:
    --[[
        Exemple : TriggerEvent('CorePickax:Creator:openSkinMenu', src)
    ]]--
end
