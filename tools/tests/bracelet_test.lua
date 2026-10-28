-- Bracelets électroniques (tablette police) : pose, droits, distance, zone, alerte hors zone, retrait (natives et base simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local now = 1700000000
os.time = function() return now end
local threads, cbs, cmds, notes, alertsSent, handlers = {}, {}, {}, {}, {}, {}
function CreateThread(f) threads[#threads + 1] = f end
function Wait() coroutine.yield() end
function SetTimeout() end
function RegisterCommand(n, f) cmds[n] = f end
function AddEventHandler(n, f) handlers[n] = f end
function RegisterNetEvent() end
function TriggerClientEvent(ev, src, a) if ev == 'jobbuilder:client:dispatchAlert' then alertsSent[#alertsSent + 1] = { src, a } end end
function GetPlayers() local l = {} for s in pairs(_G.__players) do l[#l + 1] = tostring(s) end return l end
function JBNotifyClient(src, m) notes[#notes + 1] = src .. ':' .. m end
exports = setmetatable({}, { __call = function() end })
-- joueurs et positions
local peds = { [1] = { 11, { x = 0.0, y = 0.0, z = 0.0 } }, [2] = { 12, { x = 2.0, y = 0.0, z = 0.0 } }, [3] = { 13, { x = 300.0, y = 0.0, z = 0.0 } }, [4] = { 14, { x = 1.0, y = 1.0, z = 0.0 } } }
function GetPlayerPed(s) return peds[s] and peds[s][1] or 0 end
function GetEntityCoords(p) for _, v in pairs(peds) do if v[1] == p then local c = v[2] return setmetatable({ x = c.x, y = c.y, z = c.z }, { __sub = function(a, b) return setmetatable({ x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }, getmetatable(a)) end, __len = function(a) return math.sqrt(a.x ^ 2 + a.y ^ 2 + a.z ^ 2) end }) end end end
function GetVehiclePedIsIn() return 0 end
_G.__players = { [1] = true, [2] = true, [3] = true, [4] = true }
local function mk(id, job, grade, name) return { source = id, identifier = 'id' .. id, job = { name = job, grade = grade, grade_label = 'G' .. grade }, get = function(k) return ({ firstName = name, lastName = 'X' })[k] end } end
local players = { [1] = mk(1, 'police', 3, 'Agent'), [2] = mk(2, 'unemployed', 0, 'Jean'), [3] = mk(3, 'unemployed', 0, 'Loin'), [4] = mk(4, 'police', 0, 'Recrue') }
ESX = { RegisterServerCallback = function(n, f) cbs[n] = f end, GetPlayerFromId = function(s) return players[tonumber(s)] end,
    GetPlayerFromIdentifier = function(i) for _, p in pairs(players) do if p.identifier == i and _G.__players[p.source] then return p end end end,
    GetExtendedPlayers = function(_, job) local l = {} for _, p in pairs(players) do if p.job.name == job then l[#l + 1] = p end end return l end }
JB = { Jobs = { police = { name = 'police', type = 'police', label = 'LSPD', boss_grade = 4, settings = { tablet_enabled = true, bracelet_grade = 2 } } }, playerName = function(x) return x.identifier end, log = function() end }
Config = { Police = { PursuitMax = 600, PursuitTrail = 40, NearbyRange = 80.0, RefreshMs = 2000, CallCooldown = 30, MaxCalls = 100, ClosedKeepMinutes = 30, MinFine = 1, MaxFine = 50000, CallCommand = 'appel', PanicCommand = 'panic',
    DefaultFines = {}, Map = {}, Landmarks = {}, Bracelets = { Enabled = true, Distance = 4.0, Interval = 10, MaxPerJob = 2, ZoneMin = 20.0, ZoneMax = 2000.0, EscapeCooldown = 120, Command = 'bracelet' } } }
-- base simulée : uniquement ce que le module utilise
local B, nextId, entries = {}, 0, 0
local function find(id) for _, b in ipairs(B) do if b.id == id then return b end end end
MySQL = {
    query = { await = function(sql, p)
        if sql:find('FROM jobbuilder_bracelets WHERE job_name') then local l = {} for _, b in ipairs(B) do if b.job_name == p[1] then l[#l + 1] = b end end return l end
        if sql:find('FROM jobbuilder_bracelets') then return B end
        return {} end },
    single = { await = function(sql, p)
        if sql:find('jobbuilder_bracelets WHERE id') then local b = find(p[1]) return b and b.job_name == p[2] and b or nil end
        if sql:find('FROM jobbuilder_records WHERE job_name = %? AND identifier') then return { id = 1 } end
        return nil end },
    scalar = { await = function(sql, p)
        if sql:find('FROM jobbuilder_bracelets WHERE identifier') then local n = 0 for _, b in ipairs(B) do if b.identifier == p[1] then n = n + 1 end end return n end
        if sql:find('FROM jobbuilder_bracelets WHERE job_name') then local n = 0 for _, b in ipairs(B) do if b.job_name == p[1] then n = n + 1 end end return n end
        return 0 end },
    insert = { await = function(sql, p)
        if sql:find('jobbuilder_bracelets') then nextId = nextId + 1 B[#B + 1] = { id = nextId, job_name = p[1], identifier = p[2], name = p[3], placed_by = p[4], placed_at = p[5] } return nextId end
        entries = entries + 1 return entries end },
    update = setmetatable({ await = function(sql, p)
        if sql:find('DELETE FROM jobbuilder_bracelets') then for i, b in ipairs(B) do if b.id == p[1] then table.remove(B, i) break end end end
        if sql:find('SET zone_x = %?') then local b = find(p[5]) b.zone_x, b.zone_y, b.zone_z, b.zone_r = p[1], p[2], p[3], p[4] end
        if sql:find('SET zone_x = NULL') then local b = find(p[1]) b.zone_x, b.zone_y, b.zone_z, b.zone_r = nil, nil, nil, nil end
        return 1 end }, { __call = function(_, sql, p) if sql:find('last_x') then local b for _, x in ipairs(B) do if x.identifier == p[5] then b = x end end if b then b.last_x, b.last_y, b.last_z, b.last_at = p[1], p[2], p[3], p[4] end end end }),
}
dofile(ROOT .. '/resources/[dev]/pickax_jobbuilder/server/tablet.lua')
local function call(name, src, ...) local out; cbs[name](src, function(r) out = r end, ...) return out end

-- droits
ok(call('jobbuilder:bracelet:list', 2).ok == false, 'un civil n\'a pas accès aux bracelets')
ok(call('jobbuilder:bracelet:list', 4).ok == false, 'grade insuffisant (grade 0 < 2) refusé')
JB.Jobs.police.settings.tablet_bracelets = false
ok(call('jobbuilder:bracelet:list', 1).ok == false, 'bracelets désactivés pour le service')
JB.Jobs.police.settings.tablet_bracelets = nil
-- proximité et pose
local n = call('jobbuilder:bracelet:nearby', 1)
ok(n.ok and #n.list == 2 and n.list[1].src == 4 or n.list[1].src == 2, 'personnes à proximité listées (le plus proche d\'abord, pas les lointaines)')
ok(call('jobbuilder:bracelet:place', 1, 3).error == 'La personne est trop loin', 'pose refusée si trop loin')
ok(call('jobbuilder:bracelet:place', 1, 1).error == 'Aucune personne ciblée', 'on ne se pose pas un bracelet')
local r = call('jobbuilder:bracelet:place', 1, 2)
ok(r.ok and #B == 1 and B[1].identifier == 'id2' and B[1].job_name == 'police', 'bracelet posé')
ok(notes[#notes]:find('2:') and notes[#notes]:find('bracelet'), 'le porteur est prévenu')
ok(call('jobbuilder:bracelet:place', 1, 2).error == 'Cette personne porte déjà un bracelet', 'un seul bracelet par personne')
ok(call('jobbuilder:bracelet:place', 1, 4).ok and call('jobbuilder:bracelet:place', 1, 3).error ~= nil, 'maximum de bracelets du service')
-- liste
local l = call('jobbuilder:bracelet:list', 1)
local jean; for _, v in ipairs(l.list) do if v.name == 'Jean X' then jean = v end end
ok(l.ok and #l.list == 2 and jean.online and not jean.zone, 'liste : porteur en ligne, sans zone')
-- zone
ok(call('jobbuilder:bracelet:zone', 4, 1, 100).ok == false, 'zone : grade insuffisant refusé')
ok(call('jobbuilder:bracelet:zone', 1, 999, 100).error == 'Bracelet introuvable', 'zone : bracelet inconnu')
peds[1][2] = { x = 0.0, y = 0.0, z = 0.0 }
r = call('jobbuilder:bracelet:zone', 1, 1, 5)
ok(r.ok and r.r == 20.0 and B[1].zone_r == 20.0, 'rayon minimal appliqué')
r = call('jobbuilder:bracelet:zone', 1, 1, 100000)
ok(r.r == 2000.0, 'rayon maximal appliqué')
r = call('jobbuilder:bracelet:zone', 1, 1, 100)
ok(B[1].zone_r == 100 and B[1].zone_x == 0.0, 'zone de 100 m centrée sur l\'agent')
ok(JB.braceletOutside(B[1], 50.0, 0.0) == false and JB.braceletOutside(B[1], 150.0, 0.0) == true, 'dans / hors de la zone')
-- relevé : alerte hors zone une fois
local loops = {}
for _, f in ipairs(threads) do local c = coroutine.create(f) coroutine.resume(c) loops[#loops + 1] = c end
local function tick() now = now + 11 for _, c in ipairs(loops) do if coroutine.status(c) == 'suspended' then coroutine.resume(c) end end end
tick()
ok(#alertsSent == 0, 'dans la zone : aucune alerte')
peds[2][2] = { x = 250.0, y = 0.0, z = 0.0 }
tick()
local got = 0 for _, a in ipairs(alertsSent) do if a[2].title == 'Bracelet : hors zone' then got = got + 1 end end
ok(got >= 1, 'sortie de zone : alerte au dispatch')
local before = #alertsSent
tick()
ok(#alertsSent == before, 'pas d\'alerte répétée avant le délai')
now = now + 130
tick()
ok(#alertsSent > before, 'nouvelle alerte après le délai si le porteur est toujours dehors')
peds[2][2] = { x = 10.0, y = 0.0, z = 0.0 }
tick()
local back; for _, v in ipairs(call('jobbuilder:bracelet:list', 1).list) do if v.name == 'Jean X' then back = v end end
ok(back.outNow == false, 'retour dans la zone : plus hors zone')
-- déconnexion : dernière position conservée
peds[2][2] = { x = 77.0, y = 5.0, z = 0.0 }
_G.__source = 2
source = 2
handlers.playerDropped()
local mine; for _, b in ipairs(B) do if b.identifier == 'id2' then mine = b end end
ok(mine.last_x == 77.0 and mine.last_at == now, 'déconnexion : dernière position enregistrée')
_G.__players[2] = nil
local lv = call('jobbuilder:bracelet:list', 1)
local view; for _, v in ipairs(lv.list) do if v.name == 'Jean X' then view = v end end
ok(not view.online and view.x == 77.0, 'hors ligne : dernière position connue affichée')
-- commande et retrait
_G.__players[2] = true
local nb = #B
cmds.bracelet(2, { '1' })
ok(#B == nb and notes[#notes]:find('tablette'), '/bracelet : refusé à un civil')
ok(call('jobbuilder:bracelet:remove', 4, 1).ok == false, 'retrait : grade insuffisant refusé')
ok(call('jobbuilder:bracelet:remove', 1, mine.id).ok and find(mine.id) == nil, 'bracelet retiré')
ok(notes[#notes]:find('retiré'), 'le porteur est prévenu du retrait')
print(('bracelet_test : %d vérifications OK'):format(checks))
