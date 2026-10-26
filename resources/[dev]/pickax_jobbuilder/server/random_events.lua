-- Événements aléatoires liés aux métiers (voir config_events.lua)
local R = Config.RandomEvents
local Active, nextId = {}, 0
local function now() return os.time() end

local function jobTypeOf(src)
    local x = ESX.GetPlayerFromId(src)
    local job = x and JB.Jobs[x.job.name]
    return job and job.type or nil, x
end

local function eligible(def, src)
    if not JB.isOnDuty(src) then return false end
    local t = jobTypeOf(src)
    if not t then return false end
    for _, jt in ipairs(def.jobTypes) do if jt == t then return true end end
    return false
end

local function workers(def)
    local list = {}
    for _, id in ipairs(ESX.GetPlayers()) do if eligible(def, id) then list[#list + 1] = id end end
    return list
end

local function activeCount() local n = 0 for _ in pairs(Active) do n = n + 1 end return n end

local function start(key, forced)
    local def = R.Events[key]
    if not def or not R.Locations or #R.Locations == 0 then return false, 'Événement ou lieux introuvables' end
    local ws = workers(def)
    if #ws < (forced and 1 or R.MinWorkers) then return false, 'Personne en service pour cet événement' end
    nextId = nextId + 1
    local loc = R.Locations[math.random(#R.Locations)]
    local ev = { id = nextId, key = key, def = def, loc = loc, expires = now() + (def.timeout or 900), claimed = false, workers = {} }
    for _, w in ipairs(ws) do ev.workers[w] = true end
    Active[ev.id] = ev
    local payload = { id = ev.id, key = key, label = def.label, visual = def.visual, x = loc.x, y = loc.y, z = loc.z, h = loc.h or 0.0, place = loc.label,
        interact = def.interact, progress = def.progress, seconds = def.seconds, models = def.models, ped = def.ped, props = def.props, timeout = def.timeout or 900 }
    for _, w in ipairs(ws) do
        TriggerClientEvent('jb:re:start', w, payload)
        JBNotifyClient(w, (def.announce):format(loc.label))
    end
    return true, ev.id
end

local function finish(id, reason, winner)
    local ev = Active[id]
    if not ev then return end
    Active[id] = nil
    for w in pairs(ev.workers) do TriggerClientEvent('jb:re:end', w, { id = id, reason = reason, winner = winner }) end
end

RegisterNetEvent('jb:re:claim', function(id)
    local src = source
    local ev = Active[tonumber(id)]
    if not ev then return JBNotifyClient(src, '~r~Cet événement est terminé.') end
    if ev.claimed then return JBNotifyClient(src, '~o~Un collègue s\'en est déjà chargé.') end
    if not eligible(ev.def, src) then return end
    local ped = GetPlayerPed(src)
    local p = GetEntityCoords(ped)
    if #(p - vector3(ev.loc.x, ev.loc.y, ev.loc.z)) > R.ClaimDistance then return JBNotifyClient(src, '~r~Tu es trop loin de l\'incident.') end
    ev.claimed = true    -- le premier arrivé l'emporte (un seul claim possible)
    local def = ev.def
    local base = math.random(def.reward[1], def.reward[2])
    local x = ESX.GetPlayerFromId(src)
    local paid = base
    if def.jobKey and AJ and AJ.pay then
        paid = AJ.pay(src, def.jobKey, base, def.xp or 0, def.label, 1)
    elseif x then
        x.addAccountMoney(R.Account, base, def.label)
        if GetResourceState('pickax_carnet') == 'started' then pcall(function() exports.pickax_carnet:Report(src, 'job_task', 1) exports.pickax_carnet:Report(src, 'earn', base) end) end
    end
    JBNotifyClient(src, ('~g~%s terminé !~s~ Récompense : ~g~%d$'):format(def.label, paid))
    local name = x and ((x.get and x.get('firstName')) or x.getName()) or 'un collègue'
    finish(ev.id, 'done', name)
    if JB.log and x then JB.log(x.job.name, x, 'random_event', ('%s : +%d$'):format(def.label, paid)) end
end)

-- Planification
CreateThread(function()
    Wait(60000)
    while true do
        local iv = R.Interval
        Wait(math.random(iv[1], iv[2]) * 1000)
        if R.Enabled and activeCount() < R.MaxActive then
            local keys = {}
            for k, def in pairs(R.Events) do if #workers(def) >= R.MinWorkers then keys[#keys + 1] = k end end
            if #keys > 0 then start(keys[math.random(#keys)]) end
        end
    end
end)

-- Expiration
CreateThread(function()
    while true do
        Wait(5000)
        for id, ev in pairs(Active) do if now() >= ev.expires then finish(id, 'expired') end end
    end
end)


RegisterCommand(R.AdminCommand or 'jbevent', function(src, args)
    if src ~= 0 and not (AJ and AJ.isAdmin(src)) then return end
    local key = args[1] or ''
    local ok, err = start(key, true)
    local msg = ok and ('Événement « %s » lancé'):format(key) or ('Impossible : %s'):format(tostring(err))
    if src == 0 then print('[jobbuilder] ' .. msg) else JBNotifyClient(src, msg) end
end, false)

AddEventHandler('playerDropped', function()
    local src = source
    for _, ev in pairs(Active) do ev.workers[src] = nil end
end)
