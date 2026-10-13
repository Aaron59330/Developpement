local Inventory

if Config.OxInventory then
	AddEventHandler('ox_inventory:loadInventory', function(module)
		Inventory = module
	end)
end

Core.PlayerFunctionOverrides.OxInventory = {
	getInventory = function(self)
		return function(minimal)
			if minimal then
				local minimalInventory = {}

				for k, v in pairs(self.inventory) do
					if v.count and v.count > 0 then
						local metadata = v.metadata

						if v.metadata and next(v.metadata) == nil then
							metadata = nil
						end

						minimalInventory[#minimalInventory + 1] = {
							name = v.name,
							count = v.count,
							slot = k,
							metadata = metadata
						}
					end
				end

				return minimalInventory
			end

			return self.inventory
		end
	end,

	getLoadout = function()
		return function()
			return {}
		end
	end,

	setAccountMoney = function(self)
		return function(accountName, money, reason)
			reason = reason or 'unknown'
			if money >= 0 then
				local account = self.getAccount(accountName)

				if account then
					money = account.round and ESX.Math.Round(money) or money
					self.accounts[account.index].money = money

					self.triggerEvent('esx:setAccountMoney', account)
					TriggerEvent('esx:setAccountMoney', self.source, accountName, money, reason)
					if Inventory.accounts[accountName] then
						Inventory.SetItem(self.source, accountName, money)
					end
				end
			end
		end
	end,

	addAccountMoney = function(self)
		return function(accountName, money, reason)
			reason = reason or 'unknown'
			if money > 0 then
				local account = self.getAccount(accountName)

				if account then
					money = account.round and ESX.Math.Round(money) or money
					self.accounts[account.index].money = self.accounts[account.index].money + money
					self.triggerEvent('esx:setAccountMoney', account)
					TriggerEvent('esx:addAccountMoney', self.source, accountName, money, reason)
					if Inventory.accounts[accountName] then
						Inventory.AddItem(self.source, accountName, money)
					end
				end
			end
		end
	end,

	removeAccountMoney = function(self)
		return function(accountName, money, reason)
			reason = reason or 'unknown'
			if money > 0 then
				local account = self.getAccount(accountName)

				if account then
					money = account.round and ESX.Math.Round(money) or money
					self.accounts[account.index].money = self.accounts[account.index].money - money
					self.triggerEvent('esx:setAccountMoney', account)
					TriggerEvent('esx:removeAccountMoney', self.source, accountName, money, reason)
					if Inventory.accounts[accountName] then
						Inventory.RemoveItem(self.source, accountName, money)
					end
				end
			end
		end
	end,

	getInventoryItem = function(self)
		return function(name, metadata)
			return Inventory.GetItem(self.source, name, metadata)
		end
	end,

	addInventoryItem = function(self)
		return function(name, count, metadata, slot)
			return Inventory.AddItem(self.source, name, count or 1, metadata, slot)
		end
	end,

	removeInventoryItem = function(self)
		return function(name, count, metadata, slot)
			return Inventory.RemoveItem(self.source, name, count or 1, metadata, slot)
		end
	end,

	setInventoryItem = function(self)
		return function(name, count, metadata)
			return Inventory.SetItem(self.source, name, count, metadata)
		end
	end,

	canCarryItem = function(self)
		return function(name, count, metadata)
			return Inventory.CanCarryItem(self.source, name, count, metadata)
		end
	end,

	canSwapItem = function(self)
		return function(firstItem, firstItemCount, testItem, testItemCount)
			return Inventory.CanSwapItem(self.source, firstItem, firstItemCount, testItem, testItemCount)
		end
	end,

	setMaxWeight = function(self)
		return function(newWeight)
			self.maxWeight = newWeight
			self.triggerEvent('esx:setMaxWeight', self.maxWeight)
			return Inventory.Set(self.source, 'maxWeight', newWeight)
		end
	end,

	addWeapon = function(self)
		return function(weaponName, ammo)
			local metadata = { ammo = tonumber(ammo) or 0, durability = 100 }
			return exports.ox_inventory:AddItem(self.source, weaponName, 1, metadata)
		end
	end,

	addWeaponComponent = function(self)
		return function(weaponName, component)
			local slot = exports.ox_inventory:GetSlotWithItem(self.source, weaponName)
			if not slot then return false end
			local metadata = slot.metadata or {}
			metadata.components = metadata.components or {}
			for i = 1, #metadata.components do if metadata.components[i] == component then return true end end
			metadata.components[#metadata.components + 1] = component
			exports.ox_inventory:SetMetadata(self.source, slot.slot, metadata)
			return true
		end
	end,

	addWeaponAmmo = function(self)
		return function(weaponName, ammo)
			local slot = exports.ox_inventory:GetSlotWithItem(self.source, weaponName)
			if not slot then return false end
			local metadata = slot.metadata or {}
			metadata.ammo = (tonumber(metadata.ammo) or 0) + (tonumber(ammo) or 0)
			exports.ox_inventory:SetMetadata(self.source, slot.slot, metadata)
			return true
		end
	end,

	updateWeaponAmmo = function(self)
		return function(weaponName, ammo)
			local slot = exports.ox_inventory:GetSlotWithItem(self.source, weaponName)
			if not slot then return false end
			local metadata = slot.metadata or {}
			metadata.ammo = math.max(0, tonumber(ammo) or 0)
			exports.ox_inventory:SetMetadata(self.source, slot.slot, metadata)
			return true
		end
	end,

	setWeaponTint = function(self)
		return function(weaponName, tintIndex)
			local slot = exports.ox_inventory:GetSlotWithItem(self.source, weaponName)
			if not slot then return false end
			local metadata = slot.metadata or {}
			metadata.tint = tonumber(tintIndex) or 0
			exports.ox_inventory:SetMetadata(self.source, slot.slot, metadata)
			return true
		end
	end,

	getWeaponTint = function(self)
		return function(weaponName)
			local slot = exports.ox_inventory:GetSlotWithItem(self.source, weaponName)
			return slot and slot.metadata and tonumber(slot.metadata.tint) or 0
		end
	end,

	removeWeapon = function(self)
		return function(weaponName)
			return exports.ox_inventory:RemoveItem(self.source, weaponName, 1)
		end
	end,

	removeWeaponComponent = function(self)
		return function(weaponName, component)
			local slot = exports.ox_inventory:GetSlotWithItem(self.source, weaponName)
			if not slot then return false end
			local metadata = slot.metadata or {}
			local components = metadata.components or {}
			for i = #components, 1, -1 do
				if components[i] == component then table.remove(components, i) end
			end
			metadata.components = components
			exports.ox_inventory:SetMetadata(self.source, slot.slot, metadata)
			return true
		end
	end,

	removeWeaponAmmo = function(self)
		return function(weaponName, ammo)
			local slot = exports.ox_inventory:GetSlotWithItem(self.source, weaponName)
			if not slot then return false end
			local metadata = slot.metadata or {}
			metadata.ammo = math.max(0, (tonumber(metadata.ammo) or 0) - (tonumber(ammo) or 0))
			exports.ox_inventory:SetMetadata(self.source, slot.slot, metadata)
			return true
		end
	end,

	hasWeaponComponent = function(self)
		return function(weaponName, component)
			local slot = exports.ox_inventory:GetSlotWithItem(self.source, weaponName)
			if not slot then return false end
			for i = 1, #((slot.metadata and slot.metadata.components) or {}) do
				if slot.metadata.components[i] == component then return true end
			end
			return false
		end
	end,

	hasWeapon = function(self)
		return function(weaponName)
			local slot = exports.ox_inventory:GetSlotWithItem(self.source, weaponName)
			if not slot then return false end
			return true, slot
		end
	end,

	hasItem = function(self)
		return function(name, metadata)
			return (exports.ox_inventory:GetItemCount(self.source, name, metadata) or 0) > 0
		end
	end,

	getWeapon = function(self)
		return function(weaponName)
			local slot = exports.ox_inventory:GetSlotWithItem(self.source, weaponName)
			if not slot then return nil end
			return slot.name, slot.ammo or (slot.metadata and slot.metadata.ammo) or 0, slot.metadata
		end
	end,

	getLoadout = function(self)
		return function(minimal)
			local result = {}
			local items = exports.ox_inventory:GetInventoryItems(self.source) or {}
			for _, item in pairs(items) do
				if item and type(item.name) == 'string' and item.name:sub(1, 7) == 'WEAPON_' then
					local metadata = item.metadata or {}
					result[#result + 1] = {
						name = item.name,
						label = item.label or item.name,
						ammo = tonumber(metadata.ammo) or 0,
						tintIndex = tonumber(metadata.tint) or 0,
						components = metadata.components or {},
						slot = item.slot
					}
				end
			end
			return result
		end
	end,

	syncInventory = function(self)
		return function(weight, maxWeight, items, money)
			self.weight, self.maxWeight = weight, maxWeight
			self.inventory = items

			if money then
				for accountName, amount in pairs(money) do
					local account = self.getAccount(accountName)

					if account and ESX.Math.Round(account.money) ~= amount then
						account.money = amount
						self.triggerEvent('esx:setAccountMoney', account)
						TriggerEvent('esx:setAccountMoney', self.source, accountName, amount, 'Sync account with item')
					end
				end
			end
		end
	end
}
