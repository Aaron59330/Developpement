local ESX = exports['es_extended']:getSharedObject()
local URL  = (GetConvar('aero_panel_url', '') or ''):gsub('/+$', '')
local KEY  = GetConvar('aero_panel_key', '') or ''
local VERSION = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '1.0.0'

local license = { valid = nil, status = 'inconnu', plan = nil, expires_at = nil, last_ok = 0 }
local docs, docVersions = {}, {}
local logs, results = {}, {}
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

-- bans / whitelist / message de bienvenue (documents synchronisés)
local function applyServerSettings()
    local c = serverCfg or {}
    local function ok(x) return type(x) == 'string' and x ~= '' and not x:find('"', 1, true) and not x:find('[\r\n;]') end
    if ok(c.projectName) then ExecuteCommand('sets sv_projectName "' .. c.projectName .. '"') end
    if ok(c.projectDesc) then ExecuteCommand('sets sv_projectDesc "' .. c.projectDesc .. '"') end
    if ok(c.hostname) then ExecuteCommand('sv_hostname "' .. c.hostname .. '"') end
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
        logs = logs, results = results, docs = docVersions,
    }
    if now() - lastResources >= Config.ResourcesEvery then body.resources = collectResources() end
    if not schemaSent and GetResourceState('pickax_settings') == 'started' then
        local okS, sch = pcall(function() return exports.pickax_settings:Schema() end)
        if okS and type(sch) == 'table' and #sch > 0 then body.settingsSchema = sch end
    end
    local sentLogs = #logs
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
