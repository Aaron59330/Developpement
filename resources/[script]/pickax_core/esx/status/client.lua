CreateThread(function()
	TriggerEvent('chat:addSuggestion', '/heal', 'Heal un joueur',{
		{ name = "ID", help = "ID d'un joueur." }
	})
end)

function CreateStatus(name, default, color, tickCallback)
	local self = {}

	self.val = default
	self.name = name
	self.default = default
	self.color = color
	self.tickCallback = tickCallback

	self.onTick = function()
		self.tickCallback(self)
	end

	self.set = function(val)
		self.val = val
	end

	self.add = function(val)
		if self.val + val > ConfigStatus.StatusMax then
			self.val = ConfigStatus.StatusMax
		else
			self.val = self.val + val
		end
	end

	self.remove = function(val)
		if self.val - val < 0 then
			self.val = 0
		else
			self.val = self.val - val
		end
	end

	self.reset = function()
		self.set(self.default)
	end

	self.getPercent = function()
		return (self.val / ConfigStatus.StatusMax) * 100
	end

	return self
end

Status = {}

function GetStatus(name, cb)
	for i = 1, #Status, 1 do
		if Status[i].name == name then
			cb(Status[i])
			return
		end
	end
end

function GetStatusData(minimal)
	local status = {}

	for i = 1, #Status, 1 do
		if minimal then
			table.insert(status, {
				name = Status[i].name,
				val = Status[i].val,
				percent = (Status[i].val / ConfigStatus.StatusMax) * 100
			})
		else
			table.insert(status, {
				name = Status[i].name,
				val = Status[i].val,
				color = Status[i].color,
				max = Status[i].max,
				percent = (Status[i].val / ConfigStatus.StatusMax) * 100
			})
		end
	end

	return status
end

function RegisterStatus(name, default, color, tickCallback)
	local status = CreateStatus(name, default, color, tickCallback)
	table.insert(Status, status)
end

RegisterNetEvent('esx_status:load')
AddEventHandler('esx_status:load', function(status)
	for i = 1, #Status, 1 do
		for j = 1, #status, 1 do
			if Status[i].name == status[j].name then
				Status[i].set(status[j].val)
			end
		end
	end

	Citizen.CreateThread(function()
		while true do

			if not InAFK then
				for i = 1, #Status, 1 do
					Status[i].onTick()
					if Status[i].name == "hunger" then
						Status[i].remove(ConfigStatus.Removehunger)
					elseif Status[i].name == "thirst" then
						Status[i].remove(ConfigStatus.Removethirst)
					end
				end
				TriggerEvent('esx_newui:updateBasics', GetStatusData(true))
			end

			Citizen.Wait(ConfigStatus.TickTime)
		end
	end)
end)

RegisterNetEvent('esx_status:set')
AddEventHandler('esx_status:set', function(name, val)
	for i = 1, #Status, 1 do
		if Status[i].name == name then
			Status[i].set(val)
			break
		end
	end

	TriggerServerEvent('esx_status:update', GetStatusData(true))
	TriggerEvent('esx_newui:updateBasics', GetStatusData(true))
end)

RegisterNetEvent('esx_status:healPlayer')
AddEventHandler('esx_status:healPlayer', function()
	for i = 1, #Status, 1 do
		if Status[i].name == "hunger" then
			Status[i].add(ConfigStatus.StatusMax)
		elseif Status[i].name == "thirst" then
			Status[i].add(ConfigStatus.StatusMax)
		end
	end
	local playerPed = PlayerPedId()
	SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
end)

RegisterNetEvent('esx_status:add')
AddEventHandler('esx_status:add', function(name, val)
	for i = 1, #Status, 1 do
		if Status[i].name == name then
			Status[i].add(val)
		end
	end

	TriggerServerEvent('esx_status:update', GetStatusData(true))
	TriggerEvent('esx_newui:updateBasics', GetStatusData(true))
end)

AddEventHandler('esx_status:remove', function(name, val)
	for i = 1, #Status, 1 do
		if Status[i].name == name then
			Status[i].remove(val)
			break
		end
	end

	TriggerServerEvent('esx_status:update', GetStatusData(true))
	TriggerEvent('esx_newui:updateBasics', GetStatusData(true))
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(ConfigStatus.UpdateInterval)
		TriggerServerEvent('esx_status:update', GetStatusData(true))
	end
end)

local IsAnimated = false
local IsAlreadyDrunk = false
local DrunkLevel = -1
local IsAlreadyDrug = false

function DrunkEffect(level, start)
	Citizen.CreateThread(function()
		local playerPed = PlayerPedId()

		if start then
			DoScreenFadeOut(800)
			Citizen.Wait(1000)
		end

		if level == 0 then
			ESX.Streaming.RequestAnimSet("move_m@drunk@slightlydrunk")

			SetPedMovementClipset(playerPed, "move_m@drunk@slightlydrunk", true)
			RemoveAnimSet("move_m@drunk@slightlydrunk")
		elseif level == 1 then
			ESX.Streaming.RequestAnimSet("move_m@drunk@moderatedrunk")

			SetPedMovementClipset(playerPed, "move_m@drunk@moderatedrunk", true)
			RemoveAnimSet("move_m@drunk@moderatedrunk")
		elseif level == 2 then
			ESX.Streaming.RequestAnimSet("move_m@drunk@verydrunk")

			SetPedMovementClipset(playerPed, "move_m@drunk@verydrunk", true)
			RemoveAnimSet("move_m@drunk@verydrunk")
		end

		SetTimecycleModifier("spectator5")
		SetPedMotionBlur(playerPed, true)
		SetPedIsDrunk(playerPed, true)

		if start then
			DoScreenFadeIn(800)
		end
	end)
end

function OverdoseEffect()
	Citizen.CreateThread(function()
		local playerPed = PlayerPedId()

		SetEntityHealth(playerPed, 0)
		ClearTimecycleModifier()
		ResetScenarioTypesEnabled()
		ResetPedMovementClipset(playerPed, 0.0)
		SetPedIsDrug(playerPed, false)
		SetPedMotionBlur(playerPed, false)
	end)
end

function StopEffect()
	Citizen.CreateThread(function()
		local playerPed = PlayerPedId()

		DoScreenFadeOut(800)
		Citizen.Wait(1000)

		ClearTimecycleModifier()
		ResetScenarioTypesEnabled()
		ResetPedMovementClipset(playerPed, 0.0)
		SetPedIsDrunk(playerPed, false)
		SetPedMotionBlur(playerPed, false)

		DoScreenFadeIn(800)
	end)
end

RegisterNetEvent('esx_status:resetStatus')
AddEventHandler('esx_status:resetStatus', function()
	for i = 1, #Status, 1 do
		Status[i].reset()
	end
end)

AddEventHandler('esx_status:getStatus', function(name, cb)
	for i=1, #Status, 1 do
		if Status[i].name == name then
			cb(Status[i])
			return
		end
	end
end)

AddEventHandler('esx_status:registerStatus', function(name, default, color, visible, tickCallback)
	local status = CreateStatus(name, default, color, visible, tickCallback)
	table.insert(Status, status)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	TriggerEvent('esx_status:loaded')
end)

Citizen.CreateThread(function()
	TriggerEvent('esx_status:loaded')
end)