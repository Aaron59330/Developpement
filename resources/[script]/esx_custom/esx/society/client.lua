local base64MoneyIcon = ''

Citizen.CreateThread(function()
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	while ESX.GetPlayerData().job2 == nil do
		Citizen.Wait(10)
	end

	ESX.PlayerData = ESX.GetPlayerData()

	-- RefreshBussHUD()
	-- RefreshBussHUD2()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
	RefreshBussHUD()
end)


function RefreshBussHUD()
    DisableSocietyMoneyHUDElement()

    if ESX.PlayerData.job.grade_name == 'boss' then
        EnableSocietyMoneyHUDElement()

        ESX.TriggerServerCallback('esx_society:getSocietyMoney', function(money)
            UpdateSocietyMoneyHUDElement(money)
			Account = money
        end, ESX.PlayerData.job.name)
    end
end


RegisterNetEvent('esx_addonaccount:setMoney')
AddEventHandler('esx_addonaccount:setMoney', function(society, money)
	if (ESX.PlayerData.job and ESX.PlayerData.job.grade_name == 'boss' and 'society_' .. ESX.PlayerData.job.name == society) or (ESX.PlayerData.job2 and ESX.PlayerData.job2.grade_name == 'boss' and 'society_' .. ESX.PlayerData.job2.name == society) then
		UpdateSocietyMoneyHUDElement(money)
	end
end)

function EnableSocietyMoneyHUDElement()
	local societyMoneyHUDElementTpl = '' .. base64MoneyIcon .. ''

	if ESX.GetConfig().EnableHud then
		ESX.UI.HUD.RegisterElement('society_money', 3, 0, societyMoneyHUDElementTpl, {
			money = 0
		})
	end

	TriggerEvent('esx_society:toggleSocietyHud', true)
end

function DisableSocietyMoneyHUDElement()
	if ESX.GetConfig().EnableHud then
		ESX.UI.HUD.RemoveElement('society_money')
	end

	TriggerEvent('esx_society:toggleSocietyHud', false)
end

function UpdateSocietyMoneyHUDElement(money)
	if ESX.GetConfig().EnableHud then
		ESX.UI.HUD.UpdateElement('society_money', {
			money = ESX.Math.GroupDigits(money)
		})
	end

	TriggerEvent('esx_society:setSocietyMoney', money)
end

