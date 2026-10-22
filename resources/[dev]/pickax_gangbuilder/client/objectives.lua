-- ─────────────────────────────── Missions « colis » (client) ───────────────────────────────
-- Affiche la zone, le colis au sol, le HUD de mission, et gère le ramassage (touche E). Toute la logique est côté serveur.

local OBJ = nil                -- dernier état reçu du serveur
local zoneBlips = {}           -- { radius, icon }
local itemBlip = nil
local prop = nil
local waypointSet = false
local picking = false

local function clearBlips()
    for _, h in ipairs(zoneBlips) do if DoesBlipExist(h) then RemoveBlip(h) end end
    zoneBlips = {}
    if itemBlip and DoesBlipExist(itemBlip) then RemoveBlip(itemBlip) end
    itemBlip = nil
end

local function deleteProp()
    if prop and DoesEntityExist(prop) then DeleteEntity(prop) end
    prop = nil
end

local function buildZoneBlips(d)
    clearBlips()
    local z = d.zone
    local radius = AddBlipForRadius(z.x + 0.0, z.y + 0.0, z.z + 0.0, (d.radius or 40.0) + 0.0)
    SetBlipColour(radius, 5)
    SetBlipAlpha(radius, 110)
    local icon = AddBlipForCoord(z.x + 0.0, z.y + 0.0, z.z + 0.0)
    SetBlipSprite(icon, 478)
    SetBlipColour(icon, 5)
    SetBlipScale(icon, 0.5)
    SetBlipAsShortRange(icon, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(('Colis — %s'):format(d.label or 'Mission'))
    EndTextCommandSetBlipName(icon)
    zoneBlips = { radius, icon }
end

local function setItemBlip(c)
    if not c then
        if itemBlip and DoesBlipExist(itemBlip) then RemoveBlip(itemBlip) end
        itemBlip = nil
        return
    end
    if not itemBlip or not DoesBlipExist(itemBlip) then
        itemBlip = AddBlipForCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
        SetBlipSprite(itemBlip, 306)
        SetBlipColour(itemBlip, 1)
        SetBlipScale(itemBlip, 0.5)
        SetBlipFlashes(itemBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Colis')
        EndTextCommandSetBlipName(itemBlip)
    else
        SetBlipCoords(itemBlip, c.x + 0.0, c.y + 0.0, c.z + 0.0)
    end
end

local function updateHud()
    if not OBJ or not OBJ.active then SendNUIMessage({ action = 'objective', data = nil }) return end
    local d = OBJ
    local pos = GetEntityCoords(PlayerPedId())
    local near = #(pos - vector3(d.zone.x, d.zone.y, d.zone.z)) < (d.radius or 40.0) + 120.0
    if not (d.me or near) then SendNUIMessage({ action = 'objective', data = nil }) return end
    SendNUIMessage({ action = 'objective', data = {
        label = d.label, phase = d.phase, carried = d.carried, carrierGang = d.carrierGang, me = d.me,
        holdLeft = d.holdLeft, holdTotal = d.holdTotal, outside = d.outside, leaveGrace = d.leaveGrace,
        left = math.max(0, (d.endsAt or 0) - (d.now or 0)),
    } })
end

RegisterNetEvent('gangbuilder:client:obj', function(d)
    if type(d) ~= 'table' or not d.active then
        OBJ = nil
        clearBlips()
        deleteProp()
        waypointSet = false
        SendNUIMessage({ action = 'objective', data = nil })
        return
    end
    local first = not OBJ
    OBJ = d
    OBJ.recv = GetGameTimer()
    if first then
        PlaySoundFrontend(-1, 'Event_Start_Text', 'GTAO_FM_Events_Soundset', true)
        buildZoneBlips(d)
    end
    if d.carried then
        setItemBlip(d.reveal)         -- les autres gangs voient le porteur pendant la livraison
    else
        setItemBlip(d.pos)
    end
    if d.me and d.phase == 'deliver' and d.deliver and not waypointSet then
        waypointSet = true
        SetNewWaypoint(d.deliver.x + 0.0, d.deliver.y + 0.0)
    end
    if not d.me then waypointSet = false end
    updateHud()
end)

CreateThread(function()
    Wait(4000)
    TriggerServerEvent('gangbuilder:server:objSync')
end)

-- Colis au sol : marker, objet, invite de ramassage
CreateThread(function()
    while true do
        local sleep = 1000
        local d = OBJ
        if d and d.active and not d.carried and d.pos then
            local pos = GetEntityCoords(PlayerPedId())
            local c = vector3(d.pos.x, d.pos.y, d.pos.z)
            local dist = #(pos - c)
            if dist < 120.0 then
                sleep = 0
                DrawMarker(1, c.x, c.y, c.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.4, 1.4, 0.6, 255, 200, 0, 120, false, false, 2, false, nil, nil, false)
                DrawMarker(2, c.x, c.y, c.z + 1.3, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.5, 0.5, 0.5, 255, 200, 0, 200, true, false, 2, false, nil, nil, false)
                if not prop then
                    local model = joaat(d.model or 'prop_box_wood02a_pu')
                    if IsModelInCdimage(model) then
                        RequestModel(model)
                        local t = GetGameTimer() + 1500
                        while not HasModelLoaded(model) and GetGameTimer() < t do Wait(0) end
                        if HasModelLoaded(model) then
                            prop = CreateObject(model, c.x, c.y, c.z, false, false, false)
                            PlaceObjectOnGroundProperly(prop)
                            FreezeEntityPosition(prop, true)
                            SetModelAsNoLongerNeeded(model)
                        end
                    end
                end
                if dist <= (d.pickup or 3.0) and not picking and not IsPedInAnyVehicle(PlayerPedId(), false) and not IsUIOpen() then
                    ESX.ShowHelpNotification('Appuyez sur ~INPUT_CONTEXT~ pour prendre le colis')
                    if IsControlJustReleased(0, 38) then
                        picking = true
                        ESX.TriggerServerCallback('gangbuilder:obj:pickup', function(res)
                            picking = false
                            if res and res.ok then
                                PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                            else
                                GBNotify('~r~' .. ((res and res.error) or 'Impossible de prendre le colis'))
                            end
                        end)
                    end
                end
            else
                deleteProp()
            end
        else
            deleteProp()
        end
        Wait(sleep)
    end
end)

-- Porteur : zone à tenir (anneau) puis marker du coffre où livrer
CreateThread(function()
    while true do
        local sleep = 500
        local d = OBJ
        if d and d.active and d.me then
            sleep = 0
            if d.phase == 'hold' then
                local z = d.zone
                DrawMarker(1, z.x + 0.0, z.y + 0.0, z.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, (d.radius or 40.0) * 2.0, (d.radius or 40.0) * 2.0, 30.0, 255, 200, 0, 25, false, false, 2, false, nil, nil, false)
            elseif d.deliver then
                local c = d.deliver
                DrawMarker(1, c.x + 0.0, c.y + 0.0, c.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.0, 4.0, 1.5, 80, 220, 120, 140, false, false, 2, false, nil, nil, false)
            end
        end
        Wait(sleep)
    end
end)

-- HUD : rafraîchi aussi quand le joueur s'approche / s'éloigne de la zone
CreateThread(function()
    while true do
        Wait(2000)
        if OBJ and OBJ.active then updateHud() end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    clearBlips()
    deleteProp()
end)
