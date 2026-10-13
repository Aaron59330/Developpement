-- ─────────────────────────────── Stations de lavage ───────────────────────────────
local function resolve(src, eid, pi)
    local e = WB.Entities[tonumber(eid) or 0]
    local x = ESX.GetPlayerFromId(src)
    if not e or e.type ~= 'carwash' or not e.enabled or not x then return nil, 'Introuvable' end
    local p = e.points[tonumber(pi) or 0]
    if not p or p.kind ~= 'wash' or not p.coords or not WB.near(src, p.coords, 6.0) then return nil, 'Trop loin' end
    local ok, err = WB.hasAccess(x, e.settings.access)
    if not ok then return nil, err end
    return e, p, x
end

ESX.RegisterServerCallback('worldbuilder:carwash:info', function(src, cb, eid, pi)
    local e, p, x = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local list = {}
    for i, g in ipairs(e.settings.programs or {}) do list[#list + 1] = { i = i, label = g.label ~= '' and g.label or ('Programme ' .. i), price = g.price, seconds = g.seconds } end
    cb({ ok = true, label = p.label ~= '' and p.label or e.label, programs = list, payments = WB.paymentsList(e.settings.payments, x) })
end)

ESX.RegisterServerCallback('worldbuilder:carwash:begin', function(src, cb, eid, pi, idx, method)
    if WB.Pending[src] then return cb({ ok = false, error = 'Action déjà en cours' }) end
    local e, p, x = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local g = (e.settings.programs or {})[tonumber(idx) or 0]
    if not g then return cb({ ok = false, error = 'Programme inconnu' }) end
    if not e.settings.payments or e.settings.payments[method] ~= true then return cb({ ok = false, error = 'Moyen de paiement refusé' }) end
    if WB.balance(x, method) < g.price then return cb({ ok = false, error = 'Fonds insuffisants' }) end
    WB.beginAct(src, { kind = 'carwash', eid = e.id, pi = p, program = g, method = method }, g.seconds)
    cb({ ok = true, seconds = g.seconds, label = g.label })
end)

RegisterNetEvent('worldbuilder:server:washFinish', function(done)
    local src = source
    local a, err = WB.endAct(src, 'carwash')
    local x = ESX.GetPlayerFromId(src)
    local e = a and WB.Entities[a.eid]
    if not a or not e or not x then if err then WB.notify(src, err, 'error') end return end
    if done ~= true or not WB.near(src, a.pi.coords, 8.0) then return end
    local ok, msg = WB.charge(x, e.settings.payments, a.method, a.program.price, 'Lavage : ' .. e.label)
    if not ok then return WB.notify(src, msg, 'error') end
    WB.society(e.settings.society, a.program.price)
    WB.stat(e, 'revenue', a.program.price) WB.stat(e, 'washes', 1)
    WB.log(e, x, 'wash', a.program.label, a.program.price)
    TriggerClientEvent('worldbuilder:client:washDone', src, a.program.price)
end)
