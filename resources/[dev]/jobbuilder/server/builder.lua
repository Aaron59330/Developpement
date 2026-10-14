-- ─────────────────────────────── Builder (réservé aux groupes autorisés) ───────────────────────────────

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

local function cleanCoords(c, required)
    if type(c) ~= 'table' then return nil end
    local x, y, z = tonumber(c.x), tonumber(c.y), tonumber(c.z)
    if not (x and y and z) then return nil end
    return { x = math.floor(x * 100) / 100, y = math.floor(y * 100) / 100, z = math.floor(z * 100) / 100, h = math.floor((tonumber(c.h) or 0) * 100) / 100 }
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

-- Style de marker « creux » : seuls les champs renseignés sont gardés (le reste est hérité : point → job → type de point)
local function cleanStyle(s)
    if type(s) ~= 'table' then return nil end
    local out, n = {}, 0
    if tonumber(s.marker) then out.marker = math.floor(num(s.marker, 0, 50, 1)) n = n + 1 end
    if type(s.color) == 'table' and tonumber(s.color[1]) and tonumber(s.color[2]) and tonumber(s.color[3]) then
        out.color = { math.floor(num(s.color[1], 0, 255, 255)), math.floor(num(s.color[2], 0, 255, 255)), math.floor(num(s.color[3], 0, 255, 255)) } n = n + 1
    end
    if tonumber(s.alpha) then out.alpha = math.floor(num(s.alpha, 0, 255, 140)) n = n + 1 end
    if type(s.scale) == 'table' then
        local sc = {}
        local any = false
        for k, def in pairs({ x = 0.9, y = 0.9, z = 0.6 }) do
            if tonumber(s.scale[k]) then any = true end
            sc[k] = num(tonumber(s.scale[k]), 0.05, 20, def)
        end
        if any then out.scale = sc n = n + 1 end
    end
    if tonumber(s.offset) then out.offset = num(s.offset, -10, 10, -0.95) n = n + 1 end
    if s.bob ~= nil then out.bob = s.bob == true n = n + 1 end
    if s.rotate ~= nil then out.rotate = s.rotate == true n = n + 1 end
    return n > 0 and out or nil
end

