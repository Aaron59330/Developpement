-- ─────────────────────────────── Territoires ───────────────────────────────
-- Zones circulaires créées dans le builder (onglet Territoires). Un gang capture une zone en y restant (une seule équipe présente) ;
-- le propriétaire touche un revenu dans la trésorerie de son gang. Tout est recalculé côté serveur (positions lues avec GetEntityCoords).

local function fail(msg) return { ok = false, error = msg } end

local state = {}      -- [territoire] = { progress, attacker }
local inZone = {}     -- [src] = id du territoire dont le HUD est affiché
local alerted = {}    -- ['<territoire>:<attaquant>'] = fin du délai d'alerte

local function str(v, max, default)
    if type(v) ~= 'string' then return default or '' end
    return (v:gsub('[%c]', '')):sub(1, max or 100)
end

local function num(v, min, max, default)
    v = tonumber(v)
    if not v or v ~= v then return default end
    if min and v < min then v = min end
    if max and v > max then v = max end
    return v
end

-- Valeur d'un territoire (surcharge) ou valeur par défaut de la config
local function val(t, key, default)
    local v = t.settings and tonumber(t.settings[key])
    if v and v >= 0 then return v end
    return default
end

function GB.territoryList()
    local list = {}
    for id, t in pairs(GB.Territories) do
        local o = t.owner and GB.Gangs[t.owner]
        list[#list + 1] = {
            id = id, name = t.name, label = t.label, coords = t.coords, radius = t.radius,
            owner = t.owner, ownerLabel = o and o.label or nil, ownerColor = o and o.color or nil, ownerBlip = o and o.blip and o.blip.color or nil,
            protectedUntil = t.protected_until, now = os.time(),
        }
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

function GB.syncTerritories()
    TriggerClientEvent('gangbuilder:client:territories', -1, GB.territoryList())
end

local function reload()
    GB.Territories = {}
    for _, t in ipairs(MySQL.query.await('SELECT * FROM gangbuilder_territories ORDER BY id') or {}) do
        t.coords = GB.decode(t.coords, { x = 0, y = 0, z = 0 })
        t.settings = GB.decode(t.settings, {})
        if t.owner and not GB.Gangs[t.owner] then t.owner = nil end
        GB.Territories[t.id] = t
    end
end

local function notifyGang(name, message)
    for _, s in ipairs(GB.onlineMembers(name)) do GB.notify(s, message) end
end

local function capture(t, gangName)
    local T, now = Config.Territories, os.time()
    local previous = t.owner
    t.owner, t.captured_at = gangName, now
    t.protected_until = now + math.floor(val(t, 'protection', T.ProtectionMinutes)) * 60
    t.last_income = now
    MySQL.update('UPDATE gangbuilder_territories SET owner = ?, captured_at = ?, protected_until = ?, last_income = ? WHERE id = ?', { gangName, now, t.protected_until, now, t.id })
    GB.addRep(gangName, Config.Rep.PerCapture)
    if GB.questProgress then GB.questProgress(gangName, 'capture', 1) end
    if GB.news then GB.news(('%s a capturé %s%s.'):format(GB.Gangs[gangName].label, t.label, previous and GB.Gangs[previous] and (' à ' .. GB.Gangs[previous].label) or ''), 'territory') end
    GB.log(gangName, nil, 'territory_captured', ('%s%s'):format(t.label, previous and (' (pris à ' .. previous .. ')') or ''))
    if T.AnnounceCapture then
        notifyGang(gangName, ('~g~%s~s~ est à vous !'):format(t.label))
        if previous and previous ~= gangName then notifyGang(previous, ('~r~%s a été perdu : %s l\'a capturé.'):format(t.label, GB.Gangs[gangName].label)) end
    end
    GB.syncTerritories()
end

GB.captureTerritory = capture
function GB.territoryStatus(id) return state[id] end

