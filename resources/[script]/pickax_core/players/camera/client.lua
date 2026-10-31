local cam = nil
local offsetRotX = 0.0
local offsetRotY = 0.0
local offsetRotZ = 0.0
local isAttached = false
local camCoords
local ActualSpeed = ConfigCamera.Speed.Default
local whitelisted = nil
local maxDistance = ConfigCamera.MaxDistanceForPlayer
local maxDistanceStaff = ConfigCamera.MaxDistanceForStaff

-- Barre d'aide de la caméra libre : affichée par pickax_ui (couleur du serveur), plus de bandeau GTA natif
local function ShowCamKeys()
    local B, N = ConfigCamera.Bind, ConfigCamera.MenuName
    local function k(control) local ok, v = pcall(function() return exports.pickax_ui:ControlKey(control, 1) end) return ok and v or '?' end
    pcall(function()
        exports.pickax_ui:KeysShow('freecam', {
            { key = k(B.Pivot1), label = N["Pivot1"] }, { key = k(B.Pivot2), label = N["Pivot2"] },
            { key = k(B.Down), label = N["Down"] }, { key = k(B.UP), label = N["UP"] },
            { key = k(B.Left), label = N["Left"] }, { key = k(B.Right), label = N["Right"] },
            { key = k(B.Back), label = N["Back"] }, { key = k(B.Front), label = N["Front"] },
        })
    end)
end

function StartFreeCam(fov)
    ClearFocus()

    local playerPed = GetPlayerPed(-1)
    
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", GetEntityCoords(playerPed), 0, 0, 0, fov * 1.0)

    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)
    SetCamAffectsAiming(cam, false)

    if (isAttached) then
        AttachCamToEntity(cam, playerPed, 0.0, 0.0, 0.0, true)
    end

    ShowCamKeys()
    CreateThread(function()
        while true do
            Citizen.Wait(1)
            if (IsDisabledControlPressed(1, ConfigCamera.Bind.SpeedBetter)) then
                if ActualSpeed < ConfigCamera.Speed.MaxSpeed then
                    ActualSpeed = ActualSpeed + 0.2
                end
            end

            if (IsDisabledControlPressed(1, ConfigCamera.Bind.SpeedSlow)) then
                if ConfigCamera.Speed.MinSpeed < ActualSpeed then
                    ActualSpeed = ActualSpeed - 0.2
                end
            end

            if (cam) then
                ProcessCamControls()
            else
                break
            end
        end
    end)
end

function EndFreeCam()
    ClearFocus()
    pcall(function() exports.pickax_ui:KeysHide('freecam') end)

    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(cam, false)
    
    offsetRotX = 0.0
    offsetRotY = 0.0
    offsetRotZ = 0.0

    cam = nil
end

