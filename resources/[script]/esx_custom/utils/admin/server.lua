for k, v in pairs(ConfigAdmin.Commande) do
    ESXCustomServerUtils.registerCommand(v.commande, function(source, args)
        for z, o in pairs(v.groupAcces) do
            if ESX.GetPlayerFromId(source).getGroup() == o then
                v.IsUsed(source, args)
            end
        end
    end)
end

function HealPlayer(source, args)
    if args[1] ~= nil then
        if GetPlayerName(tonumber(args[1])) ~= nil then
            TriggerClientEvent('esx_status:healPlayer', tonumber(args[1]))
            TriggerClientEvent(Config.Trigger.TriggerNotification, args[1], "Vous avez été heal par un staff.")
        end
    else
        TriggerClientEvent('esx_status:healPlayer', source)
        TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous avez été heal par vous même.")
    end
end

function TeleportMarker(source, args)
    TriggerClientEvent('esx_custom:TPM', source)
end

RegisterCommand("setgroup", function(source, args)
	if source == 0 then
		if args[1] == nil then
			print("Merci de définir un bon ID")
			return
		elseif args[2] == nil then
			print("Merci de définir un bon group")
			return
		end

        local xPlayer = ESX.GetPlayerFromId(args[1])
        if (tonumber(args[1]) ~= nil and tonumber(args[1]) >= 0) and (tostring(args[2]) ~= nil) then
            local xPlayer = ESX.GetPlayerFromId(tonumber(args[1]))
    
            if xPlayer == nil then
                print('Le joueur n\'est pas connecté')
                CancelEvent()
                return
            end
    
            if tostring(args[2]) == "_dev" or tostring(args[2]) == "superadmin" or tostring(args[2]) == "admin" or tostring(args[2]) == "user" then
            else
                print('Le nom du groupe est incorrect.')
                CancelEvent()
                return
            end
    
            TriggerEvent('esx:customDiscordLog', 'Logs SetGroup', 'Nouveau group', nil, ConfigSV.Logs["LogsSetGroup"], "ID : **Console**\nUtilisateur : **Console**\nLicense : **Console**\nAction : à modifier le group d\'un joueur.\n\nInformations du joueur :\nID : **"..tonumber(args[1]).."**\nUtilisateur : **"..GetPlayerName(tonumber(args[1])).."**\nLicense : **"..ESX.GetPlayerFromId(tonumber(args[1])).identifier.."**\nAncien groupe : **"..xPlayer.getGroup().."**\nNouveau groupe : **"..tostring(args[2]).."**")
            xPlayer.setGroup(tostring(args[2]))
        else
            print('/setgroup [user-id] [group]')
            CancelEvent()
            return
        end
    else
        if ESX.GetPlayerFromId(source).getGroup() == "superadmin" or ESX.GetPlayerFromId(source).getGroup() == "_dev" then
            local xPlayer = ESX.GetPlayerFromId(args[1])
            if (tonumber(args[1]) ~= nil and tonumber(args[1]) >= 0) and (tostring(args[2]) ~= nil) then
                local xPlayer = ESX.GetPlayerFromId(tonumber(args[1]))
        
                if xPlayer == nil then
                    TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'Le joueur n\'est pas connecté')
                    CancelEvent()
                    return
                end
        
                if tostring(args[2]) == "superadmin" or tostring(args[2]) == "admin" or tostring(args[2]) == "user" then
                else
                    TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'Le nom du groupe est incorrect.')
                    CancelEvent()
                    return
                end
        
                TriggerEvent('esx:customDiscordLog', 'Logs SetGroup', 'Nouveau group', nil, ConfigSV.Logs["LogsSetGroup"], 'ID : **'..source..'**\nUtilisateur : **'..GetPlayerName(source)..'**\nLicense : **'..ESX.GetPlayerFromId(source).identifier.."**\nAction : à modifier le group d'un joueur.\n\nInformations du joueur :\nID : **"..tonumber(args[1]).."**\nUtilisateur : **"..GetPlayerName(tonumber(args[1])).."**\nLicense : **"..ESX.GetPlayerFromId(tonumber(args[1])).identifier.."**\nAncien groupe : **"..xPlayer.getGroup().."**\nNouveau groupe : **"..tostring(args[2]).."**")
                xPlayer.setGroup(tostring(args[2]))
            else
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'Aide : /setgroup [user-id] [group].')
                CancelEvent()
                return
            end
        end
	end
end)