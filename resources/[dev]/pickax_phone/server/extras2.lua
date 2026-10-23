-- Classements des jeux, actualités, loto
local function say(src, msg) if src == 0 then print(msg) else TriggerClientEvent('chat:addMessage', src, { args = { 'Aura', msg } }) end end

CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS aura_scores (
        game VARCHAR(16) NOT NULL, identifier VARCHAR(80) NOT NULL, name VARCHAR(40) NOT NULL, score INT NOT NULL, updated BIGINT NOT NULL, PRIMARY KEY (game, identifier), INDEX (game, score))]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS aura_news (
        id INT AUTO_INCREMENT PRIMARY KEY, title VARCHAR(100) NOT NULL, body TEXT NULL, image TEXT NULL, author VARCHAR(60) NOT NULL, author_id VARCHAR(80) NULL,
        source VARCHAR(40) NULL, breaking TINYINT(1) NOT NULL DEFAULT 0, created BIGINT NOT NULL, INDEX (created))]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS aura_loto_tickets (
        id INT AUTO_INCREMENT PRIMARY KEY, identifier VARCHAR(80) NOT NULL, nums VARCHAR(40) NOT NULL, draw INT NOT NULL, won INT NOT NULL DEFAULT 0, matches TINYINT NOT NULL DEFAULT 0, created BIGINT NOT NULL, INDEX (identifier, draw))]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS aura_loto_state (
        id TINYINT NOT NULL PRIMARY KEY, pool BIGINT NOT NULL, next_draw BIGINT NOT NULL, draw INT NOT NULL, last TEXT NULL)]])
end)

-- ═════════════════ CLASSEMENTS ═════════════════
local GAMES = { snake = 500, ['2048'] = 3000000, mines = 1000, flappy = 2000, memory = 100, c4 = 100, ttt = 1000 }
local function shortName(id)
    local n = Aura.Name(id) or 'Joueur'
    local first, last = n:match('^(%S+)%s+(%S+)')
    return first and (first .. ' ' .. last:sub(1, 1) .. '.') or n
end

lib.callback.register('aura:scoreSubmit', function(src, game, score)
    local id = Aura.ident[src]; if not id or not GAMES[game] then return false end
    score = math.floor(tonumber(score) or 0)
    if score < 1 or score > GAMES[game] then return false end
    MySQL.query.await('INSERT INTO aura_scores (game, identifier, name, score, updated) VALUES (?,?,?,?,?) ON DUPLICATE KEY UPDATE score = GREATEST(score, VALUES(score)), name = VALUES(name), updated = VALUES(updated)', { game, id, shortName(id), score, Aura.Now() })
    return true
end)

lib.callback.register('aura:scoreTop', function(src, game)
    local id = Aura.ident[src]; if not id or not GAMES[game] then return {} end
    local rows = MySQL.query.await('SELECT name, score, (identifier = ?) AS me FROM aura_scores WHERE game = ? ORDER BY score DESC LIMIT 10', { id, game }) or {}
    for _, r in ipairs(rows) do r.me = r.me == 1 or r.me == true end
    return rows
end)

-- ═════════════════ ACTUALITÉS ═════════════════
local function canPost(src)
    if Config.News.adminCanPost and Aura.IsAdmin(src) then return true, 'Rédaction' end
    local x = ESX.GetPlayerFromId(src)
    if x and x.job then for _, j in ipairs(Config.News.jobs) do if j == x.job.name then return true, x.job.label end end end
    return false
end

lib.callback.register('aura:newsList', function(src, before)
    local id = Aura.ident[src]; if not id then return nil end
    local rows
    if before and tonumber(before) then rows = MySQL.query.await('SELECT id, title, body, image, author, source, breaking, created FROM aura_news WHERE id < ? ORDER BY id DESC LIMIT 20', { tonumber(before) })
    else rows = MySQL.query.await('SELECT id, title, body, image, author, source, breaking, created FROM aura_news ORDER BY id DESC LIMIT 20') end
    return { list = rows or {}, canPost = canPost(src) and true or false, admin = Aura.IsAdmin(src) }
end)

