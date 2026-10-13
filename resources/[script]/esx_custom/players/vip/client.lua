IsVipPlayer = false

AddEventHandler('esx:playerLoaded', function()
	IsVipPlayer = false
	ESX.TriggerServerCallback('esx_custom:Vip:getVIPStatus', function(vip)
		if vip then
	        ESX.ShowNotification("Votre vip à été chargé.")
            ESX.PlayerData.maxWeight = ConfigVIP.maxWeightVIP
            IsVipPlayer = true
        else
            ESX.PlayerData.maxWeight = ConfigVIP.maxWeightDefault
            IsVipPlayer = false
		end
	end)
end)

RegisterNetEvent('esx_custom:Vip:VIPStatus')
AddEventHandler('esx_custom:Vip:VIPStatus', function(stats)
    IsVipPlayer = stats
end)

Citizen.CreateThread(function()
    while true do
        TriggerServerEvent('esx_custom:Vip:GetVIP')
        Wait(60000)
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(ConfigVIP.TimerWait)
        TriggerServerEvent("esx_custom:Vip:AddCoins")
    end
end)

function GetVIP()
    return IsVipPlayer
end

RegisterNetEvent('esx_custom:Vip:updateVIP')
AddEventHandler('esx_custom:Vip:updateVIP',function(vip)
    IsVipPlayer = vip
end)