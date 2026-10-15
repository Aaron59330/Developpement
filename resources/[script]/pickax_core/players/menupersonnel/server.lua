ESX.RegisterServerCallback('CorePickax:GetBills', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM billing WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)
		local bills = {}
		for i = 1, #result do
			bills[#bills + 1] = {
				id = result[i].id,
				label = result[i].label,
				amount = result[i].amount
			}
		end
		cb(bills)
	end)
end)

-- Identité réelle du personnage (le PlayerData du client garde « John Doe » tant que le joueur n'a pas rechargé après la création du personnage)
ESX.RegisterServerCallback('CorePickax:GetIdentity', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	if not xPlayer then return cb(nil) end
	local first, last = xPlayer.get('firstName'), xPlayer.get('lastName')
	if not first or first == '' then
		local row = MySQL.single.await('SELECT firstname, lastname FROM users WHERE identifier = ?', { xPlayer.identifier })
		first, last = row and row.firstname, row and row.lastname
	end
	if first and first ~= '' then
		cb({ firstName = first, lastName = last or '' })
	else
		cb(nil)
	end
end)
