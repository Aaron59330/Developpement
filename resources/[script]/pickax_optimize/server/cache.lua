-- Cache mémoire partagé (serveur). Évite de relire la base ou de recalculer des données qui changent rarement.
--   exports.pickax_optimize:Remember('cle', 30, function() return MySQL.query.await('SELECT …') end)   -- valeur en cache 30 s, sinon calculée puis gardée
--   exports.pickax_optimize:Get('cle') / :Set('cle', valeur, ttl) / :Invalidate('cle') / :InvalidatePrefix('jobs:')
-- Une valeur nil n'est pas mise en cache. Pense à invalider la clé quand tu modifies la donnée.
local C = Config.Cache
local store, size = {}, 0
local hits, misses = 0, 0

local function now() return GetGameTimer() end

local function drop(key) if store[key] then store[key] = nil size = size - 1 end end

local function get(key)
    local e = store[key]
    if e and e.exp > now() then hits = hits + 1 return e.v, true end
    if e then drop(key) end
    misses = misses + 1
    return nil, false
end

local function set(key, value, ttl)
    if value == nil then drop(key) return end
    if not store[key] then
        if size >= C.MaxEntries then      -- plein : on retire les entrées expirées, sinon les plus anciennes
            local t = now()
            for k, e in pairs(store) do if e.exp <= t then drop(k) end end
            if size >= C.MaxEntries then
                local n = 0
                for k in pairs(store) do drop(k) n = n + 1 if n >= C.MaxEntries // 10 then break end end
            end
        end
        size = size + 1
    end
    store[key] = { v = value, exp = now() + math.floor((tonumber(ttl) or C.DefaultTTL) * 1000) }
end

local function remember(key, ttl, fn)
    local v, ok = get(key)
    if ok then return v end
    v = fn()
    set(key, v, ttl)
    return v
end

local function invalidatePrefix(prefix)
    for k in pairs(store) do if k:sub(1, #prefix) == prefix then drop(k) end end
end

exports('Get', function(key) return (get(key)) end)
exports('Set', set)
exports('Remember', remember)
exports('Invalidate', drop)
exports('InvalidatePrefix', invalidatePrefix)
exports('CacheStats', function() return { entries = size, hits = hits, misses = misses } end)

CreateThread(function()      -- nettoyage des entrées expirées
    while true do
        Wait(60000)
        local t = now()
        for k, e in pairs(store) do if e.exp <= t then drop(k) end end
    end
end)
