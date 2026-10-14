-- ─────────────────────────────── Cinématique d'arrivée en avion ───────────────────────────────
-- L'avion et son pilote sont LOCAUX (non synchronisés) : seul le joueur concerné les voit. Le vol est scripté (position calculée à chaque
-- image) : trajectoire propre, aucun risque de crash. Plans : (1) vue extérieure de la descente, (2) vue arrière pendant l'atterrissage et le roulage,
-- (3) vue au sol quand le joueur descend. Se termine par un fondu au noir ; l'écran noir et l'apparition à la destination sont gérés par main.lua.

local function loadModel(name)
	local hash = type(name) == 'number' and name or joaat(name)
	if not IsModelInCdimage(hash) then return nil end
	RequestModel(hash)
	local untilT = GetGameTimer() + 8000
	while not HasModelLoaded(hash) and GetGameTimer() < untilT do Citizen.Wait(10) end
	return HasModelLoaded(hash) and hash or nil
end

local function fadeOut(ms)
	DoScreenFadeOut(ms)
	local untilT = GetGameTimer() + ms + 1500
	while not IsScreenFadedOut() and GetGameTimer() < untilT do Citizen.Wait(10) end
end

local function newCam()
	return CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
end

local function switchCam(cam, ms)
	SetCamActive(cam, true)
	RenderScriptCams(true, ms and ms > 0, ms or 0, true, false)
end

-- Précharge l'avion pendant que le joueur choisit sa destination : la cinématique démarre ensuite instantanément
function PreloadArrivalCinematic()
	local C = Config.Cinematic
	if not C or not C.Enabled then return end
	Citizen.CreateThread(function()
		loadModel(C.Plane or 'luxor')
		loadModel('s_m_m_pilot_01')
		RequestCollisionAtCoord(C.Touchdown.x, C.Touchdown.y, C.Touchdown.z)
	end)
end

-- /pisteavion : place-toi SUR la piste, au point où l'avion doit toucher le sol, face à la direction d'atterrissage, puis tape la commande :
-- elle affiche les valeurs Touchdown et Heading à copier dans config.lua (réservé aux admins).
RegisterCommand('pisteavion', function()
	local group = ESX and ESX.GetPlayerData() and ESX.GetPlayerData().group
	if group ~= 'admin' and group ~= 'superadmin' and group ~= '_dev' then return end
	local ped = PlayerPedId()
	local c = GetEntityCoords(ped)
	local h = GetEntityHeading(ped)
	local line = ('Touchdown = vector3(%.2f, %.2f, %.2f),  Heading = %.1f,'):format(c.x, c.y, c.z, h)
	print('^2[pisteavion]^0 ' .. line)
	TriggerEvent('chat:addMessage', { args = { 'pisteavion', line } })
	ESX.ShowNotification('Valeurs copiables dans la console F8 : ~b~Touchdown~s~ et ~b~Heading~s~ (config.lua).')
end, false)

