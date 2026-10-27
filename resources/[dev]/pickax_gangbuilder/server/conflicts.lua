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
        prep = math.max(0, (c.startsAt or 0) - os.time()), declared = c.declared or false,
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

-- opts (guerre déclarée) : { declared = true, prep = secondes avant le début des points, duration = secondes de dispute }
local function startConflict(src, t, intruder, opts)
    local C = Config.Conflicts
    opts = opts or {}
    local prep, dur = math.max(0, tonumber(opts.prep) or 0), tonumber(opts.duration) or C.Duration
    local c = { id = t.id, owner = t.owner, intruder = intruder, total = dur, startsAt = os.time() + prep, endsAt = os.time() + prep + dur, declared = opts.declared,
        scores = { [t.owner] = 0, [intruder] = 0 } }
    Conf[t.id] = c
    local payload = { id = t.id, label = t.label, coords = t.coords, radius = t.radius, left = prep + dur, blip = C.AlertBlipSeconds, ownerLabel = label(t.owner), intruderLabel = label(intruder) }
    for _, s in ipairs(GB.onlineMembers(t.owner)) do
        payload.role = 'owner'
        TriggerClientEvent('gangbuilder:client:conflict', s, payload)
        if opts.declared then GB.notify(s, ('~r~%s~s~ vous déclare la guerre pour ~y~%s~s~ ! Préparez-vous : début dans %d min, puis %d min de dispute.'):format(label(intruder), t.label, math.ceil(prep / 60), math.ceil(dur / 60)))
        else GB.notify(s, ('~r~%s~s~ opère sur votre territoire ~y~%s~s~ ! Défendez-le (%d min).'):format(label(intruder), t.label, math.ceil(dur / 60))) end
    end
    for _, s in ipairs(GB.onlineMembers(intruder)) do
        payload.role = 'intruder'
        TriggerClientEvent('gangbuilder:client:conflict', s, payload)
        if opts.declared then GB.notify(s, ('Guerre déclarée à ~r~%s~s~ pour ~y~%s~s~ : début dans %d min, puis %d min pour tenir la zone.'):format(label(t.owner), t.label, math.ceil(prep / 60), math.ceil(dur / 60)))
        else GB.notify(s, ('Vous avez été repérés sur ~y~%s~s~ ! Les ~r~%s~s~ arrivent : tenez la zone %d min.'):format(t.label, label(t.owner), math.ceil(dur / 60))) end
    end
    if opts.declared and GB.news then GB.news(('%s déclare la guerre à %s pour %s.'):format(label(intruder), label(t.owner), t.label), 'war') end
    GB.log(intruder, src and ESX.GetPlayerFromId(src) or nil, opts.declared and 'turf_declare' or 'conflict_start', ('%s (propriétaire : %s)'):format(t.label, t.owner))
end

-- Appelé après une activité illégale réussie (récolte, traitement, vente)
function GB.onIllegalActivity(src, kind, point)
    local C = Config.Conflicts
    if not C.Enabled or not Config.Territories.Enabled or not (C.Kinds or {})[kind] then return end
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

-- Utilisable par d'autres ressources (Builder Illégal : récolte / traitement / vente de drogue)
exports('ReportIllegalActivity', function(src, kind) if GB.onIllegalActivity then GB.onIllegalActivity(tonumber(src), tostring(kind), nil) end end)

