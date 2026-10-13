local uiFaded = false
local ESX = exports["es_extended"]:getSharedObject()

Citizen.CreateThread(function()
    while ESX == nil do
        ESX = exports["es_extended"]:getSharedObject()
        Citizen.Wait(5)
    end

    while ESX.GetPlayerData() == nil do
		Citizen.Wait(10)
	end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

	ESX.PlayerData = ESX.GetPlayerData()

    local money, black_money, bank = 0, 0, 0
    for i = 1, #ESX.PlayerData.accounts, 1 do
        if ESX.PlayerData.accounts[i].name == 'money' then
            money = ESX.Math.GroupDigits(ESX.PlayerData.accounts[i].money) .. ' $'
        elseif ESX.PlayerData.accounts[i].name == 'black_money' then
            black_money = ESX.Math.GroupDigits(ESX.PlayerData.accounts[i].money) .. ' $'
        elseif ESX.PlayerData.accounts[i].name == 'bank' then
            bank = ESX.Math.GroupDigits(ESX.PlayerData.accounts[i].money) .. ' $'
        end
    end

    while not FirstActivate do 
        Wait(2000)
        SendNUIMessage({
            action = 'setInfos',
            infos = {
                {
                    name = 'money',
                    value = money
                },
                {
                    name = 'black_money',
                    value = black_money
                },
                {
                    name = 'bank',
                    value = bank
                }
            }
        })

        local playerIdHUD = GetPlayerServerId(PlayerId())

        SendNUIMessage({
            action = 'setId',
            value = playerIdHUD
        })
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    local money, black_money, bank = 0, 0, 0

    for i = 1, #xPlayer.accounts, 1 do
        if xPlayer.accounts[i].name == 'money' then
            money = ESX.Math.GroupDigits(xPlayer.accounts[i].money) .. ' $'
        elseif xPlayer.accounts[i].name == 'black_money' then
            black_money = ESX.Math.GroupDigits(xPlayer.accounts[i].money) .. ' $'
        elseif xPlayer.accounts[i].name == 'bank' then
            bank = ESX.Math.GroupDigits(xPlayer.accounts[i].money) .. ' $'
        end
    end

    SendNUIMessage({
        action = 'setInfos',
        infos = {
            {
                name = 'money',
                value = money
            },
            {
                name = 'black_money',
                value = black_money
            },
            {
                name = 'bank',
                value = bank
            }
        }
    })

    local playerIdHUD = GetPlayerServerId(PlayerId())

    SendNUIMessage({
        action = 'setId',
        value = playerIdHUD
    })
end)

RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account)
    local value = ESX.Math.GroupDigits(account.money) .. ' $'

    if account.name == 'black_money' then
        SendNUIMessage({
            action = 'setInfos',
            infos = {
                {
                    name = 'black_money',
                    value = value
                }
            }
        })
    elseif account.name == 'bank' then
        SendNUIMessage({
            action = 'setInfos',
            infos = {
                {
                    name = 'bank',
                    value = value
                }
            }
        })
    elseif account.name == 'money' then
        SendNUIMessage({
            action = 'setInfos',
            infos = {
                {
                    name = 'money',
                    value = value
                }
            }
        })
    end
end)

AddEventHandler('tempui:toggleUi', function(value)
    uiFaded = value

    if uiFaded then
        SendNUIMessage({action = 'fadeUi', value = true})
    else
        SendNUIMessage({action = 'fadeUi', value = false})
    end
end)

RegisterNUICallback('firstactivate', function()
    FirstActivate = true
end)

Citizen.CreateThread(function()
    local uiComponents = {'infos', 'statuts'}
    local inFrontend = false

    SendNUIMessage({action = 'hideUi', value = false})

    for i = 1, #uiComponents, 1 do
        SendNUIMessage({action = 'hideComponent', component = uiComponents[i], value = false})
    end

    while true do
        Citizen.Wait(250)

        if not uiFaded then
            if IsPauseMenuActive() or IsPlayerSwitchInProgress() then
                if not inFrontend then
                    inFrontend = true
                    SendNUIMessage({action = 'hideUi', value = true})
                end
            else
                if inFrontend then
                    inFrontend = false
                    SendNUIMessage({action = 'hideUi', value = false})
                end
            end
        end
    end
end)


c = "~r~"

local AnnounceTime = 5

RegisterNetEvent('admin:bscripts:scaleform')
AddEventHandler('admin:bscripts:scaleform', function(title, msg)
    displayOnScreen(title, msg)
end)

function displayOnScreen(title, msg)
	PlaySoundFrontend(-1, "DELETE","HUD_DEATHMATCH_SOUNDSET", 1)

	local time = 0

    local function setcountdown(x) time = GetGameTimer() + x*1000 end
    local function getcountdown() return math.floor((time-GetGameTimer())/1000) end
    
    setcountdown(AnnounceTime)

    while getcountdown() > 0 do
        Citizen.Wait(1)
		local scaleform = Initialize("mp_big_message_freemode", title, msg)
		DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
    end
end

function Initialize(scaleform, title, msg)
    local scaleform = RequestScaleformMovie(scaleform)
    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(1)
    end
    PushScaleformMovieFunction(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
	PushScaleformMovieFunctionParameterString("~c~"..c..''..title) -- Titre de l'annonce
    PushScaleformMovieFunctionParameterString(msg) -- Message de l'annonce
	PopScaleformMovieFunctionVoid()
    return scaleform
end

local lift = {
    teleport = {
        [0] =  {pos = vector3(251.1221, -324.2676, 40.03955), name = "Garages"},
        [1] =  {pos = vector3(251.1219, -324.2676, 45.54939), name = "Rez de chaussé"},
        [2] =  {pos = vector3(250.9761, -324.3932, 50.44616), name = "Étage 1"},
        [3] =  {pos = vector3(250.8736, -324.3594, 55.34293), name = "Étage 2"},
        [4] =  {pos = vector3(250.8733, -324.3594, 60.00903), name = "Étage 3"},
        [5] =  {pos = vector3(258.2163, -315.0601, 60.00793), name = "Toit"},
    },
}

local function openMenuLSPD(select)
    local mainMenu = CoraUI.CreateMenu("Ascenseur", "")

    CoraUI.Visible(mainMenu, not CoraUI.Visible(mainMenu))

    while mainMenu do
        Wait(1)
        CoraUI.IsVisible(mainMenu, function()
            for k,v in pairs(lift.teleport) do
                CoraUI.Button(v.name, nil, {RightLabel =  ""}, v.pos ~= select.pos, {
                    onSelected = function ()
                        SetEntityCoordsNoOffset(PlayerPedId(), v.pos)
                        SetEntityHeading(PlayerPedId(), 33.0)
                        ESX.ShowNotification("Vous êtes bien arrivé a l'étage "..v.name)
                        CoraUI.CloseAll()
                    end
                })
            end
        end)

        if not CoraUI.Visible(mainMenu) then
            mainMenu = RMenu:DeleteType("menu", true)
        end
    end
end

CreateThread(function()
    while true do
        local waiting = 250
        local myCoords = GetEntityCoords(PlayerPedId())

        for k,v in pairs(lift.teleport) do
            if #(myCoords-v.pos) < 1.0 then
                waiting = 1
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ~o~choisir votre étage~s~.")
                if IsControlJustReleased(0, 54) then
                    openMenuLSPD(v)
                end
            end
        end

        Wait(waiting)
    end
end)