-- Objets consommables : tout est décrit dans ConfigBasicNeeds.Consumables (config.lua)
local function hasItem(xPlayer, name)
	if GetResourceState('ox_inventory') == 'started' then
		return (exports.ox_inventory:GetItemCount(xPlayer.source, name) or 0) >= 1
	end
	local it = xPlayer.getInventoryItem and xPlayer.getInventoryItem(name)
	return it ~= nil and (it.count or 0) >= 1
end

local function takeItem(xPlayer, name)
	if GetResourceState('ox_inventory') == 'started' then
		return exports.ox_inventory:RemoveItem(xPlayer.source, name, 1) == true
	end
	xPlayer.removeInventoryItem(name, 1)
	return true
end

local busy = {}
for name, def in pairs(ConfigBasicNeeds.Consumables) do
	ESX.RegisterUsableItem(name, function(source)
		if busy[source] then return end
		local xPlayer = ESX.GetPlayerFromId(source)
		if not xPlayer or not hasItem(xPlayer, name) then return end
		-- un soin / un gilet inutile ne consomme pas l'objet
		if def.kind == 'heal' or def.kind == 'armor' then
			busy[source] = true
			TriggerClientEvent('pickax_needs:consume', source, name, true)
			return
		end
		busy[source] = true
		if not takeItem(xPlayer, name) then busy[source] = nil return end
		if def.hunger then TriggerClientEvent('esx_status:add', source, 'hunger', def.hunger) end
		if def.thirst then TriggerClientEvent('esx_status:add', source, 'thirst', def.thirst) end
		TriggerClientEvent('pickax_needs:consume', source, name, false)
		if Config.Debug then print(name .. ' was used') end
	end)
end

-- fin d'animation côté client : libère le joueur ; pour un soin / un gilet, l'objet n'est retiré que si l'effet a été appliqué
RegisterNetEvent('pickax_needs:done', function(name, applied)
	local src = source
	busy[src] = nil
	local def = ConfigBasicNeeds.Consumables[name]
	if not def or not applied or (def.kind ~= 'heal' and def.kind ~= 'armor') then return end
	local xPlayer = ESX.GetPlayerFromId(src)
	if xPlayer and hasItem(xPlayer, name) then takeItem(xPlayer, name) end
end)
AddEventHandler('playerDropped', function() busy[source] = nil end)
