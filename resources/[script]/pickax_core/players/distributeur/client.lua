local function OpenWater(LeProps)
    local menu = RageUI.CreateMenu(ConfigDistributeur.Water.Title, ConfigDistributeur.Water.Subtitle)
    local menusub = RageUI.CreateSubMenu(menu, ConfigDistributeur.Water.Title, ConfigDistributeur.Water.Subtitle)
    RageUI.Visible(menu, not RageUI.Visible(menu))
    while menu do
        Wait(0)
        RageUI.IsVisible(menu, true, true, true, function()
            RageUI.ButtonWithStyle(ConfigDistributeur.Water.Bouton, ConfigDistributeur.Water.Desc, {RightLabel = (ConfigDistributeur.Water.RightLabel):format(ConfigDistributeur.Water.MoneyRemove)}, true, function(_,_,s)
            end, menusub)
        end, function()
        end)

        RageUI.IsVisible(menusub, true, true, true, function()
            RageUI.ButtonWithStyle(ConfigDistributeur.Payement.Liquide, (ConfigDistributeur.Payement.LiquidePaiement):format(ConfigDistributeur.Water.MoneyRemove), {RightLabel = "→→→"}, true, function(_,_,s)
                if s then
                    ESXCustomFD:AnimForTake(PlayerPedId(), LeProps)
                    TriggerServerEvent("ESXCustomDistributeur:removeMoney", ConfigDistributeur.Water.MoneyRemove, true, true, 1)
                end
            end)
            RageUI.ButtonWithStyle(ConfigDistributeur.Payement.Banque, (ConfigDistributeur.Payement.BanquePaiement):format(ConfigDistributeur.Water.MoneyRemove), {RightLabel = "→→→"}, true, function(_,_,s)
                if s then
                    ESXCustomFD:AnimForTake(PlayerPedId(), LeProps)
                    TriggerServerEvent("ESXCustomDistributeur:removeMoney", ConfigDistributeur.Water.MoneyRemove, true, true, 2)
                end
            end)
        end, function()
        end)
  
        if not RageUI.Visible(menu) and not RageUI.Visible(menusub) then
            FreezeEntityPosition(PlayerPedId(), false)
            menu = RMenu:DeleteType('menu', true)
        end
    end
end

local function OpenCoffee(LeProps)
    local menu = RageUI.CreateMenu(ConfigDistributeur.Coffee.Title, ConfigDistributeur.Coffee.Subtitle)
    local menusub = RageUI.CreateSubMenu(menu, ConfigDistributeur.Coffee.Title, ConfigDistributeur.Coffee.Subtitle)
    RageUI.Visible(menu, not RageUI.Visible(menu))
    while menu do
        Wait(0)
        RageUI.IsVisible(menu, true, true, true, function()
            RageUI.ButtonWithStyle(ConfigDistributeur.Coffee.Bouton, ConfigDistributeur.Coffee.Desc, {RightLabel = (ConfigDistributeur.Coffee.RightLabel):format(ConfigDistributeur.Coffee.MoneyRemove)}, true, function(_,_,s)
            end, menusub)
        end, function()
        end)
  
        RageUI.IsVisible(menusub, true, true, true, function()
            RageUI.ButtonWithStyle(ConfigDistributeur.Payement.Liquide, (ConfigDistributeur.Payement.LiquidePaiement):format(ConfigDistributeur.Coffee.MoneyRemove), {RightLabel = "→→→"}, true, function(_,_,s)
                if s then
                    ESXCustomFD:AnimForTake(PlayerPedId(), LeProps)
                    TriggerServerEvent("ESXCustomDistributeur:removeMoney", ConfigDistributeur.Coffee.MoneyRemove, true, false, 1)
                end
            end)
            RageUI.ButtonWithStyle(ConfigDistributeur.Payement.Banque, (ConfigDistributeur.Payement.BanquePaiement):format(ConfigDistributeur.Coffee.MoneyRemove), {RightLabel = "→→→"}, true, function(_,_,s)
                if s then
                    ESXCustomFD:AnimForTake(PlayerPedId(), LeProps)
                    TriggerServerEvent("ESXCustomDistributeur:removeMoney", ConfigDistributeur.Coffee.MoneyRemove, true, false, 2)
                end
            end)
        end, function()
        end)
  
        if not RageUI.Visible(menu) and not RageUI.Visible(menusub) then
            FreezeEntityPosition(PlayerPedId(), false)
            menu = RMenu:DeleteType('menu', true)
        end
    end
end

