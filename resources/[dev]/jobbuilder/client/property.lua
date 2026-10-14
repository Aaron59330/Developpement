-- ─────────────────────────────── Immobilier (client) ───────────────────────────────
local R = Config.Real

local Props = {}        -- biens (entrées publiques) envoyés par le serveur
local propBlips = {}
local Inside = nil      -- { id, label, role, exit, entrance, points }

-- Handlers NUI -> client / serveur ajoutés par ce fichier
for _, n in ipairs({
    'prop:manage', 'prop:save', 'prop:delete', 'prop:reset', 'prop:offer', 'prop:giveKey', 'prop:removeKey',
    'prop:payRent', 'prop:terminate', 'prop:ring', 'prop:wardrobe:delete', 'prop:wardrobe:wear',
}) do NuiRemote[n] = true end

-- ─────────────────────────────── Sync / blips ───────────────────────────────
local function rebuildBlips()
    for _, b in ipairs(propBlips) do if DoesBlipExist(b) then RemoveBlip(b) end end
    propBlips = {}
    if not R.ShowBlips then return end
    for _, p in ipairs(Props) do
        if p.status == 'available' then
            local cfg = R.Blips[p.deal] or R.Blips.sale
            local blip = AddBlipForCoord(p.entrance.x, p.entrance.y, p.entrance.z)
            SetBlipSprite(blip, (R.Categories[p.category or 'house'] or {}).sprite or cfg.sprite)
            SetBlipColour(blip, cfg.color)
            SetBlipScale(blip, cfg.scale + 0.0)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(((R.Categories[p.category or 'house'] or {}).label or 'Bien') .. (p.deal == 'rent' and ' à louer : ' or ' à vendre : ') .. p.label)
            EndTextCommandSetBlipName(blip)
            propBlips[#propBlips + 1] = blip
        end
    end
end

RegisterNetEvent('jobbuilder:client:props', function(list)
    Props = list or {}
    rebuildBlips()
end)

CreateThread(function()
    Wait(2500)
    TriggerServerEvent('jobbuilder:server:requestProps')
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, b in ipairs(propBlips) do if DoesBlipExist(b) then RemoveBlip(b) end end
end)

-- ─────────────────────────────── Téléportation ───────────────────────────────
local function teleportTo(c)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    RequestCollisionAtCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
    SetEntityCoords(ped, c.x + 0.0, c.y + 0.0, c.z + 0.0, false, false, false, false)
    SetEntityHeading(ped, (c.h or 0.0) + 0.0)
    local t = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() - t < 3000 do Wait(50) end
    FreezeEntityPosition(ped, false)
    Wait(250)
    DoScreenFadeIn(500)
end

local function enterProperty(id, cb)
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        JBNotify('~r~Descends de ton véhicule.')
        return cb and cb({ ok = false, error = 'Descends de ton véhicule.' })
    end
    ESX.TriggerServerCallback('jobbuilder:prop:enter', function(res)
        if res and res.ok then
            for _, name in ipairs(res.ipl or {}) do RequestIpl(name) end
            Inside = res
            CloseUI()
            CreateThread(function() teleportTo(res.exit) end)
        end
        if cb then cb(res or { ok = false, error = 'Erreur' }) end
    end, id)
end

local function leaveProperty()
    ESX.TriggerServerCallback('jobbuilder:prop:leave', function(res)
        if res and res.ok then
            Inside = nil
            CreateThread(function() teleportTo(res.entrance) end)
        else
            JBNotify('~r~' .. ((res and res.error) or 'Erreur'))
        end
    end)
end

RegisterNetEvent('jobbuilder:client:propKick', function(entrance)
    Inside = nil
    CloseUI()
    CreateThread(function() teleportTo(entrance) end)
    JBNotify('Tu as été invité à quitter la propriété.')
end)

-- ─────────────────────────────── Handlers NUI ───────────────────────────────
NuiLocal['prop:enter'] = function(args, cb) enterProperty(args[1], cb) end

NuiLocal.waypoint = function(args, cb)
    local c = args[1]
    if c and c.x then SetNewWaypoint(c.x + 0.0, c.y + 0.0) end
    cb({ ok = true })
end

NuiLocal.ringAnswer = function(args, cb)
    TriggerServerEvent('jobbuilder:server:ringAnswer', args[1], args[2], args[3] == true)
    CloseUI()
    cb({ ok = true })
end

NuiLocal.offerAnswer = function(args, cb)
    TriggerServerEvent('jobbuilder:server:offerAnswer', args[1], args[2] == true)
    CloseUI()
    cb({ ok = true })
end

NuiLocal.wardrobeSave = function(args, cb)
    -- args: propId, pointId, label
    Config.GetClothes(function(skin)
        local out = {}
        for _, k in ipairs(Config.ClothesKeys) do
            if skin and skin[k] ~= nil then out[k] = skin[k] end
        end
        ESX.TriggerServerCallback('jobbuilder:prop:wardrobe:save', function(res)
            cb(res or { ok = false, error = 'Erreur' })
        end, args[1], args[2], args[3], out)
    end)
end

-- ─────────────────────────────── Événements serveur ───────────────────────────────
RegisterNetEvent('jobbuilder:client:ringPrompt', function(ringer, propId, name)
    OpenUI({ action = 'open', kind = 'ring', data = { ringer = ringer, propId = propId, name = name } })
end)

RegisterNetEvent('jobbuilder:client:ringAccepted', function(propId)
    JBNotify('~g~On t\'ouvre la porte.')
    enterProperty(propId)
end)

RegisterNetEvent('jobbuilder:client:propOffer', function(id, data)
    data.id = id
    OpenUI({ action = 'open', kind = 'propOffer', data = data })
end)

function OpenAgencyPanel()
    ESX.TriggerServerCallback('jobbuilder:prop:manage', function(res)
        if not res or not res.ok then
            return JBNotify('~r~' .. ((res and res.error) or 'Erreur'))
        end
        OpenUI({ action = 'open', kind = 'agency', data = res })
    end)
end

-- ─────────────────────────────── Interactions : portes, sortie, points ───────────────────────────────
local function openDoor(p)
    ESX.TriggerServerCallback('jobbuilder:prop:door', function(res)
        if not res or not res.ok then return JBNotify('~r~' .. ((res and res.error) or 'Erreur')) end
        OpenUI({ action = 'open', kind = 'door', data = res })
    end, p.id)
end

local function openInteriorPoint(pt)
    ESX.TriggerServerCallback('jobbuilder:prop:openPoint', function(res)
        if not res or not res.ok then return JBNotify('~r~' .. ((res and res.error) or 'Erreur')) end
        if res.kind == 'stash' then
            exports.ox_inventory:openInventory('stash', res.stash)
        else
            res.propId, res.pointId = Inside.id, pt.id
            OpenUI({ action = 'open', kind = 'wardrobe', data = res })
        end
    end, Inside.id, pt.id)
end

AddEventHandler('jobbuilder:internal:configChanged', function() rebuildBlips() end)

CreateThread(function()
    while true do
        local sleep = 1000
        if not IsUIOpen() then
            local pos = GetEntityCoords(PlayerPedId())
            local nearest, nearestLabel, nearestFn, nearestHelp

            if Inside then
                sleep = 0
                local e = Inside.exit
                DrawJBMarker(R.Markers.exit, e)
                if #(pos - vector3(e.x, e.y, e.z)) < Config.InteractDistance then
                    nearest, nearestLabel, nearestFn = true, 'Sortir de la propriété', leaveProperty
                end
                for _, pt in ipairs(Inside.points or {}) do
                    local t = R.PointTypes[pt.type]
                    if t then
                        local c = pt.coords
                        local d = #(pos - vector3(c.x, c.y, c.z))
                        if d < Config.DrawDistance then
                            DrawJBMarker(t, c)
                            if d < Config.InteractDistance then
                                nearest, nearestLabel, nearestFn = true, ('%s (%s)'):format(pt.label, t.label), function() openInteriorPoint(pt) end
                            end
                        end
                    end
                end
            else
                for _, p in ipairs(Props) do
                    local c = p.entrance
                    local d = #(pos - vector3(c.x, c.y, c.z))
                    if d < Config.DrawDistance then
                        sleep = 0
                        DrawJBMarker(p.status == 'available' and R.Markers.available or (p.access and R.Markers.access or R.Markers.noaccess), c)
                        if d < Config.InteractDistance then
                            local txt = p.status == 'available' and ((p.deal == 'rent' and 'À louer : ' or 'À vendre : ') .. p.label) or p.label
                            nearest, nearestLabel, nearestFn = true, txt, function() openDoor(p) end
                            nearestHelp = BB.HelpEnabled(p.status == 'available' and R.Markers.available or (p.access and R.Markers.access or R.Markers.noaccess))
                        end
                    end
                end
            end

            if nearest then
                if nearestHelp ~= false then ESX.ShowHelpNotification(('Appuie sur ~INPUT_CONTEXT~ : %s'):format(nearestLabel)) end
                if IsControlJustReleased(0, 38) then nearestFn() end
            end
        end
        Wait(sleep)
    end
end)

-- Mort / respawn à l'hôpital : on quitte l'instance proprement
AddEventHandler('esx:onPlayerSpawn', function()
    if Inside then
        Inside = nil
        TriggerServerEvent('jobbuilder:server:forceLeave')
    end
end)
