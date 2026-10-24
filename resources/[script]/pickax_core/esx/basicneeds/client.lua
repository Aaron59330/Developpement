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
-- ═══════════════ Consommation des objets (animation + prop + effet) ═══════════════
local consuming = false
local drunkUntil = 0

local function loadAnim(dict)
	RequestAnimDict(dict)
	local t = GetGameTimer()
	while not HasAnimDictLoaded(dict) and GetGameTimer() - t < 3000 do Wait(10) end
	return HasAnimDictLoaded(dict)
end

local function spawnProp(p, ped)
	local hash = GetHashKey(p.model)
	RequestModel(hash)
	local t = GetGameTimer()
	while not HasModelLoaded(hash) and GetGameTimer() - t < 3000 do Wait(10) end
	if not HasModelLoaded(hash) then return nil end
	local c = GetEntityCoords(ped)
	local obj = CreateObject(hash, c.x, c.y, c.z + 0.2, true, true, true)
	SetModelAsNoLongerNeeded(hash)
	AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, p.bone or 18905), p.x or 0.0, p.y or 0.0, p.z or 0.0, p.rx or 0.0, p.ry or 0.0, p.rz or 0.0, true, true, false, true, 1, true)
	return obj
end

local function startDrunk(seconds)
	local now = GetGameTimer()
	local first = drunkUntil < now
	drunkUntil = math.max(drunkUntil, now) + seconds * 1000
	if not first then return end
	CreateThread(function()
		local ped = PlayerPedId()
		RequestAnimSet('move_m@drunk@slightlydrunk')
		while not HasAnimSetLoaded('move_m@drunk@slightlydrunk') do Wait(10) end
		SetPedMovementClipset(ped, 'move_m@drunk@slightlydrunk', 0.5)
		SetPedMotionBlur(ped, true)
		ShakeGameplayCam('DRUNK_SHAKE', 0.5)
		while GetGameTimer() < drunkUntil do Wait(500) end
		ped = PlayerPedId()
		ResetPedMovementClipset(ped, 0.5)
		SetPedMotionBlur(ped, false)
		StopGameplayCamShaking(true)
	end)
end

-- joue l'animation (+ prop) d'une définition, retourne true si elle a pu se faire
local function playDef(def)
	local ped = PlayerPedId()
	local prop
	if def.prop then prop = spawnProp(def.prop, ped) end
	if def.scenario then
		TaskStartScenarioInPlace(ped, def.scenario, 0, true)
		Wait(def.ms or 8000)
		ClearPedTasks(ped)
	elseif def.anim and loadAnim(def.anim.dict) then
		TaskPlayAnim(ped, def.anim.dict, def.anim.clip, 8.0, -8.0, -1, def.anim.flag or 49, 0, false, false, false)
		Wait(def.anim.ms or 3500)
		StopAnimTask(ped, def.anim.dict, def.anim.clip, 1.0)
		ClearPedSecondaryTask(ped)
	end
	if prop and DoesEntityExist(prop) then DeleteObject(prop) end
end

RegisterNetEvent('pickax_needs:consume', function(name)
	local def = ConfigBasicNeeds.Consumables[name]
	if not def then return TriggerServerEvent('pickax_needs:done', name, false) end
	local ped = PlayerPedId()
	if consuming or IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) and def.kind ~= 'smoke' and def.kind ~= 'drink' and def.kind ~= 'alcohol' then
		if not consuming then ESX.ShowNotification('~r~Impossible de faire ça maintenant') end
		return TriggerServerEvent('pickax_needs:done', name, false)
	end
	consuming = true
	CreateThread(function()
		local applied = false
		local inVeh = IsPedInAnyVehicle(PlayerPedId(), false)
		-- en véhicule : pas d'animation lourde (on applique directement l'effet)
		if not inVeh then playDef(def) else Wait(800) end
		ped = PlayerPedId()
		if def.kind == 'heal' then
			local max = GetEntityMaxHealth(ped)
			local hp = GetEntityHealth(ped)
			if hp < max then SetEntityHealth(ped, math.min(max, hp + def.health)) applied = true
			else ESX.ShowNotification("~o~Vous êtes déjà en pleine forme") end
		elseif def.kind == 'armor' then
			if GetPedArmour(ped) < 100 then SetPedArmour(ped, math.min(100, GetPedArmour(ped) + def.armor)) applied = true
			else ESX.ShowNotification('~o~Vous portez déjà un gilet complet') end
		elseif def.kind == 'alcohol' then
			startDrunk(def.drunk or 60)
			applied = true
		else
			applied = true
		end
		if applied and def.msg then TriggerEvent(Config.Trigger.TriggerNotification, def.msg) end
		TriggerServerEvent('pickax_needs:done', name, applied)
		consuming = false
	end)
end)

-- distributeurs / bars : mêmes animations, avec le bon prop
local VENDING = {
	['esx_basicneeds:onDrink']      = { anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49, ms = 3500 }, prop = { model = 'prop_ld_flow_bottle', bone = 18905, x = 0.12, y = 0.028, z = 0.001, rx = 10.0, ry = 175.0, rz = 0.0 } },
	['esx_basicneeds:onDrinkCoffe'] = { anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49, ms = 3500 }, prop = { model = 'p_amb_coffeecup_01', bone = 28422, x = 0.0, y = 0.0, z = 0.0, rx = 0.0, ry = 0.0, rz = 0.0 } },
}
for ev, def in pairs(VENDING) do
	RegisterNetEvent(ev)
	AddEventHandler(ev, function()
		if consuming then return end
		consuming = true
		CreateThread(function() playDef(def) consuming = false end)
	end)
end
