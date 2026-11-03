-- TextUI du serveur : texte d'aide GTA affiché tant que l'invite est visible (remplace le TextUI d'ox_lib)
if Config.TextUI ~= 'pickax' then return end

while not Bridge do Citizen.Wait(0) end

Bridge.TextUI = {}
local current, running = nil, false

Bridge.TextUI.show = function(text)
    current = text
    if running then return end
    running = true
    Citizen.CreateThread(function()
        while current do
            local msg = (tostring(current):gsub('%[E%]', '~INPUT_CONTEXT~'))
            if GetResourceState('pickax_notify') == 'started' then
                exports['pickax_notify']:ShowHelpNotification(msg)   -- même aide que partout sur le serveur
            else
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName(msg)
                EndTextCommandDisplayHelp(0, false, false, -1)
            end
            Citizen.Wait(0)
        end
        running = false
    end)
end

Bridge.TextUI.hide = function() current = nil end
