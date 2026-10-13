local AllLicense = {}
Citizen.CreateThread(function()--Ajout des informations au cache
    if Config.Debug then
        Wait(500)
        print('ESXCustom : Initialisation des informations des joueurs...')
    end
	Wait(1500)
    MySQL.Async.fetchAll('SELECT identifier, vip FROM users', {}, function(InfoReceive)
        if InfoReceive ~= nil then
            for k, v in pairs(InfoReceive) do
                if AllLicense[v.identifier] == nil then
                    AllLicense[v.identifier] = {}
                    AllLicense[v.identifier].identifier = v.identifier
                    if v.vip == false then
                        AllLicense[v.identifier].hasVip = false
                    else
                        AllLicense[v.identifier].hasVip = true
                    end
                end
            end
            if Config.Debug then
                print('[^5LOAD^0] [^5'..#InfoReceive..'^0] informations des joueurs ont été load avec succès !')
            end
        end
    end)
end)

Citizen.CreateThread(function()
    if Config.Debug then
        Wait(500)
        print('ESXCustom : Initialisation des VIP...')
    end
	Wait(1500)
    MySQL.Async.fetchAll('SELECT identifier FROM vips', {}, function(InfoReceive)
        if InfoReceive ~= nil then
            if Config.Debug then
                print('[^5LOAD^0] [^5'..#InfoReceive..'^0] VIP ont été load avec succès !')
            end
        end
    end)
end)

CachePlayersConnectedServer = {}
local VipTable = {}
AddEventHandler('esx:playerLoaded', function(source)
    if CachePlayersConnectedServer[ESXCustom_Function_ServerSide:getLicense(source)] == nil then
        CachePlayersConnectedServer[ESXCustom_Function_ServerSide:getLicense(source)] = {}
        CachePlayersConnectedServer[ESXCustom_Function_ServerSide:getLicense(source)].WasConnected = true
        CachePlayersConnectedServer[ESXCustom_Function_ServerSide:getLicense(source)].Id = source
    else
        CachePlayersConnectedServer[ESXCustom_Function_ServerSide:getLicense(source)].WasConnected = true
        CachePlayersConnectedServer[ESXCustom_Function_ServerSide:getLicense(source)].Id = source
    end

    local xPlayer = ESX.GetPlayerFromId(source)
	MySQL.Async.fetchAll("SELECT * FROM vips WHERE identifier=@identifier",{
        ['@identifier'] = xPlayer.identifier,
	}, function(data) 
        if data[1] then
            if tonumber(data[1].expiration) <= os.time() then
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'Votre VIP à expirer.')
                MySQL.Async.execute('DELETE FROM vips WHERE identifier=@identifier', {['@identifier'] = xPlayer.identifier,})
                MySQL.Async.execute('UPDATE `users` SET `vip`=@vip WHERE identifier=@identifier', {['@identifier'] = xPlayer.identifier, ['@vip'] = 0})

                if AllLicense[xPlayer.identifier] ~= nil then
                    AllLicense[xPlayer.identifier].hasVip = false
                else
                    AllLicense[xPlayer.identifier] = {}
                    AllLicense[xPlayer.identifier].identifier = xPlayer.identifier
                    AllLicense[xPlayer.identifier].hasVip = false
                end
            else
                local tempsrestant = (((tonumber(data[1].expiration)) - os.time())/60)
                local day        = (tempsrestant / 60) / 24
                local hrs        = (day - math.floor(day)) * 24
                local minutes    = (hrs - math.floor(hrs)) * 60
                local txtday     = math.floor(day)
                local txthrs     = math.floor(hrs)
                local txtminutes = math.ceil(minutes)
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, 'Votre VIP Prendra fin dans ~g~'..math.floor(day).. ' ~w~jours et ~g~'..txthrs.."~w~ heure(s).")
                if not VipTable[xPlayer.identifier] then
                    VipTable[xPlayer.identifier] = true
                end
                TriggerClientEvent('esx_custom:Vip:updateVIP', source, true)
            end
        else
            VipTable[xPlayer.identifier] = false
            TriggerClientEvent('esx_custom:Vip:updateVIP', source, false)
        end
	end)
end)

