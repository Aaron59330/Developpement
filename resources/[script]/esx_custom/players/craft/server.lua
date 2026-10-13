RegisterNetEvent("esx_custom:CraftItem", function(ItemLabel, ItemName, qty, GoodJob, TableItemToRemove)
    VerifyToken(source, function()
        ESXCustomServerUtils.GetDistance(source, vector3(GoodJob.x, GoodJob.y, GoodJob.z), 10, "CraftItem", true, function()
            local xPlayer = GetPlayerFromId(source)

            for k, v in pairs(TableItemToRemove) do
                RemoveItemOnPlayer(source, v.name, v.amount)
            end
            AddItemOnPlayer(source, ItemName, qty)
            TriggerClientEvent(Config.Trigger.TriggerNotification,source, (ConfigCraft.Notification["CraftItem"]):format(ItemLabel))
        end, function()
        end)
    end)
end)

RegisterNetEvent("esx_custom:CraftRecolte", function(ItemReward, qty, GoodJob)
    VerifyToken(source, function()
        ESXCustomServerUtils.GetDistance(source, vector3(GoodJob.x, GoodJob.y, GoodJob.z), 10, "CraftRecolte", true, function()
            local xPlayer = GetPlayerFromId(source)

            AddItemOnPlayer(source, ItemReward, qty)
            TriggerClientEvent(Config.Trigger.TriggerNotification, source, (ConfigCraft.Notification["ReceiveItem"]):format(ItemReward))
        end, function()
        end)
    end)
end)