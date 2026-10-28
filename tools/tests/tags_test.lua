-- Tags de gang : pose dans un territoire possédé, plafonds, bonus de revenu, expiration, effacement par un rival (natives simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local now = 1700000000
os.time = function() return now end
function CreateThread() end
function Wait() end
local cmds, notes, rep, news, sent, nextId, deleted = {}, {}, {}, {}, 0, 0, 0
function RegisterCommand(n, f) cmds[n] = f end
function RegisterNetEvent() end
function AddEventHandler() end
function TriggerClientEvent() sent = sent + 1 end
local peds = { [1] = { ped = 11, pos = { x = 10.0, y = 0.0, z = 30.0 } }, [2] = { ped = 12, pos = { x = 10.0, y = 0.0, z = 30.0 } } }
function GetPlayerPed(s) return peds[s] and peds[s].ped or 0 end
function GetEntityCoords(p) for _, v in pairs(peds) do if v.ped == p then return v.pos end end end
MySQL = { insert = { await = function() nextId = nextId + 1 return nextId end }, update = function() deleted = deleted + 1 end, query = { await = function() return {} end } }
local gangOf = { [1] = { name = 'a', label = 'A' }, [2] = { name = 'b', label = 'B' } }
GB = { Gangs = { a = { label = 'A', color = '#ff0000' }, b = { label = 'B' } }, Territories = {
        [1] = { id = 1, owner = 'a', coords = { x = 0.0, y = 0.0, z = 30.0 }, radius = 50.0 }, [2] = { id = 2, owner = 'b', coords = { x = 1000.0, y = 0.0, z = 30.0 }, radius = 50.0 } },
    gangOf = function(s) return gangOf[s] end, notify = function(s, m) notes[#notes + 1] = m end, addRep = function(g, n) rep[#rep + 1] = { g, n } end, news = function(m) news[#news + 1] = m end }
Config = { Tags = { Enabled = true, MaxPerTerritory = 2, IncomePercent = 4, IncomeMaxPercent = 6, ExpireDays = 7, Cooldown = 30, EraseCooldown = 60, EraseDistance = 3.0, MinSpacing = 8.0, RepPlace = 1, RepErase = 2 } }
dofile(ROOT .. '/resources/[dev]/pickax_gangbuilder/server/tags.lua')

ok(GB.tagMul(1, 'a') == 1.0, 'aucun tag : ×1')
ok(GB.tagInside(GB.Territories[1], { x = 10.0, y = 0.0 }) and not GB.tagInside(GB.Territories[1], { x = 100.0, y = 0.0 }), 'point dans le territoire')
local good, err = GB.tagPlace(2)
ok(not good and err:find('possédér') == nil and err:find('posséder'), 'un gang ne tague pas le territoire d\'un autre')
good = GB.tagPlace(1)
ok(good and GB.tagCount(1, 'a') == 1 and rep[#rep][2] == 1, 'tag posé, réputation gagnée')
ok(math.abs(GB.tagMul(1, 'a') - 1.04) < 1e-9, 'bonus de revenu +4 %')
good, err = GB.tagPlace(1)
ok(not good and err:find('Patiente'), 'délai entre deux tags')
now = now + 31
good, err = GB.tagPlace(1)
ok(not good and err:find('déjà un tag'), 'espacement minimal')
peds[1].pos = { x = 25.0, y = 0.0, z = 30.0 }
ok(GB.tagPlace(1) and GB.tagCount(1, 'a') == 2, 'deuxième tag')
ok(math.abs(GB.tagMul(1, 'a') - 1.06) < 1e-9, 'bonus plafonné (6 %)')
now = now + 31
peds[1].pos = { x = 40.0, y = 0.0, z = 30.0 }
good, err = GB.tagPlace(1)
ok(not good and err:find('couvert'), 'plafond de tags par territoire')
peds[1].pos = { x = 500.0, y = 0.0, z = 30.0 }
good, err = GB.tagPlace(1)
ok(not good, 'hors territoire refusé')
-- effacement
peds[2].pos = { x = 300.0, y = 0.0, z = 30.0 }
good, err = GB.tagErase(2)
ok(not good and err:find('Aucun tag'), 'aucun tag à portée')
peds[2].pos = { x = 11.0, y = 0.0, z = 30.0 }
good = GB.tagErase(1)
ok(not good, 'on n\'efface pas ses propres tags')
good = GB.tagErase(2)
ok(good and GB.tagCount(1, 'a') == 1 and deleted == 1 and news[#news]:find('effacé') and rep[#rep][1] == 'b' and rep[#rep][2] == 2, 'tag rival effacé, réputation et actualité')
good, err = GB.tagErase(2)
ok(not good and err:find('Patiente'), 'délai entre deux effacements')
-- expiration
ok(not GB.tagExpired(now - 6 * 86400, now) and GB.tagExpired(now - 8 * 86400, now), 'expiration après 7 jours')
now = now + 8 * 86400
ok(GB.tagCount(1, 'a') == 0 and GB.tagMul(1, 'a') == 1.0, 'tags expirés : plus de bonus')
Config.Tags.ExpireDays = 0
ok(not GB.tagExpired(0, now), 'durée 0 = jamais')
Config.Tags.Enabled = false
ok(GB.tagMul(1, 'a') == 1.0 and select(2, GB.tagPlace(1)):find('désactivés'), 'tags désactivés')
print(('tags_test : %d vérifications OK'):format(checks))
