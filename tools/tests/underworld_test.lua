-- Pègre : marché noir à rotation, contrats de livraison, casier judiciaire (natives simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local now, timer = 1700000000, 1000000
os.time = function() return now end
function GetGameTimer() return timer end
function CreateThread() end
function Wait() end
local cmds, cbs, notes, inserts, alerts, cmdsRegistered = {}, {}, {}, {}, 0, {}
function RegisterCommand(n, f) cmds[n] = f end
function RegisterNetEvent() end
function AddEventHandler() end
function GetResourceState() return 'missing' end
function GetPlayers() return {} end
MySQL = { query = { await = function(sql) if sql:find('FROM illegalbuilder_records') then return inserts.rows or {} end return {} end }, insert = function(sql, p) inserts[#inserts + 1] = p end }
local peds = { [1] = { ped = 11, pos = { x = 0.0, y = 0.0, z = 0.0 } }, [2] = { ped = 12, pos = { x = 2.0, y = 0.0, z = 0.0 } }, [3] = { ped = 13, pos = { x = 500.0, y = 0.0, z = 0.0 } } }
function GetPlayerPed(s) return peds[s] and peds[s].ped or 0 end
function GetEntityCoords(p) for _, v in pairs(peds) do if v.ped == p then return v.pos end end end
local function mkp(id, job, black, bank)
    local p = { source = id, identifier = 'id' .. id, job = { name = job }, acc = { black_money = black, bank = bank } }
    p.getAccount = function(n) return { money = p.acc[n] or 0 } end
    p.removeAccountMoney = function(n, v) p.acc[n] = p.acc[n] - v end
    p.addAccountMoney = function(n, v) p.acc[n] = (p.acc[n] or 0) + v end
    return p
end
local players = { [1] = mkp(1, 'unemployed', 100000, 0), [2] = mkp(2, 'police', 0, 0), [3] = mkp(3, 'unemployed', 5, 0) }
players[3].acc.bank = 300
ESX = { RegisterServerCallback = function(n, f) cbs[n] = f end, GetPlayerFromId = function(s) return players[s] end }
local given, society = {}, {}
IB = { inventory = function() return 'ox' end, isPoliceJob = function(n) return n == 'police' end, playerName = function(x) return x.identifier end, log = function() end,
    notify = function(s, m) notes[#notes + 1] = s .. ':' .. m end, canCarry = function() return true end, addItem = function(s, n, c) given[#given + 1] = { n, c } return true end,
    society = function(n, v) society[#society + 1] = { n, v } end, alertPolice = function() alerts = alerts + 1 end,
    distanceTo = function(s, c) local p = peds[s].pos local dx, dy = p.x - c.x, p.y - c.y return math.sqrt(dx * dx + dy * dy) end }
Config = {
    BlackMarket = { Enabled = true, RotationHours = 24, OffersPerRotation = 3, PriceMin = 0.8, PriceMax = 1.4, PerPlayerLimit = 2, Account = 'black_money', Radius = 4.0, AlertChance = 0,
        Locations = { { label = 'A', coords = { x = 0.0, y = 0.0, z = 0.0 } }, { label = 'B', coords = { x = 1000.0, y = 0.0, z = 0.0 } }, { label = 'C', coords = { x = 0.0, y = 1000.0, z = 0.0 } } },
        Items = { { item = 'a', price = 1000, stock = 5 }, { item = 'b', price = 500, stock = 1 }, { item = 'c', price = 200, stock = 9 }, { item = 'd', price = 300, stock = 2 } } },
    Contracts = { Enabled = true, Account = 'black_money', BaseReward = 500, PerKm = 1000, FastRatio = 0.5, FastBonus = 50, AvgSpeed = 20, TimeMargin = 1.5, MinSeconds = 60, MinDistance = 100, Radius = 15.0, Cooldown = 100, AlertChance = 100,
        Destinations = { { label = 'Loin', coords = { x = 2000.0, y = 0.0, z = 0.0 } } } },
    Record = { Enabled = true, Distance = 6.0 },
}
dofile(ROOT .. '/resources/[dev]/pickax_illegalbuilder/server/underworld.lua')
local function call(name, src, ...) local out; cbs[name](src, function(r) out = r end, ...) return out end

-- rotation : stable dans la rotation, change ensuite, identique pour tous
local o1, o2 = IB.bmOffers(now), IB.bmOffers(now + 3600)
ok(#o1 == 3 and #o2 == 3, 'nombre de produits par rotation')
local same = true for i = 1, 3 do if o1[i].item ~= o2[i].item or o1[i].price ~= o2[i].price then same = false end end
ok(same, 'même stock et mêmes prix pendant toute la rotation')
local seen, locs = {}, {}
for d = 0, 40 do local o = IB.bmOffers(now + d * 86400) local k = '' for _, x in ipairs(o) do k = k .. x.item .. x.price end seen[k] = true locs[IB.bmLocation(now + d * 86400).label] = true end
local nSeen, nLocs = 0, 0 for _ in pairs(seen) do nSeen = nSeen + 1 end for _ in pairs(locs) do nLocs = nLocs + 1 end
ok(nSeen > 5 and nLocs == 3, 'stock et lieu varient d\'une rotation à l\'autre')
local distinct = {} for _, o in ipairs(o1) do distinct[o.item] = true ok(o.price >= 1, 'prix positif') end
local nd = 0 for _ in pairs(distinct) do nd = nd + 1 end
ok(nd == 3, 'pas de doublon dans les offres')
for _, o in ipairs(o1) do
    local base = ({ a = 1000, b = 500, c = 200, d = 300 })[o.item]
    ok(o.price >= base * 0.8 - 1 and o.price <= base * 1.4 + 1, 'prix dans la fourchette')
end

-- achat : lieu courant
local loc = IB.bmLocation()
peds[1].pos = { x = loc.coords.x + 0.0, y = loc.coords.y + 0.0, z = 0.0 }
local info = call('illegalbuilder:bm:info', 1)
ok(info.ok and info.near and #info.offers == 3, 'sur place : le stock est visible')
peds[1].pos = { x = loc.coords.x + 300.0, y = loc.coords.y + 0.0, z = 0.0 }
info = call('illegalbuilder:bm:info', 1)
ok(info.ok and not info.near and #info.offers == 0, 'loin : seulement l\'indice du lieu')
ok(call('illegalbuilder:bm:buy', 1, 1, 1).error == 'Tu n\'es pas chez le vendeur.', 'achat refusé loin du vendeur')
peds[1].pos = { x = loc.coords.x + 0.0, y = loc.coords.y + 0.0, z = 0.0 }
timer = timer + 5000
local offer = o1[1]
local before = players[1].acc.black_money
local r = call('illegalbuilder:bm:buy', 1, offer.id, 1)
ok(r.ok and r.paid == offer.price and players[1].acc.black_money == before - offer.price and given[#given][1] == offer.item, 'achat : argent sale débité, objet donné')
timer = timer + 5000
ok(call('illegalbuilder:bm:buy', 1, 99, 1).error == 'Offre inconnue.', 'offre inconnue refusée')
timer = timer + 5000
ok(call('illegalbuilder:bm:buy', 1, offer.id, 0).error == 'Quantité invalide.', 'quantité invalide refusée')
timer = timer + 5000
r = call('illegalbuilder:bm:buy', 1, offer.id, 10)
ok(r.ok and r.qty == 1, 'quantité plafonnée par la limite (2 max, 1 déjà pris)')
timer = timer + 5000
r = call('illegalbuilder:bm:buy', 1, offer.id, 5)
ok(not r.ok and r.error:find('épuisé'), 'limite par joueur atteinte')
timer = timer + 5000
players[3].acc.black_money = 5; peds[3].pos = { x = loc.coords.x + 0.0, y = loc.coords.y + 0.0, z = 0.0 }
ok(call('illegalbuilder:bm:buy', 3, offer.id, 1).error:find('argent sale'), 'fonds insuffisants refusés')
timer = timer + 5000
now = now + 86400 * 3
local loc2 = IB.bmLocation()
ok(loc2.label ~= nil, 'rotation suivante : nouveau lieu')
Config.BlackMarket.Enabled = false
ok(call('illegalbuilder:bm:info', 1).error == 'Le marché noir est fermé.', 'marché noir désactivé')
Config.BlackMarket.Enabled = true

-- contrats
ok(IB.contractLimit(2000) == 150 and IB.contractLimit(10) == 60, 'temps imparti : distance / vitesse × marge, minimum')
local rw, fast = IB.contractReward(2000, 100, 150)
ok(rw == 2500 and not fast, 'paiement : base + km')
rw, fast = IB.contractReward(2000, 60, 150)
ok(rw == 3750 and fast, 'prime de rapidité +50 %')
peds[1].pos = { x = 0.0, y = 0.0, z = 0.0 }
r = call('illegalbuilder:contract:start', 1)
ok(r.ok and r.label == 'Loin' and r.limit == 150, 'contrat accepté')
ok(alerts == 1, 'alerte police au départ (100 %)')
ok(call('illegalbuilder:contract:start', 1).error == 'Tu as déjà un contrat en cours.', 'un seul contrat à la fois')
ok(call('illegalbuilder:contract:done', 1).error == 'Tu n\'es pas au point de livraison.', 'livraison refusée loin du point')
peds[1].pos = { x = 2000.0, y = 0.0, z = 0.0 }
now = now + 200
r = call('illegalbuilder:contract:done', 1)
ok(not r.ok and r.failed, 'trop tard : contrat échoué')
ok(call('illegalbuilder:contract:done', 1).error == 'Aucun contrat en cours.', 'contrat terminé après échec')
now = now - 150
ok(call('illegalbuilder:contract:start', 1).error:find('Reviens dans'), 'délai entre deux contrats')
now = now + 150
now = now + 500
peds[1].pos = { x = 0.0, y = 0.0, z = 0.0 }
ok(call('illegalbuilder:contract:start', 1).ok, 'nouveau contrat')
peds[1].pos = { x = 2000.0, y = 0.0, z = 0.0 }
now = now + 40
local b2 = players[1].acc.black_money
r = call('illegalbuilder:contract:done', 1)
ok(r.ok and r.fast and r.reward == 3750 and players[1].acc.black_money == b2 + 3750, 'livraison rapide payée avec prime')
now = now + 500
peds[1].pos = { x = 0.0, y = 0.0, z = 0.0 }
call('illegalbuilder:contract:start', 1)
peds[1].pos = { x = 2000.0, y = 0.0, z = 0.0 }
r = call('illegalbuilder:contract:done', 1)
ok(not r.ok and r.failed, 'téléportation (livraison instantanée) refusée')

-- casier : un seul casier, celui de la tablette police (pickax_jobbuilder)
local added = {}
exports = setmetatable({}, { __index = function() return { AddRecordEntry = function(_, job, target, kind, label, amount, details, by) added[#added + 1] = { job, target, kind, label, amount, by } return 5 end } end })
GetResourceState = function() return 'started' end
ok(IB.recordAdd(players[2], players[3], 'seizure', 'Détention de produits illicites', 700) and added[1][1] == 'police' and added[1][2] == 3 and added[1][3] == 'seizure' and added[1][5] == 700, 'ligne ajoutée au casier de la tablette police (job de l\'agent)')
GetResourceState = function() return 'stopped' end
ok(not IB.recordAdd(players[2], players[3], 'seizure', 'x', 0), 'tablette police arrêtée : rien n\'est écrit')
ok(cmds.casier == nil and cmds.inculper == nil, 'plus de /casier ni /inculper : pas de doublon avec la tablette police')
print(('underworld_test : %d vérifications OK'):format(checks))
