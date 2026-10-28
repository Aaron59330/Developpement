-- ─────────────────────────────── Tags de gang ───────────────────────────────
-- /tag dans un territoire que ton gang possède pose une marque à tes pieds. Chaque tag augmente le revenu du territoire (plafonné) et expire au bout de quelques jours.
-- Un membre d'un autre gang peut /effacer un tag proche (sans pouvoir le faire sur son propre territoire). Position, appartenance et délais sont vérifiés côté serveur.

GB.Tags = GB.Tags or {}      -- [id] = { id, gang, territory, x, y, z, created }
local lastAct = {}           -- [src] = fin du délai

local function T() return Config.Tags or {} end
local function dist2(a, b) local dx, dy, dz = a.x - b.x, a.y - b.y, (a.z or 0) - (b.z or 0) return dx * dx + dy * dy + dz * dz end

CreateThread(function()
    Wait(2500)
    if not (MySQL and MySQL.query) then return end
    pcall(MySQL.query.await, [[CREATE TABLE IF NOT EXISTS gangbuilder_tags (id INT AUTO_INCREMENT PRIMARY KEY, gang VARCHAR(60) NOT NULL, territory INT NOT NULL,
        x DOUBLE NOT NULL, y DOUBLE NOT NULL, z DOUBLE NOT NULL, created_at INT NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    local ok, rows = pcall(MySQL.query.await, 'SELECT * FROM gangbuilder_tags')
    if ok and rows then
        local now = os.time()
        for _, r in ipairs(rows) do
            if GB.tagExpired(r.created_at, now) then MySQL.update('DELETE FROM gangbuilder_tags WHERE id = ?', { r.id })
            else GB.Tags[r.id] = { id = r.id, gang = r.gang, territory = r.territory, x = r.x, y = r.y, z = r.z, created = r.created_at } end
        end
        GB.syncTags()
    end
end)

function GB.tagExpired(created, now)
    local days = tonumber(T().ExpireDays) or 0
    return days > 0 and (now or os.time()) - (created or 0) > days * 86400
end

-- Nombre de tags valides d'un gang dans un territoire
function GB.tagCount(territory, gang)
    local n = 0
    for _, t in pairs(GB.Tags) do if t.territory == territory and t.gang == gang and not GB.tagExpired(t.created) then n = n + 1 end end
    return n
end

-- Bonus de revenu d'un territoire : 1 + (nombre de tags × % par tag), plafonné
function GB.tagMul(territory, owner)
    if not T().Enabled or not owner then return 1.0 end
    local pct = math.min(tonumber(T().IncomeMaxPercent) or 0, GB.tagCount(territory, owner) * (tonumber(T().IncomePercent) or 0))
    return 1.0 + pct / 100
end

-- Le point est-il dans ce territoire ?
function GB.tagInside(t, pos)
    return t and t.coords and dist2({ x = t.coords.x, y = t.coords.y, z = 0 }, { x = pos.x, y = pos.y, z = 0 }) <= (tonumber(t.radius) or 0) ^ 2
end

function GB.syncTags(target)
    local list = {}
    for _, t in pairs(GB.Tags) do if not GB.tagExpired(t.created) then list[#list + 1] = { id = t.id, x = t.x, y = t.y, z = t.z, gang = t.gang, color = GB.Gangs[t.gang] and GB.Gangs[t.gang].color or nil } end end
    TriggerClientEvent('gangbuilder:client:tags', target or -1, list)
end

-- Territoire contenant la position (le plus proche si plusieurs se chevauchent)
local function territoryAt(pos)
    local best, bd
    for id, t in pairs(GB.Territories or {}) do
        if GB.tagInside(t, pos) then
            local d = dist2({ x = t.coords.x, y = t.coords.y, z = 0 }, { x = pos.x, y = pos.y, z = 0 })
            if not bd or d < bd then best, bd = t, d end
        end
    end
    return best
end

local function guard(src)
    if not T().Enabled then return nil, 'Les tags sont désactivés.' end
    local now = os.time()
    if (lastAct[src] or 0) > now then return nil, ('Patiente %d s.'):format(lastAct[src] - now) end
    local gang = GB.gangOf(src)
    if not gang then return nil, 'Tu n\'es dans aucun gang.' end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil, 'Impossible.' end
    return gang, nil, GetEntityCoords(ped), now
end

function GB.tagPlace(src)
    local gang, err, pos, now = guard(src)
    if not gang then return false, err end
    local t = territoryAt(pos)
    if not t or t.owner ~= gang.name then return false, 'Ton gang doit posséder le territoire pour y poser un tag.' end
    local max = math.floor(tonumber(T().MaxPerTerritory) or 5)
    if GB.tagCount(t.id, gang.name) >= max then return false, ('Ce territoire est déjà couvert (%d tags max).'):format(max) end
    for _, o in pairs(GB.Tags) do
        if not GB.tagExpired(o.created) and dist2(o, pos) < (tonumber(T().MinSpacing) or 8.0) ^ 2 then return false, 'Il y a déjà un tag ici.' end
    end
    lastAct[src] = now + math.floor(tonumber(T().Cooldown) or 30)
    local id = MySQL.insert.await('INSERT INTO gangbuilder_tags (gang, territory, x, y, z, created_at) VALUES (?, ?, ?, ?, ?, ?)', { gang.name, t.id, pos.x, pos.y, pos.z, now })
    GB.Tags[id] = { id = id, gang = gang.name, territory = t.id, x = pos.x, y = pos.y, z = pos.z, created = now }
    GB.syncTags()
    if GB.addRep then GB.addRep(gang.name, tonumber(T().RepPlace) or 0) end
    return true, nil, t
end

function GB.tagErase(src)
    local gang, err, pos, now = guard(src)
    if not gang then return false, err end
    local best, bd
    for _, o in pairs(GB.Tags) do
        local d = dist2(o, pos)
        if o.gang ~= gang.name and d <= (tonumber(T().EraseDistance) or 3.0) ^ 2 and (not bd or d < bd) then best, bd = o, d end
    end
    if not best then return false, 'Aucun tag rival à portée.' end
    lastAct[src] = now + math.floor(tonumber(T().EraseCooldown) or 60)
    GB.Tags[best.id] = nil
    MySQL.update('DELETE FROM gangbuilder_tags WHERE id = ?', { best.id })
    GB.syncTags()
    if GB.addRep then GB.addRep(gang.name, tonumber(T().RepErase) or 0) end
    if GB.news and GB.Gangs[best.gang] then GB.news(('%s a effacé un tag de %s.'):format(gang.label or gang.name, GB.Gangs[best.gang].label), 'territory') end
    return true, nil, best
end

RegisterCommand('tag', function(src)
    if src == 0 then return end
    local ok, err = GB.tagPlace(src)
    GB.notify(src, ok and '~g~Tag posé : ton gang marque son territoire.' or ('~r~' .. err))
end, false)

RegisterCommand('effacer', function(src)
    if src == 0 then return end
    local ok, err = GB.tagErase(src)
    GB.notify(src, ok and '~g~Tag rival effacé.' or ('~r~' .. err))
end, false)

AddEventHandler('playerDropped', function() lastAct[source] = nil end)
RegisterNetEvent('gangbuilder:server:tagsReady', function() GB.syncTags(source) end)
