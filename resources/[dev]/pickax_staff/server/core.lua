ESX = exports['es_extended']:getSharedObject()

S = { perms = {}, started = os.time(), lastPos = {}, frozen = {}, chat = {}, bookmarks = {} }

local function fail(msg) return { ok = false, error = msg } end
S.fail = fail

-- ─────────────── Rang / droits (source de vérité : pickax_core) ───────────────
function S.rank(src)
    if src == 0 then return 4 end
    local ok, r = pcall(function() return exports.pickax_core:StaffRank(src) end)
    r = ok and tonumber(r) or nil
    return r
end

function S.can(src, key)
    local r = S.rank(src)
    if not r then return false end
    if r >= 4 then return true end
    local need = S.perms[key] or Config.Perm[key]
    return need ~= nil and r >= need
end

-- le staff ne peut sanctionner qu'un joueur de rang inférieur (ou un joueur normal)
function S.outranks(src, target)
    if src == 0 then return true end
    local rs, rt = S.rank(src) or 0, S.rank(target)
    if not rt then return true end
    return rs > rt or rs >= 4
end

function S.name(src) return src == 0 and 'Console' or (GetPlayerName(src) or ('ID ' .. tostring(src))) end

function S.license(src)
    if src == 0 then return 'console' end
    return ESX.GetIdentifierFromId and ESX.GetIdentifierFromId(src, 'license:') or GetPlayerIdentifierByType(src, 'license')
end

local function decode(s, def)
    if not s or s == '' then return def end
    local ok, r = pcall(json.decode, s)
    if ok and r ~= nil then return r end
    return def
end
S.decode = decode

-- ─────────────── Base de données ───────────────
CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS staff_logs (
        id INT AUTO_INCREMENT PRIMARY KEY, created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        staff_license VARCHAR(80) NOT NULL DEFAULT '', staff_name VARCHAR(80) NOT NULL DEFAULT '',
        action VARCHAR(40) NOT NULL, target_license VARCHAR(80) NULL, target_name VARCHAR(80) NULL, details VARCHAR(500) NULL,
        KEY idx_created (created), KEY idx_target (target_license), KEY idx_staff (staff_license)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS staff_warns (
        id INT AUTO_INCREMENT PRIMARY KEY, created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        license VARCHAR(80) NOT NULL, name VARCHAR(80) NOT NULL DEFAULT '', staff_name VARCHAR(80) NOT NULL DEFAULT '', reason VARCHAR(300) NOT NULL,
        KEY idx_license (license)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS staff_notes (
        id INT AUTO_INCREMENT PRIMARY KEY, created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        license VARCHAR(80) NOT NULL, staff_name VARCHAR(80) NOT NULL DEFAULT '', note VARCHAR(500) NOT NULL, KEY idx_license (license)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS staff_settings (k VARCHAR(30) NOT NULL PRIMARY KEY, v LONGTEXT NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    for _, r in ipairs(MySQL.query.await('SELECT k, v FROM staff_settings') or {}) do
        if r.k == 'perms' then S.perms = decode(r.v, {})
        elseif r.k == 'bookmarks' then S.bookmarks = decode(r.v, {}) end
    end
    MySQL.update('DELETE FROM staff_logs WHERE created < (NOW() - INTERVAL ? DAY)', { Config.LogDays })
    S.ready = true
end)

function S.saveSetting(k, v)
    MySQL.update('INSERT INTO staff_settings (k, v) VALUES (?, ?) ON DUPLICATE KEY UPDATE v = VALUES(v)', { k, json.encode(v) })
end

-- ─────────────── Journal ───────────────
-- target : source du joueur visé (optionnel)
function S.log(src, action, target, details)
    local tl, tn = nil, nil
    if target and GetPlayerName(target) then tl, tn = S.license(target), GetPlayerName(target) end
    local d = type(details) == 'table' and json.encode(details) or (details and tostring(details) or nil)
    MySQL.insert('INSERT INTO staff_logs (staff_license, staff_name, action, target_license, target_name, details) VALUES (?, ?, ?, ?, ?, ?)',
        { S.license(src) or '', S.name(src):sub(1, 80), action, tl, tn and tn:sub(1, 80), d and d:sub(1, 500) })
end

-- ─────────────── Enregistrement des callbacks ───────────────
function S.reg(name, key, fn)
    ESX.RegisterServerCallback('pickax_staff:' .. name, function(src, cb, ...)
        if not S.can(src, key) then return cb(fail('Accès refusé')) end
        local ok, res = pcall(fn, src, ...)
        if not ok then print('^1[pickax_staff]^7 ' .. name .. ' : ' .. tostring(res)) return cb(fail('Erreur serveur')) end
        cb(res)
    end)
end

-- Informations d'ouverture : rang, droits effectifs, listes de config
S.reg('open', 'panel', function(src)
    local perms = {}
    for key, need in pairs(Config.Perm) do
        perms[key] = S.can(src, key)
    end
    -- droits qui restent gérés par l'ancien système (wipe, capture d'écran)
    local okW, w = pcall(function() return exports.pickax_core:StaffPerm(src, 'func_18') end)
    local okS, sc = pcall(function() return exports.pickax_core:StaffPerm(src, 'take_screen') end)
    perms.wipe, perms.screenshot = okW and w == true, okS and sc == true
    return { ok = true, rank = S.rank(src), name = S.name(src), id = src, perms = perms, service = exports.pickax_core:StaffInService(src) == true,
        cfg = { banDurations = Config.BanDurations, jailPresets = Config.JailPresets, reasons = Config.Reasons, weather = Config.Weather, quickTp = Config.QuickTP, cleanupMax = Config.CleanupMaxRadius,
                announceMax = Config.AnnounceMax }, bookmarks = S.bookmarks }
end)
