-- Notifications du Job Builder : même système (pickax_notify) avec le logo du métier du joueur (mécano = clé à molette, police = bouclier…)
function JBNotify(msg, kind, length)
    ESX.ShowNotification(msg, kind, length, '@job')
end

-- Barre de progression d'action : la même (NUI) que dans tous les builders
function JBProgress(label, ms, hint)
    SendNUIMessage({ action = 'progress', label = label or '', ms = math.floor(tonumber(ms) or 1000), hint = hint or 'Appuie sur X pour annuler' })
end
function JBProgressEnd() SendNUIMessage({ action = 'progressEnd' }) end
