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

-- image propre à l'objet défini dans ox_inventory (data/items.lua → client.image) ; sinon <nom>.png
local function withImages(list)
    local cache = {}
    for _, it in ipairs(list or {}) do
        if cache[it.name] == nil then
            local ok, def = pcall(function() return exports.ox_inventory:Items(it.name) end)
            cache[it.name] = (ok and type(def) == 'table' and def.image) or false
        end
        if cache[it.name] then it.defimg = cache[it.name] end
    end
end

local function gather(cb)
    ESX.TriggerServerCallback('pickax_inventory:data', function(d)
        if not d then return end
        withImages(d.items)
        d.vitals, d.equipment = vitals(), equipment()
        d.cfg = { brand = C.Brand, shortcuts = C.Shortcuts, cols = C.Columns, rows = C.Rows, warn = C.WarnWeight, recentCount = C.RecentCount,
                  shop = true, img = C.ImagePath }
        d.recent = {}
        for _, r in ipairs(recent) do d.recent[#d.recent + 1] = { name = r.name, label = r.label, count = r.count, ago = math.floor((GetGameTimer() - r.t) / 1000) } end
        cb(d)
    end)
end

local function openInv()
    if open then close() return end
    if LocalPlayer.state.invOpen then return end      -- une interface ox (coffre, sol, boutique…) est déjà ouverte
    if IsPauseMenuActive() or IsNuiFocused() or IsEntityDead(PlayerPedId()) then return end
    gather(function(d)
        open = true
        SetNuiFocus(true, true)
        SendNUIMessage({ a = 'open', data = d })
    end)
end

local function sendShop()
    ESX.TriggerServerCallback('pickax_inventory:shop', function(s) if s then withImages(s.items) end SendNUIMessage({ a = 'shop', shop = s }) end)
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
RegisterNUICallback('shop', function(_, cb) cb(1) sendShop() end)
RegisterNUICallback('withdraw', function(d, cb)
    cb(1)
    if not d then return end
    TriggerServerEvent('pickax_inventory:withdraw', d.slot, d.count)
    SetTimeout(450, function() if open then sendShop() gather(function(x) SendNUIMessage({ a = 'update', data = x }) end) end end)
end)
RegisterNUICallback('sort', function(_, cb)
    cb(1)
    TriggerServerEvent('pickax_inventory:sort', C.Shortcuts + 1)
    SetTimeout(900, function() if open then gather(function(x) SendNUIMessage({ a = 'update', data = x }) end) end end)
end)
RegisterNUICallback('refresh', function(_, cb) cb(1) gather(function(x) SendNUIMessage({ a = 'update', data = x }) end) end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then SetNuiFocus(false, false) end end)

-- si ox_inventory ouvre un autre inventaire (coffre, coffre de véhicule, sol, fouille…), on referme celui-ci
AddEventHandler('pickax:inventory', function(o) if o and open then close() end end)
