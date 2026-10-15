-- ─────────────────────────────── Missions PNJ ───────────────────────────────
-- Moteur générique : chaque type de job a ses modèles de missions (Config.Missions.Templates).
-- Le serveur choisit les lieux, suit la progression étape par étape (position vérifiée) et verse la récompense.
-- Activation : global (Config.Missions.Enabled) + par job (réglage « Missions PNJ » dans le builder).

local M = Config.Missions
local Active = {}     -- [src] = instance en cours
local Cooldown = {}   -- [identifier|job] = timestamp de fin de cooldown
local nextId = 0

local function fail(msg) return { ok = false, error = msg } end
local function now() return os.time() end

local function enabledFor(job) return M.Enabled and job.settings.missions_enabled ~= false end
local function templatesFor(job) return M.Templates[job.type] or M.Templates.custom or {} end

local function findTpl(job, id)
    for _, t in ipairs(templatesFor(job)) do if t.id == id then return t end end
end

local function dist(src, c)
    local p = GetEntityCoords(GetPlayerPed(src))
    return #(vector3(p.x, p.y, p.z) - vector3(c.x, c.y, c.z))
end

-- ─────────────────────────────── Tableau des missions (point « Missions PNJ ») ───────────────────────────────
function JB.openMissions(src, x, point, job, cb)
    if not enabledFor(job) then return cb(fail('Les missions PNJ sont désactivées pour ce job')) end
    local list = {}
    local grade = x.job.grade
    for _, t in ipairs(templatesFor(job)) do
        local cd = math.max(0, (Cooldown[x.identifier .. '|' .. job.name .. '|' .. t.id] or 0) - now())
        list[#list + 1] = {
            id = t.id, label = t.label, desc = t.desc, reward = t.reward, minGrade = t.minGrade, timeLimit = t.timeLimit,
            steps = #t.steps, locked = grade < t.minGrade, cooldownLeft = cd,
        }
    end
    local st = MySQL.single.await('SELECT done, earned FROM jobbuilder_mission_stats WHERE identifier = ? AND job_name = ?', { x.identifier, job.name }) or {}
    local act = Active[src]
    cb({
        ok = true, kind = 'missions', label = point.label, jobLabel = job.label, templates = list, grades = job.grades,
        stats = { done = st.done or 0, earned = st.earned or 0 }, mult = job.settings.missions_mult or 100, source = job.settings.missions_source or 'system',
        active = act and { label = act.label, idx = math.min(act.idx, #act.steps), total = #act.steps } or nil,
    })
end

-- ─────────────────────────────── Construction d'une mission ───────────────────────────────
local function shuffledLocations()
    local keys = {}
    for k in pairs(M.Locations) do keys[#keys + 1] = k end
    table.sort(keys)
    for i = #keys, 2, -1 do
        local j = math.random(i)
        keys[i], keys[j] = keys[j], keys[i]
    end
    return keys
end

local function pickVehicle(job, tpl)
    local v = tpl.vehicle or {}
    if v.source == 'catalog' and job.type == 'dealer' and JB.dealerCatalog then
        local cars = {}
        for _, e in ipairs(JB.dealerCatalog(job)) do
            if e.enabled and e.vtype == 'car' and e.stock ~= 0 then cars[#cars + 1] = e end
        end
        if #cars > 0 then
            local e = cars[math.random(#cars)]
            return { model = e.model, label = e.label }
        end
    end
    local models = v.models or {}
    if #models > 0 then
        local m = models[math.random(#models)]
        return { model = m, label = m }
    end
end

local function build(job, tpl, point)
    local startC = (point.data and point.data.spawn) or point.coords
    local keys, ki = shuffledLocations(), 0
    local steps, last = {}, nil
    local needsVehicle = false
    for i, st in ipairs(tpl.steps) do
        local s = { t = st.t, where = st.where, label = st.label, secs = st.secs, anim = st.anim, broken = st.broken, veh = st.veh, npc = st.npc, patient = st.patient, consume = st.consume }
        if st.t == 'spawn_vehicle' then needsVehicle = true end
        local loc
        if st.where == 'start' then
            loc = { x = startC.x, y = startC.y, z = startC.z, h = startC.h or 0.0, label = 'Point de mission' }
        elseif st.same and last then
            loc = last
        else
            ki = ki % #keys + 1
            local l = M.Locations[keys[ki]]
            loc = { x = l.x, y = l.y, z = l.z, h = l.h, label = l.label }
        end
        s.loc, last = loc, loc
        steps[i] = s
    end
    local vehicle
    if needsVehicle then
        vehicle = pickVehicle(job, tpl)
        if not vehicle then return nil, 'Aucun véhicule configuré pour cette mission (catalogue vide ou liste de modèles vide)' end
    end
    return steps, nil, vehicle
end

ESX.RegisterServerCallback('jobbuilder:missions:start', function(src, cb, pointId, tplId)
    local x, point = ESX.GetPlayerFromId(src), JB.Points[tonumber(pointId)]
    if not x or not point or point.type ~= 'missions' then return cb(fail('Point introuvable')) end
    if x.job.name ~= point.job_name or x.job.grade < point.min_grade then return cb(fail('Ce point n\'est pas accessible à ton métier / grade')) end
    if dist(src, point.coords) > Config.ServerDistance + 4.0 then return cb(fail('Tu es trop loin')) end
    local job = JB.Jobs[point.job_name]
    if not job or not enabledFor(job) then return cb(fail('Les missions PNJ sont désactivées')) end
    local tpl = findTpl(job, tostring(tplId))
    if not tpl then return cb(fail('Mission inconnue')) end
    if x.job.grade < tpl.minGrade then return cb(fail('Ton grade est insuffisant pour cette mission')) end
    if Active[src] then return cb(fail('Tu as déjà une mission en cours (F6 → Missions pour l\'annuler)')) end
    local cdKey = x.identifier .. '|' .. job.name .. '|' .. tpl.id
    local left = (Cooldown[cdKey] or 0) - now()
    if left > 0 then return cb(fail(('Patiente encore %d s avant de refaire cette mission'):format(left))) end

    local steps, err, vehicle = build(job, tpl, point)
    if not steps then return cb(fail(err)) end
    nextId = nextId + 1
    Active[src] = { id = nextId, job = job.name, tpl = tpl, label = tpl.label, steps = steps, idx = 1, started = now(), hasVehicle = vehicle ~= nil, cdKey = cdKey }
    local peds = (tpl.peds and #tpl.peds > 0) and tpl.peds or M.Peds
    cb({ ok = true, mission = { id = nextId, label = tpl.label, timeLimit = tpl.timeLimit, steps = steps, vehicle = vehicle, peds = peds } })
end)

-- Le client signale qu'il a terminé l'étape idx : la position du joueur est vérifiée côté serveur
ESX.RegisterServerCallback('jobbuilder:missions:step', function(src, cb, id, idx)
    local a = Active[src]
    idx = tonumber(idx)
    if not a or a.id ~= id or a.idx ~= idx then return cb(fail('Mission invalide')) end
    local st = a.steps[idx]
    local skipDistance = st.t == 'spawn_vehicle' and st.where == 'loc'
    if st.loc and not skipDistance and dist(src, st.loc) > M.Tolerance + 25.0 then
        return cb(fail('Tu n\'es pas au bon endroit pour valider cette étape'))
    end
    a.idx = idx + 1
    cb({ ok = true, done = a.idx > #a.steps })
end)

ESX.RegisterServerCallback('jobbuilder:missions:complete', function(src, cb, id, health)
    local a, x = Active[src], ESX.GetPlayerFromId(src)
    if not a or a.id ~= id or not x or a.idx <= #a.steps then return cb(fail('Mission non terminée')) end
    local elapsed = now() - a.started
    if elapsed < M.MinSeconds then Active[src] = nil return cb(fail('Mission annulée (terminée trop vite)')) end
    local job = JB.Jobs[a.job]
    if not job then Active[src] = nil return cb(fail('Job introuvable')) end

    local r = a.tpl.reward
    local reward = (r.max > r.min) and math.random(r.min, r.max) or r.min
    reward = reward * ((job.settings.missions_mult or 100) / 100)
    local bonus = 0
    if a.tpl.timeLimit > 0 and elapsed <= a.tpl.timeLimit and M.TimeBonus > 0 then
        bonus = math.floor(reward * M.TimeBonus / 100)
        reward = reward + bonus
    end
    health = tonumber(health)
    if a.hasVehicle and health and M.DamageMaxPenalty > 0 then
        local pct = M.DamageMaxPenalty * (1 - math.max(0, math.min(1000, health)) / 1000)
        reward = reward * (1 - pct / 100)
    end
    reward = math.floor(reward)

    local paid, note = reward, nil
    if reward > 0 then
        if job.society and (job.settings.missions_source == 'society') then
            if not JB.societyRemove(job.name, reward) then paid, note = 0, 'La société n\'a pas assez d\'argent : mission non payée.' end
        else
            x.addAccountMoney(M.RewardAccount, reward)
        end
    end
    MySQL.insert('INSERT INTO jobbuilder_mission_stats (identifier, job_name, done, earned) VALUES (?, ?, 1, ?) ON DUPLICATE KEY UPDATE done = done + 1, earned = earned + VALUES(earned)',
        { x.identifier, job.name, paid })
    Cooldown[a.cdKey] = now() + (a.tpl.cooldown or M.Cooldown)
    JB.log(job.name, x, 'mission_done', ('%s : %d$ en %ds'):format(a.label, paid, elapsed))
    Active[src] = nil
    cb({ ok = true, reward = paid, bonus = bonus, note = note })
end)

ESX.RegisterServerCallback('jobbuilder:missions:cancel', function(src, cb)
    Active[src] = nil
    cb({ ok = true })
end)

ESX.RegisterServerCallback('jobbuilder:missions:status', function(src, cb)
    local a, x = Active[src], ESX.GetPlayerFromId(src)
    if not x then return cb(fail('Joueur introuvable')) end
    local job = JB.Jobs[x.job.name]
    if not job or not enabledFor(job) then return cb(fail('Les missions PNJ sont désactivées pour ton métier')) end
    local st = MySQL.single.await('SELECT done, earned FROM jobbuilder_mission_stats WHERE identifier = ? AND job_name = ?', { x.identifier, job.name }) or {}
    cb({
        ok = true, jobLabel = job.label, stats = { done = st.done or 0, earned = st.earned or 0 },
        active = a and {
            label = a.label, idx = math.min(a.idx, #a.steps), total = #a.steps, stepLabel = a.steps[math.min(a.idx, #a.steps)].label,
            elapsed = now() - a.started, timeLimit = a.tpl.timeLimit,
        } or nil,
    })
end)

AddEventHandler('esx:setJob', function(src)
    local a, x = Active[src], ESX.GetPlayerFromId(src)
    if a and x and x.job.name ~= a.job then
        Active[src] = nil
        TriggerClientEvent('jobbuilder:client:missionCancel', src, 'Mission annulée : tu as changé de métier.')
    end
end)

AddEventHandler('playerDropped', function() Active[source] = nil end)
