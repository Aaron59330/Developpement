-- ─────────────────────────────── Convois de gang ───────────────────────────────
-- Le bureau d'un gang lance /convoi : un conducteur du gang doit mener un véhicule jusqu'à la destination avant la fin du temps imparti. Les gangs rivaux voient la zone
-- approximative du convoi ; s'ils restent près du véhicule assez longtemps, ils le détournent et volent une part de la prime. Positions, véhicule et temps : côté serveur.

local Convoy = nil        -- { gang, driver, to, label, reward, startedAt, endsAt, progress, lastPush, route }
local cool = {}           -- [gang] = fin du délai

local function C() return Config.Convoy or {} end
local function dist(a, b) local dx, dy = a.x - b.x, a.y - b.y return math.sqrt(dx * dx + dy * dy) end

-- Progression de l'interception sur une seconde (pure, testée) : monte avec les rivaux proches, redescend sinon
function GB.convoyStep(progress, rivalsNear)
    if rivalsNear > 0 then return progress + 1 end
    return math.max(0, progress - 1)
end

-- Prime : base + prime par kilomètre
function GB.convoyReward(distance)
    return math.floor((tonumber(C().BaseReward) or 0) + distance / 1000 * (tonumber(C().PerKm) or 0))
end

-- Part volée par les détourneurs
function GB.convoyLoot(reward) return math.floor(reward * math.max(0, math.min(100, tonumber(C().StealPercent) or 50)) / 100) end

local function driverCoords()
    if not Convoy then return nil end
    local ped = GetPlayerPed(Convoy.driver)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped), ped
end

local function inVehicle(ped)
    if not ped then return false end
    local v = GetVehiclePedIsIn(ped, false)
    return v and v ~= 0
end

local function members(name) return GB.onlineMembers(name) end

local function push()
    if not Convoy then return end
    local pos = driverCoords()
    if not pos then return end
    local snap = { gang = Convoy.gang, label = GB.Gangs[Convoy.gang] and GB.Gangs[Convoy.gang].label or Convoy.gang, coords = { x = pos.x, y = pos.y, z = pos.z },
        to = Convoy.to, endsAt = Convoy.endsAt, progress = Convoy.progress, need = C().InterceptSeconds, reward = Convoy.reward }
    for src, g in pairs(GB.PlayerGang) do
        if g.name == Convoy.gang then TriggerClientEvent('gangbuilder:client:convoy', src, snap, 'owner')
        else
            local approx = { x = pos.x + math.random(-80, 80) + 0.0, y = pos.y + math.random(-80, 80) + 0.0, z = pos.z }
            TriggerClientEvent('gangbuilder:client:convoy', src, { gang = snap.gang, label = snap.label, coords = approx, radius = C().ApproxRadius or 150.0 }, 'rival')
        end
    end
end

local function stop(why)
    if not Convoy then return end
    for src in pairs(GB.PlayerGang) do TriggerClientEvent('gangbuilder:client:convoy', src, nil, why) end
    cool[Convoy.gang] = os.time() + math.floor(tonumber(C().Cooldown) or 1800)
    Convoy = nil
end

