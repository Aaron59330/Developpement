-- ─────────────────────────────── Justice : mandats, saisies, alcootest, contrôle des papiers ───────────────────────────────
local ESX = exports['es_extended']:getSharedObject()
local C = Config

local function now() return os.time() end
local function trim(s) return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', '')) end
local function clamp(v, a, b) return math.max(a, math.min(b, v)) end
local function name(x) return (x and x.getName and x.getName()) or 'Inconnu' end
local function fmt(t) return os.date('%d/%m/%Y %H:%M', t) end
local function near(a, b, d) return #(GetEntityCoords(GetPlayerPed(a)) - GetEntityCoords(GetPlayerPed(b))) <= d end

CreateThread(function()
    Wait(900)
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS justice_warrants (id INT AUTO_INCREMENT PRIMARY KEY, kind VARCHAR(10) NOT NULL, subject VARCHAR(100) NOT NULL, reason VARCHAR(300) NOT NULL,
        place VARCHAR(120) NULL, issued_by VARCHAR(100) NOT NULL, issued_at INT NOT NULL, expires_at INT NOT NULL, status VARCHAR(10) NOT NULL DEFAULT 'active', executed_by VARCHAR(100) NULL,
        INDEX idx_status (status), INDEX idx_subject (subject)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS justice_seizures (id INT AUTO_INCREMENT PRIMARY KEY, officer VARCHAR(100) NOT NULL, target VARCHAR(100) NOT NULL, note VARCHAR(300) NOT NULL,
        warrant_id INT NULL, at INT NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
end)

-- ═══════════════ Rôles ═══════════════
local function role(x, def)
    if not x or not x.job then return false end
    for _, j in ipairs(def.Jobs) do if x.job.name == j then return true end end
    if GetResourceState('pickax_jobbuilder') == 'started' then
        local ok, t = pcall(function() return exports.pickax_jobbuilder:GetJobType(x.job.name) end)
        if ok and t then for _, jt in ipairs(def.Types) do if t == jt then return true end end end
    end
    return false
end
local function isJudge(x) return role(x, C.Judges) end
local function isPolice(x) return role(x, C.Police) end

local function notify(src, kind, txt) TriggerClientEvent('ox_lib:notify', src, { type = kind, description = txt }) end

-- ═══════════════ Mandats ═══════════════
local function expire() MySQL.update("UPDATE justice_warrants SET status = 'expired' WHERE status = 'active' AND expires_at < ?", { now() }) end

ESX.RegisterServerCallback('pickax_justice:warrantCreate', function(src, cb, kind, subject, reason, place)
    local x = ESX.GetPlayerFromId(src)
    if not C.Enabled or not isJudge(x) then return cb({ ok = false, error = 'Réservé aux juges' }) end
    kind = kind == 'arrest' and 'arrest' or 'search'
    subject, reason, place = trim(subject):sub(1, 100), trim(reason):sub(1, 300), trim(place):sub(1, 120)
    if #subject < 3 or #reason < 5 then return cb({ ok = false, error = 'Cible et motif obligatoires' }) end
    expire()
    local active = MySQL.scalar.await("SELECT COUNT(*) FROM justice_warrants WHERE status = 'active'") or 0
    if active >= C.Warrants.Max then return cb({ ok = false, error = 'Trop de mandats actifs' }) end
    local id = MySQL.insert.await('INSERT INTO justice_warrants (kind, subject, reason, place, issued_by, issued_at, expires_at) VALUES (?,?,?,?,?,?,?)',
        { kind, subject, reason, place ~= '' and place or nil, name(x), now(), now() + C.Warrants.ExpireHours[kind] * 3600 })
    for _, p in ipairs(GetPlayers()) do local xp = ESX.GetPlayerFromId(tonumber(p)) if isPolice(xp) then notify(tonumber(p), 'inform', ('Nouveau mandat de %s : %s'):format(kind == 'arrest' and 'arrestation' or 'perquisition', subject)) end end
    cb({ ok = true, id = id, msg = ('Mandat n°%d délivré.'):format(id) })
end)

ESX.RegisterServerCallback('pickax_justice:warrantList', function(src, cb)
    local x = ESX.GetPlayerFromId(src)
    if not isJudge(x) and not isPolice(x) then return cb({ ok = false, error = 'Réservé aux juges et à la police' }) end
    expire()
    local rows = MySQL.query.await("SELECT * FROM justice_warrants WHERE status = 'active' ORDER BY id DESC LIMIT 30") or {}
    for _, r in ipairs(rows) do r.issued = fmt(r.issued_at) r.expires = fmt(r.expires_at) end
    cb({ ok = true, rows = rows, judge = isJudge(x) })
end)

ESX.RegisterServerCallback('pickax_justice:warrantSet', function(src, cb, id, action)
    local x = ESX.GetPlayerFromId(src)
    id = tonumber(id)
    if not id then return cb({ ok = false }) end
    if action == 'revoke' then
        if not isJudge(x) then return cb({ ok = false, error = 'Réservé aux juges' }) end
        MySQL.update("UPDATE justice_warrants SET status = 'revoked' WHERE id = ? AND status = 'active'", { id })
        return cb({ ok = true, msg = 'Mandat annulé.' })
    elseif action == 'execute' then
        if not isPolice(x) then return cb({ ok = false, error = 'Réservé à la police' }) end
        MySQL.update("UPDATE justice_warrants SET status = 'executed', executed_by = ? WHERE id = ? AND status = 'active'", { name(x), id })
        return cb({ ok = true, msg = 'Mandat marqué comme exécuté.' })
    end
    cb({ ok = false })
end)

-- Un mandat de perquisition valide vise-t-il cette personne ? (insensible à la casse, correspondance sur le nom complet)
local function searchWarrantFor(fullName)
    expire()
    return MySQL.single.await("SELECT id FROM justice_warrants WHERE status = 'active' AND kind = 'search' AND LOWER(subject) = LOWER(?) ORDER BY id DESC LIMIT 1", { trim(fullName) })
end
exports('HasSearchWarrant', function(fullName) local r = searchWarrantFor(fullName) return r and r.id or false end)

-- ═══════════════ Saisies ═══════════════
local function logSeizure(officerName, targetName, note)
    local w = searchWarrantFor(targetName)
    local id = MySQL.insert.await('INSERT INTO justice_seizures (officer, target, note, warrant_id, at) VALUES (?,?,?,?,?)', { officerName, targetName, trim(note):sub(1, 300), w and w.id or nil, now() })
    return id, w ~= nil
end
-- Pour les autres ressources (illegalbuilder/seizure…) : exports.pickax_justice:LogSeizure(officerSrc, targetSrc, note)
exports('LogSeizure', function(officerSrc, targetSrc, note)
    local xo, xt = ESX.GetPlayerFromId(tonumber(officerSrc) or 0), ESX.GetPlayerFromId(tonumber(targetSrc) or 0)
    if not xo or not xt then return false end
    local _, warranted = logSeizure(name(xo), name(xt), note or 'Saisie')
    return warranted
end)

ESX.RegisterServerCallback('pickax_justice:seize', function(src, cb, target, note)
    local x = ESX.GetPlayerFromId(src)
    if not isPolice(x) then return cb({ ok = false, error = 'Réservé à la police' }) end
    local t = tonumber(target)
    local xt = t and ESX.GetPlayerFromId(t)
    if not xt or not near(src, t, C.Seizures.Distance + 2.0) then return cb({ ok = false, error = 'Personne à portée' }) end
    local id, warranted = logSeizure(name(x), name(xt), note)
    cb({ ok = true, warranted = warranted, msg = warranted and ('Saisie n°%d enregistrée (mandat valide).'):format(id) or ('Saisie n°%d enregistrée SANS mandat de perquisition : elle pourra être contestée.'):format(id) })
end)

ESX.RegisterServerCallback('pickax_justice:seizureList', function(src, cb)
    local x = ESX.GetPlayerFromId(src)
    if not isJudge(x) and not isPolice(x) then return cb({ ok = false, error = 'Réservé aux juges et à la police' }) end
    local rows = MySQL.query.await('SELECT * FROM justice_seizures ORDER BY id DESC LIMIT 30') or {}
    for _, r in ipairs(rows) do r.date = fmt(r.at) r.contestable = r.warrant_id == nil end
    cb({ ok = true, rows = rows })
end)

-- ═══════════════ Alcool ═══════════════
local Bac = {}   -- [identifier] = { g, at }
local function bacOf(identifier)
    local b = Bac[identifier]
    if not b then return 0.0 end
    local g = b.g - C.Alcohol.DecayPerHour * (now() - b.at) / 3600
    return math.max(0.0, g)
end
exports('AlcoholOf', function(src) local x = ESX.GetPlayerFromId(tonumber(src) or 0) return x and bacOf(x.identifier) or nil end)
exports('AddAlcohol', function(src, units) local x = ESX.GetPlayerFromId(tonumber(src) or 0) if not x then return end Bac[x.identifier] = { g = bacOf(x.identifier) + units * C.Alcohol.PerUnit, at = now() } end)

-- ox_inventory prévient quand un item est utilisé
AddEventHandler('ox_inventory:usedItem', function(playerId, itemName)
    local u = C.Alcohol.Items[itemName]
    if u then exports.pickax_justice:AddAlcohol(playerId, u) end
end)

ESX.RegisterServerCallback('pickax_justice:breath', function(src, cb, target)
    local x = ESX.GetPlayerFromId(src)
    if not isPolice(x) then return cb({ ok = false, error = 'Réservé à la police' }) end
    local t = tonumber(target)
    local xt = t and ESX.GetPlayerFromId(t)
    if not xt or not near(src, t, C.Alcohol.Distance + 2.0) then return cb({ ok = false, error = 'Personne à portée' }) end
    local g = math.floor(bacOf(xt.identifier) * 100 + 0.5) / 100
    local over = g > C.Alcohol.Limit
    cb({ ok = true, g = g, over = over, msg = ('Alcootest de %s : %.2f g/L — %s'):format(name(xt), g, over and ('INFRACTION (limite %.2f)'):format(C.Alcohol.Limit) or 'conforme') })
end)

-- ═══════════════ Contrôle des papiers ═══════════════
local Asks = {}   -- [target] = { officer, at }

local function identityOf(xt, meta)
    if meta and meta.firstname then return ('%s %s'):format(meta.firstname, meta.lastname) end
    return name(xt)
end

RegisterNetEvent('pickax_justice:answer', function(choice)
    local t = source
    local a = Asks[t]
    if not a or now() - a.at > C.Papers.AskSeconds + 5 then return end
    Asks[t] = nil
    a.resolve(choice == 'fake' and 'fake' or 'real')
end)

ESX.RegisterServerCallback('pickax_justice:papers', function(src, cb, target)
    local x = ESX.GetPlayerFromId(src)
    if not isPolice(x) then return cb({ ok = false, error = 'Réservé à la police' }) end
    local t = tonumber(target)
    local xt = t and ESX.GetPlayerFromId(t)
    if not xt or t == src or not near(src, t, C.Papers.Distance + 2.0) then return cb({ ok = false, error = 'Personne à portée' }) end
    local P = C.Papers
    local fake
    for _, sl in pairs(exports.ox_inventory:GetInventoryItems(t) or {}) do if sl.name == P.FakeItem then fake = sl break end end
    local function finish(choice)
        if choice == 'fake' and fake then
            local q = tonumber(fake.metadata and fake.metadata.quality) or 50
            local detect = clamp(P.DetectBase + (1 - q / 100) * (P.DetectMax - P.DetectBase), P.DetectBase, P.DetectMax)
            if math.random() < detect then
                notify(t, 'error', 'Le policier a repéré que ton document est un faux !')
                return cb({ ok = true, fake = true, msg = ('Document présenté : %s — FAUX DOCUMENT détecté (qualité %d %%).'):format(identityOf(xt, fake.metadata), q) })
            end
            return cb({ ok = true, fake = false, msg = ('Document présenté : %s — document en règle (apparemment).'):format(identityOf(xt, fake.metadata)) })
        end
        cb({ ok = true, fake = false, msg = ('Document présenté : %s — document en règle.'):format(name(xt)) })
    end
    if not fake then return finish('real') end
    -- le contrôlé choisit ce qu'il présente (vrai / faux) ; sans réponse : le vrai document
    local done = false
    local function resolve(c) if done then return end done = true finish(c) end
    Asks[t] = { officer = src, at = now(), resolve = resolve }
    TriggerClientEvent('pickax_justice:ask', t, name(x), P.AskSeconds)
    SetTimeout(P.AskSeconds * 1000 + 500, function() if Asks[t] then Asks[t] = nil resolve('real') end end)
end)

AddEventHandler('playerDropped', function() Asks[source] = nil end)
