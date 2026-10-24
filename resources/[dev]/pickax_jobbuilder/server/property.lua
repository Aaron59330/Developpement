-- ─────────────────────────────── Immobilier ───────────────────────────────
-- Les agences (jobs de type "realestate") créent / vendent / louent des propriétés.
-- Tables dédiées jobbuilder_properties* : aucun lien avec `properties` / `owned_properties` de ta base.
-- Chaque propriété est une instance séparée (routing bucket) : plusieurs joueurs dans le même intérieur-type ne se croisent pas.

local R = Config.Real
local Props = {}       -- [id] = propriété (+ .points, .key_holders)
local Inside = {}      -- [src] = id de la propriété où se trouve le joueur
local Allowed = {}     -- [src] = { prop, exp } invité après avoir sonné
local RingCd = {}      -- [src] = timestamp dernier "sonner"
local Offers, offerId = {}, 0
JB.Props = Props
JB.Inside = Inside

local function fail(msg) return { ok = false, error = msg } end
local function now() return os.time() end

local function str(v, max, default)
    if type(v) ~= 'string' then return default or '' end
    return (v:gsub('%c', '')):sub(1, max or 100)
end
local function num(v, min, max, default)
    v = tonumber(v)
    if not v or v ~= v then return default end
    if min and v < min then v = min end
    if max and v > max then v = max end
    return v
end
local function coords(c)
    if type(c) ~= 'table' then return nil end
    local x, y, z = tonumber(c.x), tonumber(c.y), tonumber(c.z)
    if not (x and y and z) then return nil end
    return { x = math.floor(x * 100) / 100, y = math.floor(y * 100) / 100, z = math.floor(z * 100) / 100, h = math.floor((tonumber(c.h) or 0) * 100) / 100 }
end

local clothesKeys = {}
for _, k in ipairs(Config.ClothesKeys) do clothesKeys[k] = true end
local function cleanClothes(t)
    if type(t) ~= 'table' then return nil end
    local out, n = {}, 0
    for k, v in pairs(t) do
        if clothesKeys[k] and tonumber(v) then out[k] = tonumber(v) n = n + 1 end
    end
    return n > 0 and out or nil
end

-- ─────────────────────────────── Helpers métier ───────────────────────────────
local function agencyJob(name)
    local j = JB.Jobs[name]
    return (j and j.type == 'realestate') and j or nil
end

local function accessRole(x, p)
    if p.owner and p.owner == x.identifier then return 'owner' end
    for _, k in ipairs(p.key_holders) do
        if k.identifier == x.identifier then return 'key' end
    end
end

local function isAgent(x, p) return x.job.name == p.job_name and agencyJob(p.job_name) ~= nil end

