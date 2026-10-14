RegisterServerEvent('esx_billing:sendBill')
AddEventHandler('esx_billing:sendBill', function(playerId, sharedAccountName, label, amount)
	if playerId == nil or sharedAccountName == nil or label == nil or amount == nil then
        ESXCustomServerUtils.rejectSuspiciousAction(source, 'Désynchronisation avec le serveur ou detection de Cheat [Facture].')
		return
	end

    if playerId == -1 then
        ESXCustomServerUtils.rejectSuspiciousAction(source, 'Désynchronisation avec le serveur ou detection de Cheat [Facture].')
        return
    else
		local _SRC = source
		local xPlayer = ESX.GetPlayerFromId(_SRC)
		local xTarget = ESX.GetPlayerFromId(playerId)
		amount = tonumber(amount)

		if not xPlayer or not amount then
			return
		end

		amount = ESX.Math.Round(amount)

		if amount > 0 and xTarget then
			TriggerEvent('esx_addonaccount:getSharedAccount', sharedAccountName, function(account)
				if account then
					MySQL.Async.execute('INSERT INTO billing (identifier, sender, target_type, target, label, amount) VALUES (@identifier, @sender, @target_type, @target, @label, @amount)', {
						['@identifier'] = xTarget.identifier,
						['@sender'] = xPlayer.identifier,
						['@target_type'] = 'society',
						['@target'] = sharedAccountName,
						['@label'] = label,
						['@amount'] = amount
					}, function(rowsChanged)
						JobNotifyClient( playerId, 'Vous avez ~r~reçu~s~ une facture')
					end)
					TriggerEvent('esx:customDiscordLog', 'Logs facture', 'Logs facture', nil, ConfigSV.Logs["LogsFacture"], '**Informations du joueur ayant envoyer la facture :**\nID : '.._SRC..'\nUtilisateur : '..GetPlayerName(_SRC)..'\nLicense : '..ESX.GetPlayerFromId(_SRC).identifier.."\n\n**Informations du joueur ayant reçu la facture :**\nID : "..playerId.."\nUtilisateur : "..GetPlayerName(playerId).."\nLicense : "..ESX.GetPlayerFromId(playerId).identifier)
				
				else
					-- Une facture envoyée vers society_* ne doit jamais devenir silencieusement
					-- une facture joueur : sinon le paiement n'alimente pas le compte entreprise.
					if type(sharedAccountName) == 'string' and string.sub(sharedAccountName, 1, 8) == 'society_' then
						print(('[esx_billing] Compte société introuvable, facture annulée : %s'):format(tostring(sharedAccountName)))
						JobNotifyClient( _SRC, ('~r~Erreur : compte entreprise introuvable (%s)'):format(tostring(sharedAccountName)))
						return
					end

					MySQL.Async.execute('INSERT INTO billing (identifier, sender, target_type, target, label, amount) VALUES (@identifier, @sender, @target_type, @target, @label, @amount)', {
						['@identifier'] = xTarget.identifier,
						['@sender'] = xPlayer.identifier,
						['@target_type'] = 'player',
						['@target'] = xPlayer.identifier,
						['@label'] = label,
						['@amount'] = amount
					}, function(rowsChanged)
						JobNotifyClient( playerId, 'Vous avez ~r~reçu~s~ une facture')
						TriggerEvent('esx:customDiscordLog', 'Logs facture', 'Logs facture', nil, ConfigSV.Logs["LogsFacture"], '**Informations du joueur ayant envoyer la facture :**\nID : '.._SRC..'\nUtilisateur : '..GetPlayerName(_SRC)..'\nLicense : '..ESX.GetPlayerFromId(_SRC).identifier.."\n\n**Informations du joueur ayant reçu la facture :**\nID : "..playerId.."\nUtilisateur : "..GetPlayerName(playerId).."\nLicense : "..ESX.GetPlayerFromId(playerId).identifier)
					end)
				end
			end)
		end
	end
end)

ESX.RegisterServerCallback('esx_billing:getBills', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT amount, id, label FROM billing WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)
		cb(result)
	end)
end)

ESX.RegisterServerCallback('esx_billing:getTargetBills', function(source, cb, target)
	local xPlayer = ESX.GetPlayerFromId(target)

	if xPlayer then
		MySQL.Async.fetchAll('SELECT amount, id, label FROM billing WHERE identifier = @identifier', {
			['@identifier'] = xPlayer.identifier
		}, function(result)
			cb(result)
		end)
	else
		cb({})
	end
end)

