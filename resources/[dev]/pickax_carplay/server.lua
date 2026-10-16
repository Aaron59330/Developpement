-- ─────────────────────────────── CarPlay : serveur ───────────────────────────────
-- L'état de la musique d'un véhicule (file, titre en cours, position, volume…) vit dans le state bag `carplay` du véhicule :
-- seul le serveur l'écrit, tous les clients proches le lisent et jouent la musique (synchronisée sur l'horloge réelle).
local ESX = exports['es_extended']:getSharedObject()
local Veh = {}            -- [netId] = { st, idle }
local bucket = {}         -- limitation de débit par joueur
local ready = false
local searchAt = {}

-- Horloge unique du serveur (secondes, précision à la milliseconde) : les clients se calent dessus (callback carplay:time), jamais sur leur propre heure
local function now() return GetGameTimer() / 1000.0 end
ESX.RegisterServerCallback('carplay:time', function(_, cb) cb(now()) end)
local function notify(src, msg) TriggerClientEvent('esx:showNotification', src, msg) end

-- ─────────────────────────────── Base de données (favoris / historique) ───────────────────────────────
MySQL.ready(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS carplay_favorites (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, identifier VARCHAR(80) NOT NULL, kind VARCHAR(8) NOT NULL, ref VARCHAR(300) NOT NULL,
        title VARCHAR(160) DEFAULT NULL, author VARCHAR(120) DEFAULT NULL, thumb VARCHAR(300) DEFAULT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_fav (identifier, kind, ref(190))) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS carplay_history (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, identifier VARCHAR(80) NOT NULL, kind VARCHAR(8) NOT NULL, ref VARCHAR(300) NOT NULL,
        title VARCHAR(160) DEFAULT NULL, author VARCHAR(120) DEFAULT NULL, thumb VARCHAR(300) DEFAULT NULL, played_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_hist (identifier, kind, ref(190))) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    ready = true
end)

local function ident(src) local x = ESX.GetPlayerFromId(src) return x and x.identifier or nil end

local function trackRow(r) return { kind = r.kind, ref = r.ref, title = r.title, author = r.author, thumb = r.thumb } end

