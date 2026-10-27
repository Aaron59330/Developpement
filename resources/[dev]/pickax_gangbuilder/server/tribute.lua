-- ─────────────────────────────── Zones de tribut ───────────────────────────────
-- Un commerce de la ville est disputé : pendant Config.Tribute.CaptureSeconds, les gangs s'y battent. À la fin on compte les membres VIVANTS de chaque
-- gang dans la zone ; le gang qui en a le plus (égalité : celui qui a été le plus présent) gagne le droit d'aller collecter le tribut au commerce
-- pendant CollectWindow secondes. Tout est calculé côté serveur (positions, vie, distance de collecte) ; le client ne fait qu'afficher.

local Tr = nil   -- { zone, phase = 'fight' | 'collect', endsAt, total, presence = { [gang] = secondes }, counts = { [gang] = n }, winner, notifyAt }
local nextAuto = 0

local function label(name) return GB.Gangs[name] and GB.Gangs[name].label or name end
local function cfg() return Config.Tribute end

-- Décision pure (testée hors jeu) : gang vainqueur d'après les membres vivants, puis la présence cumulée
function GB.tributeDecide(counts, presence, minPer)
    local best, bestN, bestP, tie = nil, 0, 0, false
    for name, n in pairs(counts or {}) do
        local p = (presence or {})[name] or 0
        if n >= (minPer or 1) then
            if n > bestN or (n == bestN and p > bestP) then best, bestN, bestP, tie = name, n, p, false
            elseif n == bestN and p == bestP then tie = true end
        end
    end
    if tie then return nil end
    return best
end

local function inZone(z, c)
    local dx, dy = c.x - z.coords.x, c.y - z.coords.y
    return dx * dx + dy * dy <= z.radius * z.radius and math.abs(c.z - z.coords.z) <= 60.0
end

local function alive(ped) return ped and ped ~= 0 and GetEntityHealth(ped) > 101 end

-- Membres vivants par gang dans la zone
local function countAlive(z)
    local counts = {}
    for src, g in pairs(GB.PlayerGang) do
        local ped = GetPlayerPed(src)
        if alive(ped) and inZone(z, GetEntityCoords(ped)) then counts[g.name] = (counts[g.name] or 0) + 1 end
    end
    return counts
end

local function everyone(fn)
    for src in pairs(GB.PlayerGang) do fn(src) end
end

