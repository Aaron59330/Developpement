-- Affichage seul : aucune prise de focus NUI, le clavier reste géré par RageUI (CorePickax).
local shown = false

exports('Update', function(data)
    shown = true
    SendNUIMessage({ a = 'menu', d = data })
end)

exports('Hide', function()
    if not shown then return end
    shown = false
    SendNUIMessage({ a = 'hide' })
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)
