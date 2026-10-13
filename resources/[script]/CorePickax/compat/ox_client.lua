-- ESXCustom -> ox_inventory client bridge
local ox_inventory = exports.ox_inventory

local function openVehicleInventory(kind, vehicle)
    vehicle = vehicle or GetVehiclePedIsIn(PlayerPedId(), false)
    if not vehicle or vehicle == 0 then return false end
    local netid = NetworkGetNetworkIdFromEntity(vehicle)
    if not netid or netid == 0 then return false end
    return ox_inventory:openInventory(kind, { netid = netid })
end

-- Override legacy RageUI vehicle storage with native ox_inventory storage.
OpenCoffreVeh = function(_, _, _, _)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        vehicle = ESX.Game.GetClosestVehicle(GetEntityCoords(ped))
    end
    if vehicle and vehicle ~= 0 then
        openVehicleInventory('trunk', vehicle)
    end
end

OpenMenu = function()
    openVehicleInventory('glovebox', GetVehiclePedIsIn(PlayerPedId(), false))
end
OpenMenuDeposerBoiteGant = OpenMenu
OpenMenuPrendreBoiteGant = OpenMenu

RegisterNetEvent('esx:openPlayerInventory', function(target)
    ox_inventory:openInventory('player', tonumber(target))
end)
