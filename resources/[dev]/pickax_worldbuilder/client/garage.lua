-- ─────────────────────────────── Garages & fourrières (client) ───────────────────────────────
function VehicleLabel(model)
    if not model then return '?' end
    local hash = type(model) == 'string' and joaat(model) or model
    local name = GetDisplayNameFromVehicleModel(hash)
    local label = GetLabelText(name)
    return (label and label ~= 'NULL') and label or name
end

-- Première place de sortie libre (aucun véhicule à moins de 2,5 m)
function FreeSpawn(point)
    for i, s in ipairs(point.spawns or {}) do
        if not IsAnyVehicleNearPoint(s.x + 0.0, s.y + 0.0, s.z + 0.0, 2.5) then return i end
    end
    return nil
end

-- Fait apparaître un véhicule sur une place de sortie. Retourne l'entité (ou nil).
function SpawnVehicleAt(spawn, model, props, plate)
    local hash = LoadModel(model)
    if not hash then return nil end
    local veh = CreateVehicle(hash, spawn.x + 0.0, spawn.y + 0.0, spawn.z + 0.0, (spawn.h or 0.0) + 0.0, true, false)
    SetModelAsNoLongerNeeded(hash)
    if not veh or veh == 0 then return nil end
    SetVehicleOnGroundProperly(veh)
    if props then pcall(function() ESX.Game.SetVehicleProperties(veh, props) end) end
    if plate then SetVehicleNumberPlateText(veh, plate) end
    SetVehicleEngineOn(veh, false, true, true)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetEntityAsMissionEntity(veh, true, true)
    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    if props and props.fuelLevel and Config.SetFuel then pcall(Config.SetFuel, veh, props.fuelLevel) end
    if Config.GiveKeys then pcall(Config.GiveKeys, plate or GetVehicleNumberPlateText(veh), veh) end
    return veh
end

-- Véhicule à ranger / saisir : celui où se trouve le joueur, sinon le plus proche du point
local function findVehicle(c, radius)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then return veh end
    veh = GetClosestVehicle(c.x + 0.0, c.y + 0.0, c.z + 0.0, radius or 10.0, 0, 71)
    return veh ~= 0 and veh or nil
end

-- Note sur 100 (0 si le modèle est inconnu)
local function score(v, max) return math.max(0, math.min(100, math.floor((tonumber(v) or 0) / max * 100 + 0.5))) end

local function enrich(list)
    for _, v in ipairs(list or {}) do
        v.name = VehicleLabel(v.model)
        local hash = type(v.model) == 'string' and joaat(v.model) or v.model
        if hash and IsModelInCdimage(hash) then
            local make = GetMakeNameFromVehicleModel(hash)
            local label = make and GetLabelText(make)
            v.make = (label and label ~= 'NULL') and label or (make or '')
            v.img = (GetDisplayNameFromVehicleModel(hash) or ''):lower()
            -- performances du modèle (natives de handling), ramenées sur 100
            v.perf = {
                speed = score(GetVehicleModelEstimatedMaxSpeed(hash), 60),
                accel = score(GetVehicleModelAcceleration(hash), 0.45),
                brake = score(GetVehicleModelMaxBraking(hash), 1.4),
                grip  = score((GetVehicleModelMaxTraction(hash) or 0) - 1.0, 2.0),
            }
        end
    end
end

local function reportSpawned(veh, plate)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    SetNetworkIdExistsOnAllMachines(netId, true)
    TriggerServerEvent('worldbuilder:server:vehicleSpawned', plate, netId)
end

-- ═══════════════ GARAGE ═══════════════
local function storeVehicle(node, point, cb)
    local c = point.store or point.coords
    local veh = findVehicle(c, 12.0)
    if not veh then Notify('Aucun véhicule à ranger.', 'error') return cb and cb({ ok = false, error = 'Aucun véhicule à ranger' }) end
    if not NetworkGetEntityIsNetworked(veh) then Notify('Ce véhicule ne peut pas être rangé.', 'error') return cb and cb({ ok = false }) end
    local props = ESX.Game.GetVehicleProperties(veh)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    ESX.TriggerServerCallback('worldbuilder:garage:store', function(res)
        if res and res.ok then Notify('Véhicule rangé.', 'success') else Notify((res and res.error) or 'Impossible de ranger', 'error') end
        if cb then cb(res or { ok = false }) end
    end, node.eid, node.pi, netId, props)
end

Handlers.garage = function(node)
    local point, e = PointOf(node.eid, node.pi)
    if not point then return end
    if node.kind == 'store' then return storeVehicle(node, point) end
    ESX.TriggerServerCallback('worldbuilder:garage:list', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Garage indisponible', 'error') end
        enrich(res.vehicles) enrich(res.fleet)
        res.eid, res.pi = node.eid, node.pi
        res.inVehicle = GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 or findVehicle(point.store or point.coords, 12.0) ~= nil
        OpenPanel('garage', res, { type = 'garage', eid = node.eid, pi = node.pi })
    end, node.eid, node.pi)
