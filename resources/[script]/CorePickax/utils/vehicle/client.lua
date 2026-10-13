if ConfigVehicle.Bikerick == true then
	Citizen.CreateThread(function()
		while true do
			local timer = 500
			if IsThisModelABicycle(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false))) or IsThisModelABike(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false))) and GetEntitySpeed(GetVehiclePedIsIn(PlayerPedId(), false)) * 3.6 >= 10 then timer = 0 end
			Citizen.Wait(timer)

			if IsControlPressed(0, 21) and IsControlJustReleased(0, 172) then
				if IsThisModelABicycle(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false))) or IsThisModelABike(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false))) and GetEntitySpeed(GetVehiclePedIsIn(PlayerPedId(), false)) * 3.6 >= 10 then
					RequestAnimDict('rcmextreme2atv')
					while not HasAnimDictLoaded('rcmextreme2atv') do
						Citizen.Wait(100)
					end
					TaskPlayAnim(PlayerPedId(), 'rcmextreme2atv', 'idle_e', -1, -1, -1, 32, 0, 0, 0, 0)
				end
			end

			if IsControlPressed(0, 21) and IsControlJustReleased(0, 173) then
				if IsThisModelABicycle(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false))) or IsThisModelABike(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false))) and GetEntitySpeed(GetVehiclePedIsIn(PlayerPedId(), false)) * 3.6 >= 10 then
					RequestAnimDict('rcmextreme2atv')
					while not HasAnimDictLoaded('rcmextreme2atv') do
						Citizen.Wait(100)
					end
					TaskPlayAnim(PlayerPedId(), 'rcmextreme2atv', 'idle_d', -1, -1, -1, 32, 0, 0, 0, 0)
				end	
			end

			if IsControlPressed(0, 21) and IsControlJustReleased(0, 174) then
				if IsThisModelABicycle(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false))) or IsThisModelABike(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false))) and GetEntitySpeed(GetVehiclePedIsIn(PlayerPedId(), false)) * 3.6 >= 10 then
					RequestAnimDict('rcmextreme2atv')
					while not HasAnimDictLoaded('rcmextreme2atv') do
						Citizen.Wait(100)
					end
					TaskPlayAnim(PlayerPedId(), 'rcmextreme2atv', 'idle_b', -1, -1, -1, 32, 0, 0, 0, 0)
				end	
			end

			if IsControlPressed(0, 21) and IsControlJustReleased(0, 175) then
				if IsThisModelABicycle(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false))) or IsThisModelABike(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false))) and GetEntitySpeed(GetVehiclePedIsIn(PlayerPedId(), false)) * 3.6 >= 10 then
					RequestAnimDict('rcmextreme2atv')
					while not HasAnimDictLoaded('rcmextreme2atv') do
						Citizen.Wait(100)
					end
					TaskPlayAnim(PlayerPedId(), 'rcmextreme2atv', 'idle_c', -1, -1, -1, 32, 0, 0, 0, 0)
				end	
			end

		end
	end)
end

if ConfigVehicle.ChangeSeat == true then
	-- DESACTIVER LE CHANGEMENT DE PLACE AUTO

	local disableShuffle = true
	function disableSeatShuffle(flag)
		disableShuffle = flag
	end

	Citizen.CreateThread(function()
		while true do
			local timer = 2500
			if IsPedInAnyVehicle(GetPlayerPed(-1), false) and disableShuffle then timer = 0 end
			Citizen.Wait(timer)
			if IsPedInAnyVehicle(GetPlayerPed(-1), false) and disableShuffle then
				if GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1), false), 0) == GetPlayerPed(-1) then
					if GetIsTaskActive(GetPlayerPed(-1), 165) then
						SetPedIntoVehicle(GetPlayerPed(-1), GetVehiclePedIsIn(GetPlayerPed(-1), false), 0)
					end
				end
			end
		end
	end)

	-- KEYBIND CHANGEMENT PLACE VEHICLE
	Citizen.CreateThread(function()
	    while true do
			local timer = 2500
			if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
				timer = 0
			end
			Citizen.Wait(timer)

	        local plyPed = PlayerPedId()
	        if IsPedSittingInAnyVehicle(plyPed) then
	            local plyVehicle = GetVehiclePedIsIn(plyPed, false)
				CarSpeed = GetEntitySpeed(plyVehicle) * 3.6 -- On définit la vitesse du véhicule en km/h
				if CarSpeed <= 60.0 then -- On ne peux pas changer de place si la vitesse du véhicule est au dessus ou égale à 60 km/h
					if IsControlJustReleased(0, 157) then -- conducteur
						SetPedIntoVehicle(plyPed, plyVehicle, -1)
						Citizen.Wait(10)
					end
					if IsControlJustReleased(0, 158) then -- avant droit
						SetPedIntoVehicle(plyPed, plyVehicle, 0)
						Citizen.Wait(10)
					end
					if IsControlJustReleased(0, 160) then -- arriere gauche
						SetPedIntoVehicle(plyPed, plyVehicle, 1)
						Citizen.Wait(10)
					end
					if IsControlJustReleased(0, 164) then -- arriere gauche
						SetPedIntoVehicle(plyPed, plyVehicle, 2)
						Citizen.Wait(10)
					end
				end
			end
		end
	end)
