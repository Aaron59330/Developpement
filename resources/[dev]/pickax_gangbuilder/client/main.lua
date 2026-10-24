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

-- Menu F6 / F7 : le joueur peut continuer à marcher (le clavier reste au jeu) ; la caméra ne bouge pas, la souris ne sert qu'au menu.
-- Échap / Retour ferment le menu (le NUI ne reçoit plus le clavier) ; pas de tir ni de visée tant que le menu est ouvert.
local walkMenu = false
local function setWalkMenu(on)
    on = on == true
    if on == walkMenu then return end
    walkMenu = on
    SetNuiFocusKeepInput(on)
    if not on then return end
    CreateThread(function()
        while walkMenu and uiOpen do
            Wait(0)
            -- tir / visée / pause + caméra à la souris (1-6, 106, 270-273) : la souris ne sert qu'au menu
            for _, c in ipairs({ 24, 25, 257, 140, 141, 142, 263, 264, 200, 199, 1, 2, 3, 4, 5, 6, 106, 270, 271, 272, 273 }) do DisableControlAction(0, c, true) end
            if IsDisabledControlJustReleased(0, 200) or IsControlJustReleased(0, 177) then CloseUI() end
        end
    end)
end

function OpenUI(payload)
    if IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true then return end   -- mort : aucun menu
    if payload.action == 'open' and payload.kind ~= 'menu' and menuOrigin and GetGameTimer() - menuOrigin < 4000 then payload.back = true end
    menuOrigin = nil
    -- couleur des menus : celle du gang si elle est définie (menus du gang), sinon la couleur du serveur (builder : toujours la globale)
    local own = payload.kind ~= 'builder' and State.gangConfig and State.gangConfig.accent
    payload.theme = own or (Config.UI and Config.UI.Accent)
    uiOpen = true
    SetNuiFocus(true, true)
    setWalkMenu(payload.action == 'open' and payload.kind == 'menu')
    SendNUIMessage(payload)
end

function CloseUI()
    placing = false
    if not uiOpen then return end
    uiOpen = false
    setWalkMenu(false)
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

local returnVehicle   -- défini plus bas (a besoin de vehicleKind)

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
                    DrawGBMarker(BB.Style(pointType(p), p.style), c, Config.UseGangColor and p.color or nil)
                    if dist < (p.type == 'garage_return' and (p.radius or 5.0) or Config.InteractDistance) then nearest = p end
                end
            end
            if nearest then
                local t = pointType(nearest)
                if not BB.HelpEnabled(t, nearest.style) then
                elseif nearest.type == 'garage_return' then
                    ESX.ShowHelpNotification(GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 and 'Appuie sur ~INPUT_CONTEXT~ : ranger le véhicule' or 'Reviens au volant d\'un véhicule du gang pour le ranger')
                elseif nearest.label == t.label or nearest.label == '' then
                    ESX.ShowHelpNotification(('Appuie sur ~INPUT_CONTEXT~ : %s'):format(t.label))
                else
                    ESX.ShowHelpNotification(('Appuie sur ~INPUT_CONTEXT~ : %s (%s)'):format(nearest.label, t.label))
                end
                if IsControlJustReleased(0, 38) then
                    if nearest.type == 'garage_return' then returnVehicle(nearest) else openPoint(nearest) end
                end
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

-- Le job2 a pu changer (commande admin, autre script) sans que le gang soit déjà synchronisé : on le redemande au serveur avant de conclure « aucun gang »
local noGang = nil
RegisterNetEvent('gangbuilder:client:diag', function(d) noGang = d end)

