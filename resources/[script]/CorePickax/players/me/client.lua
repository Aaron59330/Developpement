local nbrDisplaying = 1
local currentlyDisplaying = {}

local function Display(mePlayer, text, offset)
    if not currentlyDisplaying[mePlayer] then
        currentlyDisplaying[mePlayer] = {}
    end

    for _,anyText in pairs(currentlyDisplaying[mePlayer]) do
        if anyText == text then
            return
        end
    end

    table.insert(currentlyDisplaying[mePlayer], text)

    local displaying = true
    Citizen.CreateThread(function()
        Wait(10000)
        displaying = false
        for i,anyText in pairs(currentlyDisplaying[mePlayer]) do
            if anyText == text then
                table.remove(currentlyDisplaying[mePlayer], i)
            end
        end
    end)

    Citizen.CreateThread(function()
        nbrDisplaying = nbrDisplaying + 1
        while displaying do
            Wait(0)
            local coordsMe = GetEntityCoords(mePlayer, false)
            local coords = GetEntityCoords(PlayerPedId(), false)
            local dist = #(coordsMe - coords)
            
            if dist < 50 then
                ESXCustom_Function_ClientSide:DrawText3D(vector3(coordsMe['x'], coordsMe['y'], coordsMe['z']+offset), text, nil, ConfigME.Color)
            end
        end
        nbrDisplaying = nbrDisplaying - 1
    end)
end

RegisterCommand('me', function(source, args)
    local text = ""..ConfigME.DefaultText..""
    for i = 1,#args do
        text = text .. ' ' .. args[i]
    end
    text = text .. ' '
    TriggerServerEvent('3dme:shareDisplay', text)
end)

RegisterNetEvent('3dme:triggerDisplay')
AddEventHandler('3dme:triggerDisplay', function(text, source)
    local player = GetPlayerFromServerId(source)
    if player ~= -1 then
        Display(GetPlayerPed(player), text, 1 + (nbrDisplaying*0.12))
    end
end)