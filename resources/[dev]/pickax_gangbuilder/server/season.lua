-- ─────────────────────────────── Saisons de gangs ───────────────────────────────
-- Points de saison = réputation gagnée par le gang depuis le début de la saison (captures, victoires, colis, tributs, quêtes…).
-- À la fin (Config.Season.Days), les meilleurs gangs reçoivent leurs récompenses (trésorerie + réputation), le résultat est conservé, puis une nouvelle saison démarre à zéro.

local Cur = nil          -- { id, started }
local Points = {}        -- [gang] = points de la saison en cours
local ready = false

local function S() return Config.Season end

-- Classement et attribution des récompenses (pure, testée hors jeu) : points = { [gang] = n } → liste triée { gang, points, rank, money, rep }
function GB.seasonDecide(points, rewards, minPoints)
    local list = {}
    for g, n in pairs(points or {}) do
        n = math.floor(tonumber(n) or 0)
        if n >= (minPoints or 1) then list[#list + 1] = { gang = g, points = n } end
    end
    table.sort(list, function(a, b) if a.points ~= b.points then return a.points > b.points end return a.gang < b.gang end)
    for i, e in ipairs(list) do
        e.rank = i
        local r = (rewards or {})[i]
        e.money, e.rep = r and math.floor(tonumber(r.money) or 0) or 0, r and math.floor(tonumber(r.rep) or 0) or 0
    end
    return list
end

local function label(name) return GB.Gangs[name] and GB.Gangs[name].label or name end

MySQL.ready(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS gangbuilder_seasons (id INT AUTO_INCREMENT PRIMARY KEY, started INT NOT NULL, ended INT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS gangbuilder_season_points (season INT NOT NULL, gang_name VARCHAR(50) NOT NULL, points INT NOT NULL DEFAULT 0, PRIMARY KEY (season, gang_name)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS gangbuilder_season_results (season INT NOT NULL, rank_no INT NOT NULL, gang_name VARCHAR(50) NOT NULL, points INT NOT NULL, money INT NOT NULL DEFAULT 0, rep INT NOT NULL DEFAULT 0, PRIMARY KEY (season, rank_no)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    local row = MySQL.single.await('SELECT id, started FROM gangbuilder_seasons WHERE ended IS NULL ORDER BY id DESC LIMIT 1')
    if row then Cur = { id = row.id, started = row.started }
    else Cur = { id = MySQL.insert.await('INSERT INTO gangbuilder_seasons (started) VALUES (?)', { os.time() }), started = os.time() } end
    for _, r in ipairs(MySQL.query.await('SELECT gang_name, points FROM gangbuilder_season_points WHERE season = ?', { Cur.id }) or {}) do Points[r.gang_name] = tonumber(r.points) or 0 end
    ready = true
end)

function GB.seasonAdd(gang, n)
    if not ready or not S().Enabled or not Cur then return end
    n = math.floor(tonumber(n) or 0)
    if n <= 0 then return end
    Points[gang] = (Points[gang] or 0) + n
    MySQL.update('INSERT INTO gangbuilder_season_points (season, gang_name, points) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE points = points + VALUES(points)', { Cur.id, gang, n })
end

local function endsAt() return Cur.started + math.max(1, S().Days or 7) * 86400 end

-- Fin de saison : récompenses, résultat conservé, nouvelle saison
function GB.seasonEnd()
    if not ready or not Cur then return false end
    local C = S()
    local winners = GB.seasonDecide(Points, C.Rewards, C.MinPoints)
    local old = Cur
    for _, e in ipairs(winners) do
        if GB.Gangs[e.gang] then
            if e.money > 0 then GB.treasuryAdd(e.gang, C.RewardAccount == 'money' and 'money' or 'dirty', e.money) end
            if e.rep > 0 then MySQL.update('UPDATE gangbuilder_gangs SET rep = rep + ? WHERE name = ?', { e.rep, e.gang }) end
            for _, s in ipairs(GB.onlineMembers(e.gang)) do
                GB.notify(s, ('~g~Saison terminée~s~ : ton gang finit ~y~#%d~s~ avec %d points%s.'):format(e.rank, e.points, e.money > 0 and (' (~g~+' .. e.money .. ' $~s~)') or ''))
            end
        end
        MySQL.insert('INSERT INTO gangbuilder_season_results (season, rank_no, gang_name, points, money, rep) VALUES (?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE points = VALUES(points)', { old.id, e.rank, e.gang, e.points, e.money, e.rep })
    end
    MySQL.update('UPDATE gangbuilder_seasons SET ended = ? WHERE id = ?', { os.time(), old.id })
    Cur = { id = MySQL.insert.await('INSERT INTO gangbuilder_seasons (started) VALUES (?)', { os.time() }), started = os.time() }
    Points = {}
    if GB.news then
        if winners[1] then GB.news(('Saison %d terminée : %s l\'emporte avec %d points.'):format(old.id, label(winners[1].gang), winners[1].points), 'season')
        else GB.news(('Saison %d terminée : aucun gang classé.'):format(old.id), 'season') end
    end
    return true
end

-- Données pour la tablette : saison en cours (top 10), temps restant, récompenses, dernière saison
function GB.seasonInfo(myGang)
    local C = S()
    if not ready or not C.Enabled or not Cur then return { enabled = false } end
    local list = GB.seasonDecide(Points, C.Rewards, 1)
    local top = {}
    for i = 1, math.min(10, #list) do
        local e = list[i]
        local g = GB.Gangs[e.gang]
        if g then top[#top + 1] = { rank = i, name = e.gang, label = g.label, color = g.color, logo = g.settings and g.settings.logo, points = e.points, me = e.gang == myGang } end
    end
    local mine
    for i, e in ipairs(list) do if e.gang == myGang then mine = { rank = i, points = e.points } end end
    local last = {}
    local lastId = MySQL.scalar.await('SELECT MAX(id) FROM gangbuilder_seasons WHERE ended IS NOT NULL')
    if lastId then
        for _, r in ipairs(MySQL.query.await('SELECT rank_no, gang_name, points, money FROM gangbuilder_season_results WHERE season = ? ORDER BY rank_no LIMIT 3', { lastId }) or {}) do
            last[#last + 1] = { rank = r.rank_no, label = label(r.gang_name), points = r.points, money = r.money }
        end
    end
    return { enabled = true, id = Cur.id, left = math.max(0, endsAt() - os.time()), minPoints = C.MinPoints, rewards = C.Rewards, account = C.RewardAccount, top = top, mine = mine, last = last, lastId = lastId }
end

CreateThread(function()
    while true do
        Wait(30000)
        if ready and S().Enabled and Cur and os.time() >= endsAt() then
            local ok, err = pcall(GB.seasonEnd)
            if not ok then print(('^1[gangbuilder] erreur fin de saison : %s^0'):format(tostring(err))) end
        end
    end
end)

-- Staff : /endseason termine la saison tout de suite (test ou rattrapage)
RegisterCommand('endseason', function(src)
    if src ~= 0 and not GB.isDev(src) then return end
    local ok = GB.seasonEnd()
    if src ~= 0 then GB.notify(src, ok and '~g~Saison terminée.' or '~r~Saisons indisponibles.') end
end, false)
exports('GetSeasonInfo', function(gang) return GB.seasonInfo(gang) end)
