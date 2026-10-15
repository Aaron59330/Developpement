-- ─────────────────────────────── Braquages ───────────────────────────────
local Active = {}      -- [eid] = { owner, endsAt, done = { [pi] = true }, total, finished }
local UNARMED = -1569615261
local ACCOUNT = { black_money = 'black_money', money = 'money', bank = 'bank' }

local TARGET_KINDS = { register = true, safe = true, vault = true, loot = true }

local function stateOf(eid)
    local a = Active[eid]
    if not a then return nil end
    return { owner = a.owner, endsAt = a.endsAt - os.time(), done = a.done, coop = a.coop }
end

local function broadcast(eid)
    TriggerClientEvent('worldbuilder:client:robState', -1, eid, stateOf(eid))
end

function WB.syncRobberies(src)
    local list = {}
    for eid in pairs(Active) do list[#list + 1] = { eid = eid, state = stateOf(eid) } end
    TriggerClientEvent('worldbuilder:client:robStates', src, list)
end

local function endRobbery(eid, reason)
    local a = Active[eid]
    if not a then return end
    Active[eid] = nil
    broadcast(eid)
    local e = WB.Entities[eid]
    if e then WB.log(e, nil, 'rob_end', reason or 'terminé') end
    if a.owner then WB.notify(a.owner, 'Le braquage est terminé.', 'info') end
end

local function targetCount(e)
    local n = 0
    for _, p in ipairs(e.points) do if TARGET_KINDS[p.kind] and p.coords then n = n + 1 end end
    return n
end

local function center(e)
    for _, kind in ipairs({ 'clerk', 'start' }) do
        for _, p in ipairs(e.points) do if p.kind == kind and p.coords then return p.coords end end
    end
    for _, p in ipairs(e.points) do if p.coords then return p.coords end end
end

local function cooldownLeft(e)
    return math.max(0, (WB.State['rob:' .. e.id] or 0) - os.time())
end

-- ═══════════════ Démarrage ═══════════════
ESX.RegisterServerCallback('worldbuilder:rob:start', function(src, cb, eid, pi)
    local e = WB.Entities[tonumber(eid) or 0]
    local xPlayer = ESX.GetPlayerFromId(src)
    if not e or e.type ~= 'robbery' or not e.enabled or not xPlayer then return cb({ ok = false, error = 'Introuvable' }) end
    local s = e.settings
    local p = e.points[tonumber(pi) or 0]
    local wantKind = s.trigger == 'interact' and 'start' or 'clerk'
    if not p or p.kind ~= wantKind or not p.coords or not WB.near(src, p.coords, 8.0) then return cb({ ok = false, error = 'Trop loin' }) end
    local ok, err = WB.hasAccess(xPlayer, s.access)
    if not ok then return cb({ ok = false, error = err }) end
    if Active[e.id] then return cb({ ok = false, error = 'Un braquage est déjà en cours ici' }) end
    if targetCount(e) == 0 then return cb({ ok = false, error = 'Ce braquage n\'a aucune cible configurée' }) end
    if WB.isPoliceJob(xPlayer.job.name) then return cb({ ok = false, error = 'Tu ne peux pas braquer en tant que policier' }) end
    local left = cooldownLeft(e)
    if left > 0 then return cb({ ok = false, error = ('Rien à voler pour le moment (revenez dans %d min)'):format(math.ceil(left / 60)) }) end
    if (s.copsRequired or 0) > 0 and WB.copCount() < s.copsRequired then return cb({ ok = false, error = 'Pas assez de policiers en service' }) end
    if s.weapon and GetSelectedPedWeapon(GetPlayerPed(src)) == UNARMED then return cb({ ok = false, error = 'Il te faut une arme en main' }) end
    local req = s.requireItem
    if req and req.item ~= '' and WB.itemCount(src, req.item) < (req.count or 1) then return cb({ ok = false, error = 'Il te faut : ' .. req.item }) end
    if req and req.item ~= '' and req.consume then WB.removeItem(src, req.item, req.count or 1) end

    Active[e.id] = { owner = src, endsAt = os.time() + (s.duration or 240), done = {}, coop = s.coop ~= false, total = targetCount(e) }
    WB.setState('rob:' .. e.id, os.time() + (s.cooldown or 0) + (s.duration or 0))
    if (s.alert and s.alert.chance or 100) >= math.random(100) then
        WB.alertPolice(p.coords, s.alert and s.alert.label or 'Braquage en cours', ('%s : braquage en cours'):format(e.label))
    end
    WB.stat(e, 'attempts', 1)
    WB.log(e, xPlayer, 'rob_start', e.label)
    broadcast(e.id)
    cb({ ok = true, duration = s.duration, guards = s.guards, leave = s.leaveDistance })
end)

-- ═══════════════ Cibles (caisse / coffre / vitrine...) ═══════════════
ESX.RegisterServerCallback('worldbuilder:rob:begin', function(src, cb, eid, pi)
    if WB.Pending[src] then return cb({ ok = false, error = 'Action déjà en cours' }) end
    local e = WB.Entities[tonumber(eid) or 0]
    local xPlayer = ESX.GetPlayerFromId(src)
    local a = e and Active[e.id]
    if not e or not xPlayer or not a then return cb({ ok = false, error = 'Aucun braquage en cours' }) end
    if a.owner ~= src and not a.coop then return cb({ ok = false, error = 'Tu ne participes pas à ce braquage' }) end
    if WB.isPoliceJob(xPlayer.job.name) then return cb({ ok = false, error = 'Interdit aux policiers' }) end
    pi = tonumber(pi) or 0
    local p = e.points[pi]
    if not p or not TARGET_KINDS[p.kind] or not p.coords or not WB.near(src, p.coords, 3.0) then return cb({ ok = false, error = 'Trop loin' }) end
    if a.done[pi] then return cb({ ok = false, error = 'Déjà vidé' }) end
    if p.tool and p.tool.item ~= '' and WB.itemCount(src, p.tool.item) < 1 then return cb({ ok = false, error = 'Il te faut : ' .. p.tool.item }) end
    a.busy = a.busy or {}
    if a.busy[pi] and a.busy[pi] ~= src and GetGameTimer() < a.busy[pi .. 't'] then return cb({ ok = false, error = 'Quelqu\'un s\'en occupe déjà' }) end
    a.busy[pi], a.busy[pi .. 't'] = src, GetGameTimer() + (p.time or 10) * 1000 + 5000
    WB.beginAct(src, { kind = 'rob', eid = e.id, pi = pi }, p.time or 10)
    cb({ ok = true, seconds = p.time or 10, anim = p.anim, minigame = p.minigame == true, label = p.label ~= '' and p.label or p.kind })
end)

RegisterNetEvent('worldbuilder:server:robFinish', function(done)
    local src = source
    local act, err = WB.endAct(src, 'rob')
    local xPlayer = ESX.GetPlayerFromId(src)
    local e = act and WB.Entities[act.eid]
    local a = e and Active[e.id]
    if not act or not e or not xPlayer or not a then if err then WB.notify(src, err, 'error') end return end
    if a.busy then a.busy[act.pi] = nil end
    if done ~= true then return end
    local p = e.points[act.pi]
    if not p or a.done[act.pi] or not WB.near(src, p.coords, 4.0) then return end
    if p.tool and p.tool.item ~= '' then
        if WB.itemCount(src, p.tool.item) < 1 then return WB.notify(src, 'Il te faut : ' .. p.tool.item, 'error') end
        if p.tool.consume then WB.removeItem(src, p.tool.item, 1) end
    end
    a.done[act.pi] = true

    local cash = 0
    if p.cash and (p.cash.max or 0) > 0 then
        cash = math.random(math.floor(p.cash.min or 0), math.floor(math.max(p.cash.min or 0, p.cash.max)))
        WB.pay(xPlayer, ACCOUNT[e.settings.currency] or 'black_money', cash, 'Braquage : ' .. e.label)
    end
    local got = {}
    for _, it in ipairs(p.items or {}) do
        if math.random(100) <= (it.chance or 100) then
            local n = math.random(it.min or 1, math.max(it.min or 1, it.max or 1))
            if WB.addItem(src, it.item, n) then got[#got + 1] = ('%d× %s'):format(n, it.item)
            else WB.notify(src, 'Inventaire plein : ' .. it.item .. ' perdu', 'error') end
        end
    end
    WB.stat(e, 'revenue', cash)
    WB.log(e, xPlayer, 'rob_loot', ('%s — %s'):format(p.label ~= '' and p.label or p.kind, table.concat(got, ', ')), cash)
    local parts = {}
    if cash > 0 then parts[#parts + 1] = ('%d %s'):format(cash, Config.Currency) end
    for _, g in ipairs(got) do parts[#parts + 1] = g end
    WB.notify(src, #parts > 0 and ('Butin : ' .. table.concat(parts, ', ')) or 'Il n\'y avait rien...', #parts > 0 and 'success' or 'info')

    local n = 0
    for _ in pairs(a.done) do n = n + 1 end
    if n >= a.total then endRobbery(e.id, 'toutes les cibles vidées') else broadcast(e.id) end
end)

-- ═══════════════ Surveillance (durée, éloignement, déconnexion) ═══════════════
CreateThread(function()
    while true do
        Wait(4000)
        for eid, a in pairs(Active) do
            local e = WB.Entities[eid]
            if not e or not e.enabled then endRobbery(eid, 'module désactivé')
            elseif os.time() >= a.endsAt then endRobbery(eid, 'temps écoulé')
            else
                local c = center(e)
                local leave = e.settings.leaveDistance or 30
                local alive = false
                if c then
                    if a.owner and GetPlayerName(a.owner) and WB.distanceTo(a.owner, c) <= leave + 10 then alive = true end
                    if not alive and a.coop then
                        for _, id in ipairs(GetPlayers()) do
                            local pid = tonumber(id)
                            local x = ESX.GetPlayerFromId(pid)
                            if x and not WB.isPoliceJob(x.job.name) and WB.distanceTo(pid, c) <= leave then alive = true break end
                        end
                    end
                end
                if not alive then endRobbery(eid, 'plus personne sur place') end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    for eid, a in pairs(Active) do
        if a.owner == src and not a.coop then endRobbery(eid, 'braqueur déconnecté') end
    end
end)

function WB.onEntityChanged(e, deleted)
    if Active[e.id] and (deleted or not e.enabled) then endRobbery(e.id, deleted and 'module supprimé' or 'module désactivé') end
end
