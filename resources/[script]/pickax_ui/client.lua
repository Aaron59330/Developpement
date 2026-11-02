-- Affichage des menus (aucune prise de focus NUI) + fenêtre de saisie exports.pickax_ui:Input (seul moment où le focus est pris).
local KVP = 'pickax_ui:settings2'
local DEFAULTS = {
    banner = true, style = 'dore', size = 'md',
    accent = (PickaxTheme and PickaxTheme.hex) or '#fdc27d', bg = '', text = '', selbg = '', selborder = '',
    btnRadius = 12, cardRadius = 18,
    uiBtn = -1, uiTab = -1, uiCard = -1, uiField = -1, uiFrame = -1, uiFill = 'def',   -- forme de TOUTES les interfaces (-1 = défaut du style)
    sound = true, volume = 60,
}
local STYLES = { dore = true }   -- un seul style de menus
local SIZES = { sm = true, md = true, lg = true }
local COLOR_KEYS = { accent = true, bg = true, text = true, selbg = true, selborder = true }
local SHAPE_ROUND = { -1, 0, 6, 12, 18, 24, 999 }
local SHAPE_BOX = { -1, 0, 6, 12, 18, 24 }
local RADIUS = { btnRadius = { 0, 6, 12, 18, 24, 999 }, cardRadius = { 0, 8, 14, 18, 24, 28 },
    uiBtn = SHAPE_ROUND, uiTab = SHAPE_ROUND, uiCard = SHAPE_BOX, uiField = SHAPE_BOX, uiFrame = SHAPE_BOX }
local FILLS = { def = true, outline = true, glow = true }

local settings = {}
for k, v in pairs(DEFAULTS) do settings[k] = v end

local function isHex(v) return type(v) == 'string' and v:match('^#%x%x%x%x%x%x$') ~= nil end
local function inList(list, v) for i = 1, #list do if list[i] == v then return true end end return false end

local function validate(key, value)
    if key == 'banner' or key == 'sound' then return true, value and true or false end
    if key == 'volume' then value = tonumber(value) return value ~= nil and value >= 10 and value <= 100, value and math.floor(value / 10 + 0.5) * 10 end
    if key == 'style' then return STYLES[value] == true, value end
    if key == 'size' then return SIZES[value] == true, value end
    if COLOR_KEYS[key] then
        if value == '' and key ~= 'accent' then return true, '' end
        if isHex(value) then return true, value:lower() end
        return false
    end
    if key == 'uiFill' then return FILLS[value] == true, value end
    if RADIUS[key] then return inList(RADIUS[key], value), value end
    return false
end

local saved = GetResourceKvpString(KVP)
if saved and saved ~= '' then
    local ok, t = pcall(json.decode, saved)
    if ok and type(t) == 'table' then
        for k in pairs(DEFAULTS) do
            local good, v = validate(k, t[k])
            if k == 'accent' and v == '#fdc27d' then v = DEFAULTS.accent end   -- ancien défaut mémorisé : on suit la couleur du thème
            if good then settings[k] = v end
        end
    end
end

-- Préférences simplifiées : seuls restent réglables la taille, la couleur principale, la couleur et les bords des boutons, et les sons.
-- Les anciens choix mémorisés (style, fond, texte, bordure, formes, bannière) sont remis à zéro une seule fois.
if GetResourceKvpString('pickax_ui:simple_prefs') ~= '1' then
    for _, k in ipairs({ 'bg', 'text', 'selborder' }) do settings[k] = '' end
    settings.cardRadius, settings.banner, settings.style = DEFAULTS.cardRadius, true, 'dore'
    for _, k in ipairs({ 'uiBtn', 'uiTab', 'uiCard', 'uiField', 'uiFrame' }) do settings[k] = -1 end
    settings.uiFill = 'def'
    SetResourceKvp('pickax_ui:simple_prefs', '1')
    SetResourceKvp(KVP, json.encode(settings))
end
settings.style = 'dore'

local shown, last = false, nil

local function push()
    if shown and last then
        last.cfg = settings
        SendNUIMessage({ a = 'menu', d = last })
    end
