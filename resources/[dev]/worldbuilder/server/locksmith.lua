-- ─────────────────────────────── Serrurier : refaire des clés de véhicule ───────────────────────────────
local V = Config.Vehicles
local function col(c) return '`' .. c .. '`' end
local function trimPlate(p) return (tostring(p or ''):gsub('^%s+', ''):gsub('%s+$', '')) end

local function resolve(src, eid, pi)
    local e = WB.Entities[tonumber(eid) or 0]
    local x = ESX.GetPlayerFromId(src)
    if not e or e.type ~= 'locksmith' or not e.enabled or not x then return nil, 'Introuvable' end
    local p = e.points[tonumber(pi) or 0]
    if not p or p.kind ~= 'shop' or not p.coords or not WB.near(src, p.coords, 4.0) then return nil, 'Trop loin' end
    local ok, err = WB.hasAccess(x, e.settings.access)
    if not ok then return nil, err end
    return e, p, x
end

-- Plaques des véhicules présents près de l'atelier (vérifié côté serveur, pas par le client)
local function nearbyPlates(c, radius)
    local set = {}
    for _, veh in ipairs(GetAllVehicles()) do
        local vc = GetEntityCoords(veh)
        if #(vector3(vc.x, vc.y, vc.z) - vector3(c.x, c.y, c.z)) <= radius then set[trimPlate(GetVehicleNumberPlateText(veh))] = true end
    end
    return set
end

local function owned(x)
    return MySQL.query.await(('SELECT %s AS plate, %s AS props FROM %s WHERE %s = ?'):format(col(V.plate), col(V.props), col(V.table), col(V.owner)), { x.identifier }) or {}
end

ESX.RegisterServerCallback('worldbuilder:locksmith:info', function(src, cb, eid, pi)
    local e, p, x = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local s = e.settings
    local near = nearbyPlates(p.coords, 25.0)
    local list = {}
    for _, r in ipairs(owned(x)) do
        local plate = trimPlate(r.plate)
        local props = WB.decode(r.props, {}) or {}
        local here = near[plate] == true
        local has = WB.hasKey(x.identifier, props.plate or r.plate)
        local can = (here or not s.requireNearby) and (has ~= true or s.allowIfHasKey == true)
        list[#list + 1] = { plate = r.plate, model = props.model, nearby = here, hasKey = has, canMake = can }
    end
    cb({ ok = true, label = p.label ~= '' and p.label or e.label, price = s.price or 0, requireNearby = s.requireNearby, vehicles = list, payments = WB.paymentsList(s.payments, x) })
end)

-- ─────────────────────────────── Système de clés (détection + remise) ───────────────────────────────
local K = Config.Keys or {}

local function keyResource()
    local r = K.resource
    if r and r ~= '' and GetResourceState(r) == 'started' then return r end
end

-- Même source de vérité que le script de clés : la table open_car (identifier + value = plaque). nil = système inconnu.
function WB.hasKey(identifier, plate)
    if not keyResource() then return nil end
    local ok, row = pcall(function()
        return MySQL.scalar.await(('SELECT 1 FROM `%s` WHERE identifier = ? AND TRIM(value) = ? LIMIT 1'):format(K.table or 'open_car'), { identifier, trimPlate(plate) })
    end)
    if not ok then return nil end
    return row ~= nil
end

-- plate = plaque EXACTE telle que le client la lit (celle du JSON des propriétés) : le script de clés compare des chaînes identiques
function WB.giveKey(src, plate, s)
    if Config.GiveKey and Config.GiveKey(src, plate, s) then return true end
    local r = keyResource()
    if r then
        local ok, err = pcall(function() exports[r]:RegisterNewKeys(src, plate, 'no') end)
        if ok then return true end
        print(('^1[worldbuilder] RegisterNewKeys a échoué dans « %s » : %s^0'):format(r, tostring(err)))
    end
    if s and s.keyItem and s.keyItem ~= '' then
        if WB.inventory() == 'ox' then
            return exports.ox_inventory:AddItem(src, s.keyItem, 1, { plate = plate, description = 'Clé du véhicule ' .. plate }) and true or false
        end
        return WB.addItem(src, s.keyItem, 1)
    end
    TriggerClientEvent('worldbuilder:client:giveKeys', src, plate)
    return true
end

-- Vente entre joueurs : l'ancien propriétaire perd ses clés, le nouveau reçoit la sienne
function WB.transferKeys(src, plate, s)
    local r = keyResource()
    if r and K.transferExport then
        local ok = pcall(function() exports[r]:TransferKeys(plate, src) end)
        if ok then return true end
    end
    if r then pcall(function() MySQL.update(('DELETE FROM `%s` WHERE TRIM(value) = ?'):format(K.table or 'open_car'), { trimPlate(plate) }) end) end
    return WB.giveKey(src, plate, s)
end

ESX.RegisterServerCallback('worldbuilder:locksmith:make', function(src, cb, eid, pi, plate, method)
    local e, p, x = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local s = e.settings
    plate = trimPlate(plate)
    local row = MySQL.single.await(('SELECT %s AS plate, %s AS props FROM %s WHERE %s = ? AND TRIM(%s) = ?'):format(col(V.plate), col(V.props), col(V.table), col(V.owner), col(V.plate)), { x.identifier, plate })
    if not row then return cb({ ok = false, error = 'Ce véhicule ne t\'appartient pas' }) end
    local exact = (WB.decode(row.props, {}) or {}).plate or row.plate
    if WB.hasKey(x.identifier, exact) == true and s.allowIfHasKey ~= true then return cb({ ok = false, error = 'Tu as déjà la clé de ce véhicule' }) end
    if s.requireNearby and not nearbyPlates(p.coords, 25.0)[plate] then return cb({ ok = false, error = 'Le véhicule doit être près de l\'atelier' }) end
    if (s.cooldown or 0) > 0 then
        local c = WB.counter(('key:%s:%s'):format(x.identifier, plate), s.cooldown)
        if c.n > 0 then return cb({ ok = false, error = 'Une clé vient déjà d\'être faite pour ce véhicule' }) end
        c.n = 1
    end
    local okp, err = WB.charge(x, s.payments, method, s.price, 'Serrurier : ' .. e.label)
    if not okp then return cb({ ok = false, error = err }) end
    if not WB.giveKey(src, exact, s) then
        x.addAccountMoney((Config.Payments[method] or Config.Payments.cash).account, math.floor(s.price or 0), 'Remboursement serrurier')
        return cb({ ok = false, error = 'Impossible de te donner la clé (inventaire plein ?) — remboursé' })
    end
    WB.society(s.society, s.price)
    WB.stat(e, 'revenue', s.price) WB.stat(e, 'keys', 1)
    WB.log(e, x, 'key', plate, s.price)
    cb({ ok = true, plate = plate, paid = math.floor(s.price or 0) })
end)
