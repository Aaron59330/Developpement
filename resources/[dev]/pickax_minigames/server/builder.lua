-- Validation / assainissement des définitions de mini-jeux envoyées par l'éditeur

local function str(v, max, def)
    if type(v) ~= 'string' then return def or '' end
    v = v:gsub('[\0-\8\11\12\14-\31]', ''):sub(1, max or 80)
    return v
end

local function num(v, min, max, def)
    v = tonumber(v)
    if not v or v ~= v or v == math.huge or v == -math.huge then v = def or 0 end
    if min and v < min then v = min end
    if max and v > max then v = max end
    return v
end

local function coords(c, r)
    if type(c) ~= 'table' then return nil end
    local x, y, z = tonumber(c.x), tonumber(c.y), tonumber(c.z)
    if not x or not y or not z then return nil end
    local o = { x = x + 0.0, y = y + 0.0, z = z + 0.0, h = num(c.h, 0, 360, 0) + 0.0 }
    return o
end

local function slug(s)
    s = (s or ''):lower():gsub('[^%w]+', '-'):gsub('^-+', ''):gsub('-+$', '')
    return s:sub(1, 24)
end

local function fieldValue(f, v)
    if f.kind == 'number' then
        return num(v, f.min, f.max, f.def)
    elseif f.kind == 'bool' then
        return v == true
    elseif f.kind == 'select' then
        v = tostring(v)
        for _, o in ipairs(f.options or {}) do if o[1] == v then return v end end
        return tostring(f.def)
    elseif f.kind == 'weapon' then
        v = tostring(v or '')
        for _, w in ipairs(Config.Weapons) do if w[1] == v then return v end end
        if v:match('^WEAPON_[A-Z0-9_]+$') then return v end
        return f.def
    elseif f.kind == 'model' then
        v = tostring(v or '')
        if v == '' then return '' end
        if v:match('^[%w_]+$') then return v:sub(1, 48) end
        return f.def
    end
    return f.def
end