end

local function save() SetResourceKvp(KVP, json.encode(settings)) end

exports('Update', function(data)
    shown, last = true, data
    push()
end)

-- Son motion design d'un menu (click, confirm, tab, on, off, close, error…) ; respecte le réglage « Sons des menus »
exports('Sound', function(name)
    if not settings.sound or type(name) ~= 'string' then return end
    SendNUIMessage({ a = 'snd', n = name, v = settings.volume })
end)

exports('Hide', function()
    if not shown then return end
    shown, last = false, nil
    SendNUIMessage({ a = 'hide' })
end)

-- Réglage commun des sons (menu personnel → Sons des menus / Volume) : diffusé à toutes les interfaces
local function soundEvent() TriggerEvent('pickax_ui:settings', { sound = settings.sound, volume = settings.volume }) end
exports('GetSound', function() return { sound = settings.sound, volume = settings.volume } end)

exports('GetSettings', function()
    local t = {}
    for k in pairs(DEFAULTS) do t[k] = settings[k] end
    return t
end)

exports('SetSetting', function(key, value)
    local good, v = validate(key, value)
    if not good then return false end
    settings[key] = v
    save()
    push()
    if key == 'sound' or key == 'volume' then soundEvent() end
    return true
end)

exports('ResetSettings', function()
    for k, v in pairs(DEFAULTS) do settings[k] = v end
    save()
    push()
    soundEvent()
end)

-- Forme des interfaces (boutons, onglets, cartes, champs, cadre) : lue par theme.js dans toutes les interfaces du serveur
RegisterNUICallback('getShape', function(_, cb)
    cb({ btn = settings.uiBtn, tab = settings.uiTab, card = settings.uiCard, field = settings.uiField, frame = settings.uiFrame, fill = settings.uiFill })
end)

-- Ouvre un lien (https uniquement) dans le navigateur du joueur
exports('OpenUrl', function(url)
    if type(url) ~= 'string' or not url:match('^https://[%w%.%-/_%?=&%%#:~+]+$') then return false end
    SendNUIMessage({ a = 'url', u = url })
    return true
end)

-- Fenêtre de saisie : remplace le clavier natif. Bloque le thread appelant jusqu'à la réponse ; retourne le texte saisi, ou nil si annulé.
-- opts = { title, hint, placeholder, default, max, numeric }
local inputPromise = nil

exports('Input', function(opts)
    if inputPromise then return nil end
    opts = type(opts) == 'table' and opts or {}
    local p = promise.new()
    inputPromise = p
    SetNuiFocus(true, true)
    SendNUIMessage({
        a = 'input', cfg = settings, v = settings.sound and settings.volume or 0,
        d = {
            title = tostring(opts.title or 'Saisie'), hint = opts.hint and tostring(opts.hint) or '',
            placeholder = opts.placeholder and tostring(opts.placeholder) or '', default = opts.default and tostring(opts.default) or '',
            max = math.max(1, math.min(200, tonumber(opts.max) or 60)), numeric = opts.numeric == true,
        },
    })
    local value = Citizen.Await(p)
    inputPromise = nil
    SetNuiFocus(false, false)
    return value
end)

-- Menu de choix (cartes) : retourne l'index (1-based) de l'option choisie, ou nil si annulé (seulement si opts.cancellable)
-- opts = { title, hint, cancellable, options = { { label, description, icon }, ... } }
local choosePromise = nil

exports('Choose', function(opts)
    if choosePromise or inputPromise then return nil end
    opts = type(opts) == 'table' and opts or {}
    local list = {}
    for i, o in ipairs(type(opts.options) == 'table' and opts.options or {}) do
        list[i] = { label = tostring(o.label or ('Choix ' .. i)), description = o.description and tostring(o.description) or '', icon = o.icon and tostring(o.icon) or nil }
    end
    if #list == 0 then return nil end
    local p = promise.new()
    choosePromise = p
    SetNuiFocus(true, true)
    SendNUIMessage({
        a = 'choose', cfg = settings, v = settings.sound and settings.volume or 0,
        d = { title = tostring(opts.title or 'Choix'), hint = opts.hint and tostring(opts.hint) or '', options = list, cancellable = opts.cancellable == true, align = opts.align == 'right' and 'right' or 'center' },
    })
    local value = Citizen.Await(p)
    choosePromise = nil
    SetNuiFocus(false, false)
    return value
end)

