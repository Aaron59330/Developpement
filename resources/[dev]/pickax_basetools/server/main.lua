ESX = exports['es_extended']:getSharedObject()

local function isAdmin(src)
    if src == 0 then return true end
    if Config.Ace and Config.Ace ~= '' and IsPlayerAceAllowed(src, Config.Ace) then return true end
    local x = ESX.GetPlayerFromId(src)
    if not x then return false end
    local g = x.getGroup()
    for _, a in ipairs(Config.AdminGroups) do if g == a then return true end end
    return false
end

local function webhook(title, desc, color)
    if not Config.Webhook or Config.Webhook == '' then return end
    PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode({ username = 'Outils de la base',
        embeds = { { title = title, description = desc, color = color or 16630397, timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ') } } }), { ['Content-Type'] = 'application/json' })
end

local function who(src) if src == 0 then return 'console' end return ('%s [%d]'):format(GetPlayerName(src) or '?', src) end

-- ═════════════════ AUDIT ═════════════════
local function check(id, title, status, detail, items) return { id = id, title = title, status = status, detail = detail, items = items or {} } end

local function auditAll()
    local out = {}

    -- 1) ressources
    local bad = {}
    for _, r in ipairs(Config.Required) do
        local st = GetResourceState(r)
        if st ~= 'started' then bad[#bad + 1] = ('%s — %s'):format(r, st == 'missing' and 'introuvable' or st) end
    end
    out[#out + 1] = check('resources', 'Ressources indispensables', #bad == 0 and 'ok' or 'err',
        #bad == 0 and ('%d ressources démarrées'):format(#Config.Required) or ('%d ressource(s) à corriger'):format(#bad), bad)
    local stopped = {}
    for i = 0, GetNumResources() - 1 do
        local n = GetResourceByFindIndex(i)
        if n and n:sub(1, 6) == 'pickax' and GetResourceState(n) ~= 'started' then stopped[#stopped + 1] = ('%s — %s'):format(n, GetResourceState(n)) end
    end
    out[#out + 1] = check('pickax', 'Ressources Pickax arrêtées', #stopped == 0 and 'ok' or 'warn',
        #stopped == 0 and 'toutes démarrées' or (#stopped .. ' arrêtée(s)'), stopped)

    -- 2) SQL
    local have = {}
    for _, r in ipairs(MySQL.query.await('SELECT table_name AS n FROM information_schema.tables WHERE table_schema = DATABASE()') or {}) do have[(r.n or r.TABLE_NAME or ''):lower()] = true end
    local missing = {}
    for _, t in ipairs(Config.Tables) do if not have[t:lower()] then missing[#missing + 1] = t end end
    out[#out + 1] = check('sql', 'Tables SQL', #missing == 0 and 'ok' or 'err',
        #missing == 0 and ('%d tables présentes'):format(#Config.Tables) or (#missing .. ' table(s) manquante(s) : importe database.sql ou démarre la ressource concernée'), missing)

    -- 3) objets ox_inventory
    local okI, items = pcall(function() return exports.ox_inventory:Items() end)
    local noItem = {}
    if okI and type(items) == 'table' then
        for _, n in ipairs(Config.Items) do if not items[n] then noItem[#noItem + 1] = n end end
        out[#out + 1] = check('items', 'Objets ox_inventory', #noItem == 0 and 'ok' or 'err',
            #noItem == 0 and ('%d objets trouvés'):format(#Config.Items) or (#noItem .. ' objet(s) à ajouter dans ox_inventory/data/items.lua'), noItem)
    else
        out[#out + 1] = check('items', 'Objets ox_inventory', 'warn', 'ox_inventory ne répond pas : impossible de vérifier')
    end

    -- 4) données des builders
    local function rows(q) local ok, r = pcall(function() return MySQL.query.await(q) end) return ok and r or nil end
    local pts = rows("SELECT id, job_name, type FROM jobbuilder_points WHERE coords IS NULL OR coords = '' OR coords = 'null'")
    if pts then
        local l = {} for _, r in ipairs(pts) do l[#l + 1] = ('#%d — %s (%s)'):format(r.id, r.job_name, r.type) end
        out[#out + 1] = check('points', 'Points sans position', #l == 0 and 'ok' or 'err', #l == 0 and 'tous les points ont une position' or (#l .. ' point(s) invisible(s)'), l)
    end
    local empty = rows('SELECT j.name FROM jobbuilder_jobs j WHERE NOT EXISTS (SELECT 1 FROM jobbuilder_points p WHERE p.job_name = j.name)')
    if empty then
        local l = {} for _, r in ipairs(empty) do l[#l + 1] = r.name end
        out[#out + 1] = check('emptyjobs', 'Métiers sans aucun point', #l == 0 and 'ok' or 'warn', #l == 0 and 'tous les métiers ont des points' or (#l .. ' métier(s) inutilisable(s)'), l)
    end
    local nocat = rows("SELECT j.name FROM jobbuilder_jobs j WHERE j.type = 'dealer' AND NOT EXISTS (SELECT 1 FROM jobbuilder_points p WHERE p.job_name = j.name AND p.type = 'showroom')")
    if nocat then
        local l = {} for _, r in ipairs(nocat) do l[#l + 1] = r.name end
        out[#out + 1] = check('nocatalog', 'Concessions sans point Catalogue', #l == 0 and 'ok' or 'warn', #l == 0 and 'toutes les concessions peuvent vendre' or (#l .. ' concession(s) sans point de vente/livraison'), l)
    end
    local noesx = rows('SELECT j.name FROM jobbuilder_jobs j LEFT JOIN jobs e ON e.name = j.name WHERE e.name IS NULL')
    if noesx then
        local l = {} for _, r in ipairs(noesx) do l[#l + 1] = r.name end
        out[#out + 1] = check('esxjobs', 'Métiers absents de la table ESX « jobs »', #l == 0 and 'ok' or 'warn', #l == 0 and 'cohérent' or (#l .. ' métier(s) non synchronisé(s) : redémarre pickax_jobbuilder'), l)
    end

    -- 5) configuration serveur
    local cfgBad = {}
    local lic = GetConvar('sv_licenseKey', '')
    if lic == '' or lic:find('METTRE') then cfgBad[#cfgBad + 1] = 'sv_licenseKey non renseignée' end
    local conn = GetConvar('mysql_connection_string', '')
    if conn == '' or conn:find('MOT_DE_PASSE') or conn:find('NOM_DE_LA_BASE') then cfgBad[#cfgBad + 1] = 'mysql_connection_string contient encore les valeurs d\'exemple' end
    if GetConvar('sv_enforceGameBuild', '') == '' then cfgBad[#cfgBad + 1] = 'sv_enforceGameBuild non défini (conseillé pour éviter les crashs de véhicules)' end
    out[#out + 1] = check('cfg', 'Configuration du serveur', #cfgBad == 0 and 'ok' or 'warn', #cfgBad == 0 and 'server.cfg cohérent' or (#cfgBad .. ' point(s) à vérifier'), cfgBad)

    local score = 100
    for _, c in ipairs(out) do score = score - (c.status == 'err' and 15 or c.status == 'warn' and 5 or 0) end
    return { ok = true, checks = out, score = math.max(0, score), at = os.time() }
end

lib.callback.register('basetools:audit', function(src)
    if not isAdmin(src) then return { ok = false, error = 'Accès refusé' } end
    local res = auditAll()
    webhook('Audit de la base', ('%s a lancé un audit : score **%d/100**'):format(who(src), res.score))
    return res
end)

-- ═════════════════ SAUVEGARDES ═════════════════
local INDEX = 'backups/index.json'
local function readIndex()
    local raw = LoadResourceFile(GetCurrentResourceName(), INDEX)
    local t = raw and raw ~= '' and json.decode(raw) or {}
    return type(t) == 'table' and t or {}
end
local function writeIndex(t) SaveResourceFile(GetCurrentResourceName(), INDEX, json.encode(t), -1) end

local function tableColumns(t)
    local cols = {}
    for _, c in ipairs(MySQL.query.await('SELECT column_name AS n, data_type AS d FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = ? ORDER BY ordinal_position', { t }) or {}) do
        local n, d = c.n or c.COLUMN_NAME, (c.d or c.DATA_TYPE or ''):lower()
        if n and n:match('^[%w_]+$') and d ~= 'timestamp' and d ~= 'datetime' and d ~= 'date' then cols[#cols + 1] = n end   -- les dates reprennent leur valeur par défaut à la restauration
    end
    return cols
end

local function makeBackup(label, by)
    local data, total = { version = 1, tables = {} }, 0
    for _, t in ipairs(Config.BackupTables) do
        local cols = tableColumns(t)
        if #cols > 0 then
            local sel = {}
            for i, c in ipairs(cols) do sel[i] = '`' .. c .. '`' end
            local rows = MySQL.query.await(('SELECT %s FROM `%s`'):format(table.concat(sel, ', '), t)) or {}
            data.tables[t] = { cols = cols, rows = rows }
            total = total + #rows
        end
    end
    local id = os.date('%Y%m%d-%H%M%S')
    if not SaveResourceFile(GetCurrentResourceName(), 'backups/' .. id .. '.json', json.encode(data), -1) then return nil, 'Écriture du fichier impossible (dossier backups/ ?)' end
    local idx = readIndex()
    table.insert(idx, 1, { id = id, label = label or '', at = os.time(), rows = total, tables = 0, by = by })
    local n = 0 for _ in pairs(data.tables) do n = n + 1 end
    idx[1].tables = n
    while #idx > Config.BackupKeep do table.remove(idx) end
    writeIndex(idx)
    return idx[1]
end

lib.callback.register('basetools:backups', function(src)
    if not isAdmin(src) then return { ok = false, error = 'Accès refusé' } end
    return { ok = true, list = readIndex() }
end)

lib.callback.register('basetools:backup', function(src, label)
    if not isAdmin(src) then return { ok = false, error = 'Accès refusé' } end
    local b, err = makeBackup(tostring(label or ''):sub(1, 60), who(src))
    if not b then return { ok = false, error = err } end
    webhook('Sauvegarde créée', ('%s — %d lignes, %d tables'):format(who(src), b.rows, b.tables), 5763719)
    return { ok = true, list = readIndex() }
end)

lib.callback.register('basetools:restore', function(src, id)
    if not isAdmin(src) then return { ok = false, error = 'Accès refusé' } end
    id = tostring(id or '')
    if not id:match('^%d+%-%d+$') then return { ok = false, error = 'Sauvegarde invalide' } end
    local raw = LoadResourceFile(GetCurrentResourceName(), 'backups/' .. id .. '.json')
    local data = raw and raw ~= '' and json.decode(raw)
    if type(data) ~= 'table' or type(data.tables) ~= 'table' then return { ok = false, error = 'Fichier de sauvegarde illisible' } end
    local safety = makeBackup('Avant restauration de ' .. id, who(src))   -- filet de sécurité : on peut annuler en restaurant celle-ci
    if not safety then return { ok = false, error = 'Impossible de créer la sauvegarde de sécurité : restauration annulée' } end

    local allowed = {}
    for _, t in ipairs(Config.BackupTables) do allowed[t] = true end
    local q, count = {}, 0
    for t, d in pairs(data.tables) do
        if allowed[t] and type(d) == 'table' and type(d.rows) == 'table' then
            local live = {}
            for _, c in ipairs(tableColumns(t)) do live[c] = true end
            local cols = {}
            for _, c in ipairs(d.cols or {}) do if live[c] then cols[#cols + 1] = c end end
            if #cols > 0 then
                q[#q + 1] = { query = ('DELETE FROM `%s`'):format(t), values = {} }
                for _, row in ipairs(d.rows) do
                    -- NULL écrit en clair dans la requête (une valeur nil casserait la liste des paramètres)
                    local names, marks, vals = {}, {}, {}
                    for _, c in ipairs(cols) do
                        names[#names + 1] = '`' .. c .. '`'
                        local v = row[c]
                        if v == nil then marks[#marks + 1] = 'NULL'
                        else
                            if type(v) == 'table' then v = json.encode(v) end
                            marks[#marks + 1] = '?' vals[#vals + 1] = v
                        end
                    end
                    q[#q + 1] = { query = ('INSERT INTO `%s` (%s) VALUES (%s)'):format(t, table.concat(names, ', '), table.concat(marks, ', ')), values = vals }
                    count = count + 1
                end
            end
        end
    end
    if #q == 0 then return { ok = false, error = 'Rien à restaurer' } end
    if not MySQL.transaction.await(q) then return { ok = false, error = 'Erreur SQL : la base est restée inchangée' } end
    webhook('Restauration effectuée', ('%s a restauré **%s** (%d lignes). Sauvegarde de sécurité : %s'):format(who(src), id, count, safety.id), 15548997)
    SetTimeout(1500, function()
        for _, r in ipairs(Config.RestartAfterRestore) do if GetResourceState(r) == 'started' then ExecuteCommand('restart ' .. r) end end
    end)
    return { ok = true, rows = count, safety = safety.id, list = readIndex() }
end)

lib.callback.register('basetools:info', function(src)
    if not isAdmin(src) then return { ok = false, error = 'Accès refusé' } end
    return { ok = true, changelog = Changelog, command = Config.Command, version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) }
end)

lib.callback.register('basetools:allowed', function(src) return isAdmin(src) end)

-- ═════════════════ THÈME DU SERVEUR (couleur, nom, logo) ═════════════════
-- Écrit dans pickax_core/config.lua (source de vérité) ET dans pickax_theme/theme_live.json (léger : renvoyé aux joueurs par « restart pickax_theme »).
local THEME_KEYS = { 'AccentColor', 'InventoryColor', 'ServerName', 'ServerShortName', 'ServerTagline', 'ServerDiscord', 'ServerLogo' }
local THEME_HIST = 'backups/theme-history.json'

local function readConfigValues()
    local raw = LoadResourceFile('pickax_core', 'config.lua') or ''
    raw = raw:gsub('%-%-[^\n]*', '')
    local out = {}
    for _, k in ipairs(THEME_KEYS) do
        out[k] = raw:match('[%s,{]' .. k .. "%s*=%s*'([^'\n]*)'") or raw:match('[%s,{]' .. k .. '%s*=%s*"([^"\n]*)"') or ''
    end
    return out
end

local function themeHistory()
    local raw = LoadResourceFile(GetCurrentResourceName(), THEME_HIST)
    local t = raw and raw ~= '' and json.decode(raw) or {}
    return type(t) == 'table' and t or {}
end

local function cleanTheme(v)
    if type(v) ~= 'table' then return nil, 'Données invalides' end
    local function txt(x, max) x = tostring(x or ''):gsub('^%s+', ''):gsub('%s+$', '') if #x > max or x:find('[\'"\\\r\n]') then return nil end return x end
    local o = {}
    o.AccentColor = tostring(v.AccentColor or ''):lower()
    if not o.AccentColor:match('^#%x%x%x%x%x%x$') then return nil, 'Couleur principale invalide (format #RRGGBB)' end
    o.InventoryColor = tostring(v.InventoryColor or ''):lower()
    if o.InventoryColor ~= '' and not o.InventoryColor:match('^#%x%x%x%x%x%x$') then return nil, 'Couleur de l\'inventaire invalide' end
    o.ServerName = txt(v.ServerName, 60) if not o.ServerName or o.ServerName == '' then return nil, 'Nom du serveur invalide (60 caractères max, sans guillemets)' end
    o.ServerShortName = txt(v.ServerShortName, 24) if not o.ServerShortName or o.ServerShortName == '' then return nil, 'Nom court invalide (24 caractères max)' end
    o.ServerTagline = txt(v.ServerTagline, 80) if not o.ServerTagline then return nil, 'Slogan invalide' end
    o.ServerDiscord = txt(v.ServerDiscord, 80) if not o.ServerDiscord then return nil, 'Lien Discord invalide' end
    o.ServerDiscord = o.ServerDiscord:gsub('^https?://', '')
    local logo = txt(v.ServerLogo, 200)
    local function logoOk(l)
        if not l or l == '' or l:find('..', 1, true) then return false end
        if l:match('^https://[%w%-%._~:/%?#@!$&()*+,;=%%]+$') then return true end
        if not l:match('^[%w_%-%.]+$') then return false end
        local ext = l:lower():match('%.(%a+)$')
        return ext == 'png' or ext == 'jpg' or ext == 'jpeg' or ext == 'webp' or ext == 'svg' or ext == 'gif'
    end
    if not logoOk(logo) then return nil, 'Logo invalide : nom de fichier (.png .jpg .webp .svg) placé dans pickax_theme/logo/, ou lien https' end
    o.ServerLogo = logo
    return o
end

local function writeConfigValues(o)
    local raw = LoadResourceFile('pickax_core', 'config.lua')
    if not raw or raw == '' then return false, 'pickax_core/config.lua introuvable' end
    SaveResourceFile(GetCurrentResourceName(), 'backups/core-config-' .. os.date('%Y%m%d-%H%M%S') .. '.lua.bak', raw, -1)
    for _, k in ipairs(THEME_KEYS) do
        local done = false
        raw = raw:gsub('(\n[ \t]*' .. k .. '%s*=%s*)([\'"])(.-)%2', function(pre, q, old)
            if done then return nil end
            done = true
            return pre .. "'" .. o[k] .. "'"
        end, 1)
        if not done then return false, 'Clé introuvable dans config.lua : ' .. k end
    end
    if not SaveResourceFile('pickax_core', 'config.lua', raw, -1) then return false, 'Écriture de pickax_core/config.lua impossible' end
    local live = { accent = o.AccentColor, server = { name = o.ServerName, short = o.ServerShortName, tagline = o.ServerTagline, discord = o.ServerDiscord, logo = o.ServerLogo, invColor = o.InventoryColor } }
    SaveResourceFile('pickax_theme', 'theme_live.json', json.encode(live), -1)
    return true
end

lib.callback.register('basetools:themeGet', function(src)
    if not isAdmin(src) then return { ok = false, error = 'Accès refusé' } end
    local h = themeHistory()
    return { ok = true, values = readConfigValues(), history = h }
end)

lib.callback.register('basetools:themeSave', function(src, v)
    if not isAdmin(src) then return { ok = false, error = 'Accès refusé' } end
    local o, err = cleanTheme(v)
    if not o then return { ok = false, error = err } end
    local before = readConfigValues()
    local ok, e = writeConfigValues(o)
    if not ok then return { ok = false, error = e } end
    local h = themeHistory()
    table.insert(h, 1, { at = os.time(), by = who(src), values = before })
    while #h > 10 do table.remove(h) end
    SaveResourceFile(GetCurrentResourceName(), THEME_HIST, json.encode(h), -1)
    webhook('Thème du serveur modifié', ('%s : couleur **%s**, nom **%s**'):format(who(src), o.AccentColor, o.ServerName), tonumber(o.AccentColor:sub(2), 16))
    SetTimeout(800, function()
        for _, r in ipairs(Config.ThemeRestart) do if GetResourceState(r) == 'started' then ExecuteCommand('restart ' .. r) end end
    end)
    return { ok = true, values = readConfigValues(), history = h }
end)
