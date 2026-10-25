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
    return clamp(1 - Config.Sensitivity * tanh(s.p / (c.scale or Config.Scale)) + off, c.min, c.max)
end

local function cleanKey(k) k = tostring(k or ''):lower() return (k ~= '' and #k <= 80 and not k:find('[\'"\\]')) and k or nil end

-- Prix actuel d'un produit : base × multiplicateur (arrondi)
exports('Multiplier', function(k) k = cleanKey(k) return k and mult(k) or 1.0 end)
exports('Price', function(k, base) k = cleanKey(k) return math.floor((base or 0) * (k and mult(k) or 1.0) + 0.5) end)

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
