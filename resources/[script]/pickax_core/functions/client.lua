-- Carburant : SetFuel / GetFuel globaux (utilisés par le contextMenu, les véhicules de job…).
-- Compatible ox_fuel / LegacyFuel, sinon natif.
function SetFuel(veh, level)
	if not veh or not DoesEntityExist(veh) then return end
	level = math.max(0.0, math.min(100.0, (tonumber(level) or 0) + 0.0))
	if GetResourceState('ox_fuel') == 'started' then Entity(veh).state.fuel = level end
	if GetResourceState('LegacyFuel') == 'started' then pcall(function() exports['LegacyFuel']:SetFuel(veh, level) end) end
	SetVehicleFuelLevel(veh, level)
end

function GetFuel(veh)
	if not veh or not DoesEntityExist(veh) then return 0.0 end
	if GetResourceState('ox_fuel') == 'started' then return Entity(veh).state.fuel or GetVehicleFuelLevel(veh) end
	if GetResourceState('LegacyFuel') == 'started' then
		local ok, v = pcall(function() return exports['LegacyFuel']:GetFuel(veh) end)
		if ok and v then return v end
	end
	return GetVehicleFuelLevel(veh)
end

ESXCustom_Function_ClientSide = {}

function ESXCustom_Function_ClientSide:LoadDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) RequestAnimDict(dict) end
end

function ESXCustom_Function_ClientSide:RequestModel(model)
	RequestModel(model)

	while not HasModelLoaded(model) do
		Citizen.Wait(1)
	end
end

function ESXCustom_Function_ClientSide:SpawnPNJ(PedType, PedName, Position, heading)
	ESXCustom_Function_ClientSide:RequestModel(PedName)

	local ped = CreatePed(PedType, PedName, Position, heading or GetEntityHeading(PlayerPedId()), false, true)

	return ped
end

function ESXCustom_Function_ClientSide:KeyboardInput(TextEntry, MaxStringLenght)
    if GetResourceState('pickax_ui') == 'started' then
        blockinput = true
        local result = exports['pickax_ui']:Input({ title = TextEntry, max = MaxStringLenght })
        Citizen.Wait(200)
        blockinput = false
        return result
    end
    AddTextEntry('FMMC_KEY_TIP1', TextEntry) 
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", "", "", "", "", MaxStringLenght)
    blockinput = true
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do 
        Citizen.Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult() 
        Citizen.Wait(500) 
        blockinput = false
        return result 
    else
        Citizen.Wait(500) 
        blockinput = false 
        return nil 
    end
end

function ESXCustom_Function_ClientSide:CheckQuantity(number)
    number = tonumber(number)

    if type(number) == "number" then
        number = ESX.Math.Round(number)

        if number > 0 then
            return true, number
        end
    end

    return false, number
end

function ESXCustom_Function_ClientSide:CheckQuantity2(number)
    number = tonumber(number)

    if type(number) == "number" then
        number = number

        if number > 0 then
            return true, number
        end
    end

    return false, number
end

function ESXCustom_Function_ClientSide:MathRound(value, numDecimalPlaces)
    if numDecimalPlaces then
        local power = 10^numDecimalPlaces
        return math.floor((value * power) + 0.5) / (power)
    else
        return math.floor(value + 0.5)
    end
end

function ESXCustom_Function_ClientSide:DrawText3D(coords, text, size, color)
	local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
	local camCoords = GetGameplayCamCoords()
	local dist = GetDistanceBetweenCoords(camCoords, coords.x, coords.y, coords.z, true)
	local size = size

	if size == nil then
		size = 1
	end

	if color == nil then
		color = {
			r = 255,
			g = 255,
			b = 255,
			a = 255
		}
	end

	local scale = (size / dist) * 2
	local fov = (1 / GetGameplayCamFov()) * 100
	local scale = scale * fov

	if onScreen then
		SetTextScale(0.0 * scale, 0.55 * scale)
		SetTextFont(0)
		SetTextColour(color.r, color.g, color.b, color.a)
		SetTextDropshadow(0, 0, 0, 0, 255)
		SetTextDropShadow()
		SetTextOutline()
		SetTextEntry('STRING')
		SetTextCentre(1)

		AddTextComponentString(text)
		DrawText(x, y)
	end
end

function ESXCustom_Function_ClientSide:Draw3DText(x,y,z,textInput,fontId,scaleX,scaleY)
	local px,py,pz=table.unpack(GetGameplayCamCoords())
	local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)    
	local scale = (1/dist)*20
	local fov = (1/GetGameplayCamFov())*100
	local scale = scale*fov   
	SetTextScale(scaleX*scale, scaleY*scale)
	SetTextFont(fontId)
	SetTextProportional(1)
	SetTextColour(250, 250, 250, 255)	
	SetTextDropshadow(1, 1, 1, 1, 255)
	SetTextEdge(2, 0, 0, 0, 150)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(textInput)
	SetDrawOrigin(x,y,z+2, 0)
	DrawText(0.0, 0.0)
	ClearDrawOrigin()
end

