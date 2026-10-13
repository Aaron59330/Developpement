-- À mettre à la place des 3 fonctions correspondantes dans es_extended/client/functions.lua
-- Le nom de ressource "pickax_notify" doit correspondre au dossier de la ressource.

function ESX.ShowNotification(msg, hudColorIndex)
    exports['pickax_notify']:ShowNotification(msg, hudColorIndex)
end

function ESX.ShowAdvancedNotification(title, subject, msg, icon, iconType, hudColorIndex)
    exports['pickax_notify']:ShowAdvancedNotification(title, subject, msg, icon, iconType, hudColorIndex)
end

function ESX.ShowHelpNotification(msg)
    exports['pickax_notify']:ShowHelpNotification(msg)
end
