-- Teste la logique des territoires (niveaux, équité, racket) hors du jeu : lua5.4 tools/tests/territories_test.lua
local root = (arg[0]:match('^(.*)tools/tests/') or './') .. 'resources/[dev]/pickax_gangbuilder/'
local n, fails = 0, 0
local function ok(c, m) n = n + 1 if c then print('  ✓ ' .. m) else fails = fails + 1 print('  ✗ ' .. m) end end

-- ── simulation de l'environnement FiveM ──
PickaxTheme = nil
function IsDuplicityVersion() return true end
function vector3(x, y, z) return { x = x, y = y, z = z } end
vector2 = vector3; vector4 = vector3
Config = {} ; dofile(root .. 'config.lua')
local callbacks, events, notes, logs, treasury, sql = {}, {}, {}, {}, { alpha = { money = 0, dirty = 100000 }, beta = { money = 0, dirty = 100000 } }, {}
json = { encode = function() return '{}' end }
MySQL = { update = setmetatable({ await = function(q, a) sql[#sql + 1] = { q, a } return 1 end }, { __call = function(_, q, a) sql[#sql + 1] = { q, a } end }), query = { await = function() return {} end }, insert = { await = function() return 1 end }, scalar = { await = function() return 1 end } }
ESX = { RegisterServerCallback = function(name, f) callbacks[name] = f end, GetPlayerFromId = function() return { identifier = 'x' } end }
local players = {}   -- [src] = { x, y, z, hp }
function GetPlayerPed(src) return players[src] and src or 0 end
function GetEntityCoords(ped) local p = players[ped] return { x = p.x, y = p.y, z = p.z } end
function GetEntityHealth(ped) return players[ped].hp or 200 end
function TriggerClientEvent(ev, src, d) events[#events + 1] = { ev = ev, src = src, d = d } end
local threads, waits = {}, 0
function CreateThread(f) threads[#threads + 1] = f end
function Wait() waits = waits + 1 if waits > 1 then error('STOP') end end
exports = setmetatable({}, { __call = function(t, name, f) rawset(t, name, f) end })
GB = { ready = true, Territories = {}, Gangs = {}, PlayerGang = {}, count = function(t) local c = 0 for _ in pairs(t) do c = c + 1 end return c end }
GB.Gangs.alpha = { name = 'alpha', label = 'Alpha', color = '#ff0000', boss_grade = 3, settings = {}, blip = { color = 1 } }
GB.Gangs.beta = { name = 'beta', label = 'Beta', color = '#0000ff', boss_grade = 3, settings = {}, blip = { color = 3 } }
function GB.onlineMembers(g) local l = {} for s, v in pairs(GB.PlayerGang) do if v.name == g then l[#l + 1] = s end end return l end
function GB.notify(src, m) notes[#notes + 1] = { src, m } end
function GB.log(g, x, a, d) logs[#logs + 1] = a .. ' ' .. tostring(d) end
function GB.treasuryAdd(g, k, a) treasury[g][k] = treasury[g][k] + a return true end
function GB.treasuryRemove(g, k, a) if treasury[g][k] < a then return false end treasury[g][k] = treasury[g][k] - a return true end
function GB.addRep() end
function GB.gangOf(src) local v = GB.PlayerGang[src] return GB.Gangs[v.name], v.grade, { identifier = 'x' } end
function GB.isDev() return true end
function GB.decode(v, d) return d end
GB.news = function() end
dofile(root .. 'server/territories.lua')
local T = Config.Territories
local nextId, cur = 0, 1
local function terr(over) nextId = nextId + 1 cur = (over and over.id) or nextId local t = { id = cur, name = 't' .. cur, label = 'Zone 1', coords = { x = 0, y = 0, z = 0 }, radius = 50, settings = {}, owner = 'alpha', protected_until = 0, level = 1, last_income = 0 } for k, v in pairs(over or {}) do t[k] = v end GB.Territories = { [cur] = t } return t end
local function put(src, gang, x, grade) players[src] = { x = x or 0, y = 0, z = 0, hp = 200 } GB.PlayerGang[src] = { name = gang, grade = grade or 0 } end
local function reset() players, GB.PlayerGang, notes, events, logs, sql = {}, {}, {}, {}, {}, {} GB._tick_reset = true end

print('Équité')
T.MinDefenders, T.MaxPerGang, T.Windows = 1, 0, {}
terr(); reset()
ok(select(2, GB.canCapture(GB.Territories[cur], 'beta')) == 'nodef', 'aucun défenseur connecté : capture impossible')
put(10, 'alpha', 500); ok(GB.canCapture(GB.Territories[cur], 'beta') == true, 'un défenseur connecté : capture possible')
T.MinDefenders = 0; reset(); ok(GB.canCapture(GB.Territories[cur], 'beta') == true, 'MinDefenders = 0 : aucune condition')
local realDate = os.date
os.date = function(f) if f == '%H' then return '03' end return realDate(f) end
T.Windows = { { 18, 23 } }; ok(select(2, GB.canCapture(GB.Territories[cur], 'beta')) == 'closed', 'hors de la fenêtre 18h-23h (il est 3h) : fermé')
os.date = function(f) if f == '%H' then return '20' end return realDate(f) end; ok(GB.canCapture(GB.Territories[cur], 'beta') == true, 'dans la fenêtre (20h) : ouvert')
os.date = function(f) if f == '%H' then return '23' end return realDate(f) end; ok(select(2, GB.canCapture(GB.Territories[cur], 'beta')) == 'closed', 'l’heure de fin est exclue (23h)')
T.Windows = { { 22, 2 } }; os.date = function(f) if f == '%H' then return '1' end return realDate(f) end; ok(GB.canCapture(GB.Territories[cur], 'beta') == true, 'fenêtre qui passe minuit (22h-2h) : 1h ouvert')
os.date = function(f) if f == '%H' then return '12' end return realDate(f) end; ok(select(2, GB.canCapture(GB.Territories[cur], 'beta')) == 'closed', 'fenêtre 22h-2h : 12h fermé')
os.date = realDate; T.Windows = {}
T.MaxPerGang = 1; local free = terr({ owner = false }); GB.Territories = { [cur] = free, [9999] = { id = 9999, owner = 'beta', coords = { x = 9, y = 9, z = 0 }, radius = 10 } }
ok(select(2, GB.canCapture(GB.Territories[cur], 'beta')) == 'cap', 'plafond atteint (1 territoire max) : refusé')
ok(GB.canCapture(GB.Territories[cur], 'alpha') == true, 'un autre gang sans territoire peut capturer')
T.MaxPerGang = 0

print('Capture et niveaux')
T.MinDefenders = 0; T.CaptureSeconds, T.Tick, T.ProtectionMinutes, T.LevelLoss = 100, 1, 30, 1
local t = terr({ level = 3 }); reset(); put(20, 'beta', 5, 0); put(21, 'alpha', 400)   -- un rival dans la zone, un défenseur hors zone
GB._tick() ; local st1 = GB.territoryStatus(cur).progress
ok(math.abs(st1 - 100 / (100 * 1.5)) < 1e-6, 'niveau 3 : la capture est 1,5 × plus lente (' .. string.format('%.2f', st1) .. ' % par seconde)')
t = terr({ level = 1 }); reset(); put(20, 'beta', 5, 0); GB._tick()
ok(math.abs(GB.territoryStatus(cur).progress - 1.0) < 1e-6, 'niveau 1 : vitesse de base (1 % par seconde)')
for _ = 1, 99 do GB._tick() end
ok(GB.Territories[cur].owner == 'beta', 'capturé après 100 s')
ok(GB.Territories[cur].level == 1, 'niveau 1 reste à 1 (jamais en dessous)')
local before = os.time()
t = terr({ level = 3 }); reset(); put(20, 'beta', 5, 0); GB.captureTerritory(t, 'beta')
ok(t.level == 2 and t.owner == 'beta', 'la capture fait perdre un niveau (3 → 2)')
ok(t.protected_until - before >= 30 * 60 * 1.5 - 2 and t.protected_until - before <= 30 * 60 * 1.5 + 2, 'protection = 30 min × 1,5 (multiplicateur du niveau 2 atteint après la perte)')
local saved = false for _, q in ipairs(sql) do if q[1]:find('level = %?') and q[2][5] == 2 then saved = true end end ok(saved, 'le nouveau niveau est enregistré en base')
T.LevelLoss = 0; t = terr({ level = 3 }); reset(); GB.captureTerritory(t, 'beta'); ok(t.level == 3, 'LevelLoss = 0 : le niveau est conservé')
T.LevelLoss = 1

print('Capture bloquée')
T.MinDefenders = 1; t = terr({ level = 1 }); reset(); put(20, 'beta', 5, 0)
GB._tick(); ok(GB.territoryStatus(cur).progress == 0, 'sans défenseur connecté : la barre ne monte pas')
local hud; for _, e in ipairs(events) do if e.ev == 'gangbuilder:client:zone' and e.src == 20 then hud = e.d end end
ok(hud and hud.status == 'nodef' and hud.level == 1, 'le HUD indique « nodef » et le niveau')
put(21, 'alpha', 400); GB._tick(); ok(GB.territoryStatus(cur).progress > 0, 'un défenseur se connecte : la capture démarre')
players[21] = nil; GB.PlayerGang[21] = nil; local p0 = GB.territoryStatus(cur).progress; GB._tick()
ok(GB.territoryStatus(cur).progress < p0, 'le dernier défenseur se déconnecte : la barre redescend')
T.MinDefenders = 0

print('Améliorations')
treasury.alpha.dirty = 20000; t = terr({ level = 1 }); reset(); put(30, 'alpha', 900, 1)
local function call(src, id) local r callbacks['gangbuilder:tablet:terrUpgrade'](src, function(x) r = x end, id) return r end
ok(call(30, cur).error == 'Réservé au bureau du gang', 'un membre hors bureau ne peut pas améliorer')
put(31, 'alpha', 900, 3); local r = call(31, cur)
ok(r.ok and r.level == 2 and treasury.alpha.dirty == 5000, 'le bureau améliore : niveau 2, 15 000 $ prélevés de la trésorerie')
ok(call(31, cur).error:find('insuffisante'), 'trésorerie insuffisante pour le niveau 3 (5 000 $ < 40 000 $)')
treasury.alpha.dirty = 100000; r = call(31, cur); ok(r.ok and r.level == 3 and treasury.alpha.dirty == 60000, 'niveau 3 atteint')
ok(call(31, cur).error == 'Niveau maximum atteint', 'niveau maximum : refusé')
put(32, 'beta', 900, 3); ok(call(32, cur).error == 'Ce territoire n\'est pas à vous', 'un autre gang ne peut pas améliorer')
t = terr({ level = 1 }); GB.territoryStatus(cur); GB._tick(); GB.Territories[cur].level = 1; put(40, 'beta', 5, 0); put(41, 'alpha', 400, 3); treasury.alpha.dirty = 50000; GB._tick()
ok(call(41, cur).error == 'Impossible pendant une attaque', 'pas d’amélioration pendant une attaque')
t = terr({ level = 1 }); reset(); put(31, 'alpha', 900, 3); treasury.alpha.dirty = 15000; local first, second
callbacks['gangbuilder:tablet:terrUpgrade'](31, function(x) first = x end, cur)
ok(first and first.ok and treasury.alpha.dirty == 0, 'paiement exact, trésorerie à 0')

print('Revenus')
T.Reward, T.IncomeInterval, T.RewardAccount = 500, 15, 'dirty'
local function runThreads() for _, f in ipairs(threads) do waits = 0 pcall(f) end end
t = terr({ level = 3, last_income = os.time() - 16 * 60 }); reset(); treasury.alpha.dirty = 0; runThreads()
ok(treasury.alpha.dirty == 1000, 'niveau 3 : revenu ×2 (500 $ → 1 000 $) à l’échéance')
t = terr({ level = 1, last_income = os.time() - 16 * 60 }); treasury.alpha.dirty = 0; runThreads()
ok(treasury.alpha.dirty == 500, 'niveau 1 : revenu de base (500 $)')
t = terr({ level = 3, last_income = os.time() - 5 * 60 }); treasury.alpha.dirty = 0; runThreads()
ok(treasury.alpha.dirty == 0, 'avant l’échéance : rien n’est versé')

print('Racket')
T.RacketEnabled, T.RacketRate, T.RacketAccount = true, 10, 'dirty'
t = terr({ level = 1 }); reset(); put(50, 'beta', 5, 0); treasury.alpha.dirty = 0; notes = {}
local tax = exports.TerritoryTax(50, 1000, 'vente')
ok(tax == 100 and treasury.alpha.dirty == 100, 'vente de 1 000 $ chez un rival : 10 % (100 $) pour le propriétaire')
put(51, 'alpha', 5, 0); ok(exports.TerritoryTax(51, 1000, 'vente') == 0, 'un membre du gang propriétaire ne paie rien')
players[52] = { x = 3000, y = 0, z = 0, hp = 200 }; GB.PlayerGang[52] = { name = 'beta', grade = 0 }; ok(exports.TerritoryTax(52, 1000, 'vente') == 0, 'hors du territoire : pas de taxe')
t.level = 3; treasury.alpha.dirty = 0; ok(exports.TerritoryTax(50, 1000, 'vente') == 150, 'niveau 3 : racket × 1,5 (15 %)')
t.level = 1; T.RacketRate = 500; ok(exports.TerritoryTax(50, 1000, 'vente') == 900, 'le taux est plafonné à 90 %')
T.RacketRate = 10; t.owner = nil; ok(exports.TerritoryTax(50, 1000, 'vente') == 0, 'territoire libre : pas de taxe')
t.owner = 'alpha'; T.RacketEnabled = false; ok(exports.TerritoryTax(50, 1000, 'vente') == 0, 'racket désactivé : pas de taxe')
T.RacketEnabled = true; ok(exports.TerritoryTax(50, 0, 'vente') == 0 and exports.TerritoryTax(50, -5, 'vente') == 0 and exports.TerritoryTax(nil, 100) == 0, 'montants et joueurs invalides ignorés')
t = terr({ level = 1 }); reset(); put(50, 'beta', 5, 0); put(60, 'alpha', 900, 0); put(61, 'alpha', 900, 0); treasury.alpha.dirty = 0; for _ = 1, 5 do exports.TerritoryTax(50, 1000, 'vente') end
local members = #GB.onlineMembers('alpha'); ok(#notes == members, ('les notifications du propriétaire sont groupées : %d message(s) pour 5 ventes et %d membre(s) en ligne'):format(#notes, members))

print(('\n%d vérifications, %d échec(s)'):format(n, fails))
os.exit(fails == 0 and 0 or 1)
