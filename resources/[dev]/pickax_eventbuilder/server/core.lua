ESX = exports['es_extended']:getSharedObject()

EB = {
    Defs = {},       -- [id] = définition complète
    ByName = {},     -- [name] = id
    Active = {},     -- [rid] = événement en cours
    LastEnd = {},    -- [defId] = os.time() de la dernière fin (cooldown)
    NextRid = 1,
    ready = false,
}

function EB.decode(str, default)
    if not str or str == '' then return default end
    local ok, res = pcall(json.decode, str)
    if ok and res ~= nil then return res end
    return default
end

function EB.isAdmin(src)
    if src == 0 then return true end
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        local g = xPlayer.getGroup()
        for _, allowed in ipairs(Config.AllowedGroups) do
            if g == allowed then return true end
        end
    end
    return Config.AcePermission and Config.AcePermission ~= '' and IsPlayerAceAllowed(src, Config.AcePermission) or false
end

function EB.playerName(xPlayer)
    return xPlayer.getName and xPlayer.getName() or GetPlayerName(xPlayer.source)
end

function EB.distanceTo(src, c)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return 9999.0 end
    local p = GetEntityCoords(ped)
    return #(vector3(p.x, p.y, p.z) - vector3(c.x, c.y, c.z))
end

function EB.copy(t)
    if type(t) ~= 'table' then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = EB.copy(v) end
    return o
end

function EB.policeCount()
    local n = 0
    local jobs = {}
    for _, j in ipairs(Config.PoliceJobs) do jobs[j] = true end
    for _, xPlayer in pairs(ESX.GetExtendedPlayers()) do
        if xPlayer.job and jobs[xPlayer.job.name] then n = n + 1 end
    end
    return n
end

function EB.log(def, xPlayer, action, detail, amount)
    MySQL.insert('INSERT INTO eventbuilder_logs (event_id, event_label, identifier, player_name, action, detail, amount) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        def and def.id or 0, def and def.label or '—', xPlayer and xPlayer.identifier or nil, xPlayer and EB.playerName(xPlayer) or 'système',
        action, detail and tostring(detail):sub(1, 255) or nil, math.floor(tonumber(amount) or 0),
    })
    if Config.Webhook and Config.Webhook ~= '' then
        PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode({
            username = 'EventBuilder',
            embeds = {{ title = ('[%s] %s'):format(def and def.label or '—', action), description = ('%s\n%s'):format(xPlayer and EB.playerName(xPlayer) or 'système', detail or ''), color = 15158332 }},
        }), { ['Content-Type'] = 'application/json' })
    end
end

-- ─────────────────────────────── Base de données ───────────────────────────────
local function installTables()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS eventbuilder_events (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(40) NOT NULL UNIQUE,
        label VARCHAR(60) NOT NULL,
        type VARCHAR(20) NOT NULL,
        enabled TINYINT(1) NOT NULL DEFAULT 1,
        data LONGTEXT NOT NULL,
        created_by VARCHAR(80) NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS eventbuilder_logs (
        id INT AUTO_INCREMENT PRIMARY KEY,
        event_id INT NOT NULL DEFAULT 0,
        event_label VARCHAR(60) NOT NULL DEFAULT '',
        identifier VARCHAR(80) NULL,
        player_name VARCHAR(80) NOT NULL DEFAULT 'système',
        action VARCHAR(40) NOT NULL,
        detail VARCHAR(255) NULL,
        amount INT NOT NULL DEFAULT 0,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_created (created_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
end

function EB.loadAll()
    EB.Defs, EB.ByName = {}, {}
    for _, row in ipairs(MySQL.query.await('SELECT * FROM eventbuilder_events') or {}) do
        local d = EB.decode(row.data, {})
        d.id, d.name, d.label, d.type, d.enabled = row.id, row.name, row.label, row.type, row.enabled == 1 or row.enabled == true
        EB.Defs[row.id] = d
        EB.ByName[row.name] = row.id
    end
end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    installTables()
    EB.loadAll()
    EB.ready = true
    local n = 0
    for _ in pairs(EB.Defs) do n = n + 1 end
    print(('^2[eventbuilder] %d événement(s) chargé(s).^0'):format(n))
end)
