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
                weight = (it.weight or 0) / 1000, durability = md.durability, ammo = md.ammo,
            }
        end
    end
    local cash = 0
    for _, a in ipairs(xPlayer.getAccounts() or {}) do if a.name == 'money' then cash = a.money end end
    cb({
        name = xPlayer.getName(), money = cash,
        weight = (inv.weight or 0) / 1000, maxWeight = (inv.maxWeight or 0) / 1000, slots = inv.slots or 50, items = list,
    })
end)

-- déplace / échange deux emplacements du joueur
RegisterNetEvent('pickax_inventory:swap', function(from, to)
    local src = source
    from, to = tonumber(from), tonumber(to)
    if not from or not to or from == to then return end
    pcall(function() exports.ox_inventory:SwapSlots(src, src, from, to) end)
end)


-- ───────── Inventaire boutique (coffre privé) ─────────
-- L'identifiant du coffre vient TOUJOURS du serveur (identifiant du joueur) : le client ne peut ni choisir ni deviner celui d'un autre,
-- et ce coffre n'est pas l'inventaire du joueur, donc une fouille (joueur, police…) ne le montre jamais.
local registered, last = {}, {}
local S = Config.ShopStash

local function stashOf(src)
    local x = ESX.GetPlayerFromId(src)
    if not x then return nil end
    local id = 'boutique_' .. x.identifier
    if not registered[id] then
        exports.ox_inventory:RegisterStash(id, S.Label, S.Slots, S.MaxWeight, false)
        registered[id] = true
    end
    return id
end

local function group(name, label)
    local n = (name .. ' ' .. (label or '')):lower()
    for _, g in ipairs(Config.ShopGroups) do
        for pat in g[2]:gmatch('[^|]+') do if n:find(pat) then return g[1] end end
    end
    return 'Objets'
end

-- livraison d'un objet de la boutique : coffre privé d'abord, sinon inventaire normal ; renvoie true si livré
exports('Deliver', function(src, name, count, metadata)
    count = math.max(1, math.floor(tonumber(count) or 1))
    local id = stashOf(src)
    if not id then return false end
    if exports.ox_inventory:CanCarryItem(id, name, count, metadata) and exports.ox_inventory:AddItem(id, name, count, metadata) then
        TriggerClientEvent('esx:showNotification', src, '~g~Achat boutique~s~ : rangé dans ton ~b~inventaire boutique~s~.')
        return true
    end
    if exports.ox_inventory:CanCarryItem(src, name, count, metadata) and exports.ox_inventory:AddItem(src, name, count, metadata) then
        TriggerClientEvent('esx:showNotification', src, '~y~Inventaire boutique plein~s~ : l\'objet est dans ton inventaire.')
        return true
    end
    return false
end)

exports('Count', function(src, name)
    local id = stashOf(src)
    if not id then return 0 end
    return exports.ox_inventory:GetItemCount(id, name) or 0
end)

ESX.RegisterServerCallback('pickax_inventory:shop', function(src, cb)
    local id = stashOf(src)
    if not id then return cb(nil) end
    local inv = exports.ox_inventory:GetInventory(id, false) or {}
    local defs, list = items(), {}
    for _, it in pairs(inv.items or {}) do
        if it and it.name then
            local d = defs[it.name] or {}
            local label = it.label or d.label or it.name
            list[#list + 1] = { slot = it.slot, name = it.name, label = label, count = it.count or 1, weight = (it.weight or 0) / 1000,
                durability = (it.metadata or {}).durability, group = group(it.name, label) }
        end
    end
    cb({ items = list, weight = (inv.weight or 0) / 1000, maxWeight = S.MaxWeight / 1000, slots = S.Slots })
end)

-- récupère un objet du coffre vers l'inventaire du joueur (count = nombre, nil = tout l'empilement)
RegisterNetEvent('pickax_inventory:withdraw', function(slot, count)
    local src = source
    if GetGameTimer() - (last[src] or 0) < 250 then return end
    last[src] = GetGameTimer()
    slot = tonumber(slot)
    local id = slot and stashOf(src)
    if not id then return end
    local it = exports.ox_inventory:GetSlot(id, slot)
    if not it then return end
    count = math.max(1, math.min(it.count or 1, math.floor(tonumber(count) or it.count or 1)))
    if not exports.ox_inventory:CanCarryItem(src, it.name, count, it.metadata) then
        return TriggerClientEvent('esx:showNotification', src, '~r~Ton inventaire est plein~s~ : fais de la place.')
    end
    if exports.ox_inventory:RemoveItem(id, it.name, count, it.metadata, slot) then
        if not exports.ox_inventory:AddItem(src, it.name, count, it.metadata) then
            exports.ox_inventory:AddItem(id, it.name, count, it.metadata)      -- retour au coffre si l'ajout échoue
        end
    end
end)

-- range l'inventaire du joueur par ordre alphabétique (échanges d'emplacements ox_inventory)
RegisterNetEvent('pickax_inventory:sort', function(first)
    local src = source
    if GetGameTimer() - (last[src] or 0) < 1500 then return end
    last[src] = GetGameTimer()
    first = math.max(1, math.floor(tonumber(first) or 1))
    local inv = exports.ox_inventory:GetInventory(src)
    if not inv then return end
    local list = {}
    for _, it in pairs(inv.items or {}) do if it and it.slot >= first then list[#list + 1] = { slot = it.slot, key = ((it.label or it.name) .. '\0' .. it.name):lower() } end end
    table.sort(list, function(a, b) return a.key < b.key end)
    local at = {}                                    -- at[slot] = clé de l'objet actuellement dans l'emplacement
    for _, e in ipairs(list) do at[e.slot] = e.key end
    for i, e in ipairs(list) do
        local target = first + i - 1
        if at[target] ~= e.key then
            -- retrouve où se trouve actuellement l'objet voulu
            for s, k in pairs(at) do
                if k == e.key and s > target then
                    pcall(function() exports.ox_inventory:SwapSlots(src, src, s, target) end)
                    at[s], at[target] = at[target], at[s]
                    break
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function() last[source] = nil end)
