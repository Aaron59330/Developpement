-- ─────────────────────────────── Vie quotidienne : permis, pêche, chasse, cuisine, taxi / livraison ───────────────────────────────
local ESX = exports['es_extended']:getSharedObject()
local function xp(src, a, o) if GetResourceState('pickax_xp') == 'started' then pcall(function() exports['pickax_xp']:AddXP(src, a, o) end) end end
local C = Config
local Pending, Quota, Skinned, Runs = {}, {}, {}, {}

local function clamp(v, a, b) return math.max(a, math.min(b, v)) end
local function have(src, item) return exports.ox_inventory:GetItemCount(src, item) or 0 end
local function near(src, c, d) if not c then return false end return #(GetEntityCoords(GetPlayerPed(src)) - c) <= d end
local function notify(src, kind, txt) TriggerClientEvent('pickax_notify:notify', src, { type = kind, description = txt }) end

-- Quota glissant par heure et par activité
local function quotaOk(src, key, max)
    local q = Quota[key .. src] or {}
    local t = os.time()
    local out = {}
    for _, v in ipairs(q) do if t - v < 3600 then out[#out + 1] = v end end
    Quota[key .. src] = out
    return #out < max
end
local function quotaUse(src, key) local q = Quota[key .. src] or {} q[#q + 1] = os.time() Quota[key .. src] = q end

-- ═══════════════ Permis ═══════════════
ESX.RegisterServerCallback('pickax_life:licList', function(src, cb)
    local x = ESX.GetPlayerFromId(src)
    local O = C.Licenses.Office
    if not x or not near(src, O.coords, O.Distance + 3.0) then return cb({ ok = false, error = 'Trop loin' }) end
    local list = {}
    for _, l in ipairs(C.Licenses.List) do list[#list + 1] = { item = l.item, label = l.label, price = l.price, owned = have(src, l.item) > 0 } end
    cb({ ok = true, list = list })
end)

ESX.RegisterServerCallback('pickax_life:licBuy', function(src, cb, item)
    local x = ESX.GetPlayerFromId(src)
    local O = C.Licenses.Office
    if not x or not near(src, O.coords, O.Distance + 3.0) then return cb({ ok = false, error = 'Trop loin' }) end
    for _, l in ipairs(C.Licenses.List) do
        if l.item == item then
            if have(src, l.item) > 0 then return cb({ ok = false, error = 'Tu as déjà ce permis' }) end
            if x.getAccount(C.Licenses.Account).money < l.price then return cb({ ok = false, error = 'Fonds insuffisants' }) end
            x.removeAccountMoney(C.Licenses.Account, l.price, l.label)
            exports.ox_inventory:AddItem(src, l.item, 1, { holder = x.getName and x.getName() or '', since = os.date('%d/%m/%Y') })
            return cb({ ok = true, msg = l.label .. ' délivré.' })
        end
    end
    cb({ ok = false, error = 'Permis inconnu' })
end)

-- ═══════════════ Pêche ═══════════════
local function inSpot(src, list) local p = GetEntityCoords(GetPlayerPed(src)) for _, s in ipairs(list) do if #(p - s.coords) <= s.radius then return true end end return false end

local function drawFish(boost)
    local F = C.Fishing
    local total, w = 0, {}
    for i, f in ipairs(F.Fish) do local x = f.weight * ((boost and f.difficulty >= 3) and F.BaitBoost or 1) w[i] = x total = total + x end
    local r, acc = math.random() * total, 0
    for i, f in ipairs(F.Fish) do acc = acc + w[i] if r <= acc then return f end end
    return F.Fish[1]
end

ESX.RegisterServerCallback('pickax_life:fishBegin', function(src, cb)
    local F = C.Fishing
    if not C.Enabled or not ESX.GetPlayerFromId(src) then return cb({ ok = false }) end
    if not inSpot(src, F.Spots) then return cb({ ok = false, error = 'Tu n\'es pas dans une zone de pêche' }) end
    if have(src, F.License) < 1 then return cb({ ok = false, error = 'Il te faut un permis de pêche' }) end
    if have(src, F.Rod) < 1 then return cb({ ok = false, error = 'Il te faut une canne à pêche' }) end
    if not quotaOk(src, 'fish', F.QuotaPerHour) then return cb({ ok = false, error = 'Quota de pêche atteint (réessaie dans un moment)' }) end
    local bait = F.Bait ~= '' and have(src, F.Bait) > 0
    local fish = drawFish(bait)
    if bait then exports.ox_inventory:RemoveItem(src, F.Bait, 1) end
    Pending[src] = { kind = 'fish', fish = fish, at = GetGameTimer() }
    cb({ ok = true, cfg = { title = 'Pêche', sub = 'Un poisson mord ! Garde la jauge sur lui', seconds = 22, size = 0.34 - fish.difficulty * 0.045, speed = 0.8 + fish.difficulty * 0.35, seed = math.random(1, 2147483000) }, bait = bait })
end)

ESX.RegisterServerCallback('pickax_life:fishEnd', function(src, cb, score)
    local p = Pending[src]
    Pending[src] = nil
    if not p or p.kind ~= 'fish' then return cb({ ok = false, error = 'Aucune pêche en cours' }) end
    if GetGameTimer() - p.at < 4000 then return cb({ ok = false, error = 'Trop rapide' }) end
    if not inSpot(src, C.Fishing.Spots) then return cb({ ok = false, error = 'Zone quittée' }) end
    quotaUse(src, 'fish')
    score = clamp(math.floor(tonumber(score) or 0), 0, 100)
    if score < C.Fishing.Min then return cb({ ok = true, failed = true, msg = 'Le poisson s\'est échappé…' }) end
    if not exports.ox_inventory:CanCarryItem(src, p.fish.item, 1) then return cb({ ok = false, error = 'Tu ne peux pas porter plus' }) end
    exports.ox_inventory:AddItem(src, p.fish.item, 1, { quality = score })
    xp(src, 'fish')
    cb({ ok = true, msg = ('Prise : %s !'):format(p.fish.label) })
end)

-- ═══════════════ Chasse ═══════════════
ESX.RegisterServerCallback('pickax_life:huntBegin', function(src, cb, netId, model)
    local H = C.Hunting
    if not C.Enabled or not ESX.GetPlayerFromId(src) then return cb({ ok = false }) end
    if not inSpot(src, H.Zones) then return cb({ ok = false, error = 'Tu n\'es pas dans une zone de chasse' }) end
    if have(src, H.License) < 1 then return cb({ ok = false, error = 'Il te faut un permis de chasse' }) end
    if have(src, H.Knife) < 1 then return cb({ ok = false, error = 'Il te faut : ' .. H.Knife }) end
    local ent = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if not ent or ent == 0 or not DoesEntityExist(ent) then return cb({ ok = false, error = 'Dépouille introuvable' }) end
    local an = H.Animals[GetEntityModel(ent)]
    if not an then return cb({ ok = false, error = 'Cet animal ne se dépèce pas' }) end
    if GetEntityHealth(ent) > 0 then return cb({ ok = false, error = 'L\'animal est encore vivant' }) end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(ent)) > 5.0 then return cb({ ok = false, error = 'Trop loin' }) end
    if Skinned[netId] then return cb({ ok = false, error = 'Déjà dépecé' }) end
    if not quotaOk(src, 'hunt', H.QuotaPerHour) then return cb({ ok = false, error = 'Quota de chasse atteint' }) end
    Pending[src] = { kind = 'hunt', netId = tonumber(netId), an = an, at = GetGameTimer() }
    cb({ ok = true, cfg = { rounds = 3, difficulty = an.difficulty, seconds = 22, title = 'Dépeçage : ' .. an.label, seed = math.random(1, 2147483000) } })
end)

ESX.RegisterServerCallback('pickax_life:huntEnd', function(src, cb, score)
    local p = Pending[src]
    Pending[src] = nil
    if not p or p.kind ~= 'hunt' then return cb({ ok = false, error = 'Aucun dépeçage en cours' }) end
    if GetGameTimer() - p.at < 5000 then return cb({ ok = false, error = 'Trop rapide' }) end
    local ent = NetworkGetEntityFromNetworkId(p.netId or 0)
    if not ent or ent == 0 or not DoesEntityExist(ent) or Skinned[p.netId] then return cb({ ok = false, error = 'Dépouille indisponible' }) end
    Skinned[p.netId] = true
    quotaUse(src, 'hunt')
    score = clamp(math.floor(tonumber(score) or 0), 0, 100)
    DeleteEntity(ent)
    if score < C.Hunting.Min then return cb({ ok = true, failed = true, msg = 'Dépeçage bâclé : la viande est inutilisable.' }) end
    local meat = math.max(1, math.floor(p.an.meatMax * score / 100 + 0.5))
    local got = {}
    if exports.ox_inventory:CanCarryItem(src, p.an.meat, meat) then exports.ox_inventory:AddItem(src, p.an.meat, meat, { quality = score }) got[#got + 1] = meat .. ' × ' .. p.an.meat end
    if p.an.skin and score >= 70 and exports.ox_inventory:CanCarryItem(src, p.an.skin, 1) then exports.ox_inventory:AddItem(src, p.an.skin, 1) got[#got + 1] = '1 × ' .. p.an.skin end
    xp(src, 'hunt')
    cb({ ok = true, msg = 'Dépeçage réussi : ' .. table.concat(got, ', ') })
end)

-- ═══════════════ Acheteurs ═══════════════
local function buyerPrices(b)
    local day = tonumber(os.date('%j')) or 1
    local out = {}
    for item, base in pairs(b.Items) do
        local f = ((joaat(item .. ':' .. day) & 0xFFFF) / 0xFFFF * 2 - 1) * b.Fluctuation / 100
        out[item] = math.floor(base * (1 + f))
    end
    return out
end

ESX.RegisterServerCallback('pickax_life:buyerList', function(src, cb, idx)
    local b = C.Buyers[tonumber(idx) or 0]
    if not b or not near(src, b.coords, b.Distance + 3.0) then return cb({ ok = false, error = 'Trop loin' }) end
    local pr, list = buyerPrices(b), {}
    for item, price in pairs(pr) do local n = have(src, item) if n > 0 then list[#list + 1] = { item = item, count = n, price = price } end end
    cb({ ok = true, list = list, label = b.label })
end)

ESX.RegisterServerCallback('pickax_life:buyerSell', function(src, cb, idx, item, qty)
    local x = ESX.GetPlayerFromId(src)
    local b = C.Buyers[tonumber(idx) or 0]
    if not x or not b or not near(src, b.coords, b.Distance + 3.0) then return cb({ ok = false, error = 'Trop loin' }) end
    local pr = buyerPrices(b)
    item = tostring(item or '')
    qty = clamp(math.floor(tonumber(qty) or 0), 1, 200)
    if not pr[item] or have(src, item) < qty then return cb({ ok = false, error = 'Rien à vendre' }) end
    exports.ox_inventory:RemoveItem(src, item, qty)
    local total = pr[item] * qty
    x.addAccountMoney(b.Account, total)
    cb({ ok = true, msg = ('%d × %s vendu(s) : %d $'):format(qty, item, total) })
end)

-- ═══════════════ Cuisine ═══════════════
local K = C.Cooking
local function lbl(n) local ok, it = pcall(function() return exports.ox_inventory:Items(n) end) return (ok and it and it.label) or n end
local CookXP = {}   -- identifiant -> XP de cuisinier

MySQL.ready(function()
    MySQL.query.await('CREATE TABLE IF NOT EXISTS pickax_cooking (identifier VARCHAR(60) NOT NULL PRIMARY KEY, xp INT NOT NULL DEFAULT 0)')
end)

local function cookId(src) local x = ESX.GetPlayerFromId(src) return x and x.identifier end
local function getXP(src)
    local id = cookId(src)
    if not id then return 0 end
    if CookXP[id] == nil then
        local r = MySQL.scalar.await('SELECT xp FROM pickax_cooking WHERE identifier = ?', { id })
        CookXP[id] = tonumber(r) or 0
    end
    return CookXP[id]
end
local function addXP(src, n)
    local id = cookId(src)
    if not id then return end
    CookXP[id] = getXP(src) + n
    MySQL.update('INSERT INTO pickax_cooking (identifier, xp) VALUES (?, ?) ON DUPLICATE KEY UPDATE xp = ?', { id, CookXP[id], CookXP[id] })
end
local function levelOf(xp)
    local lv = 1
    for i, need in ipairs(K.Levels) do if xp >= need then lv = i end end
    return lv, K.Levels[lv + 1]
end
local function recipeById(id) for _, r in ipairs(K.Recipes) do if r.id == id then return r end end end
local function stationOk(st, rec) return st.type == 'all' or st.type == rec.station end
local function stationAt(src, idx)
    local st = K.Stations[tonumber(idx) or 0]
    if not st or not ESX.GetPlayerFromId(src) or not near(src, st.coords, K.Distance + 3.0) then return nil end
    return st
end
local function stepCfg(rec, i)
    local st = rec.steps[i]
    local cfg = { title = st.title, sub = st.sub, seconds = st.seconds or 20, rounds = st.rounds, size = st.size, speed = st.speed, difficulty = st.difficulty, seed = math.random(1, 2147483000) }
    return { game = st.game, cfg = cfg, n = i, total = #rec.steps }
end

-- Liste des recettes d'un poste (niveau, ingrédients possédés)
ESX.RegisterServerCallback('pickax_life:cookInfo', function(src, cb, idx)
    local st = stationAt(src, idx)
    if not st then return cb({ ok = false, error = 'Trop loin' }) end
    local xp = getXP(src)
    local lv, nextXp = levelOf(xp)
    local list = {}
    for _, r in ipairs(K.Recipes) do
        if stationOk(st, r) then
            local needs, ok = {}, true
            for _, n in ipairs(r.needs) do
                local h = have(src, n[1])
                if h < n[2] then ok = false end
                needs[#needs + 1] = { item = n[1], label = lbl(n[1]), count = n[2], have = h }
            end
            list[#list + 1] = { id = r.id, label = r.label, level = r.level, locked = r.level > lv, can = ok, needs = needs, steps = #r.steps }
        end
    end
    cb({ ok = true, label = st.label, type = st.type, typeLabel = K.StationLabel[st.type], level = lv, xp = xp, nextXp = nextXp, list = list })
end)

ESX.RegisterServerCallback('pickax_life:cookBegin', function(src, cb, idx, rid)
    local st = stationAt(src, idx)
    if not st then return cb({ ok = false, error = 'Trop loin' }) end
    local rec = recipeById(rid)
    if not rec or not stationOk(st, rec) then return cb({ ok = false, error = 'Recette impossible ici' }) end
    local lv = levelOf(getXP(src))
    if rec.level > lv then return cb({ ok = false, error = ('Niveau de cuisinier %d requis'):format(rec.level) }) end
    for _, n in ipairs(rec.needs) do if have(src, n[1]) < n[2] then return cb({ ok = false, error = ('Il te manque : %s ×%d'):format(lbl(n[1]), n[2]) }) end end
    if not exports.ox_inventory:CanCarryItem(src, rec.out, 1) then return cb({ ok = false, error = 'Tu ne peux pas porter plus' }) end
    Pending[src] = { kind = 'cook', rec = rec, step = 1, scores = {}, at = GetGameTimer(), stAt = GetGameTimer() }
    local s = stepCfg(rec, 1)
    s.ok = true
    s.anim = st.type
    cb(s)
end)

-- Résultat d'une étape : passe à la suivante ou termine le plat
ESX.RegisterServerCallback('pickax_life:cookStep', function(src, cb, score)
    local p = Pending[src]
    if not p or p.kind ~= 'cook' then return cb({ ok = false, error = 'Aucune préparation en cours' }) end
    local rec = p.rec
    local stp = rec.steps[p.step]
    local minMs = (stp.game == 'hold' and (stp.seconds or 20) * 600) or 2500
    if GetGameTimer() - p.stAt < minMs then Pending[src] = nil return cb({ ok = false, error = 'Trop rapide' }) end
    p.scores[#p.scores + 1] = clamp(math.floor(tonumber(score) or 0), 0, 100)
    if p.step < #rec.steps then
        p.step = p.step + 1
        p.stAt = GetGameTimer()
        local s = stepCfg(rec, p.step)
        s.ok = true
        return cb(s)
    end
    Pending[src] = nil
    for _, n in ipairs(rec.needs) do if have(src, n[1]) < n[2] then return cb({ ok = false, error = 'Ingrédients manquants' }) end end
    for _, n in ipairs(rec.needs) do exports.ox_inventory:RemoveItem(src, n[1], n[2]) end
    -- Qualité = moyenne des étapes ; une cuisson (hold) sous le seuil brûle le plat
    local sum, burnt = 0, false
    for i, sc in ipairs(p.scores) do
        sum = sum + sc
        if rec.steps[i].game == 'hold' and sc < K.Min then burnt = true end
    end
    local q = sum / #p.scores
    local lv = levelOf(getXP(src))
    q = clamp(math.floor(q + (lv - 1) * (K.QualityBonusPerLevel or 0)), 0, 100)
    if burnt or q < K.Min then
        exports.ox_inventory:AddItem(src, K.Burnt, 1)
        addXP(src, K.XP.Burnt)
        return cb({ ok = true, done = true, failed = true, msg = 'Plat brûlé…' })
    end
    exports.ox_inventory:AddItem(src, rec.out, 1, { quality = q, label = ('%s (%d %%)'):format(rec.label, q) })
    xp(src, 'cook')
    local gain = K.XP.Dish + (q >= 90 and K.XP.Perfect or 0)
    local before = levelOf(getXP(src))
    addXP(src, gain)
    local after = levelOf(getXP(src))
    cb({ ok = true, done = true, msg = ('%s prêt (qualité %d %%). +%d XP%s'):format(rec.label, q, gain, after > before and (' · niveau %d !'):format(after) or '') })
end)

ESX.RegisterServerCallback('pickax_life:cookCancel', function(src, cb) Pending[src] = nil cb(true) end)

-- Marché aux ingrédients
ESX.RegisterServerCallback('pickax_life:marketList', function(src, cb)
    local M = K.Market
    if not ESX.GetPlayerFromId(src) or not near(src, M.coords, M.Distance + 3.0) then return cb({ ok = false, error = 'Trop loin' }) end
    local list = {}
    for item, price in pairs(M.Items) do list[#list + 1] = { item = item, label = lbl(item), price = price, have = have(src, item) } end
    table.sort(list, function(a, b) return a.item < b.item end)
    cb({ ok = true, label = M.label, list = list })
end)
ESX.RegisterServerCallback('pickax_life:marketBuy', function(src, cb, item, qty)
    local M = K.Market
    local x = ESX.GetPlayerFromId(src)
    if not x or not near(src, M.coords, M.Distance + 3.0) then return cb({ ok = false, error = 'Trop loin' }) end
    item = tostring(item or '')
    qty = clamp(math.floor(tonumber(qty) or 0), 1, 50)
    local price = M.Items[item]
    if not price then return cb({ ok = false, error = 'Article inconnu' }) end
    local total = price * qty
    if x.getAccount(M.Account).money < total then return cb({ ok = false, error = ('Il te faut %d $'):format(total) }) end
    if not exports.ox_inventory:CanCarryItem(src, item, qty) then return cb({ ok = false, error = 'Tu ne peux pas porter plus' }) end
    x.removeAccountMoney(M.Account, total)
    exports.ox_inventory:AddItem(src, item, qty)
    cb({ ok = true, msg = ('%d × %s acheté(s) : %d $'):format(qty, lbl(item), total) })
end)

-- Commandes de clients (renouvelées régulièrement, partagées entre les cuisiniers)
local Orders, OrdersAt = {}, 0
local function refreshOrders()
    Orders = {}
    OrdersAt = os.time()
    if not (K.Orders and K.Orders.Enabled) then return end
    local pool = {}
    for _, r in ipairs(K.Recipes) do pool[#pool + 1] = r end
    for i = 1, math.min(K.Orders.Count, #pool) do
        local k = math.random(#pool)
        local r = table.remove(pool, k)
        Orders[#Orders + 1] = { id = i, rid = r.id, label = r.label, out = r.out, left = math.random(1, 3), value = r.value or 60, min = K.Orders.MinQuality }
    end
end
local function ensureOrders()
    if os.time() - OrdersAt > (K.Orders.RefreshMinutes or 40) * 60 or #Orders == 0 then refreshOrders() end
end

local function dishSlot(src, name)
    local slots = exports.ox_inventory:Search(src, 'slots', name) or {}
    local best
    for _, sl in ipairs(slots) do
        local q = sl.metadata and tonumber(sl.metadata.quality) or 0
        if not best or q > best.q then best = { slot = sl.slot, q = q } end
    end
    return best
end

ESX.RegisterServerCallback('pickax_life:ordersList', function(src, cb, idx)
    if not stationAt(src, idx) then return cb({ ok = false, error = 'Trop loin' }) end
    ensureOrders()
    local out = {}
    for _, o in ipairs(Orders) do
        local d = dishSlot(src, o.out)
        out[#out + 1] = { id = o.id, label = o.label, left = o.left, min = o.min, pay = math.floor(o.value * K.Orders.PayMult), have = d and d.q or nil }
    end
    cb({ ok = true, list = out, minutes = math.max(0, math.floor(((K.Orders.RefreshMinutes or 40) * 60 - (os.time() - OrdersAt)) / 60)) })
end)

ESX.RegisterServerCallback('pickax_life:orderDeliver', function(src, cb, idx, oid)
    local x = ESX.GetPlayerFromId(src)
    if not x or not stationAt(src, idx) then return cb({ ok = false, error = 'Trop loin' }) end
    local o
    for _, v in ipairs(Orders) do if v.id == tonumber(oid) then o = v end end
    if not o or o.left <= 0 then return cb({ ok = false, error = 'Commande déjà servie' }) end
    local d = dishSlot(src, o.out)
    if not d then return cb({ ok = false, error = 'Tu n\'as pas ce plat' }) end
    if d.q < o.min then return cb({ ok = false, error = ('Qualité insuffisante (%d %% requis)'):format(o.min) }) end
    if not exports.ox_inventory:RemoveItem(src, o.out, 1, nil, d.slot) then return cb({ ok = false, error = 'Impossible' }) end
    o.left = o.left - 1
    local pay = math.floor(o.value * K.Orders.PayMult * (1 + (d.q - o.min) / 100 * K.Orders.QualityBonus))
    x.addAccountMoney(K.Orders.Account, pay)
    addXP(src, K.XP.Order)
    cb({ ok = true, msg = ('%s livré (qualité %d %%) : %d $ · +%d XP'):format(o.label, d.q, pay, K.XP.Order) })
end)

-- ═══════════════ Taxi et livraison ═══════════════
local function jobKind(x)
    for kind, names in pairs(C.Runs.Jobs) do for _, n in ipairs(names) do if x.job.name == n then return kind end end end
    if GetResourceState('pickax_jobbuilder') == 'started' then
        local ok, t = pcall(function() return exports.pickax_jobbuilder:GetJobType(x.job.name) end)
        if ok and t then for kind, types in pairs(C.Runs.JobTypes or {}) do for _, ty in ipairs(types) do if t == ty then return kind end end end end
    end
end

local function pickPoint(from, minD)
    for _ = 1, 20 do
        local p = C.Runs.Locations[math.random(#C.Runs.Locations)]
        if not from or #(p - from) >= minD then return p end
    end
    return C.Runs.Locations[math.random(#C.Runs.Locations)]
end

ESX.RegisterServerCallback('pickax_life:runToggle', function(src, cb)
    local x = ESX.GetPlayerFromId(src)
    if not x then return cb({ ok = false }) end
    if Runs[src] then Runs[src] = nil return cb({ ok = true, stopped = true, msg = 'Service terminé.' }) end
    local kind = jobKind(x)
    if not kind then return cb({ ok = false, error = 'Ton métier ne permet pas les courses' }) end
    local R = C.Runs
    if #R.Locations == 0 or (kind == 'delivery' and not R.DepotDelivery) then return cb({ ok = false, error = 'Courses non configurées (Config.Runs : points manquants)' }) end
    local start = kind == 'delivery' and R.DepotDelivery or GetEntityCoords(GetPlayerPed(src))
    local pickup = kind == 'delivery' and R.DepotDelivery or pickPoint(start, 150.0)
    local drop = pickPoint(pickup, R.Min[kind])
    Runs[src] = { kind = kind, stage = kind == 'delivery' and 'load' or 'pickup', pickup = pickup, drop = drop, at = os.time(), total = 0, count = 0, dist0 = #(pickup - drop) }
    cb({ ok = true, run = { kind = kind, stage = Runs[src].stage, target = Runs[src].stage == 'load' and R.DepotDelivery or pickup } })
end)

ESX.RegisterServerCallback('pickax_life:runArrive', function(src, cb, stats)
    local x = ESX.GetPlayerFromId(src)
    local run = Runs[src]
    local R = C.Runs
    if not x or not run then return cb({ ok = false, error = 'Aucune course en cours' }) end
    local ped = GetPlayerPed(src)
    local target = (run.stage == 'pickup' or run.stage == 'load') and run.pickup or run.drop
    if #(GetEntityCoords(ped) - target) > R.StopRadius + 6.0 then return cb({ ok = false, error = 'Pas encore arrivé' }) end
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetEntitySpeed(veh) > R.MaxArriveSpeed + 3.0 then return cb({ ok = false, error = 'Arrête-toi à l\'arrivée' }) end
    if run.stage == 'pickup' or run.stage == 'load' then
        run.stage, run.legStart, run.legAt = 'drop', os.time(), os.time()
        return cb({ ok = true, next = { stage = 'drop', target = run.drop }, msg = run.kind == 'taxi' and 'Client à bord : direction la destination.' or 'Colis chargés : livre-les à l\'adresse indiquée.' })
    end
    -- fin de course : durée plausible (≥ distance / 45 m/s)
    local dist = #(run.pickup - run.drop)
    local elapsed = os.time() - (run.legAt or run.at)
    if elapsed < dist / 45.0 then return cb({ ok = false, error = 'Course trop rapide : refusée' }) end
    stats = type(stats) == 'table' and stats or {}
    local damage, hard = clamp(tonumber(stats.damage) or 0, 0, 1000), clamp(math.floor(tonumber(stats.hard) or 0), 0, 30)
    local base = R.Base[run.kind] + dist / 100 * R.Rate[run.kind]
    local comfort = clamp(1 - damage / 400 - hard * 0.03, 0, 1)
    local tip = math.floor(base * R.TipMax * comfort)
    local pay = math.floor(base) + tip
    x.addAccountMoney(R.Account, pay)
    run.total, run.count = run.total + pay, run.count + 1
    local nextDrop = pickPoint(run.drop, R.Min[run.kind])
    run.pickup, run.drop = run.kind == 'delivery' and R.DepotDelivery or run.drop, nextDrop
    run.stage = run.kind == 'delivery' and 'load' or 'pickup'
    if run.kind == 'taxi' then run.pickup = pickPoint(GetEntityCoords(ped), 150.0) run.drop = pickPoint(run.pickup, R.Min.taxi) end
    xp(src, 'run')
    cb({ ok = true, pay = pay, tip = tip, comfort = math.floor(comfort * 100), next = { stage = run.stage, target = run.stage == 'load' and R.DepotDelivery or run.pickup },
        msg = ('Course terminée : %d $ (dont %d $ de pourboire, conduite %d %%).'):format(pay, tip, math.floor(comfort * 100)) })
end)

AddEventHandler('playerDropped', function() Pending[source] = nil Runs[source] = nil end)