lib.callback.register('aura:newsPost', function(src, d)
    local id = Aura.ident[src]; if not id or type(d) ~= 'table' then return false end
    local ok, source = canPost(src); if not ok then return false, 'Réservé aux journalistes' end
    local title = Aura.Clamp(Aura.Trim(d.title), 100); if #title < 4 then return false, 'Titre trop court' end
    local image = (type(d.image) == 'string' and d.image:match('^https?://')) and Aura.Clamp(d.image, 500) or nil
    local breaking = d.breaking and true or false
    local nid = MySQL.insert.await('INSERT INTO aura_news (title, body, image, author, author_id, source, breaking, created) VALUES (?,?,?,?,?,?,?,?)', { title, Aura.Clamp(d.body, 2000), image, shortName(id), id, source, breaking and 1 or 0, Aura.Now() })
    if breaking and Config.News.breakingToAll then
        for pid in pairs(Aura.src) do
            local p = Aura.phones[pid]
            if p and not p.settings.airplane then Aura.Push(pid, 'notify', { app = 'news', title = '🔴 ' .. (source or 'Actualités'), body = title }) end
        end
    end
    return nid
end)

lib.callback.register('aura:newsDelete', function(src, nid)
    local id = Aura.ident[src]; if not id then return false end
    if Aura.IsAdmin(src) then MySQL.update.await('DELETE FROM aura_news WHERE id = ?', { tonumber(nid) or 0 })
    else MySQL.update.await('DELETE FROM aura_news WHERE id = ? AND author_id = ?', { tonumber(nid) or 0, id }) end
    return true
end)

-- ═════════════════ LOTO ═════════════════
local L = Config.Loto
local state = { pool = L.jackpotSeed, next = os.time() + L.drawEveryMinutes * 60, draw = 1, last = nil }

local function saveState()
    MySQL.query('INSERT INTO aura_loto_state (id, pool, next_draw, draw, last) VALUES (1,?,?,?,?) ON DUPLICATE KEY UPDATE pool = VALUES(pool), next_draw = VALUES(next_draw), draw = VALUES(draw), last = VALUES(last)', { state.pool, state.next, state.draw, state.last and Aura.Json(state.last) or nil })
end

local function creditBank(identifier, amount)
    local src = Aura.src[identifier]
    local x = src and ESX.GetPlayerFromId(src)
    if x then x.addAccountMoney(Config.Bank.account, amount) return true end
    local row = MySQL.single.await('SELECT accounts FROM users WHERE identifier = ?', { identifier })
    if not row then return false end
    local acc = Aura.Unjson(row.accounts, {})
    acc[Config.Bank.account] = (tonumber(acc[Config.Bank.account]) or 0) + amount
    MySQL.update.await('UPDATE users SET accounts = ? WHERE identifier = ?', { json.encode(acc), identifier })
    return true
end

