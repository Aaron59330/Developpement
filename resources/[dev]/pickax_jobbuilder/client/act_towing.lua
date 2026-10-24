local KEY = 'towing'
local run = 0

AJ.Mod[KEY] = {
    start = function(d)
        run = run + 1
        local my = run
        local flat = AJ.SpawnVehicle(d.vehicle, d.spawn, d.plate)
        local scrap = d.scrap
        local mission = d.mission
        local target, loaded, zoneBlip = nil, false, nil

        local function beginMission(m)
            mission = m
            loaded, target = false, nil
            AJ.RemoveBlip(zoneBlip)
            zoneBlip = AJ.Blip({ x = m.zone.x, y = m.zone.y, z = 30.0 }, 477, 47, 'Véhicule en panne', true)
            AJ.SetHud({ 'DÉPANNEUR', 'Mission : véhicule en panne', '→ Rends-toi sur place avec la dépanneuse' })
        end
        beginMission(mission)

        RegisterNetEvent('aj:towing:next', function(m)
            if run ~= my then return end
            if target and DoesEntityExist(target) then SetEntityAsMissionEntity(target, true, true) DeleteEntity(target) end
            beginMission(m)
        end)

        local function spawnTarget()
            local p = GetEntityCoords(PlayerPedId())
            local found, node, hdg = GetClosestVehicleNodeWithHeading(mission.zone.x, mission.zone.y, p.z, 1, 3.0, 0)
            if not found then return end
            local h = AJ.LoadModel(mission.model)
            if not h then return end
            target = CreateVehicle(h, node.x, node.y, node.z, hdg, true, true)
            SetModelAsNoLongerNeeded(h)
            SetVehicleNumberPlateText(target, mission.plate)
            SetVehicleEngineHealth(target, 120.0) SetVehicleEngineOn(target, false, true, true) SetVehicleUndriveable(target, true)
            SetVehicleDoorsLocked(target, 2) SetVehicleDoorOpen(target, 4, false, false) SetVehicleDirtLevel(target, 9.0)
            SetVehicleIndicatorLights(target, 0, true) SetVehicleIndicatorLights(target, 1, true)
            SetEntityAsMissionEntity(target, true, true)
            AJ.Ents[#AJ.Ents + 1] = target
            AJ.RemoveBlip(zoneBlip)
            zoneBlip = AJ.Blip(node, 477, 47, 'Véhicule en panne', true)
            AJ.SetHud({ 'DÉPANNEUR', 'Véhicule localisé', '→ Place la dépanneuse derrière, puis E' })
        end

        CreateThread(function()
            while run == my and AJ.Active == KEY do
                local sleep = 500
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                if not flat or not DoesEntityExist(flat) then
                    AJ.Notify('~r~Ta dépanneuse a été détruite : service arrêté.')
                    ESX.TriggerServerCallback('aj:stop', function() end)
                    return
                end
                if not loaded then
                    if not target then
                        if #(vector2(pos.x, pos.y) - vector2(mission.zone.x, mission.zone.y)) < 160.0 then spawnTarget() end
                    elseif DoesEntityExist(target) and IsPedInVehicle(ped, flat, false) then
                        local back = GetOffsetFromEntityInWorldCoords(flat, 0.0, -5.5, 0.0)
                        local tp = GetEntityCoords(target)
                        sleep = 100
                        if #(tp - back) < 8.0 or #(tp - GetEntityCoords(flat)) < 9.0 then
                            sleep = 0
                            AJ.Help('~INPUT_PICKUP~ Charger le véhicule sur la dépanneuse')
                            if IsControlJustPressed(0, Config.Act.Interact) then
                                if GetEntitySpeed(flat) > 1.0 then AJ.Notify('Arrête la dépanneuse avant de charger.')
                                else
                                    SetVehicleDoorsLocked(target, 1) SetVehicleUndriveable(target, false)
                                    AttachEntityToEntity(target, flat, GetEntityBoneIndexByName(flat, 'bodyshell'), 0.0, -2.2, 1.1, 0.0, 0.0, 0.0, false, false, true, false, 20, true)
                                    loaded = true
                                    TriggerServerEvent('aj:towing:loaded')
                                    AJ.RemoveBlip(zoneBlip)
                                    zoneBlip = AJ.Blip(scrap, 477, 2, 'Fourrière', true)
                                    AJ.SetHud({ 'DÉPANNEUR', 'Véhicule chargé', '→ Emmène-le à la fourrière' })
                                end
                            end
                        end
                    end
                else
                    sleep = 0
                    local dd = AJ.Marker(scrap, 1, 255, 190, 0)
                    if dd < 6.0 and IsPedInVehicle(ped, flat, false) then
                        AJ.Help('~INPUT_PICKUP~ Décharger le véhicule à la fourrière')
                        if IsControlJustPressed(0, Config.Act.Interact) then
                            DetachEntity(target, true, true)
                            Wait(300)
                            SetEntityAsMissionEntity(target, true, true) DeleteEntity(target) target = nil
                            TriggerServerEvent('aj:towing:done')
                            Wait(1500)
                        end
                    end
                end
                Wait(sleep)
            end
        end)
    end,
    stop = function() run = run + 1 end,
}