-- ─────────────────────────────── Validation d'un point ───────────────────────────────
local function cleanPoint(p, maxGrade, jobType)
    if type(p) ~= 'table' or not Config.PointTypes[p.type] or (Config.PointTypes[p.type].hidden and p.type ~= 'garage_return') then return nil, 'Type de point invalide' end
    local coords = cleanCoords(p.coords)
    if not coords then return nil, ('Coordonnées manquantes (%s)'):format(Config.PointTypes[p.type].label) end
    if jobType and not JBPointAllowed(p.type, jobType) then
        return nil, ('Le point « %s » n\'est pas disponible pour un job de type « %s » : supprime-le de la liste'):format(Config.PointTypes[p.type].label, (Config.JobTypes[jobType] or {}).label or jobType)
    end
    local d = type(p.data) == 'table' and p.data or {}
    local out = {
        id = tonumber(p.id),
        type = p.type,
        label = str(p.label, 60, Config.PointTypes[p.type].label),
        coords = coords,
        min_grade = math.floor(num(p.min_grade, 0, maxGrade, 0)),
        data = {},
    }
    if out.label == '' then out.label = Config.PointTypes[p.type].label end
    out.data.style = cleanStyle(d.style)   -- apparence propre à ce point (sinon : style du job, sinon du type de point)

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
                    model = model, label = str(v.label, 60, model), min_grade = math.floor(num(v.min_grade, 0, maxGrade, 0)),
                    color = num(v.color, 0, 160, nil),
                }
            end
        end
        if #out.data.vehicles == 0 then return nil, ('Garage "%s" : ajoute au moins un véhicule'):format(out.label) end
        -- Point de rangement intégré au garage (position propre, rayon, option « tous les véhicules »)
        if type(d.store) == 'table' then
            local sc = cleanCoords(d.store.coords)
            if not sc then return nil, ('Garage "%s" : position du point de rangement manquante (ou désactive le rangement)'):format(out.label) end
            out.data.store = { coords = sc, radius = num(d.store.radius, 2, 20, 5.0), any = d.store.any == true }
        end

    elseif p.type == 'cloakroom' then
        out.data.outfits = {}
        for _, o in ipairs(type(d.outfits) == 'table' and d.outfits or {}) do
            local male, female = cleanClothes(o.male), cleanClothes(o.female)
            if (male or female) and #out.data.outfits < 40 then
                out.data.outfits[#out.data.outfits + 1] = {
                    label = str(o.label, 60, 'Tenue'), min_grade = math.floor(num(o.min_grade, 0, maxGrade, 0)), male = male, female = female,
                }
            end
        end

    elseif p.type == 'armory' then
        out.data.items = {}
        for _, it in ipairs(type(d.items) == 'table' and d.items or {}) do
            local name = str(it.name, 60)
            if name:match('^[%w_%-%.]+$') and #out.data.items < Config.MaxItemsPerPoint then
                out.data.items[#out.data.items + 1] = {
                    name = name, label = str(it.label, 60, name), count = math.floor(num(it.count, 1, 1000, 1)),
                    ammo = math.floor(num(it.ammo, 0, 9999, 0)), min_grade = math.floor(num(it.min_grade, 0, maxGrade, 0)),
                }
            end
        end
        if #out.data.items == 0 then return nil, ('Armurerie "%s" : ajoute au moins un objet'):format(out.label) end

    elseif p.type == 'stash' then
        out.data.slots = math.floor(num(d.slots, 5, 200, 50))
        out.data.weight = math.floor(num(d.weight, 1, 2000, 100))

    elseif p.type == 'garage_return' then
        out.data.kind = Config.GarageKinds[d.kind] and d.kind or 'car'
        out.data.radius = num(d.radius, 2, 20, 5.0)
        out.data.any = d.any == true

    elseif p.type == 'tuning' then
        out.data.radius = num(d.radius, 2, 30, Config.Tuning.Radius)

    elseif p.type == 'missions' then
        out.data.spawn = cleanCoords(d.spawn)   -- position d'apparition du véhicule de mission (optionnelle : sinon le point lui-même)

    elseif p.type == 'showroom' then
        local spawn = cleanCoords(d.spawn)
        if not spawn then return nil, ('Showroom "%s" : position de livraison des véhicules manquante'):format(out.label) end
        out.data.spawn = spawn

    elseif p.type == 'display' then
        local model = str(d.model, 40):lower()
        if not model:match('^[%w_]+$') then return nil, ('Véhicule expo "%s" : modèle manquant'):format(out.label) end
        out.data.model = model
        out.data.color = num(d.color, 0, 160, nil)

    elseif p.type == 'testdrive' then
        local spawn = cleanCoords(d.spawn)
        if not spawn then return nil, ('Essai routier "%s" : position de départ manquante'):format(out.label) end
        out.data.spawn = spawn
        out.data.seconds = math.floor(num(d.seconds, 30, 900, Config.Dealer.TestSeconds))

    elseif p.type == 'harvest' then
        local name = str(d.name, 60)
        if not name:match('^[%w_%-%.]+$') then return nil, ('Récolte "%s" : choisis l\'objet récolté'):format(out.label) end
        out.data = { name = name, label = str(d.label, 60, name), count = math.floor(num(d.count, 1, Config.Kitchen.MaxHarvest, 1)), seconds = math.floor(num(d.seconds, 2, 120, 8)) }

    elseif p.type == 'kitchen' then
        local K = Config.Kitchen
        out.data.recipes = {}
        for _, r in ipairs(type(d.recipes) == 'table' and d.recipes or {}) do
            if #out.data.recipes >= K.MaxRecipes then break end
            local o = type(r.output) == 'table' and r.output or {}
            local oname = str(o.name, 60)
            if not oname:match('^[%w_%-%.]+$') then return nil, ('Cuisine "%s" : une recette n\'a pas de produit fini'):format(out.label) end
            local inputs = {}
            for _, i in ipairs(type(r.inputs) == 'table' and r.inputs or {}) do
                local iname = str(i.name, 60)
                if iname:match('^[%w_%-%.]+$') and #inputs < K.MaxInputs then
                    inputs[#inputs + 1] = { name = iname, label = str(i.label, 60, iname), count = math.floor(num(i.count, 1, 100, 1)) }
                end
            end
            if #inputs == 0 then return nil, ('Cuisine "%s" : la recette « %s » n\'a aucun ingrédient'):format(out.label, str(r.label, 60, oname)) end
            out.data.recipes[#out.data.recipes + 1] = {
                label = str(r.label, 60, str(o.label, 60, oname)), seconds = math.floor(num(r.seconds, 2, 120, 10)), min_grade = math.floor(num(r.min_grade, 0, maxGrade, 0)),
                output = { name = oname, label = str(o.label, 60, oname), count = math.floor(num(o.count, 1, 100, 1)) }, inputs = inputs,
            }
        end
        if #out.data.recipes == 0 then return nil, ('Cuisine "%s" : ajoute au moins une recette'):format(out.label) end

    elseif p.type == 'shop' then
        out.data.public = d.public == true
        out.data.items = {}
        for _, it in ipairs(type(d.items) == 'table' and d.items or {}) do
            local name = str(it.name, 60)
            if name:match('^[%w_%-%.]+$') and #out.data.items < Config.MaxItemsPerPoint then
                out.data.items[#out.data.items + 1] = {
                    name = name, label = str(it.label, 60, name), price = math.floor(num(it.price, 0, 10000000, 1)),
                    min_grade = math.floor(num(it.min_grade, 0, maxGrade, 0)),
                }
            end
        end
        if #out.data.items == 0 then return nil, ('Boutique "%s" : ajoute au moins un article'):format(out.label) end
    end
    out.data.style = out.data.style or cleanStyle(d.style)
    return out
end

-- ─────────────────────────────── Validation d'un job ───────────────────────────────
local function cleanJob(payload)
    if type(payload) ~= 'table' or type(payload.job) ~= 'table' then return nil, 'Données invalides' end
    local j = payload.job
    local name = str(j.name, 31):lower()
    if not name:match('^[a-z][a-z0-9_]+$') or #name < 2 then
        return nil, 'Nom du job invalide (lettres minuscules, chiffres et _ ; 2 à 31 caractères, commence par une lettre)'
    end
    if not Config.JobTypes[j.type] then return nil, 'Type de job invalide' end
    local label = str(j.label, 50)
    if label == '' then return nil, 'Le label du job est obligatoire' end

    if type(payload.grades) ~= 'table' or #payload.grades < 1 then return nil, 'Il faut au moins un grade' end
    if #payload.grades > Config.MaxGrades then return nil, ('Maximum %d grades'):format(Config.MaxGrades) end

    local grades, used = {}, {}
    for i, g in ipairs(payload.grades) do
        local gname = str(g.name, 40):lower():gsub('[^%w_]', '_')
        if gname == '' then gname = 'grade' .. (i - 1) end
        if used[gname] then return nil, ('Nom de grade en double : %s'):format(gname) end
        used[gname] = true
        grades[i] = { grade = i - 1, name = gname, label = str(g.label, 50, gname), salary = math.floor(num(g.salary, 0, 1000000, 0)) }
    end
    local maxGrade = #grades - 1

    local blip = type(j.blip) == 'table' and j.blip or {}
    if blip.enabled == true and not cleanCoords(blip.coords) then
        return nil, 'Blip activé mais sans position : onglet Blip → « Ma position » (ou décoche « Afficher le blip »)'
    end
    local settings = type(j.settings) == 'table' and j.settings or {}
    local actions = {}
    for _, a in ipairs(type(settings.actions) == 'table' and settings.actions or {}) do
        if Config.Actions[a] and not Config.Actions[a].auto and JBActionAllowed(a, j.type) then actions[#actions + 1] = a end
    end

    local points = {}
    if type(payload.points) == 'table' then
        if #payload.points > Config.MaxPoints then return nil, ('Maximum %d points par job'):format(Config.MaxPoints) end
        for _, p in ipairs(payload.points) do
            local cp, err = cleanPoint(p, maxGrade, j.type)
            if not cp then return nil, err end
            points[#points + 1] = cp
        end
    end

    -- Rangement obligatoire : chaque garage a son point de rangement (ou, pour les anciens jobs, un point « Rangement véhicule » du même type)
    local returns = {}
    for _, p in ipairs(points) do if p.type == 'garage_return' then returns[p.data.kind or 'car'] = true end end
    for _, p in ipairs(points) do
        if p.type == 'garage' and not p.data.store and not returns[p.data.kind or 'car'] then
            return nil, ('Garage "%s" : ajoute un point de rangement (carte « Rangement des véhicules »), il est obligatoire pour pouvoir ranger les véhicules'):format(p.label)
        end
    end

    return {
        name = name, label = label, type = j.type,
        whitelisted = j.whitelisted ~= false, society = j.society ~= false,
        boss_grade = math.floor(num(j.boss_grade, 0, maxGrade, maxGrade)),
        blip = {
            enabled = blip.enabled == true, label = str(blip.label, 40), sprite = math.floor(num(blip.sprite, 0, 900, 478)),
            color = math.floor(num(blip.color, 0, 85, 0)), scale = num(blip.scale, 0.3, 2.0, 0.9), coords = cleanCoords(blip.coords),
            shortRange = blip.shortRange == true,
        },
        settings = {
            actions = actions,
            plate_prefix = str(settings.plate_prefix, 4):upper():gsub('[^%w]', ''),
            -- Immobilier (utilisé uniquement par les jobs de type realestate)
            commission = math.floor(num(settings.commission, 0, 50, Config.Real.DefaultCommission)),
            prop_grade = math.floor(num(settings.prop_grade, 0, maxGrade, 0)),
            prop_admin_grade = math.floor(num(settings.prop_admin_grade, 0, maxGrade, maxGrade)),
            -- Concession (jobs de type dealer)
            dealer_commission = math.floor(num(settings.dealer_commission, 0, 50, Config.Dealer.DefaultCommission)),
            dealer_sell_grade = math.floor(num(settings.dealer_sell_grade, 0, maxGrade, 0)),
            dealer_admin_grade = math.floor(num(settings.dealer_admin_grade, 0, maxGrade, maxGrade)),
            dealer_self_service = settings.dealer_self_service == true,
            dealer_auto = settings.dealer_auto ~= false,
            dealer_markup = math.floor(num(settings.dealer_markup, 10, 500, 100)),
            dealer_categories = (function()
                local out = {}
                for _, c in ipairs(type(settings.dealer_categories) == 'table' and settings.dealer_categories or {}) do
                    c = str(tostring(c), 40)
                    if c:match('^[%w_%-]+$') and #out < 60 then out[#out + 1] = c end
                end
                return out
            end)(),
            -- Gouvernement (jobs de type government)
            gov_grade = math.floor(num(settings.gov_grade, 0, maxGrade, 0)),
            gov_admin_grade = math.floor(num(settings.gov_admin_grade, 0, maxGrade, maxGrade)),
            treasury = settings.treasury ~= false,
            -- Carte (vente directe au client : F6 → Vendre un produit)
            menu = (function()
                local out = {}
                for _, it in ipairs(type(settings.menu) == 'table' and settings.menu or {}) do
                    local name = str(it.name, 60)
                    if name:match('^[%w_%-%.]+$') and #out < Config.Kitchen.MaxMenu then
                        out[#out + 1] = { name = name, label = str(it.label, 60, name), price = math.floor(num(it.price, 1, 100000, 10)) }
                    end
                end
                return out
            end)(),
            -- Tablette (jobs de type police, ou tout job qui coche l'action « Tablette »)
            tablet_enabled = settings.tablet_enabled ~= false,
            tablet_grade = math.floor(num(settings.tablet_grade, 0, maxGrade, 0)),
            tablet_admin_grade = math.floor(num(settings.tablet_admin_grade, 0, maxGrade, maxGrade)),
            tablet_records = settings.tablet_records ~= false,
            tablet_dispatch = settings.tablet_dispatch ~= false,
            tablet_map = settings.tablet_map ~= false,
            fine_grade = math.floor(num(settings.fine_grade, 0, maxGrade, 0)),
            fine_custom = settings.fine_custom ~= false,
            pursuit_grade = math.floor(num(settings.pursuit_grade, 0, maxGrade, 0)),
            fines = (function()
                local out = {}
                for _, f in ipairs(type(settings.fines) == 'table' and settings.fines or {}) do
                    local label = str(f.label, 60)
                    if label ~= '' and #out < 60 then
                        out[#out + 1] = { label = label, amount = math.floor(num(f.amount, Config.Police.MinFine, Config.Police.MaxFine, 100)) }
                    end
                end
                return out
            end)(),
            -- Apparence propre au job : couleur de l'interface (menus) et style par défaut de ses markers
            ui_accent = (type(settings.ui_accent) == 'table' and tonumber(settings.ui_accent[1]) and tonumber(settings.ui_accent[2]) and tonumber(settings.ui_accent[3]))
                and { math.floor(num(settings.ui_accent[1], 0, 255, 0)), math.floor(num(settings.ui_accent[2], 0, 255, 0)), math.floor(num(settings.ui_accent[3], 0, 255, 0)) } or nil,
            marker = cleanStyle(settings.marker),
            -- Tablette médicale (jobs EMS)
            ems_tablet_enabled = settings.ems_tablet_enabled ~= false,
            ems_tablet_grade = math.floor(num(settings.ems_tablet_grade, 0, maxGrade, 0)),
            ems_admin_grade = math.floor(num(settings.ems_admin_grade, 0, maxGrade, maxGrade)),
            care_grade = math.floor(num(settings.care_grade, 0, maxGrade, 0)),
            care_custom = settings.care_custom ~= false,
            care_prices = (function()
                local out = {}
                for _, f in ipairs(type(settings.care_prices) == 'table' and settings.care_prices or {}) do
                    local label = str(f.label, 60)
                    if label ~= '' and #out < 60 then out[#out + 1] = { label = label, amount = math.floor(num(f.amount, Config.Ems.MinCare, Config.Ems.MaxCare, 100)) } end
                end
                return out
            end)(),
            -- Banque (jobs de type bank)
            bank_tablet_enabled = settings.bank_tablet_enabled ~= false,
            bank_tablet_grade = math.floor(num(settings.bank_tablet_grade, 0, maxGrade, 0)),
            bank_loan_grade = math.floor(num(settings.bank_loan_grade, 0, maxGrade, math.min(2, maxGrade))),
            bank_fee_grade = math.floor(num(settings.bank_fee_grade, 0, maxGrade, 0)),
            bank_admin_grade = math.floor(num(settings.bank_admin_grade, 0, maxGrade, maxGrade)),
            bank_loans = settings.bank_loans ~= false,
            bank_ops = settings.bank_ops ~= false,
            bank_funding = settings.bank_funding == 'system' and 'system' or 'society',
            bank_loan_max = math.floor(num(settings.bank_loan_max, Config.Bank.MinLoan, Config.Bank.MaxLoan, 100000)),
            bank_rate_min = math.floor(num(settings.bank_rate_min, Config.Bank.MinRate, Config.Bank.MaxRate, 0)),
            bank_rate_max = math.floor(num(settings.bank_rate_max, Config.Bank.MinRate, Config.Bank.MaxRate, 25)),
            bank_fees = (function()
                local out = {}
                for _, f in ipairs(type(settings.bank_fees) == 'table' and settings.bank_fees or {}) do
                    local label = str(f.label, 60)
                    if label ~= '' and #out < 40 then out[#out + 1] = { label = label, amount = math.floor(num(f.amount, Config.Bank.MinFee, Config.Bank.MaxFee, 100)) } end
                end
                return out
            end)(),
            -- Atelier tuning
            tuning_grade = math.floor(num(settings.tuning_grade, 0, maxGrade, 0)),
            tuning_billing = ({ customer = true, society = true, free = true })[settings.tuning_billing] and settings.tuning_billing or 'customer',
            tuning_markup = math.floor(num(settings.tuning_markup, 10, 500, 100)),
            -- Annonces d'entreprise
            announce_enabled = settings.announce_enabled ~= false,
            announce_grade = math.floor(num(settings.announce_grade, 0, maxGrade, maxGrade)),
            announce_cooldown = math.floor(num(settings.announce_cooldown, 0, 86400, Config.Announce.Cooldown)),
            announce_cost = math.floor(num(settings.announce_cost, 0, 1000000, Config.Announce.Cost)),
            announce_radius = math.floor(num(settings.announce_radius, 0, 10000, 0)),
            announce_duration = math.floor(num(settings.announce_duration, 3, 60, Config.Announce.Duration)),
            announce_types = (function()
                local out, valid = {}, {}
                for _, t in ipairs(Config.Announce.Types) do valid[t.id] = true end
                for _, id in ipairs(type(settings.announce_types) == 'table' and settings.announce_types or {}) do
                    if valid[id] and #out < 20 then out[#out + 1] = id end
                end
                return out
            end)(),
            -- Missions PNJ
            missions_enabled = settings.missions_enabled ~= false,
            missions_source = settings.missions_source == 'society' and 'society' or 'system',
            missions_mult = math.floor(num(settings.missions_mult, 10, 300, 100)),
        },
    }, grades, points
end

-- ─────────────────────────────── Callbacks ───────────────────────────────
ESX.RegisterServerCallback('jobbuilder:list', function(src, cb)
    if not JB.isDev(src) then return cb({}) end
    local list = {}
    for name, job in pairs(JB.Jobs) do
        local pts, online = 0, 0
        for _, p in pairs(JB.Points) do if p.job_name == name then pts = pts + 1 end end
        local ok, players = pcall(ESX.GetExtendedPlayers, 'job', name)
        if ok and players then online = #players end
        list[#list + 1] = { name = name, label = job.label, type = job.type, grades = #job.grades, points = pts, online = online, society = job.society }
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    cb(list)
end)

ESX.RegisterServerCallback('jobbuilder:get', function(src, cb, name)
    if not JB.isDev(src) then return cb(nil) end
    local job = JB.Jobs[name]
    if not job then return cb(nil) end
    local points = {}
    for _, p in pairs(JB.Points) do
        if p.job_name == name then points[#points + 1] = p end
    end
    table.sort(points, function(a, b) return a.id < b.id end)
    cb({
        job = {
            name = job.name, label = job.label, type = job.type, whitelisted = job.whitelisted, society = job.society,
            boss_grade = job.boss_grade, blip = job.blip, settings = job.settings,
        },
        grades = job.grades,
        points = points,
    })
end)

ESX.RegisterServerCallback('jobbuilder:catalog', function(src, cb)
    if not JB.isDev(src) then return cb(nil) end
    local items = {}
    if JB.inventory() == 'ox' then
        local ok, all = pcall(function() return exports.ox_inventory:Items() end)
        if ok and all then
            for name, it in pairs(all) do items[#items + 1] = { name = name, label = it.label or name } end
        end
    end
    if #items == 0 then
        for _, r in ipairs(MySQL.query.await('SELECT name, label FROM items') or {}) do items[#items + 1] = { name = r.name, label = r.label } end
    end
    table.sort(items, function(a, b) return a.name < b.name end)
    local vehicles = MySQL.query.await('SELECT name, model, category FROM vehicles ORDER BY name') or {}
    cb({ items = items, vehicles = vehicles, vehicleCategories = (JB.vehicleCategories and JB.vehicleCategories() or {}), jobTypes = Config.JobTypes, pointTypes = Config.PointTypes, garageKinds = Config.GarageKinds, categoryTypes = Config.Dealer.CategoryTypes, maxItems = Config.MaxItemsPerPoint, actions = Config.Actions, clothesKeys = Config.ClothesKeys, kitchen = Config.Kitchen, announceTypes = Config.Announce.Types, announce = Config.Announce, police = Config.Police, tuning = Config.Tuning, ems = Config.Ems, bank = Config.Bank, pointRules = JB_POINT_RULES })
end)

ESX.RegisterServerCallback('jobbuilder:save', function(src, cb, payload)
    if not JB.isDev(src) then return cb(fail('Permission refusée')) end
    local job, grades, points = cleanJob(payload)
    if not job then return cb(fail(grades)) end

    local isNew = JB.Jobs[job.name] == nil
    if isNew then
        -- Ne jamais écraser / mélanger un job qui existe déjà et n'a pas été créé par le builder
        local ex = MySQL.query.await('SELECT name FROM jobs WHERE LOWER(name) = ?', { job.name })
        if ex and #ex > 0 then return cb(fail(('Le job "%s" existe déjà dans ta table jobs (non géré par le builder)'):format(job.name))) end
        local okJ2, ex2 = pcall(MySQL.query.await, 'SELECT name FROM jobs2 WHERE LOWER(name) = ?', { job.name })
        if okJ2 and ex2 and #ex2 > 0 then return cb(fail(('Le nom "%s" est déjà utilisé dans jobs2'):format(job.name))) end
        if job.society then
            local acc = MySQL.query.await('SELECT name FROM addon_account WHERE LOWER(name) = ?', { JB.societyAccount(job.name):lower() })
            if acc and #acc > 0 then return cb(fail(('Le compte société "%s" existe déjà'):format(JB.societyAccount(job.name)))) end
        end
    end

    local q = {}
    local function add(query, values) q[#q + 1] = { query = query, values = values or {} } end

    -- 1) Table jobs (ESX)
    add('INSERT INTO jobs (name, label, whitelisted) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE label = VALUES(label), whitelisted = VALUES(whitelisted)',
        { job.name, job.label, job.whitelisted and 1 or 0 })

    -- 2) Table job_grades (ESX) : remplacement uniquement des grades DE CE JOB
    add('DELETE FROM job_grades WHERE job_name = ?', { job.name })
    for _, g in ipairs(grades) do
        add("INSERT INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female) VALUES (?, ?, ?, ?, ?, '{}', '{}')",
            { job.name, g.grade, g.name, g.label, g.salary })
    end
    add('UPDATE users SET job_grade = 0 WHERE job = ? AND job_grade > ?', { job.name, #grades - 1 })

    -- 3) Société (compatible esx_addonaccount / esx_datastore / esx_society)
    if job.society then
        local acc = JB.societyAccount(job.name)
        add('INSERT IGNORE INTO addon_account (name, label, shared) VALUES (?, ?, 1)', { acc, job.label })
        add('INSERT INTO addon_account_data (account_name, money, owner) SELECT ?, 0, NULL FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM addon_account_data WHERE account_name = ? AND owner IS NULL)', { acc, acc })
        add('INSERT IGNORE INTO addon_inventory (name, label, shared) VALUES (?, ?, 1)', { acc, job.label })
        add('INSERT IGNORE INTO datastore (name, label, shared) VALUES (?, ?, 1)', { acc, job.label })
        add("INSERT INTO datastore_data (name, data, owner) SELECT ?, '{}', NULL FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM datastore_data WHERE name = ? AND owner IS NULL)", { acc, acc })
    end

    -- 4) Données du builder
    local xPlayer = ESX.GetPlayerFromId(src)
    add([[INSERT INTO jobbuilder_jobs (name, label, type, whitelisted, society, boss_grade, blip, settings, created_by)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE label = VALUES(label), type = VALUES(type), whitelisted = VALUES(whitelisted), society = VALUES(society),
          boss_grade = VALUES(boss_grade), blip = VALUES(blip), settings = VALUES(settings)]],
        { job.name, job.label, job.type, job.whitelisted and 1 or 0, job.society and 1 or 0, job.boss_grade,
          json.encode(job.blip), json.encode(job.settings), xPlayer and xPlayer.identifier or 'console' })

    -- 5) Points : suppression des retirés, update des existants, insertion des nouveaux
    local keep = {}
    for _, p in ipairs(points) do
        local existing = p.id and JB.Points[p.id]
        if existing and existing.job_name == job.name then
            keep[p.id] = true
            add('UPDATE jobbuilder_points SET type = ?, label = ?, coords = ?, min_grade = ?, data = ? WHERE id = ? AND job_name = ?',
                { p.type, p.label, json.encode(p.coords), p.min_grade, json.encode(p.data), p.id, job.name })
        else
            add('INSERT INTO jobbuilder_points (job_name, type, label, coords, min_grade, data) VALUES (?, ?, ?, ?, ?, ?)',
                { job.name, p.type, p.label, json.encode(p.coords), p.min_grade, json.encode(p.data) })
        end
    end
    for id, p in pairs(JB.Points) do
        if p.job_name == job.name and not keep[id] then
            add('DELETE FROM jobbuilder_points WHERE id = ? AND job_name = ?', { id, job.name })
        end
    end

    local ok = MySQL.transaction.await(q)
    if not ok then return cb(fail('Erreur SQL : la sauvegarde a été annulée (voir la console serveur)')) end

    JB.loadAll()
    JB.refreshESX()

    -- Joueurs en ligne dont le grade n'existe plus
    local okP, players = pcall(ESX.GetExtendedPlayers, 'job', job.name)
    if okP and players then
        for _, xp in ipairs(players) do
            if xp.job.grade > #grades - 1 then xp.setJob(job.name, 0) end
        end
    end
    JB.syncAll()
    JB.log(job.name, xPlayer, isNew and 'job_created' or 'job_updated', ('%d grades, %d points'):format(#grades, #points))
    if JB.registerSociety then JB.registerSociety(job.name) end
    local compat = JB.compatRefresh and JB.compatRefresh() or nil
    cb({ ok = true, name = job.name, created = isNew, compat = compat })
end)

ESX.RegisterServerCallback('jobbuilder:delete', function(src, cb, name)
    if not JB.isDev(src) then return cb(fail('Permission refusée')) end
    local job = JB.Jobs[name]
    if not job then return cb(fail('Ce job n\'est pas géré par le builder (suppression refusée)')) end

    -- Une agence qui a encore des biens occupés ne peut pas être supprimée (les joueurs perdraient leur logement)
    local owned = MySQL.scalar.await("SELECT COUNT(*) FROM jobbuilder_properties WHERE job_name = ? AND status = 'owned'", { name }) or 0
    if owned > 0 then return cb(fail(('Cette agence a encore %d bien(s) occupé(s) : remets-les en vente avant de supprimer le job'):format(owned))) end

    -- 1) Les joueurs retombent chômeurs (en ligne puis hors ligne)
    local okP, players = pcall(ESX.GetExtendedPlayers, 'job', name)
    if okP and players then
        for _, xp in ipairs(players) do xp.setJob('unemployed', 0) end
    end

    -- 2) Identifiants des coffres ox_inventory liés au job (points coffre + coffres des propriétés de l'agence)
    local stashes = {}
    for id, p in pairs(JB.Points) do
        if p.job_name == name and p.type == 'stash' then stashes[#stashes + 1] = ('jobbuilder_%d'):format(id) end
    end
    for _, r in ipairs(MySQL.query.await('SELECT pt.id AS ptid, pt.property_id AS pid FROM jobbuilder_property_points pt JOIN jobbuilder_properties p ON p.id = pt.property_id WHERE p.job_name = ? AND pt.type = ?', { name, 'stash' }) or {}) do
        stashes[#stashes + 1] = ('jbprop_%d_%d'):format(r.pid, r.ptid)
    end

    -- 3) Suppression étape par étape : une table absente ou une requête en échec ne bloque JAMAIS le reste
    local failed = {}
    local function run(label, query, values)
        local ok, err = pcall(function() return MySQL.update.await(query, values or {}) end)
        if not ok then failed[#failed + 1] = label print(('^3[jobbuilder] suppression « %s » : %s^0'):format(label, tostring(err))) end
    end

    if JB.inventory() == 'ox' then
        for _, id in ipairs(stashes) do pcall(function() exports.ox_inventory:ClearInventory(id) end) end
    end
    if #stashes > 0 then
        local marks = {}
        for i = 1, #stashes do marks[i] = '?' end
        run('ox_inventory (coffres)', ('DELETE FROM ox_inventory WHERE name IN (%s)'):format(table.concat(marks, ',')), stashes)
    end

    local acc = JB.societyAccount(name)
    run('tenues des propriétés', 'DELETE FROM jobbuilder_property_outfits WHERE property_id IN (SELECT id FROM jobbuilder_properties WHERE job_name = ?)', { name })
    run('points de propriétés', 'DELETE FROM jobbuilder_property_points WHERE property_id IN (SELECT id FROM jobbuilder_properties WHERE job_name = ?)', { name })
    run('propriétés', 'DELETE FROM jobbuilder_properties WHERE job_name = ?', { name })
    run('historique immobilier', 'DELETE FROM jobbuilder_property_history WHERE job_name = ?', { name })
    run('catalogue concession', 'DELETE FROM jobbuilder_dealer_vehicles WHERE job_name = ?', { name })
    run('ventes concession', 'DELETE FROM jobbuilder_dealer_sales WHERE job_name = ?', { name })
    run('journal du trésor', 'DELETE FROM jobbuilder_treasury_log WHERE source = ?', { name })
    run('points du job', 'DELETE FROM jobbuilder_points WHERE job_name = ?', { name })
    run('statistiques de missions', 'DELETE FROM jobbuilder_mission_stats WHERE job_name = ?', { name })
    run('casiers (entrées)', 'DELETE FROM jobbuilder_record_entries WHERE job_name = ?', { name })
    run('casiers', 'DELETE FROM jobbuilder_records WHERE job_name = ?', { name })
    run('annonces', 'DELETE FROM jobbuilder_announces WHERE job_name = ?', { name })
    run('banque : prêts', 'DELETE FROM jobbuilder_bank_loans WHERE job_name = ?', { name })
    run('banque : historique', 'DELETE FROM jobbuilder_bank_entries WHERE job_name = ?', { name })
    run('banque : clients', 'DELETE FROM jobbuilder_bank_clients WHERE job_name = ?', { name })
    run('dossiers patients (entrées)', 'DELETE FROM jobbuilder_patient_entries WHERE job_name = ?', { name })
    run('dossiers patients', 'DELETE FROM jobbuilder_patients WHERE job_name = ?', { name })
    run('journal du job', 'DELETE FROM jobbuilder_logs WHERE job_name = ?', { name })
    run('joueurs hors ligne', "UPDATE users SET job = 'unemployed', job_grade = 0 WHERE job = ?", { name })
    run('société : comptes', 'DELETE FROM addon_account_data WHERE account_name = ?', { acc })
    run('société : compte', 'DELETE FROM addon_account WHERE name = ?', { acc })
    run('société : inventaire (objets)', 'DELETE FROM addon_inventory_items WHERE inventory_name = ?', { acc })
    run('société : inventaire', 'DELETE FROM addon_inventory WHERE name = ?', { acc })
    run('société : datastore (données)', 'DELETE FROM datastore_data WHERE name = ?', { acc })
    run('société : datastore', 'DELETE FROM datastore WHERE name = ?', { acc })
    run('grades ESX (job_grades)', 'DELETE FROM job_grades WHERE job_name = ?', { name })
    run('job ESX (jobs)', 'DELETE FROM jobs WHERE name = ?', { name })
    run('fiche builder', 'DELETE FROM jobbuilder_jobs WHERE name = ?', { name })

    JB.log('_deleted', ESX.GetPlayerFromId(src), 'job_deleted', ('%s (%s)'):format(job.label, name))
    JB.loadAll()
    if JB.loadProps then JB.loadProps() JB.syncPropsAll() end
    JB.refreshESX()
    JB.syncAll()
    local compat = JB.compatRefresh and JB.compatRefresh() or nil
    if #failed > 0 then
        return cb({ ok = true, compat = compat, warning = ('Job supprimé, mais ces éléments ont échoué (voir console serveur) : %s'):format(table.concat(failed, ', ')) })
    end
    cb({ ok = true, compat = compat })
end)

-- Se mettre soi-même dans un job pour le tester
ESX.RegisterServerCallback('jobbuilder:setMyJob', function(src, cb, name, grade)
    if not JB.isDev(src) then return cb(fail('Permission refusée')) end
    local xPlayer = ESX.GetPlayerFromId(src)
    local job = JB.Jobs[name]
    if not xPlayer or not job then return cb(fail('Job inconnu')) end
    grade = math.floor(num(grade, 0, #job.grades - 1, 0))
    xPlayer.setJob(name, grade)
    -- ESX applique parfois le changement avec un léger délai : on revérifie sur le joueur à jour avant de conclure à un refus
    for _ = 1, 10 do
        local cur = ESX.GetPlayerFromId(src)
        if cur and cur.job and cur.job.name == name then break end
        Wait(100)
    end
    xPlayer = ESX.GetPlayerFromId(src) or xPlayer
    if xPlayer.job.name ~= name then
        return cb(fail('ESX refuse ce job : il n\'est pas encore connu de es_extended. Ton es_extended n\'a pas ESX.RefreshJobs : fais « restart es_extended » puis réessaie.'))
    end
    cb({ ok = true })
end)

ESX.RegisterServerCallback('jobbuilder:isDev', function(src, cb) cb(JB.isDev(src)) end)

RegisterCommand(Config.Command, function(src)
    if src == 0 then return end
    if not JB.isDev(src) then
        JBNotifyClient( src, '~r~Tu n\'as pas la permission d\'utiliser le Job Builder.')
        return
    end
    TriggerClientEvent('jobbuilder:client:openBuilder', src)
end, false)

-- ─────────────────────────────── Diagnostic complet : /jbcheck (console serveur ou joueur _dev) ───────────────────────────────
-- Vérifie dépendances, tables, cohérence de chaque job du builder (jobs / grades / société / points / blip) et modules.
local function runCheck()
    local lines, bad = {}, 0
    local function ok(msg) lines[#lines + 1] = '^2✔^0 ' .. msg end
    local function warn(msg) lines[#lines + 1] = '^3⚠^0 ' .. msg bad = bad + 1 end
    local function err(msg) lines[#lines + 1] = '^1✘^0 ' .. msg bad = bad + 1 end

    for _, r in ipairs({ 'es_extended', 'oxmysql' }) do
        if GetResourceState(r) == 'started' then ok(r .. ' démarré') else err(r .. ' n\'est pas démarré') end
    end
    if GetResourceState('ox_inventory') == 'started' then ok('ox_inventory détecté (coffres, fouille, armurerie)') else warn('ox_inventory absent : coffres et fouille indisponibles (armurerie ESX en secours)') end
    if ESX.RefreshJobs then ok('ESX.RefreshJobs disponible : les jobs créés sont utilisables sans restart') else warn('ESX.RefreshJobs absent : « restart es_extended » nécessaire après création d\'un job') end
    for _, r in ipairs({ 'CorePickax', 'esx_society', 'esx_addonaccount' }) do
        if GetResourceState(r) == 'started' then
            if #Config.RestartResources == 0 then warn(r .. ' charge les jobs au démarrage : configure « Ressources à redémarrer » (Paramètres → Général) ou redémarre-la après chaque job')
            else ok(r .. ' détecté, redémarrage automatique configuré') end
        end
    end

    -- Des markers enregistrés en jeu (Paramètres) prennent le dessus sur la base commune de config.lua
    local function differs(cur, def) return cur and def and (cur.marker ~= def.marker or table.concat(cur.color or {}, ',') ~= table.concat(def.color or {}, ',')) end
    local custom = {}
    for k, v in pairs(JBGet('pointTypes')) do if differs(v, JBDefaults.pointTypes[k]) then custom[#custom + 1] = k end end
    local realCur, realDef = JBGet('real'), JBDefaults.real
    for k, v in pairs(realCur.PointTypes or {}) do if differs(v, realDef.PointTypes[k]) then custom[#custom + 1] = 'immo:' .. k end end
    for k, v in pairs(realCur.Markers or {}) do if differs(v, realDef.Markers[k]) then custom[#custom + 1] = 'porte:' .. k end end
    if #custom > 0 then
        table.sort(custom)
        warn(('markers personnalisés enregistrés en base (%s) : ils remplacent la base « type 25 / turquoise » de config.lua → Paramètres → Markers des points / Immobilier → « Réinitialiser cette section »'):format(table.concat(custom, ', ')))
    else
        ok('markers : base commune de config.lua appliquée (type 25, turquoise)')
    end

    local tables = { 'jobbuilder_jobs', 'jobbuilder_points', 'jobbuilder_logs', 'jobbuilder_settings', 'jobbuilder_properties', 'jobbuilder_property_points', 'jobbuilder_property_outfits',
        'jobbuilder_property_history', 'jobbuilder_dealer_vehicles', 'jobbuilder_dealer_sales', 'jobbuilder_treasury_log', 'jobbuilder_mission_stats', 'jobbuilder_records', 'jobbuilder_record_entries', 'jobbuilder_announces', 'jobbuilder_patients', 'jobbuilder_patient_entries', 'jobbuilder_bank_clients', 'jobbuilder_bank_entries', 'jobbuilder_bank_loans', 'jobs', 'job_grades', 'addon_account', 'addon_account_data' }
    for _, t in ipairs(tables) do
        local exists = MySQL.scalar.await('SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?', { t }) or 0
        if exists == 0 then err('table manquante : ' .. t) end
    end

    local n, pts = 0, 0
    for name, job in pairs(JB.Jobs) do
        n = n + 1
        local prefix = ('[%s] '):format(name)
        local row = MySQL.single.await('SELECT name FROM jobs WHERE name = ?', { name })
        if not row then err(prefix .. 'absent de la table jobs (ESX ne le connaît pas)') end
        local g = MySQL.scalar.await('SELECT COUNT(*) FROM job_grades WHERE job_name = ?', { name }) or 0
        if g == 0 then err(prefix .. 'aucun grade dans job_grades') elseif g ~= #job.grades then warn(prefix .. ('%d grades en base, %d attendus'):format(g, #job.grades)) end
        if job.society then
            local acc = MySQL.scalar.await('SELECT COUNT(*) FROM addon_account WHERE name = ?', { JB.societyAccount(name) }) or 0
            if acc == 0 then err(prefix .. 'compte société ' .. JB.societyAccount(name) .. ' manquant') end
        end
        local b = job.blip or {}
        if b.enabled and not (b.coords and b.coords.x) then err(prefix .. 'blip activé sans position : il ne s\'affichera pas') end
        if not Config.JobTypes[job.type] then warn(prefix .. 'type de job inconnu : ' .. tostring(job.type)) end
        local mine, hasBoss = 0, false
        for _, p in pairs(JB.Points) do
            if p.job_name == name then
                mine, pts = mine + 1, pts + 1
                if p.type == 'boss' then hasBoss = true end
                if not (p.coords and p.coords.x) then err(prefix .. ('point #%d (%s) sans position'):format(p.id, p.type)) end
                if p.min_grade > #job.grades - 1 then warn(prefix .. ('point #%d : grade min. %d inexistant'):format(p.id, p.min_grade)) end
            end
        end
        if job.society and not hasBoss then warn(prefix .. 'pas de point « Gestion boss » : personne ne pourra gérer la société en jeu') end
        local serve = false
        for _, a in ipairs(job.settings.actions or {}) do if a == 'serve' then serve = true end end
        if serve and #(job.settings.menu or {}) == 0 then warn(prefix .. 'action « Vendre un produit » activée mais carte vide (onglet Général)') end
        if job.type == 'dealer' then
            local cat = MySQL.scalar.await('SELECT COUNT(*) FROM jobbuilder_dealer_vehicles WHERE job_name = ? AND enabled = 1', { name }) or 0
            if cat == 0 then warn(prefix .. 'catalogue de véhicules vide') end
            local hasShow = false
            for _, p in pairs(JB.Points) do if p.job_name == name and p.type == 'showroom' then hasShow = true end end
            if not hasShow then warn(prefix .. 'pas de point Showroom (catalogue public + livraison)') end
        end
        if job.type == 'realestate' or job.type == 'government' then
            if job.type == 'government' and job.settings.treasury ~= false and JB.treasuryJob and JB.treasuryJob() ~= name then ok(prefix .. 'gouvernement secondaire (le trésor est ' .. tostring(JB.treasuryJob()) .. ')') end
        end
        if Config.Missions.Enabled and job.settings.missions_enabled ~= false then
            local hasM = false
            for _, p in pairs(JB.Points) do if p.job_name == name and p.type == 'missions' then hasM = true end end
            if not hasM then warn(prefix .. 'missions activées mais aucun point « Missions PNJ »') end
        end
        if not (b.enabled and b.coords) then lines[#lines + 1] = ('   ^8%sblip : aucun^0'):format(prefix) end
    end
    ok(('%d job(s) et %d point(s) du builder vérifiés'):format(n, pts))
    if n > 0 and JB.treasuryJob and not JB.treasuryJob() then
        local gov = false
        for _, j in pairs(JB.Jobs) do if j.type == 'government' then gov = true end end
        if gov then warn('aucun gouvernement ne peut servir de trésor public (compte société requis)') end
    end
    lines[#lines + 1] = bad == 0 and '^2Tout est en ordre.^0' or ('^3%d point(s) à corriger.^0'):format(bad)
    return lines
end

RegisterCommand('jbcheck', function(src)
    if src ~= 0 and not JB.isDev(src) then return end
    local lines = runCheck()
    print('^5──────── jobbuilder : diagnostic ────────^0')
    for _, l in ipairs(lines) do print(l) end
    if src ~= 0 then JBNotifyClient( src, 'Diagnostic jobbuilder affiché dans la console serveur.') end
end, false)