function OpenBossMenuSociety(society, close, options)
	local isBoss = nil
	local options  = options or {}
	local elements = {}

	ESX.TriggerServerCallback('esx_society:isBoss', function(result)
		isBoss = result
	end, society)

	while isBoss == nil do
		Citizen.Wait(100)
	end

	if not isBoss then
		return
	end

	local defaultOptions = {
		withdraw  = true,
		deposit   = true,
		wash      = false,
		employees = true,
		grades    = true
	}

	for k,v in pairs(defaultOptions) do
		if options[k] == nil then
			options[k] = v
		end
	end

	if options.withdraw then
		table.insert(elements, {label = 'Retirer argent société', value = 'withdraw_society_money'})
	end

	if options.deposit then
		table.insert(elements, {label = 'Déposer argent société', value = 'deposit_money'})
	end

	if options.wash then
		table.insert(elements, {label = 'Blanchir argent', value = 'wash_money'})
	end

	if options.employees then
		table.insert(elements, {label = 'Gestion employés', value = 'manage_employees'})
	end

	if options.grades then
		table.insert(elements, {label = 'Gestion salaires', value = 'manage_grades'})
	end

	local menuPrincipal = RageUI.CreateMenu("Menu boss", "Argent entreprise : ~r~"..Account.."$")

	RageUI.Visible(menuPrincipal, not RageUI.Visible(menuPrincipal))

	while menuPrincipal do
        Citizen.Wait(0)
		RageUI.IsVisible(menuPrincipal, true, true, true, function()
			for k, v in pairs(elements) do
				RageUI.ButtonWithStyle(v.label, nil, { RightLabel = "→→" }, true, function(_,_,s)
					if s then
						if v.value == "withdraw_society_money" then
							local check, amount = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput("Combien voulez-vous déposer ?", 10))
							if check then
								if tonumber(amount) > Account then
									ESX.ShowNotification("Pas assez d'argent dans l'entreprise.")
								else
									TriggerServerEvent('esx_society:withdrawMoney1', society, tonumber(amount))
									RageUI.CloseAll()
								end
							else
								ESX.ShowNotification("Montant invalide.")
							end
						elseif v.value == "deposit_money" then
							local check, amount = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput("Combien voulez-vous déposer ?", 10))
							if check then
								-- if tonumber(amount) > Account then
								-- 	ESX.ShowNotification("~r~Vous n'avez pas les fonds nécéssaires.~s~")
								-- else
									TriggerServerEvent('esx_society:depositMoney1', society, tonumber(amount))
									RageUI.CloseAll()
								-- end
							else
								ESX.ShowNotification("Montant invalide.")
							end
						elseif v.value == "wash_money" then
							local check, amount = ESXCustom_Function_ClientSide:CheckQuantity(ESXCustom_Function_ClientSide:KeyboardInput("Combien voulez-vous déposer ?", 10))
							if check then
								if tonumber(amount) > Account then
									ESX.ShowNotification("~r~Vous n'avez pas les fonds nécéssaires.~s~")
								else
									TriggerServerEvent('esx_society:washMoney1', society, tonumber(amount))
									RageUI.CloseAll()
								end
							else
								ESX.ShowNotification("Montant invalide.")
							end
						elseif v.value == "manage_employees" then
							RageUI.CloseAll()
							OpenManageEmployeesMenu(society)
						elseif v.value == "manage_grades" then
							RageUI.CloseAll()
							OpenManageGradesMenu(society)
						end
					end
				end)
			end
		end)
		
		if not RageUI.Visible(menuPrincipal) then
			menuPrincipal = RMenu:DeleteType('menuPrincipal', true)
		end
	end
end

function OpenManageEmployeesMenu(society)
	local menuPrincipal = RageUI.CreateMenu("Menu boss", "Que voulez-vous faire ?")

	RageUI.Visible(menuPrincipal, not RageUI.Visible(menuPrincipal))

	while menuPrincipal do
        Citizen.Wait(0)
		local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		RageUI.IsVisible(menuPrincipal, true, true, true, function()
			RageUI.ButtonWithStyle("Liste des employés", nil, { RightLabel = "→→" }, true, function(_,_,s)
				if s then
					OpenEmployeeList(society)
				end
			end)
			RageUI.ButtonWithStyle("Recruter", nil, { RightLabel = "→→" }, closestPlayer ~= -1 and closestDistance <= 3.0, function(_,_,s)
				if s then
					TriggerServerEvent("esx_custom_Society:recruit", ESX.PlayerData.job.name, GetPlayerServerId(closestPlayer))
				end
			end)
		end)
		
		if not RageUI.Visible(menuPrincipal) then
			menuPrincipal = RMenu:DeleteType('menuPrincipal', true)
		end
	end
end

local IndexFiltre = 1
function OpenEmployeeList(society)
	local employeesL = {}
	ESX.TriggerServerCallback('esx_society:getEmployees', function(employees)
		employeesL = employees
	end, society)
	local menuPrincipal = RageUI.CreateMenu("Menu boss", "Que voulez-vous faire ?")

	RageUI.Visible(menuPrincipal, not RageUI.Visible(menuPrincipal))

	while menuPrincipal do
        Citizen.Wait(0)
		RageUI.IsVisible(menuPrincipal, true, true, true, function()
			for i=1, #employeesL, 1 do
				local gradeLabel = (employeesL[i].job.grade_label == '' and employeesL[i].job.label or employeesL[i].job.grade_label)
				RageUI.List(employeesL[i].name.." (~b~"..gradeLabel.."~s~)", {"Promouvoir", "Viré"}, IndexFiltre, nil, {}, true, function(Hovered, Active, Selected, Index)
					IndexFiltre = Index

					if Selected then
						if Index == 1 then
							OpenPromoteMenu(society, employeesL[i])
						elseif Index == 2 then
							ESX.ShowNotification(('Vous avez viré %s'):format(employeesL[i].name))
							ESX.TriggerServerCallback('esx_society:setJob', function()
							end, employeesL[i].identifier, 'unemployed', 0, 'fire')
							RageUI.CloseAll()
						end
					end
				end)
			end
		end)
		
		if not RageUI.Visible(menuPrincipal) then
			menuPrincipal = RMenu:DeleteType('menuPrincipal', true)
		end
	end
