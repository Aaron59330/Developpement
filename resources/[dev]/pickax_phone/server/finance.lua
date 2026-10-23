-- Banque, factures, crypto, annonces (marché), mails
local function logTx(identifier, kind, amount, other, label)
    MySQL.insert('INSERT INTO aero_bank_tx (identifier, kind, amount, other, label, created) VALUES (?,?,?,?,?,?)', { identifier, kind, amount, other and Aura.Clamp(other, 80) or nil, label and Aura.Clamp(label, 120) or nil, Aura.Now() })
end
Aura.LogTx = logTx

local function balanceOf(src) return Bridge.Money(src, 'bank'), Bridge.Money(src, 'cash') end
function Aura.CreditBank(identifier, amount, reason)
    local src = Aura.src[identifier]
    if src then return Bridge.AddMoney(src, 'bank', amount, reason) end
    return Bridge.AddMoneyOffline(identifier, 'bank', amount)
end

lib.callback.register('aura:bank', function(src)
    local id = Aura.ident[src]; if not id then return nil end
    local bank, cash = balanceOf(src)
    local tx = MySQL.query.await('SELECT id, kind, amount, other, label, created FROM aero_bank_tx WHERE identifier = ? ORDER BY id DESC LIMIT ?', { id, Config.Bank.historyLimit }) or {}
    local bills = MySQL.query.await("SELECT id, issuer, society, amount, reason, status, created FROM aero_bills WHERE identifier = ? AND status = 'open' ORDER BY id DESC", { id }) or {}
    return { bank = bank, cash = cash, tx = tx, bills = bills, max = Config.Bank.maxTransfer, fee = Config.Bank.transferFee }
end)

lib.callback.register('aura:bankTransfer', function(src, number, amount, label)
    local id = Aura.ident[src]; local me = id and Aura.phones[id]
    if not me then return { ok = false, error = 'Indisponible' } end
    amount = math.floor(tonumber(amount) or 0)
    number = Aura.CleanNumber(number)
    if amount < 1 then return { ok = false, error = 'Montant invalide' } end
    if amount > Config.Bank.maxTransfer then return { ok = false, error = 'Montant maximal dépassé' } end
    local tid = Aura.byNumber[number]
    if not tid or tid == id then return { ok = false, error = 'Destinataire introuvable' } end
    local fee = math.floor(amount * (Config.Bank.transferFee or 0) / 100)
    if Bridge.Money(src, 'bank') < amount + fee then return { ok = false, error = 'Solde insuffisant' } end
    if not Bridge.RemoveMoney(src, 'bank', amount + fee, 'Aura : virement') then return { ok = false, error = 'Virement refusé' } end
    Aura.CreditBank(tid, amount, 'Aura : virement reçu')
    label = Aura.Clamp(label, 100)
    local myName = Aura.Name(id)
    logTx(id, 'out', -(amount + fee), Aura.FormatNumber(number), label ~= '' and label or 'Virement')
    logTx(tid, 'in', amount, Aura.FormatNumber(me.number), label ~= '' and label or ('Virement de ' .. myName))
    Aura.Push(tid, 'notify', { app = 'bank', title = 'Virement reçu', body = ('%s vous a envoyé %s $'):format(myName, amount) })
    local bank, cash = balanceOf(src)
    return { ok = true, bank = bank, cash = cash }
end)

lib.callback.register('aura:billPay', function(src, bid)
    local id = Aura.ident[src]; if not id then return { ok = false } end
    local b = MySQL.single.await("SELECT id, issuer, society, amount, reason FROM aero_bills WHERE id = ? AND identifier = ? AND status = 'open'", { tonumber(bid) or 0, id })
    if not b then return { ok = false, error = 'Facture introuvable' } end
    if Bridge.Money(src, 'bank') < b.amount then return { ok = false, error = 'Solde insuffisant' } end
    if not Bridge.RemoveMoney(src, 'bank', b.amount, 'Aura : facture') then return { ok = false, error = 'Paiement refusé' } end
    MySQL.update.await("UPDATE aero_bills SET status = 'paid' WHERE id = ?", { b.id })
    if b.society and b.society ~= '' then Bridge.SocietyAdd(b.society, b.amount, b.reason or 'Facture') end
    logTx(id, 'bill', -b.amount, b.issuer, b.reason)
    local bank, cash = balanceOf(src)
    return { ok = true, bank = bank, cash = cash }
end)

