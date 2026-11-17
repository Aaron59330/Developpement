-- Cache mémoire de pickax_optimize : durée de vie, Remember, invalidation, plafond (lua5.4 tools/tests/optimize_test.lua)
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local now = 0
function GetGameTimer() return now end
function CreateThread() end
function Wait() end
local E = {}
function exports(name, f) E[name] = f end
Config = { Cache = { MaxEntries = 20, DefaultTTL = 60 } }
dofile(ROOT .. '/resources/[script]/pickax_optimize/server/cache.lua')

E.Set('a', 1, 10)
ok(E.Get('a') == 1, 'valeur lue avant expiration')
now = 11000
ok(E.Get('a') == nil, 'valeur expirée après son TTL')
local calls = 0
local fn = function() calls = calls + 1 return { n = calls } end
local v1 = E.Remember('k', 30, fn)
local v2 = E.Remember('k', 30, fn)
ok(calls == 1 and v1 == v2, 'Remember ne recalcule pas tant que la valeur est valide')
now = now + 31000
E.Remember('k', 30, fn)
ok(calls == 2, 'Remember recalcule après expiration')
E.Set('jobs:1', 'x', 100) E.Set('jobs:2', 'y', 100) E.Set('autre', 'z', 100)
E.InvalidatePrefix('jobs:')
ok(E.Get('jobs:1') == nil and E.Get('jobs:2') == nil and E.Get('autre') == 'z', 'invalidation par préfixe')
E.Remember('nil', 10, function() return nil end)
ok(E.CacheStats().entries >= 1, 'les statistiques existent')
for i = 1, 100 do E.Set('bulk' .. i, i, 1000) end
ok(E.CacheStats().entries <= 20, 'le cache ne dépasse jamais son plafond (' .. E.CacheStats().entries .. ')')
ok(E.Get('bulk100') == 100, 'la dernière entrée écrite reste disponible')
print(('optimize_test : %d vérifications OK'):format(checks))
