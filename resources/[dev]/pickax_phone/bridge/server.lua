-- ═════════════════════════════════════════════════════════════════════════════
--  Couche de compatibilité (serveur) : ESX · QBCore · Qbox · standalone
--  Tout le reste du téléphone passe par ces fonctions : on n'appelle jamais ESX / QBCore directement ailleurs.
-- ═════════════════════════════════════════════════════════════════════════════
Bridge = { fw = 'standalone', inv = 'none', society = 'none' }

local function started(name) return GetResourceState(name) == 'started' end
local function exists(name) local s = GetResourceState(name); return s ~= 'missing' and s ~= 'unknown' end
local function try(fn, ...) local ok, a, b = pcall(fn, ...); if ok then return a, b end end

-- ───────────── détection ─────────────
local function detectFramework()
    local f = (Config.Framework or 'auto'):lower()
    if f ~= 'auto' then return f end
    if exists('qbx_core') then return 'qbox' end
    if exists('es_extended') then return 'esx' end
    if exists('qb-core') then return 'qb' end
    return 'standalone'
end

local ESX, QBCore
local function waitFor(res)
    local t = 0
    while not started(res) and t < 600 do Wait(100); t = t + 1 end
end

local function initFramework()
    Bridge.fw = detectFramework()
    if Bridge.fw == 'esx' then waitFor('es_extended'); ESX = exports['es_extended']:getSharedObject()
    elseif Bridge.fw == 'qb' then waitFor('qb-core'); QBCore = exports['qb-core']:GetCoreObject()
    elseif Bridge.fw == 'qbox' then waitFor('qbx_core'); if started('qb-core') then QBCore = exports['qb-core']:GetCoreObject() end end
    -- inventaire
    local inv = (Config.Inventory or 'auto'):lower()
    if inv == 'auto' then
        if started('ox_inventory') then inv = 'ox'
        elseif started('qs-inventory') then inv = 'qs'
        elseif started('qb-inventory') or started('ps-inventory') or started('lj-inventory') then inv = 'qb'
        elseif Bridge.fw == 'esx' then inv = 'esx'
        elseif Bridge.fw == 'qb' then inv = 'qb'
        else inv = 'none' end
    end
    Bridge.inv = inv
    print(('^2[pickax_phone] framework : %s · inventaire : %s^7'):format(Bridge.fw, Bridge.inv))
end
Bridge.ready = false
CreateThread(function() initFramework(); Bridge.ready = true end)
function Bridge.Wait() while not Bridge.ready do Wait(50) end end

-- ───────────── joueurs ─────────────
local function qbPlayer(src)
    if Bridge.fw == 'qbox' then return try(function() return exports.qbx_core:GetPlayer(src) end) end
    return QBCore and QBCore.Functions.GetPlayer(src)
end
local function esxPlayer(src) return ESX and ESX.GetPlayerFromId(src) end

