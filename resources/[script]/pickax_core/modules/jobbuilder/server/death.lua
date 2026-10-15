-- ─────────────────────────────── Mort, appel des EMS, réanimation, réapparition ───────────────────────────────
-- Le joueur mort appelle les EMS : tous les employés de jobs de type « ems » reçoivent une alerte + un blip à sa position.
-- Un EMS prend l'appel (touche Y ou F6 → Appels EMS), arrive, puis F6 → Réanimer (massage cardiaque, durée serveur vérifiée).

local D = Config.Death
local function fail(msg) return { ok = false, error = msg } end

function JB.deathActive()
    if D.Mode == 'on' then return true end
    if D.Mode == 'off' then return false end
    return GetResourceState('esx_ambulancejob') ~= 'started'
end

local dead = {}        -- [src] = { t, x, y, z, name, lastCall }
local calls = {}       -- [patient src] = { id, x, y, z, name, t, units = { [ems src] = name } }
local cpr = {}         -- [ems src] = { target, ready }
local nextId = 1
local lastAlert = {}   -- [ems src] = patient src : dernier appel reçu (touche Y)

local function emsMembers()
    local out = {}
    for name, job in pairs(JB.Jobs) do
        if job.type == 'ems' and (job.settings or {}).ems_receive ~= false then
            local ok, list = pcall(ESX.GetExtendedPlayers, 'job', name)
            if ok and list then for _, p in ipairs(list) do out[#out + 1] = p end end
        end
    end
    return out
end

local function unitCount(c)
    local n = 0
    for _ in pairs(c.units) do n = n + 1 end
    return n
end

local function endCall(patient)
    local c = calls[patient]
    if not c then return end
    calls[patient] = nil
    for _, m in ipairs(emsMembers()) do TriggerClientEvent('jobbuilder:client:emsCallEnd', m.source, c.id) end
    for src, p in pairs(lastAlert) do if p == patient then lastAlert[src] = nil end end
end

local function identityName(x)
    local first = x.get and x.get('firstName') or nil
    local last = x.get and x.get('lastName') or nil
    if first and first ~= '' then return ('%s %s'):format(first, last or '') end
    return JB.playerName(x)
end

local function setDead(src, state)
    pcall(function() Player(src).state:set('jbDead', state, true) end)
end

local function respawnDelay()
    return #emsMembers() == 0 and D.NoEmsRespawn or D.RespawnTime
end

-- ── Événements client ──
RegisterNetEvent('jobbuilder:server:died', function()
    local src = source
    if not JB.deathActive() or not ESX.GetPlayerFromId(src) then return end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local c = GetEntityCoords(ped)
    dead[src] = { t = os.time(), x = c.x, y = c.y, z = c.z, name = identityName(ESX.GetPlayerFromId(src)), lastCall = 0 }
    setDead(src, true)
end)

local function revived(src)
    if not dead[src] then return end
    dead[src] = nil
    setDead(src, false)
    endCall(src)
end

RegisterNetEvent('jobbuilder:server:revived', function() revived(source) end)
AddEventHandler('playerDropped', function() local s = source revived(s) cpr[s] = nil lastAlert[s] = nil end)

-- ── État affiché au joueur mort (minuteur, EMS prévenus / en route) ──
ESX.RegisterServerCallback('jobbuilder:death:state', function(src, cb)
    local d = dead[src]
    if not d then return cb({ ok = false }) end
    local c = calls[src]
    cb({ ok = true, left = math.max(0, respawnDelay() - (os.time() - d.t)), called = c ~= nil, units = c and unitCount(c) or 0, ems = #emsMembers(),
        cooldown = math.max(0, D.CallCooldown - (os.time() - d.lastCall)) })
end)

ESX.RegisterServerCallback('jobbuilder:death:call', function(src, cb)
    local d = dead[src]
    if not d then return cb(fail('Tu n\'es pas inconscient')) end
    if os.time() - d.lastCall < D.CallCooldown then return cb(fail('Patiente avant de rappeler')) end
    local members = emsMembers()
    if #members == 0 then return cb(fail('Aucun médecin n\'est en service pour le moment')) end
    d.lastCall = os.time()
    endCall(src)
    local c = { id = nextId, x = d.x, y = d.y, z = d.z, name = d.name, t = os.time(), units = {} }
    nextId = nextId + 1
    calls[src] = c
    for _, m in ipairs(members) do
        lastAlert[m.source] = src
        TriggerClientEvent('jobbuilder:client:emsCall', m.source, { id = c.id, x = c.x, y = c.y, z = c.z, name = c.name })
    end
    cb({ ok = true, ems = #members })
end)

-- ── Réapparition à l'hôpital le plus proche ──
ESX.RegisterServerCallback('jobbuilder:death:respawn', function(src, cb)
    local d = dead[src]
    local x = ESX.GetPlayerFromId(src)
    if not d or not x then return cb(fail('Tu n\'es pas inconscient')) end
    if os.time() - d.t < respawnDelay() then return cb(fail('Il est encore trop tôt')) end
    local best, bd
    for _, h in ipairs(D.Hospitals) do
        local dist = (h[2] - d.x) ^ 2 + (h[3] - d.y) ^ 2
        if not bd or dist < bd then best, bd = h, dist end
    end
    if not best then return cb(fail('Aucun hôpital configuré')) end
    -- Frais de soins : prélevés sur le compte choisi puis sur l'autre ; soins complets en échange (vie, faim, soif)
    local fee, paid = D.RespawnFee, 0
    if fee > 0 then
        local first = D.FeeAccount == 'money' and 'money' or 'bank'
        local second = first == 'bank' and 'money' or 'bank'
        local total = x.getAccount(first).money + x.getAccount(second).money
        if total < fee and D.UnpaidAllowed == false then
            return cb(fail(('Il te faut %d $ pour être soigné (tu as %d $)'):format(fee, total)))
        end
        for _, acc in ipairs({ first, second }) do
            local take = math.min(fee - paid, x.getAccount(acc).money)
            if take > 0 then x.removeAccountMoney(acc, take) paid = paid + take end
        end
        JB.log('_hospital', x, 'hospital_fee', ('%d$ sur %d$ (%s)'):format(paid, fee, best[1]))
    end
    revived(src)
    cb({ ok = true, x = best[2], y = best[3], z = best[4], h = best[5] or 0.0, label = best[1], fee = fee, paid = paid, health = D.RespawnHealth, restore = D.RestoreStatus ~= false })
end)

-- ── Côté EMS ──
local function isEms(src)
    local x = ESX.GetPlayerFromId(src)
    local job = x and JB.Jobs[x.job.name]
    return x, job and job.type == 'ems' and (job.settings or {}).ems_receive ~= false and job
end

-- Liste des urgences en cours, triée par distance (partagée avec la tablette médicale)
function JB.emsCallList(src)
    local me = GetEntityCoords(GetPlayerPed(src))
    local list = {}
    for _, c in pairs(calls) do
        local units = {}
        for u, name in pairs(c.units) do units[#units + 1] = { src = u, name = name } end
        list[#list + 1] = { id = c.id, name = c.name, x = c.x, y = c.y, t = c.t, units = units, dist = math.floor(#(vector3(c.x, c.y, c.z) - me)), mine = c.units[src] ~= nil, manual = c.manual or false }
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

-- Agents actuellement engagés sur une urgence : [src] = true
function JB.emsBusy()
    local busy = {}
    for _, c in pairs(calls) do for u in pairs(c.units) do busy[u] = true end end
    return busy
end

-- Urgence créée par un EMS (accident, malaise vu sur place…) à sa position
function JB.emsCreate(src, title)
    local x = ESX.GetPlayerFromId(src)
    if not x then return false end
    local ped = GetPlayerPed(src)
    local pos = GetEntityCoords(ped)
    local key = 'm' .. nextId
    local c = { id = nextId, x = pos.x, y = pos.y, z = pos.z, name = tostring(title or 'Urgence'):gsub('%c', ' '):sub(1, 60), t = os.time(), units = {}, manual = true }
    nextId = nextId + 1
    calls[key] = c
    for _, m in ipairs(emsMembers()) do
        lastAlert[m.source] = key
        TriggerClientEvent('jobbuilder:client:emsCall', m.source, { id = c.id, x = c.x, y = c.y, z = c.z, name = c.name })
    end
    JB.log(x.job.name, x, 'ems_call', c.name)
    return true
end

ESX.RegisterServerCallback('jobbuilder:ems:list', function(src, cb)
    local x, job = isEms(src)
    if not x or not job then return cb(fail('Réservé aux services médicaux')) end
    cb({ ok = true, list = JB.emsCallList(src), jobLabel = job.label })
end)

local function callById(id)
    for patient, c in pairs(calls) do if c.id == tonumber(id) then return patient, c end end
end

local function notifyPatient(patient)
    local c = calls[patient]
    if c and type(patient) == 'number' then JBNotifyClient( patient, ('~g~%d médecin(s) en route.'):format(unitCount(c))) end
end

-- id de l'appel (0 = dernier appel reçu, pour la touche Y)
ESX.RegisterServerCallback('jobbuilder:ems:take', function(src, cb, id)
    local x, job = isEms(src)
    if not x or not job then return cb(fail('Réservé aux services médicaux')) end
    local patient, c
    if tonumber(id) and tonumber(id) > 0 then patient, c = callById(id) else patient = lastAlert[src] c = patient and calls[patient] end
    if not c then return cb(fail('Aucun appel en cours')) end
    if c.units[src] then c.units[src] = nil else c.units[src] = JB.playerName(x) end
    local joined = c.units[src] ~= nil
    if joined then notifyPatient(patient) JB.log(job.name, x, 'ems_take', tostring(c.name)) end
    cb({ ok = true, x = c.x, y = c.y, joined = joined, name = c.name })
end)

ESX.RegisterServerCallback('jobbuilder:ems:close', function(src, cb, id)
    local x, job = isEms(src)
    if not x or not job then return cb(fail('Réservé aux services médicaux')) end
    local patient = callById(id)
    if not patient then return cb(fail('Appel introuvable')) end
    endCall(patient)
    cb({ ok = true })
end)

-- ── Massage cardiaque (F6 → Réanimer) ──
function JB.startCpr(src, target)
    if not dead[target] then return false, 'Cette personne n\'a pas besoin d\'être réanimée' end
    cpr[src] = { target = target, ready = GetGameTimer() + math.floor(D.CprSeconds * 1000 * 0.85), expires = GetGameTimer() + D.CprSeconds * 1000 + 60000 }
    TriggerClientEvent('jobbuilder:client:cpr', src, target, D.CprSeconds)
    return true
end

RegisterNetEvent('jobbuilder:server:cprDone', function()
    local src = source
    local c = cpr[src]
    cpr[src] = nil
    if not c or GetGameTimer() < c.ready or GetGameTimer() > c.expires then return end
    local x = ESX.GetPlayerFromId(src)
    local t = ESX.GetPlayerFromId(c.target)
    if not x or not t or not dead[c.target] then return end
    if JB.distanceTo and #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(c.target))) > Config.TargetDistance + 3.0 then return end
    revived(c.target)
    TriggerClientEvent('jobbuilder:client:revive', c.target, D.ReviveHealth)
    if D.RevivePay > 0 then x.addAccountMoney('bank', D.RevivePay) end
    JB.log(x.job.name, x, 'revive', JB.playerName(t))
    JBNotifyClient( src, '~g~Patient réanimé.')
end)

RegisterNetEvent('jobbuilder:server:cprCancel', function() cpr[source] = nil end)

-- ── Commande /revive [id] (staff) : réanime et soigne à 100 % ──
local function canRevive(src)
    if src == 0 or JB.isDev(src) then return true end
    local x = ESX.GetPlayerFromId(src)
    local group = x and x.getGroup and x.getGroup()
    for _, g in ipairs(D.ReviveGroups or {}) do if g == group then return true end end
    return false
end

RegisterCommand(D.ReviveCommand or 'revive', function(src, args)
    local function say(msg)
        if src == 0 then print('[jobbuilder] ' .. msg:gsub('~%a~', '')) else JBNotifyClient( src, msg) end
    end
    if not canRevive(src) then return say('~r~Tu n\'as pas la permission d\'utiliser /' .. (D.ReviveCommand or 'revive')) end
    local target = tonumber(args[1]) or (src ~= 0 and src or nil)
    if not target or not ESX.GetPlayerFromId(target) then return say('~r~Joueur introuvable. Utilisation : /' .. (D.ReviveCommand or 'revive') .. ' [id]') end
    if JB.deathActive() then
        revived(target)
        TriggerClientEvent('jobbuilder:client:revive', target, 100, true)
    else
        TriggerClientEvent(Config.ReviveEvent, target)          -- esx_ambulancejob gère la mort : on utilise son événement
        TriggerClientEvent('jobbuilder:client:revive', target, 100, true)
    end
    say(('~g~Joueur %d réanimé.'):format(target))
    local x = ESX.GetPlayerFromId(src)
    JB.log(x and x.job.name or '_staff', x, 'revive_command', 'ID ' .. target)
end, false)

-- API pour les autres scripts
exports('IsPlayerDead', function(src) return dead[tonumber(src)] ~= nil end)
exports('RevivePlayer', function(src, health)
    src = tonumber(src)
    if not src or not ESX.GetPlayerFromId(src) then return false end
    revived(src)
    TriggerClientEvent('jobbuilder:client:revive', src, tonumber(health) or D.ReviveHealth)
    return true
end)
