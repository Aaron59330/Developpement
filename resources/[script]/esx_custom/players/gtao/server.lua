ESX.RegisterServerCallback('gtaOHud:GetAccountData', function(src, cb)
    cb({money = GetMoney(src), bank = GetMoneyBanque(src)})
end)

AddEventHandler('esx:playerLoaded', function(playerId)
    TriggerClientEvent("ESXCustomGTAO:ReloadHUD", playerId)
end)