ESX = exports['es_extended']:getSharedObject()

local State = { points = {}, blips = {}, gangConfig = nil }
local blipHandles = {}
local uiOpen = false
local placing = false

local function notify(msg) pcall(Config.Hooks.Notify, msg) end
function GBNotify(msg) notify(msg) end

-- ─────────────────────────────── NUI ───────────────────────────────
function IsUIOpen() return uiOpen end
function GetPoints() return State.points end
function GetGangConfig() return State.gangConfig end

local menuOrigin = nil   -- instant où une action du menu F7 a été choisie : l'écran ouvert juste après propose « Retour »

function OpenUI(payload)
    if IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true then return end   -- mort : aucun menu
    if payload.action == 'open' and payload.kind ~= 'menu' and menuOrigin and GetGameTimer() - menuOrigin < 4000 then payload.back = true end
    menuOrigin = nil
    payload.theme = Config.UI and Config.UI.Accent   -- couleur d'accentuation courante
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage(payload)
end

function CloseUI()
    placing = false
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    TriggerServerEvent('gangbuilder:server:requestSync')
end

-- ─────────────────────────────── Markers (réglages éditables en jeu) ───────────────────────────────
function DrawGBMarker(d, c, color)
    BB.DrawMarker(d, c, color)
end

-- Config poussée par le serveur (modifiée en jeu via /gangbuilder → Paramètres)
RegisterNetEvent('gangbuilder:client:config', function(snap)
    for section, value in pairs(snap or {}) do GBSet(section, value) end
    SendNUIMessage({ action = 'theme', accent = Config.UI and Config.UI.Accent })
    TriggerEvent('gangbuilder:internal:configChanged')
end)

