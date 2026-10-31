local ESX = exports['es_extended']:getSharedObject()

-- ───────────── Base de données ─────────────
MySQL.ready(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS casino_wallets (
        identifier VARCHAR(80) NOT NULL PRIMARY KEY, chips BIGINT NOT NULL DEFAULT 0,
        bought BIGINT NOT NULL DEFAULT 0, sold BIGINT NOT NULL DEFAULT 0,
        wagered BIGINT NOT NULL DEFAULT 0, won BIGINT NOT NULL DEFAULT 0) ]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS casino_history (
        id INT AUTO_INCREMENT PRIMARY KEY, identifier VARCHAR(80), game VARCHAR(20), bet BIGINT, payout BIGINT,
        at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, KEY(identifier)) ]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS casino_spots (
        id INT AUTO_INCREMENT PRIMARY KEY, kind VARCHAR(20), tier VARCHAR(20), x DOUBLE, y DOUBLE, z DOUBLE, h DOUBLE) ]])
    LoadSpots()
end)

-- ───────────── Réglages (config.lua + panneau : cache_casino.json si présent) ─────────────
local function cfg()
    local c = Config
    local raw = GetResourceState('pickax_panel') == 'started' and LoadResourceFile('pickax_panel', 'cache_casino.json')
    local ok, doc = pcall(json.decode, raw or 'null')
    if ok and type(doc) == 'table' then
        c = setmetatable({}, { __index = Config })
        for _, k in ipairs({ 'ChipBuyPrice', 'ChipSellPrice', 'MinBuy', 'MaxBuy', 'MaxWallet', 'BigWin' }) do
            if tonumber(doc[k]) then c[k] = tonumber(doc[k]) end
        end
        if doc.Currency == 'money' or doc.Currency == 'bank' then c.Currency = doc.Currency end
    end
    return c
end

-- ───────────── Postes de jeu ─────────────
Spots = {}
function LoadSpots()
    Spots = MySQL.query.await('SELECT * FROM casino_spots') or {}
    TriggerClientEvent('pickax_casino:spots', -1, Spots)
end
RegisterNetEvent('pickax_casino:want', function() TriggerClientEvent('pickax_casino:spots', source, Spots) end)

local KINDS = { cashier = true, slots = 'Slots', blackjack = 'Blackjack', roulette = 'Roulette' }
local function tierOk(kind, tier)
    if kind == 'cashier' then return true end
    local t = (kind == 'slots' and Config.Slots.Machines) or (kind == 'blackjack' and Config.Blackjack.Tables) or Config.Roulette.Tables
    return t[tier] ~= nil
end
local function isAdmin(src) local x = ESX.GetPlayerFromId(src) return x and Config.AdminGroups[x.getGroup()] == true end
local function say(src, m) TriggerClientEvent('esx:showNotification', src, m) end

RegisterNetEvent('pickax_casino:addSpot', function(kind, tier, x, y, z, h)
    local src = source
    if not isAdmin(src) then return end
    if not KINDS[kind] or not tierOk(kind, tier) then return say(src, '~r~Type ou gamme inconnu') end
    MySQL.insert.await('INSERT INTO casino_spots (kind,tier,x,y,z,h) VALUES (?,?,?,?,?,?)', { kind, tier or '', x, y, z, h })
    LoadSpots() say(src, ('~g~Poste « %s » ajouté'):format(kind))
end)
RegisterNetEvent('pickax_casino:delSpot', function(id)
    if not isAdmin(source) then return end
    MySQL.query.await('DELETE FROM casino_spots WHERE id = ?', { tonumber(id) })
    LoadSpots() say(source, '~g~Poste supprimé')
end)

-- ───────────── Portefeuille de jetons ─────────────
local function idOf(src) local x = ESX.GetPlayerFromId(src) return x and x.identifier, x end
local function chipsOf(id)
    local r = MySQL.single.await('SELECT chips FROM casino_wallets WHERE identifier = ?', { id })
    return r and tonumber(r.chips) or 0