function ProcessCamControls()
    DisableFirstPersonCamThisFrame()
    
    local playerPed = GetPlayerPed(-1)
    local playerRot = GetEntityRotation(playerPed, 2)

    local rotX = playerRot.x
    local rotY = playerRot.y
    local rotZ = playerRot.z

    for k, v in pairs(ConfigCamera.BindDisable) do
        DisableControlAction(0, v, true)
    end
    
    offsetRotX = offsetRotX - (GetDisabledControlNormal(1, 2) * 8.0)
    offsetRotZ = offsetRotZ - (GetDisabledControlNormal(1, 1) * 8.0)
    if (offsetRotX > 90.0) then offsetRotX = 90.0 elseif (offsetRotX < -90.0) then offsetRotX = -90.0 end
    if (offsetRotY > 90.0) then offsetRotY = 90.0 elseif (offsetRotY < -90.0) then offsetRotY = -90.0 end
    if (offsetRotZ > 360.0) then offsetRotZ = offsetRotZ - 360.0 elseif (offsetRotZ < -360.0) then offsetRotZ = offsetRotZ + 360.0 end
        
    if (isAttached) then
        local offsetCoords = GetOffsetFromEntityGivenWorldCoords(playerPed, GetCamCoord(cam))
        local x = offsetCoords.x
        local y = offsetCoords.y
        local z = offsetCoords.z
        
        if (IsDisabledControlPressed(1, ConfigCamera.Bind.Front)) then -- W
            local multCoordY = 0.0
            local multCoordX = 0.0
            if ((offsetRotZ >= 0.0 and offsetRotZ <= 90.0) or (offsetRotZ <= 0.0 and offsetRotZ >= -90.0)) then
                multCoordX = offsetRotZ / 90
                multCoordY = 1.0 - (math.abs(offsetRotZ) / 90)
            elseif ((offsetRotZ >= 90.0 and offsetRotZ <= 180.0) or (offsetRotZ <= -90.0 and offsetRotZ >= -180.0)) then
                if (offsetRotZ >= 90.0) then
                    multCoordX = 1.0 - (offsetRotZ - 90.0) / 90
                else
                    multCoordX = - (1.0 + (offsetRotZ + 90.0) / 90)
                end
                multCoordY = - (math.abs(offsetRotZ) - 90.0) / 90
            elseif ((offsetRotZ >= 180.0 and offsetRotZ <= 270.0) or (offsetRotZ <= -180.0 and offsetRotZ >= -270.0)) then
                if (offsetRotZ >= 180.0) then
                    multCoordX = - ((offsetRotZ - 180.0) / 90)
                else
                    multCoordX = - (offsetRotZ + 180.0) / 90
                end
                multCoordY = - 1.0 + (math.abs(offsetRotZ) - 180.0) / 90
            elseif ((offsetRotZ >= 270.0 and offsetRotZ <= 360.0) or (offsetRotZ <= -270.0 and offsetRotZ >= -360.0)) then
                if (offsetRotZ >= 270.0) then
                    multCoordX = - (1.0 - ((offsetRotZ - 270.0) / 90))
                else
                    multCoordX = 1.0 + (offsetRotZ + 270.0) / 90
                end
                multCoordY = (math.abs(offsetRotZ) - 270.0) / 90
            end

            x = x - (0.1 * ActualSpeed * multCoordX)
            y = y + (0.1 * ActualSpeed * multCoordY)
        end
        if (IsDisabledControlPressed(1, ConfigCamera.Bind.Back)) then -- S
            local multCoordY = 0.0
            local multCoordX = 0.0
            if ((offsetRotZ >= 0.0 and offsetRotZ <= 90.0) or (offsetRotZ <= 0.0 and offsetRotZ >= -90.0)) then
                multCoordX = offsetRotZ / 90
                multCoordY = 1.0 - (math.abs(offsetRotZ) / 90)
            elseif ((offsetRotZ >= 90.0 and offsetRotZ <= 180.0) or (offsetRotZ <= -90.0 and offsetRotZ >= -180.0)) then
                if (offsetRotZ >= 90.0) then
                    multCoordX = 1.0 - (offsetRotZ - 90.0) / 90
                else
                    multCoordX = - (1.0 + (offsetRotZ + 90.0) / 90)
                end
                multCoordY = - (math.abs(offsetRotZ) - 90.0) / 90
            elseif ((offsetRotZ >= 180.0 and offsetRotZ <= 270.0) or (offsetRotZ <= -180.0 and offsetRotZ >= -270.0)) then
                if (offsetRotZ >= 180.0) then
                    multCoordX = - ((offsetRotZ - 180.0) / 90)
                else
                    multCoordX = - (offsetRotZ + 180.0) / 90
                end
                multCoordY = - 1.0 + (math.abs(offsetRotZ) - 180.0) / 90
            elseif ((offsetRotZ >= 270.0 and offsetRotZ <= 360.0) or (offsetRotZ <= -270.0 and offsetRotZ >= -360.0)) then
                if (offsetRotZ >= 270.0) then
                    multCoordX = - (1.0 - ((offsetRotZ - 270.0) / 90))
                else
                    multCoordX = 1.0 + (offsetRotZ + 270.0) / 90
                end
                multCoordY = (math.abs(offsetRotZ) - 270.0) / 90
            end

            x = x + (0.1 * ActualSpeed * multCoordX)
            y = y - (0.1 * ActualSpeed * multCoordY)
        end
        if (IsDisabledControlPressed(1, ConfigCamera.Bind.Left)) then -- A
            local multCoordY = 0.0
            local multCoordX = 0.0
            if ((offsetRotZ >= 0.0 and offsetRotZ <= 90.0) or (offsetRotZ <= 0.0 and offsetRotZ >= -90.0)) then
                multCoordX = 1.0 - (math.abs(offsetRotZ) / 90)
                multCoordY = - (offsetRotZ / 90)
            elseif ((offsetRotZ >= 90.0 and offsetRotZ <= 180.0) or (offsetRotZ <= -90.0 and offsetRotZ >= -180.0)) then
                if (offsetRotZ >= 90.0) then
                    multCoordX = - (offsetRotZ - 90.0) / 90
                    multCoordY = - (1.0 - (math.abs(offsetRotZ) - 90.0) / 90)
                else
                    multCoordX = (offsetRotZ + 90.0) / 90
                    multCoordY = 1.0 - ((math.abs(offsetRotZ) - 90.0) / 90)
                end
            elseif ((offsetRotZ >= 180.0 and offsetRotZ <= 270.0) or (offsetRotZ <= -180.0 and offsetRotZ >= -270.0)) then
                if (offsetRotZ >= 180.0) then
                    multCoordX = - (1.0 - ((offsetRotZ - 180.0) / 90))
                    multCoordY = (math.abs(offsetRotZ) - 180.0) / 90
                else
                    multCoordX = - (1.0 + (offsetRotZ + 180.0) / 90)
                    multCoordY = - (math.abs(offsetRotZ) - 180.0) / 90
                end
            elseif ((offsetRotZ >= 270.0 and offsetRotZ <= 360.0) or (offsetRotZ <= -270.0 and offsetRotZ >= -360.0)) then
                if (offsetRotZ >= 270.0) then
                    multCoordX = (offsetRotZ - 270.0) / 90
                    multCoordY = 1.0 - (math.abs(offsetRotZ) - 270.0) / 90
                else
                    multCoordX = - (offsetRotZ + 270.0) / 90
                    multCoordY = - (1.0 - ((math.abs(offsetRotZ) - 270.0) / 90))
                end
            end

            x = x - (0.1 * ActualSpeed * multCoordX)
            y = y + (0.1 * ActualSpeed * multCoordY)
        end
        if (IsDisabledControlPressed(1, ConfigCamera.Bind.Right)) then -- D
            local multCoordY = 0.0
            local multCoordX = 0.0
            if ((offsetRotZ >= 0.0 and offsetRotZ <= 90.0) or (offsetRotZ <= 0.0 and offsetRotZ >= -90.0)) then
                multCoordX = 1.0 - (math.abs(offsetRotZ) / 90)
                multCoordY = - (offsetRotZ / 90)
            elseif ((offsetRotZ >= 90.0 and offsetRotZ <= 180.0) or (offsetRotZ <= -90.0 and offsetRotZ >= -180.0)) then
                if (offsetRotZ >= 90.0) then
                    multCoordX = - (offsetRotZ - 90.0) / 90
                    multCoordY = - (1.0 - (math.abs(offsetRotZ) - 90.0) / 90)
                else
                    multCoordX = (offsetRotZ + 90.0) / 90
                    multCoordY = 1.0 - ((math.abs(offsetRotZ) - 90.0) / 90)
                end
            elseif ((offsetRotZ >= 180.0 and offsetRotZ <= 270.0) or (offsetRotZ <= -180.0 and offsetRotZ >= -270.0)) then
                if (offsetRotZ >= 180.0) then
                    multCoordX = - (1.0 - ((offsetRotZ - 180.0) / 90))
                    multCoordY = (math.abs(offsetRotZ) - 180.0) / 90
                else
                    multCoordX = - (1.0 + (offsetRotZ + 180.0) / 90)
                    multCoordY = - (math.abs(offsetRotZ) - 180.0) / 90
                end
            elseif ((offsetRotZ >= 270.0 and offsetRotZ <= 360.0) or (offsetRotZ <= -270.0 and offsetRotZ >= -360.0)) then
                if (offsetRotZ >= 270.0) then
                    multCoordX = (offsetRotZ - 270.0) / 90
                    multCoordY = 1.0 - (math.abs(offsetRotZ) - 270.0) / 90
                else
                    multCoordX = - (offsetRotZ + 270.0) / 90
                    multCoordY = - (1.0 - ((math.abs(offsetRotZ) - 270.0) / 90))
                end
            end

            x = x + (0.1 * ActualSpeed * multCoordX)
            y = y - (0.1 * ActualSpeed * multCoordY)
        end
        if (IsDisabledControlPressed(1, ConfigCamera.Bind.UP)) then -- SHIFT
            z = z + (0.1 * ActualSpeed)
        end
        if (IsDisabledControlPressed(1, ConfigCamera.Bind.Down)) then -- LEFT CTRL
            z = z - (0.1 * ActualSpeed)
        end
        if (IsDisabledControlPressed(1, ConfigCamera.Bind.Pivot2)) then -- Q
            offsetRotY = offsetRotY - (1.0 * ActualSpeed)
            if (offsetRotY < -360.0) then offsetRotY = offsetRotY + 360.0 end
        end
        if (IsDisabledControlPressed(1, ConfigCamera.Bind.Pivot1)) then -- E
            offsetRotY = offsetRotY + (1.0 * ActualSpeed)
            if (offsetRotY > 360.0) then offsetRotY = offsetRotY - 360.0 end
        end

        -- set coords of cam
        AttachCamToEntity(cam, playerPed, x, y, z, true)
        
        SetFocusEntity(playerPed)

        -- reset coords of cam if too far from player
        if not whitelisted then
            if (Vdist(0.0, 0.0, 0.0, x, y, z) > maxDistance) then
                AttachCamToEntity(cam, playerPed, offsetCoords.x, offsetCoords.y, offsetCoords.z, true)
            end
        else
            if (Vdist(0.0, 0.0, 0.0, x, y, z) > maxDistanceStaff) then
                AttachCamToEntity(cam, playerPed, offsetCoords.x, offsetCoords.y, offsetCoords.z, true)
            end
        end
    else
        local camCoords = GetCamCoord(cam)
        local x = camCoords.x
        local y = camCoords.y
        local z = camCoords.z
        
        if (IsDisabledControlPressed(1, ConfigCamera.Bind.Front)) then -- W
            local multCoordY = 0.0
            local multCoordX = 0.0
            if ((offsetRotZ >= 0.0 and offsetRotZ <= 90.0) or (offsetRotZ <= 0.0 and offsetRotZ >= -90.0)) then
                multCoordX = offsetRotZ / 90
                multCoordY = 1.0 - (math.abs(offsetRotZ) / 90)
            elseif ((offsetRotZ >= 90.0 and offsetRotZ <= 180.0) or (offsetRotZ <= -90.0 and offsetRotZ >= -180.0)) then
                if (offsetRotZ >= 90.0) then
                    multCoordX = 1.0 - (offsetRotZ - 90.0) / 90
                else
                    multCoordX = - (1.0 + (offsetRotZ + 90.0) / 90)
                end
                multCoordY = - (math.abs(offsetRotZ) - 90.0) / 90
            elseif ((offsetRotZ >= 180.0 and offsetRotZ <= 270.0) or (offsetRotZ <= -180.0 and offsetRotZ >= -270.0)) then
                if (offsetRotZ >= 180.0) then
                    multCoordX = - ((offsetRotZ - 180.0) / 90)
                else
                    multCoordX = - (offsetRotZ + 180.0) / 90
                end
                multCoordY = - 1.0 + (math.abs(offsetRotZ) - 180.0) / 90
            elseif ((offsetRotZ >= 270.0 and offsetRotZ <= 360.0) or (offsetRotZ <= -270.0 and offsetRotZ >= -360.0)) then
                if (offsetRotZ >= 270.0) then
                    multCoordX = - (1.0 - ((offsetRotZ - 270.0) / 90))
                else
                    multCoordX = 1.0 + (offsetRotZ + 270.0) / 90
                end
                multCoordY = (math.abs(offsetRotZ) - 270.0) / 90
            end

            x = x - (0.1 * ActualSpeed * multCoordX)
            y = y + (0.1 * ActualSpeed * multCoordY)
        end
        if (IsDisabledControlPressed(1, ConfigCamera.Bind.Back)) then -- S
            local multCoordY = 0.0
            local multCoordX = 0.0
            if ((offsetRotZ >= 0.0 and offsetRotZ <= 90.0) or (offsetRotZ <= 0.0 and offsetRotZ >= -90.0)) then
                multCoordX = offsetRotZ / 90
                multCoordY = 1.0 - (math.abs(offsetRotZ) / 90)
            elseif ((offsetRotZ >= 90.0 and offsetRotZ <= 180.0) or (offsetRotZ <= -90.0 and offsetRotZ >= -180.0)) then
                if (offsetRotZ >= 90.0) then
                    multCoordX = 1.0 - (offsetRotZ - 90.0) / 90
                else
                    multCoordX = - (1.0 + (offsetRotZ + 90.0) / 90)
                end
                multCoordY = - (math.abs(offsetRotZ) - 90.0) / 90
            elseif ((offsetRotZ >= 180.0 and offsetRotZ <= 270.0) or (offsetRotZ <= -180.0 and offsetRotZ >= -270.0)) then
                if (offsetRotZ >= 180.0) then
                    multCoordX = - ((offsetRotZ - 180.0) / 90)
                else
                    multCoordX = - (offsetRotZ + 180.0) / 90
                end
                multCoordY = - 1.0 + (math.abs(offsetRotZ) - 180.0) / 90
            elseif ((offsetRotZ >= 270.0 and offsetRotZ <= 360.0) or (offsetRotZ <= -270.0 and offsetRotZ >= -360.0)) then
                if (offsetRotZ >= 270.0) then
                    multCoordX = - (1.0 - ((offsetRotZ - 270.0) / 90))
                else
                    multCoordX = 1.0 + (offsetRotZ + 270.0) / 90
                end
                multCoordY = (math.abs(offsetRotZ) - 270.0) / 90
            end

            x = x + (0.1 * ActualSpeed * multCoordX)
            y = y - (0.1 * ActualSpeed * multCoordY)
        end
        if (IsDisabledControlPressed(1, ConfigCamera.Bind.Left)) then -- A
            local multCoordY = 0.0
            local multCoordX = 0.0
            if ((offsetRotZ >= 0.0 and offsetRotZ <= 90.0) or (offsetRotZ <= 0.0 and offsetRotZ >= -90.0)) then
                multCoordX = 1.0 - (math.abs(offsetRotZ) / 90)
                multCoordY = - (offsetRotZ / 90)
            elseif ((offsetRotZ >= 90.0 and offsetRotZ <= 180.0) or (offsetRotZ <= -90.0 and offsetRotZ >= -180.0)) then
                if (offsetRotZ >= 90.0) then
                    multCoordX = - (offsetRotZ - 90.0) / 90
                    multCoordY = - (1.0 - (math.abs(offsetRotZ) - 90.0) / 90)
                else
                    multCoordX = (offsetRotZ + 90.0) / 90
                    multCoordY = 1.0 - ((math.abs(offsetRotZ) - 90.0) / 90)
                end
            elseif ((offsetRotZ >= 180.0 and offsetRotZ <= 270.0) or (offsetRotZ <= -180.0 and offsetRotZ >= -270.0)) then
                if (offsetRotZ >= 180.0) then
                    multCoordX = - (1.0 - ((offsetRotZ - 180.0) / 90))
                    multCoordY = (math.abs(offsetRotZ) - 180.0) / 90
                else
                    multCoordX = - (1.0 + (offsetRotZ + 180.0) / 90)
                    multCoordY = - (math.abs(offsetRotZ) - 180.0) / 90
                end
            elseif ((offsetRotZ >= 270.0 and offsetRotZ <= 360.0) or (offsetRotZ <= -270.0 and offsetRotZ >= -360.0)) then
                if (offsetRotZ >= 270.0) then
                    multCoordX = (offsetRotZ - 270.0) / 90
                    multCoordY = 1.0 - (math.abs(offsetRotZ) - 270.0) / 90
                else
                    multCoordX = - (offsetRotZ + 270.0) / 90
                    multCoordY = - (1.0 - ((math.abs(offsetRotZ) - 270.0) / 90))
                end
            end

            x = x - (0.1 * ActualSpeed * multCoordX)
            y = y + (0.1 * ActualSpeed * multCoordY)
        end
        if (IsDisabledControlPressed(1, ConfigCamera.Bind.Right)) then -- D
            local multCoordY = 0.0
            local multCoordX = 0.0
            if ((offsetRotZ >= 0.0 and offsetRotZ <= 90.0) or (offsetRotZ <= 0.0 and offsetRotZ >= -90.0)) then
                multCoordX = 1.0 - (math.abs(offsetRotZ) / 90)
                multCoordY = - (offsetRotZ / 90)
            elseif ((offsetRotZ >= 90.0 and offsetRotZ <= 180.0) or (offsetRotZ <= -90.0 and offsetRotZ >= -180.0)) then
                if (offsetRotZ >= 90.0) then
                    multCoordX = - (offsetRotZ - 90.0) / 90
                    multCoordY = - (1.0 - (math.abs(offsetRotZ) - 90.0) / 90)
                else
                    multCoordX = (offsetRotZ + 90.0) / 90
                    multCoordY = 1.0 - ((math.abs(offsetRotZ) - 90.0) / 90)
                end
            elseif ((offsetRotZ >= 180.0 and offsetRotZ <= 270.0) or (offsetRotZ <= -180.0 and offsetRotZ >= -270.0)) then
                if (offsetRotZ >= 180.0) then
                    multCoordX = - (1.0 - ((offsetRotZ - 180.0) / 90))
                    multCoordY = (math.abs(offsetRotZ) - 180.0) / 90
                else
                    multCoordX = - (1.0 + (offsetRotZ + 180.0) / 90)
                    multCoordY = - (math.abs(offsetRotZ) - 180.0) / 90
                end
            elseif ((offsetRotZ >= 270.0 and offsetRotZ <= 360.0) or (offsetRotZ <= -270.0 and offsetRotZ >= -360.0)) then
                if (offsetRotZ >= 270.0) then
                    multCoordX = (offsetRotZ - 270.0) / 90
                    multCoordY = 1.0 - (math.abs(offsetRotZ) - 270.0) / 90
                else
                    multCoordX = - (offsetRotZ + 270.0) / 90
                    multCoordY = - (1.0 - ((math.abs(offsetRotZ) - 270.0) / 90))
                end
            end

            x = x + (0.1 * ActualSpeed * multCoordX)
            y = y - (0.1 * ActualSpeed * multCoordY)
        end
        if (IsDisabledControlPressed(1, ConfigCamera.Bind.UP)) then -- SHIFT
            z = z + (0.1 * ActualSpeed)
        end
        if (IsDisabledControlPressed(1, ConfigCamera.Bind.Down)) then -- LEFT CTRL
            z = z - (0.1 * ActualSpeed)
        end
        if (IsDisabledControlPressed(1, ConfigCamera.Bind.Pivot2)) then -- Q
            offsetRotY = offsetRotY - (1.0 * ActualSpeed)
        end
        if (IsDisabledControlPressed(1, ConfigCamera.Bind.Pivot1)) then -- E
            offsetRotY = offsetRotY + (1.0 * ActualSpeed)
        end
        
        SetFocusArea(x, y, z, 0.0, 0.0, 0.0)
        SetCamCoord(cam, x, y, z)
    end

    if (isAttached) then
        SetCamRot(cam, rotX+offsetRotX, rotY+offsetRotY, rotZ+offsetRotZ, 2)
    else
        SetCamRot(cam, offsetRotX, offsetRotY, offsetRotZ, 2)
    end
end

--Gestion des perms
CreateThread(function()
    TriggerServerEvent('CorePickax:receivePermissions')

    while (whitelisted == nil) do
        Citizen.Wait(1000)
    end
end)

RegisterNetEvent('CorePickax:receivePermissions', function(isWhitelisted)
    whitelisted = isWhitelisted
end)

local Activeisai = false
RegisterKeyMapping(ConfigCamera.Commande.CommandeName, ConfigCamera.Commande.Desc, 'keyboard', ConfigCamera.Commande.Bind)
RegisterCommand(ConfigCamera.Commande.CommandeName, function()
    if ConfigCamera.AllowPlayerAndStaff then
        if not whitelisted then
            isAttached = true
        else
            if ConfigCamera.MaxDistanceForStaff ~= false then
                isAttached = true
            end
        end

        if not Activeisai then
            Activeisai = true
            StartFreeCam(50)
        else
            Activeisai = false
            EndFreeCam()
        end
    else
        if whitelisted then
            if ConfigCamera.MaxDistanceForStaff ~= false then
                isAttached = true
            end

            if not Activeisai then
                Activeisai = true
                StartFreeCam(50)
            else
                Activeisai = false
                EndFreeCam()
            end
        end
    end
end)