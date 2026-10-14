-- ─────────────────────────────── Activités illégales : récolte → traitement → vente / blanchiment ───────────────────────────────
-- Récolte (ex. feuilles de coca) → Traitement (recettes : ingrédients → produit) → Point de vente (argent sale) → Blanchiment (argent sale → propre).
-- Les durées sont contrôlées côté serveur (Config.Activities.Grace) : le client ne peut pas raccourcir une action.

local function fail(msg) return { ok = false, error = msg } end

local cooldowns = {}   -- ['<identifier>:<kind>:<pointId>'] = timestamp de fin

local function cdKey(xPlayer, kind, pointId) return ('%s:%s:%s'):format(xPlayer.identifier, kind, pointId) end
local function cdLeft(key) return math.max(0, (cooldowns[key] or 0) - os.time()) end

-- Valeurs effectives : point > gang > config
local function sellAccount(point)
    local a = point.data.account
    return (a == 'dirty' or a == 'money' or a == 'bank') and a or Config.Activities.SellAccount
end

local function sellCut(point, gang)
    local c = tonumber(point.data.gang_cut)
    if c and c >= 0 then return c end
    c = tonumber(gang.settings.sell_cut)
    if c and c >= 0 then return c end
    return Config.Activities.SellGangCut
end

local function launderCfg(point)
    local d, A = point.data, Config.Activities
    local fee = tonumber(d.fee)
    local cut = tonumber(d.gang_cut)
    local min, max, seconds = tonumber(d.min) or 0, tonumber(d.max) or 0, tonumber(d.seconds) or 0
    return {
        fee = (fee and fee >= 0) and fee or A.LaunderFee,
        gangCut = (cut and cut >= 0) and cut or A.LaunderGangCut,
        min = min > 0 and min or A.LaunderMin,
        max = max > 0 and max or A.LaunderMax,
        seconds = seconds > 0 and seconds or A.LaunderSeconds,
    }
end

