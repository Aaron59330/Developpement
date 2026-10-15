-- ─────────────────────────────── Banques : guichets & distributeurs ───────────────────────────────
local function resolve(src, eid, pi)
    local e = WB.Entities[tonumber(eid) or 0]
    local xPlayer = ESX.GetPlayerFromId(src)
    if not e or e.type ~= 'bank' or not e.enabled or not xPlayer then return nil, 'Introuvable' end
    local p = e.points[tonumber(pi) or 0]
    if not p or not p.coords or (p.kind ~= 'counter' and p.kind ~= 'atm') or not WB.near(src, p.coords, 4.0) then return nil, 'Trop loin' end
    local ok, err = WB.hasAccess(xPlayer, e.settings.access)
    if not ok then return nil, err end
    return e, p, xPlayer
end

local function fee(pct, amount) return math.ceil(amount * (tonumber(pct) or 0) / 100) end
local function money(x, acc) local a = x.getAccount(acc) return a and a.money or 0 end

local function snapshot(e, p, xPlayer)
    local s = e.settings
    local left = -1
    if (s.dailyLimit or 0) > 0 then left = math.max(0, s.dailyLimit - WB.counter(('bank:%s:%d'):format(xPlayer.identifier, e.id), 86400).n) end
    return { ok = true, label = p.label ~= '' and p.label or e.label, kind = p.kind, money = money(xPlayer, 'money'), bank = money(xPlayer, 'bank'),
        fees = { deposit = s.depositFee or 0, withdraw = s.withdrawFee or 0, transfer = s.transferFee or 0 }, max = s.maxTransaction or 0, left = left,
        canDeposit = p.kind == 'counter' or s.atmDeposit == true }
end

local function amountOf(s, v)
    local n = math.floor(tonumber(v) or 0)
    if n < 1 then return nil, 'Montant invalide' end
    if (s.maxTransaction or 0) > 0 and n > s.maxTransaction then return nil, ('Maximum par opération : %d'):format(s.maxTransaction) end
    return n
end

ESX.RegisterServerCallback('worldbuilder:bank:info', function(src, cb, eid, pi)
    local e, p, x = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    cb(snapshot(e, p, x))
end)

ESX.RegisterServerCallback('worldbuilder:bank:deposit', function(src, cb, eid, pi, amount)
    local e, p, x = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local snap = snapshot(e, p, x)
    if not snap.canDeposit then return cb({ ok = false, error = 'Les dépôts se font au guichet' }) end
    local n, err = amountOf(e.settings, amount)
    if not n then return cb({ ok = false, error = err }) end
    if snap.money < n then return cb({ ok = false, error = 'Tu n\'as pas assez d\'espèces' }) end
    local f = fee(e.settings.depositFee, n)
    x.removeAccountMoney('money', n, 'Dépôt bancaire')
    x.addAccountMoney('bank', n - f, 'Dépôt bancaire')
    WB.society(e.settings.society, f) WB.stat(e, 'revenue', f) WB.stat(e, 'deposits', n)
    WB.log(e, x, 'deposit', ('frais %d'):format(f), n)
    cb(snapshot(e, p, x))
end)

ESX.RegisterServerCallback('worldbuilder:bank:withdraw', function(src, cb, eid, pi, amount)
    local e, p, x = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local s = e.settings
    local n, err = amountOf(s, amount)
    if not n then return cb({ ok = false, error = err }) end
    if money(x, 'bank') < n then return cb({ ok = false, error = 'Solde bancaire insuffisant' }) end
    local c = WB.counter(('bank:%s:%d'):format(x.identifier, e.id), 86400)
    if (s.dailyLimit or 0) > 0 and c.n + n > s.dailyLimit then return cb({ ok = false, error = 'Limite de retrait journalière atteinte' }) end
    local f = fee(s.withdrawFee, n)
    c.n = c.n + n
    x.removeAccountMoney('bank', n, 'Retrait bancaire')
    x.addAccountMoney('money', n - f, 'Retrait bancaire')
    WB.society(s.society, f) WB.stat(e, 'revenue', f) WB.stat(e, 'withdrawn', n)
    WB.log(e, x, 'withdraw', ('frais %d'):format(f), n)
    cb(snapshot(e, p, x))
end)

ESX.RegisterServerCallback('worldbuilder:bank:transfer', function(src, cb, eid, pi, amount, targetId)
    local e, p, x = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local s = e.settings
    local n, err = amountOf(s, amount)
    if not n then return cb({ ok = false, error = err }) end
    local t = ESX.GetPlayerFromId(tonumber(targetId) or -1)
    if not t or t.source == src then return cb({ ok = false, error = 'Destinataire introuvable (ID du joueur en ligne)' }) end
    if money(x, 'bank') < n then return cb({ ok = false, error = 'Solde bancaire insuffisant' }) end
    local f = fee(s.transferFee, n)
    x.removeAccountMoney('bank', n, 'Virement envoyé')
    t.addAccountMoney('bank', n - f, 'Virement reçu')
    WB.society(s.society, f) WB.stat(e, 'revenue', f) WB.stat(e, 'transfers', n)
    WB.notify(t.source, ('Virement reçu : %d %s de %s'):format(n - f, Config.Currency, WB.playerName(x)), 'success')
    WB.log(e, x, 'transfer', ('vers %s, frais %d'):format(WB.playerName(t), f), n)
    cb(snapshot(e, p, x))
end)
