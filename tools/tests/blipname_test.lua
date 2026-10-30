-- Nom des blips : deux blips de même nom partagent le même texte (une seule ligne de légende) ; des noms différents ont des textes différents (natives simulées).
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local blips, nextId, entries, nameKey = {}, 0, {}, {}
function AddBlipForCoord(x, y, z) nextId = nextId + 1 blips[nextId] = { x = x, y = y } return nextId end
function SetBlipSprite() end function SetBlipColour() end function SetBlipScale() end function SetBlipDisplay() end function SetBlipAsShortRange() end
function GetHashKey(s) local h = 5381 for c in s:gmatch('.') do h = (h * 33 + c:byte()) % 4294967296 end return h end
local added = 0
function AddTextEntry(k, v) entries[k] = v added = added + 1 end
local cur
function BeginTextCommandSetBlipName(k) cur = k end
function EndTextCommandSetBlipName(h) nameKey[h] = cur end
PickaxTheme = nil
dofile(ROOT .. '/resources/[dev]/pickax_worldbuilder/client/bb_map.lua')
local a = BB.Blip({ x = 1, y = 1, z = 0 }, { sprite = 357, label = 'Garage' }, { category = 'garage' })
local b = BB.Blip({ x = 900, y = 900, z = 0 }, { sprite = 357, label = 'Garage' }, { category = 'garage' })
local c = BB.Blip({ x = 5, y = 5, z = 0 }, { label = 'Banque' }, { category = 'bank' })
ok(a ~= b and blips[a].x == 1 and blips[b].x == 900, 'deux garages = deux blips sur la carte, chacun à sa position')
ok(nameKey[a] == nameKey[b], 'les deux blips partagent EXACTEMENT le même texte de nom (une seule ligne de légende)')
ok(entries[nameKey[a]] == 'Garage' and nameKey[a] ~= nameKey[c] and entries[nameKey[c]] == 'Banque', 'le nom affiché est celui saisi ; un autre nom a son propre texte')
ok(added == 2, 'le texte n\'est enregistré qu\'une fois par nom')
local d = BB.Blip({ x = 7, y = 7, z = 0 }, {}, { label = 'Garage' })
ok(nameKey[d] == nameKey[a], 'le nom du module sert aussi : même nom = même texte')
print(('blipname_test : %d vérifications OK'):format(checks))