local function OpenDistributeur(LeProps)
    local menu = RageUI.CreateMenu(ConfigDistributeur.Machine.Title, ConfigDistributeur.Machine.Subtitle)
    local menusub = RageUI.CreateSubMenu(menu, ConfigDistributeur.Machine.Title, ConfigDistributeur.Machine.Subtitle)
    RageUI.Visible(menu, not RageUI.Visible(menu))
    while menu do
        Wait(0)
        RageUI.IsVisible(menu, true, true, true, function()
            for k, v in pairs(ConfigDistributeur.Machine.Bouton) do
                RageUI.ButtonWithStyle(v.Name, v.Desc, {RightLabel = (v.RightLabel):format(v.Price)}, true, function(_,_,s)
                    if s then
                        Price = v.Price
                        ItemReward = v.ItemReward
                    end
                end, menusub)
            end
        end, function()
        end)
  
        RageUI.IsVisible(menusub, true, true, true, function()
            RageUI.ButtonWithStyle(ConfigDistributeur.Payement.Liquide, (ConfigDistributeur.Payement.LiquidePaiement):format(Price), {RightLabel = "→→→"}, true, function(_,_,s)
                if s then
                    ESXCustomFD:Machine(LeProps, Price, 1, ItemReward)
                end
            end)
            RageUI.ButtonWithStyle(ConfigDistributeur.Payement.Banque, (ConfigDistributeur.Payement.BanquePaiement):format(Price), {RightLabel = "→→→"}, true, function(_,_,s)
                if s then
                    ESXCustomFD:Machine(LeProps, Price, 2, ItemReward)
                end
            end)
        end, function()
        end)
  
        if not RageUI.Visible(menu) and not RageUI.Visible(menusub) then
            FreezeEntityPosition(PlayerPedId(), false)
            menu = RMenu:DeleteType('menu', true)
        end
    end
end

CreateThread(function()
    while true do
        local timer = 400

        local closestTank = GetClosestObjectOfType(GetEntityCoords(PlayerPedId()), 3.0, -742198632, false)
        if DoesEntityExist(closestTank) then
            local markerCoords = GetOffsetFromEntityInWorldCoords(closestTank, 0.0, -0.2, 1.0)
            local distanceCheck = #(GetEntityCoords(PlayerPedId()) - markerCoords)

            if distanceCheck <= ConfigDistributeur.Water.ZoneDist then
                timer = 0
                ESX.ShowHelpNotification(ConfigDistributeur.Water.HelpNotification)
                if IsControlJustPressed(1,51) then
                    OpenWater(markerCoords)
                end
            end
        end

        local closestTank2 = GetClosestObjectOfType(GetEntityCoords(PlayerPedId()), 3.0, 690372739, false)
        if DoesEntityExist(closestTank2) then
            local markerCoords2 = GetOffsetFromEntityInWorldCoords(closestTank2, 0.0, -0.2, 1.0)
            local distanceCheck2 = #(GetEntityCoords(PlayerPedId()) - markerCoords2)

            if distanceCheck2 <= ConfigDistributeur.Coffee.ZoneDist then
                timer = 0
                ESX.ShowHelpNotification(ConfigDistributeur.Coffee.HelpNotification)
                if IsControlJustPressed(1,51) then
                    OpenCoffee(markerCoords2)
                end
            end
        end

        for k, v in pairs(ConfigDistributeur.Machine.Props) do
            local closestTank3 = GetClosestObjectOfType(GetEntityCoords(PlayerPedId()), 3.0, v, false)
            if DoesEntityExist(closestTank3) then
                local markerCoords3 = GetOffsetFromEntityInWorldCoords(closestTank3, 0.0, -0.2, 1.0)
                local distanceCheck3 = #(GetEntityCoords(PlayerPedId()) - markerCoords3)
    
                if distanceCheck3 <= ConfigDistributeur.Machine.ZoneDist then
                    timer = 0
                    ESX.ShowHelpNotification(ConfigDistributeur.Machine.HelpNotification)
                    if IsControlJustPressed(1,51) then
                        OpenDistributeur(markerCoords3)
                    end
                end
            end
        end

        Wait(timer)
    end
end)

--Function ESXCustom
ESXCustomFD = {}
function ESXCustomFD:LoadDict(dict, anim)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
        RequestAnimDict(dict)
    end

    TaskPlayAnim(GetPlayerPed(-1), dict, anim, 8.0, 1.0, -1, 49, 0, false, false, false)
    RemoveAnimDict(dict)
end

function ESXCustomFD:Machine(LeProps, price, HowBuy, item)
    ESXCustomFD:AnimForTake(PlayerPedId(), LeProps, "mooved")
    TriggerServerEvent("ESXCustomDistributeur:removeMoney", price, false, false, HowBuy, item)
end

function ESXCustomFD:AnimForTake(LePed, LeProps, mooved)
    if mooved ~= nil then
        ESXCustomFD:MakeEntityFaceEntity(LePed, LeProps, 240.0)
    else
        ESXCustomFD:MakeEntityFaceEntity(LePed, LeProps)
    end
    ESXCustomFD:LoadDict("mini@sprunk", "plyr_buy_drink_pt1")
    FreezeEntityPosition(LePed, true)
    Wait(5000)
    FreezeEntityPosition(LePed, false)
    ClearPedTasksImmediately(LePed)
end

function ESXCustomFD:MakeEntityFaceEntity(entity1, entity2, headingPlus)
    if headingPlus == nil then headingPlus = 0 end
    local p1 = GetEntityCoords(entity1, true)
    local p2 = GetEntityCoords(entity2, true)

    local dx = p2.x - p1.x
    local dy = p2.y - p1.y

    local heading = GetHeadingFromVector_2d(dx, dy)
    SetEntityHeading(entity1, heading+headingPlus)
end