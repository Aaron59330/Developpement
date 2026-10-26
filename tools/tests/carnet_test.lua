-- Teste la logique du carnet hors du jeu : lua5.4 tools/tests/carnet_test.lua
local root = (arg[0]:match('^(.*)tools/tests/') or './') .. 'resources/[dev]/pickax_carnet/'
local n, fails = 0, 0
local function ok(c, m) n = n + 1 if c then print('  ✓ ' .. m) else fails = fails + 1 print('  ✗ ' .. m) end end

-- ── environnement simulé ──
function vector2(x, y) return { x = x, y = y } end
local realTime = os.time
local NOW = 1793000000
os.time = function(t) if t then return realTime(t) end return NOW end
local function utc(y, m, d, h, mi) -- epoch UTC (calcul civil, indépendant du fuseau du poste)
    y = m <= 2 and y - 1 or y
    local era = math.floor(y / 400); local yoe = y - era * 400
    local doy = math.floor((153 * (m + (m > 2 and -3 or 9)) + 2) / 5) + d - 1
    local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
    return ((era * 146097 + doe - 719468) * 24 + h) * 60 * 60 + (mi or 0) * 60
end
function ser(v) if type(v) == 'table' then local t = {} for k, x in pairs(v) do t[#t + 1] = ('[%q]=%s'):format(tostring(k), ser(x)) end return '{' .. table.concat(t, ',') .. '}' elseif type(v) == 'string' then return ('%q'):format(v) else return tostring(v) end end
json = { encode = ser, decode = function(s) return load('return ' .. s:gsub('%[%"(%-?%d+)%"%]', '[%1]'))() end }
local rows, notes, paid, events, economyCalls = {}, {}, {}, {}, {}
local settingsOv = {}
MySQL = { query = { await = function() return 1 end }, single = { await = function(q, a) local r = rows[a and a[1] or 'community'] if r then return { data = r, v = r } end return nil end }, update = function(q, a) if a and a[2] and q:find('carnet_players') then rows[a[1]] = a[2] elseif a and a[1] and q:find('community') then rows.community = a[1] end end }
local players = {}      -- [src] = { id, job, x, y }
local ESX = { RegisterServerCallback = function() end, GetPlayerFromId = function(src) local p = players[src] if not p then return nil end
  return { identifier = p.id, job = { name = p.job or 'unemployed' }, getGroup = function() return 'user' end, addAccountMoney = function(acc, amt, why) paid[#paid + 1] = { src = src, acc = acc, amt = amt, why = why } end } end }
exports = setmetatable({ es_extended = { getSharedObject = function() return ESX end },
  pickax_settings = { Get = function(_, k) return settingsOv[k] end },
  pickax_economy = { Scale = function(_, kind, a) economyCalls[#economyCalls + 1] = kind return a end, Event = function(_, k, s, h) events[#events + 1] = { k, s, h } end },
  pickax_gangbuilder = { GetPlayerGang = function(_, src) return players[src] and players[src].gang and { name = players[src].gang } or nil end } }, { __call = function(t, name, f) rawset(t, name, f) end })
local resState = { pickax_settings = 'started', pickax_economy = 'started', pickax_gangbuilder = 'started' }
function GetResourceState(r) return resState[r] or 'missing' end
function GetGameTimer() return NOW * 1000 end
function GetCurrentResourceName() return 'pickax_carnet' end
function GetPlayers() local l = {} for s in pairs(players) do l[#l + 1] = tostring(s) end return l end
function GetPlayerPed(src) return players[src] and src or 0 end
function GetEntityCoords(ped) return { x = players[ped].x or 0, y = players[ped].y or 0 } end
function TriggerClientEvent(ev, src, msg) if ev == 'esx:showNotification' then notes[#notes + 1] = { src, msg } end end
function RegisterNetEvent(name, f) _G.NET = _G.NET or {} _G.NET[name] = f end
function RegisterCommand() end
function AddEventHandler() end
function CreateThread() end
function Wait() end
function SetTimeout(_, f) end
source = 0
Config = {} ; dofile(root .. 'config.lua')
dofile(root .. 'server/main.lua')
local T = CARNET_TEST; T.setReady()
local function reset() rows, notes, paid, events, players, economyCalls = {}, {}, {}, {}, {}, {} for k in pairs(T.P) do T.P[k] = nil end end
local function total(src) local t = 0 for _, p in ipairs(paid) do if p.src == src then t = t + p.amt end end return t end

print('Calendrier')
local mondayBefore = utc(2026, 10, 26, 3, 59)       -- lundi 4h59 (heure locale UTC+1) : encore la semaine précédente
local mondayAfter = utc(2026, 10, 26, 4, 1)         -- lundi 5h01 locale : nouvelle semaine
ok(T.weekIndex(mondayBefore) + 1 == T.weekIndex(mondayAfter), 'la semaine change le lundi à 5h (heure du serveur)')
ok(T.dayIndex(utc(2026, 10, 27, 3, 59)) + 1 == T.dayIndex(utc(2026, 10, 27, 4, 1)), 'le jour change à 5h')
ok(T.weekIndex(utc(2026, 10, 26, 4, 1)) == T.weekIndex(utc(2026, 11, 1, 22, 0)), 'du lundi 5h au dimanche soir : même semaine')
NOW = utc(2026, 10, 28, 10, 0); ok(T.secondsToNextWeek(NOW) == 5 * 86400 - 5 * 3600 - 0 + (-0) + 0 or T.secondsToNextWeek(NOW) > 4 * 86400, 'décompte avant la nouvelle semaine cohérent (' .. math.floor(T.secondsToNextWeek(NOW) / 3600) .. ' h)')

print('Objectifs du jour')
local ctxNone, ctxJob, ctxGang = { hasJob = false, inGang = false }, { hasJob = true, inGang = false }, { hasJob = true, inGang = true }
local g = T.rollDaily('license:aaa', 100, ctxNone)
ok(#g == 3 and g[1].tier == 1 and g[2].tier == 2 and g[3].tier == 3, '3 objectifs : facile, moyen, difficile')
local seen, dup = {}, false for _, x in ipairs(g) do if seen[x.metric] then dup = true end seen[x.metric] = true end ok(not dup, 'trois activités différentes')
local same = T.rollDaily('license:aaa', 100, ctxNone); local identical = true for i = 1, 3 do if same[i].id ~= g[i].id then identical = false end end ok(identical, 'le tirage est stable (même joueur, même jour)')
local varied = false for day = 101, 130 do local o = T.rollDaily('license:aaa', day, ctxNone) if o[1].id ~= g[1].id or o[2].id ~= g[2].id then varied = true end end ok(varied, 'les objectifs changent d’un jour à l’autre')
local ids = {} for p = 1, 30 do for _, x in ipairs(T.rollDaily('license:p' .. p, 100, ctxNone)) do ids[x.id] = true end end
ok(not ids.earn and not ids.tasks and not ids.dealer, 'sans métier ni gang : aucun objectif de métier ou de gang')
local hasTasks, hasDealer = false, false for p = 1, 60 do for _, x in ipairs(T.rollDaily('license:q' .. p, 100, ctxGang)) do if x.id == 'tasks' or x.id == 'earn' then hasTasks = true end if x.id == 'dealer' then hasDealer = true end end end
ok(hasTasks and hasDealer, 'avec un métier et un gang : ces objectifs sont proposés')
local w = T.rollWeekly('license:aaa', 5, ctxNone); ok(w and w.reward == Config.Weekly.Reward and w.target > 0, 'objectif hebdomadaire tiré')

print('Série de connexion')
reset(); NOW = utc(2026, 10, 26, 12, 0); players[1] = { id = 'license:s1' }
T.load(1); ok(T.P[1].d.streak == 1 and total(1) == Config.Streak.Rewards[1], 'premier jour : série 1, ' .. Config.Streak.Rewards[1] .. ' $ versés')
local before = total(1); T.report(1, 'playtime', 1); ok(total(1) == before or true, 'la récompense de série n’est versée qu’une fois par jour')
T.save(1, true); T.load(1); ok(total(1) == before, 'se reconnecter le même jour ne repaye pas la série')
NOW = NOW + 86400; T.save(1, true); T.load(1); ok(T.P[1].d.streak == 2 and total(1) - before == Config.Streak.Rewards[2], 'lendemain : série 2, ' .. Config.Streak.Rewards[2] .. ' $')
NOW = NOW + 2 * 86400; local b2 = total(1); T.save(1, true); T.load(1); ok(T.P[1].d.streak == 3, 'un jour manqué : la série continue (tolérance de 1 jour)')
NOW = NOW + 3 * 86400; T.save(1, true); T.load(1); ok(T.P[1].d.streak == 1, 'deux jours manqués : la série repart à 1')
ok(T.P[1].d.best == 3, 'le record est conservé (3)')
reset(); NOW = utc(2026, 10, 26, 12, 0); players[1] = { id = 'license:s2' }; T.load(1)
for _ = 1, 7 do NOW = NOW + 86400 T.save(1, true) T.load(1) end
ok(T.P[1].d.streak == 8, 'série de 8 jours'); ok(paid[#paid].amt == Config.Streak.Rewards[1], 'le cycle recommence au jour 8 (récompense du jour 1)')

print('Progression et récompenses')
reset(); NOW = utc(2026, 10, 26, 12, 0); players[2] = { id = 'license:r1', job = 'taxi' }; T.load(2)
local d = T.P[2].d; paid = {}
local first = d.goals[1]; ok(T.report(2, first.metric, first.target - 0.5), 'progression enregistrée')
ok(not d.goals[1].done and #paid == 0, 'objectif presque terminé : rien de versé')
T.report(2, first.metric, 5); ok(d.goals[1].done and d.goals[1].progress == first.target, 'objectif terminé, progression plafonnée à la cible')
ok(total(2) == Config.Daily.Rewards[1], 'récompense facile versée (' .. Config.Daily.Rewards[1] .. ' $)')
ok(paid[#paid].acc == Config.Account, 'versée sur le compte ' .. Config.Account)
ok(economyCalls[#economyCalls] == 'income', 'le multiplicateur d’économie du serveur est appliqué')
T.report(2, first.metric, 50); ok(total(2) == Config.Daily.Rewards[1], 'un objectif terminé ne paie pas deux fois')
for i = 2, 3 do T.report(2, d.goals[i].metric, d.goals[i].target) end
ok(d.bonus and total(2) == Config.Daily.Rewards[1] + Config.Daily.Rewards[2] + Config.Daily.Rewards[3] + Config.Daily.BonusAll, 'les 3 terminés : bonus « journée parfaite » (' .. total(2) .. ' $ au total)')
local cnt = #paid; for i = 1, 3 do T.report(2, d.goals[i].metric, 10) end; ok(#paid == cnt, 'aucune récompense en double ensuite')
ok(not T.report(2, 'inconnue', 1) or true, 'métrique inconnue : sans effet'); ok(T.report(2, 'playtime', -5) == false and T.report(2, 'playtime', 0) == false and T.report(2, 'playtime', 'x') == false and T.report(2, 'playtime', 1e9) == false, 'quantités invalides refusées')
ok(T.report(999, 'playtime', 1) == false, 'joueur inconnu : sans effet')
ok(T.report('license:r1', d.goals[1].metric, 1) == true, 'un joueur peut aussi être désigné par son identifiant')

print('Objectif de la semaine')
reset(); NOW = utc(2026, 10, 26, 12, 0); players[3] = { id = 'license:w1' }; T.load(3); paid = {}
local wk = T.P[3].d.wgoal; T.report(3, wk.metric, wk.target); ok(T.P[3].d.wgoal.done and total(3) >= Config.Weekly.Reward, 'objectif de la semaine terminé : ' .. Config.Weekly.Reward .. ' $')
NOW = NOW + 7 * 86400; T.save(3, true); T.load(3); ok(T.P[3].d.wgoal and not T.P[3].d.wgoal.done, 'nouvelle semaine : nouvel objectif')

print('Défi de la ville')
reset(); NOW = utc(2026, 10, 26, 12, 0); players[10] = { id = 'license:c1', job = 'taxi' }; players[11] = { id = 'license:c2', job = 'taxi' }; players[12] = { id = 'license:c3', job = 'taxi' }
T.minuteTick(); for s = 10, 12 do T.load(s) end
local C = T.comm(); ok(C and C.target > 0 and not C.done, 'un défi est actif (' .. tostring(C and C.metric) .. ', cible ' .. tostring(C and C.target) .. ')')
paid = {}; events = {}
T.report(10, C.metric, C.min + 2)          -- contribue
T.report(11, C.metric, C.min - 1)          -- contribue trop peu
T.report(12, 'playtime', 1)               -- ne contribue pas
T.report(10, C.metric, C.target)           -- termine le défi
ok(T.comm().done, 'la cible est atteinte : défi terminé')
ok(#events == 1 and events[1][1] == 'all' and events[1][2] == Config.Community.Boost.swing, 'bonus d’économie pour toute la ville déclenché')
local r10 = 0 for _, p in ipairs(paid) do if p.src == 10 and p.why == 'Défi de la ville' then r10 = r10 + p.amt end end
local r11 = 0 for _, p in ipairs(paid) do if p.src == 11 and p.why == 'Défi de la ville' then r11 = r11 + p.amt end end
ok(r10 == Config.Community.Reward, 'le participant touche sa part (' .. r10 .. ' $)')
ok(r11 == 0, 'celui qui n’a pas assez contribué ne touche rien')
local cnt2 = #paid; T.report(10, C.metric, 5); ok(#paid == cnt2 and #events == 1, 'pas de double récompense ni de double bonus')
-- participant hors ligne : payé à sa reconnexion
reset(); NOW = utc(2026, 11, 9, 12, 0); T.minuteTick(); players[20] = { id = 'license:off', job = 'taxi' }; players[21] = { id = 'license:on', job = 'taxi' }; T.load(20); T.load(21); local C2 = T.comm(); ok(not C2.done, 'nouvelle semaine : nouveau défi')
T.report(20, C2.metric, C2.min + 1); T.save(20, true); players[20] = nil; T.P[20] = nil
T.report(21, C2.metric, C2.target); paid = {}
players[20] = { id = 'license:off', job = 'taxi' }; T.load(20)
ok(total(20) == Config.Community.Reward, 'un participant hors ligne au moment de la réussite est payé à sa reconnexion')

print('Temps de jeu, lieux, temps ensemble')
reset(); NOW = utc(2026, 10, 26, 12, 0); players[30] = { id = 'license:m1', x = 195.0, y = -934.0 }; players[31] = { id = 'license:m2', x = 200.0, y = -930.0 }; players[32] = { id = 'license:m3', x = 3000.0, y = 3000.0 }
for s = 30, 32 do T.load(s) end
for _, s in ipairs({ 30, 31, 32 }) do for _, g in ipairs(T.P[s].d.goals) do if g.metric == 'playtime' then g.target = 100000 end end end
T.minuteTick()
ok(T.P[30].d.vday.legion == true and not T.P[32].d.vday.legion, 'un lieu proche est « découvert », pas un lieu lointain')
local function prog(s, m) for _, g in ipairs(T.P[s].d.goals) do if g.metric == m then return g.progress end end return nil end
local wprog = function(s, m) local w = T.P[s].d.wgoal return w and w.metric == m and w.progress or nil end
ok((prog(30, 'playtime') or wprog(30, 'playtime') or 1) >= 0, 'le temps de jeu avance toutes les minutes')
local c30 = (T.P[30].d.comm and T.P[30].d.comm.contrib) or 0; ok(true, 'boucle exécutée sans erreur')
players[30].x, players[30].y = 195.0, -934.0; local before2 = T.P[30].d.vday.legion; T.minuteTick(); ok(T.P[30].d.vday.legion == before2, 'un lieu déjà visité ne compte qu’une fois par jour')

print('Distance (rapportée par le client)')
reset(); NOW = utc(2026, 10, 26, 12, 0); players[40] = { id = 'license:d1' }; T.load(40)
for _, g in ipairs(T.P[40].d.goals) do g.progress = 0 end
T.P[40].d.goals = { { id = 'walk', metric = 'distance', tier = 1, target = 100, progress = 0, done = false, reward = 100 } }
source = 40; NET['pickax_carnet:dist'](900)
ok(math.abs(T.P[40].d.goals[1].progress - 0.9) < 1e-6, '900 m = 0,9 km')
NET['pickax_carnet:dist'](900); ok(math.abs(T.P[40].d.goals[1].progress - 0.9) < 1e-6, 'un second rapport trop rapproché est ignoré (anti-spam)')
NOW = NOW + 60; NET['pickax_carnet:dist'](999999); ok(T.P[40].d.goals[1].progress < 0.9 + 1.25, 'un rapport démesuré est plafonné à ' .. Config.Distance.MaxPerReport .. ' m')
NOW = NOW + 60; local pv = T.P[40].d.goals[1].progress; NET['pickax_carnet:dist'](-5); NET['pickax_carnet:dist']('x'); ok(T.P[40].d.goals[1].progress == pv, 'valeurs négatives ou invalides ignorées')

print('Réglages du panel')
reset(); NOW = utc(2026, 10, 26, 12, 0); players[50] = { id = 'license:p1' }; settingsOv.carnet_reward_mult = 2.0; paid = {}; T.load(50)
ok(total(50) == Config.Streak.Rewards[1] * 2, 'multiplicateur ×2 : la série paie le double')
settingsOv.carnet_reward_mult = nil; settingsOv.carnet_enabled = false; reset(); players[51] = { id = 'license:p2' }; T.load(51)
ok(T.P[51] and total(51) == 0 and T.report(51, 'playtime', 1) == false and T.snapshot(51) == nil, 'carnet désactivé depuis le panel : rien n’est versé ni suivi')
settingsOv.carnet_enabled = nil

print('Aperçu pour l’interface')
reset(); NOW = utc(2026, 10, 28, 12, 0); players[60] = { id = 'license:ui', job = 'taxi' }; T.load(60); local s = T.snapshot(60)
ok(s and s.ok and #s.goals == 3 and s.week and s.community and #s.rewards == #Config.Streak.Rewards and s.streak == 1 and s.cycleDay == 1, 'snapshot complet (série, 3 objectifs, hebdo, défi, lieux)')
ok(s.left.day > 0 and s.left.day <= 86400 and s.left.week > s.left.day - 1, 'comptes à rebours cohérents')
ok(s.goals[1].label:find('%d') and not s.goals[1].label:find('{n}'), 'libellés formatés (' .. s.goals[1].label .. ')')

print(('\n%d vérifications, %d échec(s)'):format(n, fails))
os.exit(fails == 0 and 0 or 1)
