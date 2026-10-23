local ESX
CreateThread(function()
    while GetResourceState('es_extended') ~= 'started' do Wait(200) end
    ESX = exports['es_extended']:getSharedObject()
end)

local startedAt = os.time()
local function hidden(n) for _, j in ipairs(Config.HideJobs) do if j == n then return true end end end

local function jobsOverview()
    local online = {}
    for _, id in ipairs(GetPlayers()) do
        local p = ESX.GetPlayerFromId(tonumber(id))
        if p and p.job then online[p.job.name] = (online[p.job.name] or 0) + 1 end
    end
    local out, all = {}, ESX.GetJobs and ESX.GetJobs() or {}
    local names = {}
    if #Config.ShowJobs > 0 then for _, n in ipairs(Config.ShowJobs) do names[#names + 1] = n end
    else for n in pairs(all) do if not hidden(n) then names[#names + 1] = n end end; table.sort(names) end
    for _, n in ipairs(names) do
        local j = all[n]
        if j then out[#out + 1] = { name = n, label = j.label or n, online = online[n] or 0 } end
        if #out >= Config.MaxJobs then break end
    end
    table.sort(out, function(a, b) if (a.online > 0) ~= (b.online > 0) then return a.online > 0 end return a.label < b.label end)
    return out
end

lib.callback.register('pkhub:data', function(src)
    local x = ESX and ESX.GetPlayerFromId(src); if not x then return nil end
    local accounts = {}
    for _, a in ipairs(x.getAccounts()) do accounts[a.name] = a.money end
    local job = x.job or {}

    local u = MySQL.single.await('SELECT firstname, lastname, sex, nationality, dateofbirth, points, boutique_id FROM users WHERE identifier = ?', { x.identifier }) or {}
    local okp, pt = pcall(MySQL.scalar.await, 'SELECT played_seconds FROM newplayer_playtime WHERE identifier = ?', { x.identifier })

    local vehicles = {}
    local ok, rows = pcall(MySQL.query.await, 'SELECT plate, vehicle FROM owned_vehicles WHERE owner = ? LIMIT 60', { x.identifier })
    if ok and rows then
        for _, r in ipairs(rows) do
            local model; local okj, p = pcall(json.decode, r.vehicle or '{}'); if okj and type(p) == 'table' then model = p.model end
            vehicles[#vehicles + 1] = { plate = r.plate, model = model }
        end
    end

    local bills = {}
    local okb, br = pcall(MySQL.query.await, 'SELECT id, sender, target_type, target, label, amount FROM billing WHERE identifier = ? ORDER BY id DESC LIMIT 40', { x.identifier })
    if okb and br then for _, b in ipairs(br) do bills[#bills + 1] = b end end

    local props
    if Config.PropertiesQuery then
        local okq, pr = pcall(MySQL.query.await, Config.PropertiesQuery, { x.identifier })
        props = okq and pr or {}
    end

    local staff = 0
    for _, id in ipairs(GetPlayers()) do
        local p = ESX.GetPlayerFromId(tonumber(id))
        if p and p.getGroup and p.getGroup() ~= 'user' then staff = staff + 1 end
    end
    return {
        name = ((u.firstname or '') .. ' ' .. (u.lastname or '')):gsub('^%s+', ''):gsub('%s+$', ''), id = src, uid = u.boutique_id, group = x.getGroup and x.getGroup() or 'user',
        sex = u.sex, nationality = u.nationality, dob = u.dateofbirth,
        playtime = okp and pt or nil, points = u.points or 0,
        job = { name = job.name, label = job.label, grade = job.grade_label or job.grade_name, salary = job.grade_salary or 0 },
        money = { cash = accounts.money or 0, bank = accounts.bank or 0, black = accounts.black_money or 0 },
        vehicles = vehicles, bills = bills, props = props, jobs = jobsOverview(),
        server = { online = #GetPlayers(), max = GetConvarInt('sv_maxclients', 64), staff = staff, uptime = os.time() - startedAt },
        rules = Config.Rules,
    }
end)

lib.callback.register('pkhub:payBill', function(src, id)
    local x = ESX and ESX.GetPlayerFromId(src); if not x then return false end
    local b = MySQL.single.await('SELECT id, target_type, target, amount FROM billing WHERE id = ? AND identifier = ?', { tonumber(id), x.identifier })
    if not b then return false, 'Facture introuvable.' end
    local acc = Config.PayBillsFrom
    if x.getAccount(acc).money < b.amount then return false, 'Fonds insuffisants.' end
    x.removeAccountMoney(acc, b.amount, 'Facture')
    if b.target_type == 'society' then
        TriggerEvent('esx_addonaccount:getSharedAccount', b.target, function(a) if a then a.addMoney(b.amount) end end)
    elseif b.target_type == 'player' then
        local t = ESX.GetPlayerFromIdentifier(b.target)
        if t then t.addAccountMoney('bank', b.amount, 'Facture reçue') else MySQL.update('UPDATE users SET accounts = JSON_SET(accounts, "$.bank", JSON_EXTRACT(accounts, "$.bank") + ?) WHERE identifier = ?', { b.amount, b.target }) end
    end
    MySQL.query('DELETE FROM billing WHERE id = ?', { b.id })
    return true
end)
