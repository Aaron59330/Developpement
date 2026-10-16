-- ─────────────────────────────── Missions « colis » entre gangs ───────────────────────────────
-- 1. Un colis apparaît dans une zone (annonce à tous les gangs, zone visible sur la carte).
-- 2. Le premier gang qui le ramasse doit RESTER dans la zone `hold` secondes avec le colis. Le compteur avance même si aucun adversaire
--    ne vient. Si le porteur sort trop longtemps ou meurt hors zone, le colis retourne au centre ; s'il meurt dans la zone, il tombe sur place.
--    Un autre gang qui le ramasse doit refaire tout le temps de zone.
-- 3. Temps écoulé : le porteur doit ramener le colis à SON coffre de gang (position du porteur visible par les autres gangs).
--    S'il meurt en chemin, le colis tombe : n'importe quel gang peut le ramasser (et doit alors le livrer à son propre coffre).
-- 4. Livraison : récompense dans la trésorerie du gang + réputation. Tout est calculé côté serveur.

local function fail(msg) return { ok = false, error = msg } end

local O = nil                                   -- mission en cours
local nextAuto = os.time() + 60

local function vec(c) return { x = c.x + 0.0, y = c.y + 0.0, z = c.z + 0.0 } end
local function dist3(a, b) local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z return math.sqrt(dx * dx + dy * dy + dz * dz) end
local function label(name) return GB.Gangs[name] and GB.Gangs[name].label or name end

local function inZone(c)
    local dx, dy = c.x - O.zone.x, c.y - O.zone.y
    return dx * dx + dy * dy <= O.radius * O.radius and math.abs(c.z - O.zone.z) <= 60.0
end

local function pedOf(src)
    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 then return ped end
end

-- Coffre de gang le plus proche (type de point « stash ») d'une position
local function nearestStash(gangName, from)
    local best, bd
    for _, p in pairs(GB.Points) do
        if p.gang_name == gangName and p.type == 'stash' and p.coords and p.coords.x then
            local d = dist3(from, p.coords)
            if not bd or d < bd then best, bd = p, d end
        end
    end
    return best, bd
end

