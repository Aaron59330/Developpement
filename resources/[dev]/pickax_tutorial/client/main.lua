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

-- Ouverture automatique : jamais pendant la création du personnage (identité, apparence, choix de la destination) ni sous un autre menu.
-- Nouveau personnage : on attend le signal « création terminée » de CorePickax, puis la fin du choix de destination / de l'arrivée.
-- Personnage existant : on ouvre après le chargement, quand l'écran est visible et qu'aucun menu n'a le curseur.
local running = false
local function auto(afterCreation)
    if running then return end
    running = true
    Wait(afterCreation and Config.AfterCreationDelay or Config.Delay)
    local calm = 0
    while calm < 3 do   -- 3 secondes d'affilée sans écran noir, sans menu à l'écran (curseur NUI), vivant et pas en transition
        if IsScreenFadedIn() and not IsPlayerSwitchInProgress() and not IsNuiFocused() and not IsEntityDead(PlayerPedId()) and not open then calm = calm + 1 else calm = 0 end
        Wait(1000)
    end
    if lib.callback.await('pickax_tutorial:shouldOpen', false, afterCreation == true) then show() end
    running = false
end
RegisterNetEvent('esx:playerLoaded', function() CreateThread(function() auto(false) end) end)
AddEventHandler('CorePickax:Creator:finished', function() CreateThread(function() auto(true) end) end)   -- fin de création du personnage (aussi écouté par esx_identity pour la destination)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() and open then SetNuiFocus(false, false) end end)
