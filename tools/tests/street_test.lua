-- Vente de rue aux PNJ : conditions, acceptation, quantité, prix, limites (natives simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local realRandom, refuse = math.random, false
math.random = function(a, b) if b then return realRandom(a, b) end if a == 100 then return refuse and 100 or 1 end return realRandom(a) end
local cbs, inv, paid, alerts, timer = {}, {}, {}, {}, 1000000
local xp = { identifier = 'id1', source = 1 }
function GetGameTimer() return timer end
function GetPlayerPed() return 5 end
function GetVehiclePedIsIn() return 0 end
function GetEntityCoords() return { x = 1.0, y = 2.0, z = 3.0 } end
function GetResourceState() return 'missing' end
function RegisterCommand() end
function CreateThread() end
function Wait() end
function exports() end
MySQL = { query = { await = function() end }, single = { await = function() return nil end }, update = function() end }
function ESXplaceholder() end
function AddEventHandler() end
ESX = { RegisterServerCallback = function(n, f) cbs[n] = f end, GetPlayerFromId = function() return xp end }
IB = { itemCount = function(_, n) return inv[n] or 0 end, removeItem = function(_, n, c) if (inv[n] or 0) < c then return false end inv[n] = inv[n] - c return true end,
    copCount = function() return 0 end, alertPolice = function(c, t) alerts[#alerts + 1] = t end, log = function() end, Counters = {},
    pay = function(_, acc, amount) paid[#paid + 1] = { acc, amount } end }
IB.takeUnits = function(src, n, c) if IB.removeItem(src, n, c) then return true, 1.0, 50 end return false end
function IB.counter(key, w) local c = IB.Counters[key] if not c then c = { n = 0, since = 0 } IB.Counters[key] = c end return c end
Config = { PedSales = { Enabled = true }, DrugOrder = { 'weed' }, Drugs = { weed = { label = 'Cannabis', pooch = 'weed_pooch', price = { pooch = { 100, 200 } } } },
    StreetSales = { Enabled = true, RequireTablet = true, TabletItem = 'dealer_tablet', AcceptChance = 100, QtyMin = 1, QtyMax = 3, PriceFactor = 0.8, Account = 'black_money', Cooldown = 8, MaxPerHour = 10, AlertChance = 0, RefuseAlertChance = 0, CopsRequired = 0, Items = {} } }
Config.StreetRep = { Enabled = true, PerUnit = 1, Levels = { 0, 40, 120, 300, 700 }, Names = { 'Petit revendeur', 'Revendeur', 'Dealer', 'Caïd', 'Baron' }, AcceptPerLevel = 4, PricePerLevel = 0.04 }
Config.StreetZones = { Enabled = true, Cell = 300, SatPerUnit = 4, SatDecay = 3, MaxPriceDrop = 0.4, HeatPerSale = 6, HeatPerRefuse = 3, HeatDecay = 2, HeatAlert = 0.3, HeatAccept = 0.25, Named = {} }
local takeStub = nil
dofile(ROOT .. '/resources/[dev]/pickax_illegalbuilder/server/street_rep.lua')
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
refuse = true
local rr = call('illegalbuilder:street:sell', 'weed_pooch')
refuse = false
ok(rr.ok and rr.accepted == false and inv.weed_pooch == 20 - r.qty, 'PNJ qui refuse : rien ne bouge')
Config.StreetSales.AcceptChance = 100
Config.StreetSales.RefuseAlertChance = 100
timer = timer + 9000
call('illegalbuilder:street:sell', 'weed_pooch')   -- refus possible seulement si chance 100 → acceptée, pas d'alerte
Config.StreetSales.AcceptChance = 0
timer = timer + 9000
local alertsBefore = #alerts
refuse = true
call('illegalbuilder:street:sell', 'weed_pooch')
refuse = false
ok(#alerts == alertsBefore + 1, 'alerte police au refus')
-- limite horaire
Config.StreetSales.AcceptChance = 100; Config.StreetSales.RefuseAlertChance = 0; Config.StreetSales.QtyMin = 5; Config.StreetSales.QtyMax = 5
inv.weed_pooch = 100
local sold = 0
for i = 1, 6 do timer = timer + 9000 local x = call('illegalbuilder:street:sell', 'weed_pooch') if x.ok and x.accepted then sold = sold + x.qty end end
ok(IB.counter('street:id1', 3600).n <= 10, 'limite horaire respectée : ' .. IB.counter('street:id1', 3600).n)
Config.StreetSales.RequireTablet = false; inv.dealer_tablet = 0; Config.StreetSales.CopsRequired = 2
timer = timer + 9000
ok(call('illegalbuilder:street:sell', 'weed_pooch').error:find('policiers'), 'policiers requis')

-- ─── réputation, saturation, chaleur ───
Config.StreetSales.AcceptChance = 60; Config.StreetSales.AlertChance = 0
local z0 = { sat = 0, heat = 0 }
local a0, p0, al0, l0 = IB.streetModifiers(0, z0, nil)
ok(a0 == 60 and p0 == 1.0 and al0 == 0 and l0 == 1, 'niveau 1, secteur calme : valeurs de base')
local a3, p3, _, l3 = IB.streetModifiers(150, z0, nil)
ok(l3 == 3 and a3 == 68 and math.abs(p3 - 1.08) < 1e-9, 'niveau 3 : +8 % d\'acceptation, +8 % de prix')
local _, pS = IB.streetModifiers(0, { sat = 100, heat = 0 }, nil)
ok(math.abs(pS - 0.6) < 1e-9, 'secteur saturé : prix -40 %')
local aH, _, alH = IB.streetModifiers(0, { sat = 0, heat = 100 }, nil)
ok(aH == 35 and alH == 30, 'secteur chaud : acceptation -25, alerte +30')
local _, pN = IB.streetModifiers(0, { sat = 0, heat = 0 }, { demand = 1.25 })
ok(math.abs(pN - 1.25) < 1e-9, 'zone nommée : demande ×1,25')
ok(select(1, IB.streetModifiers(10000, { sat = 0, heat = 100 }, nil)) >= 5 and select(1, IB.streetModifiers(10000, z0, nil)) <= 95, 'acceptation bornée 5-95 %')
local lvl, name, nextNeed = IB.repLevel(125)
ok(lvl == 3 and name == 'Dealer' and nextNeed == 300, 'paliers de réputation')
local zz = { sat = 0, heat = 0 }
IB.streetZoneAfter(zz, 3) ok(zz.sat == 12 and zz.heat == 6, 'une vente sature et chauffe le secteur')
IB.streetZoneAfter(zz, 0) ok(zz.heat == 9, 'un refus chauffe un peu')
local k1 = IB.streetZoneKey({ x = 10.0, y = 10.0 }) local k2 = IB.streetZoneKey({ x = 700.0, y = 10.0 })
ok(k1 ~= k2 and k1 == IB.streetZoneKey({ x = 100.0, y = 100.0 }), 'découpage en secteurs de 300 m')
Config.StreetZones.Named = { { name = 'Grove', coords = { x = 0, y = 0, z = 0 }, radius = 50, demand = 1.2 } }
local kn, nz = IB.streetZoneKey({ x = 10.0, y = 10.0 })
ok(kn == 'n:Grove' and nz.demand == 1.2, 'zone nommée prioritaire')
Config.StreetZones.Named = {}
-- retombée avec le temps (sans toucher à os.time réel)
local zs = IB.streetZoneState('test', 1000) zs.sat = 50 zs.heat = 30 zs.t = 1000
zs = IB.streetZoneState('test', 1000 + 600)    -- 10 minutes
ok(math.abs(zs.sat - 20) < 1e-9 and math.abs(zs.heat - 10) < 1e-9, 'saturation -3/min, chaleur -2/min')
-- vente complète : réputation et chaleur augmentent
Config.StreetSales.AcceptChance = 100; Config.StreetSales.QtyMin = 2; Config.StreetSales.QtyMax = 2; Config.StreetSales.MaxPerHour = 0; Config.StreetSales.CopsRequired = 0
Config.StreetSales.RequireTablet = false; inv.weed_pooch = 50; timer = timer + 20000
local before = IB.getRep('id1')
local rs = call('illegalbuilder:street:sell', 'weed_pooch')
ok(rs.ok and rs.accepted and IB.getRep('id1') == before + 2 and rs.heat >= 6 and rs.saturation >= 8, 'vente : +2 réputation, secteur chaud et saturé')
print(('street_test : %d vérifications OK'):format(checks))
