local function ECO(kind, n) if GetResourceState('pickax_economy') ~= 'started' then return n end local ok, r = pcall(function() return exports.pickax_economy:Scale(kind, n) end) return (ok and tonumber(r)) or n end   -- type d'économie du serveur (pickax_economy, optionnel)
-- ─────────────────────────────── Job Gazoline : ravitaillement des stations essence ───────────────────────────────
local G = Config.Gazoline
local Missions = {}        -- [src] = { eid, pi, coords, liters, pay, start, state = 'deliver' | 'return', label }
local depot                -- { x, y, z, h, sx, sy, sz }
local lastLow = {}

local function notify(src, msg, kind) WB.notify(src, msg, kind or 'info') end

local function isGazoline(xPlayer)
    return xPlayer and xPlayer.getJob and xPlayer.getJob().name == G.Job
end

-- ─────────────── Dépôt (position enregistrée en jeu) ───────────────
local function loadDepot()
    if G.Depot and G.Depot.x then depot = { x = G.Depot.x, y = G.Depot.y, z = G.Depot.z, h = G.Depot.h or 0.0 } end
    local row = MySQL.single.await('SELECT v FROM worldbuilder_gazoline WHERE k = ?', { 'depot' })
    local d = row and json.decode(row.v)
    if d and d.x then depot = d end
end

local function sendCfg(target)
    TriggerClientEvent('worldbuilder:gaz:cfg', target or -1, { depot = depot })
end

RegisterCommand('gazdepot', function(src)
    if src == 0 or not WB.isAdmin(src) then return end
    local ped = GetPlayerPed(src)
    local c, h = GetEntityCoords(ped), GetEntityHeading(ped)
    depot = { x = c.x, y = c.y, z = c.z - 1.0, h = h }
    MySQL.insert.await('INSERT INTO worldbuilder_gazoline (k, v) VALUES (?, ?) ON DUPLICATE KEY UPDATE v = VALUES(v)', { 'depot', json.encode(depot) })
    sendCfg()
    notify(src, 'Dépôt Gazoline enregistré ici. Le camion apparaîtra 10 m devant toi.', 'success')
end, false)

