local EntraindeCree = false
local CooldownRecolte = false

CreateThread(function()
    count = 0
    for k,v in pairs(ConfigCraft.Craft) do
        count = count + 1
    end

    Wait(10000)

    while true do
        local timer = 200
        local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)

        for k, v in pairs(ConfigCraft.Craft) do
            if #v.RequiredJob == 0 then
                local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, v.Pose.x, v.Pose.y, v.Pose.z)
                if dist < ConfigCraft.Marker.MarkerDist then
                    timer = 0
                    DrawGlobalMarker(ConfigCraft.Marker.MarkerType, v.Pose.x, v.Pose.y, v.Pose.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ConfigCraft.Marker.Scale.x, ConfigCraft.Marker.Scale.y, ConfigCraft.Marker.Scale.z, ConfigCraft.Marker.Color.r, ConfigCraft.Marker.Color.g, ConfigCraft.Marker.Color.b, ConfigCraft.Marker.Color.a, ConfigCraft.Marker.BobUpAndDown, ConfigCraft.Marker.FaceCamera, p19, ConfigCraft.Marker.Rotate)
                    if dist < ConfigCraft.DistMenu then
                        if EntraindeCree ~= true then
                            ESX.ShowHelpNotification(ConfigCraft.Notification.HelpNotification["AccesCraft"])
                            if IsControlJustPressed(1,51) then
                                OpenMenu(v)
                            end
                        end
                    end
                end
            else
                for y, i in pairs(v.RequiredJob) do
                    if ESX.PlayerData ~= nil and ESX.PlayerData[v.Jobs].name ~= nil and ESX.PlayerData[v.Jobs].name == i then
                        local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, v.Pose.x, v.Pose.y, v.Pose.z)
                        if dist < ConfigCraft.Marker.MarkerDist then
                            timer = 0
                            DrawGlobalMarker(ConfigCraft.Marker.MarkerType, v.Pose.x, v.Pose.y, v.Pose.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ConfigCraft.Marker.Scale.x, ConfigCraft.Marker.Scale.y, ConfigCraft.Marker.Scale.z, ConfigCraft.Marker.Color.r, ConfigCraft.Marker.Color.g, ConfigCraft.Marker.Color.b, ConfigCraft.Marker.Color.a, ConfigCraft.Marker.BobUpAndDown, ConfigCraft.Marker.FaceCamera, p19, ConfigCraft.Marker.Rotate)
                            if dist < ConfigCraft.DistMenu then
                                if EntraindeCree ~= true then
                                    ESX.ShowHelpNotification(ConfigCraft.Notification.HelpNotification["AccesCraft"])
                                    if IsControlJustPressed(1,51) then
                                        OpenMenu(v)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        Wait(timer)
    end
end)

CreateThread(function()
    Wait(10000)
    while true do
        local timer = 200
        local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)

        for k,v in pairs(ConfigCraft.Farm) do
            if #v.RequiredJob == 0 then
                local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, v.Pose.x, v.Pose.y, v.Pose.z)
                if dist < ConfigCraft.Marker.MarkerDist then
                    timer = 0
                    DrawGlobalMarker(ConfigCraft.Marker.MarkerType, v.Pose.x, v.Pose.y, v.Pose.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ConfigCraft.Marker.Scale.x, ConfigCraft.Marker.Scale.y, ConfigCraft.Marker.Scale.z, ConfigCraft.Marker.Color.r, ConfigCraft.Marker.Color.g, ConfigCraft.Marker.Color.b, ConfigCraft.Marker.Color.a, ConfigCraft.Marker.BobUpAndDown, ConfigCraft.Marker.FaceCamera, p19, ConfigCraft.Marker.Rotate)
                    if dist < ConfigCraft.DistMenu then
                        if not CooldownRecolte then
                            ESX.ShowHelpNotification((ConfigCraft.Notification.HelpNotification["AccesFarm"]):format(v.Label))
                            if IsControlJustPressed(1,51) then
                                ESXCustom_Function_ClientSide:LoadDict('random@domestic')
                                TaskPlayAnim(PlayerPedId(), 'random@domestic', 'pickup_low', 8.0, 1.0, 1000, 16, 0.0, false, false, false)

                                CooldownRecolte = true
                                Citizen.SetTimeout(v.TimerWait, function()
                                    TriggerServerEvent("CorePickax:CraftRecolte", v.ItemReward, v.amount, v.Pose)
                                    CooldownRecolte = false
                                end)
                            end
                        end
                    end
                end
            else
                for y, i in pairs(v.RequiredJob) do
                    if ESX.PlayerData ~= nil and ESX.PlayerData[v.Jobs].name ~= nil and ESX.PlayerData[v.Jobs].name == i then
                        local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, v.Pose.x, v.Pose.y, v.Pose.z)
                        if dist < ConfigCraft.Marker.MarkerDist then
                            timer = 0
                            DrawGlobalMarker(ConfigCraft.Marker.MarkerType, v.Pose.x, v.Pose.y, v.Pose.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ConfigCraft.Marker.Scale.x, ConfigCraft.Marker.Scale.y, ConfigCraft.Marker.Scale.z, ConfigCraft.Marker.Color.r, ConfigCraft.Marker.Color.g, ConfigCraft.Marker.Color.b, ConfigCraft.Marker.Color.a, ConfigCraft.Marker.BobUpAndDown, ConfigCraft.Marker.FaceCamera, p19, ConfigCraft.Marker.Rotate)
                            if dist < ConfigCraft.DistMenu then
                                if not CooldownRecolte then
                                    ESX.ShowHelpNotification((ConfigCraft.Notification.HelpNotification["AccesFarm"]):format(v.Label))
                                    if IsControlJustPressed(1,51) then
                                        ESXCustom_Function_ClientSide:LoadDict('random@domestic')
                                        TaskPlayAnim(PlayerPedId(), 'random@domestic', 'pickup_low', 8.0, 1.0, 1000, 16, 0.0, false, false, false)

                                        CooldownRecolte = true
                                        Citizen.SetTimeout(v.TimerWait, function()
                                            TriggerServerEvent("CorePickax:CraftRecolte", v.ItemReward, v.amount, v.Pose)
                                            CooldownRecolte = false
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        Wait(timer)
    end
end)