RegisterNUICallback('chooseDone', function(data, cb)
    cb('ok')
    if choosePromise then
        local i = data and tonumber(data.index)
        choosePromise:resolve(i and math.floor(i) or nil)
    end
end)

RegisterNUICallback('inputDone', function(data, cb)
    cb('ok')
    if inputPromise then
        local v = data and data.value
        inputPromise:resolve(type(v) == 'string' and v or nil)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    if inputPromise then inputPromise:resolve(nil) end
    if choosePromise then choosePromise:resolve(nil) end
end)


-- ───────────── Barre d'aide des touches (remplace les « instructional buttons » natifs de GTA) ─────────────
-- exports.pickax_ui:KeysShow('noclip', { { key = 'F2', label = 'Désactiver le Noclip' }, { key = { 'Q', 'D' }, label = 'Tourner' } })
-- exports.pickax_ui:KeysHide('noclip')      plusieurs barres peuvent coexister : la dernière affichée est visible
local KEYBARS, KEYORDER = {}, {}
local function pushKeys()
    local top
    for i = #KEYORDER, 1, -1 do if KEYBARS[KEYORDER[i]] then top = KEYBARS[KEYORDER[i]] break end end
    SendNUIMessage({ a = 'keys', items = top })
end
exports('KeysShow', function(id, items)
    id = tostring(id or 'default')
    if type(items) ~= 'table' then return end
    if not KEYBARS[id] then KEYORDER[#KEYORDER + 1] = id end
    KEYBARS[id] = items
    pushKeys()
end)
exports('KeysHide', function(id)
    id = tostring(id or 'default')
    if not KEYBARS[id] then return end
    KEYBARS[id] = nil
    for i, v in ipairs(KEYORDER) do if v == id then table.remove(KEYORDER, i) break end end
    pushKeys()
end)

-- Nom lisible d'une touche à partir d'un contrôle GTA (ex. 38 → « E »)
-- touches que GTA dessine comme des icônes (pas du texte) : on donne leur nom nous-mêmes
local NAMED = { [24] = 'Clic gauche', [25] = 'Clic droit', [14] = 'Molette ↓', [15] = 'Molette ↑', [16] = 'Molette ↓', [17] = 'Molette ↑', [348] = 'Clic molette',
    [21] = 'Maj', [22] = 'Espace', [36] = 'Ctrl', [19] = 'Alt', [37] = 'Tab', [18] = 'Entrée', [191] = 'Entrée', [201] = 'Entrée', [177] = 'Retour', [200] = 'Échap', [202] = 'Retour',
    [288] = 'F1', [289] = 'F2', [170] = 'F3', [166] = 'F5', [167] = 'F6', [168] = 'F7', [56] = 'F9', [57] = 'F10', [172] = '↑', [173] = '↓', [174] = '←', [175] = '→', [178] = 'Suppr',
    [73] = 'X', [38] = 'E', [51] = 'E', [74] = 'H', [75] = 'F', [47] = 'G', [45] = 'R', [140] = 'R', [44] = 'Q', [26] = 'C', [29] = 'B', [244] = 'M', [246] = 'Y', [249] = 'N', [303] = 'U', [311] = 'K', [85] = 'A', [48] = 'W', [46] = 'E', [80] = 'R', [86] = 'E', [71] = 'W', [72] = 'S', [23] = 'F' }
exports('ControlKey', function(control, group)
    local ok, s = pcall(GetControlInstructionalButton, group or 0, control, true)
    if ok and type(s) == 'string' and s:sub(1, 2) == 't_' and #s > 2 then return (s:sub(3):gsub('^%l', string.upper)) end
    return NAMED[control] or 'Touche'
end)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then KEYBARS, KEYORDER = {}, {} end end)