end

NuiLocal['garage:take'] = function(args, cb)
    local ctx = Ctx
    if not ctx or ctx.type ~= 'garage' then return cb({ ok = false, error = 'Garage fermé' }) end
    local point = PointOf(ctx.eid, ctx.pi)
    if not point then return cb({ ok = false, error = 'Introuvable' }) end
    local idx = FreeSpawn(point)
    if not idx then return cb({ ok = false, error = 'Aucune place de sortie libre' }) end
    ESX.TriggerServerCallback('worldbuilder:garage:take', function(res)
        if not res or not res.ok then return cb(res or { ok = false, error = 'Erreur' }) end
        cb({ ok = true })
        CloseUI()
        local spawn = point.spawns[res.spawn]
        if res.fleet then
            local plate = ('SRV%s'):format(math.random(10000, 99999))
            local veh = SpawnVehicleAt(spawn, res.model, nil, plate)
            if not veh then Notify('Impossible de sortir ce véhicule.', 'error') end
        else
            local veh = SpawnVehicleAt(spawn, res.props.model or res.props.vehicle, res.props, res.plate)
            if not veh then
                TriggerServerEvent('worldbuilder:server:vehicleFailed', res.plate)
                return Notify('Impossible de sortir ce véhicule (modèle introuvable).', 'error')
            end
            reportSpawned(veh, res.plate)
        end
        Notify('Véhicule sorti.', 'success')
    end, ctx.eid, ctx.pi, args[1], idx, args[2])
end

NuiLocal['garage:store'] = function(_, cb)
    local ctx = Ctx
    local point = ctx and PointOf(ctx.eid, ctx.pi)
    if not point then return cb({ ok = false, error = 'Garage fermé' }) end
    local node = { eid = ctx.eid, pi = ctx.pi }
    storeVehicle(node, point, function(res) cb(res) if res and res.ok then CloseUI() end end)
end

-- ═══════════════ FOURRIÈRE ═══════════════
Handlers.impound = function(node)
    local point = PointOf(node.eid, node.pi)
    if not point then return end
    ESX.TriggerServerCallback('worldbuilder:impound:list', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Fourrière indisponible', 'error') end
        enrich(res.vehicles)
        res.eid, res.pi = node.eid, node.pi
        res.hasVehicle = findVehicle(point.coords, 12.0) ~= nil
        OpenPanel('impound', res, { type = 'impound', eid = node.eid, pi = node.pi })
    end, node.eid, node.pi)
end

NuiLocal['impound:take'] = function(args, cb)
    local ctx = Ctx
    if not ctx or ctx.type ~= 'impound' then return cb({ ok = false, error = 'Fourrière fermée' }) end
    local point = PointOf(ctx.eid, ctx.pi)
    if not point then return cb({ ok = false, error = 'Introuvable' }) end
    local idx = FreeSpawn(point)
    if not idx then return cb({ ok = false, error = 'Aucune place de sortie libre' }) end
    ESX.TriggerServerCallback('worldbuilder:impound:take', function(res)
        if not res or not res.ok then return cb(res or { ok = false, error = 'Erreur' }) end
        cb({ ok = true })
        CloseUI()
        local veh = SpawnVehicleAt(point.spawns[res.spawn], res.props.model or res.props.vehicle, res.props, res.plate)
        if not veh then
            TriggerServerEvent('worldbuilder:server:vehicleFailed', res.plate)
            return Notify('Impossible de sortir ce véhicule (modèle introuvable).', 'error')
        end
        reportSpawned(veh, res.plate)
        Notify(('Véhicule récupéré (%s %s).'):format(res.paid or 0, Config.Currency), 'success')
    end, ctx.eid, ctx.pi, args[1], idx, args[2])
end

NuiLocal['impound:seize'] = function(args, cb)
    local ctx = Ctx
    local point = ctx and PointOf(ctx.eid, ctx.pi)
    if not point then return cb({ ok = false, error = 'Fourrière fermée' }) end
    local veh = findVehicle(point.coords, 12.0)
    if not veh or not NetworkGetEntityIsNetworked(veh) then return cb({ ok = false, error = 'Aucun véhicule à mettre en fourrière à proximité' }) end
    local netId = NetworkGetNetworkIdFromEntity(veh)
    ESX.TriggerServerCallback('worldbuilder:impound:seize', function(res)
        if res and res.ok then CloseUI() Notify(('Véhicule %s mis en fourrière.'):format(res.plate or ''), 'success') end
        cb(res or { ok = false, error = 'Erreur' })
    end, ctx.eid, ctx.pi, netId, args[1], args[2])
end
