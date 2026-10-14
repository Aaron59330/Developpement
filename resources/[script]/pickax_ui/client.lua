-- Affichage seul : aucune prise de focus NUI, le clavier reste géré par RageUI (CorePickax).
local KVP = 'pickax_ui:settings2'
local DEFAULTS = {
    banner = true, style = 'noir', size = 'md',
    accent = '#00a4ff', bg = '', text = '', selbg = '', selborder = '',
    btnRadius = 12, cardRadius = 18,
}
local STYLES = { noir = true, verre = true, clair = true, neon = true, bleu = true }
local SIZES = { sm = true, md = true, lg = true }
local COLOR_KEYS = { accent = true, bg = true, text = true, selbg = true, selborder = true }
local RADIUS = { btnRadius = { 0, 6, 12, 18, 24, 999 }, cardRadius = { 0, 8, 14, 18, 24, 28 } }

local settings = {}
for k, v in pairs(DEFAULTS) do settings[k] = v end

local function isHex(v) return type(v) == 'string' and v:match('^#%x%x%x%x%x%x$') ~= nil end
local function inList(list, v) for i = 1, #list do if list[i] == v then return true end end return false end

local function validate(key, value)
    if key == 'banner' then return true, value and true or false end
    if key == 'style' then return STYLES[value] == true, value end
    if key == 'size' then return SIZES[value] == true, value end
    if COLOR_KEYS[key] then
        if value == '' and key ~= 'accent' then return true, '' end
        if isHex(value) then return true, value:lower() end
        return false
    end
    if RADIUS[key] then return inList(RADIUS[key], value), value end
    return false
end

local saved = GetResourceKvpString(KVP)
if saved and saved ~= '' then
    local ok, t = pcall(json.decode, saved)
    if ok and type(t) == 'table' then
        for k in pairs(DEFAULTS) do
            local good, v = validate(k, t[k])
            if good then settings[k] = v end
        end
    end
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

exports('Hide', function()
    if not shown then return end
    shown, last = false, nil
    SendNUIMessage({ a = 'hide' })
end)

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
    return true
end)

exports('ResetSettings', function()
    for k, v in pairs(DEFAULTS) do settings[k] = v end
    save()
    push()
end)

-- Ouvre un lien (https uniquement) dans le navigateur du joueur
exports('OpenUrl', function(url)
    if type(url) ~= 'string' or not url:match('^https://[%w%.%-/_%?=&%%#:~+]+$') then return false end
    SendNUIMessage({ a = 'url', u = url })
    return true
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)
