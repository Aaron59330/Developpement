-- Saisons de gangs : classement, récompenses, fin de saison et remise à zéro (base simulée).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local now, inserts, updates = 10000, {}, {}
os.time = function() return now end
local nextId = 0
MySQL = { ready = function(f) f() end,
    query = { await = function() return {} end }, scalar = { await = function() return nil end }, single = { await = function() return nil end },
    insert = setmetatable({ await = function() nextId = nextId + 1 return nextId end }, { __call = function(_, sql, args) inserts[#inserts + 1] = { sql, args } end }),
    update = function(sql, args) updates[#updates + 1] = { sql, args } end }
function CreateThread() end
function Wait() end
function RegisterCommand() end
function exports() end
local paid, notes, news = {}, {}, {}
GB = { Gangs = { a = { label = 'A', color = '#f00', settings = {} }, b = { label = 'B', color = '#0f0', settings = {} }, c = { label = 'C', color = '#00f', settings = {} } },
    onlineMembers = function(n) return n == 'a' and { 1 } or {} end, notify = function(s, m) notes[#notes + 1] = m end, isDev = function() return true end,
    treasuryAdd = function(n, k, v) paid[#paid + 1] = { n, k, v } return true end, news = function(t, k) news[#news + 1] = { t, k } end }
Config = { Season = { Enabled = true, Days = 7, MinPoints = 10, RewardAccount = 'dirty', Rewards = { { money = 15000, rep = 50 }, { money = 8000, rep = 30 }, { money = 4000, rep = 15 } } } }
dofile(ROOT .. '/resources/[dev]/pickax_gangbuilder/server/season.lua')

-- décision pure
local r = GB.seasonDecide({ a = 120, b = 120, c = 5, d = 300 }, Config.Season.Rewards, 10)
ok(#r == 3 and r[1].gang == 'd' and r[1].money == 15000, 'tri par points, récompense du 1er')
ok(r[2].gang == 'a' and r[3].gang == 'b', 'égalité : ordre alphabétique stable')
ok(r[3].money == 4000 and r[3].rep == 15, 'récompense du 3e')
ok(#GB.seasonDecide({ a = 9 }, Config.Season.Rewards, 10) == 0, 'sous le minimum : pas classé')
ok(GB.seasonDecide({ a = 50, b = 40, c = 30, d = 20 }, Config.Season.Rewards, 10)[4].money == 0, '4e : pas de récompense')

-- cumul des points
GB.seasonAdd('a', 30) GB.seasonAdd('a', 25) GB.seasonAdd('b', 40) GB.seasonAdd('c', 3)
local info = GB.seasonInfo('b')
ok(info.enabled and info.top[1].name == 'a' and info.top[1].points == 55 and info.top[2].name == 'b', 'classement en direct')
ok(info.mine.rank == 2 and info.mine.points == 40, 'rang et points de mon gang')
ok(info.left == 7 * 86400, 'temps restant : 7 jours')

-- fin de saison
now = now + 7 * 86400 + 5
ok(GB.seasonEnd() == true, 'fin de saison')
ok(#paid == 2 and paid[1][1] == 'a' and paid[1][3] == 15000 and paid[2][1] == 'b' and paid[2][3] == 8000, 'récompenses versées aux 2 gangs classés (c : 3 pts, sous le minimum)')
ok(#notes == 1, 'les membres connectés du gagnant sont prévenus')
ok(news[1] and news[1][2] == 'season', 'actualité publiée')
ok(#GB.seasonInfo('a').top == 0 and GB.seasonInfo('a').id == 2, 'nouvelle saison à zéro')
Config.Season.Enabled = false
GB.seasonAdd('a', 100)
ok(GB.seasonInfo('a').enabled == false, 'désactivée : plus de points')
print(('season_test : %d vérifications OK'):format(checks))
