local ESX
CreateThread(function()
    while GetResourceState('es_extended') ~= 'started' do Wait(200) end
    ESX = exports['es_extended']:getSharedObject()
end)

local startedAt = os.time()

lib.callback.register('pkhub:data', function(src)
    local x = ESX and ESX.GetPlayerFromId(src); if not x then return nil end
    local accounts = {}
    for _, a in ipairs(x.getAccounts()) do
        if Config.Accounts[a.name] and (a.name ~= 'black_money' or Config.ShowBlackMoney) then accounts[#accounts + 1] = { name = a.name, label = Config.Accounts[a.name], money = a.money } end
    end
    local job = x.job or {}
    local vehicles = {}
    local ok, rows = pcall(MySQL.query.await, 'SELECT plate, vehicle FROM owned_vehicles WHERE owner = ? LIMIT 60', { x.identifier })
    if ok and rows then
        for _, r in ipairs(rows) do
            local model; local okj, p = pcall(json.decode, r.vehicle or '{}'); if okj and type(p) == 'table' then model = p.model end
            vehicles[#vehicles + 1] = { plate = r.plate, model = model }
        end
    end
    local staff = 0
    for _, id in ipairs(GetPlayers()) do
        local p = ESX.GetPlayerFromId(tonumber(id))
        if p and p.getGroup and p.getGroup() ~= 'user' then staff = staff + 1 end
    end
    return {
        name = x.getName and x.getName() or GetPlayerName(src), id = src, group = x.getGroup and x.getGroup() or 'user',
        job = { name = job.name, label = job.label, grade = job.grade_label or job.grade_name, salary = job.grade_salary or 0 },
        accounts = accounts, vehicles = vehicles,
        server = { online = #GetPlayers(), max = GetConvarInt('sv_maxclients', 64), staff = staff, uptime = os.time() - startedAt },
        rules = Config.Rules,
    }
end)
