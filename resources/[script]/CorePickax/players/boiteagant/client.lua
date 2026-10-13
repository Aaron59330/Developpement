local MenuOpen = false
local function OpenMenu()
    MenuOpen = true
    local mainmenu = RageUI.CreateMenu(ConfigBoiteAGant.Menu.TitleMenu, (ConfigBoiteAGant.Menu.SubtitleMenu):format(GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false))))

	RageUI.Visible(mainmenu, not RageUI.Visible(mainmenu))

	while mainmenu do
		Wait(0)
		RageUI.IsVisible(mainmenu, true, true, true, function()
            for k,v in pairs(ConfigBoiteAGant.Menu) do
                if v.type ~= nil then
                    if v.type == "Separator" then
                        RageUI.Separator(v.title)
                    elseif v.type == "Line" then
                        RageUI.Line()
                    elseif v.type == "Bouton" then
                        RageUI.ButtonWithStyle(v.title, v.desc, {RightLabel = v.RightLabel}, true, function(Hovered, Active, Selected)
                            if Selected then
                                v.OnClick(GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false)))
								MenuOpen = false
                            end
                        end)
                    end
                end
            end
		end)

        if not MenuOpen or not (GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), 0) == PlayerPedId()) then
            RageUI.Visible(mainmenu, false)
            MenuOpen = false
        end

		if not RageUI.Visible(mainmenu) then
            MenuOpen = false
			mainmenu = RMenu:DeleteType("mainmenu")
		end
	end
end

CreateThread(function()
	while true do
		local timer = 200
		if IsPedInAnyVehicle(PlayerPedId(), false) and (GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), 0) == PlayerPedId()) then
			if not IsThisModelABicycle(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false))) and not IsThisModelABike(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false))) then
				timer = 0
				ESX.ShowHelpNotification(ConfigBoiteAGant.MenuEtNotification["PushE"])
				if IsControlJustPressed(1,51) then
					if not MenuOpen then
						OpenMenu()
					end
				end
			end
		end
		Wait(timer)
	end
end)

local Menu = {
	Index = 1
}

