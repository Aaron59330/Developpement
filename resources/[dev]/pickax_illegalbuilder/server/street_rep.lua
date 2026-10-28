-- ─────────────────────────────── Vente de rue : réputation de dealer, saturation et chaleur des quartiers ───────────────────────────────
-- Règles pures (testables hors jeu) + stockage de la réputation. Utilisé par server/street.lua.
local Rep = {}          -- [identifiant] = réputation (cache)
local Zones = {}        -- [secteur] = { sat = 0..100, heat = 0..100, t = os.time() }

local function clamp(x, a, b) return math.max(a, math.min(b, x)) end
local function num(x, d) x = tonumber(x) if x ~= x or x == nil then return d end return x end

function IB.repLevel(rep)
    local R = Config.StreetRep or {}
    local lvl = 1
    for i, need in ipairs(R.Levels or { 0 }) do if rep >= need then lvl = i end end
    local nextNeed = (R.Levels or {})[lvl + 1]
    return lvl, (R.Names or {})[lvl] or ('Niveau ' .. lvl), nextNeed
end

-- Secteur d'une position : zone nommée la plus proche contenant le point, sinon case de la grille
function IB.streetZoneKey(c)
    local Zc = Config.StreetZones or {}
    for _, z in ipairs(Zc.Named or {}) do
        local dx, dy = c.x - z.coords.x, c.y - z.coords.y
        if dx * dx + dy * dy <= (z.radius or 100) ^ 2 then return 'n:' .. tostring(z.name), z end
    end
    local cell = math.max(50, num(Zc.Cell, 300))
    return ('g:%d:%d'):format(math.floor(c.x / cell), math.floor(c.y / cell)), nil
end

-- État d'un secteur avec la retombée du temps écoulé
function IB.streetZoneState(key, now)
    local Zc = Config.StreetZones or {}
    now = now or os.time()
    local z = Zones[key]
    if not z then z = { sat = 0, heat = 0, t = now } Zones[key] = z end
    local mins = math.max(0, now - z.t) / 60
    if mins > 0 then
        z.sat = clamp(z.sat - mins * num(Zc.SatDecay, 3), 0, 100)
        z.heat = clamp(z.heat - mins * num(Zc.HeatDecay, 2), 0, 100)
        z.t = now
    end
    return z
end

-- Acceptation (%), multiplicateur de prix et risque d'alerte (%) pour une vente
function IB.streetModifiers(rep, zone, named)
    local C, R, Zc = Config.StreetSales or {}, Config.StreetRep or {}, Config.StreetZones or {}
    local lvl = 1
    local accept, price, alert = num(C.AcceptChance, 60), 1.0, num(C.AlertChance, 0)
    if R.Enabled ~= false then
        lvl = IB.repLevel(rep or 0)
        accept = accept + (lvl - 1) * num(R.AcceptPerLevel, 0)
        price = price * (1 + (lvl - 1) * num(R.PricePerLevel, 0))
    end
    if Zc.Enabled ~= false and zone then
        price = price * (1 - zone.sat / 100 * num(Zc.MaxPriceDrop, 0))
        accept = accept - zone.heat * num(Zc.HeatAccept, 0)
        alert = alert + zone.heat * num(Zc.HeatAlert, 0)
        if named and named.demand then price = price * num(named.demand, 1) end
    end
    return clamp(accept, 5, 95), math.max(0.1, price), clamp(alert, 0, 100), lvl
end

-- Une vente (qty unités) ou un refus (qty = 0) modifie le secteur
function IB.streetZoneAfter(zone, qty)
    local Zc = Config.StreetZones or {}
    if Zc.Enabled == false then return end
    if qty > 0 then
        zone.sat = clamp(zone.sat + qty * num(Zc.SatPerUnit, 4), 0, 100)
        zone.heat = clamp(zone.heat + num(Zc.HeatPerSale, 6), 0, 100)
    else
        zone.heat = clamp(zone.heat + num(Zc.HeatPerRefuse, 3), 0, 100)
    end
end

-- ─── Réputation du joueur (base de données) ───
CreateThread(function()
    Wait(1500)
    if MySQL and MySQL.query then
        pcall(MySQL.query.await, [[CREATE TABLE IF NOT EXISTS illegalbuilder_dealer_rep (identifier VARCHAR(80) NOT NULL PRIMARY KEY, rep INT NOT NULL DEFAULT 0) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    end
end)

function IB.getRep(identifier)
    if Rep[identifier] == nil then
        local ok, row = pcall(function() return MySQL.single.await('SELECT rep FROM illegalbuilder_dealer_rep WHERE identifier = ?', { identifier }) end)
        Rep[identifier] = ok and row and tonumber(row.rep) or 0
    end
    return Rep[identifier]
end

function IB.addRep(identifier, n)
    local v = IB.getRep(identifier) + math.max(0, math.floor(n))
    Rep[identifier] = v
    pcall(function() MySQL.update('INSERT INTO illegalbuilder_dealer_rep (identifier, rep) VALUES (?, ?) ON DUPLICATE KEY UPDATE rep = VALUES(rep)', { identifier, v }) end)
    return v
end

exports('GetDealerRep', function(src)
    local x = ESX.GetPlayerFromId(tonumber(src))
    if not x then return 0, 1 end
    local rep = IB.getRep(x.identifier)
    return rep, (IB.repLevel(rep))
end)

-- /dealer : niveau, réputation et état du secteur
RegisterCommand('dealer', function(src)
    if src == 0 then return end
    local x = ESX.GetPlayerFromId(src)
    local ped = GetPlayerPed(src)
    if not x or not ped or ped == 0 then return end
    local rep = IB.getRep(x.identifier)
    local lvl, name, nextNeed = IB.repLevel(rep)
    local key = IB.streetZoneKey(GetEntityCoords(ped))
    local z = IB.streetZoneState(key)
    TriggerClientEvent('illegalbuilder:client:notify', src, ('%s (niv. %d) · réputation %d%s · ici : saturation %d %%, chaleur %d %%'):format(name, lvl, rep, nextNeed and (' / ' .. nextNeed) or '', math.floor(z.sat), math.floor(z.heat)), 'info')
end, false)
