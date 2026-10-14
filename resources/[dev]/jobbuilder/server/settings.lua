-- ─────────────────────────────── Paramètres modifiables en jeu (réservé aux groupes autorisés) ───────────────────────────────
-- Chaque section est validée strictement, stockée en base (jobbuilder_settings), appliquée à Config en place
-- côté serveur puis diffusée à tous les clients.

local function fail(msg) return { ok = false, error = msg } end

local function num(v, min, max, default)
    v = tonumber(v)
    if not v or v ~= v then return default end
    if v < min then v = min end
    if v > max then v = max end
    return v
end
local function int(v, min, max, default) local n = num(v, min, max, default) return n and math.floor(n) or default end
local function str(v, max, default)
    if type(v) ~= 'string' then return default or '' end
    return (v:gsub('%c', '')):sub(1, max)
end
local function color(c, default)
    if type(c) ~= 'table' then return default end
    return { int(c[1], 0, 255, default[1]), int(c[2], 0, 255, default[2]), int(c[3], 0, 255, default[3]) }
end
local function cmd(v, default)
    v = str(v, 30, default):lower():gsub('[^%w_]', '')
    return v ~= '' and v or default
end
local function deepcopyMap(m) return { Tiles = m.Tiles or '', TileMaxZoom = m.TileMaxZoom or 5, Image = m.Image or '', LabelColor = m.LabelColor, LabelOutline = m.LabelOutline, MinX = m.MinX, MaxX = m.MaxX, MinY = m.MinY, MaxY = m.MaxY } end
local function coords(c)
    if type(c) ~= 'table' then return nil end
    local x, y, z = tonumber(c.x), tonumber(c.y), tonumber(c.z)
    if not (x and y and z) then return nil end
    return { x = math.floor(x * 10000) / 10000, y = math.floor(y * 10000) / 10000, z = math.floor(z * 10000) / 10000, h = math.floor((tonumber(c.h) or 0) * 100) / 100 }
end

-- Définition complète d'un marker (type, couleur, transparence, taille, hauteur, animation)
local function markerDef(d, base)
    d = type(d) == 'table' and d or {}
    base = base or {}
    local scale = type(d.scale) == 'table' and d.scale or {}
    local bscale = base.scale or { x = 0.9, y = 0.9, z = 0.6 }
    return {
        marker = int(d.marker, 0, 50, base.marker or 1),
        color = color(d.color, base.color or { 255, 255, 255 }),
        alpha = int(d.alpha, 0, 255, base.alpha or 140),
        scale = { x = num(scale.x, 0.05, 20, bscale.x), y = num(scale.y, 0.05, 20, bscale.y), z = num(scale.z, 0.05, 20, bscale.z) },
        offset = num(d.offset, -10, 10, base.offset or -0.95),
        bob = d.bob == true,
        rotate = d.rotate == true,
        help = d.help ~= false,
    }
end

local function withLabel(d, base)
    local out = markerDef(d, base)
    out.label = str(d and d.label, 40, base.label or '')
    if out.label == '' then out.label = base.label or '' end
    return out
end

local S = {}

