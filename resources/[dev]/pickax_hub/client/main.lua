local open = false
local function nui(a, d) d = d or {}; d.action = a; SendNUIMessage(d) end

local function hasCommand(name)
    for _, c in ipairs(GetRegisteredCommands()) do if c.name == name then return true end end
    return false
end

local function vehicleLabel(model)
    if not model then return 'Véhicule' end
    local lbl = GetLabelText(GetDisplayNameFromVehicleModel(model))
    if lbl == 'NULL' or lbl == '' then lbl = GetDisplayNameFromVehicleModel(model) end
    return lbl
end

local function readStats()
    local out = {}
    for _, s in ipairs(Config.Stats) do
        local v = 0
        for _, pre in ipairs({ 'MP0_', 'SP0_' }) do
            local ok, val = StatGetInt(joaat(pre .. s.stat), 0, true)
            if ok and val and val > 0 then v = val break end
        end
        out[#out + 1] = { label = s.label, value = math.min(100, v) }
    end
    return out
end

local function openHub()
    if open then return end
    local data = lib.callback.await('pkhub:data', false)
    if not data then return end
    for _, v in ipairs(data.vehicles) do v.label = vehicleLabel(v.model) end
    local sc = {}
    for _, s in ipairs(Config.Shortcuts) do if hasCommand(s.command) then sc[#sc + 1] = s end end
    local acts = {}
    for i, a in ipairs(Config.Activities) do acts[i] = { label = a.label, desc = a.desc, tag = a.tag, gps = a.coords ~= nil, cmd = a.command and hasCommand(a.command) or false } end
    data.stats = readStats()
    local theme = PickaxTheme or {}
    open = true; SetNuiFocus(true, true)
    nui('open', { accent = Config.Accent, data = data, shortcuts = sc, activities = acts, server = { name = theme.name, short = theme.short, tagline = theme.tagline, discord = theme.discord } })
end

local function closeHub() open = false; SetNuiFocus(false, false); nui('close') end

RegisterCommand(Config.Command, function() if open then closeHub() else openHub() end end, false)
RegisterKeyMapping(Config.Command, 'Menu central du serveur', 'keyboard', Config.Key)

RegisterNUICallback('close', function(_, cb) closeHub(); cb(1) end)
RegisterNUICallback('shortcut', function(d, cb)
    closeHub()
    for _, s in ipairs(Config.Shortcuts) do if s.id == d.id then SetTimeout(150, function() ExecuteCommand(s.command) end) end end
    cb(1)
end)
RegisterNUICallback('activity', function(d, cb)
    local a = Config.Activities[tonumber(d.index)]
    if a and d.what == 'gps' and a.coords then SetNewWaypoint(a.coords.x, a.coords.y); lib.notify({ title = 'GPS', description = 'Point posé : ' .. a.label, type = 'success' })
    elseif a and a.command then closeHub(); SetTimeout(150, function() ExecuteCommand(a.command) end) end
    cb(1)
end)
RegisterNUICallback('locate', function(d, cb)
    local plate = (d.plate or ''):gsub('%s+', ''):upper()
    for _, v in ipairs(GetGamePool('CVehicle')) do
        if (GetVehicleNumberPlateText(v) or ''):gsub('%s+', ''):upper() == plate then
            local c = GetEntityCoords(v); SetNewWaypoint(c.x, c.y)
            lib.notify({ title = 'GPS', description = 'Véhicule localisé.', type = 'success' }); cb(1); return
        end
    end
    lib.notify({ title = 'GPS', description = 'Véhicule introuvable : il est probablement au garage.', type = 'warning' }); cb(1)
end)
RegisterNUICallback('payBill', function(d, cb)
    local ok, err = lib.callback.await('pkhub:payBill', false, d.id)
    lib.notify({ title = 'Facture', description = ok and 'Facture payée.' or (err or 'Impossible.'), type = ok and 'success' or 'error' })
    cb(ok and 1 or 0)
end)
RegisterNUICallback('pref', function(d, cb)
    if d.key == 'hidehud' then ExecuteCommand('hidehud') end
    cb(1)
end)