function MG.sanitize(d, existingId)
    if type(d) ~= 'table' then return nil, 'Données invalides' end
    local T = Config.Types[d.type]
    if not T then return nil, 'Type de mini-jeu inconnu' end

    local name = str(d.name, 40)
    if #name < 2 then return nil, 'Donne un nom au mini-jeu (2 caractères minimum)' end

    local out = {
        type = d.type,
        name = name,
        description = str(d.description, 220),
        enabled = d.enabled == true,
        blip = { enabled = not (type(d.blip) == 'table' and d.blip.enabled == false),
                 sprite = math.floor(num(type(d.blip) == 'table' and d.blip.sprite, 1, 900, 0)),
                 color = math.floor(num(type(d.blip) == 'table' and d.blip.color, 0, 85, 3)) },
        settings = {},
        points = {},
    }
    if out.blip.sprite == 0 then
        local def = { basket = 357, football = 357, tennis = 357, boxing = 311, paintball = 110, lasertag = 110, race = 315 }
        out.blip.sprite = def[d.type] or 357
    end

    local s = type(d.settings) == 'table' and d.settings or {}
    for _, f in ipairs(Config.Common) do out.settings[f.key] = fieldValue(f, s[f.key]) end
    for _, f in ipairs(T.fields) do out.settings[f.key] = fieldValue(f, s[f.key]) end
    if out.settings.maxPlayers < out.settings.minPlayers then out.settings.maxPlayers = out.settings.minPlayers end
    if T.engine == 'fight' then out.settings.maxPlayers = math.min(out.settings.maxPlayers, 2); out.settings.minPlayers = math.max(out.settings.minPlayers, 2) end
    if T.engine == 'fight' and out.settings.damageMax < out.settings.damageMin then out.settings.damageMax = out.settings.damageMin end

    local p = type(d.points) == 'table' and d.points or {}
    for _, pt in ipairs(T.points) do
        local src = p[pt.key]
        if pt.single then
            out.points[pt.key] = coords(src)
        else
            local list = {}
            if type(src) == 'table' then
                for i, e in ipairs(src) do
                    if i > (pt.max or 12) then break end
                    local c = coords(e)
                    if c then
                        if pt.team then c.team = math.floor(num(e.team, 1, 2, 1)) end
                        if pt.radius then c.r = num(e.r, 0.3, 60, 3) end
                        if pt.pts then c.pts = math.floor(num(e.pts, 0, 1000, 10)) end
                        list[#list + 1] = c
                    end
                end
            end
            out.points[pt.key] = list
        end
    end

    local id = existingId
    if not id then
        id = slug(name)
        if id == '' then id = 'jeu' end
        local base, n = id, 1
        while MG.Defs[id] do n = n + 1; id = base .. '-' .. n end
    end
    out.id = id
    return out
end

-- Contrôle de complétude : renvoie la liste des problèmes qui empêchent l'activation
function MG.problems(d)
    local T = Config.Types[d.type]
    local list = {}
    if not T then return { 'Type inconnu' } end
    for _, pt in ipairs(T.points) do
        local v = d.points[pt.key]
        if pt.single then
            if not v then list[#list + 1] = 'Point manquant : ' .. pt.label end
        elseif not v or #v == 0 then
            list[#list + 1] = 'Point manquant : ' .. pt.label
        end
    end
    if T.engine == 'tag' and tonumber(d.settings.teams) == 2 then
        local a, b = 0, 0
        for _, s in ipairs(d.points.spawns or {}) do if s.team == 2 then b = b + 1 else a = a + 1 end end
        if a == 0 or b == 0 then list[#list + 1] = 'Mode équipes : place des points d\'apparition pour chaque équipe' end
    end
    if T.engine == 'fight' and #(d.points.spawns or {}) < 2 then list[#list + 1] = 'Boxe : 2 coins de ring sont nécessaires' end
    return list
end

local function cbAdmin(name, fn)
    ESX.RegisterServerCallback('minigames:' .. name, function(src, cb, ...)
        if not MG.isAdmin(src) then return cb({ ok = false, error = 'Accès refusé' }) end
        local ok, res = pcall(fn, src, ...)
        if not ok then print('^1[minigames]^7 ' .. name .. ' : ' .. tostring(res)); return cb({ ok = false, error = 'Erreur serveur' }) end
        cb(res)
    end)
end

ESX.RegisterServerCallback('minigames:isAdmin', function(src, cb) cb(MG.isAdmin(src)) end)

local function summary(d)
    local g = MG.Games[d.id]
    local n = 0
    if g then for _ in pairs(g.players) do n = n + 1 end end
    return { id = d.id, name = d.name, type = d.type, enabled = d.enabled, state = g and g.state or 'idle', players = n,
             problems = MG.problems(d) }
end

cbAdmin('catalog', function()
    local types = {}
    for _, key in ipairs(Config.TypeOrder) do
        local T = Config.Types[key]
        if T then types[#types + 1] = { key = key, label = T.label, icon = T.icon, engine = T.engine, desc = T.desc, fields = T.fields, points = T.points, templates = T.templates } end
    end
    return { ok = true, types = types, common = Config.Common, weapons = Config.Weapons, currency = Config.Currency, teamColors = Config.TeamColors }
end)

cbAdmin('list', function()
    local list = {}
    for _, d in pairs(MG.Defs) do list[#list + 1] = summary(d) end
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    return { ok = true, list = list }
end)

cbAdmin('get', function(_, id)
    local d = MG.Defs[tostring(id)]
    if not d then return { ok = false, error = 'Mini-jeu introuvable' } end
    return { ok = true, def = d }
end)

-- Définition vierge pré-remplie (type + modèle)
cbAdmin('draft', function(_, typ, tpl)
    local T = Config.Types[tostring(typ)]
    if not T then return { ok = false, error = 'Type inconnu' } end
    local s = {}
    for _, f in ipairs(Config.Common) do s[f.key] = f.def end
    for _, f in ipairs(T.fields) do s[f.key] = f.def end
    local name = T.label
    local desc = ''
    for _, t in ipairs(T.templates or {}) do
        if t.id == tpl then
            for k, v in pairs(t.settings) do s[k] = v end
            name = t.label; desc = t.desc
        end
    end
    local points = {}
    for _, pt in ipairs(T.points) do points[pt.key] = pt.single and false or {} end
    return { ok = true, def = { type = typ, name = name, description = desc, enabled = false, settings = s, points = points,
                                blip = { enabled = true, sprite = 0, color = 3 } } }
end)

local function persist(d)
    MySQL.insert.await('INSERT INTO minigames_defs (id, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)', { d.id, json.encode(d) })
end

cbAdmin('save', function(src, def, id)
    id = (id and id ~= 0 and id ~= '') and tostring(id) or nil
    if id and not MG.Defs[id] then return { ok = false, error = 'Mini-jeu introuvable' } end
    local d, err = MG.sanitize(def, id)
    if not d then return { ok = false, error = err } end
    if d.enabled then
        local pr = MG.problems(d)
        if #pr > 0 then d.enabled = false end
    end
    local g = MG.Games[d.id]
    if g and g.state ~= 'waiting' and g.state ~= 'idle' then return { ok = false, error = 'Une partie est en cours : impossible de modifier maintenant' } end
    if g then MG.closeGame(d.id, 'Mini-jeu modifié par l\'équipe') end
    persist(d)
    MG.Defs[d.id] = d
    MG.sync()
    MG.log(src, id and 'modification' or 'création', d.id, d.name)
    return { ok = true, id = d.id, enabled = d.enabled, problems = MG.problems(d) }
end)

cbAdmin('toggle', function(src, id, state)
    local d = MG.Defs[tostring(id)]
    if not d then return { ok = false, error = 'Mini-jeu introuvable' } end
    state = state == true
    if state then
        local pr = MG.problems(d)
        if #pr > 0 then return { ok = false, error = pr[1] } end
    elseif MG.Games[d.id] then
        MG.closeGame(d.id, 'Mini-jeu désactivé')
    end
    d.enabled = state
    persist(d)
    MG.sync()
    MG.log(src, state and 'activation' or 'désactivation', d.id, d.name)
    return { ok = true, enabled = d.enabled }
end)

cbAdmin('duplicate', function(src, id)
    local d = MG.Defs[tostring(id)]
    if not d then return { ok = false, error = 'Mini-jeu introuvable' } end
    local copy = json.decode(json.encode(d))
    copy.name = (d.name .. ' (copie)'):sub(1, 40)
    copy.enabled = false
    local n, err = MG.sanitize(copy)
    if not n then return { ok = false, error = err } end
    persist(n)
    MG.Defs[n.id] = n
    MG.sync()
    MG.log(src, 'duplication', n.id, d.id)
    return { ok = true, id = n.id }
end)

cbAdmin('delete', function(src, id)
    id = tostring(id)
    local d = MG.Defs[id]
    if not d then return { ok = false, error = 'Mini-jeu introuvable' } end
    if MG.Games[id] then MG.closeGame(id, 'Mini-jeu supprimé') end
    MySQL.update.await('DELETE FROM minigames_defs WHERE id = ?', { id })
    MySQL.update.await('DELETE FROM minigames_stats WHERE game_id = ?', { id })
    MG.Defs[id] = nil
    MG.sync()
    MG.log(src, 'suppression', id, d.name)
    return { ok = true }
end)

cbAdmin('resetStats', function(src, id)
    id = tostring(id)
    if not MG.Defs[id] then return { ok = false, error = 'Mini-jeu introuvable' } end
    MySQL.update.await('DELETE FROM minigames_stats WHERE game_id = ?', { id })
    MG.log(src, 'reset classement', id, '')
    return { ok = true }
end)

cbAdmin('logs', function()
    local rows = MySQL.query.await('SELECT UNIX_TIMESTAMP(created) AS t, actor, action, game_id, details FROM minigames_logs ORDER BY id DESC LIMIT ?', { Config.LogLimit }) or {}
    return { ok = true, logs = rows }
end)

cbAdmin('stats', function(_, id)
    return { ok = true, top = MG.top(tostring(id)) }
end)

