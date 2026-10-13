RegisterNetEvent('CorePickax:Chargeur:remove', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeInventoryItem('clip', 1)
end)

ESX.RegisterUsableItem('clip', function(source)
	TriggerClientEvent('CorePickax:Chargeur:ChargeurUse', source)
end)