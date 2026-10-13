-- ─────────────────────────────── Tablette médicale EMS ───────────────────────────────
-- Urgences en direct (partagées avec l'alerte de mort), dossiers patients, facturation des soins, équipe, statistiques.
-- Dossiers et soins sont strictement séparés par job (job_name sur chaque requête).

local E = Config.Ems
local function fail(msg) return { ok = false, error = msg } end

local function str(v, max, default)
    if type(v) ~= 'string' then return default or '' end
    return (v:gsub('%c', ' ')):sub(1, max)
end

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

local function members(jobName)
    local ok, list = pcall(ESX.GetExtendedPlayers, 'job', jobName)
    return ok and list or {}
end

-- Contexte : joueur, job, droits. need = 'admin' | 'care'
local function ctx(src, need)
    local x = ESX.GetPlayerFromId(src)
    if not x then return nil, nil, nil, 'Joueur introuvable' end
    local job = JB.Jobs[x.job.name]
    if not job then return nil, nil, nil, 'Ton métier n\'a pas de tablette médicale' end
    local s = job.settings or {}
    local allowed = job.type == 'ems' and s.ems_tablet_enabled ~= false
    if not allowed then return nil, nil, nil, 'Ton métier n\'a pas accès à la tablette médicale' end
    local g = x.job.grade
    if g < (s.ems_tablet_grade or 0) then return nil, nil, nil, 'Ton grade ne permet pas d\'ouvrir la tablette' end
    local perms = { admin = g >= (s.ems_admin_grade or job.boss_grade), care = g >= (s.care_grade or 0) }
    if need and not perms[need] then return nil, nil, nil, 'Ton grade ne permet pas cette action' end
    return x, job, s, nil, perms
end

local function patientOf(jobName, id)
    return MySQL.single.await('SELECT * FROM jobbuilder_patients WHERE id = ? AND job_name = ?', { tonumber(id) or 0, jobName })
end

local function addEntry(pid, jobName, kind, label, amount, details, officer)
    MySQL.insert.await('INSERT INTO jobbuilder_patient_entries (patient_id, job_name, kind, label, amount, details, officer) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { pid, jobName, kind, str(label, 120), math.floor(tonumber(amount) or 0), details and str(details, 1000) or nil, officer })
    MySQL.update('UPDATE jobbuilder_patients SET updated_at = NOW() WHERE id = ?', { pid })
end

local function ensurePatient(jobName, target, officer)
    local row = MySQL.single.await('SELECT id FROM jobbuilder_patients WHERE job_name = ? AND identifier = ?', { jobName, target.identifier })
    if row then return row.id end
    local first, last, dob = identity(target)
    return MySQL.insert.await('INSERT INTO jobbuilder_patients (job_name, identifier, firstname, lastname, birthdate, created_by) VALUES (?, ?, ?, ?, ?, ?)',
        { jobName, target.identifier, first, last, dob, officer })
end

local validBlood = {}
for _, b in ipairs(E.BloodTypes) do validBlood[b] = true end

-- ── Ouverture ──
ESX.RegisterServerCallback('jobbuilder:emstab:open', function(src, cb)
    local x, job, s, err, perms = ctx(src)
    if not x then return cb(fail(err)) end
    local care = (s.care_prices and #s.care_prices > 0) and s.care_prices or E.DefaultCare
    cb({ ok = true, job = job.name, jobLabel = job.label, grade = x.job.grade, gradeLabel = x.job.grade_label, me = { src = src, name = JB.playerName(x) },
        perms = perms, care = care, careCustom = s.care_custom ~= false, limits = { min = E.MinCare, max = E.MaxCare }, blood = E.BloodTypes,
        deathActive = JB.deathActive and JB.deathActive() or false })
end)

-- ── Urgences + équipe (rafraîchi toutes les 2 s) ──
ESX.RegisterServerCallback('jobbuilder:emstab:live', function(src, cb)
    local x, job, s, err = ctx(src)
    if not x then return cb(fail(err)) end
    local busy = JB.emsBusy and JB.emsBusy() or {}
    local me = GetEntityCoords(GetPlayerPed(src))
    local team = {}
    for _, m in ipairs(members(job.name)) do
        local ped = GetPlayerPed(m.source)
        local d = (ped and ped ~= 0) and math.floor(#(GetEntityCoords(ped) - me)) or nil
        team[#team + 1] = { src = m.source, name = JB.playerName(m), grade = m.job.grade_label, busy = busy[m.source] == true, dist = d, me = m.source == src }
    end
    table.sort(team, function(a, b) return a.name < b.name end)
    cb({ ok = true, calls = JB.emsCallList and JB.emsCallList(src) or {}, team = team })
end)

ESX.RegisterServerCallback('jobbuilder:emstab:createCall', function(src, cb, title)
    local x, job, s, err = ctx(src)
    if not x then return cb(fail(err)) end
    title = str(tostring(title or ''), 60)
    if #title < 3 then return cb(fail('Décris l\'urgence (3 caractères minimum)')) end
    if not JB.emsCreate or not JB.emsCreate(src, title) then return cb(fail('Impossible de créer l\'urgence')) end
    cb({ ok = true })
end)

-- ── Statistiques (30 jours) ──
ESX.RegisterServerCallback('jobbuilder:emstab:stats', function(src, cb)
    local x, job, s, err = ctx(src)
    if not x then return cb(fail(err)) end
    local function count(sql, ...) return MySQL.scalar.await(sql, { job.name, ... }) or 0 end
    local top = MySQL.query.await("SELECT player_name AS name, COUNT(*) AS n FROM jobbuilder_logs WHERE job_name = ? AND action IN ('revive', 'ems_take', 'care') AND created_at > (NOW() - INTERVAL 30 DAY) GROUP BY player_name ORDER BY n DESC LIMIT 5", { job.name }) or {}
    cb({ ok = true,
        patients = count('SELECT COUNT(*) FROM jobbuilder_patients WHERE job_name = ?'),
        revives = count("SELECT COUNT(*) FROM jobbuilder_logs WHERE job_name = ? AND action = 'revive' AND created_at > (NOW() - INTERVAL 30 DAY)"),
        responses = count("SELECT COUNT(*) FROM jobbuilder_logs WHERE job_name = ? AND action = 'ems_take' AND created_at > (NOW() - INTERVAL 30 DAY)"),
        cares = count("SELECT COUNT(*) FROM jobbuilder_patient_entries WHERE job_name = ? AND kind = 'care' AND created_at > (NOW() - INTERVAL 30 DAY)"),
        income = count("SELECT COALESCE(SUM(amount), 0) FROM jobbuilder_patient_entries WHERE job_name = ? AND kind = 'care' AND created_at > (NOW() - INTERVAL 30 DAY)"),
        top = top })
end)

-- ── Dossiers patients ──
ESX.RegisterServerCallback('jobbuilder:patients:search', function(src, cb, q)
    local x, job, s, err = ctx(src)
    if not x then return cb(fail(err)) end
    q = str(tostring(q or ''), 60):gsub('[%%_\\]', '\\%0')
    local like = '%' .. q .. '%'
    local rows = MySQL.query.await([[SELECT p.id, p.firstname, p.lastname, p.birthdate, p.blood,
        (SELECT COUNT(*) FROM jobbuilder_patient_entries e WHERE e.patient_id = p.id) AS n
        FROM jobbuilder_patients p WHERE p.job_name = ? AND (? = '' OR CONCAT(p.firstname, ' ', p.lastname) LIKE ? OR CONCAT(p.lastname, ' ', p.firstname) LIKE ?)
        ORDER BY p.updated_at DESC LIMIT 60]], { job.name, q, like, like }) or {}
    local out = {}
    for _, r in ipairs(rows) do out[#out + 1] = { id = r.id, name = r.firstname .. ' ' .. r.lastname, birthdate = r.birthdate, blood = r.blood, n = r.n } end
    cb({ ok = true, list = out })
end)

ESX.RegisterServerCallback('jobbuilder:patients:get', function(src, cb, id)
    local x, job, s, err = ctx(src)
    if not x then return cb(fail(err)) end
    local p = patientOf(job.name, id)
    if not p then return cb(fail('Dossier introuvable')) end
    local entries = MySQL.query.await('SELECT id, kind, label, amount, details, officer, UNIX_TIMESTAMP(created_at) AS t FROM jobbuilder_patient_entries WHERE patient_id = ? AND job_name = ? ORDER BY id DESC LIMIT 100', { p.id, job.name }) or {}
    local paid = 0
    for _, e in ipairs(entries) do if e.kind == 'care' then paid = paid + e.amount end end
    cb({ ok = true, patient = { id = p.id, firstname = p.firstname, lastname = p.lastname, birthdate = p.birthdate or '', blood = p.blood or '', allergies = p.allergies or '', notes = p.notes or '', created_by = p.created_by }, entries = entries, paid = paid })
end)

ESX.RegisterServerCallback('jobbuilder:patients:save', function(src, cb, rec)
    local x, job, s, err = ctx(src)
    if not x then return cb(fail(err)) end
    rec = type(rec) == 'table' and rec or {}
    local first, last = str(rec.firstname, 50), str(rec.lastname, 50)
    if first == '' or last == '' then return cb(fail('Nom et prénom obligatoires')) end
    local blood = validBlood[rec.blood] and rec.blood or nil
    local birth, allergies, notes = str(rec.birthdate, 20), str(rec.allergies, 300), str(rec.notes, 2000)
    local id = tonumber(rec.id)
    if id then
        if not patientOf(job.name, id) then return cb(fail('Dossier introuvable')) end
        MySQL.update.await('UPDATE jobbuilder_patients SET firstname = ?, lastname = ?, birthdate = ?, blood = ?, allergies = ?, notes = ? WHERE id = ? AND job_name = ?',
            { first, last, birth ~= '' and birth or nil, blood, allergies ~= '' and allergies or nil, notes, id, job.name })
    else
        id = MySQL.insert.await('INSERT INTO jobbuilder_patients (job_name, firstname, lastname, birthdate, blood, allergies, notes, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            { job.name, first, last, birth ~= '' and birth or nil, blood, allergies ~= '' and allergies or nil, notes, JB.playerName(x) })
        JB.log(job.name, x, 'patient_created', first .. ' ' .. last)
    end
    cb({ ok = true, id = id })
end)

ESX.RegisterServerCallback('jobbuilder:patients:delete', function(src, cb, id)
    local x, job, s, err = ctx(src, 'admin')
    if not x then return cb(fail(err)) end
    local p = patientOf(job.name, id)
    if not p then return cb(fail('Dossier introuvable')) end
    MySQL.update.await('DELETE FROM jobbuilder_patient_entries WHERE patient_id = ? AND job_name = ?', { p.id, job.name })
    MySQL.update.await('DELETE FROM jobbuilder_patients WHERE id = ? AND job_name = ?', { p.id, job.name })
    JB.log(job.name, x, 'patient_deleted', p.firstname .. ' ' .. p.lastname)
    cb({ ok = true })
end)

local ENTRY_KINDS = { consult = true, care = true, surgery = true, prescription = true, observation = true, death = true }

ESX.RegisterServerCallback('jobbuilder:patients:addEntry', function(src, cb, pid, kind, label, amount, details)
    local x, job, s, err = ctx(src)
    if not x then return cb(fail(err)) end
    local p = patientOf(job.name, pid)
    if not p then return cb(fail('Dossier introuvable')) end
    if not ENTRY_KINDS[kind] then return cb(fail('Type d\'entrée invalide')) end
    label = str(label, 120)
    if label == '' then return cb(fail('Le motif est obligatoire')) end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 0 or amount > E.MaxCare * 100 then return cb(fail('Montant invalide')) end
    addEntry(p.id, job.name, kind, label, amount, details, JB.playerName(x))
    cb({ ok = true })
end)

ESX.RegisterServerCallback('jobbuilder:patients:delEntry', function(src, cb, entryId)
    local x, job, s, err = ctx(src, 'admin')
    if not x then return cb(fail(err)) end
    MySQL.update.await('DELETE FROM jobbuilder_patient_entries WHERE id = ? AND job_name = ?', { tonumber(entryId) or 0, job.name })
    cb({ ok = true })
end)

-- (placeholder, joueur proche) : crée ou retrouve le dossier de la personne devant soi
ESX.RegisterServerCallback('jobbuilder:patients:fromNearest', function(src, cb, _, targetId)
    local x, job, s, err = ctx(src)
    if not x then return cb(fail(err)) end
    local target = ESX.GetPlayerFromId(tonumber(targetId))
    if not target or not JB.playersClose(src, target.source) then return cb(fail('Aucune personne à proximité')) end
    cb({ ok = true, id = ensurePatient(job.name, target, JB.playerName(x)) })
end)

-- ── Facturation d'un soin : (dossier optionnel, joueur proche [injecté], n° du catalogue ou 0, motif, montant, remarque) ──
ESX.RegisterServerCallback('jobbuilder:care:send', function(src, cb, pid, targetId, idx, label, amount, note)
    local x, job, s, err = ctx(src, 'care')
    if not x then return cb(fail(err)) end
    local target = ESX.GetPlayerFromId(tonumber(targetId))
    if not target or target.source == src or not JB.playersClose(src, target.source) then return cb(fail('Aucun patient à proximité')) end
    idx = math.floor(tonumber(idx) or 0)
    if idx > 0 then
        local list = (s.care_prices and #s.care_prices > 0) and s.care_prices or E.DefaultCare
        local f = list[idx]
        if not f then return cb(fail('Soin inconnu')) end
        label, amount = f.label, f.amount
    else
        if s.care_custom == false then return cb(fail('Les soins libres sont désactivés pour ce job')) end
        label, amount = str(label, 60), math.floor(tonumber(amount) or 0)
        if label == '' then return cb(fail('Le motif est obligatoire')) end
    end
    if amount < E.MinCare or amount > E.MaxCare then return cb(fail(('Montant invalide (%d à %d $)'):format(E.MinCare, E.MaxCare))) end

    local officer = JB.playerName(x)
    local rid
    if tonumber(pid) then
        local p = patientOf(job.name, pid)
        if p then
            rid = p.id
            if not p.identifier then MySQL.update('UPDATE jobbuilder_patients SET identifier = ? WHERE id = ? AND job_name = ?', { target.identifier, p.id, job.name }) end
        end
    end
    rid = rid or ensurePatient(job.name, target, officer)
    note = note and str(tostring(note), 500) or nil

    JB.sendInvoice(x, target, 'Soins : ' .. label, amount, nil, {
        onPaid = function() addEntry(rid, job.name, 'care', label, amount, note, officer) JB.log(job.name, x, 'care', ('%s : %d$'):format(label, amount)) end,
        onRefused = function(why) addEntry(rid, job.name, 'observation', (why == 'unpaid' and 'Soins impayés : ' or 'Soins refusés : ') .. label, amount, note, officer) end,
    })
    cb({ ok = true })
end)
