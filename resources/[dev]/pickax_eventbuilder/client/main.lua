ESX = exports['es_extended']:getSharedObject()

local uiOpen = false

local function openUI()
    if IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true then return end
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end

function CloseUI()
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

CreateThread(function()
    while true do
        Wait(250)
        if uiOpen and (IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true) then CloseUI() end
    end
end)

RegisterCommand(Config.Command, function()
    if uiOpen then return CloseUI() end
    ESX.TriggerServerCallback('eventbuilder:isAdmin', function(ok)
        if ok then openUI() else ESX.ShowNotification('~r~Accès refusé : réservé à l\'équipe.') end
    end)
end, false)
if Config.OpenKey then RegisterKeyMapping(Config.Command, 'Ouvrir l\'Event Builder', 'keyboard', Config.OpenKey) end

-- Appels serveur autorisés depuis l'éditeur
local NuiRemote = {
    catalog = true, list = true, get = true, draft = true, create = true, save = true, delete = true, duplicate = true, toggle = true,
    start = true, stop = true, active = true, logs = true, autoGet = true, autoSave = true, autoNow = true,
}
local NuiLocal = {}

NuiLocal.close = function(_, cb) CloseUI() cb({}) end

NuiLocal.getCoords = function(_, cb)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    cb({ x = c.x, y = c.y, z = c.z, h = GetEntityHeading(ped) })
end

NuiLocal.teleport = function(args, cb)
    local c = args[1]
    if type(c) == 'table' and c.x then
        ESX.TriggerServerCallback('eventbuilder:isAdmin', function(ok)
            if ok then SetEntityCoords(PlayerPedId(), c.x + 0.0, c.y + 0.0, c.z + 0.0, false, false, false, false) end
            cb({ ok = ok })
        end)
    else cb({ ok = false }) end
end

-- Retour au panel central (builderhub)
NuiLocal.bbHub = function(_, cb)
    cb({ ok = true })
    CloseUI()
    SetTimeout(250, function() ExecuteCommand('builders') end)
end

RegisterNUICallback('rpc', function(body, cb)
    local name, args = body.name, body.args or {}
    if NuiLocal[name] then return NuiLocal[name](args, cb) end
    if NuiRemote[name] then
        return ESX.TriggerServerCallback('eventbuilder:' .. name, function(res) cb(res or { ok = false, error = 'Aucune réponse' }) end, table.unpack(args))
    end
    cb({ ok = false, error = 'Appel inconnu' })
end)
