-- Téléportation demandée depuis la carte du panel web : on charge la zone puis on cherche le sol (pas de chute dans le vide)
RegisterNetEvent('pickax_panel:tp', function(x, y)
    if type(x) ~= 'number' or type(y) ~= 'number' then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local ent = (veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped) and veh or ped
    DoScreenFadeOut(300) while not IsScreenFadedOut() do Wait(0) end
    FreezeEntityPosition(ent, true)
    SetEntityCoordsNoOffset(ent, x, y, 600.0, false, false, false)
    local z, found = 600.0, false
    local t = GetGameTimer()
    while GetGameTimer() - t < 5000 do
        RequestCollisionAtCoord(x, y, z)
        for h = 900.0, -100.0, -25.0 do
            local ok, gz = GetGroundZFor_3dCoord(x, y, h, false)
            if ok then z, found = gz, true break end
        end
        if found then break end
        Wait(100)
    end
    SetEntityCoordsNoOffset(ent, x, y, found and (z + 1.0) or 60.0, false, false, false)
    FreezeEntityPosition(ent, false)
    DoScreenFadeIn(400)
end)
