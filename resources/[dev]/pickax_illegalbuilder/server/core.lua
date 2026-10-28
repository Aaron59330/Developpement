local function ECO(kind, n) if GetResourceState('pickax_economy') ~= 'started' then return n end local ok, r = pcall(function() return exports.pickax_economy:Scale(kind, n) end) return (ok and tonumber(r)) or n end   -- type d'économie du serveur (pickax_economy, optionnel)
ESX = exports['es_extended']:getSharedObject()

IB = {
    Entities = {},   -- [id] = { id, type, name, label, enabled, settings, points, stats }
    ByName = {},     -- [name] = id
    Dirty = {},      -- [id] = true : stats à écrire en base
    State = {},      -- cooldowns persistants [clé] = timestamp de fin
    Pending = {},    -- [src] = action en cours (récolte, fabrication, braquage...)
    Counters = {},   -- compteurs horaires [clé] = { n, since }
    ready = false,
}

-- ─────────────────────────────── Helpers ───────────────────────────────
function IB.decode(str, default)
    if not str or str == '' then return default end
    local ok, res = pcall(json.decode, str)
    if ok and res ~= nil then return res end
    return default
end

function IB.flag(v) return v == 1 or v == true or v == '1' end

function IB.isAdmin(src)
    if src == 0 then return true end
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        local g = xPlayer.getGroup()
        for _, allowed in ipairs(Config.AllowedGroups) do
            if g == allowed then return true end
        end
    end
    return Config.AcePermission and Config.AcePermission ~= '' and IsPlayerAceAllowed(src, Config.AcePermission) or false
end

function IB.playerName(xPlayer)
    return xPlayer.getName and xPlayer.getName() or GetPlayerName(xPlayer.source)
end

function IB.notify(src, msg, kind)
    TriggerClientEvent('illegalbuilder:client:notify', src, msg, kind or 'info')
end

function IB.inventory()
    if Config.Inventory == 'ox' then return 'ox' end
    if Config.Inventory == 'esx' then return 'esx' end
    return GetResourceState('ox_inventory') == 'started' and 'ox' or 'esx'
end

function IB.distanceTo(src, c)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return 9999.0 end
    local p = GetEntityCoords(ped)
    return #(vector3(p.x, p.y, p.z) - vector3(c.x, c.y, c.z))
end

function IB.near(src, c, extra)
    return c and c.x ~= nil and IB.distanceTo(src, c) <= (Config.ServerDistance + (extra or 0))
end

-- Un véhicule portant cette plaque existe-t-il dans le monde ? (anti-abus des événements « échec de sortie »)
function IB.plateInWorld(plate)
    plate = tostring(plate or ''):gsub('^%s+', ''):gsub('%s+$', '')
    for _, veh in ipairs(GetAllVehicles()) do
        if DoesEntityExist(veh) and tostring(GetVehicleNumberPlateText(veh) or ''):gsub('^%s+', ''):gsub('%s+$', '') == plate then return true end
    end
    return false
end

function IB.entityCount()
    local n = 0
    for _ in pairs(IB.Entities) do n = n + 1 end
    return n
end

function IB.log(e, xPlayer, action, detail, amount)
    local label = e and e.label or '—'
    MySQL.insert('INSERT INTO illegalbuilder_logs (entity_id, entity_label, type, identifier, player_name, action, detail, amount) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        e and e.id or 0, label, e and e.type or nil, xPlayer and xPlayer.identifier or nil, xPlayer and IB.playerName(xPlayer) or 'système',
        action, detail and tostring(detail):sub(1, 255) or nil, math.floor(tonumber(amount) or 0),
    })
    if Config.Webhook and Config.Webhook ~= '' then
        PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode({
            username = 'IllegalBuilder',
            embeds = {{ title = ('[%s] %s'):format(label, action), description = ('%s\n%s'):format(xPlayer and IB.playerName(xPlayer) or 'système', detail or ''), color = 3447003 }},
        }), { ['Content-Type'] = 'application/json' })
    end
end

-- Statistiques d'un module (compteurs libres), écrites par lots
function IB.stat(e, key, amount)
    if not e then return end
    e.stats = e.stats or {}
    e.stats[key] = (e.stats[key] or 0) + (amount or 1)
    IB.Dirty[e.id] = true
