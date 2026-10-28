local playersInJail = {}
AddEventHandler('esx:playerLoaded', function(source, xPlayer)
	MySQL.Async.fetchAll('SELECT * FROM jail WHERE identifier = @identifier', {
		["@identifier"] = ESX.GetPlayerFromId(source).identifier
	}, function(result)
		if result[1] and result[1].temps > 0 then
			playersInJail[ESX.GetPlayerFromId(source).identifier] = {name = GetPlayerName(source), id = source, temps = result[1].temps, identifier = result[1].identifier, identifiersource = result[1].identifiersource, source = result[1].source, reason = result[1].reason}
			SetPedJail(source)
			TriggerClientEvent("CorePickax:SetJail", source, playersInJail[ESX.GetPlayerFromId(source).identifier].temps, playersInJail[ESX.GetPlayerFromId(source).identifier].source, playersInJail[ESX.GetPlayerFromId(source).identifier].reason)
			SetEntityCoords(GetPlayerPed(source), ConfigJail.LieuJail.x, ConfigJail.LieuJail.y, ConfigJail.LieuJail.z)
			TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigJail.Notification["SetJailAfterConnexion"])
		end
	end)
end)

AddEventHandler('esx:playerDropped', function(source, reason)
	if playersInJail[ESX.GetPlayerFromId(source).identifier] ~= nil then
		MySQL.Async.fetchAll('SELECT * FROM jail WHERE identifier = @identifier', {
			["@identifier"] = ESX.GetPlayerFromId(source).identifier
		}, function(result)
			if result[1] and result[1].temps > 0 then
				MySQL.Async.execute('UPDATE jail SET temps = @temps WHERE identifier = @identifier', {
					['@identifier'] = ESX.GetPlayerFromId(source).identifier,
					['@temps'] = playersInJail[ESX.GetPlayerFromId(source).identifier].temps
				})
			else
				MySQL.Async.execute("INSERT INTO jail (source, identifiersource, temps, reason, identifier) VALUES (@source, @identifiersource, @temps, @reason, @identifier);", {
						['source'] = playersInJail[ESX.GetPlayerFromId(source).identifier].source,
						['identifiersource'] = playersInJail[ESX.GetPlayerFromId(source).identifier].identifiersource,
						['temps'] = playersInJail[ESX.GetPlayerFromId(source).identifier].temps,
						['reason'] = playersInJail[ESX.GetPlayerFromId(source).identifier].reason,
						['identifier'] = ESX.GetPlayerFromId(source).identifier
					}, function(rowsChanged)
				end)
			end
			playersInJail[ESX.GetPlayerFromId(source).identifier] = nil
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM jail WHERE identifier = @identifier', {
			["@identifier"] = ESX.GetPlayerFromId(source).identifier
		}, function(result)
			if result[1] and result[1].temps > 0 then
				MySQL.Async.execute("DELETE FROM jail WHERE identifier = @identifier", {
					["@identifier"] = result[1].identifier
				})
			end
		end)
	end
end)

CreateThread(function()
	while true do
		Citizen.Wait(1000)

		for playerId, data in pairs(playersInJail) do
			if playersInJail[playerId].temps >= 0 then
				if #(GetEntityCoords(GetPlayerPed(playersInJail[playerId].id)) - vector3(ConfigJail.LieuJail)) > 10 then
					SetEntityCoords(GetPlayerPed(playersInJail[playerId].id), vector3(ConfigJail.LieuJail))
					TriggerClientEvent(Config.Trigger.TriggerNotification, playersInJail[playerId].id, ConfigJail.Notification["CantFleePrison"])
				end

				playersInJail[playerId].temps = playersInJail[playerId].temps - 1

				if playersInJail[playerId].temps == 0 then
					TriggerEvent('esx:customDiscordLog', ConfigSV.Logs["JailLogs"].Nom, ConfigSV.Logs["JailLogs"].Title, nil, ConfigSV.Logs["JailLogs"].Webhook, (ConfigJail.Notification["LogsFinishJail"]):format(GetPlayerName(playersInJail[playerId].id)))
					unjailPlayer(playersInJail[playerId].id)
				end
			end
		end
	end
end)

