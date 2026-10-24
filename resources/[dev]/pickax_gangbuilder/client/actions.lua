-- ─────────────────────────────── Actions du menu gang (F7) ───────────────────────────────

local isCuffed = false
local draggedBy = nil

local function loadAnim(dict)
    RequestAnimDict(dict)
    local t = GetGameTimer()
    while not HasAnimDictLoaded(dict) and GetGameTimer() - t < 3000 do Wait(10) end
end

local function hasAction(id)
    local gc = GetGangConfig()
    if not gc then return false end
    for _, a in ipairs(gc.actions or {}) do if a == id then return true end end
    return false
end

-- Appelée par le NUI (NuiLocal.doAction)
function RunAction(id)
    if not hasAction(id) then return GBNotify('~r~Action non autorisée.') end
    local cfg = Config.Actions[id]

    if id == 'info' then
        return ESX.TriggerServerCallback('gangbuilder:info', function(res)
            if not res or not res.ok then return GBNotify('~r~' .. ((res and res.error) or 'Erreur')) end
            OpenUI({ action = 'open', kind = 'info', data = res })
        end)
    end
    if id == 'props' then
        CloseUI()
        return SetTimeout(150, function() OpenPropsMenu() end)
    end
    if id == 'tablet' then
        CloseUI()
        return SetTimeout(150, function() OpenGangTablet() end)
    end
    if id == 'leave' then
        local gc = GetGangConfig()
        return OpenUI({ action = 'open', kind = 'leave', data = { gangLabel = gc and gc.label or '' } })
    end

    if cfg and cfg.target then
        local target = GetNearestPlayerId()
        if not target then return GBNotify('~r~Aucun joueur à proximité.') end
        ESX.TriggerServerCallback('gangbuilder:action', function(res)
            if not (res and res.ok) then GBNotify('~r~' .. ((res and res.error) or 'Erreur')) end
        end, id, target)
    end
end

-- ─────────────────────────────── Effets côté cible ───────────────────────────────
RegisterNetEvent('gangbuilder:client:cuff', function()
    local ped = PlayerPedId()
    isCuffed = not isCuffed
    LocalPlayer.state:set('gbCuffed', isCuffed, true)
    if isCuffed then
        loadAnim('mp_arresting')
        SetEnableHandcuffs(ped, true)
        TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0.0, false, false, false)
        GBNotify('Tu as été ~r~menotté~s~.')
    else
        SetEnableHandcuffs(ped, false)
        ClearPedSecondaryTask(ped)
        if draggedBy then
            DetachEntity(ped, true, false)
            draggedBy = nil
        end
        GBNotify('Tu as été ~g~démenotté~s~.')
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

RegisterNetEvent('gangbuilder:client:drag', function(captor)
    if not isCuffed then return end
    local ped = PlayerPedId()
    if draggedBy then
        draggedBy = nil
        DetachEntity(ped, true, false)
        return
    end
    local captorPed = GetPlayerPed(GetPlayerFromServerId(captor))
    if captorPed == 0 then return end
    draggedBy = captor
    AttachEntityToEntity(ped, captorPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)
end)

CreateThread(function()
    while true do
        Wait(1000)
        if draggedBy then
            local captorPed = GetPlayerPed(GetPlayerFromServerId(draggedBy))
            if captorPed == 0 or IsEntityDead(captorPed) or not isCuffed then
                draggedBy = nil
                DetachEntity(PlayerPedId(), true, false)
            end
        end
    end
end)

RegisterNetEvent('gangbuilder:client:search', function(target)
    exports.ox_inventory:openInventory('player', target)
end)
