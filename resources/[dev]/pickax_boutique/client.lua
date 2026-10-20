-- Interface de la boutique à coins : ne contient aucune logique d'achat (tout passe par les exports de pickax_core, comme l'ancien menu)
local ESX = exports['es_extended']:getSharedObject()
local open = false
local points = 0

RegisterNetEvent('CorePickax:ReceiveClientSideBoutique', function(info)
    if info and info.points ~= nil then
        points = tonumber(info.points) or 0
        if open then SendNUIMessage({ action = 'points', points = points }) end
    end
end)

local function Close()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    TriggerEvent('pickax:inventory', false)       -- réaffiche les HUD
end

local function Open()
    if open or IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true then return end
    if GetResourceState('pickax_core') ~= 'started' then return end
    local ok, cat = pcall(function() return exports['pickax_core']:BoutiqueCatalog() end)
    if not ok or type(cat) ~= 'table' then
        ESX.ShowNotification('~r~Boutique indisponible pour le moment.')
        return
    end
    open = true
    points = tonumber(cat.points) or points
    SetNuiFocus(true, true)
    TriggerEvent('pickax:inventory', true)        -- masque les HUD pendant la boutique
    SendNUIMessage({ action = 'open', data = cat })
end

exports('Open', Open)
exports('Close', Close)

CreateThread(function()
    while true do
        Wait(250)
        if open and (IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true) then Close() end
    end
end)

RegisterNUICallback('close', function(_, cb) Close() cb({}) end)

RegisterNUICallback('buy', function(body, cb)
    local ok, res = pcall(function() return exports['pickax_core']:BoutiqueBuy(tostring(body.cat), tonumber(body.idx)) end)
    cb(ok and res or { ok = false, error = 'Achat impossible' })
end)

RegisterNUICallback('classic', function(_, cb)
    cb({})
    Close()
    SetTimeout(250, function() pcall(function() exports['pickax_core']:BoutiqueOpenClassic() end) end)
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and open then SetNuiFocus(false, false) TriggerEvent('pickax:inventory', false) end
end)
