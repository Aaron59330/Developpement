sqlReady = false

MySQL.ready(function()
	sqlReady = true
end)

AddEventHandler('playerConnecting', function()
	local _source = source
	local license, steam, xbl, discord, live, fivem = '', '', '', '', '', ''
	local name, ip, guid = GetPlayerName(_source), GetPlayerEP(_source), GetPlayerGuid(_source)

	while not sqlReady do
		Citizen.Wait(100)
	end

	for k, v in pairs(GetPlayerIdentifiers(_source)) do
		if string.sub(v, 1, string.len('license:')) == 'license:' then
			license = v
		elseif string.sub(v, 1, string.len('steam:')) == 'steam:' then
			steam = v
		elseif string.sub(v, 1, string.len('xbl:')) == 'xbl:' then
			xbl = v
		elseif string.sub(v, 1, string.len('discord:')) == 'discord:' then
			discord = v
		elseif string.sub(v, 1, string.len('live:')) == 'live:' then
			live = v
		elseif string.sub(v, 1, string.len('fivem:')) == 'fivem:' then
			fivem = v
		end
	end

	if license ~= nil then
		MySQL.Async.fetchAll('SELECT * FROM account_info WHERE license = @license', {
			['@license'] = license
		}, function(result)
			if result[1] ~= nil then
				MySQL.Async.execute('UPDATE account_info SET steam = @steam, xbl = @xbl, discord = @discord, live = @live, fivem = @fivem, `name` = @name, ip = @ip, guid = @guid WHERE license = @license', {
					['@license'] = license,
					['@steam'] = steam,
					['@xbl'] = xbl,
					['@discord'] = discord,
					['@live'] = live,
					['@fivem'] = fivem,
					['@name'] = name,
					['@ip'] = ip,
					['@guid'] = guid
				})
			else
				MySQL.Async.execute('INSERT INTO account_info (license, steam, xbl, discord, live, fivem, `name`, ip, guid) VALUES (@license, @steam, @xbl, @discord, @live, @fivem, @name, @ip, @guid)', {
					['@license'] = license,
					['@steam'] = steam,
					['@xbl'] = xbl,
					['@discord'] = discord,
					['@live'] = live,
					['@fivem'] = fivem,
					['@name'] = name,
					['@ip'] = ip,
					['@guid'] = guid
				})
			end
		end)
	end
end)

Citizen.CreateThread(function()--Ajout des informations au cache
    if Config.Debug then
        Wait(500)
        print('ESXCustom : Initialisation des bannissements ...')
    end
	Wait(1500)
	MySQL.Async.fetchAll('SELECT * FROM banlist', {}, function(InfoReceive)
        if InfoReceive ~= nil then
            if Config.Debug then
				print('[^5LOAD^0] [^5'..#InfoReceive..'^0] bannissements, la banList à été load avec succès !')
            end
        end
    end)
end)

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
	local _source = source
	local licenseid, playerip = 'N/A', 'N/A'
	licenseid = ESX.GetIdentifierFromId(_source, 'license:')
	--playerip = GetPlayerEndpoint(_source)

	if not licenseid then
		setKickReason(ConfigBan.Locale.invalididentifier)
		CancelEvent()
	end

	deferrals.defer()
	Citizen.Wait(0)
	deferrals.update(('Vérification de %s en cours...'):format(playerName))
	Citizen.Wait(0)

	IsBanned(licenseid, function(isBanned, banData)
		if isBanned then

			if tonumber(banData.permanent) == 1 then
				deferrals.done(('Vous êtes banni\nRaison : %s\nTemps Restant : Permanent\nAuteur : %s\nBan ID : %s'):format(banData.reason, banData.sourceName, banData.banid))
				TriggerEvent('esx:customDiscordLog', 'Ban Info', ('Tentative de Connexion du Joueur : %s (%s)\nRaison : %s\nTemps Restant : Permanent\nAuteur : %s\nBan ID : %s'):format(playerName, licenseid, banData.reason, banData.sourceName, banData.banid), nil, ConfigSV.Logs["TentativedeCOBan"])
			else
				if tonumber(banData.expiration) > os.time() then
					local timeRemaining = tonumber(banData.expiration) - os.time()
					deferrals.done(('Vous êtes banni\nRaison : %s\nTemps Restant : %s\nAuteur : %s\nBan ID : %s'):format(banData.reason, SexyTime(timeRemaining), banData.sourceName, banData.banid))
					TriggerEvent('esx:customDiscordLog', 'Ban Info', ('Tentative de Connexion du Joueur : %s (%s)\nRaison : %s\nTemps Restant : %s\nAuteur : %s\nBan ID : %s'):format(playerName, licenseid, banData.reason, SexyTime(timeRemaining), banData.sourceName, banData.banid), nil, ConfigSV.Logs["TentativedeCOBan"])
				else
					DeleteBan(banData.banid)
					deferrals.done()
				end
			end
		else
			deferrals.done()
		end
	end)
end)

