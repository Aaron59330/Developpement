-- Pègre (suite) : récidive, informateurs, prison avec travaux, planques (natives simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local now, timer = 1700000000, 1000000
os.time = function() return now end
function GetGameTimer() return timer end
function CreateThread() end
function Wait() end
function SetTimeout() end
function RegisterCommand(n, f) _G.__cmds = _G.__cmds or {} _G.__cmds[n] = f end
local cmds = setmetatable({}, { __index = function(_, k) return _G.__cmds[k] end })
local cbs, notes, events, teleports, updates, inserted, opened = {}, {}, {}, {}, {}, {}, {}
function AddEventHandler(n, f) events[n] = f end
function TriggerClientEvent() end
function GetResourceState() return 'started' end
function GetPlayers() return { '1', '2', '3' } end
function SetEntityCoords(ped, x, y, z) teleports[#teleports + 1] = { ped, x, y, z } end
MySQL = { query = { await = function(sql) return {} end }, update = function(sql, p) updates[#updates + 1] = sql end,
    insert = { await = function(sql, p) inserted[#inserted + 1] = p return 7 end } }
local peds = { [1] = { ped = 11, pos = { x = 0.0, y = 0.0, z = 0.0 } }, [2] = { ped = 12, pos = { x = 1.0, y = 0.0, z = 0.0 } } }
function GetPlayerPed(s) return peds[s] and peds[s].ped or 0 end
function GetEntityCoords(p) for _, v in pairs(peds) do if v.ped == p then return v.pos end end end
local function mkp(id, job, money, bank)
    local p = { source = id, identifier = 'id' .. id, job = { name = job }, acc = { money = money, bank = bank } }
    p.getAccount = function(n) return { money = p.acc[n] or 0 } end
    p.removeAccountMoney = function(n, v) p.acc[n] = p.acc[n] - v end
    p.addAccountMoney = function(n, v) p.acc[n] = (p.acc[n] or 0) + v end
    return p
end
local players = { [1] = mkp(1, 'police', 0, 0), [2] = mkp(2, 'unemployed', 5000, 0), [3] = mkp(3, 'police', 0, 0) }
ESX = { RegisterServerCallback = function(n, f) cbs[n] = f end, GetPlayerFromId = function(s) return players[s] end }
local jail = {}   -- [source] = secondes restantes
local coreApi = { JailPlayer = function(_, id, secs, author, reason, off) if jail[id] then return false, 'déjà' end jail[id] = secs return true, secs end,
    JailTimeLeft = function(_, id) return jail[id] or 0 end,
    ReduceJail = function(_, id, s) jail[id] = math.max(1, jail[id] - s) return jail[id] end,
    UnjailPlayer = function(_, id) if not jail[id] then return false end jail[id] = nil return true end }
local handlers, priorN, lastDays = {}, 0, nil
local jobApi = { RecordPriors = function(_, id, days) lastDays = days return priorN end }
exports = setmetatable({ pickax_core = coreApi, pickax_jobbuilder = jobApi }, { __call = function(_, name, f) handlers[name] = f end, __index = function() return { forceOpenInventory = function(_, s, k, id) opened[#opened + 1] = id end, RegisterStash = function() end } end })
local records = {}
IB = { isPoliceJob = function(n) return n == 'police' end, playerName = function(x) return x.identifier end, log = function() end, isAdmin = function() return false end, copCount = function() return 1 end,
    notify = function(s, m) notes[#notes + 1] = s .. ':' .. m end,
    recordAdd = function(officer, target, kind, label, amount) records[#records + 1] = { target.identifier, label, kind } return true end,
    bmLocation = function() return { label = 'Casse', hint = 'à la casse', coords = { x = 500.0, y = 500.0, z = 0.0 } } end,
    contractZones = function() return { { x = 2000.0, y = 0.0, z = 0.0 } } end,
    distanceTo = function(s, c) local p = peds[s].pos local dx, dy = p.x - c.x, p.y - c.y return math.sqrt(dx * dx + dy * dy) end }
Config = { Record = { Enabled = true, Distance = 6.0, Recidive = { Enabled = true, PercentPerPrior = 20, MaxPercent = 60, WindowDays = 30 } },
    Informants = { Enabled = true, Radius = 3.0, Locations = { { label = 'x', coords = { x = 0.0, y = 0.0, z = 0.0 } } }, Offers = { blackmarket = { label = 'BM', price = 2500 }, contract = { label = 'C', price = 1500, police = true } } },
    Prison = { Enabled = true, MaxMinutes = 60,
        Work = { Reduce = 30, Cooldown = 45, Spots = { { label = 'Cuisine', coords = { x = 1000.0, y = 1000.0, z = 0.0 } } } }, MaxReductionPercent = 50, ArrestBonus = { Enabled = true, PerPrior = 150, Max = 400, Account = 'bank' } },
    Stashes = { Enabled = true, Max = 2, ExpireDays = 14, SearchRadius = 5.0, FindChance = 100, SearchCooldown = 20, MinCops = 0 } }
dofile(ROOT .. '/resources/[dev]/pickax_illegalbuilder/server/underworld2.lua')
local function call(name, src, ...) local out; cbs[name](src, function(r) out = r end, ...) return out end

-- récidive
ok(IB.recidiveMul(0) == 1.0 and math.abs(IB.recidiveMul(2) - 1.4) < 1e-9 and math.abs(IB.recidiveMul(10) - 1.6) < 1e-9, 'récidive : +20 % par antécédent, plafonné à +60 %')
Config.Record.Recidive.Enabled = false
ok(IB.recidiveMul(5) == 1.0, 'récidive désactivée : ×1')
Config.Record.Recidive.Enabled = true
priorN = 3
ok(IB.priorCount('x') == 3 and lastDays == 30, 'antécédents des 30 derniers jours lus dans le casier de la tablette police')
ok(math.abs(handlers.RecidiveMul('x') - 1.6) < 1e-9, 'export RecidiveMul (tablette police) : +60 % pour 3 antécédents')
Config.Record.Enabled = false
ok(handlers.RecidiveMul('x') == 1.0, 'casier désactivé : amendes non aggravées')
Config.Record.Enabled = true
GetResourceState = function(r) return r == 'pickax_jobbuilder' and 'stopped' or 'started' end
ok(IB.priorCount('x') == 0, 'tablette police arrêtée : aucun antécédent')
GetResourceState = function() return 'started' end
priorN = 0

-- informateurs
ok(call('illegalbuilder:informant:info', 2).near and #call('illegalbuilder:informant:info', 2).offers == 1, 'civil : seul le tuyau du marché noir')
ok(#call('illegalbuilder:informant:info', 1).offers == 2, 'policier : tuyau supplémentaire sur les livraisons')
local r = call('illegalbuilder:informant:buy', 2, 'blackmarket')
ok(r.ok and r.coords.x == 500.0 and players[2].acc.money == 2500, 'achat : position du marché noir, 2 500 $ en liquide')
timer = timer + 5000
ok(call('illegalbuilder:informant:buy', 2, 'contract').error == 'Il ne sait rien sur ça.', 'un civil n\'a pas accès au tuyau police')
r = call('illegalbuilder:informant:buy', 1, 'contract')
ok(not r.ok and r.error:find('liquide'), 'fonds insuffisants')
players[1].acc.money = 5000; timer = timer + 5000
r = call('illegalbuilder:informant:buy', 1, 'contract')
ok(r.ok and math.abs(r.coords.x - 2000) <= 120, 'tuyau police : zone approximative de la livraison')
timer = timer + 5000
peds[2].pos = { x = 300.0, y = 0.0, z = 0.0 }
ok(call('illegalbuilder:informant:buy', 2, 'blackmarket').error == 'Aucun indic à proximité.', 'loin de l\'indic : refusé')
peds[2].pos = { x = 1.0, y = 0.0, z = 0.0 }

-- prison (pickax_core)
local officer1 = players[1]
local okj, mins = IB.jailPlayer(2, 10, officer1, 'x')
ok(okj and mins == 10 and jail[2] == 600, 'peine envoyée à la prison de pickax_core')
ok(select(2, IB.jailPlayer(2, 5, officer1, 'x')) == 'déjà', 'déjà en prison : refusé')
jail[2] = nil
ok(select(2, IB.jailPlayer(2, 500, officer1, 'x')) == 60, 'peine plafonnée à 60 min')
jail[2] = nil
IB.jailPlayer(2, 10, officer1, 'x')
local j = { total = 600, reduced = 0 }
ok(IB.jailReduce(j, 30) == 30 and IB.jailReduce({ total = 600, reduced = 290 }, 30) == 10 and IB.jailReduce({ total = 600, reduced = 300 }, 30) == 0, 'réduction plafonnée à 50 % de la peine')
ok(call('illegalbuilder:jail:work', 1).error == 'Tu n\'es pas en prison.', 'travail réservé aux détenus')
peds[2].pos = { x = 0.0, y = 0.0, z = 0.0 }
ok(call('illegalbuilder:jail:work', 2).error == 'Rends-toi à un poste de travail.', 'travail loin du poste refusé')
peds[2].pos = { x = 1000.0, y = 1001.0, z = 0.0 }
r = call('illegalbuilder:jail:work', 2)
ok(r.ok and r.cut == 30 and r.left == 570 and jail[2] == 570, 'travail : peine réduite de 30 s dans pickax_core')
ok(call('illegalbuilder:jail:work', 2).error == 'Reprends ton souffle.', 'délai entre deux travaux')
for i = 1, 20 do now = now + 50 call('illegalbuilder:jail:work', 2) end
r = call('illegalbuilder:jail:work', 2)
ok(not r.ok and r.error:find('ne peut plus') and jail[2] >= 300, 'plafond de réduction atteint (la peine reste ≥ 50 %)')
jail[2] = nil
-- peine donnée par le staff : le plafond se calcule au premier travail
jail[2] = 200; players[2].identifier = 'idstaff'; now = now + 100
r = call('illegalbuilder:jail:work', 2)
ok(r.ok and r.cut == 30 and jail[2] == 170, 'peine du staff : travail accepté')
players[2].identifier = 'id2'; jail[2] = nil
-- commande /emprisonner
peds[2].pos = { x = 1.0, y = 0.0, z = 0.0 }; peds[1].pos = { x = 0.0, y = 0.0, z = 0.0 }
priorN = 2
cmds.emprisonner(2, { '1', '5', 'vol' })
ok(notes[#notes]:find('Réservé à la police'), 'un civil ne peut pas emprisonner')
cmds.emprisonner(1, { '2', '5', 'vol', 'armé' })
ok(jail[2] == 420 and players[1].acc.bank == 300 and records[#records][2] == 'Peine de 7 min : vol armé', 'récidive : 5 min × 1,4 = 7 min, prime de 300 $ au policier')
jail[2] = nil
priorN = 9
cmds.emprisonner(1, { '2', '5', 'vol' })
ok(players[1].acc.bank == 700, 'prime plafonnée (400)')
cmds.liberer(1, { '2' })
ok(jail[2] == nil and notes[#notes]:find('libéré'), '/liberer libère le détenu')
cmds.liberer(1, { '2' })
ok(notes[#notes]:find('pas en prison'), 'libération d\'un non-détenu refusée')
GetResourceState = function(r) return r == 'pickax_core' and 'stopped' or 'started' end
ok(select(2, IB.jailPlayer(2, 5, officer1, 'x')):find('pas disponible'), 'pickax_core arrêté : message clair')
GetResourceState = function() return 'started' end

-- planques
cmds.planque(2)
ok(inserted[#inserted][1] == 'id2' and notes[#notes]:find('Planque créée'), 'planque créée')
timer = timer + 5000
cmds.planque(2)
ok(opened[#opened] == 'ib_hide_7', 'à proximité : la planque s\'ouvre')
timer = timer + 5000
peds[2].pos = { x = 50.0, y = 0.0, z = 0.0 }
IB.Stashes[8] = { id = 8, owner = 'id2', x = 100.0, y = 0.0, z = 0.0, created = now }
cmds.planque(2)
ok(notes[#notes]:find('déjà 2 planque'), 'maximum de planques')
ok(IB.stashFindChance(0) == 100 and IB.stashFindChance(5) == 50 and IB.stashFindChance(6) == 0, 'chance de trouver : décroît avec la distance')
ok(IB.stashExpired(now - 15 * 86400, now) and not IB.stashExpired(now - 13 * 86400, now), 'expiration après 14 jours')
timer = timer + 60000
peds[1].pos = { x = 400.0, y = 0.0, z = 0.0 }
cmds.fouillerplanque(1)
ok(notes[#notes]:find('rien'), 'aucune planque à portée')
timer = timer + 60000
peds[1].pos = { x = 100.5, y = 0.0, z = 0.0 }
cmds.fouillerplanque(2)
ok(notes[#notes]:find('Réservé à la police'), 'fouille réservée à la police')
cmds.fouillerplanque(1)
ok(IB.Stashes[8] == nil and opened[#opened] == 'ib_hide_8' and records[#records][2] == 'Planque découverte par la police', 'planque découverte : ouverte, supprimée, casier du propriétaire')
print(('underworld2_test : %d vérifications OK'):format(checks))
