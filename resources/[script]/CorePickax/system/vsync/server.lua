DynamicWeather = false
AvailableWeatherTypes = {
    'EXTRASUNNY', 
    'CLEAR', 
    'NEUTRAL', 
    'SMOG', 
    'FOGGY', 
    'OVERCAST', 
    'CLOUDS', 
    'CLEARING', 
    'RAIN', 
    'THUNDER', 
    'SNOW', 
    'BLIZZARD', 
    'SNOWLIGHT', 
    'XMAS', 
    'HALLOWEEN',
}
CurrentWeather = "EXTRASUNNY"
local baseTime = 0
local timeOffset = 0
local freezeTime = false
local manualTime = false   -- vrai dès qu'un staff règle l'heure à la main : l'heure réelle est alors suspendue (retour avec /realtime)
local blackout = false
local newWeatherTimer = 10

RegisterServerEvent('DME:requestSync')
AddEventHandler('DME:requestSync', function()
    if Config.Snow == false then
        TriggerClientEvent('DME:updateWeather', -1, CurrentWeather, blackout)
    end
    TriggerClientEvent('DME:updateTime', -1, baseTime, timeOffset, freezeTime, manualTime)
end)

function isAllowedToChange(player)
    local allowed = false
    if Config.Licensestaff[ESXCustom_Function_ServerSide:getLicense(player)] then
        allowed = true
    end

    return allowed
end

RegisterCommand('freezetime', function(source, args)
    if source ~= 0 then
        if isAllowedToChange(source) then
            freezeTime = not freezeTime
            if freezeTime then
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'Le temps est maintenant ~b~Freeze~s~.')
            else
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'Le temps est ~y~maintenant plus freeze~s~.')
            end
        else
            TriggerClientEvent('chatMessage', source, '', {255,255,255}, '^8Erreur: ^1Vous n\'êtes pas autorisé à utiliser cette commande.')
        end
    else
        freezeTime = not freezeTime
        if freezeTime then
            print("Le temps est maintenant Freeze.")
        else
            print("Le temps est maintenant plus freeze.")
        end
    end
end)

if Config.Snow == false then
    RegisterCommand('freezeweather', function(source, args)
        if source ~= 0 then
        if isAllowedToChange(source) then
            DynamicWeather = not DynamicWeather
                if not DynamicWeather then
                    TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'Les changements météorologiques dynamiques sont maintenant ~r~disabled~s~.')
                else
                    TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'Les changements météorologiques dynamiques sont maintenant ~b~enabled~s~.')
                end
            else
                TriggerClientEvent('chatMessage', source, '', {255,255,255}, '^8Erreur: ^1Vous n\'êtes pas autorisé à utiliser cette commande.')
            end
        else
            DynamicWeather = not DynamicWeather
            if not DynamicWeather then
                print("Le temps est maintenant Freeze.")
            else
                print("Le temps n'est plus Freeze.")
            end
        end
    end)

    RegisterCommand('weather', function(source, args)
        if source == 0 then
            local validWeatherType = false
            if args[1] == nil then
                print("Syntaxe incorrecte, la syntaxe correcte est: / weather <weathertype>")
                return
            else
                for i,wtype in ipairs(AvailableWeatherTypes) do
                    if wtype == string.upper(args[1]) then
                        validWeatherType = true
                    end
                end
                if validWeatherType then
                    print("La météo a été mise à jour.")
                    CurrentWeather = string.upper(args[1])
                    newWeatherTimer = 10
                    TriggerEvent('DME:requestSync')
                else
                    print("Type de météo non valide, les types de météo valides sont : \nEXTRASUNNY CLEAR NEUTRAL SMOG FOGGY OVERCAST CLOUDS CLEARING RAIN THUNDER SNOW BLIZZARD SNOWLIGHT XMAS HALLOWEEN ")
                end
            end
        else
            if isAllowedToChange(source) then
                local validWeatherType = false
                if args[1] == nil then
                    TriggerClientEvent('chatMessage', source, '', {255,255,255}, '^8Erreur: ^1Syntaxe non valide, utilisez ^ 0 / weather <weatherType> ^ 1 à la place !')
                else
                    for i,wtype in ipairs(AvailableWeatherTypes) do
                        if wtype == string.upper(args[1]) then
                            validWeatherType = true
                        end
                    end
                    if validWeatherType then
                        TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'La météo changera en : ~y~' .. string.lower(args[1]) .. "~s~.")
                        CurrentWeather = string.upper(args[1])
                        newWeatherTimer = 10
                        TriggerEvent('DME:requestSync')
                    else
                        TriggerClientEvent('chatMessage', source, '', {255,255,255}, '^8Erreur: ^1Type de temps non valide, les types de temps valides sont: : ^0\nEXTRASUNNY CLEAR NEUTRAL SMOG FOGGY OVERCAST CLOUDS CLEARING RAIN THUNDER SNOW BLIZZARD SNOWLIGHT XMAS HALLOWEEN ')
                    end
                end
            else
                TriggerClientEvent('chatMessage', source, '', {255,255,255}, '^8Error: ^1Vous n\'avez pas accès à cette commande.')
                print('Accès pour commande / météo refusé.')
            end
        end
    end, false)