function OpenMenuDeposerBoiteGant()
	ESX.PlayerData = ESX.GetPlayerData()

	local InfoTableReceive2 = 0
	ESX.TriggerServerCallback("CorePickax:getInventoryByPlate", function(InfoReceive)
		InfoTableReceive2 = InfoReceive.ItemMax
	end, GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false)))

    MenuOpen = true
    local mainmenu = RageUI.CreateMenu(ConfigBoiteAGant.Menu.TitleMenu, (ConfigBoiteAGant.Menu.SubtitleMenu):format(GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false))))

    Items = {}

    for i = 1, #ESX.PlayerData.inventory, 1 do
        if ESX.PlayerData.inventory[i].count > 0 then
            table.insert(Items, {label = ESX.PlayerData.inventory[i].label, name = ESX.PlayerData.inventory[i].name, itemType = 'item_standard', amount = ESX.PlayerData.inventory[i].count})
        end
    end

	Armes = {}

	local weaponList = ESX.GetWeaponList()
	for i=1, #weaponList, 1 do
		local weaponHash = GetHashKey(weaponList[i].name)
		local ammo = GetAmmoInPedWeapon(PlayerPedId(), weaponHash)
		if HasPedGotWeapon(PlayerPedId(), weaponHash, false) and weaponList[i].name ~= 'WEAPON_UNARMED' then
			table.insert(Armes, {label = weaponList[i].label, name = weaponList[i].name, itemType = 'item_weapon', amount = 1, ammo = ammo})
		end
	end

	RageUI.Visible(mainmenu, not RageUI.Visible(mainmenu))

	while mainmenu do
		Wait(0)
		RageUI.IsVisible(mainmenu, true, true, true, function()
			if ConfigBoiteAGant.WeaponItem then
				RageUI.List(ConfigBoiteAGant.MenuEtNotification["Trier"], {"Items", "Armes", "Munitions"}, Menu.Index, nil, {}, true, function(Hovered, Active, Selected, Index)
					Menu.Index = Index
				end)

				if Menu.Index == 1 then
					RageUI.Line()
					for k,v in pairs(Items) do
						if not string.find(v.name, "weapon_") and not string.find(v.name, "ammo_") then
							if v.amount > 0 then
								RageUI.ButtonWithStyle(v.label, nil, {RightLabel = "~g~x"..v.amount}, true, function(_, _, s)
									if s then
										local check, amount = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput(ConfigBoiteAGant.MenuEtNotification["Input"], 10))
										if check then
											if InfoTableReceive2 > ConfigBoiteAGant.MaxCoffreItem then
												ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["BoiteGantsPleins"])
											else
												if tonumber(amount) > (ConfigBoiteAGant.MaxCoffreItem - InfoTableReceive2) then
													ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["BoiteGantsPleins"])
												else
													if tonumber(amount) > v.amount then
														ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["ErrorQuantity"])
													else
														TriggerServerEvent('CorePickax:GestionItem', "deposit", v.name, tonumber(amount), v.label, v.itemType)
														RageUI.CloseAll()
													end
												end
											end
										else
											ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["Error2"])
										end
									end
								end)
							end
						end
					end
				elseif Menu.Index == 2 then
					RageUI.Line()
					for k, v in pairs(Items) do
						if v.amount > 0 then
							if string.find(v.name, "weapon_") and not string.find(v.name, "ammo_") then
								ammo = 0
								if Config.ArmesPerm[v.name] then
									RageUI.ButtonWithStyle(""..v.label, nil, { RightLabel = (ConfigBoiteAGant.MenuEtNotification["ammo"]):format(ammo)}, false, function(_,_,s)
									end)
								else
									RageUI.ButtonWithStyle(""..v.label, nil, { RightLabel = (ConfigBoiteAGant.MenuEtNotification["ammo"]):format(ammo) }, true, function(_,_,s)
										if s then
											local check, amount = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput(ConfigBoiteAGant.MenuEtNotification["Input"], 10))
											if check then
												if InfoTableReceive2 > ConfigBoiteAGant.MaxCoffreItem then
													ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["BoiteGantsPleins"])
												else
													if tonumber(amount) > (ConfigBoiteAGant.MaxCoffreItem - InfoTableReceive2) then
														ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["BoiteGantsPleins"])
													else
														if tonumber(amount) > v.amount then
															ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["ErrorQuantity"])
														else
															TriggerServerEvent('CorePickax:GestionItem', "deposit", v.name, tonumber(amount), v.label, v.itemType)
															RageUI.CloseAll()
														end
													end
												end
											else
												ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["Error2"])
											end
										end
									end)
								end
							end
						end
					end
				elseif Menu.Index == 3 then
					RageUI.Line()
					for k, v in pairs(Items) do
						if v.amount > 0 then
							if string.find(v.name, "ammo_") and not string.find(v.name, "weapon_") then
								RageUI.ButtonWithStyle(v.label, nil, { RightLabel = (ConfigBoiteAGant.MenuEtNotification["rightlabel"]):format(v.amount) }, true, function(_,_,s)
									if s then
										local check, amount = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput(ConfigBoiteAGant.MenuEtNotification["Input"], 10))
										if check then
											if InfoTableReceive2 > ConfigBoiteAGant.MaxCoffreItem then
												ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["BoiteGantsPleins"])
											else
												if tonumber(amount) > (ConfigBoiteAGant.MaxCoffreItem - InfoTableReceive2) then
													ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["BoiteGantsPleins"])
												else
													if tonumber(amount) > v.amount then
														ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["ErrorQuantity"])
													else
														TriggerServerEvent('CorePickax:GestionItem', "deposit", v.name, tonumber(amount), v.label, v.itemType)
														RageUI.CloseAll()
													end
												end
											end
										else
											ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["Error2"])
										end
									end
								end)
							end
						end
					end
				end
			else
				RageUI.List(ConfigBoiteAGant.MenuEtNotification["Trier"], {"Items", "Armes"}, Menu.Index, nil, {}, true, function(Hovered, Active, Selected, Index)
					Menu.Index = Index
				end)

				if Menu.Index == 1 then
					RageUI.Line()
					for k,v in pairs(Items) do
						if v.amount > 0 then
							RageUI.ButtonWithStyle(v.label, nil, {RightLabel = "~g~x"..v.amount}, true, function(_, _, s)
								if s then
									local check, amount = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput(ConfigBoiteAGant.MenuEtNotification["Input"], 10))
									if check then
										if InfoTableReceive2 > ConfigBoiteAGant.MaxCoffreItem then
											ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["BoiteGantsPleins"])
										else
											if tonumber(amount) > (ConfigBoiteAGant.MaxCoffreItem - InfoTableReceive2) then
												ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["BoiteGantsPleins"])
											else
												if tonumber(amount) > v.amount then
													ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["ErrorQuantity"])
												else
													TriggerServerEvent('CorePickax:GestionItem', "deposit", v.name, tonumber(amount), v.label, v.itemType)
													RageUI.CloseAll()
												end
											end
										end
									else
										ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["Error2"])
									end
								end
							end)
						end
					end
				elseif Menu.Index == 2 then
					RageUI.Line()
					for k, v in pairs(Armes) do
						if v.amount > 0 then
							if Config.ArmesPerm[v.name] then
								RageUI.ButtonWithStyle(""..v.label, nil, { RightLabel = (ConfigBoiteAGant.MenuEtNotification["ammo"]):format(v.ammo)}, false, function(_,_,s)
								end)
							else
								RageUI.ButtonWithStyle(""..v.label, nil, { RightLabel = (ConfigBoiteAGant.MenuEtNotification["ammo"]):format(v.ammo) }, true, function(_,_,s)
									if s then
										local check, amount = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput(ConfigBoiteAGant.MenuEtNotification["Input"], 10))
										if check then
											if InfoTableReceive2 > ConfigBoiteAGant.MaxCoffreItem then
												ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["BoiteGantsPleins"])
											else
												if tonumber(amount) > (ConfigBoiteAGant.MaxCoffreItem - InfoTableReceive2) then
													ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["BoiteGantsPleins"])
												else
													if tonumber(amount) > v.amount then
														ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["ErrorQuantity"])
													else
														TriggerServerEvent('CorePickax:GestionItem', "deposit", v.name, tonumber(amount), v.label, v.itemType, v.ammo)
														RageUI.CloseAll()
													end
												end
											end
										else
											ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["Error2"])
										end
									end
								end)
							end
						end
					end
				end
			end
		end)

        if not MenuOpen or not (GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), 0) == PlayerPedId()) then
            RageUI.Visible(mainmenu, false)
            MenuOpen = false
        end

		if not RageUI.Visible(mainmenu) then
            MenuOpen = false
			mainmenu = RMenu:DeleteType("mainmenu")
		end
	end
