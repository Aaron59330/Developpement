local open = false

local function close()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function show()
    if open then return end
    local data = lib.callback.await('pickax_tutorial:data', false)
    if not data then return end
    open = true
    SetNuiFocus(true, true)
    data.action = 'open'
    SendNUIMessage(data)
end

RegisterCommand(Config.Command, show, false)

RegisterNUICallback('finish', function(body, cb)
    local r = lib.callback.await('pickax_tutorial:finish', false, body and body.skipped == true) or { ok = false }
    cb(r)
end)
RegisterNUICallback('close', function(_, cb) cb(1) close() end)

-- Ouverture automatique à l'arrivée d'un nouveau joueur
local function auto()
    Wait(Config.Delay)
    while not IsScreenFadedIn() or IsPlayerSwitchInProgress() or IsEntityDead(PlayerPedId()) do Wait(1000) end
    if lib.callback.await('pickax_tutorial:shouldOpen', false) then show() end
end
RegisterNetEvent('esx:playerLoaded', function() CreateThread(auto) end)
AddEventHandler('onResourceStart', function(r) if r == GetCurrentResourceName() then CreateThread(auto) end end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() and open then SetNuiFocus(false, false) end end)
