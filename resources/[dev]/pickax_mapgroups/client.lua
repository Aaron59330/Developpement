-- ─────────────────────────────── Blips groupés + fiche du lieu (client) ───────────────────────────────
-- Les builders (garages, banques…) nous enregistrent leurs blips (SetGroups) : ceux de même nom sont déjà fusionnés en un seul blip « Nom (N) », et chaque blip peut avoir une fiche
-- (image + description saisies dans le builder). Le blip fusionné se place sur le lieu le plus proche du joueur.
-- « Sélectionner » un blip = poser un point de passage dessus sur la carte : un blip fusionné ouvre alors la liste de ses lieux ; la fiche du lieu s'affiche en haut à gauche.

local owners = {}     -- [ressource] = { { blip, name, info = { image, description }, tag, members = { { x, y, z } } } }
local ignoreWp = nil  -- point de passage posé par nous-mêmes : à ne pas réinterpréter
local lastWp = nil
local cardUntil, cardOn = 0, false

exports('SetGroups', function(owner, groups)
    owners[tostring(owner or '?')] = type(groups) == 'table' and groups or {}
end)

local TAGS = { garage = 'Garage', impound = 'Fourrière', rental = 'Location', dealer = 'Concessionnaire', fuel = 'Station-service', carwash = 'Lavage', bank = 'Banque', atm = 'Distributeur',
    shop = 'Boutique', pharmacy = 'Pharmacie', weapons = 'Armurerie', hardware = 'Bricolage', clothing = 'Vêtements', barber = 'Coiffeur', bar = 'Bar', electronics = 'Électronique',
    police = 'Police', ems = 'Hôpital', mecano = 'Garage auto', taxi = 'Taxi', realestate = 'Immobilier', government = 'Administration', school = 'École', locksmith = 'Serrurier',
    robbery = 'Commerce', drug = 'Activité', pvp = 'Arène', chase = 'Course', gang = 'Gang' }

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

-- ─── fiche du lieu (NUI, en haut à gauche) ───
local function showCard(g, m)
    if not g.info then return end
    local p = GetEntityCoords(PlayerPedId())
    SendNUIMessage({ action = 'show', title = g.name, image = g.info.image, description = g.info.description, tag = TAGS[g.tag] or 'Lieu',
        distance = m and dist2d(p.x, p.y, m.x, m.y) or nil })
    cardOn, cardUntil = true, GetGameTimer() + 12000
end

local function hideCard()
    if cardOn then SendNUIMessage({ action = 'hide' }) end
    cardOn, cardUntil = false, 0
end

-- la fiche reste tant que la carte est ouverte (puis 12 s) et disparaît si le point de passage est retiré
CreateThread(function()
    while true do
        Wait(500)
        if cardOn then
            if not IsWaypointActive() then hideCard()
            elseif IsPauseMenuActive() then cardUntil = math.max(cardUntil, GetGameTimer() + 3000)
            elseif GetGameTimer() > cardUntil then hideCard() end
        end
    end
end)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then SendNUIMessage({ action = 'hide' }) end end)

-- le blip fusionné suit le lieu le plus proche
CreateThread(function()
    while true do
        Wait(3000)
        local p = GetEntityCoords(PlayerPedId())
        for _, groups in pairs(owners) do
            for _, g in ipairs(groups) do
                if #g.members > 1 and DoesBlipExist(g.blip) then
                    local m = nearest(g, p.x, p.y)
                    if m then SetBlipCoords(g.blip, m.x + 0.0, m.y + 0.0, (m.z or 0.0) + 0.0) end
                end
            end
        end
    end
end)

local function streetOf(m)
    local s = GetStreetNameFromHashKey(GetStreetNameAtCoord(m.x + 0.0, m.y + 0.0, (m.z or 0.0) + 0.0))
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
                showCard(g, e.m)
            end }
    end
    lib.registerContext({ id = 'mapgroup_' .. tostring(g.blip), title = ('%s (%d lieux)'):format(g.name, #g.members), options = opts })
    lib.showContext('mapgroup_' .. tostring(g.blip))
end

-- sélection d'un blip = point de passage posé dessus
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
                    if hit then
                        if #hit.members > 1 then openMenu(hit) else showCard(hit, hit.members[1]) end
                    else hideCard() end
                end
            end
        else
            lastWp, ignoreWp = nil, nil
        end
    end
end)

-- un builder démarré avant nous se ré-enregistre
CreateThread(function() Wait(1500) TriggerEvent('pickax_mapgroups:ready') end)
