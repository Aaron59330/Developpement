if Config.Snow == true then
    RegisterNetEvent('CorePickax:Neige:giveSnowball')
    AddEventHandler('CorePickax:Neige:giveSnowball', function()
        local xPlayer = ESX.GetPlayerFromId(source)
        local item = xPlayer.getInventoryItem('snowball').count
        if item > 10 then return end
        xPlayer.addInventoryItem('snowball', 1)
    end)

    ESX.RegisterUsableItem('snow_chain', function(source)
        TriggerClientEvent('CorePickax:Neige:toggleSnowChain', source)
    end)

    AddEventHandler('esx:onRemoveInventoryItem', function(source, item, count)
        if item.name == 'snow_chain' and item.count <= 0 then
            TriggerClientEvent('CorePickax:Neige:forceSnowChain', source, true)
        end
    end)

    AddEventHandler('weaponDamageEvent', function(source, data)
        if data.weaponType == `WEAPON_SNOWBALL` or data.weaponType == `AMMO_SNOWBALL` then CancelEvent() end
    end)
end