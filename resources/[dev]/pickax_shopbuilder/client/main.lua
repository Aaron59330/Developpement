ESX = exports['es_extended']:getSharedObject()

local State = { shops = {}, config = {} }
local uiOpen, placing = false, false
local current = nil      -- boutique actuellement ouverte { id, locIdx, restrict }
local blipHandles, peds, targetZones = {}, {}, {}

-- ─────────────────────────────── NUI ───────────────────────────────
function IsUIOpen() return uiOpen end

local function openUI(payload)
    if IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true then return end   -- mort : aucun menu
    payload.theme = Config.UI and Config.UI.Accent
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage(payload)
end

function CloseUI()
    placing = false
    if EndCabin then EndCabin(true) end      -- cabine ouverte : tenue d'origine restaurée
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    TriggerServerEvent('shopbuilder:server:requestSync')
end

-- Mort : un menu déjà ouvert se ferme
CreateThread(function()
    while true do
        Wait(250)
        if uiOpen and (IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true) then CloseUI() end
    end
end)

-- ─────────────────────────────── Blips ───────────────────────────────
local function rebuildBlips()
    for _, b in ipairs(blipHandles) do if DoesBlipExist(b) then RemoveBlip(b) end end
    blipHandles = {}
    for _, shop in ipairs(State.shops) do
        local b = shop.blip
        if b and b.enabled then
            for _, loc in ipairs(shop.locations or {}) do
                pcall(function()
                    blipHandles[#blipHandles + 1] = BB.Blip(loc.coords, b, { label = shop.label, category = shop.type })
                end)
            end
        end
    end
end

-- ─────────────────────────────── Vendeurs (PNJ) ───────────────────────────────
local function deletePed(key)
    local p = peds[key]
    if p and DoesEntityExist(p) then DeleteEntity(p) end
    peds[key] = nil
end

local function clearPeds() for key in pairs(peds) do deletePed(key) end end

local function spawnPed(key, shop, loc)
    local def = shop.ped
    local hash = joaat(def.model)
    if not IsModelInCdimage(hash) then return end
    RequestModel(hash)
    local t = GetGameTimer() + 3000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
    if not HasModelLoaded(hash) then return end
    local c = loc.ped or loc.coords      -- vendeur placé à part si une position dédiée existe
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
        for _, shop in ipairs(State.shops) do
            if shop.ped and shop.ped.enabled and shop.ped.model ~= '' then
                for i, loc in ipairs(shop.locations or {}) do
                    local key = shop.id .. ':' .. i
                    local c = loc.ped or loc.coords
                    if #(pos - vector3(c.x, c.y, c.z)) < dist then
                        want[key] = true
                        if not peds[key] or not DoesEntityExist(peds[key]) then spawnPed(key, shop, loc) end
                    end
                end
            end
        end
        for key in pairs(peds) do if not want[key] then deletePed(key) end end
        Wait(1500)
    end
end)

-- ─────────────────────────────── Ouverture d'une boutique ───────────────────────────────
local opening = false

local function doOpenShop(shop, locIdx)
    if opening or uiOpen then return end
    opening = true
    SetTimeout(1500, function() opening = false end)
    ESX.TriggerServerCallback('shopbuilder:open', function(res)
        opening = false
        if uiOpen then return end
        if not res or not res.ok then
            ESX.ShowNotification('~r~' .. ((res and res.error) or 'Erreur'), nil, nil, 'shop')
            return
        end
        current = { id = shop.id, locIdx = locIdx, restrict = res.restrict }
        openUI({ action = 'open', kind = 'shop', data = res })
    end, shop.id, locIdx)
end

-- Dialogue du PNJ (pickax_dialog) avant l'ouverture : le vendeur écrit un message, Accepter ouvre la boutique
local asking = false
local function openShop(shop, locIdx)
    if asking or opening or uiOpen then return end
    local d, D = shop.ped, Config.Dialog
    if D and D.Enabled ~= false and d and d.enabled and d.model ~= '' and not (d.dialog and d.dialog.enabled == false) and GetResourceState('pickax_dialog') == 'started' then
        asking = true
        CreateThread(function()
            local text = d.dialog and d.dialog.text and d.dialog.text ~= '' and d.dialog.text or D.Texts[shop.type] or D.Texts.default
            local ok, res = pcall(function()
                return exports.pickax_dialog:Ask({ ped = peds[shop.id .. ':' .. locIdx], name = shop.label, text = text, scenario = d.scenario })
            end)
            asking = false
            if not ok or res == true then doOpenShop(shop, locIdx) end
        end)
        return
    end
    doOpenShop(shop, locIdx)
end

