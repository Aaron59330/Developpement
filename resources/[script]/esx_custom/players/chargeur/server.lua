RegisterNetEvent('esx_custom:Chargeur:remove', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeInventoryItem('clip', 1)
end)

ESX.RegisterUsableItem('clip', function(source)
	TriggerClientEvent('esx_custom:Chargeur:ChargeurUse', source)
end)