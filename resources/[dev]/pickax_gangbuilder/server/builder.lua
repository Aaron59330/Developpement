-- ─────────────────────────────── Builder (réservé aux groupes autorisés) ───────────────────────────────

local J = Config.Job2

local function fail(msg) return { ok = false, error = msg } end

local function str(v, max, default)
    if type(v) ~= 'string' then return default or '' end
    v = v:gsub('[%c]', ''):sub(1, max or 100)
    return v
end

local function num(v, min, max, default)
    v = tonumber(v)
    if not v or v ~= v then return default end
    if min and v < min then v = min end
    if max and v > max then v = max end
    return v
end

local function int(v, min, max, default)
    local n = num(v, min, max, default)
    return n and math.floor(n) or default
end

local function cleanCoords(c)
    if type(c) ~= 'table' then return nil end
    local x, y, z = tonumber(c.x), tonumber(c.y), tonumber(c.z)
    if not (x and y and z) then return nil end
    return { x = math.floor(x * 100) / 100, y = math.floor(y * 100) / 100, z = math.floor(z * 100) / 100, h = math.floor((tonumber(c.h) or 0) * 100) / 100 }
end

local function itemName(v)
    local name = str(v, 60)
    return name:match('^[%w_%-%.]+$') and name or nil
end

local clothesKeys = {}
for _, k in ipairs(Config.ClothesKeys) do clothesKeys[k] = true end

local function cleanClothes(t)
    if type(t) ~= 'table' then return nil end
    local out, count = {}, 0
    for k, v in pairs(t) do
        if clothesKeys[k] and tonumber(v) then out[k] = tonumber(v) count = count + 1 end
    end
    return count > 0 and out or nil
end

local ACCOUNTS = { money = true, bank = true, dirty = true }

-- ─────────────────────────────── Validation d'un point ───────────────────────────────
-- Style de marker « creux » : seuls les champs renseignés sont gardés (le reste est hérité du marker de base du serveur)
local function cleanStyle(s)
    if type(s) ~= 'table' then return nil end
    local out, n = {}, 0
    if tonumber(s.marker) then out.marker = math.floor(math.max(0, math.min(50, tonumber(s.marker)))) n = n + 1 end
    if type(s.color) == 'table' and tonumber(s.color[1]) and tonumber(s.color[2]) and tonumber(s.color[3]) then
        out.color = { math.floor(math.max(0, math.min(255, tonumber(s.color[1])))), math.floor(math.max(0, math.min(255, tonumber(s.color[2])))), math.floor(math.max(0, math.min(255, tonumber(s.color[3])))) } n = n + 1
    end
    if tonumber(s.alpha) then out.alpha = math.floor(math.max(0, math.min(255, tonumber(s.alpha)))) n = n + 1 end
    if type(s.scale) == 'table' then
        local sc, any = {}, false
        for k, def in pairs({ x = 1.0, y = 1.0, z = 0.5 }) do
            if tonumber(s.scale[k]) then any = true end
            sc[k] = math.max(0.05, math.min(20, tonumber(s.scale[k]) or def))
        end
        if any then out.scale = sc n = n + 1 end
    end
    if tonumber(s.offset) then out.offset = math.max(-10, math.min(10, tonumber(s.offset))) n = n + 1 end
    if s.bob ~= nil then out.bob = s.bob == true n = n + 1 end
    if s.rotate ~= nil then out.rotate = s.rotate == true n = n + 1 end
    if s.help ~= nil then out.help = s.help ~= false n = n + 1 end
    return n > 0 and out or nil
end

