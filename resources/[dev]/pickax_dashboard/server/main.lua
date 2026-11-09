ESX = exports['es_extended']:getSharedObject()
local C = Config

-- ───────── temps de jeu (minutes cumulées) ─────────
CreateThread(function()
    MySQL.query.await('CREATE TABLE IF NOT EXISTS pickax_dashboard_playtime (identifier VARCHAR(60) NOT NULL PRIMARY KEY, minutes INT NOT NULL DEFAULT 0) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4')
    while true do
        Wait(60000)
        for _, id in ipairs(GetPlayers()) do
            local x = ESX.GetPlayerFromId(tonumber(id))
            if x then MySQL.update('INSERT INTO pickax_dashboard_playtime (identifier, minutes) VALUES (?, 1) ON DUPLICATE KEY UPDATE minutes = minutes + 1', { x.identifier }) end
        end
    end
end)

local function fmtTime(min)
    min = tonumber(min) or 0
    local d, h = math.floor(min / 1440), math.floor(min % 1440 / 60)
    if d > 0 then return ('%dj %dh'):format(d, h) end
    return ('%dh %02dmin'):format(h, min % 60)
end

local function safe(f, default) local ok, r = pcall(f) if ok and r ~= nil then return r end return default end
local function ident(s) return tostring(s):gsub('[^%w_]', '') end   -- noms de tables / colonnes issus de la config : lettres, chiffres, _ seulement

local function gather(src)
    local x = ESX.GetPlayerFromId(src)
    if not x then return nil end
    local id = x.identifier
    local lic = GetPlayerIdentifierByType and GetPlayerIdentifierByType(src, 'license') or id
    local d = {
        lang = C.Lang, name = x.getName and x.getName() or GetPlayerName(src), charId = src, accountId = (joaat(tostring(lic)) & 0x7fffffff) % 100000,
        playtime = fmtTime(safe(function() return MySQL.scalar.await('SELECT minutes FROM pickax_dashboard_playtime WHERE identifier = ?', { id }) end, 0)),
    }
    -- factures (liste)
    local B = C.Billing
    local rows = safe(function() return MySQL.query.await(('SELECT %s label, %s amount FROM %s WHERE %s = ? ORDER BY 2 DESC LIMIT 50'):format(ident(B.LabelColumn), ident(B.AmountColumn), ident(B.Table), ident(B.IdentifierColumn)), { id }) end, {})
    local total = 0
    d.bills = { count = #rows, items = {} }
    for _, r in ipairs(rows) do total = total + (tonumber(r.amount) or 0) d.bills.items[#d.bills.items + 1] = { label = tostring(r.label or 'Facture'), amount = tonumber(r.amount) or 0 } end
    d.bills.total = total
    -- véhicules
    local V = C.Vehicles
    local cols = V.StoredColumn ~= '' and (', ' .. ident(V.StoredColumn) .. ' stored') or ''
    local vr = safe(function() return MySQL.query.await(('SELECT plate, vehicle%s FROM %s WHERE %s = ?'):format(cols, ident(V.Table), ident(V.OwnerColumn)), { id }) end, {})
    local out = 0
    d.vehicles = { count = #vr, items = {} }
    for _, r in ipairs(vr) do
        local stored = r.stored == nil or tonumber(r.stored) == 1 or r.stored == true
        if not stored then out = out + 1 end
        local ok, v = pcall(json.decode, r.vehicle or '{}')
        d.vehicles.items[#d.vehicles.items + 1] = { plate = r.plate, model = ok and type(v) == 'table' and v.model or nil, state = stored and 'Rangé' or 'Sorti' }
    end
    d.vehicles.out, d.vehicles.stored = out, #vr - out
    -- niveau et récompenses (pickax_xp)
    if GetResourceState('pickax_xp') == 'started' then d.xp = safe(function() return exports.pickax_xp:Info(src) end, nil) end
    -- carnet (pickax_carnet)
    if GetResourceState('pickax_carnet') == 'started' then d.carnet = safe(function() return exports.pickax_carnet:Snapshot(src) end, nil) end
    -- métier et organisation (ESX)
    local function jobOf(j) if type(j) ~= 'table' then return nil end return { name = j.name, label = j.label or j.name, grade = j.grade, gradeLabel = j.grade_label or j.grade_name or '', salary = tonumber(j.grade_salary) or 0 } end
    d.job, d.job2 = jobOf(x.job), jobOf(x.job2)
    d.actions = { job = C.JobActions, gang = C.GangActions }
    -- services disponibles (ressource démarrée)
    d.services = {}
    for _, s in ipairs(C.Services or {}) do if GetResourceState(s.res) == 'started' then d.services[#d.services + 1] = s end end
    -- boutique
    local coins = 0
    local acc = C.Shop.CoinsAccount and x.getAccount and x.getAccount(C.Shop.CoinsAccount)
    if acc then coins = acc.money or 0 end
    d.shop = { coins = coins, items = C.Shop.Items or {}, hasBoutique = GetResourceState('pickax_boutique') == 'started' }
    return d
end

ESX.RegisterServerCallback('pickax_dashboard:data', function(src, cb) cb(gather(src)) end)
RegisterNetEvent('pickax_dashboard:buy', function(id)
    local src = source
    if C.Shop.BuyServerEvent then TriggerEvent(C.Shop.BuyServerEvent, src, tonumber(id)) end
end)