end


--Receive cache on Client side
local CacheKeys = {}
RegisterNetEvent("CorePickax:ReceiveClientSideKeys", function(ReceiveInfo)
    CacheKeys = ReceiveInfo
end)
RegisterNetEvent("esx:playerLoaded", function(xPlayer)
    Wait(5000)
    TriggerServerEvent("CorePickax:SendServerSideKeys")
end)
Citizen.CreateThread(function()
    Wait(5000)
    TriggerServerEvent("CorePickax:SendServerSideKeys")
end)
--Fin du cache load
if not ConfigVehicle.DisableKey then
    Citizen.CreateThread(function()
            while true do
                local timer = 200
                for k,v in pairs(ConfigVehicle.Positions) do
                    local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
                    local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, v.x, v.y, v.z)
                    if dist <= 10.0 then
                        timer = 0
                    end
                end
        
                Citizen.Wait(timer)
        
                for k,v in pairs(ConfigVehicle.Positions) do
                    local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
                    local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, v.x, v.y, v.z)

                    if dist <= ConfigVehicle.Marker.Distance then 
                        wait = 0
                        DrawGlobalMarker(ConfigVehicle.Marker.MarkerType, v.x, v.y, v.z-ConfigVehicle.Marker.MarkerDebug, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ConfigVehicle.Marker.Scale.x, ConfigVehicle.Marker.Scale.y, ConfigVehicle.Marker.Scale.z, ConfigVehicle.Marker.Color.r, ConfigVehicle.Marker.Color.g, ConfigVehicle.Marker.Color.b, ConfigVehicle.Marker.Color.a, ConfigVehicle.Marker.BobUpAndDown, ConfigVehicle.Marker.FaceCamera, p19, ConfigVehicle.Marker.Rotate)
                    end
            
                    if dist <= ConfigVehicle.Marker.PushEDistance then 
                        wait = 0 
                        ESX.ShowHelpNotification(ConfigVehicle.Marker.PushEText)
                        if IsControlJustPressed(1,51) then
                            OpenMenuListeClef()
                        end
                    end
                end
            end
    end)
    
    function OpenMenuListeClef()
        local MenuClef = RageUI.CreateMenu(ConfigVehicle.MenuEtNotification["Title1"], ConfigVehicle.MenuEtNotification["SubTitle1"])
        ListeClef = {}
        ESX.TriggerServerCallback('CorePickax:getVehiclesnokey', function(Vehicles2)
            ListeClef = Vehicles2
        end)
    
        RageUI.Visible(MenuClef, not RageUI.Visible(MenuClef))
        while MenuClef do
            RageUI.IsVisible(MenuClef, true, true, true, function()
                if #ListeClef == 0 then
                    RageUI.Separator("")
                    RageUI.Separator(ConfigVehicle.MenuEtNotification["NoKeys"])
                    RageUI.Separator("")
                else
                    RageUI.Separator(ConfigVehicle.MenuEtNotification["NewKeys"])
                    for i=1, #ListeClef, 1 do
                        model = ListeClef[i].model
                        modelname = GetDisplayNameFromVehicleModel(model)
                        ListeClef[i].model = GetLabelText(modelname)
                    end
    
                    for i=1, #ListeClef, 1 do
                        if ListeClef[i].model ~= nil and ListeClef[i].plate ~= nil and ListeClef[i].plate ~= "nil" then
                            RageUI.ButtonWithStyle((ConfigVehicle.MenuEtNotification["Button"]):format(ListeClef[i].model, ListeClef[i].plate), nil, { RightLabel = "→→→" }, true, function(_,_,s)
                                if s then
                                    TriggerServerEvent('CorePickax:registerkey', ListeClef[i].plate, 'no')
                                    RageUI.CloseAll()
                                end
                            end)
                        end
                    end
                end
            end, function()
            end, 1)
    
            if not RageUI.Visible(MenuClef) then
                MenuClef = RMenu:DeleteType("MenuClef")
            end
    
            Citizen.Wait(1)
        end
    end
