-- ─────────────────────────────── Sang (ADN), empreintes, profils, GSR, nettoyage ───────────────────────────────
-- Même principe que les douilles : le client signale un événement, le SERVEUR valide et décide. Les codes ADN / empreinte d'une personne ne quittent jamais le serveur
-- avant une analyse, et ne désignent une identité que si la personne a été prélevée par la police (profil).
local ESX, FX = FX.ESX, FX
local isPolice = FX.isPolice
local B, P, G, CL, LB = Config.Blood, Config.Prints, Config.Gsr, Config.Cleaning, Config.Lab

local Blood = {}          -- [id] = { id, x, y, z, subject, at }
local Prints = {}         -- [id] = { id, plate, subject, at }
local ByPlate = {}        -- [plate] = { id, id, … }
local LastBleed, LastPrint = {}, {}

CreateThread(function()
    Wait(900)
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS forensics_traces (
        id INT AUTO_INCREMENT PRIMARY KEY, kind VARCHAR(8) NOT NULL, x FLOAT NOT NULL, y FLOAT NOT NULL, z FLOAT NOT NULL, plate VARCHAR(12) NULL,
        subject VARCHAR(80) NOT NULL, created INT NOT NULL, status VARCHAR(10) NOT NULL DEFAULT 'ground', collected_by VARCHAR(80) NULL,
        quality INT NULL, analysed_at INT NULL, INDEX idx_subject (subject), INDEX idx_status (status)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS forensics_profiles (
        identifier VARCHAR(80) PRIMARY KEY, name VARCHAR(100) NOT NULL, dna VARCHAR(16) NOT NULL, fp VARCHAR(16) NOT NULL,
        sampled_by VARCHAR(80) NULL, sampled_at INT NOT NULL, INDEX idx_dna (dna), INDEX idx_fp (fp)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.update.await("UPDATE forensics_traces SET status = 'lost' WHERE status = 'ground'")
    MySQL.update.await('DELETE FROM forensics_traces WHERE created < ?', { os.time() - Config.Analysis.KeepDays * 86400 })
end)

local function code(prefix, identifier)
    return ('%s-%08X'):format(prefix, joaat(prefix .. ':' .. identifier .. ':' .. Config.Salt) & 0xFFFFFFFF)
end
local function dnaOf(id) return code('ADN', id) end
local function fpOf(id) return code('EMP', id) end

local function trim(s) return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', '')) end
local function near(src, x, y, z, d) return #(GetEntityCoords(GetPlayerPed(src)) - vector3(x, y, z)) <= d end

-- ═══════════════ Synchronisation vers la police ═══════════════
function FX.publicTraces()
    local out = {}
    for id, e in pairs(Blood) do out[#out + 1] = { id = id, kind = 'blood', x = e.x, y = e.y, z = e.z } end
    for plate, ids in pairs(ByPlate) do if #ids > 0 then out[#out + 1] = { kind = 'plate', plate = plate, n = #ids } end end
    return out
end

local function dropBlood(id, status, who)
    if not Blood[id] then return end
    Blood[id] = nil
    MySQL.update('UPDATE forensics_traces SET status = ?, collected_by = ? WHERE id = ?', { status, who, id })
    FX.toPolice('pickax_forensics:remove', id, 'blood')
end

local function dropPrint(id, status, who)
    local e = Prints[id]
    if not e then return end
    Prints[id] = nil
    local l = ByPlate[e.plate] or {}
    for i, v in ipairs(l) do if v == id then table.remove(l, i) break end end
    if #l == 0 then ByPlate[e.plate] = nil end
    MySQL.update('UPDATE forensics_traces SET status = ?, collected_by = ? WHERE id = ?', { status, who, id })
    FX.toPolice('pickax_forensics:plate', e.plate, ByPlate[e.plate] and #ByPlate[e.plate] or 0)
end

-- ═══════════════ Sang : le blessé signale, le serveur contrôle ═══════════════
RegisterNetEvent('pickax_forensics:bleed', function()
    local src = source
    if not Config.Enabled or not B.Enabled then return end
    local x = ESX.GetPlayerFromId(src)
    if not x then return end
    local now = os.time()
    if LastBleed[src] and now - LastBleed[src] < B.MinInterval then return end
    local ped = GetPlayerPed(src)
    if GetEntityHealth(ped) >= GetEntityMaxHealth(ped) then return end   -- pas blessé : pas de sang
    LastBleed[src] = now
    local c = GetEntityCoords(ped)
    local own, oldest = 0, nil
    for id, e in pairs(Blood) do
        if e.subject == x.identifier then own = own + 1 if not oldest or e.at < Blood[oldest].at then oldest = id end end
    end
    if own >= B.MaxPerPlayer and oldest then dropBlood(oldest, 'lost') end
    local id = MySQL.insert.await("INSERT INTO forensics_traces (kind, x, y, z, subject, created) VALUES ('blood', ?, ?, ?, ?, ?)", { c.x, c.y, c.z - 0.95, x.identifier, now })
    if not id then return end
    Blood[id] = { id = id, x = c.x, y = c.y, z = c.z - 0.95, subject = x.identifier, at = now }
    FX.toPolice('pickax_forensics:add', { id = id, kind = 'blood', x = c.x, y = c.y, z = c.z - 0.95 })
end)

-- ═══════════════ Empreintes : monter dans un véhicule sans gants ═══════════════
RegisterNetEvent('pickax_forensics:vehicle', function(netId)
    local src = source
    if not Config.Enabled or not P.Enabled then return end
    local x = ESX.GetPlayerFromId(src)
    local veh = x and NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if not veh or veh == 0 or not DoesEntityExist(veh) or GetEntityType(veh) ~= 2 then return end
    local vc = GetEntityCoords(veh)
    if not near(src, vc.x, vc.y, vc.z, 12.0) then return end
    local plate = trim(GetVehicleNumberPlateText(veh)):sub(1, 12)
    if plate == '' then return end
    if P.GloveItem ~= '' and (exports.ox_inventory:GetItemCount(src, P.GloveItem) or 0) > 0 then return end
    local key, now = x.identifier .. ':' .. plate, os.time()
    if LastPrint[key] and now - LastPrint[key] < P.PerVehicleInterval then return end
    LastPrint[key] = now
    local l = ByPlate[plate] or {}
    for _, pid in ipairs(l) do if Prints[pid] and Prints[pid].subject == x.identifier then return end end   -- déjà une empreinte de cette personne
    if #l >= P.MaxPerVehicle then dropPrint(l[1], 'lost') l = ByPlate[plate] or {} end
    local id = MySQL.insert.await("INSERT INTO forensics_traces (kind, x, y, z, plate, subject, created) VALUES ('print', ?, ?, ?, ?, ?, ?)", { vc.x, vc.y, vc.z, plate, x.identifier, now })
    if not id then return end
    Prints[id] = { id = id, plate = plate, subject = x.identifier, at = now }
    l[#l + 1] = id
    ByPlate[plate] = l
    FX.toPolice('pickax_forensics:plate', plate, #l)
end)

-- ═══════════════ Expiration ═══════════════
CreateThread(function()
    while true do
        Wait(60000)
        local now = os.time()
        for id, e in pairs(Blood) do if now - e.at > B.LifetimeMinutes * 60 then dropBlood(id, 'lost') end end
        for id, e in pairs(Prints) do if now - e.at > P.LifetimeMinutes * 60 then dropPrint(id, 'lost') end end
    end
end)

-- ═══════════════ Relevé sur la scène (police) : deux temps pour imposer la durée ═══════════════
local PendingCollect = {}   -- [src] = { kind, id, at, min }

ESX.RegisterServerCallback('pickax_forensics:traceBegin', function(src, cb, kind, ref, netId)
    local x = ESX.GetPlayerFromId(src)
    if not isPolice(x) then return cb({ ok = false, error = 'Réservé à la police' }) end
    local item = kind == 'blood' and B.Item or P.Item
    if not exports.ox_inventory:CanCarryItem(src, item, 1) then return cb({ ok = false, error = 'Tu ne peux pas porter plus' }) end
    if kind == 'blood' then
        local e = Blood[tonumber(ref) or 0]
        if not e then return cb({ ok = false, error = 'Trace introuvable' }) end
        if not near(src, e.x, e.y, e.z, 4.5) then return cb({ ok = false, error = 'Trop loin' }) end
        PendingCollect[src] = { kind = 'blood', id = e.id, at = GetGameTimer(), min = (B.PickupSeconds - 1) * 1000 }
        return cb({ ok = true, seconds = B.PickupSeconds })
    elseif kind == 'print' then
        local plate = trim(ref):sub(1, 12)
        local list = ByPlate[plate]
        local veh = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
        if not list or #list == 0 or not veh or veh == 0 or not DoesEntityExist(veh) then return cb({ ok = false, error = 'Aucune empreinte exploitable' }) end
        if trim(GetVehicleNumberPlateText(veh)) ~= plate then return cb({ ok = false, error = 'Véhicule différent' }) end
        local vc = GetEntityCoords(veh)
        if not near(src, vc.x, vc.y, vc.z, P.DustDistance + 3.0) then return cb({ ok = false, error = 'Trop loin du véhicule' }) end
        local id = list[math.random(#list)]
        PendingCollect[src] = { kind = 'print', id = id, at = GetGameTimer(), min = 5000 }
        return cb({ ok = true, seconds = 25, seed = math.random(1, 2147483000) })
    end
    cb({ ok = false, error = 'Type inconnu' })
end)

ESX.RegisterServerCallback('pickax_forensics:traceEnd', function(src, cb, score)
    local x = ESX.GetPlayerFromId(src)
    local p = PendingCollect[src]
    PendingCollect[src] = nil
    if not isPolice(x) or not p then return cb({ ok = false, error = 'Aucun relevé en cours' }) end
    if GetGameTimer() - p.at < p.min then return cb({ ok = false, error = 'Relevé trop rapide' }) end
    score = math.max(0, math.min(100, math.floor(tonumber(score) or 0)))
    if p.kind == 'blood' then
        if not Blood[p.id] then return cb({ ok = false, error = 'Trace déjà prélevée' }) end
        dropBlood(p.id, 'collected', x.identifier)
        exports.ox_inventory:AddItem(src, B.Item, 1, { eid = p.id, kind = 'blood', label = ('Prélèvement de sang #%d (scellé)'):format(p.id), description = ('Prélevé le %s. À analyser au laboratoire.'):format(FX.fmtDate(os.time())) })
        return cb({ ok = true, msg = ('Prélèvement de sang #%d placé sous scellé.'):format(p.id) })
    end
    local e = Prints[p.id]
    if not e then return cb({ ok = false, error = 'Empreinte déjà relevée' }) end
    if score < P.MinQuality then
        dropPrint(p.id, 'lost', x.identifier)
        return cb({ ok = true, msg = 'Empreinte écrasée par le poudrage : inexploitable.', failed = true })
    end
    dropPrint(p.id, 'collected', x.identifier)
    MySQL.update('UPDATE forensics_traces SET quality = ? WHERE id = ?', { score, p.id })
    exports.ox_inventory:AddItem(src, P.Item, 1, { eid = p.id, kind = 'print', quality = score, label = ('Empreinte #%d (scellé)'):format(p.id), description = ('Relevée le %s — qualité %d %%.'):format(FX.fmtDate(os.time()), score) })
    cb({ ok = true, msg = ('Empreinte #%d relevée (qualité %d %%).'):format(p.id, score) })
end)

-- ═══════════════ Analyse d'un prélèvement (appelé par le labo) ═══════════════
local function profileBy(col, c)
    return MySQL.single.await(('SELECT name, sampled_at FROM forensics_profiles WHERE %s = ?'):format(col), { c })
end

function FX.analyseTrace(src, x, slot, kind, eid, score)
    local row = MySQL.single.await('SELECT * FROM forensics_traces WHERE id = ? AND kind = ?', { eid, kind })
    if not row then return { ok = false, error = 'Prélèvement inexploitable' } end
    local md = slot.metadata
    local good = score >= 60
    if not good then
        md.tries = (md.tries or 0) + 1
        if md.tries > LB.MaxRetries then
            md.analysed, md.description = true, 'Échantillon dégradé : inexploitable.'
            exports.ox_inventory:SetMetadata(src, slot.slot, md)
            return { ok = true, report = { kind = kind, id = eid, degraded = true } }
        end
        exports.ox_inventory:SetMetadata(src, slot.slot, md)
        return { ok = true, report = { kind = kind, id = eid, inconclusive = true, left = LB.MaxRetries - md.tries + 1 } }
    end
    local c = kind == 'blood' and dnaOf(row.subject) or fpOf(row.subject)
    local prof = profileBy(kind == 'blood' and 'dna' or 'fp', c)
    local others = MySQL.query.await("SELECT id, x, y, created FROM forensics_traces WHERE subject = ? AND kind = ? AND status = 'analysed' AND id <> ? ORDER BY id DESC LIMIT 8", { row.subject, kind, eid }) or {}
    if row.status ~= 'analysed' then MySQL.update.await("UPDATE forensics_traces SET status = 'analysed', analysed_at = ? WHERE id = ?", { os.time(), eid }) end
    local m = {}
    for _, o in ipairs(others) do m[#m + 1] = { id = o.id, x = o.x, y = o.y, at = FX.fmtDate(o.created) } end
    md.analysed, md.signature = true, c
    md.description = ('Analysé : profil %s — %s.'):format(c, prof and ('identifié : ' .. prof.name) or 'individu inconnu')
    exports.ox_inventory:SetMetadata(src, slot.slot, md)
    return { ok = true, report = { kind = kind, id = eid, code = c, identified = prof and prof.name or nil, profiled = prof and FX.fmtDate(prof.sampled_at) or nil,
        quality = row.quality, plate = row.plate, at = FX.fmtDate(row.created), matches = m } }
end

-- ═══════════════ Prélèvement d'un suspect ═══════════════
local function nearestTarget(src, targetId, dist)
    local t = tonumber(targetId)
    local xt = t and ESX.GetPlayerFromId(t)
    if not xt then return nil, 'Joueur introuvable' end
    local c = GetEntityCoords(GetPlayerPed(t))
    if not near(src, c.x, c.y, c.z, dist + 2.0) then return nil, 'Trop loin du suspect' end
    return xt, nil, t
end

ESX.RegisterServerCallback('pickax_forensics:sample', function(src, cb, targetId)
    local x = ESX.GetPlayerFromId(src)
    if not isPolice(x) then return cb({ ok = false, error = 'Réservé à la police' }) end
    local xt, err, t = nearestTarget(src, targetId, Config.Profile.Distance)
    if not xt then return cb({ ok = false, error = err }) end
    if t == src then return cb({ ok = false, error = 'Impossible sur toi-même' }) end
    local name = xt.getName and xt.getName() or GetPlayerName(t)
    MySQL.query.await('INSERT INTO forensics_profiles (identifier, name, dna, fp, sampled_by, sampled_at) VALUES (?,?,?,?,?,?) ON DUPLICATE KEY UPDATE name = VALUES(name), sampled_by = VALUES(sampled_by), sampled_at = VALUES(sampled_at)',
        { xt.identifier, name, dnaOf(xt.identifier), fpOf(xt.identifier), x.identifier, os.time() })
    TriggerClientEvent('esx:showNotification', t, 'Un prélèvement ADN et d\'empreintes a été effectué sur toi.')
    cb({ ok = true, msg = ('Profil de %s enregistré (ADN + empreintes).'):format(name) })
end)

-- ═══════════════ Résidus de tir (GSR) ═══════════════
ESX.RegisterServerCallback('pickax_forensics:gsr', function(src, cb, targetId)
    local x = ESX.GetPlayerFromId(src)
    if not isPolice(x) or not G.Enabled then return cb({ ok = false, error = 'Réservé à la police' }) end
    local xt, err = nearestTarget(src, targetId, G.Distance)
    if not xt then return cb({ ok = false, error = err }) end
    local last = FX.lastShot[xt.identifier]
    local wiped = FX.wiped[xt.identifier] or 0
    local name = xt.getName and xt.getName() or ('#' .. tostring(targetId))
    if last and last > wiped and os.time() - last < G.Minutes * 60 then
        return cb({ ok = true, positive = true, msg = ('Test GSR POSITIF sur %s : tir détecté il y a environ %d min.'):format(name, math.max(1, (os.time() - last) // 60)) })
    end
    cb({ ok = true, positive = false, msg = ('Test GSR négatif sur %s.'):format(name) })
end)

RegisterNetEvent('pickax_forensics:wipe', function()
    local src = source
    local x = ESX.GetPlayerFromId(src)
    if not x or not G.Enabled or G.WipeItem == '' then return end
    if not exports.ox_inventory:RemoveItem(src, G.WipeItem, 1) then return end
    FX.wiped[x.identifier] = os.time()
    TriggerClientEvent('esx:showNotification', src, 'Tes mains sont nettoyées.')
end)

-- ═══════════════ Nettoyage de scène (criminels) ═══════════════
local LastClean = {}
ESX.RegisterServerCallback('pickax_forensics:clean', function(src, cb, netId)
    local x = ESX.GetPlayerFromId(src)
    if not x or not CL.Enabled then return cb({ ok = false }) end
    local now = GetGameTimer()
    if LastClean[src] and now - LastClean[src] < 8000 then return cb({ ok = false, error = 'Doucement…' }) end
    if (exports.ox_inventory:GetItemCount(src, CL.Item) or 0) < 1 then return cb({ ok = false, error = 'Il te faut : ' .. CL.Item }) end
    LastClean[src] = now
    local c = GetEntityCoords(GetPlayerPed(src))
    local n = FX.removeCasingsNear and FX.removeCasingsNear(c, CL.Radius) or 0
    for id, e in pairs(Blood) do if #(vector3(e.x, e.y, e.z) - c) <= CL.Radius then dropBlood(id, 'lost') n = n + 1 end end
    local veh = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if veh and veh ~= 0 and DoesEntityExist(veh) and GetEntityType(veh) == 2 and #(GetEntityCoords(veh) - c) <= 8.0 then
        local plate = trim(GetVehicleNumberPlateText(veh))
        for _, id in ipairs({ table.unpack(ByPlate[plate] or {}) }) do dropPrint(id, 'lost') n = n + 1 end
    end
    exports.ox_inventory:RemoveItem(src, CL.Item, 1)
    cb({ ok = true, count = n, msg = n > 0 and ('Scène nettoyée : %d trace(s) effacée(s).'):format(n) or 'Rien à nettoyer ici.' })
end)

AddEventHandler('playerDropped', function() local s = source LastBleed[s], LastClean[s], PendingCollect[s] = nil, nil, nil end)
