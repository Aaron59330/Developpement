-- ─────────────────────────────── Stations de lavage (client) ───────────────────────────────
local washing = nil

local function driverVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then return veh end
end

Handlers.carwash = function(node)
    if node.kind ~= 'wash' then return end
    local veh = driverVehicle()
    if not veh then return Notify('Entre dans la station au volant de ton véhicule.', 'error') end
    ServerCall('worldbuilder:carwash:info', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Station indisponible', 'error') end
        res.eid, res.pi = node.eid, node.pi
        res.vehicle = VehicleLabel(GetEntityModel(veh))
        res.dirt = math.floor((GetVehicleDirtLevel(veh) / 15.0) * 100 + 0.5)
        washing = veh
        OpenPanel('carwash', res, { type = 'carwash', eid = node.eid, pi = node.pi })
    end, node.eid, node.pi)
end

NuiLocal['carwash:start'] = function(args, cb)
    local ctx = Ctx
    local veh = washing
    if not ctx or ctx.type ~= 'carwash' or not veh or not DoesEntityExist(veh) then return cb({ ok = false, error = 'Véhicule introuvable' }) end
    ESX.TriggerServerCallback('worldbuilder:carwash:begin', function(res)
        if not res or not res.ok then return cb(res or { ok = false, error = 'Erreur' }) end
        cb({ ok = true })
        CloseUI()
        CreateThread(function()
            Busy = true
            FreezeEntityPosition(veh, true)
            SetVehicleEngineOn(veh, false, true, true)
            SendNUIMessage({ action = 'progress', label = res.label, ms = math.floor(res.seconds * 1000), hint = 'X pour annuler' })
            local finish, ok = GetGameTimer() + math.floor(res.seconds * 1000), true
            while GetGameTimer() < finish do
                DisableControlAction(0, 71, true) DisableControlAction(0, 72, true) DisableControlAction(0, 75, true)
                if IsControlJustPressed(0, Config.CancelKey or 73) or not DoesEntityExist(veh) or GetVehiclePedIsIn(PlayerPedId(), false) ~= veh then ok = false break end
                -- gouttelettes d'eau autour du véhicule
                if GetGameTimer() % 6 == 0 then
                    local c = GetEntityCoords(veh)
                    UseParticleFxAsset('core')
                    StartParticleFxNonLoopedAtCoord('ent_amb_water_splash_sml', c.x, c.y, c.z + 1.4, 0.0, 0.0, 0.0, 1.0, false, false, false)
                end
                Wait(0)
            end
            SendNUIMessage({ action = 'progressEnd' })
            if DoesEntityExist(veh) then FreezeEntityPosition(veh, false) end
            Busy = false
            TriggerServerEvent('worldbuilder:server:washFinish', ok)
            if not ok then Notify('Lavage interrompu.', 'error') end
        end)
    end, ctx.eid, ctx.pi, args[1], args[2])
end

RegisterNetEvent('worldbuilder:client:washDone', function(paid)
    local veh = washing
    if veh and DoesEntityExist(veh) then
        WashDecalsFromVehicle(veh, 1.0)
        SetVehicleDirtLevel(veh, 0.0)
    end
    Notify(('Véhicule lavé (%d %s).'):format(math.floor(paid), Config.Currency), 'success')
end)
