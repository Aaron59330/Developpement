--CalmAI List
local relationshipTypes = {
    'COP',
    'SECURITY_GUARD',
    'PRIVATE_SECURITY',
    'FIREMAN',
    'GANG_1',
    'GANG_2',
    'GANG_9',
    'GANG_10',
    'AMBIENT_GANG_LOST',
    'AMBIENT_GANG_MEXICAN',
    'AMBIENT_GANG_FAMILY',
    'AMBIENT_GANG_BALLAS',
    'AMBIENT_GANG_MARABUNTE',
    'AMBIENT_GANG_CULT',
    'AMBIENT_GANG_SALVA',
    'AMBIENT_GANG_WEICHENG',
    'AMBIENT_GANG_HILLBILLY',
    'DEALER',
    'HATES_PLAYER',
    'HEN',
    'WILD_ANIMAL',
    'SHARK',
    'COUGAR',
    'NO_RELATIONSHIP',
    'SPECIAL',
    'MISSION2',
    'MISSION3',
    'MISSION4',
    'MISSION5',
    'MISSION6',
    'MISSION7',
    'MISSION8',
    'ARMY',
    'GUARD_DOG',
    'AGGRESSIVE_INVESTIGATE',
    'MEDIC',
    'CAT'
}

Citizen.CreateThread(function()
    --Desactiver la radio lspd sound de gta v
    for i = 1, 15 do
		EnableDispatchService(i, EnableDispatch)
	end

	--CalmAI
	for _, group in ipairs(relationshipTypes) do
		SetRelationshipBetweenGroups(1, GetHashKey('PLAYER'), GetHashKey(group)) -- could be removed
		SetRelationshipBetweenGroups(1, GetHashKey(group), GetHashKey('PLAYER'))
	end

	while true do
		Wait(1)
		
		--Desactivation des recompense du joueur du vehicule
		DisablePlayerVehicleRewards(PlayerId())
			
		--Desactivation des drops des armes
		RemoveAllPickupsOfType(0xDF711959) -- carbine rifle
		RemoveAllPickupsOfType(0xF9AFB48F) -- pistol
		RemoveAllPickupsOfType(0xA9355DCD) -- pumpshotgun
	end
end)

Citizen.CreateThread(function()
	-- Function MAP ZOOM
	if ConfigNPC.ZoomMap == true then
		SetMapZoomDataLevel(0, 0.96, 0.9, 0.08, 0.0, 0.0) -- Level 0
		SetMapZoomDataLevel(1, 1.6, 0.9, 0.08, 0.0, 0.0) -- Level 1
		SetMapZoomDataLevel(2, 8.6, 0.9, 0.08, 0.0, 0.0) -- Level 2
		SetMapZoomDataLevel(3, 12.3, 0.9, 0.08, 0.0, 0.0) -- Level 3
		SetMapZoomDataLevel(4, 24.3, 0.9, 0.08, 0.0, 0.0) -- Level 4
		SetMapZoomDataLevel(5, 55.0, 0.0, 0.1, 2.0, 1.0) -- ZOOM_LEVEL_GOLF_COURSE
		SetMapZoomDataLevel(6, 450.0, 0.0, 0.1, 1.0, 1.0) -- ZOOM_LEVEL_INTERIOR
		SetMapZoomDataLevel(7, 4.5, 0.0, 0.0, 0.0, 0.0) -- ZOOM_LEVEL_GALLERY
		SetMapZoomDataLevel(8, 11.0, 0.0, 0.0, 2.0, 3.0) -- ZOOM_LEVEL_GALLERY_MAXIMIZE
	end

	--Train
	if ConfigNPC.Train == true then
		SwitchTrainTrack(0, true)
		SwitchTrainTrack(3, true)
		N_0x21973bbf8d17edfa(0, 120000)
		SetRandomTrains(true)
	end
end)

