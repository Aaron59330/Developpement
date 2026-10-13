-- ─────────────────────────────── Location de véhicules ───────────────────────────────
local Rentals = {}      -- [identifier] = { eid, plate, model, deposit, expiresAt, netId, src }

local function trimPlate(p) return (tostring(p or ''):gsub('^%s+', ''):gsub('%s+$', '')) end

local function resolve(src, eid, pi)
    local e = WB.Entities[tonumber(eid) or 0]
    local xPlayer = ESX.GetPlayerFromId(src)
    if not e or e.type ~= 'rental' or not e.enabled or not xPlayer then return nil, 'Introuvable' end
    local p = e.points[tonumber(pi) or 0]
    if not p or not p.coords or not WB.near(src, p.coords, 6.0) then return nil, 'Trop loin' end
    local ok, err = WB.hasAccess(xPlayer, e.settings.access)
    if not ok then return nil, err end
    return e, p, xPlayer
end

ESX.RegisterServerCallback('worldbuilder:rental:list', function(src, cb, eid, pi)
    local e, p, xPlayer = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local s, fleet = e.settings, {}
    for i, f in ipairs(s.fleet or {}) do
        if xPlayer.job.grade >= (f.minGrade or 0) or f.minGrade == 0 then
            fleet[#fleet + 1] = { i = i, model = f.model, label = f.label ~= '' and f.label or f.model, price = f.price or 0, deposit = f.deposit or 0 }
        end
    end
    local r = Rentals[xPlayer.identifier]
    cb({ ok = true, label = e.label, fleet = fleet, minutes = s.minutes or 0, payments = WB.paymentsList(s.payments, xPlayer),
        current = r and { model = r.model, plate = r.plate, expiresAt = r.expiresAt } or nil })
end)

ESX.RegisterServerCallback('worldbuilder:rental:rent', function(src, cb, eid, pi, idx, spawnIdx, method)
    local e, p, xPlayer = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local s = e.settings
    spawnIdx = tonumber(spawnIdx) or 0
    if not p.spawns or not p.spawns[spawnIdx] then return cb({ ok = false, error = 'Aucune place de sortie configurée' }) end
    if Rentals[xPlayer.identifier] then return cb({ ok = false, error = 'Tu as déjà un véhicule en location' }) end
    local f = (s.fleet or {})[tonumber(idx) or 0]
    if not f then return cb({ ok = false, error = 'Véhicule indisponible' }) end
    local total = (f.price or 0) + (f.deposit or 0)
    local okp, err = WB.charge(xPlayer, s.payments, method, total, 'Location : ' .. e.label)
    if not okp then return cb({ ok = false, error = err }) end
    WB.society(s.society, f.price or 0)
    local plate = ('LOC%s'):format(math.random(10000, 99999))
    local minutes = s.minutes or 0
    Rentals[xPlayer.identifier] = { eid = e.id, plate = plate, model = f.model, deposit = f.deposit or 0, method = method, expiresAt = minutes > 0 and (os.time() + minutes * 60) or 0, src = src }
    WB.stat(e, 'revenue', f.price or 0) WB.stat(e, 'rentals', 1)
    WB.log(e, xPlayer, 'rent', ('%s (%s)'):format(f.model, plate), total)
    cb({ ok = true, model = f.model, plate = plate, spawn = spawnIdx, minutes = minutes, paid = total })
end)

RegisterNetEvent('worldbuilder:server:rentalSpawned', function(netId)
    local x = ESX.GetPlayerFromId(source)
    local r = x and Rentals[x.identifier]
    if r then r.netId = netId end
end)

RegisterNetEvent('worldbuilder:server:rentalFailed', function()
    local x = ESX.GetPlayerFromId(source)
    local r = x and Rentals[x.identifier]
    if not r or r.netId then return end
    local e = WB.Entities[r.eid]
    local back = (e and WB.balance(x, r.method) >= 0) and r.method or 'cash'
    local p = Config.Payments[back] or Config.Payments.cash
    local f
    if e then for _, it in ipairs(e.settings.fleet or {}) do if it.model == r.model then f = it end end end
    WB.pay(x, p.account, (f and f.price or 0) + r.deposit, 'Remboursement location')
    Rentals[x.identifier] = nil
end)

-- Retour : le véhicule doit être celui loué, près du point de retour. Caution rendue (proportionnelle à l'état si activé).
ESX.RegisterServerCallback('worldbuilder:rental:return', function(src, cb, eid, pi, netId)
    local e, p, xPlayer = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local r = Rentals[xPlayer.identifier]
    if not r then return cb({ ok = false, error = 'Aucune location en cours' }) end
    local ent = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if not ent or ent == 0 or not DoesEntityExist(ent) then return cb({ ok = false, error = 'Véhicule introuvable' }) end
    if trimPlate(GetVehicleNumberPlateText(ent)) ~= r.plate then return cb({ ok = false, error = 'Ce n\'est pas ton véhicule de location' }) end
    local at = p.ret or p.coords
    local c = GetEntityCoords(ent)
    if #(vector3(c.x, c.y, c.z) - vector3(at.x, at.y, at.z)) > Config.ServerDistance + 8.0 then return cb({ ok = false, error = 'Ramène le véhicule au point de retour' }) end
    local refund = r.deposit
    if e.settings.refundDamage ~= false and r.deposit > 0 then
        local body, eng = GetVehicleBodyHealth(ent), GetVehicleEngineHealth(ent)
        local health = math.max(0.0, math.min(1000.0, ((body or 1000.0) + (eng or 1000.0)) / 2.0))
        refund = math.floor(r.deposit * (health / 1000.0))
    end
    if r.expiresAt > 0 and os.time() > r.expiresAt then refund = 0 end
    local acc = (Config.Payments[r.method] or Config.Payments.cash).account
    WB.pay(xPlayer, acc, refund, 'Caution de location')
    DeleteEntity(ent)
    Rentals[xPlayer.identifier] = nil
    WB.log(e, xPlayer, 'return', ('%s — caution rendue %d/%d'):format(r.plate, refund, r.deposit), refund)
    cb({ ok = true, refund = refund, deposit = r.deposit })
end)

-- Expiration : prévient le joueur puis retire le véhicule (la caution est perdue)
CreateThread(function()
    while true do
        Wait(15000)
        local now = os.time()
        for ident, r in pairs(Rentals) do
            if r.expiresAt > 0 and now > r.expiresAt + 120 then
                if r.netId then
                    local ent = NetworkGetEntityFromNetworkId(r.netId)
                    if ent and ent ~= 0 and DoesEntityExist(ent) then DeleteEntity(ent) end
                end
                if r.src then WB.notify(r.src, 'Ta location est terminée : le véhicule a été récupéré (caution perdue).', 'error') end
                Rentals[ident] = nil
            elseif r.expiresAt > 0 and now > r.expiresAt and not r.warned then
                r.warned = true
                if r.src then WB.notify(r.src, 'Ta location est terminée : ramène le véhicule sous 2 minutes.', 'error') end
            end
        end
    end
end)
