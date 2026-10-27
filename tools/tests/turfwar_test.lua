-- Guerre de zone déclarée : conditions, préparation puis points (natives simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local now, handlers, threads, notes = 5000, {}, {}, {}
os.time = function() return now end
function Wait() end
function CreateThread(f) threads[#threads + 1] = f end
function RegisterNetEvent(n, f) handlers[n] = f end
function AddEventHandler() end
function RegisterCommand() end
function exports() end
function TriggerClientEvent() end
local peds = {}
function GetPlayerPed(src) return peds[src] and peds[src].ped or 0 end
function GetEntityCoords(ped) for _, p in pairs(peds) do if p.ped == ped then return p.pos end end end
ESX = { GetPlayerFromId = function() return {} end }
Config = { Rep = { Enabled = true }, Territories = { Enabled = true }, Conflicts = { Enabled = true, Kinds = {}, Duration = 300, Cooldown = 900, WinnerCaptures = true, MinKillsToWin = 1, RepWin = 20, RepLoss = 0, AlertBlipSeconds = 90 },
    TurfWar = { Enabled = true, PrepSeconds = 120, Duration = 600, MinAttackers = 2, MinDefenders = 1, Cooldown = 1800, MinKillsToWin = 1, RepWin = 30, RepLoss = 10 } }
local captured, reps = nil, {}
GB = { Gangs = { a = { label = 'A' }, b = { label = 'B' } }, PlayerGang = {}, Territories = {}, isDev = function() return true end,
    notify = function(s, m) notes[#notes + 1] = m end, log = function() end, news = function() end, addRep = function(n, v) reps[#reps + 1] = { n, v } end,
    questProgress = function() end, canCapture = function() return true end, captureTerritory = function(t, g) captured = { t.id, g } t.owner = g end,
    onlineMembers = function(n) local l = {} for s, g in pairs(GB.PlayerGang) do if g.name == n then l[#l + 1] = s end end return l end }
GB.Territories[1] = { id = 1, label = 'Davis', owner = 'b', coords = { x = 0.0, y = 0.0, z = 30.0 }, radius = 50.0, protected_until = 0 }
GB.PlayerGang = { [1] = { name = 'a' }, [2] = { name = 'a' }, [3] = { name = 'b' } }
peds = { [1] = { ped = 11, pos = { x = 1.0, y = 1.0, z = 30.0 } }, [3] = { ped = 13, pos = { x = 2.0, y = 2.0, z = 30.0 } } }
MySQL = { update = function() end }
dofile(ROOT .. '/resources/[dev]/pickax_gangbuilder/server/conflicts.lua')
local t = GB.Territories[1]

ok(select(2, GB.turfCheck(t, 'b')) == 'own', 'propre territoire')
ok(select(2, GB.turfCheck({ id = 9, owner = nil }, 'a')) == 'noowner', 'sans propriétaire')
t.protected_until = now + 100
ok(select(2, GB.turfCheck(t, 'a')) == 'prot', 'protégé')
t.protected_until = 0
GB.PlayerGang[2] = nil
ok(select(2, GB.turfCheck(t, 'a')) == 'att', 'pas assez d\'attaquants')
GB.PlayerGang[2] = { name = 'a' }
GB.PlayerGang[3] = nil
ok(select(2, GB.turfCheck(t, 'a')) == 'def', 'aucun défenseur')
GB.PlayerGang[3] = { name = 'b' }
ok(GB.turfCheck(t, 'a') == true, 'conditions réunies')

ok(GB.startTurfWar(1, 1, 'a') == true, 'déclaration')
ok(select(2, GB.turfCheck(t, 'a')) == 'busy', 'une guerre à la fois')
ok(GB.conflictInfo(1).prep == 120 and GB.conflictInfo(1).declared, 'préparation 120 s')

-- kill pendant la préparation : ignoré
local function kill(victim, killer, vpos, kpos)
    peds[victim] = { ped = 100 + victim, pos = vpos }; peds[killer] = { ped = 100 + killer, pos = kpos }
    _G.source = victim; now = now + 11
    handlers['esx:onPlayerDeath']({ killedByPlayer = true, killerServerId = killer })
end
local inside = { x = 3.0, y = 3.0, z = 30.0 }
kill(3, 1, inside, inside)
ok(GB.conflictInfo(1).intruder == 0, 'kill ignoré avant le début')
now = now + 130
kill(3, 1, inside, inside)
ok(GB.conflictInfo(1).intruder == 1, 'kill compté après la préparation')

-- fin : l'attaquant gagne → capture + réputation 30
now = now + 700
local loop = threads[#threads]
local STOP = {}
Wait = function() error(STOP) end
-- la boucle fait Wait() en début de tour : on la fait avancer un tour en remplaçant Wait par un compteur
local n = 0
Wait = function() n = n + 1 if n > 2 then error(STOP) end end
for _, th in ipairs(threads) do n = 0 pcall(th) end
ok(captured and captured[2] == 'a', 'capture par le gagnant')
ok(reps[1] and reps[1][1] == 'a' and reps[1][2] == 30, 'réputation de guerre de zone')
ok(GB.conflictInfo(1) == nil, 'guerre terminée')
ok(select(2, GB.turfCheck(t, 'a')) ~= 'busy', 'plus en cours')
print(('turfwar_test : %d vérifications OK'):format(checks))
