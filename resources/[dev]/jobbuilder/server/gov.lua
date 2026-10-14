-- ─────────────────────────────── Gouvernement : trésor public, taxes, subventions, primes, annonces ───────────────────────────────
-- Le compte société du job "gouvernement" (réglage « Trésor public ») sert de trésor.
-- Les taxes (config.Gov.Taxes) sont prélevées sur les ventes de concession, immobilier, boutiques et factures des autres jobs.

local G = Config.Gov
local lastAnnounce = 0

local function fail(msg) return { ok = false, error = msg } end
local function now() return os.time() end

function JB.treasuryJob()
    local best
    for name, job in pairs(JB.Jobs) do
        if job.type == 'government' and job.society and job.settings.treasury ~= false then
            if not best or name < best then best = name end
        end
    end
    return best
end

local function treasuryLog(kind, source, actor, detail, amount)
    MySQL.insert('INSERT INTO jobbuilder_treasury_log (kind, source, actor, detail, amount) VALUES (?, ?, ?, ?, ?)',
        { kind, source, actor, detail and tostring(detail):sub(1, 200) or nil, amount })
end

-- Prélève la taxe `kind` sur `amount` au profit du trésor. Retourne le montant prélevé (à déduire de la part du vendeur).
function JB.applyTax(kind, amount, sourceJob)
    local rate = (G.Taxes and G.Taxes[kind]) or 0
    if rate <= 0 or amount <= 0 then return 0 end
    local tj = JB.treasuryJob()
    if not tj or tj == sourceJob then return 0 end
    local tax = math.floor(amount * rate / 100)
    if tax <= 0 then return 0 end
    JB.societyAdd(tj, tax)
    treasuryLog('tax', kind, sourceJob, ('%d%% de %d$'):format(rate, amount), tax)
    return tax
end

local function ctx(src, needAdmin)
    local x = ESX.GetPlayerFromId(src)
    if not x then return nil, nil, 'Joueur introuvable' end
    local job = JB.Jobs[x.job.name]
    if not job or job.type ~= 'government' then return nil, nil, 'Ton métier n\'est pas un gouvernement' end
    if x.job.name ~= JB.treasuryJob() then return nil, nil, 'Ce gouvernement n\'est pas le trésor public (réglage « Trésor public » du job)' end
    local s = job.settings or {}
    if x.job.grade < (s.gov_grade or 0) then return nil, nil, 'Ton grade ne permet pas d\'accéder à cette gestion' end
    if needAdmin and x.job.grade < (s.gov_admin_grade or job.boss_grade) then return nil, nil, 'Réservé à la direction du gouvernement' end
    return x, job
end

