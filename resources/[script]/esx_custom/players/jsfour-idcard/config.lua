ConfigJsFourd = {
    Text = "Appuyez sur ~INPUT_CELLPHONE_CANCEL~ ou ~INPUT_AIM~ pour enlever la carte.",
    ShowToNearby = true, -- montre aussi la carte aux joueurs proches quand on utilise l'item
    ShowDistance = 3.0,
    Notify = function(source, msg)
        TriggerClientEvent('esx:showNotification', source, msg)
    end
}
