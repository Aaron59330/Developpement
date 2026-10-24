ESX = exports['es_extended']:getSharedObject()

WB = {
    Entities = {},   -- [id] = { id, type, name, label, enabled, settings, points, stats }
    ByName = {},     -- [name] = id
    Dirty = {},      -- [id] = true : stats à écrire en base
    State = {},      -- cooldowns persistants [clé] = timestamp de fin
    Pending = {},    -- [src] = action en cours (récolte, fabrication, braquage...)
    Counters = {},   -- compteurs horaires [clé] = { n, since }
    ready = false,
}

-- ─────────────────────────────── Helpers ───────────────────────────────
function WB.decode(str, default)
    if not str or str == '' then return default end
    local ok, res = pcall(json.decode, str)
    if ok and res ~= nil then return res end
    return default
end

function WB.flag(v) return v == 1 or v == true or v == '1' end

function WB.isAdmin(src)
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

function WB.playerName(xPlayer)
    return xPlayer.getName and xPlayer.getName() or GetPlayerName(xPlayer.source)
end

function WB.notify(src, msg, kind)
    TriggerClientEvent('worldbuilder:client:notify', src, msg, kind or 'info')
end

function WB.inventory()
    if Config.Inventory == 'ox' then return 'ox' end
    if Config.Inventory == 'esx' then return 'esx' end
    return GetResourceState('ox_inventory') == 'started' and 'ox' or 'esx'
end

function WB.distanceTo(src, c)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return 9999.0 end
    local p = GetEntityCoords(ped)
    return #(vector3(p.x, p.y, p.z) - vector3(c.x, c.y, c.z))
end

function WB.near(src, c, extra)
    return c and c.x ~= nil and WB.distanceTo(src, c) <= (Config.ServerDistance + (extra or 0))
end

-- Un véhicule portant cette plaque existe-t-il dans le monde ? (anti-abus des événements « échec de sortie »)
function WB.plateInWorld(plate)
    plate = tostring(plate or ''):gsub('^%s+', ''):gsub('%s+$', '')
    for _, veh in ipairs(GetAllVehicles()) do
        if DoesEntityExist(veh) and tostring(GetVehicleNumberPlateText(veh) or ''):gsub('^%s+', ''):gsub('%s+$', '') == plate then return true end
    end
    return false
end

function WB.entityCount()
    local n = 0
    for _ in pairs(WB.Entities) do n = n + 1 end
    return n
end

function WB.log(e, xPlayer, action, detail, amount)
    local label = e and e.label or '—'
    MySQL.insert('INSERT INTO worldbuilder_logs (entity_id, entity_label, type, identifier, player_name, action, detail, amount) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        e and e.id or 0, label, e and e.type or nil, xPlayer and xPlayer.identifier or nil, xPlayer and WB.playerName(xPlayer) or 'système',
        action, detail and tostring(detail):sub(1, 255) or nil, math.floor(tonumber(amount) or 0),
    })
    if Config.Webhook and Config.Webhook ~= '' then
        PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode({
            username = 'WorldBuilder',
            embeds = {{ title = ('[%s] %s'):format(label, action), description = ('%s\n%s'):format(xPlayer and WB.playerName(xPlayer) or 'système', detail or ''), color = 3447003 }},
        }), { ['Content-Type'] = 'application/json' })
    end
end

-- Statistiques d'un module (compteurs libres), écrites par lots
function WB.stat(e, key, amount)
    if not e then return end
    e.stats = e.stats or {}
    e.stats[key] = (e.stats[key] or 0) + (amount or 1)
    WB.Dirty[e.id] = true
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

function WB.loadAll()
    WB.Entities, WB.ByName = {}, {}
    for _, r in ipairs(MySQL.query.await("SELECT * FROM worldbuilder_entities WHERE type NOT IN ('drug', 'robbery') ORDER BY id") or {}) do
        r.enabled = WB.flag(r.enabled)
        r.settings = WB.decode(r.settings, {})
        r.points = WB.decode(r.points, {})
        r.stats = WB.decode(r.stats, {})
        WB.Entities[r.id] = r
        WB.ByName[r.name] = r.id
    end
    WB.State = {}
    for _, r in ipairs(MySQL.query.await('SELECT k, v FROM worldbuilder_state') or {}) do WB.State[r.k] = tonumber(r.v) or 0 end