RegisterNetEvent('esx_custom:Vip:GetVIP')
AddEventHandler('esx_custom:Vip:GetVIP', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(source)
    while not xPlayer do Wait(1) xPlayer = ESX.GetPlayerFromId(source) end
    if not VipTable[xPlayer.identifier] then
        MySQL.Async.fetchAll("SELECT * FROM vips WHERE identifier=@identifier",{
            ['@identifier'] = xPlayer.identifier,
        }, function(data) 
            if data[1] then
                if tonumber(data[1].expiration) <= os.time() then
                    TriggerClientEvent(Config.Trigger.TriggerNotification, src, 'Votre VIP à expirer.')
                    MySQL.Async.execute('DELETE FROM vips WHERE identifier=@identifier', {
                        ['@identifier'] = xPlayer.identifier,
                    })
                    MySQL.Async.execute('UPDATE `users` SET `vip`=@vip WHERE identifier=@identifier', {['@identifier'] = xPlayer.identifier, ['@vip'] = 0})
                    if AllLicense[xPlayer.identifier] ~= nil then
                        AllLicense[xPlayer.identifier].hasVip = false
                    else
                        AllLicense[xPlayer.identifier] = {}
                        AllLicense[xPlayer.identifier].identifier = xPlayer.identifier
                        AllLicense[xPlayer.identifier].hasVip = false
                    end
                else
                    local tempsrestant = (((tonumber(data[1].expiration)) - os.time())/60)
                    local day        = (tempsrestant / 60) / 24
                    local hrs        = (day - math.floor(day)) * 24
                    local minutes    = (hrs - math.floor(hrs)) * 60
                    local txtday     = math.floor(day)
                    local txthrs     = math.floor(hrs)
                    local txtminutes = math.ceil(minutes)
                    TriggerClientEvent(Config.Trigger.TriggerNotification, src, 'Votre VIP Prendra fin dans ~g~'..math.floor(day).. ' ~w~jours et ~g~'..txthrs.."~w~ heure(s).")
                    if not VipTable[xPlayer.identifier] then
                        VipTable[xPlayer.identifier] = true
                    end
                    TriggerClientEvent('esx_custom:Vip:updateVIP', src, true)
                end
            else
                VipTable[xPlayer.identifier] = false
                TriggerClientEvent('esx_custom:Vip:updateVIP', src, false)
            end
        end)
    end
end)

AddEventHandler('playerDropped', function (reason)
    if CachePlayersConnectedServer[ESXCustom_Function_ServerSide:getLicense(source)] ~= nil then
        CachePlayersConnectedServer[ESXCustom_Function_ServerSide:getLicense(source)].WasConnected = false
        CachePlayersConnectedServer[ESXCustom_Function_ServerSide:getLicense(source)].Id = nil
    end
end)

ESX.RegisterServerCallback('esx_custom:Vip:getVIPStatus', function(source, cb)
    if AllLicense[ESX.GetPlayerFromId(source).identifier] ~= nil then
        if AllLicense[ESX.GetPlayerFromId(source).identifier].hasVip then
            local T = ESX.GetPlayerFromId(source).setMaxWeight(ConfigVIP.maxWeightVIP)
            cb(true)
        else
            local T = ESX.GetPlayerFromId(source).setMaxWeight(ConfigVIP.maxWeightDefault)
            cb(false)
        end
    end
end)

ESXCustomServerUtils.registerConsoleCommand('addVIP',function(source, args)
    if source == 0 then
        if args[1] then
            local TARGET = ESX.GetPlayerFromId(args[1])
            if TARGET ~= nil then
                if not VipTable[TARGET.identifier] then
                    local TARGET = ESX.GetPlayerFromId(tonumber(args[1]))
                    local jour = ConfigVIP.DureeVIP
                    local expiration = (jour * 86400)

                    if expiration < os.time() then
                        expiration = os.time() + expiration
                    end
                    MySQL.Async.execute('INSERT INTO vips (identifier, vip, expiration) VALUES (@identifier, @vip, @expiration)', {
                        ['@identifier'] = TARGET.identifier,
                        ['@vip'] = 1,
                        ['@expiration'] = expiration,
                    })
                    MySQL.Async.execute('UPDATE `users` SET `vip`=@vip WHERE identifier=@identifier', {['@identifier'] = TARGET.identifier, ['@vip'] = 1})
                    local tempsrestant = (((tonumber(expiration)) - os.time())/60)
                    local day        = (tempsrestant / 60) / 24
                    local hrs        = (day - math.floor(day)) * 24
                    local minutes    = (hrs - math.floor(hrs)) * 60
                    local txtday     = math.floor(day)
                    local txthrs     = math.floor(hrs)
                    local txtminutes = math.ceil(minutes)
                    TriggerClientEvent(Config.Trigger.TriggerNotification, args[1], "Vous venez d'obtenir un VIP, il prendra fin dans ~g~"..math.floor(day).." ~w~jours.")
                    VipTable[TARGET.identifier] = true
                    TriggerClientEvent('esx_custom:Vip:updateVIP', TARGET.source, true)
                    print("Le joueur vient de recevoir le VIP.")
                else
                    print("Le joueur à déjà le VIP.")
                end
            else
                print("Le joueur n'est pas connecté.")
            end
        else
            print("Merci d'entrer un ID d'un joueur.")
        end
    end
end)

function CheckVIP(source)
	local xPlayer = ESX.GetPlayerFromId(source)

	return xPlayer.vip, ConfigVIP.CombienDeFoisLeSalaire
end
exports('CheckVIP', CheckVIP)

RegisterServerEvent("esx_custom:Vip:AddCoins")
AddEventHandler('esx_custom:Vip:AddCoins', function()
    if AllLicense[ESX.GetPlayerFromId(source).identifier].hasVip then
        BoutiqueFunction.addPointsToPlayerReward(source, ConfigVIP.CoinsAdd)
    end
end)