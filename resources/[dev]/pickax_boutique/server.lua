local ESX = exports['es_extended']:getSharedObject()

local pending = {}                       -- [src] = { queue = { {cat, idx, name, price} }, code = '', pct = 0 }
local Settings = { referral = { Enabled = Config.Referral.Enabled, FilleulCoins = Config.Referral.FilleulCoins, ParrainCoins = Config.Referral.ParrainCoins } }

local function fail(msg) return { ok = false, error = msg } end
local function core() return exports['pickax_core'] end
local function isAdmin(src) local ok, r = pcall(function() return core():BoutiqueIsAdmin(src) end) return ok and r == true end
local function notify(src, msg) TriggerClientEvent('esx:showNotification', src, msg) end
local function esc(s, n) return tostring(s or ''):gsub('[%c]', ' '):sub(1, n or 80) end

local function log(text)
    print('^3[boutique] ' .. text .. '^0')
    if Config.Webhook ~= '' then
        PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode({ username = 'Boutique', embeds = {{ description = text, color = 3447003 }} }), { ['Content-Type'] = 'application/json' })
    end
end

-- ─────────────────────────────── Base de données ───────────────────────────────
CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS boutique_codes (
        id INT AUTO_INCREMENT PRIMARY KEY, code VARCHAR(32) NOT NULL UNIQUE, kind VARCHAR(10) NOT NULL DEFAULT 'percent',
        value INT NOT NULL DEFAULT 10, max_uses INT NOT NULL DEFAULT 0, per_player INT NOT NULL DEFAULT 1, uses INT NOT NULL DEFAULT 0,
        expires_at TIMESTAMP NULL, active TINYINT(1) NOT NULL DEFAULT 1, note VARCHAR(120) NULL, created_by VARCHAR(80) NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS boutique_code_uses (
        id INT AUTO_INCREMENT PRIMARY KEY, code_id INT NOT NULL, identifier VARCHAR(80) NOT NULL, player_name VARCHAR(80) NULL,
        used_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX idx_code (code_id), INDEX idx_player (identifier)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS boutique_history (
        id INT AUTO_INCREMENT PRIMARY KEY, identifier VARCHAR(80) NOT NULL, player_name VARCHAR(80) NULL, item_name VARCHAR(100) NOT NULL,
        category VARCHAR(20) NULL, price INT NOT NULL DEFAULT 0, full_price INT NOT NULL DEFAULT 0, code VARCHAR(32) NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX idx_player (identifier), INDEX idx_date (created_at)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS boutique_referrals (
        id INT AUTO_INCREMENT PRIMARY KEY, filleul VARCHAR(80) NOT NULL UNIQUE, parrain VARCHAR(80) NOT NULL, filleul_name VARCHAR(80) NULL,
        filleul_coins INT NOT NULL DEFAULT 0, parrain_coins INT NOT NULL DEFAULT 0, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_parrain (parrain)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS boutique_settings (name VARCHAR(40) PRIMARY KEY, value TEXT NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    local row = MySQL.single.await("SELECT value FROM boutique_settings WHERE name = 'referral'")
    if row then
        local ok, v = pcall(json.decode, row.value)
        if ok and type(v) == 'table' then
            Settings.referral.Enabled = v.Enabled ~= false
            Settings.referral.FilleulCoins = tonumber(v.FilleulCoins) or Settings.referral.FilleulCoins
            Settings.referral.ParrainCoins = tonumber(v.ParrainCoins) or Settings.referral.ParrainCoins
        end
    end
end)

-- ─────────────────────────────── Aides ───────────────────────────────
local function playerOf(src) return ESX.GetPlayerFromId(src) end
local function nameOf(xPlayer) return (xPlayer.getName and xPlayer.getName()) or GetPlayerName(xPlayer.source) end
local function normCode(c) return tostring(c or ''):upper():gsub('%s+', ''):gsub('[^%w%-_]', ''):sub(1, 32) end
local function refCodeOf(xPlayer) return xPlayer.boutique_id and ('REF-' .. tostring(xPlayer.boutique_id)) or nil end

-- Vérifie un code promo / cadeau : renvoie la ligne SQL ou nil, message d'erreur
local function checkCode(code, identifier)
    local row = MySQL.single.await('SELECT *, UNIX_TIMESTAMP(expires_at) AS exp FROM boutique_codes WHERE code = ?', { code })
    if not row or row.active ~= 1 then return nil, 'Code invalide' end
    if row.exp and tonumber(row.exp) < os.time() then return nil, 'Ce code a expiré' end
    if row.max_uses > 0 and row.uses >= row.max_uses then return nil, 'Ce code a atteint sa limite d\'utilisations' end
    local mine = MySQL.scalar.await('SELECT COUNT(*) FROM boutique_code_uses WHERE code_id = ? AND identifier = ?', { row.id, identifier }) or 0
    if mine >= math.max(1, row.per_player) then return nil, 'Tu as déjà utilisé ce code' end
    return row
end

local function consumeCode(row, xPlayer)
    MySQL.insert.await('INSERT INTO boutique_code_uses (code_id, identifier, player_name) VALUES (?, ?, ?)', { row.id, xPlayer.identifier, esc(nameOf(xPlayer), 80) })
    MySQL.update.await('UPDATE boutique_codes SET uses = uses + 1 WHERE id = ?', { row.id })
end

local function priceWithPct(price, pct)
    return math.max(0, math.floor(price * (100 - pct) / 100 + 0.5))        -- même arrondi que pickax_core
end

-- ─────────────────────────────── Historique ───────────────────────────────
AddEventHandler('CorePickax:Boutique:Paid', function(src, paid, full, label)
    local xPlayer = playerOf(src)
    if not xPlayer then return end
    local p = pending[src]
    local name, cat, code = label and tostring(label) or 'Achat boutique', nil, nil
    if p and #p.queue > 0 then
        local item = table.remove(p.queue, 1)
        name, cat = item.name, item.cat
        if p.pct > 0 and paid < full then code = p.code end
    end
    MySQL.insert('INSERT INTO boutique_history (identifier, player_name, item_name, category, price, full_price, code) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { xPlayer.identifier, esc(nameOf(xPlayer), 80), esc(name, 100), cat, math.floor(tonumber(paid) or 0), math.floor(tonumber(full) or 0), code })
    log(('%s a acheté « %s » pour %d coins%s'):format(nameOf(xPlayer), name, tonumber(paid) or 0, code and (' (code ' .. code .. ')') or ''))
end)

ESX.RegisterServerCallback('pickax_boutique:history', function(src, cb)
    local xPlayer = playerOf(src)
    if not xPlayer then return cb(fail('Joueur introuvable')) end
    cb({ ok = true, list = MySQL.query.await('SELECT item_name, category, price, full_price, code, UNIX_TIMESTAMP(created_at) AS ts FROM boutique_history WHERE identifier = ? ORDER BY id DESC LIMIT ?',
        { xPlayer.identifier, Config.HistoryLimit }) or {} })
end)

-- ─────────────────────────────── Parrainage / codes ───────────────────────────────
ESX.RegisterServerCallback('pickax_boutique:overview', function(src, cb)
    local xPlayer = playerOf(src)
    if not xPlayer then return cb(fail('Joueur introuvable')) end
    local ref = Settings.referral
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM boutique_referrals WHERE parrain = ?', { xPlayer.identifier }) or 0
    local earned = MySQL.scalar.await('SELECT COALESCE(SUM(parrain_coins), 0) FROM boutique_referrals WHERE parrain = ?', { xPlayer.identifier }) or 0
    local mine = MySQL.single.await('SELECT parrain FROM boutique_referrals WHERE filleul = ?', { xPlayer.identifier })
    cb({ ok = true, referral = { enabled = ref.Enabled, code = refCodeOf(xPlayer), filleulCoins = ref.FilleulCoins, parrainCoins = ref.ParrainCoins, count = count, earned = earned, hasParrain = mine ~= nil } })
end)

ESX.RegisterServerCallback('pickax_boutique:redeem', function(src, cb, code)
    local xPlayer = playerOf(src)
    if not xPlayer then return cb(fail('Joueur introuvable')) end
    code = normCode(code)
    if code == '' then return cb(fail('Saisis un code')) end

    -- code de parrainage : REF-<code boutique du parrain>
    local pid = code:match('^REF%-(%d+)$')
    if pid then
        local ref = Settings.referral
        if not ref.Enabled then return cb(fail('Le parrainage est désactivé')) end
        if refCodeOf(xPlayer) == code then return cb(fail('Tu ne peux pas utiliser ton propre code')) end
        if MySQL.scalar.await('SELECT 1 FROM boutique_referrals WHERE filleul = ?', { xPlayer.identifier }) then return cb(fail('Tu as déjà été parrainé')) end
        local parrain = MySQL.single.await('SELECT identifier FROM users WHERE boutique_id = ?', { tonumber(pid) })
        if not parrain or parrain.identifier == xPlayer.identifier then return cb(fail('Code de parrainage introuvable')) end
        MySQL.insert.await('INSERT INTO boutique_referrals (filleul, parrain, filleul_name, filleul_coins, parrain_coins) VALUES (?, ?, ?, ?, ?)',
            { xPlayer.identifier, parrain.identifier, esc(nameOf(xPlayer), 80), ref.FilleulCoins, ref.ParrainCoins })
        pcall(function() core():BoutiqueGrantCoins(xPlayer.identifier, ref.FilleulCoins) end)
        pcall(function() core():BoutiqueGrantCoins(parrain.identifier, ref.ParrainCoins) end)
        local px = ESX.GetPlayerFromIdentifier(parrain.identifier)
        if px then notify(px.source, ('~g~%s a utilisé ton code de parrainage : +%d coins !'):format(nameOf(xPlayer), ref.ParrainCoins)) end
        log(('Parrainage : %s parrainé par %s (+%d / +%d coins)'):format(nameOf(xPlayer), parrain.identifier, ref.FilleulCoins, ref.ParrainCoins))
        return cb({ ok = true, message = ('Parrainage validé : +%d coins !'):format(ref.FilleulCoins) })
    end

    local row, err = checkCode(code, xPlayer.identifier)
    if not row then return cb(fail(err)) end
    if row.kind ~= 'coins' then return cb(fail('Ce code de réduction s\'utilise dans le panier')) end
    consumeCode(row, xPlayer)
    pcall(function() core():BoutiqueGrantCoins(xPlayer.identifier, row.value) end)
    log(('Code cadeau %s utilisé par %s (+%d coins)'):format(code, nameOf(xPlayer), row.value))
    cb({ ok = true, message = ('Code accepté : +%d coins !'):format(row.value) })
end)

ESX.RegisterServerCallback('pickax_boutique:previewCode', function(src, cb, code)
    local xPlayer = playerOf(src)
    if not xPlayer then return cb(fail('Joueur introuvable')) end
    code = normCode(code)
    local row, err = checkCode(code, xPlayer.identifier)
    if not row then return cb(fail(err)) end
    if row.kind ~= 'percent' then return cb(fail('Ce code offre des coins : utilise l\'onglet « Codes »')) end
    cb({ ok = true, pct = row.value, code = code })
end)

-- ─────────────────────────────── Panier : préparation du paiement ───────────────────────────────
ESX.RegisterServerCallback('pickax_boutique:prepare', function(src, cb, cart, code)
    local xPlayer = playerOf(src)
    if not xPlayer then return cb(fail('Joueur introuvable')) end
    if pending[src] and #pending[src].queue > 0 then return cb(fail('Un paiement est déjà en cours')) end
    if type(cart) ~= 'table' or #cart == 0 then return cb(fail('Panier vide')) end

    local queue, total, count = {}, 0, 0
    for _, line in ipairs(cart) do
        local cat, idx = tostring(line.cat), tonumber(line.idx)
        local qty = math.max(1, math.min(10, math.floor(tonumber(line.qty) or 1)))
        if cat == 'weapon' or cat == 'business' then qty = 1 end
        local ok, item = pcall(function() return core():BoutiqueItem(cat, idx) end)
        if not ok or not item then return cb(fail('Article introuvable dans le panier')) end
        for _ = 1, qty do
            count = count + 1
            if count > Config.MaxCartItems then return cb(fail(('Panier limité à %d articles'):format(Config.MaxCartItems))) end
            queue[#queue + 1] = { cat = cat, idx = idx, name = item.name, price = item.price }
            total = total + item.price
        end
    end

    local pct, row = 0, nil
    code = normCode(code)
    if code ~= '' then
        local err
        row, err = checkCode(code, xPlayer.identifier)
        if not row then return cb(fail(err)) end
        if row.kind ~= 'percent' then return cb(fail('Ce code offre des coins : utilise l\'onglet « Codes »')) end
        pct = row.value
    end

    local final = 0
    for _, it in ipairs(queue) do final = final + priceWithPct(it.price, pct) end
    local okP, points = pcall(function() return core():BoutiquePointsOf(src) end)
    if not okP or (tonumber(points) or 0) < final then return cb(fail('Tu n\'as pas assez de coins')) end

    if row then consumeCode(row, xPlayer) end
    pcall(function() core():SetBoutiqueCoupon(src, pct, #queue, Config.CouponSeconds) end)
    pending[src] = { queue = queue, code = code, pct = pct }
    local out = {}
    for _, it in ipairs(queue) do out[#out + 1] = { cat = it.cat, idx = it.idx, name = it.name } end
    cb({ ok = true, queue = out, total = total, final = final, pct = pct })
end)

RegisterNetEvent('pickax_boutique:done', function()
    local src = source
    pcall(function() core():SetBoutiqueCoupon(src, 0, 0) end)
    pending[src] = nil
end)

AddEventHandler('playerDropped', function() pending[source] = nil end)

-- ─────────────────────────────── Administration ───────────────────────────────
local function adminOnly(src, cb) if isAdmin(src) then return true end cb(fail('Accès refusé')) return false end

ESX.RegisterServerCallback('pickax_boutique:admin:data', function(src, cb)
    if not adminOnly(src, cb) then return end
    cb({ ok = true,
        codes = MySQL.query.await('SELECT id, code, kind, value, max_uses, per_player, uses, active, note, UNIX_TIMESTAMP(expires_at) AS expires FROM boutique_codes ORDER BY id DESC LIMIT 200') or {},
        referral = Settings.referral,
        sales = MySQL.query.await('SELECT player_name, item_name, price, full_price, code, UNIX_TIMESTAMP(created_at) AS ts FROM boutique_history ORDER BY id DESC LIMIT 80') or {},
        referrals = MySQL.query.await('SELECT filleul_name, filleul_coins, parrain_coins, parrain, UNIX_TIMESTAMP(created_at) AS ts FROM boutique_referrals ORDER BY id DESC LIMIT 40') or {},
    })
end)

ESX.RegisterServerCallback('pickax_boutique:admin:saveCode', function(src, cb, d)
    if not adminOnly(src, cb) then return end
    if type(d) ~= 'table' then return cb(fail('Données invalides')) end
    local code = normCode(d.code)
    if code == '' then
        local chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
        for _ = 1, 8 do local i = math.random(#chars) code = code .. chars:sub(i, i) end
    end
    if code:match('^REF%-') then return cb(fail('Le préfixe REF- est réservé au parrainage')) end
    local kind = d.kind == 'coins' and 'coins' or 'percent'
    local value = math.floor(tonumber(d.value) or 0)
    if kind == 'percent' then value = math.max(1, math.min(95, value)) else value = math.max(1, math.min(1000000, value)) end
    local maxUses = math.max(0, math.min(1000000, math.floor(tonumber(d.maxUses) or 0)))
    local perPlayer = math.max(1, math.min(100, math.floor(tonumber(d.perPlayer) or 1)))
    local days = math.floor(tonumber(d.days) or 0)
    local xPlayer = playerOf(src)
    local expr = days > 0 and ('DATE_ADD(NOW(), INTERVAL ' .. math.min(days, 3650) .. ' DAY)') or 'NULL'
    local ok = pcall(function()
        MySQL.insert.await('INSERT INTO boutique_codes (code, kind, value, max_uses, per_player, expires_at, note, created_by) VALUES (?, ?, ?, ?, ?, ' .. expr .. ', ?, ?)',
            { code, kind, value, maxUses, perPlayer, esc(d.note, 120), xPlayer and xPlayer.identifier or '' })
    end)
    if not ok then return cb(fail('Ce code existe déjà')) end
    log(('Code créé : %s (%s %d)'):format(code, kind, value))
    cb({ ok = true, code = code })
end)

ESX.RegisterServerCallback('pickax_boutique:admin:toggleCode', function(src, cb, id)
    if not adminOnly(src, cb) then return end
    MySQL.update.await('UPDATE boutique_codes SET active = 1 - active WHERE id = ?', { tonumber(id) })
    cb({ ok = true })
end)

ESX.RegisterServerCallback('pickax_boutique:admin:deleteCode', function(src, cb, id)
    if not adminOnly(src, cb) then return end
    MySQL.update.await('DELETE FROM boutique_codes WHERE id = ?', { tonumber(id) })
    MySQL.update.await('DELETE FROM boutique_code_uses WHERE code_id = ?', { tonumber(id) })
    cb({ ok = true })
end)

ESX.RegisterServerCallback('pickax_boutique:admin:saveSettings', function(src, cb, d)
    if not adminOnly(src, cb) then return end
    if type(d) ~= 'table' then return cb(fail('Données invalides')) end
    Settings.referral.Enabled = d.Enabled ~= false
    Settings.referral.FilleulCoins = math.max(0, math.min(1000000, math.floor(tonumber(d.FilleulCoins) or 0)))
    Settings.referral.ParrainCoins = math.max(0, math.min(1000000, math.floor(tonumber(d.ParrainCoins) or 0)))
    MySQL.update.await("INSERT INTO boutique_settings (name, value) VALUES ('referral', ?) ON DUPLICATE KEY UPDATE value = VALUES(value)", { json.encode(Settings.referral) })
    cb({ ok = true })
end)