local function cleanPoint(p, maxGrade)
    if type(p) ~= 'table' or not Config.PointTypes[p.type] or Config.PointTypes[p.type].hidden then return nil, 'Type de point invalide' end
    local coords = cleanCoords(p.coords)
    if not coords then return nil, ('Coordonnées manquantes (%s)'):format(Config.PointTypes[p.type].label) end
    local d = type(p.data) == 'table' and p.data or {}
    local out = {
        id = tonumber(p.id),
        type = p.type,
        label = str(p.label, 60, Config.PointTypes[p.type].label),
        coords = coords,
        min_grade = int(p.min_grade, 0, maxGrade, 0),
        data = {},
    }
    if out.label == '' then out.label = Config.PointTypes[p.type].label end
    out.data.style = cleanStyle(d.style)   -- apparence propre à ce point (sinon : marker de base du serveur)
    local A = Config.Activities

    if p.type == 'garage' then
        out.data.kind = Config.GarageKinds[d.kind] and d.kind or 'car'
        local spawn = cleanCoords(d.spawn)
        if not spawn then return nil, ('Garage "%s" : position de sortie des véhicules manquante'):format(out.label) end
        out.data.spawn = spawn
        out.data.vehicles = {}
        for _, v in ipairs(type(d.vehicles) == 'table' and d.vehicles or {}) do
            local model = str(v.model, 40):lower()
            if model:match('^[%w_]+$') and #out.data.vehicles < Config.MaxItemsPerPoint then
                out.data.vehicles[#out.data.vehicles + 1] = {
                    model = model, label = str(v.label, 60, model), min_grade = int(v.min_grade, 0, maxGrade, 0), color = num(v.color, 0, 160, nil),
                }
            end
        end
        if #out.data.vehicles == 0 then return nil, ('Garage "%s" : ajoute au moins un véhicule'):format(out.label) end

    elseif p.type == 'cloakroom' then
        out.data.outfits = {}
        for _, o in ipairs(type(d.outfits) == 'table' and d.outfits or {}) do
            local male, female = cleanClothes(o.male), cleanClothes(o.female)
            if (male or female) and #out.data.outfits < 40 then
                out.data.outfits[#out.data.outfits + 1] = { label = str(o.label, 60, 'Tenue'), min_grade = int(o.min_grade, 0, maxGrade, 0), male = male, female = female }
            end
        end

    elseif p.type == 'armory' then
        out.data.items = {}
        for _, it in ipairs(type(d.items) == 'table' and d.items or {}) do
            local name = itemName(it.name)
            if name and #out.data.items < Config.MaxItemsPerPoint then
                out.data.items[#out.data.items + 1] = {
                    name = name, label = str(it.label, 60, name), count = int(it.count, 1, 1000, 1),
                    ammo = int(it.ammo, 0, 9999, 0), min_grade = int(it.min_grade, 0, maxGrade, 0),
                }
            end
        end
        if #out.data.items == 0 then return nil, ('Armurerie "%s" : ajoute au moins un objet'):format(out.label) end

    elseif p.type == 'stash' then
        out.data.slots = int(d.slots, 5, 200, 50)
        out.data.weight = int(d.weight, 1, 2000, 100)

    elseif p.type == 'shop' then
        out.data.public = d.public == true
        out.data.account = ACCOUNTS[d.account] and d.account or 'money'
        out.data.items = {}
        for _, it in ipairs(type(d.items) == 'table' and d.items or {}) do
            local name = itemName(it.name)
            if name and #out.data.items < Config.MaxItemsPerPoint then
                out.data.items[#out.data.items + 1] = {
                    name = name, label = str(it.label, 60, name), price = int(it.price, 0, 10000000, 1), min_grade = int(it.min_grade, 0, maxGrade, 0),
                }
            end
        end
        if #out.data.items == 0 then return nil, ('Marché noir "%s" : ajoute au moins un article'):format(out.label) end

    elseif p.type == 'harvest' then
        local name = itemName(d.name)
        if not name then return nil, ('Récolte "%s" : choisis l\'objet récolté'):format(out.label) end
        out.data = {
            name = name, label = str(d.label, 60, name), count = int(d.count, 1, A.MaxHarvest, 1), seconds = int(d.seconds, 2, 300, 8),
            cooldown = int(d.cooldown, 0, 86400, 0), tool = itemName(d.tool) or '',
        }

    elseif p.type == 'process' then
        out.data.recipes = {}
        for _, r in ipairs(type(d.recipes) == 'table' and d.recipes or {}) do
            if #out.data.recipes >= A.MaxRecipes then break end
            local o = type(r.output) == 'table' and r.output or {}
            local oname = itemName(o.name)
            if not oname then return nil, ('Traitement "%s" : une recette n\'a pas de produit fini'):format(out.label) end
            local inputs = {}
            for _, i in ipairs(type(r.inputs) == 'table' and r.inputs or {}) do
                local iname = itemName(i.name)
                if iname and #inputs < A.MaxInputs then inputs[#inputs + 1] = { name = iname, label = str(i.label, 60, iname), count = int(i.count, 1, 1000, 1) } end
            end
            if #inputs == 0 then return nil, ('Traitement "%s" : la recette « %s » n\'a aucun ingrédient'):format(out.label, str(r.label, 60, oname)) end
            out.data.recipes[#out.data.recipes + 1] = {
                label = str(r.label, 60, str(o.label, 60, oname)), seconds = int(r.seconds, 2, 300, 10), min_grade = int(r.min_grade, 0, maxGrade, 0),
                chance = int(r.chance, 1, 100, 100),
                output = { name = oname, label = str(o.label, 60, oname), count = int(o.count, 1, 1000, 1) }, inputs = inputs,
            }
        end
        if #out.data.recipes == 0 then return nil, ('Traitement "%s" : ajoute au moins une recette'):format(out.label) end

    elseif p.type == 'sell' then
        out.data.account = (d.account == 'dirty' or d.account == 'money' or d.account == 'bank') and d.account or ''   -- '' = valeur par défaut de la config
        out.data.gang_cut = int(d.gang_cut, -1, 100, -1)                                                              -- -1 = valeur par défaut
        out.data.items = {}
        for _, it in ipairs(type(d.items) == 'table' and d.items or {}) do
            local name = itemName(it.name)
            if name and #out.data.items < Config.MaxItemsPerPoint then
                out.data.items[#out.data.items + 1] = { name = name, label = str(it.label, 60, name), price = int(it.price, 1, 10000000, 10), min_grade = int(it.min_grade, 0, maxGrade, 0) }
            end
        end
        if #out.data.items == 0 then return nil, ('Point de vente "%s" : ajoute au moins un produit'):format(out.label) end

    elseif p.type == 'laundry' then
        out.data = {
            fee = int(d.fee, -1, 100, -1), gang_cut = int(d.gang_cut, -1, 100, -1),
            min = int(d.min, 0, 1000000000, 0), max = int(d.max, 0, 1000000000, 0), seconds = int(d.seconds, 0, 300, 0),     -- 0 / -1 = valeur par défaut
        }
    end
    return out
end

-- ─────────────────────────────── Validation d'un gang ───────────────────────────────
local function cleanGang(payload)
    if type(payload) ~= 'table' or type(payload.gang) ~= 'table' then return nil, 'Données invalides' end
    local g = payload.gang
    -- pas de troncature silencieuse : un nom trop long est refusé (users.job2 est un varchar(20))
    local name = type(g.name) == 'string' and #g.name <= J.NameMaxLength and g.name:lower() or ''
    if not name:match('^[a-z][a-z0-9_]+$') or #name < 2 then
        return nil, ('Nom du gang invalide (lettres minuscules, chiffres et _ ; 2 à %d caractères, commence par une lettre)'):format(J.NameMaxLength)
    end
    if not Config.GangTypes[g.type] then return nil, 'Type de gang invalide' end
    local label = str(g.label, 50)
    if label == '' then return nil, 'Le label du gang est obligatoire' end
    local color = str(g.color, 7):lower()
    if not color:match('^#%x%x%x%x%x%x$') then color = Config.GangTypes[g.type].color or '#ef4444' end

    if type(payload.grades) ~= 'table' or #payload.grades < 1 then return nil, 'Il faut au moins un grade' end
    if #payload.grades > Config.MaxGrades then return nil, ('Maximum %d grades'):format(Config.MaxGrades) end

    local grades, used = {}, {}
    for i, gr in ipairs(payload.grades) do
        local gname = str(gr.name, 40):lower():gsub('[^%w_]', '_')
        if gname == '' then gname = 'grade' .. (i - 1) end
        if used[gname] then return nil, ('Nom de grade en double : %s'):format(gname) end
        used[gname] = true
        grades[i] = { grade = i - 1, name = gname, label = str(gr.label, 50, gname), salary = int(gr.salary, 0, 1000000, 0) }
    end
    local maxGrade = #grades - 1

    local blip = type(g.blip) == 'table' and g.blip or {}
    if blip.enabled == true and not cleanCoords(blip.coords) then
        return nil, 'Blip activé mais sans position : onglet Blip → « Ma position » (ou décoche « Afficher le blip »)'
    end
    local settings = type(g.settings) == 'table' and g.settings or {}
    local actions = {}
    for _, a in ipairs(type(settings.actions) == 'table' and settings.actions or {}) do
        if Config.Actions[a] and a ~= 'info' and a ~= 'leave' and a ~= 'tablet' then actions[#actions + 1] = a end
    end

    local points = {}
    if type(payload.points) == 'table' then
        if #payload.points > Config.MaxPoints then return nil, ('Maximum %d points par gang'):format(Config.MaxPoints) end
        for _, p in ipairs(payload.points) do
            local cp, err = cleanPoint(p, maxGrade)
            if not cp then return nil, err end
            points[#points + 1] = cp
        end
    end

    local bossGrade = int(g.boss_grade, 0, maxGrade, maxGrade)
    return {
        name = name, label = label, type = g.type, color = color, boss_grade = bossGrade,
        blip = {
            enabled = blip.enabled == true, label = str(blip.label, 40), sprite = int(blip.sprite, 0, 900, 310),
            color = int(blip.color, 0, 85, 0), scale = num(blip.scale, 0.3, 2.0, (PickaxTheme and PickaxTheme.blipScale or 0.9)), coords = cleanCoords(blip.coords), shortRange = blip.shortRange == true,
        },
        settings = {
            actions = actions,
            plate_prefix = str(settings.plate_prefix, 4):upper():gsub('[^%w]', ''),
            motd = str(settings.motd, 200),
            max_members = int(settings.max_members, -1, 500, -1),                       -- -1 = valeur par défaut de la config
            recruit_grade = int(settings.recruit_grade, 0, maxGrade, math.min(Config.Gang.RecruitGrade, maxGrade)),
            withdraw_grade = int(settings.withdraw_grade, 0, maxGrade, bossGrade),     -- grade min. pour retirer de l'argent de la trésorerie
            capture_grade = int(settings.capture_grade, 0, maxGrade, 0),               -- grade min. pour participer à la capture des territoires
            salary_source = (settings.salary_source == 'treasury' or settings.salary_source == 'system') and settings.salary_source or 'default',
            sell_cut = int(settings.sell_cut, -1, 100, -1),                             -- part des ventes reversée au gang (-1 = défaut)
            marker = cleanStyle(settings.marker),                                       -- style de marker propre à ce gang (champs vides = marker du serveur)
            ui_accent = (type(settings.ui_accent) == 'table' and #settings.ui_accent == 3)
                and { int(settings.ui_accent[1], 0, 255, 239), int(settings.ui_accent[2], 0, 255, 68), int(settings.ui_accent[3], 0, 255, 68) } or nil,   -- couleur des menus du gang
        },
        start_money = int(g.start_money, 0, 1000000000, Config.Treasury.StartMoney),
    }, grades, points
end

-- ─────────────────────────────── Callbacks ───────────────────────────────
ESX.RegisterServerCallback('gangbuilder:list', function(src, cb)
    if not GB.isDev(src) then return cb({}) end
    local list = {}
    for name, gang in pairs(GB.Gangs) do
        local pts, owned = 0, 0
        for _, p in pairs(GB.Points) do if p.gang_name == name then pts = pts + 1 end end
        for _, t in pairs(GB.Territories) do if t.owner == name then owned = owned + 1 end end
        list[#list + 1] = {
            name = name, label = gang.label, type = gang.type, color = gang.color, grades = #gang.grades, points = pts, online = #GB.onlineMembers(name),
            members = GB.memberCount(name), money = gang.money, dirty = gang.dirty, rep = gang.rep, territories = owned,
        }
    end
    -- argent à jour (la table gangbuilder_gangs est la référence)
    for _, g in ipairs(list) do g.money, g.dirty, g.rep = GB.treasury(g.name) end
    table.sort(list, function(a, b) return a.name < b.name end)
    cb(list)
end)

ESX.RegisterServerCallback('gangbuilder:get', function(src, cb, name)
    if not GB.isDev(src) then return cb(nil) end
    local gang = GB.Gangs[name]
    if not gang then return cb(nil) end
    local points = {}
    for _, p in pairs(GB.Points) do
        if p.gang_name == name then points[#points + 1] = p end
    end
    table.sort(points, function(a, b) return a.id < b.id end)
    cb({
        gang = { name = gang.name, label = gang.label, type = gang.type, color = gang.color, boss_grade = gang.boss_grade, blip = gang.blip, settings = gang.settings },
        grades = gang.grades,
        points = points,
    })
end)

ESX.RegisterServerCallback('gangbuilder:catalog', function(src, cb)
    if not GB.isDev(src) then return cb(nil) end
    local items = {}
    if GB.inventory() == 'ox' then
        local ok, all = pcall(function() return exports.ox_inventory:Items() end)
        if ok and all then
            for name, it in pairs(all) do items[#items + 1] = { name = name, label = it.label or name } end
        end
    end
    if #items == 0 then
        for _, r in ipairs(MySQL.query.await('SELECT name, label FROM items') or {}) do items[#items + 1] = { name = r.name, label = r.label } end
    end
    table.sort(items, function(a, b) return a.name < b.name end)
    local okV, vehicles = pcall(MySQL.query.await, 'SELECT name, model, category FROM vehicles ORDER BY name')
    cb({
        items = items, vehicles = okV and vehicles or {}, blipScale = PickaxTheme and PickaxTheme.blipScale or nil, gangTypes = Config.GangTypes, pointTypes = Config.PointTypes, coreMarker = PickaxTheme and PickaxTheme.marker or nil, garageKinds = Config.GarageKinds,
        maxItems = Config.MaxItemsPerPoint, maxGrades = Config.MaxGrades, categoryTypes = Config.CategoryTypes, territories = Config.Territories, actions = Config.Actions, clothesKeys = Config.ClothesKeys, activities = Config.Activities,
        nameMax = J.NameMaxLength, dirty = Config.Dirty, defaults = { sellCut = Config.Activities.SellGangCut, launderFee = Config.Activities.LaunderFee, launderGangCut = Config.Activities.LaunderGangCut,
            launderMin = Config.Activities.LaunderMin, launderMax = Config.Activities.LaunderMax, launderSeconds = Config.Activities.LaunderSeconds, maxMembers = Config.Gang.MaxMembers },
    })
end)

ESX.RegisterServerCallback('gangbuilder:save', function(src, cb, payload)
    if not GB.isDev(src) then return cb(fail('Permission refusée')) end
    local gang, grades, points = cleanGang(payload)
    if not gang then return cb(fail(grades)) end

    local isNew = GB.Gangs[gang.name] == nil
    if isNew then
        -- Ne jamais écraser / mélanger un job ou un gang qui existe déjà et n'a pas été créé par le builder
        local used = GB.nameConflict(gang.name)
        if used then return cb(fail(('Le nom "%s" est déjà utilisé dans la table %s (non géré par le builder)'):format(gang.name, used))) end
        if Config.MaxGangs > 0 and GB.count(GB.Gangs) >= Config.MaxGangs then return cb(fail(('Limite atteinte : %d gangs maximum'):format(Config.MaxGangs))) end
    end

    local C = J.GradeColumns
    local q = {}
    local function add(query, values) q[#q + 1] = { query = query, values = values or {} } end

    -- 1) Table job2 : jobs2
    add(('INSERT INTO %s (name, label) VALUES (?, ?) ON DUPLICATE KEY UPDATE label = VALUES(label)'):format(GB.id(J.JobsTable)), { gang.name, gang.label })

    -- 2) Table job2_grades : remplacement uniquement des grades DE CE GANG
    add(('DELETE FROM %s WHERE %s = ?'):format(GB.id(J.GradesTable), GB.id(C.job)), { gang.name })
    for _, g in ipairs(grades) do
        add(('INSERT INTO %s (%s, %s, %s, %s, %s, %s, %s) VALUES (?, ?, ?, ?, ?, \'{}\', \'{}\')'):format(GB.id(J.GradesTable), GB.id(C.job), GB.id(C.grade), GB.id(C.name),
            GB.id(C.label), GB.id(C.salary), GB.id(C.skinMale), GB.id(C.skinFemale)), { gang.name, g.grade, g.name, g.label, g.salary })
    end
    add(('UPDATE %s SET %s = 0 WHERE %s = ? AND %s > ?'):format(GB.id(J.UsersTable), GB.id(J.UserGradeColumn), GB.id(J.UserJobColumn), GB.id(J.UserGradeColumn)), { gang.name, #grades - 1 })

    -- 3) Données du builder
    local xPlayer = ESX.GetPlayerFromId(src)
    add([[INSERT INTO gangbuilder_gangs (name, label, type, color, boss_grade, money, blip, settings, created_by)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE label = VALUES(label), type = VALUES(type), color = VALUES(color), boss_grade = VALUES(boss_grade),
          blip = VALUES(blip), settings = VALUES(settings)]],
        { gang.name, gang.label, gang.type, gang.color, gang.boss_grade, isNew and gang.start_money or 0, json.encode(gang.blip), json.encode(gang.settings), xPlayer and xPlayer.identifier or 'console' })

    -- 4) Points : suppression des retirés, update des existants, insertion des nouveaux
    local keep = {}
    for _, p in ipairs(points) do
        local existing = p.id and GB.Points[p.id]
        if existing and existing.gang_name == gang.name then
            keep[p.id] = true
            add('UPDATE gangbuilder_points SET type = ?, label = ?, coords = ?, min_grade = ?, data = ? WHERE id = ? AND gang_name = ?',
                { p.type, p.label, json.encode(p.coords), p.min_grade, json.encode(p.data), p.id, gang.name })
        else
            add('INSERT INTO gangbuilder_points (gang_name, type, label, coords, min_grade, data) VALUES (?, ?, ?, ?, ?, ?)',
                { gang.name, p.type, p.label, json.encode(p.coords), p.min_grade, json.encode(p.data) })
        end
    end
    for id, p in pairs(GB.Points) do
        if p.gang_name == gang.name and not keep[id] then
            add('DELETE FROM gangbuilder_points WHERE id = ? AND gang_name = ?', { id, gang.name })
        end
    end

    local ok = MySQL.transaction.await(q)
    if not ok then return cb(fail('Erreur SQL : la sauvegarde a été annulée (voir la console serveur)')) end

    GB.loadAll()
    GB.refreshJob2()

    -- Membres en ligne dont le grade n'existe plus
    for _, member in ipairs(GB.onlineMembers(gang.name)) do
        local _, grade = GB.job2Of(member)
        if grade > #grades - 1 then GB.setJob2(member, gang.name, 0) end
    end
    GB.syncAll()
    GB.log(gang.name, xPlayer, isNew and 'gang_created' or 'gang_updated', ('%d grades, %d points'):format(#grades, #points))
    cb({ ok = true, name = gang.name, created = isNew, compat = GB.compatRefresh() })
end)

ESX.RegisterServerCallback('gangbuilder:delete', function(src, cb, name)
    if not GB.isDev(src) then return cb(fail('Permission refusée')) end
    local gang = GB.Gangs[name]
    if not gang then return cb(fail('Ce gang n\'est pas géré par le builder (suppression refusée)')) end

    -- 1) Les membres reviennent « sans gang » (en ligne, puis hors ligne)
    for _, member in ipairs(GB.onlineMembers(name)) do GB.setJob2(member, J.Default.name, J.Default.grade) end

    -- 2) Identifiants des coffres ox_inventory liés au gang
    local stashes = {}
    for id, p in pairs(GB.Points) do
        if p.gang_name == name and p.type == 'stash' then stashes[#stashes + 1] = ('gangbuilder_%d'):format(id) end
    end

    -- 3) Suppression étape par étape : une table absente ou une requête en échec ne bloque JAMAIS le reste
    local failed = {}
    local function run(label, query, values)
        local ok, err = pcall(function() return MySQL.update.await(query, values or {}) end)
        if not ok then failed[#failed + 1] = label print(('^3[gangbuilder] suppression « %s » : %s^0'):format(label, tostring(err))) end
    end

    if GB.inventory() == 'ox' then
        for _, id in ipairs(stashes) do pcall(function() exports.ox_inventory:ClearInventory(id) end) end
    end
    if #stashes > 0 then
        local marks = {}
        for i = 1, #stashes do marks[i] = '?' end
        run('ox_inventory (coffres)', ('DELETE FROM ox_inventory WHERE name IN (%s)'):format(table.concat(marks, ',')), stashes)
    end

    local C = J.GradeColumns
    run('territoires', 'UPDATE gangbuilder_territories SET owner = NULL, captured_at = 0, protected_until = 0 WHERE owner = ?', { name })
    run('points du gang', 'DELETE FROM gangbuilder_points WHERE gang_name = ?', { name })
    run('statistiques', 'DELETE FROM gangbuilder_stats WHERE gang_name = ?', { name })
    run('journal du gang', 'DELETE FROM gangbuilder_logs WHERE gang_name = ?', { name })
    run('membres hors ligne', ('UPDATE %s SET %s = ?, %s = ? WHERE %s = ?'):format(GB.id(J.UsersTable), GB.id(J.UserJobColumn), GB.id(J.UserGradeColumn), GB.id(J.UserJobColumn)),
        { J.Default.name, J.Default.grade, name })
    run('grades job2', ('DELETE FROM %s WHERE %s = ?'):format(GB.id(J.GradesTable), GB.id(C.job)), { name })
    run('gang job2 (jobs2)', ('DELETE FROM %s WHERE name = ?'):format(GB.id(J.JobsTable)), { name })
    run('fiche builder', 'DELETE FROM gangbuilder_gangs WHERE name = ?', { name })

    GB.log('_deleted', ESX.GetPlayerFromId(src), 'gang_deleted', ('%s (%s)'):format(gang.label, name))
    if GetResourceState('pickax_dlogs') == 'started' then pcall(function() exports.pickax_dlogs:Delete('gang', name) end) end
    GB.loadAll()
    GB.refreshJob2()
    GB.syncAll()
    local compat = GB.compatRefresh()
    if #failed > 0 then
        return cb({ ok = true, compat = compat, warning = ('Gang supprimé, mais ces éléments ont échoué (voir console serveur) : %s'):format(table.concat(failed, ', ')) })
    end
    cb({ ok = true, compat = compat })
end)

-- Se mettre soi-même dans un gang pour le tester
ESX.RegisterServerCallback('gangbuilder:setMyJob', function(src, cb, name, grade)
    if not GB.isDev(src) then return cb(fail('Permission refusée')) end
    local xPlayer = ESX.GetPlayerFromId(src)
    local gang = GB.Gangs[name]
    if not xPlayer or not gang then return cb(fail('Gang inconnu')) end
    grade = int(grade, 0, #gang.grades - 1, 0)
    GB.setJob2(xPlayer, name, grade)
    local n = GB.job2Of(src)
    if n ~= name then
        return cb(fail('Le job2 n\'a pas été appliqué : ton es_extended ne connaît pas encore ce gang (voir /gbcheck et Config.Job2.Refresh*).'))
    end
    cb({ ok = true })
end)

-- Quitter le gang de test
ESX.RegisterServerCallback('gangbuilder:leaveMyJob', function(src, cb)
    if not GB.isDev(src) then return cb(fail('Permission refusée')) end
    GB.setJob2(src, J.Default.name, J.Default.grade)
    cb({ ok = true })
end)

ESX.RegisterServerCallback('gangbuilder:isDev', function(src, cb) cb(GB.isDev(src)) end)

RegisterCommand(Config.Command, function(src)
    if src == 0 then return end
    if not GB.isDev(src) then
        GB.notify(src, '~r~Tu n\'as pas la permission d\'utiliser le Gang Builder.')
        return
    end
    TriggerClientEvent('gangbuilder:client:openBuilder', src)
end, false)

-- ─────────────────────────────── Diagnostic complet : /gbcheck (console serveur ou joueur _dev) ───────────────────────────────
local function runCheck()
    local lines, bad = {}, 0
    local function ok(msg) lines[#lines + 1] = '^2✔^0 ' .. msg end
    local function warn(msg) lines[#lines + 1] = '^3⚠^0 ' .. msg bad = bad + 1 end
    local function err(msg) lines[#lines + 1] = '^1✘^0 ' .. msg bad = bad + 1 end

    for _, r in ipairs({ 'es_extended', 'oxmysql' }) do
        if GetResourceState(r) == 'started' then ok(r .. ' démarré') else err(r .. ' n\'est pas démarré') end
    end
    if GetResourceState('ox_inventory') == 'started' then ok('ox_inventory détecté (coffres, fouille, armurerie)') else warn('ox_inventory absent : coffres et fouille indisponibles') end

    -- job2 côté es_extended
    local refresh = {}
    for _, fn in ipairs(J.RefreshFunctions or {}) do if type(ESX[fn]) == 'function' then refresh[#refresh + 1] = 'ESX.' .. fn end end
    if #refresh > 0 then ok('rechargement ES disponible : ' .. table.concat(refresh, ', ')) else warn('aucune fonction de rechargement job2 dans ES (' .. table.concat(J.RefreshFunctions or {}, ', ') .. ') : restart nécessaire après création d\'un gang, ou renseigne Config.Job2.Refresh') end
    local first = GetPlayers()[1]
    if first then
        local xp = ESX.GetPlayerFromId(tonumber(first))
        if xp then
            local j = xp[J.PlayerField]
            if type(j) == 'table' and j.name then ok(('xPlayer.%s lisible (joueur %s : %s, grade %s)'):format(J.PlayerField, first, j.name, tostring(j.grade)))
            else warn(('xPlayer.%s absent : lecture/écriture du job2 via la base (Config.Job2.Source = %s)'):format(J.PlayerField, J.Source)) end
            if type(xp[J.SetMethod]) == 'function' then ok(('xPlayer.%s disponible'):format(J.SetMethod)) else warn(('xPlayer.%s absent : écriture du job2 directement en base + event %s'):format(J.SetMethod, J.ClientEvent)) end
        end
    else
        lines[#lines + 1] = '   ^8(aucun joueur connecté : vérifications xPlayer.job2 / setJob2 ignorées)^0'
    end

    -- tables
    local tables = { 'gangbuilder_gangs', 'gangbuilder_points', 'gangbuilder_territories', 'gangbuilder_logs', 'gangbuilder_stats', 'gangbuilder_settings', J.JobsTable, J.GradesTable, J.UsersTable }
    for _, t in ipairs(tables) do
        local exists = MySQL.scalar.await('SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?', { t }) or 0
        if exists == 0 then err('table manquante : ' .. t) end
    end
    for _, col in ipairs({ J.UserJobColumn, J.UserGradeColumn }) do
        local exists = MySQL.scalar.await('SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?', { J.UsersTable, col }) or 0
        if exists == 0 then err(('colonne manquante : %s.%s'):format(J.UsersTable, col)) end
    end
    local def = MySQL.scalar.await(('SELECT COUNT(*) FROM %s WHERE name = ?'):format(GB.id(J.JobsTable)), { J.Default.name }) or 0
    if def == 0 then warn(('job2 par défaut « %s » absent de %s : les membres virés / les gangs supprimés laisseront un job2 inconnu'):format(J.Default.name, J.JobsTable)) end

    -- markers
    local function differs(cur, d) return cur and d and (cur.marker ~= d.marker or table.concat(cur.color or {}, ',') ~= table.concat(d.color or {}, ',')) end
    local custom = {}
    for k, v in pairs(GBGet('pointTypes')) do if differs(v, GBDefaults.pointTypes[k]) then custom[#custom + 1] = k end end
    if #custom > 0 then
        table.sort(custom)
        warn(('markers personnalisés enregistrés en base (%s) : ils remplacent ceux de config.lua → Paramètres → Markers des points → « Réinitialiser cette section »'):format(table.concat(custom, ', ')))
    end

    local n, pts = 0, 0
    for name, gang in pairs(GB.Gangs) do
        n = n + 1
        local prefix = ('[%s] '):format(name)
        local row = MySQL.single.await(('SELECT name FROM %s WHERE name = ?'):format(GB.id(J.JobsTable)), { name })
        if not row then err(prefix .. 'absent de ' .. J.JobsTable .. ' (ES ne le connaît pas)') end
        local g = MySQL.scalar.await(('SELECT COUNT(*) FROM %s WHERE %s = ?'):format(GB.id(J.GradesTable), GB.id(J.GradeColumns.job)), { name }) or 0
        if g == 0 then err(prefix .. 'aucun grade dans ' .. J.GradesTable) elseif g ~= #gang.grades then warn(prefix .. ('%d grades en base, %d attendus'):format(g, #gang.grades)) end
        local b = gang.blip or {}
        if b.enabled and not (b.coords and b.coords.x) then err(prefix .. 'blip activé sans position : il ne s\'affichera pas') end
        local hasBoss = false
        for _, p in pairs(GB.Points) do
            if p.gang_name == name then
                pts = pts + 1
                if p.type == 'boss' then hasBoss = true end
                if not (p.coords and p.coords.x) then err(prefix .. ('point #%d (%s) sans position'):format(p.id, p.type)) end
                if p.min_grade > #gang.grades - 1 then warn(prefix .. ('point #%d : grade min. %d inexistant'):format(p.id, p.min_grade)) end
            end
        end
        if not hasBoss then warn(prefix .. 'pas de point « Gestion du gang » : personne ne pourra gérer le gang en jeu') end
        lines[#lines + 1] = ('   ^8%s%d membre(s) · trésorerie $%d + $%d sale · réputation %d^0'):format(prefix, GB.memberCount(name), GB.treasury(name))
    end
    ok(('%d gang(s) et %d point(s) du builder vérifiés · %d territoire(s)'):format(n, pts, GB.count(GB.Territories)))
    lines[#lines + 1] = bad == 0 and '^2Tout est en ordre.^0' or ('^3%d point(s) à corriger.^0'):format(bad)
    return lines
end

RegisterCommand('gbcheck', function(src)
    if src ~= 0 and not GB.isDev(src) then return end
    local lines = runCheck()
    print('^5──────── gangbuilder : diagnostic ────────^0')
    for _, l in ipairs(lines) do print(l) end
    if src ~= 0 then GB.notify(src, 'Diagnostic gangbuilder affiché dans la console serveur.') end
end, false)
