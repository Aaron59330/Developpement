ESX = ESX or exports["es_extended"]:getSharedObject()

ESXCustomClientUtils = {}

ESXCustomClientUtils.toServer = function(eventName, ...)
    if (ConfigMenuF5 ~= nil and ConfigMenuF5.Trigger.TriggerUseItem ~= nil and eventName == ConfigMenuF5.Trigger.TriggerUseItem) then
        TriggerServerEvent(eventName, ...)
    else
        TriggerServerEvent("CorePickax:".. GetHashKey(eventName), ...)
    end
    
    if Config.Debug then
        print("event : "..eventName.." was used")
    end
end

ESXCustomClientUtils.useCallback = ESX.TriggerServerCallback

function ESXCustomClientUtils.initPlayerClass()
    PlayerClass = {
        pPed = function()
            return self.pPed
        end,

        pVeh = function()
            return self.pVeh
        end,

        pLastVeh = function()
            return self.pLastVeh
        end,

        pHealth = function()
            return self.pHealth
        end,

        pName = function()
            return self.pName
        end,

        pCoords = function()
            return self.pCoords
        end,

        pArmour = function()
            return self.pArmour
        end,

        pID = function()
            return self.pID
        end,

        pServerID = function()
            return self.pServerID
        end,

        IsInVeh = function()
            return self.IsInVeh
        end,

        pIsDeath = function()
            return self.pIsDeath
        end,

        pWeaponSelected = function()
            return self.pWeaponSelected
        end,

        pInWater = function()
            return self.pInWater
        end,

        pInStaffMode = function()
            return self.pInStaffMode
        end,

        pEmoteEnCours = function()
            return self.pEmoteEnCours
        end,
    }

    CreateThread(function()
        PlayerClass.pInStaffMode = false
        PlayerClass.pEmoteEnCours = nil

        while true do
            PlayerClass.pPed = PlayerPedId()
            PlayerClass.pVeh = GetVehiclePedIsIn(PlayerClass.pPed, 0)
            PlayerClass.pLastVeh = GetVehiclePedIsIn(PlayerClass.pPed, 1)
            PlayerClass.pHealth = GetEntityHealth(PlayerClass.pPed)
            PlayerClass.pName = GetPlayerName(GetPlayerIndex())
            PlayerClass.pCoords = GetEntityCoords(PlayerClass.pPed)
            PlayerClass.pArmour = GetPedArmour(PlayerClass.pPed)
            PlayerClass.pID = PlayerId()
            PlayerClass.pServerID = GetPlayerServerId(NetworkGetEntityOwner(PlayerClass.pPed))
            PlayerClass.pIsDeath = IsPedDeadOrDying(PlayerClass.pPed, 1) or IsEntityDead(PlayerClass.pPed)
            PlayerClass.IsInVeh = IsPedInAnyVehicle(PlayerClass.pPed, false)
            PlayerClass.pWeaponSelected = GetSelectedPedWeapon(PlayerClass.pPed)

            if IsEntityInWater(PlayerClass.pPed) or IsPedSwimmingUnderWater(PlayerClass.pPed) then
                PlayerClass.pInWater = true
            else
                PlayerClass.pInWater = false
            end

            Wait(1000)
        end
    end)
end

ESXCustomClientUtils.initPlayerClass()

localPlayers = {}
RegisterNetEvent("CorePickax:updatePlayers", function(table)
    localPlayers = table
end)