-- ───────────── Menu contextuel (clic droit / main levée) : dessiné ici, la logique reste dans pickax_core/players/contextMenu ─────────────
-- exports.pickax_ui:CtxShow({ { x, y, w, h, title, items = { { y, h, text, right, kind, enabled, hovered, open, checked, sep } } } })   exports.pickax_ui:CtxHide()
exports('CtxShow', function(menus) SendNUIMessage({ a = 'ctx', menus = menus }) end)
exports('CtxHide', function() SendNUIMessage({ a = 'ctx', menus = false }) end)


-- ───────────── Légende de la carte (remplace la liste de blips de GTA) ─────────────
-- Les ressources enregistrent leurs blips : exports.pickax_ui:LegendAdd(blip, nom, sprite, couleur). Les blips de même nom sont regroupés (« Garage 1/3 »).
-- Ouverture : touche M (modifiable dans Paramètres FiveM → Raccourcis) ou /carte. La carte native s'ouvre et le panneau de légende s'affiche à droite.
local LEG, LEGHIDDEN, LEGCUR, legOpen = {}, {}, {}, false
do
    local raw = GetResourceKvpString('pickax_ui:legend_hidden')
    if raw and raw ~= '' then local ok, t = pcall(json.decode, raw) if ok and type(t) == 'table' then for _, k in ipairs(t) do LEGHIDDEN[k] = true end end end
