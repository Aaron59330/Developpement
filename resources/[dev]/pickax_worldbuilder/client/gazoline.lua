-- ─────────────────────────────── Job Gazoline (client) ───────────────────────────────
local G = Config.Gazoline
local depot
local mission, truck, trailer, destBlip, depotBlip

local function isGazoline()
    local d = ESX.GetPlayerData()
    return d and d.job and d.job.name == G.Job
end

RegisterNetEvent('worldbuilder:gaz:cfg', function(c)
    depot = c and c.depot or nil
    if depotBlip and DoesBlipExist(depotBlip) then RemoveBlip(depotBlip) depotBlip = nil end
end)
CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end
    Wait(3000)
    TriggerServerEvent('worldbuilder:server:gazRequest')
end)

local function clearBlip()
    if destBlip and DoesBlipExist(destBlip) then RemoveBlip(destBlip) end
    destBlip = nil
end
local function routeTo(c, label, color)
    clearBlip()
    destBlip = AddBlipForCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
    SetBlipSprite(destBlip, 361) SetBlipColour(destBlip, color or 5) SetBlipScale(destBlip, 0.5)
    SetBlipRoute(destBlip, true) SetBlipRouteColour(destBlip, color or 5)
    BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(label) EndTextCommandSetBlipName(destBlip)
end

local function delVeh(v) if v and DoesEntityExist(v) then SetEntityAsMissionEntity(v, true, true) DeleteVehicle(v) end end
local function cleanupTruck() delVeh(trailer) delVeh(truck) trailer, truck = nil, nil end

local function loadModel(name)
    local h = GetHashKey(name)
    if not IsModelInCdimage(h) then return nil end
    RequestModel(h)
    local t = GetGameTimer() + 6000
    while not HasModelLoaded(h) and GetGameTimer() < t do Wait(20) end
    return HasModelLoaded(h) and h or nil
end

local function spawnTruck(truckModel, trailerModel)
    local th, tr = loadModel(truckModel), loadModel(trailerModel)
    if not th or not tr then Notify('Modèle de camion introuvable (config Gazoline).', 'error') return false end
    local rad = math.rad(depot.h or 0.0)
    local sx, sy = depot.x - math.sin(rad) * 10.0, depot.y + math.cos(rad) * 10.0
    truck = CreateVehicle(th, sx, sy, depot.z + 1.0, depot.h or 0.0, true, false)
    SetEntityAsMissionEntity(truck, true, true)
    SetVehicleNumberPlateText(truck, 'GAZ' .. math.random(100, 999))
    local back = GetOffsetFromEntityInWorldCoords(truck, 0.0, -11.0, 0.0)
    trailer = CreateVehicle(tr, back.x, back.y, back.z, depot.h or 0.0, true, false)
    SetEntityAsMissionEntity(trailer, true, true)
    Wait(300)
    AttachVehicleToTrailer(truck, trailer, 1.2)
    if Config.SetFuel then Config.SetFuel(truck, 100.0) end
    SetVehicleEngineOn(truck, true, true, false)
    TaskWarpPedIntoVehicle(PlayerPedId(), truck, -1)
    SetModelAsNoLongerNeeded(th) SetModelAsNoLongerNeeded(tr)
    return true
end

local function endMission(msg, kind)
    mission = nil
    clearBlip()
    cleanupTruck()
    if msg then Notify(msg, kind or 'info') end
end

RegisterNetEvent('worldbuilder:gaz:delivered', function(d)
    if mission then mission.state = 'return' end
    Notify(('Livraison effectuée : %d L déposés à %s. +%d %s. Ramène le camion au dépôt pour ta prime.'):format(d.liters, d.label, d.pay, Config.Currency or '$'), 'success')
    if depot then routeTo(depot, 'Dépôt Gazoline', 3) end
end)
RegisterNetEvent('worldbuilder:gaz:finished', function(bonus, cancelled)
    if cancelled then return endMission('Livraison annulée.', 'error') end
    endMission(bonus and bonus > 0 and ('Camion rendu : prime de %d %s.'):format(bonus, Config.Currency or '$') or 'Camion rendu.', 'success')
end)

local function vehNear(c, r)
    for _, v in ipairs({ truck, trailer }) do
        if v and DoesEntityExist(v) and #(GetEntityCoords(v) - vector3(c.x, c.y, c.z)) <= r then return true end
    end
    return false
end

