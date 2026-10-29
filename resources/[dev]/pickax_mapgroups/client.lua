-- ─────────────────────────────── Fiche du lieu (client) ───────────────────────────────
-- Les builders nous enregistrent leurs blips qui ont une fiche (SetGroups) : image + description saisies dans le builder, une fiche par lieu.
-- « Sélectionner » un blip sur la carte = poser un point de passage dessus : la fiche s'affiche en haut à gauche. (Passer d'un lieu de même nom à l'autre se fait avec les flèches de
-- la LÉGENDE de la carte : les blips de même nom sont identiques, GTA les range dans une seule ligne.)

local owners = {}      -- [ressource] = { { name, tag, members = { { blip, x, y, z, info } } } }
local cardOn, cardUntil = false, 0
local lastWp = nil

local TAGS = { garage = 'Garage', impound = 'Fourrière', rental = 'Location', dealer = 'Concessionnaire', fuel = 'Station-service', carwash = 'Lavage', bank = 'Banque', atm = 'Distributeur',
    shop = 'Boutique', pharmacy = 'Pharmacie', weapons = 'Armurerie', hardware = 'Bricolage', clothing = 'Vêtements', barber = 'Coiffeur', bar = 'Bar', electronics = 'Électronique',
    police = 'Police', ems = 'Hôpital', mecano = 'Garage auto', taxi = 'Taxi', realestate = 'Immobilier', government = 'Administration', school = 'École', locksmith = 'Serrurier',
    robbery = 'Commerce', drug = 'Activité', pvp = 'Arène', chase = 'Course', gang = 'Gang' }

local function dist2d(ax, ay, bx, by) local dx, dy = ax - bx, ay - by return math.sqrt(dx * dx + dy * dy) end

exports('SetGroups', function(owner, groups)
    owners[tostring(owner or '?')] = type(groups) == 'table' and groups or {}
end)

local function streetOf(m)
    local s = GetStreetNameFromHashKey(GetStreetNameAtCoord(m.x, m.y, m.z))
    return (s and s ~= '') and s or ''
end

local function showCard(g, i)
    local m = g.members[i]
    if not m then return end
    local info = m.info or {}
    local p = GetEntityCoords(PlayerPedId())
    SendNUIMessage({ action = 'show', title = g.name, image = info.image, description = (info.description and info.description ~= '') and info.description or streetOf(m),
        tag = TAGS[g.tag] or 'Lieu', distance = dist2d(p.x, p.y, m.x, m.y), index = i, total = #g.members })
    cardOn, cardUntil = true, GetGameTimer() + 12000
end

local function hideCard()
    if cardOn then SendNUIMessage({ action = 'hide' }) end
    cardOn = false
end

-- la fiche reste tant que la carte est ouverte (puis 12 s)
CreateThread(function()
    while true do
        Wait(400)
        if cardOn then
            if IsPauseMenuActive() then cardUntil = math.max(cardUntil, GetGameTimer() + 2500)
            elseif GetGameTimer() > cardUntil then hideCard() end
        end
    end
end)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then SendNUIMessage({ action = 'hide' }) end end)

-- sélection d'un blip = point de passage posé dessus (à 35 m près)
CreateThread(function()
    while true do
        Wait(400)
        if IsWaypointActive() then
            local wb = GetFirstBlipInfoId(8)
            if DoesBlipExist(wb) then
                local c = GetBlipInfoIdCoord(wb)
                local changed = not lastWp or dist2d(lastWp.x, lastWp.y, c.x, c.y) > 2.0
                lastWp = { x = c.x, y = c.y }
                if changed then
                    local best, bg, bi
                    for _, groups in pairs(owners) do
                        for _, g in ipairs(groups) do
                            for i, m in ipairs(g.members) do
                                local d = DoesBlipExist(m.blip) and dist2d(m.x, m.y, c.x, c.y) or nil
                                if d and d <= 35.0 and (not best or d < best) then best, bg, bi = d, g, i end
                            end
                        end
                    end
                    if bg then showCard(bg, bi) else hideCard() end
                end
            end
        else
            lastWp = nil
            if cardOn and not IsPauseMenuActive() then hideCard() end
        end
    end
end)

-- un builder démarré avant nous se ré-enregistre
CreateThread(function() Wait(1500) TriggerEvent('pickax_mapgroups:ready') end)