function ReloadItemPlayer()
    if ConfigCraft.Trigger.ESX then
        ESX.PlayerData = ESX.ESX.PlayerData
    end
end

local function OpenMenu(v)
    ReloadItemPlayer()
    count = 0
    ItemToCraft = v.ItemNameToCraft
    GoodJob = v.Pose

    local menu = RageUI.CreateMenu(ConfigCraft.Notification.Menu["Title"], ConfigCraft.Notification.Menu["SubTitle"])
    RageUI.Visible(menu, not RageUI.Visible(menu))
    while menu do
        Wait(0)
        RageUI.IsVisible(menu, true, true, true, function()
            for i = 1, #ConfigCraft.ItemCraft[ItemToCraft], 1 do
                RageUI.ButtonWithStyle(ConfigCraft.ItemCraft[ItemToCraft][i].ItemLabel, ConfigCraft.ItemCraft[ItemToCraft][i].Desc, {RightLabel = (ConfigCraft.Notification.Menu["TimeWaitLabel"]):format(ConfigCraft.ItemCraft[ItemToCraft][i].TimeToWait /1000)}, true, function(_,_,s)
                    if s then
                        RageUI.CloseAll()
                        for k, v in pairs(ConfigCraft.ItemCraft[ItemToCraft][i].required) do
                            local test, item, amountItemRequire = check(v.name, v.amount, v.label)

                            if test == true then
                                count = count + 1

                                if #ConfigCraft.ItemCraft[ItemToCraft][i].required == count then
                                    EntraindeCree = true
                                    FreezeEntityPosition(PlayerPedId(), true)
                                    TaskStartScenarioInPlace(PlayerPedId(), "PROP_HUMAN_BUM_BIN", 0, true)
                                    Citizen.SetTimeout(ConfigCraft.ItemCraft[ItemToCraft][i].TimeToWait, function()
                                        ClearPedTasksImmediately(PlayerPedId())
                                        EntraindeCree = false
                                        FreezeEntityPosition(PlayerPedId(), false)
                                        TriggerServerEvent("CorePickax:CraftItem", ConfigCraft.ItemCraft[ItemToCraft][i].ItemLabel, ConfigCraft.ItemCraft[ItemToCraft][i].ItemName, ConfigCraft.ItemCraft[ItemToCraft][i].RewardsAmountItem, GoodJob, ConfigCraft.ItemCraft[ItemToCraft][i].required)
                                    end)
                                end
                            else
                                Notification((ConfigCraft.Notification["NeedItem"]):format(v.label, v.amount))
                            end
                        end
                    end
                end)
            end
        end, function()
        end)
  
        if not RageUI.Visible(menu) then
            menu = RMenu:DeleteType('menu', true)
        end
    end
end

function check(Item, amount, Label)
    for i = 1, #ESX.PlayerData.inventory, 1 do
        if ESX.PlayerData.inventory[i].name == Item and ESX.PlayerData.inventory[i].count >= amount then
            return true
        end
    end

    return false, Label, amount
end