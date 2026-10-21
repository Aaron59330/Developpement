-- ─────────────────────────────── Réglages : validation + panneau de gestion ───────────────────────────────
local copy = AC.copy

local function num(v, min, max, def)
    v = tonumber(v)
    if not v or v ~= v or v == math.huge or v == -math.huge then v = def or 0 end
    if min and v < min then v = min end
    if max and v > max then v = max end
    return v
end
local function bool(v, def) if v == nil then return def end return v == true end
local function str(v, max, def)
    if type(v) ~= 'string' then return def or '' end
    return (v:gsub('[\0-\8\11\12\14-\31]', '')):sub(1, max or 100)
end

-- liste de chaînes validées par un motif, sans doublon
local function strList(v, pattern, maxLen, maxCount, def)
    if type(v) ~= 'table' then return copy(def or {}) end
    local out, seen = {}, {}
    for _, s in ipairs(v) do
        if type(s) == 'string' then
            s = s:gsub('^%s+', ''):gsub('%s+$', '')
            if s ~= '' and #s <= maxLen and s:match(pattern) and not seen[s] then
                seen[s] = true
                out[#out + 1] = s
                if #out >= maxCount then break end
            end
        end
    end
    return out
end

local NAME_PAT, EVENT_PAT, LIC_PAT = '^[%w_%-]+$', '^[%w_%-%.:]+$', '^[%w_%-%.:]+$'

-- champs propres à chaque module : { clé = { min, max } | 'b' }
local SPEC = {
    movement  = { maxSpeed = { 5, 200 }, samples = { 1, 30 } },
    teleport  = { distance = { 20, 5000 }, vehicleDistance = { 50, 10000 } },
    health    = { maxHealth = { 100, 1000 }, maxArmor = { 0, 500 } },
    entities  = { vehicles = { 0, 500 }, peds = { 0, 500 }, objects = { 0, 2000 }, window = { 10, 3600 } },
    explosions = { max = { 1, 200 }, window = { 1, 300 }, blockInvisible = 'b' },
    heartbeat = { timeout = { 30, 1800 } },
}

function AC.sanitize(d, base)
    d = type(d) == 'table' and d or {}
    local D = Config.Defaults
    local out = copy(base or D)
    out.mode = d.mode == 'observe' and 'observe' or 'protect'
    local wh = str(d.webhook, 300, '')
    out.webhook = (wh == '' or wh:match('^https://')) and wh or ''
    out.scoreDecay = num(d.scoreDecay, 10, 3600, D.scoreDecay)
    out.appeal = str(d.appeal, 200, D.appeal)

    local durs = {}
    for _, s in ipairs(type(d.banDurations) == 'table' and d.banDurations or D.banDurations) do
        if type(s) == 'string' and AC.parseDuration(s) ~= nil and #durs < 12 then durs[#durs + 1] = s end
    end
    out.banDurations = #durs > 0 and durs or copy(D.banDurations)

    local g = type(d.grace) == 'table' and d.grace or {}
    out.grace = { join = num(g.join, 0, 600, D.grace.join), spawn = num(g.spawn, 0, 120, D.grace.spawn), exempt = num(g.exempt, 0, 120, D.grace.exempt) }

    local e = type(d.exempt) == 'table' and d.exempt or {}
    local modNames = {}
    for k in pairs(D.modules) do modNames[#modNames + 1] = k end
    local okMods = {}
    for _, k in ipairs(modNames) do okMods[k] = true end
    local am = {}
    for _, k in ipairs(type(e.adminModules) == 'table' and e.adminModules or D.exempt.adminModules) do if okMods[k] then am[#am + 1] = k end end
    out.exempt = {
        groups = strList(e.groups, NAME_PAT, 30, 20, D.exempt.groups), adminModules = am, jobs = strList(e.jobs, NAME_PAT, 30, 60, D.exempt.jobs),
        states = strList(e.states, NAME_PAT, 40, 40, D.exempt.states), licenses = strList(e.licenses, LIC_PAT, 70, 300, D.exempt.licenses),
    }

    local ev = type(d.evasion) == 'table' and d.evasion or {}
    out.evasion = {}
    for k, def in pairs(D.evasion) do out.evasion[k] = bool(ev[k], def) end

    local w = type(d.weapons) == 'table' and d.weapons or {}
    out.weapons = {
        checkInventory = bool(w.checkInventory, D.weapons.checkInventory),
        whitelist = strList(w.whitelist, NAME_PAT, 48, 300, D.weapons.whitelist),
        blacklist = strList(w.blacklist, NAME_PAT, 48, 300, D.weapons.blacklist),
        jobs = {},
    }
    if type(w.jobs) == 'table' then
        local n = 0
        for job, list in pairs(w.jobs) do
            if type(job) == 'string' and job:match(NAME_PAT) and #job <= 30 and n < 60 then
                out.weapons.jobs[job] = strList(list, NAME_PAT, 48, 100, {})
                n = n + 1
            end
        end
    else out.weapons.jobs = copy(D.weapons.jobs) end

    local m = type(d.models) == 'table' and d.models or {}
    out.models = { vehicles = strList(m.vehicles, NAME_PAT, 64, 500, D.models.vehicles), peds = strList(m.peds, NAME_PAT, 64, 500, D.models.peds), objects = strList(m.objects, NAME_PAT, 64, 500, D.models.objects) }

    local evn = type(d.events) == 'table' and d.events or {}
    local limits = {}
    if type(evn.limits) == 'table' then
        for _, l in ipairs(evn.limits) do
            if type(l) == 'table' and type(l.event) == 'string' and l.event:match(EVENT_PAT) and #l.event <= 80 and #limits < 200 then
                limits[#limits + 1] = { event = l.event, max = math.floor(num(l.max, 1, 10000, 10)), window = math.floor(num(l.window, 1, 3600, 5)), weight = num(l.weight, 0, 20, 1) }
            end
        end
    else limits = copy(D.events.limits) end
    out.events = { honeypots = strList(evn.honeypots, EVENT_PAT, 80, 200, D.events.honeypots), limits = limits }

    out.modules = {}
    local mods = type(d.modules) == 'table' and d.modules or {}
    for name, def in pairs(D.modules) do
        local src = type(mods[name]) == 'table' and mods[name] or {}
        local o = { enabled = bool(src.enabled, def.enabled), weight = num(src.weight, 0, 50, def.weight), kick = num(src.kick, 0, 1000, def.kick), ban = num(src.ban, 0, 1000, def.ban) }
        for key, sp in pairs(SPEC[name] or {}) do
            if sp == 'b' then o[key] = bool(src[key], def[key]) else o[key] = num(src[key], sp[1], sp[2], def[key]) end
        end
        out.modules[name] = o
    end
    return out
end

-- Libellés affichés dans le panneau
local MODULE_INFO = {
    movement = { 'Vitesse à pied', 'Course soutenue anormalement rapide (fly, noclip, speed hack)' },
    teleport = { 'Téléportation', 'Saut de position impossible en 1 seconde (journal seulement par défaut : beaucoup de scripts téléportent légitimement)' },
    godmode = { 'Invincibilité', 'Joueur invincible plusieurs secondes de suite' },
    health = { 'Santé / armure', 'Santé ou armure au-dessus du maximum' },
    weapon = { 'Armes hors inventaire', 'Arme en main qui ne vient ni de l\'inventaire ni de la liste blanche' },
    weaponBlacklist = { 'Armes interdites', 'Arme de la liste noire tenue ou utilisée pour blesser' },
    blacklistModels = { 'Modèles interdits', 'Création d\'un véhicule / PNJ / objet de la liste noire' },
    entities = { 'Création en masse', 'Trop de véhicules / PNJ / objets créés en peu de temps' },
    explosions = { 'Explosions', 'Explosions invisibles ou en rafale' },
    events = { 'Fréquence des événements', 'Un événement serveur déclenché trop souvent' },
    honeypots = { 'Honeypots', 'Événement qu\'aucun script légitime n\'envoie : outil de triche' },
    heartbeat = { 'Battement client', 'Le script client de l\'anti-cheat ne répond plus' },
    clientFlags = { 'Signalements client', 'Modificateurs de dégâts, invisibilité, mode spectateur' },
}

-- ─────────────────────────────── Callbacks du panneau ───────────────────────────────
local function reg(name, need, fn)
    ESX.RegisterServerCallback('pickax_anticheat:' .. name, function(src, cb, ...)
        local ok
        if need == 'ban' then ok = AC.canBan(src) else ok = AC.canView(src) end
        if not ok then return cb({ ok = false, error = need == 'ban' and 'Réservé aux groupes autorisés à bannir' or 'Accès refusé' }) end
        local good, res = pcall(fn, src, ...)
        if not good then print('^1[anticheat]^7 ' .. name .. ' : ' .. tostring(res)) return cb({ ok = false, error = 'Erreur serveur' }) end
        cb(res)
    end)
end

ESX.RegisterServerCallback('pickax_anticheat:isAllowed', function(src, cb) cb(AC.canView(src), AC.canBan(src)) end)

local function adminLog(src, action, details)
    AC.log(src, src ~= 0 and AC.license(src) or '', src ~= 0 and AC.name(src) or 'Console', 'admin', action, 0, details)
    AC.webhook('Panel anti-cheat', ('**%s** : %s\n%s'):format(src ~= 0 and AC.name(src) or 'Console', action, type(details) == 'table' and json.encode(details) or tostring(details or '')), 3447003)
end

reg('overview', 'view', function()
    local mods = MySQL.query.await("SELECT module, COUNT(*) AS n FROM anticheat_logs WHERE created > (NOW() - INTERVAL 1 DAY) AND module NOT IN ('admin','ban','kick') GROUP BY module ORDER BY n DESC") or {}
    local acts = MySQL.single.await("SELECT SUM(action LIKE 'kick%') AS kicks, SUM(action LIKE 'ban%') AS bans, SUM(action LIKE 'simulé%') AS sims FROM anticheat_logs WHERE created > (NOW() - INTERVAL 1 DAY) AND module NOT IN ('admin')") or {}
    local active = MySQL.scalar.await('SELECT COUNT(*) FROM banlist WHERE permanent = 1 OR expiration > ?', { os.time() }) or 0
    local top = MySQL.query.await("SELECT name, identifier, COUNT(*) AS n, MAX(created) AS last FROM anticheat_logs WHERE created > (NOW() - INTERVAL 1 DAY) AND module NOT IN ('admin','ban','kick') AND fp = 0 GROUP BY identifier, name ORDER BY n DESC LIMIT 8") or {}
    local recent = MySQL.query.await("SELECT id, UNIX_TIMESTAMP(created) AS t, name, module, action, score, details FROM anticheat_logs WHERE module <> 'admin' ORDER BY id DESC LIMIT 12") or {}
    return { ok = true, mode = AC.cfg.mode, online = #GetPlayers(), modules = mods, kicks = tonumber(acts.kicks) or 0, bans = tonumber(acts.bans) or 0, sims = tonumber(acts.sims) or 0,
             activeBans = active, top = top, recent = recent }
end)

reg('players', 'view', function()
    local list = {}
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        local x = ESX.GetPlayerFromId(src)
        local p = AC.players[src]
        local scores = {}
        if p then for m in pairs(p.score) do local v = AC.scoreOf(p, m) if v > 0.4 then scores[m] = math.floor(v * 10) / 10 end end end
        local job = x and x.getJob and x.getJob() or nil
        list[#list + 1] = { id = src, name = AC.name(src), license = AC.license(src) or '', group = x and x.getGroup() or 'user', job = job and (job.label or job.name) or '',
            ping = GetPlayerPing(src), score = math.floor(AC.totalScore(src) * 10) / 10, scores = scores, hb = p and p.hb and math.floor((AC.now() - p.hb) / 1000) or -1,
            staff = AC.idx.groups[x and x.getGroup() or 'user'] == true }
    end
    table.sort(list, function(a, b) if a.score ~= b.score then return a.score > b.score end return a.id < b.id end)
    return { ok = true, players = list }
end)

reg('player', 'view', function(_, target)
    target = tonumber(target)
    if not target or not GetPlayerName(target) then return { ok = false, error = 'Joueur hors ligne' } end
    local lic = AC.license(target)
    local logs = MySQL.query.await("SELECT id, UNIX_TIMESTAMP(created) AS t, module, action, score, details, fp FROM anticheat_logs WHERE identifier = ? ORDER BY id DESC LIMIT 40", { lic or '' }) or {}
    local bans = MySQL.query.await('SELECT reason, sourceName, timeat, expiration, permanent, banid FROM banlisthistory WHERE licenseid = ? ORDER BY timeat DESC LIMIT 10', { lic or '' }) or {}
    local ids = AC.identifiers(target)
    ids.ip = nil           -- l'adresse IP n'est jamais affichée dans le panneau
    local p = AC.players[target]
    local scores = {}
    if p then for m in pairs(p.score) do scores[m] = math.floor(AC.scoreOf(p, m) * 10) / 10 end end
    local exemptList = AC.idx.licenses[lic or ''] == true
    return { ok = true, id = target, name = AC.name(target), license = lic, identifiers = ids, logs = logs, bans = bans, scores = scores, exempted = exemptList, group = AC.group(target),
             ping = GetPlayerPing(target) }
end)

reg('warn', 'view', function(src, target, msg)
    target = tonumber(target)
    if not target or not GetPlayerName(target) then return { ok = false, error = 'Joueur hors ligne' } end
    msg = str(msg, 200, 'Comportement suspect : merci de respecter le règlement.')
    TriggerClientEvent('esx:showNotification', target, '~r~[Avertissement staff]~s~ ' .. msg)
    AC.log(target, AC.license(target), AC.name(target), 'admin', 'avertissement', 0, { by = AC.name(src), message = msg })
    adminLog(src, 'avertissement', { target = AC.name(target), message = msg })
    return { ok = true }
end)

reg('kick', 'view', function(src, target, reason)
    target = tonumber(target)
    if not target or not GetPlayerName(target) then return { ok = false, error = 'Joueur hors ligne' } end
    if target == src then return { ok = false, error = 'Tu ne peux pas t\'expulser toi-même' } end
    reason = str(reason, 200, 'Expulsé par le staff')
    AC.kick(target, reason, AC.name(src))
    return { ok = true }
end)

local function staffProtected(src, target)
    local tg = AC.group(target)
    if tg and AC.idx.groups[tg] and not (AC.canBan(src) and tg ~= 'superadmin' and tg ~= '_dev') then return true end
    return false
end

reg('ban', 'ban', function(src, target, duration, reason)
    target = tonumber(target)
    if not target or not GetPlayerName(target) then return { ok = false, error = 'Joueur hors ligne (utilise le bannissement hors ligne)' } end
    if target == src then return { ok = false, error = 'Tu ne peux pas te bannir toi-même' } end
    if staffProtected(src, target) then return { ok = false, error = 'Ce membre du staff est protégé' } end
    local secs = AC.parseDuration(duration)
    if secs == nil then return { ok = false, error = 'Durée invalide (ex : 1h, 3d, perm)' } end
    reason = str(reason, 200, 'Triche')
    local ok, res = AC.ban(target, reason, secs, AC.name(src))
    if not ok then return { ok = false, error = res } end
    adminLog(src, 'bannissement', { target = AC.name(target), duration = duration, reason = reason, banid = res })
    return { ok = true, banid = res }
end)

reg('banOffline', 'ban', function(src, license, name, duration, reason)
    license = str(license, 70, '')
    if not license:match(LIC_PAT) or #license < 10 then return { ok = false, error = 'Licence invalide (ex : license:abc123…)' } end
    local secs = AC.parseDuration(duration)
    if secs == nil then return { ok = false, error = 'Durée invalide' } end
    reason = str(reason, 200, 'Triche')
    name = str(name, 32, 'Inconnu')
    local u = MySQL.single.await('SELECT boutique_id FROM users WHERE identifier = ? LIMIT 1', { license })
    local banid = u and u.boutique_id or ('AC' .. os.time() .. math.random(100, 999))
    local perm = secs == 0 and 1 or 0
    local t = os.time()
    local exp = perm == 1 and t or t + secs
    MySQL.insert.await('INSERT INTO banlist (licenseid, playerip, targetName, sourceName, reason, timeat, expiration, permanent, banid) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', { license, 'N/A', name, AC.name(src):sub(1, 30), reason, t, exp, perm, banid })
    MySQL.insert('INSERT INTO banlisthistory (licenseid, playerip, targetName, sourceName, reason, timeat, expiration, permanent, banid) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', { license, 'N/A', name, AC.name(src):sub(1, 30), reason, t, exp, perm, banid })
    adminLog(src, 'bannissement hors ligne', { license = license, duration = duration, reason = reason })
    -- si le joueur est connecté, il est expulsé
    for _, id in ipairs(GetPlayers()) do
        if AC.license(tonumber(id)) == license then DropPlayer(tonumber(id), 'Vous êtes banni\nRaison : ' .. reason) end
    end
    return { ok = true, banid = banid }
end)

reg('unban', 'ban', function(src, banid)
    banid = str(banid, 60, '')
    if banid == '' then return { ok = false, error = 'Ban introuvable' } end
    local row = MySQL.single.await('SELECT targetName, licenseid, reason FROM banlist WHERE banid = ? LIMIT 1', { banid })
    if not row then return { ok = false, error = 'Ban introuvable (déjà levé ?)' } end
    MySQL.update.await('DELETE FROM banlist WHERE banid = ?', { banid })
    adminLog(src, 'débannissement', { target = row.targetName, license = row.licenseid, banid = banid })
    return { ok = true }
end)

reg('bans', 'view', function(_, search, page)
    search = str(search, 60, '')
    page = math.max(0, math.floor(tonumber(page) or 0))
    local like = '%' .. search:gsub('[%%_]', '') .. '%'
    local rows = MySQL.query.await('SELECT licenseid, targetName, sourceName, reason, timeat, expiration, permanent, banid FROM banlist WHERE (? = \'\' OR targetName LIKE ? OR licenseid LIKE ? OR banid LIKE ? OR reason LIKE ?) ORDER BY timeat DESC LIMIT 26 OFFSET ?',
        { search, like, like, like, like, page * 25 }) or {}
    local more = #rows > 25
    if more then rows[#rows] = nil end
    local t = os.time()
    for _, r in ipairs(rows) do r.active = r.permanent == 1 or r.expiration > t end
    return { ok = true, bans = rows, more = more, page = page }
end)

reg('logs', 'view', function(_, module, search, onlyActions, hideFp, page)
    module = str(module, 30, '')
    search = str(search, 60, '')
    page = math.max(0, math.floor(tonumber(page) or 0))
    local where, args = { '1 = 1' }, {}
    if module ~= '' then where[#where + 1] = 'module = ?' args[#args + 1] = module end
    if search ~= '' then
        local like = '%' .. search:gsub('[%%_]', '') .. '%'
        where[#where + 1] = '(name LIKE ? OR identifier LIKE ?)' args[#args + 1] = like args[#args + 1] = like
    end
    if onlyActions == true then where[#where + 1] = "action <> 'log'" end
    if hideFp == true then where[#where + 1] = 'fp = 0' end
    args[#args + 1] = page * 30
    local rows = MySQL.query.await(('SELECT id, UNIX_TIMESTAMP(created) AS t, identifier, name, module, action, score, details, fp FROM anticheat_logs WHERE %s ORDER BY id DESC LIMIT 31 OFFSET ?'):format(table.concat(where, ' AND ')), args) or {}
    local more = #rows > 30
    if more then rows[#rows] = nil end
    return { ok = true, logs = rows, more = more, page = page }
end)

reg('markFp', 'view', function(src, id, state)
    id = math.floor(tonumber(id) or 0)
    MySQL.update.await('UPDATE anticheat_logs SET fp = ? WHERE id = ?', { state == true and 1 or 0, id })
    adminLog(src, state == true and 'faux positif' or 'faux positif retiré', { logId = id })
    return { ok = true }
end)

reg('exempt', 'ban', function(src, license, add)
    license = str(license, 70, '')
    if not license:match(LIC_PAT) or #license < 10 then return { ok = false, error = 'Licence invalide' } end
    local list, found = {}, false
    for _, l in ipairs(AC.cfg.exempt.licenses) do
        if l == license then found = true if add == true then list[#list + 1] = l end else list[#list + 1] = l end
    end
    if add == true and not found then list[#list + 1] = license end
    AC.cfg.exempt.licenses = list
    AC.saveSettings()
    adminLog(src, add == true and 'joueur exempté' or 'exemption retirée', { license = license })
    return { ok = true }
end)

reg('settingsGet', 'view', function(src)
    return { ok = true, cfg = AC.cfg, defaults = Config.Defaults, weapons = Config.KnownWeapons, info = MODULE_INFO, canEdit = AC.canBan(src) }
end)

reg('settingsSave', 'ban', function(src, data)
    local clean = AC.sanitize(data, copy(Config.Defaults))
    AC.cfg = clean
    AC.saveSettings()
    adminLog(src, 'règles modifiées', { mode = clean.mode })
    return { ok = true, cfg = AC.cfg }
end)

reg('settingsReset', 'ban', function(src)
    AC.cfg = copy(Config.Defaults)
    MySQL.update.await("DELETE FROM anticheat_settings WHERE k = 'cfg'")
    AC.rebuild()
    adminLog(src, 'règles réinitialisées', {})
    return { ok = true, cfg = AC.cfg }
end)

reg('setMode', 'ban', function(src, mode)
    AC.cfg.mode = mode == 'observe' and 'observe' or 'protect'
    AC.saveSettings()
    adminLog(src, 'mode : ' .. AC.cfg.mode, {})
    return { ok = true, mode = AC.cfg.mode }
end)

-- Nettoyage des journaux de plus de 60 jours (une fois par jour)
CreateThread(function()
    while not AC.ready do Wait(1000) end
    while true do
        MySQL.update("DELETE FROM anticheat_logs WHERE created < (NOW() - INTERVAL 60 DAY) AND module <> 'ban'")
        Wait(24 * 3600 * 1000)
    end
end)
