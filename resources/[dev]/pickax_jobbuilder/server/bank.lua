-- ─────────────────────────────── Banque : tablette bancaire (jobs de type bank) ───────────────────────────────
-- Fiches clients (cote, notes, historique), prêts avec remboursement automatique, guichet (dépôt / retrait avec l'accord du client),
-- frais facturés, statistiques.  Toutes les données sont isolées par job (job_name sur chaque requête).

local B = Config.Bank
local function fail(msg) return { ok = false, error = msg } end

local function str(v, max, default)
    if type(v) ~= 'string' then return default or '' end
    return (v:gsub('%c', ' ')):sub(1, max)
end

local function identity(x)
    local first = x.get and x.get('firstName') or nil
    local last = x.get and x.get('lastName') or nil
    if not first or first == '' then
        local name = JB.playerName(x)
        first, last = name:match('^(%S+)%s+(.+)$')
        first, last = first or name, last or ''
    end
    return str(tostring(first), 50), str(tostring(last or ''), 50)
end

local function intIn(v, min, max, default)
    v = tonumber(v)
    if not v or v ~= v then return default end
    v = math.floor(v)
    if v < min or v > max then return default end
    return v
end

local validRating, validTerm = {}, {}
for _, r in ipairs(B.Ratings) do validRating[r] = true end
for _, t in ipairs(B.Terms) do validTerm[t] = true end

-- Contexte : joueur, job, réglages, droits
local function ctx(src, need)
    local x = ESX.GetPlayerFromId(src)
    if not x then return nil, nil, nil, 'Joueur introuvable' end
    local job = JB.Jobs[x.job.name]
    if not job or job.type ~= 'bank' or (job.settings or {}).bank_tablet_enabled == false then return nil, nil, nil, 'Ton métier n\'a pas accès à la tablette bancaire' end
    local s = job.settings or {}
    local g = x.job.grade
    if g < (s.bank_tablet_grade or 0) then return nil, nil, nil, 'Ton grade ne permet pas d\'ouvrir la tablette' end
    local perms = {
        admin = g >= (s.bank_admin_grade or job.boss_grade),
        loan = g >= (s.bank_loan_grade or 0) and s.bank_loans ~= false and job.society == true,
        fee = g >= (s.bank_fee_grade or 0),
        ops = g >= (s.bank_fee_grade or 0) and s.bank_ops ~= false,
    }
    if need and not perms[need] then
        if need == 'loan' and not job.society then return nil, nil, nil, 'Les prêts nécessitent un compte société pour ce job' end
        return nil, nil, nil, 'Ton grade ne permet pas cette action'
    end
    return x, job, s, nil, perms
end

local function clientOf(jobName, id)
    return MySQL.single.await('SELECT * FROM jobbuilder_bank_clients WHERE id = ? AND job_name = ?', { tonumber(id) or 0, jobName })
end

local function addEntry(cid, jobName, kind, label, amount, officer)
    MySQL.insert.await('INSERT INTO jobbuilder_bank_entries (client_id, job_name, kind, label, amount, officer) VALUES (?, ?, ?, ?, ?, ?)',
        { cid, jobName, kind, str(label, 120), math.floor(tonumber(amount) or 0), officer })
    MySQL.update('UPDATE jobbuilder_bank_clients SET updated_at = NOW() WHERE id = ?', { cid })
end

local function ensureClient(jobName, target, officer)
    local row = MySQL.single.await('SELECT id FROM jobbuilder_bank_clients WHERE job_name = ? AND identifier = ?', { jobName, target.identifier })
    if row then return row.id end
    local first, last = identity(target)
    return MySQL.insert.await('INSERT INTO jobbuilder_bank_clients (job_name, identifier, firstname, lastname, created_by) VALUES (?, ?, ?, ?, ?)',
        { jobName, target.identifier, first, last, officer })
end

local function members(jobName)
    local ok, list = pcall(ESX.GetExtendedPlayers, 'job', jobName)
    return ok and list or {}
end

local function notify(src, msg) if src then JBNotifyClient( src, msg) end end
local function money(n) return tostring(math.floor(n)):reverse():gsub('(%d%d%d)', '%1 '):reverse():gsub('^ ', '') .. ' $' end

local function ratingLimit(rating, max)
    return math.floor(max * ((B.RatingLimit or {})[rating] or 0) / 100)
end

local function outstanding(l) return l.installment * l.left_count + l.penalties end

-- ─────────────────────────────── Remboursement automatique ───────────────────────────────
local busy = {}

-- Prélève l'échéance (+ pénalités) sur le compte bancaire du client. Retourne 'paid' | 'late'
local function collect(loan, x)
    if busy[loan.id] then return 'skip' end
    busy[loan.id] = true
    local job = JB.Jobs[loan.job_name]
    local due = loan.installment + loan.penalties
    local result
    if x.getAccount('bank').money >= due then
        x.removeAccountMoney('bank', due)
        if job and job.society then JB.societyAdd(loan.job_name, due) end
        local left = loan.left_count - 1
        local status = left <= 0 and 'paid' or 'active'
        MySQL.update.await(('UPDATE jobbuilder_bank_loans SET paid = paid + ?, left_count = ?, penalties = 0, status = ?, next_due = DATE_ADD(NOW(), INTERVAL %d HOUR) WHERE id = ?'):format(B.IntervalHours),
            { loan.installment, left, status, loan.id })
        addEntry(loan.client_id, loan.job_name, 'payment', ('Échéance prélevée (%d/%d)'):format(loan.installments - left, loan.installments) .. (loan.penalties > 0 and (' + pénalités ' .. loan.penalties .. ' $') or ''), due, 'Système')
        notify(x.source, ('~b~[Banque]~s~ Échéance de ~g~%s~s~ prélevée.%s'):format(money(due), status == 'paid' and ' ~g~ Prêt entièrement remboursé, merci !' or ''))
        if status == 'paid' then addEntry(loan.client_id, loan.job_name, 'note', 'Prêt #' .. loan.id .. ' soldé', 0, 'Système') end
        result = 'paid'
    else
        local lateCount = loan.late_count + 1
        local penalty = math.ceil(loan.installment * B.LateFeePct / 100)
        local status = lateCount >= B.DefaultAfter and 'defaulted' or 'late'
        MySQL.update.await(('UPDATE jobbuilder_bank_loans SET late_count = ?, penalties = penalties + ?, status = ?, next_due = DATE_ADD(NOW(), INTERVAL %d HOUR) WHERE id = ?'):format(B.RetryHours),
            { lateCount, penalty, status, loan.id })
        addEntry(loan.client_id, loan.job_name, 'late', ('Échéance impayée (retard n°%d, pénalité %d $)'):format(lateCount, penalty), due, 'Système')
        if status == 'defaulted' then MySQL.update('UPDATE jobbuilder_bank_clients SET rating = ? WHERE id = ?', { 'E', loan.client_id }) end
        notify(x.source, ('~b~[Banque]~s~ ~r~Échéance impayée~s~ de %s : approvisionne ton compte bancaire (pénalité %s).'):format(money(due), money(penalty)))
        result = 'late'
    end
    busy[loan.id] = nil
    return result
end

local function collectFor(identifier)
    local x = ESX.GetPlayerFromIdentifier(identifier)
    if not x then return end
    local rows = MySQL.query.await("SELECT * FROM jobbuilder_bank_loans WHERE identifier = ? AND status IN ('active','late','defaulted') AND next_due <= NOW() ORDER BY id", { identifier }) or {}
    for _, l in ipairs(rows) do collect(l, x) end
end

CreateThread(function()
    Wait(15000)
    while true do
        local rows = MySQL.query.await("SELECT DISTINCT identifier FROM jobbuilder_bank_loans WHERE status IN ('active','late','defaulted') AND next_due <= NOW()") or {}
        for _, r in ipairs(rows) do pcall(collectFor, r.identifier) end
        Wait(math.max(10, B.CheckSeconds) * 1000)
    end
end)

AddEventHandler('esx:playerLoaded', function(src, xPlayer)
    local id = xPlayer and xPlayer.identifier
    if not id then return end
    SetTimeout(25000, function() pcall(collectFor, id) end)
end)

-- ─────────────────────────────── Ouverture ───────────────────────────────
ESX.RegisterServerCallback('jobbuilder:bank:open', function(src, cb)
    local x, job, s, err, perms = ctx(src)
    if not x then return cb(fail(err)) end
    local fees = (s.bank_fees and #s.bank_fees > 0) and s.bank_fees or B.DefaultFees
    cb({ ok = true, job = job.name, jobLabel = job.label, grade = x.job.grade, gradeLabel = x.job.grade_label, perms = perms, fees = fees, society = job.society == true,
        limits = { minLoan = B.MinLoan, maxLoan = s.bank_loan_max or 100000, minRate = s.bank_rate_min or 0, maxRate = s.bank_rate_max or 25, terms = B.Terms, interval = B.IntervalHours,
            lateFee = B.LateFeePct, maxActive = B.MaxActive, minOp = B.MinOp, maxOp = B.MaxOp, minFee = B.MinFee, maxFee = B.MaxFee, defaultAfter = B.DefaultAfter },
        ratings = B.Ratings, ratingLimit = B.RatingLimit, flags = B.Flags, funding = s.bank_funding or 'society' })
end)

-- ─────────────────────────────── Tableau de bord ───────────────────────────────
ESX.RegisterServerCallback('jobbuilder:bank:dash', function(src, cb)
    local x, job, s, err = ctx(src)
    if not x then return cb(fail(err)) end
    local n = job.name
    local function one(sql, ...) return MySQL.scalar.await(sql, { n, ... }) or 0 end
    local recent = MySQL.query.await([[SELECT e.kind, e.label, e.amount, e.officer, UNIX_TIMESTAMP(e.created_at) AS t, CONCAT(c.firstname, ' ', c.lastname) AS client
        FROM jobbuilder_bank_entries e JOIN jobbuilder_bank_clients c ON c.id = e.client_id WHERE e.job_name = ? ORDER BY e.id DESC LIMIT 8]], { n }) or {}
    local due = MySQL.query.await([[SELECT l.id, l.installment, l.penalties, l.status, UNIX_TIMESTAMP(l.next_due) AS due, CONCAT(c.firstname, ' ', c.lastname) AS client
        FROM jobbuilder_bank_loans l JOIN jobbuilder_bank_clients c ON c.id = l.client_id WHERE l.job_name = ? AND l.status IN ('active','late','defaulted') ORDER BY l.next_due LIMIT 5]], { n }) or {}
    cb({ ok = true,
        balance = job.society and JB.societyBalance and JB.societyBalance(n) or nil,
        clients = one('SELECT COUNT(*) FROM jobbuilder_bank_clients WHERE job_name = ?'),
        active = one("SELECT COUNT(*) FROM jobbuilder_bank_loans WHERE job_name = ? AND status = 'active'"),
        late = one("SELECT COUNT(*) FROM jobbuilder_bank_loans WHERE job_name = ? AND status = 'late'"),
        defaulted = one("SELECT COUNT(*) FROM jobbuilder_bank_loans WHERE job_name = ? AND status = 'defaulted'"),
        outstanding = one("SELECT COALESCE(SUM(installment * left_count + penalties), 0) FROM jobbuilder_bank_loans WHERE job_name = ? AND status IN ('active','late','defaulted')"),
        collected = one("SELECT COALESCE(SUM(amount), 0) FROM jobbuilder_bank_entries WHERE job_name = ? AND kind = 'payment' AND created_at > (NOW() - INTERVAL 30 DAY)"),
        granted = one("SELECT COALESCE(SUM(principal), 0) FROM jobbuilder_bank_loans WHERE job_name = ? AND created_at > (NOW() - INTERVAL 30 DAY)"),
        fees = one("SELECT COALESCE(SUM(amount), 0) FROM jobbuilder_bank_entries WHERE job_name = ? AND kind = 'fee' AND created_at > (NOW() - INTERVAL 30 DAY)"),
        recent = recent, due = due })
end)

ESX.RegisterServerCallback('jobbuilder:bank:live', function(src, cb)
    local x, job, s, err = ctx(src)
    if not x then return cb(fail(err)) end
    local me = GetEntityCoords(GetPlayerPed(src))
    local team = {}
    for _, m in ipairs(members(job.name)) do
        local ped = GetPlayerPed(m.source)
        local d = (ped and ped ~= 0) and math.floor(#(GetEntityCoords(ped) - me)) or nil
        team[#team + 1] = { src = m.source, name = JB.playerName(m), grade = m.job.grade_label, dist = d, me = m.source == src }
    end
    table.sort(team, function(a, b) return a.name < b.name end)
    cb({ ok = true, team = team, balance = job.society and JB.societyBalance and JB.societyBalance(job.name) or nil })
end)

-- ─────────────────────────────── Clients ───────────────────────────────
ESX.RegisterServerCallback('jobbuilder:bank:clients', function(src, cb, q, flag)
    local x, job, s, err = ctx(src)
    if not x then return cb(fail(err)) end
    q = str(tostring(q or ''), 60):gsub('[%%_\\]', '\\%0')
    local like = '%' .. q .. '%'
    flag = B.Flags[flag] and flag or ''
    local rows = MySQL.query.await([[SELECT c.id, c.firstname, c.lastname, c.rating, c.flag,
        (SELECT COUNT(*) FROM jobbuilder_bank_loans l WHERE l.client_id = c.id AND l.status IN ('active','late','defaulted')) AS loans
        FROM jobbuilder_bank_clients c WHERE c.job_name = ? AND (? = '' OR c.flag = ?) AND (? = '' OR CONCAT(c.firstname, ' ', c.lastname) LIKE ? OR CONCAT(c.lastname, ' ', c.firstname) LIKE ?)
        ORDER BY c.updated_at DESC LIMIT 80]], { job.name, flag, flag, q, like, like }) or {}
    local out = {}
    for _, r in ipairs(rows) do out[#out + 1] = { id = r.id, name = r.firstname .. ' ' .. r.lastname, rating = r.rating, flag = r.flag, loans = r.loans } end
    cb({ ok = true, list = out })
end)

local function loanRow(l)
    return { id = l.id, principal = l.principal, rate = l.rate, installment = l.installment, installments = l.installments, left = l.left_count, paid = l.paid, penalties = l.penalties,
        late = l.late_count, status = l.status, due = l.due, t = l.t, officer = l.officer, note = l.note, outstanding = outstanding(l), name = l.client }
end

local LOAN_COLS = 'l.id, l.principal, l.rate, l.installment, l.installments, l.left_count, l.paid, l.penalties, l.late_count, l.status, l.officer, l.note, UNIX_TIMESTAMP(l.next_due) AS due, UNIX_TIMESTAMP(l.created_at) AS t'

ESX.RegisterServerCallback('jobbuilder:bank:client', function(src, cb, id)
    local x, job, s, err = ctx(src)
    if not x then return cb(fail(err)) end
    local c = clientOf(job.name, id)
    if not c then return cb(fail('Fiche introuvable')) end
    local entries = MySQL.query.await('SELECT id, kind, label, amount, officer, UNIX_TIMESTAMP(created_at) AS t FROM jobbuilder_bank_entries WHERE client_id = ? AND job_name = ? ORDER BY id DESC LIMIT 100', { c.id, job.name }) or {}
    local loans = {}
    for _, l in ipairs(MySQL.query.await('SELECT ' .. LOAN_COLS .. ' FROM jobbuilder_bank_loans l WHERE l.client_id = ? AND l.job_name = ? ORDER BY l.id DESC LIMIT 30', { c.id, job.name }) or {}) do loans[#loans + 1] = loanRow(l) end
    -- Solde en direct : uniquement si le client est EN FACE du conseiller
    local balance
    local t = c.identifier and ESX.GetPlayerFromIdentifier(c.identifier)
    if t and JB.playersClose(src, t.source) then balance = { bank = t.getAccount('bank').money, cash = t.getAccount('money').money } end
    local maxLoan = ratingLimit(c.rating, s.bank_loan_max or 100000)
    cb({ ok = true, client = { id = c.id, firstname = c.firstname, lastname = c.lastname, rating = c.rating, flag = c.flag, notes = c.notes or '', created_by = c.created_by },
        entries = entries, loans = loans, balance = balance, online = t ~= nil, maxLoan = maxLoan })
end)

ESX.RegisterServerCallback('jobbuilder:bank:saveClient', function(src, cb, rec)
    local x, job, s, err = ctx(src, 'fee')
    if not x then return cb(fail(err)) end
    rec = type(rec) == 'table' and rec or {}
    local first, last = str(rec.firstname, 50), str(rec.lastname, 50)
    if first == '' or last == '' then return cb(fail('Nom et prénom obligatoires')) end
    local rating = validRating[rec.rating] and rec.rating or 'C'
    local flag = B.Flags[rec.flag] and rec.flag or 'normal'
    local notes = str(rec.notes, 2000)
    local id = tonumber(rec.id)
    if id then
        local old = clientOf(job.name, id)
        if not old then return cb(fail('Fiche introuvable')) end
        MySQL.update.await('UPDATE jobbuilder_bank_clients SET firstname = ?, lastname = ?, rating = ?, flag = ?, notes = ? WHERE id = ? AND job_name = ?', { first, last, rating, flag, notes, id, job.name })
        if old.rating ~= rating then addEntry(id, job.name, 'rating', ('Cote modifiée : %s → %s'):format(old.rating, rating), 0, JB.playerName(x)) end
        if old.flag ~= flag then addEntry(id, job.name, 'rating', ('Statut : %s'):format(B.Flags[flag]), 0, JB.playerName(x)) end
    else
        id = MySQL.insert.await('INSERT INTO jobbuilder_bank_clients (job_name, firstname, lastname, rating, flag, notes, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)',
            { job.name, first, last, rating, flag, notes, JB.playerName(x) })
        JB.log(job.name, x, 'bank_client', first .. ' ' .. last)
    end
    cb({ ok = true, id = id })
end)

ESX.RegisterServerCallback('jobbuilder:bank:deleteClient', function(src, cb, id)
    local x, job, s, err = ctx(src, 'admin')
    if not x then return cb(fail(err)) end
    local c = clientOf(job.name, id)
    if not c then return cb(fail('Fiche introuvable')) end
    if (MySQL.scalar.await("SELECT COUNT(*) FROM jobbuilder_bank_loans WHERE client_id = ? AND status IN ('active','late','defaulted')", { c.id }) or 0) > 0 then
        return cb(fail('Ce client a un prêt en cours : solde-le ou annule-le avant'))
    end
    MySQL.update.await('DELETE FROM jobbuilder_bank_loans WHERE client_id = ? AND job_name = ?', { c.id, job.name })
    MySQL.update.await('DELETE FROM jobbuilder_bank_entries WHERE client_id = ? AND job_name = ?', { c.id, job.name })
    MySQL.update.await('DELETE FROM jobbuilder_bank_clients WHERE id = ? AND job_name = ?', { c.id, job.name })
    JB.log(job.name, x, 'bank_client_deleted', c.firstname .. ' ' .. c.lastname)
    cb({ ok = true })
end)

ESX.RegisterServerCallback('jobbuilder:bank:note', function(src, cb, id, label)
    local x, job, s, err = ctx(src)
    if not x then return cb(fail(err)) end
    local c = clientOf(job.name, id)
    if not c then return cb(fail('Fiche introuvable')) end
    label = str(tostring(label or ''), 120)
    if label == '' then return cb(fail('La note est vide')) end
    addEntry(c.id, job.name, 'note', label, 0, JB.playerName(x))
    cb({ ok = true })
end)

ESX.RegisterServerCallback('jobbuilder:bank:delEntry', function(src, cb, entryId)
    local x, job, s, err = ctx(src, 'admin')
    if not x then return cb(fail(err)) end
    MySQL.update.await('DELETE FROM jobbuilder_bank_entries WHERE id = ? AND job_name = ?', { tonumber(entryId) or 0, job.name })
    cb({ ok = true })
end)

-- (placeholder, client en face [injecté]) : crée ou retrouve la fiche de la personne devant soi
ESX.RegisterServerCallback('jobbuilder:bank:nearest', function(src, cb, _, targetId)
    local x, job, s, err = ctx(src)
    if not x then return cb(fail(err)) end
    local target = ESX.GetPlayerFromId(tonumber(targetId))
    if not target or target.source == src or not JB.playersClose(src, target.source) then return cb(fail('Aucun client en face de toi')) end
    cb({ ok = true, id = ensureClient(job.name, target, JB.playerName(x)) })
end)

-- ─────────────────────────────── Prêts ───────────────────────────────
ESX.RegisterServerCallback('jobbuilder:bank:loans', function(src, cb, status)
    local x, job, s, err = ctx(src)
    if not x then return cb(fail(err)) end
    local filter = ({ active = "('active')", late = "('late')", defaulted = "('defaulted')", paid = "('paid')", forgiven = "('forgiven')", open = "('active','late','defaulted')" })[status] or "('active','late','defaulted')"
    local rows = MySQL.query.await(('SELECT %s, CONCAT(c.firstname, \' \', c.lastname) AS client, c.id AS cid FROM jobbuilder_bank_loans l JOIN jobbuilder_bank_clients c ON c.id = l.client_id WHERE l.job_name = ? AND l.status IN %s ORDER BY l.next_due LIMIT 120'):format(LOAN_COLS, filter), { job.name }) or {}
    local out = {}
    for _, l in ipairs(rows) do local r = loanRow(l) r.cid = l.cid out[#out + 1] = r end
    cb({ ok = true, list = out })
end)

local function loanOf(jobName, id)
    return MySQL.single.await('SELECT * FROM jobbuilder_bank_loans WHERE id = ? AND job_name = ?', { tonumber(id) or 0, jobName })
end

-- Proposition de prêt : (placeholder, client en face [injecté], montant, intérêt %, nb d'échéances, note)
ESX.RegisterServerCallback('jobbuilder:bank:offerLoan', function(src, cb, _, targetId, amount, rate, n, note)
    local x, job, s, err = ctx(src, 'loan')
    if not x then return cb(fail(err)) end
    local target = ESX.GetPlayerFromId(tonumber(targetId))
    if not target or target.source == src or not JB.playersClose(src, target.source) then return cb(fail('Aucun client en face de toi')) end
    local maxJob = s.bank_loan_max or 100000
    amount = intIn(amount, B.MinLoan, maxJob)
    if not amount then return cb(fail(('Montant invalide (%s à %s)'):format(money(B.MinLoan), money(maxJob)))) end
    local rmin, rmax = s.bank_rate_min or 0, s.bank_rate_max or 25
    rate = intIn(rate, rmin, rmax)
    if not rate then return cb(fail(('Intérêt invalide (%d à %d %%)'):format(rmin, rmax))) end
    n = intIn(n, 1, 100)
    if not n or not validTerm[n] then return cb(fail('Durée invalide')) end
    note = str(tostring(note or ''), 200)

    local cid = ensureClient(job.name, target, JB.playerName(x))
    local c = clientOf(job.name, cid)
    local limit = ratingLimit(c.rating, maxJob)
    if limit <= 0 then return cb(fail(('Cote %s : ce client ne peut pas emprunter'):format(c.rating))) end
    if amount > limit then return cb(fail(('Cote %s : plafond de %s pour ce client'):format(c.rating, money(limit)))) end
    local open = MySQL.scalar.await("SELECT COUNT(*) FROM jobbuilder_bank_loans WHERE client_id = ? AND status IN ('active','late','defaulted')", { cid }) or 0
    if open >= B.MaxActive then return cb(fail(('Ce client a déjà %d prêt(s) en cours (maximum %d)'):format(open, B.MaxActive))) end
    local bad = MySQL.scalar.await("SELECT COUNT(*) FROM jobbuilder_bank_loans WHERE client_id = ? AND status IN ('late','defaulted')", { cid }) or 0
    if bad > 0 then return cb(fail('Ce client a un prêt en retard de paiement')) end
    local funding = s.bank_funding or 'society'
    if funding == 'society' and (JB.societyBalance(job.name) or 0) < amount then return cb(fail(('La banque n\'a pas les %s nécessaires'):format(money(amount)))) end

    local total = math.ceil(amount * (100 + rate) / 100)
    local inst = math.ceil(total / n)
    total = inst * n
    local officer = JB.playerName(x)
    local jobName = job.name

    JB.sendInvoice(x, target, 'Proposition de prêt', total, nil, {
        offer = { title = 'Proposition de prêt', accept = 'Accepter le prêt', decline = 'Refuser', lines = {
            { 'Tu reçois', money(amount) }, { 'Intérêt', rate .. ' %' }, { 'Remboursement', n .. ' × ' .. money(inst) }, { 'Total à rembourser', money(total) },
            { 'Une échéance toutes les', B.IntervalHours .. ' h' }, { 'Retard', '+' .. B.LateFeePct .. ' % par échéance manquée' } } },
        onAccept = function(payer)
            local j = JB.Jobs[jobName]
            if not j or payer.identifier ~= target.identifier then return end
            if funding == 'society' and not JB.societyRemove(jobName, amount) then
                notify(payer.source, '~r~La banque n\'a plus les fonds pour ce prêt.')
                return notify(src, '~r~Prêt annulé : fonds insuffisants dans la société.')
            end
            local stillOpen = MySQL.scalar.await("SELECT COUNT(*) FROM jobbuilder_bank_loans WHERE client_id = ? AND status IN ('active','late','defaulted')", { cid }) or 0
            if stillOpen >= B.MaxActive then
                if funding == 'society' then JB.societyAdd(jobName, amount) end
                return notify(payer.source, '~r~Tu as déjà trop de prêts en cours.')
            end
            local id = MySQL.insert.await(('INSERT INTO jobbuilder_bank_loans (job_name, client_id, identifier, principal, rate, installment, installments, left_count, status, next_due, officer, note) VALUES (?, ?, ?, ?, ?, ?, ?, ?, \'active\', DATE_ADD(NOW(), INTERVAL %d HOUR), ?, ?)'):format(B.IntervalHours),
                { jobName, cid, payer.identifier, amount, rate, inst, n, n, officer, note ~= '' and note or nil })
            payer.addAccountMoney('bank', amount)
            addEntry(cid, jobName, 'loan', ('Prêt #%d accordé : %s à %d %% sur %d échéances'):format(id, money(amount), rate, n), amount, officer)
            JB.log(jobName, ESX.GetPlayerFromId(src) or x, 'bank_loan', ('%s : %d$ à %d%% (%d x %d$)'):format(JB.playerName(payer), amount, rate, n, inst))
            notify(payer.source, ('~b~[Banque]~s~ Prêt accepté : ~g~%s~s~ versés sur ton compte bancaire. Première échéance dans %d h.'):format(money(amount), B.IntervalHours))
            notify(src, ('~g~Prêt de %s accordé.'):format(money(amount)))
        end,
        onRefused = function() notify(src, '~r~Le client a refusé le prêt.') end,
    })
    cb({ ok = true, total = total, installment = inst })
end)

ESX.RegisterServerCallback('jobbuilder:bank:forgive', function(src, cb, id)
    local x, job, s, err = ctx(src, 'admin')
    if not x then return cb(fail(err)) end
    local l = loanOf(job.name, id)
    if not l or (l.status ~= 'active' and l.status ~= 'late' and l.status ~= 'defaulted') then return cb(fail('Prêt introuvable ou déjà clos')) end
    MySQL.update.await("UPDATE jobbuilder_bank_loans SET status = 'forgiven', penalties = 0 WHERE id = ?", { l.id })
    addEntry(l.client_id, job.name, 'forgive', ('Prêt #%d annulé (reste %s)'):format(l.id, money(outstanding(l))), outstanding(l), JB.playerName(x))
    JB.log(job.name, x, 'bank_forgive', '#' .. l.id)
    cb({ ok = true })
end)

ESX.RegisterServerCallback('jobbuilder:bank:remind', function(src, cb, id)
    local x, job, s, err = ctx(src, 'loan')
    if not x then return cb(fail(err)) end
    local l = loanOf(job.name, id)
    if not l then return cb(fail('Prêt introuvable')) end
    local t = ESX.GetPlayerFromIdentifier(l.identifier)
    if not t then return cb(fail('Le client n\'est pas en ville')) end
    notify(t.source, ('~b~[Banque]~s~ Rappel : il te reste ~r~%s~s~ à rembourser (échéance de %s).'):format(money(outstanding(l)), money(l.installment + l.penalties)))
    cb({ ok = true })
end)

ESX.RegisterServerCallback('jobbuilder:bank:collect', function(src, cb, id)
    local x, job, s, err = ctx(src, 'admin')
    if not x then return cb(fail(err)) end
    local l = loanOf(job.name, id)
    if not l or (l.status ~= 'active' and l.status ~= 'late' and l.status ~= 'defaulted') then return cb(fail('Prêt introuvable ou déjà clos')) end
    local t = ESX.GetPlayerFromIdentifier(l.identifier)
    if not t then return cb(fail('Le client n\'est pas en ville')) end
    local r = collect(l, t)
    if r == 'paid' then return cb({ ok = true, msg = 'Échéance prélevée' }) end
    cb(fail('Le client n\'a pas assez sur son compte bancaire (pénalité appliquée)'))
end)

-- ─────────────────────────────── Guichet : dépôt / retrait avec l'accord du client ───────────────────────────────
-- (placeholder, client en face [injecté], 'deposit' | 'withdraw', montant)
ESX.RegisterServerCallback('jobbuilder:bank:op', function(src, cb, _, targetId, kind, amount)
    local x, job, s, err = ctx(src, 'ops')
    if not x then return cb(fail(err)) end
    local target = ESX.GetPlayerFromId(tonumber(targetId))
    if not target or target.source == src or not JB.playersClose(src, target.source) then return cb(fail('Aucun client en face de toi')) end
    if kind ~= 'deposit' and kind ~= 'withdraw' then return cb(fail('Opération invalide')) end
    amount = intIn(amount, B.MinOp, B.MaxOp)
    if not amount then return cb(fail(('Montant invalide (%s à %s)'):format(money(B.MinOp), money(B.MaxOp)))) end
    if kind == 'deposit' and target.getAccount('money').money < amount then return cb(fail('Le client n\'a pas assez d\'argent liquide')) end
    if kind == 'withdraw' and target.getAccount('bank').money < amount then return cb(fail('Le client n\'a pas assez sur son compte')) end
    local cid = ensureClient(job.name, target, JB.playerName(x))
    local officer, jobName = JB.playerName(x), job.name
    JB.sendInvoice(x, target, kind == 'deposit' and 'Dépôt au guichet' or 'Retrait au guichet', amount, nil, {
        offer = { title = kind == 'deposit' and 'Dépôt au guichet' or 'Retrait au guichet', accept = 'Confirmer', decline = 'Annuler', lines = {
            { kind == 'deposit' and 'Espèces déposées' or 'Retiré du compte', money(amount) }, { 'Conseiller', officer } } },
        onAccept = function(payer)
            if payer.identifier ~= target.identifier then return end
            if kind == 'deposit' then
                if payer.getAccount('money').money < amount then return notify(payer.source, '~r~Tu n\'as pas assez d\'argent liquide.') end
                payer.removeAccountMoney('money', amount)
                payer.addAccountMoney('bank', amount)
            else
                if payer.getAccount('bank').money < amount then return notify(payer.source, '~r~Tu n\'as pas assez sur ton compte.') end
                payer.removeAccountMoney('bank', amount)
                payer.addAccountMoney('money', amount)
            end
            addEntry(cid, jobName, kind, (kind == 'deposit' and 'Dépôt' or 'Retrait') .. ' au guichet', amount, officer)
            JB.log(jobName, ESX.GetPlayerFromId(src) or x, 'bank_' .. kind, ('%s : %d$'):format(JB.playerName(payer), amount))
            notify(payer.source, ('~b~[Banque]~s~ %s de ~g~%s~s~ effectué.'):format(kind == 'deposit' and 'Dépôt' or 'Retrait', money(amount)))
            notify(src, ('~g~%s de %s effectué.'):format(kind == 'deposit' and 'Dépôt' or 'Retrait', money(amount)))
        end,
        onRefused = function() notify(src, '~r~Le client a annulé l\'opération.') end,
    })
    cb({ ok = true })
end)

-- ─────────────────────────────── Frais & services ───────────────────────────────
-- (placeholder, client en face [injecté], n° du catalogue ou 0, motif, montant)
ESX.RegisterServerCallback('jobbuilder:bank:fee', function(src, cb, _, targetId, idx, label, amount)
    local x, job, s, err = ctx(src, 'fee')
    if not x then return cb(fail(err)) end
    local target = ESX.GetPlayerFromId(tonumber(targetId))
    if not target or target.source == src or not JB.playersClose(src, target.source) then return cb(fail('Aucun client en face de toi')) end
    idx = math.floor(tonumber(idx) or 0)
    if idx > 0 then
        local list = (s.bank_fees and #s.bank_fees > 0) and s.bank_fees or B.DefaultFees
        local f = list[idx]
        if not f then return cb(fail('Service inconnu')) end
        label, amount = f.label, f.amount
    else
        label, amount = str(tostring(label or ''), 60), math.floor(tonumber(amount) or 0)
        if label == '' then return cb(fail('Le motif est obligatoire')) end
    end
    if amount < B.MinFee or amount > B.MaxFee then return cb(fail(('Montant invalide (%d à %d $)'):format(B.MinFee, B.MaxFee))) end
    local cid = ensureClient(job.name, target, JB.playerName(x))
    local officer, jobName = JB.playerName(x), job.name
    JB.sendInvoice(x, target, label, amount, nil, {
        onPaid = function() addEntry(cid, jobName, 'fee', label, amount, officer) JB.log(jobName, x, 'bank_fee', ('%s : %d$'):format(label, amount)) end,
        onRefused = function(why) addEntry(cid, jobName, 'note', (why == 'unpaid' and 'Frais impayés : ' or 'Frais refusés : ') .. label, amount, officer) end,
    })
    cb({ ok = true })
end)
