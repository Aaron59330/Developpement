-- ─────────────────────────────── Tablette police : casiers, amendes, dispatch, carte en temps réel ───────────────────────────────
-- Chaque job a SA tablette : casiers, appels, poursuites et unités sont strictement séparés par job (job_name sur chaque requête).
-- Ouverture : F6 → Tablette (jobs de type police, ou tout job qui coche l'action « Tablette »).

local P = Config.Police
local function fail(msg) return { ok = false, error = msg } end

local function str(v, max, default)
    if type(v) ~= 'string' then return default or '' end
    return (v:gsub('%c', ' ')):sub(1, max)
end

local function hasAction(job, action)
    for _, a in ipairs(job.settings.actions or {}) do if a == action then return true end end
    return false
end

-- Identité RP d'un joueur (esx_identity) avec repli sur le nom du compte
local function identity(x)
    local first = x.get and x.get('firstName') or nil
    local last = x.get and x.get('lastName') or nil
    local dob = x.get and x.get('dateofbirth') or nil
    if not first or first == '' then
        local name = JB.playerName(x)
        first, last = name:match('^(%S+)%s+(.+)$')
        first, last = first or name, last or ''
    end
    return str(tostring(first), 50), str(tostring(last or ''), 50), dob and str(tostring(dob), 20) or nil
end

-- Contexte d'une requête : joueur, job, réglages, droits. `need` = 'records' | 'dispatch' | 'map' | 'admin' | 'fine' | 'pursuit'
local function ctx(src, need)   -- need : …| 'bracelet'
    local x = ESX.GetPlayerFromId(src)
    if not x then return nil, nil, nil, 'Joueur introuvable' end
    local job = JB.Jobs[x.job.name]
    if not job then return nil, nil, nil, 'Ton métier n\'a pas de tablette' end
    local s = job.settings or {}
    local allowed = job.type == 'police' and s.tablet_enabled ~= false
    if not allowed then return nil, nil, nil, 'Ton métier n\'a pas accès à la tablette' end
    local g = x.job.grade
    if g < (s.tablet_grade or 0) then return nil, nil, nil, 'Ton grade ne permet pas d\'ouvrir la tablette' end
    local perms = {
        records = s.tablet_records ~= false, dispatch = s.tablet_dispatch ~= false, map = s.tablet_map ~= false,
        bracelet = (P.Bracelets or {}).Enabled ~= false and s.tablet_bracelets ~= false and g >= (s.bracelet_grade or 0),
        admin = g >= (s.tablet_admin_grade or job.boss_grade), fine = g >= (s.fine_grade or 0), pursuit = g >= (s.pursuit_grade or 0),
    }
    if need and not perms[need] then return nil, nil, nil, 'Ton grade ne permet pas cette action' end
    return x, job, s, nil, perms
end

local function jobMembers(jobName)
    local ok, list = pcall(ESX.GetExtendedPlayers, 'job', jobName)
    return ok and list or {}
end

local function recordOf(jobName, id)
    return MySQL.single.await('SELECT * FROM jobbuilder_records WHERE id = ? AND job_name = ?', { tonumber(id) or 0, jobName })
end

local function addEntry(recId, jobName, kind, label, amount, details, officer)
    MySQL.insert.await('INSERT INTO jobbuilder_record_entries (record_id, job_name, kind, label, amount, details, officer) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { recId, jobName, kind, str(label, 120), math.floor(tonumber(amount) or 0), details and str(details, 1000) or nil, officer })
    MySQL.update('UPDATE jobbuilder_records SET updated_at = NOW() WHERE id = ?', { recId })
end

-- Casier du joueur ciblé pour CE job (créé s'il n'existe pas)
local function ensureRecord(jobName, target, officer)
    local row = MySQL.single.await('SELECT id FROM jobbuilder_records WHERE job_name = ? AND identifier = ?', { jobName, target.identifier })
    if row then return row.id end
    local first, last, dob = identity(target)
    return MySQL.insert.await('INSERT INTO jobbuilder_records (job_name, identifier, firstname, lastname, birthdate, created_by) VALUES (?, ?, ?, ?, ?, ?)',
        { jobName, target.identifier, first, last, dob, officer })
end

-- ─────────────────────────────── Dispatch (en mémoire, par job) ───────────────────────────────
local calls = {}        -- [job] = { next = n, list = { call... } }
local KINDS = { citizen = true, officer = true, panic = true, pursuit = true, alert = true }

local function jobCalls(jobName)
    calls[jobName] = calls[jobName] or { next = 1, list = {} }
    return calls[jobName]
end

local function pruneCalls(jobName)
    local c = jobCalls(jobName)
    local keep, limit = {}, os.time() - P.ClosedKeepMinutes * 60
    for _, call in ipairs(c.list) do
        if call.status ~= 'closed' or (call.closedAt or 0) >= limit then keep[#keep + 1] = call end
    end
    while #keep > P.MaxCalls do table.remove(keep, 1) end
    c.list = keep
end

local function findCall(jobName, id)
    for _, call in ipairs(jobCalls(jobName).list) do if call.id == tonumber(id) then return call end end
end

local function alertJob(jobName, call)
    local job = JB.Jobs[jobName]
    local minGrade = job and job.settings.tablet_grade or 0
    for _, m in ipairs(jobMembers(jobName)) do
        if m.job.grade >= minGrade then
            TriggerClientEvent('jobbuilder:client:dispatchAlert', m.source, { id = call.id, title = call.title, message = call.message, kind = call.kind, x = call.x, y = call.y, z = call.z })
        end
    end
end

local function addCall(jobName, data)
    local c = jobCalls(jobName)
    local call = {
        id = c.next, title = str(data.title, 60, 'Appel'), message = str(data.message, 240), kind = KINDS[data.kind] and data.kind or 'alert',
        x = data.x or 0.0, y = data.y or 0.0, z = data.z or 0.0, by = str(data.by, 80, 'Anonyme'), t = os.time(), status = 'open', units = {},
    }
    c.next = c.next + 1
    c.list[#c.list + 1] = call
    pruneCalls(jobName)
    alertJob(jobName, call)
    return call
end

JB.tabletAddCall = addCall   -- utilisé par le téléphone Aura (appels citoyens)

local function callView(call)
    local units = {}
    for _, u in ipairs(call.units) do units[#units + 1] = { src = u.src, name = u.name } end
    return { id = call.id, title = call.title, message = call.message, kind = call.kind, x = call.x, y = call.y, z = call.z, by = call.by, t = call.t, status = call.status, units = units }
end

-- Jobs qui reçoivent les appels : type police avec dispatch actif (ou tablette cochée)
local function dispatchJobs()
    local out = {}
    for name, job in pairs(JB.Jobs) do
        local s = job.settings or {}
        if job.type == 'police' and s.tablet_enabled ~= false and s.tablet_dispatch ~= false then out[#out + 1] = name end
    end
    return out
end

local lastCall = {}   -- [src] = os.time()
RegisterCommand(P.CallCommand, function(src, args)
    if src == 0 then return end
    local msg = str(table.concat(args, ' '), 200)
    if #msg < 3 then return JBNotifyClient( src, ('~r~Utilisation : /%s <ton message>'):format(P.CallCommand)) end
    if lastCall[src] and os.time() - lastCall[src] < P.CallCooldown then
        return JBNotifyClient( src, '~r~Patiente un instant avant de rappeler.')
    end
    local x = ESX.GetPlayerFromId(src)
    local c = GetEntityCoords(GetPlayerPed(src))
    local sent = 0
    for _, name in ipairs(dispatchJobs()) do
        if #jobMembers(name) > 0 then
            addCall(name, { title = 'Appel citoyen', message = msg, kind = 'citizen', x = c.x, y = c.y, z = c.z, by = x and select(1, identity(x)) .. ' ' .. select(2, identity(x)) or 'Anonyme' })
            sent = sent + 1
        end
    end
    lastCall[src] = os.time()
    JBNotifyClient( src, sent > 0 and '~g~Appel transmis aux unités.' or '~r~Aucune unité n\'est disponible pour le moment.')
end, false)

RegisterCommand(P.PanicCommand, function(src)
    if src == 0 then return end
    local x, job, s, err = ctx(src, 'dispatch')
    if not x then return JBNotifyClient( src, '~r~' .. (err or 'Action impossible')) end
    local c = GetEntityCoords(GetPlayerPed(src))
    addCall(job.name, { title = 'Officier en difficulté', message = JB.playerName(x) .. ' demande des renforts immédiats !', kind = 'panic', x = c.x, y = c.y, z = c.z, by = JB.playerName(x) })
    JBNotifyClient( src, '~g~Appel à l\'aide envoyé à tes collègues.')
    JB.log(job.name, x, 'panic')
end, false)

function JB.tabletHandles(job)
    local s = job.settings or {}
    return job.type == 'police' and s.tablet_enabled ~= false and s.tablet_dispatch ~= false
end

-- API pour les autres scripts (alarmes, braquages…) : target = nom d'un job OU « police » (tous les jobs police)
exports('SendDispatch', function(target, title, message, coords, kind)
    local c = type(coords) == 'table' and coords or {}
    local data = { title = title, message = message, kind = kind or 'alert', x = tonumber(c.x), y = tonumber(c.y), z = tonumber(c.z), by = 'Système' }
    if JB.Jobs[target] then return addCall(target, data).id end
    for _, name in ipairs(dispatchJobs()) do addCall(name, data) end
    return true
end)

-- ─────────────────────────────── Poursuite en temps réel ───────────────────────────────
local pursuits = {}     -- [job] = { target, name, identifier, by, started, call }
local pursuitThread = false

local function pursuitTarget(p)
    local t = ESX.GetPlayerFromId(p.target)
    if not t then return nil end
    local ped = GetPlayerPed(p.target)
    if not ped or ped == 0 then return nil end
    local c = GetEntityCoords(ped)
    local veh = GetVehiclePedIsIn(ped, false)
    return { x = c.x, y = c.y, z = c.z, h = GetEntityHeading(ped), speed = math.floor(GetEntitySpeed(ped) * 3.6), veh = veh ~= 0 }
end

local function endPursuit(jobName, reason)
    local p = pursuits[jobName]
    if not p then return end
    pursuits[jobName] = nil
    local call = findCall(jobName, p.call)
    if call then call.status = 'closed' call.closedAt = os.time() end
    for _, m in ipairs(jobMembers(jobName)) do
        TriggerClientEvent('jobbuilder:client:pursuit', m.source, { active = false })
        JBNotifyClient( m.source, ('Poursuite terminée : %s (%s)'):format(p.name, reason))
    end
end

local function startPursuitThread()
    if pursuitThread then return end
    pursuitThread = true
    CreateThread(function()
        while next(pursuits) do
            for jobName, p in pairs(pursuits) do
                if os.time() - p.started > P.PursuitMax then
                    endPursuit(jobName, 'durée maximale atteinte')
                else
                    local pos = pursuitTarget(p)
                    if not pos then
                        endPursuit(jobName, 'le suspect a quitté le serveur')
                    else
                        for _, m in ipairs(jobMembers(jobName)) do
                            TriggerClientEvent('jobbuilder:client:pursuit', m.source, { active = true, name = p.name, x = pos.x, y = pos.y, z = pos.z })
                        end
                    end
                end
            end
            Wait(P.RefreshMs)
        end
        pursuitThread = false
    end)
end

AddEventHandler('playerDropped', function() lastCall[source] = nil end)

-- ─────────────────────────────── Callbacks ───────────────────────────────
ESX.RegisterServerCallback('jobbuilder:tablet:open', function(src, cb)
    local x, job, s, err, perms = ctx(src)
    if not x then return cb(fail(err)) end
    pruneCalls(job.name)
    local openCalls = 0
    for _, c in ipairs(jobCalls(job.name).list) do if c.status ~= 'closed' then openCalls = openCalls + 1 end end
    local stats = {
        records = MySQL.scalar.await('SELECT COUNT(*) FROM jobbuilder_records WHERE job_name = ?', { job.name }) or 0,
        wanted = MySQL.scalar.await('SELECT COUNT(*) FROM jobbuilder_records WHERE job_name = ? AND wanted = 1', { job.name }) or 0,
        fines = MySQL.scalar.await('SELECT COALESCE(SUM(amount), 0) FROM jobbuilder_record_entries WHERE job_name = ? AND kind = ? AND created_at > (NOW() - INTERVAL 30 DAY)', { job.name, 'fine' }) or 0,
        calls = openCalls, units = #jobMembers(job.name),
    }
    local recent = MySQL.query.await([[SELECT e.kind, e.label, e.amount, e.officer, UNIX_TIMESTAMP(e.created_at) AS t, r.firstname, r.lastname
        FROM jobbuilder_record_entries e JOIN jobbuilder_records r ON r.id = e.record_id WHERE e.job_name = ? ORDER BY e.id DESC LIMIT 8]], { job.name }) or {}
    local fines = (s.fines and #s.fines > 0) and s.fines or P.DefaultFines
    cb({
        ok = true, job = job.name, jobLabel = job.label, grade = x.job.grade, gradeLabel = x.job.grade_label, me = { src = src, name = JB.playerName(x) },
        perms = perms, stats = stats, recent = recent, fines = fines, fineCustom = s.fine_custom ~= false, limits = { min = P.MinFine, max = P.MaxFine },
        map = P.Map, landmarks = P.Landmarks, commands = { call = P.CallCommand, panic = P.PanicCommand }, refresh = P.RefreshMs, trail = P.PursuitTrail, pursuitMax = P.PursuitMax,
    })
end)

-- Rafraîchissement (carte, dispatch) : unités du job, poursuite, appels
ESX.RegisterServerCallback('jobbuilder:tablet:live', function(src, cb)
    local x, job, s, err, perms = ctx(src)
    if not x then return cb(fail(err)) end
    local units = {}
    if perms.map then
        for _, m in ipairs(jobMembers(job.name)) do
            local ped = GetPlayerPed(m.source)
            if ped and ped ~= 0 then
                local c = GetEntityCoords(ped)
                units[#units + 1] = { src = m.source, name = JB.playerName(m), grade = m.job.grade_label, x = c.x, y = c.y, z = c.z, h = GetEntityHeading(ped),
                    veh = GetVehiclePedIsIn(ped, false) ~= 0, speed = math.floor(GetEntitySpeed(ped) * 3.6), me = m.source == src }
            end
        end
    end
    local pursuit
    local p = pursuits[job.name]
    if p then
        local pos = pursuitTarget(p)
        if pos then
            pursuit = { name = p.name, by = p.by, x = pos.x, y = pos.y, z = pos.z, h = pos.h, speed = pos.speed, veh = pos.veh, since = p.started, left = math.max(0, P.PursuitMax - (os.time() - p.started)) }
        end
    end
    local list = {}
    if perms.dispatch then
        pruneCalls(job.name)
        for i = #jobCalls(job.name).list, 1, -1 do list[#list + 1] = callView(jobCalls(job.name).list[i]) end
    end
    cb({ ok = true, units = units, pursuit = pursuit, calls = list })
end)

-- ── Casiers ──
ESX.RegisterServerCallback('jobbuilder:records:search', function(src, cb, q, wantedOnly)
    local x, job, s, err = ctx(src, 'records')
    if not x then return cb(fail(err)) end
    q = str(tostring(q or ''), 60):gsub('[%%_\\]', '\\%0')
    local like = '%' .. q .. '%'
    local rows = MySQL.query.await([[SELECT r.id, r.firstname, r.lastname, r.birthdate, r.wanted, r.wanted_reason,
        (SELECT COUNT(*) FROM jobbuilder_record_entries e WHERE e.record_id = r.id) AS n
        FROM jobbuilder_records r WHERE r.job_name = ? AND (? = '' OR CONCAT(r.firstname, ' ', r.lastname) LIKE ? OR CONCAT(r.lastname, ' ', r.firstname) LIKE ?)
        AND (? = 0 OR r.wanted = 1) ORDER BY r.wanted DESC, r.updated_at DESC LIMIT 60]], { job.name, q, like, like, wantedOnly and 1 or 0 }) or {}
    local out = {}
    for _, r in ipairs(rows) do
        out[#out + 1] = { id = r.id, name = r.firstname .. ' ' .. r.lastname, birthdate = r.birthdate, wanted = JB.flag(r.wanted), wanted_reason = r.wanted_reason, n = r.n }
    end
    cb({ ok = true, list = out })
end)

ESX.RegisterServerCallback('jobbuilder:records:get', function(src, cb, id)
    local x, job, s, err = ctx(src, 'records')
    if not x then return cb(fail(err)) end
    local r = recordOf(job.name, id)
    if not r then return cb(fail('Casier introuvable')) end
    local entries = MySQL.query.await('SELECT id, kind, label, amount, details, officer, UNIX_TIMESTAMP(created_at) AS t FROM jobbuilder_record_entries WHERE record_id = ? AND job_name = ? ORDER BY id DESC LIMIT 100', { r.id, job.name }) or {}
    local fines = 0
    for _, e in ipairs(entries) do if e.kind == 'fine' then fines = fines + e.amount end end
    local online = false
    if r.identifier and ESX.GetPlayerFromIdentifier then online = ESX.GetPlayerFromIdentifier(r.identifier) ~= nil end
    cb({ ok = true, record = {
        id = r.id, firstname = r.firstname, lastname = r.lastname, birthdate = r.birthdate, notes = r.notes or '', wanted = JB.flag(r.wanted), wanted_reason = r.wanted_reason or '',
        linked = r.identifier ~= nil, online = online, created_by = r.created_by, created = r.created_at and tostring(r.created_at) or '',
    }, entries = entries, fines = fines })
end)

ESX.RegisterServerCallback('jobbuilder:records:save', function(src, cb, rec)
    local x, job, s, err = ctx(src, 'records')
    if not x then return cb(fail(err)) end
    rec = type(rec) == 'table' and rec or {}
    local first, last = str(rec.firstname, 50), str(rec.lastname, 50)
    if first == '' or last == '' then return cb(fail('Nom et prénom obligatoires')) end
    local notes = str(rec.notes, 2000)
    local birth = str(rec.birthdate, 20)
    local wanted = rec.wanted == true
    local reason = str(rec.wanted_reason, 200)
    local officer = JB.playerName(x)
    local id = tonumber(rec.id)
    if id then
        local old = recordOf(job.name, id)
        if not old then return cb(fail('Casier introuvable')) end
        MySQL.update.await('UPDATE jobbuilder_records SET firstname = ?, lastname = ?, birthdate = ?, notes = ?, wanted = ?, wanted_reason = ? WHERE id = ? AND job_name = ?',
            { first, last, birth ~= '' and birth or nil, notes, wanted and 1 or 0, wanted and reason or nil, id, job.name })
        if wanted ~= JB.flag(old.wanted) then
            addEntry(id, job.name, 'wanted', wanted and ('Avis de recherche : ' .. (reason ~= '' and reason or 'sans motif')) or 'Avis de recherche levé', 0, nil, officer)
            JB.log(job.name, x, wanted and 'record_wanted' or 'record_cleared', first .. ' ' .. last)
        end
    else
        id = MySQL.insert.await('INSERT INTO jobbuilder_records (job_name, firstname, lastname, birthdate, notes, wanted, wanted_reason, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            { job.name, first, last, birth ~= '' and birth or nil, notes, wanted and 1 or 0, wanted and reason or nil, officer })
        if wanted then addEntry(id, job.name, 'wanted', 'Avis de recherche : ' .. (reason ~= '' and reason or 'sans motif'), 0, nil, officer) end
        JB.log(job.name, x, 'record_created', first .. ' ' .. last)
    end
    cb({ ok = true, id = id })
end)

ESX.RegisterServerCallback('jobbuilder:records:delete', function(src, cb, id)
    local x, job, s, err = ctx(src, 'admin')
    if not x then return cb(fail(err)) end
    local r = recordOf(job.name, id)
    if not r then return cb(fail('Casier introuvable')) end
    MySQL.update.await('DELETE FROM jobbuilder_record_entries WHERE record_id = ? AND job_name = ?', { r.id, job.name })
    MySQL.update.await('DELETE FROM jobbuilder_records WHERE id = ? AND job_name = ?', { r.id, job.name })
    JB.log(job.name, x, 'record_deleted', r.firstname .. ' ' .. r.lastname)
    cb({ ok = true })
end)

local ENTRY_KINDS = { fine = true, arrest = true, warning = true, note = true, seizure = true, jail = true }

ESX.RegisterServerCallback('jobbuilder:records:addEntry', function(src, cb, recId, kind, label, amount, details)
    local x, job, s, err = ctx(src, 'records')
    if not x then return cb(fail(err)) end
    local r = recordOf(job.name, recId)
    if not r then return cb(fail('Casier introuvable')) end
    if not ENTRY_KINDS[kind] then return cb(fail('Type d\'entrée invalide')) end
    label = str(label, 120)
    if label == '' then return cb(fail('Le motif est obligatoire')) end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 0 or amount > P.MaxFine * 100 then return cb(fail('Montant invalide')) end
    addEntry(r.id, job.name, kind, label, amount, details, JB.playerName(x))
    cb({ ok = true })
end)

ESX.RegisterServerCallback('jobbuilder:records:delEntry', function(src, cb, entryId)
    local x, job, s, err = ctx(src, 'admin')
    if not x then return cb(fail(err)) end
    MySQL.update.await('DELETE FROM jobbuilder_record_entries WHERE id = ? AND job_name = ?', { tonumber(entryId) or 0, job.name })
    cb({ ok = true })
end)

-- (placeholder, joueur proche) : crée / retrouve le casier de la personne devant soi
ESX.RegisterServerCallback('jobbuilder:records:fromNearest', function(src, cb, _, targetId)
    local x, job, s, err = ctx(src, 'records')
    if not x then return cb(fail(err)) end
    local target = ESX.GetPlayerFromId(tonumber(targetId))
    if not target or not JB.playersClose(src, target.source) then return cb(fail('Aucune personne à proximité')) end
    cb({ ok = true, id = ensureRecord(job.name, target, JB.playerName(x)) })
end)

-- API pour les autres ressources (pickax_illegalbuilder : saisies, peines de prison, récidive) : un seul casier, celui de la tablette police.
-- Ajoute une ligne au casier du joueur (connecté) pour le job de l'agent.
exports('AddRecordEntry', function(jobName, targetSrc, kind, label, amount, details, officerName)
    if not ENTRY_KINDS[kind] or not JB.Jobs[jobName] then return false end
    local target = ESX.GetPlayerFromId(tonumber(targetSrc))
    if not target then return false end
    label = str(tostring(label or ''), 120)
    if label == '' then return false end
    local rid = ensureRecord(jobName, target, officerName or 'Système')
    addEntry(rid, jobName, kind, label, math.max(0, math.floor(tonumber(amount) or 0)), details, officerName or 'Système')
    return rid
end)

-- Nombre d'infractions (amendes payées, arrestations, peines, saisies) d'un joueur sur N jours, tous jobs confondus
exports('RecordPriors', function(identifier, days)
    if not identifier then return 0 end
    return MySQL.scalar.await([[SELECT COUNT(*) FROM jobbuilder_record_entries e JOIN jobbuilder_records r ON r.id = e.record_id
        WHERE r.identifier = ? AND e.kind IN ('fine', 'arrest', 'jail', 'seizure') AND e.created_at > (NOW() - INTERVAL ? DAY)]], { identifier, math.max(1, math.floor(tonumber(days) or 30)) }) or 0
end)

-- ── Amendes ── (casier optionnel, joueur proche, n° du catalogue ou 0 pour une amende libre, motif, montant, remarque)
ESX.RegisterServerCallback('jobbuilder:fine:send', function(src, cb, recId, targetId, idx, label, amount, note)
    local x, job, s, err = ctx(src, 'fine')
    if not x then return cb(fail(err)) end
    local target = ESX.GetPlayerFromId(tonumber(targetId))
    if not target or target.source == src or not JB.playersClose(src, target.source) then return cb(fail('Aucune personne à proximité')) end
    idx = math.floor(tonumber(idx) or 0)
    if idx > 0 then
        local list = (s.fines and #s.fines > 0) and s.fines or P.DefaultFines
        local f = list[idx]
        if not f then return cb(fail('Amende inconnue')) end
        label, amount = f.label, f.amount
    else
        if s.fine_custom == false then return cb(fail('Les amendes libres sont désactivées pour ce job')) end
        label, amount = str(label, 60), math.floor(tonumber(amount) or 0)
        if label == '' then return cb(fail('Le motif est obligatoire')) end
    end
    if amount < P.MinFine or amount > P.MaxFine then return cb(fail(('Montant invalide (%d à %d $)'):format(P.MinFine, P.MaxFine))) end

    -- récidive (pickax_illegalbuilder) : les infractions récentes aggravent l'amende
    if GetResourceState('pickax_illegalbuilder') == 'started' then
        local ok, mul = pcall(function() return exports.pickax_illegalbuilder:RecidiveMul(target.identifier) end)
        if ok and type(mul) == 'number' and mul > 1.0 then
            amount = math.min(math.floor(amount * mul + 0.5), math.floor(P.MaxFine * mul))
            label = ('%s (récidive +%d %%)'):format(label, math.floor((mul - 1) * 100 + 0.5))
        end
    end

    local officer = JB.playerName(x)
    local rid
    if tonumber(recId) then
        local r = recordOf(job.name, recId)
        if r then
            rid = r.id
            if not r.identifier then MySQL.update('UPDATE jobbuilder_records SET identifier = ? WHERE id = ? AND job_name = ?', { target.identifier, r.id, job.name }) end
        end
    end
    rid = rid or ensureRecord(job.name, target, officer)
    note = note and str(tostring(note), 500) or nil

    JB.sendInvoice(x, target, 'Amende : ' .. label, amount, nil, {
        onPaid = function() addEntry(rid, job.name, 'fine', label, amount, note, officer) end,
        onRefused = function(why) addEntry(rid, job.name, 'warning', (why == 'unpaid' and 'Amende impayée : ' or 'Amende refusée : ') .. label, amount, note, officer) end,
    })
    JB.log(job.name, x, 'fine_sent', ('%s : %d$ (%s)'):format(label, amount, JB.playerName(target)))
    cb({ ok = true })
end)

-- ── Dispatch ──
ESX.RegisterServerCallback('jobbuilder:dispatch:create', function(src, cb, title, message)
    local x, job, s, err = ctx(src, 'dispatch')
    if not x then return cb(fail(err)) end
    title = str(tostring(title or ''), 60)
    if title == '' then return cb(fail('Le titre est obligatoire')) end
    local c = GetEntityCoords(GetPlayerPed(src))
    addCall(job.name, { title = title, message = str(tostring(message or ''), 240), kind = 'officer', x = c.x, y = c.y, z = c.z, by = JB.playerName(x) })
    cb({ ok = true })
end)

ESX.RegisterServerCallback('jobbuilder:dispatch:take', function(src, cb, id)
    local x, job, s, err = ctx(src, 'dispatch')
    if not x then return cb(fail(err)) end
    local call = findCall(job.name, id)
    if not call or call.status == 'closed' then return cb(fail('Appel introuvable ou clôturé')) end
    local found
    for i, u in ipairs(call.units) do if u.src == src then found = i end end
    if found then table.remove(call.units, found) if #call.units == 0 then call.status = 'open' end
    else call.units[#call.units + 1] = { src = src, name = JB.playerName(x) } call.status = 'taken' end
    cb({ ok = true, x = call.x, y = call.y, joined = not found })
end)

ESX.RegisterServerCallback('jobbuilder:dispatch:close', function(src, cb, id)
    local x, job, s, err = ctx(src, 'dispatch')
    if not x then return cb(fail(err)) end
    local call = findCall(job.name, id)
    if not call then return cb(fail('Appel introuvable')) end
    call.status, call.closedAt = 'closed', os.time()
    cb({ ok = true })
end)

ESX.RegisterServerCallback('jobbuilder:dispatch:delete', function(src, cb, id)
    local x, job, s, err = ctx(src, 'admin')
    if not x then return cb(fail(err)) end
    local c = jobCalls(job.name)
    for i, call in ipairs(c.list) do if call.id == tonumber(id) then table.remove(c.list, i) break end end
    cb({ ok = true })
end)

-- ── Poursuite ──
ESX.RegisterServerCallback('jobbuilder:pursuit:nearby', function(src, cb)
    local x, job, s, err = ctx(src, 'pursuit')
    if not x then return cb(fail(err)) end
    local me = GetEntityCoords(GetPlayerPed(src))
    local out = {}
    for _, id in ipairs(GetPlayers()) do
        id = tonumber(id)
        if id ~= src then
            local t = ESX.GetPlayerFromId(id)
            local ped = GetPlayerPed(id)
            if t and ped and ped ~= 0 then
                local d = #(GetEntityCoords(ped) - me)
                if d <= P.NearbyRange then
                    local first, last = identity(t)
                    out[#out + 1] = { src = id, name = first .. ' ' .. last, dist = math.floor(d), veh = GetVehiclePedIsIn(ped, false) ~= 0, mate = t.job.name == job.name }
                end
            end
        end
    end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    cb({ ok = true, list = out, active = pursuits[job.name] ~= nil })
end)

ESX.RegisterServerCallback('jobbuilder:pursuit:start', function(src, cb, targetId)
    local x, job, s, err = ctx(src, 'pursuit')
    if not x then return cb(fail(err)) end
    local target = ESX.GetPlayerFromId(tonumber(targetId))
    if not target or target.source == src then return cb(fail('Suspect introuvable')) end
    local tp, mp = GetEntityCoords(GetPlayerPed(target.source)), GetEntityCoords(GetPlayerPed(src))
    if #(tp - mp) > P.NearbyRange + 20.0 then return cb(fail('Le suspect est trop loin')) end
    local first, last = identity(target)
    local name = first .. ' ' .. last
    if pursuits[job.name] then endPursuit(job.name, 'nouvelle poursuite') end
    local call = addCall(job.name, { title = 'Poursuite en cours', message = ('Suspect : %s — lancée par %s'):format(name, JB.playerName(x)), kind = 'pursuit', x = tp.x, y = tp.y, z = tp.z, by = JB.playerName(x) })
    call.status = 'taken'
    pursuits[job.name] = { target = target.source, name = name, identifier = target.identifier, by = JB.playerName(x), started = os.time(), call = call.id }
    startPursuitThread()
    JB.log(job.name, x, 'pursuit_start', name)
    cb({ ok = true })
end)

ESX.RegisterServerCallback('jobbuilder:pursuit:stop', function(src, cb)
    local x, job, s, err = ctx(src, 'dispatch')
    if not x then return cb(fail(err)) end
    endPursuit(job.name, 'arrêtée par ' .. JB.playerName(x))
    cb({ ok = true })
end)

-- ═══════════════════════════ Bracelets électroniques ═══════════════════════════
-- Un agent pose un bracelet sur un joueur proche. Le serveur relève sa position toutes les quelques secondes ; si une zone est définie et que le porteur en sort,
-- une alerte part au dispatch du service. Le bracelet ne se retire que par la tablette d'un agent habilité. Tout est décidé côté serveur (distance, grades, zone).
local function BR() return P.Bracelets or {} end
local braceletsLive = {}      -- [id] = { x, y, z, at, out, alertAt }

CreateThread(function()
    Wait(2500)
    pcall(MySQL.query.await, [[CREATE TABLE IF NOT EXISTS jobbuilder_bracelets (id INT AUTO_INCREMENT PRIMARY KEY, job_name VARCHAR(60) NOT NULL, identifier VARCHAR(80) NOT NULL,
        name VARCHAR(100) NOT NULL, placed_by VARCHAR(100) NULL, placed_at INT NOT NULL, zone_x DOUBLE NULL, zone_y DOUBLE NULL, zone_z DOUBLE NULL, zone_r DOUBLE NULL,
        last_x DOUBLE NULL, last_y DOUBLE NULL, last_z DOUBLE NULL, last_at INT NULL, UNIQUE KEY uq_ident (identifier), INDEX (job_name)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    pcall(MySQL.query.await, 'ALTER TABLE jobbuilder_bracelets ADD COLUMN expires_at INT NULL')   -- bracelets de liberté sous caution : fin automatique
end)

local function bracelet(id, jobName)
    return MySQL.single.await('SELECT * FROM jobbuilder_bracelets WHERE id = ? AND job_name = ?', { tonumber(id) or 0, jobName })
end

-- Joueur connecté portant ce bracelet (xPlayer) ou nil
local function wearer(identifier)
    return ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(identifier) or nil
end

-- Distance au centre de la zone (nil si pas de zone)
function JB.braceletOutside(b, x, y)
    if not b.zone_r or not b.zone_x then return false end
    local dx, dy = x - b.zone_x, y - b.zone_y
    return dx * dx + dy * dy > b.zone_r * b.zone_r
end

local function braceletView(b)
    local w = wearer(b.identifier)
    local live = braceletsLive[b.id]
    local x, y, z, at = b.last_x, b.last_y, b.last_z, b.last_at
    if w then
        local ped = GetPlayerPed(w.source)
        if ped and ped ~= 0 then local c = GetEntityCoords(ped) x, y, z, at = c.x, c.y, c.z, os.time() end
    end
    return { id = b.id, name = b.name, by = b.placed_by, placedAt = b.placed_at, online = w ~= nil, x = x, y = y, z = z, seen = at,
        zone = b.zone_r and { x = b.zone_x, y = b.zone_y, r = b.zone_r } or nil, out = (live and live.out) or false,
        outNow = w ~= nil and x ~= nil and JB.braceletOutside(b, x, y) or false }
end

ESX.RegisterServerCallback('jobbuilder:bracelet:list', function(src, cb)
    local x, job, s, err = ctx(src, 'bracelet')
    if not x then return cb(fail(err)) end
    local rows = MySQL.query.await('SELECT * FROM jobbuilder_bracelets WHERE job_name = ? ORDER BY id DESC', { job.name }) or {}
    local list = {}
    for _, b in ipairs(rows) do list[#list + 1] = braceletView(b) end
    cb({ ok = true, list = list, max = BR().MaxPerJob or 30, zoneMin = BR().ZoneMin or 20, zoneMax = BR().ZoneMax or 2000 })
end)

-- Joueurs à portée pour poser un bracelet
ESX.RegisterServerCallback('jobbuilder:bracelet:nearby', function(src, cb)
    local x, job, s, err = ctx(src, 'bracelet')
    if not x then return cb(fail(err)) end
    local me = GetEntityCoords(GetPlayerPed(src))
    local out = {}
    for _, id in ipairs(GetPlayers()) do
        id = tonumber(id)
        local t = id ~= src and ESX.GetPlayerFromId(id)
        local ped = t and GetPlayerPed(id)
        if t and ped and ped ~= 0 then
            local d = #(GetEntityCoords(ped) - me)
            if d <= (BR().Distance or 4.0) + 1.0 then
                local first, last = identity(t)
                out[#out + 1] = { src = id, name = first .. ' ' .. last, dist = math.floor(d * 10) / 10 }
            end
        end
    end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    cb({ ok = true, list = out })
end)

local function placeBracelet(src, targetId)
    local x, job, s, err = ctx(src, 'bracelet')
    if not x then return false, err end
    local t = ESX.GetPlayerFromId(tonumber(targetId))
    if not t or t.source == src then return false, 'Aucune personne ciblée' end
    local a, b = GetPlayerPed(src), GetPlayerPed(t.source)
    if not a or a == 0 or not b or b == 0 or #(GetEntityCoords(a) - GetEntityCoords(b)) > (BR().Distance or 4.0) + 1.0 then return false, 'La personne est trop loin' end
    if MySQL.scalar.await('SELECT COUNT(*) FROM jobbuilder_bracelets WHERE identifier = ?', { t.identifier }) > 0 then return false, 'Cette personne porte déjà un bracelet' end
    if MySQL.scalar.await('SELECT COUNT(*) FROM jobbuilder_bracelets WHERE job_name = ?', { job.name }) >= (BR().MaxPerJob or 30) then return false, 'Nombre maximal de bracelets atteint' end
    local first, last = identity(t)
    local id = MySQL.insert.await('INSERT INTO jobbuilder_bracelets (job_name, identifier, name, placed_by, placed_at) VALUES (?, ?, ?, ?, ?)',
        { job.name, t.identifier, first .. ' ' .. last, JB.playerName(x), os.time() })
    local rid = ensureRecord(job.name, t, JB.playerName(x))
    addEntry(rid, job.name, 'note', 'Bracelet électronique posé', 0, nil, JB.playerName(x))
    JB.log(job.name, x, 'bracelet_placed', first .. ' ' .. last)
    JBNotifyClient(t.source, '~r~Un bracelet électronique vient d\'être posé à ta cheville. Ta position est suivie par la police.')
    return true, id
end

ESX.RegisterServerCallback('jobbuilder:bracelet:place', function(src, cb, targetId)
    local ok, res = placeBracelet(src, targetId)
    cb(ok and { ok = true, id = res } or fail(res))
end)

RegisterCommand(BR().Command or 'bracelet', function(src, args)
    if src == 0 then return end
    local ok, res = placeBracelet(src, args[1])
    JBNotifyClient(src, ok and '~g~Bracelet posé.' or ('~r~' .. tostring(res)))
end, false)

ESX.RegisterServerCallback('jobbuilder:bracelet:remove', function(src, cb, id)
    local x, job, s, err = ctx(src, 'bracelet')
    if not x then return cb(fail(err)) end
    local b = bracelet(id, job.name)
    if not b then return cb(fail('Bracelet introuvable')) end
    MySQL.update.await('DELETE FROM jobbuilder_bracelets WHERE id = ?', { b.id })
    braceletsLive[b.id] = nil
    JB.log(job.name, x, 'bracelet_removed', b.name)
    local w = wearer(b.identifier)
    if w then JBNotifyClient(w.source, '~g~Ton bracelet électronique a été retiré.') end
    cb({ ok = true })
end)

-- Définit (ou retire avec rayon 0) la zone autorisée : centrée sur la position de l'agent
ESX.RegisterServerCallback('jobbuilder:bracelet:zone', function(src, cb, id, radius)
    local x, job, s, err = ctx(src, 'bracelet')
    if not x then return cb(fail(err)) end
    local b = bracelet(id, job.name)
    if not b then return cb(fail('Bracelet introuvable')) end
    radius = tonumber(radius) or 0
    if radius <= 0 then
        MySQL.update.await('UPDATE jobbuilder_bracelets SET zone_x = NULL, zone_y = NULL, zone_z = NULL, zone_r = NULL WHERE id = ?', { b.id })
        if braceletsLive[b.id] then braceletsLive[b.id].out = false end
        return cb({ ok = true, cleared = true })
    end
    radius = math.max(BR().ZoneMin or 20, math.min(BR().ZoneMax or 2000, radius))
    local c = GetEntityCoords(GetPlayerPed(src))
    MySQL.update.await('UPDATE jobbuilder_bracelets SET zone_x = ?, zone_y = ?, zone_z = ?, zone_r = ? WHERE id = ?', { c.x, c.y, c.z, radius, b.id })
    if braceletsLive[b.id] then braceletsLive[b.id].out = false end
    JB.log(job.name, x, 'bracelet_zone', ('%s : %d m'):format(b.name, math.floor(radius)))
    cb({ ok = true, r = radius })
end)

-- Relevé des positions : alerte au dispatch quand un porteur quitte sa zone, mémorise la dernière position connue
CreateThread(function()
    while true do
        Wait(math.max(3, tonumber(BR().Interval) or 10) * 1000)
        if BR().Enabled ~= false then
            local ok, rows = pcall(MySQL.query.await, 'SELECT * FROM jobbuilder_bracelets')
            for _, b in ipairs(ok and rows or {}) do
                local w = wearer(b.identifier)
                local ped = w and GetPlayerPed(w.source)
                if ped and ped ~= 0 then
                    local c = GetEntityCoords(ped)
                    local live = braceletsLive[b.id] or {}
                    braceletsLive[b.id] = live
                    live.x, live.y, live.z, live.at = c.x, c.y, c.z, os.time()
                    local outside = JB.braceletOutside(b, c.x, c.y)
                    if outside and (not live.out or os.time() - (live.alertAt or 0) >= (BR().EscapeCooldown or 120)) then
                        live.out, live.alertAt = true, os.time()
                        if JB.Jobs[b.job_name] then
                            addCall(b.job_name, { title = 'Bracelet : hors zone', message = ('%s a quitté sa zone autorisée.'):format(b.name), kind = 'alert', x = c.x, y = c.y, z = c.z, by = 'Bracelet électronique' })
                        end
                    elseif not outside then live.out = false end
                end
            end
        end
    end
end)

-- Dernière position connue conservée quand le porteur se déconnecte
AddEventHandler('playerDropped', function()
    local src = source
    local x = ESX.GetPlayerFromId(src)
    if not x then return end
    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 then
        local c = GetEntityCoords(ped)
        MySQL.update('UPDATE jobbuilder_bracelets SET last_x = ?, last_y = ?, last_z = ?, last_at = ? WHERE identifier = ?', { c.x, c.y, c.z, os.time(), x.identifier })
    end
end)

AddEventHandler('esx:playerLoaded', function(src, xPlayer)
    xPlayer = xPlayer or ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    SetTimeout(8000, function()
        local n = MySQL.scalar.await('SELECT COUNT(*) FROM jobbuilder_bracelets WHERE identifier = ?', { xPlayer.identifier }) or 0
        if n > 0 then JBNotifyClient(src, '~r~Tu portes un bracelet électronique : ta position est suivie par la police.') end
    end)
end)

-- Bracelet posé sans agent (liberté sous caution) : durée en heures, zone facultative { x, y, r }
exports('AutoBracelet', function(targetSrc, jobName, hours, byLabel, zone)
    local t = ESX.GetPlayerFromId(tonumber(targetSrc))
    if not t or not JB.Jobs[jobName] then return false end
    if (MySQL.scalar.await('SELECT COUNT(*) FROM jobbuilder_bracelets WHERE identifier = ?', { t.identifier }) or 0) > 0 then return false end
    local first, last = identity(t)
    local z = type(zone) == 'table' and zone or {}
    MySQL.insert.await('INSERT INTO jobbuilder_bracelets (job_name, identifier, name, placed_by, placed_at, zone_x, zone_y, zone_r, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { jobName, t.identifier, first .. ' ' .. last, byLabel or 'Liberté sous caution', os.time(), z.x, z.y, z.r, os.time() + math.max(1, math.floor(tonumber(hours) or 24)) * 3600 })
    JBNotifyClient(t.source, '~r~Tu es libre sous caution et portes un bracelet électronique : ne quitte pas ta zone.')
    return true
end)

-- Fin automatique des bracelets de caution
CreateThread(function()
    while true do
        Wait(60000)
        pcall(MySQL.update.await, 'DELETE FROM jobbuilder_bracelets WHERE expires_at IS NOT NULL AND expires_at < ?', { os.time() })
    end
end)

exports('HasBracelet', function(identifier)
    return (MySQL.scalar.await('SELECT COUNT(*) FROM jobbuilder_bracelets WHERE identifier = ?', { identifier }) or 0) > 0
end)
