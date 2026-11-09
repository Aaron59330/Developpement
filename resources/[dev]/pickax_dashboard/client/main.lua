ESX = exports['es_extended']:getSharedObject()
local C = Config
local open = false
local allowed = {}   -- commandes que le tableau de bord peut lancer (celles de la config)

local function close()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ a = 'close' })
end

local function openDash()
    if open or IsPauseMenuActive() or IsNuiFocused() then return end
    ESX.TriggerServerCallback('pickax_dashboard:data', function(d)
        if not d then return end
        -- noms de véhicules : résolus côté client à partir du modèle
        for _, v in ipairs(d.vehicles.items or {}) do
            if v.model then
                local label = GetLabelText(GetDisplayNameFromVehicleModel(v.model))
                v.name = (label and label ~= 'NULL') and label or tostring(GetDisplayNameFromVehicleModel(v.model))
                v.sub = v.plate
            else v.name, v.sub = v.plate or '?', '' end
        end
        d.prefs = {}
        allowed = {}
        for _, s in ipairs(d.services or {}) do allowed[s.command] = true end
        for _, grp in pairs(d.actions or {}) do for _, a in ipairs(grp) do allowed[a.command] = true end end
        open = true
        SetNuiFocus(true, true)
        SendNUIMessage({ a = 'open', data = d })
    end)
end

RegisterCommand(C.Command, openDash, false)
if C.Key and C.Key ~= '' then RegisterKeyMapping(C.Command, 'Tableau de bord', 'keyboard', C.Key) end
exports('Open', openDash)
exports('Close', close)

RegisterNUICallback('close', function(_, cb) cb(1) close() end)
RegisterNUICallback('buy', function(d, cb) cb(1) TriggerServerEvent('pickax_dashboard:buy', d and d.id) end)
RegisterNUICallback('setting', function(_, cb) cb(1) end)
RegisterNUICallback('volume', function(_, cb) cb(1) end)
RegisterNUICallback('cmd', function(d, cb)
    cb(1)
    local name = d and d.command
    if type(name) == 'string' and allowed[name] then
        close()
        SetTimeout(150, function() ExecuteCommand(name) end)
    end
end)
RegisterNUICallback('act', function(d, cb)
    cb(1)
    local a = d and d.a
    if a == 'locate' then TriggerEvent('pickax_dashboard:locate') end   -- à brancher : écoute cet événement dans ton système de garage / de métiers
end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() and open then SetNuiFocus(false, false) end end)
