local ESX = exports["es_extended"]:getSharedObject()

Citizen.CreateThread(function()
    while ESX == nil do
        ESX = exports["es_extended"]:getSharedObject()
        Citizen.Wait(5)
    end
end)

RegisterCommand('smsg', function(source, args)
    local _src = source
    
    local targetId = tonumber(args[1])
    local message = table.concat(args, ' ', 2)
    local xPlayer = ESX.GetPlayerFromId(_src)
    local playerName = xPlayer.getName()
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if xPlayer.getGroup() ~= 'user' then 
        if targetPlayer then
            TriggerClientEvent('admin:bscripts:scaleform', targetId, 'MSG STAFF', message)
        else
            TriggerClientEvent("esx:showNotification", _src, "Joueur ID "..targetId.." introuvable.")
        end
    else
        TriggerClientEvent("esx:showNotification", _src, "Vous n'avez pas la permission d'envoyer ce message.")
    end
end)

-- Nombre de joueurs connectés (affiché dans le HUD)
CreateThread(function()
    GlobalState.pickaxMaxPlayers = GetConvarInt('sv_maxclients', 64)
    while true do
        GlobalState.pickaxPlayers = GetNumPlayerIndices()
        Wait(10000)
    end
end)
