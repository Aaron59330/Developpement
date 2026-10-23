-- Météo, position, lampe torche, localisation de véhicule, alertes de service, recharge en voiture
local flashlight = false

local WEATHER = {
    [`CLEAR`] = { 'Ciel dégagé', 'sun', 24 }, [`EXTRASUNNY`] = { 'Grand soleil', 'sun', 30 }, [`CLOUDS`] = { 'Nuageux', 'cloud', 19 }, [`OVERCAST`] = { 'Couvert', 'cloud', 16 },
    [`RAIN`] = { 'Pluie', 'rain', 14 }, [`CLEARING`] = { 'Éclaircies', 'cloudsun', 17 }, [`THUNDER`] = { 'Orage', 'storm', 15 }, [`SMOG`] = { 'Brume de pollution', 'fog', 20 },
    [`FOGGY`] = { 'Brouillard', 'fog', 13 }, [`SNOW`] = { 'Neige', 'snow', -1 }, [`BLIZZARD`] = { 'Tempête de neige', 'snow', -5 }, [`SNOWLIGHT`] = { 'Neige légère', 'snow', 0 },
    [`XMAS`] = { 'Neige', 'snow', -2 }, [`HALLOWEEN`] = { 'Nuit brumeuse', 'fog', 11 }, [`NEUTRAL`] = { 'Variable', 'cloud', 18 },
}

local function weatherNow()
    local cur = GetPrevWeatherTypeHashName()
    local nxt = GetNextWeatherTypeHashName()
    local w = WEATHER[cur] or WEATHER[nxt] or { 'Variable', 'cloud', 18 }
    local h, m = GetClockHours(), GetClockMinutes()
    local temp = w[3] + (h >= 11 and h <= 17 and 3 or (h >= 22 or h < 6) and -4 or 0)
    local nw = WEATHER[nxt] or w
    return { label = w[1], icon = w[2], temp = temp, next = nw[1], nextIcon = nw[2], hour = h, minute = m, wind = math.floor(GetWindSpeed() * 3.6), day = GetClockDayOfWeek() }
end

RegisterNUICallback('weather', function(_, cb) cb(weatherNow()) end)

RegisterNUICallback('position', function(_, cb)
    local c = GetEntityCoords(PlayerPedId())
    local street, cross = GetStreetNameAtCoord(c.x, c.y, c.z)
    local zone = GetNameOfZone(c.x, c.y, c.z)
    cb({ x = c.x, y = c.y, z = c.z, heading = GetEntityHeading(PlayerPedId()), street = GetStreetNameFromHashKey(street), cross = cross ~= 0 and GetStreetNameFromHashKey(cross) or nil,
         zone = GetLabelText(zone) ~= 'NULL' and GetLabelText(zone) or zone })
end)

RegisterNUICallback('waypoint', function(d, cb)
    if d and tonumber(d.x) and tonumber(d.y) then SetNewWaypoint(tonumber(d.x) + 0.0, tonumber(d.y) + 0.0) end
    cb(1)
end)
RegisterNUICallback('clearWaypoint', function(_, cb) DeleteWaypoint() cb(1) end)

RegisterNUICallback('streetName', function(d, cb)
    if d and tonumber(d.x) then
        local s = GetStreetNameAtCoord(tonumber(d.x) + 0.0, tonumber(d.y) + 0.0, 0.0)
        cb({ street = GetStreetNameFromHashKey(s) })
    else cb({}) end
end)

-- ═════════ lampe torche ═════════
RegisterNUICallback('flashlight', function(d, cb) flashlight = d and d.state and true or false cb(1) end)
CreateThread(function()
    while true do
        if flashlight then
            Wait(0)
            local ped = PlayerPedId()
            local bone = GetPedBoneCoords(ped, 28422, 0.0, 0.0, 0.0)
            local fwd = GetEntityForwardVector(ped)
            local c = GetGameplayCamRot(2)
            local rad = math.rad
            local dx, dy, dz = -math.sin(rad(c.z)) * math.cos(rad(c.x)), math.cos(rad(c.z)) * math.cos(rad(c.x)), math.sin(rad(c.x))
            DrawSpotLightWithShadow(bone.x, bone.y, bone.z + 0.1, dx, dy, dz, 255, 244, 220, 22.0, 6.0, 4.0, 35.0, 1.0, 0)
        else Wait(250) end
    end
end)

-- ═════════ garage : localiser un véhicule ═════════
RegisterNUICallback('locateVehicle', function(d, cb)
    local plate = tostring(d and d.plate or ''):gsub('%s+', ''):upper()
    for _, v in ipairs(GetGamePool('CVehicle')) do
        local p = GetVehicleNumberPlateText(v):gsub('%s+', ''):upper()
        if p == plate then
            local c = GetEntityCoords(v)
            SetNewWaypoint(c.x, c.y)
            cb({ found = true, x = c.x, y = c.y })
            return
        end
    end
    cb({ found = false })
end)

RegisterNUICallback('vehicleName', function(d, cb)
    local model = tonumber(d and d.model)
    if not model then cb({ name = '' }) return end
    local n = GetDisplayNameFromVehicleModel(model)
    local label = GetLabelText(n)
    cb({ name = (label ~= 'NULL' and label) or n })
end)

-- ═════════ alertes de service (côté agents) ═════════
local blips = {}
RegisterNetEvent('aura:dispatch', function(a)
    SendNUIMessage({ action = 'push', event = 'dispatch', data = a })
    if not a.noBlip and a.coords then   -- noBlip : la tablette du job place déjà son propre blip
        local blip = AddBlipForCoord(a.coords.x, a.coords.y, a.coords.z)
        SetBlipSprite(blip, Config.Dispatch.sprite); SetBlipColour(blip, Config.Dispatch.color); SetBlipScale(blip, 0.9)
        SetBlipFlashes(blip, true); SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName(a.label .. ' — ' .. (a.name or '')); EndTextCommandSetBlipName(blip)
        blips[#blips + 1] = blip
        SetTimeout(Config.Dispatch.blipSeconds * 1000, function() if DoesBlipExist(blip) then RemoveBlip(blip) end end)
    end
    PlaySoundFrontend(-1, 'Event_Message_Purple', 'GTAO_FM_Events_Soundset', true)
end)

RegisterNUICallback('dispatchGps', function(d, cb)
    local c = d and d.id and lib.callback.await('aura:dispatchAccept', false, d.id)
    if c then SetNewWaypoint(c.x, c.y) end
    cb(c and 1 or 0)
end)

-- ═════════ recharge en véhicule ═════════
CreateThread(function()
    if not (Config.Battery.enabled and Config.Battery.chargeInVehicle) then return end
    local charging = false
    while true do
        Wait(2000)
        local inVeh = IsPedInAnyVehicle(PlayerPedId(), false) and GetIsVehicleEngineRunning(GetVehiclePedIsIn(PlayerPedId(), false))
        if inVeh ~= charging then charging = inVeh and true or false; TriggerServerEvent('aura:setCharging', charging) end
    end
end)

-- ═════════ divers ═════════
RegisterNUICallback('notifyGame', function(d, cb) if d and d.text then ESX.ShowNotification(tostring(d.text)) end cb(1) end)
RegisterNUICallback('copy', function(d, cb) cb(1) end)
RegisterNUICallback('usePowerbank', function(_, cb) cb(lib.callback.await('aura:usePowerbank', false)) end)
RegisterNUICallback('gameTime', function(_, cb) cb({ h = GetClockHours(), m = GetClockMinutes(), d = GetClockDayOfWeek(), day = GetClockDayOfMonth(), mo = GetClockMonth() + 1, y = GetClockYear() }) end)
