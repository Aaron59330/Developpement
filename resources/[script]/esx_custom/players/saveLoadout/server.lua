-- RegisterServerEvent('esx:updateLoadout')
-- AddEventHandler('esx:updateLoadout', function(loadout)
-- 	local xPlayer = ESX.GetPlayerFromId(source)

-- 	if xPlayer then
-- 		for k, v in pairs(xPlayer.loadout) do
-- 			for q, z in pairs(loadout) do
-- 				if v.name == z.name then
-- 					v.ammo = z.ammo
-- 				end
-- 			end
-- 		end
-- 	end
-- end)

RegisterNetEvent('esx_custom:esx:updateWeaponAmmo')
AddEventHandler('esx_custom:esx:updateWeaponAmmo', function(weaponName, ammoCount)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer then
		xPlayer.updateWeaponAmmo(weaponName, ammoCount)
	end
end)