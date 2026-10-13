LeBonus = false
MiniFlic = 2
Citizen.CreateThread(function()
     if Config.Debug then
          Wait(1000)
          print("Initialisations des GoFast...")
     end
end)

-- Gestion GoFast
GoFastDejaFait = 1
Citizen.CreateThread(function()
	while true do
	     Citizen.Wait(10*60000)
          GoFastDejaFait = GoFastDejaFait + 0
          TriggerClientEvent("Sync:GoFast", -1, GoFastDejaFait)
	end
end)

ESX.RegisterServerCallback('GoFast:Starting', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	cb(ESXCustom_Function_ServerSide:CountCops())
end)

local TablePlayersForGoFast = {}
RegisterServerEvent("GoFast:MoinUnGoFast")
AddEventHandler("GoFast:MoinUnGoFast", function()
     local _source = source

     if GoFastDejaFait == 0 then
          DeleteEntity(GetVehiclePedIsIn(GetPlayerPed(_source)))
          DropPlayer(_source, 'Tentative de glitch [GoFast]')
          return
     end

     TriggerEvent("GoFast:AddCache", _source)
     VerifyToken(_source, function()
          ESXCustomServerUtils.GetDistance(_source, ConfigGoFast.DebutMission, 20, "GoFast:MoinUnGoFast", false, function()
               GoFastDejaFait = GoFastDejaFait - 1
               TriggerClientEvent("Sync:GoFast", -1, GoFastDejaFait)
          end, function()
          end)
     end)
end)

RegisterServerEvent("GoFast:AddCache")
AddEventHandler("GoFast:AddCache", function(_source)
     Wait(5000)
     VerifyToken(_source, function()
          ESXCustomServerUtils.GetDistance(_source, ConfigGoFast.DebutMission, 20, "GoFast:MoinUnGoFast", false, function()
               local veh = GetVehiclePedIsIn(GetPlayerPed(_source))
               TablePlayersForGoFast[_source] = veh
          end, function()
          end)
     end)
end)

RegisterServerEvent("GoFast:VenteDuVehicule")
AddEventHandler("GoFast:VenteDuVehicule", function(qqxt)
     local _source = source
     local xPlayer = ESX.GetPlayerFromId(_source)
     local bonus = GetVehicleEngineHealth(TablePlayersForGoFast[_source])

     if ConfigGoFast.ZoneToSell[qqxt] == nil then
          if ConfigAC.AntiTrigger.Active then
               if ConfigAC.AntiTrigger.Kick then
                    DropPlayer(_source, 'Anticheat | Anti trigger [GoFast]')
               elseif ConfigAC.AntiTrigger.Ban then
                    TriggerEvent("BanSql:ICheatServer", _source, "Anticheat | Anti trigger [GoFast]", -1)
               end
          end
          return
     end

     if not xPlayer then return; end

     VerifyToken(_source, function()
          ESXCustomServerUtils.GetDistance(_source, ConfigGoFast.ZoneToSell[qqxt], 20, "GoFast:VenteDuVehicule", false, function()
               if LeBonus then
                    PrixPolicierVente = CopsConnected * 2
                    local r = math.random(2500, 4000) + PrixPolicierVente
                    PrixVente = r

                    local bonusFinal = bonus

                    if ESXCustom_Function_ServerSide:CountCops() < 2 then
                         bonusFinal = bonusFinal / 2
                    end

                    if bonus > 100 then
                         TriggerClientEvent(Config.Trigger.TriggerAdvancedNotification, _source, 'GoFast', '~b~Récompense GoFast', '🔧~w~Véhicule en parfait état ! Bonus de ~g~'..bonusFinal..'$', 'CHAR_LESTER_DEATHWISH', 3)
                    elseif bonus > 75 then
                         TriggerClientEvent(Config.Trigger.TriggerAdvancedNotification, _source, 'GoFast', '~b~Récompense GoFast', '🔧~w~Véhicule en états correct ! Bonus de ~g~'..bonusFinal..'$', 'CHAR_LESTER_DEATHWISH', 3)
                    elseif bonus > 50 then
                         TriggerClientEvent(Config.Trigger.TriggerAdvancedNotification, _source, 'GoFast', '~b~Récompense GoFast', '🔧~w~Véhicule assez abimé ! Bonus de ~g~'..bonusFinal..'$', 'CHAR_LESTER_DEATHWISH', 3)
                    elseif bonus > 25 then
                         TriggerClientEvent(Config.Trigger.TriggerAdvancedNotification, _source, 'GoFast', '~b~Récompense GoFast', '🔧~w~Véhicule complétement abimé ! Bonus de ~g~'..bonusFinal..'$', 'CHAR_LESTER_DEATHWISH', 3)
                    end
                    PrixVente = PrixVente + bonusFinal
               else
                    PrixVente = math.random(2500, 4000)
               end
               DeleteEntity(TablePlayersForGoFast[_source])
               TablePlayersForGoFast[_source] = nil
               AddBlackMoneyOnPlayer(_source, PrixVente)
               TriggerClientEvent(Config.Trigger.TriggerAdvancedNotification, _source, 'GoFast', '~b~Récompense GoFast', '✅~w~Vous avez gagné ~g~'..PrixVente..'$', 'CHAR_LESTER_DEATHWISH', 3)
          end, function()
          end)
          if DoesEntityExist(TablePlayersForGoFast[_source]) then
               DeleteEntity(TablePlayersForGoFast[_source])
          end
     end)
end)

RegisterServerEvent("GoFast:MessagePolice")
AddEventHandler("GoFast:MessagePolice", function()
     if TablePlayersForGoFast[_source] ~= nil then
          for k, v in pairs(ESXCustomServerUtils.GetInfoByJobsName.Police) do
               local xPlayer = ESX.GetPlayerFromId(k)
     
               if xPlayer.job.name == 'police' then
                    Citizen.Wait(10*1000)
                    TriggerClientEvent(Config.Trigger.TriggerAdvancedNotification, k, "Indic LSPD", "~b~Message de l'indic", "D'après mes infos, un GoFast à commencé, rester attentif!", "CHAR_JOSEF", 3)
               end
          end
     end
end)