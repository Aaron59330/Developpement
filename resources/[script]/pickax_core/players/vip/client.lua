IsVipPlayer = false

AddEventHandler('esx:playerLoaded', function()
	IsVipPlayer = false
	ESX.TriggerServerCallback('CorePickax:Vip:getVIPStatus', function(vip)
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

RegisterNetEvent('CorePickax:Vip:VIPStatus')
AddEventHandler('CorePickax:Vip:VIPStatus', function(stats)
    IsVipPlayer = stats
end)

Citizen.CreateThread(function()
    while true do
        TriggerServerEvent('CorePickax:Vip:GetVIP')
        Wait(60000)
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(ConfigVIP.TimerWait)
        TriggerServerEvent("CorePickax:Vip:AddCoins")
    end
end)

function GetVIP()
    return IsVipPlayer
end

RegisterNetEvent('CorePickax:Vip:updateVIP')
AddEventHandler('CorePickax:Vip:updateVIP',function(vip)
    IsVipPlayer = vip
end)