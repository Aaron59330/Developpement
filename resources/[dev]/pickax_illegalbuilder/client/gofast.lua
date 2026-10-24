-- ─────────────────────────────── Go Fast (client) ───────────────────────────────
local Run = nil   -- { drop = vector3, radius, blip, plate }

Handlers.gofast = function(node)
    if node.kind ~= 'gfstart' then return end
    ESX.TriggerServerCallback('illegalbuilder:gofast:info', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Indisponible', 'error') end
        OpenPanel('gofast', res, { type = 'gofast', eid = node.eid, pi = node.pi })
    end, node.eid, node.pi)
end

local function clearRun()
    if Run and Run.blip and DoesBlipExist(Run.blip) then RemoveBlip(Run.blip) end
    Run = nil
end

RegisterNetEvent('illegalbuilder:client:gofastEnd', function(reason, total, bonus)
    clearRun()
    if total and total > 0 then
        Notify(('Livraison terminée : %s%s%s'):format(Config.Currency, total, (bonus or 0) > 0 and (' (dont bonus état du véhicule ' .. Config.Currency .. bonus .. ')') or ''), 'success')
    elseif reason and reason ~= '' then
        Notify(reason, 'error')
    end
end)

NuiLocal['gofast:start'] = function(args, cb)
    local ctx = Ctx
    if not ctx or ctx.type ~= 'gofast' then return cb({ ok = false, error = 'Fermé' }) end
    ESX.TriggerServerCallback('illegalbuilder:gofast:start', function(res)
        if not res or not res.ok then return cb(res or { ok = false, error = 'Erreur' }) end
        cb({ ok = true })
        CloseUI()
        CreateThread(function()
            local t = GetGameTimer()
            while not NetworkDoesNetworkIdExist(res.netId) and GetGameTimer() - t < 5000 do Wait(50) end
            local veh = NetworkDoesNetworkIdExist(res.netId) and NetToVeh(res.netId) or 0
            t = GetGameTimer()
            while veh ~= 0 and not DoesEntityExist(veh) and GetGameTimer() - t < 3000 do Wait(50) veh = NetToVeh(res.netId) end
            local ped = PlayerPedId()
            if veh ~= 0 and DoesEntityExist(veh) then
                SetVehicleDoorsLocked(veh, 1)
                TaskWarpPedIntoVehicle(ped, veh, -1)
                if Config.GiveKeys then pcall(Config.GiveKeys, res.plate, veh) end
            end
            clearRun()
            local blip = AddBlipForCoord(res.drop.x, res.drop.y, res.drop.z)
            SetBlipSprite(blip, 272) SetBlipColour(blip, 1) SetBlipScale(blip, 0.7) SetBlipRoute(blip, true)
            BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('Livraison Go Fast') EndTextCommandSetBlipName(blip)
            Run = { drop = vector3(res.drop.x, res.drop.y, res.drop.z), radius = res.radius or 8.0, blip = blip, plate = res.plate }
            PlaySoundFrontend(-1, 'Event_Start_Text', 'GTAO_FM_Events_Soundset', true)
            Notify(('Go Fast lancé : livre le véhicule dans %d minutes.'):format(res.minutes or 30), 'info')
        end)
    end, ctx.eid, ctx.pi)
end

CreateThread(function()
    while true do
        local sleep = 1000
        if Run then
            local ped = PlayerPedId()
            local d = #(GetEntityCoords(ped) - Run.drop)
            if d < 80.0 then
                sleep = 0
                DrawMarker(1, Run.drop.x, Run.drop.y, Run.drop.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Run.radius * 2.0, Run.radius * 2.0, 1.2, 255, 80, 80, 120, false, false, 2, false, nil, nil, false)
                if d <= Run.radius and IsPedInAnyVehicle(ped, false) then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Appuie sur ~INPUT_PICKUP~ pour livrer le véhicule')
                    EndTextCommandDisplayHelp(0, false, false, -1)
                    if IsControlJustPressed(0, 38) then
                        TriggerServerEvent('illegalbuilder:server:gofastDeliver')
                        Wait(1500)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