ESX.RegisterServerCallback('carplay:library', function(src, cb)
    local id = ident(src)
    if not id or not ready then return cb({ favorites = {}, history = {} }) end
    local fav, his = {}, {}
    for _, r in ipairs(MySQL.query.await('SELECT kind, ref, title, author, thumb FROM carplay_favorites WHERE identifier = ? ORDER BY id DESC LIMIT 100', { id }) or {}) do fav[#fav + 1] = trackRow(r) end
    for _, r in ipairs(MySQL.query.await('SELECT kind, ref, title, author, thumb FROM carplay_history WHERE identifier = ? ORDER BY played_at DESC LIMIT 30', { id }) or {}) do his[#his + 1] = trackRow(r) end
    cb({ favorites = fav, history = his })
end)

local function pushLibrary(src)
    local id = ident(src)
    if not id or not ready then return end
    local fav, his = {}, {}
    for _, r in ipairs(MySQL.query.await('SELECT kind, ref, title, author, thumb FROM carplay_favorites WHERE identifier = ? ORDER BY id DESC LIMIT 100', { id }) or {}) do fav[#fav + 1] = trackRow(r) end
    for _, r in ipairs(MySQL.query.await('SELECT kind, ref, title, author, thumb FROM carplay_history WHERE identifier = ? ORDER BY played_at DESC LIMIT 30', { id }) or {}) do his[#his + 1] = trackRow(r) end
    TriggerClientEvent('carplay:client:library', src, { favorites = fav, history = his })
end

local function clip(s, n) return tostring(s or ''):gsub('[%c]', ''):sub(1, n) end

RegisterNetEvent('carplay:server:fav', function(op, kind, ref, title, author, thumb)
    local src = source
    local id = ident(src)
    if not id or not ready or (kind ~= 'yt' and kind ~= 'direct') then return end
    local k2, r2 = CarPlay.parse(kind == 'yt' and ('https://www.youtube.com/watch?v=' .. tostring(ref)) or tostring(ref))
    if not k2 or r2 ~= ref then return end
    if op == 'add' then
        local n = MySQL.scalar.await('SELECT COUNT(*) FROM carplay_favorites WHERE identifier = ?', { id }) or 0
        if (tonumber(n) or 0) >= 100 then return notify(src, '~r~Favoris pleins (100 maximum).') end
        MySQL.update.await('INSERT IGNORE INTO carplay_favorites (identifier, kind, ref, title, author, thumb) VALUES (?, ?, ?, ?, ?, ?)', { id, kind, ref, clip(title, 160), clip(author, 120), clip(thumb, 300) })
    elseif op == 'remove' then
        MySQL.update.await('DELETE FROM carplay_favorites WHERE identifier = ? AND kind = ? AND ref = ?', { id, kind, ref })
    end
    pushLibrary(src)
end)

local function remember(src, t)
    local id = ident(src)
    if not id or not ready then return end
    MySQL.update('INSERT INTO carplay_history (identifier, kind, ref, title, author, thumb) VALUES (?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE played_at = CURRENT_TIMESTAMP, title = VALUES(title), author = VALUES(author), thumb = VALUES(thumb)',
        { id, t.kind, t.ref, clip(t.title, 160), clip(t.author, 120), clip(t.thumb, 300) })
    MySQL.update('DELETE FROM carplay_history WHERE identifier = ? AND id NOT IN (SELECT id FROM (SELECT id FROM carplay_history WHERE identifier = ? ORDER BY played_at DESC LIMIT 30) x)', { id, id })
end

-- ─────────────────────────────── État d'un véhicule ───────────────────────────────
local function newState()
    return { on = true, queue = {}, index = 0, playing = false, startedAt = 0, pausedAt = 0, volume = Config.DefaultVolume, loop = 'off', shuffle = false, speakers = true, rev = 0, seq = 0 }
end

local function commit(netId)
    local v = Veh[netId]
    if not v then return end
    local ent = NetworkGetEntityFromNetworkId(netId)
    if ent and ent ~= 0 and DoesEntityExist(ent) then Entity(ent).state:set('carplay', v.st, true) end
end

local function startTrack(st, i)
    st.index, st.rev, st.playing, st.startedAt, st.pausedAt = i, st.rev + 1, true, now(), 0
end

local function stopAll(st) st.playing, st.pausedAt, st.startedAt = false, 0, 0 end

local function position(st) return st.playing and (now() - st.startedAt) or st.pausedAt end

-- passe à la suite (fin d'un titre ou « suivant »)
local function advance(st, manual)
    local n = #st.queue
    if n == 0 then return stopAll(st) end
    if st.loop == 'one' and not manual then return startTrack(st, st.index) end
    local nxt
    if st.shuffle and n > 1 then
        repeat nxt = math.random(1, n) until nxt ~= st.index
    else
        nxt = st.index + 1
        if nxt > n then
            if st.loop == 'all' or (manual and st.loop ~= 'off') then nxt = 1 else stopAll(st) return end
        end
    end
    startTrack(st, nxt)
end

local function fetchMeta(netId, track)
    if track.kind ~= 'yt' then return end
    local u = 'https://www.youtube.com/oembed?format=json&url=' .. ('https://www.youtube.com/watch?v=' .. track.ref)
    PerformHttpRequest(u, function(status, body)
        if status ~= 200 or not body then return end
        local ok, j = pcall(json.decode, body)
        local v = Veh[netId]
        if not ok or type(j) ~= 'table' or not v then return end
        for _, t in ipairs(v.st.queue) do
            if t.id == track.id then
                t.title = clip(j.title, 160) ~= '' and clip(j.title, 160) or t.title
                t.author = clip(j.author_name, 120)
                break
            end
        end
        commit(netId)
    end, 'GET')
end

local function makeTrack(st, kind, ref, by)
    st.seq = st.seq + 1
    local t = { id = st.seq, kind = kind, ref = ref, by = clip(by, 40) }
    if kind == 'yt' then
        t.title, t.author, t.thumb = 'Chargement…', 'YouTube', 'https://i.ytimg.com/vi/' .. ref .. '/hqdefault.jpg'
    else
        local file = ref:match('([^/?#]+)%.%w+[?#]?[^/]*$') or ref:match('^https?://([^/?#]+)') or 'Flux audio'
        t.title, t.author = clip(file:gsub('[%-_%+]', ' '), 80), clip(ref:match('^https?://([^/?#]+)') or '', 60)
    end
    return t
end

local function allowed(src, netId)
    local ent = NetworkGetEntityFromNetworkId(netId)
    if not ent or ent == 0 or not DoesEntityExist(ent) or GetEntityType(ent) ~= 2 then return nil end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or GetVehiclePedIsIn(ped, false) ~= ent then return nil end
    if Config.ControlSeats == 'driver' and GetPedInVehicleSeat(ent, -1) ~= ped then return nil, 'Seul le conducteur peut piloter la musique.' end
    return ent
end

local function limited(src)
    local t = GetGameTimer()
    if (bucket[src] or 0) + 120 > t then return true end
    bucket[src] = t
    return false
end
AddEventHandler('playerDropped', function() bucket[source] = nil searchAt[source] = nil end)

-- ─────────────────────────────── Commandes ───────────────────────────────
RegisterNetEvent('carplay:server:cmd', function(netId, action, a, b)
    local src = source
    netId = tonumber(netId)
    if not netId or type(action) ~= 'string' or limited(src) then return end
    local ent, why = allowed(src, netId)
    if not ent then if why then notify(src, '~r~' .. why) end return end
    local v = Veh[netId]
    if not v then v = { st = newState(), idle = os.time() } Veh[netId] = v end
    local st = v.st
    local x = ESX.GetPlayerFromId(src)
    local who = x and x.getName and x.getName() or GetPlayerName(src)

    if action == 'power' then
        st.on = not (a == false)
        if not st.on then stopAll(st) end
    elseif action == 'playNow' or action == 'add' then
        local kind, ref = CarPlay.parse(a)
        if not kind then return notify(src, '~r~' .. tostring(ref)) end
        if #st.queue >= Config.QueueMax then return notify(src, '~r~File d\'attente pleine.') end
        st.on = true
        local t = makeTrack(st, kind, ref, who)
        if action == 'playNow' then
            table.insert(st.queue, st.index + 1, t)
            startTrack(st, st.index + 1)
            remember(src, t)
        else
            st.queue[#st.queue + 1] = t
            if not st.playing or st.index == 0 then startTrack(st, #st.queue) remember(src, t) end
        end
        fetchMeta(netId, t)
    elseif action == 'playIndex' then
        local i = math.floor(tonumber(a) or 0)
        if st.queue[i] then startTrack(st, i) remember(src, st.queue[i]) end
    elseif action == 'next' then advance(st, true)
    elseif action == 'prev' then
        if #st.queue == 0 then return end
        if position(st) > 5 or st.index <= 1 then startTrack(st, math.max(1, st.index))
        else startTrack(st, st.index - 1) end
    elseif action == 'pause' then
        if st.playing then st.pausedAt, st.playing = position(st), false end
    elseif action == 'resume' then
        if not st.playing and st.index > 0 then st.startedAt, st.playing = now() - st.pausedAt, true
        elseif st.index == 0 and #st.queue > 0 then startTrack(st, 1) end
    elseif action == 'seek' then
        local t = st.queue[st.index]
        local s = math.max(0, tonumber(a) or 0)
        if t and t.dur and t.dur > 0 then s = math.min(s, math.max(0, t.dur - 1)) end
        if st.playing then st.startedAt = now() - s else st.pausedAt = s end
    elseif action == 'volume' then
        st.volume = math.max(0, math.min(100, math.floor(tonumber(a) or st.volume)))
    elseif action == 'loop' then
        st.loop = (a == 'one' or a == 'all') and a or 'off'
    elseif action == 'shuffle' then
        st.shuffle = a == true
    elseif action == 'speakers' then
        st.speakers = a ~= false
    elseif action == 'remove' then
        local i = math.floor(tonumber(a) or 0)
        if st.queue[i] then
            table.remove(st.queue, i)
            if i < st.index then st.index = st.index - 1
            elseif i == st.index then
                if #st.queue == 0 then st.index = 0 stopAll(st)
                else st.index = math.min(i, #st.queue) startTrack(st, st.index) end
            end
        end
    elseif action == 'clear' then
        st.queue, st.index = {}, 0
        stopAll(st)
    else
        return
    end
    commit(netId)
end)

-- Durée du titre (rapportée par un occupant dont le lecteur l'a chargé) : sert à enchaîner automatiquement côté serveur
RegisterNetEvent('carplay:server:meta', function(netId, rev, dur)
    local src = source
    netId, rev, dur = tonumber(netId), tonumber(rev), tonumber(dur)
    local v = netId and Veh[netId]
    if not v or not allowed(src, netId) or v.st.rev ~= rev then return end
    local t = v.st.queue[v.st.index]
    if not t or t.dur ~= nil then return end
    if dur and dur >= 5 and dur <= 28800 then t.dur = math.floor(dur) else t.dur = 0 end   -- 0 = flux en direct
    commit(netId)
end)

-- Lecture impossible (vidéo non intégrable, lien mort…) : on prévient et on passe au suivant
RegisterNetEvent('carplay:server:error', function(netId, rev, code)
    local src = source
    netId, rev = tonumber(netId), tonumber(rev)
    local v = netId and Veh[netId]
    if not v or not allowed(src, netId) or v.st.rev ~= rev or not v.st.playing then return end
    local t = v.st.queue[v.st.index]
    for _, s in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(s)
        if ped ~= 0 and GetVehiclePedIsIn(ped, false) == NetworkGetEntityFromNetworkId(netId) then
            notify(tonumber(s), ('~r~CarPlay~s~ : lecture impossible%s (code %s).'):format(t and (' de ' .. tostring(t.title)) or '', tostring(code or '?')))
        end
    end
    advance(v.st, false)
    commit(netId)
end)

-- Fin des titres + véhicules vides / supprimés
CreateThread(function()
    while true do
        Wait(1000)
        local n = now()
        for netId, v in pairs(Veh) do
            local ent = NetworkGetEntityFromNetworkId(netId)
            if not ent or ent == 0 or not DoesEntityExist(ent) then
                Veh[netId] = nil
            else
                local st = v.st
                local t = st.queue[st.index]
                if st.playing and t and t.dur and t.dur > 0 and n - st.startedAt >= t.dur + 1 then
                    advance(st, false)
                    commit(netId)
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(20000)
        local minutes = tonumber(Config.StopWhenEmptyMinutes) or 0
        if minutes > 0 then
            local occupied = {}
            for _, s in ipairs(GetPlayers()) do
                local ped = GetPlayerPed(s)
                if ped ~= 0 then
                    local veh = GetVehiclePedIsIn(ped, false)
                    if veh ~= 0 then occupied[veh] = true end
                end
            end
            for netId, v in pairs(Veh) do
                local ent = NetworkGetEntityFromNetworkId(netId)
                if ent and ent ~= 0 and occupied[ent] then v.idle = os.time()
                elseif v.st.playing and os.time() - (v.idle or os.time()) >= minutes * 60 then
                    stopAll(v.st)
                    v.st.queue, v.st.index = {}, 0
                    commit(netId)
                end
            end
        end
    end
end)

-- ─────────────────────────────── Recherche YouTube (clé API facultative) ───────────────────────────────
ESX.RegisterServerCallback('carplay:search', function(src, cb, q)
    local key = GetConvar(Config.YouTubeKeyConvar or 'carplay_youtube_key', '')
    if key == '' then return cb({ ok = false, error = 'Recherche non configurée : colle un lien YouTube.' }) end
    q = clip(q, 80)
    if #q < 2 then return cb({ ok = false, error = 'Recherche trop courte.' }) end
    local t = GetGameTimer()
    if (searchAt[src] or 0) + 1500 > t then return cb({ ok = false, error = 'Doucement : une recherche à la fois.' }) end
    searchAt[src] = t
    local u = ('https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&videoEmbeddable=true&maxResults=12&q=%s&key=%s'):format(
        q:gsub('[^%w]', function(c) return ('%%%02X'):format(c:byte()) end), key)
    PerformHttpRequest(u, function(status, body)
        if status ~= 200 or not body then return cb({ ok = false, error = 'YouTube ne répond pas (code ' .. tostring(status) .. ').' }) end
        local ok, j = pcall(json.decode, body)
        local out = {}
        if ok and type(j) == 'table' and type(j.items) == 'table' then
            for _, it in ipairs(j.items) do
                local id = it.id and it.id.videoId
                local sn = it.snippet or {}
                if type(id) == 'string' and #id == 11 then
                    out[#out + 1] = { kind = 'yt', ref = id, title = clip(sn.title, 160), author = clip(sn.channelTitle, 120), thumb = 'https://i.ytimg.com/vi/' .. id .. '/hqdefault.jpg' }
                end
            end
        end
        cb({ ok = true, results = out })
    end, 'GET')
end)

ESX.RegisterServerCallback('carplay:canSearch', function(_, cb) cb(GetConvar(Config.YouTubeKeyConvar or 'carplay_youtube_key', '') ~= '') end)
