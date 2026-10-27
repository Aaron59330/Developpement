-- ─────────────────────────────── Laboratoires ───────────────────────────────
-- Un laboratoire est une propriété de catégorie « lab » (créée / vendue / louée par un agent immobilier). Son propriétaire y entre puis place
-- ses équipements : serres (plantation → récolte), tables de traitement (produit brut → pochon) et zones de tenue obligatoire.
-- Occupants (propriétaire + clés) : ils utilisent l'équipement ; seul le propriétaire l'installe.
local L = Config.Real.Lab
local T = L.Toxic
local Cache = {}        -- [propId] = liste { id, kind, drug, x, y, z, h, radius, outfit, planted }
local Pending = {}      -- [src] = action chronométrée { id, sub, ready, batches }
local Level, Last, Warned = {}, {}, {}   -- intoxication

local function fail(msg) return { ok = false, error = msg } end

CreateThread(function()
    Wait(900)
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS jobbuilder_lab (
        id INT AUTO_INCREMENT PRIMARY KEY, property_id INT NOT NULL, kind VARCHAR(12) NOT NULL, drug VARCHAR(12) NULL,
        x FLOAT NOT NULL, y FLOAT NOT NULL, z FLOAT NOT NULL, h FLOAT NOT NULL DEFAULT 0, radius FLOAT NULL, outfit TEXT NULL, planted BIGINT NULL, placed_by VARCHAR(80) NULL,
        INDEX idx_prop (property_id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS jobbuilder_lab_toxic (identifier VARCHAR(80) NOT NULL PRIMARY KEY, level INT NOT NULL DEFAULT 0) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
end)

local function load(pid)
    if not Cache[pid] then
        local list = {}
        for _, r in ipairs(MySQL.query.await('SELECT * FROM jobbuilder_lab WHERE property_id = ? ORDER BY id', { pid }) or {}) do
            list[#list + 1] = { id = r.id, kind = r.kind, drug = r.drug, x = r.x, y = r.y, z = r.z, h = r.h, radius = r.radius, outfit = r.outfit and json.decode(r.outfit) or nil, planted = r.planted }
        end
        Cache[pid] = list
    end
    return Cache[pid]
end

local function find(pid, id)
    for i, q in ipairs(load(pid)) do if q.id == tonumber(id) then return q, i end end
end

-- État d'une serre : empty | growing | ready (calculé avec l'heure serveur)
local function plantState(q)
    if q.kind ~= 'greenhouse' then return nil end
    local d = L.Drugs[q.drug]
    if not q.planted or not d then return 'empty', 0, 0 end
    local total = d.grow * 60
    local pct = math.min(1.0, (os.time() - q.planted) / total)
    return pct >= 1.0 and 'ready' or 'growing', pct, math.max(0, math.ceil(total * (1 - pct)))
end

local function pub(list)
    local out = {}
    for _, q in ipairs(list) do
        local st, pct, left = plantState(q)
        local d = L.Drugs[q.drug]
        out[#out + 1] = { id = q.id, kind = q.kind, drug = q.drug, drugLabel = d and d.label or nil, x = q.x, y = q.y, z = q.z, h = q.h, radius = q.radius, outfit = q.outfit,
            state = st, pct = pct and math.floor(pct * 100) or nil, left = left }
    end
    return out
end

function JB.labList(pid)
    local p = JB.Props[pid]
    if not L.Enabled or not p or p.category ~= L.Category then return nil end
    return pub(load(pid))
end

function JB.labClear(pid)
    Cache[pid] = nil
    MySQL.update.await('DELETE FROM jobbuilder_lab WHERE property_id = ?', { pid })
end

local function push(pid)
    local list = JB.labList(pid)
    for src, p in pairs(JB.Inside) do
        if p == pid then TriggerClientEvent('jobbuilder:client:lab', src, list or {}) end
    end
end

-- Mise à jour périodique de l'état des serres pour les occupants
CreateThread(function()
    while true do
        Wait(15000)
        local seen = {}
        for _, pid in pairs(JB.Inside) do if not seen[pid] then seen[pid] = true push(pid) end end
    end
end)

-- Contexte : le joueur est dans un laboratoire (propriétaire ou clé) ; owner = true exige d'être le propriétaire
local function ctx(src, needOwner)
    if not L.Enabled then return nil, nil, 'Les laboratoires sont désactivés' end
    local x = ESX.GetPlayerFromId(src)
    local p = x and JB.Props[JB.Inside[src] or 0]
    if not p then return nil, nil, 'Tu dois être dans ton laboratoire' end
    if p.category ~= L.Category then return nil, nil, 'Cette propriété n\'est pas un laboratoire' end
    local owner = p.owner == x.identifier
    local key = false
    for _, k in ipairs(p.key_holders or {}) do if k.identifier == x.identifier then key = true end end
    if not owner and not key then return nil, nil, 'Réservé au propriétaire et aux clés' end
    if needOwner and not owner then return nil, nil, 'Seul le propriétaire installe l\'équipement' end
    return x, p
end

local function counts(list)
    local c = { greenhouse = 0, table = 0, outfit = 0 }
    for _, q in ipairs(list) do c[q.kind] = (c[q.kind] or 0) + 1 end
    return c
end

-- ─────────────────────────────── Installation (propriétaire) ───────────────────────────────
ESX.RegisterServerCallback('jobbuilder:lab:list', function(src, cb)
    local x, p, err = ctx(src, true)
    if not x then return cb(fail(err)) end
    local list = load(p.id)
    local drugs = {}
    for _, k in ipairs(L.DrugOrder) do
        local d = L.Drugs[k]
        if d then drugs[#drugs + 1] = { id = k, label = d.label, greenhouse = d.seed ~= nil } end
    end
    cb({ ok = true, label = p.label, max = L.Max, counts = counts(list), drugs = drugs, equipment = pub(list), radius = L.OutfitRadius })
end)

local function validPos(src, c)
    if type(c) ~= 'table' or not tonumber(c.x) or not tonumber(c.y) or not tonumber(c.z) then return nil end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local pc = GetEntityCoords(ped)
    local x, y, z = tonumber(c.x) + 0.0, tonumber(c.y) + 0.0, tonumber(c.z) + 0.0
    if #(vector3(pc.x, pc.y, pc.z) - vector3(x, y, z)) > (Config.Real.Furniture.PlaceDistance or 8.0) + 6.0 then return nil end
    return x, y, z, (tonumber(c.h) or 0.0) + 0.0
end

local function cleanOutfit(o)
    if type(o) ~= 'table' then return nil end
    local out = {}
    for _, sex in ipairs({ 'male', 'female' }) do
        if type(o[sex]) == 'table' then
            out[sex] = {}
            for _, r in ipairs(o[sex]) do
                if type(r) == 'table' and (r.k == 'c' or r.k == 'p') and tonumber(r.id) and tonumber(r.d) and #out[sex] < 14 then
                    out[sex][#out[sex] + 1] = { k = r.k, id = math.floor(tonumber(r.id)), d = math.floor(tonumber(r.d)) }
                end
            end
        end
    end
    return next(out) and out or nil
end

ESX.RegisterServerCallback('jobbuilder:lab:place', function(src, cb, kind, drug, c, radius, outfit)
    local x, p, err = ctx(src, true)
    if not x then return cb(fail(err)) end
    if kind ~= 'greenhouse' and kind ~= 'table' and kind ~= 'outfit' then return cb(fail('Équipement inconnu')) end
    local d = L.Drugs[tostring(drug)]
    if kind ~= 'outfit' then
        if not d then return cb(fail('Choisis une substance')) end
        if kind == 'greenhouse' and not d.seed then return cb(fail('Pas de serre pour cette substance')) end
    end
    local px, py, pz, ph = validPos(src, c)
    if not px then return cb(fail('Position invalide ou trop loin')) end
    local list = load(p.id)
    if counts(list)[kind] >= (L.Max[kind] or 0) then return cb(fail(('Maximum atteint pour ce laboratoire (%d)'):format(L.Max[kind] or 0))) end
    local r = nil
    local o = nil
    if kind == 'outfit' then
        local R = L.OutfitRadius
        r = math.max(R.min, math.min(R.max, tonumber(radius) or R.default))
        o = cleanOutfit(outfit)
    end
    local id = MySQL.insert.await('INSERT INTO jobbuilder_lab (property_id, kind, drug, x, y, z, h, radius, outfit, placed_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { p.id, kind, kind ~= 'outfit' and tostring(drug) or nil, px, py, pz, ph, r, o and json.encode(o) or nil, x.identifier })
    list[#list + 1] = { id = id, kind = kind, drug = kind ~= 'outfit' and tostring(drug) or nil, x = px, y = py, z = pz, h = ph, radius = r, outfit = o }
    push(p.id)
    cb({ ok = true })
end)

ESX.RegisterServerCallback('jobbuilder:lab:remove', function(src, cb, id)
    local x, p, err = ctx(src, true)
    if not x then return cb(fail(err)) end
    local q, i = find(p.id, id)
    if not q then return cb(fail('Équipement introuvable')) end
    table.remove(load(p.id), i)
    MySQL.update('DELETE FROM jobbuilder_lab WHERE id = ?', { q.id })
    push(p.id)
    cb({ ok = true })
end)

-- Met à jour la tenue exigée d'une zone (le propriétaire porte la tenue voulue et appuie sur « Capturer ma tenue »)
ESX.RegisterServerCallback('jobbuilder:lab:setOutfit', function(src, cb, id, outfit)
    local x, p, err = ctx(src, true)
    if not x then return cb(fail(err)) end
    local q = find(p.id, id)
    if not q or q.kind ~= 'outfit' then return cb(fail('Zone introuvable')) end
    local o = cleanOutfit(outfit)
    if not o then return cb(fail('Tenue invalide')) end
    q.outfit = o
    MySQL.update('UPDATE jobbuilder_lab SET outfit = ? WHERE id = ?', { json.encode(o), q.id })
    push(p.id)
    cb({ ok = true })
end)

-- ─────────────────────────────── Utilisation (propriétaire + clés) ───────────────────────────────
local function itemCount(src, name)
    local ok, n = pcall(function() return exports.ox_inventory:Search(src, 'count', name) end)
    return ok and tonumber(n) or 0
end

local function near(src, q, dist)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local c = GetEntityCoords(ped)
    return #(vector3(c.x, c.y, c.z) - vector3(q.x, q.y, q.z)) <= (dist or 4.0)
end

-- Début d'une action chronométrée : retourne la durée (le serveur vérifie qu'elle a été respectée à la fin)
ESX.RegisterServerCallback('jobbuilder:lab:begin', function(src, cb, id)
    if Pending[src] then return cb(fail('Action déjà en cours')) end
    local x, p, err = ctx(src, false)
    if not x then return cb(fail(err)) end
    local q = find(p.id, id)
    if not q or not near(src, q) then return cb(fail('Trop loin')) end
    local d = L.Drugs[q.drug]
    if not d then return cb(fail('Équipement invalide')) end
    local sub, secs, label
    if q.kind == 'greenhouse' then
        local st = plantState(q)
        if st == 'empty' then
            if itemCount(src, d.seed) < 1 then return cb(fail(('Il te faut : %s'):format(d.seed))) end
            sub, secs, label = 'plant', d.plantSeconds, 'Plantation'
        elseif st == 'ready' then sub, secs, label = 'harvest', math.max(3, d.plantSeconds), 'Récolte'
        else return cb(fail('La plante n\'est pas prête.')) end
    elseif q.kind == 'table' then
        local have = itemCount(src, d.raw)
        local batches = math.min(L.BatchMax, math.floor(have / d.recipe.count))
        if batches < 1 then return cb(fail(('Il te faut %d × %s'):format(d.recipe.count, d.raw))) end
        -- Laboratoire interactif : une suite d'étapes jouées à la souris remplace la barre de progression
        local X, tpl = L.Experience, L.Experience and L.Experience.Templates and L.Experience.Templates[q.drug]
        if X and X.Enabled and tpl and tpl.steps and #tpl.steps > 0 then
            local iname = L.Experience.ItemLabels and L.Experience.ItemLabels[d.raw]
            local ok, items = pcall(function() return exports.ox_inventory:Items() end)
            local label = iname or (ok and items and items[d.raw] and items[d.raw].label) or d.raw
            Pending[src] = { id = q.id, pid = p.id, sub = 'process', exp = true, batches = batches, nsteps = #tpl.steps,
                ready = GetGameTimer() + LabExp.minMs(tpl.steps, X), expires = GetGameTimer() + 25 * 60000 }
            return cb({ ok = true, experience = true, session = { lab = 'Laboratoire', title = tpl.title or d.label, batches = batches, steps = LabExp.publicSteps(tpl.steps),
                inventory = { { label = label, sub = ('Lots : ×%d'):format(batches), count = have, icon = d.raw } }, cam = X.Cam } })
        end
        sub, secs, label = 'process', d.recipe.time * batches, ('%s ×%d'):format(d.recipe.label, batches)
        Pending[src] = { id = q.id, pid = p.id, sub = sub, ready = GetGameTimer() + math.floor(secs * 1000 * L.Grace), expires = GetGameTimer() + secs * 1000 + 60000, batches = batches }
        return cb({ ok = true, seconds = secs, label = label, sub = sub })
    else return cb(fail('Rien à faire ici')) end
    Pending[src] = { id = q.id, pid = p.id, sub = sub, ready = GetGameTimer() + math.floor(secs * 1000 * L.Grace), expires = GetGameTimer() + secs * 1000 + 60000 }
    cb({ ok = true, seconds = secs, label = label, sub = sub })
end)

RegisterNetEvent('jobbuilder:lab:cancel', function() Pending[source] = nil end)

ESX.RegisterServerCallback('jobbuilder:lab:finish', function(src, cb)
    local a = Pending[src]
    Pending[src] = nil
    if not a or GetGameTimer() < a.ready or GetGameTimer() > a.expires then return cb(fail('Action invalide')) end
    local x, p, err = ctx(src, false)
    if not x or p.id ~= a.pid then return cb(fail(err or 'Erreur')) end
    local q = find(p.id, a.id)
    if not q or not near(src, q, 6.0) then return cb(fail('Trop loin')) end
    local d = L.Drugs[q.drug]
    if a.sub == 'plant' then
        if plantState(q) ~= 'empty' or not d.seed then return cb(fail('Impossible de planter ici')) end
        if not exports.ox_inventory:RemoveItem(src, d.seed, 1) then return cb(fail('Il te faut : ' .. d.seed)) end
        q.planted = os.time()
        MySQL.update('UPDATE jobbuilder_lab SET planted = ? WHERE id = ?', { q.planted, q.id })
        push(p.id)
        return cb({ ok = true, message = ('Graines plantées : prête dans %d min.'):format(d.grow) })
    elseif a.sub == 'harvest' then
        if plantState(q) ~= 'ready' then return cb(fail('La plante n\'est pas prête.')) end
        local n = math.random(d.yield[1], d.yield[2])
        if not exports.ox_inventory:CanCarryItem(src, d.raw, n) then return cb(fail('Tu ne peux pas porter plus.')) end
        exports.ox_inventory:AddItem(src, d.raw, n)
        q.planted = nil
        MySQL.update('UPDATE jobbuilder_lab SET planted = NULL WHERE id = ?', { q.id })
        push(p.id)
        return cb({ ok = true, message = ('Tu as récolté %d × %s'):format(n, d.raw) })
    elseif a.sub == 'process' then
        local need = d.recipe.count * a.batches
        if itemCount(src, d.raw) < need then return cb(fail('Ingrédients manquants')) end
        exports.ox_inventory:RemoveItem(src, d.raw, need)
        local made, failed = 0, 0
        for _ = 1, a.batches do
            if math.random(100) <= (d.recipe.fail or 0) then failed = failed + 1 else made = made + 1 end
        end
        if made > 0 then exports.ox_inventory:AddItem(src, d.pooch, made) end
        return cb({ ok = true, message = ('Fabrication terminée : %d lot(s)%s.'):format(made, failed > 0 and (', ' .. failed .. ' raté(s)') or '') })
    end
    cb(fail('Action inconnue'))
end)

-- Fin d'un laboratoire interactif : le client envoie le résultat de chaque étape ; le serveur contrôle la durée, calcule la qualité, retire les ingrédients et remet les pochons
ESX.RegisterServerCallback('jobbuilder:lab:finishExp', function(src, cb, results)
    local a = Pending[src]
    Pending[src] = nil
    if not a or not a.exp or GetGameTimer() < a.ready or GetGameTimer() > a.expires then return cb(fail('Action invalide')) end
    local x, p, err = ctx(src, false)
    if not x or p.id ~= a.pid then return cb(fail(err or 'Erreur')) end
    local q = find(p.id, a.id)
    if not q or not near(src, q, 8.0) then return cb(fail('Trop loin')) end
    local d = L.Drugs[q.drug]
    local ok, quality = LabExp.validate(results, a.nsteps)
    if not ok then return cb(fail(quality)) end
    local need = d.recipe.count * a.batches
    if itemCount(src, d.raw) < need then return cb(fail('Ingrédients manquants')) end
    local made, failed, bonus = LabExp.outcome(quality, a.batches, d.recipe.fail, L.Experience)
    local give = made + bonus
    if give > 0 and not exports.ox_inventory:CanCarryItem(src, d.pooch, give) then return cb(fail('Tu ne peux pas porter plus.')) end
    exports.ox_inventory:RemoveItem(src, d.raw, need)
    local pct = math.floor(quality * 100 + 0.5)
    if give > 0 then exports.ox_inventory:AddItem(src, d.pooch, give, { purity = pct, description = ('Pureté : %d %%'):format(pct) }) end   -- la pureté suit le pochon (visible dans l'inventaire)
    cb({ ok = true, quality = pct, message = ('Fabrication terminée (qualité %d %%) : %d pochon(s)%s%s.'):format(pct, give, bonus > 0 and (' dont ' .. bonus .. ' bonus') or '', failed > 0 and (', ' .. failed .. ' lot(s) raté(s)') or '') })
end)

-- ─────────────────────────────── Intoxication (zone de tenue sans la tenue) ───────────────────────────────
local function setLevel(src, v)
    v = math.max(0, math.min(T.KillAt, v))
    Level[src] = v
    if Player(src) then Player(src).state:set('labToxic', math.floor(v), true) end
    TriggerClientEvent('jobbuilder:client:toxic', src, math.floor(v))
end

local function saveTox(src)
    local x = ESX.GetPlayerFromId(src)
    if not x then return end
    local v = math.floor(Level[src] or 0)
    if v > 0 then MySQL.update('INSERT INTO jobbuilder_lab_toxic (identifier, level) VALUES (?, ?) ON DUPLICATE KEY UPDATE level = VALUES(level)', { x.identifier, v })
    else MySQL.update('DELETE FROM jobbuilder_lab_toxic WHERE identifier = ?', { x.identifier }) end
end

-- Dans une zone de tenue du laboratoire où se trouve le joueur ?
local function inZone(src)
    local pid = JB.Inside[src]
    local ped = GetPlayerPed(src)
    if not pid or not ped or ped == 0 then return false end
    local c = GetEntityCoords(ped)
    for _, q in ipairs(load(pid)) do
        if q.kind == 'outfit' and #(vector3(c.x, c.y, c.z) - vector3(q.x, q.y, q.z)) <= (q.radius or 10.0) + 4.0 then return true end
    end
    return false
end

AddEventHandler('esx:playerLoaded', function(src, xPlayer)
    xPlayer = xPlayer or ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local row = MySQL.single.await('SELECT level FROM jobbuilder_lab_toxic WHERE identifier = ?', { xPlayer.identifier })
    setLevel(src, row and tonumber(row.level) or 0)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if Level[src] ~= nil then saveTox(src) end
    Level[src], Last[src], Warned[src], Pending[src] = nil, nil, nil, nil
end)

RegisterNetEvent('jobbuilder:server:labExposure', function()
    local src = source
    if not T.Enabled or not ESX.GetPlayerFromId(src) then return end
    local now = GetGameTimer()
    if Last[src] and now - Last[src] < (T.Tick * 1000) - 800 then return end
    if not inZone(src) then return end
    Last[src] = now
    setLevel(src, (Level[src] or 0) + T.ExposureGain)
end)

CreateThread(function()
    while true do
        Wait(T.Tick * 1000)
        if T.Enabled then
            for src, lvl in pairs(Level) do
                if lvl > 0 and ESX.GetPlayerFromId(src) then
                    local ped = GetPlayerPed(src)
                    local dead = ped and ped ~= 0 and GetEntityHealth(ped) <= 0
                    if dead then setLevel(src, 0) saveTox(src) Warned[src] = nil
                    else
                        local new = lvl + (Last[src] and GetGameTimer() - Last[src] < T.Tick * 1000 + 500 and 0 or T.SickGain)
                        setLevel(src, new)
                        new = Level[src]
                        if new >= T.DamageFrom and ped and ped ~= 0 then SetEntityHealth(ped, math.max(0, GetEntityHealth(ped) - T.DamageHealth)) end
                        for _, w in ipairs(T.WarnAt) do
                            if new >= w and (Warned[src] or 0) < w then
                                Warned[src] = w
                                JBNotifyClient(src, w >= 80 and ('Tu es mourant ! Il te faut un ' .. T.CureItem .. ' tout de suite.') or w >= 50 and 'Tu vomis, ton état empire.' or 'Tu te sens mal : tu es intoxiqué.')
                            end
                        end
                        if new >= T.KillAt then
                            if ped and ped ~= 0 then SetEntityHealth(ped, 0) end
                            JBNotifyClient(src, '~r~L\'intoxication t\'a tué.')
                            setLevel(src, 0) saveTox(src) Warned[src] = nil
                        end
                    end
                end
            end
        end
    end
end)

CreateThread(function() while true do Wait(60000) for src in pairs(Level) do saveTox(src) end end end)

RegisterNetEvent('esx:onPlayerDeath', function()
    local src = source
    if (Level[src] or 0) > 0 then setLevel(src, 0) saveTox(src) Warned[src] = nil end
end)

ESX.RegisterUsableItem(T.CureItem, function(src)
    if (Level[src] or 0) <= 0 then return JBNotifyClient(src, 'Tu n\'es pas intoxiqué.') end
    if not exports.ox_inventory:RemoveItem(src, T.CureItem, 1) then return end
    setLevel(src, 0) saveTox(src) Warned[src] = nil
    TriggerClientEvent('jobbuilder:client:toxicCured', src)
    JBNotifyClient(src, '~g~Antidote pris : tu es guéri.')
end)

exports('GetToxicLevel', function(src) return math.floor(Level[tonumber(src)] or 0) end)
