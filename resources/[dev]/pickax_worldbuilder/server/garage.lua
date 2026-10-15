-- ─────────────────────────────── Garages & fourrières ───────────────────────────────
local V = Config.Vehicles
local function col(c) return '`' .. c .. '`' end
local T = col(V.table)

local Out = {}          -- [plate] = { src, at, netId } véhicules sortis (suivi)
-- oxmysql renvoie true/false pour les TINYINT(1) : on normalise en 0/1/2
local function st(v)
    if v == true then return 1 elseif v == false then return 0 end
    return tonumber(v) or 0
end
local function trimPlate(p) return (tostring(p or ''):gsub('^%s+', ''):gsub('%s+$', '')) end

local function ownedRow(identifier, plate)
    return MySQL.single.await(('SELECT %s AS plate, %s AS props, %s AS stored%s FROM %s WHERE %s = ? AND TRIM(%s) = ?'):format(
        col(V.plate), col(V.props), col(V.stored), V.type and (', ' .. col(V.type) .. ' AS vtype') or '', T, col(V.owner), col(V.plate)), { identifier, trimPlate(plate) })
end

local function typeAllowed(settings, vtype)
    local types = settings.types
    if not types or #types == 0 or not V.type or not vtype then return true end
    for _, t in ipairs(types) do if t == vtype then return true end end
    return false
end

local function propsInfo(row)
    local p = WB.decode(row.props, {}) or {}
    return { plate = row.plate, model = p.model, fuel = p.fuelLevel, engine = p.engineHealth, body = p.bodyHealth, stored = st(row.stored), vtype = row.vtype }
end

local function resolve(src, eid, pi, tp)
    local e = WB.Entities[tonumber(eid) or 0]
    local xPlayer = ESX.GetPlayerFromId(src)
    if not e or e.type ~= tp or not e.enabled or not xPlayer then return nil, 'Introuvable' end
    local p = e.points[tonumber(pi) or 0]
    if not p or not p.coords or not WB.near(src, p.coords, 6.0) then return nil, 'Trop loin' end
    local ok, err = WB.hasAccess(xPlayer, e.settings.access)
    if not ok then return nil, err end
    return e, p, xPlayer
end

-- Véhicule (entité) accessible côté serveur : doit exister et se trouver près du point
local function vehicleFromNet(src, netId, near)
    local ent = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if not ent or ent == 0 or not DoesEntityExist(ent) or GetEntityType(ent) ~= 2 then return nil, 'Véhicule introuvable' end
    local c = GetEntityCoords(ent)
    if near and #(vector3(c.x, c.y, c.z) - vector3(near.x, near.y, near.z)) > (Config.ServerDistance + 12.0) then return nil, 'Véhicule trop loin' end
    return ent
end

RegisterNetEvent('worldbuilder:server:vehicleSpawned', function(plate, netId)
    local src = source
    plate = trimPlate(plate)
    if Out[plate] and Out[plate].src == src then Out[plate].netId = netId end
end)

RegisterNetEvent('worldbuilder:server:vehicleFailed', function(plate)
    local src = source
    plate = trimPlate(plate)
    SetTimeout(2500, function()
        local o = Out[plate]
        local xPlayer = ESX.GetPlayerFromId(src)
        -- refusé si le véhicule existe bel et bien (sinon le joueur le garderait ET le retrouverait au garage)
        if o and o.src == src and not o.netId and xPlayer and not WB.plateInWorld(plate) then
            MySQL.update(('UPDATE %s SET %s = 1 WHERE %s = ? AND TRIM(%s) = ?'):format(T, col(V.stored), col(V.owner), col(V.plate)), { xPlayer.identifier, plate })
            Out[plate] = nil
        end
    end)
end)

