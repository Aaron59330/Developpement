-- Progression : XP, niveaux, paliers de coins boutique, défis quotidiens / hebdo, succès, saisons, mini-jeu de la semaine
-- Tout est configurable en jeu (builder → Progression). Les valeurs par défaut viennent de Config.Progress.

Progress = { cfg = nil, rows = {}, season = nil }
local P = Progress

local function copy(t)
    if type(t) ~= 'table' then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = copy(v) end
    return o
end
local function num(v, min, max, def)
    v = tonumber(v)
    if not v or v ~= v or v == math.huge or v == -math.huge then v = def or 0 end
    if min and v < min then v = min end
    if max and v > max then v = max end
    return v
end
local function str(v, max, def)
    if type(v) ~= 'string' then return def or '' end
    return (v:gsub('[\0-\8\11\12\14-\31]', '')):sub(1, max or 60)
end
local function slug(s) s = tostring(s or ''):lower():gsub('[^%w_]+', '_'):gsub('^_+', ''):gsub('_+$', ''); return s:sub(1, 24) end

-- ─── Réglages ────────────────────────────────────────────────────────────────
local SPEC = {
    xp        = { enabled = 'b', perGame = { 0, 10000 }, win = { 0, 10000 }, perPoint = { 0, 1000 }, maxPerGame = { 0, 100000 }, streakPct = { 0, 200 }, streakMax = { 0, 20 } },
    curve     = { base = { 10, 1000000 }, growth = { 1.0, 3.0 }, maxLevel = { 1, 200 } },
    milestone = { enabled = 'b', xp = { 100, 10000000 }, coins = { 0, 100000 }, money = { 0, 100000000 } },
    weekly    = { enabled = 'b', mode = 's', gameId = 't', mult = { 1, 10 } },
    season    = { enabled = 'b', days = { 1, 365 } },
    announce  = { records = 'b', levels = 'b' },
}
local KINDS_C = { plays = true, wins = true, points = true, kills = true }
local KINDS_A = { plays_total = true, wins_total = true, points_total = true, best_streak = true, level = true }

local function cleanSection(spec, input, default)
    local out = {}
    input = type(input) == 'table' and input or {}
    for k, sp in pairs(spec) do
        local v = input[k]
        if v == nil then v = default[k] end
        if sp == 'b' then out[k] = v == true
        elseif sp == 's' then out[k] = (v == 'fixed') and 'fixed' or 'random'
        elseif sp == 't' then out[k] = str(v, 40, '')
        else out[k] = num(v, sp[1], sp[2], default[k]) end
    end
    return out
end

