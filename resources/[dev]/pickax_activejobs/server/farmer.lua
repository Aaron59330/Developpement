local KEY = 'farmer'
local Farms = {}      -- Farms[identifier] = { [plot] = { crop, planted, watered } }

local function ox() return exports.ox_inventory end

CreateThread(function()
    Wait(500)
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS activejobs_farm (
        identifier VARCHAR(80) NOT NULL, plot INT NOT NULL, crop VARCHAR(30) NOT NULL, planted BIGINT NOT NULL, watered TINYINT NOT NULL DEFAULT 0,
        PRIMARY KEY (identifier, plot)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
end)

local function farmOf(x)
    local f = Farms[x.identifier]
    if not f then
        f = {}
        for _, r in ipairs(MySQL.query.await('SELECT plot, crop, planted, watered FROM activejobs_farm WHERE identifier = ?', { x.identifier }) or {}) do
            f[r.plot] = { crop = r.crop, planted = r.planted, watered = r.watered == 1 }
        end
        Farms[x.identifier] = f
    end
    return f
end

-- Avancement 0..1 (la tâche d'arrosage raccourcit le temps de pousse)
local function progress(p)
    local c = Config.Jobs[KEY].crops[p.crop]
    if not c then return 0 end
    local total = c.grow * 60 * (p.watered and Config.Jobs[KEY].waterFactor or 1.0)
    return math.min(1.0, (os.time() - p.planted) / total), total
end

local function snapshot(x)
    local out = {}
    for plot, p in pairs(farmOf(x)) do
        local pr, total = progress(p)
        out[#out + 1] = { plot = plot, crop = p.crop, stage = pr >= 1.0 and 3 or (pr >= 0.5 and 2 or 1), ready = pr >= 1.0, watered = p.watered, left = math.max(0, math.ceil(total * (1 - pr))) }
    end
    return out
end

local function push(src)
    local x = ESX.GetPlayerFromId(src)
    if x then TriggerClientEvent('aj:farm:plots', src, snapshot(x)) end
end

local function fieldOk(src, st, plot)
    local j = Config.Jobs[KEY]
    local f = AJ.pts(st, 'field')[1]
    return f and plot and plot >= 1 and plot <= j.fieldRows * j.fieldCols and AJ.near(src, f, (j.fieldRows + j.fieldCols) * j.spacing + 12.0)
end

AJ.Modules[KEY] = {
    start = function(src, st)
        local j = Config.Jobs[KEY]
        local x = ESX.GetPlayerFromId(src)
        local field, market, spawn = AJ.pts(st, 'field')[1], AJ.pts(st, 'market')[1], AJ.spawnPoint(st)
        if not field or not market then return nil, 'Champ ou marché non configuré (points d\'activité « Champ » et « Marché » dans le Job Builder)' end
        local crops = {}
        for k, c in pairs(j.crops) do crops[k] = { label = c.label, seed = c.seed, item = c.item, models = c.models, price = c.price, seedPrice = c.seedPrice } end
        return { field = field, market = market, spawn = spawn, tractor = j.tractor, rows = j.fieldRows, cols = j.fieldCols, spacing = j.spacing, crops = crops, plots = snapshot(x) }
    end,
    stop = function() end,
}

RegisterNetEvent('aj:farm:sow', function(plot, crop)
    local src = source
    local st = AJ.session(src, KEY)
    if not st then return end
    local x, c = ESX.GetPlayerFromId(src), Config.Jobs[KEY].crops[crop]
    plot = tonumber(plot)
    if not x or not c or not fieldOk(src, st, plot) then return end
    local f = farmOf(x)
    if f[plot] then return AJ.notify(src, 'Cette parcelle est déjà semée.', 'error') end
    if not ox():RemoveItem(src, c.seed, 1) then return AJ.notify(src, ('Tu n\'as pas de graines de %s (achète-en au marché).'):format(c.label:lower()), 'error') end
    f[plot] = { crop = crop, planted = os.time(), watered = false }
    MySQL.update('INSERT INTO activejobs_farm (identifier, plot, crop, planted, watered) VALUES (?, ?, ?, ?, 0) ON DUPLICATE KEY UPDATE crop = VALUES(crop), planted = VALUES(planted), watered = 0', { x.identifier, plot, crop, f[plot].planted })
    AJ.pay(src, KEY, 0, 2, nil, 0)
    push(src)
end)

RegisterNetEvent('aj:farm:water', function(plot)
    local src = source
    local st = AJ.session(src, KEY)
    if not st then return end
    local x = ESX.GetPlayerFromId(src)
    plot = tonumber(plot)
    if not x or not fieldOk(src, st, plot) then return end
    local p = farmOf(x)[plot]
    if not p or p.watered or progress(p) >= 1.0 then return end
    -- on garde la progression déjà accomplie : on décale la date de plantation pour conserver le ratio
    local c = Config.Jobs[KEY].crops[p.crop]
    local oldTotal = c.grow * 60
    local ratio = (os.time() - p.planted) / oldTotal
    local newTotal = oldTotal * Config.Jobs[KEY].waterFactor
    p.watered, p.planted = true, os.time() - math.floor(ratio * newTotal)
    MySQL.update('UPDATE activejobs_farm SET watered = 1, planted = ? WHERE identifier = ? AND plot = ?', { p.planted, x.identifier, plot })
    AJ.pay(src, KEY, 0, 2, nil, 0)
    push(src)
end)

RegisterNetEvent('aj:farm:harvest', function(plot)
    local src = source
    local st = AJ.session(src, KEY)
    if not st then return end
    local x = ESX.GetPlayerFromId(src)
    plot = tonumber(plot)
    if not x or not fieldOk(src, st, plot) then return end
    local f = farmOf(x)
    local p = f[plot]
    if not p or progress(p) < 1.0 then return end
    local c = Config.Jobs[KEY].crops[p.crop]
    local n = math.random(c.yield[1], c.yield[2])
    if not ox():CanCarryItem(src, c.item, n) then return AJ.notify(src, 'Tu ne peux pas porter la récolte (inventaire plein).', 'error') end
    ox():AddItem(src, c.item, n)
    f[plot] = nil
    MySQL.update('DELETE FROM activejobs_farm WHERE identifier = ? AND plot = ?', { x.identifier, plot })
    AJ.pay(src, KEY, 0, 6, nil, 0)
    AJ.notify(src, ('Récolte : %d × %s'):format(n, c.label), 'success')
    push(src)
end)

RegisterNetEvent('aj:farm:buy', function(crop, qty)
    local src = source
    local st = AJ.session(src, KEY)
    if not st then return end
    local c, x, m = Config.Jobs[KEY].crops[crop], ESX.GetPlayerFromId(src), AJ.pts(st, 'market')[1]
    qty = math.floor(tonumber(qty) or 0)
    if not c or not x or not m or qty < 1 or qty > 50 or not AJ.near(src, m, 10.0) then return end
    local cost = qty * c.seedPrice
    if x.getAccount(Config.Account).money < cost then return AJ.notify(src, ('Il te faut %d $.'):format(cost), 'error') end
    if not ox():CanCarryItem(src, c.seed, qty) then return AJ.notify(src, 'Inventaire plein.', 'error') end
    x.removeAccountMoney(Config.Account, cost, 'Graines de ' .. c.label)
    ox():AddItem(src, c.seed, qty)
    AJ.notify(src, ('%d graines de %s achetées : -%d $'):format(qty, c.label:lower(), cost), 'success')
end)

RegisterNetEvent('aj:farm:sell', function()
    local src = source
    local st = AJ.session(src, KEY)
    if not st then return end
    local m = AJ.pts(st, 'market')[1]
    if not m or not AJ.near(src, m, 10.0) then return end
    local base, count = 0, 0
    for _, c in pairs(Config.Jobs[KEY].crops) do
        local n = ox():Search(src, 'count', c.item) or 0
        if n > 0 and ox():RemoveItem(src, c.item, n) then base = base + n * c.price count = count + n end
    end
    if count == 0 then return AJ.notify(src, 'Tu n\'as rien à vendre.', 'error') end
    local paid = AJ.pay(src, KEY, base, count * 2, 'Vente de récolte', 1)
    AJ.notify(src, ('%d produit(s) vendu(s) : %d $'):format(count, paid), 'success')
end)

-- mise à jour périodique de l'affichage des parcelles
CreateThread(function()
    while true do
        Wait(20000)
        for src, a in pairs(AJ.Active) do if a.job == KEY then push(src) end end
    end
end)
