--GetItem
ESX.RegisterServerCallback('ContextMenu:HasItem', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local HasItemQuantity = GetItemOnPlayer(source, ConfigContextMenu.ItemCrocheter).count
	if HasItemQuantity >= 1 then
		RemoveItemOnPlayer(source, ConfigContextMenu.ItemCrocheter, 1)
		cb(true)
	else
		cb(false)
	end
end)
--Drogues
for k, v in ipairs(ConfigContextMenu.Drugs.DrugsListCallback) do
	ESX.RegisterServerCallback(v.callback, function(source, cb)
		local xPlayer = ESX.GetPlayerFromId(source)
		local HasItemQuantity = GetItemOnPlayer(source, v.Item).count
		if HasItemQuantity >= v.Count then
			cb(true)
		else
			cb(false)
		end
	end)
end
ESX.RegisterServerCallback("ContextMenu:CheckIfCops", function(source, cb)
	if ESXCustom_Function_ServerSide:CountCops() < ConfigContextMenu.Drugs.PoliceRequis then
		cb(false)
	else
		cb(true)
	end
end)
RegisterServerEvent("ContextMenu:DrugsMoula")
AddEventHandler("ContextMenu:DrugsMoula", function(src, lapose, item, ItemDrugs, AmountDrugs, Count)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	if lapose < 10.0 then
		local HasItemQuantity = GetItemOnPlayer(src, ItemDrugs).count
		if HasItemQuantity >= Count then
			AddMoneyDrugsOnPlayer(src, AmountDrugs)
			RemoveItemOnPlayer(src, ItemDrugs, Count)
			TriggerClientEvent(Config.Trigger.TriggerNotification, src, (NotificationContextMenu.Messagevente):format(item))
		else
			return ESXCustomServerUtils.rejectSuspiciousAction(src, NotificationContextMenu.MaybeCheat)
		end
	else
		return ESXCustomServerUtils.rejectSuspiciousAction(src, NotificationContextMenu.MaybeCheat)
	end
end)
ESX.RegisterServerCallback('ContextMenu:Bill_getBills', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	MySQL.Async.fetchAll('SELECT * FROM billing WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)
		local bills = {}
		for i = 1, #result do
			bills[#bills + 1] = {
				id = result[i].id,
				label = result[i].label,
				amount = result[i].amount
			}
		end
		cb(bills)
	end)
end)

ESX.RegisterServerCallback('ContextMenu:GetItems', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	MySQL.Async.fetchAll('SELECT * FROM items', {}, function(result)
		cb(result)
	end)
end)
--Pour les jobs
function getMaximumGrade(jobName)
	local p = promise.new()
	MySQL.Async.fetchScalar('SELECT grade FROM job_grades WHERE job_name = @job_name ORDER BY `grade` DESC', { ['@job_name'] = jobName }, function(result)
		p:resolve(result)
	end)
	local queryResult = Citizen.Await(p)
	return tonumber(queryResult)
end
RegisterServerEvent('ContextMenu:Boss_promouvoirplayer')
AddEventHandler('ContextMenu:Boss_promouvoirplayer', function(target)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local sourceJob = GetJob(source)
	if sourceJob.grade_name == ConfigContextMenu.GradeBoss.Jobs then
		local targetXPlayer = ESX.GetPlayerFromId(target)
		local targetJob = GetJob(target)
		if sourceJob.name == targetJob.name then
			local newGrade = tonumber(targetJob.grade) + 1
			if newGrade ~= getMaximumGrade(targetJob.name) then
				SetJobPlayerJob(targetXPlayer, targetJob.name, newGrade)
				-- targetXPlayer.setJob(targetJob.name, newGrade)
				TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, (NotificationContextMenu.PromotePlayer):format(targetXPlayer.name))
				TriggerClientEvent(Config.Trigger.TriggerNotification, target, (NotificationContextMenu.PromotePlayer2):format(sourceXPlayer.name))
			else
				TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, NotificationContextMenu.ErrorMaxGrade)
			end
		else
			TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, NotificationContextMenu.NoJob)
		end
	else
		TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, NotificationContextMenu.NoAuthorization)
	end