RegisterServerEvent('BanSql:ICheatClient')
AddEventHandler('BanSql:ICheatClient', function(reason)
	local _source = source
	local licenseid, playerip = 'N/A', 'N/A'

	if reason == nil then
		reason = 'Cheat'
	end

	if _source then
		local name = GetPlayerName(_source)

		if name then
			licenseid = ESX.GetIdentifierFromId(_source, 'license:')
			--playerip = GetPlayerEndpoint(_source)

			if not licenseid then
				licenseid = 'N/A'
			end

			AddBan(_source, licenseid, playerip, name, 'Anti-Cheat', 0, reason, 1, ESX.GetPlayerFromId(_source).boutique_id)
			DropPlayer(_source, ('Vous êtes banni\nRaison : %s\nTemps Restant : Permanent\nAuteur : Anti-Cheat'):format(reason))
		end
	else
		print('BanSql Error : Anti-Cheat have received invalid id.')
	end
end)

AddEventHandler('BanSql:ICheatServer', function(target, reason)
	local licenseid, playerip = 'N/A', 'N/A'

	if reason == nil then
		reason = 'Cheat'
	end

	if target then
		local name = GetPlayerName(target)

		if name then
			licenseid = ESX.GetIdentifierFromId(target, 'license:')
			--playerip = GetPlayerEndpoint(_source)

			if not licenseid then
				licenseid = 'N/A'
			end

			AddBan(target, licenseid, playerip, name, 'Anti-Cheat', 0, reason, 1, ESX.GetPlayerFromId(target).boutique_id)
			DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : Permanent\nAuteur : Anti-Cheat'):format(reason))
		end
	else
		print('BanSql Error : Anti-Cheat have received invalid id.')
	end
end)

AddEventHandler('Ban:ServerSide', function(reason)
	local target = source
	local licenseid, playerip = 'N/A', 'N/A'

	if reason == nil then
		reason = 'Cheat'
	end

	if target then
		local name = GetPlayerName(target)

		if name then
			licenseid = ESX.GetIdentifierFromId(target, 'license:')
			--playerip = GetPlayerEndpoint(_source)

			if not licenseid then
				licenseid = 'N/A'
			end

			AddBan(target, licenseid, playerip, name, 'Anti-Cheat', 0, reason, 1, ESX.GetPlayerFromId(target).boutique_id)
			DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : Permanent\nAuteur : Anti-Cheat'):format(reason))
		end
	else
		print('BanSql Error : Anti-Cheat have received invalid id.')
	end
end)

