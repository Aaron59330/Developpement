Aura = {
    phones   = {},   -- [identifier] = données du téléphone
    byNumber = {},   -- [numéro]     = identifier
    byAddr   = {},   -- [adresse mail] = identifier
    src      = {},   -- [identifier] = source (joueur en ligne)
    ident    = {},   -- [source]     = identifier
}

local function dbg(...) if Config.Debug then print('^5[pickax_phone]^7', ...) end end
Aura.dbg = dbg

-- ═════════════════ BASE DE DONNÉES ═════════════════
local SCHEMA = {
[[CREATE TABLE IF NOT EXISTS aura_phones (
    identifier VARCHAR(80) NOT NULL PRIMARY KEY,
    number VARCHAR(20) NOT NULL UNIQUE,
    mail VARCHAR(120) NULL,
    settings LONGTEXT NULL,
    apps LONGTEXT NULL,
    battery TINYINT UNSIGNED NOT NULL DEFAULT 100,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
)]],
[[CREATE TABLE IF NOT EXISTS aura_kv (
    owner VARCHAR(80) NOT NULL,
    k VARCHAR(40) NOT NULL,
    v LONGTEXT NULL,
    PRIMARY KEY (owner, k)
)]],
[[CREATE TABLE IF NOT EXISTS aura_contacts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner VARCHAR(80) NOT NULL,
    name VARCHAR(60) NOT NULL,
    number VARCHAR(20) NOT NULL,
    email VARCHAR(120) NULL,
    avatar TEXT NULL,
    favorite TINYINT(1) NOT NULL DEFAULT 0,
    blocked TINYINT(1) NOT NULL DEFAULT 0,
    note VARCHAR(255) NULL,
    INDEX (owner)
)]],
[[CREATE TABLE IF NOT EXISTS aura_calls (
    id INT AUTO_INCREMENT PRIMARY KEY,
    caller VARCHAR(20) NOT NULL,
    callee VARCHAR(20) NOT NULL,
    status VARCHAR(12) NOT NULL DEFAULT 'missed',
    duration INT NOT NULL DEFAULT 0,
    hidden TINYINT(1) NOT NULL DEFAULT 0,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX (caller), INDEX (callee)
)]],
[[CREATE TABLE IF NOT EXISTS aura_conv (
    id VARCHAR(60) NOT NULL PRIMARY KEY,
    kind VARCHAR(8) NOT NULL DEFAULT 'direct',
    name VARCHAR(60) NULL,
    avatar TEXT NULL,
    owner VARCHAR(20) NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
)]],
[[CREATE TABLE IF NOT EXISTS aura_conv_members (
    conv VARCHAR(60) NOT NULL,
    number VARCHAR(20) NOT NULL,
    muted TINYINT(1) NOT NULL DEFAULT 0,
    pinned TINYINT(1) NOT NULL DEFAULT 0,
    hidden TINYINT(1) NOT NULL DEFAULT 0,
    last_read BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY (conv, number),
    INDEX (number)
)]],
[[CREATE TABLE IF NOT EXISTS aura_messages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    conv VARCHAR(60) NOT NULL,
    sender VARCHAR(20) NOT NULL,
    kind VARCHAR(12) NOT NULL DEFAULT 'text',
    body TEXT NULL,
    meta TEXT NULL,
    reply_to BIGINT NULL,
    reactions TEXT NULL,
    created BIGINT NOT NULL,
    INDEX (conv, id)
)]],
[[CREATE TABLE IF NOT EXISTS aura_photos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner VARCHAR(80) NOT NULL,
    url TEXT NOT NULL,
    kind VARCHAR(8) NOT NULL DEFAULT 'photo',
    favorite TINYINT(1) NOT NULL DEFAULT 0,
    created BIGINT NOT NULL,
    INDEX (owner)
)]],
[[CREATE TABLE IF NOT EXISTS aura_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    app VARCHAR(12) NOT NULL,
    identifier VARCHAR(80) NOT NULL,
    handle VARCHAR(30) NOT NULL,
    display VARCHAR(60) NOT NULL,
    avatar TEXT NULL,
    banner TEXT NULL,
    bio VARCHAR(200) NULL,
    verified TINYINT(1) NOT NULL DEFAULT 0,
    created BIGINT NOT NULL,
    UNIQUE KEY uq_handle (app, handle),
    UNIQUE KEY uq_owner (app, identifier)
)]],
[[CREATE TABLE IF NOT EXISTS aura_posts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    app VARCHAR(12) NOT NULL,
    handle VARCHAR(30) NOT NULL,
    kind VARCHAR(8) NOT NULL DEFAULT 'post',
    body TEXT NULL,
    images TEXT NULL,
    parent BIGINT NULL,
    repost BIGINT NULL,
    created BIGINT NOT NULL,
    INDEX (app, created), INDEX (parent), INDEX (handle)
)]],
[[CREATE TABLE IF NOT EXISTS aura_likes (
    app VARCHAR(12) NOT NULL,
    post BIGINT NOT NULL,
    handle VARCHAR(30) NOT NULL,
    PRIMARY KEY (app, post, handle)
)]],
[[CREATE TABLE IF NOT EXISTS aura_follows (
    app VARCHAR(12) NOT NULL,
    follower VARCHAR(30) NOT NULL,
    followee VARCHAR(30) NOT NULL,
    PRIMARY KEY (app, follower, followee)
)]],
[[CREATE TABLE IF NOT EXISTS aura_match (
    identifier VARCHAR(80) NOT NULL PRIMARY KEY,
    name VARCHAR(40) NOT NULL,
    age TINYINT UNSIGNED NOT NULL DEFAULT 25,
    gender VARCHAR(10) NOT NULL DEFAULT 'autre',
    looking VARCHAR(10) NOT NULL DEFAULT 'tous',
    bio VARCHAR(250) NULL,
    photos TEXT NULL,
    active TINYINT(1) NOT NULL DEFAULT 1
)]],
[[CREATE TABLE IF NOT EXISTS aura_swipes (
    identifier VARCHAR(80) NOT NULL,
    target VARCHAR(80) NOT NULL,
    liked TINYINT(1) NOT NULL,
    created BIGINT NOT NULL,
    PRIMARY KEY (identifier, target)
)]],
[[CREATE TABLE IF NOT EXISTS aura_bank_tx (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(80) NOT NULL,
    kind VARCHAR(12) NOT NULL,
    amount DOUBLE NOT NULL,
    other VARCHAR(80) NULL,
    label VARCHAR(120) NULL,
    created BIGINT NOT NULL,
    INDEX (identifier, id)
)]],
[[CREATE TABLE IF NOT EXISTS aura_bills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(80) NOT NULL,
    issuer VARCHAR(80) NOT NULL,
    society VARCHAR(40) NULL,
    amount DOUBLE NOT NULL,
    reason VARCHAR(200) NULL,
    status VARCHAR(8) NOT NULL DEFAULT 'open',
    created BIGINT NOT NULL,
    INDEX (identifier, status)
)]],
[[CREATE TABLE IF NOT EXISTS aura_crypto (
    identifier VARCHAR(80) NOT NULL,
    coin VARCHAR(10) NOT NULL,
    amount DOUBLE NOT NULL DEFAULT 0,
    invested DOUBLE NOT NULL DEFAULT 0,
    PRIMARY KEY (identifier, coin)
)]],
[[CREATE TABLE IF NOT EXISTS aura_crypto_prices (
    coin VARCHAR(10) NOT NULL PRIMARY KEY,
    price DOUBLE NOT NULL,
    history TEXT NULL
)]],
[[CREATE TABLE IF NOT EXISTS aura_market (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(80) NOT NULL,
    number VARCHAR(20) NOT NULL,
    seller VARCHAR(60) NOT NULL,
    title VARCHAR(80) NOT NULL,
    descr TEXT NULL,
    price DOUBLE NOT NULL DEFAULT 0,
    category VARCHAR(30) NOT NULL,
    images TEXT NULL,
    sold TINYINT(1) NOT NULL DEFAULT 0,
    created BIGINT NOT NULL,
    INDEX (category), INDEX (identifier)
)]],
[[CREATE TABLE IF NOT EXISTS aura_mail (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner VARCHAR(120) NOT NULL,
    from_addr VARCHAR(120) NOT NULL,
    to_addr VARCHAR(120) NOT NULL,
    subject VARCHAR(120) NOT NULL,
    body TEXT NULL,
    folder VARCHAR(8) NOT NULL DEFAULT 'inbox',
    seen TINYINT(1) NOT NULL DEFAULT 0,
    starred TINYINT(1) NOT NULL DEFAULT 0,
    created BIGINT NOT NULL,
    INDEX (owner, folder)
)]],
}

