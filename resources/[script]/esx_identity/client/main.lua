local guiEnabled = false
local myIdentity = {}
local myIdentifiers = {}
local hasIdentity = false
local isDead = false
local awaitingDestination = false   -- vrai entre la validation de l'identité et le choix de la destination

ESX = exports[Config.Framework]:getSharedObject()
Citizen.CreateThread(function()
	while ESX == nil do
		Citizen.Wait(100)
	end
end)

AddEventHandler('esx:onPlayerDeath', function()
	isDead = true
end)

AddEventHandler('playerSpawned', function()
	isDead = false
end)

local headHandle = nil

-- Photo de la tête du joueur (pedheadshot) pour la carte d'identité
local function UpdateHeadshot()
	if headHandle then
		UnregisterPedheadshot(headHandle)
		headHandle = nil
	end

	-- Plusieurs essais : le ped peut ne pas être prêt juste après le spawn
	for attempt = 1, 3 do
		local handle = RegisterPedheadshotTransparent(PlayerPedId())
		local timeout = GetGameTimer() + 4000

		while not IsPedheadshotReady(handle) or not IsPedheadshotValid(handle) do
			if GetGameTimer() > timeout then break end
			Citizen.Wait(50)
		end

		if IsPedheadshotReady(handle) and IsPedheadshotValid(handle) then
			headHandle = handle
			local txd = GetPedheadshotTxdString(handle)
			SendNUIMessage({ type = "head", src = "https://nui-img/" .. txd .. "/" .. txd })
			return
		end

		UnregisterPedheadshot(handle)
		Citizen.Wait(500)
	end
end

-- Rafraîchit la photo quand un autre script change l'apparence du joueur (skinchanger, créateur de personnage...)
-- Utilisable aussi manuellement : TriggerEvent('esx_identity:refreshHead')
local function RefreshHeadIfOpen()
	if guiEnabled then
		Citizen.CreateThread(function()
			Citizen.Wait(600) -- laisse le ped finir de charger sa nouvelle apparence
			if guiEnabled then UpdateHeadshot() end
		end)
	end
end

RegisterNetEvent('esx_identity:refreshHead', RefreshHeadIfOpen)
AddEventHandler('skinchanger:modelLoaded', RefreshHeadIfOpen)
AddEventHandler('skinchanger:loadSkin', RefreshHeadIfOpen)
AddEventHandler('skinchanger:loadClothes', RefreshHeadIfOpen)
AddEventHandler('esx_skin:playerRegistered', RefreshHeadIfOpen)

-- Choix Homme / Femme dans le formulaire : le personnage change tout de suite de modèle (homme = sexe 0, femme = sexe 1)
-- et la photo de la carte d'identité se met à jour avec le bon ped.
RegisterNUICallback('setSex', function(data, cb)
	cb('ok')
	local wantFemale = data and (data.sex == 'f' or data.sex == 'F')
	local isFemale = GetEntityModel(PlayerPedId()) == `mp_f_freemode_01`
	if wantFemale == isFemale then return end
	Citizen.CreateThread(function()
		local applied = false
		TriggerEvent('skinchanger:loadSkin', { sex = wantFemale and 1 or 0 }, function() applied = true end)
		local untilT = GetGameTimer() + 5000
		while not applied and GetGameTimer() < untilT do Citizen.Wait(50) end
		Citizen.Wait(300)
		if guiEnabled then UpdateHeadshot() end
	end)
end)

RegisterNUICallback('requestHead', function(data, cb)
	if guiEnabled then
		Citizen.CreateThread(UpdateHeadshot)
	end
	cb('ok')
end)

function EnableGui(state)
	-- Nouvel écran « Enregistrement du Personnage » (pickax_creator) si la ressource est démarrée ; sinon l'ancien formulaire
	if GetResourceState('pickax_creator') == 'started' then
		guiEnabled = state
		if state then exports['pickax_creator']:OpenIdentity() else exports['pickax_creator']:Close() end
		return
	end
	SetNuiFocus(state, state)
	guiEnabled = state

	if state then
		Citizen.CreateThread(UpdateHeadshot)

		-- Rafraîchit la photo dès que l'apparence du ped change (modèle homme/femme, visage, cheveux, tenue...)
		Citizen.CreateThread(function()
			local function signature()
				local ped = PlayerPedId()
				local sig = tostring(GetEntityModel(ped))
				for comp = 0, 11 do
					sig = sig .. ':' .. GetPedDrawableVariation(ped, comp) .. '/' .. GetPedTextureVariation(ped, comp)
				end
				for prop = 0, 2 do
					sig = sig .. ':p' .. GetPedPropIndex(ped, prop)
				end
				return sig
			end

			local last = signature()
			while guiEnabled do
				Citizen.Wait(700)
				local current = signature()
				if current ~= last then
					last = current
					UpdateHeadshot()
				end
			end
		end)

		-- Garde le curseur NUI tant que le menu est ouvert (le loading screen peut le retirer en se fermant)
		Citizen.CreateThread(function()
			while guiEnabled do
				SetNuiFocus(true, true)
				Citizen.Wait(250)
			end
		end)
	elseif headHandle then
		UnregisterPedheadshot(headHandle)
		headHandle = nil
	end

	SendNUIMessage({
		type = "enableui",
		enable = state
	})