ESXCustomServerUtils.registerCommand(ConfigJail.Commande.jail, function(source, args)
	local source = source
	local xPlayerSource = ESX.GetPlayerFromId(source)
	local author = GetPlayerName(source)

	if CheckPermission(xPlayerSource) then
		if args[1] == nil then
			TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayerSource.source, ConfigJail.Notification["Error1"])
			return
		end

		if args[2] == nil then
			TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayerSource.source, ConfigJail.Notification["Error2"])
			return
		end

		if args[3] == nil then
			TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayerSource.source, ConfigJail.Notification["Error3"])
			return
		end

		local playerId = args[1]
		local xPlayer = ESX.GetPlayerFromId(playerId)
		local jailTime = args[2] * 60
		local reason = ""

		for i=3, #args do
			reason = reason .. args[i] .. " "
		end

		if #reason > 25 then
			reason = reason:sub(1, 25) .. "..."
		end

		if xPlayer == nil then
			TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayerSource.source, ConfigJail.Notification["Error4"])
			return
		end

		-- if source == tonumber(args[1]) then
		-- 	TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayerSource.source, ConfigJail.Notification["Error5"])
		-- 	return
		-- end

		if playersInJail[xPlayer.identifier] ~= nil then
			TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayerSource.source, ConfigJail.Notification["Error6"])
			return
		end

		if jailTime > ConfigJail.MaxJail*60 then
			TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayerSource.source, ConfigJail.Notification["Error7"])
			return
		end

		if 1*60 > jailTime then
			TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayerSource.source, ConfigJail.Notification["Error8"])
			return
		end

		if xPlayer then
			if jailTime <= ConfigJail.MaxJail*60 then
				if not playersInJail[xPlayer.identifier] then
					SetPedJail(playerId)
					TriggerClientEvent("CorePickax:SetJail", playerId, jailTime, author, reason)
					TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayerSource.source, (ConfigJail.Notification["UJail"]):format(playerId))
					TriggerEvent('esx:customDiscordLog', ConfigSV.Logs["JailLogs"].Nom, ConfigSV.Logs["JailLogs"].Title, nil, ConfigSV.Logs["JailLogs"].Webhook, (ConfigJail.Notification["LogsJail"]):format(GetPlayerName(xPlayerSource.source), GetPlayerName(playerId), formatDuration(jailTime), reason))
					playersInJail[xPlayer.identifier] = {name = GetPlayerName(playerId), id = playerId, temps = jailTime, identifier = xPlayer.getIdentifier(), identifiersource = xPlayerSource.getIdentifier(), source = author, reason = reason}
				end
			else
				TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayerSource.source, ConfigJail.Notification["Error7"])
			end
		end
	end
end)

ESXCustomServerUtils.registerCommand(ConfigJail.Commande.unjail, function(source, args)
	local source = source
	local xPlayerSource = ESX.GetPlayerFromId(source)
	local author = GetPlayerName(source)

	if CheckPermission(xPlayerSource) then
		if args[1] == nil then
			TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayerSource.source, ConfigJail.Notification["Error1"])
			return
		end

		local playerId = args[1]
		local xPlayer = ESX.GetPlayerFromId(playerId)

		if xPlayer == nil then
			TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayerSource.source, ConfigJail.Notification["Error4"])
			return
		end

		if playersInJail[xPlayer.identifier] == nil then
			TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayerSource.source, ConfigJail.Notification["Error9"])
			return
		end

		if xPlayer then
			unjailPlayer(playerId)
			TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayerSource.source, (ConfigJail.Notification["Uunjail"]):format(playerId))
			TriggerEvent('esx:customDiscordLog', ConfigSV.Logs["JailLogs"].Nom, ConfigSV.Logs["JailLogs"].Title, nil, ConfigSV.Logs["JailLogs"].Webhook, (ConfigJail.Notification["LogsUnjail"]):format(GetPlayerName(xPlayerSource.source), GetPlayerName(playerId)))
		end
	end
end)

ESXCustomServerUtils.registerCommand(ConfigJail.Commande.OpenMenu, function(source, args)
	local source = source
	local xPlayerSource = ESX.GetPlayerFromId(source)
	if CheckPermission(xPlayerSource) then
		TriggerClientEvent("CorePickax:OpenMenuGestionJail", source)
	end
end)

