for k, v in pairs(ConfigAdmin.FunctionClientSide) do
    RegisterNetEvent(v.name, function()
        v.IsUsed()
    end)
end

TeleportMarkerClientSide = function()
    local waypointHandle = GetFirstBlipInfoId(8)

    if DoesBlipExist(waypointHandle) then
        Citizen.CreateThread(function()
            local waypointCoords = GetBlipInfoIdCoord(waypointHandle)
            local foundGround, zCoords, zPos = false, -500.0, 0.0

            while not foundGround do
                zCoords = zCoords + 10.0
                RequestCollisionAtCoord(waypointCoords.x, waypointCoords.y, zCoords)
                Citizen.Wait(0)
                foundGround, zPos = GetGroundZFor_3dCoord(waypointCoords.x, waypointCoords.y, zCoords)

                if not foundGround and zCoords >= 2000.0 then
                    foundGround = true
                end
            end

            SetPedCoordsKeepVehicle(PlayerPedId(), waypointCoords.x, waypointCoords.y, zPos)
            ESX.ShowNotification('Vous avez été TP au marker')
        end)
    else
        ESX.ShowNotification('~r~Pas de point sur la map !')
    end
end