-- Natives à appliquer une fois (et à ré-appliquer quand un réglage du panel web change)
local function applyNpcFlags()
	SetRandomBoats(ConfigNPC.EnableBoats)
	SetRandomTrains(ConfigNPC.EnableTrains)
	SetGarbageTrucks(ConfigNPC.EnableGarbageTrucks)
	SetCreateRandomCops(ConfigNPC.EnablePolice)
	SetCreateRandomCopsNotOnScenarios(ConfigNPC.EnablePolice)
	SetCreateRandomCopsOnScenarios(ConfigNPC.EnablePolice)
	SetDispatchCopsForPlayer(PlayerId(), ConfigNPC.EnablePolice)
end

local budgetZero = false

Citizen.CreateThread(function()
	-- Ces options doivent etre appliquees meme lorsque AllowNPC = false.
	applyNpcFlags()

	while true do
		local on = ConfigNPC.AllowNPC
		local dPed = on and ConfigNPC.pnjdensity or 0.0
		local dVeh = on and (ConfigNPC.vehdensity or ConfigNPC.pnjdensity) or 0.0
		local dPark = on and (ConfigNPC.parkeddensity or ConfigNPC.pnjdensity) or 0.0

		-- Les natives *ThisFrame doivent etre reappliquees a chaque frame.
		SetVehicleDensityMultiplierThisFrame(dVeh)
		SetPedDensityMultiplierThisFrame(dPed)
		SetRandomVehicleDensityMultiplierThisFrame(dVeh)
		SetParkedVehicleDensityMultiplierThisFrame(dPark)
		SetScenarioPedDensityMultiplierThisFrame(dPed, dPed)

		-- Renforce la desactivation de la population ambiante GTA (et la restaure si le panel la reactive).
		if dPed <= 0.0 and dVeh <= 0.0 then
			if not budgetZero then budgetZero = true end
			SetPedPopulationBudget(0)
			SetVehiclePopulationBudget(0)
		elseif budgetZero then
			budgetZero = false
			SetPedPopulationBudget(3)
			SetVehiclePopulationBudget(3)
		end

		Citizen.Wait(0)
	end
end)

-- Reglages du panel web (pickax_settings > Monde & PNJ) : appliques en direct, sans redemarrage.
local function onSettings(all, ov)
	if not ov then return end
	local touched = false
	if ov.npc_enabled ~= nil or ov.npc_density ~= nil or ov.traffic_density ~= nil or ov.parked_density ~= nil then
		ConfigNPC.AllowNPC = all.npc_enabled == true
		ConfigNPC.pnjdensity = tonumber(all.npc_density) or 0.5
		ConfigNPC.vehdensity = tonumber(all.traffic_density) or ConfigNPC.pnjdensity
		ConfigNPC.parkeddensity = tonumber(all.parked_density) or ConfigNPC.pnjdensity
	end
	if ov.npc_police ~= nil then ConfigNPC.EnablePolice = all.npc_police == true touched = true end
	if ov.npc_boats ~= nil then ConfigNPC.EnableBoats = all.npc_boats == true touched = true end
	if ov.npc_trains ~= nil then ConfigNPC.EnableTrains = all.npc_trains == true touched = true end
	if ov.npc_garbage ~= nil then ConfigNPC.EnableGarbageTrucks = all.npc_garbage == true touched = true end
	if touched then
		applyNpcFlags()
		if ov.npc_police ~= nil then for i = 1, 15 do EnableDispatchService(i, ConfigNPC.EnablePolice) end end
	end
end
AddEventHandler('pickax_settings:changed', onSettings)
-- si pickax_core redemarre apres pickax_settings : on recupere les reglages deja recus
Citizen.CreateThread(function()
	Citizen.Wait(4000)
	if GetResourceState('pickax_settings') ~= 'started' then return end
	local ok, all = pcall(function() return exports.pickax_settings:GetAll() end)
	local ok2, ov = pcall(function() return exports.pickax_settings:Overrides() end)
	if ok and ok2 and type(ov) == 'table' and next(ov) then onSettings(all, ov) end
end)
