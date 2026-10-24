local KEY = 'carwash'
local run = 0

AJ.Mod[KEY] = {
    start = function(d)
        run = run + 1
        local my = run
        local cars = {}        -- id → { veh, driver, spots, left }
        local washed, asked = 0, 0

        AJ.SetHud({ 'LAVEUR AUTO', 'Clients lavés : 0', '→ Attends un client dans une baie' })

        RegisterNetEvent('aj:carwash:customer', function(c)
            if run ~= my then return end
            local bay = d.bays[c.bay]
            local h = AJ.LoadModel(c.model)
            if not bay or not h then return end
            local veh = CreateVehicle(h, bay.x, bay.y, bay.z, bay.h + 0.0, true, true)
            SetModelAsNoLongerNeeded(h)
            SetVehicleDirtLevel(veh, 14.5) SetVehicleDoorsLocked(veh, 2) SetVehicleOnGroundProperly(veh)
            SetEntityAsMissionEntity(veh, true, true)
            AJ.Ents[#AJ.Ents + 1] = veh
            -- le client est au volant puis descend et s'écarte
            local pedHash = AJ.LoadModel('a_m_y_business_02')
            local drv
            if pedHash then
                drv = CreatePedInsideVehicle(veh, 4, pedHash, -1, true, false)
                SetModelAsNoLongerNeeded(pedHash)
                SetBlockingOfNonTemporaryEvents(drv, true)
            end
            cars[c.id] = { veh = veh, drv = drv, parts = { false, false, false, false }, bay = bay, t = GetGameTimer() }
            local b = AJ.Blip(bay, 100, 3, 'Voiture à laver', false)
            cars[c.id].blip = b
            AJ.Notify('Un client attend dans une baie : lave sa voiture.')
            SetTimeout(2500, function()
                if drv and DoesEntityExist(drv) then
                    TaskLeaveVehicle(drv, veh, 0)
                    SetTimeout(2500, function() if DoesEntityExist(drv) then TaskWanderStandard(drv, 10.0, 10) end end)
                end
            end)
        end)

        -- demande de clients à intervalles réguliers
        CreateThread(function()
            while run == my and AJ.Active == KEY do
                TriggerServerEvent('aj:carwash:request')
                Wait(Config.Jobs[KEY].interval * 1000 * 0.8)
            end
        end)

        local labels = { 'avant', 'côté gauche', 'arrière', 'côté droit' }
        local offs = { { 0.0, 3.0 }, { -1.9, 0.0 }, { 0.0, -3.0 }, { 1.9, 0.0 } }
        CreateThread(function()
            while run == my and AJ.Active == KEY do
                local sleep = 600
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                for id, c in pairs(cars) do
                    if not DoesEntityExist(c.veh) then cars[id] = nil
                    else
                        local left = 0
                        for i = 1, 4 do
                            if not c.parts[i] then
                                left = left + 1
                                local p = GetOffsetFromEntityInWorldCoords(c.veh, offs[i][1], offs[i][2], 0.0)
                                local dist = #(pos - p)
                                if dist < 12.0 then
                                    sleep = 0
                                    DrawMarker(1, p.x, p.y, p.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.5, 0, 164, 255, 110, false, false, 2, false, nil, nil, false)
                                    if dist < 1.4 then
                                        AJ.Help(('~INPUT_PICKUP~ Laver ' .. labels[i]))
                                        if IsControlJustPressed(0, Config.Interact) then
                                            local secs = Config.Jobs[KEY].washSeconds / 4
                                            if AJ.Progress('Lavage — ' .. labels[i], secs, { dict = 'timetable@floyd@clean_kitchen@base', clip = 'base', radius = 3.0 }) then
                                                c.parts[i] = true
                                                SetVehicleDirtLevel(c.veh, math.max(0.0, GetVehicleDirtLevel(c.veh) - 3.6))
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        if left == 0 or (c.parts[1] and c.parts[2] and c.parts[3] and c.parts[4]) then
                            SetVehicleDirtLevel(c.veh, 0.0)
                            washed = washed + 1
                            TriggerServerEvent('aj:carwash:done', id)
                            AJ.RemoveBlip(c.blip)
                            -- la voiture est rendue au client
                            local veh, drv = c.veh, c.drv
                            cars[id] = nil
                            SetVehicleDoorsLocked(veh, 1)
                            AJ.SetHud({ 'LAVEUR AUTO', 'Clients lavés : ' .. washed, '→ Attends le prochain client' })
                            SetTimeout(3000, function()
                                if DoesEntityExist(veh) then
                                    if drv and DoesEntityExist(drv) then
                                        SetPedIntoVehicle(drv, veh, -1)
                                        TaskVehicleDriveWander(drv, veh, 18.0, 786603)
                                    end
                                    SetTimeout(30000, function()
                                        if DoesEntityExist(veh) then SetEntityAsMissionEntity(veh, true, true) DeleteEntity(veh) end
                                        if drv and DoesEntityExist(drv) then DeleteEntity(drv) end
                                    end)
                                end
                            end)
                        end
                    end
                end
                Wait(sleep)
            end
        end)
    end,
    stop = function() run = run + 1 end,
}
