local Action = {
	Cross = false,
	Radar = false,
	Hud = false,
	WindowsList = {"Avant Gauche", "Avant Droite", "Arrière Gauche", "Arrière Droite"},
	WindowsIndex = 1,
	DoorState = {
		FrontLeft = false,
		FrontRight = false,
		BackLeft = false,
		BackRight = false,
		Hood = false,
		Trunk = false
	},
	WindowsState = {
		FrontLeft = false,
		FrontRight = false,
		BackLeft = false,
		BackRight = false,
	},
	DoorIndex = 1,
	DoorList = {"Avant Gauche", "Avant Droite", "Arrière Gauche", "Arrière Droite"},
	LimitateurList = {"50 km/h", "80 km/h", "120 km/h", "Personnaliser", "Désactiver"},
	LimitateurIndex = 1
}

local BillData = {}
local Breakable = false

local disabledLourdKeys = {
	{group = 2, key = 37},
	{group = 0, key = 24},
	{group = 0, key = 69},
	{group = 0, key = 92},
	{group = 0, key = 140},
	{group = 0, key = 106},
	{group = 0, key = 21},
	{group = 0, key = 22},
}


Citizen.CreateThread(function()
	while GetResourceState('ox_inventory') ~= 'started' do
		Wait(250)
	end

	while true do
		local timer = 1000
		local currentWeight = exports.ox_inventory:GetPlayerWeight() or 0
		local maxWeight = exports.ox_inventory:GetPlayerMaxWeight() or 0

		if maxWeight > 0 and currentWeight > maxWeight then
			timer = 0

			if not InAFK then
				RageUI.Text({message = "~r~Vous êtes trop lourd~s~", time_display = 1})
				for i = 1, #disabledLourdKeys, 1 do
					DisableControlAction(disabledLourdKeys[i].group, disabledLourdKeys[i].key, true)
				end
			end
		end

		Wait(timer)
	end
end)

