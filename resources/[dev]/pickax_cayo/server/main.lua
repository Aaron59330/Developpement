ESX = exports['es_extended']:getSharedObject()
local C = Config

local parties, memberOf, lastRun, invites = {}, {}, {}, {}     -- parties[chef] = party · memberOf[src] = chef · lastRun[identifier] = fin du dernier braquage
local function notify(src, msg) TriggerClientEvent('esx:showNotification', src, msg) end
local function byId(list, id) for _, v in ipairs(list) do if v.id == id then return v end end end
local function isStaff(src) local x = ESX.GetPlayerFromId(src) return x and C.AdminGroups[x.getGroup()] == true end
local function money(n) return ESX.Math and ESX.Math.GroupDigits and ESX.Math.GroupDigits(math.floor(n)) or tostring(math.floor(n)) end

local function partyOf(src) local l = memberOf[src] return l and parties[l] end
local function ensureParty(src)
    local p = partyOf(src)
    if p then return p end
    local x = ESX.GetPlayerFromId(src)
    if not x then return nil end
    p = {
        leader = src, phase = 'plan', order = { src },
        members = { [src] = { name = x.getName and x.getName() or GetPlayerName(src), cut = 100, state = 'lobby', bag = 0, loot = {} } },
        plan = { target = nil, approach = nil, infil = nil, exfil = nil, loadout = nil, difficulty = 'normal', equipment = {} },
        scope = {}, prep = {}, taken = {}, opened = {}, primary = false,
    }
    parties[src], memberOf[src] = p, src
    return p
end