function unjailPlayer(playerId)
	local xPlayer = ESX.GetPlayerFromId(playerId)
	
	if xPlayer then
		if playersInJail[xPlayer.identifier] then
			AddonToUnJailFunction(playerId)
			TriggerClientEvent('CorePickax:unjailPlayer', playerId)
			TriggerClientEvent(Config.Trigger.TriggerNotification, playerId, ConfigJail.Notification["MessageSendAfterUnjail"])
			SetEntityCoords(GetPlayerPed(playerId), ConfigJail.LieuUnJail.x, ConfigJail.LieuUnJail.y, ConfigJail.LieuUnJail.z)
			playersInJail[xPlayer.identifier] = nil
		end
	end
end

function SetPedJail(playerId)
	AddonToSetPedInJail(playerId)
	SetEntityCoords(GetPlayerPed(playerId), ConfigJail.LieuJail.x, ConfigJail.LieuJail.y, ConfigJail.LieuJail.z)
end

-- ─────────── API pour les autres ressources (pickax_illegalbuilder : peines de police, travaux qui réduisent la peine) ───────────
-- Même prison, même tenue, même minuteur que la commande du staff : pas de second système.
exports('JailPlayer', function(playerId, seconds, authorName, reason, officerId)
	local xPlayer = ESX.GetPlayerFromId(playerId)
	if not xPlayer then return false, 'Le joueur n\'est pas sur le serveur.' end
	if playersInJail[xPlayer.identifier] then return false, 'Le joueur est déjà en jail.' end
	seconds = math.floor(tonumber(seconds) or 0)
	seconds = math.max(60, math.min(seconds, (ConfigJail.MaxJailPolice or ConfigJail.MaxJail) * 60))
	local officer = officerId and ESX.GetPlayerFromId(officerId)
	reason = tostring(reason or ''):sub(1, 25)
	SetPedJail(playerId)
	TriggerClientEvent("CorePickax:SetJail", playerId, seconds, authorName or 'Police', reason)
	playersInJail[xPlayer.identifier] = {name = GetPlayerName(playerId), id = playerId, temps = seconds, identifier = xPlayer.getIdentifier(), identifiersource = officer and officer.getIdentifier() or xPlayer.getIdentifier(), source = authorName or 'Police', reason = reason}
	return true, seconds
end)

-- Secondes restantes de la peine (0 si le joueur n'est pas en jail)
exports('JailTimeLeft', function(playerId)
	local xPlayer = ESX.GetPlayerFromId(playerId)
	local j = xPlayer and playersInJail[xPlayer.identifier]
	return j and j.temps or 0
end)

-- Retire des secondes à la peine (travail en prison) ; renvoie les secondes restantes
exports('ReduceJail', function(playerId, seconds)
	local xPlayer = ESX.GetPlayerFromId(playerId)
	local j = xPlayer and playersInJail[xPlayer.identifier]
	if not j then return 0 end
	j.temps = math.max(1, j.temps - math.max(0, math.floor(tonumber(seconds) or 0)))
	TriggerClientEvent("CorePickax:JailReduce", playerId, j.temps)
	return j.temps
end)

-- Évasion : le joueur n'est plus retenu par la prison ; renvoie les secondes de peine qu'il lui restait (la ressource appelante les garde pour l'arrestation suivante)
exports('EscapePlayer', function(playerId)
	local xPlayer = ESX.GetPlayerFromId(playerId)
	local j = xPlayer and playersInJail[xPlayer.identifier]
	if not j then return nil end
	local left = j.temps
	playersInJail[xPlayer.identifier] = nil
	TriggerClientEvent('CorePickax:unjailPlayer', playerId)
	return left
end)

exports('UnjailPlayer', function(playerId)
	local xPlayer = ESX.GetPlayerFromId(playerId)
	if not xPlayer or not playersInJail[xPlayer.identifier] then return false end
	unjailPlayer(playerId)
	return true
end)

RegisterNetEvent("CorePickax:SendServerSideJail", function()--Send to client side
	TriggerClientEvent("CorePickax:AddClientSideJail", source, playersInJail)
end)

function CheckPermission(xPlayer)
	for k,v in pairs(ConfigJail.adminRanks) do
		if v == xPlayer.getGroup() then
			return true
		end
	end

	return false
end

--discord.gg/votreinvite

--GetTimer
function formatDuration(milliseconds)
	local milliseconds = tonumber(milliseconds)
    local totalSeconds = milliseconds
    local minutes = math.floor(totalSeconds / 60)
    local seconds = math.floor(totalSeconds % 60)
    return string.format("%02d:%02d", minutes, seconds)
end