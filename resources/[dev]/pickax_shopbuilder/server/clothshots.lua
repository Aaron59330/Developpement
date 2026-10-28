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

-- Groupes autorisés (même liste que les admins de pickax_core) ; l'ACE « command » (console / txAdmin) est aussi acceptée
local GROUPS = { _dev = true, god = true, owner = true, superadmin = true, admin = true, mod = true }

local function isAdmin(src)
    if src == 0 then return true end
    local ok, xp = pcall(function() return ESX.GetPlayerFromId(src) end)
    local g = ok and xp and xp.getGroup and xp.getGroup() or ''
    if GROUPS[g] then return true end
    return IsPlayerAceAllowed(src, 'command') and true or false
end

RegisterNetEvent('pickax_shopbuilder:clothshotCheck', function()
    local src = source
    local ok = isAdmin(src) and GetResourceState('screenshot-basic') == 'started'
    if not ok then print(('^3[clothshots] refusé pour %s : admin=%s (groupe « %s »), screenshot-basic=%s^0'):format(tostring(src), tostring(isAdmin(src)), (function() local x = ESX.GetPlayerFromId(src) return x and x.getGroup and x.getGroup() or '?' end)(), GetResourceState('screenshot-basic'))) end
    TriggerClientEvent('pickax_shopbuilder:clothshotGo', src, ok, ok and '' or (GetResourceState('screenshot-basic') == 'started' and 'Réservé aux administrateurs.' or 'La ressource « screenshot-basic » doit être démarrée.'))
end)

-- L'image arrive en morceaux (capture faite côté joueur par screenshot-basic) : on la rassemble puis on l'enregistre
local parts = {}   -- [source] = { key, n, got, list }

RegisterNetEvent('pickax_shopbuilder:clothshotPart', function(sex, piece, value, i, n, chunk)
    local src = source
    if not isAdmin(src) or (sex ~= 'm' and sex ~= 'f') or not PIECES[piece] or type(value) ~= 'number' or value < 0 or value > 9999 then return end
    if type(i) ~= 'number' or type(n) ~= 'number' or type(chunk) ~= 'string' or n < 1 or n > 60 or i < 1 or i > n or #chunk > 8200 then return end
    local key = sex .. piece .. value
    local p = parts[src]
    if not p or p.key ~= key or i == 1 then p = { key = key, n = n, got = 0, list = {} } parts[src] = p end
    if not p.list[i] then p.list[i] = chunk p.got = p.got + 1 end
    if p.got < p.n then return end
    parts[src] = nil
    local data = table.concat(p.list):gsub('^data:image/%w+;base64,', '')
    local raw = b64decode(data)
    local ok = #raw > 100 and SaveResourceFile(RES, ('html/clothes/%s/%s/%d.webp'):format(sex, piece, value), raw, #raw)
    if not ok then print(('^1[clothshots] impossible d\'écrire html/clothes/%s/%s/%d.webp^0'):format(sex, piece, value)) end
    TriggerClientEvent('pickax_shopbuilder:clothshotAck', src, ok and true or false)
end)

AddEventHandler('playerDropped', function() parts[source] = nil end)
