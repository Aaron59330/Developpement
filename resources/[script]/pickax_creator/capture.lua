-- Capture des têtes : voir server.lua (/capturefaces). Place un ped freemode devant une caméra serrée sur le visage, applique le visage n°id et demande une capture.
local busy, nextShot = false, nil

local function loadModel(name)
    local h = joaat(name)
    RequestModel(h)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(h) and GetGameTimer() < t do Wait(10) end
    return h
end

RegisterNetEvent('pickax_creator:faceShotDone', function(id, ok) nextShot = ok and id or false end)

RegisterNetEvent('pickax_creator:captureFaces', function()
    if busy then return end
    busy = true
    local me = PlayerPedId()
    local base = GetOffsetFromEntityInWorldCoords(me, 0.0, 3.0, 0.0)
    local heading = GetEntityHeading(me) + 180.0
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    DisplayHud(false) DisplayRadar(false)
    SendNUIMessage({ a = 'hide' })
    local done, failed = 0, 0
    for id = 0, 45 do
        local model = (id >= 21 and id <= 41) and 'mp_f_freemode_01' or 'mp_m_freemode_01'
        local h = loadModel(model)
        local ped = CreatePed(4, h, base.x, base.y, base.z - 1.0, heading, false, false)
        SetEntityInvincible(ped, true) FreezeEntityPosition(ped, true) SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedHeadBlendData(ped, id, id, 0, id, id, 0, 1.0, 1.0, 0.0, false)
        SetPedComponentVariation(ped, 2, 0, 0, 0)   -- cheveux courts / neutres
        local hd = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)   -- tête
        local f = GetEntityForwardVector(ped)
        SetCamCoord(cam, hd.x + f.x * 0.62, hd.y + f.y * 0.62, hd.z + 0.02)
        PointCamAtCoord(cam, hd.x, hd.y, hd.z + 0.01)
        SetCamFov(cam, 28.0) SetCamActive(cam, true) RenderScriptCams(true, false, 0, true, true)
        Wait(900)
        nextShot = nil
        TriggerServerEvent('pickax_creator:faceShot', id)
        local t = GetGameTimer() + 8000
        while nextShot == nil and GetGameTimer() < t do Wait(50) end
        if nextShot == false or nextShot == nil then failed = failed + 1 else done = done + 1 end
        DeleteEntity(ped) SetModelAsNoLongerNeeded(h)
    end
    RenderScriptCams(false, false, 0, true, true) DestroyCam(cam, false)
    DisplayHud(true) DisplayRadar(true)
    busy = false
    TriggerEvent('chat:addMessage', { args = { 'Création', ('Capture terminée : %d visage(s) enregistré(s), %d échec(s). Redémarre pickax_creator.'):format(done, failed) } })
end)
