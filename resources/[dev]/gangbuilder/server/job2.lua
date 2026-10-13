-- ─────────────────────────────── Couche job2 ───────────────────────────────
-- Tout ce que le builder fait avec job2 passe par ici : lecture / écriture du job2 d'un joueur (en ligne ou non),
-- liste des membres, rechargement de la liste des jobs2 côté es_extended, détection des noms déjà pris.
-- Si ton es_extended gère job2 différemment, adapte Config.Job2 (config.lua) — ou ce fichier, il est volontairement court.

local J = Config.Job2
local cache = {}   -- [identifier] = { name, grade, t } : lecture base (source 'db') pendant 1,5 s

local function usersQuery()
    return ('SELECT %s AS job, %s AS grade FROM %s WHERE %s = ?'):format(
        GB.id(J.UserJobColumn), GB.id(J.UserGradeColumn), GB.id(J.UsersTable), GB.id(J.IdentifierColumn))
end

local function toXPlayer(who)
    if type(who) == 'table' then return who end
    return who and ESX.GetPlayerFromId(who) or nil
end

-- Gang (job2) d'un joueur : name, grade. Relu à chaque appel (jamais de cache pour les contrôles de sécurité).
local function dbJob2(xPlayer)
    local c = cache[xPlayer.identifier]
    if c and GetGameTimer() - c.t < 1500 then return c.name, c.grade end
    local row = MySQL.single.await(usersQuery(), { xPlayer.identifier })
    local name, grade = row and row.job, row and tonumber(row.grade) or 0
    cache[xPlayer.identifier] = { name = name, grade = grade, t = GetGameTimer() }
    return name, grade
end

function GB.job2Of(who)
    local xPlayer = toXPlayer(who)
    if not xPlayer then return nil, 0 end
    if J.Source ~= 'db' then
        local j = xPlayer[J.PlayerField]
        local n, g
        if type(j) == 'table' and j.name then n, g = j.name, tonumber(j.grade) or 0
        elseif type(j) == 'string' then n, g = j, tonumber(xPlayer[J.PlayerField .. '_grade']) or 0 end
        if J.Source == 'esx' then return n, g or 0 end
        -- 'auto' : si ES ne voit pas (encore) un gang du builder mais que la base le dit, on fait confiance à la base
        if n and GB.Gangs[n] then return n, g end
        local dn, dg = dbJob2(xPlayer)
        if dn and GB.Gangs[dn] then return dn, dg end
        if n then return n, g end
        return dn, dg
    end
    return dbJob2(xPlayer)
end

