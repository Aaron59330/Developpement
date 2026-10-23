local ESX
CreateThread(function()
    while GetResourceState('es_extended') ~= 'started' do Wait(200) end
    ESX = exports['es_extended']:getSharedObject()
end)

MySQL.ready(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS pk_heists (
        identifier VARCHAR(60) NOT NULL, heist VARCHAR(40) NOT NULL,
        done LONGTEXT NULL, finales INT NOT NULL DEFAULT 0, last_finale INT NOT NULL DEFAULT 0,
        PRIMARY KEY (identifier, heist))]])
end)

local crews, inCrew, invites = {}, {}, {}   -- crews[leader] = { leader, members, heist, diff, progress, run }

local function ident(src)
    local x = ESX and ESX.GetPlayerFromId(src)
    return x and x.identifier
end

local function missionById(heist, id)
    local h = Heists[heist]; if not h then return end
    for _, m in ipairs(h.missions) do if m.id == id then return m end end
end

local function loadProgress(src, heist)
    local id = ident(src); if not id then return { done = {}, finales = 0, last = 0 } end
    local r = MySQL.single.await('SELECT done, finales, last_finale FROM pk_heists WHERE identifier = ? AND heist = ?', { id, heist })
    local done = {}
    if r and r.done then local ok, t = pcall(json.decode, r.done); if ok and type(t) == 'table' then done = t end end
    return { done = done, finales = r and r.finales or 0, last = r and r.last_finale or 0 }
end

local function saveProgress(src, heist, p)
    local id = ident(src); if not id then return end
    MySQL.query('INSERT INTO pk_heists (identifier, heist, done, finales, last_finale) VALUES (?,?,?,?,?) ON DUPLICATE KEY UPDATE done = VALUES(done), finales = VALUES(finales), last_finale = VALUES(last_finale)',
        { id, heist, json.encode(p.done), p.finales, p.last })
end

local function crewOf(src) local l = inCrew[src]; return l and crews[l] end
local function notify(src, msg, typ) TriggerClientEvent('ox_lib:notify', src, { title = 'Braquage', description = msg, type = typ or 'inform' }) end
local function broadcast(c, ev, ...) for _, m in ipairs(c.members) do TriggerClientEvent(ev, m, ...) end end

local function cooldownLeft(p)
    local left = (p.last + Config.Cooldown * 60) - os.time()
    return left > 0 and left or 0
end

local function policeCount()
    local n = 0
    for _, id in ipairs(GetPlayers()) do
        local x = ESX and ESX.GetPlayerFromId(tonumber(id))
        if x then for _, j in ipairs(Config.PoliceJobs) do if x.job and x.job.name == j then n = n + 1 end end end
    end
    return n
end

local function status(c, m)
    if c.progress.done[m.id] then return 'done' end
    for _, r in ipairs(m.requires or {}) do if not c.progress.done[r] then return 'locked' end end
    return 'ready'
end

