-- ─────────────────────────────── Course poursuite (client) ───────────────────────────────
local inMatch, myRole, saved, vehicle = false, nil, nil, nil
local blips = {}

local function send(action, data)
    data = data or {}
    data.action = action
    SendNUIMessage(data)
end

-- ─────────────────────────────── Menu ───────────────────────────────
Handlers.chase = function(node)
    if node.kind ~= 'lobby' or inMatch then return end
    if IsPedInAnyVehicle(PlayerPedId(), false) then return Notify('Descends du véhicule pour ouvrir la course poursuite.', 'error') end
    ServerCall('worldbuilder:chase:info', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Indisponible', 'error') end
        OpenPanel('chase', res, { type = 'chase', eid = node.eid, pi = node.pi })
    end, node.eid, node.pi)
end

-- Quand le menu se ferme, le joueur n'écoute plus les lobbies
OnPanelClose = function(ctx)
    if ctx and ctx.type == 'chase' then TriggerServerEvent('worldbuilder:chase:unsubscribe') end
end

local function evt(name, withArg)
    NuiLocal['chase:' .. name] = function(args, cb)
        if withArg then TriggerServerEvent('worldbuilder:chase:' .. name, args[1]) else TriggerServerEvent('worldbuilder:chase:' .. name) end
        cb({ ok = true })
    end
end
evt('create', true) evt('join', true) evt('leave') evt('setRole', true) evt('setVehicle', true) evt('start')

NuiLocal['chase:leaderboard'] = function(_, cb)
    ESX.TriggerServerCallback('worldbuilder:chase:leaderboard', function(res) cb(res or { ok = false }) end)
end

RegisterNetEvent('worldbuilder:client:chaseState', function(state) send('chaseState', { state = state }) end)

-- ─────────────────────────────── Utilitaires ───────────────────────────────
local function clearBlips()
    for _, b in pairs(blips) do if DoesBlipExist(b) then RemoveBlip(b) end end
    blips = {}
end

