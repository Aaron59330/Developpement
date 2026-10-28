-- ─────────────────────────────── Prison (suite) : évasion, caution, justice ───────────────────────────────
-- S'appuie sur la prison de pickax_core (JailTimeLeft / ReduceJail / UnjailPlayer / EscapePlayer) et sur les bracelets de la tablette police (AutoBracelet).
-- Distances, délais, argent et grades sont vérifiés côté serveur.

local function dist(a, b) local dx, dy, dz = a.x - b.x, a.y - b.y, (a.z or 0) - (b.z or 0) return math.sqrt(dx * dx + dy * dy + dz * dz) end
local function ES() return Config.Escape or {} end
local function BA() return Config.Bail or {} end
local function JU() return Config.Justice or {} end

local function core(fn, ...)
    if GetResourceState('pickax_core') ~= 'started' then return nil end
    local ok, a = pcall(function(...) return exports.pickax_core[fn](exports.pickax_core, ...) end, ...)
    return ok and a or nil
end
local function inList(list, v) for _, x in ipairs(list or {}) do if x == v then return true end end return false end

-- ═══════════════════════════ Évasion ═══════════════════════════
local attempts = {}   -- [src] = { startedAt, spot }

-- Peine ajoutée à la reprise d'un évadé : reste de peine (arrondi à la minute) + pénalité
function IB.escapeExtra(leftSeconds)
    return math.ceil(math.max(0, tonumber(leftSeconds) or 0) / 60) + math.floor(tonumber(ES().PenaltyMinutes) or 0)
end

local function spotNear(src)
    for _, s in ipairs(ES().Spots or {}) do if IB.distanceTo(src, s.coords) <= 3.5 then return s end end
end

ESX.RegisterServerCallback('illegalbuilder:escape:start', function(src, cb)
    local x = ESX.GetPlayerFromId(src)
    if not ES().Enabled or not x then return cb({ ok = false, error = 'Impossible.' }) end
    if (core('JailTimeLeft', src) or 0) <= 0 then return cb({ ok = false, error = 'Tu n\'es pas en prison.' }) end
    if not spotNear(src) then return cb({ ok = false, error = 'Aucune issue ici.' }) end
    if IB.copCount() < (tonumber(ES().MinCops) or 0) then return cb({ ok = false, error = 'Trop calme : les gardes sont partout.' }) end
    local item = ES().Item or ''
    if item ~= '' and IB.itemCount(src, item) < 1 then return cb({ ok = false, error = ('Il te faut : %s'):format(item) }) end
    attempts[src] = { startedAt = os.time() }
    cb({ ok = true, seconds = math.floor(tonumber(ES().Seconds) or 45) })
end)

ESX.RegisterServerCallback('illegalbuilder:escape:finish', function(src, cb)
    local a = attempts[src]
    attempts[src] = nil
    local x = ESX.GetPlayerFromId(src)
    if not a or not x then return cb({ ok = false, error = 'Tentative annulée.' }) end
    if os.time() - a.startedAt < (tonumber(ES().Seconds) or 45) - 1 then return cb({ ok = false, error = 'Trop tôt.' }) end
    if not spotNear(src) then return cb({ ok = false, error = 'Tu as bougé : tentative annulée.' }) end
    local item = ES().Item or ''
    if item ~= '' and not IB.removeItem(src, item, 1) then return cb({ ok = false, error = 'Il te manque l\'objet.' }) end
    local left = core('EscapePlayer', src)
    if not left then return cb({ ok = false, error = 'Tu n\'es plus en prison.' }) end
    IB.Escapees[x.identifier] = { left = left, at = os.time() }
    local e = ES().Exit
    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 and e then SetEntityCoords(ped, e.x + 0.0, e.y + 0.0, e.z + 0.0, false, false, false, false) end
    IB.alertPolice(e or { x = 0.0, y = 0.0, z = 0.0 }, 'Évasion !', ('%s s\'est évadé de prison.'):format(IB.playerName(x)))
    IB.log(nil, x, 'escape', ('reste %d s'):format(left))
    cb({ ok = true })
end)

RegisterNetEvent('illegalbuilder:server:escapeCancel', function() attempts[source] = nil end)

-- Les évadés oubliés au bout d'un moment
CreateThread(function()
    while true do
        Wait(60000)
        local limit = math.floor(tonumber(ES().ForgetMinutes) or 45) * 60
        for id, e in pairs(IB.Escapees) do if os.time() - e.at > limit then IB.Escapees[id] = nil end end
    end
end)

