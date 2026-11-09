ESX = exports['es_extended']:getSharedObject()

local function items() return exports.ox_inventory:Items() or {} end

ESX.RegisterServerCallback('pickax_inventory:data', function(src, cb)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return cb(nil) end
    local inv = exports.ox_inventory:GetInventory(src) or {}
    local defs, list = items(), {}
    for _, it in pairs(inv.items or {}) do
        if it and it.name then
            local d = defs[it.name] or defs[string.lower(it.name)] or {}
            local md = it.metadata or {}
            list[#list + 1] = {
                slot = it.slot, name = it.name, label = it.label or d.label or it.name, count = it.count or 1,
                weight = (it.weight or 0), durability = md.durability, ammo = md.ammo,
            }
        end
    end
    local cash = 0
    for _, a in ipairs(xPlayer.getAccounts() or {}) do if a.name == 'money' then cash = a.money end end
    cb({
        name = xPlayer.getName(), money = cash,
        weight = inv.weight or 0, maxWeight = inv.maxWeight or 0, slots = inv.slots or 50, items = list,
    })
end)

-- déplace / échange deux emplacements du joueur
RegisterNetEvent('pickax_inventory:swap', function(from, to)
    local src = source
    from, to = tonumber(from), tonumber(to)
    if not from or not to or from == to then return end
    pcall(function() exports.ox_inventory:SwapSlots(src, src, from, to) end)
end)