CreateThread(function()
    while true do
        local wait = 700
        if G.Enabled and depot and isGazoline() then
            local ped = PlayerPedId()
            local p = GetEntityCoords(ped)
            local dd = #(p - vector3(depot.x, depot.y, depot.z))
            if dd < G.DrawDistance then
                wait = 0
                BB.DrawMarker(nil, depot)
                if dd < 3.0 then
                    if not mission then
                        BB.ShowHelp('Appuie sur ~INPUT_CONTEXT~ pour charger une citerne de carburant')
                        if IsControlJustReleased(0, 38) then
                            ESX.TriggerServerCallback('worldbuilder:gaz:start', function(r)
                                if not r or not r.ok then return Notify((r and r.error) or 'Impossible', 'error') end
                                if not spawnTruck(r.truck, r.trailer) then return TriggerServerEvent('worldbuilder:server:gazCancel') end
                                mission = { state = 'deliver', coords = r.mission.coords, label = r.mission.label, liters = r.mission.liters, pay = r.mission.pay }
                                routeTo(r.mission.coords, 'Livraison : ' .. r.mission.label)
                                Notify(('Livraison : %d L pour la station « %s » (%d %% restants). Paie : %d %s.'):format(r.mission.liters, r.mission.label, r.mission.pct, r.mission.pay, Config.Currency or '$'), 'success')
                            end)
                            Wait(800)
                        end
                    elseif mission.state == 'return' then
                        BB.ShowHelp('Appuie sur ~INPUT_CONTEXT~ pour rendre le camion et toucher ta prime')
                        if IsControlJustReleased(0, 38) then
                            if vehNear(depot, 40.0) then TriggerServerEvent('worldbuilder:server:gazReturn')
                            else Notify('Ramène le camion près du dépôt.', 'error') end
                            Wait(800)
                        end
                    else
                        BB.ShowHelp('Livraison en cours · ~INPUT_DETONATE~ pour l\'annuler')
                        if IsControlJustReleased(0, 47) then TriggerServerEvent('worldbuilder:server:gazCancel') Wait(800) end
                    end
                end
            end
            -- point de livraison
            if mission and mission.state == 'deliver' then
                local c = mission.coords
                local dc = #(p - vector3(c.x, c.y, c.z))
                if dc < 40.0 then
                    wait = 0
                    BB.DrawMarker(nil, c)
                    if dc < 3.0 and not IsPedInAnyVehicle(ped, false) then
                        if vehNear(c, 30.0) then
                            BB.ShowHelp(('Appuie sur ~INPUT_CONTEXT~ pour décharger %d L'):format(mission.liters))
                            if IsControlJustReleased(0, 38) then
                                ESX.TriggerServerCallback('worldbuilder:gaz:unloadBegin', function(r)
                                    if not r or not r.ok then return Notify((r and r.error) or 'Impossible', 'error') end
                                    CreateThread(function()
                                        local ok = RunAction({ seconds = r.seconds, label = ('Déchargement : %d L'):format(r.liters), anim = 'fuel', radius = 8.0 })
                                        TriggerServerEvent('worldbuilder:server:gazUnloadFinish', ok)
                                        if not ok then Notify('Déchargement interrompu.', 'error') end
                                    end)
                                end)
                                Wait(800)
                            end
                        else
                            BB.ShowHelp('Amène la citerne près de la pompe pour la décharger')
                        end
                    end
                end
            end
        end
        -- camion détruit / supprimé : la mission est annulée
        if mission and truck and (not DoesEntityExist(truck) or IsEntityDead(truck)) then
            TriggerServerEvent('worldbuilder:server:gazCancel')
            mission = nil
        end
        Wait(wait)
    end
end)

-- Blip du dépôt (visible seulement par les livreurs)
CreateThread(function()
    while true do
        Wait(3000)
        local show = G.Enabled and depot and isGazoline()
        if show and not depotBlip then
            depotBlip = AddBlipForCoord(depot.x + 0.0, depot.y + 0.0, depot.z + 0.0)
            SetBlipSprite(depotBlip, G.Blip.sprite) SetBlipColour(depotBlip, G.Blip.color) SetBlipScale(depotBlip, 0.5) SetBlipAsShortRange(depotBlip, true)
            BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(G.Blip.label) EndTextCommandSetBlipName(depotBlip)
        elseif not show and depotBlip then
            if DoesBlipExist(depotBlip) then RemoveBlip(depotBlip) end
            depotBlip = nil
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    cleanupTruck() clearBlip()
    if depotBlip and DoesBlipExist(depotBlip) then RemoveBlip(depotBlip) end
end)