-- ═══════════════════════════ Caution ═══════════════════════════
-- Montant de la caution pour une peine restante (0 si trop longue)
function IB.bailAmount(leftSeconds)
    local minutes = math.ceil((tonumber(leftSeconds) or 0) / 60)
    if minutes <= 0 or minutes > (tonumber(BA().MaxMinutes) or 30) then return 0 end
    return minutes * math.floor(tonumber(BA().PerMinute) or 0)
end

local lastBail = {}
RegisterCommand('caution', function(src, args)
    if src == 0 or not BA().Enabled then return end
    local payer = ESX.GetPlayerFromId(src)
    local t = ESX.GetPlayerFromId(tonumber(args[1]))
    if not payer or not t then return IB.notify(src, 'Usage : /caution <id du détenu>', 'error') end
    if (lastBail[src] or 0) + 5 > os.time() then return end
    lastBail[src] = os.time()
    local left = core('JailTimeLeft', t.source) or 0
    if left <= 0 then return IB.notify(src, 'Cette personne n\'est pas en prison.', 'error') end
    local amount = IB.bailAmount(left)
    if amount <= 0 then return IB.notify(src, ('Peine trop longue pour une caution (maximum %d min).'):format(BA().MaxMinutes or 30), 'error') end
    local acc = payer.getAccount(BA().Account or 'bank')
    if not acc or acc.money < amount then return IB.notify(src, ('La caution est de %d $ (compte %s).'):format(amount, BA().Account or 'bank'), 'error') end
    if GetResourceState('pickax_jobbuilder') ~= 'started' then return IB.notify(src, 'Bracelets indisponibles : la caution est impossible.', 'error') end
    local zone
    if (tonumber(BA().ZoneRadius) or 0) > 0 and BA().Exit then zone = { x = BA().Exit.x, y = BA().Exit.y, r = BA().ZoneRadius } end
    payer.removeAccountMoney(BA().Account or 'bank', amount, 'Caution')
    if not core('UnjailPlayer', t.source) then payer.addAccountMoney(BA().Account or 'bank', amount, 'Caution (remboursement)') return IB.notify(src, 'Impossible de libérer cette personne.', 'error') end
    local ped = GetPlayerPed(t.source)
    if ped and ped ~= 0 and BA().Exit then SetEntityCoords(ped, BA().Exit.x + 0.0, BA().Exit.y + 0.0, BA().Exit.z + 0.0, false, false, false, false) end
    pcall(function() exports.pickax_jobbuilder:AutoBracelet(t.source, BA().BraceletJob or 'police', BA().BraceletHours or 12, 'Liberté sous caution', zone) end)
    if (BA().Society or '') ~= '' then IB.society(BA().Society, amount) end
    IB.log(nil, payer, 'bail', ('%s : %d $'):format(IB.playerName(t), amount), amount)
    IB.notify(src, ('Caution de %d $ payée : %s est libre sous bracelet.'):format(amount, IB.playerName(t)), 'success')
    if t.source ~= src then IB.notify(t.source, 'Tu es libre sous caution. Un bracelet électronique te suit pendant quelques heures.', 'success') end
end, false)

-- ═══════════════════════════ Justice : avocat et juge ═══════════════════════════
local offers = {}     -- [client] = { lawyer, fee, percent, expires }
local pleaded = {}    -- [identifiant du client] = true : une plaidoirie par peine
local lastPardon = {}

function IB.lawyerCut(leftSeconds)
    return math.floor(math.max(0, tonumber(leftSeconds) or 0) * math.max(0, math.min(100, tonumber(JU().LawyerReducePercent) or 0)) / 100)
end

