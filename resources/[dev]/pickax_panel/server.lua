-- pickax_panel : panel web de configuration.
--  • Accès : http://IP_DU_SERVEUR:30120/pickax_panel/  (même port que le serveur de jeu)
--  • Clé d'accès : une seule ligne dans server.cfg →  set pickax_panel_key "UneCleLongueEtSecrete"
--  • Base de données : table pickax_panel_settings (les réglages survivent aux `git pull` : ils sont réappliqués au démarrage)

local RES = GetCurrentResourceName()
local KEY = GetConvar('pickax_panel_key', '')
local KEY_OK = #KEY >= 12

local function log(msg) print(('^5[pickax_panel]^7 %s'):format(msg)) end

-- ───────────── Base de données ─────────────
MySQL.ready(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS pickax_panel_settings (
        field VARCHAR(80) NOT NULL PRIMARY KEY,
        value LONGTEXT NOT NULL,
        original LONGTEXT NULL,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) CHARACTER SET utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS pickax_panel_log (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        field VARCHAR(80) NOT NULL,
        old_value TEXT NULL,
        new_value TEXT NULL,
        source VARCHAR(40) NULL
    ) CHARACTER SET utf8mb4]])
    CreateThread(function() Wait(500) TriggerEvent('pickax_panel:dbReady') end)
end)

-- ───────────── Fichiers ─────────────
local function readFile(resource, file)
    return LoadResourceFile(resource, file)
end

-- Lit la valeur actuelle de tous les champs (fichiers lus une seule fois)
local function readAll()
    local cache, values, status = {}, {}, {}
    for id, f in pairs(PanelFields) do
        local key = f.resource .. '/' .. f.file
        if cache[key] == nil then cache[key] = readFile(f.resource, f.file) or false end
        if not cache[key] then
            status[id] = 'fichier introuvable (' .. key .. ')'
        else
            local v, err = Patcher.read(cache[key], f)
            if v == nil then status[id] = err or 'valeur introuvable' else values[id] = v end
        end
    end
    return values, status
end

