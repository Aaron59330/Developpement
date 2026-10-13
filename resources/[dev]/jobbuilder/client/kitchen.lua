-- ─────────────────────────────── Restaurant / bar : récolte, cuisine, vente (côté client) ───────────────────────────────
for _, n in ipairs({ 'serve:menu', 'serve:offer' }) do NuiRemote[n] = true end

local working = false

local function drawBar(label, pct)
    local w, x, y = 0.18, 0.5, 0.9
    DrawRect(x, y, w + 0.006, 0.026, 0, 0, 0, 170)
    local a = Config.UI and Config.UI.Accent or { 64, 224, 208 }
    DrawRect(x - w / 2 + (w * pct) / 2, y, math.max(w * pct, 0.0001), 0.018, a[1] or 64, a[2] or 224, a[3] or 208, 235)
    SetTextFont(4) SetTextScale(0.0, 0.38) SetTextColour(255, 255, 255, 235) SetTextCentre(true) SetTextOutline()
    BeginTextCommandDisplayText('STRING') AddTextComponentSubstringPlayerName(label) EndTextCommandDisplayText(x, y - 0.055)
    SetTextFont(4) SetTextScale(0.0, 0.3) SetTextColour(200, 200, 200, 220) SetTextCentre(true) SetTextOutline()
    BeginTextCommandDisplayText('STRING') AddTextComponentSubstringPlayerName('~INPUT_VEH_DUCK~ Annuler') EndTextCommandDisplayText(x, y + 0.02)
end

local function runWork(res, pointId)
    working = true
    CreateThread(function()
        local ped = PlayerPedId()
        local start = GetEntityCoords(ped)
        local scenario = res.kind == 'harvest' and Config.Kitchen.HarvestScenario or Config.Kitchen.CookScenario
        TaskStartScenarioInPlace(ped, scenario, 0, true)
        local t0, total, cancelled = GetGameTimer(), res.seconds * 1000, false
        while GetGameTimer() - t0 < total do
            Wait(0)
            drawBar(res.label, (GetGameTimer() - t0) / total)
            ped = PlayerPedId()
            if IsEntityDead(ped) or #(GetEntityCoords(ped) - start) > 2.0 or IsControlJustPressed(0, 73) then cancelled = true break end
        end
        ClearPedTasks(ped)
        if cancelled then
            TriggerServerEvent('jobbuilder:kitchen:cancel')
            working = false
            return ESX.ShowNotification('~r~Travail annulé.')
        end
        ESX.TriggerServerCallback('jobbuilder:kitchen:finish', function(r)
            working = false
            if r and r.ok then ESX.ShowNotification(r.msg) else ESX.ShowNotification('~r~' .. ((r and r.error) or 'Erreur')) end
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