-- ─────────────────────────────── Sync serveur ───────────────────────────────
local function rebuildBlips(list)
    for _, b in ipairs(blipHandles) do if DoesBlipExist(b) then RemoveBlip(b) end end
    blipHandles = {}
    for _, b in ipairs(list or {}) do
        -- un blip invalide ne doit jamais empêcher les suivants de s'afficher
        pcall(function()
            blipHandles[#blipHandles + 1] = BB.Blip(b.coords, b, { label = 'Gang', category = b.category })
        end)
    end
end

RegisterNetEvent('gangbuilder:client:sync', function(data)
    local merged, seen = {}, {}
    for _, p in ipairs(data.points or {}) do merged[#merged + 1] = p seen[p.id] = true end
    for _, p in ipairs(data.shops or {}) do if not seen[p.id] then merged[#merged + 1] = p end end
    State.points = merged
    State.gangConfig = data.gangConfig
    rebuildBlips(data.blips)
    TriggerEvent('gangbuilder:internal:territories', data.territories)
end)

CreateThread(function()
    Wait(2000)
    TriggerServerEvent('gangbuilder:server:requestSync')
end)

-- Solde du gang poussé par le serveur : l'interface ouverte se met à jour en direct
RegisterNetEvent('gangbuilder:client:money', function(gang, money, dirty)
    SendNUIMessage({ action = 'money', gang = gang, money = money, dirty = dirty })
end)

-- Redemande les points quand le job2 change (filet de sécurité en plus de la synchro serveur)
for _, ev in ipairs({ 'esx:setJob2' }) do
    RegisterNetEvent(ev, function() SetTimeout(800, function() TriggerServerEvent('gangbuilder:server:requestSync') end) end)
end

-- /gbdebug : état du client (points reçus, gang, UI) + resynchronisation
RegisterCommand('gbdebug', function()
    local g = State.gangConfig
    local lines = { ('gangbuilder — gang : %s (grade %s) | points reçus : %d | UI ouverte : %s'):format(g and g.name or 'aucun', g and tostring(g.grade) or '-', #State.points, tostring(uiOpen)) }
    for _, p in ipairs(State.points) do lines[#lines + 1] = ('  #%d %s « %s » à %.1f m'):format(p.id, p.type, p.label or '', #(GetEntityCoords(PlayerPedId()) - vector3(p.coords.x, p.coords.y, p.coords.z))) end
    for _, l in ipairs(lines) do print(l) TriggerEvent('chat:addMessage', { args = { l } }) end
    TriggerServerEvent('gangbuilder:server:requestSync')
end, false)

-- /gbreset : débloque l'UI si elle est restée "ouverte" (ex : mode placement oublié)
RegisterCommand('gbreset', function()
    uiOpen, placing = false, false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    TriggerServerEvent('gangbuilder:server:requestSync')
end, false)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    rebuildBlips({})
    if uiOpen then SetNuiFocus(false, false) end
end)

-- ─────────────────────────────── Markers & interaction ───────────────────────────────
local opening = false
local function openPoint(point)
    if opening or uiOpen then return end
    opening = true
    SetTimeout(1500, function() opening = false end)
    ESX.TriggerServerCallback('gangbuilder:openPoint', function(res)
        opening = false
        if uiOpen then return end
        if not res or not res.ok then
            notify('~r~' .. ((res and res.error) or 'Erreur'))
            return
        end
        if res.kind == 'stash' then
            exports.ox_inventory:openInventory('stash', res.stash)
            return
        end
        OpenUI({ action = 'open', kind = res.kind, pointId = point.id, data = res })
    end, point.id)
end

-- Rouvre un point après une activité : le panneau se met à jour avec le nouveau contenu de l'inventaire
function ReopenPoint(id)
    for _, p in ipairs(State.points) do
        if p.id == id then return openPoint(p) end
    end
end

local function pointType(p)
    return Config.PointTypes[(p.type == 'garage' and p.kind and p.kind ~= 'car') and ('garage_' .. p.kind) or p.type] or Config.PointTypes[p.type]
end

CreateThread(function()
    while true do
        local sleep = 1000
        if not uiOpen and #State.points > 0 then
            local pos = GetEntityCoords(PlayerPedId())
            local nearest
            for _, p in ipairs(State.points) do
                local c = p.coords
                local dist = #(pos - vector3(c.x, c.y, c.z))
                if dist < Config.DrawDistance then
                    sleep = 0
                    DrawGBMarker(pointType(p), c, Config.UseGangColor and p.color or nil)
                    if dist < Config.InteractDistance then nearest = p end
                end
            end
            if nearest then
                local t = pointType(nearest)
                if not BB.HelpEnabled(t, nearest.style) then
                elseif nearest.label == t.label or nearest.label == '' then
                    ESX.ShowHelpNotification(('Appuie sur ~INPUT_CONTEXT~ : %s'):format(t.label))
                else
                    ESX.ShowHelpNotification(('Appuie sur ~INPUT_CONTEXT~ : %s (%s)'):format(nearest.label, t.label))
                end
                if IsControlJustReleased(0, 38) then openPoint(nearest) end
            end
        end
        Wait(sleep)
    end
end)

-- Mort : un menu déjà ouvert se ferme
CreateThread(function()
    while true do
        Wait(250)
        if uiOpen and (IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true) then CloseUI() end
    end
end)

-- ─────────────────────────────── Menu gang ───────────────────────────────
local function openGangMenu()
    local gc = State.gangConfig
    if not gc then return notify('~r~Tu n\'es dans aucun gang.') end
    local actions = {}
    for _, id in ipairs(gc.actions or {}) do
        local a = Config.Actions[id]
        if a then actions[#actions + 1] = { id = id, label = a.label, icon = a.icon, target = a.target } end
    end
    OpenUI({ action = 'open', kind = 'menu', data = { gangLabel = gc.label, color = gc.color, grade = gc.gradeLabel or '', actions = actions } })
end

RegisterCommand(Config.GangMenuCommand, function() if not uiOpen then openGangMenu() end end, false)
RegisterKeyMapping(Config.GangMenuCommand, 'Menu du gang', 'keyboard', Config.GangMenuKey)

RegisterNetEvent('gangbuilder:client:openBuilder', function()
    if uiOpen then return end
    OpenUI({ action = 'open', kind = 'builder' })
end)

-- ─────────────────────────────── Helpers ───────────────────────────────
function GetNearestPlayerId()
    local player, dist = ESX.Game.GetClosestPlayer()
    if player ~= -1 and dist ~= -1 and dist <= Config.TargetDistance then return GetPlayerServerId(player) end
    return nil
end

local function pedSex()
    return GetEntityModel(PlayerPedId()) == joaat('mp_f_freemode_01') and 'f' or 'm'
end

local function spawnVehicle(res)
    local c = res.spawn
    ESX.Game.SpawnVehicle(res.model, vector3(c.x, c.y, c.z), c.h, function(veh)
        SetVehicleNumberPlateText(veh, res.plate)
        SetVehicleFuelLevel(veh, 100.0)
        if res.color then SetVehicleColours(veh, res.color, res.color) end
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        pcall(Config.Hooks.OnVehicleSpawned, veh, res.plate)
    end)
end

-- Type de véhicule d'après sa classe GTA : 8/13 moto-vélo, 14 bateau, 15/16 aéronef, le reste voiture
local function vehicleKind(veh)
    local c = GetVehicleClass(veh)
    if c == 8 or c == 13 then return 'bike' elseif c == 14 then return 'boat' elseif c == 15 or c == 16 then return 'aircraft' end
    return 'car'
end

local function findPoint(id)
    for _, p in ipairs(State.points) do if p.id == id then return p end end
end

-- ─────────────────────────────── RPC NUI -> client/serveur ───────────────────────────────
-- Callbacks serveur autorisés (nom JS -> 'gangbuilder:<nom>')
NuiRemote = {
    list = true, get = true, catalog = true, save = true, delete = true, setMyJob = true, leaveMyJob = true,
    ['cloak:wear'] = true, ['armory:take'] = true, ['shop:buy'] = true,
    ['boss:money'] = true, ['boss:recruit'] = true, ['boss:setGrade'] = true, ['boss:fire'] = true, ['boss:salary'] = true, ['boss:poll'] = true,
    ['sell:do'] = true, info = true, leave = true,
    openPoint = true,
    ['settings:get'] = true, ['settings:save'] = true, ['settings:reset'] = true,
    ['terr:list'] = true, ['terr:save'] = true, ['terr:delete'] = true, ['terr:setOwner'] = true,
}

-- Handlers locaux (nom JS -> function(args, cb))
NuiLocal = {}

NuiLocal.close = function(_, cb) CloseUI() cb({}) end

-- Retour au panel central (builderhub) : ferme ce builder puis ouvre /builders
NuiLocal.bbHub = function(_, cb)
    cb({ ok = true })
    NuiLocal.close({}, function() end)
    SetTimeout(250, function() ExecuteCommand('builders') end)
end

NuiLocal.getCoords = function(_, cb)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    cb({ x = c.x, y = c.y, z = c.z, h = GetEntityHeading(ped) })
end

NuiLocal.teleport = function(args, cb)
    local c = args[1]
    if c and c.x then
        ESX.TriggerServerCallback('gangbuilder:isDev', function(ok)
            if ok then SetEntityCoords(PlayerPedId(), c.x + 0.0, c.y + 0.0, c.z + 0.0, false, false, false, false) end
            cb({ ok = ok })
        end)
    else cb({ ok = false }) end
end

NuiLocal.checkModel = function(args, cb)
    local hash = joaat(tostring(args[1] or ''))
    cb({ valid = IsModelInCdimage(hash) and IsModelAVehicle(hash) })
end

NuiLocal.captureOutfit = function(_, cb)
    Config.Hooks.GetClothes(function(skin)
        local out = {}
        for _, k in ipairs(Config.ClothesKeys) do
            if skin and skin[k] ~= nil then out[k] = skin[k] end
        end
        cb({ sex = pedSex(), clothes = out })
    end)
end

NuiLocal.cloakCivil = function(_, cb)
    Config.Hooks.RestoreCivil()
    cb({ ok = true })
end

NuiLocal['garage:spawn'] = function(args, cb)
    local point = findPoint(args[1])
    if point and point.spawn then
        local clear = (Config.GarageKinds[point.kind or 'car'] or Config.GarageKinds.car).clear
        if not ESX.Game.IsSpawnPointClear(vector3(point.spawn.x, point.spawn.y, point.spawn.z), clear) then
            return cb({ ok = false, error = 'La sortie du garage est bloquée' })
        end
    end
    ESX.TriggerServerCallback('gangbuilder:garage:spawn', function(res)
        if res and res.ok then
            CloseUI()
            spawnVehicle(res)
        end
        cb(res or { ok = false, error = 'Erreur' })
    end, args[1], args[2])
end

NuiLocal['garage:store'] = function(args, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then
        return cb({ ok = false, error = 'Tu dois être au volant du véhicule à ranger' })
    end
    local point = findPoint(args[1])
    local want = (point and point.kind) or 'car'
    if vehicleKind(veh) ~= want then
        return cb({ ok = false, error = ('Ce garage n\'accepte que : %s'):format((Config.GarageKinds[want] or Config.GarageKinds.car).label:lower()) })
    end
    ESX.TriggerServerCallback('gangbuilder:garage:store', function(res)
        if res and res.ok then
            ESX.Game.DeleteVehicle(veh)
            CloseUI()
        end
        cb(res or { ok = false, error = 'Erreur' })
    end, args[1], GetVehicleNumberPlateText(veh))
end

NuiLocal.openGangMenu = function(_, cb)
    CloseUI()
    cb({ ok = true })
    openGangMenu()
end

NuiLocal.doAction = function(args, cb)
    CloseUI()
    menuOrigin = GetGameTimer()
    RunAction(args[1])
    cb({ ok = true })
end

-- Aperçu d'un marker devant le joueur pendant quelques secondes
NuiLocal.previewMarker = function(args, cb)
    local def = args[1]
    if type(def) == 'table' then
        local ped = PlayerPedId()
        local c = GetOffsetFromEntityInWorldCoords(ped, 0.0, 3.0, 0.0)
        local d = { marker = tonumber(def.marker) or 1, color = def.color, alpha = tonumber(def.alpha), scale = def.scale, offset = tonumber(def.offset), bob = def.bob == true, rotate = def.rotate == true }
        CreateThread(function()
            local untilT = GetGameTimer() + 8000
            while GetGameTimer() < untilT do
                DrawGBMarker(d, { x = c.x, y = c.y, z = c.z })
                Wait(0)
            end
        end)
    end
    cb({ ok = true })
end

-- Mode placement : le menu se réduit en HUD, le joueur se déplace librement.
-- Entrée = enregistrer la position, ← / → = changer de cible, Retour arrière = revenir au menu.
NuiLocal.placement = function(args, cb)
    if args[1] and not placing then
        placing = true
        SetNuiFocus(false, false)
        CreateThread(function()
            while placing do
                if IsControlJustReleased(0, 201) then
                    local ped = PlayerPedId()
                    local c = GetEntityCoords(ped)
                    SendNUIMessage({ action = 'placementSave', coords = { x = c.x, y = c.y, z = c.z, h = GetEntityHeading(ped) } })
                elseif IsControlJustReleased(0, 190) then SendNUIMessage({ action = 'placementNav', dir = 1 })
                elseif IsControlJustReleased(0, 189) then SendNUIMessage({ action = 'placementNav', dir = -1 })
                elseif IsControlJustReleased(0, 177) then
                    placing = false
                    SetNuiFocus(true, true)
                    SendNUIMessage({ action = 'placementEnd' })
                end
                Wait(0)
            end
        end)
    end
    cb({ ok = true })
end

NuiLocal.nearestPlayer = function(_, cb) cb({ id = GetNearestPlayerId() }) end

RegisterNUICallback('rpc', function(body, cb)
    local name, args = body.name, body.args or {}
    if NuiLocal[name] then
        return NuiLocal[name](args, cb)
    end
    if NuiRemote[name] then
        -- Les actions qui ciblent un joueur voisin reçoivent son ID ici (jamais fourni par le NUI)
        if name == 'boss:recruit' then args[2] = GetNearestPlayerId() or -1 end
        if name == 'cloak:wear' then
            return ESX.TriggerServerCallback('gangbuilder:' .. name, function(res)
                if res and res.ok then Config.Hooks.ApplyClothes(res.clothes) end
                cb(res or { ok = false })
            end, table.unpack(args))
        end
        return ESX.TriggerServerCallback('gangbuilder:' .. name, function(res) cb(res or { ok = false, error = 'Aucune réponse' }) end, table.unpack(args))
    end
    cb({ ok = false, error = 'Appel inconnu' })
end)

-- Fermeture sécurité : si le joueur meurt, on ferme l'UI
CreateThread(function()
    while true do
        Wait(500)
        if uiOpen and IsEntityDead(PlayerPedId()) then CloseUI() end
    end
end)
