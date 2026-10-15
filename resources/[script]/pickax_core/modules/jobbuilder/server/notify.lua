-- Notification serveur -> joueur avec le logo de son métier
function JBNotifyClient(target, msg)
    TriggerClientEvent('esx:showNotification', target, msg, nil, nil, '@job')
end
