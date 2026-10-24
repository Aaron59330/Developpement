local KEY = 'garbage'
local run = 0

AJ.Mod[KEY] = {
    start = function(d)
        run = run + 1
        local my = run
        local truck = AJ.SpawnVehicle(d.vehicle, d.spawn, d.plate)
        local collected, total, carrying, carryObj = 0, d.total, false, nil
        local bags = {}
        local depot = AJ.Points_(KEY, 'depot')[1]

        -- les sacs sont placés au bord des routes de la zone, puis créés quand on s'en approche
        local ped = PlayerPedId()
        CreateThread(function()
            local made = 0
            local tries = 0
            while made < total and tries < 400 and run == my do
                tries = tries + 1
                local a, r = math.random() * 6.2831, 25.0 + math.random() * (d.radius - 25.0)
                local x, y = d.zone.x + math.cos(a) * r, d.zone.y + math.sin(a) * r
                local found, node = GetClosestVehicleNode(x, y, 40.0, 1, 3.0, 0)
                if found then
                    bags[#bags + 1] = { x = node.x + 2.6, y = node.y + 1.0, z = node.z, taken = false }
                    made = made + 1
                end
                Wait(0)
            end
            -- si la zone n'est pas encore streamée on complète autour du joueur
            while made < total and run == my do
                local p = GetEntityCoords(PlayerPedId())
                local found, node = GetClosestVehicleNode(p.x + math.random(-120, 120), p.y + math.random(-120, 120), p.z, 1, 3.0, 0)
                if found then bags[#bags + 1] = { x = node.x + 2.6, y = node.y + 1.0, z = node.z, taken = false } made = made + 1 end
                Wait(50)
            end
            for _, b in ipairs(bags) do b.blip = AJ.Blip(b, 1, 5, 'Sac poubelle', false) SetBlipScale(b.blip, 0.5) end
        end)
        AJ.Blip(d.zone, 318, 5, 'Zone de ramassage', true)

        local function hud()
            local done = collected >= total
            AJ.SetHud({ 'ÉBOUEUR', ('Sacs : %d / %d'):format(collected, total), done and '→ Retourne au centre de tri' or (carrying and '→ Jette le sac dans le camion' or '→ Ramasse les sacs (blips jaunes)') })
        end
        hud()

        CreateThread(function()
            local wasDone = false
            while run == my and AJ.Active == KEY do
                local sleep = 500
                ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                if not truck or not DoesEntityExist(truck) then
                    AJ.Notify('~r~Ton camion a été détruit : tournée annulée.')
                    ESX.TriggerServerCallback('aj:stop', function() end)
                    return
                end
                -- création / suppression des sacs selon la distance
                for _, b in ipairs(bags) do
                    if not b.taken then
                        local dist = #(pos - vector3(b.x, b.y, b.z))
                        if dist < 110.0 and not b.obj then
                            local h = AJ.LoadModel('prop_cs_rub_binbag_01')
                            if h then
                                b.obj = CreateObject(h, b.x, b.y, b.z, false, false, false)
                                PlaceObjectOnGroundProperly(b.obj) FreezeEntityPosition(b.obj, true)
                                SetModelAsNoLongerNeeded(h)
                            end
                        elseif dist >= 140.0 and b.obj then DeleteEntity(b.obj) b.obj = nil end
                        if dist < 25.0 then sleep = 0 end
                        if not carrying and dist < 1.8 and not IsPedInAnyVehicle(ped, false) then
                            AJ.Help('~INPUT_PICKUP~ Ramasser le sac poubelle')
                            if IsControlJustPressed(0, Config.Interact) then
                                if AJ.Progress('Ramassage', 1.2, { dict = 'anim@heists@narcotics@trash', clip = 'pickup' }) then
                                    b.taken = true
                                    if b.obj then DeleteEntity(b.obj) b.obj = nil end
                                    AJ.RemoveBlip(b.blip)
                                    local h = AJ.LoadModel('prop_cs_rub_binbag_01')
                                    carryObj = CreateObject(h, 0.0, 0.0, 0.0, false, false, false)
                                    AttachEntityToEntity(carryObj, ped, GetPedBoneIndex(ped, 57005), 0.12, 0.0, -0.04, 10.0, 270.0, 0.0, true, true, false, true, 1, true)
                                    carrying = true
                                    RequestAnimDict('anim@heists@narcotics@trash')
                                    while not HasAnimDictLoaded('anim@heists@narcotics@trash') do Wait(10) end
                                    TaskPlayAnim(ped, 'anim@heists@narcotics@trash', 'walk', 4.0, 4.0, -1, 49, 0.0, false, false, false)
                                    hud()
                                end
                            end
                        end
                    end
                end
                -- jeter dans le camion
                if carrying then
                    sleep = 0
                    DisableControlAction(0, 23, true)
                    local rear = GetOffsetFromEntityInWorldCoords(truck, 0.0, -4.4, 0.0)
                    if #(pos - rear) < 2.4 then
                        AJ.Help('~INPUT_PICKUP~ Jeter le sac dans le camion')
                        if IsControlJustPressed(0, Config.Interact) then
                            RequestAnimDict('anim@heists@narcotics@trash')
                            TaskPlayAnim(ped, 'anim@heists@narcotics@trash', 'throw_b', 4.0, 4.0, 1200, 48, 0.0, false, false, false)
                            Wait(900)
                            if carryObj then DeleteEntity(carryObj) carryObj = nil end
                            ClearPedTasks(ped)
                            carrying = false
                            collected = collected + 1
                            TriggerServerEvent('aj:garbage:bag')
                            hud()
                        end
                    end
                end
                -- retour au dépôt
                if collected >= total and depot then
                    if not wasDone then wasDone = true AJ.Blip(depot, 318, 2, 'Centre de tri', true) end
                    sleep = 0
                    local dd = AJ.Marker(depot, 1, 255, 190, 0)
                    if dd < 6.0 and IsPedInVehicle(ped, truck, false) then
                        AJ.Help('~INPUT_PICKUP~ Terminer la tournée')
                        if IsControlJustPressed(0, Config.Interact) then TriggerServerEvent('aj:garbage:finish') Wait(1500) end
                    end
                end
                Wait(sleep)
            end
        end)

        -- terminer plus tôt avec ce qui a été ramassé
        CreateThread(function()
            while run == my and AJ.Active == KEY do
                if depot and collected > 0 and collected < total then
                    local ped2 = PlayerPedId()
                    if #(GetEntityCoords(ped2) - vector3(depot.x, depot.y, depot.z)) < 6.0 and IsPedInVehicle(ped2, truck, false) then
                        AJ.Help('~INPUT_PICKUP~ Rendre le camion (tournée incomplète, pas de prime)')
                        if IsControlJustPressed(0, Config.Interact) then TriggerServerEvent('aj:garbage:finish') Wait(1500) end
                    end
                    Wait(0)
                else Wait(700) end
            end
        end)
        AJ.Mod[KEY].cleanup = function()
            for _, b in ipairs(bags) do if b.obj and DoesEntityExist(b.obj) then DeleteEntity(b.obj) end end
            if carryObj and DoesEntityExist(carryObj) then DeleteEntity(carryObj) end
            ClearPedTasks(PlayerPedId())
        end
    end,
    stop = function()
        run = run + 1
        if AJ.Mod[KEY].cleanup then AJ.Mod[KEY].cleanup() AJ.Mod[KEY].cleanup = nil end
    end,
}
