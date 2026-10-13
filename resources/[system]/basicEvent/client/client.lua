Citizen.CreateThread(function()
	local isDead = false
	local hasBeenDead = false
	local diedAt

	while true do
		Citizen.Wait(0)
		local player = PlayerId()

		if NetworkIsPlayerActive(player) then
			local ped = PlayerPedId()

			if IsPedFatallyInjured(ped) and not isDead then
				isDead = true
				if not diedAt then
					diedAt = GetGameTimer()
				end

				local killer, killerweapon = NetworkGetEntityKillerOfPlayer(player)
				local killerentitytype = GetEntityType(killer)
				local killertype = -1
				local killerinvehicle = false
				local killervehiclename = ''
				local killervehicleseat = 0

				if killerentitytype == 1 then
					killertype = GetPedType(killer)
					if IsPedInAnyVehicle(killer, false) == 1 then
						killerinvehicle = true
						killervehiclename = GetDisplayNameFromVehicleModel(GetEntityModel(GetVehiclePedIsUsing(killer)))
						killervehicleseat = GetPedVehicleSeat(killer)
					else
						killerinvehicle = false
					end
				end

				local killerid = GetPedSourceOfDeath(PlayerPedId())
				if killer ~= ped and killerid ~= nil then
					killerid = GetPlayerServerId(NetworkGetPlayerIndexFromPed(killerid))
				else
					killerid = -1
				end

				if killer == ped or killer == -1 then
					TriggerEvent('baseevents:onPlayerDied', killertype, GetEntityCoords(ped, false))
					TriggerServerEvent('baseevents:onPlayerDied', killertype, GetEntityCoords(ped, false))
					hasBeenDead = true
				else
					TriggerEvent('baseevents:onPlayerKilled', killerid, {killedPlayer = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped)), killertype = killertype, weaponhash = killerweapon, killerinveh = killerinvehicle, killervehseat = killervehicleseat, killervehname = killervehiclename, killerpos = GetEntityCoords(ped, false)})
					TriggerServerEvent('baseevents:onPlayerKilled', killerid, {killedPlayer = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped)), killertype = killertype, weaponhash = killerweapon, killerinveh = killerinvehicle, killervehseat = killervehicleseat, killervehname = killervehiclename, killerpos = GetEntityCoords(ped, false)})
					hasBeenDead = true
				end
			elseif not IsPedFatallyInjured(ped) then
				isDead = false
				diedAt = nil
			end

			if not hasBeenDead and diedAt ~= nil and diedAt > 0 then
				TriggerEvent('baseevents:onPlayerWasted', GetEntityCoords(ped, false))
				TriggerServerEvent('baseevents:onPlayerWasted', GetEntityCoords(ped, false))
				hasBeenDead = true
			elseif hasBeenDead and diedAt ~= nil and diedAt <= 0 then
				hasBeenDead = false
			end
		end
	end
end)

function GetPedVehicleSeat(ped)
	local vehicle = GetVehiclePedIsIn(ped, false)

	for i = -2, GetVehicleMaxNumberOfPassengers(vehicle) do
		if GetPedInVehicleSeat(vehicle, i) == ped then
			return i
		end
	end

	return -2
end