local function setBlip(key, x, y, sprite, colour, label)
    local b = blips[key]
    if not b or not DoesBlipExist(b) then
        b = AddBlipForCoord(x, y, 0.0)
        SetBlipSprite(b, sprite) SetBlipColour(b, colour) SetBlipScale(b, 0.9) SetBlipAsShortRange(b, false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(label)
        EndTextCommandSetBlipName(b)
        blips[key] = b
    end
    SetBlipCoords(b, x, y, 0.0)
end

local function groundZ(x, y, z)
    RequestCollisionAtCoord(x, y, z)
    local t = GetGameTimer()
    while GetGameTimer() - t < 3000 do
        local found, gz = GetGroundZFor_3dCoord(x, y, z + 50.0, false)
        if found then return gz end
        Wait(50)
    end
    return z
end

local function applyLoadout(veh, role, maxPerformance)
    if role == 'runner' then
        SetVehicleCustomPrimaryColour(veh, 255, 122, 69) SetVehicleCustomSecondaryColour(veh, 30, 30, 30)
    else
        SetVehicleCustomPrimaryColour(veh, 56, 189, 248) SetVehicleCustomSecondaryColour(veh, 15, 23, 42)
    end
    SetVehicleNumberPlateText(veh, role == 'runner' and 'FUGITIF' or 'CHASE')
    if maxPerformance then
        SetVehicleModKit(veh, 0)
        for _, modType in ipairs({ 11, 12, 13, 15 }) do
            local n = GetNumVehicleMods(veh, modType)
            if n > 0 then SetVehicleMod(veh, modType, n - 1, false) end
        end
        ToggleVehicleMod(veh, 18, true)
    end
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleDirtLevel(veh, 0.0)
end

local function deleteVehicle()
    if vehicle and DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
    end
    vehicle = nil
end

-- ─────────────────────────────── Déroulement de la partie ───────────────────────────────
RegisterNetEvent('worldbuilder:client:chasePrepare', function(d)
    CloseUI()
    inMatch, myRole, Busy = true, d.role, true
    local ped = PlayerPedId()
    if not saved then saved = { coords = GetEntityCoords(ped), heading = GetEntityHeading(ped) } end
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end
    local s = d.spawn
    local hash = LoadModel(d.model)
    deleteVehicle()
    if hash then
        local z = groundZ(s.x, s.y, s.z)
        SetEntityCoordsNoOffset(ped, s.x, s.y, z, false, false, false)
        vehicle = CreateVehicle(hash, s.x, s.y, z, s.h, true, false)
        SetModelAsNoLongerNeeded(hash)
        SetVehicleOnGroundProperly(vehicle)
        SetPedIntoVehicle(ped, vehicle, -1)
        applyLoadout(vehicle, d.role, d.maxPerformance)
        FreezeEntityPosition(vehicle, true)
    end
    DoScreenFadeIn(500)
    TriggerServerEvent('worldbuilder:chase:ready')
end)

RegisterNetEvent('worldbuilder:client:chaseCountdown', function(seconds)
    CreateThread(function()
        for i = seconds, 1, -1 do
            send('chaseCount', { value = tostring(i), role = myRole })
            PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
            Wait(1000)
        end
        send('chaseCount', { value = 'GO', role = myRole })
        PlaySoundFrontend(-1, 'Out_Of_Bounds_Timer', 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', true)
    end)
end)

RegisterNetEvent('worldbuilder:client:chaseGo', function(d)
    send('chaseHud', { show = true, role = d.role, catchTime = d.catchTime, headStart = d.headStart })
    if d.release and vehicle and DoesEntityExist(vehicle) then FreezeEntityPosition(vehicle, false) end
end)

RegisterNetEvent('worldbuilder:client:chaseRelease', function()
    if vehicle and DoesEntityExist(vehicle) then FreezeEntityPosition(vehicle, false) end
    PlaySoundFrontend(-1, 'Beep_Green', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
end)

RegisterNetEvent('worldbuilder:client:chaseTick', function(t)
    if not inMatch then return end
    send('chaseTick', { tick = t })
    if not (Config.Chase and Config.Chase.ShowBlips) then return end
    if myRole == 'chaser' and t.runner then
        setBlip('runner', t.runner.x, t.runner.y, 225, 1, 'Fugitif')
    elseif myRole == 'runner' and t.chasers then
        local seen = {}
        for i, c in ipairs(t.chasers) do
            local key = 'chaser' .. i
            seen[key] = true
            setBlip(key, c.x, c.y, 225, 3, 'Poursuivant')
        end
        for key, b in pairs(blips) do
            if not seen[key] and DoesBlipExist(b) then RemoveBlip(b) blips[key] = nil end
        end
    end
end)

RegisterNetEvent('worldbuilder:client:chaseFinish', function(d)
    send('chaseHud', { show = false })
    send('chaseResult', { result = d })
    PlaySoundFrontend(-1, (d.won and d.winner ~= 'none') and 'RACE_PLACED' or 'CHECKPOINT_MISSED', 'HUD_AWARDS', true)
    clearBlips()
end)

RegisterNetEvent('worldbuilder:client:chaseCleanup', function()
    send('chaseHud', { show = false })
    send('chaseResult', { result = nil })
    clearBlips()
    if not inMatch then return end
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16)
        Wait(100)
    end
    deleteVehicle()
    if saved then
        RequestCollisionAtCoord(saved.coords.x, saved.coords.y, saved.coords.z)
        SetEntityCoordsNoOffset(ped, saved.coords.x, saved.coords.y, saved.coords.z, false, false, false)
        SetEntityHeading(ped, saved.heading)
    end
    saved, myRole, inMatch, Busy = nil, nil, false, false
    FreezeEntityPosition(ped, false)
    Wait(300)
    DoScreenFadeIn(500)
end)

-- Empêche de sortir du véhicule pendant la partie
CreateThread(function()
    while true do
        if inMatch then DisableControlAction(0, 75, true) Wait(0) else Wait(500) end
    end
end)

local prevStop = OnStop
function OnStop()
    if prevStop then prevStop() end
    clearBlips()
    deleteVehicle()
end