S.general = function(v, src)
    if type(v) ~= 'table' then return nil, 'Données invalides' end
    local out = {
        DrawDistance = num(v.DrawDistance, 3, 100, Config.DrawDistance),
        InteractDistance = num(v.InteractDistance, 0.5, 6, Config.InteractDistance),
        ServerDistance = num(v.ServerDistance, 2, 60, Config.ServerDistance),
        TargetDistance = num(v.TargetDistance, 1, 20, Config.TargetDistance),
        MaxGrades = int(v.MaxGrades, 1, 50, Config.MaxGrades),
        MaxPoints = int(v.MaxPoints, 1, 300, Config.MaxPoints),
        MaxItemsPerPoint = int(v.MaxItemsPerPoint, 1, 300, Config.MaxItemsPerPoint),
        PlatePrefixLength = int(v.PlatePrefixLength, 1, 4, Config.PlatePrefixLength),
        ReviveEvent = str(v.ReviveEvent, 80, Config.ReviveEvent),
        Webhook = str(v.Webhook, 300, ''),
        AcePermission = str(v.AcePermission, 60, ''),
        Inventory = (v.Inventory == 'ox' or v.Inventory == 'esx') and v.Inventory or 'auto',
        ActionDuration = {
            repair = int(type(v.ActionDuration) == 'table' and v.ActionDuration.repair, 1000, 120000, Config.ActionDuration.repair),
            clean = int(type(v.ActionDuration) == 'table' and v.ActionDuration.clean, 1000, 120000, Config.ActionDuration.clean),
        },
        AllowedGroups = {}, RestartResources = {},
    }
    local protected = { es_extended = true, oxmysql = true, jobbuilder = true, ox_lib = true, ox_inventory = true, ['mysql-async'] = true, ['ghmattimysql'] = true, monitor = true, sessionmanager = true }
    for _, r in ipairs(type(v.RestartResources) == 'table' and v.RestartResources or {}) do
        r = str(r, 60):gsub('%s', '')
        if r ~= '' then
            if not r:match('^[%w_%-%.]+$') then return nil, ('Nom de ressource invalide : « %s »'):format(r) end
            if protected[r] then return nil, ('« %s » est protégée : elle ne peut pas être redémarrée automatiquement'):format(r) end
            if #out.RestartResources < 8 then out.RestartResources[#out.RestartResources + 1] = r end
        end
    end
    for _, g in ipairs(type(v.AllowedGroups) == 'table' and v.AllowedGroups or {}) do
        g = str(g, 40):gsub('%s', '')
        if g:match('^[%w_%-]+$') and #out.AllowedGroups < 10 then out.AllowedGroups[#out.AllowedGroups + 1] = g end
    end
    if #out.AllowedGroups == 0 then return nil, 'Il faut au moins un groupe autorisé' end
    -- Garde-fou : on ne peut pas se retirer l'accès à soi-même
    local x = src and src ~= 0 and ESX.GetPlayerFromId(src)
    if x then
        local ok = false
        for _, g in ipairs(out.AllowedGroups) do if x.getGroup() == g then ok = true end end
        if not ok and not (out.AcePermission ~= '' and IsPlayerAceAllowed(src, out.AcePermission)) then
            return nil, ('Tu t\'enlèverais l\'accès à toi-même : garde ton groupe (%s) dans la liste'):format(x.getGroup())
        end
    end
    return out
end

S.pointTypes = function(v)
    if type(v) ~= 'table' then return nil, 'Données invalides' end
    local out = {}
    for key, base in pairs(Config.PointTypes) do          -- on ne peut pas ajouter de nouveaux types (code), seulement modifier
        out[key] = withLabel(v[key], base)
        out[key].hidden = base.hidden
    end
    return out
end

S.real = function(v)
    if type(v) ~= 'table' then return nil, 'Données invalides' end
    local R = Config.Real
    local out = {
        RentDays = int(v.RentDays, 1, 60, R.RentDays), MaxRentAhead = int(v.MaxRentAhead, 1, 12, R.MaxRentAhead),
        MaxPerPlayer = int(v.MaxPerPlayer, 1, 50, R.MaxPerPlayer), MaxKeys = int(v.MaxKeys, 0, 20, R.MaxKeys),
        MaxPointsPerProp = int(v.MaxPointsPerProp, 1, 50, R.MaxPointsPerProp), OutfitsPerPlayer = int(v.OutfitsPerPlayer, 1, 50, R.OutfitsPerPlayer),
        DefaultCommission = int(v.DefaultCommission, 0, 50, R.DefaultCommission), RentCheckMinutes = int(v.RentCheckMinutes, 1, 120, R.RentCheckMinutes),
        ShowBlips = v.ShowBlips == true, Blips = {}, PointTypes = {}, Markers = {},
    }
    local b = type(v.Blips) == 'table' and v.Blips or {}
    for _, k in ipairs({ 'sale', 'rent' }) do
        local d = type(b[k]) == 'table' and b[k] or {}
        out.Blips[k] = { sprite = int(d.sprite, 0, 900, R.Blips[k].sprite), color = int(d.color, 0, 85, R.Blips[k].color), scale = num(d.scale, 0.1, 3, R.Blips[k].scale) }
    end
    for key, base in pairs(R.PointTypes) do out.PointTypes[key] = withLabel(type(v.PointTypes) == 'table' and v.PointTypes[key], base) end
    for key, base in pairs(R.Markers) do out.Markers[key] = markerDef(type(v.Markers) == 'table' and v.Markers[key], base) end
    return out
end

