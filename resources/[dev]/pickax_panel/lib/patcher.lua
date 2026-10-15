-- Lecture / écriture des valeurs directement dans les fichiers de configuration EXISTANTS des ressources
-- (config.lua, style.css, index.html, ui.js...). Aucun fichier n'a besoin d'être préparé : le panel retrouve la valeur
-- à partir d'un repère (anchor) + d'un nom (key) et la remplace sur place, sans toucher au reste du fichier
-- (commentaires, indentation, fins de ligne conservés).

Patcher = {}

local function isWord(c) return c ~= '' and c:match('[%w_]') ~= nil end

-- Fin d'une chaîne qui commence en i (guillemet)
local function scanString(src, i)
    local q, j = src:sub(i, i), i + 1
    while j <= #src do
        local c = src:sub(j, j)
        if c == '\\' then j = j + 2
        elseif c == q then return j
        elseif c == '\n' then return nil
        else j = j + 1 end
    end
end

-- Fin d'une table { ... } qui commence en i
local function scanBalanced(src, i)
    local depth, j = 0, i
    while j <= #src do
        local c = src:sub(j, j)
        if c == '"' or c == "'" then
            local e = scanString(src, j)
            if not e then return nil end
            j = e
        elseif c == '-' and src:sub(j, j + 1) == '--' then
            j = src:find('\n', j, true) or #src
        elseif c == '{' then depth = depth + 1
        elseif c == '}' then
            depth = depth - 1
            if depth == 0 then return j end
        end
        j = j + 1
    end
end

