-- ─────────────────────────────── Entreprises de joueurs ───────────────────────────────
-- Un joueur fonde sa propre entreprise (nom, modèle, frais) sans passer par un admin : un job est créé avec un bureau de patron (gestion : embauche, trésorerie, salaires) et un
-- coffre à l'endroit où il se trouve. Il peut la dissoudre : le solde de la société lui est reversé. Création et suppression passent par le builder (JB.saveJob / JB.deleteJob).

local function C() return Config.Company or {} end
local function fail(m) return { ok = false, error = m } end
local pendingDissolve = {}   -- [src] = fin du délai de confirmation
local lastCmd = {}

CreateThread(function()
    Wait(3000)
    if MySQL and MySQL.query then
        pcall(MySQL.query.await, [[CREATE TABLE IF NOT EXISTS jobbuilder_companies (job_name VARCHAR(20) PRIMARY KEY, owner VARCHAR(80) NOT NULL, created_at INT NOT NULL, INDEX (owner)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    end
end)

local ACCENTS = { ['é'] = 'e', ['è'] = 'e', ['ê'] = 'e', ['ë'] = 'e', ['à'] = 'a', ['â'] = 'a', ['ä'] = 'a', ['î'] = 'i', ['ï'] = 'i', ['ô'] = 'o', ['ö'] = 'o', ['ù'] = 'u', ['û'] = 'u', ['ü'] = 'u', ['ç'] = 'c', ['É'] = 'e', ['È'] = 'e', ['Ê'] = 'e', ['À'] = 'a', ['Â'] = 'a', ['Î'] = 'i', ['Ô'] = 'o', ['Û'] = 'u', ['Ù'] = 'u', ['Ç'] = 'c' }

-- Nom d'entreprise valide : 3 à 30 caractères (lettres, chiffres, espaces, apostrophes, tirets)
function JB.companyLabel(raw)
    local s = tostring(raw or ''):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    if #s < 3 or #s > 30 then return nil, 'Le nom doit faire entre 3 et 30 caractères.' end
    if s:find('[%c<>"%%]') then return nil, 'Caractères interdits dans le nom.' end
    return s
end

-- Identifiant technique du job : co_<nom simplifié>_<n°>, 20 caractères maximum
function JB.companyJobName(label, n)
    local s = label:lower():gsub('[\195][\128-\191]', function(c) return ACCENTS[c] or '' end):gsub('[^a-z0-9]', '')
    if s == '' then s = 'societe' end
    return ('co_%s_%d'):format(s:sub(1, 9), n):sub(1, 20)
end

local function templateOf(id) for _, t in ipairs(C().Templates or {}) do if t.id == id then return t end end end

local function ownedBy(identifier)
    return MySQL.query.await('SELECT job_name FROM jobbuilder_companies WHERE owner = ?', { identifier }) or {}
end

local function templatesText()
    local out = {}
    for _, t in ipairs(C().Templates or {}) do out[#out + 1] = t.id end
    return table.concat(out, ' | ')
end

local function create(src, tid, rawName)
    local x = ESX.GetPlayerFromId(src)
    if not x then return end
    local t = templateOf(tid)
    if not t then return JBNotifyClient(src, '~r~Usage : /entreprise creer <' .. templatesText() .. '> <nom>') end
    local label, err = JB.companyLabel(rawName)
    if not label then return JBNotifyClient(src, '~r~' .. err) end
    if #ownedBy(x.identifier) >= (tonumber(C().MaxPerPlayer) or 1) then return JBNotifyClient(src, '~r~Tu as déjà le nombre maximal d\'entreprises.') end
    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped)
    if C().Registry and #C().Registry > 0 then
        local near = false
        for _, r in ipairs(C().Registry) do
            local dx, dy = c.x - r.coords.x, c.y - r.coords.y
            if math.sqrt(dx * dx + dy * dy) <= (r.radius or 6.0) then near = true end
        end
        if not near then return JBNotifyClient(src, '~r~Rends-toi au registre du commerce pour fonder ton entreprise.') end
    end
    local cost = math.floor(tonumber(t.cost) or tonumber(C().Cost) or 0)
    local acc = x.getAccount('bank')
    if not acc or acc.money < cost then return JBNotifyClient(src, ('~r~Il te faut %d $ en banque.'):format(cost)) end
    for _, row in ipairs(MySQL.query.await('SELECT label FROM jobbuilder_jobs WHERE LOWER(label) = ?', { label:lower() }) or {}) do
        return JBNotifyClient(src, '~r~Ce nom est déjà pris.')
    end
    local name
    for n = 1, 200 do
        local cand = JB.companyJobName(label, n)
        if not JB.Jobs[cand] and #(MySQL.query.await('SELECT name FROM jobs WHERE name = ?', { cand }) or {}) == 0 then name = cand break end
    end
    if not name then return JBNotifyClient(src, '~r~Impossible de trouver un identifiant libre.') end
    local grades = {}
    for i, g in ipairs(t.grades) do grades[i] = { name = g.name, label = g.label, salary = g.salary } end
    local boss = #grades - 1
    local payload = { job = { name = name, label = label, type = t.type or 'custom', whitelisted = true, society = true, boss_grade = boss, blip = { enabled = false }, settings = { actions = t.actions or { 'invoice' } } },
        grades = grades, points = {
            { type = 'boss', label = 'Bureau du patron', coords = { x = c.x, y = c.y, z = c.z }, min_grade = boss, data = {} },
            { type = 'stash', label = 'Coffre', coords = { x = c.x + 1.5, y = c.y, z = c.z }, min_grade = 0, data = { slots = t.stashSlots or 50, weight = t.stashWeight or 100 } },
        } }
    if cost > 0 then x.removeAccountMoney('bank', cost, 'Création d\'entreprise') end
    JB.saveJob(src, function(res)
        if not res or not res.ok then
            if cost > 0 then x.addAccountMoney('bank', cost, 'Création d\'entreprise (remboursement)') end
            return JBNotifyClient(src, '~r~Création impossible : ' .. tostring(res and res.error or 'erreur'))
        end
        MySQL.insert.await('INSERT INTO jobbuilder_companies (job_name, owner, created_at) VALUES (?, ?, ?)', { name, x.identifier, os.time() })
        x.setJob(name, boss)
        JB.log(name, x, 'company_created', label)
        JBNotifyClient(src, ('~g~« %s » est créée ! Tu en es le patron : rends-toi au bureau (marqueur) pour gérer les employés et la trésorerie.'):format(label))
    end, payload)
end

local function dissolve(src, confirm)
    local x = ESX.GetPlayerFromId(src)
    if not x then return end
    local mine = ownedBy(x.identifier)
    if #mine == 0 then return JBNotifyClient(src, '~r~Tu n\'as aucune entreprise.') end
    if not confirm or not pendingDissolve[src] or pendingDissolve[src] < os.time() then
        pendingDissolve[src] = os.time() + 30
        return JBNotifyClient(src, '~y~Dissoudre définitivement ton entreprise ? Tape /entreprise confirmer dans les 30 secondes. Le solde de la société te sera reversé.')
    end
    pendingDissolve[src] = nil
    local name = mine[1].job_name
    local acc = JB.societyAccount(name)
    local money = tonumber(MySQL.scalar.await('SELECT money FROM addon_account_data WHERE account_name = ? AND owner IS NULL', { acc })) or 0
    JB.deleteJob(src, function(res)
        if not res or not res.ok then return JBNotifyClient(src, '~r~Dissolution impossible : ' .. tostring(res and res.error or 'erreur')) end
        MySQL.update('DELETE FROM jobbuilder_companies WHERE job_name = ?', { name })
        if money > 0 then x.addAccountMoney('bank', math.floor(money), 'Solde de l\'entreprise dissoute') end
        JBNotifyClient(src, ('~g~Entreprise dissoute. %d $ reversés sur ton compte.'):format(math.floor(money)))
    end, name)
end

RegisterCommand(C().Command or 'entreprise', function(src, args)
    if src == 0 or not C().Enabled then return end
    if (lastCmd[src] or 0) + 2 > os.time() then return end
    lastCmd[src] = os.time()
    local sub = tostring(args[1] or '')
    if sub == 'creer' then return create(src, tostring(args[2] or ''), table.concat(args, ' ', 3)) end
    if sub == 'dissoudre' or sub == 'confirmer' then return dissolve(src, sub == 'confirmer') end
    local x = ESX.GetPlayerFromId(src)
    local mine = x and ownedBy(x.identifier) or {}
    if #mine > 0 then
        local j = JB.Jobs[mine[1].job_name]
        return JBNotifyClient(src, ('~b~Ton entreprise : %s. /entreprise dissoudre pour la fermer.'):format(j and j.label or mine[1].job_name))
    end
    JBNotifyClient(src, ('~b~/entreprise creer <%s> <nom> (frais %d $)'):format(templatesText(), tonumber(C().Cost) or 0))
end, false)

AddEventHandler('playerDropped', function() pendingDissolve[source] = nil lastCmd[source] = nil end)
