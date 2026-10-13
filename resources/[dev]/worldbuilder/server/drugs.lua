-- ─────────────────────────────── Drogues : récolte, laboratoires, vente, blanchiment ───────────────────────────────
local Uses = {}      -- [eid:pi] = { uses, resetAt } épuisement global d'un point de récolte

local function resolve(src, eid, pi, kind, skipCops)
    local e = WB.Entities[tonumber(eid) or 0]
    local xPlayer = ESX.GetPlayerFromId(src)
    if not e or e.type ~= 'drug' or not e.enabled or not xPlayer then return nil, 'Introuvable' end
    local idx = tonumber(pi) or 0
    local p = e.points[idx]
    if not p or p.kind ~= kind or not p.coords or not WB.near(src, p.coords, 4.0) then return nil, 'Trop loin' end
    local ok, err = WB.hasAccess(xPlayer, p.access)
    if not ok then return nil, err end
    if not skipCops then
        local need = math.max(p.copsRequired or 0, e.settings.copsRequired or 0)
        if need > 0 and WB.copCount() < need then return nil, 'Impossible pour le moment (pas assez de policiers en service)' end
    end
    return e, p, xPlayer, idx
end

local function roll(a, b)
    a, b = math.floor(a or 0), math.floor(b or 0)
    if b < a then b = a end
    return math.random(a, b)
end

local function maybeAlert(p, e)
    if (p.alertChance or 0) > 0 and math.random(100) <= p.alertChance then
        WB.alertPolice(p.coords, 'Activité suspecte', ('Activité de drogue suspectée (%s)'):format(p.label ~= '' and p.label or e.label))
    end
end

local function hourly(prefix, xPlayer, eid, pi, limit)
    local c = WB.counter(('%s:%s:%d:%d'):format(prefix, xPlayer.identifier, eid, pi), 3600)
    return c, limit > 0 and math.max(0, limit - c.n) or math.huge
end

-- ═══════════════ Début d'une action chronométrée (récolte / fabrication) ═══════════════
ESX.RegisterServerCallback('worldbuilder:drug:begin', function(src, cb, eid, pi, kind, recipeIdx, batches)
    if WB.Pending[src] then return cb({ ok = false, error = 'Action déjà en cours' }) end
    if kind ~= 'harvest' and kind ~= 'process' then return cb({ ok = false, error = 'Action invalide' }) end
    local e, p, xPlayer, idx = resolve(src, eid, pi, kind)
    if not e then return cb({ ok = false, error = p }) end

    if kind == 'harvest' then
        local h = p.harvest
        if not h or h.item == '' then return cb({ ok = false, error = 'Point mal configuré' }) end
        if h.tool and h.tool.item ~= '' and WB.itemCount(src, h.tool.item) < 1 then return cb({ ok = false, error = 'Il te faut : ' .. h.tool.item }) end
        local now = os.time()
        local key = ('%d:%d'):format(e.id, idx)
        if (h.maxUses or 0) > 0 then
            local u = Uses[key]
            if u and u.uses >= h.maxUses then
                if now >= u.resetAt then Uses[key] = nil else return cb({ ok = false, error = 'Il n\'y a plus rien à récolter ici pour le moment' }) end
            end
        end
        local cd = WB.counter(('cd:%s:%s'):format(xPlayer.identifier, key), math.max(1, h.cooldown or 0))
        if (h.cooldown or 0) > 0 and cd.n > 0 then return cb({ ok = false, error = 'Attends un peu avant de recommencer' }) end
        WB.beginAct(src, { kind = 'drug', sub = 'harvest', eid = e.id, pi = idx }, h.time)
        return cb({ ok = true, seconds = h.time, anim = h.anim, label = p.label ~= '' and p.label or 'Récolte' })
    end

    local r = (p.recipes or {})[tonumber(recipeIdx) or 0]
    if not r then return cb({ ok = false, error = 'Recette inconnue' }) end
    batches = math.max(1, math.min(10, math.floor(tonumber(batches) or 1)))
    if r.tool and r.tool.item ~= '' and WB.itemCount(src, r.tool.item) < 1 then return cb({ ok = false, error = 'Il te faut : ' .. r.tool.item }) end
    for _, inp in ipairs(r.inputs) do
        if WB.itemCount(src, inp.item) < inp.count * batches then return cb({ ok = false, error = ('Il te manque : %s ×%d'):format(inp.item, inp.count * batches) }) end
    end
    for _, out in ipairs(r.outputs) do
        if not WB.canCarry(src, out.item, out.count * batches) then return cb({ ok = false, error = 'Tu ne peux pas porter autant' }) end
    end
    local secs = r.time * batches
    WB.beginAct(src, { kind = 'drug', sub = 'process', eid = e.id, pi = idx, recipe = tonumber(recipeIdx), batches = batches }, secs)
    cb({ ok = true, seconds = secs, anim = r.anim, label = r.label ~= '' and r.label or 'Fabrication' })
end)

