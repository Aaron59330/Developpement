-- Parties : lobby → attente → compte à rebours → partie → résultats (tout est décidé côté serveur)

local function now() return os.time() end

-- Anti-cheat : le joueur est marqué « en mini-jeu » (statebag lu par pickax_anticheat) et exempté quelques secondes à chaque téléportation
local function acMark(src, on, seconds)
    pcall(function() Player(src).state:set('inMinigame', on and true or nil, true) end)
    if GetResourceState('pickax_anticheat') == 'started' then pcall(function() exports.pickax_anticheat:Exempt(src, seconds or 10, 'minigame') end) end
end

local function getGame(id)
    local g = MG.Games[id]
    if not g then
        g = { id = id, state = 'idle', players = {}, order = {}, pot = 0 }
        MG.Games[id] = g
    end
    return g
end

local function count(g)
    local n = 0
    for _ in pairs(g.players) do n = n + 1 end
    return n
end

local function eachPlayer(g, fn)
    for src, p in pairs(g.players) do fn(src, p) end
end

local function pushLobby(g)
    local def = MG.Defs[g.id]
    if not def then return end
    local list = {}
    for _, src in ipairs(g.order) do
        local p = g.players[src]
        if p then list[#list + 1] = { name = p.name, team = p.team } end
    end
    local info = { id = g.id, state = g.state, count = #list, min = def.settings.minPlayers, max = def.settings.maxPlayers,
                   left = g.waitEnd and math.max(0, g.waitEnd - now()) or nil, players = list }
    eachPlayer(g, function(src) TriggerClientEvent('minigames:lobbyState', src, info) end)
end

-- Classement
function MG.top(id)
    local def = MG.Defs[id]
    local rows
    if def and Config.Types[def.type].engine == 'race' then
        rows = MySQL.query.await('SELECT name, plays, wins, best, total, best_time FROM minigames_stats WHERE game_id = ? AND best_time > 0 ORDER BY best_time ASC LIMIT ?', { id, Config.MaxTop })
    else
        rows = MySQL.query.await('SELECT name, plays, wins, best, total, best_time FROM minigames_stats WHERE game_id = ? ORDER BY best DESC, wins DESC LIMIT ?', { id, Config.MaxTop })
    end
    return rows or {}
end

local function refund(p, src)
    if p.fee and p.fee > 0 and not p.refunded then
        p.refunded = true
        local x = ESX.GetPlayerFromId(src)
        if x then x.addAccountMoney(Config.PayAccount, p.fee, 'minigames-refund') end
        return true
    end
    return false
end

local function spawnFor(g, p, idx)
    local def = MG.Defs[g.id]
    local list = def.points.spawns or {}
    local pool = {}
    local engine = Config.Types[def.type].engine
    if p.team then
        for _, s in ipairs(list) do if (s.team or 1) == p.team then pool[#pool + 1] = s end end
    end
    if #pool == 0 then pool = list end
    if #pool == 0 then return def.points.lobby end
    if p.team or engine == 'tag' then return pool[math.random(#pool)] end
    return pool[((idx - 1) % #pool) + 1]
end

function MG.removePlayer(src, reason, silent)
    local id = MG.InGame[src]
    if not id then return end
    local g = MG.Games[id]
    MG.InGame[src] = nil
    acMark(src, false, 12)
    if not g or not g.players[src] then return end
    local p = g.players[src]
    if g.state == 'waiting' then refund(p, src) end
    g.players[src] = nil
    for i, s in ipairs(g.order) do if s == src then table.remove(g.order, i) break end end
    if not silent then TriggerClientEvent('minigames:kick', src, reason or 'Tu as quitté la partie.', g.state == 'waiting') end

    local def = MG.Defs[id]
    local n = count(g)
    if n == 0 then
        g.state = 'idle'; g.waitEnd = nil; g.pot = 0
        return
    end
    if g.state == 'waiting' then
        if def and n < def.settings.minPlayers then g.waitEnd = nil end
        pushLobby(g)
    elseif (g.state == 'countdown' or g.state == 'running') and def and n < math.min(2, def.settings.minPlayers) then
        MG.finish(g, 'Plus assez de joueurs')
    end
end

function MG.closeGame(id, reason)
    local g = MG.Games[id]
    if not g then return end
    for src in pairs(g.players) do
        local p = g.players[src]
        if g.state == 'waiting' or g.state == 'countdown' then refund(p, src) end
        MG.InGame[src] = nil
        acMark(src, false, 12)
        TriggerClientEvent('minigames:kick', src, reason or 'Partie annulée.', true)
    end
    MG.Games[id] = nil
end

-- ─── Démarrage ────────────────────────────────────────────────────────────────
local function startCountdown(g)
    local def = MG.Defs[g.id]
    local T = Config.Types[def.type]
    g.state = 'countdown'
    g.waitEnd = nil
    g.countEnd = now() + def.settings.countdown
    local teams = T.engine == 'tag' and tonumber(def.settings.teams) == 2
    local t1, t2 = 0, 0
    for i, src in ipairs(g.order) do
        local p = g.players[src]
        if teams then
            if t1 <= t2 then p.team = 1; t1 = t1 + 1 else p.team = 2; t2 = t2 + 1 end
        end
        p.score, p.kills, p.deaths, p.shots, p.cp, p.finished, p.hp = 0, 0, 0, 0, 0, false, def.settings.hp
        p.lastAct = 0
        local sp = spawnFor(g, p, i)
        acMark(src, true, 12)
        TriggerClientEvent('minigames:begin', src, {
            id = g.id, type = def.type, engine = T.engine, name = def.name, team = p.team, spawn = sp,
            countdown = def.settings.countdown, settings = def.settings, points = def.points, slot = i, props = def.props,
        })
    end
    g.teamScore = { 0, 0 }
    if T.engine == 'fight' then
        g.round, g.roundState, g.roundEnd = 1, 'wait', nil
    end
    pushLobby(g)
end

local function startRunning(g)
    local def = MG.Defs[g.id]
    local T = Config.Types[def.type]
    g.state = 'running'
    g.startedAt = GetGameTimer()
    g.endAt = now() + def.settings.duration
    if T.engine == 'fight' then
        g.endAt = now() + def.settings.rounds * (def.settings.roundTime + 6) + 10
        g.roundState = 'fight'
        g.roundEnd = now() + def.settings.roundTime
    end
    eachPlayer(g, function(src) TriggerClientEvent('minigames:go', src, { duration = def.settings.duration }) end)
end

-- ─── Fin de partie ────────────────────────────────────────────────────────────
local function rank(g, def)
    local T = Config.Types[def.type]
    local rows = {}
    for src, p in pairs(g.players) do
        rows[#rows + 1] = { src = src, name = p.name, team = p.team, score = p.score, kills = p.kills, deaths = p.deaths, time = p.time, cp = p.cp, finished = p.finished, hp = p.hp }
    end
    if T.engine == 'race' then
        table.sort(rows, function(a, b)
            if a.finished ~= b.finished then return a.finished end
            if a.finished then return (a.time or 0) < (b.time or 0) end
            return (a.cp or 0) > (b.cp or 0)
        end)
    else
        table.sort(rows, function(a, b)
            if a.score ~= b.score then return a.score > b.score end
            if (a.kills or 0) ~= (b.kills or 0) then return (a.kills or 0) > (b.kills or 0) end
            return (a.name or '') < (b.name or '')
        end)
    end
    return rows
end

function MG.finish(g, why)
    if g.state ~= 'running' and g.state ~= 'countdown' then return end
    local def = MG.Defs[g.id]
    if not def then return MG.closeGame(g.id, 'Mini-jeu supprimé') end
    local T = Config.Types[def.type]
    local S = def.settings
    local rows = rank(g, def)
    local solo = #rows == 1
    local teams = T.engine == 'tag' and tonumber(S.teams) == 2

    -- gagnants
    local winners = {}
    if teams then
        local w = (g.teamScore[1] > g.teamScore[2]) and 1 or ((g.teamScore[2] > g.teamScore[1]) and 2 or 0)
        for _, r in ipairs(rows) do if w ~= 0 and r.team == w then winners[r.src] = true end end
    elseif T.engine == 'race' then
        if rows[1] and rows[1].finished then winners[rows[1].src] = true end
    elseif solo then
        if rows[1] and rows[1].score > 0 then winners[rows[1].src] = true end
    else
        local top = rows[1] and rows[1].score or 0
        if top > 0 then
            for _, r in ipairs(rows) do if r.score == top then winners[r.src] = true end end
        end
    end

    local nWin = 0
    for _ in pairs(winners) do nWin = nWin + 1 end
    local share = (S.pot and nWin > 0) and math.floor((g.pot or 0) / nWin) or 0

    local summary = {}
    for pos, r in ipairs(rows) do
        local p = g.players[r.src]
        local won = winners[r.src] == true
        local ident = p and MG.identifier(r.src)
        local mult = 1.0
        if ident then mult = Progress.multiplier(ident, def, won) end
        local gain = (won and S.rewardWin or S.rewardLose) + S.rewardPerPoint * math.max(0, r.score or 0)
        if T.engine == 'race' and not r.finished then gain = S.rewardLose end
        gain = math.floor(gain * mult + (won and share or 0))
        local x = ESX.GetPlayerFromId(r.src)
        if x and gain > 0 then x.addAccountMoney(Config.RewardAccount, gain, 'minigames-reward') end
        r.won, r.gain, r.pos = won, gain, pos
        local entry = { name = r.name, team = r.team, score = r.score, kills = r.kills, deaths = r.deaths, time = r.time, finished = r.finished, won = won, gain = gain, pos = pos, mult = mult }
        summary[#summary + 1] = entry
        if ident then
            local bt = (r.finished and r.time) or 0
            -- record battu : annonce serveur
            if Progress.cfg.settings.announce.records and (T.engine ~= 'race' or r.finished) then
                local prev
                if T.engine == 'race' then prev = MySQL.scalar.await('SELECT MIN(best_time) FROM minigames_stats WHERE game_id = ? AND best_time > 0', { g.id })
                else prev = MySQL.scalar.await('SELECT MAX(best) FROM minigames_stats WHERE game_id = ?', { g.id }) end
                prev = tonumber(prev)
                local beaten = prev and prev > 0 and ((T.engine == 'race' and bt > 0 and bt < prev) or (T.engine ~= 'race' and r.score > prev))
                if beaten then
                    local v = T.engine == 'race' and ('%.2fs'):format(bt / 1000) or (r.score .. ' pts')
                    TriggerClientEvent('esx:showNotification', -1, ('~y~Record !~s~ %s bat le record de ~b~%s~s~ : %s'):format(r.name, def.name, v))
                end
            end
            entry.prog = Progress.record(ident, r.name, { def = def, won = won, score = r.score, kills = r.kills, mult = mult })
            MySQL.update('INSERT INTO minigames_stats (game_id, identifier, name, plays, wins, best, total, best_time) VALUES (?, ?, ?, 1, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name), plays = plays + 1, wins = wins + VALUES(wins), best = GREATEST(best, VALUES(best)), total = total + VALUES(total), best_time = IF(VALUES(best_time) > 0 AND (best_time = 0 OR VALUES(best_time) < best_time), VALUES(best_time), best_time)',
                { g.id, ident, r.name, won and 1 or 0, math.max(0, r.score or 0), math.max(0, r.score or 0), bt })
        end
    end

    local payload = { id = g.id, name = def.name, type = def.type, engine = T.engine, why = why, rows = summary, teams = teams, teamScore = g.teamScore, ret = Config.ReturnAfterEnd }
    for src in pairs(g.players) do
        MG.InGame[src] = nil
        acMark(src, false, 20)
        payload.you = g.players[src] and g.players[src].name or nil
        TriggerClientEvent('minigames:end', src, payload)
    end
    if #summary > 0 then
        local best = summary[1]
        MG.log(nil, 'partie terminée', g.id, ('%d joueur(s) · 1er : %s (%s)'):format(#summary, best.name, tostring(T.engine == 'race' and (best.time or 0) / 1000 or best.score)))
    end
    for _, r in ipairs(rows) do
        MG.Cool[(MG.identifier(r.src) or tostring(r.src)) .. g.id] = now() + (S.cooldown or 0)
    end
    MG.Games[g.id] = nil
end

-- ─── HUD ──────────────────────────────────────────────────────────────────────
local function pushHud(g)
    local def = MG.Defs[g.id]
    if not def then return end
    local rows = rank(g, def)
    local list = {}
    for _, r in ipairs(rows) do list[#list + 1] = { src = r.src, name = r.name, team = r.team, score = r.score, cp = r.cp, hp = r.hp, finished = r.finished, time = r.time } end
    local T = Config.Types[def.type]
    local left = g.endAt and math.max(0, g.endAt - now()) or 0
    local extra
    if T.engine == 'fight' then
        extra = { round = g.round, rounds = def.settings.rounds, roundState = g.roundState, roundLeft = g.roundEnd and math.max(0, g.roundEnd - now()) or 0, maxHp = def.settings.hp }
        left = extra.roundLeft
    elseif T.engine == 'race' then
        local N = #(def.points.checkpoints or {})
        extra = { total = N * def.settings.laps, laps = def.settings.laps, perLap = N }
    elseif T.engine == 'tag' then
        extra = { limit = def.settings.scoreLimit, teamScore = g.teamScore, teams = tonumber(def.settings.teams) == 2 }
    elseif T.engine == 'shoot' or T.engine == 'rally' then
        extra = { balls = def.settings.balls }
    elseif T.engine == 'bowling' then
        extra = { frames = def.settings.frames }
    end
    for src in pairs(g.players) do
        TriggerClientEvent('minigames:hud', src, { left = left, rows = list, extra = extra, me = src })
    end
end

-- ─── Boucle principale (1 Hz) ─────────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(1000)
        for id, g in pairs(MG.Games) do
            local def = MG.Defs[id]
            if not def then
                MG.closeGame(id, 'Mini-jeu supprimé')
            elseif g.state == 'waiting' then
                local n = count(g)
                -- un joueur qui s'éloigne du lobby est retiré (remboursé)
                for src in pairs(g.players) do
                    if def.points.lobby and MG.distanceTo(src, def.points.lobby) > 80.0 then MG.removePlayer(src, 'Tu t\'es trop éloigné du lobby.') end
                end
                n = count(g)
                if n > 0 then
                    if n >= def.settings.maxPlayers and n >= def.settings.minPlayers then startCountdown(g)
                    elseif n >= def.settings.minPlayers then
                        if not g.waitEnd then g.waitEnd = now() + def.settings.waitSeconds; pushLobby(g) end
                        if now() >= g.waitEnd then startCountdown(g) else pushLobby(g) end
                    end
                end
            elseif g.state == 'countdown' then
                if now() >= g.countEnd then startRunning(g) end
            elseif g.state == 'running' then
                local T = Config.Types[def.type]
                local t = now()
                -- joueurs hors ligne / retours de réapparition
                for src, p in pairs(g.players) do
                    if p.deadUntil and t >= p.deadUntil then
                        p.deadUntil = nil
                        local sp = spawnFor(g, p, 1)
                        TriggerClientEvent('minigames:respawn', src, sp)
                    end
                end
                if T.engine == 'fight' then MG.fightTick(g, def) end
                if g.state == 'running' then
                    local allDone = count(g) > 0
                    if T.engine == 'shoot' or T.engine == 'rally' or T.engine == 'bowling' or T.engine == 'race' then
                        for _, p in pairs(g.players) do if not p.finished then allDone = false end end
                    else allDone = false end
                    if allDone then MG.finish(g, 'Terminé')
                    elseif t >= g.endAt then MG.finish(g, 'Temps écoulé')
                    else pushHud(g) end
                end
            end
        end
    end
end)

-- ─── Combat (boxe) ────────────────────────────────────────────────────────────
function MG.fightTick(g, def)
    local S = def.settings
    local t = now()
    if g.roundState == 'fight' then
        local lowest, ko = nil, false
        for _, p in pairs(g.players) do if p.hp <= 0 then ko = true end end
        if ko or t >= g.roundEnd then
            -- vainqueur du round : plus de PV
            local best, bestHp, tie = nil, -1, false
            for src, p in pairs(g.players) do
                if p.hp > bestHp then best, bestHp, tie = src, p.hp, false
                elseif p.hp == bestHp then tie = true end
            end
            if best and not tie then g.players[best].score = g.players[best].score + 1 end
            g.roundState = 'break'
            g.roundEnd = t + 5
            eachPlayer(g, function(src) TriggerClientEvent('minigames:round', src, { round = g.round, winner = (best and not tie) and g.players[best].name or nil, ko = ko }) end)
        end
    elseif g.roundState == 'break' and t >= g.roundEnd then
        local need = math.floor(S.rounds / 2) + 1
        local over = g.round >= S.rounds
        for _, p in pairs(g.players) do if p.score >= need then over = true end end
        if over then return MG.finish(g, 'Combat terminé') end
        g.round = g.round + 1
        g.roundState = 'fight'
        g.roundEnd = t + S.roundTime
        local i = 0
        for _, src in ipairs(g.order) do
            i = i + 1
            local p = g.players[src]
            if p then
                p.hp = S.hp
                TriggerClientEvent('minigames:respawn', src, spawnFor(g, p, i))
            end
        end
    end
end

-- ─── Callbacks ────────────────────────────────────────────────────────────────
ESX.RegisterServerCallback('minigames:lobby', function(src, cb, id)
    id = tostring(id)
    local def = MG.Defs[id]
    if not def or not def.enabled then return cb({ ok = false, error = 'Mini-jeu indisponible' }) end
    local g = MG.Games[id]
    local list = {}
    if g then for _, s in ipairs(g.order) do local p = g.players[s]; if p then list[#list + 1] = { name = p.name, team = p.team } end end end
    local ident = MG.identifier(src)
    local mine
    if ident then
        mine = MySQL.single.await('SELECT plays, wins, best, best_time FROM minigames_stats WHERE game_id = ? AND identifier = ?', { id, ident })
    end
    local cool = ident and MG.Cool[ident .. id] and math.max(0, MG.Cool[ident .. id] - now()) or 0
    cb({
        ok = true, id = id, name = def.name, type = def.type, desc = def.description ~= '' and def.description or Config.Types[def.type].desc,
        engine = Config.Types[def.type].engine, settings = def.settings,
        state = g and g.state or 'idle', players = list, joined = MG.InGame[src] == id,
        top = MG.top(id), mine = mine, cooldown = cool, currency = Config.Currency,
        me = Progress.brief(src), featured = Progress.featured() == id and Progress.cfg.settings.weekly.mult or nil,
        left = g and g.waitEnd and math.max(0, g.waitEnd - now()) or nil,
    })
end)

ESX.RegisterServerCallback('minigames:join', function(src, cb, id)
    id = tostring(id)
    local def = MG.Defs[id]
    local x = ESX.GetPlayerFromId(src)
    if not def or not def.enabled or not x then return cb({ ok = false, error = 'Mini-jeu indisponible' }) end
    if MG.InGame[src] then return cb({ ok = false, error = 'Tu es déjà dans une partie' }) end
    if def.points.lobby and MG.distanceTo(src, def.points.lobby) > Config.InteractDistance + 15.0 then return cb({ ok = false, error = 'Tu es trop loin du lobby' }) end
    local g = getGame(id)
    if g.state ~= 'idle' and g.state ~= 'waiting' then return cb({ ok = false, error = 'Une partie est déjà en cours' }) end
    if count(g) >= def.settings.maxPlayers then return cb({ ok = false, error = 'Le lobby est complet' }) end
    local ident = x.identifier
    local cd = MG.Cool[ident .. id]
    if cd and cd > now() then return cb({ ok = false, error = ('Patiente encore %ds avant de rejouer'):format(cd - now()) }) end
    local fee = math.floor(def.settings.entryFee or 0)
    if fee > 0 then
        local acc = x.getAccount(Config.PayAccount)
        if not acc or acc.money < fee then return cb({ ok = false, error = ('Il te faut %s%d pour participer'):format(Config.Currency, fee) }) end
        x.removeAccountMoney(Config.PayAccount, fee, 'minigames-entry')
        g.pot = (g.pot or 0) + fee
    end
    g.state = 'waiting'
    g.players[src] = { name = MG.playerName(src), fee = fee, score = 0 }
    g.order[#g.order + 1] = src
    MG.InGame[src] = id
    acMark(src, true, 12)
    if def.settings.minPlayers <= 1 and def.settings.waitSeconds == 0 then startCountdown(g) else pushLobby(g) end
    cb({ ok = true })
end)

ESX.RegisterServerCallback('minigames:leave', function(src, cb)
    MG.removePlayer(src, 'Tu as quitté la partie.')
    cb({ ok = true })
end)

AddEventHandler('playerDropped', function()
    MG.removePlayer(source, nil, true)
end)

-- ─── Événements de jeu envoyés par les clients (tous vérifiés) ───────────────
local function running(src)
    local id = MG.InGame[src]
    local g = id and MG.Games[id]
    if not g or g.state ~= 'running' then return end
    local p = g.players[src]
    local def = MG.Defs[id]
    if not p or not def then return end
    return g, p, def, Config.Types[def.type]
end

RegisterNetEvent('minigames:shot', function()
    local g, p, def, T = running(source)
    if not g or (T.engine ~= 'shoot' and T.engine ~= 'rally' and T.engine ~= 'bowling') then return end
    p.shots = p.shots + 1
    local lim = T.engine == 'bowling' and def.settings.frames * 2 or def.settings.balls
    if lim and p.shots > lim + 1 then p.shots = lim + 1 end
end)

RegisterNetEvent('minigames:score', function(pts)
    local g, p, def, T = running(source)
    if not g or (T.engine ~= 'shoot' and T.engine ~= 'rally' and T.engine ~= 'bowling') then return end
    pts = math.floor(tonumber(pts) or 0)
    if pts <= 0 then return end
    local max = math.max(def.settings.points2 or 0, def.settings.points3 or 0)
    if T.engine == 'bowling' then max = 10 + math.max(def.settings.strikeBonus or 0, def.settings.spareBonus or 0) end
    for _, z in ipairs(def.points.zones or {}) do max = math.max(max, z.pts or 0) end
    if pts > max then return end
    local t = GetGameTimer()
    if p.lastScore and t - p.lastScore < 900 then return end
    if (p.scored or 0) >= p.shots then return end
    p.lastScore = t
    p.scored = (p.scored or 0) + 1
    p.score = p.score + pts
    TriggerClientEvent('minigames:scored', source, pts)
end)

RegisterNetEvent('minigames:done', function()
    local g, p, def, T = running(source)
    if not g then return end
    if T.engine == 'shoot' or T.engine == 'rally' or T.engine == 'bowling' then p.finished = true end
end)

RegisterNetEvent('minigames:tagHit', function(victim)
    local src = source
    victim = tonumber(victim)
    local g, p, def, T = running(src)
    if not g or T.engine ~= 'tag' or not victim or victim == src then return end
    local v = g.players[victim]
    if not v or v.deadUntil then return end
    local S = def.settings
    local t = GetGameTimer()
    if p.deadUntil or (p.lastAct and t - p.lastAct < S.fireDelay) then return end
    if S.friendlyFire ~= true and p.team and p.team == v.team then return end
    local a, b = GetPlayerPed(src), GetPlayerPed(victim)
    if not a or a == 0 or not b or b == 0 then return end
    if #(GetEntityCoords(a) - GetEntityCoords(b)) > S.hitRange + 8.0 then return end
    p.lastAct = t
    p.score = p.score + 1
    p.kills = p.kills + 1
    v.deaths = v.deaths + 1
    v.deadUntil = now() + S.respawnSeconds
    if p.team then g.teamScore[p.team] = g.teamScore[p.team] + 1 end
    TriggerClientEvent('minigames:down', victim, { by = p.name, secs = S.respawnSeconds })
    TriggerClientEvent('minigames:scored', src, 1)
    local reached = p.team and g.teamScore[p.team] >= S.scoreLimit or p.score >= S.scoreLimit
    if reached then MG.finish(g, 'Limite de score atteinte') else pushHud(g) end
end)

RegisterNetEvent('minigames:splat', function(x, y, z)
    local src = source
    local g, p, def, T = running(src)
    if not g or T.engine ~= 'tag' or not def.settings.splat then return end
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y or not z then return end
    local t = GetGameTimer()
    if p.lastSplat and t - p.lastSplat < 80 then return end
    p.lastSplat = t
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or #(GetEntityCoords(ped) - vector3(x, y, z)) > def.settings.hitRange + 12.0 then return end
    local col
    if p.team then col = Config.Splat.team[p.team] or Config.Splat.team[1]
    else col = Config.Splat.ffa[(src % #Config.Splat.ffa) + 1] end
    for dst in pairs(g.players) do TriggerClientEvent('minigames:splat', dst, x, y, z, col[1], col[2], col[3]) end
end)

RegisterNetEvent('minigames:fightHit', function(victim)
    local src = source
    victim = tonumber(victim)
    local g, p, def, T = running(src)
    if not g or T.engine ~= 'fight' or g.roundState ~= 'fight' or not victim or victim == src then return end
    local v = g.players[victim]
    if not v or v.hp <= 0 or p.hp <= 0 then return end
    local S = def.settings
    local t = GetGameTimer()
    if p.lastAct and t - p.lastAct < S.hitDelay then return end
    local a, b = GetPlayerPed(src), GetPlayerPed(victim)
    if not a or a == 0 or not b or b == 0 then return end
    if #(GetEntityCoords(a) - GetEntityCoords(b)) > 3.5 then return end
    p.lastAct = t
    local dmg = math.random(S.damageMin, math.max(S.damageMin, S.damageMax))
    v.hp = math.max(0, v.hp - dmg)
    TriggerClientEvent('minigames:hurt', victim, { dmg = dmg, hp = v.hp, ko = v.hp <= 0 })
    pushHud(g)
end)

RegisterNetEvent('minigames:cp', function(idx)
    local src = source
    local g, p, def, T = running(src)
    if not g or T.engine ~= 'race' or p.finished then return end
    local cps = def.points.checkpoints or {}
    local N = #cps
    idx = math.floor(tonumber(idx) or 0)
    local expected = (p.cp % N) + 1
    if idx ~= expected then return end
    local c = cps[idx]
    if MG.distanceTo(src, c) > (c.r or def.settings.cpRadius) + 30.0 then return end
    local t = GetGameTimer()
    if p.lastAct and t - p.lastAct < 600 then return end
    p.lastAct = t
    p.cp = p.cp + 1
    if p.cp >= N * def.settings.laps then
        p.finished = true
        p.time = t - g.startedAt
        p.score = 1
        TriggerClientEvent('minigames:scored', src, 0)
    end
    pushHud(g)
end)

RegisterNetEvent('minigames:quit', function()
    MG.removePlayer(source, 'Tu as quitté la partie.')
end)
