ESX = exports['es_extended']:getSharedObject()

local function now() return os.time() end
local function fail(m) return { ok = false, error = m } end
local V = Config.Vehicles
local function ident(s) return s and s:match('^[%w_]+$') and s or nil end
local VT, VC = ident(V.Table), {}
for k, c in pairs(V.Cols) do VC[k] = ident(c) end

MySQL.ready(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS pickax_auctions (
        id INT AUTO_INCREMENT PRIMARY KEY, seller VARCHAR(80) NOT NULL, seller_name VARCHAR(60) NOT NULL DEFAULT '',
        kind VARCHAR(10) NOT NULL, item VARCHAR(80) NULL, count INT NOT NULL DEFAULT 1, plate VARCHAR(12) NULL, label VARCHAR(80) NOT NULL DEFAULT '',
        start_price INT NOT NULL, buyout INT NULL, bid INT NOT NULL DEFAULT 0, bidder VARCHAR(80) NULL, bidder_name VARCHAR(60) NULL, bid_account VARCHAR(8) NULL,
        ends_at INT NOT NULL, status VARCHAR(12) NOT NULL DEFAULT 'active', created INT NOT NULL, final_price INT NULL,
        KEY idx_status_end (status, ends_at), KEY idx_seller (seller), KEY idx_bidder (bidder)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS pickax_auction_claims (
        id INT AUTO_INCREMENT PRIMARY KEY, identifier VARCHAR(80) NOT NULL, item VARCHAR(80) NOT NULL, count INT NOT NULL, label VARCHAR(80) NOT NULL DEFAULT '',
        reason VARCHAR(20) NOT NULL DEFAULT 'won', created INT NOT NULL, KEY idx_owner (identifier)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
end)

local function webhook(title, desc)
    if not Config.Webhook or Config.Webhook == '' then return end
    PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode({ username = 'Hôtel des ventes', embeds = { { title = title, description = desc, color = 16630397 } } }), { ['Content-Type'] = 'application/json' })
end

local function notify(identifier, msg, kind)
    local x = ESX.GetPlayerFromIdentifier(identifier)
    if x then TriggerClientEvent('ox_lib:notify', x.source, { title = 'Hôtel des ventes', description = msg, type = kind or 'inform' }) end
end

-- Crédite un compte, même hors ligne
local function credit(identifier, account, amount)
    if amount <= 0 then return end
    account = (account == 'money' or account == 'cash') and 'money' or 'bank'
    local x = ESX.GetPlayerFromIdentifier(identifier)
    if x then x.addAccountMoney(account, amount, 'Hôtel des ventes') return end
    MySQL.update.await(("UPDATE users SET accounts = JSON_SET(accounts, '$.%s', COALESCE(JSON_EXTRACT(accounts, '$.%s'), 0) + ?) WHERE identifier = ?"):format(account, account), { amount, identifier })
end

local function balance(x, account) return x.getAccount(account == 'money' and 'money' or 'bank').money end

-- Anti-spam léger
local last = {}
local function throttle(src, ms) local t = GetGameTimer() if last[src] and t - last[src] < (ms or 600) then return true end last[src] = t return false end
AddEventHandler('playerDropped', function() last[source] = nil end)

local function nameOf(x) return ((x.get and x.get('firstName')) or '') .. ' ' .. ((x.get and x.get('lastName')) or '') end

-- ═════════════════ lecture ═════════════════
local function rowOut(r, me)
    local inc = math.max(Config.MinIncrementFlat, math.floor(r.bid * Config.MinIncrementPct / 100))
    return { id = r.id, kind = r.kind, item = r.item, count = r.count, plate = r.plate, label = r.label, start = r.start_price, buyout = r.buyout, bid = r.bid,
        minBid = r.bid > 0 and (r.bid + inc) or r.start_price, ends = r.ends_at, seller = r.seller_name, mine = r.seller == me, leading = r.bidder == me and r.status == 'active',
        bids = r.bidder ~= nil, status = r.status, final = r.final_price }
end

lib.callback.register('pickax_auction:list', function(src)
    local x = ESX.GetPlayerFromId(src)
    if not x then return fail('Joueur introuvable') end
    local me = x.identifier
    local out = {}
    for _, r in ipairs(MySQL.query.await("SELECT * FROM pickax_auctions WHERE status = 'active' AND ends_at > ? ORDER BY ends_at LIMIT 200", { now() }) or {}) do out[#out + 1] = rowOut(r, me) end
    local mine = {}
    for _, r in ipairs(MySQL.query.await("SELECT * FROM pickax_auctions WHERE seller = ? ORDER BY id DESC LIMIT 25", { me }) or {}) do mine[#mine + 1] = rowOut(r, me) end
    local bids = {}
    for _, r in ipairs(MySQL.query.await("SELECT * FROM pickax_auctions WHERE bidder = ? AND status = 'active' ORDER BY ends_at", { me }) or {}) do bids[#bids + 1] = rowOut(r, me) end
    local claims = MySQL.query.await('SELECT id, item, count, label, reason FROM pickax_auction_claims WHERE identifier = ? ORDER BY id', { me }) or {}
    return { ok = true, now = now(), auctions = out, mine = mine, bids = bids, claims = claims, cash = balance(x, 'money'), bank = balance(x, 'bank'),
        cfg = { durations = Config.Durations, fee = Config.ListingFee, minFee = Config.MinFee, tax = Config.SaleTax, max = Config.MaxListings, vehicles = Config.AllowVehicles, maxPrice = Config.MaxPrice } }
end)

local function blocked(name)
    for _, b in ipairs(Config.BlockedItems) do if b == name then return true end end
    if not Config.AllowWeapons and name:upper():sub(1, 7) == 'WEAPON_' then return true end
    return false
end

lib.callback.register('pickax_auction:inventory', function(src)
    local x = ESX.GetPlayerFromId(src)
    if not x then return fail('Joueur introuvable') end
    local items, byName, order = exports.ox_inventory:Items(), {}, {}
    for _, it in pairs(exports.ox_inventory:GetInventoryItems(src) or {}) do
        if it and it.name and (it.count or 0) > 0 and not blocked(it.name) then
            if not byName[it.name] then byName[it.name] = { name = it.name, label = (items[it.name] and items[it.name].label) or it.label or it.name, count = 0 } order[#order + 1] = it.name end
            byName[it.name].count = byName[it.name].count + it.count
        end
    end
    local list = {}
    for _, n in ipairs(order) do list[#list + 1] = byName[n] end
    table.sort(list, function(a, b) return a.label:lower() < b.label:lower() end)
    local vehicles = {}
    if Config.AllowVehicles and VT then
        local q = ('SELECT `%s` AS plate, `%s` AS name FROM `%s` WHERE `%s` = ? AND `%s` = ?'):format(VC.plate, VC.name or VC.plate, VT, VC.owner, VC.state)
        for _, r in ipairs(MySQL.query.await(q, { x.identifier, V.StoredState }) or {}) do vehicles[#vehicles + 1] = { plate = r.plate, label = (r.name and r.name ~= '') and r.name or r.plate } end
    end
    return { ok = true, items = list, vehicles = vehicles }
end)

-- ═════════════════ création ═════════════════
local function chargeFee(x, fee, account)
    if balance(x, account) < fee then return false end
    x.removeAccountMoney(account == 'money' and 'money' or 'bank', fee, 'Frais de mise en vente')
    return true
end

lib.callback.register('pickax_auction:create', function(src, d)
    if throttle(src, 1200) then return fail('Doucement…') end
    local x = ESX.GetPlayerFromId(src)
    if not x or type(d) ~= 'table' then return fail('Données invalides') end
    local kind = d.kind == 'vehicle' and 'vehicle' or 'item'
    if kind == 'vehicle' and (not Config.AllowVehicles or not VT) then return fail('Les véhicules ne sont pas acceptés') end
    local start = math.floor(tonumber(d.start) or 0)
    if start < 1 or start > Config.MaxPrice then return fail('Prix de départ invalide') end
    local buyout = d.buyout and math.floor(tonumber(d.buyout) or 0) or nil
    if buyout and buyout <= 0 then buyout = nil end
    if buyout and (buyout <= start or buyout > Config.MaxPrice) then return fail('L\'achat immédiat doit dépasser le prix de départ') end
    local okDur = false
    for _, h in ipairs(Config.Durations) do if h == tonumber(d.hours) then okDur = true end end
    if not okDur then return fail('Durée invalide') end
    local active = MySQL.scalar.await("SELECT COUNT(*) FROM pickax_auctions WHERE seller = ? AND status = 'active'", { x.identifier }) or 0
    if active >= Config.MaxListings then return fail(('Maximum %d enchères actives'):format(Config.MaxListings)) end
    local account = d.account == 'money' and 'money' or 'bank'
    local fee = math.max(Config.MinFee, math.floor(start * Config.ListingFee / 100))
    if balance(x, account) < fee then return fail(('Frais de mise en vente : %d $ (solde insuffisant)'):format(fee)) end

    local id, label, item, count, plate
    if kind == 'item' then
        item = tostring(d.item or '')
        count = math.floor(tonumber(d.count) or 0)
        if item == '' or count < 1 or blocked(item) then return fail('Objet invalide') end
        if (exports.ox_inventory:Search(src, 'count', item) or 0) < count then return fail('Tu n\'as pas assez de cet objet') end
        local def = exports.ox_inventory:Items()[item]
        label = def and def.label or item
        if not exports.ox_inventory:RemoveItem(src, item, count) then return fail('Impossible de retirer l\'objet') end
        id = MySQL.insert.await('INSERT INTO pickax_auctions (seller, seller_name, kind, item, count, label, start_price, buyout, ends_at, created) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            { x.identifier, nameOf(x), 'item', item, count, label, start, buyout, now() + tonumber(d.hours) * 3600, now() })
        if not id then exports.ox_inventory:AddItem(src, item, count) return fail('Erreur base de données') end
    else
        plate = tostring(d.plate or '')
        id = MySQL.insert.await('INSERT INTO pickax_auctions (seller, seller_name, kind, plate, count, label, start_price, buyout, ends_at, created, status) VALUES (?, ?, ?, ?, 1, ?, ?, ?, ?, ?, ?)',
            { x.identifier, nameOf(x), 'vehicle', plate, plate, start, buyout, now() + tonumber(d.hours) * 3600, now(), 'pending' })
        if not id then return fail('Erreur base de données') end
        -- le véhicule passe en dépôt (propriétaire = auction:<id>) : introuvable dans le garage pendant la vente
        local upd = MySQL.update.await(('UPDATE `%s` SET `%s` = ? WHERE `%s` = ? AND `%s` = ? AND `%s` = ?'):format(VT, VC.owner, VC.owner, VC.plate, VC.state), { 'auction:' .. id, x.identifier, plate, V.StoredState }) or 0
        if upd ~= 1 then MySQL.update.await('DELETE FROM pickax_auctions WHERE id = ?', { id }) return fail('Ce véhicule n\'est pas disponible (il doit être au garage)') end
        local nm = MySQL.scalar.await(('SELECT `%s` FROM `%s` WHERE `%s` = ? AND `%s` = ?'):format(VC.name or VC.plate, VT, VC.owner, VC.plate), { 'auction:' .. id, plate })
        label = (nm and nm ~= '') and nm or plate
        MySQL.update.await("UPDATE pickax_auctions SET label = ?, status = 'active' WHERE id = ?", { label, id })
    end
    chargeFee(x, fee, account)
    return { ok = true, id = id, fee = fee }
end)

-- ═════════════════ fin d'enchère ═════════════════
local function giveClaim(identifier, item, count, label, reason)
    MySQL.insert.await('INSERT INTO pickax_auction_claims (identifier, item, count, label, reason, created) VALUES (?, ?, ?, ?, ?, ?)', { identifier, item, count, label, reason, now() })
end

local function finalize(id)
    -- on « verrouille » l'enchère : un seul traitement même si deux événements arrivent en même temps
    if (MySQL.update.await("UPDATE pickax_auctions SET status = 'closing' WHERE id = ? AND status = 'active'", { id }) or 0) ~= 1 then return end
    local r = MySQL.single.await('SELECT * FROM pickax_auctions WHERE id = ?', { id })
    if not r then return end
    if r.bidder and r.bid > 0 then
        local tax = math.floor(r.bid * Config.SaleTax / 100)
        credit(r.seller, Config.PayoutAccount, r.bid - tax)
        if r.kind == 'item' then giveClaim(r.bidder, r.item, r.count, r.label, 'won')
        else MySQL.update.await(('UPDATE `%s` SET `%s` = ? WHERE `%s` = ? AND `%s` = ?'):format(VT, VC.owner, VC.owner, VC.plate), { r.bidder, 'auction:' .. id, r.plate }) end
        MySQL.update.await("UPDATE pickax_auctions SET status = 'sold', final_price = ? WHERE id = ?", { r.bid, id })
        notify(r.seller, ('« %s » vendu %d $ (taxe %d $).'):format(r.label, r.bid, tax), 'success')
        notify(r.bidder, ('Tu as remporté « %s » pour %d $.%s'):format(r.label, r.bid, r.kind == 'item' and ' Récupère-le dans Réclamations.' or ' Il t\'attend dans ton garage.'), 'success')
        webhook('Enchère terminée', ('**%s** vendu **%d $** (%s → %s)'):format(r.label, r.bid, r.seller_name, r.bidder_name or '?'))
    else
        if r.kind == 'item' then giveClaim(r.seller, r.item, r.count, r.label, 'unsold')
        else MySQL.update.await(('UPDATE `%s` SET `%s` = ? WHERE `%s` = ? AND `%s` = ?'):format(VT, VC.owner, VC.owner, VC.plate), { r.seller, 'auction:' .. id, r.plate }) end
        MySQL.update.await("UPDATE pickax_auctions SET status = 'expired' WHERE id = ?", { id })
        notify(r.seller, ('« %s » n\'a pas trouvé preneur : récupère-le (Réclamations / garage).'):format(r.label), 'inform')
    end
end

CreateThread(function()
    while true do
        Wait(20000)
        for _, r in ipairs(MySQL.query.await("SELECT id FROM pickax_auctions WHERE status = 'active' AND ends_at <= ?", { now() }) or {}) do finalize(r.id) end
        -- reprise après plantage : enchères restées en « closing » depuis plus de 5 min
        MySQL.update.await("UPDATE pickax_auctions SET status = 'active' WHERE status = 'closing' AND ends_at < ?", { now() - 300 })
    end
end)

-- ═════════════════ enchérir / acheter ═════════════════
lib.callback.register('pickax_auction:bid', function(src, id, amount, account, buyNow)
    if throttle(src, 700) then return fail('Doucement…') end
    local x = ESX.GetPlayerFromId(src)
    id = tonumber(id)
    if not x or not id then return fail('Données invalides') end
    account = account == 'money' and 'money' or 'bank'
    local r = MySQL.single.await("SELECT * FROM pickax_auctions WHERE id = ? AND status = 'active' AND ends_at > ?", { id, now() })
    if not r then return fail('Cette enchère est terminée') end
    if r.seller == x.identifier then return fail('Tu ne peux pas enchérir sur ta propre vente') end
    local inc = math.max(Config.MinIncrementFlat, math.floor(r.bid * Config.MinIncrementPct / 100))
    local minBid = r.bid > 0 and (r.bid + inc) or r.start_price
    amount = math.floor(tonumber(amount) or 0)
    local isBuy = false
    if buyNow then
        if not r.buyout then return fail('Pas d\'achat immédiat sur cette enchère') end
        amount, isBuy = r.buyout, true
    elseif r.buyout and amount >= r.buyout then amount, isBuy = r.buyout, true end
    if amount < minBid and not isBuy then return fail(('Enchère minimale : %d $'):format(minBid)) end
    if isBuy and amount <= r.bid then return fail('Une enchère dépasse déjà le prix d\'achat immédiat') end
    if amount > Config.MaxPrice then return fail('Montant trop élevé') end
    if balance(x, account) < amount then return fail(account == 'money' and 'Pas assez de liquide' or 'Pas assez d\'argent en banque') end
    -- dépôt : l'argent est retiré tout de suite ; compare-and-swap sur l'enchère précédente pour éviter deux gagnants
    x.removeAccountMoney(account, amount, 'Enchère #' .. id)
    local ends = r.ends_at
    if ends - now() < Config.SnipeSeconds then ends = now() + Config.SnipeSeconds end
    local upd = MySQL.update.await("UPDATE pickax_auctions SET bid = ?, bidder = ?, bidder_name = ?, bid_account = ?, ends_at = ? WHERE id = ? AND status = 'active' AND bid = ?",
        { amount, x.identifier, nameOf(x), account, ends, id, r.bid }) or 0
    if upd ~= 1 then x.addAccountMoney(account, amount, 'Enchère annulée') return fail('Quelqu\'un a enchéri avant toi : réessaie') end
    if r.bidder and r.bid > 0 then
        credit(r.bidder, r.bid_account, r.bid)
        notify(r.bidder, ('Tu as été surenchéri sur « %s » (%d $). Ton argent a été rendu.'):format(r.label, amount), 'warning')
    end
    notify(r.seller, ('Nouvelle enchère sur « %s » : %d $'):format(r.label, amount))
    if isBuy then finalize(id) end
    return { ok = true, bought = isBuy, amount = amount }
end)

lib.callback.register('pickax_auction:cancel', function(src, id)
    if throttle(src, 800) then return fail('Doucement…') end
    local x = ESX.GetPlayerFromId(src)
    id = tonumber(id)
    if not x or not id then return fail('Données invalides') end
    local r = MySQL.single.await("SELECT * FROM pickax_auctions WHERE id = ? AND seller = ? AND status = 'active'", { id, x.identifier })
    if not r then return fail('Enchère introuvable') end
    if r.bidder then return fail('Impossible : une enchère a déjà été placée') end
    if (MySQL.update.await("UPDATE pickax_auctions SET status = 'cancelled' WHERE id = ? AND status = 'active' AND bidder IS NULL", { id }) or 0) ~= 1 then return fail('Impossible : une enchère vient d\'être placée') end
    if r.kind == 'item' then giveClaim(x.identifier, r.item, r.count, r.label, 'cancel')
    else MySQL.update.await(('UPDATE `%s` SET `%s` = ? WHERE `%s` = ? AND `%s` = ?'):format(VT, VC.owner, VC.owner, VC.plate), { x.identifier, 'auction:' .. id, r.plate }) end
    return { ok = true }
end)

lib.callback.register('pickax_auction:claim', function(src, id)
    if throttle(src, 600) then return fail('Doucement…') end
    local x = ESX.GetPlayerFromId(src)
    id = tonumber(id)
    if not x or not id then return fail('Données invalides') end
    local c = MySQL.single.await('SELECT * FROM pickax_auction_claims WHERE id = ? AND identifier = ?', { id, x.identifier })
    if not c then return fail('Réclamation introuvable') end
    if not exports.ox_inventory:CanCarryItem(src, c.item, c.count) then return fail('Pas assez de place dans ton inventaire') end
    if (MySQL.update.await('DELETE FROM pickax_auction_claims WHERE id = ?', { id }) or 0) ~= 1 then return fail('Déjà récupéré') end
    if not exports.ox_inventory:AddItem(src, c.item, c.count) then giveClaim(x.identifier, c.item, c.count, c.label, c.reason) return fail('Impossible d\'ajouter l\'objet') end
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