-- ─────────────────────────────── ox_target (optionnel) ───────────────────────────────
local function rebuildTargets()
    if Config.Target ~= 'ox_target' or GetResourceState('ox_target') ~= 'started' then return end
    for _, id in ipairs(targetZones) do pcall(function() exports.ox_target:removeZone(id) end) end
    targetZones = {}
    for _, shop in ipairs(State.shops) do
        for i, loc in ipairs(shop.locations or {}) do
            local c = loc.coords
            local ok, id = pcall(function()
                return exports.ox_target:addSphereZone({
                    coords = vec3(c.x, c.y, c.z), radius = 1.6, debug = false,
                    options = {{ name = ('shopbuilder_%d_%d'):format(shop.id, i), icon = 'fa-solid fa-store', label = shop.label, distance = 2.0,
                        onSelect = function() openShop(shop, i) end }},
                })
            end)
            if ok and id then targetZones[#targetZones + 1] = id end
        end
    end
end

-- ─────────────────────────────── Sync serveur ───────────────────────────────
RegisterNetEvent('shopbuilder:client:sync', function(data)
    State.shops = data.shops or {}
    State.config = data.config or {}
    if data.accent then
        Config.UI.Accent = data.accent
        SendNUIMessage({ action = 'theme', accent = data.accent })
    end
    if Config.Marker and State.config.marker then Config.Marker = State.config.marker end
    clearPeds()
    rebuildBlips()
    rebuildTargets()
end)

CreateThread(function()
    Wait(2000)
    TriggerServerEvent('shopbuilder:server:requestSync')
end)

RegisterNetEvent('esx:setJob', function()
    SetTimeout(800, function() TriggerServerEvent('shopbuilder:server:requestSync') end)
end)

RegisterNetEvent('shopbuilder:client:openBuilder', function()
    if uiOpen then return end
    openUI({ action = 'open', kind = 'builder' })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if EndCabin then EndCabin(true) end
    clearPeds()
    for _, b in ipairs(blipHandles) do if DoesBlipExist(b) then RemoveBlip(b) end end
    for _, id in ipairs(targetZones) do pcall(function() exports.ox_target:removeZone(id) end) end
    if uiOpen then SetNuiFocus(false, false) end
end)

-- /sbreset : débloque l'UI si elle est restée « ouverte »
RegisterCommand('sbreset', function()
    uiOpen, placing = false, false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    TriggerServerEvent('shopbuilder:server:requestSync')
end, false)

-- ─────────────────────────────── Markers & interaction ───────────────────────────────
local function drawMarker(c, shop)
    -- couches : marker commun (Config.Marker) → marker de la boutique ; couleur : propre à la boutique
    BB.DrawMarker(BB.Style(Config.Marker, shop.marker), c, shop.color)
end

CreateThread(function()
    while true do
        local sleep = 1000
        if not uiOpen and #State.shops > 0 then
            local pos = GetEntityCoords(PlayerPedId())
            local drawDist = State.config.drawDistance or Config.DrawDistance
            local useDist = State.config.interactDistance or Config.InteractDistance
            local nearShop, nearIdx
            for _, shop in ipairs(State.shops) do
                for i, loc in ipairs(shop.locations or {}) do
                    local c = loc.coords
                    local dist = #(pos - vector3(c.x, c.y, c.z))
                    if dist < drawDist then
                        sleep = 0
                        if not shop.marker or shop.marker.enabled ~= false then drawMarker(c, shop) end
                        if dist < useDist then nearShop, nearIdx = shop, i end
                    end
                end
            end
            if nearShop then
                local label = nearShop.locations[nearIdx].label
                local name = (label and label ~= '') and ('%s — %s'):format(nearShop.label, label) or nearShop.label
                BB.ShowHelp(('Appuie sur ~INPUT_CONTEXT~ : %s'):format(name), Config.Marker, nearShop.marker)
                if IsControlJustReleased(0, Config.InteractKey or 38) then openShop(nearShop, nearIdx) end
            end
        end
        Wait(sleep)
    end
end)

-- ─────────────────────────────── RPC NUI -> client/serveur ───────────────────────────────
-- Callbacks serveur autorisés (nom JS -> 'shopbuilder:<nom>')
local NuiRemote = {
    dlogsGet = true, dlogsSave = true, dlogsTest = true,
    catalog = true, list = true, get = true, create = true, save = true, delete = true, duplicate = true, toggle = true,
    restock = true, resetStats = true, logs = true, buy = true, ['settings:save'] = true, importSuperettes = true,
}

local NuiLocal = {}

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
        ESX.TriggerServerCallback('shopbuilder:isAdmin', function(ok)
            if ok then SetEntityCoords(PlayerPedId(), c.x + 0.0, c.y + 0.0, c.z + 0.0, false, false, false, false) end
            cb({ ok = ok })
        end)
    else cb({ ok = false }) end
end

NuiLocal.checkPed = function(args, cb)
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

-- Cabine d'essayage : le panneau se ferme, le menu de vêtements s'ouvre ; le paiement est prélevé à la validation
NuiLocal['clothing:start'] = function(args, cb)
    local cur, method = current, args[1]
    if not cur or not cur.restrict then return cb({ ok = false, error = 'Boutique introuvable' }) end
    if Config.GetSkinSystem() == 'skinchanger' then
        return StartCabin(cur, method, cb)          -- cabine intégrée : le panneau reste ouvert
    end
    cb({ ok = true })
    CloseUI()
    CreateThread(function()
        Wait(300)          -- laisse le focus NUI se libérer avant d'ouvrir le menu externe
        StartClothing(cur, method)
    end)
end

NuiLocal['cabin:change'] = function(args, cb) CabinChange(args[1], args[2], cb) end
NuiLocal['cabin:rotate'] = function(args, cb) CabinRotate(tonumber(args[1]) or 1) cb({ ok = true }) end
NuiLocal['cabin:cam'] = function(args, cb) CabinCamera(tostring(args[1])) cb({ ok = true }) end
NuiLocal['cabin:confirm'] = function(_, cb) CabinConfirm(cb) end

RegisterNUICallback('rpc', function(body, cb)
    local name, args = body.name, body.args or {}
    if NuiLocal[name] then return NuiLocal[name](args, cb) end
    if NuiRemote[name] then
        return ESX.TriggerServerCallback('shopbuilder:' .. name, function(res) cb(res or { ok = false, error = 'Aucune réponse' }) end, table.unpack(args))
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