ESXCustomServerUtils.BanPlayer = function(source, target, reason, time)
	local licenseid, playerip = 'N/A', 'N/A'
	local target = tonumber(target)
	local xTarget = ESX.GetPlayerFromId(target)

	-- if target and target > 0 then
	-- 	local targetName = GetPlayerName(target)

	-- 	if targetName then
	-- 		if expiration ~= nil then
	-- 			licenseid = xTarget.identifier

	-- 			if not licenseid then
	-- 				licenseid = 'N/A'
	-- 			end

	-- 			if reason == '' then
	-- 				reason = ConfigBan.Locale.noreason
	-- 			end

	-- 			if expiration > 0 then
	-- 				AddBan(target, licenseid, playerip, targetName, NameStaff, expiration, reason, 0, xTarget.boutique_id)
	-- 				DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : %s\nAuteur : %s\nBan ID : %s'):format(reason, SexyTime(expiration), NameStaff, xTarget.boutique_id))
	-- 			else
	-- 				AddBan(target, licenseid, playerip, targetName, NameStaff, expiration, reason, 1, xTarget.boutique_id)
	-- 				DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : Permanent\nAuteur : %s\nBan ID : %s'):format(reason, NameStaff, xTarget.boutique_id))
	-- 			end
	-- 		end
	-- 	end
	-- end
	local duration = time
	local expiration, unit = duration:match('(%d+)(%a+)') -- Extract numeric value and unit (e.g., 2 and 'h')
	-- local reason = table.concat(args, ' ', 3)

	if target and target > 0 then
		local sourceName = GetPlayerName(source)
		local targetName = GetPlayerName(target)

		local banid = xTarget.boutique_id
		if targetName then
			-- if expiration and expiration <= 336 then
			if expiration and tonumber(expiration) or duration ~= nil then
				licenseid = ESX.GetIdentifierFromId(target, 'license:')

				if not licenseid then
					licenseid = 'N/A'
				end

				if reason == '' then
					reason = ConfigBan.Locale.noreason
				end

				if duration ~= -1 and tonumber(expiration) ~= nil and tonumber(expiration) > 0 then
					if unit and unit:lower() == 'm' then
						AddBan(target, licenseid, playerip, targetName, sourceName, expiration * 60, reason, 0, banid)
						DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : %s\nAuteur : %s\nBan ID : %s'):format(reason, SexyTime(expiration * 60), sourceName, banid))
					elseif unit and unit:lower() == 'h' then
						AddBan(target, licenseid, playerip, targetName, sourceName, expiration * 3600, reason, 0, banid)
						DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : %s\nAuteur : %s\nBan ID : %s'):format(reason, SexyTime(expiration * 3600), sourceName, banid))
					elseif unit and unit:lower() == 'd' then
						AddBan(target, licenseid, playerip, targetName, sourceName, expiration* 3600 * 24, reason, 0, banid)
						DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : %s\nAuteur : %s\nBan ID : %s'):format(reason, SexyTime(expiration * 3600 * 24), sourceName, banid))
					end
				else
					AddBan(target, licenseid, playerip, targetName, sourceName, duration, reason, 1, banid)
					DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : Permanent\nAuteur : %s\nBan ID : %s'):format(reason, sourceName, banid))
				end
			else
				SendMessage(source, ConfigBan.Locale.invalidtime)
			end
		else
			SendMessage(source, ConfigBan.Locale.invalidid)
		end
	else
		SendMessage(source, ConfigBan.Locale.invalidid)
	end
end