-- ─────────────────────────────── Calcul de la capture ───────────────────────────────
local function tick()
    local T, now = Config.Territories, os.time()
    local players = {}
    for src, g in pairs(GB.PlayerGang) do
        local gang = GB.Gangs[g.name]
        local ped = GetPlayerPed(src)
        if gang and ped and ped ~= 0 and GetEntityHealth(ped) > 0 then
            local c = GetEntityCoords(ped)
            players[#players + 1] = { src = src, gang = g.name, eligible = g.grade >= (gang.settings.capture_grade or 0), x = c.x, y = c.y, z = c.z }
        end
    end

    local seen = {}
    for id, t in pairs(GB.Territories) do
        local st = state[id] or { progress = 0 }
        state[id] = st
        local present, here = {}, {}
        local c, r = t.coords, t.radius
        for _, p in ipairs(players) do
            local dx, dy = p.x - c.x, p.y - c.y
            if dx * dx + dy * dy <= r * r and math.abs(p.z - c.z) <= 80.0 then
                here[#here + 1] = p
                if p.eligible then present[p.gang] = (present[p.gang] or 0) + 1 end
            end
        end

        local minM = math.floor(val(t, 'min_members', T.MinMembers))
        local step = 100 * T.Tick / math.max(1, val(t, 'capture_seconds', T.CaptureSeconds))
        local protected = (t.protected_until or 0) > now
        local attackers, others = {}, 0
        for gname, n in pairs(present) do
            if gname ~= t.owner then
                others = others + 1
                if n >= minM then attackers[#attackers + 1] = gname end
            end
        end
        local ownerPresent = t.owner and (present[t.owner] or 0) > 0
        local status = 'idle'

        if protected then
            st.progress, st.attacker, status = 0, nil, 'protected'
        elseif others == 1 and #attackers == 1 and not (T.OwnerBlocks and ownerPresent) then
            local a = attackers[1]
            if st.attacker ~= a then st.attacker, st.progress = a, 0 end
            if T.AlertOwner and t.owner and GB.Gangs[t.owner] then
                local key = id .. ':' .. a
                if (alerted[key] or 0) <= now then
                    alerted[key] = now + math.max(10, T.AlertCooldown or 120)
                    notifyGang(t.owner, ('~r~%s~s~ attaque votre territoire ~y~%s~s~ !'):format(GB.Gangs[a].label, t.label))
                end
            end
            st.progress = st.progress + step
            status = 'capturing'
            if st.progress >= 100 then
                capture(t, a)
                st.progress, st.attacker, status = 0, nil, 'captured'
            end
        elseif others > 1 or (others >= 1 and ownerPresent and T.OwnerBlocks) then
            status = 'contested'                              -- plusieurs équipes : la capture est gelée
        elseif st.progress > 0 then
            st.progress = math.max(0, st.progress - step * T.DecayFactor)
            if st.progress == 0 then st.attacker = nil end
            status = 'decaying'
        end

        if status == 'idle' and others >= 1 and #attackers == 0 then status = 'short' end   -- des rivaux sont là mais pas assez nombreux

        -- HUD des joueurs présents
        for _, p in ipairs(here) do
            seen[p.src] = id
            local o = t.owner and GB.Gangs[t.owner]
            local a = st.attacker and GB.Gangs[st.attacker]
            TriggerClientEvent('gangbuilder:client:zone', p.src, {
                id = id, label = t.label, progress = math.floor(st.progress * 10) / 10, status = status, need = minM,
                owner = o and o.label or nil, attacker = a and a.label or nil, color = a and a.color or (o and o.color or nil),
                protectedLeft = protected and (t.protected_until - now) or 0,
                conflict = GB.conflictInfo and GB.conflictInfo(id) or nil,
            })
        end
    end
    for src in pairs(inZone) do
        if not seen[src] then TriggerClientEvent('gangbuilder:client:zone', src, nil) end
    end
    inZone = seen
end

CreateThread(function()
    while true do
        Wait(math.max(1, Config.Territories.Tick) * 1000)
        if Config.Territories.Enabled and GB.ready and next(GB.Territories) then
            local ok, err = pcall(tick)
            if not ok then print(('^1[gangbuilder] erreur territoires : %s^0'):format(tostring(err))) end
        end
    end
end)

-- ─────────────────────────────── Revenus ───────────────────────────────
CreateThread(function()
    while true do
        Wait(30 * 1000)
        local T, now = Config.Territories, os.time()
        if T.Enabled and GB.ready then
            for id, t in pairs(GB.Territories) do
                if t.owner and GB.Gangs[t.owner] then
                    local interval = math.max(1, val(t, 'interval', T.IncomeInterval)) * 60
                    if (t.last_income or 0) == 0 then
                        t.last_income = now
                        MySQL.update('UPDATE gangbuilder_territories SET last_income = ? WHERE id = ?', { now, id })
                    elseif now - t.last_income >= interval then
                        local reward = math.floor(val(t, 'reward', T.Reward))
                        t.last_income = now
                        MySQL.update('UPDATE gangbuilder_territories SET last_income = ? WHERE id = ?', { now, id })
                        if reward > 0 and GB.treasuryAdd(t.owner, T.RewardAccount == 'money' and 'money' or 'dirty', reward) then
                            GB.addRep(t.owner, Config.Rep.PerIncome)
                            GB.log(t.owner, nil, 'territory_income', ('%s : %d$'):format(t.label, reward))
                            notifyGang(t.owner, ('Revenu de ~g~%s~s~ : ~g~+%d$'):format(t.label, reward))
                        end
                    end
                end
            end
        end
    end
end)

-- ─────────────────────────────── Administration (builder → onglet Territoires) ───────────────────────────────
ESX.RegisterServerCallback('gangbuilder:terr:list', function(src, cb)
    if not GB.isDev(src) then return cb({}) end
    local list = {}
    for id, t in pairs(GB.Territories) do
        local o = t.owner and GB.Gangs[t.owner]
        list[#list + 1] = {
            id = id, name = t.name, label = t.label, coords = t.coords, radius = t.radius, settings = t.settings or {},
            owner = t.owner, ownerLabel = o and o.label or nil, protectedUntil = t.protected_until, capturedAt = t.captured_at,
            progress = state[id] and state[id].progress or 0,
        }
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    cb(list)
end)

ESX.RegisterServerCallback('gangbuilder:terr:save', function(src, cb, t)
    if not GB.isDev(src) then return cb(fail('Permission refusée')) end
    if type(t) ~= 'table' then return cb(fail('Données invalides')) end
    local T = Config.Territories
    local name = str(t.name, 50):lower()
    if not name:match('^[a-z][a-z0-9_]+$') then return cb(fail('Nom invalide (minuscules, chiffres, _ ; commence par une lettre)')) end
    local label = str(t.label, 100)
    if label == '' then return cb(fail('Le label est obligatoire')) end
    local c = type(t.coords) == 'table' and t.coords or {}
    local x, y, z = tonumber(c.x), tonumber(c.y), tonumber(c.z)
    if not (x and y and z) then return cb(fail('Position manquante : place le centre du territoire')) end
    local radius = num(t.radius, 5, T.MaxRadius, T.DefaultRadius)
    local s = type(t.settings) == 'table' and t.settings or {}
    local settings = {}
    for _, k in ipairs({ 'reward', 'capture_seconds', 'min_members', 'interval', 'protection' }) do
        local v = tonumber(s[k])
        if v and v >= 0 then settings[k] = math.floor(v) end
    end
    local coords = { x = math.floor(x * 100) / 100, y = math.floor(y * 100) / 100, z = math.floor(z * 100) / 100 }

    local id = tonumber(t.id)
    if id and GB.Territories[id] then
        local ok, err = pcall(MySQL.update.await, 'UPDATE gangbuilder_territories SET name = ?, label = ?, coords = ?, radius = ?, settings = ? WHERE id = ?',
            { name, label, json.encode(coords), radius, json.encode(settings), id })
        if not ok then return cb(fail('Ce nom est déjà utilisé par un autre territoire')) end
    else
        if GB.count(GB.Territories) >= T.MaxTerritories then return cb(fail(('Limite atteinte : %d territoires maximum'):format(T.MaxTerritories))) end
        local ok, res = pcall(MySQL.insert.await, 'INSERT INTO gangbuilder_territories (name, label, coords, radius, settings) VALUES (?, ?, ?, ?, ?)',
            { name, label, json.encode(coords), radius, json.encode(settings) })
        if not ok then return cb(fail('Ce nom est déjà utilisé par un autre territoire')) end
        id = res
    end
    reload()
    GB.syncTerritories()
    GB.log('_territories', ESX.GetPlayerFromId(src), 'territory_saved', ('%s (%s)'):format(label, name))
    cb({ ok = true, id = id })
end)

ESX.RegisterServerCallback('gangbuilder:terr:delete', function(src, cb, id)
    if not GB.isDev(src) then return cb(fail('Permission refusée')) end
    id = tonumber(id)
    local t = id and GB.Territories[id]
    if not t then return cb(fail('Territoire introuvable')) end
    MySQL.update.await('DELETE FROM gangbuilder_territories WHERE id = ?', { id })
    state[id] = nil
    reload()
    GB.syncTerritories()
    GB.log('_territories', ESX.GetPlayerFromId(src), 'territory_deleted', t.label)
    cb({ ok = true })
end)

-- Attribue un territoire à un gang (ou le libère avec gangName = nil)
ESX.RegisterServerCallback('gangbuilder:terr:setOwner', function(src, cb, id, gangName)
    if not GB.isDev(src) then return cb(fail('Permission refusée')) end
    id = tonumber(id)
    local t = id and GB.Territories[id]
    if not t then return cb(fail('Territoire introuvable')) end
    if gangName and gangName ~= '' and not GB.Gangs[gangName] then return cb(fail('Gang inconnu')) end
    local now = os.time()
    local owner = (gangName and gangName ~= '') and gangName or nil
    t.owner, t.captured_at, t.protected_until, t.last_income = owner, owner and now or 0, 0, owner and now or 0
    MySQL.update.await('UPDATE gangbuilder_territories SET owner = ?, captured_at = ?, protected_until = 0, last_income = ? WHERE id = ?', { owner, t.captured_at, t.last_income, id })
    if state[id] then state[id].progress, state[id].attacker = 0, nil end
    GB.syncTerritories()
    GB.log(owner or '_territories', ESX.GetPlayerFromId(src), 'territory_set_owner', ('%s -> %s'):format(t.label, owner or 'libre'))
    cb({ ok = true })
end)
