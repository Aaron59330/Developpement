local C = Config
local function dot(a, b) return a.x * b.x + a.y * b.y + a.z * b.z end
local function byId(list, id) for _, v in ipairs(list) do if v.id == id then return v end end end

InHeist = false
local D                      -- données du braquage reçues du serveur
local nodes, opened, taken = {}, {}, {}
local primaryTaken, landed, alerted = false, false, false
local bag, startedAt = 0, 0
local guards, vehicles, spawnedZones, extra, dogs, camProps, deadSeen = {}, {}, {}, {}, {}, {}, {}
local blips = {}
local guardGroup
local zoneAsked = {}
local lastCheck = 0

local function hasEq(id) return D and D.plan.equipment and D.plan.equipment[id] == true end
local function load(model)
    local h = type(model) == 'string' and joaat(model) or model
    RequestModel(h)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(h) and GetGameTimer() < t do Wait(20) end
    return h
end

-- ───────── nettoyage ─────────
local function cleanup()
    InHeist = false
    for _, g in ipairs(guards) do if DoesEntityExist(g) then SetEntityAsMissionEntity(g, true, true) DeleteEntity(g) end end
    for _, v in ipairs(vehicles) do if DoesEntityExist(v) then SetEntityAsMissionEntity(v, true, true) DeleteEntity(v) end end
    for _, e in ipairs(extra) do if DoesEntityExist(e) then SetEntityAsMissionEntity(e, true, true) DeleteEntity(e) end end
    for _, b in ipairs(blips) do if DoesBlipExist(b) then RemoveBlip(b) end end
    for _, c in ipairs(camProps) do if DoesEntityExist(c) then DeleteEntity(c) end end
    guards, vehicles, extra, blips, spawnedZones, zoneAsked, dogs, camProps, deadSeen = {}, {}, {}, {}, {}, {}, {}, {}, {}
    nodes, opened, taken, D = {}, {}, {}, nil
    primaryTaken, landed, alerted, bag = false, false, false, 0
end

local function goHome()
    DoScreenFadeOut(500) Wait(600)
    local p = C.ReturnPoint
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16) Wait(300) end
    RequestCollisionAtCoord(p.x, p.y, p.z)
    SetEntityCoords(ped, p.x, p.y, p.z, false, false, false, false)
    SetEntityHeading(ped, p.w)
    Wait(800) DoScreenFadeIn(600)
end

