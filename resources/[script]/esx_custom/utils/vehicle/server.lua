--Système sous cache
CacheKeys = {} --Registre de la table pour le cache
CacheKeys2 = {}
NewCacheKeys = NewCacheKeys or {} -- Evite une erreur si aucun cache de nouvelles clefs n’a été créé

Citizen.CreateThread(function()--Ajout des informations au cache
	Wait(1500)
	if Config.Debug then
		print('ESXCustom : Initialisation des clefs...')
	end
	MySQL.Async.fetchAll('SELECT * FROM open_car', {}, function(InfoReceive)
		for k, v in pairs(InfoReceive) do
			if CacheKeys[v.identifier] == nil then
				CacheKeys[v.identifier] = {}
				table.insert(CacheKeys[v.identifier], {id = v.id, identifier = v.identifier, label = v.label, value = v.value, got = v.got, NB = v.NB})
			else
				table.insert(CacheKeys[v.identifier], {id = v.id, identifier = v.identifier, label = v.label, value = v.value, got = v.got, NB = v.NB})
			end
			if CacheKeys2[v.value] == nil then
				CacheKeys2[v.value] = {}
				CacheKeys2[v.value].id = v.id
				CacheKeys2[v.value].identifier = v.identifier
				CacheKeys2[v.value].label = v.label
				CacheKeys2[v.value].value = v.value
				CacheKeys2[v.value].got = v.got
				CacheKeys2[v.value].NB = v.NB
			end
		end
		if Config.Debug then
			print('[^5LOAD^0] [^5'..#InfoReceive..'^0] clefs ont été load avec succès !')
		end
	end)
end)

RegisterNetEvent("esx_custom:SendServerSideKeys", function()--Send to client side
	TriggerClientEvent("esx_custom:ReceiveClientSideKeys", source, CacheKeys[ESX.GetPlayerFromId(source).identifier])
end)

--Partie cache finis
if Config.AfterRebootDeleteLandKey then
	AddEventHandler('onMySQLReady', function()
		MySQL.Async.fetchAll('SELECT * FROM open_car WHERE NB = @NB', { ['@NB'] = 2}, function(result)
			for i=1, #result, 1 do
				MySQL.Async.execute('DELETE FROM open_car WHERE id = @id', {['@id'] = result[i].id})
			end
		end)
	end)
end

ESX.RegisterServerCallback('esx_custom:getVehiclesnokey', function(source, cb)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner', {['@owner'] = xPlayer.identifier}, function(result)
		local vehicles = {}
		for i=1, #result, 1 do
			local found = false
			local vehicleData = json.decode(result[i].vehicle)
			if CacheKeys[xPlayer.identifier] ~= nil then
				for j=1, #CacheKeys[xPlayer.identifier], 1 do
					if CacheKeys[xPlayer.identifier][j].value == vehicleData.plate then
						found = true
					end
				end
			end
			if found ~= true then
				table.insert(vehicles, vehicleData)
			end
			if NewCacheKeys[xPlayer.identifier] ~= nil then
				for k, v in pairs(NewCacheKeys[xPlayer.identifier]) do
					table.insert(vehicles, {model = NewCacheKeys[xPlayer.identifier].model, plate = NewCacheKeys[xPlayer.identifier].value})
				end
			end
		end
		cb(vehicles)
	end)
end)