function ESXCustom_Function_ClientSide:SpawnLocalVehicle(modelName, coords, heading, cb)
	local model = (type(modelName) == 'number' and modelName or GetHashKey(modelName))

	Citizen.CreateThread(function()
		ESX.Streaming.RequestModel(model)

		local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, false, false)

		SetEntityAsMissionEntity(vehicle, true, false)
		SetVehicleHasBeenOwnedByPlayer(vehicle, true)
		SetVehicleNeedsToBeHotwired(vehicle, false)
		SetModelAsNoLongerNeeded(model)
		RequestCollisionAtCoord(coords.x, coords.y, coords.z)

		while not HasCollisionLoadedAroundEntity(vehicle) do
			RequestCollisionAtCoord(coords.x, coords.y, coords.z)
			Citizen.Wait(0)
		end

		SetVehRadioStation(vehicle, 'OFF')

		if cb then
			cb(vehicle)
		end
	end)
end

function ESXCustom_Function_ClientSide:IsSpawnPointClear(coords, radius)
	local vehicles = ESX.Game.GetVehiclesInArea(coords, radius)

	return #vehicles == 0
end

function ESXCustom_Function_ClientSide:GroupDigits(value)
	local left,num,right = string.match(value,'^([^%d]*%d)(%d*)(.-)$')

	return left..(num:reverse():gsub('(%d%d%d)','%1' .. ' '):reverse())..right
end

function ESXCustom_Function_ClientSide:Round(value, numDecimalPlaces)
	if numDecimalPlaces then
		local power = 10^numDecimalPlaces
		return math.floor((value * power) + 0.5) / (power)
	else
		return math.floor(value + 0.5)
	end
end

function ESXCustom_Function_ClientSide:CheckQuantity(number)
    number = tonumber(number)

    if type(number) == "number" then
        number = ESXCustom_Function_ClientSide:Round(number)

        if number > 0 then
            return true, number
        end
    end

    return false, number
end

function ESXCustom_Function_ClientSide:startAnimAction(lib, anim)
	ESX.Streaming.RequestAnimDict(lib, function()
		TaskPlayAnim(PlayerPedId(), lib, anim, 8.0, 1.0, -1, 49, 0, false, false, false)
		RemoveAnimDict(lib)
	end)
end

function ESXCustom_Function_ClientSide:GetPlayerHandsup(hitEntity, configChecker)
    for k, v in pairs(configChecker) do
        if IsEntityPlayingAnim(hitEntity,v.dict, v.anim, 3) then
            return true
        end
    end
    return false
end

function ESXCustom_Function_ClientSide:ShowHelp(text, n)
    local msg = GetLabelText(text)
    if msg == 'NULL' then msg = text end
    ESX.ShowHelpNotification(msg)
end

function ESXCustom_Function_ClientSide:ShowFloatingHelp(text, pos)
    SetFloatingHelpTextWorldPosition(1, pos)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    ESXCustom_Function_ClientSide:ShowHelp(text, 2)
end

function ESXCustom_Function_ClientSide:LoadAnimDict(dictname)
	if not HasAnimDictLoaded(dictname) then
		RequestAnimDict(dictname) 
		while not HasAnimDictLoaded(dictname) do 
			Citizen.Wait(1)
		end
		RemoveAnimDict(dictname)
	end
end

function ESXCustom_Function_ClientSide:SpawnVehicle(vehicleName, Position, Heading, NomPlaque, Type)
	local hash = GetHashKey(vehicleName)
	Citizen.CreateThread(function()
		RequestModel(hash)
		while not HasModelLoaded(hash) do Citizen.Wait(10) end

		local vehicle = CreateVehicle(hash, Position.x, Position.y, Position.z, Heading, true, false)
		local plate = NomPlaque..' '..math.random(1000, 9000)
		TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
		TriggerServerEvent('esx_vehiclelock:givekey', 'no', plate) -- vehicle lock
        SetVehicleNumberPlateText(vehicle, plate)
		SetVehicleDirtLevel(vehicle, 0.0)
		SetFuel(vehicle, 100)

		if Type == "Helico" then
			if NomPlaque == "EMS" then
				SetVehicleLivery(vehicle, 1)
			elseif NomPlaque == "LSPD" then 
				SetVehicleLivery(vehicle, 0)
			end
		end
	end)
end

function ESXCustom_Function_ClientSide:DeleteVehicle(coords)
	if IsPedInAnyVehicle(PlayerPedId(), false) then
		local veh = GetVehiclePedIsIn(PlayerPedId(), false)
		local plate = GetVehicleNumberPlateText(veh) 
		if veh ~= nil then
			TriggerServerEvent('esx_vehiclelock:deletekeyjobs', 'no', plate)
			DeleteEntity(veh)
		end
	else
		local veh, vehDistance = ESX.Game.GetClosestVehicle(coords)
		local plate = GetVehicleNumberPlateText(veh) 
		if vehDistance <= 5.0 then
			TriggerServerEvent('esx_vehiclelock:deletekeyjobs', 'no', plate)
			DeleteEntity(veh)
		else
			ESX.ShowNotification("~r~Aucun véhicule assez proche de la zone.~s~")
		end
	end
end

