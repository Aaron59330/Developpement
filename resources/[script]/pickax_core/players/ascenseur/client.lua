Citizen.CreateThread(function()
    count = 0
    for k,v in pairs(ConfigAscenseur.AllPosition) do
        count = count + 1
    end
    while true do
        timer = 500
        local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
        for k,v in pairs(ConfigAscenseur.AllPosition) do
            if v.JobsRequis ~= nil then
                if ESX.PlayerData ~= nil and ESX.PlayerData.job ~= nil and ESX.PlayerData.job.name == v.JobsRequis then
                    local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, v.Pose.x, v.Pose.y, v.Pose.z)
                
                    if dist < 4.0 then
                        timer = 0
                        if ConfigAscenseur.DrawMarker.Marker then
                            DrawGlobalMarker(ConfigAscenseur.DrawMarker.TypeMarker, v.Pose.x, v.Pose.y, v.Pose.z-1.0, 0.0, 0.0, 0.0, ConfigAscenseur.DrawMarker.Rotation, 0.0, 0.0, ConfigAscenseur.DrawMarker.Size.SizeX, ConfigAscenseur.DrawMarker.Size.SizeY, ConfigAscenseur.DrawMarker.Size.SizeZ, ConfigAscenseur.DrawMarker.Color.colorR, ConfigAscenseur.DrawMarker.Color.colorG, ConfigAscenseur.DrawMarker.Color.colorB, ConfigAscenseur.DrawMarker.Color.colorA)
                        end
                        ESX.ShowHelpNotification(ConfigAscenseur.Text.AccesAscenseur)
                        if IsControlJustPressed(1,51) then
                            OpenAscenseur(v.Items, v.Name)
                        end
                    end
                end
            else
                local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, v.Pose.x, v.Pose.y, v.Pose.z)
                
                if dist < 4.0 then
                    timer = 0
                    if ConfigAscenseur.DrawMarker.Marker then
                        DrawGlobalMarker(ConfigAscenseur.DrawMarker.TypeMarker, v.Pose.x, v.Pose.y, v.Pose.z-1.0, 0.0, 0.0, 0.0, ConfigAscenseur.DrawMarker.Rotation, 0.0, 0.0, ConfigAscenseur.DrawMarker.Size.SizeX, ConfigAscenseur.DrawMarker.Size.SizeY, ConfigAscenseur.DrawMarker.Size.SizeZ, ConfigAscenseur.DrawMarker.Color.colorR, ConfigAscenseur.DrawMarker.Color.colorG, ConfigAscenseur.DrawMarker.Color.colorB, ConfigAscenseur.DrawMarker.Color.colorA)
                    end
                    ESX.ShowHelpNotification(ConfigAscenseur.Text.AccesAscenseur)
                    if IsControlJustPressed(1,51) then
                        OpenAscenseur(v.Items, v.Name)
                    end
                end
            end
        end
        Wait(timer)
    end
end)

function OpenAscenseur(LeProps, LeNom)
    local menu = RageUI.CreateMenu(ConfigAscenseur.Text.Title, ConfigAscenseur.Text.Subtitle)
    RageUI.Visible(menu, not RageUI.Visible(menu))
    while menu do
        Wait(0)
        RageUI.IsVisible(menu, true, true, true, function()
            for k,v in pairs(ConfigAscenseur[LeProps]) do
                if v.Desc then
                    Desc = v.Desc
                else
                    Desc = nil
                end
                if LeNom == v.Name then
                    RageUI.ButtonWithStyle(v.Name, ConfigAscenseur.Vousetesla, { RightLabel = "→→→" }, false, function(_, Active, Selected)
                    end)
                else
                    RageUI.ButtonWithStyle(v.Name, Desc, { RightLabel = "→→→" }, true, function(_, Active, Selected)
                        if Selected then
                            RageUI.CloseAll()
                            if ConfigAscenseur.EcranNoir then
                                DoScreenFadeOut(100)
                                Wait(100)
                                SetEntityCoords(PlayerPedId(), v.Pose.x, v.Pose.y, v.Pose.z)
                                Wait(2000)
                                DoScreenFadeIn(100)
                                ESX.ShowNotification(ConfigAscenseur.Arrive..v.Name)
                            else
                                SetEntityCoords(PlayerPedId(), v.Pose.x, v.Pose.y, v.Pose.z)
                                ESX.ShowNotification(ConfigAscenseur.Arrive..v.Name)
                            end
                        end
                    end)
                end
            end
        end, function()
        end)
  
        if not RageUI.Visible(menu) then
            FreezeEntityPosition(PlayerPedId(), false)
            menu = RMenu:DeleteType('menu', true)
        end
    end
end