end

if not ConfigVehicle.DisableMenuKey then
    --Menu clef
    ItemIndexCarKeys = {}

    function OpenKeyMenu()
        local mainmenu = RageUI.CreateMenu(ConfigVehicle.MenuEtNotification["YourKeys"], ConfigVehicle.MenuEtNotification["YourKeysSub"])
    
        RageUI.Visible(mainmenu, not RageUI.Visible(mainmenu))
        while mainmenu do
            Wait(0)
            RageUI.IsVisible(mainmenu, true, true, true, function()
                if CacheKeys ~= nil then
                    if #CacheKeys == 0 then
                        RageUI.Separator("")
                        RageUI.Separator(ConfigVehicle.MenuEtNotification["NoKeys2"])
                        RageUI.Separator("")
                    else
                        for i=1, #CacheKeys, 1 do
                            if CacheKeys[i].got == 'true' then
                                if CacheKeys[i].value ~= nil then
                                    if ConfigVehicle.CanGiveKey then
                                        if CacheKeys[i].NB == 1 then
                                            RageUI.List((ConfigVehicle.MenuEtNotification["Button2"]):format(CacheKeys[i].value), {ConfigVehicle.MenuEtNotification["Give"], ConfigVehicle.MenuEtNotification["Lend"]}, ItemIndexCarKeys[CacheKeys[i].value] or 1, nil, {}, true, function(Hovered, Active, Selected, Index)
                                                ItemIndexCarKeys[CacheKeys[i].value] = Index
                                                if Selected then
                                                    local player, distance = ESX.Game.GetClosestPlayer()
                                                    if Index == 1 then
                                                        if player ~= -1 and distance < 3.0 then
                                                            TriggerServerEvent('CorePickax:donnerkey', GetPlayerServerId(player), CacheKeys[i].value)
                                                        else 
                                                            ESX.ShowNotification(ConfigVehicle.MenuEtNotification["NoPerson"])
                                                        end
                                                    elseif Index == 2 then
                                                        if player ~= -1 and distance < 3.0 then 
                                                            TriggerServerEvent('CorePickax:preterkey', GetPlayerServerId(player), CacheKeys[i].value)
                                                        else
                                                            ESX.ShowNotification(ConfigVehicle.MenuEtNotification["NoPerson"])
                                                        end
                                                    end
                                                end
                                            end)
                                        elseif CacheKeys[i].NB == 2 then
                                            RageUI.List((ConfigVehicle.MenuEtNotification["Button3"]):format(CacheKeys[i].value), {ConfigVehicle.MenuEtNotification["Error"]}, ItemIndexCarKeys[CacheKeys[i].value] or 1, nil, {}, true, function(Hovered, Active, Selected, Index)
                                                ItemIndexCarKeys[CacheKeys[i].value] = Index
                                            end)
                                        end
                                    else
                                        RageUI.ButtonWithStyle((ConfigVehicle.MenuEtNotification["Button2"]):format(CacheKeys[i].value), nil, { RightLabel = "→→→" }, true, function(_,_,s)
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
    
            if not RageUI.Visible(mainmenu) then 
                mainmenu = RMenu:DeleteType("mainmenu")
            end
        end
    end

    RegisterNetEvent("CorePickax:OpenKeyMenuCar", function()
        OpenKeyMenu()
    end)

    RegisterKeyMapping(ConfigVehicle.Commande.CommandeName, ConfigVehicle.Commande.DescCommande, 'keyboard', ConfigVehicle.Commande.Bind)

    RegisterCommand(ConfigVehicle.Commande.CommandeName, function()
        TriggerEvent("CorePickax:OpenKeyMenuCar")
    end, false)
end

local playerCars = {}
function OpenCloseVehicle()
	local playerPed = GetPlayerPed(-1)
	local coords    = GetEntityCoords(playerPed, true)
	local vehicle = nil
	if IsPedInAnyVehicle(playerPed,  false) then
		vehicle = GetVehiclePedIsIn(playerPed, false)
	else
		vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 7.0, 0, 71)
	end
	ESX.TriggerServerCallback('CorePickax:GotAkey', function(gotkey)
		if gotkey then
			local locked = GetVehicleDoorLockStatus(vehicle)
			if locked == 1 or locked == 0 then -- if unlocked
				SetVehicleDoorsLocked(vehicle, 2)
				PlayVehicleDoorCloseSound(vehicle, 1)
				ESX.ShowNotification("Vous avez ~r~fermé~s~ le véhicule")
				TriggerServerEvent("ESXCustomsv:PlayOnSource", "lock", 0.8)
			elseif locked == 2 then -- if locked
				SetVehicleDoorsLocked(vehicle, 1)
				PlayVehicleDoorOpenSound(vehicle, 0)
				ESX.ShowNotification("Vous avez ~g~ouvert~s~ le véhicule")
				TriggerServerEvent("ESXCustomsv:PlayOnSource", "unlock", 0.8)
			end
		else
			ESX.ShowNotification("~r~Vous n'avez pas les clés de ce véhicule")
		end
	end, GetVehicleNumberPlateText(vehicle))
end

-- Citizen.CreateThread(function()
-- 	local dict = "anim@mp_player_intmenu@key_fob@"

--     RequestAnimDict(dict)
--     while not HasAnimDictLoaded(dict) do
--         Citizen.Wait(100)
--     end
-- 	while true do
-- 		Wait(0)
-- 		if IsControlJustReleased(0, 303) then
-- 			OpenCloseVehicle()
-- 		end
-- 		if IsControlJustPressed(1, 303) then
-- 			if not IsPedInAnyVehicle(GetPlayerPed(-1), true) then 
-- 			   TaskPlayAnim(GetPlayerPed(-1), dict, "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
-- 			   StopAnimTask = true		
-- 			end
-- 	   end
-- 	end
-- end)

RegisterKeyMapping(ConfigVehicle.Commande.CommandeName2, ConfigVehicle.Commande.DescCommande2, 'keyboard', ConfigVehicle.Commande.Bind2)

RegisterCommand(ConfigVehicle.Commande.CommandeName2, function()
    local dict = "anim@mp_player_intmenu@key_fob@"

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(100)
    end
    OpenCloseVehicle()
    if not IsPedInAnyVehicle(GetPlayerPed(-1), true) then 
        TaskPlayAnim(GetPlayerPed(-1), dict, "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
        StopAnimTask = true		
     end
end, false)

if ConfigVehicle.HideInTruck == true then
    InVehicleCoffre = false
    local inTrunk = false

    Citizen.CreateThread(function()
        while true do
            local timer = 2500
            local vehicle = GetClosestVehicle(GetEntityCoords(PlayerPedId()), 10.0, 0, 70)
            if DoesEntityExist(vehicle) then
                timer = 0
                local trunk = GetEntityBoneIndexByName(vehicle, 'boot')
                if trunk ~= -1 then
                    local coords = GetWorldPositionOfEntityBone(vehicle, trunk)
                    if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), coords, true) <= 2.5 then
                        if not inTrunk then
                            if not IsPedSittingInAnyVehicle(PlayerPedId()) then
                                if GetVehicleDoorAngleRatio(vehicle, 5) < 0.9 then
                                    DrawText3D(coords, '[Y] Entrer dans coffre\n[H] Ouvrir Coffre\n[L] Contenu coffre')
                                    if IsControlJustReleased(0, 74) then
                                        SetCarBootOpen(vehicle)
                                    end
                                else
                                    DrawText3D(coords, '[Y] Entrer dans coffre\n[H] Fermer Coffre\n[L] Contenu coffre')
                                    if IsControlJustReleased(0, 74) then
                                        SetVehicleDoorShut(vehicle, 5)
                                    end
                                end
                            end
                        end
                        if IsControlJustReleased(0, 246) and not inTrunk then
                            local player = ESX.Game.GetClosestPlayer()
                            local playerPed = GetPlayerPed(player)
                            if DoesEntityExist(playerPed) then
                                if not IsEntityAttached(playerPed) or GetDistanceBetweenCoords(GetEntityCoords(playerPed), GetEntityCoords(PlayerPedId()), true) >= 5.0 then
                                    SetCarBootOpen(vehicle)
                                    Wait(350)
                                    AttachEntityToEntity(PlayerPedId(), vehicle, -1, 0.0, -2.2, 0.5, 0.0, 0.0, 0.0, false, false, false, false, 20, true)	
                                    ESXCustom_Function_ClientSide:LoadDict('timetable@floyd@cryingonbed@base')
                                    TaskPlayAnim(PlayerPedId(), 'timetable@floyd@cryingonbed@base', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)
                                    Wait(50)
                                    inTrunk = true
                                    InVehicleCoffre = true
				                    TriggerServerEvent('baseevents:enteredVehicleCoffre')
                                    Wait(1500)
                                    SetVehicleDoorShut(vehicle, 5)
                                else
                                    ESX.ShowNotification('Une personne est déjà dans le coffre!')
                                end
                            end
                        end
                    end
                end
            end
            Wait(timer)
            if inTrunk then
                local vehicle = GetEntityAttachedTo(PlayerPedId())
                if DoesEntityExist(vehicle) or not IsPedDeadOrDying(PlayerPedId()) or not IsPedFatallyInjured(PlayerPedId()) then
                    local coords = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, 'boot'))
                    SetEntityCollision(PlayerPedId(), false, false)
                    SetTimecycleModifier("NG_blackout")
                    AddTextComponentSubstringPlayerName("zzzzz")
                    AddTextEntry('TEST_LABEL', '~a~')
                    BeginTextCommandDisplayText('TEST_LABEL')
                    AddTextComponentSubstringPlayerName('Vous êtes dans un coffre ! ~b~[Y]~s~ Pour Quitter Coffre')
                    EndTextCommandDisplayText(0.125, 0.40)

                    if GetVehicleDoorAngleRatio(vehicle, 5) < 0.9 then
                        SetEntityVisible(PlayerPedId(), false, false)
                    else
                        if not IsEntityPlayingAnim(PlayerPedId(), 'timetable@floyd@cryingonbed@base', 3) then
                            ESXCustom_Function_ClientSide:LoadDict('timetable@floyd@cryingonbed@base')
                            TaskPlayAnim(PlayerPedId(), 'timetable@floyd@cryingonbed@base', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)

                            SetEntityVisible(PlayerPedId(), true, false)
                        end
                    end
                    if IsControlJustReleased(0, 246) and inTrunk then
                        SetCarBootOpen(vehicle)
                        SetEntityCollision(PlayerPedId(), true, true)
                        Wait(750)
                        inTrunk = false
                        InVehicleCoffre = false
				        TriggerServerEvent('baseevents:leftVehicleCoffre')
                        SetTimecycleModifier("default")
                        DetachEntity(PlayerPedId(), true, true)
                        SetEntityVisible(PlayerPedId(), true, false)
                        ClearPedTasks(PlayerPedId())
                        SetEntityCoords(PlayerPedId(), GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, -0.5, -0.75))
                        Wait(250)
                        SetVehicleDoorShut(vehicle, 5)
                    end
                else
                    InVehicleCoffre = false
				    TriggerServerEvent('baseevents:leftVehicleCoffre')
                    SetEntityCollision(PlayerPedId(), true, true)
                    DetachEntity(PlayerPedId(), true, true)
                    SetEntityVisible(PlayerPedId(), true, false)
                    ClearPedTasks(PlayerPedId())
                    SetEntityCoords(PlayerPedId(), GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, -0.5, -0.75))
                end
            end
        end
    end)

    
    AddEventHandler('esx:onPlayerDeath', function()
        SetCarBootOpen(vehicle)
        SetEntityCollision(PlayerPedId(), true, true)
        Wait(750)
        inTrunk = false
        InVehicleCoffre = false
        TriggerServerEvent('baseevents:leftVehicleCoffre')
        SetTimecycleModifier("default")
        DetachEntity(PlayerPedId(), true, true)
        SetEntityVisible(PlayerPedId(), true, false)
        ClearPedTasks(PlayerPedId())
        SetEntityCoords(PlayerPedId(), GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, -0.5, -0.75))
        Wait(250)
        SetVehicleDoorShut(vehicle, 5)
    end)

    function DrawText3D(coords, text)
        local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
        local pX, pY, pZ = table.unpack(GetGameplayCamCoords())
    
        SetTextScale(0.4, 0.4)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextEntry("STRING")
        SetTextCentre(1)
        SetTextColour(255, 255, 255, 255)
        SetTextOutline()
    
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

