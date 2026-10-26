-- Reçoit les réglages du serveur ; les ressources les lisent via l'export ou l'événement local 'pickax_settings:changed' (valeurs, surcharges).
local values, over = {}, {}
local ready = false

RegisterNetEvent('pickax_settings:sync', function(all, ov)
    values, over, ready = all or {}, ov or {}, true
    TriggerEvent('pickax_settings:changed', values, over)
end)

exports('Get', function(key) return values[key] end)
exports('GetAll', function() return values end)
exports('Overrides', function() return over end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('pickax_settings:request')
    Wait(8000)
    if not ready then TriggerServerEvent('pickax_settings:request') end
end)