lib.callback.register('aura:billDecline', function(src, bid)
    local id = Aura.ident[src]; if not id then return false end
    MySQL.update.await("UPDATE aero_bills SET status = 'declined' WHERE id = ? AND identifier = ? AND status = 'open'", { tonumber(bid) or 0, id })
    return true
end)

-- Création d'une facture (utilisable par d'autres scripts : exports.pickax_phone:CreateBill)
function Aura.CreateBill(identifier, issuer, amount, reason, society)
    amount = tonumber(amount) or 0
    if amount <= 0 or not identifier then return false end
    local bid = MySQL.insert.await('INSERT INTO aero_bills (identifier, issuer, society, amount, reason, status, created) VALUES (?,?,?,?,?, "open", ?)',
        { identifier, Aura.Clamp(issuer, 80), society, amount, Aura.Clamp(reason, 200), Aura.Now() })
    Aura.Push(identifier, 'notify', { app = 'bank', title = 'Nouvelle facture', body = ('%s — %s $'):format(issuer, amount) })
    Aura.SendMailTo(identifier, Aura.Clamp(issuer, 60) .. ' <factures@' .. Config.MailDomain .. '>', 'Facture de ' .. amount .. ' $', (reason or '') .. '\n\nMontant : ' .. amount .. ' $\nÀ régler depuis l\'application Banque.')
    return bid
end

