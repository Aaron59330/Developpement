-- ─────────────────────────────── Location de véhicules (client) ───────────────────────────────
local function currentVehicle(c)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then return veh end
    veh = GetClosestVehicle(c.x + 0.0, c.y + 0.0, c.z + 0.0, 12.0, 0, 71)
    return veh ~= 0 and veh or nil
end

Handlers.rental = function(node)
    local point = PointOf(node.eid, node.pi)
    if not point then return end
    if node.kind == 'return' then
        local c = point.ret or point.coords
        local veh = currentVehicle(c)
        if not veh or not NetworkGetEntityIsNetworked(veh) then return Notify('Aucun véhicule à rendre ici.', 'error') end
        local netId = NetworkGetNetworkIdFromEntity(veh)
        ESX.TriggerServerCallback('worldbuilder:rental:return', function(res)
            if not res or not res.ok then return Notify((res and res.error) or 'Impossible', 'error') end
            Notify(('Véhicule rendu. Caution remboursée : %d / %d %s'):format(res.refund, res.deposit, Config.Currency), 'success')
        end, node.eid, node.pi, netId)
        return
    end
    ESX.TriggerServerCallback('worldbuilder:rental:list', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Location indisponible', 'error') end
        WBEnrich(res.fleet)
        res.eid, res.pi = node.eid, node.pi
        OpenPanel('rental', res, { type = 'rental', eid = node.eid, pi = node.pi })
    end, node.eid, node.pi)
end

NuiLocal['rental:rent'] = function(args, cb)
    local ctx = Ctx
    if not ctx or ctx.type ~= 'rental' then return cb({ ok = false, error = 'Fermé' }) end
    local point = PointOf(ctx.eid, ctx.pi)
    if not point then return cb({ ok = false, error = 'Introuvable' }) end
    local idx = FreeSpawn(point)
    if not idx then return cb({ ok = false, error = 'Aucune place de sortie libre' }) end
    ESX.TriggerServerCallback('worldbuilder:rental:rent', function(res)
        if not res or not res.ok then return cb(res or { ok = false, error = 'Erreur' }) end
        cb({ ok = true })
        CloseUI()
        local veh = SpawnVehicleAt(point.spawns[res.spawn], res.model, nil, res.plate)
        if not veh then
            TriggerServerEvent('worldbuilder:server:rentalFailed')
            return Notify('Impossible de sortir ce véhicule : tu as été remboursé.', 'error')
        end
        TriggerServerEvent('worldbuilder:server:rentalSpawned', NetworkGetNetworkIdFromEntity(veh))
        Notify(('Véhicule loué (%d %s, caution comprise)%s.'):format(res.paid, Config.Currency, res.minutes > 0 and (' pour %d min'):format(res.minutes) or ''), 'success')
    end, ctx.eid, ctx.pi, args[1], idx, args[2])
end
