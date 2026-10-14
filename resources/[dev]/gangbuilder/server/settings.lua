-- ─────────────────────────────── Paramètres modifiables en jeu (réservé aux groupes autorisés) ───────────────────────────────
-- Les sections « Schema » (config.lua) sont validées champ par champ (type, min, max), stockées en base (gangbuilder_settings),
-- appliquées à Config en place côté serveur puis diffusées à tous les clients. Les sections « markers » et « modèles de gangs » ont leur validation dédiée.

local function fail(msg) return { ok = false, error = msg } end

local function num(v, min, max, default)
    v = tonumber(v)
    if not v or v ~= v then return default end
    if min and v < min then v = min end
    if max and v > max then v = max end
    return v
end
local function int(v, min, max, default) local n = num(v, min, max, default) return n and math.floor(n) or default end
local function str(v, max, default)
    if type(v) ~= 'string' then return default or '' end
    return (v:gsub('%c', '')):sub(1, max or 100)
end
local function color(c, default)
    if type(c) ~= 'table' then return default end
    return { int(c[1], 0, 255, default[1]), int(c[2], 0, 255, default[2]), int(c[3], 0, 255, default[3]) }
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

local PROTECTED = { es_extended = true, oxmysql = true, gangbuilder = true, jobbuilder = true, ox_lib = true, ox_inventory = true, ['mysql-async'] = true, ghmattimysql = true, monitor = true, sessionmanager = true }

-- Validation d'un champ du Schema : renvoie la valeur propre, ou nil + message
local function cleanField(f, v, src)
    local cur = GBGetPath(f.key)
    if f.t == 'int' then return int(v, f.min, f.max, cur)
    elseif f.t == 'num' then return num(v, f.min, f.max, cur)
    elseif f.t == 'bool' then return v == true
    elseif f.t == 'str' then return str(v, f.max or 100, '')
    elseif f.t == 'color' then return color(v, cur or { 255, 255, 255 })
    elseif f.t == 'enum' then
        for _, o in ipairs(f.opts or {}) do if o[1] == v then return v end end
        return cur
    elseif f.t == 'list' then
        local out = {}
        for _, x in ipairs(type(v) == 'table' and v or {}) do
            x = str(tostring(x), 80):gsub('%s', '')
            if x ~= '' then
                if f.pat and not x:match(f.pat) then return nil, ('« %s » n\'est pas valide pour « %s »'):format(x, f.label) end
                if f.key == 'RestartResources' and PROTECTED[x] then return nil, ('« %s » est protégée : elle ne peut pas être redémarrée automatiquement'):format(x) end
                if #out < (f.max or 20) then out[#out + 1] = x end
            end
        end
        if f.key == 'AllowedGroups' then
            if #out == 0 then return nil, 'Il faut au moins un groupe autorisé' end
            -- Garde-fou : on ne peut pas se retirer l'accès à soi-même
            local x = src and src ~= 0 and ESX.GetPlayerFromId(src)
            if x then
                local keep = false
                for _, g in ipairs(out) do if x.getGroup() == g then keep = true end end
                if not keep and not (Config.AcePermission ~= '' and IsPlayerAceAllowed(src, Config.AcePermission)) then
                    return nil, ('Tu t\'enlèverais l\'accès à toi-même : garde ton groupe (%s) dans la liste'):format(x.getGroup())
                end
            end
        end
        return out
    end
    return cur
end

local function cleanSchemaSection(section, v, src)
    if type(v) ~= 'table' then return nil, 'Données invalides' end
    local out = {}
    for _, sec in ipairs(Config.Schema) do
        if sec.id == section then
            for _, f in ipairs(sec.fields) do
                local val, err = cleanField(f, v[f.key], src)
                if err then return nil, err end
                out[f.key] = val
            end
        end
    end
    -- cohérence entre champs
    if out['Activities.LaunderMin'] and out['Activities.LaunderMax'] and out['Activities.LaunderMin'] > out['Activities.LaunderMax'] then
        out['Activities.LaunderMax'] = out['Activities.LaunderMin']
    end
    if out['Territories.DefaultRadius'] and out['Territories.MaxRadius'] and out['Territories.DefaultRadius'] > out['Territories.MaxRadius'] then
        out['Territories.MaxRadius'] = out['Territories.DefaultRadius']
    end
    return out
end

local function cleanPointTypes(v)
    if type(v) ~= 'table' then return nil, 'Données invalides' end
    local out = {}
    for key, base in pairs(Config.PointTypes) do          -- on ne peut pas ajouter de nouveaux types (code), seulement modifier
        local d = type(v[key]) == 'table' and v[key] or {}
        out[key] = markerDef(d, base)
        out[key].label = str(d.label, 40, base.label)
        if out[key].label == '' then out[key].label = base.label end
        out[key].hidden = base.hidden
    end
    return out
end

