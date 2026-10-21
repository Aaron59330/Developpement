ESX = exports['es_extended']:getSharedObject()

MGC = { defs = {}, session = nil, joined = nil }
local uiMode = nil            -- nil | 'builder' | 'lobby'
local blips = {}

local ACC = (PickaxTheme and PickaxTheme.rgb) or { 0, 164, 255 }

-- ─── Interface (builder + lobby) ──────────────────────────────────────────────
local function openUI(mode, data)
    if IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true then return end
    uiMode = mode
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', mode = mode, data = data })
end

function CloseUI()
    if not uiMode then return end
    uiMode = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

CreateThread(function()
    while true do
        Wait(250)
        if uiMode and (IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true) then CloseUI() end
    end
end)

RegisterCommand(Config.Command, function()
    if uiMode then return CloseUI() end
    ESX.TriggerServerCallback('minigames:isAdmin', function(ok)
        if ok then openUI('builder') else ESX.ShowNotification('~r~Accès refusé : réservé à l\'équipe.') end
    end)
end, false)
if Config.OpenKey then RegisterKeyMapping(Config.Command, 'Ouvrir le Mini-jeux Builder', 'keyboard', Config.OpenKey) end

RegisterCommand(Config.ProfileCommand, function()
    if uiMode then return CloseUI() end
    openUI('lobby', { profileOnly = true })
end, false)
if Config.ProfileKey then RegisterKeyMapping(Config.ProfileCommand, 'Profil mini-jeux (niveau, défis, succès)', 'keyboard', Config.ProfileKey) end

RegisterCommand('minigames_leave', function()
    if MGC.joined or MGC.session then TriggerServerEvent('minigames:quit') end
end, false)
RegisterKeyMapping('minigames_leave', 'Quitter le mini-jeu en cours', 'keyboard', Config.LeaveKey)

-- ─── Appels NUI ───────────────────────────────────────────────────────────────
local NuiRemote = {
    catalog = true, list = true, get = true, draft = true, save = true, delete = true, duplicate = true, toggle = true,
    resetStats = true, logs = true, stats = true,
    lobby = true, join = true, leave = true,
    profile = true, progGet = true, progSave = true, seasonEnd = true, progReset = true,
}
local NuiLocal = {}

NuiLocal.close = function(_, cb) CloseUI() cb({}) end

NuiLocal.getCoords = function(_, cb)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    cb({ x = c.x, y = c.y, z = c.z - 1.0, h = GetEntityHeading(ped) })
end

-- Point visé par la caméra (utile pour placer un panier, une zone de but, un checkpoint à distance)
NuiLocal.aimCoords = function(_, cb)
    local from = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local dir = vector3(-math.sin(rz) * math.abs(math.cos(rx)), math.cos(rz) * math.abs(math.cos(rx)), math.sin(rx))
    local to = from + dir * 80.0
    local h = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, 1 + 16, PlayerPedId(), 0)
    local _, hit, pos = GetShapeTestResult(h)
    if hit == 1 then cb({ ok = true, x = pos.x, y = pos.y, z = pos.z, h = GetEntityHeading(PlayerPedId()) }) else cb({ ok = false }) end
end

NuiLocal.teleport = function(args, cb)
    local c = args[1]
    if type(c) == 'table' and c.x then
        ESX.TriggerServerCallback('minigames:isAdmin', function(ok)
            if ok then SetEntityCoords(PlayerPedId(), c.x + 0.0, c.y + 0.0, c.z + 0.0, false, false, false, false) end
            cb({ ok = ok })
        end)
    else cb({ ok = false }) end
end

NuiLocal.bbHub = function(_, cb)
    cb({ ok = true })
    CloseUI()
    SetTimeout(250, function() ExecuteCommand('builders') end)
end

RegisterNUICallback('rpc', function(body, cb)
    local name, args = body.name, body.args or {}
    if NuiLocal[name] then return NuiLocal[name](args, cb) end
    if NuiRemote[name] then
        return ESX.TriggerServerCallback('minigames:' .. name, function(res)
            if name == 'join' and res and res.ok then MGC.joined = args[1] end
            if name == 'leave' then MGC.joined = nil end
            cb(res or { ok = false, error = 'Aucune réponse' })
        end, table.unpack(args))
    end
    cb({ ok = false, error = 'Appel inconnu' })
end)

