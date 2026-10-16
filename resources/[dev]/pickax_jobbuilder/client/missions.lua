-- ─────────────────────────────── Missions PNJ (client) ───────────────────────────────
-- Exécute les étapes décidées par le serveur : véhicule à livrer, trajet, PNJ à rencontrer, travail avec animation,
-- course de taxi... Le serveur vérifie la position du joueur à chaque étape.

NuiRemote['missions:status'] = true

local M = nil   -- mission en cours

local function srv(name, ...)
    local p = promise.new()
    ESX.TriggerServerCallback('jobbuilder:missions:' .. name, function(r) p:resolve(r) end, ...)
    return Citizen.Await(p)
end

-- ─────────────────────────────── Utilitaires ───────────────────────────────
local function text(x, y, str, scale, r, g, b)
    SetTextFont(4) SetTextScale(0.0, scale) SetTextColour(r or 255, g or 255, b or 255, 235) SetTextCentre(true) SetTextOutline()
    BeginTextCommandDisplayText('STRING') AddTextComponentSubstringPlayerName(str) EndTextCommandDisplayText(x, y)
end

local function requestModel(model)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 6000 do Wait(20) end
    return HasModelLoaded(hash) and hash or nil
end

local function groundZ(loc)
    RequestCollisionAtCoord(loc.x + 0.0, loc.y + 0.0, loc.z + 0.0)
    for _ = 1, 25 do
        local ok, z = GetGroundZFor_3dCoord(loc.x + 0.0, loc.y + 0.0, loc.z + 60.0, false)
        if ok then return z end
        Wait(40)
    end
    return loc.z
end

-- Marker des étapes de mission : même apparence de base que les points « Missions PNJ » (type et couleur réglables dans Paramètres)
local function stepMarker(c, size, height)
    local t = Config.PointTypes.missions or {}
    DrawJBMarker({ marker = t.marker or 25, color = t.color or { 64, 224, 208 }, alpha = 150, scale = { x = size, y = size, z = height }, offset = -1.0 }, c)
end

local function dist(loc) return #(GetEntityCoords(PlayerPedId()) - vector3(loc.x, loc.y, loc.z)) end
local function dist2(loc) local p = GetEntityCoords(PlayerPedId()) return #(vector2(p.x, p.y) - vector2(loc.x, loc.y)) end

local function setBlip(loc, label, entity)
    if M.blip and DoesBlipExist(M.blip) then RemoveBlip(M.blip) end
    M.blip = entity and AddBlipForEntity(entity) or AddBlipForCoord(loc.x + 0.0, loc.y + 0.0, loc.z + 0.0)
    SetBlipSprite(M.blip, entity and 225 or 1)
    SetBlipColour(M.blip, 5)
    SetBlipScale(M.blip, 0.9)
    if not entity then SetBlipRoute(M.blip, true) SetBlipRouteColour(M.blip, 5) end
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label or 'Mission')
    EndTextCommandSetBlipName(M.blip)
end

local function clearBlip()
    if M and M.blip and DoesBlipExist(M.blip) then RemoveBlip(M.blip) end
    if M then M.blip = nil end
end

local function aborted(mid) return not M or M.id ~= mid or M.cancel or IsEntityDead(PlayerPedId()) end

