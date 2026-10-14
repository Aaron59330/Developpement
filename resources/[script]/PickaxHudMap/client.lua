CreateThread(function()
    Wait(1000)

    SetMinimapClipType(0)
    DisplayRadar(true)

    SetMinimapComponentPosition('minimap', 'L', 'B', -0.0045, 0.002, 0.15, 0.188888)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.0, -0.01, 0.12, 0.2)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.0305, 0.04, 0.267, 0.272)

    lib.requestStreamedTextureDict('shokoradar')
    AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', 'shokoradar', 'radarmasksm-rounded')
    AddReplaceTexture('platform:/textures/graphics', 'radarmask1g', 'shokoradar', 'radarmasksm-rounded')
    SetStreamedTextureDictAsNoLongerNeeded('shokoradar')

    local minimap = RequestScaleformMovie('minimap')
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)

    CreateThread(function()
        while true do
            Wait(0)
            SetBlipAlpha(GetNorthRadarBlip(), 0)
        end
    end)

    CreateThread(function()
        while true do
            Wait(0)
            BeginScaleformMovieMethod(minimap, 'SETUP_HEALTH_ARMOUR')
            ScaleformMovieMethodAddParamInt(3)
            EndScaleformMovieMethod()
        end
    end)
end)




-- Minimap masquée quand l'inventaire est ouvert
CreateThread(function()
    local hidden = false
    while true do
        Wait(150)
        local open = LocalPlayer.state.invOpen == true
        if open ~= hidden then
            hidden = open
            DisplayRadar(not open)
        end
    end
end)