CreateThread(function()
    for _, q in ipairs(SCHEMA) do MySQL.query.await(q) end
    -- charge les numéros existants
    local rows = MySQL.query.await('SELECT identifier, number, mail, settings, apps, battery FROM aura_phones') or {}
    for _, r in ipairs(rows) do Aura.LoadRow(r) end
    dbg(('%d téléphones chargés'):format(#rows))
    if Config.Messages.historyDays and Config.Messages.historyDays > 0 then
        MySQL.query('DELETE FROM aura_messages WHERE created < ?', { (os.time() - Config.Messages.historyDays * 86400) * 1000 })
    end
    MySQL.query('DELETE FROM aura_posts WHERE app = "snap" AND kind = "story" AND created < ?', { (os.time() - Config.Social.storyHours * 3600) * 1000 })
    MySQL.query('DELETE FROM aura_market WHERE created < ?', { (os.time() - Config.Market.expireDays * 86400) * 1000 })
    Bridge.Wait()
    for _, src in ipairs(Bridge.Players()) do Aura.OnLoaded(src) end
end)

-- ═════════════════ UTILITAIRES ═════════════════
function Aura.Now() return os.time() * 1000 end
function Aura.Json(v) return json.encode(v == nil and {} or v) end
function Aura.Unjson(s, d) if not s or s == '' then return d end local ok, v = pcall(json.decode, s) if ok and v ~= nil then return v end return d end
function Aura.Clamp(s, n) s = tostring(s or ''); if #s > n then s = s:sub(1, n) end return s end
function Aura.Trim(s) return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', '')) end
function Aura.CleanNumber(n) return (tostring(n or ''):gsub('%D', '')) end

function Aura.Push(identifier, event, data)
    local s = Aura.src[identifier]
    if s then TriggerClientEvent('aura:push', s, event, data) return true end
    return false
end
function Aura.PushNumber(number, event, data)
    local id = Aura.byNumber[number]
    return id and Aura.Push(id, event, data) or false
end

function Aura.Identifier(src)
    if Aura.ident[src] then return Aura.ident[src] end
    return Bridge.Identifier(src)
end

function Aura.Name(identifier)
    local s = Aura.src[identifier]
    local n = s and Bridge.Name(s)
    if n and n ~= '' then return n end
    return Bridge.OfflineName(identifier) or 'Inconnu'
end

function Aura.IsAdmin(src) return Bridge.IsAdmin(src) end

function Aura.FormatNumber(n)
    n = tostring(n or '')
    local g = Config.Number.group or 2
    local first = n:sub(1, g)
    local rest = n:sub(g + 1)
    local out = { first }
    for i = 1, #rest, g do out[#out + 1] = rest:sub(i, i + g - 1) end
    return table.concat(out, ' ')
end

-- ═════════════════ TÉLÉPHONES ═════════════════
local DEFAULT_SETTINGS = {
    wallpaper = 'aurora', lockWallpaper = 'aurora', customWallpaper = '', theme = 'dark', accent = '#0a84ff',
    ringtone = 'Marimba', texttone = 'Cristal', volume = 70, dnd = false, airplane = false, wifi = true, bluetooth = false,
    pinEnabled = false, pin = '', brightness = 100, textSize = 100, phoneScale = 100, previews = true, hour24 = true, hideNumber = false,
    vibrate = true, autoLock = 30, notifOff = {}, badgeOff = {}, readReceipts = true, focusMode = 'none', bold = false,
    reduceMotion = false, lang = 'fr',
}
for k, v in pairs(Config.Defaults or {}) do if DEFAULT_SETTINGS[k] ~= nil and type(v) == type(DEFAULT_SETTINGS[k]) then DEFAULT_SETTINGS[k] = v end end

local function defaultApps()
    local t = {}
    for _, a in ipairs(Config.Apps) do if a.enabled and a.default then t[#t + 1] = a.id end end
    return t
end

function Aura.LoadRow(r)
    local settings = Aura.Unjson(r.settings, {})
    for k, v in pairs(DEFAULT_SETTINGS) do if settings[k] == nil then settings[k] = v end end
    local p = { identifier = r.identifier, number = r.number, mail = r.mail, settings = settings, apps = Aura.Unjson(r.apps, defaultApps()), battery = r.battery or 100 }
    Aura.phones[r.identifier] = p
    Aura.byNumber[r.number] = r.identifier
    if r.mail then Aura.byAddr[r.mail] = r.identifier end
    return p
end

local function genNumber()
    local pre = Config.Number.prefixes
    for _ = 1, 200 do
        local n = pre[math.random(#pre)]
        while #n < Config.Number.length do n = n .. tostring(math.random(0, 9)) end
        if not Aura.byNumber[n] then return n end
    end
end

local function slug(s)
    s = (s or ''):lower()
    local map = { ['à'] = 'a', ['â'] = 'a', ['ä'] = 'a', ['é'] = 'e', ['è'] = 'e', ['ê'] = 'e', ['ë'] = 'e', ['î'] = 'i', ['ï'] = 'i', ['ô'] = 'o', ['ö'] = 'o', ['ù'] = 'u', ['û'] = 'u', ['ü'] = 'u', ['ç'] = 'c' }
    for k, v in pairs(map) do s = s:gsub(k, v) end
    s = s:gsub('[^%w]+', '.'):gsub('^%.+', ''):gsub('%.+$', '')
    return s ~= '' and s or 'user'
end
Aura.Slug = slug

function Aura.EnsurePhone(identifier, name)
    local p = Aura.phones[identifier]
    if p then return p end
    local number = genNumber()
    if not number then return nil end
    local base = slug(name or Aura.Name(identifier)) .. '@' .. Config.MailDomain
    local mail, i = base, 1
    while Aura.byAddr[mail] do i = i + 1; mail = slug(name or '') .. i .. '@' .. Config.MailDomain end
    local settings = {}
    for k, v in pairs(DEFAULT_SETTINGS) do settings[k] = v end
    MySQL.insert.await('INSERT INTO aura_phones (identifier, number, mail, settings, apps, battery) VALUES (?, ?, ?, ?, ?, 100)', { identifier, number, mail, Aura.Json(settings), Aura.Json(defaultApps()) })
    p = { identifier = identifier, number = number, mail = mail, settings = settings, apps = defaultApps(), battery = 100 }
    Aura.phones[identifier] = p; Aura.byNumber[number] = identifier; Aura.byAddr[mail] = identifier
    return p
end

function Aura.SaveSettings(identifier)
    local p = Aura.phones[identifier]; if not p then return end
    MySQL.update('UPDATE aura_phones SET settings = ?, apps = ?, battery = ? WHERE identifier = ?', { Aura.Json(p.settings), Aura.Json(p.apps), math.floor(p.battery), identifier })
end

function Aura.OnLoaded(src)
    local id = Bridge.Identifier(src)
    if not id then return end
    Aura.src[id] = src; Aura.ident[src] = id
    local p = Aura.EnsurePhone(id, Bridge.Name(src))
    if p then TriggerEvent('aura:phoneLoaded', src, p.number) end
end

CreateThread(function()
    Bridge.Wait()
    Bridge.OnLoaded(function(src) SetTimeout(500, function() Aura.OnLoaded(src) end) end)
end)
AddEventHandler('playerDropped', function()
    local src = source
    local id = Aura.ident[src]
    if id then
        Aura.SaveSettings(id)
        Aura.src[id] = nil; Aura.ident[src] = nil
        TriggerEvent('aura:phoneDropped', src, id)
    end
end)

-- ═════════════════ BATTERIE ═════════════════
CreateThread(function()
    if not Config.Battery.enabled then return end
    while true do
        Wait(Config.Battery.drainEvery * 1000)
        for id, src in pairs(Aura.src) do
            local p = Aura.phones[id]
            if p and p.battery > 0 and not p.charging then
                p.battery = math.max(0, p.battery - 1)
                TriggerClientEvent('aura:push', src, 'battery', { level = p.battery, charging = false })
            end
        end
    end
end)
CreateThread(function()
    if not Config.Battery.enabled then return end
    while true do
        Wait(Config.Battery.chargeEvery * 1000)
        for id, src in pairs(Aura.src) do
            local p = Aura.phones[id]
            if p and p.charging and p.battery < 100 then
                p.battery = math.min(100, p.battery + 1)
                TriggerClientEvent('aura:push', src, 'battery', { level = p.battery, charging = true })
            end
        end
    end
end)
CreateThread(function() -- sauvegarde périodique
    while true do Wait(300000) for id in pairs(Aura.src) do Aura.SaveSettings(id) end end
end)

RegisterNetEvent('aura:setCharging', function(state)
    local id = Aura.ident[source]; local p = id and Aura.phones[id]
    if not p then return end
    p.charging = state and true or false
    TriggerClientEvent('aura:push', source, 'battery', { level = p.battery, charging = p.charging })
end)

lib.callback.register('aura:usePowerbank', function(src)
    local id = Aura.ident[src]; local p = id and Aura.phones[id]
    if not p or not Config.Battery.powerbankItem then return false end
    if not Bridge.RemoveItem(src, Config.Battery.powerbankItem, 1) then return false end
    p.battery = 100
    TriggerClientEvent('aura:push', src, 'battery', { level = 100, charging = p.charging or false })
    return true
end)

-- ═════════════════ CONTACTS ═════════════════
local function contactsOf(id)
    return MySQL.query.await('SELECT id, name, number, email, avatar, favorite, blocked, note FROM aura_contacts WHERE owner = ? ORDER BY name', { id }) or {}
end
Aura.ContactsOf = contactsOf

function Aura.ContactName(owner, number)
    local r = MySQL.scalar.await('SELECT name FROM aura_contacts WHERE owner = ? AND number = ? LIMIT 1', { owner, number })
    return r
end

lib.callback.register('aura:contacts', function(src) local id = Aura.ident[src]; return id and contactsOf(id) or {} end)

lib.callback.register('aura:contactSave', function(src, c)
    local id = Aura.ident[src]; if not id or type(c) ~= 'table' then return false end
    local name = Aura.Clamp(Aura.Trim(c.name), 60)
    local number = Aura.Clamp(Aura.CleanNumber(c.number), 20)
    if name == '' or number == '' then return false, 'Nom et numéro requis' end
    local avatar = c.avatar and Aura.Clamp(c.avatar, 500) or nil
    local email = c.email and Aura.Clamp(c.email, 120) or nil
    local note = c.note and Aura.Clamp(c.note, 255) or nil
    if c.id then
        MySQL.update.await('UPDATE aura_contacts SET name=?, number=?, email=?, avatar=?, favorite=?, blocked=?, note=? WHERE id=? AND owner=?',
            { name, number, email, avatar, c.favorite and 1 or 0, c.blocked and 1 or 0, note, c.id, id })
        return c.id
    end
    local n = MySQL.scalar.await('SELECT COUNT(*) FROM aura_contacts WHERE owner = ?', { id })
    if (n or 0) >= (Config.Limits.contacts or 500) then return false, 'Limite de contacts atteinte' end
    return MySQL.insert.await('INSERT INTO aura_contacts (owner, name, number, email, avatar, favorite, blocked, note) VALUES (?,?,?,?,?,?,?,?)',
        { id, name, number, email, avatar, c.favorite and 1 or 0, c.blocked and 1 or 0, note })
end)

lib.callback.register('aura:contactDelete', function(src, cid)
    local id = Aura.ident[src]; if not id then return false end
    MySQL.update.await('DELETE FROM aura_contacts WHERE id = ? AND owner = ?', { tonumber(cid) or 0, id })
    return true
end)

lib.callback.register('aura:contactFlag', function(src, cid, field, value)
    local id = Aura.ident[src]; if not id then return false end
    if field ~= 'favorite' and field ~= 'blocked' then return false end
    MySQL.update.await(('UPDATE aura_contacts SET %s = ? WHERE id = ? AND owner = ?'):format(field), { value and 1 or 0, tonumber(cid) or 0, id })
    return true
end)

function Aura.IsBlocked(owner, number)
    return (MySQL.scalar.await('SELECT 1 FROM aura_contacts WHERE owner = ? AND number = ? AND blocked = 1 LIMIT 1', { owner, number })) ~= nil
end

-- ═════════════════ PARAMÈTRES / APPLICATIONS / KV ═════════════════
lib.callback.register('aura:settingsSet', function(src, patch)
    local id = Aura.ident[src]; local p = id and Aura.phones[id]
    if not p or type(patch) ~= 'table' then return false end
    for k, v in pairs(patch) do
        if DEFAULT_SETTINGS[k] ~= nil and type(v) == type(DEFAULT_SETTINGS[k]) then
            if type(v) == 'string' then v = Aura.Clamp(v, k == 'customWallpaper' and 500 or 40) end
            p.settings[k] = v
        end
    end
    Aura.SaveSettings(id)
    return true
end)

lib.callback.register('aura:appInstall', function(src, appId, install)
    local id = Aura.ident[src]; local p = id and Aura.phones[id]
    if not p then return false end
    local def
    for _, a in ipairs(Config.Apps) do if a.id == appId and a.enabled then def = a end end
    if not def or not Aura.AppAllowed(src, def, Bridge.Job(src)) then return false end
    local has = false
    for i, a in ipairs(p.apps) do if a == appId then has = i end end
    if install and not has then p.apps[#p.apps + 1] = appId
    elseif not install and has and not def.system then table.remove(p.apps, has) end
    Aura.SaveSettings(id)
    return p.apps
end)

local KV_KEYS = { notes = true, events = true, alarms = true, places = true, playlist = true, lastweather = true, widgets = true, home = true, recents = true, fm_share = true, todos = true, scores = true }
lib.callback.register('aura:kvGet', function(src, key)
    local id = Aura.ident[src]; if not id or not KV_KEYS[key] then return nil end
    return Aura.Unjson(MySQL.scalar.await('SELECT v FROM aura_kv WHERE owner = ? AND k = ?', { id, key }), nil)
end)
lib.callback.register('aura:kvSet', function(src, key, value)
    local id = Aura.ident[src]; if not id or not KV_KEYS[key] then return false end
    local s = Aura.Json(value)
    if #s > 200000 then return false, 'Trop volumineux' end
    MySQL.query.await('INSERT INTO aura_kv (owner, k, v) VALUES (?,?,?) ON DUPLICATE KEY UPDATE v = VALUES(v)', { id, key, s })
    return true
end)

lib.callback.register('aura:pinCheck', function(src, pin)
    local id = Aura.ident[src]; local p = id and Aura.phones[id]
    if not p then return false end
    return tostring(pin) == tostring(p.settings.pin)
end)

-- Règles d'accès d'une application (Config.Apps : jobs / grade / item)
function Aura.AppAllowed(src, app, job)
    if app.jobs and #app.jobs > 0 then
        local ok = false
        for _, j in ipairs(app.jobs) do if job and job.name == j then ok = true end end
        if not ok then return false end
        if app.grade and (not job or job.grade < app.grade) then return false end
    end
    if app.item and app.item ~= '' and not Bridge.HasItem(src, app.item) then return false end
    return true
end

local phoneCache = {}
lib.callback.register('aura:hasPhone', function(src)
    if not Config.RequireItem then return true end
    return Bridge.HasItem(src, Config.Item)
end)

-- ═════════════════ INITIALISATION CLIENT ═════════════════
lib.callback.register('aura:init', function(src)
    local id = Aura.Identifier(src)
    if not id then return nil end
    Aura.ident[src] = id; Aura.src[id] = src
    local p = Aura.EnsurePhone(id, Bridge.Name(src))
    if not p then return nil end
    local job = Bridge.Job(src)
    local apps = {}
    for _, a in ipairs(Config.Apps) do if a.enabled and Aura.AppAllowed(src, a, job) then apps[#apps + 1] = { id = a.id, default = a.default, system = a.system, dock = a.dock, store = a.store, name = a.name, grad = a.grad, icon = a.icon } end end
    local allowed = {}
    for _, a in ipairs(apps) do allowed[a.id] = true end
    local installed = {}
    for _, appId in ipairs(p.apps) do if allowed[appId] then installed[#installed + 1] = appId end end
    local hasPin = p.settings.pinEnabled and p.settings.pin ~= ''
    local settings = {}
    for k, v in pairs(p.settings) do if k ~= 'pin' then settings[k] = v end end
    return {
        me = { number = p.number, display = Aura.FormatNumber(p.number), name = Bridge.Name(src) or 'Joueur', mail = p.mail, job = job and job.name or nil,
               jobLabel = job and job.label or nil, identifier = id, admin = Aura.IsAdmin(src) },
        settings = settings, hasPin = hasPin, installed = installed, catalog = apps,
        battery = p.battery, contacts = contactsOf(id),
        config = { mailDomain = Config.MailDomain, brand = Config.Brand, model = Config.Model, carrier = Config.Carrier, accent = Config.Defaults.accent, serverName = PickaxTheme and PickaxTheme.name or nil, ui = Config.UI, limits = Config.Limits, framework = Bridge.fw, wallpapers = Config.Wallpapers, ringtones = Config.Ringtones, radios = Config.Radios,
                   lines = Aura.LinesPublic(), taxi = Config.Taxi, market = Config.Market.categories, crypto = Config.Crypto.coins, social = { max = Config.Social.postMaxLength, images = Config.Social.maxImages },
                   numberGroup = Config.Number.group, messages = Config.Messages, camera = Config.Camera.mode, maxMarketImages = Config.Market.maxImages, storyHours = Config.Social.storyHours },
    }
end)

-- ═════════════════ ADMIN ═════════════════
RegisterCommand('phone_number', function(src, args)
    if src ~= 0 and not Aura.IsAdmin(src) then return end
    local target = tonumber(args[1]) or src
    local id = Aura.ident[target]; local p = id and Aura.phones[id]
    local msg = p and ('Numéro de %s : %s'):format(GetPlayerName(target), Aura.FormatNumber(p.number)) or 'Joueur introuvable'
    if src == 0 then print(msg) else TriggerClientEvent('chat:addMessage', src, { args = { 'Aura', msg } }) end
end, false)

RegisterCommand('phone_reset', function(src, args)
    if src ~= 0 and not Aura.IsAdmin(src) then return end
    local target = tonumber(args[1]); local id = target and Aura.ident[target]
    if not id then return end
    local p = Aura.phones[id]
    MySQL.query.await('DELETE FROM aura_kv WHERE owner = ?', { id })
    MySQL.query.await('DELETE FROM aura_contacts WHERE owner = ?', { id })
    MySQL.query.await('DELETE FROM aura_photos WHERE owner = ?', { id })
    for k, v in pairs(DEFAULT_SETTINGS) do p.settings[k] = v end
    p.apps = defaultApps(); Aura.SaveSettings(id)
    TriggerClientEvent('aura:push', target, 'reset', {})
end, false)

RegisterCommand('phone_give', function(src, args)
    if src ~= 0 and not Aura.IsAdmin(src) then return end
    local target = tonumber(args[1]) or src
    if target == 0 then return end
    Bridge.AddItem(target, Config.Item, 1)
end, false)
