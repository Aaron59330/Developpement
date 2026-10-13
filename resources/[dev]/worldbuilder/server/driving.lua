-- ─────────────────────────────── Auto-écoles : code (QCM) + conduite (parcours) ───────────────────────────────
local Exams = {}      -- [src] = examen en cours { kind = 'theory' | 'practical', ... }

-- Permis : esx_license si démarré, sinon table worldbuilder_licenses (toujours alimentée)
function WB.hasLicense(src, id)
    local x = ESX.GetPlayerFromId(src)
    if not x then return false end
    if GetResourceState('esx_license') == 'started' then
        local p = promise.new()
        TriggerEvent('esx_license:checkLicense', src, id, function(has) p:resolve(has == true) end)
        SetTimeout(2500, function() p:resolve(false) end)
        if Citizen.Await(p) then return true end
    end
    return MySQL.scalar.await('SELECT 1 FROM worldbuilder_licenses WHERE identifier = ? AND license = ?', { x.identifier, id }) ~= nil
end

function WB.giveLicense(src, id)
    local x = ESX.GetPlayerFromId(src)
    if not x then return end
    MySQL.update.await('INSERT IGNORE INTO worldbuilder_licenses (identifier, license) VALUES (?, ?)', { x.identifier, id })
    if GetResourceState('esx_license') == 'started' then TriggerEvent('esx_license:addLicense', src, id) end
end

local function licenseOf(e, id)
    for _, l in ipairs(e.settings.licenses or {}) do if l.id == id then return l end end
end

local function resolve(src, eid, pi)
    local e = WB.Entities[tonumber(eid) or 0]
    local x = ESX.GetPlayerFromId(src)
    if not e or e.type ~= 'driving' or not e.enabled or not x then return nil, 'Introuvable' end
    local p = e.points[tonumber(pi) or 0]
    if not p or p.kind ~= 'desk' or not p.coords or not WB.near(src, p.coords, 4.0) then return nil, 'Trop loin' end
    local ok, err = WB.hasAccess(x, e.settings.access)
    if not ok then return nil, err end
    return e, p, x
end

local function key(prefix, x, e, lic) return ('%s:%s:%d:%s'):format(prefix, x.identifier, e.id, lic.id) end

local function cooldownLeft(x, e, lic) return math.max(0, (WB.State[key('drvc', x, e, lic)] or 0) - os.time()) end
local function theoryDone(x, e, lic) return (WB.State[key('drvt', x, e, lic)] or 0) > 0 end

-- Vérifie qu'on peut entamer un examen ; retourne nil ou un message
local function blocked(src, x, e, lic, part)
    if WB.hasLicense(src, lic.id) then return 'Tu as déjà ce permis' end
    local cd = cooldownLeft(x, e, lic)
    if cd > 0 then return ('Tu pourras repasser dans %d min'):format(math.ceil(cd / 60)) end
    if lic.requires and lic.requires ~= '' and not WB.hasLicense(src, lic.requires) then return 'Il te faut d\'abord le permis : ' .. lic.requires end
    if part == 'practical' and lic.theory.enabled and not theoryDone(x, e, lic) then return 'Tu dois d\'abord réussir le code' end
    return nil
end

