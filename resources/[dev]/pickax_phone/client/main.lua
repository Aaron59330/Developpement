Phone = { open = false, loaded = false, typing = false, inCall = false, ringing = false, camera = false }
local prop, animDict, animName

local function hasPhone(force) return Bridge.HasPhone(force) end
Phone.HasPhone = hasPhone

local function canUse()
    local ped = PlayerPedId()
    local R = Config.Restrictions or {}
    if R.dead ~= false and (IsPedDeadOrDying(ped, true) or Bridge.IsDead()) then return false end
    if R.ragdoll ~= false and (IsPedRagdoll(ped) or IsPedBeingStunned(ped, 0)) then return false end
    if R.cuffed ~= false and Bridge.IsCuffed() then return false end
    if R.inVehicleDriver and IsPedInAnyVehicle(ped, false) and GetPedInVehicleSeat(GetVehiclePedIsIn(ped, false), -1) == ped and GetEntitySpeed(GetVehiclePedIsIn(ped, false)) > 3.0 then return false end
    if LocalPlayer.state.invBusy then return false end
    return true
end

-- ═════════════════ ANIMATION / PROP ═════════════════
local function loadDict(d) RequestAnimDict(d) local t = 0 while not HasAnimDictLoaded(d) and t < 100 do Wait(10) t = t + 1 end end

local function playAnim(name)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return end
    local dict = 'cellphone@'
    loadDict(dict)
    if animName ~= name then
        TaskPlayAnim(ped, dict, name, 3.0, 3.0, -1, 50, 0, false, false, false)
        animDict, animName = dict, name
    end
end

local function attachProp()
    if prop and DoesEntityExist(prop) then return end
    local model = `prop_npc_phone_02`
    RequestModel(model) local t = 0 while not HasModelLoaded(model) and t < 100 do Wait(10) t = t + 1 end
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    prop = CreateObject(model, c.x, c.y, c.z + 0.2, true, true, false)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)
end

local function dropProp()
    if prop and DoesEntityExist(prop) then DeleteEntity(prop) end
    prop = nil
end

function Phone.UpdateAnim()
    if Phone.camera then return end
    local ped = PlayerPedId()
    if not Phone.open and not Phone.inCall then
        if animName then StopAnimTask(ped, animDict, animName, 3.0) animName = nil end
        dropProp()
        return
    end
    attachProp()
    if Phone.inCall and not Phone.open then playAnim('cellphone_call_listen_base')
    elseif Phone.inCall then playAnim('cellphone_call_listen_base')
    else playAnim('cellphone_text_read_base') end
end

-- ═════════════════ OUVERTURE / FERMETURE ═════════════════
local function sendInit()
    local data = lib.callback.await('aura:init', false)
    if not data then return false end
    Phone.loaded = true
    Phone.me = data.me
    SendNUIMessage({ action = 'init', data = data })
    return true
end

function Phone.Open()
    if Phone.open then return end
    if not hasPhone(true) then Bridge.Notify('Vous n\'avez pas de téléphone.') return end
    if not canUse() then return end
    if not Phone.loaded and not sendInit() then return end
    Phone.open = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({ action = 'open' })
    Phone.UpdateAnim()
    TriggerEvent('aura:opened')
end

function Phone.Close()
    if not Phone.open then return end
    Phone.open = false
    Phone.typing = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'close' })
    Phone.UpdateAnim()
    TriggerEvent('aura:closed')
end

function Phone.Toggle() if Phone.open then Phone.Close() else Phone.Open() end end

RegisterCommand(Config.Command, function() Phone.Toggle() end, false)
RegisterKeyMapping(Config.Command, 'Ouvrir le téléphone (' .. Config.Brand .. ')', 'keyboard', Config.Key)

AddEventHandler('ox_inventory:usedItem', function(name)
    if Config.UseItem and name == Config.Item then Phone.Toggle() end
end)
RegisterNetEvent('aura:useItem', function() if Config.UseItem then Phone.Toggle() end end)   -- ESX / QBCore / qs-inventory

-- Fermeture automatique : mort, menotté, ragdoll, perte de l'objet
CreateThread(function()
    while true do
        Wait(500)
        if Phone.open then
            if not canUse() or not hasPhone() then Phone.Close() end
        end
    end
end)

-- Contrôles désactivés tant que le téléphone est ouvert (le déplacement reste possible hors saisie)
CreateThread(function()
    while true do
        if Phone.open or Phone.ringing then
            Wait(0)
            DisableControlAction(0, 1, true); DisableControlAction(0, 2, true)       -- regard (souris sur le téléphone)
            DisableControlAction(0, 24, true); DisableControlAction(0, 25, true)     -- attaque / visée
            DisableControlAction(0, 37, true); DisableControlAction(0, 47, true)     -- roue des armes / arme
            DisableControlAction(0, 140, true); DisableControlAction(0, 141, true); DisableControlAction(0, 142, true); DisableControlAction(0, 143, true)
            DisableControlAction(0, 257, true); DisableControlAction(0, 263, true); DisableControlAction(0, 264, true)
            DisableControlAction(0, 199, true); DisableControlAction(0, 200, true)   -- pause
            if Phone.typing then
                for k = 30, 36 do DisableControlAction(0, k, true) end
                for k = 21, 23 do DisableControlAction(0, k, true) end
                DisableControlAction(0, 44, true); DisableControlAction(0, 75, true); DisableControlAction(0, 73, true)
            end
        else Wait(300) end
    end
end)

-- ═════════════════ PONT NUI ═════════════════
RegisterNUICallback('close', function(_, cb) Phone.Close() cb(1) end)
RegisterNUICallback('msgTyping', function(d, cb)
    if d and type(d.conv) == 'string' then TriggerServerEvent('aura:typing', d.conv) end
    cb(1)
end)

RegisterNUICallback('typing', function(d, cb)
    Phone.typing = d and d.state and true or false
    SetNuiFocusKeepInput(not Phone.typing)
    cb(1)
end)

-- appel serveur générique : le nom est limité à [A-Za-z0-9_] et préfixé côté client
RegisterNUICallback('rpc', function(d, cb)
    local name = d and d.name
    if type(name) ~= 'string' or not name:match('^[%w_]+$') then cb({ a = false }) return end
    local args = type(d.args) == 'table' and d.args or {}
    local res = table.pack(pcall(lib.callback.await, 'aura:' .. name, false, table.unpack(args, 1, d.n or #args)))
    if not res[1] then
        if Config.Debug then print('^1[pickax_phone] rpc ' .. name .. ' : ' .. tostring(res[2]) .. '^7') end
        cb({ a = false, b = 'Erreur serveur' })
        return
    end
    cb({ a = res[2], b = res[3] })
end)

RegisterNetEvent('aura:push', function(event, data)
    if event == 'battery' then Phone.battery = data.level end
    if event == 'reset' then Phone.loaded = false end
    TriggerEvent('aura:client:' .. event, data)
    SendNUIMessage({ action = 'push', event = event, data = data })
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        SetNuiFocus(false, false); dropProp()
        local ped = PlayerPedId()
        if animName then StopAnimTask(ped, animDict, animName, 3.0) end
    end
end)

Bridge.OnLogout(function() Phone.loaded = false; Phone.Close() end)

exports('Open', Phone.Open)
exports('Close', Phone.Close)
exports('IsOpen', function() return Phone.open end)
exports('HasPhone', hasPhone)
