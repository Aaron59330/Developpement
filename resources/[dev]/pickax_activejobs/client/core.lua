ESX = exports['es_extended']:getSharedObject()

AJ = { Points = {}, Active = nil, Mod = {}, Hud = {}, Blips = {}, Ents = {} }

-- ─────────────────────────────── Outils communs ───────────────────────────────
function AJ.Notify(msg, kind)
    if GetResourceState('pickax_notify') == 'started' then
        local ok = pcall(function() exports['pickax_notify']:ShowNotification(msg, kind or 'info') end)
        if ok then return end
    end
    ESX.ShowNotification(msg)
end
RegisterNetEvent('aj:client:notify', function(msg, kind) AJ.Notify(msg, kind) end)

function AJ.Help(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

function AJ.Text3D(x, y, z, text, scale)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.0, scale or 0.32) SetTextFont(4) SetTextCentre(true) SetTextOutline()
    SetTextColour(255, 255, 255, 235)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

function AJ.Points_(key, kind) return (AJ.Points[key] and AJ.Points[key][kind]) or {} end

function AJ.LoadModel(name)
    local hash = type(name) == 'number' and name or joaat(name)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
    return HasModelLoaded(hash) and hash or nil
end

-- Véhicule de travail à la sortie du dépôt (plaque personnalisée) ; retourne l'entité ou nil
function AJ.SpawnVehicle(model, p, plate, warp)
    local hash = AJ.LoadModel(model)
    if not hash then AJ.Notify('~r~Modèle de véhicule introuvable : ' .. tostring(model)) return nil end
    -- libère l'emplacement si un véhicule le bloque
    local blocked = GetClosestVehicle(p.x + 0.0, p.y + 0.0, p.z + 0.0, 3.5, 0, 71)
    if blocked ~= 0 and not IsPedAPlayer(GetPedInVehicleSeat(blocked, -1)) then SetEntityAsMissionEntity(blocked, true, true) DeleteVehicle(blocked) end
    local veh = CreateVehicle(hash, p.x + 0.0, p.y + 0.0, p.z + 0.0, (p.h or 0.0) + 0.0, true, true)
    SetModelAsNoLongerNeeded(hash)
    if not veh or veh == 0 then return nil end
    SetVehicleNumberPlateText(veh, plate or 'TRAVAIL')
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineOn(veh, true, true, false)
    SetEntityAsMissionEntity(veh, true, true)
    if warp ~= false then TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1) end
    AJ.Ents[#AJ.Ents + 1] = veh
    return veh
end

function AJ.Blip(c, sprite, color, label, route)
    local b = AddBlipForCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
    SetBlipSprite(b, sprite or 1) SetBlipColour(b, color or 0) SetBlipScale(b, 0.85) SetBlipAsShortRange(b, false)
    if route then SetBlipRoute(b, true) SetBlipRouteColour(b, color or 0) end
    BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(label or 'Mission') EndTextCommandSetBlipName(b)
    AJ.Blips[#AJ.Blips + 1] = b
    return b
end

function AJ.RemoveBlip(b) if b and DoesBlipExist(b) then RemoveBlip(b) end end

-- Nettoyage de tout ce que le service a créé (blips, véhicules)
function AJ.Cleanup()
    for _, b in ipairs(AJ.Blips) do AJ.RemoveBlip(b) end
    AJ.Blips = {}
    for _, e in ipairs(AJ.Ents) do
        if DoesEntityExist(e) then SetEntityAsMissionEntity(e, true, true) DeleteEntity(e) end
    end
    AJ.Ents = {}
    AJ.Hud = {}
end

-- Marqueur + distance (retourne la distance)
function AJ.Marker(c, kind, r, g, b)
    local pos = GetEntityCoords(PlayerPedId())
    local d = #(pos - vector3(c.x, c.y, c.z))
    if d < Config.DrawDistance then
        DrawMarker(kind or 1, c.x, c.y, c.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.6, 1.6, 0.7, r or 0, g or 164, b or 255, 110, false, false, 2, false, nil, nil, false)
    end
    return d
end

-- Barre de progression native : retourne true si l'action est menée à terme (X ou éloignement = annulation)
function AJ.Progress(label, seconds, opts)
    opts = opts or {}
    local ped = PlayerPedId()
    local origin = GetEntityCoords(ped)
    local radius = opts.radius or 4.0
    if opts.scenario then TaskStartScenarioInPlace(ped, opts.scenario, 0, true)
    elseif opts.dict then
        RequestAnimDict(opts.dict)
        local t = GetGameTimer() + 2000
        while not HasAnimDictLoaded(opts.dict) and GetGameTimer() < t do Wait(10) end
        TaskPlayAnim(ped, opts.dict, opts.clip, 4.0, 4.0, -1, opts.flag or 49, 0.0, false, false, false)
    end
    local start, total, ok = GetGameTimer(), math.floor(seconds * 1000), true
    while GetGameTimer() - start < total do
        Wait(0)
        ped = PlayerPedId()
        DisableControlAction(0, 24, true) DisableControlAction(0, 25, true) DisableControlAction(0, 140, true) DisableControlAction(0, 141, true) DisableControlAction(0, 142, true)
        local f = (GetGameTimer() - start) / total
        DrawRect(0.5, 0.88, 0.2, 0.026, 0, 0, 0, 170)
        DrawRect(0.5 - 0.1 * (1 - f), 0.88, 0.2 * f, 0.02, 0, 164, 255, 230)
        SetTextScale(0.0, 0.34) SetTextFont(4) SetTextCentre(true) SetTextOutline()
        BeginTextCommandDisplayText('STRING') AddTextComponentSubstringPlayerName(label .. '  ·  X pour annuler') EndTextCommandDisplayText(0.5, 0.845)
        if IsControlJustPressed(0, 73) or IsEntityDead(ped) or IsPedRagdoll(ped) or #(GetEntityCoords(ped) - origin) > radius then ok = false break end
    end
    ClearPedTasks(PlayerPedId())
    return ok
end

-- ─────────────────────────────── Affichage du service (HUD) ───────────────────────────────
function AJ.SetHud(lines) AJ.Hud = lines or {} end

CreateThread(function()
    while true do
        if AJ.Active and #AJ.Hud > 0 then
            local y = 0.40
            DrawRect(0.9, y + 0.012 * #AJ.Hud, 0.17, 0.03 + 0.024 * #AJ.Hud, 12, 14, 20, 175)
            for i, l in ipairs(AJ.Hud) do
                SetTextScale(0.0, i == 1 and 0.36 or 0.32) SetTextFont(4) SetTextOutline() SetTextColour(255, 255, 255, 235)
                BeginTextCommandDisplayText('STRING') AddTextComponentSubstringPlayerName(l) EndTextCommandDisplayText(0.823, y - 0.004 + 0.024 * (i - 1))
            end
            Wait(0)
        else Wait(500) end
    end
end)

-- ─────────────────────────────── Points & dépôts (PNJ + menu) ───────────────────────────────
RegisterNetEvent('aj:client:points', function(p) AJ.Points = p or {} end)
CreateThread(function() Wait(2000) TriggerServerEvent('aj:server:requestPoints') end)

local peds, depotBlips = {}, {}
local uiOpen = false

local function closePanel() uiOpen = false SetNuiFocus(false, false) SendNUIMessage({ action = 'close' }) end

local function openPanel(key)
    ESX.TriggerServerCallback('aj:panel', function(res)
        if not res or not res.ok then return AJ.Notify('~r~' .. ((res and res.error) or 'Indisponible')) end
        uiOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', data = res, accent = PickaxTheme and PickaxTheme.rgb or nil })
    end, key)
end

CreateThread(function()
    while true do
        local sleep = 1000
        local pos = GetEntityCoords(PlayerPedId())
        for key, j in pairs(Config.Jobs) do
            local d = AJ.Points_(key, 'depot')[1]
            if d then
                local dist = #(pos - vector3(d.x, d.y, d.z))
                -- PNJ
                if dist < 70.0 then
                    if not peds[key] or not DoesEntityExist(peds[key]) then
                        local hash = AJ.LoadModel(j.ped)
                        if hash then
                            local ped = CreatePed(4, hash, d.x, d.y, d.z - 1.0, d.h + 0.0, false, false)
                            SetEntityInvincible(ped, true) SetBlockingOfNonTemporaryEvents(ped, true) FreezeEntityPosition(ped, true)
                            TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
                            SetModelAsNoLongerNeeded(hash)
                            peds[key] = ped
                        end
                    end
                elseif peds[key] and DoesEntityExist(peds[key]) then DeleteEntity(peds[key]) peds[key] = nil end
                if dist < Config.DrawDistance then
                    sleep = 0
                    DrawMarker(1, d.x, d.y, d.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.2, 1.2, 0.6, 0, 164, 255, 120, false, false, 2, false, nil, nil, false)
                    if dist < 2.2 and not uiOpen then
                        AJ.Text3D(d.x, d.y, d.z + 1.1, j.label, 0.34)
                        AJ.Help('Appuie sur ~INPUT_PICKUP~ pour parler au recruteur — ' .. j.label)
                        if IsControlJustPressed(0, Config.Interact) then openPanel(key) end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- blips des dépôts
local function rebuildDepotBlips()
    for _, b in ipairs(depotBlips) do AJ.RemoveBlip(b) end
    depotBlips = {}
    for key, j in pairs(Config.Jobs) do
        local d = AJ.Points_(key, 'depot')[1]
        if d then
            local b = AddBlipForCoord(d.x + 0.0, d.y + 0.0, d.z + 0.0)
            SetBlipSprite(b, j.blip.sprite) SetBlipColour(b, j.blip.color) SetBlipScale(b, 0.75) SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(j.label) EndTextCommandSetBlipName(b)
            depotBlips[#depotBlips + 1] = b
        end
    end
end
RegisterNetEvent('aj:client:points', function() SetTimeout(200, rebuildDepotBlips) end)

-- ─────────────────────────────── NUI ───────────────────────────────
RegisterNUICallback('close', function(_, cb) closePanel() cb({}) end)
RegisterNUICallback('act', function(body, cb)
    local key, what = body.key, body.what
    local map = { join = 'aj:join', leave = 'aj:leave', start = 'aj:start' }
    if what == 'stop' then
        ESX.TriggerServerCallback('aj:stop', function() openPanel(key) cb({ ok = true }) end)
        return
    end
    if not map[what] then return cb({ ok = false }) end
    ESX.TriggerServerCallback(map[what], function(res)
        if res and res.ok then
            if what == 'start' then closePanel() else openPanel(key) end
        else
            AJ.Notify('~r~' .. ((res and res.error) or 'Erreur'))
        end
        cb(res or { ok = false })
    end, key)
end)

-- ─────────────────────────────── Début / fin de service ───────────────────────────────
RegisterNetEvent('aj:client:start', function(key, data)
    AJ.Cleanup()
    AJ.Active = key
    local m = AJ.Mod[key]
    if m and m.start then
        local ok, err = pcall(m.start, data or {})
        if not ok then AJ.Notify('~r~Erreur : ' .. tostring(err)) print('^1[activejobs] ' .. tostring(err) .. '^0') end
    end
end)

RegisterNetEvent('aj:client:stop', function(key, reason)
    local m = AJ.Mod[key]
    if m and m.stop then pcall(m.stop) end
    AJ.Active = nil
    AJ.Cleanup()
    if reason and reason ~= '' then AJ.Notify(reason) end
end)

RegisterCommand('finservice', function()
    if AJ.Active then ESX.TriggerServerCallback('aj:stop', function() end) else AJ.Notify('Tu n\'es pas en service.') end
end, false)

RegisterNetEvent('aj:client:printPoints', function(key, list)
    for _, l in ipairs(list or {}) do print('[activejobs] ' .. key .. ' ' .. l) end
    AJ.Notify(('%d point(s) pour %s : liste dans la console F8.'):format(#(list or {}), key))
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, p in pairs(peds) do if DoesEntityExist(p) then DeleteEntity(p) end end
    for _, b in ipairs(depotBlips) do AJ.RemoveBlip(b) end
    AJ.Cleanup()
    if uiOpen then SetNuiFocus(false, false) end
end)
