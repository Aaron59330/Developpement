ESX = exports['es_extended']:getSharedObject()

AJ = {
    Modules = {},     -- Modules[clé] = { start = function(src, ctx) -> payload | nil, err ; stop = function(src, state) }
    Active = {},      -- Active[src] = { job = clé, state = {}, started = os.time() }
    Points = {},      -- Points[clé][type] = liste de points (base de données, sinon valeurs par défaut)
    Stats = {},       -- Stats[identifier][clé] = { xp, done }
}

local function fail(msg) return { ok = false, error = msg } end

function AJ.notify(src, msg, kind) TriggerClientEvent('aj:client:notify', src, msg, kind or 'info') end

function AJ.isAdmin(src)
    if src == 0 then return true end
    local x = ESX.GetPlayerFromId(src)
    if not x then return false end
    local g = x.getGroup()
    for _, a in ipairs(Config.AdminGroups) do if g == a then return true end end
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
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS activejobs_points (
        id INT AUTO_INCREMENT PRIMARY KEY, job VARCHAR(30) NOT NULL, kind VARCHAR(20) NOT NULL, label VARCHAR(80) NULL,
        x FLOAT NOT NULL, y FLOAT NOT NULL, z FLOAT NOT NULL, h FLOAT NOT NULL DEFAULT 0, INDEX idx_job (job, kind)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS activejobs_stats (
        identifier VARCHAR(80) NOT NULL, job VARCHAR(30) NOT NULL, xp INT NOT NULL DEFAULT 0, done INT NOT NULL DEFAULT 0, earned INT NOT NULL DEFAULT 0,
        PRIMARY KEY (identifier, job)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
end

-- Crée les jobs ESX manquants (jamais d'écrasement d'un job existant)
local function ensureJobs()
    local created = 0
    for _, key in ipairs(Config.JobOrder) do
        local j = Config.Jobs[key]
        local exists = MySQL.scalar.await('SELECT 1 FROM jobs WHERE name = ?', { j.job })
        if not exists then
            MySQL.insert.await('INSERT INTO jobs (name, label, whitelisted) VALUES (?, ?, 0)', { j.job, j.label })
            created = created + 1
        end
        for i, g in ipairs(j.grades) do
            local has = MySQL.scalar.await('SELECT 1 FROM job_grades WHERE job_name = ? AND grade = ?', { j.job, i - 1 })
            if not has then
                MySQL.insert.await("INSERT INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female) VALUES (?, ?, ?, ?, ?, '{}', '{}')",
                    { j.job, i - 1, g.name, g.label, g.salary })
            end
        end
    end
    if created > 0 then
        if ESX.RefreshJobs then pcall(ESX.RefreshJobs) else print('^3[activejobs] Redémarre es_extended pour prendre en compte les nouveaux jobs.^0') end
        print(('^2[activejobs] %d job(s) créé(s) dans la table jobs.^0'):format(created))
    end
end

-- ─────────────────────────────── Points ───────────────────────────────
function AJ.loadPoints()
    AJ.Points = {}
    local rows = MySQL.query.await('SELECT * FROM activejobs_points ORDER BY id') or {}
    for _, r in ipairs(rows) do
        AJ.Points[r.job] = AJ.Points[r.job] or {}
        local l = AJ.Points[r.job][r.kind] or {}
        l[#l + 1] = { id = r.id, x = r.x, y = r.y, z = r.z, h = r.h, label = r.label or '' }
        AJ.Points[r.job][r.kind] = l
    end
    -- valeurs par défaut pour les types sans point en base
    for key, kinds in pairs(Config.DefaultPoints) do
        AJ.Points[key] = AJ.Points[key] or {}
        for kind, list in pairs(kinds) do
            if not AJ.Points[key][kind] then
                local copy = {}
                for _, p in ipairs(list) do copy[#copy + 1] = { id = 0, x = p.x, y = p.y, z = p.z, h = p.h or 0.0, label = p.label or '' } end
                AJ.Points[key][kind] = copy
            end
        end
    end
    AJ.Points.train = AJ.Points.train or {}
    if not AJ.Points.train.station then
        local copy = {}
        for _, p in ipairs(Config.TrainStations) do copy[#copy + 1] = { id = 0, x = p.x, y = p.y, z = p.z, h = 0.0, label = p.label } end
        AJ.Points.train.station = copy
    end
end

function AJ.points(key, kind) return (AJ.Points[key] and AJ.Points[key][kind]) or {} end

-- Position de sortie du véhicule : point « spawn » sinon 7 m devant le dépôt
function AJ.spawnPoint(key)
    local s = AJ.points(key, 'spawn')[1]
    if s then return s end
    local d = AJ.points(key, 'depot')[1]
    if not d then return nil end
    local rad = math.rad(d.h)
    return { x = d.x - math.sin(rad) * 7.0, y = d.y + math.cos(rad) * 7.0, z = d.z, h = d.h }
end

function AJ.syncPoints(src)
    TriggerClientEvent('aj:client:points', src or -1, AJ.Points)
end

-- ─────────────────────────────── Stats / niveau / paie ───────────────────────────────
local function levelOf(xp) return math.min(Config.XP.MaxLevel, 1 + math.floor((xp or 0) / Config.XP.PerLevel)) end
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
    return Config.XP.VipPayBonus[l] or 0
end

-- Paie une mission : base × (niveau + VIP) ; ajoute de l'XP (et fait monter de niveau / de grade). Retourne le montant versé.
function AJ.pay(src, key, base, xpGain, reason, doneCount)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return 0 end
    local s = AJ.stat(xPlayer, key)
    local before = levelOf(s.xp)
    local mult = 1 + (before - 1) * Config.XP.PayPerLevel / 100 + vipBonus(src) / 100
    local amount = math.floor(math.max(0, base) * mult)
    if amount > 0 then xPlayer.addAccountMoney(Config.Account, amount, reason or Config.Jobs[key].label) end
    s.xp = s.xp + math.max(0, math.floor(xpGain or 0))
    s.done = s.done + (doneCount or 0)
    s.earned = s.earned + amount
    local after = levelOf(s.xp)
    if after > before then
        AJ.notify(src, ('Niveau %d atteint : %s !'):format(after, Config.Jobs[key].label), 'success')
        local grade = 0
        for lvl, g in pairs(Config.XP.Promotions) do if after >= lvl and g > grade then grade = g end end
        if grade > 0 and xPlayer.job.name == Config.Jobs[key].job and xPlayer.job.grade < grade and Config.Jobs[key].grades[grade + 1] then
            xPlayer.setJob(Config.Jobs[key].job, grade)
            AJ.notify(src, ('Promotion : %s !'):format(Config.Jobs[key].grades[grade + 1].label), 'success')
        end
    end
    saveStat(xPlayer, key)
    return amount
end

-- ─────────────────────────────── Service (début / fin) ───────────────────────────────
function AJ.isWorker(src, key)
    local x = ESX.GetPlayerFromId(src)
    return x ~= nil and x.job.name == Config.Jobs[key].job
end

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

ESX.RegisterServerCallback('aj:panel', function(src, cb, key)
    local j = Config.Jobs[key]
    local x = ESX.GetPlayerFromId(src)
    if not j or not x then return cb(fail('Métier inconnu')) end
    local dep = AJ.points(key, 'depot')[1]
    if not dep or not AJ.near(src, dep, 8.0) then return cb(fail('Trop loin du PNJ')) end
    local s = AJ.stat(x, key)
    local lvl = levelOf(s.xp)
    local gradeLabel = nil
    if x.job.name == j.job then gradeLabel = (j.grades[x.job.grade + 1] or {}).label end
    cb({ ok = true, key = key, label = j.label, icon = j.icon, desc = j.desc, worker = x.job.name == j.job, gradeLabel = gradeLabel, level = lvl, maxLevel = Config.XP.MaxLevel,
        xp = s.xp, xpInLevel = s.xp - (lvl - 1) * Config.XP.PerLevel, xpPerLevel = Config.XP.PerLevel, done = s.done, earned = s.earned, active = AJ.Active[src] ~= nil and AJ.Active[src].job == key,
        payBonus = (lvl - 1) * Config.XP.PayPerLevel + vipBonus(src), grades = j.grades })
end)

ESX.RegisterServerCallback('aj:join', function(src, cb, key)
    local j, x = Config.Jobs[key], ESX.GetPlayerFromId(src)
    if not j or not x then return cb(fail('Erreur')) end
    local dep = AJ.points(key, 'depot')[1]
    if not dep or not AJ.near(src, dep, 8.0) then return cb(fail('Trop loin du PNJ')) end
    if x.job.name == j.job then return cb(fail('Tu fais déjà ce métier')) end
    -- on ne prend pas un job géré par un autre builder (police, ems…) : seulement le chômage ou un autre métier actif de ce script
    local keepOut = false
    for _, k in ipairs(Config.JobOrder) do if Config.Jobs[k].job == x.job.name then keepOut = true end end
    if x.job.name ~= 'unemployed' and not keepOut then return cb(fail('Quitte d\'abord ton métier actuel')) end
    AJ.stopShift(src, 'Changement de métier')
    x.setJob(j.job, 0)
    cb({ ok = true })
end)

ESX.RegisterServerCallback('aj:leave', function(src, cb, key)
    local j, x = Config.Jobs[key], ESX.GetPlayerFromId(src)
    if not j or not x or x.job.name ~= j.job then return cb(fail('Tu ne fais pas ce métier')) end
    AJ.stopShift(src, 'Tu as quitté le métier')
    x.setJob('unemployed', 0)
    cb({ ok = true })
end)

ESX.RegisterServerCallback('aj:start', function(src, cb, key)
    local j, x, m = Config.Jobs[key], ESX.GetPlayerFromId(src), AJ.Modules[key]
    if not j or not x or not m then return cb(fail('Métier indisponible')) end
    if x.job.name ~= j.job then return cb(fail('Rejoins d\'abord ce métier')) end
    if AJ.Active[src] then return cb(fail('Tu as déjà un service en cours')) end
    local dep = AJ.points(key, 'depot')[1]
    if not dep or not AJ.near(src, dep, 8.0) then return cb(fail('Trop loin du PNJ')) end
    local state = {}
    local payload, err = m.start(src, state)
    if not payload then return cb(fail(err or 'Impossible de commencer')) end
    AJ.Active[src] = { job = key, state = state, started = os.time() }
    TriggerClientEvent('aj:client:start', src, key, payload)
    cb({ ok = true })
end)

ESX.RegisterServerCallback('aj:stop', function(src, cb)
    AJ.stopShift(src, 'Service terminé')
    cb({ ok = true })
end)

AddEventHandler('playerDropped', function() AJ.stopShift(source, nil) end)
-- si le joueur change de métier hors du script, son service est arrêté
AddEventHandler('esx:setJob', function(src, job)
    local a = AJ.Active[src]
    if a and job and job.name ~= Config.Jobs[a.job].job then AJ.stopShift(src, 'Tu n\'as plus ce métier') end
end)

AddEventHandler('esx:playerLoaded', function(src) SetTimeout(1500, function() AJ.syncPoints(src) end) end)
RegisterNetEvent('aj:server:requestPoints', function() AJ.syncPoints(source) end)

-- ─────────────────────────────── Administration : points ───────────────────────────────
RegisterCommand('ajpoint', function(src, args)
    if not AJ.isAdmin(src) or src == 0 then return end
    local key, kind = args[1], args[2]
    if not Config.Jobs[key] or not kind or not kind:match('^[%a_]+$') then
        return AJ.notify(src, 'Usage : /ajpoint <métier> <type> [nom]  — métiers : ' .. table.concat(Config.JobOrder, ', '), 'error')
    end
    local ped = GetPlayerPed(src)
    local c, h = GetEntityCoords(ped), GetEntityHeading(ped)
    table.remove(args, 1) table.remove(args, 1)
    local label = table.concat(args, ' '):sub(1, 80)
    local id = MySQL.insert.await('INSERT INTO activejobs_points (job, kind, label, x, y, z, h) VALUES (?, ?, ?, ?, ?, ?, ?)', { key, kind, label, c.x, c.y, c.z, h })
    AJ.loadPoints() AJ.syncPoints()
    AJ.notify(src, ('Point #%d ajouté : %s / %s'):format(id, key, kind), 'success')
end, false)

RegisterCommand('ajpoints', function(src, args)
    if not AJ.isAdmin(src) then return end
    local key = args[1]
    local out = {}
    for kind, list in pairs(AJ.Points[key] or {}) do
        for _, p in ipairs(list) do out[#out + 1] = ('[%s] #%s %s (%.1f, %.1f, %.1f)%s'):format(kind, p.id == 0 and 'défaut' or p.id, p.label, p.x, p.y, p.z, '') end
    end
    table.sort(out)
    local text = #out > 0 and table.concat(out, '\n') or 'Aucun point.'
    if src == 0 then print(text) else TriggerClientEvent('aj:client:printPoints', src, key, out) end
end, false)

RegisterCommand('ajdelpoint', function(src, args)
    if not AJ.isAdmin(src) then return end
    local id = tonumber(args[1])
    if not id then return AJ.notify(src, 'Usage : /ajdelpoint <id>', 'error') end
    MySQL.update.await('DELETE FROM activejobs_points WHERE id = ?', { id })
    AJ.loadPoints() AJ.syncPoints()
    AJ.notify(src, 'Point supprimé.', 'success')
end, false)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    installTables()
    ensureJobs()
    AJ.loadPoints()
    SetTimeout(1000, function() AJ.syncPoints() end)
    print('^2[activejobs] Métiers actifs chargés.^0')
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for src in pairs(AJ.Active) do AJ.stopShift(src, nil) end
end)

exports('GetActiveJob', function(src) local a = AJ.Active[tonumber(src)] return a and a.job or nil end)
