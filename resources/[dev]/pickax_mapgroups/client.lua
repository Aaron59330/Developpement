-- ─────────────────────────────── Blips groupés + fiche du lieu (client) ───────────────────────────────
-- Les builders nous enregistrent leurs blips (SetGroups). Des lieux de même nom ne forment qu'UN blip sur la carte (même nom, rien d'ajouté).
-- Carte ouverte : ← → font passer le blip d'un lieu au suivant ; ↑ ↓ changent de blip groupé s'il y en a plusieurs. La fiche du lieu (image + description saisies dans le builder)
-- s'affiche en haut à gauche, aussi quand on pose un point de passage sur le blip.

local owners = {}      -- [ressource] = { { blip, name, tag, members = { { x, y, z, info } }, idx } }
local activeKey = nil  -- blip actif (celui que ← → font défiler)
local cardOn, cardUntil = false, 0
local lastWp, ignoreWp = nil, nil

local TAGS = { garage = 'Garage', impound = 'Fourrière', rental = 'Location', dealer = 'Concessionnaire', fuel = 'Station-service', carwash = 'Lavage', bank = 'Banque', atm = 'Distributeur',
    shop = 'Boutique', pharmacy = 'Pharmacie', weapons = 'Armurerie', hardware = 'Bricolage', clothing = 'Vêtements', barber = 'Coiffeur', bar = 'Bar', electronics = 'Électronique',
    police = 'Police', ems = 'Hôpital', mecano = 'Garage auto', taxi = 'Taxi', realestate = 'Immobilier', government = 'Administration', school = 'École', locksmith = 'Serrurier',
    robbery = 'Commerce', drug = 'Activité', pvp = 'Arène', chase = 'Course', gang = 'Gang' }

local function dist2d(ax, ay, bx, by) local dx, dy = ax - bx, ay - by return math.sqrt(dx * dx + dy * dy) end

