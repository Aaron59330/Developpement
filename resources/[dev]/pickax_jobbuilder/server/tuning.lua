-- ─────────────────────────────── Atelier tuning (jobs mécano) ───────────────────────────────
-- Le client prévisualise sur le véhicule ; le serveur valide chaque modification (schéma strict), calcule le prix, gère la facturation
-- (client / société / gratuit) puis enregistre dans owned_vehicles UNIQUEMENT les clés payées.

local T = Config.Tuning
local function fail(msg) return { ok = false, error = msg } end

local function intIn(v, min, max)
    v = tonumber(v)
    if not v or v ~= v then return nil end
    v = math.floor(v)
    if v < min or v > max then return nil end
    return v
end

-- Valide une modification { key, value } -> valeur nettoyée ou nil
local function cleanValue(key, value)
    local k = T.Keys[key]
    if not k then return nil end
    if k.kind == 'int' then return intIn(value, k.min, k.max) end
    if k.kind == 'bool' then return value == true or value == 1 end
    if k.kind == 'rgb' then
        if type(value) ~= 'table' then return nil end
        local r, g, b = intIn(value[1], 0, 255), intIn(value[2], 0, 255), intIn(value[3], 0, 255)
        return r and g and b and { r, g, b } or nil
    end
    if k.kind == 'bool4' then
        if type(value) ~= 'table' then return nil end
        local out = {}
        for i = 1, 4 do out[i] = value[i] == true or value[i] == 1 end
        return out
    end
end

-- Catégorie de prix d'une clé ; plusieurs clés d'une même catégorie « groupée » ne sont facturées qu'une fois
local GROUP = { modFrontWheels = 'wheels', modBackWheels = 'wheels', wheels = 'wheels', neonEnabled = 'neon', neonColor = 'neon', modXenon = 'xenon', xenonColor = 'xenon',
    modSmokeEnabled = 'smoke', tyreSmokeColor = 'smoke', modLivery = 'livery', livery = 'livery', color1 = 'paint', color2 = 'paint', pearlescentColor = 'pearl', wheelColor = 'wheelColor',
    windowTint = 'tint', plateIndex = 'plate', modTurbo = 'turbo', modHorns = 'horn' }
local LEVELS = { modEngine = 'engine', modBrakes = 'brakes', modTransmission = 'transmission', modSuspension = 'suspension', modArmor = 'armor' }