-- ─── Définitions / blips ──────────────────────────────────────────────────────
RegisterNetEvent('minigames:sync', function(defs)
    MGC.defs = defs or {}
    for _, b in pairs(blips) do RemoveBlip(b) end
    blips = {}
    for id, d in pairs(MGC.defs) do
        local l = d.points and d.points.lobby
        if l and d.blip and d.blip.enabled ~= false then
            blips[id] = BB.Blip(l, d.blip, { label = d.name, category = 'default' })
        end
    end
    MGC.refreshProps()
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end
    Wait(1500)
    TriggerServerEvent('minigames:requestSync')
end)

-- ─── Markers de lobby (même rendu et même aide « E » que les autres builders) ─────────────────
CreateThread(function()
    while true do
        local wait = 800
        if not MGC.session and not uiMode then
            local ped = PlayerPedId()
            local p = GetEntityCoords(ped)
            for id, d in pairs(MGC.defs) do
                local l = d.points and d.points.lobby
                if l and (not d.marker or d.marker.enabled ~= false) then
                    local dist = #(p - vector3(l.x, l.y, l.z))
                    if dist < Config.DrawDistance then
                        wait = 0
                        BB.DrawMarker(d.marker, l)
                        if dist < Config.InteractDistance then
                            BB.ShowHelp(('Appuie sur ~INPUT_CONTEXT~ pour jouer : ~b~%s'):format(d.name), d.marker)
                            if IsControlJustPressed(0, 38) then
                                ESX.TriggerServerCallback('minigames:lobby', function(res)
                                    if res and res.ok then openUI('lobby', res)
                                    else ESX.ShowNotification('~r~' .. ((res and res.error) or 'Indisponible')) end
                                end, id)
                            end
                        end
                    end
                end
            end
        end
        Wait(wait)
    end
end)

-- ─── Props (décor / obstacles placés dans le builder) ─────────────────────────
-- « always » : apparaissent à proximité du lobby ; « match » : seulement pendant la partie (voir games.lua)
local always = {}   -- [id] = { objs }

local function makeProp(p)
    local hash = GetHashKey(p.model)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local t = GetGameTimer() + 3000
    while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
    if not HasModelLoaded(hash) then return nil end
    local o = CreateObjectNoOffset(hash, p.x + 0.0, p.y + 0.0, p.z + 0.0, false, false, false)
    SetEntityRotation(o, (p.rx or 0.0) + 0.0, (p.ry or 0.0) + 0.0, (p.h or 0.0) + 0.0, 2, true)
    FreezeEntityPosition(o, p.freeze ~= false)
    SetEntityCollision(o, p.collision ~= false, p.collision ~= false)
    SetModelAsNoLongerNeeded(hash)
    return o
end
MGC.makeProp = makeProp

