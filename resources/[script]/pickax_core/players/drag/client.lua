local dragging_data = {
	InProgress = false,
	target = -1,
	Anim = {
		dict = "combat@drag_ped@",
		start = "injured_pickup_back_",
		loop = "injured_drag_",
		ending = "injured_putdown_"
	}
}

local old_TaskPlayAnim = TaskPlayAnim
local function TaskPlayAnim(ped, animDictionary, animationName, blendInSpeed, blendOutSpeed, duration , flag, playbackRate, lockX, lockY, lockZ)
	old_TaskPlayAnim(ped, animDictionary, animationName, blendInSpeed, blendOutSpeed, duration , flag, playbackRate, lockX, lockY, lockZ)
	RemoveAnimDict(animDictionary)
	return
end

local function PlayAnim(type, desinence)
	local duration = nil
	if type == "loop" then duration = -1 elseif type == "start" then duration = 6000 elseif type == "ending" then duration = 5000 end

	ESXCustom_Function_ClientSide:LoadAnimDict(dragging_data.Anim.dict)
	TaskPlayAnim(PlayerPedId(), dragging_data.Anim.dict, dragging_data.Anim[type]..desinence, 8.0, -8.0, duration, 33, 0, 0, 0, 0)

	if duration ~= -1 then
		Wait(duration)
		ClearPedTasks(PlayerPedId())
	end
end

Citizen.CreateThread(function()
	while true do
		local timer = 200
		local player = PlayerPedId()
		if not dragging_data.InProgress then
			local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
            if closestPlayer ~= -1 and closestDistance <= 1.5 then
                if IsPedRagdoll(GetPlayerPed(closestPlayer)) then
                    timer = 0
                    local target = GetPlayerServerId(closestPlayer)
                    if target ~= -1 then
                        ESX.ShowHelpNotification("Appuyez sur ~INPUT_PICKUP~ pour tirer la personne.")
                        if IsControlJustPressed(1, 51) then
                            dragging_data.InProgress = true
                            dragging_data.target = target
                            TriggerServerEvent("CorePickax:DragPeople:sync", target)
                            PlayAnim("start", "plyr")
                            PlayAnim("loop", "plyr")
                        end
                    end
                end
            end
		else
            if dragging_data.target ~= -1 then
                timer = 0
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_PICKUP~ pour poser la personne.")
                if IsControlJustPressed(1, 51) then
                    dragging_data.InProgress = false
                    local target_ped = GetPlayerPed(GetPlayerFromServerId(dragging_data.target))
                    TriggerServerEvent("CorePickax:DragPeople:stop",dragging_data.target)
                    DetachEntity(PlayerPedId(), true, false)
                    PlayAnim("ending", "plyr")
                    ClearPedTasks(target_ped)
                    dragging_data.InProgress = false
                    dragging_data.target = -1
                end
            end
		end
		Wait(timer)
	end
end)

RegisterNetEvent("CorePickax:DragPeople:syncTarget")
AddEventHandler("CorePickax:DragPeople:syncTarget", function(target)
	local target_ped = GetPlayerPed(GetPlayerFromServerId(target))
	local player = PlayerPedId()
	dragging_data.InProgress = true
	SetEntityCoords(player, GetOffsetFromEntityInWorldCoords(target_ped, 0.0, 1.2, -1.0))
	SetEntityHeading(player, GetEntityHeading(target_ped))
	PlayAnim("start", "ped")
	ClearPedTasks(player)
	AttachEntityToEntity(player, target_ped, 1816, 4103, 0.48, 0.0, 0.0, 0.0, 0.0, 0.0)
	PlayAnim("loop", "ped")
end)

RegisterNetEvent("CorePickax:DragPeople:cl_stop")
AddEventHandler("CorePickax:DragPeople:cl_stop", function(_target)
	_target = GetPlayerPed(GetPlayerFromServerId(_target))
	dragging_data.InProgress = false
	DetachEntity(PlayerPedId(), true, false)
	SetEntityCoords(PlayerPedId(), GetOffsetFromEntityInWorldCoords(_target, 0.0, 0.4, -1.0))
	PlayAnim("ending", "ped")
end)