-- IPL à charger côté client pour entrer (préréglage de l'intérieur ou liste saisie pour un intérieur personnalisé)
local function interiorIpl(p)
    if p.interior == 'custom' then
        local list = {}
        for name in tostring(p.ipl or ''):gmatch('[%w_]+') do list[#list + 1] = name end
        return list
    end
    local i = R.Interiors[p.interior]
    return i and i.ipl or {}
end

local function cleanIpl(v)
    local list = {}
    for name in tostring(v or ''):gmatch('[%w_]+') do
        if #list >= 8 then break end
        list[#list + 1] = name:sub(1, 90)
    end
    return table.concat(list, ',')
end

local function interiorExit(p)
    if p.interior == 'custom' then return p.exit end
    local i = R.Interiors[p.interior]
    return i and i.exit
end

local function history(p, job, action, actor, detail, amount)
    MySQL.insert('INSERT INTO jobbuilder_property_history (property_id, job_name, action, actor, detail, amount) VALUES (?, ?, ?, ?, ?, ?)',
        { p and p.id or nil, job, action, actor, detail and tostring(detail):sub(1, 200) or nil, amount or 0 })
end

local function stashId(p, pt) return ('jbprop_%d_%d'):format(p.id, pt.id) end

local function registerPropStash(p, pt)
    if JB.inventory() ~= 'ox' or (pt.type ~= 'stash' and pt.type ~= 'safe') then return end
    pcall(function()
        exports.ox_inventory:RegisterStash(stashId(p, pt), pt.label ~= '' and pt.label or p.label,
            tonumber(pt.data.slots) or 50, (tonumber(pt.data.weight) or 100) * 1000, false)
    end)
end

local function registerHook()
    if GetResourceState('ox_inventory') ~= 'started' then return end
    pcall(function()
        -- Seuls le propriétaire et les détenteurs de clés, présents DANS la propriété, ouvrent ses coffres
        exports.ox_inventory:registerHook('openInventory', function(payload)
            local pid = tonumber(tostring(payload.inventoryId):match('^jbprop_(%d+)_'))
            if not pid then return end
            local p, x = Props[pid], ESX.GetPlayerFromId(payload.source)
            if not p or not x or Inside[payload.source] ~= pid or not accessRole(x, p) then return false end
            -- Coffre-fort : propriétaire / locataire uniquement (pas les détenteurs de clés)
            local ptid = tonumber(tostring(payload.inventoryId):match('^jbprop_%d+_(%d+)$'))
            for _, pt in ipairs(p.points) do
                if pt.id == ptid and pt.type == 'safe' and accessRole(x, p) ~= 'owner' then return false end
            end
        end, { inventoryFilter = { '^jbprop_%d+_%d+$' } })
    end)
end

-- ─────────────────────────────── Chargement / sync ───────────────────────────────
local migrated = false
local function migrate()
    if migrated then return end
    migrated = true
    local cols = {
        { 'category', "varchar(20) NOT NULL DEFAULT 'house'" },
        { 'description', "varchar(300) NOT NULL DEFAULT ''" },
        { 'ipl', "varchar(300) NOT NULL DEFAULT ''" },
    }
    for _, c in ipairs(cols) do
        local has = MySQL.scalar.await("SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'jobbuilder_properties' AND COLUMN_NAME = ?", { c[1] }) or 0
        if has == 0 then
            local ok, err = pcall(MySQL.update.await, ('ALTER TABLE jobbuilder_properties ADD COLUMN `%s` %s'):format(c[1], c[2]))
            if not ok then print(('^1[jobbuilder] migration colonne %s : %s^0'):format(c[1], tostring(err))) end
        end
    end
end

function JB.loadProps()
    migrate()
    for k in pairs(Props) do Props[k] = nil end
    for _, r in ipairs(MySQL.query.await('SELECT * FROM jobbuilder_properties') or {}) do
        r.entrance = JB.decode(r.entrance, { x = 0, y = 0, z = 0, h = 0 })
        r.exit = JB.decode(r.exit_coords, nil)
        r.key_holders = JB.decode(r.key_holders, {})
        r.points = {}
        Props[r.id] = r
    end
    for _, pt in ipairs(MySQL.query.await('SELECT * FROM jobbuilder_property_points ORDER BY id') or {}) do
        local p = Props[pt.property_id]
        if p then
            pt.coords = JB.decode(pt.coords, { x = 0, y = 0, z = 0 })
            pt.data = JB.decode(pt.data, {})
            p.points[#p.points + 1] = pt
            registerPropStash(p, pt)
        end
    end
end

local function publicProp(p, x)
    return {
        id = p.id, label = p.label, address = p.address, deal = p.deal, price = p.price, status = p.status, category = p.category or 'house',
        job = p.job_name, entrance = p.entrance, access = (x and accessRole(x, p)) and true or false,
    }
end

function JB.syncProps(src)
    local x = ESX.GetPlayerFromId(src)
    local list = {}
    for _, p in pairs(Props) do list[#list + 1] = publicProp(p, x) end
    TriggerClientEvent('jobbuilder:client:props', src, list)
end

function JB.syncPropsAll()
    for _, s in ipairs(GetPlayers()) do JB.syncProps(tonumber(s)) end
end

RegisterNetEvent('jobbuilder:server:requestProps', function() JB.syncProps(source) end)
AddEventHandler('esx:playerLoaded', function(src) SetTimeout(2000, function() JB.syncProps(src) end) end)

AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then
        CreateThread(function()
            while not JB.ready do Wait(100) end
            JB.loadProps()
            registerHook()
            Wait(1500)
            JB.syncPropsAll()
        end)
    elseif res == 'ox_inventory' then
        CreateThread(function()
            Wait(1500)
            registerHook()
            for _, p in pairs(Props) do for _, pt in ipairs(p.points) do registerPropStash(p, pt) end end
        end)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    Inside[src], Allowed[src], RingCd[src] = nil, nil, nil
end)

-- ─────────────────────────────── Sortir les gens / remise à zéro ───────────────────────────────
local function kickAll(p)
    for src, pid in pairs(Inside) do
        if pid == p.id then
            Inside[src] = nil
            SetPlayerRoutingBucket(src, 0)
            TriggerClientEvent('jobbuilder:client:propKick', src, p.entrance)
        end
    end
end

local function resetProp(p, reason, actor)
    kickAll(p)
    if JB.furnClear then JB.furnClear(p.id) end
    for _, pt in ipairs(p.points) do
        if (pt.type == 'stash' or pt.type == 'safe') and JB.inventory() == 'ox' then
            pcall(function() exports.ox_inventory:ClearInventory(stashId(p, pt)) end)
        end
    end
    MySQL.update.await('DELETE FROM jobbuilder_property_outfits WHERE property_id = ?', { p.id })
    MySQL.update.await("UPDATE jobbuilder_properties SET status = 'available', owner = NULL, owner_name = NULL, rent_until = NULL, key_holders = '[]', sold_at = NULL WHERE id = ?", { p.id })
    local ownerX = p.owner and ESX.GetPlayerFromIdentifier(p.owner)
    if ownerX then JBNotifyClient( ownerX.source, ('~r~Tu n\'as plus accès à ~s~%s (%s)'):format(p.label, reason)) end
    p.status, p.owner, p.owner_name, p.rent_until, p.key_holders = 'available', nil, nil, nil, {}
    history(p, p.job_name, 'reset', actor, reason, 0)
    JB.syncPropsAll()
end

-- Loyers impayés
CreateThread(function()
    while true do
        Wait(R.RentCheckMinutes * 60000)
        for _, p in pairs(Props) do
            if p.deal == 'rent' and p.status == 'owned' and p.rent_until and p.rent_until < now() then
                resetProp(p, 'loyer impayé', 'système')
            end
        end
    end
end)

-- ─────────────────────────────── Porte : infos / entrer / sortir / sonner ───────────────────────────────
ESX.RegisterServerCallback('jobbuilder:prop:door', function(src, cb, id)
    local p, x = Props[tonumber(id)], ESX.GetPlayerFromId(src)
    if not p or not x then return cb(fail('Propriété introuvable')) end
    if JB.distanceTo(src, p.entrance) > Config.ServerDistance then return cb(fail('Tu es trop loin')) end
    local role = accessRole(x, p) or (isAgent(x, p) and 'agent') or 'visitor'
    local job = JB.Jobs[p.job_name]
    cb({
        ok = true, id = p.id, label = p.label, address = p.address, deal = p.deal, price = p.price, status = p.status,
        category = p.category or 'house', categoryLabel = (R.Categories[p.category or 'house'] or R.Categories.other).label, description = p.description or '',
        jobLabel = job and job.label or '', role = role, rent_until = p.rent_until, rent_days = R.RentDays,
        keys = role == 'owner' and p.key_holders or nil, maxKeys = R.MaxKeys,
        canVisit = role == 'agent' and p.status == 'available',
    })
end)

local function canEnter(src, x, p)
    local role = accessRole(x, p)
    if role then return role end
    if isAgent(x, p) and p.status == 'available' then return 'agent' end
    local a = Allowed[src]
    if a and a.prop == p.id and a.exp > now() then return 'guest' end
end

ESX.RegisterServerCallback('jobbuilder:prop:enter', function(src, cb, id)
    local p, x = Props[tonumber(id)], ESX.GetPlayerFromId(src)
    if not p or not x then return cb(fail('Propriété introuvable')) end
    if Inside[src] then return cb(fail('Tu es déjà dans une propriété')) end
    local role = canEnter(src, x, p)
    if not role then return cb(fail('Tu n\'as pas les clés de cette propriété')) end
    -- Un agent peut faire visiter à distance (depuis le panel) ; tous les autres doivent être devant la porte
    if role ~= 'agent' and JB.distanceTo(src, p.entrance) > Config.ServerDistance then return cb(fail('Tu es trop loin de la porte')) end
    local exit = interiorExit(p)
    if not exit then return cb(fail('Intérieur non configuré')) end
    if role == 'guest' then Allowed[src] = nil end

    Inside[src] = p.id
    SetPlayerRoutingBucket(src, R.BucketBase + p.id)
    local pts = {}
    for _, pt in ipairs(p.points) do pts[#pts + 1] = { id = pt.id, type = pt.type, label = pt.label, coords = pt.coords } end
    cb({ ok = true, id = p.id, label = p.label, role = role, exit = exit, entrance = p.entrance, points = pts, ipl = interiorIpl(p), furniture = JB.furnList and JB.furnList(p.id) or {} })
end)

ESX.RegisterServerCallback('jobbuilder:prop:leave', function(src, cb)
    local pid = Inside[src]
    local p = pid and Props[pid]
    if not p then
        Inside[src] = nil
        SetPlayerRoutingBucket(src, 0)
        return cb(fail('Tu n\'es dans aucune propriété'))
    end
    local exit = interiorExit(p)
    if exit and JB.distanceTo(src, exit) > Config.ServerDistance * 3 then return cb(fail('Rapproche-toi de la sortie')) end
    Inside[src] = nil
    SetPlayerRoutingBucket(src, 0)
    cb({ ok = true, entrance = p.entrance })
end)

ESX.RegisterServerCallback('jobbuilder:prop:ring', function(src, cb, id)
    local p, x = Props[tonumber(id)], ESX.GetPlayerFromId(src)
    if not p or not x then return cb(fail('Propriété introuvable')) end
    if JB.distanceTo(src, p.entrance) > Config.ServerDistance then return cb(fail('Tu es trop loin')) end
    if accessRole(x, p) then return cb(fail('Tu as les clés de cette propriété')) end
    if p.status ~= 'owned' then return cb(fail('Personne n\'habite ici')) end
    if (RingCd[src] or 0) > now() - 8 then return cb(fail('Patiente avant de sonner à nouveau')) end
    RingCd[src] = now()
    local count = 0
    for s, pid in pairs(Inside) do
        local xs = ESX.GetPlayerFromId(s)
        if pid == p.id and xs and accessRole(xs, p) then
            count = count + 1
            TriggerClientEvent('jobbuilder:client:ringPrompt', s, src, p.id, JB.playerName(x))
        end
    end
    if count == 0 then return cb(fail('Personne ne répond')) end
    cb({ ok = true })
end)

RegisterNetEvent('jobbuilder:server:ringAnswer', function(ringer, id, yes)
    local src = source
    local p, x = Props[tonumber(id)], ESX.GetPlayerFromId(src)
    if not p or not x or Inside[src] ~= p.id or not accessRole(x, p) then return end
    ringer = tonumber(ringer)
    if not ringer or not GetPlayerName(ringer) then return end
    if yes then
        Allowed[ringer] = { prop = p.id, exp = now() + 60 }
        TriggerClientEvent('jobbuilder:client:ringAccepted', ringer, p.id)
    else
        JBNotifyClient( ringer, '~r~Personne ne t\'ouvre.')
    end
end)

RegisterNetEvent('jobbuilder:server:forceLeave', function()
    local src = source
    if Inside[src] then
        Inside[src] = nil
        SetPlayerRoutingBucket(src, 0)
    end
end)

-- ─────────────────────────────── Points intérieurs (coffre / penderie) ───────────────────────────────
local function pointCtx(src, propId, pointId, ptype)
    local x, p = ESX.GetPlayerFromId(src), Props[tonumber(propId)]
    if not x or not p then return nil, nil, nil, 'Propriété introuvable' end
    if Inside[src] ~= p.id then return nil, nil, nil, 'Tu n\'es pas dans cette propriété' end
    local point
    for _, pt in ipairs(p.points) do if pt.id == tonumber(pointId) then point = pt end end
    if not point or (ptype and point.type ~= ptype) then return nil, nil, nil, 'Point introuvable' end
    if JB.distanceTo(src, point.coords) > Config.ServerDistance then return nil, nil, nil, 'Tu es trop loin' end
    if not accessRole(x, p) then return nil, nil, nil, 'Réservé aux occupants' end
    return p, point, x
end

local function outfitList(propId, identifier)
    local rows = MySQL.query.await('SELECT id, label FROM jobbuilder_property_outfits WHERE property_id = ? AND identifier = ? ORDER BY id', { propId, identifier }) or {}
    return rows
end

ESX.RegisterServerCallback('jobbuilder:prop:openPoint', function(src, cb, propId, pointId)
    local p, point, x, err = pointCtx(src, propId, pointId)
    if not p then return cb(fail(err)) end
    if point.type == 'stash' or point.type == 'safe' then
        if point.type == 'safe' and accessRole(x, p) ~= 'owner' then return cb(fail('Réservé au propriétaire')) end
        if JB.inventory() ~= 'ox' then return cb(fail('Les coffres nécessitent ox_inventory')) end
        cb({ ok = true, kind = 'stash', stash = stashId(p, point) })
    else
        cb({ ok = true, kind = 'wardrobe', label = point.label ~= '' and point.label or p.label, outfits = outfitList(p.id, x.identifier), max = R.OutfitsPerPlayer })
    end
end)

ESX.RegisterServerCallback('jobbuilder:prop:wardrobe:save', function(src, cb, propId, pointId, label, clothes)
    local p, point, x, err = pointCtx(src, propId, pointId, 'wardrobe')
    if not p then return cb(fail(err)) end
    clothes = cleanClothes(clothes)
    if not clothes then return cb(fail('Impossible de lire ta tenue')) end
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM jobbuilder_property_outfits WHERE property_id = ? AND identifier = ?', { p.id, x.identifier }) or 0
    if count >= R.OutfitsPerPlayer then return cb(fail(('Penderie pleine (%d tenues max)'):format(R.OutfitsPerPlayer))) end
    MySQL.insert.await('INSERT INTO jobbuilder_property_outfits (property_id, identifier, label, clothes) VALUES (?, ?, ?, ?)',
        { p.id, x.identifier, str(label, 60, 'Tenue'), json.encode(clothes) })
    cb({ ok = true, outfits = outfitList(p.id, x.identifier) })
end)

ESX.RegisterServerCallback('jobbuilder:prop:wardrobe:delete', function(src, cb, propId, pointId, outfitId)
    local p, point, x, err = pointCtx(src, propId, pointId, 'wardrobe')
    if not p then return cb(fail(err)) end
    MySQL.update.await('DELETE FROM jobbuilder_property_outfits WHERE id = ? AND property_id = ? AND identifier = ?', { tonumber(outfitId), p.id, x.identifier })
    cb({ ok = true, outfits = outfitList(p.id, x.identifier) })
end)

ESX.RegisterServerCallback('jobbuilder:prop:wardrobe:wear', function(src, cb, propId, pointId, outfitId)
    local p, point, x, err = pointCtx(src, propId, pointId, 'wardrobe')
    if not p then return cb(fail(err)) end
    local row = MySQL.single.await('SELECT clothes FROM jobbuilder_property_outfits WHERE id = ? AND property_id = ? AND identifier = ?', { tonumber(outfitId), p.id, x.identifier })
    if not row then return cb(fail('Tenue introuvable')) end
    cb({ ok = true, clothes = JB.decode(row.clothes, {}) })
end)

-- ─────────────────────────────── Clés / loyer ───────────────────────────────
local function playersClose(a, b)
    return #(GetEntityCoords(GetPlayerPed(a)) - GetEntityCoords(GetPlayerPed(b))) <= Config.TargetDistance + 2.0
end

local function saveKeys(p)
    MySQL.update.await('UPDATE jobbuilder_properties SET key_holders = ? WHERE id = ?', { json.encode(p.key_holders), p.id })
    JB.syncPropsAll()
end

ESX.RegisterServerCallback('jobbuilder:prop:giveKey', function(src, cb, id, targetId)
    local p, x = Props[tonumber(id)], ESX.GetPlayerFromId(src)
    if not p or not x or accessRole(x, p) ~= 'owner' then return cb(fail('Réservé au propriétaire')) end
    local t = ESX.GetPlayerFromId(tonumber(targetId))
    if not t or t.source == src then return cb(fail('Aucun joueur à proximité')) end
    if not playersClose(src, t.source) then return cb(fail('Le joueur est trop loin')) end
    if #p.key_holders >= R.MaxKeys then return cb(fail(('Maximum %d doubles de clés'):format(R.MaxKeys))) end
    if accessRole(t, p) then return cb(fail('Ce joueur a déjà accès')) end
    p.key_holders[#p.key_holders + 1] = { identifier = t.identifier, name = JB.playerName(t) }
    saveKeys(p)
    JBNotifyClient( t.source, ('Tu as reçu un double des clés de ~b~%s'):format(p.label))
    cb({ ok = true, keys = p.key_holders })
end)

ESX.RegisterServerCallback('jobbuilder:prop:removeKey', function(src, cb, id, identifier)
    local p, x = Props[tonumber(id)], ESX.GetPlayerFromId(src)
    if not p or not x or accessRole(x, p) ~= 'owner' then return cb(fail('Réservé au propriétaire')) end
    for i, k in ipairs(p.key_holders) do
        if k.identifier == identifier then
            table.remove(p.key_holders, i)
            saveKeys(p)
            local t = ESX.GetPlayerFromIdentifier(identifier)
            if t and Inside[t.source] == p.id then
                Inside[t.source] = nil
                SetPlayerRoutingBucket(t.source, 0)
                TriggerClientEvent('jobbuilder:client:propKick', t.source, p.entrance)
            end
            break
        end
    end
    cb({ ok = true, keys = p.key_holders })
end)

ESX.RegisterServerCallback('jobbuilder:prop:payRent', function(src, cb, id)
    local p, x = Props[tonumber(id)], ESX.GetPlayerFromId(src)
    if not p or not x or accessRole(x, p) ~= 'owner' or p.deal ~= 'rent' then return cb(fail('Loyer indisponible')) end
    local base = math.max(p.rent_until or 0, now())
    if base > now() + (R.MaxRentAhead - 1) * R.RentDays * 86400 then return cb(fail(('Tu ne peux pas payer plus de %d périodes d\'avance'):format(R.MaxRentAhead))) end
    if not JB.pay(x, p.price) then return cb(fail('Pas assez d\'argent')) end
    local job = JB.Jobs[p.job_name]
    local tax = JB.applyTax and JB.applyTax('realestate', p.price, p.job_name) or 0
    if job and job.society then JB.societyAdd(p.job_name, p.price - tax) end
    p.rent_until = base + R.RentDays * 86400
    MySQL.update.await('UPDATE jobbuilder_properties SET rent_until = ? WHERE id = ?', { p.rent_until, p.id })
    history(p, p.job_name, 'rent_paid', JB.playerName(x), p.label, p.price)
    cb({ ok = true, rent_until = p.rent_until })
end)

ESX.RegisterServerCallback('jobbuilder:prop:terminate', function(src, cb, id)
    local p, x = Props[tonumber(id)], ESX.GetPlayerFromId(src)
    if not p or not x or accessRole(x, p) ~= 'owner' or p.deal ~= 'rent' then return cb(fail('Action indisponible')) end
    resetProp(p, 'résiliation du bail', JB.playerName(x))
    cb({ ok = true })
end)

-- ─────────────────────────────── Agence : panel de gestion ───────────────────────────────
local function agentCtx(src, needAdmin)
    local x = ESX.GetPlayerFromId(src)
    if not x then return nil, nil, 'Joueur introuvable' end
    local job = agencyJob(x.job.name)
    if not job then return nil, nil, 'Ton métier n\'est pas une agence immobilière' end
    local s = job.settings or {}
    if x.job.grade < (s.prop_grade or 0) then return nil, nil, 'Ton grade ne permet pas de gérer les propriétés' end
    if needAdmin and x.job.grade < (s.prop_admin_grade or job.boss_grade) then return nil, nil, 'Réservé à la direction de l\'agence' end
    return x, job
end

local function agencyData(x, job)
    local s = job.settings or {}
    local list = {}
    local stats = { total = 0, available = 0, sale = 0, rent = 0 }
    for _, p in pairs(Props) do
        if p.job_name == job.name then
            local pts = {}
            for _, pt in ipairs(p.points) do pts[#pts + 1] = { id = pt.id, type = pt.type, label = pt.label, coords = pt.coords, data = pt.data } end
            local ex = interiorExit(p)
            list[#list + 1] = {
                id = p.id, label = p.label, address = p.address, deal = p.deal, price = p.price, status = p.status,
                owner_name = p.owner_name, rent_until = p.rent_until, interior = p.interior, entrance = p.entrance,
                category = p.category or 'house', description = p.description or '', ipl = p.ipl or '',
                exit = p.interior == 'custom' and p.exit or nil, hasExit = ex ~= nil, keys = #p.key_holders, points = pts,
            }
            stats.total = stats.total + 1
            if p.status == 'available' then stats.available = stats.available + 1
            elseif p.deal == 'rent' then stats.rent = stats.rent + 1
            else stats.sale = stats.sale + 1 end
        end
    end
    table.sort(list, function(a, b) return a.id > b.id end)
    stats.revenue = MySQL.scalar.await("SELECT COALESCE(SUM(amount), 0) FROM jobbuilder_property_history WHERE job_name = ? AND amount > 0 AND created_at > (NOW() - INTERVAL 30 DAY)", { job.name }) or 0
    local hist = MySQL.query.await([[SELECT h.action, h.actor, h.detail, h.amount, UNIX_TIMESTAMP(h.created_at) AS t, p.label AS prop
        FROM jobbuilder_property_history h LEFT JOIN jobbuilder_properties p ON p.id = h.property_id
        WHERE h.job_name = ? ORDER BY h.id DESC LIMIT 40]], { job.name }) or {}
    local interiors = {}
    for k, i in pairs(R.Interiors) do interiors[#interiors + 1] = { key = k, label = i.label, cat = i.cat or 'other' } end
    table.sort(interiors, function(a, b) return a.cat == b.cat and a.key < b.key or a.cat < b.cat end)
    interiors[#interiors + 1] = { key = 'custom', label = 'Intérieur personnalisé (MLO / shell)', cat = 'custom' }
    local cats = {}
    for _, k in ipairs(R.CategoryOrder) do if R.Categories[k] then cats[#cats + 1] = { key = k, label = R.Categories[k].label } end end
    return {
        ok = true, job = job.name, jobLabel = job.label, agent = JB.playerName(x), gradeLabel = x.job.grade_label,
        commission = s.commission or R.DefaultCommission, admin = x.job.grade >= (s.prop_admin_grade or job.boss_grade),
        props = list, stats = stats, history = hist, interiors = interiors, categories = cats, maxPoints = R.MaxPointsPerProp, rentDays = R.RentDays,
    }
end

ESX.RegisterServerCallback('jobbuilder:prop:manage', function(src, cb)
    local x, job, err = agentCtx(src)
    if not x then return cb(fail(err)) end
    cb(agencyData(x, job))
end)

local function cleanProperty(d, existing)
    if type(d) ~= 'table' then return nil, 'Données invalides' end
    local out = { label = str(d.label, 80), address = str(d.address, 120) }
    if out.label == '' then return nil, 'Le nom de la propriété est obligatoire' end
    out.category = R.Categories[tostring(d.category or '')] and tostring(d.category) or 'house'
    out.description = str(d.description, 300)
    out.ipl = cleanIpl(d.ipl)
    out.entrance = coords(d.entrance)
    if not out.entrance then return nil, 'Position de l\'entrée manquante' end

    local owned = existing and existing.status == 'owned'
    if owned then
        out.deal, out.price, out.interior, out.exit, out.ipl = existing.deal, existing.price, existing.interior, existing.exit, existing.ipl or ''
    else
        out.deal = d.deal == 'rent' and 'rent' or 'sale'
        out.price = math.floor(num(d.price, 0, 1000000000, 0))
        if out.price <= 0 then return nil, 'Indique un prix (ou un loyer) supérieur à 0' end
        out.interior = tostring(d.interior or '')
        if out.interior == 'custom' then
            out.exit = coords(d.exit)
            if not out.exit then return nil, 'Intérieur personnalisé : position de sortie manquante (place-toi à l\'intérieur)' end
        elseif R.Interiors[out.interior] then
            out.exit = nil
        else
            return nil, 'Intérieur invalide'
        end
    end

    out.points = {}
    local pts = type(d.points) == 'table' and d.points or {}
    if #pts > R.MaxPointsPerProp then return nil, ('Maximum %d points par propriété'):format(R.MaxPointsPerProp) end
    for _, p in ipairs(pts) do
        if type(p) ~= 'table' or not R.PointTypes[p.type] then return nil, 'Type de point invalide' end
        local c = coords(p.coords)
        if not c then return nil, ('Point « %s » : position manquante (visite la propriété puis « Ma position »)'):format(str(p.label, 40, R.PointTypes[p.type].label)) end
        local pd = {}
        if p.type == 'stash' or p.type == 'safe' then
            local dd = type(p.data) == 'table' and p.data or {}
            pd.slots = math.floor(num(dd.slots, 5, 200, 50))
            pd.weight = math.floor(num(dd.weight, 1, 2000, 100))
        end
        out.points[#out.points + 1] = { id = tonumber(p.id), type = p.type, label = str(p.label, 60, R.PointTypes[p.type].label), coords = c, data = pd }
    end
    return out
end

ESX.RegisterServerCallback('jobbuilder:prop:save', function(src, cb, d)
    local x, job, err = agentCtx(src)
    if not x then return cb(fail(err)) end
    local existing = type(d) == 'table' and d.id and Props[tonumber(d.id)] or nil
    if existing and existing.job_name ~= job.name then return cb(fail('Cette propriété appartient à une autre agence')) end
    local prop, perr = cleanProperty(d, existing)
    if not prop then return cb(fail(perr)) end

    local id
    if existing then
        id = existing.id
        MySQL.update.await('UPDATE jobbuilder_properties SET label = ?, address = ?, deal = ?, price = ?, interior = ?, entrance = ?, exit_coords = ?, category = ?, description = ?, ipl = ? WHERE id = ? AND job_name = ?',
            { prop.label, prop.address, prop.deal, prop.price, prop.interior, json.encode(prop.entrance), prop.exit and json.encode(prop.exit) or nil, prop.category, prop.description, prop.ipl, id, job.name })
    else
        id = MySQL.insert.await('INSERT INTO jobbuilder_properties (job_name, label, address, deal, price, interior, entrance, exit_coords, category, description, ipl, key_holders, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            { job.name, prop.label, prop.address, prop.deal, prop.price, prop.interior, json.encode(prop.entrance), prop.exit and json.encode(prop.exit) or nil, prop.category, prop.description, prop.ipl, '[]', x.identifier })
    end
    if not id then return cb(fail('Erreur SQL')) end

    local q, keep = {}, {}
    local old = {}
    if existing then for _, pt in ipairs(existing.points) do old[pt.id] = true end end
    for _, p in ipairs(prop.points) do
        if p.id and old[p.id] then
            keep[p.id] = true
            q[#q + 1] = { query = 'UPDATE jobbuilder_property_points SET type = ?, label = ?, coords = ?, data = ? WHERE id = ? AND property_id = ?',
                values = { p.type, p.label, json.encode(p.coords), json.encode(p.data), p.id, id } }
        else
            q[#q + 1] = { query = 'INSERT INTO jobbuilder_property_points (property_id, type, label, coords, data) VALUES (?, ?, ?, ?, ?)',
                values = { id, p.type, p.label, json.encode(p.coords), json.encode(p.data) } }
        end
    end
    for pid in pairs(old) do
        if not keep[pid] then q[#q + 1] = { query = 'DELETE FROM jobbuilder_property_points WHERE id = ? AND property_id = ?', values = { pid, id } } end
    end
    if #q > 0 and not MySQL.transaction.await(q) then return cb(fail('Erreur SQL : points non enregistrés')) end

    if existing then kickAll(existing) end   -- les points ont pu changer : on fait sortir tout le monde proprement
    JB.loadProps()
    history(Props[id], job.name, existing and 'updated' or 'created', JB.playerName(x), prop.label, 0)
    JB.syncPropsAll()
    local data = agencyData(x, job)
    data.savedId = id
    cb(data)
end)

ESX.RegisterServerCallback('jobbuilder:prop:delete', function(src, cb, id)
    local x, job, err = agentCtx(src, true)
    if not x then return cb(fail(err)) end
    local p = Props[tonumber(id)]
    if not p or p.job_name ~= job.name then return cb(fail('Propriété introuvable')) end
    if p.status ~= 'available' then return cb(fail('Cette propriété est occupée : remets-la d\'abord en vente')) end
    kickAll(p)
    if JB.furnClear then JB.furnClear(p.id) end
    MySQL.update.await('DELETE FROM jobbuilder_properties WHERE id = ? AND job_name = ?', { p.id, job.name })
    history(nil, job.name, 'deleted', JB.playerName(x), p.label, 0)
    JB.loadProps()
    JB.syncPropsAll()
    cb(agencyData(x, job))
end)

ESX.RegisterServerCallback('jobbuilder:prop:reset', function(src, cb, id)
    local x, job, err = agentCtx(src, true)
    if not x then return cb(fail(err)) end
    local p = Props[tonumber(id)]
    if not p or p.job_name ~= job.name then return cb(fail('Propriété introuvable')) end
    if p.status ~= 'owned' then return cb(fail('Cette propriété est déjà disponible')) end
    resetProp(p, 'reprise par l\'agence', JB.playerName(x))
    cb(agencyData(x, job))
end)

-- ─────────────────────────────── Vente / location à un joueur ───────────────────────────────
ESX.RegisterServerCallback('jobbuilder:prop:offer', function(src, cb, id, targetId)
    local x, job, err = agentCtx(src)
    if not x then return cb(fail(err)) end
    local p = Props[tonumber(id)]
    if not p or p.job_name ~= job.name then return cb(fail('Propriété introuvable')) end
    if p.status ~= 'available' then return cb(fail('Cette propriété n\'est pas disponible')) end
    local t = ESX.GetPlayerFromId(tonumber(targetId))
    if not t or t.source == src then return cb(fail('Aucun client à proximité')) end
    if not playersClose(src, t.source) then return cb(fail('Le client est trop loin')) end
    local owned = 0
    for _, q in pairs(Props) do if q.owner == t.identifier then owned = owned + 1 end end
    if owned >= R.MaxPerPlayer then return cb(fail(('Ce client possède déjà %d propriétés (maximum)'):format(R.MaxPerPlayer))) end

    offerId = offerId + 1
    Offers[offerId] = { from = src, to = t.source, prop = p.id, exp = now() + 90 }
    TriggerClientEvent('jobbuilder:client:propOffer', t.source, offerId, {
        label = p.label, address = p.address, deal = p.deal, price = p.price, jobLabel = job.label, days = R.RentDays,
    })
    cb({ ok = true })
end)

RegisterNetEvent('jobbuilder:server:offerAnswer', function(id, yes)
    local src = source
    local o = Offers[id]
    if not o or o.to ~= src then return end
    Offers[id] = nil
    local agent = ESX.GetPlayerFromId(o.from)
    if o.exp < now() then return end
    if not yes then
        if agent then JBNotifyClient( o.from, '~r~Le client a refusé l\'offre.') end
        return
    end
    local buyer, p = ESX.GetPlayerFromId(src), Props[o.prop]
    if not buyer or not p or p.status ~= 'available' then
        JBNotifyClient( src, '~r~Ce bien n\'est plus disponible.')
        return
    end
    local owned = 0
    for _, q in pairs(Props) do if q.owner == buyer.identifier then owned = owned + 1 end end
    if owned >= R.MaxPerPlayer then
        JBNotifyClient( src, '~r~Tu possèdes déjà trop de propriétés.')
        return
    end
    if not JB.pay(buyer, p.price) then
        JBNotifyClient( src, '~r~Tu n\'as pas assez d\'argent.')
        if agent then JBNotifyClient( o.from, '~r~Le client n\'a pas assez d\'argent.') end
        return
    end
    p.status, p.owner = 'owned', buyer.identifier      -- réservé tout de suite : deux offres acceptées en même temps ne vendent pas le bien deux fois

    -- Répartition : commission à l'agent (s'il est en ligne), le reste à la société de l'agence
    local job = JB.Jobs[p.job_name]
    local pct = (job and job.settings.commission) or R.DefaultCommission
    local tax = JB.applyTax and JB.applyTax('realestate', p.price, p.job_name) or 0
    local net = p.price - tax
    local commission = (agent and agent.job.name == p.job_name) and math.floor(net * pct / 100) or 0
    local toSociety = net - commission
    if job and job.society then
        JB.societyAdd(p.job_name, toSociety)
    elseif agent then
        commission = commission + toSociety
    end
    if agent and commission > 0 then
        agent.addAccountMoney('bank', commission)
        JBNotifyClient( o.from, ('Vente conclue ! Commission : ~g~+%d$'):format(commission))
    end

    local rentUntil = p.deal == 'rent' and (now() + R.RentDays * 86400) or nil
    MySQL.update.await("UPDATE jobbuilder_properties SET status = 'owned', owner = ?, owner_name = ?, rent_until = ?, key_holders = '[]', sold_at = NOW() WHERE id = ?",
        { buyer.identifier, JB.playerName(buyer), rentUntil, p.id })
    p.status, p.owner, p.owner_name, p.rent_until, p.key_holders = 'owned', buyer.identifier, JB.playerName(buyer), rentUntil, {}
    history(p, p.job_name, p.deal == 'rent' and 'rented' or 'sold', agent and JB.playerName(agent) or 'agence',
        ('%s → %s'):format(p.label, JB.playerName(buyer)), p.price)
    JBNotifyClient( src, ('Félicitations ! ~b~%s~s~ est à toi.'):format(p.label))
    JB.syncPropsAll()
end)
