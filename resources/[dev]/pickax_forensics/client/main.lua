local ESX = exports['es_extended']:getSharedObject()
local Ev = {}          -- ["casing:12"] = { id, kind, x, y, z } : repères visibles (police uniquement)
local Plates = {}      -- [plate] = nombre d'empreintes relevables sur ce véhicule
local isPolice = false

local policeJobs = {}
for _, j in ipairs(Config.PoliceJobs) do policeJobs[j] = true end

local function refreshJob()
    local d = ESX.GetPlayerData()
    local was = isPolice
    isPolice = d and d.job and policeJobs[d.job.name] == true or false
    if isPolice ~= was or isPolice then TriggerServerEvent('pickax_forensics:requestSync') end
    if not isPolice then Ev, Plates = {}, {} end
end

RegisterNetEvent('esx:playerLoaded', function() Wait(1500) refreshJob() end)
RegisterNetEvent('esx:setJob', function() Wait(300) refreshJob() end)
CreateThread(function() Wait(3000) refreshJob() end)

local function key(e) return (e.kind or 'casing') .. ':' .. e.id end
RegisterNetEvent('pickax_forensics:sync', function(list)
    Ev, Plates = {}, {}
    for _, e in ipairs(list or {}) do
        if e.kind == 'plate' then Plates[e.plate] = e.n else Ev[key(e)] = e end
    end
end)
RegisterNetEvent('pickax_forensics:add', function(e) Ev[key(e)] = e end)
RegisterNetEvent('pickax_forensics:remove', function(id, kind) Ev[(kind or 'casing') .. ':' .. id] = nil end)
RegisterNetEvent('pickax_forensics:plate', function(plate, n) Plates[plate] = (n and n > 0) and n or nil end)

local function notify(kind, txt) lib.notify({ type = kind, description = txt }) end
local function help(txt) PickaxTheme.Help(txt) end
local function plateOf(veh) return (GetVehicleNumberPlateText(veh) or ''):gsub('^%s+', ''):gsub('%s+$', '') end

-- ───────────── Événements locaux : tir, blessure, montée dans un véhicule (le serveur valide tout) ─────────────
CreateThread(function()
    local last = 0
    while true do
        Wait(0)
        if IsPedShooting(PlayerPedId()) then
            local now = GetGameTimer()
            if now - last > Config.Casings.MinInterval then last = now TriggerServerEvent('pickax_forensics:shot') end
        else Wait(60) end
    end
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    if args[1] == PlayerPedId() then TriggerServerEvent('pickax_forensics:bleed') end
end)

CreateThread(function()
    local seen = 0
    while true do
        Wait(400)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsTryingToEnter(ped)
        if veh == 0 and IsPedInAnyVehicle(ped, false) then veh = GetVehiclePedIsIn(ped, false) end
        if veh ~= 0 and veh ~= seen and NetworkGetEntityIsNetworked(veh) then
            seen = veh
            TriggerServerEvent('pickax_forensics:vehicle', NetworkGetNetworkIdFromEntity(veh))
        elseif veh == 0 then seen = 0 end
    end
end)

-- ───────────── NUI : laboratoire et mini-jeux ─────────────
local nuiOpen, mgPromise = false, nil

local function nui(msg) SendNUIMessage(msg) end
local function closeNui()
    if not nuiOpen then return end
    nuiOpen = false
    SetNuiFocus(false, false)
    nui({ action = 'close' })
end

-- Lance un mini-jeu et attend le score (0-100) ; nil si annulé
local function minigame(game, cfg)
    if nuiOpen then return nil end
    nuiOpen = true
    SetNuiFocus(true, true)
    mgPromise = promise.new()
    nui({ action = 'mg', game = game, cfg = cfg or {} })
    local score = Citizen.Await(mgPromise)
    mgPromise = nil
    nuiOpen = false
    SetNuiFocus(false, false)
    nui({ action = 'close' })
    return score
end

RegisterNUICallback('mgDone', function(d, cb) if mgPromise then mgPromise:resolve(tonumber(d.score)) end cb(1) end)
RegisterNUICallback('close', function(_, cb) closeNui() if mgPromise then mgPromise:resolve(nil) end cb(1) end)

local function street(x, y)
    local s = GetStreetNameFromHashKey((GetStreetNameAtCoord((x or 0.0) + 0.0, (y or 0.0) + 0.0, 0.0)))
    return s ~= '' and s or 'lieu inconnu'
end
local function addStreets(rep)
    for _, m in ipairs(rep.matches or {}) do m.street = street(m.x, m.y) end
    return rep
end

-- Laboratoire
local function openLab()
    ESX.TriggerServerCallback('pickax_forensics:labOpen', function(r)
        if not r or not r.ok then return notify('error', (r and r.error) or 'Indisponible') end
        nuiOpen = true
        SetNuiFocus(true, true)
        nui({ action = 'lab', items = r.items, lab = r.lab })
    end)
end

