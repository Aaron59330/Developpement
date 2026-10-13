local NeedBag = true
bigWeaponOut = false
smallWeaponOut = false
meleeWeaponOut = false

Citizen.CreateThread(function()
	while true do
		Wait(250)

		playerPed = GetPlayerPed(-1)
		if playerPed then
			local weapon = GetSelectedPedWeapon(playerPed, true)
			if isWeaponBig(weapon) then
				local vehicle = VehicleInFront()
				if GetVehiclePedIsIn(playerPed, false) == 0 and DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) and bigWeaponOut == false then
					bigWeaponOut = true
					SetVehicleDoorOpen(vehicle, 5, false, false)
					Citizen.Wait(2000)
					SetVehicleDoorShut(vehicle, 5, false)
				else
					if NeedBag == true then
						if IsPedModel(playerPed,1885233650) and bigWeaponOut == false and GetVehiclePedIsIn(playerPed, false) == 0 then -- male
							local bagIndex = GetPedDrawableVariation(PlayerPedId(), 5)
							if Config.NeedBags.ListBags[bagIndex] ~= nil then
								bigWeaponOut = true
							else
								ESX.ShowNotification("~r~Action Impossible~s~ : Vous devez disposer d'un sac ou être proche d'une voiture.")
								Wait(1)
								SetCurrentPedWeapon(playerPed, -1569615261)
							end
						else	
							if IsPedModel(playerPed,-1667301416) and bigWeaponOut == false and GetVehiclePedIsIn(playerPed, false) == 0 then -- female
								local bagIndex = GetPedDrawableVariation(PlayerPedId(), 5)
								if Config.NeedBags.ListBags[bagIndex] ~= nil then
									bigWeaponOut = true
								else
									ESX.ShowNotification("~r~Action Impossible~s~ : Vous devez disposer d'un sac ou être proche d'une voiture.")
									Wait(1)
									SetCurrentPedWeapon(playerPed, -1569615261)
								end
							else
								if bigWeaponOut == false and GetVehiclePedIsIn(playerPed, false) == 0 then
									Wait(1)
									SetCurrentPedWeapon(playerPed, -1569615261)
								end
							end
						end
					else
						if bigWeaponOut == false and GetVehiclePedIsIn(playerPed, false) == 0 then
							local bagIndex = GetPedDrawableVariation(PlayerPedId(), 5)
							if Config.NeedBags.ListBags[bagIndex] == nil then
								ESX.ShowNotification("~r~Action Impossible~s~ : Vous devez disposer d'un sac ou être proche d'une voiture.")
								Wait(1)
								SetCurrentPedWeapon(playerPed, -1569615261)
							end
						end
					end
				end
			end
			if GetVehiclePedIsIn(playerPed, false) == 0 and isWeaponSmall(weapon) then
				if smallWeaponOut == false then
					smallWeaponOut = true
					Citizen.Wait(100)
				end
			end
			if GetVehiclePedIsIn(playerPed, false) == 0 and isWeaponMelee(weapon) then
				if meleeWeaponOut == false then
					meleeWeaponOut = true
					Citizen.Wait(100)
				end
			end
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Wait(500)
		
		playerPed = GetPlayerPed(-1)
		if playerPed then
			local weapon = GetSelectedPedWeapon(playerPed, true)
			if not isWeaponBig(weapon) and bigWeaponOut == true then
				Wait(100)
				bigWeaponOut = false
			end
			if not isWeaponSmall(weapon) and smallWeaponOut == true then
				Wait(100)
				smallWeaponOut = false
			end
			if not isWeaponMelee(weapon) and meleeWeaponOut == true then
				Wait(100)
				meleeWeaponOut = false
			end
		end
	end
end)

function VehicleInFront()
	local player = PlayerPedId()
    local pos = GetEntityCoords(player)
    local entityWorld = GetOffsetFromEntityInWorldCoords(player, 0.0, 2.0, 0.0)
    local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 30, player, 0)
    local _, _, _, _, result = GetRaycastResult(rayHandle)
    return result
end

function isWeaponBig(model)
	for _, bigWeapon in pairs(Config.NeedBags.bigweaponslist) do
		if model == GetHashKey(bigWeapon) then
			return true
		end
	end

	return false
end

function isWeaponSmall(model)
	for _, smallWeapon in pairs(Config.NeedBags.smallweaponslist) do
		if model == GetHashKey(smallWeapon) then
			return true
		end
	end

	return false
end

function isWeaponMelee(model)
	for _, meleeWeapon in pairs(Config.NeedBags.meleeweaponslist) do
		if model == GetHashKey(meleeWeapon) then
			return true
		end
	end

	return false
end