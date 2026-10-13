ESX.RegisterServerCallback('CorePickax:Radio:GetAmountItem', function(source, cb)
    cb(ESX.GetPlayerFromId(source).getInventoryItem(ConfigRadio.Item.NameItem).count)
end)

RegisterNetEvent("CorePickax:Radio:RemoveRadio", function()
    if ESX.GetPlayerFromId(source).getInventoryItem(ConfigRadio.Item.NameItem).count >= 1 then
        RemoveItemOnPlayer(source, ConfigRadio.Item.NameItem, 1)
    end
end)