local function removeRep(name, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount > 0 and Config.Rep.Enabled then
        MySQL.update('UPDATE gangbuilder_gangs SET rep = GREATEST(0, rep - ?) WHERE name = ?', { amount, name })
    end
end

local function endFor(c)
    for _, s in ipairs(GB.onlineMembers(c.owner)) do TriggerClientEvent('gangbuilder:client:conflictEnd', s, c.id) end
    for _, s in ipairs(GB.onlineMembers(c.intruder)) do TriggerClientEvent('gangbuilder:client:conflictEnd', s, c.id) end
end

local function resolve(c)
    local C, T = Config.Conflicts, Config.Territories
    local t = GB.Territories[c.id]
    Conf[c.id] = nil
    cool[c.id .. ':' .. c.intruder] = os.time() + C.Cooldown
    -- un des deux gangs a été supprimé pendant l'affrontement : on l'arrête sans récompense ni capture
    if not GB.Gangs[c.owner] or not GB.Gangs[c.intruder] then return endFor(c) end
    local so, si = c.scores[c.owner] or 0, c.scores[c.intruder] or 0
    local TW = Config.TurfWar or {}
    local minKills = c.declared and (TW.MinKillsToWin or C.MinKillsToWin) or C.MinKillsToWin
    local intruderWins = si >= minKills and si > so
    local winner, loser = intruderWins and c.intruder or c.owner, intruderWins and c.owner or c.intruder
    local name = t and t.label or 'le territoire'

    if intruderWins and t and C.WinnerCaptures and t.owner == c.owner then
        if (t.protected_until or 0) > os.time() then
            for _, s in ipairs(members(c)) do GB.notify(s, ('~y~%s~s~ est protégé : l\'affrontement ne change pas le propriétaire.'):format(name)) end
        elseif GB.captureTerritory then
            local can, why = true, nil
            if GB.canCapture then can, why = GB.canCapture(t, c.intruder) end
            if can then GB.captureTerritory(t, c.intruder)
            else
                local reason = why == 'cap' and 'limite de territoires atteinte' or why == 'closed' and 'capture fermée à cette heure' or 'aucun défenseur connecté'
                for _, s in ipairs(members(c)) do GB.notify(s, ('~y~%s~s~ ne change pas de propriétaire (%s).'):format(name, reason)) end
            end
        end
    end
    if GB.questProgress and (intruderWins and si or so) > 0 then GB.questProgress(winner, 'conflict_win', 1) end
    if GB.news and (intruderWins and si or so) > 0 then GB.news(('%s l\'emporte contre %s à %s (%d - %d).'):format(label(winner), label(loser), name, intruderWins and si or so, intruderWins and so or si), 'conflict') end
    if (intruderWins and si or so) > 0 then GB.addRep(winner, c.declared and (TW.RepWin or C.RepWin) or C.RepWin) end   -- pas de réputation sur un 0-0 (anti-farm)
    removeRep(loser, c.declared and (TW.RepLoss or C.RepLoss) or C.RepLoss)
    GB.log(winner, nil, 'conflict_win', ('%s : %d - %d contre %s'):format(name, intruderWins and si or so, intruderWins and so or si, loser))

    for _, s in ipairs(GB.onlineMembers(winner)) do
        GB.notify(s, ('~g~Victoire~s~ sur ~y~%s~s~ (%d - %d) !'):format(name, intruderWins and si or so, intruderWins and so or si))
    end
    for _, s in ipairs(GB.onlineMembers(loser)) do
        GB.notify(s, ('~r~Défaite~s~ sur ~y~%s~s~ (%d - %d).'):format(name, intruderWins and so or si, intruderWins and si or so))
    end
    endFor(c)
end

-- Kills : esx:onPlayerDeath (côté serveur) contient le tueur ; on ne compte que les kills dans la zone, entre les deux gangs
-- L'event vient du client de la victime (non fiable) : on vérifie côté serveur que les deux joueurs sont dans la zone et on ignore les doublons
local lastDeath = {}   -- [victime] = os.time() du dernier kill compté
AddEventHandler('playerDropped', function() lastDeath[source] = nil end)

RegisterNetEvent('esx:onPlayerDeath', function(data)
    local victim = source
    if type(data) ~= 'table' or not data.killedByPlayer then return end
    local killer = tonumber(data.killerServerId)
    local vg, kg = GB.PlayerGang[victim], killer and GB.PlayerGang[killer]
    if not vg or not kg or vg.name == kg.name or killer == victim then return end
    if next(Conf) == nil or (lastDeath[victim] or 0) + 10 > os.time() then return end
    local ped, kped = GetPlayerPed(victim), GetPlayerPed(killer)
    if not ped or ped == 0 or not kped or kped == 0 then return end
    local pos, kpos = GetEntityCoords(ped), GetEntityCoords(kped)
    for id, c in pairs(Conf) do
        local t = GB.Territories[id]
        if t and (c.startsAt or 0) <= os.time() and c.scores[vg.name] and c.scores[kg.name] and inTerritory(t, pos) and inTerritory(t, kpos) then
            lastDeath[victim] = os.time()
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
            if not GB.Territories[id] or c.endsAt <= now or not GB.Gangs[c.owner] or not GB.Gangs[c.intruder] then
                local ok, err = pcall(resolve, c)
                if not ok then Conf[id] = nil print(('^1[gangbuilder] erreur affrontement : %s^0'):format(tostring(err))) end
            end
        end
    end
end)

-- ─────────────────────────────── Guerre de zone déclarée ───────────────────────────────
local turfCool = {}   -- ['<territoire>:<gang>'] = fin du délai

-- Peut-on déclarer la guerre à ce territoire ? → ok, raison ('off' | 'noowner' | 'own' | 'busy' | 'cool' | 'prot' | 'def' | 'att' | 'closed' | 'cap')
function GB.turfCheck(t, gangName)
    local TW = Config.TurfWar or {}
    if not TW.Enabled or not Config.Territories.Enabled then return false, 'off' end
    if not t or not t.owner or not GB.Gangs[t.owner] then return false, 'noowner' end
    if t.owner == gangName then return false, 'own' end
    if Conf[t.id] then return false, 'busy' end
    if (turfCool[t.id .. ':' .. gangName] or 0) > os.time() then return false, 'cool' end
    if not TW.AllowProtected and (t.protected_until or 0) > os.time() then return false, 'prot' end
    if #GB.onlineMembers(t.owner) < (TW.MinDefenders or 1) then return false, 'def' end
    if #GB.onlineMembers(gangName) < (TW.MinAttackers or 1) then return false, 'att' end
    if GB.canCapture then
        local can, why = GB.canCapture(t, gangName)
        if not can and (why == 'closed' or why == 'cap') then return false, why end
    end
    return true
end

function GB.startTurfWar(src, id, gangName)
    local t = GB.Territories[tonumber(id)]
    if not t then return false, 'unknown' end
    local ok, why = GB.turfCheck(t, gangName)
    if not ok then return false, why end
    local TW = Config.TurfWar
    turfCool[t.id .. ':' .. gangName] = os.time() + (TW.Cooldown or 1800)
    startConflict(src, t, gangName, { declared = true, prep = TW.PrepSeconds or 120, duration = TW.Duration or 600 })
    return true
end

GB.TurfReasons = { off = 'Les guerres de zone sont désactivées', noowner = 'Ce territoire n\'a pas de propriétaire : capture-le simplement', own = 'Ce territoire est déjà à vous',
    busy = 'Une guerre est déjà en cours sur cette zone', cool = 'Vous avez déjà déclaré la guerre sur cette zone récemment', prot = 'Ce territoire est encore protégé',
    def = 'Aucun défenseur connecté', att = 'Pas assez de membres de ton gang en ligne', closed = 'Capture fermée à cette heure', cap = 'Limite de territoires atteinte pour votre gang', unknown = 'Territoire inconnu' }

-- Commande joueur : /startturfwar <id du territoire> (bureau du gang)
CreateThread(function()
    local cmd = (Config.TurfWar or {}).Command
    if not cmd or cmd == '' then return end
    RegisterCommand(cmd, function(src, args)
        if src == 0 then return end
        local gang, grade = GB.gangOf(src)
        if not gang then return GB.notify(src, '~r~Tu n\'es dans aucun gang.') end
        if grade < (gang.boss_grade or 0) then return GB.notify(src, '~r~Réservé au bureau du gang.') end
        local ok, why = GB.startTurfWar(src, args[1], gang.name)
        if not ok then GB.notify(src, '~r~' .. (GB.TurfReasons[why] or 'Impossible')) end
    end, false)
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
