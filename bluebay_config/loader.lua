-- Charge config.json (généré depuis panel/index.html) et l'expose aux autres ressources.
--
--   local cfg = exports['bluebay_config']:GetConfig()
--   local accent = exports['bluebay_config']:GetAccent()       -- "#00a4ff"
--   local r, g, b = exports['bluebay_config']:GetAccentRGB()   -- 0, 164, 255
--   exports['bluebay_config']:DrawMarker('garage', coords)     -- à appeler à chaque frame
--   exports['bluebay_config']:GetLogoUrl()                     -- URL NUI du logo

local resourceName = GetCurrentResourceName()
local config = {}

local function hexToRgb(hex)
    hex = tostring(hex or '#00a4ff'):gsub('#', '')
    if #hex == 3 then hex = hex:gsub('.', '%0%0') end
    return tonumber(hex:sub(1, 2), 16) or 0, tonumber(hex:sub(3, 4), 16) or 164, tonumber(hex:sub(5, 6), 16) or 255
end

local function load()
    local raw = LoadResourceFile(resourceName, 'config.json')
    local ok, decoded = pcall(json.decode, raw or '{}')
    config = (ok and decoded) or {}
end

load()

exports('GetConfig', function() return config end)
exports('GetAccent', function() return (config.brand and config.brand.accent) or '#00a4ff' end)
exports('GetAccentRGB', function() return hexToRgb(config.brand and config.brand.accent) end)
exports('GetLogoUrl', function()
    return ('https://cfx-nui-%s/%s'):format(resourceName, (config.brand and config.brand.logo) or 'logo.png')
end)
exports('GetMenu', function(name) return config.menus and config.menus[name] or {} end)

exports('GetMarker', function(name)
    local markers = config.markers or {}
    for _, m in ipairs(markers.list or {}) do
        if m.name == name then return m end
    end
    return markers.default or {}
end)

if not IsDuplicityVersion() then
    -- Dessine un marker depuis la config (client uniquement), à appeler à chaque frame.
    exports('DrawMarker', function(name, coords)
        local m = exports[resourceName]:GetMarker(name)
        local r, g, b = hexToRgb(m.color)
        local ped = PlayerPedId()
        if #(GetEntityCoords(ped) - coords) > (m.drawDistance or 15.0) then return false end
        DrawMarker(m.type or 1, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            m.sizeX or 1.0, m.sizeY or 1.0, m.sizeZ or 1.0, r, g, b, m.alpha or 160,
            m.bobUpDown == true, false, 2, m.rotate == true, nil, nil, false)
        return true
    end)
end