-- ───────── vue envoyée à la tablette ─────────
local function scopeCount(p) local n = 0 for _ in pairs(p.scope) do n = n + 1 end return n end
local function missing(p)
    local out, pl = {}, p.plan
    if not pl.target then out[#out + 1] = 'Choisis la cible principale' end
    if not pl.approach then out[#out + 1] = 'Choisis l\'approche' end
    if not pl.infil then out[#out + 1] = 'Choisis le point d\'infiltration' end
    if not pl.exfil then out[#out + 1] = 'Choisis le point d\'extraction' end
    if not pl.loadout then out[#out + 1] = 'Choisis l\'armement' end
    if scopeCount(p) < C.ScopeRequired then out[#out + 1] = ('Reconnaissances : %d / %d'):format(scopeCount(p), C.ScopeRequired) end
    for id in pairs(pl.equipment) do if not p.prep[id] then out[#out + 1] = 'Matériel à récupérer : ' .. (byId(C.Equipment, id) or { label = id }).label end end
    if #p.order < C.Players.min then out[#out + 1] = 'Équipe incomplète' end
    return out
end

local function view(src)
    local p = ensureParty(src)
    if not p then return nil end
    local members = {}
    for _, id in ipairs(p.order) do local m = p.members[id] members[#members + 1] = { id = id, name = m.name, cut = m.cut, state = m.state, leader = id == p.leader } end
    local x = ESX.GetPlayerFromId(src)
    local cd = 0
    local last = x and lastRun[x.identifier]
    if last then cd = math.max(0, C.Cooldown - (os.time() - last)) end
    return { me = src, leader = p.leader, phase = p.phase, plan = p.plan, members = members, scope = p.scope, prep = p.prep, missing = missing(p), cooldown = cd }
end

local function push(p) for _, id in ipairs(p.order) do TriggerClientEvent('pickax_cayo:sync', id, view(id)) end end

local function xy(c) return { x = c.x, y = c.y } end
local function staticCfg()
    local infils, exfils, scope, zones = {}, {}, {}, {}
    for _, i in ipairs(C.Infiltrations) do infils[#infils + 1] = { id = i.id, label = i.label, x = i.coords.x, y = i.coords.y } end
    for _, i in ipairs(C.Exfils) do exfils[#exfils + 1] = { id = i.id, label = i.label, x = i.coords.x, y = i.coords.y } end
    for _, i in ipairs(C.Scope) do scope[#scope + 1] = { id = i.id, label = i.label } end
    for _, z in ipairs(C.Island.guards) do zones[#zones + 1] = { x = z.coords.x, y = z.coords.y, label = z.label, count = z.count } end
    return {
        targets = C.Targets, loot = C.Loot, approaches = (function() local o = {} for _, a in ipairs(C.Approaches) do o[#o + 1] = { id = a.id, label = a.label, desc = a.desc, skydive = a.skydive } end return o end)(), infils = infils, exfils = exfils, equipment = C.Equipment,
        loadouts = (function() local o = {} for _, l in ipairs(C.Loadouts) do o[#o + 1] = { id = l.id, label = l.label, desc = l.desc } end return o end)(), difficulties = C.Difficulties, scope = scope, fees = C.Fees, hardBonus = C.HardBonus, players = C.Players,
        launchFee = C.LaunchFee, scopeRequired = C.ScopeRequired, bag = C.BagCapacity, vault = xy(C.Island.vault), zones = zones, title = C.Planning.label,
    }
end

-- ───────── ouverture, équipe ─────────
ESX.RegisterServerCallback('pickax_cayo:open', function(src, cb)
    local p = ensureParty(src)
    if not p then return cb(nil) end
    cb({ cfg = staticCfg(), state = view(src) })
end)

RegisterNetEvent('pickax_cayo:set', function(field, value)
    local src = source
    local p = partyOf(src)
    if not p or p.leader ~= src or p.phase ~= 'plan' then return end
    local pl = p.plan
    if field == 'target' and byId(C.Targets, value) then pl.target = value
    elseif field == 'approach' and byId(C.Approaches, value) then pl.approach = value
    elseif field == 'infil' and byId(C.Infiltrations, value) then pl.infil = value
    elseif field == 'exfil' and byId(C.Exfils, value) then pl.exfil = value
    elseif field == 'loadout' and byId(C.Loadouts, value) then pl.loadout = value
    elseif field == 'difficulty' and C.Difficulties[value] then pl.difficulty = value
    elseif field == 'equipment' and byId(C.Equipment, value) then
        if pl.equipment[value] then pl.equipment[value] = nil p.prep[value] = nil else pl.equipment[value] = true end
    else return end
    push(p)
end)

RegisterNetEvent('pickax_cayo:invite', function(target)
    local src = source
    local p = partyOf(src)
    target = tonumber(target)
    if not p or p.leader ~= src or p.phase ~= 'plan' or not target or target == src then return end
    if not ESX.GetPlayerFromId(target) then return notify(src, '~r~Joueur introuvable.') end
    if #p.order >= C.Players.max then return notify(src, '~r~Équipe complète.') end
    if memberOf[target] and #parties[memberOf[target]].order > 1 then return notify(src, '~r~Ce joueur est déjà dans une équipe.') end
    local a, b = GetEntityCoords(GetPlayerPed(src)), GetEntityCoords(GetPlayerPed(target))
    if #(a - b) > 40.0 then return notify(src, '~r~Ce joueur est trop loin.') end
    invites[target] = { leader = src, t = os.time() }
    notify(src, '~g~Invitation envoyée.')
    notify(target, ('~b~%s~s~ t\'invite au braquage de Cayo Perico — appuie sur ~g~Y~s~ (ou /cayoaccept) dans %d s.'):format(p.members[src].name, C.InviteSeconds))
end)

local function dropMember(src, reason)
    local p = partyOf(src)
    if not p then return end
    local m = p.members[src]
    if p.phase == 'finale' and m and m.state == 'island' then m.state = 'left' m.bag = 0 m.loot = {} end
    if p.phase == 'plan' or src == p.leader and p.phase ~= 'finale' then
        -- en préparation : retire le joueur ; si c'est le chef, l'équipe est dissoute
        if src == p.leader then
            for _, id in ipairs(p.order) do memberOf[id] = nil TriggerClientEvent('pickax_cayo:sync', id, nil) end
            parties[src] = nil
            return
        end
        p.members[src] = nil
        for i, id in ipairs(p.order) do if id == src then table.remove(p.order, i) break end end
        memberOf[src] = nil
        local n = #p.order
        for _, id in ipairs(p.order) do p.members[id].cut = math.floor(100 / n) end
        p.members[p.leader].cut = 100 - math.floor(100 / n) * (n - 1)
        TriggerClientEvent('pickax_cayo:sync', src, nil)
        push(p)
    end
    if p.phase == 'finale' then TriggerEvent('pickax_cayo:checkEnd', p.leader) end
end

local function accept(src)
    local inv = invites[src]
    if not inv or os.time() - inv.t > C.InviteSeconds then return notify(src, '~r~Aucune invitation en cours.') end
    invites[src] = nil
    local p = parties[inv.leader]
    if not p or p.phase ~= 'plan' or #p.order >= C.Players.max then return notify(src, '~r~Cette équipe n\'est plus disponible.') end
    if partyOf(src) then dropMember(src) end
    local x = ESX.GetPlayerFromId(src)
    if not x then return end
    p.order[#p.order + 1] = src
    memberOf[src] = p.leader
    p.members[src] = { name = x.getName and x.getName() or GetPlayerName(src), cut = 0, state = 'lobby', bag = 0, loot = {} }
    local n = #p.order
    for _, id in ipairs(p.order) do p.members[id].cut = math.floor(100 / n) end
    p.members[p.leader].cut = 100 - math.floor(100 / n) * (n - 1)
    push(p)
    notify(src, '~g~Tu as rejoint l\'équipe.')
end
RegisterNetEvent('pickax_cayo:accept', function() accept(source) end)
RegisterNetEvent('pickax_cayo:leave', function() dropMember(source) end)

RegisterNetEvent('pickax_cayo:cuts', function(cuts)
    local src = source
    local p = partyOf(src)
    if not p or p.leader ~= src or p.phase ~= 'plan' or type(cuts) ~= 'table' then return end
    local sum = 0
    local new = {}
    for _, id in ipairs(p.order) do
        local v = math.floor(tonumber(cuts[tostring(id)]) or -1)
        if v < 0 or v > 100 then return end
        new[id] = v sum = sum + v
    end
    if sum ~= 100 then return notify(src, '~r~Le total des parts doit faire 100 %.') end
    for id, v in pairs(new) do p.members[id].cut = v end
    push(p)
end)

-- ───────── reconnaissances et matériel (sur le continent) ─────────
RegisterNetEvent('pickax_cayo:prep', function(kind, id)
    local src = source
    local p = partyOf(src)
    if not p or p.phase ~= 'plan' then return end
    local pos = GetEntityCoords(GetPlayerPed(src))
    if kind == 'scope' then
        local s = byId(C.Scope, id)
        if not s or #(pos - s.coords) > 12.0 then return end
        p.scope[id] = true
    elseif kind == 'equip' then
        local pt = C.PrepPoints[id]
        if not pt or not p.plan.equipment[id] or #(pos - pt) > 12.0 then return end
        p.prep[id] = true
    else return end
    push(p)
end)

-- ───────── lancement ─────────
local function policeCount()
    local n = 0
    for _, id in ipairs(GetPlayers()) do local x = ESX.GetPlayerFromId(tonumber(id)) if x and x.job and x.job.name == C.PoliceJob then n = n + 1 end end
    return n
end

local function takeFee(x, amount)
    local cash, bank = x.getAccount('money').money, x.getAccount('bank').money
    if cash + bank < amount then return false end
    local fromCash = math.min(cash, amount)
    if fromCash > 0 then x.removeAccountMoney('money', fromCash) end
    if amount - fromCash > 0 then x.removeAccountMoney('bank', amount - fromCash) end
    return true
end

local function giveLoadout(src, lo)
    for _, it in ipairs(lo.items) do pcall(function() exports.ox_inventory:AddItem(src, it[1], it[2]) end) end
end
local function removeLoadout(src, lo)
    for _, it in ipairs(lo.items) do pcall(function()
        local have = exports.ox_inventory:GetItemCount(src, it[1])
        if have and have > 0 then exports.ox_inventory:RemoveItem(src, it[1], math.min(have, it[2])) end
    end) end
end

local function finish(p, reason)
    if p.phase ~= 'finale' then return end
    p.phase = 'done'
    local tgt = byId(C.Targets, p.plan.target)
    local diff = C.Difficulties[p.plan.difficulty]
    local pool, outs, cutSum = 0, {}, 0
    if p.primary and p.primaryBy and p.members[p.primaryBy] and p.members[p.primaryBy].state == 'out' then pool = pool + tgt.value end
    for _, id in ipairs(p.order) do
        local m = p.members[id]
        if m.state == 'out' then
            outs[#outs + 1] = id
            cutSum = cutSum + m.cut
            for t, n in pairs(m.loot) do pool = pool + (C.Loot[t].value * n * C.Loot[t].units / C.BagCapacity) end
        end
    end
    -- le sac plein vaut la valeur du butin ; un sac partiel vaut sa part
    if p.plan.difficulty == 'hard' then pool = pool * (1 + C.HardBonus) end
    local net = pool * (1 - (C.Fees.pavel + C.Fees.fence) / 100)
    local lo = byId(C.Loadouts, p.plan.loadout)
    for _, id in ipairs(p.order) do
        local x = ESX.GetPlayerFromId(id)
        if lo then removeLoadout(id, lo) end
        local m = p.members[id]
        local pay = 0
        if x and m.state == 'out' and cutSum > 0 then
            pay = math.floor(net * (m.cut > 0 and m.cut or 1) / (cutSum > 0 and cutSum or 1))
            if pay > 0 then x.addAccountMoney(C.PayAccount, pay) end
        end
        TriggerClientEvent('pickax_cayo:result', id, { success = #outs > 0, pay = pay, pool = math.floor(pool), reason = reason, state = m.state, primary = p.primary })
        memberOf[id] = nil
    end
    local leaderX = ESX.GetPlayerFromId(p.leader)
    if leaderX then lastRun[leaderX.identifier] = os.time() end
    print(('^3[pickax_cayo] terminé (%s) : %d évadé(s), butin %s $^0'):format(reason or '?', #outs, money(pool)))
    parties[p.leader] = nil
end

AddEventHandler('pickax_cayo:checkEnd', function(leader)
    local p = parties[leader]
    if not p or p.phase ~= 'finale' then return end
    for _, id in ipairs(p.order) do if p.members[id].state == 'island' then return end end
    finish(p, 'fin')
end)

ESX.RegisterServerCallback('pickax_cayo:launch', function(src, cb)
    local p = partyOf(src)
    if not p or p.leader ~= src or p.phase ~= 'plan' then return cb(false, 'Tu n\'es pas le chef de cette équipe.') end
    local miss = missing(p)
    if #miss > 0 then return cb(false, miss[1]) end
    local x = ESX.GetPlayerFromId(src)
    if lastRun[x.identifier] and os.time() - lastRun[x.identifier] < C.Cooldown then return cb(false, 'Tu dois encore attendre avant de relancer un braquage.') end
    if C.MinPolice > 0 and policeCount() < C.MinPolice then return cb(false, 'Pas assez de policiers en service.') end
    local origin = C.Planning.coords
    for _, id in ipairs(p.order) do
        if #(GetEntityCoords(GetPlayerPed(id)) - origin) > 60.0 then return cb(false, 'Toute l\'équipe doit être au poste de planification.') end
    end
    if not takeFee(x, C.LaunchFee) then return cb(false, ('Frais de lancement : %s $ (en liquide ou en banque).'):format(money(C.LaunchFee))) end

    p.phase, p.startedAt = 'finale', os.time()
    local lo = byId(C.Loadouts, p.plan.loadout)
    local nodes = {}
    for _, n in ipairs(C.Island.loot) do if math.random() < C.Island.LootChance then nodes[#nodes + 1] = { id = n.id, type = n.type, coords = n.coords } end end
    p.nodes = {}
    for _, n in ipairs(nodes) do p.nodes[n.id] = n end
    for _, id in ipairs(p.order) do
        p.members[id].state, p.members[id].bag, p.members[id].loot = 'island', 0, {}
        giveLoadout(id, lo)
        TriggerClientEvent('pickax_cayo:start', id, { leader = p.leader, plan = p.plan, nodes = nodes, duration = C.MaxDuration })
    end
    cb(true)
    SetTimeout(C.MaxDuration * 1000, function() local q = parties[p.leader] if q == p and p.phase == 'finale' then for _, id in ipairs(p.order) do if p.members[id].state == 'island' then p.members[id].state = 'left' TriggerClientEvent('pickax_cayo:forceOut', id) end end finish(p, 'temps écoulé') end end)
end)

-- ───────── sur l'île ─────────
local function member(src)
    local p = partyOf(src)
    if not p or p.phase ~= 'finale' then return end
    local m = p.members[src]
    if m and m.state == 'island' then return p, m end
end
local function near(src, coords, r) return #(GetEntityCoords(GetPlayerPed(src)) - coords) <= r end
local function broadcast(p, ev, ...) for _, id in ipairs(p.order) do TriggerClientEvent(ev, id, ...) end end

RegisterNetEvent('pickax_cayo:obstacle', function(id)
    local src = source
    local p = member(src)
    if not p then return end
    local ob
    for _, o in ipairs(C.Island.obstacles) do if o.id == id then ob = o end end
    if not ob or p.opened[id] or not near(src, ob.coords, 8.0) then return end
    if ob.need and not p.plan.equipment[ob.need] then return notify(src, '~r~Il te manque le matériel nécessaire.') end
    p.opened[id] = true
    broadcast(p, 'pickax_cayo:opened', id)
end)

RegisterNetEvent('pickax_cayo:loot', function(id)
    local src = source
    local p, m = member(src)
    if not p then return end
    local n = p.nodes[id]
    if not n or p.taken[id] or not near(src, n.coords, 6.0) then return end
    local def = C.Loot[n.type]
    if m.bag + def.units > C.BagCapacity then return notify(src, '~r~Ton sac est plein.') end
    p.taken[id] = true
    m.bag = m.bag + def.units
    m.loot[n.type] = (m.loot[n.type] or 0) + 1
    broadcast(p, 'pickax_cayo:taken', id)
    TriggerClientEvent('pickax_cayo:bag', src, m.bag)
end)

RegisterNetEvent('pickax_cayo:primary', function()
    local src = source
    local p = member(src)
    if not p or p.primary or not p.opened.door or not near(src, C.Island.vault, 8.0) then return end
    p.primary, p.primaryBy = true, src
    broadcast(p, 'pickax_cayo:primaryTaken', src)
end)

RegisterNetEvent('pickax_cayo:exfil', function()
    local src = source
    local p, m = member(src)
    if not p then return end
    local ex = byId(C.Exfils, p.plan.exfil)
    if not ex or not near(src, ex.coords, ex.radius + 8.0) then return end
    m.state = 'out'
    TriggerClientEvent('pickax_cayo:out', src)
    TriggerEvent('pickax_cayo:checkEnd', p.leader)
end)

AddEventHandler('esx:onPlayerDeath', function()
    local src = source
    local p, m = member(src)
    if not p then return end
    m.state, m.bag, m.loot = 'dead', 0, {}
    if p.primary and p.primaryBy == src then p.primary = false p.primaryBy = nil broadcast(p, 'pickax_cayo:primaryLost') end
    TriggerEvent('pickax_cayo:checkEnd', p.leader)
end)

AddEventHandler('playerDropped', function()
    local src = source
    invites[src] = nil
    local p = partyOf(src)
    if p and p.phase == 'finale' then
        local m = p.members[src]
        if m and m.state == 'island' then
            m.state, m.bag, m.loot = 'left', 0, {}
            if p.primary and p.primaryBy == src then p.primary = false p.primaryBy = nil end
        end
        TriggerEvent('pickax_cayo:checkEnd', p.leader)
    else dropMember(src) end
end)

RegisterNetEvent('pickax_cayo:alert', function()
    local src = source
    local p = member(src)
    if not p or p.alerted then return end
    p.alerted = true
    broadcast(p, 'pickax_cayo:alerted')
end)

-- une seule machine fait apparaître les gardes d'une zone (la première à s'en approcher)
ESX.RegisterServerCallback('pickax_cayo:zone', function(src, cb, i)
    local p = member(src)
    i = tonumber(i)
    if not p or not i or not C.Island.guards[i] then return cb(false) end
    p.zones = p.zones or {}
    if p.zones[i] then return cb(false) end
    p.zones[i] = src
    cb(true)
end)

-- ───────── staff ─────────
RegisterCommand('cayotp', function(src, args)
    if src == 0 or not isStaff(src) then return end
    local name = tostring(args[1] or '')
    local pts = { planning = C.Planning.coords, vault = C.Island.vault, compound = C.Island.obstacles[1].coords }
    for _, i in ipairs(C.Infiltrations) do pts[i.id] = vec3(i.coords.x, i.coords.y, i.coords.z) end
    for _, s in ipairs(C.Scope) do pts['scope_' .. s.id] = s.coords end
    local c = pts[name]
    if not c then
        local keys = {} for k in pairs(pts) do keys[#keys + 1] = k end table.sort(keys)
        return notify(src, '~y~Points : ~s~' .. table.concat(keys, ', '))
    end
    TriggerClientEvent('pickax_cayo:tp', src, c)
end, false)
RegisterCommand('cayopos', function(src) if src ~= 0 and isStaff(src) then TriggerClientEvent('pickax_cayo:printPos', src) end end, false)
RegisterCommand('cayoreset', function(src, args)
    if src ~= 0 and not isStaff(src) then return end
    local t = tonumber(args[1])
    if t then
        local x = ESX.GetPlayerFromId(t)
        if x then lastRun[x.identifier] = nil end
    else lastRun = {} end
    if src ~= 0 then notify(src, '~g~Délai de relance réinitialisé.') end
end, false)
