ESX = exports['es_extended']:getSharedObject()

State = { entities = {}, config = {} }
Handlers = {}          -- Handlers[type](node) : appelé quand le joueur interagit avec un point (modules garage.lua, drugs.lua...)
NodeFilter = {}        -- NodeFilter[type](node) → bool : visibilité d'un point (braquages : seulement pendant l'action)
NuiLocal, NuiRemote = {}, {}
Busy = false           -- action chronométrée en cours

local uiOpen, placing = false, false
local blipHandles, peds, targetZones, Nodes = {}, {}, {}, {}
Ctx = nil              -- contexte du panneau ouvert { type, eid, pi, ... }

-- ─────────────────────────────── Utilitaires ───────────────────────────────
-- Logo selon le module ouvert (garage, fourrière, drogue, braquage…) ; sinon logo « monde »
local WB_ICON = { garage = 'garage', impound = 'impound', rental = 'dealer', carlot = 'dealer', fuel = 'fuel', carwash = 'carwash', locksmith = 'mecano', jobcenter = 'world',
    bank = 'bank', driving = 'school', drug = 'drug', robbery = 'robbery', doorlock = 'world', pvp = 'gang', chase = 'police' }
local LastType = nil   -- dernier module utilisé (logo des notifications hors panneau)
function Notify(msg, kind)
    local t = (Ctx and Ctx.type) or LastType
    local icon = WB_ICON[t] or 'world'
    -- ESX.ShowNotification (es_extended) ne transmet pas l'icône : appel direct à pickax_notify (repli : ESX)
    if GetResourceState('pickax_notify') == 'started' then
        local ok = pcall(function() exports['pickax_notify']:ShowNotification(msg, kind or 'info', nil, icon) end)
        if ok then return end
    end
    ESX.ShowNotification(msg, kind or 'info', nil, icon)
end

RegisterNetEvent('worldbuilder:client:notify', function(msg, kind) Notify(msg, kind) end)

function LoadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
    return HasModelLoaded(hash) and hash or nil
end

function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local t = GetGameTimer() + 3000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < t do Wait(10) end
    return HasAnimDictLoaded(dict)
end

function EntityById(id)
    for _, e in ipairs(State.entities) do if e.id == id then return e end end
end

function PointOf(eid, pi)
    local e = EntityById(eid)
    if not e then return nil end
    for _, p in ipairs(e.points) do if p.i == pi then return p, e end end
end

function Teleport(c)
    local ped = PlayerPedId()
    DoScreenFadeOut(400)
    while not IsScreenFadedOut() do Wait(10) end
    SetEntityCoords(ped, c.x + 0.0, c.y + 0.0, c.z + 0.0, false, false, false, false)
    if c.h then SetEntityHeading(ped, c.h + 0.0) end
    Wait(300)
    DoScreenFadeIn(400)
end

-- Appel serveur avec délai : prévient le joueur si le serveur ne répond pas (callback absent / erreur serveur)
function ServerCall(name, cb, ...)
    local answered = false
    SetTimeout(6000, function()
        if not answered then Notify(('Le serveur ne répond pas à « %s » : vérifie la console serveur (erreur ?) et redémarre worldbuilder.'):format(name), 'error') end
    end)
    ESX.TriggerServerCallback(name, function(...) answered = true cb(...) end, ...)
end

-- ─────────────────────────────── NUI ───────────────────────────────
function IsUIOpen() return uiOpen end

function OpenPanel(kind, data, ctx)
    if uiOpen then return end
    if IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true then return end   -- mort : aucun menu
    Ctx = ctx
    if type(data) == 'table' and kind ~= 'builder' then data.imagePath, data.currency = Config.ImagePath, Config.Currency end
    uiOpen = true
    SetNuiFocus(true, true)
    -- Couleur des menus : celle du module (si définie) sinon la couleur globale
    local mod = ctx and ctx.eid and EntityById(ctx.eid)
    SendNUIMessage({ action = 'open', kind = kind, data = data, theme = Config.UI and Config.UI.Accent, moduleTheme = mod and mod.uiColor or nil })
end

function CloseUI()
    placing = false
    if not uiOpen then return end
    if OnPanelClose then OnPanelClose(Ctx) end
    uiOpen = false
    Ctx = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    TriggerServerEvent('worldbuilder:server:requestSync')