local function ensureGang()
    if State.gangConfig then return State.gangConfig end
    noGang = nil
    TriggerServerEvent('gangbuilder:server:requestSync')
    local t = GetGameTimer()
    while not State.gangConfig and GetGameTimer() - t < 1500 do Wait(50) end
    if not State.gangConfig and noGang then
        notify(('~r~Aucun gang : ton job2 est « %s », il doit être EXACTEMENT le nom d\'un gang du builder (%s).'):format(noGang.job2 ~= '' and noGang.job2 or 'vide', #noGang.known > 0 and table.concat(noGang.known, ', ') or 'aucun gang créé'))
    end
    return State.gangConfig
end

-- ─────────────────────────────── Menu gang ───────────────────────────────
local function openGangMenu()
    local gc = ensureGang()
    if not gc then return end
    local actions = {}
    for _, id in ipairs(gc.actions or {}) do
        local a = Config.Actions[id]
        if a then actions[#actions + 1] = { id = id, label = a.label, icon = a.icon, target = a.target } end
    end
    OpenUI({ action = 'open', kind = 'menu', data = { gangLabel = gc.label, color = gc.color, grade = gc.gradeLabel or '', actions = actions } })
end

local lastGangToggle = 0
local function toggleGangMenu()
    if GetGameTimer() - lastGangToggle < 400 then return end   -- la touche peut arriver par la commande ET par le contrôle : une seule ouverture
    lastGangToggle = GetGameTimer()
    if not uiOpen then CreateThread(openGangMenu) elseif walkMenu then CloseUI() end
end

RegisterCommand(Config.GangMenuCommand, toggleGangMenu, false)
-- Filet de sécurité : si le raccourci enregistré (RegisterKeyMapping) a été perdu / réattribué dans les paramètres FiveM, F7 (contrôle 168) ouvre quand même le menu
CreateThread(function()
    while true do
        Wait(0)
        if Config.GangMenuKey == 'F7' and IsControlJustPressed(0, 168) and not IsNuiFocused() then toggleGangMenu() end
    end
end)
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

-- Rangement à part : au volant d'un véhicule du bon type, E = rangé (le serveur vérifie la plaque du gang)
returnVehicle = function(point)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then return notify('~r~Tu dois être au volant du véhicule à ranger.') end
    local want = point.kind or 'car'
    if vehicleKind(veh) ~= want then
        return notify(('~r~Ce point ne range que : %s'):format((Config.GarageKinds[want] or Config.GarageKinds.car).label:lower()))
    end
    ESX.TriggerServerCallback('gangbuilder:garage:return', function(res)
        if res and res.ok then
            ESX.Game.DeleteVehicle(veh)
            notify('~g~Véhicule rangé.')
        else
            notify('~r~' .. ((res and res.error) or 'Impossible de ranger ce véhicule'))
        end
    end, point.id, GetVehicleNumberPlateText(veh))
end


local function findPoint(id)
    for _, p in ipairs(State.points) do if p.id == id then return p end end
end

-- ─────────────────────────────── RPC NUI -> client/serveur ───────────────────────────────
-- Callbacks serveur autorisés (nom JS -> 'gangbuilder:<nom>')
NuiRemote = {
    dlogsGet = true, dlogsSave = true, dlogsTest = true,
    list = true, get = true, catalog = true, save = true, delete = true, setMyJob = true, leaveMyJob = true,
    ['cloak:wear'] = true, ['armory:take'] = true, ['shop:buy'] = true,
    ['boss:money'] = true, ['boss:recruit'] = true, ['boss:setGrade'] = true, ['boss:fire'] = true, ['boss:salary'] = true, ['boss:poll'] = true,
    ['sell:do'] = true, info = true, leave = true,
    openPoint = true,
    ['settings:get'] = true, ['settings:save'] = true, ['settings:reset'] = true,
    ['tablet:open'] = true, ['tablet:claim'] = true, ['tablet:warPropose'] = true, ['tablet:warRespond'] = true,
    ['props:list'] = true, ['props:remove'] = true, ['props:removeAll'] = true,
    ['terr:list'] = true, ['terr:save'] = true, ['terr:delete'] = true, ['terr:setOwner'] = true,
}

-- Handlers locaux (nom JS -> function(args, cb))
NuiLocal = {}

NuiLocal.close = function(_, cb) CloseUI() cb({}) end

-- Tablette : point GPS vers un territoire / une zone
NuiLocal.waypoint = function(args, cb)
    local p = args[1]
    if p and tonumber(p.x) and tonumber(p.y) then
        SetNewWaypoint(p.x + 0.0, p.y + 0.0)
        notify('Point GPS défini.')
    end
    cb({ ok = true })
end

-- Tablette de gang (F7, commande, menu contextuel → Organisation)
function OpenGangTablet()
    if not ensureGang() then return end
    ESX.TriggerServerCallback('gangbuilder:tablet:open', function(res)
        if not res or not res.ok then return notify('~r~' .. ((res and res.error) or 'Tablette indisponible')) end
        OpenUI({ action = 'open', kind = 'tablet', data = res })
    end)
end
exports('OpenTablet', OpenGangTablet)
RegisterNetEvent('gangbuilder:client:openTablet', function() if not uiOpen then OpenGangTablet() end end)
if Config.Tablet and Config.Tablet.Command and Config.Tablet.Command ~= '' then
    RegisterCommand(Config.Tablet.Command, function() if not uiOpen then OpenGangTablet() end end, false)
end

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
