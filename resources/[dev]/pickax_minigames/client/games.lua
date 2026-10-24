-- Moteurs de jeu côté client : shoot (basket / football), rally (tennis), fight (boxe), tag (paintball / laser game), race (course)

local G = -vector3(0.0, 0.0, 9.81)   -- gravité GTA

local function dot(a, b) return a.x * b.x + a.y * b.y + a.z * b.z end

-- SetEntityVelocity attend trois nombres (pas un vector3) ; appliquée deux fois pour survivre au détachement de la main
local function setVel(e, v)
    if not DoesEntityExist(e) then return end
    SetEntityVelocity(e, v.x + 0.0, v.y + 0.0, v.z + 0.0)
    SetTimeout(60, function() if DoesEntityExist(e) then SetEntityVelocity(e, v.x + 0.0, v.y + 0.0, v.z + 0.0) end end)
end

local function V(c) return vector3(c.x + 0.0, c.y + 0.0, (c.z or 0.0) + 0.0) end

local function loadModel(name)
    local h = type(name) == 'number' and name or GetHashKey(name)
    if not IsModelInCdimage(h) then return nil end
    RequestModel(h)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(h) and GetGameTimer() < t do Wait(20) end
    return HasModelLoaded(h) and h or nil
end

local function hint(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

local function fade(out, ms)
    if out then DoScreenFadeOut(ms or 300) while not IsScreenFadedOut() do Wait(10) end
    else DoScreenFadeIn(ms or 300) end
end

local function teleport(c)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local ent = veh ~= 0 and veh or ped
    SetEntityCoords(ent, c.x + 0.0, c.y + 0.0, c.z + 0.0, false, false, false, false)
    SetEntityHeading(ent, (c.h or 0.0) + 0.0)
end

local function camDir()
    local rot = GetGameplayCamRot(2)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local c = math.abs(math.cos(rx))
    return vector3(-math.sin(rz) * c, math.cos(rz) * c, math.sin(rx))
end

-- Vitesse initiale pour joindre `to` depuis `from` en `T` secondes
local function ballistic(from, to, T)
    return (to - from - G * (0.5 * T * T)) / T
end

-- Zone la plus proche du rayon de visée de la caméra
local function aimZone(zones, from)
    local cam, dir = GetGameplayCamCoord(), camDir()
    local best, bd
    for _, z in ipairs(zones or {}) do
        local zc = V(z)
        local t = #((zc - cam)) > 0 and dot(zc - cam, dir) or 0.0
        local closest = cam + dir * math.max(t, 0.0)
        local d = #(zc - closest)
        if not bd or d < bd then best, bd = z, d end
    end
    return best
end

local function randomOffset(mag)
    local a = math.random() * math.pi * 2
    local m = mag * math.sqrt(math.random())
    return vector3(math.cos(a) * m, math.sin(a) * m, (math.random() - 0.5) * mag * 0.4)
end

local function deleteEnt(e)
    if e and DoesEntityExist(e) then SetEntityAsMissionEntity(e, true, true) DeleteEntity(e) end
end

local function center(s)
    local p = s.points
    return p.center or (p.spawns and p.spawns[1]) or p.lobby
end

-- ─── Session ─────────────────────────────────────────────────────────────────
function MGC.begin(d)
    if MGC.session then MGC.cleanup(true) end
    local s = {
        id = d.id, type = d.type, engine = d.engine, name = d.name, team = d.team, settings = d.settings, points = d.points,
        spawn = d.spawn, slot = d.slot, running = false, props = {}, hud = nil, shots = 0,
    }
    MGC.session = s
    MGC.joined = d.id
    local ped = PlayerPedId()
    fade(true, 350)
    teleport(d.spawn)
    s.prevInvincible = GetPlayerInvincible(PlayerId())
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    for _, o in ipairs(MGC.spawnProps({ props = d.props }, 'match')) do s.props[#s.props + 1] = o end
    local E = MGC.engines[s.engine]
    if E and E.prepare then E.prepare(s) end
    SendNUIMessage({ action = 'begin', name = s.name, engine = s.engine, type = s.type, team = s.team, countdown = d.countdown, theme = d.uiColor })
    Wait(250)
    fade(false, 400)

    -- compte à rebours (côté serveur : durée totale ; ici affichage)
    CreateThread(function()
        local n = d.countdown
        while MGC.session == s and not s.running and n > 0 do
            SendNUIMessage({ action = 'count', n = n })
            Wait(1000)
            n = n - 1
        end
    end)

    -- boucle de jeu
    CreateThread(function()
        local lastSlow = 0
        while MGC.session == s do
            Wait(0)
            local ped = PlayerPedId()
            if s.running and E and E.tick then E.tick(s, ped) end
            if E and E.always then E.always(s, ped) end
            local t = GetGameTimer()
            if t - lastSlow > 500 then
                lastSlow = t
                -- limite de l'arène
                if s.running and s.engine ~= 'race' and not s.down then
                    local c = center(s)
                    if c and #(GetEntityCoords(ped) - V(c)) > (s.settings.arenaRadius or 40.0) then
                        teleport(s.spawn)
                        ESX.ShowNotification('~o~Tu ne peux pas quitter l\'arène.')
                    end
                end
            end
        end
    end)
end

function MGC.go()
    local s = MGC.session
    if not s then return end
    s.running = true
    FreezeEntityPosition(PlayerPedId(), false)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then FreezeEntityPosition(veh, false) end
    local E = MGC.engines[s.engine]
    if E and E.start then E.start(s) end
    SendNUIMessage({ action = 'go' })
end

function MGC.cleanup(skipReturn)
    local s = MGC.session
    if not s then return end
    MGC.session = nil
    local ped = PlayerPedId()
    local E = MGC.engines[s.engine]
    if E and E.stop then pcall(E.stop, s) end
    for _, e in ipairs(s.props) do deleteEnt(e) end
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetPlayerWeaponDamageModifier(PlayerId(), 1.0)
    ClearPedTasks(ped)
    SendNUIMessage({ action = 'meter', show = false })
    if not skipReturn and s.points.lobby then
        fade(true, 300)
        teleport(s.points.lobby)
        Wait(200)
        fade(false, 400)
    end
end

function MGC.finish(d)
    local s = MGC.session
    SendNUIMessage({ action = 'end', data = d })
    MGC.joined = nil
    if not s then return end
    s.running = false
    local E = MGC.engines[s.engine]
    if E and E.stop then pcall(E.stop, s) end
    SetTimeout((d.ret or Config.ReturnAfterEnd) * 1000, function()
        if MGC.session == s then MGC.cleanup(false) end
    end)
end

function MGC.down(d)
    local s = MGC.session
    if not s then return end
    s.down = true
    local ped = PlayerPedId()
    SetPedToRagdoll(ped, 1500, 1500, 0, false, false, false)
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.2)
    SendNUIMessage({ action = 'down', by = d.by, secs = d.secs })
end

function MGC.respawn(sp)
    local s = MGC.session
    if not s then return end
    s.down = false
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    teleport(sp or s.spawn)
    SendNUIMessage({ action = 'respawn' })
    local E = MGC.engines[s.engine]
    if E and E.respawn then E.respawn(s) end
end

function MGC.hurt(d)
    local s = MGC.session
    if not s then return end
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.12)
    if d.ko then SetPedToRagdoll(PlayerPedId(), 2500, 2500, 0, false, false, false) end
    SendNUIMessage({ action = 'hurt', hp = d.hp, dmg = d.dmg })
