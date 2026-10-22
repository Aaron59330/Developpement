local GoFastDejaFait = nil
-- Coordonée pour le point de début de mission
local GoFastEnCours = true
local BlipsGoFast = nil

RegisterNetEvent("Sync:GoFast")
AddEventHandler("Sync:GoFast", function(_GoFastDejaFait)
	GoFastDejaFait = _GoFastDejaFait
end)

-- Affichage du points sur la map
Citizen.CreateThread(function()
	while true do
		while GoFastDejaFait == nil do
			Wait(1000)
			GoFastDejaFait = 1
		end
		local sleepThread = 500
		local ped = PlayerPedId()
		local pedCoords = GetEntityCoords(ped)
		local dstCheck = GetDistanceBetweenCoords(pedCoords, ConfigGoFast.DebutMission, true)
		if dstCheck <= 4.2 then
			sleepThread = 5
			if dstCheck <= 4.2 then
				ESX.ShowHelpNotification((ConfigGoFast.Text):format(GoFastDejaFait))
				if IsControlJustPressed(0, 38) then
					if GoFastDejaFait > 0 then
						DebutMissionMenu()
					else
						ESX.ShowAdvancedNotification("GoFast", "~b~Livraison GoFast", "Aucun GoFast disponible, revient plus tard.", 'CHAR_LESTER_DEATHWISH', 8)
					end
				end
			end
		end
		Citizen.Wait(sleepThread)
	end
end)

function InitSell(coordsToSell, quoi)
	InitSellCars = not InitSellCars

	Citizen.CreateThread(function()
		while InitSellCars do
			local sleepThread = 2500
			local ped = PlayerPedId()
			local pedCoords = GetEntityCoords(ped)
			local dstCheck = GetDistanceBetweenCoords(pedCoords, coordsToSell, true)
			if GoFastEnCours then
				if dstCheck <= 10.0 then
					sleepThread = 0
					AddTextEntry("SHOW_DMX_TAKE_ITEM", ConfigGoFast.Text2)
					ESXCustom_Function_ClientSide:ShowFloatingHelp("SHOW_DMX_TAKE_ITEM", coordsToSell)
					if IsControlJustPressed(0, 38) then
						FinDeGoFast(quoi)
					end
				end
			end
			Citizen.Wait(sleepThread)
		end
	end)
end

-- Menu de début de mission 
function DebutMissionMenu()
	local MainMenu = RageUI.CreateMenu("GoFast","Que voulez-vous faire ?")
    local camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", 1)
	local ped = PlayerPedId()
	SetCamCoord(camera, 757.9, -1865.39, 29.29)
	PointCamAtEntity(camera, ped, 0, 0, 0, 1)
	RenderScriptCams(1, 1, 1000, 1, 1)
	SetCamShakeAmplitude(camera, 3.0)

	local randomForSell = math.random(1, #ConfigGoFast.ZoneToSell)
	randomsell = ConfigGoFast.ZoneToSell[randomForSell]

	InitSell(randomsell, randomForSell)

    MainMenu.Closed = function()
        RenderScriptCams(0, 1, 1000, 1, 1)
		DestroyCam(camera, true)
	end

	RageUI.Visible(MainMenu, not RageUI.Visible(MainMenu))
	while MainMenu do
		Citizen.Wait(0)
		RageUI.IsVisible(MainMenu, true, true, true,function()
			RageUI.ButtonWithStyle("Commencer un GoFast", nil, {RightLabel = "→→→"}, true, function(_, _, Selected)
				if Selected then
					ESX.TriggerServerCallback('GoFast:Starting', function(CopsConnected)
						if CopsConnected >= ConfigGoFast.RequiredCops then
							TriggerServerEvent("GoFast:MoinUnGoFast")
							StartGoFast(randomsell)
						else
							blip = false
							ESX.ShowNotification("Il faut ~b~"..ConfigGoFast.RequiredCops.." policier~s~ pour lancer le gofast")
						end
					end)
					RenderScriptCams(0, 1, 1000, 1, 1)
					DestroyCam(camera, true)
					RageUI.CloseAll()
				end
			end)
		end, function()
		end, 1)

		if not RageUI.Visible(MainMenu) then
            MainMenu = RMenu:DeleteType('MainMenu')
        end
	end
end

function StartGoFast(randomsell)
	local ped = PlayerPedId()
	local timer = GetGameTimer()
	
	while true do
		Citizen.Wait(0)

		if GetGameTimer() - timer > 1000 then
			RequestModel(-1485523546)
			while not HasModelLoaded(-1485523546) do
				Citizen.Wait(0)
			end

			local veh = CreateVehicle(-1485523546, ConfigGoFast.SpawnVehicule, 265.5, true, true)
			SetVehicleNumberPlateText(veh, 'GOFAST')
			TaskEnterVehicle(ped, veh, 1000, -1, 1.0, 1, 0)
			SetModelAsNoLongerNeeded(-1485523546)
			SetModelAsNoLongerNeeded(veh)
			SetVehicleAsNoLongerNeeded(veh)
            ESX.ShowNotification("Vous avez pris le véhicule ~p~GoFast")
			GoFastEnCours = true
			break
		end
	end

	ClearDrawOrigin()
	TriggerServerEvent("GoFast:MessagePolice")
	GoFastBlips(randomsell)
	PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 1)
end


function GoFastBlips(coordsToSellBlipS)
	BlipsGoFast = AddBlipForCoord(coordsToSellBlipS)
	SetBlipSprite(BlipsGoFast, 272)
	SetBlipScale(BlipsGoFast, 0.5) -- set scale
	SetBlipColour(BlipsGoFast, 1)
	SetBlipAlpha(BlipsGoFast, 200)
	PulseBlip(BlipsGoFast)

	SetBlipRoute(BlipsGoFast,  true)

	while GoFastEnCours do
		SetBlipAlpha(BlipsGoFast, 200)
		Wait(1000)
	end
end

function FinDeGoFast(amount)
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsIn( ped, false )
	local plate = GetVehicleNumberPlateText(vehicle)
	if plate == ' GOFAST ' then
		SetVehicleEngineOn(vehicle, false, false, true)
		TaskLeaveAnyVehicle(ped, 1, 1)
		SetVehicleDoorsLocked(vehicle, 2)
        -- Ouverture de toute les portes
		Wait(2000)
		SetVehicleDoorOpen(vehicle, 0, false, false)
		SetVehicleDoorOpen(vehicle, 1, false, false)
		SetVehicleDoorOpen(vehicle, 2, false, false)
		SetVehicleDoorOpen(vehicle, 3, false, false)
		SetVehicleDoorOpen(vehicle, 4, false, false)
		SetVehicleDoorOpen(vehicle, 5, false, false)
		SetVehicleDoorOpen(vehicle, 6, false, false)
		SetVehicleDoorOpen(vehicle, 7, false, false)
		ESX.ShowAdvancedNotification("GoFast", "~b~Livraison GoFast", "Calcule du butin en cours ...", 'CHAR_LESTER_DEATHWISH', 8)
		Wait(5000)
		RemoveBlip(BlipsGoFast)
		TriggerServerEvent("GoFast:VenteDuVehicule", amount)
		PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 1)
		GoFastEnCours = false
	else
		ESX.ShowAdvancedNotification("GoFast", "~b~Livraison GoFast", "Hein ? C'est quoi ça ? C'est pas la voiture du GoFast !", 'CHAR_LESTER_DEATHWISH', 8)
		PlaySoundFrontend(-1, "CHECKPOINT_MISSED", "HUD_MINI_GAME_SOUNDSET", 1)
	end
end