-- Cherche la valeur décrite par `loc` = { anchor?, key, sep?, to? } ; renvoie début, fin (inclus) ou nil, raison
function Patcher.locate(src, loc)
    local init = 1
    if loc.anchor then
        local _, b = src:find(loc.anchor, 1, true)
        if not b then return nil, 'repère introuvable' end
        init = b + 1
    end
    local sep = loc.sep
    if sep == nil then sep = '^%s*[=:]%s*' end
    while true do
        local s, e = src:find(loc.key, init, true)
        if not s then return nil, 'clé introuvable' end
        init = e + 1
        local ok = true
        -- mot entier uniquement (évite InfoBackground pour Background, --accent pour --accent-rgb...)
        if isWord(loc.key:sub(1, 1)) and isWord(src:sub(s - 1, s - 1)) then ok = false end
        -- ligne commentée
        if ok then
            local ls = s
            while ls > 1 and src:sub(ls - 1, ls - 1) ~= '\n' do ls = ls - 1 end
            local before = src:sub(ls, s - 1)
            if before:match('^%s*//') then ok = false end
            -- commentaire Lua (--) avant la clé sur la même ligne, sauf variable CSS (--nom:)
            local line = src:sub(ls, (src:find('\n', s, true) or #src + 1) - 1)
            local p = 1
            while ok do
                local c = line:find('--', p, true)
                if not c or c > #before then break end
                if not line:sub(c):match('^%-%-[%a][%w%-]*:') then ok = false end
                p = c + 2
            end
        end
        local vs = e + 1
        if ok and sep then
            local _, se = src:find(sep, e + 1)
            if se then vs = se + 1 else ok = false end
        end
        if ok then
            local ve
            local c = src:sub(vs, vs)
            if loc.to then
                local ts = src:find(loc.to, vs, true)
                if not ts then return nil, 'fin de valeur introuvable' end
                ve = ts - 1
                while ve >= vs and src:sub(ve, ve):match('%s') do ve = ve - 1 end
            elseif c == '{' then
                ve = scanBalanced(src, vs)
            elseif c == '"' or c == "'" then
                ve = scanString(src, vs)
            else
                local _, te = src:find('^[^%s,;})]+', vs)
                ve = te
            end
            if not ve then return nil, 'valeur illisible' end
            return vs, ve
        end
    end
end

-- ===== Types =====
local function unquote(raw)
    local q = raw:sub(1, 1)
    if (q == '"' or q == "'" or q == '`') and raw:sub(-1) == q and #raw >= 2 then
        return (raw:sub(2, -2):gsub('\\(.)', '%1')), q
    end
    return raw, nil
end

local function unhtml(s)
    return (s:gsub('&lt;', '<'):gsub('&gt;', '>'):gsub('&quot;', '"'):gsub('&#39;', "'"):gsub('&amp;', '&'))
end

local function html(s)
    return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;'))
end

local function trimNum(n)
    local s = string.format('%.4f', n):gsub('0+$', ''):gsub('%.$', '')
    return s
end

local TEXTLIKE = { text = true, color = true, css = true, url = true, raw = true }

function Patcher.parse(field, raw)
    local t = field.type
    if TEXTLIKE[t] then
        local v = unquote(raw)
        if field.escape == 'html' then v = unhtml(v) end
        return v
    elseif t == 'number' then
        local s = unquote(raw)
        if field.unit and s:sub(-#field.unit) == field.unit then s = s:sub(1, -#field.unit - 1) end
        return tonumber(s)
    elseif t == 'select' then
        local v, q = unquote(raw)
        if q then return v end
        return tonumber(v) or v
    elseif t == 'bool' then
        if raw == 'true' then return true elseif raw == 'false' then return false end
        return nil
    elseif t == 'rgba' then
        local out = {}
        for n in raw:gmatch('%-?%d+%.?%d*') do out[#out + 1] = tonumber(n) end
        if #out < 3 then return nil end
        return out
    end
    return nil
end

function Patcher.format(field, value, raw)
    local t = field.type
    if TEXTLIKE[t] then
        local _, q = unquote(raw)
        local v = tostring(value)
        if field.escape == 'html' then return html(v) end
        if q then
            v = v:gsub('\\', '\\\\'):gsub(q, '\\' .. q)
            return q .. v .. q
        end
        return v
    elseif t == 'number' then
        local _, q = unquote(raw)
        local out = trimNum(value) .. (field.unit or '')
        if q then out = q .. out .. q end
        return out
    elseif t == 'select' then
        if type(value) == 'number' then return trimNum(value) end
        local _, q = unquote(raw)
        q = q or "'"
        return q .. tostring(value):gsub('\\', '\\\\'):gsub(q, '\\' .. q) .. q
    elseif t == 'bool' then
        return value and 'true' or 'false'
    elseif t == 'rgba' then
        local n = #value
        if field.named then
            local parts = { 'r = ' .. value[1], 'g = ' .. value[2], 'b = ' .. value[3] }
            if n >= 4 then parts[4] = 'a = ' .. value[4] end
            return '{ ' .. table.concat(parts, ', ') .. ' }'
        end
        local parts = {}
        for i = 1, n do parts[i] = tostring(value[i]) end
        return '{' .. table.concat(parts, ', ') .. '}'
    end
end

-- Valide / normalise une valeur venant du panel. Renvoie la valeur propre, ou nil + message
function Patcher.validate(field, v, curLen)
    local t = field.type
    if t == 'bool' then
        if type(v) ~= 'boolean' then return nil, 'booléen attendu' end
        return v
    elseif t == 'number' then
        v = tonumber(v)
        if not v then return nil, 'nombre attendu' end
        if field.min and v < field.min then return nil, 'minimum ' .. field.min end
        if field.max and v > field.max then return nil, 'maximum ' .. field.max end
        if field.int then v = math.floor(v + 0.5) end
        return v
    elseif t == 'select' then
        for _, o in ipairs(field.options or {}) do
            if tostring(o[1]) == tostring(v) then return o[1] end
        end
        return nil, 'choix invalide'
    elseif t == 'color' then
        if v == '' and field.optional then return '' end
        if type(v) ~= 'string' or not v:match('^#%x%x%x%x%x%x$') then return nil, 'couleur #RRGGBB attendue' end
        return v:lower()
    elseif t == 'rgba' then
        if type(v) ~= 'table' then return nil, 'couleur attendue' end
        local n = curLen or (field.alpha == false and 3 or 4)
        local out = {}
        for i = 1, n do
            local x = tonumber(v[i])
            if not x then return nil, 'couleur invalide' end
            out[i] = math.max(0, math.min(255, math.floor(x + 0.5)))
        end
        return out
    elseif t == 'text' or t == 'css' or t == 'url' then
        if type(v) ~= 'string' then return nil, 'texte attendu' end
        if #v > (field.max or 200) then return nil, 'trop long' end
        if v:find('[%c]') then return nil, 'caractères de contrôle interdits' end
        if t == 'css' and not v:match('^[%w%s%.,%-%%#%(%)/_:]*$') then return nil, 'valeur CSS invalide' end
        if t == 'url' and v ~= '' and not v:match('^https?://[^%s"\'<>\\]+$') then return nil, 'lien http(s) attendu' end
        if field.pattern and not v:match(field.pattern) then return nil, field.patternError or 'format invalide' end
        return v
    elseif t == 'items' then
        if type(v) ~= 'table' then return nil, 'liste attendue' end
        local out = {}
        for _, s in ipairs(v) do
            if type(s) ~= 'string' or s:find('[%c]') or #s > 140 then return nil, 'ligne invalide' end
            if s ~= '' then out[#out + 1] = s end
            if #out > 20 then return nil, '20 lignes maximum' end
        end
        return out
    end
    return nil, 'type inconnu'
end

-- ===== Liste d'éléments HTML consécutifs (ticker) =====
local function locateItems(src, loc)
    local _, b = src:find(loc.anchor, 1, true)
    if not b then return nil, 'repère introuvable' end
    local first, last, items = nil, nil, {}
    local pos = b + 1
    while true do
        local s, e = src:find('^%s*' .. loc.open:gsub('%p', '%%%0'), pos)
        if not s then break end
        local cs = src:find(loc.close, e + 1, true)
        if not cs then break end
        first = first or (src:find(loc.open, s, true))
        items[#items + 1] = unhtml(src:sub(e + 1, cs - 1))
        last = cs + #loc.close - 1
        pos = last + 1
    end
    if not first then return nil, 'liste introuvable' end
    return first, last, items
end

-- ===== API haut niveau (sur le contenu d'un fichier) =====
-- Lit la valeur d'un champ dans `src` ; renvoie valeur, ou nil + raison
function Patcher.read(src, field)
    local loc = field.loc
    if field.type == 'items' then
        local s, e, items = locateItems(src, loc)
        if not s then return nil, e end
        return items
    end
    local s, e = Patcher.locate(src, loc)
    if not s then return nil, e end
    local v = Patcher.parse(field, src:sub(s, e))
    if v == nil then return nil, 'valeur de type inattendu' end
    return v
end

local function transform(xf, value)
    if xf == 'rgbcsv' then
        local r, g, b = value:match('^#(%x%x)(%x%x)(%x%x)$')
        return string.format('%d, %d, %d', tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
    elseif xf == 'div100' then
        return value / 100
    end
    return value
end

-- Remplace la valeur d'un champ (et de ses compagnons dans le même fichier) ; renvoie le nouveau contenu, ou nil + raison
local function replaceAt(src, loc, field, value)
    if field.type == 'items' then
        local s, e = locateItems(src, loc)
        if not s then return nil, e end
        local indent = src:sub(1, s - 1):match('([ \t]*)$') or ''
        local parts = {}
        for i, line in ipairs(value) do parts[i] = loc.open .. html(line) .. loc.close end
        return src:sub(1, s - 1) .. table.concat(parts, '\n' .. indent) .. src:sub(e + 1)
    end
    local s, e = Patcher.locate(src, loc)
    if not s then return nil, e end
    return src:sub(1, s - 1) .. Patcher.format(field, value, src:sub(s, e)) .. src:sub(e + 1)
end

function Patcher.write(src, field, value)
    return replaceAt(src, field.loc, field, value)
end

function Patcher.writeCompanion(src, comp, value)
    local cf = { type = comp.type or 'raw', escape = comp.escape, unit = comp.unit }
    return replaceAt(src, comp, cf, transform(comp.xform, value))
end

function Patcher.equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= 'table' then return a == b end
    if #a ~= #b then return false end
    for i = 1, #a do if not Patcher.equal(a[i], b[i]) then return false end end
    return true
end