function P.sanitize(d, cur)
    d = type(d) == 'table' and d or {}
    local s = type(d.settings) == 'table' and d.settings or {}
    local out = { settings = {} }
    for k, spec in pairs(SPEC) do out.settings[k] = cleanSection(spec, s[k], cur.settings[k]) end
    out.settings.curve.maxLevel = math.floor(out.settings.curve.maxLevel)

    local rw = {}
    for i, r in ipairs(type(s.season) == 'table' and type(s.season.rewards) == 'table' and s.season.rewards or {}) do
        if i > 10 then break end
        rw[#rw + 1] = { rank = math.floor(num(r.rank, 1, 100, i)), money = math.floor(num(r.money, 0, 100000000, 0)), coins = math.floor(num(r.coins, 0, 100000, 0)) }
    end
    out.settings.season.rewards = rw

    out.levels = {}
    for i, l in ipairs(type(d.levels) == 'table' and d.levels or {}) do
        if i > 60 then break end
        out.levels[#out.levels + 1] = { level = math.floor(num(l.level, 1, 200, 2)), title = str(l.title, 24), money = math.floor(num(l.money, 0, 100000000, 0)), coins = math.floor(num(l.coins, 0, 100000, 0)) }
    end
    table.sort(out.levels, function(a, b) return a.level < b.level end)

    local function list(src, kinds, withScope)
        local res, seen = {}, {}
        for i, c in ipairs(type(src) == 'table' and src or {}) do
            if i > 60 then break end
            local id = slug(c.id)
            if id == '' or seen[id] then id = 'x' .. i .. '_' .. tostring(math.random(1000, 9999)) end
            seen[id] = true
            local e = {
                id = id, name = str(c.name, 50, 'Sans nom'), kind = kinds[c.kind] and c.kind or next(kinds),
                target = math.floor(num(c.target, 1, 1000000, 1)), xp = math.floor(num(c.xp, 0, 100000, 0)),
                money = math.floor(num(c.money, 0, 100000000, 0)), coins = math.floor(num(c.coins, 0, 100000, 0)), enabled = c.enabled ~= false,
            }
            if withScope then e.scope = c.scope == 'weekly' and 'weekly' or 'daily'; e.game = str(c.game, 24, 'any'); if e.game == '' then e.game = 'any' end
            else e.desc = str(c.desc, 80) end
            res[#res + 1] = e
        end
        return res
    end
    out.challenges = list(d.challenges, KINDS_C, true)
    out.achievements = list(d.achievements, KINDS_A, false)
    return out
end

local function persistCfg()
    MySQL.insert.await('INSERT INTO minigames_settings (k, v) VALUES (?, ?) ON DUPLICATE KEY UPDATE v = VALUES(v)', { 'progress', json.encode(P.cfg) })
end
local function persistSeason()
    MySQL.insert.await('INSERT INTO minigames_settings (k, v) VALUES (?, ?) ON DUPLICATE KEY UPDATE v = VALUES(v)', { 'season', json.encode(P.season) })
end

function P.load()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS minigames_settings (k VARCHAR(40) NOT NULL PRIMARY KEY, v LONGTEXT NOT NULL)]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS minigames_players (
        identifier VARCHAR(80) NOT NULL PRIMARY KEY, name VARCHAR(80) NOT NULL DEFAULT '',
        xp INT NOT NULL DEFAULT 0, plays INT NOT NULL DEFAULT 0, wins INT NOT NULL DEFAULT 0, points INT NOT NULL DEFAULT 0,
        streak INT NOT NULL DEFAULT 0, best_streak INT NOT NULL DEFAULT 0, rewarded_level INT NOT NULL DEFAULT 1,
        milestones INT NOT NULL DEFAULT 0, season_xp INT NOT NULL DEFAULT 0,
        challenges LONGTEXT NULL, achievements LONGTEXT NULL
    )]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS minigames_pending (
        id INT AUTO_INCREMENT PRIMARY KEY, identifier VARCHAR(80) NOT NULL, money INT NOT NULL DEFAULT 0, coins INT NOT NULL DEFAULT 0, label VARCHAR(120) NOT NULL DEFAULT ''
    )]])
    local base = copy(Config.Progress)
    local row = MySQL.single.await('SELECT v FROM minigames_settings WHERE k = ?', { 'progress' })
    local saved = row and MG.decode(row.v, nil)
    P.cfg = saved and P.sanitize(saved, base) or base
    local s = MySQL.single.await('SELECT v FROM minigames_settings WHERE k = ?', { 'season' })
    P.season = s and MG.decode(s.v, nil) or nil
    if not P.season or not P.season.id then P.season = { id = 1, start = os.time() }; persistSeason() end
end

-- ─── Niveaux ─────────────────────────────────────────────────────────────────
function P.need(level)    -- XP nécessaire pour passer de `level` à `level + 1`
    local c = P.cfg.settings.curve
    return math.floor(c.base * (c.growth ^ (level - 1)))
end

function P.levelOf(xp)
    local c = P.cfg.settings.curve
    local lvl, left = 1, xp
    while lvl < c.maxLevel do
        local n = P.need(lvl)
        if left < n then break end
        left = left - n
        lvl = lvl + 1
    end
    if lvl >= c.maxLevel then return lvl, 0, 0 end
    return lvl, left, P.need(lvl)
end

function P.titleOf(level)
    local t = ''
    for _, l in ipairs(P.cfg.levels) do if level >= l.level and l.title ~= '' then t = l.title end end
    return t
end

-- ─── Joueurs ─────────────────────────────────────────────────────────────────
local function dayKey() return os.date('%Y-%m-%d') end
local function weekKey() return os.date('%Y-W%W') end

local function hash(s) local h = 5381 for i = 1, #s do h = (h * 33 + s:byte(i)) % 2147483647 end return h end

