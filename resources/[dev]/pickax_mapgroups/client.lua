-- ─────────────────────────────── Blips groupés + fiche du lieu (client) ───────────────────────────────
-- Les builders (garages, banques…) nous enregistrent les blips qui ont une fiche (SetGroups) : image + description saisies dans le builder.
-- Chaque lieu garde son propre blip sur la carte (même nom, rien ajouté). « Sélectionner » un blip = poser un point de passage dessus : la fiche s'affiche en haut à gauche.

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
        distance = m and dist2d(p.x, p.y, m.x, m.y) or nil, siblings = g.siblings or 0 })
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
                        showCard(hit, hit.members[1])
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
