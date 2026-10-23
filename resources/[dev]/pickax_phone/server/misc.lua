-- Localiser (partage de position) et AirShare
CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS aura_findmy (
        owner VARCHAR(80) NOT NULL, viewer VARCHAR(80) NOT NULL, PRIMARY KEY (owner, viewer))]])
end)

local function coordsOf(src)
    local c = GetEntityCoords(GetPlayerPed(src))
    return { x = c.x, y = c.y, z = c.z }
end

lib.callback.register('aura:fmMine', function(src)
    local id = Aura.ident[src]; if not id then return {} end
    local rows = MySQL.query.await('SELECT viewer FROM aura_findmy WHERE owner = ?', { id }) or {}
    local out = {}
    for _, r in ipairs(rows) do local p = Aura.phones[r.viewer]; if p then out[#out + 1] = p.number end end
    return out
end)

lib.callback.register('aura:fmShare', function(src, number, state)
    local id = Aura.ident[src]; if not id then return false end
    number = Aura.CleanNumber(number)
    local tid = Aura.byNumber[number]; if not tid or tid == id then return false end
    if state then
        MySQL.insert.await('INSERT IGNORE INTO aura_findmy (owner, viewer) VALUES (?, ?)', { id, tid })
        Aura.Push(tid, 'notify', { app = 'findmy', title = 'Localiser', body = Aura.Name(id) .. ' partage sa position avec vous' })
    else MySQL.update.await('DELETE FROM aura_findmy WHERE owner = ? AND viewer = ?', { id, tid }) end
    return true
end)

lib.callback.register('aura:fmList', function(src)
    local id = Aura.ident[src]; if not id then return {} end
    local rows = MySQL.query.await('SELECT owner FROM aura_findmy WHERE viewer = ?', { id }) or {}
    local out = {}
    for _, r in ipairs(rows) do
        local p = Aura.phones[r.owner]; local s = Aura.src[r.owner]
        if p then
            local item = { number = p.number, name = Aura.Name(r.owner), online = s ~= nil }
            if s and not p.settings.airplane and p.battery > 0 then item.coords = coordsOf(s) end
            out[#out + 1] = item
        end
    end
    return out
end)

lib.callback.register('aura:myCoords', function(src) return coordsOf(src) end)

-- ═════════════════ AIRSHARE ═════════════════
local pending, nextShare = {}, 0

lib.callback.register('aura:airNearby', function(src)
    local id = Aura.ident[src]; if not id then return {} end
    local me = GetEntityCoords(GetPlayerPed(src))
    local out = {}
    for tid, tsrc in pairs(Aura.src) do
        if tsrc ~= src then
            local d = #(me - GetEntityCoords(GetPlayerPed(tsrc)))
            local p = Aura.phones[tid]
            if d <= Config.AirShare.distance and p and not p.settings.airplane and p.battery > 0 then
                out[#out + 1] = { src = tsrc, name = Aura.Name(tid), distance = math.floor(d) }
            end
        end
    end
    return out
end)

lib.callback.register('aura:airSend', function(src, target, kind, data)
    local id = Aura.ident[src]; if not id then return false end
    local tid = Aura.ident[target]; if not tid then return false end
    if kind ~= 'photo' and kind ~= 'contact' and kind ~= 'note' and kind ~= 'location' then return false end
    local me = GetEntityCoords(GetPlayerPed(src))
    if #(me - GetEntityCoords(GetPlayerPed(target))) > Config.AirShare.distance + 2 then return false, 'Trop loin' end
    if type(data) ~= 'table' then return false end
    local payload = {}
    if kind == 'photo' then payload.url = Aura.Clamp(data.url, 500); if not payload.url:match('^https?://') then return false end
    elseif kind == 'contact' then payload.name = Aura.Clamp(data.name, 60); payload.number = Aura.CleanNumber(data.number)
    elseif kind == 'note' then payload.title = Aura.Clamp(data.title, 80); payload.body = Aura.Clamp(data.body, 4000)
    else payload.x = tonumber(data.x) or 0; payload.y = tonumber(data.y) or 0 end
    nextShare = nextShare + 1
    local sid = nextShare
    pending[sid] = { from = src, to = target, kind = kind, payload = payload }
    SetTimeout(Config.AirShare.timeout * 1000, function() pending[sid] = nil end)
    TriggerClientEvent('aura:push', target, 'airRequest', { id = sid, from = Aura.Name(id), kind = kind, preview = payload })
    return true
end)

lib.callback.register('aura:airRespond', function(src, sid, accept)
    local s = pending[tonumber(sid)]
    if not s or s.to ~= src then return false end
    pending[tonumber(sid)] = nil
    local tid = Aura.ident[src]
    if accept then
        if s.kind == 'photo' and tid then Aura.AddPhoto(tid, s.payload.url) end
        TriggerClientEvent('aura:push', src, 'airReceived', { kind = s.kind, payload = s.payload })
        TriggerClientEvent('aura:push', s.from, 'notify', { app = 'airshare', title = 'AirShare', body = 'Partage accepté' })
    else
        TriggerClientEvent('aura:push', s.from, 'notify', { app = 'airshare', title = 'AirShare', body = 'Partage refusé' })
    end
    return true
end)
