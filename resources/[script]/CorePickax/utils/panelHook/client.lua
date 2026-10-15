-- Réglages « Markers » envoyés par le panel web (ressource pickax_panel, facultative).
-- Surcharge Config.GlobalMarker en direct ; retirer un réglage dans le panel rend la valeur de config.lua.
local KEYS = { enabled = 'Enabled', type = 'Type', color = 'Color', bob = 'BobUpAndDown', rotate = 'Rotate', face = 'FaceCamera' }
local base = {}

local function apply()
    if GetResourceState('pickax_panel') ~= 'started' or not Config or not Config.GlobalMarker then return end
    local ok, o = pcall(function() return exports.pickax_panel:Get('markers') end)
    if not ok or type(o) ~= 'table' then return end
    for pk, key in pairs(KEYS) do
        if o[pk] ~= nil then
            if base[key] == nil then base[key] = { Config.GlobalMarker[key] } end
            Config.GlobalMarker[key] = o[pk]
        elseif base[key] ~= nil then
            Config.GlobalMarker[key] = base[key][1]
            base[key] = nil
        end
    end
    if ClearGlobalMarkerGroundCache then ClearGlobalMarkerGroundCache() end
end

AddEventHandler('pickax_panel:changed', apply)
CreateThread(function() Wait(1500) apply() end)