end
-- débit atomique : refuse si le solde est insuffisant
local function debit(id, n) local r = MySQL.update.await('UPDATE casino_wallets SET chips = chips - ?, wagered = wagered + ? WHERE identifier = ? AND chips >= ?', { n, n, id, n }) return r and r > 0 end
local function credit(id, n) MySQL.query.await('INSERT INTO casino_wallets (identifier, chips, won) VALUES (?,?,?) ON DUPLICATE KEY UPDATE chips = chips + VALUES(chips), won = won + VALUES(won)', { id, n, n }) end
local function record(id, game, bet, payout) MySQL.insert('INSERT INTO casino_history (identifier,game,bet,payout) VALUES (?,?,?,?)', { id, game, bet, payout }) end

local function hook(text)
    if not Config.Webhook or Config.Webhook == '' then return end
    PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode({ username = Config.Name, content = text }), { ['Content-Type'] = 'application/json' })
end
local function settle(src, id, game, bet, payout)
    if payout > 0 then credit(id, payout) end
    record(id, game, bet, payout)
    if payout - bet >= cfg().BigWin then
        say(src, ('~y~Jackpot ! +%d jetons'):format(payout - bet))
        local x = ESX.GetPlayerFromId(src)
        hook(('🎰 **%s** gagne **%d** jetons au %s (mise %d).'):format(x and x.getName() or id, payout, game, bet))
    end
end

-- Un seul coup à la fois par joueur + le joueur doit être près d'un poste du bon type
local busy = {}
local function locked(src) if busy[src] then return true end busy[src] = true return false end
local function near(src, kind)
    local p = GetEntityCoords(GetPlayerPed(src))
    for _, s in ipairs(Spots) do
        if s.kind == kind and #(p - vector3(s.x, s.y, s.z)) <= Config.InteractDistance + 2.5 then return s end
    end
end
AddEventHandler('playerDropped', function() busy[source] = nil Bj[source] = nil end)
Bj = {}

ESX.RegisterServerCallback('pickax_casino:state', function(src, cb)
    local id = idOf(src)
    if not id then return cb({ ok = false }) end
    local c = cfg()
    local w = MySQL.single.await('SELECT * FROM casino_wallets WHERE identifier = ?', { id }) or {}
    local x = ESX.GetPlayerFromId(src)
    cb({ ok = true, name = Config.Name, chips = tonumber(w.chips) or 0, cash = x.getAccount(c.Currency).money, currency = c.Currency,
        buy = c.ChipBuyPrice, sell = c.ChipSellPrice, minBuy = c.MinBuy, maxBuy = c.MaxBuy,
        stats = { bought = tonumber(w.bought) or 0, sold = tonumber(w.sold) or 0, wagered = tonumber(w.wagered) or 0, won = tonumber(w.won) or 0 } })
end)

ESX.RegisterServerCallback('pickax_casino:buy', function(src, cb, chips)
    local id, x = idOf(src)
    chips = math.floor(tonumber(chips) or 0)
    local c = cfg()
    if not id or not near(src, 'cashier') then return cb({ ok = false, msg = 'Rends-toi à la caisse' }) end
    if chips < c.MinBuy or chips > c.MaxBuy then return cb({ ok = false, msg = ('Entre %d et %d jetons'):format(c.MinBuy, c.MaxBuy) }) end
    if locked(src) then return cb({ ok = false, msg = 'Patiente' }) end
    local have = chipsOf(id)
    if have + chips > c.MaxWallet then busy[src] = nil return cb({ ok = false, msg = 'Limite de jetons atteinte' }) end
    local cost = math.ceil(chips * c.ChipBuyPrice)
    if x.getAccount(c.Currency).money < cost then busy[src] = nil return cb({ ok = false, msg = 'Fonds insuffisants' }) end
    x.removeAccountMoney(c.Currency, cost)
    MySQL.query.await('INSERT INTO casino_wallets (identifier, chips, bought) VALUES (?,?,?) ON DUPLICATE KEY UPDATE chips = chips + VALUES(chips), bought = bought + VALUES(bought)', { id, chips, chips })
    busy[src] = nil
    if cost >= 100000 then hook(('💶 %s achète %d jetons (%d $).'):format(x.getName(), chips, cost)) end
    cb({ ok = true, chips = chipsOf(id), cash = x.getAccount(c.Currency).money, msg = ('+%d jetons pour %d $'):format(chips, cost) })
end)