-- AddEventHandler('BanSql:IServer', function(target, reason, time)
-- 	local licenseid, playerip = 'N/A', 'N/A'
-- 	local target = tonumber(target)
-- 	local expiration = tonumber(time)
-- 	local reason = table.concat(reason, ' ', 3)

-- 	if target and target > 0 then
-- 		local sourceName = GetPlayerName(source)
-- 		local targetName = GetPlayerName(target)

-- 		if targetName then
-- 			if expiration and expiration <= 336 then
-- 				licenseid = ESX.GetIdentifierFromId(target, 'license:')

-- 				if not licenseid then
-- 					licenseid = 'N/A'
-- 				end

-- 				if reason == '' then
-- 					reason = ConfigBan.Locale.noreason
-- 				end

-- 				if expiration > 0 then
-- 					AddBan(source, licenseid, playerip, targetName, sourceName, expiration, reason, 0, ESX.GetPlayerFromId(target).boutique_id)
-- 					DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : %s\nAuteur : %s'):format(reason, SexyTime(expiration * 3600), sourceName))
-- 				else
-- 					AddBan(source, licenseid, playerip, targetName, sourceName, expiration, reason, 1, ESX.GetPlayerFromId(target).boutique_id)
-- 					DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : Permanent\nAuteur : %s'):format(reason, sourceName))
-- 				end
-- 			else
-- 				SendMessage(source, ConfigBan.Locale.invalidtime)
-- 			end
-- 		else
-- 			SendMessage(source, ConfigBan.Locale.invalidid)
-- 		end
-- 	else
-- 		SendMessage(source, ConfigBan.Locale.invalidid)
-- 	end
-- end)

AddEventHandler('BanSql:ICheatServer', function(target, reason, time)
	local licenseid, playerip = 'N/A', 'N/A'
	local target = tonumber(target)

	if target and target > 0 then
		local sourceName = "AntiCheat"
		local targetName = GetPlayerName(target)

		if ESX.GetPlayerFromId(target) == nil then
			SendMessage(source, ConfigBan.Locale.invalidPlayer)
			return
		end

		local banid = ESX.GetPlayerFromId(target).boutique_id
		if targetName then
			AddBan(source, licenseid, playerip, targetName, sourceName, duration, reason, 1, banid)
			DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : Permanent\nAuteur : %s\nBan ID : %s'):format(reason, sourceName, banid))
		else
			SendMessage(source, ConfigBan.Locale.invalidid)
		end
	else
		SendMessage(source, ConfigBan.Locale.invalidid)
	end
end)

function SexyTime(seconds)
	local days = seconds / 86400
	local hours = (days - math.floor(days)) * 24
	local minutes = (hours - math.floor(hours)) * 60
	seconds = (minutes - math.floor(minutes)) * 60
	return ('%s jours %s heures %s minutes %s secondes'):format(math.floor(days), math.floor(hours), math.floor(minutes), math.floor(seconds))
end

function SendMessage(source, message)
	if source ~= 0 then
		TriggerClientEvent('chat:addMessage', source, { args = {'^1BanInfo ', message} })
	else
		print(('SqlBan: %s'):format(message))
	end
end

function AddBan(source, licenseid, playerip, targetName, sourceName, time, reason, permanent, banid)
	local timeat = os.time()
	local expiration = time + timeat

	MySQL.Async.execute('INSERT INTO banlist (licenseid, playerip, targetName, sourceName, reason, timeat, expiration, permanent, banid) VALUES (@licenseid, @playerip, @targetName, @sourceName, @reason, @timeat, @expiration, @permanent, @banid)', {
		['@licenseid'] = licenseid,
		['@playerip'] = playerip,
		['@targetName'] = targetName,
		['@sourceName'] = sourceName,
		['@reason'] = reason,
		['@timeat'] = timeat,
		['@expiration'] = expiration,
		['@permanent'] = permanent,
		['@banid'] = banid
	}, function()
		MySQL.Async.execute('INSERT INTO banlisthistory (licenseid, playerip, targetName, sourceName, reason, timeat, expiration, permanent, banid) VALUES (@licenseid, @playerip, @targetName, @sourceName, @reason, @timeat, @expiration, @permanent, @banid)', {
			['@licenseid'] = licenseid,
			['@playerip'] = playerip,
			['@targetName'] = targetName,
			['@sourceName'] = sourceName,
			['@reason'] = reason,
			['@timeat'] = timeat,
			['@expiration'] = expiration,
			['@permanent'] = permanent,
			['@banid'] = banid
		})

		if permanent == 0 then
			SendMessage(source, (('Vous avez banni %s / Durée : %s / Raison : %s / Ban ID : %s'):format(targetName, SexyTime(time), reason, banid)))
			TriggerEvent('esx:customDiscordLog', 'Ban Info', ('`%s` a banni `%s` / Durée : `%s` / Raison : `%s` / Ban ID : `%s`\n / License : `%s`'):format(sourceName, targetName, SexyTime(time), reason, banid, licenseid), nil, ConfigSV.Logs["Ban"])
		else
			SendMessage(source, (('Vous avez banni %s / Durée : Permanent / Raison : %s / Ban ID : %s'):format(targetName, reason, banid)))
			TriggerEvent('esx:customDiscordLog', 'Ban Info', ('`%s` a banni `%s` / Durée : `Permanent` / Raison : `%s` / Ban ID : `%s`\n / License : `%s`'):format(sourceName, targetName, reason, banid, licenseid), nil, ConfigSV.Logs["Ban"])
		end
	end)
