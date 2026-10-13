-- ─────────────────────────────── Occasion : annonces de véhicules entre joueurs ───────────────────────────────
-- Le véhicule mis en vente passe à stored = Config.Vehicles.forSale (3) : il disparaît du garage et de la fourrière,
-- et reste exposé sur une place du module (véhicule d'exposition côté client) jusqu'à la vente, au retrait ou à l'expiration.
local V = Config.Vehicles
local function col(c) return '`' .. c .. '`' end
local T = col(V.table)
local FORSALE = V.forSale or 3
local Listings = {}       -- [id] = annonce

local function trimPlate(p) return (tostring(p or ''):gsub('^%s+', ''):gsub('%s+$', '')) end
local function st(v) if v == true then return 1 elseif v == false then return 0 end return tonumber(v) or 0 end

local function public(l, e)
    local props = l.props or {}
    return { id = l.id, eid = l.entity_id, pi = l.slot, price = l.price, desc = l.description or '', phone = l.phone or '', seller = l.seller_name or '?',
        model = props.model, props = props, plate = (e and e.settings.showPlate) and l.plate or nil, expires = l.expires_at }
end

local function loadListings()
    Listings = {}
    for _, r in ipairs(MySQL.query.await('SELECT * FROM worldbuilder_listings') or {}) do
        r.props = WB.decode(r.props, {})
        Listings[r.id] = r
    end
end

local prevReady = WB.onReady
function WB.onReady()
    if prevReady then prevReady() end
    loadListings()
end

function WB.syncListings(src)
    local list = {}
    for _, l in pairs(Listings) do
        local e = WB.Entities[l.entity_id]
        if e and e.enabled then list[#list + 1] = public(l, e) end
    end
    TriggerClientEvent('worldbuilder:client:listings', src, list)
end

local function broadcastRemove(id) TriggerClientEvent('worldbuilder:client:listingRemove', -1, id) end

local function returnToGarage(l)
    MySQL.update.await(('UPDATE %s SET %s = 1 WHERE TRIM(%s) = ? AND %s = ?'):format(T, col(V.stored), col(V.plate), col(V.stored)), { l.plate, FORSALE })
    MySQL.update.await('DELETE FROM worldbuilder_listings WHERE id = ?', { l.id })
    Listings[l.id] = nil
    broadcastRemove(l.id)
end

-- ─────────────────────────────── Accès ───────────────────────────────
local function resolve(src, eid, pi)
    local e = WB.Entities[tonumber(eid) or 0]
    local x = ESX.GetPlayerFromId(src)
    if not e or e.type ~= 'carlot' or not e.enabled or not x then return nil, 'Introuvable' end
    local p = e.points[tonumber(pi) or 0]
    if not p or (p.kind ~= 'lot' and p.kind ~= 'slot') or not p.coords or not WB.near(src, p.coords, 6.0) then return nil, 'Trop loin' end
    local ok, err = WB.hasAccess(x, e.settings.access)
    if not ok then return nil, err end
    return e, p, x
end

local function claimPayouts(x)
    local rows = MySQL.query.await('SELECT id, amount FROM worldbuilder_payouts WHERE identifier = ?', { x.identifier }) or {}
    local sum = 0
    for _, r in ipairs(rows) do sum = sum + r.amount end
    if sum > 0 then
        MySQL.update.await('DELETE FROM worldbuilder_payouts WHERE identifier = ?', { x.identifier })
        x.addAccountMoney('bank', sum, 'Vente de véhicule')
        WB.notify(x.source, ('Tu as reçu %d %s (ventes de véhicules) sur ton compte.'):format(sum, Config.Currency), 'success')
    end
end

AddEventHandler('esx:playerLoaded', function(src) SetTimeout(6000, function() local x = ESX.GetPlayerFromId(src) if x then claimPayouts(x) end end) end)

local function slotsOf(e)
    local list = {}
    for i, p in ipairs(e.points) do if p.kind == 'slot' and p.coords then list[#list + 1] = i end end
    return list
end

local function listingAt(eid, slot)
    for _, l in pairs(Listings) do if l.entity_id == eid and l.slot == slot then return l end end
end

local function snapshot(e, p, x)
    local s = e.settings
    local all, mineCount = {}, 0
    for _, l in pairs(Listings) do
        if l.entity_id == e.id then
            local pub = public(l, e)
            pub.mine = l.seller == x.identifier
            if pub.mine then mineCount = mineCount + 1 end
            all[#all + 1] = pub
        end
    end
    table.sort(all, function(a, b) return a.id > b.id end)
    local free = #slotsOf(e) - #all
    local vehicles = {}
    if p.kind == 'lot' then
        for _, r in ipairs(MySQL.query.await(('SELECT %s AS plate, %s AS props FROM %s WHERE %s = ? AND %s = 1'):format(col(V.plate), col(V.props), T, col(V.owner), col(V.stored)), { x.identifier }) or {}) do
            local props = WB.decode(r.props, {}) or {}
            vehicles[#vehicles + 1] = { plate = r.plate, model = props.model }
        end
    end
    return { ok = true, label = p.label ~= '' and p.label or e.label, kind = p.kind, listings = all, vehicles = vehicles, freeSlots = math.max(0, free),
        mineCount = mineCount, maxListings = s.maxListings, fee = s.listingFee or 0, commission = s.commission or 0, minPrice = s.minPrice or 0, maxPrice = s.maxPrice or 0,
        days = s.durationDays or 0, payments = WB.paymentsList(s.payments, x), showPlate = s.showPlate == true }
end

ESX.RegisterServerCallback('worldbuilder:carlot:info', function(src, cb, eid, pi)
    local e, p, x = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    claimPayouts(x)
    cb(snapshot(e, p, x))
end)

-- ─────────────────────────────── Mise en vente ───────────────────────────────
local function clean(s, max, pattern)
    s = tostring(s or ''):gsub('[%c]', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    if pattern and not s:match(pattern) then return '' end
    return s:sub(1, max)
end

ESX.RegisterServerCallback('worldbuilder:carlot:list', function(src, cb, eid, pi, plate, price, desc, phone, method)
    local e, p, x = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    if p.kind ~= 'lot' then return cb({ ok = false, error = 'Les annonces se déposent au bureau' }) end
    local s = e.settings
    plate = trimPlate(plate)
    price = math.floor(tonumber(price) or 0)
    if price < math.max(1, s.minPrice or 0) then return cb({ ok = false, error = ('Prix minimum : %d'):format(math.max(1, s.minPrice or 0)) }) end
    if (s.maxPrice or 0) > 0 and price > s.maxPrice then return cb({ ok = false, error = ('Prix maximum : %d'):format(s.maxPrice) }) end
    local mine = 0
    for _, l in pairs(Listings) do if l.seller == x.identifier then mine = mine + 1 end end
    if mine >= (s.maxListings or 3) then return cb({ ok = false, error = ('Tu as déjà %d annonce(s) (maximum atteint)'):format(mine) }) end
    local slot
    for _, i in ipairs(slotsOf(e)) do if not listingAt(e.id, i) then slot = i break end end
    if not slot then return cb({ ok = false, error = 'Aucune place d\'exposition libre' }) end
    local row = MySQL.single.await(('SELECT %s AS plate, %s AS props, %s AS stored FROM %s WHERE %s = ? AND TRIM(%s) = ?'):format(col(V.plate), col(V.props), col(V.stored), T, col(V.owner), col(V.plate)), { x.identifier, plate })
    if not row or st(row.stored) ~= 1 then return cb({ ok = false, error = 'Le véhicule doit être rangé dans ton garage' }) end
    local okp, err = WB.charge(x, s.payments, method, s.listingFee, 'Annonce : ' .. e.label)
    if not okp then return cb({ ok = false, error = err }) end
    local changed = MySQL.update.await(('UPDATE %s SET %s = ? WHERE %s = ? AND %s = ? AND %s = 1'):format(T, col(V.stored), col(V.owner), col(V.plate), col(V.stored)), { FORSALE, x.identifier, row.plate })
    if not changed or changed < 1 then
        x.addAccountMoney((Config.Payments[method] or Config.Payments.cash).account, math.floor(s.listingFee or 0), 'Remboursement annonce')
        return cb({ ok = false, error = 'Véhicule indisponible' })
    end
    WB.society(s.society, s.listingFee)
    local expires = (s.durationDays or 0) > 0 and (os.time() + s.durationDays * 86400) or 0
    local props = WB.decode(row.props, {}) or {}
    local id = MySQL.insert.await('INSERT INTO worldbuilder_listings (entity_id, slot, seller, seller_name, plate, props, price, description, phone, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { e.id, slot, x.identifier, WB.playerName(x), trimPlate(row.plate), json.encode(props), price, clean(desc, 140), clean(phone, 20, '^[%d%s%-%+%.]*$'), expires })
    local l = { id = id, entity_id = e.id, slot = slot, seller = x.identifier, seller_name = WB.playerName(x), plate = trimPlate(row.plate), props = props, price = price,
        description = clean(desc, 140), phone = clean(phone, 20, '^[%d%s%-%+%.]*$'), expires_at = expires }
    Listings[id] = l
    TriggerClientEvent('worldbuilder:client:listingAdd', -1, public(l, e))
    WB.stat(e, 'listed', 1) WB.stat(e, 'revenue', s.listingFee)
    WB.log(e, x, 'list', ('%s à %d'):format(l.plate, price), price)
    cb(snapshot(e, p, x))
end)

-- ─────────────────────────────── Achat ───────────────────────────────
ESX.RegisterServerCallback('worldbuilder:carlot:buy', function(src, cb, eid, pi, id, method)
    local e, p, x = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local s = e.settings
    local l = Listings[tonumber(id) or 0]
    if not l or l.entity_id ~= e.id then return cb({ ok = false, error = 'Annonce introuvable (déjà vendue ?)' }) end
    if l.seller == x.identifier then return cb({ ok = false, error = 'C\'est ton annonce' }) end
    local okp, err = WB.charge(x, s.payments, method, l.price, 'Achat véhicule : ' .. l.plate)
    if not okp then return cb({ ok = false, error = err }) end
    local changed = MySQL.update.await(('UPDATE %s SET %s = ?, %s = 1 WHERE %s = ? AND TRIM(%s) = ? AND %s = ?'):format(T, col(V.owner), col(V.stored), col(V.owner), col(V.plate), col(V.stored)), { x.identifier, l.seller, l.plate, FORSALE })
    if not changed or changed < 1 then
        x.addAccountMoney((Config.Payments[method] or Config.Payments.cash).account, l.price, 'Remboursement achat')
        return cb({ ok = false, error = 'Véhicule indisponible : tu as été remboursé' })
    end
    MySQL.update('DELETE FROM worldbuilder_parking WHERE plate = ?', { l.plate })
    MySQL.update('DELETE FROM worldbuilder_impound WHERE plate = ?', { l.plate })
    MySQL.update.await('DELETE FROM worldbuilder_listings WHERE id = ?', { l.id })
    Listings[l.id] = nil
    broadcastRemove(l.id)
    local commission = math.floor(l.price * (s.commission or 0) / 100)
    local net = l.price - commission
    WB.society(s.society, commission)
    local seller
    for _, pid in ipairs(GetPlayers()) do
        local o = ESX.GetPlayerFromId(tonumber(pid))
        if o and o.identifier == l.seller then seller = o break end
    end
    if seller then
        seller.addAccountMoney('bank', net, 'Vente de véhicule')
        WB.notify(seller.source, ('Ton véhicule %s a été vendu : %d %s reçus sur ton compte.'):format(l.plate, net, Config.Currency), 'success')
    else
        MySQL.insert('INSERT INTO worldbuilder_payouts (identifier, amount, note) VALUES (?, ?, ?)', { l.seller, net, 'Vente ' .. l.plate })
    end
    if WB.transferKeys then WB.transferKeys(src, (l.props and l.props.plate) or l.plate, e.settings) end
    WB.stat(e, 'sold', 1) WB.stat(e, 'revenue', commission)
    WB.log(e, x, 'buy', ('%s à %d (commission %d)'):format(l.plate, l.price, commission), l.price)
    WB.notify(src, ('Véhicule acheté ! Il t\'attend dans ton garage (%s).'):format(l.plate), 'success')
    cb(snapshot(e, p, x))
end)

-- ─────────────────────────────── Retrait / modification ───────────────────────────────
ESX.RegisterServerCallback('worldbuilder:carlot:cancel', function(src, cb, eid, pi, id)
    local e, p, x = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local l = Listings[tonumber(id) or 0]
    if not l or l.entity_id ~= e.id then return cb({ ok = false, error = 'Annonce introuvable' }) end
    if l.seller ~= x.identifier and not WB.isAdmin(src) then return cb({ ok = false, error = 'Ce n\'est pas ton annonce' }) end
    returnToGarage(l)
    WB.log(e, x, 'cancel', l.plate)
    cb(snapshot(e, p, x))
end)

ESX.RegisterServerCallback('worldbuilder:carlot:price', function(src, cb, eid, pi, id, price)
    local e, p, x = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local s = e.settings
    local l = Listings[tonumber(id) or 0]
    if not l or l.entity_id ~= e.id or l.seller ~= x.identifier then return cb({ ok = false, error = 'Annonce introuvable' }) end
    price = math.floor(tonumber(price) or 0)
    if price < math.max(1, s.minPrice or 0) or ((s.maxPrice or 0) > 0 and price > s.maxPrice) then return cb({ ok = false, error = 'Prix hors limites' }) end
    l.price = price
    MySQL.update('UPDATE worldbuilder_listings SET price = ? WHERE id = ?', { price, l.id })
    TriggerClientEvent('worldbuilder:client:listingAdd', -1, public(l, e))
    cb(snapshot(e, p, x))
end)

-- ─────────────────────────────── Expiration & modifications du module ───────────────────────────────
CreateThread(function()
    while true do
        Wait(300000)
        if WB.ready then
            local now = os.time()
            for _, l in pairs(Listings) do
                if l.expires_at and l.expires_at > 0 and now >= l.expires_at then
                    returnToGarage(l)
                    local e = WB.Entities[l.entity_id]
                    if e then WB.log(e, nil, 'expire', l.plate) end
                end
            end
        end
    end
end)

local prevChanged = WB.onEntityChanged
function WB.onEntityChanged(e, deleted)
    if prevChanged then prevChanged(e, deleted) end
    if e.type ~= 'carlot' then return end
    for _, l in pairs(Listings) do
        if l.entity_id == e.id then
            local p = e.points[l.slot]
            if deleted or not p or p.kind ~= 'slot' or not p.coords then returnToGarage(l) end
        end
    end
end
