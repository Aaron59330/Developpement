-- Exports pour les autres scripts
exports('GetPhoneNumber', function(src) local id = Aura.Identifier(src); local p = id and Aura.phones[id]; return p and p.number end)
exports('GetPhoneNumberByIdentifier', function(identifier) local p = Aura.phones[identifier]; return p and p.number end)
exports('GetSourceByNumber', function(number) local id = Aura.byNumber[Aura.CleanNumber(number)]; return id and Aura.src[id] end)
exports('GetIdentifierByNumber', function(number) return Aura.byNumber[Aura.CleanNumber(number)] end)
exports('Notify', function(src, title, body, app)
    local id = Aura.Identifier(src); if id then Aura.Push(id, 'notify', { app = app or 'system', title = title, body = body }) end
end)
exports('SendMail', function(identifier, from, subject, body) return Aura.SendMailTo(identifier, from, subject, body) end)
exports('SendMessage', function(fromNumber, toNumber, body)
    local fid = Aura.byNumber[Aura.CleanNumber(fromNumber)]
    local src = fid and Aura.src[fid]
    if not src then return false end
    return Aura.SendMessage(src, { to = toNumber, body = body })
end)
exports('CreateBill', function(identifier, issuer, amount, reason, society) return Aura.CreateBill(identifier, issuer, amount, reason, society) end)
exports('Dispatch', function(service, message, coords, label) return Aura.Dispatch(service, message, coords, label) end)
exports('AddPhoto', function(identifier, url) return Aura.AddPhoto(identifier, url) end)
exports('SetBattery', function(src, level)
    local id = Aura.Identifier(src); local p = id and Aura.phones[id]
    if p then p.battery = math.max(0, math.min(100, tonumber(level) or 100)); TriggerClientEvent('aura:push', src, 'battery', { level = p.battery, charging = p.charging or false }) end
end)
exports('HasPhone', function(src)
    if not Config.RequireItem then return true end
    local ok, n = pcall(function() return exports.ox_inventory:Search(src, 'count', Config.Item) end)
    return ok and (n or 0) > 0
end)
