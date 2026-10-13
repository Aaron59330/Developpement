if ConfigAntiCarKill.AntiCarKill then
    if ConfigAntiCarKill.Collision then
        Citizen.CreateThread(function()
            while true do
            Citizen.Wait(5000)
                for _,player in ipairs(GetActivePlayers()) do
                    if GetPlayerPed(player) ~= GetPlayerPed(-1) then
                        local ped = GetPlayerPed(-1)
                        local everyone = GetPlayerPed(player)
                        local everyoneveh = GetVehiclePedIsUsing(everyone)
                        if IsPedInAnyBoat(everyone) and IsPedInAnyVehicle(everyone, true) then
                        elseif IsPedInAnyVehicle(everyone, false) and not IsPedInAnyBoat(everyone) then
                            SetEntityNoCollisionEntity(ped, everyoneveh, false)
                            SetEntityNoCollisionEntity(everyoneveh, ped, false)
                        else
                            SetEntityNoCollisionEntity(ped, everyone, false)
                        end
                    end
                end
            end
        end)
    else
        Citizen.CreateThread(function()
            while true do
                SetWeaponDamageModifier(-1553120962, 0.0)
                Wait(0)
            end
        end)
    end
end