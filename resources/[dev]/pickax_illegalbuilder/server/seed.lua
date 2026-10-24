-- ─────────────────────────────── Point de blanchiment par défaut ───────────────────────────────
-- Sans module « Blanchiment » créé dans le builder, la tablette de blanchiment n'a rien à révéler. Au premier démarrage, si aucun point de
-- blanchiment n'existe, un module est créé (et activé) avec un point à la position ci-dessous. Position approximative : déplace-la dans
-- /illegalbuilder → module « Blanchiment d'argent » → Points. Commande admin : /ibseed (recrée le point s'il n'y en a plus aucun).
local Seed = { label = 'Blanchiment d\'argent', coords = { x = -1137.9, y = -1990.6, z = 13.2, h = 90.0 } }

local function hasLaunder()
    for _, e in pairs(IB.Entities) do
        if e.type == 'drug' then
            for _, p in ipairs(e.points or {}) do if p.kind == 'launder' then return true end end
        end
    end
    return false
end

local function seed()
    if hasLaunder() then return false end
    local tpl = Config.Templates.drug and Config.Templates.drug.launder
    if not tpl or not tpl.points or not tpl.points[1] then return false end
    local pt = json.decode(json.encode(tpl.points[1]))
    pt.coords = Seed.coords
    local e = IB.createFromTemplate('système', 'drug', 'launder', Seed.label, { points = { pt } })
    if not e then return false end
    e.enabled = true
    IB.save(e)
    IB.syncAll()
    print(('^2[illegalbuilder] Point de blanchiment créé par défaut (%.1f, %.1f, %.1f) : visible avec la tablette de blanchiment.^0'):format(Seed.coords.x, Seed.coords.y, Seed.coords.z))
    return true
end

CreateThread(function()
    while not IB.ready do Wait(500) end
    Wait(1500)
    local done = MySQL.scalar.await("SELECT v FROM illegalbuilder_settings WHERE k = 'seed_launder_v1'")
    if done then return end
    seed()
    MySQL.update.await("INSERT INTO illegalbuilder_settings (k, v) VALUES ('seed_launder_v1', '1') ON DUPLICATE KEY UPDATE v = VALUES(v)")
end)

RegisterCommand('ibseed', function(src)
    if src ~= 0 and not IB.isAdmin(src) then return end
    local ok = seed()
    local msg = ok and 'Point de blanchiment créé.' or 'Un point de blanchiment existe déjà (ou création impossible).'
    if src == 0 then print(msg) else TriggerClientEvent('esx:showNotification', src, msg) end
end, false)