local function OpenMenu()
	ESX.PlayerData = ESX.GetPlayerData()
    local mainmenu = RageUI.CreateMenu("Menu Personnel", "Actions disponibles :")
	local Informations = RageUI.CreateSubMenu(mainmenu, "Mon portefeuille", "Informations :")
	local Parametres = RageUI.CreateSubMenu(mainmenu, "Paramètres", "Paramètres disponibles :")
	local editorMenu = RageUI.CreateSubMenu(Parametres, "Rockstar editor", "Que voulez-vous faire ?")
	local Facture = RageUI.CreateSubMenu(Informations, "Vos facture", "Que voulez-vous faire ?")
	local MenuVehicle = RageUI.CreateSubMenu(mainmenu, "Vehicule", "Que voulez-vous faire ?")

	RageUI.Visible(mainmenu, not RageUI.Visible(mainmenu))

	while mainmenu do
		Wait(0)
		RageUI.IsVisible(mainmenu, true, true, true, function()
			RageUI.Separator("Connecte en tant qu'id [~p~"..GetPlayerServerId(PlayerId()).."~s~].")
			RageUI.ButtonWithStyle("Mon portefeuille", "Accéder à votre portefeuille", {RightLabel = "→→→"}, true, function(_, _, s)
			end, Informations)
			RageUI.ButtonWithStyle("Mes paramètres", "Accéder à votre paramètres", {RightLabel = "→→→"}, true, function(_, _, s)
			end, Parametres)
			if IsPedInAnyVehicle(PlayerPedId(), false) then
				RageUI.ButtonWithStyle("Gestion véhicule", "Accéder à la gestion du véhicule", {RightLabel = "→→→"}, true, function(_, _, s)
				end, MenuVehicle)
			end
		end)
		RageUI.IsVisible(Informations, true, true, true, function()
			RageUI.ButtonWithStyle("Mes factures", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					ESX.TriggerServerCallback('esx_custom:GetBills', function(bills)
                        BillData = bills
                        ESX.PlayerData = ESX.GetPlayerData()
                    end)
				end
			end, Facture)
			RageUI.Separator("~p~↓ Carte d'identité ↓~s~")
			RageUI.ButtonWithStyle("Montrer sa carte d'identité", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestDistance ~= -1 and closestDistance <= 3.0 then
						TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer))
					else
                        ESX.ShowNotification('Aucun joueur à proximité')
					end
				end
			end)
			RageUI.ButtonWithStyle("Regarder sa carte d'identité", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()))
				end
			end)
			RageUI.Separator("~p~↓ Permis de conduire ↓~s~")
			RageUI.ButtonWithStyle("Montrer son permis de conduire", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestDistance ~= -1 and closestDistance <= 3.0 then
						TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer), 'driver')
					else
                        ESX.ShowNotification('Aucun joueur à proximité')
					end
				end
			end)
			RageUI.ButtonWithStyle("Regarder son permis de conduire", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()), 'driver')
				end
			end)
			RageUI.Separator("~p~↓ Permis de port d'armes ↓~s~")
			RageUI.ButtonWithStyle("Montrer son permis de port d'armes", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestDistance ~= -1 and closestDistance <= 3.0 then
						TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer), 'weapon')
					else
                        ESX.ShowNotification('Aucun joueur à proximité')
					end
				end
			end)
			RageUI.ButtonWithStyle("Regarder son permis de port d'armes", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()), 'weapon')
				end
			end)
		end)
		RageUI.IsVisible(Parametres, true, true, true, function()
			RageUI.Checkbox("Désactiver les coups de crosse", nil, Action.Cross, { Style = RageUI.CheckboxStyle.Tick }, function(Hovered, Selected, Active, Checked)
                Action.Cross = Checked;
            end, function()
				-- Coup de cross
				CreateThread(function()
					while true do
						local timer = 200
						if IsPedArmed(PlayerPedId(), 6) then
							timer = 0
							DisableControlAction(1, 140, true)
							DisableControlAction(1, 141, true)
							DisableControlAction(1, 142, true)
						end
						if Breakable then
							Breakable = false
							break
						end

						Citizen.Wait(timer)
					end
				end)
            end, function()
				Breakable = true
            end)
			RageUI.Checkbox("Désactiver le radar", nil, Action.Radar, { Style = RageUI.CheckboxStyle.Tick }, function(Hovered, Selected, Active, Checked)
                Action.Radar = Checked;
            end, function()
				DisplayRadar(false)
            end, function()
				DisplayRadar(true)
            end)
			RageUI.Checkbox("Désactiver l'hud", nil, Action.Hud, { Style = RageUI.CheckboxStyle.Tick }, function(Hovered, Selected, Active, Checked)
                Action.Hud = Checked;
            end, function()
				DisplayHideHud(true)
            end, function()
				DisplayHideHud(false)
            end)
			RageUI.ButtonWithStyle("Rockstar editor", nil, {RightLabel = "→→→"}, true, function(_, _, s)
			end, editorMenu)
		end)
		RageUI.IsVisible(editorMenu, true, true, true, function()
			RageUI.ButtonWithStyle("Lancer Record", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					if IsRecording() then
						ESX.ShowNotification("Vous êtes déjà en train d'enregistrer un clip, vous devez d'abord arrêter l'enregistrement avant de pouvoir recommencer à enregistrer.")
					else
						StartRecording(1)
					end
				end
			end)
			RageUI.ButtonWithStyle("Stoper Record", nil, {RightLabel = "→→→"}, true, function(_, _, s)
				if s then
					if not IsRecording() then
						ESX.ShowNotification("Vous n'êtes pas en train d'enregistrer un clip, vous devez d'abord démarrer l'enregistrement avant de pouvoir arrêter et enregistrer un clip.")
					else
						StopRecordingAndSaveClip()
					end
				end
			end)
		end)
		RageUI.IsVisible(Facture, true, true, true, function()
            if #BillData == 0 then
                RageUI.Separator('')
                RageUI.Separator('~r~Aucune facture')
                RageUI.Separator('')
            end
            for i = 1, #BillData, 1 do
                RageUI.ButtonWithStyle(BillData[i].label, nil, {RightLabel = '~g~$' .. ESX.Math.GroupDigits(BillData[i].amount)}, true, function(Hovered, Active, Selected)
                    if Selected then
                        ESX.TriggerServerCallback(ConfigMenuF5.Trigger.TriggerPayBill, function()
                            ESX.TriggerServerCallback('esx_custom:GetBills', function(bills) BillData = bills end)
                        end, BillData[i].id)
                    end
                end)
            end
		end)
		RageUI.IsVisible(MenuVehicle, true, true, true, function()
			RageUI.Separator("~r~Information~s~")
			RageUI.ButtonWithStyle("Nom du véhicule", nil, {RightLabel = "~p~"..GetDisplayNameFromVehicleModel(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false)))}, true, function(_,_,s)
			end)
			RageUI.ButtonWithStyle("Plaque du véhicule", nil, {RightLabel = "~p~"..GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false))}, true, function(_,_,s)
			end)
			RageUI.ButtonWithStyle("État du moteur", nil, {RightLabel = "~p~"..math.floor(GetVehicleEngineHealth(GetVehiclePedIsIn(PlayerPedId(), false))/10) .."%"}, true, function(_,_,s)
			end)
			if (GetPedInVehicleSeat(GetVehiclePedIsIn(GetPlayerPed(-1), false), -1) == GetPlayerPed(-1)) then
				RageUI.Separator("~r~Actions~s~")
				RageUI.ButtonWithStyle("Allumer/Eteindre le moteur", nil, {RightLabel = "→→→"}, true, function(_,_,s)
					if s then
						local plyVeh = GetVehiclePedIsIn(PlayerPedId(), false)
						
						if GetIsVehicleEngineRunning(plyVeh) then
							SetVehicleEngineOn(plyVeh, false, false, true)
							SetVehicleUndriveable(plyVeh, true)
						elseif not GetIsVehicleEngineRunning(plyVeh) then
							SetVehicleEngineOn(plyVeh, true, false, true)
							SetVehicleUndriveable(plyVeh, false)
						end
					end
				end)
				RageUI.ButtonWithStyle("Ouvrir/Fermer le capot", nil, {RightLabel = "→→→"}, true, function(_,_,s)
					if s then
						local plyVeh = GetVehiclePedIsIn(PlayerPedId(), false)
						
						if GetVehicleDoorAngleRatio(plyVeh, 4) == 0 then
							SetVehicleDoorOpen(plyVeh, 4, false, false)
						else
							SetVehicleDoorShut(plyVeh, 4, false)
						end
					end
				end)
				RageUI.ButtonWithStyle("Ouvrir/Fermer le coffre", nil, {RightLabel = "→→→"}, true, function(_,_,s)
					if s then
						local plyVeh = GetVehiclePedIsIn(PlayerPedId(), false)
						
						if GetVehicleDoorAngleRatio(plyVeh, 5) == 0 then
							SetVehicleDoorOpen(plyVeh, 5, false, false)
						else
							SetVehicleDoorShut(plyVeh, 5, false)
						end
					end
				end)
				RageUI.ButtonWithStyle("Fermer toutes les portes", nil, {RightLabel = "→→→"}, true, function(_,_,s)
					if s then
						local plyVeh = GetVehiclePedIsIn(PlayerPedId(), false)

						SetVehicleDoorShut(plyVeh, 0, false)
						SetVehicleDoorShut(plyVeh, 1, false)
						SetVehicleDoorShut(plyVeh, 2, false)
						SetVehicleDoorShut(plyVeh, 3, false)
						SetVehicleDoorShut(plyVeh, 4, false)
						SetVehicleDoorShut(plyVeh, 5, false)
					end
				end)
				RageUI.List('Ouvrir/Fermer Fenêtre', Action.WindowsList, Action.WindowsIndex, nil, {}, true, function(Hovered, Active, Selected, Index)
					Action.WindowsIndex = Index

					if (Selected) then
						local plyVeh = GetVehiclePedIsIn(PlayerPedId(), false)

						if Index == 1 then
							if not Action.WindowsState.FrontLeft then
								Action.WindowsState.FrontLeft = true
								RollDownWindow(plyVeh, 0)
							elseif Action.WindowsState.FrontLeft then
								Action.WindowsState.FrontLeft = false
								RollUpWindow(plyVeh, 0)
							end
						elseif Index == 2 then
							if not Action.WindowsState.FrontRight then
								Action.WindowsState.FrontRight = true
								RollDownWindow(plyVeh, 1)
							elseif Action.WindowsState.FrontRight then
								Action.WindowsState.FrontRight = false
								RollUpWindow(plyVeh, 1)
							end
						elseif Index == 3 then
							if not Action.WindowsState.BackLeft then
								Action.WindowsState.BackLeft = true
								RollDownWindow(plyVeh, 2)
							elseif Action.WindowsState.BackLeft then
								Action.WindowsState.BackLeft = false
								RollUpWindow(plyVeh, 2)
							end
						elseif Index == 4 then
							if not Action.WindowsState.BackRight then
								Action.WindowsState.BackRight = true
								RollDownWindow(plyVeh, 3)
							elseif Action.WindowsState.BackRight then
								Action.WindowsState.BackRight = false
								RollUpWindow(plyVeh, 3)
							end
						end
					end
				end)

				RageUI.List('Ouvrir/Fermer Porte', Action.DoorList, Action.DoorIndex, nil,{}, true, function(Hovered, Active, Selected, Index)
					Action.DoorIndex = Index

					if (Selected) then
						local plyVeh = GetVehiclePedIsIn(PlayerPedId(), false)

						if Index == 1 then
							if not Action.DoorState.FrontLeft then
								Action.DoorState.FrontLeft = true
								SetVehicleDoorOpen(plyVeh, 0, false, false)
							elseif Action.DoorState.FrontLeft then
								Action.DoorState.FrontLeft = false
								SetVehicleDoorShut(plyVeh, 0, false, false)
							end
						elseif Index == 2 then
							if not Action.DoorState.FrontRight then
								Action.DoorState.FrontRight = true
								SetVehicleDoorOpen(plyVeh, 1, false, false)
							elseif Action.DoorState.FrontRight then
								Action.DoorState.FrontRight = false
								SetVehicleDoorShut(plyVeh, 1, false, false)
							end
						elseif Index == 3 then
							if not Action.DoorState.BackLeft then
								Action.DoorState.BackLeft = true
								SetVehicleDoorOpen(plyVeh, 2, false, false)
							elseif Action.DoorState.BackLeft then
								Action.DoorState.BackLeft = false
								SetVehicleDoorShut(plyVeh, 2, false, false)
							end
						elseif Index == 4 then
							if not Action.DoorState.BackRight then
								Action.DoorState.BackRight = true
								SetVehicleDoorOpen(plyVeh, 3, false, false)
							elseif Action.DoorState.BackRight then
								Action.DoorState.BackRight = false
								SetVehicleDoorShut(plyVeh, 3, false, false)
							end
						end
					end
				end)

				RageUI.List('Limitateur', Action.LimitateurList, Action.LimitateurIndex, nil,{}, true, function(Hovered, Active, Selected, Index)
					Action.LimitateurIndex = Index

					if (Selected) then
						local plyVeh = GetVehiclePedIsIn(PlayerPedId(), false)

						if Index == 1 then
							ESX.ShowNotification('Le ~b~limitateur~s~ est ~g~activée ~s~à ~o~50 Km/h.')
							SetVehicleMaxSpeed(plyVeh, 49/3.6)
						elseif Index == 2 then
							ESX.ShowNotification('Le ~b~limitateur~s~ est ~g~activée ~s~à ~o~80 Km/h.')
							SetVehicleMaxSpeed(plyVeh, 79/3.6)
						elseif Index == 3 then
							ESX.ShowNotification('Le ~b~limitateur~s~ est ~g~activée ~s~à ~o~120 Km/h.')
							SetVehicleMaxSpeed(plyVeh, 119/3.6)
						elseif Index == 4 then
							local AAA = ESXCustom_Function_ClientSide:KeyboardInput("Limitateur personnaliser", 3)

							if AAA ~= nil then
								ESX.ShowNotification("Le ~b~limitateur~s~ est ~g~activée ~s~à ~o~"..tonumber(AAA).." Km/h.")
								SetVehicleMaxSpeed(plyVeh, tonumber(AAA-1)/3.6)
							end
						elseif Index == 5 then
							ESX.ShowNotification('Le ~b~limitateur~s~ est ~r~desactivée')
							SetVehicleMaxSpeed(plyVeh, 1000/3.6)
						end
					end
				end)
			end
		end)

		if not RageUI.Visible(mainmenu) and not RageUI.Visible(Informations) and not RageUI.Visible(Parametres) and not RageUI.Visible(editorMenu) and not RageUI.Visible(Facture) and not RageUI.Visible(MenuVehicle) then
			mainmenu = RMenu:DeleteType("mainmenu")
		end
	end
end

--Register
RegisterKeyMapping(ConfigMenuF5.Commande.CommandeName, ConfigMenuF5.Commande.DescCommande, 'keyboard', ConfigMenuF5.Commande.Bind)

RegisterCommand(ConfigMenuF5.Commande.CommandeName, function()
	OpenMenu()
end)