ESX = exports['es_extended']:getSharedObject()
local C = Config
local open = false

local function theme()
    local th = PickaxTheme or {}
    local srv = C.Server
    local logo = srv.Logo ~= '' and srv.Logo or th.logo
    if logo and logo ~= '' and not logo:match('^https?://') then logo = 'https://cfx-nui-pickax_theme/logo/' .. logo end
    return { name = srv.Name, subtitle = srv.Subtitle, version = srv.Version, license = srv.License, logo = logo, accent = (C.Accent ~= '' and C.Accent) or th.hex }
end

local function close()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ a = 'close' })
end

local function openMenu()
    if open then return end
    ESX.TriggerServerCallback('pickax_manage:open', function(d)
        if not d then ESX.ShowNotification('Accès refusé.') return end
        open = true
        SetNuiFocus(true, true)
        SendNUIMessage({ a = 'open', data = d, server = theme(), cats = C.Categories, refresh = C.RefreshSec })
    end)
end

RegisterCommand(C.Command, openMenu, false)
if C.Key and C.Key ~= '' then RegisterKeyMapping(C.Command, 'Gestion du serveur', 'keyboard', C.Key) end

RegisterNUICallback('close', function(_, cb) cb(1) close() end)
RegisterNUICallback('refresh', function(_, cb) ESX.TriggerServerCallback('pickax_manage:refresh', function(d) cb(d or {}) end) end)
RegisterNUICallback('action', function(d, cb)
    cb(1)
    local a = d and d.action
    TriggerServerEvent('pickax_manage:log', 'Ouvre « ' .. tostring(d and d.title or '?') .. ' »')
    if type(a) ~= 'table' then return end
    close()
    Wait(150)
    if a.command then ExecuteCommand(a.command)
    elseif a.event then TriggerEvent(a.event)
    elseif a.export then pcall(function() exports[a.export[1]][a.export[2]](exports[a.export[1]]) end) end
end)

CreateThread(function() while true do if open then DisableControlAction(0, 1, true) DisableControlAction(0, 2, true) DisableControlAction(0, 24, true) Wait(0) else Wait(500) end end end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() and open then SetNuiFocus(false, false) end end)
