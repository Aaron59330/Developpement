CreateThread(function()
	while true do
		local timer = 400
		if IsPedInAnyVehicle(PlayerClass.pPed, false) and (GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerClass.pPed, false), -1) == PlayerClass.pPed) then
			if IsPedInAnyBoat(PlayerClass.pPed) then
				local GetSpeed = math.floor(GetEntitySpeed(GetVehiclePedIsIn(PlayerClass.pPed, false)) * 3.6)

                if ConfigAncre.MaxVitesse >= GetSpeed then
                    timer = 0
                    if not IsBoatAnchoredAndFrozen(GetVehiclePedIsIn(PlayerClass.pPed, false)) then
                        ESX.ShowHelpNotification(ConfigAncre["HelpNotif1"])
                    elseif IsBoatAnchoredAndFrozen(GetVehiclePedIsIn(PlayerClass.pPed, false)) == 1 then
                        ESX.ShowHelpNotification(ConfigAncre["HelpNotif2"])
                    end
                    if IsControlJustPressed(1,51) then
                        if not IsBoatAnchoredAndFrozen(GetVehiclePedIsIn(PlayerClass.pPed, false)) then
                            SetBoatAnchor(GetVehiclePedIsIn(PlayerClass.pPed, false), true)
                            SetBoatFrozenWhenAnchored(GetVehiclePedIsIn(PlayerClass.pPed, false),true)
                            Wait(5000)
                            ESX.ShowNotification(ConfigAncre["Notif1"])
                            ClearPedTasks(PlayerClass.pPed)
                        elseif IsBoatAnchoredAndFrozen(GetVehiclePedIsIn(PlayerClass.pPed, false)) == 1 then
                            Wait(5000)
                            SetBoatAnchor(GetVehiclePedIsIn(PlayerClass.pPed, false), false)
                            SetBoatFrozenWhenAnchored(GetVehiclePedIsIn(PlayerClass.pPed, false),false)
                            ESX.ShowNotification(ConfigAncre["Notif2"])
                            ClearPedTasks(PlayerClass.pPed)
                        end
                    end
                end
			end
		end

		Wait(timer)
	end
end)