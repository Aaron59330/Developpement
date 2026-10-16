-- ─────────────────────────────── Activités : récolte, traitement, blanchiment (animation + barre de progression) ───────────────────────────────
-- La durée est décidée et vérifiée par le serveur (gangbuilder:act:start / finish) : ici on ne fait que jouer l'animation.

local running = false

-- Joue le scénario + la barre de progression. done(true) = terminé, done(false) = annulé (déplacement, mort, véhicule, touche X)
local function runProgress(res, done)
    running = true
    local ped = PlayerPedId()
    local startPos = GetEntityCoords(ped)
    if res.scenario and res.scenario ~= '' then TaskStartScenarioInPlace(ped, res.scenario, 0, true) end
    SendNUIMessage({ action = 'progress', label = res.label, duration = res.seconds * 1000 })
    CreateThread(function()
        local untilT = GetGameTimer() + res.seconds * 1000
        local ok = true
        while GetGameTimer() < untilT do
            Wait(0)
            ped = PlayerPedId()
            DisableControlAction(0, 21, true) DisableControlAction(0, 22, true) DisableControlAction(0, 23, true)
            if IsControlJustReleased(0, 73) or IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) or #(GetEntityCoords(ped) - startPos) > 1.5 then
                ok = false
                break
            end
        end
        ClearPedTasks(PlayerPedId())
        SendNUIMessage({ action = 'progress', stop = true })
        running = false
        done(ok)
    end)
end

-- args = { kind, pointId, a, b } : récolte (rien), traitement (recette, quantité), blanchiment (montant)
NuiLocal['act:run'] = function(args, cb)
    if running then return cb({ ok = false, error = 'Tu es déjà occupé' }) end
    local kind, pointId = args[1], args[2]
    ESX.TriggerServerCallback('gangbuilder:act:start', function(res)
        if not res or not res.ok then return cb(res or { ok = false, error = 'Erreur' }) end
        CloseUI()
        cb({ ok = true })
        runProgress(res, function(finished)
            if finished then
                ESX.TriggerServerCallback('gangbuilder:act:finish', function(r)
                    GBNotify(r and r.ok and r.message or ('~r~' .. ((r and r.error) or 'Erreur')))
                    ReopenPoint(pointId)
                end)
            else
                ESX.TriggerServerCallback('gangbuilder:act:cancel', function() GBNotify('~r~Action annulée.') end)
            end
        end)
    end, kind, pointId, args[3], args[4])
end

-- Vente : le serveur indique si la police doit être alertée (Config.Activities.PoliceAlert / PoliceAlertChance)
NuiLocal['sell:do'] = function(args, cb)
    ESX.TriggerServerCallback('gangbuilder:sell:do', function(res)
        if res and res.ok and res.alert and Config.Activities.PoliceAlert then
            pcall(Config.Hooks.PoliceAlert, GetEntityCoords(PlayerPedId()), 'Vente suspecte')
        end
        cb(res or { ok = false, error = 'Aucune réponse' })
    end, table.unpack(args))
end

-- Les points d'activité se mettent à jour quand le joueur revient dessus : si une action est en cours, on empêche d'ouvrir un autre panneau
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and running then ClearPedTasks(PlayerPedId()) end
end)
