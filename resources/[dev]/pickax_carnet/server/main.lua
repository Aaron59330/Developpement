-- ─────────────────────────────── Carnet du joueur : serveur ───────────────────────────────
-- Les progressions arrivent par exports.pickax_carnet:Report(src, métrique, quantité) (appelé par les métiers, boutiques, mini-jeux…),
-- et par la boucle interne (temps de jeu, lieux visités, temps passé avec d'autres joueurs) + la distance rapportée par le client (plafonnée).
-- Tout est payé automatiquement ; l'état de chaque joueur est un petit JSON en base (carnet_players), celui de la ville dans carnet_state.

local ESX = exports['es_extended']:getSharedObject()
local P = {}                 -- [src] = { id = identifier, d = données, dirty = bool }
local Comm = nil             -- défi de la ville en cours { week, metric, target, progress, done, label, min }
local lastDist = {}          -- [src] = GetGameTimer() du dernier rapport de distance

-- ─────────────── Utilitaires ───────────────
local function setting(key, default)
    if GetResourceState('pickax_settings') ~= 'started' then return default end
    local ok, v = pcall(function() return exports.pickax_settings:Get(key) end)
    if ok and v ~= nil then return v end
    return default
end
local function enabled() return setting('carnet_enabled', Config.Enabled) ~= false end
local function rewardMul() return math.max(0, tonumber(setting('carnet_reward_mult', Config.RewardMultiplier)) or 1.0) end

local function dayIndex(now) return math.floor(((now or os.time()) + Config.UtcOffset * 3600 - Config.ResetHour * 3600) / 86400) end
local function weekIndex(now) return math.floor((dayIndex(now) + 3) / 7) end            -- le jour 0 (jeudi 1er janv. 1970) + 3 = lundi
local function secondsToNextDay(now) now = now or os.time() return 86400 - ((now + Config.UtcOffset * 3600 - Config.ResetHour * 3600) % 86400) end
local function secondsToNextWeek(now)
    local d = dayIndex(now)
    local daysLeft = 7 - ((d + 3) % 7) - 1
    return daysLeft * 86400 + secondsToNextDay(now)
end

local function hash(s) local h = 5381 for i = 1, #s do h = (h * 33 + s:byte(i)) % 2147483647 end return h end
local function rng(seed) local x = seed % 2147483647 if x <= 0 then x = x + 2147483646 end return function(n) x = (x * 48271) % 2147483647 return (x % n) + 1 end end

local function fmtNum(n) local s = tostring(math.floor(n)) local out = s:reverse():gsub('(%d%d%d)', '%1 '):reverse():gsub('^ ', '') return out end
local function label(goal, target) return (goal.label:gsub('{n}', fmtNum(target))) end

local function notify(src, msg) TriggerClientEvent('esx:showNotification', src, msg) end

local function pay(src, amount, reason)
    amount = math.floor((tonumber(amount) or 0) * rewardMul())
    if amount <= 0 then return 0 end
    if GetResourceState('pickax_economy') == 'started' then
        local ok, r = pcall(function() return exports.pickax_economy:Scale('income', amount) end)
        if ok and tonumber(r) then amount = math.floor(tonumber(r)) end
    end
    local x = ESX.GetPlayerFromId(src)
    if not x or amount <= 0 then return 0 end
    x.addAccountMoney(Config.Account, amount, reason or 'Carnet')
    return amount
end

-- ─────────────── Base de données ───────────────
local ready = false
CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS carnet_players (
        identifier VARCHAR(80) NOT NULL PRIMARY KEY, data LONGTEXT NOT NULL, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS carnet_state (
        k VARCHAR(40) NOT NULL PRIMARY KEY, v LONGTEXT NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    local row = MySQL.single.await("SELECT v FROM carnet_state WHERE k = 'community'")
    if row then local ok, v = pcall(json.decode, row.v) if ok and type(v) == 'table' then Comm = v end end
    ready = true
end)

local commDirty = false
local function saveComm()
    if not commDirty or not Comm then return end
    commDirty = false
    MySQL.update("INSERT INTO carnet_state (k, v) VALUES ('community', ?) ON DUPLICATE KEY UPDATE v = VALUES(v)", { json.encode(Comm) })
end

-- ─────────────── Défi de la ville ───────────────
local function rollCommunity()
    local C = Config.Community
    if not C.Enabled or #C.Challenges == 0 then Comm = nil return end
    local week = weekIndex()
    if Comm and Comm.week == week then return end
    local ch = C.Challenges[(week % #C.Challenges) + 1]       -- rotation prévisible : une activité différente chaque semaine
    Comm = { week = week, metric = ch.metric, target = ch.target, min = ch.min or 1, progress = 0, done = false, label = ch.label }
    commDirty = true
end

-- ─────────────── Génération des objectifs ───────────────
local function eligible(goal, ctx)
    if goal.needs == 'job' then return ctx.hasJob end
    if goal.needs == 'gang' then return ctx.inGang end
    return true
end

local function context(src)
    local x = ESX.GetPlayerFromId(src)
    local hasJob = x and x.job and x.job.name and x.job.name ~= 'unemployed' or false
    local inGang = false
    if GetResourceState('pickax_gangbuilder') == 'started' then
        local ok, g = pcall(function() return exports.pickax_gangbuilder:GetPlayerGang(src) end)
        inGang = ok and g ~= nil and g.name ~= nil and g.name ~= 'unemployed2' or false
    end
    return { hasJob = hasJob, inGang = inGang }
end

local function rollDaily(identifier, day, ctx)
    local r = rng(hash(identifier) + day * 7919)
    local goals, used = {}, {}
    for tier = 1, 3 do
        local pool = {}
        for _, g in ipairs(Config.Goals) do
            if not used[g.metric] and g.targets[tier] and eligible(g, ctx) then pool[#pool + 1] = g end
        end
        local g = pool[r(#pool)]
        if g then
            used[g.metric] = true
            goals[#goals + 1] = { id = g.id, metric = g.metric, tier = tier, target = g.targets[tier], progress = 0, done = false, reward = Config.Daily.Rewards[tier] or 0 }
        end
    end
    return goals
end

local function rollWeekly(identifier, week, ctx)
    local r = rng(hash(identifier) * 31 + week * 104729)
    local pool = {}
    for _, g in ipairs(Config.Goals) do if g.weekly and eligible(g, ctx) then pool[#pool + 1] = g end end
    local g = pool[r(#pool)]
    if not g then return nil end
    return { id = g.id, metric = g.metric, target = g.weekly, progress = 0, done = false, reward = Config.Weekly.Reward }
end

local function goalDef(id) for _, g in ipairs(Config.Goals) do if g.id == id then return g end end end

-- ─────────────── Données d'un joueur ───────────────
local function fresh() return { streak = 0, best = 0, lastClaim = -999, day = -1, goals = {}, bonus = false, week = -1, wgoal = nil, vday = {}, comm = { week = -1, contrib = 0, paid = false }, total = 0 } end

local function save(src, force)
    local s = P[src]
    if not s or (not s.dirty and not force) then return end
    s.dirty = false
    MySQL.update('INSERT INTO carnet_players (identifier, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)', { s.id, json.encode(s.d) })
end

local function payCommunity(src, s)
    if not Comm or not Comm.done or s.d.comm.week ~= Comm.week or s.d.comm.paid then return end
    if s.d.comm.contrib < (Comm.min or 1) then return end
    s.d.comm.paid, s.dirty = true, true
    local got = pay(src, Config.Community.Reward, 'Défi de la ville')
    if got > 0 then notify(src, ('~g~Défi de la ville réussi !~s~ Ta part : ~g~+%d $~s~'):format(got)) end
end

-- remet à jour les objectifs si le jour / la semaine a changé ; attribue la récompense de série (une fois par jour)
local function refresh(src, s)
    local today, week = dayIndex(), weekIndex()
    local d = s.d
    local ctx = context(src)
    if d.day ~= today then d.day, d.goals, d.bonus, d.vday, s.dirty = today, rollDaily(s.id, today, ctx), false, {}, true end
    if d.week ~= week then d.week, d.wgoal, s.dirty = week, rollWeekly(s.id, week, ctx), true end
    if d.comm.week ~= (Comm and Comm.week or -1) then d.comm, s.dirty = { week = Comm and Comm.week or -1, contrib = 0, paid = false }, true end
    if Config.Streak.Enabled and d.lastClaim ~= today then
        local gap = today - d.lastClaim
        if gap == 1 or (gap > 1 and gap <= 1 + (Config.Streak.GraceDays or 0)) then d.streak = d.streak + 1 else d.streak = 1 end
        d.best, d.lastClaim, s.dirty = math.max(d.best, d.streak), today, true
        local rewards = Config.Streak.Rewards
        local amount = rewards[((d.streak - 1) % #rewards) + 1] or 0
        local got = pay(src, amount, 'Série de connexion')
        if got > 0 then notify(src, ('~y~Série de %d jour(s)~s~ : ~g~+%d $~s~ — ouvre ton carnet (~y~%s~s~) pour voir tes objectifs du jour !'):format(d.streak, got, Config.Key)) end
    end
    payCommunity(src, s)
end

local function load(src)
    local x = ESX.GetPlayerFromId(src)
    if not x then return end
    local id = x.identifier
    local row = MySQL.single.await('SELECT data FROM carnet_players WHERE identifier = ?', { id })
    local d = fresh()
    if row then local ok, v = pcall(json.decode, row.data) if ok and type(v) == 'table' then for k, val in pairs(v) do d[k] = val end end end
    d.comm = type(d.comm) == 'table' and d.comm or fresh().comm
    d.vday = type(d.vday) == 'table' and d.vday or {}
    P[src] = { id = id, d = d, dirty = not row }
    if enabled() then refresh(src, P[src]) end
end

-- ─────────────── Progression ───────────────
local function tell(src, text) notify(src, text) end

local function completeGoal(src, s, g, kind)
    g.done, s.dirty = true, true
    s.d.total = (s.d.total or 0) + 1
    local got = pay(src, g.reward, kind == 'week' and 'Objectif de la semaine' or 'Objectif du jour')
    local def = goalDef(g.id)
    local name = def and label(def, g.target) or g.id
    tell(src, ('%s ~g~Objectif terminé~s~ : %s — ~g~+%d $~s~'):format(kind == 'week' and '★' or '✓', name, got))
end

local function advance(src, s, metric, amount)
    local d, changed = s.d, false
    for _, g in ipairs(d.goals) do
        if not g.done and g.metric == metric then
            g.progress = math.min(g.target, g.progress + amount) changed = true
            if g.progress >= g.target then completeGoal(src, s, g, 'day') end
        end
    end
    if d.wgoal and not d.wgoal.done and d.wgoal.metric == metric then
        d.wgoal.progress = math.min(d.wgoal.target, d.wgoal.progress + amount) changed = true
        if d.wgoal.progress >= d.wgoal.target then completeGoal(src, s, d.wgoal, 'week') end
    end
    if changed and not d.bonus then
        local all = #d.goals > 0
        for _, g in ipairs(d.goals) do if not g.done then all = false end end
        if all then
            d.bonus = true
            local got = pay(src, Config.Daily.BonusAll, 'Objectifs du jour')
            tell(src, ('~y~Journée parfaite !~s~ Les 3 objectifs sont terminés : ~g~+%d $~s~'):format(got))
        end
    end
    if Comm and not Comm.done and Comm.metric == metric and d.comm.week == Comm.week then
        Comm.progress, commDirty = Comm.progress + amount, true
        d.comm.contrib, changed = (d.comm.contrib or 0) + amount, true
        if Comm.progress >= Comm.target then
            Comm.done = true
            TriggerClientEvent('esx:showNotification', -1, ('~y~Défi de la ville réussi !~s~ %s'):format(label({ label = Comm.label }, Comm.target)))
            local B = Config.Community.Boost
            if B and B.swing and B.swing ~= 0 and GetResourceState('pickax_economy') == 'started' then
                pcall(function() exports.pickax_economy:Event('all', B.swing, B.hours or 1) end)
                TriggerClientEvent('esx:showNotification', -1, ('~g~Bonus pour toute la ville~s~ : gains +%d %% pendant %d h !'):format(math.floor(B.swing * 100 + 0.5), B.hours or 1))
            end
            for other, so in pairs(P) do payCommunity(other, so) end
        end
    end
    if changed then s.dirty = true end
end

-- métrique rapportée par une autre ressource ; `who` = id serveur du joueur (ou identifiant)
local function resolve(who)
    if type(who) == 'number' then return who, P[who] end
    if type(who) == 'string' and not tonumber(who) then
        for src, s in pairs(P) do if s.id == who then return src, s end end
        return nil
    end
    who = tonumber(who)
    return who, who and P[who]
end

local function report(who, metric, amount)
    if not ready or not enabled() then return false end
    if amount == nil then amount = 1 else amount = tonumber(amount) end
    if not amount or amount <= 0 or amount ~= amount or amount > 1000000 or type(metric) ~= 'string' then return false end
    local src, s = resolve(who)
    if not s then return false end
    refresh(src, s)
    advance(src, s, metric, amount)
    return true
end

exports('Report', report)

-- ─────────────── Distance (rapportée par le client, plafonnée) ───────────────
RegisterNetEvent('pickax_carnet:dist', function(meters)
    local src = source
    meters = tonumber(meters)
    if not meters or meters ~= meters or meters <= 0 then return end
    local now = GetGameTimer()
    if lastDist[src] and now - lastDist[src] < 20000 then return end
    lastDist[src] = now
    meters = math.min(meters, Config.Distance.MaxPerReport)
    report(src, 'distance', meters / 1000)
end)

-- ─────────────── Boucle : temps de jeu, lieux, temps ensemble ───────────────
local function coordsOf(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local c = GetEntityCoords(ped)
    return c.x, c.y
end

local function minuteTick()
    if not ready or not enabled() then return end
    rollCommunity()
    local pos = {}
    for src in pairs(P) do local x, y = coordsOf(src) if x then pos[src] = { x, y } end end
    local D2 = Config.Social.Distance * Config.Social.Distance
    for src, s in pairs(P) do
        report(src, 'playtime', 1)
        local p = pos[src]
        if p then
            for _, pl in ipairs(Config.Places) do
                if not s.d.vday[pl.id] then
                    local dx, dy = p[1] - pl.x, p[2] - pl.y
                    if dx * dx + dy * dy <= pl.r * pl.r then
                        s.d.vday[pl.id], s.dirty = true, true
                        tell(src, ('Lieu découvert : ~y~%s~s~'):format(pl.label))
                        report(src, 'visit', 1)
                    end
                end
            end
            for other, q in pairs(pos) do
                if other ~= src then
                    local dx, dy = p[1] - q[1], p[2] - q[2]
                    if dx * dx + dy * dy <= D2 then report(src, 'social', 1) break end
                end
            end
        end
    end
end

CreateThread(function()
    while true do
        Wait(math.max(10, Config.PlaceCheckSeconds) * 1000)
        local ok, err = pcall(minuteTick)
        if not ok then print(('^1[carnet] erreur : %s^0'):format(tostring(err))) end
    end
end)

-- sauvegardes groupées
CreateThread(function()
    while true do
        Wait(60 * 1000)
        for src in pairs(P) do save(src) end
        saveComm()
    end
end)

-- ─────────────── Connexion / déconnexion ───────────────
AddEventHandler('esx:playerLoaded', function(src) SetTimeout(4000, function() if ready then rollCommunity() load(src) end end) end)
AddEventHandler('playerDropped', function() local src = source save(src, true) P[src], lastDist[src] = nil, nil end)
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetTimeout(3000, function() for _, src in ipairs(GetPlayers()) do load(tonumber(src)) end end)
end)
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for src in pairs(P) do save(src, true) end
    saveComm()
end)

-- ─────────────── Données pour l'interface ───────────────
local function snapshot(src)
    local s = P[src]
    if not s or not enabled() then return nil end
    refresh(src, s)
    local d, now = s.d, os.time()
    local goals = {}
    for _, g in ipairs(d.goals) do
        local def = goalDef(g.id)
        goals[#goals + 1] = { label = def and label(def, g.target) or g.id, metric = g.metric, tier = g.tier, target = g.target, progress = math.floor(g.progress * 10) / 10, done = g.done, reward = math.floor(g.reward * rewardMul()) }
    end
    local w = d.wgoal
    local week
    if w then
        local def = goalDef(w.id)
        week = { label = def and label(def, w.target) or w.id, metric = w.metric, target = w.target, progress = math.floor(w.progress * 10) / 10, done = w.done, reward = math.floor(w.reward * rewardMul()) }
    end
    local comm
    if Comm and Config.Community.Enabled then
        comm = { label = label({ label = Comm.label }, Comm.target), metric = Comm.metric, target = Comm.target, progress = math.floor(Comm.progress), done = Comm.done,
                 mine = math.floor((d.comm.week == Comm.week and d.comm.contrib or 0) * 10) / 10, min = Comm.min, paid = d.comm.paid == true,
                 reward = math.floor(Config.Community.Reward * rewardMul()), boost = Config.Community.Boost }
    end
    local rewards = {}
    for i, r in ipairs(Config.Streak.Rewards) do rewards[i] = math.floor(r * rewardMul()) end
    local places = {}
    for _, pl in ipairs(Config.Places) do places[#places + 1] = { label = pl.label, seen = d.vday[pl.id] == true } end
    return {
        ok = true, key = Config.Key, streak = d.streak, best = d.best, rewards = rewards, cycleDay = ((d.streak - 1) % #Config.Streak.Rewards) + 1,
        goals = goals, bonus = { amount = math.floor(Config.Daily.BonusAll * rewardMul()), done = d.bonus }, week = week, community = comm, places = places, total = d.total or 0,
        left = { day = secondsToNextDay(now), week = secondsToNextWeek(now) },
    }
end
exports('Snapshot', snapshot)

ESX.RegisterServerCallback('carnet:snapshot', function(src, cb) cb(snapshot(src) or { ok = false, error = 'Le carnet est désactivé ou pas encore prêt' }) end)

-- Test staff : /carnetreset (groupe admin) remet à zéro la série et les objectifs du jour du joueur qui tape la commande
RegisterCommand('carnetreset', function(src)
    if src == 0 or not P[src] then return end
    local x = ESX.GetPlayerFromId(src)
    local g = x and x.getGroup and x.getGroup()
    if g ~= 'admin' and g ~= 'superadmin' and g ~= '_dev' then return end
    P[src].d = fresh() P[src].dirty = true refresh(src, P[src])
    notify(src, 'Carnet réinitialisé.')
end, false)

-- hooks de test hors jeu
CARNET_TEST = { dayIndex = dayIndex, weekIndex = weekIndex, rollDaily = rollDaily, rollWeekly = rollWeekly, load = load, report = report, snapshot = snapshot, P = P, comm = function() return Comm end, minuteTick = minuteTick, save = save, secondsToNextWeek = secondsToNextWeek, setReady = function() ready = true end }

-- [AERO] contrôle de licence (pickax_guard) : cette ressource s'arrête si la licence n'est pas valide ou si pickax_guard est absent
CreateThread(function()
    local res = GetCurrentResourceName()
    Wait(20000 + math.random(0, 20000))
    while true do
        local valid = false
        for _ = 1, 4 do
            local ok, v = pcall(function() return exports.pickax_guard:Check(res) end)
            if ok and v == true then valid = true break end
            Wait(10000)
        end
        if not valid then print(('^1[AERO] %s arrêtée : licence invalide ou pickax_guard absent.^0'):format(res)) StopResource(res) return end
        Wait(240000 + math.random(0, 120000))
    end
end)
