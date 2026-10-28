-- Équipes de braquage : création, invitations, rôles, bonus appliqués au braquage (natives simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local now = 1700000000
os.time = function() return now end
local threads, cmds, cbs, evs, notes, alerts = {}, {}, {}, {}, {}, 0
function CreateThread(f) threads[#threads + 1] = f end
function Wait() end
function RegisterCommand(n, f) cmds[n] = f end
function RegisterNetEvent(n, f) if f then evs[n] = f end end
function AddEventHandler(n, f) evs[n] = evs[n] or f end
function TriggerClientEvent() end
function GetGameTimer() return 1000 end
function GetSelectedPedWeapon() return 1 end
function GetPlayers() return { '1', '2', '3' } end
function GetPlayerName(s) return 'P' .. s end
local VM = {} VM.__index = VM
VM.__sub = function(a, b) return setmetatable({ x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }, VM) end
VM.__len = function(a) return math.sqrt(a.x ^ 2 + a.y ^ 2 + a.z ^ 2) end
function vector3(x, y, z) return setmetatable({ x = x, y = y, z = z }, VM) end
local pos = { [1] = vector3(0, 0, 0), [2] = vector3(3, 0, 0), [3] = vector3(500, 0, 0) }
function GetPlayerPed(s) return s end
function GetEntityCoords(p) return pos[p] end
local function mk(id, job) return { source = id, identifier = 'id' .. id, job = { name = job }, acc = {} } end
local players = { [1] = mk(1, 'unemployed'), [2] = mk(2, 'unemployed'), [3] = mk(3, 'police') }
ESX = { RegisterServerCallback = function(n, f) cbs[n] = f end, GetPlayerFromId = function(s) return players[s] end }
local paid, items, started = 0, {}, {}
IB = { Entities = {}, State = {}, Pending = {}, notify = function(s, m) notes[#notes + 1] = s .. ':' .. m end, playerName = function(x) return x.identifier end, log = function() end, stat = function() end,
    isPoliceJob = function(n) return n == 'police' end, copCount = function() return 0 end, itemCount = function() return 99 end, removeItem = function() return true end, addItem = function(s, it, n) items[#items + 1] = { it, n } return true end,
    near = function() return true end, hasAccess = function() return true end, setState = function(k, v) IB.State[k] = v end, pay = function(x, acc, amount) paid = paid + amount end,
    alertPolice = function() alerts = alerts + 1 end,
    distanceTo = function(s, c) local p = pos[s] local dx, dy = p.x - c.x, p.y - c.y return math.sqrt(dx * dx + dy * dy) end,
    beginAct = function(s, d, sec) IB.Pending[s] = { d = d, sec = sec } started.sec = sec end,
    endAct = function(s, kind) local p = IB.Pending[s] IB.Pending[s] = nil return p and p.d or nil end }
Config = { Currency = '$', Crew = { Enabled = true, Command = 'equipe', MaxMembers = 3, InviteDistance = 8.0, MinTimeMul = 0.5, MaxLoot = 40, MaxAlert = 60,
    Roles = { pirate = { label = 'Pirate', timeMul = 0.7 }, tireur = { label = 'Tireur', loot = 10 }, conducteur = { label = 'Conducteur', alert = 20 }, guetteur = { label = 'Guetteur', alert = 10, duration = 60 } } } }
dofile(ROOT .. '/resources/[dev]/pickax_illegalbuilder/server/crew.lua')
dofile(ROOT .. '/resources/[dev]/pickax_illegalbuilder/server/robbery.lua')

-- bonus
local m = IB.crewMods({ 'pirate', 'tireur', 'conducteur', 'guetteur' })
ok(math.abs(m.timeMul - 0.7) < 1e-9 and m.loot == 10 and m.alert == 30 and m.duration == 60, 'bonus cumulés des rôles')
ok(IB.crewMods({ 'pirate', 'pirate' }).timeMul == 0.7, 'un même rôle ne s\'empile pas')
Config.Crew.Roles.pirate.timeMul = 0.1
ok(IB.crewMods({ 'pirate' }).timeMul == 0.5, 'plafond : durée minimale ×0,5')
Config.Crew.Roles.pirate.timeMul = 0.7
ok(IB.crewMods({}).timeMul == 1.0 and IB.crewMods(nil).loot == 0, 'aucun rôle : aucun bonus')
-- équipe
cmds.equipe(1, { 'creer' }) ok(IB.crewOf(1) ~= nil, 'équipe créée')
cmds.equipe(1, { 'creer' }) ok(notes[#notes]:find('déjà'), 'pas deux équipes')
cmds.equipe(2, { 'inviter', '1' }) ok(notes[#notes]:find('Seul le chef'), 'seul le chef invite')
cmds.equipe(1, { 'inviter', '3' }) ok(notes[#notes]:find('invalide'), 'on n\'invite pas un policier')
cmds.equipe(1, { 'inviter', '2' }) cmds.equipe(2, { 'accepter' })
ok(IB.crewOf(2) == IB.crewOf(1), 'invitation acceptée')
cmds.equipe(2, { 'accepter' }) ok(notes[#notes]:find('Aucune invitation') or notes[#notes]:find('déjà'), 'plus d\'invitation')
cmds.equipe(1, { 'role', 'pirate' }) cmds.equipe(2, { 'role', 'pirate' }) ok(notes[#notes]:find('déjà pris'), 'un rôle par personne')
cmds.equipe(2, { 'role', 'tireur' })
local roles, n = IB.crewRolesNear(1, 40)
ok(n == 2 and #roles == 2, 'membres présents sur place comptés avec leurs rôles')
pos[2] = vector3(300, 0, 0)
roles, n = IB.crewRolesNear(1, 40) ok(n == 1 and #roles == 1, 'un membre trop loin ne compte pas')
pos[2] = vector3(3, 0, 0)
-- braquage : bonus appliqués
local e = { id = 1, type = 'robbery', enabled = true, label = 'Banque', settings = { trigger = 'clerk', duration = 240, cooldown = 0, coop = true, alert = { chance = 25 } },
    points = { { kind = 'clerk', coords = { x = 0, y = 0, z = 0 } }, { kind = 'vault', coords = { x = 1, y = 0, z = 0 }, time = 20, cash = { min = 1000, max = 1000 }, items = { { item = 'gold', min = 10, max = 10, chance = 100 } } } } }
IB.Entities[1] = e
local r; cbs['illegalbuilder:rob:start'](1, function(x) r = x end, 1, 1)
ok(r.ok, 'braquage démarré avec une équipe')
cbs['illegalbuilder:rob:begin'](1, function(x) r = x end, 1, 2)
ok(r.ok and r.seconds == 14, 'chambre forte : 20 s × 0,7 = 14 s avec un pirate')
cbs['illegalbuilder:rob:begin'](2, function(x) r = x end, 1, 2)
source = 1
evs['illegalbuilder:server:robFinish'](true)
ok(paid == 1100 and items[#items][2] == 11, 'butin +10 % (tireur) : 1 100 $ et 11 lingots')
cmds.equipe(1, { 'quitter' }) cmds.equipe(2, { 'quitter' })
ok(IB.crewOf(1) == nil, 'équipe dissoute quand tout le monde part')
print(('crew_test : %d vérifications OK'):format(checks))
