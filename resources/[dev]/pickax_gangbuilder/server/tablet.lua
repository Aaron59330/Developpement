-- ─────────────────────────────── Tablette de gang ───────────────────────────────
-- Données de la tablette (F7 → Tablette) : tableau de bord, territoires, quêtes, guerres entre gangs, classement, actualités.
-- Tout est calculé côté serveur : le client n'envoie que des demandes (proposer / accepter une guerre, réclamer une quête).

local function fail(msg) return { ok = false, error = msg } end
local T = function() return Config.Tablet end

local News = {}           -- actualités visibles par tous les gangs (mémoire)
local Wars = {}           -- [id] = guerre en attente / en cours
local lastDeath = {}      -- [victime] = os.time() du dernier kill compté
local ready = false

local function label(name) return GB.Gangs[name] and GB.Gangs[name].label or name end

-- ─────────────────────────────── Actualités ───────────────────────────────
function GB.news(text, kind)
    News[#News + 1] = { t = os.time(), text = tostring(text):sub(1, 200), kind = kind or 'info' }
    while #News > (T().NewsMax or 30) do table.remove(News, 1) end
end

local function notifyGang(name, msg)
    for _, s in ipairs(GB.onlineMembers(name)) do GB.notify(s, msg) end
end

-- ─────────────────────────────── Base de données ───────────────────────────────
MySQL.ready(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS gangbuilder_quests (
        gang_name VARCHAR(50) NOT NULL, qkey VARCHAR(20) NOT NULL, quest_id VARCHAR(40) NOT NULL,
        progress INT NOT NULL DEFAULT 0, claimed TINYINT(1) NOT NULL DEFAULT 0,
        PRIMARY KEY (gang_name, qkey, quest_id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS gangbuilder_wars (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, gang_a VARCHAR(50) NOT NULL, gang_b VARCHAR(50) NOT NULL,
        target INT NOT NULL, duration INT NOT NULL, stake INT NOT NULL DEFAULT 0, status VARCHAR(12) NOT NULL DEFAULT 'pending',
        kills_a INT NOT NULL DEFAULT 0, kills_b INT NOT NULL DEFAULT 0, created_at INT NOT NULL, started_at INT NOT NULL DEFAULT 0,
        ends_at INT NOT NULL DEFAULT 0, winner VARCHAR(50) DEFAULT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    for _, w in ipairs(MySQL.query.await("SELECT * FROM gangbuilder_wars WHERE status IN ('pending','active')") or {}) do Wars[w.id] = w end
    ready = true
end)

-- ─────────────────────────────── Quêtes ───────────────────────────────
local function periodKey(kind)
    return kind == 'weekly' and os.date('!%Y-W%W') or os.date('!%Y%m%d')
end

local function hash(s)
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 2147483647 end
    return h
end

-- Tirage déterministe (gang + période) : tous les membres voient les mêmes quêtes
local function pick(pool, count, seed)
    local idx, out = {}, {}
    for i = 1, #pool do idx[i] = i end
    local x = seed
    for i = #idx, 2, -1 do
        x = (x * 1103515245 + 12345) % 2147483648
        local j = (x % i) + 1
        idx[i], idx[j] = idx[j], idx[i]
    end
    for i = 1, math.min(count, #idx) do out[#out + 1] = pool[idx[i]] end
    return out
end

local function activeQuests(gangName)
    local Q, list = T().Quests, {}
    for _, per in ipairs({ 'daily', 'weekly' }) do
        local key = periodKey(per)
        local pool = per == 'daily' and Q.Daily or Q.Weekly
        for _, q in ipairs(pick(pool, per == 'daily' and Q.DailyCount or Q.WeeklyCount, hash(gangName .. key))) do
            list[#list + 1] = { def = q, qkey = key, period = per }
        end
    end
    return list
end

function GB.questProgress(gangName, metric, amount)
    if not ready or not T().Enabled or not GB.Gangs[gangName] then return end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end
    for _, aq in ipairs(activeQuests(gangName)) do
        if aq.def.metric == metric then
            MySQL.update('INSERT INTO gangbuilder_quests (gang_name, qkey, quest_id, progress) VALUES (?, ?, ?, LEAST(?, ?)) ON DUPLICATE KEY UPDATE progress = IF(claimed = 1, progress, LEAST(?, progress + ?))',
                { gangName, aq.qkey, aq.def.id, aq.def.target, amount, aq.def.target, amount })
        end
    end
end

local function questList(gangName)
    local rows = {}
    for _, r in ipairs(MySQL.query.await('SELECT qkey, quest_id, progress, claimed FROM gangbuilder_quests WHERE gang_name = ? AND qkey IN (?, ?)', { gangName, periodKey('daily'), periodKey('weekly') }) or {}) do
        rows[r.qkey .. ':' .. r.quest_id] = r
    end
    local out = {}
    for _, aq in ipairs(activeQuests(gangName)) do
        local r = rows[aq.qkey .. ':' .. aq.def.id]
        local d = aq.def
        out[#out + 1] = {
            id = d.id, qkey = aq.qkey, period = aq.period, label = d.label, desc = d.desc, metric = d.metric, target = d.target,
            progress = r and tonumber(r.progress) or 0, claimed = r and GB.flag(r.claimed) or false, reward = d.reward, rep = d.rep,
        }
    end
    return out
end

ESX.RegisterServerCallback('gangbuilder:tablet:claim', function(src, cb, qkey, questId)
    local gang, _, xPlayer = GB.gangOf(src)
    if not gang then return cb(fail('Tu n\'es dans aucun gang')) end
    for _, q in ipairs(questList(gang.name)) do
        if q.id == questId and q.qkey == qkey then
            if q.claimed then return cb(fail('Récompense déjà récupérée')) end
            if q.progress < q.target then return cb(fail('Quête non terminée')) end
            local n = MySQL.update.await('UPDATE gangbuilder_quests SET claimed = 1 WHERE gang_name = ? AND qkey = ? AND quest_id = ? AND claimed = 0 AND progress >= ?', { gang.name, qkey, questId, q.target }) or 0
            if n < 1 then return cb(fail('Récompense déjà récupérée')) end
            local account = T().Quests.RewardAccount == 'money' and 'money' or 'dirty'
            GB.treasuryAdd(gang.name, account, q.reward)
            GB.addRep(gang.name, q.rep)
            GB.log(gang.name, xPlayer, 'quest_done', ('%s : %d$'):format(q.label, q.reward))
            GB.news(('%s a terminé la quête « %s ».'):format(gang.label, q.label), 'quest')
            return cb({ ok = true, reward = q.reward, rep = q.rep })
        end
    end
    cb(fail('Quête introuvable'))
end)

-- ─────────────────────────────── Guerres entre gangs ───────────────────────────────
local function warOf(gangName)
    for id, w in pairs(Wars) do
        if w.gang_a == gangName or w.gang_b == gangName then return id, w end
    end
end

local function removeRep(name, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount > 0 then MySQL.update('UPDATE gangbuilder_gangs SET rep = GREATEST(rep - ?, 0) WHERE name = ?', { amount, name }) end
end

local function saveWar(w)
    MySQL.update('UPDATE gangbuilder_wars SET status = ?, kills_a = ?, kills_b = ?, started_at = ?, ends_at = ?, winner = ? WHERE id = ?',
        { w.status, w.kills_a, w.kills_b, w.started_at or 0, w.ends_at or 0, w.winner, w.id })
end

local function finishWar(w, reason)
    Wars[w.id] = nil
    local a, b = w.gang_a, w.gang_b
    local pot = (w.stake or 0) * 2
    w.status = 'done'
    if w.kills_a == w.kills_b or not (GB.Gangs[a] and GB.Gangs[b]) then
        w.winner = nil
        if w.stake > 0 then
            if GB.Gangs[a] then GB.treasuryAdd(a, 'dirty', w.stake) end
            if GB.Gangs[b] then GB.treasuryAdd(b, 'dirty', w.stake) end
        end
        GB.news(('Guerre %s / %s : égalité (%d - %d), mises rendues.'):format(label(a), label(b), w.kills_a, w.kills_b), 'war')
        notifyGang(a, '~y~Guerre terminée : égalité, mise rendue.'); notifyGang(b, '~y~Guerre terminée : égalité, mise rendue.')
    else
        local win = w.kills_a > w.kills_b and a or b
        local lose = win == a and b or a
        w.winner = win
        if pot > 0 then GB.treasuryAdd(win, 'dirty', pot) end
        GB.addRep(win, T().Wars.RepWin); removeRep(lose, T().Wars.RepLoss)
        GB.questProgress(win, 'war_win', 1)
        GB.log(win, nil, 'war_win', ('contre %s : %d - %d%s'):format(label(lose), math.max(w.kills_a, w.kills_b), math.min(w.kills_a, w.kills_b), pot > 0 and (' · +' .. pot .. '$') or ''))
        GB.log(lose, nil, 'war_loss', ('contre %s : %d - %d'):format(label(win), math.max(w.kills_a, w.kills_b), math.min(w.kills_a, w.kills_b)))
        GB.news(('%s remporte la guerre contre %s (%d - %d)%s.'):format(label(win), label(lose), math.max(w.kills_a, w.kills_b), math.min(w.kills_a, w.kills_b), pot > 0 and (' et empoche ' .. pot .. ' $') or ''), 'war')
        notifyGang(win, ('~g~Victoire~s~ dans la guerre contre ~y~%s~s~%s !'):format(label(lose), pot > 0 and (' (~g~+' .. pot .. '$~s~)') or ''))
        notifyGang(lose, ('~r~Défaite~s~ dans la guerre contre ~y~%s~s~.'):format(label(win)))
    end
    saveWar(w)
end

local function bureau(gang, grade) return grade >= (gang.boss_grade or 0) end

ESX.RegisterServerCallback('gangbuilder:tablet:warPropose', function(src, cb, target, kills, minutes, stake)
    local W = T().Wars
    local gang, grade, xPlayer = GB.gangOf(src)
    if not gang then return cb(fail('Tu n\'es dans aucun gang')) end
    if not W.Enabled then return cb(fail('Les guerres sont désactivées')) end
    if not bureau(gang, grade) then return cb(fail('Réservé au bureau du gang')) end
    target = tostring(target or '')
    local other = GB.Gangs[target]
    if not other or target == gang.name then return cb(fail('Gang invalide')) end
    kills, minutes, stake = math.floor(tonumber(kills) or 0), math.floor(tonumber(minutes) or 0), math.floor(tonumber(stake) or 0)
    local okK, okM = false, false
    for _, k in ipairs(W.Targets) do if k == kills then okK = true end end
    for _, m in ipairs(W.Durations) do if m == minutes then okM = true end end
    if not okK or not okM then return cb(fail('Paramètres invalides')) end
    if stake < 0 or stake > W.MaxStake then return cb(fail('Mise invalide (max ' .. W.MaxStake .. ' $)')) end
    if warOf(gang.name) then return cb(fail('Ton gang a déjà une guerre en cours ou en attente')) end
    if warOf(target) then return cb(fail('Ce gang a déjà une guerre en cours ou en attente')) end
    if #GB.onlineMembers(target) == 0 then return cb(fail('Aucun membre de ce gang n\'est en ligne')) end
    local since = os.time() - W.Cooldown * 60
    local recent = MySQL.scalar.await("SELECT COUNT(*) FROM gangbuilder_wars WHERE status = 'done' AND ends_at > ? AND ((gang_a = ? AND gang_b = ?) OR (gang_a = ? AND gang_b = ?))", { since, gang.name, target, target, gang.name }) or 0
    if (tonumber(recent) or 0) > 0 then return cb(fail('Vous vous êtes déjà affrontés récemment : attendez un peu')) end
    local _, dirty = GB.treasury(gang.name)
    if dirty < stake then return cb(fail('Pas assez d\'argent sale dans la trésorerie pour cette mise')) end
    local id = MySQL.insert.await('INSERT INTO gangbuilder_wars (gang_a, gang_b, target, duration, stake, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)', { gang.name, target, kills, minutes, stake, 'pending', os.time() })
    Wars[id] = { id = id, gang_a = gang.name, gang_b = target, target = kills, duration = minutes, stake = stake, status = 'pending', kills_a = 0, kills_b = 0, created_at = os.time(), started_at = 0, ends_at = 0 }
    GB.log(gang.name, xPlayer, 'war_propose', ('contre %s : %d kills, %d min, mise %d$'):format(label(target), kills, minutes, stake))
    notifyGang(target, ('~r~%s~s~ vous défie : guerre à %d kills, mise ~g~%d$~s~. Répondez dans la tablette (F7).'):format(gang.label, kills, stake))
    cb({ ok = true })
end)

ESX.RegisterServerCallback('gangbuilder:tablet:warRespond', function(src, cb, id, accept)
    local gang, grade = GB.gangOf(src)
    if not gang then return cb(fail('Tu n\'es dans aucun gang')) end
    local w = Wars[tonumber(id)]
    if not w or w.status ~= 'pending' then return cb(fail('Proposition expirée')) end
    if w.gang_a == gang.name then   -- le défieur annule
        if not bureau(gang, grade) then return cb(fail('Réservé au bureau du gang')) end
        Wars[w.id] = nil
        w.status = 'cancelled'; saveWar(w)
        return cb({ ok = true })
    end
    if w.gang_b ~= gang.name then return cb(fail('Cette proposition ne te concerne pas')) end
    if not bureau(gang, grade) then return cb(fail('Réservé au bureau du gang')) end
    if not accept then
        Wars[w.id] = nil
        w.status = 'refused'; saveWar(w)
        notifyGang(w.gang_a, ('~y~%s~s~ a refusé votre défi.'):format(gang.label))
        return cb({ ok = true })
    end
    if not GB.Gangs[w.gang_a] then Wars[w.id] = nil return cb(fail('Le gang adverse n\'existe plus')) end
    if w.stake > 0 then
        local _, da = GB.treasury(w.gang_a)
        local _, db = GB.treasury(w.gang_b)
        if da < w.stake then return cb(fail('Le gang adverse n\'a plus de quoi miser')) end
        if db < w.stake then return cb(fail('Pas assez d\'argent sale dans la trésorerie pour la mise')) end
        if not GB.treasuryRemove(w.gang_a, 'dirty', w.stake) then return cb(fail('Mise impossible')) end
        if not GB.treasuryRemove(w.gang_b, 'dirty', w.stake) then GB.treasuryAdd(w.gang_a, 'dirty', w.stake) return cb(fail('Mise impossible')) end
    end
    w.status, w.started_at = 'active', os.time()
    w.ends_at = w.started_at + w.duration * 60
    saveWar(w)
    GB.news(('Guerre déclarée : %s contre %s (premier à %d kills%s).'):format(label(w.gang_a), label(w.gang_b), w.target, w.stake > 0 and (', mise ' .. w.stake .. ' $') or ''), 'war')
    notifyGang(w.gang_a, ('~r~La guerre contre %s commence !~s~ Premier à %d kills (%d min).'):format(gang.label, w.target, w.duration))
    notifyGang(w.gang_b, ('~r~La guerre contre %s commence !~s~ Premier à %d kills (%d min).'):format(label(w.gang_a), w.target, w.duration))
    cb({ ok = true })
end)

-- Kills : l'événement vient du client de la victime (non fiable) → on recoupe côté serveur (distance, source de la mort, doublons)
AddEventHandler('playerDropped', function() lastDeath[source] = nil end)
RegisterNetEvent('esx:onPlayerDeath', function(data)
    local victim = source
    if type(data) ~= 'table' or not data.killedByPlayer then return end
    local killer = tonumber(data.killerServerId)
    local vg, kg = GB.PlayerGang[victim], killer and GB.PlayerGang[killer]
    if not vg or not kg or vg.name == kg.name or killer == victim then return end
    local _, w = warOf(vg.name)
    if not w or w.status ~= 'active' or not ((w.gang_a == vg.name and w.gang_b == kg.name) or (w.gang_b == vg.name and w.gang_a == kg.name)) then return end
    if (lastDeath[victim] or 0) + 10 > os.time() then return end
    local vp, kp = GetPlayerPed(victim), GetPlayerPed(killer)
    if not vp or vp == 0 or not kp or kp == 0 then return end
    if #(GetEntityCoords(vp) - GetEntityCoords(kp)) > (T().Wars.MaxKillDistance or 250.0) then return end
    local okSrc, srcPed = pcall(GetPedSourceOfDeath, vp)
    if okSrc and srcPed and srcPed ~= 0 and srcPed ~= kp and GetVehiclePedIsIn(kp, false) ~= srcPed then return end
    lastDeath[victim] = os.time()
    if kg.name == w.gang_a then w.kills_a = w.kills_a + 1 else w.kills_b = w.kills_b + 1 end
    saveWar(w)
    local msg = ('~r~Guerre~s~ : %s ~b~%d~s~ - ~b~%d~s~ %s (objectif %d)'):format(label(w.gang_a), w.kills_a, w.kills_b, label(w.gang_b), w.target)
    notifyGang(w.gang_a, msg); notifyGang(w.gang_b, msg)
    if w.kills_a >= w.target or w.kills_b >= w.target then finishWar(w) end
end)

CreateThread(function()
    while true do
        Wait(2000)
        if ready then
            local now = os.time()
            for _, w in pairs(Wars) do
                if w.status == 'pending' and (tonumber(w.created_at) or 0) + T().Wars.ProposalSeconds <= now then
                    Wars[w.id] = nil
                    w.status = 'expired'; saveWar(w)
                    notifyGang(w.gang_a, ('~y~%s~s~ n\'a pas répondu à votre défi.'):format(label(w.gang_b)))
                elseif w.status == 'active' and (tonumber(w.ends_at) or 0) <= now then
                    local ok, err = pcall(finishWar, w)
                    if not ok then Wars[w.id] = nil print(('^1[gangbuilder] erreur guerre : %s^0'):format(tostring(err))) end
                end
            end
        end
    end
end)

-- ─────────────────────────────── Données de la tablette ───────────────────────────────
local function warView(w)
    return {
        id = tonumber(w.id), a = w.gang_a, aLabel = label(w.gang_a), aColor = GB.Gangs[w.gang_a] and GB.Gangs[w.gang_a].color,
        b = w.gang_b, bLabel = label(w.gang_b), bColor = GB.Gangs[w.gang_b] and GB.Gangs[w.gang_b].color,
        target = tonumber(w.target), duration = tonumber(w.duration), stake = tonumber(w.stake),
        status = w.status, killsA = tonumber(w.kills_a) or 0, killsB = tonumber(w.kills_b) or 0,
        left = w.status == 'active' and math.max(0, (tonumber(w.ends_at) or 0) - os.time()) or nil,
        expiresIn = w.status == 'pending' and math.max(0, (tonumber(w.created_at) or 0) + T().Wars.ProposalSeconds - os.time()) or nil,
        winner = w.winner,
    }
end

local function snapshot(src)
    local gang, grade, xPlayer = GB.gangOf(src)
    if not gang then return nil end
    local money, dirty, rep = GB.treasury(gang.name)
    local seeMoney = grade >= (gang.settings.withdraw_grade or gang.boss_grade)
    local now = os.time()

    local online = {}
    for _, s in ipairs(GB.onlineMembers(gang.name)) do
        local x = ESX.GetPlayerFromId(s)
        if x then
            local _, g = GB.job2Of(x)
            online[#online + 1] = { name = GB.playerName(x), grade = g, gradeLabel = (gang.grades[g + 1] or {}).label or '' }
        end
    end
    table.sort(online, function(a, b) return a.grade > b.grade end)

    local Tc = Config.Territories
    local terr, mine = {}, 0
    for id, t in pairs(GB.Territories) do
        local o = t.owner and GB.Gangs[t.owner]
        local st = GB.territoryStatus and GB.territoryStatus(id) or nil
        if t.owner == gang.name then mine = mine + 1 end
        local interval = math.max(1, tonumber(t.settings and t.settings.interval) or Tc.IncomeInterval)
        terr[#terr + 1] = {
            id = id, label = t.label, x = t.coords.x, y = t.coords.y, radius = t.radius,
            owner = t.owner, ownerLabel = o and o.label or nil, ownerColor = o and o.color or nil, mine = t.owner == gang.name,
            protectedLeft = math.max(0, (t.protected_until or 0) - now),
            income = math.floor(tonumber(t.settings and t.settings.reward) or Tc.Reward), incomeEvery = interval,
            nextIncome = t.owner and math.max(0, (t.last_income or 0) + interval * 60 - now) or nil,
            progress = st and st.progress or 0, attacker = st and st.attacker and label(st.attacker) or nil,
        }
    end
    table.sort(terr, function(a, b) return a.id < b.id end)

    -- Classement
    local wonRows = MySQL.query.await("SELECT winner, COUNT(*) AS n FROM gangbuilder_wars WHERE status = 'done' AND winner IS NOT NULL GROUP BY winner") or {}
    local won = {}
    for _, r in ipairs(wonRows) do won[r.winner] = tonumber(r.n) or 0 end
    local ranking = {}
    for _, r in ipairs(MySQL.query.await('SELECT name, rep FROM gangbuilder_gangs ORDER BY rep DESC LIMIT 20') or {}) do
        local g = GB.Gangs[r.name]
        if g then
            local tc = 0
            for _, t in pairs(GB.Territories) do if t.owner == r.name then tc = tc + 1 end end
            ranking[#ranking + 1] = { name = r.name, label = g.label, color = g.color, rep = tonumber(r.rep) or 0, territories = tc, wars = won[r.name] or 0, online = #GB.onlineMembers(r.name), me = r.name == gang.name }
        end
    end

    -- Guerres
    local current, incoming
    local _, w = warOf(gang.name)
    if w then
        current = warView(w)
        if w.status == 'pending' and w.gang_b == gang.name then incoming = true end
    end
    local history = {}
    for _, r in ipairs(MySQL.query.await("SELECT * FROM gangbuilder_wars WHERE status = 'done' AND (gang_a = ? OR gang_b = ?) ORDER BY id DESC LIMIT 8", { gang.name, gang.name }) or {}) do history[#history + 1] = warView(r) end
    local rivals = {}
    for name, g in pairs(GB.Gangs) do
        if name ~= gang.name then rivals[#rivals + 1] = { name = name, label = g.label, color = g.color, online = #GB.onlineMembers(name), busy = warOf(name) ~= nil } end
    end
    table.sort(rivals, function(a, b) return a.label < b.label end)

    -- Colis en cours
    local obj = GB.objectiveInfo and GB.objectiveInfo() or nil

    -- Journal du gang
    local logs = MySQL.query.await('SELECT player_name, action, detail, UNIX_TIMESTAMP(created_at) AS t FROM gangbuilder_logs WHERE gang_name = ? ORDER BY id DESC LIMIT 25', { gang.name }) or {}

    local news = {}
    for i = #News, 1, -1 do news[#news + 1] = News[i] end

    local W = T().Wars
    return {
        ok = true, now = now,
        me = { name = gang.name, label = gang.label, color = gang.color, motd = gang.settings.motd or '', grade = grade, gradeLabel = (gang.grades[grade + 1] or {}).label or '', isBureau = bureau(gang, grade),
               rep = rep, money = seeMoney and money or nil, dirty = seeMoney and dirty or nil, members = GB.memberCount(gang.name), online = online, player = GB.playerName(xPlayer) },
        territories = terr, territoryCount = mine,
        quests = questList(gang.name), questsEnabled = T().Enabled,
        wars = { enabled = W.Enabled, current = current, incoming = incoming or false, history = history, rivals = rivals, targets = W.Targets, durations = W.Durations, maxStake = W.MaxStake, cooldown = W.Cooldown },
        ranking = ranking, objective = obj, logs = logs, news = news,
        resets = { daily = 86400 - now % 86400, weekly = (((8 - tonumber(os.date('!%w'))) % 7 == 0 and 7 or (8 - tonumber(os.date('!%w'))) % 7) * 86400) - now % 86400 },
    }
end

ESX.RegisterServerCallback('gangbuilder:tablet:open', function(src, cb)
    if not T().Enabled then return cb(fail('La tablette est désactivée')) end
    cb(snapshot(src) or fail('Tu n\'es dans aucun gang'))
end)

-- Pour d'autres scripts : exports.pickax_gangbuilder:GetGangNews()
exports('GetGangNews', function() return News end)