end

RegisterServerEvent('DME:BLackoutContext')
AddEventHandler('DME:BLackoutContext', function()
    blackout = not blackout
    TriggerEvent('DME:requestSync')
end)

RegisterCommand('blackout', function(source)
    if source == 0 then
        blackout = not blackout
        if blackout then
            print("Blackout est activée.")
        else
            print("Blackout est desactivée.")
        end
    else
        if isAllowedToChange(source) then
            blackout = not blackout
            if blackout then
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'Blackout est maintenant ~b~enabled~s~.')
            else
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'Blackout est maintenant ~r~disabled~s~.')
            end
            TriggerEvent('DME:requestSync')
        end
    end
end)

RegisterCommand('morning', function(source)
    if source == 0 then
        print("Pour la console, utilisez la commande \"/ time <hh> <mm> \" à la place!")
        return
    end
    if isAllowedToChange(source) then
        ShiftToMinute(0)
        ShiftToHour(9)
        TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'Time set to ~y~morning~s~.')
        TriggerEvent('DME:requestSync')
    end
end)
RegisterCommand('noon', function(source)
    if source == 0 then
        print("Pour la console, utilisez la commande \"/ time <hh> <mm> \" à la place!")
        return
    end
    if isAllowedToChange(source) then
        ShiftToMinute(0)
        ShiftToHour(12)
        TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'Time set to ~y~noon~s~.')
        TriggerEvent('DME:requestSync')
    end
end)
RegisterCommand('evening', function(source)
    if source == 0 then
        print("Pour la console, utilisez la commande \"/ time <hh> <mm> \" à la place!")
        return
    end
    if isAllowedToChange(source) then
        ShiftToMinute(0)
        ShiftToHour(18)
        TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'Time set to ~y~evening~s~.')
        TriggerEvent('DME:requestSync')
    end
end)
RegisterCommand('night', function(source)
    if source == 0 then
        print("Pour la console, utilisez la commande \"/ time <hh> <mm> \" à la place!")
        return
    end
    if isAllowedToChange(source) then
        ShiftToMinute(0)
        ShiftToHour(23)
        TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'Time set to ~y~night~s~.')
        TriggerEvent('DME:requestSync')
    end
end)

function ShiftToMinute(minute)
    manualTime = true
    timeOffset = timeOffset - ( ( (baseTime+timeOffset) % 60 ) - minute )
end

function ShiftToHour(hour)
    manualTime = true
    timeOffset = timeOffset - ( ( ((baseTime+timeOffset)/60) % 24 ) - hour ) * 60
end

