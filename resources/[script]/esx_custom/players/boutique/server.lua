discord_webhook = {
	url = ConfigBoutique.Webhook
}

--Mise en cache
local PlayerCacheBoutique = {} --Registre de la table pour le cache
local PlayerCacheBoutique2 = {}
local PriceConfigBoutique = {}

Citizen.CreateThread(function()--Ajout des informations au cache
	Wait(1500)
    if Config.Debug then
        print('ESXCustom : Initialisation des informations de la boutique des joueurs...')
    end
    MySQL.Async.fetchAll('SELECT identifier, boutique_id, points FROM users', {}, function(Receive)
        if Receive ~= nil then
            for k, v in pairs(Receive) do
                if PlayerCacheBoutique[v.identifier] == nil then
                    PlayerCacheBoutique[v.identifier] = {}
                    PlayerCacheBoutique[v.identifier].boutique_id = v.boutique_id
                    PlayerCacheBoutique[v.identifier].identifier = v.identifier
                    PlayerCacheBoutique[v.identifier].points = v.points

                    if ConfigBoutique.PermissionDebug then
                        if ConfigBoutique.PermissionAllowed[v.identifier] then
                            PlayerCacheBoutique[v.identifier].Staff = true
                        end
                    else
                        if ConfigBoutique.PermissionAllowed["license:"..v.identifier] then
                            PlayerCacheBoutique[v.identifier].Staff = true
                        end
                    end
                end

                if PlayerCacheBoutique2[v.boutique_id] == nil then
                    PlayerCacheBoutique2[v.boutique_id] = {}
                    PlayerCacheBoutique2[v.boutique_id].boutique_id = v.boutique_id
                    PlayerCacheBoutique2[v.boutique_id].identifier = v.identifier
                    PlayerCacheBoutique2[v.boutique_id].points = v.points
                end
            end
        end
    end)
end)

Citizen.CreateThread(function()--Ajout des informations au cache Price
    PriceConfigBoutique.Vehicle = {}
    for k, v in pairs(ConfigBoutique.vehicle) do
        if PriceConfigBoutique.Vehicle[k] == nil then
            PriceConfigBoutique.Vehicle[k] = {}
            PriceConfigBoutique.Vehicle[k].id = k
            PriceConfigBoutique.Vehicle[k].model = v.model
            PriceConfigBoutique.Vehicle[k].price = v.price
            PriceConfigBoutique.Vehicle[k].name = v.name
        end
    end
    PriceConfigBoutique.Motos = {}
    for k, v in pairs(ConfigBoutique.Motos) do
        if PriceConfigBoutique.Motos[k] == nil then
            PriceConfigBoutique.Motos[k] = {}
            PriceConfigBoutique.Motos[k].id = k
            PriceConfigBoutique.Motos[k].model = v.model
            PriceConfigBoutique.Motos[k].price = v.price
            PriceConfigBoutique.Motos[k].name = v.name
        end
    end

    PriceConfigBoutique.Autres = {}
    for k, v in pairs(ConfigBoutique.Autres) do
        if PriceConfigBoutique.Autres[k] == nil then
            PriceConfigBoutique.Autres[k] = {}
            PriceConfigBoutique.Autres[k].id = k
            PriceConfigBoutique.Autres[k].model = v.model
            PriceConfigBoutique.Autres[k].price = v.price
            PriceConfigBoutique.Autres[k].name = v.name
            PriceConfigBoutique.Autres[k].type = v.type
        end
    end

    PriceConfigBoutique.weapon = {}
    for k, v in pairs(ConfigBoutique.weapon) do
        if PriceConfigBoutique.weapon[k] == nil then
            PriceConfigBoutique.weapon[k] = {}
            PriceConfigBoutique.weapon[k].id = k
            PriceConfigBoutique.weapon[k].model = v.model
            PriceConfigBoutique.weapon[k].price = v.price
            PriceConfigBoutique.weapon[k].name = v.name
        end
    end

    PriceConfigBoutique.caisse = {}
    for k, v in pairs(ConfigBoutique.caisse) do
        if PriceConfigBoutique.caisse[k] == nil then
            PriceConfigBoutique.caisse[k] = {}
            PriceConfigBoutique.caisse[k].id = k
            PriceConfigBoutique.caisse[k].model = v.model
            PriceConfigBoutique.caisse[k].price = v.price
            PriceConfigBoutique.caisse[k].name = v.name
        end
    end

    PriceConfigBoutique.pack = {}
    for k, v in pairs(ConfigBoutique.pack) do
        if PriceConfigBoutique.pack[k] == nil then
            PriceConfigBoutique.pack[k] = {}
            PriceConfigBoutique.pack[k].id = k
            PriceConfigBoutique.pack[k].price = v.price
            PriceConfigBoutique.pack[k].name = v.name
        end
    end

    PriceConfigBoutique.Entreprise = {}
    for k, v in pairs(ConfigBoutique.Entreprise) do
        if PriceConfigBoutique.Entreprise[k] == nil then
            PriceConfigBoutique.Entreprise[k] = {}
            PriceConfigBoutique.Entreprise[k].id = k
            PriceConfigBoutique.Entreprise[k].price = v.price
            PriceConfigBoutique.Entreprise[k].name = v.name
        end
    end

    PriceConfigBoutique.boost = {}
    for k, v in pairs(ConfigBoutique.boost) do
        if PriceConfigBoutique.boost[k] == nil then
            PriceConfigBoutique.boost[k] = {}
            PriceConfigBoutique.boost[k].id = k
            PriceConfigBoutique.boost[k].price = v.price
        end
    end
end)