end

-- ─────────────────────────────── Base de données ───────────────────────────────
local function installTables()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/install.sql')
    if not sql then return end -- tables déjà créées par database.sql
    sql = sql:gsub('%-%-[^\n]*', '')
    for stmt in sql:gmatch('[^;]+') do
        if stmt:match('%S') then MySQL.query.await(stmt) end
    end
end

-- Reprise des drogues / braquages créés avant la séparation (ils étaient dans le World Builder) : copiés une seule fois, puis retirés de l'ancien builder
local function migrateFromWorldBuilder()
    local ok, err = pcall(function()
        local has = MySQL.scalar.await("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'worldbuilder_entities'")
        if (tonumber(has) or 0) == 0 then return end
        local rows = MySQL.query.await("SELECT * FROM worldbuilder_entities WHERE type IN ('drug', 'robbery')") or {}
        if #rows == 0 then return end
        local n = 0
        for _, r in ipairs(rows) do
            MySQL.insert.await('INSERT IGNORE INTO illegalbuilder_entities (id, type, name, label, enabled, settings, points, stats, created_by, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                { r.id, r.type, r.name, r.label, r.enabled, r.settings, r.points, r.stats, r.created_by, r.created_at })
            if MySQL.scalar.await('SELECT 1 FROM illegalbuilder_entities WHERE name = ?', { r.name }) then
                MySQL.update.await('DELETE FROM worldbuilder_entities WHERE id = ?', { r.id })
                n = n + 1
            end
        end
        print(('^2[illegalbuilder] %d module(s) drogue / braquage repris depuis le World Builder.^0'):format(n))
    end)
    if not ok then print('^1[illegalbuilder] reprise depuis le World Builder impossible : ' .. tostring(err) .. '^0') end
end

function IB.loadAll()
    IB.Entities, IB.ByName = {}, {}
    for _, r in ipairs(MySQL.query.await('SELECT * FROM illegalbuilder_entities ORDER BY id') or {}) do
        r.enabled = IB.flag(r.enabled)
        r.settings = IB.decode(r.settings, {})
        r.points = IB.decode(r.points, {})
        r.stats = IB.decode(r.stats, {})
        IB.Entities[r.id] = r
        IB.ByName[r.name] = r.id
    end
    IB.State = {}
    for _, r in ipairs(MySQL.query.await('SELECT k, v FROM illegalbuilder_state') or {}) do IB.State[r.k] = tonumber(r.v) or 0 end
end

function IB.save(e)
    MySQL.update.await('UPDATE illegalbuilder_entities SET label = ?, type = ?, enabled = ?, settings = ?, points = ?, stats = ? WHERE id = ?', {
        e.label, e.type, e.enabled and 1 or 0, json.encode(e.settings), json.encode(e.points), json.encode(e.stats or {}), e.id,
    })
    IB.Dirty[e.id] = nil
end

function IB.flush()
    for id in pairs(IB.Dirty) do
        local e = IB.Entities[id]
        if e then MySQL.update('UPDATE illegalbuilder_entities SET stats = ? WHERE id = ?', { json.encode(e.stats or {}), id }) end
        IB.Dirty[id] = nil
    end
end

CreateThread(function()
    while true do
        Wait(30000)
        if IB.ready then IB.flush() end
    end
end)

function IB.setState(key, value)
    IB.State[key] = value
    MySQL.update('INSERT INTO illegalbuilder_state (k, v) VALUES (?, ?) ON DUPLICATE KEY UPDATE v = VALUES(v)', { key, value })
end

-- Compteur glissant (ex : quantité vendue par heure et par joueur). Retourne la valeur AVANT ajout.
function IB.counter(key, window)
    local c = IB.Counters[key]
    local now = os.time()
    if not c or now - c.since >= window then c = { n = 0, since = now } IB.Counters[key] = c end
    return c
end

-- ─────────────────────────────── Réglages (apparence) ───────────────────────────────
function IB.loadSettings()
    local ps = MySQL.scalar.await("SELECT v FROM illegalbuilder_settings WHERE k = 'pedsales'")
    if ps ~= nil then Config.PedSales.Enabled = tostring(ps) ~= '0' end
    local r = MySQL.scalar.await("SELECT v FROM illegalbuilder_settings WHERE k = 'accent'")
    local acc = IB.decode(r, nil)
    if type(acc) == 'table' and #acc == 3 then Config.UI.Accent = { tonumber(acc[1]) or 239, tonumber(acc[2]) or 68, tonumber(acc[3]) or 68 } end
end

-- ─────────────────────────────── Inventaire ───────────────────────────────
local catalogCache, catalogAt, itemSet = nil, 0, nil

function IB.itemCatalog()
    if catalogCache and GetGameTimer() - catalogAt < 60000 then return catalogCache end
    local list, seen = {}, {}
    local function add(name, label)
        if type(name) ~= 'string' or name == '' then return end
        local k = name:lower()
        if seen[k] then return end
        seen[k] = true
        list[#list + 1] = { name = name, label = (type(label) == 'string' and label ~= '') and label or name }
    end
    if IB.inventory() == 'ox' then
        local ok, items = pcall(function() return exports.ox_inventory:Items() end)
        if ok and type(items) == 'table' then for name, it in pairs(items) do add(it.name or name, it.label) end end
    else
        if type(ESX.Items) == 'table' then for name, it in pairs(ESX.Items) do add(name, it.label) end end
        if #list == 0 then
            for _, r in ipairs(MySQL.query.await('SELECT name, label FROM items') or {}) do add(r.name, r.label) end
        end
        pcall(function() for _, w in ipairs(ESX.GetWeaponList()) do add(w.name, w.label) end end)
    end
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    catalogCache, catalogAt, itemSet = list, GetGameTimer(), seen
    return list
end

function IB.itemExists(name)
    IB.itemCatalog()
    return itemSet and itemSet[tostring(name):lower()] == true
end

AddEventHandler('onResourceStart', function(res)
    if res == 'ox_inventory' or res == 'es_extended' then catalogCache = nil end
end)

function IB.itemCount(src, name)
    if not name or name == '' then return 0 end
    if IB.inventory() == 'ox' then return exports.ox_inventory:GetItemCount(src, name) or 0 end
    local x = ESX.GetPlayerFromId(src)
    local it = x and x.getInventoryItem(name)
    return it and it.count or 0
end

function IB.canCarry(src, name, count)
    if IB.inventory() == 'ox' then return exports.ox_inventory:CanCarryItem(src, name, count) and true or false end
    local x = ESX.GetPlayerFromId(src)
    if not x then return false end
    if x.canCarryItem then return x.canCarryItem(name, count) end
    return true
end

function IB.addItem(src, name, count)
    count = math.floor(tonumber(count) or 0)
    if count <= 0 then return true end
    if IB.inventory() == 'ox' then
        if not exports.ox_inventory:CanCarryItem(src, name, count) then return false end
        return exports.ox_inventory:AddItem(src, name, count) and true or false
    end
    local x = ESX.GetPlayerFromId(src)
    if not x then return false end
    if name:find('^WEAPON_') then x.addWeapon(name, 0) return true end
    if x.canCarryItem and not x.canCarryItem(name, count) then return false end
    x.addInventoryItem(name, count)
    return true
end

function IB.removeItem(src, name, count)
    count = math.floor(tonumber(count) or 0)
    if count <= 0 then return true end
    if IB.itemCount(src, name) < count then return false end
    if IB.inventory() == 'ox' then return exports.ox_inventory:RemoveItem(src, name, count) and true or false end
    local x = ESX.GetPlayerFromId(src)
    if not x then return false end
    x.removeInventoryItem(name, count)
    return true
end

-- ─────────────────────────────── Argent ───────────────────────────────
function IB.balance(xPlayer, method)
    local p = Config.Payments[method]
    if not p then return 0 end
    local acc = xPlayer.getAccount(p.account)
    return acc and acc.money or 0
end

-- Paiement : le moyen doit être autorisé par le module (payments = { cash = true, ... })
function IB.charge(xPlayer, allowed, method, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end
    local p = Config.Payments[method]
    if not p or not allowed or allowed[method] ~= true then return false, 'Moyen de paiement refusé' end
    if IB.balance(xPlayer, method) < amount then return false, 'Fonds insuffisants' end
    xPlayer.removeAccountMoney(p.account, amount, reason)
    return true
end

function IB.pay(xPlayer, account, amount, reason)
    amount = ECO('income', math.floor(tonumber(amount) or 0))
    if amount > 0 then xPlayer.addAccountMoney(account, amount, reason) end
end

-- Crédite un compte société (esx_addonaccount ou CorePickax, qui le fournit sur ce serveur). 1) pont AddSharedMoney (solde en mémoire partagé avec esx_society / jobbuilder)
-- 2) événement esx_addonaccount:getSharedAccount 3) repli SQL direct sur addon_account_data
function IB.society(name, amount)
    amount = math.floor(tonumber(amount) or 0)
    if not name or name == '' or amount <= 0 then return end
    for _, host in ipairs({ 'pickax_core', 'esx_addonaccount' }) do
        if GetResourceState(host) == 'started' then
            local ok, res = pcall(function() return exports[host]:AddSharedMoney(name, amount) end)
            if ok and res then return true end
        end
    end
    local done = false
    pcall(function() TriggerEvent('esx_addonaccount:getSharedAccount', name, function(acc) if acc and acc.addMoney then acc.addMoney(amount) done = true end end) end)
    if done then return true end
    MySQL.update('UPDATE addon_account_data SET money = money + ? WHERE account_name = ? AND owner IS NULL', { amount, name })
    return true
