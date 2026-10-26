-- Réglages « Nouveaux joueurs » (panel web → Réglages) : message de bienvenue et argent bonus à la création du personnage.
-- Rien ne s'exécute tant que ces réglages ne sont pas modifiés.
AddEventHandler('esx:playerLoaded', function(src, xPlayer, isNew)
    local msg = Settings.Get('welcome_message')
    if type(msg) == 'string' and msg ~= '' then
        local name = xPlayer and xPlayer.getName and xPlayer.getName() or GetPlayerName(src) or ''
        SetTimeout(6000, function() TriggerClientEvent('esx:showNotification', src, (msg:gsub('{nom}', (name:gsub('%%', '%%%%'))))) end)
    end
    local bonus = math.floor(tonumber(Settings.Get('start_money')) or 0)
    if isNew and bonus > 0 and xPlayer then
        xPlayer.addAccountMoney('bank', bonus, 'Bonus de bienvenue')
        SetTimeout(7000, function() TriggerClientEvent('esx:showNotification', src, ('~g~Bonus de bienvenue~s~ : +%d $ sur ton compte bancaire'):format(bonus)) end)
    end
end)