end

function DeleteBan(banid, cb)
	MySQL.Async.execute('DELETE FROM banlist WHERE banid = @banid', {
		['@banid'] = banid
	}, function()
		if cb then
			cb()
		end
	end)
end

function IsBanned(licenseid, cb)
	MySQL.Async.fetchAll('SELECT * FROM banlist WHERE licenseid = @licenseid', {
		['@licenseid'] = licenseid
	}, function(result)
		if #result > 0 then
			cb(true, result[1])
		else
			cb(false, result[1])
		end
	end)
end

RegisterCommand('sqlban', function(source, args, user)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() == "superadmin" or xPlayer.getGroup() == "_dev" then
		if args[1] == nil then
			SendMessage(source, "Merci de définir un bon ID")
			return
		elseif args[2] == nil then
			SendMessage(source, "Merci de définir un bon temps de ban")
			return
		elseif args[3] == nil then
			SendMessage(source, "Merci de définir une bonne raison de ban")
			return
		end

		local licenseid, playerip = 'N/A', 'N/A'
		local target = tonumber(args[1])
		-- local expiration = tonumber(args[2])
		local duration = args[2]
		local expiration, unit = duration:match('(%d+)(%a+)') -- Extract numeric value and unit (e.g., 2 and 'h')
		local reason = table.concat(args, ' ', 3)

		if target and target > 0 then
			local sourceName = GetPlayerName(source)
			local targetName = GetPlayerName(target)

			if ESX.GetPlayerFromId(target) == nil then
				SendMessage(source, ConfigBan.Locale.invalidPlayer)
				return
			end

			local banid = ESX.GetPlayerFromId(target).boutique_id
			if targetName then
				-- if expiration and expiration <= 336 then
				if expiration and tonumber(expiration) or duration ~= nil then
					licenseid = ESX.GetIdentifierFromId(target, 'license:')

					if not licenseid then
						licenseid = 'N/A'
					end

					if reason == '' then
						reason = ConfigBan.Locale.noreason
					end

					if duration ~= -1 and tonumber(expiration) ~= nil and tonumber(expiration) > 0 then
						if unit and unit:lower() == 'm' then
							AddBan(source, licenseid, playerip, targetName, sourceName, expiration * 60, reason, 0, banid)
							DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : %s\nAuteur : %s\nBan ID : %s'):format(reason, SexyTime(expiration * 60), sourceName, banid))
						elseif unit and unit:lower() == 'h' then
							AddBan(source, licenseid, playerip, targetName, sourceName, expiration * 3600, reason, 0, banid)
							DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : %s\nAuteur : %s\nBan ID : %s'):format(reason, SexyTime(expiration * 3600), sourceName, banid))
						elseif unit and unit:lower() == 'd' then
							AddBan(source, licenseid, playerip, targetName, sourceName, expiration* 3600 * 24, reason, 0, banid)
							DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : %s\nAuteur : %s\nBan ID : %s'):format(reason, SexyTime(expiration * 3600 * 24), sourceName, banid))
						end
					else
						AddBan(source, licenseid, playerip, targetName, sourceName, duration, reason, 1, banid)
						DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : Permanent\nAuteur : %s\nBan ID : %s'):format(reason, sourceName, banid))
					end
				else
					SendMessage(source, ConfigBan.Locale.invalidtime)
				end
			else
				SendMessage(source, ConfigBan.Locale.invalidid)
			end
		else
			SendMessage(source, ConfigBan.Locale.invalidid)
		end
	end
end, false)

