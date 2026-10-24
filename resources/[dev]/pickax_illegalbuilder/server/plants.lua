-- ─────────────────────────────── Plantations : pousse en temps réel ───────────────────────────────
-- Un point de récolte avec « plantation » activée est une parcelle : vide → on plante des graines → la plante pousse (0 → 100 %) → on la récolte → la parcelle est vide.
-- Le temps de pousse est calculé avec l'heure du serveur (la plante continue de pousser quand le joueur est hors ligne).
local Plants = {}   -- ['<entité>:<point>'] = planted_at

local function key(eid, pi) return eid .. ':' .. pi end

-- Définition de plantation d'un point (nil si désactivée)
function IB.plantDef(e, idx)
    local p = e and e.points[idx]
    local pl = p and p.kind == 'harvest' and p.harvest and p.harvest.plant
    if pl and pl.enabled and pl.seed and pl.seed ~= '' then return pl, p end
    return nil
end

-- État d'une parcelle : 'empty' | 'growing' | 'ready', pourcentage, secondes restantes
function IB.plantStatus(e, idx)
    local pl = IB.plantDef(e, idx)
    if not pl then return 'none', 0, 0 end
    local at = Plants[key(e.id, idx)]
    if not at then return 'empty', 0, 0 end
    local total = math.max(1, pl.growMinutes) * 60
    local elapsed = os.time() - at
    if elapsed >= total then return 'ready', 100, 0 end
    return 'growing', math.floor(elapsed / total * 100), total - elapsed
end

local function payload()
    local list = {}
    for k, at in pairs(Plants) do
        local eid, pi = k:match('^(%d+):(%d+)$')
        list[#list + 1] = { eid = tonumber(eid), pi = tonumber(pi), at = at }
    end
    return { now = os.time(), list = list }
end

function IB.syncPlants(src) TriggerClientEvent('illegalbuilder:client:plants', src or -1, payload()) end

function IB.plantSet(e, idx, identifier)
    local at = os.time()
    Plants[key(e.id, idx)] = at
    MySQL.update('INSERT INTO illegalbuilder_plants (entity_id, point_idx, planted_at, planted_by) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE planted_at = VALUES(planted_at), planted_by = VALUES(planted_by)',
        { e.id, idx, at, identifier })
    IB.syncPlants()
end

function IB.plantClear(e, idx)
    Plants[key(e.id, idx)] = nil
    MySQL.update('DELETE FROM illegalbuilder_plants WHERE entity_id = ? AND point_idx = ?', { e.id, idx })
    IB.syncPlants()
end

local function loadAll()
    Plants = {}
    local ok, rows = pcall(function() return MySQL.query.await('SELECT entity_id, point_idx, planted_at FROM illegalbuilder_plants') end)
    for _, r in ipairs(ok and rows or {}) do Plants[key(r.entity_id, r.point_idx)] = tonumber(r.planted_at) end
end

local prevReady = IB.onReady
IB.onReady = function()
    if prevReady then prevReady() end
    loadAll()
end

-- Modules supprimés / points retirés / plantation désactivée : les plantes correspondantes disparaissent
local prevChanged = IB.onEntityChanged
function IB.onEntityChanged(e, deleted)
    if prevChanged then prevChanged(e, deleted) end
    local changed = false
    for k in pairs(Plants) do
        local eid, pi = k:match('^(%d+):(%d+)$')
        if tonumber(eid) == e.id and (deleted or not IB.plantDef(e, tonumber(pi))) then
            Plants[k] = nil changed = true
            MySQL.update('DELETE FROM illegalbuilder_plants WHERE entity_id = ? AND point_idx = ?', { e.id, tonumber(pi) })
        end
    end
    if changed then IB.syncPlants() end
end

-- État d'une parcelle pour le joueur qui s'en approche (panneau / notification)
ESX.RegisterServerCallback('illegalbuilder:drug:plantState', function(src, cb, eid, pi)
    local e = IB.Entities[tonumber(eid) or 0]
    local idx = tonumber(pi) or 0
    local pl, p = IB.plantDef(e, idx)
    if not pl or not e.enabled or not p.coords or not IB.near(src, p.coords, 4.0) then return cb({ ok = false, error = 'Trop loin' }) end
    local state, pct, left = IB.plantStatus(e, idx)
    cb({ ok = true, state = state, pct = pct, left = left, seed = pl.seed, seedCount = pl.seedCount, have = IB.itemCount(src, pl.seed) })
end)
