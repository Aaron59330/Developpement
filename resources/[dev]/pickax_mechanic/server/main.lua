-- ─────────────────────────────── Mécanicien réaliste : état des véhicules, pièces en stock, réparations ───────────────────────────────
-- Le serveur décide de tout : usure (rapports du conducteur plausibilisés), stock du magasin, pièces consommées, réussite d'une réparation.
local ESX = exports['es_extended']:getSharedObject()
local C = Config

local Veh = {}         -- [plate] = { cond = { engine=.. }, km = n, dirty = bool }
local Stock = {}       -- [item] = { qty, last }
local Pending = {}     -- [src] = { comp, plate, at, parts }
local LastWear = {}    -- [src] = os.time()

local function trim(s) return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', '')) end
local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

CreateThread(function()
    Wait(800)
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS mechanic_vehicles (plate VARCHAR(12) PRIMARY KEY, cond TEXT NOT NULL, km FLOAT NOT NULL DEFAULT 0, updated INT NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS mechanic_stock (item VARCHAR(50) PRIMARY KEY, qty INT NOT NULL, last INT NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    local rows = {}
    for _, r in ipairs(MySQL.query.await('SELECT * FROM mechanic_stock') or {}) do rows[r.item] = r end
    local now = os.time()
    for _, p in ipairs(C.Shop.Parts) do
        local r = rows[p.item]
        Stock[p.item] = { qty = r and math.min(r.qty, p.max) or p.max, last = r and r.last or now }
    end
end)

-- ═══════════════ Qui est mécanicien ═══════════════
local function isMech(x)
    if not x or not x.job then return false end
    for _, j in ipairs(C.Jobs) do if x.job.name == j then return true end end
    if GetResourceState('pickax_jobbuilder') == 'started' then
        local ok, t = pcall(function() return exports.pickax_jobbuilder:GetJobType(x.job.name) end)
        if ok and t then for _, jt in ipairs(C.JobTypes) do if t == jt then return true end end end
    end
    return false
end

local function near(src, c, d) return #(GetEntityCoords(GetPlayerPed(src)) - c) <= d end

-- ═══════════════ État des véhicules ═══════════════
local function load(plate)
    local v = Veh[plate]
    if v then return v end
    local r = MySQL.single.await('SELECT cond, km FROM mechanic_vehicles WHERE plate = ?', { plate })
    if r then
        local ok, cond = pcall(json.decode, r.cond)
        v = { cond = ok and cond or {}, km = r.km or 0 }
    else
        v = { cond = {}, km = 0, dirty = true }
    end
    for _, k in ipairs(C.ComponentOrder) do
        if k ~= 'body' and v.cond[k] == nil then v.cond[k] = math.random(C.Initial.min, C.Initial.max) + 0.0 end
    end
    Veh[plate] = v
    return v
end

local function save(plate)
    local v = Veh[plate]
    if not v or not v.dirty then return end
    v.dirty = false
    MySQL.query('INSERT INTO mechanic_vehicles (plate, cond, km, updated) VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE cond = VALUES(cond), km = VALUES(km), updated = VALUES(updated)', { plate, json.encode(v.cond), v.km, os.time() })
end

CreateThread(function() while true do Wait(60000) for p in pairs(Veh) do save(p) end end end)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then for p in pairs(Veh) do save(p) end end end)

local function publicCond(v, engineNative, bodyNative)
    local c = {}
    for _, k in ipairs(C.ComponentOrder) do c[k] = math.floor((v.cond[k] or 100) + 0.5) end
    -- le moteur et la carrosserie tiennent aussi compte des dégâts réels (lus par le client)
    if engineNative then c.engine = math.min(c.engine, math.floor(clamp(engineNative / 10, 0, 100) + 0.5)) end
    if bodyNative then c.body = math.floor(clamp(bodyNative / 10, 0, 100) + 0.5) else c.body = c.body or 100 end
    return c
end

local function vehicleOf(src, netId)
    local veh = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if not veh or veh == 0 or not DoesEntityExist(veh) or GetEntityType(veh) ~= 2 then return nil end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(veh)) > C.MaxDistance + 4.0 then return nil end
    return veh, trim(GetVehicleNumberPlateText(veh))