local function snapshot()
    if not Tr then return nil end
    local z = Tr.zone
    local list = {}
    for name, n in pairs(Tr.counts or {}) do list[#list + 1] = { name = name, label = label(name), count = n } end
    table.sort(list, function(a, b) return a.count > b.count end)
    return { phase = Tr.phase, label = z.label, coords = z.coords, radius = z.radius, collect = z.collect, left = math.max(0, Tr.endsAt - os.time()), total = Tr.total,
        winner = Tr.winner, winnerLabel = Tr.winner and label(Tr.winner) or nil, counts = list }
end

local function push()
    local snap = snapshot()
    everyone(function(src) TriggerClientEvent('gangbuilder:client:tribute', src, snap) end)
end

local function pickZone(name)
    local zones = cfg().Zones or {}
    if name then for _, z in ipairs(zones) do if z.name == name then return z end end return nil end
    if #zones == 0 then return nil end
    return zones[math.random(#zones)]
end

local function gangsOnline()
    local seen, n = {}, 0
    for _, g in pairs(GB.PlayerGang) do if not seen[g.name] then seen[g.name] = true n = n + 1 end end
    return n
end

function GB.startTribute(name)
    local C = cfg()
    if not C.Enabled or Tr then return false, 'busy' end
    local z = pickZone(name)
    if not z then return false, 'zone' end
    Tr = { zone = z, phase = 'fight', total = C.CaptureSeconds, endsAt = os.time() + C.CaptureSeconds, presence = {}, counts = {}, notifyAt = 0 }
    everyone(function(src)
        GB.notify(src, ('~y~Tribut~s~ : les gangs se disputent ~b~%s~s~ ! Tenez la zone %d min avec le plus de survivants.'):format(z.label, math.ceil(C.CaptureSeconds / 60)))
    end)
    if GB.news then GB.news(('Zone de tribut ouverte : %s.'):format(z.label), 'tribute') end
    push()
    return true
end

local function finishFight()
    local C = cfg()
    local winner = GB.tributeDecide(Tr.counts, Tr.presence, C.MinPerGang)
    if winner and not GB.Gangs[winner] then winner = nil end
    if not winner then
        everyone(function(src) GB.notify(src, ('~y~Tribut~s~ : personne n\'a tenu ~b~%s~s~. Aucun tribut cette fois.'):format(Tr.zone.label)) end)
        if GB.news then GB.news(('Tribut de %s : aucun vainqueur.'):format(Tr.zone.label), 'tribute') end
        push(); Tr = nil
        return
    end
    Tr.phase, Tr.winner, Tr.endsAt, Tr.total, Tr.collected = 'collect', winner, os.time() + C.CollectWindow, C.CollectWindow, false
    everyone(function(src)
        local g = GB.PlayerGang[src]
        if g and g.name == winner then GB.notify(src, ('~g~Victoire~s~ ! Allez collecter le tribut chez ~b~%s~s~ (%d min).'):format(Tr.zone.label, math.ceil(C.CollectWindow / 60)))
        else GB.notify(src, ('~y~Tribut~s~ : ~b~%s~s~ remporte ~b~%s~s~ et va collecter.'):format(label(winner), Tr.zone.label)) end
    end)
    if GB.news then GB.news(('%s remporte la zone de tribut %s.'):format(label(winner), Tr.zone.label), 'tribute') end
    push()
end

function GB.stopTribute()
    if not Tr then return false end
    Tr = nil
    everyone(function(src) TriggerClientEvent('gangbuilder:client:tribute', src, nil) end)
    return true
end

-- Collecte : le client demande, le serveur vérifie gang vainqueur, phase, vie et distance
RegisterNetEvent('gangbuilder:tribute:collect', function()
    local src = source
    local C = cfg()
    local g = GB.PlayerGang[src]
    if not Tr or Tr.phase ~= 'collect' or Tr.collected or not g or g.name ~= Tr.winner then return end
    local ped = GetPlayerPed(src)
    if not alive(ped) then return end
    local p, c = GetEntityCoords(ped), Tr.zone.collect or Tr.zone.coords
    local dx, dy, dz = p.x - c.x, p.y - c.y, p.z - c.z
    if dx * dx + dy * dy + dz * dz > (C.CollectDistance + 1.0) ^ 2 then return end
    Tr.collected = true
    local reward = math.floor(tonumber(Tr.zone.reward or C.Reward) or 0)
    if reward > 0 then GB.treasuryAdd(g.name, C.RewardAccount, reward) end
    GB.addRep(g.name, C.RewardRep)
    if GB.questProgress then GB.questProgress(g.name, 'tribute', 1) end
    GB.log(g.name, ESX.GetPlayerFromId(src), 'tribute_collect', ('%s : +%d $'):format(Tr.zone.label, reward))
    for _, s in ipairs(GB.onlineMembers(g.name)) do GB.notify(s, ('~g~Tribut collecté~s~ chez %s : ~g~+%d $~s~ dans la trésorerie.'):format(Tr.zone.label, reward)) end
    if GB.news then GB.news(('%s collecte le tribut de %s (%d $).'):format(label(g.name), Tr.zone.label, reward), 'tribute') end
    Tr = nil
    everyone(function(s) TriggerClientEvent('gangbuilder:client:tribute', s, nil) end)
end)

-- Nouveau joueur / changement de gang : il reçoit l'état courant
AddEventHandler('esx:playerLoaded', function(src) SetTimeout(4000, function() if Tr then TriggerClientEvent('gangbuilder:client:tribute', src, snapshot()) end end) end)

CreateThread(function()
    nextAuto = os.time() + 120
    while true do
        Wait(1000)
        local C, now = cfg(), os.time()
        if Tr then
            if Tr.phase == 'fight' then
                Tr.counts = countAlive(Tr.zone)
                for name, n in pairs(Tr.counts) do Tr.presence[name] = (Tr.presence[name] or 0) + n end
                if now >= Tr.notifyAt then Tr.notifyAt = now + 10 push() end
                if now >= Tr.endsAt then local ok, err = pcall(finishFight) if not ok then Tr = nil print(('^1[gangbuilder] erreur tribut : %s^0'):format(tostring(err))) end end
            elseif now >= Tr.endsAt then
                everyone(function(src) GB.notify(src, ('~y~Tribut~s~ : le tribut de %s n\'a pas été collecté.'):format(Tr.zone.label)) end)
                GB.stopTribute()
            end
        elseif C.Enabled and C.AutoStart and now >= nextAuto then
            nextAuto = now + math.max(5, C.Interval) * 60
            if gangsOnline() >= (C.MinGangsOnline or 2) then GB.startTribute() end
        end
    end
end)

RegisterCommand('starttribute', function(src, args)
    if src ~= 0 and not GB.isDev(src) then return end
    local ok, why = GB.startTribute(args[1])
    local msg = ok and '~g~Zone de tribut lancée.' or (why == 'busy' and '~r~Une zone de tribut est déjà en cours.' or '~r~Zone inconnue.')
    if src == 0 then print((msg:gsub('~.~', ''))) else GB.notify(src, msg) end
end, false)
RegisterCommand('stoptribute', function(src)
    if src ~= 0 and not GB.isDev(src) then return end
    GB.stopTribute()
end, false)

exports('StartTribute', function(name) return GB.startTribute(name) end)
