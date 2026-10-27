-- [AERO:LIC] contrôle de licence via pickax_core (qui vérifie lui-même la signature du panel) : ne pas retirer
do
    local res = GetCurrentResourceName()
    -- true / false ; nil = pickax_core n'a pas encore fini sa vérification
    local function lic() local good, v = pcall(function() return exports.pickax_core:Licensed() end) if good then return v end end
    local function die(why) print(('^1[AERO] %s arrêtée : %s^0'):format(res, why)) StopResource(res) end
    if GetResourceState('pickax_core') == 'started' and lic() == false then die('licence invalide (pickax_core)') error('AERO : licence invalide', 0) end
    CreateThread(function()
        local tries = 0
        while true do
            local v = lic()
            if v == true then break end
            tries = tries + 1
            if v == false or tries > 30 then die(v == false and 'licence invalide (pickax_core)' or 'pickax_core absent ou licence non vérifiée') return end
            Wait(2000)
        end
        while true do
            Wait(240000 + math.random(0, 120000))
            local good = false
            for _ = 1, 4 do if lic() == true then good = true break end Wait(10000) end
            if not good then die('licence invalide') return end
        end
    end)
end
-- [/AERO:LIC]

ESX = exports['es_extended']:getSharedObject()

AC = {
    cfg = nil,            -- réglages effectifs (Config.Defaults + réglages faits en jeu)
    players = {},         -- [src] = état de suivi du joueur
    grace = {},           -- [src] = { until = ms, reason = '' }
    ready = false,
    handlers = {},        -- événements déjà écoutés
}

local function copy(t)
    if type(t) ~= 'table' then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = copy(v) end
    return o
end
AC.copy = copy

local function merge(base, over)
    for k, v in pairs(over) do
        if type(v) == 'table' and type(base[k]) == 'table' and #v == 0 and next(v) ~= nil and #base[k] == 0 then merge(base[k], v)
        else base[k] = copy(v) end
    end
    return base
end

function AC.decode(s, default)
    if not s or s == '' then return default end
    local ok, r = pcall(json.decode, s)
    if ok and r ~= nil then return r end
    return default
end

local function now() return GetGameTimer() end
local function unix() return os.time() end
AC.now, AC.unix = now, unix

function AC.debug(...) if Config.Debug then print('^3[anticheat]^7', ...) end end

