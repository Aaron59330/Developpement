local ESX
CreateThread(function()
    while GetResourceState('es_extended') ~= 'started' do Wait(200) end
    ESX = exports['es_extended']:getSharedObject()
end)

local function hidden(n) for _, j in ipairs(Config.HideJobs) do if j == n then return true end end end

-- Entreprises et statut : depuis le Job Builder s'il tourne (jobs créés en jeu), sinon depuis les jobs ESX
lib.callback.register('pkhub:jobs', function()
    if GetResourceState('pickax_jobbuilder') == 'started' then
        local ok, list = pcall(function() return exports['pickax_jobbuilder']:GetJobsStatus() end)
        if ok and type(list) == 'table' then
            local out = {}
            for _, j in ipairs(list) do if not hidden(j.name) then out[#out + 1] = { name = j.name, label = j.label, online = j.online } end end
            return out
        end
    end
    local online, out = {}, {}
    for _, id in ipairs(GetPlayers()) do
        local p = ESX and ESX.GetPlayerFromId(tonumber(id))
        if p and p.job then online[p.job.name] = (online[p.job.name] or 0) + 1 end
    end
    for n, j in pairs(ESX and ESX.GetJobs() or {}) do
        if not hidden(n) then out[#out + 1] = { name = n, label = j.label or n, online = online[n] or 0 } end
    end
    table.sort(out, function(a, b) if (a.online > 0) ~= (b.online > 0) then return a.online > 0 end return a.label < b.label end)
    return out
end)