RegisterServerEvent("esx_custom:SendServerSideBoutique")
AddEventHandler("esx_custom:SendServerSideBoutique", function()--Send to client side
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer == nil then
        return
    end

    if PlayerCacheBoutique[xPlayer.identifier] ~= nil then
        PlayerCacheBoutique[xPlayer.identifier].SourceID = source
    else
        PlayerCacheBoutique[xPlayer.identifier] = {}
        PlayerCacheBoutique[xPlayer.identifier].boutique_id = xPlayer.boutique_id
        PlayerCacheBoutique[xPlayer.identifier].identifier = xPlayer.identifier
        PlayerCacheBoutique[xPlayer.identifier].points = xPlayer.points
        PlayerCacheBoutique[xPlayer.identifier].SourceID = source

        if ConfigBoutique.PermissionDebug then
            if ConfigBoutique.PermissionAllowed[xPlayer.identifier] then
                PlayerCacheBoutique[xPlayer.identifier].Staff = true
            end
        else
            if ConfigBoutique.PermissionAllowed["license:"..xPlayer.identifier] then
                PlayerCacheBoutique[xPlayer.identifier].Staff = true
            end
        end

        if PlayerCacheBoutique2[xPlayer.boutique_id] == nil then
            PlayerCacheBoutique2[xPlayer.boutique_id] = {}
            PlayerCacheBoutique2[xPlayer.boutique_id].boutique_id = xPlayer.boutique_id
            PlayerCacheBoutique2[xPlayer.boutique_id].identifier = xPlayer.identifier
            PlayerCacheBoutique2[xPlayer.boutique_id].points = xPlayer.points
        end
    end
	TriggerClientEvent("esx_custom:ReceiveClientSideBoutique", source, PlayerCacheBoutique[xPlayer.identifier])
end)

--Function
BoutiqueFunction = {}
BoutiqueFunction.SaveData = function(id, xPlayer)
    MySQL.Async.execute('UPDATE `users` SET `points`=@points WHERE identifier=@identifier', {
        ['@identifier'] = xPlayer,
        ['@points'] = PlayerCacheBoutique[xPlayer].points
    }, function(rowsChange)
    end)

	TriggerClientEvent("esx_custom:ReceiveClientSideBoutique", id, PlayerCacheBoutique[xPlayer])
end

BoutiqueFunction.removePointsToPlayer = function(id, price)
    local xPlayer = ESX.GetPlayerFromId(id)
    TriggerClientEvent(Config.Trigger.TriggerNotification, id, (ConfigBoutique.Notification["Ubuy"]):format(tostring(ESX.Math.GroupDigits(price))))
    PlayerCacheBoutique[xPlayer.identifier].points = PlayerCacheBoutique[xPlayer.identifier].points - price

    BoutiqueFunction.SaveData(id, xPlayer.identifier)
end

