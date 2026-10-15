-- pickax_panel : agent de liaison avec le panel web.
--
--  • UNE ligne dans server.cfg (la clé est générée par le panel, page « Mes serveurs ») :
--        set pickax_panel_key "https://ton-panel.exemple|CLE_SECRETE"
--  • Le serveur APPELLE le panel toutes les 15 s (connexion sortante : aucun port à ouvrir) :
--      - il envoie la liste des réglages de TES scripts et leurs valeurs actuelles (lues dans tes fichiers existants),
--      - il reçoit les réglages enregistrés sur le site et les applique (même méthode que schema.lua / patcher.lua).
--  • Les réglages sont stockés par le panel : après un `git pull` qui écrase un config, ils sont réappliqués au démarrage.

local RES = GetCurrentResourceName()
local RAW = GetConvar('pickax_panel_key', '')
local URL, LICENSE = RAW:match('^(https?://[^|]+)|(.+)$')
if URL then URL = URL:gsub('/+$', '') end

local function log(msg) print(('^5[pickax_panel]^7 %s'):format(msg)) end

if not URL or #LICENSE < 16 then
    log('^1Clé de liaison absente ou invalide.^7 Dans le panel : Mes serveurs → ton serveur → copie la ligne  set pickax_panel_key "..."  dans server.cfg.')
    return
end

-- ───────────── Lecture de l'état actuel ─────────────
local function readAll()
    local cache, values, status = {}, {}, {}
    for id, f in pairs(PanelFields) do
        if f.convar then
            values[id] = GetConvar(f.convar, '')
        else
            local key = f.resource .. '/' .. f.file
            if cache[key] == nil then cache[key] = LoadResourceFile(f.resource, f.file) or false end
            if not cache[key] then
                status[id] = 'fichier introuvable (' .. key .. ')'
            else
                local v, err = Patcher.read(cache[key], f)
                if v == nil then status[id] = err or 'valeur introuvable' else values[id] = v end
            end
        end
    end
    return values, status
end

-- Remplace des valeurs dans les fichiers (en mémoire) ; renvoie les fichiers modifiés ou nil, erreur
local function stage(changes)
    local files = {}
    local function get(resource, file)
        local key = resource .. '/' .. file
        if not files[key] then
            local c = LoadResourceFile(resource, file)
            if not c then return nil, key end
            files[key] = { resource = resource, file = file, content = c, original = c }
        end
        return files[key]
    end
    for id, value in pairs(changes) do
        local f = PanelFields[id]
        local entry, key = get(f.resource, f.file)
        if not entry then return nil, ('%s : fichier introuvable (%s)'):format(f.label, key) end
        local new, err = Patcher.write(entry.content, f, value)
        if not new then return nil, ('%s : %s'):format(f.label, err) end
        entry.content = new
        for _, comp in ipairs(f.also or {}) do
            local ce, ck = get(f.resource, comp.file or f.file)
            if not ce then return nil, ('%s : fichier introuvable (%s)'):format(f.label, ck) end
            local cnew, cerr = Patcher.writeCompanion(ce.content, comp, value)
            if not cnew then return nil, ('%s : %s'):format(f.label, cerr) end
            ce.content = cnew
        end
    end
    local out = {}
    for key, e in pairs(files) do
        if e.content ~= e.original then out[key] = e end
    end
    return out
end

