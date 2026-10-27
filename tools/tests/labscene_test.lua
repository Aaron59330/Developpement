-- Test de la scène 3D du labo (natives simulées) : projection écran→plateau, chaque étape se dessine sans erreur, nettoyage complet.
local ROOT = os.getenv('ROOT') or '.'
local calls, ents, nextE = {}, {}, 100
local now = 0
local function cnt(n) calls[n] = (calls[n] or 0) + 1 end
Config = { Real = { Lab = { Experience = { Cam = { fov = 45.0 }, Scene3D = { Enabled = true, Surface = 0.92, PotRadius = 0.15, BowlRadius = 0.1,
    Models = { pot = {}, bowl = { 'nope', 'prop_cs_bowl_01' }, spatula = { 'zzz' } }, Pool = { bowl = 2 } } } } } }
function joaat(s) return s end
function IsModelInCdimage(h) return h == 'prop_cs_bowl_01' end
function IsModelValid(h) return true end
function RequestModel() end
function HasModelLoaded() return true end
function SetModelAsNoLongerNeeded() end
function GetGameTimer() now = now + 16; return now end
function Wait() end
function CreateObject() nextE = nextE + 1; ents[nextE] = { vis = true }; return nextE end
function DoesEntityExist(e) return ents[e] ~= nil end
function DeleteEntity(e) ents[e] = nil; cnt('del') end
function SetEntityCollision() end
function FreezeEntityPosition() end
function SetEntityVisible(e, v) if ents[e] then ents[e].vis = v end end
function SetEntityCoordsNoOffset(e, x, y, z) assert(x == x and y == y and z == z, 'NaN'); cnt('place') end
function SetEntityRotation() end
function DrawMarker(...) cnt('marker') end
function DrawLightWithRange() cnt('light') end
function RegisterNUICallback() end
function RegisterCommand() end
json = { encode = function() return '{}' end }
function PlayerPedId() return 1 end
function StartExpensiveSynchronousShapeTestLosProbe() return 7 end
local SHAPE_HIT = { 1, { x = 100.0, y = 200.0, z = 30.97 } }
function GetShapeTestResult() return 2, SHAPE_HIT[1], SHAPE_HIT[2] end
local threads = {}
function CreateThread(f) threads[#threads + 1] = f end
-- caméra à 0.85 m derrière la table, 1.2 m de haut, regardant la table (q.z+0.92)
local q = { x = 100.0, y = 200.0, z = 30.0, h = 0.0 }
local pr = math.rad(-64.0)
local cp = { x = 100.0, y = 200.0 - math.cos(pr) * 0.85, z = q.z + 0.92 - math.sin(pr) * 0.85 }
local dx, dy, dz = q.x - cp.x, q.y - cp.y, (q.z + 0.92) - cp.z
local pitch = math.deg(math.atan(dz, math.sqrt(dx * dx + dy * dy)))
function GetCamRot() return { x = pitch, y = 0.0, z = 0.0 } end
function GetCamCoord() return cp end
dofile(ROOT .. '/resources/[dev]/pickax_jobbuilder/client/labscene.lua')

local sz = LabScene.findSurface(q)
assert(math.abs(sz - 30.974) < 0.001, 'plateau trouvé par rayon ' .. sz)
SHAPE_HIT[1] = 0
assert(math.abs(LabScene.findSurface(q) - 30.924) < 0.001, 'repli sur Surface')
local sc = LabScene.init(q, 1, { fov = 45.0 })
assert(sc and sc.rel > 0 and sc.potR == 0.15, 'init')
-- le centre de l'écran tombe sur le point visé
local c = LabScene._onPlane(0.5, 0.5, q.z + 0.92)
assert(math.abs(c.x - q.x) < 0.01 and math.abs(c.y - q.y) < 0.01, ('centre %.3f %.3f'):format(c.x, c.y))
-- en haut de l'écran = plus loin de la caméra ; à droite = x croissant
local up, right = LabScene._onPlane(0.5, 0.2, q.z + 0.92), LabScene._onPlane(0.8, 0.5, q.z + 0.92)
assert(up.y > c.y and right.x > c.x, 'orientation')
-- échelle : un mètre sur la table ≈ rel × hauteur d'écran
local a, b = LabScene._onPlane(0.5, 0.5, q.z + 0.92), LabScene._onPlane(0.5, 0.5 - sc.rel * 0.2, q.z + 0.92)
local dist = math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
assert(dist > 0.18 and dist < 0.27, ('échelle %.3f'):format(dist))

local mask = string.rep('1', 100) .. string.rep('0', 44)
local scenes = {
    { t = 'add', bowl = { .5, .5 }, prog = .5, hold = 1, p = { .5, .4 }, d = 1, c = '#5f8f3c', ar = 1.78 },
    { t = 'scrape', pot = { .5, .5 }, rn = .2, rm = .15, mask = mask, p = { .5, .5 }, d = 1, c = '#e8ece8', ar = 1.78 },
    { t = 'stir', pot = { .5, .5 }, swirl = 2.0, rm = .12, p = { .5, .5 }, d = 1, c = '#8a7a3b', ar = 1.78 },
    { t = 'heat', pot = { .5, .5 }, temp = .8, lo = .45, hi = .7, p = { .5, .5 }, d = 0, c = '#7a5a2a', ar = 1.78 },
    { t = 'pour', cur = 0, drag = 1, pots = { { p = { .4, .45 }, f = .3 }, { p = { .6, .45 }, f = 0 } },
      bowls = { { p = { .4, .35 }, f = .7, pour = .3, done = 0 }, { p = { .7, .7 }, f = 1, pour = 0, done = 0 } }, p = { .4, .35 }, d = 1, c = '#8a7a3b', ar = 1.78 },
    { t = 'timing', pos = { .5, .5 }, x = .5, flash = .2, hits = 1, nc = 3, p = { .5, .5 }, d = 0, c = '', ar = 1.78 },
}
for _, s in ipairs(scenes) do
    LabScene.set(s)
    local before = calls.marker or 0
    -- une image de la boucle (le thread de LabScene)
    local f = threads[#threads]
    local gotErr
    local oldprint = print; print = function(m) gotErr = m end
    -- exécute exactement un tour : Wait() est neutre, on casse la boucle après un tour via stop() depuis Wait
    local n = 0; local oldWait = Wait; Wait = function() n = n + 1; if n >= 3 then LabScene.stop() end end
    f()
    Wait = oldWait; print = oldprint
    assert(not gotErr, s.t .. ' : ' .. tostring(gotErr))
    assert((calls.marker or 0) > before, s.t .. ' : rien de dessiné')
    -- repartir d'une scène neuve pour le test suivant
    LabScene.init(q, 1, { fov = 45.0 })
end
assert(calls.light and calls.light > 0, 'lueur de chauffe')
-- le bol existe (modèle 2e de la liste), les modèles inconnus sont ignorés
local alive = 0; for _ in pairs(ents) do alive = alive + 1 end
LabScene.stop()
do local m0 = calls.marker or 0; LabScene.init(q, 1, { fov = 45.0 }); local n = 0; local oW = Wait; Wait = function() n = n + 1; if n >= 3 then LabScene.stop() end end; threads[#threads]() ; Wait = oW; assert((calls.marker or 0) > m0, 'scène par défaut sans données') end
local left = 0; for _ in pairs(ents) do left = left + 1 end
assert(left == 0, 'objets restants : ' .. left)
Config.Real.Lab.Experience.Scene3D.Enabled = false
print('labscene_test : OK')
