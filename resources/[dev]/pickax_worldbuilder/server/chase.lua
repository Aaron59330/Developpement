local function ECO(kind, n) if GetResourceState('pickax_economy') ~= 'started' then return n end local ok, r = pcall(function() return exports.pickax_economy:Scale(kind, n) end) return (ok and tonumber(r)) or n end   -- type d'économie du serveur (pickax_economy, optionnel)
-- ─────────────────────────────── Course poursuite (intégration de pickax_chase) ───────────────────────────────
-- Règle : si un poursuivant reste collé au fugitif (≤ catchDistance) pendant catchTime secondes, les poursuivants gagnent ;
-- si le temps est écoulé, le fugitif gagne. Détection 100 % côté serveur, partie isolée dans un routing bucket.
local C = Config.Chase
local matches, playerMatch, viewers = {}, {}, {}     -- viewers[src] = id du module consulté
local statsCache = {}
local nextId, joinCounter = 1, 0
local PICK_MS = 10000     -- fenêtre de choix du véhicule après l'arrivée d'un joueur (lancement impossible)

-- ─────────────────────────────── Données du module ───────────────────────────────
local function mapsOf(e)
    local list = {}
    for i, p in ipairs(e.points) do
        if p.kind == 'map' and p.coords then list[#list + 1] = { id = i, label = (p.label ~= '' and p.label or ('Carte ' .. i)), desc = p.desc or '', x = p.coords.x, y = p.coords.y, z = p.coords.z, h = p.coords.h or 0.0, runner = p.runner, spawns = p.spawns or {} } end
    end
    return list
end

local function vehiclesOf(e)
    local list, by = {}, {}
    for _, v in ipairs(e.settings.vehicles or {}) do
        if v.model ~= '' and not by[v.model] then by[v.model] = v list[#list + 1] = v end
    end
    return list, by
end

local function resolveDesk(src, eid, pi)
    local e = WB.Entities[tonumber(eid) or 0]
    local x = ESX.GetPlayerFromId(src)
    if not e or e.type ~= 'chase' or not e.enabled or not x then return nil, 'Introuvable' end
    local p = e.points[tonumber(pi) or 0]
    if not p or p.kind ~= 'lobby' or not p.coords or not WB.near(src, p.coords, 6.0) then return nil, 'Trop loin' end
    local ok, err = WB.hasAccess(x, e.settings.access)
    if not ok then return nil, err end
    return e, p, x
end

-- ─────────────────────────────── Statistiques ───────────────────────────────
local function getStats(identifier)
    if statsCache[identifier] then return statsCache[identifier] end
    local row = MySQL.single.await('SELECT matches, wins_runner, wins_chaser, losses FROM worldbuilder_chase_stats WHERE identifier = ?', { identifier })
    statsCache[identifier] = row or { matches = 0, wins_runner = 0, wins_chaser = 0, losses = 0 }
    return statsCache[identifier]
end

local function recordResult(identifier, name, role, won)
    local s = getStats(identifier)
    s.matches = s.matches + 1
    local wr, wc, l = 0, 0, 0
    if won then
        if role == 'runner' then wr = 1 s.wins_runner = s.wins_runner + 1 else wc = 1 s.wins_chaser = s.wins_chaser + 1 end
    else l = 1 s.losses = s.losses + 1 end
    MySQL.insert([[INSERT INTO worldbuilder_chase_stats (identifier, name, matches, wins_runner, wins_chaser, losses) VALUES (?, ?, 1, ?, ?, ?)
        ON DUPLICATE KEY UPDATE name = VALUES(name), matches = matches + 1, wins_runner = wins_runner + VALUES(wins_runner), wins_chaser = wins_chaser + VALUES(wins_chaser), losses = losses + VALUES(losses)]],
        { identifier, name, wr, wc, l })
end

-- ─────────────────────────────── Utilitaires ───────────────────────────────
local function clean(s, max, fallback)
    if type(s) ~= 'string' then return fallback end
    s = s:gsub('[%c<>]', ''):gsub('^%s+', ''):gsub('%s+$', '')
    if s == '' then return fallback end
    return s:sub(1, max)
end

local function clamp(n, lo, hi, fallback)
    n = tonumber(n)
    if not n then return fallback end
    return math.max(lo, math.min(hi, math.floor(n)))
end

local function playerName(src)
    local x = ESX.GetPlayerFromId(src)
    return x and WB.playerName(x) or GetPlayerName(src) or ('Joueur ' .. src)
end

local function countRole(m, role)
    local n = 0
    for _, p in pairs(m.players) do if p.role == role then n = n + 1 end end
    return n
end

local function memberList(m)
    local list = {}
    for src, p in pairs(m.players) do list[#list + 1] = { src = src, p = p } end
    table.sort(list, function(a, b) return a.p.order < b.p.order end)
    return list
end

local function serializeMatch(m)
    local players = {}
    for _, e in ipairs(memberList(m)) do
        players[#players + 1] = { src = e.src, name = e.p.name, role = e.p.role, vehicle = e.p.vehicle, host = (e.src == m.host) }
    end
    return { id = m.id, name = m.name, map = m.map, mapLabel = m.mapData.label, duration = m.duration, maxChasers = m.maxChasers, fee = math.floor(tonumber(m.set.entryFee) or 0), state = m.state, host = m.host,
        chasers = countRole(m, 'chaser'), runners = countRole(m, 'runner'), players = players,
        pickLeft = math.max(0, (m.pickUntil or 0) - GetGameTimer()) }
end

local function pushState(src, lobbies)
    local x = ESX.GetPlayerFromId(src)
    if not x then return end
    local id = playerMatch[src]
    local current = id and matches[id]
    local eid = current and current.eid or viewers[src]
    local mine = {}
    for _, l in ipairs(lobbies) do if l.eid == eid then mine[#mine + 1] = l.data end end
    TriggerClientEvent('worldbuilder:client:chaseState', src, { you = src, name = WB.playerName(x), lobbies = mine, current = current and serializeMatch(current) or nil, stats = getStats(x.identifier) })
end

local function broadcast()
    local lobbies = {}
    for _, m in pairs(matches) do lobbies[#lobbies + 1] = { eid = m.eid, id = m.id, data = serializeMatch(m) } end
    table.sort(lobbies, function(a, b) return a.id < b.id end)
    local targets = {}
    for src in pairs(viewers) do targets[src] = true end
    for src in pairs(playerMatch) do targets[src] = true end
    for src in pairs(targets) do pushState(src, lobbies) end
end

local function resetBucket(src)
    if GetPlayerName(src) then SetPlayerRoutingBucket(src, 0) end
end

-- Mise d'entrée : compte utilisé pour débiter / créditer
local function acct(set)
    local a = set.rewardAccount
    if a == 'cash' then a = 'money' end
    return (a == 'money' or a == 'black_money') and a or 'bank'
end

local function balanceOf(x, account)
    local a = x.getAccount(account)
    return a and a.money or 0
end

-- ─────────────────────────────── Fin de partie ───────────────────────────────
local function cleanupMatch(m)
    local members = memberList(m)
    for _, e in ipairs(members) do
        if playerMatch[e.src] == m.id then TriggerClientEvent('worldbuilder:client:chaseCleanup', e.src) end
    end
    Wait(1500)
    for _, e in ipairs(members) do
        if playerMatch[e.src] == m.id then playerMatch[e.src] = nil resetBucket(e.src) end
    end
    matches[m.id] = nil
    broadcast()
end

local function endMatch(m, winner, reason, winnerSrc)
    if m.state == 'ended' then return end
    m.state = 'ended'
    local elapsed = m.startedAt and (GetGameTimer() - m.startedAt) or 0
    local winnerName = winnerSrc and m.players[winnerSrc] and m.players[winnerSrc].name or nil
    local e = WB.Entities[m.eid]
    -- gains : les gagnants se partagent toutes les mises (+ bonus serveur) ; les perdants perdent la leur ; annulée = remboursement
    local account = acct(m.set)
    local winners = 0
    for _, p in pairs(m.players) do
        if (winner == 'runner' and p.role == 'runner') or (winner == 'chasers' and p.role == 'chaser') then winners = winners + 1 end
    end
    local share = (winners > 0 and m.pot or 0) > 0 and math.floor(m.pot / winners) or 0
    for src, p in pairs(m.players) do
        local won = (winner == 'runner' and p.role == 'runner') or (winner == 'chasers' and p.role == 'chaser')
        local x = ESX.GetPlayerFromId(src)
        local reward, lost = 0, 0
        if winner == 'none' then
            reward = m.paid[src] and m.fee or 0                        -- remboursement
        elseif won then
            reward = share + (m.set.rewardWin or 0)
        else
            lost = m.paid[src] and m.fee or 0
        end
        if x then
            if reward > 0 then x.addAccountMoney(account, ECO('income', reward), 'Course poursuite') end
            if winner ~= 'none' then recordResult(x.identifier, p.name, p.role, won) end
        end
        TriggerClientEvent('worldbuilder:client:chaseFinish', src, { winner = winner, won = won, reason = reason, reward = reward, lost = lost, fee = m.fee, elapsed = elapsed, winnerName = winnerName, delay = C.EndDelay })
    end
    if e then WB.stat(e, 'matches', 1) WB.log(e, nil, 'chase_end', ('%s — %s'):format(m.name, winner)) end
    broadcast()
    CreateThread(function()
        Wait(C.EndDelay * 1000)
        cleanupMatch(m)
    end)
end

local function removePlayer(src, dropped)
    local id = playerMatch[src]
    local m = id and matches[id]
    playerMatch[src] = nil
    if not m then return end
    local leaver = m.players[src]
    m.players[src] = nil
    m.contact[src] = nil
    if not dropped and m.state ~= 'lobby' then
        TriggerClientEvent('worldbuilder:client:chaseCleanup', src)
        SetTimeout(1500, function() resetBucket(src) end)
    elseif not dropped then
        resetBucket(src)
    end
    if m.state == 'lobby' then
        if next(m.players) == nil then matches[m.id] = nil
        elseif m.host == src then m.host = memberList(m)[1].src end
    elseif m.state ~= 'ended' and leaver then
        if leaver.role == 'runner' then endMatch(m, 'chasers', 'Le fugitif a abandonné la course.')
        elseif countRole(m, 'chaser') == 0 then endMatch(m, 'runner', 'Tous les poursuivants ont abandonné.') end
    end
    broadcast()
end

-- ─────────────────────────────── Déroulement ───────────────────────────────
local function spawnFor(m, src)
    local s = m.mapData
    local h = math.rad(s.h)
    local fx, fy = -math.sin(h), math.cos(h)
    local rx, ry = math.cos(h), math.sin(h)
    local p = m.players[src]
    local function at(c) return { x = c.x, y = c.y, z = c.z, h = c.h or s.h } end
    if p.role == 'runner' then return (s.runner and s.runner.x) and at(s.runner) or { x = s.x, y = s.y, z = s.z, h = s.h } end
    local idx = p.chaserIndex or 1
    -- positions des poursuivants configurées sur la carte (sinon placement automatique derrière le fugitif)
    local cs = s.spawns or {}
    if #cs > 0 then return at(cs[((idx - 1) % #cs) + 1]) end
    local back = 10.0 + 7.0 * math.ceil(idx / 2)
    local side = (idx % 2 == 0) and 3.0 or -3.0
    return { x = s.x - fx * back + rx * side, y = s.y - fy * back + ry * side, z = s.z, h = s.h }
end

local function allReady(m)
    for src in pairs(m.players) do if not m.ready[src] then return false end end
    return true
end

local function runMatch(m)
    m.state = 'prepare'
    m.ready, m.contact = {}, {}
    m.bucket = C.BucketBase + m.id
    SetRoutingBucketPopulationEnabled(m.bucket, m.set.traffic == true)
    local idx = 0
    for _, e in ipairs(memberList(m)) do
        if e.p.role == 'chaser' then idx = idx + 1 e.p.chaserIndex = idx end
        if not m.vehicleBy[e.p.vehicle] and m.vehicles[1] then e.p.vehicle = m.vehicles[1].model end
    end
    for src, p in pairs(m.players) do
        SetPlayerRoutingBucket(src, m.bucket)
        TriggerClientEvent('worldbuilder:client:chasePrepare', src, { role = p.role, model = p.vehicle, spawn = spawnFor(m, src), maxPerformance = m.set.maxPerformance == true })
    end
    broadcast()
    local t = GetGameTimer()
    while m.state == 'prepare' and not allReady(m) and GetGameTimer() - t < C.PrepareTimeout * 1000 do Wait(250) end
    if m.state ~= 'prepare' then return end

    m.state = 'countdown'
    for src in pairs(m.players) do TriggerClientEvent('worldbuilder:client:chaseCountdown', src, m.set.countdown) end
    broadcast()
    Wait(m.set.countdown * 1000)
    if m.state ~= 'countdown' then return end

    m.state = 'running'
    m.startedAt = GetGameTimer()
    m.endsAt = m.startedAt + m.duration * 60000
    m.contactFrom = m.startedAt + m.set.headStart * 1000
    for src, p in pairs(m.players) do
        TriggerClientEvent('worldbuilder:client:chaseGo', src, { role = p.role, release = (p.role == 'runner'), headStart = m.set.headStart, catchTime = m.set.catchTime * 1000 })
    end
    broadcast()
    Wait(m.set.headStart * 1000)
    if m.state ~= 'running' then return end
    for src, p in pairs(m.players) do
        if p.role == 'chaser' then TriggerClientEvent('worldbuilder:client:chaseRelease', src) end
    end
end

local function tickMatch(m, now, dt, sendUi)
    if now >= m.endsAt then return endMatch(m, 'runner', 'Le temps est écoulé : le fugitif a survécu !') end
    -- un joueur qui sort de son véhicule annule la course (aucune récompense)
    m.outFor = m.outFor or {}
    if now - m.startedAt > 3000 then
        for src, p in pairs(m.players) do
            local ped = GetPlayerPed(src)
            if ped and ped ~= 0 then
                if GetVehiclePedIsIn(ped, false) == 0 then
                    m.outFor[src] = (m.outFor[src] or 0) + dt
                    if m.outFor[src] >= 1000 then return endMatch(m, 'none', p.name .. ' est sorti de son véhicule : course annulée, aucune récompense.') end
                else m.outFor[src] = 0 end
            end
        end
    end
    local runnerSrc
    for src, p in pairs(m.players) do if p.role == 'runner' then runnerSrc = src break end end
    if not runnerSrc then return end
    local rped = GetPlayerPed(runnerSrc)
    if not rped or rped == 0 then return end
    local rc = GetEntityCoords(rped)
    local rveh = GetVehiclePedIsIn(rped, false)
    local active = now >= m.contactFrom
    local needMs = m.set.catchTime * 1000
    local nearest, bestContact, perChaser = 99999.0, 0, {}

    for src, p in pairs(m.players) do
        if p.role == 'chaser' then
            local ped = GetPlayerPed(src)
            if ped and ped ~= 0 then
                local c = GetEntityCoords(ped)
                local d = #(rc - c)
                local inRange = d <= m.set.catchDistance
                if inRange and m.set.requireVehicle then inRange = rveh ~= 0 and GetVehiclePedIsIn(ped, false) ~= 0 end
                if active and inRange then m.contact[src] = (m.contact[src] or 0) + dt else m.contact[src] = 0 end
                if m.contact[src] >= needMs then
                    return endMatch(m, 'chasers', 'Le fugitif a été collé pendant ' .. m.set.catchTime .. ' secondes !', src)
                end
                perChaser[src] = { dist = d, contact = m.contact[src], x = c.x, y = c.y, z = c.z }
                if d < nearest then nearest = d end
                if m.contact[src] > bestContact then bestContact = m.contact[src] end
            end
        end
    end
    if not sendUi then return end

    local remaining, releaseIn = m.endsAt - now, math.max(0, m.contactFrom - now)
    local chaserPositions
    if m.set.runnerSeesChasers then
        chaserPositions = {}
        for _, c in pairs(perChaser) do chaserPositions[#chaserPositions + 1] = { x = c.x, y = c.y } end
    end
    for src, p in pairs(m.players) do
        local payload = { remaining = remaining, releaseIn = releaseIn, catchTime = needMs }
        if p.role == 'runner' then
            payload.dist, payload.contact, payload.chasers = nearest, bestContact, chaserPositions
        else
            local c = perChaser[src]
            payload.dist = c and c.dist or 99999.0
            payload.contact = c and c.contact or 0
            payload.runner = { x = rc.x, y = rc.y }
        end
        TriggerClientEvent('worldbuilder:client:chaseTick', src, payload)
    end
end

CreateThread(function()
    local last, lastUi = GetGameTimer(), 0
    while true do
        Wait(C.TickMs)
        local now = GetGameTimer()
        local dt = now - last
        last = now
        local sendUi = now - lastUi >= C.UiTickMs
        if sendUi then lastUi = now end
        for _, m in pairs(matches) do
            if m.state == 'running' then tickMatch(m, now, dt, sendUi) end
        end
    end
end)

-- ─────────────────────────────── Menu / lobbies ───────────────────────────────
ESX.RegisterServerCallback('worldbuilder:chase:info', function(src, cb, eid, pi)
    local e, p, x = resolveDesk(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    -- Déjà dans un lobby : on peut rouvrir le menu (il s'ouvre sur « Mon lobby »)
    local mine = matches[playerMatch[src] or 0]
    if mine and mine.state ~= 'lobby' then return cb({ ok = false, error = 'Ta partie est en cours' }) end
    local s = e.settings
    local vehicles = vehiclesOf(e)
    local maps = {}
    for _, m in ipairs(mapsOf(e)) do maps[#maps + 1] = { id = m.id, label = m.label, desc = m.desc } end
    viewers[src] = e.id
    cb({ ok = true, eid = e.id, pi = tonumber(pi), label = p.label ~= '' and p.label or e.label, maps = maps, vehicles = vehicles,
        cfg = { pickTime = PICK_MS / 1000, duration = { min = s.durationMin, max = s.durationMax, default = s.durationDefault }, maxChasers = s.maxChasers, catchTime = s.catchTime, catchDistance = s.catchDistance, headStart = s.headStart,
            reward = { win = s.rewardWin, fee = s.entryFee } } })
    SetTimeout(200, broadcast)
end)

RegisterNetEvent('worldbuilder:chase:unsubscribe', function() viewers[source] = nil end)

ESX.RegisterServerCallback('worldbuilder:chase:leaderboard', function(src, cb)
    cb({ ok = true, rows = MySQL.query.await([[SELECT name, matches, wins_runner, wins_chaser, losses, (wins_runner + wins_chaser) AS wins FROM worldbuilder_chase_stats ORDER BY wins DESC, matches ASC LIMIT 15]]) or {} })
end)

local function addPlayer(m, src, role)
    if role ~= 'runner' and role ~= 'chaser' then role = 'chaser' end
    if role == 'runner' and countRole(m, 'runner') >= 1 then return false, 'Un fugitif est déjà présent dans cette partie.' end
    if role == 'chaser' and countRole(m, 'chaser') >= m.maxChasers then return false, 'Le nombre maximum de poursuivants est atteint.' end
    joinCounter = joinCounter + 1
    m.players[src] = { name = playerName(src), role = role, order = joinCounter, vehicle = m.vehicles[1].model }
    playerMatch[src] = m.id
    -- à partir du 2e joueur : 10 s pour choisir son véhicule, la partie ne peut pas être lancée
    if countRole(m, 'runner') + countRole(m, 'chaser') >= 2 then
        m.pickUntil = GetGameTimer() + PICK_MS
        SetTimeout(PICK_MS + 150, function() if matches[m.id] and m.state == 'lobby' then broadcast() end end)
    end
    return true
end

local function myMatchOf(src) return matches[playerMatch[src] or 0] end

RegisterNetEvent('worldbuilder:chase:create', function(data)
    local src = source
    local e = WB.Entities[viewers[src] or 0]
    if not e or e.type ~= 'chase' or not e.enabled or not ESX.GetPlayerFromId(src) or playerMatch[src] or type(data) ~= 'table' then return end
    local mapData
    for _, m in ipairs(mapsOf(e)) do if m.id == tonumber(data.map) then mapData = m end end
    if not mapData then return WB.notify(src, 'Carte invalide.', 'error') end
    local vehicles, vehicleBy = vehiclesOf(e)
    if #vehicles == 0 then return WB.notify(src, 'Aucun véhicule n\'est configuré.', 'error') end
    local s = e.settings
    local id = nextId
    nextId = nextId + 1
    local m = { id = id, eid = e.id, set = s, vehicles = vehicles, vehicleBy = vehicleBy, name = clean(data.name, 28, 'Course de ' .. playerName(src)), map = mapData.id, mapData = mapData,
        duration = clamp(data.duration, s.durationMin, s.durationMax, s.durationDefault), maxChasers = clamp(data.maxChasers, 1, s.maxChasers, 1),
        state = 'lobby', host = src, players = {}, ready = {}, contact = {} }
    matches[id] = m
    local cfee = math.floor(tonumber(s.entryFee) or 0)
    if cfee > 0 and balanceOf(ESX.GetPlayerFromId(src), acct(s)) < cfee then matches[id] = nil return WB.notify(src, 'Mise d\'entrée : ' .. cfee .. ' $ requis.', 'error') end
    local ok, err = addPlayer(m, src, data.role)
    if not ok then matches[id] = nil return WB.notify(src, err, 'error') end
    WB.notify(src, 'Partie créée.', 'success')
    broadcast()
end)

RegisterNetEvent('worldbuilder:chase:join', function(data)
    local src = source
    if not ESX.GetPlayerFromId(src) or playerMatch[src] or type(data) ~= 'table' then return end
    local m = matches[tonumber(data.id)]
    if not m or m.state ~= 'lobby' or m.eid ~= viewers[src] then return WB.notify(src, 'Cette partie n\'est plus disponible.', 'error') end
    local jx = ESX.GetPlayerFromId(src)
    local fee = math.floor(tonumber(m.set.entryFee) or 0)
    if fee > 0 and balanceOf(jx, acct(m.set)) < fee then return WB.notify(src, 'Mise d\'entrée : ' .. fee .. ' $ requis.', 'error') end
    local ok, err = addPlayer(m, src, data.role)
    if not ok then return WB.notify(src, err, 'error') end
    broadcast()
end)

RegisterNetEvent('worldbuilder:chase:leave', function() removePlayer(source, false) end)

RegisterNetEvent('worldbuilder:chase:setRole', function(role)
    local src = source
    local m = myMatchOf(src)
    if not m or m.state ~= 'lobby' or (role ~= 'runner' and role ~= 'chaser') then return end
    local p = m.players[src]
    if p.role == role then return end
    if role == 'runner' and countRole(m, 'runner') >= 1 then return WB.notify(src, 'Un fugitif est déjà présent.', 'error') end
    if role == 'chaser' and countRole(m, 'chaser') >= m.maxChasers then return WB.notify(src, 'Plus de place côté poursuivants.', 'error') end
    p.role = role
    broadcast()
end)

RegisterNetEvent('worldbuilder:chase:setVehicle', function(model)
    local src = source
    local m = myMatchOf(src)
    if not m or m.state ~= 'lobby' or type(model) ~= 'string' or not m.vehicleBy[model] then return end
    m.players[src].vehicle = model
    broadcast()
end)

RegisterNetEvent('worldbuilder:chase:start', function()
    local src = source
    local m = myMatchOf(src)
    if not m or m.state ~= 'lobby' then return end
    if m.host ~= src then return WB.notify(src, 'Seul l\'hôte peut lancer la partie.', 'error') end
    if (m.pickUntil or 0) > GetGameTimer() then return WB.notify(src, 'Les joueurs choisissent leur véhicule, patiente quelques secondes.', 'error') end
    if countRole(m, 'runner') ~= 1 or countRole(m, 'chaser') < 1 then return WB.notify(src, 'Il faut 1 fugitif et au moins 1 poursuivant.', 'error') end
    -- mise d'entrée : tout le monde doit pouvoir payer, puis chacun est débité au lancement
    local fee = math.floor(tonumber(m.set.entryFee) or 0)
    local account = acct(m.set)
    if fee > 0 then
        for psrc, p in pairs(m.players) do
            local px = ESX.GetPlayerFromId(psrc)
            if not px or balanceOf(px, account) < fee then
                return WB.notify(src, p.name .. ' n\'a pas assez d\'argent pour la mise (' .. fee .. ' $).', 'error')
            end
        end
        for psrc in pairs(m.players) do
            ESX.GetPlayerFromId(psrc).removeAccountMoney(account, fee, 'Mise course poursuite')
        end
    end
    m.fee, m.paid, m.pot = fee, {}, 0
    if fee > 0 then for psrc in pairs(m.players) do m.paid[psrc] = true m.pot = m.pot + fee end end
    CreateThread(function() runMatch(m) end)
end)

RegisterNetEvent('worldbuilder:chase:ready', function()
    local m = myMatchOf(source)
    if m and m.state == 'prepare' then m.ready[source] = true end
end)

AddEventHandler('playerDropped', function()
    local src = source
    viewers[src] = nil
    removePlayer(src, true)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for src in pairs(playerMatch) do resetBucket(src) end
end)
