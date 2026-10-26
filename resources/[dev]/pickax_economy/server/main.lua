local PresetName = 'equilibre'
do
    local saved = GetResourceKvpString('economy:preset')
    local want = (saved and saved ~= '') and saved or Config.Preset
    PresetName = (Config.Presets[want] and want) or 'equilibre'
end
local function P() return Config.Presets[PresetName] or Config.Presets.equilibre end

-- Bonus de gains le week-end (panel web > Réglages > Économie) : n'agit que s'il a été réglé
local weekend = 1.0
local function readWeekend(all, ov) weekend = (ov and ov.eco_weekend_income ~= nil) and (tonumber(all.eco_weekend_income) or 1.0) or 1.0 end
AddEventHandler('pickax_settings:changed', readWeekend)
CreateThread(function()
    Wait(6000)
    if GetResourceState('pickax_settings') == 'started' then pcall(function() readWeekend(exports.pickax_settings:GetAll(), exports.pickax_settings:Overrides()) end) end
end)
local function weekendFactor()
    if weekend <= 1.0 then return 1.0 end
    local d = tonumber(os.date('%w'))
    return (d == 0 or d == 6) and weekend or 1.0
end

local State = {}   -- State[clé] = { p = pression, off = écart d'événement, off_until = fin (os.time), last = dernier multiplicateur, dirty = bool }

MySQL.ready(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS pickax_economy (
        k VARCHAR(80) NOT NULL PRIMARY KEY, p DOUBLE NOT NULL DEFAULT 0, off DOUBLE NOT NULL DEFAULT 0, off_until INT NOT NULL DEFAULT 0) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    for _, r in ipairs(MySQL.query.await('SELECT k, p, off, off_until FROM pickax_economy') or {}) do
        State[r.k] = { p = r.p, off = r.off, off_until = r.off_until, last = 1.0 }
    end
end)

local function cfgOf(k)
    for prefix, c in pairs(Config.Defaults) do if k:sub(1, #prefix) == prefix then return c end end
    return Config.Fallback
end

local function tanh(x) local e = math.exp(2 * x) return (e - 1) / (e + 1) end
local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

local function mult(k)
    local s = State[k]
    if not s then return 1.0 end
    local c = cfgOf(k)
    local off = (s.off_until > os.time()) and s.off or 0
    return clamp(1 - (P().sensitivity or Config.Sensitivity) * tanh(s.p / (c.scale or Config.Scale)) + off, c.min, c.max)
end

local function cleanKey(k) k = tostring(k or ''):lower() return (k ~= '' and #k <= 80 and not k:find('[\'"\\]')) and k or nil end

-- Facteur du type d'économie selon le marché : boutiques (prix) / récoltes (gains du joueur)
local function factorOf(k)
    if not k then return 1.0 end
    if k:sub(1, 5) == 'shop:' then return P().prices or 1.0 end
    if k:sub(1, 5) == 'crop:' then return (P().income or 1.0) * weekendFactor() end
    return 1.0
end

-- Prix actuel d'un produit : base × multiplicateur de l'offre/demande × type d'économie du serveur (arrondi)
exports('Multiplier', function(k) k = cleanKey(k) return k and (mult(k) * factorOf(k)) or 1.0 end)
exports('Price', function(k, base) k = cleanKey(k) return math.floor((base or 0) * (k and (mult(k) * factorOf(k)) or 1.0) + 0.5) end)

-- Type d'économie du serveur : Preset() → nom + valeurs ; SetPreset(nom) ; Presets() → liste ; Scale('income'|'prices', montant) → montant ajusté
exports('Preset', function() local p = P() return PresetName, p end)
exports('Presets', function() local out = {} for id, p in pairs(Config.Presets) do out[#out + 1] = { id = id, label = p.label, desc = p.desc, income = p.income, prices = p.prices } end table.sort(out, function(a, b) return a.id < b.id end) return out end)
exports('SetPreset', function(name)
    if type(name) ~= 'string' or not Config.Presets[name] then return false end
    PresetName = name
    SetResourceKvp('economy:preset', name)
    return true
end)
exports('Scale', function(kind, amount)
    amount = tonumber(amount) or 0
    local f = (kind == 'prices') and (P().prices or 1.0) or ((P().income or 1.0) * weekendFactor())
    return math.floor(amount * f + 0.5)
end)

-- Enregistre un échange : side = 'sell' (le joueur vend → offre) ou 'buy' (le joueur achète → demande)
exports('Record', function(k, qty, side)
    k = cleanKey(k); qty = tonumber(qty) or 0
    if not k or qty <= 0 then return end
    local s = State[k]
    if not s then s = { p = 0, off = 0, off_until = 0, last = 1.0 } State[k] = s end
    s.p = s.p + (side == 'sell' and qty or -qty)
    s.p = clamp(s.p, -2000, 2000)
    s.dirty = true
end)

exports('Snapshot', function()
    local out = {}
    for k, s in pairs(State) do
        local m = mult(k)
        out[#out + 1] = { key = k, mult = m, pressure = s.p, trend = m - (s.last or m), event = (s.off_until > os.time()) and { swing = s.off, ends = s.off_until } or nil }
    end
    table.sort(out, function(a, b) return math.abs(a.mult - 1) > math.abs(b.mult - 1) end)
    return out
end)

-- Événement manuel ou aléatoire : swing > 0 = pénurie (prix en hausse), < 0 = surplus (prix en baisse)
exports('Event', function(k, swing, hours)
    k = cleanKey(k); swing = tonumber(swing) or 0; hours = tonumber(hours) or 3
    if not k or swing == 0 then return false end
    local s = State[k]
    if not s then s = { p = 0, off = 0, off_until = 0, last = 1.0 } State[k] = s end
    s.off, s.off_until, s.dirty = clamp(swing, -0.5, 0.5), os.time() + math.floor(clamp(hours, 0.1, 48) * 3600), true
    return true
end)

exports('Reset', function(k)
    if k == nil then
        for key, s in pairs(State) do s.p, s.off, s.off_until, s.dirty = 0, 0, 0, true end
        return true
    end
    k = cleanKey(k)
    local s = k and State[k]
    if not s then return false end
    s.p, s.off, s.off_until, s.dirty = 0, 0, 0, true
    return true
end)

local function save(sync)
    for k, s in pairs(State) do
        if s.dirty then
            s.dirty = false
            local run = sync and MySQL.update.await or MySQL.update
            run('INSERT INTO pickax_economy (k, p, off, off_until) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE p = VALUES(p), off = VALUES(off), off_until = VALUES(off_until)', { k, s.p, s.off, s.off_until })
        end
    end
end

CreateThread(function()
    while true do
        Wait(Config.Tick * 1000)
        for k, s in pairs(State) do
            s.last = mult(k)
            local before = s.p
            s.p = s.p * (1 - Config.Recovery)
            if math.abs(s.p) < 0.5 then s.p = 0 end
            if s.p ~= before then s.dirty = true end
            if s.off_until > 0 and s.off_until <= os.time() then s.off, s.off_until, s.dirty = 0, 0, true end
        end
        local E = Config.Events
        if E.Enabled and math.random() < E.Chance then
            local active, keys = 0, {}
            for k, s in pairs(State) do if s.off_until > os.time() then active = active + 1 elseif math.abs(s.p) >= 5 or s.last ~= 1.0 then keys[#keys + 1] = k end end
            if active < E.Max and #keys > 0 then
                local k = keys[math.random(#keys)]
                local sw = E.Swing[1] + math.random() * (E.Swing[2] - E.Swing[1])
                if math.random() < 0.5 then sw = -sw end
                exports.pickax_economy:Event(k, sw, E.Duration[1] + math.random() * (E.Duration[2] - E.Duration[1]))
            end
        end
        save()
    end
end)

AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then save(true) end end)

-- [AERO] contrôle de licence (pickax_guard) : cette ressource s'arrête si la licence n'est pas valide ou si pickax_guard est absent
CreateThread(function()
    local res = GetCurrentResourceName()
    Wait(20000 + math.random(0, 20000))
    while true do
        local valid = false
        for _ = 1, 4 do
            local ok, v = pcall(function() return exports.pickax_guard:Check(res) end)
            if ok and v == true then valid = true break end
            Wait(10000)
        end
        if not valid then print(('^1[AERO] %s arrêtée : licence invalide ou pickax_guard absent.^0'):format(res)) StopResource(res) return end
        Wait(240000 + math.random(0, 120000))
    end
end)
