local PlayerLeave = {}

RegisterNetEvent("esx_custom:DecoPlayer:playerDisconnect", function(player, info)
    PlayerLeave[player] = info
    StartLoop(player)
end)

function StartLoop(player)
    Citizen.CreateThread(function()
        Wait(ConfigDeco.Time)
        if PlayerLeave[player] ~= nil then
            PlayerLeave[player] = nil
        end
    end)
end

Citizen.CreateThread(function()
    while true do
        local pPed = GetPlayerPed(-1)
        local pCoords = GetEntityCoords(pPed)
        local pNear = false

        for k,v in pairs(PlayerLeave) do
            if #(v.pos - pCoords) < ConfigDeco.DrawDistance then
                pNear = true
                ESXCustom_Function_ClientSide:DrawText3D(vector3(v.pos.x, v.pos.y, v.pos.z), (ConfigDeco.Text):format(v.IDBoutique))
            end
        end

        if pNear then
            Wait(1)
        else
            Wait(500)
        end
    end
end)