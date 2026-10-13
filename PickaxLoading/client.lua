local closed = false
local function closeLoadingScreen()
    if closed then return end
    closed = true
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
end

-- Le menu de création de personnage (esx_identity) a besoin du curseur : on libère le focus tout de suite.
RegisterNetEvent('esx_identity:showRegisterIdentity', function()
    closeLoadingScreen()
end)
AddEventHandler('esx:playerLoaded', function()
    Wait(500)
    closeLoadingScreen()
end)

-- Fermeture manuelle du loading screen (nécessaire avec loadscreen_cursor).
-- On le ferme dès que le joueur est actif dans la session, puis on laisse la main aux autres scripts
-- (ex : esx_identity qui redemande le curseur juste après).
CreateThread(function()
    local timeout = GetGameTimer() + 90000 -- sécurité : fermeture forcée au bout de 90 s

    while not NetworkIsPlayerActive(PlayerId()) and GetGameTimer() < timeout do
        Wait(100)
    end

    Wait(1500)
    closeLoadingScreen()
end)