-- ───────── gardes ─────────
local function setupGuard(g, diff, weapon, armour)
    SetEntityAsMissionEntity(g, true, true)
    SetPedRelationshipGroupHash(g, guardGroup)
    local hp = hasEq('dis_armor') and math.floor(diff.health * 0.6) or diff.health
    SetPedMaxHealth(g, hp) SetEntityHealth(g, hp)
    SetPedArmour(g, hasEq('dis_armor') and 0 or armour)
    SetPedAccuracy(g, diff.accuracy)
    SetPedCombatAbility(g, 2) SetPedCombatMovement(g, 2) SetPedCombatRange(g, 2)
    SetPedFleeAttributes(g, 0, false) SetPedCombatAttributes(g, 46, true) SetPedCombatAttributes(g, 5, true)
    SetPedSeeingRange(g, hasEq('uniform') and 12.0 or 45.0)
    SetPedHearingRange(g, 35.0)
    SetPedAlertness(g, 1)
    GiveWeaponToPed(g, joaat(weapon), 250, false, true)
    SetPedDropsWeaponsWhenDead(g, false)
    guards[#guards + 1] = g
end

local function spawnZone(i)
    local z = C.Island.guards[i]
    local diff = C.Difficulties[D.plan.difficulty]
    local armour = D.plan.difficulty == 'hard' and 100 or 40
    local weapons = hasEq('dis_weapons') and { 'WEAPON_PISTOL' } or C.Island.guardWeapons
    local n = math.ceil(z.count * diff.guards)
    for k = 1, n do
        local a = math.random() * 6.283
        local r = math.random() * z.radius * 0.8
        local x, y = z.coords.x + math.cos(a) * r, z.coords.y + math.sin(a) * r
        local ok, gz = GetGroundZFor_3dCoord(x, y, z.coords.z + 20.0, false)
        local h = load(C.Island.guardModels[math.random(#C.Island.guardModels)])
        local zz = z.sniper and z.coords.z or (ok and gz or z.coords.z)
        local g = CreatePed(4, h, x, y, zz, math.random(0, 359) + 0.0, true, true)
        setupGuard(g, diff, z.sniper and 'WEAPON_SNIPERRIFLE' or weapons[math.random(#weapons)], armour)
        if z.sniper then
            SetPedCombatMovement(g, 0) SetPedCombatRange(g, 3) SetPedSeeingRange(g, 90.0) SetPedAccuracy(g, diff.accuracy + 15)
            TaskGuardCurrentPosition(g, 20.0, 10.0, true)
        else TaskWanderInArea(g, z.coords.x, z.coords.y, z.coords.z, z.radius, 2.0, 8000) end
        SetModelAsNoLongerNeeded(h)
    end
    -- chiens : flair très fin, se jettent sur le joueur à moins de ~10 m
    for k = 1, (z.dogs or 0) do
        local h = load('a_c_rottweiler')
        local a = math.random() * 6.283
        local g = CreatePed(28, h, z.coords.x + math.cos(a) * 6.0, z.coords.y + math.sin(a) * 6.0, z.coords.z, 0.0, true, true)
        SetEntityAsMissionEntity(g, true, true)
        SetPedRelationshipGroupHash(g, guardGroup)
        SetPedSeeingRange(g, 25.0) SetPedHearingRange(g, 45.0)
        SetPedCombatAttributes(g, 46, true) SetPedFleeAttributes(g, 0, false)
        SetEntityHealth(g, 220)
        TaskWanderInArea(g, z.coords.x, z.coords.y, z.coords.z, z.radius, 2.0, 6000)
        guards[#guards + 1] = g
        dogs[#dogs + 1] = g
        SetModelAsNoLongerNeeded(h)
    end
end

local function spawnReinforcements()
    if not D then return end
    local v = C.Island.vault
    local h = load(C.Island.reinforcementHeli)
    local heli = CreateVehicle(h, v.x + 180.0, v.y, v.z + 130.0, 270.0, true, true)
    SetEntityAsMissionEntity(heli, true, true)
    SetHeliBladesFullSpeed(heli)
    extra[#extra + 1] = heli
    local diff = C.Difficulties[D.plan.difficulty]
    local gm = load(C.Island.guardModels[1])
    local crew = {}
    for seat = -1, 2 do
        local g = CreatePedInsideVehicle(heli, 4, gm, seat, true, true)
        SetPedRelationshipGroupHash(g, guardGroup)
        SetPedMaxHealth(g, diff.health) SetEntityHealth(g, diff.health) SetPedAccuracy(g, diff.accuracy)
        GiveWeaponToPed(g, joaat('WEAPON_CARBINERIFLE'), 500, false, true)
        SetPedCombatAttributes(g, 46, true) SetPedFleeAttributes(g, 0, false)
        crew[#crew + 1] = g guards[#guards + 1] = g
    end
    TaskHeliMission(crew[1], heli, 0, 0, v.x, v.y, v.z + 35.0, 4, 25.0, 5.0, -1.0, 30, 15, -1.0, 0)
    for i = 2, #crew do TaskCombatHatedTargetsAroundPed(crew[i], 200.0, 0) end
end

RegisterNetEvent('pickax_cayo:alerted', function()
    if not D or alerted then return end
    alerted = true
    PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
    TriggerEvent('esx:showNotification', '~r~ALARME !~s~ Les gardes sont alertés, des renforts arrivent.')
    for _, g in ipairs(guards) do if DoesEntityExist(g) and not IsEntityDead(g) then TaskCombatHatedTargetsAroundPed(g, 150.0, 0) end end
    if D.leader == GetPlayerServerId(PlayerId()) and not hasEq('dis_air') then
        SetTimeout(C.Difficulties[D.plan.difficulty].reinforce * 1000, function() if InHeist and D then spawnReinforcements() end end)
    end
end)

-- ───────── départ ─────────
RegisterNetEvent('pickax_cayo:start', function(d)
    if InHeist then return end
    cleanup()
    D = d
    InHeist = true
    nodes = {}
    for _, n in ipairs(d.nodes) do nodes[n.id] = n end
    startedAt = GetGameTimer()
    local _, grp = AddRelationshipGroup('CAYO_GUARD')
    guardGroup = grp
    SetRelationshipBetweenGroups(5, grp, joaat('PLAYER'))
    SetRelationshipBetweenGroups(5, joaat('PLAYER'), grp)
    SetRelationshipBetweenGroups(0, grp, grp)

    local ap = byId(C.Approaches, d.plan.approach)
    local infil = byId(C.Infiltrations, d.plan.infil)
    DoScreenFadeOut(800) Wait(900)
    local ped = PlayerPedId()
    local s = ap.start
    local ox, oy = (math.random() - 0.5) * 16.0, (math.random() - 0.5) * 16.0
    RequestCollisionAtCoord(s.x, s.y, s.z)
    if ap.vehicle then
        local h = load(ap.vehicle)
        local veh = CreateVehicle(h, s.x + ox, s.y + oy, s.z, s.w, true, true)
        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleEngineOn(veh, true, true, false)
        if IsThisModelAHeli(h) then SetHeliBladesFullSpeed(veh) end
        SetPedIntoVehicle(ped, veh, -1)
        vehicles[#vehicles + 1] = veh
        SetModelAsNoLongerNeeded(h)
    else
        SetEntityCoords(ped, s.x + ox, s.y + oy, s.z, false, false, false, false)
        GiveWeaponToPed(ped, joaat('GADGET_PARACHUTE'), 1, false, true)
    end
    Wait(800) DoScreenFadeIn(800)
    SetNewWaypoint(infil.coords.x, infil.coords.y)
    local b = AddBlipForCoord(infil.coords.x, infil.coords.y, infil.coords.z)
    SetBlipSprite(b, 1) SetBlipColour(b, 5) SetBlipRoute(b, true) SetBlipRouteColour(b, 5)
    blips[#blips + 1] = b
    local e = byId(C.Exfils, d.plan.exfil)
    local b2 = AddBlipForCoord(e.coords.x, e.coords.y, e.coords.z)
    SetBlipSprite(b2, 410) SetBlipColour(b2, 2) SetBlipScale(b2, 0.9) SetBlipAsShortRange(b2, false)
    BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('Extraction') EndTextCommandDisplayText(b2)
    blips[#blips + 1] = b2
    for _, cm in ipairs(C.Island.cameras or {}) do
        local mh = load('prop_cctv_cam_01a')
        local o = CreateObject(mh, cm.coords.x, cm.coords.y, cm.coords.z, false, false, false)
        SetEntityHeading(o, cm.heading) FreezeEntityPosition(o, true)
        camProps[#camProps + 1] = o
        SetModelAsNoLongerNeeded(mh)
    end
    TriggerEvent('esx:showNotification', '~g~Braquage de Cayo Perico lancé.~s~ Rejoins ' .. infil.label .. '.')
    if not ap.vehicle then TriggerEvent('esx:showNotification', 'Ouvre ton parachute avec ~b~F~s~ pour atterrir sur l\'île.') end
end)

-- ───────── événements serveur ─────────
RegisterNetEvent('pickax_cayo:opened', function(id) opened[id] = true TriggerEvent('esx:showNotification', '~g~Obstacle franchi.') end)
RegisterNetEvent('pickax_cayo:taken', function(id) taken[id] = true end)
RegisterNetEvent('pickax_cayo:bag', function(n) bag = n end)
RegisterNetEvent('pickax_cayo:primaryTaken', function(src)
    primaryTaken = true
    TriggerEvent('esx:showNotification', '~g~Cible principale sécurisée !~s~ Rejoins le point d\'extraction.')
end)
RegisterNetEvent('pickax_cayo:primaryLost', function()
    primaryTaken = false
    TriggerEvent('esx:showNotification', '~r~Le porteur de la cible est tombé : elle est perdue.')
end)
RegisterNetEvent('pickax_cayo:out', function()
    if not InHeist then return end
    cleanup()
    goHome()
end)
RegisterNetEvent('pickax_cayo:forceOut', function()
    if not InHeist then return end
    TriggerEvent('esx:showNotification', '~r~Temps écoulé.~s~ Tu es évacué.')
    cleanup()
    goHome()
end)
RegisterNetEvent('pickax_cayo:result', function(r)
    local wasIn = InHeist
    cleanup()
    local msg
    if r.success and r.pay > 0 then msg = ('~g~Braquage réussi !~s~ Butin total ~b~%s $~s~ — ta part : ~g~%s $~s~'):format(ESX.Math.GroupDigits(r.pool), ESX.Math.GroupDigits(r.pay)) .. (r.elite and '\n~y~Défi Élite réussi : bonus inclus.' or '')
    elseif r.success then msg = '~y~Braquage terminé~s~ : tu n\'as pas de part à toucher.'
    else msg = '~r~Braquage raté.~s~ Personne n\'est reparti de l\'île.' end
    TriggerEvent('esx:showNotification', msg)
    if wasIn and r.state ~= 'dead' and not IsEntityDead(PlayerPedId()) then goHome() end
end)

-- ───────── boucle principale ─────────
local function fmt(s) s = math.max(0, math.floor(s)) return ('%d:%02d'):format(s // 60, s % 60) end

CreateThread(function()
    while true do
        if not InHeist or not D then Wait(700)
        else
            local ped = PlayerPedId()
            local me = GetEntityCoords(ped)
            local dead = IsEntityDead(ped)
            local infil = byId(C.Infiltrations, D.plan.infil)
            local exfil = byId(C.Exfils, D.plan.exfil)
            local tgt = byId(C.Targets, D.plan.target)

            -- atterrissage
            if not landed and #(me - infil.coords.xyz) < 120.0 then
                landed = true
                TriggerEvent('esx:showNotification', '~g~Tu es arrivé sur l\'île.~s~ Rejoins le complexe d\'El Rubio.')
                for _, b in ipairs(blips) do if GetBlipSprite(b) == 1 then SetBlipRoute(b, false) end end
            end

            -- objectifs + chrono + sac
            if not dead then
                local obj
                if not landed then obj = ('Rejoins : %s (%d m)'):format(infil.label, #(me - infil.coords.xyz))
                elseif primaryTaken then obj = ('Rejoins l\'extraction : %s'):format(exfil.label)
                else
                    local sp = C.Island.targetSpots[D.plan.target]
                    local req = sp.requires and byId(C.Island.obstacles, sp.requires)
                    if req and not opened[sp.requires] then obj = ('Ouvre : %s'):format(req.label)
                    else obj = ('Prends la cible : %s'):format(tgt.label) end
                end
                Hud(0.985, 0.60, 'CAYO PERICO', 0.5, 255, 190, 40, 'right')
                Hud(0.985, 0.64, obj, 0.4, 255, 255, 255, 'right')
                Hud(0.985, 0.675, ('Temps : %s    Sac : %d / %d'):format(fmt(D.duration - (GetGameTimer() - startedAt) / 1000), bag, C.BagCapacity), 0.36, 200, 200, 200, 'right')
                Hud(0.985, 0.705, 'Butin secondaire facultatif — extraction sans la cible = abandon', 0.30, 160, 160, 160, 'right')
                if D.plan.elite then Hud(0.985, 0.73, alerted and 'Défi Élite : échoué (alarme)' or 'Défi Élite : aucune alarme, personne à terre', 0.30, alerted and 229 or 63, alerted and 72 or 185, alerted and 77 or 80, 'right') end
            end

            -- extraction : repère
            local de = #(me - exfil.coords)
            if de < exfil.radius + 60.0 then
                DrawMarker(1, exfil.coords.x, exfil.coords.y, exfil.coords.z - 1.0, 0, 0, 0, 0, 0, 0, exfil.radius * 2.0, exfil.radius * 2.0, 2.0, 60, 200, 110, 60, false, false, 2, false, nil, nil, false)
            end

            -- zones de gardes : la première machine qui s'en approche les fait apparaître
            for i, z in ipairs(C.Island.guards) do
                if not zoneAsked[i] and #(me - z.coords) < 320.0 then
                    zoneAsked[i] = true
                    ESX.TriggerServerCallback('pickax_cayo:zone', function(ok) if ok and D then spawnZone(i) end end, i)
                end
            end

            -- détection d'alerte : tir non silencieux ou garde en combat contre moi
            if not alerted and not dead then
                if IsPedShooting(ped) and not hasEq('silencer') then TriggerServerEvent('pickax_cayo:alert') alerted = true
                else
                    for _, g in ipairs(guards) do
                        if DoesEntityExist(g) and not IsEntityDead(g) and #(GetEntityCoords(g) - me) < 40.0 and IsPedInCombat(g, ped) then TriggerServerEvent('pickax_cayo:alert') alerted = true break end
                    end
                end
            end

            -- furtivité : accroupi = les gardes voient moins loin ; cadavres découverts ; caméras ; chiens
            if not dead and GetGameTimer() - lastCheck > 500 then
                lastCheck = GetGameTimer()
                local duck = IsPedDucking(ped)
                local uni = hasEq('uniform')
                local rng = uni and (duck and 6.0 or 12.0) or (duck and 18.0 or 45.0)
                local bodies = {}
                for _, g in ipairs(guards) do
                    if DoesEntityExist(g) then
                        if IsEntityDead(g) then bodies[#bodies + 1] = g
                        elseif GetPedCombatMovement(g) ~= 0 and not dogs[g] then SetPedSeeingRange(g, rng) end
                    end
                end
                if not alerted then
                    for _, b in ipairs(bodies) do
                        if not deadSeen[b] then
                            for _, g in ipairs(guards) do
                                if DoesEntityExist(g) and not IsEntityDead(g) and #(GetEntityCoords(g) - GetEntityCoords(b)) < 14.0 and HasEntityClearLosToEntity(g, b, 17) then
                                    deadSeen[b] = true TriggerServerEvent('pickax_cayo:alert') alerted = true
                                    TriggerEvent('esx:showNotification', '~r~Un garde a découvert un corps.') break
                                end
                            end
                        end
                        if alerted then break end
                    end
                    if not opened.cams then
                        for ci, cm in ipairs(C.Island.cameras or {}) do
                            local to = me - cm.coords
                            local dist = #to
                            if dist < cm.range then
                                local hr = math.rad(cm.heading)
                                local fwd = vec3(-math.sin(hr), math.cos(hr), 0.0)
                                local ang = math.deg(math.acos(math.max(-1.0, math.min(1.0, dot(fwd, vec3(to.x, to.y, 0.0) / math.max(0.01, #vec3(to.x, to.y, 0.0)))))))
                                if ang < cm.fov / 2 and camProps[ci] and HasEntityClearLosToEntity(camProps[ci], ped, 17) and not (uni and duck) then
                                    TriggerServerEvent('pickax_cayo:alert') alerted = true
                                    TriggerEvent('esx:showNotification', '~r~Une caméra t\'a repéré.') break
                                end
                            end
                        end
                    end
                end
                for _, dg in ipairs(dogs) do
                    if DoesEntityExist(dg) and not IsEntityDead(dg) and #(GetEntityCoords(dg) - me) < 12.0 and not GetIsTaskActive(dg, 6) then
                        TaskCombatPed(dg, ped, 0, 16)
                        if not alerted then TriggerServerEvent('pickax_cayo:alert') alerted = true end
                    end
                end
            end

            -- interactions
            local sleep = 0
            if not dead and not IsPedInAnyVehicle(ped, false) then
                local act
                for _, ob in ipairs(C.Island.obstacles) do
                    if not opened[ob.id] and (not ob.requires or opened[ob.requires]) then
                        local d = #(me - ob.coords)
                        if d < 25.0 then
                            DrawMarker(1, ob.coords.x, ob.coords.y, ob.coords.z - 1.0, 0, 0, 0, 0, 0, 0, 1.2, 1.2, 0.5, 255, 190, 40, 110, false, false, 2, false, nil, nil, false)
                            if d < 2.5 then
                                local need = ob.need and byId(C.Equipment, ob.need)
                                if need and not hasEq(ob.need) then
                                    Draw3D(ob.coords.x, ob.coords.y, ob.coords.z + 0.8, '~r~' .. ob.label .. '~s~ — matériel requis : ' .. need.label)
                                else
                                    Draw3D(ob.coords.x, ob.coords.y, ob.coords.z + 0.8, '~g~[E]~s~ ' .. ob.label .. (need and (' — ' .. need.label) or ''))
                                    if IsControlJustPressed(0, 38) then act = { 'obstacle', ob } end
                                end
                            end
                        end
                    end
                end
                for id, n in pairs(nodes) do
                    if not taken[id] then
                        local d = #(me - n.coords)
                        if d < 18.0 then
                            local def = C.Loot[n.type]
                            DrawMarker(2, n.coords.x, n.coords.y, n.coords.z + 0.3, 0, 0, 0, 0, 0, 0, 0.35, 0.35, 0.35, n.type == 'jewel' and 120 or 255, n.type == 'jewel' and 220 or 215, n.type == 'jewel' and 255 or 60, 190, true, false, 2, false, nil, nil, false)
                            if d < 2.0 then
                                local how = n.type == 'jewel' and (hasEq('glasscutter') and ' (coupe-verre)' or ' ~r~(briser la vitrine = alarme)~s~') or ''
                                Draw3D(n.coords.x, n.coords.y, n.coords.z + 0.9, ('~g~[E]~s~ (maintenir) Prendre : %s%s'):format(def.label, how))
                                if IsControlPressed(0, 38) then act = { 'loot', id } end
                            end
                        end
                    end
                end
                local sp = C.Island.targetSpots[D.plan.target]
                if not primaryTaken and (not sp.requires or opened[sp.requires]) then
                    local v = sp.coords
                    local d = #(me - v)
                    if d < 20.0 then
                        DrawMarker(2, v.x, v.y, v.z + 0.3, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 60, 200, 255, 200, true, false, 2, false, nil, nil, false)
                        if d < 2.5 then
                            local need = sp.need and byId(C.Equipment, sp.need)
                            if need and not hasEq(sp.need) then
                                Draw3D(v.x, v.y, v.z + 1.0, '~r~' .. tgt.label .. '~s~ — matériel requis : ' .. need.label)
                            else
                                Draw3D(v.x, v.y, v.z + 1.0, ('~g~[E]~s~ Prendre : %s'):format(tgt.label))
                                if IsControlJustPressed(0, 38) then act = { 'primary', sp } end
                            end
                        end
                    end
                end
                if de <= exfil.radius then
                    Draw3D(me.x, me.y, me.z + 1.1, '~g~[E]~s~ (maintenir) Quitter l\'île' .. (primaryTaken and '' or ' ~r~(sans la cible)'))
                    if IsControlPressed(0, 38) then act = { 'exfil' } end
                end

                if act then
                    local anim = { 'anim@heists@ornate_bank@grab_cash', 'grab' }
                    local function game(g, diff)
                        local sg = GetResourceState('pickax_skillgames') == 'started' and exports.pickax_skillgames
                        if not sg then return true end
                        local sc = sg:Play(g, { difficulty = diff or 3, pins = 4, seconds = 40 })
                        if (sc or 0) >= 50 then return true end
                        TriggerEvent('esx:showNotification', '~r~Raté.~s~ Réessaie.')
                        return false
                    end
                    if act[1] == 'obstacle' then
                        local ob = act[2]
                        local ok
                        if ob.game then ok = game(ob.game, ob.difficulty) else ok = HoldE(ob.label, ob.seconds or 5, { 'anim@heists@fleeca_bank@drilling', 'drill_straight_idle' }) end
                        if ok then
                            if ob.id == 'door' and not opened.secure then TriggerServerEvent('pickax_cayo:alert') alerted = true end
                            TriggerServerEvent('pickax_cayo:obstacle', ob.id)
                        end
                    elseif act[1] == 'loot' then
                        local n = nodes[act[2]]
                        if n and n.type == 'jewel' and not hasEq('glasscutter') and not alerted then
                            -- vitrine brisée : l'alarme se déclenche
                            TriggerServerEvent('pickax_cayo:alert') alerted = true
                        end
                        if HoldE(n and n.type == 'jewel' and 'Vitrine…' or 'Ramassage…', C.LootSeconds, anim) then TriggerServerEvent('pickax_cayo:loot', act[2]) end
                    elseif act[1] == 'primary' then
                        local sp = act[2]
                        local ok
                        if sp.game then ok = game(sp.game, sp.difficulty) else ok = HoldE('Sécurisation de la cible…', sp.seconds or 5, anim) end
                        if ok then TriggerServerEvent('pickax_cayo:primary') end
                    elseif act[1] == 'exfil' then
                        if HoldE('Évacuation…', 2, nil) then TriggerServerEvent('pickax_cayo:exfil') end
                    end
                end
            end
            Wait(sleep)
        end
    end
end)

AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then cleanup() end end)
