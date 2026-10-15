Player = {}
Citizen.CreateThread(function()
    ESX.PlayerData = ESX.GetPlayerData()
	Player.WeaponData = ESX.GetWeaponList()

    while ESX.PlayerData == nil do
		Wait(1)
	end

    for i = 1, #Player.WeaponData, 1 do
		if Player.WeaponData[i].name == 'WEAPON_UNARMED' then
			Player.WeaponData[i] = nil
		else
			Player.WeaponData[i].hash = GetHashKey(Player.WeaponData[i].name)
		end
    end
end)

CoffreVeh = {
    Item = true, 
    Weapon = false, 
    Money = false,

    ItemR = true, 
    WeaponR = false, 
    MoneyR = false,
    IndexDeposit = 1,
    IndexRemove = 1
}

Data = {}

OpenCoffreVeh = function(CorrdVeh, plate, model, class)
    Data["items"] = nil 
    Data["weapons"] = nil 
    Data["accounts"] = nil
    local maincoffre = RageUI.CreateMenu("Coffre du véhicule", "Voici le coffre du véhicule")
    local depositincoffre = RageUI.CreateSubMenu(maincoffre, "Déposer", "Voici les actions disponibles")
    local retirerincoffre = RageUI.CreateSubMenu(maincoffre, "Retirer", "Voici les objets disponibles")
    TriggerServerEvent("ESXCustomCoffre:recievecoffrevehserverside", plate)
    RageUI.Visible(maincoffre, not RageUI.Visible(maincoffre))
    Info = {
        weight = nil
    }

    while maincoffre do 
        Wait(0)
        if #(GetEntityCoords(PlayerPedId()) - CorrdVeh) > 5 then 
            ESX.ShowNotification("~r~Information\n~s~Vous vous éloignez de trop.")
            RageUI.CloseAll()
        end
        if IsPedSittingInAnyVehicle(PlayerPedId()) then 
            ESX.ShowNotification("~r~Information\n~s~Vous êtes montez dans un véhicule")
            RageUI.CloseAll()
        end
        RageUI.IsVisible(maincoffre, true, true, true, function()
            RageUI.ButtonWithStyle("Déposer du stock", "Vous permet de déposer vos items dans le coffre", {RightLabel = "→→→"}, true, function()
            end, depositincoffre)
            RageUI.ButtonWithStyle("Accéder au stock", "Vous permet d'accéder au stock du véhicule", {RightLabel = "→→→"}, true, function()
            end, retirerincoffre)
        end, function()
        end)

        RageUI.IsVisible(depositincoffre, true, true, true, function()
            ESX.PlayerData = ESX.GetPlayerData()

            -- if Info.weight ~= nil then
            --     RageUI.Separator("Contenu du coffre: ~b~"..ESX.Math.Round(Info.weight, 1).."kg / "..Info.maxweight.."kg ")
            -- else
            --     RageUI.Separator("Contenu du coffre: ~b~ 0 kg / "..tostring(ConfigVehicleCoffre.WeightWeh[class]).."kg ")
            -- end

            for i = 1, #ESX.PlayerData.accounts, 1 do
                if ESX.PlayerData.accounts[i].name == ConfigVehicleCoffre.Money.money  then
                    -- RageUI.Separator('Argent : ~g~'..ESX.PlayerData.accounts[i].money.."$")
                    Argent = ESX.PlayerData.accounts[i].money
                end
            end
            for i = 1, #ESX.PlayerData.accounts, 1 do
                if ESX.PlayerData.accounts[i].name == ConfigVehicleCoffre.Money.argentsale  then
                    -- RageUI.Separator('Argent non déclaré: ~r~'..ESX.PlayerData.accounts[i].money.."$")
                    ArgentSale = ESX.PlayerData.accounts[i].money
                end
            end
            if Info.weight ~= nil then
                RageUI.Info("Informations :", {"\nContenu du coffre: ~b~ "..ESX.Math.Round(Info.weight, 1).." kg / "..tostring(ConfigVehicleCoffre.WeightWeh[class]).."kg~s~\nArgent : ~g~"..Argent.."$~s~\nArgent non déclaré: ~r~"..ArgentSale.."$"}, {"", "", "", ""})
            else
                RageUI.Info("Informations :", {"\nContenu du coffre: ~b~ 0 kg / "..tostring(ConfigVehicleCoffre.WeightWeh[class]).."kg~s~\nArgent : ~g~"..Argent.."$~s~\nArgent non déclaré: ~r~"..ArgentSale.."$"}, {"", "", "", ""})
            end

            RageUI.List("Filtre", {"Items", "Armes", "Argent"}, CoffreVeh.IndexDeposit, nil, {}, true, function(Hovered, Active, Selected, Index)
                CoffreVeh.IndexDeposit = Index

                if Index == 1 then 
                    CoffreVeh.Item, CoffreVeh.Weapon, CoffreVeh.Money = true, false, false 
                elseif Index == 2 then 
                    CoffreVeh.Item, CoffreVeh.Weapon, CoffreVeh.Money = false, true, false 
                elseif Index == 3 then 
                    CoffreVeh.Item, CoffreVeh.Weapon, CoffreVeh.Money = false, false, true 
                end
            end)

            if CoffreVeh.Item then 
                RageUI.Separator("↓ Items ↓")
                for k, v in pairs(ESX.PlayerData.inventory) do 
                    if v.count > 0 then 
                        RageUI.ButtonWithStyle(""..v.label..' [x'..v.count.."]", nil, {RightLabel = "~g~Déposer"}, true, function(_, _, s)
                            if s then
                                local check, count = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput("Combien voulez vous deposer ?", 15))
                                if check then 
                                    if v.count >= count then 
                                        TriggerServerEvent("ESXCustomCoffre:actionsitemveh", plate, class, "deposit", count, v.name)
                                    else
                                        ESX.ShowNotification("Vous ne disposez pas d'assser de ~r~"..v.label.." ~s~pour faire cela")
                                    end
                                else
                                    ESX.ShowNotification("Veuillez entrez des chiffres")
                                end
                            end
                        end)
                    end
                end
            end

            if CoffreVeh.Weapon then 
                if #Player.WeaponData > 0 then 
                    RageUI.Separator("↓ Armes ↓")
                    for i = 1, #Player.WeaponData, 1 do
                        if HasPedGotWeapon(PlayerPedId(), Player.WeaponData[i].hash, false) then
                            local ammo = GetAmmoInPedWeapon(PlayerPedId(), Player.WeaponData[i].hash)
                            if Config.ArmesPerm[Player.WeaponData[i].name] then
                                RageUI.ButtonWithStyle(""..Player.WeaponData[i].label, nil, { RightLabel = "Munition(s) : ~r~x"..ammo.."~s~"}, false, function(_,_,s)
                                end)
                            else
                                RageUI.ButtonWithStyle(""..Player.WeaponData[i].label, nil, { RightLabel = "Munition(s) : ~r~x"..ammo }, true, function(_, _, s)
                                    if s then
                                        TriggerServerEvent("ESXCustomCoffre:actionsweaponsveh", plate, class, "deposit", Player.WeaponData[i].name, ammo, Player.WeaponData[i].label)
                                    end
                                end)
                            end
                        end
                    end
                else
                    RageUI.Separator("~r~Aucune Armes")
                end
            end

            if CoffreVeh.Money then 
                RageUI.Separator("↓ Argent ↓")
                RageUI.ButtonWithStyle("Déposer de l'argent", nil, {RightLabel = "→→→"}, true, function(_, _, s)
                    if s then
                        local check, count = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput("Combien voulez vous deposer ?", 15))
                        if check then 
                            TriggerServerEvent("ESXCustomCoffre:actionsargentveh", plate, class, "deposit", count, ConfigVehicleCoffre.Money.money)
                        else
                            ESX.ShowNotification("Veuillez entrez des chiffres")
                        end
                    end
                end)

                RageUI.ButtonWithStyle("Déposer de l'argent sale", nil, {RightLabel = "→→→"}, true, function(_, _, s)
                    if s then
                        local check, count = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput("Combien voulez vous deposer ?", 15))
                        if check then 
                            TriggerServerEvent("ESXCustomCoffre:actionsargentveh", plate, class, "deposit", count, ConfigVehicleCoffre.Money.argentsale)
                        else
                            ESX.ShowNotification("Veuillez entrez des chiffres")
                        end
                    end
                end)
            end

        end, function()
        end)

        RageUI.IsVisible(retirerincoffre, true, true, true, function()    
            if Info.weight ~= nil then 
                RageUI.Separator("Contenu du coffre: ~b~"..ESX.Math.Round(Info.weight, 1).."kg / "..tostring(ConfigVehicleCoffre.WeightWeh[class]).."kg ")
            else
                RageUI.Separator("Contenu du coffre: ~b~ 0 kg / "..tostring(ConfigVehicleCoffre.WeightWeh[class]).."kg ")
            end 

            RageUI.List("Filtre", {"Items", "Armes", "Argent"}, CoffreVeh.IndexRemove, nil, {}, true, function(Hovered, Active, Selected, Index)
                CoffreVeh.IndexRemove = Index

                if Index == 1 then 
                    CoffreVeh.ItemR, CoffreVeh.WeaponR, CoffreVeh.MoneyR = true, false, false 
                elseif Index == 2 then 
                    CoffreVeh.ItemR, CoffreVeh.WeaponR, CoffreVeh.MoneyR = false, true, false 
                elseif Index == 3 then 
                    CoffreVeh.ItemR, CoffreVeh.WeaponR, CoffreVeh.MoneyR = false, false, true 
                end
            end)

            if CoffreVeh.ItemR then 
                if Data["items"] ~= nil then 
                    for k, v in pairs(Data["items"]) do 
                        RageUI.ButtonWithStyle(""..v.label.." [x"..v.count.."]", "Cet item pèse un total de  ~r~"..v.weight.." kg  ", {RightLabel = "~r~Retirer"}, true, function(_, _, s)
                            if s then
                                local check, count = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput("Combien voulez vous retirer ?", 15))
                                if check then 
                                    if v.count >= count then 
                                        TriggerServerEvent("ESXCustomCoffre:actionsitemveh", plate, Info.id, "remove", count, v.name)
                                    else
                                        ESX.ShowNotification("Vous ne disposez pas d'assser de ~r~"..v.label.." ~s~pour faire cela")
                                    end
                                else
                                    ESX.ShowNotification("Veuillez entrez des chiffres" )
                                end
                            end
                        end)
                    end
                else
                    RageUI.Separator("↓ Aucun Items dans le coffre ↓")
                end
            end

            if CoffreVeh.WeaponR then 
                if Data["weapons"] ~= nil then 
                    for k, v in pairs(Data["weapons"]) do 
                        RageUI.ButtonWithStyle(""..v.label.." [x"..v.count.."]", "Cet item pèse un total de  ~r~"..v.weight.." kg  ", {RightLabel = "~r~Retirer"}, true, function(_, _, s)
                            if s then
                                local check, count = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput("Combien voulez vous retirer ?", 15))
                                if check then 
                                    if v.count >= count then 
                                        TriggerServerEvent("ESXCustomCoffre:actionsweaponsveh", plate, Info.id, "remove", v.name, count, v.label)
                                    else
                                        ESX.ShowNotification("Vous ne disposez pas d'assser de ~r~"..v.label.." ~s~pour faire cela")
                                    end
                                else
                                    ESX.ShowNotification("Veuillez entrez des chiffres")
                                end
                            end
                        end)
                    end
                else
                    RageUI.Separator("↓ Aucunes armes dans le coffre ↓")
                end
            end

            if CoffreVeh.MoneyR then 
                if Data["accounts"] ~= nil  then 
                    RageUI.ButtonWithStyle("Argent: ~g~"..Data["accounts"].money.." $", nil, {RightLabel = "→→→"}, true, function(_, _, s)
                        if s then
                            local check, count = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput("Combien voulez vous retirer ?", 15))
                            if check then 
                                if Data["accounts"].money >= tonumber(count) then 
                                    TriggerServerEvent("ESXCustomCoffre:actionsargentveh", plate, Info.id, "remove", count, "money")
                                else
                                    ESX.ShowNotification("Somme invalide")
                                end
                            else
                                ESX.ShowNotification("Veuillez entrez des chiffres")
                            end

                        end
                    end)
                else
                    RageUI.Separator("↓ Aucun argent propre ↓")
                end

                if Data["accounts"] ~= nil then 
                    RageUI.ButtonWithStyle("Argent sale: ~r~"..Data["accounts"].black_money.." $", nil, {RightLabel = "→→→"}, true, function(_, _, s)
                        if s then
                            local check, count = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput("Combien voulez vous retirer ?", 15))
                            if check then 
                                if Data["accounts"].black_money >= tonumber(count) then 
                                    TriggerServerEvent("ESXCustomCoffre:actionsargentveh", plate, Info.id, "remove", count, "black_money")
                                else
                                    ESX.ShowNotification("Somme invalide")
                                end
                            else
                                ESX.ShowNotification("Veuillez entrez des chiffres")
                            end

                        end
                    end)
                else
                    RageUI.Separator("↓ Aucun argent sale ↓")
                end
            end
        end, function()
        end)

        if not RageUI.Visible(maincoffre) and 
        not RageUI.Visible(depositincoffre) and 
        not RageUI.Visible(retirerincoffre) then 
            maincoffre = RMenu:DeleteType("maincoffre")
        end
    end
