-- local InfoWeapon = {}

-- Citizen.CreateThread(function()
-- 	Wait(5000)
-- 	while true do
-- 		Citizen.Wait(5000)
--         InfoWeapon = {}
--         for k, v in pairs(ESX.PlayerData.loadout) do
--             table.insert(InfoWeapon, {ammo = GetAmmoInPedWeapon(PlayerPedId(), v.name), name = v.name})
--         end

-- 		TriggerServerEvent('esx:updateLoadout', InfoWeapon)
-- 	end
-- end)

local weaponsByHash = {}
CreateThread(function()
	local Conf = ESX.GetConfig()
	for index, weapon in pairs(Conf.Weapons) do
		weaponsByHash[joaat(weapon.name)] = weapon
	end
end)

local GetWeaponFromHash = function(weaponHash)
	weaponHash = type(weaponHash) == "string" and joaat(weaponHash) or weaponHash

	return weaponsByHash[weaponHash]
end

Citizen.CreateThread(function()
	local currentWeapon = {Ammo = 0}
	while true do
		local sleep = 1500
		if GetSelectedPedWeapon(PlayerPedId()) ~= -1569615261 then
			sleep = 1000
			local _, weaponHash = GetCurrentPedWeapon(PlayerPedId(), true)
			local weapon = GetWeaponFromHash(weaponHash)
			if weapon then
				local ammoCount = GetAmmoInPedWeapon(PlayerPedId(), weaponHash)
				if weapon.name ~= currentWeapon.name then
					currentWeapon.Ammo = ammoCount
					currentWeapon.name = weapon.name
				else
					if ammoCount ~= currentWeapon.Ammo then
						currentWeapon.Ammo = ammoCount
						TriggerServerEvent('esx_custom:esx:updateWeaponAmmo', weapon.name, ammoCount)
					end
				end
			end
		end
		Wait(sleep)
	end
end)