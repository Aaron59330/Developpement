function OpenMenuLoteries(k)
    local Lotery = {
        InfoPlayer = nil,
        All = 0,
        Time = ""
    }
    ESX.TriggerServerCallback('lotery:GetAll', function(Data)
        Lotery.InfoPlayer = Data.source
        Lotery.All = Data.all
        Lotery.Time = Data.Time
    end)

    local PoseMenu = GetEntityCoords(PlayerPedId())
    local menu = RageUI.CreateMenu("Loteries", "Que voulez-vous faire ?")
    local menu2 = RageUI.CreateSubMenu(menu, "Loteries", "Que voulez-vous faire ?")
    RageUI.Visible(menu, not RageUI.Visible(menu))

    while menu do
        Wait(0)

        if #(GetEntityCoords(PlayerPedId()) - PoseMenu) > 5 then 
            ESX.ShowNotification("~r~Information\n~s~Vous vous éloignez de trop.")
            RageUI.CloseAll()
        end
        
        RageUI.IsVisible(menu, true, true, true,function()
            RageUI.Separator("Tirage : ~y~"..Lotery.Time.. "~s~")
            RageUI.Separator("Gain : ~g~"..ESXCustom_Function_ClientSide:GroupDigits(Lotery.All * ConfigLotery.PriceByTicket).. "$~s~")
            RageUI.Line()
            RageUI.ButtonWithStyle("Participer à la loterie", nil, {RightLabel = "→→→"}, true, function(_, Active, Selected)
                if Selected then
                    local Keyboard = ESXCustom_Function_ClientSide:KeyboardInput("Acheter un ticket ? (~g~Oui~s~ ou ~r~Non~s~)", 3)
                    if Keyboard == "oui" or Keyboard == "Oui" then
                        local table = {anticheat = true, code = math.random(111111111111111, 999999999999999), id = k}
                        TriggerServerEvent("lotery:GiveServerSide", table)
                        RageUI.CloseAll()
                        OpenMenuLoteries(k)
                    end
                end
			end)
            RageUI.ButtonWithStyle("Mes tickets", nil, {RightLabel = "→→→"}, true, function(_, Active, Selected)
			end, menu2)
        end)

        RageUI.IsVisible(menu2, true, true, true, function()
            if Lotery.InfoPlayer ~= nil then
                for q, v in pairs(Lotery.InfoPlayer.code) do
                    if v.win == nil then
                        RageUI.ButtonWithStyle("Ticket N°"..v.code, nil, {RightLabel = "→→→"}, true)
                    else
                        RageUI.ButtonWithStyle("Ticket N°"..v.code, "Vous avez gagné avec ce ticket, toutes nos félicitations.\n\nLe montant s'élève à ~g~"..v.gain.."$~s~.", {RightBadge = RageUI.BadgeStyle.Star}, true, function(_, Active, Selected)
                            if Selected then
                                local table = {anticheat = true, code = v.code, id = k}
                                TriggerServerEvent("lotery:Felicitations", table)
                                RageUI.CloseAll()
                            end
                        end)
                    end
                end
            else
                RageUI.Separator("")
                RageUI.Separator("~r~Vous avez aucun tickets~s~")
                RageUI.Separator("")
            end
        end)

        if not RageUI.Visible(menu) and not RageUI.Visible(menu2) then
            menu = RMenu:DeleteType('menu', true)
        end
    end
end

CreateThread(function()
    while true do
		local timer = 500
		local plyCoords = GetEntityCoords(PlayerPedId())

        for k,v in pairs(ConfigLotery.Pos) do
            local dist = Vdist2(GetEntityCoords(PlayerPedId(), false), v.x, v.y, v.z)

            if dist < ConfigLotery.Marker.Distance then
                timer = 0
                DrawGlobalMarker(ConfigLotery.Marker.MarkerType, v.x, v.y, v.z-ConfigLotery.Marker.MarkerDebug, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ConfigLotery.Marker.Scale.x, ConfigLotery.Marker.Scale.y, ConfigLotery.Marker.Scale.z, ConfigLotery.Marker.Color.r, ConfigLotery.Marker.Color.g, ConfigLotery.Marker.Color.b, ConfigLotery.Marker.Color.a, ConfigLotery.Marker.BobUpAndDown, ConfigLotery.Marker.FaceCamera, p19, ConfigLotery.Marker.Rotate)
            end
            if dist < ConfigLotery.Marker.PushEDistance then
                ESX.ShowHelpNotification(ConfigLotery.ShowHelp)
                if IsControlJustPressed(1,51) then
                    OpenMenuLoteries(k)
                end
            end
        end
	    Citizen.Wait(timer)
	end
end)