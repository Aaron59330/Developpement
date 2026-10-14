-- Toutes les notifications ESX passent par pickax_notify (repli natif GTA seulement si la ressource est arrêtée)
local function pickax() return GetResourceState('pickax_notify') == 'started' end

function ESX.ShowNotification(msg, type, length, icon)
    if pickax() then return exports['pickax_notify']:ShowNotification(msg, type, length, icon) end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(tostring(msg))
    EndTextCommandThefeedPostTicker(false, true)
end

function ESX.ShowAdvancedNotification(title, subject, msg, icon, iconType, hudColorIndex)
    if pickax() then return exports['pickax_notify']:ShowAdvancedNotification(title, subject, msg, icon, iconType, hudColorIndex) end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(tostring(msg))
    EndTextCommandThefeedPostMessagetext(icon or 'CHAR_DEFAULT', icon or 'CHAR_DEFAULT', false, iconType or 1, tostring(title), tostring(subject))
end

function ESX.ShowHelpNotification(msg)
    AddTextEntry('esxHelpNotification', msg)
    BeginTextCommandDisplayHelp('esxHelpNotification')
    EndTextCommandDisplayHelp(0, false, true, -1)
end
