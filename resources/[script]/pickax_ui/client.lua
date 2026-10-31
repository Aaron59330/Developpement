-- Affichage des menus (aucune prise de focus NUI) + fenêtre de saisie exports.pickax_ui:Input (seul moment où le focus est pris).
local KVP = 'pickax_ui:settings2'
local DEFAULTS = {
    banner = true, style = 'dore', size = 'md',
    accent = (PickaxTheme and PickaxTheme.hex) or '#fdc27d', bg = '', text = '', selbg = '', selborder = '',
    btnRadius = 12, cardRadius = 18,
    uiBtn = -1, uiTab = -1, uiCard = -1, uiField = -1, uiFrame = -1, uiFill = 'def',   -- forme de TOUTES les interfaces (-1 = défaut du style)
    sound = true, volume = 60,
}
local STYLES = { noir = true, verre = true, clair = true, neon = true, bleu = true, arcade = true, pinata = true, dore = true }
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

-- une seule fois : le style « Doré » devient le style par défaut, même pour ceux qui avaient mémorisé l'ancien « noir »
if GetResourceKvpString('pickax_ui:dore_default') ~= '1' then
    if settings.style == 'noir' then settings.style = 'dore' end
    SetResourceKvp('pickax_ui:dore_default', '1')
    SetResourceKvp(KVP, json.encode(settings))
end

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
local MOUSE = { [24] = 'Clic gauche', [25] = 'Clic droit', [14] = 'Molette ↓', [15] = 'Molette ↑', [16] = 'Molette ↓', [17] = 'Molette ↑', [348] = 'Clic molette' }
exports('ControlKey', function(control, group)
    local ok, s = pcall(GetControlInstructionalButton, group or 0, control, true)
    if ok and type(s) == 'string' and s:sub(1, 2) == 't_' then return (s:sub(3):gsub('^%l', string.upper)) end
    return MOUSE[control] or '?'
end)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then KEYBARS, KEYORDER = {}, {} end end)
