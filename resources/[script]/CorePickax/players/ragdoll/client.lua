IsRagdollPut = false

RegisterCommand(ConfigRagdoll.Commande.Name, function()
    IsRagdollPut = not IsRagdollPut
    while IsRagdollPut do
        Wait(0)

        local plyPed = PlayerPedId()
        if not ESXCustom_Function_ClientSide:GetPlayerHandsup(plyPed, ConfigRagdoll.AnimUseBUG) then
            if IsRagdollPut and IsControlJustReleased(1, 22) or IsRagdollPut and IsControlJustReleased(1, 51) then
                IsRagdollPut = not IsRagdollPut
                break
            end
            if IsRagdollPut then
                SetPedRagdollForceFall(plyPed)
                ResetPedRagdollTimer(PlayerPedId())
                SetPedToRagdoll(PlayerPedId(), 1000, 1000, 3, 0, 0, 0)
                ResetPedRagdollTimer(PlayerPedId())
                ESX.ShowHelpNotification(ConfigRagdoll.Push)
            end
        else
            ESX.ShowNotification(ConfigRagdoll.Notify)
            break
        end
    end
end, false)
RegisterKeyMapping(ConfigRagdoll.Commande.Name, ConfigRagdoll.Commande.Desc, 'keyboard', ConfigRagdoll.Commande.Bind)