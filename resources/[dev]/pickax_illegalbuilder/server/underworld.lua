-- ─────────────────────────────── Pègre : marché noir à rotation, contrats de livraison, casier judiciaire ───────────────────────────────
-- Marché noir : un vendeur change de lieu et de stock à chaque rotation (même résultat pour tous les joueurs, calculé depuis l'heure). Contrats : /contrat donne une
-- livraison à faire avant la fin du temps imparti (distance et durée vérifiées côté serveur). Casier : les infractions et amendes d'un joueur, alimentées par les
-- saisies et par /inculper (police). Rien n'est décidé par le client.

local lastBuy, contracts, contractCool = {}, {}, {}
local bought = {}   -- [identifiant] = { rotation, [offre] = quantité achetée }

local function BM() return Config.BlackMarket or {} end
local function CT() return Config.Contracts or {} end
local function RC() return Config.Record or {} end

CreateThread(function()
    Wait(2000)
    if MySQL and MySQL.query then
        pcall(MySQL.query.await, [[CREATE TABLE IF NOT EXISTS illegalbuilder_records (id INT AUTO_INCREMENT PRIMARY KEY, identifier VARCHAR(80) NOT NULL, name VARCHAR(100) NULL,
            reason VARCHAR(200) NOT NULL, fine INT NOT NULL DEFAULT 0, by_name VARCHAR(100) NULL, created_at INT NOT NULL, INDEX (identifier)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    end
end)

-- ═══════════════════════════ Marché noir ═══════════════════════════
function IB.bmRotation(now)
    return math.floor((now or os.time()) / (math.max(1, tonumber(BM().RotationHours) or 24) * 3600))
end

-- petit générateur déterministe (résultat identique pour tous les joueurs et après un redémarrage)
local function rng(seed)
    local s = (seed * 1103515245 + 12345) % 2147483648
    return function(n)
        s = (s * 1103515245 + 12345) % 2147483648
        return 1 + math.floor((s / 2147483648) * n) % n
    end
end

function IB.bmLocation(now)
    local L = BM().Locations or {}
    if #L == 0 then return nil end
    local r = IB.bmRotation(now)
    return L[rng(r + 7)(#L)], r
end

-- Offres de la rotation : { { id, item, label, price, stock } }
function IB.bmOffers(now)
    local pool, out = BM().Items or {}, {}
    if #pool == 0 then return out end
    local r = IB.bmRotation(now)
    local roll = rng(r + 99)
    local picked, n = {}, math.min(math.floor(tonumber(BM().OffersPerRotation) or 4), #pool)
    local guard = 0
    while #out < n and guard < 200 do
        guard = guard + 1
        local i = roll(#pool)
        if not picked[i] then
            picked[i] = true
            local it = pool[i]
            local lo, hi = tonumber(BM().PriceMin) or 0.8, tonumber(BM().PriceMax) or 1.4
            local mul = lo + (hi - lo) * ((roll(1000) - 1) / 999)
            out[#out + 1] = { id = #out + 1, item = it.item, label = it.label or it.item, price = math.max(1, math.floor(it.price * mul + 0.5)), stock = math.floor(tonumber(it.stock) or 5), rare = it.rare and true or false }
        end
    end
    return out
end

ESX.RegisterServerCallback('illegalbuilder:bm:info', function(src, cb)
    if not BM().Enabled then return cb({ ok = false, error = 'Le marché noir est fermé.' }) end
    local loc, r = IB.bmLocation()
    if not loc then return cb({ ok = false, error = 'Aucun vendeur pour le moment.' }) end
    local near = IB.distanceTo(src, loc.coords) <= (tonumber(BM().Radius) or 4.0) + 2.0
    local offers = {}
    if near then for _, o in ipairs(IB.bmOffers()) do offers[#offers + 1] = o end end
    cb({ ok = true, near = near, coords = loc.coords, hint = loc.hint or loc.label, label = loc.label, offers = offers, until_ = (r + 1) * math.max(1, tonumber(BM().RotationHours) or 24) * 3600 - os.time() })
end)

ESX.RegisterServerCallback('illegalbuilder:bm:buy', function(src, cb, offerId, qty)
    if not BM().Enabled then return cb({ ok = false, error = 'Le marché noir est fermé.' }) end
    local x = ESX.GetPlayerFromId(src)
    if not x then return cb({ ok = false }) end
    local now = GetGameTimer()
    if (lastBuy[src] or -1e9) + 1500 > now then return cb({ ok = false, error = 'Doucement.' }) end
    lastBuy[src] = now
    local loc, rot = IB.bmLocation()
    if not loc or IB.distanceTo(src, loc.coords) > (tonumber(BM().Radius) or 4.0) + 2.0 then return cb({ ok = false, error = 'Tu n\'es pas chez le vendeur.' }) end
    qty = math.floor(tonumber(qty) or 1)
    if qty < 1 or qty > 50 then return cb({ ok = false, error = 'Quantité invalide.' }) end
    local offer
    for _, o in ipairs(IB.bmOffers()) do if o.id == tonumber(offerId) then offer = o end end
    if not offer then return cb({ ok = false, error = 'Offre inconnue.' }) end
    local b = bought[x.identifier]
    if not b or b.rot ~= rot then b = { rot = rot } bought[x.identifier] = b end
    local limit = math.floor(tonumber(BM().PerPlayerLimit) or offer.stock)
    local left = math.min(offer.stock, limit) - (b[offer.id] or 0)
    if left <= 0 then return cb({ ok = false, error = 'Tu as épuisé ce produit pour cette rotation.' }) end
    if qty > left then qty = left end
    local total = offer.price * qty
    local acc = x.getAccount(BM().Account or 'black_money')
    if not acc or acc.money < total then return cb({ ok = false, error = ('Il te faut %d $ d\'argent sale.'):format(total) }) end
    if not IB.canCarry(src, offer.item, qty) then return cb({ ok = false, error = 'Tu ne peux pas porter autant.' }) end
    x.removeAccountMoney(BM().Account or 'black_money', total, 'Marché noir')
    if not IB.addItem(src, offer.item, qty) then
        x.addAccountMoney(BM().Account or 'black_money', total, 'Marché noir (remboursement)')
        return cb({ ok = false, error = 'Impossible de te donner l\'objet.' })
    end
    b[offer.id] = (b[offer.id] or 0) + qty
    IB.log(nil, x, 'blackmarket', ('%d × %s'):format(qty, offer.item), total)
    if (BM().AlertChance or 0) > 0 and math.random(100) <= BM().AlertChance and IB.alertPolice then
        IB.alertPolice(loc.coords, 'Trafic suspect', 'Des échanges louches sont signalés dans le secteur.')
    end
    cb({ ok = true, item = offer.item, label = offer.label, qty = qty, paid = total })
end)

-- ═══════════════════════════ Contrats de livraison ═══════════════════════════
local function dist(a, b) local dx, dy, dz = a.x - b.x, a.y - b.y, (a.z or 0) - (b.z or 0) return math.sqrt(dx * dx + dy * dy + dz * dz) end

-- Paiement : base + prime par kilomètre ; prime de rapidité si livré en moins de FastRatio du temps imparti
function IB.contractReward(distance, elapsed, limit)
    local C = CT()
    local r = (tonumber(C.BaseReward) or 0) + (distance / 1000) * (tonumber(C.PerKm) or 0)
    local fast = limit > 0 and elapsed <= limit * (tonumber(C.FastRatio) or 0.6)
    if fast then r = r * (1 + (tonumber(C.FastBonus) or 0) / 100) end
    return math.floor(r), fast
end

-- Temps imparti : trajet à vitesse moyenne + marge
function IB.contractLimit(distance)
    local C = CT()
    return math.max(tonumber(C.MinSeconds) or 60, math.floor(distance / math.max(1, tonumber(C.AvgSpeed) or 18) * (tonumber(C.TimeMargin) or 1.5)))
end

ESX.RegisterServerCallback('illegalbuilder:contract:start', function(src, cb)
    local C = CT()
    if not C.Enabled then return cb({ ok = false, error = 'Les contrats sont indisponibles.' }) end
    local x = ESX.GetPlayerFromId(src)
    if not x then return cb({ ok = false }) end
    if contracts[src] then return cb({ ok = false, error = 'Tu as déjà un contrat en cours.' }) end
    if (contractCool[x.identifier] or 0) > os.time() then return cb({ ok = false, error = ('Reviens dans %d s.'):format(contractCool[x.identifier] - os.time()) }) end
    local D = C.Destinations or {}
    if #D == 0 then return cb({ ok = false, error = 'Aucun client disponible.' }) end
    local ped = GetPlayerPed(src)
    local from = GetEntityCoords(ped)
    local pick, tries = nil, 0
    repeat pick = D[math.random(#D)] tries = tries + 1 until tries > 20 or dist(from, pick.coords) >= (tonumber(C.MinDistance) or 300)
    local d = dist(from, pick.coords)
    local limit = IB.contractLimit(d)
    contracts[src] = { to = pick.coords, label = pick.label, startedAt = os.time(), limit = limit, dist = d, from = from }
    contractCool[x.identifier] = os.time() + math.floor(tonumber(C.Cooldown) or 120)
    if (C.AlertChance or 0) > 0 and math.random(100) <= C.AlertChance then IB.alertPolice(from, 'Livraison suspecte', 'Un colis louche circule dans le quartier.') end
    cb({ ok = true, label = pick.label, coords = pick.coords, limit = limit })
end)

ESX.RegisterServerCallback('illegalbuilder:contract:done', function(src, cb)
    local c = contracts[src]
    if not c then return cb({ ok = false, error = 'Aucun contrat en cours.' }) end
    local x = ESX.GetPlayerFromId(src)
    if not x then return cb({ ok = false }) end
    local elapsed = os.time() - c.startedAt
    local here = GetEntityCoords(GetPlayerPed(src))
    if dist(here, c.to) > (tonumber(CT().Radius) or 15.0) + 3.0 then return cb({ ok = false, error = 'Tu n\'es pas au point de livraison.' }) end
    contracts[src] = nil
    if elapsed > c.limit then return cb({ ok = false, failed = true, error = 'Trop tard : le client a annulé.' }) end
    -- vitesse impossible → triche : on refuse (plus de 70 m/s en moyenne)
    if elapsed < 1 or c.dist / elapsed > 70 then return cb({ ok = false, failed = true, error = 'Livraison invalide.' }) end
    local reward, fast = IB.contractReward(c.dist, elapsed, c.limit)
    x.addAccountMoney(CT().Account or 'black_money', reward, 'Contrat de livraison')
    IB.log(nil, x, 'contract', c.label or '', reward)
    if GetResourceState('pickax_settings') == 'started' then pcall(function() exports.pickax_settings:Count('contracts', 1, 'Contrats livrés') end) end
    cb({ ok = true, reward = reward, fast = fast })
end)

RegisterNetEvent('illegalbuilder:server:contractCancel', function() contracts[source] = nil end)

-- ═══════════════════════════ Casier judiciaire ═══════════════════════════
function IB.recordAdd(identifier, name, reason, fine, by)
    reason = tostring(reason or ''):gsub('[%c]', ' '):sub(1, 200)
    if reason == '' or not identifier then return false end
    MySQL.insert('INSERT INTO illegalbuilder_records (identifier, name, reason, fine, by_name, created_at) VALUES (?, ?, ?, ?, ?, ?)',
        { identifier, name, reason, math.max(0, math.floor(tonumber(fine) or 0)), by, os.time() })
    return true
end

function IB.recordSummary(rows)
    local fines = 0
    for _, r in ipairs(rows) do fines = fines + (tonumber(r.fine) or 0) end
    return #rows, fines
end

local function police(src)
    local x = ESX.GetPlayerFromId(src)
    if not x or not IB.isPoliceJob(x.job.name) then IB.notify(src, 'Réservé à la police.', 'error') return nil end
    return x
end

RegisterCommand('casier', function(src, args)
    if src == 0 or not RC().Enabled or not police(src) then return end
    local t = ESX.GetPlayerFromId(tonumber(args[1]))
    if not t then return IB.notify(src, 'Usage : /casier <id du joueur>', 'error') end
    local rows = MySQL.query.await('SELECT reason, fine, by_name, created_at FROM illegalbuilder_records WHERE identifier = ? ORDER BY id DESC LIMIT 20', { t.identifier }) or {}
    local n, fines = IB.recordSummary(rows)
    if n == 0 then return IB.notify(src, ('%s a un casier vierge.'):format(IB.playerName(t)), 'info') end
    IB.notify(src, ('Casier de %s : %d infraction(s), %d $ d\'amendes'):format(IB.playerName(t), n, fines), 'warning')
    for i = 1, math.min(5, n) do
        local r = rows[i]
        IB.notify(src, ('%s · %s%s'):format(os.date('%d/%m', r.created_at), r.reason, (r.fine or 0) > 0 and (' (%d $)'):format(r.fine) or ''), 'info')
    end
end, false)

RegisterCommand('inculper', function(src, args)
    if src == 0 or not RC().Enabled then return end
    local officer = police(src)
    if not officer then return end
    local t = ESX.GetPlayerFromId(tonumber(args[1]))
    local fine = math.floor(tonumber(args[2]) or -1)
    local reason = table.concat(args, ' ', 3)
    if not t or t.source == src or fine < 0 or reason == '' then return IB.notify(src, 'Usage : /inculper <id> <amende> <motif>', 'error') end
    local a, b = GetPlayerPed(src), GetPlayerPed(t.source)
    if not a or a == 0 or not b or b == 0 or dist(GetEntityCoords(a), GetEntityCoords(b)) > (tonumber(RC().Distance) or 6.0) then return IB.notify(src, 'Le suspect est trop loin.', 'error') end
    fine = math.min(fine, math.floor(tonumber(RC().MaxFine) or 50000))
    local paid = 0
    if fine > 0 then
        local acc = t.getAccount('bank')
        paid = math.min(fine, acc and acc.money or 0)
        if paid > 0 then
            t.removeAccountMoney('bank', paid, 'Amende')
            if (RC().Society or '') ~= '' then IB.society(RC().Society, paid) end
        end
    end
    IB.recordAdd(t.identifier, IB.playerName(t), reason, fine, IB.playerName(officer))
    IB.log(nil, officer, 'record', ('%s : %s'):format(IB.playerName(t), reason), fine)
    IB.notify(src, ('%s inculpé : %s (%d $ prélevés sur %d $)'):format(IB.playerName(t), reason, paid, fine), 'success')
    IB.notify(t.source, ('Tu as été inculpé : %s — amende de %d $.'):format(reason, fine), 'error')
    if GetResourceState('pickax_settings') == 'started' then pcall(function() exports.pickax_settings:Count('fines', paid, 'Amendes encaissées ($)') end) end
end, false)

AddEventHandler('playerDropped', function() lastBuy[source] = nil contracts[source] = nil end)