local function cleanGangTypes(v)
    if type(v) ~= 'table' then return nil, 'Données invalides' end
    local out, n = {}, 0
    for key, t in pairs(v) do
        key = tostring(key)
        if not key:match('^[a-z0-9_]+$') or #key < 2 or #key > 20 then return nil, ('Clé de modèle invalide : « %s » (a-z, 0-9, _ ; 2-20 car.)'):format(key) end
        if type(t) ~= 'table' then return nil, 'Données invalides' end
        local blip = type(t.blip) == 'table' and t.blip or {}
        local entry = {
            label = str(t.label, 40, key),
            color = (type(t.color) == 'string' and t.color:match('^#%x%x%x%x%x%x$')) and t.color:lower() or '#ef4444',
            blip = { sprite = int(blip.sprite, 0, 900, 310), color = int(blip.color, 0, 85, 0), scale = num(blip.scale, 0.3, 2, 0.9) },
            actions = {}, points = {}, grades = {},
        }
        for _, a in ipairs(type(t.actions) == 'table' and t.actions or {}) do
            if Config.Actions[a] and a ~= 'info' and a ~= 'leave' then entry.actions[#entry.actions + 1] = a end
        end
        for _, p in ipairs(type(t.points) == 'table' and t.points or {}) do
            if Config.PointTypes[p] and not Config.PointTypes[p].hidden then entry.points[#entry.points + 1] = p end
        end
        for i, g in ipairs(type(t.grades) == 'table' and t.grades or {}) do
            if #entry.grades >= Config.MaxGrades then break end
            local gname = str(type(g) == 'table' and g.name or '', 40):lower():gsub('[^%w_]', '_')
            if gname == '' then gname = 'grade' .. (i - 1) end
            entry.grades[#entry.grades + 1] = { name = gname, label = str(type(g) == 'table' and g.label or '', 50, gname), salary = int(type(g) == 'table' and g.salary, 0, 1000000, 0) }
        end
        if #entry.grades == 0 then return nil, ('Modèle « %s » : il faut au moins un grade'):format(key) end
        out[key] = entry
        n = n + 1
    end
    if n == 0 then return nil, 'Il faut au moins un modèle de gang' end
    for name, gang in pairs(GB.Gangs) do
        if not out[gang.type] then return nil, ('Le modèle « %s » est utilisé par le gang « %s » : il ne peut pas être supprimé'):format(gang.type, name) end
    end
    return out
end

local function clean(section, v, src)
    if section == 'pointTypes' then return cleanPointTypes(v) end
    if section == 'gangTypes' then return cleanGangTypes(v) end
    return cleanSchemaSection(section, v, src)
end

local function isSection(s)
    for _, id in ipairs(GB_SECTIONS) do if id == s then return true end end
    return false
end

local function allValues()
    local values = {}
    for _, id in ipairs(GB_SECTIONS) do values[id] = GBGet(id) end
    return values
end

local function broadcast()
    TriggerClientEvent('gangbuilder:client:config', -1, GB.configSnapshot())
    if GB.syncTerritories then GB.syncTerritories() end
end

ESX.RegisterServerCallback('gangbuilder:settings:get', function(src, cb)
    if not GB.isDev(src) then return cb(fail('Permission refusée')) end
    cb({ ok = true, values = allValues(), defaults = GBDefaults, schema = Config.Schema, custom = Config.CustomSections })
end)

ESX.RegisterServerCallback('gangbuilder:settings:save', function(src, cb, section, value)
    if not GB.isDev(src) then return cb(fail('Permission refusée')) end
    if not isSection(section) then return cb(fail('Section inconnue')) end
    local out, err = clean(section, value, src)
    if not out then return cb(fail(err)) end
    GBSet(section, out)
    local xPlayer = ESX.GetPlayerFromId(src)
    MySQL.update.await('INSERT INTO gangbuilder_settings (name, value, updated_by) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE value = VALUES(value), updated_by = VALUES(updated_by)',
        { section, json.encode(out), xPlayer and GB.playerName(xPlayer) or 'console' })
    GB.log('_settings', xPlayer, 'settings_saved', section)
    broadcast()
    cb({ ok = true, value = GBGet(section) })
end)

ESX.RegisterServerCallback('gangbuilder:settings:reset', function(src, cb, section)
    if not GB.isDev(src) then return cb(fail('Permission refusée')) end
    if not isSection(section) then return cb(fail('Section inconnue')) end
    if section == 'gangTypes' then
        -- on ne supprime pas un modèle utilisé : cleanGangTypes vérifie
        local _, err = cleanGangTypes(GBDefaults.gangTypes)
        if err then return cb(fail(err)) end
    end
    if section == 'general' then
        -- garde-fou : revenir aux défauts ne doit pas retirer l'accès à celui qui clique
        local x = ESX.GetPlayerFromId(src)
        local ok = false
        for _, g in ipairs(GBDefaults.general.AllowedGroups or {}) do if x and x.getGroup() == g then ok = true end end
        if not ok and not (Config.AcePermission ~= '' and IsPlayerAceAllowed(src, Config.AcePermission)) then
            return cb(fail('Réinitialiser retirerait ton accès : ton groupe n\'est pas dans la liste par défaut de config.lua'))
        end
    end
    GBSet(section, GBDeepCopy(GBDefaults[section]))
    MySQL.update.await('DELETE FROM gangbuilder_settings WHERE name = ?', { section })
    GB.log('_settings', ESX.GetPlayerFromId(src), 'settings_reset', section)
    broadcast()
    cb({ ok = true, value = GBGet(section) })
end)

-- Chargement des réglages enregistrés au démarrage
CreateThread(function()
    while not GB.ready do Wait(100) end
    local rows = MySQL.query.await('SELECT name, value FROM gangbuilder_settings') or {}
    local n = 0
    for _, r in ipairs(rows) do
        if isSection(r.name) then
            local v = GB.decode(r.value, nil)
            local out = v and clean(r.name, v, nil)
            if out then GBSet(r.name, out) n = n + 1
            else print(('^3[gangbuilder] réglages « %s » invalides en base : ignorés (valeurs de config.lua utilisées).^0'):format(r.name)) end
        end
    end
    if n > 0 then
        print(('^2[gangbuilder] %d section(s) de réglages chargée(s) depuis la base (Paramètres en jeu).^0'):format(n))
        for _, p in pairs(GB.Points) do GB.registerStash(p) end
        GB.syncAll()
    end
end)