-- ─────────────────────────────── Base de données ───────────────────────────────
local function installTables()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS anticheat_logs (
        id INT AUTO_INCREMENT PRIMARY KEY,
        created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        identifier VARCHAR(80) NOT NULL DEFAULT '',
        name VARCHAR(80) NOT NULL DEFAULT '',
        module VARCHAR(30) NOT NULL DEFAULT '',
        action VARCHAR(40) NOT NULL DEFAULT 'log',
        score FLOAT NOT NULL DEFAULT 0,
        details TEXT NULL,
        fp TINYINT NOT NULL DEFAULT 0,
        KEY idx_created (created), KEY idx_ident (identifier), KEY idx_module (module)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS anticheat_settings (k VARCHAR(30) NOT NULL PRIMARY KEY, v LONGTEXT NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
end

function AC.loadSettings()
    local cfg = copy(Config.Defaults)
    local row = MySQL.single.await("SELECT v FROM anticheat_settings WHERE k = 'cfg'")
    local saved = row and AC.decode(row.v, nil)
    if type(saved) == 'table' and AC.sanitize then
        saved = AC.sanitize(saved, cfg)
        cfg = saved
    end
    AC.cfg = cfg
    AC.rebuild()
end

function AC.saveSettings()
    MySQL.insert.await("INSERT INTO anticheat_settings (k, v) VALUES ('cfg', ?) ON DUPLICATE KEY UPDATE v = VALUES(v)", { json.encode(AC.cfg) })
    AC.rebuild()
end

-- Index rapides (ensembles) reconstruits à chaque changement de réglages
local function hashOf(name)
    local h = GetHashKey(name)
    return h & 0xFFFFFFFF
end
AC.hashOf = hashOf

local function set(list)
    local s = {}
    for _, v in ipairs(list or {}) do s[tostring(v)] = true end
    return s
end

function AC.rebuild()
    local c = AC.cfg
    local idx = { groups = set(c.exempt.groups), adminModules = set(c.exempt.adminModules), jobs = set(c.exempt.jobs), licenses = set(c.exempt.licenses),
        wl = {}, bl = {}, mveh = {}, mped = {}, mobj = {}, hp = set(c.events.honeypots), lim = {} }
    for _, w in ipairs(c.weapons.whitelist or {}) do idx.wl[hashOf(w)] = w end
    for _, w in ipairs(c.weapons.blacklist or {}) do idx.bl[hashOf(w)] = w end
    idx.jobwl = {}
    for job, list in pairs(c.weapons.jobs or {}) do
        idx.jobwl[job] = {}
        for _, w in ipairs(list) do idx.jobwl[job][hashOf(w)] = w end
    end
    for _, m in ipairs(c.models.vehicles or {}) do idx.mveh[hashOf(m)] = m end
    for _, m in ipairs(c.models.peds or {}) do idx.mped[hashOf(m)] = m end
    for _, m in ipairs(c.models.objects or {}) do idx.mobj[hashOf(m)] = m end
    for _, l in ipairs(c.events.limits or {}) do idx.lim[l.event] = l end
    AC.idx = idx
    if AC.listen then AC.listen() end
end

-- ─────────────────────────────── Identifiants / droits ───────────────────────────────
function AC.license(src)
    local id = ESX.GetIdentifierFromId and ESX.GetIdentifierFromId(src, 'license:') or nil
    if not id or id == '' then id = GetPlayerIdentifierByType(src, 'license') end
    return id
end

function AC.identifiers(src)
    local out = {}
    for _, t in ipairs({ 'license', 'license2', 'steam', 'discord', 'fivem', 'xbl', 'live' }) do
        local v = GetPlayerIdentifierByType(src, t)
        if v then out[t] = v end
    end
    out.ip = GetPlayerEndpoint(src)
    return out
end

function AC.group(src)
    local x = ESX.GetPlayerFromId(src)
    return x and x.getGroup() or 'user'
end

local function inList(list, v)
    for _, g in ipairs(list or {}) do if g == v then return true end end
    return false
end

function AC.isStaff(src)
    if src == 0 then return true end
    return AC.cfg and AC.idx.groups[AC.group(src)] == true
end

function AC.canView(src)
    if src == 0 then return true end
    if inList(Config.Panel.ViewGroups, AC.group(src)) or inList(Config.Panel.BanGroups, AC.group(src)) then return true end
    return Config.Panel.Ace and Config.Panel.Ace ~= '' and IsPlayerAceAllowed(src, Config.Panel.Ace) or false
end

function AC.canBan(src)
    if src == 0 then return true end
    if inList(Config.Panel.BanGroups, AC.group(src)) then return true end
    return Config.Panel.Ace and Config.Panel.Ace ~= '' and IsPlayerAceAllowed(src, Config.Panel.Ace) or false
end

function AC.name(src) return (src and src > 0 and GetPlayerName(src)) or ('Joueur ' .. tostring(src)) end

-- ─────────────────────────────── Exemptions ───────────────────────────────
-- Délai de grâce : autres ressources → exports['pickax_anticheat']:Exempt(source, secondes, 'raison')
function AC.exempt(src, seconds, reason)
    src = tonumber(src)
    if not src then return end
    local untilMs = now() + math.floor((tonumber(seconds) or (AC.cfg and AC.cfg.grace.exempt) or 8) * 1000)
    local g = AC.grace[src]
    if not g or g.untilMs < untilMs then AC.grace[src] = { untilMs = untilMs, reason = reason or 'exempt' } end
end

AddEventHandler('pickax_anticheat:exempt', function(src, seconds, reason) AC.exempt(src, seconds, reason) end)   -- TriggerEvent côté serveur

-- Retourne true + raison si le joueur n'est PAS contrôlé pour ce module
function AC.isExempt(src, module)
    local cfg = AC.cfg
    local p = AC.players[src]
    local t = now()
    local g = AC.grace[src]
    if g and g.untilMs > t and module ~= 'honeypots' and module ~= 'events' and module ~= 'heartbeat' then return true, g.reason end
    local x = ESX.GetPlayerFromId(src)
    if p and p.joinedAt and (t - p.joinedAt) < cfg.grace.join * 1000 and module ~= 'honeypots' then return true, 'connexion' end
    if p and p.spawnAt and (t - p.spawnAt) < cfg.grace.spawn * 1000 and module ~= 'honeypots' and module ~= 'events' and module ~= 'heartbeat' then return true, 'apparition' end
    local lic = AC.license(src)
    if lic and AC.idx.licenses[lic] then return true, 'licence exemptée' end
    if x then
        local group = x.getGroup()
        if AC.idx.groups[group] and AC.idx.adminModules[module] then return true, 'staff' end
        local job = x.getJob and x.getJob() or nil
        if job and AC.idx.jobs[job.name] and (module == 'weapon' or module == 'weaponBlacklist') then return true, 'métier exempté' end
    end
    local ok, st = pcall(function() return Player(src).state end)
    if ok and st then
        for _, name in ipairs(cfg.exempt.states or {}) do
            if st[name] then return true, 'état ' .. name end
        end
    end
    return false
end

-- ─────────────────────────────── Journal ───────────────────────────────
local function webhook(title, desc, color)
    local url = AC.cfg and AC.cfg.webhook
    if not url or url == '' then return end
    PerformHttpRequest(url, function() end, 'POST', json.encode({ username = 'Pickax Anticheat',
        embeds = { { title = title, description = desc, color = color or 15158332, footer = { text = os.date('%d/%m/%Y %H:%M:%S') } } } }), { ['Content-Type'] = 'application/json' })
end
AC.webhook = webhook

function AC.log(src, identifier, name, module, action, score, details)
    local d = type(details) == 'table' and json.encode(details) or tostring(details or '')
    MySQL.insert('INSERT INTO anticheat_logs (identifier, name, module, action, score, details) VALUES (?, ?, ?, ?, ?, ?)', { identifier or '', (name or ''):sub(1, 80), module, action, score or 0, d:sub(1, 3000) })
end

-- ─────────────────────────────── Sanctions ───────────────────────────────
local function sexy(seconds)
    seconds = math.floor(seconds)
    local d = math.floor(seconds / 86400)
    local h = math.floor((seconds % 86400) / 3600)
    local m = math.floor((seconds % 3600) / 60)
    if d > 0 then return ('%d j %d h'):format(d, h) end
    if h > 0 then return ('%d h %d min'):format(h, m) end
    return ('%d min'):format(math.max(1, m))
end
AC.sexy = sexy

function AC.parseDuration(s)
    s = tostring(s or ''):lower()
    if s == 'perm' or s == 'permanent' or s == '0' or s == '' then return 0 end
    local n, u = s:match('^(%d+)%s*(%a+)$')
    n = tonumber(n)
    if not n or n <= 0 then return nil end
    if u == 'm' or u == 'min' then return n * 60 end
    if u == 'h' then return n * 3600 end
    if u == 'd' or u == 'j' then return n * 86400 end
    return nil
end

-- Ban dans la table du core (banlist + banlisthistory) : appliqué par le contrôle de connexion déjà en place (pickax_core/system/ban)
-- seconds = 0 → permanent
function AC.ban(src, reason, seconds, by, evidence)
    src = tonumber(src)
    if not src or not GetPlayerName(src) then return false, 'Joueur introuvable' end
    local lic = AC.license(src)
    if not lic then return false, 'Licence introuvable' end
    local x = ESX.GetPlayerFromId(src)
    local banid = x and x.boutique_id or nil
    if not banid or banid == '' then banid = 'AC' .. tostring(unix()) .. tostring(math.random(100, 999)) end
    local name = AC.name(src)
    local perm = (not seconds or seconds <= 0) and 1 or 0
    local timeat = unix()
    local expiration = perm == 1 and timeat or (timeat + seconds)
    reason = tostring(reason or 'Triche'):sub(1, 200)
    by = tostring(by or 'Anti-Cheat'):sub(1, 30)
    local ip = 'N/A'
    MySQL.insert.await('INSERT INTO banlist (licenseid, playerip, targetName, sourceName, reason, timeat, expiration, permanent, banid) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { lic, ip, name:sub(1, 32), by, reason, timeat, expiration, perm, banid })
    MySQL.insert('INSERT INTO banlisthistory (licenseid, playerip, targetName, sourceName, reason, timeat, expiration, permanent, banid) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { lic, ip, name:sub(1, 50), by, reason, timeat, expiration, perm, banid })
    AC.log(src, lic, name, 'ban', perm == 1 and 'ban permanent' or ('ban ' .. sexy(seconds)), 0, { reason = reason, by = by, banid = banid, evidence = evidence })
    webhook('Bannissement', ('**%s** (%s)\nRaison : %s\nDurée : %s\nPar : %s'):format(name, lic, reason, perm == 1 and 'permanent' or sexy(seconds), by))
    DropPlayer(src, ('Vous êtes banni\nRaison : %s\nTemps restant : %s\nAuteur : %s\nBan ID : %s\n%s'):format(reason, perm == 1 and 'Permanent' or sexy(seconds), by, banid, AC.cfg.appeal or ''))
    return true, banid
end

function AC.kick(src, reason, by)
    if not GetPlayerName(src) then return false end
    local lic, name = AC.license(src), AC.name(src)
    reason = tostring(reason or 'Comportement suspect'):sub(1, 200)
    AC.log(src, lic, name, 'kick', 'kick', 0, { reason = reason, by = by or 'Anti-Cheat' })
    webhook('Expulsion', ('**%s** (%s)\nRaison : %s\nPar : %s'):format(name, lic or '?', reason, by or 'Anti-Cheat'), 16753920)
    DropPlayer(src, ('Expulsé par l\'anti-cheat\nRaison : %s\n%s'):format(reason, AC.cfg.appeal or ''))
    return true
end

-- ─────────────────────────────── Scores et décision ───────────────────────────────
-- score d'un module pour un joueur, avec décroissance linéaire
local function scoreOf(p, module)
    local s = p.score[module]
    if not s then return 0 end
    local elapsed = (now() - s.t) / 1000
    local decay = math.max(10, AC.cfg.scoreDecay)
    local v = s.v * math.max(0, 1 - elapsed / decay)
    return v
end
AC.scoreOf = scoreOf

function AC.totalScore(src)
    local p = AC.players[src]
    if not p then return 0 end
    local tot = 0
    for m in pairs(p.score) do tot = tot + scoreOf(p, m) end
    return tot
end

-- Signale un comportement : ajoute des points ; sanctionne si le seuil du module est atteint (sauf mode observe)
function AC.flag(src, module, details, weight)
    src = tonumber(src)
    local cfg = AC.cfg
    local m = cfg and cfg.modules[module]
    if not src or not m or not m.enabled or not GetPlayerName(src) then return end
    local exempt, why = AC.isExempt(src, module)
    if exempt then AC.debug(('exempté %s (%s) : %s'):format(AC.name(src), module, tostring(why))) return end
    local p = AC.players[src]
    if not p then p = { joinedAt = now(), score = {}, lastLog = {} } AC.players[src] = p end
    weight = tonumber(weight) or m.weight or 1
    local cur = scoreOf(p, module) + weight
    p.score[module] = { v = cur, t = now() }
    local action = 'log'
    if m.ban and m.ban > 0 and cur >= m.ban then action = 'ban'
    elseif m.kick and m.kick > 0 and cur >= m.kick then action = 'kick' end
    local observe = cfg.mode == 'observe'
    local lic, name = AC.license(src), AC.name(src)
    -- anti-spam du journal : une ligne par module et par 6 s, sauf quand une sanction tombe
    local t = now()
    if action ~= 'log' or not p.lastLog[module] or t - p.lastLog[module] > 6000 then
        p.lastLog[module] = t
        details = type(details) == 'table' and details or { info = tostring(details or '') }
        details.exemptBy = nil
        AC.log(src, lic, name, module, (observe and action ~= 'log') and ('simulé : ' .. action) or action, cur, details)
    end
    if action == 'log' or observe then return end
    local reason = ('Anti-Cheat (%s)'):format(module)
    if action == 'ban' then AC.ban(src, reason, 0, 'Anti-Cheat', details)
    else AC.kick(src, reason) end
end

-- ─────────────────────────────── Suivi des joueurs ───────────────────────────────
AddEventHandler('playerJoining', function()
    local src = source
    AC.players[src] = { joinedAt = now(), score = {}, lastLog = {}, hb = now() }
end)

AddEventHandler('esx:playerLoaded', function(src)
    local p = AC.players[src]
    if not p then p = { joinedAt = now(), score = {}, lastLog = {} } AC.players[src] = p end
    p.joinedAt, p.hb, p.spawnAt = now(), now(), now()
    p.token = ('%x%x%x'):format(math.random(0, 0xFFFFFF), math.random(0, 0xFFFFFF), unix())
    SetTimeout(3000, function() if GetPlayerName(src) then TriggerClientEvent('pickax_anticheat:token', src, p.token) end end)
    if AC.checkEvasion then AC.checkEvasion(src) end
end)

RegisterNetEvent('esx:onPlayerSpawn', function()
    local p = AC.players[source]
    if p then p.spawnAt = now() end
end)

AddEventHandler('playerDropped', function()
    local src = source
    AC.players[src] = nil
    AC.grace[src] = nil
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    installTables()
    AC.loadSettings()
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        AC.players[src] = AC.players[src] or { joinedAt = now() - 600000, score = {}, lastLog = {}, hb = now() }
        AC.players[src].token = AC.players[src].token or ('%x%x%x'):format(math.random(0, 0xFFFFFF), math.random(0, 0xFFFFFF), unix())
        TriggerClientEvent('pickax_anticheat:token', src, AC.players[src].token)
    end
    AC.ready = true
    print(('^2[anticheat] actif — mode « %s », %d module(s) activé(s).^0'):format(AC.cfg.mode, (function() local n = 0 for _, m in pairs(AC.cfg.modules) do if m.enabled then n = n + 1 end end return n end)()))
end)

-- ─────────────────────────────── Exports ───────────────────────────────
exports('Exempt', function(src, seconds, reason) AC.exempt(src, seconds, reason) end)
exports('IsExempt', function(src, module) return AC.isExempt(src, module or 'movement') end)
exports('Flag', function(src, module, details, weight) AC.flag(src, module, details, weight) end)
exports('Ban', function(src, reason, seconds, by) return AC.ban(src, reason, seconds, by or 'Resource') end)
