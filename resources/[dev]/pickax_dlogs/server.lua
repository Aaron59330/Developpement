-- [AERO:LIC] contrôle de licence via pickax_core (qui vérifie lui-même la signature du panel) : ne pas retirer
do
    local res = GetCurrentResourceName()
    local function ok() local good, v = pcall(function() return exports.pickax_core:Licensed() end) return good and v == true end
    local function die(why) print(('^1[AERO] %s arrêtée : %s^0'):format(res, why)) StopResource(res) end
    if GetResourceState('pickax_core') == 'started' and not ok() then die('licence invalide (pickax_core)') error('AERO : licence invalide', 0) end
    CreateThread(function()
        local tries = 0
        while not ok() do
            tries = tries + 1
            if tries > 8 then die('pickax_core absent ou licence invalide') return end
            Wait(2500)
        end
        while true do
            Wait(240000 + math.random(0, 120000))
            local good = false
            for _ = 1, 4 do if ok() then good = true break end Wait(10000) end
            if not good then die('licence invalide') return end
        end
    end)
end
-- [/AERO:LIC]

-- couleur par défaut des embeds Discord = couleur principale du serveur (pickax_core/config.lua)
local function themeHex()
    local ok, st = pcall(function() return exports['pickax_core']:GetGlobalStyle() end)
    if ok and type(st) == 'table' and type(st.hex) == 'string' and st.hex:match('^#%x%x%x%x%x%x$') then return st.hex end
    return '#fdc27d'
end

-- ─────────────────────────────── Logs Discord par élément ───────────────────────────────
-- Configuration enregistrée en base (table pickax_dlogs), modifiée depuis l'onglet « Logs Discord » de chaque builder.
local cache = {}          -- ['job:police'] = cfg
local queues = {}         -- file d'envoi par webhook (limite Discord)

local DEFAULT_FIELDS = { player = true, identifier = false, detail = true, amount = true, entity = true, time = true }
local FIELD_KEYS = { 'player', 'identifier', 'detail', 'amount', 'entity', 'time' }

local function key(kind, ref) return tostring(kind) .. ':' .. tostring(ref) end

local function validWebhook(u)
    if type(u) ~= 'string' or #u > 300 then return false end
    return u:match('^https://discord%.com/api/webhooks/%d+/[%w_%-]+$') ~= nil
        or u:match('^https://discordapp%.com/api/webhooks/%d+/[%w_%-]+$') ~= nil
        or u:match('^https://ptb%.discord%.com/api/webhooks/%d+/[%w_%-]+$') ~= nil
        or u:match('^https://canary%.discord%.com/api/webhooks/%d+/[%w_%-]+$') ~= nil
end

local function catalogKeys(kind)
    local set = {}
    local cat = DLogsCatalog[kind]
    if not cat then return nil end
    for _, g in ipairs(cat.groups) do for _, e in ipairs(g[2]) do set[e[1]] = e[2] end end
    return set
end

local function colorToInt(hex)
    hex = tostring(hex or ''):gsub('#', '')
    if #hex ~= 6 or not hex:match('^%x+$') then return 0x00A4FF end
    return tonumber(hex, 16)
end

local function sanitize(kind, d, old)
    d = type(d) == 'table' and d or {}
    old = old or {}
    local keys = catalogKeys(kind) or {}
    local out = { enabled = d.enabled == true, webhook = old.webhook or '', name = '', color = themeHex(), mention = '', events = {}, fields = {} }
    if d.clearWebhook == true then out.webhook = '' end
    if type(d.webhook) == 'string' and d.webhook ~= '' and not d.webhook:find('•', 1, true) then
        if not validWebhook(d.webhook) then return nil, 'Lien de webhook invalide (doit commencer par https://discord.com/api/webhooks/)' end
        out.webhook = d.webhook
    end
    out.name = tostring(d.name or ''):gsub('[%c]', ''):sub(1, 40)
    local col = tostring(d.color or '')
    if col:match('^#%x%x%x%x%x%x$') then out.color = col end
    local mention = tostring(d.mention or '')
    if mention == '' or mention == '@everyone' or mention == '@here' or mention:match('^<@&%d+>$') or mention:match('^<@%d+>$') then out.mention = mention end
    if type(d.events) == 'table' then
        for k, v in pairs(d.events) do if v == true and keys[k] then out.events[k] = true end end
    end
    local f = type(d.fields) == 'table' and d.fields or {}
    for _, k in ipairs(FIELD_KEYS) do
        if f[k] == nil then out.fields[k] = DEFAULT_FIELDS[k] else out.fields[k] = f[k] == true end
    end
    if out.enabled and out.webhook == '' then return nil, 'Ajoute un lien de webhook avant d\'activer les logs' end
    return out
