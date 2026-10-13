local UNARMED = `WEAPON_UNARMED`

local ProtectedPlayers = {}
local IsProtected = false

RegisterNetEvent('newplayer:syncProtection', function(list)
    ProtectedPlayers = list or {}

    local myServerId = GetPlayerServerId(PlayerId())
    IsProtected = ProtectedPlayers[myServerId] == true
end)

RegisterNetEvent('newplayer:setProtection', function(serverId, protected)
    if protected then
        ProtectedPlayers[serverId] = true
    else
        ProtectedPlayers[serverId] = nil
    end

    if serverId == GetPlayerServerId(PlayerId()) then
        IsProtected = protected == true
    end
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('newplayer:requestSync')
end)

local function drawNewPlayerBadge(coords)
    if not ConfigNewPlayer.BadgeEnabled then
        return
    end

    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)

    if not onScreen then
        return
    end

    if ConfigNewPlayer.ShowLogo then
        local color = ConfigNewPlayer.LogoColor

        DrawRect(
            x,
            y,
            ConfigNewPlayer.LogoWidth,
            ConfigNewPlayer.LogoHeight,
            color.r,
            color.g,
            color.b,
            color.a
        )
    end

    if ConfigNewPlayer.ShowBadgeText then
        local color = ConfigNewPlayer.BadgeTextColor

        SetTextFont(4)
        SetTextScale(0.0, ConfigNewPlayer.BadgeTextScale)
        SetTextCentre(true)
        SetTextColour(color.r, color.g, color.b, color.a)
        SetTextOutline()

        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(ConfigNewPlayer.BadgeText)
        EndTextCommandDisplayText(x, y - 0.011)
    end

    if ConfigNewPlayer.ShowBadgeLabel then
        local color = ConfigNewPlayer.BadgeLabelColor

        SetTextFont(4)
        SetTextScale(0.0, ConfigNewPlayer.BadgeLabelScale)
        SetTextCentre(true)
        SetTextColour(color.r, color.g, color.b, color.a)
        SetTextOutline()

        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(ConfigNewPlayer.BadgeLabel)
        EndTextCommandDisplayText(x, y + 0.019)
    end
end

CreateThread(function()
    while true do
        local sleep = 1000

        if ConfigNewPlayer.BadgeEnabled then
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)

            for _, player in ipairs(GetActivePlayers()) do
                local serverId = GetPlayerServerId(player)

                if ProtectedPlayers[serverId] then
                    local ped = GetPlayerPed(player)

                    if DoesEntityExist(ped) then
                        local coords = GetEntityCoords(ped)
                        local distance = #(myCoords - coords)

                        if distance <= ConfigNewPlayer.BadgeDistance then
                            sleep = 0

                            local headCoords = GetPedBoneCoords(ped, 0x796E, 0.0, 0.0, 0.0)

                            drawNewPlayerBadge(vector3(
                                headCoords.x,
                                headCoords.y,
                                headCoords.z + ConfigNewPlayer.BadgeHeight
                            ))
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        if ConfigNewPlayer.BlockWeapons and IsProtected then
            Wait(0)

            local ped = PlayerPedId()

            if GetSelectedPedWeapon(ped) ~= UNARMED then
                SetCurrentPedWeapon(ped, UNARMED, true)
            end

            DisablePlayerFiring(PlayerId(), true)

            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 45, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 143, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 264, true)
        else
            Wait(750)
        end
    end
end)