RegisterCommand('sqlbanoffline', function(source, args, user)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() == "superadmin" or xPlayer.getGroup() == "_dev" then
		local licenseid = tostring(args[1])
		local expiration = tonumber(args[2])
		local reason = table.concat(args, ' ', 3)
		local sourceName = GetPlayerName(source)

		if expiration then
			if licenseid then
				MySQL.Async.fetchAll('SELECT * FROM account_info WHERE license = @license', {
					['@license'] = licenseid
				}, function(data)
					if data[1] then
						if expiration and expiration <= 336 then
							if reason == '' then
								reason = ConfigBan.Locale.noreason
							end
							MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier', {
								['@identifier'] = licenseid
							}, function(data2)
								if expiration > 0 then
									AddBan(source, data[1].license, data[1].ip, data[1].name, sourceName, expiration, reason, 0, data2[1].boutique_id)
								else
									AddBan(source, data[1].license, data[1].ip, data[1].name, sourceName, expiration, reason, 1, data2[1].boutique_id)
								end
							end)
						else
							SendMessage(source, ConfigBan.Locale.invalidtime)
						end
					else
						SendMessage(source, ConfigBan.Locale.invalidid)
					end
				end)
			else
				SendMessage(source, ConfigBan.Locale.invalidID)
			end
		else
			SendMessage(source, ConfigBan.Locale.invalidtime)
		end
	end
end, false)

RegisterCommand('sqlunban', function(source, args, user)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() == "superadmin" or xPlayer.getGroup() == "_dev" then
		local sourceName = GetPlayerName(source)
		local banid = table.concat(args, ' ')

		if banid then
			MySQL.Async.fetchAll('SELECT * FROM banlist WHERE banid LIKE @banid', {
				['@banid'] = ('%' .. banid .. '%')
			}, function(data)
				if data[1] then
					DeleteBan(data[1].banid, function()
						SendMessage(source, ('%s a été déban'):format(data[1].targetName))
						TriggerEvent('esx:customDiscordLog','Ban Info', ('`%s` a été déban par `%s`'):format(data[1].targetName, sourceName), nil, ConfigSV.Logs["Ban"])
					end)
				else
					SendMessage(source, ConfigBan.Locale.invalidID)
				end
			end)
		else
			SendMessage(source, ConfigBan.Locale.cmdunban)
		end
	end
end, false)