end

local function mask(u)
    if not u or u == '' then return '' end
    local id = u:match('/webhooks/(%d+)/') or '…'
    return ('https://discord.com/api/webhooks/%s/••••••••'):format(id)
end

-- ─────────────────────────────── Envoi (file d'attente, limite Discord) ───────────────────────────────
local function pump(url)
    local q = queues[url]
    if not q or q.running then return end
    q.running = true
    CreateThread(function()
        while #q.items > 0 do
            local payload = table.remove(q.items, 1)
            local wait = 700
            PerformHttpRequest(url, function(status, _, headers)
                if status == 429 then
                    table.insert(q.items, 1, payload)
                    local ra = tonumber(headers and (headers['retry-after'] or headers['Retry-After'])) or 2
                    q.pause = math.min(30, ra)
                end
            end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
            Wait(wait)
            if q.pause then Wait(math.floor(q.pause * 1000)) q.pause = nil end
        end
        q.running = false
        if #q.items == 0 then queues[url] = nil end
    end)
end

local function push(url, payload)
    local q = queues[url]
    if not q then q = { items = {} } queues[url] = q end
    if #q.items >= 60 then table.remove(q.items, 1) end      -- jamais plus de 60 messages en attente
    q.items[#q.items + 1] = payload
    pump(url)
end

local function label(kind, action)
    if action == '__test' then return 'Test des logs' end
    local cat = DLogsCatalog[kind]
    if not cat then return action end
    for _, g in ipairs(cat.groups) do
        for _, e in ipairs(g[2]) do
            if e[1] == action then return e[2] end
            if e[1]:sub(-1) == '*' and action:sub(1, #e[1] - 1) == e[1]:sub(1, -2) then return e[2] .. ' · ' .. action end
        end
    end
    return action
end

local function enabledFor(cfg, action)
    if cfg.events[action] then return true end
    local base = action:match('^(.-_)')
    return base ~= nil and cfg.events[base .. '*'] == true
end

local function buildPayload(cfg, kind, entityLabel, action, actor, detail, amount)
    local f = cfg.fields
    local fields = {}
    if f.player and actor and actor.name then fields[#fields + 1] = { name = 'Joueur', value = tostring(actor.name):sub(1, 100), inline = true } end
    if f.identifier and actor and actor.identifier then fields[#fields + 1] = { name = 'Identifiant', value = '`' .. tostring(actor.identifier):sub(1, 80) .. '`', inline = true } end
    if f.amount and amount and tonumber(amount) and tonumber(amount) ~= 0 then fields[#fields + 1] = { name = 'Montant', value = tostring(math.floor(tonumber(amount))), inline = true } end
    if f.entity and entityLabel then fields[#fields + 1] = { name = (DLogsCatalog[kind] and DLogsCatalog[kind].title or 'Élément'), value = tostring(entityLabel):sub(1, 100), inline = true } end
    local embed = { title = label(kind, action):sub(1, 200), color = colorToInt(cfg.color), fields = fields }
    if f.detail and detail and tostring(detail) ~= '' then embed.description = tostring(detail):sub(1, 1500) end
    if f.time then embed.timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ') end
    local content = cfg.mention ~= '' and cfg.mention or nil
    local allowed = { parse = {} }
    if cfg.mention == '@everyone' or cfg.mention == '@here' then allowed.parse = { 'everyone' }
    elseif cfg.mention and cfg.mention:match('^<@&%d+>$') then allowed.roles = { cfg.mention:match('%d+') }
    elseif cfg.mention and cfg.mention:match('^<@%d+>$') then allowed.users = { cfg.mention:match('%d+') } end
    return { username = (cfg.name ~= '' and cfg.name) or 'Pickax Logs', content = content, embeds = { embed }, allowed_mentions = allowed }
end

-- exports.pickax_dlogs:Send('job', 'police', 'Police', 'recruit', { name = 'Jean', identifier = 'license:…' }, 'détail', montant)
local function Send(kind, ref, entityLabel, action, actor, detail, amount)
    if type(ref) == 'string' and ref:sub(1, 1) == '_' then return end
    local cfg = cache[key(kind, ref)]
    if not cfg or not cfg.enabled or cfg.webhook == '' or type(action) ~= 'string' or not enabledFor(cfg, action) then return end
    push(cfg.webhook, buildPayload(cfg, kind, entityLabel, action, actor, detail, amount))
end

-- ─────────────────────────────── Données ───────────────────────────────
CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS pickax_dlogs (kind VARCHAR(12) NOT NULL, ref VARCHAR(80) NOT NULL, cfg MEDIUMTEXT NOT NULL, PRIMARY KEY (kind, ref)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    for _, r in ipairs(MySQL.query.await('SELECT kind, ref, cfg FROM pickax_dlogs') or {}) do
        local ok, c = pcall(json.decode, r.cfg)
        if ok and type(c) == 'table' then cache[key(r.kind, r.ref)] = c end
    end
end)

local function View(kind, ref)
    local keys = catalogKeys(kind)
    if not keys then return { ok = false, error = 'Type inconnu' } end
    local cfg = cache[key(kind, ref)] or { enabled = false, webhook = '', name = '', color = themeHex(), mention = '', events = {}, fields = DEFAULT_FIELDS }
    local groups = {}
    for _, g in ipairs(DLogsCatalog[kind].groups) do
        local ev = {}
        for _, e in ipairs(g[2]) do ev[#ev + 1] = { key = e[1], label = e[2] } end
        groups[#groups + 1] = { label = g[1], events = ev }
    end
    local fields = {}
    for _, k in ipairs(FIELD_KEYS) do
        local v = cfg.fields and cfg.fields[k]
        if v == nil then v = DEFAULT_FIELDS[k] end
        fields[k] = v == true
    end
    return { ok = true, cfg = { enabled = cfg.enabled == true, hasWebhook = cfg.webhook ~= '', webhook = mask(cfg.webhook), name = cfg.name or '', color = cfg.color or themeHex(), mention = cfg.mention or '',
        events = cfg.events or {}, fields = fields }, groups = groups, title = DLogsCatalog[kind].title }
end

local function Save(kind, ref, data)
    if not catalogKeys(kind) or not ref or tostring(ref) == '' then return { ok = false, error = 'Élément inconnu' } end
    local old = cache[key(kind, ref)]
    local cfg, err = sanitize(kind, data, old)
    if not cfg then return { ok = false, error = err } end
    cache[key(kind, ref)] = cfg
    MySQL.update.await('INSERT INTO pickax_dlogs (kind, ref, cfg) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE cfg = VALUES(cfg)', { kind, tostring(ref), json.encode(cfg) })
    return View(kind, ref)
end

local function Delete(kind, ref)
    cache[key(kind, ref)] = nil
    MySQL.update('DELETE FROM pickax_dlogs WHERE kind = ? AND ref = ?', { kind, tostring(ref) })
end

local function Test(kind, ref, entityLabel, by)
    local cfg = cache[key(kind, ref)]
    if not cfg or cfg.webhook == '' then return { ok = false, error = 'Enregistre d\'abord un lien de webhook' } end
    push(cfg.webhook, buildPayload(cfg, kind, entityLabel, '__test', { name = by or 'Staff', identifier = 'license:test' }, 'Message de test : les logs de cet élément arriveront dans ce salon.', 100))
    return { ok = true }
end

exports('Send', Send)
exports('View', View)
exports('Save', Save)
exports('Delete', Delete)
exports('Test', Test)
