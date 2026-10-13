-- ─────────────────────────────── Territoires : blips, zone au sol, HUD de capture ───────────────────────────────
local territories = {}
local blips = {}

local function clearBlips()
    for _, b in ipairs(blips) do if DoesBlipExist(b) then RemoveBlip(b) end end
    blips = {}
end

local function hexRgb(hex)
    local r, g, b = tostring(hex or ''):match('^#(%x%x)(%x%x)(%x%x)$')
    if not r then return { 255, 255, 255 } end
    return { tonumber(r, 16), tonumber(g, 16), tonumber(b, 16) }
end

local function rebuild()
    clearBlips()
    local T = Config.Territories
    if not T.Enabled or not T.ShowBlips then return end
    for _, t in ipairs(territories) do
        pcall(function()
            local c = t.coords
            local colour = t.ownerBlip or T.NeutralColor
            local radius = AddBlipForRadius(c.x + 0.0, c.y + 0.0, c.z + 0.0, t.radius + 0.0)
            SetBlipColour(radius, colour)
            SetBlipAlpha(radius, T.BlipAlpha)
            blips[#blips + 1] = radius

            local icon = AddBlipForCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
            SetBlipSprite(icon, T.BlipSprite)
            SetBlipColour(icon, colour)
            SetBlipScale(icon, T.BlipScale + 0.0)
            SetBlipAsShortRange(icon, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(t.ownerLabel and ('%s — %s'):format(t.label, t.ownerLabel) or ('%s (libre)'):format(t.label))
            EndTextCommandSetBlipName(icon)
            blips[#blips + 1] = icon
        end)
    end
end

AddEventHandler('gangbuilder:internal:territories', function(list)
    territories = list or {}
    rebuild()
end)
RegisterNetEvent('gangbuilder:client:territories', function(list)
    territories = list or {}
    rebuild()
end)
AddEventHandler('gangbuilder:internal:configChanged', rebuild)

-- HUD de capture : envoyé par le serveur aux joueurs présents dans une zone (nil = sortie de zone)
RegisterNetEvent('gangbuilder:client:zone', function(data)
    SendNUIMessage({ action = 'zone', data = data })
end)

-- Zone dessinée au sol quand on est proche
CreateThread(function()
    while true do
        local sleep = 1000
        local T = Config.Territories
        if T.Enabled and T.DrawZone and #territories > 0 and not IsUIOpen() then
            local pos = GetEntityCoords(PlayerPedId())
            for _, t in ipairs(territories) do
                local c = t.coords
                local d = #(vector2(pos.x, pos.y) - vector2(c.x, c.y))
                if d < t.radius + Config.DrawDistance + 40.0 then
                    sleep = 0
                    local col = hexRgb(t.ownerColor or '#ffffff')
                    DrawMarker(1, c.x + 0.0, c.y + 0.0, c.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, t.radius * 2.0, t.radius * 2.0, 40.0,
                        col[1], col[2], col[3], T.ZoneAlpha, false, false, 2, false, nil, nil, false)
                end
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then clearBlips() end
end)
