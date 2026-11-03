-- ─────────────────────────────── EMS avancé : blessures, saignements, soins, RCR, dossier, transfusion, triage ───────────────────────────────
-- Le client signale seulement « je suis touché à la zone X » ; le serveur valide (la vie a réellement baissé), décide de la gravité, du saignement et des effets.
local ESX = exports['es_extended']:getSharedObject()
local function xp(src, a, o) if GetResourceState('pickax_xp') == 'started' then pcall(function() exports['pickax_xp']:AddXP(src, a, o) end) end end
local C = Config

local S = {}            -- [src] = { zones = { [zone] = { lvl, bleed, kind, hidden } }, blood = 100, lastHurt = {} }
local Pending = {}      -- [src] = { kind, target, zone, at, ... }
local Tags = {}         -- [patient src] = { tag, by, at }
local triageScore = {}  -- [medic identifier] = { ok, total }

local function now() return os.time() end
local function clamp(v, a, b) return math.max(a, math.min(b, v)) end
local function st(src) local s = S[src] if not s then s = { zones = {}, blood = 100, lastHurt = {} } S[src] = s end return s end

CreateThread(function()
    Wait(900)
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS medical_records (id INT AUTO_INCREMENT PRIMARY KEY, patient VARCHAR(80) NOT NULL, kind VARCHAR(20) NOT NULL,
        text VARCHAR(500) NOT NULL, medic VARCHAR(100) NULL, at INT NOT NULL, INDEX idx_patient (patient)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
end)

-- ═══════════════ Rôles ═══════════════
local function isEms(x)
    if not x or not x.job then return false end
    for _, j in ipairs(C.Jobs) do if x.job.name == j then return true end end
    if GetResourceState('pickax_jobbuilder') == 'started' then
        local ok, t = pcall(function() return exports.pickax_jobbuilder:GetJobType(x.job.name) end)
        if ok and t then for _, jt in ipairs(C.JobTypes) do if t == jt then return true end end end
    end
    return false
end
local function isDead(src)
    if GetResourceState('pickax_jobbuilder') == 'started' then
        local ok, d = pcall(function() return exports.pickax_jobbuilder:IsPlayerDead(src) end)
        if ok and d then return true end
    end
    return GetEntityHealth(GetPlayerPed(src)) <= 105
end
local function near(a, b, d) return #(GetEntityCoords(GetPlayerPed(a)) - GetEntityCoords(GetPlayerPed(b))) <= d end
local function atHospital(src)
    if #C.Hospitals == 0 then return true end
    local p = GetEntityCoords(GetPlayerPed(src))
    for _, h in ipairs(C.Hospitals) do if #(p - h.coords) <= h.radius then return true end end
    return false
end

-- ═══════════════ Groupe sanguin (déterministe, jamais envoyé avant un test) ═══════════════
local GROUPS = { { 'O+', 38 }, { 'A+', 34 }, { 'B+', 9 }, { 'O-', 7 }, { 'A-', 6 }, { 'AB+', 3 }, { 'B-', 2 }, { 'AB-', 1 } }
local function bloodGroupOf(identifier)
    local h = (joaat('BG:' .. tostring(identifier) .. ':' .. C.Blood.Salt) & 0xFFFFFF) % 100
    local acc = 0
    for _, g in ipairs(GROUPS) do acc = acc + g[2] if h < acc then return g[1] end end
    return 'O+'
end
exports('BloodGroupOf', bloodGroupOf)

-- Compatibilité donneur → receveur (ABO + Rh)
local function compatible(donor, recv)
    local dA, dR = donor:gsub('[+-]', ''), donor:sub(-1)
    local rA, rR = recv:gsub('[+-]', ''), recv:sub(-1)
    local okABO = (dA == 'O') or (dA == rA) or (rA == 'AB')
    local okRh = (dR == '-') or (rR == '+')
    return okABO and okRh
end

-- ═══════════════ État public (statebag lu par le client du blessé) ═══════════════
local function publish(src)
    local s = st(src)
    local z = {}
    for name, v in pairs(s.zones) do z[name] = { lvl = v.lvl, bleed = v.bleed } end
    Player(src).state:set('med', { zones = z, blood = math.floor(s.blood) }, true)
end
exports('ClearInjuries', function(src) S[tonumber(src)] = nil Tags[tonumber(src)] = nil publish(tonumber(src)) end)
RegisterNetEvent('jobbuilder:server:revived', function() local s = source if S[s] then S[s].blood = math.max(S[s].blood, 45) publish(s) end end)
AddEventHandler('playerDropped', function() local s = source S[s], Pending[s], Tags[s] = nil, nil, nil end)

-- ═══════════════ Un coup reçu ═══════════════
local KIND = { head = 'commotion', torso = 'hémorragie interne', larm = 'fracture', rarm = 'fracture', lleg = 'fracture', rleg = 'fracture' }
RegisterNetEvent('pickax_medical:hurt', function(zone, dmg)
    local src = source
    if not C.Enabled or not C.Zones[zone] then return end
    dmg = tonumber(dmg) or 0
    if dmg < 3 or dmg > 250 then return end
    local ped = GetPlayerPed(src)
    if GetEntityHealth(ped) >= GetEntityMaxHealth(ped) and dmg < 20 then return end   -- vie pleine : signalement douteux
    local s = st(src)
    local t = GetGameTimer()
    if s.lastHurt[zone] and t - s.lastHurt[zone] < 1500 then return end
    s.lastHurt[zone] = t
    local lvl = dmg >= C.Severity.severe and 3 or dmg >= C.Severity.wound and 2 or 1
    local z = s.zones[zone] or { lvl = 0 }
    if lvl > z.lvl then z.lvl = lvl end
    if z.lvl >= 2 then z.bleed = true end
    if z.lvl == 3 then z.kind = KIND[zone] z.hidden = true elseif z.lvl == 2 then z.kind = 'plaie' else z.kind = z.kind or 'contusion' end
    s.zones[zone] = z
    publish(src)
end)

-- Saignements et récupération
CreateThread(function()
    while true do
        Wait(C.Bleed.Tick * 1000)
        for src, s in pairs(S) do
            local loss, any = 0, false
            for _, z in pairs(s.zones) do
                if z.bleed then any = true loss = loss + C.Bleed.PerLevel * z.lvl end
                if z.lvl == 3 and z.kind == 'hémorragie interne' then any = true loss = loss + C.Bleed.Internal end
            end
            local was = s.blood
            if any then s.blood = clamp(s.blood - loss, 0, 100) else s.blood = clamp(s.blood + C.Bleed.Regen, 0, 100) end
            if math.floor(was) ~= math.floor(s.blood) then publish(src) end
            if s.blood <= C.Bleed.DeathBelow and any then TriggerClientEvent('pickax_medical:blackout', src) end
        end
    end
end)

-- ═══════════════ Examen ═══════════════
local function targetOf(src, id)
    local t = tonumber(id)
    local x = t and ESX.GetPlayerFromId(t)
    if not x or not near(src, t, C.Distance + 2.0) then return nil end
    return t, x
end

local function supplies(src)
    local out = {}
    for k, tr in pairs(C.Treatments) do out[k] = exports.ox_inventory:GetItemCount(src, tr.item) or 0 end
    out.blood_bag = exports.ox_inventory:GetItemCount(src, C.Blood.BagItem) or 0
    return out
end

local function records(identifier)
    local list = MySQL.query.await('SELECT kind, text, medic, at FROM medical_records WHERE patient = ? ORDER BY id DESC LIMIT 12', { identifier }) or {}
    for _, r in ipairs(list) do r.at = os.date('%d/%m/%Y %H:%M', r.at) end
    return list
end

local function patientView(src, t, xt, revealed)
    local s = st(t)
    local zones = {}
    for name, z in pairs(s.zones) do
        local hidden = z.hidden and not (revealed and revealed[name])
        zones[name] = { lvl = hidden and math.min(z.lvl, 2) or z.lvl, bleed = z.bleed, kind = hidden and 'à explorer' or z.kind, hidden = hidden or nil }
    end
    return { id = t, name = xt.getName and xt.getName() or ('#' .. t), dead = isDead(t), blood = math.floor(s.blood), zones = zones, tag = Tags[t] and Tags[t].tag or nil,
        pulse = isDead(t) and 0 or math.floor(70 + (100 - s.blood) * 0.8 + math.random(-3, 3)) }
end

local Revealed = {}   -- [medic src .. ':' .. patient] = { zone = true } (radio réalisée)

ESX.RegisterServerCallback('pickax_medical:exam', function(src, cb, id)
    local x = ESX.GetPlayerFromId(src)
    if not isEms(x) then return cb({ ok = false, error = 'Réservé aux EMS' }) end
    local t, xt = targetOf(src, id)
    if not t then return cb({ ok = false, error = 'Patient trop loin' }) end
    cb({ ok = true, patient = patientView(src, t, xt, Revealed[src .. ':' .. t]), supplies = supplies(src), records = records(xt.identifier), cfg = { zones = C.Zones, treatments = C.Treatments, tags = C.Triage.Tags, hospital = atHospital(src) }, me = x.getName and x.getName() or '' })
end)

-- Radio : révèle les blessures graves cachées (fractures, hémorragie interne, commotion)
ESX.RegisterServerCallback('pickax_medical:xray', function(src, cb, id)
    local x = ESX.GetPlayerFromId(src)
    if not isEms(x) then return cb({ ok = false, error = 'Réservé aux EMS' }) end
    local t, xt = targetOf(src, id)
    if not t then return cb({ ok = false, error = 'Patient trop loin' }) end
    if C.RequireHospitalFor.xray and not atHospital(src) then return cb({ ok = false, error = 'Il faut être à l\'hôpital (imagerie)' }) end
    local rev = {}
    local found = {}
    for name, z in pairs(st(t).zones) do if z.hidden then rev[name] = true found[#found + 1] = ('%s : %s'):format(C.Zones[name], z.kind) end end
    Revealed[src .. ':' .. t] = rev
    MySQL.insert('INSERT INTO medical_records (patient, kind, text, medic, at) VALUES (?,?,?,?,?)', { xt.identifier, 'radio', #found > 0 and ('Radio : ' .. table.concat(found, ' ; ')) or 'Radio : RAS', x.getName and x.getName() or '', now() })
    cb({ ok = true, seconds = C.Exam.XraySeconds, found = found })
end)

-- Prise de sang : groupe sanguin + taux d'alcool (si pickax_justice est installé)
ESX.RegisterServerCallback('pickax_medical:bloodTest', function(src, cb, id)
    local x = ESX.GetPlayerFromId(src)
    if not isEms(x) then return cb({ ok = false, error = 'Réservé aux EMS' }) end
    local t, xt = targetOf(src, id)
    if not t then return cb({ ok = false, error = 'Patient trop loin' }) end
    if C.Exam.BloodTestItem ~= '' and not exports.ox_inventory:RemoveItem(src, C.Exam.BloodTestItem, 1) then return cb({ ok = false, error = 'Il te faut : ' .. C.Exam.BloodTestItem }) end
    local group = bloodGroupOf(xt.identifier)
    local alc
    if GetResourceState('pickax_justice') == 'started' then local ok, v = pcall(function() return exports.pickax_justice:AlcoholOf(t) end) if ok then alc = v end end
    local txt = ('Groupe sanguin %s%s'):format(group, alc and (' — alcoolémie %.2f g/L'):format(alc) or '')
    MySQL.insert('INSERT INTO medical_records (patient, kind, text, medic, at) VALUES (?,?,?,?,?)', { xt.identifier, 'sang', txt, x.getName and x.getName() or '', now() })
    cb({ ok = true, group = group, alcohol = alc })
end)

-- ═══════════════ Soins : début → mini-jeu (client) → fin ═══════════════
local function zoneState(t, zone) return st(t).zones[zone] end

ESX.RegisterServerCallback('pickax_medical:treatBegin', function(src, cb, id, zone, kind)
    local x = ESX.GetPlayerFromId(src)
    if not isEms(x) then return cb({ ok = false, error = 'Réservé aux EMS' }) end
    local t, xt = targetOf(src, id)
    local tr = C.Treatments[tostring(kind or '')]
    local z = t and C.Zones[zone] and zoneState(t, zone)
    if not t or not tr then return cb({ ok = false, error = 'Soin impossible' }) end
    if isDead(t) then return cb({ ok = false, error = 'Le patient est en arrêt : réanime-le d\'abord' }) end
    if not z then return cb({ ok = false, error = 'Aucune blessure à cet endroit' }) end
    local ok = (tr.only == 'bleeding' and z.bleed) or (tr.only == 'wound' and z.lvl == 2) or (tr.only == 'fracture' and z.lvl == 3 and z.kind == 'fracture') or (tr.only == 'severe' and z.lvl == 3 and z.kind ~= 'fracture')
    if not ok then return cb({ ok = false, error = 'Ce soin ne convient pas à cette blessure' }) end
    if z.hidden and not (Revealed[src .. ':' .. t] or {})[zone] then return cb({ ok = false, error = 'Blessure grave non identifiée : fais une radio' }) end
    if tr.hospital and C.RequireHospitalFor.surgery and not atHospital(src) then return cb({ ok = false, error = 'Chirurgie : bloc opératoire de l\'hôpital uniquement' }) end
    if (exports.ox_inventory:GetItemCount(src, tr.item) or 0) < 1 then return cb({ ok = false, error = 'Il te faut : ' .. tr.item }) end
    Pending[src] = { kind = 'treat', t = t, zone = zone, tk = kind, at = GetGameTimer() }
    local cfg = {} for k, v in pairs(tr.cfg) do cfg[k] = v end
    cfg.seed, cfg.title = math.random(1, 2147483000), tr.label .. ' — ' .. C.Zones[zone]
    cb({ ok = true, game = tr.game, cfg = cfg })
end)

ESX.RegisterServerCallback('pickax_medical:treatEnd', function(src, cb, score)
    local x = ESX.GetPlayerFromId(src)
    local p = Pending[src]
    Pending[src] = nil
    if not isEms(x) or not p or p.kind ~= 'treat' then return cb({ ok = false, error = 'Aucun soin en cours' }) end
    if GetGameTimer() - p.at < 5000 then return cb({ ok = false, error = 'Soin trop rapide : refusé' }) end
    local tr, z = C.Treatments[p.tk], zoneState(p.t, p.zone)
    if not tr or not z or not near(src, p.t, C.Distance + 3.0) then return cb({ ok = false, error = 'Patient hors de portée' }) end
    score = clamp(math.floor(tonumber(score) or 0), 0, 100)
    exports.ox_inventory:RemoveItem(src, tr.item, 1)
    if score < tr.min then return cb({ ok = true, failed = true, msg = tr.label .. ' raté : le matériel est perdu et la blessure demeure.' }) end
    local s = st(p.t)
    if p.tk == 'bandage' then z.bleed = false
    elseif p.tk == 'suture' then z.bleed = false z.lvl, z.kind = 1, 'contusion'
    elseif p.tk == 'splint' then z.lvl, z.kind, z.hidden, z.bleed = 1, 'contusion', nil, false
    elseif p.tk == 'surgery' then z.lvl, z.kind, z.hidden, z.bleed = 1, 'contusion', nil, false end
    if z.lvl <= 1 and not z.bleed then s.zones[p.zone] = (z.lvl == 1 and z) or nil end
    publish(p.t)
    local xt = ESX.GetPlayerFromId(p.t)
    if xt then MySQL.insert('INSERT INTO medical_records (patient, kind, text, medic, at) VALUES (?,?,?,?,?)', { xt.identifier, 'soin', ('%s — %s'):format(tr.label, C.Zones[p.zone]), x.getName and x.getName() or '', now() }) end
    xp(src, 'treat')
    cb({ ok = true, msg = ('%s réussi (%d %%).'):format(tr.label, score) })
end)

-- ═══════════════ Réanimation (RCR) ═══════════════
ESX.RegisterServerCallback('pickax_medical:cprBegin', function(src, cb, id)
    local x = ESX.GetPlayerFromId(src)
    if not isEms(x) then return cb({ ok = false, error = 'Réservé aux EMS' }) end
    local t = targetOf(src, id)
    if not t then return cb({ ok = false, error = 'Patient trop loin' }) end
    if not isDead(t) then return cb({ ok = false, error = 'Le patient n\'est pas en arrêt' }) end
    Pending[src] = { kind = 'cpr', t = t, at = GetGameTimer() }
    local cfg = {} for k, v in pairs(C.Cpr.cfg) do cfg[k] = v end
    cb({ ok = true, cfg = cfg })
end)

ESX.RegisterServerCallback('pickax_medical:cprEnd', function(src, cb, score)
    local x = ESX.GetPlayerFromId(src)
    local p = Pending[src]
    Pending[src] = nil
    if not isEms(x) or not p or p.kind ~= 'cpr' then return cb({ ok = false, error = 'Aucun massage en cours' }) end
    if GetGameTimer() - p.at < 15000 then return cb({ ok = false, error = 'Massage trop court : refusé' }) end
    if not near(src, p.t, C.Distance + 3.0) or not isDead(p.t) then return cb({ ok = false, error = 'Le patient n\'est plus à portée / en arrêt' }) end
    score = clamp(math.floor(tonumber(score) or 0), 0, 100)
    if score < C.Cpr.min then return cb({ ok = true, failed = true, msg = 'Massage insuffisant : le patient n\'a pas repris. Recommence.' }) end
    local bonus = 0
    if C.Cpr.DefibItem ~= '' and (exports.ox_inventory:GetItemCount(src, C.Cpr.DefibItem) or 0) > 0 then bonus = C.Cpr.DefibBonus end
    local hp = clamp(C.Cpr.health + math.floor(score * C.Cpr.healthBonus) + bonus, 1, 100)
    local ok = GetResourceState('pickax_jobbuilder') == 'started' and pcall(function() exports.pickax_jobbuilder:RevivePlayer(p.t, hp) end)
    if not ok then TriggerClientEvent('pickax_medical:revive', p.t, hp) end
    local s = st(p.t); s.blood = math.max(s.blood, 30) publish(p.t)
    local xt = ESX.GetPlayerFromId(p.t)
    if xt then MySQL.insert('INSERT INTO medical_records (patient, kind, text, medic, at) VALUES (?,?,?,?,?)', { xt.identifier, 'rcr', ('Réanimation réussie (%d %%)'):format(score), x.getName and x.getName() or '', now() }) end
    cb({ ok = true, msg = ('Le patient a repris conscience (%d %%).'):format(score) })
end)

-- ═══════════════ Dons du sang et transfusions ═══════════════
ESX.RegisterServerCallback('pickax_medical:donate', function(src, cb, id)
    local x = ESX.GetPlayerFromId(src)
    if not isEms(x) then return cb({ ok = false, error = 'Réservé aux EMS' }) end
    local t, xt = targetOf(src, id)
    if not t or t == src then return cb({ ok = false, error = 'Donneur invalide' }) end
    local s = st(t)
    if s.blood < C.Blood.Min then return cb({ ok = false, error = 'Le donneur a perdu trop de sang' }) end
    if not exports.ox_inventory:CanCarryItem(src, C.Blood.BagItem, 1) then return cb({ ok = false, error = 'Tu ne peux pas porter plus' }) end
    s.blood = s.blood - C.Blood.Donation publish(t)
    local group = bloodGroupOf(xt.identifier)
    exports.ox_inventory:AddItem(src, C.Blood.BagItem, 1, { group = group, label = ('Poche de sang %s'):format(group), description = ('Prélevée le %s'):format(os.date('%d/%m/%Y %H:%M')) })
    cb({ ok = true, msg = ('Poche de sang %s prélevée.'):format(group) })
end)

ESX.RegisterServerCallback('pickax_medical:transfuseBegin', function(src, cb, id)
    local x = ESX.GetPlayerFromId(src)
    if not isEms(x) then return cb({ ok = false, error = 'Réservé aux EMS' }) end
    local t = targetOf(src, id)
    if not t then return cb({ ok = false, error = 'Patient trop loin' }) end
    if (exports.ox_inventory:GetItemCount(src, C.Blood.BagItem) or 0) < 1 then return cb({ ok = false, error = 'Il te faut une poche de sang' }) end
    Pending[src] = { kind = 'transfuse', t = t, at = GetGameTimer() }
    cb({ ok = true, game = 'timing', cfg = { rounds = 2, seconds = 18, title = 'Transfusion', difficulty = 0 } })
end)

ESX.RegisterServerCallback('pickax_medical:transfuseEnd', function(src, cb, score)
    local x = ESX.GetPlayerFromId(src)
    local p = Pending[src]
    Pending[src] = nil
    if not isEms(x) or not p or p.kind ~= 'transfuse' then return cb({ ok = false, error = 'Aucune transfusion en cours' }) end
    if GetGameTimer() - p.at < 4000 then return cb({ ok = false, error = 'Trop rapide' }) end
    local xt = ESX.GetPlayerFromId(p.t)
    if not xt or not near(src, p.t, C.Distance + 3.0) then return cb({ ok = false, error = 'Patient hors de portée' }) end
    -- la première poche de l'inventaire du soignant
    local bag
    for _, sl in pairs(exports.ox_inventory:GetInventoryItems(src) or {}) do if sl.name == C.Blood.BagItem then bag = sl break end end
    if not bag then return cb({ ok = false, error = 'Il te faut une poche de sang' }) end
    exports.ox_inventory:RemoveItem(src, C.Blood.BagItem, 1, nil, bag.slot)
    score = clamp(math.floor(tonumber(score) or 0), 0, 100)
    local s = st(p.t)
    local donor, recv = bag.metadata and bag.metadata.group or 'O+', bloodGroupOf(xt.identifier)
    local txt
    if not compatible(donor, recv) then
        s.blood = clamp(s.blood - C.Blood.Reaction, 0, 100)
        txt = ('Réaction transfusionnelle : poche %s incompatible avec un patient %s !'):format(donor, recv)
        cb({ ok = true, failed = true, msg = txt })
    else
        local gain = math.floor(C.Blood.Transfuse * (0.5 + 0.5 * score / 100))
        s.blood = clamp(s.blood + gain, 0, 100)
        txt = ('Transfusion réussie (+%d %% de sang).'):format(gain)
        cb({ ok = true, msg = txt })
    end
    publish(p.t)
    MySQL.insert('INSERT INTO medical_records (patient, kind, text, medic, at) VALUES (?,?,?,?,?)', { xt.identifier, 'transfusion', txt, x.getName and x.getName() or '', now() })
end)

-- ═══════════════ Triage ═══════════════
local function priorityOf(v)
    if v.dead then return 'black' end
    local worst = 0
    for _, z in pairs(v.zones) do worst = math.max(worst, z.lvl) end
    if v.blood < 35 or worst == 3 and v.blood < 60 then return 'red' end
    if worst >= 2 or v.blood < 70 then return 'orange' end
    return 'green'
end

ESX.RegisterServerCallback('pickax_medical:triageList', function(src, cb)
    local x = ESX.GetPlayerFromId(src)
    if not isEms(x) then return cb({ ok = false, error = 'Réservé aux EMS' }) end
    local mc = GetEntityCoords(GetPlayerPed(src))
    local list = {}
    for _, p in ipairs(GetPlayers()) do
        local t = tonumber(p)
        local xt = t ~= src and ESX.GetPlayerFromId(t)
        if xt and #(GetEntityCoords(GetPlayerPed(t)) - mc) <= C.Triage.Range then
            local v = patientView(src, t, xt, nil)
            if v.dead or v.blood < 100 or next(v.zones) then list[#list + 1] = { id = t, name = v.name, dead = v.dead, blood = v.blood, tag = v.tag, injuries = (function() local n = 0 for _ in pairs(v.zones) do n = n + 1 end return n end)(), dist = math.floor(#(GetEntityCoords(GetPlayerPed(t)) - mc)) } end
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    local sc = triageScore[x.identifier] or { ok = 0, total = 0 }
    cb({ ok = true, list = list, tags = C.Triage.Tags, score = sc })
end)

ESX.RegisterServerCallback('pickax_medical:triageTag', function(src, cb, id, tag)
    local x = ESX.GetPlayerFromId(src)
    if not isEms(x) then return cb({ ok = false, error = 'Réservé aux EMS' }) end
    local t, xt = targetOf(src, id)
    if not t or not C.Triage.Tags[tostring(tag or '')] then return cb({ ok = false, error = 'Impossible' }) end
    local right = priorityOf(patientView(src, t, xt, { head = true, torso = true, larm = true, rarm = true, lleg = true, rleg = true }))
    Tags[t] = { tag = tag, by = src, at = now() }
    local sc = triageScore[x.identifier] or { ok = 0, total = 0 }
    sc.total = sc.total + 1 if right == tag then sc.ok = sc.ok + 1 end
    triageScore[x.identifier] = sc
    TriggerClientEvent('pickax_medical:tag', -1, t, tag)
    cb({ ok = true, correct = right == tag, expected = right, score = sc })
end)

exports('IsEms', function(src) return isEms(ESX.GetPlayerFromId(tonumber(src) or 0)) end)
