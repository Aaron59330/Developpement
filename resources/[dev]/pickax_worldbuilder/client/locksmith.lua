-- ─────────────────────────────── Serrurier (client) ───────────────────────────────
Handlers.locksmith = function(node)
    if node.kind ~= 'shop' then return end
    ServerCall('worldbuilder:locksmith:info', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Serrurier indisponible', 'error') end
        WBEnrich(res.vehicles)
        res.eid, res.pi = node.eid, node.pi
        OpenPanel('locksmith', res, { type = 'locksmith', eid = node.eid, pi = node.pi })
    end, node.eid, node.pi)
end

-- Clés « virtuelles » : utilise le hook Config.GiveKeys (qs-vehiclekeys, wasabi_carlock...)
RegisterNetEvent('worldbuilder:client:giveKeys', function(plate)
    if Config.GiveKeys then pcall(Config.GiveKeys, plate, nil) end
end)
