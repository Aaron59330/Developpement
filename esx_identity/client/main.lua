local guiEnabled = false
local myIdentity = {}
local myIdentifiers = {}
local hasIdentity = false
local isDead = false

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

RegisterNUICallback('requestHead', function(data, cb)
	if guiEnabled then
		Citizen.CreateThread(UpdateHeadshot)
	end
	cb('ok')
end)

function EnableGui(state)
	SetNuiFocus(state, state)
	guiEnabled = state

	if state then
		Citizen.CreateThread(UpdateHeadshot)

		-- Le loading screen retire le curseur NUI quand il se ferme : on le réapplique
		-- tant que l'écran de chargement est actif, puis encore quelques instants après.
		Citizen.CreateThread(function()
			while GetIsLoadingScreenActive() do
				if not guiEnabled then return end
				SetNuiFocus(true, true)
				Citizen.Wait(200)
			end
			for _ = 1, 12 do
				Citizen.Wait(300)
				if not guiEnabled then return end
				SetNuiFocus(true, true)
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

RegisterNUICallback('register', function(myIdentity, cb)
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
		if Config.CustomTrigger then
			CustomEvent(myIdentifiers.id)
		else
			TriggerEvent('esx_custom:Creator:openSkinMenu', myIdentifiers.id)
		end
	else
		ESX.ShowNotification(reason)
	end
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