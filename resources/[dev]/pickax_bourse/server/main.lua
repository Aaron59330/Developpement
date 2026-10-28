-- ─────────────────────────────── Bourse ───────────────────────────────
-- Les prix évoluent côté serveur uniquement (marche aléatoire avec tendance, + actualités). Les ordres s'exécutent au prix courant : le client ne décide jamais d'un prix.

ESX = exports['es_extended']:getSharedObject()
local Br = {}                  -- fonctions pures (testées)
BRS = Br
local prices, history, lastOrder = {}, {}, {}
local stocks = {}
for _, s in ipairs(Config.Stocks) do stocks[s.id] = s end

local function now() return os.time() end
local function fail(m) return { ok = false, error = m } end

-- Prochain prix : variation aléatoire (±vol %) + tendance, bornée à [10 % du prix de départ ; 10 × le prix de départ]
function Br.nextPrice(price, start, vol, drift, r)   -- r ∈ [0, 1)
    local change = (r * 2 - 1) * vol + (drift or 0)
    local p = price * (1 + change / 100)
    local lo, hi = start * 0.10, start * 10
    p = math.max(lo, math.min(hi, p))
    return math.floor(p * 100 + 0.5) / 100
end

-- Coût d'un achat, produit d'une vente (frais compris), arrondis à l'entier
function Br.buyCost(price, qty, feePct) return math.ceil(price * qty * (1 + feePct / 100)) end
function Br.sellGain(price, qty, feePct) return math.floor(price * qty * (1 - feePct / 100)) end

-- Prix moyen d'achat après un nouvel achat
function Br.avgCost(shares, avg, qty, price) return (shares * avg + qty * price) / (shares + qty) end

