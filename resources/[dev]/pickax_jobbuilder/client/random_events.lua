-- Événements aléatoires liés aux métiers : blip + incident visible (objets locaux) + intervention (voir config_events.lua)
local Evs = {}

local function loadModel(name)
    local hash = type(name) == 'number' and name or joaat(name)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local t = GetGameTimer() + 4000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
    return HasModelLoaded(hash) and hash or nil
end

local function groundZ(x, y, z)
    local ok, gz = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, z + 50.0, false)
    return ok and gz or z
end

local function spawn(ev)
    local d = ev.data
    local x, y = d.x, d.y
    RequestCollisionAtCoord(x + 0.0, y + 0.0, d.z + 0.0)
    local z = groundZ(x, y, d.z)
    local list = ev.ents
    if d.visual == 'vehicle' or d.visual == 'injured' then
        local model = loadModel((d.models and d.models[math.random(#d.models)]) or 'blista')
        if model then
            local veh = CreateVehicle(model, x + 0.0, y + 0.0, z + 0.0, d.h + 0.0, false, false)
            SetVehicleOnGroundProperly(veh)
            SetVehicleEngineHealth(veh, d.visual == 'vehicle' and 120.0 or 0.0)
            SetVehicleBodyHealth(veh, d.visual == 'injured' and 150.0 or 600.0)
            SetVehicleUndriveable(veh, true)
            SetVehicleDoorsLocked(veh, 2)
            SetVehicleIndicatorLights(veh, 0, true) SetVehicleIndicatorLights(veh, 1, true)
            if d.visual == 'vehicle' then SetVehicleDoorOpen(veh, 4, false, false) else SmashVehicleWindow(veh, 0) SetVehicleDoorBroken(veh, 0, true) end
            FreezeEntityPosition(veh, true)
            SetModelAsNoLongerNeeded(model)
            list[#list + 1] = veh
        end
        if d.visual == 'injured' then
            local pm = loadModel(d.ped or 'a_m_m_business_01')
            if pm then
                local ped = CreatePed(4, pm, x + 2.2, y + 0.8, z + 0.0, d.h + 0.0, false, false)
                SetEntityHealth(ped, 120)
                SetBlockingOfNonTemporaryEvents(ped, true)
                RequestAnimDict('dead')
                local t = GetGameTimer() + 2000
                while not HasAnimDictLoaded('dead') and GetGameTimer() < t do Wait(10) end
                TaskPlayAnim(ped, 'dead', 'dead_a', 8.0, 8.0, -1, 1, 0.0, false, false, false)
                FreezeEntityPosition(ped, true)
                SetModelAsNoLongerNeeded(pm)
                list[#list + 1] = ped
            end
        end
    elseif d.visual == 'dump' then
        for i = 1, 6 do
            local model = loadModel(d.props[math.random(#d.props)])
            if model then
                local ox, oy = x + math.random(-30, 30) / 10.0, y + math.random(-30, 30) / 10.0
                local o = CreateObject(model, ox, oy, groundZ(ox, oy, z) + 0.0, false, false, false)
                PlaceObjectOnGroundProperly(o)
                FreezeEntityPosition(o, true)
                SetModelAsNoLongerNeeded(model)
                list[#list + 1] = o
            end
        end
    end
    ev.spawned = true
    ev.z = z
end

local function cleanup(ev)
    for _, e in ipairs(ev.ents or {}) do if DoesEntityExist(e) then SetEntityAsMissionEntity(e, true, true) DeleteEntity(e) end end
    if ev.blip and DoesBlipExist(ev.blip) then RemoveBlip(ev.blip) end
    if ev.area and DoesBlipExist(ev.area) then RemoveBlip(ev.area) end
    if ev.sound then StopSound(ev.sound) ReleaseSoundId(ev.sound) end
end

RegisterNetEvent('jb:re:start', function(d)
    if Evs[d.id] then return end
    local ev = { data = d, ents = {}, spawned = false }
    ev.area = AddBlipForRadius(d.x + 0.0, d.y + 0.0, d.z + 0.0, 90.0)
    SetBlipColour(ev.area, 1) SetBlipAlpha(ev.area, 110)
    ev.blip = AddBlipForCoord(d.x + 0.0, d.y + 0.0, d.z + 0.0)
    SetBlipSprite(ev.blip, 161) SetBlipColour(ev.blip, 1) SetBlipScale(ev.blip, 1.0) SetBlipAsShortRange(ev.blip, false) SetBlipFlashes(ev.blip, true)
    BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(d.label) EndTextCommandSetBlipName(ev.blip)
    Evs[d.id] = ev
    PlaySoundFrontend(-1, 'Event_Start_Text', 'GTAO_FM_Events_Soundset', true)
end)

RegisterNetEvent('jb:re:end', function(d)
    local ev = Evs[d.id]
    if not ev then return end
    Evs[d.id] = nil
    cleanup(ev)
    if d.reason == 'expired' then JBNotify('~o~' .. ev.data.label .. ' : plus personne n\'a eu besoin de toi, l\'incident est clos.')
    elseif d.winner and not ev.mine then JBNotify(('~b~%s~s~ a pris en charge « %s ».'):format(d.winner, ev.data.label)) end
end)

local busy = false
CreateThread(function()
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        for id, ev in pairs(Evs) do
            local d = ev.data
            local dist = #(pos - vector3(d.x, d.y, ev.z or d.z))
            if dist < 140.0 and not ev.spawned then spawn(ev) end
            if dist < 30.0 then
                wait = 0
                local c = { x = d.x, y = d.y, z = (ev.z or d.z) }
                if BB and BB.DrawMarker then BB.DrawMarker(nil, c) end
                if dist < 3.0 and not busy and not IsPedInAnyVehicle(ped, false) then
                    if GetResourceState('pickax_notify') == 'started' then exports['pickax_notify']:ShowHelpNotification('~INPUT_CONTEXT~ ' .. d.interact)
                    else AddTextEntry('JBRE_HELP', '~INPUT_CONTEXT~ ' .. d.interact) BeginTextCommandDisplayHelp('JBRE_HELP') EndTextCommandDisplayHelp(0, false, false, -1) end
                    if IsControlJustPressed(0, 38) then
                        busy = true
                        local ok = AJ and AJ.Progress and AJ.Progress(d.progress, d.seconds, { radius = 6.0, scenario = 'WORLD_HUMAN_STAND_MOBILE' })
                        if ok and Evs[id] then ev.mine = true TriggerServerEvent('jb:re:claim', id) end
                        busy = false
                    end
                end
            end
        end
        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then for _, ev in pairs(Evs) do cleanup(ev) end end end)
