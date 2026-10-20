local ESX = exports['es_extended']:getSharedObject()

ESX.RegisterServerCallback('pickax_weaponcarry:isDev', function(src, cb)
    local x = ESX.GetPlayerFromId(src)
    cb(x ~= nil and Config.DevGroups[x.getGroup()] == true)
end)