end)
RegisterServerEvent('ContextMenu:Boss_destituerplayer')
AddEventHandler('ContextMenu:Boss_destituerplayer', function(target)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local sourceJob = GetJob(source)
	if sourceJob.grade_name == ConfigContextMenu.GradeBoss.Jobs then
		local targetXPlayer = ESX.GetPlayerFromId(target)
		local targetJob = GetJob(target)
		if sourceJob.name == targetJob.name then
			local newGrade = tonumber(targetJob.grade) - 1
			if newGrade >= 0 then
				SetJobPlayerJob(targetXPlayer, targetJob.name, newGrade)
				-- targetXPlayer.setJob(targetJob.name, newGrade)
				TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, (NotificationContextMenu.DemotePlayer):format(targetXPlayer.name))
				TriggerClientEvent(Config.Trigger.TriggerNotification, target, (NotificationContextMenu.DemotePlayer2):format(sourceXPlayer.name))
			else
				TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, NotificationContextMenu.ErrorDemoteMiniGrade)
			end
		else
			TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, NotificationContextMenu.NoJob2)
		end
	else
		TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, NotificationContextMenu.NoAuthorization)
	end
end)
RegisterServerEvent('ContextMenu:Boss_recruterplayer')
AddEventHandler('ContextMenu:Boss_recruterplayer', function(target)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local sourceJob = GetJob(source)
	if sourceJob.grade_name == ConfigContextMenu.GradeBoss.Jobs then
		local targetXPlayer = ESX.GetPlayerFromId(target)
		SetJobPlayerJob(targetXPlayer, sourceJob.name, 0)
		-- targetXPlayer.setJob(sourceJob.name, 0)
		TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, (NotificationContextMenu.RecruitPlayer):format(targetXPlayer.name))
		TriggerClientEvent(Config.Trigger.TriggerNotification, target, (NotificationContextMenu.HiringPlayer):format(sourceXPlayer.name))
	end
end)
RegisterServerEvent('ContextMenu:Boss_virerplayer')
AddEventHandler('ContextMenu:Boss_virerplayer', function(target)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local sourceJob = GetJob(source)
	if sourceJob.grade_name == ConfigContextMenu.GradeBoss.Jobs then
		local targetXPlayer = ESX.GetPlayerFromId(target)
		local targetJob = GetJob(target)
		if sourceJob.name == targetJob.name then
			SetJobPlayerJob(targetXPlayer, ConfigContextMenu.JobsName, 0)
			-- targetXPlayer.setJob(ConfigContextMenu.JobsName, 0)
			TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, (NotificationContextMenu.FiredPlayer):format(targetXPlayer.name))
			TriggerClientEvent(Config.Trigger.TriggerNotification, target, (NotificationContextMenu.FiredPlayer2):format(sourceXPlayer.name))
		else
			TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, NotificationContextMenu.NoJob)
		end
	else
		TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, NotificationContextMenu.NoAuthorization)
	end
