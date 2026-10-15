local IsDeadB = false
local IsAnimated = false

----DRUGS----

RegisterNetEvent('esx_basicneeds:onSmokeweed')
AddEventHandler('esx_basicneeds:onSmokeweed', function()
  TaskStartScenarioInPlace(GetPlayerPed(-1), "WORLD_HUMAN_SMOKING_POT", 0, 1)
  emotePlay = true
  Citizen.Wait(150000)
  ClearPedTasksImmediately(GetPlayerPed(-1))
 emotePlay = false
end)

function stopEmote()
	ClearPedTasks(GetPlayerPed(-1))
	emotePlay = false
end

Citizen.CreateThread(function()
	while true do
		local timer = 200
		if emotePlay then
			timer = 0
			if IsControlJustPressed(1, 22) or IsControlJustPressed(1, 30) or IsControlJustPressed(1, 31) then
			  stopEmote()
			end
	  	end
		Citizen.Wait(timer)
	end
end)

  ------------------------------------
AddEventHandler('esx_basicneeds:resetStatus', function()
	TriggerEvent('esx_status:set', 'hunger', 500000)
	TriggerEvent('esx_status:set', 'thirst', 500000)
end)

AddEventHandler('esx:onPlayerDeath', function()
	IsDeadB = true
end)

AddEventHandler('playerSpawned', function(spawn)
	if IsDeadB then
		TriggerEvent('esx_basicneeds:resetStatus')
	end

	IsDeadB = false
end)

local Notify = {}
AddEventHandler('esx_status:loaded', function(status)
	TriggerEvent('esx_status:registerStatus', 'hunger', 1000000, 'fas fa-hamburger blue', function(status)
		return true
	end, function(status)
		status.remove(30)
	end)

	TriggerEvent('esx_status:registerStatus', 'thirst', 1000000, 'fas fa-tint blue', function(status)
		return true
	end, function(status)
		status.remove(50)
	end)

	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(1000)

			local playerPed  = PlayerPedId()
			local prevHealth = GetEntityHealth(playerPed)
			local health = prevHealth

			TriggerEvent('esx_status:getStatus', 'hunger', function(status)
				if status.val < 90000 then
					if Notify["hunger"] == nil then
						Notify["hunger"] = false
					end
					if not Notify["hunger"] then
						Notify["hunger"] = true
						ESX.ShowNotification("Vous avez extremement faim")
					end
				else
					if Notify["hunger"] ~= nil and not Notify["hunger"] == false then
						Notify["hunger"] = false
					end
				end

				if status.val == 0 then
					if prevHealth <= 150 then
						health = health - 3
					else
						health = health - 1
					end
				end
			end)

			TriggerEvent('esx_status:getStatus', 'thirst', function(status)
				if status.val < 90000 then
					if Notify["thirst"] == nil then
						Notify["thirst"] = false
					end
					if not Notify["thirst"] then
						Notify["thirst"] = true
						ESX.ShowNotification("Vous avez extremement soif")
					end
				else
					if Notify["thirst"] ~= nil and not Notify["thirst"] == false then
						Notify["thirst"] = false
					end
				end
				if status.val == 0 then
					if prevHealth <= 150 then
						health = health - 3
					else
						health = health - 1
					end
				end
			end)

			if health ~= prevHealth then
				SetEntityHealth(playerPed, health)
			end
		end
	end)
end)

AddEventHandler('esx_basicneeds:isEating', function(cb)
	cb(IsAnimated)
end)

for k, v in pairs(ConfigBasicNeeds.RegisterItemUsableClientSide) do
	RegisterNetEvent('esx_basicneeds:onEat'..v.name)
	AddEventHandler('esx_basicneeds:onEat'..v.name, function(prop_name)
		v.IsUsed(prop_name)
	end)
end