BoutiqueFunction.addPointsToPlayerReward = function(source, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    PlayerCacheBoutique[xPlayer.identifier].points =  PlayerCacheBoutique[xPlayer.identifier].points + amount
    BoutiqueFunction.SaveData(source, xPlayer.identifier)
    TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Remboursement de coins (Après achats le remboursement par le système)', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '..source..'\nUtilisateur : '..GetPlayerName(source)..'\nLicense : '..ESX.GetPlayerFromId(source).identifier.."\nMontant : "..amount.."\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(source).identifier].points)
end

BoutiqueFunction.addPointsTemporaryToPlayerReward = function(data)
    local source = data.source
    local amount = data.amount

    if data == nil or data.source == nil or data.amount == nil or type(data) ~= "table" or data.ak47danslachatteatamere == nil or data.ak47danslachatteatamere == false then
        ESXCustomServerUtils.rejectSuspiciousAction(source, "Désynchronisation avec le serveur ou Detection de Cheat [GiveCoins]")
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    PlayerCacheBoutique[xPlayer.identifier].points =  PlayerCacheBoutique[xPlayer.identifier].points + amount
    BoutiqueFunction.SaveData(source, xPlayer.identifier)
    TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Remboursement de coins (Après achats le remboursement par le système)', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '..source..'\nUtilisateur : '..GetPlayerName(source)..'\nLicense : '..ESX.GetPlayerFromId(source).identifier.."\nMontant : "..amount.."\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(source).identifier].points)
end

exports("AddCoins", function(data)
    BoutiqueFunction.addPointsTemporaryToPlayerReward(data)
end)

--Trigger
RegisterServerEvent("esx_custom:Boutique:Add")
AddEventHandler("esx_custom:Boutique:Add", function(table)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local name = GetPlayerName(_src)

    if table == nil or type(table) ~= "table" then
        ESXCustomServerUtils.rejectSuspiciousAction(source, 'Désynchronisation avec le serveur ou detection de Cheat [Give boutique]')
        return
    end

    if xPlayer ~= nil then
        if table.Interaction == "GiveVehPack" or table.Interaction == "GiveVehCaisse" then
            table.price = 79329539235472341523467
        end
        if tonumber(table.price) == 79329539235472341523467 or PlayerCacheBoutique[xPlayer.identifier].points >= tonumber(table.price) then
            if tonumber(table.price) >= 0 then
                if table.Interaction == "weapon" then
                    if tonumber(PriceConfigBoutique.weapon[table.id].price) == tonumber(table.price) then
                        if ConfigBoutique.WeaponItem then
                            if GetItemOnPlayer(_src, table.model).count >= 1 then
                                TriggerClientEvent(Config.Trigger.TriggerNotification, _src, (ConfigBoutique.Notification["YouHaveWeapon"]):format(table.Nameweapon))
                            else
                                AddItemOnPlayer(_src, table.model, 1)
                                BoutiqueFunction.removePointsToPlayer(_src, table.price)
                            end
                        else
                            if GetWeaponOnPlayer(_src, table.model) then
                                TriggerClientEvent(Config.Trigger.TriggerNotification, _src, (ConfigBoutique.Notification["YouHaveWeapon"]):format(table.Nameweapon))
                            else
                                addWeaponOnPlayer(_src, table.model, ConfigBoutique.WeaponAmmoInWeapon)
                                BoutiqueFunction.removePointsToPlayer(_src, table.price)
                            end
                        end
                    else
                        DropPlayer(_src, ConfigBoutique.Notification["KickPlayer"])
                    end
                elseif table.Interaction == "vehicle" then
                    if tonumber(PriceConfigBoutique.Vehicle[table.id].price) == tonumber(table.price) then
                        MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, state) VALUES (@owner, @plate, @vehicle, @state)', {
                            ['@owner']   = xPlayer.identifier,
                            ['@plate']   = table.vehicle.plate,
                            ['@vehicle'] = json.encode(table.vehicle),
                            ['@state'] = 1
                        })

                        BoutiqueFunction.removePointsToPlayer(_src, table.price)
                        TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Nouvelle achat', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '.._src..'\nUtilisateur : '..GetPlayerName(_src)..'\nLicense : '..ESX.GetPlayerFromId(_src).identifier.."\nAchat : "..table.veh.."\nPrix : "..table.price.." coins\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(_src).identifier].points)
                    else
                        DropPlayer(_src, ConfigBoutique.Notification["KickPlayer"])
                    end
                elseif table.Interaction == "Moto" then
                    if tonumber(PriceConfigBoutique.Motos[table.id].price) == tonumber(table.price) then
                        MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, state) VALUES (@owner, @plate, @vehicle, @state)', {
                            ['@owner']   = xPlayer.identifier,
                            ['@plate']   = table.vehicle.plate,
                            ['@vehicle'] = json.encode(table.vehicle),
                            ['@state'] = 1
                        })

                        BoutiqueFunction.removePointsToPlayer(_src, table.price)
                        TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Nouvelle achat', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '.._src..'\nUtilisateur : '..GetPlayerName(_src)..'\nLicense : '..ESX.GetPlayerFromId(_src).identifier.."\nAchat : "..table.veh.."\nPrix : "..table.price.." coins\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(_src).identifier].points)
                    else
                        DropPlayer(_src, ConfigBoutique.Notification["KickPlayer"])
                    end
                elseif table.Interaction == "OtherVehicle" then
                    if tonumber(PriceConfigBoutique.Autres[table.id].price) == tonumber(table.price) then
                        MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, state, type) VALUES (@owner, @plate, @vehicle, @state, @type)', {
                            ['@owner']   = xPlayer.identifier,
                            ['@plate']   = table.vehicle.plate,
                            ['@vehicle'] = json.encode(table.vehicle),
                            ['@type'] = table.type or "car",
                            ['@state'] = 1
                        })

                        BoutiqueFunction.removePointsToPlayer(_src, table.price)
                        TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Nouvelle achat', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '.._src..'\nUtilisateur : '..GetPlayerName(_src)..'\nLicense : '..ESX.GetPlayerFromId(_src).identifier.."\nAchat : "..table.veh.."\nPrix : "..table.price.." coins\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(_src).identifier].points)
                    else
                        DropPlayer(_src, ConfigBoutique.Notification["KickPlayer"])
                    end
                elseif table.Interaction == "achatfullcustom" then
                    if tonumber(PriceConfigBoutique.boost[table.id].price) == tonumber(table.price) then
                        BoutiqueFunction.removePointsToPlayer(_src, table.price)
                        TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Nouvelle achat', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '.._src..'\nUtilisateur : '..GetPlayerName(_src)..'\nLicense : '..ESX.GetPlayerFromId(_src).identifier.."\nAchat : Full Custom\nPrix : "..table.price.." coins\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(_src).identifier].points)
                    else
                        DropPlayer(_src, ConfigBoutique.Notification["KickPlayer"])
                    end
                elseif table.Interaction == "entrepriseachat" then
                    if tonumber(PriceConfigBoutique.Entreprise[table.id].price) == tonumber(table.price) then
                        BoutiqueFunction.removePointsToPlayer(_src, table.price)
                        TriggerClientEvent(Config.Trigger.TriggerNotification, _src, ConfigBoutique.Notification["YouBuyEntreprise"])

                        TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Nouvelle achat', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '.._src..'\nUtilisateur : '..GetPlayerName(_src)..'\nLicense : '..ESX.GetPlayerFromId(_src).identifier.."\nAchat : "..table.name.."\nPrix : "..table.price.." coins\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(_src).identifier].points)
                    else
                        DropPlayer(_src, ConfigBoutique.Notification["KickPlayer"])
                    end
                elseif table.Interaction == "giveitem" then
                    if tonumber(PriceConfigBoutique.caisse[table.id].price) == tonumber(table.price) then
                        TriggerClientEvent('esx_custom:openESXCustom', _src, table.item, tonumber(table.price), table.nameitem)
                        BoutiqueFunction.removePointsToPlayer(_src, table.price)
                        TriggerClientEvent(Config.Trigger.TriggerNotification, _src, (ConfigBoutique.Notification["Ubuy2"]):format(table.nameitem))

                        -- TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Nouvelle achat', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '.._src..'\nUtilisateur : '..GetPlayerName(_src)..'\nLicense : '..ESX.GetPlayerFromId(_src).identifier.."\nAchat : "..table.nameitem.."\nPrix : "..table.price.."\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(_src).identifier].points)
                    else
                        DropPlayer(_src, ConfigBoutique.Notification["KickPlayer"])
                    end
                elseif table.Interaction == "BuyPack" then
                    if tonumber(PriceConfigBoutique.pack[table.id].price) == tonumber(table.price) then
                        BoutiqueFunction.removePointsToPlayer(_src, table.price)

                        TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Nouvelle achat', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '.._src..'\nUtilisateur : '..GetPlayerName(_src)..'\nLicense : '..ESX.GetPlayerFromId(_src).identifier.."\nAchat : "..PriceConfigBoutique.pack[table.id].name.."\nPrix : "..table.price.." coins\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(_src).identifier].points)
                    else
                        DropPlayer(_src, ConfigBoutique.Notification["KickPlayer"])
                    end
                elseif table.Interaction == "GiveVehPack" then
                    if tonumber(table.price) == 79329539235472341523467 then
                        MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, state) VALUES (@owner, @plate, @vehicle, @state)', {
                            ['@owner']   = xPlayer.identifier,
                            ['@plate']   = table.plate_625,
                            ['@vehicle'] = json.encode(table.vehicleProps),
                            ['@state'] = 1
                        })
                    
                        MySQL.Async.execute('INSERT INTO open_car (label, value, NB, got, identifier) VALUES (@label, @value, @NB, @got, @identifier)', {
                            ['@label']		  = 'Cles',
                            ['@value']  	  = table.plate_625,
                            ['@NB']   		  = 3,
                            ['@got']  		  = 'true',
                            ['@identifier']   = xPlayer.identifier
                        })
                    else
                        DropPlayer(_src, ConfigBoutique.Notification["KickPlayer"])
                    end
                elseif table.Interaction == "GiveVehCaisse" then
                    if tonumber(table.price) == 79329539235472341523467 then
                        MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)', {
                            ['@owner']   = xPlayer.identifier,
                            ['@plate']   = table.plate_625,
                            ['@vehicle'] = json.encode(table.vehicleProps),
                            ['@state'] = 1
                        })
                    
                        MySQL.Async.execute('INSERT INTO open_car (label, value, NB, got, identifier) VALUES (@label, @value, @NB, @got, @identifier)', {
                            ['@label']		  = 'Cles',
                            ['@value']  	  = table.plate_625,
                            ['@NB']   		  = 3,
                            ['@got']  		  = 'true',
                            ['@identifier']   = xPlayer.identifier
                        })
                        TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Nouvelle achat', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '.._src..'\nUtilisateur : '..GetPlayerName(_src)..'\nLicense : '..ESX.GetPlayerFromId(_src).identifier.."\nAchat : Caisse\nGains : "..table.vehicleProps.model.."\nPrix : "..table.price.." coins\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(_src).identifier].points)
                    else
                        DropPlayer(_src, ConfigBoutique.Notification["KickPlayer"])
                    end
                elseif table.Interaction == "CustomWeapon" then
                    xPlayer.addWeaponComponent(table.weaponName, table.name)
                    BoutiqueFunction.removePointsToPlayer(_src, table.price)

                    TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Nouvelle achat', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '.._src..'\nUtilisateur : '..GetPlayerName(_src)..'\nLicense : '..ESX.GetPlayerFromId(_src).identifier.."\nAchat : Custom Weapon\nComposant de l'armes : "..table.name.."\nPrix : "..table.price.." coins\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(_src).identifier].points)
                else
                    DropPlayer(_src, ConfigBoutique.Notification["KickPlayer"])
                end
            else
                DropPlayer(_src, ConfigBoutique.Notification["KickPlayer"])
            end
        else
            TriggerClientEvent(Config.Trigger.TriggerNotification, _src, ConfigBoutique.Notification["NoCoins"])
        end
    else
        DropPlayer(_src, ConfigBoutique.Notification["KickPlayer"])
    end
