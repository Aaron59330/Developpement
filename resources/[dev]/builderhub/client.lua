local open = false

local function close()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ a = 'close' })
end

RegisterCommand(Config.Command, function()
    if not open then TriggerServerEvent('builderhub:request') end
end, false)

if Config.OpenKey then
    RegisterKeyMapping(Config.Command, 'Ouvrir le panel des builders', 'keyboard', Config.OpenKey)
end

RegisterNetEvent('builderhub:open', function(list)
    open = true
    SetNuiFocus(true, true)
    SendNUIMessage({ a = 'open', list = list })
end)

RegisterNetEvent('builderhub:run', function(command)
    close()
    Wait(200)
    ExecuteCommand(command)
end)

RegisterNUICallback('close', function(_, cb)
    close()
    cb('ok')
end)

RegisterNUICallback('launch', function(data, cb)
    if type(data) == 'table' and type(data.id) == 'string' then
        TriggerServerEvent('builderhub:launch', data.id)
    end
    cb('ok')
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)
