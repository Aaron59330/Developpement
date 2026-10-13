-- Fermeture du loading screen NUI (nécessaire avec loadscreen_cursor + loadscreen_manual_shutdown).
-- On ne ferme QUE la page NUI : le loading screen du jeu reste géré par spawnmanager (pas d'effet sur la map/radar).
local closed = false

local function closeNui()
    if closed then return end
    closed = true
    ShutdownLoadingScreenNui()
end

-- Dès que le joueur est spawn / chargé, on ferme la page (le curseur est alors rendu aux autres scripts)
AddEventHandler('playerSpawned', function()
    Wait(1000)
    closeNui()
end)

AddEventHandler('esx:playerLoaded', function()
    Wait(1500)
    closeNui()
end)

-- Sécurité : fermeture forcée si aucun des événements n'arrive
CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(200) end
    Wait(20000)
    closeNui()
end)
