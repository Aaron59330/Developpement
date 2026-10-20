-- ─────────────────────────────── Pôle emploi : petits jobs en libre accès + quêtes ───────────────────────────────
-- Point « Pôle emploi » (type jobcenter, public) → menu des petits jobs (Config.JobCenter.Jobs). Un clic = setJob.
-- Les jobs sont créés tout seuls dans la base (jobs + job_grades + fiche jobbuilder pour le menu F6) dès qu'un point Pôle emploi existe.
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

local function hasCenter()
    for _, p in pairs(JB.Points) do if p.type == 'jobcenter' then return true end end
    return false
end

-- ─────────────────────────────── Création des jobs dans la base ───────────────────────────────
-- Ne modifie jamais un job qui existe déjà dans ta table jobs.
local function ensureJobs()
    if not C.Enabled then return end
    local created = {}
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
        MySQL.insert.await([[INSERT IGNORE INTO jobbuilder_jobs (name, label, type, whitelisted, society, boss_grade, blip, settings, created_by) VALUES (?, ?, 'custom', 0, 0, ?, '{}', ?, 'polemploi')]],
            { j.name, j.label, #j.grades, json.encode({ missions_enabled = false, announce_enabled = false, smalljob = true, actions = {} }) })
    end
    JB.loadAll()
    if #created > 0 then
        JB.refreshESX()
        print(('^2[jobbuilder] Pôle emploi : %d job(s) créé(s) dans la base : %s^0'):format(#created, table.concat(created, ', ')))
    end
    JB.syncAll()
end

function JB.jobcenterAfterSave() if hasCenter() then ensureJobs() end end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(2500)
        MySQL.query.await([[CREATE TABLE IF NOT EXISTS jobbuilder_jobcenter_stats (
            identifier VARCHAR(80) NOT NULL, job_name VARCHAR(40) NOT NULL, done INT NOT NULL DEFAULT 0, earned BIGINT NOT NULL DEFAULT 0,
            PRIMARY KEY (identifier, job_name)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
        if hasCenter() then ensureJobs() end
    end)
end)
RegisterCommand('jbjobs', function(src)      -- (re)crée les petits jobs à la main : console serveur ou _dev
    if src ~= 0 and not JB.isDev(src) then return end
    ensureJobs()
end, false)

-- ─────────────────────────────── Données du menu ───────────────────────────────
local function isFreeJob(name)
    if BY[name] then return true end
    for _, n in ipairs(C.FreeJobs or {}) do if n == name then return true end end
    return false
end

local function statsOf(identifier, job)
    return MySQL.single.await('SELECT done, earned FROM jobbuilder_jobcenter_stats WHERE identifier = ? AND job_name = ?', { identifier, job }) or { done = 0, earned = 0 }
end

local function payload(x, label, pointId)
    local cur = x.job.name
    local jobs = {}
    for _, j in ipairs(JOBS) do
        local lo, hi = 9e9, 0
        for _, q in ipairs(j.quests) do lo = math.min(lo, q.reward[1]) hi = math.max(hi, q.reward[2]) end
        jobs[#jobs + 1] = { id = j.name, label = j.label, icon = j.icon, desc = j.desc, quests = #j.quests, min = lo, max = hi, current = cur == j.name }
    end
    local quests, st = {}, nil
    local cj = BY[cur]
    if cj then
        local s = statsOf(x.identifier, cur)
        local g = x.job.grade
        for _, q in ipairs(cj.quests) do
            local cd = math.max(0, (Cool[x.identifier .. '|' .. cur .. '|' .. q.id] or 0) - now())
            quests[#quests + 1] = { id = q.id, label = q.label, desc = q.desc, min = q.reward[1], max = q.reward[2], steps = q.spots * 2, cooldownLeft = cd }
        end
        st = { done = s.done, earned = s.earned, grade = g, bonus = (C.GradeBonus or {})[g + 1] or 0, next = (C.Promotions or {})[g + 1] }
    end
    local a = Active[x.source]
    return { ok = true, kind = 'jobcenter', label = label, pointId = pointId, jobs = jobs, current = cur, currentLabel = x.job.label, isSmall = cj ~= nil, quests = quests, stats = st,
        gradeLabel = x.job.grade_label, active = a and { label = a.label, idx = math.min(a.idx, #a.steps), total = #a.steps } or nil }
end

-- Appelé par runtime.lua à l'ouverture du point (touche E sur le guichet)
function JB.openJobcenter(src, x, point, job, cb)
    if not C.Enabled then return cb(fail('Le Pôle emploi est désactivé')) end
    cb(payload(x, point.label ~= '' and point.label or 'Pôle emploi', point.id))
end

-- Rafraîchissement du menu (guichet : pointId ; menu F6 : sans point)
ESX.RegisterServerCallback('jobbuilder:jobcenter:info', function(src, cb, pointId)
    local x = ESX.GetPlayerFromId(src)
    if not x then return cb(fail('Joueur introuvable')) end
    if pointId then
        local p = JB.Points[tonumber(pointId)]
        if not p or p.type ~= 'jobcenter' or JB.distanceTo(src, p.coords) > Config.ServerDistance then return cb(fail('Trop loin du guichet')) end
        return cb(payload(x, p.label ~= '' and p.label or 'Pôle emploi', p.id))
    end
    cb(payload(x, 'Mes quêtes'))
end)

ESX.RegisterServerCallback('jobbuilder:jobcenter:take', function(src, cb, pointId, jobName)
    local x = ESX.GetPlayerFromId(src)
    local p = JB.Points[tonumber(pointId) or 0]
    if not x or not p or p.type ~= 'jobcenter' or JB.distanceTo(src, p.coords) > Config.ServerDistance then return cb(fail('Trop loin du guichet')) end
    local j = BY[tostring(jobName)]
    if not j then return cb(fail('Job inconnu')) end
    if x.job.name == j.name then return cb(fail('C\'est déjà ton job')) end
    if not isFreeJob(x.job.name) then return cb(fail('Quitte d\'abord ton métier actuel (F6 → Quitter le métier)')) end
    if not ESX.DoesJobExist(j.name, 0) then
        ensureJobs()
        if not ESX.DoesJobExist(j.name, 0) then return cb(fail('Le job vient d\'être créé : réessaie dans quelques secondes')) end
    end
    local grade = math.min(gradeOf(statsOf(x.identifier, j.name).done), #j.grades - 1)      -- reprend le grade acquis dans ce job
    if not ESX.DoesJobExist(j.name, grade) then grade = 0 end
    Active[src] = nil
    x.setJob(j.name, grade)
    JB.log(j.name, x, 'jobcenter_take', j.label)
    cb(payload(ESX.GetPlayerFromId(src) or x, p.label, p.id))
end)

ESX.RegisterServerCallback('jobbuilder:jobcenter:leave', function(src, cb)
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

ESX.RegisterServerCallback('jobbuilder:jobcenter:questStart', function(src, cb, questId)
    local x = ESX.GetPlayerFromId(src)
    if not x then return cb(fail('Joueur introuvable')) end
    local j = BY[x.job.name]
    if not j then return cb(fail('Prends d\'abord un petit job au Pôle emploi')) end
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

ESX.RegisterServerCallback('jobbuilder:jobcenter:questStep', function(src, cb, id, idx)
    local a, x = Active[src], ESX.GetPlayerFromId(src)
    idx = tonumber(idx)
    if not a or not x or a.id ~= id or a.idx ~= idx or x.job.name ~= a.job then return cb(fail('Quête invalide')) end
    local st = a.steps[idx]
    if JB.distanceTo(src, st.loc) > C.Tolerance then return cb(fail('Tu n\'es pas au bon endroit pour valider cette étape')) end
    if st.t == 'work' and now() - a.lastT < math.floor(st.secs * 0.7) then return cb(fail('Étape validée trop vite')) end
    a.idx, a.lastT = idx + 1, now()
    cb({ ok = true, done = a.idx > #a.steps })
end)

ESX.RegisterServerCallback('jobbuilder:jobcenter:questFinish', function(src, cb, id)
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
    MySQL.insert('INSERT INTO jobbuilder_jobcenter_stats (identifier, job_name, done, earned) VALUES (?, ?, 1, ?) ON DUPLICATE KEY UPDATE done = done + 1, earned = earned + VALUES(earned)', { x.identifier, a.job, reward })
    JB.log(a.job, x, 'jobcenter_quest', ('%s : %d$'):format(a.label, reward))
    local promoted
    local newGrade = math.min(gradeOf(done), #j.grades - 1)
    if newGrade > x.job.grade and ESX.DoesJobExist(a.job, newGrade) then x.setJob(a.job, newGrade) promoted = j.grades[newGrade + 1][2] end
    cb({ ok = true, reward = reward, bonus = bonus, promoted = promoted, done = done })
end)

ESX.RegisterServerCallback('jobbuilder:jobcenter:questCancel', function(src, cb)
    Active[src] = nil
    cb({ ok = true })
end)

AddEventHandler('esx:setJob', function(src, job)
    local a = Active[src]
    if a and job and job.name ~= a.job then
        Active[src] = nil
        TriggerClientEvent('jobbuilder:client:jobcenterCancel', src, 'Quête annulée : tu as changé de métier.')
    end
end)
AddEventHandler('playerDropped', function() Active[source] = nil end)