end)
if ConfigContextMenu.Jobs2 then
	--Pour les orga
	function getMaximumGrade(jobName)
		local p = promise.new()
		MySQL.Async.fetchScalar('SELECT grade FROM job_grades WHERE job_name = @job_name ORDER BY `grade` DESC', { ['@job_name'] = jobName }, function(result)
			p:resolve(result)
		end)
		local queryResult = Citizen.Await(p)
		return tonumber(queryResult)
	end
	RegisterServerEvent('ContextMenu:Boss_promouvoirplayer2')
	AddEventHandler('ContextMenu:Boss_promouvoirplayer2', function(target)
		local sourceXPlayer = ESX.GetPlayerFromId(source)
		local sourceJob = GetJob2(source)
		if sourceJob.grade_name == ConfigContextMenu.GradeBoss.Jobs2 then
			local targetXPlayer = ESX.GetPlayerFromId(target)
			local targetJob = GetJob2(target)
			if sourceJob.name == targetJob.name then
				local newGrade = tonumber(targetJob.grade) + 1
				if newGrade ~= getMaximumGrade(targetJob.name) then
					SetJobPlayerOrga(targetXPlayer, targetJob.name, newGrade)
					-- targetXPlayer.setJob2(targetJob.name, newGrade)
					TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, (NotificationContextMenu.PromotePlayer):format(targetXPlayer.name))
					TriggerClientEvent(Config.Trigger.TriggerNotification, target, (NotificationContextMenu.PromotePlayer2):format(sourceXPlayer.name))
				else
					TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, NotificationContextMenu.ErrorMaxGrade)
				end
			else
				TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, NotificationContextMenu.NoJob)
			end
		else
			TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, NotificationContextMenu.NoAuthorization)
		end
	end)
	RegisterServerEvent('ContextMenu:Boss_destituerplayer2')
	AddEventHandler('ContextMenu:Boss_destituerplayer2', function(target)
		local sourceXPlayer = ESX.GetPlayerFromId(source)
		local sourceJob = GetJob2(source)
		if sourceJob.grade_name == ConfigContextMenu.GradeBoss.Jobs2 then
			local targetXPlayer = ESX.GetPlayerFromId(target)
			local targetJob = GetJob2(target)
			if sourceJob.name == targetJob.name then
				local newGrade = tonumber(targetJob.grade) - 1
				if newGrade >= 0 then
					SetJobPlayerOrga(targetXPlayer, targetJob.name, newGrade)
					-- targetXPlayer.setJob2(targetJob.name, newGrade)
					TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, (NotificationContextMenu.DemotePlayer):format(targetXPlayer.name))
					TriggerClientEvent(Config.Trigger.TriggerNotification, target, (NotificationContextMenu.DemotePlayer2):format(sourceXPlayer.name))
				else
					TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, NotificationContextMenu.ErrorDemoteMiniGrade)
				end
			else
				TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, NotificationContextMenu.NoJob2)
			end
		else
			TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, NotificationContextMenu.NoAuthorization)
		end
	end)
	RegisterServerEvent('ContextMenu:Boss_recruterplayer2')
	AddEventHandler('ContextMenu:Boss_recruterplayer2', function(target)
		local sourceXPlayer = ESX.GetPlayerFromId(source)
		local sourceJob = GetJob2(source)
		if sourceJob.grade_name == ConfigContextMenu.GradeBoss.Jobs2 then
			local targetXPlayer = ESX.GetPlayerFromId(target)
			SetJobPlayerOrga(targetXPlayer, sourceJob.name, 0)
			-- targetXPlayer.setJob2(sourceJob.name, 0)
			TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, (NotificationContextMenu.RecruitPlayer):format(targetXPlayer.name))
			TriggerClientEvent(Config.Trigger.TriggerNotification, target, (NotificationContextMenu.HiringPlayer):format(sourceXPlayer.name))
		end
	end)
	RegisterServerEvent('ContextMenu:Boss_virerplayer2')
	AddEventHandler('ContextMenu:Boss_virerplayer2', function(target)
		local sourceXPlayer = ESX.GetPlayerFromId(source)
		local sourceJob = GetJob2(source)
		if sourceJob.grade_name == ConfigContextMenu.GradeBoss.Jobs2 then
			local targetXPlayer = ESX.GetPlayerFromId(target)
			local targetJob = GetJob2(target)
			if sourceJob.name == targetJob.name then
				SetJobPlayerOrga(targetXPlayer, ConfigContextMenu.Jobs2Name, 0)
				-- targetXPlayer.setJob2(ConfigContextMenu.Jobs2Name, 0)
				TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, (NotificationContextMenu.FiredPlayer):format(targetXPlayer.name))
				TriggerClientEvent(Config.Trigger.TriggerNotification, target, (NotificationContextMenu.FiredPlayer2):format(sourceXPlayer.name))
			else
				TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, NotificationContextMenu.NoJob)
			end
		else
			TriggerClientEvent(Config.Trigger.TriggerNotification, sourceXPlayer.source, NotificationContextMenu.NoAuthorization)
		end
	end)
end
--GiveItem
RegisterServerEvent("ContextMenu:GiveLitemAujoueurs")
AddEventHandler("ContextMenu:GiveLitemAujoueurs", function(src, item, amount, itemName, lapose)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	if #(GetEntityCoords(GetPlayerPed(src)) - lapose) < 10.0 then
		AddItemOnPlayer(src, item, amount)
		TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, (NotificationContextMenu.FindItem):format(amount, itemName))
	else
		return ESXCustomServerUtils.rejectSuspiciousAction(src, NotificationContextMenu.MaybeCheat)
	end
