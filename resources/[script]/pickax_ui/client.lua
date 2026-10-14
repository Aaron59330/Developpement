-- Affichage seul : aucune prise de focus NUI, le clavier reste géré par RageUI (CorePickax).
local KVP = 'pickax_ui:settings'
local DEFAULTS = { banner = true, style = 'noir', size = 'md', accent = '#00a4ff' }
local STYLES = { noir = true, verre = true, clair = true, neon = true, bleu = true }
local SIZES = { sm = true, md = true, lg = true }

local settings = {}
for k, v in pairs(DEFAULTS) do settings[k] = v end

local saved = GetResourceKvpString(KVP)
if saved and saved ~= '' then
    local ok, t = pcall(json.decode, saved)
    if ok and type(t) == 'table' then
        if type(t.banner) == 'boolean' then settings.banner = t.banner end
        if STYLES[t.style] then settings.style = t.style end
        if SIZES[t.size] then settings.size = t.size end
        if type(t.accent) == 'string' and t.accent:match('^#%x%x%x%x%x%x$') then settings.accent = t.accent end
    end
end

local shown, last = false, nil

local function push()
    if shown and last then
        last.cfg = settings
        SendNUIMessage({ a = 'menu', d = last })
    end
end

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
    return { banner = settings.banner, style = settings.style, size = settings.size, accent = settings.accent }
end)

exports('SetSetting', function(key, value)
    if key == 'banner' then value = value and true or false
    elseif key == 'style' then if not STYLES[value] then return end
    elseif key == 'size' then if not SIZES[value] then return end
    elseif key == 'accent' then if type(value) ~= 'string' or not value:match('^#%x%x%x%x%x%x$') then return end
    else return end
    settings[key] = value
    SetResourceKvp(KVP, json.encode(settings))
    push()
end)

exports('ResetSettings', function()
    for k, v in pairs(DEFAULTS) do settings[k] = v end
    SetResourceKvp(KVP, json.encode(settings))
    push()
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)