-- Gang du joueur uniquement s'il est géré par le builder : gang, grade, xPlayer
function GB.gangOf(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return nil end
    local name, grade = GB.job2Of(xPlayer)
    local gang = name and GB.Gangs[name]
    if not gang then return nil end
    return gang, grade, xPlayer
end

-- Écrit le job2 d'un joueur CONNECTÉ. 1) méthode du xPlayer (xPlayer.setJob2) 2) à défaut / en cas d'échec : base + events de repli.
function GB.setJob2(who, name, grade)
    local xPlayer = toXPlayer(who)
    if not xPlayer then return false end
    grade = math.floor(tonumber(grade) or 0)
    local src = xPlayer.source
    local oldName, oldGrade = GB.job2Of(xPlayer)

    local fn = J.Source ~= 'db' and xPlayer[J.SetMethod]
    if type(fn) == 'function' then
        local ok, err = pcall(fn, name, grade)
        if not ok then print(('^3[gangbuilder] xPlayer.%s a échoué : %s^0'):format(J.SetMethod, tostring(err))) end
        -- ESX applique parfois le changement avec un léger délai : on revérifie avant de passer au repli
        for _ = 1, 10 do
            local n, g = GB.job2Of(src)
            if n == name and g == grade then break end
            Wait(100)
        end
        local n, g = GB.job2Of(src)
        if n == name and g == grade then
            SetTimeout(300, function() GB.syncPlayer(src) end)
            return true
        end
        print(('^3[gangbuilder] %s n\'a pas pris en compte le job2 « %s » : repli sur la base de données. Vérifie que ton es_extended connaît ce job2 (/gbcheck, Config.Job2.Refresh*).^0'):format(J.SetMethod, name))
    end

    -- Repli : base de données + events
    MySQL.update.await(('UPDATE %s SET %s = ?, %s = ? WHERE %s = ?'):format(GB.id(J.UsersTable), GB.id(J.UserJobColumn), GB.id(J.UserGradeColumn), GB.id(J.IdentifierColumn)),
        { name, grade, xPlayer.identifier })
    cache[xPlayer.identifier] = nil
    -- Même forme que les jobs ESX : { name, label, grade, grade_name, grade_label, grade_salary, skin_male, skin_female }
    local function jobTable(n, g, prev)
        local gang = GB.Gangs[n]
        local gr = gang and gang.grades[g + 1]
        if gang or type(prev) ~= 'table' then
            return { name = n, label = gang and gang.label or n, grade = g, grade_name = gr and gr.name or '', grade_label = gr and gr.label or '',
                grade_salary = gr and gr.salary or 0, skin_male = {}, skin_female = {} }
        end
        return prev
    end
    local prevField = xPlayer[J.PlayerField]
    local data = jobTable(name, grade)
    local last = type(prevField) == 'table' and prevField.name and prevField or jobTable(oldName or J.Default.name, oldGrade or 0, nil)
    -- les scripts tiers (ex : esx_custom) attendent les DEUX arguments : (nouveau job2, ancien job2)
    TriggerClientEvent(J.ClientEvent, src, data, last)
    TriggerEvent(J.ServerEvent, src, data, last)
    SetTimeout(300, function() GB.syncPlayer(src) end)
    return true
end

-- Écrit le job2 d'un joueur HORS LIGNE (condition optionnelle : seulement s'il est toujours dans `fromGang`)
function GB.setJob2Offline(identifier, name, grade, fromGang)
    local q = ('UPDATE %s SET %s = ?, %s = ? WHERE %s = ?'):format(GB.id(J.UsersTable), GB.id(J.UserJobColumn), GB.id(J.UserGradeColumn), GB.id(J.IdentifierColumn))
    local values = { name, math.floor(tonumber(grade) or 0), identifier }
    if fromGang then
        q = q .. (' AND %s = ?'):format(GB.id(J.UserJobColumn))
        values[#values + 1] = fromGang
    end
    cache[identifier] = nil
    return (MySQL.update.await(q, values) or 0) > 0
end

-- Change le job2 d'un membre, en ligne ou non
function GB.setMemberJob2(identifier, name, grade, fromGang)
    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then return GB.setJob2(xTarget, name, grade), xTarget end
    return GB.setJob2Offline(identifier, name, grade, fromGang), nil
end

-- Membre ramené « sans gang »
function GB.clearMember(identifier, fromGang)
    return GB.setMemberJob2(identifier, J.Default.name, J.Default.grade, fromGang)
end

-- Joueurs connectés d'un gang (liste de sources)
function GB.onlineMembers(gangName)
    local list = {}
    for src, g in pairs(GB.PlayerGang) do
        if g.name == gangName then list[#list + 1] = src end
    end
    return list
end

-- Membres d'un gang (base) : { identifier, name, grade, online }
function GB.members(gangName, limit)
    local rows = MySQL.query.await(('SELECT %s AS identifier, firstname, lastname, %s AS grade FROM %s WHERE %s = ? ORDER BY %s DESC, lastname LIMIT %d'):format(
        GB.id(J.IdentifierColumn), GB.id(J.UserGradeColumn), GB.id(J.UsersTable), GB.id(J.UserJobColumn), GB.id(J.UserGradeColumn), limit or 300), { gangName }) or {}
    local out = {}
    for _, r in ipairs(rows) do
        out[#out + 1] = {
            identifier = r.identifier,
            name = (((r.firstname or '') .. ' ' .. (r.lastname or '')):gsub('^%s+', '')),
            grade = tonumber(r.grade) or 0,
            online = ESX.GetPlayerFromIdentifier(r.identifier) ~= nil,
        }
    end
    return out
end

function GB.memberCount(gangName)
    return tonumber(MySQL.scalar.await(('SELECT COUNT(*) FROM %s WHERE %s = ?'):format(GB.id(J.UsersTable), GB.id(J.UserJobColumn)), { gangName })) or 0
end

-- Nom déjà pris dans une table de jobs / de gangs (jamais de mélange avec un job existant ou un autre script de gangs)
function GB.nameConflict(name)
    if name == J.Default.name then return J.Default.name end
    for _, c in ipairs(J.ConflictTables or {}) do
        local ok, rows = pcall(function()
            return MySQL.query.await(('SELECT 1 FROM %s WHERE LOWER(%s) = ? LIMIT 1'):format(GB.id(c.table), GB.id(c.column)), { name })
        end)
        if ok and rows and #rows > 0 then return c.table end
    end
    return nil
end

-- Recharge la liste des jobs2 dans es_extended. Retourne true si une fonction / un event spécifique à job2 a été appelé.
local warned = false
function GB.refreshJob2()
    local called = false
    for _, fn in ipairs(J.RefreshFunctions or {}) do
        if type(ESX[fn]) == 'function' then
            local ok, err = pcall(ESX[fn])
            if not ok then print(('^1[gangbuilder] ESX.%s a échoué : %s^0'):format(fn, tostring(err))) end
            if fn:find('2') then called = called or ok end
        end
    end
    for _, ev in ipairs(J.RefreshEvents or {}) do TriggerEvent(ev) called = true end
    if type(J.Refresh) == 'function' then
        local ok, err = pcall(J.Refresh)
        if not ok then print(('^1[gangbuilder] Config.Job2.Refresh a échoué : %s^0'):format(tostring(err))) end
        called = called or ok
    end
    if not called and not warned then
        warned = true
        print('^3[gangbuilder] Aucune fonction de rechargement job2 trouvée dans es_extended (ESX.RefreshJobs2…). Les nouveaux gangs ne seront pris en compte par ES qu\'après un restart : renseigne Config.Job2.RefreshFunctions / Refresh, ou Config.RestartResources.^0')
    end
    return called
end

-- Redémarre les ressources configurées (un seul redémarrage même si plusieurs modifications rapprochées)
local restartToken = 0
function GB.compatRefresh()
    if #Config.RestartResources == 0 then return { restarted = false } end
    restartToken = restartToken + 1
    local mine = restartToken
    SetTimeout(3000, function()
        if mine ~= restartToken then return end
        for _, r in ipairs(Config.RestartResources) do
            if GetResourceState(r) == 'started' then
                print(('^2[gangbuilder] Redémarrage de %s pour prendre en compte les gangs.^0'):format(r))
                ExecuteCommand('restart ' .. r)
            end
        end
    end)
    return { restarted = true, resources = Config.RestartResources }
end

-- API pour les autres scripts
exports('SetPlayerGang', function(src, name, grade) return GB.Gangs[tostring(name)] ~= nil and GB.setJob2(src, tostring(name), grade) end)
exports('GetGangMembers', function(name) return GB.members(tostring(name)) end)

-- /gbwho [id] : ce que le script lit pour ton job2 (console serveur ou joueur _dev)
RegisterCommand('gbwho', function(src, args)
    if src ~= 0 and not GB.isDev(src) then return end
    local target = tonumber(args[1]) or src
    local x = target and target ~= 0 and ESX.GetPlayerFromId(target)
    local out = {}
    if not x then out[1] = 'joueur introuvable' else
        local raw = x[J.PlayerField]
        out[#out + 1] = ('xPlayer.%s = %s'):format(J.PlayerField, type(raw) == 'table' and json.encode({ name = raw.name, grade = raw.grade }) or tostring(raw))
        out[#out + 1] = ('xPlayer.%s = %s'):format(J.SetMethod, type(x[J.SetMethod]))
        cache[x.identifier] = nil
        local dn, dg = dbJob2(x)
        out[#out + 1] = ('base (%s.%s) = %s / %s'):format(J.UsersTable, J.UserJobColumn, tostring(dn), tostring(dg))
        local n, g = GB.job2Of(x)
        out[#out + 1] = ('lu par le script = %s / %s | gang du builder : %s | points : %d'):format(tostring(n), tostring(g), tostring(n and GB.Gangs[n] ~= nil), n and #GB.pointsForGang(n) or 0)
    end
    for _, l in ipairs(out) do print('^5[gbwho]^0 ' .. l) end
    if src ~= 0 then for _, l in ipairs(out) do GB.notify(src, l) end end
end, false)