end)

RegisterServerEvent('ESXCustomBoutique:giveReward')
AddEventHandler('ESXCustomBoutique:giveReward', function (t, data, amount, nameCaisse)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	if t == "item" then
		AddItemOnPlayer(_source, data, amount)
        TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Nouvelle caisse ouverte', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '.._source..'\nUtilisateur : '..GetPlayerName(_source)..'\nLicense : '..ESX.GetPlayerFromId(_source).identifier.."\nAchat : "..nameCaisse.name.."\nGains : x"..amount..data.." item\nPrix : "..nameCaisse.price.." coins\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(_source).identifier].points)
	elseif t == "weapon" then
        if ConfigBoutique.WeaponItem then
            AddItemOnPlayer(_source, data, 1)
            TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Nouvelle caisse ouverte', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '.._source..'\nUtilisateur : '..GetPlayerName(_source)..'\nLicense : '..ESX.GetPlayerFromId(_source).identifier.."\nAchat : "..nameCaisse.name.."\nGains : "..data.."\nPrix : "..nameCaisse.price.." coins\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(_source).identifier].points)
        else
            if GetWeaponOnPlayer(_source, data) then
                TriggerClientEvent(Config.Trigger.TriggerNotification, _source, (ConfigBoutique.Notification["YouHaveWeapon"]):format(data))
                BoutiqueFunction.addPointsToPlayerReward(source, amount)
                TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Nouvelle caisse ouverte', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '.._source..'\nUtilisateur : '..GetPlayerName(_source)..'\nLicense : '..ESX.GetPlayerFromId(_source).identifier.."\nAchat : "..nameCaisse.name.."\nGains : **Rembourser car il a déjà cette armes**\nPrix : "..nameCaisse.price.." coins\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(_source).identifier].points)
            else
                addWeaponOnPlayer(_source, data, ConfigBoutique.WeaponAmmoInWeapon)
                TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Nouvelle caisse ouverte', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '.._source..'\nUtilisateur : '..GetPlayerName(_source)..'\nLicense : '..ESX.GetPlayerFromId(_source).identifier.."\nAchat : "..nameCaisse.name.."\nGains : "..data.."\nPrix : "..nameCaisse.price.." coins\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(_source).identifier].points)
            end
        end
	elseif t == "Coins" then
        BoutiqueFunction.addPointsToPlayerReward(source, data)
        TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Nouvelle caisse ouverte', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '.._source..'\nUtilisateur : '..GetPlayerName(_source)..'\nLicense : '..ESX.GetPlayerFromId(_source).identifier.."\nAchat : "..nameCaisse.name.."\nGains : "..data.." coins\nPrix : "..nameCaisse.price.." coins\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(_source).identifier].points)
	elseif t == "money" then
		AddMoney(_source, data)
        TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Nouvelle caisse ouverte', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '.._source..'\nUtilisateur : '..GetPlayerName(_source)..'\nLicense : '..ESX.GetPlayerFromId(_source).identifier.."\nAchat : "..nameCaisse.name.."\nGains : "..data.."$ argent\nPrix : "..nameCaisse.price.." coins\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(_source).identifier].points)
	elseif t == "black_money" then
		AddBlackMoneyOnPlayer(_source, data)
        TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Nouvelle caisse ouverte', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '.._source..'\nUtilisateur : '..GetPlayerName(_source)..'\nLicense : '..ESX.GetPlayerFromId(_source).identifier.."\nAchat : "..nameCaisse.name.."\nGains : "..data.."$ argent sale\nPrix : "..nameCaisse.price.." coins\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(_source).identifier].points)
    elseif t == "Vehicle" then
        TriggerEvent('esx:customDiscordLog', 'Logs boutique', 'Nouvelle caisse ouverte', nil, ConfigSV.Logs["LogsBoutique"], 'ID : '.._source..'\nUtilisateur : '..GetPlayerName(_source)..'\nLicense : '..ESX.GetPlayerFromId(_source).identifier.."\nAchat : "..nameCaisse.name.."\nGains véhicule : "..data.."\nPrix : "..nameCaisse.price.." coins\nCoins Actuelle : "..PlayerCacheBoutique[ESX.GetPlayerFromId(_source).identifier].points)
    end
end)

