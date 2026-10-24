-- ─────────────────────────────── Builder (admin) ───────────────────────────────
local function fail(msg) return { ok = false, error = msg } end

local function trim(s) return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', '')) end

local function str(v, max, default)
    local s = trim(v)
    if s == '' then return default or '' end
    return s:sub(1, max)
end

local function num(v, min, max, default)
    local n = tonumber(v)
    if not n or n ~= n then n = default or min end
    if n < min then n = min elseif n > max then n = max end
    return n
end

local function int(v, min, max, default) return math.floor(num(v, min, max, default)) end

local function slug(s)
    s = tostring(s or ''):lower()
    local from = { 'à', 'â', 'ä', 'é', 'è', 'ê', 'ë', 'î', 'ï', 'ô', 'ö', 'ù', 'û', 'ü', 'ç' }
    local to   = { 'a', 'a', 'a', 'e', 'e', 'e', 'e', 'i', 'i', 'o', 'o', 'u', 'u', 'u', 'c' }
    for i, ch in ipairs(from) do s = s:gsub(ch, to[i]) end
    s = s:gsub('[^%w]+', '_'):gsub('^_+', ''):gsub('_+$', '')
    return s:sub(1, 40)
end

local function uniqueName(base)
    base = slug(base)
    if base == '' then base = 'module' end
    local name, i = base, 1
    while IB.ByName[name] do i = i + 1 name = ('%s_%d'):format(base:sub(1, 36), i) end
    return name
end

local function copy(t) return json.decode(json.encode(t)) end

-- ─────────────────────────────── Nettoyeur à schéma ───────────────────────────────
-- Nœuds : { 'on', min, max } nombre optionnel · { 'ob' } booléen optionnel · { 's', max, def } texte · { 'n', min, max, def } nombre · { 'b', def } booléen · { 'i' } nom d'item · { 'm' } nom de modèle
--         { 'c' } coordonnées (nil si absentes) · { 'rgb' } couleur · { 'j' } métiers {nom = grade} · { 'p' } moyens de paiement
--         { 'e', {valeurs}, def } énumération · { 'o', {champs} } objet · { 'a', nœud, max, filtre } tableau
local clean

local function coord(v)
    if type(v) ~= 'table' or not tonumber(v.x) or not tonumber(v.y) or not tonumber(v.z) then return nil end
    return { x = num(v.x, -20000, 20000), y = num(v.y, -20000, 20000), z = num(v.z, -2000, 4000), h = num(v.h, 0, 360, 0) }
end

