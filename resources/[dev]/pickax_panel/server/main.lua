local ESX = exports['es_extended']:getSharedObject()
local URL  = (GetConvar('aero_panel_url', '') or ''):gsub('/+$', '')
local KEY  = GetConvar('aero_panel_key', '') or ''
local VERSION = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '1.0.0'

local license = { valid = nil, status = 'inconnu', plan = nil, expires_at = nil, last_ok = 0 }
local docs, docVersions = {}, {}
local logs, results, reports = {}, {}, {}
local lastResources = 0
local lastErr = nil
local bans, whitelist, motd = {}, {}, { enabled = false, text = '' }
local serverCfg, econCfg = {}, nil
local settingsDoc, schemaSent = nil, false

local function now() return os.time() end

local function PanelLog(level, source, message)
    if #logs >= 150 then table.remove(logs, 1) end
    logs[#logs + 1] = { level = level or 'info', source = source or '', message = tostring(message or ''):sub(1, 480), at = now() }
end
exports('PanelLog', PanelLog)
exports('IsLicensed', function() return license.valid == true or (license.valid == nil and not Config.Enforce) end)
exports('GetLicenseInfo', function() return license end)

if URL == '' or KEY == '' then
    print('^1[pickax_panel]^7 aero_panel_url / aero_panel_key manquants dans server.cfg : le panel web est désactivé.')
    return
end
if not URL:match('^https?://') then print('^1[pickax_panel]^7 aero_panel_url doit commencer par http:// ou https://') return end

-- ───────── données joueurs ─────────
local function identifierOf(src)
    local lic
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then lic = id end
    end
    return lic or GetPlayerIdentifier(src, 0) or ''
end

local function collectPlayers()
    local out = {}
    for _, src in ipairs(GetPlayers()) do
        src = tonumber(src)
        local x = ESX.GetPlayerFromId(src)
        local p = { id = src, name = GetPlayerName(src) or '?', identifier = identifierOf(src), ping = GetPlayerPing(src) }
        -- position pour la carte live (natives serveur : OneSync requis ; sans OneSync le joueur reste simplement non localisé)
        pcall(function()
            local ped = GetPlayerPed(src)
            if ped and ped ~= 0 then
                local c = GetEntityCoords(ped)
                p.x, p.y = math.floor(c.x * 10 + 0.5) / 10, math.floor(c.y * 10 + 0.5) / 10
                p.h = math.floor(GetEntityHeading(ped) + 0.5)
                p.veh = GetVehiclePedIsIn(ped, false) ~= 0
            end
        end)
        if x then
            local job = x.getJob and x.getJob() or x.job or {}
            p.job = job.name or ''; p.grade = job.grade or 0
            p.group = x.getGroup and x.getGroup() or ''
            p.money = x.getAccount and (x.getAccount('money') or {}).money or 0
            p.bank = x.getAccount and (x.getAccount('bank') or {}).money or 0
        end
        out[#out + 1] = p
    end
    return out
end

local function collectResources()
    local out = {}
    for i = 0, GetNumResources() - 1 do
        local n = GetResourceByFindIndex(i)
        if n then out[#out + 1] = { name = n, state = GetResourceState(n) } end
    end
    return out
end

-- ───────── exécution des actions (liste blanche, doublée côté panel) ─────────
local function banIdentifiers(src)
    local t = {}
    for _, id in ipairs(GetPlayerIdentifiers(src)) do t[#t + 1] = id end
    return t
end

local H = {}
H.announce = function(p) TriggerClientEvent('chat:addMessage', -1, { args = { Config.AnnounceTitle, p.message } }) TriggerClientEvent('pickax_notify:showNotification', -1, '~y~' .. Config.AnnounceTitle .. '~s~ : ' .. p.message) return 'envoyé' end
H.message = function(p) if not GetPlayerName(p.id) then return nil, 'joueur absent' end TriggerClientEvent('pickax_notify:showNotification', p.id, p.message) return 'envoyé' end
H.kick = function(p) if not GetPlayerName(p.id) then return nil, 'joueur absent' end local n = GetPlayerName(p.id) DropPlayer(p.id, p.reason or 'Expulsé') PanelLog('staff', 'kick', ('%s (ID %d) expulsé : %s'):format(n, p.id, p.reason or '')) return 'expulsé' end
H.revive = function(p) if not GetPlayerName(p.id) then return nil, 'joueur absent' end TriggerClientEvent('jobbuilder:client:revive', p.id) TriggerClientEvent('esx_ambulancejob:revive', p.id) return 'réanimé' end
H.setjob = function(p) local x = ESX.GetPlayerFromId(p.id) if not x then return nil, 'joueur absent' end if not ESX.DoesJobExist(p.job, p.grade) then return nil, 'job ou grade inexistant' end x.setJob(p.job, p.grade) PanelLog('staff', 'setjob', ('%s → %s (%d)'):format(GetPlayerName(p.id), p.job, p.grade)) return 'métier changé' end
H.setgroup = function(p) local x = ESX.GetPlayerFromId(p.id) if not x then return nil, 'joueur absent' end x.setGroup(p.group) PanelLog('staff', 'setgroup', ('%s → groupe %s'):format(GetPlayerName(p.id), p.group)) return 'groupe changé' end
H.givemoney = function(p)
    local x = ESX.GetPlayerFromId(p.id) if not x then return nil, 'joueur absent' end
    if p.amount >= 0 then x.addAccountMoney(p.account, p.amount, 'panel web') else x.removeAccountMoney(p.account, -p.amount, 'panel web') end
    PanelLog('staff', 'argent', ('%s : %+d $ (%s)'):format(GetPlayerName(p.id), p.amount, p.account)) return 'ok'
end
H.giveitem = function(p)
    if not GetPlayerName(p.id) then return nil, 'joueur absent' end
    if GetResourceState('ox_inventory') ~= 'started' then return nil, 'ox_inventory non démarré' end
    local ok = exports.ox_inventory:AddItem(p.id, p.item, p.count)
    if not ok then return nil, 'objet inconnu ou inventaire plein' end
    PanelLog('staff', 'objet', ('%s : +%d %s'):format(GetPlayerName(p.id), p.count, p.item)) return 'ok'
end
H.restart_resource = function(p)
    for _, r in ipairs(Config.Protected) do if r == p.resource then return nil, 'ressource protégée' end end
    if #Config.RestartAllow > 0 then local ok = false for _, r in ipairs(Config.RestartAllow) do if r == p.resource then ok = true end end if not ok then return nil, 'ressource non autorisée (Config.RestartAllow)' end end
    local st = GetResourceState(p.resource)
    if st == 'missing' or st == 'uninitialized' then return nil, 'ressource introuvable' end
    ExecuteCommand(('ensure %s'):format(p.resource)) SetTimeout(500, function() ExecuteCommand(('restart %s'):format(p.resource)) end)
    PanelLog('staff', 'restart', 'redémarrage de ' .. p.resource) return 'redémarrage lancé'
end
H.economy_event = function(p) if GetResourceState('pickax_economy') ~= 'started' then return nil, 'pickax_economy non démarré' end exports.pickax_economy:Event(p.key == 'all' and '' or p.key, p.swing, p.hours) return 'ok' end
H.economy_reset = function(p) if GetResourceState('pickax_economy') ~= 'started' then return nil, 'pickax_economy non démarré' end exports.pickax_economy:Reset(p.key ~= '' and p.key or nil) return 'ok' end
H.refresh_docs = function() return 'ok' end

-- Téléporte un joueur à des coordonnées de la carte (le client cherche le sol, voir client/main.lua)
H.teleport = function(p)
    if not GetPlayerName(p.id) then return nil, 'joueur absent' end
    TriggerClientEvent('pickax_panel:tp', p.id, p.x + 0.0, p.y + 0.0)
    PanelLog('staff', 'teleport', ('%s téléporté en %.0f, %.0f'):format(GetPlayerName(p.id), p.x, p.y)) return 'téléporté'
end
local function refreshJobs() local ok = pcall(function() ESX.RefreshJobs() end) return ok end
H.jobs_refresh = function() if not refreshJobs() then return nil, 'ESX.RefreshJobs indisponible' end return 'métiers rechargés' end

-- ───────── plaintes en jeu → panel (Plaintes) ─────────
-- /plainte <id du joueur visé, 0 si aucun> <message> : le panel reçoit qui, quand, où, avec l'identifiant du joueur visé. Délai et file d'attente limités.
local lastReport = {}
local function identOf(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do if id:sub(1, 8) == 'license:' then return id end end
    return ''
end
local function submitReport(src, targetId, message)
    if #reports >= 30 then return false, 'Trop de plaintes en attente de transmission : réessaie dans un instant.' end
    message = tostring(message or ''):gsub('[%c]', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    if #message < 5 then return false, 'Décris le problème (5 caractères minimum).' end
    local t = now()
    if (lastReport[src] or 0) + (Config.ReportCooldown or 60) > t then return false, 'Patiente avant une nouvelle plainte.' end
    lastReport[src] = t
    local target = tonumber(targetId)
    if target and (target <= 0 or not GetPlayerName(target)) then target = nil end
    local c = GetEntityCoords(GetPlayerPed(src))
    reports[#reports + 1] = { at = t, reporter = GetPlayerName(src) or '?', reporter_id = src, reporter_ident = identOf(src),
        target = target and GetPlayerName(target) or nil, target_id = target, target_ident = target and identOf(target) or nil, message = message:sub(1, 400), x = c.x, y = c.y, z = c.z }
    PanelLog('info', 'plainte', ('%s a déposé une plainte%s'):format(GetPlayerName(src) or '?', target and (' contre ' .. (GetPlayerName(target) or '?')) or ''))
    return true
end
exports('PanelReport', submitReport)   -- utilisable par un téléphone ou un menu : exports.pickax_panel:PanelReport(src, idVisé, message)
RegisterCommand(Config.ReportCommand or 'plainte', function(src, args)
    if src == 0 then return end
    local ok, err = submitReport(src, args[1], table.concat(args, ' ', 2))
    TriggerClientEvent('chat:addMessage', src, { color = ok and { 74, 222, 128 } or { 239, 68, 68 }, args = { 'Plainte', ok and 'Ta plainte a été transmise au staff. Merci.' or err } })
end, false)
AddEventHandler('playerDropped', function() lastReport[source] = nil end)

-- ───────── sauvegarde de la base (tables des builders) ─────────
-- Lecture seule : db.tables liste les tables autorisées (préfixes de Config.DbBackupPrefixes + jobs / job_grades), db.export renvoie leurs lignes (plafonnées).
local function allowedTable(name)
    if type(name) ~= 'string' or not name:match('^[%w_]+$') or #name > 64 then return false end
    if name == 'jobs' or name == 'job_grades' then return true end
    for _, p in ipairs(Config.DbBackupPrefixes or {}) do if name:sub(1, #p) == p then return true end end
    return false
end
local function sqlReady2() return GetResourceState('oxmysql') == 'started' and MySQL ~= nil end
H['db.tables'] = function()
    if not sqlReady2() then return nil, 'oxmysql indisponible' end
    local out = {}
    for _, r in ipairs(MySQL.query.await('SELECT table_name AS name, table_rows AS n FROM information_schema.tables WHERE table_schema = DATABASE() ORDER BY table_name') or {}) do
        if allowedTable(r.name) then out[#out + 1] = { name = r.name, rows = tonumber(r.n) or 0 } end
    end
    return 'ok', { tables = out }
end
H['db.export'] = function(p)
    if not sqlReady2() then return nil, 'oxmysql indisponible' end
    local out, budget = {}, 900000
    for _, name in ipairs(type(p.tables) == 'table' and p.tables or {}) do
        if not allowedTable(name) then return nil, 'table non autorisée : ' .. tostring(name) end
        local rows = MySQL.query.await(('SELECT * FROM `%s` LIMIT %d'):format(name, Config.DbBackupMaxRows or 5000)) or {}
        local enc = json.encode(rows)
        if #enc > budget then out[name] = { truncated = true, rows = {} } else out[name] = { rows = rows } budget = budget - #enc end
    end
    return 'ok', { tables = out }
end

-- ───────── boutiques créées en jeu (pickax_shopbuilder) : les callbacks du builder, appelés depuis le panel ─────────
H['db.shop'] = function(p)
    if GetResourceState('pickax_shopbuilder') ~= 'started' then return nil, 'pickax_shopbuilder n\'est pas démarré' end
    local args = type(p.args) == 'table' and p.args or {}
    local ok, r = pcall(function() return exports.pickax_shopbuilder:PanelCall(p.fn, table.unpack(args, 1, 4)) end)
    if not ok then return nil, tostring(r):sub(1, 200) end
    if type(r) ~= 'table' then return nil, 'réponse invalide' end
    if r.ok == false then return nil, r.error or 'refusé' end
    if r.ok == nil then r = { ok = true, shops = r } end   -- « list » renvoie un tableau
    if p.fn ~= 'list' and p.fn ~= 'get' and p.fn ~= 'catalog' then PanelLog('staff', 'boutique', 'boutique en jeu : ' .. tostring(p.fn) .. ' depuis le panel') end
    return 'ok', r
end

-- ───────── éditeur de base : métiers et grades (tables ESX jobs / job_grades) ─────────
local function sqlReady() return GetResourceState('oxmysql') == 'started' and MySQL ~= nil end
H['db.jobs'] = function()
    if not sqlReady() then return nil, 'oxmysql indisponible' end
    local jobs = MySQL.query.await('SELECT name, label, whitelisted FROM jobs ORDER BY label') or {}
    local grades = MySQL.query.await('SELECT job_name, grade, name, label, salary FROM job_grades ORDER BY job_name, grade') or {}
    local by = {}
    for _, j in ipairs(jobs) do j.whitelisted = (j.whitelisted == 1 or j.whitelisted == true) j.grades = {} by[j.name] = j end
    for _, g in ipairs(grades) do local j = by[g.job_name] if j then j.grades[#j.grades + 1] = { grade = g.grade, name = g.name, label = g.label, salary = g.salary } end end
    return 'ok', { jobs = jobs }
end
H['db.job_save'] = function(p)
    if not sqlReady() then return nil, 'oxmysql indisponible' end
    local j = p.job
    if type(j) ~= 'table' or type(j.name) ~= 'string' or not j.name:match('^[a-z0-9_]+$') or #j.name > 40 then return nil, 'nom de métier invalide' end
    if type(j.grades) ~= 'table' or #j.grades < 1 or #j.grades > 40 then return nil, 'au moins un grade est requis' end
    local seen = {}
    for _, g in ipairs(j.grades) do
        if type(g.grade) ~= 'number' or g.grade < 0 or g.grade > 99 or g.grade % 1 ~= 0 or seen[g.grade] then return nil, 'numéros de grade invalides' end
        if type(g.name) ~= 'string' or not g.name:match('^[%w_]+$') or #g.name > 40 then return nil, 'nom de grade invalide' end
        if type(g.label) ~= 'string' or #g.label < 1 or #g.label > 50 then return nil, 'libellé de grade invalide' end
        if type(g.salary) ~= 'number' or g.salary < 0 or g.salary > 1000000 then return nil, 'salaire invalide' end
        seen[g.grade] = true
    end
    local exists = MySQL.scalar.await('SELECT 1 FROM jobs WHERE name = ?', { j.name })
    if exists then MySQL.update.await('UPDATE jobs SET label = ?, whitelisted = ? WHERE name = ?', { j.label, j.whitelisted and 1 or 0, j.name })
    else MySQL.insert.await('INSERT INTO jobs (name, label, whitelisted) VALUES (?, ?, ?)', { j.name, j.label, j.whitelisted and 1 or 0 }) end
    local have = {}
    for _, r in ipairs(MySQL.query.await('SELECT grade FROM job_grades WHERE job_name = ?', { j.name }) or {}) do have[r.grade] = true end
    for _, g in ipairs(j.grades) do
        if have[g.grade] then MySQL.update.await('UPDATE job_grades SET name = ?, label = ?, salary = ? WHERE job_name = ? AND grade = ?', { g.name, g.label, g.salary, j.name, g.grade })
        else MySQL.insert.await("INSERT INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female) VALUES (?, ?, ?, ?, ?, '{}', '{}')", { j.name, g.grade, g.name, g.label, g.salary }) end
    end
    for gr in pairs(have) do if not seen[gr] then MySQL.update.await('DELETE FROM job_grades WHERE job_name = ? AND grade = ?', { j.name, gr }) end end
    refreshJobs()
    PanelLog('staff', 'jobs', ('métier %s enregistré (%d grades)'):format(j.name, #j.grades))
    return exists and 'métier mis à jour' or 'métier créé', { message = exists and 'métier mis à jour' or 'métier créé' }
end


-- ───────── fichiers (fs/main.js), console, alimentation ─────────
local EXT_OK = { lua = true, json = true, cfg = true, meta = true, js = true, html = true, css = true, txt = true, md = true, sql = true, xml = true, yml = true, yaml = true, ini = true }
local function extOf(p) return (p:match('%.([%w]+)$') or ''):lower() end

-- Mode 1 : module Node (fs/main.js) : explore tout le dossier resources/
local function callNode(name, ...)
    local ok, r = pcall(function(...) return exports[GetCurrentResourceName()][name](exports[GetCurrentResourceName()], ...) end, ...)
    if not ok then return nil, 'module fichiers indisponible : ' .. tostring(r):sub(1, 160) end
    if type(r) ~= 'table' then return nil, 'réponse invalide' end
    if r.error then return nil, r.error end
    return r
end

-- Mode 2 : natives FiveM (si le Node intégré n'a pas le droit de lire le disque, ex. « Access to this API has been restricted »).
-- Liste = fichiers déclarés dans le fxmanifest de chaque ressource ; lecture/écriture via LoadResourceFile / SaveResourceFile.
local function manifestFiles(res)
    local set = {}
    for _, key in ipairs({ 'client_script', 'server_script', 'shared_script', 'file', 'ui_page', 'loadscreen' }) do
        for i = 0, (GetNumResourceMetadata(res, key) or 0) - 1 do
            local f = GetResourceMetadata(res, key, i)
            if type(f) == 'string' and f ~= '' and not f:find('*', 1, true) and f:sub(1, 1) ~= '@' and not f:find('..', 1, true) and EXT_OK[extOf(f)] then set[f] = true end
        end
    end
    for _, m in ipairs({ 'fxmanifest.lua', '__resource.lua' }) do if LoadResourceFile(res, m) then set[m] = true end end
    return set
end
local function splitPath(path)
    local res, rel = path:match('^([^/]+)/?(.*)$')
    return res, rel
end
local function luaList(path)
    if path == '' then
        local out = {}
        for i = 0, GetNumResources() - 1 do
            local n = GetResourceByFindIndex(i)
            if n and n ~= GetCurrentResourceName() then out[#out + 1] = { name = n, type = 'dir' } end
        end
        table.sort(out, function(a, b) return a.name < b.name end)
        return { entries = out }
    end
    local res, sub = splitPath(path)
    if res == GetCurrentResourceName() then return nil, 'la ressource pickax_panel est protégée' end
    if GetResourceState(res) == 'missing' then return nil, 'ressource introuvable' end
    local prefix = sub ~= '' and (sub .. '/') or ''
    local dirs, files = {}, {}
    for f in pairs(manifestFiles(res)) do
        if f:sub(1, #prefix) == prefix then
            local rest = f:sub(#prefix + 1)
            local seg, tail = rest:match('^([^/]+)(.*)$')
            if seg then if tail ~= '' then dirs[seg] = true else files[seg] = true end end
        end
    end
    local out = {}
    for d in pairs(dirs) do out[#out + 1] = { name = d, type = 'dir' } end
    table.sort(out, function(a, b) return a.name < b.name end)
    local fl = {}
    for f in pairs(files) do fl[#fl + 1] = { name = f, type = 'file' } end
    table.sort(fl, function(a, b) return a.name < b.name end)
    for _, f in ipairs(fl) do out[#out + 1] = f end
    return { entries = out }
end
local function luaRead(path)
    local res, rel = splitPath(path)
    if not res or rel == '' or rel:find('..', 1, true) then return nil, 'chemin invalide' end
    if res == GetCurrentResourceName() then return nil, 'la ressource pickax_panel est protégée' end
    if not EXT_OK[extOf(rel)] then return nil, 'type de fichier non modifiable' end
    local c = LoadResourceFile(res, rel)
    if not c then return nil, 'fichier introuvable ou illisible' end
    if #c > 1048576 then return nil, 'fichier trop gros (1 Mo max)' end
    return { content = c }
end
local function luaWrite(path, content)
    local res, rel = splitPath(path)
    if not res or rel == '' or rel:find('..', 1, true) then return nil, 'chemin invalide' end
    if res == GetCurrentResourceName() then return nil, 'la ressource pickax_panel est protégée' end
    if not EXT_OK[extOf(rel)] then return nil, 'type de fichier non modifiable' end
    if GetResourceState(res) == 'missing' then return nil, 'ressource introuvable' end
    if not SaveResourceFile(res, rel, content, -1) then
        return nil, ('FiveM refuse d\'écrire dans « %s » : ajoute dans server.cfg la ligne  add_filesystem_permission pickax_panel write %s  puis redémarre le serveur'):format(res, res)
    end
    return { ok = true, message = 'fichier enregistré' }
end

local nodeOk, nodeAt = nil, 0
local function useNode()
    if nodeOk ~= nil and now() - nodeAt < 120 then return nodeOk end
    local r = callNode('FsList', '')
    nodeOk, nodeAt = r ~= nil, now()
    if not nodeOk then PanelLog('warn', 'pickax_panel', 'Module Node indisponible : éditeur de fichiers en mode natives FiveM (fichiers déclarés dans les fxmanifest)') end
    return nodeOk
end
local function noFiles() return nil, 'éditeur de fichiers désactivé sur ce serveur (Config.AllowFiles)' end
H['fs.list'] = function(p) if not Config.AllowFiles then return noFiles() end local r, e if useNode() then r, e = callNode('FsList', p.path) else r, e = luaList(p.path) end if not r then return nil, e end return 'ok', r end
H['fs.read'] = function(p) if not Config.AllowFiles then return noFiles() end local r, e if useNode() then r, e = callNode('FsRead', p.path) else r, e = luaRead(p.path) end if not r then return nil, e end return 'ok', r end
local function fsWrite(path, content, create)
    if not Config.AllowFiles then return noFiles() end
    if useNode() then return callNode('FsWrite', path, content, create) end
    if create then return nil, 'création de fichier indisponible en mode natives FiveM (module Node bloqué)' end
    return luaWrite(path, content)
end
local function checkLua(path, content)
    if not Config.CheckLuaSyntax or not path:lower():match('%.lua$') then return true end
    local f, err = load(content, '=' .. path)
    if not f then return false, 'erreur de syntaxe Lua : ' .. tostring(err):sub(1, 160) end
    return true
end
H['fs.write'] = function(p)
    local ok, e = checkLua(p.path, p.content) if not ok then return nil, e end
    local r, err = fsWrite(p.path, p.content, false) if not r then return nil, err end
    PanelLog('staff', 'fichier', 'modifié depuis le panel : ' .. p.path) return 'ok', { message = r.message }
end
H['fs.create'] = function(p)
    local ok, e = checkLua(p.path, p.content) if not ok then return nil, e end
    local r, err = fsWrite(p.path, p.content, true) if not r then return nil, err end
    PanelLog('staff', 'fichier', 'créé depuis le panel : ' .. p.path) return 'ok', { message = r.message }
end
H.console = function(p)
    if not Config.AllowConsole then return nil, 'console désactivée (Config.AllowConsole)' end
    local first = (p.cmd:match('^%s*(%S+)') or ''):lower()
    local allowed = false
    for _, c in ipairs(Config.ConsoleAllowed) do if c == first then allowed = true end end
    if not allowed then return nil, 'commande non autorisée : ' .. first end
    if (first == 'restart' or first == 'stop' or first == 'start' or first == 'ensure') then
        local res = p.cmd:match('^%s*%S+%s+(%S+)') or ''
        for _, r in ipairs(Config.Protected) do if r == res then return nil, 'ressource protégée' end end
    end
    ExecuteCommand(p.cmd) PanelLog('staff', 'console', 'commande lancée depuis le panel : ' .. p.cmd) return 'exécutée'
end
H.resource_start = function(p)
    if GetResourceState(p.resource) == 'missing' then return nil, 'ressource introuvable' end
    ExecuteCommand('ensure ' .. p.resource) PanelLog('staff', 'module', 'démarrage de ' .. p.resource) return 'démarrée'
end
H.resource_stop = function(p)
    for _, r in ipairs(Config.Protected) do if r == p.resource then return nil, 'ressource protégée' end end
    if GetResourceState(p.resource) == 'missing' then return nil, 'ressource introuvable' end
    ExecuteCommand('stop ' .. p.resource) PanelLog('staff', 'module', 'arrêt de ' .. p.resource) return 'arrêtée'
end
H.server_restart = function()
    local d = Config.RestartDelay or 30
    TriggerClientEvent('pickax_notify:showNotification', -1, ('~r~Redémarrage du serveur dans %d secondes~s~'):format(d))
    PanelLog('staff', 'serveur', 'redémarrage demandé depuis le panel')
    SetTimeout(d * 1000, function() ExecuteCommand('quit') end)
    return ('arrêt dans %d s (le gestionnaire txAdmin/service doit relancer le serveur)'):format(d)
end
H.server_stop = function()
    TriggerClientEvent('pickax_notify:showNotification', -1, '~r~Le serveur va s’arrêter dans 15 secondes~s~')
    PanelLog('staff', 'serveur', 'arrêt demandé depuis le panel')
    SetTimeout(15000, function() ExecuteCommand('quit') end)
    return 'arrêt dans 15 s'
end

local function saveDoc(key, value) SaveResourceFile(GetCurrentResourceName(), 'cache_' .. key .. '.json', json.encode(value), -1) end

H.apply_theme = function(p)
    local t = docs.theme
    if not t then return nil, 'aucun thème enregistré dans le panel' end
    if GetResourceState('pickax_basetools') ~= 'started' then return nil, 'pickax_basetools non démarré' end
    local r = exports.pickax_basetools:ApplyTheme(t, 'panel web', p and p.core == true)
    if not r or not r.ok then return nil, (r and r.error) or 'échec' end
    return 'thème appliqué' .. (r.warning and (' (' .. r.warning .. ')') or '')
end

H.apply_loading = function(p)
    local t = docs.loading
    if not t then return nil, 'aucune configuration de l\'écran de chargement enregistrée dans le panel' end
    if GetResourceState('pickax_basetools') ~= 'started' then return nil, 'pickax_basetools non démarré' end
    local r = exports.pickax_basetools:ApplyLoading(t, 'panel web', p and p.core == true)
    if not r or not r.ok then return nil, (r and r.error) or 'échec' end
    return r.restarted and 'écran de chargement appliqué (pickax_core redémarré)' or 'écran de chargement enregistré (visible après le prochain redémarrage de pickax_core)'
end

-- bans / whitelist / message de bienvenue (documents synchronisés)
-- Nombre de places : écrit dans server.cfg (une seule ligne, copie .aero-backup avant). Fait en Lua (io) : le Node de FiveM refuse les fichiers hors resources/.
local function setMaxClients(n)
    local root = GetResourcePath(GetCurrentResourceName()):gsub('\\', '/')
    root = root:match('^(.*/resources)/') or root:match('^(.*/resources)$')
    if not root then return nil, 'dossier resources introuvable' end
    -- où est le server.cfg ? 1) convar aero_server_cfg  2) Config.ServerCfgPath  3) à côté de resources/  4) recherche dans le dossier parent (txAdmin : txData/<profil>/server.cfg)
    local base = root:gsub('/resources$', '')
    local cands, tried = {}, {}
    local function add(x) if type(x) == 'string' and x ~= '' then cands[#cands + 1] = x end end
    add(GetConvar('aero_server_cfg', '')) add(Config.ServerCfgPath) add(base .. '/server.cfg')
    local file, f
    local lastErr
    for _, c in ipairs(cands) do local ff, er = io.open(c, 'rb') if ff then f, file = ff, c break end tried[#tried + 1] = c .. ' (' .. tostring(er) .. ')' end
    local diag = ''
    if not f and io.popen then   -- certains hébergeurs désactivent io.popen
        local function sh(cmd) local ok, h = pcall(io.popen, cmd .. ' 2>&1') if not ok or not h then return '' end local o = h:read('*a') or '' h:close() return o end
        local found = {}
        for line in sh('find / -maxdepth 6 -name server.cfg -not -path "/proc/*" -not -path "*/resources/*" 2>/dev/null | head -8'):gmatch('[^\r\n]+') do
            if line:sub(1, 1) == '/' and not line:find('find:', 1, true) then found[#found + 1] = line end
        end
        if #found == 1 then file = found[1] f = io.open(file, 'rb')
        else diag = ' | pwd=' .. sh('pwd'):gsub('%s+$', '') .. ' | ls ' .. base .. ' = ' .. sh('ls ' .. base .. ' | head -25'):gsub('%s+', ' ') .. ' | server.cfg trouvés = ' .. (#found > 0 and table.concat(found, ', ') or 'aucun') end
    end
    if not f then return nil, 'server.cfg illisible (' .. table.concat(tried, ', ') .. ')' .. diag .. ' : indique-le avec  set aero_server_cfg "/chemin/réel/server.cfg"' end
    local raw = f:read('*a') f:close()
    local eol = raw:find('\r\n', 1, true) and '\r\n' or '\n'
    local lines, idx, previous = {}, nil, nil
    for l in (raw .. '\n'):gmatch('(.-)\r?\n') do lines[#lines + 1] = l end
    if lines[#lines] == '' then lines[#lines] = nil end
    for i, l in ipairs(lines) do
        if not l:match('^%s*#') then
            local a, num, b = l:match('^(%s*s?e?t?%s*sv_maxclients%s+)["\']?(%d+)["\']?(.-)$')
            if a and (a:match('^%s*sv_maxclients') or a:match('^%s*set%s+sv_maxclients')) then
                idx, previous = i, tonumber(num)
                if previous == n then return { ok = true, changed = false, previous = previous } end
                lines[i] = a .. n .. b
                break
            end
        end
    end
    if not idx then lines[#lines + 1] = 'sv_maxclients ' .. n end
    local bk = io.open(file .. '.aero-backup', 'wb') if bk then bk:write(raw) bk:close() end
    local w, err = io.open(file, 'wb')
    if not w then return nil, 'écriture impossible : ' .. tostring(err) end
    w:write(table.concat(lines, eol) .. eol) w:close()
    return { ok = true, changed = true, previous = previous }
end

local lastMaxClients = nil
local function applyServerSettings()
    local c = serverCfg or {}
    local function ok(x) return type(x) == 'string' and x ~= '' and not x:find('"', 1, true) and not x:find('[\r\n;]') end
    if ok(c.projectName) then ExecuteCommand('sets sv_projectName "' .. c.projectName .. '"') end
    if ok(c.projectDesc) then ExecuteCommand('sets sv_projectDesc "' .. c.projectDesc .. '"') end
    if ok(c.hostname) then ExecuteCommand('sv_hostname "' .. c.hostname .. '"') end
    if ok(c.tags) then ExecuteCommand('sets tags "' .. c.tags .. '"') end
    if ok(c.discord) then ExecuteCommand('sets discord "' .. c.discord .. '"') end
    local function url(x) return type(x) == 'string' and x:match('^https://[%w%-%._~:/%?#@!%$&%(%)%*%+,;=%%]+$') and #x <= 300 and x or nil end
    if url(c.bannerDetail) then ExecuteCommand('sets banner_detail "' .. c.bannerDetail .. '"') end
    if url(c.bannerConnecting) then ExecuteCommand('sets banner_connecting "' .. c.bannerConnecting .. '"') end
    -- nombre de places : écrit dans server.cfg (FiveM ne le lit qu'au démarrage)
    local want = math.floor(tonumber(c.maxClients) or 0)
    if want >= 1 and want ~= lastMaxClients then
        lastMaxClients = want
        if not Config.AllowMaxClients then PanelLog('warn', 'maxclients', 'Config.AllowMaxClients = false : sv_maxclients non modifié') return end
        local r, e = setMaxClients(want)
        print(r and ('^2[pickax_panel]^7 places : sv_maxclients ' .. tostring(r.previous or '?') .. ' -> ' .. want .. (r.changed and ' écrit dans server.cfg' or ' (déjà à jour)')) or ('^1[pickax_panel]^7 places : server.cfg non modifié : ' .. tostring(e)))
        if not r then lastMaxClients = nil PanelLog('error', 'maxclients', 'sv_maxclients non modifié : ' .. tostring(e))
        elseif r.changed then PanelLog('staff', 'maxclients', ('sv_maxclients %s → %d dans server.cfg : pris en compte au prochain redémarrage du serveur'):format(tostring(r.previous or '?'), want))
        else PanelLog('info', 'maxclients', 'sv_maxclients est déjà à ' .. want .. ' dans server.cfg') end
    end
end

local function applyEconomy()
    if type(econCfg) ~= 'table' or type(econCfg.preset) ~= 'string' then return end
    if GetResourceState('pickax_economy') ~= 'started' then return end
    local ok, r = pcall(function() return exports.pickax_economy:SetPreset(econCfg.preset) end)
    if ok and r then PanelLog('staff', 'economie', 'type d\'économie du serveur : ' .. econCfg.preset) end
end

local function applySettingsDoc()
    if type(settingsDoc) ~= 'table' or GetResourceState('pickax_settings') ~= 'started' then return end
    pcall(function() exports.pickax_settings:ApplyRemote(settingsDoc) end)
end

local function onDoc(key, value)
    docs[key] = value; saveDoc(key, value)
    if key == 'bans' then bans = value or {} elseif key == 'whitelist' then whitelist = value or {} elseif key == 'motd' then motd = value or { enabled = false, text = '' }
    elseif key == 'settings' then settingsDoc = value applySettingsDoc()
    elseif key == 'boutique' then TriggerEvent('pickax_boutique:docUpdated', value) PanelLog('staff', 'boutique', 'boutique à coins modifiée depuis le panel')
    elseif key == 'economy' then econCfg = value applyEconomy()
    elseif key == 'server' then serverCfg = value or {} applyServerSettings() PanelLog('staff', 'serveur', 'nom / description du serveur modifiés depuis le panel') end
end
for _, k in ipairs({ 'bans', 'whitelist', 'motd', 'server', 'economy', 'settings' }) do
    local raw = LoadResourceFile(GetCurrentResourceName(), 'cache_' .. k .. '.json')
    if raw and raw ~= '' then local ok, v = pcall(json.decode, raw) if ok then if k == 'server' then serverCfg = v docs.server = v elseif k == 'economy' then econCfg = v docs.economy = v elseif k == 'settings' then settingsDoc = v docs.settings = v else onDoc(k, v) end end end
end
-- au démarrage : réappliquer le nom / la description enregistrés dans le panel (même si le panel est injoignable)
CreateThread(function() Wait(10000) applyServerSettings() Wait(10000) applyEconomy() applySettingsDoc() Wait(15000) applySettingsDoc() end)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer(); Wait(0)
    local ids = {}
    for _, id in ipairs(GetPlayerIdentifiers(src)) do ids[id] = true end
    for _, b in ipairs(bans) do
        if ids[b.identifier] and (not b['until'] or b['until'] == 0 or b['until'] > now()) then
            PanelLog('info', 'ban', ('Connexion refusée (banni) : %s'):format(name))
            deferrals.done(('Tu es banni%s. Raison : %s'):format((b['until'] and b['until'] > 0) and (' jusqu’au ' .. os.date('%d/%m/%Y', b['until'])) or '', b.reason or '—'))
            return
        end
    end
    if #whitelist > 0 then
        local ok = false
        for _, w in ipairs(whitelist) do if ids[w] then ok = true break end end
        if not ok then PanelLog('info', 'whitelist', ('Connexion refusée (hors whitelist) : %s'):format(name)) deferrals.done('Tu n’es pas sur la whitelist du serveur.') return end
    end
    -- nombre de places du panel : sv_maxclients n'est lu qu'au démarrage, donc une valeur plus petite est appliquée tout de suite ici
    local cap = math.floor(tonumber((serverCfg or {}).maxClients) or 0)
    if cap >= 1 and cap < GetConvarInt('sv_maxclients', 48) and #GetPlayers() >= cap then
        PanelLog('info', 'places', ('Connexion refusée (serveur plein %d/%d) : %s'):format(#GetPlayers(), cap, name))
        deferrals.done(('Le serveur est plein (%d/%d).'):format(#GetPlayers(), cap))
        return
    end
    deferrals.done()
end)

H.ban = function(p)
    local ident, name = p.identifier, p.name or ''
    if p.id and GetPlayerName(p.id) then
        local ids = banIdentifiers(p.id)
        for _, id in ipairs(ids) do if id:sub(1, 8) == 'license:' then ident = id end end
        name = GetPlayerName(p.id)
    end
    if not ident or ident == '' then return nil, 'identifiant introuvable' end
    local entry = { identifier = ident, name = name, reason = p.reason or 'Banni', ['until'] = (p.days or 0) > 0 and (now() + p.days * 86400) or 0, at = now() }
    local list = {} for _, b in ipairs(bans) do if b.identifier ~= ident then list[#list + 1] = b end end
    list[#list + 1] = entry; bans = list; saveDoc('bans', bans)
    PanelLog('staff', 'ban', ('%s banni : %s'):format(name ~= '' and name or ident, entry.reason))
    if p.id and GetPlayerName(p.id) then DropPlayer(p.id, 'Banni : ' .. entry.reason) end
    return 'banni', { bans = bans }
end
H.unban = function(p)
    local list = {} for _, b in ipairs(bans) do if b.identifier ~= p.identifier then list[#list + 1] = b end end
    bans = list; saveDoc('bans', bans) return 'débanni', { bans = bans }
end
H.whitelist_add = function(p) for _, w in ipairs(whitelist) do if w == p.identifier then return 'déjà présent' end end whitelist[#whitelist + 1] = p.identifier saveDoc('whitelist', whitelist) return 'ajouté', { whitelist = whitelist } end
H.whitelist_remove = function(p) local l = {} for _, w in ipairs(whitelist) do if w ~= p.identifier then l[#l + 1] = w end end whitelist = l saveDoc('whitelist', whitelist) return 'retiré', { whitelist = whitelist } end

AddEventHandler('esx:playerLoaded', function(src)
    PanelLog('info', 'connexion', ('%s (ID %d) a rejoint le serveur'):format(GetPlayerName(src) or '?', src))
    if motd.enabled and motd.text ~= '' then SetTimeout(8000, function() if GetPlayerName(src) then TriggerClientEvent('pickax_notify:showNotification', src, motd.text) end end) end
end)
AddEventHandler('playerDropped', function(reason) PanelLog('info', 'connexion', ('%s (ID %d) a quitté : %s'):format(GetPlayerName(source) or '?', source, reason or '')) end)

-- ───────── boucle de synchronisation ─────────
local extra -- bans/whitelist modifiés en jeu, renvoyés au panel
local interval = Config.Interval

local function runCommand(c)
    local f = H[c.type]
    if not f then return false, 'action inconnue' end
    local ok, r1, r2 = pcall(f, c.payload or {})
    if not ok then PanelLog('error', 'pickax_panel', 'action ' .. tostring(c.type) .. ' : ' .. tostring(r1)) return false, tostring(r1):sub(1, 200) end
    if r1 == nil then return false, r2 or 'échec' end
    local pre = tostring(c.type):sub(1, 3)
    return true, r1, (pre == 'fs.' or pre == 'db.') and r2 or nil
end

local function runCommands(list)
    for _, c in ipairs(list or {}) do
        local done, res, data = runCommand(c)
        results[#results + 1] = { id = c.id, ok = done, result = tostring(res), data = data }
    end
end
local function dropResults(sent)
    local ids = {}
    for _, r in ipairs(sent) do ids[r.id] = true end
    local keep = {}
    for _, r in ipairs(results) do if not ids[r.id] then keep[#keep + 1] = r end end
    results = keep
end

local function enforce()
    if not Config.Enforce then return end
    local invalid = license.valid == false
    local lost = license.valid ~= false and license.last_ok > 0 and (now() - license.last_ok) > Config.GraceHours * 3600
    if not invalid and not lost then return end
    for _, r in ipairs(Config.StopResources) do
        if GetResourceState(r) == 'started' then
            print(('^1[pickax_panel]^7 Licence %s : arrêt de %s'):format(invalid and 'invalide (' .. tostring(license.status) .. ')' or 'non vérifiable depuis trop longtemps', r))
            ExecuteCommand('stop ' .. r)
        end
    end
end

local function sync()
    local body = {
        version = VERSION, maxPlayers = GetConvarInt('sv_maxclients', 48), players = collectPlayers(),
        stats = { uptime = math.floor(GetGameTimer() / 1000), version = GetConvar('version', ''), hostname = GetConvar('sv_projectName', GetConvar('sv_hostname', '')), memory = math.floor(collectgarbage('count') / 1024) },
        logs = logs, results = results, docs = docVersions, reports = reports,
    }
    if GetResourceState('pickax_settings') == 'started' then
        local okA, act = pcall(function() return exports.pickax_settings:Activity() end)       -- activité du jour / de la semaine (ventes, saisies, labos, gangs…) pour la page Statistiques
        if okA and type(act) == 'table' then body.stats.activity = act end
    end
    if now() - lastResources >= Config.ResourcesEvery then body.resources = collectResources() end
    if not schemaSent and GetResourceState('pickax_settings') == 'started' then
        local okS, sch = pcall(function() return exports.pickax_settings:Schema() end)
        if okS and type(sch) == 'table' and #sch > 0 then body.settingsSchema = sch end
    end
    local sentLogs, sentReports = #logs, #reports
    local sentResults = {}
    for i, r in ipairs(results) do sentResults[i] = r end
    PerformHttpRequest(URL .. '/api/agent/sync', function(code, text)
        if code ~= 200 then
            local ok, r = pcall(json.decode, text or '')
            local msg = ok and r and r.error or ('HTTP ' .. tostring(code))
            if msg ~= lastErr then lastErr = msg print('^1[pickax_panel]^7 ' .. tostring(msg)) end
            if code == 403 then license.valid = false license.status = 'refusée' end
            enforce() return
        end
        local ok, r = pcall(json.decode, text)
        if not ok or type(r) ~= 'table' then return end
        for _ = 1, sentLogs do table.remove(logs, 1) end
        for _ = 1, sentReports do table.remove(reports, 1) end
        dropResults(sentResults)
        if body.resources then lastResources = now() end
        if body.settingsSchema then schemaSent = true end
        if r.license then
            license.valid = r.license.valid == true; license.status = r.license.status; license.plan = r.license.plan; license.expires_at = r.license.expires_at
            if license.valid then license.last_ok = now() end
        end
        if r.ok == false then
            if r.error ~= lastErr then lastErr = r.error print('^1[pickax_panel]^7 ' .. tostring(r.error)) end
            license.valid = false enforce() return
        end
        lastErr = nil; interval = tonumber(r.interval) or Config.Interval
        for k, d in pairs(r.docs or {}) do docVersions[k] = d.version onDoc(k, d.value) end
        runCommands(r.commands)
        enforce()
    end, 'POST', json.encode(body), { ['Content-Type'] = 'application/json', ['X-License-Key'] = KEY })
end

CreateThread(function()
    Wait(5000)
    PanelLog('info', 'pickax_panel', 'Ressource démarrée (v' .. VERSION .. ')')
    while true do
        local ok, err = pcall(sync)
        if not ok then print('^1[pickax_panel]^7 erreur : ' .. tostring(err)) end
        Wait(math.max(5, interval) * 1000)
    end
end)


-- Requête longue : le panel répond dès qu'une action (fichier, console…) est demandée → éditeur instantané
CreateThread(function()
    Wait(8000)
    while true do
        local finished, wait = false, 1
        local sent = {}
        for i, r in ipairs(results) do sent[i] = r end
        PerformHttpRequest(URL .. '/api/agent/poll', function(code, text)
            finished = true
            if code ~= 200 then wait = 5000 return end
            local ok, r = pcall(json.decode, text)
            if not ok or type(r) ~= 'table' then wait = 5000 return end
            dropResults(sent)
            if r.license then license.valid = r.license.valid == true if license.valid then license.last_ok = now() end end
            if r.ok == false then wait = 15000 return end
            if r.retry then wait = r.retry * 1000 end
            for k, d in pairs(r.docs or {}) do docVersions[k] = d.version onDoc(k, d.value) end
            runCommands(r.commands)
        end, 'POST', json.encode({ results = sent, docs = docVersions }), { ['Content-Type'] = 'application/json', ['X-License-Key'] = KEY })
        local t = 0
        while not finished and t < 40000 do Wait(50) t = t + 50 end
        Wait(wait)
    end
end)

AddEventHandler('onResourceStart', function(res) if res ~= GetCurrentResourceName() then PanelLog('info', 'ressource', res .. ' démarrée') end end)
AddEventHandler('onResourceStop', function(res) if res ~= GetCurrentResourceName() then PanelLog('info', 'ressource', res .. ' arrêtée') end end)
print(('^2[pickax_panel]^7 Liaison avec le panel : %s'):format(URL))