-- ═════════════════ CRYPTO ═════════════════
local coins, prices, history = {}, {}, {}
CreateThread(function()
    if not Config.Crypto.enabled then return end
    for _, c in ipairs(Config.Crypto.coins) do
        coins[c.id] = c
        local r = MySQL.single.await('SELECT price, history FROM aero_crypto_prices WHERE coin = ?', { c.id })
        prices[c.id] = r and r.price or c.price
        history[c.id] = r and Aura.Unjson(r.history, {}) or {}
        if #history[c.id] == 0 then for i = 1, 40 do history[c.id][i] = prices[c.id] * (1 + (math.random() - .5) * .05) end end
    end
    while true do
        Wait(Config.Crypto.tickEvery * 1000)
        for id, c in pairs(coins) do
            local drift = (c.price - prices[id]) / c.price * 0.05     -- rappel vers le cours de base
            local move = (math.random() * 2 - 1) * Config.Crypto.volatility + drift
            prices[id] = math.max(c.price * 0.15, prices[id] * (1 + move))
            local h = history[id]; h[#h + 1] = prices[id]; while #h > 60 do table.remove(h, 1) end
            MySQL.query('INSERT INTO aero_crypto_prices (coin, price, history) VALUES (?,?,?) ON DUPLICATE KEY UPDATE price = VALUES(price), history = VALUES(history)', { id, prices[id], Aura.Json(h) })
        end
    end
end)

lib.callback.register('aura:crypto', function(src)
    local id = Aura.ident[src]; if not id or not Config.Crypto.enabled then return nil end
    local hold = MySQL.query.await('SELECT coin, amount, invested FROM aero_crypto WHERE identifier = ? AND amount > 0', { id }) or {}
    local list = {}
    for cid, c in pairs(coins) do
        local h = history[cid]
        list[#list + 1] = { id = cid, name = c.name, color = c.color, price = prices[cid], history = h, change = h[1] and (prices[cid] - h[1]) / h[1] * 100 or 0 }
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    local bank = balanceOf(src)
    return { coins = list, holdings = hold, bank = bank, fee = Config.Crypto.fee }
end)

lib.callback.register('aura:cryptoTrade', function(src, coin, side, value, mode)
    local id = Aura.ident[src]; if not id or not coins[coin] then return { ok = false } end
    local price = prices[coin]
    value = tonumber(value) or 0
    if value <= 0 then return { ok = false, error = 'Montant invalide' } end
    local feeRate = Config.Crypto.fee / 100
    if side == 'buy' then
        local fiat = mode == 'units' and value * price or value
        fiat = math.floor(fiat * 100) / 100
        if fiat < 1 then return { ok = false, error = 'Minimum 1 $' } end
        if Bridge.Money(src, 'bank') < math.ceil(fiat) then return { ok = false, error = 'Solde insuffisant' } end
        local units = (fiat * (1 - feeRate)) / price
        if not Bridge.RemoveMoney(src, 'bank', math.ceil(fiat), 'Aura : achat crypto') then return { ok = false, error = 'Ordre refusé' } end
        MySQL.query.await('INSERT INTO aero_crypto (identifier, coin, amount, invested) VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE amount = amount + VALUES(amount), invested = invested + VALUES(invested)', { id, coin, units, fiat })
        logTx(id, 'crypto', -math.ceil(fiat), coin, ('Achat %s'):format(coin))
    elseif side == 'sell' then
        local units = mode == 'fiat' and value / price or value
        local row = MySQL.single.await('SELECT amount, invested FROM aero_crypto WHERE identifier = ? AND coin = ?', { id, coin })
        if not row or row.amount + 1e-9 < units then return { ok = false, error = 'Quantité insuffisante' } end
        local fiat = units * price * (1 - feeRate)
        local ratio = units / row.amount
        MySQL.update.await('UPDATE aero_crypto SET amount = amount - ?, invested = invested * (1 - ?) WHERE identifier = ? AND coin = ?', { units, ratio, id, coin })
        Bridge.AddMoney(src, 'bank', math.floor(fiat), 'Aura : vente crypto')
        logTx(id, 'crypto', math.floor(fiat), coin, ('Vente %s'):format(coin))
    else return { ok = false } end
    return { ok = true }
end)

-- ═════════════════ ANNONCES ═════════════════
lib.callback.register('aura:marketList', function(src, category, search, before)
    local id = Aura.ident[src]; if not id then return {} end
    local cond, args = 'sold = 0', {}
    if category and category ~= '' and category ~= 'all' then cond = cond .. ' AND category = ?'; args[#args + 1] = category end
    if search and #tostring(search) > 0 then cond = cond .. ' AND (title LIKE ? OR descr LIKE ?)'; local s = '%' .. tostring(search):gsub('[%%_]', '') .. '%'; args[#args + 1] = s; args[#args + 1] = s end
    if before and tonumber(before) then cond = cond .. ' AND id < ?'; args[#args + 1] = tonumber(before) end
    local rows = MySQL.query.await('SELECT id, number, seller, title, descr, price, category, images, created, (identifier = ?) AS mine FROM aero_market WHERE ' .. cond .. ' ORDER BY id DESC LIMIT 30', (function() local a = { id } for _, v in ipairs(args) do a[#a + 1] = v end return a end)()) or {}
    for _, r in ipairs(rows) do r.images = Aura.Unjson(r.images, {}); r.mine = r.mine == 1 or r.mine == true end
    return rows
end)

lib.callback.register('aura:marketMine', function(src)
    local id = Aura.ident[src]; if not id then return {} end
    local rows = MySQL.query.await('SELECT id, number, seller, title, descr, price, category, images, sold, created FROM aero_market WHERE identifier = ? ORDER BY id DESC', { id }) or {}
    for _, r in ipairs(rows) do r.images = Aura.Unjson(r.images, {}); r.mine = true end
    return rows
end)

lib.callback.register('aura:marketCreate', function(src, d)
    local id = Aura.ident[src]; local p = id and Aura.phones[id]
    if not p or type(d) ~= 'table' then return false end
    local title = Aura.Clamp(Aura.Trim(d.title), 80); if title == '' then return false, 'Titre requis' end
    local cat = tostring(d.category or '')
    local okc = false
    for _, c in ipairs(Config.Market.categories) do if c == cat then okc = true end end
    if not okc then cat = Config.Market.categories[#Config.Market.categories] end
    local n = MySQL.scalar.await('SELECT COUNT(*) FROM aero_market WHERE identifier = ? AND sold = 0', { id }) or 0
    if n >= Config.Market.maxActive then return false, 'Limite d\'annonces atteinte' end
    if Config.Market.fee > 0 then
        if not Bridge.RemoveMoney(src, 'bank', Config.Market.fee, 'Aura : annonce') then return false, 'Frais de publication insuffisants' end
    end
    local imgs = {}
    for _, u in ipairs(d.images or {}) do if type(u) == 'string' and u:match('^https?://') and #imgs < Config.Market.maxImages then imgs[#imgs + 1] = Aura.Clamp(u, 500) end end
    return MySQL.insert.await('INSERT INTO aero_market (identifier, number, seller, title, descr, price, category, images, created) VALUES (?,?,?,?,?,?,?,?,?)',
        { id, p.number, Aura.Name(id), title, Aura.Clamp(d.descr, 800), math.max(0, tonumber(d.price) or 0), cat, Aura.Json(imgs), Aura.Now() })
end)

lib.callback.register('aura:marketUpdate', function(src, mid, patch)
    local id = Aura.ident[src]; if not id then return false end
    if patch and patch.sold ~= nil then MySQL.update.await('UPDATE aero_market SET sold = ? WHERE id = ? AND identifier = ?', { patch.sold and 1 or 0, tonumber(mid) or 0, id }) end
    if patch and patch.price then MySQL.update.await('UPDATE aero_market SET price = ? WHERE id = ? AND identifier = ?', { math.max(0, tonumber(patch.price) or 0), tonumber(mid) or 0, id }) end
    return true
end)

lib.callback.register('aura:marketDelete', function(src, mid)
    local id = Aura.ident[src]; if not id then return false end
    if Aura.IsAdmin(src) then MySQL.update.await('DELETE FROM aero_market WHERE id = ?', { tonumber(mid) or 0 })
    else MySQL.update.await('DELETE FROM aero_market WHERE id = ? AND identifier = ?', { tonumber(mid) or 0, id }) end
    return true
end)

-- ═════════════════ MAILS ═════════════════
function Aura.SendMailTo(identifier, from, subject, body)
    local p = Aura.phones[identifier]; if not p or not p.mail then return false end
    local now = Aura.Now()
    local mid = MySQL.insert.await('INSERT INTO aero_mail (owner, from_addr, to_addr, subject, body, folder, created) VALUES (?,?,?,?,?, "inbox", ?)', { p.mail, Aura.Clamp(from, 120), p.mail, Aura.Clamp(subject, 120), Aura.Clamp(body, 4000), now })
    Aura.Push(identifier, 'mail', { id = mid, from = from, subject = subject })
    return mid
end

lib.callback.register('aura:mailList', function(src, folder)
    local id = Aura.ident[src]; local p = id and Aura.phones[id]
    if not p then return {} end
    folder = (folder == 'sent' or folder == 'trash') and folder or 'inbox'
    return MySQL.query.await('SELECT id, from_addr, to_addr, subject, body, folder, seen, starred, created FROM aero_mail WHERE owner = ? AND folder = ? ORDER BY id DESC LIMIT 100', { p.mail, folder }) or {}
end)

lib.callback.register('aura:mailSend', function(src, to, subject, body)
    local id = Aura.ident[src]; local p = id and Aura.phones[id]
    if not p then return false end
    to = Aura.Trim(to):lower()
    local tid = Aura.byAddr[to]
    if not tid then return false, 'Adresse inconnue' end
    subject = Aura.Clamp(Aura.Trim(subject), 120); if subject == '' then subject = '(Sans objet)' end
    body = Aura.Clamp(body, 4000)
    local now = Aura.Now()
    MySQL.insert.await('INSERT INTO aero_mail (owner, from_addr, to_addr, subject, body, folder, seen, created) VALUES (?,?,?,?,?, "sent", 1, ?)', { p.mail, p.mail, to, subject, body, now })
    local mid = MySQL.insert.await('INSERT INTO aero_mail (owner, from_addr, to_addr, subject, body, folder, created) VALUES (?,?,?,?,?, "inbox", ?)', { to, p.mail, to, subject, body, now })
    Aura.Push(tid, 'mail', { id = mid, from = p.mail, subject = subject })
    return true
end)

lib.callback.register('aura:mailFlag', function(src, mid, field, value)
    local id = Aura.ident[src]; local p = id and Aura.phones[id]
    if not p then return false end
    mid = tonumber(mid) or 0
    if field == 'seen' then MySQL.update.await('UPDATE aero_mail SET seen = ? WHERE id = ? AND owner = ?', { value and 1 or 0, mid, p.mail })
    elseif field == 'starred' then MySQL.update.await('UPDATE aero_mail SET starred = ? WHERE id = ? AND owner = ?', { value and 1 or 0, mid, p.mail })
    elseif field == 'trash' then MySQL.update.await('UPDATE aero_mail SET folder = "trash" WHERE id = ? AND owner = ?', { mid, p.mail })
    elseif field == 'delete' then MySQL.update.await('DELETE FROM aero_mail WHERE id = ? AND owner = ?', { mid, p.mail }) end
    return true
end)

lib.callback.register('aura:mailUnread', function(src)
    local id = Aura.ident[src]; local p = id and Aura.phones[id]
    if not p then return 0 end
    return MySQL.scalar.await('SELECT COUNT(*) FROM aero_mail WHERE owner = ? AND folder = "inbox" AND seen = 0', { p.mail }) or 0
end)