end)
--Déposer
RegisterServerEvent("ContextMenuBank:deposer")
AddEventHandler("ContextMenuBank:deposer", function(money)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local total = money
	local xMoney = GetMoney(_source)
	local name = GetPlayerName(_source)
	
	if xMoney >= total then
		AddAtAccountOnPlayer(_source, ConfigContextMenu.Money.ArgentBanque, total)
		RemoveMoneyOnPlayer(_source, total)
		TriggerClientEvent(Config.Trigger.TriggerNotification, source, (NotificationContextMenu.DepositMoney):format(total))
	else
		TriggerClientEvent(Config.Trigger.TriggerNotification, source, NotificationContextMenu.NoEnoughtMoney)
	end 
end)
--Retirer
RegisterServerEvent("ContextMenuBank:retirer")
AddEventHandler("ContextMenuBank:retirer", function(money)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local total = money
	local xMoney = GetMoneyBanque(_source)
	local name = GetPlayerName(_source)
	
	if xMoney >= total then
		RemoveAtAccountOnPlayer(_source, ConfigContextMenu.Money.ArgentBanque, total)
		AddMoney(_source, total)
		TriggerClientEvent(Config.Trigger.TriggerNotification, source, (NotificationContextMenu.TakeMoney):format(total))
	else
		TriggerClientEvent(Config.Trigger.TriggerNotification, source, NotificationContextMenu.NoEnoughtMoney)
	end
end)
--Send
RegisterServerEvent('ContextMenuBank:transfer')
AddEventHandler('ContextMenuBank:transfer', function(to, amountt)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local zPlayer = ESX.GetPlayerFromId(to)
	local balance = 0
	if(zPlayer == nil or zPlayer == -1) then
		TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, NotificationContextMenu.NoID)
	else
		balance = GetMoneyBanque(_source)
		zbalance = GetMoneyBanque(to)
		if tonumber(_source) == tonumber(to) then
			TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, NotificationContextMenu.NotToYou)
		else
			if balance <= 0 or balance < tonumber(amountt) or tonumber(amountt) <= 0 then
				TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, NotificationContextMenu.NoMoneyAtBank)
			else
				RemoveAtAccountOnPlayer(_source, ConfigContextMenu.Money.ArgentBanque, tonumber(amountt))
				AddAtAccountOnPlayer(to, ConfigContextMenu.Money.ArgentBanque, tonumber(amountt))
				TriggerClientEvent(Config.Trigger.TriggerNotification, _source, (NotificationContextMenu.TransfereMoney):format(tonumber(amountt), zPlayer.getName()))
				TriggerClientEvent(Config.Trigger.TriggerNotification, to, (NotificationContextMenu.ReceiveMoney):format(tonumber(amountt), xPlayer.getName()))
			end
		end
	end
end)
--
RegisterNetEvent("ContextMenu:removeMoney")
AddEventHandler("ContextMenu:removeMoney", function(src, Moula, healing, water, Item)
	local src = source
	xPlayer = ESX.GetPlayerFromId(src)
	local argent = 0
	argent = GetMoney(src)
	if argent <= 0 or argent < tonumber(Moula) or tonumber(Moula) <= 0 then
		TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, NotificationContextMenu.NomMoneyOnYou)
	else
		TriggerClientEvent(Config.Trigger.TriggerNotification, xPlayer.source, NotificationContextMenu.YouBuy)
		RemoveMoneyOnPlayer(src, tonumber(Moula))
		if healing and water then
			Item = nil
			TriggerEvent("ContextMenu:GiveHeal", src, "eau")
		elseif healing and not water then
			TriggerEvent("ContextMenu:GiveHeal", src, "cafe")
		else
			AddItemOnPlayer(src, Item, 1)
		end
	end
end)
RegisterNetEvent("ContextMenu:GiveHeal")
AddEventHandler("ContextMenu:GiveHeal", function(src, List)
	xPlayer = ESX.GetPlayerFromId(src)
	if List == "eau" then
		TriggerClientEvent('esx_status:add', src, 'thirst', 200000)
		TriggerClientEvent('esx_basicneeds:onDrink', src)
		-- xPlayer.showNotification("Vous avez bu de l'eau")
		TriggerClientEvent(Config.Trigger.TriggerNotification, src, "Vous avez bu de l'eau")
	elseif List == "cafe" then
		TriggerClientEvent('esx_status:add', src, 'thirst', 60000)
		TriggerClientEvent('esx_basicneeds:onDrinkCoffe', src)
		-- xPlayer.showNotification("Vous avez bu un café")
		TriggerClientEvent(Config.Trigger.TriggerNotification, src, "Vous avez bu un café")
	else
		return ESXCustomServerUtils.rejectSuspiciousAction(src, NotificationContextMenu.MaybeCheat)
	end
end)

