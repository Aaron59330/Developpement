-- ─────────────────────────────── Meubles des propriétés ───────────────────────────────
-- Le propriétaire (seul) décore son intérieur depuis la propriété. Limite PAR PROPRIÉTÉ : Config.Real.Furniture.BaseLimit, ou celle du VIP du
-- propriétaire si elle est plus haute. Les meubles sont enregistrés en base (jobbuilder_furniture) et créés en local chez les occupants.
local F = Config.Real.Furniture
local Cache = {}     -- [propId] = liste { id, model, x, y, z, h }
local lastAct = {}

local function fail(msg) return { ok = false, error = msg } end

CreateThread(function()
    Wait(800)
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS jobbuilder_furniture (
        id INT AUTO_INCREMENT PRIMARY KEY, property_id INT NOT NULL, model VARCHAR(40) NOT NULL,
        x FLOAT NOT NULL, y FLOAT NOT NULL, z FLOAT NOT NULL, h FLOAT NOT NULL DEFAULT 0, placed_by VARCHAR(80) NULL,
        INDEX idx_prop (property_id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
end)

local function entry(id) for _, c in ipairs(F.Catalog) do if c.id == id then return c end end end

local function load(pid)
    if not Cache[pid] then
        local list = {}
        for _, r in ipairs(MySQL.query.await('SELECT id, model, x, y, z, h FROM jobbuilder_furniture WHERE property_id = ? ORDER BY id', { pid }) or {}) do
            list[#list + 1] = { id = r.id, model = r.model, x = r.x, y = r.y, z = r.z, h = r.h }
        end
        Cache[pid] = list
    end
    return Cache[pid]
end

function JB.furnList(pid) return load(pid) end

function JB.furnClear(pid)
    Cache[pid] = nil
    MySQL.update.await('DELETE FROM jobbuilder_furniture WHERE property_id = ?', { pid })
end

local function push(pid)
    local list = load(pid)
    for src, p in pairs(JB.Inside) do
        if p == pid then TriggerClientEvent('jobbuilder:client:furniture', src, list) end
    end
end

local function vipLevel(src)
    local ok, l = pcall(function() return exports.pickax_core:GetVIPLevel(src) end)
    return ok and tonumber(l) or 0
end

local function limitFor(src, role)
    if role == 'agent' then return (Config.Real.Decor or {}).AgentLimit or F.BaseLimit, 0 end
    local l, lim = vipLevel(src), F.BaseLimit
    if l > 0 and F.VipLimits and F.VipLimits[l] then lim = math.max(lim, F.VipLimits[l]) end
    return lim, l
end

-- Le joueur doit être DANS la propriété et en être le propriétaire (ou l'agent de l'agence qui gère un bien disponible : Config.Real.Decor)
local D = Config.Real.Decor or {}
local function agentCan(x, p)
    if not D.Enabled then return false end
    if x.job.name ~= p.job_name then return false end
    local j = JB.Jobs[p.job_name]
    if not j or j.type ~= 'realestate' then return false end
    if D.AgentOnAvailable ~= false and p.status ~= 'available' then return false end
    return true
end

local function ctx(src)
    if not F.Enabled then return nil, nil, 'Les meubles sont désactivés' end
    local x = ESX.GetPlayerFromId(src)
    local p = x and JB.Props[JB.Inside[src] or 0]
    if not p then return nil, nil, 'Tu dois être dans la propriété' end
    if p.owner == x.identifier then return x, p, nil, 'owner' end
    if agentCan(x, p) then return x, p, nil, 'agent' end
    return nil, nil, 'Seul le propriétaire (ou l\'agent du bien disponible) peut décorer'
end

-- ───────────── Styles d'intérieur ─────────────
local function stylesOf(p)
    if p.interior == 'custom' then return D.CustomStyles or {} end
    local i = Config.Real.Interiors[p.interior]
    return (i and i.styles) or {}
end

local function styleById(p, id)
    for _, st in ipairs(stylesOf(p)) do if st.id == id then return st end end
end

-- Données d'application côté client : tous les sets gérés par cet intérieur + ceux du style choisi
function JB.decorSets(p)
    local all, on, tint = {}, {}, {}
    for _, st in ipairs(stylesOf(p)) do
        for _, n in ipairs(st.sets or {}) do all[#all + 1] = n end
        for _, n in ipairs(st.tintSets or {}) do all[#all + 1] = n end
    end
    local cur = p.decor and styleById(p, p.decor.style)
    if cur then
        for _, n in ipairs(cur.sets or {}) do on[#on + 1] = n end
        for _, n in ipairs(cur.tintSets or {}) do on[#on + 1] = n tint[#tint + 1] = n end
    end
    return { all = all, on = on, tint = tint, color = p.decor and p.decor.color or 0 }
end

local function pushDecor(p)
    for src, pid in pairs(JB.Inside) do
        if pid == p.id then TriggerClientEvent('jobbuilder:client:decor', src, JB.decorSets(p)) end
    end
end

ESX.RegisterServerCallback('jobbuilder:decor:set', function(src, cb, styleId, color)
    local x, p, err, role = ctx(src)
    if not x then return cb(fail(err)) end
    if role == 'owner' and D.OwnerCanStyle == false then return cb(fail('Le style ne peut être changé que par l\'agent')) end
    local st = styleById(p, tostring(styleId or ''))
    if not st then return cb(fail('Style inconnu')) end
    local col = math.floor(tonumber(color) or 0)
    local okc = false
    for _, c in ipairs(D.Colors or {}) do if c.id == col then okc = true break end end
    if not okc then col = 0 end
    p.decor = { style = st.id, color = col }
    MySQL.update('UPDATE jobbuilder_properties SET decor = ? WHERE id = ?', { json.encode(p.decor), p.id })
    pushDecor(p)
    cb({ ok = true, decor = p.decor })
end)

local function pubList(list)
    local out = {}
    for _, f in ipairs(list) do
        local c = entry(f.model)
        if c then out[#out + 1] = { id = f.id, model = f.model, label = c.label, cat = c.cat } end
    end
    return out
end

ESX.RegisterServerCallback('jobbuilder:furn:list', function(src, cb)
    local x, p, err, role = ctx(src)
    if not x then return cb(fail(err)) end
    local limit, vip = limitFor(src, role)
    local list = load(p.id)
    local cat = {}
    for _, c in ipairs(F.Catalog) do cat[#cat + 1] = { id = c.id, label = c.label, cat = c.cat, wall = c.wall or nil } end
    local styles = {}
    if role ~= 'owner' or D.OwnerCanStyle ~= false then
        for _, st in ipairs(stylesOf(p)) do styles[#styles + 1] = { id = st.id, label = st.label, tint = (st.tintSets and #st.tintSets > 0) or nil } end
    end
    cb({ ok = true, lab = Config.Real.Lab.Enabled and p.category == Config.Real.Lab.Category or false, label = p.label, limit = limit, vip = vip, base = F.BaseLimit, vipLimits = F.VipLimits, count = #list, catalog = cat, mine = pubList(list), role = role, decor = { styles = styles, current = p.decor or {}, colors = D.Colors or {}, canStyle = role ~= 'owner' or D.OwnerCanStyle ~= false } })
end)

local function validPos(src, c)
    if type(c) ~= 'table' or not tonumber(c.x) or not tonumber(c.y) or not tonumber(c.z) then return nil end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local pc = GetEntityCoords(ped)
    local x, y, z = tonumber(c.x) + 0.0, tonumber(c.y) + 0.0, tonumber(c.z) + 0.0
    if #(vector3(pc.x, pc.y, pc.z) - vector3(x, y, z)) > (F.PlaceDistance or 8.0) + 6.0 then return nil end
    return x, y, z, (tonumber(c.h) or 0.0) + 0.0
end

local function throttled(src)
    local now = GetGameTimer()
    if lastAct[src] and now - lastAct[src] < (F.Cooldown or 700) then return true end
    lastAct[src] = now
    return false
end

ESX.RegisterServerCallback('jobbuilder:furn:place', function(src, cb, id, c)
    local x, p, err, role = ctx(src)
    if not x then return cb(fail(err)) end
    local e = entry(tostring(id))
    if not e then return cb(fail('Meuble inconnu')) end
    local px, py, pz, ph = validPos(src, c)
    if not px then return cb(fail('Position invalide ou trop loin')) end
    if throttled(src) then return cb(fail('Doucement…')) end
    local list = load(p.id)
    local limit = limitFor(src, role)
    if #list >= limit then return cb(fail(('Limite atteinte : %d meubles maximum dans cette propriété'):format(limit))) end
    local rid = MySQL.insert.await('INSERT INTO jobbuilder_furniture (property_id, model, x, y, z, h, placed_by) VALUES (?, ?, ?, ?, ?, ?, ?)', { p.id, e.id, px, py, pz, ph, x.identifier })
    list[#list + 1] = { id = rid, model = e.id, x = px, y = py, z = pz, h = ph }
    push(p.id)
    cb({ ok = true, count = #list, limit = limit })
end)

ESX.RegisterServerCallback('jobbuilder:furn:move', function(src, cb, fid, c)
    local x, p, err = ctx(src)
    if not x then return cb(fail(err)) end
    local px, py, pz, ph = validPos(src, c)
    if not px then return cb(fail('Position invalide ou trop loin')) end
    if throttled(src) then return cb(fail('Doucement…')) end
    for _, f in ipairs(load(p.id)) do
        if f.id == tonumber(fid) then
            f.x, f.y, f.z, f.h = px, py, pz, ph
            MySQL.update('UPDATE jobbuilder_furniture SET x = ?, y = ?, z = ?, h = ? WHERE id = ?', { px, py, pz, ph, f.id })
            push(p.id)
            return cb({ ok = true })
        end
    end
    cb(fail('Meuble introuvable'))
end)

ESX.RegisterServerCallback('jobbuilder:furn:remove', function(src, cb, fid)
    local x, p, err = ctx(src)
    if not x then return cb(fail(err)) end
    local list = load(p.id)
    for i, f in ipairs(list) do
        if f.id == tonumber(fid) then
            table.remove(list, i)
            MySQL.update('DELETE FROM jobbuilder_furniture WHERE id = ?', { f.id })
            push(p.id)
            return cb({ ok = true })
        end
    end
    cb(fail('Meuble introuvable'))
end)

ESX.RegisterServerCallback('jobbuilder:furn:removeAll', function(src, cb)
    local x, p, err = ctx(src)
    if not x then return cb(fail(err)) end
    JB.furnClear(p.id)
    push(p.id)
    cb({ ok = true })
end)

AddEventHandler('playerDropped', function() lastAct[source] = nil end)
exports('GetFurnitureLimit', function(src) return (limitFor(tonumber(src))) end)