--Commande
RegisterCommand(ConfigBoutique.Commande.CommandeGiveViaIDIG, function(source, args, raw)
    if source ~= 0 then
        if ConfigBoutique.PermissionAllowed[ESXCustom_Function_ServerSide:getLicense(source)] then
            if args[1] == nil then
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigBoutique.Notification["Error"])
                return
            end

            if args[2] == nil then
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigBoutique.Notification["Error2"])
                return
            end

            local id    = args[1]
            local point = args[2]
            local xPlayer = ESX.GetPlayerFromId(id)
            local xPlayerSource = ESX.GetPlayerFromId(source)

            if xPlayer == nil then
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigBoutique.Notification["Error3"])
                return
            end

            if PlayerCacheBoutique[xPlayer.identifier] == nil then
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigBoutique.Notification["Error4"])
                return
            end
            TriggerClientEvent(Config.Trigger.TriggerNotification, id, (ConfigBoutique.Notification["ReceiveCoins"]):format(point))
            PlayerCacheBoutique[xPlayer.identifier].points = PlayerCacheBoutique[xPlayer.identifier].points + point
            BoutiqueFunction.SaveData(id, xPlayer.identifier)
            PerformHttpRequest(discord_webhook.url, function(err, text, headers) end, 'POST', json.encode({username = "", content = ("[**%s**] à reçu des coins par : %s : __%s Coins__ est en a désormais : __%s__"):format(xPlayer.getName(), xPlayerSource.getName(), point, PlayerCacheBoutique[xPlayer.identifier].points)}), { ['Content-Type'] = 'application/json' })
        else
            TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigBoutique.Notification["Error5"])
        end
    else
        if args[1] == nil then
            print(ConfigBoutique.Notification["Error"])
            return
        end

        if args[2] == nil then
            print(ConfigBoutique.Notification["Error2"])
            return
        end

        local id    = args[1]
        local point = args[2]
        local xPlayer = ESX.GetPlayerFromId(id)

        if xPlayer == nil then
            print(ConfigBoutique.Notification["Error3"])
            return
        end

        if PlayerCacheBoutique[xPlayer.identifier] == nil then
            print(ConfigBoutique.Notification["Error4"])
            return
        end
        TriggerClientEvent(Config.Trigger.TriggerNotification, id, (ConfigBoutique.Notification["ReceiveCoins"]):format(point))
        PlayerCacheBoutique[xPlayer.identifier].points = PlayerCacheBoutique[xPlayer.identifier].points + point
        BoutiqueFunction.SaveData(id, xPlayer.identifier)

        PerformHttpRequest(discord_webhook.url, function(err, text, headers) end, 'POST', json.encode({username = "", content = ("[**%s**] à reçu des coins par : %s : __%s Coins__ est en a désormais : __%s__"):format(xPlayer.getName(), "Console", point, PlayerCacheBoutique[xPlayer.identifier].points)}), { ['Content-Type'] = 'application/json' })
    end
