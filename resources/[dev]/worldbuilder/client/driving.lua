-- ─────────────────────────────── Auto-école (client) ───────────────────────────────
Handlers.driving = function(node)
    if node.kind ~= 'desk' then return end
    ServerCall('worldbuilder:driving:info', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Auto-école indisponible', 'error') end
        res.eid, res.pi = node.eid, node.pi
        OpenPanel('driving', res, { type = 'driving', eid = node.eid, pi = node.pi })
    end, node.eid, node.pi)
end

local function drawHud(text)
    SetTextFont(4) SetTextScale(0.0, 0.45) SetTextColour(255, 255, 255, 230) SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.5, 0.90)
end

local function runExam(res, entity)
    local spawn = res.spawn
    local veh = SpawnVehicleAt(spawn, res.model, nil, res.plate)
    if not veh then
        TriggerServerEvent('worldbuilder:server:drivingFinish', false, 99, 'véhicule introuvable')
        return Notify('Impossible de faire apparaître le véhicule d\'examen.', 'error')
    end
    Notify(('Examen « %s » : suis les points sur la route. Limite : %d km/h. Fautes max : %d. Touche X pour abandonner.'):format(res.label, res.speedLimit, res.maxFaults), 'info')
    local faults, idx, blip = 0, 1, nil
    local outSince, lastSpeed, lastBody, success, reason = nil, 0, GetVehicleBodyHealth(veh), false, ''
    local function setBlip(c)
        if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
        blip = AddBlipForCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
        SetBlipSprite(blip, 1) SetBlipColour(blip, 5) SetBlipRoute(blip, true)
    end
    setBlip(res.route[1])
    local function fault(why)
        faults = faults + 1
        Notify(('Faute : %s (%d/%d)'):format(why, faults, res.maxFaults), 'error')
    end
    while true do
        Wait(0)
        local ped = PlayerPedId()
        if not DoesEntityExist(veh) or IsEntityDead(ped) or GetEntityHealth(veh) <= 0 then reason = 'véhicule détruit' break end
        if GetVehiclePedIsIn(ped, false) ~= veh then
            outSince = outSince or GetGameTimer()
            if GetGameTimer() - outSince > 15000 then reason = 'tu as quitté le véhicule' break end
            drawHud('Remonte dans le véhicule d\'examen !')
        else
            outSince = nil
            local cp = res.route[idx]
            local pos = GetEntityCoords(veh)
            DrawMarker(1, cp.x + 0.0, cp.y + 0.0, cp.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.0, 4.0, 2.0, 255, 200, 0, 140, false, false, 2, false, nil, nil, false)
            if #(pos - vector3(cp.x, cp.y, cp.z)) < 5.0 then
                idx = idx + 1
                if idx > #res.route then success = true break end
                setBlip(res.route[idx])
                PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
            end
            local kmh = math.floor(GetEntitySpeed(veh) * 3.6 + 0.5)
            if kmh > res.speedLimit + 5 and GetGameTimer() - lastSpeed > 5000 then lastSpeed = GetGameTimer() fault(('excès de vitesse (%d km/h)'):format(kmh)) end
            local body = GetVehicleBodyHealth(veh)
            if lastBody - body >= 40 then fault('collision') end
            lastBody = body
            drawHud(('EXAMEN — point %d/%d — %d km/h (limite %d) — fautes %d/%d'):format(idx, #res.route, kmh, res.speedLimit, faults, res.maxFaults))
        end
        if faults > res.maxFaults then reason = 'trop de fautes' break end
        if IsControlJustPressed(0, Config.CancelKey or 73) then reason = 'abandon' break end
    end
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
    TriggerServerEvent('worldbuilder:server:drivingFinish', success, faults, reason)
    local ped = PlayerPedId()
    if DoesEntityExist(veh) then
        TaskLeaveVehicle(ped, veh, 0)
        Wait(1500)
        DeleteEntity(veh)
    end
end

NuiLocal['driving:practicalStart'] = function(args, cb)
    local ctx = Ctx
    local e = ctx and EntityById(ctx.eid)
    if not e then return cb({ ok = false, error = 'Fermé' }) end
    local chosen
    for _, p in ipairs(e.points) do
        if p.kind == 'spawn' and not IsAnyVehicleNearPoint(p.coords.x + 0.0, p.coords.y + 0.0, p.coords.z + 0.0, 2.5) then chosen = p break end
    end
    if not chosen then return cb({ ok = false, error = 'Aucun point de départ libre' }) end
    ESX.TriggerServerCallback('worldbuilder:driving:practicalStart', function(res)
        if not res or not res.ok then return cb(res or { ok = false, error = 'Erreur' }) end
        cb({ ok = true })
        CloseUI()
        CreateThread(function() runExam(res, e) end)
    end, ctx.eid, ctx.pi, args[1], chosen.i, args[2])
end

-- Rafraîchit la liste des permis (après un examen de code)
NuiLocal['driving:info'] = function(_, cb)
    local ctx = Ctx
    if not ctx or ctx.type ~= 'driving' then return cb({ ok = false }) end
    ServerCall('worldbuilder:driving:info', function(res) cb(res or { ok = false }) end, ctx.eid, ctx.pi)
end
