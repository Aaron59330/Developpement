-- ═══════════════════════════ Moteur d'événements (serveur) ═══════════════════════════
-- Le serveur est maître : il crée les entités (véhicules / PNJ), décide des étapes, valide chaque interaction (distance, durée, objet)
-- et verse les récompenses. Les clients n'affichent que (blips, markers, butin local, barres de progression).

local function now() return os.time() end
local function rnd(a, b) if b <= a then return a end return math.random(a, b) end
local function rad(h) return math.rad(h or 0.0) end
local function forward(h) return -math.sin(rad(h)), math.cos(rad(h)) end

-- ─────────────────────────────── Objets / inventaire ───────────────────────────────
local function oxStarted() return GetResourceState('ox_inventory') == 'started' end

function EB.itemCount(xPlayer, name)
    if oxStarted() then
        local ok, c = pcall(function() return exports.ox_inventory:GetItemCount(xPlayer.source, name) end)
        if ok then return tonumber(c) or 0 end
    end
    local it = xPlayer.getInventoryItem and xPlayer.getInventoryItem(name)
    return it and tonumber(it.count) or 0
end

function EB.removeItem(xPlayer, name, n)
    if oxStarted() then
        local ok = pcall(function() exports.ox_inventory:RemoveItem(xPlayer.source, name, n) end)
        if ok then return end
    end
    if xPlayer.removeInventoryItem then xPlayer.removeInventoryItem(name, n) end
end

function EB.addItem(src, xPlayer, name, n)
    if oxStarted() then
        local ok, res = pcall(function() return exports.ox_inventory:AddItem(src, name, n) end)
        if ok and res then return true end
        return false
    end
    if xPlayer.canCarryItem and not xPlayer.canCarryItem(name, n) then return false end
    xPlayer.addInventoryItem(name, n)
    return true
end

