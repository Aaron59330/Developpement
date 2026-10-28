-- ─────────────────────────────── Équipes de braquage ───────────────────────────────
-- Un chef crée une équipe, invite des joueurs proches et chacun choisit un rôle. Au début d'un braquage, les rôles des membres présents sur place donnent des bonus
-- (coffres plus rapides, plus de butin, alerte police moins probable, plus de temps). Tout est calculé côté serveur (présence, rôles, plafonds).

local Crews, CrewOf, invites = {}, {}, {}   -- Crews[id] = { leader, members = { [src] = role|false } } ; CrewOf[src] = id ; invites[cible] = { crew, expires }
local nextId = 1
local function C() return Config.Crew or {} end

-- Bonus cumulés d'une liste de rôles (un même rôle compte une fois : pas d'empilement)
function IB.crewMods(roleIds)
    local m = { timeMul = 1.0, loot = 0, alert = 0, duration = 0 }
    local seen = {}
    for _, id in ipairs(roleIds or {}) do
        local r = (C().Roles or {})[id]
        if r and not seen[id] then
            seen[id] = true
            if r.timeMul then m.timeMul = m.timeMul * r.timeMul end
            m.loot = m.loot + (r.loot or 0)
            m.alert = m.alert + (r.alert or 0)
            m.duration = m.duration + (r.duration or 0)
        end
    end
    m.timeMul = math.max(tonumber(C().MinTimeMul) or 0.5, m.timeMul)
    m.loot = math.min(tonumber(C().MaxLoot) or 40, m.loot)
    m.alert = math.min(tonumber(C().MaxAlert) or 60, m.alert)
    return m
end

function IB.crewOf(src) return CrewOf[src] and Crews[CrewOf[src]] or nil, CrewOf[src] end

-- Rôles des membres de l'équipe de `src` présents à moins de `radius` m de `src` (le chef du braquage inclus)
function IB.crewRolesNear(src, radius)
    local c = IB.crewOf(src)
    local roles, count = {}, 1
    if not c then return roles, 1 end
    for m, role in pairs(c.members) do
        if m == src then if role then roles[#roles + 1] = role end
        elseif GetPlayerName(m) and IB.distanceTo(m, GetEntityCoords(GetPlayerPed(src))) <= (radius or 40) then
            count = count + 1
            if role then roles[#roles + 1] = role end
        end
    end
    return roles, count
end

local function tell(c, msg) for m in pairs(c.members) do IB.notify(m, msg, 'info') end end
local function size(c) local n = 0 for _ in pairs(c.members) do n = n + 1 end return n end

local function leave(src)
    local c, id = IB.crewOf(src)
    if not c then return end
    c.members[src] = nil CrewOf[src] = nil
    if size(c) == 0 then Crews[id] = nil return end
    if c.leader == src then c.leader = next(c.members) tell(c, ('Le chef a quitté : %s dirige l\'équipe.'):format(GetPlayerName(c.leader) or '?')) else tell(c, (GetPlayerName(src) or 'Un membre') .. ' a quitté l\'équipe.') end
end

local function rolesList()
    local out = {}
    for id, r in pairs(C().Roles or {}) do out[#out + 1] = id .. ' (' .. (r.label or id) .. ')' end
    table.sort(out)
    return table.concat(out, ', ')
end

RegisterCommand(C().Command or 'equipe', function(src, args)
    if src == 0 or not C().Enabled then return end
    local x = ESX.GetPlayerFromId(src)
    if not x then return end
    local sub = tostring(args[1] or '')
    local c = IB.crewOf(src)
    if sub == 'creer' then
        if c then return IB.notify(src, 'Tu es déjà dans une équipe : /equipe quitter', 'error') end
        local id = nextId nextId = nextId + 1
        Crews[id] = { leader = src, members = { [src] = false } } CrewOf[src] = id
        IB.notify(src, 'Équipe créée. /equipe inviter <id> · /equipe role <' .. rolesList() .. '>', 'success')
    elseif sub == 'inviter' then
        if not c or c.leader ~= src then return IB.notify(src, 'Seul le chef peut inviter.', 'error') end
        if size(c) >= (C().MaxMembers or 4) then return IB.notify(src, ('Équipe complète (%d max).'):format(C().MaxMembers or 4), 'error') end
        local t = tonumber(args[2])
        local tx = t and ESX.GetPlayerFromId(t)
        if not tx or t == src or IB.isPoliceJob(tx.job.name) then return IB.notify(src, 'Joueur invalide.', 'error') end
        if CrewOf[t] then return IB.notify(src, 'Cette personne est déjà dans une équipe.', 'error') end
        if IB.distanceTo(t, GetEntityCoords(GetPlayerPed(src))) > (C().InviteDistance or 8.0) then return IB.notify(src, 'Cette personne est trop loin.', 'error') end
        invites[t] = { crew = CrewOf[src], expires = os.time() + 60 }
        IB.notify(src, ('Invitation envoyée à %s.'):format(IB.playerName(tx)), 'info')
        IB.notify(t, ('%s t\'invite dans son équipe : /equipe accepter'):format(IB.playerName(x)), 'warning')
    elseif sub == 'accepter' then
        local inv = invites[src]
        invites[src] = nil
        if not inv or inv.expires < os.time() or not Crews[inv.crew] then return IB.notify(src, 'Aucune invitation valide.', 'error') end
        if c then return IB.notify(src, 'Tu es déjà dans une équipe.', 'error') end
        local cr = Crews[inv.crew]
        if size(cr) >= (C().MaxMembers or 4) then return IB.notify(src, 'Équipe complète.', 'error') end
        cr.members[src] = false CrewOf[src] = inv.crew
        tell(cr, IB.playerName(x) .. ' rejoint l\'équipe.')
    elseif sub == 'role' then
        if not c then return IB.notify(src, 'Tu n\'es dans aucune équipe.', 'error') end
        local role = tostring(args[2] or '')
        if not (C().Roles or {})[role] then return IB.notify(src, 'Rôles : ' .. rolesList(), 'info') end
        for m, r in pairs(c.members) do if r == role and m ~= src then return IB.notify(src, 'Ce rôle est déjà pris.', 'error') end end
        c.members[src] = role
        tell(c, ('%s : %s'):format(IB.playerName(x), C().Roles[role].label or role))
    elseif sub == 'quitter' then
        if not c then return IB.notify(src, 'Tu n\'es dans aucune équipe.', 'error') end
        leave(src) IB.notify(src, 'Tu as quitté l\'équipe.', 'info')
    elseif sub == 'infos' or sub == '' then
        if not c then return IB.notify(src, '/equipe creer · inviter <id> · accepter · role <rôle> · quitter', 'info') end
        for m, r in pairs(c.members) do IB.notify(src, ('%s%s : %s'):format(m == c.leader and '★ ' or '', GetPlayerName(m) or '?', r and ((C().Roles[r] or {}).label or r) or 'sans rôle'), 'info') end
    end
end, false)

AddEventHandler('playerDropped', function() leave(source) invites[source] = nil end)
