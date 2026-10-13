VehCoffre = {}
local OwnerVeh = {}
CoffreLoad = false 
CoffreLoadNumber = 0
CreateThread(function()
	Wait(1500)
	if Config.Debug then
        print('ESXCustom : Initialisation des coffres...')
    end
    MySQL.Async.fetchAll("SELECT * FROM coffre_veh", {}, function(result)
        for k, v in pairs(result) do 
            CoffreLoadNumber = CoffreLoadNumber +1
            local InfoVeh = json.decode(v.info)
            if not VehCoffre[InfoVeh.plate] then 
                VehCoffre[InfoVeh.plate] = {}
                VehCoffre[InfoVeh.plate].id = v.id
                VehCoffre[InfoVeh.plate].infos = InfoVeh
                v.data = json.decode(v.data)
                if v.data ~= nil and v.data.accounts then
                    -- Compatibilité des anciens coffres sans conserver d'alias pendant le gameplay.
                    v.data.accounts.money = tonumber(v.data.accounts.money or v.data.accounts.cash) or 0
                    v.data.accounts.black_money = tonumber(v.data.accounts.black_money or v.data.accounts.dirtycash or v.data.accounts.dirtymoney) or 0
                    v.data.accounts.cash = nil
                    v.data.accounts.dirtycash = nil
                    v.data.accounts.dirtymoney = nil
                end
                if v.data ~= nil then 
                    if v.data["items"] ~= nil then 
                        VehCoffre[InfoVeh.plate].data = v.data 
                    else
                        VehCoffre[InfoVeh.plate].data = v.data 
                        VehCoffre[InfoVeh.plate].data["weapons"] = {}
                    end
                else
                    VehCoffre[InfoVeh.plate].data = {
                        ["weapons"] = {},
                        ["items"] = {},
                        ['accounts'] = {
                            money = 0,
                            black_money = 0
                        },
                    }
                end
            end
        end
        CoffreLoad = true 
		if Config.Debug then
			print('[^5LOAD^0] [^5'..CoffreLoadNumber..'^0] coffre de véhicule ont été load avec succès !')
		 end
    end)   

    MySQL.Async.fetchAll("SELECT * FROM owned_vehicles", {}, function(result)
        for k, v in pairs(result) do 
            if not OwnerVeh[v.plate] then 
                OwnerVeh[v.plate] = {}
                OwnerVeh[v.plate].plate = v.plate 
                OwnerVeh[v.plate].owner = v.owner 
            end
        end
    end)
end)

RegisterNetEvent("ESXCustomCoffre:recievecoffrevehserverside", function(plate)
    if VehCoffre[plate] then
        TriggerClientEvent("ESXCustomCoffre:recievecoffrevehclientside", source, VehCoffre[plate] )
    else
        return
    end
end)

CreateThread(function()
    while not CoffreLoad do 
        Wait(1)
    end
    local CunterSave = 0
    while true do 
        for k, v in pairs(VehCoffre) do 
            MySQL.Sync.execute("UPDATE coffre_veh set info = @info, data = @data WHERE id = @id", {
                ["@id"] = v.id,
                ["@info"] = json.encode(v.infos),
                ["@data"] = json.encode(v.data)
            })
        end
        CunterSave = CunterSave + 1
        Wait(5*60000)
        if Config.Debug then
            print("[^4"..CunterSave.."^0] Save de coffre de véhicule effecutée !")
        end
    end
end)

CreateVehToBdd = function(plate, class)
    local xPlayer = ESX.GetPlayerFromId(source)
    local NewId = math.random(0, 999999)
    local Infos = {
        plate = plate,
        maxweight = ConfigVehicleCoffre.WeightWeh[class],
        weight = 0
    }
    VehCoffre[plate] = {}
    VehCoffre[plate].plate = plate 
    VehCoffre[plate].id = NewId 
    VehCoffre[plate].infos = Infos 
    VehCoffre[plate].data = {
        ["weapons"] = {},
        ["items"] = {},
        ['accounts'] = {
            money = 0,
            black_money = 0
        },
    }
    MySQL.Async.execute("INSERT INTO coffre_veh (info, id) VALUES (@info, @id)", {
        ["@info"] = json.encode(Infos),
        ["@id"] = NewId
    })
    return true 
end

