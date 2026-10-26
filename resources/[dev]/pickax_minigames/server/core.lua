ESX = exports['es_extended']:getSharedObject()

MG = {
    Defs = {},        -- [id] = définition complète
    Games = {},       -- [id] = partie en cours (lobby / match)
    InGame = {},      -- [src] = id de la partie
    Cool = {},        -- [identifier..id] = os.time() autorisé
    ready = false,
}

function MG.decode(str, default)
    if not str or str == '' then return default end
    local ok, res = pcall(json.decode, str)
    if ok and res ~= nil then return res end
    return default
end

function MG.isAdmin(src)
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

function MG.playerName(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer and xPlayer.getName then return xPlayer.getName() end
    return (src and src > 0 and GetPlayerName(src)) or ('Joueur ' .. tostring(src))
end

function MG.identifier(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    return xPlayer and xPlayer.identifier or nil
end

function MG.distanceTo(src, c)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return 9999.0 end
    local p = GetEntityCoords(ped)
    return #(vector3(p.x, p.y, p.z) - vector3(c.x, c.y, c.z))
end

function MG.notify(src, msg)
    TriggerClientEvent('esx:showNotification', src, msg)
end

function MG.log(src, action, gameId, details)
    local name = src and src ~= 0 and MG.playerName(src) or 'Console'
    MySQL.insert('INSERT INTO minigames_logs (actor, action, game_id, details) VALUES (?, ?, ?, ?)', { name, action, gameId or '', details or '' })
    if Config.Webhook and Config.Webhook ~= '' then
        PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode({
            username = 'Mini-jeux',
            embeds = { { title = 'Mini-jeux · ' .. action, description = (gameId and gameId ~= '' and ('**' .. gameId .. '**\n') or '') .. (details or ''), footer = { text = name }, color = 41215 } },
        }), { ['Content-Type'] = 'application/json' })
    end
end

local function installTables()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS minigames_defs (
        id VARCHAR(40) NOT NULL PRIMARY KEY,
        data LONGTEXT NOT NULL,
        updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS minigames_stats (
        game_id VARCHAR(40) NOT NULL,
        identifier VARCHAR(80) NOT NULL,
        name VARCHAR(80) NOT NULL DEFAULT '',
        plays INT NOT NULL DEFAULT 0,
        wins INT NOT NULL DEFAULT 0,
        best INT NOT NULL DEFAULT 0,
        total INT NOT NULL DEFAULT 0,
        best_time INT NOT NULL DEFAULT 0,
        last_play TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (game_id, identifier)
    )]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS minigames_logs (
        id INT AUTO_INCREMENT PRIMARY KEY,
        created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        actor VARCHAR(80) NOT NULL DEFAULT '',
        action VARCHAR(40) NOT NULL DEFAULT '',
        game_id VARCHAR(40) NOT NULL DEFAULT '',
        details TEXT
    )]])
end

function MG.loadAll()
    MG.Defs = {}
    local rows = MySQL.query.await('SELECT id, data FROM minigames_defs') or {}
    for _, r in ipairs(rows) do
        local d = MG.decode(r.data, nil)
        if d and Config.Types[d.type] then
            d.id = r.id
            MG.Defs[r.id] = d
        end
    end
end

-- Définitions actives envoyées aux clients (markers, moteurs de jeu)
function MG.publicDefs()
    local out = {}
    for id, d in pairs(MG.Defs) do
        if d.enabled then out[id] = d end
    end
    return out
end

function MG.sync(target)
    TriggerClientEvent('minigames:sync', target or -1, MG.publicDefs())
end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    installTables()
    MG.loadAll()
    Progress.load()
    MG.ready = true
    MG.sync()
    print(('^2[minigames]^7 %d mini-jeu(x) chargé(s)'):format((function() local n = 0 for _ in pairs(MG.Defs) do n = n + 1 end return n end)()))
end)

AddEventHandler('esx:playerLoaded', function(src)
    if MG.ready then MG.sync(src) end
end)

RegisterNetEvent('minigames:requestSync', function()
    if MG.ready then MG.sync(source) end
end)

-- [AERO] contrôle de licence (pickax_guard) : cette ressource s'arrête si la licence n'est pas valide ou si pickax_guard est absent
CreateThread(function()
    local res = GetCurrentResourceName()
    Wait(20000 + math.random(0, 20000))
    while true do
        local valid = false
        for _ = 1, 4 do
            local ok, v = pcall(function() return exports.pickax_guard:Check(res) end)
            if ok and v == true then valid = true break end
            Wait(10000)
        end
        if not valid then print(('^1[AERO] %s arrêtée : licence invalide ou pickax_guard absent.^0'):format(res)) StopResource(res) return end
        Wait(240000 + math.random(0, 120000))
    end
end)