RegisterNetEvent('esx_custom:registerkey', function(plate, target, viewNewKey)
	local _source = source
	if target == 'no' then
		xPlayer = ESX.GetPlayerFromId(_source)
	else
		xPlayer = ESX.GetPlayerFromId(target)
	end
	if CacheKeys[xPlayer.identifier] == nil then
		CacheKeys[xPlayer.identifier] = {}
		table.insert(CacheKeys[xPlayer.identifier], {identifier = xPlayer.identifier, label = "Cles", value = plate, got = 'true', NB = 1})
	else
		table.insert(CacheKeys[xPlayer.identifier], {identifier = xPlayer.identifier, label = "Cles", value = plate, got = 'true', NB = 1})
	end
	if CacheKeys2[plate] == nil then
		CacheKeys2[plate] = {}
		CacheKeys2[plate].identifier = xPlayer.identifier
		CacheKeys2[plate].label = "Cles"
		CacheKeys2[plate].value = plate
		CacheKeys2[plate].got = "true"
		CacheKeys2[plate].NB = 1
	end
	TriggerClientEvent("esx_custom:ReceiveClientSideKeys", source, CacheKeys[xPlayer.identifier])
	
	MySQL.Async.execute('INSERT INTO open_car (value, NB, got, identifier, label) VALUES (@value, @NB, @got, @identifier, @label)', {
		['@label'] = 'Cles',
		['@value'] = plate,
		['@NB'] = 1,
		['@got'] = 'true',
		['@identifier'] = xPlayer.identifier
	}, function(result)
		if viewNewKey ~= nil and viewNewKey then
			if not ConfigVehicle.DisableKey then
				TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, ConfigVehicle.MenuEtNotification["Notif1"])
				TriggerClientEvent(Config.Trigger.TriggerNotification, _source, ConfigVehicle.MenuEtNotification["Notif2"])
			end
		end
	end)
end)

function RegisterNewKeys(source, plate, target)
	local _source = source
	if target == 'no' then
		xPlayer = ESX.GetPlayerFromId(_source)
	else
		xPlayer = ESX.GetPlayerFromId(target)
	end
	if CacheKeys[xPlayer.identifier] == nil then
		CacheKeys[xPlayer.identifier] = {}
		table.insert(CacheKeys[xPlayer.identifier], {identifier = xPlayer.identifier, label = "Cles", value = plate, got = 'true', NB = 1})
	else
		table.insert(CacheKeys[xPlayer.identifier], {identifier = xPlayer.identifier, label = "Cles", value = plate, got = 'true', NB = 1})
	end
	if CacheKeys2[plate] == nil then
		CacheKeys2[plate] = {}
		CacheKeys2[plate].identifier = xPlayer.identifier
		CacheKeys2[plate].label = "Cles"
		CacheKeys2[plate].value = plate
		CacheKeys2[plate].got = "true"
		CacheKeys2[plate].NB = 1
	end
	TriggerClientEvent("esx_custom:ReceiveClientSideKeys", source, CacheKeys[xPlayer.identifier])
	
	MySQL.Async.execute('INSERT INTO open_car (value, NB, got, identifier, label) VALUES (@value, @NB, @got, @identifier, @label)', {
		['@label'] = 'Cles',
		['@value'] = plate,
		['@NB'] = 1,
		['@got'] = 'true',
		['@identifier'] = xPlayer.identifier
	}, function(result)
		if not ConfigVehicle.DisableKey then
			TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, ConfigVehicle.MenuEtNotification["Notif1"])
			TriggerClientEvent(Config.Trigger.TriggerNotification, _source, ConfigVehicle.MenuEtNotification["Notif2"])
		end
	end)
end

exports('RegisterNewKeys', RegisterNewKeys)

RegisterNetEvent('esx_custom:donnerkey', function(target, plate, vehicleProps)
	local _source = source
	local xPlayer = nil
	local toplate = plate
	local xPlayertarget = ESX.GetPlayerFromId(target)
	local xPlayer = ESX.GetPlayerFromId(_source)
	--Source
	MySQL.Async.fetchAll('SELECT * FROM open_car WHERE value = @plate AND NB = @NB AND identifier = @identifier', {['@NB'] = 1, ['@plate'] = toplate, ['@identifier'] = xPlayer.identifier}, function(result)
		for i=1, #result, 1 do
			MySQL.Async.execute('UPDATE open_car SET identifier = @identifier WHERE id = @id', {['@id'] = result[i].id, ['@identifier'] = xPlayertarget.identifier})
		end
	end)
	for k, v in pairs(CacheKeys[xPlayer.identifier]) do
		if v.value == toplate then
			v.value = nil
			TriggerClientEvent("esx_custom:ReceiveClientSideKeys", _source, CacheKeys[xPlayer.identifier])
		end
	end
	--Target
	MySQL.Async.execute('UPDATE owned_vehicles SET owner = @owner WHERE plate = @plate', {['@owner']   = xPlayertarget.identifier, ['@plate'] = plate}, function(result)
		TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayertarget.source, (ConfigVehicle.MenuEtNotification["Notif3"]):format(plate))
		TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, (ConfigVehicle.MenuEtNotification["Notif4"]):format(plate))
	end)
	--CacheKeys
	if CacheKeys[xPlayertarget.identifier] == nil then
		CacheKeys[xPlayertarget.identifier] = {}
	end
	table.insert(CacheKeys[xPlayertarget.identifier], {identifier = xPlayertarget.identifier, label = 'Cles', value = toplate, got = 'true', NB = 1})
	--CacheKeys2
	if CacheKeys2[toplate] ~= nil then
		CacheKeys2[toplate].identifier = xPlayertarget.identifier
	end
	TriggerClientEvent("esx_custom:ReceiveClientSideKeys", xPlayertarget.source, CacheKeys[xPlayertarget.identifier])
