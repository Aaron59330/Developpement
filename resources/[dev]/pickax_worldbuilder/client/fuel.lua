-- ─────────────────────────────── Stations essence (client) ───────────────────────────────
local fuelTarget = nil

local function nearestVehicle(c)
    local veh = GetClosestVehicle(c.x + 0.0, c.y + 0.0, c.z + 0.0, 8.0, 0, 71)
    return veh ~= 0 and veh or nil
end

Handlers.fuel = function(node)
    local point = PointOf(node.eid, node.pi)
    if not point then return end
    if IsPedInAnyVehicle(PlayerPedId(), false) then return Notify('Descends du véhicule pour faire le plein.', 'error') end
    local veh = nearestVehicle(point.coords)
    ESX.TriggerServerCallback('worldbuilder:fuel:info', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Station indisponible', 'error') end
        res.eid, res.pi = node.eid, node.pi
        if veh then
            res.vehicle = VehicleLabel(GetEntityModel(veh))
            res.level = math.floor((Config.GetFuel and Config.GetFuel(veh) or GetVehicleFuelLevel(veh)) + 0.5)
        end
        fuelTarget = veh
        OpenPanel('fuel', res, { type = 'fuel', eid = node.eid, pi = node.pi })
    end, node.eid, node.pi)
end

NuiLocal['fuel:fill'] = function(args, cb)
    local ctx = Ctx
    if not ctx or ctx.type ~= 'fuel' then return cb({ ok = false, error = 'Fermé' }) end
    local veh = fuelTarget
    if not veh or not DoesEntityExist(veh) then return cb({ ok = false, error = 'Aucun véhicule à proximité de la pompe' }) end
    ESX.TriggerServerCallback('worldbuilder:fuel:begin', function(res)
        if not res or not res.ok then return cb(res or { ok = false, error = 'Erreur' }) end
        cb({ ok = true })
        CloseUI()
        CreateThread(function()
            SetVehicleEngineOn(veh, false, true, true)
            local done = RunAction({ seconds = res.seconds, label = ('Plein : %d L'):format(res.liters), anim = 'fuel', radius = 6.0 })
            TriggerServerEvent('worldbuilder:server:fuelFinish', done)
            if not done then Notify('Plein interrompu.', 'error') end
        end)
    end, ctx.eid, ctx.pi, args[1], args[2])
end

RegisterNetEvent('worldbuilder:client:fuelDone', function(liters, cost)
    local veh = fuelTarget
    if veh and DoesEntityExist(veh) then
        local cur = Config.GetFuel and Config.GetFuel(veh) or GetVehicleFuelLevel(veh)
        Config.SetFuel(veh, math.min(100.0, cur + liters))
    end
    Notify(('Plein effectué : %d L pour %d %s.'):format(liters, cost, Config.Currency), 'success')
end)
