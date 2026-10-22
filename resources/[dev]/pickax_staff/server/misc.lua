local fail = S.fail
local function done(msg, extra) local r = { ok = true, msg = msg } if extra then for k, v in pairs(extra) do r[k] = v end end return r end

-- ─────────────── Tableau de bord ───────────────
S.reg('dash', 'panel', function(src)
    local staffOnline, service = {}, 0
    for _, id in ipairs(GetPlayers()) do
        id = tonumber(id)
        local r = S.rank(id)
        if r then
            local inS = exports.pickax_core:StaffInService(id) == true
            if inS then service = service + 1 end
            staffOnline[#staffOnline + 1] = { id = id, name = GetPlayerName(id), rank = r, service = inS }
        end
    end
    local reports = exports.pickax_core:StaffReports() or {}
    local waiting = 0
    for _, r in ipairs(reports) do if not r.isTake then waiting = waiting + 1 end end
    local recent = MySQL.query.await('SELECT UNIX_TIMESTAMP(created) AS t, staff_name, action, target_name, details FROM staff_logs ORDER BY id DESC LIMIT 8') or {}
    local bans = MySQL.scalar.await('SELECT COUNT(*) FROM banlist WHERE permanent = 1 OR expiration > ?', { os.time() }) or 0
    local warns24 = MySQL.scalar.await('SELECT COUNT(*) FROM staff_warns WHERE created > (NOW() - INTERVAL 1 DAY)') or 0
    return { ok = true, online = #GetPlayers(), staff = staffOnline, service = service, reports = #reports, waiting = waiting, bans = bans, warns24 = warns24,
        uptime = os.time() - S.started, recent = recent, maxClients = GetConvarInt('sv_maxclients', 48) }
end)

-- ─────────────── Reports ───────────────
S.reg('reports', 'reports', function() return { ok = true, reports = exports.pickax_core:StaffReports() or {} } end)

S.reg('reportTake', 'reports', function(src, id)
    local ok, err = exports.pickax_core:StaffTakeReport(src, id)
    if not ok then return fail(err) end
    S.log(src, 'report_take', tonumber(id))
    return done('Report pris en charge')
end)

S.reg('reportClose', 'reports', function(src, id)
    local ok, err = exports.pickax_core:StaffCloseReport(src, id)
    if not ok then return fail(err) end
    S.log(src, 'report_close', tonumber(id))
    return done('Report fermé')
end)

S.reg('reportReply', 'reports', function(src, id, text)
    id = tonumber(id)
    text = tostring(text or ''):gsub('[%c]', ' '):sub(1, 200)
    if not id or not GetPlayerName(id) then return fail('Joueur hors ligne') end
    if #text < 1 then return fail('Message vide') end
    TriggerClientEvent('esx:showNotification', id, '~b~Réponse du staff : ~s~' .. text)
    S.log(src, 'report_reply', id, { text = text })
    return done('Réponse envoyée')
end)

-- ─────────────── Actions sur moi (droit + journal ; l'exécution se fait chez le staff) ───────────────
local SELF = { self_heal = true, self_revive = true, self_armor = true, tp_waypoint = true, tp_coords = true, tp_back = true, self_clothes = true,
    veh_spawn = true, veh_repair = true, veh_delete = true, veh_clean = true, veh_flip = true, veh_max = true, veh_plate = true, veh_neon = true, veh_unlock = true, veh_fuel = true, veh_give = true, legacy = true }
local QUIET = { tp_waypoint = true, tp_back = true, veh_repair = true, veh_clean = true, veh_flip = true, veh_fuel = true, self_clothes = true, legacy = true }

ESX.RegisterServerCallback('pickax_staff:self', function(src, cb, action, args)
    if type(action) ~= 'string' or not SELF[action] then return cb(fail('Action inconnue')) end
    if not S.can(src, action) then return cb(fail('Accès refusé')) end
    args = type(args) == 'table' and args or {}
    if action == 'veh_give' then
        local m = tostring(args.model or '')
        if not m:match('^[%w_]+$') or #m > 40 then return cb(fail('Modèle invalide')) end
    end
    if action == 'veh_spawn' then
        local m = tostring(args.model or '')
        if not m:match('^[%w_]+$') or #m > 40 then return cb(fail('Modèle invalide')) end
    end
    if action == 'self_revive' then ExecuteCommand('revive ' .. src) end
    if action == 'self_heal' then TriggerClientEvent('esx_status:healPlayer', src) SetEntityHealth(GetPlayerPed(src), 200) end
    if action == 'self_armor' then SetPedArmour(GetPlayerPed(src), 100) end
    if not QUIET[action] then S.log(src, action, nil, args.model or args.plate) end
    cb({ ok = true })
end)

-- ─────────────── Monde ───────────────
local function worldReg(name, key, fn) S.reg(name, key, function(src, ...) local r = fn(src, ...) if r and r.ok then S.log(src, name, nil, r.log) end return r end) end

worldReg('weather', 'weather', function(src, w)
    w = tostring(w or ''):upper()
    local valid = false
    for _, k in ipairs(Config.Weather) do if k == w then valid = true end end
    if not valid then return fail('Météo inconnue') end
    ExecuteCommand('weather ' .. w)
    return done('Météo : ' .. w, { log = w })
end)

worldReg('time', 'time', function(src, h, m)
    h, m = math.floor(tonumber(h) or -1), math.floor(tonumber(m) or -1)
    if h < 0 or h > 23 or m < 0 or m > 59 then return fail('Heure invalide') end
    ExecuteCommand(('time %d %d'):format(h, m))
    return done(('Heure : %02d:%02d'):format(h, m), { log = ('%02d:%02d'):format(h, m) })
end)

worldReg('announce', 'announce', function(src, text)
    text = tostring(text or ''):gsub('[%c]', ' '):sub(1, Config.AnnounceMax)
    if #text < 2 then return fail('Annonce vide') end
    TriggerClientEvent('pickax_staff:announce', -1, text, S.name(src))
    return done('Annonce envoyée', { log = text })
end)

worldReg('cleanup', 'cleanup', function(src, kind, radius)
    radius = math.min(Config.CleanupMaxRadius, math.max(5.0, tonumber(radius) or 50.0))
    local origin = GetEntityCoords(GetPlayerPed(src))
    local n = 0
    if kind == 'vehicles' then
        for _, veh in ipairs(GetAllVehicles()) do
            if DoesEntityExist(veh) and #(GetEntityCoords(veh) - origin) <= radius then
                local occupied = false
                for seat = -1, 6 do
                    local p = GetPedInVehicleSeat(veh, seat)
                    if p ~= 0 and IsPedAPlayer(p) then occupied = true break end
                end
                if not occupied then DeleteEntity(veh) n = n + 1 end
            end
        end
    elseif kind == 'peds' then
        for _, ped in ipairs(GetAllPeds()) do
            if DoesEntityExist(ped) and not IsPedAPlayer(ped) and #(GetEntityCoords(ped) - origin) <= radius then DeleteEntity(ped) n = n + 1 end
        end
    else
        return fail('Type inconnu')
    end
    return done(('%d élément(s) supprimé(s)'):format(n), { log = ('%s r=%d : %d'):format(kind, radius, n) })
end)

local function forAllPlayers(fn) local n = 0 for _, id in ipairs(GetPlayers()) do fn(tonumber(id)) n = n + 1 end return n end
worldReg('reviveAll', 'reviveAll', function(src)
    local n = forAllPlayers(function(id) ExecuteCommand('revive ' .. id) end)
    return done(n .. ' joueur(s) réanimé(s)', { log = tostring(n) })
end)
worldReg('healAll', 'healAll', function(src)
    local n = forAllPlayers(function(id) TriggerClientEvent('esx_status:healPlayer', id) SetEntityHealth(GetPlayerPed(id), 200) end)
    return done(n .. ' joueur(s) soigné(s)', { log = tostring(n) })
end)

-- ─────────────── Chat staff ───────────────
S.reg('chatList', 'staffchat', function() return { ok = true, messages = S.chat } end)
S.reg('chatSend', 'staffchat', function(src, text)
    text = tostring(text or ''):gsub('[%c]', ' '):sub(1, 220)
    if #text < 1 then return fail('Message vide') end
    local msg = { t = os.time(), id = src, name = S.name(src), rank = S.rank(src), text = text }
    S.chat[#S.chat + 1] = msg
    while #S.chat > Config.ChatMax do table.remove(S.chat, 1) end
    for _, id in ipairs(GetPlayers()) do
        id = tonumber(id)
        if id ~= src and S.can(id, 'staffchat') then TriggerClientEvent('pickax_staff:chat', id, msg) end
    end
    return { ok = true, message = msg }
end)

-- ─────────────── Journal ───────────────
S.reg('logs', 'logs', function(src, action, search, page)
    action = tostring(action or ''):sub(1, 40)
    search = tostring(search or ''):sub(1, 60)
    page = math.max(0, math.floor(tonumber(page) or 0))
    local where, args = { '1 = 1' }, {}
    if action ~= '' then where[#where + 1] = 'action = ?' args[#args + 1] = action end
    if search ~= '' then
        local like = '%' .. search:gsub('[%%_]', '') .. '%'
        where[#where + 1] = '(staff_name LIKE ? OR target_name LIKE ? OR details LIKE ?)'
        args[#args + 1] = like args[#args + 1] = like args[#args + 1] = like
    end
    args[#args + 1] = page * 30
    local rows = MySQL.query.await(('SELECT id, UNIX_TIMESTAMP(created) AS t, staff_name, action, target_name, details FROM staff_logs WHERE %s ORDER BY id DESC LIMIT 31 OFFSET ?'):format(table.concat(where, ' AND ')), args) or {}
    local more = #rows > 30
    if more then rows[#rows] = nil end
    local actions = {}
    for _, r in ipairs(MySQL.query.await('SELECT DISTINCT action FROM staff_logs ORDER BY action') or {}) do actions[#actions + 1] = r.action end
    return { ok = true, logs = rows, more = more, page = page, actions = actions }
end)

-- Historique des sanctions (avertissements récents de tout le serveur)
S.reg('warns', 'players', function(src, page)
    page = math.max(0, math.floor(tonumber(page) or 0))
    local rows = MySQL.query.await('SELECT id, UNIX_TIMESTAMP(created) AS t, name, staff_name, reason FROM staff_warns ORDER BY id DESC LIMIT 31 OFFSET ?', { page * 30 }) or {}
    local more = #rows > 30
    if more then rows[#rows] = nil end
    return { ok = true, warns = rows, more = more, page = page }
end)

-- ─────────────── Favoris de téléportation ───────────────
S.reg('bookmarkSave', 'bookmarks', function(src, label, x, y, z)
    label = tostring(label or ''):gsub('[%c]', ' '):sub(1, 40)
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if #label < 1 or not x or not y or not z then return fail('Nom ou coordonnées invalides') end
    if #S.bookmarks >= 60 then return fail('Trop de favoris (60 max)') end
    S.bookmarks[#S.bookmarks + 1] = { label = label, x = x, y = y, z = z }
    S.saveSetting('bookmarks', S.bookmarks)
    S.log(src, 'bookmark_add', nil, label)
    return { ok = true, bookmarks = S.bookmarks }
end)

S.reg('bookmarkDelete', 'bookmarks', function(src, index)
    index = math.floor(tonumber(index) or 0)
    if not S.bookmarks[index] then return fail('Favori introuvable') end
    table.remove(S.bookmarks, index)
    S.saveSetting('bookmarks', S.bookmarks)
    return { ok = true, bookmarks = S.bookmarks }
end)

-- ─────────────── Droits ───────────────
S.reg('permsGet', 'perms', function()
    local list = {}
    for key, def in pairs(Config.Perm) do
        local l = Config.PermLabels[key] or { 'Autre', key }
        list[#list + 1] = { key = key, group = l[1], label = l[2], value = S.perms[key] or def, default = def, locked = key == 'perms' }
    end
    table.sort(list, function(a, b) if a.group ~= b.group then return a.group < b.group end return a.label < b.label end)
    return { ok = true, perms = list }
end)

S.reg('permsSave', 'perms', function(src, map)
    if type(map) ~= 'table' then return fail('Données invalides') end
    local out = {}
    for key, v in pairs(map) do
        v = math.floor(tonumber(v) or 0)
        if Config.Perm[key] and v >= 1 and v <= 4 and key ~= 'perms' then out[key] = v end
    end
    S.perms = out
    S.saveSetting('perms', out)
    S.log(src, 'perms_save', nil, 'droits modifiés')
    return { ok = true }
end)

S.reg('permsReset', 'perms', function(src)
    S.perms = {}
    S.saveSetting('perms', {})
    S.log(src, 'perms_reset')
    return { ok = true }
end)

-- Matrice des droits de l'ancien menu (lecture ; l'écriture passe par les événements du core, vérifiés côté core)
S.reg('permMatrix', 'perms', function(src)
    local d = exports.pickax_core:StaffPermMatrix(src)
    if not d then return fail('Réservé au rôle _dev') end
    return { ok = true, matrix = d.matrix, funcs = d.funcs, grades = d.grades }
end)

-- Journal des actions déléguées au core (wipe, capture d'écran)
S.reg('audit', 'panel', function(src, kind, id)
    if kind ~= 'wipe' and kind ~= 'screenshot' then return fail('Action inconnue') end
    S.log(src, 'core_' .. kind, tonumber(id))
    return { ok = true }
end)