end

-- ═══════════════ Usure : rapports du conducteur ═══════════════
RegisterNetEvent('pickax_mechanic:enter', function(netId)
    local src = source
    local veh = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    if GetPedInVehicleSeat(veh, -1) ~= GetPlayerPed(src) then return end
    local plate = trim(GetVehicleNumberPlateText(veh))
    if plate == '' then return end
    local v = load(plate)
    LastWear[src] = os.time()
    Entity(veh).state:set('mech', v.cond, true)
end)

RegisterNetEvent('pickax_mechanic:wear', function(netId, meters, maxKmh, hard, impacts)
    local src = source
    if not C.Enabled then return end
    local veh = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if not veh or veh == 0 or not DoesEntityExist(veh) or GetPedInVehicleSeat(veh, -1) ~= GetPlayerPed(src) then return end
    local now = os.time()
    local dt = now - (LastWear[src] or now)
    if dt < C.Wear.ReportEvery - 5 then return end
    LastWear[src] = now
    meters = tonumber(meters) or 0
    if meters <= 0 or meters > C.Wear.MaxSpeed * dt then return end
    local plate = trim(GetVehicleNumberPlateText(veh))
    local v = load(plate)
    local km = meters / 1000.0
    local f = (tonumber(maxKmh) or 0) > 120 and C.Wear.SpeedFactor or 1.0
    for k, per in pairs(C.Wear.PerKm) do v.cond[k] = math.max(0, (v.cond[k] or 100) - per * km * f) end
    hard, impacts = clamp(math.floor(tonumber(hard) or 0), 0, 10), clamp(math.floor(tonumber(impacts) or 0), 0, 3)
    for k, per in pairs(C.Wear.HardBrakeCost) do v.cond[k] = math.max(0, (v.cond[k] or 100) - per * hard) end
    for k, per in pairs(C.Wear.ImpactCost) do if per > 0 then v.cond[k] = math.max(0, (v.cond[k] or 100) - per * impacts) end end
    v.km = (v.km or 0) + km
    v.dirty = true
    Entity(veh).state:set('mech', v.cond, true)
end)

RegisterNetEvent('pickax_mechanic:cancel', function() Pending[source] = nil end)
AddEventHandler('playerDropped', function() LastWear[source] = nil Pending[source] = nil end)

-- ═══════════════ Magasin de pièces ═══════════════
local function restock()
    local now, changed = os.time(), false
    for _, p in ipairs(C.Shop.Parts) do
        local s = Stock[p.item]
        if s and s.qty < p.max and now - s.last >= p.every * 60 then
            local cycles = math.floor((now - s.last) / (p.every * 60))
            s.qty = math.min(p.max, s.qty + cycles * p.amount)
            s.last = s.last + cycles * p.every * 60
            changed = true
        elseif s and s.qty >= p.max then s.last = now end
        if changed and s then MySQL.query('INSERT INTO mechanic_stock (item, qty, last) VALUES (?,?,?) ON DUPLICATE KEY UPDATE qty = VALUES(qty), last = VALUES(last)', { p.item, s.qty, s.last }) end
    end
end
CreateThread(function() Wait(5000) while true do restock() Wait(60000) end end)

local function partDef(item) for _, p in ipairs(C.Shop.Parts) do if p.item == item then return p end end end

local function shopOf(src, idx)
    local s = C.Shops[tonumber(idx) or 0]
    if not s or not near(src, s.coords, C.Shop.Distance + 3.0) then return nil end
    return s
end