local function recipeAvailable(src, xPlayer, recipe)
    local make = 9999
    local inputs = {}
    for _, i in ipairs(recipe.inputs) do
        local have = GB.itemCount(src, xPlayer, i.name)
        make = math.min(make, math.floor(have / i.count))
        inputs[#inputs + 1] = { name = i.name, label = i.label, count = i.count, have = have }
    end
    return make, inputs
end

-- ─────────────────────────────── Ouverture d'un point d'activité ───────────────────────────────
function GB.openActivity(src, xPlayer, point, gang, grade, cb)
    local d = point.data
    if point.type == 'harvest' then
        local toolOk = true
        if d.tool and d.tool ~= '' then toolOk = GB.itemCount(src, xPlayer, d.tool) > 0 end
        cb({
            ok = true, kind = 'harvest', label = point.label, item = { name = d.name, label = d.label }, count = d.count, seconds = d.seconds,
            cooldownLeft = cdLeft(cdKey(xPlayer, 'harvest', point.id)), tool = d.tool ~= '' and d.tool or nil, toolOk = toolOk, have = GB.itemCount(src, xPlayer, d.name),
        })

    elseif point.type == 'process' then
        local list = {}
        for i, r in ipairs(d.recipes) do
            if grade >= r.min_grade then
                local make, inputs = recipeAvailable(src, xPlayer, r)
                list[#list + 1] = { idx = i, label = r.label, seconds = r.seconds, chance = r.chance or 100, output = r.output, inputs = inputs, make = math.min(make, Config.Activities.MaxBatch) }
            end
        end
        cb({ ok = true, kind = 'process', label = point.label, recipes = list, maxBatch = Config.Activities.MaxBatch })

    elseif point.type == 'sell' then
        local list = {}
        for i, it in ipairs(d.items) do
            if grade >= it.min_grade then list[#list + 1] = { idx = i, name = it.name, label = it.label, price = it.price, have = GB.itemCount(src, xPlayer, it.name) } end
        end
        cb({
            ok = true, kind = 'sell', label = point.label, items = list, account = sellAccount(point), cut = sellCut(point, gang),
            variance = Config.Activities.SellPriceVariance, cooldownLeft = cdLeft(cdKey(xPlayer, 'sell', point.id)), maxSell = Config.Activities.MaxSell,
        })

    elseif point.type == 'laundry' then
        local c = launderCfg(point)
        cb({ ok = true, kind = 'laundry', label = point.label, dirty = GB.dirtyCount(src, xPlayer), fee = c.fee, min = c.min, max = c.max, seconds = c.seconds })
    end
end

-- ─────────────────────────────── Démarrage d'une activité (durée contrôlée par le serveur) ───────────────────────────────
ESX.RegisterServerCallback('gangbuilder:act:start', function(src, cb, kind, pointId, a, b)
    if kind ~= 'harvest' and kind ~= 'process' and kind ~= 'laundry' then return cb(fail('Activité inconnue')) end
    local point, xPlayer, grade, err = GB.getPoint(src, pointId, kind)
    if not point then return cb(fail(err)) end
    if GB.Active[src] then return cb(fail('Tu es déjà occupé')) end
    local d, act = point.data, nil

    if kind == 'harvest' then
        local left = cdLeft(cdKey(xPlayer, 'harvest', point.id))
        if left > 0 then return cb(fail(('Reviens dans %d secondes'):format(left))) end
        if d.tool and d.tool ~= '' and GB.itemCount(src, xPlayer, d.tool) < 1 then return cb(fail('Il te manque l\'outil nécessaire')) end
        if not GB.canCarry(src, xPlayer, d.name, d.count) then return cb(fail('Tu ne peux pas porter plus')) end
        act = { seconds = d.seconds, scenario = Config.Activities.HarvestScenario, label = ('Récolte : %s'):format(d.label) }

    elseif kind == 'process' then
        local r = d.recipes[tonumber(a) or 0]
        local qty = math.floor(tonumber(b) or 1)
        if not r or grade < r.min_grade then return cb(fail('Recette indisponible')) end
        if qty < 1 or qty > Config.Activities.MaxBatch then return cb(fail('Quantité invalide')) end
        local make = recipeAvailable(src, xPlayer, r)
        if make < qty then return cb(fail('Il te manque des ingrédients')) end
        if not GB.canCarry(src, xPlayer, r.output.name, r.output.count * qty) then return cb(fail('Tu ne peux pas porter autant')) end
        act = { seconds = r.seconds * qty, scenario = Config.Activities.ProcessScenario, label = ('%s ×%d'):format(r.label, qty), idx = tonumber(a), qty = qty }

    elseif kind == 'laundry' then
        local c = launderCfg(point)
        local amount = math.floor(tonumber(a) or 0)
        if amount < c.min or amount > c.max then return cb(fail(('Montant autorisé : %d$ à %d$'):format(c.min, c.max))) end
        if GB.dirtyCount(src, xPlayer) < amount then return cb(fail('Pas assez d\'argent sale')) end
        act = { seconds = c.seconds, scenario = Config.Activities.LaunderScenario, label = ('Blanchiment : %d$'):format(amount), amount = amount }
    end

    act.kind, act.pointId, act.started = kind, point.id, GetGameTimer()
    GB.Active[src] = act
    cb({ ok = true, seconds = act.seconds, scenario = act.scenario, label = act.label })
end)

ESX.RegisterServerCallback('gangbuilder:act:cancel', function(src, cb)
    GB.Active[src] = nil
    cb({ ok = true })
end)

-- ─────────────────────────────── Fin d'une activité ───────────────────────────────
ESX.RegisterServerCallback('gangbuilder:act:finish', function(src, cb)
    local act = GB.Active[src]
    GB.Active[src] = nil
    if not act then return cb(fail('Aucune action en cours')) end
    if GetGameTimer() - act.started < act.seconds * 1000 * Config.Activities.Grace then return cb(fail('Action trop rapide')) end
    local point, xPlayer, grade, err = GB.getPoint(src, act.pointId, act.kind)
    if not point then return cb(fail(err)) end
    local gang = GB.Gangs[point.gang_name]
    local d = point.data

    if act.kind == 'harvest' then
        if not GB.canCarry(src, xPlayer, d.name, d.count) then return cb(fail('Tu ne peux pas porter plus')) end
        if not GB.giveItem(src, xPlayer, d.name, d.count) then return cb(fail('Impossible de donner l\'objet')) end
        if d.cooldown and d.cooldown > 0 then cooldowns[cdKey(xPlayer, 'harvest', point.id)] = os.time() + d.cooldown end
        GB.stat(xPlayer.identifier, gang.name, 'harvested', d.count)
        GB.addRep(gang.name, Config.Rep.PerHarvest)
        GB.log(gang.name, xPlayer, 'harvest', ('%dx %s'):format(d.count, d.label))
        if GB.onIllegalActivity then GB.onIllegalActivity(src, 'harvest', point) end
        return cb({ ok = true, message = ('Tu as récolté ~g%dx %s'):format(d.count, d.label) })

    elseif act.kind == 'process' then
        local r = d.recipes[act.idx or 0]
        if not r or grade < r.min_grade then return cb(fail('Recette indisponible')) end
        local make = recipeAvailable(src, xPlayer, r)
        if make < act.qty then return cb(fail('Il te manque des ingrédients')) end
        if not GB.canCarry(src, xPlayer, r.output.name, r.output.count * act.qty) then return cb(fail('Tu ne peux pas porter autant')) end
        for _, i in ipairs(r.inputs) do
            if not GB.takeItem(src, xPlayer, i.name, i.count * act.qty) then return cb(fail('Il te manque des ingrédients')) end
        end
        local ok = 0
        for _ = 1, act.qty do
            if math.random(100) <= (r.chance or 100) then ok = ok + 1 end
        end
        if ok > 0 then GB.giveItem(src, xPlayer, r.output.name, r.output.count * ok) end
        GB.stat(xPlayer.identifier, gang.name, 'processed', ok)
        GB.addRep(gang.name, Config.Rep.PerProcess * ok)
        GB.log(gang.name, xPlayer, 'process', ('%dx %s (%d/%d réussi)'):format(r.output.count * ok, r.output.label, ok, act.qty))
        if GB.onIllegalActivity then GB.onIllegalActivity(src, 'process', point) end
        if ok == 0 then return cb({ ok = true, message = '~r~Le traitement a échoué : les ingrédients sont perdus.' }) end
        return cb({ ok = true, message = ('Tu as produit ~g%dx %s%s'):format(r.output.count * ok, r.output.label, ok < act.qty and ('~s~ (%d/%d réussis)'):format(ok, act.qty) or '') })

    elseif act.kind == 'laundry' then
        local c = launderCfg(point)
        if act.amount < c.min or act.amount > c.max then return cb(fail('Montant invalide')) end
        if not GB.dirtyRemove(src, xPlayer, act.amount) then return cb(fail('Pas assez d\'argent sale')) end
        local fee = math.floor(act.amount * c.fee / 100)
        local clean = act.amount - fee
        xPlayer.addAccountMoney('money', clean)
        local gangFee = math.floor(fee * c.gangCut / 100)
        if gangFee > 0 then GB.treasuryAdd(gang.name, 'money', gangFee) end
        GB.stat(xPlayer.identifier, gang.name, 'laundered', act.amount)
        GB.addRep(gang.name, math.floor(act.amount / 1000) * Config.Rep.PerLaunderThousand)
        GB.log(gang.name, xPlayer, 'launder', ('%d$ sale -> %d$ propre (commission %d$)'):format(act.amount, clean, fee))
        return cb({ ok = true, message = ('Blanchiment terminé : ~g%d$~s~ propres (commission %d$)'):format(clean, fee) })
    end
    cb(fail('Activité inconnue'))
end)

-- ─────────────────────────────── Vente ───────────────────────────────
ESX.RegisterServerCallback('gangbuilder:sell:do', function(src, cb, pointId, idx, qty)
    local point, xPlayer, grade, err = GB.getPoint(src, pointId, 'sell')
    if not point then return cb(fail(err)) end
    local gang = GB.Gangs[point.gang_name]
    local A = Config.Activities
    local it = point.data.items[tonumber(idx) or 0]
    qty = math.floor(tonumber(qty) or 0)
    if not it or grade < it.min_grade then return cb(fail('Produit indisponible')) end
    if qty < 1 or qty > A.MaxSell then return cb(fail('Quantité invalide')) end
    local key = cdKey(xPlayer, 'sell', point.id)
    if cdLeft(key) > 0 then return cb(fail(('Attends encore %d secondes'):format(cdLeft(key)))) end
    if GB.itemCount(src, xPlayer, it.name) < qty then return cb(fail('Tu n\'as pas assez de ce produit')) end

    local var = A.SellPriceVariance
    local total = 0
    for _ = 1, qty do
        total = total + math.max(1, math.floor(it.price * (1 + math.random(-var, var) / 100)))
    end
    local account = sellAccount(point)
    local cut = math.floor(total * sellCut(point, gang) / 100)
    if not GB.takeItem(src, xPlayer, it.name, qty) then return cb(fail('Tu n\'as pas assez de ce produit')) end
    GB.credit(src, xPlayer, account, total - cut)
    if cut > 0 then GB.treasuryAdd(gang.name, account == 'dirty' and 'dirty' or 'money', cut) end
    if A.SellCooldown > 0 then cooldowns[key] = os.time() + A.SellCooldown end
    GB.stat(xPlayer.identifier, gang.name, 'sold', total)
    GB.addRep(gang.name, math.floor(total / 1000) * Config.Rep.PerSaleThousand)
    GB.log(gang.name, xPlayer, 'sell', ('%dx %s pour %d$ (gang : %d$)'):format(qty, it.label, total, cut))
    if GB.onIllegalActivity then GB.onIllegalActivity(src, 'sell', point) end
    cb({ ok = true, total = total, paid = total - cut, cut = cut, alert = A.PoliceAlert and math.random(100) <= A.PoliceAlertChance })
end)
