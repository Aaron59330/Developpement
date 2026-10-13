ESXCustom_Function_ServerSide = {}

function ESXCustom_Function_ServerSide:getLicense(src)
    for k,v in pairs(GetPlayerIdentifiers(src))do
        if string.sub(v, 1, string.len("license:")) == "license:" then
            return v
        end
    end
end

ESX.RegisterServerCallback("esx_custom:checkMoney", function(source, cb, checker)
    VerifyToken(source, function()
        if GetMoney(source) >= tonumber(checker) then
            cb(true)
        else
            cb(false)
        end
    end)
end)

ESX.RegisterServerCallback("esx_custom:getItemAmount", function(source, cb, item)
    VerifyToken(source, function()
        local quantity = ESX.GetPlayerFromId(source).getInventoryItem(item).count
        cb(quantity)
    end)
end)

function ESXCustom_Function_ServerSide:sendToDiscord(titre, desc, webhook)
    local date = os.date("*t")
    if date.day < 10 then date.day = '0' .. tostring(date.day) end
    if date.month < 10 then date.month = '0' .. tostring(date.month) end
    if date.hour < 10 then date.hour = '0' .. tostring(date.hour) end
    if date.min < 10 then date.min = '0' .. tostring(date.min) end
    if date.sec < 10 then date.sec = '0' .. tostring(date.sec) end

    local embed = {
        {
            ["color"] = 8421504,
            ["title"] = titre,
            ["description"] = desc,
            ["footer"] = {
                ["text"] = ("%s/%s/%s à %sh%sm %ss"):format(date.day, date.month, date.year, date.hour, date.min, date.sec),
                ["icon_url"] = nil
            }
        }
    }
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({username = "Logs", embeds = embed}), { ['Content-Type'] = 'application/json' })
end

ESX.RegisterServerCallback("esx_custom:CountCops", function(source, cb, item)
    VerifyToken(source, function()
        cb(ESXCustom_Function_ServerSide:CountCops())
    end)
end)

function ESXCustom_Function_ServerSide:CountCops()
    return #ESXCustomServerUtils.GetInfoByJobsName.Police
end

function ESXCustom_Function_ServerSide:RefreshJobs()
    local TableJobs2 = {}
	Wait(2000)
	MySQL.Async.fetchAll('SELECT * FROM jobs', {}, function(jobs2)
		for k,v in ipairs(jobs2) do
			TableJobs2[v.name] = v
			TableJobs2[v.name].grades = {}
		end

		MySQL.Async.fetchAll('SELECT * FROM job_grades', {}, function(job2Grades)
			for k,v in ipairs(job2Grades) do
				if TableJobs2[v.job_name] then
					TableJobs2[v.job_name].grades[tostring(v.grade)] = v
				end
			end

			for k2,v2 in pairs(TableJobs2) do
				if ESX.Table.SizeOf(v2.grades) == 0 then
					TableJobs2[v2.name] = nil
				end
			end
		end)
	end)
	Wait(2000)
	TriggerEvent("esx_custom:refreshJobs", TableJobs2)
end