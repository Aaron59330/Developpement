-- ─────────────────────────────── Blips groupés (client) ───────────────────────────────
-- Les builders (garages, banques…) regroupent leurs lieux de même nom en un seul blip et nous l'enregistrent avec la liste des lieux (SetGroups).
-- Le blip se place sur le lieu le plus proche du joueur. Quand le joueur pose un point de passage sur ce blip (carte → sélectionner le blip → « Définir un point de passage »),
-- une liste des lieux s'ouvre ; son choix déplace le point de passage sur le lieu choisi.

local owners = {}     -- [ressource] = { { blip, name, members = { { x, y, z } } } }
local ignoreWp = nil  -- point de passage posé par nous-mêmes : à ne pas réinterpréter
local lastWp = nil

exports('SetGroups', function(owner, groups)
    owners[tostring(owner or '?')] = type(groups) == 'table' and groups or {}
end)

local function dist2d(ax, ay, bx, by) local dx, dy = ax - bx, ay - by return math.sqrt(dx * dx + dy * dy) end

-- Lieu du groupe le plus proche du joueur
local function nearest(g, px, py)
    local best, bd
    for _, m in ipairs(g.members) do
        local d = dist2d(px, py, m.x, m.y)
        if not bd or d < bd then best, bd = m, d end
    end
    return best
end

CreateThread(function()
    while true do
        Wait(3000)
        local p = GetEntityCoords(PlayerPedId())
        for _, groups in pairs(owners) do
            for _, g in ipairs(groups) do
                if DoesBlipExist(g.blip) then
                    local m = nearest(g, p.x, p.y)
                    if m then SetBlipCoords(g.blip, m.x + 0.0, m.y + 0.0, (m.z or 0.0) + 0.0) end
                end
            end
        end
    end
end)

local function streetOf(m)
    local h = GetStreetNameAtCoord(m.x + 0.0, m.y + 0.0, (m.z or 0.0) + 0.0)
    local s = GetStreetNameFromHashKey(h)
    return (s and s ~= '') and s or ''
end

local function openMenu(g)
    local p = GetEntityCoords(PlayerPedId())
    local list = {}
    for _, m in ipairs(g.members) do list[#list + 1] = { m = m, d = dist2d(p.x, p.y, m.x, m.y) } end
    table.sort(list, function(a, b) return a.d < b.d end)
    local opts = {}
    for i, e in ipairs(list) do
        opts[#opts + 1] = { title = ('%s — %s'):format(g.name, e.d >= 1000 and ('%.1f km'):format(e.d / 1000) or ('%d m'):format(math.floor(e.d))),
            description = streetOf(e.m), icon = i == 1 and 'location-dot' or 'map-pin',
            onSelect = function()
                ignoreWp = { x = e.m.x, y = e.m.y }
                SetNewWaypoint(e.m.x + 0.0, e.m.y + 0.0)
                lib.notify({ title = g.name, description = 'Point de passage placé sur ce lieu.', type = 'success' })
            end }
    end
    lib.registerContext({ id = 'mapgroup_' .. tostring(g.blip), title = ('%s (%d lieux)'):format(g.name, #g.members), options = opts })
    lib.showContext('mapgroup_' .. tostring(g.blip))
end

CreateThread(function()
    while true do
        Wait(400)
        if IsWaypointActive() then
            local wb = GetFirstBlipInfoId(8)
            if DoesBlipExist(wb) then
                local c = GetBlipInfoIdCoord(wb)
                local changed = not lastWp or dist2d(lastWp.x, lastWp.y, c.x, c.y) > 2.0
                lastWp = { x = c.x, y = c.y }
                if changed and not (ignoreWp and dist2d(ignoreWp.x, ignoreWp.y, c.x, c.y) < 3.0) then
                    ignoreWp = nil
                    local hit
                    for _, groups in pairs(owners) do
                        for _, g in ipairs(groups) do
                            if not hit and DoesBlipExist(g.blip) then
                                local b = GetBlipCoords(g.blip)
                                if dist2d(b.x, b.y, c.x, c.y) <= 35.0 then hit = g end
                            end
                        end
                    end
                    if hit then openMenu(hit) end
                end
            end
        else
            lastWp, ignoreWp = nil, nil
        end
    end
end)

-- un builder démarré avant nous se ré-enregistre
CreateThread(function() Wait(1500) TriggerEvent('pickax_mapgroups:ready') end)