RegisterNetEvent('worldbuilder:server:drugFinish', function(done)
    local src = source
    local a, err = WB.endAct(src, 'drug')
    local xPlayer = ESX.GetPlayerFromId(src)
    local e = a and WB.Entities[a.eid]
    if not a or not e or not xPlayer then if err then WB.notify(src, err, 'error') end return end
    if done ~= true then return end
    local p = e.points[a.pi]
    if not p or not p.coords or not WB.near(src, p.coords, 6.0) then return end

    if a.sub == 'harvest' then
        local h = p.harvest
        local n = roll(h.min, h.max)
        if h.tool and h.tool.item ~= '' then
            if WB.itemCount(src, h.tool.item) < 1 then return WB.notify(src, 'Il te faut : ' .. h.tool.item, 'error') end
            if h.tool.consume then WB.removeItem(src, h.tool.item, 1) end
        end
        if not WB.addItem(src, h.item, n) then return WB.notify(src, 'Tu ne peux pas porter plus.', 'error') end
        local key = ('%d:%d'):format(e.id, a.pi)
        if (h.maxUses or 0) > 0 then
            local u = Uses[key] or { uses = 0, resetAt = 0 }
            u.uses = u.uses + 1
            if u.uses >= h.maxUses then u.resetAt = os.time() + (h.regen or 300) end
            Uses[key] = u
        end
        WB.counter(('cd:%s:%s'):format(xPlayer.identifier, key), math.max(1, h.cooldown or 0)).n = 1
        maybeAlert(p, e)
        WB.stat(e, 'harvested', n)
        WB.log(e, xPlayer, 'harvest', ('%s ×%d'):format(h.item, n), n)
        WB.notify(src, ('Tu as récolté %d × %s'):format(n, h.item), 'success')
        return
    end

    local r = (p.recipes or {})[a.recipe]
    if not r then return end
    if r.tool and r.tool.item ~= '' then
        if WB.itemCount(src, r.tool.item) < 1 then return WB.notify(src, 'Il te faut : ' .. r.tool.item, 'error') end
    end
    for _, inp in ipairs(r.inputs) do
        if WB.itemCount(src, inp.item) < inp.count * a.batches then return WB.notify(src, 'Ingrédients manquants', 'error') end
    end
    for _, inp in ipairs(r.inputs) do WB.removeItem(src, inp.item, inp.count * a.batches) end
    if r.tool and r.tool.item ~= '' and r.tool.consume then WB.removeItem(src, r.tool.item, 1) end
    local made, failed = 0, 0
    for _ = 1, a.batches do
        if math.random(100) <= (r.failChance or 0) then failed = failed + 1
        else
            made = made + 1
            for _, out in ipairs(r.outputs) do WB.addItem(src, out.item, out.count) end
        end
    end
    maybeAlert(p, e)
    WB.stat(e, 'crafted', made)
    WB.log(e, xPlayer, 'process', ('%s ×%d (%d raté)'):format(r.label ~= '' and r.label or 'recette', made, failed), made)
    if failed > 0 then WB.notify(src, ('%d lot(s) raté(s) : ingrédients perdus.'):format(failed), 'error') end
    if made > 0 then WB.notify(src, ('Fabrication terminée : %d lot(s).'):format(made), 'success') end
end)

