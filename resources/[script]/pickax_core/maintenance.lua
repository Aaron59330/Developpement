local maintenance = false

local function devStart(state)
    if state then
        maintenance = true
        local xPlayers = ESX.GetPlayers()
        for i = 1, #xPlayers, 1 do
            if not Config.Licensestaff[ESXCustom_Function_ServerSide:getLicense(xPlayers[i])] then
                print("Le joueur ^4"..GetPlayerName(xPlayers[i]).."^0 connexion ^1reffusé^0 ")
                DropPlayer(xPlayers[i], "\nInformation\nLe serveur est actuellement en maintenance patientez quelques minutes !")
            else
                print("Le joueur ^4"..GetPlayerName(xPlayers[i]).."^0 connexion ^2accepté^0 ")
            end
        end
    else
        maintenance = false
    end
end

Citizen.CreateThread(function()
    devStart(maintenance)
end)

AddEventHandler('playerConnecting', function(name, setReason)
    if maintenance then
        if not Config.Licensestaff[ESXCustom_Function_ServerSide:getLicense(source)] then
            print("Le joueur ^4"..name.."^0 connexion ^1refusée^0 (^5Maintenance^0)")
            setReason("\nLe serveur est en maintenance, plus d'informations sur discord !")
            CancelEvent()
            return
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(60*1000*4)
        if maintenance then
            print("Maintenance ^2détecté^0 !")
            local xPlayers = ESX.GetPlayers()
            for i = 1, #xPlayers, 1 do
                if not Config.Licensestaff[ESXCustom_Function_ServerSide:getLicense(xPlayers[i])] then
                    print("Le joueur ^4"..GetPlayerName(xPlayers[i]).."^0 est ^1reffusé^0 dans la maintenance et je le kick .")
                    DropPlayer(xPlayers[i], "\nInformation\nLe serveur est actuellement en maintenance, plus d'informations sur discord !")
                else
                    print("Le joueur ^4"..GetPlayerName(xPlayers[i]).."^0 est ^2accepté^0 dans la maintenance .")
                end
            end
        end
    end
end)

ESXCustomServerUtils.registerConsoleCommand("maintenance", function(source)
    if source == 0 then
        if not maintenance then
            print("Maintenance ^2actif^0 !")
            devStart(true)
         else
            print("Maintenance non ^1actif^0 !")
            devStart(false)
        end
    end
end)