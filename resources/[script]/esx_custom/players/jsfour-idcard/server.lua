-- Open ID card (cœur de la logique : identifiant du propriétaire -> joueur qui regarde)
local function OpenCard(identifier, ID, _source, type)
	local show       = false
	local licenses = {}

	-- SELECT * : fonctionne avec ou sans la colonne `nationality` (voir esx_identity/install.sql)
	MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier', {['@identifier'] = identifier},
	function (user)
		if (user[1] ~= nil) then
			MySQL.Async.fetchAll('SELECT type FROM user_licenses WHERE owner = @identifier', {['@identifier'] = identifier},
			function (result)
				if type ~= nil then
					for _, v in pairs(result) do
						if type == 'driver' then
							if v.type == 'drive' or v.type == 'drive_bike' or v.type == 'drive_truck' then
								show = true
							end
						elseif type == 'weapon' then
							if v.type == 'weapon' then
								show = true
							end
						elseif type == 'code' then
							if v.type == 'code' then
								show = true
							end
						end
						table.insert(licenses, v)
					end
				else
					show = true
				end

				if show then
					local array = {
						user = user,
						licenses = licenses,
						owner = ID -- sert au client à récupérer la vraie tête du personnage
					}
					TriggerClientEvent('jsfour-idcard:open', _source, array, type)
				else
					ConfigJsFourd.Notify(_source, "Vous n'avez pas ce type de licence..")
				end
			end)
		end
	end)
end

-- Open ID card
RegisterNetEvent('jsfour-idcard:open', function(ID, targetID, type)
	local identifier = ESX.GetPlayerFromId(ID).identifier
	local _source 	 = ESX.GetPlayerFromId(targetID).source
	OpenCard(identifier, ID, _source, type)
end)

-- ===== Intégration ox_inventory =====
local ITEM_TYPES = {
	id_card        = nil,       -- carte d'identité
	driver_license = 'driver',  -- permis de conduire
	weapon_license = 'weapon'   -- permis de port d'arme
}

local CARD_ITEMS = { id_card = true, driver_license = true, weapon_license = true }

-- Joueurs à proximité (pour montrer la carte)
local function NearbyPlayers(src)
	local list = {}
	local coords = GetEntityCoords(GetPlayerPed(src))

	for _, id in ipairs(GetPlayers()) do
		id = tonumber(id)
		if id ~= src and #(GetEntityCoords(GetPlayerPed(id)) - coords) <= ConfigJsFourd.ShowDistance then
			list[#list + 1] = id
		end
	end

	return list
end

local function UseCard(itemName, src, slotNumber)
	local xPlayer = ESX.GetPlayerFromId(src)
	if not xPlayer then return end

	-- Le propriétaire est celui inscrit dans les métadonnées de l'item (sinon l'utilisateur)
	local slot = exports.ox_inventory:GetSlot(src, slotNumber)
	local ownerIdentifier = slot and slot.metadata and slot.metadata.identifier or xPlayer.identifier
	local ownerPlayer = ESX.GetPlayerFromIdentifier(ownerIdentifier)
	local ownerSource = ownerPlayer and ownerPlayer.source or nil
	local type = ITEM_TYPES[itemName]

	OpenCard(ownerIdentifier, ownerSource, src, type)

	if ConfigJsFourd.ShowToNearby then
		for _, id in ipairs(NearbyPlayers(src)) do
			OpenCard(ownerIdentifier, ownerSource, id, type)
		end
	end
end

-- Exports appelés par ox_inventory (voir install/items.lua)
exports('id_card', function(event, item, inventory, slot)
	if event == 'usingItem' then UseCard('id_card', inventory.id, slot) end
end)
exports('driver_license', function(event, item, inventory, slot)
	if event == 'usingItem' then UseCard('driver_license', inventory.id, slot) end
end)
exports('weapon_license', function(event, item, inventory, slot)
	if event == 'usingItem' then UseCard('weapon_license', inventory.id, slot) end
end)

-- Donne une carte à un joueur (utilisable par vos autres scripts) :
-- exports['esx_custom']:GiveCard(source, 'id_card')
exports('GiveCard', function(src, itemName)
	local xPlayer = ESX.GetPlayerFromId(src)
	if not xPlayer or not CARD_ITEMS[itemName] then return false end
	if exports.ox_inventory:GetItemCount(src, itemName) > 0 then return false end

	return exports.ox_inventory:AddItem(src, itemName, 1, {
		identifier = xPlayer.identifier,
		description = xPlayer.getName()
	})
end)
