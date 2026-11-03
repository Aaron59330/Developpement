local ESX = exports['es_extended']:getSharedObject()
local C = Config
local Data = {}          -- identifiant -> { xp, granted, day = {action = xp}, last = {action = t}, log = {}, mins = n }
local Pending = {}       -- src -> { xp, parts }  (regroupe les notifications)
local IdBySrc = {}

MySQL.ready(function()
    MySQL.query.await('CREATE TABLE IF NOT EXISTS pickax_xp (identifier VARCHAR(60) NOT NULL PRIMARY KEY, xp INT NOT NULL DEFAULT 0, granted INT NOT NULL DEFAULT 1, last_login DATE NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4')
end)

-- ───────────── Niveaux ─────────────
local function xpFor(level) if level <= 1 then return 0 end return math.floor(C.Curve.Base * (level - 1) ^ C.Curve.Exponent) end
local function levelOf(xp)
    local lv = 1
    while lv < C.MaxLevel and xp >= xpFor(lv + 1) do lv = lv + 1 end
    return lv
end
local function idOf(src) local x = ESX.GetPlayerFromId(src) return x and x.identifier end
local function today() return os.date('%Y-%m-%d') end

local function load(src)
    local id = idOf(src)
    if not id then return nil end
    IdBySrc[src] = id
    if Data[id] then return Data[id] end
    local r = MySQL.single.await('SELECT xp, granted, last_login FROM pickax_xp WHERE identifier = ?', { id })
    Data[id] = { xp = r and tonumber(r.xp) or 0, granted = r and tonumber(r.granted) or 1, day = {}, dayKey = today(), last = {}, log = {}, mins = 0, id = id, loginDone = false, lastLogin = r and tostring(r.last_login or '') or '' }
    if not r then MySQL.insert('INSERT INTO pickax_xp (identifier, xp, granted) VALUES (?, 0, 1)', { id }) end
    return Data[id]
end
local function save(d) MySQL.update('UPDATE pickax_xp SET xp = ?, granted = ?, last_login = ? WHERE identifier = ?', { d.xp, d.granted, d.lastLogin ~= '' and d.lastLogin or nil, d.id }) end

local function notify(src, kind, title, txt) TriggerClientEvent('pickax_notify:notify', src, { type = kind, title = title, description = txt }) end

-- ───────────── Récompenses ─────────────
local function rewardText(r)
    if r.type == 'money' then return ('%s $ en liquide'):format(r.amount) end
    if r.type == 'bank' then return ('%s $ en banque'):format(r.amount) end
    if r.type == 'item' then
        local ok, it = pcall(function() return exports.ox_inventory:Items(r.item) end)
        return ('%d × %s'):format(r.count or 1, (ok and it and it.label) or r.item)
    end
    return r.label or ''
end
local function give(src, x, r)
    if r.type == 'money' then x.addAccountMoney(C.Accounts.money, r.amount, 'Récompense de niveau')
    elseif r.type == 'bank' then x.addAccountMoney(C.Accounts.bank, r.amount, 'Récompense de niveau')
    elseif r.type == 'item' then
        if exports.ox_inventory:CanCarryItem(src, r.item, r.count or 1) then exports.ox_inventory:AddItem(src, r.item, r.count or 1)
        else exports.ox_inventory:AddItem(src, r.item, r.count or 1) end   -- ox gère le dépôt au sol si besoin
    end