local function data(x, job)
    local s = job.settings or {}
    local taxes = {}
    for k, v in pairs(G.Taxes) do taxes[k] = v end
    local societies = {}
    for name, j in pairs(JB.Jobs) do
        if j.society and name ~= job.name then societies[#societies + 1] = { name = name, label = j.label, type = j.type } end
    end
    table.sort(societies, function(a, b) return a.label < b.label end)
    local stats = { tax = {}, taxTotal = 0, grants = 0, primes = 0 }
    for _, r in ipairs(MySQL.query.await([[SELECT kind, source, COALESCE(SUM(amount),0) AS total FROM jobbuilder_treasury_log
        WHERE created_at > (NOW() - INTERVAL 30 DAY) GROUP BY kind, source]]) or {}) do
        if r.kind == 'tax' then stats.tax[r.source] = r.total stats.taxTotal = stats.taxTotal + r.total
        elseif r.kind == 'grant' then stats.grants = r.total
        elseif r.kind == 'prime' then stats.primes = r.total end
    end
    local log = MySQL.query.await('SELECT kind, source, actor, detail, amount, UNIX_TIMESTAMP(created_at) AS t FROM jobbuilder_treasury_log ORDER BY id DESC LIMIT 40') or {}
    return {
        ok = true, job = job.name, jobLabel = job.label, agent = JB.playerName(x), gradeLabel = x.job.grade_label,
        balance = JB.societyBalance(job.name), taxes = taxes, societies = societies, stats = stats, log = log,
        admin = x.job.grade >= (s.gov_admin_grade or job.boss_grade),
        limits = { grantMax = G.GrantMax, primeMax = G.PrimeMax, announceMax = G.AnnounceMax, cooldown = G.AnnounceCooldown, cooldownLeft = math.max(0, G.AnnounceCooldown - (now() - lastAnnounce)) },
    }
end

ESX.RegisterServerCallback('jobbuilder:gov:manage', function(src, cb)
    local x, job, err = ctx(src)
    if not x then return cb(fail(err)) end
    cb(data(x, job))
end)

ESX.RegisterServerCallback('jobbuilder:gov:balance', function(src, cb)
    local x, job, err = ctx(src)
    if not x then return cb(fail(err)) end
    cb({ ok = true, job = job.name, balance = JB.societyBalance(job.name) })
end)

ESX.RegisterServerCallback('jobbuilder:gov:money', function(src, cb, mode, amount)
    local x, job, err = ctx(src, true)
    if not x then return cb(fail(err)) end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 or amount > 1000000000 then return cb(fail('Montant invalide')) end
    if mode == 'deposit' then
        if x.getAccount('money').money < amount then return cb(fail('Pas assez d\'argent liquide')) end
        x.removeAccountMoney('money', amount)
        JB.societyAdd(job.name, amount)
        treasuryLog('deposit', nil, JB.playerName(x), nil, amount)
    elseif mode == 'withdraw' then
        if not JB.societyRemove(job.name, amount) then return cb(fail('Fonds insuffisants dans le trésor')) end
        x.addAccountMoney('money', amount)
        treasuryLog('withdraw', nil, JB.playerName(x), nil, -amount)
    else return cb(fail('Action invalide')) end
    JB.log(job.name, x, 'treasury_' .. mode, amount .. '$')
    cb(data(x, job))
end)

ESX.RegisterServerCallback('jobbuilder:gov:setTaxes', function(src, cb, taxes)
    local x, job, err = ctx(src, true)
    if not x then return cb(fail(err)) end
    if type(taxes) ~= 'table' then return cb(fail('Données invalides')) end
    local value = JBGet('gov')
    for k in pairs(G.Taxes) do if taxes[k] ~= nil then value.Taxes[k] = taxes[k] end end
    local clean, e = JB.saveSetting('gov', value, 0, x.identifier)
    if not clean then return cb(fail(e)) end
    JB.log(job.name, x, 'taxes_set', json.encode(clean.Taxes))
    cb(data(x, job))
end)

ESX.RegisterServerCallback('jobbuilder:gov:grant', function(src, cb, target, amount, reason)
    local x, job, err = ctx(src, true)
    if not x then return cb(fail(err)) end
    local tj = JB.Jobs[tostring(target)]
    amount = math.floor(tonumber(amount) or 0)
    if not tj or not tj.society or tj.name == job.name then return cb(fail('Société invalide')) end
    if amount < 1 or amount > G.GrantMax then return cb(fail(('Montant invalide (1 à %d)'):format(G.GrantMax))) end
    if not JB.societyRemove(job.name, amount) then return cb(fail('Fonds insuffisants dans le trésor')) end
    JB.societyAdd(tj.name, amount)
    treasuryLog('grant', tj.name, JB.playerName(x), tostring(reason or ''):gsub('%c', ''):sub(1, 120), -amount)
    JB.log(job.name, x, 'grant', ('%d$ → %s'):format(amount, tj.name))
    cb(data(x, job))
end)

ESX.RegisterServerCallback('jobbuilder:gov:prime', function(src, cb, targetId, amount, reason)
    local x, job, err = ctx(src, true)
    if not x then return cb(fail(err)) end
    local t = ESX.GetPlayerFromId(tonumber(targetId))
    amount = math.floor(tonumber(amount) or 0)
    if not t then return cb(fail('Aucun citoyen à proximité')) end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(t.source))) > Config.TargetDistance + 2.0 then return cb(fail('Le citoyen est trop loin')) end
    if amount < 1 or amount > G.PrimeMax then return cb(fail(('Montant invalide (1 à %d)'):format(G.PrimeMax))) end
    if not JB.societyRemove(job.name, amount) then return cb(fail('Fonds insuffisants dans le trésor')) end
    t.addAccountMoney('bank', amount)
    local why = tostring(reason or ''):gsub('%c', ''):sub(1, 120)
    JBNotifyClient( t.source, ('Prime du gouvernement : ~g+%d$~s~ %s'):format(amount, why))
    treasuryLog('prime', JB.playerName(t), JB.playerName(x), why, -amount)
    JB.log(job.name, x, 'prime', ('%d$ → %s'):format(amount, JB.playerName(t)))
    cb(data(x, job))
end)

ESX.RegisterServerCallback('jobbuilder:gov:announce', function(src, cb, text)
    local x, job, err = ctx(src)
    if not x then return cb(fail(err)) end
    text = tostring(text or ''):gsub('%c', ' '):sub(1, G.AnnounceMax)
    if #text < 3 then return cb(fail('Annonce trop courte')) end
    local left = G.AnnounceCooldown - (now() - lastAnnounce)
    if left > 0 then return cb(fail(('Patiente encore %d s avant la prochaine annonce'):format(left))) end
    lastAnnounce = now()
    TriggerClientEvent('jobbuilder:client:announce', -1, { title = job.label, text = text, author = JB.playerName(x) })
    JB.log(job.name, x, 'announce', text)
    cb(data(x, job))
end)