function ESXCustom_Function_ClientSide:LoadWeaponObj(weaponHash)
	if not HasWeaponAssetLoaded(weaponHash) then
		RequestWeaponAsset(weaponHash)

		while not HasWeaponAssetLoaded(weaponHash) do
			Wait(0)
		end
	end
end

--[[
	AddTextEntry("SHOW_DMX_TAKE_ITEM", "Appuyez sur ~y~Y~s~ Entrer dans coffre\nAppuyez sur ~y~H~s~ Ouvrir Coffre\nAppuyez sur ~y~L~s~ Contenu coffre")
    ESXCustom_Function_ClientSide:ShowFloatingHelp("SHOW_DMX_TAKE_ITEM", coords)
]]--

--Buttons
--Freeze + Moov
function ESXCustom_Function_ClientSide:MoovPlayer()
	FreezePedCameraRotation(PlayerClass.pPed, true)

	-- barre d'aide pickax_ui : affichée tant que la fonction est appelée, masquée 400 ms après le dernier appel
	if not MoovKeysShown then
		MoovKeysShown = true
		pcall(function() exports.pickax_ui:KeysShow('moov', { { key = { exports.pickax_ui:ControlKey(63, 0), exports.pickax_ui:ControlKey(64, 0) }, label = 'Pivoter à gauche / à droite' } }) end)
		CreateThread(function()
			while GetGameTimer() - (MoovKeysLast or 0) < 400 do Wait(100) end
			MoovKeysShown = false
			pcall(function() exports.pickax_ui:KeysHide('moov') end)
		end)
	end
	MoovKeysLast = GetGameTimer()
	DisableControlAction(0, 63, true)
	DisableControlAction(0, 64, true)

	if IsDisabledControlPressed(0, 63) then
		SetEntityHeading(PlayerClass.pPed, GetEntityHeading(PlayerClass.pPed) + 2)
	elseif IsDisabledControlPressed(0, 64) then
		SetEntityHeading(PlayerClass.pPed, GetEntityHeading(PlayerClass.pPed) - 2)
	end
end

exports("MoovPlayer", function()
	ESXCustom_Function_ClientSide:MoovPlayer()
end)

--HeadCam
function ESXCustom_Function_ClientSide:HeadCamera(action, type)
	if action == "create" then
		local fov = 50.0
		local coords = vector3(0.0,0.0,0.0)
		local point = vector3(0.0,0.0,0.0)
		if type == "face" then
			fov = 10.0
			coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(),0.0,3.0,1.0)
			point = GetPedBoneCoords(PlayerPedId(),31086,0.0,0.0,0.0)
		elseif type == "root" then
			fov = 15.0
			coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(),0.0,3.0,1.0)
			point = GetPedBoneCoords(PlayerPedId(),0,0.0,0.0,0.0)
		elseif type == "pants" then
			fov = 20.0
			coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(),0.0,3.0,1.0)
			point = GetPedBoneCoords(PlayerPedId(),16335,0.0,-0.3,0.0)
		elseif type == "torso" then
			fov = 20.0
			coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(),0.0,3.0,1.0)
			point = GetPedBoneCoords(PlayerPedId(),0,0.0,0.0,0.2)
		elseif type == "shoes" then
			fov = 10.0
			coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(),0.0,3.0,1.0)
			point = GetPedBoneCoords(PlayerPedId(),24806,0.0,0.2,0.0)
		elseif type ~= nil and type:find("ZONE") then
			fov = 60.0
			coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(),coordsto.x,coordsto.y,coordsto.z)
			point = pointto
		-- else
		-- 	fov = fov or 40.0
		-- 	coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(),0.0,3.0,0.5)
		-- 	point = pointto or GetPedBoneCoords(PlayerPedId(),0,0.0,0.0,0.0)
		-- end
		-- if type == "face" then
		-- 	fov = 10.0
		-- 	coords = GetOffsetFromEntityInWorldCoords(PlayerPedId(),0.0,3.0,1.0)
		-- 	point = GetPedBoneCoords(PlayerPedId(),31086,0.0,0.0,0.0)
		end

		PlayerClass.pByPassAC = true
		if CameraHead == nil then
			CameraHead = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
			SetCamCoord(CameraHead, coords)
			SetCamFov(CameraHead, fov)
			PointCamAtCoord(CameraHead, point)
			SetCamShakeAmplitude(CameraHead, 13.0)
			RenderScriptCams(1, 1, 1500, 1, 1)
		else
			RageUI.PlaySound("MUGSHOT_CHARACTER_CREATION_SOUNDS","Zoom_In",false)
			SetCamCoord(CameraHead, coords)
			SetCamFov(CameraHead, fov)
			PointCamAtCoord(CameraHead, point)
			RenderScriptCams(1, 1, 1500, 1, 1)
		end
	elseif action == "destroy" then
		SetCamActive(CameraHead, false)
		RenderScriptCams(false, true, 500, true, true)
		DestroyCam(CameraHead)
		CameraHead = nil

		PlayerClass.pByPassAC = false
	end
end

exports("HeadCam", function(action, type)
	ESXCustom_Function_ClientSide:HeadCamera(action, type)
end)