end
local function grantUpTo(src, d, level)
    local x = ESX.GetPlayerFromId(src)
    if not x then return end
    for lv = d.granted + 1, level do
        local list = C.Rewards[lv]
        if list then
            local txt = {}
            for _, r in ipairs(list) do give(src, x, r) txt[#txt + 1] = rewardText(r) end
            TriggerClientEvent('pickax_xp:levelup', src, lv, txt)
        else
            TriggerClientEvent('pickax_xp:levelup', src, lv, {})
        end
    end
    d.granted = level
end

-- ───────────── Gain d'XP ─────────────
local function amountFor(def, o)
    o = o or {}
    local xp = def.xp or 0
    if o.item and def.items and def.items[o.item] then xp = def.items[o.item] * (tonumber(o.count) or 1)
    elseif def.perDollar and tonumber(o.price) then
        xp = (tonumber(o.price) or 0) * def.perDollar
        if def.min then xp = math.max(xp, def.min) end
        if def.max then xp = math.min(xp, def.max) end
    end
    return math.floor(xp * (tonumber(o.mult) or 1))
end

local function addXP(src, action, o)
    src = tonumber(src)
    local def = C.Actions[action]
    if not src or not def then return 0 end
    local d = load(src)
    if not d then return 0 end
    if d.dayKey ~= today() then d.dayKey = today() d.day = {} end
    local now = os.time()
    if (def.cooldown or 0) > 0 and d.last[action] and now - d.last[action] < def.cooldown then return 0 end
    local xp = amountFor(def, o)
    if xp <= 0 then return 0 end
    if (def.dailyCap or 0) > 0 then
        local used = d.day[action] or 0
        if used >= def.dailyCap then return 0 end
        xp = math.min(xp, def.dailyCap - used)
    end
    d.last[action] = now
    d.day[action] = (d.day[action] or 0) + xp
    local before = levelOf(d.xp)
    d.xp = d.xp + xp
    local after = levelOf(d.xp)
    table.insert(d.log, 1, { label = def.label, xp = xp, t = now })
    if #d.log > 12 then d.log[#d.log] = nil end
    -- notification regroupée
    local p = Pending[src]
    if not p then p = { xp = 0, parts = {} } Pending[src] = p
        SetTimeout(C.Notify.Batch, function()
            local q = Pending[src] Pending[src] = nil
            if q and GetPlayerName(src) then TriggerClientEvent('pickax_xp:gain', src, q.xp, q.parts, d.xp, levelOf(d.xp), xpFor(levelOf(d.xp)), xpFor(math.min(C.MaxLevel, levelOf(d.xp) + 1))) end
        end)
    end
    p.xp = p.xp + xp
    if #p.parts < 3 then p.parts[#p.parts + 1] = def.label end
    if after > before or after > d.granted then grantUpTo(src, d, after) end
    save(d)
    return xp
end

exports('AddXP', addXP)
exports('GetXP', function(src) local d = load(tonumber(src)) return d and d.xp or 0 end)
exports('GetLevel', function(src) local d = load(tonumber(src)) return d and levelOf(d.xp) or 1 end)
AddEventHandler('pickax_xp:add', function(src, action, o) addXP(src, action, o) end)   -- côté serveur : TriggerEvent('pickax_xp:add', src, 'repair')

-- ───────────── Chargement, connexion quotidienne, temps de jeu ─────────────
AddEventHandler('esx:playerLoaded', function(src)
    local d = load(src)
    if not d then return end
    if C.DailyLogin.Enabled and d.lastLogin ~= today() then
        d.lastLogin = today()
        d.loginDone = true
        local gain = C.DailyLogin.XP
        local before = levelOf(d.xp)
        d.xp = d.xp + gain
        local after = levelOf(d.xp)
        if after > before then grantUpTo(src, d, after) end
        save(d)
        SetTimeout(8000, function() if GetPlayerName(src) then notify(src, 'success', 'Connexion du jour', ('+%d XP'):format(gain)) end end)
    end
end)
AddEventHandler('playerDropped', function()
    local src = source
    local id = IdBySrc[src]
    if id and Data[id] then save(Data[id]) Data[id] = nil end
    IdBySrc[src] = nil Pending[src] = nil
end)

CreateThread(function()
    while true do
        Wait(60000)
        if C.Playtime.Enabled then
            for _, s in ipairs(GetPlayers()) do
                local src = tonumber(s)
                local d = Data[idOf(src) or '']
                if d then
                    d.mins = d.mins + 1
                    if d.mins >= C.Playtime.EveryMinutes then
                        d.mins = 0
                        local before = levelOf(d.xp)
                        d.xp = d.xp + C.Playtime.XP
                        local after = levelOf(d.xp)
                        if after > before then grantUpTo(src, d, after) end
                        save(d)
                    end
                end
            end
        end
    end
end)

-- ───────────── Achats dans les magasins ox_inventory ─────────────
CreateThread(function()
    local tries = 0
    while GetResourceState('ox_inventory') ~= 'started' and tries < 60 do Wait(1000) tries = tries + 1 end
    if GetResourceState('ox_inventory') ~= 'started' then return end
    exports.ox_inventory:registerHook('buyItem', function(payload)
        local total = tonumber(payload.totalPrice) or tonumber(payload.price) or 0
        SetTimeout(0, function() addXP(payload.source, 'buy_item', { item = payload.itemName, count = payload.count or 1, price = total }) end)
        return true
    end, {})
end)

-- ───────────── Écran du joueur ─────────────
ESX.RegisterServerCallback('pickax_xp:info', function(src, cb)
    local d = load(src)
    if not d then return cb({ ok = false }) end
    local lv = levelOf(d.xp)
    local rewards, levels = {}, {}
    for lvl, list in pairs(C.Rewards) do levels[#levels + 1] = lvl end
    table.sort(levels)
    for _, lvl in ipairs(levels) do
        local t = {}
        for _, r in ipairs(C.Rewards[lvl]) do t[#t + 1] = { text = rewardText(r), kind = r.type } end
        rewards[#rewards + 1] = { level = lvl, items = t, got = lv >= lvl, need = xpFor(lvl) }
    end
    local actions = {}
    for id, a in pairs(C.Actions) do
        local txt
        if a.items then txt = 'selon l\'objet' elseif a.perDollar then txt = 'selon le prix' else txt = ('+%d XP'):format(a.xp or 0) end
        if (a.xp or 0) > 0 or a.perDollar or a.items then actions[#actions + 1] = { label = a.label, txt = txt, order = a.xp or 99 } end
    end
    table.sort(actions, function(a, b) return a.label < b.label end)
    cb({ ok = true, level = lv, max = C.MaxLevel, xp = d.xp, floor = xpFor(lv), nextXp = lv >= C.MaxLevel and nil or xpFor(lv + 1), rewards = rewards, actions = actions, log = d.log,
         playtime = C.Playtime.Enabled and { every = C.Playtime.EveryMinutes, xp = C.Playtime.XP } or nil, daily = C.DailyLogin.Enabled and C.DailyLogin.XP or nil })
end)

-- Commande admin : /givexp [id] [quantité]
RegisterCommand('givexp', function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, 'command') then return end
    local t, n = tonumber(args[1]), tonumber(args[2])
    if not t or not n then return end
    local d = load(t)
    if not d then return end
    local before = levelOf(d.xp)
    d.xp = math.max(0, d.xp + math.floor(n))
    local after = levelOf(d.xp)
    if after > before then grantUpTo(t, d, after) end
    save(d)
    print(('[pickax_xp] %s : %d XP (niveau %d)'):format(d.id, d.xp, after))
end, false)
