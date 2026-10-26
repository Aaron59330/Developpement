local function ECO(kind, n) if GetResourceState('pickax_economy') ~= 'started' then return n end local ok, r = pcall(function() return exports.pickax_economy:Scale(kind, n) end) return (ok and tonumber(r)) or n end   -- type d'économie du serveur (pickax_economy, optionnel)
AJ = {
    Modules = {},     -- Modules[clé] = { start = function(src, ctx) -> payload | nil, err ; stop = function(src, state) }
    Active = {},      -- Active[src] = { job = clé, state = {}, started = os.time() }
    Stats = {},       -- Stats[identifier][clé] = { xp, done }
}

function AJ.notify(src, msg, kind) TriggerClientEvent('aj:client:notify', src, msg, kind or 'info') end

function AJ.isAdmin(src)
    if src == 0 then return true end
    local x = ESX.GetPlayerFromId(src)
    if not x then return false end
    local g = x.getGroup()
    for _, a in ipairs(Config.Act.AdminGroups) do if g == a then return true end end
    return false
end

function AJ.near(src, c, dist)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or not c then return false end
    local p = GetEntityCoords(ped)
    return #(vector3(p.x, p.y, p.z) - vector3(c.x, c.y, c.z)) <= (dist or 12.0)
end

-- ─────────────────────────────── Base de données ───────────────────────────────
local function installTables()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS activejobs_stats (
        identifier VARCHAR(80) NOT NULL, job VARCHAR(30) NOT NULL, xp INT NOT NULL DEFAULT 0, done INT NOT NULL DEFAULT 0, earned INT NOT NULL DEFAULT 0,
        PRIMARY KEY (identifier, job)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS activejobs_achievements (
        identifier VARCHAR(80) NOT NULL, id VARCHAR(60) NOT NULL, at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (identifier, id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
end

-- ─────────────────────────────── Lien avec le Job Builder (même ressource) ───────────────────────────────
-- Types de job : garbage, towing, carwash, trucker, farmer, firefighter, train (Config.JobTypes). Ici : le gameplay de l'activité.
function AJ.meta(jobName)
    local job = JB.Jobs[jobName]
    if not job then return nil end
    return { name = job.name, type = job.type, label = job.label, grades = job.grades, boss_grade = job.boss_grade }
end

-- Clé du module d'activité d'un joueur (selon le type de son job)
function AJ.keyOf(xPlayer)
    local m = xPlayer and AJ.meta(xPlayer.job.name)
    return m and Config.Act.Jobs[m.type] and m.type or nil, m
end

local function xyz(c, label) return { x = c.x + 0.0, y = c.y + 0.0, z = c.z + 0.0, h = (c.h or 0.0) + 0.0, label = label or '' } end

-- Points d'activité du job : { rôle = { {x,y,z,h,label}, ... } } dans l'ordre de création
local function activityRoles(jobName)
    local list, out = {}, {}
    for _, p in pairs(JB.Points) do if p.job_name == jobName and p.type == 'actpoint' and p.data.role then list[#list + 1] = p end end
    table.sort(list, function(a, b) return a.id < b.id end)
    for _, p in ipairs(list) do
        out[p.data.role] = out[p.data.role] or {}
        table.insert(out[p.data.role], xyz(p.coords, p.label))
    end
    return out
end

-- Points du terrain pour une session : poste d'activité (dépôt), sortie du véhicule, points d'activité du Job Builder, sinon valeurs par défaut
local function buildPts(key, jobName, point)
    local pts = {}
    for role, list in pairs(activityRoles(jobName)) do pts[role] = list end
    pts.depot = { { x = point.coords.x, y = point.coords.y, z = point.coords.z, h = point.coords.h or 0.0, label = point.label } }
    if point.spawn then
        pts.spawn = { point.spawn }
    else
        local d, rad = pts.depot[1], math.rad(point.coords.h or 0.0)
        pts.spawn = { { x = d.x - math.sin(rad) * 7.0, y = d.y + math.cos(rad) * 7.0, z = d.z, h = d.h } }
    end
    local j = Config.Act.Jobs[key]
    for role, list in pairs(Config.Act.DefaultPoints[key] or {}) do
        if role ~= 'depot' and not pts[role] then
            pts[role] = {}
            for _, p in ipairs(list) do pts[role][#pts[role] + 1] = { x = p.x, y = p.y, z = p.z, h = p.h or 0.0, label = p.label or '' } end
        end
    end
    if not pts.zone and j.zones then
        pts.zone = {}
        for _, z in ipairs(j.zones) do pts.zone[#pts.zone + 1] = { x = z.x, y = z.y, z = z.z or 0.0, h = 0.0, label = z.label or '' } end
    end
    if not pts.fire and j.sites then
        pts.fire = {}
        for _, z in ipairs(j.sites) do pts.fire[#pts.fire + 1] = { x = z.x, y = z.y, z = z.z, h = 0.0, label = z.label or '' } end
    end
    if not pts.station and key == 'train' then
        pts.station = {}
        for _, z in ipairs(Config.Act.TrainStations) do pts.station[#pts.station + 1] = { x = z.x, y = z.y, z = z.z, h = 0.0, label = z.label } end
    end
    return pts
end

-- Liste des points d'une session (les modules lisent state.pts)
function AJ.pts(st, kind) return (st and st.pts and st.pts[kind]) or {} end
function AJ.spawnPoint(st) return AJ.pts(st, 'spawn')[1] end

-- ─────────────────────────────── Stats / niveau / paie ───────────────────────────────
local function levelOf(xp) return math.min(Config.Act.XP.MaxLevel, 1 + math.floor((xp or 0) / Config.Act.XP.PerLevel)) end
function AJ.level(xp) return levelOf(xp) end

function AJ.stat(xPlayer, key)
    local id = xPlayer.identifier
    AJ.Stats[id] = AJ.Stats[id] or {}
    local s = AJ.Stats[id][key]
    if not s then
        local r = MySQL.single.await('SELECT xp, done, earned FROM activejobs_stats WHERE identifier = ? AND job = ?', { id, key })
        s = { xp = r and r.xp or 0, done = r and r.done or 0, earned = r and r.earned or 0 }
        AJ.Stats[id][key] = s
    end
    return s
end

local function saveStat(xPlayer, key)
    local s = AJ.Stats[xPlayer.identifier] and AJ.Stats[xPlayer.identifier][key]
    if s then
        MySQL.update('INSERT INTO activejobs_stats (identifier, job, xp, done, earned) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE xp = VALUES(xp), done = VALUES(done), earned = VALUES(earned)',
            { xPlayer.identifier, key, s.xp, s.done, s.earned })
    end
end

local function vipBonus(src)
    local ok, l = pcall(function() return exports.pickax_core:GetVIPLevel(src) end)
    l = ok and tonumber(l) or 0
    return Config.Act.XP.VipPayBonus[l] or 0
end

-- ─────────────────────────────── Titres & succès ───────────────────────────────
function AJ.title(level)
    local best, bl = nil, 0
    for lvl, t in pairs(Config.Act.XP.Titles or {}) do if lvl <= level and lvl >= bl then best, bl = t, lvl end end
    return best
end

AJ.Ach = {}   -- AJ.Ach[identifier] = { [id] = true }
local function achSet(identifier)
    local set = AJ.Ach[identifier]
    if not set then
        set = {}
        for _, r in ipairs(MySQL.query.await('SELECT id FROM activejobs_achievements WHERE identifier = ?', { identifier }) or {}) do set[r.id] = true end
        AJ.Ach[identifier] = set
    end
    return set
end
AddEventHandler('playerDropped', function() local x = ESX.GetPlayerFromId(source) if x then AJ.Ach[x.identifier] = nil end end)

-- Valeur actuelle d'un succès pour un joueur
local function achProgress(xPlayer, def)
    if def.job ~= '*' then
        local s = AJ.stat(xPlayer, def.job)
        if def.stat == 'done' then return s.done elseif def.stat == 'earned' then return s.earned else return levelOf(s.xp) end
    end
    local total, jobs, lv = 0, 0, 0
    local earned = 0
    for key in pairs(Config.Act.Jobs) do
        local s = AJ.stat(xPlayer, key)
        total = total + s.done; earned = earned + s.earned
        if s.done > 0 then jobs = jobs + 1 end
        if levelOf(s.xp) >= (def.level or 1) then lv = lv + 1 end
    end
    if def.stat == 'done' then return total elseif def.stat == 'earned' then return earned elseif def.stat == 'jobs' then return jobs else return lv end
end

-- Débloque les succès atteints (appelé après chaque paie) ; verse la récompense une seule fois (INSERT IGNORE)
function AJ.checkAchievements(src, xPlayer, key)
    local set = achSet(xPlayer.identifier)
    for _, def in ipairs(Config.Act.Achievements or {}) do
        if not set[def.id] and (def.job == '*' or def.job == key) and achProgress(xPlayer, def) >= def.target then
            local inserted = MySQL.update.await('INSERT IGNORE INTO activejobs_achievements (identifier, id) VALUES (?, ?)', { xPlayer.identifier, def.id }) or 0
            set[def.id] = true
            if inserted > 0 then
                local r = def.reward or {}
                if (r.money or 0) > 0 then xPlayer.addAccountMoney(Config.Act.Account, r.money, 'Succès : ' .. def.label) end
                if (r.xp or 0) > 0 and def.job ~= '*' then
                    local s = AJ.stat(xPlayer, def.job)
                    s.xp = s.xp + r.xp
                    saveStat(xPlayer, def.job)
                end
                local bits = {}
                if (r.money or 0) > 0 then bits[#bits + 1] = ('+%d$'):format(r.money) end
                if (r.xp or 0) > 0 and def.job ~= '*' then bits[#bits + 1] = ('+%d XP'):format(r.xp) end
                AJ.notify(src, ('Succès débloqué : %s%s'):format(def.label, #bits > 0 and (' (' .. table.concat(bits, ', ') .. ')') or ''), 'success')
                TriggerClientEvent('aj:client:achievement', src, { label = def.label, desc = def.desc, reward = bits })
            end
        end
    end
end

-- Liste pour le panneau : succès du métier + succès généraux, avec la progression
function AJ.achievementList(xPlayer, key)
    local set = achSet(xPlayer.identifier)
    local out = {}
    for _, def in ipairs(Config.Act.Achievements or {}) do
        if def.job == '*' or def.job == key then
            local cur = achProgress(xPlayer, def)
            out[#out + 1] = { id = def.id, label = def.label, desc = def.desc, target = def.target, progress = math.min(cur, def.target), done = set[def.id] == true,
                general = def.job == '*', reward = def.reward or {} }
        end
    end
    table.sort(out, function(a, b) if a.done ~= b.done then return a.done end if a.general ~= b.general then return a.general end return a.target < b.target end)
    return out
end

-- Paie une mission : base × (niveau + VIP) ; ajoute de l'XP (et fait monter de niveau / de grade). Retourne le montant versé.
function AJ.pay(src, key, base, xpGain, reason, doneCount)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return 0 end
    local s = AJ.stat(xPlayer, key)
    local before = levelOf(s.xp)
    local mult = 1 + (before - 1) * Config.Act.XP.PayPerLevel / 100 + vipBonus(src) / 100
    local amount = ECO('income', math.floor(math.max(0, base) * mult))
    local meta = AJ.meta(xPlayer.job.name)
    local label = meta and meta.label or Config.Act.Jobs[key].label
    if amount > 0 then xPlayer.addAccountMoney(Config.Act.Account, amount, reason or label) end
    s.xp = s.xp + math.max(0, math.floor(xpGain or 0))
    s.done = s.done + (doneCount or 0)
    s.earned = s.earned + amount
    local after = levelOf(s.xp)
    if after > before then
        AJ.notify(src, ('Niveau %d atteint : %s !'):format(after, label), 'success')
        -- promotion automatique : jamais jusqu'au grade boss ni au-delà du nombre de grades du job
        local grade = 0
        for lvl, g in pairs(Config.Act.XP.Promotions) do if after >= lvl and g > grade then grade = g end end
        if meta and grade > 0 then
            local cap = math.max(0, (meta.boss_grade or #meta.grades) - 1)
            grade = math.min(grade, cap, #meta.grades - 1)
            if xPlayer.job.grade < grade then
                xPlayer.setJob(xPlayer.job.name, grade)
                AJ.notify(src, ('Promotion : %s !'):format((meta.grades[grade + 1] or {}).label or ('grade ' .. grade)), 'success')
            end
        end
    end
    saveStat(xPlayer, key)
    AJ.checkAchievements(src, xPlayer, key)
    return amount
end

-- ─────────────────────────────── Service (début / fin) ───────────────────────────────
-- État de service du joueur s'il est bien en service sur ce métier
function AJ.session(src, key)
    local a = AJ.Active[src]
    if a and a.job == key then return a.state, a end
end

function AJ.dist(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, (a.z or 0.0) - (b.z or 0.0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function AJ.stopShift(src, reason)
    local a = AJ.Active[src]
    if not a then return end
    AJ.Active[src] = nil
    local m = AJ.Modules[a.job]
    if m and m.stop then pcall(m.stop, src, a.state) end
    TriggerClientEvent('aj:client:stop', src, a.job, reason or '')
end

local function onDuty(src) return JB.isOnDuty(src) end

-- Vérifie le poste d'activité : point existant, bon job, grade, proximité et service pris dans le Job Builder
local function context(src, pointId)
    local x = ESX.GetPlayerFromId(src)
    if not x then return nil, 'Erreur' end
    local p = JB.Points[tonumber(pointId)]
    local job = p and JB.Jobs[p.job_name]
    if not p or p.type ~= 'activity' or not job then return nil, 'Poste introuvable' end
    local point = { id = p.id, job = p.job_name, type = job.type, min_grade = p.min_grade, label = p.label, coords = xyz(p.coords, p.label), spawn = p.data.spawn and xyz(p.data.spawn, 'Sortie véhicule') or nil }
    if x.job.name ~= point.job then return nil, 'Ce poste n\'appartient pas à ton métier' end
    if x.job.grade < (point.min_grade or 0) then return nil, 'Ton grade est insuffisant' end
    if not AJ.near(src, point.coords, 10.0) then return nil, 'Tu es trop loin du poste' end
    if not onDuty(src) then return nil, 'Prends ton service (F6) pour utiliser ce poste' end
    local key = point.type
    if not Config.Act.Jobs[key] then return nil, 'Ce type de job n\'a pas d\'activité' end
    return { x = x, key = key, point = point }
end

local function fail(msg) return { ok = false, error = msg } end

-- Données du panneau (ouvert par le point « Poste d'activité » via JB.openActivity)
local function panelData(src, pointId, cb)
    local c, err = context(src, pointId)
    if not c then return cb(fail(err)) end
    local j, x, key = Config.Act.Jobs[c.key], c.x, c.key
    local meta = AJ.meta(x.job.name) or { grades = {}, label = j.label }
    local s = AJ.stat(x, key)
    local lvl = levelOf(s.xp)
    cb({ ok = true, kind = 'activity', pointId = pointId, key = key, label = meta.label or j.label, icon = j.icon, desc = j.desc, worker = true, gradeLabel = (meta.grades[x.job.grade + 1] or {}).label,
        level = lvl, maxLevel = Config.Act.XP.MaxLevel, xp = s.xp, xpInLevel = s.xp - (lvl - 1) * Config.Act.XP.PerLevel, xpPerLevel = Config.Act.XP.PerLevel,
        done = s.done, earned = s.earned, active = AJ.Active[src] ~= nil and AJ.Active[src].job == key,
        payBonus = (lvl - 1) * Config.Act.XP.PayPerLevel + vipBonus(src), grades = meta.grades,
        title = AJ.title(lvl), achievements = AJ.achievementList(x, key) })
end

function JB.openActivity(src, xPlayer, point, job, cb) panelData(src, point.id, cb) end

ESX.RegisterServerCallback('aj:start', function(src, cb, pointId)
    local c, err = context(src, pointId)
    if not c then return cb(fail(err)) end
    local m = AJ.Modules[c.key]
    if not m then return cb(fail('Activité indisponible')) end
    if AJ.Active[src] then return cb(fail('Tu as déjà un service en cours')) end
    local state = { pts = buildPts(c.key, c.x.job.name, c.point), jobName = c.x.job.name }
    local payload, e = m.start(src, state)
    if not payload then return cb(fail(e or 'Impossible de commencer')) end
    payload.pts = state.pts
    AJ.Active[src] = { job = c.key, jobName = c.x.job.name, state = state, started = os.time() }
    TriggerClientEvent('aj:client:start', src, c.key, payload)
    cb({ ok = true })
end)

ESX.RegisterServerCallback('aj:stop', function(src, cb)
    AJ.stopShift(src, 'Activité terminée')
    cb({ ok = true })
end)

AddEventHandler('playerDropped', function() AJ.stopShift(source, nil) end)
-- changement de métier hors du script : l'activité s'arrête
AddEventHandler('esx:setJob', function(src, job)
    local a = AJ.Active[src]
    if a and job and job.name ~= a.jobName then AJ.stopShift(src, 'Tu n\'as plus ce métier') end
end)
-- fin de service dans le Job Builder : l'activité s'arrête aussi
CreateThread(function()
    while true do
        Wait(4000)
        for src, a in pairs(AJ.Active) do if not onDuty(src) then AJ.stopShift(src, 'Service terminé') end end
    end
end)

-- ─────────────────────────────── Administration ───────────────────────────────
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    installTables()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for src in pairs(AJ.Active) do AJ.stopShift(src, nil) end
end)

exports('GetActiveActivity', function(src) local a = AJ.Active[tonumber(src)] return a and a.job or nil end)
