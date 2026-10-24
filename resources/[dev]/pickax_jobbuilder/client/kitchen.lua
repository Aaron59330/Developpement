-- ─────────────────────────────── Restaurant / bar : récolte, cuisine, vente (côté client) ───────────────────────────────
for _, n in ipairs({ 'serve:menu', 'serve:offer', 'serve:offerSelf' }) do NuiRemote[n] = true end

local working = false

local function runWork(res, pointId)
    working = true
    CreateThread(function()
        local ped = PlayerPedId()
        local start = GetEntityCoords(ped)
        local scenario = res.kind == 'harvest' and Config.Kitchen.HarvestScenario or Config.Kitchen.CookScenario
        TaskStartScenarioInPlace(ped, scenario, 0, true)
        local t0, total, cancelled = GetGameTimer(), res.seconds * 1000, false
        JBProgress(res.label, total)
        while GetGameTimer() - t0 < total do
            Wait(0)
            ped = PlayerPedId()
            if IsEntityDead(ped) or #(GetEntityCoords(ped) - start) > 2.0 or IsControlJustPressed(0, 73) then cancelled = true break end
        end
        JBProgressEnd()
        ClearPedTasks(ped)
        if cancelled then
            TriggerServerEvent('jobbuilder:kitchen:cancel')
            working = false
            return JBNotify('~r~Travail annulé.')
        end
        ESX.TriggerServerCallback('jobbuilder:kitchen:finish', function(r)
            working = false
            if r and r.ok then JBNotify(r.msg) else JBNotify('~r~' .. ((r and r.error) or 'Erreur')) end
            ReopenPoint(pointId)
        end)
    end)
end

-- args : pointId, idx (recette, 0 pour une récolte), quantité
NuiLocal['kitchen:work'] = function(args, cb)
    if working then return cb({ ok = false, error = 'Tu es déjà occupé' }) end
    ESX.TriggerServerCallback('jobbuilder:kitchen:begin', function(res)
        if not res or not res.ok then return cb(res or { ok = false, error = 'Erreur' }) end
        cb({ ok = true })
        CloseUI()
        runWork(res, args[1])
    end, args[1], args[2], args[3])
end
