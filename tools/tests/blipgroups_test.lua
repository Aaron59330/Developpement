-- Blips de même nom : chaque lieu garde son blip, tous STRICTEMENT identiques (icône, couleur, taille, nom) pour que GTA les range dans une seule ligne de la légende ;
-- les fiches (image / description) sont transmises à pickax_mapgroups (natives simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local blips, nextId, registered = {}, 0, nil
function AddBlipForCoord(x, y, z) nextId = nextId + 1 blips[nextId] = { x = x, y = y, z = z } return nextId end
function SetBlipSprite(h, v) blips[h].sprite = v end function SetBlipColour(h, v) blips[h].color = v end function SetBlipScale(h, v) blips[h].scale = v end
function SetBlipDisplay(h, v) blips[h].display = v end function SetBlipAsShortRange(h, v) blips[h].short = v end
local cur
function BeginTextCommandSetBlipName() end
function AddTextComponentSubstringPlayerName(n) cur = n end
function EndTextCommandSetBlipName(h) blips[h].name = cur end
function GetResourceState() return 'started' end
function GetCurrentResourceName() return 'pickax_worldbuilder' end
function AddEventHandler() end
exports = setmetatable({}, { __call = function() end, __index = function() return { SetGroups = function(_, owner, groups) registered = { owner = owner, groups = groups } end } end })
PickaxTheme = nil
dofile(ROOT .. '/resources/[dev]/pickax_worldbuilder/client/bb_map.lua')

local h = BB.Blip({ x = 1, y = 2, z = 3 }, { label = 'Banque' }, { category = 'bank' })
ok(h and blips[h].name == 'Banque', 'blip isolé : créé tout de suite, comme avant')
-- deux garages de même nom mais réglés différemment (icône, couleur, taille, visibilité) + une banque
BB.BlipsBegin()
ok(BB.Blip({ x = 10, y = 0, z = 0 }, { sprite = 357, color = 3, scale = 0.9, shortRange = true, label = 'Garage', image = 'garage.webp', description = 'Garage nord' }, { category = 'garage' }) == nil, 'pendant un lot, rien n\'est créé tout de suite')
BB.Blip({ x = 500, y = 0, z = 0 }, { sprite = 50, color = 1, scale = 0.4, shortRange = false, label = 'Garage', description = 'Garage sud' }, { category = 'impound' })
BB.Blip({ x = 20, y = 20, z = 0 }, { label = 'Banque' }, { category = 'bank' })
local hs = BB.BlipsEnd()
ok(#hs == 3, '3 lieux = 3 blips : AUCUN blip n\'est supprimé')
local g = {} for _, id in ipairs(hs) do if blips[id].name == 'Garage' then g[#g + 1] = blips[id] end end
ok(#g == 2 and g[1].x == 10.0 and g[2].x == 500.0, 'les deux garages sont bien sur la carte, chacun à sa position')
ok(g[1].sprite == g[2].sprite and g[1].color == g[2].color and g[1].scale == g[2].scale and g[1].display == g[2].display and g[1].short == g[2].short and g[1].name == g[2].name, 'les deux blips sont strictement identiques (icône, couleur, taille, affichage, nom)')
ok(g[1].sprite == 357 and g[1].color == 3 and g[1].name == 'Garage', 'ils prennent le style du premier, nom exact sans rien ajouter')
ok(registered.owner == 'pickax_worldbuilder' and #registered.groups == 1 and #registered.groups[1].members == 2, 'les deux lieux sont transmis pour les fiches (la banque sans fiche n\'est pas enregistrée)')
ok(registered.groups[1].members[1].info.image == 'garage.webp' and registered.groups[1].members[2].info.description == 'Garage sud' and registered.groups[1].members[2].info.image == '', 'chaque lieu garde sa propre fiche')
-- noms différents : réglages différents conservés
BB.BlipsBegin() BB.Blip({ x = 1, y = 1, z = 0 }, { sprite = 357, label = 'Garage' }, {}) BB.Blip({ x = 2, y = 2, z = 0 }, { sprite = 50, label = 'garage' }, {})
local two = BB.BlipsEnd() ok(#two == 2 and blips[two[1]].sprite == 357 and blips[two[2]].sprite == 50, 'noms différents (casse) : chaque blip garde son style')
BB.BlipsBegin() BB.Blip({ x = 1, y = 1, z = 0 }, {}, { label = 'Fourrière', category = 'impound' }) BB.Blip({ x = 9, y = 9, z = 0 }, { label = '' }, { label = 'Fourrière', category = 'garage' })
local hh = BB.BlipsEnd() ok(#hh == 2 and blips[hh[1]].sprite == blips[hh[2]].sprite, 'le nom du module sert aussi au regroupement : 2 blips identiques')
function AddBlipForEntity() nextId = nextId + 1 blips[nextId] = {} return nextId end
BB.BlipsBegin() local e = BB.Blip(nil, { label = 'Véhicule' }, { entity = 5 }) ok(e ~= nil, 'blip d\'entité : jamais mis en lot') BB.BlipsEnd()
print(('blipgroups_test : %d vérifications OK'):format(checks))