end

RegisterNetEvent('esx_identity:saveID')
AddEventHandler('esx_identity:saveID', function(data)
	myIdentifiers = data
end)

RegisterNetEvent('esx_identity:showRegisterIdentity')
AddEventHandler('esx_identity:showRegisterIdentity', function()
	if not isDead then
		-- Première connexion : le menu s'ouvre tout seul pendant que le loading screen est encore là.
		-- On attend la fin du chargement du jeu, puis on ferme la page du loading screen (qui garde le curseur)
		-- avant d'ouvrir le menu, pour que le curseur soit bien rendu à esx_identity.
		local waited = 0
		while GetIsLoadingScreenActive() and waited < 30000 do
			Citizen.Wait(200)
			waited = waited + 200
		end

		ShutdownLoadingScreenNui()
		Citizen.Wait(500)

		EnableGui(true)
	end
end)

-- Mise à jour du personnage après un /register : synchronise ESX.PlayerData côté client
RegisterNetEvent('esx_identity:identityUpdated')
AddEventHandler('esx_identity:identityUpdated', function(data)
	if ESX and ESX.PlayerData then
		ESX.PlayerData.firstName = data.firstname
		ESX.PlayerData.lastName = data.lastname
		ESX.PlayerData.dateofbirth = data.dateofbirth
		ESX.PlayerData.sex = data.sex
		ESX.PlayerData.height = data.height
		ESX.PlayerData.nationality = data.nationality
	end
end)

RegisterNetEvent('esx_identity:identityCheck')
AddEventHandler('esx_identity:identityCheck', function(identityCheck)
	hasIdentity = identityCheck
end)

RegisterNUICallback('escape', function(data, cb)
	if hasIdentity then
		EnableGui(false)
	else
		ESX.ShowNotification('~r~Action Impossible~s~ : Vous devez créer votre premier personnage pour pouvoir jouer !')
	end
end)

-- Validation + création : renvoie le motif du refus (texte) ou nil si l'identité est acceptée
function SubmitIdentity(myIdentity)
	local reason

	for k, v in pairs(myIdentity) do
		if k == "firstname" or k == "lastname" then
			reason = verifyName(v)
			
			if reason ~= nil then
				break
			end
		elseif k == "dateofbirth" then
			if v == "invalid" then
				reason = "Date de naissance invalide!"
				break
			end
		elseif k == "nationality" then
			if v == nil or v == "" then
				reason = "Veuillez choisir une nationalité !"
				break
			end
		elseif k == "height" then
			local height = tonumber(v)

			if height then
				if height > 200 or height < 140 then
					reason = "Hauteur de joueur incorrect !"
					break
				end
			else
				reason = "Hauteur de joueur incorrect !"
				break
			end
		end
	end
	
	if reason == nil then
		TriggerServerEvent('esx_identity:setIdentity', myIdentity)
		EnableGui(false)
		Citizen.Wait(500)

		-- Le sexe choisi dans l'identité devient le « sexe » du menu de création (Homme = 0, Femme = 1)
		local sex = (myIdentity.sex == 'f' or myIdentity.sex == 'F') and 1 or 0
		local applied = false
		TriggerEvent('skinchanger:loadSkin', { sex = sex }, function() applied = true end)
		local untilT = GetGameTimer() + 6000
		while not applied and GetGameTimer() < untilT do Citizen.Wait(50) end

		awaitingDestination = Config.Destinations and Config.Destinations.Enabled == true
		if Config.CustomTrigger then
			CustomEvent(myIdentifiers.id)
		else
			TriggerEvent('CorePickax:Creator:openSkinMenu', true)
		end
	else
		ESX.ShowNotification(reason)
	end
	return reason
end
exports('SubmitIdentity', SubmitIdentity)
exports('GetSpots', function() return (Config.Destinations and Config.Destinations.Spots) or {} end)
RegisterNUICallback('register', function(myIdentity, cb) SubmitIdentity(myIdentity) end)
exports('CancelIdentity', function()
	if hasIdentity then EnableGui(false) else ESX.ShowNotification('~r~Action Impossible~s~ : Vous devez créer votre premier personnage pour pouvoir jouer !') end
end)
exports('SetSex', function(sex)
	local wantFemale = sex == 'f' or sex == 'F'
	local isFemale = GetEntityModel(PlayerPedId()) == `mp_f_freemode_01`
	if wantFemale == isFemale then return end
	Citizen.CreateThread(function()
		local applied = false
		TriggerEvent('skinchanger:loadSkin', { sex = wantFemale and 1 or 0 }, function() applied = true end)
		local untilT = GetGameTimer() + 5000
		while not applied and GetGameTimer() < untilT do Citizen.Wait(50) end
	end)
end)

