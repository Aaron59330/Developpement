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

-- ───────── Tablettes d'accès (Go Fast, blanchiment…) : sans l'item, le point n'existe pas pour le joueur ─────────
-- Le serveur n'envoie les points « à tablette » qu'aux joueurs qui possèdent l'item. Ici : on surveille l'inventaire pour redemander
-- la synchronisation quand la tablette est achetée / perdue, on affiche les points révélés sur la carte et on pose le GPS à l'achat.
local revBlips, revCount = {}, {}

local function clearRevBlips()
    for _, b in ipairs(revBlips) do if DoesBlipExist(b) then RemoveBlip(b) end end
    revBlips = {}
end

local function rebuildRevBlips()
    clearRevBlips()
    for _, e in ipairs((State and State.entities) or {}) do
        for _, p in ipairs(e.points) do
            local label, sprite, colour
            if e.type == 'gofast' and e.gofastItem and p.kind == 'gfstart' then label, sprite, colour = 'Contact Go Fast', 225, 1
            elseif p.reveal and p.coords and not (e.blip and e.blip.enabled) then label, sprite, colour = (p.label and p.label ~= '') and p.label or 'Blanchiment', 108, 2 end   -- blip du module activé : il dessine déjà ce point
            if label and p.coords then
                local b = AddBlipForCoord(p.coords.x + 0.0, p.coords.y + 0.0, p.coords.z + 0.0)
                SetBlipSprite(b, sprite) SetBlipColour(b, colour) SetBlipScale(b, 0.8) SetBlipAsShortRange(b, true)
                BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(label) EndTextCommandSetBlipName(b)
                revBlips[#revBlips + 1] = b
            end
        end
    end
end

RegisterNetEvent('illegalbuilder:client:sync', function() SetTimeout(300, rebuildRevBlips) end)

-- Premier point révélé par `item` : position + texte du message
local function revealedBy(item)
    for _, e in ipairs((State and State.entities) or {}) do
        for _, p in ipairs(e.points) do
            if p.coords and ((e.type == 'gofast' and e.gofastItem == item and p.kind == 'gfstart') or p.reveal == item) then
                return p, (e.type == 'gofast') and 'le contact Go Fast' or 'le point de blanchiment'
            end
        end
    end
end

CreateThread(function()
    while true do
        Wait(3000)
        local changed, gainedItem = false, nil
        local items, seen = {}, {}
        for _, e in ipairs((State and State.entities) or {}) do
            for _, it in ipairs(e.revealItems or {}) do if not seen[it] then seen[it] = true items[#items + 1] = it end end
        end
        for _, item in ipairs(items) do
            local ok, n = pcall(function() return exports.ox_inventory:Search('count', item) end)
            n = ok and tonumber(n) or 0
            if revCount[item] == nil then revCount[item] = n end
            if (revCount[item] > 0) ~= (n > 0) then
                changed = true
                if n > 0 then gainedItem = item end
            end
            revCount[item] = n
        end
        if changed then
            TriggerServerEvent('illegalbuilder:server:requestSync')
            if gainedItem then
                SetTimeout(2500, function()
                    local p, what = revealedBy(gainedItem)
                    if p then
                        SetNewWaypoint(p.coords.x + 0.0, p.coords.y + 0.0)
                        Notify(('Tablette reçue : %s est indiqué sur ta carte (GPS posé).'):format(what), 'success')
                    end
                end)
            else
                Notify('Tu n\'as plus la tablette : l\'accès n\'est plus disponible.', 'error')
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then clearRevBlips() end end)
