ESX = exports['es_extended']:getSharedObject()

GB = {
    Gangs       = {},   -- [name] = ligne gangbuilder_gangs + .grades (lues dans job2_grades)
    Points      = {},   -- [id]   = ligne gangbuilder_points
    Territories = {},   -- [id]   = ligne gangbuilder_territories
    PlayerGang  = {},   -- [src]  = { name, grade } : cache (territoires, salaires) — les contrôles sensibles relisent toujours le job2
    Active      = {},   -- [src]  = activité en cours (récolte, traitement, blanchiment)
    ready       = false,
}

-- ─────────────────────────────── Helpers ───────────────────────────────
function GB.decode(str, default)
    if not str or str == '' then return default end
    local ok, res = pcall(json.decode, str)
    if ok and res ~= nil then return res end
    return default
end

-- Les colonnes tinyint(1) reviennent en 1/0 ou en true/false selon la version d'oxmysql : on accepte les deux
function GB.flag(v) return v == 1 or v == true or v == '1' end

-- Identifiant SQL (table / colonne) : lettres, chiffres et _ uniquement, sinon on refuse (jamais d'injection via la config)
function GB.id(s)
    s = tostring(s or '')
    if not s:match('^[%w_]+$') then error(('[gangbuilder] identifiant SQL invalide dans config.lua : « %s »'):format(s)) end
    return '`' .. s .. '`'
end

function GB.isDev(src)
    if src == 0 then return true end
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        for _, g in ipairs(Config.AllowedGroups) do
            if xPlayer.getGroup() == g then return true end
        end
    end
    if Config.AcePermission and Config.AcePermission ~= '' and IsPlayerAceAllowed(src, Config.AcePermission) then
        return true
    end
    return false
end

function GB.playerName(xPlayer)
    return xPlayer.getName and xPlayer.getName() or GetPlayerName(xPlayer.source)
end

function GB.inventory()
    if Config.Inventory == 'ox' then return 'ox' end
    if Config.Inventory == 'esx' then return 'esx' end
    return GetResourceState('ox_inventory') == 'started' and 'ox' or 'esx'
end

function GB.notify(src, message)
    if not src or src == 0 then return end
    pcall(Config.Hooks.Notify, src, message)
end

function GB.log(gangName, xPlayer, action, detail)
    MySQL.insert('INSERT INTO gangbuilder_logs (gang_name, identifier, player_name, action, detail) VALUES (?, ?, ?, ?, ?)', {
        gangName, xPlayer and xPlayer.identifier or nil, xPlayer and GB.playerName(xPlayer) or 'système', action, detail and tostring(detail):sub(1, 255) or nil,
    })
    if GetResourceState('pickax_dlogs') == 'started' and gangName then
        local g = GB.Gangs and GB.Gangs[gangName]
        pcall(function()
            exports.pickax_dlogs:Send('gang', gangName, g and g.label or gangName, action,
                xPlayer and { name = GB.playerName(xPlayer), identifier = xPlayer.identifier } or nil, detail)
        end)
    end
end

function GB.distanceTo(src, coords)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return 9999.0 end
    local p = GetEntityCoords(ped)
    return #(vector3(p.x, p.y, p.z) - vector3(coords.x, coords.y, coords.z))
end

function GB.playersClose(a, b, extra)
    local pa, pb = GetPlayerPed(a), GetPlayerPed(b)
    if not pa or pa == 0 or not pb or pb == 0 then return false end
    return #(GetEntityCoords(pa) - GetEntityCoords(pb)) <= Config.TargetDistance + (extra or 2.0)
end

function GB.hexToRgb(hex)
    hex = tostring(hex or '')
    local r, g, b = hex:match('^#(%x%x)(%x%x)(%x%x)$')
    if not r then return { 239, 68, 68 } end
    return { tonumber(r, 16), tonumber(g, 16), tonumber(b, 16) }
end

-- ─────────────────────────────── Inventaire (ox_inventory ou ESX) ───────────────────────────────
function GB.itemCount(src, xPlayer, name)
    if GB.inventory() == 'ox' then
        return tonumber(exports.ox_inventory:GetItemCount(src, name)) or 0
    end
    local it = xPlayer.getInventoryItem(name)
    return it and it.count or 0
end

function GB.canCarry(src, xPlayer, name, count)
    if GB.inventory() == 'ox' then return exports.ox_inventory:CanCarryItem(src, name, count) and true or false end
    return xPlayer.canCarryItem(name, count)
end

function GB.giveItem(src, xPlayer, name, count, metadata)
    if GB.inventory() == 'ox' then
        return exports.ox_inventory:AddItem(src, name, count, metadata) and true or false
    end
    if name:upper():find('^WEAPON_') then
        if xPlayer.hasWeapon(name:upper()) then return false end
        xPlayer.addWeapon(name:upper(), metadata and metadata.ammo or 0)
        return true
    end
    xPlayer.addInventoryItem(name, count)
    return true
end

function GB.takeItem(src, xPlayer, name, count)
    if GB.itemCount(src, xPlayer, name) < count then return false end
    if GB.inventory() == 'ox' then return exports.ox_inventory:RemoveItem(src, name, count) and true or false end
    xPlayer.removeInventoryItem(name, count)
    return true
end

-- ─────────────────────────────── Argent du joueur ───────────────────────────────
function GB.dirtyCount(src, xPlayer)
    if Config.Dirty.Mode == 'item' then return GB.itemCount(src, xPlayer, Config.Dirty.Name) end
    local acc = xPlayer.getAccount(Config.Dirty.Name)
    return acc and math.floor(acc.money) or 0
end

function GB.dirtyAdd(src, xPlayer, amount)
    if Config.Dirty.Mode == 'item' then return GB.giveItem(src, xPlayer, Config.Dirty.Name, amount) end
    xPlayer.addAccountMoney(Config.Dirty.Name, amount)
    return true
end

function GB.dirtyRemove(src, xPlayer, amount)
    if GB.dirtyCount(src, xPlayer) < amount then return false end
    if Config.Dirty.Mode == 'item' then return GB.takeItem(src, xPlayer, Config.Dirty.Name, amount) end
    xPlayer.removeAccountMoney(Config.Dirty.Name, amount)
    return true
end

-- Crédite un compte « dirty » | « money » | « bank »
function GB.credit(src, xPlayer, account, amount)
    if amount <= 0 then return true end
    if account == 'dirty' then return GB.dirtyAdd(src, xPlayer, amount) end
    xPlayer.addAccountMoney(account == 'bank' and 'bank' or 'money', amount)
    return true
end

-- Débite un compte « dirty » | « money » | « bank » (en liquide puis banque si account == 'money')
function GB.debit(src, xPlayer, account, amount)
    if amount <= 0 then return true end
    if account == 'dirty' then return GB.dirtyRemove(src, xPlayer, amount) end
    if account == 'bank' then
        if xPlayer.getAccount('bank').money < amount then return false end
        xPlayer.removeAccountMoney('bank', amount)
        return true
    end
    if xPlayer.getAccount('money').money >= amount then xPlayer.removeAccountMoney('money', amount) return true end
    if xPlayer.getAccount('bank').money >= amount then xPlayer.removeAccountMoney('bank', amount) return true end
    return false
end

-- ─────────────────────────────── Trésorerie du gang (gangbuilder_gangs.money / dirty) ───────────────────────────────
local MONEY_COL = { money = 'money', dirty = 'dirty' }

function GB.treasury(name)
    local row = MySQL.single.await('SELECT money, dirty, rep FROM gangbuilder_gangs WHERE name = ?', { name })
    if not row then return 0, 0, 0 end
    return math.floor(tonumber(row.money) or 0), math.floor(tonumber(row.dirty) or 0), math.floor(tonumber(row.rep) or 0)
end

-- Pousse les soldes aux membres connectés (l'interface ouverte se met à jour sans rien rouvrir)
function GB.pushMoney(name)
    local money, dirty = GB.treasury(name)
    for _, src in ipairs(GB.onlineMembers and GB.onlineMembers(name) or {}) do
        TriggerClientEvent('gangbuilder:client:money', src, name, money, dirty)
    end
    return money, dirty
end

function GB.treasuryAdd(name, kind, amount)
    amount = math.floor(tonumber(amount) or 0)
    local col = MONEY_COL[kind]
    if amount <= 0 or not col then return false end
    local n = MySQL.update.await(('UPDATE gangbuilder_gangs SET %s = %s + ? WHERE name = ?'):format(col, col), { amount, name }) or 0
    if n > 0 then GB.pushMoney(name) end
    return n > 0
end

function GB.treasuryRemove(name, kind, amount)
    amount = math.floor(tonumber(amount) or 0)
    local col = MONEY_COL[kind]
    if amount <= 0 or not col then return false end
    local n = MySQL.update.await(('UPDATE gangbuilder_gangs SET %s = %s - ? WHERE name = ? AND %s >= ?'):format(col, col, col), { amount, name, amount }) or 0
    if n > 0 then GB.pushMoney(name) end
    return n > 0
end

function GB.addRep(name, amount)
    amount = math.floor(tonumber(amount) or 0)
    if not Config.Rep.Enabled or amount <= 0 then return end
    MySQL.update('UPDATE gangbuilder_gangs SET rep = rep + ? WHERE name = ?', { amount, name })
    if GB.seasonAdd then GB.seasonAdd(name, amount) end     -- la réputation gagnée compte pour le classement de la saison
end

-- Statistiques par membre (récolté, fabriqué, vendu, blanchi) — alimente la fiche du gang
function GB.stat(identifier, gangName, field, amount)
    if not identifier or amount <= 0 then return end
    local cols = { harvested = true, processed = true, sold = true, laundered = true, contribution = true }
    if not cols[field] then return end
    if field ~= 'contribution' and GB.questProgress then GB.questProgress(gangName, field, amount) end
    MySQL.update(('INSERT INTO gangbuilder_stats (identifier, gang_name, %s) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE %s = %s + VALUES(%s)'):format(field, field, field, field),
        { identifier, gangName, math.floor(amount) })
end

-- API pour les autres scripts
exports('GetGangMoney', function(gang, kind) local m, d = GB.treasury(tostring(gang)) return kind == 'dirty' and d or m end)
exports('AddGangMoney', function(gang, amount, kind) return GB.treasuryAdd(tostring(gang), kind == 'dirty' and 'dirty' or 'money', amount) end)
exports('RemoveGangMoney', function(gang, amount, kind) return GB.treasuryRemove(tostring(gang), kind == 'dirty' and 'dirty' or 'money', amount) end)
exports('AddGangRep', function(gang, amount) GB.addRep(tostring(gang), amount) end)
exports('GetPlayerGang', function(src) local n, g = GB.job2Of(src) return n and GB.Gangs[n] and { name = n, grade = g, label = GB.Gangs[n].label } or nil end)

-- ─────────────────────────────── Base de données ───────────────────────────────
-- Migration : colonne « level » des territoires (niveaux améliorables depuis la tablette)
local function migrate()
    local has = MySQL.scalar.await("SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'gangbuilder_territories' AND COLUMN_NAME = 'level'")
    if (tonumber(has) or 0) == 0 then
        pcall(MySQL.query.await, 'ALTER TABLE gangbuilder_territories ADD COLUMN level TINYINT NOT NULL DEFAULT 1')
    end
end

local function installTables()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/install.sql')
    if sql then
        sql = sql:gsub('%-%-[^\n]*', '')
        for stmt in sql:gmatch('[^;]+') do
            if stmt:match('%S') then MySQL.query.await(stmt) end
        end
    end
    pcall(migrate)
end

-- Requête de lecture des grades (colonnes de job2_grades configurables)
function GB.gradesSelect(where)
    local C = Config.Job2.GradeColumns
    return ('SELECT %s AS job_name, %s AS grade, %s AS name, %s AS label, %s AS salary FROM %s %s ORDER BY %s, %s'):format(
        GB.id(C.job), GB.id(C.grade), GB.id(C.name), GB.id(C.label), GB.id(C.salary), GB.id(Config.Job2.GradesTable), where or '', GB.id(C.job), GB.id(C.grade))
end

function GB.registerStash(point)
    if GB.inventory() ~= 'ox' or point.type ~= 'stash' then return end
    local d = point.data or {}
    pcall(function()
        -- Pas de « groups » ESX : l'accès est contrôlé par le hook openInventory (job2 + grade), voir registerStashHook
        exports.ox_inventory:RegisterStash(('gangbuilder_%d'):format(point.id), point.label ~= '' and point.label or 'Coffre',
            tonumber(d.slots) or 50, (tonumber(d.weight) or 100) * 1000, false)
    end)
end

local function registerStashHook()
    if GB.inventory() ~= 'ox' then return end
    pcall(function()
        exports.ox_inventory:registerHook('openInventory', function(payload)
            local id = tonumber(tostring(payload.inventoryId):match('^gangbuilder_(%d+)$'))
            local point = id and GB.Points[id]
            if not point then return false end
            local name, grade = GB.job2Of(payload.source)
            return name == point.gang_name and grade >= point.min_grade
        end, { inventoryFilter = { '^gangbuilder_%d+$' } })
    end)
end

function GB.loadAll()
    GB.Gangs, GB.Points, GB.Territories = {}, {}, {}
    for _, r in ipairs(MySQL.query.await('SELECT * FROM gangbuilder_gangs') or {}) do
        r.blip = GB.decode(r.blip, {})
        r.settings = GB.decode(r.settings, {})
        r.money, r.dirty, r.rep = math.floor(tonumber(r.money) or 0), math.floor(tonumber(r.dirty) or 0), math.floor(tonumber(r.rep) or 0)
        r.grades = {}
        GB.Gangs[r.name] = r
    end
    local grades = MySQL.query.await(GB.gradesSelect(('WHERE %s IN (SELECT name FROM gangbuilder_gangs)'):format(GB.id(Config.Job2.GradeColumns.job)))) or {}
    for _, g in ipairs(grades) do
        if GB.Gangs[g.job_name] then table.insert(GB.Gangs[g.job_name].grades, g) end
    end
    for _, p in ipairs(MySQL.query.await('SELECT * FROM gangbuilder_points ORDER BY id') or {}) do
        p.coords = GB.decode(p.coords, { x = 0, y = 0, z = 0, h = 0 })
        p.data = GB.decode(p.data, {})
        if GB.Gangs[p.gang_name] then
            GB.Points[p.id] = p
            GB.registerStash(p)
        end
    end
    for _, t in ipairs(MySQL.query.await('SELECT * FROM gangbuilder_territories ORDER BY id') or {}) do
        t.coords = GB.decode(t.coords, { x = 0, y = 0, z = 0 })
        t.settings = GB.decode(t.settings, {})
        t.level = math.max(1, math.floor(tonumber(t.level) or 1))
        if t.owner and not GB.Gangs[t.owner] then t.owner = nil end
        GB.Territories[t.id] = t
    end
end

function GB.count(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end

-- ─────────────────────────────── Synchronisation clients ───────────────────────────────
function GB.publicBlips()
    local list = {}
    for name, gang in pairs(GB.Gangs) do
        local b = gang.blip or {}
        if b.enabled and b.coords then
            list[#list + 1] = {
                gang = name, label = (b.label and b.label ~= '') and b.label or gang.label, sprite = b.sprite, color = b.color, category = 'gang',
                scale = b.scale, coords = b.coords, shortRange = b.shortRange ~= false,
            }
        end
    end
    return list
end

local function mergeStyle(a, b)
    local o = {}
    for k, v in pairs(a or {}) do o[k] = v end
    for k, v in pairs(b or {}) do o[k] = v end
    return next(o) and o or nil
end

function GB.pointsForGang(name)
    local list, gang = {}, GB.Gangs[name]
    if not gang then return list end
    local color = GB.hexToRgb(gang.color)
    for id, p in pairs(GB.Points) do
        if p.gang_name == name then
            if p.type == 'garage' and p.data.store then      -- point de rangement du garage : envoyé comme un point à part (id décalé)
                list[#list + 1] = { id = id + 100000000, type = 'garage_return', label = p.label .. ' (rangement)', coords = p.data.store.coords, min_grade = p.min_grade, color = color,
                    kind = p.data.kind or 'car', radius = p.data.store.radius or 5.0, style = mergeStyle(gang.settings and gang.settings.marker, p.data.style) }
            end
            list[#list + 1] = {
                id = id, type = p.type, label = p.label, coords = p.coords, min_grade = p.min_grade, color = color,
                kind = (p.type == 'garage' or p.type == 'garage_return') and (p.data.kind or 'car') or nil,
                radius = p.type == 'garage_return' and (p.data.radius or 5.0) or nil,
                spawn = p.type == 'garage' and p.data.spawn or nil, style = mergeStyle(gang.settings and gang.settings.marker, p.data.style),
            }
        end
    end
    return list
end

-- Boutiques publiques (marché noir ouvert à tous) : envoyées à tout le monde
function GB.publicShops()
    local list = {}
    for id, p in pairs(GB.Points) do
        if p.type == 'shop' and p.data and p.data.public then
            list[#list + 1] = { id = id, type = 'shop', label = p.label, coords = p.coords, min_grade = 0, public = true, gang = p.gang_name, color = GB.hexToRgb(GB.Gangs[p.gang_name].color) }
        end
    end
    return list
end

-- Actions du menu F7 : celles cochées dans le builder + fiche du gang (+ quitter si autorisé)
function GB.menuActions(gang)
    local list = { 'info' }
    if Config.Tablet and Config.Tablet.Enabled then list[#list + 1] = 'tablet' end
    for _, a in ipairs(gang.settings.actions or {}) do
        if Config.Actions[a] and a ~= 'info' and a ~= 'leave' and a ~= 'tablet' then list[#list + 1] = a end
    end
    if Config.Gang.AllowLeave then list[#list + 1] = 'leave' end
    return list
end

function GB.configSnapshot()
    local snap = {}
    for _, id in ipairs(GB_SECTIONS) do
        if id ~= 'gangTypes' then snap[id] = GBGet(id, true) end
    end
    return snap
end

function GB.syncPlayer(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local name, grade = GB.job2Of(xPlayer)
    local gang = name and GB.Gangs[name]
    GB.PlayerGang[src] = gang and { name = name, grade = grade } or nil
    if not gang then   -- aide au diagnostic : ce que le serveur voit comme job2 et les gangs qu'il connaît
        local known = {}
        for n in pairs(GB.Gangs) do if #known < 8 then known[#known + 1] = n end end
        TriggerClientEvent('gangbuilder:client:diag', src, { job2 = name or '', known = known })
    end
    TriggerClientEvent('gangbuilder:client:config', src, GB.configSnapshot())
    TriggerClientEvent('gangbuilder:client:sync', src, {
        points = gang and GB.pointsForGang(name) or {},
        shops = GB.publicShops(),
        blips = GB.publicBlips(),
        territories = GB.territoryList and GB.territoryList() or {},
        gangConfig = gang and {
            name = name, label = gang.label, color = gang.color, accent = gang.settings and gang.settings.ui_accent, grade = grade, gradeLabel = (gang.grades[grade + 1] or {}).label or '',
            actions = GB.menuActions(gang), boss_grade = gang.boss_grade,
        } or nil,
    })
end

function GB.syncAll()
    for _, src in ipairs(GetPlayers()) do GB.syncPlayer(tonumber(src)) end
end

AddEventHandler('esx:playerLoaded', function(src) SetTimeout(1500, function() GB.syncPlayer(src) end) end)
AddEventHandler('playerDropped', function() GB.PlayerGang[source] = nil GB.Active[source] = nil end)

RegisterNetEvent('gangbuilder:server:requestSync', function()
    GB.syncPlayer(source)
end)

-- Resynchronisation périodique : rattrape un changement de job2 fait par un autre script
CreateThread(function()
    while true do
        Wait(60000)
        if GB.ready then GB.syncAll() end
    end
end)

AddEventHandler('onResourceStart', function(res)
    if res == 'ox_inventory' then
        registerStashHook()
        for _, p in pairs(GB.Points) do GB.registerStash(p) end
        return
    end
    if res ~= GetCurrentResourceName() then return end
    installTables()
    GB.loadAll()
    registerStashHook()
    GB.ready = true
    for _, ev in ipairs(Config.Job2.SyncEvents or {}) do
        AddEventHandler(ev, function(src) if type(src) == 'number' then SetTimeout(300, function() GB.syncPlayer(src) end) end end)
    end
    SetTimeout(1000, GB.syncAll)
    print(('^2[gangbuilder] %d gang(s), %d point(s), %d territoire(s) chargés.^0'):format(GB.count(GB.Gangs), GB.count(GB.Points), GB.count(GB.Territories)))
end)
