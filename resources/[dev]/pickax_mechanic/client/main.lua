local ESX = exports['es_extended']:getSharedObject()
local C = Config
local nuiOpen, mgPromise, ctx = false, nil, nil   -- ctx = { netId, veh, plate }
-- ───────────── Rôle du joueur (noms de jobs ESX ou type du Job Builder) ─────────────
local function hasRole(names, types)
    local d = ESX.GetPlayerData()
    local job = d and d.job and d.job.name
    for _, n in ipairs(names or {}) do if job == n then return true end end
    if types and #types > 0 and GetResourceState('pickax_jobbuilder') == 'started' then
        local ok, t = pcall(function() return exports.pickax_jobbuilder:GetJobType() end)
        if ok and t then for _, x in ipairs(types) do if t == x then return true end end end
    end
    return false
end


local function notify(kind, txt) lib.notify({ type = kind, description = txt }) end
local function nui(m) SendNUIMessage(m) end
local function closeNui()
    if not nuiOpen then return end
    nuiOpen = false
    SetNuiFocus(false, false)
    nui({ action = 'close' })
    if ctx and ctx.veh and DoesEntityExist(ctx.veh) then SetVehicleDoorShut(ctx.veh, 4, false) end
    ctx = nil
end
RegisterNUICallback('close', function(_, cb) closeNui() cb(1) end)

-- Réserve le contrôle réseau de l'entité avant de la modifier
local function control(ent)
    local t = GetGameTimer() + 1500
    while not NetworkHasControlOfEntity(ent) and GetGameTimer() < t do NetworkRequestControlOfEntity(ent) Wait(50) end
    return NetworkHasControlOfEntity(ent)
end

-- ───────────── Diagnostic ─────────────
local function closestVehicle()
    local ped = PlayerPedId()
    local pc = GetEntityCoords(ped)
    local v = GetClosestVehicle(pc.x, pc.y, pc.z, C.MaxDistance, 0, 71)
    if v ~= 0 and NetworkGetEntityIsNetworked(v) then return v end
end

local function openDiag(target)
    if nuiOpen then return end
    local veh = (type(target) == 'number' and DoesEntityExist(target)) and target or closestVehicle()
    if not veh then return notify('error', 'Aucun véhicule à proximité.') end
    if IsPedInAnyVehicle(PlayerPedId(), false) then return notify('error', 'Descends du véhicule.') end
    local netId = NetworkGetNetworkIdFromEntity(veh)
    ESX.TriggerServerCallback('pickax_mechanic:info', function(r)
        if not r or not r.ok then return notify('error', (r and r.error) or 'Indisponible') end
        ctx = { netId = netId, veh = veh, plate = r.plate }
        nuiOpen = true
        SetNuiFocus(true, true)
        SetVehicleDoorOpen(veh, 4, false, false)
        local name = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(veh)))
        nui({ action = 'diag', data = r, name = (name ~= 'NULL' and name) or 'Véhicule' })
    end, netId, GetVehicleEngineHealth(veh), GetVehicleBodyHealth(veh))
end
if C.UseCommands then RegisterCommand(C.Command, function() openDiag() end, false) end
exports('OpenDiagnostic', openDiag)

