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

local function saveDoc(key, value) SaveResourceFile(GetCurrentResourceName(), 'cache_' .. key .. '.json', json.encode(value), -1) end

H.apply_theme = function()
    local t = docs.theme
    if not t then return nil, 'aucun thème enregistré dans le panel' end
    if GetResourceState('pickax_basetools') ~= 'started' then return nil, 'pickax_basetools non démarré' end
    local r = exports.pickax_basetools:ApplyTheme(t, 'panel web')
    if not r or not r.ok then return nil, (r and r.error) or 'échec' end
    return 'thème appliqué'
end

-- bans / whitelist / message de bienvenue (documents synchronisés)
local function onDoc(key, value)
    docs[key] = value; saveDoc(key, value)
    if key == 'bans' then bans = value or {} elseif key == 'whitelist' then whitelist = value or {} elseif key == 'motd' then motd = value or { enabled = false, text = '' } end
end
for _, k in ipairs({ 'bans', 'whitelist', 'motd' }) do
    local raw = LoadResourceFile(GetCurrentResourceName(), 'cache_' .. k .. '.json')
    if raw and raw ~= '' then local ok, v = pcall(json.decode, raw) if ok then onDoc(k, v) end end
end

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
    return true, r1
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
    local sentLogs, sentResults = #logs, #results
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
        for _ = 1, sentResults do table.remove(results, 1) end
        if body.resources then lastResources = now() end
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
        for _, c in ipairs(r.commands or {}) do
            local done, res = runCommand(c)
            results[#results + 1] = { id = c.id, ok = done, result = tostring(res) }
        end
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

AddEventHandler('onResourceStart', function(res) if res ~= GetCurrentResourceName() then PanelLog('info', 'ressource', res .. ' démarrée') end end)
AddEventHandler('onResourceStop', function(res) if res ~= GetCurrentResourceName() then PanelLog('info', 'ressource', res .. ' arrêtée') end end)
print(('^2[pickax_panel]^7 Liaison avec le panel : %s'):format(URL))