--
RegisterServerEvent("ContextMenu:TPJoueur")
AddEventHandler("ContextMenu:TPJoueur", function(src, lejoueur, lapose)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	if xPlayer.getGroup() ~= ConfigContextMenu.UserGroup then
		SetEntityCoords(lejoueur, lapose)
	else
		return ESXCustomServerUtils.rejectSuspiciousAction(src, NotificationContextMenu.MaybeCheat)
	end
end)
RegisterServerEvent("ContextMenu:healPlayer")
AddEventHandler("ContextMenu:healPlayer", function(lejoueur)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() ~= ConfigContextMenu.UserGroup then
		TriggerClientEvent(ConfigContextMenu.Triggers.TriggerhealLejoueur, lejoueur)
		TriggerClientEvent(Config.Trigger.TriggerNotification, lejoueur, NotificationContextMenu.HealPlayer)
	else
		return ESXCustomServerUtils.rejectSuspiciousAction(src, NotificationContextMenu.MaybeCheat)
	end
end)
--
RegisterServerEvent('ContextMenu:EnleveMask')
AddEventHandler('ContextMenu:EnleveMask', function(target)
	TriggerClientEvent(Config.Trigger.TriggerNotification, target, NotificationContextMenu.TakeOffMask)
	SetPedComponentVariation(target, 1, 0, 0, 2)
end)
RegisterServerEvent('ContextMenu:SendMessage')
AddEventHandler('ContextMenu:SendMessage', function(target, society, raison, montant)
	TriggerClientEvent(Config.Trigger.TriggerNotification, target, (NotificationContextMenu.BillingMessage):format(society, raison, montant))
end)
--Gangs
ESX.RegisterServerCallback('ContextMenu:getOtherPlayerData', function(source, cb, target, notify)
	local xPlayer = ESX.GetPlayerFromId(target)
	TriggerClientEvent(Config.Trigger.TriggerNotification, target, NotificationContextMenu.BodySearch)
	if xPlayer then
		local data = {
			name = xPlayer.getName(),
			job = xPlayer.job.label,
			grade = xPlayer.job.grade_label,
			inventory = xPlayer.getInventory(),
			accounts = xPlayer.getAccounts(),
			weapons = xPlayer.getLoadout()
		}
		cb(data)
	end
end)
ESX.RegisterServerCallback('ContextMenu:getOtherPlayerData1', function(source, cb, target, notify)
	local xPlayer = ESX.GetPlayerFromId(target)
	if xPlayer then
		local data = {
			name = xPlayer.getName(),
			job = xPlayer.job.label,
			grade = xPlayer.job.grade_label,
			inventory = xPlayer.getInventory(),
			accounts = xPlayer.getAccounts(),
			weapons = xPlayer.getLoadout()
		}
		cb(data)
	end
end)
RegisterNetEvent('ContextMenu:confiscatePlayerItem')
AddEventHandler('ContextMenu:confiscatePlayerItem', function(target, itemType, itemName, amount)
	local _source = source
	local sourceXPlayer = ESX.GetPlayerFromId(_source)
	local targetXPlayer = ESX.GetPlayerFromId(target)
	if itemType == 'item_standard' then
		local targetItem = GetItemOnPlayer(target, itemName).count
		local sourceItem = GetItemOnPlayer(_source, itemName).count
		
		RemoveItemOnPlayer(target, itemName, amount)
		AddItemOnPlayer(_source, itemName, amount)
		TriggerClientEvent(Config.Trigger.TriggerNotification, source, (NotificationContextMenu.ConfiscateItem):format(amount, sourceItem.label))
		TriggerClientEvent(Config.Trigger.TriggerNotification, target, (NotificationContextMenu.ConfiscateItem2):format(amount, sourceItem.label))
	end
	if itemType == 'item_account' then
		RemoveAtAccountOnPlayer(target, itemName, amount)
		AddAtAccountOnPlayer(_source, itemName, amount)
		TriggerClientEvent(Config.Trigger.TriggerNotification, source, (NotificationContextMenu.ConfiscateMoney):format(amount))
		TriggerClientEvent(Config.Trigger.TriggerNotification, target, (NotificationContextMenu.ConfiscateMoney2):format(amount))
	end
	if itemType == 'item_weapon' then
		if amount == nil then amount = 0 end
		targetXPlayer.removeWeapon(itemName, amount)
		sourceXPlayer.addWeapon(itemName, amount)
		TriggerClientEvent(Config.Trigger.TriggerNotification, source, (NotificationContextMenu.ConfiscateWeapon):format(ESX.GetWeaponLabel(itemName), amount))
		TriggerClientEvent(Config.Trigger.TriggerNotification, target, (NotificationContextMenu.ConfiscateWeapon2):format(ESX.GetWeaponLabel(itemName), amount))
	end
end)
--
if ConfigContextMenu.Drugs.AppellePolice then
	RegisterServerEvent("ContextMenu:SendMessageCops")
	AddEventHandler("ContextMenu:SendMessageCops", function(src)
		local src = source
		local xPlayer = ESX.GetPlayerFromId(src)
		for k, v in pairs(ESXCustomServerUtils.GetInfoByJobsName.Police) do
			local xPlayer = ESX.GetPlayerFromId(k)
	
			if xPlayer.job.name == 'police' then
				TriggerClientEvent(Config.Trigger.TriggerNotification, k, NotificationContextMenu.CallPoliceDrugs)
			end
		end
	end)
	RegisterServerEvent('ContextMenu:DrugsInProgress')
	AddEventHandler('ContextMenu:DrugsInProgress', function(targetCoords)
		TriggerClientEvent('ContextMenu:DrugsInProgress', -1, targetCoords)
	end)