end

function OpenPromoteMenu(society, employee)
	local menuPrincipal = RageUI.CreateMenu("Menu boss", "Que voulez-vous faire ?")

	RageUI.Visible(menuPrincipal, not RageUI.Visible(menuPrincipal))

	ESX.TriggerServerCallback('esx_society:getJob', function(job)
		local elements = {}
		for i=1, #job.grades, 1 do
			local gradeLabel = (job.grades[i].label == '' and job.label or job.grades[i].label)
			table.insert(elements, {
				label = gradeLabel,
				value = job.grades[i].grade,
				selected = (employee.job.grade == job.grades[i].grade)
			})
		end
	
		while menuPrincipal do
			Citizen.Wait(0)
			RageUI.IsVisible(menuPrincipal, true, true, true, function()
				for k, v in pairs(elements) do
					RageUI.ButtonWithStyle(v.label, nil, { RightLabel = "→→→" }, true, function(_,_,s)
						if s then
							ESX.ShowNotification(('Vous avez promu %s en tant que %s'):format(employee.name, v.label))
							ESX.TriggerServerCallback('esx_society:setJob', function()
								OpenEmployeeList(society)
							end, employee.identifier, society, v.value, 'promote')
						end
					end)
				end
			end)
			
			if not RageUI.Visible(menuPrincipal) then
				menuPrincipal = RMenu:DeleteType('menuPrincipal', true)
			end
		end
	end, society)
end

function OpenManageGradesMenu(society)
	ESX.TriggerServerCallback('esx_society:getJob', function(job)
		local menuPrincipal = RageUI.CreateMenu("Menu boss", "Que voulez-vous faire ?")

		RageUI.Visible(menuPrincipal, not RageUI.Visible(menuPrincipal))

		while menuPrincipal do
			Citizen.Wait(0)
			RageUI.IsVisible(menuPrincipal, true, true, true, function()
				for i=1, #job.grades, 1 do
					local gradeLabel = (job.grades[i].label == '' and job.label or job.grades[i].label)
					RageUI.ButtonWithStyle(('%s - ~g~%s~s~'):format(gradeLabel, ('%s$'):format(ESX.Math.GroupDigits(job.grades[i].salary))), nil, { RightLabel = "→→" }, true, function(_,_,s)
						if s then
							local amount = ESXCustom_Function_ClientSide:KeyboardInput("Combien voulez-vous mettre en salaire ?", 10)

							amount = tonumber(amount)
							if amount == nil then
								ESX.ShowNotification('Montant invalide')
							elseif amount > Config.MaxSalary then
								ESX.ShowNotification('Ce salaire n\'est pas autorisé')
							else
								RageUI.CloseAll()
								ESX.TriggerServerCallback('esx_society:setJobSalary', function()
									OpenManageGradesMenu(society)
								end, society, job.grades[i].grade, amount)
							end
						end
					end)
				end
			end)
			
			if not RageUI.Visible(menuPrincipal) then
				menuPrincipal = RMenu:DeleteType('menuPrincipal', true)
			end
		end
	end, society)

	-- ESX.TriggerServerCallback('esx_society:getJob', function(job)
	-- 	local elements = {}
	-- 	for i=1, #job.grades, 1 do
	-- 		local gradeLabel = (job.grades[i].label == '' and job.label or job.grades[i].label)
	-- 		table.insert(elements, {
	-- 			label = ('%s - <span style="color:green;">%s</span>'):format(gradeLabel, ('%s$'):format(ESX.Math.GroupDigits(job.grades[i].salary))),
	-- 			value = job.grades[i].grade
	-- 		})
	-- 	end
	-- 	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'manage_grades_' .. society, {
	-- 		title    = 'Gestion salaires',
	-- 		align    = 'top-left',
	-- 		elements = elements
	-- 	}, function(data, menu)
	-- 		ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'manage_grades_amount_' .. society, {
	-- 			title = 'Montant du salaire'
	-- 		}, function(data2, menu2)
	-- 			local amount = tonumber(data2.value)
	-- 			if amount == nil then
	-- 				ESX.ShowNotification('Montant invalide')
	-- 			elseif amount > Config.MaxSalary then
	-- 				ESX.ShowNotification('Ce salaire n\'est pas autorisé')
	-- 			else
	-- 				menu2.close()
	-- 				ESX.TriggerServerCallback('esx_society:setJobSalary', function()
	-- 					OpenManageGradesMenu(society)
	-- 				end, society, data.current.value, amount)
	-- 			end
	-- 		end, function(data2, menu2)
	-- 			menu2.close()
	-- 		end)
	-- 	end, function(data, menu)
	-- 		menu.close()
	-- 	end)
	-- end, society)
