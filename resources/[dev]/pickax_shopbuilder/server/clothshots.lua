-- Génération des images de vêtements (admin) : reçoit la demande du client, fait capturer l'écran du joueur par « screenshot-basic »
-- puis enregistre html/clothes/<m|f>/<pièce>/<numéro>.webp. Utilisation : /clothshots <pièce> [de] [à]   (voir html/clothes/LISEZMOI.md)
local RES = GetCurrentResourceName()
local B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local lookup = {}
for i = 1, #B64 do lookup[B64:sub(i, i)] = i - 1 end

local function b64decode(data)
    data = data:gsub('[^%w%+/=]', '')
    local out, n, bits, val = {}, 0, 0, 0
    for c in data:gmatch('.') do
        if c == '=' then break end
        val = (val << 6) | lookup[c]; bits = bits + 6
        if bits >= 8 then bits = bits - 8; n = n + 1; out[n] = string.char((val >> bits) & 0xFF); val = val & ((1 << bits) - 1) end
    end
    return table.concat(out)
end

local PIECES = { tshirt = true, torso = true, arms = true, bproof = true, decals = true, pants = true, shoes = true, helmet = true, glasses = true, ears = true, mask = true, chain = true, bags = true, watches = true, bracelets = true }

local function isAdmin(src)
    if src == 0 then return true end
    local ok, xp = pcall(function() return ESX.GetPlayerFromId(src) end)
    local g = ok and xp and xp.getGroup and xp.getGroup() or ''
    return g == 'admin' or g == 'superadmin' or g == 'owner'
end

RegisterNetEvent('pickax_shopbuilder:clothshotCheck', function()
    local src = source
    local ok = isAdmin(src) and GetResourceState('screenshot-basic') == 'started'
    if not ok then print(('^3[clothshots] refusé pour %s : admin=%s, screenshot-basic=%s^0'):format(tostring(src), tostring(isAdmin(src)), GetResourceState('screenshot-basic'))) end
    TriggerClientEvent('pickax_shopbuilder:clothshotGo', src, ok, ok and '' or (GetResourceState('screenshot-basic') == 'started' and 'Réservé aux administrateurs.' or 'La ressource « screenshot-basic » doit être démarrée.'))
end)

RegisterNetEvent('pickax_shopbuilder:clothshot', function(sex, piece, value)
    local src = source
    if not isAdmin(src) or (sex ~= 'm' and sex ~= 'f') or not PIECES[piece] or type(value) ~= 'number' then return end
    exports['screenshot-basic']:requestClientScreenshot(src, { encoding = 'webp', quality = 0.6 }, function(err, data)
        if not err and type(data) == 'string' then
            local raw = b64decode(data:gsub('^data:image/%w+;base64,', ''))
            SaveResourceFile(RES, ('html/clothes/%s/%s/%d.webp'):format(sex, piece, value), raw, #raw)
        end
        TriggerClientEvent('pickax_shopbuilder:clothshotAck', src, err == nil)
    end)
end)
