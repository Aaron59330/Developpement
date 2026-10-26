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
    local liveRaw = LoadResourceFile(GetCurrentResourceName(), 'theme_live.json')
    if liveRaw and liveRaw ~= '' then
        local okj, j = pcall(json.decode, liveRaw)
        if okj and type(j) == 'table' and j.accent and type(j.server) == 'table' then
            local m, b = j.marker or {}, j.blip or {}
            local mc = m.color
            return { Design = j.design or 'arcade', AccentColor = j.accent, InventoryColor = j.server.invColor or '', ServerName = j.server.name or '', ServerShortName = j.server.short or '',
                ServerTagline = j.server.tagline or '', ServerDiscord = j.server.discord or '', ServerLogo = j.server.logo or '',
                MenuBanner = j.server.menuBanner or '', LoadingBanner = j.server.loadingBanner or '',
                MarkerType = m.type or 23, MarkerAlpha = m.alpha or 150, MarkerSize = (m.size and m.size.x) or 1.0,
                MarkerColor = (type(mc) == 'table' and mc.r) and ('#%02x%02x%02x'):format(mc.r, mc.g, mc.b) or '',
                BlipScale = b.scale or 0.5, BlipColor = b.color or -1 }
        end
    end
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
    o.Design = (v.Design == 'ancien' or v.Design == 'arcade') and v.Design or (readConfigValues().Design or 'arcade')
    local prev = readConfigValues()
    local function url(x)
        x = tostring(x or '')
        if x == '' then return '' end
        if #x > 300 or not x:match('^https://[%w%-%._~:/%?#@!$&()*+,;=%%]+$') then return nil end
        return x
    end
    if v.MenuBanner ~= nil then o.MenuBanner = url(v.MenuBanner) if o.MenuBanner == nil then return nil, 'Lien de la bannière du menu invalide (https://… sans espace ni guillemet)' end else o.MenuBanner = prev.MenuBanner or '' end
    if v.LoadingBanner ~= nil then o.LoadingBanner = url(v.LoadingBanner) if o.LoadingBanner == nil then return nil, 'Lien de l\'image de chargement invalide (https://…)' end else o.LoadingBanner = prev.LoadingBanner or '' end
    local function clampn(x, lo, hi, def) x = tonumber(x) if not x then return def end return math.max(lo, math.min(hi, x)) end
    o.MarkerType = math.floor(clampn(v.MarkerType, 0, 43, prev.MarkerType or 23))
    o.MarkerAlpha = math.floor(clampn(v.MarkerAlpha, 0, 255, prev.MarkerAlpha or 150))
    o.MarkerSize = clampn(v.MarkerSize, 0.1, 5, prev.MarkerSize or 1.0)
    local mcol = v.MarkerColor ~= nil and tostring(v.MarkerColor):lower() or (prev.MarkerColor or '')
    if mcol ~= '' and not mcol:match('^#%x%x%x%x%x%x$') then return nil, 'Couleur des markers invalide (#RRGGBB ou vide = couleur principale)' end
    o.MarkerColor = mcol
    o.BlipScale = clampn(v.BlipScale, 0.1, 3, prev.BlipScale or 0.5)
    o.BlipColor = math.floor(clampn(v.BlipColor, -1, 85, prev.BlipColor or -1))
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
    -- 1) thème « vivant » dans cette ressource : l'écriture dans sa propre ressource est toujours autorisée par FiveM
    local mcol
    if o.MarkerColor and o.MarkerColor:match('^#%x%x%x%x%x%x$') then mcol = { r = tonumber(o.MarkerColor:sub(2, 3), 16), g = tonumber(o.MarkerColor:sub(4, 5), 16), b = tonumber(o.MarkerColor:sub(6, 7), 16) } end
    local ms = o.MarkerSize or 1.0
    local live = { design = o.Design or 'arcade', accent = o.AccentColor,
        server = { name = o.ServerName, short = o.ServerShortName, tagline = o.ServerTagline, discord = o.ServerDiscord, logo = o.ServerLogo, invColor = o.InventoryColor, menuBanner = o.MenuBanner or '', loadingBanner = o.LoadingBanner or '' },
        marker = { type = o.MarkerType or 23, size = { x = ms, y = ms, z = ms * 0.5 }, color = mcol, alpha = o.MarkerAlpha or 150 },
        blip = { scale = o.BlipScale or 0.5, color = o.BlipColor or -1 } }
    if not SaveResourceFile(GetCurrentResourceName(), 'theme_live.json', json.encode(live), -1) then return false, 'Écriture de pickax_basetools/theme_live.json impossible' end
    pcall(SaveResourceFile, 'pickax_theme', 'theme_live.json', json.encode(live), -1)   -- ancien emplacement (facultatif)
    -- 2) pickax_core/config.lua : au mieux (FiveM bloque l'écriture dans une autre ressource sans add_filesystem_permission)
    local warning
    local raw = LoadResourceFile('pickax_core', 'config.lua')
    if not raw or raw == '' then
        warning = 'pickax_core/config.lua introuvable'
    else
        SaveResourceFile(GetCurrentResourceName(), 'backups/core-config-' .. os.date('%Y%m%d-%H%M%S') .. '.lua.bak', raw, -1)
        for _, k in ipairs(THEME_KEYS) do
            local done = false
            raw = raw:gsub('(\n[ \t]*' .. k .. '%s*=%s*)([\'"])(.-)%2', function(pre, q, old)
                if done then return nil end
                done = true
                return pre .. "'" .. o[k] .. "'"
            end, 1)
            if not done then warning = 'clé introuvable dans config.lua : ' .. k break end
        end
        for cfgKey, val in pairs({ ServerMenuBanner = o.MenuBanner or '', ServerLoadingBanner = o.LoadingBanner or '' }) do   -- clés facultatives : ignorées si absentes
            raw = raw:gsub('(\n[ \t]*' .. cfgKey .. '%s*=%s*)([\'"])(.-)%2', function(pre) return pre .. "'" .. val .. "'" end, 1)
        end
        if not warning and not SaveResourceFile('pickax_core', 'config.lua', raw, -1) then
            warning = 'config.lua non modifié (FiveM bloque l\'écriture dans pickax_core ; facultatif : add_filesystem_permission pickax_basetools write pickax_core)'
        end
    end
    return true, warning
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

-- Appelé par pickax_panel (panel web) : même validation et mêmes sauvegardes que le menu en jeu
exports('ApplyTheme', function(v, by, restartCore)
    local o, err = cleanTheme(v)
    if not o then return { ok = false, error = err } end
    local before = readConfigValues()
    local ok, e = writeConfigValues(o)
    if not ok then return { ok = false, error = e } end
    local warning = e
    local h = themeHistory()
    table.insert(h, 1, { at = os.time(), by = by or 'panel web', values = before })
    while #h > 10 do table.remove(h) end
    SaveResourceFile(GetCurrentResourceName(), THEME_HIST, json.encode(h), -1)
    webhook('Thème du serveur modifié', ('%s : couleur **%s**, nom **%s**'):format(by or 'panel web', o.AccentColor, o.ServerName), tonumber(o.AccentColor:sub(2), 16))
    SetTimeout(800, function()
        local list = {}
        for _, r in ipairs(Config.ThemeRestart) do if r ~= 'pickax_basetools' then list[#list + 1] = r end end
        if restartCore then list[#list + 1] = 'pickax_core' end    -- écran de chargement, chat, markers… lisent le thème dans pickax_core
        list[#list + 1] = 'pickax_basetools'                      -- en dernier : il redémarre lui-même
        for _, r in ipairs(list) do if GetResourceState(r) == 'started' then ExecuteCommand('restart ' .. r) end end
    end)
    return { ok = true, warning = warning }
end)

-- ═════════════════ ÉCRAN DE CHARGEMENT (réglé depuis le panel web) ═════════════════
-- Écrit pickax_core/loading/loading.json : l'écran de chargement le lit (messages, musique, liens, équipe, mises à jour, textes d'étapes).
-- Les clients récupèrent le nouveau fichier quand pickax_core redémarre (option « appliquer maintenant »), sinon au prochain redémarrage du serveur.
local function lstr(x, max) x = tostring(x == nil and '' or x):gsub('[%c]', ' ') return x:sub(1, max) end
local function lurl(x) x = tostring(x or '') if x == '' then return '' end if #x <= 300 and x:match('^https://[%w%-%._~:/%?#@!%$&%(%)%*%+,;=%%]+$') then return x end return nil end
local function cleanLoading(v)
    if type(v) ~= 'table' then return nil, 'données invalides' end
    local o = { tips = {}, links = {}, team = {}, updates = {}, stages = {}, music = {} }
    for _, t in ipairs(type(v.tips) == 'table' and v.tips or {}) do local x = lstr(t, 140) if x ~= '' and #o.tips < 12 then o.tips[#o.tips + 1] = x end end
    local L = type(v.links) == 'table' and v.links or {}
    for _, k in ipairs({ 'reglement', 'discord', 'boutique' }) do local u = lurl(L[k]) if u == nil then return nil, 'lien invalide : ' .. k .. ' (https:// requis)' end o.links[k] = u end
    for _, m in ipairs(type(v.team) == 'table' and v.team or {}) do if type(m) == 'table' and #o.team < 12 then local n = lstr(m.name, 40) if n ~= '' then o.team[#o.team + 1] = { name = n, role = lstr(m.role, 60) } end end end
    for _, u in ipairs(type(v.updates) == 'table' and v.updates or {}) do
        if type(u) == 'table' and #o.updates < 8 then
            local t = lstr(u.title, 60)
            if t ~= '' then
                local items = {}
                for _, it in ipairs(type(u.items) == 'table' and u.items or {}) do local x = lstr(it, 120) if x ~= '' and #items < 6 then items[#items + 1] = x end end
                o.updates[#o.updates + 1] = { date = lstr(u.date, 20), title = t, items = items }
            end
        end
    end
    for i = 1, 4 do o.stages[i] = lstr((type(v.stages) == 'table' and v.stages[i]) or '', 40) end
    local M = type(v.music) == 'table' and v.music or {}
    local mu = lurl(M.url)
    if mu == nil then return nil, 'adresse de la musique invalide (https:// requis)' end
    o.music = { enabled = M.enabled ~= false, url = mu, volume = math.max(0, math.min(100, math.floor(tonumber(M.volume) or 10))), autoplay = M.autoplay ~= false }
    o.showTeam, o.showUpdates = v.showTeam ~= false, v.showUpdates ~= false
    return o
end

exports('ApplyLoading', function(v, by, restartCore)
    local o, err = cleanLoading(v)
    if not o then return { ok = false, error = err } end
    local raw = json.encode(o)
    SaveResourceFile(GetCurrentResourceName(), 'loading_live.json', raw, -1)
    if not SaveResourceFile('pickax_core', 'loading/loading.json', raw, -1) then
        return { ok = false, error = 'Écriture dans pickax_core/loading impossible : ajoute dans server.cfg « add_filesystem_permission pickax_basetools write pickax_core » puis redémarre le serveur' }
    end
    webhook('Écran de chargement modifié', ('%s a modifié l\'écran de chargement'):format(by or 'panel web'), 0xfdc27d)
    if restartCore and GetResourceState('pickax_core') == 'started' then SetTimeout(800, function() ExecuteCommand('restart pickax_core') end) end
    return { ok = true, restarted = restartCore == true }
end)

-- ═════════════════ ÉCONOMIE DYNAMIQUE (pickax_economy) ═════════════════
local function eco(fn, ...)
    if GetResourceState('pickax_economy') ~= 'started' then return nil, 'pickax_economy n\'est pas démarré' end
    local ok, r = pcall(fn, ...)
    if not ok then return nil, tostring(r) end
    return r
end

lib.callback.register('basetools:ecoGet', function(src)
    if not isAdmin(src) then return { ok = false, error = 'Accès refusé' } end
    local snap, err = eco(function() return exports.pickax_economy:Snapshot() end)
    if not snap then return { ok = false, error = err } end
    return { ok = true, markets = snap, now = os.time() }
end)

lib.callback.register('basetools:ecoEvent', function(src, key, swing, hours)
    if not isAdmin(src) then return { ok = false, error = 'Accès refusé' } end
    swing, hours = tonumber(swing) or 0, tonumber(hours) or 3
    if swing == 0 or math.abs(swing) > 0.5 then return { ok = false, error = 'Variation invalide' } end
    local ok, err = eco(function() return exports.pickax_economy:Event(tostring(key or ''), swing, hours) end)
    if not ok then return { ok = false, error = err or 'Marché introuvable' } end
    webhook('Événement de marché', ('%s : %s sur **%s** (%+d %%, %d h)'):format(who(src), swing > 0 and 'pénurie' or 'surplus', tostring(key), math.floor(swing * 100), hours))
    return { ok = true }
end)

lib.callback.register('basetools:ecoReset', function(src, key)
    if not isAdmin(src) then return { ok = false, error = 'Accès refusé' } end
    local ok, err = eco(function() return exports.pickax_economy:Reset(key ~= '' and key or nil) end)
    if not ok then return { ok = false, error = err or 'Marché introuvable' } end
    webhook('Marché réinitialisé', ('%s a réinitialisé %s'):format(who(src), key and key ~= '' and ('**' .. key .. '**') or 'tous les marchés'))
    return { ok = true }
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
