-- Notifications liées au métier / à l'entreprise : avec le logo du métier du joueur
if IsDuplicityVersion() then
    function JobNotifyClient(target, msg)
        TriggerClientEvent('esx:showNotification', target, msg, nil, nil, '@job')
    end
else
    function JobNotify(msg, kind, length)
        ESX.ShowNotification(msg, kind, length, '@job')
    end
end