-- Menu contextuel : clic droit sur un véhicule (mécanicien)
local CTX_ACTIONS = { { id = 'diag', label = 'Diagnostic du véhicule', target = 'vehicle' } }
exports('ContextCan', function(id, ent) return hasRole(C.Jobs, C.JobTypes) and not IsPedInAnyVehicle(PlayerPedId(), false) and #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ent)) <= C.MaxDistance + 1.5 end)
exports('ContextDo', function(id, ent) openDiag(ent) end)
local function registerContext() exports.pickax_core:RegisterContextActions(GetCurrentResourceName(), CTX_ACTIONS) end
CreateThread(function() Wait(2500) registerContext() end)
AddEventHandler('onResourceStart', function(r) if r == 'pickax_core' then SetTimeout(2500, registerContext) end end)

local function refreshDiag()
    if not ctx or not DoesEntityExist(ctx.veh) then return end
    ESX.TriggerServerCallback('pickax_mechanic:info', function(r)
        if r and r.ok then nui({ action = 'diagUpdate', data = r }) end
    end, ctx.netId, GetVehicleEngineHealth(ctx.veh), GetVehicleBodyHealth(ctx.veh))
end

-- ───────────── Réparation : serveur → mini-jeu (NUI) → serveur ─────────────
RegisterNUICallback('repairBegin', function(d, cb)
    if not ctx then return cb({ ok = false, error = 'Aucun véhicule' }) end
    ESX.TriggerServerCallback('pickax_mechanic:repairBegin', function(r) cb(r or { ok = false, error = 'Erreur' }) end, ctx.netId, d.comp)
end)

local function applyNatives(veh, apply)
    if not apply or not DoesEntityExist(veh) then return end
    control(veh)
    if apply.engine then SetVehicleEngineHealth(veh, apply.engine * 10.0) SetVehicleUndriveable(veh, false) end
    if apply.body then
        SetVehicleBodyHealth(veh, apply.body * 10.0)
        if apply.body >= 60 then SetVehicleDeformationFixed(veh) for i = 0, 7 do FixVehicleWindow(veh, i) end end
        if apply.body >= 95 then SetVehicleFixed(veh) end
    end
    if apply.tires then for i = 0, 7 do SetVehicleTyreFixed(veh, i) end end
end

RegisterNUICallback('repairCancel', function(_, cb) TriggerServerEvent('pickax_mechanic:cancel') cb(1) end)
RegisterNUICallback('repairEnd', function(d, cb)
    ESX.TriggerServerCallback('pickax_mechanic:repairEnd', function(r)
        if r and r.ok and not r.failed then applyNatives(ctx and ctx.veh, r.apply) end
        cb(r or { ok = false, error = 'Erreur' })
        SetTimeout(300, refreshDiag)
    end, d.score)
end)

-- ───────────── Magasin de pièces ─────────────
local shopIdx = nil
RegisterNUICallback('shopBuy', function(d, cb)
    ESX.TriggerServerCallback('pickax_mechanic:buy', function(r) cb(r or { ok = false, error = 'Erreur' }) end, shopIdx, d.item, d.qty)
end)
RegisterNUICallback('shopList', function(_, cb)
    ESX.TriggerServerCallback('pickax_mechanic:shopOpen', function(r) cb(r or { ok = false }) end, shopIdx)
end)

local function openShop(i)
    if nuiOpen then return end
    ESX.TriggerServerCallback('pickax_mechanic:shopOpen', function(r)
        if not r or not r.ok then return notify('error', (r and r.error) or 'Indisponible') end
        shopIdx = i
        nuiOpen = true
        SetNuiFocus(true, true)
        nui({ action = 'shop', data = r })
    end, i)
end

local blips, peds = {}, {}
local function help(txt) PickaxTheme.Help(txt) end

CreateThread(function()
    for i, s in ipairs(C.Shops) do
        if s.blip then
            local b = AddBlipForCoord(s.coords.x, s.coords.y, s.coords.z)
            SetBlipSprite(b, 402) SetBlipColour(b, 47) SetBlipScale(b, 0.6) SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(s.label) EndTextCommandSetBlipName(b)
            blips[#blips + 1] = b
        end
    end
    while true do
        local sleep = 1000
        local pc = GetEntityCoords(PlayerPedId())
        for i, s in ipairs(C.Shops) do
            local d = #(pc - s.coords)
            if d < 40.0 and s.ped and not peds[i] then
                local h = joaat(s.ped)
                if IsModelInCdimage(h) then
                    RequestModel(h)
                    local t = GetGameTimer() + 3000
                    while not HasModelLoaded(h) and GetGameTimer() < t do Wait(20) end
                    if HasModelLoaded(h) then
                        local p = CreatePed(4, h, s.coords.x, s.coords.y, s.coords.z - 1.0, s.pedHeading or 0.0, false, true)
                        SetEntityInvincible(p, true) SetBlockingOfNonTemporaryEvents(p, true) FreezeEntityPosition(p, true)
                        TaskStartScenarioInPlace(p, 'WORLD_HUMAN_CLIPBOARD', 0, true)
                        peds[i] = p
                    end
                    SetModelAsNoLongerNeeded(h)
                end
            end
            if d < 15.0 and not nuiOpen then
                sleep = 0
                PickaxTheme.Marker(s.coords.x, s.coords.y, s.coords.z - 1.0)
                if d < C.Shop.Distance then
                    help('Appuie sur ~INPUT_CONTEXT~ : magasin de pièces')
                    if IsControlJustPressed(0, 38) then openShop(i) Wait(400) end
                end
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, b in ipairs(blips) do RemoveBlip(b) end
    for _, p in pairs(peds) do DeleteEntity(p) end
    if nuiOpen then SetNuiFocus(false, false) end
end)

-- ───────────── Effets d'un mauvais état + rapports d'usure (conducteur) ─────────────
local E = C.Effects
local cur = { veh = 0, base = nil }

local function handlingBase(veh)
    return {
        brake = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fBrakeForce'),
        trac = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionCurveMax'),
        susp = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fSuspensionForce'),
    }
end

local function restore(veh, base)
    if veh ~= 0 and base and DoesEntityExist(veh) then
        SetVehicleHandlingFloat(veh, 'CHandlingData', 'fBrakeForce', base.brake)
        SetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionCurveMax', base.trac)
        SetVehicleHandlingFloat(veh, 'CHandlingData', 'fSuspensionForce', base.susp)
        SetVehicleEnginePowerMultiplier(veh, 0.0)
        SetVehicleEngineTorqueMultiplier(veh, 1.0)
    end
end

local function applyEffects(veh, st)
    local base = cur.base
    if not base then return end
    local eng, brk, tire, tr, sus = st.engine or 100, st.brakes or 100, st.tires or 100, st.transmission or 100, st.suspension or 100
    -- puissance : jusqu'à -45 % quand le moteur est à 0 %
    local pw = (eng < E.EnginePower) and (1.0 - 0.45 * (1 - eng / E.EnginePower)) or 1.0
    if tr < E.TransmissionBad then pw = pw * (0.7 + 0.3 * tr / E.TransmissionBad) end
    SetVehicleEngineTorqueMultiplier(veh, pw)
    -- freins
    local bf = (brk < E.BrakeWeak) and (0.35 + 0.65 * brk / E.BrakeWeak) or 1.0
    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fBrakeForce', base.brake * bf)
    -- adhérence : pneus et suspension
    local g = 1.0
    if tire < E.TyreGrip then g = g * (0.7 + 0.3 * tire / E.TyreGrip) end
    if sus < E.SuspensionBad then g = g * (0.85 + 0.15 * sus / E.SuspensionBad) end
    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionCurveMax', base.trac * g)
    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fSuspensionForce', base.susp * ((sus < E.SuspensionBad) and (0.7 + 0.3 * sus / E.SuspensionBad) or 1.0))
end

CreateThread(function()
    local lastReport, dist, maxKmh, hard, impacts = GetGameTimer(), 0.0, 0.0, 0, 0
    local lastPos, lastSpeed, lastHealth = nil, 0.0, nil
    while true do
        Wait(500)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and NetworkGetEntityIsNetworked(veh) then
            if cur.veh ~= veh then
                restore(cur.veh, cur.base)
                cur = { veh = veh, base = handlingBase(veh) }
                lastPos, lastSpeed, lastHealth = GetEntityCoords(veh), 0.0, GetEntityHealth(veh)
                dist, maxKmh, hard, impacts, lastReport = 0.0, 0.0, 0, 0, GetGameTimer()
                TriggerServerEvent('pickax_mechanic:enter', NetworkGetNetworkIdFromEntity(veh))
            end
            local pos = GetEntityCoords(veh)
            local spd = GetEntitySpeed(veh)
            if lastPos then dist = dist + #(pos - lastPos) end
            lastPos = pos
            maxKmh = math.max(maxKmh, spd * 3.6)
            if lastSpeed - spd > 9.0 and IsControlPressed(0, 72) then hard = hard + 1 end   -- freinage brusque
            if lastSpeed - spd > 14.0 and not IsControlPressed(0, 72) then impacts = impacts + 1 end   -- choc
            lastSpeed = spd
            local st = Entity(veh).state.mech
            if st then
                applyEffects(veh, st)
                local eng = st.engine or 100
                if eng < E.EngineStall and math.random(100) <= 2 and spd > 3.0 then
                    SetVehicleEngineOn(veh, false, true, true)
                    notify('error', 'Le moteur cale…')
                end
                if (st.tires or 100) < E.TyreBurst and spd * 3.6 > 90.0 and math.random(100) <= 3 then
                    SetVehicleTyreBurst(veh, math.random(0, 3), false, 1000.0)
                    notify('error', 'Un pneu a éclaté !')
                end
            end
            if GetGameTimer() - lastReport >= C.Wear.ReportEvery * 1000 then
                TriggerServerEvent('pickax_mechanic:wear', NetworkGetNetworkIdFromEntity(veh), dist, maxKmh, hard, impacts)
                lastReport, dist, maxKmh, hard, impacts = GetGameTimer(), 0.0, 0.0, 0, 0
            end
        elseif cur.veh ~= 0 then
            restore(cur.veh, cur.base)
            cur = { veh = 0, base = nil }
        end
    end
end)