local function allMembers()
    local list = {}
    for src in pairs(GB.PlayerGang) do list[#list + 1] = src end
    return list
end

local function announce(msg)
    for _, s in ipairs(allMembers()) do GB.notify(s, msg) end
end

-- Résumé de la mission colis pour la tablette
function GB.objectiveInfo()
    if not O then return { active = false, nextIn = math.max(0, nextAuto - os.time()), auto = Config.Objectives.AutoStart } end
    return { active = true, label = O.label, x = O.zone.x, y = O.zone.y, radius = O.radius, phase = O.phase, reward = O.reward,
        holdLeft = O.holdLeft, holdTotal = O.holdTotal, endsAt = O.endsAt, now = os.time(), carried = O.carrier ~= nil, carrierGang = O.carrierGang and label(O.carrierGang) or nil }
end

-- ─────────────────────────────── Envoi de l'état aux clients ───────────────────────────────
-- throttle : le porteur reçoit l'état chaque seconde, les autres seulement toutes les RevealInterval secondes
local function pushState(throttle)
    if not O then return end
    local carried = O.carrier ~= nil
    local tick = os.time() % math.max(1, math.floor(tonumber(Config.Objectives.RevealInterval) or 5)) == 0
    for _, src in ipairs(allMembers()) do
      if not throttle or tick or O.carrier == src then
        local g = GB.PlayerGang[src]
        local d = {
            active = true, label = O.label, zone = O.zone, radius = O.radius, phase = O.phase,
            pos = (not carried) and O.pos or nil, carried = carried, carrierGang = carried and label(O.carrierGang) or nil,
            holdLeft = O.holdLeft, holdTotal = O.holdTotal, endsAt = O.endsAt, now = os.time(),
            pickup = Config.Objectives.PickupDistance, model = Config.Objectives.Model,
        }
        if carried and O.carrier == src then
            d.me = true
            d.outside = O.outside
            d.leaveGrace = Config.Objectives.LeaveGrace
            if O.phase == 'deliver' then
                local st = nearestStash(g.name, O.lastPos or O.zone)
                if st then d.deliver = vec(st.coords) end
            end
        elseif carried and O.phase == 'deliver' and Config.Objectives.RevealCarrier and g.name ~= O.carrierGang then
            d.reveal = O.lastPos
        end
        TriggerClientEvent('gangbuilder:client:obj', src, d)
      end
    end
end

local function stop(reason)
    if not O then return end
    O = nil
    nextAuto = os.time() + math.max(5, Config.Objectives.Interval) * 60
    for _, src in ipairs(allMembers()) do TriggerClientEvent('gangbuilder:client:obj', src, { active = false }) end
    if reason then announce(reason) end
end

-- ─────────────────────────────── Démarrage ───────────────────────────────
local function startMission(zone)
    local C = Config.Objectives
    if not C.Enabled then return false, 'Les missions colis sont désactivées' end
    if O then return false, 'Une mission est déjà en cours' end
    local hold = math.floor(tonumber(zone.hold) or C.Hold)
    O = {
        name = zone.name, label = zone.label or zone.name, zone = vec(zone.coords), radius = (zone.radius or 40.0) + 0.0,
        pos = vec(zone.coords), phase = 'hold', carrier = nil, carrierGang = nil, lastGang = nil,
        holdTotal = hold, holdLeft = hold, outside = 0, endsAt = os.time() + math.floor(C.Duration * 60),
        reward = math.floor(tonumber(zone.reward) or C.Reward),
    }
    announce(('~y~Colis~s~ repéré : ~b~%s~s~ ! Le premier gang à le prendre doit tenir la zone %d s, puis le ramener à son coffre.'):format(O.label, hold))
    pushState()
    return true
end

local function dropCarrier(reason)
    if not O or not O.carrier then return end
    local src = O.carrier
    local pos = O.lastPos or O.zone
    O.carrier, O.carrierGang, O.outside = nil, nil, 0
    if O.phase == 'hold' and not inZone(pos) then pos = O.zone end   -- hors zone : retour au centre
    O.pos = vec(pos)
    if src and reason then GB.notify(src, reason) end   -- reason = nil : porteur déconnecté
    announce(('Le colis est tombé à ~b~%s~s~ : il peut être ramassé !'):format(O.label))
end

local function deliver(src, g)
    local C = Config.Objectives
    local reward = O.reward
    local account = C.RewardAccount == 'money' and 'money' or 'dirty'
    if not GB.treasuryAdd(g.name, account, reward) and reward > 0 then   -- gang supprimé entre-temps : pas de livraison
        return dropCarrier('~r~Votre gang n\'existe plus : livraison impossible.')
    end
    GB.addRep(g.name, C.RewardRep)
    if GB.questProgress then GB.questProgress(g.name, 'objective', 1) end
    if GB.news then GB.news(('%s a livré le colis « %s » à son coffre.'):format(label(g.name), O.label), 'objective') end
    GB.log(g.name, ESX.GetPlayerFromId(src), 'objective_delivered', ('%s : %d$'):format(O.label, reward))
    stop(('~g~%s~s~ a livré le colis ~b~%s~s~ à son coffre (~g~+%d$~s~).'):format(label(g.name), O.label, reward))
end

-- ─────────────────────────────── Ramasser le colis ───────────────────────────────
ESX.RegisterServerCallback('gangbuilder:obj:pickup', function(src, cb)
    local g = GB.PlayerGang[src]
    if not O then return cb(fail('Aucune mission en cours')) end
    if not g then return cb(fail('Réservé aux membres d\'un gang')) end
    if O.carrier then return cb(fail('Le colis est déjà porté')) end
    local ped = pedOf(src)
    if not ped or GetEntityHealth(ped) <= 0 then return cb(fail('Impossible')) end
    local pos = GetEntityCoords(ped)
    if dist3(pos, O.pos) > Config.Objectives.PickupDistance + 1.5 then return cb(fail('Tu es trop loin du colis')) end
    if not nearestStash(g.name, pos) then return cb(fail('Ton gang n\'a pas de coffre où livrer le colis')) end
    O.carrier, O.carrierGang = src, g.name
    O.lastPos = vec(pos)
    O.outside = 0
    if O.phase == 'hold' and O.lastGang ~= g.name then O.holdLeft = O.holdTotal end   -- un nouveau gang refait le temps de zone
    O.lastGang = g.name
    announce(('~r~%s~s~ a pris le colis ~b~%s~s~ !'):format(label(g.name), O.label))
    if O.phase == 'hold' then
        GB.notify(src, ('Restez dans la zone ~y~%d s~s~ avec le colis.'):format(O.holdLeft))
    else
        GB.notify(src, '~g~ Ramenez le colis à votre coffre de gang !')
    end
    pushState()
    cb({ ok = true })
end)

-- ─────────────────────────────── Boucle principale ───────────────────────────────
CreateThread(function()
    while true do
        Wait(1000)
        local C = Config.Objectives
        if not C.Enabled then
            if O then stop('La mission colis a été annulée.') end
        elseif O then
            local now = os.time()
            if now >= O.endsAt then
                stop('~r~Le colis a disparu : mission terminée sans vainqueur.')
            elseif O.carrier then
                local src = O.carrier
                local g, ped = GB.PlayerGang[src], pedOf(src)
                if not g or not GB.Gangs[g.name] or g.name ~= O.carrierGang or not ped then
                    dropCarrier('~r~Vous avez perdu le colis.')
                elseif GetEntityHealth(ped) <= 0 then
                    local c = GetEntityCoords(ped)
                    O.lastPos = vec(c)
                    dropCarrier('~r~Vous êtes tombé : le colis est au sol.')
                else
                    local c = GetEntityCoords(ped)
                    O.lastPos = vec(c)
                    if O.phase == 'hold' then
                        if inZone(c) then
                            O.outside = 0
                            O.holdLeft = O.holdLeft - 1
                            if O.holdLeft <= 0 then
                                O.phase = 'deliver'
                                GB.notify(src, '~g~ Zone tenue ! Ramenez maintenant le colis à votre coffre de gang.')
                                announce(('~r~%s~s~ a tenu la zone ~b~%s~s~ et file vers son coffre : arrêtez-les !'):format(label(O.carrierGang), O.label))
                            end
                        else
                            O.outside = O.outside + 1
                            if O.outside == 1 then GB.notify(src, '~r~Vous quittez la zone : revenez vite avec le colis !') end
                            if O.outside >= C.LeaveGrace then
                                O.pos = vec(O.zone)
                                O.carrier, O.carrierGang, O.outside = nil, nil, 0
                                GB.notify(src, '~r~Vous êtes resté trop longtemps hors zone : le colis est retourné au centre.')
                                announce(('Le colis est retourné au centre de ~b~%s~s~.'):format(O.label))
                            end
                        end
                    else
                        local st, d = nearestStash(g.name, c)
                        if st and d <= C.DeliverDistance then
                            deliver(src, g)
                        end
                    end
                end
                if O then pushState(true) end
            else
                if now % 5 == 0 then pushState() end
            end
        elseif C.AutoStart and os.time() >= nextAuto and #C.Zones > 0 then
            local gangs, n = {}, 0
            for _, g in pairs(GB.PlayerGang) do
                if not gangs[g.name] then gangs[g.name] = true n = n + 1 end
            end
            if n >= C.MinGangsOnline then
                startMission(C.Zones[math.random(#C.Zones)])
            else
                nextAuto = os.time() + 120
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    if O and O.carrier == source then dropCarrier(nil) pushState() end
end)

-- Un joueur qui (re)charge reçoit l'état de la mission en cours
RegisterNetEvent('gangbuilder:server:objSync', function()
    if O then pushState() end
end)

-- ─────────────────────────────── Commandes staff ───────────────────────────────
RegisterCommand('gbobjective', function(src, args)
    if not GB.isDev(src) then return end
    local C = Config.Objectives
    local zone
    for _, z in ipairs(C.Zones) do if z.name == args[1] then zone = z end end
    zone = zone or C.Zones[math.random(#C.Zones)]
    if not zone then return GB.notify(src, '~r~Aucune zone dans Config.Objectives.Zones.') end
    local ok, err = startMission(zone)
    if not ok and src ~= 0 then GB.notify(src, '~r~' .. err) end
end, false)

RegisterCommand('gbobjstop', function(src)
    if not GB.isDev(src) then return end
    stop('La mission colis a été arrêtée par le staff.')
end, false)

exports('StartObjective', function(name)
    for _, z in ipairs(Config.Objectives.Zones) do if z.name == name then return startMission(z) end end
    return false
end)

-- État de la mission en cours (pour d'autres scripts : HUD, logs…) : nil si aucune
exports('GetObjective', function()
    if not O then return nil end
    return { name = O.name, label = O.label, phase = O.phase, carrier = O.carrier, carrierGang = O.carrierGang, holdLeft = O.holdLeft, holdTotal = O.holdTotal, endsAt = O.endsAt, pos = O.pos, outside = O.outside }
end)
