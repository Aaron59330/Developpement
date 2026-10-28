-- Convois de gang : lancement, conditions, livraison, détournement par un rival (natives simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local now = 1700000000
os.time = function() return now end
local threads, notes, sent = {}, {}, {}
function CreateThread(f) threads[#threads + 1] = f end
function Wait() end
function AddEventHandler() end
local cmds = {}
function RegisterCommand(n, f) cmds[n] = f end
function TriggerClientEvent(ev, src, a, b) sent[#sent + 1] = { src, a, b } end
local peds, veh, hp = { [1] = { 11, { x = 0.0, y = 0.0, z = 0.0 } }, [2] = { 12, { x = 500.0, y = 0.0, z = 0.0 } }, [3] = { 13, { x = 900.0, y = 0.0, z = 0.0 } } }, { [11] = 5 }, {}
function GetPlayerPed(s) return peds[s] and peds[s][1] or 0 end
function GetEntityCoords(p) for _, v in pairs(peds) do if v[1] == p then return v[2] end end end
function GetEntityHealth() return 200 end
function GetVehiclePedIsIn(p) return veh[p] or 0 end
local money = { a = { money = 0, dirty = 0 }, b = { money = 0, dirty = 0 } }
local rep = {}
GB = { Gangs = { a = { label = 'A', boss_grade = 3 }, b = { label = 'B', boss_grade = 3 } }, PlayerGang = { [1] = { name = 'a' }, [2] = { name = 'b' }, [3] = { name = 'b' } },
    notify = function(s, m) notes[#notes + 1] = m end, news = function() end, addRep = function(g, n) rep[#rep + 1] = { g, n } end,
    onlineMembers = function(n) local l = {} for s, g in pairs(GB.PlayerGang) do if g.name == n then l[#l + 1] = s end end return l end,
    gangOf = function(s) local g = GB.PlayerGang[s] return g and GB.Gangs[g.name] and setmetatable({ name = g.name }, { __index = GB.Gangs[g.name] }), s == 1 and 3 or 0 end,
    treasuryAdd = function(n, k, v) money[n][k] = money[n][k] + v return true end }
Config = { Convoy = { Enabled = true, Account = 'dirty', BaseReward = 1000, PerKm = 1000, StealPercent = 50, InterceptRadius = 25.0, InterceptSeconds = 3, ArriveRadius = 20.0, AvgSpeed = 10, TimeMargin = 1.5, Cooldown = 600, MinMembers = 1, ApproxRadius = 150.0, RepWin = 5, RepHijack = 8,
    Routes = { { label = 'Loin', coords = { x = 2000.0, y = 0.0, z = 0.0 } } } } }
dofile(ROOT .. '/resources/[dev]/pickax_gangbuilder/server/convoy.lua')
-- la boucle est infinie : on l'exécute par pas en remplaçant Wait par un yield
Wait = function() coroutine.yield() end
-- recharge avec Wait coopératif
threads = {}
dofile(ROOT .. '/resources/[dev]/pickax_gangbuilder/server/convoy.lua')
local co = coroutine.create(threads[1])
local function step(n) for _ = 1, n or 1 do now = now + 1 assert(coroutine.resume(co)) end end

ok(GB.convoyStep(0, 1) == 1 and GB.convoyStep(5, 0) == 4 and GB.convoyStep(0, 0) == 0 and GB.convoyStep(2, 3) == 3, 'progression : +1 avec rival proche, -1 sinon')
ok(GB.convoyReward(2000) == 3000 and GB.convoyLoot(3000) == 1500, 'prime et part volée')
local good, err = GB.convoyStart(2)
ok(not good and err:find('bureau'), 'réservé au bureau du gang')
veh[11] = 0
good, err = GB.convoyStart(1)
ok(not good and err:find('Monte dans le véhicule'), 'il faut être en véhicule')
veh[11] = 5
good = GB.convoyStart(1)
ok(good and GB.convoyActive(), 'convoi lancé')
ok(select(2, GB.convoyStart(1)):find('déjà en cours'), 'un seul convoi à la fois')
local owner, rival = false, false
for _, e in ipairs(sent) do if e[1] == 1 and e[3] == 'owner' and e[2].to then owner = true end if e[1] == 2 and e[3] == 'rival' and e[2].radius and not e[2].to then rival = true end end
ok(owner and rival, 'le gang voit la destination, les rivaux seulement une zone approximative')
-- détournement : un rival reste près du véhicule
peds[1][2] = { x = 100.0, y = 0.0, z = 0.0 }; peds[2][2] = { x = 110.0, y = 0.0, z = 0.0 }
step(2)
ok(GB.convoyActive(), 'interception en cours')
step(2)
ok(not GB.convoyActive() and money.b.dirty == 1500 and money.a.dirty == 0, 'détourné : la moitié de la prime (convoi de 2 km : 3 000 $) va au rival')
ok(rep[#rep][1] == 'b', 'réputation au détourneur')
ok(select(2, GB.convoyStart(1)):find('Prochain convoi'), 'délai avant un nouveau convoi')
-- livraison
now = now + 1000
peds[2][2] = { x = 500.0, y = 0.0, z = 0.0 }; peds[1][2] = { x = 0.0, y = 0.0, z = 0.0 }
ok(GB.convoyStart(1), 'nouveau convoi après le délai')
peds[1][2] = { x = 2000.0, y = 0.0, z = 0.0 }
step(1)
ok(not GB.convoyActive() and money.a.dirty == 3000, 'livraison : prime dans la trésorerie')
-- hors véhicule / retard
now = now + 1000
peds[1][2] = { x = 0.0, y = 0.0, z = 0.0 }
GB.convoyStart(1)
veh[11] = 0; peds[1][2] = { x = 2000.0, y = 0.0, z = 0.0 }
step(1)
ok(GB.convoyActive(), 'à pied à destination : pas de livraison')
now = now + 100000
step(1)
ok(not GB.convoyActive(), 'retard : convoi annulé')
Config.Convoy.Enabled = false
ok(select(2, GB.convoyStart(1)):find('désactivés'), 'convois désactivés')
print(('convoy_test : %d vérifications OK'):format(checks))