-- ─────────────── Job ESX (créé s'il n'existe pas) ───────────────
local function ensureJob()
    if not G.Enabled then return end
    if MySQL.scalar.await('SELECT 1 FROM jobs WHERE name = ? LIMIT 1', { G.Job }) then return end
    MySQL.insert.await('INSERT INTO jobs (name, label, whitelisted) VALUES (?, ?, 0)', { G.Job, G.Label })
    for i, g in ipairs(G.Grades) do
        MySQL.insert.await("INSERT INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female) VALUES (?, ?, ?, ?, ?, '{}', '{}')", { G.Job, i - 1, g[1], g[2], g[3] })
    end
    if pcall(MySQL.scalar.await, 'SELECT 1 FROM jobbuilder_jobs LIMIT 1') then
        pcall(function()
            MySQL.insert.await([[INSERT IGNORE INTO jobbuilder_jobs (name, label, type, whitelisted, society, boss_grade, blip, settings, created_by) VALUES (?, ?, 'custom', 0, 0, ?, '{}', ?, 'polemploi')]],
                { G.Job, G.Label, #G.Grades, json.encode({ missions_enabled = false, announce_enabled = false, smalljob = true, actions = {} }) })
        end)
        pcall(function() exports.pickax_jobbuilder:Reload() end)
    end
    if ESX.RefreshJobs then pcall(ESX.RefreshJobs) end
    print(('^2[worldbuilder] Job « %s » créé (grades : %d). Ajoute-le au Pôle emploi ou donne-le avec /setjob.^0'):format(G.Job, #G.Grades))
end

-- ─────────────── Stations ───────────────
local function stations()
    local list = {}
    for _, e in pairs(WB.Entities) do
        if e.type == 'fuel' and e.enabled and e.points and e.points[1] and e.points[1].coords then
            local cap = e.settings.tank or 0
            e.stats = e.stats or {}
            if cap > 0 and e.stats.tank == nil then e.stats.tank = cap end
            local tank = cap > 0 and math.min(e.stats.tank or cap, cap) or -1
            list[#list + 1] = { e = e, cap = cap, tank = tank, pct = cap > 0 and (tank / cap * 100) or 100 }
        end
    end
    table.sort(list, function(a, b) return a.e.id < b.e.id end)
    return list
end

local function assigned(eid)
    for _, m in pairs(Missions) do if m.eid == eid then return true end end
    return false
end

-- ─────────────── Garantie : toujours une station avec de l'essence + alertes ───────────────
local function reserveStation(list)
    local best
    for _, s in ipairs(list) do
        if s.cap > 0 then
            if s.e.settings.reserve == true then return s end
            if not best or s.cap > best.cap then best = s end
        end
    end
    return best
end

CreateThread(function()
    while not WB.ready do Wait(1000) end
    while true do
        Wait(math.max(10, G.CheckSeconds) * 1000)
        if G.Enabled then
            local list = stations()
            local anyFuel, unlimited = false, false
            for _, s in ipairs(list) do
                if s.cap <= 0 then unlimited = true
                elseif s.tank >= s.cap * G.ReservePercent / 100 then anyFuel = true end
            end
            if not anyFuel and not unlimited then
                local r = reserveStation(list)
                if r then
                    local target = math.ceil(r.cap * G.ReservePercent / 100)
                    r.e.stats.tank = math.max(r.e.stats.tank or 0, target)
                    WB.Dirty[r.e.id] = true
                    print(('^3[worldbuilder] Gazoline : réserve de secours — la station « %s » est remplie à %d %% pour qu\'il reste de l\'essence.^0'):format(r.e.label, G.ReservePercent))
                    for _, id in ipairs(GetPlayers()) do
                        local xp = ESX.GetPlayerFromId(tonumber(id))
                        if isGazoline(xp) then notify(xp.source, ('Réserve de secours activée : %s est ravitaillée en urgence.'):format(r.e.label), 'info') end
                    end
                end
            end
            -- alertes stock bas aux livreurs
            local now = os.time()
            for _, s in ipairs(list) do
                if s.cap > 0 and s.pct < G.LowAlertPercent and (not lastLow[s.e.id] or now - lastLow[s.e.id] > 600) and not assigned(s.e.id) then
                    lastLow[s.e.id] = now
                    for _, id in ipairs(GetPlayers()) do
                        local xp = ESX.GetPlayerFromId(tonumber(id))
                        if isGazoline(xp) then notify(xp.source, ('Station « %s » presque vide (%d %%) : une livraison est nécessaire.'):format(s.e.label, math.floor(s.pct)), 'error') end
                    end
                end
            end
        end
    end
end)

-- ─────────────── Missions ───────────────
ESX.RegisterServerCallback('worldbuilder:gaz:info', function(src, cb)
    local xp = ESX.GetPlayerFromId(src)
    cb({ ok = true, job = isGazoline(xp), depot = depot, mission = Missions[src] })
end)

ESX.RegisterServerCallback('worldbuilder:gaz:start', function(src, cb)
    local xp = ESX.GetPlayerFromId(src)
    if not G.Enabled or not xp then return cb({ ok = false, error = 'Indisponible' }) end
    if not isGazoline(xp) then return cb({ ok = false, error = 'Tu dois travailler pour ' .. G.Label .. '.' }) end
    if not depot then return cb({ ok = false, error = 'Le dépôt n\'est pas encore défini (/gazdepot).' }) end
    if not WB.near(src, depot, 30) then return cb({ ok = false, error = 'Tu es trop loin du dépôt.' }) end
    if Missions[src] then return cb({ ok = false, error = 'Tu as déjà une livraison en cours.' }) end
    -- station qui en a le plus besoin et qui n'est pas déjà prise
    local pick
    for _, s in ipairs(stations()) do
        if s.cap > 0 and s.pct < G.OrderBelowPercent and not assigned(s.e.id) and (not pick or s.pct < pick.pct) then pick = s end
    end
    if not pick then return cb({ ok = false, error = 'Toutes les stations sont bien approvisionnées pour le moment.' }) end
    local liters = math.floor(math.min(G.TankerLiters, pick.cap - pick.tank))
    if liters < 100 then return cb({ ok = false, error = 'Aucune livraison utile pour le moment.' }) end
    local rate = G.PayPerLiter * (pick.pct < G.LowAlertPercent and (1 + G.UrgentBonus) or 1)
    local p = pick.e.points[1]
    Missions[src] = { eid = pick.e.id, pi = 1, coords = p.coords, liters = liters, pay = math.floor(liters * rate), start = GetGameTimer(), state = 'deliver', label = pick.e.label }
    local m = Missions[src]
    cb({ ok = true, mission = { label = m.label, coords = m.coords, liters = m.liters, pay = m.pay, pct = math.floor(pick.pct) }, truck = G.Truck, trailer = G.Trailer })
end)

ESX.RegisterServerCallback('worldbuilder:gaz:unloadBegin', function(src, cb)
    local m = Missions[src]
    if not m or m.state ~= 'deliver' then return cb({ ok = false, error = 'Aucune livraison en cours' }) end
    if not WB.near(src, m.coords, 20) then return cb({ ok = false, error = 'Tu es trop loin de la pompe' }) end
    if GetGameTimer() - m.start < G.MinSeconds * 1000 then return cb({ ok = false, error = 'Chargement tout juste terminé : prends la route.' }) end
    local secs = math.max(8, math.min(40, m.liters / math.max(1, G.UnloadLitersPerSecond)))
    WB.beginAct(src, { kind = 'gaz', mission = m }, secs)
    cb({ ok = true, seconds = secs, liters = m.liters })
end)

RegisterNetEvent('worldbuilder:server:gazUnloadFinish', function(done)
    local src = source
    local a = WB.endAct(src, 'gaz')
    local xp = ESX.GetPlayerFromId(src)
    local m = Missions[src]
    if not a or not m or not xp or a.mission ~= m then return end
    if done ~= true or not WB.near(src, m.coords, 20) then return end
    local e = WB.Entities[m.eid]
    if not e then Missions[src] = nil return end
    local cap = e.settings.tank or 0
    e.stats = e.stats or {}
    e.stats.tank = math.min(cap, (e.stats.tank or 0) + m.liters)
    WB.stat(e, 'delivered', m.liters)
    xp.addAccountMoney(G.PayAccount, ECO('income', m.pay), 'Livraison de carburant')
    WB.log(e, xp, 'delivery', ('%d L livrés'):format(m.liters), m.pay)
    m.state = 'return'
    TriggerClientEvent('worldbuilder:gaz:delivered', src, { liters = m.liters, pay = m.pay, label = m.label })
end)

RegisterNetEvent('worldbuilder:server:gazReturn', function()
    local src = source
    local m = Missions[src]
    local xp = ESX.GetPlayerFromId(src)
    if not m or m.state ~= 'return' or not xp or not depot or not WB.near(src, depot, 40) then return end
    Missions[src] = nil
    if G.ReturnBonus > 0 then xp.addAccountMoney(G.PayAccount, G.ReturnBonus, 'Camion rendu') end
    TriggerClientEvent('worldbuilder:gaz:finished', src, G.ReturnBonus)
end)

RegisterNetEvent('worldbuilder:server:gazCancel', function()
    local src = source
    if Missions[src] then Missions[src] = nil WB.Pending[src] = nil end
    TriggerClientEvent('worldbuilder:gaz:finished', src, 0, true)
end)

AddEventHandler('playerDropped', function() Missions[source] = nil end)
AddEventHandler('esx:setJob', function(src, job)
    if job and job.name ~= G.Job and Missions[src] then
        Missions[src] = nil
        TriggerClientEvent('worldbuilder:gaz:finished', src, 0, true)
    end
end)
AddEventHandler('esx:playerLoaded', function(src) SetTimeout(2000, function() sendCfg(src) end) end)
RegisterNetEvent('worldbuilder:server:gazRequest', function() sendCfg(source) end)

-- ─────────────── Démarrage ───────────────
local prevReady = WB.onReady
WB.onReady = function()
    if prevReady then prevReady() end
    CreateThread(function()
        MySQL.query.await([[CREATE TABLE IF NOT EXISTS worldbuilder_gazoline (k VARCHAR(30) NOT NULL PRIMARY KEY, v TEXT NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
        loadDepot()
        ensureJob()
        sendCfg()
        if G.Enabled and not depot then print('^3[worldbuilder] Gazoline : dépôt non défini. Va à l\'endroit voulu et tape /gazdepot (groupe admin).^0') end
    end)
end
