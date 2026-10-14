-- Notifications du Job Builder : même système (pickax_notify) avec le logo du métier du joueur (mécano = clé à molette, police = bouclier…)
function JBNotify(msg, kind, length)
    ESX.ShowNotification(msg, kind, length, '@job')
end