end

-- Mort : un menu déjà ouvert se ferme
CreateThread(function()
    while true do
        Wait(250)
        if uiOpen and (IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true) then CloseUI() end
    end
end)

-- ─────────────────────────────── Barre de progression + animation ───────────────────────────────
local function animOf(id)
    for _, a in ipairs(Config.Animations) do if a.id == id then return a end end
end

local function startAnim(id)
    local a = animOf(id)
    local ped = PlayerPedId()
    if not a or id == 'none' then return end
    if a.scenario then
        TaskStartScenarioInPlace(ped, a.scenario, 0, true)
    elseif a.dict and LoadAnimDict(a.dict) then
        TaskPlayAnim(ped, a.dict, a.clip, 3.0, -3.0, -1, 1, 0.0, false, false, false)
    end
end

local function minigame()
    if Config.Minigame == 'none' then return true end
    if GetResourceState('ox_lib') ~= 'started' then return true end
    local ok, res = pcall(function() return exports.ox_lib:skillCheck(Config.MinigameDifficulty, { 'w', 'a', 's', 'd' }) end)
    if not ok then return true end
    return res == true
end

-- o = { seconds, label, anim, minigame, radius } → true si terminé sans interruption
function RunAction(o)
    if Busy then return false end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then Notify('Descends du véhicule d\'abord.', 'error') return false end
    Busy = true
    local seconds = math.max(0.5, tonumber(o.seconds) or 3)
    local origin = GetEntityCoords(ped)
    local radius = o.radius or 3.0
    startAnim(o.anim)
    SendNUIMessage({ action = 'progress', label = o.label or '', ms = math.floor(seconds * 1000), hint = ('Appuie sur X pour annuler') })
    local finish, ok = GetGameTimer() + math.floor(seconds * 1000), true
    while GetGameTimer() < finish do
        ped = PlayerPedId()
        DisablePlayerFiring(PlayerId(), true)
        DisableControlAction(0, 24, true) DisableControlAction(0, 25, true) DisableControlAction(0, 23, true) DisableControlAction(0, 75, true)
        if IsControlJustPressed(0, Config.CancelKey or 73) or IsEntityDead(ped) or IsPedRagdoll(ped)
            or #(GetEntityCoords(ped) - origin) > radius then ok = false break end
        Wait(0)
    end
    SendNUIMessage({ action = 'progressEnd' })
    ClearPedTasks(PlayerPedId())
    if ok and o.minigame then ok = minigame() end
    Busy = false
    if not ok then TriggerServerEvent('worldbuilder:server:cancelAct') end
    return ok
end