RegisterNetEvent("ESXCustomCoffre:actionsitemveh", function(plate, class, action, count, name)
    local xPlayer = ESX.GetPlayerFromId(source)
    VerifyToken(source, function()
        local VerifExistPlate = VehCoffre[plate] ~= nil and true or false 
        local VehNoOwner = OwnerVeh[plate] ~= nil and true or false 
        if VehNoOwner then 
            if xPlayer.identifier == OwnerVeh[plate].owner then 
                OwnerofVeh = true
            else
                OwnerofVeh = false 
            end
        end

        if not ConfigVehicleCoffre.JustForOwner then
            OwnerofVeh = true 
        end

        local InfoItem = GetItemOnPlayer(source, name)
        if action == "deposit" then 
            if OwnerofVeh == false then 
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous ne pouvez pas déposer d'item dans le coffre de ce véhicule")
                return
            end
            if InfoItem.count >= tonumber(count) then 
                if not VerifExistPlate then 
                    local CreateVeh = CreateVehToBdd(plate, class)
                    if CreateVeh then 
                        -- local VerifWeigt = tonumber(VehCoffre[plate].infos.weight) + tonumber(InfoItem.weight*count) <= VehCoffre[plate].infos.maxweight and true or false
                        local VerifWeigt = tonumber(VehCoffre[plate].infos.weight) + tonumber(InfoItem.weight*count) <= ConfigVehicleCoffre.WeightWeh[class] and true or false
                        if VerifWeigt then 
                            VehCoffre[plate].data["items"][InfoItem.name] = {}
                            VehCoffre[plate].data["items"][InfoItem.name].name = InfoItem.name 
                            VehCoffre[plate].data["items"][InfoItem.name].label = InfoItem.label 
                            VehCoffre[plate].data["items"][InfoItem.name].weight = tonumber(InfoItem.weight*count)
                            VehCoffre[plate].data["items"][InfoItem.name].count = tonumber(count)
                            VehCoffre[plate].infos.weight = tonumber(VehCoffre[plate].infos.weight) + tonumber(InfoItem.weight*count)
                            RemoveItemOnPlayer(source, name, count)
                            TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous venez de déposé ~b~x"..count.." "..InfoItem.label.."~s~ dans le coffre du véhicule")
                            TriggerClientEvent("ESXCustomCoffre:recievecoffrevehclientside", source, VehCoffre[plate])
                        else
                            TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Le coffre ne dispose pas d'asser de place pour déposer autant de ~b~"..InfoItem.label)
                        end
                    end
                else
                    -- local VerifWeigt = tonumber(VehCoffre[plate].infos.weight) + tonumber(InfoItem.weight*count) <= VehCoffre[plate].infos.maxweight and true or false
                    local VerifWeigt = tonumber(VehCoffre[plate].infos.weight) + tonumber(InfoItem.weight*count) <= ConfigVehicleCoffre.WeightWeh[class] and true or false
                    if VerifWeigt then 
                        if VehCoffre[plate].data["items"][InfoItem.name] then 
                            VehCoffre[plate].data["items"][InfoItem.name].weight = VehCoffre[plate].data["items"][InfoItem.name].weight + tonumber(InfoItem.weight*count)
                            VehCoffre[plate].data["items"][InfoItem.name].count = VehCoffre[plate].data["items"][InfoItem.name].count + tonumber(count)
                            VehCoffre[plate].infos.weight = tonumber(VehCoffre[plate].infos.weight) + tonumber(InfoItem.weight*count)
                        else
                            VehCoffre[plate].data["items"][InfoItem.name] = {}
                            VehCoffre[plate].data["items"][InfoItem.name].name = InfoItem.name 
                            VehCoffre[plate].data["items"][InfoItem.name].label = InfoItem.label 
                            VehCoffre[plate].data["items"][InfoItem.name].weight = tonumber(InfoItem.weight*count)
                            VehCoffre[plate].data["items"][InfoItem.name].count = tonumber(count)
                            VehCoffre[plate].infos.weight = tonumber(VehCoffre[plate].infos.weight) + tonumber(InfoItem.weight*count)
                            TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous venez de déposé ~b~x"..count.." "..InfoItem.label.."~s~ dans le coffre du véhicule")
                        end
                        RemoveItemOnPlayer(source, name, count)
                        TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous venez de déposé ~b~x"..count.." "..InfoItem.label.."~s~ dans le coffre du véhicule")
                        TriggerClientEvent("ESXCustomCoffre:recievecoffrevehclientside", source, VehCoffre[plate])
                    else
                        TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Le coffre ne dispose pas d'asser de place pour déposer autant de ~b~"..InfoItem.label)
                    end
                end
            else
                return ESXCustomServerUtils.rejectSuspiciousAction(source, 'Désynchronisation avec le serveur ou detection de Cheat')
            end
        elseif action == "remove" then 
            if OwnerofVeh == false then 
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous ne pouvez pas retirer d'item dans le coffre de ce véhicule")
                return
            end
            if xPlayer.canCarryItem(InfoItem.name, count) then 
                if VehCoffre[plate].data["items"][InfoItem.name] ~= nil then 
                    if VehCoffre[plate].data["items"][InfoItem.name].count >= tonumber(count) then 
                        VehCoffre[plate].data["items"][InfoItem.name].count = VehCoffre[plate].data["items"][InfoItem.name].count - tonumber(count)
                        VehCoffre[plate].data["items"][InfoItem.name].weight = VehCoffre[plate].data["items"][InfoItem.name].weight - tonumber(InfoItem.weight*count)
                        VehCoffre[plate].infos.weight = tonumber(VehCoffre[plate].infos.weight) - tonumber(InfoItem.weight*count)
                        TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous venez de retiré ~g~x"..count.." "..InfoItem.label.."~s~ du coffre du véhicule")
                        AddItemOnPlayer(source, InfoItem.name, count)
                    
                        if VehCoffre[plate].data["items"][InfoItem.name].count == 0 then 
                            VehCoffre[plate].data["items"][InfoItem.name] = nil 
                        end
                        TriggerClientEvent("ESXCustomCoffre:recievecoffrevehclientside", source, VehCoffre[plate])
                    else
                        return ESXCustomServerUtils.rejectSuspiciousAction(source, 'Désynchronisation avec le serveur ou detection de Cheat')
                    end
                else
                    return ESXCustomServerUtils.rejectSuspiciousAction(source, 'Désynchronisation avec le serveur ou detection de Cheat')
                end
            else
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous êtes trop lourd !")
            end
        end
    end)
end)