end, false)

RegisterCommand(ConfigBoutique.Commande.CommandeGiveViaBoutiqueID, function(source, args, raw)
    if source ~= 0 then
        if ConfigBoutique.PermissionAllowed[ESXCustom_Function_ServerSide:getLicense(source)] then
            if args[1] == nil then
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigBoutique.Notification["Error"])
                return
            end

            if args[2] == nil then
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigBoutique.Notification["Error2"])
                return
            end

            local id = args[1]
            local point = args[2]
            local xPlayer = ESX.GetPlayerFromId(source)

            if PlayerCacheBoutique2[tonumber(id)] == nil then
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigBoutique.Notification["Error6"])
                return
            end

            local xPlayerReceive = PlayerCacheBoutique2[tonumber(id)].identifier
            PlayerCacheBoutique[xPlayerReceive].points = PlayerCacheBoutique[xPlayerReceive].points + point
            BoutiqueFunction.SaveData(PlayerCacheBoutique[xPlayerReceive].SourceID, xPlayerReceive)

            PerformHttpRequest(discord_webhook.url, function(err, text, headers) end, 'POST', json.encode({username = "", content = ("[**%s**] à reçu des coins par : %s : __%s Coins__ est en a désormais : __%s__"):format(xPlayerReceive, xPlayer.getName(), point, PlayerCacheBoutique[xPlayerReceive].points)}), { ['Content-Type'] = 'application/json' })
        else
            TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigBoutique.Notification["Error5"])
        end
    else
        if args[1] == nil then
            print(ConfigBoutique.Notification["Error"])
            return
        end
    
        if args[2] == nil then
            print(ConfigBoutique.Notification["Error2"])
            return
        end
    
        local id = args[1]
        local point = args[2]
    
        if PlayerCacheBoutique2[tonumber(id)] == nil then
            print(ConfigBoutique.Notification["Error6"])
            return
        end
    
        local xPlayerReceive = PlayerCacheBoutique2[tonumber(id)].identifier
        PlayerCacheBoutique[xPlayerReceive].points = PlayerCacheBoutique[xPlayerReceive].points + tonumber(point)
        BoutiqueFunction.SaveData(PlayerCacheBoutique[xPlayerReceive].SourceID, xPlayerReceive)

        PerformHttpRequest(discord_webhook.url, function(err, text, headers) end, 'POST', json.encode({username = "", content = ("[**%s**] à reçu des coins par : %s : __%s Coins__ est en a désormais : __%s__"):format(xPlayerReceive, "Console", point, PlayerCacheBoutique[xPlayerReceive].points)}), { ['Content-Type'] = 'application/json' })
    end
