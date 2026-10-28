-- Évasion, caution, avocats et juges (natives simulées, prison de pickax_core simulée).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local now = 1700000000
os.time = function() return now end
local cbs, cmds, notes, tele, brace, society, alerts = {}, {}, {}, {}, {}, {}, {}
function CreateThread() end
function Wait() end
function RegisterCommand(n, f) cmds[n] = f end
function RegisterNetEvent() end
function AddEventHandler() end
function SetEntityCoords(ped, x, y, z) tele[#tele + 1] = { ped, x, y, z } end
function GetResourceState() return 'started' end
local peds = { [1] = { 11, { x = 1648.0, y = 2566.0, z = 45.5 } }, [2] = { 12, { x = 1649.0, y = 2566.0, z = 45.5 } }, [3] = { 13, { x = 1650.0, y = 2566.0, z = 45.5 } }, [4] = { 14, { x = 0.0, y = 0.0, z = 0.0 } } }
function GetPlayerPed(s) return peds[s] and peds[s][1] or 0 end
function GetEntityCoords(p) for _, v in pairs(peds) do if v[1] == p then return v[2] end end end
local function mk(id, job, bank) local p = { source = id, identifier = 'id' .. id, job = { name = job }, acc = { bank = bank } }
    p.getAccount = function(n) return { money = p.acc[n] or 0 } end p.removeAccountMoney = function(n, v) p.acc[n] = p.acc[n] - v end p.addAccountMoney = function(n, v) p.acc[n] = (p.acc[n] or 0) + v end return p end
local players = { [1] = mk(1, 'unemployed', 100), [2] = mk(2, 'avocat', 0), [3] = mk(3, 'juge', 0), [4] = mk(4, 'unemployed', 5000) }
ESX = { RegisterServerCallback = function(n, f) cbs[n] = f end, GetPlayerFromId = function(s) return players[tonumber(s)] end }
-- prison simulée
local jail, escapedLeft = {}, nil
local core = { JailTimeLeft = function(_, id) return jail[id] or 0 end, ReduceJail = function(_, id, s) jail[id] = math.max(1, jail[id] - s) return jail[id] end,
    UnjailPlayer = function(_, id) if not jail[id] then return false end jail[id] = nil return true end, EscapePlayer = function(_, id) local l = jail[id] jail[id] = nil return l end }
local jb = { AutoBracelet = function(_, src, job, hours, by, zone) brace[#brace + 1] = { src, job, hours, zone } return true end }
exports = setmetatable({ pickax_core = core, pickax_jobbuilder = jb }, { __call = function() end, __index = function() return {} end })
local items = { lockpick = 1 }
IB = { Escapees = {}, isPoliceJob = function() return false end, playerName = function(x) return x.identifier end, log = function() end, copCount = function() return 0 end,
    notify = function(s, m) notes[#notes + 1] = s .. ':' .. m end, itemCount = function(s, n) return items[n] or 0 end, removeItem = function(s, n) if (items[n] or 0) < 1 then return false end items[n] = items[n] - 1 return true end,
    society = function(n, v) society[#society + 1] = { n, v } end, alertPolice = function(c, t, m) alerts[#alerts + 1] = t end,
    distanceTo = function(s, c) local p = peds[s][2] local dx, dy = p.x - c.x, p.y - c.y return math.sqrt(dx * dx + dy * dy) end }
Config = { Escape = { Enabled = true, Item = 'lockpick', Seconds = 45, MinCops = 0, PenaltyMinutes = 10, ForgetMinutes = 45, Spots = { { label = 'Grillage', coords = { x = 1648.0, y = 2566.0, z = 45.5 } } }, Exit = { x = 1695.0, y = 2535.0, z = 45.6 } },
    Bail = { Enabled = true, PerMinute = 400, MaxMinutes = 30, Account = 'bank', Society = 'society_police', BraceletJob = 'police', BraceletHours = 12, ZoneRadius = 300.0, Exit = { x = 1848.0, y = 2586.0, z = 45.7 } },
    Justice = { Enabled = true, LawyerJobs = { 'avocat' }, JudgeJobs = { 'juge' }, Distance = 6.0, LawyerReducePercent = 25, FeeMin = 100, FeeMax = 20000, OfferSeconds = 60, JudgeMaxPercent = 100, JudgeCooldown = 30 } }
dofile(ROOT .. '/resources/[dev]/pickax_illegalbuilder/server/underworld3.lua')
local function call(name, src, ...) local out; cbs[name](src, function(r) out = r end, ...) return out end

-- ── évasion ──
ok(IB.escapeExtra(600) == 20 and IB.escapeExtra(0) == 10 and IB.escapeExtra(61) == 12, 'peine de reprise : reste (minutes) + pénalité')
ok(call('illegalbuilder:escape:start', 1).error == 'Tu n\'es pas en prison.', 'évasion réservée aux détenus')
jail[1] = 600
peds[1][2] = { x = 1600.0, y = 2566.0, z = 45.5 }
ok(call('illegalbuilder:escape:start', 1).error == 'Aucune issue ici.', 'loin du point d\'évasion : refusé')
peds[1][2] = { x = 1648.0, y = 2566.0, z = 45.5 }
items.lockpick = 0
ok(call('illegalbuilder:escape:start', 1).error:find('Il te faut'), 'objet nécessaire')
items.lockpick = 1
IB.copCount = function() return 0 end Config.Escape.MinCops = 2
ok(call('illegalbuilder:escape:start', 1).error:find('Trop calme'), 'pas assez de policiers connectés')
Config.Escape.MinCops = 0
local r = call('illegalbuilder:escape:start', 1)
ok(r.ok and r.seconds == 45, 'tentative lancée')
ok(call('illegalbuilder:escape:finish', 1).error == 'Trop tôt.', 'terminer trop tôt : refusé (durée vérifiée côté serveur)')
call('illegalbuilder:escape:start', 1)
now = now + 46
peds[1][2] = { x = 1500.0, y = 2566.0, z = 45.5 }
ok(call('illegalbuilder:escape:finish', 1).error:find('bougé'), 'avoir bougé annule la tentative')
peds[1][2] = { x = 1648.0, y = 2566.0, z = 45.5 }
call('illegalbuilder:escape:start', 1) now = now + 46
r = call('illegalbuilder:escape:finish', 1)
ok(r.ok and items.lockpick == 0 and jail[1] == nil and IB.Escapees.id1.left == 600 and tele[#tele][2] == 1695.0 and alerts[#alerts] == 'Évasion !', 'évasion : objet consommé, téléporté dehors, police alertée, reste de peine mémorisé')
-- ── caution ──
ok(IB.bailAmount(600) == 4000 and IB.bailAmount(1800) == 12000 and IB.bailAmount(1900) == 0 and IB.bailAmount(0) == 0, 'caution : 400 $/min, plafonnée à 30 min')
jail[4] = 900
peds[4][2] = { x = 0.0, y = 0.0, z = 0.0 }
cmds.caution(4, { '1' }) ok(notes[#notes]:find('pas en prison'), 'caution : cible hors prison refusée')
jail[2] = 4000
now = now + 10
cmds.caution(1, { '2' }) ok(notes[#notes]:find('trop longue'), 'caution : peine trop longue refusée')
jail[2] = 900
now = now + 10
cmds.caution(1, { '2' }) ok(notes[#notes]:find('La caution est de 6000'), 'caution : fonds insuffisants')
now = now + 10
players[4].acc.bank = 10000
cmds.caution(4, { '2' })
ok(jail[2] == nil and brace[1][1] == 2 and brace[1][2] == 'police' and brace[1][3] == 12 and brace[1][4].r == 300.0 and society[#society][2] == 6000, 'caution payée : libéré sous bracelet, caution à la société')
-- ── avocat ──
jail[1] = 1000 players[1].acc.bank = 5000 IB.Escapees = {}
peds[2][2] = { x = 1648.0, y = 2566.0, z = 45.5 } peds[1][2] = { x = 1649.0, y = 2566.0, z = 45.5 }
cmds.defendre(1, { '1', '500' }) ok(notes[#notes]:find('avocats'), 'plaidoirie réservée aux avocats')
cmds.defendre(2, { '1', '5' }) ok(notes[#notes]:find('Usage'), 'honoraires hors fourchette refusés')
peds[2][2] = { x = 1000.0, y = 2566.0, z = 45.5 }
cmds.defendre(2, { '1', '500' }) ok(notes[#notes]:find('trop loin'), 'avocat trop loin du client')
peds[2][2] = { x = 1648.0, y = 2566.0, z = 45.5 }
cmds.defendre(2, { '1', '500' }) ok(notes[#notes]:find('/accepter'), 'offre envoyée au client')
cmds.accepter(1)
ok(jail[1] == 750 and players[1].acc.bank == 4500 and players[2].acc.bank == 500, 'plaidoirie : -25 % de peine, honoraires versés')
cmds.defendre(2, { '1', '500' }) ok(notes[#notes]:find('déjà eu lieu'), 'une seule plaidoirie par peine')
cmds.accepter(1) -- pas d'offre : rien ne se passe
ok(players[1].acc.bank == 4500, 'pas d\'offre : rien n\'est prélevé')
-- offre expirée
jail[3] = 800 players[3].acc.bank = 1000 peds[3][2] = { x = 1648.0, y = 2566.0, z = 45.5 }
cmds.defendre(2, { '3', '300' }) now = now + 120 cmds.accepter(3)
ok(jail[3] == 800 and notes[#notes]:find('expiré'), 'offre expirée : refusée')
-- ── juge ──
cmds.gracier(1, { '3' }) ok(notes[#notes]:find('juges'), 'grâce réservée aux juges')
now = now + 40
cmds.gracier(3, { '3', '50' })
ok(jail[3] == 400, 'grâce partielle : 50 % effacés')
cmds.gracier(3, { '3', '100' }) ok(notes[#notes]:find('Patiente'), 'délai entre deux décisions')
now = now + 40
cmds.gracier(3, { '3', '100' }) ok(jail[3] == nil, 'grâce totale : libéré')
print(('justice_test : %d vérifications OK'):format(checks))
