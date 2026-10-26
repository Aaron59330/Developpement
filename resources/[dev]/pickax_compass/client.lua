local KVP = 'pickax_compass:enabled'
local enabled = Config.DefaultEnabled
local saved = GetResourceKvpString(KVP)
if saved == '1' then enabled = true elseif saved == '0' then enabled = false end

local hiddenByUi = false
local visible = false

AddEventHandler('pickax:inventory', function(open) hiddenByUi = open == true end)   -- même événement que le menu pause / inventaire : masque les HUD

exports('GetSettings', function() return { enabled = enabled } end)
exports('SetEnabled', function(v)
    enabled = v == true
    SetResourceKvp(KVP, enabled and '1' or '0')
    if not enabled then SendNUIMessage({ a = 'show', v = false }) visible = false end
    return true
end)
RegisterCommand('boussole', function() exports[GetCurrentResourceName()]:SetEnabled(not enabled) end, false)

local function sendCfg()
    SendNUIMessage({ a = 'cfg', layout = Config.Layout, left = Config.Compact.left, bottom = Config.Compact.bottom, width = Config.Compact.width, street = Config.ShowStreet })
end
local function show(v)
    if v ~= visible then
        visible = v
        if v then sendCfg() end
        SendNUIMessage({ a = 'show', v = v })
    end
end

CreateThread(function()
    local lastH, street, zone, tStreet = -1, '', '', 0
    while true do
        local ped = PlayerPedId()
        local want = enabled and not hiddenByUi and not IsPauseMenuActive() and not IsScreenFadedOut()
        if want and Config.OnFootOnly and IsPedInAnyVehicle(ped, false) then want = false end
        if want and Config.HideWhenMapOpen and IsPauseMenuActive() then want = false end
        show(want)
        if want then
            local h = math.floor((360.0 - GetGameplayCamRot(2).z) % 360.0 + 0.5) % 360
            local now = GetGameTimer()
            local changed = h ~= lastH
            if Config.ShowStreet and now - tStreet > 600 then
                tStreet = now
                local c = GetEntityCoords(ped)
                local s1 = GetStreetNameAtCoord(c.x, c.y, c.z)
                local st, zn = GetStreetNameFromHashKey(s1), GetLabelText(GetNameOfZone(c.x, c.y, c.z))
                if st ~= street or zn ~= zone then street, zone, changed = st, zn, true end
            end
            if changed then lastH = h SendNUIMessage({ a = 'h', h = h, street = street, zone = zone }) end
            Wait(Config.Refresh)
        else
            Wait(300)
        end
    end
end)


-- Réglages du serveur (panel web > Réglages) : format et position de la boussole.
AddEventHandler('pickax_settings:changed', function(all, ov)
    if not ov then return end
    local touched = false
    if ov.compass_layout ~= nil then Config.Layout = all.compass_layout touched = true end
    if ov.compass_street ~= nil then Config.ShowStreet = all.compass_street touched = true end
    if ov.compass_left ~= nil then Config.Compact.left = tostring(all.compass_left) .. 'vw' touched = true end
    if ov.compass_bottom ~= nil then Config.Compact.bottom = tostring(all.compass_bottom) .. 'vh' touched = true end
    if touched and visible then sendCfg() end
end)
