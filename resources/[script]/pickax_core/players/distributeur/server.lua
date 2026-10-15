RegisterNetEvent("ESXCustomDistributeur:GiveHeal", function(src, List)
	if List == "eau" then
		HealAfterBuy(src, 200000, List)
	elseif List == "cafe" then
		HealAfterBuy(src, 60000, List)
	else
		TriggerEvent("ESXCustomDistributeur:PlayerKickForCheat", src)
	end
end)

RegisterNetEvent("ESXCustomDistributeur:removeMoney", function(Moula, healing, water, Payement, Item)
	local src = source

	VerifyToken(src, function()
		xPlayer = ESX.GetPlayerFromId(src)
		local argent = 0
		argent = GetMoney(src)

		if argent <= 0 or argent < tonumber(Moula) or tonumber(Moula) <= 0 then
			TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, "~r~Vous n'avez pas les fonds nécéssaires.~s~")
		else
			if Payement ~= nil then
				TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, ConfigDistributeur.Notification.YouBuy)
				if Payement == 1 then
					RemoveMoneyOnPlayer(src, Moula)
				elseif Payement == 2 then
					RemoveMoneyOnBanque(src, Moula)
				end
				if healing and water then
					Item = nil
					TriggerEvent("ESXCustomDistributeur:GiveHeal", src, "eau")
				elseif healing and not water then
					TriggerEvent("ESXCustomDistributeur:GiveHeal", src, "cafe")
				else
					AddItemOnPlayer(src, Item, 1)
				end
			else
				TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, ConfigDistributeur.Notification.YouBuy)
				RemoveMoneyOnPlayer(src, Moula)
				if healing and water then
					Item = nil
					TriggerEvent("ESXCustomDistributeur:GiveHeal", src, "eau")
				elseif healing and not water then
					TriggerEvent("ESXCustomDistributeur:GiveHeal", src, "cafe")
				else
					AddItemOnPlayer(src, Item, 1)
				end
			end
		end
	end)
end)