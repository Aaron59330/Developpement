-- ─────────────────────────────── CarPlay : client ───────────────────────────────
-- Lit le state bag `carplay` des véhicules proches, calcule le volume de chacun (distance, portes / toit ouverts) et le donne au moteur audio
-- de l'interface (html/engine.js). Gère aussi l'ouverture de l'autoradio (menu contextuel du véhicule, commande, export).
local ESX = exports['es_extended']:getSharedObject()

local active = {}            -- [netId] = état carplay des véhicules connus
local uiOpen, uiNet, uiVeh = false, nil, nil
local inputMode = false
local library = { favorites = {}, history = {} }
local canSearch = false
local lastSig, lastToastRev = '', {}
local KVP = 'carplay_personal'

-- Réglages du joueur (volume perso, bandeau de titre) — enregistrés sur son PC
local personal = { vol = 100, toast = Config.TrackToast ~= false }
do
    local raw = GetResourceKvpString(KVP)
    if raw and raw ~= '' then
        local ok, t = pcall(json.decode, raw)
        if ok and type(t) == 'table' then
            personal.vol = math.max(0, math.min(100, tonumber(t.vol) or 100))
            if t.toast ~= nil then personal.toast = t.toast == true end
        end
    end
end
local function savePersonal() SetResourceKvp(KVP, json.encode(personal)) end

local function notify(msg) ESX.ShowNotification(msg) end
local function cloud() return GetCloudTimeAsInt() end

-- ─────────────────────────────── Véhicules & états ───────────────────────────────
AddStateBagChangeHandler('carplay', nil, function(bagName, _, value)
    local netId = tonumber(bagName:match('^entity:(%d+)$'))
    if not netId then return end
    active[netId] = type(value) == 'table' and value or nil
    if uiOpen and uiNet == netId then
        SendNUIMessage({ t = 'state', st = value, now = cloud() })
    end
end)

CreateThread(function()   -- véhicules déjà présents au démarrage de la ressource
    Wait(1500)
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if NetworkGetEntityIsNetworked(veh) then
            local st = Entity(veh).state.carplay
            if type(st) == 'table' then active[NetworkGetNetworkIdFromEntity(veh)] = st end
        end
    end
end)

local function openCabin(veh)
    if IsVehicleAConvertible(veh, false) and GetConvertibleRoofState(veh) ~= 0 then return true end
    for i = 0, 5 do
        if DoesVehicleHaveDoor(veh, i) and GetVehicleDoorAngleRatio(veh, i) > 0.05 then return true end
    end
    return false
end

local function currentTrack(st) return st and st.queue and st.queue[st.index] or nil end

-- Occupant « référent » : le premier siège occupé par un joueur (envoie les durées / erreurs de lecture)
local function isReferent(veh)
    local ped = PlayerPedId()
    for seat = -1, GetVehicleModelNumberOfSeats(GetEntityModel(veh)) - 2 do
        local p = GetPedInVehicleSeat(veh, seat)
        if p ~= 0 and IsPedAPlayer(p) then return p == ped end
    end
    return false
end