RegisterNUICallback('labList', function(_, cb)
    ESX.TriggerServerCallback('pickax_forensics:labOpen', function(r) cb(r or { ok = false }) end)
end)
RegisterNUICallback('labBegin', function(d, cb)
    ESX.TriggerServerCallback('pickax_forensics:labBegin', function(r) cb(r or { ok = false, error = 'Erreur' }) end, d.slot)
end)
RegisterNUICallback('labEnd', function(d, cb)
    ESX.TriggerServerCallback('pickax_forensics:labEnd', function(r)
        if r and r.ok and r.report then addStreets(r.report) end
        cb(r or { ok = false, error = 'Erreur' })
    end, d.score)
end)
RegisterNUICallback('search', function(d, cb)
    ESX.TriggerServerCallback('pickax_forensics:lookup', function(r)
        if r and r.ok then for _, x in ipairs(r.rows or {}) do x.street = street(x.x, x.y) end end
        cb(r or { ok = false })
    end, d.q or '')
end)

-- ───────────── Repères sur la scène + relevés (police) ─────────────
local COLORS = { casing = { 253, 194, 125 }, blood = { 220, 60, 60 } }
local busy = false

local function collectCasing(e)
    local ok = lib.progressBar({ duration = Config.Casings.PickupSeconds * 1000, label = 'Ramassage de la douille…', canCancel = true, disable = { move = true, combat = true }, anim = { dict = 'pickup_object', clip = 'pickup_low' } })
    if not ok then return end
    ESX.TriggerServerCallback('pickax_forensics:collect', function(r)
        if r and r.ok then notify('success', ('Douille #%d placée sous scellé.'):format(r.id)) else notify('error', (r and r.error) or 'Impossible') end
    end, e.id)
end

local function collectBlood(e)
    ESX.TriggerServerCallback('pickax_forensics:traceBegin', function(b)
        if not b or not b.ok then return notify('error', (b and b.error) or 'Impossible') end
        local ok = lib.progressBar({ duration = b.seconds * 1000, label = 'Prélèvement de sang…', canCancel = true, disable = { move = true, combat = true }, anim = { dict = 'amb@medic@standing@tendtodead@idle_a', clip = 'idle_a', flag = 1 } })
        if not ok then return end
        ESX.TriggerServerCallback('pickax_forensics:traceEnd', function(r) if r and r.ok then notify('success', r.msg) else notify('error', (r and r.error) or 'Impossible') end end, 100)
    end, 'blood', e.id)
end

local function dustVehicle(veh)
    local plate = plateOf(veh)
    ESX.TriggerServerCallback('pickax_forensics:traceBegin', function(b)
        if not b or not b.ok then return notify('error', (b and b.error) or 'Impossible') end
        local score = minigame('dust', { seed = b.seed, seconds = b.seconds })
        if not score then return end
        ESX.TriggerServerCallback('pickax_forensics:traceEnd', function(r)
            if r and r.ok then notify(r.failed and 'error' or 'success', r.msg) else notify('error', (r and r.error) or 'Impossible') end
        end, score)
    end, 'print', plate, NetworkGetNetworkIdFromEntity(veh))
end

CreateThread(function()
    while true do
        local sleep = 800
        if isPolice and not busy and not nuiOpen then
            local ped = PlayerPedId()
            local pc = GetEntityCoords(ped)
            local nearest, nd
            for _, e in pairs(Ev) do
                local d = #(pc - vector3(e.x, e.y, e.z))
                if d < Config.Casings.DrawDistance then
                    sleep = 0
                    local c = COLORS[e.kind] or COLORS.casing
                    DrawMarker(0, e.x, e.y, e.z + 0.35, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.12, 0.12, 0.12, c[1], c[2], c[3], 190, true, false, 2, false, nil, nil, false)
                    if not nd or d < nd then nearest, nd = e, d end
                end
            end
            local veh
            if next(Plates) and not IsPedInAnyVehicle(ped, false) then
                local v = GetClosestVehicle(pc.x, pc.y, pc.z, Config.Prints.DustDistance, 0, 71)
                if v ~= 0 and Plates[plateOf(v)] then veh = v sleep = 0 end
            end
            if nearest and nd <= Config.Casings.PickupDistance and not IsPedInAnyVehicle(ped, false) then
                help(nearest.kind == 'blood' and 'Appuie sur ~INPUT_CONTEXT~ pour prélever le sang' or 'Appuie sur ~INPUT_CONTEXT~ pour ramasser la douille')
                if IsControlJustPressed(0, 38) then
                    busy = true
                    if nearest.kind == 'blood' then collectBlood(nearest) else collectCasing(nearest) end
                    busy = false
                end
            elseif veh then
                help('Appuie sur ~INPUT_CONTEXT~ pour relever les empreintes du véhicule')
                if IsControlJustPressed(0, 38) then busy = true dustVehicle(veh) busy = false end
            end
        end
        Wait(sleep)
    end
end)

