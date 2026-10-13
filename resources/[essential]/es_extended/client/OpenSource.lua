
function ESX.ShowNotification(msg, hudColorIndex)
    exports['pickax_notify']:ShowNotification(msg, hudColorIndex)
end

function ESX.ShowAdvancedNotification(title, subject, msg, icon, iconType, hudColorIndex)
    exports['pickax_notify']:ShowAdvancedNotification(title, subject, msg, icon, iconType, hudColorIndex)
end

function ESX.ShowHelpNotification(msg)
	AddTextEntry('esxHelpNotification', msg)
	BeginTextCommandDisplayHelp('esxHelpNotification')
	EndTextCommandDisplayHelp(0, false, true, -1)
end