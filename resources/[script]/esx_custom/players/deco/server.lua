local PlayerLeave = {}

AddEventHandler('esx:playerDropped', function(eventSrc, xPlayer)
    local pCoords = GetEntityCoords(GetPlayerPed(xPlayer.source))
    PlayerLeave[xPlayer.source] = {coords = pCoords, IDBoutique = xPlayer.boutique_id}
    TriggerClientEvent("esx_custom:DecoPlayer:playerDisconnect", -1, xPlayer.source, {pos = pCoords, IDBoutique = xPlayer.boutique_id})
end)