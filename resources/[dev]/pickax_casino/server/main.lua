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
end)

-- ───────────── Postes de jeu : placés et réglés dans le World Builder (module « Casino ») ─────────────
-- Le serveur revérifie à chaque action : poste existant et actif, accès, distance. Le client n'envoie que (eid, pi) et sa mise.
local function spot(src, eid, pi, kind)
    if GetResourceState('pickax_worldbuilder') ~= 'started' then return nil end
    local ok, sp = pcall(function() return exports.pickax_worldbuilder:CasinoSpot(src, eid, pi, Config.InteractDistance + 2.5) end)
    if ok and type(sp) == 'table' and (not kind or sp.kind == kind) then return sp end
end

-- Réglages : valeurs du config.lua, remplacées par celles du casino (World Builder → Jetons & limites)
local function cfgOf(sp)
    local s = sp and sp.settings or {}
    local c = setmetatable({}, { __index = Config })
    if s.currency == 'money' or s.currency == 'bank' then c.Currency = s.currency end
    local map = { chipBuyPrice = 'ChipBuyPrice', chipSellPrice = 'ChipSellPrice', minBuy = 'MinBuy', maxBuy = 'MaxBuy', maxWallet = 'MaxWallet', bigWin = 'BigWin' }
    for k, v in pairs(map) do if tonumber(s[k]) then c[v] = tonumber(s[k]) end end
    return c
end