function Bridge.Players()
    local out = {}
    if Bridge.fw == 'esx' and ESX then
        for _, p in ipairs(ESX.GetExtendedPlayers()) do out[#out + 1] = p.source end
    else
        for _, s in ipairs(GetPlayers()) do
            s = tonumber(s)
            if Bridge.fw == 'standalone' or qbPlayer(s) then out[#out + 1] = s end
        end
    end
    return out
end

function Bridge.Identifier(src)
    if Bridge.fw == 'esx' then local x = esxPlayer(src); return x and x.identifier end
    if Bridge.fw == 'qb' or Bridge.fw == 'qbox' then local p = qbPlayer(src); return p and p.PlayerData.citizenid end
    local id = GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifierByType(src, 'license2')
    return id
end

function Bridge.Name(src)
    if Bridge.fw == 'esx' then local x = esxPlayer(src); return x and x.getName() end
    if Bridge.fw == 'qb' or Bridge.fw == 'qbox' then
        local p = qbPlayer(src); local ci = p and p.PlayerData.charinfo
        return ci and ((ci.firstname or '') .. ' ' .. (ci.lastname or '')) or nil
    end
    return GetPlayerName(src)
end

function Bridge.OfflineName(identifier)
    if Bridge.fw == 'esx' then
        local r = MySQL.single.await('SELECT firstname, lastname FROM users WHERE identifier = ?', { identifier })
        if r then return ((r.firstname or '') .. ' ' .. (r.lastname or '')):gsub('^%s+', '') end
    elseif Bridge.fw == 'qb' or Bridge.fw == 'qbox' then
        local r = MySQL.single.await('SELECT charinfo FROM players WHERE citizenid = ?', { identifier })
        local ci = r and json.decode(r.charinfo or '{}')
        if ci then return (ci.firstname or '') .. ' ' .. (ci.lastname or '') end
    end
    return nil
end

-- métier : { name, label, grade, gradeLabel, onDuty (bool|nil), isBoss (bool|nil) }
function Bridge.Job(src)
    if Bridge.fw == 'esx' then
        local x = esxPlayer(src); local j = x and x.job
        if not j then return nil end
        return { name = j.name, label = j.label, grade = j.grade or 0, gradeLabel = j.grade_label or j.grade_name, onDuty = j.onDuty }
    elseif Bridge.fw == 'qb' or Bridge.fw == 'qbox' then
        local p = qbPlayer(src); local j = p and p.PlayerData.job
        if not j then return nil end
        local g = type(j.grade) == 'table' and j.grade or { level = j.grade }
        return { name = j.name, label = j.label, grade = tonumber(g.level) or 0, gradeLabel = g.name, onDuty = j.onduty, isBoss = j.isboss }
    end
    return nil
end

function Bridge.PlayersByJob(jobName)
    local out = {}
    for _, s in ipairs(Bridge.Players()) do
        local j = Bridge.Job(s)
        if j and j.name == jobName then out[#out + 1] = { source = s, grade = j.grade, onDuty = j.onDuty } end
    end
    return out
end

function Bridge.SetJob(src, jobName, grade)
    if Bridge.fw == 'esx' then local x = esxPlayer(src); if x then x.setJob(jobName, grade) return true end
    elseif Bridge.fw == 'qbox' then local id = Bridge.Identifier(src); return id and try(function() exports.qbx_core:SetJob(id, jobName, grade) return true end) or false
    elseif Bridge.fw == 'qb' then local p = qbPlayer(src); if p then p.Functions.SetJob(jobName, grade) return true end end
    return false
end

-- Liste des métiers du framework : [nom] = { label, bossGrade, grades = { {grade, label, salary} } }
function Bridge.Jobs()
    local out = {}
    if Bridge.fw == 'esx' and ESX then
        local jobs = try(function() return ESX.GetJobs() end) or ESX.Jobs or {}
        for name, j in pairs(jobs) do
            local grades, boss = {}, -1
            for k, g in pairs(j.grades or {}) do
                local n = tonumber(g.grade or k) or 0
                grades[#grades + 1] = { grade = n, label = g.label or g.name, salary = g.salary }
                if n > boss then boss = n end
            end
            table.sort(grades, function(a, b) return a.grade < b.grade end)
            out[name] = { label = j.label or name, bossGrade = boss, grades = grades }
        end
    elseif Bridge.fw == 'qb' or Bridge.fw == 'qbox' then
        local jobs = (Bridge.fw == 'qbox' and try(function() return exports.qbx_core:GetJobs() end)) or (QBCore and QBCore.Shared.Jobs) or {}
        for name, j in pairs(jobs) do
            local grades, boss, top = {}, nil, -1
            for k, g in pairs(j.grades or {}) do
                local n = tonumber(k) or 0
                grades[#grades + 1] = { grade = n, label = g.name, salary = g.payment }
                if g.isboss and (not boss or n < boss) then boss = n end
                if n > top then top = n end
            end
            table.sort(grades, function(a, b) return a.grade < b.grade end)
            out[name] = { label = j.label or name, bossGrade = boss or top, grades = grades }
        end
    end
    return out
end

function Bridge.IsAdmin(src)
    if src == 0 then return true end
    local ace = Config.Admin.ace
    if ace and ace ~= '' and IsPlayerAceAllowed(src, ace) then return true end
    if Bridge.fw == 'esx' then
        local x = esxPlayer(src); local g = x and x.getGroup()
        for _, a in ipairs(Config.Admin.groups) do if a == g then return true end end
    elseif Bridge.fw == 'qb' or Bridge.fw == 'qbox' then
        for _, a in ipairs(Config.Admin.groups) do
            local ok = Bridge.fw == 'qbox' and try(function() return exports.qbx_core:HasPermission(src, a) end) or (QBCore and try(function() return QBCore.Functions.HasPermission(src, a) end))
            if ok then return true end
        end
    else
        return IsPlayerAceAllowed(src, 'command')
    end
    return false
end

-- ───────────── argent ─────────────
local function accName(kind)
    local v = Config.Accounts and Config.Accounts[kind]
    if v and v ~= 'auto' then return v end
    if Bridge.fw == 'esx' then return kind == 'cash' and 'money' or 'bank' end
    return kind                                     -- QBCore / Qbox : 'bank' / 'cash'
end
Bridge.AccountName = accName

function Bridge.Money(src, kind)
    local acc = accName(kind)
    if Bridge.fw == 'esx' then
        local x = esxPlayer(src); if not x then return 0 end
        if acc == 'money' then return x.getMoney() end
        local a = x.getAccount(acc); return a and a.money or 0
    elseif Bridge.fw == 'qb' or Bridge.fw == 'qbox' then
        local p = qbPlayer(src); return p and (p.PlayerData.money[acc] or 0) or 0
    end
    return 0
end

function Bridge.AddMoney(src, kind, amount, reason)
    amount = math.floor(tonumber(amount) or 0); if amount <= 0 then return false end
    local acc = accName(kind)
    if Bridge.fw == 'esx' then
        local x = esxPlayer(src); if not x then return false end
        if acc == 'money' then x.addMoney(amount) else x.addAccountMoney(acc, amount, reason) end
        return true
    elseif Bridge.fw == 'qbox' then return try(function() return exports.qbx_core:AddMoney(src, acc, amount, reason) end) and true or false
    elseif Bridge.fw == 'qb' then local p = qbPlayer(src); if p then p.Functions.AddMoney(acc, amount, reason) return true end end
    return false
end

function Bridge.RemoveMoney(src, kind, amount, reason)
    amount = math.floor(tonumber(amount) or 0); if amount <= 0 then return false end
    if Bridge.Money(src, kind) < amount then return false end
    local acc = accName(kind)
    if Bridge.fw == 'esx' then
        local x = esxPlayer(src); if not x then return false end
        if acc == 'money' then x.removeMoney(amount) else x.removeAccountMoney(acc, amount, reason) end
        return true
    elseif Bridge.fw == 'qbox' then return try(function() return exports.qbx_core:RemoveMoney(src, acc, amount, reason) end) and true or false
    elseif Bridge.fw == 'qb' then local p = qbPlayer(src); if p then return p.Functions.RemoveMoney(acc, amount, reason) and true or false end end
    return false
end

-- argent d'un joueur hors ligne (virement, gains du loto)
function Bridge.AddMoneyOffline(identifier, kind, amount)
    local acc = accName(kind)
    local cfg = Config.Database and Config.Database.players
    if type(cfg) ~= 'table' then
        if Bridge.fw == 'esx' then cfg = { table = 'users', identifier = 'identifier', money = 'accounts', moneyFormat = 'esx' }
        elseif Bridge.fw == 'qb' or Bridge.fw == 'qbox' then cfg = { table = 'players', identifier = 'citizenid', money = 'money', moneyFormat = 'qb' }
        else return false end
    end
    local row = MySQL.single.await(('SELECT `%s` AS m FROM `%s` WHERE `%s` = ?'):format(cfg.money, cfg.table, cfg.identifier), { identifier })
    if not row then return false end
    local m = json.decode(row.m or '{}') or {}
    m[acc] = (tonumber(m[acc]) or 0) + amount
    MySQL.update.await(('UPDATE `%s` SET `%s` = ? WHERE `%s` = ?'):format(cfg.table, cfg.money, cfg.identifier), { json.encode(m), identifier })
    return true
end

-- ───────────── comptes société ─────────────
local function societyMode(jobName)
    local m = (Config.Society or 'auto'):lower()
    if m ~= 'auto' then return m end
    if started('pickax_jobbuilder') and jobName and try(function() return exports.pickax_jobbuilder:GetJobInfo(jobName) end) then return 'jobbuilder' end
    if started('Renewed-Banking') then return 'renewed' end
    if started('qb-banking') then return 'qb-banking' end
    if started('qb-management') then return 'qb-management' end
    if started('okokBanking') then return 'okok' end
    if started('esx_addonaccount') or (Bridge.fw == 'esx' and started('pickax_core')) then return 'esx_addonaccount' end
    return 'none'
end

function Bridge.SocietyAdd(jobName, amount, reason)
    local m = societyMode(jobName)
    if m == 'jobbuilder' then return try(function() return exports.pickax_jobbuilder:AddJobMoney(jobName, amount) end) and true or false
    elseif m == 'renewed' then return try(function() return exports['Renewed-Banking']:addAccountMoney(jobName, amount) end) and true or false
    elseif m == 'qb-banking' then return try(function() return exports['qb-banking']:AddMoney(jobName, amount, reason or 'Aura') end) and true or false
    elseif m == 'qb-management' then return try(function() return exports['qb-management']:AddMoney(jobName, amount) end) and true or false
    elseif m == 'okok' then return try(function() return exports.okokBanking:AddMoney('society_' .. jobName, amount) end) and true or false
    elseif m == 'esx_addonaccount' then
        local done = false
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. jobName, function(acc) if acc then acc.addMoney(amount) done = true end end)
        return done
    elseif m == 'custom' and Config.Hooks.societyAdd then return Config.Hooks.societyAdd(jobName, amount, reason) and true or false end
    return false
end

function Bridge.SocietyBalance(jobName)
    local m = societyMode(jobName)
    if m == 'jobbuilder' then return try(function() return exports.pickax_jobbuilder:GetJobMoney(jobName) end) or 0
    elseif m == 'renewed' then return try(function() return exports['Renewed-Banking']:getAccountMoney(jobName) end) or 0
    elseif m == 'qb-banking' then return try(function() return exports['qb-banking']:GetAccountBalance(jobName) end) or 0
    elseif m == 'qb-management' then return try(function() return exports['qb-management']:GetAccount(jobName) end) or 0
    elseif m == 'okok' then return try(function() return exports.okokBanking:GetAccount('society_' .. jobName) end) or 0
    elseif m == 'esx_addonaccount' then
        local bal = 0
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. jobName, function(acc) if acc then bal = acc.money end end)
        return bal
    elseif m == 'custom' and Config.Hooks.societyBalance then return Config.Hooks.societyBalance(jobName) or 0 end
    return nil
end
function Bridge.HasSociety(jobName) return societyMode(jobName) ~= 'none' end

-- ───────────── véhicules possédés ─────────────
local function vehCfg()
    local c = Config.Database and Config.Database.vehicles
    if type(c) == 'table' then return c end
    if Bridge.fw == 'esx' then
        -- colonne « stored » (ESX d'origine) ou « state » (CorePickax) : détectée une fois
        if Bridge._esxVeh == nil then
            local col = MySQL.scalar.await("SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'owned_vehicles' AND COLUMN_NAME IN ('stored','state') ORDER BY COLUMN_NAME = 'state' DESC LIMIT 1")
            Bridge._esxVeh = { table = 'owned_vehicles', owner = 'owner', plate = 'plate', props = 'vehicle', stored = col or 'stored', storedValue = 1, impoundValue = col == 'state' and 2 or nil }
        end
        return Bridge._esxVeh
    end
    if Bridge.fw == 'qb' or Bridge.fw == 'qbox' then return { table = 'player_vehicles', owner = 'citizenid', plate = 'plate', props = 'mods', model = 'hash', stored = 'state', storedValue = 1 } end
    return nil
end

function Bridge.Vehicles(identifier)
    local c = vehCfg(); if not c then return {} end
    local cols = ('`%s` AS plate, `%s` AS props'):format(c.plate, c.props)
    if c.model then cols = cols .. (', `%s` AS model'):format(c.model) end
    if c.stored then cols = cols .. (', `%s` AS stored'):format(c.stored) end
    local ok, rows = pcall(function() return MySQL.query.await(('SELECT %s FROM `%s` WHERE `%s` = ?'):format(cols, c.table, c.owner), { identifier }) end)
    if not ok or not rows then return {} end
    local out = {}
    for _, r in ipairs(rows) do
        local props = type(r.props) == 'string' and (json.decode(r.props) or {}) or {}
        local model = tonumber(r.model) or props.model
        if not model and type(r.model) == 'string' then model = joaat(r.model) end
        local stored, impounded = true, false
        if c.stored then
            stored = tostring(r.stored) == tostring(c.storedValue or 1) or r.stored == true
            if c.impoundValue and tostring(r.stored) == tostring(c.impoundValue) then impounded = true; stored = false end
        end
        out[#out + 1] = { plate = r.plate, model = model, stored = stored, impounded = impounded, fuel = props.fuelLevel or props.fuel, engine = props.engineHealth, body = props.bodyHealth }
    end
    return out
end

function Bridge.OwnsPlate(identifier, plate)
    plate = tostring(plate or ''):gsub('%s+', ''):upper()
    for _, v in ipairs(Bridge.Vehicles(identifier)) do if (v.plate or ''):gsub('%s+', ''):upper() == plate then return true end end
    return false
end

-- ───────────── inventaire ─────────────
function Bridge.ItemCount(src, item)
    if not item or item == '' then return 1 end
    if Config.Hooks.hasItem then return Config.Hooks.hasItem(src, item) or 0 end
    local inv = Bridge.inv
    if inv == 'ox' then return try(function() return exports.ox_inventory:Search(src, 'count', item) end) or 0
    elseif inv == 'qs' then return try(function() return exports['qs-inventory']:GetItemTotalAmount(src, item) end) or 0
    elseif inv == 'esx' then local x = esxPlayer(src); local it = x and x.getInventoryItem(item); return it and it.count or 0
    elseif inv == 'qb' then
        local p = qbPlayer(src)
        local it = p and p.Functions and p.Functions.GetItemByName(item)
        if it then return it.amount or it.count or 1 end
        local n = try(function() return exports['qb-inventory']:GetItemCount(src, item) end)
        return n or 0
    end
    return 1                                           -- 'none' : pas de contrôle
end
function Bridge.HasItem(src, item) return Bridge.ItemCount(src, item) > 0 end

function Bridge.RemoveItem(src, item, count)
    count = count or 1
    local inv = Bridge.inv
    if inv == 'ox' then return try(function() return exports.ox_inventory:RemoveItem(src, item, count) end) and true or false
    elseif inv == 'qs' then return try(function() return exports['qs-inventory']:RemoveItem(src, item, count) end) and true or false
    elseif inv == 'esx' then local x = esxPlayer(src); if x then x.removeInventoryItem(item, count) return true end
    elseif inv == 'qb' then local p = qbPlayer(src); if p then return p.Functions.RemoveItem(item, count) and true or false end end
    return false
end

function Bridge.AddItem(src, item, count)
    count = count or 1
    local inv = Bridge.inv
    if inv == 'ox' then return try(function() return exports.ox_inventory:AddItem(src, item, count) end) and true or false
    elseif inv == 'qs' then return try(function() return exports['qs-inventory']:AddItem(src, item, count) end) and true or false
    elseif inv == 'esx' then local x = esxPlayer(src); if x then x.addInventoryItem(item, count) return true end
    elseif inv == 'qb' then local p = qbPlayer(src); if p then return p.Functions.AddItem(item, count) and true or false end end
    return false
end

-- objet utilisable : ouvre le téléphone (ox_inventory passe par l'événement client, géré dans client/main.lua)
CreateThread(function()
    Bridge.Wait()
    if not Config.UseItem then return end
    local function use(src) TriggerClientEvent('aura:useItem', src) end
    if Bridge.inv == 'esx' and ESX then try(function() ESX.RegisterUsableItem(Config.Item, use) end)
    elseif Bridge.inv == 'qb' and QBCore then try(function() QBCore.Functions.CreateUseableItem(Config.Item, use) end)
    elseif Bridge.inv == 'qs' then try(function() exports['qs-inventory']:CreateUsableItem(Config.Item, use) end) end
end)

-- ───────────── événements ─────────────
function Bridge.OnLoaded(cb)
    if Bridge.fw == 'esx' then AddEventHandler('esx:playerLoaded', function(src) cb(src) end)
    elseif Bridge.fw == 'qb' or Bridge.fw == 'qbox' then
        AddEventHandler('QBCore:Server:PlayerLoaded', function(player) local s = player and (player.PlayerData and player.PlayerData.source or player.source); if s then cb(s) end end)
    else AddEventHandler('playerJoining', function() cb(source) end) end
end

function Bridge.Notify(src, message) TriggerClientEvent('aura:notifyGame', src, message) end

-- ───────────── lignes de métiers issues du framework ─────────────
local TYPE_BY_NAME = { police = 'police', sheriff = 'police', ambulance = 'ems', ems = 'ems', mechanic = 'mecano', mecano = 'mecano', bennys = 'mecano', taxi = 'taxi', realestate = 'realestate', cardealer = 'dealer', dealer = 'dealer', bank = 'bank', government = 'government', bar = 'bar' }
function Bridge.FrameworkLines()
    local C = Config.JobLines
    local lines, only = {}, {}
    for _, n in ipairs(C.only or {}) do only[n] = true end
    local ignore = {}
    for _, n in ipairs(C.ignore or {}) do ignore[n] = true end
    local names = {}
    for name in pairs(Bridge.Jobs()) do names[#names + 1] = name end
    table.sort(names)
    local jobs = Bridge.Jobs()
    for _, name in ipairs(names) do
        if not ignore[name] and (next(only) == nil or only[name]) then
            local o, d = (C.jobs or {})[name] or {}, C.default or {}
            lines[#lines + 1] = {
                job = name, label = o.label or jobs[name].label or name, type = o.type or TYPE_BY_NAME[name] or 'custom',
                number = o.number or d.number or '', icon = o.icon or d.icon or 'briefcase', color = o.color or d.color or '#8b5cf6',
                mode = o.mode or d.mode or 'both', anon = o.anon == nil and (d.anon or false) or o.anon, hint = o.hint or d.hint or '', minGrade = o.minGrade or d.minGrade or 0,
            }
        end
    end
    return lines
end
