-- Réglages du serveur (panel web). Optimisation : rien ne tourne tant que rien n'est réglé ; aucune boucle par image ;
-- les valeurs sont lues une fois puis mises en cache par chaque ressource (événement pickax_settings:changed).
local SELF = GetCurrentResourceName()
local FILE = 'settings.json'
local DEF, ORDER = {}, {}
for i, d in ipairs(Settings.Schema) do DEF[d.key] = d ORDER[i] = d.key end

local function clean(def, v)
    if def.type == 'bool' then if type(v) == 'boolean' then return true, v end return false end
    if def.type == 'number' then
        v = tonumber(v)
        if not v or v ~= v then return false end
        return true, math.max(def.min or -1e9, math.min(def.max or 1e9, v))
    end
    if def.type == 'select' then for _, o in ipairs(def.options or {}) do if o[1] == v then return true, v end end return false end
    if def.type == 'text' then
        if type(v) ~= 'string' or #v > 300 or v:find('[%c]') then return false end
        return true, v
    end
    if def.type == 'list' then
        if type(v) ~= 'table' or #v > 20 then return false end
        local out = {}
        for _, x in ipairs(v) do
            if type(x) ~= 'string' or #x > 200 or x:find('[%c]') then return false end
            if x ~= '' then out[#out + 1] = x end
        end
        return true, out
    end
    return false
end

local function same(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) == 'table' then
        if #a ~= #b then return false end
        for i = 1, #a do if a[i] ~= b[i] then return false end end
        return true
    end
    return a == b
end

local over = {}   -- surcharges (valeurs différentes de la valeur par défaut)
do
    local raw = LoadResourceFile(SELF, FILE)
    if raw and raw ~= '' then
        local ok, t = pcall(json.decode, raw)
        if ok and type(t) == 'table' then
            for k, v in pairs(t) do
                local def = DEF[k]
                if def then local good, c = clean(def, v) if good and not same(c, def.default) then over[k] = c end end
            end
        end
    end
end

local saveTimer = false
local function persist()
    if saveTimer then return end
    saveTimer = true
    SetTimeout(2000, function() saveTimer = false SaveResourceFile(SELF, FILE, json.encode(over), -1) end)
end

local function effective()
    local all = {}
    for k, def in pairs(DEF) do local v = over[k] if v == nil then v = def.default end all[k] = v end
    return all
end

-- Les réglages « secrets » (ex : adresse du webhook Discord) ne sont JAMAIS envoyés aux joueurs
local function clientView(tbl)
    local o = {}
    for k, v in pairs(tbl) do if not (DEF[k] and DEF[k].secret) then o[k] = v end end
    return o
end
local function broadcast(target)
    TriggerClientEvent('pickax_settings:sync', target or -1, clientView(effective()), clientView(over))
end

local features = {}   -- applicateurs (annonces, redémarrages, maintenance) : réévalués à chaque changement
local function changed(keys)
    TriggerEvent('pickax_settings:changed', effective(), over, keys)
    broadcast()
    for _, f in ipairs(features) do pcall(f) end
end

local function get(key) local def = DEF[key] if not def then return nil end local v = over[key] if v == nil then return def.default end return v end
exports('Get', get)
Settings.Get = get   -- utilisé par server/gameplay.lua
exports('GetAll', effective)
exports('Overrides', function() return over end)
exports('Schema', function()
    local out = {}
    for i, k in ipairs(ORDER) do local d = DEF[k] out[i] = { key = d.key, group = d.group, label = d.label, type = d.type, default = d.default, min = d.min, max = d.max, step = d.step, options = d.options, hint = d.hint, section = d.section } end
    return out
end)

local function setMany(tbl, replace)
    local touched = {}
    if replace then
        for k in pairs(over) do if tbl[k] == nil then over[k] = nil touched[#touched + 1] = k end end
    end
    for k, v in pairs(tbl) do
        local def = DEF[k]
        if def then
            if v == nil or (type(v) == 'table' and v.__reset) then
                if over[k] ~= nil then over[k] = nil touched[#touched + 1] = k end
            else
                local good, c = clean(def, v)
                if good then
                    if same(c, def.default) then
                        if over[k] ~= nil then over[k] = nil touched[#touched + 1] = k end
                    elseif not same(over[k], c) then over[k] = c touched[#touched + 1] = k end
                end
            end
        end
    end
    if #touched > 0 then persist() changed(touched) end
    return #touched
end
exports('Set', function(key, value) return setMany({ [key] = value }) end)
exports('SetMany', function(tbl) return type(tbl) == 'table' and setMany(tbl) or 0 end)
exports('ApplyRemote', function(tbl) if type(tbl) ~= 'table' then return 0 end return setMany(tbl, true) end)   -- le panel envoie l'ensemble des surcharges
exports('Reset', function(key) return setMany({ [key] = { __reset = true } }) end)

RegisterNetEvent('pickax_settings:request', function() broadcast(source) end)

-- FPS rapportés par les joueurs (1 message par minute et par joueur) : moyenne affichée dans le panel web
local fpsBy = {}
RegisterNetEvent('pickax_settings:fps', function(fps, perf)
    local src = source
    fps = tonumber(fps)
    if not fps or fps < 1 or fps > 1000 then return end
    local now = GetGameTimer()
    local cur = fpsBy[src]
    if cur and now - cur.at < 30000 then return end
    fpsBy[src] = { fps = fps, perf = perf == true, at = now }
end)
AddEventHandler('playerDropped', function() fpsBy[source] = nil end)
exports('FpsStats', function()
    local n, sum, low, perf = 0, 0, 0, 0
    for _, v in pairs(fpsBy) do n = n + 1 sum = sum + v.fps if v.fps < 30 then low = low + 1 end if v.perf then perf = perf + 1 end end
    return { n = n, avg = n > 0 and math.floor(sum / n + 0.5) or 0, low = low, perf = perf }
end)

local function say(msg)
    TriggerClientEvent('pickax_notify:showNotification', -1, msg)
    TriggerClientEvent('chat:addMessage', -1, { args = { 'Serveur', (msg:gsub('~%a~', '')) } })
end

-- ───────── Mode maintenance ─────────
local function isStaff(src)
    return IsPlayerAceAllowed(src, 'command') or IsPlayerAceAllowed(src, 'pickax.maintenance')
end
local function allowed(src)
    if isStaff(src) then return true end
    local list = get('maintenance_allow') or {}
    if #list == 0 then return false end
    local ids = {}
    for _, id in ipairs(GetPlayerIdentifiers(src)) do ids[id] = true end
    for _, a in ipairs(list) do if ids[a] then return true end end
    return false
end
AddEventHandler('playerConnecting', function(name, setKick, deferrals)
    if not get('maintenance_enabled') then return end
    local src = source
    deferrals.defer() Wait(0)
    if allowed(src) then deferrals.done() else deferrals.done(get('maintenance_message') or 'Serveur en maintenance.') end
end)
local wasMaint = get('maintenance_enabled')
features[#features + 1] = function()
    local now = get('maintenance_enabled')
    if now and not wasMaint then
        say('~r~Maintenance du serveur~s~ : les joueurs seront déconnectés dans 2 minutes.')
        if get('maintenance_kick') then
            SetTimeout(120000, function()
                if not get('maintenance_enabled') then return end
                for _, p in ipairs(GetPlayers()) do
                    p = tonumber(p)
                    if not allowed(p) then DropPlayer(p, get('maintenance_message') or 'Maintenance') end
                end
            end)
        end
    end
    wasMaint = now
end

-- ───────── Annonces automatiques (un seul fil, arrêté dès que la fonction est désactivée) ─────────
local announceGen = 0
local function startAnnounce()
    announceGen = announceGen + 1
    if not get('announce_enabled') then return end
    local gen, idx = announceGen, 0
    CreateThread(function()
        while gen == announceGen do
            local minutes = tonumber(get('announce_interval')) or 15
            for _ = 1, math.floor(minutes * 6) do          -- attente par tranches de 10 s : un changement d'intervalle est pris en compte rapidement
                Wait(10000)
                if gen ~= announceGen then return end
            end
            local list = get('announce_messages') or {}
            if #list > 0 and #GetPlayers() > 0 then
                idx = idx % #list + 1
                say(list[idx])
            end
        end
    end)
end
features[#features + 1] = startAnnounce

-- ───────── Redémarrages programmés (tick de 30 s, seulement si activé) ─────────
local restartGen = 0
local WARN = { 30, 10, 5, 1 }
local function parseTimes(s)
    local out = {}
    for h, m in tostring(s or ''):gmatch('(%d%d?):(%d%d)') do
        h, m = tonumber(h), tonumber(m)
        if h < 24 and m < 60 then out[#out + 1] = h * 60 + m end
    end
    return out
end
local function startRestart()
    restartGen = restartGen + 1
    if not get('restart_enabled') then return end
    local gen, last = restartGen, nil
    CreateThread(function()
        while gen == restartGen do
            Wait(30000)
            if gen ~= restartGen then return end
            local d = os.date('*t')
            local cur = d.hour * 60 + d.min
            local key = d.yday * 1440 + cur
            if key ~= last then
                for _, t in ipairs(parseTimes(get('restart_times'))) do
                    local left = (t - cur) % 1440
                    if left == 0 then
                        last = key
                        say('~r~Redémarrage du serveur en cours…~s~')
                        SetTimeout(5000, function() ExecuteCommand('quit') end)
                    else
                        for _, w in ipairs(WARN) do
                            if left == w then last = key say(('~y~Redémarrage du serveur dans %d minute%s.~s~'):format(w, w > 1 and 's' or '')) end
                        end
                    end
                end
            end
        end
    end)
end
features[#features + 1] = startRestart

CreateThread(function() Wait(3000) startAnnounce() startRestart() end)
print(('^2[pickax_settings]^7 %d réglage(s) disponible(s), %d personnalisé(s).'):format(#ORDER, (function() local n = 0 for _ in pairs(over) do n = n + 1 end return n end)()))