local function commit(staged)
    local touched = {}
    for key, e in pairs(staged) do
        if not SaveResourceFile(e.resource, e.file, e.content, #e.content) then return false, 'écriture impossible : ' .. key end
        touched[e.resource] = true
    end
    return true, touched
end

-- ───────────── Redémarrages ─────────────
local pending = {}   -- ressources modifiées mais pas encore redémarrées

AddEventHandler('onResourceStart', function(name) pending[name] = nil end)

local function restartResource(name)
    pending[name] = nil
    if GetResourceState(name) == 'missing' then return false end
    ExecuteCommand('restart ' .. name)
    return true
end

local function managed(name)
    for _, g in ipairs(PanelSchema) do if g.resource == name then return true end end
    return false
end

-- ───────────── Application des réglages reçus ─────────────
local acks = {}   -- accusés envoyés au panel à la prochaine synchronisation

local function applyDesired(desired, boot)
    local current, status = readAll()
    local files, convars, want = {}, {}, {}
    local touchedIds = 0
    for id, d in pairs(desired) do
        local f = PanelFields[id]
        local needAck = d.status ~= 'applied'   -- on n'accuse réception que des changements en attente (évite un échange permanent)
        if not f then
            acks[id] = { err = 'réglage inconnu de ce serveur', value = d.value }
        elseif status[id] then
            acks[id] = { err = status[id], value = d.value }
        else
            local v, err = Patcher.validate(f, d.value, f.type == 'rgba' and #current[id] or nil)
            if v == nil then
                acks[id] = { err = err, value = d.value }
            elseif Patcher.equal(v, current[id]) then
                if needAck then acks[id] = { ok = true, value = v } end
            elseif f.convar then
                convars[id] = v
            else
                files[id] = v
                if d.restart then want[f.resource] = true end
            end
        end
    end

    for id, v in pairs(convars) do
        local f = PanelFields[id]
        if f.info then SetConvarServerInfo(f.convar, v) else SetConvar(f.convar, v) end
        acks[id] = { ok = true, value = v }
        touchedIds = touchedIds + 1
        log(('%s appliqué'):format(id))
    end

    if next(files) then
        local staged, err = stage(files)
        local ok, touched
        if staged then ok, touched = commit(staged) end
        if not staged or not ok then
            local msg = err or touched
            for id, v in pairs(files) do acks[id] = { err = msg, value = v } end
            log('^1' .. tostring(msg))
        else
            for id, v in pairs(files) do
                acks[id] = { ok = true, value = v }
                touchedIds = touchedIds + 1
                log(('%s appliqué'):format(id))
            end
            for res in pairs(touched) do
                if want[res] or (boot and GetResourceState(res) == 'started') then
                    log(('redémarrage de %s'):format(res))
                    restartResource(res)
                elseif GetResourceState(res) == 'started' then
                    pending[res] = true
                end
            end
        end
    end
    return touchedIds
end

-- ───────────── Synchronisation avec le panel ─────────────
local function exportGroups(values, status)
    local groups = {}
    for _, g in ipairs(PanelSchema) do
        local out = { id = g.id, label = g.label, icon = g.icon, resource = g.resource, desc = g.desc, fields = {} }
        if g.resource then out.state = GetResourceState(g.resource) end
        for _, f in ipairs(g.fields) do
            local o = {
                id = f.id, section = f.section, label = f.label, hint = f.hint, type = f.type, min = f.min, max = f.max,
                unit = f.unit, int = f.int, named = f.named, value = values[f.id], error = status[f.id],
            }
            if f.type == 'rgba' and values[f.id] then o.alpha = #values[f.id] >= 4 end
            out.fields[#out.fields + 1] = o
        end
        groups[#groups + 1] = out
    end
    return groups
end

local connected, firstSync, lastError = false, true, nil

local function pendingList()
    local list = {}
    for r in pairs(pending) do list[#list + 1] = r end
    table.sort(list)
    return list
end

local sync
local function schedule(ms) SetTimeout(ms, function() sync() end) end

sync = function()
    local values, status = readAll()
    local resources = {}
    for _, g in ipairs(PanelSchema) do if g.resource then resources[g.resource] = GetResourceState(g.resource) end end
    local sending = acks
    acks = {}
    local payload = {
        groups = exportGroups(values, status),
        acks = sending,
        pendingRestart = pendingList(),
        info = {
            hostname = GetConvar('sv_hostname', ''), players = #GetPlayers(), maxPlayers = GetConvarInt('sv_maxclients', 48),
            resources = resources, version = '2.0.0',
        },
    }
    PerformHttpRequest(URL .. '/api/agent/sync', function(code, body)
        local ok, data = false, nil
        if code == 200 and body then ok, data = pcall(json.decode, body) end
        if not ok or type(data) ~= 'table' then
            -- on garde les accusés pour le prochain essai
            for id, a in pairs(sending) do if not acks[id] then acks[id] = a end end
            local why = code == 401 and 'licence refusée (clé régénérée ou supprimée ?)' or ('panel injoignable (code ' .. tostring(code) .. ')')
            if lastError ~= why then log('^1' .. why) lastError = why end
            connected = false
            return schedule(30000)
        end
        if not connected or lastError then log('^2Connecté au panel^7 ' .. URL) end
        connected, lastError = true, nil

        local boot = firstSync
        firstSync = false
        local n = applyDesired(data.desired or {}, boot)
        for _, name in ipairs(data.restart or {}) do
            if managed(name) then log(('redémarrage de %s demandé depuis le panel'):format(name)) restartResource(name) end
        end
        -- accusés à renvoyer vite pour que le panel affiche « appliqué » sans attendre
        if n > 0 and next(acks) then return schedule(800) end
        schedule(math.max(5, tonumber(data.interval) or 15) * 1000)
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json', ['X-License'] = LICENSE })
end

CreateThread(function()
    Wait(3000)   -- laisse démarrer les autres ressources
    sync()
end)

log(('Liaison avec le panel : %s'):format(URL))
