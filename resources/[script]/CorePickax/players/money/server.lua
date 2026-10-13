local AllPlayersToUse = {}

for k, v in pairs(ConfigMoney.CommandeList) do
    if v.active then
        ESXCustomServerUtils.registerCommand(v.commande, function(source, args, rawCommand)
            local xPlayer = ESX.GetPlayerFromId(source)

            if not AllPlayersToUse[xPlayer.identifier] then
                AllPlayersToUse[xPlayer.identifier] = {}
                AllPlayersToUse[xPlayer.identifier].WasUsed = true
                AllPlayersToUse[xPlayer.identifier].License = xPlayer.identifier
                AllPlayersToUse[xPlayer.identifier].LocalID = source

                AddMoney(source, v.montant)
            else
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, v.messagerefuse)
            end
        end, false)
    end
end