end
local function legSave() local t = {} for k in pairs(LEGHIDDEN) do t[#t + 1] = k end SetResourceKvp('pickax_ui:legend_hidden', json.encode(t)) end
local function legKey(name) return tostring(name or ''):lower() end

local function legApply(rec, hidden)
    if not DoesBlipExist(rec.blip) then return end
    if hidden then SetBlipDisplay(rec.blip, 0) else SetBlipDisplay(rec.blip, rec.display or 4) end
end

exports('LegendAdd', function(blip, name, sprite, color)
    if not blip or blip == 0 or type(name) ~= 'string' or name == '' then return end
    local k = legKey(name)
    local rec = { blip = blip, key = k, name = name, sprite = tonumber(sprite) or 1, color = tonumber(color) or 0, display = GetBlipInfoIdDisplay(blip) }
    if rec.display == 0 then rec.display = 4 end
    LEG[blip] = rec
    -- retire ce blip de la liste native de GTA (la nôtre la remplace)
    pcall(SetBlipHiddenOnLegend, blip, true)
    if LEGHIDDEN[k] then legApply(rec, true) end
end)
exports('LegendRemove', function(blip) LEG[blip] = nil end)

local function legGroups()
    local groups, order = {}, {}
    for blip, rec in pairs(LEG) do
        if not DoesBlipExist(blip) then LEG[blip] = nil
        else
            local g = groups[rec.key]
            if not g then g = { key = rec.key, name = rec.name, sprite = rec.sprite, color = rec.color, blips = {} } groups[rec.key] = g order[#order + 1] = g end
            g.blips[#g.blips + 1] = blip
        end
    end
    table.sort(order, function(a, b) return a.name:lower() < b.name:lower() end)
    return order
end

local function legPayload()
    local out = {}
    for _, g in ipairs(legGroups()) do
        table.sort(g.blips)
        local cur = math.max(1, math.min(#g.blips, LEGCUR[g.key] or 1))
        LEGCUR[g.key] = cur
        local c = GetBlipInfoIdCoord(g.blips[cur])
        local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(c.x, c.y, c.z))
        out[#out + 1] = { key = g.key, name = g.name, sprite = g.sprite, color = g.color, n = #g.blips, idx = cur, hidden = LEGHIDDEN[g.key] == true, street = street }
    end
    return out
end

local function legGroup(key)
    for _, g in ipairs(legGroups()) do if g.key == key then table.sort(g.blips) return g end end
end

local legFlash
local function legClose()
    if not legOpen then return end
    legOpen = false
    SetNuiFocus(false, false)
    if legFlash and DoesBlipExist(legFlash) then SetBlipFlashes(legFlash, false) end
    legFlash = nil
    SendNUIMessage({ a = 'leg', open = false })
end

local function legOpenNow()
    if legOpen then return end
    legOpen = true
    if not IsPauseMenuActive() then
        ActivateFrontendMenu(`FE_MENU_VERSION_MP_PAUSE`, false, -1)
        Wait(150)
        PauseMenuceptionGoDeeper(0)
    end
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({ a = 'leg', open = true, groups = legPayload() })
    CreateThread(function()
        Wait(600)
        while legOpen do
            if not IsPauseMenuActive() then legClose() break end
            Wait(250)
        end
    end)
end

RegisterCommand('carte', function() if legOpen then legClose() else legOpenNow() end end, false)
RegisterKeyMapping('carte', 'Carte avec légende des lieux', 'keyboard', 'M')

RegisterNUICallback('legClose', function(_, cb) legClose() if IsPauseMenuActive() then SetFrontendActive(false) end cb(1) end)
RegisterNUICallback('legToggle', function(d, cb)
    local g = legGroup(d.key)
    if g then
        local hide = not LEGHIDDEN[g.key]
        LEGHIDDEN[g.key] = hide or nil
        for _, b in ipairs(g.blips) do if LEG[b] then legApply(LEG[b], hide) end end
        legSave()
    end
    cb(legPayload())
end)
RegisterNUICallback('legAll', function(d, cb)
    for _, g in ipairs(legGroups()) do
        LEGHIDDEN[g.key] = d.hide and true or nil
        for _, b in ipairs(g.blips) do if LEG[b] then legApply(LEG[b], d.hide) end end
    end
    legSave()
    cb(legPayload())
end)
-- met en évidence le blip courant d'un groupe (clignote + repère sur la carte) ; les autres du groupe redeviennent normaux
local function legFocus(g, place)
    if legFlash and DoesBlipExist(legFlash) then SetBlipFlashes(legFlash, false) end
    legFlash = nil
    if not g then return end
    local cur = math.max(1, math.min(#g.blips, LEGCUR[g.key] or 1))
    local b = g.blips[cur]
    if not DoesBlipExist(b) then return end
    SetBlipFlashes(b, true)
    legFlash = b
    local c = GetBlipInfoIdCoord(b)
    if place ~= false then SetNewWaypoint(c.x + 0.0, c.y + 0.0) end
    pcall(function() SetRadarZoomToBlip(b, 0.0) end)
end
RegisterNUICallback('legStep', function(d, cb)
    local g = legGroup(d.key)
    if g then
        LEGCUR[g.key] = ((((LEGCUR[g.key] or 1) - 1 + (d.dir or 1)) % #g.blips) + 1)
        legFocus(g, true)
    end
    cb(legPayload())
end)
RegisterNUICallback('legSelect', function(d, cb) legFocus(legGroup(d.key), true) cb(1) end)
RegisterNUICallback('legGo', function(d, cb)
    local g = legGroup(d.key)
    if g then
        local c = GetBlipInfoIdCoord(g.blips[math.max(1, math.min(#g.blips, LEGCUR[g.key] or 1))])
        SetNewWaypoint(c.x + 0.0, c.y + 0.0)
    end
    cb(1)
end)
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if legOpen then SetNuiFocus(false, false) end
    for _, rec in pairs(LEG) do pcall(SetBlipHiddenOnLegend, rec.blip, false) if LEGHIDDEN[rec.key] then legApply(rec, false) end end
end)


-- La touche P (carte native) ouvre aussi la légende : on la détecte quand la carte s'affiche
CreateThread(function()
    local armed = false
    while true do
        Wait(0)
        if not legOpen and not IsPauseMenuActive() then
            if IsDisabledControlJustReleased(0, 199) or IsControlJustReleased(0, 199) or IsDisabledControlJustReleased(0, 200) or IsControlJustReleased(0, 200) then armed = true end
        end
        if armed then
            armed = false
            local t = 0
            while not IsPauseMenuActive() and t < 20 do Wait(50) t = t + 1 end
            if IsPauseMenuActive() and not legOpen then Wait(300) legOpenNow() end
        end
    end
end)
