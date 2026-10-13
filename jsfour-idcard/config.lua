ConfigJsFourd = {
    Text = "Appuyez sur ~INPUT_CELLPHONE_CANCEL~ ou ~INPUT_AIM~ pour enlever la carte.",
    Notify = function(source, msg)
        TriggerClientEvent('esx:showNotification', source, msg)
    end
}