--Console
ESXCustomServerUtils.registerConsoleCommand("ban", function(source, args)
	if source == 0 then
		if args[1] == nil then
			print("Merci de définir un bon ID")
			return
		elseif args[2] == nil then
			print("Merci de définir un bon temps de ban")
			return
		elseif args[3] == nil then
			print("Merci de définir une bonne raison de ban")
			return
		end

		local licenseid, playerip = 'N/A', 'N/A'
		local target = tonumber(args[1])
		local duration = args[2]
		local expiration, unit = duration:match('(%d+)(%a+)')
		local reason = table.concat(args, ' ', 3)
	
		if target and target > 0 then
			local sourceName = "Console"
			local targetName = GetPlayerName(target)
	
			if ESX.GetPlayerFromId(target) == nil then
				print(ConfigBan.Locale.invalidPlayer)
				return
			end
	
			local banid = ESX.GetPlayerFromId(target).boutique_id
			if targetName then
				if expiration and tonumber(expiration) then
					licenseid = ESX.GetIdentifierFromId(target, 'license:')
	
					if not licenseid then
						licenseid = 'N/A'
					end
	
					if reason == '' then
						reason = ConfigBan.Locale.noreason
					end
	
					if tonumber(expiration) > 0 then
						if unit and unit:lower() == 'm' then
							AddBan(source, licenseid, playerip, targetName, sourceName, expiration * 60, reason, 0, banid)
							DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : %s\nAuteur : %s\nBan ID : %s'):format(reason, SexyTime(expiration * 60), sourceName, banid))
						elseif unit and unit:lower() == 'h' then
							AddBan(source, licenseid, playerip, targetName, sourceName, expiration * 3600, reason, 0, banid)
							DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : %s\nAuteur : %s\nBan ID : %s'):format(reason, SexyTime(expiration * 3600), sourceName, banid))
						elseif unit and unit:lower() == 'd' then
							AddBan(source, licenseid, playerip, targetName, sourceName, expiration* 3600 * 24, reason, 0, banid)
							DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : %s\nAuteur : %s\nBan ID : %s'):format(reason, SexyTime(expiration * 3600 * 24), sourceName, banid))
						end
					else
						AddBan(source, licenseid, playerip, targetName, sourceName, expiration, reason, 1, banid)
						DropPlayer(target, ('Vous êtes banni\nRaison : %s\nTemps Restant : Permanent\nAuteur : %s\nBan ID : %s'):format(reason, sourceName, banid))
					end
				else
					print(ConfigBan.Locale.invalidtime)
				end
			else
				print(ConfigBan.Locale.invalidid)
			end
		else
			print(ConfigBan.Locale.invalidid)
		end
	end
end)

ESXCustomServerUtils.registerConsoleCommand("banoffline", function(source, args)
	if source == 0 then
		local licenseid = tostring(args[1])
		local expiration = tonumber(args[2])
		local reason = table.concat(args, ' ', 3)
		local sourceName = "Console"
	
		if expiration then
			if licenseid then
				MySQL.Async.fetchAll('SELECT * FROM account_info WHERE license = @license', {
					['@license'] = licenseid
				}, function(data)
					if data[1] then
						if expiration and expiration <= 336 then
							if reason == '' then
								reason = ConfigBan.Locale.noreason
							end
							MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier', {
								['@identifier'] = licenseid
							}, function(data2)
								if expiration > 0 then
									AddBan(source, data[1].license, data[1].ip, data[1].name, sourceName, expiration, reason, 0, data2[1].boutique_id)
								else
									AddBan(source, data[1].license, data[1].ip, data[1].name, sourceName, expiration, reason, 1, data2[1].boutique_id)
								end
							end)
						else
							SendMessage(source, ConfigBan.Locale.invalidtime)
						end
					else
						SendMessage(source, ConfigBan.Locale.invalidid)
					end
				end)
			else
				SendMessage(source, ConfigBan.Locale.invalidID)
			end
		else
			SendMessage(source, ConfigBan.Locale.invalidtime)
		end
	end
end)

ESXCustomServerUtils.registerConsoleCommand("unban", function(source, args)
	if source == 0 then
		local banid = table.concat(args, ' ')

		if banid then
			MySQL.Async.fetchAll('SELECT * FROM banlist WHERE banid LIKE @banid', {
				['@banid'] = ('%' .. banid .. '%')
			}, function(data)
				if data[1] then
					DeleteBan(data[1].banid, function()
						print(('%s a été déban'):format(data[1].targetName))
						TriggerEvent('esx:customDiscordLog','Ban Info', ('`%s` a été déban par `%s`'):format(data[1].targetName, "Console"), nil, ConfigSV.Logs["Ban"])
					end)
				else
					print(ConfigBan.Locale.invalidID)
				end
			end)
		else
			print(ConfigBan.Locale.cmdunban)
		end
	end
end)