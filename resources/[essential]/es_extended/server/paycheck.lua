function StartPayCheck()
    CreateThread(function()
        while true do
            Wait(Config.PaycheckInterval)
            for player, xPlayer in pairs(ESX.Players) do
                local jobLabel = xPlayer.job.label
                local job = xPlayer.job.grade_name
                local salary = xPlayer.job.grade_salary

		        if GetResourceState(Config.CustomCore) ~= "missing" and GetResourceState(Config.CustomCore) == "started" then
                    local CheckVIP, Amount = exports[Config.CustomCore]:CheckVIP(player)
                    
                    if salary > 0 then
                        if job == 'unemployed' then -- unemployed
                            if xPlayer.vip == 0 then
                                salary = salary
                            else
                                salary = salary*Amount
                            end
                            xPlayer.addAccountMoney('bank', salary, "Welfare Check")
                            TriggerClientEvent('esx:showAdvancedNotification', player, TranslateCap('bank'), TranslateCap('received_paycheck'), TranslateCap('received_help', salary),
                            'CHAR_BANK_MAZE', 9)
                            if Config.LogPaycheck then
                            ESX.DiscordLogFields("Paycheck", "Paycheck - Unemployment Benefits", "green", {
                                { name = "Player", value = xPlayer.name,   inline = true },
                                { name = "ID",     value = xPlayer.source, inline = true },
                                { name = "Amount", value = salary,         inline = true }
                            })
                            end
                        elseif Config.EnableSocietyPayouts then -- possibly a society
                            TriggerEvent('esx_society:getSociety', xPlayer.job.name, function(society)
                            if society ~= nil then              -- verified society
                                TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
                                if account.money >= salary then -- does the society money to pay its employees?
                                    if xPlayer.vip == 0 then
                                        xPlayer.addAccountMoney('bank', salary, "Paycheck")
                                        if Config.LogPaycheck then
                                            ESX.DiscordLogFields("Paycheck", "Paycheck - " .. jobLabel, "green", {
                                                { name = "Player", value = xPlayer.name,   inline = true },
                                                { name = "ID",     value = xPlayer.source, inline = true },
                                                { name = "Amount", value = salary,         inline = true }
                                            })
                                        end
                                    else
                                        xPlayer.addAccountMoney('bank', salary*Amount, "Paycheck")
                                        if Config.LogPaycheck then
                                            ESX.DiscordLogFields("Paycheck", "Paycheck - " .. jobLabel, "green", {
                                                { name = "Player", value = xPlayer.name,   inline = true },
                                                { name = "ID",     value = xPlayer.source, inline = true },
                                                { name = "Amount", value = salary*Amount, inline = true }
                                            })
                                        end
                                    end
                                    account.removeMoney(salary)

                                    TriggerClientEvent('esx:showAdvancedNotification', player, TranslateCap('bank'), TranslateCap('received_paycheck'),
                                    TranslateCap('received_salary', salary), 'CHAR_BANK_MAZE', 9)
                                else
                                    TriggerClientEvent('esx:showAdvancedNotification', player, TranslateCap('bank'), '', TranslateCap('company_nomoney'), 'CHAR_BANK_MAZE', 1)
                                end
                                end)
                            else -- not a society
                                if xPlayer.vip == 0 then
                                    salary = salary
                                else
                                    salary = salary*Amount
                                end
                                xPlayer.addAccountMoney('bank', salary, "Paycheck")
                                if Config.LogPaycheck then
                                ESX.DiscordLogFields("Paycheck", "Paycheck - " .. jobLabel, "green", {
                                    { name = "Player", value = xPlayer.name,   inline = true },
                                    { name = "ID",     value = xPlayer.source, inline = true },
                                    { name = "Amount", value = salary,         inline = true }
                                })
                                end
                                TriggerClientEvent('esx:showAdvancedNotification', player, TranslateCap('bank'), TranslateCap('received_paycheck'), TranslateCap('received_salary', salary),
                                'CHAR_BANK_MAZE', 9)
                            end
                            end)
                        else -- generic job
                            if xPlayer.vip == 0 then
                                salary = salary
                            else
                                salary = salary*Amount
                            end
                            xPlayer.addAccountMoney('bank', salary, "Paycheck")
                            if Config.LogPaycheck then
                            ESX.DiscordLogFields("Paycheck", "Paycheck - Generic", "green", {
                                { name = "Player", value = xPlayer.name,   inline = true },
                                { name = "ID",     value = xPlayer.source, inline = true },
                                { name = "Amount", value = salary,         inline = true }
                            })
                            end
                            TriggerClientEvent('esx:showAdvancedNotification', player, TranslateCap('bank'), TranslateCap('received_paycheck'), TranslateCap('received_salary', salary),
                            'CHAR_BANK_MAZE', 9)
                        end
                    end
                else
                    if salary > 0 then
                        if job == 'unemployed' then -- unemployed
                            salary = salary
                            xPlayer.addAccountMoney('bank', salary, "Welfare Check")
                            TriggerClientEvent('esx:showAdvancedNotification', player, TranslateCap('bank'), TranslateCap('received_paycheck'), TranslateCap('received_help', salary),'CHAR_BANK_MAZE', 9)
                                if Config.LogPaycheck then
                                ESX.DiscordLogFields("Paycheck", "Paycheck - Unemployment Benefits", "green", {
                                    { name = "Player", value = xPlayer.name,   inline = true },
                                    { name = "ID",     value = xPlayer.source, inline = true },
                                    { name = "Amount", value = salary,         inline = true }
                                })
                            end
                        elseif Config.EnableSocietyPayouts then -- possibly a society
                            TriggerEvent('esx_society:getSociety', xPlayer.job.name, function(society)
                            if society ~= nil then              -- verified society
                                TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
                                    if account.money >= salary then -- does the society money to pay its employees?
                                        xPlayer.addAccountMoney('bank', salary, "Paycheck")
                                        if Config.LogPaycheck then
                                            ESX.DiscordLogFields("Paycheck", "Paycheck - " .. jobLabel, "green", {
                                                { name = "Player", value = xPlayer.name,   inline = true },
                                                { name = "ID",     value = xPlayer.source, inline = true },
                                                { name = "Amount", value = salary,         inline = true }
                                            })
                                        end
                                        account.removeMoney(salary)

                                        TriggerClientEvent('esx:showAdvancedNotification', player, TranslateCap('bank'), TranslateCap('received_paycheck'),
                                        TranslateCap('received_salary', salary), 'CHAR_BANK_MAZE', 9)
                                    else
                                        TriggerClientEvent('esx:showAdvancedNotification', player, TranslateCap('bank'), '', TranslateCap('company_nomoney'), 'CHAR_BANK_MAZE', 1)
                                    end
                                end)
                            else -- not a society
                                salary = salary
                                xPlayer.addAccountMoney('bank', salary, "Paycheck")
                                if Config.LogPaycheck then
                                ESX.DiscordLogFields("Paycheck", "Paycheck - " .. jobLabel, "green", {
                                    { name = "Player", value = xPlayer.name,   inline = true },
                                    { name = "ID",     value = xPlayer.source, inline = true },
                                    { name = "Amount", value = salary,         inline = true }
                                })
                                end
                                TriggerClientEvent('esx:showAdvancedNotification', player, TranslateCap('bank'), TranslateCap('received_paycheck'), TranslateCap('received_salary', salary),
                                'CHAR_BANK_MAZE', 9)
                            end
                            end)
                        else -- generic job
                            salary = salary
                            xPlayer.addAccountMoney('bank', salary, "Paycheck")
                            if Config.LogPaycheck then
                            ESX.DiscordLogFields("Paycheck", "Paycheck - Generic", "green", {
                                { name = "Player", value = xPlayer.name,   inline = true },
                                { name = "ID",     value = xPlayer.source, inline = true },
                                { name = "Amount", value = salary,         inline = true }
                            })
                            end
                            TriggerClientEvent('esx:showAdvancedNotification', player, TranslateCap('bank'), TranslateCap('received_paycheck'), TranslateCap('received_salary', salary),
                            'CHAR_BANK_MAZE', 9)
                        end
                    end
                end
            end
        end
    end)
end