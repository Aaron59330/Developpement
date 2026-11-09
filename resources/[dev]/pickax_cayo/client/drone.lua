local C = Config
local function dot(a, b) return a.x * b.x + a.y * b.y + a.z * b.z end

-- Drone de reconnaissance : survole l'île depuis le poste de planification. ZQSD/WASD pour avancer, souris pour viser, Espace / Ctrl : monter / descendre,
-- Maj : accélérer, G : marquer le repère visé, Retour arrière : quitter. Tous les repères doivent être marqués.
local flying = false

function RunDrone(scope)
    if flying then return false end
    flying = true
    TriggerEvent('pickax_cayo:forceIsland', true)
    DoScreenFadeOut(400) Wait(500)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    local v = scope.view
    local start = vec3(v.x, v.y, v.z)
    local pos, heading, pitch = start, v.w, -30.0
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, pos.x, pos.y, pos.z) SetCamRot(cam, pitch, 0.0, heading, 2) SetCamFov(cam, 55.0)
    SetCamActive(cam, true) RenderScriptCams(true, false, 0, true, false)
    SetFocusPosAndVel(pos.x, pos.y, pos.z, 0.0, 0.0, 0.0)
    Wait(2500)
    DoScreenFadeIn(400)

    local D = C.Drone
    local tagged, count = {}, 0
    local t0 = GetGameTimer()
    local done = false
    while true do
        Wait(0)
        DisableAllControlActions(0)
        local left = D.seconds - (GetGameTimer() - t0) / 1000
        if left <= 0 or IsDisabledControlJustPressed(0, 177) or IsEntityDead(ped) then break end

        heading = heading - GetDisabledControlNormal(0, 1) * 7.0
        pitch = math.max(-89.0, math.min(89.0, pitch - GetDisabledControlNormal(0, 2) * 5.0))
        local hr, pr = math.rad(heading), math.rad(pitch)
        local fwd = vec3(-math.sin(hr), math.cos(hr), 0.0)
        local right = vec3(math.cos(hr), math.sin(hr), 0.0)
        local sp = (IsDisabledControlPressed(0, 21) and D.boost or D.speed) * GetFrameTime()
        if IsDisabledControlPressed(0, 32) then pos = pos + fwd * sp end
        if IsDisabledControlPressed(0, 33) then pos = pos - fwd * sp end
        if IsDisabledControlPressed(0, 34) then pos = pos - right * sp end
        if IsDisabledControlPressed(0, 35) then pos = pos + right * sp end
        if IsDisabledControlPressed(0, 22) then pos = vec3(pos.x, pos.y, pos.z + sp) end
        if IsDisabledControlPressed(0, 36) then pos = vec3(pos.x, pos.y, pos.z - sp) end
        local off = pos - start
        if #off > 320.0 then pos = start + off / #off * 320.0 end
        pos = vec3(pos.x, pos.y, math.max(12.0, math.min(220.0, pos.z)))
        SetCamCoord(cam, pos.x, pos.y, pos.z) SetCamRot(cam, pitch, 0.0, heading, 2)
        SetFocusPosAndVel(pos.x, pos.y, pos.z, 0.0, 0.0, 0.0)

        -- viseur
        DrawRect(0.5, 0.5, 0.0015, 0.03, 255, 255, 255, 200) DrawRect(0.5, 0.5, 0.012, 0.0027, 255, 255, 255, 200)
        local dir = vec3(-math.sin(hr) * math.cos(pr), math.cos(hr) * math.cos(pr), math.sin(pr))
        local inSight
        for i, t in ipairs(scope.targets) do
            local to = t[2] - pos
            local dist = #to
            local on, sx, sy = GetScreenCoordFromWorldCoord(t[2].x, t[2].y, t[2].z + 2.0)
            if on then
                local col = tagged[i] and { 63, 185, 80 } or { 240, 179, 35 }
                Hud(sx, sy - 0.02, (tagged[i] and '✔ ' or '') .. t[1] .. ('  %d m'):format(dist), 0.3, col[1], col[2], col[3], 'center')
            end
            if not tagged[i] and dist < D.tagRange and dot(to / dist, dir) > 0.985 then inSight = i end
        end
        if inSight then Hud(0.5, 0.53, '[G] Marquer : ' .. scope.targets[inSight][1], 0.4, 240, 179, 35, 'center') end
        if inSight and IsDisabledControlJustPressed(0, 47) then
            tagged[inSight] = true count = count + 1
            PlaySoundFrontend(-1, 'Beep_Green', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
            if count >= #scope.targets then done = true break end
        end
        Hud(0.04, 0.05, 'DRONE — ' .. scope.label, 0.5, 240, 179, 35)
        Hud(0.04, 0.095, ('Repères : %d / %d    Batterie : %d s'):format(count, #scope.targets, math.floor(left)), 0.38)
        Hud(0.04, 0.93, 'ZQSD : voler   Souris : viser   Espace / Ctrl : altitude   Maj : vitesse   G : marquer   Retour arrière : quitter', 0.3, 200, 200, 200)
    end

    DoScreenFadeOut(300) Wait(400)
    RenderScriptCams(false, false, 0, true, false) DestroyCam(cam, false) ClearFocus()
    FreezeEntityPosition(ped, false)
    TriggerEvent('pickax_cayo:forceIsland', false)
    Wait(300) DoScreenFadeIn(400)
    flying = false
    return done
end
