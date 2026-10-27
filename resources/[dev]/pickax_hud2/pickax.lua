-- [AERO:LIC] contrôle de licence via pickax_core (qui vérifie lui-même la signature du panel) : ne pas retirer
do
    local res = GetCurrentResourceName()
    -- true / false ; nil = pickax_core n'a pas encore fini sa vérification
    local function lic() local good, v = pcall(function() return exports.pickax_core:Licensed() end) if good then return v end end
    local function die(why) print(('^1[AERO] %s arrêtée : %s^0'):format(res, why)) StopResource(res) end
    if GetResourceState('pickax_core') == 'started' and lic() == false then die('licence invalide (pickax_core)') error('AERO : licence invalide', 0) end
    CreateThread(function()
        local tries = 0
        while true do
            local v = lic()
            if v == true then break end
            tries = tries + 1
            if v == false or tries > 30 then die(v == false and 'licence invalide (pickax_core)' or 'pickax_core absent ou licence non vérifiée') return end
            Wait(2000)
        end
        while true do
            Wait(240000 + math.random(0, 120000))
            local good = false
            for _ = 1, 4 do if lic() == true then good = true break end Wait(10000) end
            if not good then die('licence invalide') return end
        end
    end)
end
-- [/AERO:LIC]

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