MySQL.ready(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS pickax_bourse_prices (symbol VARCHAR(10) PRIMARY KEY, price DOUBLE NOT NULL, updated INT NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS pickax_bourse_holdings (identifier VARCHAR(80) NOT NULL, symbol VARCHAR(10) NOT NULL, shares INT NOT NULL, avg_cost DOUBLE NOT NULL,
        PRIMARY KEY (identifier, symbol)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    for _, r in ipairs(MySQL.query.await('SELECT symbol, price FROM pickax_bourse_prices') or {}) do if stocks[r.symbol] then prices[r.symbol] = r.price end end
    for id, s in pairs(stocks) do prices[id] = prices[id] or s.price history[id] = { prices[id] } end
end)

local function pushHistory(id, p)
    local h = history[id] or {}
    h[#h + 1] = p
    while #h > (Config.HistoryPoints or 24) do table.remove(h, 1) end
    history[id] = h
end

local function holders(symbol)
    return MySQL.query.await('SELECT identifier, shares FROM pickax_bourse_holdings WHERE symbol = ?', { symbol }) or {}
end

local function tick()
    for id, s in pairs(stocks) do
        local p = Br.nextPrice(prices[id] or s.price, s.price, s.vol, s.drift, math.random())
        prices[id] = p
        pushHistory(id, p)
        MySQL.update('REPLACE INTO pickax_bourse_prices (symbol, price, updated) VALUES (?, ?, ?)', { id, p, now() })
    end
    local N = Config.News or {}
    if N.Enabled and math.random(100) <= (N.ChancePerTick or 0) then
        local list = {}
        for id in pairs(stocks) do list[#list + 1] = id end
        table.sort(list)
        local id = list[math.random(#list)]
        local swing = (N.SwingMin or 4) + math.random() * ((N.SwingMax or 12) - (N.SwingMin or 4))
        local up = math.random(2) == 1
        local s = stocks[id]
        prices[id] = Br.nextPrice(prices[id], s.price, 0, up and swing or -swing, 0.5)
        pushHistory(id, prices[id])
        MySQL.update('REPLACE INTO pickax_bourse_prices (symbol, price, updated) VALUES (?, ?, ?)', { id, prices[id], now() })
        for _, h in ipairs(holders(id)) do
            local x = ESX.GetPlayerFromIdentifier(h.identifier)
            if x then TriggerClientEvent('ox_lib:notify', x.source, { title = 'Bourse', description = ('%s %s de %.1f %% : %s'):format(s.label, up and 'bondit' or 'chute', swing, up and 'bonne nouvelle !' or 'mauvaise nouvelle…'), type = up and 'success' or 'error' }) end
        end
    end
end

CreateThread(function()
    Wait(5000)
    while true do
        Wait(math.max(1, Config.TickMinutes or 10) * 60000)
        pcall(tick)
    end
end)

-- ─── lecture : cours + portefeuille du joueur ───
lib.callback.register('pickax_bourse:market', function(src)
    local x = ESX.GetPlayerFromId(src)
    if not x then return fail('Joueur introuvable') end
    local mine = {}
    for _, r in ipairs(MySQL.query.await('SELECT symbol, shares, avg_cost FROM pickax_bourse_holdings WHERE identifier = ?', { x.identifier }) or {}) do mine[r.symbol] = r end
    local list = {}
    for _, s in ipairs(Config.Stocks) do
        local h = history[s.id] or {}
        local first = h[1] or prices[s.id]
        local p = prices[s.id] or s.price
        local m = mine[s.id]
        list[#list + 1] = { id = s.id, label = s.label, sector = s.sector, price = p, change = first and first > 0 and math.floor((p / first - 1) * 1000) / 10 or 0,
            trend = h, shares = m and m.shares or 0, avg = m and m.avg_cost or 0 }
    end
    local acc = x.getAccount(Config.Account or 'bank')
    return { ok = true, stocks = list, cash = acc and acc.money or 0, fee = Config.Fee or 0, max = Config.MaxPositionPerStock }
end)

local function nearSpot(src)
    if not Config.Spots or #Config.Spots == 0 then return true end
    local p = GetEntityCoords(GetPlayerPed(src))
    for _, s in ipairs(Config.Spots) do if #(p - s.coords) <= (s.radius or 3.0) + 2.0 then return true end end
    return false
end

-- ─── ordres ───
lib.callback.register('pickax_bourse:order', function(src, side, symbol, qty)
    local x = ESX.GetPlayerFromId(src)
    if not x then return fail('Joueur introuvable') end
    local t = now()
    if (lastOrder[src] or 0) + (Config.Cooldown or 2) > t then return fail('Doucement…') end
    lastOrder[src] = t
    if not nearSpot(src) then return fail('Rends-toi à la bourse.') end
    local s = stocks[tostring(symbol)]
    qty = math.floor(tonumber(qty) or 0)
    if not s or qty < 1 or qty > 100000 then return fail('Ordre invalide') end
    local price = prices[s.id] or s.price
    local fee, acct = Config.Fee or 0, Config.Account or 'bank'
    local row = MySQL.single.await('SELECT shares, avg_cost FROM pickax_bourse_holdings WHERE identifier = ? AND symbol = ?', { x.identifier, s.id })
    local have = row and row.shares or 0
    if side == 'buy' then
        if have + qty > (Config.MaxPositionPerStock or 5000) then return fail(('Maximum %d actions de ce titre.'):format(Config.MaxPositionPerStock or 5000)) end
        local cost = Br.buyCost(price, qty, fee)
        local acc = x.getAccount(acct)
        if not acc or acc.money < cost then return fail(('Il te faut %d $ (frais compris).'):format(cost)) end
        x.removeAccountMoney(acct, cost, 'Bourse : achat ' .. s.id)
        local avg = have > 0 and Br.avgCost(have, row.avg_cost, qty, price) or price
        MySQL.update.await('REPLACE INTO pickax_bourse_holdings (identifier, symbol, shares, avg_cost) VALUES (?, ?, ?, ?)', { x.identifier, s.id, have + qty, avg })
        if (Config.FeeSociety or '') ~= '' then pcall(function() exports.pickax_core:AddSharedMoney(Config.FeeSociety, cost - math.floor(price * qty)) end) end
        return { ok = true, side = 'buy', qty = qty, price = price, total = cost }
    elseif side == 'sell' then
        if have < qty then return fail('Tu n\'as pas assez d\'actions.') end
        local gain = Br.sellGain(price, qty, fee)
        if have == qty then MySQL.update.await('DELETE FROM pickax_bourse_holdings WHERE identifier = ? AND symbol = ?', { x.identifier, s.id })
        else MySQL.update.await('UPDATE pickax_bourse_holdings SET shares = ? WHERE identifier = ? AND symbol = ?', { have - qty, x.identifier, s.id }) end
        x.addAccountMoney(acct, gain, 'Bourse : vente ' .. s.id)
        local profit = gain - math.floor((row.avg_cost or price) * qty)
        return { ok = true, side = 'sell', qty = qty, price = price, total = gain, profit = profit }
    end
    return fail('Ordre invalide')
end)

AddEventHandler('playerDropped', function() lastOrder[source] = nil end)
exports('GetPrice', function(symbol) return prices[symbol] end)