RegisterCommand('defendre', function(src, args)
    if src == 0 or not JU().Enabled then return end
    local lawyer = ESX.GetPlayerFromId(src)
    if not lawyer or not inList(JU().LawyerJobs, lawyer.job.name) then return IB.notify(src, 'Réservé aux avocats.', 'error') end
    local t = ESX.GetPlayerFromId(tonumber(args[1]))
    local fee = math.floor(tonumber(args[2]) or -1)
    if not t or t.source == src or fee < (JU().FeeMin or 0) or fee > (JU().FeeMax or 20000) then return IB.notify(src, ('Usage : /defendre <id> <honoraires %d–%d>'):format(JU().FeeMin or 0, JU().FeeMax or 20000), 'error') end
    local left = core('JailTimeLeft', t.source) or 0
    if left <= 0 then return IB.notify(src, 'Ton client n\'est pas en prison.', 'error') end
    if pleaded[t.identifier] then return IB.notify(src, 'Une plaidoirie a déjà eu lieu pour cette peine.', 'error') end
    if IB.distanceTo(src, GetEntityCoords(GetPlayerPed(t.source))) > (tonumber(JU().Distance) or 6.0) then return IB.notify(src, 'Ton client est trop loin.', 'error') end
    offers[t.source] = { lawyer = src, fee = fee, expires = os.time() + math.floor(tonumber(JU().OfferSeconds) or 60) }
    IB.notify(src, ('Offre envoyée à %s : %d $ pour une plaidoirie.'):format(IB.playerName(t), fee), 'info')
    IB.notify(t.source, ('Maître %s propose de te défendre pour %d $ (peine réduite de %d %%). /accepter pour confirmer.'):format(IB.playerName(lawyer), fee, JU().LawyerReducePercent or 0), 'warning')
end, false)

RegisterCommand('accepter', function(src)
    local o = offers[src]
    if src == 0 or not o then return end
    offers[src] = nil
    if os.time() > o.expires then return IB.notify(src, 'L\'offre a expiré.', 'error') end
    local client, lawyer = ESX.GetPlayerFromId(src), ESX.GetPlayerFromId(o.lawyer)
    if not client or not lawyer or not inList(JU().LawyerJobs, lawyer.job.name) then return end
    local left = core('JailTimeLeft', src) or 0
    if left <= 0 or pleaded[client.identifier] then return IB.notify(src, 'Plus de plaidoirie possible.', 'error') end
    local acc = client.getAccount('bank')
    if not acc or acc.money < o.fee then return IB.notify(src, 'Fonds insuffisants en banque pour les honoraires.', 'error') end
    client.removeAccountMoney('bank', o.fee, 'Honoraires d\'avocat')
    lawyer.addAccountMoney('bank', o.fee, 'Honoraires')
    pleaded[client.identifier] = true
    local cut = IB.lawyerCut(left)
    core('ReduceJail', src, cut)
    IB.log(nil, lawyer, 'lawyer', ('%s : -%d s'):format(IB.playerName(client), cut), o.fee)
    IB.notify(src, ('Plaidoirie réussie : peine réduite de %d min.'):format(math.floor(cut / 60)), 'success')
    IB.notify(o.lawyer, ('%s a accepté : %d $ d\'honoraires reçus.'):format(IB.playerName(client), o.fee), 'success')
end, false)

-- /gracier <id> [pourcentage] : le juge efface une part de la peine restante
RegisterCommand('gracier', function(src, args)
    if src == 0 or not JU().Enabled then return end
    local judge = ESX.GetPlayerFromId(src)
    if not judge or not inList(JU().JudgeJobs, judge.job.name) then return IB.notify(src, 'Réservé aux juges.', 'error') end
    if (lastPardon[src] or 0) + (tonumber(JU().JudgeCooldown) or 30) > os.time() then return IB.notify(src, 'Patiente avant une autre décision.', 'error') end
    local t = ESX.GetPlayerFromId(tonumber(args[1]))
    local pct = math.min(math.floor(tonumber(args[2]) or 100), math.floor(tonumber(JU().JudgeMaxPercent) or 100))
    if not t or pct <= 0 then return IB.notify(src, 'Usage : /gracier <id> [pourcentage]', 'error') end
    local left = core('JailTimeLeft', t.source) or 0
    if left <= 0 then return IB.notify(src, 'Cette personne n\'est pas en prison.', 'error') end
    lastPardon[src] = os.time()
    if pct >= 100 then core('UnjailPlayer', t.source) else core('ReduceJail', t.source, math.floor(left * pct / 100)) end
    IB.log(nil, judge, 'pardon', ('%s : %d %%'):format(IB.playerName(t), pct))
    IB.notify(src, ('Décision rendue : %d %% de la peine effacée.'):format(pct), 'success')
    IB.notify(t.source, pct >= 100 and 'Le juge t\'a gracié : tu es libre.' or ('Le juge a réduit ta peine de %d %%.'):format(pct), 'success')
end, false)

AddEventHandler('playerDropped', function() attempts[source] = nil offers[source] = nil lastBail[source] = nil end)