end

function WB.save(e)
    MySQL.update.await('UPDATE worldbuilder_entities SET label = ?, type = ?, enabled = ?, settings = ?, points = ?, stats = ? WHERE id = ?', {
        e.label, e.type, e.enabled and 1 or 0, json.encode(e.settings), json.encode(e.points), json.encode(e.stats or {}), e.id,
    })
    WB.Dirty[e.id] = nil
end

function WB.flush()
    for id in pairs(WB.Dirty) do
        local e = WB.Entities[id]
        if e then MySQL.update('UPDATE worldbuilder_entities SET stats = ? WHERE id = ?', { json.encode(e.stats or {}), id }) end
        WB.Dirty[id] = nil
    end
end

CreateThread(function()
    while true do
        Wait(30000)
        if WB.ready then WB.flush() end
    end
end)

function WB.setState(key, value)
    WB.State[key] = value
    MySQL.update('INSERT INTO worldbuilder_state (k, v) VALUES (?, ?) ON DUPLICATE KEY UPDATE v = VALUES(v)', { key, value })
end

-- Compteur glissant (ex : quantité vendue par heure et par joueur). Retourne la valeur AVANT ajout.
function WB.counter(key, window)
    local c = WB.Counters[key]
    local now = os.time()
    if not c or now - c.since >= window then c = { n = 0, since = now } WB.Counters[key] = c end
    return c
end

-- ─────────────────────────────── Réglages (apparence) ───────────────────────────────
function WB.loadSettings()
    local r = MySQL.scalar.await("SELECT v FROM worldbuilder_settings WHERE k = 'accent'")
    local acc = WB.decode(r, nil)
    if type(acc) == 'table' and #acc == 3 then Config.UI.Accent = { tonumber(acc[1]) or 239, tonumber(acc[2]) or 68, tonumber(acc[3]) or 68 } end
end

-- ─────────────────────────────── Inventaire ───────────────────────────────
local catalogCache, catalogAt, itemSet = nil, 0, nil

function WB.itemCatalog()
    if catalogCache and GetGameTimer() - catalogAt < 60000 then return catalogCache end
    local list, seen = {}, {}
    local function add(name, label)
        if type(name) ~= 'string' or name == '' then return end
        local k = name:lower()
        if seen[k] then return end
        seen[k] = true
        list[#list + 1] = { name = name, label = (type(label) == 'string' and label ~= '') and label or name }
    end
    if WB.inventory() == 'ox' then
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

function WB.itemExists(name)
    WB.itemCatalog()
    return itemSet and itemSet[tostring(name):lower()] == true
end

AddEventHandler('onResourceStart', function(res)
    if res == 'ox_inventory' or res == 'es_extended' then catalogCache = nil end
end)

function WB.itemCount(src, name)
    if not name or name == '' then return 0 end
    if WB.inventory() == 'ox' then return exports.ox_inventory:GetItemCount(src, name) or 0 end
    local x = ESX.GetPlayerFromId(src)
    local it = x and x.getInventoryItem(name)
    return it and it.count or 0
end

function WB.canCarry(src, name, count)
    if WB.inventory() == 'ox' then return exports.ox_inventory:CanCarryItem(src, name, count) and true or false end
    local x = ESX.GetPlayerFromId(src)
    if not x then return false end
    if x.canCarryItem then return x.canCarryItem(name, count) end
    return true
end

function WB.addItem(src, name, count)
    count = math.floor(tonumber(count) or 0)
    if count <= 0 then return true end
    if WB.inventory() == 'ox' then
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

function WB.removeItem(src, name, count)
    count = math.floor(tonumber(count) or 0)
    if count <= 0 then return true end
    if WB.itemCount(src, name) < count then return false end
    if WB.inventory() == 'ox' then return exports.ox_inventory:RemoveItem(src, name, count) and true or false end
    local x = ESX.GetPlayerFromId(src)
    if not x then return false end
    x.removeInventoryItem(name, count)
    return true
end

-- ─────────────────────────────── Argent ───────────────────────────────
function WB.balance(xPlayer, method)
    local p = Config.Payments[method]
    if not p then return 0 end
    local acc = xPlayer.getAccount(p.account)
    return acc and acc.money or 0
end

-- Paiement : le moyen doit être autorisé par le module (payments = { cash = true, ... })
function WB.charge(xPlayer, allowed, method, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end
    local p = Config.Payments[method]
    if not p or not allowed or allowed[method] ~= true then return false, 'Moyen de paiement refusé' end
    if WB.balance(xPlayer, method) < amount then return false, 'Fonds insuffisants' end
    xPlayer.removeAccountMoney(p.account, amount, reason)
    return true
end

function WB.pay(xPlayer, account, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount > 0 then xPlayer.addAccountMoney(account, amount, reason) end
end

-- Crédite un compte société (esx_addonaccount ou CorePickax, qui le fournit sur ce serveur). 1) pont AddSharedMoney (solde en mémoire partagé avec esx_society / jobbuilder)
-- 2) événement esx_addonaccount:getSharedAccount 3) repli SQL direct sur addon_account_data
function WB.society(name, amount)
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