end

AddEventHandler('esx_society:openBossMenu1', function(society, close, options)
	RefreshBussHUD()
	OpenBossMenuSociety(society, close, options)
end)

--[[
	RegisterNetEvent('esx:setJob2')
	AddEventHandler('esx:setJob2', function(job2)
		ESX.PlayerData.job2 = job2
		RefreshBussHUD2()
	end)

	function RefreshBussHUD2()
		DisableSocietyMoneyHUDElement()

		if ESX.PlayerData.job2.grade_name == 'boss' then
			EnableSocietyMoneyHUDElement()

			ESX.TriggerServerCallback('esx_society:getSocietyMoney', function(money)
				UpdateSocietyMoneyHUDElement(money)
			Account = money
			end, ESX.PlayerData.job2.name)
		end
	end

	AddEventHandler('esx_society:openBossMenu2', function(society, close, options)
		RefreshBussHUD2()
		OpenBossMenu2(society, close, options)
	end)

	function OpenManageEmployeesMenu2(society)
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'manage_employees_' .. society, {
			title    = 'Gestion employés',
			align    = 'top-left',
			elements = {
				{label = 'Liste des employés', value = 'employee_list'}
			}
		}, function(data, menu)
			if data.current.value == 'employee_list' then
				OpenEmployeeList2(society)
			end
		end, function(data, menu)
			menu.close()
		end)
	end

	function OpenEmployeeList2(society)
		ESX.TriggerServerCallback('esx_society:getEmployees2', function(employees)
			local elements = {
				head = {'Employé', 'Grade', 'Actions'},
				rows = {}
			}
			for i=1, #employees, 1 do
				local gradeLabel = (employees[i].job2.grade_label == '' and employees[i].job2.label or employees[i].job2.grade_label)
				table.insert(elements.rows, {
					data = employees[i],
					cols = {
						employees[i].name,
						gradeLabel,
						'{{' .. 'Promouvoir' .. '|promote}} {{' .. 'Vous avez viré %s' .. '|fire}}'
					}
				})
			end
			ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'employee_list_' .. society, elements, function(data, menu)
				local employee = data.data

				if data.value == 'promote' then
					menu.close()
					OpenPromoteMenu2(society, employee)
				elseif data.value == 'fire' then
					ESX.ShowNotification(('Vous avez viré %s'):format(employee.name))

					ESX.TriggerServerCallback('esx_society:setJob2', function()
						OpenEmployeeList2(society)
					end, employee.identifier, 'unemployed2', 0, 'fire')
				end
			end, function(data, menu)
				menu.close()
				OpenManageEmployeesMenu2(society)
			end)
		end, society)
	end

	function OpenPromoteMenu2(society, employee)
		ESX.TriggerServerCallback('esx_society:getJob2', function(job2)
			local elements = {}
			for i=1, #job2.grades, 1 do
				local gradeLabel = (job2.grades[i].label == '' and job2.label or job2.grades[i].label)
				table.insert(elements, {
					label = gradeLabel,
					value = job2.grades[i].grade,
					selected = (employee.job2.grade == job2.grades[i].grade)
				})
			end
			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'promote_employee_' .. society, {
				title    = ('Promouvoir %s'):format(employee.name),
				align    = 'top-left',
				elements = elements
			}, function(data, menu)
				menu.close()
				ESX.ShowNotification(('Vous avez promu %s en tant que %s'):format(employee.name, data.current.label))
				ESX.TriggerServerCallback('esx_society:setJob2', function()
					OpenEmployeeList2(society)
				end, employee.identifier, society, data.current.value, 'promote')
			end, function(data, menu)
				menu.close()
				OpenEmployeeList2(society)
			end)
		end, society)
	end

	function OpenBossMenu2(society, close, options)
		local isBoss = nil
		local options  = options or {}
		local elements = {}
		ESX.TriggerServerCallback('esx_society:isBoss2', function(result)
			isBoss = result
		end, society)
		while isBoss == nil do
			Citizen.Wait(100)
		end
		if not isBoss then
			return
		end
		local defaultOptions = {
			withdraw  = true,
			deposit   = true,
			employees = true,
		}
		for k,v in pairs(defaultOptions) do
			if options[k] == nil then
				options[k] = v
			end
		end
		if options.withdraw then
			table.insert(elements, {label = 'Retirer argent société', value = 'withdraw_society_money'})
		end
		if options.deposit then
			table.insert(elements, {label = 'Déposer argent société', value = 'deposit_money'})
		end
		if options.employees then
			table.insert(elements, {label = 'Gestion employés', value = 'manage_employees'})
		end
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'boss_actions_' .. society, {
			title    = ('Mon entreprise : ~r~'.. society .. ' ~s~Mon argent : ~r~$ ' .. Account),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			if data.current.value == 'withdraw_society_money' then
				ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'withdraw_society_money_amount_' .. society, {
					title = 'Montant du retrait'
				}, function(data, menu)
					local amount = tonumber(data.value)
					if amount == nil then
						ESX.ShowNotification('Montant invalide')
					else
						menu.close()
						TriggerServerEvent('esx_society:withdrawMoney2', society, amount)
					end
				end, function(data, menu)
					menu.close()
				end)
			elseif data.current.value == 'deposit_money' then
				ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'deposit_money_amount_' .. society, {
					title = 'Montant du dépôt'
				}, function(data, menu)
					local amount = tonumber(data.value)
					if amount == nil then
						ESX.ShowNotification('Montant invalide')
					else
						menu.close()
						TriggerServerEvent('esx_society:depositMoney2', society, amount)
					end
				end, function(data, menu)
					menu.close()
				end)
			elseif data.current.value == 'manage_employees' then
				OpenManageEmployeesMenu2(society)
			end
		end, function(data, menu)
			if close then
				close(data, menu)
			end
		end)
	end
--]]

RegisterNetEvent("esx_custom_Society:recruit")
AddEventHandler("esx_custom_Society:recruit", function(sender, job)
	ESX.ShowNotification("Vous avez été invité à rejoindre l'entreprise ~b~"..job.."~s~.\n\nApppuyez sur ~g~Y~s~ pour accepter.\nAppuyez sur ~r~N~s~ pour refuser.")

    local time = 0
    activeMess = true

    while activeMess do
        time = time + 10
        if IsControlJustPressed(0, 246) then
            TriggerServerEvent("esx_custom_Society:recruit2", "accept", job, sender)
            activeMess = false
            break
        end
        if IsControlJustPressed(0, 306) then
            TriggerServerEvent("esx_custom_Society:recruit2", "decline", job, sender)
            activeMess = false
            break
        end
        if time == 10000 then
            TriggerServerEvent("esx_custom_Society:recruit2", "passed", job, sender)
            activeMess = false
            break
        end
        Wait(1)
    end
end)