ESX.RegisterServerCallback('esx_billing:payBill', function(source, cb, billId)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT sender, target_type, target, amount FROM billing WHERE id = @id', {
		['@id'] = billId
	}, function(result)
		if result[1] then
			local amount = result[1].amount
			local xTarget = ESX.GetPlayerFromIdentifier(result[1].sender)

			if result[1].target_type == 'player' then
				if xTarget then
					if GetMoney(source) >= amount then
						MySQL.Async.execute('DELETE FROM billing WHERE id = @id', {
							['@id'] = billId
						}, function(rowsChanged)
							if rowsChanged == 1 then
								RemoveMoneyOnPlayer(source, amount)
								AddMoney(result[1].sender, amount)

								JobNotifyClient( source, ('vous avez ~g~payé~s~ une facture de ~r~$%s~s~'):format(ESX.Math.GroupDigits(amount)))
								JobNotifyClient( xTarget.source, ('vous avez ~g~reçu~s~ un paiement de ~g~$%s~s~'):format(ESX.Math.GroupDigits(amount)))
							end

							cb()
						end)
					elseif GetMoneyBanque(source) >= amount then
						MySQL.Async.execute('DELETE FROM billing WHERE id = @id', {
							['@id'] = billId
						}, function(rowsChanged)
							if rowsChanged == 1 then
								RemoveMoneyOnBanque(source, amount)
								AddMoneyOnBanque(result[1].sender, amount)

								JobNotifyClient( source, ('Vous avez ~g~payé~s~ une facture de ~r~$%s~s~'):format(ESX.Math.GroupDigits(amount)))
								JobNotifyClient( xTarget.source, ('Vous avez ~g~reçu~s~ un paiement de ~g~$%s~s~'):format(ESX.Math.GroupDigits(amount)))
							end

							cb()
						end)
					else
						JobNotifyClient( source, 'Vous n\'avez pas assez d\'argent pour payer cette facture')
						JobNotifyClient( xTarget.source, 'Le joueur ~r~n\'a pas ~s~assez d\'argent pour payer la facture!')
						cb()
					end
				else
					JobNotifyClient( source, 'Le joueur n\'est pas connecté')
					cb()
				end
			else
				TriggerEvent('esx_addonaccount:getSharedAccount', result[1].target, function(account)
					if not account then
						print(('[esx_billing] Paiement impossible, compte société introuvable : %s'):format(tostring(result[1].target)))
						JobNotifyClient( source, '~r~Erreur : compte entreprise introuvable. La facture n\'a pas été débitée.')
						cb()
						return
					end

					if GetMoney(source) >= amount then
						MySQL.Async.execute('DELETE FROM billing WHERE id = @id', {
							['@id'] = billId
						}, function(rowsChanged)
							if rowsChanged == 1 then
								RemoveMoneyOnPlayer(source, amount)
								account.addMoney(amount)

								JobNotifyClient( source, ('Vous avez ~g~payé~s~ une facture de ~r~$%s~s~'):format(ESX.Math.GroupDigits(amount)))
								if xTarget then
									JobNotifyClient( xTarget.source, ('Vous avez ~g~reçu~s~ un paiement de ~g~$%s~s~'):format(ESX.Math.GroupDigits(amount)))
								end
							end

							cb()
						end)
					elseif xPlayer.getAccount('bank').money >= amount then
						MySQL.Async.execute('DELETE FROM billing WHERE id = @id', {
							['@id'] = billId
						}, function(rowsChanged)
							if rowsChanged == 1 then
								RemoveMoneyOnBanque(source, amount)
								account.addMoney(amount)
								JobNotifyClient( source, ('Vous avez ~g~payé~s~ une facture de ~r~$%s~s~'):format(ESX.Math.GroupDigits(amount)))

								if xTarget then
									JobNotifyClient( xTarget.source, ('Vous avez ~g~reçu~s~ un paiement de ~g~$%s~s~'):format(ESX.Math.GroupDigits(amount)))
								end
							end

							cb()
						end)
					else
						if xTarget then
							JobNotifyClient( xTarget.source, 'le joueur ~r~n\'a pas ~s~assez d\'argent pour payer la facture !')
						end

						JobNotifyClient( source, 'Vous n\'avez pas assez d\'argent pour payer cette facture')
						cb()
					end
				end)
			end
		else
			cb()
		end
	end)
end)