-- Applique des changements { id = valeur } en mémoire ; renvoie fichiers modifiés { 'res/file' = {resource,file,content} } ou nil, erreur
local function stage(changes)
    local files = {}
    local function get(resource, file)
        local key = resource .. '/' .. file
        if not files[key] then
            local c = readFile(resource, file)
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
        if not SaveResourceFile(e.resource, e.file, e.content, #e.content) then
            return false, 'écriture impossible : ' .. key
        end
        touched[e.resource] = true
    end
    return true, touched
end

-- ───────────── Redémarrages ─────────────
local pending = {}   -- ressources modifiées mais pas encore redémarrées

AddEventHandler('onResourceStart', function(name)
    if pending[name] then pending[name] = nil end
end)

local function restartResource(name)
    if GetResourceState(name) == 'missing' then pending[name] = nil return false end
    pending[name] = nil
    ExecuteCommand('restart ' .. name)
    return true
end

-- ───────────── Enregistrement ─────────────
local function logChange(id, old, new, source)
    MySQL.insert('INSERT INTO pickax_panel_log (field, old_value, new_value, source) VALUES (?, ?, ?, ?)',
        { id, json.encode(old), json.encode(new), source })
end

local function save(changes, apply, source)
    local current, status = readAll()
    local valid, order = {}, {}
    for id, raw in pairs(changes) do
        local f = PanelFields[id]
        if not f then return nil, 'réglage inconnu : ' .. tostring(id) end
        if status[id] then return nil, ('%s : %s'):format(f.label, status[id]) end
        local cur = current[id]
        local v, err = Patcher.validate(f, raw, f.type == 'rgba' and #cur or nil)
        if v == nil then return nil, ('%s : %s'):format(f.label, err) end
        if not Patcher.equal(v, cur) then valid[id] = v order[#order + 1] = id end
    end
    if #order == 0 then return { saved = 0, restarted = {}, pending = pending } end

    local staged, err = stage(valid)
    if not staged then return nil, err end
    local ok, touched = commit(staged)
    if not ok then return nil, touched end

    local rows = MySQL.query.await('SELECT field FROM pickax_panel_settings') or {}
    local has = {}
    for _, r in ipairs(rows) do has[r.field] = true end
    for _, id in ipairs(order) do
        local f = PanelFields[id]
        if has[id] then
            MySQL.update.await('UPDATE pickax_panel_settings SET value = ? WHERE field = ?', { json.encode(valid[id]), id })
        else
            MySQL.insert.await('INSERT INTO pickax_panel_settings (field, value, original) VALUES (?, ?, ?)',
                { id, json.encode(valid[id]), json.encode(current[id]) })
        end
        logChange(id, current[id], valid[id], source)
        log(('%s modifié (%s)'):format(id, source))
    end

    local restarted = {}
    for res in pairs(touched) do
        if apply then
            if restartResource(res) then restarted[#restarted + 1] = res end
        elseif GetResourceState(res) == 'started' then
            pending[res] = true
        end
    end
    return { saved = #order, restarted = restarted }
end

-- Restaure la valeur d'origine du script (celle présente avant la première modification via le panel)
local function reset(ids, apply, source)
    local rows = MySQL.query.await('SELECT field, original FROM pickax_panel_settings') or {}
    local originals = {}
    for _, r in ipairs(rows) do originals[r.field] = r.original end
    local changes = {}
    for _, id in ipairs(ids) do
        if originals[id] then changes[id] = json.decode(originals[id]) end
    end
    local current = readAll()
    local staged, err = stage(changes)
    if not staged then return nil, err end
    local ok, touched = commit(staged)
    if not ok then return nil, touched end
    for id in pairs(changes) do
        MySQL.update.await('DELETE FROM pickax_panel_settings WHERE field = ?', { id })
        logChange(id, current[id], changes[id], source .. ' (restauration)')
    end
    local restarted = {}
    for res in pairs(touched) do
        if apply then
            if restartResource(res) then restarted[#restarted + 1] = res end
        elseif GetResourceState(res) == 'started' then
            pending[res] = true
        end
    end
    return { saved = 0, restored = #ids, restarted = restarted }
end

-- ───────────── Réapplication au démarrage (après un git pull qui écrase les fichiers) ─────────────
AddEventHandler('pickax_panel:dbReady', function()
    local rows = MySQL.query.await('SELECT field, value FROM pickax_panel_settings') or {}
    local changes = {}
    local _, missing = readAll()
    for _, r in ipairs(rows) do
        if PanelFields[r.field] and missing[r.field] then
            log(('^3%s ignoré : %s'):format(r.field, missing[r.field]))
        elseif PanelFields[r.field] then
            local ok, v = pcall(json.decode, r.value)
            if ok and v ~= nil then changes[r.field] = v end
        end
    end
    if next(changes) == nil then return end
    local res, err = save(changes, false, 'démarrage')
    if not res then log('^1réapplication impossible : ' .. tostring(err)) return end
    if res.saved > 0 then
        log(('^2%d réglage(s) réappliqué(s) sur les fichiers (écrasés par une mise à jour ?)'):format(res.saved))
        for resource in pairs(pending) do
            log(('redémarrage de %s pour prendre en compte les réglages'):format(resource))
            restartResource(resource)
        end
    end
end)

-- ───────────── État pour l'interface ─────────────
local function buildState()
    local values, status = readAll()
    local rows = MySQL.query.await('SELECT field, original FROM pickax_panel_settings') or {}
    local overridden = {}
    for _, r in ipairs(rows) do overridden[r.field] = r.original end
    local groups = {}
    for _, g in ipairs(PanelSchema) do
        local out = { id = g.id, label = g.label, icon = g.icon, resource = g.resource, desc = g.desc,
            state = GetResourceState(g.resource), fields = {} }
        for _, f in ipairs(g.fields) do
            local o = {
                id = f.id, section = f.section, label = f.label, hint = f.hint, type = f.type, min = f.min, max = f.max, unit = f.unit,
                int = f.int, named = f.named, value = values[f.id], error = status[f.id],
            }
            if f.type == 'rgba' and values[f.id] then o.alpha = #values[f.id] >= 4 end
            if overridden[f.id] then
                local ok, orig = pcall(json.decode, overridden[f.id])
                o.modified = true
                if ok then o.original = orig end
            end
            out.fields[#out.fields + 1] = o
        end
        groups[#groups + 1] = out
    end
    local pend = {}
    for r in pairs(pending) do pend[#pend + 1] = r end
    table.sort(pend)
    return { groups = groups, pending = pend, server = GetConvar('sv_projectName', GetConvar('sv_hostname', '')), players = #GetPlayers() }
end

-- ───────────── HTTP ─────────────
local STATIC = {
    ['/'] = { 'web/index.html', 'text/html; charset=utf-8' },
    ['/index.html'] = { 'web/index.html', 'text/html; charset=utf-8' },
    ['/app.js'] = { 'web/app.js', 'application/javascript; charset=utf-8' },
    ['/app.css'] = { 'web/app.css', 'text/css; charset=utf-8' },
}

local CORS_ORIGIN = GetConvar('pickax_panel_origin', '*')   -- optionnel : restreindre à une origine, ex. http://localhost:8080

local function send(res, code, body, ctype)
    res.writeHead(code, {
        ['Content-Type'] = ctype or 'application/json; charset=utf-8',
        ['Cache-Control'] = 'no-store',
        ['X-Content-Type-Options'] = 'nosniff',
        ['X-Frame-Options'] = 'DENY',
        ['Referrer-Policy'] = 'no-referrer',
        -- Accès depuis un panel lancé sur un autre PC (localhost) : l'authentification se fait par la clé (en-tête), pas par cookie
        ['Access-Control-Allow-Origin'] = CORS_ORIGIN,
        ['Access-Control-Allow-Headers'] = 'X-Panel-Key, Content-Type',
        ['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS',
        ['Content-Security-Policy'] = "default-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self'",
    })
    res.send(body)
end

local function jsend(res, code, tbl) send(res, code, json.encode(tbl)) end

local function sameString(a, b)
    if #a ~= #b then return false end
    local diff = 0
    for i = 1, #a do diff = diff | (a:byte(i) ~ b:byte(i)) end
    return diff == 0
end

local function header(req, name)
    for k, v in pairs(req.headers or {}) do
        if k:lower() == name then return v end
    end
end

-- Anti brute-force : 6 essais ratés → blocage 10 min par adresse
local fails = {}
local function blocked(ip)
    local f = fails[ip]
    return f and f.n >= 6 and os.time() < f.t + 600
end
local function failed(ip)
    local f = fails[ip]
    if not f or os.time() > f.t + 600 then f = { n = 0 } fails[ip] = f end
    f.n = f.n + 1
    f.t = os.time()
end

local function authorized(req, res)
    local ip = req.address or '?'
    if blocked(ip) then jsend(res, 429, { error = 'Trop d\'essais, réessaie dans 10 minutes.' }) return false end
    local given = header(req, 'x-panel-key') or ''
    if not sameString(given, KEY) then
        failed(ip)
        jsend(res, 401, { error = 'Clé invalide.' })
        return false
    end
    fails[ip] = nil
    return true
end

local DEBUG = GetConvar('pickax_panel_debug', '0') == '1'
local seen = 0

local function handle(req, res, body)
    local path = (req.path or '/'):gsub('%?.*$', '')
    -- selon la version du serveur, le chemin peut contenir le nom de la ressource
    path = path:gsub('^/' .. RES, '')
    if path == '' then path = '/' end
    local method = req.method
    if DEBUG or seen < 5 then
        seen = seen + 1
        log(('requête reçue : %s %s depuis %s'):format(tostring(method), tostring(req.path), tostring(req.address)))
    end
    if path == '/ping' then return send(res, 200, 'pickax_panel OK', 'text/plain; charset=utf-8') end
    if method == 'OPTIONS' then return send(res, 204, '', 'text/plain') end

    if STATIC[path] and method == 'GET' then
        local s = STATIC[path]
        local content = LoadResourceFile(RES, s[1])
        if not content then return send(res, 404, 'introuvable', 'text/plain') end
        if path == '/' or path == '/index.html' then content = content:gsub('{{BASE}}', '/' .. RES .. '/'):gsub('{{REMOTE}}', 'no') end
        return send(res, 200, content, s[2])
    end

    if not path:find('^/api/') then return send(res, 404, 'introuvable', 'text/plain') end
    if not KEY_OK then
        return jsend(res, 503, { error = 'Aucune clé configurée : ajoute  set pickax_panel_key "..."  (12 caractères minimum) dans server.cfg.' })
    end
    if not authorized(req, res) then return end

    local data = {}
    if body and body ~= '' then
        local ok, decoded = pcall(json.decode, body)
        if not ok or type(decoded) ~= 'table' then return jsend(res, 400, { error = 'JSON invalide' }) end
        data = decoded
    end

    if path == '/api/state' and method == 'GET' then
        return jsend(res, 200, buildState())
    elseif path == '/api/log' and method == 'GET' then
        local rows = MySQL.query.await('SELECT UNIX_TIMESTAMP(at) AS at, field, old_value, new_value, source FROM pickax_panel_log ORDER BY id DESC LIMIT 60') or {}
        return jsend(res, 200, { log = rows })
    elseif path == '/api/save' and method == 'POST' then
        if type(data.changes) ~= 'table' then return jsend(res, 400, { error = 'Aucun changement' }) end
        local result, err = save(data.changes, data.apply == true, 'panel')
        if not result then return jsend(res, 400, { error = err }) end
        return jsend(res, 200, result)
    elseif path == '/api/reset' and method == 'POST' then
        if type(data.ids) ~= 'table' then return jsend(res, 400, { error = 'Aucun réglage' }) end
        local result, err = reset(data.ids, data.apply == true, 'panel')
        if not result then return jsend(res, 400, { error = err }) end
        return jsend(res, 200, result)
    elseif path == '/api/restart' and method == 'POST' then
        local name = tostring(data.resource or '')
        local allowed = false
        for _, g in ipairs(PanelSchema) do if g.resource == name then allowed = true end end
        if not allowed then return jsend(res, 400, { error = 'Ressource non gérée par le panel' }) end
        restartResource(name)
        return jsend(res, 200, { restarted = { name } })
    end
    return jsend(res, 404, { error = 'Route inconnue' })
end

SetHttpHandler(function(req, res)
    local function run(body)
        CreateThread(function()
            local ok, err = pcall(handle, req, res, body)
            if not ok then
                print(('^1[pickax_panel] erreur : %s^7'):format(tostring(err)))
                pcall(jsend, res, 500, { error = 'Erreur interne (voir la console du serveur)' })
            end
        end)
    end
    if req.method == 'POST' then req.setDataHandler(run) else run() end
end)

if KEY_OK then
    local ip = GetConvar('sv_listingIpOverride', '')
    if ip == '' or ip:find('IP_PUBLIQUE') then ip = 'IP_DU_SERVEUR' end
    log(('^2Panel prêt^7 → http://%s:%s/%s/   (test de connexion : /%s/ping)'):format(ip, GetConvar('netPort', '30120'), RES, RES))
else
    log('^1Aucune clé : ajoute dans server.cfg →  set pickax_panel_key "UneCleLongueEtSecrete"  (12 caractères minimum). Le panel reste désactivé.')
end