ESX.RegisterServerCallback('pickax_casino:sell', function(src, cb, chips)
    local id, x = idOf(src)
    chips = math.floor(tonumber(chips) or 0)
    local c = cfg()
    if not id or not near(src, 'cashier') then return cb({ ok = false, msg = 'Rends-toi à la caisse' }) end
    if chips < 1 then return cb({ ok = false, msg = 'Montant invalide' }) end
    if locked(src) then return cb({ ok = false, msg = 'Patiente' }) end
    local r = MySQL.update.await('UPDATE casino_wallets SET chips = chips - ?, sold = sold + ? WHERE identifier = ? AND chips >= ?', { chips, chips, id, chips })
    if not r or r == 0 then busy[src] = nil return cb({ ok = false, msg = 'Pas assez de jetons' }) end
    local pay = math.floor(chips * c.ChipSellPrice)
    x.addAccountMoney(c.Currency, pay)
    busy[src] = nil
    cb({ ok = true, chips = chipsOf(id), cash = x.getAccount(c.Currency).money, msg = ('%d jetons rachetés : +%d $'):format(chips, pay) })
end)

-- ───────────── Machines à sous ─────────────
ESX.RegisterServerCallback('pickax_casino:slots', function(src, cb, tier, bet)
    local id = idOf(src)
    local m = Config.Slots.Machines[tier]
    bet = math.floor(tonumber(bet) or 0)
    local spot = near(src, 'slots')
    if not id or not m or not spot then return cb({ ok = false, msg = 'Approche-toi d\'une machine' }) end
    if bet < m.min or bet > m.max then return cb({ ok = false, msg = 'Mise hors limites' }) end
    if locked(src) then return cb({ ok = false, msg = 'Patiente' }) end
    if not debit(id, bet) then busy[src] = nil return cb({ ok = false, msg = 'Pas assez de jetons' }) end
    local r = Games.slotsSpin(Config.Slots, bet)
    settle(src, id, 'slots', bet, r.payout)
    busy[src] = nil
    cb({ ok = true, grid = r.grid, wins = r.wins, payout = r.payout, chips = chipsOf(id) })
end)

-- ───────────── Blackjack ─────────────
local function bjReply(src, id, s, cb)
    if s.over then
        settle(src, id, 'blackjack', s.bet * (s.doubled and 2 or 1), s.payout)
        Bj[src].shoe = s.shoe Bj[src].game = nil
    end
    cb({ ok = true, view = Games.bjView(s), chips = chipsOf(id) })
end
ESX.RegisterServerCallback('pickax_casino:bj:deal', function(src, cb, tier, bet)
    local id = idOf(src)
    local t = Config.Blackjack.Tables[tier]
    bet = math.floor(tonumber(bet) or 0)
    if not id or not t or not near(src, 'blackjack') then return cb({ ok = false, msg = 'Approche-toi d\'une table' }) end
    if bet < t.min or bet > t.max then return cb({ ok = false, msg = 'Mise hors limites' }) end
    if locked(src) then return cb({ ok = false, msg = 'Patiente' }) end
    Bj[src] = Bj[src] or {}
    if Bj[src].game then busy[src] = nil return cb({ ok = false, msg = 'Une partie est déjà en cours' }) end
    if not debit(id, bet) then busy[src] = nil return cb({ ok = false, msg = 'Pas assez de jetons' }) end
    local sh = Bj[src].shoe
    if sh and #sh < 30 then sh = nil end
    local s = Games.bjNew(bet, { decks = Config.Blackjack.Decks, bjPay = Config.Blackjack.BlackjackPays, hitSoft17 = Config.Blackjack.DealerHitsSoft17 }, sh)
    Bj[src].game = s
    bjReply(src, id, s, cb)
    busy[src] = nil
end)
ESX.RegisterServerCallback('pickax_casino:bj:act', function(src, cb, act)
    local id = idOf(src)
    local s = Bj[src] and Bj[src].game
    if not id or not s then return cb({ ok = false, msg = 'Aucune partie en cours' }) end
    if locked(src) then return cb({ ok = false, msg = 'Patiente' }) end
    if act == 'hit' then Games.bjHit(s)
    elseif act == 'stand' then Games.bjStand(s)
    elseif act == 'double' then
        if not s.over and #s.player == 2 and not s.doubled then
            if not debit(id, s.bet) then busy[src] = nil return cb({ ok = false, msg = 'Pas assez de jetons pour doubler' }) end
            Games.bjDouble(s)
        end
    end
    bjReply(src, id, s, cb)
    busy[src] = nil
end)

