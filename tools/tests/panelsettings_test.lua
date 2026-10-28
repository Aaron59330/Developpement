-- panelsettings.lua des builders : application des réglages du panel, restauration de la valeur d'origine, schéma cohérent.
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
local handler
function AddEventHandler(n, f) if n == 'pickax_settings:changed' then handler = f end end
function CreateThread() end
function Wait() end
function GetResourceState() return 'missing' end
function IsDuplicityVersion() return true end
function vector3(x, y, z) return { x = x, y = y, z = z } end
vector2 = function(x, y) return { x = x, y = y } end
local function load(res, cfg)
    Config = cfg; handler = nil
    dofile(ROOT .. '/resources/[dev]/' .. res .. '/panelsettings.lua')
    return handler
end
-- schéma
Settings = {}
dofile(ROOT .. '/resources/[dev]/pickax_settings/config.lua')
local def, n = {}, 0
for _, d in ipairs(Settings.Schema) do ok(not def[d.key], 'clé en double : ' .. d.key) def[d.key] = d n = n + 1 end
ok(n <= 300, 'schéma ≤ 300 réglages (limite du panel) : ' .. n)
for _, d in ipairs(Settings.Schema) do
    if d.type == 'number' then ok(d.min and d.max and d.default >= d.min and d.default <= d.max, 'défaut hors bornes : ' .. d.key) end
    if d.type == 'select' then local f = false for _, o in ipairs(d.options) do if o[1] == d.default then f = true end end ok(f, 'défaut hors options : ' .. d.key) end
    ok(#d.key <= 60 and d.key:match('^[a-z0-9_]+$'), 'clé invalide : ' .. d.key)
end
-- chaque ligne du MAP existe dans le schéma, et son défaut = la valeur du config.lua
local function configOf(res, rootName)
    Config = { Real = { Lab = {} } }
    if res == 'pickax_gangbuilder' then Config.Tablet = {} end
    if res == 'pickax_illegalbuilder' then Config.Max = {} Config.Templates = { drug = {}, robbery = {}, gofast = {} } Config.UI = {} Config.Marker = {} end
    PickaxTheme = nil
    local ok2, err = pcall(dofile, ROOT .. '/resources/[dev]/' .. res .. '/config.lua')
    return ok2 and Config or nil, err
end
for _, res in ipairs({ 'pickax_gangbuilder', 'pickax_jobbuilder', 'pickax_illegalbuilder' }) do
    local cfg = configOf(res)
    ok(cfg, res .. ' : config.lua doit se charger dans le test')
    if cfg then
        local h = load(res, cfg)
        ok(h, res .. ' : écoute pickax_settings:changed')
        local mapSrc = io.open(ROOT .. '/resources/[dev]/' .. res .. '/panelsettings.lua'):read('a')
        for key, path in mapSrc:gmatch("{ '([%w_]+)', '([%w%.]+)' }") do
            ok(def[key], res .. ' : ' .. key .. ' absent du schéma')
            local t = cfg
            for seg in path:gmatch('[^%.]+') do if type(t) == 'table' then t = t[tonumber(seg) or seg] else t = nil end end
            ok(t ~= nil, res .. ' : chemin introuvable dans le config : ' .. path)
            ok(t == def[key].default, ('%s : défaut du schéma (%s) ≠ config (%s) pour %s'):format(res, tostring(def[key].default), tostring(t), key))
        end
    end
end
-- application + restauration
local cfg = { Territories = { CaptureSeconds = 120, Reward = 500 }, TurfWar = { Enabled = true } }
local h = load('pickax_gangbuilder', cfg)
h({ gb_capture_seconds = 60, gb_turf_enabled = false, gb_income_reward = 500 }, { gb_capture_seconds = 60, gb_turf_enabled = false })
ok(cfg.Territories.CaptureSeconds == 60, 'réglage appliqué')
ok(cfg.TurfWar.Enabled == false, 'booléen false appliqué')
ok(cfg.Territories.Reward == 500, 'réglage non modifié inchangé')
h({ gb_capture_seconds = 120 }, {})
ok(cfg.Territories.CaptureSeconds == 120 and cfg.TurfWar.Enabled == true, 'valeur d\'origine restaurée')
local called = 0
function PanelSettingsChanged() called = called + 1 end
h({ gb_capture_seconds = 90 }, { gb_capture_seconds = 90 })
ok(called == 1 and cfg.Territories.CaptureSeconds == 90, 'hook appelé à chaque changement')
h({ gb_capture_seconds = 90 }, { gb_capture_seconds = 90 })
ok(called == 1, 'pas de hook si rien ne change')
print(('panelsettings_test : %d vérifications OK'):format(checks))
