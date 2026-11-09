ESX = exports['es_extended']:getSharedObject()
local C = Config
local open = false
local recent, last = {}, {}

local function snapshot()
    local out = {}
    for _, it in pairs(exports.ox_inventory:GetPlayerItems() or {}) do
        if it and it.name then out[it.name] = (out[it.name] or 0) + (it.count or 1) end
    end
    return out
end

-- « Reçu récemment » : on compare l'inventaire à chaque mise à jour
local function track()
    local now, labels = snapshot(), {}
    for _, it in pairs(exports.ox_inventory:GetPlayerItems() or {}) do if it and it.name then labels[it.name] = it.label or it.name end end
    for n, c in pairs(now) do
        local d = c - (last[n] or 0)
        if d > 0 and next(last) ~= nil then
            table.insert(recent, 1, { name = n, label = labels[n] or n, count = d, t = GetGameTimer() })
            while #recent > 10 do table.remove(recent) end
        end
    end
    last = now
end
CreateThread(function() Wait(4000) last = snapshot() end)
RegisterNetEvent('ox_inventory:updateInventory', function() track() end)

local function equipment()
    local ped, out = PlayerPedId(), {}
    for _, grp in ipairs({ 'top', 'left', 'right' }) do
        out[grp] = {}
        for _, e in ipairs(C.Equipment[grp]) do
            local worn
            if e[2] == 'comp' then worn = GetPedDrawableVariation(ped, e[3]) > 0 else worn = GetPedPropIndex(ped, e[3]) ~= -1 end
            out[grp][#out[grp] + 1] = { label = e[1], worn = worn }
        end
    end
    return out
end

local function vitals()
    local ped = PlayerPedId()
    local hp = math.max(0, math.floor((GetEntityHealth(ped) - 100) / math.max(1, GetEntityMaxHealth(ped) - 100) * 100))
    local st = { health = hp, armor = GetPedArmour(ped), hunger = nil, thirst = nil }
    -- faim / soif : esx_status si présent
    local ok = pcall(function()
        TriggerEvent('esx_status:getStatus', 'hunger', function(s) st.hunger = math.floor(s.val / 10000) end)
        TriggerEvent('esx_status:getStatus', 'thirst', function(s) st.thirst = math.floor(s.val / 10000) end)
    end)
    return st
end

local function close()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ a = 'close' })
end

local function openInv()
    if open then close() return end
    if IsPauseMenuActive() or IsNuiFocused() or IsEntityDead(PlayerPedId()) then return end
    ESX.TriggerServerCallback('pickax_inventory:data', function(d)
        if not d then return end
        d.vitals, d.equipment = vitals(), equipment()
        d.cfg = { brand = C.Brand, shortcuts = C.Shortcuts, cols = C.Columns, rows = C.Rows, warn = C.WarnWeight, recentCount = C.RecentCount,
                  shop = (C.ShopCommand or '') ~= '', img = C.ImagePath }
        d.recent = {}
        for _, r in ipairs(recent) do d.recent[#d.recent + 1] = { name = r.name, label = r.label, count = r.count, ago = math.floor((GetGameTimer() - r.t) / 1000) } end
        open = true
        SetNuiFocus(true, true)
        SendNUIMessage({ a = 'open', data = d })
    end)
end

RegisterCommand(C.Command, openInv, false)
if C.Key and C.Key ~= '' then RegisterKeyMapping(C.Command, 'Inventaire', 'keyboard', C.Key) end
exports('Open', openInv)
exports('Close', close)

RegisterNUICallback('close', function(_, cb) cb(1) close() end)
RegisterNUICallback('use', function(d, cb)
    cb(1)
    if d and tonumber(d.slot) then close() exports.ox_inventory:useSlot(tonumber(d.slot)) end
end)
RegisterNUICallback('swap', function(d, cb)
    cb(1)
    if d then TriggerServerEvent('pickax_inventory:swap', d.from, d.to) end
end)
RegisterNUICallback('shop', function(_, cb)
    cb(1)
    if (C.ShopCommand or '') ~= '' then close() ExecuteCommand(C.ShopCommand) end
end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then SetNuiFocus(false, false) end end)
