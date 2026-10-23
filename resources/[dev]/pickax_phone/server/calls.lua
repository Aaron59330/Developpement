-- Appels vocaux : joueur → joueur, et joueur → ligne d'un job (sonne chez tous les employés, le premier qui décroche prend l'appel)
local calls, byPlayer, nextId = {}, {}, 0

local function logCall(caller, callee, status, duration, hidden)
    MySQL.insert('INSERT INTO aero_calls (caller, callee, status, duration, hidden) VALUES (?,?,?,?,?)', { caller, callee, status, duration or 0, hidden and 1 or 0 })
end

local function lineKey(line) return line.number ~= '' and line.number or ('srv-' .. line.id):sub(1, 20) end
Aura.LineKey = lineKey

local function finish(call, reason)
    if call.done then return end
    call.done = true
    local dur = call.answeredAt and (os.time() - call.answeredAt) or 0
    local status = call.answeredAt and 'answered' or (reason == 'declined' and 'declined' or 'missed')
    local calleeKey = call.line and lineKey(call.line) or call.callee.number
    logCall(call.caller.number, calleeKey, status, dur, call.hidden)
    local parties = { call.caller }
    if call.callee and call.callee.src then parties[#parties + 1] = call.callee end
    for s in pairs(call.group or {}) do parties[#parties + 1] = { src = s, member = true } end
    for _, side in ipairs(parties) do
        byPlayer[side.src] = nil
        TriggerClientEvent('aura:push', side.src, 'callEnd', { id = call.id, reason = reason, duration = dur, number = (side == call.caller) and calleeKey or call.caller.number })
        if status == 'missed' and side ~= call.caller then
            TriggerClientEvent('aura:push', side.src, 'missedCall', { number = call.hidden and '' or call.caller.number, hidden = call.hidden, service = call.line and call.line.label or nil })
        end
    end
    calls[call.id] = nil
end

local function phoneOf(src) local id = Aura.ident[src]; return id and Aura.phones[id], id end

local function startRingTimeout(call, seconds)
    SetTimeout(seconds * 1000, function()
        local c = calls[call.id]
        if c and not c.answeredAt then finish(c, 'noanswer') end
    end)
end

-- Appel vers la ligne d'un job
function Aura.StartLineCall(src, line, hidden)
    local me = phoneOf(src)
    if not me then return { ok = false, error = 'Téléphone indisponible' } end
    if byPlayer[src] then return { ok = false, error = 'Déjà en appel' } end
    if me.settings.airplane then return { ok = false, error = 'Mode avion activé' } end
    if not Config.JobLines.voice or line.mode == 'alert' then return { ok = false, error = 'Ce service se joint par alerte uniquement' } end
    local group, any = {}, false
    for _, m in ipairs(Aura.LineMembers(line)) do
        local p = phoneOf(m)
        if m ~= src and p and not p.settings.airplane and p.battery > 0 and not byPlayer[m] then group[m] = true; any = true end
    end
    if not any then
        logCall(me.number, lineKey(line), 'missed', 0, false)
        return { ok = true, state = 'unavailable' }
    end
    nextId = nextId + 1
    local call = { id = nextId, line = line, hidden = (hidden and Config.Calls.allowHidden and (Config.Limits or {}).hideNumber ~= false) or (me.settings.hideNumber and (Config.Limits or {}).hideNumber ~= false) or false, group = group,
        caller = { src = src, id = Aura.ident[src], number = me.number }, channel = Config.Calls.channelBase + nextId }
    calls[call.id] = call; byPlayer[src] = call.id
    for m in pairs(group) do
        byPlayer[m] = call.id
        local p = phoneOf(m)
        TriggerClientEvent('aura:push', m, 'incomingCall', { id = call.id, number = call.hidden and '' or me.number, hidden = call.hidden, silent = p.settings.dnd, service = line.label })
    end
    startRingTimeout(call, Config.JobLines.ringTimeout or Config.Calls.ringTimeout)
    return { ok = true, state = 'ringing', id = call.id, line = line.label }
end

lib.callback.register('aura:callStart', function(src, number, hidden)
    local me = phoneOf(src)
    if not me then return { ok = false, error = 'Téléphone indisponible' } end
    number = Aura.CleanNumber(number)
    if number == '' then return { ok = false, error = 'Numéro invalide' } end
    local line = Aura.LineByNumber(number)
    if line then
        if Config.JobLines.voice and line.mode ~= 'alert' then return Aura.StartLineCall(src, line, hidden) end
        return { ok = true, service = line.id, label = line.label }
    end
    if byPlayer[src] then return { ok = false, error = 'Déjà en appel' } end
    if me.settings.airplane then return { ok = false, error = 'Mode avion activé' } end
    if number == me.number then return { ok = false, error = 'Impossible de s\'appeler soi-même' } end
    if Config.Calls.price > 0 then
        if Bridge.Money(src, 'bank') < Config.Calls.price then return { ok = false, error = 'Solde insuffisant' } end
    end
    local tid = Aura.byNumber[number]
    local tsrc = tid and Aura.src[tid]
    nextId = nextId + 1
    local call = { id = nextId, hidden = (hidden and Config.Calls.allowHidden and (Config.Limits or {}).hideNumber ~= false) or (me.settings.hideNumber and (Config.Limits or {}).hideNumber ~= false) or false,
        caller = { src = src, id = Aura.ident[src], number = me.number }, callee = { src = tsrc, id = tid, number = number }, channel = Config.Calls.channelBase + nextId }
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
    startRingTimeout(call, Config.Calls.ringTimeout)
    return { ok = true, state = 'ringing', id = call.id }
end)

lib.callback.register('aura:serviceVoice', function(src, lineId, hidden)
    local line = Aura.LineById(lineId)
    if not line then return { ok = false, error = 'Service inconnu' } end
    return Aura.StartLineCall(src, line, hidden)
end)

lib.callback.register('aura:callAnswer', function(src, callId)
    local c = calls[tonumber(callId)]
    if not c or c.answeredAt then return false end
    local isGroup = c.group and c.group[src]
    if not isGroup and not (c.callee and c.callee.src == src) then return false end
    if isGroup then
        local p, id = phoneOf(src)
        c.callee = { src = src, id = id, number = p and p.number or '' }
        for s in pairs(c.group) do
            if s ~= src then
                byPlayer[s] = nil
                TriggerClientEvent('aura:push', s, 'callEnd', { id = c.id, reason = 'answered_elsewhere', duration = 0, number = c.caller.number })
            end
        end
        c.group = nil
    end
    if Config.Calls.price > 0 then
        Bridge.RemoveMoney(c.caller.src, 'bank', Config.Calls.price, 'Aura : appel')
    end
    c.answeredAt = os.time()
    local calleeKey = c.line and lineKey(c.line) or c.callee.number
    TriggerClientEvent('aura:push', c.caller.src, 'callConnect', { id = c.id, channel = c.channel, number = calleeKey, service = c.line and c.line.label or nil, peer = c.callee.src })
    TriggerClientEvent('aura:push', c.callee.src, 'callConnect', { id = c.id, channel = c.channel, number = c.hidden and '' or c.caller.number, service = c.line and c.line.label or nil, peer = c.caller.src })
    return true
end)

lib.callback.register('aura:callEnd', function(src, reason)
    local cid = byPlayer[src]; local c = cid and calls[cid]
    if not c then return false end
    if not c.answeredAt then
        if c.group and c.group[src] then
            -- un employé refuse : l'appel continue de sonner chez les autres
            c.group[src] = nil; byPlayer[src] = nil
            TriggerClientEvent('aura:push', src, 'callEnd', { id = c.id, reason = 'declined', duration = 0, number = c.caller.number })
            if next(c.group) == nil then finish(c, 'declined') end
            return true
        end
        reason = (c.callee and src == c.callee.src) and 'declined' or 'cancelled'
    end
    finish(c, reason or 'ended')
    return true
end)

AddEventHandler('aura:phoneDropped', function(src)
    local cid = byPlayer[src]; local c = cid and calls[cid]
    if not c then return end
    if c.group and c.group[src] then c.group[src] = nil; byPlayer[src] = nil; if next(c.group) == nil then finish(c, 'noanswer') end return end
    finish(c, 'ended')
end)

lib.callback.register('aura:callLog', function(src)
    local p = phoneOf(src)
    if not p then return {} end
    return MySQL.query.await([[SELECT id, caller, callee, status, duration, hidden, UNIX_TIMESTAMP(created) * 1000 AS created FROM aero_calls
        WHERE caller = ? OR callee = ? ORDER BY id DESC LIMIT 100]], { p.number, p.number }) or {}
end)

lib.callback.register('aura:callLogClear', function(src)
    local p = phoneOf(src)
    if not p then return false end
    MySQL.update.await('DELETE FROM aero_calls WHERE caller = ? OR callee = ?', { p.number, p.number })
    return true
end)