end

function MGC.onHud(h)
    local s = MGC.session
    if not s then return end
    s.hud = h
    local E = MGC.engines[s.engine]
    if E and E.hud then E.hud(s, h) end
end

local function myRow(s)
    if not s.hud then return nil end
    for _, r in ipairs(s.hud.rows or {}) do if r.src == s.hud.me then return r end end
end

-- ─── shoot : basket / football ────────────────────────────────────────────────
local function meterValue(speed)
    local t = (GetGameTimer() / 1000.0) * speed
    local f = t % 2.0
    return f < 1.0 and f or 2.0 - f
end

local shoot = {}

local function shootSpawnBall(s)
    local S = s.settings
    local model = loadModel(S.ballModel)
    if not model then return end
    local ped = PlayerPedId()
    local pos
    if S.holdBall then pos = GetPedBoneCoords(ped, 28422, 0.0, 0.0, 0.0)
    elseif s.points.ball then pos = V(s.points.ball)
    else pos = GetEntityCoords(ped) + GetEntityForwardVector(ped) * 1.2 end
    local b = CreateObject(model, pos.x, pos.y, pos.z + (S.holdBall and 0.0 or 0.15), true, true, false)
    SetEntityAsMissionEntity(b, true, true)
    if S.holdBall then
        AttachEntityToEntity(b, ped, GetPedBoneIndex(ped, 28422), 0.12, 0.04, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    else
        FreezeEntityPosition(b, true)
    end
    s.props[#s.props + 1] = b
    s.ball = b
end

function shoot.prepare(s)
    s.shotsDone, s.charging, s.cool = 0, false, 0
end

function shoot.start(s)
    shootSpawnBall(s)
    SendNUIMessage({ action = 'hint', text = 'Maintiens E pour charger · relâche dans la zone verte' })
end

function shoot.respawn(s) if s.running and (not s.ball or not DoesEntityExist(s.ball)) then shootSpawnBall(s) end end

local function launch(s, ball, ped, level)
    local S = s.settings
    local from = GetEntityCoords(ball)
    local target, T
    local hoop = s.points.hoop
    if S.targetKind == 'hoop' and hoop then
        target = V(hoop)
        T = math.min(2.2, math.max(0.9, #(target - from) * 0.1 + 0.75))
    else
        local z = aimZone(s.points.zones, from)
        target = z and V(z) or (from + camDir() * 20.0)
        T = math.min(1.6, math.max(0.45, #(target - from) * 0.03 + 0.4))
        s.targetZone = z
    end
    -- précision : 0 dans la zone verte, 1 tout au bord de la jauge
    local sweet = S.sweet or 0.15
    local err = math.max(0.0, math.abs(level - 0.5) - sweet / 2) / math.max(0.01, 0.5 - sweet / 2)
    target = target + randomOffset((S.scatter or 1.5) * err)
    if DoesEntityExist(ball) then
        DetachEntity(ball, true, true)
        SetEntityNoCollisionEntity(ball, ped, false)   -- le ballon ne rebondit pas sur toi à la sortie de la main
        FreezeEntityPosition(ball, false)
        SetEntityDynamic(ball, true)
        ActivatePhysics(ball)
        SetEntityHasGravity(ball, true)
        setVel(ball, ballistic(from, target, T))
    end
    return from, target
end

function shoot.tick(s, ped)
    local S = s.settings
    DisableControlAction(0, 24, true) DisableControlAction(0, 25, true) DisableControlAction(0, 140, true) DisableControlAction(0, 141, true)
    local t = GetGameTimer()
    -- vol de balle en cours
    local f = s.flight
    if f then
        local pos = GetEntityCoords(f.ball)
        if not f.scored then
            if S.targetKind == 'hoop' and s.points.hoop then
                local h = s.points.hoop
                if f.prev.z > h.z and pos.z <= h.z + 0.05 and #(vector3(pos.x, pos.y, 0.0) - vector3(h.x, h.y, 0.0)) <= S.hoopRadius then
                    f.scored = true
                    local pts = #(V(f.origin) - V(h)) >= S.threeDist and S.points3 or S.points2
                    TriggerServerEvent('minigames:score', pts)
                end
            else
                for _, z in ipairs(s.points.zones or {}) do
                    if #(pos - V(z)) <= (z.r or 1.0) then
                        f.scored = true
                        TriggerServerEvent('minigames:score', z.pts or 1)
                        break
                    end
                end
            end
        end
        f.prev = pos
        if t - f.t0 > 3800 or not DoesEntityExist(f.ball) then
            deleteEnt(f.ball)
            s.flight = nil
            s.cool = t + 600
            s.shotsDone = s.shotsDone + 1
            if S.balls and s.shotsDone >= S.balls then TriggerServerEvent('minigames:done') return end
            shootSpawnBall(s)
        end
        return
    end
    if not s.ball or not DoesEntityExist(s.ball) or t < s.cool then return end
    if IsDisabledControlJustPressed(0, 38) or IsControlJustPressed(0, 38) then s.charging = true end
    if s.charging then
        local m = meterValue(S.meterSpeed or 1.1)
        SendNUIMessage({ action = 'meter', show = true, v = m, sweet = S.sweet or 0.15 })
        if IsControlJustReleased(0, 38) or not IsControlPressed(0, 38) then
            s.charging = false
            SendNUIMessage({ action = 'meter', show = false })
            local from = launch(s, s.ball, ped, m)
            TriggerServerEvent('minigames:shot')
            s.flight = { ball = s.ball, t0 = t, prev = from, origin = from }
            s.ball = nil
        end
    end
end

function shoot.stop(s) SendNUIMessage({ action = 'meter', show = false }) end

-- ─── rally : tennis ───────────────────────────────────────────────────────────
local rally = {}

function rally.prepare(s) s.fed, s.nextFeed, s.balls = 0, 0, {} end

function rally.start(s)
    s.nextFeed = GetGameTimer() + 1500
    SendNUIMessage({ action = 'hint', text = 'Appuie sur E quand la balle est près de toi · vise avec la caméra' })
end

local function rallyFeed(s, ped)
    local S = s.settings
    local model = loadModel(S.ballModel)
    if not model or not s.points.machine then return end
    local m = V(s.points.machine)
    local b = CreateObject(model, m.x, m.y, m.z + 1.0, true, true, false)
    SetEntityAsMissionEntity(b, true, true)
    s.props[#s.props + 1] = b
    SetEntityDynamic(b, true) ActivatePhysics(b) SetEntityHasGravity(b, true)
    local p = GetEntityCoords(ped)
    local target = vector3(p.x, p.y, p.z + 0.4) + randomOffset(1.6)
    setVel(b, ballistic(m + vector3(0.0, 0.0, 1.0), target, S.feedTime))
    s.balls[#s.balls + 1] = { e = b, t0 = GetGameTimer(), hit = false, scored = false, prev = m }
    s.fed = s.fed + 1
    TriggerServerEvent('minigames:shot')
end

function rally.tick(s, ped)
    local S = s.settings
    DisableControlAction(0, 24, true) DisableControlAction(0, 25, true)
    local t = GetGameTimer()
    if s.fed < S.balls and t >= s.nextFeed then
        s.nextFeed = t + S.feedInterval * 1000
        rallyFeed(s, ped)
    end
    local pressed = IsControlJustPressed(0, 38)
    local pp = GetEntityCoords(ped) + vector3(0.0, 0.0, 0.3)
    for i = #s.balls, 1, -1 do
        local b = s.balls[i]
        if not DoesEntityExist(b.e) then table.remove(s.balls, i)
        else
            local pos = GetEntityCoords(b.e)
            if not b.hit and pressed and #(pos - pp) <= S.hitRadius then
                b.hit = true
                local acc = 1.0 - math.min(1.0, #(pos - pp) / S.hitRadius)
                local z = aimZone(s.points.zones, pos)
                local target = z and V(z) or (pos + camDir() * 18.0)
                target = target + randomOffset((S.scatter or 3.0) * (1.0 - acc))
                setVel(b.e, ballistic(pos, target, S.returnTime))
                PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
                b.t0 = t
            end
            if b.hit and not b.scored then
                for _, z in ipairs(s.points.zones or {}) do
                    local zc = V(z)
                    if #(vector3(pos.x, pos.y, 0.0) - vector3(zc.x, zc.y, 0.0)) <= (z.r or 2.0) and pos.z <= zc.z + 0.45 then
                        b.scored = true
                        TriggerServerEvent('minigames:score', z.pts or 1)
                        break
                    end
                end
            end
            if t - b.t0 > 5500 or (b.hit and b.scored and t - b.t0 > 2500) then
                deleteEnt(b.e)
                table.remove(s.balls, i)
            end
        end
    end
    if s.fed >= S.balls and #s.balls == 0 and not s.doneSent then
        s.doneSent = true
        TriggerServerEvent('minigames:done')
    end
end

-- ─── fight : boxe ─────────────────────────────────────────────────────────────
local fight = {}
local unarmed = GetHashKey('WEAPON_UNARMED')

function fight.prepare(s)
    s.lastPunch = 0
    SetCurrentPedWeapon(PlayerPedId(), unarmed, true)
end

function fight.respawn(s)
    FreezeEntityPosition(PlayerPedId(), false)
end

function fight.tick(s, ped)
    local S = s.settings
    DisableControlAction(0, 25, true)
    if GetSelectedPedWeapon(ped) ~= unarmed then SetCurrentPedWeapon(ped, unarmed, true) end
    local h = s.hud
    local rs = h and h.extra and h.extra.roundState
    if rs == 'break' then return end
    if (IsControlJustPressed(0, 24) or IsControlJustPressed(0, 140) or IsControlJustPressed(0, 141)) and not s.down then
        local t = GetGameTimer()
        if t - s.lastPunch < (S.hitDelay or 350) then return end
        s.lastPunch = t
        local pp, fw = GetEntityCoords(ped), GetEntityForwardVector(ped)
        SetTimeout(180, function()
            for _, r in ipairs((s.hud and s.hud.rows) or {}) do
                if r.src ~= s.hud.me then
                    local pl = GetPlayerFromServerId(r.src)
                    if pl ~= -1 then
                        local op = GetPlayerPed(pl)
                        local d = GetEntityCoords(op) - GetEntityCoords(PlayerPedId())
                        if #d < 1.9 and dot(d, fw) / math.max(#d, 0.01) > 0.2 then
                            TriggerServerEvent('minigames:fightHit', r.src)
                            return
                        end
                    end
                end
            end
        end)
    end
end

-- ─── tag : paintball / laser game ─────────────────────────────────────────────
local tag = {}

-- ox_inventory retire toute arme qui n'est pas dans l'inventaire : on suspend ce contrôle pendant la partie
local function oxWheel(state)
    if GetResourceState('ox_inventory') == 'started' then pcall(function() exports.ox_inventory:weaponWheel(state) end) end
end

function tag.prepare(s)
    local ped = PlayerPedId()
    oxWheel(true)
    s.weaponHash = GetHashKey(s.settings.weapon)
    GiveWeaponToPed(ped, s.weaponHash, 9999, false, true)
    SetPedInfiniteAmmo(ped, true, s.weaponHash)
    SetPlayerWeaponDamageModifier(PlayerId(), 0.0)
    local tint = s.settings.tint
    if tint == 'team' then tint = s.team and Config.TeamTints[s.team] or 0 end
    SetPedWeaponTintIndex(ped, s.weaponHash, tonumber(tint) or 0)
    SetCurrentPedWeapon(ped, s.weaponHash, true)
    s.lastShot = 0
end

function tag.stop(s)
    local ped = PlayerPedId()
    oxWheel(false)
    SetPedInfiniteAmmo(ped, false, s.weaponHash or 0)
    RemoveWeaponFromPed(ped, s.weaponHash or 0)
    SetPlayerWeaponDamageModifier(PlayerId(), 1.0)
end

function tag.respawn(s)
    local ped = PlayerPedId()
    if not HasPedGotWeapon(ped, s.weaponHash, false) then GiveWeaponToPed(ped, s.weaponHash, 9999, false, true) end
    SetCurrentPedWeapon(ped, s.weaponHash, true)
end

function tag.always(s, ped)
    -- l'arme reste en main (aucun script ne doit la retirer pendant la partie)
    local nowT = GetGameTimer()
    if s.running and not s.down and nowT - (s.weaponCheck or 0) > 700 then
        s.weaponCheck = nowT
        if not HasPedGotWeapon(ped, s.weaponHash, false) then GiveWeaponToPed(ped, s.weaponHash, 9999, false, true) end
        if GetSelectedPedWeapon(ped) ~= s.weaponHash then SetCurrentPedWeapon(ped, s.weaponHash, true) end
        SetPedCurrentWeaponVisible(ped, true, false, false, false)
    end
    -- éclaboussures de peinture
    local now = GetGameTimer()
    local life = Config.Splat.life * 1000
    local list = MGC.splats
    for i = #list, 1, -1 do
        local sp = list[i]
        local age = now - sp.t
        if age > life then table.remove(list, i)
        else
            local a = age > life - 4000 and math.floor(220 * (life - age) / 4000) or 220
            DrawMarker(28, sp.x, sp.y, sp.z, 0, 0, 0, 0, 0, 0, 0.32, 0.32, 0.12, sp.r, sp.g, sp.b, a, false, false, 2, false, nil, nil, false)
        end
    end
    -- marqueur d'équipe au-dessus des autres joueurs
    local h = s.hud
    if not h or not h.extra or not h.extra.teams then return end
    local col = Config.TeamColors
    for _, r in ipairs(h.rows or {}) do
        if r.src ~= h.me and r.team then
            local pl = GetPlayerFromServerId(r.src)
            if pl ~= -1 then
                local p = GetPlayerPed(pl)
                local c = GetEntityCoords(p)
                if #(c - GetEntityCoords(ped)) < 70.0 then
                    local k = col[r.team] or col[1]
                    DrawMarker(2, c.x, c.y, c.z + 1.15, 0, 0, 0, 180.0, 0, 0, 0.22, 0.22, 0.22, k[1], k[2], k[3], 220, false, true, 2, false, nil, nil, false)
                end
            end
        end
    end
end

function tag.tick(s, ped)
    if s.down then
        DisableControlAction(0, 24, true) DisableControlAction(0, 25, true)
        return
    end
    if IsPedShooting(ped) then
        local t = GetGameTimer()
        if t - s.lastShot < (s.settings.fireDelay or 200) then return end
        s.lastShot = t
        local from = GetGameplayCamCoord()
        local to = from + camDir() * (s.settings.hitRange or 60.0)
        local h = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, 1 + 4 + 8, ped, 0)
        local _, hit, endC, _, ent = GetShapeTestResult(h)
        if hit == 1 and s.settings.splat then TriggerServerEvent('minigames:splat', endC.x, endC.y, endC.z) end
        if hit == 1 and ent ~= 0 and IsEntityAPed(ent) and IsPedAPlayer(ent) then
            local idx = NetworkGetPlayerIndexFromPed(ent)
            if idx and idx ~= -1 then TriggerServerEvent('minigames:tagHit', GetPlayerServerId(idx)) end
        end
    end
end

-- ─── race : course ────────────────────────────────────────────────────────────
local race = {}

function race.prepare(s)
    local S = s.settings
    s.cp, s.lastCp, s.blip = 0, 0, nil
    if S.vehicle and S.vehicle ~= '' then
        local model = loadModel(S.vehicle)
        if model then
            local c = s.spawn
            local veh = CreateVehicle(model, c.x + 0.0, c.y + 0.0, c.z + 0.0, (c.h or 0.0) + 0.0, true, false)
            SetEntityAsMissionEntity(veh, true, true)
            SetPedIntoVehicle(PlayerPedId(), veh, -1)
            FreezeEntityPosition(veh, true)
            SetVehicleDoorsLocked(veh, 4)
            s.props[#s.props + 1] = veh
            s.veh = veh
        end
    end
end

local function raceBlip(s, idx)
    if s.blip then RemoveBlip(s.blip) s.blip = nil end
    local c = s.points.checkpoints[idx]
    if not c then return end
    s.blip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(s.blip, 1)
    SetBlipColour(s.blip, 5) SetBlipScale(s.blip, 0.5)
    SetBlipRoute(s.blip, true)
end

function race.start(s) raceBlip(s, 1) end

function race.hud(s, h)
    local r = myRow(s)
    if r then
        s.cp = r.cp or 0
        local N = #s.points.checkpoints
        if N > 0 then raceBlip(s, (s.cp % N) + 1) end
    end
end

function race.stop(s)
    if s.blip then RemoveBlip(s.blip) s.blip = nil end
end

function race.tick(s, ped)
    local cps = s.points.checkpoints
    local N = #cps
    if N == 0 then return end
    local r = myRow(s)
    if r and r.finished then return end
    local idx = (s.cp % N) + 1
    local c = cps[idx]
    local nxt = cps[(idx % N) + 1]
    local rad = (c.r or s.settings.cpRadius) + 0.0
    DrawMarker(1, c.x, c.y, c.z - 1.0, 0, 0, 0, 0, 0, 0, rad * 2, rad * 2, 4.0, 253, 194, 125, 110, false, false, 2, false, nil, nil, false)
    if nxt and (idx % N) + 1 ~= idx then
        DrawMarker(1, nxt.x, nxt.y, nxt.z - 1.0, 0, 0, 0, 0, 0, 0, (nxt.r or rad) * 2, (nxt.r or rad) * 2, 4.0, 255, 255, 255, 40, false, false, 2, false, nil, nil, false)
    end
    local ent = s.veh and DoesEntityExist(s.veh) and s.veh or ped
    local p = GetEntityCoords(ent)
    if #(p - V(c)) <= rad + 1.5 then
        local t = GetGameTimer()
        if t - s.lastCp > 400 then
            s.lastCp = t
            TriggerServerEvent('minigames:cp', idx)
            PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
        end
    end
end


-- ─── bowling ──────────────────────────────────────────────────────────────────
local bowling = {}

local function bwPins(s)
    local S = s.settings
    for _, pin in ipairs(s.pins or {}) do deleteEnt(pin.e) end
    s.pins = {}
    local model = loadModel(S.pinModel)
    if not model or not s.points.pinhead or not s.points.ball then return end
    local head, start = V(s.points.pinhead), V(s.points.ball)
    local d = vector3(head.x - start.x, head.y - start.y, 0.0)
    local len = #d
    if len < 0.01 then d = vector3(0.0, 1.0, 0.0) else d = d / len end
    local right = vector3(d.y, -d.x, 0.0)
    local sp = S.pinSpacing or 0.32
    for r = 0, 3 do
        for i = 0, r do
            local pos = head + d * (r * sp * 0.9) + right * ((i - r / 2.0) * sp)
            local e = CreateObject(model, pos.x, pos.y, pos.z, true, true, false)
            SetEntityAsMissionEntity(e, true, true)
            PlaceObjectOnGroundProperly(e)
            FreezeEntityPosition(e, true)
            s.pins[#s.pins + 1] = { e = e, o = GetEntityCoords(e), down = false }
            s.props[#s.props + 1] = e
        end
    end
end

local function bwHint(s, text) SendNUIMessage({ action = 'hint', text = text }) end

function bowling.prepare(s) s.frame, s.throw, s.phase, s.cool, s.frameKnocked, s.charging = 1, 1, 'ready', 0, 0, false end

function bowling.start(s)
    bwPins(s)
    bwHint(s, ('Frame 1/%d · maintiens E pour charger, relâche dans la zone verte'):format(s.settings.frames))
end

local function bwKnocked(pin)
    if not DoesEntityExist(pin.e) then return true end
    local c = GetEntityCoords(pin.e)
    return math.abs(GetEntityPitch(pin.e)) > 35.0 or math.abs(GetEntityRoll(pin.e)) > 35.0
        or #(vector3(c.x, c.y, 0.0) - vector3(pin.o.x, pin.o.y, 0.0)) > 0.45
end

function bowling.tick(s, ped)
    local S = s.settings
    DisableControlAction(0, 24, true) DisableControlAction(0, 25, true)
    local t = GetGameTimer()
    if s.phase == 'rolling' then
        if t - s.rollT0 < 5500 then return end
        deleteEnt(s.ball)
        local k = 0
        for _, pin in ipairs(s.pins) do
            if not pin.down and bwKnocked(pin) then pin.down = true; k = k + 1; deleteEnt(pin.e) end
        end
        s.frameKnocked = s.frameKnocked + k
        local pts = k
        local frameOver = false
        if s.throw == 1 and s.frameKnocked >= 10 then pts = pts + (S.strikeBonus or 0); frameOver = true; bwHint(s, 'STRIKE !')
        elseif s.throw == 2 then
            if s.frameKnocked >= 10 then pts = pts + (S.spareBonus or 0); bwHint(s, 'SPARE !') end
            frameOver = true
        end
        if pts > 0 then TriggerServerEvent('minigames:score', pts) elseif k == 0 then bwHint(s, 'Raté…') end
        if frameOver then
            s.frame, s.throw, s.frameKnocked = s.frame + 1, 1, 0
            if s.frame > S.frames then s.phase = 'done'; TriggerServerEvent('minigames:done') return end
            bwPins(s)
            Wait(1200)
            bwHint(s, ('Frame %d/%d'):format(s.frame, S.frames))
        else
            s.throw = 2
            bwHint(s, ('Frame %d/%d · deuxième lancer'):format(s.frame, S.frames))
        end
        s.phase, s.cool = 'ready', t + 500
        return
    end
    if s.phase ~= 'ready' or t < s.cool then return end
    if IsControlJustPressed(0, 38) then s.charging = true end
    if s.charging then
        local m = meterValue(S.meterSpeed or 1.2)
        SendNUIMessage({ action = 'meter', show = true, v = m, sweet = S.sweet or 0.2 })
        if IsControlJustReleased(0, 38) or not IsControlPressed(0, 38) then
            s.charging = false
            SendNUIMessage({ action = 'meter', show = false })
            local model = loadModel(S.ballModel)
            if not model or not s.points.ball or not s.points.pinhead then return end
            local b0, head = V(s.points.ball), V(s.points.pinhead)
            local d = vector3(head.x - b0.x, head.y - b0.y, 0.0)
            d = d / math.max(#d, 0.01)
            local sweet = S.sweet or 0.2
            local err = math.max(0.0, math.abs(m - 0.5) - sweet / 2) / math.max(0.01, 0.5 - sweet / 2)
            local ang = math.rad((m < 0.5 and -1 or 1) * err * (S.scatter or 7.0))
            local c, sn = math.cos(ang), math.sin(ang)
            local v = vector3(d.x * c - d.y * sn, d.x * sn + d.y * c, 0.0) * (S.rollSpeed or 13.0)
            local ball = CreateObject(model, b0.x, b0.y, b0.z + 0.15, true, true, false)
            SetEntityAsMissionEntity(ball, true, true)
            SetEntityDynamic(ball, true) ActivatePhysics(ball) SetEntityHasGravity(ball, true)
            SetEntityVelocity(ball, v.x, v.y, 0.0)
            s.props[#s.props + 1] = ball
            s.ball = ball
            for _, pin in ipairs(s.pins) do if DoesEntityExist(pin.e) then FreezeEntityPosition(pin.e, false) ActivatePhysics(pin.e) end end
            s.phase, s.rollT0 = 'rolling', t
            TriggerServerEvent('minigames:shot')
        end
    end
end

function bowling.stop(s) SendNUIMessage({ action = 'meter', show = false }) end

MGC.engines = { bowling = bowling, shoot = shoot, rally = rally, fight = fight, tag = tag, race = race }