-- ─────────────────────────────── Moteur audio (messages vers l'interface) ───────────────────────────────
CreateThread(function()
    while true do
        Wait(250)
        local ped = PlayerPedId()
        local pc = GetEntityCoords(ped)
        local myVeh = GetVehiclePedIsIn(ped, false)
        local list = {}
        for netId, st in pairs(active) do
            local t = currentTrack(st)
            if st.on and t and NetworkDoesNetworkIdExist(netId) then
                local ent = NetworkGetEntityFromNetworkId(netId)
                if ent ~= 0 and DoesEntityExist(ent) then
                    local d = #(pc - GetEntityCoords(ent))
                    local vol
                    if ent == myVeh then vol = 1.0
                    elseif st.speakers == false or d > Config.MaxHearDistance then vol = 0.0
                    else
                        local f = 1.0 - d / Config.MaxHearDistance
                        vol = f * f
                        if not openCabin(ent) then vol = vol * Config.OutsideMuffle end
                    end
                    vol = vol * ((st.volume or 0) / 100) * (personal.vol / 100)
                    if vol > 0.004 then list[#list + 1] = { netId = netId, d = d, vol = vol, st = st, t = t, mine = ent == myVeh } end
                end
            end
        end
        table.sort(list, function(a, b) return a.d < b.d end)
        local out, sig = {}, {}
        for i = 1, math.min(#list, Config.MaxChannels) do
            local c = list[i]
            local v = math.floor(c.vol * 50 + 0.5) / 50      -- pas de 2 % : évite d'inonder l'interface
            out[i] = { id = c.netId, kind = c.t.kind, ref = c.t.ref, rev = c.st.rev, playing = c.st.playing, startedAt = c.st.startedAt, pausedAt = c.st.pausedAt, vol = v, mine = c.mine }
            sig[i] = ('%d:%d:%s:%d:%d:%.2f'):format(c.netId, c.st.rev, tostring(c.st.playing), c.st.startedAt, c.st.pausedAt, v)
        end
        local s = table.concat(sig, '|')
        if s ~= lastSig then
            lastSig = s
            SendNUIMessage({ t = 'engine', now = cloud(), ch = out })
        end
        -- bandeau « en cours de lecture » (mon véhicule, à chaque nouveau titre)
        if personal.toast and myVeh ~= 0 and NetworkGetEntityIsNetworked(myVeh) then
            local netId = NetworkGetNetworkIdFromEntity(myVeh)
            local st = active[netId]
            local t = currentTrack(st)
            if st and st.on and st.playing and t and lastToastRev[netId] ~= st.rev then
                lastToastRev[netId] = st.rev
                SetTimeout(1500, function() SendNUIMessage({ t = 'toast', track = t }) end)
            end
        end
    end
end)

-- ─────────────────────────────── Interface ───────────────────────────────
local function myVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return nil end
    if not NetworkGetEntityIsNetworked(veh) then return nil end
    return veh
end

local function canControl(veh)
    if Config.ControlSeats == 'driver' then return GetPedInVehicleSeat(veh, -1) == PlayerPedId() end
    return true
end

local function modelLabel(veh)
    local n = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
    local l = GetLabelText(n)
    return (l and l ~= 'NULL') and l or n
end

local function closeUI()
    if not uiOpen then return end
    uiOpen, uiNet, uiVeh, inputMode = false, nil, nil, false
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    SendNUIMessage({ t = 'close' })
end

local function doOpen()
    local veh = myVehicle()
    if not veh then return notify('~r~Monte dans un véhicule (réseau) pour utiliser CarPlay.') end
    uiOpen, uiVeh, uiNet = true, veh, NetworkGetNetworkIdFromEntity(veh)
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)          -- on peut continuer à conduire avec le clavier
    SendNUIMessage({
        t = 'open', netId = uiNet, now = cloud(), st = active[uiNet], lib = library, canSearch = canSearch, canControl = canControl(veh),
        presets = Config.Presets, personal = personal, maxQueue = Config.QueueMax,
        veh = { plate = GetVehicleNumberPlateText(veh), label = modelLabel(veh) },
    })
    ESX.TriggerServerCallback('carplay:library', function(lib) library = lib or library SendNUIMessage({ t = 'lib', lib = library }) end)
    ESX.TriggerServerCallback('carplay:canSearch', function(ok) canSearch = ok == true SendNUIMessage({ t = 'caps', canSearch = canSearch }) end)
    CreateThread(function()
        while uiOpen do
            Wait(0)
            -- la souris sert à l'interface : pas de caméra, pas de tir (la conduite au clavier reste possible)
            for _, c in ipairs({ 1, 2, 3, 4, 5, 6, 24, 25, 106, 140, 141, 142, 257, 263, 264, 270, 271, 272, 273 }) do DisableControlAction(0, c, true) end
        end
    end)
end

function OpenCarPlay()
    -- état « ouvert » resté coincé (interface fermée sans nous prévenir) : on repart de zéro
    if uiOpen and not IsNuiFocused() then uiOpen, uiNet, uiVeh, inputMode = false, nil, nil, false end
    if uiOpen then return end
    if IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true then return notify('~r~Impossible pour le moment.') end
    local ok, err = pcall(doOpen)
    if not ok then
        uiOpen, uiNet, uiVeh = false, nil, nil
        SetNuiFocusKeepInput(false)
        SetNuiFocus(false, false)
        print(('^1[carplay] erreur à l\'ouverture : %s^0'):format(tostring(err)))
        notify('~r~CarPlay : erreur à l\'ouverture (voir la console F8).')
    end
end
exports('OpenCarPlay', OpenCarPlay)
RegisterNetEvent('carplay:client:open', function() OpenCarPlay() end)

if Config.Command and Config.Command ~= '' then
    RegisterCommand(Config.Command, function() if uiOpen then closeUI() else OpenCarPlay() end end, false)
    if Config.OpenKey and Config.OpenKey ~= '' then RegisterKeyMapping(Config.Command, 'Ouvrir CarPlay', 'keyboard', Config.OpenKey) end
end

RegisterNetEvent('carplay:client:library', function(lib)
    library = lib or library
    if uiOpen then SendNUIMessage({ t = 'lib', lib = library }) end
end)

-- fermeture automatique : le joueur quitte le véhicule, meurt, ou le véhicule disparaît
CreateThread(function()
    while true do
        Wait(500)
        if uiOpen then
            if not uiVeh or not DoesEntityExist(uiVeh) or GetVehiclePedIsIn(PlayerPedId(), false) ~= uiVeh or IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true then closeUI() end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and uiOpen then SetNuiFocusKeepInput(false) SetNuiFocus(false, false) end
end)

-- ─────────────────────────────── Callbacks de l'interface ───────────────────────────────
RegisterNUICallback('close', function(_, cb) closeUI() cb({}) end)

RegisterNUICallback('cmd', function(d, cb)
    if uiOpen and uiNet and type(d) == 'table' and type(d.action) == 'string' then
        TriggerServerEvent('carplay:server:cmd', uiNet, d.action, d.a, d.b)
    end
    cb({})
end)

RegisterNUICallback('fav', function(d, cb)
    if type(d) == 'table' and (d.op == 'add' or d.op == 'remove') then
        TriggerServerEvent('carplay:server:fav', d.op, d.kind, d.ref, d.title, d.author, d.thumb)
    end
    cb({})
end)

RegisterNUICallback('search', function(d, cb)
    ESX.TriggerServerCallback('carplay:search', function(res) cb(res or { ok = false, error = 'Aucune réponse' }) end, type(d) == 'table' and d.q or '')
end)

-- saisie de texte : le clavier ne doit plus piloter la voiture
RegisterNUICallback('inputFocus', function(d, cb)
    inputMode = type(d) == 'table' and d.on == true
    if uiOpen then SetNuiFocusKeepInput(not inputMode) end
    cb({})
end)

RegisterNUICallback('personal', function(d, cb)
    if type(d) == 'table' then
        if d.vol ~= nil then personal.vol = math.max(0, math.min(100, math.floor(tonumber(d.vol) or 100))) end
        if d.toast ~= nil then personal.toast = d.toast == true end
        savePersonal()
        lastSig = ''      -- force le recalcul des volumes
    end
    cb({})
end)

-- Rapports du lecteur : durée du titre / erreur de lecture (seul l'occupant « référent » les transmet)
RegisterNUICallback('meta', function(d, cb)
    cb({})
    if type(d) ~= 'table' then return end
    local netId = tonumber(d.id)
    local veh = myVehicle()
    if veh and netId == NetworkGetNetworkIdFromEntity(veh) and isReferent(veh) then TriggerServerEvent('carplay:server:meta', netId, d.rev, d.dur) end
end)

RegisterNUICallback('error', function(d, cb)
    cb({})
    if type(d) ~= 'table' then return end
    local netId = tonumber(d.id)
    local veh = myVehicle()
    if veh and netId == NetworkGetNetworkIdFromEntity(veh) and isReferent(veh) then TriggerServerEvent('carplay:server:error', netId, d.rev, d.code) end
end)

-- Diagnostic : /carplaydebug (console F8)
RegisterCommand('carplaydebug', function()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    local n = 0
    for _ in pairs(active) do n = n + 1 end
    print(('[carplay] module client chargé · véhicule=%s · réseau=%s · interface ouverte=%s · focus NUI=%s · véhicules avec musique=%d'):format(
        tostring(veh), tostring(veh ~= 0 and NetworkGetEntityIsNetworked(veh)), tostring(uiOpen), tostring(IsNuiFocused()), n))
    SendNUIMessage({ t = 'ping' })
    notify('CarPlay : diagnostic envoyé dans la console F8.')
end, false)
