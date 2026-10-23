local lastSend = {}

local function directId(a, b)
    if a > b then a, b = b, a end
    return 'd:' .. a .. ':' .. b
end

local function members(conv)
    return MySQL.query.await('SELECT number, muted, pinned, hidden, last_read FROM aura_conv_members WHERE conv = ?', { conv }) or {}
end

local function myNumber(src)
    local id = Aura.ident[src]; local p = id and Aura.phones[id]
    return p and p.number, id, p
end

local function decode(m)
    m.meta = Aura.Unjson(m.meta, nil)
    m.reactions = Aura.Unjson(m.reactions, nil)
    return m
end

local function isMember(conv, number)
    return MySQL.scalar.await('SELECT 1 FROM aura_conv_members WHERE conv = ? AND number = ?', { conv, number }) ~= nil
end

local function convInfo(conv)
    return MySQL.single.await('SELECT id, kind, name, avatar, owner FROM aura_conv WHERE id = ?', { conv })
end

lib.callback.register('aura:convList', function(src)
    local number = myNumber(src)
    if not number then return {} end
    local rows = MySQL.query.await([[
        SELECT c.id, c.kind, c.name, c.avatar, c.owner, m.muted, m.pinned, m.hidden, m.last_read,
               (SELECT id FROM aura_messages WHERE conv = c.id ORDER BY id DESC LIMIT 1) AS last_id
        FROM aura_conv_members m JOIN aura_conv c ON c.id = m.conv
        WHERE m.number = ? AND m.hidden = 0]], { number }) or {}
    local out = {}
    for _, r in ipairs(rows) do
        local last = r.last_id and decode(MySQL.single.await('SELECT id, conv, sender, kind, body, meta, created FROM aura_messages WHERE id = ?', { r.last_id }))
        r.last = last
        r.unread = MySQL.scalar.await('SELECT COUNT(*) FROM aura_messages WHERE conv = ? AND sender <> ? AND created > ?', { r.id, number, r.last_read }) or 0
        local mem = members(r.id)
        r.members = {}
        for _, mm in ipairs(mem) do r.members[#r.members + 1] = mm.number end
        if r.kind == 'direct' then
            for _, n in ipairs(r.members) do if n ~= number then r.other = n end end
        end
        out[#out + 1] = r
    end
    table.sort(out, function(a, b)
        if a.pinned ~= b.pinned then return a.pinned > b.pinned end
        return (a.last and a.last.created or 0) > (b.last and b.last.created or 0)
    end)
    return out
end)

lib.callback.register('aura:msgHistory', function(src, conv, before, limit)
    local number = myNumber(src)
    if not number or not isMember(conv, number) then return {} end
    limit = math.min(tonumber(limit) or 40, 100)
    local rows
    if before and tonumber(before) then
        rows = MySQL.query.await('SELECT id, conv, sender, kind, body, meta, reply_to, reactions, created FROM aura_messages WHERE conv = ? AND id < ? ORDER BY id DESC LIMIT ?', { conv, tonumber(before), limit })
    else
        rows = MySQL.query.await('SELECT id, conv, sender, kind, body, meta, reply_to, reactions, created FROM aura_messages WHERE conv = ? ORDER BY id DESC LIMIT ?', { conv, limit })
    end
    rows = rows or {}
    local out = {}
    for i = #rows, 1, -1 do out[#out + 1] = decode(rows[i]) end
    return out
end)

local function ensureDirect(a, b)
    local conv = directId(a, b)
    if not convInfo(conv) then
        MySQL.insert.await('INSERT IGNORE INTO aura_conv (id, kind, owner) VALUES (?, "direct", ?)', { conv, a })
        MySQL.insert.await('INSERT IGNORE INTO aura_conv_members (conv, number) VALUES (?, ?), (?, ?)', { conv, a, conv, b })
    end
    return conv
end
Aura.EnsureDirectConv = ensureDirect

local function deliver(conv, msg, senderNumber)
    local info = convInfo(conv)
    local mem = members(conv)
    local sname
    for _, m in ipairs(mem) do
        if m.number ~= senderNumber then
            local id = Aura.byNumber[m.number]
            if m.hidden == 1 then MySQL.update('UPDATE aura_conv_members SET hidden = 0 WHERE conv = ? AND number = ?', { conv, m.number }) end
            local blocked = id and info.kind == 'direct' and Aura.IsBlocked(id, senderNumber)
            if id and not blocked and Aura.src[id] then
                local p = Aura.phones[id]
                TriggerClientEvent('aura:push', Aura.src[id], 'message', { conv = conv, msg = msg, kind = info.kind, name = info.name, muted = m.muted == 1,
                    silent = p and (p.settings.dnd or m.muted == 1) or false })
            end
        end
    end
    -- envoi côté expéditeur (autres appareils / confirmation)
    local sid = Aura.byNumber[senderNumber]
    if sid then Aura.Push(sid, 'messageSent', { conv = conv, msg = msg }) end
end

local function sendMessage(src, data)
    local number = myNumber(src)
    if not number then return { ok = false, error = 'Téléphone indisponible' } end
    local p = Aura.phones[Aura.ident[src]]
    if p.settings.airplane then return { ok = false, error = 'Mode avion activé' } end
    local now = GetGameTimer()
    if lastSend[src] and now - lastSend[src] < 250 then return { ok = false, error = 'Trop rapide' } end
    lastSend[src] = now
    if type(data) ~= 'table' then return { ok = false } end
    local conv = data.conv
    if not conv then
        local to = Aura.CleanNumber(data.to)
        if to == '' or to == number then return { ok = false, error = 'Destinataire invalide' } end
        if not Aura.byNumber[to] then return { ok = false, error = 'Numéro inconnu' } end
        conv = ensureDirect(number, to)
    elseif not isMember(conv, number) then
        return { ok = false, error = 'Conversation introuvable' }
    end
    local kind = data.kind or 'text'
    if kind ~= 'text' and kind ~= 'image' and kind ~= 'location' and kind ~= 'contact' and kind ~= 'system' then kind = 'text' end
    if kind == 'system' then kind = 'text' end
    local body = Aura.Clamp(data.body, Config.Messages.maxLength)
    if kind == 'text' and Aura.Trim(body) == '' then return { ok = false, error = 'Message vide' } end
    local meta = nil
    if type(data.meta) == 'table' then
        if kind == 'location' then meta = { x = tonumber(data.meta.x) or 0, y = tonumber(data.meta.y) or 0, label = Aura.Clamp(data.meta.label or 'Position', 60) }
        elseif kind == 'contact' then meta = { name = Aura.Clamp(data.meta.name, 60), number = Aura.CleanNumber(data.meta.number) }
        elseif kind == 'image' then meta = { w = tonumber(data.meta.w), h = tonumber(data.meta.h) } end
    end
    local created = Aura.Now()
    local id = MySQL.insert.await('INSERT INTO aura_messages (conv, sender, kind, body, meta, reply_to, created) VALUES (?,?,?,?,?,?,?)',
        { conv, number, kind, body, meta and Aura.Json(meta) or nil, tonumber(data.replyTo), created })
    local msg = { id = id, conv = conv, sender = number, kind = kind, body = body, meta = meta, reply_to = tonumber(data.replyTo), created = created }
    MySQL.update('UPDATE aura_conv_members SET hidden = 0 WHERE conv = ? AND number = ?', { conv, number })
    deliver(conv, msg, number)
    return { ok = true, msg = msg, conv = conv }
end
Aura.SendMessage = sendMessage

lib.callback.register('aura:msgSend', function(src, data) return sendMessage(src, data) end)

lib.callback.register('aura:msgRead', function(src, conv)
    local number = myNumber(src)
    if not number then return false end
    MySQL.update('UPDATE aura_conv_members SET last_read = ? WHERE conv = ? AND number = ?', { Aura.Now(), conv, number })
    local info = convInfo(conv)
    if info and info.kind == 'direct' then
        local p = Aura.phones[Aura.ident[src]]
        if p and p.settings.readReceipts then
            for _, m in ipairs(members(conv)) do
                if m.number ~= number then Aura.PushNumber(m.number, 'messageRead', { conv = conv, by = number, at = Aura.Now() }) end
            end
        end
    end
    return true
end)

lib.callback.register('aura:msgDelete', function(src, mid)
    local number = myNumber(src)
    mid = tonumber(mid)
    if not number or not mid then return false end
    local m = MySQL.single.await('SELECT conv, sender FROM aura_messages WHERE id = ?', { mid })
    if not m or m.sender ~= number then return false end
    MySQL.update.await('DELETE FROM aura_messages WHERE id = ?', { mid })
    for _, mm in ipairs(members(m.conv)) do Aura.PushNumber(mm.number, 'messageDeleted', { conv = m.conv, id = mid }) end
    return true
end)

lib.callback.register('aura:msgReact', function(src, mid, emoji)
    local number = myNumber(src)
    mid = tonumber(mid)
    if not number or not mid then return false end
    local m = MySQL.single.await('SELECT conv, reactions FROM aura_messages WHERE id = ?', { mid })
    if not m or not isMember(m.conv, number) then return false end
    local r = Aura.Unjson(m.reactions, {})
    emoji = Aura.Clamp(emoji, 8)
    if emoji == '' or r[number] == emoji then r[number] = nil else r[number] = emoji end
    MySQL.update.await('UPDATE aura_messages SET reactions = ? WHERE id = ?', { Aura.Json(r), mid })
    for _, mm in ipairs(members(m.conv)) do Aura.PushNumber(mm.number, 'messageReact', { conv = m.conv, id = mid, reactions = r }) end
    return true
end)

lib.callback.register('aura:convSet', function(src, conv, patch)
    local number = myNumber(src)
    if not number or not isMember(conv, number) or type(patch) ~= 'table' then return false end
    for _, f in ipairs({ 'muted', 'pinned', 'hidden' }) do
        if patch[f] ~= nil then MySQL.update.await(('UPDATE aura_conv_members SET %s = ? WHERE conv = ? AND number = ?'):format(f), { patch[f] and 1 or 0, conv, number }) end
    end
    return true
end)

lib.callback.register('aura:convClear', function(src, conv)
    local number = myNumber(src)
    if not number or not isMember(conv, number) then return false end
    MySQL.update.await('UPDATE aura_conv_members SET hidden = 1, last_read = ? WHERE conv = ? AND number = ?', { Aura.Now(), conv, number })
    return true
end)

lib.callback.register('aura:groupCreate', function(src, name, numbers, avatar)
    local number = myNumber(src)
    if not number then return false end
    local list, seen = { number }, { [number] = true }
    for _, n in ipairs(numbers or {}) do
        n = Aura.CleanNumber(n)
        if n ~= '' and Aura.byNumber[n] and not seen[n] and #list < Config.Messages.maxGroup then seen[n] = true; list[#list + 1] = n end
    end
    if #list < 3 then return false, 'Un groupe nécessite au moins 2 autres membres' end
    local conv = 'g:' .. Aura.Now() .. math.random(100, 999)
    MySQL.insert.await('INSERT INTO aura_conv (id, kind, name, avatar, owner) VALUES (?, "group", ?, ?, ?)', { conv, Aura.Clamp(name ~= '' and name or 'Groupe', 60), avatar and Aura.Clamp(avatar, 500) or nil, number })
    for _, n in ipairs(list) do MySQL.insert.await('INSERT IGNORE INTO aura_conv_members (conv, number) VALUES (?, ?)', { conv, n }) end
    for _, n in ipairs(list) do Aura.PushNumber(n, 'convUpdate', { conv = conv }) end
    return conv
end)

lib.callback.register('aura:groupEdit', function(src, conv, patch)
    local number = myNumber(src)
    local info = convInfo(conv)
    if not number or not info or info.kind ~= 'group' or not isMember(conv, number) or type(patch) ~= 'table' then return false end
    if patch.name then MySQL.update.await('UPDATE aura_conv SET name = ? WHERE id = ?', { Aura.Clamp(patch.name, 60), conv }) end
    if patch.avatar then MySQL.update.await('UPDATE aura_conv SET avatar = ? WHERE id = ?', { Aura.Clamp(patch.avatar, 500), conv }) end
    if patch.add then
        local mem = members(conv)
        for _, n in ipairs(patch.add) do
            n = Aura.CleanNumber(n)
            if Aura.byNumber[n] and #mem < Config.Messages.maxGroup then MySQL.insert.await('INSERT IGNORE INTO aura_conv_members (conv, number) VALUES (?, ?)', { conv, n }) end
        end
    end
    if patch.remove and info.owner == number then
        MySQL.update.await('DELETE FROM aura_conv_members WHERE conv = ? AND number = ?', { conv, Aura.CleanNumber(patch.remove) })
    end
    if patch.leave then MySQL.update.await('DELETE FROM aura_conv_members WHERE conv = ? AND number = ?', { conv, number }) end
    for _, m in ipairs(members(conv)) do Aura.PushNumber(m.number, 'convUpdate', { conv = conv }) end
    if patch.leave then Aura.PushNumber(number, 'convUpdate', { conv = conv }) end
    return true
end)

RegisterNetEvent('aura:typing', function(conv)
    local src = source
    local number = myNumber(src)
    if not number or not isMember(conv, number) then return end
    for _, m in ipairs(members(conv)) do
        if m.number ~= number then Aura.PushNumber(m.number, 'typing', { conv = conv, number = number }) end
    end
end)

lib.callback.register('aura:numberExists', function(src, number)
    number = Aura.CleanNumber(number)
    return Aura.byNumber[number] ~= nil
end)
