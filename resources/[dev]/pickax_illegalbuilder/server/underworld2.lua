-- ─────────────────────────────── Pègre (suite) : récidive, informateurs, prison, planques ───────────────────────────────
-- Récidive : les infractions récentes aggravent amendes et peines. Informateurs : des PNJ vendent des tuyaux. Prison : peine avec travaux qui la réduisent.
-- Planques : cachettes d'objets que la police peut dénicher. Distances, délais et chances sont tous calculés côté serveur.

local function dist(a, b) local dx, dy, dz = a.x - b.x, a.y - b.y, (a.z or 0) - (b.z or 0) return math.sqrt(dx * dx + dy * dy + dz * dz) end
local function PR() return Config.Prison or {} end
local function INF() return Config.Informants or {} end
local function STA() return Config.Stashes or {} end

CreateThread(function()
    Wait(2200)
    if not (MySQL and MySQL.query) then return end
    pcall(MySQL.query.await, [[CREATE TABLE IF NOT EXISTS illegalbuilder_stashes (id INT AUTO_INCREMENT PRIMARY KEY, owner VARCHAR(80) NOT NULL, x DOUBLE NOT NULL, y DOUBLE NOT NULL, z DOUBLE NOT NULL, created_at INT NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    local ok, rows = pcall(MySQL.query.await, 'SELECT * FROM illegalbuilder_stashes')
    if ok and rows then
        for _, r in ipairs(rows) do
            if IB.stashExpired(r.created_at, os.time()) then MySQL.update('DELETE FROM illegalbuilder_stashes WHERE id = ?', { r.id })
            else IB.Stashes[r.id] = { id = r.id, owner = r.owner, x = r.x, y = r.y, z = r.z, created = r.created_at } IB.stashRegister(r.id, r.owner) end
        end
    end
end)

-- ═══════════════════════════ Récidive ═══════════════════════════
-- Multiplicateur d'amende et de peine : +PercentPerPrior % par infraction récente, plafonné
function IB.recidiveMul(priors)
    local R = (Config.Record or {}).Recidive or {}
    if not R.Enabled then return 1.0 end
    return 1.0 + math.min(tonumber(R.MaxPercent) or 0, math.max(0, priors) * (tonumber(R.PercentPerPrior) or 0)) / 100
end

-- Antécédents récents : lus dans le casier de la tablette police (pickax_jobbuilder)
function IB.priorCount(identifier)
    if GetResourceState('pickax_jobbuilder') ~= 'started' then return 0 end
    local R = (Config.Record or {}).Recidive or {}
    local ok, n = pcall(function() return exports.pickax_jobbuilder:RecordPriors(identifier, tonumber(R.WindowDays) or 30) end)
    return ok and math.floor(tonumber(n) or 0) or 0
end

-- Utilisé par la tablette police pour aggraver une amende (export)
exports('RecidiveMul', function(identifier)
    if not ((Config.Record or {}).Enabled and ((Config.Record or {}).Recidive or {}).Enabled) then return 1.0 end
    return IB.recidiveMul(IB.priorCount(identifier))
end)

-- ═══════════════════════════ Informateurs ═══════════════════════════
local lastInfo = {}

function IB.informantNear(src)
    for _, l in ipairs(INF().Locations or {}) do
        if IB.distanceTo(src, l.coords) <= (tonumber(INF().Radius) or 3.0) + 1.5 then return l end
    end
end

local function offersFor(x)
    local out = {}
    for kind, o in pairs(INF().Offers or {}) do
        if (not o.police) or IB.isPoliceJob(x.job.name) then out[#out + 1] = { kind = kind, label = o.label or kind, price = math.floor(tonumber(o.price) or 0) } end
    end
    table.sort(out, function(a, b) return a.kind < b.kind end)
    return out
end

ESX.RegisterServerCallback('illegalbuilder:informant:info', function(src, cb)
    if not INF().Enabled then return cb({ ok = false, error = 'Personne ne parle en ce moment.' }) end
    local x = ESX.GetPlayerFromId(src)
    if not x then return cb({ ok = false }) end
    local near = IB.informantNear(src)
    cb({ ok = true, near = near ~= nil, offers = near and offersFor(x) or {} })
end)

ESX.RegisterServerCallback('illegalbuilder:informant:buy', function(src, cb, kind)
    if not INF().Enabled then return cb({ ok = false, error = 'Personne ne parle en ce moment.' }) end
    local x = ESX.GetPlayerFromId(src)
    if not x then return cb({ ok = false }) end
    local now = GetGameTimer()
    if (lastInfo[src] or -1e9) + 2000 > now then return cb({ ok = false, error = 'Doucement.' }) end
    lastInfo[src] = now
    if not IB.informantNear(src) then return cb({ ok = false, error = 'Aucun indic à proximité.' }) end
    local offer
    for _, o in ipairs(offersFor(x)) do if o.kind == kind then offer = o end end
    if not offer then return cb({ ok = false, error = 'Il ne sait rien sur ça.' }) end
    local tip
    if kind == 'blackmarket' then
        local loc = IB.bmLocation()
        if not loc then return cb({ ok = false, error = 'Rien à te dire.' }) end
        tip = { coords = loc.coords, text = ('Le vendeur est %s.'):format(loc.hint or loc.label) }
    elseif kind == 'contract' then
        local zones = IB.contractZones and IB.contractZones() or {}
        if #zones == 0 then return cb({ ok = false, error = 'Aucune livraison suspecte en ce moment.' }) end
        local z = zones[math.random(#zones)]
        tip = { coords = { x = z.x + math.random(-120, 120) + 0.0, y = z.y + math.random(-120, 120) + 0.0, z = z.z }, text = 'Une livraison doit avoir lieu dans ce secteur.' }
    else return cb({ ok = false, error = 'Il ne sait rien sur ça.' }) end
    local acc = x.getAccount('money')
    if not acc or acc.money < offer.price then return cb({ ok = false, error = ('Il veut %d $ en liquide.'):format(offer.price) }) end
    x.removeAccountMoney('money', offer.price, 'Informateur')
    IB.log(nil, x, 'informant', kind, offer.price)
    cb({ ok = true, coords = tip.coords, text = tip.text, paid = offer.price })
end)

-- ═══════════════════════════ Prison ═══════════════════════════
-- La prison est celle de pickax_core (players/jail) : même lieu, tenue et minuteur que le /jail du staff. Ici : la peine donnée par la police (avec récidive et prime)
-- et les travaux qui la réduisent. Aucun second système de prison.
local worked = {}   -- [identifiant] = { total, reduced, lastWork }

local function core(fn, ...)
    if GetResourceState('pickax_core') ~= 'started' then return nil end
    local ok, a, b = pcall(function(...) return exports.pickax_core[fn](exports.pickax_core, ...) end, ...)
    if ok then return a, b end
    return nil
end

-- Réduction de peine possible : plafonnée à MaxReductionPercent de la peine totale
function IB.jailReduce(j, seconds)
    local cap = math.floor(j.total * math.max(0, math.min(100, tonumber(PR().MaxReductionPercent) or 50)) / 100)
    return math.max(0, math.min(seconds, cap - j.reduced))
end

function IB.jailPlayer(target, minutes, officer, reason)
    local x = ESX.GetPlayerFromId(target)
    if not x then return false, 'Cible introuvable' end
    minutes = math.max(1, math.min(math.floor(tonumber(PR().MaxMinutes) or 60), math.floor(tonumber(minutes) or 0)))
    local ok, res = core('JailPlayer', target, minutes * 60, IB.playerName(officer), reason, officer.source)
    if ok == nil then return false, 'La prison (pickax_core) n\'est pas disponible.' end
    if not ok then return false, res end
    worked[x.identifier] = { total = res, reduced = 0, lastWork = 0 }
    return true, math.floor(res / 60)
end

ESX.RegisterServerCallback('illegalbuilder:jail:work', function(src, cb)
    local x = ESX.GetPlayerFromId(src)
    local left = x and core('JailTimeLeft', src) or 0
    if not PR().Enabled or not x or not left or left <= 0 then return cb({ ok = false, error = 'Tu n\'es pas en prison.' }) end
    local near
    for _, s in ipairs((PR().Work or {}).Spots or {}) do if IB.distanceTo(src, s.coords) <= 3.5 then near = s end end
    if not near then return cb({ ok = false, error = 'Rends-toi à un poste de travail.' }) end
    local W = PR().Work or {}
    -- peine donnée par le staff ou avant un redémarrage : le plafond se calcule sur le temps restant au premier travail
    local j = worked[x.identifier]
    if not j then j = { total = left, reduced = 0, lastWork = 0 } worked[x.identifier] = j end
    if os.time() - j.lastWork < (tonumber(W.Cooldown) or 45) then return cb({ ok = false, error = 'Reprends ton souffle.' }) end
    local cut = IB.jailReduce(j, math.floor(tonumber(W.Reduce) or 30))
    if cut <= 0 then return cb({ ok = false, error = 'Ta peine ne peut plus être réduite par le travail.' }) end
    j.lastWork = os.time()
    j.reduced = j.reduced + cut
    local remaining = core('ReduceJail', src, cut) or 0
    cb({ ok = true, cut = cut, left = remaining, job = near.label })
end)

RegisterCommand('emprisonner', function(src, args)
    if src == 0 or not PR().Enabled then return end
    local officer = ESX.GetPlayerFromId(src)
    if not officer or not IB.isPoliceJob(officer.job.name) then return IB.notify(src, 'Réservé à la police.', 'error') end
    local t = ESX.GetPlayerFromId(tonumber(args[1]))
    local minutes = math.floor(tonumber(args[2]) or 0)
    local reason = table.concat(args, ' ', 3)
    if not t or t.source == src or minutes < 1 or reason == '' then return IB.notify(src, 'Usage : /emprisonner <id> <minutes> <motif>', 'error') end
    local a, b = GetPlayerPed(src), GetPlayerPed(t.source)
    if not a or a == 0 or not b or b == 0 or dist(GetEntityCoords(a), GetEntityCoords(b)) > (tonumber((Config.Record or {}).Distance) or 6.0) then return IB.notify(src, 'Le suspect est trop loin.', 'error') end
    local priors = IB.priorCount(t.identifier)
    minutes = math.floor(minutes * IB.recidiveMul(priors) + 0.5)
    local ok, real = IB.jailPlayer(t.source, minutes, officer, reason)
    if not ok then return IB.notify(src, real or 'Impossible', 'error') end
    IB.recordAdd(officer, t, 'jail', ('Peine de %d min : %s'):format(real, reason), 0)
    local B = PR().ArrestBonus or {}
    local bonus = 0
    if B.Enabled and priors > 0 then
        bonus = math.min(math.floor(tonumber(B.Max) or 0), priors * math.floor(tonumber(B.PerPrior) or 0))
        if bonus > 0 then officer.addAccountMoney(B.Account or 'bank', bonus, 'Prime d\'arrestation') end
    end
    IB.notify(t.source, ('Tu es en prison pour %d minute(s). Travaille aux postes pour réduire ta peine.'):format(real), 'error')
    IB.notify(src, ('%s en prison pour %d min%s%s'):format(IB.playerName(t), real, priors > 0 and (' (récidive : %d antécédent(s))'):format(priors) or '', bonus > 0 and (' · prime %d $'):format(bonus) or ''), 'success')
end, false)

RegisterCommand('liberer', function(src, args)
    if src == 0 then return end
    local x = ESX.GetPlayerFromId(src)
    if not x or not (IB.isPoliceJob(x.job.name) or IB.isAdmin(src)) then return IB.notify(src, 'Réservé à la police.', 'error') end
    local t = tonumber(args[1])
    if not t or not core('UnjailPlayer', t) then return IB.notify(src, 'Ce joueur n\'est pas en prison.', 'error') end
    IB.notify(src, 'Détenu libéré.', 'success')
end, false)

-- ═══════════════════════════ Planques ═══════════════════════════
IB.Stashes = IB.Stashes or {}

function IB.stashExpired(created, now)
    local d = tonumber(STA().ExpireDays) or 0
    return d > 0 and (now or os.time()) - (created or 0) > d * 86400
end

function IB.stashRegister(id, owner)
    if GetResourceState('ox_inventory') == 'started' then
        pcall(function() exports.ox_inventory:RegisterStash('ib_hide_' .. id, 'Planque', STA().Slots or 20, STA().Weight or 50000, owner) end)
    end
end

local function stashesOf(owner)
    local list = {}
    for _, s in pairs(IB.Stashes) do if s.owner == owner and not IB.stashExpired(s.created) then list[#list + 1] = s end end
    return list
end

-- Chance de dénicher une planque : décroît avec la distance
function IB.stashFindChance(d)
    local R, base = tonumber(STA().SearchRadius) or 5.0, tonumber(STA().FindChance) or 35
    if d > R then return 0 end
    return math.floor(base * (1 - 0.5 * d / R))
end

local lastStash = {}
RegisterCommand('planque', function(src)
    if src == 0 or not STA().Enabled then return end
    local x = ESX.GetPlayerFromId(src)
    if not x then return end
    local now = GetGameTimer()
    if (lastStash[src] or -1e9) + 3000 > now then return end
    lastStash[src] = now
    local pos = GetEntityCoords(GetPlayerPed(src))
    for _, s in ipairs(stashesOf(x.identifier)) do
        if dist(s, pos) <= 2.5 then
            pcall(function() exports.ox_inventory:forceOpenInventory(src, 'stash', 'ib_hide_' .. s.id) end)
            return
        end
    end
    local max = math.floor(tonumber(STA().Max) or 2)
    if #stashesOf(x.identifier) >= max then return IB.notify(src, ('Tu as déjà %d planque(s). Approche-toi de l\'une d\'elles pour l\'ouvrir.'):format(max), 'error') end
    if IB.copCount() < (tonumber(STA().MinCops) or 0) then return IB.notify(src, 'Pas assez de policiers en ville.', 'error') end
    local id = MySQL.insert.await('INSERT INTO illegalbuilder_stashes (owner, x, y, z, created_at) VALUES (?, ?, ?, ?, ?)', { x.identifier, pos.x, pos.y, pos.z, os.time() })
    IB.Stashes[id] = { id = id, owner = x.identifier, x = pos.x, y = pos.y, z = pos.z, created = os.time() }
    IB.stashRegister(id, x.identifier)
    IB.notify(src, 'Planque créée ici. Refais /planque pour l\'ouvrir.', 'success')
end, false)

RegisterCommand('fouillerplanque', function(src)
    if src == 0 or not STA().Enabled then return end
    local x = ESX.GetPlayerFromId(src)
    if not x or not IB.isPoliceJob(x.job.name) then return IB.notify(src, 'Réservé à la police.', 'error') end
    local now = GetGameTimer()
    if (lastStash[src] or -1e9) + (tonumber(STA().SearchCooldown) or 20) * 1000 > now then return IB.notify(src, 'Patiente avant de fouiller à nouveau.', 'error') end
    lastStash[src] = now
    local pos = GetEntityCoords(GetPlayerPed(src))
    local best, bd
    for _, s in pairs(IB.Stashes) do
        local d = dist(s, pos)
        if d <= (tonumber(STA().SearchRadius) or 5.0) and (not bd or d < bd) then best, bd = s, d end
    end
    if not best or math.random(100) > IB.stashFindChance(bd) then return IB.notify(src, 'Tu ne trouves rien ici.', 'info') end
    IB.Stashes[best.id] = nil
    MySQL.update('DELETE FROM illegalbuilder_stashes WHERE id = ?', { best.id })
    pcall(function() exports.ox_inventory:forceOpenInventory(src, 'stash', 'ib_hide_' .. best.id) end)
    IB.notify(src, 'Planque découverte ! Tout ce qu\'elle contient est à toi.', 'success')
    for _, id in ipairs(GetPlayers()) do
        local o = ESX.GetPlayerFromId(tonumber(id))
        if o and o.identifier == best.owner then
            IB.notify(o.source, 'La police a découvert une de tes planques.', 'error')
            IB.recordAdd(x, o, 'seizure', 'Planque découverte par la police', 0)
        end
    end
end, false)

AddEventHandler('playerDropped', function() lastInfo[source] = nil lastStash[source] = nil end)