if ConfigVehicle.Drift == true then
	local kmh = 3.6
	local mph = 2.23693629
	local carspeed = 0
	local driftmode = true
	local speed = kmh
	local drift_speed_limit = 160.0

	Citizen.CreateThread(function()
		while true do
			local timer = 300
			if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
				timer = 0
			end
			Citizen.Wait(timer)
            if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
                if IsControlJustPressed(1, 344) then
                    TriggerEvent("driftmode:ByESXCustom")
                end
            end

            if driftmode then
                if IsPedInAnyVehicle(GetPlayerPed(-1), false) and ConfigVehicle.BlacklistVehDrift[GetDisplayNameFromVehicleModel(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false)))] == nil or ConfigVehicle.BlacklistVehDrift[GetDisplayNameFromVehicleModel(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false)))] == true then
                    CarSpeed = GetEntitySpeed(GetVehiclePedIsIn(GetPlayerPed(-1),false)) * speed
                    if GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1),false), -1) == GetPlayerPed(-1) then
                        if CarSpeed <= drift_speed_limit then  
                            if IsControlPressed(1, 21) then		
                                SetVehicleReduceGrip(GetVehiclePedIsIn(GetPlayerPed(-1),false), true)	
                            else
                                SetVehicleReduceGrip(GetVehiclePedIsIn(GetPlayerPed(-1),false), false)
                            end
                        end
                    end
                end
            end
		end
	end)

	RegisterNetEvent('driftmode:ByESXCustom', function()
		driftmode = not driftmode
		if driftmode then
			ESX.ShowNotification(ConfigVehicle.MenuEtNotification["Drift"])
		else
			ESX.ShowNotification(ConfigVehicle.MenuEtNotification["Drift1"])
		end
	end)
