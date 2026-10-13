Citizen.CreateThread(function()
    if Config.Debug then
        print('ESXCustom : Initialisation Wipe...')
        Wait(1500)
        print('[^5LOAD^0] le Wipe à été load avec succès !')
    end
end)

local Checker = {}
RegisterCommand("Wipe", function(source, args)
    VerifyToken(source, function()
        if GetAdminWipe(source) then
            if args[1] == nil then
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigWipe.Notification["Error5"])
                return
            else
                local playerId = tonumber(args[1])
                local xPlayer = ESX.GetPlayerFromId(playerId)

                if xPlayer == nil then
                    TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigWipe.Notification["Error"])
                    return
                end

                if source == tonumber(args[1]) then
                    TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigWipe.Notification["Error7"])
                    return
                end

                if Checker[playerId] == nil then
                    Checker[playerId] = {}
                    Checker[playerId].source = playerId
                    Checker[playerId].idSource = source
                    Checker[playerId].stats = true
                    TriggerClientEvent("esx_custom:ResetIdentityPlayer", playerId, source)
                else
                    TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigWipe.Notification["Error4"])
                    return
                end
            end
        end
    end)
end)

RegisterServerEvent("esx_custom:ResetIdentityPlayer")
AddEventHandler("esx_custom:ResetIdentityPlayer", function(id, info)
    if Checker[source] ~= nil then
        if GetAdminWipe(id) then
            if info == nil then
                TriggerClientEvent(Config.Trigger.TriggerNotification, id, ConfigWipe.Notification["Good"])
                WipePlayer(source)
            elseif info == false then
                TriggerClientEvent(Config.Trigger.TriggerNotification, id, ConfigWipe.Notification["Error2"])
            elseif info then
                TriggerClientEvent(Config.Trigger.TriggerNotification, id, ConfigWipe.Notification["Error3"])
            end

            Checker[source] = nil
        end
    end
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
	if Checker[playerId] then
        TriggerClientEvent(Config.Trigger.TriggerNotification, Checker[playerId].idSource, ConfigWipe.Notification["Error6"])
		Checker[playerId] = nil
	end
end)

function GetAdminWipe(source)
    for k, v in pairs(ConfigWipe.adminGroup) do
        if ESX.GetPlayerFromId(source).getGroup() == v then
            return true
        end

        return false
    end
end