-- Ordre de passage : les groupes encore existants, de tous les builders
local function allGroups()
    local list = {}
    for _, groups in pairs(owners) do
        for _, g in ipairs(groups) do if DoesBlipExist(g.blip) then list[#list + 1] = g end end
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

local function place(g)
    local m = g.members[g.idx]
    if m then SetBlipCoords(g.blip, m.x, m.y, m.z) end
end

exports('SetGroups', function(owner, groups)
    local p = GetEntityCoords(PlayerPedId())
    groups = type(groups) == 'table' and groups or {}
    for _, g in ipairs(groups) do
        g.idx = nearestIndex(g, p.x, p.y)   -- on commence par le lieu le plus proche
        place(g)
        HideNumberOnBlip(g.blip)            -- jamais de chiffre sur le blip
    end
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
    if IsNuiFocused() and not IsPauseMenuActive() then return end   -- pas de fiche par-dessus une autre interface
    local info = m.info or {}
    local p = GetEntityCoords(PlayerPedId())
    SendNUIMessage({ action = 'show', title = g.name, image = info.image, description = (info.description and info.description ~= '') and info.description or streetOf(m),
        tag = TAGS[g.tag] or 'Lieu', distance = dist2d(p.x, p.y, m.x, m.y), index = g.idx, total = #g.members })
    cardOn, cardUntil = true, GetGameTimer() + 12000
end

local function hideCard()
    if cardOn then SendNUIMessage({ action = 'hide' }) end
    cardOn = false
end

local function flash(g)
    SetBlipFlashes(g.blip, true)
    SetTimeout(900, function() if DoesBlipExist(g.blip) then SetBlipFlashes(g.blip, false) end end)
end

-- la fiche reste tant que la carte est ouverte (puis 12 s) ; elle disparaît quand la carte se ferme
CreateThread(function()
    while true do
        Wait(cardOn and 120 or 400)
        if cardOn then
            if IsPauseMenuActive() then cardUntil = math.max(cardUntil, GetGameTimer() + 2500)
            elseif IsNuiFocused() or GetGameTimer() > cardUntil then hideCard() end   -- inventaire, téléphone, menus… : la fiche s'efface tout de suite
        end
    end
end)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then SendNUIMessage({ action = 'hide' }) end end)

-- ─── ← → : lieu suivant / précédent ; ↑ ↓ : autre blip groupé ───
local function pressed(...)
    for i = 1, select('#', ...), 2 do
        local grp, ctl = select(i, ...)
        if IsDisabledControlJustPressed(grp, ctl) or IsControlJustPressed(grp, ctl) then return true end
    end
    return false
end

local function activeGroup(list)
    for _, g in ipairs(list) do if tostring(g.blip) == activeKey then return g end end
    local p = GetEntityCoords(PlayerPedId())
    local best, bd
    for _, g in ipairs(list) do
        if #g.members > 1 then
            local m = g.members[g.idx]
            local d = dist2d(p.x, p.y, m.x, m.y)
            if not bd or d < bd then best, bd = g, d end
        end
    end
    if best then activeKey = tostring(best.blip) end
    return best
end

-- Passe le blip du groupe actif au lieu suivant (+1) / précédent (-1) ; `other` : change de groupe à la place
local function multiGroups()
    local list = {}
    for _, g in ipairs(allGroups()) do if #g.members > 1 then list[#list + 1] = g end end
    return list
end

local lastCycle = 0
local function cycle(dir, other)
    -- une flèche déclenche la lecture des touches ET la touche configurable : sans ce garde-fou, le blip avançait deux fois (retour au point de départ avec 2 lieux)
    local now = GetGameTimer()
    if now - lastCycle < 260 then return true end
    lastCycle = now
    local multi = multiGroups()
    local g = #multi > 0 and activeGroup(multi) or nil
    if not g then return false end
    if other then
        for i, x in ipairs(multi) do if x == g then g = multi[(i - 1 + dir) % #multi + 1] break end end
        activeKey = tostring(g.blip)
    else
        g.idx = (g.idx - 1 + dir) % #g.members + 1
        place(g)
    end
    flash(g) showCard(g)
    return true
end

-- Méthode 1 : les touches de la carte (flèches), lues image par image tant que la carte est ouverte
local wasOpen = false
CreateThread(function()
    while true do
        if not IsPauseMenuActive() then wasOpen = false Wait(500) else
            Wait(0)
            if not wasOpen then   -- à l'ouverture de la carte : la fiche du blip groupé le plus proche s'affiche avec l'indication des touches
                wasOpen = true
                local multi = multiGroups()
                local g = #multi > 0 and activeGroup(multi) or nil
                if g then showCard(g) end
            end
            if pressed(0, 175, 2, 190) then if cycle(1) then Wait(180) end
            elseif pressed(0, 174, 2, 189) then if cycle(-1) then Wait(180) end
            elseif pressed(0, 172, 2, 188) then if cycle(1, true) then Wait(220) end
            elseif pressed(0, 173, 2, 187) then if cycle(-1, true) then Wait(220) end end
        end
    end
end)

-- Méthode 2 : touches configurables (Paramètres FiveM → Touches → « Blip suivant / précédent ») et commande /lieu — au cas où les flèches ne passent pas sur ta carte
RegisterCommand('pk_mapgroups_next', function() if IsPauseMenuActive() then cycle(1) end end, false)
RegisterCommand('pk_mapgroups_prev', function() if IsPauseMenuActive() then cycle(-1) end end, false)
RegisterKeyMapping('pk_mapgroups_next', 'Carte : lieu suivant du blip groupé', 'keyboard', 'RIGHT')
RegisterKeyMapping('pk_mapgroups_prev', 'Carte : lieu précédent du blip groupé', 'keyboard', 'LEFT')
RegisterCommand('lieu', function(_, args)
    local dir = (args[1] == 'prec' or args[1] == 'prev' or args[1] == '-') and -1 or 1
    if not cycle(dir) then print('[pickax_mapgroups] aucun blip groupé à parcourir') end
end, false)

-- ─── sélection d'un blip = point de passage posé dessus : la fiche s'affiche ───
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
                    for _, g in ipairs(allGroups()) do
                        local m = g.members[g.idx]
                        if m and dist2d(m.x, m.y, c.x, c.y) <= 35.0 then activeKey = tostring(g.blip) showCard(g) break end
                    end
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