end

if ConfigVehicle.DriveByWithSpeed then
    Citizen.CreateThread(function()
        while true do
            local timer = 500

            if (GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1), false), -1) == GetPlayerPed(-1)) then
                timer = 0
            end
            Citizen.Wait(timer)
            if (GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1), false), -1) == GetPlayerPed(-1)) and GetEntitySpeed(GetVehiclePedIsIn(GetPlayerPed(-1),false)) * 3.6 >= ConfigVehicle.MaxSpeedDriveBY then
                SetPlayerCanDoDriveBy(PlayerId(), false)
            else
                SetPlayerCanDoDriveBy(PlayerId(), true)
            end
        end
    end)
end

if ConfigVehicle.AntiVehiclePoliceUnemployed then
    local function JobBuilderCanDriveVehicle(vehicle)
        if not Entity or not DoesEntityExist(vehicle) then
            return nil
        end

        local entity = Entity(vehicle)
        if not entity or not entity.state or entity.state.jobbuilderVehicle ~= true then
            return nil
        end

        local playerJob = ESX.PlayerData and ESX.PlayerData.job
        if not playerJob then
            return false
        end

        local requiredJob = tostring(entity.state.jobbuilderJob or '')
        local currentJob = tostring(playerJob.name or '')

        -- Unemployed, mauvais job, ou job vide : accès refusé.
        if currentJob == '' or currentJob == 'unemployed' or currentJob ~= requiredJob then
            return false
        end

        local allowedGrades = entity.state.jobbuilderAllowedGrades
        local grade = tostring(tonumber(playerJob.grade) or 0)

        if type(allowedGrades) ~= 'table' then
            return false
        end

        return allowedGrades[grade] == true or allowedGrades[tonumber(grade)] == true
    end

    Citizen.CreateThread(function()
        while true do
            local timer = 200
            local ped = GetPlayerPed(PlayerId())

            if IsPedInAnyPoliceVehicle(ped) then
                local veh = GetVehiclePedIsUsing(ped, false)

                if GetPedInVehicleSeat(veh, -1) == ped then
                    local builderAccess = JobBuilderCanDriveVehicle(veh)

                    if builderAccess == true then
                        SetVehicleUndriveable(veh, false)
                    elseif builderAccess == false then
                        timer = 0
                        ESX.ShowNotification("Tu n'as pas accès à ce véhicule de service.")
                        SetVehicleUndriveable(veh, true)
                    elseif CantDrive() then
                        timer = 0
                        ESX.ShowNotification("Une voiture de service n'est pas réservée aux civils..")
                        SetVehicleUndriveable(veh, true)
                    else
                        SetVehicleUndriveable(veh, false)
                    end
                end
            end

            Citizen.Wait(timer)
        end
    end)

    function CantDrive()
        local jobName = ESX.PlayerData
            and ESX.PlayerData.job
            and ESX.PlayerData.job.name

        if not jobName then
            return true
        end

        return not ConfigVehicle.AntiVehiclePoliceUnemployedJobsListAcces[jobName]
    end
