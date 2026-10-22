local treasure = nil
local blip = nil
local LastWin = nil

RegisterNetEvent('CorePickax:StartEventChasse', function()
    local random = math.random(1, #ConfigChasseAuTresor.CoffreTresor)
    local coordChest = vector3(ConfigChasseAuTresor.CoffreTresor[random].x, ConfigChasseAuTresor.CoffreTresor[random].y, ConfigChasseAuTresor.CoffreTresor[random].z)
    treasure = CreateObject("xm_prop_x17_chest_closed", coordChest, false, false, false)
    PlaceObjectOnGroundProperly(treasure)

    blip = AddBlipForCoord(coordChest)
    SetBlipSprite(blip, ConfigChasseAuTresor.Blips.Sprite)
    SetBlipColour(blip, ConfigChasseAuTresor.Blips.Colour)
    SetBlipScale(blip, 0.5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(ConfigChasseAuTresor.Blips.Name)
    EndTextCommandSetBlipName(blip)

    ESX.ShowNotification(ConfigChasseAuTresor.Notification["EventStart"])
    
    CreateThread(function()
        while true do
            local timer = 200
            local ped = PlayerPedId()
            local mycords = GetEntityCoords(ped)
            
            if GetDistanceBetweenCoords(mycords, coordChest, true) < ConfigChasseAuTresor.distance + 3.0 then
                timer = 0

                if GetDistanceBetweenCoords(mycords, coordChest, true) < ConfigChasseAuTresor.distance then
                    ESX.ShowHelpNotification(ConfigChasseAuTresor.Notification["PressE"])
                    if IsControlJustReleased(0, 38) then
                        Citizen.Wait(500)
                        if ConfigChasseAuTresor.WinJustMoney then
                            TriggerEvent('CorePickax:anim', coordChest)
                            Citizen.Wait(5000)
                            TriggerServerEvent('CorePickax:ReceiveMoney', coordChest)
                            Citizen.Wait(2000)
                            break
                        else
                            local itemormoney = math.random(1, 2)
                            if itemormoney == 1 then
                                TriggerEvent('CorePickax:anim', coordChest)
                                Citizen.Wait(5000)
                                TriggerServerEvent('CorePickax:ReceiveItem', coordChest)
                                Citizen.Wait(2000)
                                break
                            elseif itemormoney == 2 then
                                TriggerEvent('CorePickax:anim', coordChest)
                                Citizen.Wait(5000)
                                TriggerServerEvent('CorePickax:ReceiveMoney', coordChest)
                                Citizen.Wait(2000)
                                break
                            end
                        end
                    end
                end
            end
            Citizen.Wait(timer)
        end
    end)
end)

RegisterNetEvent('CorePickax:StopEvent', function()
    if LastWin ~= GetPlayerServerId(PlayerId()) then
        ESX.ShowNotification(ConfigChasseAuTresor.Notification["EventStop"])
    end
end)
   
RegisterNetEvent('CorePickax:anim', function(coordChest)
    local playerPed = PlayerPedId()
    local animDict = "anim@treasurehunt@doubleaction@action"
    local animName = "double_action_pickup"
    LastWin = GetPlayerServerId(PlayerId())

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
    Citizen.Wait(0)
    end

    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 0, 0, false, false, false)

    Citizen.Wait(5000)
    DeleteObject(treasure)
    treasure = CreateObject("xm_prop_x17_chest_open", coordChest, false, false, false)
    Citizen.Wait(1000)

    ClearPedTasksImmediately(playerPed)
    ClearPedTasks(playerPed)

    Citizen.Wait(1000)
    DeleteObject(treasure)
    treasure = nil
    RemoveBlip(blip)
    blip = nil

    TriggerServerEvent("CorePickax:SendServerSideChasse")
end)