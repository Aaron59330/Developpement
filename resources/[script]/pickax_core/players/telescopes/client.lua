-- Variables --
local inTelescope = false
local gameplayCamera = {}
local telescopeHeading = 0.0
local frozen = false

local camera = nil
local scaleform = nil

local fov = ConfigTelescopes.Zoom.Max
local relativeOffset = 0.0
local maxVertical = 20.0
local maxHorizontal = 55.0

local hudComponentsToHide = {
    [1] = true,
    [2] = true,
    [3] = true,
    [4] = true,
    [13] = true,
    [11] = true,
    [12] = true,
    [15] = true,
    [18] = true,
    [19] = true
}

local function CreateTelescopeCamera(entity, data)
    camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local coords = GetOffsetFromEntityInWorldCoords(entity, data.cameraOffset.x, data.cameraOffset.y, data.cameraOffset.z)
    local rotation = GetEntityRotation(entity, 5).z
    if data.headingOffset then
        rotation = rotation + data.headingOffset
        if rotation > 360.0 then rotation = rotation - 360.0 end
    end

    SetCamCoord(camera, coords.x, coords.y, coords.z)
    SetCamRot(camera, 0.0, 0.0, rotation, 2)

    SetExtraTimecycleModifier("telescope")

    scaleform = RequestScaleformMovie(data.scaleform)
    while not HasScaleformMovieLoaded(scaleform) do
        Wait(10)
    end
    local xRes, yRes = GetActiveScreenResolution()
    BeginScaleformMovieMethod(scaleform, "SET_DISPLAY_ConfigTelescopes")
    ScaleformMovieMethodAddParamInt(xRes)
    ScaleformMovieMethodAddParamInt(yRes)
    ScaleformMovieMethodAddParamInt(5) --_safeTopPercent
    ScaleformMovieMethodAddParamInt(5) --_safeBottomPercent
    ScaleformMovieMethodAddParamInt(5) --_safeLeftPercent
    ScaleformMovieMethodAddParamInt(5) --_safeRightPercent
    ScaleformMovieMethodAddParamBool(GetIsWidescreen())
    ScaleformMovieMethodAddParamBool(GetIsHidef())
    ScaleformMovieMethodAddParamBool(false) --isAsian
    EndScaleformMovieMethod()

    RenderScriptCams(true, false, 0, false, false)
end

local function HideHudThisFrame()
    HideHudAndRadarThisFrame()
    for id, _state in pairs(hudComponentsToHide) do
        HideHudComponentThisFrame(id)
    end
end

local function IsPedPlayingAnyTelescopeAnim(ped)
    for _animType, animations in pairs(ConfigTelescopes.Animations) do
        for _key, animation in pairs(animations) do
            if type(animation) == "string" and IsEntityPlayingAnim(ped, "mini@telescope", animation, 3) then
                return true
            end
        end
    end
    return false
end

local function IsTelescopeAvailable(coords)
    local playerPed = PlayerPedId()
    local pedPool = GetGamePool('CPed')
    for _index, ped in pairs(pedPool) do
        if #(GetEntityCoords(ped) - coords) < 1.0 and ped ~= playerPed then
            if IsPedPlayingAnyTelescopeAnim(ped) then
                return false
            end
        end
    end

    return true
end

local function HandleZoom()
    if GetDisabledControlNormal(0, 32) ~= 0.0 or GetDisabledControlNormal(0, 335) ~= 0.0 then -- Zoom in
        fov = math.max(fov - ConfigTelescopes.Zoom.Speed, ConfigTelescopes.Zoom.Min)
    end
    if GetDisabledControlNormal(0, 33) ~= 0.0 or GetDisabledControlNormal(0, 336) ~= 0.0 then -- Zoom out
        fov = math.min(fov + ConfigTelescopes.Zoom.Speed, ConfigTelescopes.Zoom.Max)
    end
    local current_fov = GetCamFov(camera)
    if math.abs(fov-current_fov) < 0.1 then
        fov = current_fov
    end
    SetCamFov(camera, current_fov + (fov - current_fov)*0.05)
end

