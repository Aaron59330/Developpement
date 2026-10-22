ESX = exports['es_extended']:getSharedObject()

local open = false
local prevPos = nil          -- position avant ma dernière téléportation (retour)

-- ─────────────── Ouverture ───────────────
local function closeUI()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function stateOf()
    local ok, st = pcall(function() return exports.pickax_core:StaffState() end)
    return ok and st or {}
end

local function openUI()
    if open then return end
    if IsEntityDead(PlayerPedId()) then return end
    ESX.TriggerServerCallback('pickax_staff:open', function(res)
        if not res or not res.ok then return ESX.ShowNotification('~r~Accès refusé : réservé à l\'équipe.') end
        open = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', data = res, state = stateOf() })
    end)
end

local function toggleUI() if open then closeUI() else openUI() end end

exports('Toggle', toggleUI)
exports('Open', openUI)
exports('Close', closeUI)
RegisterCommand(Config.Command, toggleUI, false)

CreateThread(function()
    while true do
        Wait(300)
        if open and IsEntityDead(PlayerPedId()) then closeUI() end
    end
end)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() and open then SetNuiFocus(false, false) end end)

-- ─────────────── Outils locaux ───────────────
local function notify(msg) ESX.ShowNotification(msg) end

local function remember() prevPos = GetEntityCoords(PlayerPedId()) end

local function loadModel(model)
    local hash = type(model) == 'number' and model or GetHashKey(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then return nil end
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) do
        Wait(10)
        if GetGameTimer() - t > 5000 then return nil end
    end
    return hash
end

-- véhicule actuel, sinon le plus proche (8 m)
local function targetVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then return veh end
    local c = GetEntityCoords(ped)
    local best, bd = 0, 8.0
    for _, v in ipairs(GetGamePool('CVehicle')) do
        local d = #(GetEntityCoords(v) - c)
        if d < bd then best, bd = v, d end
    end
    return best
end

local function setFuel(veh, level)
    if GetResourceState('ox_fuel') == 'started' then Entity(veh).state.fuel = level end
    if GetResourceState('LegacyFuel') == 'started' then pcall(function() exports['LegacyFuel']:SetFuel(veh, level) end) end
    SetVehicleFuelLevel(veh, level)
end

local function control(veh)
    if veh == 0 or not DoesEntityExist(veh) then notify('~r~Aucun véhicule à proximité') return false end
    if not NetworkHasControlOfEntity(veh) then
        NetworkRequestControlOfEntity(veh)
        local t = GetGameTimer()
        while not NetworkHasControlOfEntity(veh) and GetGameTimer() - t < 1500 do Wait(10) NetworkRequestControlOfEntity(veh) end
    end
    return true
end

local H = {}
H.tp_waypoint = function()
    local wp = GetFirstBlipInfoId(8)
    if not DoesBlipExist(wp) then return false, 'Pose d\'abord un marqueur sur la carte' end
    local c = GetBlipInfoIdCoord(wp)
    remember()
    local ped = PlayerPedId()
    local target = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or ped
    local found, z = false, 0.0
    for h = 1000, 0, -25 do
        SetEntityCoordsNoOffset(target, c.x, c.y, h + 0.0, false, false, false)
        Wait(0)
        found, z = GetGroundZFor_3dCoord(c.x, c.y, h + 0.0, false)
        if found then break end
    end
    SetEntityCoordsNoOffset(target, c.x, c.y, (found and z or 100.0) + 1.0, false, false, false)
    return true
end
H.tp_coords = function(a)
    local x, y, z = tonumber(a.x), tonumber(a.y), tonumber(a.z)
    if not x or not y or not z then return false, 'Coordonnées invalides' end
    remember()
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or ped, x + 0.0, y + 0.0, z + 0.0, false, false, false)
    return true
end
H.tp_back = function()
    if not prevPos then return false, 'Aucune position précédente' end
    local p = prevPos
    prevPos = GetEntityCoords(PlayerPedId())
    SetEntityCoordsNoOffset(PlayerPedId(), p.x, p.y, p.z, false, false, false)
    return true
