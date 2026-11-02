-- ─────────────────────────────── Atelier d'armes (client) ───────────────────────────────
-- Les natives d'armes ne sont lisibles que côté client : on calcule ici la compatibilité des accessoires et le nombre de teintes de chaque arme,
-- puis le panneau les affiche. Le serveur revérifie et applique tout.
local function buildInfo(res)
    local cu = res.custom
    if not cu then return res end
    for _, w in ipairs(cu.weapons or {}) do
        local hash = joaat(w.name)
        w.tints = math.max(1, GetWeaponTintCount(hash))
        w.compat = {}
        for _, a in ipairs(cu.attachments or {}) do
            for _, h in ipairs(a.hashes or {}) do
                if DoesWeaponTakeWeaponComponent(hash, h) then w.compat[#w.compat + 1] = a.name break end
            end
        end
    end
    for _, a in ipairs(cu.attachments or {}) do a.hashes = nil end
    return res
end

Handlers.weapon = function(node)
    if node.kind ~= 'bench' then return end
    ESX.TriggerServerCallback('illegalbuilder:weapon:info', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Indisponible', 'error') end
        res.eid, res.pi = node.eid, node.pi
        OpenPanel('weapon', buildInfo(res), { type = 'weapon', eid = node.eid, pi = node.pi })
    end, node.eid, node.pi)
end

-- Fabrication
NuiLocal['weapon:craft'] = function(args, cb)
    local ctx = Ctx
    if not ctx or ctx.type ~= 'weapon' then return cb({ ok = false, error = 'Fermé' }) end
    ESX.TriggerServerCallback('illegalbuilder:weapon:begin', function(res)
        if not res or not res.ok then return cb(res or { ok = false, error = 'Erreur' }) end
        cb({ ok = true })
        CloseUI()
        CreateThread(function()
            local done = RunAction({ seconds = res.seconds, label = res.label, anim = res.anim })
            TriggerServerEvent('illegalbuilder:server:weaponFinish', done)
            if not done then Notify('Fabrication interrompue.', 'error') end
        end)
    end, ctx.eid, ctx.pi, args[1], args[2])
end

-- Personnalisation : chaque action renvoie l'état à jour du panneau
local function customCall(name)
    NuiLocal['weapon:' .. name] = function(args, cb)
        local ctx = Ctx
        if not ctx or ctx.type ~= 'weapon' then return cb({ ok = false, error = 'Fermé' }) end
        ESX.TriggerServerCallback('illegalbuilder:weapon:' .. name, function(res)
            if not res or not res.ok then return cb(res or { ok = false, error = 'Erreur' }) end
            res.eid, res.pi = ctx.eid, ctx.pi
            cb(buildInfo(res))
        end, ctx.eid, ctx.pi, args[1], args[2])
    end
end
customCall('attach') customCall('detach') customCall('tint')
