-- ─────────────────────────────── Affrontements de territoire ───────────────────────────────
-- Un gang fait une activité illégale (récolte, traitement, vente) sur le territoire d'un autre gang :
--   → le propriétaire est prévenu (notification + zone qui clignote sur la carte) et un affrontement commence ;
--   → chaque kill entre les deux gangs dans la zone rapporte 1 point ;
--   → à la fin, le gang qui a le plus de points gagne (l'intrus capture alors le territoire si Config.Conflicts.WinnerCaptures).
-- Les positions sont lues côté serveur ; seul le killer rapporté par ESX (esx:onPlayerDeath) est fourni par le client.

local Conf = {}   -- [territoire] = { id, owner, intruder, endsAt, scores = { [gang] = n } }
local cool = {}   -- ['<territoire>:<gang>'] = fin du délai

local function inTerritory(t, c)
    local dx, dy = c.x - t.coords.x, c.y - t.coords.y
    return dx * dx + dy * dy <= t.radius * t.radius and math.abs(c.z - t.coords.z) <= 80.0
end

local function territoryAt(c)
    for id, t in pairs(GB.Territories) do
        if inTerritory(t, c) then return id, t end
    end
end

local function label(name) return GB.Gangs[name] and GB.Gangs[name].label or name end

local function members(c)
    local list = {}
    for _, name in ipairs({ c.owner, c.intruder }) do
        for _, s in ipairs(GB.onlineMembers(name)) do list[#list + 1] = s end
    end
    return list
end

local function snapshot(c)
    return {
        id = c.id, ownerLabel = label(c.owner), intruderLabel = label(c.intruder),
        owner = c.scores[c.owner] or 0, intruder = c.scores[c.intruder] or 0,
        left = math.max(0, c.endsAt - os.time()), total = c.total,
    }
end

-- Utilisé par le HUD de zone (server/territories.lua)
function GB.conflictInfo(id)
    local c = Conf[id]
    return c and snapshot(c) or nil
end

local function push(c)
    local snap = snapshot(c)
    for _, s in ipairs(members(c)) do TriggerClientEvent('gangbuilder:client:conflictScore', s, snap) end
end

local function startConflict(src, t, intruder)
    local C = Config.Conflicts
    local c = { id = t.id, owner = t.owner, intruder = intruder, total = C.Duration, endsAt = os.time() + C.Duration, scores = { [t.owner] = 0, [intruder] = 0 } }
    Conf[t.id] = c
    local payload = { id = t.id, label = t.label, coords = t.coords, radius = t.radius, left = C.Duration, blip = C.AlertBlipSeconds, ownerLabel = label(t.owner), intruderLabel = label(intruder) }
    for _, s in ipairs(GB.onlineMembers(t.owner)) do
        payload.role = 'owner'
        TriggerClientEvent('gangbuilder:client:conflict', s, payload)
        GB.notify(s, ('~r~%s~s~ opère sur votre territoire ~y~%s~s~ ! Défendez-le (%d min).'):format(label(intruder), t.label, math.ceil(C.Duration / 60)))
    end
    for _, s in ipairs(GB.onlineMembers(intruder)) do
        payload.role = 'intruder'
        TriggerClientEvent('gangbuilder:client:conflict', s, payload)
        GB.notify(s, ('Vous avez été repérés sur ~y~%s~s~ ! Les ~r~%s~s~ arrivent : tenez la zone %d min.'):format(t.label, label(t.owner), math.ceil(C.Duration / 60)))
    end
    GB.log(intruder, ESX.GetPlayerFromId(src), 'conflict_start', ('%s (propriétaire : %s)'):format(t.label, t.owner))
end

-- Appelé après une activité illégale réussie (récolte, traitement, vente)
function GB.onIllegalActivity(src, kind, point)
    local C = Config.Conflicts
    if not C.Enabled or not (C.Kinds or {})[kind] then return end
    local g = GB.PlayerGang[src]
    local ped = GetPlayerPed(src)
    if not g or not ped or ped == 0 then return end
    local id, t = territoryAt(GetEntityCoords(ped))
    if not t or not t.owner or t.owner == g.name or not GB.Gangs[t.owner] then return end
    if Conf[id] then return end
    if (cool[id .. ':' .. g.name] or 0) > os.time() then return end
    if #GB.onlineMembers(t.owner) == 0 then return end        -- personne à prévenir : pas d'affrontement
    startConflict(src, t, g.name)
end

local function removeRep(name, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount > 0 and Config.Rep.Enabled then
        MySQL.update('UPDATE gangbuilder_gangs SET rep = GREATEST(0, rep - ?) WHERE name = ?', { amount, name })
    end
end

local function resolve(c)
    local C, T = Config.Conflicts, Config.Territories
    local t = GB.Territories[c.id]
    Conf[c.id] = nil
    cool[c.id .. ':' .. c.intruder] = os.time() + C.Cooldown
    local so, si = c.scores[c.owner] or 0, c.scores[c.intruder] or 0
    local intruderWins = si >= C.MinKillsToWin and si > so
    local winner, loser = intruderWins and c.intruder or c.owner, intruderWins and c.owner or c.intruder
    local name = t and t.label or 'le territoire'

    if intruderWins and t and C.WinnerCaptures and t.owner == c.owner then
        if (t.protected_until or 0) > os.time() then
            for _, s in ipairs(members(c)) do GB.notify(s, ('~y~%s~s~ est protégé : l\'affrontement ne change pas le propriétaire.'):format(name)) end
        elseif GB.captureTerritory then
            GB.captureTerritory(t, c.intruder)
        end
    end
    GB.addRep(winner, C.RepWin)
    removeRep(loser, C.RepLoss)
    GB.log(winner, nil, 'conflict_win', ('%s : %d - %d contre %s'):format(name, intruderWins and si or so, intruderWins and so or si, loser))

    for _, s in ipairs(GB.onlineMembers(winner)) do
        GB.notify(s, ('~g~Victoire~s~ sur ~y~%s~s~ (%d - %d) !'):format(name, intruderWins and si or so, intruderWins and so or si))
    end
    for _, s in ipairs(GB.onlineMembers(loser)) do
        GB.notify(s, ('~r~Défaite~s~ sur ~y~%s~s~ (%d - %d).'):format(name, intruderWins and so or si, intruderWins and si or so))
    end
    for _, s in ipairs(GB.onlineMembers(c.owner)) do TriggerClientEvent('gangbuilder:client:conflictEnd', s, c.id) end
    for _, s in ipairs(GB.onlineMembers(c.intruder)) do TriggerClientEvent('gangbuilder:client:conflictEnd', s, c.id) end
end

-- Kills : esx:onPlayerDeath (côté serveur) contient le tueur ; on ne compte que les kills dans la zone, entre les deux gangs
RegisterNetEvent('esx:onPlayerDeath', function(data)
    local victim = source
    if type(data) ~= 'table' or not data.killedByPlayer then return end
    local killer = tonumber(data.killerServerId)
    local vg, kg = GB.PlayerGang[victim], killer and GB.PlayerGang[killer]
    if not vg or not kg or vg.name == kg.name or killer == victim then return end
    local ped = GetPlayerPed(victim)
    if not ped or ped == 0 then return end
    local pos = GetEntityCoords(ped)
    for id, c in pairs(Conf) do
        local t = GB.Territories[id]
        if t and c.scores[vg.name] and c.scores[kg.name] and inTerritory(t, pos) then
            c.scores[kg.name] = c.scores[kg.name] + 1
            push(c)
            return
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        local now = os.time()
        for id, c in pairs(Conf) do
            if not GB.Territories[id] or c.endsAt <= now then
                local ok, err = pcall(resolve, c)
                if not ok then Conf[id] = nil print(('^1[gangbuilder] erreur affrontement : %s^0'):format(tostring(err))) end
            end
        end
    end
end)

-- Test staff : /gbconflict <id territoire> <gang intrus>
RegisterCommand('gbconflict', function(src, args)
    if not GB.isDev(src) then return end
    local t = GB.Territories[tonumber(args[1])]
    local intruder = args[2]
    if not t or not t.owner then return GB.notify(src, '~r~Territoire inconnu ou sans propriétaire.') end
    if not GB.Gangs[intruder] or intruder == t.owner then return GB.notify(src, '~r~Gang intrus invalide.') end
    if Conf[t.id] then return GB.notify(src, '~r~Un affrontement est déjà en cours.') end
    startConflict(src, t, intruder)
end, false)