end, false)

-- RegisterCommand(ConfigBoutique.Commande.CommandeRemoveCoins, function(source, args, raw)
--     if source ~= 0 then
--         if ConfigBoutique.PermissionAllowed[ESXCustom_Function_ServerSide:getLicense(source)] then
--             if args[1] == nil then
--                 TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigBoutique.Notification["Error"])
--                 return
--             end

--             if args[2] == nil then
--                 TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigBoutique.Notification["Error2"])
--                 return
--             end

--             local id = args[1]
--             local point = args[2]
--             local xPlayer = ESX.GetPlayerFromId(id)
--             local xPlayerSource = ESX.GetPlayerFromId(source)

--             if xPlayer == nil then
--                 TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigBoutique.Notification["Error3"])
--                 return
--             end

--             if PlayerCacheBoutique[xPlayer.identifier] == nil then
--                 TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigBoutique.Notification["Error4"])
--                 return
--             end
            
--             PlayerCacheBoutique[xPlayer.identifier].points = PlayerCacheBoutique[xPlayer.identifier].points - point

--             TriggerClientEvent(Config.Trigger.TriggerNotification, source, (ConfigBoutique.Notification["ClearCoins"]):format(point, id))
--             PerformHttpRequest(discord_webhook.url, function(err, text, headers) end, 'POST', json.encode({username = "", content = ("[**%s**] à perdu des coins par : %s : __%s Coins__ est en a désormais : __%s__"):format(xPlayer.getName(), xPlayerSource.getName(), point, PlayerCacheBoutique[xPlayer.identifier].points)}), { ['Content-Type'] = 'application/json' })
--         else
--             TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigBoutique.Notification["Error5"])
--         end
--     else
--         if args[1] == nil then
--             print(ConfigBoutique.Notification["Error"])
--             return
--         end
    
