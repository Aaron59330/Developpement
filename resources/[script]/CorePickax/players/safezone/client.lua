local disabledSafeZonesKeys = {
	{group = 2, key = 37, message = '~r~Vous ne pouvez pas sortir d\'arme en zone safe'},
	{group = 0, key = 24, message = '~r~Vous ne pouvez pas faire ceci en zone safe'},
	{group = 0, key = 69, message = '~r~Vous ne pouvez pas faire ceci en zone safe'},
	{group = 0, key = 92, message = '~r~Vous ne pouvez pas faire ceci en zone safe'},
	{group = 0, key = 140, message = '~r~Vous ne pouvez pas faire ceci en zone safe'},
	{group = 0, key = 106, message = '~r~Vous ne pouvez pas faire ceci en zone safe'}
}

local notifIn, notifOut = false, false
local closestZone = 1

Citizen.CreateThread(function()
	while not NetworkIsPlayerActive(PlayerId()) do
		Citizen.Wait(0)
	end

	while true do
		local plyPed = PlayerPedId()
		local plyCoords = GetEntityCoords(plyPed, false)
		local minDistance = 100000

		for i = 1, #ConfigSafeZone.safeZones, 1 do
			local dist = #(ConfigSafeZone.safeZones[i] - plyCoords)

			if dist < minDistance then
				minDistance = dist
				closestZone = i
			end
		end

		Citizen.Wait(15000)
	end
end)

Citizen.CreateThread(function()
	while not NetworkIsPlayerActive(PlayerId()) do
		Citizen.Wait(0)
	end
	while true do
		local timer = 350
		local plyPed = PlayerPedId()
		local plyCoords = GetEntityCoords(plyPed, false)
		local dist = #(ConfigSafeZone.safeZones[closestZone] - plyCoords)
	
		if dist <= 70 then
			timer = 0
		end
		Citizen.Wait(timer)
		local plyPed = PlayerPedId()
		local plyCoords = GetEntityCoords(plyPed, false)
		local dist = #(ConfigSafeZone.safeZones[closestZone] - plyCoords)

		if dist <= 50 then
			if not notifIn then
				NetworkSetFriendlyFireOption(false)
				SetCurrentPedWeapon(plyPed, `WEAPON_UNARMED`, true)
				ESX.ShowNotification('~g~Vous êtes en zone safe')

				notifIn = true
				notifOut = false
			end
		else
			if not notifOut then
				NetworkSetFriendlyFireOption(true)
				ESX.ShowNotification('~r~Vous n\'êtes plus en zone safe')

				notifOut = true
				notifIn = false
			end
		end

		if notifIn then
			--NO OPTI FONCTIONNEL !
			-- for vehicle in ESXCustom.Game.EnumerateVehicles() do
			-- 	if not IsVehicleSeatFree(vehicle, -1) then
			-- 		SetEntityNoCollisionEntity(plyPed, vehicle, true)
			-- 		SetEntityNoCollisionEntity(vehicle, plyPed, true)
			-- 	end
			-- end
			--OPTI FONCTIONNEL !
			local myCoord = GetEntityCoords(PlayerPedId())
			local closestVeh = GetClosestVehicle(myCoord.x, myCoord.y, myCoord.z, 4.0, 0, 71)
			if closestVeh ~= 0 and closestVeh > 1.0 then
				timeToSleep = 1;
				SetEntityNoCollisionEntity(closestVeh, PlayerPedId(), true)
			end

			DisablePlayerFiring(player, true)

			for i = 1, #disabledSafeZonesKeys, 1 do
				DisableControlAction(disabledSafeZonesKeys[i].group, disabledSafeZonesKeys[i].key, true)

				if IsDisabledControlJustPressed(disabledSafeZonesKeys[i].group, disabledSafeZonesKeys[i].key) then
					SetCurrentPedWeapon(player, `WEAPON_UNARMED`, true)

					if disabledSafeZonesKeys[i].message then
						ESX.ShowNotification(disabledSafeZonesKeys[i].message)
					end
				end
			end

			if ConfigSafeZone.SeeText then
				if not InAFK then
					RageUI.Text({message = "~g~Vous êtes protéger par la zone safe~s~", time_display = 1})
				end
			end
		end
	end
end)

function GetSafeZone()
	return notifIn
end

exports("GetSafeZone", GetSafeZone)