end

local TableFDP = {}
local Spawn = {}
Citizen.CreateThread(function()
    while true do
        local timer = 200
        for k, v in pairs(ConfigVehicle.ListVehicleFreeze) do
            local distance = #(GetEntityCoords(PlayerPedId()) - vector3(v.x, v.y, v.z))

            if distance < 50.0 then
                if Spawn[k] == nil then
                    Spawn[k] = {}
                    Spawn[k].stats = false
                    Spawn[k].rotation = v.h

                    if not Spawn[k].stats then
                        if ESXCustom_Function_ClientSide:IsSpawnPointClear(vector3(v.x, v.y, v.z), 5) then
                            ESXCustom_Function_ClientSide:SpawnLocalVehicle(v.model, vector3(v.x, v.y, v.z), v.h, function(vehicle)
                                SetVehicleNumberPlateText(vehicle, "SHOWROOM")
                                SetVehicleDoorsLocked(vehicle, 2)
                                if TableFDP[k] == nil then
                                    TableFDP[k] = {}
                                    TableFDP[k].id = vehicle
                                else
                                    TableFDP[k].id = vehicle
                                end
                                Spawn[k].stats = true
                            end)
                        end
                    end
                end
            end

            if distance < 25.0 then
                timer = 0
                if Spawn[k] == nil then
                    Spawn[k] = {}
                    Spawn[k].stats = false
                    Spawn[k].rotation = v.h

                    if not Spawn[k].stats then
                        if ESXCustom_Function_ClientSide:IsSpawnPointClear(vector3(v.x, v.y, v.z), 5) then
                            ESXCustom_Function_ClientSide:SpawnLocalVehicle(v.model, vector3(v.x, v.y, v.z), v.h, function(vehicle)
                                SetVehicleNumberPlateText(vehicle, "SHOWROOM")
                                SetVehicleDoorsLocked(vehicle, 2)
                                if TableFDP[k] == nil then
                                    TableFDP[k] = {}
                                    TableFDP[k].id = vehicle
                                else
                                    TableFDP[k].id = vehicle
                                end
                                Spawn[k].stats = true
                            end)
                        end
                    end
                end

                if TableFDP[k] ~= nil and TableFDP[k].id ~= nil and v.rotation then
                    Spawn[k].rotation = Spawn[k].rotation + 0.3
                    SetEntityHeading(TableFDP[k].id, Spawn[k].rotation)
                end
            end
        end
        Wait(timer)
    end
end)