end
RegisterServerEvent("CorePickax:GiveItemStaffRapide")
AddEventHandler("CorePickax:GiveItemStaffRapide", function(_src, Item, Label, target)
	_src = source
	local xPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)
	if xPlayer then
		if xPlayer.getGroup() ~= ConfigContextMenu.UserGroup then
			if target == nil then
				AddItemOnPlayer(_src, Item, 1)
				TriggerClientEvent(Config.Trigger.TriggerNotification, _src, (NotificationContextMenu.GiveItem):format(Label))
			else
				AddItemOnPlayer(target, Item, 1)
				TriggerClientEvent(Config.Trigger.TriggerNotification, _src, (NotificationContextMenu.GiveItemToPlayer):format(Label, targetXPlayer.getName()))
				TriggerClientEvent(Config.Trigger.TriggerNotification, targetXPlayer, (NotificationContextMenu.GiveItemToPlayer2):format(Label))
			end
		else
			return ESXCustomServerUtils.rejectSuspiciousAction(src, NotificationContextMenu.MaybeCheat)
		end
	else
		return ESXCustomServerUtils.rejectSuspiciousAction(src, NotificationContextMenu.MaybeCheat)
	end
end)
RegisterServerEvent("ContextMenu:SendMessageStaff")
AddEventHandler("ContextMenu:SendMessageStaff", function(src, target, LeMessage)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)
	local name = GetPlayerName(src)
	if xPlayer.getGroup() ~= ConfigContextMenu.UserGroup then
		TriggerClientEvent(Config.Trigger.TriggerNotification, target, (NotificationContextMenu.MessageAdminOnPlayer):format(name, LeMessage))
	else
		return ESXCustomServerUtils.rejectSuspiciousAction(src, NotificationContextMenu.MaybeCheat)
	end
end)
ESX.RegisterServerCallback('ContextMenu:getVehicleInfos', function(source, cb, plate)
	MySQL.Async.fetchAll('SELECT owner FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function(result)
		local retrivedInfo = {plate = plate}

		if result[1] then
			local xPlayer = ESX.GetPlayerFromIdentifier(result[1].owner)
			MySQL.Async.fetchAll('SELECT firstname, lastname FROM users WHERE identifier = @identifier',  {
				['@identifier'] = result[1].owner
			}, function(result2)
				if result2[1] then
					retrivedInfo.owner = ('%s %s'):format(result2[1].firstname, result2[1].lastname)
					cb(retrivedInfo)
				else
					cb(retrivedInfo)
				end
			end)
		else
			cb(retrivedInfo)
		end
	end)
end)

--Copie Animation
local RequestPlayer = {}
RegisterServerEvent("ContextMenu:getAnimationTarget")
AddEventHandler("ContextMenu:getAnimationTarget", function(data)
	if data == nil or data.src == nil then
		ESXCustomServerUtils.rejectSuspiciousAction(source, "Désynchronisation avec le serveur ou Detection de Cheat")
		return
	end

	if RequestPlayer[data.src] ~= nil then
		RequestPlayer[data.src].animation = data.animation
		RequestPlayer[data.src].waiting = false
	end
end)

ESX.RegisterServerCallback('ContextMenu:getAnimation', function(source, cb, target)
	if target == nil or target == -1 then
		cb(nil)
	elseif RequestPlayer[source] ~= nil then
		cb("wait")
	else
		RequestPlayer[source] = {
			request = source,
			target = target,
			waiting = true,
			animation = nil
		}
		TriggerClientEvent("ContextMenu:getAnimationTarget", target, source)

		while RequestPlayer[source].waiting do
			Wait(200)
		end

		cb(RequestPlayer[source].animation)
		RequestPlayer[source] = nil
	end
end)