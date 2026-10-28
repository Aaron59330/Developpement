-- Mode de jeu facile / difficile : fusion des réglages, cohérence du schéma et application réelle sur les configs des builders.
local ROOT = os.getenv('ROOT') or '.'
local checks = 0
local function ok(c, m) checks = checks + 1 assert(c, m) end
function IsDuplicityVersion() return true end
function vector3(x, y, z) return { x = x, y = y, z = z } end
vector2 = function(x, y) return { x = x, y = y } end
function GetResourceState() return 'missing' end
function CreateThread() end function Wait() end
local handler
function AddEventHandler(n, f) if n == 'pickax_settings:changed' then handler = f end end

Settings = {}
dofile(ROOT .. '/resources/[dev]/pickax_settings/config.lua')
local DEF = {}
for _, d in ipairs(Settings.Schema) do DEF[d.key] = d end
ok(DEF.game_mode and DEF.game_mode.default == 'difficile', 'le mode par défaut est « difficile » (comportement actuel de la base)')

-- cohérence : chaque valeur « facile » a le type du réglage, est dans ses bornes et existe dans un panelsettings.lua
local mapped = {}
for _, res in ipairs({ 'pickax_gangbuilder', 'pickax_jobbuilder', 'pickax_illegalbuilder' }) do
    local src = io.open(ROOT .. '/resources/[dev]/' .. res .. '/panelsettings.lua'):read('a')
    for key in src:gmatch("{ '([%w_]+)', '[%w%.]+' }") do mapped[key] = res end
end
local nEasy = 0
for k, d in pairs(DEF) do
    if d.easy ~= nil then
        nEasy = nEasy + 1
        ok(type(d.easy) == type(d.default), k .. ' : type de la valeur facile')
        if d.type == 'number' then ok(d.easy >= d.min and d.easy <= d.max, k .. ' : valeur facile dans les bornes') end
        ok(mapped[k], k .. ' : appliqué par un panelsettings.lua (sinon le mode facile ne changerait rien)')
        ok(d.easy ~= d.default, k .. ' : la valeur facile diffère du défaut')
    end
end
ok(nEasy >= 15, nEasy .. ' réglages changent en mode facile')

-- fusion
local a = Settings.ActiveOverrides(DEF, {})
ok(next(a) == nil, 'difficile : aucun préréglage')
a = Settings.ActiveOverrides(DEF, { game_mode = 'facile' })
ok(a.jb_lab_enabled == false and a.gb_capture_seconds == 60 and a.ib_tablets_required == false and a.ib_street_chance == 85, 'facile : valeurs simplifiées actives')
ok(a.game_mode == 'facile', 'le mode lui-même reste dans les surcharges')
a = Settings.ActiveOverrides(DEF, { game_mode = 'facile', gb_capture_seconds = 200, jb_lab_enabled = true })
ok(a.gb_capture_seconds == 200 and a.jb_lab_enabled == true and a.gb_min_defenders == 0, 'un réglage modifié par le client passe avant le mode')
ok(Settings.ActiveOverrides(DEF, { gb_capture_seconds = 90 }).jb_lab_enabled == nil, 'sans mode facile, seuls les réglages modifiés comptent')

-- application réelle sur les configs
local function realConfig(res)
    Config = { Real = { Lab = {} }, Tablet = {} }
    if res == 'pickax_illegalbuilder' then Config.Max = {} Config.Templates = { drug = {}, robbery = {}, gofast = {} } Config.UI = {} Config.Marker = {} end
    assert(pcall(dofile, ROOT .. '/resources/[dev]/' .. res .. '/config.lua'))
    handler = nil
    dofile(ROOT .. '/resources/[dev]/' .. res .. '/panelsettings.lua')
    return Config, handler
end
local function allOf(over) local all = {} for k, d in pairs(DEF) do local v = over[k] if v == nil then v = d.default end all[k] = v end return all end
do
    local C, h = realConfig('pickax_gangbuilder')
    ok(C.Territories.CaptureSeconds == 120 and C.TurfWar.Enabled == true and C.HQ.Raid.Enabled == true, 'gangs : valeurs de départ (difficile)')
    local ov = Settings.ActiveOverrides(DEF, { game_mode = 'facile' }); h(allOf(ov), ov)
    ok(C.Territories.CaptureSeconds == 60 and C.Territories.MinDefenders == 0 and C.TurfWar.Enabled == false and C.HQ.Raid.Enabled == false and C.Conflicts.Enabled == false, 'gangs en facile : capture rapide, sans défenseurs requis, ni guerre de zone ni raids ni affrontements')
    ov = Settings.ActiveOverrides(DEF, {}); h(allOf(ov), ov)
    ok(C.Territories.CaptureSeconds == 120 and C.TurfWar.Enabled == true and C.HQ.Raid.Enabled == true, 'retour en difficile : valeurs d\'origine restaurées')
end
do
    local C, h = realConfig('pickax_jobbuilder')
    ok(C.Real.Lab.Experience.Enabled == true, 'labo : interactif au départ')
    local ov = Settings.ActiveOverrides(DEF, { game_mode = 'facile' }); h(allOf(ov), ov)
    ok(C.Real.Lab.Experience.Enabled == false and C.Real.Lab.Experience.Accidents.Enabled == false and C.Real.Lab.Toxic.Enabled == false, 'labo en facile : barre de progression, sans accident ni intoxication')
    ov = Settings.ActiveOverrides(DEF, { game_mode = 'facile', jb_lab_enabled = true }); h(allOf(ov), ov)
    ok(C.Real.Lab.Experience.Enabled == true and C.Real.Lab.Toxic.Enabled == false, 'facile mais labo interactif réactivé à la main')
end
do
    local C, h = realConfig('pickax_illegalbuilder')
    ok(C.Tablets.Required == true and C.StreetSales.RequireTablet == true and C.Purity.Enabled == true, 'illégal : tablettes et pureté au départ')
    local ov = Settings.ActiveOverrides(DEF, { game_mode = 'facile' }); h(allOf(ov), ov)
    ok(C.Tablets.Required == false and C.StreetSales.RequireTablet == false and C.Purity.Enabled == false and C.StreetRep.Enabled == false and C.StreetZones.Enabled == false, 'illégal en facile : sans tablettes, pureté, réputation ni quartiers')
    ok(C.StreetSales.AcceptChance == 85 and C.StreetSales.AlertChance == 5, 'illégal en facile : PNJ plus accueillants, moins d\'alertes')
end
print(('modes_test : %d vérifications OK'):format(checks))
