local knockedOut = false
local wait = 1
local count = ConfigKO.Timer * 2.5

Citizen.CreateThread(function()
	while true do
		Wait(200)
        local myPed = PlayerClass.pPed
		local myPedId = PlayerClass.pID

        if IsPedInMeleeCombat(myPed) then
            if GetEntityHealth(myPed) < ConfigKO.MiniumHPToActive then
                SetPlayerInvincible(myPedId, false)
				SetPedToRagdoll(myPed, 1000, 1000, 0, 0, 0, 0)
                ESX.ShowNotification(ConfigKO.Text)
                wait = 1
				knockedOut = true
			end
		end
		
		if knockedOut == true then		
			SetPlayerInvincible(myPedId, false)
			DisablePlayerFiring(myPedId, true)
			SetPedToRagdoll(myPed, 1000, 1000, 0, 0, 0, 0)
			ResetPedRagdollTimer(myPed)
			if wait >= 0 then
				count = count - 1
                if GetEntityHealth(myPed) <= ConfigKO.MaxHPToDisable then
                    SetEntityHealth(myPed, GetEntityHealth(myPed)+1)
                end

                if count == 0 then
					count = ConfigKO.Timer * 2.5
					wait = wait - 1
				end
            else
				SetPlayerInvincible(myPedId, false)
				knockedOut = false
			end
		end
	end
end)