RegisterNetEvent("ESXCustomCoffre:actionsweaponsveh", function(plate, class, action, name, ammo, label, id)
    local xPlayer = ESX.GetPlayerFromId(source)

    VerifyToken(source, function()
        local VerifExistPlate = VehCoffre[plate] ~= nil and true or false 
        local VehNoOwner = OwnerVeh[plate] ~= nil and true or false 
        if VehNoOwner then 
            if xPlayer.identifier == OwnerVeh[plate].owner then 
                OwnerofVeh = true 
            else
                OwnerofVeh = false 
            end
        end

        if not ConfigVehicleCoffre.JustForOwner then
            OwnerofVeh = true 
        end

        local InfoWeapon = xPlayer.getWeapon(name)
        if action == "deposit" then 
            if OwnerofVeh == false then 
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous ne pouvez pas déposer d'item dans le coffre de ce véhicule")
                return
            end
            if InfoWeapon > 0 then 
                if not VerifExistPlate then 
                    local CreateVeh = CreateVehToBdd(plate, class)
                    if CreateVeh then 
                        if ConfigVehicleCoffre.WeaponWeight[name] == nil then 
                            TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous ne pouvez pas déposer cette arme dans le coffre de ce véhicule")
                            return;
                        end

                        -- local VerifWeigt = tonumber(VehCoffre[plate].infos.weight) + tonumber(ConfigVehicleCoffre.WeaponWeight[name]) <= VehCoffre[plate].infos.maxweight and true or false
                        local VerifWeigt = tonumber(VehCoffre[plate].infos.weight) + tonumber(ConfigVehicleCoffre.WeaponWeight[name]) <= ConfigVehicleCoffre.WeightWeh[class] and true or false
                        if VerifWeigt then 
                            if not VehCoffre[plate].data["weapons"][name] then 
                                VehCoffre[plate].data["weapons"][name] = {}
                                VehCoffre[plate].data["weapons"][name].name = name 
                                VehCoffre[plate].data["weapons"][name].ammo = ammo 
                                VehCoffre[plate].data["weapons"][name].label = label 
                                VehCoffre[plate].data["weapons"][name].weight = tonumber(ConfigVehicleCoffre.WeaponWeight[name])
                                VehCoffre[plate].data["weapons"][name].count = 1
                                VehCoffre[plate].infos.weight = tonumber(VehCoffre[plate].infos.weight) + tonumber(ConfigVehicleCoffre.WeaponWeight[name])
                            end
                            removeWeaponOnPlayer(source, name)
                            TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous venez de déposé ~b~x1 "..label.."~s~ dans le coffre du véhicule")
                            TriggerClientEvent("ESXCustomCoffre:recievecoffrevehclientside", source, VehCoffre[plate])
                        else
                            TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Le coffre ne dispose pas d'asser de place pour déposer autant de ~b~"..label)
                        end
                    end
                else
                    if ConfigVehicleCoffre.WeaponWeight[name] == nil then 
                        TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous ne pouvez pas déposer cette arme dans le coffre de ce véhicule")
                        return;
                    end

                    -- local VerifWeigt = tonumber(VehCoffre[plate].infos.weight) + tonumber(ConfigVehicleCoffre.WeaponWeight[name]) <= VehCoffre[plate].infos.maxweight and true or false
                    local VerifWeigt = tonumber(VehCoffre[plate].infos.weight) + tonumber(ConfigVehicleCoffre.WeaponWeight[name]) <= ConfigVehicleCoffre.WeightWeh[class] and true or false
                    if VerifWeigt then 
                        if VehCoffre[plate].data["weapons"][name] then 
                            VehCoffre[plate].data["weapons"][name].weight =  VehCoffre[plate].data["weapons"][name].weight+ tonumber(ConfigVehicleCoffre.WeaponWeight[name]) 
                            VehCoffre[plate].data["weapons"][name].count = VehCoffre[plate].data["weapons"][name].count + 1
                            VehCoffre[plate].infos.weight = tonumber(VehCoffre[plate].infos.weight) + tonumber(ConfigVehicleCoffre.WeaponWeight[name])
                        else
                            VehCoffre[plate].data["weapons"][name] = {}
                            VehCoffre[plate].data["weapons"][name].name = name 
                            VehCoffre[plate].data["weapons"][name].ammo = ammo 
                            VehCoffre[plate].data["weapons"][name].label = label 
                            VehCoffre[plate].data["weapons"][name].weight = tonumber(ConfigVehicleCoffre.WeaponWeight[name])
                            VehCoffre[plate].data["weapons"][name].count = 1
                            VehCoffre[plate].infos.weight = tonumber(VehCoffre[plate].infos.weight) + tonumber(ConfigVehicleCoffre.WeaponWeight[name])
                        end
                        removeWeaponOnPlayer(source, name)
                        TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous venez de déposé ~b~x1 "..label.."~s~ dans le coffre du véhicule")
                        TriggerClientEvent("ESXCustomCoffre:recievecoffrevehclientside", source, VehCoffre[plate])
                    else
                        TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Le coffre ne dispose pas d'asser de place pour déposer autant de ~b~"..label)
                    end
                end
            else
                return ESXCustomServerUtils.rejectSuspiciousAction(source, 'Désynchronisation avec le serveur ou detection de Cheat')
            end
        elseif action == "remove" then 
            if OwnerofVeh == false then 
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous ne pouvez pas retirer d'item dans le coffre de ce véhicule")
                return
            end
            
            if VehCoffre[plate].data["weapons"][name] ~= nil then  
                if VehCoffre[plate].data["weapons"][name].count >= tonumber(ammo) then 
                    VehCoffre[plate].data["weapons"][name].count = VehCoffre[plate].data["weapons"][name].count - tonumber(ammo)
                    VehCoffre[plate].data["weapons"][name].weight = VehCoffre[plate].data["weapons"][name].weight - tonumber(ConfigVehicleCoffre.WeaponWeight[name]*ammo)
                    VehCoffre[plate].infos.weight = tonumber(VehCoffre[plate].infos.weight) - tonumber(ConfigVehicleCoffre.WeaponWeight[name]*ammo)
                    addWeaponOnPlayer(source, name, VehCoffre[plate].data["weapons"][name].ammo)
                    TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous venez de retiré ~g~x"..tostring(ammo).." "..label.."~s~ du coffre du véhicule")
                    if VehCoffre[plate].data["weapons"][name].count == 0 then 
                        VehCoffre[plate].data["weapons"][name] = nil 
                    end
                    TriggerClientEvent("ESXCustomCoffre:recievecoffrevehclientside", source, VehCoffre[plate])
                else
                    return ESXCustomServerUtils.rejectSuspiciousAction(source, 'Désynchronisation avec le serveur ou detection de Cheat')
                end
            else
                return ESXCustomServerUtils.rejectSuspiciousAction(source, 'Désynchronisation avec le serveur ou detection de Cheat')
            end
        end
    end)
end)

