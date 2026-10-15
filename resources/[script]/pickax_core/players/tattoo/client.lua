local Tatouage = {}
local playerTatoos = {}
local currentPreviewTatoo = nil
local cleaning = false
RegisterNetEvent("CorePickax:buyTattoo")
AddEventHandler("CorePickax:buyTattoo", function(ok)
    if ok then
        ESX.ShowNotification("~g~Tatouage acheté")
    else
        ESX.ShowNotification("~r~Vous n'avez pas les fonds nécéssaires.~s~")
    end
end)

RegisterNetEvent("CorePickax:tatoesCallback")
AddEventHandler("CorePickax:tatoesCallback", function(ok)
    if ok ~= nil then
        playerTatoos = json.decode(ok)
        ClearPedDecorations(PlayerPedId())
        for _,t in pairs(playerTatoos) do
            AddPedDecorationFromHashes(PlayerPedId(),t.cat,t.name) 
        end
    end
end)

local firstLoad = false

AddEventHandler("skinchanger:loadSkin", function(skin)
	if not firstLoad then
		Citizen.CreateThread(function()
			while not GetEntityModel(PlayerPedId() == `mp_m_freemode_01` or GetEntityModel(PlayerPedId()) == `mp_f_freemode_01`) do
				Citizen.Wait(10)
			end

			Citizen.Wait(75)
			TriggerServerEvent("CorePickax:requestPlayerTatoos")
		end)
		
		firstLoad = true
	else
		Citizen.Wait(75)

		for _,t in pairs(playerTatoos) do
			AddPedDecorationFromHashes(PlayerPedId(),t.cat,t.name) 
		end
	end
end)

RegisterNetEvent("CorePickax:clean")
AddEventHandler("CorePickax:clean", function(ok)
    if ok then
        playerTatoos = {}
        DoScreenFadeOut(1000)
        while not IsScreenFadedOut() do Citizen.Wait(10) end
        ClearPedDecorations(PlayerPedId())
        Citizen.Wait(200)
        DoScreenFadeIn(1000)
        cleaning = false
        ESX.ShowNotification("~g~Tous vos tatouages ont étés effacés")
    else
        ESX.ShowNotification("~r~Vous n'avez pas les fonds nécéssaires.~s~")
    end
end)

RMenu.Add('tattoo', 'main', RageUI.CreateMenu("Tatoueur", "Que voulez-vous faire ?"))
for k,v in pairs(ConfigTattooShop.TattooCategories) do
    RMenu.Add('tattoo', 'part'..k, RageUI.CreateSubMenu(RMenu:Get('tattoo', 'main'), "Tatoueur", "Que voulez-vous faire ?"))
    RMenu:Get('tattoo', 'part'..k).Closed = function()
        ClearPedDecorations(PlayerPedId())
        for _,t in pairs(playerTatoos) do
            ApplyPedOverlay(PlayerPedId(),t.cat,t.name) 
        end
    end
end

RMenu:Get('tattoo', 'main').EnableMouse = false
RMenu:Get('tattoo', 'main').Closed = function()
    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
        local isMale = skin.sex == 0
        TriggerEvent('skinchanger:loadDefaultModel', isMale, function()
            ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
            TriggerEvent('skinchanger:loadSkin', skin)
            TriggerEvent('esx:restoreLoadout')
            end)
        end)
    end)
    ClearPedDecorations(PlayerPedId())
    for _,t in pairs(playerTatoos) do
        ApplyPedOverlay(PlayerPedId(),t.cat,t.name) 
    end
    FreezeEntityPosition(GetPlayerPed(-1), false)
    Tatouage.Menu = false 
end