RegisterCommand('time', function(source, args, rawCommand)
    if source == 0 then
        if tonumber(args[1]) ~= nil and tonumber(args[2]) ~= nil then
            local argh = tonumber(args[1])
            local argm = tonumber(args[2])
            if argh < 24 then
                ShiftToHour(argh)
            else
                ShiftToHour(0)
            end
            if argm < 60 then
                ShiftToMinute(argm)
            else
                ShiftToMinute(0)
            end
            print("Le temps a changé par " .. argh .. ":" .. argm .. ".")
            TriggerEvent('DME:requestSync')
        else
            print("Syntaxe invalide, la syntaxe correcte est : time <hour> <minute>!")
        end
    elseif source ~= 0 then
        if isAllowedToChange(source) then
            if tonumber(args[1]) ~= nil and tonumber(args[2]) ~= nil then
                local argh = tonumber(args[1])
                local argm = tonumber(args[2])
                if argh < 24 then
                    ShiftToHour(argh)
                else
                    ShiftToHour(0)
                end
                if argm < 60 then
                    ShiftToMinute(argm)
                else
                    ShiftToMinute(0)
                end
                local newtime = math.floor(((baseTime+timeOffset)/60)%24) .. ":"
				local minute = math.floor((baseTime+timeOffset)%60)
                if minute < 10 then
                    newtime = newtime .. "0" .. minute
                else
                    newtime = newtime .. minute
                end
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'L\'heure a été remplacée par : ~y~' .. newtime .. "~s~ !")
                TriggerEvent('DME:requestSync')
            else
                TriggerClientEvent('chatMessage', source, '', {255,255,255}, '^8Erreur: ^1 Syntaxe incorrecte. Utilisez ^ 0 / time <heur> espace <minute> ^ 1 à la place !')
            end
        else
            TriggerClientEvent('chatMessage', source, '', {255,255,255}, '^8Erreur: ^1Vous n\'avez pas accès à cette commande.')
            print('Accès pour commande / heure refusé.')
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local newBaseTime = os.time(os.date("!*t"))/2 + 360
        if freezeTime then
            timeOffset = timeOffset + baseTime - newBaseTime			
        end
        baseTime = newBaseTime
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        TriggerClientEvent('DME:updateTime', -1, baseTime, timeOffset, freezeTime, manualTime)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000)
        TriggerClientEvent('DME:updateWeather', -1, CurrentWeather, blackout)
    end
end)

Citizen.CreateThread(function()
    while true do
        newWeatherTimer = newWeatherTimer - 1
        Citizen.Wait(60000)
        if newWeatherTimer == 0 then
            if DynamicWeather then
                NextWeatherStage()
            end
            newWeatherTimer = 10
        end
    end
end)

function NextWeatherStage()
    if CurrentWeather == "CLEAR" or CurrentWeather == "CLOUDS" or CurrentWeather == "EXTRASUNNY"  then
        local new = math.random(1,2)
        if new == 1 then
            CurrentWeather = "CLEARING"
        else
            CurrentWeather = "OVERCAST"
        end
    elseif CurrentWeather == "CLEARING" or CurrentWeather == "OVERCAST" then
        local new = math.random(1,6)
        if new == 1 then
            if CurrentWeather == "CLEARING" then CurrentWeather = "FOGGY" else CurrentWeather = "RAIN" end
        elseif new == 2 then
            CurrentWeather = "CLOUDS"
        elseif new == 3 then
            CurrentWeather = "CLEAR"
        elseif new == 4 then
            CurrentWeather = "EXTRASUNNY"
        elseif new == 5 then
            CurrentWeather = "SMOG"
        else
            CurrentWeather = "FOGGY"
        end
    elseif CurrentWeather == "THUNDER" or CurrentWeather == "RAIN" then
        CurrentWeather = "CLEARING"
    elseif CurrentWeather == "SMOG" or CurrentWeather == "FOGGY" then
        CurrentWeather = "CLEAR"
    end
    TriggerEvent("DME:requestSync")
end



-- /realtime : revient à l'heure réelle (si Config.SynchroRealTime est activé)
RegisterCommand('realtime', function(source)
    if source ~= 0 and not isAllowedToChange(source) then return end
    manualTime = false
    TriggerEvent('DME:requestSync')
    if source ~= 0 then
        TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'L\'heure suit de nouveau l\'~b~heure réelle~s~.')
    else
        print("L'heure suit de nouveau l'heure réelle.")
    end
end, false)