ESX.RegisterServerCallback('pickax_mechanic:shopOpen', function(src, cb, idx)
    local x = ESX.GetPlayerFromId(src)
    if not isMech(x) then return cb({ ok = false, error = 'Réservé aux mécaniciens' }) end
    local s = shopOf(src, idx)
    if not s then return cb({ ok = false, error = 'Trop loin' }) end
    restock()
    local list = {}
    for _, p in ipairs(C.Shop.Parts) do
        local st = Stock[p.item] or { qty = 0, last = os.time() }
        local nextIn = (st.qty < p.max) and math.max(0, p.every * 60 - (os.time() - st.last)) or nil
        list[#list + 1] = { item = p.item, label = p.label, price = p.price, stock = st.qty, max = p.max, have = exports.ox_inventory:GetItemCount(src, p.item) or 0, nextIn = nextIn, amount = p.amount }
    end
    cb({ ok = true, label = s.label, parts = list, balance = x.getAccount(C.Shop.Account).money, account = C.Shop.Account, maxPerOrder = C.Shop.MaxPerOrder })
end)

local busy = {}
ESX.RegisterServerCallback('pickax_mechanic:buy', function(src, cb, idx, item, qty)
    local x = ESX.GetPlayerFromId(src)
    if not isMech(x) then return cb({ ok = false, error = 'Réservé aux mécaniciens' }) end
    if not shopOf(src, idx) then return cb({ ok = false, error = 'Trop loin' }) end
    local p = partDef(tostring(item or ''))
    qty = math.floor(tonumber(qty) or 0)
    if not p or qty < 1 or qty > C.Shop.MaxPerOrder then return cb({ ok = false, error = 'Quantité invalide' }) end
    if busy[src] then return cb({ ok = false, error = 'Patiente' }) end
    busy[src] = true
    local st = Stock[p.item]
    local function done(r) busy[src] = nil cb(r) end
    if not st or st.qty < qty then return done({ ok = false, error = st and st.qty > 0 and ('Il ne reste que %d en stock'):format(st.qty) or 'Rupture de stock' }) end
    local total = p.price * qty
    if x.getAccount(C.Shop.Account).money < total then return done({ ok = false, error = 'Fonds insuffisants' }) end
    if not exports.ox_inventory:CanCarryItem(src, p.item, qty) then return done({ ok = false, error = 'Tu ne peux pas porter autant' }) end
    x.removeAccountMoney(C.Shop.Account, total, 'Pièces détachées')
    exports.ox_inventory:AddItem(src, p.item, qty)
    st.qty = st.qty - qty
    MySQL.query('INSERT INTO mechanic_stock (item, qty, last) VALUES (?,?,?) ON DUPLICATE KEY UPDATE qty = VALUES(qty), last = VALUES(last)', { p.item, st.qty, st.last })
    done({ ok = true, msg = ('%d × %s achetée(s) pour %d $.'):format(qty, p.label, total) })
end)

-- ═══════════════ Diagnostic et réparations ═══════════════
local function inWorkshop(src)
    if not C.RequireWorkshop then return true end
    local pc = GetEntityCoords(GetPlayerPed(src))
    for _, w in ipairs(C.Workshops) do if #(pc - w.coords) <= w.radius then return true end end
    return false
end

local function repairList(src)
    local out = {}
    for _, k in ipairs(C.ComponentOrder) do
        local r = C.Repairs[k]
        if r then
            local parts, can = {}, true
            for _, pt in ipairs(r.parts) do
                local have = exports.ox_inventory:GetItemCount(src, pt[1]) or 0
                local def = partDef(pt[1])
                parts[#parts + 1] = { item = pt[1], label = def and def.label or pt[1], need = pt[2], have = have }
                if have < pt[2] then can = false end
            end
            out[k] = { label = r.label, parts = parts, can = can, game = r.game, seconds = r.seconds }
        end
    end
    return out
end

ESX.RegisterServerCallback('pickax_mechanic:info', function(src, cb, netId, engineNative, bodyNative)
    local x = ESX.GetPlayerFromId(src)
    if not isMech(x) then return cb({ ok = false, error = 'Réservé aux mécaniciens' }) end
    local veh, plate = vehicleOf(src, netId)
    if not veh then return cb({ ok = false, error = 'Aucun véhicule à portée' }) end
    if not inWorkshop(src) then return cb({ ok = false, error = 'Il faut être dans un atelier' }) end
    local v = load(plate)
    cb({ ok = true, plate = plate, km = math.floor(v.km or 0), cond = publicCond(v, tonumber(engineNative), tonumber(bodyNative)), repairs = repairList(src),
        components = C.Components, order = C.ComponentOrder, tool = C.Tool ~= '' and { item = C.Tool, have = (exports.ox_inventory:GetItemCount(src, C.Tool) or 0) } or nil })
end)

ESX.RegisterServerCallback('pickax_mechanic:repairBegin', function(src, cb, netId, comp)
    local x = ESX.GetPlayerFromId(src)
    if not isMech(x) then return cb({ ok = false, error = 'Réservé aux mécaniciens' }) end
    local veh, plate = vehicleOf(src, netId)
    local r = C.Repairs[tostring(comp or '')]
    if not veh or not r then return cb({ ok = false, error = 'Réparation impossible' }) end
    if not inWorkshop(src) then return cb({ ok = false, error = 'Il faut être dans un atelier' }) end
    if C.Tool ~= '' and (exports.ox_inventory:GetItemCount(src, C.Tool) or 0) < 1 then return cb({ ok = false, error = 'Il te faut : ' .. C.Tool }) end
    for _, pt in ipairs(r.parts) do
        if (exports.ox_inventory:GetItemCount(src, pt[1]) or 0) < pt[2] then
            local d = partDef(pt[1])
            return cb({ ok = false, error = ('Pièce manquante : %s ×%d — va en acheter au magasin de pièces.'):format(d and d.label or pt[1], pt[2]) })
        end
    end
    Pending[src] = { comp = comp, plate = plate, netId = tonumber(netId), at = GetGameTimer() }
    cb({ ok = true, game = r.game, seed = math.random(1, 2147483000), rounds = r.rounds, bolts = r.seed, seconds = r.seconds, label = r.label })
end)

ESX.RegisterServerCallback('pickax_mechanic:repairEnd', function(src, cb, score)
    local x = ESX.GetPlayerFromId(src)
    local p = Pending[src]
    Pending[src] = nil
    if not isMech(x) or not p then return cb({ ok = false, error = 'Aucune réparation en cours' }) end
    if GetGameTimer() - p.at < C.MinSeconds * 1000 then return cb({ ok = false, error = 'Réparation trop rapide : refusée' }) end
    local r = C.Repairs[p.comp]
    local veh = NetworkGetEntityFromNetworkId(p.netId or 0)
    if not r or not veh or veh == 0 or not DoesEntityExist(veh) or #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(veh)) > C.MaxDistance + 4.0 then return cb({ ok = false, error = 'Véhicule hors de portée' }) end
    for _, pt in ipairs(r.parts) do
        if (exports.ox_inventory:GetItemCount(src, pt[1]) or 0) < pt[2] then return cb({ ok = false, error = 'Pièces manquantes' }) end
    end
    -- les pièces sont consommées dans tous les cas (une réparation ratée détruit ce qu'on a monté)
    for _, pt in ipairs(r.parts) do exports.ox_inventory:RemoveItem(src, pt[1], pt[2]) end
    score = clamp(math.floor(tonumber(score) or 0), 0, 100)
    if score < C.FailBelow then
        return cb({ ok = true, failed = true, score = score, msg = 'Réparation ratée : les pièces sont inutilisables.' })
    end
    local q = C.QualityFloor + (1 - C.QualityFloor) * (score - C.FailBelow) / (100 - C.FailBelow)
    local gain = math.floor(r.gain * q + 0.5)
    local v = load(p.plate)
    local new = {}
    if p.comp == 'body' then
        new.body = clamp(gain, 0, 100)
    else
        v.cond[p.comp] = math.min(100, (v.cond[p.comp] or 0) + gain)
        if p.comp == 'engine' then new.engine = v.cond.engine end
        if p.comp == 'tires' then new.tires = true end
    end
    v.dirty = true
    Entity(veh).state:set('mech', v.cond, true)
    save(p.plate)
    cb({ ok = true, score = score, gain = gain, apply = new, comp = p.comp, msg = ('%s : +%d %%.'):format(C.Components[p.comp].label, gain) })
end)

exports('IsMechanic', function(src) return isMech(ESX.GetPlayerFromId(tonumber(src) or 0)) end)