function WB.paymentsList(allowed, xPlayer)
    local list = {}
    for id, p in pairs(Config.Payments) do
        if allowed and allowed[id] == true then list[#list + 1] = { id = id, label = p.label, balance = WB.balance(xPlayer, id) } end
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

-- ─────────────────────────────── Accès / police ───────────────────────────────
function WB.jobAllowed(xPlayer, jobs)
    if not jobs or not next(jobs) then return true end
    local g = jobs[xPlayer.job.name]
    return g ~= nil and xPlayer.job.grade >= (tonumber(g) or 0)
end

-- access = { jobs = { police = 0 }, item = 'cle' } : métier/grade + objet clé (non consommé)
function WB.hasAccess(xPlayer, access)
    if not access then return true end
    if WB.isAdmin(xPlayer.source) and not next(access.jobs or {}) and (access.item or '') == '' then return true end
    if not WB.jobAllowed(xPlayer, access.jobs) then return false, 'Accès réservé' end
    if access.item and access.item ~= '' and WB.itemCount(xPlayer.source, access.item) < 1 then return false, 'Il te faut : ' .. access.item end
    return true
end

function WB.isPoliceJob(name)
    for _, j in ipairs(Config.PoliceJobs) do if j == name then return true end end
    return false
end

function WB.copCount()
    local n = 0
    for _, id in ipairs(GetPlayers()) do
        local x = ESX.GetPlayerFromId(tonumber(id))
        if x and WB.isPoliceJob(x.job.name) then n = n + 1 end
    end
    return n
end

function WB.alertPolice(coords, title, message)
    if Config.AlertHook and Config.AlertHook(coords, title, message) then return end
    -- tablette police du jobbuilder (dispatch) : en plus du blip d'alerte ci-dessous
    if GetResourceState('pickax_jobbuilder') == 'started' then
        pcall(function() exports.pickax_jobbuilder:SendDispatch('police', title, message, coords, 'alert') end)
    end
    for _, id in ipairs(GetPlayers()) do
        local x = ESX.GetPlayerFromId(tonumber(id))
        if x and WB.isPoliceJob(x.job.name) then
            TriggerClientEvent('worldbuilder:client:alert', x.source, coords, title, message)
        end
    end
end

-- ─────────────────────────────── Actions chronométrées ───────────────────────────────
-- begin → le client joue l'animation/barre de progression → finish. Le serveur refuse un finish prématuré.
function WB.beginAct(src, data, seconds)
    data.src = src
    data.finishAt = GetGameTimer() + math.floor((tonumber(seconds) or 0) * 1000)
    WB.Pending[src] = data
end

function WB.endAct(src, kind)
    local p = WB.Pending[src]
    if not p or p.kind ~= kind then return nil, 'Aucune action en cours' end
    WB.Pending[src] = nil
    if GetGameTimer() < p.finishAt - 1500 then return nil, 'Action trop rapide' end
    return p
end

RegisterNetEvent('worldbuilder:server:cancelAct', function() WB.Pending[source] = nil end)
AddEventHandler('playerDropped', function() WB.Pending[source] = nil end)

-- ─────────────────────────────── Synchronisation clients ───────────────────────────────
function WB.canSee(e, xPlayer)
    if not e.enabled then return false end
    local jobs = e.settings.access and e.settings.access.jobs
    if jobs and next(jobs) then
        if WB.isAdmin(xPlayer.source) then return true end
        return WB.jobAllowed(xPlayer, jobs)
    end
    return true
end

function WB.publicEntity(e)
    local s, pts = e.settings, {}
    for i, p in ipairs(e.points) do
        if p.coords and p.coords.x then
            pts[#pts + 1] = { i = i, kind = p.kind or 'main', label = p.label, coords = p.coords, store = p.store, ret = p.ret, inside = p.inside,
                spawns = p.spawns, ped = p.ped, blip = p.blip, color = p.color, color2 = p.color2, doors = p.doors, useKey = p.useKey, showMarker = p.showMarker, showText = p.showText, desc = p.desc, zone = (p.kind == 'zone') and { radius = p.radius, reviveEnabled = p.reviveEnabled, reviveDelay = p.reviveDelay, giveWeapons = p.giveWeapons, removeOnExit = p.removeOnExit,
                infiniteAmmo = p.infiniteAmmo, armorOnRespawn = p.armorOnRespawn, spawnProtection = p.spawnProtection, weapons = p.weapons, spawns = p.spawns } or nil }
        end
    end
    return { id = e.id, type = e.type, label = e.label, points = pts, blip = s.blip, color = s.color, uiColor = s.uiColor, marker = s.marker,
        mode = s.mode, trigger = s.trigger, weapon = s.weapon, duration = s.duration }
end

function WB.syncPlayer(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local list = {}
    for _, e in pairs(WB.Entities) do
        if WB.canSee(e, xPlayer) then list[#list + 1] = WB.publicEntity(e) end
    end
    TriggerClientEvent('worldbuilder:client:sync', src, { entities = list, accent = Config.UI.Accent, config = {
        marker = Config.Marker, drawDistance = Config.DrawDistance, interactDistance = Config.InteractDistance, pedDistance = Config.PedDistance,
    } })
    if WB.syncDoors then WB.syncDoors(src) end
    if WB.syncListings then WB.syncListings(src) end
end

function WB.syncAll()
    for _, src in ipairs(GetPlayers()) do WB.syncPlayer(tonumber(src)) end
end

AddEventHandler('esx:playerLoaded', function(src) SetTimeout(1500, function() WB.syncPlayer(src) end) end)
AddEventHandler('esx:setJob', function(src) SetTimeout(300, function() WB.syncPlayer(src) end) end)
RegisterNetEvent('worldbuilder:server:requestSync', function() WB.syncPlayer(source) end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    installTables()
    WB.loadAll()
    WB.loadSettings()
    WB.ready = true
    if WB.onReady then WB.onReady() end
    SetTimeout(1000, WB.syncAll)
    print(('^2[worldbuilder] %d module(s) chargé(s).^0'):format(WB.entityCount()))
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for id in pairs(WB.Dirty) do
        local e = WB.Entities[id]
        if e then MySQL.update.await('UPDATE worldbuilder_entities SET stats = ? WHERE id = ?', { json.encode(e.stats or {}), id }) end
    end
end)

-- /worldbuilder : ouvre le builder (droits vérifiés ici ET à chaque action)
RegisterCommand(Config.Command, function(src)
    if src == 0 then print('[worldbuilder] commande disponible en jeu uniquement') return end
    if not WB.isAdmin(src) then
        WB.notify(src, 'Tu n\'as pas la permission d\'utiliser le World Builder.', 'error')
        return
    end
    TriggerClientEvent('worldbuilder:client:openBuilder', src)
end, false)
