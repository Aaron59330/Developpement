local isTackling = false
local isGettingTackled = false
local tackleLib = 'missmic2ig_11'
local tackleAnim = 'mic_2_ig_11_intro_goon'
local tackleVictimAnim = 'mic_2_ig_11_intro_p_one'
local lastTackleTime = 0
local isRagdoll = false

Citizen.CreateThread(function()
	while true do
        local timer = 200

		if isRagdoll then
            timer = 0
			SetPedToRagdoll(GetPlayerPed(-1), 1000, 1000, 0, 0, 0, 0)
		end
        Citizen.Wait(timer)
	end
end)

RegisterNetEvent('esx_kekke_tackle:getTackled')
AddEventHandler('esx_kekke_tackle:getTackled', function(target)
	isGettingTackled = true
	local playerPed = GetPlayerPed(-1)
	local targetPed = GetPlayerPed(GetPlayerFromServerId(target))
	RequestAnimDict(tackleLib)
	while not HasAnimDictLoaded(tackleLib) do
		Citizen.Wait(10)
	end
	AttachEntityToEntity(GetPlayerPed(-1), targetPed, 11816, 0.25, 0.5, 0.0, 0.5, 0.5, 180.0, false, false, false, false, 2, false)
	TaskPlayAnim(playerPed, tackleLib, tackleVictimAnim, 8.0, -8.0, 3000, 0, 0, false, false, false)
	Citizen.Wait(3000)
	DetachEntity(GetPlayerPed(-1), true, false)
	isRagdoll = true
	Citizen.Wait(3000)
	isRagdoll = false
	isGettingTackled = false
end)

RegisterNetEvent('esx_kekke_tackle:playTackle')
AddEventHandler('esx_kekke_tackle:playTackle', function()
	local playerPed = GetPlayerPed(-1)
	RequestAnimDict(tackleLib)
	while not HasAnimDictLoaded(tackleLib) do
		Citizen.Wait(10)
	end
	TaskPlayAnim(playerPed, tackleLib, tackleAnim, 8.0, -8.0, 3000, 0, 0, false, false, false)
	Citizen.Wait(3000)
	isTackling = false
end)

-- Main thread
Citizen.CreateThread(function()
	while true do
        local timer = 200
		if IsControlPressed(0, 21) and IsControlPressed(0, 47) and not isTackling and GetGameTimer() - lastTackleTime > 10 * 1000 then
			Citizen.Wait(10)
			local closestPlayer, distance = ESX.Game.GetClosestPlayer()
			if distance ~= -1 and distance <= ConfigTacle.TackleDistance and not isTackling and not isGettingTackled and not IsPedInAnyVehicle(GetPlayerPed(-1)) and not IsPedInAnyVehicle(GetPlayerPed(closestPlayer)) then
				isTackling = true
				lastTackleTime = GetGameTimer()
				TriggerServerEvent('esx_kekke_tackle:tryTackle', GetPlayerServerId(closestPlayer))
			end
		end
        Wait(timer)
	end
end)