-- ───────────── Roulette ─────────────
ESX.RegisterServerCallback('pickax_casino:roulette', function(src, cb, tier, bets)
    local id = idOf(src)
    local t = Config.Roulette.Tables[tier]
    if not id or not t or not near(src, 'roulette') then return cb({ ok = false, msg = 'Approche-toi d\'une table' }) end
    local clean = {}
    for i, b in ipairs(type(bets) == 'table' and bets or {}) do if type(b) == 'table' then clean[i] = { t = b.t, n = tonumber(b.n), a = tonumber(b.a) } end end
    local total, err = Games.rouletteCheck(clean, t.min, t.max, t.total)
    if not total then return cb({ ok = false, msg = err }) end
    if locked(src) then return cb({ ok = false, msg = 'Patiente' }) end
    if not debit(id, total) then busy[src] = nil return cb({ ok = false, msg = 'Pas assez de jetons' }) end
    local r = Games.rouletteSpin(clean)
    settle(src, id, 'roulette', total, r.payout)
    busy[src] = nil
    cb({ ok = true, number = r.number, color = r.color, payout = r.payout, bet = total, wins = r.wins, chips = chipsOf(id) })
end)

-- ───────────── Commandes staff ─────────────
local function staff(name, fn) RegisterCommand(name, function(src, args) if src == 0 or isAdmin(src) then fn(src, args) end end, false) end
staff('casinoadd', function(src, args)          -- /casinoadd cashier | slots <bronze|silver|gold> | blackjack <classic|vip> | roulette <classic|vip>
    if src == 0 then return end
    local kind, tier = args[1], args[2]
    if kind == 'cashier' then tier = '' end
    TriggerClientEvent('pickax_casino:addHere', src, kind, tier)
end)
staff('casinolist', function(src)
    for _, s in ipairs(Spots) do print(('[casino] #%d %s %s  %.1f %.1f %.1f'):format(s.id, s.kind, s.tier, s.x, s.y, s.z)) end
    if src ~= 0 then say(src, ('%d postes (voir la console)'):format(#Spots)) end
end)
staff('casinodel', function(src, args)
    local id = tonumber(args[1]) if not id then return end
    MySQL.query.await('DELETE FROM casino_spots WHERE id = ?', { id }) LoadSpots()
end)
staff('casinortp', function()
    local rtp, hit = Games.slotsRTP(Config.Slots)
    print(('[casino] Machines à sous : retour théorique %.2f %%, un tour sur %.1f gagne'):format(rtp * 100, 1 / hit))
end)
staff('casinostats', function(src)
    local r = MySQL.single.await('SELECT COUNT(*) n, COALESCE(SUM(bet),0) b, COALESCE(SUM(payout),0) p FROM casino_history') or {}
    local msg = ('[casino] %d parties, %d jetons misés, %d rendus : bénéfice de la maison %d jetons'):format(r.n or 0, r.b or 0, r.p or 0, (r.b or 0) - (r.p or 0))
    if src == 0 then print(msg) else say(src, msg:gsub('%[casino%] ', '')) end
end)
