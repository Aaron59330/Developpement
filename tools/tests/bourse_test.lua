-- Bourse : marche aléatoire bornée, achats / ventes, frais, limites, plus-values (natives et base simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local now = 1700000000
os.time = function() return now end
local cbs, threads, notes = {}, {}, {}
function CreateThread(f) threads[#threads + 1] = f end
function Wait() coroutine.yield() end
function AddEventHandler() end
function TriggerClientEvent(ev, src, d) notes[#notes + 1] = d end
function GetPlayerPed(s) return s end
lib = { callback = { register = function(n, f) cbs[n] = f end } }
exports = setmetatable({ es_extended = { getSharedObject = function() return ESX end }, pickax_core = { AddSharedMoney = function() return true end } }, { __call = function() end })
local hold = {}
MySQL = { ready = function(f) f() end,
    query = { await = function(sql, p)
        if sql:find('FROM pickax_bourse_holdings WHERE symbol') then local l = {} for k, h in pairs(hold) do if h.symbol == p[1] then l[#l + 1] = { identifier = h.identifier, shares = h.shares } end end return l end
        if sql:find('FROM pickax_bourse_holdings WHERE identifier') then local l = {} for _, h in pairs(hold) do if h.identifier == p[1] then l[#l + 1] = { symbol = h.symbol, shares = h.shares, avg_cost = h.avg } end end return l end
        return {} end },
    single = { await = function(sql, p) local h = hold[p[1] .. p[2]] return h and { shares = h.shares, avg_cost = h.avg } or nil end },
    update = setmetatable({ await = function(sql, p)
        if sql:find('REPLACE INTO pickax_bourse_holdings') then hold[p[1] .. p[2]] = { identifier = p[1], symbol = p[2], shares = p[3], avg = p[4] } end
        if sql:find('DELETE FROM pickax_bourse_holdings') then hold[p[1] .. p[2]] = nil end
        if sql:find('UPDATE pickax_bourse_holdings SET shares') then local h = hold[p[2] .. p[3]] h.shares = p[1] end
        return 1 end }, { __call = function() end }) }
local bank = { id1 = 100000, id2 = 50 }
local function mk(id, ident) return { source = id, identifier = ident, getAccount = function() return { money = bank[ident] } end, removeAccountMoney = function(_, v) bank[ident] = bank[ident] - v end, addAccountMoney = function(_, v) bank[ident] = bank[ident] + v end } end
local players = { [1] = mk(1, 'id1'), [2] = mk(2, 'id2') }
ESX = { GetPlayerFromId = function(s) return players[s] end, GetPlayerFromIdentifier = function(i) for _, p in pairs(players) do if p.identifier == i then return p end end end }
Config = {} dofile(ROOT .. '/resources/[dev]/pickax_bourse/config.lua')
Config.Fee = 1.0 Config.Cooldown = 0 Config.News = { Enabled = false } Config.MaxPositionPerStock = 100
dofile(ROOT .. '/resources/[dev]/pickax_bourse/server/main.lua')
local B = BRS
local function order(src, side, sym, q) return cbs['pickax_bourse:order'](src, side, sym, q) end

-- fonctions pures
ok(B.nextPrice(100, 100, 5, 0, 0.5) == 100.0 and B.nextPrice(100, 100, 5, 0, 1) == 105.0 and B.nextPrice(100, 100, 5, 0, 0) == 95.0, 'variation : ±volatilité autour du prix')
ok(B.nextPrice(100, 100, 5, 1, 0.5) == 101.0, 'tendance (drift) ajoutée')
ok(B.nextPrice(11, 100, 50, 0, 0) == 10.0 and B.nextPrice(990, 100, 50, 0, 1) == 1000.0, 'prix borné entre 10 % et 1000 % du prix de départ')
ok(B.buyCost(100, 10, 1) == 1010 and B.sellGain(100, 10, 1) == 990 and B.buyCost(33.33, 3, 1) == 101, 'frais à l\'achat et à la vente')
ok(math.abs(B.avgCost(10, 100, 10, 120) - 110) < 1e-9, 'prix moyen d\'achat')
-- marché
local m = cbs['pickax_bourse:market'](1)
ok(m.ok and #m.stocks == 5 and m.cash == 100000 and m.stocks[1].shares == 0, 'cours et portefeuille')
-- ordres
ok(order(1, 'buy', 'INCONNU', 5).error == 'Ordre invalide' and order(1, 'buy', 'AERO', 0).error == 'Ordre invalide' and order(1, 'x', 'AERO', 1).error == 'Ordre invalide', 'ordres invalides refusés')
ok(order(2, 'buy', 'AERO', 5).error:find('Il te faut'), 'fonds insuffisants')
local r = order(1, 'buy', 'AERO', 10)
ok(r.ok and r.price == 120.0 and r.total == 1212 and bank.id1 == 100000 - 1212 and hold.id1AERO.shares == 10, 'achat au prix courant frais compris')
ok(order(1, 'buy', 'AERO', 95).error:find('Maximum 100'), 'position maximale par titre')
r = order(1, 'sell', 'AERO', 4)
ok(r.ok and r.total == 475 and r.profit == 475 - 480 and hold.id1AERO.shares == 6, 'vente partielle : frais déduits, plus-value (ici négative à cause des frais)')
ok(order(1, 'sell', 'AERO', 50).error:find('pas assez'), 'vente de plus que détenu refusée')
r = order(1, 'sell', 'AERO', 6)
ok(r.ok and hold.id1AERO == nil, 'vente totale : position supprimée')
-- le prix bouge côté serveur
local co = coroutine.create(threads[#threads]) coroutine.resume(co) coroutine.resume(co) coroutine.resume(co)
local m2 = cbs['pickax_bourse:market'](1)
ok(m2.stocks[1].price ~= 120.0 or m2.stocks[2].price ~= 85.0, 'les prix évoluent à chaque mouvement')
for _, s in ipairs(m2.stocks) do ok(s.price >= 1 and s.price <= 5000, 'prix dans les bornes : ' .. s.id) end
-- limite de lieu : l'ordre n'est possible qu'à la bourse
local VM = {} VM.__index = VM
VM.__sub = function(a, b) return setmetatable({ x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }, VM) end
VM.__len = function(a) return math.sqrt(a.x ^ 2 + a.y ^ 2 + a.z ^ 2) end
local where = setmetatable({ x = 500.0, y = 0.0, z = 0.0 }, VM)
function GetEntityCoords() return where end
Config.Spots = { { label = 'Bourse', coords = setmetatable({ x = 0.0, y = 0.0, z = 0.0 }, VM), radius = 3.0 } }
ok(order(1, 'buy', 'AERO', 1).error == 'Rends-toi à la bourse.', 'loin de la bourse : ordre refusé')
where = setmetatable({ x = 1.0, y = 0.0, z = 0.0 }, VM)
ok(order(1, 'buy', 'AERO', 1).ok, 'à la bourse : ordre accepté')
print(('bourse_test : %d vérifications OK'):format(checks))
