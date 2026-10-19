local Jobs = {}
local Jobs2 = {}
local RegisteredSocieties = {}

function GetSociety(name)
	for i=1, #RegisteredSocieties, 1 do
		if RegisteredSocieties[i].name == name then
			return RegisteredSocieties[i]
		end
	end
end

local function RefreshSocietyJobs2()
	Jobs2 = {}
	if not Config.HaveJob2SQL then return end

	local jobs = MySQL.Sync.fetchAll('SELECT * FROM jobs2', {}) or {}
	for i = 1, #jobs do
		Jobs2[jobs[i].name] = jobs[i]
		Jobs2[jobs[i].name].grades = {}
	end

	local grades = MySQL.Sync.fetchAll('SELECT * FROM job2_grades', {}) or {}
	for i = 1, #grades do
		local job = Jobs2[grades[i].job_name]
		if job then
			job.grades[tostring(grades[i].grade)] = grades[i]
		end
	end
end

-- Appelé par Gangbuilder après création/suppression d'un métier secondaire.
AddEventHandler('esx_society:refreshJobs2', RefreshSocietyJobs2)

-- Charge (ou recharge) un métier depuis la base : les métiers créés en jeu (Job Builder) n'existaient pas dans le cache chargé au démarrage
local function EnsureJob(name, force)
	if not name or (Jobs[name] and not force) then return Jobs[name] end
	local row = MySQL.Sync.fetchAll('SELECT * FROM jobs WHERE name = @name', { ['@name'] = name })
	if not row or not row[1] then return nil end
	local job = row[1]
	job.grades = {}
	local grades = MySQL.Sync.fetchAll('SELECT * FROM job_grades WHERE job_name = @name', { ['@name'] = name }) or {}
	for i = 1, #grades do job.grades[tostring(grades[i].grade)] = grades[i] end
	Jobs[name] = job
	return job
end
AddEventHandler('esx_society:refreshJob', function(name) EnsureJob(name, true) end)

MySQL.ready(function()
	local result = MySQL.Sync.fetchAll('SELECT * FROM jobs', {})

	for i=1, #result, 1 do
		Jobs[result[i].name] = result[i]
		Jobs[result[i].name].grades = {}
	end

	local result2 = MySQL.Sync.fetchAll('SELECT * FROM job_grades', {})

	for i=1, #result2, 1 do
		if Jobs[result2[i].job_name] ~= nil then
			Jobs[result2[i].job_name].grades[tostring(result2[i].grade)] = result2[i]
		end
	end

	RefreshSocietyJobs2()
end)

AddEventHandler('esx_society:registerSociety', function(name, label, account, datastore, inventory, data)
	local found = false

	local society = {
		name      = name,
		label     = label,
		account   = account,
		datastore = datastore,
		inventory = inventory,
		data      = data
	}

	for i=1, #RegisteredSocieties, 1 do
		if RegisteredSocieties[i].name == name then
			found = true
			RegisteredSocieties[i] = society
			break
		end
	end

	if not found then
		table.insert(RegisteredSocieties, society)
	end
end)

AddEventHandler('esx_society:getSocieties', function(cb)
	cb(RegisteredSocieties)
end)

AddEventHandler('esx_society:getSociety', function(name, cb)
	cb(GetSociety(name))
end)

RegisterServerEvent('esx_society:withdrawMoney1')
AddEventHandler('esx_society:withdrawMoney1', function(society, amount)
	local _src = source
	local xPlayer = ESX.GetPlayerFromId(source)
	local society = GetSociety(society)
	local name = GetPlayerName(source)
	amount = ESX.Math.Round(tonumber(amount))

	if xPlayer.job.name == society.name then
		TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
			if amount > 0 and account.money >= amount then
				account.removeMoney(amount)
				AddMoney(_src, amount)
				JobNotifyClient( _src, ('Vous avez retiré ~g~%s$~s~'):format(ESX.Math.GroupDigits(amount)))
			else
				JobNotifyClient( _src, ('montant invalide'))
			end
		end)
	else
		print(('esx_society: %s attempted to call withdrawMoney!'):format(xPlayer.identifier))
	end
end)

