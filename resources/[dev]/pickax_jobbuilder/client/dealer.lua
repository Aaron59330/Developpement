-- ─────────────────────────────── Concession (client) ───────────────────────────────
for _, n in ipairs({ 'dealer:manage', 'dealer:saveCatalog', 'dealer:offer', 'dealer:offerSelf', 'dealer:buy' }) do NuiRemote[n] = true end

function OpenDealerPanel()
    ESX.TriggerServerCallback('jobbuilder:dealer:manage', function(res)
        if not res or not res.ok then return JBNotify('~r~' .. ((res and res.error) or 'Erreur')) end
        OpenUI({ action = 'open', kind = 'dealer', data = res })
    end)
end

RegisterNetEvent('jobbuilder:client:dealerOffer', function(id, data)
    data.id = id
    OpenUI({ action = 'open', kind = 'dealerOffer', data = data })
end)

NuiLocal.dealerAnswer = function(args, cb)
    TriggerServerEvent('jobbuilder:server:dealerAnswer', args[1], args[2] == true)
    CloseUI()
    cb({ ok = true })
end

local function loadModel(model)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then return nil end
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(20) end
    return HasModelLoaded(hash) and hash or nil
end

-- ─────────────────────────────── Livraison après achat ───────────────────────────────
RegisterNetEvent('jobbuilder:client:dealerDeliver', function(d)
    CreateThread(function()
        local hash = loadModel(d.model)
        if not hash then return JBNotify('~r~Modèle introuvable, contacte le staff.') end
        local c = d.spawn
        local veh = CreateVehicle(hash, c.x + 0.0, c.y + 0.0, c.z + 0.0, (c.h or 0.0) + 0.0, true, false)
        SetModelAsNoLongerNeeded(hash)
        SetVehicleNumberPlateText(veh, d.plate)
        SetVehicleOnGroundProperly(veh)
        SetVehicleFuelLevel(veh, 100.0)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        Config.OnVehicleSpawned(veh, d.plate)
        if GetResourceState('CorePickax') == 'started' then TriggerServerEvent('CorePickax:registerkey', d.plate, 'no', false) end     -- clés du véhicule acheté (système de clés CorePickax)
        JBNotify(('~g~%s~s~ livré ! Plaque : ~b~%s'):format(d.label or 'Véhicule', d.plate))
        Wait(1500)
        local props = ESX.Game.GetVehicleProperties(veh)
        if props then TriggerServerEvent('jobbuilder:server:dealerProps', d.plate, props) end
    end)
end)

-- ─────────────────────────────── Essai routier ───────────────────────────────
local testing = false

NuiLocal['dealer:test'] = function(args, cb)
    if testing then return cb({ ok = false, error = 'Tu as déjà un essai en cours' }) end
    ESX.TriggerServerCallback('jobbuilder:dealer:test', function(res)
        if not res or not res.ok then return cb(res or { ok = false, error = 'Erreur' }) end
        CloseUI()
        cb({ ok = true })
        CreateThread(function()
            local ped = PlayerPedId()
            local origin = GetEntityCoords(ped)
            local originH = GetEntityHeading(ped)
            local hash = loadModel(res.model)
            if not hash then
                TriggerServerEvent('jobbuilder:server:testEnd')
                return JBNotify('~r~Modèle introuvable.')
            end
            testing = true
            local c = res.spawn
            local veh = CreateVehicle(hash, c.x + 0.0, c.y + 0.0, c.z + 0.0, (c.h or 0.0) + 0.0, true, false)
            SetModelAsNoLongerNeeded(hash)
            SetVehicleNumberPlateText(veh, res.plate)
            SetVehicleOnGroundProperly(veh)
            SetVehicleFuelLevel(veh, 100.0)
            TaskWarpPedIntoVehicle(ped, veh, -1)
            Config.OnVehicleSpawned(veh, res.plate)
            local untilT = GetGameTimer() + res.seconds * 1000
            while testing do
                local left = math.ceil((untilT - GetGameTimer()) / 1000)
                if left <= 0 or not DoesEntityExist(veh) or IsEntityDead(ped) or GetVehiclePedIsIn(ped, false) ~= veh and left < res.seconds - 3 then break end
                SetTextFont(4) SetTextScale(0.0, 0.5) SetTextColour(255, 255, 255, 230) SetTextOutline()
                SetTextEntry('STRING') AddTextComponentString(('Essai : %s — %d s restantes'):format(res.label or '', left))
                DrawText(0.5 - 0.1, 0.04)
                Wait(0)
            end
            if DoesEntityExist(veh) then
                TaskLeaveVehicle(ped, veh, 16)
                Wait(300)
                ESX.Game.DeleteVehicle(veh)
            end
            SetEntityCoords(PlayerPedId(), origin.x, origin.y, origin.z, false, false, false, false)
            SetEntityHeading(PlayerPedId(), originH)
            testing = false
            TriggerServerEvent('jobbuilder:server:testEnd')
            JBNotify('Essai terminé.')
        end)
    end, args[1], args[2])
end

-- ─────────────────────────────── Véhicules d'exposition (locaux, figés) ───────────────────────────────
local displays = {}   -- [pointId] = { entity, model }

local function removeDisplay(id)
    local d = displays[id]
    if d and DoesEntityExist(d.entity) then DeleteEntity(d.entity) end
    displays[id] = nil
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for id in pairs(displays) do removeDisplay(id) end
end)

CreateThread(function()
    while true do
        Wait(1500)
        local pos = GetEntityCoords(PlayerPedId())
        local seen = {}
        for _, p in ipairs(GetPoints()) do
            if p.type == 'display' and p.model then
                seen[p.id] = true
                local c = p.coords
                local dist = #(pos - vector3(c.x, c.y, c.z))
                local d = displays[p.id]
                if d and d.model ~= p.model then removeDisplay(p.id) d = nil end
                if dist < Config.Dealer.DisplayDistance and not d then
                    local hash = loadModel(p.model)
                    if hash then
                        local veh = CreateVehicle(hash, c.x + 0.0, c.y + 0.0, c.z - 0.95, (c.h or 0.0) + 0.0, false, false)
                        SetModelAsNoLongerNeeded(hash)
                        SetVehicleOnGroundProperly(veh)
                        SetEntityInvincible(veh, true)
                        SetVehicleDoorsLocked(veh, 2)
                        SetVehicleNumberPlateText(veh, 'EXPO')
                        if p.color then SetVehicleColours(veh, p.color, p.color) end
                        FreezeEntityPosition(veh, true)
                        displays[p.id] = { entity = veh, model = p.model }
                    end
                elseif d and dist > Config.Dealer.DisplayDistance + 25.0 then
                    removeDisplay(p.id)
                end
            end
        end
        for id in pairs(displays) do if not seen[id] then removeDisplay(id) end end
    end
end)