local function parseNums(s) local t = {} for n in tostring(s):gmatch('%d+') do t[#t + 1] = tonumber(n) end return t end

local function runDraw()
    local pool = {}
    for i = 1, L.max do pool[i] = i end
    local nums = {}
    for _ = 1, L.pick do nums[#nums + 1] = table.remove(pool, math.random(#pool)) end
    table.sort(nums)
    local set = {}
    for _, n in ipairs(nums) do set[n] = true end
    local tickets = MySQL.query.await('SELECT id, identifier, nums FROM aura_loto_tickets WHERE draw = ?', { state.draw }) or {}
    local jackpotWinners, total = {}, 0
    for _, t in ipairs(tickets) do
        local m = 0
        for _, n in ipairs(parseNums(t.nums)) do if set[n] then m = m + 1 end end
        t.m = m
        if m == L.pick then jackpotWinners[#jackpotWinners + 1] = t end
    end
    local jackpotEach = #jackpotWinners > 0 and math.floor(state.pool / #jackpotWinners) or 0
    local winners = 0
    for _, t in ipairs(tickets) do
        local gain = 0
        if t.m == L.pick then gain = jackpotEach
        elseif L.payouts[t.m] then gain = L.price * L.payouts[t.m] end
        MySQL.update('UPDATE aura_loto_tickets SET matches = ?, won = ? WHERE id = ?', { t.m, gain, t.id })
        if gain > 0 then
            winners = winners + 1; total = total + gain
            if creditBank(t.identifier, gain) then
                Aura.LogTx(t.identifier, 'in', gain, 'Loto', ('Loto : %d bon%s numéro%s'):format(t.m, t.m > 1 and 's' or '', t.m > 1 and 's' or ''))
                Aura.Push(t.identifier, 'notify', { app = 'loto', title = '🎉 Loto', body = ('%d bons numéros : vous gagnez %s $ !'):format(t.m, gain) })
            end
        end
    end
    state.last = { draw = state.draw, nums = nums, tickets = #tickets, winners = winners, jackpot = #jackpotWinners > 0 and jackpotEach or 0, at = os.time() }
    if #jackpotWinners > 0 then state.pool = L.jackpotSeed end
    state.draw = state.draw + 1
    state.next = os.time() + L.drawEveryMinutes * 60
    saveState()
end

CreateThread(function()
    if not L.enabled then return end
    Wait(2500)
    local r = MySQL.single.await('SELECT pool, next_draw, draw, last FROM aura_loto_state WHERE id = 1')
    if r then state.pool = r.pool; state.next = r.next_draw; state.draw = r.draw; state.last = Aura.Unjson(r.last, nil) else saveState() end
    while true do
        Wait(10000)
        if os.time() >= state.next then runDraw() end
    end
end)

lib.callback.register('aura:lotoInfo', function(src)
    local id = Aura.ident[src]; if not id or not L.enabled then return nil end
    local mine = MySQL.query.await('SELECT id, nums, draw, won, matches, created FROM aura_loto_tickets WHERE identifier = ? ORDER BY id DESC LIMIT 15', { id }) or {}
    return { price = L.price, pick = L.pick, max = L.max, pool = state.pool, next = state.next * 1000, now = os.time() * 1000, draw = state.draw, last = state.last, tickets = mine, payouts = L.payouts }
end)

lib.callback.register('aura:lotoBuy', function(src, nums)
    local id = Aura.ident[src]; if not id or not L.enabled then return false end
    local x = ESX.GetPlayerFromId(src); if not x then return false end
    local chosen, seen = {}, {}
    if type(nums) == 'table' and #nums > 0 then
        for _, n in ipairs(nums) do n = math.floor(tonumber(n) or 0); if n >= 1 and n <= L.max and not seen[n] then seen[n] = true; chosen[#chosen + 1] = n end end
        if #chosen ~= L.pick then return false, ('Choisissez %d numéros'):format(L.pick) end
    else
        local pool = {}
        for i = 1, L.max do pool[i] = i end
        for _ = 1, L.pick do chosen[#chosen + 1] = table.remove(pool, math.random(#pool)) end
    end
    table.sort(chosen)
    local n = MySQL.scalar.await('SELECT COUNT(*) FROM aura_loto_tickets WHERE identifier = ? AND draw = ?', { id, state.draw }) or 0
    if n >= 10 then return false, 'Maximum 10 tickets par tirage' end
    if x.getAccount(Config.Bank.account).money < L.price then return false, 'Solde insuffisant' end
    x.removeAccountMoney(Config.Bank.account, L.price)
    Aura.LogTx(id, 'out', -L.price, 'Loto', 'Ticket de loto')
    state.pool = state.pool + math.floor(L.price * L.sharePool)
    MySQL.insert.await('INSERT INTO aura_loto_tickets (identifier, nums, draw, created) VALUES (?,?,?,?)', { id, table.concat(chosen, ' '), state.draw, Aura.Now() })
    saveState()
    return { nums = chosen }
end)

RegisterCommand('phone_lotodraw', function(src)
    if src ~= 0 and not Aura.IsAdmin(src) then return end
    runDraw(); say(src, 'Tirage du loto lancé.')
end, false)
