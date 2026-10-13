RegisterNetEvent('CorePickax:Chargeur:ChargeurUse', function()
    ped = GetPlayerPed(-1)
    if IsPedArmed(ped, 4) then
        hash = GetSelectedPedWeapon(ped)
        if hash ~= nil then
            TriggerServerEvent('CorePickax:Chargeur:remove')
            AddAmmoToPed(GetPlayerPed(-1), hash, 25)
            ESX.ShowNotification("Vous avez utilisé un chargeur")
        else
            ESX.ShowNotification("Vous n'avez pas d'arme en main")
        end
    else
        ESX.ShowNotification("Ce type de munition ne convient pas avec votre arme.")
    end
end)