-- ───────────── Laboratoire : repère + blip ─────────────
local blips = {}
CreateThread(function()
    for _, l in ipairs(Config.Labs) do
        if l.blip then
            local b = AddBlipForCoord(l.coords.x, l.coords.y, l.coords.z)
            SetBlipSprite(b, 403) SetBlipColour(b, 3) SetBlipScale(b, 0.6) SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(l.label) EndTextCommandSetBlipName(b)
            blips[#blips + 1] = b
        end
    end
end)
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, b in ipairs(blips) do RemoveBlip(b) end
    if nuiOpen then SetNuiFocus(false, false) end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if isPolice and not busy and not nuiOpen then
            local pc = GetEntityCoords(PlayerPedId())
            for _, l in ipairs(Config.Labs) do
                local d = #(pc - l.coords)
                if d < Config.Analysis.DrawDistance then
                    sleep = 0
                    PickaxTheme.Marker(l.coords.x, l.coords.y, l.coords.z)
                    if d <= Config.Analysis.InteractDistance then
                        help('Appuie sur ~INPUT_CONTEXT~ : ouvrir le laboratoire')
                        if IsControlJustPressed(0, 38) then openLab() Wait(500) end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Fichier balistique : onglet « Balistique » de la tablette de police, laboratoire, ou /balistique si Config.UseCommands
local function openFile(q)
    if not isPolice then return notify('error', 'Réservé à la police.') end
    if nuiOpen then return end
    nuiOpen = true
    SetNuiFocus(true, true)
    nui({ action = 'file', q = q or '' })
end
if Config.UseCommands then RegisterCommand(Config.Analysis.Command, function(_, args) openFile(args[1]) end, false) end
exports('OpenFile', openFile)

-- ───────────── Prélèvement d'un suspect + test GSR ─────────────
local function nearestPlayer(maxDist)
    local me, best, bd = PlayerPedId(), nil, maxDist
    local mc = GetEntityCoords(me)
    for _, p in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(p)
        if ped ~= me then
            local d = #(mc - GetEntityCoords(ped))
            if d < bd then best, bd = GetPlayerServerId(p), d end
        end
    end
    return best
end

local function onTarget(cmd, seconds, label, cbName, dist)
    local function run(forced, args)
        if not isPolice then return notify('error', 'Réservé à la police.') end
        local target = forced or tonumber(args and args[1]) or nearestPlayer(dist)
        if not target then return notify('error', 'Personne à proximité.') end
        local ok = lib.progressBar({ duration = seconds * 1000, label = label, canCancel = true, disable = { move = true, combat = true }, anim = { dict = 'amb@medic@standing@kneel@base', clip = 'base', flag = 1 } })
        if not ok then return end
        ESX.TriggerServerCallback(cbName, function(r)
            if r and r.ok then notify(r.positive and 'warning' or 'success', r.msg) else notify('error', (r and r.error) or 'Impossible') end
        end, target)
    end
    if Config.UseCommands then RegisterCommand(cmd, function(_, args) run(nil, args) end, false) end
    return run
end
local doSample = onTarget(Config.Profile.Command, Config.Profile.Seconds, 'Prélèvement ADN et empreintes…', 'pickax_forensics:sample', Config.Profile.Distance)
local doGsr = onTarget(Config.Gsr.Command, Config.Gsr.Seconds, 'Test de résidus de tir…', 'pickax_forensics:gsr', Config.Gsr.Distance)

-- ───────────── Objets : kit de nettoyage et lingettes ─────────────
RegisterNetEvent('pickax_forensics:useCleaning', function()
    if nuiOpen or busy then return end
    local ped = PlayerPedId()
    local pc = GetEntityCoords(ped)
    local v = GetClosestVehicle(pc.x, pc.y, pc.z, 6.0, 0, 71)
    local score = minigame('scrub', { seconds = 22 })
    if not score or score < 80 then return notify('error', 'Nettoyage interrompu.') end
    ESX.TriggerServerCallback('pickax_forensics:clean', function(r)
        if r and r.ok then notify('success', r.msg) else notify('error', (r and r.error) or 'Impossible') end
    end, v ~= 0 and NetworkGetEntityIsNetworked(v) and NetworkGetNetworkIdFromEntity(v) or 0)
end)

RegisterNetEvent('pickax_forensics:useWipes', function()
    if busy then return end
    local ok = lib.progressBar({ duration = 4000, label = 'Nettoyage des mains…', canCancel = true, disable = { move = true, combat = true }, anim = { dict = 'mp_arresting', clip = 'a_uncuff' } })
    if ok then TriggerServerEvent('pickax_forensics:wipe') end
end)

-- ───────────── Menu contextuel : clic droit sur un joueur (police) ─────────────
local CTX_ACTIONS = {
    { id = 'sample', label = 'Prélèvement ADN', target = 'player' },
    { id = 'gsr',    label = 'Test de résidus', target = 'player' },
}
exports('ContextCan', function(id, ent) return isPolice and ent ~= PlayerPedId() end)
exports('ContextDo', function(id, ent)
    local sid = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ent))
    if not sid or sid <= 0 then return end
    if id == 'sample' then doSample(sid) elseif id == 'gsr' then doGsr(sid) end
end)
local function registerContext() exports.pickax_core:RegisterContextActions(GetCurrentResourceName(), CTX_ACTIONS) end
CreateThread(function() Wait(2500) registerContext() end)
AddEventHandler('onResourceStart', function(r) if r == 'pickax_core' then SetTimeout(2500, registerContext) end end)
