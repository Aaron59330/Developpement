-- ─────────────────────────────── Pré-placement des stations essence et des banques ───────────────────────────────
local P = Config.Preset

local function hasLabel(label)
    for _, e in pairs(WB.Entities) do if e.label == label then return true end end
    return false
end

local function activate(e)
    e.enabled = true
    WB.save(e)
end

-- Crée ce qui manque ; force = ignore le drapeau « déjà fait »
local function seed(force)
    if not P or not P.Enabled then return 0 end
    if not P.Auto and not force then return 0 end
    local made = 0
    local row = MySQL.single.await("SELECT v FROM worldbuilder_seed WHERE k = 'v1'")
    if row and not force then return 0 end

    local fuelTpl = Config.Templates.fuel.station
    for i, c in ipairs(P.FuelStations or {}) do
        local label = ('Station essence %02d'):format(i)
        if not hasLabel(label) then
            local pt = json.decode(json.encode(fuelTpl.points[1]))
            pt.label, pt.kind, pt.blip, pt.coords = 'Pompe', 'pump', true, { x = c[1], y = c[2], z = c[3], h = 0.0 }
            local e = WB.createFromTemplate('préréglage', 'fuel', 'station', label, {
                settings = { restockMinutes = P.FuelRestockMinutes or 0, restockLiters = P.FuelRestockLiters or 0 }, points = { pt } })
            if e then activate(e) made = made + 1 end
        end
    end

    if #(P.Banks or {}) > 0 and not hasLabel('Banque') then
        local pts = {}
        for i, c in ipairs(P.Banks) do
            local pt = json.decode(json.encode(Config.Templates.bank.branch.points[1]))
            pt.label, pt.kind, pt.blip, pt.coords = 'Agence ' .. i, 'counter', true, { x = c[1], y = c[2], z = c[3], h = 0.0 }
            pt.ped = { enabled = false, model = '', scenario = '' }
            pts[#pts + 1] = pt
        end
        local e = WB.createFromTemplate('préréglage', 'bank', 'branch', 'Banque', { points = pts })
        if e then activate(e) made = made + 1 end
    end

    MySQL.insert.await("INSERT INTO worldbuilder_seed (k, v) VALUES ('v1', ?) ON DUPLICATE KEY UPDATE v = VALUES(v)", { tostring(os.time()) })
    if made > 0 then
        WB.syncAll()
        print(('^2[worldbuilder] Pré-placement : %d module(s) créé(s) et activé(s) (stations essence, banque).^0'):format(made))
    end
    return made
end

-- Casino : créé une fois (drapeau « casino1 »), indépendamment de Preset.Auto ; force = recrée s'il manque
local function seedCasino(force)
    local C = P and P.Casino
    if not P or not P.Enabled or not C or not C.Enabled then return 0 end
    local row = MySQL.single.await("SELECT v FROM worldbuilder_seed WHERE k = 'casino1'")
    if row and not force then return 0 end
    if hasLabel(C.Label) then return 0 end
    local pts = {}
    for _, d in ipairs(C.Points or {}) do
        local isCashier = d[1] == 'cashier'
        pts[#pts + 1] = { kind = d[1], tier = d[2] ~= '' and d[2] or nil, label = d[3], blip = isCashier, coords = { x = d[4], y = d[5], z = d[6], h = d[7] },
            ped = isCashier and { enabled = true, model = 'u_m_m_bankman', scenario = 'WORLD_HUMAN_CLIPBOARD' } or { enabled = false, model = '', scenario = '' } }
    end
    local e = WB.createFromTemplate('préréglage', 'casino', 'casino', C.Label, { points = pts })
    MySQL.insert.await("INSERT INTO worldbuilder_seed (k, v) VALUES ('casino1', ?) ON DUPLICATE KEY UPDATE v = VALUES(v)", { tostring(os.time()) })
    if not e then return 0 end
    activate(e)
    WB.syncAll()
    print('^2[worldbuilder] Pré-placement : casino créé et activé (caisse, machines, blackjack, roulette).^0')
    return 1
end

local prevReady = WB.onReady
WB.onReady = function()
    if prevReady then prevReady() end
    CreateThread(function()
        MySQL.query.await([[CREATE TABLE IF NOT EXISTS worldbuilder_seed (k VARCHAR(30) NOT NULL PRIMARY KEY, v VARCHAR(60) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
        seed(false)
        seedCasino(false)
    end)
end

RegisterCommand('wbseed', function(src)
    if src ~= 0 and not WB.isAdmin(src) then return end
    local n = seed(true) + seedCasino(true)
    local msg = n > 0 and (n .. ' module(s) créé(s).') or 'Rien à créer : tout est déjà en place.'
    if src == 0 then print('[worldbuilder] ' .. msg) else WB.notify(src, msg, 'success') end
end, false)