local function priceOf(changes, markup)
    local total, seen, lines = 0, {}, {}
    for _, c in ipairs(changes) do
        local cat, amount = LEVELS[c.key], 0
        if cat then
            local list = T.Prices[cat] or {}
            if c.value >= 0 and #list > 0 then amount = list[math.min(c.value + 1, #list)] end
        else
            cat = GROUP[c.key] or 'cosmetic'
            if cat == 'cosmetic' then
                amount = (c.value ~= -1) and (T.Prices.cosmetic or 0) or 0
            elseif not seen[cat] then
                seen[cat] = true
                amount = T.Prices[cat] or 0
            end
            if (c.key == 'modTurbo' or c.key == 'modXenon' or c.key == 'modSmokeEnabled') and c.value == false then amount = 0 end
        end
        if amount > 0 then
            total = total + amount
            lines[#lines + 1] = { key = c.key, amount = math.floor(amount * markup / 100) }
        end
    end
    return math.floor(total * markup / 100), lines
end

local function cleanChanges(raw)
    if type(raw) ~= 'table' then return nil end
    local out, used = {}, {}
    for _, c in ipairs(raw) do
        if type(c) == 'table' and type(c.key) == 'string' and not used[c.key] and #out < 80 then
            local v = cleanValue(c.key, c.value)
            if v ~= nil then used[c.key] = true out[#out + 1] = { key = c.key, value = v } end
        end
    end
    return out
end

local function getPoint(src, pointId)
    local xPlayer = ESX.GetPlayerFromId(src)
    local point = JB.Points[tonumber(pointId)]
    if not xPlayer or not point or point.type ~= 'tuning' then return nil, nil, nil, 'Atelier introuvable' end
    if JB.distanceTo(src, point.coords) > Config.ServerDistance + (point.data.radius or T.Radius) then return nil, nil, nil, 'Tu es trop loin de l\'atelier' end
    local job = JB.Jobs[point.job_name]
    if xPlayer.job.name ~= point.job_name or not job then return nil, nil, nil, 'Cet atelier n\'appartient pas à ton métier' end
    if xPlayer.job.grade < point.min_grade or xPlayer.job.grade < (job.settings.tuning_grade or 0) then return nil, nil, nil, 'Ton grade ne permet pas d\'utiliser l\'atelier' end
    return point, xPlayer, job
end

-- Ouverture : le client reçoit prix, majoration et mode de facturation
function JB.openTuning(src, xPlayer, point, job, cb)
    local s = job.settings or {}
    cb({ ok = true, kind = 'tuning', label = point.label, jobLabel = job.label, radius = point.data.radius or T.Radius,
        prices = T.Prices, markup = s.tuning_markup or 100, billing = s.tuning_billing or 'customer' })
end

-- ─────────────────────────────── Persistance (owned_vehicles) ───────────────────────────────
local function persist(plate, changes)
    local D = Config.Dealer
    local col = D.Cols.vehicle
    if not col or col == '' or not D.Cols.plate or D.Cols.plate == '' then return false end
    local row = MySQL.single.await(('SELECT `%s` AS props FROM `%s` WHERE TRIM(`%s`) = TRIM(?) LIMIT 1'):format(col, D.Table, D.Cols.plate), { plate })
    if not row then return false end
    local props = JB.decode(row.props, {})
    if type(props) ~= 'table' then props = {} end
    for _, c in ipairs(changes) do props[c.key] = c.value end
    MySQL.update.await(('UPDATE `%s` SET `%s` = ? WHERE TRIM(`%s`) = TRIM(?)'):format(D.Table, col, D.Cols.plate), { json.encode(props), plate })
    return true
end

local function cleanPlate(p)
    p = type(p) == 'string' and p:gsub('%c', ''):sub(1, 12) or ''
    return p
end

-- (pointId, client proche [injecté], plaque, modifications)
ESX.RegisterServerCallback('jobbuilder:tuning:validate', function(src, cb, pointId, targetId, plate, raw)
    local point, x, job, err = getPoint(src, pointId)
    if not point then return cb(fail(err)) end
    local changes = cleanChanges(raw)
    plate = cleanPlate(plate)
    if not changes or #changes == 0 then return cb(fail('Aucune modification à appliquer')) end
    if plate == '' then return cb(fail('Véhicule inconnu')) end
    local s = job.settings or {}
    local total = priceOf(changes, s.tuning_markup or 100)
    local mode = s.tuning_billing or 'customer'
    local label = ('Customisation véhicule %s'):format(plate)

    local function finish(extra)
        local saved = persist(plate, changes)
        JB.log(job.name, x, 'tuning', ('%s : %d modif(s), %d$ [%s]%s'):format(plate, #changes, total, mode, saved and '' or ' (non enregistré)'))
        return saved
    end

    if total <= 0 or mode == 'free' then
        local saved = finish()
        return cb({ ok = true, total = total, mode = 'free', saved = saved })
    end

    if mode == 'society' then
        if not job.society then return cb(fail('Ce job n\'a pas de compte société')) end
        if not JB.societyRemove(job.name, total) then return cb(fail(('La société n\'a pas les %d $ nécessaires'):format(total))) end
        local saved = finish()
        return cb({ ok = true, total = total, mode = 'society', saved = saved })
    end

    -- Facturation au client le plus proche : appliqué (enregistré) une fois payé
    local target = ESX.GetPlayerFromId(tonumber(targetId))
    if not target or target.source == src then return cb(fail('Aucun client à proximité à facturer')) end
    if not JB.playersClose(src, target.source) then return cb(fail('Le client est trop loin')) end
    local settled = false
    JB.sendInvoice(x, target, label, total, nil, {
        onPaid = function()
            settled = true
            local saved = finish()
            TriggerClientEvent('jobbuilder:client:tuningResult', src, { ok = true, msg = saved and 'Facture payée : modifications enregistrées.' or 'Facture payée (véhicule non enregistré en base : modifications visuelles).' })
        end,
        onRefused = function(why)
            settled = true
            TriggerClientEvent('jobbuilder:client:tuningResult', src, { ok = false, msg = why == 'unpaid' and 'Le client n\'a pas assez d\'argent : modifications annulées.' or 'Le client a refusé : modifications annulées.' })
        end,
    })
    SetTimeout(70000, function()      -- la facture expire au bout de 60 s : on libère le mécanicien
        if not settled then
            settled = true
            TriggerClientEvent('jobbuilder:client:tuningResult', src, { ok = false, msg = 'Facture expirée : modifications annulées.' })
        end
    end)
    cb({ ok = true, waiting = true, total = total, mode = 'customer' })
end)