function clean(node, v)
    local t = node[1]
    if t == 's' then return str(v, node[2], node[3])
    elseif t == 'n' then return num(v, node[2], node[3], node[4])
    elseif t == 'b' then
        if v == nil then return node[2] == true end
        return v == true
    elseif t == 'i' then
        local s = trim(v)
        if s == '' or #s > 64 or not s:match('^[%w_%-%.]+$') then return '' end
        return s
    elseif t == 'm' then
        local s = trim(v)
        if s == '' or #s > 60 or not s:match('^[%w_]+$') then return '' end
        return s
    elseif t == 'c' then return coord(v)
    elseif t == 'on' then        -- nombre optionnel : absent = hérite du style commun
        if tonumber(v) == nil then return nil end
        return num(v, node[2], node[3])
    elseif t == 'ob' then        -- booléen optionnel
        if v == nil then return nil end
        return v == true
    elseif t == 'rgb' then
        if type(v) == 'table' and #v == 3 then return { int(v[1], 0, 255, 239), int(v[2], 0, 255, 68), int(v[3], 0, 255, 68) } end
        return nil
    elseif t == 'j' then
        local out, known = {}, ESX.GetJobs()
        for name, grade in pairs(type(v) == 'table' and v or {}) do
            if known[name] then out[name] = int(grade, 0, 50, 0) end
        end
        return out
    elseif t == 'j2' then
        local out, n = {}, 0
        for name, grade in pairs(type(v) == 'table' and v or {}) do
            if type(name) == 'string' and name:match('^[%w_%-]+$') and #name <= 40 and n < 30 then out[name] = int(grade, 0, 50, 0) n = n + 1 end
        end
        return out
    elseif t == 'p' then
        local out, any = {}, false
        v = type(v) == 'table' and v or {}
        for id in pairs(Config.Payments) do out[id] = v[id] == true any = any or out[id] end
        if not any then out.cash = true end
        return out
    elseif t == 'e' then
        for _, opt in ipairs(node[2]) do if opt == v then return v end end
        return node[3] or node[2][1]
    elseif t == 'o' then
        v = type(v) == 'table' and v or {}
        local out = {}
        for k, sub in pairs(node[2]) do
            local r = clean(sub, v[k])
            if r ~= nil then out[k] = r end
        end
        return out
    elseif t == 'a' then
        local out = {}
        for _, x in ipairs(type(v) == 'table' and v or {}) do
            if #out >= (node[3] or 50) then break end
            local r = clean(node[2], x)
            if r ~= nil and (not node[4] or node[4](r)) then out[#out + 1] = r end
        end
        return out
    end
end

local function obj(t) return { 'o', t } end
local function merge(...)
    local out = {}
    for _, t in ipairs({ ... }) do for k, v in pairs(t) do out[k] = v end end
    return out
end

local animIds = {}
for _, a in ipairs(Config.Animations) do animIds[#animIds + 1] = a.id end
local ANIM = { 'e', animIds, 'none' }


local ITEM, MODEL = { 'i' }, { 'm' }
local TOOL = obj({ item = ITEM, consume = { 'b', false } })
-- Tenue obligatoire : liste de composants (k = 'c' composant / 'p' accessoire, id, d = variation attendue) par sexe
local OUTFIT_ROW = { 'a', obj({ k = { 'e', { 'c', 'p' }, 'c' }, id = { 'n', 0, 12, 0 }, d = { 'n', 0, 5000, 0 } }), 14 }
local OUTFIT = obj({ enabled = { 'b', false }, radius = { 'n', 3, 100, 15 }, male = OUTFIT_ROW, female = OUTFIT_ROW })
-- Plantation : la plante pousse avec le temps (de la plantation à 100 %), puis on la récolte et on doit replanter des graines
local PLANT = obj({ enabled = { 'b', false }, seed = ITEM, seedCount = { 'n', 1, 100, 1 }, growMinutes = { 'n', 1, 10080, 30 }, plantSeconds = { 'n', 1, 600, 6 },
    small = MODEL, medium = MODEL, large = MODEL })
local STACK = { 'a', obj({ item = ITEM, count = { 'n', 1, 1000, 1 } }), 10, function(x) return x.item ~= '' end }

local PED = obj({ enabled = { 'b', false }, model = MODEL, scenario = { 's', 60, '' }, pos = { 'c' }, dialog = obj({ enabled = { 'b', true }, text = { 's', 220, '' } }) })
local BLIP = obj({ enabled = { 'b', false }, sprite = { 'n', 0, 900, 52 }, color = { 'n', 0, 85, 0 }, scale = { 'n', 0.1, 3, (PickaxTheme and PickaxTheme.blipScale or 0.8) }, label = { 's', 60, '' }, shortRange = { 'b', true } })

local COMMON = {
    blip = BLIP,
    access = obj({ jobs = { 'j' }, item = ITEM }),
    color = { 'rgb' },
    uiColor = { 'rgb' },
    marker = obj({ enabled = { 'b', true }, type = { 'n', 0, 43, 25 }, alpha = { 'on', 0, 255 }, offset = { 'on', -10, 10 }, bob = { 'ob' }, rotate = { 'ob' }, help = { 'ob' },
        scale = obj({ x = { 'on', 0.05, 20 }, y = { 'on', 0.05, 20 }, z = { 'on', 0.05, 20 } }) }),
    note = { 's', 200, '' },
}

local FLEET = { 'a', obj({ model = MODEL, label = { 's', 60, '' }, minGrade = { 'n', 0, 50, 0 }, price = { 'n', 0, 100000000, 0 }, deposit = { 'n', 0, 100000000, 0 } }),
    Config.Max.Fleet, function(x) return x.model ~= '' end }

local SETTINGS = {
    gofast = merge(COMMON, {
        copsRequired = { 'n', 0, 30, 0 }, cooldown = { 'n', 0, 604800, 1800 }, stock = { 'n', 1, 100, 3 }, regenMinutes = { 'n', 1, 1440, 30 },
        model = MODEL, plate = { 's', 8, 'GOFAST' }, account = { 'e', { 'black_money', 'money', 'bank' }, 'black_money' },
        rewardMin = { 'n', 0, 100000000, 2500 }, rewardMax = { 'n', 0, 100000000, 4000 }, damageBonus = { 'b', true }, bonusMax = { 'n', 0, 100000000, 1500 },
        timeLimit = { 'n', 1, 240, 30 }, deliverRadius = { 'n', 3, 50, 8 },
        alert = obj({ chance = { 'n', 0, 100, 60 }, delay = { 'n', 0, 600, 20 }, label = { 's', 80, 'Go Fast suspecté' } }),
        tablet = obj({ enabled = { 'b', false }, item = ITEM }),
    }),
    drug = merge(COMMON, { copsRequired = { 'n', 0, 30, 0 } }),
    robbery = merge(COMMON, {
        trigger = { 'e', { 'aim', 'interact' }, 'aim' }, weapon = { 'b', true }, copsRequired = { 'n', 0, 30, 0 }, cooldown = { 'n', 0, 604800, 1800 },
        duration = { 'n', 30, 3600, 240 }, leaveDistance = { 'n', 5, 300, 30 }, coop = { 'b', true }, currency = { 'e', { 'black_money', 'money', 'bank' }, 'black_money' },
        requireItem = obj({ item = ITEM, count = { 'n', 1, 100, 1 }, consume = { 'b', false } }),
        alert = obj({ chance = { 'n', 0, 100, 100 }, label = { 's', 80, 'Braquage en cours' } }),
        guards = obj({ enabled = { 'b', false }, model = MODEL, weapon = { 's', 40, 'WEAPON_PISTOL' }, count = { 'n', 0, 10, 0 }, accuracy = { 'n', 0, 100, 30 }, health = { 'n', 100, 1000, 200 } }),
    }),
}

local PBASE = { label = { 's', 60, '' }, coords = { 'c' }, blip = { 'b', false }, ped = PED, color = { 'rgb' }, color2 = { 'rgb' } }
local ACCESS = obj({ jobs = { 'j' }, item = ITEM })
local DRUGBASE = merge(PBASE, { access = ACCESS, copsRequired = { 'n', 0, 30, 0 }, alertChance = { 'n', 0, 100, 0 } })
local TARGET = merge(PBASE, {
    time = { 'n', 1, 600, 10 }, anim = ANIM, minigame = { 'b', false }, tool = TOOL, cash = obj({ min = { 'n', 0, 100000000, 0 }, max = { 'n', 0, 100000000, 0 } }),
    items = { 'a', obj({ item = ITEM, min = { 'n', 1, 1000, 1 }, max = { 'n', 1, 1000, 1 }, chance = { 'n', 1, 100, 100 } }), Config.Max.Items, function(x) return x.item ~= '' end },
})

local POINTS = {
    gofast = {
        gfstart = merge(PBASE, { access = obj({ jobs = { 'j' }, item = ITEM }) }),
        gfspawn = PBASE,
        gfdrop = PBASE,
    },
    drug = {
        harvest = merge(DRUGBASE, { harvest = obj({ item = ITEM, min = { 'n', 1, 1000, 1 }, max = { 'n', 1, 1000, 3 }, time = { 'n', 1, 600, 6 }, anim = ANIM, tool = TOOL,
            cooldown = { 'n', 0, 3600, 10 }, maxUses = { 'n', 0, 10000, 0 }, regen = { 'n', 10, 86400, 300 }, plant = PLANT }) }),
        process = merge(DRUGBASE, { recipes = { 'a', obj({ label = { 's', 60, '' }, inputs = STACK, outputs = STACK, time = { 'n', 1, 600, 8 }, anim = ANIM,
            failChance = { 'n', 0, 100, 0 }, tool = TOOL }), Config.Max.Recipes }, outfit = OUTFIT }),
        sell = merge(DRUGBASE, { sell = obj({ currency = { 'e', { 'black_money', 'money', 'bank' }, 'black_money' }, maxPerHour = { 'n', 0, 100000, 0 },
            items = { 'a', obj({ item = ITEM, min = { 'n', 0, 100000000, 1 }, max = { 'n', 0, 100000000, 1 } }), Config.Max.Items, function(x) return x.item ~= '' end } }) }),
        launder = merge(DRUGBASE, { reveal = obj({ enabled = { 'b', false }, item = ITEM }), launder = obj({ rate = { 'n', 1, 100, 70 }, min = { 'n', 0, 100000000, 0 }, max = { 'n', 0, 100000000, 100000 }, from = ITEM,
            to = { 'e', { 'money', 'bank', 'black_money' }, 'money' }, maxPerHour = { 'n', 0, 1000000000, 0 } }) }),
        door = merge(DRUGBASE, { inside = { 'c' } }),
    },
    robbery = {
        clerk = PBASE, start = PBASE, guard = PBASE,
        register = TARGET, safe = TARGET, vault = TARGET, loot = TARGET,
    },
}

local KINDS = {}
for tp, kinds in pairs(POINTS) do KINDS[tp] = {} for k in pairs(kinds) do KINDS[tp][#KINDS[tp] + 1] = k end table.sort(KINDS[tp]) end

local function cleanSettings(tp, s)
    s = type(s) == 'table' and s or {}
    local out = clean(obj(SETTINGS[tp]), s)
    if out.marker == nil then out.marker = { enabled = true, type = Config.Marker.type } end
    -- les cibles d'un braquage et les valeurs min/max restent cohérentes
    return out
end

local function cleanPoints(tp, list)
    local out = {}
    for _, p in ipairs(type(list) == 'table' and list or {}) do
        if #out >= Config.Max.Points then break end
        if type(p) == 'table' then
            local kind = tostring(p.kind or 'main')
            local sch = POINTS[tp][kind]
            if sch then
                local c = clean(obj(sch), p)
                c.kind = kind
                -- min <= max pour les plages
                for _, key in ipairs({ 'harvest', 'cash' }) do
                    if c[key] and c[key].min and c[key].max and c[key].max < c[key].min then c[key].max = c[key].min end
                end
                for _, key in ipairs({ 'items' }) do
                    for _, it in ipairs(c[key] or {}) do if it.max and it.min and it.max < it.min then it.max = it.min end end
                end
                out[#out + 1] = c
            end
        end
    end
    return out
end

IB.cleanSettings, IB.cleanPoints = cleanSettings, cleanPoints

-- Items référencés (clé « item ») inexistants sur le serveur : avertissement dans le builder
local function missingItems(e)
    local miss, seen = {}, {}
    local function walk(t)
        if type(t) ~= 'table' then return end
        for k, v in pairs(t) do
            if k == 'item' and type(v) == 'string' and v ~= '' and not seen[v] then
                seen[v] = true
                if not IB.itemExists(v) then miss[#miss + 1] = v end
            elseif type(v) == 'table' then walk(v) end
        end
    end
    walk(e.settings) walk(e.points)
    table.sort(miss)
    return miss
end

-- ─────────────────────────────── Callbacks ───────────────────────────────
local function admin(src, cb)
    if IB.isAdmin(src) then return true end
    cb(fail('Accès refusé'))
    return false
end

local function jobList()
    local out = {}
    for name, job in pairs(ESX.GetJobs()) do
        local grades = {}
        for g, data in pairs(job.grades or {}) do grades[#grades + 1] = { grade = tonumber(g) or tonumber(data.grade) or 0, label = data.label } end
        table.sort(grades, function(a, b) return a.grade < b.grade end)
        out[#out + 1] = { name = name, label = job.label or name, grades = grades }
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

-- Liste des job2 / gangs (ESX.GetJobs2 si présent, sinon lecture des tables Config.Jobs2) ; vide si introuvable → saisie libre dans l'éditeur
local function jobs2List()
    local out, ok = {}, false
    if ESX.GetJobs2 then
        ok = pcall(function()
            for name, job in pairs(ESX.GetJobs2()) do
                local grades = {}
                for g, data in pairs(job.grades or {}) do grades[#grades + 1] = { grade = tonumber(g) or 0, label = data.label } end
                table.sort(grades, function(a, b) return a.grade < b.grade end)
                out[#out + 1] = { name = name, label = job.label or name, grades = grades }
            end
        end)
    end
    if not ok or #out == 0 then
        pcall(function()
            local c = Config.Jobs2
            for _, r in ipairs(MySQL.query.await(('SELECT name, label FROM `%s`'):format(c.table)) or {}) do out[#out + 1] = { name = r.name, label = r.label or r.name, grades = {} } end
        end)
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

ESX.RegisterServerCallback('illegalbuilder:isAdmin', function(src, cb) cb(IB.isAdmin(src)) end)

ESX.RegisterServerCallback('illegalbuilder:catalog', function(src, cb)
    if not admin(src, cb) then return end
    local types = {}
    for _, id in ipairs(Config.TypeOrder) do
        local t = Config.Types[id]
        local tpls = {}
        for tid, tpl in pairs(Config.Templates[id] or {}) do tpls[#tpls + 1] = { id = tid, label = tpl.label, icon = tpl.icon or t.icon, points = #(tpl.points or {}) } end
        table.sort(tpls, function(a, b) return a.label < b.label end)
        types[#types + 1] = { id = id, label = t.label, one = t.one, icon = t.icon, sub = t.sub, templates = tpls, kinds = KINDS[id] }
    end
    local pay = {}
    for id, p in pairs(Config.Payments) do pay[#pay + 1] = { id = id, label = p.label } end
    table.sort(pay, function(a, b) return a.id < b.id end)
    local anims = {}
    for _, a in ipairs(Config.Animations) do anims[#anims + 1] = { id = a.id, label = a.label } end
    cb({ ok = true, types = types, drugs = Config.Drugs, drugOrder = Config.DrugOrder, items = IB.itemCatalog(), jobs = jobList(), jobs2 = jobs2List(), weapons = {}, payments = pay, scenarios = Config.PedScenarios, animations = anims, jobcenter = {},
        vehicleTypes = Config.VehicleTypes, inventory = IB.inventory(), imagePath = Config.ImagePath, currency = Config.Currency, accent = Config.UI.Accent,
        policeJobs = Config.PoliceJobs, limits = { points = Config.Max.Points, fleet = Config.Max.Fleet, recipes = Config.Max.Recipes } })
end)

ESX.RegisterServerCallback('illegalbuilder:list', function(src, cb)
    if not IB.isAdmin(src) then return cb({}) end
    local list = {}
    for id, e in pairs(IB.Entities) do
        local placed = 0
        for _, p in ipairs(e.points) do if p.coords and p.coords.x then placed = placed + 1 end end
        list[#list + 1] = { id = id, name = e.name, label = e.label, type = e.type, enabled = e.enabled, points = #e.points, placed = placed, stats = e.stats or {} }
    end
    table.sort(list, function(a, b) return a.label:lower() < b.label:lower() end)
    cb(list)
end)

ESX.RegisterServerCallback('illegalbuilder:get', function(src, cb, id)
    if not admin(src, cb) then return end
    local e = IB.Entities[tonumber(id) or 0]
    if not e then return cb(fail('Module introuvable')) end
    cb({ ok = true, entity = e, missing = missingItems(e) })
end)

-- Crée un module à partir d'un modèle. over = { settings = {...}, points = {...} } remplace des réglages / les points du modèle avant nettoyage.
function IB.createFromTemplate(createdBy, tp, tplId, label, over)
    tp = tostring(tp)
    local type_ = Config.Types[tp]
    local tpl = Config.Templates[tp] and Config.Templates[tp][tostring(tplId)]
    if not type_ or not tpl then return nil, 'Modèle inconnu' end
    if IB.entityCount() >= Config.Max.Entities then return nil, 'Nombre maximum de modules atteint' end
    label = str(label, 100, tpl.label)
    local name = uniqueName(label)
    local rawSettings, rawPoints = copy(tpl.settings or {}), copy(tpl.points or {})
    for k, v in pairs(over and over.settings or {}) do rawSettings[k] = v end
    if over and over.points then rawPoints = over.points end
    local settings = cleanSettings(tp, rawSettings)
    local points = cleanPoints(tp, rawPoints)
    local id = MySQL.insert.await('INSERT INTO illegalbuilder_entities (type, name, label, enabled, settings, points, stats, created_by) VALUES (?, ?, ?, 0, ?, ?, ?, ?)', {
        tp, name, label, json.encode(settings), json.encode(points), '{}', createdBy or 'console',
    })
    if not id then return nil, 'Erreur base de données' end
    local e = { id = id, type = tp, name = name, label = label, enabled = false, settings = settings, points = points, stats = {} }
    IB.Entities[id], IB.ByName[name] = e, id
    return e
end

ESX.RegisterServerCallback('illegalbuilder:create', function(src, cb, tp, tplId, label)
    if not admin(src, cb) then return end
    local e, err = IB.createFromTemplate(GetPlayerName(src), tp, tplId, label)
    if not e then return cb(fail(err)) end
    IB.log(e, ESX.GetPlayerFromId(src), 'create', ('%s (%s)'):format(e.label, tplId))
    cb({ ok = true, entity = e, missing = missingItems(e) })
end)

ESX.RegisterServerCallback('illegalbuilder:save', function(src, cb, data)
    if not admin(src, cb) then return end
    if type(data) ~= 'table' then return cb(fail('Données invalides')) end
    local e = IB.Entities[tonumber(data.id) or 0]
    if not e then return cb(fail('Module introuvable')) end
    local label = str(data.label, 100, '')
    if label == '' then return cb(fail('Le nom est obligatoire')) end
    e.label = label
    e.enabled = data.enabled == true
    e.settings = cleanSettings(e.type, data.settings)
    e.points = cleanPoints(e.type, data.points)
    IB.save(e)
    if IB.onEntityChanged then IB.onEntityChanged(e) end
    IB.syncAll()
    IB.log(e, ESX.GetPlayerFromId(src), 'save', ('%d point(s), %s'):format(#e.points, e.enabled and 'actif' or 'désactivé'))
    cb({ ok = true, entity = e, missing = missingItems(e) })
end)

ESX.RegisterServerCallback('illegalbuilder:delete', function(src, cb, id)
    if not admin(src, cb) then return end
    local e = IB.Entities[tonumber(id) or 0]
    if not e then return cb(fail('Module introuvable')) end
    MySQL.update.await('DELETE FROM illegalbuilder_entities WHERE id = ?', { e.id })
    IB.Entities[e.id], IB.ByName[e.name], IB.Dirty[e.id] = nil, nil, nil
    if IB.onEntityChanged then IB.onEntityChanged(e, true) end
    IB.syncAll()
    IB.log(e, ESX.GetPlayerFromId(src), 'delete', e.label)
    cb({ ok = true })
end)

ESX.RegisterServerCallback('illegalbuilder:duplicate', function(src, cb, id)
    if not admin(src, cb) then return end
    local e = IB.Entities[tonumber(id) or 0]
    if not e then return cb(fail('Module introuvable')) end
    local label = (e.label .. ' (copie)'):sub(1, 100)
    local name = uniqueName(e.name .. '_copie')
    local settings, points = copy(e.settings), copy(e.points)
    local newId = MySQL.insert.await('INSERT INTO illegalbuilder_entities (type, name, label, enabled, settings, points, stats, created_by) VALUES (?, ?, ?, 0, ?, ?, ?, ?)', {
        e.type, name, label, json.encode(settings), json.encode(points), '{}', createdBy or 'console',
    })
    if not newId then return cb(fail('Erreur base de données')) end
    local c = { id = newId, type = e.type, name = name, label = label, enabled = false, settings = settings, points = points, stats = {} }
    IB.Entities[newId], IB.ByName[name] = c, newId
    IB.log(c, ESX.GetPlayerFromId(src), 'duplicate', ('copie de %s'):format(e.label))
    cb({ ok = true, entity = c, missing = missingItems(c) })
end)

ESX.RegisterServerCallback('illegalbuilder:toggle', function(src, cb, id, state)
    if not admin(src, cb) then return end
    local e = IB.Entities[tonumber(id) or 0]
    if not e then return cb(fail('Module introuvable')) end
    e.enabled = state == true
    MySQL.update.await('UPDATE illegalbuilder_entities SET enabled = ? WHERE id = ?', { e.enabled and 1 or 0, e.id })
    if IB.onEntityChanged then IB.onEntityChanged(e) end
    IB.syncAll()
    IB.log(e, ESX.GetPlayerFromId(src), 'toggle', e.enabled and 'activé' or 'désactivé')
    cb({ ok = true })
end)

ESX.RegisterServerCallback('illegalbuilder:resetStats', function(src, cb, id)
    if not admin(src, cb) then return end
    local e = IB.Entities[tonumber(id) or 0]
    if not e then return cb(fail('Module introuvable')) end
    e.stats = {}
    IB.save(e)
    cb({ ok = true, entity = e })
end)

ESX.RegisterServerCallback('illegalbuilder:logs', function(src, cb, id)
    if not admin(src, cb) then return end
    id = tonumber(id) or 0
    local rows
    if id > 0 then
        rows = MySQL.query.await('SELECT entity_label, type, player_name, action, detail, amount, UNIX_TIMESTAMP(created_at) AS t FROM illegalbuilder_logs WHERE entity_id = ? ORDER BY id DESC LIMIT 60', { id })
    else
        rows = MySQL.query.await('SELECT entity_label, type, player_name, action, detail, amount, UNIX_TIMESTAMP(created_at) AS t FROM illegalbuilder_logs ORDER BY id DESC LIMIT 60')
    end
    cb({ ok = true, logs = rows or {} })
end)

ESX.RegisterServerCallback('illegalbuilder:settings:save', function(src, cb, accent)
    if not admin(src, cb) then return end
    if type(accent) ~= 'table' or #accent ~= 3 then return cb(fail('Couleur invalide')) end
    local c = { int(accent[1], 0, 255, 239), int(accent[2], 0, 255, 68), int(accent[3], 0, 255, 68) }
    Config.UI.Accent = c
    MySQL.update.await("INSERT INTO illegalbuilder_settings (k, v) VALUES ('accent', ?) ON DUPLICATE KEY UPDATE v = VALUES(v)", { json.encode(c) })
    IB.syncAll()
    cb({ ok = true, accent = c })
end)
