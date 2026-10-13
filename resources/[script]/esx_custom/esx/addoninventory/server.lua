function CreateAddonInventory(name, owner, items)
	local self = {}

	self.name  = name
	self.owner = owner
	self.items = items

	self.addItem = function(name, count)
		local item = self.getItem(name)
		item.count = item.count + count

		self.saveItem(name, item.count)
	end

	self.removeItem = function(name, count)
		local item = self.getItem(name)
		item.count = item.count - count

		self.saveItem(name, item.count)
	end

	self.setItem = function(name, count)
		local item = self.getItem(name)
		item.count = count

		self.saveItem(name, item.count)
	end

	self.getItem = function(name)
		for i=1, #self.items, 1 do
			if self.items[i].name == name then
				return self.items[i]
			end
		end

		item = {
			name  = name,
			count = 0,
			label = ItemsQ[name]
		}

		table.insert(self.items, item)

		if self.owner == nil then
			MySQL.Async.execute('INSERT INTO addon_inventory_items (inventory_name, name, count) VALUES (@inventory_name, @item_name, @count)',
			{
				['@inventory_name'] = self.name,
				['@item_name']      = name,
				['@count']          = 0
			})
		else
			MySQL.Async.execute('INSERT INTO addon_inventory_items (inventory_name, name, count, owner) VALUES (@inventory_name, @item_name, @count, @owner)',
			{
				['@inventory_name'] = self.name,
				['@item_name']      = name,
				['@count']          = 0,
				['@owner']          = self.owner
			})
		end

		return item
	end

	self.saveItem = function(name, count)
		if self.owner == nil then
			MySQL.Async.execute('UPDATE addon_inventory_items SET count = @count WHERE inventory_name = @inventory_name AND name = @item_name', {
				['@inventory_name'] = self.name,
				['@item_name']      = name,
				['@count']          = count
			})
		else
			MySQL.Async.execute('UPDATE addon_inventory_items SET count = @count WHERE inventory_name = @inventory_name AND name = @item_name AND owner = @owner', {
				['@inventory_name'] = self.name,
				['@item_name']      = name,
				['@count']          = count,
				['@owner']          = self.owner
			})
		end
	end

	return self
end

ItemsQ = {}
local Inventories, SharedInventories = {}, {}, {}
MySQL.ready(function()
	MySQL.Async.fetchAll('SELECT * FROM items', {}, function(result)
		for i = 1, #result, 1 do
			ItemsQ[result[i].name] = result[i].label
		end

		MySQL.Async.fetchAll('SELECT * FROM addon_inventory', {}, function(result2)
			for i = 1, #result2, 1 do
				local name = result2[i].name
				local label = result2[i].label
				local shared = result2[i].shared
		
				MySQL.Async.fetchAll('SELECT * FROM addon_inventory_items WHERE inventory_name = @inventory_name', {
					['@inventory_name'] = name
				}, function(result3)
					if shared == 0 then
						Inventories[name] = {}
						local items = {}

						for j = 1, #result3, 1 do
							local itemName = result3[j].name
							local itemCount = result3[j].count
							local itemOwner = result3[j].owner

							if items[itemOwner] == nil then
								items[itemOwner] = {}
							end

							table.insert(items[itemOwner], {
								name = itemName,
								count = itemCount,
								label = ItemsQ[itemName]
							})
						end

						for k, v in pairs(items) do
							table.insert(Inventories[name], CreateAddonInventory(name, k, v))
						end
					else
						local items = {}

						for j = 1, #result3, 1 do
							table.insert(items, {
								name = result3[j].name,
								count = result3[j].count,
								label = ItemsQ[result3[j].name]
							})
						end

						SharedInventories[name] = CreateAddonInventory(name, nil, items)
					end
				end)
			end
		end)
	end)
end)

function GetInventory(name, owner)
	for i = 1, #Inventories[name], 1 do
		if Inventories[name][i].owner == owner then
			return Inventories[name][i]
		end
	end

	local inventory = CreateAddonInventory(name, owner, {})
	table.insert(Inventories[name], inventory)
	return inventory
end

function GetSharedInventory(name)
	return SharedInventories[name]
end

-- local Items = {}
-- local InventoriesIndex, Inventories, SharedInventories = {}, {}, {}

-- MySQL.ready(function()
-- 	local items = MySQL.Sync.fetchAll('SELECT * FROM items')

-- 	for i=1, #items, 1 do
-- 		Items[items[i].name] = items[i].label
-- 	end

-- 	local result = MySQL.Sync.fetchAll('SELECT * FROM addon_inventory')

-- 	for i=1, #result, 1 do
-- 		local name   = result[i].name
-- 		local label  = result[i].label
-- 		local shared = result[i].shared

-- 		local result2 = MySQL.Sync.fetchAll('SELECT * FROM addon_inventory_items WHERE inventory_name = @inventory_name', {
-- 			['@inventory_name'] = name
-- 		})

-- 		if shared == 0 then

-- 			table.insert(InventoriesIndex, name)

-- 			Inventories[name] = {}
-- 			local items       = {}

-- 			for j=1, #result2, 1 do
-- 				local itemName  = result2[j].name
-- 				local itemCount = result2[j].count
-- 				local itemOwner = result2[j].owner

-- 				if items[itemOwner] == nil then
-- 					items[itemOwner] = {}
-- 				end

-- 				table.insert(items[itemOwner], {
-- 					name  = itemName,
-- 					count = itemCount,
-- 					label = Items[itemName]
-- 				})
-- 			end

-- 			for k,v in pairs(items) do
-- 				local addonInventory = CreateAddonInventory(name, k, v)
-- 				table.insert(Inventories[name], addonInventory)
-- 			end

-- 		else
-- 			local items = {}

-- 			for j=1, #result2, 1 do
-- 				table.insert(items, {
-- 					name  = result2[j].name,
-- 					count = result2[j].count,
-- 					label = Items[result2[j].name]
-- 				})
-- 			end

-- 			local addonInventory    = CreateAddonInventory(name, nil, items)
-- 			SharedInventories[name] = addonInventory
-- 		end
-- 	end
-- end)

-- function GetInventory(name, owner)
-- 	for i=1, #Inventories[name], 1 do
-- 		if Inventories[name][i].owner == owner then
-- 			return Inventories[name][i]
-- 		end
-- 	end

-- 	return false
-- end

-- function GetSharedInventory(name)
-- 	return SharedInventories[name]
-- end

AddEventHandler('esx_addoninventory:getInventory', function(name, owner, cb)
	cb(GetInventory(name, owner))
end)

AddEventHandler('esx_addoninventory:getSharedInventory', function(name, cb)
	cb(GetSharedInventory(name))
end)

-- AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
-- 	local addonInventories = {}

-- 	for i=1, #InventoriesIndex, 1 do
-- 		local name      = InventoriesIndex[i]
-- 		local inventory = GetInventory(name, xPlayer.identifier)

-- 		if inventory == nil then
-- 			inventory = CreateAddonInventory(name, xPlayer.identifier, {})
-- 			table.insert(Inventories[name], inventory)
-- 		end

-- 		table.insert(addonInventories, inventory)
-- 	end

-- 	xPlayer.set('addonInventories', addonInventories)
-- end)