ESX.RegisterServerCallback('worldbuilder:driving:info', function(src, cb, eid, pi)
    local e, p, x = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local s, list = e.settings, {}
    for _, l in ipairs(s.licenses or {}) do
        local owned = WB.hasLicense(src, l.id)
        local reason = (not owned) and (blocked(src, x, e, l, 'theory')) or nil
        local lock
        if not owned then
            if cooldownLeft(x, e, l) > 0 then lock = reason
            elseif l.requires and l.requires ~= '' and not WB.hasLicense(src, l.requires) then lock = reason end
        end
        list[#list + 1] = { id = l.id, label = l.label ~= '' and l.label or l.id, owned = owned, lock = lock,
            theory = l.theory.enabled and { price = l.theoryPrice, count = math.min(l.theory.count, #l.theory.questions), passPercent = l.theory.passPercent, done = theoryDone(x, e, l) } or nil,
            practical = l.practical.enabled and { price = l.practicalPrice, speedLimit = l.practical.speedLimit, maxFaults = l.practical.maxFaults } or nil,
            canTheory = not owned and not lock and l.theory.enabled and not theoryDone(x, e, l) and #l.theory.questions > 0,
            canPractical = not owned and not lock and l.practical.enabled and (not l.theory.enabled or theoryDone(x, e, l)) }
    end
    cb({ ok = true, label = p.label ~= '' and p.label or e.label, licenses = list, payments = WB.paymentsList(s.payments, x) })
end)

-- ═══════════════ Code de la route ═══════════════
ESX.RegisterServerCallback('worldbuilder:driving:theoryStart', function(src, cb, eid, pi, licId, method)
    local e, p, x = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local lic = licenseOf(e, licId)
    if not lic or not lic.theory.enabled or #lic.theory.questions == 0 then return cb({ ok = false, error = 'Examen indisponible' }) end
    local why = blocked(src, x, e, lic, 'theory')
    if why then return cb({ ok = false, error = why }) end
    if theoryDone(x, e, lic) then return cb({ ok = false, error = 'Code déjà réussi' }) end
    local okp, err = WB.charge(x, e.settings.payments, method, lic.theoryPrice, 'Auto-école : ' .. lic.label)
    if not okp then return cb({ ok = false, error = err }) end
    WB.society(e.settings.society, lic.theoryPrice)
    -- tirage au sort des questions et mélange des réponses
    local pool = {}
    for i, q in ipairs(lic.theory.questions) do pool[#pool + 1] = i end
    for i = #pool, 2, -1 do local j = math.random(i) pool[i], pool[j] = pool[j], pool[i] end
    local n = math.min(lic.theory.count, #pool)
    local asked, out = {}, {}
    for k = 1, n do
        local q = lic.theory.questions[pool[k]]
        local order = {}
        for i = 1, #q.answers do order[i] = i end
        for i = #order, 2, -1 do local j = math.random(i) order[i], order[j] = order[j], order[i] end
        local answers, correct = {}, 1
        local right = math.min(q.correct, #q.answers)
        for pos, orig in ipairs(order) do answers[pos] = q.answers[orig] if orig == right then correct = pos end end
        asked[k] = correct
        out[k] = { q = q.q, answers = answers }
    end
    Exams[src] = { kind = 'theory', eid = e.id, lic = lic.id, correct = asked, startedAt = GetGameTimer() }
    WB.stat(e, 'revenue', lic.theoryPrice) WB.stat(e, 'exams', 1)
    cb({ ok = true, questions = out, passPercent = lic.theory.passPercent, label = lic.label })
end)

ESX.RegisterServerCallback('worldbuilder:driving:theorySubmit', function(src, cb, answers)
    local ex = Exams[src]
    local x = ESX.GetPlayerFromId(src)
    local e = ex and WB.Entities[ex.eid]
    if not ex or ex.kind ~= 'theory' or not e or not x then return cb({ ok = false, error = 'Aucun examen en cours' }) end
    Exams[src] = nil
    local lic = licenseOf(e, ex.lic)
    if not lic then return cb({ ok = false, error = 'Permis introuvable' }) end
    answers = type(answers) == 'table' and answers or {}
    local right = 0
    for i, c in ipairs(ex.correct) do if tonumber(answers[i]) == c then right = right + 1 end end
    local pct = math.floor(right * 100 / #ex.correct)
    local passed = pct >= lic.theory.passPercent
    local granted = false
    if passed then
        WB.setState(key('drvt', x, e, lic), 1)
        if not lic.practical.enabled then WB.giveLicense(src, lic.id) granted = true WB.stat(e, 'passed', 1) end
    else
        WB.setState(key('drvc', x, e, lic), os.time() + (e.settings.cooldown or 0) * 60)
    end
    WB.log(e, x, 'theory', ('%s : %d/%d (%s)'):format(lic.id, right, #ex.correct, passed and 'réussi' or 'raté'))
    cb({ ok = true, passed = passed, right = right, total = #ex.correct, percent = pct, need = lic.theory.passPercent, granted = granted, practical = lic.practical.enabled })
end)

-- ═══════════════ Conduite ═══════════════
local function dist(a, b) return #(vector3(a.x, a.y, a.z) - vector3(b.x, b.y, b.z)) end

ESX.RegisterServerCallback('worldbuilder:driving:practicalStart', function(src, cb, eid, pi, licId, spawnPi, method)
    if Exams[src] then return cb({ ok = false, error = 'Un examen est déjà en cours' }) end
    local e, p, x = resolve(src, eid, pi)
    if not e then return cb({ ok = false, error = p }) end
    local lic = licenseOf(e, licId)
    if not lic or not lic.practical.enabled or lic.practical.model == '' then return cb({ ok = false, error = 'Examen indisponible' }) end
    local why = blocked(src, x, e, lic, 'practical')
    if why then return cb({ ok = false, error = why }) end
    local spawn = e.points[tonumber(spawnPi) or 0]
    if not spawn or spawn.kind ~= 'spawn' or not spawn.coords then return cb({ ok = false, error = 'Aucun point de départ configuré' }) end
    local route, len, last = {}, 0, spawn.coords
    for _, pt in ipairs(e.points) do
        if pt.kind == 'checkpoint' and pt.coords then route[#route + 1] = pt.coords len = len + dist(last, pt.coords) last = pt.coords end
    end
    if #route == 0 then return cb({ ok = false, error = 'Aucun point de passage configuré' }) end
    local okp, err = WB.charge(x, e.settings.payments, method, lic.practicalPrice, 'Auto-école : ' .. lic.label)
    if not okp then return cb({ ok = false, error = err }) end
    WB.society(e.settings.society, lic.practicalPrice)
    local plate = ('ECOLE%d'):format(math.random(10, 99))
    Exams[src] = { kind = 'practical', eid = e.id, lic = lic.id, startedAt = GetGameTimer(), minMs = math.floor(len / 45 * 1000), maxFaults = lic.practical.maxFaults }
    WB.stat(e, 'revenue', lic.practicalPrice) WB.stat(e, 'exams', 1)
    cb({ ok = true, model = lic.practical.model, plate = plate, speedLimit = lic.practical.speedLimit, maxFaults = lic.practical.maxFaults, label = lic.label, route = route, spawn = spawn.coords })
end)

RegisterNetEvent('worldbuilder:server:drivingFinish', function(success, faults, reason)
    local src = source
    local ex = Exams[src]
    local x = ESX.GetPlayerFromId(src)
    local e = ex and WB.Entities[ex.eid]
    if not ex or ex.kind ~= 'practical' or not e or not x then return end
    Exams[src] = nil
    local lic = licenseOf(e, ex.lic)
    if not lic then return end
    faults = math.floor(tonumber(faults) or 99)
    local elapsed = GetGameTimer() - ex.startedAt
    local passed = success == true and faults <= ex.maxFaults and elapsed >= ex.minMs
    if success == true and elapsed < ex.minMs then WB.notify(src, 'Examen invalidé (parcours effectué trop vite).', 'error') end
    if passed then
        WB.giveLicense(src, lic.id)
        WB.stat(e, 'passed', 1)
        WB.notify(src, ('Félicitations ! Tu as obtenu le permis : %s (%d faute(s)).'):format(lic.label, faults), 'success')
    else
        WB.setState(key('drvc', x, e, lic), os.time() + (e.settings.cooldown or 0) * 60)
        WB.notify(src, ('Examen raté%s. Il te faudra le repasser.'):format(reason and reason ~= '' and (' : ' .. tostring(reason):sub(1, 60)) or ''), 'error')
    end
    WB.log(e, x, 'practical', ('%s : %d faute(s) (%s)'):format(lic.id, faults, passed and 'réussi' or 'raté'))
end)

AddEventHandler('playerDropped', function() Exams[source] = nil end)
