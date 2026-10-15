ESX = exports['es_extended']:getSharedObject()

local State = { points = {}, blips = {}, jobConfig = nil }
local blipHandles = {}
local uiOpen = false

-- ─────────────────────────────── NUI ───────────────────────────────
function IsUIOpen() return uiOpen end
function GetPoints() return State.points end

local menuOrigin = nil   -- instant où une action du menu F6 a été choisie : l'écran ouvert juste après propose « Retour »

local uiKind = nil

-- Couleur à afficher : celle du job (sauf éditeur) sinon la globale
local function currentAccent()
    local own = uiKind ~= 'builder' and State.jobConfig and State.jobConfig.accent
    return own or (Config.UI and Config.UI.Accent)
end

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
    uiKind = payload.kind
    if payload.action == 'open' and payload.kind ~= 'menu' and menuOrigin and GetGameTimer() - menuOrigin < 4000 then payload.back = true end
    menuOrigin = nil
    -- couleur d'accentuation : celle du job du joueur si elle est définie (menus du job), sinon la couleur globale (builder : toujours la globale)
    payload.theme = currentAccent()
    uiOpen = true
    SetNuiFocus(true, true)
    setWalkMenu(payload.action == 'open' and payload.kind == 'menu')
    SendNUIMessage(payload)
end

local placing = false

function CloseUI()
    placing = false
    if not uiOpen then return end
    uiOpen = false
    setWalkMenu(false)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    TriggerServerEvent('jobbuilder:server:requestSync')
end

-- ─────────────────────────────── Markers (réglages éditables en jeu) ───────────────────────────────
function DrawJBMarker(d, c)
    BB.DrawMarker(d, c)
end

-- Config poussée par le serveur (modifiée en jeu via /jobbuilder → Paramètres)
RegisterNetEvent('jobbuilder:client:config', function(snap)
    for section, value in pairs(snap or {}) do JBSet(section, value) end
    SendNUIMessage({ action = 'theme', accent = currentAccent() })
    TriggerEvent('jobbuilder:internal:configChanged')
end)

