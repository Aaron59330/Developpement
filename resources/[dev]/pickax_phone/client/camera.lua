-- Appareil photo : caméra scriptée (arrière / selfie), capture via screenshot-basic
local cam, selfie, fov = nil, false, 50.0
local capturing = false

local function destroyCam()
    if cam then RenderScriptCams(false, false, 0, true, false); DestroyCam(cam, false); cam = nil end
end

local function buildCam()
    destroyCam()
    local ped = PlayerPedId()
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    if selfie then
        AttachCamToPedBone(cam, ped, 31086, 0.0, 0.62, 0.08, true)
        PointCamAtPedBone(cam, ped, 31086, 0.0, 0.0, 0.0, true)
    end
    SetCamFov(cam, fov)
    RenderScriptCams(true, false, 0, true, false)
end

local function uploadUrl() return Config.Camera.webhook end

local function parseUrl(raw)
    local ok, j = pcall(json.decode, raw)
    if not ok or type(j) ~= 'table' then return nil end
    if Config.Camera.mode == 'discord' then
        local a = j.attachments and j.attachments[1]
        return a and (a.proxy_url or a.url)
    elseif Config.Camera.mode == 'fivemanage' then
        return j.url or (j.data and j.data.url)
    end
    return j.url
end

local function capture()
    if capturing then return end
    if GetResourceState('screenshot-basic') ~= 'started' then
        SendNUIMessage({ action = 'cameraError', error = 'screenshot-basic n\'est pas démarré' }) return
    end
    local url = uploadUrl()
    if (not url or url == '') and Config.Camera.mode ~= 'fivemanage' then
        SendNUIMessage({ action = 'cameraError', error = 'Aucune adresse d\'envoi configurée (Config.Camera.webhook)' }) return
    end
    capturing = true
    SendNUIMessage({ action = 'cameraFlash' })
    Wait(120)
    SendNUIMessage({ action = 'cameraHide', state = true })
    Wait(60)
    local opts = { encoding = Config.Camera.encoding, quality = Config.Camera.quality, headers = {} }
    if Config.Camera.mode == 'fivemanage' then
        url = 'https://api.fivemanage.com/api/image'
        opts.headers = { ['Authorization'] = Config.Camera.apiKey }
    end
    exports['screenshot-basic']:requestScreenshotUpload(url, Config.Camera.field, opts, function(raw)
        SendNUIMessage({ action = 'cameraHide', state = false })
        local link = parseUrl(raw)
        if not link then capturing = false; SendNUIMessage({ action = 'cameraError', error = 'Envoi de la photo impossible' }) return end
        local p, err = lib.callback.await('aura:photoAdd', false, link, 'photo')
        capturing = false
        if p then SendNUIMessage({ action = 'cameraShot', photo = p }) else SendNUIMessage({ action = 'cameraError', error = err or 'Galerie pleine' }) end
    end)
end

local function stop()
    Phone.camera = false
    destroyCam()
    SendNUIMessage({ action = 'cameraStopped' })
    if not Phone.open then Phone.Open() else Phone.UpdateAnim() end
end

RegisterNUICallback('cameraStart', function(d, cb)
    cb(1)
    if Phone.camera then return end
    selfie = d and d.selfie and true or false
    fov = 50.0
    Phone.camera = true
    Phone.open = false                        -- l'interface reste affichée, mais seule la surcouche caméra est visible
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    buildCam()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        RequestAnimDict('cellphone@')
        while not HasAnimDictLoaded('cellphone@') do Wait(10) end
        TaskPlayAnim(ped, 'cellphone@', selfie and 'cellphone_photo_idle' or 'cellphone_photo_idle', 3.0, 3.0, -1, 50, 0, false, false, false)
    end
    CreateThread(function()
        while Phone.camera do
            Wait(0)
            if not selfie and cam then
                local c = GetGameplayCamCoord(); local r = GetGameplayCamRot(2)
                SetCamCoord(cam, c.x, c.y, c.z); SetCamRot(cam, r.x, r.y, r.z, 2)
            end
            if IsControlJustPressed(0, 176) then capture() end                       -- ENTRÉE : photo
            if IsControlJustPressed(0, 177) or IsControlJustPressed(0, 200) then stop() break end   -- RETOUR / ÉCHAP
            if IsControlJustPressed(0, 38) then selfie = not selfie; buildCam(); SendNUIMessage({ action = 'cameraMode', selfie = selfie }) end   -- E : retourner
            if IsControlPressed(0, 241) or IsControlPressed(0, 96) then fov = math.max(15.0, fov - 1.0); if cam then SetCamFov(cam, fov) end SendNUIMessage({ action = 'cameraZoom', value = math.floor((50.0 - fov) / 35.0 * 100) }) end
            if IsControlPressed(0, 242) or IsControlPressed(0, 97) then fov = math.min(70.0, fov + 1.0); if cam then SetCamFov(cam, fov) end SendNUIMessage({ action = 'cameraZoom', value = math.floor((50.0 - fov) / 35.0 * 100) }) end
            DisableControlAction(0, 24, true); DisableControlAction(0, 25, true); DisableControlAction(0, 37, true)
        end
    end)
end)

RegisterNUICallback('cameraStop', function(_, cb) cb(1) if Phone.camera then stop() end end)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then destroyCam() end end)
