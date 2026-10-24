local KEY = 'trucker'
local run = 0

AJ.Mod[KEY] = {
    start = function(d)
        run = run + 1
        local my = run
        local truck = AJ.SpawnVehicle(d.truck, d.spawn, d.plate)
        local trailer
        local th = AJ.LoadModel(d.trailer)
        if truck and th then
            local c = GetOffsetFromEntityInWorldCoords(truck, 0.0, -7.5, 0.0)
            trailer = CreateVehicle(th, c.x, c.y, c.z, GetEntityHeading(truck), true, true)
            SetModelAsNoLongerNeeded(th)
            SetEntityAsMissionEntity(trailer, true, true)
            AJ.Ents[#AJ.Ents + 1] = trailer
            Wait(300)
            AttachVehicleToTrailer(truck, trailer, 1.0)
        end
        local depot = AJ.Points_(KEY, 'depot')[1]
        local delivered = false
        local t0 = GetGameTimer()
        AJ.Blip(d.dest, 477, 5, 'Livraison : ' .. (d.dest.label or ''), true)

        CreateThread(function()
            while run == my and AJ.Active == KEY do
                local sleep = 500
                local ped = PlayerPedId()
                if not truck or not DoesEntityExist(truck) or not trailer or not DoesEntityExist(trailer) then
                    AJ.Notify('~r~Camion ou remorque détruit : mission annulée.')
                    ESX.TriggerServerCallback('aj:stop', function() end)
                    return
                end
                local left = math.max(0, d.limit - math.floor((GetGameTimer() - t0) / 1000))
                local hp = math.floor(GetEntityHealth(trailer) / math.max(1, GetEntityMaxHealth(trailer)) * 100)
                if not delivered then
                    AJ.SetHud({ 'CAMIONNEUR', ('Destination : %s (%.1f km)'):format(d.dest.label or '?', d.km), ('Temps restant : %d:%02d'):format(left // 60, left % 60), ('Cargaison : %d%%'):format(hp) })
                    sleep = 0
                    local dd = AJ.Marker(d.dest, 1, 255, 190, 0)
                    if dd < 12.0 and IsPedInVehicle(ped, truck, false) then
                        AJ.Help('~INPUT_PICKUP~ Livrer la cargaison')
                        if IsControlJustPressed(0, Config.Act.Interact) then
                            if IsVehicleAttachedToTrailer(truck) then
                                if AJ.Progress('Déchargement de la cargaison', 6, { radius = 15.0 }) then
                                    TriggerServerEvent('aj:trucker:deliver', GetEntityHealth(trailer) / math.max(1, GetEntityMaxHealth(trailer)))
                                end
                            else AJ.Notify('~r~Ta remorque n\'est pas attelée.') end
                        end
                    end
                else
                    AJ.SetHud({ 'CAMIONNEUR', 'Livraison effectuée', '→ Ramène le camion au dépôt (prime)' })
                    sleep = 0
                    if depot then
                        local dd = AJ.Marker(depot, 1, 0, 200, 90)
                        if dd < 12.0 and IsPedInVehicle(ped, truck, false) then
                            AJ.Help('~INPUT_PICKUP~ Rendre le camion')
                            if IsControlJustPressed(0, Config.Act.Interact) then TriggerServerEvent('aj:trucker:return') Wait(1500) end
                        end
                    end
                end
                Wait(sleep)
            end
        end)

        RegisterNetEvent('aj:trucker:delivered', function()
            if run ~= my then return end
            delivered = true
            for _, b in ipairs(AJ.Blips) do AJ.RemoveBlip(b) end
            AJ.Blips = {}
            if depot then AJ.Blip(depot, 477, 2, 'Dépôt de transport', true) end
            if trailer and DoesEntityExist(trailer) then DetachVehicleFromTrailer(truck) end
        end)
    end,
    stop = function() run = run + 1 end,
}