local function HandleMovementInput()
    local axisX = GetDisabledControlNormal(0, 220)
    local axisY = GetDisabledControlNormal(0, 221)

    if axisX ~= 0.0 or axisY ~= 0.0 then
        local zoomValue = (1.0/(ConfigTelescopes.Zoom.Max-ConfigTelescopes.Zoom.Min))*(fov-ConfigTelescopes.Zoom.Min)
        local rotation = GetCamRot(camera, 2)

        local movementSpeed = (IsUsingKeyboard(1) and ConfigTelescopes.MovementSpeed.Keyboard) or ConfigTelescopes.MovementSpeed.Controller
        relativeOffset = relativeOffset + axisX*-1.0*(movementSpeed)*(zoomValue+0.1)
        if relativeOffset > maxHorizontal then
            relativeOffset = maxHorizontal
        elseif relativeOffset < maxHorizontal*-1 then
            relativeOffset = maxHorizontal*-1
        end

        local newX = math.max(math.min(maxVertical, rotation.x + axisY*-1.0*(movementSpeed)*(zoomValue+0.1)), maxVertical*-1)
        local newZ = telescopeHeading + relativeOffset

        SetCamRot(camera, newX, 0.0, newZ, 2)
    end
end

local function GetClosestTelescope()
    local objectPool = GetGamePool('CObject')
    local telescopes = {}
    for _index, entity in pairs(objectPool) do
        local model = GetEntityModel(entity)
        if ConfigTelescopes.Models[model] then
            telescopes[entity] = true
        end
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closest = 0
    local distance = 1000

    for entity, _boolean in pairs(telescopes) do
        local coords = GetEntityCoords(entity)
        local dist = #(playerCoords - coords)
        if dist < distance then
            closest = entity
            distance = dist
        end
    end

    return closest, distance
end

local function RequestControlIfNetworked(entity)
    if NetworkGetEntityIsNetworked(entity) then
        NetworkRequestControlOfEntity(entity)
    end
end

local function FreezeTelescope(entity)
    if not IsEntityPositionFrozen(entity) then
        RequestControlIfNetworked(entity)
        FreezeEntityPosition(entity, true)
        frozen = true
    end
end

local function UnfreezeTelescope(entity)
    if frozen then
        RequestControlIfNetworked(entity)
        FreezeEntityPosition(entity, false)
        frozen = false
    end
end

-- Barre d'aide du télescope : affichée par pickax_ui (couleur du serveur), plus de bandeau GTA natif
local function SetupInstructions()
    local function k(control) local ok, v = pcall(function() return exports.pickax_ui:ControlKey(control, 0) end) return ok and v or '?' end
    pcall(function()
        exports.pickax_ui:KeysShow('telescope', {
            { key = k(38), label = ConfigTelescopes.Text.Leave },
            { key = k(15), label = ConfigTelescopes.Text.Zoom },
            { key = k(14), label = ConfigTelescopes.Text.Dezoom },
        })
    end)
end

