-- Open ID card
RegisterNetEvent('jsfour-idcard:open', function(ID, targetID, type)
	local identifier = ESX.GetPlayerFromId(ID).identifier
	local _source 	 = ESX.GetPlayerFromId(targetID).source
	local show       = false
	local licenses = {}

	-- SELECT * : fonctionne avec ou sans la colonne `nationality` (voir esx_identity/install.sql)
	MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier', {['@identifier'] = identifier},
	function (user)
		if (user[1] ~= nil) then
			MySQL.Async.fetchAll('SELECT type FROM user_licenses WHERE owner = @identifier', {['@identifier'] = identifier},
			function (result)
				if type ~= nil then
					for _, v in pairs(result) do
						if type == 'driver' then
							if v.type == 'drive' or v.type == 'drive_bike' or v.type == 'drive_truck' then
								show = true
							end
						elseif type == 'weapon' then
							if v.type == 'weapon' then
								show = true
							end
						elseif type == 'code' then
							if v.type == 'code' then
								show = true
							end
						end
						table.insert(licenses, v)
					end
				else
					show = true
				end

				if show then
					local array = {
						user = user,
						licenses = licenses,
						owner = ID -- sert au client à récupérer la vraie tête du personnage
					}
					TriggerClientEvent('jsfour-idcard:open', _source, array, type)
				else
					ConfigJsFourd.Notify(_source, "Vous n'avez pas ce type de licence..")
				end
			end)
		end
	end)
end)
