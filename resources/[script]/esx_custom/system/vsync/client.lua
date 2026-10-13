CurrentWeather = 'EXTRASUNNY'
local lastWeather = CurrentWeather
local baseTime = 0
local timeOffset = 0
local timer = 0
local freezeTime = false
local blackout = false

if Config.Snow == false then
    RegisterNetEvent('DME:updateWeather')
    AddEventHandler('DME:updateWeather', function(NewWeather, newblackout)
        CurrentWeather = NewWeather
        blackout = newblackout
    end)
end

Citizen.CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/weather', 'Changer le temps.', {{ name="weatherType", help="Available types: extrasunny, clear, neutral, smog, foggy, overcast, clouds, clearing, rain, thunder, snow, blizzard, snowlight, xmas & halloween"}})
    TriggerEvent('chat:addSuggestion', '/time', 'Changer l\'heure.', {{ name="heure", help="un nombre entre 0 - 23"}, { name="minutes", help="un nombre entre 0 - 59"}})
    TriggerEvent('chat:addSuggestion', '/freezetime', 'Freeze / defreeze le temps.')
    TriggerEvent('chat:addSuggestion', '/freezeweather', 'Activer / désactiver les changements météorologiques dynamiques.')
    TriggerEvent('chat:addSuggestion', '/morning', 'Réglez l\'heure sur 09:00')
    TriggerEvent('chat:addSuggestion', '/noon', 'Réglez l\'heure sur 12:00')
    TriggerEvent('chat:addSuggestion', '/evening', 'Réglez l\'heure sur 18:00')
    TriggerEvent('chat:addSuggestion', '/night', 'Réglez l\'heure sur 23:00')
    TriggerEvent('chat:addSuggestion', '/blackout', 'Basculer en mode blackout.')
    while true do
        if lastWeather ~= CurrentWeather then
            lastWeather = CurrentWeather
            SetWeatherTypeOverTime(CurrentWeather, 15.0)
            Citizen.Wait(15000)
        end
        
        Citizen.Wait(100) -- Wait 0 seconds to prevent crashing.
        SetBlackout(blackout)
        ClearOverrideWeather()
        ClearWeatherTypePersist()
        SetWeatherTypePersist(lastWeather)
        SetWeatherTypeNow(lastWeather)
        SetWeatherTypeNowPersist(lastWeather)
        if lastWeather == 'XMAS' then
            SetForceVehicleTrails(true)
            SetForcePedFootstepsTracks(true)
        else
            SetForceVehicleTrails(false)
            SetForcePedFootstepsTracks(false)
        end
    end
end)

RegisterNetEvent('DME:updateTime')
AddEventHandler('DME:updateTime', function(base, offset, freeze)
    freezeTime = freeze
    timeOffset = offset
    baseTime = base
end)

Citizen.CreateThread(function()
    local hour = 0
    local minute = 0
    while true do
        Citizen.Wait(500)
        local newBaseTime = baseTime
        if GetGameTimer() - 500  > timer then
            newBaseTime = newBaseTime + 0.25
            timer = GetGameTimer()
        end
        if freezeTime then
            timeOffset = timeOffset + baseTime - newBaseTime			
        end
        baseTime = newBaseTime
        hour = math.floor(((baseTime+timeOffset)/60)%24)
        minute = math.floor((baseTime+timeOffset)%60)
        if not Config.SynchroRealTime then
            NetworkOverrideClockTime(hour, minute, 0)
        end
    end
end)

if Config.SynchroRealTime then
    Citizen.CreateThread(function()
        while true do
            local _, _, _, hour, minute = GetUtcTime()
            NetworkOverrideClockTime(hour, minute, 0)
            Citizen.Wait(60000)
        end
    end)
end

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('DME:requestSync')
end)