function GB.convoyStart(src)
    if not C().Enabled then return false, 'Les convois sont désactivés.' end
    local gang, grade = GB.gangOf(src)
    if not gang then return false, 'Tu n\'es dans aucun gang.' end
    if grade < (gang.boss_grade or 0) then return false, 'Réservé au bureau du gang.' end
    if Convoy then return false, 'Un convoi est déjà en cours sur le serveur.' end
    if (cool[gang.name] or 0) > os.time() then return false, ('Prochain convoi possible dans %d min.'):format(math.ceil((cool[gang.name] - os.time()) / 60)) end
    if #members(gang.name) < (tonumber(C().MinMembers) or 1) then return false, 'Pas assez de membres connectés.' end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or not inVehicle(ped) then return false, 'Monte dans le véhicule du convoi : tu en seras le conducteur.' end
    local routes = C().Routes or {}
    if #routes == 0 then return false, 'Aucun itinéraire configuré.' end
    local from = GetEntityCoords(ped)
    local pick = routes[math.random(#routes)]
    for _ = 1, 10 do local r = routes[math.random(#routes)] if dist(from, r.coords) > dist(from, pick.coords) then pick = r end end
    local d = dist(from, pick.coords)
    local limit = math.max(120, math.floor(d / math.max(1, tonumber(C().AvgSpeed) or 16) * (tonumber(C().TimeMargin) or 1.5)))
    Convoy = { gang = gang.name, driver = src, to = pick.coords, label = pick.label, reward = GB.convoyReward(d), startedAt = os.time(), endsAt = os.time() + limit, progress = 0, lastPush = 0 }
    for _, s in ipairs(members(gang.name)) do GB.notify(s, ('~g~Convoi lancé : rejoignez %s en %d min.'):format(pick.label or 'la destination', math.ceil(limit / 60))) end
    if GB.news then GB.news(('%s lance un convoi.'):format(gang.label), 'territory') end
    push()
    return true
end

local function succeed()
    local gang, reward = Convoy.gang, Convoy.reward
    GB.treasuryAdd(gang, (C().Account == 'money') and 'money' or 'dirty', reward)
    GB.addRep(gang, tonumber(C().RepWin) or 0)
    for _, s in ipairs(members(gang)) do GB.notify(s, ('~g~Convoi livré : +%d $ dans la trésorerie.'):format(reward)) end
    if GB.news then GB.news(('%s a livré son convoi.'):format(GB.Gangs[gang].label), 'territory') end
    stop('win')
end

local function hijack(by)
    local loot = GB.convoyLoot(Convoy.reward)
    local victim = Convoy.gang
    GB.treasuryAdd(by, (C().Account == 'money') and 'money' or 'dirty', loot)
    GB.addRep(by, tonumber(C().RepHijack) or 0)
    for _, s in ipairs(members(victim)) do GB.notify(s, ('~r~Convoi détourné par %s !'):format(GB.Gangs[by].label)) end
    for _, s in ipairs(members(by)) do GB.notify(s, ('~g~Convoi détourné : +%d $ dans la trésorerie.'):format(loot)) end
    if GB.news then GB.news(('%s a détourné le convoi de %s.'):format(GB.Gangs[by].label, GB.Gangs[victim].label), 'territory') end
    stop('hijack')
end

CreateThread(function()
    while true do
        Wait(1000)
        if Convoy then
            local pos, ped = driverCoords()
            local g = GB.PlayerGang[Convoy.driver]
            if not pos or not g or g.name ~= Convoy.gang then
                for _, s in ipairs(members(Convoy.gang)) do GB.notify(s, '~r~Le conducteur a quitté le convoi : échec.') end
                stop('lost')
            elseif os.time() >= Convoy.endsAt then
                for _, s in ipairs(members(Convoy.gang)) do GB.notify(s, '~r~Convoi en retard : le client a annulé.') end
                stop('late')
            elseif inVehicle(ped) and dist(pos, Convoy.to) <= (tonumber(C().ArriveRadius) or 20.0) then
                local ok, err = pcall(succeed)
                if not ok then Convoy = nil print(('^1[gangbuilder] erreur convoi : %s^0'):format(tostring(err))) end
            else
                -- rivaux proches du véhicule : on retient le gang rival le plus présent
                local near, byGang = 0, {}
                for src, gg in pairs(GB.PlayerGang) do
                    if gg.name ~= Convoy.gang then
                        local p = GetPlayerPed(src)
                        if p and p ~= 0 and dist(GetEntityCoords(p), pos) <= (tonumber(C().InterceptRadius) or 25.0) and GetEntityHealth(p) > 0 then
                            near = near + 1 byGang[gg.name] = (byGang[gg.name] or 0) + 1
                        end
                    end
                end
                Convoy.progress = GB.convoyStep(Convoy.progress, near)
                if Convoy.progress >= (tonumber(C().InterceptSeconds) or 30) then
                    local best, bn = nil, 0
                    for name, n in pairs(byGang) do if n > bn then best, bn = name, n end end
                    if best then hijack(best) else Convoy.progress = 0 end
                elseif os.time() - Convoy.lastPush >= 5 then
                    Convoy.lastPush = os.time()
                    push()
                end
            end
        end
    end
end)

RegisterCommand('convoi', function(src)
    if src == 0 then return end
    local ok, err = GB.convoyStart(src)
    if not ok then GB.notify(src, '~r~' .. err) end
end, false)

AddEventHandler('playerDropped', function() end)
function GB.convoyActive() return Convoy ~= nil end