function P.get(ident, name)
    local r = P.rows[ident]
    if r then if name and name ~= '' then r.name = name end return r end
    local row = MySQL.single.await('SELECT * FROM minigames_players WHERE identifier = ?', { ident })
    if not row then
        row = { identifier = ident, name = name or '', xp = 0, plays = 0, wins = 0, points = 0, streak = 0, best_streak = 0, rewarded_level = 1, milestones = 0, season_xp = 0 }
        MySQL.insert.await('INSERT INTO minigames_players (identifier, name) VALUES (?, ?)', { ident, name or '' })
    end
    row.ch = MG.decode(row.challenges, {}) ; row.ach = MG.decode(row.achievements, {})
    if name and name ~= '' then row.name = name end
    P.rows[ident] = row
    return row
end

function P.save(ident)
    local r = P.rows[ident]
    if not r then return end
    MySQL.update('UPDATE minigames_players SET name=?, xp=?, plays=?, wins=?, points=?, streak=?, best_streak=?, rewarded_level=?, milestones=?, season_xp=?, challenges=?, achievements=? WHERE identifier=?',
        { r.name or '', r.xp, r.plays, r.wins, r.points, r.streak, r.best_streak, r.rewarded_level, r.milestones, r.season_xp, json.encode(r.ch or {}), json.encode(r.ach or {}), ident })
end

AddEventHandler('playerDropped', function()
    local x = ESX.GetPlayerFromId(source)
    if x and P.rows[x.identifier] then P.save(x.identifier) P.rows[x.identifier] = nil end
end)

-- ─── Récompenses (argent + coins boutique), mises en attente si le joueur est hors-ligne ───
local function giveNow(x, money, coins)
    if money > 0 then x.addAccountMoney(Config.RewardAccount, money, 'minigames-progress') end
    if coins > 0 then
        local ok = false
        if Config.CoinsGrant and GetResourceState('pickax_core') == 'started' then
            local s, res = pcall(function() return exports['pickax_core']:BoutiqueGrantCoins(x.identifier, coins) end)
            ok = s and res == true
        end
        return ok
    end
    return true
end

function P.grant(ident, money, coins, label)
    money, coins = math.floor(money or 0), math.floor(coins or 0)
    if money <= 0 and coins <= 0 then return end
    local x = ESX.GetPlayerFromIdentifier(ident)
    if x then
        local okCoins = giveNow(x, money, coins)
        if not okCoins and coins > 0 then
            MySQL.insert('INSERT INTO minigames_pending (identifier, money, coins, label) VALUES (?, 0, ?, ?)', { ident, coins, label or '' })
        end
        return
    end
    MySQL.insert('INSERT INTO minigames_pending (identifier, money, coins, label) VALUES (?, ?, ?, ?)', { ident, money, coins, label or '' })
end

local function deliverPending(x)
    local rows = MySQL.query.await('SELECT id, money, coins FROM minigames_pending WHERE identifier = ?', { x.identifier }) or {}
    if #rows == 0 then return end
    local m, c = 0, 0
    for _, r in ipairs(rows) do m = m + r.money; c = c + r.coins end
    if m > 0 then x.addAccountMoney(Config.RewardAccount, m, 'minigames-pending') end
    local coinsOk = c == 0 or giveNow(x, 0, c)
    if coinsOk then MySQL.update('DELETE FROM minigames_pending WHERE identifier = ?', { x.identifier })
    else MySQL.update('UPDATE minigames_pending SET money = 0 WHERE identifier = ?', { x.identifier }) end
    if m > 0 or coinsOk then MG.notify(x.source, ('~g~Mini-jeux : récompenses reçues (%s%d%s)'):format(Config.Currency, m, c > 0 and coinsOk and (' + ' .. c .. ' coins') or '')) end
end
AddEventHandler('esx:playerLoaded', function(src, x)
    x = x or ESX.GetPlayerFromId(src)
    if x then SetTimeout(8000, function() deliverPending(x) end) end
end)

