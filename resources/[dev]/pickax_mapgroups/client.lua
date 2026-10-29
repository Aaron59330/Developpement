-- ─────────────────────────────── Blips de même nom : sélection au clavier + fiche du lieu (client) ───────────────────────────────
-- Les builders nous enregistrent leurs groupes (SetGroups) : des lieux de même nom gardent CHACUN leur blip sur la carte, mais forment un groupe.
-- Carte ouverte : ← → sélectionnent le lieu suivant / précédent du groupe (le blip choisi grossit et clignote, sa fiche — image + description saisies dans le builder — s'affiche en haut à gauche) ;
-- ↑ ↓ changent de groupe s'il y en a plusieurs. Poser un point de passage sur un blip le sélectionne aussi.

local owners = {}      -- [ressource] = { { name, tag, members = { { blip, x, y, z, info, scale } }, idx } }
local activeKey = nil  -- groupe actif (celui que ← → font défiler)
local cardOn, cardUntil = false, 0
local lastWp = nil
local lit = {}         -- membres actuellement mis en évidence : [blip] = scale d'origine

local TAGS = { garage = 'Garage', impound = 'Fourrière', rental = 'Location', dealer = 'Concessionnaire', fuel = 'Station-service', carwash = 'Lavage', bank = 'Banque', atm = 'Distributeur',
    shop = 'Boutique', pharmacy = 'Pharmacie', weapons = 'Armurerie', hardware = 'Bricolage', clothing = 'Vêtements', barber = 'Coiffeur', bar = 'Bar', electronics = 'Électronique',
    police = 'Police', ems = 'Hôpital', mecano = 'Garage auto', taxi = 'Taxi', realestate = 'Immobilier', government = 'Administration', school = 'École', locksmith = 'Serrurier',
    robbery = 'Commerce', drug = 'Activité', pvp = 'Arène', chase = 'Course', gang = 'Gang' }
local BIG = 1.6   -- le blip sélectionné est agrandi de 60 %

local function dist2d(ax, ay, bx, by) local dx, dy = ax - bx, ay - by return math.sqrt(dx * dx + dy * dy) end
local function alive(m) return m.blip and DoesBlipExist(m.blip) end

local function allGroups()
    local list = {}
    for _, groups in pairs(owners) do
        for _, g in ipairs(groups) do
            local any = false
            for _, m in ipairs(g.members) do if alive(m) then any = true end end
            if any then list[#list + 1] = g end
        end
    end
    return list
end

local function nearestIndex(g, px, py)
    local best, bd = 1, nil
    for i, m in ipairs(g.members) do
        local d = dist2d(px, py, m.x, m.y)
        if not bd or d < bd then best, bd = i, d end
    end
    return best
end

-- ─── mise en évidence du lieu sélectionné ───
local function unlight()
    for blip, scale in pairs(lit) do
        if DoesBlipExist(blip) then SetBlipScale(blip, scale) SetBlipFlashes(blip, false) end
    end
    lit = {}
end

local function light(g)
    unlight()
    local m = g.members[g.idx]
    if m and alive(m) then
        lit[m.blip] = m.scale or 0.5
        SetBlipScale(m.blip, (m.scale or 0.5) * BIG)
        SetBlipFlashes(m.blip, true)
    end
end

exports('SetGroups', function(owner, groups)
    local p = GetEntityCoords(PlayerPedId())
    groups = type(groups) == 'table' and groups or {}
    for _, g in ipairs(groups) do g.idx = nearestIndex(g, p.x, p.y) end   -- on commence par le lieu le plus proche
    owners[tostring(owner or '?')] = groups
end)

-- ─── fiche du lieu (NUI, en haut à gauche) ───
local function streetOf(m)
    local s = GetStreetNameFromHashKey(GetStreetNameAtCoord(m.x, m.y, m.z))
    return (s and s ~= '') and s or ''
end

local function showCard(g)
    local m = g.members[g.idx]
    if not m then return end
    local info = m.info or {}
    local p = GetEntityCoords(PlayerPedId())
    SendNUIMessage({ action = 'show', title = g.name, image = info.image, description = (info.description and info.description ~= '') and info.description or streetOf(m),
        tag = TAGS[g.tag] or 'Lieu', distance = dist2d(p.x, p.y, m.x, m.y), index = g.idx, total = #g.members })
    cardOn, cardUntil = true, GetGameTimer() + 12000
end

local function hideCard()
    if cardOn then SendNUIMessage({ action = 'hide' }) end
    cardOn = false
    unlight()
end

local function choose(g, idx)
    if idx then g.idx = idx end
    activeKey = tostring(g)
    light(g)
    showCard(g)
end

-- la fiche reste tant que la carte est ouverte (puis 12 s) ; elle disparaît quand la carte se ferme
CreateThread(function()
    while true do
        Wait(400)
        if cardOn then
            if IsPauseMenuActive() then cardUntil = math.max(cardUntil, GetGameTimer() + 2500)
            elseif GetGameTimer() > cardUntil then hideCard() end
        end
    end
end)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then unlight() SendNUIMessage({ action = 'hide' }) end end)

-- ─── ← → : lieu suivant / précédent ; ↑ ↓ : autre groupe ───
local function pressed(...)
    for i = 1, select('#', ...), 2 do
        local grp, ctl = select(i, ...)
        if IsDisabledControlJustPressed(grp, ctl) or IsControlJustPressed(grp, ctl) then return true end
    end
    return false
end

local function activeGroup(multi)
    for _, g in ipairs(multi) do if tostring(g) == activeKey then return g end end
    local p = GetEntityCoords(PlayerPedId())
    local best, bd
    for _, g in ipairs(multi) do
        local m = g.members[g.idx]
        local d = dist2d(p.x, p.y, m.x, m.y)
        if not bd or d < bd then best, bd = g, d end
    end
    if best then activeKey = tostring(best) end
    return best
end

CreateThread(function()
    while true do
        if not IsPauseMenuActive() then Wait(500) else
            Wait(0)
            local multi = {}
            for _, g in ipairs(allGroups()) do if #g.members > 1 then multi[#multi + 1] = g end end
            local g = #multi > 0 and activeGroup(multi) or nil
            if g then
                if pressed(0, 175, 2, 190) then choose(g, g.idx % #g.members + 1) Wait(180)
                elseif pressed(0, 174, 2, 189) then choose(g, (g.idx - 2) % #g.members + 1) Wait(180)
                elseif #multi > 1 and pressed(0, 172, 2, 188) then
                    for i, x in ipairs(multi) do if x == g then g = multi[i % #multi + 1] break end end
                    choose(g) Wait(220)
                elseif #multi > 1 and pressed(0, 173, 2, 187) then
                    for i, x in ipairs(multi) do if x == g then g = multi[(i - 2) % #multi + 1] break end end
                    choose(g) Wait(220)
                end
            end
        end
    end
end)

-- ─── sélection d'un blip = point de passage posé dessus ───
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
                    local done = false
                    for _, g in ipairs(allGroups()) do
                        for i, m in ipairs(g.members) do
                            if not done and dist2d(m.x, m.y, c.x, c.y) <= 35.0 then choose(g, i) done = true end
                        end
                    end
                end
            end
        else
            lastWp = nil
        end
    end
end)

-- un builder démarré avant nous se ré-enregistre
CreateThread(function() Wait(1500) TriggerEvent('pickax_mapgroups:ready') end)
