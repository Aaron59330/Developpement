-- ─────────────────────────────── Actions métier (menu F6) ───────────────────────────────

local isCuffed = false
local draggedBy = nil

local function loadAnim(dict)
    RequestAnimDict(dict)
    local t = GetGameTimer()
    while not HasAnimDictLoaded(dict) and GetGameTimer() - t < 3000 do Wait(10) end
end

local function hasAction(id)
    local jc = GetJobConfig()
    if not jc then return false end
    for _, a in ipairs(jc.actions or {}) do if a == id then return true end end
    return false
end

local function closestVehicle(maxDist)
    local ped = PlayerPedId()
    local current = GetVehiclePedIsIn(ped, false)
    if current ~= 0 then return current end
    local pos = GetEntityCoords(ped)
    local best, bestDist = nil, maxDist
    for _, v in ipairs(GetGamePool('CVehicle')) do
        local d = #(pos - GetEntityCoords(v))
        if d < bestDist then best, bestDist = v, d end
    end
    return best
end

local function vehicleWork(scenario, duration, done)
    local veh = closestVehicle(4.0)
    if not veh then return ESX.ShowNotification('~r~Aucun véhicule à proximité.') end
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) ~= 0 then return ESX.ShowNotification('~r~Sors du véhicule d\'abord.') end
    TaskStartScenarioInPlace(ped, scenario, 0, true)
    local start, startPos = GetGameTimer(), GetEntityCoords(ped)
    while GetGameTimer() - start < duration do
        Wait(250)
        if #(GetEntityCoords(ped) - startPos) > 1.5 or IsEntityDead(ped) then
            ClearPedTasks(ped)
            return ESX.ShowNotification('~r~Action annulée.')
        end
    end
    ClearPedTasks(ped)
    done(veh)
end

-- Appelée par le NUI (Local.doAction)
function RunAction(id, label, amount)
    if not hasAction(id) then return ESX.ShowNotification('~r~Action non autorisée.') end
    local cfg = Config.Actions[id]

    if id == 'missions' then
        if not OpenMissionStatus then return ESX.ShowNotification('~r~client/missions.lua non chargé : fais ~s~refresh~r~ puis ~s~restart jobbuilder') end
        return OpenMissionStatus()
    end
    if id == 'dealership' then
        if not OpenDealerPanel then return ESX.ShowNotification('~r~client/dealer.lua non chargé : fais ~s~refresh~r~ puis ~s~restart jobbuilder') end
        return OpenDealerPanel()
    end
    if id == 'government' then
        if not OpenGovPanel then return ESX.ShowNotification('~r~client/gov.lua non chargé : fais ~s~refresh~r~ puis ~s~restart jobbuilder') end
        return OpenGovPanel()
    end

    if id == 'properties' then
        if not OpenAgencyPanel then
            return ESX.ShowNotification('~r~client/property.lua non chargé : fais ~s~refresh~r~ puis ~s~restart jobbuilder~r~ (vérifie qu\'il est bien dans fxmanifest.lua).')
        end
        return OpenAgencyPanel()
    end

    if id == 'repair' then
        return vehicleWork('PROP_HUMAN_BUM_BIN', Config.ActionDuration.repair, function(veh)
            SetVehicleFixed(veh)
            SetVehicleDeformationFixed(veh)
            SetVehicleEngineHealth(veh, 1000.0)
            SetVehicleUndriveable(veh, false)
            ESX.ShowNotification('~g~Véhicule réparé.')
        end)
    elseif id == 'clean' then
        return vehicleWork('WORLD_HUMAN_MAID_CLEAN', Config.ActionDuration.clean, function(veh)
            SetVehicleDirtLevel(veh, 0.0)
            ESX.ShowNotification('~g~Véhicule nettoyé.')
        end)
    end

    if cfg and cfg.target then
        local target = GetNearestPlayerId()
        if not target then return ESX.ShowNotification('~r~Aucun joueur à proximité.') end
        if id == 'invoice' then
            ESX.TriggerServerCallback('jobbuilder:invoice:send', function(res)
                if res and res.ok then ESX.ShowNotification('~g~Facture envoyée.')
                else ESX.ShowNotification('~r~' .. ((res and res.error) or 'Erreur')) end
            end, target, label, amount)
            return
        end
        ESX.TriggerServerCallback('jobbuilder:action', function(res)
            if not (res and res.ok) then ESX.ShowNotification('~r~' .. ((res and res.error) or 'Erreur')) end
        end, id, target)
    end
end

-- ─────────────────────────────── Effets côté cible ───────────────────────────────
RegisterNetEvent('jobbuilder:client:cuff', function()
    local ped = PlayerPedId()
    isCuffed = not isCuffed
    LocalPlayer.state:set('jbCuffed', isCuffed, true)
    if isCuffed then
        loadAnim('mp_arresting')
        SetEnableHandcuffs(ped, true)
        TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0.0, false, false, false)
        ESX.ShowNotification('Tu as été ~r~menotté~s~.')
    else
        SetEnableHandcuffs(ped, false)
        ClearPedSecondaryTask(ped)
        if draggedBy then
            DetachEntity(ped, true, false)
            draggedBy = nil
        end
        ESX.ShowNotification('Tu as été ~g~démenotté~s~.')
    end
end)

CreateThread(function()
    while true do
        if isCuffed then
            local ped = PlayerPedId()
            DisableControlAction(0, 24, true) DisableControlAction(0, 25, true) -- tir / visée
            DisableControlAction(0, 140, true) DisableControlAction(0, 141, true) DisableControlAction(0, 142, true) -- mêlée
            DisableControlAction(0, 21, true) DisableControlAction(0, 22, true) -- sprint / saut
            DisableControlAction(0, 23, true) -- entrer véhicule
            DisableControlAction(0, 37, true) -- roue d'armes
            if not IsEntityPlayingAnim(ped, 'mp_arresting', 'idle', 3) and not IsPedInAnyVehicle(ped, false) then
                loadAnim('mp_arresting')
                TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0.0, false, false, false)
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

RegisterNetEvent('jobbuilder:client:drag', function(officer)
    if not isCuffed then return end
    local ped = PlayerPedId()
    if draggedBy then
        draggedBy = nil
        DetachEntity(ped, true, false)
        return
    end
    local officerPed = GetPlayerPed(GetPlayerFromServerId(officer))
    if officerPed == 0 then return end
    draggedBy = officer
    AttachEntityToEntity(ped, officerPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)
end)

CreateThread(function()
    while true do
        Wait(1000)
        if draggedBy then
            local officerPed = GetPlayerPed(GetPlayerFromServerId(draggedBy))
            if officerPed == 0 or IsEntityDead(officerPed) or not isCuffed then
                draggedBy = nil
                DetachEntity(PlayerPedId(), true, false)
            end
        end
    end
end)

RegisterNetEvent('jobbuilder:client:search', function(target)
    exports.ox_inventory:openInventory('player', target)
end)

RegisterNetEvent('jobbuilder:client:heal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ESX.ShowNotification('~g~Tu as été soigné.')
end)

-- ─────────────────────────────── Facture reçue ───────────────────────────────
RegisterNetEvent('jobbuilder:client:invoice', function(id, jobLabel, label, amount, offer)
    OpenUI({ action = 'open', kind = 'invoice', data = { id = id, jobLabel = jobLabel, label = label, amount = amount, offer = offer } })
end)
