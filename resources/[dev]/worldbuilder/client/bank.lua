-- ─────────────────────────────── Banques (client) ───────────────────────────────
Handlers.bank = function(node)
    ServerCall('worldbuilder:bank:info', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Banque indisponible', 'error') end
        res.eid, res.pi = node.eid, node.pi
        OpenPanel('bank', res, { type = 'bank', eid = node.eid, pi = node.pi })
    end, node.eid, node.pi)
end
