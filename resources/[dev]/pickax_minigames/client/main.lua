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
        if l and d.blip and d.blip.enabled then
            local b = AddBlipForCoord(l.x, l.y, l.z)
            SetBlipSprite(b, d.blip.sprite or 357)
            SetBlipColour(b, d.blip.color or 3)
            SetBlipScale(b, 0.8)
            SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(d.name)
            EndTextCommandSetBlipName(b)
            blips[id] = b
        end
    end
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end
    Wait(1500)
    TriggerServerEvent('minigames:requestSync')
end)

-- ─── Markers de lobby ─────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        local wait = 800
        if not MGC.session and not uiMode then
            local ped = PlayerPedId()
            local p = GetEntityCoords(ped)
            for id, d in pairs(MGC.defs) do
                local l = d.points and d.points.lobby
                if l then
                    local dist = #(p - vector3(l.x, l.y, l.z))
                    if dist < Config.DrawDistance then
                        wait = 0
                        DrawMarker(1, l.x, l.y, l.z - 0.95, 0, 0, 0, 0, 0, 0, 1.4, 1.4, 0.5, ACC[1], ACC[2], ACC[3], 90, false, false, 2, false, nil, nil, false)
                        DrawMarker(21, l.x, l.y, l.z + 0.2, 0, 0, 0, 0, 0, 0, 0.35, 0.35, 0.35, 255, 255, 255, 160, true, true, 2, false, nil, nil, false)
                        if dist < Config.InteractDistance then
                            BeginTextCommandDisplayHelp('STRING')
                            AddTextComponentSubstringPlayerName(('~INPUT_CONTEXT~ Jouer : ~b~%s'):format(d.name))
                            EndTextCommandDisplayHelp(0, false, true, -1)
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
end)