-- Props décidés par le jeu lui-même (ex : panier de basket posé au point « Panier »)
local function derivedProps(def)
    local out = {}
    local s, h = def.settings, def.points and def.points.hoop
    if s and h and h.x and s.hoopSpawn and s.hoopModel and s.hoopModel ~= '' then
        out[#out + 1] = { model = s.hoopModel, x = h.x, y = h.y, z = h.z + (s.hoopOffsetZ or 0.0), h = (h.h or 0.0) + (s.hoopYaw or 0.0), rx = 0.0, ry = 0.0, freeze = true, collision = true, mode = 'always' }
    end
    return out
end

function MGC.spawnProps(def, mode)
    local list = {}
    local all = {}
    for _, p in ipairs(def.props or {}) do all[#all + 1] = p end
    for _, p in ipairs(derivedProps(def)) do all[#all + 1] = p end
    for _, p in ipairs(all) do
        if (p.mode or 'match') == mode then
            local o = makeProp(p)
            if o then list[#list + 1] = o end
        end
    end
    return list
end

function MGC.deleteProps(list)
    for _, o in ipairs(list or {}) do
        if DoesEntityExist(o) then SetEntityAsMissionEntity(o, true, true) DeleteEntity(o) end
    end
end

function MGC.refreshProps()
    for id, e in pairs(always) do MGC.deleteProps(e.objs) always[id] = nil end
end

CreateThread(function()
    while true do
        Wait(2000)
        local p = GetEntityCoords(PlayerPedId())
        for id, d in pairs(MGC.defs) do
            local l = d.points and d.points.lobby
            if l then
                local dist = #(p - vector3(l.x, l.y, l.z))
                local e = always[id]
                if dist < Config.PropStream and not e then
                    always[id] = { objs = MGC.spawnProps(d, 'always') }
                elseif dist > Config.PropStream + 60.0 and e then
                    MGC.deleteProps(e.objs) always[id] = nil
                end
            end
        end
    end
end)

-- Test d'un modèle (bouton « Tester » du builder) : apparaît 3 m devant toi pendant 8 s
local previewObj
NuiLocal.checkModel = function(args, cb)
    local hash = GetHashKey(tostring(args[1] or ''))
    cb({ valid = IsModelInCdimage(hash) and IsModelValid(hash) })
end
NuiLocal.previewProp = function(args, cb)
    local model = tostring(args[1] or '')
    local hash = GetHashKey(model)
    if model == '' or not IsModelInCdimage(hash) then return cb({ ok = false }) end
    cb({ ok = true })
    CreateThread(function()
        if previewObj and DoesEntityExist(previewObj) then DeleteEntity(previewObj) end
        local ped = PlayerPedId()
        local c = GetOffsetFromEntityInWorldCoords(ped, 0.0, 3.0, 0.0)
        local isVeh = IsModelAVehicle(hash)
        RequestModel(hash)
        local t = GetGameTimer() + 4000
        while not HasModelLoaded(hash) and GetGameTimer() < t do Wait(10) end
        if not HasModelLoaded(hash) then return end
        if isVeh then previewObj = CreateVehicle(hash, c.x, c.y, c.z, GetEntityHeading(ped), false, false)
        else previewObj = CreateObjectNoOffset(hash, c.x, c.y, c.z - 0.9, false, false, false) end
        SetEntityAlpha(previewObj, 190, false)
        FreezeEntityPosition(previewObj, true)
        SetEntityCollision(previewObj, false, false)
        local untilT = GetGameTimer() + 8000
        local o = previewObj
        while GetGameTimer() < untilT and DoesEntityExist(o) do Wait(0) end
        if DoesEntityExist(o) then DeleteEntity(o) end
    end)
end

NuiLocal.bbPreview = function(args, cb)
    cb({ ok = true })
    if type(args[1]) == 'table' then BB.Preview(args[1], 8) end
end

-- Mode placement : le menu se réduit en HUD, le joueur se déplace librement (Entrée = enregistrer, ← → = cible, Retour = menu)
local placing = false
NuiLocal.placement = function(args, cb)
    if args[1] and not placing then
        placing = true
        SetNuiFocus(false, false)
        CreateThread(function()
            while placing do
                if IsControlJustReleased(0, 201) then
                    local ped = PlayerPedId()
                    local c = GetEntityCoords(ped)
                    SendNUIMessage({ action = 'placementSave', coords = { x = c.x, y = c.y, z = c.z - 1.0, h = GetEntityHeading(ped) } })
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

-- Éclaboussures de peinture (paintball)
MGC.splats = {}
RegisterNetEvent('minigames:splat', function(x, y, z, r, g, b)
    local list = MGC.splats
    list[#list + 1] = { x = x, y = y, z = z, r = r, g = g, b = b, t = GetGameTimer() }
    while #list > Config.Splat.max do table.remove(list, 1) end
end)

-- ─── Événements serveur → NUI / moteurs ──────────────────────────────────────
RegisterNetEvent('minigames:lobbyState', function(info)
    MGC.joined = info.id
    SendNUIMessage({ action = 'lobbyState', data = info })
end)
RegisterNetEvent('minigames:hud', function(h) SendNUIMessage({ action = 'hud', data = h }) if MGC.onHud then MGC.onHud(h) end end)
RegisterNetEvent('minigames:scored', function(pts) SendNUIMessage({ action = 'scored', pts = pts }) end)
RegisterNetEvent('minigames:begin', function(d) if uiMode == 'lobby' then CloseUI() end MGC.begin(d) end)
RegisterNetEvent('minigames:go', function(d) MGC.go(d) end)
RegisterNetEvent('minigames:down', function(d) MGC.down(d) end)
RegisterNetEvent('minigames:respawn', function(sp) MGC.respawn(sp) end)
RegisterNetEvent('minigames:hurt', function(d) MGC.hurt(d) end)
RegisterNetEvent('minigames:round', function(d) SendNUIMessage({ action = 'round', data = d }) end)
RegisterNetEvent('minigames:end', function(d) MGC.finish(d) end)
RegisterNetEvent('minigames:kick', function(reason, silent)
    MGC.joined = nil
    if uiMode == 'lobby' then CloseUI() end
    SendNUIMessage({ action = 'kicked', text = reason })
    if MGC.session then MGC.cleanup(true) end
    if reason and not silent then ESX.ShowNotification(reason) end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if MGC.session then MGC.cleanup(true) end
    if uiMode then SetNuiFocus(false, false) end
    for _, b in pairs(blips) do RemoveBlip(b) end
    MGC.refreshProps()
end)