end

function OpenMenuPrendreBoiteGant()
    MenuOpen = true
    local mainmenu = RageUI.CreateMenu(ConfigBoiteAGant.Menu.TitleMenu, (ConfigBoiteAGant.Menu.SubtitleMenu):format(GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false))))
	RageUI.Visible(mainmenu, not RageUI.Visible(mainmenu))

	local InfoTableReceive = {}
	local InfoTableReceive2 = 0
	ESX.TriggerServerCallback("CorePickax:getInventoryByPlate", function(InfoReceive)
		InfoTableReceive = InfoReceive.data
		InfoTableReceive2 = InfoReceive.ItemMax
	end, GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false)))

	while mainmenu do
		Wait(0)
		RageUI.IsVisible(mainmenu, true, true, true, function()
			RageUI.Separator((ConfigBoiteAGant.MenuEtNotification.TakeMenu["Separator"]):format(InfoTableReceive2, ConfigBoiteAGant.MaxCoffreItem))
			if ConfigBoiteAGant.WeaponItem then
				RageUI.List(ConfigBoiteAGant.MenuEtNotification["Trier"], {"Items", "Armes", "Munitions"}, Menu.Index, nil, {}, true, function(Hovered, Active, Selected, Index)
					Menu.Index = Index
				end)
				if Menu.Index == 1 then
					for b, c in pairs(InfoTableReceive) do
						for k, v in pairs(InfoTableReceive[b]) do
							if v.amount > 0 then
								if not string.find(v.name, "weapon_") and not string.find(v.name, "ammo_") then
									RageUI.ButtonWithStyle((ConfigBoiteAGant.MenuEtNotification.TakeMenu["Bouton"]):format(v.label), nil, {RightLabel = (ConfigBoiteAGant.MenuEtNotification.TakeMenu["RightLabel"]):format(v.amount)}, true, function(_, _, s)
										if s then
											local check, amount = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput(ConfigBoiteAGant.MenuEtNotification["Input"], 10))
											if check then
												if tonumber(amount) > v.amount then
													ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["ErrorQuantity"])
												else
													TriggerServerEvent('CorePickax:GestionItem', "take", b, tonumber(amount), v.label, v.itemType)
													RageUI.CloseAll()
												end
											else
												ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["Error2"])
											end
										end
									end)
								end
							end
						end
					end
				elseif Menu.Index == 2 then
					for b, c in pairs(InfoTableReceive) do
						for k, v in pairs(InfoTableReceive[b]) do
							if v.amount > 0 then
								if string.find(v.name, "weapon_") and not string.find(v.name, "ammo_") then
									RageUI.ButtonWithStyle((ConfigBoiteAGant.MenuEtNotification.TakeMenu["Bouton"]):format(v.label), nil, {RightLabel = (ConfigBoiteAGant.MenuEtNotification.TakeMenu["RightLabel"]):format(v.amount)}, true, function(_, _, s)
										if s then
											local check, amount = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput(ConfigBoiteAGant.MenuEtNotification["Input"], 10))
											if check then
												if tonumber(amount) > v.amount then
													ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["ErrorQuantity"])
												else
													TriggerServerEvent('CorePickax:GestionItem', "take", b, tonumber(amount), v.label, v.itemType)
													RageUI.CloseAll()
												end
											else
												ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["Error2"])
											end
										end
									end)
								end
							end
						end
					end
				elseif Menu.Index == 3 then
					for b, c in pairs(InfoTableReceive) do
						for k, v in pairs(InfoTableReceive[b]) do
							if v.amount > 0 then
								if string.find(v.name, "ammo_") and not string.find(v.name, "weapon_") then
									RageUI.ButtonWithStyle((ConfigBoiteAGant.MenuEtNotification.TakeMenu["Bouton"]):format(v.label), nil, {RightLabel = (ConfigBoiteAGant.MenuEtNotification.TakeMenu["RightLabel"]):format(v.amount)}, true, function(_, _, s)
										if s then
											local check, amount = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput(ConfigBoiteAGant.MenuEtNotification["Input"], 10))
											if check then
												if tonumber(amount) > v.amount then
													ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["ErrorQuantity"])
												else
													TriggerServerEvent('CorePickax:GestionItem', "take", b, tonumber(amount), v.label, v.itemType)
													RageUI.CloseAll()
												end
											else
												ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["Error2"])
											end
										end
									end)
								end
							end
						end
					end
				end
			else
				RageUI.List(ConfigBoiteAGant.MenuEtNotification["Trier"], {"Items", "Armes"}, Menu.Index, nil, {}, true, function(Hovered, Active, Selected, Index)
					Menu.Index = Index
				end)
				if Menu.Index == 1 then
					for b, c in pairs(InfoTableReceive) do
						for k, v in pairs(InfoTableReceive[b]) do
							if not v.isWeapon then
								if v.amount > 0 then
									RageUI.ButtonWithStyle((ConfigBoiteAGant.MenuEtNotification.TakeMenu["Bouton"]):format(v.label), nil, {RightLabel = (ConfigBoiteAGant.MenuEtNotification.TakeMenu["RightLabel"]):format(v.amount)}, true, function(_, _, s)
										if s then
											local check, amount = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput(ConfigBoiteAGant.MenuEtNotification["Input"], 10))
											if check then
												if tonumber(amount) > v.amount then
													ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["ErrorQuantity"])
												else
													TriggerServerEvent('CorePickax:GestionItem', "take", b, tonumber(amount), v.label, v.itemType)
													RageUI.CloseAll()
												end
											else
												ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["Error2"])
											end
										end
									end)
								end
							end
						end
					end
				elseif Menu.Index == 2 then
					for b, c in pairs(InfoTableReceive) do
						for k, v in pairs(InfoTableReceive[b]) do
							if v.isWeapon then
								if v.amount > 0 then
									RageUI.ButtonWithStyle((ConfigBoiteAGant.MenuEtNotification.TakeMenu["Bouton"]):format(v.label), nil, {RightLabel = (ConfigBoiteAGant.MenuEtNotification["ammo"]):format(v.ammo)}, true, function(_, _, s)
										if s then
											local check, amount = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput(ConfigBoiteAGant.MenuEtNotification["Input"], 10))
											if check then
												if tonumber(amount) > v.amount then
													ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["ErrorQuantity"])
												else
													TriggerServerEvent('CorePickax:GestionItem', "take", b, tonumber(amount), v.label, "item_weapon")
													RageUI.CloseAll()
												end
											else
												ESX.ShowNotification(ConfigBoiteAGant.MenuEtNotification["Error2"])
											end
										end
									end)
								end
							end
						end
					end
				end
			end
		end)

        if not MenuOpen or not (GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), 0) == PlayerPedId()) then
            RageUI.Visible(mainmenu, false)
            MenuOpen = false
        end

		if not RageUI.Visible(mainmenu) then
            MenuOpen = false
			mainmenu = RMenu:DeleteType("mainmenu")
		end
	end
end