local draw = {}
mainCatIndex = 1
Tets = 1
local LastVeh = nil
local rot = nil
local lastPos = nil
local VisualiserQQ = 0
local PlayerData = {}
local CacheLoad = false
local DZQDZQDZQZ = nil

TriggerEvent('chat:addSuggestion', '/'..ConfigBoutique.Commande.CommandeGiveViaIDIG, "Give des coins avec ID du joueur",{ { name = "id", help = "Exemple : 1" }, { name = "montant", help = "Exemple 2500 pour recevoir 2500 coins" } })
TriggerEvent('chat:addSuggestion', '/'..ConfigBoutique.Commande.CommandeGiveViaBoutiqueID, "Give des coins avec code boutique du joueur",{ { name = "code boutique", help = "Exemple : 1" }, { name = "montant", help = "Exemple 2500 pour recevoir 2500 coins" } })

RegisterNetEvent("CorePickax:ReceiveClientSideBoutique")
AddEventHandler("CorePickax:ReceiveClientSideBoutique", function(ReceiveInfo)
    if ReceiveInfo ~= nil and ReceiveInfo.boutique_id ~= nil then
        if ReceiveInfo.points == nil then
            ReceiveInfo.points = 0
        end
	    PlayerData = ReceiveInfo
    end
end)

RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(xPlayer)
	Wait(5000)
	TriggerServerEvent("CorePickax:SendServerSideBoutique")
	CacheLoad = true
end)

Citizen.CreateThread(function()
    Wait(5000)
	TriggerServerEvent("CorePickax:SendServerSideBoutique")
	CacheLoad = true
end)

local obj = nil
local MenuStore = false
local CamShowVeh = nil
local CamWeapon = nil
local CamOBJ = nil

ClearAllCam = function()
    RenderScriptCams(false, false, 0, 1, 0)
    DestroyCam(CamShowVeh, true)
    DestroyCam(CamWeapon, true)
    DestroyCam(CamOBJ, true)
    CamShowVeh = nil
    CamWeapon = nil
    CamOBJ = nil
end

