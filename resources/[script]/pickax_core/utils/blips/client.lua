Citizen.CreateThread(function()
    for k,v in pairs(ConfigBlips) do
        local blip = AddBlipForCoord(v.Position) 
        SetBlipSprite(blip, v.id)
        SetBlipDisplay(blip, 6)
        if v.scale ~= nil then
            SetBlipScale(blip, 0.5)
        else
            SetBlipScale(blip, 0.5)
        end
        SetBlipColour(blip, v.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING") 
        AddTextComponentString(v.name)
        EndTextCommandSetBlipName(blip)

        if v.ZoneBlip then
            local zoneblip = AddBlipForRadius(v.Position, 800.0)
            SetBlipSprite(zoneblip,1)
            SetBlipColour(zoneblip, v.color)
            SetBlipAlpha(zoneblip,100)
        end
    end
end)