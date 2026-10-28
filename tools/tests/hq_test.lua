-- QG de gang : niveaux, multiplicateurs, amélioration, pillage et déroulé d'un raid (natives simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local now, threads, notes, paid, updates = 1000, {}, {}, {}, {}
os.time = function() return now end
function Wait() end
function CreateThread(f) threads[#threads + 1] = f end
function RegisterCommand() end
function exports() end
function TriggerClientEvent() end
local peds = {}
function GetPlayerPed(src) return peds[src] and peds[src].ped or 0 end
function GetEntityCoords(ped) for _, p in pairs(peds) do if p.ped == ped then return p.pos end end end
function GetEntityHealth(ped) for _, p in pairs(peds) do if p.ped == ped then return p.hp end end end
json = { encode = function() return '{}' end }
MySQL = { update = function(sql) updates[#updates + 1] = sql end }
local money = { a = { money = 0, dirty = 50000 }, b = { money = 0, dirty = 100000 } }
Config = { HQ = { Enabled = true, UpgradeAccount = 'dirty',
    Levels = { {}, { cost = 25000, income = 1.10, protection = 1.15, steal = 0.80 }, { cost = 60000, income = 1.20, protection = 1.30, steal = 0.60 } },
    Raid = { Enabled = true, HoldSeconds = 5, Radius = 12.0, MaxSeconds = 600, MinAttackers = 2, MinDefenders = 1, StealPercent = 10, MinDirty = 2000, MaxSteal = 20000, Cooldown = 3600, AttackerCooldown = 1800 } } }
GB = { Gangs = { a = { label = 'A', settings = {} }, b = { label = 'B', settings = {} } }, PlayerGang = {}, Points = {},
    notify = function(s, m) notes[#notes + 1] = m end, log = function() end, news = function() end, addRep = function() end, gangOf = function() end,
    onlineMembers = function(n) local l = {} for s, g in pairs(GB.PlayerGang) do if g.name == n then l[#l + 1] = s end end return l end,
    treasury = function(n) return money[n].money, money[n].dirty, 0 end,
    treasuryAdd = function(n, k, v) money[n][k] = money[n][k] + v return true end,
    treasuryRemove = function(n, k, v) if money[n][k] < v then return false end money[n][k] = money[n][k] - v return true end }
GB.Points[1] = { gang_name = 'a', type = 'stash', coords = { x = 0.0, y = 0.0, z = 30.0 } }
GB.Points[2] = { gang_name = 'b', type = 'stash', coords = { x = 100.0, y = 100.0, z = 30.0 } }
dofile(ROOT .. '/resources/[dev]/pickax_gangbuilder/server/hq.lua')

-- niveaux et multiplicateurs
ok(GB.hqLevel('a') == 1 and GB.hqMul('a', 'income') == 1.0, 'niveau 1 : valeurs de base')
local up, lvl = GB.hqUpgrade('a')
ok(up and lvl == 2 and money.a.dirty == 25000 and GB.hqLevel('a') == 2, 'amélioration payée par la trésorerie')
ok(math.abs(GB.hqMul('a', 'income') - 1.10) < 1e-9 and math.abs(GB.hqMul('a', 'protection') - 1.15) < 1e-9, 'avantages du niveau 2')
local up2, why = GB.hqUpgrade('a')
ok(not up2 and why == 'funds', 'fonds insuffisants refusés (25 000 < 60 000)')
money.a.dirty = 100000
ok(GB.hqUpgrade('a') and GB.hqLevel('a') == 3, 'niveau 3')
ok(select(2, GB.hqUpgrade('a')) == 'max', 'niveau maximum')
Config.HQ.Enabled = false
ok(GB.hqMul('a', 'income') == 1.0, 'QG désactivé : ×1')
Config.HQ.Enabled = true
-- pillage
ok(GB.hqStealAmount(1000, 1, Config.HQ.Raid) == 0, 'trop peu d\'argent : rien à piller')
ok(GB.hqStealAmount(50000, 1, Config.HQ.Raid) == 5000, '10 % de 50 000')
ok(GB.hqStealAmount(50000, 3, Config.HQ.Raid) == 3000, 'niveau 3 : pillage ×0,6')
ok(GB.hqStealAmount(10 ^ 7, 1, Config.HQ.Raid) == 20000, 'plafond du pillage')
-- progression
ok(GB.hqRaidStep(10, 2, 0) == 11, 'attaquants seuls : +1')
ok(GB.hqRaidStep(10, 2, 1) == 9, 'défenseur présent : -1')
ok(GB.hqRaidStep(10, 0, 0) == 8 and GB.hqRaidStep(0, 0, 0) == 0, 'zone vide : -2, jamais négatif')

-- conditions
GB.PlayerGang = { [1] = { name = 'a' }, [3] = { name = 'b' } }
ok(select(2, GB.hqRaidCheck('b', 'b')) == 'self', 'son propre QG')
ok(select(2, GB.hqRaidCheck('b', 'a')) == 'att', 'pas assez d\'attaquants')
GB.PlayerGang[2] = { name = 'a' }
GB.PlayerGang[3] = nil
ok(select(2, GB.hqRaidCheck('b', 'a')) == 'def', 'aucun défenseur')
GB.PlayerGang[3] = { name = 'b' }
ok(GB.hqRaidCheck('b', 'a') == true, 'raid possible')
-- déroulé : 2 attaquants dans la zone de b, pas de défenseur dedans
peds = { [1] = { ped = 11, pos = { x = 101.0, y = 100.0, z = 30.0 }, hp = 200 }, [2] = { ped = 12, pos = { x = 99.0, y = 100.0, z = 30.0 }, hp = 200 }, [3] = { ped = 13, pos = { x = 500.0, y = 500.0, z = 30.0 }, hp = 200 } }
ok(GB.hqStartRaid('b', 'a') == true, 'raid lancé')
ok(select(2, GB.hqRaidCheck('b', 'a')) == 'busy', 'un seul raid à la fois')
local n = 0
Wait = function() n = n + 1 now = now + 1 if n >= 8 then error('stop') end end
for _, th in ipairs(threads) do n = 0 pcall(th) end
ok(money.a.dirty == 40000 + 10000, '10 % de 100 000 versés aux attaquants : ' .. money.a.dirty)
ok(money.b.dirty == 90000, 'argent retiré au QG pillé : ' .. money.b.dirty)
ok(select(2, GB.hqRaidCheck('b', 'a')) ~= 'busy', 'raid terminé')
GB.PlayerGang[4] = { name = 'a' } GB.PlayerGang[5] = { name = 'a' }
ok(select(2, GB.hqRaidCheck('b', 'a')) == 'cool', 'délai avant de raider le même QG')
print(('hq_test : %d vérifications OK'):format(checks))
