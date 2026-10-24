local KEY = 'firefighter'
local Incident = nil          -- incident en cours : { id, site, foyers = {{x,y,z,out}}, t0, credited = {[src]={[idx]=true}} }
local nextId = 1

local function workers()
    local list = {}
    for src, a in pairs(AJ.Active) do if a.job == KEY then list[#list + 1] = src end end
    return list
end

local function publicIncident()
    local f = {}
    for i, p in ipairs(Incident.foyers) do f[i] = { x = p.x, y = p.y, z = p.z, out = p.out } end
    return { id = Incident.id, label = Incident.site.label, site = Incident.site, foyers = f, left = math.max(0, Incident.t0 + Config.Jobs[KEY].timeLimit - os.time()) }
end

local function clear(reason)
    if not Incident then return end
    local id = Incident.id
    Incident = nil
    for _, src in ipairs(workers()) do TriggerClientEvent('aj:fire:clear', src, id, reason) end
end

local function createIncident()
    if Incident then return false end
    local j = Config.Jobs[KEY]
    -- le lieu est tiré parmi les points d'incendie d'un pompier en service (Job Builder), sinon les lieux par défaut
    local w = workers()
    if #w == 0 then return false end
    local sites = AJ.pts(AJ.Active[w[math.random(#w)]].state, 'fire')
    if #sites == 0 then return false end
    local site = sites[math.random(#sites)]
    site = { label = (site.label ~= '' and site.label) or 'Incendie', x = site.x, y = site.y, z = site.z }
    local n = math.random(j.foyers[1], j.foyers[2])
    local foyers = {}
    for i = 1, n do
        local a, r = math.random() * 6.2831, (i == 1) and 0.0 or (1.5 + math.random() * (j.spread - 1.5))
        foyers[i] = { x = site.x + math.cos(a) * r, y = site.y + math.sin(a) * r, z = site.z, out = false }
    end
    Incident = { id = nextId, site = site, foyers = foyers, t0 = os.time(), credited = {} }
    nextId = nextId + 1
    for _, src in ipairs(workers()) do
        TriggerClientEvent('aj:fire:alert', src, publicIncident())
    end
    return true
end

AJ.Modules[KEY] = {
    start = function(src, st)
        local j = Config.Jobs[KEY]
        local spawn = AJ.spawnPoint(st)
        if not spawn then return nil, 'Caserne non configurée' end
        st.score = 0
        -- premier incident quelques secondes après la prise de service s'il n'y en a pas déjà
        SetTimeout(20000, function()
            if AJ.Active[src] and AJ.Active[src].job == KEY and not Incident then createIncident() end
        end)
        return { vehicle = j.vehicle, spawn = spawn, weapon = j.extinguisher, plate = 'POMPIER', incident = Incident and publicIncident() or nil }
    end,
    stop = function(src)
        if #workers() == 0 then clear(nil) end
    end,
}

-- Incidents automatiques
CreateThread(function()
    local j = Config.Jobs[KEY]
    while true do
        Wait(j.interval * 1000)
        if not Incident and #workers() >= j.minWorkers then createIncident() end
    end
end)

-- Incendie hors de contrôle
CreateThread(function()
    while true do
        Wait(5000)
        if Incident and os.time() - Incident.t0 > Config.Jobs[KEY].timeLimit then
            for _, src in ipairs(workers()) do AJ.notify(src, 'L\'incendie à ' .. Incident.site.label .. ' est hors de contrôle...', 'error') end
            clear('expired')
        end
    end
end)

RegisterNetEvent('aj:fire:foyerOut', function(id, idx)
    local src = source
    if not AJ.session(src, KEY) or not Incident or Incident.id ~= id then return end
    local f = Incident.foyers[idx]
    if not f or not AJ.near(src, f, 60.0) then return end
    Incident.credited[src] = Incident.credited[src] or {}
    if Incident.credited[src][idx] then return end
    Incident.credited[src][idx] = true
    local j = Config.Jobs[KEY]
    local paid = AJ.pay(src, KEY, j.payPerFire, 14, 'Foyer éteint', 0)
    AJ.notify(src, ('Foyer éteint : %d $'):format(paid), 'success')
    if not f.out then
        f.out = true
        for _, w in ipairs(workers()) do TriggerClientEvent('aj:fire:foyer', w, id, idx) end
    end
    for _, p in ipairs(Incident.foyers) do if not p.out then return end end
    -- tous les foyers sont éteints : prime pour chaque pompier qui a participé
    for who in pairs(Incident.credited) do
        if AJ.Active[who] and AJ.Active[who].job == KEY then
            local b = AJ.pay(who, KEY, j.bonus, 40, 'Incendie maîtrisé', 1)
            AJ.notify(who, ('Incendie maîtrisé à %s ! Prime : %d $'):format(Incident.site.label, b), 'success')
        end
    end
    clear('done')
end)

-- (admin) déclenche un incendie tout de suite
RegisterCommand('ajfire', function(src)
    if not AJ.isAdmin(src) then return end
    if createIncident() then AJ.notify(src, 'Incendie déclenché.', 'success') else AJ.notify(src, 'Un incendie est déjà en cours.', 'error') end
end, false)
