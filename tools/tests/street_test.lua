-- Vente de rue aux PNJ : conditions, acceptation, quantité, prix, limites (natives simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local cbs, inv, paid, alerts, timer = {}, {}, {}, {}, 1000000
local xp = { identifier = 'id1', source = 1 }
function GetGameTimer() return timer end
function GetPlayerPed() return 5 end
function GetVehiclePedIsIn() return 0 end
function GetEntityCoords() return { x = 1.0, y = 2.0, z = 3.0 } end
function GetResourceState() return 'missing' end
function AddEventHandler() end
ESX = { RegisterServerCallback = function(n, f) cbs[n] = f end, GetPlayerFromId = function() return xp end }
IB = { itemCount = function(_, n) return inv[n] or 0 end, removeItem = function(_, n, c) if (inv[n] or 0) < c then return false end inv[n] = inv[n] - c return true end,
    copCount = function() return 0 end, alertPolice = function(c, t) alerts[#alerts + 1] = t end, log = function() end, Counters = {},
    pay = function(_, acc, amount) paid[#paid + 1] = { acc, amount } end }
function IB.counter(key, w) local c = IB.Counters[key] if not c then c = { n = 0, since = 0 } IB.Counters[key] = c end return c end
Config = { PedSales = { Enabled = true }, DrugOrder = { 'weed' }, Drugs = { weed = { label = 'Cannabis', pooch = 'weed_pooch', price = { pooch = { 100, 200 } } } },
    StreetSales = { Enabled = true, RequireTablet = true, TabletItem = 'dealer_tablet', AcceptChance = 100, QtyMin = 1, QtyMax = 3, PriceFactor = 0.8, Account = 'black_money', Cooldown = 8, MaxPerHour = 10, AlertChance = 0, RefuseAlertChance = 0, CopsRequired = 0, Items = {} } }
dofile(ROOT .. '/resources/[dev]/pickax_illegalbuilder/server/street.lua')
local function call(name, ...) local out; cbs[name](1, function(r) out = r end, ...) return out end

local cat = IB.streetCatalog()
ok(#cat == 1 and cat[1].item == 'weed_pooch' and cat[1].min == 80 and cat[1].max == 160, 'catalogue : prix du dealer × 0,8')
ok(call('illegalbuilder:street:info').error == 'Il te faut la tablette vendeur', 'tablette exigée')
inv.dealer_tablet = 1
ok(call('illegalbuilder:street:info').error == 'Tu n\'as rien à vendre', 'rien à vendre')
inv.weed_pooch = 20
local info = call('illegalbuilder:street:info')
ok(info.ok and info.items[1].have == 20, 'article proposé')
Config.PedSales.Enabled = false
ok(call('illegalbuilder:street:info').error:find('désactivée'), 'interrupteur général')
Config.PedSales.Enabled = true
ok(call('illegalbuilder:street:sell', 'coke_pooch').error:find('ne se vend pas'), 'article inconnu refusé')
local r = call('illegalbuilder:street:sell', 'weed_pooch')
ok(r.ok and r.accepted and r.qty >= 1 and r.qty <= 3 and r.total >= 80 * r.qty and r.total <= 160 * r.qty, 'vente acceptée')
ok(inv.weed_pooch == 20 - r.qty and paid[1][1] == 'black_money' and paid[1][2] == r.total, 'objets retirés et argent versé')
ok(call('illegalbuilder:street:sell', 'weed_pooch').error:find('Doucement'), 'délai entre deux ventes')
timer = timer + 9000
Config.StreetSales.AcceptChance = 0
local rr = call('illegalbuilder:street:sell', 'weed_pooch')
ok(rr.ok and rr.accepted == false and inv.weed_pooch == 20 - r.qty, 'PNJ qui refuse : rien ne bouge')
Config.StreetSales.AcceptChance = 100
Config.StreetSales.RefuseAlertChance = 100
timer = timer + 9000
call('illegalbuilder:street:sell', 'weed_pooch')   -- refus possible seulement si chance 100 → acceptée, pas d'alerte
Config.StreetSales.AcceptChance = 0
timer = timer + 9000
call('illegalbuilder:street:sell', 'weed_pooch')
ok(#alerts == 1, 'alerte police au refus')
-- limite horaire
Config.StreetSales.AcceptChance = 100; Config.StreetSales.RefuseAlertChance = 0; Config.StreetSales.QtyMin = 5; Config.StreetSales.QtyMax = 5
inv.weed_pooch = 100
local sold = 0
for i = 1, 6 do timer = timer + 9000 local x = call('illegalbuilder:street:sell', 'weed_pooch') if x.ok and x.accepted then sold = sold + x.qty end end
ok(IB.counter('street:id1', 3600).n <= 10, 'limite horaire respectée : ' .. IB.counter('street:id1', 3600).n)
Config.StreetSales.RequireTablet = false; inv.dealer_tablet = 0; Config.StreetSales.CopsRequired = 2
timer = timer + 9000
ok(call('illegalbuilder:street:sell', 'weed_pooch').error:find('policiers'), 'policiers requis')
print(('street_test : %d vérifications OK'):format(checks))
