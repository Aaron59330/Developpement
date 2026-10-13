local sortir = false
local encour = false

Citizen.CreateThread(function ()
	while true do
		local timer = 300
		for i = 1, #ConfigDouche.douche do
			coorddouche = ConfigDouche.douche[i]
			if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), coorddouche[1], coorddouche[2], coorddouche[3], true ) < 2 then
				timer = 0

				if encour == false then
					ESX.ShowHelpNotification(ConfigDouche.Text)
					if IsControlJustPressed(1, 51) then
						ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
							if skin.sex == 0 then
								local clothesSkin = { -- male skins , change if u have addon clothes
								['bags_1'] = 0, ['bags_2'] = 0,
								['tshirt_1'] = 15, ['tshirt_2'] = 15,
								['torso_1'] = 15, ['torso_2'] = 0,
								['arms'] = 15,
								['pants_1'] = 61, ['pants_2'] = 6,
								['shoes_1'] = 34, ['shoes_2'] = 0,
								['mask_1'] = 0, ['mask_2'] = 0,
								['bproof_1'] = 0,
								['helmet_1'] = -1, ['helmet_2'] = 0,
								["decals_1"] = -1, ["decals_2"] = 0,
								['chain_1'] = 0, ['chain_2'] = 0,
								['glasses_1'] = 0, ['glasses_2'] = 0
								}
								TriggerEvent('skinchanger:loadClothes', skin, clothesSkin)
							else
								local clothesSkinfemale = { -- female skins , change if u have addon clothes
									['bags_1'] = 0, ['bags_2'] = 0,
									['tshirt_1'] = 15, ['tshirt_2'] = 15,
									['torso_1'] = 15, ['torso_2'] = 0,
									['arms'] = 15,
									['pants_1'] = 61, ['pants_2'] = 6,
									['shoes_1'] = 34, ['shoes_2'] = 0,
									['mask_1'] = 0, ['mask_2'] = 0,
									['bproof_1'] = 0,
									['helmet_1'] = -1, ['helmet_2'] = 0,
									["decals_1"] = -1, ["decals_2"] = 0,
									['chain_1'] = 0, ['chain_2'] = 0,
									['glasses_1'] = 0, ['glasses_2'] = 0
								}
								TriggerEvent('skinchanger:loadClothes', skin, clothesSkinfemale)
							end
						end)
						local coords = GetEntityCoords(PlayerPedId())
						encour = true
						FreezeEntityPosition((PlayerPedId()), true)
						if not HasNamedPtfxAssetLoaded("core") then
							RequestNamedPtfxAsset("core")
							while not HasNamedPtfxAssetLoaded("core") do
								Wait(1)
							end
						end
						TaskStartScenarioInPlace((PlayerPedId()), "PROP_HUMAN_STAND_IMPATIENT", 0, true)
						UseParticleFxAssetNextCall("core") particles  = StartParticleFxLoopedAtCoord("ent_sht_water", coords.x, coords.y, coords.z +1.2, 0.0, 0.0, 0.0, 1.0, false, false, false, false) UseParticleFxAssetNextCall("core") Citizen.Wait(3000) particles2  = StartParticleFxLoopedAtCoord("ent_sht_water", coords.x, coords.y, coords.z +1.2, 0.0, 0.0, 0.0, 1.0, false, false, false, false) UseParticleFxAssetNextCall("core") Citizen.Wait(3000) particles3  = StartParticleFxLoopedAtCoord("ent_sht_water", coords.x, coords.y, coords.z +1.2, 0.0, 0.0, 0.0, 1.0, false, false, false, false) UseParticleFxAssetNextCall("core") Citizen.Wait(3000) particles4  = StartParticleFxLoopedAtCoord("ent_sht_water", coords.x, coords.y, coords.z +1.2, 0.0, 0.0, 0.0, 1.0, false, false, false, false) UseParticleFxAssetNextCall("core") Citizen.Wait(3000) particles5  = StartParticleFxLoopedAtCoord("ent_sht_water", coords.x, coords.y, coords.z +1.2, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
						timer = 8
						sortir = true
						Citizen.CreateThread(function()
							while sortir do
								Citizen.Wait(0)
								Citizen.Wait(1000)
								if(timer > 0)then
									timer = timer - 1
								elseif (timer == 0) then
									encour = false
									FreezeEntityPosition((PlayerPedId()), false)
									ESX.ShowNotification("~g~Vous vous êtes laver.~s~")
									ClearPedTasksImmediately(PlayerPedId()) 
									ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
										TriggerEvent('skinchanger:loadSkin', skin)
									end)
									StopParticleFxLooped(particles, 0) StopParticleFxLooped(particles2, 0) StopParticleFxLooped(particles3, 0) StopParticleFxLooped(particles4, 0) StopParticleFxLooped(particles5, 0)
									sortir = false
								end
							end
						end)
					end
				end
			end
		end
		Citizen.Wait(timer)
	end
end)