-- ─────────────────────────────── Alerte police ───────────────────────────────
RegisterNetEvent('worldbuilder:client:alert', function(coords, title, message)
    Notify(('~r~[ALERTE]~s~ %s'):format(message or title or 'Activité suspecte'), 'error')
    if not coords then return end
    local blip = AddBlipForCoord(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    SetBlipSprite(blip, 161) SetBlipColour(blip, 1) SetBlipScale(blip, 0.5) SetBlipAsShortRange(blip, false) SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(tostring(title or 'Alerte'))
    EndTextCommandSetBlipName(blip)
    SetTimeout(120000, function() if DoesBlipExist(blip) then RemoveBlip(blip) end end)
end)

-- ─────────────────────────────── Blips ───────────────────────────────
local function rebuildBlips()
    for _, b in ipairs(blipHandles) do if DoesBlipExist(b) then RemoveBlip(b) end end
    blipHandles = {}
    for _, e in ipairs(State.entities) do
        local b = e.blip
        if b and b.enabled then
            for _, p in ipairs(e.points) do
                if p.blip then
                    pcall(function()
                        blipHandles[#blipHandles + 1] = BB.Blip(p.coords, b, { label = e.label, category = e.type })
                    end)
                end
            end
        end
    end
end

-- ─────────────────────────────── PNJ ───────────────────────────────
local function deletePed(key)
    local p = peds[key]
    if p and DoesEntityExist(p) then DeleteEntity(p) end
    peds[key] = nil
end

local function clearPeds() for key in pairs(peds) do deletePed(key) end end

function WBPed(eid, pi)
    local p = peds[eid .. ':' .. pi]
    if p and DoesEntityExist(p) then return p end
end

local function spawnPed(key, def, c)
    local hash = LoadModel(def.model)
    if not hash then return end
    local ped = CreatePed(4, hash, c.x + 0.0, c.y + 0.0, c.z - 1.0, (c.h or 0.0) + 0.0, false, false)
    SetModelAsNoLongerNeeded(hash)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCanRagdoll(ped, false)
    if def.scenario and def.scenario ~= '' then TaskStartScenarioInPlace(ped, def.scenario, 0, true) end
    peds[key] = ped
end

CreateThread(function()
    while true do
        local pos = GetEntityCoords(PlayerPedId())
        local want = {}
        local dist = State.config.pedDistance or Config.PedDistance
        for _, e in ipairs(State.entities) do
            for _, p in ipairs(e.points) do
                local d = p.ped
                if d and d.enabled and d.model ~= '' then
                    local key = e.id .. ':' .. p.i
                    local c = d.pos or p.coords
                    if #(pos - vector3(c.x, c.y, c.z)) < dist then
                        want[key] = true
                        if not peds[key] or not DoesEntityExist(peds[key]) then spawnPed(key, d, c) end
                    end
                end
            end
        end
        for key in pairs(peds) do if not want[key] then deletePed(key) end end
        Wait(1500)
    end
end)

-- ─────────────────────────────── Points d'interaction (nodes) ───────────────────────────────
local KIND_TEXT = {
    garage = { main = 'Ouvrir le garage', store = 'Ranger le véhicule' },
    impound = { main = 'Ouvrir la fourrière' },
    rental = { main = 'Louer un véhicule', ['return'] = 'Rendre le véhicule loué' },
    fuel = { pump = 'Faire le plein' },
    pvp = { lobby = 'Ouvrir les zones PVP' },
    chase = { lobby = 'Ouvrir la course poursuite' },
    carlot = { lot = 'Ouvrir les annonces', slot = 'Voir l\'annonce' },
    doorlock = { lock = 'Verrouiller / déverrouiller la porte' },
    locksmith = { shop = 'Parler au serrurier' },
    jobcenter = { desk = 'Parler au conseiller Pôle emploi' },
    carwash = { wash = 'Laver le véhicule' },
    driving = { desk = 'Ouvrir l\'auto-école' },
    bank = { counter = 'Accéder au guichet', atm = 'Utiliser le distributeur' },
    drug = { harvest = 'Récolter', process = 'Utiliser le poste de travail', sell = 'Parler au dealer', launder = 'Blanchir de l\'argent', door = 'Entrer', exit = 'Sortir' },
    robbery = { start = 'Commencer le braquage', register = 'Vider la caisse', safe = 'Forcer le coffre', vault = 'Percer le coffre-fort', loot = 'Ramasser le butin' },
}
local EXIT_COLOR = { 255, 140, 60 }

local function addNode(e, p, kind, c, color)
    local text = KIND_TEXT[e.type] and KIND_TEXT[e.type][kind]
    if not text then return end
    if e.type == 'doorlock' and Config.Doors and Config.Doors.Key and (Config.Doors.Marker == false or p.showMarker == false) then return end
    Nodes[#Nodes + 1] = { eid = e.id, type = e.type, pi = p.i, kind = kind, c = vector3(c.x, c.y, c.z), text = text, label = p.label, entity = e, color = color }
end

local function buildNodes()
    Nodes = {}
    for _, e in ipairs(State.entities) do
        for _, p in ipairs(e.points) do
            local kind = p.kind or 'main'
            local c2 = p.color2 or EXIT_COLOR
            addNode(e, p, kind, p.coords, p.color)
            if e.type == 'garage' and p.store then addNode(e, p, 'store', p.store, c2) end
            if e.type == 'rental' and p.ret then addNode(e, p, 'return', p.ret, c2) end
            if e.type == 'drug' and kind == 'door' and p.inside then addNode(e, p, 'exit', p.inside, c2) end
        end
    end
end

local function visible(n)
    local f = NodeFilter[n.type]
    return not f or f(n)
end

-- Dialogue du PNJ (pickax_dialog) avant d'ouvrir le service : renvoie true si on peut continuer
local Asking = false
local DIALOG_SKIP = { store = true, ['return'] = true, exit = true }
local function askDialog(n)
    local D = Config.Dialog
    if not D or D.Enabled == false or DIALOG_SKIP[n.kind] or GetResourceState('pickax_dialog') ~= 'started' then return true end
    local pt
    for _, p in ipairs(n.entity.points) do if p.i == n.pi then pt = p break end end
    local d = pt and pt.ped
    if not (d and d.enabled and d.model ~= '') then return true end
    local dl = d.dialog or {}
    if dl.enabled == false or (dl.enabled == nil and D.Default == false) then return true end
    local text = (dl.text and dl.text ~= '') and dl.text or D.Texts[n.type .. '.' .. n.kind] or D.Texts.default
    local ok, res = pcall(function()
        return exports.pickax_dialog:Ask({ ped = WBPed(n.eid, n.pi), name = (pt.label and pt.label ~= '') and pt.label or n.entity.label, text = text, scenario = d.scenario })
    end)
    return not ok or res == true      -- en cas d'erreur du dialogue, on ouvre quand même le service
end

local function interact(n)
    if Busy or uiOpen or Asking then return end
    Asking = true
    CreateThread(function()
        local go = askDialog(n)
        Asking = false
        if go and not Busy and not uiOpen then RunInteract(n) end
    end)
end

function RunInteract(n)
    LastType = n.type
    local h = Handlers[n.type]
    if not h then return Notify(('Module « %s » non géré par le client (fichiers à jour ? refresh + restart pickax_worldbuilder)'):format(n.type), 'error') end
    local ok, err = pcall(h, n)
    if not ok then
        print(('^1[worldbuilder] erreur d\'interaction (%s/%s) : %s^0'):format(n.type, n.kind, tostring(err)))
        Notify('Erreur : ' .. tostring(err), 'error')
    end
end

local function rebuildTargets()
    for _, id in ipairs(targetZones) do pcall(function() exports.ox_target:removeZone(id) end) end
    targetZones = {}
    if Config.Target ~= 'ox_target' or GetResourceState('ox_target') ~= 'started' then return end
    for i, n in ipairs(Nodes) do
        local ok, id = pcall(function()
            return exports.ox_target:addSphereZone({
                coords = n.c, radius = 1.6, debug = false,
                options = {{ name = ('worldbuilder_%d_%d_%s_%d'):format(n.eid, n.pi, n.kind, i), icon = 'fa-solid fa-circle-dot', label = n.text, distance = 2.0,
                    canInteract = function() return not Busy and not uiOpen and visible(n) end, onSelect = function() interact(n) end }},
            })
        end)
        if ok and id then targetZones[#targetZones + 1] = id end
    end
end
function RebuildTargets() rebuildTargets() end

-- ─────────────────────────────── Sync serveur ───────────────────────────────
RegisterNetEvent('worldbuilder:client:sync', function(data)
    State.entities = data.entities or {}
    State.config = data.config or {}
    if data.accent then
        Config.UI.Accent = data.accent
        SendNUIMessage({ action = 'theme', accent = data.accent })
    end
    if State.config.marker then Config.Marker = State.config.marker end
    clearPeds()
    buildNodes()
    rebuildBlips()
    rebuildTargets()
    if OnSynced then OnSynced() end
end)

CreateThread(function()
    Wait(2000)
    TriggerServerEvent('worldbuilder:server:requestSync')
end)

RegisterNetEvent('esx:setJob', function()
    SetTimeout(800, function() TriggerServerEvent('worldbuilder:server:requestSync') end)
end)

RegisterNetEvent('worldbuilder:client:openBuilder', function()
    if uiOpen then return end
    OpenPanel('builder', nil, { type = 'builder' })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    clearPeds()
    for _, b in ipairs(blipHandles) do if DoesBlipExist(b) then RemoveBlip(b) end end
    for _, id in ipairs(targetZones) do pcall(function() exports.ox_target:removeZone(id) end) end
    if uiOpen then SetNuiFocus(false, false) end
    if OnStop then OnStop() end
end)

-- Touche d'ouverture du builder (optionnelle) : exécute la commande, droits revérifiés côté serveur
if Config.OpenKey then
    RegisterKeyMapping(Config.Command, 'Ouvrir le World Builder', 'keyboard', Config.OpenKey)
end

-- /wbreset : débloque l'interface si elle reste « ouverte »
RegisterCommand('wbreset', function()
    uiOpen, placing, Busy = false, false, false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    SendNUIMessage({ action = 'progressEnd' })
    TriggerServerEvent('worldbuilder:server:requestSync')
end, false)

-- ─────────────────────────────── Markers & interaction ───────────────────────────────
local function drawMarker(n, e)
    -- couches : marker commun (Config.Marker) → marker du module ; couleur : point → module (marker puis couleur générale)
    local mk = e.marker or {}
    BB.DrawMarker(BB.Style(Config.Marker, mk), n.c, n.color or mk.color or e.color)
end

CreateThread(function()
    while true do
        local sleep = 1000
        if not uiOpen and not Busy and #Nodes > 0 then
            local pos = GetEntityCoords(PlayerPedId())
            local drawDist = State.config.drawDistance or Config.DrawDistance
            local useDist = State.config.interactDistance or Config.InteractDistance
            local near, nearDist
            for _, n in ipairs(Nodes) do
                local dist = #(pos - n.c)
                if dist < drawDist and visible(n) then
                    sleep = 0
                    local mk = n.entity.marker
                    if not mk or mk.enabled ~= false then drawMarker(n, n.entity) end
                    if dist < useDist and (not nearDist or dist < nearDist) then near, nearDist = n, dist end
                end
            end
            if near and Config.Target ~= 'ox_target' then
                local label = (near.label and near.label ~= '' and near.kind ~= 'store' and near.kind ~= 'return' and near.kind ~= 'exit') and (' — ' .. near.label) or ''
                -- pas de répétition : « Ouvrir le garage — Garage » devient « Ouvrir le garage »
                if label ~= '' and near.text and near.text:lower():find(near.label:lower(), 1, true) then label = '' end
                BB.ShowHelp(('Appuie sur ~INPUT_CONTEXT~ : %s%s'):format(near.text, label), Config.Marker, near.entity.marker)
                if IsControlJustReleased(0, Config.InteractKey or 38) then interact(near) end
            end
        end
        Wait(sleep)
    end
end)

-- ─────────────────────────────── RPC NUI -> client/serveur ───────────────────────────────
-- Callbacks serveur autorisés (nom JS -> 'worldbuilder:<nom>')
for _, n in ipairs({ 'catalog', 'list', 'get', 'create', 'save', 'delete', 'duplicate', 'toggle', 'resetStats', 'logs', 'settings:save',
    'drug:processInfo', 'drug:sellInfo', 'drug:sell', 'drug:launderInfo', 'drug:launder', 'fuel:info', 'fuel:jerrycan', 'locksmith:make', 'jobcenter:info', 'jobcenter:take', 'jobcenter:leave', 'driving:theoryStart', 'driving:theorySubmit', 'bank:deposit', 'bank:withdraw', 'bank:transfer' }) do NuiRemote[n] = true end

NuiLocal.close = function(_, cb) CloseUI() cb({}) end

-- Aperçu du marker (éditeur commun BBMap) : affiché devant le joueur pendant 8 secondes
NuiLocal.previewMarker = function(args, cb)
    if type(args[1]) == 'table' then BB.Preview(BB.Style(Config.Marker, args[1]), 8) end
    cb({ ok = true })
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
        ESX.TriggerServerCallback('worldbuilder:isAdmin', function(ok)
            if ok then SetEntityCoords(PlayerPedId(), c.x + 0.0, c.y + 0.0, c.z + 0.0, false, false, false, false) end
            cb({ ok = ok })
        end)
    else cb({ ok = false }) end
end

NuiLocal.checkModel = function(args, cb)
    local hash = joaat(tostring(args[1] or ''))
    cb({ valid = IsModelInCdimage(hash) and IsModelValid(hash) })
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
    if NuiLocal[name] then return NuiLocal[name](args, cb) end
    if NuiRemote[name] then
        return ESX.TriggerServerCallback('worldbuilder:' .. name, function(res) cb(res or { ok = false, error = 'Aucune réponse' }) end, table.unpack(args))
    end
    cb({ ok = false, error = 'Appel inconnu' })
end)

-- Sécurité : si le joueur meurt, on ferme l'UI
CreateThread(function()
    while true do
        Wait(500)
        if uiOpen and IsEntityDead(PlayerPedId()) then CloseUI() end
    end
end)
