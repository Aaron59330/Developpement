-- ═══════════════════════════ Événements : partie client ═══════════════════════════
-- Affiche blips / zones / butin (props locaux), gère les interactions (percer, fouiller, ramasser, menacer le vendeur)
-- et configure les PNJ gardes dont le joueur est propriétaire réseau. Toute décision reste côté serveur.

local Runs, Defs = {}, {}
local Blips, Props, Clerks, Configured = {}, {}, {}, {}
local busy = false
local myServerId = GetPlayerServerId(PlayerId())
local GUARD_GROUP = joaat('EVT_GUARD')
local aimStart, triggeredAt = {}, {}

CreateThread(function()
    AddRelationshipGroup('EVT_GUARD')
    SetRelationshipBetweenGroups(5, GUARD_GROUP, joaat('PLAYER'))
    SetRelationshipBetweenGroups(5, joaat('PLAYER'), GUARD_GROUP)
    SetRelationshipBetweenGroups(0, GUARD_GROUP, GUARD_GROUP)
end)

-- ─────────────────────────────── Aides d'affichage ───────────────────────────────
local function help(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function text2d(x, y, msg, scale, r, g, b, centered)
    SetTextFont(4)
    SetTextScale(0.0, scale or 0.4)
    SetTextColour(r or 255, g or 255, b or 255, 235)
    SetTextOutline()
    if centered then SetTextCentre(true) end
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayText(x, y)
end

local function loadModel(name)
    local hash = type(name) == 'number' and name or joaat(name)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 4000 do Wait(20) end
    return HasModelLoaded(hash) and hash or nil
end

local function mmss(s)
    s = math.max(0, math.floor(s))
    return ('%d:%02d'):format(s // 60, s % 60)
end

-- Barre de progression : renvoie true si menée à terme (annulée si on s'éloigne, qu'on appuie sur X ou qu'on tombe)
local function progress(seconds, label, scenario)
    local ped = PlayerPedId()
    local start = GetEntityCoords(ped)
    local t0, total = GetGameTimer(), math.max(0.2, seconds) * 1000
    if scenario then TaskStartScenarioInPlace(ped, scenario, 0, true) end
    local ok = true
    while true do
        Wait(0)
        local k = (GetGameTimer() - t0) / total
        DrawRect(0.5, 0.92, 0.22, 0.022, 0, 0, 0, 170)
        DrawRect(0.5 - 0.11 + 0.11 * math.min(1.0, k), 0.92, 0.22 * math.min(1.0, k), 0.014, 0, 164, 255, 230)
        text2d(0.5, 0.885, label, 0.38, 255, 255, 255, true)
        text2d(0.5, 0.935, '~INPUT_VEH_DUCK~ annuler', 0.3, 200, 200, 200, true)
        DisableControlAction(0, 24, true)
        if k >= 1.0 then break end
        if IsControlJustPressed(0, 73) or IsEntityDead(ped) or IsPedRagdoll(ped) or #(GetEntityCoords(ped) - start) > 2.5 then ok = false break end
    end
    ClearPedTasks(ped)
    return ok
end

-- ─────────────────────────────── Blips ───────────────────────────────
local function removeBlips(rid)
    local b = Blips[rid]
    if not b then return end
    for _, h in pairs(b) do if type(h) == 'number' and DoesBlipExist(h) then RemoveBlip(h) end end
    Blips[rid] = nil
end

local function updateBlips(run)
    local bl = run.blip or {}
    local b = Blips[run.rid]
    if not b then b = {} Blips[run.rid] = b end
    if bl.enabled ~= false and not b.main then
        local c = run.coords
        b.main = AddBlipForCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
        SetBlipSprite(b.main, bl.sprite or 161)
        SetBlipColour(b.main, bl.color or 1)
        SetBlipScale(b.main, (bl.scale or (PickaxTheme and PickaxTheme.blipScale) or 0.9) + 0.0)
        SetBlipAsShortRange(b.main, false)
        if bl.flash then SetBlipFlashes(b.main, true) end
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(run.label)
        EndTextCommandSetBlipName(b.main)
        local radius = run.type == 'koth' and (run.params.radius or 25) or (bl.radius or 0)
        if radius and radius > 0 then
            b.area = AddBlipForRadius(c.x + 0.0, c.y + 0.0, c.z + 0.0, radius + 0.0)
            SetBlipColour(b.area, bl.color or 1)
            SetBlipAlpha(b.area, 90)
        end
    end
    -- livraison : la destination n'est visible que par le livreur
    local d = run.extra and run.extra.dest
    if run.type == 'delivery' and d and run.stage == 'deliver' and run.robber == myServerId then
        if not b.dest then
            b.dest = AddBlipForCoord(d.x + 0.0, d.y + 0.0, d.z + 0.0)
            SetBlipSprite(b.dest, 1)
            SetBlipColour(b.dest, 2)
            SetBlipRoute(b.dest, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName('Livraison')
            EndTextCommandSetBlipName(b.dest)
        end
    elseif b.dest then
        RemoveBlip(b.dest)
        b.dest = nil
    end
    if b.main and run.type == 'delivery' and run.stage == 'pickup' and not b.veh and run.truck and NetworkDoesNetworkIdExist(run.truck) then
        local e = NetworkGetEntityFromNetworkId(run.truck)
        if e and e ~= 0 and DoesEntityExist(e) then
            b.veh = AddBlipForEntity(e)
            SetBlipSprite(b.veh, 225)
            SetBlipColour(b.veh, 3)
        end
    end
end

-- ─────────────────────────────── Props locaux (butin) ───────────────────────────────
local function propKey(rid, id) return rid .. ':' .. id end

local function dropProp(key)
    local p = Props[key]
    if p and DoesEntityExist(p) then DeleteEntity(p) end
    Props[key] = nil
end

local function syncProps()
    local me = GetEntityCoords(PlayerPedId())
    for rid, run in pairs(Runs) do
      if run.type ~= 'heli_drop' then
        for _, l in ipairs(run.loot or {}) do
            local key = propKey(rid, l.id)
            local dist = #(me - vector3(l.x, l.y, l.z))
            if l.taken or dist > (Config.StreamDistance or 140.0) then
                dropProp(key)
            elseif not Props[key] and dist <= (Config.StreamDistance or 140.0) - 10.0 then
                local hash = loadModel(l.model)
                if hash then
                    local o = CreateObject(hash, l.x, l.y, l.z + 1.0, false, false, false)
                    if o and o ~= 0 then
                        SetEntityAsMissionEntity(o, true, true)
                        PlaceObjectOnGroundProperly(o)
                        FreezeEntityPosition(o, true)
                        Props[key] = o
                    end
                    SetModelAsNoLongerNeeded(hash)
                end
            end
        end
      end
    end
end

-- ─────────────────────────────── PNJ gardes / véhicule : configuration par le propriétaire réseau ───────────────────────────────
local function configureGuard(ped, cfg)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedRelationshipGroupHash(ped, GUARD_GROUP)
    SetPedArmour(ped, 100)
    SetPedAccuracy(ped, math.floor(cfg.accuracy or 30))
    SetPedDropsWeaponsWhenDead(ped, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAttributes(ped, 5, true)
    SetPedCombatAbility(ped, 2)
    SetPedCombatMovement(ped, 2)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCanRagdoll(ped, true)
    local w = joaat(cfg.weapon or 'WEAPON_CARBINERIFLE')
    GiveWeaponToPed(ped, w, 250, false, true)
    SetCurrentPedWeapon(ped, w, true)
    SetPedKeepTask(ped, true)
    if not IsPedInAnyVehicle(ped, false) then TaskGuardCurrentPosition(ped, 12.0, 10.0, true) end
end

local function entityFromNet(netId)
    if not netId or not NetworkDoesNetworkIdExist(netId) then return nil end
    local e = NetworkGetEntityFromNetworkId(netId)
    if e and e ~= 0 and DoesEntityExist(e) then return e end
    return nil
end

local function ownerTick()
    for rid, run in pairs(Runs) do
        -- gardes
        for _, netId in ipairs(run.guards or {}) do
            local ped = entityFromNet(netId)
            if ped and NetworkGetEntityOwner(ped) == PlayerId() and not Configured[netId] then
                configureGuard(ped, run.guardCfg or {})
                Configured[netId] = true
            end
            -- après l'alerte, les gardes attaquent tout joueur proche
            if ped and Configured[netId] and run.alerted and not IsPedDeadOrDying(ped, true) and NetworkGetEntityOwner(ped) == PlayerId() then
                if not Configured[netId .. 'a'] then
                    Configured[netId .. 'a'] = true
                    if IsPedInAnyVehicle(ped, false) then TaskLeaveAnyVehicle(ped, 0, 0) end
                    TaskCombatHatedTargetsAroundPed(ped, 90.0, 0)
                end
            end
        end
        -- fourgon : patrouille puis arrêt à l'alerte
        local truck = entityFromNet(run.truck)
        if truck and run.type == 'truck' and NetworkGetEntityOwner(truck) == PlayerId() then
            local key = 'truck' .. rid
            if run.params.patrol and not run.alerted and not Configured[key] then
                local driver = GetPedInVehicleSeat(truck, -1)
                if driver ~= 0 and Configured[(run.guards or {})[1] or 0] then
                    Configured[key] = true
                    SetDriverAbility(driver, 0.8)
                    TaskVehicleDriveWander(driver, truck, 16.0, 786603)
                end
            elseif run.alerted and not Configured[key .. 's'] then
                Configured[key .. 's'] = true
                BringVehicleToHalt(truck, 4.0, 5000, false)
            end
        end
        -- épave : flammes
        local wreck = entityFromNet(run.wreck)
        if wreck and run.type == 'crash' and run.params.fire and NetworkGetEntityOwner(wreck) == PlayerId() and not Configured['fire' .. rid] then
            Configured['fire' .. rid] = true
            SetVehicleEngineHealth(wreck, -1000.0)
            StartEntityFire(wreck)
        end
    end
end

-- ─────────────────────────────── Réseau ───────────────────────────────
RegisterNetEvent('eventbuilder:client:state', function(pub)
    pub.recv = GetGameTimer()
    local old = Runs[pub.rid]
    pub.t0Local = old and old.t0Local or (GetGameTimer() - (pub.elapsed or 0) * 1000)      -- horloge commune de l'événement (stable entre deux synchros)
    Runs[pub.rid] = pub
    updateBlips(pub)
end)

RegisterNetEvent('eventbuilder:client:end', function(rid)
    local run = Runs[rid]
    if run then
        for _, l in ipairs(run.loot or {}) do dropProp(propKey(rid, l.id)) end
    end
    if HeliCleanup then HeliCleanup(rid) end
    Runs[rid] = nil
    removeBlips(rid)
end)

RegisterNetEvent('eventbuilder:client:defs', function(list)
    Defs = list or {}
end)

RegisterNetEvent('eventbuilder:client:alert', function(a)
    ESX.ShowNotification(('~r~ALERTE~s~ %s — %s'):format(a.label or 'Événement', a.message or ''))
    PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
    local b = AddBlipForCoord(a.x + 0.0, a.y + 0.0, a.z + 0.0)
    SetBlipSprite(b, 161)
    SetBlipColour(b, 1)
    SetBlipScale(b, 1.1)
    SetBlipFlashes(b, true)
    SetBlipAsShortRange(b, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(a.label or 'Alerte')
    EndTextCommandSetBlipName(b)
    SetTimeout(90000, function() if DoesBlipExist(b) then RemoveBlip(b) end end)
end)

-- Téléportation d'un admin vers un événement (depuis le builder)
RegisterNetEvent('eventbuilder:client:tp', function(c)
    SetEntityCoords(PlayerPedId(), c.x + 0.0, c.y + 0.0, c.z + 1.0, false, false, false, false)
end)

-- ─────────────────────────────── Interactions ───────────────────────────────
local function nearestInteraction(me)
    local best
    for rid, run in pairs(Runs) do
        if run.stage == 'loot' or run.stage == 'wait' then
            for _, l in ipairs(run.loot or {}) do
                if not l.taken then
                    local d = #(me - vector3(l.x, l.y, l.z))
                    if d <= (Config.InteractDistance or 2.2) + 0.8 and (not best or d < best.d) then
                        best = { d = d, kind = 'loot', rid = rid, run = run, l = l }
                    end
                end
            end
        elseif run.stage == 'breach' and run.type == 'truck' then
            local truck = entityFromNet(run.truck)
            if truck then
                local rear = GetOffsetFromEntityInWorldCoords(truck, 0.0, -4.0, 0.0)
                local d = #(me - rear)
                if d <= 3.2 and (not best or d < best.d) then best = { d = d, kind = 'breach', rid = rid, run = run, rear = rear } end
            end
        end
    end
    return best
end

local function doInteract(it)
    busy = true
    if it.kind == 'breach' then
        ESX.TriggerServerCallback('eventbuilder:begin', function(r)
            if not r or not r.ok then ESX.ShowNotification('~r~' .. ((r and r.error) or 'Impossible')) busy = false return end
            local done = progress(r.seconds, 'Perçage des portes…', 'WORLD_HUMAN_WELDING')
            if not done then ESX.ShowNotification('~y~Perçage interrompu.') busy = false return end
            ESX.TriggerServerCallback('eventbuilder:finish', function(f)
                if not f or not f.ok then ESX.ShowNotification('~r~' .. ((f and f.error) or 'Échec')) end
                busy = false
            end, it.rid, 'breach')
        end, it.rid, 'breach')
    else
        local l = it.l
        ESX.TriggerServerCallback('eventbuilder:begin', function(r)
            if not r or not r.ok then ESX.ShowNotification('~r~' .. ((r and r.error) or 'Impossible')) busy = false return end
            local done = r.seconds <= 0 or progress(r.seconds, (l.label or 'Butin') .. '…', 'PROP_HUMAN_BUM_BIN')
            if not done then ESX.ShowNotification('~y~Interrompu.') busy = false return end
            ESX.TriggerServerCallback('eventbuilder:finish', function(f)
                if not f or not f.ok then ESX.ShowNotification('~r~' .. ((f and f.error) or 'Échec')) end
                busy = false
            end, it.rid, 'loot', l.id)
        end, it.rid, 'loot', l.id)
    end
end

-- ─────────────────────────────── Commerces (menacer le vendeur) ───────────────────────────────
local function clerkKey(defId, i) return defId .. ':' .. i end

local function dropClerk(key)
    local p = Clerks[key]
    if p and DoesEntityExist(p) then DeleteEntity(p) end
    Clerks[key] = nil
end

local function storeTick(me)
    local ped = PlayerPedId()
    local wanted = {}
    for _, d in ipairs(Defs) do
        for i, loc in ipairs(d.locations or {}) do
            local key = clerkKey(d.id, i)
            local dist = #(me - vector3(loc.x, loc.y, loc.z))
            if dist < 60.0 then
                wanted[key] = true
                if not Clerks[key] then
                    local hash = loadModel(d.clerkModel or 'mp_m_shopkeep_01')
                    if hash then
                        local c = CreatePed(4, hash, loc.x, loc.y, loc.z - 1.0, loc.h or 0.0, false, false)
                        SetEntityAsMissionEntity(c, true, true)
                        SetBlockingOfNonTemporaryEvents(c, true)
                        SetPedFleeAttributes(c, 0, false)
                        FreezeEntityPosition(c, true)
                        SetEntityInvincible(c, true)
                        TaskStartScenarioInPlace(c, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
                        Clerks[key] = c
                        SetModelAsNoLongerNeeded(hash)
                    end
                end
                local c = Clerks[key]
                if c and dist < 25.0 then
                    local active = false
                    for _, run in pairs(Runs) do
                        if run.type == 'store' and run.defId == d.id and run.stage == 'register' then active = true end
                    end
                    if active and not Configured['hands' .. key] then
                        Configured['hands' .. key] = true
                        ClearPedTasks(c)
                        RequestAnimDict('missminuteman_1ig_2')
                        while not HasAnimDictLoaded('missminuteman_1ig_2') do Wait(10) end
                        TaskPlayAnim(c, 'missminuteman_1ig_2', 'handsup_base', 8.0, -8.0, -1, 49, 0, false, false, false)
                    elseif not active and Configured['hands' .. key] then
                        Configured['hands' .. key] = nil
                        ClearPedTasks(c)
                        TaskStartScenarioInPlace(c, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
                    end
                    -- visée prolongée sur le vendeur = braquage
                    if not active and IsPlayerFreeAimingAtEntity(PlayerId(), c) and IsPedArmed(ped, 4) and dist < 12.0 then
                        aimStart[key] = aimStart[key] or GetGameTimer()
                        local need = (d.aimSeconds or 3) * 1000
                        local k = (GetGameTimer() - aimStart[key]) / need
                        text2d(0.5, 0.55, ('Vous menacez le vendeur… %d%%'):format(math.min(100, math.floor(k * 100))), 0.45, 255, 120, 120, true)
                        if k >= 1.0 and GetGameTimer() - (triggeredAt[key] or -999999) > 20000 then
                            triggeredAt[key] = GetGameTimer()
                            aimStart[key] = nil
                            TriggerServerEvent('eventbuilder:server:trigger', d.id, i)
                        end
                    else
                        aimStart[key] = nil
                    end
                end
            end
        end
    end
    for key in pairs(Clerks) do
        if not wanted[key] then dropClerk(key) end
    end
end

-- ─────────────────────────────── Affichage : zones, HUD ───────────────────────────────
local function drawRun(run, me)
    local c = run.coords
    local dist = #(me - vector3(c.x, c.y, c.z))
    if run.type == 'koth' then
        local r = (run.params and run.params.radius) or 25
        local col = (run.extra and run.extra.contested) and { 255, 80, 60 } or { 60, 200, 255 }
        DrawMarker(1, c.x, c.y, c.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, r * 2.0, r * 2.0, 3.0, col[1], col[2], col[3], 70, false, false, 2, false, nil, nil, false)
        if dist < r + 80.0 then
            local y = 0.12
            text2d(0.5, y, '~b~Contrôle de zone~s~' .. ((run.extra and run.extra.contested) and ' · ~r~contestée' or ''), 0.5, 255, 255, 255, true)
            for _, row in ipairs((run.extra and run.extra.board) or {}) do
                y = y + 0.032
                text2d(0.5, y, ('%s : %ds / %ds'):format(row.name, row.score, run.extra.hold or 0), 0.36, 255, 255, 255, true)
            end
        end
    elseif run.type == 'delivery' and run.stage == 'deliver' and run.robber == myServerId and run.extra and run.extra.dest then
        local d = run.extra.dest
        DrawMarker(1, d.x, d.y, d.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, d.r * 2.0, d.r * 2.0, 2.0, 60, 220, 120, 90, false, false, 2, false, nil, nil, false)
    end
    if dist < 160.0 then
        local left = math.max(0, (run.endsIn or 0) - (GetGameTimer() - (run.recv or GetGameTimer())) / 1000)
        local line = ('%s · %s'):format(run.label, run.stageText or run.stage)
        if run.stage == 'wait' then
            local u = math.max(0, (run.unlockIn or 0) - (GetGameTimer() - (run.recv or GetGameTimer())) / 1000)
            line = line .. (' (%s)'):format(mmss(u))
        end
        text2d(0.5, 0.965, ('%s — fin dans %s'):format(line, mmss(left)), 0.32, 230, 230, 230, true)
    end
end

-- ─────────────────────────────── Largage par hélicoptère (rejeu local) ───────────────────────────────
-- Chaque client voit le même hélicoptère et la même chute de caisses : tout est calculé à partir de l'horloge commune de l'événement.
local Fx = {}     -- [rid] = { heli, pilot, crates = { [lootId] = { obj, chute, flare, landed } } }

local function lerp(a, b, k) return a + (b - a) * k end

function HeliCleanup(rid)
    local f = Fx[rid]
    if not f then return end
    if f.pilot and DoesEntityExist(f.pilot) then DeleteEntity(f.pilot) end
    if f.heli and DoesEntityExist(f.heli) then DeleteEntity(f.heli) end
    for _, c in pairs(f.crates) do
        if c.chute and DoesEntityExist(c.chute) then DeleteEntity(c.chute) end
        if c.obj and DoesEntityExist(c.obj) then DeleteEntity(c.obj) end
        if c.flare then StopParticleFxLooped(c.flare, false) end
    end
    Fx[rid] = nil
end

local function heliPos(H, n, t)
    local hover = (n - 1) * H.stagger + H.fall + 5.0
    local dx, dy = H.ex - H.sx, H.ey - H.sy
    local len = math.sqrt(dx * dx + dy * dy)
    local ux, uy = dx / math.max(len, 0.001), dy / math.max(len, 0.001)
    local heading = GetHeadingFromVector_2d(ux, uy)
    if t < H.flight then
        local k = t / H.flight
        return lerp(H.sx, H.ex, k), lerp(H.sy, H.ey, k), lerp(H.sz, H.ez, k), heading, true
    elseif t < H.flight + hover then
        return H.ex, H.ey, H.ez, heading, true
    end
    local away = t - (H.flight + hover)
    return H.ex + ux * away * H.speed, H.ey + uy * away * H.speed, H.ez + away * 4.0, heading, away < 30.0
end

local function heliTick(rid, run, me)
    local H = run.extra and run.extra.heli
    if not H then return end
    local f = Fx[rid]
    if not f then f = { crates = {} } Fx[rid] = f end
    local n = #(run.loot or {})
    local t = (GetGameTimer() - (run.t0Local or GetGameTimer())) / 1000.0
    local hx, hy, hz, heading, alive = heliPos(H, n, t)

    -- hélicoptère (visuel local, non réseau)
    if alive and #(me - vector3(hx, hy, hz)) < 900.0 then
        if not f.heli then
            local hash = loadModel(H.model or 'maverick')
            if hash then
                f.heli = CreateVehicle(hash, hx, hy, hz, heading, false, false)
                SetEntityCollision(f.heli, false, false)
                SetEntityInvincible(f.heli, true)
                SetVehicleEngineOn(f.heli, true, true, true)
                SetHeliBladesFullSpeed(f.heli)
                SetVehicleDoorsLocked(f.heli, 10)
                local ph = loadModel('s_m_y_pilot_01')
                if ph then
                    f.pilot = CreatePedInsideVehicle(f.heli, 4, ph, -1, false, false)
                    SetBlockingOfNonTemporaryEvents(f.pilot, true)
                    SetModelAsNoLongerNeeded(ph)
                end
                SetModelAsNoLongerNeeded(hash)
            end
        end
        if f.heli and DoesEntityExist(f.heli) then
            SetEntityCoordsNoOffset(f.heli, hx, hy, hz, false, false, false)
            SetEntityHeading(f.heli, heading)
            SetHeliBladesFullSpeed(f.heli)
        end
    elseif f.heli then
        if f.pilot and DoesEntityExist(f.pilot) then DeleteEntity(f.pilot) end
        if DoesEntityExist(f.heli) then DeleteEntity(f.heli) end
        f.heli, f.pilot = nil, nil
    end

    -- caisses : chute en parachute puis atterrissage
    for i, l in ipairs(run.loot or {}) do
        local c = f.crates[l.id]
        if l.taken then
            if c then
                if c.chute and DoesEntityExist(c.chute) then DeleteEntity(c.chute) end
                if c.obj and DoesEntityExist(c.obj) then DeleteEntity(c.obj) end
                if c.flare then StopParticleFxLooped(c.flare, false) end
                f.crates[l.id] = nil
            end
        else
            local tStart = H.flight + (i - 1) * H.stagger
            local tLand = tStart + H.fall
            local close = #(me - vector3(l.x, l.y, l.z)) < ((Config.StreamDistance or 140.0) + 160.0)
            if t >= tStart and close then
                if not c then
                    c = { gz = nil }
                    f.crates[l.id] = c
                end
                if not c.obj then
                    local hash = loadModel(l.model)
                    if hash then
                        local ok, gz = GetGroundZFor_3dCoord(l.x, l.y, l.z + 60.0, false)
                        c.gz = ok and gz or l.z
                        c.obj = CreateObject(hash, l.x, l.y, (t >= tLand) and c.gz or (H.ez - 2.0), false, false, false)
                        SetEntityAsMissionEntity(c.obj, true, true)
                        FreezeEntityPosition(c.obj, true)
                        SetModelAsNoLongerNeeded(hash)
                        if t < tLand then
                            local chash = loadModel('p_parachute1_mp_dec')
                            if chash then
                                c.chute = CreateObject(chash, l.x, l.y, H.ez, false, false, false)
                                AttachEntityToEntity(c.chute, c.obj, 0, 0.0, 0.0, 1.6, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                                SetModelAsNoLongerNeeded(chash)
                            end
                        end
                    end
                end
                if c.obj and DoesEntityExist(c.obj) then
                    if t < tLand then
                        local k = math.min(1.0, (t - tStart) / H.fall)
                        local z = lerp(H.ez - 2.0, c.gz or l.z, k * (2 - k))                 -- ralentit à l'approche du sol
                        local sway = math.sin(t * 1.3 + i) * 1.2 * (1 - k)
                        SetEntityCoordsNoOffset(c.obj, l.x + sway, l.y + math.cos(t + i) * 0.8 * (1 - k), z, false, false, false)
                    elseif not c.landed then
                        c.landed = true
                        SetEntityCoordsNoOffset(c.obj, l.x, l.y, c.gz or l.z, false, false, false)
                        PlaceObjectOnGroundProperly(c.obj)
                        if c.chute and DoesEntityExist(c.chute) then DeleteEntity(c.chute) c.chute = nil end
                        if H.flare then
                            RequestNamedPtfxAsset('core')
                            local tt = GetGameTimer()
                            while not HasNamedPtfxAssetLoaded('core') and GetGameTimer() - tt < 1500 do Wait(10) end
                            UseParticleFxAssetNextCall('core')
                            c.flare = StartParticleFxLoopedAtCoord('exp_grd_flare', l.x, l.y, (c.gz or l.z) + 0.2, 0.0, 0.0, 0.0, 1.4, false, false, false, false)
                        end
                    end
                end
            elseif c and not close then
                if c.chute and DoesEntityExist(c.chute) then DeleteEntity(c.chute) end
                if c.obj and DoesEntityExist(c.obj) then DeleteEntity(c.obj) end
                if c.flare then StopParticleFxLooped(c.flare, false) end
                f.crates[l.id] = nil
            end
        end
    end
end

CreateThread(function()
    while true do
        local sleep = 500
        local me = GetEntityCoords(PlayerPedId())
        for rid, run in pairs(Runs) do
            if run.type == 'heli_drop' then
                local H = run.extra and run.extra.heli
                if H and #(me - vector3(run.coords.x, run.coords.y, run.coords.z)) < 1200.0 then
                    sleep = 0
                    local ok, err = pcall(heliTick, rid, run, me)
                    if not ok then print(('^1[eventbuilder] largage hélico : %s^0'):format(tostring(err))) end
                elseif Fx[rid] then
                    HeliCleanup(rid)
                end
            end
        end
        Wait(sleep)
    end
end)

-- ─────────────────────────────── Boucles ───────────────────────────────
CreateThread(function()
    while true do
        Wait(700)
        local ok, err = pcall(function()
            syncProps()
            ownerTick()
        end)
        if not ok then print(('^1[eventbuilder] client : %s^0'):format(tostring(err))) end
    end
end)

CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local me = GetEntityCoords(ped)
        local any = next(Runs) ~= nil
        if any then
            for _, run in pairs(Runs) do
                if #(me - vector3(run.coords.x, run.coords.y, run.coords.z)) < 200.0 then sleep = 0 drawRun(run, me) end
            end
            if not busy and not IsEntityDead(ped) then
                local it = nearestInteraction(me)
                if it then
                    sleep = 0
                    if it.kind == 'loot' and it.run.stage == 'wait' then
                        local u = math.max(0, (it.run.unlockIn or 0) - (GetGameTimer() - (it.run.recv or GetGameTimer())) / 1000)
                        help(('Caisse verrouillée : %s'):format(mmss(u)))
                    elseif it.kind == 'loot' then
                        help(('~INPUT_CONTEXT~ %s'):format(it.l.label == 'Sac de billets' and 'Ramasser le sac' or 'Fouiller / ouvrir'))
                        if IsControlJustPressed(0, 38) then doInteract(it) end
                    elseif it.kind == 'breach' then
                        help('~INPUT_CONTEXT~ Percer les portes du fourgon')
                        if IsControlJustPressed(0, 38) then doInteract(it) end
                    end
                end
            end
        end
        if #Defs > 0 then
            local ok2 = pcall(storeTick, me)
            if next(Clerks) then sleep = math.min(sleep, 100) end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for k in pairs(Props) do dropProp(k) end
    for k in pairs(Clerks) do dropClerk(k) end
    if HeliCleanup then for rid in pairs(Runs) do HeliCleanup(rid) end end
    for rid in pairs(Blips) do removeBlips(rid) end
end)