-- Verse la récompense : `mult` multiplie les comptes (ex : un sac = 1). Renvoie un texte résumé.
function EB.pay(src, def, mult)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return nil end
    local r = def.reward
    if r.kind == 'account' then
        local amount = math.floor(rnd(r.min, r.max) * (mult or 1))
        if amount > 0 then xPlayer.addAccountMoney(r.account, amount, 'Événement : ' .. def.label) end
        EB.log(def, xPlayer, 'reward', ('%s %d'):format(r.account, amount), amount)
        return ('%d%s'):format(amount, Config.Currency), amount
    end
    local got = {}
    for _, it in ipairs(r.items or {}) do
        if math.random(100) <= (it.chance or 100) then
            local n = rnd(it.min, it.max)
            if EB.addItem(src, xPlayer, it.name, n) then got[#got + 1] = ('%dx %s'):format(n, it.name) end
        end
    end
    local txt = #got > 0 and table.concat(got, ', ') or 'rien d\'utile'
    EB.log(def, xPlayer, 'reward', txt, 0)
    return txt, 0
end

local function notify(src, msg) TriggerClientEvent('esx:showNotification', src, msg) end

-- ─────────────────────────────── Entités ───────────────────────────────
local function waitEntity(e)
    local t = 0
    while (not e or e == 0 or not DoesEntityExist(e)) and t < 40 do Wait(50) t = t + 1 end
    return e and e ~= 0 and DoesEntityExist(e)
end

local function spawnVehicle(run, model, c, h, vtype)
    local e = CreateVehicleServerSetter(joaat(model), vtype or 'automobile', c.x, c.y, c.z, h or 0.0)
    if not waitEntity(e) then return nil end
    run.vehicles[#run.vehicles + 1] = e
    return e
end

local function spawnPed(run, model, c, h)
    local e = CreatePed(4, joaat(model), c.x, c.y, c.z, h or 0.0, true, true)
    if not waitEntity(e) then return nil end
    run.peds[#run.peds + 1] = e
    return e
end

local function netIds(list)
    local out = {}
    for _, e in ipairs(list) do
        if DoesEntityExist(e) then out[#out + 1] = NetworkGetNetworkIdFromEntity(e) end
    end
    return out
end

local function aliveGuards(run)
    local n = 0
    for _, g in ipairs(run.guards) do
        if DoesEntityExist(g) and GetEntityHealth(g) > 0 then n = n + 1 end
    end
    return n
end

local function ring(c, radius, i, n, jitter)
    local a = (i / math.max(1, n)) * math.pi * 2 + math.random() * (jitter or 0.4)
    return { x = c.x + math.cos(a) * radius, y = c.y + math.sin(a) * radius, z = c.z }
end

-- Garde : modèle / arme / précision sont envoyés aux clients (le propriétaire réseau du PNJ le configure)
local function spawnGuards(run, n, c, inVehicle)
    local P = run.def.params
    run.guardCfg = { model = P.guardModel, weapon = P.guardWeapon, accuracy = P.guardAccuracy or 30 }
    for i = 1, n do
        local pos = ring(c, 3.5 + math.random() * 3.0, i, n)
        local ped = spawnPed(run, P.guardModel, pos, math.random(0, 359) + 0.0)
        if ped then
            run.guards[#run.guards + 1] = ped
            if inVehicle and inVehicle[i] and run.truck then
                SetPedIntoVehicle(ped, run.truck, inVehicle[i].seat)
            end
        end
    end
end

-- ─────────────────────────────── Synchronisation ───────────────────────────────
function EB.pub(run)
    local loot = {}
    for _, l in ipairs(run.loot) do
        loot[#loot + 1] = { id = l.id, x = l.x, y = l.y, z = l.z, model = l.model, taken = l.taken == true, secs = l.secs, label = l.label }
    end
    local d = run.def
    return {
        rid = run.rid, defId = run.defId, type = run.type, label = d.label, coords = run.coords, stage = run.stage, stageText = run.stageText,
        endsIn = math.max(0, run.endsAt - now()), unlockIn = run.unlockAt and math.max(0, run.unlockAt - now()) or 0,
        blip = d.blip, vehicles = netIds(run.vehicles), guards = netIds(run.guards), guardCfg = run.guardCfg,
        truck = run.truck and DoesEntityExist(run.truck) and NetworkGetNetworkIdFromEntity(run.truck) or nil,
        wreck = run.wreck and DoesEntityExist(run.wreck) and NetworkGetNetworkIdFromEntity(run.wreck) or nil,
        alerted = run.alerted == true, loot = loot, extra = run.extra, params = { patrol = d.params.patrol, fire = d.params.fire, radius = d.params.radius,
            destRadius = d.params.destRadius, openSeconds = d.params.openSeconds, lootSeconds = d.params.lootSeconds, clerkModel = d.params.clerkModel,
            breachSeconds = d.params.breachSeconds, registerSeconds = d.params.registerSeconds },
        robber = run.robber,
    }
end

function EB.sync(run, target)
    TriggerClientEvent('eventbuilder:client:state', target or -1, EB.pub(run))
end

-- Commerces à braquer (interaction) : envoyés à tous les clients pour afficher le marker / le vendeur
function EB.syncDefs(target)
    local list = {}
    for _, d in pairs(EB.Defs) do
        if d.enabled and d.trigger == 'interact' then
            list[#list + 1] = { id = d.id, label = d.label, type = d.type, locations = d.locations, clerkModel = d.params.clerkModel, aimSeconds = d.params.aimSeconds }
        end
    end
    TriggerClientEvent('eventbuilder:client:defs', target or -1, list)
end

AddEventHandler('eventbuilder:internal:defsChanged', function() EB.syncDefs() end)

AddEventHandler('esx:playerLoaded', function(src)
    SetTimeout(4000, function()
        EB.syncDefs(src)
        for _, run in pairs(EB.Active) do EB.sync(run, src) end
    end)
end)

-- ─────────────────────────────── Alertes ───────────────────────────────
local function policeIds()
    local jobs, ids = {}, {}
    for _, j in ipairs(Config.PoliceJobs) do jobs[j] = true end
    for _, xPlayer in pairs(ESX.GetExtendedPlayers()) do
        if xPlayer.job and jobs[xPlayer.job.name] then ids[#ids + 1] = xPlayer.source end
    end
    return ids
end

function EB.alert(run, coords)
    local d = run.def
    if not d.alert or not d.alert.enabled or run.alertSent then return end
    run.alertSent = true
    SetTimeout((d.alert.delay or 0) * 1000, function()
        local c = coords or run.coords
        for _, id in ipairs(policeIds()) do
            TriggerClientEvent('eventbuilder:client:alert', id, { x = c.x + math.random(-25, 25) + 0.0, y = c.y + math.random(-25, 25) + 0.0, z = c.z, label = d.label, message = d.alert.message })
        end
    end)
end

local function announce(text)
    if text and text ~= '' then TriggerClientEvent('esx:showNotification', -1, text) end
end

-- ─────────────────────────────── Cycle de vie ───────────────────────────────
local TypeStart, TypeTick = {}, {}

local function cleanup(run)
    local list = {}
    for _, e in ipairs(run.peds) do list[#list + 1] = e end
    for _, e in ipairs(run.vehicles) do list[#list + 1] = e end
    for _, e in ipairs(list) do if DoesEntityExist(e) then DeleteEntity(e) end end
    run.peds, run.vehicles = {}, {}
end

function EB.stopRun(rid, reason, keepSeconds)
    local run = EB.Active[rid]
    if not run then return false end
    EB.Active[rid] = nil
    EB.LastEnd[run.defId] = now()
    TriggerClientEvent('eventbuilder:client:end', -1, rid)
    EB.log(run.def, nil, 'end', reason or 'terminé')
    announce(run.def.announce and run.def.announce.finish)
    if keepSeconds and keepSeconds > 0 then
        local snapshot = { peds = run.peds, vehicles = run.vehicles }
        SetTimeout(keepSeconds * 1000, function() cleanup(snapshot) end)
    else
        cleanup(run)
    end
    EB.syncDefs()
    return true
end

function EB.startRun(defId, opts)
    opts = opts or {}
    local def = EB.Defs[tonumber(defId)]
    if not def then return false, 'Événement introuvable' end
    if not opts.force then
        if not def.enabled then return false, 'Événement désactivé' end
        if EB.LastEnd[def.id] and EB.LastEnd[def.id] + (def.cooldown or 0) * 60 > now() then return false, 'Cet événement est en attente (délai de récupération)' end
        if EB.policeCount() < (def.minPolice or 0) then return false, ('Pas assez de policiers en service (%d requis)'):format(def.minPolice) end
        if #GetPlayers() < (def.minPlayers or 0) then return false, 'Pas assez de joueurs connectés' end
    end
    for _, r in pairs(EB.Active) do if r.defId == def.id then return false, 'Cet événement est déjà en cours' end end
    local H = TypeStart[def.type]
    if not H then return false, 'Type non géré' end

    local idx = tonumber(opts.locIdx)
    local loc = (idx and def.locations[idx]) or def.locations[math.random(#def.locations)]
    local rid = EB.NextRid
    EB.NextRid = rid + 1
    local run = {
        rid = rid, defId = def.id, def = EB.copy(def), type = def.type, coords = { x = loc.x, y = loc.y, z = loc.z, h = loc.h or 0.0 },
        stage = 'init', startedAt = now(), endsAt = now() + (def.duration or 20) * 60,
        vehicles = {}, peds = {}, guards = {}, loot = {}, nextLoot = 1, extra = {}, requester = opts.requester,
    }
    EB.Active[rid] = run
    local ok, err = pcall(H, run, opts)
    if not ok then
        print(('^1[eventbuilder] erreur au lancement de « %s » : %s^0'):format(def.label, tostring(err)))
        EB.stopRun(rid, 'erreur de lancement')
        return false, 'Erreur au lancement (voir la console serveur)'
    end
    if run.failed then
        local msg = run.failed
        EB.stopRun(rid, msg)
        return false, msg
    end
    EB.log(def, opts.requester and ESX.GetPlayerFromId(opts.requester) or nil, 'start', loc.label ~= '' and loc.label or ('lieu %s'):format(idx or '?'))
    announce(def.announce and def.announce.start)
    EB.sync(run)
    EB.syncDefs()
    return true, nil, rid
end

local function addLoot(run, x, y, z, model, secs, label)
    local l = { id = run.nextLoot, x = x, y = y, z = z, model = model, secs = secs or 0, taken = false, label = label }
    run.nextLoot = run.nextLoot + 1
    run.loot[#run.loot + 1] = l
    return l
end

local function lootLeft(run)
    local n = 0
    for _, l in ipairs(run.loot) do if not l.taken then n = n + 1 end end
    return n
end

-- ═══════════════════════════ Types ═══════════════════════════
-- 1) Fourgon blindé ──────────────────────────────────────────────────────────
TypeStart.truck = function(run)
    local P, c = run.def.params, run.coords
    run.truck = spawnVehicle(run, P.truckModel, c, c.h)
    if not run.truck then run.failed = ('Modèle de fourgon invalide : %s'):format(P.truckModel) return end
    SetVehicleNumberPlateText(run.truck, ('BRK%04d'):format(math.random(0, 9999)))
    local seats = {}
    if P.patrol then seats = { { seat = -1 }, { seat = 0 } } end
    spawnGuards(run, P.guards or 0, c, seats)
    run.stage, run.stageText = 'fight', 'Neutralisez les gardes'
    run.alerted = false
end

local function truckRear(run)
    if not run.truck or not DoesEntityExist(run.truck) then return nil end
    local p, h = GetEntityCoords(run.truck), GetEntityHeading(run.truck)
    local fx, fy = forward(h)
    return { x = p.x - fx * 4.2, y = p.y - fy * 4.2, z = p.z }
end

TypeTick.truck = function(run)
    local P = run.def.params
    if not run.truck or not DoesEntityExist(run.truck) then
        if run.stage ~= 'done' then EB.stopRun(run.rid, 'fourgon détruit') end
        return
    end
    if run.stage == 'fight' then
        if not run.alerted then
            local tp = GetEntityCoords(run.truck)
            local hurt = GetEntityHealth(run.truck) < (GetEntityMaxHealth(run.truck) - 40)
            for _, g in ipairs(run.guards) do
                if DoesEntityExist(g) and GetEntityHealth(g) < GetEntityMaxHealth(g) then hurt = true end
            end
            if not hurt then
                for _, id in ipairs(GetPlayers()) do
                    local ped = GetPlayerPed(id)
                    if ped and ped ~= 0 and #(GetEntityCoords(ped) - tp) < 30.0 then hurt = true break end
                end
            end
            if hurt then
                run.alerted = true
                EB.alert(run, tp)
                EB.sync(run)
            end
        end
        if run.alerted and aliveGuards(run) == 0 then
            run.stage, run.stageText = 'breach', 'Percez les portes arrière du fourgon'
            EB.sync(run)
        end
    elseif run.stage == 'done' then
        if os.time() >= (run.closeAt or 0) then EB.stopRun(run.rid, 'butin récupéré', 45) end
    end
end

-- 2) Largage ─────────────────────────────────────────────────────────────────
TypeStart.drop = function(run)
    local P, c = run.def.params, run.coords
    local n = P.crates or 3
    for i = 1, n do
        local pos = ring(c, (P.spread or 8) * (0.4 + math.random() * 0.6), i, n)
        addLoot(run, pos.x, pos.y, pos.z, P.crateModel, P.openSeconds or 6, 'Caisse')
    end
    spawnGuards(run, P.guards or 0, c)
    run.unlockAt = now() + (P.unlockSeconds or 0)
    run.stage = (P.unlockSeconds or 0) > 0 and 'wait' or 'loot'
    run.stageText = run.stage == 'wait' and 'Les caisses sont verrouillées…' or 'Ouvrez les caisses'
    EB.alert(run, c)
end

TypeTick.drop = function(run)
    if run.stage == 'wait' and now() >= (run.unlockAt or 0) then
        run.stage, run.stageText = 'loot', 'Ouvrez les caisses'
        EB.sync(run)
    elseif run.stage == 'done' and now() >= (run.closeAt or 0) then
        EB.stopRun(run.rid, 'caisses vidées')
    end
end

-- 3) Épave ───────────────────────────────────────────────────────────────────
TypeStart.crash = function(run)
    local P, c = run.def.params, run.coords
    run.wreck = spawnVehicle(run, P.wreckModel, c, c.h, P.wreckType or 'plane')
    local n = P.crates or 4
    for i = 1, n do
        local pos = ring(c, 4 + (P.spread or 12) * (0.3 + math.random() * 0.7), i, n)
        addLoot(run, pos.x, pos.y, pos.z, P.crateModel, P.openSeconds or 7, 'Caisse')
    end
    spawnGuards(run, P.guards or 0, c)
    run.stage, run.stageText = 'loot', 'Fouillez l\'épave'
    EB.alert(run, c)
end

TypeTick.crash = TypeTick.drop

-- 4) Commerce ────────────────────────────────────────────────────────────────
TypeStart.store = function(run, opts)
    local P, c = run.def.params, run.coords
    local src = opts.requester
    local xPlayer = src and ESX.GetPlayerFromId(src)
    if not xPlayer then run.failed = 'Joueur introuvable' return end
    if (P.requiredItem or '') ~= '' then
        if EB.itemCount(xPlayer, P.requiredItem) < 1 then run.failed = ('Il te faut : %s'):format(P.requiredItem) return end
        if P.consumeItem then EB.removeItem(xPlayer, P.requiredItem, 1) end
    end
    run.robber = src
    run.stage, run.stageText = 'register', 'Le vendeur vide la caisse… ne t\'éloigne pas'
    run.registerEnd = now() + (P.registerSeconds or 20)
    run.endsAt = math.min(run.endsAt, run.registerEnd + 120)
    EB.alert(run, c)
end

TypeTick.store = function(run)
    if run.stage ~= 'register' then return end
    local src = run.robber
    local xPlayer = src and ESX.GetPlayerFromId(src)
    if not xPlayer then return EB.stopRun(run.rid, 'braqueur déconnecté') end
    if EB.distanceTo(src, run.coords) > 14.0 then
        notify(src, '~r~Tu t\'es trop éloigné : le vendeur referme la caisse.')
        return EB.stopRun(run.rid, 'braqueur parti')
    end
    if GetEntityHealth(GetPlayerPed(src)) <= 105 then return EB.stopRun(run.rid, 'braqueur à terre') end
    if now() >= run.registerEnd then
        local txt = EB.pay(src, run.def, 1)
        notify(src, ('~g~Caisse vidée : %s'):format(txt or ''))
        EB.stopRun(run.rid, 'caisse vidée')
    end
end

-- 5) Livraison ───────────────────────────────────────────────────────────────
TypeStart.delivery = function(run)
    local P, c = run.def.params, run.coords
    run.truck = spawnVehicle(run, P.vehicleModel, c, c.h)
    if not run.truck then run.failed = ('Modèle de véhicule invalide : %s'):format(P.vehicleModel) return end
    SetVehicleNumberPlateText(run.truck, ('EVT%04d'):format(math.random(0, 9999)))
    if P.locked then SetVehicleDoorsLocked(run.truck, 2) end
    run.extra.dest = { x = P.destX, y = P.destY, z = P.destZ, r = P.destRadius or 6 }
    run.stage, run.stageText = 'pickup', 'Récupérez le véhicule'
end

TypeTick.delivery = function(run)
    local P = run.def.params
    if not run.truck or not DoesEntityExist(run.truck) or GetEntityHealth(run.truck) <= 0 then
        return EB.stopRun(run.rid, 'véhicule détruit')
    end
    if run.stage == 'pickup' then
        for _, id in ipairs(GetPlayers()) do
            local ped = GetPlayerPed(id)
            if ped and ped ~= 0 and GetVehiclePedIsIn(ped, false) == run.truck and GetPedInVehicleSeat(run.truck, -1) == ped then
                run.robber = tonumber(id)
                run.stage, run.stageText = 'deliver', 'Livrez le véhicule à la destination'
                if P.alertOnTake then EB.alert(run, GetEntityCoords(run.truck)) end
                EB.sync(run)
                break
            end
        end
    elseif run.stage == 'deliver' then
        local src = run.robber
        local d = run.extra.dest
        local vp = GetEntityCoords(run.truck)
        if #(vector3(vp.x, vp.y, vp.z) - vector3(d.x, d.y, d.z)) <= (d.r + 3.0) then
            local ped = src and GetPlayerPed(src)
            if ped and ped ~= 0 and GetVehiclePedIsIn(ped, false) == run.truck then
                local txt = EB.pay(src, run.def, 1)
                notify(src, ('~g~Livraison réussie : %s'):format(txt or ''))
                EB.stopRun(run.rid, 'livré', 5)
            end
        end
    end
end

-- 6) Contrôle de zone ───────────────────────────────────────────────────────
TypeStart.koth = function(run)
    run.scores = {}
    run.extra.radius = run.def.params.radius or 25
    run.extra.hold = run.def.params.holdSeconds or 120
    run.extra.board = {}
    run.stage, run.stageText = 'hold', 'Tenez la zone seul(e)'
    EB.alert(run, run.coords)
end

TypeTick.koth = function(run)
    local P = run.def.params
    local c = run.coords
    local inside = {}
    for _, id in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(id)
        if ped and ped ~= 0 and GetEntityHealth(ped) > 105 and #(GetEntityCoords(ped) - vector3(c.x, c.y, c.z)) <= (P.radius or 25) then
            inside[#inside + 1] = tonumber(id)
        end
    end
    run.extra.contested = #inside > 1
    if #inside == 1 then
        local id = inside[1]
        run.scores[id] = (run.scores[id] or 0) + 1
        if (P.tickReward or 0) > 0 and run.scores[id] % 30 == 0 then
            local xPlayer = ESX.GetPlayerFromId(id)
            if xPlayer then xPlayer.addAccountMoney(run.def.reward.account or 'black_money', P.tickReward, 'Événement : zone') end
        end
        if run.scores[id] >= (P.holdSeconds or 120) then
            local txt = EB.pay(id, run.def, 1)
            notify(id, ('~g~Zone conquise : %s'):format(txt or ''))
            return EB.stopRun(run.rid, 'zone conquise')
        end
    end
    local board = {}
    for id, s in pairs(run.scores) do
        local xp = ESX.GetPlayerFromId(id)
        board[#board + 1] = { name = xp and EB.playerName(xp) or ('#' .. id), score = s }
    end
    table.sort(board, function(a, b) return a.score > b.score end)
    while #board > 5 do board[#board] = nil end
    run.extra.board = board
    if run.tickN == nil then run.tickN = 0 end
    run.tickN = run.tickN + 1
    if run.tickN % 2 == 0 then EB.sync(run) end
end

-- ─────────────────────────────── Boucle principale ───────────────────────────────
CreateThread(function()
    while true do
        Wait(1000)
        for rid, run in pairs(EB.Active) do
            if now() >= run.endsAt then
                EB.stopRun(rid, 'temps écoulé', run.type == 'truck' and 30 or 0)
            else
                local T = TypeTick[run.type]
                if T then
                    local ok, err = pcall(T, run)
                    if not ok then print(('^1[eventbuilder] erreur tick %s : %s^0'):format(run.type, tostring(err))) end
                end
            end
        end
    end
end)

-- ─────────────────────────────── Interactions (ouvrir / percer / ramasser) ───────────────────────────────
-- begin : le serveur contrôle les conditions et mémorise l'heure ; finish : il vérifie la durée et la distance avant de verser le butin.
local function reach(src, c, max)
    return EB.distanceTo(src, c) <= (max or 5.0)
end

ESX.RegisterServerCallback('eventbuilder:begin', function(src, cb, rid, action, arg)
    local run = EB.Active[tonumber(rid)]
    if not run then return cb({ ok = false, error = 'Événement terminé' }) end
    local P = run.def.params
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return cb({ ok = false }) end
    if GetEntityHealth(GetPlayerPed(src)) <= 105 then return cb({ ok = false }) end
    if action == 'breach' and run.type == 'truck' then
        if run.stage ~= 'breach' then return cb({ ok = false, error = 'Neutralise d\'abord les gardes' }) end
        local rear = truckRear(run)
        if not rear or not reach(src, rear, 5.5) then return cb({ ok = false, error = 'Place-toi à l\'arrière du fourgon' }) end
        if (P.requiredItem or '') ~= '' and EB.itemCount(xPlayer, P.requiredItem) < 1 then
            return cb({ ok = false, error = ('Il te faut : %s'):format(P.requiredItem) })
        end
        run.breach = { src = src, t = GetGameTimer() }
        EB.alert(run, rear)
        return cb({ ok = true, seconds = P.breachSeconds or 20 })
    elseif action == 'loot' then
        if run.stage ~= 'loot' then return cb({ ok = false, error = 'Pas encore disponible' }) end
        local l
        for _, x in ipairs(run.loot) do if x.id == tonumber(arg) then l = x end end
        if not l or l.taken then return cb({ ok = false, error = 'Déjà pris' }) end
        if not reach(src, l, 5.0) then return cb({ ok = false, error = 'Trop loin' }) end
        if l.busy and l.busy ~= src and GetGameTimer() - (l.busyT or 0) < ((l.secs or 0) + 4) * 1000 then return cb({ ok = false, error = 'Quelqu\'un le fouille déjà' }) end
        l.busy, l.busyT = src, GetGameTimer()
        run.lootBegin = run.lootBegin or {}
        run.lootBegin[src .. ':' .. l.id] = GetGameTimer()
        return cb({ ok = true, seconds = l.secs or 0 })
    end
    cb({ ok = false, error = 'Action inconnue' })
end)

ESX.RegisterServerCallback('eventbuilder:finish', function(src, cb, rid, action, arg)
    local run = EB.Active[tonumber(rid)]
    if not run then return cb({ ok = false, error = 'Événement terminé' }) end
    local P = run.def.params
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return cb({ ok = false }) end
    if action == 'breach' and run.type == 'truck' then
        local b = run.breach
        if run.stage ~= 'breach' or not b or b.src ~= src then return cb({ ok = false, error = 'Perçage annulé' }) end
        if GetGameTimer() - b.t < ((P.breachSeconds or 20) - 1.5) * 1000 then return cb({ ok = false, error = 'Trop rapide' }) end
        local rear = truckRear(run)
        if not rear or not reach(src, rear, 7.0) then return cb({ ok = false, error = 'Tu t\'es éloigné' }) end
        if (P.requiredItem or '') ~= '' then
            if EB.itemCount(xPlayer, P.requiredItem) < 1 then return cb({ ok = false, error = ('Il te faut : %s'):format(P.requiredItem) }) end
            if P.consumeItem then EB.removeItem(xPlayer, P.requiredItem, 1) end
        end
        -- les sacs apparaissent derrière le fourgon
        local tp, h = GetEntityCoords(run.truck), GetEntityHeading(run.truck)
        local fx, fy = forward(h)
        local n = P.bags or 6
        for i = 1, n do
            local a = (i / n) * math.pi * 2
            local dist = 1.2 + (i % 3) * 0.9
            addLoot(run, rear.x + math.cos(a) * dist - fx * 1.0, rear.y + math.sin(a) * dist - fy * 1.0, tp.z - 0.2, P.bagModel, P.lootSeconds or 3, 'Sac de billets')
        end
        run.breach = nil
        run.stage, run.stageText = 'loot', 'Ramassez les sacs'
        EB.sync(run)
        EB.log(run.def, xPlayer, 'breach', 'portes ouvertes')
        return cb({ ok = true })
    elseif action == 'loot' then
        local l
        for _, x in ipairs(run.loot) do if x.id == tonumber(arg) then l = x end end
        if not l or l.taken then return cb({ ok = false, error = 'Déjà pris' }) end
        local t0 = run.lootBegin and run.lootBegin[src .. ':' .. l.id]
        if not t0 or GetGameTimer() - t0 < ((l.secs or 0) - 1.0) * 1000 then return cb({ ok = false, error = 'Trop rapide' }) end
        if not reach(src, l, 6.0) then return cb({ ok = false, error = 'Trop loin' }) end
        l.taken = true
        run.lootBegin[src .. ':' .. l.id] = nil
        local txt = EB.pay(src, run.def, 1)
        if run.def.reward.kind == 'items' and txt == 'rien d\'utile' then
            notify(src, '~y~Rien d\'utile dans cette caisse…')
        else
            notify(src, ('~g~Butin : %s'):format(txt or ''))
        end
        if lootLeft(run) == 0 then
            run.stage, run.stageText = 'done', 'Butin récupéré'
            run.closeAt = now() + 20
        end
        EB.sync(run)
        return cb({ ok = true })
    end
    cb({ ok = false, error = 'Action inconnue' })
end)

-- Déclenchement par interaction (commerce) : le client envoie l'événement et le lieu ; le serveur revérifie tout
RegisterNetEvent('eventbuilder:server:trigger', function(defId, locIdx)
    local src = source
    local def = EB.Defs[tonumber(defId)]
    if not def or def.trigger ~= 'interact' or not def.enabled then return end
    local loc = def.locations[tonumber(locIdx) or 0]
    if not loc or not reach(src, loc, 12.0) then return end
    local ok, err = EB.startRun(def.id, { locIdx = locIdx, requester = src })
    if not ok then notify(src, '~r~' .. tostring(err)) end
end)

-- ─────────────────────────────── Planification automatique ───────────────────────────────
CreateThread(function()
    while not EB.ready do Wait(500) end
    while true do
        Wait((Config.Auto.CheckSeconds or 60) * 1000)
        if Config.Auto.Enabled and #GetPlayers() >= (Config.Auto.MinPlayers or 1) then
            local running = 0
            for _ in pairs(EB.Active) do running = running + 1 end
            if running < (Config.Auto.MaxConcurrent or 2) and math.random() <= (Config.Auto.Chance or 0.3) then
                local pool = {}
                for _, d in pairs(EB.Defs) do
                    if d.enabled and d.trigger == 'auto' then pool[#pool + 1] = d end
                end
                if #pool > 0 then
                    local d = pool[math.random(#pool)]
                    local ok, err = EB.startRun(d.id, {})
                    if ok then print(('^3[eventbuilder] événement automatique lancé : %s^0'):format(d.label)) end
                end
            end
        end
    end
end)

-- ─────────────────────────────── Administration en direct ───────────────────────────────
ESX.RegisterServerCallback('eventbuilder:start', function(src, cb, id, locIdx)
    if not EB.isAdmin(src) then return cb({ ok = false, error = 'Accès refusé' }) end
    local ok, err, rid = EB.startRun(id, { locIdx = locIdx, force = true, requester = src })
    cb({ ok = ok, error = err, rid = rid })
end)

ESX.RegisterServerCallback('eventbuilder:stop', function(src, cb, rid)
    if not EB.isAdmin(src) then return cb({ ok = false, error = 'Accès refusé' }) end
    cb({ ok = EB.stopRun(tonumber(rid), 'arrêté par un admin') })
end)

ESX.RegisterServerCallback('eventbuilder:active', function(src, cb)
    if not EB.isAdmin(src) then return cb({ ok = false, error = 'Accès refusé' }) end
    local list = {}
    for rid, run in pairs(EB.Active) do
        list[#list + 1] = { rid = rid, defId = run.defId, label = run.def.label, type = run.type, stage = run.stageText or run.stage, endsIn = math.max(0, run.endsAt - now()),
            coords = run.coords, loot = lootLeft(run), guards = aliveGuards(run) }
    end
    table.sort(list, function(a, b) return a.rid < b.rid end)
    cb({ ok = true, list = list })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for rid in pairs(EB.Active) do EB.stopRun(rid, 'ressource arrêtée') end
end)

RegisterCommand('eventstop', function(src, args)
    if src ~= 0 and not EB.isAdmin(src) then return end
    local n = 0
    for rid in pairs(EB.Active) do EB.stopRun(rid, 'arrêt manuel') n = n + 1 end
    print(('[eventbuilder] %d événement(s) arrêté(s)'):format(n))
end, false)
