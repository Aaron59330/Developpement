-- Services : lignes des jobs (Job Builder) ou liste fixe, alertes avec position, garage
local lastAlert, alerts, nextAlert = {}, {}, 0

local function onDuty(x, jobs)
    if not x or not x.job then return false end
    local name = x.job.name or ''
    if x.job.onDuty == false then return false end
    if name:sub(1, 3) == 'off' then return false end
    for _, j in ipairs(jobs) do if j == name then return true end end
    return false
end

local function staticMembers(svc)
    local list = {}
    for _, x in ipairs(ESX.GetExtendedPlayers()) do
        if onDuty(x, svc.jobs) then list[#list + 1] = x.source end
    end
    return list
end

local function jbLines()
    if not Config.JobLines.enabled or GetResourceState('pickax_jobbuilder') ~= 'started' then return nil end
    local ok, lines = pcall(function() return exports.pickax_jobbuilder:GetPhoneLines() end)
    if ok and type(lines) == 'table' then return lines end
end

-- Toutes les lignes joignables (jobs du builder en direct, sinon liste fixe)
function Aura.Lines()
    local out = {}
    local jb = jbLines()
    if jb then
        for _, l in ipairs(jb) do
            out[#out + 1] = { id = 'job:' .. l.job, job = l.job, jb = true, label = l.label, number = l.number or '', icon = l.icon, color = l.color, type = l.type,
                mode = l.mode or 'both', anon = l.anon, hint = l.hint or '', minGrade = l.minGrade or 0 }
        end
    end
    if not jb or Config.JobLines.keepStatic then
        for _, s in ipairs(Config.Services) do
            out[#out + 1] = { id = s.id, static = s, label = s.label, number = s.number or '', icon = s.icon, color = s.color, mode = 'both', anon = s.anon, hint = '', minGrade = 0 }
        end
    end
    return out
end

-- Version publique (envoyée à l'interface : noms pour l'historique d'appels, numéros)
function Aura.LinesPublic()
    local out = {}
    for _, l in ipairs(Aura.Lines()) do
        out[#out + 1] = { id = l.id, label = l.label, number = l.number, key = Aura.LineKey and Aura.LineKey(l) or l.number, icon = l.icon, color = l.color }
    end
    return out
end

function Aura.LineById(id)
    for _, l in ipairs(Aura.Lines()) do if l.id == id then return l end end
end
function Aura.LineByNumber(number)
    if not number or number == '' then return nil end
    for _, l in ipairs(Aura.Lines()) do if l.number ~= '' and l.number == number then return l end end
end

-- Employés joignables d'une ligne (sources)
function Aura.LineMembers(line)
    if line.jb then
        local ok, list = pcall(function() return exports.pickax_jobbuilder:GetJobMembers(line.job, line.minGrade) end)
        return ok and list or {}
    end
    return staticMembers(line.static)
end

lib.callback.register('aura:serviceLines', function(src)
    local out = {}
    for _, l in ipairs(Aura.Lines()) do
        local members = Aura.LineMembers(l)
        local n = 0
        for _, m in ipairs(members) do if m ~= src then n = n + 1 end end
        out[#out + 1] = { id = l.id, label = l.label, number = l.number, icon = l.icon, color = l.color, type = l.type, mode = l.mode, anon = l.anon, hint = l.hint, online = n,
            voice = Config.JobLines.voice and l.mode ~= 'alert', alert = l.mode ~= 'voice' }
    end
    return out
end)

lib.callback.register('aura:serviceStatus', function(src)
    local out = {}
    for _, l in ipairs(Aura.Lines()) do out[l.id] = #Aura.LineMembers(l) end
    return out
end)

lib.callback.register('aura:serviceCall', function(src, serviceId, message, anon)
    local id = Aura.ident[src]; local me = id and Aura.phones[id]
    if not me then return { ok = false, error = 'Indisponible' } end
    if me.settings.airplane then return { ok = false, error = 'Mode avion activé' } end
    local line = Aura.LineById(serviceId)
    if not line then return { ok = false, error = 'Service inconnu' } end
    if line.mode == 'voice' then return { ok = false, error = 'Ce service se joint uniquement par appel' } end
    local now = GetGameTimer()
    if lastAlert[src] and now - lastAlert[src] < Config.Dispatch.cooldown * 1000 then return { ok = false, error = 'Patientez avant de renvoyer une alerte' } end
    local alert
    local list
    if line.jb then
        local ok, res = pcall(function() return exports.pickax_jobbuilder:PhoneAlert(src, line.job, message, anon and line.anon) end)
        if not ok or not res or not res.ok then return { ok = false, error = (ok and res and res.error) or 'Service indisponible' } end
        list = res.members
        nextAlert = nextAlert + 1
        alert = { id = nextAlert, service = line.id, label = line.label, name = res.name, message = Aura.Clamp(message, 300), coords = res.coords, noBlip = res.handled,
            fromNumber = (not (anon and line.anon)) and me.number or nil, from = src }
    else
        list = Aura.LineMembers(line)
        local filtered = {}
        for _, m in ipairs(list) do filtered[#filtered + 1] = m end
        list = filtered
        if #list == 0 then return { ok = false, error = 'Aucun agent disponible pour le moment' } end
        local c = GetEntityCoords(GetPlayerPed(src))
        nextAlert = nextAlert + 1
        local hide = line.anon and anon
        alert = { id = nextAlert, service = line.id, label = line.label, from = src, fromNumber = (not hide) and me.number or nil, name = (not hide) and Aura.Name(id) or 'Anonyme',
            message = Aura.Clamp(message, 300), coords = { x = c.x, y = c.y, z = c.z } }
    end
    lastAlert[src] = now
    alerts[alert.id] = alert
    SetTimeout(Config.Dispatch.blipSeconds * 1000, function() alerts[alert.id] = nil end)
    local sent = 0
    for _, t in ipairs(list) do
        if t ~= src then TriggerClientEvent('aura:dispatch', t, alert); sent = sent + 1 end
    end
    return { ok = true, count = sent, id = alert.id }
end)

lib.callback.register('aura:dispatchAccept', function(src, aid)
    local a = alerts[tonumber(aid)]
    local x = ESX.GetPlayerFromId(src)
    if not a or not x then return false end
    if a.from and GetPlayerName(a.from) then
        TriggerClientEvent('aura:push', a.from, 'notify', { app = 'services', title = a.label, body = x.getName() .. ' prend votre appel en charge' })
    end
    return a.coords
end)

-- API : alerte envoyée par un script externe (id d'un service fixe, ou « job:<nom> » / nom du job)
function Aura.Dispatch(serviceId, message, coords, label)
    local line = Aura.LineById(serviceId) or Aura.LineById('job:' .. tostring(serviceId))
    if not line then return false end
    nextAlert = nextAlert + 1
    local a = { id = nextAlert, service = line.id, label = label or line.label, name = 'Système', message = message, coords = coords }
    alerts[a.id] = a
    for _, t in ipairs(Aura.LineMembers(line)) do TriggerClientEvent('aura:dispatch', t, a) end
    return true
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
