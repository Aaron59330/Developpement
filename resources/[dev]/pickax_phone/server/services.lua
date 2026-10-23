-- Services (alertes aux métiers) et garage
local lastAlert, alerts, nextAlert = {}, {}, 0

local function onDuty(x, jobs)
    if not x or not x.job then return false end
    local name = x.job.name or ''
    if x.job.onDuty == false then return false end
    if name:sub(1, 3) == 'off' then return false end
    for _, j in ipairs(jobs) do if j == name then return true end end
    return false
end

local function responders(svc)
    local list = {}
    for _, x in ipairs(ESX.GetExtendedPlayers()) do
        if onDuty(x, svc.jobs) then list[#list + 1] = x.source end
    end
    return list
end

lib.callback.register('aura:serviceStatus', function(src)
    local out = {}
    for _, svc in ipairs(Config.Services) do out[svc.id] = #responders(svc) end
    return out
end)

lib.callback.register('aura:serviceCall', function(src, serviceId, message, anon)
    local id = Aura.ident[src]; local me = id and Aura.phones[id]
    if not me then return { ok = false, error = 'Indisponible' } end
    if me.settings.airplane then return { ok = false, error = 'Mode avion activé' } end
    local svc
    for _, s in ipairs(Config.Services) do if s.id == serviceId then svc = s end end
    if not svc then return { ok = false, error = 'Service inconnu' } end
    local now = GetGameTimer()
    if lastAlert[src] and now - lastAlert[src] < Config.Dispatch.cooldown * 1000 then return { ok = false, error = 'Patientez avant de renvoyer une alerte' } end
    local list = responders(svc)
    if #list == 0 then return { ok = false, error = 'Aucun agent disponible pour le moment' } end
    lastAlert[src] = now
    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped)
    nextAlert = nextAlert + 1
    local hide = svc.anon and anon
    local alert = { id = nextAlert, service = svc.id, label = svc.label, from = src, fromNumber = (not hide) and me.number or nil, name = (not hide) and Aura.Name(id) or 'Anonyme',
        message = Aura.Clamp(message, 300), coords = { x = c.x, y = c.y, z = c.z } }
    alerts[alert.id] = alert
    SetTimeout(Config.Dispatch.blipSeconds * 1000, function() alerts[alert.id] = nil end)
    for _, t in ipairs(list) do TriggerClientEvent('aura:dispatch', t, alert) end
    return { ok = true, count = #list, id = alert.id }
end)

lib.callback.register('aura:dispatchAccept', function(src, aid)
    local a = alerts[tonumber(aid)]
    local x = ESX.GetPlayerFromId(src)
    if not a or not x then return false end
    if GetPlayerName(a.from) then
        TriggerClientEvent('aura:push', a.from, 'notify', { app = 'services', title = a.label, body = x.getName() .. ' prend votre appel en charge' })
    end
    return a.coords
end)

-- API : alerte envoyée par un script externe
function Aura.Dispatch(serviceId, message, coords, label)
    for _, svc in ipairs(Config.Services) do
        if svc.id == serviceId then
            nextAlert = nextAlert + 1
            local a = { id = nextAlert, service = svc.id, label = label or svc.label, name = 'Système', message = message, coords = coords }
            alerts[a.id] = a
            for _, t in ipairs(responders(svc)) do TriggerClientEvent('aura:dispatch', t, a) end
            return true
        end
    end
    return false
end

-- ═════════════════ GARAGE ═════════════════
lib.callback.register('aura:garage', function(src)
    local id = Aura.ident[src]; if not id then return {} end
    local ok, rows = pcall(function() return MySQL.query.await('SELECT plate, vehicle, stored FROM owned_vehicles WHERE owner = ?', { id }) end)
    if not ok or not rows then return {} end
    local out = {}
    for _, r in ipairs(rows) do
        local props = Aura.Unjson(r.vehicle, {})
        out[#out + 1] = { plate = r.plate, model = props.model, stored = r.stored == 1 or r.stored == true, fuel = props.fuelLevel, engine = props.engineHealth, body = props.bodyHealth, color = props.color1 }
    end
    return out
end)
