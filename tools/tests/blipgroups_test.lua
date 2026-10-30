-- Blips de même nom : UN seul blip (nom exact, rien d'ajouté) ; ← → sur la carte le font passer d'un lieu à l'autre (natives simulées).
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
local evs = {}
function AddEventHandler(n, f) evs[n] = f end
local mg = {}
exports = setmetatable({}, { __call = function(_, n, f) mg[n] = f end, __index = function() return { SetGroups = function(_, owner, groups) registered = { owner = owner, groups = groups } end } end })
PickaxTheme = nil
dofile(ROOT .. '/resources/[dev]/pickax_worldbuilder/client/bb_map.lua')

local h = BB.Blip({ x = 1, y = 2, z = 3 }, { label = 'Banque' }, { category = 'bank' })
ok(h and names[h] == 'Banque', 'blip isolé : créé tout de suite, comme avant')
BB.BlipsBegin()
ok(BB.Blip({ x = 10, y = 0, z = 0 }, { sprite = 357, label = 'Garage', image = 'garage.webp', description = 'Garage nord' }, { category = 'garage' }) == nil, 'pendant un lot, rien n\'est créé tout de suite')
BB.Blip({ x = 500, y = 0, z = 0 }, { sprite = 357, label = 'Garage', description = 'Garage sud' }, { category = 'garage' })
BB.Blip({ x = 20, y = 20, z = 0 }, { label = 'Banque' }, { category = 'bank' })
BB.Blip({ x = 30, y = 30, z = 0 }, {}, { label = 'Garage central' })
local hs = BB.BlipsEnd()
ok(#hs == 3, '4 lieux → 3 blips : les deux « Garage » ne forment qu\'un blip')
local garage; for _, id in ipairs(hs) do if names[id] == 'Garage' then garage = id end end
ok(garage and names[garage] == 'Garage', 'le blip garde EXACTEMENT son nom (rien d\'ajouté)')
ok(registered.owner == 'pickax_worldbuilder' and #registered.groups == 1 and registered.groups[1].blip == garage and #registered.groups[1].members == 2, 'les deux lieux sont transmis (les noms différents restent séparés)')
ok(registered.groups[1].members[1].info.image == 'garage.webp' and registered.groups[1].members[2].info.description == 'Garage sud' and registered.groups[1].members[2].info.image == '', 'chaque lieu garde sa propre fiche')
BB.BlipsBegin() BB.Blip({ x = 1, y = 1, z = 0 }, { label = 'Garage' }, {}) BB.Blip({ x = 2, y = 2, z = 0 }, { label = 'garage' }, {})
ok(#BB.BlipsEnd() == 2, 'seuls les noms EXACTEMENT identiques sont regroupés (casse comprise)')
BB.BlipsBegin() BB.Blip({ x = 1, y = 1, z = 0 }, {}, { label = 'Fourrière' }) BB.Blip({ x = 9, y = 9, z = 0 }, { label = '' }, { label = 'Fourrière' })
local hh = BB.BlipsEnd() ok(#hh == 1 and names[hh[1]] == 'Fourrière', 'le nom du module sert aussi au regroupement')
function AddBlipForEntity() nextId = nextId + 1 blips[nextId] = {} return nextId end
BB.BlipsBegin() local e = BB.Blip(nil, { label = 'Véhicule' }, { entity = 5 }) ok(e ~= nil, 'blip d\'entité : jamais mis en lot') BB.BlipsEnd()

-- ═══ pickax_mapgroups : flèches de la carte ═══
local threads, moved, flashed, nui = {}, {}, {}, {}
local pressedNow = nil
function CreateThread(f) threads[#threads + 1] = f end
function Wait() coroutine.yield() end
function SetTimeout() end
function DoesBlipExist() return true end
function SetBlipCoords(b, x, y, z) moved[#moved + 1] = { b, x, y } end
function SetBlipFlashes(b, on) flashed[#flashed + 1] = on end
function PlayerPedId() return 1 end
function GetEntityCoords() return { x = 480.0, y = 0.0, z = 0.0 } end
function IsPauseMenuActive() return true end
function IsNuiFocused() return false end
function IsWaypointActive() return false end
function IsDisabledControlJustPressed(g, c) return pressedNow == c end
function IsControlJustPressed() return false end
function GetGameTimer() return 0 end
function GetStreetNameAtCoord() return 1 end
function GetStreetNameFromHashKey() return 'Rue Test' end
function SendNUIMessage(m) nui[#nui + 1] = m end
function TriggerEvent() end
local cmds = {}
function RegisterCommand(n, f) cmds[n] = f end
function RegisterKeyMapping() end
dofile(ROOT .. '/resources/[dev]/pickax_mapgroups/client.lua')
local groups = { { blip = 77, name = 'Garage', tag = 'garage', members = { { x = 10.0, y = 0.0, z = 0.0, info = { image = 'g.webp', description = 'Nord' } }, { x = 500.0, y = 0.0, z = 0.0, info = { image = '', description = '' } }, { x = 900.0, y = 0.0, z = 0.0 } } } }
mg.SetGroups('pickax_worldbuilder', groups)
ok(groups[1].idx == 2 and moved[#moved][2] == 500.0, 'au départ, le blip est sur le lieu le plus proche du joueur')
local cos = {} for _, f in ipairs(threads) do local c = coroutine.create(f) coroutine.resume(c) cos[#cos + 1] = c end
local function step(key) pressedNow = key for _ = 1, 2 do for _, c in ipairs(cos) do if coroutine.status(c) == 'suspended' then coroutine.resume(c) end end end pressedNow = nil end   -- 2 passes : action puis temporisation
step(175) ok(groups[1].idx == 3 and moved[#moved][2] == 900.0, '→ : lieu suivant')
step(175) ok(groups[1].idx == 1 and moved[#moved][2] == 10.0, '→ : retour au premier lieu (boucle)')
step(174) ok(groups[1].idx == 3 and moved[#moved][2] == 900.0, '← : lieu précédent')
ok(nui[#nui].action == 'show' and nui[#nui].index == 3 and nui[#nui].total == 3 and nui[#nui].title == 'Garage', 'la fiche indique « lieu 3 sur 3 »')
step(174) ok(nui[#nui].index == 2 and nui[#nui].description == 'Rue Test' and flashed[#flashed - 0] ~= nil, 'sans description : la rue du lieu est affichée ; le blip clignote')
step(175) step(175) ok(nui[#nui].description == 'Nord' and nui[#nui].image == 'g.webp', 'la fiche du lieu courant (image + description)')
-- méthode 2 : touches configurables et /lieu (si les flèches ne passent pas sur la carte)
local i0 = groups[1].idx
cmds.pk_mapgroups_next() ok(groups[1].idx == i0 % 3 + 1, 'touche configurable « suivant » : lieu suivant')
cmds.pk_mapgroups_prev() ok(groups[1].idx == i0, 'touche configurable « précédent » : lieu précédent')
cmds.lieu(0, {}) ok(groups[1].idx == i0 % 3 + 1, '/lieu : lieu suivant') cmds.lieu(0, { 'prec' }) ok(groups[1].idx == i0, '/lieu prec : lieu précédent')
print(('blipgroups_test : %d vérifications OK'):format(checks))
