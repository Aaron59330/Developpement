-- ─────────────────────────────── Vie quotidienne : permis, pêche, chasse, cuisine, taxi / livraison ───────────────────────────────
local ESX = exports['es_extended']:getSharedObject()
local C = Config
local Pending, Quota, Skinned, Runs = {}, {}, {}, {}

local function clamp(v, a, b) return math.max(a, math.min(b, v)) end
local function have(src, item) return exports.ox_inventory:GetItemCount(src, item) or 0 end
local function near(src, c, d) return #(GetEntityCoords(GetPlayerPed(src)) - c) <= d end
local function notify(src, kind, txt) TriggerClientEvent('ox_lib:notify', src, { type = kind, description = txt }) end

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
ESX.RegisterServerCallback('pickax_life:cookBegin', function(src, cb, idx, rid)
    local K = C.Cooking
    local st = K.Stations[tonumber(idx) or 0]
    if not ESX.GetPlayerFromId(src) or not st or not near(src, st.coords, K.Distance + 3.0) then return cb({ ok = false, error = 'Trop loin' }) end
    local rec
    for _, r in ipairs(K.Recipes) do if r.id == rid then rec = r end end
    if not rec then return cb({ ok = false, error = 'Recette inconnue' }) end
    for _, n in ipairs(rec.needs) do if have(src, n[1]) < n[2] then return cb({ ok = false, error = ('Il te manque : %s ×%d'):format(n[1], n[2]) }) end end
    if not exports.ox_inventory:CanCarryItem(src, rec.out, 1) then return cb({ ok = false, error = 'Tu ne peux pas porter plus' }) end
    Pending[src] = { kind = 'cook', rec = rec, at = GetGameTimer() }
    cb({ ok = true, cfg = { title = 'Cuisson : ' .. rec.label, sub = 'Garde la bonne température', seconds = rec.seconds, size = 0.26, speed = rec.speed, seed = math.random(1, 2147483000) } })
end)

ESX.RegisterServerCallback('pickax_life:cookEnd', function(src, cb, score)
    local p = Pending[src]
    Pending[src] = nil
    if not p or p.kind ~= 'cook' then return cb({ ok = false, error = 'Aucune cuisson en cours' }) end
    if GetGameTimer() - p.at < 6000 then return cb({ ok = false, error = 'Trop rapide' }) end
    for _, n in ipairs(p.rec.needs) do if have(src, n[1]) < n[2] then return cb({ ok = false, error = 'Ingrédients manquants' }) end end
    for _, n in ipairs(p.rec.needs) do exports.ox_inventory:RemoveItem(src, n[1], n[2]) end
    score = clamp(math.floor(tonumber(score) or 0), 0, 100)
    if score < C.Cooking.Min then exports.ox_inventory:AddItem(src, C.Cooking.Burnt, 1) return cb({ ok = true, failed = true, msg = 'Plat brûlé…' }) end
    exports.ox_inventory:AddItem(src, p.rec.out, 1, { quality = score, label = ('%s (%d %%)'):format(p.rec.label, score) })
    cb({ ok = true, msg = ('%s prêt (qualité %d %%).'):format(p.rec.label, score) })
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
    cb({ ok = true, pay = pay, tip = tip, comfort = math.floor(comfort * 100), next = { stage = run.stage, target = run.stage == 'load' and R.DepotDelivery or run.pickup },
        msg = ('Course terminée : %d $ (dont %d $ de pourboire, conduite %d %%).'):format(pay, tip, math.floor(comfort * 100)) })
end)

AddEventHandler('playerDropped', function() Pending[source] = nil Runs[source] = nil end)