RegisterNetEvent("ESXCustomCoffre:actionsargentveh", function(plate, class, action, count, typee)
    local xPlayer = ESX.GetPlayerFromId(source)

    VerifyToken(source, function()
        local VerifExistPlate = VehCoffre[plate] ~= nil and true or false 
        local VehNoOwner = OwnerVeh[plate] ~= nil and true or false 
        if VehNoOwner then 
            if xPlayer.identifier == OwnerVeh[plate].owner then 
                OwnerofVeh = true 
            else
                OwnerofVeh = false 
            end
        end

        if not ConfigVehicleCoffre.JustForOwner then
            OwnerofVeh = true 
        end

        if action == "deposit" then 
            if OwnerofVeh == false then 
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous ne pouvez pas déposer d'item dans le coffre de ce véhicule")
                return
            end
            if typee == "money" then
                if GetMoney(source) >= tonumber(count) then 
                    if not VerifExistPlate then 
                        local CreateVeh = CreateVehToBdd(plate, class)
                        if CreateVeh then 
                            if VehCoffre[plate].data["accounts"][typee] then 
                                VehCoffre[plate].data["accounts"][typee] = VehCoffre[plate].data["accounts"][typee] + tonumber(count)
                            end
                            RemoveMoneyOnPlayer(source, count)
                            TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous venez de déposé ~b~ "..count.." $~s~ dans le coffre du véhicule")
                            TriggerClientEvent("ESXCustomCoffre:recievecoffrevehclientside", source, VehCoffre[plate])
                        end
                    else
                        if VehCoffre[plate].data["accounts"][typee] then 
                            VehCoffre[plate].data["accounts"][typee] = VehCoffre[plate].data["accounts"][typee] + tonumber(count)
                        end
                        RemoveMoneyOnPlayer(source, count)
                        TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous venez de déposé ~b~ "..count.." $~s~ dans le coffre du véhicule")
                        TriggerClientEvent("ESXCustomCoffre:recievecoffrevehclientside", source, VehCoffre[plate])    
                    end
                else
                    TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous n'avez pas les fonds nécéssaire pour faire cela")
                end
            else
                if GetBlackMoneyOnPlayer(source) >= tonumber(count) then 
                    if not VerifExistPlate then 
                        local CreateVeh = CreateVehToBdd(plate, class)
                        if CreateVeh then 
                            if VehCoffre[plate].data["accounts"][typee] then 
                                VehCoffre[plate].data["accounts"][typee] = VehCoffre[plate].data["accounts"][typee] + tonumber(count)
                            end
                            RemoveBlackMoneyOnPlayer(source, count)
                            TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous venez de déposé ~b~ "..count.." $~s~ dans le coffre du véhicule")
                            TriggerClientEvent("ESXCustomCoffre:recievecoffrevehclientside", source, VehCoffre[plate])
                        end
                    else
                        if VehCoffre[plate].data["accounts"][typee] then 
                            VehCoffre[plate].data["accounts"][typee] = VehCoffre[plate].data["accounts"][typee] + tonumber(count)
                        end
                        RemoveBlackMoneyOnPlayer(source, count)
                        TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous venez de déposé ~b~ "..count.." $~s~ dans le coffre du véhicule")
                        TriggerClientEvent("ESXCustomCoffre:recievecoffrevehclientside", source, VehCoffre[plate])    
                    end
                else
                    TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous n'avez pas les fonds nécéssaire pour faire cela")
                end
            end
        elseif action == "remove" then 
            if OwnerofVeh == false then 
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous ne pouvez pas retirer d'item dans le coffre de ce véhicule")
                return
            end
            if VehCoffre[plate].data["accounts"][typee] >= tonumber(count) then 
                VehCoffre[plate].data["accounts"][typee] = VehCoffre[plate].data["accounts"][typee] - tonumber(count)
                if VehCoffre[plate].data["accounts"][typee] == 0 then 
                    VehCoffre[plate].data["accounts"][typee] = 0
                end
                if typee == "money" then
                    AddMoney(source, count)
                else
                    AddBlackMoneyOnPlayer(source, count)
                end
                -- xPlayer.addAccountMoney(typee, count)
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous venez de retiré ~b~"..count.." $~s~ dans le coffre du véhicule")
                TriggerClientEvent("ESXCustomCoffre:recievecoffrevehclientside", source, VehCoffre[plate])    
            else
                return ESXCustomServerUtils.rejectSuspiciousAction(source, 'Désynchronisation avec le serveur ou detection de Cheat')
            end
        
        end
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    for k, v in pairs(VehCoffre) do 
        MySQL.Sync.execute("UPDATE coffre_veh set info = @info, data = @data WHERE id = @id", {
            ["@id"] = v.id,
            ["@info"] = json.encode(v.infos),
            ["@data"] = json.encode(v.data)
        })
    end
    if Config.Debug then
        print("Server save the chest")
    end
end)