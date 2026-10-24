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

-- ───────── Tablette Go Fast : sans l'item, le contact n'existe pas pour le joueur ─────────
-- Le serveur n'envoie les points d'un Go Fast « à tablette » qu'aux joueurs qui possèdent l'item. Ici : on surveille l'inventaire pour
-- redemander la synchronisation quand la tablette est achetée / perdue, on affiche le contact sur la carte et on pose le GPS à l'achat.
local gfBlips, gfCount, gfLastKey = {}, {}, ''

local function clearGfBlips()
    for _, b in ipairs(gfBlips) do if DoesBlipExist(b) then RemoveBlip(b) end end
    gfBlips = {}
end

local function rebuildGfBlips()
    clearGfBlips()
    for _, e in ipairs((State and State.entities) or {}) do
        if e.type == 'gofast' and e.gofastItem then
            for _, p in ipairs(e.points) do
                if p.kind == 'gfstart' and p.coords then
                    local b = AddBlipForCoord(p.coords.x + 0.0, p.coords.y + 0.0, p.coords.z + 0.0)
                    SetBlipSprite(b, 225) SetBlipColour(b, 1) SetBlipScale(b, 0.8) SetBlipAsShortRange(b, true)
                    BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('Contact Go Fast') EndTextCommandSetBlipName(b)
                    gfBlips[#gfBlips + 1] = b
                end
            end
        end
    end
end

RegisterNetEvent('illegalbuilder:client:sync', function() SetTimeout(300, rebuildGfBlips) end)

CreateThread(function()
    while true do
        Wait(3000)
        local changed, gained = false, nil
        for _, e in ipairs((State and State.entities) or {}) do
            local item = e.gofastItem
            if item then
                local ok, n = pcall(function() return exports.ox_inventory:Search('count', item) end)
                n = ok and tonumber(n) or 0
                if gfCount[item] == nil then gfCount[item] = n end
                if (gfCount[item] > 0) ~= (n > 0) then
                    changed = true
                    if n > 0 then gained = e end
                end
                gfCount[item] = n
            end
        end
        if changed then
            TriggerServerEvent('illegalbuilder:server:requestSync')
            if gained then
                SetTimeout(2500, function()
                    for _, e in ipairs((State and State.entities) or {}) do
                        if e.id == gained.id then
                            for _, p in ipairs(e.points) do
                                if p.kind == 'gfstart' and p.coords then
                                    SetNewWaypoint(p.coords.x + 0.0, p.coords.y + 0.0)
                                    Notify('Tablette Go Fast : le contact est indiqué sur ta carte (GPS posé).', 'success')
                                    return
                                end
                            end
                        end
                    end
                end)
            else
                Notify('Tu n\'as plus la tablette Go Fast : le contact n\'est plus accessible.', 'error')
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then clearGfBlips() end end)
