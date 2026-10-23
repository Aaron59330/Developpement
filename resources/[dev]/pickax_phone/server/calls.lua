local calls, byPlayer, nextId = {}, {}, 0

local function serviceByNumber(n)
    for _, s in ipairs(Config.Services) do if s.number ~= '' and s.number == n then return s end end
end

local function logCall(caller, callee, status, duration, hidden)
    MySQL.insert('INSERT INTO aura_calls (caller, callee, status, duration, hidden) VALUES (?,?,?,?,?)', { caller, callee, status, duration or 0, hidden and 1 or 0 })
end

local function finish(call, reason)
    if call.done then return end
    call.done = true
    local dur = call.answeredAt and (os.time() - call.answeredAt) or 0
    local status = call.answeredAt and 'answered' or (reason == 'declined' and 'declined' or 'missed')
    logCall(call.caller.number, call.callee.number, status, dur, call.hidden)
    for _, side in ipairs({ call.caller, call.callee }) do
        byPlayer[side.src] = nil
        TriggerClientEvent('aura:push', side.src, 'callEnd', { id = call.id, reason = reason, duration = dur, number = side == call.caller and call.callee.number or call.caller.number })
    end
    if status == 'missed' then
        local callerShown = call.hidden and 'Numéro masqué' or call.caller.number
        TriggerClientEvent('aura:push', call.callee.src, 'missedCall', { number = call.hidden and '' or call.caller.number, hidden = call.hidden })
    end
    calls[call.id] = nil
end

lib.callback.register('aura:callStart', function(src, number, hidden)
    local id = Aura.ident[src]; local me = id and Aura.phones[id]
    if not me then return { ok = false, error = 'Téléphone indisponible' } end
    number = Aura.CleanNumber(number)
    if number == '' then return { ok = false, error = 'Numéro invalide' } end
    local svc = serviceByNumber(number)
    if svc then return { ok = true, service = svc.id, label = svc.label } end
    if byPlayer[src] then return { ok = false, error = 'Déjà en appel' } end
    if me.settings.airplane then return { ok = false, error = 'Mode avion activé' } end
    if number == me.number then return { ok = false, error = 'Impossible de s\'appeler soi-même' } end
    if Config.Calls.price > 0 then
        local x = ESX.GetPlayerFromId(src)
        if not x or x.getAccount(Config.Bank.account).money < Config.Calls.price then return { ok = false, error = 'Solde insuffisant' } end
    end
    local tid = Aura.byNumber[number]
    local tsrc = tid and Aura.src[tid]
    nextId = nextId + 1
    local call = { id = nextId, hidden = (hidden and Config.Calls.allowHidden) or me.settings.hideNumber or false,
        caller = { src = src, id = id, number = me.number }, callee = { src = tsrc, id = tid, number = number }, channel = Config.Calls.channelBase + nextId }
    local tp = tid and Aura.phones[tid]
    local unavailable = (not tsrc) or (tp and tp.settings.airplane) or (tp and tp.battery <= 0)
    if unavailable then
        logCall(me.number, number, 'missed', 0, call.hidden)
        return { ok = true, state = 'unavailable' }
    end
    if byPlayer[tsrc] then return { ok = true, state = 'busy' } end
    calls[call.id] = call; byPlayer[src] = call.id; byPlayer[tsrc] = call.id
    local blocked = Aura.IsBlocked(tid, me.number)
    if not blocked then
        TriggerClientEvent('aura:push', tsrc, 'incomingCall', { id = call.id, number = call.hidden and '' or me.number, hidden = call.hidden, silent = tp.settings.dnd })
    end
    SetTimeout(Config.Calls.ringTimeout * 1000, function()
        local c = calls[call.id]
        if c and not c.answeredAt then finish(c, 'noanswer') end
    end)
    return { ok = true, state = 'ringing', id = call.id }
end)

lib.callback.register('aura:callAnswer', function(src, callId)
    local c = calls[tonumber(callId)]
    if not c or c.callee.src ~= src or c.answeredAt then return false end
    if Config.Calls.price > 0 then
        local x = ESX.GetPlayerFromId(c.caller.src)
        if x and x.getAccount(Config.Bank.account).money >= Config.Calls.price then x.removeAccountMoney(Config.Bank.account, Config.Calls.price) end
    end
    c.answeredAt = os.time()
    for _, side in ipairs({ c.caller, c.callee }) do
        TriggerClientEvent('aura:push', side.src, 'callConnect', { id = c.id, channel = c.channel, number = side == c.caller and c.callee.number or (c.hidden and '' or c.caller.number) })
    end
    return true
end)

lib.callback.register('aura:callEnd', function(src, reason)
    local cid = byPlayer[src]; local c = cid and calls[cid]
    if not c then return false end
    local r = reason
    if not c.answeredAt then r = (src == c.callee.src) and 'declined' or 'cancelled' end
    finish(c, r or 'ended')
    return true
end)

AddEventHandler('aura:phoneDropped', function(src)
    local cid = byPlayer[src]; local c = cid and calls[cid]
    if c then finish(c, 'ended') end
end)

lib.callback.register('aura:callLog', function(src)
    local id = Aura.ident[src]; local p = id and Aura.phones[id]
    if not p then return {} end
    return MySQL.query.await([[SELECT id, caller, callee, status, duration, hidden, UNIX_TIMESTAMP(created) * 1000 AS created FROM aura_calls
        WHERE caller = ? OR callee = ? ORDER BY id DESC LIMIT 100]], { p.number, p.number }) or {}
end)

lib.callback.register('aura:callLogClear', function(src)
    local id = Aura.ident[src]; local p = id and Aura.phones[id]
    if not p then return false end
    MySQL.update.await('DELETE FROM aura_calls WHERE caller = ? OR callee = ?', { p.number, p.number })
    return true
end)

function Aura.Services() return Config.Services end