Citizen.CreateThread(function()
	while true do
		if guiEnabled then
			DisableControlAction(0, 1, true) -- LookLeftRight
			DisableControlAction(0, 2, true) -- LookUpDown
			DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
			DisableControlAction(0, 142, true) -- MeleeAttackAlternate
			DisableControlAction(0, 30, true) -- MoveLeftRight
			DisableControlAction(0, 31, true) -- MoveUpDown
			DisableControlAction(0, 21, true) -- disable sprint
			DisableControlAction(0, 24, true) -- disable attack
			DisableControlAction(0, 25, true) -- disable aim
			DisableControlAction(0, 47, true) -- disable weapon
			DisableControlAction(0, 58, true) -- disable weapon
			DisableControlAction(0, 263, true) -- disable melee
			DisableControlAction(0, 264, true) -- disable melee
			DisableControlAction(0, 257, true) -- disable melee
			DisableControlAction(0, 140, true) -- disable melee
			DisableControlAction(0, 141, true) -- disable melee
			DisableControlAction(0, 143, true) -- disable melee
			DisableControlAction(0, 75, true) -- disable exit vehicle
			DisableControlAction(27, 75, true) -- disable exit vehicle
		end

		Citizen.Wait(10)
	end
end)

function verifyName(name)
	local nameLength = string.len(name)

	if nameLength > 25 or nameLength < 2 then
		return 'Votre nom est trop court ou trop long.'
	end

	local count = 0

	for i in name:gmatch('[abcdefghijklmnopqrstuvwxyzåäöABCDEFGHIJKLMNOPQRSTUVWXYZÅÄÖ0123456789 -]') do
		count = count + 1
	end

	if count ~= nameLength then
		return 'Votre nom de joueur contient des caractères spéciaux qui ne sont pas autorisés sur ce serveur.'
	end

	local spacesInName = 0
	local spacesWithUpper = 0

	for word in string.gmatch(name, '%S+') do
		if string.match(word, '%u') then
			spacesWithUpper = spacesWithUpper + 1
		end

		spacesInName = spacesInName + 1
	end

	if spacesInName > 2 then
		return 'Votre nom contient plus de deux espaces'
	end
	
	if spacesWithUpper ~= spacesInName then
		return 'votre nom doit commencer par une lettre majuscule.'
	end

	return
end

-- ─────────────────────────────── Menu « Destination » ───────────────────────────────
local function teleportTo(spot)
	local c = spot.coords
	local ped = PlayerPedId()
	DoScreenFadeOut(600)
	while not IsScreenFadedOut() do Citizen.Wait(10) end
	FreezeEntityPosition(ped, true)
	RequestCollisionAtCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
	SetEntityCoordsNoOffset(ped, c.x + 0.0, c.y + 0.0, c.z + 0.0, false, false, false)
	SetEntityHeading(ped, (c.w or 0.0) + 0.0)
	local t = GetGameTimer()
	while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() - t < 4000 do Citizen.Wait(50) end
	FreezeEntityPosition(ped, false)
	Citizen.Wait(300)
	DoScreenFadeIn(800)
end

-- Appelé par CorePickax (skinchanger) quand le joueur valide son personnage
AddEventHandler('CorePickax:Creator:finished', function()
	if not awaitingDestination then return end
	awaitingDestination = false

	local D = Config.Destinations
	if not D or not D.Enabled or not D.Spots or #D.Spots == 0 then return end

	Citizen.Wait(600)
	local index = 1
	local creator = GetResourceState('pickax_creator') == 'started'
	if creator and #D.Spots > 1 then
		index = exports['pickax_creator']:ChooseSpawn(D.Spots) or 1
	elseif GetResourceState('pickax_ui') == 'started' and #D.Spots > 1 then
		local options = {}
		for i, spot in ipairs(D.Spots) do
			options[i] = { label = spot.label, description = spot.description, icon = spot.icon }
		end
		index = exports['pickax_ui']:Choose({ title = D.Title or 'Destination', hint = D.Hint, options = options, cancellable = false }) or 1
	end

	local spot = D.Spots[index] or D.Spots[1]
	teleportTo(spot)
	ESX.ShowNotification(('Bienvenue ! Tu arrives à ~b~%s~s~.'):format(spot.label))
	if creator then Citizen.Wait(600) exports['pickax_creator']:ShowWelcome() end
end)
