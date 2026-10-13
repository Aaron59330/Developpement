function CreateAddonAccount(name, owner, money)
	local self = {}

	self.name  = name
	self.owner = owner
	self.money = money

	self.addMoney = function(m)
		m = tonumber(m) or 0
		self.money = (tonumber(self.money) or 0) + m
		self.save()

		TriggerClientEvent('esx_addonaccount:setMoney', -1, self.name, self.money)
	end

	self.removeMoney = function(m)
		m = tonumber(m) or 0
		self.money = (tonumber(self.money) or 0) - m
		self.save()

		TriggerClientEvent('esx_addonaccount:setMoney', -1, self.name, self.money)
	end

	self.setMoney = function(m)
		self.money = tonumber(m) or 0
		self.save()

		TriggerClientEvent('esx_addonaccount:setMoney', -1, self.name, self.money)
	end

	self.save = function()
		if self.owner == nil then
			MySQL.Async.execute('UPDATE addon_account_data SET money = @money WHERE account_name = @account_name', {
				['@account_name'] = self.name,
				['@money']        = self.money
			})
		else
			MySQL.Async.execute('UPDATE addon_account_data SET money = @money WHERE account_name = @account_name AND owner = @owner', {
				['@account_name'] = self.name,
				['@money']        = self.money,
				['@owner']        = self.owner
			})
		end
	end

	return self
end

local AccountsIndex, Accounts, SharedAccounts = {}, {}, {}

MySQL.ready(function()
	local result = MySQL.Sync.fetchAll('SELECT * FROM addon_account')

	for i=1, #result, 1 do
		local name   = result[i].name
		local label  = result[i].label
		local shared = result[i].shared

		local result2 = MySQL.Sync.fetchAll('SELECT * FROM addon_account_data WHERE account_name = @account_name', {
			['@account_name'] = name
		})

		if shared == 0 then
			table.insert(AccountsIndex, name)
			Accounts[name] = {}

			for j=1, #result2, 1 do
				local addonAccount = CreateAddonAccount(name, result2[j].owner, result2[j].money)
				table.insert(Accounts[name], addonAccount)
			end
		else
			local money = nil

			if #result2 == 0 then
				MySQL.Sync.execute('INSERT INTO addon_account_data (account_name, money, owner) VALUES (@account_name, @money, NULL)', {
					['@account_name'] = name,
					['@money']        = 0
				})

				money = 0
			else
				money = result2[1].money
			end

			local addonAccount   = CreateAddonAccount(name, nil, money)
			SharedAccounts[name] = addonAccount
		end
	end
end)

function GetAccount(name, owner)
	if Accounts[name] == nil then
		return nil
	end

	for i=1, #Accounts[name], 1 do
		if Accounts[name][i].owner == owner then
			return Accounts[name][i]
		end
	end

	return nil
end

function GetSharedAccount(name)
	local account = SharedAccounts[name]

	if account == nil then
		print(('[esx_addonaccount] Compte partagé introuvable : %s'):format(tostring(name)))
	end

	return account
end

AddEventHandler('esx_addonaccount:getAccount', function(name, owner, cb)
	cb(GetAccount(name, owner))
end)

AddEventHandler('esx_addonaccount:getSharedAccount', function(name, cb)
	cb(GetSharedAccount(name))
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
	local addonAccounts = {}

	for i=1, #AccountsIndex, 1 do
		local name    = AccountsIndex[i]
		local account = GetAccount(name, xPlayer.identifier)

		if account == nil then
			MySQL.Async.execute('INSERT INTO addon_account_data (account_name, money, owner) VALUES (@account_name, @money, @owner)', {
				['@account_name'] = name,
				['@money']        = 0,
				['@owner']        = xPlayer.identifier
			})

			account = CreateAddonAccount(name, xPlayer.identifier, 0)
			table.insert(Accounts[name], account)
		end

		table.insert(addonAccounts, account)
	end

	xPlayer.set('addonAccounts', addonAccounts)
end)


-- ─────────────────────────────── Pont jobbuilder (ajouté) ───────────────────────────────
-- Permet à jobbuilder de charger en mémoire les comptes société créés en jeu et de modifier leur solde
-- DEPUIS cette ressource, pour que esx_society / menu contextuel / tablettes voient exactement le même solde.
exports('AddSharedAccount', function(society, amount)
	if type(society) ~= 'table' or not society.name then return false end
	if SharedAccounts[society.name] then return true end
	SharedAccounts[society.name] = CreateAddonAccount(society.name, nil, tonumber(amount) or 0)
	return true
end)

exports('AddSharedMoney', function(name, amount)
	local acc = SharedAccounts[name]
	if not acc then return false end
	acc.addMoney(amount)
	return acc.money
end)

exports('RemoveSharedMoney', function(name, amount)
	local acc = SharedAccounts[name]
	if not acc then return false end
	acc.removeMoney(amount)
	return acc.money
end)

exports('GetSharedMoney', function(name)
	local acc = SharedAccounts[name]
	return acc and acc.money or nil
end)