-- ═══════════════ Laboratoire : liste des recettes ═══════════════
ESX.RegisterServerCallback('worldbuilder:drug:processInfo', function(src, cb, eid, pi)
    local e, p, xPlayer = resolve(src, eid, pi, 'process')
    if not e then return cb({ ok = false, error = p }) end
    local list = {}
    for i, r in ipairs(p.recipes or {}) do
        local ins, outs = {}, {}
        local max = 10
        for _, inp in ipairs(r.inputs) do
            local have = WB.itemCount(src, inp.item)
            ins[#ins + 1] = { item = inp.item, count = inp.count, have = have }
            max = math.min(max, math.floor(have / inp.count))
        end
        for _, out in ipairs(r.outputs) do outs[#outs + 1] = { item = out.item, count = out.count } end
        list[#list + 1] = { i = i, label = r.label ~= '' and r.label or ('Recette ' .. i), inputs = ins, outputs = outs, time = r.time, failChance = r.failChance or 0,
            tool = (r.tool and r.tool.item ~= '') and r.tool.item or nil, max = math.max(0, max) }
    end
    cb({ ok = true, label = p.label ~= '' and p.label or e.label, recipes = list })
end)

-- ═══════════════ Vente (dealer) ═══════════════
local ACCOUNT = { black_money = 'black_money', money = 'money', bank = 'bank' }

ESX.RegisterServerCallback('worldbuilder:drug:sellInfo', function(src, cb, eid, pi)
    local e, p, xPlayer, idx = resolve(src, eid, pi, 'sell')
    if not e then return cb({ ok = false, error = p }) end
    local s = p.sell
    local _, left = hourly('sell', xPlayer, e.id, idx, s.maxPerHour or 0)
    local list = {}
    for _, it in ipairs(s.items or {}) do
        list[#list + 1] = { item = it.item, min = it.min, max = it.max, have = WB.itemCount(src, it.item) }
    end
    cb({ ok = true, label = p.label ~= '' and p.label or e.label, items = list, account = s.currency, left = left == math.huge and -1 or left })
end)

ESX.RegisterServerCallback('worldbuilder:drug:sell', function(src, cb, eid, pi, item, qty)
    local e, p, xPlayer, idx = resolve(src, eid, pi, 'sell')
    if not e then return cb({ ok = false, error = p }) end
    local s = p.sell
    local entry
    for _, it in ipairs(s.items or {}) do if it.item == item then entry = it end end
    if not entry then return cb({ ok = false, error = 'Le dealer n\'achète pas ça' }) end
    qty = math.floor(tonumber(qty) or 0)
    if qty < 1 then return cb({ ok = false, error = 'Quantité invalide' }) end
    qty = math.min(qty, WB.itemCount(src, item))
    if qty < 1 then return cb({ ok = false, error = 'Tu n\'en as pas' }) end
    local c, left = hourly('sell', xPlayer, e.id, idx, s.maxPerHour or 0)
    if left ~= math.huge then
        if left < 1 then return cb({ ok = false, error = 'Le dealer n\'en veut plus pour le moment' }) end
        qty = math.min(qty, left)
    end
    local unit = roll(entry.min, entry.max)
    local total = unit * qty
    if not WB.removeItem(src, item, qty) then return cb({ ok = false, error = 'Erreur' }) end
    c.n = c.n + qty
    WB.pay(xPlayer, ACCOUNT[s.currency] or 'black_money', total, 'Vente : ' .. item)
    maybeAlert(p, e)
    WB.stat(e, 'revenue', total) WB.stat(e, 'sold', qty)
    WB.log(e, xPlayer, 'sell', ('%s ×%d à %d'):format(item, qty, unit), total)
    cb({ ok = true, qty = qty, unit = unit, total = total })
end)

-- ═══════════════ Blanchiment ═══════════════
local function launderSource(xPlayer, from)
    if ACCOUNT[from] then
        local a = xPlayer.getAccount(ACCOUNT[from])
        return a and a.money or 0, true
    end
    return WB.itemCount(xPlayer.source, from), false
end

ESX.RegisterServerCallback('worldbuilder:drug:launderInfo', function(src, cb, eid, pi)
    local e, p, xPlayer, idx = resolve(src, eid, pi, 'launder')
    if not e then return cb({ ok = false, error = p }) end
    local l = p.launder
    local have = launderSource(xPlayer, l.from)
    local _, left = hourly('launder', xPlayer, e.id, idx, l.maxPerHour or 0)
    cb({ ok = true, label = p.label ~= '' and p.label or e.label, rate = l.rate, min = l.min, max = l.max, have = have, from = l.from, to = l.to, left = left == math.huge and -1 or left })
end)

ESX.RegisterServerCallback('worldbuilder:drug:launder', function(src, cb, eid, pi, amount)
    local e, p, xPlayer, idx = resolve(src, eid, pi, 'launder')
    if not e then return cb({ ok = false, error = p }) end
    local l = p.launder
    amount = math.floor(tonumber(amount) or 0)
    if amount < math.max(1, l.min or 0) then return cb({ ok = false, error = ('Minimum : %d'):format(math.max(1, l.min or 0)) }) end
    if (l.max or 0) > 0 and amount > l.max then amount = l.max end
    local have, isAccount = launderSource(xPlayer, l.from)
    if have < amount then return cb({ ok = false, error = 'Tu n\'as pas assez' }) end
    local c, left = hourly('launder', xPlayer, e.id, idx, l.maxPerHour or 0)
    if left ~= math.huge and left < amount then return cb({ ok = false, error = ('Limite horaire atteinte (reste %d)'):format(left) }) end
    if isAccount then xPlayer.removeAccountMoney(ACCOUNT[l.from], amount, 'Blanchiment')
    elseif not WB.removeItem(src, l.from, amount) then return cb({ ok = false, error = 'Erreur' }) end
    c.n = c.n + amount
    local got = math.floor(amount * (l.rate or 70) / 100)
    WB.pay(xPlayer, ACCOUNT[l.to] or 'money', got, 'Blanchiment')
    maybeAlert(p, e)
    WB.stat(e, 'laundered', amount)
    WB.log(e, xPlayer, 'launder', ('%d → %d'):format(amount, got), got)
    cb({ ok = true, given = amount, received = got })
end)

-- ═══════════════ Portes (entrée / sortie de laboratoire) ═══════════════
ESX.RegisterServerCallback('worldbuilder:drug:door', function(src, cb, eid, pi, dir)
    local e = WB.Entities[tonumber(eid) or 0]
    local xPlayer = ESX.GetPlayerFromId(src)
    if not e or e.type ~= 'drug' or not e.enabled or not xPlayer then return cb({ ok = false, error = 'Introuvable' }) end
    local p = e.points[tonumber(pi) or 0]
    if not p or p.kind ~= 'door' or not p.coords or not p.inside then return cb({ ok = false, error = 'Introuvable' }) end
    local from, to = p.coords, p.inside
    if dir == 'out' then from, to = p.inside, p.coords end
    if not WB.near(src, from, 4.0) then return cb({ ok = false, error = 'Trop loin' }) end
    if dir ~= 'out' then
        local ok, err = WB.hasAccess(xPlayer, p.access)
        if not ok then return cb({ ok = false, error = err }) end
    end
    cb({ ok = true, to = to })
end)