-- Gammes disponibles (le World Builder les propose pour chaque poste)
local function sortedKeys(t) local o = {} for k in pairs(t) do o[#o + 1] = k end table.sort(o, function(a, b) return (t[a].min or 0) < (t[b].min or 0) end) return o end
exports('Tiers', function() return { slots = sortedKeys(Config.Slots.Machines), blackjack = sortedKeys(Config.Blackjack.Tables), roulette = sortedKeys(Config.Roulette.Tables) } end)

local function say(src, m) TriggerClientEvent('esx:showNotification', src, m) end

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
local function settle(src, id, game, bet, payout, cfg)
    if payout > 0 then credit(id, payout) end
    record(id, game, bet, payout)
    if cfg.BigWin > 0 and payout - bet >= cfg.BigWin then
        say(src, ('~y~Jackpot ! +%d jetons'):format(payout - bet))
        local x = ESX.GetPlayerFromId(src)
        hook(('🎰 **%s** gagne **%d** jetons au %s (mise %d).'):format(x and x.getName() or id, payout, game, bet))
    end
end

-- Un seul coup à la fois par joueur
local busy = {}
local function locked(src) if busy[src] then return true end busy[src] = true return false end
Bj = {}
AddEventHandler('playerDropped', function() busy[source] = nil Bj[source] = nil end)

local function walletRow(id) return MySQL.single.await('SELECT * FROM casino_wallets WHERE identifier = ?', { id }) or {} end

ESX.RegisterServerCallback('pickax_casino:state', function(src, cb, eid, pi)
    local id, x = idOf(src)
    local sp = spot(src, eid, pi)
    if not id or not sp then return cb({ ok = false }) end
    local c = cfgOf(sp)
    local w = walletRow(id)
    cb({ ok = true, name = sp.entityName or Config.Name, chips = tonumber(w.chips) or 0, cash = x.getAccount(c.Currency).money, currency = c.Currency,
        buy = c.ChipBuyPrice, sell = c.ChipSellPrice, minBuy = c.MinBuy, maxBuy = c.MaxBuy,
        stats = { bought = tonumber(w.bought) or 0, sold = tonumber(w.sold) or 0, wagered = tonumber(w.wagered) or 0, won = tonumber(w.won) or 0 } })
end)

ESX.RegisterServerCallback('pickax_casino:buy', function(src, cb, eid, pi, chips)
    local id, x = idOf(src)
    chips = math.floor(tonumber(chips) or 0)
    local sp = spot(src, eid, pi, 'cashier')
    if not id or not sp then return cb({ ok = false, msg = 'Rends-toi à la caisse' }) end
    local c = cfgOf(sp)
    if chips < c.MinBuy or chips > c.MaxBuy then return cb({ ok = false, msg = ('Entre %d et %d jetons'):format(c.MinBuy, c.MaxBuy) }) end
    if locked(src) then return cb({ ok = false, msg = 'Patiente' }) end
    if chipsOf(id) + chips > c.MaxWallet then busy[src] = nil return cb({ ok = false, msg = 'Limite de jetons atteinte' }) end
    local cost = math.ceil(chips * c.ChipBuyPrice)
    if x.getAccount(c.Currency).money < cost then busy[src] = nil return cb({ ok = false, msg = 'Fonds insuffisants' }) end
    x.removeAccountMoney(c.Currency, cost)
    MySQL.query.await('INSERT INTO casino_wallets (identifier, chips, bought) VALUES (?,?,?) ON DUPLICATE KEY UPDATE chips = chips + VALUES(chips), bought = bought + VALUES(bought)', { id, chips, chips })
    busy[src] = nil
    if cost >= 100000 then hook(('💶 %s achète %d jetons (%d $).'):format(x.getName(), chips, cost)) end
    cb({ ok = true, chips = chipsOf(id), cash = x.getAccount(c.Currency).money, msg = ('+%d jetons pour %d $'):format(chips, cost) })
end)

ESX.RegisterServerCallback('pickax_casino:sell', function(src, cb, eid, pi, chips)
    local id, x = idOf(src)
    chips = math.floor(tonumber(chips) or 0)
    local sp = spot(src, eid, pi, 'cashier')
    if not id or not sp then return cb({ ok = false, msg = 'Rends-toi à la caisse' }) end
    local c = cfgOf(sp)
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
ESX.RegisterServerCallback('pickax_casino:slots', function(src, cb, eid, pi, bet)
    local id = idOf(src)
    local sp = spot(src, eid, pi, 'slots')
    local m = sp and Config.Slots.Machines[sp.tier]
    bet = math.floor(tonumber(bet) or 0)
    if not id or not m then return cb({ ok = false, msg = 'Approche-toi d\'une machine' }) end
    if bet < m.min or bet > m.max then return cb({ ok = false, msg = 'Mise hors limites' }) end
    if locked(src) then return cb({ ok = false, msg = 'Patiente' }) end
    if not debit(id, bet) then busy[src] = nil return cb({ ok = false, msg = 'Pas assez de jetons' }) end
    local r = Games.slotsSpin(Config.Slots, bet)
    settle(src, id, 'slots', bet, r.payout, cfgOf(sp))
    busy[src] = nil
    cb({ ok = true, grid = r.grid, wins = r.wins, payout = r.payout, chips = chipsOf(id) })
end)

-- ───────────── Blackjack ─────────────
local function bjReply(src, id, s, cb)
    local B = Bj[src]
    if s.over then
        settle(src, id, 'blackjack', s.bet * (s.doubled and 2 or 1), s.payout, B.cfg)
        B.shoe = s.shoe B.game = nil
    end
    cb({ ok = true, view = Games.bjView(s), chips = chipsOf(id) })
end
ESX.RegisterServerCallback('pickax_casino:bj:deal', function(src, cb, eid, pi, bet)
    local id = idOf(src)
    local sp = spot(src, eid, pi, 'blackjack')
    local t = sp and Config.Blackjack.Tables[sp.tier]
    bet = math.floor(tonumber(bet) or 0)
    if not id or not t then return cb({ ok = false, msg = 'Approche-toi d\'une table' }) end
    if bet < t.min or bet > t.max then return cb({ ok = false, msg = 'Mise hors limites' }) end
    if locked(src) then return cb({ ok = false, msg = 'Patiente' }) end
    Bj[src] = Bj[src] or {}
    if not debit(id, bet) then busy[src] = nil return cb({ ok = false, msg = 'Pas assez de jetons' }) end
    -- une partie abandonnée (joueur parti en cours de main) est perdue : la mise est déjà débitée
    local sh = Bj[src].shoe
    if Bj[src].game then sh = Bj[src].game.shoe end
    if sh and #sh < 30 then sh = nil end
    local s = Games.bjNew(bet, { decks = Config.Blackjack.Decks, bjPay = Config.Blackjack.BlackjackPays, hitSoft17 = Config.Blackjack.DealerHitsSoft17 }, sh)
    Bj[src].game, Bj[src].cfg = s, cfgOf(sp)
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
ESX.RegisterServerCallback('pickax_casino:roulette', function(src, cb, eid, pi, bets)
    local id = idOf(src)
    local sp = spot(src, eid, pi, 'roulette')
    local t = sp and Config.Roulette.Tables[sp.tier]
    if not id or not t then return cb({ ok = false, msg = 'Approche-toi d\'une table' }) end
    local clean = {}
    for i, b in ipairs(type(bets) == 'table' and bets or {}) do if type(b) == 'table' then clean[i] = { t = b.t, n = tonumber(b.n), a = tonumber(b.a) } end end
    local total, err = Games.rouletteCheck(clean, t.min, t.max, t.total)
    if not total then return cb({ ok = false, msg = err }) end
    if locked(src) then return cb({ ok = false, msg = 'Patiente' }) end
    if not debit(id, total) then busy[src] = nil return cb({ ok = false, msg = 'Pas assez de jetons' }) end
    local r = Games.rouletteSpin(clean)
    settle(src, id, 'roulette', total, r.payout, cfgOf(sp))
    busy[src] = nil
    cb({ ok = true, number = r.number, color = r.color, payout = r.payout, bet = total, wins = r.wins, chips = chipsOf(id) })
end)

-- ───────────── Commandes staff (console ou groupe autorisé) ─────────────
local function staff(name, fn)
    RegisterCommand(name, function(src, args)
        local x = src ~= 0 and ESX.GetPlayerFromId(src)
        if src == 0 or (x and Config.AdminGroups[x.getGroup()]) then fn(src, args) end
    end, false)
end
staff('casinortp', function(src)
    local rtp, hit = Games.slotsRTP(Config.Slots)
    local msg = ('[casino] Machines à sous : retour théorique %.2f %%, un tour sur %.1f gagne'):format(rtp * 100, 1 / hit)
    if src == 0 then print(msg) else say(src, msg) end
end)
staff('casinostats', function(src)
    local r = MySQL.single.await('SELECT COUNT(*) n, COALESCE(SUM(bet),0) b, COALESCE(SUM(payout),0) p FROM casino_history') or {}
    local msg = ('[casino] %d parties, %d jetons misés, %d rendus : bénéfice de la maison %d jetons'):format(r.n or 0, r.b or 0, r.p or 0, (r.b or 0) - (r.p or 0))
    if src == 0 then print(msg) else say(src, msg) end
end)
