local active, typed, result = false, false, nil

RegisterNUICallback('choice', function(data, cb) cb({}) result = data and data.accept == true end)
RegisterNUICallback('typed', function(_, cb) cb({}) typed = true end)

local function loadDict(d)
    if HasAnimDictLoaded(d) then return true end
    RequestAnimDict(d)
    local t = GetGameTimer() + 1500
    while not HasAnimDictLoaded(d) and GetGameTimer() < t do Wait(10) end
    return HasAnimDictLoaded(d)
end

-- exports.pickax_dialog:Ask({ ped = entity, name = 'Agent de la fourrière', text = '…', scenario = 'WORLD_HUMAN_CLIPBOARD', accept = 'Accepter', refuse = 'Refuser' })
-- → true si le joueur accepte, false sinon (bloquant : à appeler depuis un thread)
exports('Ask', function(o)
    o = type(o) == 'table' and o or {}
    if active then return false end
    active, typed, result = true, false, nil

    local me = PlayerPedId()
    local ped = o.ped and DoesEntityExist(o.ped) and o.ped or nil
    local oldHeading, cam = nil, nil

    if ped and Config.Gesture then
        oldHeading = GetEntityHeading(ped)
        local mc, pc = GetEntityCoords(me), GetEntityCoords(ped)
        SetEntityHeading(ped, GetHeadingFromVector_2d(mc.x - pc.x, mc.y - pc.y))
        if loadDict('gestures@m@standing@casual') then
            ClearPedTasks(ped)
            TaskPlayAnim(ped, 'gestures@m@standing@casual', 'gesture_hello', 4.0, -4.0, 1800, 48, 0, false, false, false)
        end
    end
    if ped and Config.Camera then
        cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        local c = GetOffsetFromEntityInWorldCoords(ped, 0.45, 1.35, 0.7)
        SetCamCoord(cam, c.x, c.y, c.z)
        PointCamAtPedBone(cam, ped, 31086, 0.0, 0.0, 0.0, true)
        SetCamFov(cam, 42.0)
        RenderScriptCams(true, true, 600, true, false)
    end
    if Config.HideHuds then TriggerEvent('pickax:inventory', true) end

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'show', name = o.name, text = o.text, accept = o.accept or Config.Accept, refuse = o.refuse or Config.Refuse, speed = Config.TypeSpeed })

    local started = GetGameTimer()
    local startPos = GetEntityCoords(me)
    while result == nil do
        Wait(150)
        if IsEntityDead(me) or #(GetEntityCoords(me) - startPos) > Config.MaxDistance then result = false end
        if Config.Timeout > 0 and GetGameTimer() - started > Config.Timeout * 1000 then result = false end
    end

    SendNUIMessage({ action = 'hide' })
    SetNuiFocus(false, false)
    if cam then RenderScriptCams(false, true, 500, true, false) Wait(0) DestroyCam(cam, false) end
    if Config.HideHuds then TriggerEvent('pickax:inventory', false) end
    if ped and DoesEntityExist(ped) and Config.Gesture then
        if oldHeading then SetEntityHeading(ped, oldHeading) end
        if o.scenario and o.scenario ~= '' then ClearPedTasks(ped) TaskStartScenarioInPlace(ped, o.scenario, 0, true) end
    end
    active = false
    return result == true
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and active then SetNuiFocus(false, false) RenderScriptCams(false, false, 0, true, false) end
end)
