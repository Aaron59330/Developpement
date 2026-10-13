CacheLoadLicense = {}
CacheLoadLicense2 = {}
RemoveLoadLicense = {}
CreateThread(function()--Ajout des informations au cache
    Wait(1500)
    if Config.Debug then
        print('ESXCustom : Initialisation des licenses...')
    end
	MySQL.Async.fetchAll('SELECT * FROM licenses', {}, function(InfoReceive)
        for k, v in pairs(InfoReceive) do
			if CacheLoadLicense2[v.type] == nil then
				CacheLoadLicense2[v.type] = {}
				CacheLoadLicense2[v.type].type = v.type
				CacheLoadLicense2[v.type].label = v.label
			else
				CacheLoadLicense2[v.type].type = v.type
				CacheLoadLicense2[v.type].label = v.label
			end
        end

        if Config.Debug then
            print('[^5LOAD^0] [^5'..#InfoReceive..'^0] licenses ont été load avec succès !')
        end
    end)
	Wait(200)
    MySQL.Async.fetchAll('SELECT * FROM user_licenses', {}, function(InfoReceive)
        for k, v in pairs(InfoReceive) do
			if CacheLoadLicense[v.owner] == nil then
				CacheLoadLicense[v.owner] = {}
				if CacheLoadLicense[v.owner][v.type] == nil then
					CacheLoadLicense[v.owner][v.type] = {}
					CacheLoadLicense[v.owner][v.type].type = v.type
					CacheLoadLicense[v.owner][v.type].owner = v.owner
					CacheLoadLicense[v.owner][v.type].hasThisLicense = true
					CacheLoadLicense[v.owner][v.type].label = CacheLoadLicense2[v.type].label
				end
			else
				if CacheLoadLicense[v.owner][v.type] == nil then
					CacheLoadLicense[v.owner][v.type] = {}
					CacheLoadLicense[v.owner][v.type].type = v.type
					CacheLoadLicense[v.owner][v.type].owner = v.owner
					CacheLoadLicense[v.owner][v.type].hasThisLicense = true
					CacheLoadLicense[v.owner][v.type].label = CacheLoadLicense2[v.type].label
				end
			end
        end

        if Config.Debug then
            print('[^5LOAD^0] [^5'..#InfoReceive..'^0] licenses de joueurs ont été load avec succès !')
        end
    end)
end)

function AddLicense(target, type, cb)
	local xPlayer = ESX.GetPlayerFromId(target)

	if xPlayer then
		if CacheLoadLicense[xPlayer.identifier] == nil then
			CacheLoadLicense[xPlayer.identifier] = {}
			if CacheLoadLicense[xPlayer.identifier][type] == nil then
				CacheLoadLicense[xPlayer.identifier][type] = {}
				CacheLoadLicense[xPlayer.identifier][type].type = type
				CacheLoadLicense[xPlayer.identifier][type].owner = xPlayer.identifier
				CacheLoadLicense[xPlayer.identifier][type].hasThisLicense = true
				CacheLoadLicense[xPlayer.identifier][type].WasNotSaveInBDD = true
				CacheLoadLicense[xPlayer.identifier][type].label = CacheLoadLicense2[type].label
			end
		else
			if CacheLoadLicense[xPlayer.identifier][type] == nil then
				CacheLoadLicense[xPlayer.identifier][type] = {}
				CacheLoadLicense[xPlayer.identifier][type].type = type
				CacheLoadLicense[xPlayer.identifier][type].owner = xPlayer.identifier
				CacheLoadLicense[xPlayer.identifier][type].hasThisLicense = true
				CacheLoadLicense[xPlayer.identifier][type].WasNotSaveInBDD = true
				CacheLoadLicense[xPlayer.identifier][type].label = CacheLoadLicense2[type].label
			end
		end
		--[[MySQL.Async.execute('INSERT INTO user_licenses (type, owner) VALUES (@type, @owner)', {
			['@type']  = type,
			['@owner'] = xPlayer.identifier
		}, function(rowsChanged)
			if CacheLoadLicense[xPlayer.identifier] == nil then
				CacheLoadLicense[xPlayer.identifier] = {}
				CacheLoadLicense[xPlayer.identifier].type = type

				if CacheLoadLicense[xPlayer.identifier][type] == nil then
					CacheLoadLicense[xPlayer.identifier][type] = {}
					CacheLoadLicense[xPlayer.identifier][type].type = type
					CacheLoadLicense[xPlayer.identifier][type].owner = xPlayer.identifier
					CacheLoadLicense[xPlayer.identifier][type].hasThisLicense = true
					CacheLoadLicense[xPlayer.identifier][type].WasNotSaveInBDD = true
				end
			else
				CacheLoadLicense[xPlayer.identifier].type = type
				if CacheLoadLicense[xPlayer.identifier][type] == nil then
					CacheLoadLicense[xPlayer.identifier][type] = {}
					CacheLoadLicense[xPlayer.identifier][type].type = type
					CacheLoadLicense[xPlayer.identifier][type].owner = xPlayer.identifier
					CacheLoadLicense[xPlayer.identifier][type].hasThisLicense = true
					CacheLoadLicense[xPlayer.identifier][type].WasNotSaveInBDD = true
				end
			end
			if cb then
				cb()
			end
		end)]]--
	else
		if cb then
			cb()
		end
	end
end

function RemoveLicense(target, type, cb)
	local xPlayer = ESX.GetPlayerFromId(target)

	if xPlayer then
		--[[MySQL.Async.execute('DELETE FROM user_licenses WHERE type = @type AND owner = @owner', {
			['@type'] = type,
			['@owner'] = xPlayer.identifier
		}, function(rowsChanged)
			if CacheLoadLicense[xPlayer.identifier] ~= nil then
				if CacheLoadLicense[xPlayer.identifier][type] ~= nil then
					CacheLoadLicense[xPlayer.identifier][type] = nil
				end
			end
			if cb then
				cb()
			end
		end)]]--
		if CacheLoadLicense[xPlayer.identifier] ~= nil then
			if RemoveLoadLicense[xPlayer.identifier] == nil then
				RemoveLoadLicense[xPlayer.identifier] = {}

				if RemoveLoadLicense[xPlayer.identifier][type] == nil then
					RemoveLoadLicense[xPlayer.identifier][type] = {}
					RemoveLoadLicense[xPlayer.identifier][type].type = type
					RemoveLoadLicense[xPlayer.identifier][type].owner = CacheLoadLicense[xPlayer.identifier][type].owner
				else
					RemoveLoadLicense[xPlayer.identifier][type].type = type
					RemoveLoadLicense[xPlayer.identifier][type].owner = CacheLoadLicense[xPlayer.identifier][type].owner
				end
			else
				RemoveLoadLicense[xPlayer.identifier].type = type

				if RemoveLoadLicense[xPlayer.identifier][type] == nil then
					RemoveLoadLicense[xPlayer.identifier][type] = {}
					RemoveLoadLicense[xPlayer.identifier][type].type = type
					RemoveLoadLicense[xPlayer.identifier][type].owner = CacheLoadLicense[xPlayer.identifier][type].owner
				else
					RemoveLoadLicense[xPlayer.identifier][type].type = type
					RemoveLoadLicense[xPlayer.identifier][type].owner = CacheLoadLicense[xPlayer.identifier][type].owne
				end
			end
			if CacheLoadLicense[xPlayer.identifier][type] ~= nil then
				CacheLoadLicense[xPlayer.identifier][type] = nil
			end
		end
	else
		if cb then
			cb()
		end
	end
end

function GetLicense(type, cb)
	--[[MySQL.Async.fetchAll('SELECT label FROM licenses WHERE type = @type', {
		['@type'] = type
	}, function(result)
		local data = {
			type  = type,
			label = result[1].label
		}

		cb(data)
	end)]]--

	local data = {type = type, label = CacheLoadLicense2[type].label}
	cb(data)
end

function GetLicenses(target, cb)
	--[[local xPlayer = ESX.GetPlayerFromId(target)

	MySQL.Async.fetchAll('SELECT type FROM user_licenses WHERE owner = @owner', {
		['@owner'] = xPlayer.identifier
	}, function(result)
		local licenses, asyncTasks = {}, {}

		for i=1, #result, 1 do
			local scope = function(type)
				table.insert(asyncTasks, function(cb)
					MySQL.Async.fetchAll('SELECT label FROM licenses WHERE type = @type', {
						['@type'] = type
					}, function(result2)
						table.insert(licenses, {
							type  = type,
							label = result2[1].label
						})

						cb()
					end)
				end)
			end

			scope(result[i].type)
		end

		Async.parallel(asyncTasks, function(results)
			cb(licenses)
		end)
	end)]]--

	local licenses = {}
	if CacheLoadLicense[ESX.GetPlayerFromId(target).identifier] ~= nil then
		for k, v in pairs(CacheLoadLicense[ESX.GetPlayerFromId(target).identifier]) do
			if v.type ~= nil and v.label ~= nil then
				table.insert(licenses, {
					type  = v.type,
					label = v.label
				})
			end
		end
	end
	cb(licenses)
end

function CheckLicense(target, type, cb)
	local xPlayer = ESX.GetPlayerFromId(target)

	if xPlayer then
		--[[MySQL.Async.fetchAll('SELECT COUNT(*) as count FROM user_licenses WHERE type = @type AND owner = @owner', {
			['@type'] = type,
			['@owner'] = xPlayer.identifier
		}, function(result)
			if tonumber(result[1].count) > 0 then
				cb(true)
			else
				cb(false)
			end
		end)]]--
		if CacheLoadLicense[ESX.GetPlayerFromId(target).identifier] ~= nil then
			if CacheLoadLicense[ESX.GetPlayerFromId(target).identifier][type].hasThisLicense then
				cb(true)
			else
				cb(false)
			end
		end
	else
		cb(false)
	end
end

exports("CheckLicense", function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	return CacheLoadLicense[xPlayer.identifier]
end)

function GetLicensesList(cb)
	--[[MySQL.Async.fetchAll('SELECT type, label FROM licenses', {
		['@type'] = type
	}, function(result)
		local licenses = {}

		for i=1, #result, 1 do
			table.insert(licenses, {
				type  = result[i].type,
				label = result[i].label
			})
		end

		cb(licenses)
	end)]]--

	local licenses = {}
	for k, v in pairs(CacheLoadLicense2) do
		table.insert(licenses, {
			type  = v.type,
			label = CacheLoadLicense2[v.type].label
		})
	end
	cb(licenses)
end

RegisterServerEvent('esx_license:addLicense')
AddEventHandler('esx_license:addLicense', function(target, type, cb)
	AddLicense(target, type, cb)
end)

RegisterServerEvent('esx_license:removeLicense')
AddEventHandler('esx_license:removeLicense', function(target, type, cb)
	RemoveLicense(target, type, cb)
end)

RegisterServerEvent('esx_license:getLicense')
AddEventHandler('esx_license:getLicense', function(type, cb)
	GetLicense(type, cb)
end)

RegisterServerEvent('esx_license:getLicenses')
AddEventHandler('esx_license:getLicenses', function(target, cb)
	GetLicenses(target, cb)
end)

RegisterServerEvent('esx_license:checkLicense')
AddEventHandler('esx_license:checkLicense', function(target, type, cb)
	CheckLicense(target, type, cb)
end)

RegisterServerEvent('esx_license:getLicensesList')
AddEventHandler('esx_license:getLicensesList', function(cb)
	GetLicensesList(cb)
end)

ESX.RegisterServerCallback('esx_license:getLicense', function(source, cb, type)
	GetLicense(type, cb)
end)

ESX.RegisterServerCallback('esx_license:getLicenses', function(source, cb, target)
	GetLicenses(target, cb)
end)

AddEventHandler('esx:playerDropped', function(eventSrc, xPlayer)
	if CacheLoadLicense[xPlayer.identifier] ~= nil then
		for k, v in pairs(CacheLoadLicense[xPlayer.identifier]) do
			if v.WasNotSaveInBDD ~= nil then
				MySQL.Async.execute('INSERT INTO user_licenses (type, owner) VALUES (@type, @owner)', {['@type'] = v.type, ['@owner'] = xPlayer.identifier})
				v.WasNotSaveInBDD = nil
			end
		end
	end

	if RemoveLoadLicense[xPlayer.identifier] ~= nil then
		for k, v in pairs(RemoveLoadLicense[xPlayer.identifier]) do
			MySQL.Async.execute('DELETE FROM user_licenses WHERE type = @type AND owner = @owner', {
				['@type'] = v.type,
				['@owner'] = xPlayer.identifier
			}, function(rowsChanged)
				if CacheLoadLicense[xPlayer.identifier] ~= nil then
					if CacheLoadLicense[xPlayer.identifier][type] ~= nil then
						CacheLoadLicense[xPlayer.identifier][type] = nil
					end
				end

				RemoveLoadLicense[xPlayer.identifier] = nil
			end)
		end
	end
end)