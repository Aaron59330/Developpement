-- ─────────────────────────────── Police scientifique : douilles + balistique ───────────────────────────────
-- Tout est décidé ici : le client signale seulement « je tire » ; le serveur lit l'arme réellement équipée (ox_inventory), sa position, son n° de série
-- et son propriétaire enregistré. La police reçoit uniquement la position des douilles ; le détail n'est jamais envoyé avant l'analyse au labo.
local ESX = exports['es_extended']:getSharedObject()
local C, A = Config.Casings, Config.Analysis

local Ground = {}        -- [id] = { id, x, y, z, shooter, at } : douilles au sol (police)
local LastShot = {}      -- [src] = GetGameTimer() du dernier enregistrement
local ignored = {}
for _, w in ipairs(C.Ignored) do ignored[w] = true end

local policeJobs = {}
for _, j in ipairs(Config.PoliceJobs) do policeJobs[j] = true end
local function isPolice(x) return x and x.job and policeJobs[x.job.name] == true end

CreateThread(function()
    Wait(800)
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS forensics_casings (
        id INT AUTO_INCREMENT PRIMARY KEY, x FLOAT NOT NULL, y FLOAT NOT NULL, z FLOAT NOT NULL,
        weapon VARCHAR(50) NOT NULL, caliber VARCHAR(30) NOT NULL, signature VARCHAR(16) NOT NULL, serial VARCHAR(60) NULL, owner VARCHAR(100) NULL,
        shooter VARCHAR(80) NOT NULL, shot_at INT NOT NULL, status VARCHAR(10) NOT NULL DEFAULT 'ground',
        collected_by VARCHAR(80) NULL, analysed_by VARCHAR(80) NULL, analysed_at INT NULL,
        INDEX idx_sig (signature), INDEX idx_serial (serial), INDEX idx_status (status)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    -- au redémarrage, les douilles restées au sol sont considérées comme perdues
    MySQL.update.await("UPDATE forensics_casings SET status = 'lost' WHERE status = 'ground'")
    MySQL.update.await('DELETE FROM forensics_casings WHERE shot_at < ?', { os.time() - A.KeepDays * 86400 })
end)

local function item(name)
    local ok, it = pcall(function() return exports.ox_inventory:Items(name) end)
    return ok and it or nil
end

-- Signature balistique : identifie « l'âme du canon » de l'arme (stable pour un même n° de série)
local function signature(serial, weapon, shooter)
    local h = joaat(serial and serial ~= '' and ('S:' .. serial) or ('W:' .. weapon .. ':' .. shooter))
    return ('BAL-%06X'):format(h & 0xFFFFFF)
end

-- ═══════════════ Synchronisation vers la police ═══════════════
local function publicList()
    local out = {}
    for id, e in pairs(Ground) do out[#out + 1] = { id = id, x = e.x, y = e.y, z = e.z } end
    return out
end

local function toPolice(event, ...)
    for _, src in ipairs(GetPlayers()) do
        local x = ESX.GetPlayerFromId(tonumber(src))
        if isPolice(x) then TriggerClientEvent(event, tonumber(src), ...) end
    end
end

RegisterNetEvent('pickax_forensics:requestSync', function()
    local src = source
    TriggerClientEvent('pickax_forensics:sync', src, isPolice(ESX.GetPlayerFromId(src)) and publicList() or {})
end)

local function removeGround(id, status, who)
    local e = Ground[id]
    if not e then return nil end
    Ground[id] = nil
    MySQL.update('UPDATE forensics_casings SET status = ?, collected_by = ? WHERE id = ?', { status, who, id })
    toPolice('pickax_forensics:remove', id)
    return e
end

-- ═══════════════ Un tir = une douille ═══════════════
RegisterNetEvent('pickax_forensics:shot', function()
    local src = source
    if not Config.Enabled then return end
    local now = GetGameTimer()
    if LastShot[src] and now - LastShot[src] < C.MinInterval then return end
    local x = ESX.GetPlayerFromId(src)
    if not x then return end
    local w = exports.ox_inventory:GetCurrentWeapon(src)
    if not w or not w.name or ignored[w.name] then return end
    local def = item(w.name)
    if not def or not def.weapon or def.throwable then return end
    LastShot[src] = now
    local md = w.metadata or {}
    local serial = (type(md.serial) == 'string' and md.serial ~= '') and md.serial or nil
    local owner = type(md.registered) == 'string' and md.registered or nil
    local ped = GetPlayerPed(src)
    local pc = GetEntityCoords(ped)
    local a = math.random() * 6.2832
    local r = math.random() * C.ScatterRadius
    local cx, cy, cz = pc.x + math.cos(a) * r, pc.y + math.sin(a) * r, pc.z - 0.95
    local ident = x.identifier
    -- plafonds : par tireur puis global (la plus ancienne disparaît)
    local own, oldest, total = 0, nil, 0
    for id, e in pairs(Ground) do
        total = total + 1
        if e.shooter == ident then
            own = own + 1
            if not oldest or e.at < Ground[oldest].at then oldest = id end
        end
    end
    if own >= C.MaxPerShooter and oldest then removeGround(oldest, 'lost') end
    if total >= C.MaxOnGround then
        local g
        for id, e in pairs(Ground) do if not g or e.at < Ground[g].at then g = id end end
        if g then removeGround(g, 'lost') end
    end
    local caliber = Config.Calibers[w.name] or 'calibre indéterminé'
    local sig = signature(serial, w.name, ident)
    local id = MySQL.insert.await('INSERT INTO forensics_casings (x, y, z, weapon, caliber, signature, serial, owner, shooter, shot_at) VALUES (?,?,?,?,?,?,?,?,?,?)',
        { cx, cy, cz, w.name, caliber, sig, serial, owner, ident, os.time() })
    if not id then return end
    Ground[id] = { id = id, x = cx, y = cy, z = cz, shooter = ident, at = os.time() }
    toPolice('pickax_forensics:add', { id = id, x = cx, y = cy, z = cz })
end)

AddEventHandler('playerDropped', function() LastShot[source] = nil end)

-- Expiration des douilles au sol
CreateThread(function()
    while true do
        Wait(60000)
        local limit = os.time() - C.LifetimeMinutes * 60
        for id, e in pairs(Ground) do if e.at < limit then removeGround(id, 'lost') end end
    end
end)

-- ═══════════════ Ramassage (police) ═══════════════
local function near(src, x, y, z, d)
    local p = GetEntityCoords(GetPlayerPed(src))
    return #(p - vector3(x, y, z)) <= d
end

ESX.RegisterServerCallback('pickax_forensics:collect', function(src, cb, id)
    local x = ESX.GetPlayerFromId(src)
    id = tonumber(id)
    local e = id and Ground[id]
    if not isPolice(x) or not e then return cb({ ok = false, error = 'Douille introuvable' }) end
    if not near(src, e.x, e.y, e.z, C.PickupDistance + 2.5) then return cb({ ok = false, error = 'Trop loin' }) end
    if C.BagItem ~= '' and (exports.ox_inventory:GetItemCount(src, C.BagItem) or 0) < 1 then return cb({ ok = false, error = 'Il te faut : ' .. C.BagItem }) end
    if not exports.ox_inventory:CanCarryItem(src, C.Item, 1) then return cb({ ok = false, error = 'Tu ne peux pas porter plus' }) end
    if not removeGround(id, 'collected', x.identifier) then return cb({ ok = false, error = 'Douille déjà ramassée' }) end
    if C.BagItem ~= '' then exports.ox_inventory:RemoveItem(src, C.BagItem, 1) end
    exports.ox_inventory:AddItem(src, C.Item, 1, { eid = id, label = ('Douille #%d (scellé)'):format(id), description = ('Ramassée le %s. À analyser au laboratoire.'):format(os.date('%d/%m/%Y %H:%M')) })
    cb({ ok = true, id = id })
end)

-- ═══════════════ Analyse au laboratoire ═══════════════
local function atLab(src)
    local p = GetEntityCoords(GetPlayerPed(src))
    for _, l in ipairs(Config.Labs) do if #(p - l.coords) <= A.InteractDistance + 3.0 then return true end end
    return false
end

local function fmtDate(t) return os.date('%d/%m/%Y %H:%M', t) end

local function report(row)
    local matches = MySQL.query.await("SELECT id, x, y, shot_at FROM forensics_casings WHERE signature = ? AND id <> ? AND status = 'analysed' ORDER BY id DESC LIMIT 8", { row.signature, row.id }) or {}
    local m = {}
    for _, r in ipairs(matches) do m[#m + 1] = { id = r.id, x = r.x, y = r.y, at = fmtDate(r.shot_at) } end
    return {
        id = row.id, weapon = row.weapon, caliber = row.caliber, signature = row.signature, serial = row.serial, owner = row.owner,
        shotAt = fmtDate(row.shot_at), matches = m,
    }
end

ESX.RegisterServerCallback('pickax_forensics:labInfo', function(src, cb)
    local x = ESX.GetPlayerFromId(src)
    if not isPolice(x) or not atLab(src) then return cb({ ok = false, error = 'Réservé à la police, au laboratoire' }) end
    local list = {}
    for _, s in pairs(exports.ox_inventory:GetInventoryItems(src) or {}) do
        if s.name == C.Item and s.metadata and s.metadata.eid then
            list[#list + 1] = { slot = s.slot, eid = s.metadata.eid, label = s.metadata.label or ('Douille #' .. s.metadata.eid), analysed = s.metadata.analysed == true, signature = s.metadata.signature }
        end
    end
    table.sort(list, function(a, b) return a.eid < b.eid end)
    cb({ ok = true, items = list, seconds = A.Seconds })
end)

ESX.RegisterServerCallback('pickax_forensics:analyse', function(src, cb, slot)
    local x = ESX.GetPlayerFromId(src)
    if not isPolice(x) or not atLab(src) then return cb({ ok = false, error = 'Réservé à la police, au laboratoire' }) end
    local s = exports.ox_inventory:GetSlot(src, tonumber(slot) or 0)
    if not s or s.name ~= C.Item or not s.metadata or not s.metadata.eid then return cb({ ok = false, error = 'Scellé introuvable' }) end
    local row = MySQL.single.await('SELECT * FROM forensics_casings WHERE id = ?', { s.metadata.eid })
    if not row then return cb({ ok = false, error = 'Scellé inexploitable' }) end
    local md = s.metadata
    if row.status ~= 'analysed' then
        MySQL.update.await("UPDATE forensics_casings SET status = 'analysed', analysed_by = ?, analysed_at = ? WHERE id = ?", { x.identifier, os.time(), row.id })
        row.status = 'analysed'
    end
    md.analysed, md.signature = true, row.signature
    md.description = ('Analysée : %s, %s, signature %s.'):format(row.caliber, row.owner and ('arme enregistrée au nom de ' .. row.owner) or 'arme non enregistrée', row.signature)
    exports.ox_inventory:SetMetadata(src, s.slot, md)
    cb({ ok = true, report = report(row) })
end)

-- ═══════════════ Fichier balistique : /balistique [n° de série | BAL-xxxxxx] ═══════════════
ESX.RegisterServerCallback('pickax_forensics:lookup', function(src, cb, q)
    local x = ESX.GetPlayerFromId(src)
    if not isPolice(x) then return cb({ ok = false, error = 'Réservé à la police' }) end
    q = tostring(q or ''):sub(1, 60)
    local rows
    if q == '' then
        rows = MySQL.query.await("SELECT * FROM forensics_casings WHERE status = 'analysed' ORDER BY analysed_at DESC LIMIT 10")
    else
        rows = MySQL.query.await("SELECT * FROM forensics_casings WHERE status = 'analysed' AND (signature = ? OR serial = ?) ORDER BY id DESC LIMIT 15", { q:upper(), q })
    end
    local out = {}
    for _, r in ipairs(rows or {}) do out[#out + 1] = { id = r.id, weapon = r.weapon, caliber = r.caliber, signature = r.signature, serial = r.serial, owner = r.owner, shotAt = fmtDate(r.shot_at), x = r.x, y = r.y } end
    cb({ ok = true, rows = out, q = q })
end)

-- Aide admin : position à copier dans Config.Labs
RegisterCommand('laboici', function(src)
    if src == 0 then return end
    local x = ESX.GetPlayerFromId(src)
    if not x or not Config.AdminGroups[x.getGroup()] then return end
    local p = GetEntityCoords(GetPlayerPed(src))
    TriggerClientEvent('chat:addMessage', src, { args = { '^2Labo', ('coords = vector3(%.2f, %.2f, %.2f)'):format(p.x, p.y, p.z - 0.95) } })
    print(('[pickax_forensics] coords = vector3(%.2f, %.2f, %.2f)'):format(p.x, p.y, p.z - 0.95))
end, false)