function OpenMenuBoutique()
    if CacheLoad then
        MenuStore = true
        Visualiser = 0
        local View = false
        TriggerServerEvent("CorePickax:SendServerSide")

        local store = RageUI.CreateMenu(ConfigBoutique.Menu["Title1"], ConfigBoutique.Menu["SubTitle1"])
        local caissemenu = RageUI.CreateSubMenu(store, ConfigBoutique.Menu["Title2"], ConfigBoutique.Menu["SubTitle2"])
        local caissemenu2 = RageUI.CreateSubMenu(caissemenu, ConfigBoutique.Menu["Title2"], ConfigBoutique.Menu["SubTitle2"])
        local menuPack = RageUI.CreateSubMenu(store, ConfigBoutique.Menu["Title4"], ConfigBoutique.Menu["SubTitle4"])
        local entreprisemenu = RageUI.CreateSubMenu(store, ConfigBoutique.Menu["Title6"], ConfigBoutique.Menu["SubTitle6"])
        local vehiclemenu = RageUI.CreateSubMenu(store, ConfigBoutique.Menu["Title8"], ConfigBoutique.Menu["SubTitle8"])
        local weaponmenu = RageUI.CreateSubMenu(store, ConfigBoutique.Menu["Title11"], ConfigBoutique.Menu["SubTitle11"])
        local weaponmenu2 = RageUI.CreateSubMenu(store, ConfigBoutique.Menu["Title14"], ConfigBoutique.Menu["SubTitle14"])
        local buyCustommenu = RageUI.CreateSubMenu(store, ConfigBoutique.Menu["Title13"], ConfigBoutique.Menu["SubTitle13"])
        local adminMenu = RageUI.CreateSubMenu(store, ConfigBoutique.Menu["Title16"], ConfigBoutique.Menu["SubTitle16"])
        local adminOnline = RageUI.CreateSubMenu(adminMenu, ConfigBoutique.Menu["Title16"], "Joueurs en ligne")
        local adminRecent = RageUI.CreateSubMenu(adminMenu, ConfigBoutique.Menu["Title16"], "Joueurs hors ligne (derniers vus)")
        local adminResults = RageUI.CreateSubMenu(adminMenu, ConfigBoutique.Menu["Title16"], "Résultats de la recherche")
        local adminTarget = RageUI.CreateSubMenu(adminMenu, ConfigBoutique.Menu["Title16"], "Joueur")

        -- Administration : listes de joueurs + donner / retirer des coins (contrôles faits côté serveur)
        local adminList, adminSelected = {}, nil

        local function adminLoad(callbackName, ...)
            adminList = {}
            ESX.TriggerServerCallback(callbackName, function(list) adminList = list or {} end, ...)
        end

        local function adminCoins(sign, target, label)
            local value = ESXCustom_Function_ClientSide:KeyboardInput((sign > 0 and "Coins à donner à " or "Coins à retirer à ") .. label, 8)
            local amount = tonumber(value)
            if not amount or amount < 1 then
                ESX.ShowNotification("~r~Montant invalide")
                return
            end
            ESX.TriggerServerCallback('CorePickax:boutique:admin:coins', function(ok, result)
                if ok then
                    if adminSelected and adminSelected.identifier == target then adminSelected.points = result end
                    ESX.ShowNotification(("~g~Fait~s~ : %s a maintenant ~b~%s~s~ coins"):format(label, ESX.Math.GroupDigits(result)))
                else
                    ESX.ShowNotification("~r~" .. tostring(result))
                end
            end, target, math.floor(amount) * sign)
        end

        local function adminPlayerButtons(parentMenu)
            if #adminList == 0 then
                RageUI.Separator("Aucun joueur")
            end
            for _, p in ipairs(adminList) do
                local label = (p.id and ("[" .. p.id .. "] ") or "") .. p.name
                local desc = ("Code boutique : ~b~%s~s~\nIdentifiant : %s\n%s"):format(tostring(p.boutique_id or "?"), p.identifier, p.online and "~g~En ligne" or ("~r~Hors ligne" .. (p.last_seen and (" · vu " .. p.last_seen) or "")))
                RageUI.ButtonWithStyle(label, desc, { RightLabel = ESX.Math.GroupDigits(p.points) .. " coins" }, true, function(Hovered, Active, Selected)
                    if Selected then
                        adminSelected = p
                        adminTarget.Parent = parentMenu
                    end
                end, adminTarget)
            end
        end

        weaponmenu2.Closed = function() 
            TriggerEvent('esx:restoreLoadout')
            VisualiserQQ = 0
        end

        store.Closed = function()
            MenuStore = false
        end

        vehiclemenu.Closed = function()
            Visualiser = 0
            View = false
            RenderScriptCams(false, false, 0, 1, 0)
            DestroyCam(CamShowVeh, true)
            DeleteEntity(LastVeh)
        end

        caissemenu2.Closed = function()
            Visualiser = 0
            View = false
            ClearAllCam()
            DeleteEntity(LastVeh)
            DeleteEntity(obj)
            obj = nil
            SetFocusEntity(PlayerPedId())
        end

        weaponmenu.Closed = function()
            Visualiser = 0
            View = false
            ClearAllCam()
            DeleteEntity(obj)
            obj = nil
        end

        RageUI.Visible(store, not RageUI.Visible(store))

        while store do
            Wait(0)
            RageUI.IsVisible(store, true, true, true, function()
                RageUI.Info(ConfigBoutique.Menu.Info["Title"], {(ConfigBoutique.Menu.Info["Desc"]):format(GetPlayerName(PlayerId()), PlayerData.boutique_id, PlayerData.points)}, {"", "", "", ""})
                RageUI.Line()
                
                RageUI.ButtonWithStyle(ConfigBoutique.Menu.Bouton["Bouton_Vehicle"], ConfigBoutique.Menu.Bouton["Bouton_Vehicle_Desc"], {RightLabel = "→→→"}, true, function(_,_,Selected)
                    if Selected then
                        lastPos = GetEntityCoords(PlayerPedId())
                        rot = 1.0
                    end
                end, vehiclemenu)

                if ConfigBoutique.weapon ~= nil and #ConfigBoutique.weapon > 0 then
                    RageUI.ButtonWithStyle(ConfigBoutique.Menu.Bouton["Bouton_Weapon"], ConfigBoutique.Menu.Bouton["Bouton_Weapon_Desc"], {RightLabel = "→→→"}, true, function(_,_,Selected)
                    end, weaponmenu)
                end

                if ConfigBoutique.weaponCustom ~= nil and ConfigBoutique.weaponCustom then
                    RageUI.ButtonWithStyle(ConfigBoutique.Menu.Bouton["Bouton_WeaponCustom"], ConfigBoutique.Menu.Bouton["Bouton_WeaponCustom_Desc"], {RightLabel = "→→→"}, true, function(_,_,Selected)
                    end, weaponmenu2)
                end

                if ConfigBoutique.pack ~= nil and #ConfigBoutique.pack > 0 then
                    RageUI.ButtonWithStyle(ConfigBoutique.Menu.Bouton["Bouton_Pack"], ConfigBoutique.Menu.Bouton["Bouton_Pack_Desc"], {RightLabel = "→→→"}, true, function()
                    end, menuPack)
                end
                if ConfigBoutique.caisse ~= nil and #ConfigBoutique.caisse > 0 then
                    RageUI.ButtonWithStyle(ConfigBoutique.Menu.Bouton["Bouton_Case"], ConfigBoutique.Menu.Bouton["Bouton_Case_Desc"], {RightLabel = "→→→"}, true, function()
                    end, caissemenu)
                end

                if ConfigBoutique.Entreprise ~= nil and #ConfigBoutique.Entreprise > 0 then
                    RageUI.ButtonWithStyle(ConfigBoutique.Menu.Bouton["Bouton_Entreprise"], ConfigBoutique.Menu.Bouton["Bouton_Entreprise_Desc"], {RightLabel = "→→→"}, true, function()
                    end, entreprisemenu)
                end
                if ConfigBoutique.boost ~= nil and #ConfigBoutique.boost > 0 then
                    RageUI.ButtonWithStyle(ConfigBoutique.Menu.Bouton["Bouton_FullCustom"], ConfigBoutique.Menu.Bouton["Bouton_FullCustom_Desc"], {RightLabel = "→→→"}, true, function()
                    end, buyCustommenu)
                end
                RageUI.Line()

                if PlayerData.Staff ~= nil and PlayerData.Staff then
                    RageUI.ButtonWithStyle(ConfigBoutique.Menu.Bouton["Bouton_Admin"], ConfigBoutique.Menu.Bouton["Bouton_Admin_Desc"], {RightLabel = "→→→"}, true, function()
                    end, adminMenu)
                end

                RageUI.ButtonWithStyle(ConfigBoutique.Menu.Bouton["Bouton_Link"], ConfigBoutique.Menu.Bouton["Bouton_Link_Desc"], {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    if Selected then
                        SendNUIMessage({LinkShop = ConfigBoutique.LinkShop})
                    end
                end)
            end)

            RageUI.IsVisible(adminMenu, true, true, true, function()
                RageUI.Separator("Joueurs")
                RageUI.ButtonWithStyle("Joueurs en ligne", "Voir les joueurs connectés, leur solde, et leur donner / retirer des coins", {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    if Selected then adminLoad('CorePickax:boutique:admin:online') end
                end, adminOnline)
                RageUI.ButtonWithStyle("Rechercher un joueur", "Par nom, prénom, ID serveur, code boutique ou identifiant (en ligne ou hors ligne)", {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    if Selected then
                        local q = ESXCustom_Function_ClientSide:KeyboardInput("Nom, ID, code boutique…", 40)
                        if q ~= nil and q ~= "" then
                            adminLoad('CorePickax:boutique:admin:search', q)
                        else
                            adminList = {}
                        end
                    end
                end, adminResults)
                RageUI.ButtonWithStyle("Joueurs hors ligne", "Les derniers joueurs vus qui ne sont pas connectés", {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    if Selected then adminLoad('CorePickax:boutique:admin:recent') end
                end, adminRecent)
                RageUI.Separator("Par ID de joueur connecté")
                RageUI.ButtonWithStyle(ConfigBoutique.Menu.Bouton["Bouton_GiveCoins"], ConfigBoutique.Menu.Bouton["Bouton_GiveCoins_Desc"], {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    if Selected then
                        local id = tonumber(ESXCustom_Function_ClientSide:KeyboardInput(ConfigBoutique.Menu.Keyboard["Give"], 3))
                        if id ~= nil then adminCoins(1, id, "le joueur " .. id) end
                    end
                end)
                RageUI.ButtonWithStyle(ConfigBoutique.Menu.Bouton["Bouton_RemoveCoins"], ConfigBoutique.Menu.Bouton["Bouton_RemoveCoins_Desc"], {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    if Selected then
                        local id = tonumber(ESXCustom_Function_ClientSide:KeyboardInput(ConfigBoutique.Menu.Keyboard["Remove"], 3))
                        if id ~= nil then adminCoins(-1, id, "le joueur " .. id) end
                    end
                end)
            end)

            RageUI.IsVisible(adminOnline, true, true, true, function() adminPlayerButtons(adminOnline) end)
            RageUI.IsVisible(adminResults, true, true, true, function() adminPlayerButtons(adminResults) end)
            RageUI.IsVisible(adminRecent, true, true, true, function() adminPlayerButtons(adminRecent) end)

            RageUI.IsVisible(adminTarget, true, true, true, function()
                if not adminSelected then
                    RageUI.Separator("Aucun joueur sélectionné")
                    return
                end
                local p = adminSelected
                RageUI.Separator(p.name .. (p.online and " ~g~• en ligne" or " ~r~• hors ligne"))
                RageUI.ButtonWithStyle("Solde actuel", ("Code boutique : ~b~%s~s~\nIdentifiant : %s"):format(tostring(p.boutique_id or "?"), p.identifier), {RightLabel = ESX.Math.GroupDigits(p.points) .. " coins"}, true, function() end)
                RageUI.ButtonWithStyle("Donner des coins", nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    if Selected then adminCoins(1, p.identifier, p.name) end
                end)
                RageUI.ButtonWithStyle("Retirer des coins", nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                    if Selected then adminCoins(-1, p.identifier, p.name) end
                end)
            end)

            RageUI.IsVisible(caissemenu2, true, true, true, function()
                RageUI.Separator("Listes des véhicules")
                for k, v in pairs(ConfigBoutique["ESXCustom"][DZQDZQDZQZ].list) do
                    if v.vehicle ~= nil then
                        RageUI.ButtonWithStyle(v.name, nil, {RightLabel = ConfigBoutique["chance"][v.tier].name}, true, function(Hovered, Active, Selected)
                            if Active then
                                RageUI.Info(ConfigBoutique.Menu.Info["Title"], {(ConfigBoutique.Menu.Info["DescCam"]):format(tostring(v.name), GetVehicleModelNumberOfSeats(v.model))}, {"", "", ""})
                                
                                if not View then
                                    DeleteEntity(obj)
                                    View = true
                                    if ESX.Game.IsSpawnPointClear(ConfigBoutique.Position.PositionCaisse, 20) then
                                        local veh = ESX.Game.GetClosestVehicle(ConfigBoutique.Position.PositionCaisse)
                                        DeleteEntity(veh)
                                        ESX.Game.SpawnLocalVehicle(v.vehicle, ConfigBoutique.Position.PositionCaisse, ConfigBoutique.Position.PositionCaisseHeading, function(vehicle)
                                            LastVeh = vehicle
                                            FreezeEntityPosition(vehicle, true)
                                            SetVehicleDoorsLocked(vehicle, 2)
                                            SetEntityInvincible(vehicle, true)
                                            SetVehicleFixed(vehicle)
                                            SetVehicleDirtLevel(vehicle, 0.0)
                                            SetVehicleEngineOn(vehicle, true, true, true)
                                            SetVehicleLights(vehicle, 2)
                                            SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                            SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                        end)
                                    else
                                        local veh = ESX.Game.GetClosestVehicle(ConfigBoutique.Position.PositionCaisse)
                                        DeleteEntity(veh)
                                        DeleteEntity(LastVeh)
                                        ESX.Game.SpawnLocalVehicle(v.vehicle, ConfigBoutique.Position.PositionCaisse, ConfigBoutique.Position.PositionCaisseHeading, function(vehicle)
                                            LastVeh = vehicle
                                            FreezeEntityPosition(vehicle, true)
                                            SetVehicleDoorsLocked(vehicle, 2)
                                            SetEntityInvincible(vehicle, true)
                                            SetVehicleFixed(vehicle)
                                            SetVehicleDirtLevel(vehicle, 0.0)
                                            SetVehicleEngineOn(vehicle, true, true, true)
                                            SetVehicleLights(vehicle, 2)
                                            SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                            SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                        end)
                                    end
                                end

                                if Visualiser < 1 then
                                    Visualiser = 1
                                    if not DoesCamExist(CamShowVeh) then
                                        CamShowVeh = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                                    end
                                    SetCamCoord(CamShowVeh, vector3(ConfigBoutique.Position.PositionCamCaisse))
                                    SetCamRot(CamShowVeh, 0.0, 0.0, ConfigBoutique.Position.PositionCamHeadingCaisse)
                                    SetCamActive(CamShowVeh, true)
                                    SetCamFov(CamShowVeh, 50.0)
                                    RenderScriptCams(true, false, 0, true, true)

                                    if ConfigBoutique.Position.PositionInterrior then
                                        local interiorId = GetInteriorAtCoords(ConfigBoutique.Position.PositionCamCaisse.x, ConfigBoutique.Position.PositionCamCaisse.y, ConfigBoutique.Position.PositionCamCaisse.z)
                                        if IsValidInterior(interiorId) then
                                            LoadInterior(interiorId)
                                        end
                                    else
                                        SetFocusArea(ConfigBoutique.Position.PositionCamCaisse.x, ConfigBoutique.Position.PositionCamCaisse.y, ConfigBoutique.Position.PositionCamCaisse.z, 0.0, 0.0, 0.0)
                                        PointCamAtCoord(CamShowVeh, ConfigBoutique.Position.PositionCamCaisse.x, ConfigBoutique.Position.PositionCamCaisse.y, ConfigBoutique.Position.PositionCamCaisse.z)
                                    end
                                end
                                if IsControlJustReleased(0, 172) then
                                    DeleteEntity(LastVeh)
                                    View = false
                                end

                                if IsControlJustReleased(0, 173) then
                                    DeleteEntity(LastVeh)
                                    View = false
                                end
                                if LastVeh ~= nil then
                                    if rot == nil then
                                        rot = ConfigBoutique.Position.PositionCaisseHeading
                                    end
                                    rot = rot + 0.10
                                    SetEntityHeading(LastVeh, rot)
                                end
                            end
                        end)
                    end
                end
                RageUI.Separator("Listes des armes")
                for k, v in pairs(ConfigBoutique["ESXCustom"][DZQDZQDZQZ].list) do
                    if v.weapon ~= nil then
                        RageUI.ButtonWithStyle(v.name, nil, {RightLabel = ConfigBoutique["chance"][v.tier].name}, true, function(Hovered, Active, Selected)
                            if Active then
                                DeleteEntity(LastVeh)
                                if IsControlJustReleased(0, 172) then
                                    DeleteEntity(obj)
                                    View = false
                                end
    
                                if IsControlJustReleased(0, 173) then
                                    DeleteEntity(obj)
                                    View = false
                                end
    
                                if not View then
                                    View = true
                                    CreateWeaponSpect2(v.weapon, ConfigBoutique.Position.PositionCaisseWeapon, ConfigBoutique.Position.PositionCaisseWeaponCam, ConfigBoutique.Position.PositionCaisseWeaponHeading)
                                end
                            end
                        end)
                    end
                end

                RageUI.Separator("Listes des coins")
                for k, v in pairs(ConfigBoutique["ESXCustom"][DZQDZQDZQZ].list) do
                    if v.Coins ~= nil then
                        RageUI.ButtonWithStyle(v.Coins.." "..v.name, nil, {RightLabel = ConfigBoutique["chance"][v.tier].name}, true, function(Hovered, Active, Selected)
                            if Active then
                                DeleteEntity(LastVeh)
                                if IsControlJustReleased(0, 172) then
                                    DeleteEntity(obj)
                                    View = false
                                end
    
                                if IsControlJustReleased(0, 173) then
                                    DeleteEntity(obj)
                                    View = false
                                end
    
                                if not View then
                                    View = true
                                    TriggerEvent("ESXCustomBoutique:CreateWeaponSpect", v.modelTexture, ConfigBoutique.Position.PositionCaisse, ConfigBoutique.Position.PositionCamCaisse, ConfigBoutique.Position.PositionCamHeadingCaisse, 50.0)
                                end
                            end
                        end)
                    end
                end
                RageUI.Separator("Listes d'argent")
                for k, v in pairs(ConfigBoutique["ESXCustom"][DZQDZQDZQZ].list) do
                    if v.money ~= nil then
                        RageUI.ButtonWithStyle(v.money.."$", nil, {RightLabel = ConfigBoutique["chance"][v.tier].name}, true, function(Hovered, Active, Selected)
                            if Active then
                                DeleteEntity(LastVeh)
                                if IsControlJustReleased(0, 172) then
                                    DeleteEntity(obj)
                                    View = false
                                end
    
                                if IsControlJustReleased(0, 173) then
                                    DeleteEntity(obj)
                                    View = false
                                end
    
                                if not View then
                                    View = true
                                    TriggerEvent("ESXCustomBoutique:CreateWeaponSpect", v.modelTexture, ConfigBoutique.Position.PositionCaisse, ConfigBoutique.Position.PositionCamCaisse, ConfigBoutique.Position.PositionCamHeadingCaisse, 50.0)
                                end
                            end
                        end)
                    end
                end
            end)

            RageUI.IsVisible(caissemenu, true, true, true, function()
                for k, v in pairs(ConfigBoutique.caisse) do
                    RageUI.List((ConfigBoutique.Menu.Bouton["Bouton_Caisse"]):format(v.name), {"Visualiser", "Acheter"}, Tets, ConfigBoutique.Menu.Bouton["Bouton_Caisse_Desc"], {}, true, function(Hovered, Active, Selected, Index)
                        Tets = Index

                        if Active then
                            RageUI.Info((ConfigBoutique.Menu.Bouton["Bouton_Caisse_Info"]):format(v.name), {v.desc.."\n\nPrix actuelle : ~p~"..v.price.."~s~ coins"}, {"", "", "", "", "", ""})
                        end

                        if Tets == 1 then
                            if Selected then
                                Wait(100)
                                DZQDZQDZQZ = v.model
                                RageUI.Visible(caissemenu, false)
                                RageUI.Visible(caissemenu2, true)
                            end
                        elseif Tets == 2 then
                            if Selected then
                                local Keyboard = ESXCustom_Function_ClientSide:KeyboardInput("Acheter la caisse ? (~g~Oui~s~ ou ~r~Non~s~)", 3)
                                if Keyboard == "oui" or Keyboard == "Oui" then 
                                    if tonumber(PlayerData.points) >= tonumber(v.price) then
                                        TriggerServerEvent("CorePickax:Boutique:Add", {id = k, price = tonumber(v.price), item = v.model, nameitem = v.name, Interaction = "giveitem"})
                                        RageUI.GoBack()
                                    else
                                        RageUI.GoBack()
                                        ESX.ShowNotification("~r~Vous n'avez pas assez de coins pour acheter cette caisse~s~")
                                    end
                                end
                            end
                        end
                    end)
                    -- RageUI.ButtonWithStyle((ConfigBoutique.Menu.Bouton["Bouton_Caisse"]):format(v.name), ConfigBoutique.Menu.Bouton["Bouton_Caisse_Desc"], {RightLabel = (ConfigBoutique.Menu.Bouton["Bouton_Caisse_RightLabel"]):format(v.price)}, true, function(Hovered, Active, Selected)
                    --     if Active then
                    --         RageUI.Info((ConfigBoutique.Menu.Bouton["Bouton_Caisse_Info"]):format(v.name), {v.desc}, {"", "", "", ""})
                    --     end

                    --     if Selected then
                    --         local Keyboard = ESXCustom_Function_ClientSide:KeyboardInput("Acheter la caisse ? (~g~Oui~s~ ou ~r~Non~s~)", 3)
                    --         if Keyboard == "oui" or Keyboard == "Oui" then 
                    --             if tonumber(PlayerData.points) >= tonumber(v.price) then
                    --                 TriggerServerEvent("CorePickax:Boutique:Add", {id = k, price = tonumber(v.price), item = v.model, nameitem = v.name, Interaction = "giveitem"})
                    --                 RageUI.GoBack()
                    --             else
                    --                 RageUI.GoBack()
                    --                 ESX.ShowNotification("~r~Vous n'avez pas assez de coins pour acheter cette caisse~s~")
                    --             end
                    --         end
                    --     end
                    -- end)
                end
            end)

            RageUI.IsVisible(menuPack, true, true, true, function()
                for k, v in pairs(ConfigBoutique.pack) do
                    RageUI.ButtonWithStyle((ConfigBoutique.Menu.Bouton["Bouton_Pack2"]):format(v.name), ConfigBoutique.Menu.Bouton["Bouton_Pack2_Desc"], {RightLabel = (ConfigBoutique.Menu.Bouton["Bouton_Pack2_RightLabel"]):format(v.price)}, true, function(Hovered, Active, Selected)
                        if Active then
                            RageUI.Info((ConfigBoutique.Menu.Bouton["Bouton_Pack2_Info"]):format(v.name), {v.desc}, {"", "", "", ""})
                        end
                        if Selected then
                            local Keyboard = ESXCustom_Function_ClientSide:KeyboardInput("Acheter le pack ? (~g~Oui~s~ ou ~r~Non~s~)", 3)
                            if Keyboard == "oui" or Keyboard == "Oui" then 
                                if tonumber(PlayerData.points) >= tonumber(v.price) then
                                    TriggerServerEvent("CorePickax:Boutique:Add", {id = k, price = tonumber(v.price), Interaction = "BuyPack"})
                                    RageUI.GoBack()
                                    for u, i in pairs(v.Win) do
                                        if i.item then
                                            TriggerServerEvent('ESXCustomBoutique:giveReward', 'item', i.item, i.amount)
                                        elseif i.Vehicle then
                                            TriggerEvent('mkbussZ:RewardVehicleCar', i.Vehicle)
                                            Wait(100)
                                        elseif i.money then
                                            TriggerServerEvent('ESXCustomBoutique:giveReward', 'money', i.money)
                                        elseif i.weapon then
                                            TriggerServerEvent('ESXCustomBoutique:giveReward', 'weapon', i.weapon)
                                        end
                                    end
                                    ESX.ShowNotification("Vous avez reçu votre pack")
                                else
                                    RageUI.GoBack()
                                    ESX.ShowNotification("~r~Vous n'avez pas assez de coins pour acheter ce véhicule~s~")
                                end
                            end
                        end
                    end)
                end
            end)

            RageUI.IsVisible(vehiclemenu, true, true, true, function()
                if ConfigBoutique.Autres ~= nil and #ConfigBoutique.Autres > 0 then
                    RageUI.List("Catégorie - véhicule", {"Voiture", "Moto", "Autres"}, mainCatIndex, nil, {}, true, function(Hovered, Active, Selected, Index)
                        mainCatIndex = Index
                    end)
                    if mainCatIndex == 1 then
                        RageUI.Separator("↓ Voiture ↓")
                        for k, v in pairs(ConfigBoutique.vehicle) do
                            RageUI.List((ConfigBoutique.Menu.Bouton["Bouton_Vehicle2"]):format(v.name, v.price), {"Visualiser", "Acheter"}, Tets, nil, {}, true, function(Hovered, Active, Selected, Index)
                                Tets = Index

                                if Active then
                                    RageUI.Info(ConfigBoutique.Menu.Info["Title"], {(ConfigBoutique.Menu.Info["DescVeh"]):format(tostring(v.name), GetVehicleModelNumberOfSeats(v.model), tostring(v.price))}, {"", "", "", ""})
                                    
                                    if Visualiser < 1 then
                                        Visualiser = 1
                                        if not DoesCamExist(CamShowVeh) then
                                            CamShowVeh = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                                        end
                                        SetCamCoord(CamShowVeh, vector3(ConfigBoutique.Position.PositionVehiculeCam))
                                        SetCamRot(CamShowVeh, 0.0, 0.0, ConfigBoutique.Position.PositionVehiculeCamHeading)
                                        SetCamActive(CamShowVeh, true)
                                        RenderScriptCams(true, false, 0, true, true)
                                        local interiorId = GetInteriorAtCoords(ConfigBoutique.Position.PositionVehiculeCam)
                                        if IsValidInterior(interiorId) then
                                            LoadInterior(interiorId)
                                        end
                                    end
                                    if IsControlJustReleased(0, 172) then
                                        DeleteEntity(LastVeh)
                                        View = false
                                    end

                                    if IsControlJustReleased(0, 173) then
                                        DeleteEntity(LastVeh)
                                        View = false
                                    end
                                    if LastVeh ~= nil then
                                        rot = rot + 0.10
                                        SetEntityHeading(LastVeh, rot)
                                    end
                                end

                                if Tets == 1 then
                                    if Active then
                                        if not View then
                                            View = true
                                            if ESX.Game.IsSpawnPointClear(ConfigBoutique.Position.PositionVehicule, 20) then
                                                local veh = ESX.Game.GetClosestVehicle(ConfigBoutique.Position.PositionVehicule)
                                                DeleteEntity(veh)
                                                ESX.Game.SpawnLocalVehicle(v.model, ConfigBoutique.Position.PositionVehicule, ConfigBoutique.Position.PositionVehiculeHeading, function(vehicle)
                                                    LastVeh = vehicle
                                                    FreezeEntityPosition(vehicle, true)
                                                    SetVehicleDoorsLocked(vehicle, 2)
                                                    SetEntityInvincible(vehicle, true)
                                                    SetVehicleFixed(vehicle)
                                                    SetVehicleDirtLevel(vehicle, 0.0)
                                                    SetVehicleEngineOn(vehicle, true, true, true)
                                                    SetVehicleLights(vehicle, 2)
                                                    SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                                    SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                                end)
                                            else
                                                local veh = ESX.Game.GetClosestVehicle(ConfigBoutique.Position.PositionVehicule)
                                                DeleteEntity(veh)
                                                DeleteEntity(LastVeh)
                                                ESX.Game.SpawnLocalVehicle(v.model, ConfigBoutique.Position.PositionVehicule, ConfigBoutique.Position.PositionVehiculeHeading, function(vehicle)
                                                    LastVeh = vehicle
                                                    FreezeEntityPosition(vehicle, true)
                                                    SetVehicleDoorsLocked(vehicle, 2)
                                                    SetEntityInvincible(vehicle, true)
                                                    SetVehicleFixed(vehicle)
                                                    SetVehicleDirtLevel(vehicle, 0.0)
                                                    SetVehicleEngineOn(vehicle, true, true, true)
                                                    SetVehicleLights(vehicle, 2)
                                                    SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                                    SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                                end)
                                            end
                                        end
                                    end
                                else
                                    if Selected then
                                        local Keyboard = ESXCustom_Function_ClientSide:KeyboardInput("Acheter le véhicule ? (~g~Oui~s~ ou ~r~Non~s~)", 3)
                                        if Keyboard == "oui" or Keyboard == "Oui" then 
                                            if tonumber(PlayerData.points) >= tonumber(v.price) then
                                                vehicle_give(v.model, k, v.price)
                                            else
                                                RageUI.GoBack()
                                                ESX.ShowNotification("~r~Vous n'avez pas assez de coins pour acheter ce véhicule~s~")
                                            end
                                            RageUI.CloseAll()
                                            RenderScriptCams(false, false, 0, 1, 0)
                                            DestroyCam(CamShowVeh, true)
                                            DeleteEntity(LastVeh)
                                        end
                                    end
                                end
                            end)
                        end
                    elseif mainCatIndex == 2 then
                        RageUI.Separator("↓ Motos ↓")
                        for k, v in pairs(ConfigBoutique.Motos) do
                            RageUI.List((ConfigBoutique.Menu.Bouton["Bouton_Moto"]):format(v.name, v.price), {"Visualiser", "Acheter"}, Tets, nil, {}, true, function(Hovered, Active, Selected, Index)
                                Tets = Index

                                if Active then
                                    RageUI.Info(ConfigBoutique.Menu.Info["Title"], {(ConfigBoutique.Menu.Info["DescMoto"]):format(tostring(v.name), GetVehicleModelNumberOfSeats(v.model), tostring(v.price))}, {"", "", "", ""})

                                    if Visualiser < 1 then
                                        Visualiser = 1
                                        if not DoesCamExist(CamShowVeh) then
                                            CamShowVeh = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                                        end
                                        SetCamCoord(CamShowVeh, vector3(ConfigBoutique.Position.PositionVehiculeCam))
                                        SetCamRot(CamShowVeh, 0.0, 0.0, ConfigBoutique.Position.PositionVehiculeCamHeading)
                                        SetCamActive(CamShowVeh, true)
                                        RenderScriptCams(true, false, 0, true, true)
                                        local interiorId = GetInteriorAtCoords(ConfigBoutique.Position.PositionVehiculeCam)
                                        if IsValidInterior(interiorId) then
                                            LoadInterior(interiorId)
                                        end
                                    end

                                    if LastVeh ~= nil then
                                        rot = rot + 0.10
                                        SetEntityHeading(LastVeh, rot)
                                    end

                                    if IsControlJustReleased(0, 172) then
                                        DeleteEntity(LastVeh)
                                        View = false
                                    end

                                    if IsControlJustReleased(0, 173) then
                                        DeleteEntity(LastVeh)
                                        View = false
                                    end
                                end

                                if Tets == 1 then
                                    if Active then
                                        if not View then
                                            View = true
                                            if ESX.Game.IsSpawnPointClear(ConfigBoutique.Position.PositionVehicule, 20) then
                                                local veh = ESX.Game.GetClosestVehicle(ConfigBoutique.Position.PositionVehicule)
                                                DeleteEntity(veh)
                                                ESX.Game.SpawnLocalVehicle(v.model, ConfigBoutique.Position.PositionVehicule, ConfigBoutique.Position.PositionVehiculeHeading, function(vehicle)
                                                    LastVeh = vehicle
                                                    FreezeEntityPosition(vehicle, true)
                                                    SetVehicleDoorsLocked(vehicle, 2)
                                                    SetEntityInvincible(vehicle, true)
                                                    SetVehicleFixed(vehicle)
                                                    SetVehicleDirtLevel(vehicle, 0.0)
                                                    SetVehicleEngineOn(vehicle, true, true, true)
                                                    SetVehicleLights(vehicle, 2)
                                                    SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                                    SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                                end)
                                            else
                                                local veh = ESX.Game.GetClosestVehicle(ConfigBoutique.Position.PositionVehicule)
                                                DeleteEntity(veh)
                                                DeleteEntity(LastVeh)
                                                ESX.Game.SpawnLocalVehicle(v.model, ConfigBoutique.Position.PositionVehicule, ConfigBoutique.Position.PositionVehiculeHeading, function(vehicle)
                                                    LastVeh = vehicle
                                                    FreezeEntityPosition(vehicle, true)
                                                    SetVehicleDoorsLocked(vehicle, 2)
                                                    SetEntityInvincible(vehicle, true)
                                                    SetVehicleFixed(vehicle)
                                                    SetVehicleDirtLevel(vehicle, 0.0)
                                                    SetVehicleEngineOn(vehicle, true, true, true)
                                                    SetVehicleLights(vehicle, 2)
                                                    SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                                    SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                                end)
                                            end
                                        end
                                    end
                                else
                                    if Selected then
                                        local Keyboard = ESXCustom_Function_ClientSide:KeyboardInput("Acheter le véhicule ? (~g~Oui~s~ ou ~r~Non~s~)", 3)
                                        if Keyboard == "oui" or Keyboard == "Oui" then 
                                            if tonumber(PlayerData.points) >= tonumber(v.price) then
                                                vehicleMotoGive(v.model, k, v.price)
                                            else
                                                RageUI.GoBack()
                                                ESX.ShowNotification("~r~Vous n'avez pas assez de coins pour acheter ce véhicule~s~")
                                            end
                                            RageUI.CloseAll()
                                            RenderScriptCams(false, false, 0, 1, 0)
                                            DestroyCam(CamShowVeh, true)
                                            DeleteEntity(LastVeh)
                                        end
                                    end
                                end
                            end)
                        end
                    elseif mainCatIndex == 3 then
                        for k, v in pairs(ConfigBoutique.Autres) do
                            if v.Separator then
                                RageUI.Separator(v.name)
                            else
                                RageUI.List(("%s à ~p~%s~s~ Coins~s~"):format(v.name, v.price), {"Visualiser", "Acheter"}, Tets, nil, {}, true, function(Hovered, Active, Selected, Index)
                                    Tets = Index

                                    if Active then
                                        RageUI.Info(ConfigBoutique.Menu.Info["Title"], {("info du véhicule :\nNom du véhicule : %s.\nPlace : %s.\nPrix : %s ~s~coins"):format(tostring(v.name), GetVehicleModelNumberOfSeats(v.model), tostring(v.price))}, {"", "", "", ""})

                                        if Visualiser < 1 then
                                            Visualiser = 1
                                            if not DoesCamExist(CamShowVeh) then
                                                CamShowVeh = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                                            end
                                            SetCamCoord(CamShowVeh, vector3(ConfigBoutique.Position.PositionVehiculeCam))
                                            SetCamRot(CamShowVeh, 0.0, 0.0, ConfigBoutique.Position.PositionVehiculeCamHeading)
                                            SetCamActive(CamShowVeh, true)
                                            RenderScriptCams(true, false, 0, true, true)
                                            local interiorId = GetInteriorAtCoords(ConfigBoutique.Position.PositionVehiculeCam)
                                            if IsValidInterior(interiorId) then
                                                LoadInterior(interiorId)
                                            end
                                        end

                                        if LastVeh ~= nil then
                                            rot = rot + 0.10
                                            SetEntityHeading(LastVeh, rot)
                                        end

                                        if IsControlJustReleased(0, 172) then
                                            DeleteEntity(LastVeh)
                                            View = false
                                        end

                                        if IsControlJustReleased(0, 173) then
                                            DeleteEntity(LastVeh)
                                            View = false
                                        end
                                    end

                                    if Tets == 1 then
                                        if Active then
                                            if not View then
                                                View = true
                                                if ESX.Game.IsSpawnPointClear(ConfigBoutique.Position.PositionVehicule, 20) then
                                                    local veh = ESX.Game.GetClosestVehicle(ConfigBoutique.Position.PositionVehicule)
                                                    DeleteEntity(veh)
                                                    ESX.Game.SpawnLocalVehicle(v.model, ConfigBoutique.Position.PositionVehicule, ConfigBoutique.Position.PositionVehiculeHeading, function(vehicle)
                                                        LastVeh = vehicle
                                                        FreezeEntityPosition(vehicle, true)
                                                        SetVehicleDoorsLocked(vehicle, 2)
                                                        SetEntityInvincible(vehicle, true)
                                                        SetVehicleFixed(vehicle)
                                                        SetVehicleDirtLevel(vehicle, 0.0)
                                                        SetVehicleEngineOn(vehicle, true, true, true)
                                                        SetVehicleLights(vehicle, 2)
                                                        SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                                        SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                                    end)
                                                else
                                                    local veh = ESX.Game.GetClosestVehicle(ConfigBoutique.Position.PositionVehicule)
                                                    DeleteEntity(veh)
                                                    DeleteEntity(LastVeh)
                                                    ESX.Game.SpawnLocalVehicle(v.model, ConfigBoutique.Position.PositionVehicule, ConfigBoutique.Position.PositionVehiculeHeading, function(vehicle)
                                                        LastVeh = vehicle
                                                        FreezeEntityPosition(vehicle, true)
                                                        SetVehicleDoorsLocked(vehicle, 2)
                                                        SetEntityInvincible(vehicle, true)
                                                        SetVehicleFixed(vehicle)
                                                        SetVehicleDirtLevel(vehicle, 0.0)
                                                        SetVehicleEngineOn(vehicle, true, true, true)
                                                        SetVehicleLights(vehicle, 2)
                                                        SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                                        SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                                    end)
                                                end
                                            end
                                        end
                                    else
                                        if Selected then
                                            local Keyboard = ESXCustom_Function_ClientSide:KeyboardInput("Acheter le véhicule ? (~g~Oui~s~ ou ~r~Non~s~)", 3)
                                            if Keyboard == "oui" or Keyboard == "Oui" then 
                                                if tonumber(PlayerData.points) >= tonumber(v.price) then
                                                    vehicleOtherGive(v.model, k, v.price, v.type)
                                                else
                                                    RageUI.GoBack()
                                                    ESX.ShowNotification("~r~Vous n'avez pas assez de coins pour acheter ce véhicule~s~")
                                                end
                                                RageUI.CloseAll()
                                                RenderScriptCams(false, false, 0, 1, 0)
                                                DestroyCam(CamShowVeh, true)
                                                DeleteEntity(LastVeh)
                                            end
                                        end
                                    end
                                end)
                            end
                        end
                    end
                else
                    RageUI.List("Catégorie - véhicule", {"Voiture", "Moto"}, mainCatIndex, nil, {}, true, function(Hovered, Active, Selected, Index)
                        mainCatIndex = Index
                    end)
                    if mainCatIndex == 1 then
                        RageUI.Separator("↓ Voiture ↓")
                        for k, v in pairs(ConfigBoutique.vehicle) do
                            RageUI.List((ConfigBoutique.Menu.Bouton["Bouton_Vehicle2"]):format(v.name, v.price), {"Visualiser", "Acheter"}, Tets, nil, {}, true, function(Hovered, Active, Selected, Index)
                                Tets = Index

                                if Active then
                                    RageUI.Info(ConfigBoutique.Menu.Info["Title"], {(ConfigBoutique.Menu.Info["DescVeh"]):format(tostring(v.name), GetVehicleModelNumberOfSeats(v.model), tostring(v.price))}, {"", "", "", ""})
                                    
                                    if Visualiser < 1 then
                                        Visualiser = 1
                                        if not DoesCamExist(CamShowVeh) then
                                            CamShowVeh = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                                        end
                                        SetCamCoord(CamShowVeh, vector3(ConfigBoutique.Position.PositionVehiculeCam))
                                        SetCamRot(CamShowVeh, 0.0, 0.0, ConfigBoutique.Position.PositionVehiculeCamHeading)
                                        SetCamActive(CamShowVeh, true)
                                        RenderScriptCams(true, false, 0, true, true)
                                        local interiorId = GetInteriorAtCoords(ConfigBoutique.Position.PositionVehiculeCam)
                                        if IsValidInterior(interiorId) then
                                            LoadInterior(interiorId)
                                        end
                                    end
                                    if IsControlJustReleased(0, 172) then
                                        DeleteEntity(LastVeh)
                                        View = false
                                    end

                                    if IsControlJustReleased(0, 173) then
                                        DeleteEntity(LastVeh)
                                        View = false
                                    end
                                    if LastVeh ~= nil then
                                        rot = rot + 0.10
                                        SetEntityHeading(LastVeh, rot)
                                    end
                                end

                                if Tets == 1 then
                                    if Active then
                                        if not View then
                                            View = true
                                            if ESX.Game.IsSpawnPointClear(ConfigBoutique.Position.PositionVehicule, 20) then
                                                local veh = ESX.Game.GetClosestVehicle(ConfigBoutique.Position.PositionVehicule)
                                                DeleteEntity(veh)
                                                ESX.Game.SpawnLocalVehicle(v.model, ConfigBoutique.Position.PositionVehicule, ConfigBoutique.Position.PositionVehiculeHeading, function(vehicle)
                                                    LastVeh = vehicle
                                                    FreezeEntityPosition(vehicle, true)
                                                    SetVehicleDoorsLocked(vehicle, 2)
                                                    SetEntityInvincible(vehicle, true)
                                                    SetVehicleFixed(vehicle)
                                                    SetVehicleDirtLevel(vehicle, 0.0)
                                                    SetVehicleEngineOn(vehicle, true, true, true)
                                                    SetVehicleLights(vehicle, 2)
                                                    SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                                    SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                                end)
                                            else
                                                local veh = ESX.Game.GetClosestVehicle(ConfigBoutique.Position.PositionVehicule)
                                                DeleteEntity(veh)
                                                DeleteEntity(LastVeh)
                                                ESX.Game.SpawnLocalVehicle(v.model, ConfigBoutique.Position.PositionVehicule, ConfigBoutique.Position.PositionVehiculeHeading, function(vehicle)
                                                    LastVeh = vehicle
                                                    FreezeEntityPosition(vehicle, true)
                                                    SetVehicleDoorsLocked(vehicle, 2)
                                                    SetEntityInvincible(vehicle, true)
                                                    SetVehicleFixed(vehicle)
                                                    SetVehicleDirtLevel(vehicle, 0.0)
                                                    SetVehicleEngineOn(vehicle, true, true, true)
                                                    SetVehicleLights(vehicle, 2)
                                                    SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                                    SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                                end)
                                            end
                                        end
                                    end
                                else
                                    if Selected then
                                        local Keyboard = ESXCustom_Function_ClientSide:KeyboardInput("Acheter le véhicule ? (~g~Oui~s~ ou ~r~Non~s~)", 3)
                                        if Keyboard == "oui" or Keyboard == "Oui" then 
                                            if tonumber(PlayerData.points) >= tonumber(v.price) then
                                                vehicle_give(v.model, k, v.price)
                                            else
                                                RageUI.GoBack()
                                                ESX.ShowNotification("~r~Vous n'avez pas assez de coins pour acheter ce véhicule~s~")
                                            end
                                            RageUI.CloseAll()
                                            RenderScriptCams(false, false, 0, 1, 0)
                                            DestroyCam(CamShowVeh, true)
                                            DeleteEntity(LastVeh)
                                        end
                                    end
                                end
                            end)
                        end
                    elseif mainCatIndex == 2 then
                        RageUI.Separator("↓ Motos ↓")
                        for k, v in pairs(ConfigBoutique.Motos) do
                            RageUI.List((ConfigBoutique.Menu.Bouton["Bouton_Moto"]):format(v.name, v.price), {"Visualiser", "Acheter"}, Tets, nil, {}, true, function(Hovered, Active, Selected, Index)
                                Tets = Index

                                if Active then
                                    RageUI.Info(ConfigBoutique.Menu.Info["Title"], {(ConfigBoutique.Menu.Info["DescMoto"]):format(tostring(v.name), GetVehicleModelNumberOfSeats(v.model), tostring(v.price))}, {"", "", "", ""})

                                    if Visualiser < 1 then
                                        Visualiser = 1
                                        if not DoesCamExist(CamShowVeh) then
                                            CamShowVeh = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                                        end
                                        SetCamCoord(CamShowVeh, vector3(ConfigBoutique.Position.PositionVehiculeCam))
                                        SetCamRot(CamShowVeh, 0.0, 0.0, ConfigBoutique.Position.PositionVehiculeCamHeading)
                                        SetCamActive(CamShowVeh, true)
                                        RenderScriptCams(true, false, 0, true, true)
                                        local interiorId = GetInteriorAtCoords(ConfigBoutique.Position.PositionVehiculeCam)
                                        if IsValidInterior(interiorId) then
                                            LoadInterior(interiorId)
                                        end
                                    end

                                    if LastVeh ~= nil then
                                        rot = rot + 0.10
                                        SetEntityHeading(LastVeh, rot)
                                    end

                                    if IsControlJustReleased(0, 172) then
                                        DeleteEntity(LastVeh)
                                        View = false
                                    end

                                    if IsControlJustReleased(0, 173) then
                                        DeleteEntity(LastVeh)
                                        View = false
                                    end
                                end

                                if Tets == 1 then
                                    if Active then
                                        if not View then
                                            View = true
                                            if ESX.Game.IsSpawnPointClear(ConfigBoutique.Position.PositionVehicule, 20) then
                                                local veh = ESX.Game.GetClosestVehicle(ConfigBoutique.Position.PositionVehicule)
                                                DeleteEntity(veh)
                                                ESX.Game.SpawnLocalVehicle(v.model, ConfigBoutique.Position.PositionVehicule, ConfigBoutique.Position.PositionVehiculeHeading, function(vehicle)
                                                    LastVeh = vehicle
                                                    FreezeEntityPosition(vehicle, true)
                                                    SetVehicleDoorsLocked(vehicle, 2)
                                                    SetEntityInvincible(vehicle, true)
                                                    SetVehicleFixed(vehicle)
                                                    SetVehicleDirtLevel(vehicle, 0.0)
                                                    SetVehicleEngineOn(vehicle, true, true, true)
                                                    SetVehicleLights(vehicle, 2)
                                                    SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                                    SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                                end)
                                            else
                                                local veh = ESX.Game.GetClosestVehicle(ConfigBoutique.Position.PositionVehicule)
                                                DeleteEntity(veh)
                                                DeleteEntity(LastVeh)
                                                ESX.Game.SpawnLocalVehicle(v.model, ConfigBoutique.Position.PositionVehicule, ConfigBoutique.Position.PositionVehiculeHeading, function(vehicle)
                                                    LastVeh = vehicle
                                                    FreezeEntityPosition(vehicle, true)
                                                    SetVehicleDoorsLocked(vehicle, 2)
                                                    SetEntityInvincible(vehicle, true)
                                                    SetVehicleFixed(vehicle)
                                                    SetVehicleDirtLevel(vehicle, 0.0)
                                                    SetVehicleEngineOn(vehicle, true, true, true)
                                                    SetVehicleLights(vehicle, 2)
                                                    SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                                    SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                                end)
                                            end
                                        end
                                    end
                                else
                                    if Selected then
                                        local Keyboard = ESXCustom_Function_ClientSide:KeyboardInput("Acheter le véhicule ? (~g~Oui~s~ ou ~r~Non~s~)", 3)
                                        if Keyboard == "oui" or Keyboard == "Oui" then 
                                            if tonumber(PlayerData.points) >= tonumber(v.price) then
                                                vehicleMotoGive(v.model, k, v.price)
                                            else
                                                RageUI.GoBack()
                                                ESX.ShowNotification("~r~Vous n'avez pas assez de coins pour acheter ce véhicule~s~")
                                            end
                                            RageUI.CloseAll()
                                            RenderScriptCams(false, false, 0, 1, 0)
                                            DestroyCam(CamShowVeh, true)
                                            DeleteEntity(LastVeh)
                                        end
                                    end
                                end
                            end)
                        end
                    end
                end
            end)

            RageUI.IsVisible(entreprisemenu, true, true, true, function()
                for k, v in pairs(ConfigBoutique.Entreprise) do
                    RageUI.ButtonWithStyle((ConfigBoutique.Menu.Bouton["Bouton_Entreprise2"]):format(v.name), (ConfigBoutique.Menu.Bouton["Bouton_Entreprise2_Desc"]):format(v.desc), {RightLabel = (ConfigBoutique.Menu.Bouton["Bouton_Entreprise2_RightLabel"]):format(v.price)}, true, function(Hovered, Active, Selected)
                        if Selected then
                            local Keyboard = ESXCustom_Function_ClientSide:KeyboardInput("Acheter le pack entreprise ? (~g~Oui~s~ ou ~r~Non~s~)", 3)
                            if Keyboard == "oui" or Keyboard == "Oui" then 
                                if tonumber(PlayerData.points) >= tonumber(v.price) then
                                    TriggerServerEvent("CorePickax:Boutique:Add", {id = k, price = tonumber(v.price), name = v.name, Interaction = "entrepriseachat"})
                                    RageUI.GoBack()
                                else
                                    RageUI.GoBack()
                                    ESX.ShowNotification("~r~Vous n'avez pas assez de coins pour acheter ce pack entreprise~s~")
                                end
                            end
                        end
                    end)
                end
            end)

            RageUI.IsVisible(weaponmenu2, true, true, true, function()
                local weapon = GetSelectedPedWeapon(PlayerPedId());
                if (weapon ~= GetHashKey("weapon_unarmed")) and (weapon ~= 966099553) and (weapon ~= 0) then
                    for i, v in pairs(ESX.GetWeaponList()) do
                        if (GetHashKey(v.name) == weapon and weapon ~= nil) then
                            if v.components ~= nil and (#v.components > 0) then
                                for i, q in pairs(v.components) do
                                    RageUI.ButtonWithStyle(q.label, nil, {RightLabel = ConfigBoutique.weaponCustomPrice.." Coins"}, true, function(Hovered, Active, Selected)
                                        if Active then
                                            if VisualiserQQ == 0 then
                                                VisualiserQQ = 1
                                                GiveWeaponComponentToPed(PlayerPedId(), GetHashKey(v.name), v.components[i].hash)
                                                if (v.components[i - 1] ~= nil) and (v.components[i - 1].hash ~= nil) then
                                                    RemoveWeaponComponentFromPed(PlayerPedId(), GetHashKey(v.name), v.components[i - 1].hash)
                                                end
                                            end

                                            if IsControlJustReleased(0, 172) then
                                                VisualiserQQ = 0
                                            end
    
                                            if IsControlJustReleased(0, 173) then
                                                VisualiserQQ = 0
                                            end
                                        end
                    
                                        if Selected then
                                            local Keyboard = ESXCustom_Function_ClientSide:KeyboardInput("Acheter le composant ? (~g~Oui~s~ ou ~r~Non~s~)", 3)
                                            if Keyboard == "oui" or Keyboard == "Oui" then
                                                RageUI.CloseAll()
                                                TriggerServerEvent("CorePickax:Boutique:Add", {weaponName = v.name, name = q.name, Interaction = "CustomWeapon", price = ConfigBoutique.weaponCustomPrice})
                                            end
                                        end
                                    end)
                                end
                            else
                                RageUI.Separator("Aucune personnalisation disponible")
                            end
                        end
                    end
                else
                    RageUI.Separator("Vous devez avoir une armes en mains")
                end
            end)

            RageUI.IsVisible(weaponmenu, true, true, true, function()
                for k, v in pairs(ConfigBoutique.weapon) do
                    RageUI.ButtonWithStyle((ConfigBoutique.Menu.Bouton["Bouton_Weapon2"]):format(v.name), ConfigBoutique.Menu.Bouton["Bouton_Weapon2_Desc"], {RightLabel = (ConfigBoutique.Menu.Bouton["Bouton_Weapon2_RightLabel"]):format(v.price)}, true, function(Hovered, Active, Selected)
                        if Active then
                            RageUI.Info(ConfigBoutique.Menu.Info["Title"], {(ConfigBoutique.Menu.Bouton["Bouton_Weapon2_Info"]):format(tostring(v.name), v.balle, tostring(v.price))}, {"", "", "", ""})
                            
                            if IsControlJustReleased(0, 172) then
                                DeleteEntity(obj)
                                View = false
                            end

                            if IsControlJustReleased(0, 173) then
                                DeleteEntity(obj)
                                View = false
                            end

                            if not View then
                                View = true
                                CreateWeaponSpect2(v.model, ConfigBoutique.Position.PositionWeapon, ConfigBoutique.Position.PositionCamCoords, ConfigBoutique.Position.PositionWeaponHeading)
                            end
                        end

                        if Selected then
                            local Keyboard = ESXCustom_Function_ClientSide:KeyboardInput("Acheter l'arme ? (~g~Oui~s~ ou ~r~Non~s~)", 3)
                            if Keyboard == "oui" or Keyboard == "Oui" then
                                if tonumber(PlayerData.points) >= tonumber(v.price) then
                                    TriggerServerEvent("CorePickax:Boutique:Add", {id = k, model = v.model, price = tonumber(v.price), Nameweapon = v.name, Interaction = "weapon"})
                                    RageUI.GoBack()
                                else
                                    RageUI.GoBack()
                                    ESX.ShowNotification("~r~Vous n'avez pas assez de coins pour acheter cette arme~s~")
                                end
                                SetFocusEntity(PlayerPedId())
                            end
                            local cam = GetRenderingCam()
                            SetCamActive(cam, false)
                            RenderScriptCams(false, false, 0, true, true)
                            DeleteEntity(obj)
                        end
                    end)
                end
            end)

            RageUI.IsVisible(buyCustommenu, true, true, true, function()
                for k, v in pairs(ConfigBoutique.boost) do
                    local vehiculeZ = GetDisplayNameFromVehicleModel(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false)))
                    RageUI.Separator("↓ ~r~Informations sur votre vehicule ↓")
                    if vehiculeZ == nil then
                    else
                        RageUI.Separator("Nom de la voiture : ~o~"..vehiculeZ.."")
                    end
                    RageUI.ButtonWithStyle(ConfigBoutique.Menu.Bouton["Bouton_FullCustom2"], ConfigBoutique.Menu.Bouton["Bouton_FullCustom2_Desc"], {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                        if Active then
                            RageUI.Info(ConfigBoutique.Menu.Info["Title"], {(ConfigBoutique.Menu.Bouton["Bouton_FullCustom2_Info"]):format(vehiculeZ, v.price)}, {"", "", "", ""})
                        end

                        if Selected then
                            if IsPedInAnyVehicle(PlayerPedId(), false) then
                                local Keyboard = ESXCustom_Function_ClientSide:KeyboardInput("Acheter la custom ? (~g~Oui~s~ ou ~r~Non~s~)", 3)
                                if Keyboard == "oui" or Keyboard == "Oui" then
                                    if tonumber(PlayerData.points) >= tonumber(v.price) then
                                        if IsPedInAnyVehicle(PlayerPedId(), false) then
                                            local props = {}
                                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
                                            props['modTurbo'] = true
                                            ESX.Game.SetVehicleProperties(vehicle, {
                                                modTurbo = true,
                                                modEngine = 3,
                                                modBrakes = 2,
                                                modTransmission = 2,
                                                modSuspension = 3
                                            })
                                            TriggerServerEvent("CorePickax:Boutique:Add", {id = k, price = v.price, Interaction = "achatfullcustom"})
                                            ESX.ShowNotification("Votre véhicule a bien été full custom.")
                                        else
                                            ESX.ShowNotification("~r~vous devez êtres dans un véhicule pour faire sa !")
                                        end
                                    else
                                        ESX.ShowNotification("~r~Vous n'avez pas assez de coins pour acheter ce boost~s~")
                                    end
                                end
                            else
                                ESX.ShowNotification("~r~vous devez êtres dans un véhicule pour faire sa !")
                            end
                        end
                    end)
                end
            end)

            if not RageUI.Visible(store) and not RageUI.Visible(caissemenu) and not RageUI.Visible(caissemenu2) and not RageUI.Visible(menuPack) and not RageUI.Visible(entreprisemenu) and not RageUI.Visible(vehiclemenu) and not RageUI.Visible(weaponmenu) and not RageUI.Visible(weaponmenu2) and not RageUI.Visible(buyCustommenu) and not RageUI.Visible(adminMenu) and not RageUI.Visible(adminOnline) and not RageUI.Visible(adminRecent) and not RageUI.Visible(adminResults) and not RageUI.Visible(adminTarget) then
                MenuStore = false
                if ConfigBoutique.weaponCustom ~= nil and ConfigBoutique.weaponCustom then
                    TriggerEvent('esx:restoreLoadout')
                    VisualiserQQ = 0
                end
                store = RMenu:DeleteType('store', true)
                caissemenu = RMenu:DeleteType("caissemenu", true)
                caissemenu2 = RMenu:DeleteType("caissemenu2", true)
                menuPack = RMenu:DeleteType("menuPack", true)
                entreprisemenu = RMenu:DeleteType("entreprisemenu", true)
                vehiclemenu = RMenu:DeleteType("vehiclemenu", true)
                weaponmenu = RMenu:DeleteType("weaponmenu", true)
                buyCustommenu = RMenu:DeleteType("buyCustommenu", true)
                adminMenu = RMenu:DeleteType("adminMenu", true)
            end
        end
    end
end

RegisterKeyMapping(ConfigBoutique.Commande.CommandeName, ConfigBoutique.Commande.DescCommande, 'keyboard', ConfigBoutique.Commande.Bind)

RegisterCommand(ConfigBoutique.Commande.CommandeName, function()
    -- interface moderne (ressource pickax_boutique) si elle est démarrée ; sinon l'ancien menu RageUI
    if GetResourceState('pickax_boutique') == 'started' then
        exports['pickax_boutique']:Open()
    elseif MenuStore == false then
        OpenMenuBoutique()
    end
end)

function vehicle_give(veh, id, price)
    ESX.ShowNotification('Vous avez reçu votre :\n '..veh)
    Wait(10)
    SpawnLocalVehicle(veh, vec3(0.0, 0.0, 0.0), 0.0, function(vehicle)
        plate = GeneratePlate()
        local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
        vehicleProps.plate = plate
        TriggerServerEvent('CorePickax:registerkey', plate, 'no', false)
        SetVehicleNumberPlateText(vehicle, plate)
        TriggerServerEvent("CorePickax:Boutique:Add", {vehicle = vehicleProps, vehicle_plate = plate, price = price, veh = veh, id = id, Interaction = "vehicle"})
        Wait(1000)
        DeleteEntity(vehicle)
	end)
end

function vehicleMotoGive(veh, id, price)
    ESX.ShowNotification('Vous avez reçu votre :\n '..veh)
    local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
    Wait(10)
    SpawnLocalVehicle(veh, vec3(0.0, 0.0, 0.0), 0.0, function(vehicle)
        plate = GeneratePlate()
        local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
        vehicleProps.plate = plate
        SetVehicleNumberPlateText(vehicle , plate)
        TriggerServerEvent('CorePickax:registerkey', plate, 'no', false)
        TriggerServerEvent("CorePickax:Boutique:Add", {vehicle = vehicleProps, vehicle_plate = plate, price = price, veh = veh, id = id, Interaction = "Moto"})
        Wait(1000)
        DeleteEntity(vehicle)
	end)
end

function vehicleOtherGive(veh, id, price, type)
    ESX.ShowNotification('Vous avez reçu votre :\n '..veh)
    local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
    Wait(10)
    SpawnLocalVehicle(veh, vec3(0.0, 0.0, 0.0), 0.0, function(vehicle)
        plate = GeneratePlate()
        local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
        vehicleProps.plate = plate
        SetVehicleNumberPlateText(vehicle , plate)
        TriggerServerEvent('CorePickax:registerkey', plate, 'no', false)
        TriggerServerEvent("CorePickax:Boutique:Add", {type = type, vehicle = vehicleProps, vehicle_plate = plate, price = price, veh = veh, id = id, Interaction = "OtherVehicle"})
        Wait(1000)
        DeleteEntity(vehicle)
	end)
end

RegisterNetEvent("CorePickax:openESXCustom")
AddEventHandler("CorePickax:openESXCustom", function(data, refund, nameCaisse)
    ESX.ShowNotification("~p~Vous avez utilisé un caisse veuillez attendre 5 secondes.")
	local sum = 0
	draw = {}
	for k, v in pairs(ConfigBoutique["ESXCustom"][data].list) do
		local rate = ConfigBoutique["chance"][v.tier].rate * 100
		for i=1,rate do 
			if v.item then
				if v.amount then
					table.insert(draw, {item = v.item ,amount = v.amount, tier = v.tier})
				else
					table.insert(draw, {item = v.item ,amount = 1, tier = v.tier})
				end
			elseif v.weapon then
				table.insert(draw, {weapon = v.weapon , tier = v.tier})
            elseif v.Coins then
				table.insert(draw, {Coins = v.Coins , tier = v.tier})
			elseif v.vehicle then
				table.insert(draw, {vehicle = v.vehicle, tier = v.tier})
			elseif v.money then
				table.insert(draw, {money = v.money, tier = v.tier})
			elseif v.black_money then
				table.insert(draw, {black_money = v.black_money, tier = v.tier})
			end
			i = i + 1
		end
		sum = sum + rate
	end
	local random = math.random(1,sum)
	Wait(6000)
	if draw[random].item then
		TriggerServerEvent('ESXCustomBoutique:giveReward', 'item', draw[random].item, draw[random].amount, {name = nameCaisse, price = refund})
        ESX.ShowNotification("Vous avez gagné : "..draw[random].amount)
	elseif draw[random].weapon then
		TriggerServerEvent('ESXCustomBoutique:giveReward', 'weapon', draw[random].weapon, refund, {name = nameCaisse, price = refund})
        ESX.ShowNotification("Vous avez gagné : "..draw[random].weapon)
    elseif draw[random].Coins then
		TriggerServerEvent('ESXCustomBoutique:giveReward', 'Coins', draw[random].Coins, nil, {name = nameCaisse, price = refund})
        ESX.ShowNotification("Vous avez gagné : "..draw[random].Coins.."Coins")
	elseif draw[random].vehicle then
		TriggerEvent('CorePickax:RewardVehicle', draw[random].vehicle)
        ESX.ShowNotification("Vous avez gagné : "..draw[random].vehicle)
		TriggerServerEvent('ESXCustomBoutique:giveReward', 'Vehicle', draw[random].vehicle, nil, {name = nameCaisse, price = refund})
	elseif draw[random].money then
		TriggerServerEvent('ESXCustomBoutique:giveReward', 'money', draw[random].money, nil, {name = nameCaisse, price = refund})
        ESX.ShowNotification("Vous avez gagné : ~g~"..draw[random].money.."Argent")
	elseif draw[random].black_money then
		TriggerServerEvent('ESXCustomBoutique:giveReward', 'black_money', draw[random].black_money, nil, {name = nameCaisse, price = refund})
        ESX.ShowNotification("Vous avez gagné : ~r~"..draw[random].black_money.."Argent sale")
	end
end)

RegisterNetEvent('mkbussZ:RewardVehicleCar')
AddEventHandler('mkbussZ:RewardVehicleCar', function(model)
    local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
    Citizen.Wait(10)
    SpawnLocalVehicle(model, vec3(0.0, 0.0, 0.0), 0.0, function(vehicle)
        local plate = GeneratePlate()
        local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
        vehicleProps.plate = plate
        SetVehicleNumberPlateText(vehicle , plate)
        TriggerServerEvent('CorePickax:registerkey', plate, 'no', false)
        TriggerServerEvent("CorePickax:Boutique:Add", {vehicleProps = vehicleProps, plate_625 = plate, Interaction = "GiveVehPack"})
        DeleteEntity(vehicle)
    end)
end)

RegisterNetEvent('CorePickax:RewardVehicle')
AddEventHandler('CorePickax:RewardVehicle', function(model)
    local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
    Citizen.Wait(10)
    SpawnLocalVehicle(model, vec3(0.0, 0.0, 0.0), 0.0, function(vehicle)
        local plate = GeneratePlate()
        local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
        vehicleProps.plate = plate
        SetVehicleNumberPlateText(vehicle , plate)
        TriggerServerEvent('CorePickax:registerkey', plate, 'no', false)
        TriggerServerEvent("CorePickax:Boutique:Add", {vehicleProps = vehicleProps, plate_625 = plate, Interaction = "GiveVehCaisse"})
        DeleteEntity(vehicle)
    end)
end)

--SeeWeapon
RegisterNetEvent("ESXCustomBoutique:CreateWeaponSpect")
AddEventHandler("ESXCustomBoutique:CreateWeaponSpect", function(modelHash, Coords, CamCoords, headingCam, FOV)
    Citizen.CreateThread(function()
		if not HasModelLoaded(modelHash) and IsModelInCdimage(modelHash) then
			RequestModel(modelHash)
	
			while not HasModelLoaded(modelHash) do
				Citizen.Wait(1)
			end
		end

		buttons = setupScaleform("instructional_buttons")
		Wait(1)
		local rot = 0.0
        if obj == nil then
            obj = nil

		    obj = CreateObject(modelHash, Coords, true, false, true)
            FreezeEntityPosition(obj, true)
            SetEntityInvincible(obj, true)
            SetEntityHeading(obj, rot)
        else
            DeleteEntity(obj)
            obj = nil

            obj = CreateObject(modelHash, Coords, true, false, true)
            FreezeEntityPosition(obj, true)
            SetEntityInvincible(obj, true)
            SetEntityHeading(obj, rot)
        end
        
        if not DoesCamExist(CamOBJ) then
            CamOBJ = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        end
        SetCamCoord(CamOBJ, vector3(CamCoords))
        SetCamRot(CamOBJ, 0.0, 0.0, headingCam)
        if FOV ~= nil then
            SetCamFov(CamOBJ, FOV)
        end
        SetCamActive(CamOBJ, true)
        RenderScriptCams(true, false, 0, true, true)
        local interiorId = GetInteriorAtCoords(CamCoords)
        if IsValidInterior(interiorId) then
            LoadInterior(interiorId)
        end
        SetFocusArea(Coords, 0.0, 0.0, 0.0)

		while true do
			Wait(0)

			DrawScaleformMovieFullscreen(buttons)
			rot = rot + 0.10
			SetEntityHeading(obj, rot)
            
			if IsControlPressed(0, ConfigBoutique.Control.ControlPressedDelete) then
				DeleteEntity(obj)
				RenderScriptCams(false, false, 0, 1, 0)
				DestroyCam(CamOBJ, true)
				break
			end
		end
	end)
end)

CreateWeaponSpect2 = function(modelHash, Coords, CamCoords, headingCam, FOV)
    Citizen.CreateThread(function()
		-- if not HasModelLoaded(modelHash) and IsModelInCdimage(modelHash) then
		-- 	RequestModel(modelHash)
	
		-- 	while not HasModelLoaded(modelHash) do
		-- 		Citizen.Wait(1)
		-- 	end
		-- end

		buttons = setupScaleform("instructional_buttons")
		Wait(1)
        modelHash = GetHashKey(modelHash)

		local rot = 0.0
        if obj == nil then
            obj = nil

            ESXCustom_Function_ClientSide:LoadWeaponObj(modelHash)
            obj = CreateWeaponObject(modelHash, 50, Coords, true, 1.0, 0)
		    -- obj = CreateObject(modelHash, Coords, false, false, true)
            FreezeEntityPosition(obj, true)
            SetEntityInvincible(obj, true)
            SetEntityHeading(obj, rot)
        else
            DeleteEntity(obj)
            obj = nil

            ESXCustom_Function_ClientSide:LoadWeaponObj(modelHash)
            obj = CreateWeaponObject(modelHash, 50, Coords, true, 1.0, 0)
            -- obj = CreateObject(modelHash, Coords, false, false, true)
            FreezeEntityPosition(obj, true)
            SetEntityInvincible(obj, true)
            SetEntityHeading(obj, rot)
        end
        
        if not DoesCamExist(CamWeapon) then
            CamWeapon = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        end
        SetCamCoord(CamWeapon, vector3(CamCoords))
        SetCamRot(CamWeapon, 0.0, 0.0, headingCam)
        if FOV ~= nil then
            SetCamFov(CamWeapon, FOV)
        end
        SetCamActive(CamWeapon, true)
        RenderScriptCams(true, false, 0, true, true)
        local interiorId = GetInteriorAtCoords(CamCoords)
        if ConfigBoutique.Position.PositionInterriorWeapon then
            if IsValidInterior(interiorId) then
                LoadInterior(interiorId)
            end
        else
            SetFocusArea(ConfigBoutique.Position.PositionWeapon.x, ConfigBoutique.Position.PositionWeapon.y, ConfigBoutique.Position.PositionWeapon.z, 0.0, 0.0, 0.0)
        end

		while true do
			Wait(0)

			DrawScaleformMovieFullscreen(buttons)
			rot = rot + 0.10
			SetEntityHeading(obj, rot)
            
			if IsControlPressed(0, ConfigBoutique.Control.ControlPressedDelete) then
				DeleteEntity(obj)
				RenderScriptCams(false, false, 0, 1, 0)
				DestroyCam(CamWeapon, true)

                SetFocusEntity(PlayerPedId())
				break
			end
		end
	end)
end

function ButtonMessage(text)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

function Button(ControlButton)
    N_0xe83a3e3557a56640(ControlButton)
end

function setupScaleform(scaleform)
    local scaleform = RequestScaleformMovie(scaleform)

    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(1)
    end

    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()
    
    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(1)
    Button(GetControlInstructionalButton(2, ConfigBoutique.Control.ControlPressedRotation, true))
    ButtonMessage(ConfigBoutique.Message.Rotation)
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(0)
    Button(GetControlInstructionalButton(2, ConfigBoutique.Control.ControlPressedDelete, true))
    ButtonMessage(ConfigBoutique.Message.Delete)
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()

    return scaleform
end

function SpawnLocalVehicle(modelName, coords, heading, cb)
	local model = (type(modelName) == 'number' and modelName or GetHashKey(modelName))

	Citizen.CreateThread(function()
		ESX.Streaming.RequestModel(model)

		local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, false, false)

		SetEntityAsMissionEntity(vehicle, true, false)
		SetVehicleHasBeenOwnedByPlayer(vehicle, true)
		SetVehicleNeedsToBeHotwired(vehicle, false)
		SetModelAsNoLongerNeeded(model)
		RequestCollisionAtCoord(coords.x, coords.y, coords.z)

		while not HasCollisionLoadedAroundEntity(vehicle) do
			RequestCollisionAtCoord(coords.x, coords.y, coords.z)
			Citizen.Wait(0)
		end

		SetVehRadioStation(vehicle, 'OFF')

		if cb then
			cb(vehicle)
		end
	end)
end

-- ═══════════════════════════ Passerelle vers pickax_boutique (interface NUI) ═══════════════════════════
-- La boutique garde TOUTE sa logique (prix vérifiés par le serveur, livraison des véhicules, packs, caisses…) :
-- la nouvelle interface appelle simplement les mêmes événements que l'ancien menu RageUI.
local function stripCodes(str) return (tostring(str or ''):gsub('~[a-zA-Z]~', '')) end

local function packContents(win)
    local out = {}
    for _, i in ipairs(win or {}) do
        if i.item then out[#out + 1] = ('%dx %s'):format(tonumber(i.amount) or 1, i.item)
        elseif i.money then out[#out + 1] = ('%s $'):format(tostring(i.money))
        elseif i.weapon then out[#out + 1] = tostring(i.weapon)
        elseif i.Vehicle then out[#out + 1] = ('Véhicule : %s'):format(tostring(i.Vehicle))
        elseif i.vip then out[#out + 1] = ('Statut VIP niveau %s pendant %s jours'):format(tostring(i.vip), tostring(i.days or 31)) end
    end
    return out
end

local function conv(list, kind)
    local out = {}
    for k, v in ipairs(list or {}) do
        if not v.Separator then
            out[#out + 1] = { idx = k, name = v.name, model = v.model, price = tonumber(v.price) or 0, desc = stripCodes(v.desc), balle = v.balle, vtype = v.type,
                contents = kind == 'pack' and packContents(v.Win) or nil }
        end
    end
    return out
end

exports('BoutiqueCatalog', function()
    return {
        points = tonumber(PlayerData.points) or 0, staff = PlayerData.Staff == true, link = ConfigBoutique.LinkShop, boutiqueId = PlayerData.boutique_id,
        vehicle = conv(ConfigBoutique.vehicle), moto = conv(ConfigBoutique.Motos), other = conv(ConfigBoutique.Autres), weapon = conv(ConfigBoutique.weapon),
        crate = conv(ConfigBoutique.caisse), pack = conv(ConfigBoutique.pack, 'pack'), vip = conv(ConfigBoutique.vip, 'pack'), business = conv(ConfigBoutique.Entreprise),
    }
end)

exports('BoutiquePoints', function() return tonumber(PlayerData.points) or 0 end)

exports('BoutiqueOpenClassic', function()
    if MenuStore == false then OpenMenuBoutique() end
end)

exports('BoutiqueBuy', function(cat, idx, skipCheck)
    local lists = { vehicle = ConfigBoutique.vehicle, moto = ConfigBoutique.Motos, other = ConfigBoutique.Autres, weapon = ConfigBoutique.weapon,
        crate = ConfigBoutique.caisse, pack = ConfigBoutique.pack, vip = ConfigBoutique.vip or {}, business = ConfigBoutique.Entreprise }
    local k = tonumber(idx)
    local v = lists[cat] and k and lists[cat][k]
    if not v or v.Separator then return { ok = false, error = 'Article introuvable' } end
    local price = tonumber(v.price) or 0
    if not skipCheck and (tonumber(PlayerData.points) or 0) < price then return { ok = false, error = 'Tu n\'as pas assez de coins' } end      -- skipCheck : panier déjà contrôlé (remise) par le serveur
    CreateThread(function()
        if cat == 'vehicle' then vehicle_give(v.model, k, v.price)
        elseif cat == 'moto' then vehicleMotoGive(v.model, k, v.price)
        elseif cat == 'other' then vehicleOtherGive(v.model, k, v.price, v.type)
        elseif cat == 'weapon' then
            TriggerServerEvent("CorePickax:Boutique:Add", { id = k, model = v.model, price = price, Nameweapon = v.name, Interaction = "weapon" })
        elseif cat == 'crate' then
            TriggerServerEvent("CorePickax:Boutique:Add", { id = k, price = price, item = v.model, nameitem = v.name, Interaction = "giveitem" })
        elseif cat == 'pack' then
            TriggerServerEvent("CorePickax:Boutique:Add", { id = k, price = price, Interaction = "BuyPack" })
            for _, i in pairs(v.Win) do
                if i.item then
                    TriggerServerEvent('ESXCustomBoutique:giveReward', 'item', i.item, i.amount)
                elseif i.Vehicle then
                    TriggerEvent('mkbussZ:RewardVehicleCar', i.Vehicle)
                    Wait(100)
                elseif i.money then
                    TriggerServerEvent('ESXCustomBoutique:giveReward', 'money', i.money)
                elseif i.weapon then
                    TriggerServerEvent('ESXCustomBoutique:giveReward', 'weapon', i.weapon)
                end
            end
            ESX.ShowNotification("Vous avez reçu votre pack")
        elseif cat == 'vip' then
            TriggerServerEvent("CorePickax:Boutique:Add", { id = k, price = price, name = v.name, Interaction = "BuyVip" })
            ESX.ShowNotification("Votre VIP est en cours d'activation")
        elseif cat == 'business' then
            TriggerServerEvent("CorePickax:Boutique:Add", { id = k, price = price, name = v.name, Interaction = "entrepriseachat" })
        end
    end)
    return { ok = true }
end)
