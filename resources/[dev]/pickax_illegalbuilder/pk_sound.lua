-- Réglage « Sons des menus » du menu personnel (pickax_ui) transmis à l'interface de cette ressource :
-- un seul réglage (activé / volume) pour toutes les interfaces du serveur.
local function pkPush(c)
    if type(c) ~= 'table' then return end
    SendNUIMessage({ action = 'pkSound', sound = c.sound ~= false, volume = tonumber(c.volume) or 60 })
end
AddEventHandler('pickax_ui:settings', pkPush)
CreateThread(function()
    while true do
        if GetResourceState('pickax_ui') == 'started' then
            local ok, c = pcall(function() return exports['pickax_ui']:GetSound() end)
            if ok then pkPush(c) end
        end
        Wait(4000)
    end
end)
