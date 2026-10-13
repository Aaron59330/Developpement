-- ESXCustom -> ox_inventory compatibility bridge
-- Keeps legacy custom scripts functional while using ox_inventory as the item backend.
local ox_inventory = exports.ox_inventory

local function safeRegisterStash(id, label, slots, weight, owner, groups, coords)
    local ok, err = pcall(function()
        ox_inventory:RegisterStash(id, label, slots or 50, weight or 100000, owner, groups, coords)
    end)
    if not ok and Config and Config.Debug then
        print(('[ox_inventory] stash %s: %s'):format(id, err))
    end
end

CreateThread(function()
    while GetResourceState('ox_inventory') ~= 'started' do Wait(250) end

    -- Convert legacy shared addon inventories into ox stashes.
    local rows = MySQL.query.await('SELECT name, label, shared FROM addon_inventory') or {}
    for i = 1, #rows do
        local row = rows[i]
        if row.shared == 1 then
            safeRegisterStash(row.name, row.label or row.name, 80, 250000, nil)
        end
    end

    -- Common stashes used by bundled ESX resources.
    safeRegisterStash('society_police', 'Coffre Police', 100, 500000, nil, { police = 0 })
    safeRegisterStash('society_ambulance', 'Coffre Ambulance', 100, 500000, nil, { ambulance = 0 })
end)

-- Standard ESX callbacks for inventory information.
ESX.RegisterServerCallback('esx:getInventoryItem', function(source, cb, item, metadata)
    cb(ox_inventory:GetItem(source, item, metadata, false))
end)

ESX.RegisterServerCallback('esx:getInventoryItems', function(source, cb)
    cb(ox_inventory:GetInventoryItems(source) or {})
end)

exports('GetItem', function(source, item, metadata)
    return ox_inventory:GetItem(source, item, metadata, false)
end)
exports('AddItem', function(source, item, count, metadata)
    if not ox_inventory:CanCarryItem(source, item, count, metadata) then return false, 'inventory_full' end
    return ox_inventory:AddItem(source, item, count, metadata)
end)
exports('RemoveItem', function(source, item, count, metadata)
    return ox_inventory:RemoveItem(source, item, count, metadata)
end)