--         if args[2] == nil then
--             print(ConfigBoutique.Notification["Error2"])
--             return
--         end
    
--         local id = args[1]
--         local point = args[2]
--         local xPlayer = ESX.GetPlayerFromId(id)
    
--         if xPlayer == nil then
--             print(ConfigBoutique.Notification["Error3"])
--             return
--         end
    
--         if PlayerCacheBoutique[xPlayer.identifier] == nil then
--             print(ConfigBoutique.Notification["Error4"])
--             return
--         end
        
--         PlayerCacheBoutique[xPlayer.identifier].points = PlayerCacheBoutique[xPlayer.identifier].points - point
--         print((ConfigBoutique.Notification["ClearCoins"]):format(point, id))
--         PerformHttpRequest(discord_webhook.url, function(err, text, headers) end, 'POST', json.encode({username = "", content = ("[**%s**] à perdu des coins par : %s : __%s Coins__ est en a désormais : __%s__"):format(xPlayer.getName(), "Console", point, PlayerCacheBoutique[xPlayer.identifier].points)}), { ['Content-Type'] = 'application/json' })
--     end
-- end, false)

FetchCoins = function(source)
    return PlayerCacheBoutique[ESX.GetPlayerFromId(source).identifier]
end

RegisterNetEvent("esx_custom:Boutique:Remove", function(data)
    local xPlayer = ESX.GetPlayerFromId(source)

    if data == nil then
        ESXCustomServerUtils.rejectSuspiciousAction(source, 'Désynchronisation avec le serveur ou detection de Cheat [Data Boutique Nil]')
        return
    end

    if data.anticheat == nil or data.anticheat ~= true then
        ESXCustomServerUtils.rejectSuspiciousAction(source, 'Désynchronisation avec le serveur ou detection de Cheat [Data Boutique]')
        return
    end

    if data.price == nil or data.price == 0 then
        ESXCustomServerUtils.rejectSuspiciousAction(source, 'Désynchronisation avec le serveur ou detection de Cheat [Data Boutique Price]')
        return
    end

    if xPlayer == nil then
        ESXCustomServerUtils.rejectSuspiciousAction(source, 'Désynchronisation avec le serveur ou detection de Cheat [Data Boutique Source Nil]')
        return
    end

    VerifyToken(source, function()
        if FetchCoins(source).points >= tonumber(data.price) then
            TriggerEvent('esx:customDiscordLog', ConfigSV.Logs["CustomVehicle"].Title, ConfigSV.Logs["CustomVehicle"].Nom, ConfigSV.Logs["CustomVehicle"].Color or nil, ConfigSV.Logs["CustomVehicle"].Webhook, "ID : **"..source.."**\nUtilisateur : **"..GetPlayerName(source).."**\nLicense : **"..ESX.GetPlayerFromId(source).identifier.."**\nPrix : **"..data.price.."**\nBoutique ID : **"..PlayerCacheBoutique[ESX.GetPlayerFromId(source).identifier].boutique_id.."**\nCoins avant achat : **"..PlayerCacheBoutique[ESX.GetPlayerFromId(source).identifier].points.."** coins\nCoins après achat : **"..(PlayerCacheBoutique[ESX.GetPlayerFromId(source).identifier].points - data.price).."** coins")
            BoutiqueFunction.removePointsToPlayer(source, data.price)
        else
			TriggerClientEvent(Config.Trigger.TriggerNotification, source, "~r~Vous ne possédez pas assez de coins nécessaires pour payer ceci.~s~")
        end
    end)
end)