function PlayArrivalCinematic()
	local C = Config.Cinematic
	if not C or not C.Enabled then return end

	local ped = PlayerPedId()
	local planeHash = loadModel(C.Plane or 'luxor')
	local pilotHash = loadModel('s_m_m_pilot_01') or loadModel('s_m_y_airworker')
	if not planeHash then return end   -- modèle indisponible : on saute la cinématique

	-- Géométrie de la piste
	local hRad = math.rad(C.Heading)
	local fwd = vector3(-math.sin(hRad), math.cos(hRad), 0.0)
	local touch = C.Touchdown
	local startPos = touch - fwd * C.ApproachDistance
	local stopPos = touch + fwd * C.RolloutDistance
	local min = GetModelDimensions(planeHash)
	local groundOffset = -min.z + 0.15   -- distance entre l'origine de l'avion et ses roues

	HideHudAndRadarThisFrame()
	TriggerEvent('tempui:toggleUi', true)
	DisplayRadar(false)
	fadeOut(250)

	-- Entités locales
	RequestCollisionAtCoord(touch.x, touch.y, touch.z)
	local plane = CreateVehicle(planeHash, startPos.x, startPos.y, touch.z + C.StartAltitude, C.Heading + 0.0, false, false)
	SetEntityAsMissionEntity(plane, true, true)
	SetEntityCollision(plane, false, false)
	SetVehicleEngineOn(plane, true, true, false)
	SetVehicleDoorsLocked(plane, 1)
	SetEntityInvincible(plane, true)
	local pilot
	if pilotHash then
		pilot = CreatePedInsideVehicle(plane, 26, pilotHash, -1, false, false)
		SetBlockingOfNonTemporaryEvents(pilot, true)
		SetEntityInvincible(pilot, true)
	end

	-- Le joueur monte à bord (siège passager)
	SetEntityInvincible(ped, true)
	FreezeEntityPosition(ped, false)
	local seat = 1
	local seats = GetVehicleModelNumberOfSeats(planeHash)
	if seats and seats <= seat + 1 then seat = math.max(0, seats - 2) end
	SetPedIntoVehicle(ped, plane, seat)

	local function place(pos, zAbove, pitch)
		SetEntityCoordsNoOffset(plane, pos.x, pos.y, pos.z + zAbove, false, false, false)
		SetEntityRotation(plane, pitch, 0.0, C.Heading + 0.0, 2, true)
		SetEntityVelocity(plane, 0.0, 0.0, 0.0)
	end

	-- Plan 1 : caméra latérale fixe près de la piste, qui suit l'avion pendant la descente
	local cam1 = newCam()
	local side = vector3(-fwd.y, fwd.x, 0.0)
	local c1 = touch - fwd * 380.0 + side * 120.0
	SetCamCoord(cam1, c1.x, c1.y, touch.z + 22.0)
	SetCamFov(cam1, 38.0)
	PointCamAtEntity(cam1, plane, 0.0, 0.0, 0.0, true)
	switchCam(cam1, 0)
	place(startPos, C.StartAltitude, -3.0)
	DoScreenFadeIn(500)

	local skip = false
	local function checkSkip()
		if C.AllowSkip and IsControlJustPressed(0, 177) then skip = true end
		return skip
	end

	-- Descente
	local T1 = (C.ApproachSeconds or 16) * 1000
	local t0 = GetGameTimer()
	local cam2, cam2On = nil, false
	while not checkSkip() do
		local t = (GetGameTimer() - t0) / T1
		if t >= 1.0 then break end
		local pos = startPos + (touch - startPos) * t
		local alt = C.StartAltitude * (1.0 - t) ^ 1.7           -- pente de descente douce, plus plate à l'approche
		place(pos, alt + groundOffset, -3.0 + (1.0 - t) * 2.0)
		-- Plan 2 : à mi-descente, caméra derrière-dessus de l'avion
		if t > 0.55 and not cam2On then
			cam2On = true
			cam2 = newCam()
			AttachCamToEntity(cam2, plane, 0.0, -22.0, 6.5, true)
			PointCamAtEntity(cam2, plane, 0.0, 6.0, 0.0, true)
			SetCamFov(cam2, 52.0)
			SetCamActive(cam2, true)
			RenderScriptCams(true, true, 1200, true, false)
		end
		Citizen.Wait(0)
	end

	-- Roulage jusqu'à l'arrêt (décélération)
	if not skip then
		local T2 = (C.RolloutSeconds or 7) * 1000
		local r0 = GetGameTimer()
		local dist = #(stopPos - touch)
		while not checkSkip() do
			local t = (GetGameTimer() - r0) / T2
			if t >= 1.0 then break end
			local ease = 1.0 - (1.0 - t) ^ 2.2                      -- avance vite puis s'arrête
			local pos = touch + fwd * (dist * ease)
			place(pos, groundOffset, 0.0)
			Citizen.Wait(0)
		end
	end

	-- Arrêt : l'avion se pose, le joueur descend
	local endPos = touch + fwd * (skip and 0.0 or #(stopPos - touch))
	place(endPos, groundOffset, 0.0)
	SetVehicleEngineOn(plane, false, true, true)
	FreezeEntityPosition(plane, true)

	if not skip then
		-- Plan 3 : caméra au sol près de la porte
		local cam3 = newCam()
		local c3 = endPos + side * 7.0 - fwd * 2.0
		SetCamCoord(cam3, c3.x, c3.y, endPos.z + 1.6)
		SetCamFov(cam3, 45.0)
		PointCamAtEntity(cam3, plane, 0.0, 0.0, 0.5, true)
		SetCamActive(cam3, true)
		RenderScriptCams(true, true, 900, true, false)
		if cam2 then DestroyCam(cam2, false) end
		Citizen.Wait(1500)

		TaskLeaveVehicle(ped, plane, 0)
		local untilT = GetGameTimer() + 6000
		while IsPedInVehicle(ped, plane, false) and GetGameTimer() < untilT do Citizen.Wait(50) end
		-- le joueur s'éloigne de l'avion de quelques pas
		local away = GetOffsetFromEntityInWorldCoords(plane, 6.0, 4.0, 0.0)
		TaskGoStraightToCoord(ped, away.x, away.y, away.z, 1.0, 4000, C.Heading + 0.0, 0.5)
		Citizen.Wait(2800)
		DestroyCam(cam3, false)
	else
		if cam2 then DestroyCam(cam2, false) end
	end

	-- Fondu au noir (l'écran reste noir pendant BlackScreenMs, géré par main.lua) puis nettoyage
	fadeOut(600)
	ClearPedTasksImmediately(ped)
	if IsPedInAnyVehicle(ped, false) then
		TaskLeaveVehicle(ped, plane, 16)
		Citizen.Wait(200)
	end
	RenderScriptCams(false, false, 0, true, false)
	DestroyCam(cam1, false)
	SetEntityCoordsNoOffset(ped, endPos.x + 6.0, endPos.y + 6.0, endPos.z + 1.0, false, false, false)
	if pilot and DoesEntityExist(pilot) then DeleteEntity(pilot) end
	if DoesEntityExist(plane) then DeleteEntity(plane) end
	SetModelAsNoLongerNeeded(planeHash)
	if pilotHash then SetModelAsNoLongerNeeded(pilotHash) end
	SetEntityInvincible(ped, false)
	FreezeEntityPosition(ped, false)
	DisplayRadar(true)
	TriggerEvent('tempui:toggleUi', false)
end
