-- Fermeture manuelle du loading screen (nécessaire avec loadscreen_cursor).
-- On le ferme dès que le joueur est actif dans la session, puis on laisse la main aux autres scripts
-- (ex : esx_identity qui redemande le curseur juste après).
CreateThread(function()
    local timeout = GetGameTimer() + 90000 -- sécurité : fermeture forcée au bout de 90 s

    while not NetworkIsPlayerActive(PlayerId()) and GetGameTimer() < timeout do
        Wait(100)
    end

    Wait(1500)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
end)