end

function IB.paymentsList(allowed, xPlayer)
    local list = {}
    for id, p in pairs(Config.Payments) do
        if allowed and allowed[id] == true then list[#list + 1] = { id = id, label = p.label, balance = IB.balance(xPlayer, id) } end
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

-- ─────────────────────────────── Accès / police ───────────────────────────────
function IB.jobAllowed(xPlayer, jobs)
    if not jobs or not next(jobs) then return true end
    local g = jobs[xPlayer.job.name]
    return g ~= nil and xPlayer.job.grade >= (tonumber(g) or 0)
end

-- access = { jobs = { police = 0 }, item = 'cle' } : métier/grade + objet clé (non consommé)
function IB.hasAccess(xPlayer, access)
    if not access then return true end
    if IB.isAdmin(xPlayer.source) and not next(access.jobs or {}) and (access.item or '') == '' then return true end
    if not IB.jobAllowed(xPlayer, access.jobs) then return false, 'Accès réservé' end
    if access.item and access.item ~= '' and IB.itemCount(xPlayer.source, access.item) < 1 then return false, 'Il te faut : ' .. access.item end
    return true
end

function IB.isPoliceJob(name)
    for _, j in ipairs(Config.PoliceJobs) do if j == name then return true end end
    return false
end

function IB.copCount()
    local n = 0
    for _, id in ipairs(GetPlayers()) do
        local x = ESX.GetPlayerFromId(tonumber(id))
        if x and IB.isPoliceJob(x.job.name) then n = n + 1 end
    end
    return n
end

function IB.alertPolice(coords, title, message)
    if Config.AlertHook and Config.AlertHook(coords, title, message) then return end
    -- tablette police du jobbuilder (dispatch) : en plus du blip d'alerte ci-dessous
    if GetResourceState('pickax_jobbuilder') == 'started' then
        pcall(function() exports.pickax_jobbuilder:SendDispatch('police', title, message, coords, 'alert') end)
    end
    for _, id in ipairs(GetPlayers()) do
        local x = ESX.GetPlayerFromId(tonumber(id))
        if x and IB.isPoliceJob(x.job.name) then
            TriggerClientEvent('illegalbuilder:client:alert', x.source, coords, title, message)
        end
    end
end

-- ─────────────────────────────── Actions chronométrées ───────────────────────────────
-- begin → le client joue l'animation/barre de progression → finish. Le serveur refuse un finish prématuré.
function IB.beginAct(src, data, seconds)
    data.src = src
    data.finishAt = GetGameTimer() + math.floor((tonumber(seconds) or 0) * 1000)
    IB.Pending[src] = data
end

function IB.endAct(src, kind)
    local p = IB.Pending[src]
    if not p or p.kind ~= kind then return nil, 'Aucune action en cours' end
    IB.Pending[src] = nil
    if GetGameTimer() < p.finishAt - 1500 then return nil, 'Action trop rapide' end
    return p
end

RegisterNetEvent('illegalbuilder:server:cancelAct', function() IB.Pending[source] = nil end)
AddEventHandler('playerDropped', function() IB.Pending[source] = nil end)

-- ─────────────────────────────── Synchronisation clients ───────────────────────────────
function IB.canSee(e, xPlayer)
    if not e.enabled then return false end
    local jobs = e.settings.access and e.settings.access.jobs
    if jobs and next(jobs) then
        if IB.isAdmin(xPlayer.source) then return true end
        return IB.jobAllowed(xPlayer, jobs)
    end
    return true
end

-- Un dealer est-il utilisable ? (interrupteur général + interrupteur du point)
function IB.sellEnabled(p)
    return Config.PedSales.Enabled ~= false and not (p and p.sell and p.sell.enabled == false)
end

function IB.publicEntity(e)
    local s, pts = e.settings, {}
    for i, p in ipairs(e.points) do
        if p.coords and p.coords.x and p.kind ~= 'process' and (p.kind ~= 'sell' or IB.sellEnabled(p)) then   -- le traitement se fait désormais dans les laboratoires (propriétés, Job Builder)
            pts[#pts + 1] = { i = i, kind = p.kind or 'main', reveal = IB.pointRevealItem and IB.pointRevealItem(p) or nil, outfit = (p.outfit and p.outfit.enabled) and p.outfit or nil,
                plant = (p.harvest and p.harvest.plant and p.harvest.plant.enabled) and p.harvest.plant or nil, label = p.label, coords = p.coords, store = p.store, ret = p.ret, inside = p.inside,
                spawns = p.spawns, ped = p.ped, blip = p.blip, color = p.color, color2 = p.color2, doors = p.doors, useKey = p.useKey, showMarker = p.showMarker, showText = p.showText, desc = p.desc, zone = (p.kind == 'zone') and { radius = p.radius, reviveEnabled = p.reviveEnabled, reviveDelay = p.reviveDelay, giveWeapons = p.giveWeapons, removeOnExit = p.removeOnExit,
                infiniteAmmo = p.infiniteAmmo, armorOnRespawn = p.armorOnRespawn, spawnProtection = p.spawnProtection, weapons = p.weapons, spawns = p.spawns } or nil }
        end
    end
    local gfItem = IB.gofastTabletItem and IB.gofastTabletItem(e) or nil
    local reveal, seen = {}, {}
    if gfItem then reveal[#reveal + 1] = gfItem seen[gfItem] = true end
    for _, pt in ipairs(pts) do if pt.reveal and not seen[pt.reveal] then reveal[#reveal + 1] = pt.reveal seen[pt.reveal] = true end end
    return { revealItems = #reveal > 0 and reveal or nil, gofastItem = gfItem, id = e.id, type = e.type, label = e.label, points = pts, blip = s.blip, color = s.color, uiColor = s.uiColor, marker = s.marker,
        mode = s.mode, trigger = s.trigger, weapon = s.weapon, duration = s.duration }
end

function IB.syncPlayer(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local list = {}
    for _, e in pairs(IB.Entities) do
        if IB.canSee(e, xPlayer) then
            local pub = IB.publicEntity(e)
            -- Go Fast avec tablette : sans la tablette, ni le contact ni les points ne sont envoyés au joueur (il ne sait pas où est le Go Fast)
            if pub.gofastItem and IB.itemCount(src, pub.gofastItem) < 1 then pub.points = {}
            else
                -- points « à tablette » (ex : blanchiment) : retirés tant que le joueur n'a pas l'item
                local keep = {}
                for _, pt in ipairs(pub.points) do if not pt.reveal or IB.itemCount(src, pt.reveal) >= 1 then keep[#keep + 1] = pt end end
                pub.points = keep
            end
            list[#list + 1] = pub
        end
    end
    local st = Config.StreetSales or {}
    TriggerClientEvent('illegalbuilder:client:sync', src, { entities = list, accent = Config.UI.Accent, config = {
        street = { enabled = Config.PedSales.Enabled ~= false and st.Enabled ~= false, tablet = st.RequireTablet and st.TabletItem or nil, items = IB.streetCatalog and IB.streetCatalog() or {} },
        marker = Config.Marker, drawDistance = Config.DrawDistance, interactDistance = Config.InteractDistance, pedDistance = Config.PedDistance,
    } })
    if IB.syncRobberies then IB.syncRobberies(src) end
    if IB.syncPlants then IB.syncPlants(src) end
    if IB.syncDoors then IB.syncDoors(src) end
    if IB.syncListings then IB.syncListings(src) end
end

function IB.syncAll()
    for _, src in ipairs(GetPlayers()) do IB.syncPlayer(tonumber(src)) end
end

AddEventHandler('esx:playerLoaded', function(src) SetTimeout(1500, function() IB.syncPlayer(src) end) end)
AddEventHandler('esx:setJob', function(src) SetTimeout(300, function() IB.syncPlayer(src) end) end)
RegisterNetEvent('illegalbuilder:server:requestSync', function() IB.syncPlayer(source) end)

-- Marker / couleur de base = ceux de pickax_core : on retire une seule fois les anciennes valeurs « par défaut » figées en base
-- (forme 25 ou forme actuelle du core enregistrée sur chaque module, couleur d'interface restée sur l'ancien bleu / turquoise).
local function migrateCoreStyle(settingsTable, entityTable)
    local flag = '_core_style_v2'
    if MySQL.scalar.await(('SELECT 1 FROM %s WHERE k = ?'):format(settingsTable), { flag }) then return end
    local acc = json.decode(MySQL.scalar.await(('SELECT v FROM %s WHERE k = ?'):format(settingsTable), { 'accent' }) or 'null')
    if type(acc) == 'table' and ((acc[1] == 0 and acc[2] == 164 and acc[3] == 255) or (acc[1] == 64 and acc[2] == 224 and acc[3] == 208)) then
        MySQL.update.await(('DELETE FROM %s WHERE k = ?'):format(settingsTable), { 'accent' })
    end
    local n = 0
    for _, r in ipairs(MySQL.query.await(('SELECT id, settings FROM %s'):format(entityTable)) or {}) do
        local s = json.decode(r.settings or '{}')
        local t = type(s) == 'table' and type(s.marker) == 'table' and tonumber(s.marker.type)
        if t and (t == 25 or t == (Config.Marker and Config.Marker.type)) then
            s.marker.type = nil
            MySQL.update.await(('UPDATE %s SET settings = ? WHERE id = ?'):format(entityTable), { json.encode(s), r.id })
            n = n + 1
        end
    end
    MySQL.update.await(('INSERT INTO %s (k, v) VALUES (?, ?) ON DUPLICATE KEY UPDATE v = VALUES(v)'):format(settingsTable), { flag, '1' })
    if n > 0 then print(('^2[%s] %d module(s) : marker de base remis sur celui de pickax_core.^0'):format(GetCurrentResourceName(), n)) end
end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    installTables()
    migrateCoreStyle('illegalbuilder_settings', 'illegalbuilder_entities')
    migrateFromWorldBuilder()
    IB.loadAll()
    IB.loadSettings()
    IB.ready = true
    if IB.onReady then IB.onReady() end
    SetTimeout(1000, IB.syncAll)
    print(('^2[illegalbuilder] %d module(s) chargé(s).^0'):format(IB.entityCount()))
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for id in pairs(IB.Dirty) do
        local e = IB.Entities[id]
        if e then MySQL.update.await('UPDATE illegalbuilder_entities SET stats = ? WHERE id = ?', { json.encode(e.stats or {}), id }) end
    end
end)

-- /illegalbuilder : ouvre le builder (droits vérifiés ici ET à chaque action)
RegisterCommand(Config.Command, function(src)
    if src == 0 then print('[illegalbuilder] commande disponible en jeu uniquement') return end
    if not IB.isAdmin(src) then
        IB.notify(src, 'Tu n\'as pas la permission d\'utiliser le Builder Illégal.', 'error')
        return
    end
    TriggerClientEvent('illegalbuilder:client:openBuilder', src)
end, false)
