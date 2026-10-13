AddEventHandler('es:invalidCommandHandler', function(source, command_args, user)
	CancelEvent()
	TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', ('^3%s^0 n\'est pas une commande valide!'):format(command_args[1]) } })
end)

AddEventHandler('chatMessage', function(source, name, message)
	local name = GetPlayerName(source)
	if string.sub(message, 1, string.len('/')) ~= '/' then
		CancelEvent()
	end
end)

if ConfigChat.AllowTWT then
	ESXCustomServerUtils.registerCommand('twt', function(source, args, rawCommand)
		local src = source
		local msg = rawCommand:sub(5)
		local args = msg
		local nameplayer = GetPlayerName(source)
		local name = GetPlayerName(source)
		local RealName = ESX.GetPlayerFromId(src).getName()
		if player ~= false then
			local xPlayers	= ESX.GetPlayers()
			for i=1, #xPlayers, 1 do
				local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
				TriggerClientEvent(Config.Trigger.TriggerAdvancedNotification, xPlayers[i], 'Twitter', ''..RealName..'', ''..msg..'', 'CHAR_STRETCH', 0)
			end
		end
	end, false)
end

if ConfigChat.AllowANO then
	ESXCustomServerUtils.registerCommand('ano', function(source, args, rawCommand)
		local src = source
		local msg = rawCommand:sub(5)
		local args = msg
		local nameplayer = GetPlayerName(source)
		if player ~= false then
			local name = GetPlayerName(source)
			local xPlayers	= ESX.GetPlayers()
			for i=1, #xPlayers, 1 do
				local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
				TriggerClientEvent(Config.Trigger.TriggerAdvancedNotification, xPlayers[i], 'Twitter', 'Anonyme', ''..msg..'', 'CHAR_STRETCH', 0)
			end
		end
	end, false)
end