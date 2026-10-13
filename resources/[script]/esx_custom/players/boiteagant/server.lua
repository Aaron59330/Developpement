--Système sous cache
local CacheLoad = {} --Registre de la table pour le cache
CreateThread(function()--Ajout des informations au cache
	Wait(1500)
    if Config.Debug then
        print('ESXCustom : Initialisation des boîtes à gants...')
    end
    MySQL.Async.fetchAll('SELECT * FROM BoiteGant', {}, function(InfoReceive)
		for k, v in pairs(InfoReceive) do
			CacheLoad[v.plate] = {}
			CacheLoad[v.plate].id = v.id
			CacheLoad[v.plate].plate = v.plate
            CacheLoad[v.plate].data = json.decode(v.data)
            CacheLoad[v.plate].ItemMax = 0
            CacheLoad[v.plate].itemType = v.itemType

			for a, b in pairs(CacheLoad[v.plate].data) do
				for c, d in pairs(CacheLoad[v.plate].data[a]) do
					CacheLoad[v.plate].ItemMax = CacheLoad[v.plate].ItemMax + d.amount
				end
			end
		end
        if Config.Debug then
		    print('[^5LOAD^0] [^5'..#InfoReceive..'^0] boîtes à gants ont été load avec succès !')
        end
    end)
end)
--Fin du cache

ESX.RegisterServerCallback('esx_custom:getInventoryByPlate', function(source, cb, plate)
    if CacheLoad[plate] ~= nil then
	    cb({data = CacheLoad[plate].data, ItemMax = CacheLoad[plate].ItemMax})
    end
end)

RegisterNetEvent('esx_custom:GestionItem', function(action, item, amount, label, itemType, ammo)
    local xPlayer = ESX.GetPlayerFromId(source)

    VerifyToken(source, function()
        if itemType == "item_standard" then
            if action == "deposit" then
                local sourceItem = GetItemOnPlayer(source, item)
                if sourceItem.count >= amount and amount > 0 then
                    if CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))] ~= nil then
                        if CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item] == nil then
                            CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item] = {}
                
                            table.insert(CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item], {amount = amount, name = item, label = label, itemType = itemType})
                        else
                            for k, v in pairs(CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item]) do
                                v.amount = v.amount + amount
                            end
                        end

                        RemoveItemOnPlayer(source, item, amount)
                        CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].ItemMax = CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].ItemMax + amount
                        MySQL.Sync.execute("UPDATE BoiteGant set data = @data WHERE plate = @plate", {
                            ["@plate"] = CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].plate,
                            ["@data"] = json.encode(CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data)
                        })
                    else
                        CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))] = {}
                        CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].plate = GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))
                        CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data = {}

                        if CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item] == nil then
                            CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item] = {}
                
                            table.insert(CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item], {amount = amount, name = itemName, label = label})
                        else
                            for k, v in pairs(CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item]) do
                                v.amount = v.amount + amount
                            end
                        end

                        RemoveItemOnPlayer(source, item, amount)
                        if CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].ItemMax == nil then
                            CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].ItemMax = 0
                        end
                        CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].ItemMax = CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].ItemMax + amount
                        MySQL.Async.execute('INSERT INTO BoiteGant (plate, data) VALUES (@plate, @data)', {
                            ['@plate'] = CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].plate,
                            ["@data"] = json.encode(CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data)
                        })
                    end
                    TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, (ConfigBoiteAGant.MenuEtNotification["Deposit"]):format(amount, item))
                else
                    TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, ConfigBoiteAGant.MenuEtNotification["ErrorQuantity"])
                end
            elseif action == "take" then
                for k, v in pairs(CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item]) do
                    v.amount = v.amount - amount
            
                    if v.amount == 0 then
                        CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item] = nil
                    end
                end

                AddItemOnPlayer(source, item, amount)
                CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].ItemMax = CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].ItemMax - amount
                MySQL.Sync.execute("UPDATE BoiteGant set data = @data WHERE plate = @plate", {
                    ["@plate"] = CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].plate,
                    ["@data"] = json.encode(CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data)
                })
                TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, (ConfigBoiteAGant.MenuEtNotification["Retirer"]):format(amount, item))
            end
        elseif itemType == "item_weapon" then
            if action == "deposit" then
                if xPlayer.hasWeapon(item) then
                    if CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))] ~= nil then
                        if CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item] == nil then
                            CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item] = {}
                
                            table.insert(CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item], {isWeapon = true, amount = amount, name = item, label = label, ammo = ammo})
                        else
                            table.insert(CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item], {isWeapon = true, amount = amount, name = item, label = label, ammo = ammo})
                        end

                        xPlayer.removeWeapon(item, amount)
                        CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].ItemMax = CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].ItemMax + amount
                        MySQL.Sync.execute("UPDATE BoiteGant set data = @data WHERE plate = @plate", {
                            ["@plate"] = CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].plate,
                            ["@data"] = json.encode(CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data)
                        })
                    else
                        CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))] = {}
                        CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].plate = GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))
                        CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data = {}

                        if CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item] == nil then
                            CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item] = {}
                
                            table.insert(CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item], {isWeapon = true, amount = amount, name = itemName, label = label, ammo = ammo})
                        else
                            for k, v in pairs(CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item]) do
                                v.amount = v.amount + amount
                            end
                        end

                        xPlayer.removeWeapon(item, amount)
                        if CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].ItemMax == nil then
                            CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].ItemMax = 0
                        end
                        CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].ItemMax = CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].ItemMax + amount
                        MySQL.Async.execute('INSERT INTO BoiteGant (plate, data) VALUES (@plate, @data)', {
                            ['@plate'] = CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].plate,
                            ["@data"] = json.encode(CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data)
                        })
                    end
                    TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, (ConfigBoiteAGant.MenuEtNotification["Deposit"]):format(amount, item))
                else
                    TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, ConfigBoiteAGant.MenuEtNotification["ErrorQuantity"])
                end
            elseif action == "take" then
                for k, v in pairs(CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item]) do
                    v.amount = v.amount - amount
            
                    if v.amount == 0 then
                        CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data[item] = nil
                    end
                end

                xPlayer.addWeapon(item, amount)
                CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].ItemMax = CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].ItemMax - amount
                MySQL.Sync.execute("UPDATE BoiteGant set data = @data WHERE plate = @plate", {
                    ["@plate"] = CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].plate,
                    ["@data"] = json.encode(CacheLoad[GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)))].data)
                })
                TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, (ConfigBoiteAGant.MenuEtNotification["Retirer"]):format(amount, item))
            end
        end
    end)
end)