S.interiors = function(v)
    if type(v) ~= 'table' then return nil, 'Données invalides' end
    local out, n = {}, 0
    for key, i in pairs(v) do
        key = tostring(key)
        if key == 'custom' or not key:match('^[a-z0-9_]+$') or #key < 2 or #key > 20 then return nil, ('Clé d\'intérieur invalide : « %s » (a-z, 0-9, _ ; 2-20 car.)'):format(key) end
        local exit = type(i) == 'table' and coords(i.exit)
        if not exit then return nil, ('Intérieur « %s » : position de sortie manquante'):format(key) end
        n = n + 1
        if n > 30 then return nil, 'Maximum 30 intérieurs' end
        out[key] = { label = str(i.label, 60, key), exit = exit }
    end
    for key in pairs(Config.Real.Interiors) do
        if not out[key] then
            local used = MySQL.scalar.await('SELECT COUNT(*) FROM jobbuilder_properties WHERE interior = ?', { key }) or 0
            if used > 0 then return nil, ('Impossible de supprimer « %s » : %d propriété(s) l\'utilisent'):format(key, used) end
        end
    end
    return out
end

S.jobTypes = function(v)
    if type(v) ~= 'table' then return nil, 'Données invalides' end
    local out, n = {}, 0
    for key, t in pairs(v) do
        key = tostring(key)
        if not key:match('^[a-z][a-z0-9_]+$') or #key < 2 or #key > 20 then return nil, ('Clé de modèle invalide : « %s »'):format(key) end
        if type(t) ~= 'table' then return nil, 'Modèle invalide' end
        n = n + 1
        if n > 30 then return nil, 'Maximum 30 modèles' end
        local blip = type(t.blip) == 'table' and t.blip or {}
        local clean = {
            label = str(t.label, 40, key),
            blip = { sprite = int(blip.sprite, 0, 900, 478), color = int(blip.color, 0, 85, 0), scale = num(blip.scale, 0.3, 2, 0.9) },
            actions = {}, grades = {},
            points = (Config.JobTypes[key] and Config.JobTypes[key].points) or { 'garage', 'cloakroom', 'armory', 'stash', 'boss', 'shop' },
        }
        for _, a in ipairs(type(t.actions) == 'table' and t.actions or {}) do
            if Config.Actions[a] and a ~= 'properties' then clean.actions[#clean.actions + 1] = a end
        end
        for i, g in ipairs(type(t.grades) == 'table' and t.grades or {}) do
            if i > Config.MaxGrades then break end
            local gname = str(g.name, 40, 'grade' .. (i - 1)):lower():gsub('[^%w_]', '_')
            clean.grades[#clean.grades + 1] = { name = gname ~= '' and gname or ('grade' .. (i - 1)), label = str(g.label, 50, gname), salary = int(g.salary, 0, 1000000, 0) }
        end
        if #clean.grades == 0 then return nil, ('Modèle « %s » : il faut au moins un grade'):format(key) end
        out[key] = clean
    end
    if not out.custom then return nil, 'Le modèle « custom » est obligatoire' end
    for name, job in pairs(JB.Jobs) do
        if not out[job.type] then return nil, ('Impossible de supprimer le modèle « %s » : le job « %s » l\'utilise'):format(job.type, name) end
    end
    return out
end

S.ui = function(v)
    if type(v) ~= 'table' then return nil, 'Données invalides' end
    return { Accent = color(v.Accent, Config.UI.Accent) }
end

S.dealer = function(v)
    if type(v) ~= 'table' then return nil, 'Données invalides' end
    local D = Config.Dealer
    return {
        Delivery = v.Delivery == 'garage' and 'garage' or 'spawn',
        StateOut = int(v.StateOut, -10, 100, D.StateOut), StateStored = int(v.StateStored, -10, 100, D.StateStored),
        TestSeconds = int(v.TestSeconds, 30, 900, D.TestSeconds), DefaultCommission = int(v.DefaultCommission, 0, 50, D.DefaultCommission),
        MaxVehiclesPerPlayer = int(v.MaxVehiclesPerPlayer, 0, 500, D.MaxVehiclesPerPlayer), DisplayDistance = num(v.DisplayDistance, 10, 200, D.DisplayDistance),
    }
end

S.police = function(v)
    if type(v) ~= 'table' then return nil, 'Données invalides' end
    local P = Config.Police
    local out = {
        PursuitMax = int(v.PursuitMax, 30, 7200, P.PursuitMax), PursuitTrail = int(v.PursuitTrail, 5, 200, P.PursuitTrail),
        NearbyRange = int(v.NearbyRange, 10, 500, P.NearbyRange), RefreshMs = int(v.RefreshMs, 1000, 10000, P.RefreshMs),
        CallCooldown = int(v.CallCooldown, 0, 600, P.CallCooldown), MaxCalls = int(v.MaxCalls, 10, 500, P.MaxCalls),
        ClosedKeepMinutes = int(v.ClosedKeepMinutes, 1, 1440, P.ClosedKeepMinutes),
        MinFine = int(v.MinFine, 1, 1000000, P.MinFine), MaxFine = int(v.MaxFine, 1, 100000000, P.MaxFine),
        CallCommand = cmd(v.CallCommand, P.CallCommand), PanicCommand = cmd(v.PanicCommand, P.PanicCommand),
        DefaultFines = {}, Landmarks = {}, Map = {},
    }
    if out.MinFine > out.MaxFine then out.MinFine = out.MaxFine end
    for _, f in ipairs(type(v.DefaultFines) == 'table' and v.DefaultFines or {}) do
        local label = str(f.label, 60)
        if label ~= '' and #out.DefaultFines < 60 then out.DefaultFines[#out.DefaultFines + 1] = { label = label, amount = int(f.amount, 1, 100000000, 100) } end
    end
    for _, l in ipairs(type(v.Landmarks) == 'table' and v.Landmarks or {}) do
        local x, y = tonumber(l[2]), tonumber(l[3])
        if x and y and str(l[1], 40) ~= '' and #out.Landmarks < 60 then out.Landmarks[#out.Landmarks + 1] = { str(l[1], 40), x, y } end
    end
    local m = type(v.Map) == 'table' and v.Map or {}
    local function safePath(x, needTiles)
        x = str(x, 200)
        if x == '' or x:find('%.%.') or not x:match('^[%w_%-%./:{}%%]+$') then return '' end
        if x:match('^%a+:') and not x:match('^https://') then return '' end
        if needTiles and not (x:find('{z}', 1, true) and x:find('{x}', 1, true) and x:find('{y}', 1, true)) then return '' end
        return x
    end
    out.Map = { Tiles = safePath(m.Tiles, true), TileMaxZoom = int(m.TileMaxZoom, 1, 8, P.Map.TileMaxZoom or 5), Image = safePath(m.Image, false), LabelColor = color(m.LabelColor, P.Map.LabelColor or { 255, 255, 255 }), LabelOutline = m.LabelOutline ~= false,
        MinX = tonumber(m.MinX) or P.Map.MinX, MaxX = tonumber(m.MaxX) or P.Map.MaxX, MinY = tonumber(m.MinY) or P.Map.MinY, MaxY = tonumber(m.MaxY) or P.Map.MaxY }
    if out.Map.MaxX <= out.Map.MinX or out.Map.MaxY <= out.Map.MinY then out.Map = deepcopyMap(P.Map) end
    return out
end

S.tuning = function(v)
    if type(v) ~= 'table' then return nil, 'Données invalides' end
    local T = Config.Tuning
    local out = { Radius = num(v.Radius, 2, 30, T.Radius), Prices = {} }
    local src = type(v.Prices) == 'table' and v.Prices or {}
    for k, base in pairs(T.Prices) do
        if type(base) == 'table' then
            local arr = {}
            for i = 1, #base do arr[i] = int(type(src[k]) == 'table' and src[k][i], 0, 10000000, base[i]) end
            out.Prices[k] = arr
        else
            out.Prices[k] = int(src[k], 0, 10000000, base)
        end
    end
    return out
end

S.death = function(v)
    if type(v) ~= 'table' then return nil, 'Données invalides' end
    local D = Config.Death
    local out = {
        Mode = (v.Mode == 'on' or v.Mode == 'off') and v.Mode or 'auto', RespawnTime = int(v.RespawnTime, 10, 3600, D.RespawnTime), NoEmsRespawn = int(v.NoEmsRespawn, 0, 3600, D.NoEmsRespawn),
        CallCooldown = int(v.CallCooldown, 0, 600, D.CallCooldown), RespawnFee = int(v.RespawnFee, 0, 1000000, D.RespawnFee), UnpaidAllowed = v.UnpaidAllowed ~= false, RestoreStatus = v.RestoreStatus ~= false, FeeAccount = v.FeeAccount == 'money' and 'money' or 'bank',
        ReviveHealth = int(v.ReviveHealth, 10, 100, D.ReviveHealth), RespawnHealth = int(v.RespawnHealth, 10, 100, D.RespawnHealth), CprSeconds = int(v.CprSeconds, 2, 60, D.CprSeconds),
        RevivePay = int(v.RevivePay, 0, 1000000, D.RevivePay), ReviveAnim = v.ReviveAnim ~= false, OxygenHud = v.OxygenHud ~= false, OxygenWarn = int(v.OxygenWarn, 1, 30, D.OxygenWarn), OxygenCustom = v.OxygenCustom ~= false, OxygenSeconds = int(v.OxygenSeconds, 5, 600, D.OxygenSeconds), OxygenDamage = int(v.OxygenDamage, 1, 100, D.OxygenDamage), Hospitals = {},
    }
    for _, h in ipairs(type(v.Hospitals) == 'table' and v.Hospitals or {}) do
        local x, y, z = tonumber(h[2]), tonumber(h[3]), tonumber(h[4])
        if x and y and z and str(h[1], 40) ~= '' and #out.Hospitals < 20 then out.Hospitals[#out.Hospitals + 1] = { str(h[1], 40), x, y, z, tonumber(h[5]) or 0.0 } end
    end
    if #out.Hospitals == 0 then for i, h in ipairs(D.Hospitals) do out.Hospitals[i] = h end end
    return out
end

S.announce = function(v)
    if type(v) ~= 'table' then return nil, 'Données invalides' end
    local A = Config.Announce
    local out = {
        Enabled = v.Enabled ~= false, Cooldown = int(v.Cooldown, 0, 86400, A.Cooldown), Cost = int(v.Cost, 0, 1000000, A.Cost),
        Duration = int(v.Duration, 3, 60, A.Duration), MaxTitle = int(v.MaxTitle, 10, 80, A.MaxTitle), MaxText = int(v.MaxText, 40, 500, A.MaxText),
        History = int(v.History, 1, 100, A.History), ToggleCommand = cmd(v.ToggleCommand, A.ToggleCommand), Types = {},
    }
    local used = {}
    for _, t in ipairs(type(v.Types) == 'table' and v.Types or {}) do
        local id = str(t.id, 20):lower():gsub('[^%w_]', '')
        if id ~= '' and not used[id] and #out.Types < 20 then
            used[id] = true
            out.Types[#out.Types + 1] = { id = id, label = str(t.label, 30) ~= '' and str(t.label, 30) or id, color = color(t.color, { 64, 224, 208 }) }
        end
    end
    if #out.Types == 0 then out.Types = (function() local c = {} for i, t in ipairs(A.Types) do c[i] = t end return c end)() end
    return out
end

S.gov = function(v)
    if type(v) ~= 'table' then return nil, 'Données invalides' end
    local G = Config.Gov
    local out = {
        AnnounceCooldown = int(v.AnnounceCooldown, 10, 3600, G.AnnounceCooldown), AnnounceMax = int(v.AnnounceMax, 20, 500, G.AnnounceMax),
        GrantMax = int(v.GrantMax, 1, 1000000000, G.GrantMax), PrimeMax = int(v.PrimeMax, 1, 1000000000, G.PrimeMax), Taxes = {},
    }
    for k in pairs(G.Taxes) do out.Taxes[k] = int(type(v.Taxes) == 'table' and v.Taxes[k], 0, 50, G.Taxes[k]) end
    return out
end

local STEP_TYPES = { spawn_vehicle = true, ['goto'] = true, interact = true, pickup_npc = true, dropoff_npc = true }
local ANIMS = { give = true, work = true, repair = true, heal = true, inspect = true, talk = true }

local function modelList(l, max)
    local out = {}
    for _, m in ipairs(type(l) == 'table' and l or {}) do
        m = str(m, 40):lower()
        if m:match('^[%w_]+$') and #out < max then out[#out + 1] = m end
    end
    return out
end

S.missions = function(v)
    if type(v) ~= 'table' then return nil, 'Données invalides' end
    local M = Config.Missions
    local out = {
        Enabled = v.Enabled ~= false, Cooldown = int(v.Cooldown, 0, 3600, M.Cooldown), MinSeconds = int(v.MinSeconds, 0, 600, M.MinSeconds),
        Tolerance = num(v.Tolerance, 20, 300, M.Tolerance), RewardAccount = v.RewardAccount == 'bank' and 'bank' or 'money',
        TimeBonus = int(v.TimeBonus, 0, 100, M.TimeBonus), DamageMaxPenalty = int(v.DamageMaxPenalty, 0, 90, M.DamageMaxPenalty),
        Peds = modelList(v.Peds, 30), Locations = {}, Templates = {},
    }
    if #out.Peds == 0 then out.Peds = { 'a_m_y_business_01' } end

    local n = 0
    for key, l in pairs(type(v.Locations) == 'table' and v.Locations or {}) do
        key = tostring(key)
        if not key:match('^[%w_]+$') or #key > 24 then return nil, ('Clé de lieu invalide : « %s »'):format(key) end
        local c = type(l) == 'table' and coords(l)
        if not c then return nil, ('Lieu « %s » : position manquante'):format(key) end
        n = n + 1
        if n > 60 then return nil, 'Maximum 60 lieux' end
        out.Locations[key] = { label = str(l.label, 50, key), x = c.x, y = c.y, z = c.z, h = c.h }
    end
    if n < 3 then return nil, 'Il faut au moins 3 lieux de mission' end

    for jtype, list in pairs(type(v.Templates) == 'table' and v.Templates or {}) do
        jtype = tostring(jtype)
        if not jtype:match('^[a-z][a-z0-9_]+$') or #jtype > 20 then return nil, ('Type de job invalide : « %s »'):format(jtype) end
        local clean, ids = {}, {}
        for _, t in ipairs(type(list) == 'table' and list or {}) do
            if #clean >= 12 then break end
            local id = str(t.id, 30):lower()
            if not id:match('^[a-z0-9_]+$') or ids[id] then return nil, ('Mission « %s » : identifiant invalide ou en double (a-z, 0-9, _)'):format(jtype) end
            ids[id] = true
            local reward = type(t.reward) == 'table' and t.reward or {}
            local rmin, rmax = int(reward.min, 0, 1000000, 0), int(reward.max, 0, 1000000, 0)
            if rmax < rmin then rmin, rmax = rmax, rmin end
            local veh = type(t.vehicle) == 'table' and t.vehicle or {}
            local tpl = {
                id = id, label = str(t.label, 50, id), desc = str(t.desc, 220), minGrade = int(t.minGrade, 0, 50, 0),
                reward = { min = rmin, max = rmax }, cooldown = int(t.cooldown, 0, 3600, M.Cooldown), timeLimit = int(t.timeLimit, 0, 7200, 0),
                vehicle = { source = veh.source == 'catalog' and 'catalog' or 'models', models = modelList(veh.models, 20) },
                peds = modelList(t.peds, 10), steps = {},
            }
            for _, st in ipairs(type(t.steps) == 'table' and t.steps or {}) do
                if #tpl.steps >= 14 then break end
                if type(st) == 'table' and STEP_TYPES[st.t] then
                    tpl.steps[#tpl.steps + 1] = {
                        t = st.t, label = str(st.label, 60, ''), secs = int(st.secs, 1, 120, 5), where = st.where == 'start' and 'start' or 'loc',
                        same = st.same == true, anim = ANIMS[st.anim] and st.anim or 'talk', broken = st.broken == true, veh = st.veh == true,
                        npc = st.npc ~= false, patient = st.patient == true, consume = st.consume == true,
                    }
                end
            end
            if #tpl.steps == 0 then return nil, ('Mission « %s » : ajoute au moins une étape'):format(tpl.label) end
            clean[#clean + 1] = tpl
        end
        out.Templates[jtype] = clean
    end
    if not out.Templates.custom or #out.Templates.custom == 0 then return nil, 'Le type « custom » doit avoir au moins une mission (utilisé par les jobs sans modèle)' end
    return out
end

-- ─────────────────────────────── Persistance / application ───────────────────────────────
local function broadcast()
    TriggerClientEvent('jobbuilder:client:config', -1, JB.configSnapshot())
end

local function clone(v)
    if type(v) ~= 'table' then return v end
    local o = {}
    for k, x in pairs(v) do o[k] = clone(x) end
    return o
end

CreateThread(function()
    while not JB.ready do Wait(100) end
    -- Nouveau modèle livré avec le script (banque) : les réglages déjà enregistrés en base remplacent les modèles par défaut, on l'ajoute donc une seule fois
    local newType, newTpl = clone(Config.JobTypes.bank), clone(Config.Missions.Templates.bank)
    for _, row in ipairs(MySQL.query.await('SELECT name, value FROM jobbuilder_settings') or {}) do
        local v = JB.decode(row.value, nil)
        local sanitize = S[row.name]
        if v and sanitize then
            local ok, clean = pcall(sanitize, v, 0)
            if ok and clean then JBSet(row.name, clean) end
        end
    end
    local seen = MySQL.scalar.await("SELECT 1 FROM jobbuilder_settings WHERE name = '_seen_bank'")
    if not seen then
        local touched = false
        if newType and not Config.JobTypes.bank then Config.JobTypes.bank = newType touched = true end
        if newTpl and not Config.Missions.Templates.bank then Config.Missions.Templates.bank = newTpl touched = true end
        MySQL.update.await("INSERT INTO jobbuilder_settings (name, value) VALUES ('_seen_bank', '1') ON DUPLICATE KEY UPDATE value = '1'")
        if touched then
            if Config.JobTypes.bank then MySQL.update.await("INSERT INTO jobbuilder_settings (name, value) VALUES ('jobTypes', ?) ON DUPLICATE KEY UPDATE value = VALUES(value)", { json.encode(JBGet('jobTypes')) }) end
            if Config.Missions.Templates.bank then MySQL.update.await("INSERT INTO jobbuilder_settings (name, value) VALUES ('missions', ?) ON DUPLICATE KEY UPDATE value = VALUES(value)", { json.encode(JBGet('missions')) }) end
        end
    end
    Wait(500)
    broadcast()
end)

-- Utilisable par d'autres modules (ex : le gouverneur règle les taxes)
function JB.saveSetting(section, value, src, who)
    if not S[section] then return nil, 'Section inconnue' end
    local clean, err = S[section](value, src)
    if not clean then return nil, err end
    MySQL.query.await('INSERT INTO jobbuilder_settings (name, value, updated_by) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE value = VALUES(value), updated_by = VALUES(updated_by)',
        { section, json.encode(clean), who or 'système' })
    JBSet(section, clean)
    broadcast()
    return clean
end

ESX.RegisterServerCallback('jobbuilder:settings:get', function(src, cb)
    if not JB.isDev(src) then return cb(fail('Permission refusée (groupe non autorisé)')) end
    local ok, res = pcall(function()
        local values = {}
        for _, sec in ipairs(JB_SECTIONS) do values[sec] = JBGet(sec) end
        return { ok = true, values = values, defaults = JBDefaults }
    end)
    if not ok then
        print(('^1[jobbuilder] settings:get a échoué : %s^0'):format(tostring(res)))
        return cb(fail('Erreur serveur (voir la console) : ' .. tostring(res)))
    end
    cb(res)
end)

ESX.RegisterServerCallback('jobbuilder:settings:save', function(src, cb, section, value)
    if not JB.isDev(src) then return cb(fail('Permission refusée')) end
    if not S[section] then return cb(fail('Section inconnue')) end
    local clean, err = S[section](value, src)
    if not clean then return cb(fail(err)) end
    MySQL.query.await('INSERT INTO jobbuilder_settings (name, value, updated_by) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE value = VALUES(value), updated_by = VALUES(updated_by)',
        { section, json.encode(clean), (ESX.GetPlayerFromId(src) or {}).identifier or 'console' })
    JBSet(section, clean)
    JB.log('_settings', ESX.GetPlayerFromId(src), 'settings_saved', section)
    broadcast()
    if section == 'real' and JB.syncPropsAll then JB.syncPropsAll() end
    cb({ ok = true, value = JBGet(section) })
end)

ESX.RegisterServerCallback('jobbuilder:settings:reset', function(src, cb, section)
    if not JB.isDev(src) then return cb(fail('Permission refusée')) end
    if not S[section] then return cb(fail('Section inconnue')) end
    local clean, err = S[section](JBDeepCopy(JBDefaults[section]), src)
    if not clean then return cb(fail('Réinitialisation impossible : ' .. tostring(err))) end
    MySQL.query.await('DELETE FROM jobbuilder_settings WHERE name = ?', { section })
    JBSet(section, clean)
    JB.log('_settings', ESX.GetPlayerFromId(src), 'settings_reset', section)
    broadcast()
    cb({ ok = true, value = JBGet(section) })
end)
