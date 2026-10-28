-- ─────────────────────────────── Activité du serveur et alertes Discord ───────────────────────────────
-- Count(clé, n, libellé) : compteurs du jour (ventes, saisies, laboratoires, gangs…) conservés 14 jours ; Activity() : liste pour le panel web (page Statistiques) ;
-- Discord(catégorie, titre, texte, couleur) : message dans un salon via un webhook (réglages « Discord » du panel). Le webhook n'est jamais envoyé aux joueurs.
local KVP = 'pickax_activity_v1'
local days, labels = {}, {}
local dirty = false

local function today() return os.date('%Y%m%d') end

local function load()
    local raw = GetResourceKvpString(KVP)
    if raw and raw ~= '' then
        local ok, t = pcall(json.decode, raw)
        if ok and type(t) == 'table' then days, labels = t.days or {}, t.labels or {} end
    end
end

local function prune()
    local keys = {}
    for d in pairs(days) do keys[#keys + 1] = d end
    table.sort(keys)
    while #keys > 14 do days[table.remove(keys, 1)] = nil end
end

local function save()
    if not dirty then return end
    dirty = false
    prune()
    SetResourceKvp(KVP, json.encode({ days = days, labels = labels }))
end

function Settings.Count(key, n, label)
    if n == nil then n = 1 else n = tonumber(n) end
    if type(key) ~= 'string' or key == '' or #key > 40 or not n or n ~= n then return end
    local d = today()
    days[d] = days[d] or {}
    days[d][key] = (days[d][key] or 0) + n
    if type(label) == 'string' and label ~= '' then labels[key] = label:sub(1, 60) end
    dirty = true
end

-- [{ key, label, today, week }] triée par libellé (40 max)
function Settings.Activity()
    local d = today()
    local keys, seen = {}, {}
    for day, t in pairs(days) do for k in pairs(t) do if not seen[k] then seen[k] = true keys[#keys + 1] = k end end end
    table.sort(keys, function(a, b) return (labels[a] or a) < (labels[b] or b) end)
    local out = {}
    local now = os.time()
    for i = 1, math.min(40, #keys) do
        local k = keys[i]
        local week = 0
        for back = 0, 6 do
            local day = os.date('%Y%m%d', now - back * 86400)
            week = week + ((days[day] or {})[k] or 0)
        end
        out[#out + 1] = { key = k, label = labels[k] or k, today = (days[d] or {})[k] or 0, week = week }
    end
    return out
end

exports('Count', function(key, n, label) Settings.Count(key, n, label) end)
exports('Activity', function() return Settings.Activity() end)

-- ─── Discord ───
local CATEGORY = { gangs = 'discord_cat_gangs', police = 'discord_cat_police', labs = 'discord_cat_labs', digest = 'discord_digest' }
local queue, sending = {}, false

local function validHook(u) return type(u) == 'string' and (u:match('^https://discord%.com/api/webhooks/') or u:match('^https://discordapp%.com/api/webhooks/') or u:match('^https://ptb%.discord%.com/api/webhooks/')) ~= nil end

-- Corps du message (pur) : un embed
function Settings.DiscordPayload(title, text, color)
    return { username = 'Serveur', embeds = { { title = tostring(title or ''):sub(1, 200), description = tostring(text or ''):sub(1, 1500), color = tonumber(color) or 16626301, timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ') } } }
end

local function flush()
    if sending then return end
    sending = true
    CreateThread(function()
        while #queue > 0 do
            local item = table.remove(queue, 1)
            PerformHttpRequest(item.url, function() end, 'POST', json.encode(item.body), { ['Content-Type'] = 'application/json' })
            Wait(1300)    -- limite de débit de Discord
        end
        sending = false
    end)
end

-- Renvoie true si le message est parti en file d'envoi
function Settings.Discord(category, title, text, color)
    if not Settings.Get('discord_alerts') then return false end
    local key = CATEGORY[category]
    if not key or not Settings.Get(key) then return false end
    local url = Settings.Get('discord_webhook')
    if not validHook(url) or #queue >= 30 then return false end
    queue[#queue + 1] = { url = url, body = Settings.DiscordPayload(title, text, color) }
    flush()
    return true
end
exports('Discord', function(category, title, text, color) return Settings.Discord(category, title, text, color) end)

-- Résumé quotidien
local lastDigest = nil
CreateThread(function()
    load()
    while true do
        Wait(60000)
        save()
        if Settings.Get('discord_digest') and tonumber(os.date('%H')) == math.floor(tonumber(Settings.Get('discord_digest_hour')) or 20) and lastDigest ~= today() then
            lastDigest = today()
            local lines = {}
            for _, a in ipairs(Settings.Activity()) do if a.today > 0 then lines[#lines + 1] = ('**%s** : %s (7 j : %s)'):format(a.label, a.today, a.week) end end
            Settings.Discord('digest', 'Résumé du jour', #lines > 0 and table.concat(lines, '\n') or 'Aucune activité enregistrée aujourd\'hui.')
        end
    end
end)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then save() end end)