local function snapshot(src)
    local c = crewOf(src)
    local out = { inCrew = false, heists = {} }
    for hid, h in pairs(Heists) do out.heists[#out.heists + 1] = { id = hid, label = h.label, act = h.act, brief = h.brief, elite = h.elite } end
    if not c then return out end
    local h = Heists[c.heist]
    out.inCrew = true; out.leader = c.leader == src; out.heist = c.heist; out.difficulty = c.diff
    out.min, out.max = Config.Crew.min, Config.Crew.max
    out.payout, out.mult = Config.Difficulty[c.diff].payout, Config.PayoutMultiplier
    out.cooldown = cooldownLeft(c.progress)
    out.finales = c.progress.finales
    out.running = c.run and c.run.mission or nil
    out.crew = {}
    for _, m in ipairs(c.members) do
        local x = ESX and ESX.GetPlayerFromId(m)
        out.crew[#out.crew + 1] = { id = m, name = x and x.getName and x.getName() or GetPlayerName(m), leader = m == c.leader, team = c.run and c.run.teams[m] or nil }
    end
    out.missions = {}
    for _, m in ipairs(h.missions) do
        local teams
        if m.teams then teams = {}; for k, t in pairs(m.teams) do teams[#teams + 1] = { id = k, label = t.label, steps = #t.steps } end; table.sort(teams, function(a, b) return a.id > b.id end) end
        local steps = {}
        for _, s in ipairs(m.steps or {}) do steps[#steps + 1] = s.label end
        if m.teams then for k, t in pairs(m.teams) do local l = {}; for _, s in ipairs(t.steps) do l[#l + 1] = s.label end; steps[k] = l end end
        out.missions[#out.missions + 1] = { id = m.id, kind = m.kind, label = m.label, brief = m.brief, players = m.players, teamed = m.teamed or false, teams = teams,
            steps = steps, requires = m.requires or {}, status = status(c, m), finale = m.finale or false }
    end
    return out
end

local function pushState(c) for _, m in ipairs(c.members) do TriggerClientEvent('pkh:state', m, snapshot(m)) end end

local function dropFromCrew(src, silent)
    local l = inCrew[src]; local c = l and crews[l]; inCrew[src] = nil
    if not c then return end
    if c.leader == src then
        for _, m in ipairs(c.members) do inCrew[m] = nil; if m ~= src then notify(m, 'Le chef a dissous l’équipe.', 'warning') end; TriggerClientEvent('pkh:end', m, 'abort'); TriggerClientEvent('pkh:state', m, snapshot(m)) end
        crews[l] = nil
    else
        for i, m in ipairs(c.members) do if m == src then table.remove(c.members, i) break end end
        if c.run then c.run.teams[src] = nil; c.run.done[src] = nil end
        TriggerClientEvent('pkh:end', src, 'abort')
        pushState(c)
    end
    if not silent then TriggerClientEvent('pkh:state', src, snapshot(src)) end
end

AddEventHandler('playerDropped', function() local s = source; dropFromCrew(s, true); invites[s] = nil end)

lib.callback.register('pkh:state', function(src) return snapshot(src) end)

lib.callback.register('pkh:create', function(src, heist)
    if not Heists[heist] then return false end
    if inCrew[src] then return false end
    crews[src] = { leader = src, members = { src }, heist = heist, diff = 'normal', progress = loadProgress(src, heist) }
    inCrew[src] = src
    return snapshot(src)
end)

lib.callback.register('pkh:leave', function(src) dropFromCrew(src); return true end)

lib.callback.register('pkh:invite', function(src, target)
    target = tonumber(target)
    local c = crewOf(src); if not c or c.leader ~= src or c.run then return false, 'Action impossible.' end
    if not target or target == src or not GetPlayerName(target) then return false, 'Joueur introuvable.' end
    if inCrew[target] then return false, 'Ce joueur est déjà dans une équipe.' end
    if #c.members >= Config.Crew.max then return false, 'Équipe complète.' end
    local a, b = GetEntityCoords(GetPlayerPed(src)), GetEntityCoords(GetPlayerPed(target))
    if #(a - b) > Config.InviteDistance then return false, 'Joueur trop loin.' end
    invites[target] = src
    TriggerClientEvent('pkh:invited', target, src, GetPlayerName(src), Heists[c.heist].label)
    return true
end)

RegisterNetEvent('pkh:accept', function()
    local src = source; local l = invites[src]; invites[src] = nil
    local c = l and crews[l]; if not c or c.run or inCrew[src] or #c.members >= Config.Crew.max then return end
    c.members[#c.members + 1] = src; inCrew[src] = l
    pushState(c)
end)

lib.callback.register('pkh:difficulty', function(src, d)
    local c = crewOf(src); if not c or c.leader ~= src or c.run or not Config.Difficulty[d] then return false end
    c.diff = d; pushState(c); return true
end)

local function assignTeams(c, m)
    local teams, names = {}, {}
    for k in pairs(m.teams) do names[#names + 1] = k end
    table.sort(names, function(a, b) return a > b end)        -- ordre stable (finale : sub, air)
    for i, s in ipairs(c.members) do teams[s] = names[((i - 1) % #names) + 1] end
    return teams
end

lib.callback.register('pkh:start', function(src, missionId)
    local c = crewOf(src); if not c or c.leader ~= src then return false, 'Seul le chef peut lancer.' end
    if c.run then return false, 'Une mission est déjà en cours.' end
    local m = missionById(c.heist, missionId); if not m then return false end
    local st = status(c, m)
    if st == 'locked' then return false, 'Mission verrouillée : terminez les préalables.' end
    if st == 'done' then return false, 'Déjà terminée.' end
    local minP = m.finale and Config.Crew.min or math.max(m.players and m.players[1] or 1, Config.PrepMinPlayers)
    if #c.members < minP then return false, ('Il faut au moins %d joueurs.'):format(minP) end
    if m.finale then
        local left = cooldownLeft(c.progress)
        if left > 0 then return false, ('Prochain finale dans %d min.'):format(math.ceil(left / 60)) end
        if Config.MinPolice > 0 and policeCount() < Config.MinPolice then return false, 'Pas assez de policiers en ville.' end
    end
    local teams = m.teams and assignTeams(c, m) or {}
    if m.teams then                                               -- chaque équipe doit avoir au moins un joueur
        local used = {}; for _, t in pairs(teams) do used[t] = true end
        for k in pairs(m.teams) do if not used[k] then return false, 'Il faut au moins un joueur par équipe (' .. m.teams[k].label .. ').' end end
    end
    c.run = { mission = m.id, teams = teams, done = {}, t0 = os.time(), deaths = 0 }
    for _, s in ipairs(c.members) do
        TriggerClientEvent('pkh:begin', s, { heist = c.heist, mission = m.id, team = teams[s], diff = c.diff, t0 = c.run.t0, crew = #c.members })
    end
    pushState(c)
    return true
end)

local function finish(c, ok, reason)
    local run = c.run; c.run = nil
    if not run then return end
    local m = missionById(c.heist, run.mission)
    if not ok then
        broadcast(c, 'pkh:end', reason or 'fail'); pushState(c); return
    end
    c.progress.done[m.id] = true
    if m.finale then
        local d = Config.Difficulty[c.diff]
        local total = d.payout * Config.PayoutMultiplier
        local elapsed = os.time() - run.t0
        local el = Heists[c.heist].elite
        local elite = el and elapsed <= el.time and (not el.noDeaths or run.deaths == 0)
        if elite then total = total * (1 + Config.EliteBonus) end
        local n = #c.members
        local cut = total * Config.LeaderCut
        local each = math.floor((total - cut) / n)
        for _, s in ipairs(c.members) do
            local x = ESX and ESX.GetPlayerFromId(s)
            if x then
                local amt = each + (s == c.leader and math.floor(cut) or 0)
                x.addAccountMoney(Config.PayoutAccount, amt, 'Braquage ' .. c.heist)
                notify(s, ('Braquage réussi ! Vous recevez %s $%s'):format(amt, elite and ' (bonus Élite)' or ''), 'success')
            end
        end
        c.progress.done = {}; c.progress.finales = c.progress.finales + 1; c.progress.last = os.time()
    end
    saveProgress(c.leader, c.heist, c.progress)
    broadcast(c, 'pkh:end', m.finale and 'finale' or 'success')
    pushState(c)
end

RegisterNetEvent('pkh:teamDone', function()
    local src = source; local c = crewOf(src); if not c or not c.run then return end
    c.run.done[src] = true
    local m = missionById(c.heist, c.run.mission)
    if m.teams then
        local doneTeams, need = {}, 0
        for s in pairs(c.run.done) do doneTeams[c.run.teams[s]] = true end
        for k in pairs(m.teams) do need = need + 1; if not doneTeams[k] then return end end
    end
    finish(c, true)
end)

RegisterNetEvent('pkh:death', function() local c = crewOf(source); if c and c.run then c.run.deaths = c.run.deaths + 1 end end)

RegisterNetEvent('pkh:abort', function(reason)
    local src = source; local c = crewOf(src); if not c or not c.run then return end
    if c.leader ~= src and reason ~= 'wiped' then return end
    finish(c, false, reason == 'wiped' and 'wiped' or 'abort')
end)

RegisterNetEvent('pkh:sync', function(ev, payload)           -- relais entre membres d'une équipe (ex. étape terminée)
    local src = source; local c = crewOf(src); if not c or not c.run then return end
    for _, s in ipairs(c.members) do if s ~= src then TriggerClientEvent('pkh:sync', s, src, ev, payload) end end
end)

lib.addCommand('heistreset', { help = 'Réinitialise le braquage d’un joueur (staff)', params = { { name = 'id', type = 'playerId' } }, restricted = 'group.admin' }, function(src, args)
    local id = ident(args.id); if not id then return end
    MySQL.query('DELETE FROM pk_heists WHERE identifier = ?', { id })
    local c = crewOf(args.id); if c then c.progress = { done = {}, finales = 0, last = 0 }; pushState(c) end
end)
