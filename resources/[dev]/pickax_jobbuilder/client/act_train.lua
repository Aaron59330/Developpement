local KEY = 'train'
local run = 0
local train

local function cleanTrain()
    if train and DoesEntityExist(train) then DeleteMissionTrain(train) end
    train = nil
end

AJ.Mod[KEY] = {
    start = function(d)
        run = run + 1
        local my = run
        local s1 = d.stations[1]
        local h = AJ.LoadModel('metrotrain')
        if not h then return AJ.Notify('~r~Modèle du métro introuvable.') end
        RequestCollisionAtCoord(s1.x + 0.0, s1.y + 0.0, s1.z + 0.0)
        SetEntityCoords(PlayerPedId(), s1.x + 0.0, s1.y + 0.0, s1.z + 0.5, false, false, false, false)
        Wait(1500)
        train = CreateMissionTrain(d.variation, s1.x + 0.0, s1.y + 0.0, s1.z + 0.0, true, true, true)
        if not train or train == 0 then
            AJ.Notify('~r~Impossible de créer le métro ici : replace la station 1 sur la voie (/ajpoint train station).')
            ESX.TriggerServerCallback('aj:stop', function() end)
            return
        end
        SetModelAsNoLongerNeeded(h)
        SetMissionTrainAsNoLongerNeeded(train, false)
        SetEntityAsMissionEntity(train, true, true)
        TaskWarpPedIntoVehicle(PlayerPedId(), train, -1)
        SetTrainCruiseSpeed(train, 0.0)

        local idx, spd, dwellUntil, dwelling = 2, 0.0, 0, false
        local blip
        local function target() return d.stations[idx] end
        local function setBlip()
            AJ.RemoveBlip(blip)
            local t = target()
            if t then blip = AJ.Blip(t, 795, 38, 'Prochaine station : ' .. (t.label ~= '' and t.label or idx), true) end
        end
        setBlip()
        AJ.Notify('Maintiens ~INPUT_MOVE_UP_ONLY~ pour accélérer, ~INPUT_MOVE_DOWN_ONLY~ pour freiner, ~INPUT_JUMP~ pour le freinage d\'urgence.')

        CreateThread(function()
            local outSince
            while run == my and AJ.Active == KEY do
                Wait(0)
                local ped = PlayerPedId()
                if not train or not DoesEntityExist(train) then
                    AJ.Notify('~r~Le métro n\'existe plus : service arrêté.')
                    ESX.TriggerServerCallback('aj:stop', function() end)
                    return
                end
                if not IsPedInVehicle(ped, train, false) then
                    outSince = outSince or GetGameTimer()
                    if GetGameTimer() - outSince > 8000 then ESX.TriggerServerCallback('aj:stop', function() end) return end
                    AJ.Help('Remonte dans le métro (service arrêté dans quelques secondes).')
                else outSince = nil end

                local t = target()
                if not t then Wait(500) goto continue end
                local pos = GetEntityCoords(train)
                local dist = #(pos - vector3(t.x, t.y, t.z))
                local now = GetGameTimer()
                if dwelling then
                    spd = 0.0
                    if now >= dwellUntil then
                        dwelling = false
                        TriggerServerEvent('aj:train:stop', idx)
                        idx = idx + 1
                        if d.stations[idx] then setBlip() end
                    else
                        AJ.SetHud({ 'CONDUCTEUR', 'Station : ' .. (t.label ~= '' and t.label or idx), ('Montée des voyageurs : %d s'):format(math.ceil((dwellUntil - now) / 1000)), 'Reste à l\'arrêt' })
                    end
                else
                    if IsControlPressed(0, 71) then spd = math.min(d.maxSpeed, spd + 6.0 * GetFrameTime())
                    elseif IsControlPressed(0, 72) then spd = math.max(0.0, spd - 10.0 * GetFrameTime()) end
                    if IsControlPressed(0, 76) then spd = math.max(0.0, spd - 25.0 * GetFrameTime()) end
                    -- aide à l'arrêt : le métro ralentit automatiquement en approchant d'une station si on ne freine pas
                    local cap = dist < 120.0 and math.max(5.0, dist / 6.0) or d.maxSpeed
                    if spd > cap + 4.0 and dist < 120.0 then spd = math.max(cap, spd - 4.0 * GetFrameTime()) end
                    if dist < d.stopRadius then
                        DrawMarker(1, t.x, t.y, t.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, 0.8, 80, 220, 90, 120, false, false, 2, false, nil, nil, false)
                        if GetEntitySpeed(train) <= d.stopSpeed and spd <= d.stopSpeed then dwelling, dwellUntil = true, now + d.dwell * 1000 end
                    end
                    AJ.SetHud({ 'CONDUCTEUR', ('Prochaine : %s'):format(t.label ~= '' and t.label or idx), ('Distance : %d m'):format(math.floor(dist)), ('Vitesse : %d km/h'):format(math.floor(GetEntitySpeed(train) * 3.6)), dist < d.stopRadius + 60 and '→ Freine, arrête-toi sur le quai' or '→ Roule' })
                end
                SetTrainCruiseSpeed(train, spd)
                ::continue::
            end
        end)
    end,
    stop = function()
        run = run + 1
        local ped = PlayerPedId()
        if train and DoesEntityExist(train) then
            TaskLeaveVehicle(ped, train, 16)
            Wait(500)
        end
        cleanTrain()
        local dep = AJ.Points_(KEY, 'depot')[1]
        if dep then SetEntityCoords(PlayerPedId(), dep.x + 0.0, dep.y + 0.0, dep.z + 0.0, false, false, false, false) end
    end,
}