-- ─────────────────────────────── Sync serveur ───────────────────────────────
local function rebuildBlips(list)
    for _, b in ipairs(blipHandles) do if DoesBlipExist(b) then RemoveBlip(b) end end
    blipHandles = {}
    for _, b in ipairs(list or {}) do
        -- un blip invalide ne doit jamais empêcher les suivants de s'afficher
        pcall(function()
            blipHandles[#blipHandles + 1] = BB.Blip(b.coords, b, { label = 'Job', category = b.category })
        end)
    end
end

RegisterNetEvent('jobbuilder:client:sync', function(data)
    local merged, seen = {}, {}
    for _, p in ipairs(data.points or {}) do merged[#merged + 1] = p seen[p.id] = true end
    for _, p in ipairs(data.shops or {}) do if not seen[p.id] then merged[#merged + 1] = p end end
    State.points = merged
    State.jobConfig = data.jobConfig
    if uiOpen then SendNUIMessage({ action = 'theme', accent = currentAccent() }) end     -- la synchro ne doit pas écraser la couleur du job
    rebuildBlips(data.blips)
end)

CreateThread(function()
    Wait(2000)
    TriggerServerEvent('jobbuilder:server:requestSync')
end)

-- Solde société poussé par le serveur : l'interface ouverte se met à jour en direct
RegisterNetEvent('jobbuilder:client:money', function(job, money)
    SendNUIMessage({ action = 'money', job = job, money = money })
end)

-- Redemande les points quand le métier change (filet de sécurité en plus de la synchro serveur)
RegisterNetEvent('esx:setJob', function()
    SetTimeout(800, function() TriggerServerEvent('jobbuilder:server:requestSync') end)
end)

-- /jbdebug : état du client (points reçus, métier, UI) + resynchronisation
RegisterCommand('jbdebug', function()
    -- ESX.PlayerData de l'objet partagé est une copie figée : on interroge ESX en direct
    local okP, pd = pcall(ESX.GetPlayerData)
    local job = (okP and pd and pd.job) or {}
    local lines = { ('jobbuilder — métier : %s (grade %s) | points reçus : %d | UI ouverte : %s'):format(tostring(job.name), tostring(job.grade), #State.points, tostring(uiOpen)) }
    for _, p in ipairs(State.points) do lines[#lines + 1] = ('  #%d %s « %s » à %.1f m'):format(p.id, p.type, p.label or '', #(GetEntityCoords(PlayerPedId()) - vector3(p.coords.x, p.coords.y, p.coords.z))) end
    for _, l in ipairs(lines) do print(l) TriggerEvent('chat:addMessage', { args = { l } }) end
    TriggerServerEvent('jobbuilder:server:requestSync')
end, false)

-- /jbreset : débloque l'UI si elle est restée "ouverte" (ex : mode placement oublié)
RegisterCommand('jbreset', function()
    uiOpen, placing = false, false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    TriggerServerEvent('jobbuilder:server:requestSync')
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
    ESX.TriggerServerCallback('jobbuilder:openPoint', function(res)
        opening = false
        if uiOpen then return end
        if not res or not res.ok then
            JBNotify('~r~' .. ((res and res.error) or 'Erreur'))
            return
        end
        if res.kind == 'stash' then
            exports.ox_inventory:openInventory('stash', res.stash)
            return
        end
        if res.kind == 'tuning' then return OpenTuning(point, res) end
        OpenUI({ action = 'open', kind = res.kind, pointId = point.id, data = res })
    end, point.id)
end

-- Rouvre un point après un travail (cuisine, récolte) : le panneau se met à jour avec le nouveau contenu de l'inventaire
function ReopenPoint(id)
    for _, p in ipairs(State.points) do
        if p.id == id then return openPoint(p) end
    end
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
                if dist < Config.DrawDistance and p.type ~= 'testdrive' then
                    sleep = 0
                    local t = Config.PointTypes[(p.type == 'garage' and p.kind and p.kind ~= 'car') and ('garage_' .. p.kind) or p.type] or Config.PointTypes[p.type]
                    if p.style then                      -- style propre au point / au job : seuls les champs renseignés remplacent ceux du type
                        local m = {}
                        for k, v in pairs(t) do m[k] = v end
                        for k, v in pairs(p.style) do m[k] = v end
                        t = m
                    end
                    DrawJBMarker(t, c)
                    if dist < (p.type == 'display' and Config.InteractDistance + 2.5 or p.type == 'garage_return' and (p.radius or 5.0) or Config.InteractDistance) then nearest = p end
                end
            end
            if nearest then
                local t = Config.PointTypes[(nearest.type == 'garage' and nearest.kind and nearest.kind ~= 'car') and ('garage_' .. nearest.kind) or nearest.type] or Config.PointTypes[nearest.type]
                local helpOn = BB.HelpEnabled(t, nearest.style)
                if not helpOn then
                elseif nearest.type == 'garage_return' then
                    local inVeh = GetVehiclePedIsIn(PlayerPedId(), false) ~= 0
                    ESX.ShowHelpNotification(inVeh and 'Appuie sur ~INPUT_CONTEXT~ : ranger le véhicule' or 'Reviens au volant d\'un véhicule du service pour le ranger')
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

-- ─────────────────────────────── Menu métier ───────────────────────────────
local function openJobMenu()
    local jc = State.jobConfig
    if not jc then
        JBNotify('~r~Aucune action disponible pour ton métier.')
        return
    end
    local actions = {}
    for _, id in ipairs(jc.actions) do
        local a = Config.Actions[id]
        if a then actions[#actions + 1] = { id = id, label = a.label, icon = a.icon, target = a.target } end
    end
    if Config.AllowLeave ~= false then actions[#actions + 1] = { id = 'leavejob', label = 'Quitter le métier', icon = 'logout' } end
    if #actions == 0 then
        JBNotify('~r~Aucune action disponible pour ton métier.')
        return
    end
    OpenUI({ action = 'open', kind = 'menu', data = { type = jc.type, jobLabel = jc.label, grade = jc.gradeLabel or '', actions = actions } })
end

RegisterCommand(Config.JobMenuCommand, function() if not uiOpen then openJobMenu() elseif walkMenu then CloseUI() end end, false)
RegisterKeyMapping(Config.JobMenuCommand, 'Menu métier', 'keyboard', Config.JobMenuKey)

RegisterNetEvent('jobbuilder:client:openBuilder', function()
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
    return GetEntityModel(PlayerPedId()) == joaat("mp_f_freemode_01") and 'f' or 'm'
end

local function spawnVehicle(res)
    local c = res.spawn
    ESX.Game.SpawnVehicle(res.model, vector3(c.x, c.y, c.z), c.h, function(veh)
        SetVehicleNumberPlateText(veh, res.plate)
        SetVehicleFuelLevel(veh, 100.0)
        if res.color then SetVehicleColours(veh, res.color, res.color) end
        if res.job then       -- marque le véhicule comme véhicule de service du job (CorePickax : anti-conduite des véhicules police par les civils)
            pcall(function()
                local st = Entity(veh).state
                st:set('jobbuilderVehicle', true, true)
                st:set('jobbuilderJob', res.job, true)
                st:set('jobbuilderAllowedGrades', res.grades or {}, true)
            end)
        end
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        Config.OnVehicleSpawned(veh, res.plate)
    end)
end

-- Type de véhicule d'après sa classe GTA : 8/13 moto-vélo, 14 bateau, 15/16 aéronef, le reste voiture
local function vehicleKind(veh)
    local c = GetVehicleClass(veh)
    if c == 8 or c == 13 then return 'bike' elseif c == 14 then return 'boat' elseif c == 15 or c == 16 then return 'aircraft' end
    return 'car'
end

returnVehicle = function(point)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then return JBNotify('~r~Tu dois être au volant du véhicule à ranger.') end
    local want = point.kind or 'car'
    if vehicleKind(veh) ~= want then
        return JBNotify(('~r~Ce point ne range que : %s'):format((Config.GarageKinds[want] or Config.GarageKinds.car).label:lower()))
    end
    ESX.TriggerServerCallback('jobbuilder:garage:return', function(res)
        if res and res.ok then
            ESX.Game.DeleteVehicle(veh)
            JBNotify('~g~Véhicule rangé.')
        else
            JBNotify('~r~' .. ((res and res.error) or 'Impossible de ranger ce véhicule'))
        end
    end, point.id, GetVehicleNumberPlateText(veh))
end

local function findPoint(id)
    for _, p in ipairs(State.points) do if p.id == id then return p end end
end

-- ─────────────────────────────── RPC NUI -> client/serveur ───────────────────────────────
-- Callbacks serveur autorisés (nom JS -> 'jobbuilder:<nom>')
NuiRemote = {
    list = true, get = true, catalog = true, save = true, delete = true, setMyJob = true, leaveJob = true,
    ['cloak:wear'] = true, ['armory:take'] = true, ['shop:buy'] = true,
    ['boss:money'] = true, ['boss:recruit'] = true, ['boss:setGrade'] = true, ['boss:fire'] = true, ['boss:salary'] = true,
    openPoint = true,
    ['boss:poll'] = true, ['gov:balance'] = true,
    ['settings:get'] = true, ['settings:save'] = true, ['settings:reset'] = true,
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
        ESX.TriggerServerCallback('jobbuilder:isDev', function(ok)
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
    Config.GetClothes(function(skin)
        local out = {}
        for _, k in ipairs(Config.ClothesKeys) do
            if skin and skin[k] ~= nil then out[k] = skin[k] end
        end
        cb({ sex = pedSex(), clothes = out })
    end)
end

NuiLocal.cloakCivil = function(_, cb)
    Config.RestoreCivil()
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
    ESX.TriggerServerCallback('jobbuilder:garage:spawn', function(res)
        if res and res.ok then
            CloseUI()
            spawnVehicle(res)
        end
        cb(res or { ok = false, error = 'Erreur' })
    end, args[1], args[2])
end

NuiLocal.openJobMenu = function(_, cb)
    CloseUI()
    cb({ ok = true })
    openJobMenu()
end

NuiLocal.doAction = function(args, cb)
    CloseUI()
    menuOrigin = GetGameTimer()
    RunAction(args[1], args[2], args[3])
    cb({ ok = true })
end

NuiLocal.invoiceAnswer = function(args, cb)
    TriggerServerEvent('jobbuilder:server:invoiceAnswer', args[1], args[2] == true)
    CloseUI()
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
                DrawJBMarker(d, { x = c.x, y = c.y, z = c.z })
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

RegisterNUICallback('rpc', function(body, cb)
    local name, args = body.name, body.args or {}
    if NuiLocal[name] then
        return NuiLocal[name](args, cb)
    end
    if NuiRemote[name] then
        -- Les actions qui ciblent un joueur voisin reçoivent son ID ici (jamais fourni par le NUI)
        if name == 'boss:recruit' or name == 'prop:offer' or name == 'prop:giveKey' or name == 'dealer:offer' or name == 'serve:offer' or name == 'records:fromNearest' or name == 'fine:send' or name == 'tuning:validate' or name == 'patients:fromNearest' or name == 'care:send' or name == 'bank:nearest' or name == 'bank:offerLoan' or name == 'bank:op' or name == 'bank:fee' then args[2] = GetNearestPlayerId() or -1 end
        if name == 'gov:prime' then args[1] = GetNearestPlayerId() end
        if name == 'cloak:wear' or name == 'prop:wardrobe:wear' then
            return ESX.TriggerServerCallback('jobbuilder:' .. name, function(res)
                if res and res.ok then Config.ApplyClothes(res.clothes) end
                cb(res or { ok = false })
            end, table.unpack(args))
        end
        return ESX.TriggerServerCallback('jobbuilder:' .. name, function(res) cb(res or { ok = false, error = 'Aucune réponse' }) end, table.unpack(args))
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

function GetJobConfig() return State.jobConfig end
exports('GetJobType', function() return State.jobConfig and State.jobConfig.type or nil end)