RegisterServerEvent('esx_society:withdrawMoney2')
AddEventHandler('esx_society:withdrawMoney2', function(society, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	local society = GetSociety(society)
	local name = GetPlayerName(source)
	amount = ESX.Math.Round(tonumber(amount))

	if xPlayer.job2.name == society.name then
		TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
			if amount > 0 and account.money >= amount then
				account.removeMoney(amount)
				AddBlackMoneyOnPlayer(source, amount)
				JobNotifyClient( source, ('Vous avez retiré ~g~$%s~s~'):format(ESX.Math.GroupDigits(amount)))
			else
				JobNotifyClient( source, ('montant invalide'))
			end
		end)
	else
		print(('esx_society: %s attempted to call withdrawMoney!'):format(xPlayer.identifier))
	end
end)

RegisterServerEvent('esx_society:depositMoney1')
AddEventHandler('esx_society:depositMoney1', function(society, amount)
	local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
	local society = GetSociety(society)
	local name = GetPlayerName(source)
	amount = ESX.Math.Round(tonumber(amount))

	if xPlayer.job.name == society.name then
		if amount > 0 and GetMoney(source) >= amount then
			TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
				RemoveMoneyOnPlayer(source, amount)
				account.addMoney(amount)
			end)

			JobNotifyClient( source, ('Vous avez déposé ~r~$%s~s~'):format(ESX.Math.GroupDigits(amount)))
		else
			JobNotifyClient( source, ('montant invalide'))
		end
	else
		print(('esx_society: %s attempted to call depositMoney!'):format(xPlayer.identifier))
	end
end)

RegisterServerEvent('esx_society:depositMoney2')
AddEventHandler('esx_society:depositMoney2', function(society, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	local society = GetSociety(society)
	local name = GetPlayerName(source)
	amount = ESX.Math.Round(tonumber(amount))

	if xPlayer.job2.name == society.name then
		if amount > 0 and GetBlackMoneyOnPlayer(source) >= amount then
			TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
				RemoveBlackMoneyOnPlayer(source, amount)
				account.addMoney(amount)
			end)

			JobNotifyClient( source, ('vous avez déposé ~r~$%s~s~'):format(ESX.Math.GroupDigits(amount)))
		else
			JobNotifyClient( source, ('montant invalide'))
		end
	else
		print(('esx_society: %s attempted to call depositMoney!'):format(xPlayer.identifier))
	end
end)


