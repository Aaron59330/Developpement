-- Blips : chaque lieu garde son blip (même nom, rien ajouté) ; les fiches (image / description) sont transmises à pickax_mapgroups (natives simulées).
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

local h = BB.Blip({ x = 1, y = 2, z = 3 }, { label = 'Banque' }, { category = 'bank' })
ok(h and names[h] == 'Banque', 'blip isolé : créé tout de suite, comme avant')
-- lot : deux garages de même nom (avec fiche) + une banque sans fiche
BB.BlipsBegin()
ok(BB.Blip({ x = 10, y = 0, z = 0 }, { sprite = 357, label = 'Garage', image = 'garage.webp', description = 'Garage public' }, { category = 'garage' }) == nil, 'pendant un lot, rien n\'est créé tout de suite')
BB.Blip({ x = 500, y = 0, z = 0 }, { sprite = 357, label = 'Garage', image = 'garage.webp', description = 'Garage public' }, { category = 'garage' })
BB.Blip({ x = 20, y = 20, z = 0 }, { label = 'Banque' }, { category = 'bank' })
local hs = BB.BlipsEnd()
ok(#hs == 3, '3 lieux → 3 blips : aucun blip n\'est fusionné')
local garages = 0 for _, id in ipairs(hs) do if names[id] == 'Garage' then garages = garages + 1 end end
ok(garages == 2, 'les deux garages gardent exactement le même nom, sans « (2) » ajouté')
ok(registered and registered.owner == 'pickax_worldbuilder' and #registered.groups == 2, 'seuls les blips avec fiche sont transmis à pickax_mapgroups')
local g = registered.groups[1]
ok(g.name == 'Garage' and g.tag == 'garage' and g.info.image == 'garage.webp' and g.info.description == 'Garage public' and g.siblings == 1 and #g.members == 1, 'fiche : nom, type, image, description et nombre d\'autres lieux de même nom')
ok(registered.groups[1].members[1].x == 10.0 and registered.groups[2].members[1].x == 500.0, 'chaque blip garde sa position')
-- sans fiche : rien à enregistrer
BB.BlipsBegin() BB.Blip({ x = 1, y = 1, z = 0 }, { label = 'Banque' }, {}) BB.Blip({ x = 2, y = 2, z = 0 }, { label = 'Banque' }, {})
ok(#BB.BlipsEnd() == 2 and #registered.groups == 0, 'sans image ni description : deux blips, aucune fiche')
-- fiche différente pour deux lieux de même nom : chacun la sienne
BB.BlipsBegin() BB.Blip({ x = 1, y = 1, z = 0 }, { label = 'Garage', description = 'Nord' }, {}) BB.Blip({ x = 2, y = 2, z = 0 }, { label = 'Garage', description = 'Sud' }, {})
BB.BlipsEnd() ok(registered.groups[1].info.description == 'Nord' and registered.groups[2].info.description == 'Sud', 'chaque lieu garde sa propre fiche')
-- un blip lié à une entité n'est jamais mis en lot
function AddBlipForEntity() nextId = nextId + 1 blips[nextId] = {} return nextId end
BB.BlipsBegin() local e = BB.Blip(nil, { label = 'Véhicule' }, { entity = 5 }) ok(e ~= nil, 'blip d\'entité : jamais mis en lot')
BB.BlipsEnd()
print(('blipgroups_test : %d vérifications OK'):format(checks))