function OpenTattooRageUIMenu()
    if Tatouage.Menu then
        Tatouage.Menu = false
    else
        Tatouage.Menu = true
        RageUI.Visible(RMenu:Get('tattoo', 'main'), true)

        Citizen.CreateThread(function()
			while Tatouage.Menu do
                FreezeEntityPosition(GetPlayerPed(-1), true)
                RageUI.IsVisible(RMenu:Get('tattoo', 'main'), true, false, true, function()
    
                    for k,v in pairs(ConfigTattooShop.TattooCategories) do
                        RageUI.ButtonWithStyle(v.name, nil, { RightLabel = "→" }, true, function()
                        end, RMenu:Get('tattoo', 'part'..k))
                    end
                    RageUI.ButtonWithStyle("~g~Effacer tous mes tatouages", nil, { RightLabel = "~g~500$ ~s~→" }, not cleaning, function(Hovered, Active, Selected)
                        if (Selected) then
                            cleaning = true
                            TriggerServerEvent("CorePickax:payClean", 500)
                        end
                    end)
                end)
                for k,v in pairs(ConfigTattooShop.TattooCategories) do
                    RageUI.IsVisible(RMenu:Get('tattoo', 'part'..k), true, false, true, function()
                        RageUI.ButtonWithStyle("~g~Supprimer la prévisualisation actuelle", nil, { RightLabel = "→" }, true, function(Hovered, Active, Selected)
                            if (Selected) then
                                ClearPedDecorations(PlayerPedId())
                                for _,t in pairs(playerTatoos) do
                                    ApplyPedOverlay(PlayerPedId(),t.cat,t.name) 
                                end
                            end
                        end)
                        for index,tatoo in pairs(ConfigTattooShop.TattooList[v.value]) do
                            RageUI.ButtonWithStyle("Tatouage n°"..index, nil, { RightLabel = "~g~"..tatoo.price.."$ ~s~→" }, true, function(Hovered, Active, Selected)
                                if (Active) then
                                    if currentPreviewTatoo ~= GetHashKey(tatoo.nameHash) then 
                                        ClearPedDecorations(PlayerPedId())
                                        for _,t in pairs(playerTatoos) do
                                            ApplyPedOverlay(PlayerPedId(),t.cat,t.name) 
                                        end
                                        ApplyPedOverlay(PlayerPedId(),GetHashKey(ConfigTattooShop.TattooCategories[k].value),GetHashKey(tatoo.nameHash)) 
                                    end
                                    currentPreviewTatoo = GetHashKey(tatoo.nameHash)
                                end
                                if (Selected) then
                                    local needModif = true
                                    for _,t in pairs(playerTatoos) do
                                        if GetHashKey(ConfigTattooShop.TattooCategories[k].value) == playerTatoos.cat and GetHashKey(tatoo.nameHash) == playerTatoos.name then
                                            needModif = false
                                        end
                                    end
                                    if needModif then
                                        table.insert(playerTatoos, {cat = GetHashKey(ConfigTattooShop.TattooCategories[k].value), name = GetHashKey(tatoo.nameHash)})
                                        TriggerServerEvent("CorePickax:pay", tatoo.price, playerTatoos)
                                    else
                                        ESX.ShowNotification("~g~Vous possédez déjà ce tatouage!")
                                    end
                                end
                            end)
                        end
                    end)
                end
				Wait(0)
			end
		end) 
	end
end

Citizen.CreateThread(function()
    while true do
        att = 500
        local pCoords = GetEntityCoords(PlayerPedId())
        for k, v in pairs(ConfigTattooShop.Position) do
            if not Tatouage.Menu then
                if #(pCoords-v.pos) < ConfigTattooShop.Marker.Distance then
                    att = 1
                    DrawGlobalMarker(ConfigTattooShop.Marker.MarkerType, v.pos.x, v.pos.y, v.pos.z-ConfigTattooShop.Marker.MarkerDebug, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, ConfigTattooShop.Marker.Scale.x, ConfigTattooShop.Marker.Scale.y, ConfigTattooShop.Marker.Scale.z, ConfigTattooShop.Marker.Color.r, ConfigTattooShop.Marker.Color.g, ConfigTattooShop.Marker.Color.b, ConfigTattooShop.Marker.Color.a, ConfigTattooShop.Marker.BobUpAndDown, ConfigTattooShop.Marker.FaceCamera, p19, ConfigTattooShop.Marker.Rotate)

                    if #(pCoords-v.pos) < ConfigTattooShop.Marker.PushEDistance then
                        ESX.ShowHelpNotification(ConfigTattooShop.Marker.PushEText)
                        if IsControlJustPressed(0, 51) then
                            if GetEntityModel(GetPlayerPed(-1)) == GetHashKey("mp_m_freemode_01") then
                                SetPedComponentVariation(GetPlayerPed(-1), 8, 15, 0, 2)
                                SetPedComponentVariation(GetPlayerPed(-1), 11, 15, 0, 2)
                                SetPedComponentVariation(GetPlayerPed(-1), 3, 15)
                                SetPedComponentVariation(GetPlayerPed(-1), 4, 14, 0, 2)
                                SetPedComponentVariation(GetPlayerPed(-1), 6, 43, 0, 2)
                                SetPedComponentVariation(ped, componentId, drawableId, textureId, paletteId)
                            else
                                SetPedComponentVariation(GetPlayerPed(-1), 8, 14, 0, 2) --tshirt
                                SetPedComponentVariation(GetPlayerPed(-1), 11, 15, 0, 2) --torse
                                SetPedComponentVariation(GetPlayerPed(-1), 3, 15) -- bras
                                SetPedComponentVariation(GetPlayerPed(-1), 4, 15, 0, 2) --jambe
                                SetPedComponentVariation(GetPlayerPed(-1), 6, 41, 0, 2) --chaussure
                            end
                            OpenTattooRageUIMenu()
                        end
                    end
                end
            end
        end
        Citizen.Wait(att)
    end
end)