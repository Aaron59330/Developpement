Citizen.CreateThread(function()
	TriggerEvent('chat:addSuggestion', '/Wipe', 'Wipe un joueur',{
		{name = "Id du joueur", help = "L'id du joueur" }
    })
end)

local isRequest = false
RegisterNetEvent("esx_custom:ResetIdentityPlayer")
AddEventHandler("esx_custom:ResetIdentityPlayer", function(id)
    isRequest = true
    ESX.ShowNotification(ConfigWipe.Notification["Push"])

    Citizen.CreateThread(function()
        local timer = 0
        local maxTimer = 1000

        while true do
            Citizen.Wait(10)
            timer = timer + 1

            if IsControlJustPressed(1, 246) and isRequest then
                local Keyboard = ESXCustom_Function_ClientSide:KeyboardInput(ConfigWipe.Notification["Keyboard"], "", 3)
                if Keyboard == "oui" or Keyboard == "Oui" then 
                    ESX.ShowNotification(ConfigWipe.Notification["Accept"])
                    TriggerServerEvent("esx_custom:ResetIdentityPlayer", id)
                    isRequest = false
                    break
                else
                    ESX.ShowNotification(ConfigWipe.Notification["Denied"])
                    TriggerServerEvent("esx_custom:ResetIdentityPlayer", id, false)
                    isRequest = false
                    break
                end
            elseif IsControlJustPressed(1, 182) and isRequest then
                ESX.ShowNotification(ConfigWipe.Notification["Denied"])
                TriggerServerEvent("esx_custom:ResetIdentityPlayer", id, false)
                isRequest = false
                break
            end

            if timer >= maxTimer then
                ESX.ShowNotification(ConfigWipe.Notification["DeniedSource"])
                TriggerServerEvent("esx_custom:ResetIdentityPlayer", id, true)
                isRequest = false
                break
            end
        end
    end)
end)