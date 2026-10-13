ConfigBasicNeeds = {
    RegisterItemUsable = {
        {
            name = "bread",
            IsUsed = function(source)
                ESX.GetPlayerFromId(source).removeInventoryItem('bread', 1)
                TriggerClientEvent('esx_status:add', source, 'hunger', 250000)
                TriggerClientEvent('esx_basicneeds:onEatbread', source)
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous avez mangé du pain")
            end
        },
        {
            name = "water",
            IsUsed = function(source)
                ESX.GetPlayerFromId(source).removeInventoryItem('water', 1)
                TriggerClientEvent('esx_status:add', source, 'thirst', 250000)
                TriggerClientEvent('esx_basicneeds:onEatwater', source)
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous avez bu de l'eau")
            end
        }
    },
    RegisterItemUsableClientSide = {
        {
            name = "bread",--Le trigger Sera "esx_basicneeds:onEat"+ le name donc = "esx_basicneeds:onEatbread"
            IsUsed = function(prop_name)
                prop_name = prop_name or 'prop_cs_burger_01'
            
                Citizen.CreateThread(function()
                    local playerPed = PlayerPedId()
                    local x,y,z = table.unpack(GetEntityCoords(playerPed))
                    local prop = CreateObject(GetHashKey(prop_name), x, y, z + 0.2, true, true, true)
                    local boneIndex = GetPedBoneIndex(playerPed, 18905)
                    AttachEntityToEntity(prop, playerPed, boneIndex, 0.12, 0.028, 0.001, 10.0, 175.0, 0.0, true, true, false, true, 1, true)
            
                    ESX.Streaming.RequestAnimDict('mp_player_inteat@burger', function()
                        TaskPlayAnim(playerPed, 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 8.0, -8, -1, 49, 0, 0, 0, 0)
            
                        Citizen.Wait(3000)
                        ClearPedSecondaryTask(playerPed)
                        DeleteObject(prop)
                    end)
                end)
            end
        },
        {
            name = "water",--Le trigger Sera "esx_basicneeds:onEat"+ le name donc = "esx_basicneeds:onEatwater"
            IsUsed = function(prop_name)
                prop_name = prop_name or 'prop_ld_flow_bottle'
            
                Citizen.CreateThread(function()
                    local playerPed = PlayerPedId()
                    local x,y,z = table.unpack(GetEntityCoords(playerPed))
                    local prop = CreateObject(GetHashKey(prop_name), x, y, z + 0.2, true, true, true)
                    local boneIndex = GetPedBoneIndex(playerPed, 18905)
                    AttachEntityToEntity(prop, playerPed, boneIndex, 0.12, 0.028, 0.001, 10.0, 175.0, 0.0, true, true, false, true, 1, true)
            
                    ESX.Streaming.RequestAnimDict('mp_player_inteat@burger', function()
                        TaskPlayAnim(playerPed, 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 8.0, -8, -1, 49, 0, 0, 0, 0)
            
                        Citizen.Wait(3000)
                        ClearPedSecondaryTask(playerPed)
                        DeleteObject(prop)
                    end)
                end)
            end
        }
    }
}