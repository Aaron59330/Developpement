-- ─────────────────────────────── Drogues (client) ───────────────────────────────
local function timedAction(node, kind, recipeIdx, batches)
    ESX.TriggerServerCallback('illegalbuilder:drug:begin', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Impossible', 'error') end
        CreateThread(function()
            local done = RunAction({ seconds = res.seconds, label = res.label, anim = res.anim })
            TriggerServerEvent('illegalbuilder:server:drugFinish', done)
            if not done then Notify('Action interrompue.', 'error') end
        end)
    end, node.eid, node.pi, kind, recipeIdx, batches)
end

local function openInfo(cbName, panel, node)
    ESX.TriggerServerCallback('illegalbuilder:drug:' .. cbName, function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Indisponible', 'error') end
        res.eid, res.pi = node.eid, node.pi
        OpenPanel(panel, res, { type = 'drug', eid = node.eid, pi = node.pi })
    end, node.eid, node.pi)
end

Handlers.drug = function(node)
    local k = node.kind
    if k == 'harvest' then return timedAction(node, 'harvest') end
    if k == 'process' then return openInfo('processInfo', 'lab', node) end
    if k == 'sell' then return openInfo('sellInfo', 'dealer', node) end
    if k == 'launder' then return openInfo('launderInfo', 'launder', node) end
    if k == 'door' or k == 'exit' then
        ESX.TriggerServerCallback('illegalbuilder:drug:door', function(res)
            if not res or not res.ok then return Notify((res and res.error) or 'Verrouillé', 'error') end
            Teleport(res.to)
        end, node.eid, node.pi, k == 'exit' and 'out' or 'in')
    end
end

-- Fabrication depuis le panneau du laboratoire
NuiLocal['lab:craft'] = function(args, cb)
    local ctx = Ctx
    if not ctx or ctx.type ~= 'drug' then return cb({ ok = false, error = 'Fermé' }) end
    local node = { eid = ctx.eid, pi = ctx.pi }
    ESX.TriggerServerCallback('illegalbuilder:drug:begin', function(res)
        if not res or not res.ok then return cb(res or { ok = false, error = 'Erreur' }) end
        cb({ ok = true })
        CloseUI()
        CreateThread(function()
            local done = RunAction({ seconds = res.seconds, label = res.label, anim = res.anim })
            TriggerServerEvent('illegalbuilder:server:drugFinish', done)
            if not done then Notify('Fabrication interrompue.', 'error') end
        end)
    end, node.eid, node.pi, 'process', args[1], args[2])
end
