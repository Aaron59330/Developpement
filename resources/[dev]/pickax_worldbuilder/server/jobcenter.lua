-- ─────────────────────────────── Pôle emploi : petits jobs en libre accès + quêtes ───────────────────────────────
local C = Config.JobCenter
local Active, Cool = {}, {}      -- [src] = quête en cours ; [identifier|job|quête] = fin de cooldown
local nextId = 0

local function fail(msg) return { ok = false, error = msg } end
local function now() return os.time() end

local JOBS, BY = C.Jobs, {}
for _, j in ipairs(JOBS) do BY[j.name] = j end

local function gradeOf(done)
    local g = 0
    for i, n in ipairs(C.Promotions or {}) do if done >= n then g = i end end
    return g
end

-- ─────────────────────────────── Création des jobs dans la base ───────────────────────────────
-- jobs + job_grades (ESX) + fiche jobbuilder_jobs (menu F6 : « Mes quêtes », « Quitter le métier »). Ne modifie jamais un job qui existe déjà.
local function ensureJobs()
    if not C.Enabled then return end
    local created = {}
    local hasJB = pcall(MySQL.scalar.await, 'SELECT 1 FROM jobbuilder_jobs LIMIT 1')
    for _, j in ipairs(JOBS) do
        local exists = MySQL.scalar.await('SELECT 1 FROM jobs WHERE name = ? LIMIT 1', { j.name })
        if not exists then
            MySQL.insert.await('INSERT INTO jobs (name, label, whitelisted) VALUES (?, ?, 0)', { j.name, j.label })
            for i, g in ipairs(j.grades) do
                MySQL.insert.await("INSERT INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female) VALUES (?, ?, ?, ?, ?, '{}', '{}')",
                    { j.name, i - 1, g[1], g[2], g[3] })
            end
            created[#created + 1] = j.label
        end
        if hasJB then
            local ok = pcall(function()
                MySQL.insert.await([[INSERT IGNORE INTO jobbuilder_jobs (name, label, type, whitelisted, society, boss_grade, blip, settings, created_by) VALUES (?, ?, 'custom', 0, 0, ?, '{}', ?, 'polemploi')]],
                    { j.name, j.label, #j.grades, json.encode({ missions_enabled = false, announce_enabled = false, smalljob = true, actions = {} }) })
            end)
            if not ok then print('^3[worldbuilder] Pôle emploi : fiche jobbuilder non créée pour ' .. j.name .. '^0') end
        end
    end
    if #created > 0 or hasJB then
        pcall(function() exports.pickax_jobbuilder:Reload() end)
        if #created > 0 then
            if ESX.RefreshJobs then pcall(ESX.RefreshJobs) end
            print(('^2[worldbuilder] Pôle emploi : %d job(s) créé(s) dans la base : %s^0'):format(#created, table.concat(created, ', ')))
        end
    end
end

local function hasCenter()
    for _, e in pairs(WB.Entities) do if e.type == 'jobcenter' then return true end end
    return false
end

local prevChanged, prevReady = WB.onEntityChanged, WB.onReady
WB.onEntityChanged = function(e)
    if prevChanged then prevChanged(e) end
    if e and e.type == 'jobcenter' then CreateThread(ensureJobs) end
end
WB.onReady = function()
    if prevReady then prevReady() end
    CreateThread(function()
        MySQL.query.await([[CREATE TABLE IF NOT EXISTS worldbuilder_jobcenter_stats (
            identifier VARCHAR(80) NOT NULL, job_name VARCHAR(40) NOT NULL, done INT NOT NULL DEFAULT 0, earned BIGINT NOT NULL DEFAULT 0,
            PRIMARY KEY (identifier, job_name)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
        if hasCenter() then ensureJobs() end
    end)
end
RegisterCommand('wbjobs', function(src)      -- (re)crée les jobs du pôle emploi à la main : console serveur ou groupe autorisé
    if src ~= 0 and not WB.isAdmin(src) then return end
    ensureJobs()
end, false)

-- ─────────────────────────────── Données pour le menu ───────────────────────────────
local function isFreeJob(name)
    if BY[name] then return true end
    for _, n in ipairs(C.FreeJobs or {}) do if n == name then return true end end
    return false
end

local function statsOf(identifier, job)
    return MySQL.single.await('SELECT done, earned FROM worldbuilder_jobcenter_stats WHERE identifier = ? AND job_name = ?', { identifier, job }) or { done = 0, earned = 0 }
end

local function questList(x, jobName)
    local j = BY[jobName]
    if not j then return {}, nil end
    local st = statsOf(x.identifier, jobName)
    local g = x.job.name == jobName and x.job.grade or 0
    local out = {}
    for _, q in ipairs(j.quests) do
        local cd = math.max(0, (Cool[x.identifier .. '|' .. jobName .. '|' .. q.id] or 0) - now())
        out[#out + 1] = { id = q.id, label = q.label, desc = q.desc, min = q.reward[1], max = q.reward[2], steps = q.spots * 2, cooldownLeft = cd }
    end
    return out, { done = st.done, earned = st.earned, grade = g, bonus = (C.GradeBonus or {})[g + 1] or 0, next = (C.Promotions or {})[g + 1] }
end

local function payload(x, label)
    local jobs = {}
    local cur = x.job.name
    for _, j in ipairs(JOBS) do
        local lo, hi = 9e9, 0
        for _, q in ipairs(j.quests) do lo = math.min(lo, q.reward[1]) hi = math.max(hi, q.reward[2]) end
        jobs[#jobs + 1] = { id = j.name, label = j.label, icon = j.icon, desc = j.desc, quests = #j.quests, min = lo, max = hi, current = cur == j.name, salary = j.grades[1][3] }
    end
    local quests, st = questList(x, cur)
    local a = Active[x.source]
    return { ok = true, label = label, jobs = jobs, current = cur, currentLabel = x.job.label, isSmall = BY[cur] ~= nil, quests = quests, stats = st,
        gradeLabel = x.job.grade_label, active = a and { label = a.label, idx = math.min(a.idx, #a.steps), total = #a.steps } or nil }
end

ESX.RegisterServerCallback('worldbuilder:jobcenter:info', function(src, cb, eid, pi)
    local x = ESX.GetPlayerFromId(src)
    if not x then return cb(fail('Joueur introuvable')) end
    if eid and tonumber(eid) and tonumber(eid) > 0 then       -- depuis un guichet : le point doit exister, être actif et proche
        local e = WB.Entities[tonumber(eid) or 0]
        local p = e and e.type == 'jobcenter' and e.enabled and e.points[tonumber(pi) or 0]
        if not p or not p.coords or not WB.near(src, p.coords, 4.0) then return cb(fail('Trop loin du guichet')) end
        return cb(payload(x, (p.label and p.label ~= '') and p.label or e.label))
    end
    if not BY[x.job.name] then return cb(fail('Pour prendre un job, rends-toi à un guichet Pôle emploi')) end
    cb(payload(x, 'Mes quêtes'))      -- depuis le menu F6 : uniquement les quêtes d'un petit job déjà pris
end)

ESX.RegisterServerCallback('worldbuilder:jobcenter:take', function(src, cb, eid, pi, jobName)
    local x = ESX.GetPlayerFromId(src)
    if not x then return cb(fail('Joueur introuvable')) end
    local e, p
    if tonumber(eid) and tonumber(eid) > 0 then      -- au guichet : le point doit être actif et proche
        e = WB.Entities[tonumber(eid)]
        p = e and e.type == 'jobcenter' and e.enabled and e.points[tonumber(pi) or 0]
        if not p or not p.coords or not WB.near(src, p.coords, 4.0) then return cb(fail('Trop loin du guichet')) end
    else
        return cb(fail('Prends ton job à un guichet Pôle emploi'))      -- l'embauche n'est possible qu'au point marker, jamais depuis F6
    end
    local j = BY[tostring(jobName)]
    if not j then return cb(fail('Job inconnu')) end
    if x.job.name == j.name then return cb(fail('C\'est déjà ton job')) end
    if not isFreeJob(x.job.name) then return cb(fail('Quitte d\'abord ton métier actuel (F6 → Quitter le métier)')) end
    if not ESX.DoesJobExist(j.name, 0) then
        ensureJobs()
        if not ESX.DoesJobExist(j.name, 0) then return cb(fail('Le job vient d\'être créé : réessaie dans quelques secondes')) end
    end
    -- reprend le grade acquis dans ce job (promotions)
    local grade = math.min(gradeOf(statsOf(x.identifier, j.name).done), #j.grades - 1)
    if not ESX.DoesJobExist(j.name, grade) then grade = 0 end
    Active[src] = nil
    x.setJob(j.name, grade)
    if e then WB.log(e, x, 'take', j.label) end
    cb(payload(ESX.GetPlayerFromId(src) or x, p and p.label or 'Pôle emploi'))
end)

ESX.RegisterServerCallback('worldbuilder:jobcenter:leave', function(src, cb)
    local x = ESX.GetPlayerFromId(src)
    if not x or not BY[x.job.name] then return cb(fail('Tu n\'as pas de petit job')) end
    Active[src] = nil
    x.setJob((C.FreeJobs or { 'unemployed' })[1], 0)
    cb({ ok = true })
end)

-- ─────────────────────────────── Quêtes ───────────────────────────────
local function pickSpots(n)
    local idx = {}
    for i = 1, #C.Locations do idx[i] = i end
    for i = #idx, 2, -1 do local j = math.random(i) idx[i], idx[j] = idx[j], idx[i] end
    local out = {}
    for i = 1, n do
        local l = C.Locations[idx[(i - 1) % #idx + 1]]
        out[i] = { label = l[1], x = l[2], y = l[3], z = l[4], h = l[5] }
    end
    return out
end

ESX.RegisterServerCallback('worldbuilder:jobcenter:questStart', function(src, cb, questId)
    local x = ESX.GetPlayerFromId(src)
    if not x then return cb(fail('Joueur introuvable')) end
    local j = BY[x.job.name]
    if not j then return cb(fail('Prends d\'abord un petit job au pôle emploi')) end
    local q
    for _, t in ipairs(j.quests) do if t.id == tostring(questId) then q = t end end
    if not q then return cb(fail('Quête inconnue')) end
    if Active[src] then return cb(fail('Tu as déjà une quête en cours')) end
    local key = x.identifier .. '|' .. j.name .. '|' .. q.id
    local left = (Cool[key] or 0) - now()
    if left > 0 then return cb(fail(('Patiente encore %d s avant de refaire cette quête'):format(left))) end

    local steps = {}
    for _, s in ipairs(pickSpots(q.spots)) do
        steps[#steps + 1] = { t = 'goto', loc = s, label = ('%s — %s'):format(q.go, s.label) }
        steps[#steps + 1] = { t = 'work', loc = s, label = q.work, anim = q.anim, secs = q.secs }
    end
    nextId = nextId + 1
    Active[src] = { id = nextId, job = j.name, q = q, label = q.label, steps = steps, idx = 1, started = now(), lastT = now(), key = key }
    cb({ ok = true, mission = { id = nextId, label = q.label, steps = steps } })
end)

ESX.RegisterServerCallback('worldbuilder:jobcenter:questStep', function(src, cb, id, idx)
    local a, x = Active[src], ESX.GetPlayerFromId(src)
    idx = tonumber(idx)
    if not a or not x or a.id ~= id or a.idx ~= idx or x.job.name ~= a.job then return cb(fail('Quête invalide')) end
    local st = a.steps[idx]
    if WB.distanceTo(src, st.loc) > C.Tolerance then return cb(fail('Tu n\'es pas au bon endroit pour valider cette étape')) end
    if st.t == 'work' and now() - a.lastT < math.floor(st.secs * 0.7) then return cb(fail('Étape validée trop vite')) end
    a.idx, a.lastT = idx + 1, now()
    cb({ ok = true, done = a.idx > #a.steps })
end)

ESX.RegisterServerCallback('worldbuilder:jobcenter:questFinish', function(src, cb, id)
    local a, x = Active[src], ESX.GetPlayerFromId(src)
    if not a or not x or a.id ~= id or a.idx <= #a.steps or x.job.name ~= a.job then return cb(fail('Quête non terminée')) end
    Active[src] = nil
    local j = BY[a.job]
    local st = statsOf(x.identifier, a.job)
    local reward = math.random(a.q.reward[1], math.max(a.q.reward[1], a.q.reward[2]))
    local bonus = (C.GradeBonus or {})[x.job.grade + 1] or 0
    reward = math.floor(reward * (100 + bonus) / 100)
    x.addAccountMoney(C.RewardAccount or 'money', reward)
    Cool[a.key] = now() + (C.Cooldown or 45)
    local done = st.done + 1
    MySQL.insert('INSERT INTO worldbuilder_jobcenter_stats (identifier, job_name, done, earned) VALUES (?, ?, 1, ?) ON DUPLICATE KEY UPDATE done = done + 1, earned = earned + VALUES(earned)', { x.identifier, a.job, reward })
    local promoted
    local newGrade = math.min(gradeOf(done), #j.grades - 1)
    if newGrade > x.job.grade and ESX.DoesJobExist(a.job, newGrade) then x.setJob(a.job, newGrade) promoted = j.grades[newGrade + 1][2] end
    cb({ ok = true, reward = reward, bonus = bonus, promoted = promoted, done = done })
end)

ESX.RegisterServerCallback('worldbuilder:jobcenter:questCancel', function(src, cb)
    Active[src] = nil
    cb({ ok = true })
end)

AddEventHandler('esx:setJob', function(src, job)
    local a = Active[src]
    if a and job and job.name ~= a.job then
        Active[src] = nil
        TriggerClientEvent('worldbuilder:client:jobcenterCancel', src, 'Quête annulée : tu as changé de métier.')
    end
end)
AddEventHandler('playerDropped', function() Active[source] = nil end)