-- HUD : titre, étape, chronomètre
local function hud(step)
    text(0.5, 0.905, M.label, 0.42, 251, 191, 36)
    text(0.5, 0.932, ('%d/%d — %s'):format(M.idx, #M.steps, step.label ~= '' and step.label or 'Étape'), 0.38)
    if M.timeLimit and M.timeLimit > 0 then
        local left = M.timeLimit - math.floor((GetGameTimer() - M.started) / 1000)
        local m, s = math.floor(math.abs(left) / 60), math.abs(left) % 60
        text(0.5, 0.956, ('%s%d:%02d'):format(left < 0 and '+' or '', m, s), 0.34, left < 0 and 248 or 255, left < 0 and 113 or 255, left < 0 and 113 or 255)
    end
end

-- ─────────────────────────────── Entités ───────────────────────────────
local function spawnVehicle(model, loc, broken)
    local hash = requestModel(model)
    if not hash then return nil end
    local z = groundZ(loc)
    local veh = CreateVehicle(hash, loc.x + 0.0, loc.y + 0.0, z + 0.0, (loc.h or 0.0) + 0.0, true, false)
    SetModelAsNoLongerNeeded(hash)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    SetVehicleFuelLevel(veh, 100.0)
    SetVehicleNumberPlateText(veh, ('JB%06d'):format(math.random(0, 999999)))
    if broken then
        SetVehicleEngineHealth(veh, 250.0)
        SetVehicleBodyHealth(veh, 600.0)
        SetVehicleDoorOpen(veh, 4, false, false)
        SetVehicleUndriveable(veh, true)
    else
        Config.OnVehicleSpawned(veh, GetVehicleNumberPlateText(veh))
    end
    M.vehicles[#M.vehicles + 1] = veh
    return veh
end

local function spawnPed(loc, patient)
    local model = M.peds[math.random(#M.peds)]
    local hash = requestModel(model)
    if not hash then return nil end
    local z = groundZ(loc)
    local ped = CreatePed(4, hash, loc.x + 1.2, loc.y + 0.0, z + 0.0, (loc.h or 0.0) + 0.0, false, true)
    SetModelAsNoLongerNeeded(hash)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetEntityInvincible(ped, true)
    if patient then
        RequestAnimDict('combat@damage@writhe')
        while not HasAnimDictLoaded('combat@damage@writhe') do Wait(10) end
        TaskPlayAnim(ped, 'combat@damage@writhe', 'writhe_loop', 8.0, -8.0, -1, 1, 0.0, false, false, false)
    else
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
    end
    M.peds_spawned[#M.peds_spawned + 1] = ped
    return ped
end

local function cleanup(delay)
    if not M then return end
    local m = M
    M = nil
    if m.blip and DoesBlipExist(m.blip) then RemoveBlip(m.blip) end
    CreateThread(function()
        if delay then Wait(delay) end
        local ped = PlayerPedId()
        for _, v in ipairs(m.vehicles) do
            if DoesEntityExist(v) then
                if GetVehiclePedIsIn(ped, false) == v then TaskLeaveVehicle(ped, v, 0) Wait(900) end
                SetEntityAsMissionEntity(v, true, true)
                DeleteEntity(v)
            end
        end
        for _, n in ipairs(m.peds_spawned) do if DoesEntityExist(n) then SetEntityAsMissionEntity(n, true, true) DeleteEntity(n) end end
    end)
end

-- ─────────────────────────────── Animations d'interaction ───────────────────────────────
local SCENARIOS = { work = 'WORLD_HUMAN_HAMMERING', repair = 'WORLD_HUMAN_VEHICLE_MECHANIC', heal = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', inspect = 'WORLD_HUMAN_CLIPBOARD', talk = 'WORLD_HUMAN_STAND_IMPATIENT' }

-- Retourne true si l'action est menée à son terme
local function progress(step, mid)
    local ped = PlayerPedId()
    local start = GetEntityCoords(ped)
    if step.anim == 'give' then
        RequestAnimDict('mp_common')
        while not HasAnimDictLoaded('mp_common') do Wait(10) end
        TaskPlayAnim(ped, 'mp_common', 'givetake1_a', 8.0, -8.0, step.secs * 1000, 49, 0.0, false, false, false)
    else
        TaskStartScenarioInPlace(ped, SCENARIOS[step.anim] or SCENARIOS.talk, 0, true)
    end
    local t0, total = GetGameTimer(), step.secs * 1000
    while true do
        local el = GetGameTimer() - t0
        if el >= total then break end
        if aborted(mid) or #(GetEntityCoords(ped) - start) > 3.5 or IsPedInAnyVehicle(ped, false) then
            ClearPedTasks(ped)
            return false
        end
        DrawRect(0.5, 0.875, 0.18, 0.014, 0, 0, 0, 190)
        DrawRect(0.5 - 0.09 + 0.09 * (el / total), 0.875, 0.18 * (el / total), 0.014, 255, 255, 255, 235)
        hud(step)
        Wait(0)
    end
    ClearPedTasks(ped)
    return true
end

-- ─────────────────────────────── Étapes ───────────────────────────────
local function stepSpawnVehicle(step, mid)
    local ped = PlayerPedId()
    if step.where == 'start' then
        clearBlip()
        local veh = spawnVehicle(M.vehicleInfo.model, step.loc, false)
        if not veh then M.error = 'Modèle de véhicule introuvable : ' .. tostring(M.vehicleInfo.model) return false end
        M.vehicle = veh
        setBlip(step.loc, M.vehicleInfo.label, veh)
        while not aborted(mid) do
            if GetVehiclePedIsIn(ped, false) == veh then clearBlip() return true end
            hud(step)
            ESX.ShowHelpNotification(('Monte dans le véhicule : ~b~%s'):format(M.vehicleInfo.label or ''))
            Wait(0)
        end
        return false
    end
    -- véhicule en panne : on le fait apparaître à l'approche
    setBlip(step.loc, step.label)
    while not aborted(mid) do
        if dist2(step.loc) < 180.0 then break end
        hud(step)
        Wait(200)
    end
    if aborted(mid) then return false end
    local veh = spawnVehicle(M.vehicleInfo.model, step.loc, step.broken)
    if not veh then M.error = 'Modèle de véhicule introuvable : ' .. tostring(M.vehicleInfo.model) return false end
    M.target = veh
    return true
end

local function stepGoto(step, mid)
    local ped = PlayerPedId()
    setBlip(step.loc, step.label)
    local c = step.loc
    while not aborted(mid) do
        local d = dist(c)
        if step.veh and (not M.vehicle or not DoesEntityExist(M.vehicle) or IsEntityDead(M.vehicle)) then M.error = 'Le véhicule de mission a été détruit.' return false end
        if d < 150.0 then stepMarker(c, 6.0, 1.2) end
        if d < (step.veh and 12.0 or 7.0) then
            if not step.veh or GetVehiclePedIsIn(ped, false) == M.vehicle then clearBlip() return true end
            ESX.ShowHelpNotification('Remonte dans le véhicule de mission.')
        end
        hud(step)
        Wait(0)
    end
    return false
end

local function stepInteract(step, mid)
    local ped = PlayerPedId()
    local c = step.loc
    setBlip(c, step.label)
    -- PNJ : réutilisé s'il est déjà au même endroit, sinon créé à l'approche
    local npc = M.npc
    if step.npc ~= false and not (npc and DoesEntityExist(npc) and M.npcLoc and M.npcLoc.x == c.x and M.npcLoc.y == c.y) then
        while not aborted(mid) and dist2(c) > 130.0 do hud(step) Wait(200) end
        if aborted(mid) then return false end
        npc = spawnPed(c, step.patient)
        M.npc, M.npcLoc = npc, c
        if npc and step.patient then FreezeEntityPosition(npc, true) end
    end
    while not aborted(mid) do
        local d = dist(c)
        if d < 60.0 then stepMarker(c, 1.2, 0.6) end
        if d < 2.8 then
            if IsPedInAnyVehicle(ped, false) then
                ESX.ShowHelpNotification('Descends du véhicule.')
            else
                ESX.ShowHelpNotification(('~INPUT_CONTEXT~ %s'):format(step.label ~= '' and step.label or 'Interagir'))
                if IsControlJustReleased(0, 38) then
                    if progress(step, mid) then
                        if step.consume and M.vehicle and DoesEntityExist(M.vehicle) then
                            M.health = GetVehicleBodyHealth(M.vehicle)
                            SetEntityAsMissionEntity(M.vehicle, true, true)
                            DeleteEntity(M.vehicle)
                            M.vehicle = nil
                        end
                        if step.t == 'interact' and step.anim == 'repair' and M.target and DoesEntityExist(M.target) then
                            SetVehicleFixed(M.target) SetVehicleDeformationFixed(M.target) SetVehicleEngineHealth(M.target, 1000.0) SetVehicleUndriveable(M.target, false)
                        end
                        if npc and DoesEntityExist(npc) then
                            FreezeEntityPosition(npc, false)
                            ClearPedTasks(npc)
                            TaskWanderStandard(npc, 10.0, 10)
                        end
                        clearBlip()
                        return true
                    end
                    if not aborted(mid) then JBNotify('~r~Action interrompue : reste sur place jusqu\'à la fin.') end
                end
            end
        end
        hud(step)
        Wait(0)
    end
    return false
end

local function stepPickupNpc(step, mid)
    local ped = PlayerPedId()
    local c = step.loc
    setBlip(c, step.label)
    while not aborted(mid) and dist2(c) > 130.0 do hud(step) Wait(200) end
    if aborted(mid) then return false end
    local npc = spawnPed(c, false)
    if not npc then M.error = 'Modèle de PNJ introuvable' return false end
    M.npc, M.npcLoc = npc, c
    while not aborted(mid) do
        local veh = GetVehiclePedIsIn(ped, false)
        local d = dist(c)
        if d < 150.0 then stepMarker(c, 4.0, 1.0) end
        if d < 12.0 then
            if veh == 0 then
                ESX.ShowHelpNotification('Monte dans un véhicule pour prendre le client.')
            elseif GetEntitySpeed(veh) > 3.0 then
                ESX.ShowHelpNotification('Arrête-toi près du client.')
            else
                M.vehicle = veh
                clearBlip()
                FreezeEntityPosition(npc, false)
                ClearPedTasksImmediately(npc)
                TaskEnterVehicle(npc, veh, 12000, 2, 1.0, 1, 0)
                local t = GetGameTimer()
                while not aborted(mid) and not IsPedInVehicle(npc, veh, false) and GetGameTimer() - t < 14000 do hud(step) Wait(100) end
                if not IsPedInVehicle(npc, veh, false) then SetPedIntoVehicle(npc, veh, 2) end
                return not aborted(mid)
            end
        end
        hud(step)
        Wait(0)
    end
    return false
end

local function stepDropoffNpc(step, mid)
    local ped = PlayerPedId()
    local c = step.loc
    setBlip(c, step.label)
    while not aborted(mid) do
        local veh = GetVehiclePedIsIn(ped, false)
        local d = dist(c)
        if not M.npc or not DoesEntityExist(M.npc) then M.error = 'Le client a disparu.' return false end
        if d < 150.0 then stepMarker(c, 4.0, 1.0) end
        if d < 12.0 and veh ~= 0 and GetEntitySpeed(veh) < 4.0 then
            clearBlip()
            TaskLeaveVehicle(M.npc, veh, 0)
            local t = GetGameTimer()
            while not aborted(mid) and IsPedInVehicle(M.npc, veh, false) and GetGameTimer() - t < 8000 do hud(step) Wait(100) end
            TaskWanderStandard(M.npc, 10.0, 10)
            return not aborted(mid)
        elseif d < 12.0 then
            ESX.ShowHelpNotification('Arrête-toi pour déposer le client.')
        end
        hud(step)
        Wait(0)
    end
    return false
end

local HANDLERS = { spawn_vehicle = stepSpawnVehicle, ['goto'] = stepGoto, interact = stepInteract, pickup_npc = stepPickupNpc, dropoff_npc = stepDropoffNpc }

-- ─────────────────────────────── Boucle principale ───────────────────────────────
local function run(mid)
    while M and M.id == mid do
        local step = M.steps[M.idx]
        if not step then break end
        local handler = HANDLERS[step.t]
        local ok = handler and handler(step, mid)
        if not M or M.id ~= mid then return end
        if M.cancel then return end
        if not ok then
            local msg = M.error or (IsEntityDead(PlayerPedId()) and 'Mission échouée : tu es mort.' or 'Mission annulée.')
            srv('cancel')
            cleanup(0)
            JBNotify('~r~' .. msg)
            return
        end
        local r = srv('step', mid, M.idx)
        if not r or not r.ok then
            srv('cancel')
            cleanup(0)
            JBNotify('~r~' .. ((r and r.error) or 'Étape refusée par le serveur.'))
            return
        end
        M.idx = M.idx + 1
    end
    if not M or M.id ~= mid then return end
    local health = M.health
    if not health and M.vehicle and DoesEntityExist(M.vehicle) then health = GetVehicleBodyHealth(M.vehicle) end
    local r = srv('complete', mid, health)
    if r and r.ok then
        PlaySoundFrontend(-1, 'Mission_Pass_Notify', 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', true)
        JBNotify(('~g~Mission terminée !~s~ %s~n~Récompense : ~g~+%d$%s'):format(M.label, r.reward or 0, (r.bonus and r.bonus > 0) and (' ~s~(dont bonus ~y~+' .. r.bonus .. '$~s~)') or ''))
        if r.note then JBNotify('~y~' .. r.note) end
    else
        JBNotify('~r~' .. ((r and r.error) or 'Mission non validée.'))
    end
    cleanup(2500)
end

function StartMission(m)
    if M then return JBNotify('~r~Tu as déjà une mission en cours.') end
    M = {
        id = m.id, label = m.label, steps = m.steps, idx = 1, vehicleInfo = m.vehicle, peds = (m.peds and #m.peds > 0) and m.peds or { 'a_m_y_business_01' },
        timeLimit = m.timeLimit, started = GetGameTimer(), vehicles = {}, peds_spawned = {},
    }
    JBNotify(('~y~Mission : ~s~%s'):format(m.label))
    CreateThread(function() run(m.id) end)
end

function CancelMission(msg)
    if not M then return end
    M.cancel = true
    ESX.TriggerServerCallback('jobbuilder:missions:cancel', function() end)
    cleanup(0)
    JBNotify(msg or '~y~Mission annulée.')
end

RegisterNetEvent('jobbuilder:client:missionCancel', function(msg)
    if M then M.cancel = true cleanup(0) end
    if msg then JBNotify('~r~' .. msg) end
end)

RegisterCommand('missionstop', function() CancelMission() end, false)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and M then M.cancel = true cleanup(0) end
end)

-- ─────────────────────────────── Interface ───────────────────────────────
NuiLocal['missions:start'] = function(args, cb)
    ESX.TriggerServerCallback('jobbuilder:missions:start', function(res)
        if res and res.ok then
            CloseUI()
            StartMission(res.mission)
        end
        cb(res or { ok = false, error = 'Erreur' })
    end, args[1], args[2])
end

NuiLocal['missions:cancel'] = function(_, cb)
    CancelMission()
    CloseUI()
    cb({ ok = true })
end

function OpenMissionStatus()
    ESX.TriggerServerCallback('jobbuilder:missions:status', function(res)
        if not res or not res.ok then return JBNotify('~r~' .. ((res and res.error) or 'Erreur')) end
        OpenUI({ action = 'open', kind = 'missionStatus', data = res })
    end)
end
