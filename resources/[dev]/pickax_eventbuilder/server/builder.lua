-- ─────────────────────────────── Validation ───────────────────────────────
local function fail(msg) return { ok = false, error = msg } end

local function str(v, max, default)
    v = tostring(v == nil and (default or '') or v):gsub('[%c]', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    return v:sub(1, max or 60)
end
local function num(v, lo, hi, default)
    v = tonumber(v)
    if not v then return default end
    return math.max(lo, math.min(hi, v))
end
local function int(v, lo, hi, default)
    local n = num(v, lo, hi, default)
    return n and math.floor(n + 0.5) or default
end
local function flag(v, default)
    if v == nil then return default end
    return v == true or v == 1 or v == '1'
end

local ACCOUNTS = { money = true, bank = true, black_money = true }

local function cleanCoords(c)
    if type(c) ~= 'table' then return nil end
    local x, y, z = tonumber(c.x), tonumber(c.y), tonumber(c.z)
    if not x or not y or not z then return nil end
    return { x = x + 0.0, y = y + 0.0, z = z + 0.0, h = (tonumber(c.h) or 0.0) + 0.0, label = str(c.label, 40) }
end

local function cleanReward(r, base)
    r = type(r) == 'table' and r or {}
    local kind = r.kind == 'items' and 'items' or 'account'
    local out = { kind = kind }
    if kind == 'account' then
        out.account = ACCOUNTS[r.account] and r.account or (base and base.account) or 'black_money'
        out.min = int(r.min, 0, 10000000, (base and base.min) or 500)
        out.max = int(r.max, out.min, 10000000, math.max(out.min, (base and base.max) or out.min))
    else
        out.items = {}
        for _, it in ipairs(type(r.items) == 'table' and r.items or {}) do
            local name = str(it.name, 50):gsub('[^%w_%-%.]', '')
            if name ~= '' and #out.items < 20 then
                local mn = int(it.min, 1, 1000, 1)
                out.items[#out.items + 1] = { name = name, min = mn, max = int(it.max, mn, 1000, mn), chance = int(it.chance, 1, 100, 100) }
            end
        end
        if #out.items == 0 then return nil, 'Récompense : ajoute au moins un objet' end
    end
    return out
end

-- Nettoie une définition envoyée par l'éditeur. `isNew` : le nom technique est choisi à la création.
local function clean(d, isNew)
    if type(d) ~= 'table' then return nil, 'Données invalides' end
    local T = Config.Types[d.type]
    if not T then return nil, 'Type d\'événement inconnu' end
    local out = { type = d.type }
    out.label = str(d.label, 60)
    if out.label == '' then return nil, 'Donne un nom à l\'événement' end
    if isNew then
        out.name = str(d.name, 40):lower():gsub('[^a-z0-9_]', '')
        if #out.name < 3 then out.name = (d.type .. '_' .. math.random(1000, 9999)) end
    end
    out.enabled = flag(d.enabled, true)
    out.trigger = (d.trigger == 'auto' or d.trigger == 'manual' or d.trigger == 'interact') and d.trigger or T.trigger or 'manual'
    if T.trigger == 'interact' and out.trigger == 'auto' then out.trigger = 'interact' end      -- un commerce se braque en interagissant
    out.cooldown = int(d.cooldown, 0, 1440, T.cooldown or 60)
    out.duration = int(d.duration, 1, 240, T.duration or 20)
    out.minPolice = int(d.minPolice, 0, 30, T.minPolice or 0)
    out.minPlayers = int(d.minPlayers, 0, 200, 0)

    out.locations = {}
    for _, c in ipairs(type(d.locations) == 'table' and d.locations or {}) do
        local cc = cleanCoords(c)
        if cc and #out.locations < 20 then out.locations[#out.locations + 1] = cc end
    end
    if #out.locations == 0 then return nil, 'Ajoute au moins un lieu (bouton « Ma position »)' end

    out.params = {}
    local p = type(d.params) == 'table' and d.params or {}
    for _, f in ipairs(T.fields) do
        local v = p[f.key]
        if f.kind == 'number' then
            out.params[f.key] = num(v, f.min or -1e9, f.max or 1e9, f.default)
        elseif f.kind == 'bool' then
            out.params[f.key] = flag(v, f.default)
        elseif f.kind == 'select' then
            local pick = f.default
            for _, o in ipairs(f.options or {}) do if o[1] == v then pick = v end end
            out.params[f.key] = pick
        else
            local s = str(v, 80, f.default)
            if f.kind == 'model' and (s == '' or not s:match('^[%w_]+$')) then s = f.default end
            if f.key == 'guardWeapon' and not s:match('^[%w_]+$') then s = f.default end
            out.params[f.key] = s
        end
    end
    if T.needsDest and (out.params.destX == 0 and out.params.destY == 0) then return nil, 'Définis la destination (bouton « Ma position » dans Paramètres)' end

    local reward, rerr = cleanReward(d.reward, T.reward)
    if not reward then return nil, rerr end
    out.reward = reward

    local a = type(d.alert) == 'table' and d.alert or {}
    out.alert = { enabled = flag(a.enabled, Config.Defaults.alert.enabled), delay = int(a.delay, 0, 300, Config.Defaults.alert.delay), message = str(a.message, 100, Config.Defaults.alert.message) }
    local b = type(d.blip) == 'table' and d.blip or {}
    local B = Config.Defaults.blip
    out.blip = { enabled = flag(b.enabled, B.enabled), sprite = int(b.sprite, 0, 900, B.sprite), color = int(b.color, 0, 85, B.color),
        scale = num(b.scale, 0.3, 2.0, B.scale), radius = num(b.radius, 0, 500, B.radius), flash = flag(b.flash, B.flash) }
    local an = type(d.announce) == 'table' and d.announce or {}
    out.announce = { start = str(an.start, 140), finish = str(an.finish, 140) }
    return out
end

local function summary(d)
    local T = Config.Types[d.type] or {}
    local running = false
    for _, run in pairs(EB.Active) do if run.defId == d.id then running = true break end end
    local cd = 0
    if EB.LastEnd[d.id] then cd = math.max(0, (EB.LastEnd[d.id] + (d.cooldown or 0) * 60) - os.time()) end
    return { id = d.id, name = d.name, label = d.label, type = d.type, typeLabel = T.label, icon = T.icon, enabled = d.enabled, trigger = d.trigger,
        cooldown = d.cooldown, minPolice = d.minPolice, locations = #(d.locations or {}), running = running, cooldownLeft = cd }
end

local function needAdmin(src, cb)
    if EB.isAdmin(src) then return true end
    cb(fail('Accès refusé'))
    return false
end

-- ─────────────────────────────── Callbacks de l'éditeur ───────────────────────────────
ESX.RegisterServerCallback('eventbuilder:isAdmin', function(src, cb) cb(EB.isAdmin(src)) end)

ESX.RegisterServerCallback('eventbuilder:catalog', function(src, cb)
    if not needAdmin(src, cb) then return end
    local types = {}
    for id, T in pairs(Config.Types) do
        types[id] = { id = id, label = T.label, icon = T.icon, desc = T.desc, fields = T.fields, reward = T.reward, duration = T.duration, cooldown = T.cooldown,
            minPolice = T.minPolice, trigger = T.trigger, needsDest = T.needsDest == true }
    end
    cb({ ok = true, types = types, templates = Config.Templates, defaults = Config.Defaults, currency = Config.Currency, policeJobs = Config.PoliceJobs })
end)

ESX.RegisterServerCallback('eventbuilder:list', function(src, cb)
    if not needAdmin(src, cb) then return end
    local list = {}
    for _, d in pairs(EB.Defs) do list[#list + 1] = summary(d) end
    table.sort(list, function(a, b) return a.label:lower() < b.label:lower() end)
    cb({ ok = true, list = list })
end)

ESX.RegisterServerCallback('eventbuilder:get', function(src, cb, id)
    if not needAdmin(src, cb) then return end
    local d = EB.Defs[tonumber(id)]
    if not d then return cb(fail('Événement introuvable')) end
    cb({ ok = true, event = EB.copy(d) })
end)

-- Nouveau brouillon à partir d'un modèle : valeurs du type + surcharges du modèle (rien n'est enregistré avant « Enregistrer »)
ESX.RegisterServerCallback('eventbuilder:draft', function(src, cb, templateId)
    if not needAdmin(src, cb) then return end
    local tpl
    for _, t in ipairs(Config.Templates) do if t.id == templateId then tpl = t end end
    if not tpl then return cb(fail('Modèle inconnu')) end
    local T = Config.Types[tpl.type]
    local d = { type = tpl.type, label = tpl.label, name = '', enabled = true, trigger = T.trigger, cooldown = T.cooldown, duration = T.duration,
        minPolice = tpl.minPolice or T.minPolice or 0, minPlayers = 0, locations = {}, params = {},
        reward = EB.copy(T.reward), alert = EB.copy(Config.Defaults.alert), blip = EB.copy(Config.Defaults.blip), announce = { start = '', finish = '' } }
    for _, f in ipairs(T.fields) do d.params[f.key] = f.default end
    for k, v in pairs(tpl.params or {}) do d.params[k] = v end
    if tpl.reward then for k, v in pairs(tpl.reward) do d.reward[k] = v end end
    if tpl.announce then d.announce = EB.copy(tpl.announce) d.announce.finish = d.announce.finish or '' end
    cb({ ok = true, event = d })
end)

ESX.RegisterServerCallback('eventbuilder:create', function(src, cb, d)
    if not needAdmin(src, cb) then return end
    local out, err = clean(d, true)
    if not out then return cb(fail(err)) end
    if EB.ByName[out.name] then out.name = out.name .. '_' .. math.random(100, 999) end
    local xPlayer = ESX.GetPlayerFromId(src)
    local data = EB.copy(out)
    data.name, data.label, data.type, data.enabled = nil, nil, nil, nil
    local id = MySQL.insert.await('INSERT INTO eventbuilder_events (name, label, type, enabled, data, created_by) VALUES (?, ?, ?, ?, ?, ?)',
        { out.name, out.label, out.type, out.enabled and 1 or 0, json.encode(data), xPlayer and xPlayer.identifier or nil })
    if not id then return cb(fail('Erreur base de données')) end
    out.id = id
    EB.Defs[id], EB.ByName[out.name] = out, id
    EB.log(out, xPlayer, 'create', out.label)
    TriggerEvent('eventbuilder:internal:defsChanged')
    cb({ ok = true, id = id })
end)

ESX.RegisterServerCallback('eventbuilder:save', function(src, cb, id, d)
    if not needAdmin(src, cb) then return end
    local cur = EB.Defs[tonumber(id)]
    if not cur then return cb(fail('Événement introuvable')) end
    d = type(d) == 'table' and d or {}
    d.type = cur.type                                   -- le type ne change pas après création
    local out, err = clean(d, false)
    if not out then return cb(fail(err)) end
    out.id, out.name = cur.id, cur.name
    local data = EB.copy(out)
    data.id, data.name, data.label, data.type, data.enabled = nil, nil, nil, nil, nil
    MySQL.update.await('UPDATE eventbuilder_events SET label = ?, enabled = ?, data = ? WHERE id = ?', { out.label, out.enabled and 1 or 0, json.encode(data), cur.id })
    EB.Defs[cur.id] = out
    EB.log(out, ESX.GetPlayerFromId(src), 'save', out.label)
    TriggerEvent('eventbuilder:internal:defsChanged')
    cb({ ok = true })
end)

ESX.RegisterServerCallback('eventbuilder:delete', function(src, cb, id)
    if not needAdmin(src, cb) then return end
    local cur = EB.Defs[tonumber(id)]
    if not cur then return cb(fail('Événement introuvable')) end
    for rid, run in pairs(EB.Active) do if run.defId == cur.id then EB.stopRun(rid, 'supprimé') end end
    MySQL.update.await('DELETE FROM eventbuilder_events WHERE id = ?', { cur.id })
    EB.Defs[cur.id], EB.ByName[cur.name] = nil, nil
    EB.log(cur, ESX.GetPlayerFromId(src), 'delete', cur.label)
    TriggerEvent('eventbuilder:internal:defsChanged')
    cb({ ok = true })
end)

ESX.RegisterServerCallback('eventbuilder:duplicate', function(src, cb, id)
    if not needAdmin(src, cb) then return end
    local cur = EB.Defs[tonumber(id)]
    if not cur then return cb(fail('Événement introuvable')) end
    local d = EB.copy(cur)
    d.label = (cur.label .. ' (copie)'):sub(1, 60)
    d.name = cur.name .. '_' .. math.random(100, 999)
    local out = clean(d, true)
    if not out then return cb(fail('Copie impossible')) end
    out.name = d.name
    local data = EB.copy(out)
    data.name, data.label, data.type, data.enabled = nil, nil, nil, nil
    local xPlayer = ESX.GetPlayerFromId(src)
    local nid = MySQL.insert.await('INSERT INTO eventbuilder_events (name, label, type, enabled, data, created_by) VALUES (?, ?, ?, ?, ?, ?)',
        { out.name, out.label, out.type, 0, json.encode(data), xPlayer and xPlayer.identifier or nil })
    out.id, out.enabled = nid, false
    EB.Defs[nid], EB.ByName[out.name] = out, nid
    TriggerEvent('eventbuilder:internal:defsChanged')
    cb({ ok = true, id = nid })
end)

ESX.RegisterServerCallback('eventbuilder:toggle', function(src, cb, id)
    if not needAdmin(src, cb) then return end
    local cur = EB.Defs[tonumber(id)]
    if not cur then return cb(fail('Événement introuvable')) end
    cur.enabled = not cur.enabled
    MySQL.update.await('UPDATE eventbuilder_events SET enabled = ? WHERE id = ?', { cur.enabled and 1 or 0, cur.id })
    TriggerEvent('eventbuilder:internal:defsChanged')
    cb({ ok = true, enabled = cur.enabled })
end)

ESX.RegisterServerCallback('eventbuilder:logs', function(src, cb)
    if not needAdmin(src, cb) then return end
    cb({ ok = true, logs = MySQL.query.await('SELECT id, event_label, player_name, action, detail, amount, UNIX_TIMESTAMP(created_at) AS ts FROM eventbuilder_logs ORDER BY id DESC LIMIT ?', { Config.LogLimit }) or {} })
end)