end

RegisterKeyMapping("coffre", "Pour ouvrir le coffre de la voiture", 'keyboard', "L")
RegisterCommand("coffre", function()
    if not IsPedSittingInAnyVehicle(PlayerPedId()) then 
        local coord = GetEntityCoords(PlayerPedId())
        local VehCloset, VehDist = ESX.Game.GetClosestVehicle(coord, false)
        local VehCoords = GetEntityCoords(VehCloset)
        local dist = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), VehDist, true)
        
        if VehDist < 4 then
            local locked = GetVehicleDoorLockStatus(VehCloset) 
            if locked == 1 then
                local class = GetVehicleClass(VehCloset)
                local plate = GetVehicleNumberPlateText(VehCloset)
                local model = GetEntityModel(VehCloset)
                if GetVehicleBodyHealth(VehCloset) > 0 then
                    OpenCoffreVeh(VehCoords, plate, model, class)
                else
                    ESX.ShowNotification("Le véhicule n'est plus en état d'être ouvert.")
                end
            else
                ESX.ShowNotification("Le véhicule est fermé.")
            end
        else
            ESX.ShowNotification("Aucun véhicule aux alentours.")
        end
    else
        ESX.ShowNotification("Vous ne pouvez pas faire cela dans un véhicule")
    end
end)


RegisterNetEvent("ESXCustomCoffre:recievecoffrevehclientside", function(data)
    Data = data.data
    Info = data.infos
end)