end)

RegisterNetEvent('esx_custom:preterkey', function(target, plate)
	local _source = source
	local xPlayer = nil
	local toplate = plate
	xPlayertarget = ESX.GetPlayerFromId(target)
	xPlayer = ESX.GetPlayerFromId(_source)
	MySQL.Async.execute('INSERT INTO open_car (label, value, NB, got, identifier) VALUES (@label, @value, @NB, @got, @identifier)', {['@label'] = 'Cles', ['@value'] = toplate, ['@NB'] = 2, ['@got'] = 'true', ['@identifier'] = xPlayertarget.identifier}, function(result)
		TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayertarget.source, ConfigVehicle.MenuEtNotification["Notif5"])
		TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, ConfigVehicle.MenuEtNotification["Notif6"])
	end)
	if CacheKeys[xPlayertarget.identifier] == nil then
		CacheKeys[xPlayertarget.identifier] = {}
		table.insert(CacheKeys[xPlayertarget.identifier], {identifier = xPlayertarget.identifier, label = "Cles", value = toplate, got = 'true', NB = 2})
	else
		table.insert(CacheKeys[xPlayertarget.identifier], {identifier = xPlayertarget.identifier, label = "Cles", value = toplate, got = 'true', NB = 2})
	end
	TriggerClientEvent("esx_custom:ReceiveClientSideKeys", xPlayertarget.source, CacheKeys[xPlayertarget.identifier])
end)

--Clés appartenue par rapport a la plaque
ESX.RegisterServerCallback('esx_custom:GotAkey', function(source, cb, plate)
	local xPlayer = ESX.GetPlayerFromId(source)
	if CacheKeys2[plate] ~= nil then
		if CacheKeys2[plate].identifier == ESX.GetPlayerFromId(source).identifier then
			cb(true)
			return
		end
		if not found then
			cb(false)
			return
		end
	else
		cb(false)
		return
	end
end)

exports('TransferKeys', function(plate, target)
	local xTarget = ESX.GetPlayerFromId(target)
	if not xTarget or not plate then return false end
	MySQL.Async.execute('DELETE FROM open_car WHERE value = @plate', { ['@plate'] = plate })
	for _, list in pairs(CacheKeys) do
		for i = #list, 1, -1 do
			if list[i].value == plate or list[i].value == nil then table.remove(list, i) end
		end
	end
	CacheKeys2[plate] = { identifier = xTarget.identifier, label = 'Cles', value = plate, got = 'true', NB = 1 }
	if CacheKeys[xTarget.identifier] == nil then CacheKeys[xTarget.identifier] = {} end
	table.insert(CacheKeys[xTarget.identifier], { identifier = xTarget.identifier, label = 'Cles', value = plate, got = 'true', NB = 1 })
	MySQL.Async.execute('INSERT INTO open_car (value, NB, got, identifier, label) VALUES (@value, 1, @got, @identifier, @label)', {
		['@label'] = 'Cles', ['@value'] = plate, ['@got'] = 'true', ['@identifier'] = xTarget.identifier,
	})
	TriggerClientEvent('esx_custom:ReceiveClientSideKeys', target, CacheKeys[xTarget.identifier])
	return true
end)