-- ─── Semaine / séries ────────────────────────────────────────────────────────
function P.featured()
    local w = P.cfg.settings.weekly
    if not w.enabled then return nil end
    if w.mode == 'fixed' then return MG.Defs[w.gameId] and MG.Defs[w.gameId].enabled and w.gameId or nil end
    local ids = {}
    for id, d in pairs(MG.Defs) do if d.enabled then ids[#ids + 1] = id end end
    if #ids == 0 then return nil end
    table.sort(ids)
    return ids[(hash(weekKey()) % #ids) + 1]
end

-- Multiplicateur d'XP et de gains pour une partie (série de victoires + mini-jeu de la semaine)
function P.multiplier(ident, def, won)
    local r = P.get(ident)
    local x = P.cfg.settings.xp
    local mult, streak = 1.0, won and (r.streak + 1) or 0
    if won and streak > 1 and x.streakPct > 0 then mult = mult * (1 + x.streakPct * math.min(streak - 1, x.streakMax) / 100) end
    if def and P.featured() == def.id then mult = mult * P.cfg.settings.weekly.mult end
    return mult, streak
end

-- ─── Défis du jour / de la semaine ───────────────────────────────────────────
local function pickChallenges(ident, scope, count)
    local pool = {}
    for _, c in ipairs(P.cfg.challenges) do if c.enabled and c.scope == scope then pool[#pool + 1] = c end end
    if #pool <= count then return pool end
    local key = scope == 'daily' and dayKey() or weekKey()
    local keyed = {}
    for _, c in ipairs(pool) do keyed[#keyed + 1] = { c = c, h = hash(ident .. key .. c.id) } end
    table.sort(keyed, function(a, b) return a.h < b.h end)
    local out = {}
    for i = 1, count do out[i] = keyed[i].c end
    return out
end
P.DAILY_COUNT, P.WEEKLY_COUNT = 3, 2

local function roll(r)
    r.ch = r.ch or {}
    if r.ch.d ~= dayKey() then r.ch.d, r.ch.dp, r.ch.dd = dayKey(), {}, {} end
    if r.ch.w ~= weekKey() then r.ch.w, r.ch.wp, r.ch.wd = weekKey(), {}, {} end
end

local function matches(c, def) return c.game == 'any' or c.game == def.type or c.game == def.id end

-- ─── Enregistrement d'une partie ─────────────────────────────────────────────
-- info = { def, won, score, kills, mult, streak }
function P.record(ident, name, info)
    local cfg = P.cfg
    local r = P.get(ident, name)
    roll(r)
    local def = info.def
    local out = { xp = 0, done = {}, ach = {}, levelUps = {}, money = 0, coins = 0 }

    r.plays = r.plays + 1
    r.points = r.points + math.max(0, info.score or 0)
    if info.won then r.wins = r.wins + 1; r.streak = r.streak + 1; if r.streak > r.best_streak then r.best_streak = r.streak end else r.streak = 0 end
    out.streak = r.streak

    local oldLevel = P.levelOf(r.xp)
    local function addXp(n)
        n = math.floor(n)
        if n <= 0 then return end
        r.xp = r.xp + n
        if cfg.settings.season.enabled then r.season_xp = r.season_xp + n end
        out.xp = out.xp + n
    end
    local function reward(label, m, c)
        m, c = m or 0, c or 0
        if m <= 0 and c <= 0 then return end
        out.money, out.coins = out.money + m, out.coins + c
        P.grant(ident, m, c, label)
    end

    if cfg.settings.xp.enabled then
        local x = cfg.settings.xp
        local base = x.perGame + (info.won and x.win or 0) + x.perPoint * math.max(0, info.score or 0)
        base = math.min(base, x.maxPerGame)
        addXp(base * (info.mult or 1))
    end

    -- défis
    for _, scope in ipairs({ 'daily', 'weekly' }) do
        local pk, dk = scope == 'daily' and 'dp' or 'wp', scope == 'daily' and 'dd' or 'wd'
        for _, c in ipairs(pickChallenges(ident, scope, scope == 'daily' and P.DAILY_COUNT or P.WEEKLY_COUNT)) do
            if not r.ch[dk][c.id] and matches(c, def) then
                local add = (c.kind == 'plays' and 1) or (c.kind == 'wins' and (info.won and 1 or 0)) or (c.kind == 'points' and math.max(0, info.score or 0)) or (c.kind == 'kills' and (info.kills or 0)) or 0
                if add > 0 then
                    r.ch[pk][c.id] = (r.ch[pk][c.id] or 0) + add
                    if r.ch[pk][c.id] >= c.target then
                        r.ch[dk][c.id] = true
                        out.done[#out.done + 1] = c.name
                        addXp(c.xp)
                        reward('Défi : ' .. c.name, c.money, c.coins)
                    end
                end
            end
        end
    end

    -- niveaux
    local function levelCheck()
        local newLevel = P.levelOf(r.xp)
        if newLevel > r.rewarded_level then
            for lvl = r.rewarded_level + 1, newLevel do
                for _, l in ipairs(cfg.levels) do
                    if l.level == lvl then
                        out.levelUps[#out.levelUps + 1] = { level = lvl, title = l.title, money = l.money, coins = l.coins }
                        reward('Niveau ' .. lvl, l.money, l.coins)
                    end
                end
            end
            r.rewarded_level = newLevel
        end
        return newLevel
    end

    -- succès (peuvent donner de l'XP, donc un 2e passage niveau)
    local function achievementCheck()
        local level = P.levelOf(r.xp)
        local vals = { plays_total = r.plays, wins_total = r.wins, points_total = r.points, best_streak = r.best_streak, level = level }
        local got = false
        for _, a in ipairs(cfg.achievements) do
            if a.enabled and not r.ach[a.id] and (vals[a.kind] or 0) >= a.target then
                r.ach[a.id] = os.time()
                out.ach[#out.ach + 1] = a.name
                addXp(a.xp)
                reward('Succès : ' .. a.name, a.money, a.coins)
                got = true
            end
        end
        return got
    end
    levelCheck()
    if achievementCheck() then levelCheck() achievementCheck() end

    -- palier d'XP → coins
    local m = cfg.settings.milestone
    if m.enabled and m.xp > 0 then
        local count = math.floor(r.xp / m.xp)
        if count > r.milestones then
            local n = count - r.milestones
            r.milestones = count
            out.milestoneCount = n
            reward(('Palier de %d XP'):format(m.xp), m.money * n, m.coins * n)
        end
    end

    local level, cur, need = P.levelOf(r.xp)
    out.level, out.cur, out.need, out.title, out.xpTotal = level, cur, need, P.titleOf(level), r.xp
    out.levelUp = level > oldLevel
    P.save(ident)

    if out.levelUp and cfg.settings.announce.levels and level % 5 == 0 then
        TriggerClientEvent('esx:showNotification', -1, ('~b~Mini-jeux~s~ : %s passe niveau %d%s !'):format(r.name, level, out.title ~= '' and (' (' .. out.title .. ')') or ''))
    end
    return out
end

-- ─── Saisons ────────────────────────────────────────────────────────────────
function P.endSeason(manual)
    local rows = MySQL.query.await('SELECT identifier, name, season_xp FROM minigames_players WHERE season_xp > 0 ORDER BY season_xp DESC LIMIT 20') or {}
    local rewards = P.cfg.settings.season.rewards
    local lines = {}
    for rank, row in ipairs(rows) do
        for _, rw in ipairs(rewards) do
            if rw.rank == rank then
                P.grant(row.identifier, rw.money, rw.coins, ('Saison %d · #%d'):format(P.season.id, rank))
                lines[#lines + 1] = ('#%d %s'):format(rank, row.name)
            end
        end
    end
    MySQL.update.await('UPDATE minigames_players SET season_xp = 0')
    for _, r in pairs(P.rows) do r.season_xp = 0 end
    MG.log(nil, manual and 'saison terminée (manuel)' or 'saison terminée', '', ('Saison %d : %s'):format(P.season.id, table.concat(lines, ', ')))
    if #lines > 0 then
        TriggerClientEvent('esx:showNotification', -1, ('~b~Mini-jeux~s~ : saison %d terminée ! %s'):format(P.season.id, table.concat(lines, ' · ')))
    end
    P.season = { id = P.season.id + 1, start = os.time() }
    persistSeason()
end

CreateThread(function()
    while not MG.ready do Wait(500) end
    while true do
        Wait(60000)
        local s = P.cfg.settings.season
        if s.enabled and os.time() >= P.season.start + s.days * 86400 then P.endSeason(false) end
    end
end)

-- ─── Callbacks joueur ───────────────────────────────────────────────────────
function P.brief(src)
    local ident = MG.identifier(src)
    if not ident then return nil end
    local r = P.get(ident, MG.playerName(src))
    local level, cur, need = P.levelOf(r.xp)
    return { level = level, cur = cur, need = need, xp = r.xp, title = P.titleOf(level) }
end

ESX.RegisterServerCallback('minigames:profile', function(src, cb)
    local ident = MG.identifier(src)
    if not ident then return cb({ ok = false }) end
    local r = P.get(ident, MG.playerName(src))
    roll(r)
    local cfg = P.cfg
    local level, cur, need = P.levelOf(r.xp)
    local function chList(scope)
        local out = {}
        local pk, dk = scope == 'daily' and 'dp' or 'wp', scope == 'daily' and 'dd' or 'wd'
        for _, c in ipairs(pickChallenges(ident, scope, scope == 'daily' and P.DAILY_COUNT or P.WEEKLY_COUNT)) do
            out[#out + 1] = { id = c.id, name = c.name, kind = c.kind, game = c.game, target = c.target, progress = math.min(c.target, r.ch[pk][c.id] or 0), done = r.ch[dk][c.id] == true, xp = c.xp, money = c.money, coins = c.coins }
        end
        return out
    end
    local ach = {}
    for _, a in ipairs(cfg.achievements) do
        if a.enabled then ach[#ach + 1] = { id = a.id, name = a.name, desc = a.desc, target = a.target, kind = a.kind, xp = a.xp, money = a.money, coins = a.coins, unlocked = r.ach[a.id] ~= nil } end
    end
    local levels = {}
    for _, l in ipairs(cfg.levels) do levels[#levels + 1] = { level = l.level, title = l.title, money = l.money, coins = l.coins, reached = level >= l.level } end
    local seasonTop = MySQL.query.await('SELECT name, season_xp FROM minigames_players WHERE season_xp > 0 ORDER BY season_xp DESC LIMIT 10') or {}
    local globalTop = MySQL.query.await('SELECT name, xp, wins FROM minigames_players WHERE xp > 0 ORDER BY xp DESC LIMIT 10') or {}
    local fid = P.featured()
    local s = cfg.settings.season
    local m = cfg.settings.milestone
    cb({
        ok = true, name = r.name,
        level = level, cur = cur, need = need, xp = r.xp, title = P.titleOf(level), maxLevel = cfg.settings.curve.maxLevel,
        plays = r.plays, wins = r.wins, points = r.points, streak = r.streak, bestStreak = r.best_streak,
        milestone = m.enabled and { xp = m.xp, coins = m.coins, money = m.money, into = r.xp % m.xp, claimed = r.milestones } or nil,
        daily = chList('daily'), weekly = chList('weekly'), achievements = ach, levels = levels,
        season = s.enabled and { id = P.season.id, endsIn = math.max(0, P.season.start + s.days * 86400 - os.time()), xp = r.season_xp, top = seasonTop, rewards = s.rewards } or nil,
        globalTop = globalTop, featured = fid and { id = fid, name = MG.Defs[fid].name, mult = cfg.settings.weekly.mult } or nil,
        streakPct = cfg.settings.xp.streakPct, currency = Config.Currency,
    })
end)

-- ─── Callbacks admin (édition en jeu) ───────────────────────────────────────
local function cbAdmin(name, fn)
    ESX.RegisterServerCallback('minigames:' .. name, function(src, cb, ...)
        if not MG.isAdmin(src) then return cb({ ok = false, error = 'Accès refusé' }) end
        local ok, res = pcall(fn, src, ...)
        if not ok then print('^1[minigames]^7 ' .. name .. ' : ' .. tostring(res)) return cb({ ok = false, error = 'Erreur serveur' }) end
        cb(res)
    end)
end

cbAdmin('progGet', function()
    local games = {}
    for id, d in pairs(MG.Defs) do games[#games + 1] = { id = id, name = d.name } end
    table.sort(games, function(a, b) return a.name < b.name end)
    return { ok = true, cfg = P.cfg, games = games, season = { id = P.season.id, start = P.season.start }, featured = P.featured() }
end)

cbAdmin('progSave', function(src, data)
    local new = P.sanitize(data, P.cfg)
    P.cfg = new
    persistCfg()
    MG.log(src, 'progression modifiée', '', '')
    return { ok = true, cfg = P.cfg }
end)

cbAdmin('seasonEnd', function(src)
    P.endSeason(true)
    return { ok = true }
end)

cbAdmin('progReset', function(src)
    P.cfg = copy(Config.Progress)
    persistCfg()
    MG.log(src, 'progression réinitialisée', '', '')
    return { ok = true, cfg = P.cfg }
end)