end
H.veh_spawn = function(a)
    local hash = loadModel(tostring(a.model or ''))
    if not hash then return false, 'Modèle de véhicule introuvable' end
    local ped = PlayerPedId()
    local c, h = GetEntityCoords(ped), GetEntityHeading(ped)
    local old = GetVehiclePedIsIn(ped, false)
    if old ~= 0 and a.replace == true and control(old) then SetEntityAsMissionEntity(old, true, true) DeleteVehicle(old) end
    local veh = CreateVehicle(hash, c.x, c.y, c.z + 0.5, h, true, false)
    SetVehicleOnGroundProperly(veh)
    SetVehicleNumberPlateText(veh, 'STAFF' .. math.random(100, 999))
    setFuel(veh, 100.0)
    TaskWarpPedIntoVehicle(ped, veh, -1)
    SetModelAsNoLongerNeeded(hash)
    return true
end
H.veh_repair = function()
    local veh = targetVehicle()
    if not control(veh) then return false, 'Aucun véhicule' end
    SetVehicleFixed(veh)
    SetVehicleDeformationFixed(veh)
    SetVehicleEngineHealth(veh, 1000.0)
    SetVehicleBodyHealth(veh, 1000.0)
    SetVehiclePetrolTankHealth(veh, 1000.0)
    SetVehicleEngineOn(veh, true, true, false)
    return true
end
H.veh_delete = function()
    local veh = targetVehicle()
    if not control(veh) then return false, 'Aucun véhicule' end
    SetEntityAsMissionEntity(veh, true, true)
    DeleteVehicle(veh)
    return true
end
H.veh_clean = function()
    local veh = targetVehicle()
    if not control(veh) then return false, 'Aucun véhicule' end
    SetVehicleDirtLevel(veh, 0.0)
    WashDecalsFromVehicle(veh, 1.0)
    return true
end
H.veh_flip = function()
    local veh = targetVehicle()
    if not control(veh) then return false, 'Aucun véhicule' end
    SetVehicleOnGroundProperly(veh)
    return true
end
H.veh_unlock = function()
    local veh = targetVehicle()
    if not control(veh) then return false, 'Aucun véhicule' end
    SetVehicleDoorsLocked(veh, 1)
    SetVehicleDoorsLockedForAllPlayers(veh, false)
    return true
end
H.veh_fuel = function()
    local veh = targetVehicle()
    if not control(veh) then return false, 'Aucun véhicule' end
    setFuel(veh, 100.0)
    return true
end
H.veh_plate = function(a)
    local veh = targetVehicle()
    local p = tostring(a.plate or ''):upper():gsub('[^%w ]', ''):sub(1, 8)
    if #p < 1 then return false, 'Plaque invalide (lettres et chiffres, 8 max)' end
    if not control(veh) then return false, 'Aucun véhicule' end
    SetVehicleNumberPlateText(veh, p)
    return true
end
H.veh_neon = function(a)
    local veh = targetVehicle()
    if not control(veh) then return false, 'Aucun véhicule' end
    if a.off == true then
        for i = 0, 3 do SetVehicleNeonLightEnabled(veh, i, false) end
        return true
    end
    local r, g, b = math.floor(tonumber(a.r) or 0), math.floor(tonumber(a.g) or 0), math.floor(tonumber(a.b) or 0)
    r, g, b = math.max(0, math.min(255, r)), math.max(0, math.min(255, g)), math.max(0, math.min(255, b))
    for i = 0, 3 do SetVehicleNeonLightEnabled(veh, i, true) end
    SetVehicleNeonLightsColour(veh, r, g, b)
    return true
end
H.veh_max = function()
    local veh = targetVehicle()
    if not control(veh) then return false, 'Aucun véhicule' end
    SetVehicleModKit(veh, 0)
    for mod = 0, 49 do
        if mod ~= 18 and mod ~= 22 and mod ~= 23 and mod ~= 24 and mod ~= 48 then
            local n = GetNumVehicleMods(veh, mod)
            if n > 0 then SetVehicleMod(veh, mod, n - 1, false) end
        end
    end
    ToggleVehicleMod(veh, 18, true)
    ToggleVehicleMod(veh, 22, true)
    SetVehicleWindowTint(veh, 1)
    return true
end
H.self_clothes = function() return true end
H.legacy = function()
    closeUI()
    SetTimeout(200, function() pcall(function() exports.pickax_core:StaffOpenLegacy() end) end)
    return true
end

