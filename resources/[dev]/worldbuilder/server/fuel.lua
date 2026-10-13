-- ─────────────────────────────── Stations essence ───────────────────────────────
-- Stock de la cuve en mémoire (persisté dans stats.tank) ; réapprovisionnement automatique optionnel.

local function tankOf(e)
    local cap = e.settings.tank or 0
    if cap <= 0 then return -1, 0 end                      -- illimitée
    e.stats = e.stats or {}
    if e.stats.tank == nil then e.stats.tank = cap end
    return math.min(e.stats.tank, cap), cap
end

local function resolve(src, eid, pi)
    local e = WB.Entities[tonumber(eid) or 0]
    local xPlayer = ESX.GetPlayerFromId(src)
    if not e or e.type ~= 'fuel' or not e.enabled or not xPlayer then return nil, 'Introuvable' end
    local p = e.points[tonumber(pi) or 0]
    if not p or not p.coords or not WB.near(src, p.coords, 8.0) then return nil, 'Trop loin' end
    local ok, err = WB.hasAccess(xPlayer, e.settings.access)
    if not ok then return nil, err end
    return e, p, xPlayer
end

ESX.RegisterServerCallback('worldbuilder:fuel:info', function(src, cb, eid, pi)
    local e, p, xPlayer = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local s = e.settings
    local tank, cap = tankOf(e)
    cb({ ok = true, label = e.label, price = s.price or 0, tank = tank, capacity = cap, payments = WB.paymentsList(s.payments, xPlayer),
        jerrycan = s.jerrycan and s.jerrycan.enabled and s.jerrycan.item ~= '' and { price = s.jerrycan.price or 0, item = s.jerrycan.item } or nil })
end)

-- Début du plein : on réserve les litres demandés, le client joue l'animation puis confirme
ESX.RegisterServerCallback('worldbuilder:fuel:begin', function(src, cb, eid, pi, liters, method)
    local e, p, xPlayer = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local s = e.settings
    liters = math.floor(tonumber(liters) or 0)
    if liters < 1 or liters > 200 then return cb({ ok = false, error = 'Quantité invalide' }) end
    local tank = tankOf(e)
    if tank >= 0 and tank < liters then liters = math.floor(tank) end
    if liters < 1 then return cb({ ok = false, error = 'La cuve de la station est vide' }) end
    local cost = math.ceil(liters * (s.price or 0))
    if not s.payments or s.payments[method] ~= true then return cb({ ok = false, error = 'Moyen de paiement refusé' }) end
    if WB.balance(xPlayer, method) < cost then return cb({ ok = false, error = 'Fonds insuffisants' }) end
    WB.beginAct(src, { kind = 'fuel', eid = e.id, pi = p, liters = liters, method = method, cost = cost }, math.min(30, 2 + liters * 0.15))
    cb({ ok = true, liters = liters, cost = cost, seconds = math.min(30, 2 + liters * 0.15) })
end)

RegisterNetEvent('worldbuilder:server:fuelFinish', function(done)
    local src = source
    local a, err = WB.endAct(src, 'fuel')
    local xPlayer = ESX.GetPlayerFromId(src)
    local e = a and WB.Entities[a.eid]
    if not a or not e or not xPlayer then if err then WB.notify(src, err, 'error') end return end
    if done ~= true or not WB.near(src, a.pi.coords, 8.0) then return end
    local s = e.settings
    local ok, msg = WB.charge(xPlayer, s.payments, a.method, a.cost, 'Carburant : ' .. e.label)
    if not ok then WB.notify(src, msg, 'error') return end
    WB.society(s.society, a.cost)
    if (s.tank or 0) > 0 then e.stats.tank = math.max(0, (e.stats.tank or s.tank) - a.liters) end
    WB.stat(e, 'revenue', a.cost) WB.stat(e, 'liters', a.liters)
    WB.log(e, xPlayer, 'fuel', ('%d L'):format(a.liters), a.cost)
    TriggerClientEvent('worldbuilder:client:fuelDone', src, a.liters, a.cost)
end)

ESX.RegisterServerCallback('worldbuilder:fuel:jerrycan', function(src, cb, eid, pi, method)
    local e, p, xPlayer = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local j = e.settings.jerrycan
    if not j or not j.enabled or j.item == '' then return cb({ ok = false, error = 'Indisponible' }) end
    local okp, err = WB.charge(xPlayer, e.settings.payments, method, j.price, 'Jerricane : ' .. e.label)
    if not okp then return cb({ ok = false, error = err }) end
    if not WB.addItem(src, j.item, 1) then
        WB.pay(xPlayer, (Config.Payments[method] or Config.Payments.cash).account, j.price, 'Remboursement jerricane')
        return cb({ ok = false, error = 'Inventaire plein' })
    end
    WB.society(e.settings.society, j.price)
    WB.stat(e, 'revenue', j.price)
    WB.log(e, xPlayer, 'jerrycan', j.item, j.price)
    cb({ ok = true })
end)

-- Réapprovisionnement automatique des cuves
CreateThread(function()
    while true do
        Wait(60000)
        if WB.ready then
            local now = os.time()
            for _, e in pairs(WB.Entities) do
                local s = e.settings
                if e.type == 'fuel' and (s.tank or 0) > 0 and (s.restockMinutes or 0) > 0 and (s.restockLiters or 0) > 0 then
                    e.stats = e.stats or {}
                    e.stats.restockAt = e.stats.restockAt or now
                    if now - e.stats.restockAt >= s.restockMinutes * 60 then
                        e.stats.restockAt = now
                        e.stats.tank = math.min(s.tank, (e.stats.tank or s.tank) + s.restockLiters)
                        WB.Dirty[e.id] = true
                    end
                end
            end
        end
    end
end)
