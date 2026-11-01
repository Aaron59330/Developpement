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
        local key = ('PKBLIP_%x'):format(GetHashKey(v.name))   -- texte partagé : les blips de même nom se regroupent dans la légende (« Nom 1/9 »)
        AddTextEntry(key, v.name)
        BeginTextCommandSetBlipName(key)
        EndTextCommandSetBlipName(blip)

        if v.ZoneBlip then
            local zoneblip = AddBlipForRadius(v.Position, 800.0)
            SetBlipSprite(zoneblip,1)
            SetBlipColour(zoneblip, v.color)
            SetBlipAlpha(zoneblip,100)
        end
    end
end)