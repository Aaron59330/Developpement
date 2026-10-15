--Gsetion money
function GetMoney(src)
	return ESX.GetPlayerFromId(src).getAccount("money").money
end

function RemoveMoneyOnPlayer(src, priceremove)
    TriggerClientEvent("ESXCustomGTAO:ReloadHUD", src)
    return ESX.GetPlayerFromId(src).removeAccountMoney("money", tonumber(priceremove))
end

function AddMoney(src, amount)
    TriggerClientEvent("ESXCustomGTAO:ReloadHUD", src)
	return ESX.GetPlayerFromId(src).addAccountMoney("money", amount)
end

--Gestion Banque
function GetMoneyBanque(src)
	return ESX.GetPlayerFromId(src).getAccount("bank").money
end

function RemoveMoneyOnBanque(src, amount)
    TriggerClientEvent("ESXCustomGTAO:ReloadHUD", src)
	return ESX.GetPlayerFromId(src).removeAccountMoney("bank", amount)
end

function AddMoneyOnBanque(src, amount)
    TriggerClientEvent("ESXCustomGTAO:ReloadHUD", src)
	return ESX.GetPlayerFromId(src).addAccountMoney("bank", amount)
end

--Gestion argent sale
function GetBlackMoneyOnPlayer(src)
    return ESX.GetPlayerFromId(src).getAccount("black_money").money
end

function RemoveBlackMoneyOnPlayer(src, priceremove)
    return ESX.GetPlayerFromId(src).removeAccountMoney("black_money", tonumber(priceremove))
end

function AddBlackMoneyOnPlayer(src, amount)
	return ESX.GetPlayerFromId(src).addAccountMoney("black_money", tonumber(amount))
end

--Gestion Item (ox_inventory)
local ox_inventory = exports.ox_inventory

function AddItemOnPlayer(src, Item, amount, metadata)
    amount = tonumber(amount) or 1
    if not ox_inventory:CanCarryItem(src, Item, amount, metadata) then
        return false, 'inventory_full'
    end
    return ox_inventory:AddItem(src, Item, amount, metadata)
end

function GetItemOnPlayer(src, Item, metadata)
    local item = ox_inventory:GetItem(src, Item, metadata, false)
    if item then return item end
    local data = ox_inventory:Items(Item) or {}
    return {
        name = Item,
        label = data.label or Item,
        weight = data.weight or 0,
        count = 0
    }
end

function RemoveItemOnPlayer(src, Item, amount, metadata)
    return ox_inventory:RemoveItem(src, Item, tonumber(amount) or 1, metadata)
end

function CanCarryItemOnPlayer(src, Item, amount, metadata)
    return ox_inventory:CanCarryItem(src, Item, tonumber(amount) or 1, metadata)
end

--Gestion Weapon
function GetWeaponOnPlayer(src, WeaponItem)
    return ESX.GetPlayerFromId(src).hasWeapon(WeaponItem)
end

function addWeaponOnPlayer(src, WeaponItem, ammo)
    return ESX.GetPlayerFromId(src).addWeapon(WeaponItem, ammo)
end

function removeWeaponOnPlayer(src, WeaponItem)
    return ESX.GetPlayerFromId(src).removeWeapon(WeaponItem)
end

--Gestion Concess
function RemoveVehicle(src, plate, owner)
    MySQL.Async.execute('UPDATE owned_vehicles SET owner = @owner WHERE plate = @plate',{['@plate'] = plate, ['@owner'] = owner})
end

function ReAddVehicle(src, plate)
    MySQL.Async.execute('UPDATE owned_vehicles SET owner = @owner WHERE plate = @plate',{['@plate'] = plate, ['@owner'] = ESX.GetPlayerFromId(src).identifier})
end

function CheckVehicle(src, cb)
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND type = @type', {
        ['@owner'] = ESX.GetPlayerFromId(src).identifier,
        ['@type'] = 'car'
    }, function(data)
        cb(data)
    end)
end

function SaveVehicle(vehicle, plate)
	TriggerServerEvent('esx_vehiclelock:registerkey', plate, GetPlayerServerId(PlayerId()))-- permet de save les clée
end

--Gestion Distributeur
function HealAfterBuy(src, HowMuch, Type)
    TriggerClientEvent('esx_status:add', src, 'thirst', HowMuch)
    if Type == "eau" then
        TriggerClientEvent('esx_basicneeds:onDrink', src)
        TriggerClientEvent(Config.Trigger.TriggerNotification, src, "Vous avez bu de l'eau")
    elseif Type == "cafe" then
        TriggerClientEvent('esx_basicneeds:onDrinkCoffe', src)
        TriggerClientEvent(Config.Trigger.TriggerNotification, src, "Vous avez bu un café")
    end
end