-- Un véhicule « sorti » existe-t-il encore dans le monde ?
local function isInWorld(plate)
    local o = Out[plate]
    if not o then return false end
    if not o.netId then return GetGameTimer() - o.at < 60000 end      -- vient d'être sorti, pas encore de netId
    local ent = NetworkGetEntityFromNetworkId(o.netId)
    if ent and ent ~= 0 and DoesEntityExist(ent) then return true end
    Out[plate] = nil
    return false
end

-- ═══════════════════════════════ GARAGES ═══════════════════════════════
ESX.RegisterServerCallback('worldbuilder:garage:list', function(src, cb, eid, pi)
    local e, p, xPlayer = resolve(src, eid, pi, 'garage')
    if not e then return cb({ ok = false, error = p }) end
    local s = e.settings
    local res = { ok = true, mode = s.mode, fee = s.fee or 0, label = e.label, payments = WB.paymentsList(s.payments, xPlayer), vehicles = {}, fleet = {} }
    if s.mode == 'job' then
        for i, f in ipairs(s.fleet or {}) do
            if xPlayer.job.grade >= (f.minGrade or 0) then res.fleet[#res.fleet + 1] = { i = i, model = f.model, label = f.label ~= '' and f.label or f.model, price = f.price or 0 } end
        end
        return cb(res)
    end
    local rows = MySQL.query.await(('SELECT %s AS plate, %s AS props, %s AS stored%s FROM %s WHERE %s = ? AND %s = 1'):format(
        col(V.plate), col(V.props), col(V.stored), V.type and (', ' .. col(V.type) .. ' AS vtype') or '', T, col(V.owner), col(V.stored)), { xPlayer.identifier }) or {}
    local bound = {}
    if s.bound and #rows > 0 then
        for _, r in ipairs(MySQL.query.await('SELECT plate, entity_id FROM worldbuilder_parking') or {}) do bound[r.plate] = r.entity_id end
    end
    for _, r in ipairs(rows) do
        local plate = trimPlate(r.plate)
        if typeAllowed(s, r.vtype) and (not s.bound or not bound[plate] or bound[plate] == e.id) then res.vehicles[#res.vehicles + 1] = propsInfo(r) end
    end
    cb(res)
end)

ESX.RegisterServerCallback('worldbuilder:garage:take', function(src, cb, eid, pi, plate, spawnIdx, method)
    local e, p, xPlayer = resolve(src, eid, pi, 'garage')
    if not e then return cb({ ok = false, error = p }) end
    local s = e.settings
    spawnIdx = tonumber(spawnIdx) or 0
    if not p.spawns or not p.spawns[spawnIdx] then return cb({ ok = false, error = 'Aucune place de sortie configurée' }) end

    if s.mode == 'job' then
        local f = (s.fleet or {})[tonumber(plate) or 0]
        if not f or xPlayer.job.grade < (f.minGrade or 0) then return cb({ ok = false, error = 'Véhicule indisponible' }) end
        local okp, err = WB.charge(xPlayer, s.payments, method, f.price, 'Garage : ' .. e.label)
        if not okp then return cb({ ok = false, error = err }) end
        WB.society(s.society, f.price)
        WB.log(e, xPlayer, 'fleet', f.model, f.price)
        return cb({ ok = true, fleet = true, model = f.model, spawn = spawnIdx })
    end

    plate = trimPlate(plate)
    local row = ownedRow(xPlayer.identifier, plate)
    if not row or st(row.stored) ~= 1 or not typeAllowed(s, row.vtype) then return cb({ ok = false, error = 'Véhicule indisponible' }) end
    if (s.fee or 0) > 0 then
        local okp, err = WB.charge(xPlayer, s.payments, method, s.fee, 'Garage : ' .. e.label)
        if not okp then return cb({ ok = false, error = err }) end
        WB.society(s.society, s.fee)
    end
    MySQL.update.await(('UPDATE %s SET %s = 0 WHERE %s = ? AND %s = ?'):format(T, col(V.stored), col(V.owner), col(V.plate)), { xPlayer.identifier, row.plate })
    Out[plate] = { src = src, at = GetGameTimer() }
    WB.log(e, xPlayer, 'take', plate, s.fee)
    cb({ ok = true, props = WB.decode(row.props, {}), plate = row.plate, spawn = spawnIdx })
end)

ESX.RegisterServerCallback('worldbuilder:garage:store', function(src, cb, eid, pi, netId, props)
    local e, p, xPlayer = resolve(src, eid, pi, 'garage')
    if not e then return cb({ ok = false, error = p }) end
    local s = e.settings
    local ent, err = vehicleFromNet(src, netId, p.store or p.coords)
    if not ent then return cb({ ok = false, error = err }) end
    local plate = trimPlate(GetVehicleNumberPlateText(ent))

    if s.mode == 'job' then
        local model = GetEntityModel(ent)
        for _, f in ipairs(s.fleet or {}) do
            if joaat(f.model) == model then
                DeleteEntity(ent)
                return cb({ ok = true })
            end
        end
        return cb({ ok = false, error = 'Ce véhicule ne fait pas partie de la flotte' })
    end

    local row = ownedRow(xPlayer.identifier, plate)
    if not row then return cb({ ok = false, error = 'Ce véhicule ne t\'appartient pas' }) end
    if not typeAllowed(s, row.vtype) then return cb({ ok = false, error = 'Ce garage n\'accepte pas ce type de véhicule' }) end
    local encoded
    if type(props) == 'table' then
        props.plate = row.plate
        encoded = json.encode(props)
        if #encoded > 30000 then encoded = nil end
    end
    if encoded then
        MySQL.update.await(('UPDATE %s SET %s = 1, %s = ? WHERE %s = ? AND %s = ?'):format(T, col(V.stored), col(V.props), col(V.owner), col(V.plate)), { encoded, xPlayer.identifier, row.plate })
    else
        MySQL.update.await(('UPDATE %s SET %s = 1 WHERE %s = ? AND %s = ?'):format(T, col(V.stored), col(V.owner), col(V.plate)), { xPlayer.identifier, row.plate })
    end
    if s.bound then MySQL.update('INSERT INTO worldbuilder_parking (plate, entity_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE entity_id = VALUES(entity_id)', { plate, e.id }) end
    MySQL.update('DELETE FROM worldbuilder_impound WHERE plate = ?', { plate })
    Out[plate] = nil
    DeleteEntity(ent)
    WB.log(e, xPlayer, 'store', plate)
    cb({ ok = true })
end)

-- ═══════════════════════════════ FOURRIÈRES ═══════════════════════════════
local function impoundFee(s, plate)
    local rec = MySQL.single.await('SELECT fee, reason, officer, UNIX_TIMESTAMP(created_at) AS t FROM worldbuilder_impound WHERE plate = ?', { plate })
    local fee, reason = s.fee or 0, nil
    if rec then
        reason = rec.reason
        if (rec.fee or 0) > 0 then fee = rec.fee end
        local days = math.floor((os.time() - (tonumber(rec.t) or os.time())) / 86400)
        if (s.perDay or 0) > 0 and days > 0 then fee = fee + s.perDay * days end
    end
    if (s.maxFee or 0) > 0 and fee > s.maxFee then fee = s.maxFee end
    return fee, reason, rec and rec.officer or nil
end

local function canImpound(xPlayer, s)
    local jobs = s.impoundJobs
    if not jobs or not next(jobs) then return false end
    return WB.jobAllowed(xPlayer, jobs)
end

ESX.RegisterServerCallback('worldbuilder:impound:list', function(src, cb, eid, pi)
    local e, p, xPlayer = resolve(src, eid, pi, 'impound')
    if not e then return cb({ ok = false, error = p }) end
    local s = e.settings
    local rows = MySQL.query.await(('SELECT %s AS plate, %s AS props, %s AS stored%s FROM %s WHERE %s = ? AND %s IN (0, 2)'):format(
        col(V.plate), col(V.props), col(V.stored), V.type and (', ' .. col(V.type) .. ' AS vtype') or '', T, col(V.owner), col(V.stored)), { xPlayer.identifier }) or {}
    local list = {}
    for _, r in ipairs(rows) do
        local plate = trimPlate(r.plate)
        if typeAllowed(s, r.vtype) and (st(r.stored) == 2 or not isInWorld(plate)) then
            local info = propsInfo(r)
            info.fee, info.reason = impoundFee(s, plate)
            list[#list + 1] = info
        end
    end
    cb({ ok = true, label = e.label, vehicles = list, payments = WB.paymentsList(s.payments, xPlayer), canImpound = canImpound(xPlayer, s) })
end)

ESX.RegisterServerCallback('worldbuilder:impound:take', function(src, cb, eid, pi, plate, spawnIdx, method)
    local e, p, xPlayer = resolve(src, eid, pi, 'impound')
    if not e then return cb({ ok = false, error = p }) end
    local s = e.settings
    spawnIdx = tonumber(spawnIdx) or 0
    if not p.spawns or not p.spawns[spawnIdx] then return cb({ ok = false, error = 'Aucune place de sortie configurée' }) end
    plate = trimPlate(plate)
    local row = ownedRow(xPlayer.identifier, plate)
    if not row or not typeAllowed(s, row.vtype) then return cb({ ok = false, error = 'Véhicule introuvable' }) end
    local stored = st(row.stored)
    if stored == 1 then return cb({ ok = false, error = 'Ce véhicule est au garage' }) end
    if stored == 0 and isInWorld(plate) then return cb({ ok = false, error = 'Ce véhicule est déjà sorti' }) end
    local fee = impoundFee(s, plate)
    local okp, err = WB.charge(xPlayer, s.payments, method, fee, 'Fourrière : ' .. e.label)
    if not okp then return cb({ ok = false, error = err }) end
    WB.society(s.society, fee)
    MySQL.update.await(('UPDATE %s SET %s = 0 WHERE %s = ? AND %s = ?'):format(T, col(V.stored), col(V.owner), col(V.plate)), { xPlayer.identifier, row.plate })
    MySQL.update('DELETE FROM worldbuilder_impound WHERE plate = ?', { plate })
    Out[plate] = { src = src, at = GetGameTimer() }
    WB.stat(e, 'revenue', fee) WB.stat(e, 'released', 1)
    WB.log(e, xPlayer, 'release', plate, fee)
    cb({ ok = true, props = WB.decode(row.props, {}), plate = row.plate, spawn = spawnIdx, paid = fee })
end)

-- Mise en fourrière d'un véhicule (entité) : possédé → stored = 2 ; sinon supprimé
local function seize(ent, e, reason, fee, officer)
    local plate = trimPlate(GetVehicleNumberPlateText(ent))
    local row = MySQL.single.await(('SELECT %s AS plate FROM %s WHERE TRIM(%s) = ?'):format(col(V.plate), T, col(V.plate)), { plate })
    if row then
        MySQL.update.await(('UPDATE %s SET %s = 2 WHERE TRIM(%s) = ?'):format(T, col(V.stored), col(V.plate)), { plate })
        MySQL.update('INSERT INTO worldbuilder_impound (plate, impound_id, reason, fee, officer) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE impound_id = VALUES(impound_id), reason = VALUES(reason), fee = VALUES(fee), officer = VALUES(officer), created_at = current_timestamp()',
            { plate, e and e.id or 0, tostring(reason or ''):sub(1, 200), math.floor(tonumber(fee) or 0), tostring(officer or ''):sub(1, 100) })
    end
    Out[plate] = nil
    DeleteEntity(ent)
    return plate, row ~= nil
end

ESX.RegisterServerCallback('worldbuilder:impound:seize', function(src, cb, eid, pi, netId, reason, fee)
    local e, p, xPlayer = resolve(src, eid, pi, 'impound')
    if not e then return cb({ ok = false, error = p }) end
    if not canImpound(xPlayer, e.settings) then return cb({ ok = false, error = 'Tu n\'as pas le droit de mettre un véhicule en fourrière' }) end
    local ent, err = vehicleFromNet(src, netId, p.coords)
    if not ent then return cb({ ok = false, error = err }) end
    fee = math.floor(tonumber(fee) or 0)
    if fee < 0 then fee = 0 end
    if fee > 1000000 then fee = 1000000 end
    local plate, owned = seize(ent, e, reason, fee, WB.playerName(xPlayer))
    WB.stat(e, 'seized', 1)
    WB.log(e, xPlayer, 'seize', ('%s — %s'):format(plate, tostring(reason or ''):sub(1, 100)), fee)
    cb({ ok = true, plate = plate, owned = owned })
end)

-- Intégration externe : exports.pickax_worldbuilder:ImpoundVehicle(vehicleEntity, impoundModuleId, reason, fee, officerName)
exports('ImpoundVehicle', function(ent, impoundId, reason, fee, officer)
    if not ent or not DoesEntityExist(ent) then return false end
    return seize(ent, WB.Entities[tonumber(impoundId) or 0], reason, fee, officer or 'système') ~= nil
end)

-- ─────────────────────────────── Redémarrage du serveur ───────────────────────────────
-- Détection des colonnes de la table des véhicules (ajoute `stored` si absente, désactive `type` si absente)
local function ensureColumns()
    local rows = MySQL.query.await('SELECT COLUMN_NAME AS c FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?', { V.table }) or {}
    local have = {}
    for _, r in ipairs(rows) do have[r.c:lower()] = r.c end
    if next(have) == nil then print(('^1[worldbuilder] table `%s` introuvable : adapte Config.Vehicles^0'):format(V.table)) return end
    for _, k in ipairs({ 'owner', 'plate', 'props' }) do
        if not have[V[k]:lower()] then print(('^1[worldbuilder] colonne `%s` absente de `%s` : adapte Config.Vehicles.%s^0'):format(V[k], V.table, k)) end
    end
    if not have[V.stored:lower()] then
        local found
        for _, alt in ipairs({ 'state', 'garage_state', 'in_garage' }) do if have[alt] then found = have[alt] break end end
        if found then
            print(('^3[worldbuilder] colonne `%s` absente : utilisation de `%s` (1 = garage, 0 = sorti)^0'):format(V.stored, found))
            V.stored = found
        else
            MySQL.query.await(('ALTER TABLE %s ADD COLUMN %s TINYINT(1) NOT NULL DEFAULT 1'):format(T, col(V.stored)))
            print(('^3[worldbuilder] colonne `%s` ajoutée à `%s` (tous les véhicules sont considérés au garage)^0'):format(V.stored, V.table))
        end
    end
    if V.type and not have[V.type:lower()] then
        print(('^3[worldbuilder] colonne `%s` absente : le filtre par type de véhicule est désactivé^0'):format(V.type))
        V.type = nil
    end
end

function WB.onReady()
    local ok, err = pcall(ensureColumns)
    if not ok then print('^1[worldbuilder] vérification de la table véhicules : ' .. tostring(err) .. '^0') end
    if GetGameTimer() > 180000 then return end        -- uniquement au démarrage du serveur (pas lors d'un restart de la ressource)
    local mode = Config.OnRestart
    if mode == 'garage' then
        MySQL.update(('UPDATE %s SET %s = 1 WHERE %s = 0'):format(T, col(V.stored), col(V.stored)))
    elseif mode == 'impound' then
        MySQL.update(('UPDATE %s SET %s = 2 WHERE %s = 0'):format(T, col(V.stored), col(V.stored)))
    end
end