-- ─────────────── Pont NUI ↔ serveur ───────────────
local NuiRemote = {
    dash = true, players = true, player = true, inventory = true, items = true, jobs = true, grades = true, act = true, deleteEntry = true,
    reports = true, reportTake = true, reportClose = true, reportReply = true,
    weather = true, time = true, announce = true, cleanup = true, reviveAll = true, healAll = true,
    chatList = true, chatSend = true, logs = true, warns = true, bookmarkSave = true, bookmarkDelete = true, permsGet = true, permsSave = true, permsReset = true,
}

local function runClient(c)
    if type(c) ~= 'table' then return end
    if c.kind == 'spect' then
        closeUI()
        ExecuteCommand('spect ' .. tostring(c.id))
    elseif c.kind == 'cmd' and type(c.cmd) == 'string' then
        ExecuteCommand(c.cmd)
    end
end

local NuiLocal = {}
NuiLocal.close = function(_, cb) cb({ ok = true }) closeUI() end
NuiLocal.state = function(_, cb) cb({ ok = true, state = stateOf() }) end

NuiLocal.toggle = function(a, cb)
    local map = { service = 'StaffSetService', noclip = 'StaffSetNoclip', invisible = 'StaffSetInvisible', invincible = 'StaffSetInvincible', names = 'StaffSetNames', hud = 'StaffSetHud' }
    local fn = map[a[1]]
    if not fn then return cb({ ok = false, error = 'Réglage inconnu' }) end
    local ok, res, err = pcall(function() return exports.pickax_core[fn](exports.pickax_core, a[2] == true) end)
    if not ok or res == false then return cb({ ok = false, error = (type(err) == 'string' and err) or 'Impossible', state = stateOf() }) end
    cb({ ok = true, state = stateOf() })
end

-- ouvrir un autre panel staff (après fermeture de celui-ci)
NuiLocal.openPanel = function(a, cb)
    local allowed = { anticheat = 'anticheat', builders = 'builders' }
    local cmd = allowed[a[1]]
    if not cmd then return cb({ ok = false, error = 'Panel inconnu' }) end
    cb({ ok = true })
    closeUI()
    SetTimeout(250, function() ExecuteCommand(cmd) end)
end

NuiLocal.coords = function(_, cb)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    cb({ ok = true, x = math.floor(c.x * 100) / 100, y = math.floor(c.y * 100) / 100, z = math.floor(c.z * 100) / 100, h = math.floor(GetEntityHeading(ped) * 100) / 100 })
end

-- action sur moi : droit + journal côté serveur, exécution ici
NuiLocal.me = function(a, cb)
    local action, args = a[1], type(a[2]) == 'table' and a[2] or {}
    ESX.TriggerServerCallback('pickax_staff:self', function(res)
        if not res or not res.ok then return cb(res or { ok = false, error = 'Aucune réponse' }) end
        local h = H[action]
        if h then
            local ok, err = h(args)
            if ok == false then return cb({ ok = false, error = err or 'Impossible' }) end
        end
        cb({ ok = true })
    end, action, args)
end

-- action sur un joueur ; le serveur peut demander une suite côté client (spectate, jail…)
NuiLocal.act = function(a, cb)
    ESX.TriggerServerCallback('pickax_staff:act', function(res)
        if res and res.ok and res.client then runClient(res.client) end
        cb(res or { ok = false, error = 'Aucune réponse' })
    end, a[1], a[2], type(a[3]) == 'table' and a[3] or {})
end

RegisterNUICallback('rpc', function(body, cb)
    local name, args = body.name, body.args or {}
    if NuiLocal[name] then return NuiLocal[name](args, cb) end
    if NuiRemote[name] then
        return ESX.TriggerServerCallback('pickax_staff:' .. name, function(res)
            cb(res or { ok = false, error = 'Aucune réponse' })
        end, table.unpack(args))
    end
    cb({ ok = false, error = 'Appel inconnu' })
end)

-- ─────────────── Événements reçus ───────────────
RegisterNetEvent('pickax_staff:announce', function(text, author)
    ESX.ShowAdvancedNotification('ANNONCE', author or 'Staff', text, 'CHAR_CALL911', 8)
    PlaySoundFrontend(-1, 'Menu_Accept', 'Phone_SoundSet_Default', true)
end)

RegisterNetEvent('pickax_staff:chat', function(msg)
    if open then SendNUIMessage({ action = 'chat', message = msg })
    else ESX.ShowNotification(('~b~[Staff]~s~ %s : %s'):format(msg.name or '?', msg.text or '')) end
end)
