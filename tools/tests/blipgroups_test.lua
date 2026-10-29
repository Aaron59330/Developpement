-- Blips de même nom regroupés en un seul (natives simulées) : lot, regroupement exact par nom, libellé « Nom (N) », liste des lieux transmise à pickax_mapgroups.
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local blips, names, registered, nextId = {}, {}, nil, 0
function AddBlipForCoord(x, y, z) nextId = nextId + 1 blips[nextId] = { x = x, y = y, z = z } return nextId end
function SetBlipSprite() end function SetBlipColour() end function SetBlipScale() end function SetBlipDisplay() end function SetBlipAsShortRange() end
local curName
function BeginTextCommandSetBlipName() end
function AddTextComponentSubstringPlayerName(n) curName = n end
function EndTextCommandSetBlipName(h) names[h] = curName end
function GetResourceState() return 'started' end
function GetCurrentResourceName() return 'pickax_worldbuilder' end
function AddEventHandler() end
exports = setmetatable({}, { __index = function() return { SetGroups = function(_, owner, groups) registered = { owner = owner, groups = groups } end } end })
PickaxTheme = nil
dofile(ROOT .. '/resources/[dev]/pickax_worldbuilder/client/bb_map.lua')

-- sans lot : comportement inchangé
local h = BB.Blip({ x = 1, y = 2, z = 3 }, { label = 'Banque' }, { category = 'bank' })
ok(h and names[h] == 'Banque', 'blip isolé : créé tout de suite, comme avant')
-- lot : deux garages de même nom + une banque
BB.BlipsBegin()
ok(BB.Blip({ x = 10, y = 0, z = 0 }, { sprite = 357, label = 'Garage' }, {}) == nil, 'pendant un lot, rien n\'est créé tout de suite')
BB.Blip({ x = 500, y = 0, z = 0 }, { sprite = 357, label = 'Garage' }, {})
BB.Blip({ x = 20, y = 20, z = 0 }, { label = 'Banque' }, { category = 'bank' })
BB.Blip({ x = 30, y = 30, z = 0 }, {}, { label = 'Garage central' })   -- nom différent : séparé
local hs = BB.BlipsEnd()
ok(#hs == 3, '4 lieux → 3 blips (les deux « Garage » sont fusionnés)')
local garage
for _, id in ipairs(hs) do if names[id] == 'Garage (2)' then garage = id end end
ok(garage, 'blip fusionné nommé « Garage (2) »')
ok(registered and registered.owner == 'pickax_worldbuilder' and #registered.groups == 1 and #registered.groups[1].members == 2 and registered.groups[1].blip == garage and registered.groups[1].name == 'Garage', 'la liste des deux lieux est transmise à pickax_mapgroups')
local single = 0 for _, id in ipairs(hs) do if names[id] == 'Banque' or names[id] == 'Garage central' then single = single + 1 end end
ok(single == 2, 'les noms différents restent séparés')
-- noms presque identiques : pas de fusion
BB.BlipsBegin() BB.Blip({ x = 1, y = 1, z = 0 }, { label = 'Garage' }, {}) BB.Blip({ x = 2, y = 2, z = 0 }, { label = 'garage' }, {})
ok(#BB.BlipsEnd() == 2, 'seuls les noms EXACTEMENT identiques sont fusionnés (casse comprise)')
-- libellé par défaut du module
BB.BlipsBegin() BB.Blip({ x = 1, y = 1, z = 0 }, {}, { label = 'Fourrière' }) BB.Blip({ x = 9, y = 9, z = 0 }, { label = '' }, { label = 'Fourrière' })
local hh = BB.BlipsEnd() ok(#hh == 1 and names[hh[1]] == 'Fourrière (2)', 'le nom du module sert aussi au regroupement')
-- un blip lié à une entité n'est jamais regroupé
function AddBlipForEntity() nextId = nextId + 1 blips[nextId] = {} return nextId end
BB.BlipsBegin() local e = BB.Blip(nil, { label = 'Véhicule' }, { entity = 5 }) ok(e ~= nil, 'blip d\'entité : jamais mis en lot')
BB.BlipsEnd()
print(('blipgroups_test : %d vérifications OK'):format(checks))
