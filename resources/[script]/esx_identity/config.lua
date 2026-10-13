Config = {
    Framework = "es_extended",
    GiveIdCardItem = true, -- donne l'item id_card (ox_inventory) à la création du personnage
    CustomTrigger = false,--Mettre true puis mettre se qu'il faut dans la fonction en dessous
}

function CustomEvent(src)
    --Mettre votre trigger ici:
    --[[
        Exemple : TriggerEvent('CorePickax:Creator:openSkinMenu', src)
    ]]--
end