RegisterServerEvent('esx_society:washMoney1')
AddEventHandler('esx_society:washMoney1', function(society, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	local account = GetBlackMoneyOnPlayer(source)
	amount = ESX.Math.Round(tonumber(amount))

	if xPlayer.job.name == society then
		if amount and amount > 0 and account.money >= amount then
			RemoveBlackMoneyOnPlayer(source, amount)

			MySQL.Async.execute('INSERT INTO society_moneywash (identifier, society, amount) VALUES (@identifier, @society, @amount)', {
				['@identifier'] = xPlayer.identifier,
				['@society']    = society,
				['@amount']     = amount
			}, function(rowsChanged)
				JobNotifyClient( source, ('vous avez ~g~$%s~s~ en attente de ~r~blanchiement~s~ (24h).'):format(ESX.Math.GroupDigits(amount)))
			end)
		else
			JobNotifyClient( source, ('montant invalide'))
		end
	else
		print(('esx_society: %s attempted to call washMoney!'):format(xPlayer.identifier))
	end
end)

RegisterServerEvent('esx_society:putVehicleInGarage1')
AddEventHandler('esx_society:putVehicleInGarage1', function(societyName, vehicle)
	local society = GetSociety(societyName)
	local name = GetPlayerName(source)

	TriggerEvent('esx_datastore:getSharedDataStore', society.datastore, function(store)
		local garage = store.get('garage') or {}
		table.insert(garage, vehicle)
		store.set('garage', garage)
	end)
end)

RegisterServerEvent('esx_society:removeVehicleFromGarage1')
AddEventHandler('esx_society:removeVehicleFromGarage1', function(societyName, vehicle)
	local society = GetSociety(societyName)
	local name = GetPlayerName(source)

	TriggerEvent('esx_datastore:getSharedDataStore', society.datastore, function(store)
		local garage = store.get('garage') or {}
		for i=1, #garage, 1 do
			if garage[i].plate == vehicle.plate then
				table.remove(garage, i)
				break
			end
		end

		store.set('garage', garage)
	end)
end)

ESX.RegisterServerCallback('esx_society:getSocietyMoney', function(source, cb, societyName)
	local xPlayer = ESX.GetPlayerFromId(source)

	if not xPlayer or not xPlayer.job then
		cb(0)
		return
	end

	-- Le menu patron demande le solde du métier courant.
	-- On refuse de lire le compte d'un autre métier via ce callback.
	societyName = societyName or xPlayer.job.name
	if societyName ~= xPlayer.job.name then
		print(('[esx_society] Lecture de solde refusée pour %s (job joueur: %s)'):format(tostring(societyName), tostring(xPlayer.job.name)))
		cb(0)
		return
	end

	-- Certaines ressources enregistrent la société via registerSociety, d'autres
	-- créent seulement le compte addon_account. On supporte les deux cas.
	local society = GetSociety(societyName)
	local accountName = society and society.account or ('society_' .. societyName)

	TriggerEvent('esx_addonaccount:getSharedAccount', accountName, function(account)
		if not account then
			print(('[esx_society] Compte entreprise introuvable : %s'):format(tostring(accountName)))
			cb(0)
			return
		end

		cb(tonumber(account.money) or 0)
	end)
end)

ESX.RegisterServerCallback('esx_society:getEmployees', function(source, cb, society)
	-- if Config.EnableESXIdentity then

		MySQL.Async.fetchAll('SELECT firstname, lastname, identifier, job, job_grade FROM users WHERE job = @job ORDER BY job_grade DESC', {
			['@job'] = society
		}, function (results)
			local employees = {}

			for i=1, #results, 1 do
				EnsureJob(results[i].job)
				local J = Jobs[results[i].job]
				if J and J.grades[tostring(results[i].job_grade)] then   -- métier / grade inconnu : employé ignoré au lieu de planter
				table.insert(employees, {
					name       = results[i].firstname .. ' ' .. results[i].lastname,
					identifier = results[i].identifier,
					job = {
						name        = results[i].job,
						label       = Jobs[results[i].job].label,
						grade       = results[i].job_grade,
						grade_name  = Jobs[results[i].job].grades[tostring(results[i].job_grade)].name,
						grade_label = Jobs[results[i].job].grades[tostring(results[i].job_grade)].label
					},
				})
				end
			end

			print(#employees)

			cb(employees)
		end)
	-- end
end)

ESX.RegisterServerCallback('esx_society:getEmployees2', function(source, cb, society)
	-- if Config.EnableESXIdentity then
		MySQL.Async.fetchAll('SELECT firstname, lastname, identifier, job2, job2_grade FROM users WHERE job2 = @job2 ORDER BY job2_grade DESC', {
			['@job2'] = society
		}, function (results)
			local employees = {}

			for i=1, #results, 1 do
				table.insert(employees, {
					name       = results[i].firstname .. ' ' .. results[i].lastname,
					identifier = results[i].identifier,
					job2 = {
						name        = results[i].job2,
						label       = Jobs2[results[i].job2].label,
						grade       = results[i].job2_grade,
						grade_name  = Jobs2[results[i].job2].grades[tostring(results[i].job2_grade)].name,
						grade_label = Jobs2[results[i].job2].grades[tostring(results[i].job2_grade)].label
					}
				})
			end

			cb(employees)
		end)
	-- end
end)

ESX.RegisterServerCallback('esx_society:getJob', function(source, cb, society)
	EnsureJob(society)
	local job    = Jobs[society] and json.decode(json.encode(Jobs[society]))
	if not job then return cb(nil) end
	local grades = {}

	for k,v in pairs(job.grades) do
		table.insert(grades, v)
	end

	table.sort(grades, function(a, b)
		return a.grade < b.grade
	end)

	job.grades = grades

	cb(job)
end)

ESX.RegisterServerCallback('esx_society:getJob2', function(source, cb, society)
	local job2    = Jobs2[society] and json.decode(json.encode(Jobs2[society]))
	if not job2 then return cb(nil) end
	local grades = {}

	for k,v in pairs(job2.grades) do
		table.insert(grades, v)
	end

	table.sort(grades, function(a, b)
		return a.grade < b.grade
	end)

	job2.grades = grades

	cb(job2)
end)

ESX.RegisterServerCallback('esx_society:setJob', function(source, cb, identifier, job, grade, type)
	local xPlayer = ESX.GetPlayerFromId(source)
	local isBoss = xPlayer.job.grade_name == 'boss'

	if isBoss then
		local xTarget = ESX.GetPlayerFromIdentifier(identifier)

		if xTarget then
			xTarget.setJob(job, grade)

			if type == 'hire' then
				JobNotifyClient( source, ('Vous avez été recruté dans la société %s'):format(job))
			elseif type == 'promote' then
				JobNotifyClient( source, ('Vous avez été promu'))
			elseif type == 'fire' then
				JobNotifyClient( source, ('Vous avez été viré de la société %s'):format(xTarget.getJob().label))
			end

			cb()
		else
			MySQL.Async.execute('UPDATE users SET job = @job, job_grade = @job_grade WHERE identifier = @identifier', {
				['@job']        = job,
				['@job_grade']  = grade,
				['@identifier'] = identifier
			}, function(rowsChanged)
				cb()
			end)
		end
	else
		print(('esx_society: %s attempted to setJob'):format(xPlayer.identifier))
		cb()
	end
end)

ESX.RegisterServerCallback('esx_society:setJob2', function(source, cb, identifier, job, grade, type)
	local xPlayer = ESX.GetPlayerFromId(source)
	if not xPlayer or not xPlayer.job2 or xPlayer.job2.grade_name ~= 'boss' then
		if xPlayer then print(('esx_society: %s attempted to setJob2'):format(xPlayer.identifier)) end
		cb(false)
		return
	end

	local currentGang = xPlayer.job2.name
	local isFire = job == 'unemployed2' and tonumber(grade) == 0
	if (not isFire and job ~= currentGang) or not identifier then
		cb(false)
		return
	end

	local xTarget = ESX.GetPlayerFromIdentifier(identifier)

	if xTarget then
		if not xTarget.job2 or xTarget.job2.name ~= currentGang then
			cb(false)
			return
		end

		local previousJob2 = xTarget.job2.label
		xTarget.setJob2(job, grade)

		if type == 'hire' then
			JobNotifyClient( source, ('Vous avez été recruté dans le gang %s'):format(job))
		elseif type == 'promote' then
			JobNotifyClient( source, 'Vous avez été promu')
		elseif type == 'fire' then
			JobNotifyClient( source, ('Vous avez été viré du gang %s'):format(previousJob2))
		end

		cb(true)
	else
		MySQL.Async.fetchAll('SELECT job2 FROM users WHERE identifier = @identifier LIMIT 1', {
			['@identifier'] = identifier
		}, function(rows)
			if not rows or not rows[1] or rows[1].job2 ~= currentGang then
				cb(false)
				return
			end

			MySQL.Async.execute('UPDATE users SET job2 = @job2, job2_grade = @job2_grade WHERE identifier = @identifier', {
				['@job2'] = job,
				['@job2_grade'] = tonumber(grade),
				['@identifier'] = identifier
			}, function(rowsChanged)
				cb(rowsChanged and rowsChanged > 0)
			end)
		end)
	end
end)

ESX.RegisterServerCallback('esx_society:setJobSalary', function(source, cb, job, grade, salary)
	local isBoss = isPlayerBoss(source, job)
	local identifier = GetPlayerIdentifier(source, 0)

	if isBoss then
		if salary <= Config.MaxSalary then
			MySQL.Async.execute('UPDATE job_grades SET salary = @salary WHERE job_name = @job_name AND grade = @grade', {
				['@salary']   = salary,
				['@job_name'] = job,
				['@grade']    = grade
			}, function(rowsChanged)
				EnsureJob(job)
				if Jobs[job] and Jobs[job].grades[tostring(grade)] then Jobs[job].grades[tostring(grade)].salary = salary end
				local xPlayers = ESX.GetPlayers()

				for i=1, #xPlayers, 1 do
					local xPlayer = ESX.GetPlayerFromId(xPlayers[i])

					if xPlayer.job.name == job and xPlayer.job.grade == grade then
						xPlayer.setJob(job, grade)
					end
				end

				cb()
			end)
		else
			print(('esx_society: %s attempted to setJobSalary over config limit!'):format(identifier))
			cb()
		end
	else
		print(('esx_society: %s attempted to setJobSalary'):format(identifier))
		cb()
	end
end)

ESX.RegisterServerCallback('esx_society:setJobSalaryGouv', function(source, cb, job, grade, salary)
	local identifier = GetPlayerIdentifier(source, 0)

	MySQL.Async.execute('UPDATE job_grades SET salary = @salary WHERE job_name = @job_name AND grade = @grade', {
		['@salary']   = salary,
		['@job_name'] = job,
		['@grade']    = grade
	}, function(rowsChanged)
		EnsureJob(job)
		if Jobs[job] and Jobs[job].grades[tostring(grade)] then Jobs[job].grades[tostring(grade)].salary = salary end
		local xPlayers = ESX.GetPlayers()

		for i=1, #xPlayers, 1 do
			local xPlayer = ESX.GetPlayerFromId(xPlayers[i])

			if xPlayer.job.name == job and xPlayer.job.grade == grade then
				xPlayer.setJob(job, grade)
			end
		end

		cb()
	end)
end)

ESX.RegisterServerCallback('esx_society:getOnlinePlayers', function(source, cb)
	local xPlayers = ESX.GetPlayers()
	local players  = {}

	for i=1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		table.insert(players, {
			source     = xPlayer.source,
			identifier = xPlayer.identifier,
			name       = xPlayer.name,
			job        = xPlayer.job,
			job2	   = xPlayer.job2
		})
	end

	cb(players)
end)

ESX.RegisterServerCallback('esx_society:getVehiclesInGarage1', function(source, cb, societyName)
	local society = GetSociety(societyName)

	TriggerEvent('esx_datastore:getSharedDataStore', society.datastore, function(store)
		local garage = store.get('garage') or {}
		cb(garage)
	end)
end)

function isPlayerBoss2(playerId, job)
	local xPlayer = ESX.GetPlayerFromId(playerId)

	if xPlayer.job2.name == job and xPlayer.job2.grade_name == 'boss' then
		return true
	else
		print(('esx_society: %s attempted open a society boss menu!'):format(xPlayer.identifier))
		return false
	end
end

ESX.RegisterServerCallback('esx_society:isBoss2', function(source, cb, job)
	cb(isPlayerBoss2(source, job))

end)

function isPlayerBoss(playerId, job)
	local xPlayer = ESX.GetPlayerFromId(playerId)

	if xPlayer.job.name == job and xPlayer.job.grade_name == 'boss' then
		return true
	else
		print(('esx_society: %s attempted open a society boss menu!'):format(xPlayer.identifier))
		return false
	end
end

ESX.RegisterServerCallback('esx_society:isBoss', function(source, cb, job)
	cb(isPlayerBoss(source, job))
end)

RegisterServerEvent("CorePickax_Society:recruit")
AddEventHandler("CorePickax_Society:recruit", function(job, target)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(target)

    if (not xPlayer) then return end
    if (xPlayer.getJob().name) == job and (xPlayer.getJob().grade_name) == "boss" then
		if xTarget.getJob().name ~= job then
			TriggerClientEvent("CorePickax_Society:recruit", target, source, job)
		else
			JobNotifyClient( source, 'La personne est déjà dans votre entreprise.')
		end
    end
end)

RegisterServerEvent("CorePickax_Society:recruit2")
AddEventHandler("CorePickax_Society:recruit2", function(type, job, target)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(target)

    if (not xPlayer) then return end
	if (xTarget.getJob().name) == job and (xTarget.getJob().grade_name) == "boss" then
		if type == "accept" then
			xPlayer.setJob(job, 0)
			JobNotifyClient( xTarget.source, 'La personne à été recruté.')
			JobNotifyClient( xPlayer.source, ('Vous avez été recruté en tant que %s'):format(job))
		elseif type == "decline" then
			JobNotifyClient( xTarget.source, 'La personne n\'a pas été recruté car il a refuser')
			JobNotifyClient( xPlayer.source, 'Vous n\'avez pas été recruté car vous avez refusé')
		elseif type == "passed" then 
			JobNotifyClient( xTarget.source, 'La personne n\'a pas été recruté a cause du temps imparti.')
			JobNotifyClient( xPlayer.source, 'Vous n\'avez pas été recruté a cause du temps imparti')
		end
	end
end)