local function UseTelescope(entity)
    local playerPed = PlayerPedId()
    local data = ConfigTelescopes.Models[GetEntityModel(entity)]
    local offsetCoords = GetOffsetFromEntityInWorldCoords(entity, data.offset.x, data.offset.y, data.offset.z)
    local animation = ConfigTelescopes.Animations[data.animation]
    inTelescope = true

    if not IsTelescopeAvailable(offsetCoords) then
        ESX.ShowNotification(ConfigTelescopes.Text.TelescopeInUse)
        return
    end

    local heading = GetEntityHeading(entity)
    if data.headingOffset then
        heading = heading + data.headingOffset
        if heading > 360.0 then heading = heading - 360.0 end
    end

    TaskGoStraightToCoord(playerPed, offsetCoords.x, offsetCoords.y, offsetCoords.z, 1, 8000, heading, 0.05)

    while true do
        Wait(250)
        local taskStatus = GetScriptTaskStatus(playerPed, "SCRIPT_TASK_GO_STRAIGHT_TO_COORD")
        if taskStatus == 0 or taskStatus == 7 then
            break
        end
    end

    ClearPedTasks(playerPed)
    local difference = math.abs(heading - GetEntityHeading(playerPed))
    if difference > 10.0 then
        SetEntityHeading(playerPed, heading)
    end

    local dist = #(GetEntityCoords(playerPed)-offsetCoords)
    if dist > 0.425 and dist < 2.0 then
        SetEntityCoords(playerPed, offsetCoords.x, offsetCoords.y, offsetCoords.z-1.0)
    elseif dist > 2.0 then
        DisplayNotification(ConfigTelescopes.Text.ToFarAway)
        ClearPedTasks(playerPed)
        return
    end

    FreezeTelescope(entity)
    ESXCustom_Function_ClientSide:LoadAnimDict("mini@telescope")
    TaskPlayAnim(playerPed, "mini@telescope", animation.enter, 2.0, 2.0, -1, 2, 0, false, false, false)

    gameplayCamera.heading = GetGameplayCamRelativeHeading()
    gameplayCamera.pitch = GetGameplayCamRelativePitch()

    Wait(animation.enterTime)
    
    DoScreenFadeOut(500)
    Wait(600)

    TaskPlayAnim(playerPed, "mini@telescope", animation.idle, 2.0, 2.0, -1, 1, 0, false, false, false)
    CreateTelescopeCamera(entity, data)
    SetupInstructions()
    Citizen.CreateThread(function()
        DoScreenFadeIn(500)
    end)

    local tick = 0
    local doAnim = true
    fov = ConfigTelescopes.Zoom.Max
    maxVertical = data.MaxVertical
    maxHorizontal = data.MaxHorizontal
    telescopeHeading = heading
    relativeOffset = 0.0

    while true do
        HandleZoom()
        HandleMovementInput()

        if IsControlJustPressed(0, 38) then
            break
        end

        -- Only handle "less important" stuff every 100 frames
        if tick >= 100 then
            if #(GetEntityCoords(playerPed)-offsetCoords) > 1.5 or IsEntityDead(playerPed) then
                doAnim = false
                break
            end
            tick = 0
        end
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
        HideHudThisFrame()

        tick = tick + 1
        Wait(0)
    end

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
        Wait(0)
    end
    Wait(150)

    RenderScriptCams(false, false, 0, false, false)
    DestroyCam(camera, false)

    ClearExtraTimecycleModifier()
    SetScaleformMovieAsNoLongerNeeded(scaleform)
    pcall(function() exports.pickax_ui:KeysHide('telescope') end)

    SetGameplayCamRelativeHeading(gameplayCamera.heading)
    SetGameplayCamRelativePitch(gameplayCamera.pitch, 1.0)

    DoScreenFadeIn(500)
    Wait(500)

    if doAnim then
        TaskPlayAnim(playerPed, "mini@telescope", animation.exit, 2.0, 1.0, -1, 0, 0, false, false, false)
        Wait(1500)
    else
        ClearPedTasks(playerPed)
    end
    inTelescope = false
    UnfreezeTelescope(entity)
    RemoveAnimDict("mini@telescope")
end

local telescopes = {}
Citizen.CreateThread(function()
    while true do
        local objectPool = GetGamePool('CObject')
        for _index, entity in pairs(objectPool) do
            local model = GetEntityModel(entity)
            if ConfigTelescopes.Models[model] then
                telescopes[entity] = true
            end
        end
        Wait(1000)
    end
end)

Citizen.CreateThread(function()
    while true do
        if not inTelescope then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local closest = 0
            local distance = 250
            for entity, _boolean in pairs(telescopes) do
                local coords = GetEntityCoords(entity)
                local dist = #(playerCoords - coords)
                if dist < distance then
                    closest = entity
                    distance = dist
                end
            end
            if closest ~= 0 and distance < ConfigTelescopes.MaxInteractionDist then
                ESX.ShowHelpNotification(ConfigTelescopes.Text.HelpText)
                if IsControlJustPressed(0, 38) then
                    UseTelescope(closest)
                end
                Wait(0)
            else
                Wait(distance*20)
            end
        else
            Wait(500)
        end
    end
end)