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
    if (MySQL.scalar.await("SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'boutique_codes' AND column_name = 'owner'") or 0) == 0 then
        MySQL.query.await('ALTER TABLE boutique_codes ADD COLUMN owner VARCHAR(80) NULL')   -- bons personnels (roulette) : réservés à un joueur
    end
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
    if row.owner and row.owner ~= '' and row.owner ~= identifier then return nil, 'Code invalide' end   -- bon personnel d'un autre joueur
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

-- ─────────────────────────────── Boutique du jour ───────────────────────────────
local daily = { key = nil, items = {}, set = {} }
local function dayKey() return os.date('%Y-%m-%d', os.time() - (Config.Daily.ResetHour or 0) * 3600) end
local function hashStr(s) local h = 2166136261 for i = 1, #s do h = ((h ~ s:byte(i)) * 16777619) % 4294967296 end return h end

local function buildDaily()
    local key = dayKey()
    if daily.key == key then return daily end
    local items, set = {}, {}
    if Config.Daily and Config.Daily.Enabled then
        for _, p in ipairs(Config.Daily.Pick or {}) do
            local ok, list = pcall(function() return core():BoutiqueList(p.cat) end)
            if ok and type(list) == 'table' and #list > 0 and (p.count or 0) > 0 then
                local x = hashStr(key .. ':' .. p.cat) % 2147483646 + 1
                local function rnd(n) x = (x * 48271) % 2147483647 return x % n + 1 end       -- tirage déterministe : même résultat pour tout le monde, toute la journée
                for i = #list, 2, -1 do local j = rnd(i) list[i], list[j] = list[j], list[i] end
                for i = 1, math.min(p.count, #list) do
                    items[#items + 1] = { cat = p.cat, idx = list[i].idx }
                    set[p.cat .. ':' .. list[i].idx] = true
                end
            end
        end
    end
    daily = { key = key, items = items, set = set }
    return daily
end

local function dailyPayload()
    local d = buildDaily()
    if #d.items == 0 then return nil end
    local t = os.time()
    local y = os.date('*t', t - (Config.Daily.ResetHour or 0) * 3600)
    local nextT = os.time({ year = y.year, month = y.month, day = y.day + 1, hour = Config.Daily.ResetHour or 0, min = 0, sec = 0 })
    return { items = d.items, discount = math.max(0, math.min(90, tonumber(Config.Daily.Discount) or 0)), endsIn = math.max(60, nextT - t) }
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
        if paid < full then code = (p.pct > 0 and p.code ~= '' and p.code) or (item.daily and 'BOUTIQUE DU JOUR') or nil end
    end
    MySQL.insert('INSERT INTO boutique_history (identifier, player_name, item_name, category, price, full_price, code) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { xPlayer.identifier, esc(nameOf(xPlayer), 80), esc(name, 100), cat or '', math.floor(tonumber(paid) or 0), math.floor(tonumber(full) or 0), code or '' })   -- jamais de nil : un nil final/au milieu fait perdre un paramètre à oxmysql
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
        if cat == 'weapon' or cat == 'business' or cat == 'vip' then qty = 1 end
        local ok, item = pcall(function() return core():BoutiqueItem(cat, idx) end)
        if not ok or not item then return cb(fail('Article introuvable dans le panier')) end
        for _ = 1, qty do
            count = count + 1
            if count > Config.MaxCartItems then return cb(fail(('Panier limité à %d articles'):format(Config.MaxCartItems))) end
            queue[#queue + 1] = { cat = cat, idx = idx, name = item.name, price = item.price, daily = buildDaily().set[cat .. ':' .. idx] == true }
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

    local dpct = math.max(0, math.min(90, tonumber(Config.Daily and Config.Daily.Discount) or 0))
    local final = 0
    for _, it in ipairs(queue) do
        -- remise de la boutique du jour puis code promo, cumulées (calculées ici, jamais fournies par le client)
        it.pct = it.daily and (100 - (100 - dpct) * (100 - pct) / 100) or pct
        final = final + priceWithPct(it.price, it.pct)
    end
    local okP, points = pcall(function() return core():BoutiquePointsOf(src) end)
    if not okP or (tonumber(points) or 0) < final then return cb(fail('Tu n\'as pas assez de coins')) end

    if row then consumeCode(row, xPlayer) end
    local all = {}
    for i, it in ipairs(queue) do all[i] = it end
    pending[src] = { queue = queue, all = all, armed = 0, code = code, pct = pct }
    local out = {}
    for _, it in ipairs(queue) do out[#out + 1] = { cat = it.cat, idx = it.idx, name = it.name } end
    cb({ ok = true, queue = out, total = total, final = final, pct = pct })
end)

-- Avant chaque article, le client demande d'appliquer la remise de CET article (dans l'ordre uniquement) : le pourcentage vient du serveur
RegisterNetEvent('pickax_boutique:arm', function(i)
    local src = source
    local p, n = pending[src], tonumber(i)
    if not p or not n or n ~= p.armed + 1 or not p.all[n] then return end
    p.armed = n
    pcall(function() core():SetBoutiqueCoupon(src, p.all[n].pct, 1, Config.CouponSeconds) end)
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
        codes = MySQL.query.await('SELECT id, code, kind, value, max_uses, per_player, uses, active, note, UNIX_TIMESTAMP(expires_at) AS expires FROM boutique_codes WHERE owner IS NULL ORDER BY id DESC LIMIT 200') or {},
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


-- Give de coins à tous les joueurs actuellement connectés
ESX.RegisterServerCallback('pickax_boutique:admin:giveAll', function(src, cb, d)
    if not adminOnly(src, cb) then return end
    d = type(d) == 'table' and d or {}
    local amount = math.floor(tonumber(d.amount) or 0)
    if amount < 1 or amount > 1000000 then return cb(fail('Montant invalide (1 à 1 000 000)')) end
    local reason = esc(d.reason, 60)
    local given, label = 0, ('+%d coins (cadeau%s)'):format(amount, reason ~= '' and (' : ' .. reason) or '')
    for _, id in ipairs(GetPlayers()) do
        local xTarget = ESX.GetPlayerFromId(tonumber(id))
        if xTarget and exports['pickax_core']:BoutiqueGrantCoins(xTarget.identifier, amount) then
            given = given + 1
            MySQL.insert('INSERT INTO boutique_history (identifier, player_name, item_name, category, price, full_price) VALUES (?, ?, ?, ?, 0, 0)',
                { xTarget.identifier, esc(nameOf(xTarget), 80), label, 'gift' })
            TriggerClientEvent('esx:showNotification', xTarget.source, ('~g~Cadeau du serveur !~s~ +%d coins%s'):format(amount, reason ~= '' and (' (' .. reason .. ')') or ''))
        end
    end
    log(('%s a donné %d coins à %d joueur(s) en ligne%s'):format(GetPlayerName(src), amount, given, reason ~= '' and (' — ' .. reason) or ''))
    cb({ ok = true, given = given })
end)

-- ─────────────────────────────── Tebex ───────────────────────────────
-- pickax_tebex <cible> <coins> [transaction]   (console / Tebex uniquement)
--   cible : ID serveur d'un joueur en ligne (Tebex {id})  ou  b<ID boutique> (joueur en ligne ou non)
CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS boutique_tebex (
        transaction_id VARCHAR(64) NOT NULL, identifier VARCHAR(80) NOT NULL, coins INT NOT NULL DEFAULT 0,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (transaction_id, identifier, coins)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
end)

RegisterCommand((Config.Tebex and Config.Tebex.Command) or 'pickax_tebex', function(src, args)
    if src ~= 0 then return end                                        -- jamais utilisable par un joueur
    local target, coins, tx = tostring(args[1] or ''), math.floor(tonumber(args[2]) or 0), args[3] and esc(args[3], 64) or nil
    if target == '' or coins <= 0 or coins > 10000000 then print('^1[pickax_boutique] Tebex : usage  pickax_tebex <id|bID> <coins> [transaction]^7') return end

    local identifier, name, online
    local bid = target:match('^[bB](%d+)$')
    if bid then
        local row = MySQL.single.await('SELECT identifier FROM users WHERE boutique_id = ?', { tonumber(bid) })
        identifier = row and row.identifier
    else
        local xPlayer = ESX.GetPlayerFromId(tonumber(target))
        if xPlayer then identifier, name, online = xPlayer.identifier, nameOf(xPlayer), xPlayer.source end
    end
    if not identifier then print(('^1[pickax_boutique] Tebex : joueur introuvable (%s) — commande à rejouer depuis Tebex quand il est connecté^7'):format(target)) return end

    if tx and MySQL.scalar.await('SELECT 1 FROM boutique_tebex WHERE transaction_id = ? AND identifier = ? AND coins = ?', { tx, identifier, coins }) then
        print(('^3[pickax_boutique] Tebex : transaction %s déjà créditée, ignorée^7'):format(tx)) return
    end
    local total = coins + math.floor(coins * ((Config.Tebex and tonumber(Config.Tebex.BonusPct)) or 0) / 100)
    if not exports['pickax_core']:BoutiqueGrantCoins(identifier, total) then print('^1[pickax_boutique] Tebex : crédit refusé (joueur absent du cache boutique)^7') return end
    if tx then MySQL.insert('INSERT IGNORE INTO boutique_tebex (transaction_id, identifier, coins) VALUES (?, ?, ?)', { tx, identifier, coins }) end

    name = name or identifier
    MySQL.insert('INSERT INTO boutique_history (identifier, player_name, item_name, category, price, full_price) VALUES (?, ?, ?, ?, 0, 0)',
        { identifier, esc(name, 80), ('+%d coins (achat Tebex)'):format(total), 'tebex' })
    if online then TriggerClientEvent('esx:showNotification', online, ('~g~Merci pour ton achat !~s~ +%d coins ajoutés à ta boutique.'):format(total)) end
    log(('Tebex : %s reçoit %d coins%s'):format(name, total, tx and (' (transaction ' .. tx .. ')') or ''))
    print(('^2[pickax_boutique] Tebex : +%d coins pour %s^7'):format(total, name))
end, true)


-- ─────────────────────────────── Code boutique & descriptifs des articles ───────────────────────────────
local DESC_CATS = { vehicle = true, moto = true, other = true, weapon = true, crate = true, pack = true, vip = true, business = true }
CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS boutique_descriptions (
        cat VARCHAR(16) NOT NULL, item_key VARCHAR(100) NOT NULL, description TEXT NOT NULL, updated_by VARCHAR(80) NULL,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, PRIMARY KEY (cat, item_key)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
end)

local function canEditDesc(src)
    local x = playerOf(src)
    if not x then return false end
    local g = x.getGroup and x.getGroup()
    return Config.DescGroups ~= nil and g ~= nil and Config.DescGroups[g] == true
end

-- Code boutique unique du joueur : la colonne users.boutique_id est unique (auto-incrément) ; on la relit en base si elle est vide côté jeu
local function boutiqueIdOf(xPlayer)
    local id = tonumber(xPlayer.boutique_id) or 0
    if id > 0 then return id end
    local row = MySQL.single.await('SELECT boutique_id FROM users WHERE identifier = ?', { xPlayer.identifier })
    id = row and tonumber(row.boutique_id) or 0
    if id > 0 then xPlayer.boutique_id = id end
    return id > 0 and id or nil
end

-- ─────────────────────────────── Roulette du jour ───────────────────────────────
-- Le tirage et les gains se font UNIQUEMENT ici (le client ne reçoit que le numéro de la part gagnante).
CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS boutique_wheel (
        identifier VARCHAR(80) NOT NULL PRIMARY KEY, last_day VARCHAR(10) NOT NULL DEFAULT '', spins_today INT NOT NULL DEFAULT 0,
        total INT NOT NULL DEFAULT 0, last_prize VARCHAR(120) NULL, last_at TIMESTAMP NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
end)
math.randomseed(os.time() + GetGameTimer())

local WHEEL_COLORS = { '#3fb950', '#e5a23c', '#4aa8ff', '#c77dff', '#ff6b6b', '#2ec4b6', '#ffd166', '#8d99ae', '#ef476f', '#06d6a0', '#118ab2', '#f78c6b' }
local KINDS = { coins = true, money = true, item = true, discount = true, none = true }
local function wheelCfg()
    local W = {}
    for k, v in pairs(Config.Wheel or {}) do W[k] = v end
    if GetResourceState('pickax_panel') ~= 'missing' then
        local raw = LoadResourceFile('pickax_panel', 'cache_boutique.json')
        if raw and raw ~= '' then
            local ok, d = pcall(json.decode, raw)
            if ok and type(d) == 'table' and type(d.wheel) == 'table' then
                local w = d.wheel
                if w.enabled ~= nil then W.Enabled = w.enabled == true end
                if tonumber(w.spins) then W.DailySpins = tonumber(w.spins) end
                if tonumber(w.resetHour) then W.ResetHour = tonumber(w.resetHour) end
                if w.account == 'bank' or w.account == 'money' then W.Account = w.account end
                if type(w.prizes) == 'table' and #w.prizes >= 2 then W.Prizes = w.prizes end
            end
        end
    end
    return W
end
local function wheelPrizes(W)
    local out, total = {}, 0
    for i, p in ipairs(type(W.Prizes) == 'table' and W.Prizes or {}) do
        if #out >= 12 then break end
        local kind = KINDS[p.kind] and p.kind or 'none'
        local wgt = tonumber(p.weight) or 0
        if type(p.label) == 'string' and p.label ~= '' and wgt > 0 then
            local amount = math.floor(tonumber(p.amount) or 0)
            if kind == 'coins' then amount = math.max(0, math.min(amount, 100000)) elseif kind == 'money' then amount = math.max(0, math.min(amount, 5000000)) elseif kind == 'item' then amount = math.max(1, math.min(amount, 1000)) elseif kind == 'discount' then amount = math.max(1, math.min(amount, 90)) end
            local color = type(p.color) == 'string' and p.color:match('^#%x%x%x%x%x%x$') or WHEEL_COLORS[(#out % #WHEEL_COLORS) + 1]
            out[#out + 1] = { label = esc(p.label, 40), kind = kind, amount = amount, hours = math.max(1, math.min(720, math.floor(tonumber(p.hours) or 48))), item = type(p.item) == 'string' and p.item:match('^[%w_%-]+$') or nil, weight = wgt, color = color }
            total = total + wgt
        end
    end
    for _, p in ipairs(out) do p.pct = math.floor(p.weight / total * 1000 + 0.5) / 10 end
    return out, total
end
local function wheelDay(W) return os.date('%Y-%m-%d', os.time() - (tonumber(W.ResetHour) or 0) * 3600) end
local function wheelNext(W)
    local h = tonumber(W.ResetHour) or 0
    local y = os.date('*t', os.time() - h * 3600)
    return math.max(0, os.time({ year = y.year, month = y.month, day = y.day + 1, hour = h, min = 0, sec = 0 }) - os.time())
end
local function wheelState(W, identifier)
    local row = MySQL.single.await('SELECT last_day, spins_today, last_prize, UNIX_TIMESTAMP(last_at) AS ts FROM boutique_wheel WHERE identifier = ?', { identifier })
    local allowed = math.max(1, math.min(10, math.floor(tonumber(W.DailySpins) or 1)))
    local used = (row and row.last_day == wheelDay(W)) and (tonumber(row.spins_today) or 0) or 0
    return { spins = allowed, left = math.max(0, allowed - used), last = row and row.last_prize and { label = row.last_prize, ts = row.ts } or nil }
end
local function wheelPublic(prizes)
    local o = {}
    for i, p in ipairs(prizes) do o[i] = { label = p.label, kind = p.kind, amount = p.amount, color = p.color, pct = p.pct, hours = p.kind == 'discount' and p.hours or nil } end
    return o
end

ESX.RegisterServerCallback('pickax_boutique:wheel:info', function(src, cb)
    local W, xPlayer = wheelCfg(), playerOf(src)
    if not xPlayer then return cb(fail('Joueur introuvable')) end
    local prizes = wheelPrizes(W)
    if W.Enabled == false or #prizes < 2 then return cb({ ok = true, enabled = false }) end
    local st = wheelState(W, xPlayer.identifier)
    local coupons = MySQL.query.await("SELECT code, value, UNIX_TIMESTAMP(expires_at) - UNIX_TIMESTAMP() AS secs FROM boutique_codes WHERE owner = ? AND active = 1 AND kind = 'percent' AND uses < max_uses AND (expires_at IS NULL OR expires_at > NOW()) ORDER BY value DESC LIMIT 10", { xPlayer.identifier }) or {}
    cb({ ok = true, enabled = true, prizes = wheelPublic(prizes), spins = st.spins, left = st.left, next = wheelNext(W), last = st.last, coupons = coupons })
end)

local spinning = {}
local function wheelAward(src, xPlayer, p, W)
    if p.kind == 'none' or p.amount <= 0 and p.kind ~= 'item' and p.kind ~= 'discount' then return true end
    if p.kind == 'coins' then
        if not exports['pickax_core']:BoutiqueGrantCoins(xPlayer.identifier, p.amount) then return false, 'Ton compte boutique n\'est pas encore prêt : réessaie dans un instant.' end
        return true
    elseif p.kind == 'money' then
        xPlayer.addAccountMoney(W.Account == 'bank' and 'bank' or 'money', p.amount, 'Roulette boutique')
        return true
    elseif p.kind == 'discount' then
        -- bon de réduction personnel : un code à usage unique, valable quelques heures, utilisable seulement par ce joueur
        local alphabet, code = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789', nil
        for _ = 1, 8 do
            local c = 'ROUE-'
            for _ = 1, 6 do local k = math.random(1, #alphabet) c = c .. alphabet:sub(k, k) end
            if not MySQL.scalar.await('SELECT 1 FROM boutique_codes WHERE code = ?', { c }) then code = c break end
        end
        if not code then return false, 'Impossible de créer ton bon pour le moment : réessaie.' end
        MySQL.insert.await('INSERT INTO boutique_codes (code, kind, value, max_uses, per_player, expires_at, note, created_by, owner) VALUES (?, ?, ?, 1, 1, DATE_ADD(NOW(), INTERVAL ? HOUR), ?, ?, ?)',
            { code, 'percent', p.amount, p.hours, 'Roulette du jour', 'roulette', xPlayer.identifier })
        return true, nil, code
    elseif p.kind == 'item' and p.item then
        if GetResourceState('ox_inventory') == 'started' then
            if not exports.ox_inventory:CanCarryItem(src, p.item, p.amount) then return false, 'Ton inventaire est plein : fais de la place puis retente ta chance.' end
            if not exports.ox_inventory:AddItem(src, p.item, p.amount) then return false, 'Objet indisponible : préviens le staff.' end
        else
            if xPlayer.canCarryItem and not xPlayer.canCarryItem(p.item, p.amount) then return false, 'Ton inventaire est plein : fais de la place puis retente ta chance.' end
            xPlayer.addInventoryItem(p.item, p.amount)
        end
        return true
    end
    return true
end

ESX.RegisterServerCallback('pickax_boutique:wheel:spin', function(src, cb)
    local xPlayer = playerOf(src)
    if not xPlayer then return cb(fail('Joueur introuvable')) end
    if spinning[src] then return cb(fail('Patiente un instant…')) end
    spinning[src] = true
    local done, ok, err = false, pcall(function()
        local W = wheelCfg()
        local prizes, total = wheelPrizes(W)
        if W.Enabled == false or #prizes < 2 then return cb(fail('La roulette est désactivée.')) end
        local st = wheelState(W, xPlayer.identifier)
        if st.left <= 0 then return cb(fail('Tu as déjà tourné la roue aujourd\'hui : reviens demain !')) end
        local r, idx = math.random() * total, #prizes
        for i, p in ipairs(prizes) do r = r - p.weight if r <= 0 then idx = i break end end
        local p = prizes[idx]
        local given, why, code = wheelAward(src, xPlayer, p, W)
        if not given then return cb(fail(why or 'Gain impossible')) end
        MySQL.update.await([[INSERT INTO boutique_wheel (identifier, last_day, spins_today, total, last_prize, last_at) VALUES (?, ?, 1, 1, ?, NOW())
            ON DUPLICATE KEY UPDATE spins_today = IF(last_day = VALUES(last_day), spins_today + 1, 1), last_day = VALUES(last_day), total = total + 1, last_prize = VALUES(last_prize), last_at = NOW()]],
            { xPlayer.identifier, wheelDay(W), p.label })
        MySQL.insert('INSERT INTO boutique_history (identifier, player_name, item_name, category, price, full_price, code) VALUES (?, ?, ?, ?, 0, 0, ?)',
            { xPlayer.identifier, esc(nameOf(xPlayer), 80), esc('Roulette : ' .. p.label, 100), 'roulette', '' })
        log(('%s a tourné la roulette : %s'):format(nameOf(xPlayer), p.label))
        done = true
        cb({ ok = true, index = idx, prize = { label = p.label, kind = p.kind, amount = p.amount, hours = p.kind == 'discount' and p.hours or nil, code = code }, left = st.left - 1, next = wheelNext(W) })
    end)
    spinning[src] = nil
    if not ok and not done then print('^1[pickax_boutique] roulette : ' .. tostring(err) .. '^7') cb(fail('Erreur de la roulette : réessaie.')) end
end)
AddEventHandler('playerDropped', function() spinning[source] = nil end)

ESX.RegisterServerCallback('pickax_boutique:descs', function(src, cb)
    local xPlayer = playerOf(src)
    local map = {}
    for _, r in ipairs(MySQL.query.await('SELECT cat, item_key, description FROM boutique_descriptions') or {}) do map[r.cat .. '|' .. r.item_key] = r.description end
    local wheel
    if xPlayer then
        local W = wheelCfg()
        local prizes = wheelPrizes(W)
        if W.Enabled ~= false and #prizes >= 2 then wheel = { left = wheelState(W, xPlayer.identifier).left } end
    end
    cb({ ok = true, map = map, daily = dailyPayload(), dev = canEditDesc(src), boutiqueId = xPlayer and boutiqueIdOf(xPlayer) or nil, wheel = wheel })
end)

ESX.RegisterServerCallback('pickax_boutique:saveDesc', function(src, cb, d)
    if not canEditDesc(src) then return cb(fail('Réservé aux administrateurs (_dev)')) end
    if type(d) ~= 'table' or not DESC_CATS[d.cat] then return cb(fail('Article invalide')) end
    local key, text = esc(d.key, 100), tostring(d.text or ''):gsub('\r', ''):gsub('[\0-\8\11\12\14-\31]', ''):sub(1, 800)
    if key == '' then return cb(fail('Article invalide')) end
    local xPlayer = playerOf(src)
    if text:gsub('%s', '') == '' then
        MySQL.update.await('DELETE FROM boutique_descriptions WHERE cat = ? AND item_key = ?', { d.cat, key })
    else
        MySQL.update.await('INSERT INTO boutique_descriptions (cat, item_key, description, updated_by) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE description = VALUES(description), updated_by = VALUES(updated_by)',
            { d.cat, key, text, xPlayer and xPlayer.identifier or 'console' })
    end
    log(('%s a modifié le descriptif de « %s » (%s)'):format(GetPlayerName(src), key, d.cat))
    cb({ ok = true })
end)
