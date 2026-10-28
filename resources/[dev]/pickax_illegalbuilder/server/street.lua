-- ─────────────────────────────── Vente de drogue dans la rue (PNJ) ───────────────────────────────
-- Utilisée par le menu contextuel (pickax_core : clic sur un PNJ → « Vendre de la drogue »). Le client ne décide de rien : le serveur vérifie
-- l'interrupteur général, la tablette vendeur, les policiers, le délai et la limite horaire, tire au sort l'acceptation, la quantité et le prix, puis paie.

local last = {}   -- [src] = GetGameTimer() de la dernière vente

local function S() return Config.StreetSales end
local function enabled() return Config.PedSales.Enabled ~= false and S().Enabled ~= false end

-- Articles vendables : drogues du catalogue (pochon) au prix du dealer × PriceFactor, ou la liste Config.StreetSales.Items
function IB.streetCatalog()
    local C, list = S(), {}
    if type(C.Items) == 'table' and #C.Items > 0 then
        for _, it in ipairs(C.Items) do
            if type(it.item) == 'string' and it.item ~= '' then list[#list + 1] = { item = it.item, label = it.label or it.item, min = math.floor(tonumber(it.min) or 0), max = math.floor(tonumber(it.max) or tonumber(it.min) or 0) } end
        end
        return list
    end
    local f = tonumber(C.PriceFactor) or 1.0
    for _, id in ipairs(Config.DrugOrder or {}) do
        local d = Config.Drugs[id]
        if d and d.pooch and d.pooch ~= '' then
            local pr = d.price and d.price.pooch or { 90, 140 }
            list[#list + 1] = { item = d.pooch, label = d.label, min = math.floor((pr[1] or 0) * f), max = math.floor((pr[2] or pr[1] or 0) * f) }
        end
    end
    return list
end

-- Conditions communes → nil si tout va bien, sinon le message à afficher
local function blocked(src)
    local C = S()
    if not enabled() then return 'La vente de drogue aux PNJ est désactivée' end
    if C.RequireTablet and (C.TabletItem or '') ~= '' and IB.itemCount(src, C.TabletItem) < 1 then return 'Il te faut la tablette vendeur' end
    if (C.CopsRequired or 0) > 0 and IB.copCount() < C.CopsRequired then return 'Pas assez de policiers en service' end
    return nil
end

local function roll(a, b)
    a, b = math.floor(a or 0), math.floor(b or 0)
    if b < a then b = a end
    return math.random(a, b)
end

ESX.RegisterServerCallback('illegalbuilder:street:info', function(src, cb)
    local why = blocked(src)
    if why then return cb({ ok = false, error = why }) end
    local list = {}
    for _, it in ipairs(IB.streetCatalog()) do
        local have = IB.itemCount(src, it.item)
        if have > 0 then list[#list + 1] = { item = it.item, label = it.label, min = it.min, max = it.max, have = have } end
    end
    if #list == 0 then return cb({ ok = false, error = 'Tu n\'as rien à vendre' }) end
    cb({ ok = true, items = list })
end)

ESX.RegisterServerCallback('illegalbuilder:street:sell', function(src, cb, item)
    local xPlayer = ESX.GetPlayerFromId(src)
    local C = S()
    if not xPlayer then return cb({ ok = false, error = 'Erreur' }) end
    local why = blocked(src)
    if why then return cb({ ok = false, error = why }) end
    local entry
    for _, it in ipairs(IB.streetCatalog()) do if it.item == item then entry = it end end
    if not entry then return cb({ ok = false, error = 'Cet article ne se vend pas dans la rue' }) end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or GetVehiclePedIsIn(ped, false) ~= 0 then return cb({ ok = false, error = 'Impossible en véhicule' }) end
    local now = GetGameTimer()
    if (last[src] or -1e9) + (C.Cooldown or 0) * 1000 > now then return cb({ ok = false, error = 'Doucement, laisse passer un peu de temps' }) end
    local have = IB.itemCount(src, entry.item)
    if have < 1 then return cb({ ok = false, error = 'Tu n\'en as pas' }) end
    local ctr = IB.counter('street:' .. xPlayer.identifier, 3600)
    local limit = C.MaxPerHour or 0
    if limit > 0 and ctr.n >= limit then return cb({ ok = false, error = 'Tu as trop vendu, fais une pause' }) end
    last[src] = now
    local coords = GetEntityCoords(ped)
    -- réputation du joueur + état du secteur (saturation, chaleur)
    local rep = IB.getRep(xPlayer.identifier)
    local zkey, named = IB.streetZoneKey(coords)
    local zone = IB.streetZoneState(zkey)
    local accept, priceMult, alertChance, repLvl = IB.streetModifiers(rep, zone, named)
    if math.random(100) > accept then      -- le PNJ refuse
        IB.streetZoneAfter(zone, 0)
        if math.random(100) <= (C.RefuseAlertChance or 0) + zone.heat * 0.1 then IB.alertPolice(coords, 'Activité suspecte', 'Un passant signale une proposition de drogue dans la rue') end
        return cb({ ok = true, accepted = false })
    end
    local qty = math.min(have, roll(C.QtyMin or 1, C.QtyMax or 1))
    if limit > 0 then qty = math.min(qty, limit - ctr.n) end
    if qty < 1 then return cb({ ok = false, error = 'Tu as trop vendu, fais une pause' }) end
    local unit = roll(entry.min, entry.max)
    local took, factor, purity = IB.takeUnits(src, entry.item, qty)
    if not took then return cb({ ok = false, error = 'Erreur' }) end
    local total = math.floor(unit * qty * factor * priceMult + 0.5)
    ctr.n = ctr.n + qty
    local tax = 0
    if GetResourceState('pickax_gangbuilder') == 'started' then
        local okT, t = pcall(function() return exports.pickax_gangbuilder:TerritoryTax(src, total, 'vente de rue : ' .. entry.item) end)
        if okT then tax = math.min(total, math.max(0, math.floor(tonumber(t) or 0))) end
        pcall(function() exports.pickax_gangbuilder:ReportIllegalActivity(src, 'sell') end)
    end
    IB.pay(xPlayer, (C.Account == 'money' or C.Account == 'bank') and C.Account or 'black_money', total - tax, 'Vente de rue : ' .. entry.item)
    if math.random(100) <= alertChance then IB.alertPolice(coords, 'Vente de drogue', 'Un témoin signale une vente de drogue dans la rue') end
    IB.streetZoneAfter(zone, qty)
    local newRep = rep
    if (Config.StreetRep or {}).Enabled ~= false then newRep = IB.addRep(xPlayer.identifier, qty * ((Config.StreetRep or {}).PerUnit or 1)) end
    local newLvl, lvlName = IB.repLevel(newRep)
    if GetResourceState('pickax_carnet') == 'started' then pcall(function() exports.pickax_carnet:Report(src, 'sell', qty) end) end
    IB.log(nil, xPlayer, 'street_sell', ('%s ×%d'):format(entry.item, qty), total - tax)
    cb({ ok = true, accepted = true, item = entry.item, label = entry.label, qty = qty, total = total - tax, tax = tax, purity = purity,
        levelUp = newLvl > repLvl and lvlName or nil, saturation = math.floor(zone.sat), heat = math.floor(zone.heat) })
end)

AddEventHandler('playerDropped', function() last[source] = nil end)
