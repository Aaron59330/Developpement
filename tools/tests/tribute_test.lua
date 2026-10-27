-- Zones de tribut : décision du vainqueur, déroulé d'un événement et collecte (natives simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local now, handlers, cmds, threads, events, pay, rep = 1000, {}, {}, {}, {}, {}, {}
os.time = function() return now end
function Wait() end
function CreateThread(f) threads[#threads + 1] = f end
function SetTimeout() end
function AddEventHandler() end
function RegisterNetEvent(n, f) handlers[n] = f end
function RegisterCommand(n, f) cmds[n] = f end
function exports() end
function TriggerClientEvent(n, src, d) events[#events + 1] = { n = n, src = src, d = d } end
local peds = {}
function GetPlayerPed(src) return peds[src] and peds[src].ped or 0 end
function GetEntityCoords(ped) for _, p in pairs(peds) do if p.ped == ped then return p.pos end end end
function GetEntityHealth(ped) for _, p in pairs(peds) do if p.ped == ped then return p.hp end end end
ESX = { GetPlayerFromId = function() return {} end }
Config = { Tribute = { Enabled = true, AutoStart = false, Interval = 60, MinGangsOnline = 2, MinPerGang = 1, CaptureSeconds = 300, CollectWindow = 600, CollectDistance = 3.5,
    RewardAccount = 'dirty', Reward = 3000, RewardRep = 15,
    Zones = { { name = 'z1', label = 'Zone 1', coords = { x = 0.0, y = 0.0, z = 30.0 }, radius = 50.0, collect = { x = 5.0, y = 5.0, z = 30.0 } } } } }
GB = { Gangs = { a = { label = 'A' }, b = { label = 'B' } }, PlayerGang = {}, isDev = function() return true end, notify = function() end, log = function() end, news = function() end,
    treasuryAdd = function(n, k, v) pay[#pay + 1] = { n, k, v } end, addRep = function(n, v) rep[#rep + 1] = { n, v } end, onlineMembers = function(n) local l = {} for s, g in pairs(GB.PlayerGang) do if g.name == n then l[#l + 1] = s end end return l end }
dofile(ROOT .. '/resources/[dev]/pickax_gangbuilder/server/tribute.lua')

-- décision pure
ok(GB.tributeDecide({ a = 3, b = 2 }, {}, 1) == 'a', 'plus de survivants')
ok(GB.tributeDecide({ a = 2, b = 2 }, { a = 50, b = 80 }, 1) == 'b', 'égalité : présence')
ok(GB.tributeDecide({ a = 2, b = 2 }, { a = 50, b = 50 }, 1) == nil, 'égalité parfaite : personne')
ok(GB.tributeDecide({ a = 1 }, {}, 2) == nil, 'minimum non atteint')
ok(GB.tributeDecide({}, {}, 1) == nil, 'zone vide')

-- événement
GB.PlayerGang = { [1] = { name = 'a' }, [2] = { name = 'a' }, [3] = { name = 'b' } }
peds = { [1] = { ped = 11, pos = { x = 1.0, y = 1.0, z = 30.0 }, hp = 200 }, [2] = { ped = 12, pos = { x = 2.0, y = 2.0, z = 30.0 }, hp = 200 }, [3] = { ped = 13, pos = { x = 3.0, y = 3.0, z = 30.0 }, hp = 200 } }
ok(GB.startTribute('nope') == false, 'zone inconnue refusée')
ok(GB.startTribute('z1') == true, 'démarrage')
ok(GB.startTribute('z1') == false, 'une seule zone à la fois')
local loop = threads[#threads]
-- fait tourner la boucle : Wait() avance le temps d'une seconde ; s'arrête quand on lève une erreur contrôlée
local ticks, STOP = 0, {}
Wait = function() now = now + 1; ticks = ticks + 1; if ticks > 320 then error(STOP) end end
peds[3].hp = 0                                    -- le gang b est mort : aucun survivant
local r, e = pcall(loop)
ok(not r and e == STOP, 'boucle')
ok(rep[1] == nil, 'pas encore de récompense')
-- phase collecte : gang a vainqueur (2 vivants contre 0)
local snap
for i = #events, 1, -1 do if events[i].n == 'gangbuilder:client:tribute' and events[i].d and events[i].d.phase == 'collect' then snap = events[i].d break end end
ok(snap and snap.winner == 'a', 'vainqueur a')
-- collecte refusée : mauvais gang, trop loin
local function collect(src) _G.source = src; handlers['gangbuilder:tribute:collect']() end
collect(3); ok(#pay == 0, 'gang adverse refusé')
collect(1); ok(#pay == 0, 'trop loin refusé')
peds[1].pos = { x = 5.5, y = 5.0, z = 30.0 }
peds[1].hp = 0; collect(1); ok(#pay == 0, 'mort refusé')
peds[1].hp = 200; collect(1)
ok(#pay == 1 and pay[1][1] == 'a' and pay[1][2] == 'dirty' and pay[1][3] == 3000, 'tribut versé')
ok(rep[1] and rep[1][2] == 15, 'réputation')
collect(2); ok(#pay == 1, 'pas de double collecte')
ok(GB.startTribute('z1') == true, 'nouvelle zone possible après collecte')
print(('tribute_test : %d vérifications OK'):format(checks))
