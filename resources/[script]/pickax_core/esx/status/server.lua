AddEventHandler('esx:playerLoaded', function(eventSrc, xPlayer)
	MySQL.Async.fetchAll('SELECT status FROM users WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)
		local data = {}

		if result[1].status ~= nil then
			data = json.decode(result[1].status)
		end

		xPlayer.set('status', data)
		TriggerClientEvent('esx_status:load', eventSrc, data)
	end)
end)

AddEventHandler('esx:playerDropped', function(eventSrc, xPlayer)
	local status = xPlayer.get('status')

	MySQL.Async.execute('UPDATE users SET status = @status WHERE identifier = @identifier', {
		['@status'] = json.encode(status),
		['@identifier'] = xPlayer.identifier
	})
end)

RegisterServerEvent('esx_status:update')
AddEventHandler('esx_status:update', function(status)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer then
		xPlayer.set('status', status)
	end
end)

-- Commands --
RegisterCommand("heal", function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    VerifyToken(source, function()
        if xPlayer.getGroup() ~= 'user' then
			if FetchPlayerStaff then
				if not FetchPlayerStaff(source) then
					TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigTig.Notification["Error9"])
					return
				end
			end
			
			if tonumber(args[1]) then
				local target = tonumber(args[1])
		
				if GetPlayerName(target) then
					TriggerClientEvent('esx_status:healPlayer', target)
					TriggerClientEvent('chatMessage', target, "HEAL", {255, 0, 0}, "Vous avez été heal.")
					if ConfigSV.Logs["LogsHeal"] ~= nil then
						TriggerEvent('esx:customDiscordLog', 'Ambulance', 'Heal', nil, ConfigSV.Logs["LogsHeal"], 'ID : '..source..'\nUtilisateur : '..GetPlayerName(source)..'\nLicense : '..ESX.GetPlayerFromId(source).identifier.."\n\nAction : à heal le joueur **"..GetPlayerName(target).."** [**"..target.."**].")
					end
				else
					TriggerClientEvent('chatMessage', source, "HEAL", {255, 0, 0}, "Player not found!")
				end
			else
				TriggerClientEvent('esx_status:healPlayer', source)
				TriggerClientEvent('chatMessage', source, "HEAL", {255, 0, 0}, "Vous vous êtes heal.")
				if ConfigSV.Logs["LogsHeal"] ~= nil then
					TriggerEvent('esx:customDiscordLog', 'Ambulance', 'Heal', nil, ConfigSV.Logs["LogsHeal"], 'ID : '..source..'\nUtilisateur : '..GetPlayerName(source)..'\nLicense : '..ESX.GetPlayerFromId(source).identifier.."\n\nAction : s'est heal.")
				end
			end
		end
    end)
end)