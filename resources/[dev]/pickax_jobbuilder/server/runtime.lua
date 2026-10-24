-- ─────────────────────────────── Runtime : utilisation des points par les joueurs ───────────────────────────────
-- Chaque appel re-vérifie : le point existe, le joueur est dans CE job, grade suffisant, et il est à proximité.
-- Les jobs ne sont jamais mélangés : un point n'est utilisable que par le job auquel il appartient.

local function fail(msg) return { ok = false, error = msg } end

local function getPoint(src, pointId, ptype, publicOk)
    local xPlayer = ESX.GetPlayerFromId(src)
    local point = JB.Points[tonumber(pointId)]
    if not xPlayer or not point then return nil, nil, 'Point introuvable' end
    if ptype and point.type ~= ptype then return nil, nil, 'Point invalide' end
    if JB.distanceTo(src, point.coords) > Config.ServerDistance then return nil, nil, 'Tu es trop loin' end
    if not (publicOk and (point.type ~= 'shop' or (point.data and point.data.public))) then
        if xPlayer.job.name ~= point.job_name then return nil, nil, 'Ce point n\'appartient pas à ton métier' end
        if xPlayer.job.grade < point.min_grade then return nil, nil, 'Ton grade est insuffisant' end
        if not JB.isOnDuty(src) then return nil, nil, 'Prends ton service (menu F6) pour utiliser ce point' end
    end
    return point, xPlayer
end

-- ─────────────────────────────── Société : même système que le reste du serveur ───────────────────────────────
-- L'argent d'un job vit dans le compte partagé `society_<job>` d'esx_addonaccount (ici celui d'CorePickax), qui le garde EN MÉMOIRE
-- et le réécrit en base. On passe donc par lui (comme esx_society) pour que tous les scripts voient le même solde, instantanément.
-- Repli : SQL direct sur addon_account_data (job pas encore connu d'esx_addonaccount : créé en jeu, avant son redémarrage).
local unknown = {}        -- [compte] = timestamp : compte absent d'esx_addonaccount (évite de relancer sa recherche et ses messages d'erreur)
local badBackend = false  -- l'API du compte ne se comporte pas comme prévu : on reste sur SQL
local backendUp = function() return GetResourceState('esx_addonaccount') == 'started' or GetResourceState('pickax_core') == 'started' end

local function sharedAccount(jobName)
    if badBackend or not backendUp() then return nil end
    local name = JB.societyAccount(jobName)
    if unknown[name] and unknown[name] > os.time() then return nil end
    local acc
    local ok = pcall(function() TriggerEvent('esx_addonaccount:getSharedAccount', name, function(a) acc = a end) end)
    if not ok or type(acc) ~= 'table' then unknown[name] = os.time() + 60 return nil end
    unknown[name] = nil
    return acc
end

AddEventHandler('onResourceStart', function(res)
    if res == 'esx_addonaccount' or res == 'pickax_core' or res == 'esx_society' then unknown, badBackend = {}, false end
end)

-- Applique add/removeMoney et vérifie sur une lecture neuve que le solde a vraiment bougé.
-- 1) méthodes du compte (esx_society les appelle ainsi) 2) exports « pont » AddSharedMoney / RemoveSharedMoney si le serveur les expose
-- (utile quand CorePickax regroupe addonaccount + society : le compte reçu depuis une autre ressource est alors une simple copie sans méthodes)
local diagShown = false
local function applyMem(jobName, acc, fn, amount)
    local name = JB.societyAccount(jobName)
    local want = (tonumber(acc.money) or 0) + (fn == 'addMoney' and amount or -amount)
    local function moved()
        local after = sharedAccount(jobName)
        return after and (tonumber(after.money) or 0) == want
    end
    if type(acc[fn]) == 'function' then
        if pcall(acc[fn], amount) and moved() then return true end
        if pcall(acc[fn], acc, amount) and moved() then return true end
    end
    local bridge = fn == 'addMoney' and 'AddSharedMoney' or 'RemoveSharedMoney'
    for _, host in ipairs({ 'esx_addonaccount', 'pickax_core' }) do
        if GetResourceState(host) == 'started' then
            if pcall(function() exports[host][bridge](exports[host], name, amount) end) and moved() then return true end
        end
    end
    if not diagShown then
        diagShown = true
        local keys = {}
        for k, v in pairs(acc) do keys[#keys + 1] = k .. ':' .. type(v) end
        print(('^3[jobbuilder] DIAG compte %s : impossible de modifier le solde en mémoire. Champs reçus : %s^0'):format(name, table.concat(keys, ', ')))
        print('^3[jobbuilder] Solution : ajoute ces 2 exports dans le script qui contient esx_addonaccount (voir README « Pont esx_addonaccount »).^0')
    end
    return false
end

local function sqlBalance(name)
    local row = MySQL.single.await('SELECT money FROM addon_account_data WHERE account_name = ? AND owner IS NULL', { name })
    return row and row.money or 0
end

local function societyBalance(jobName)
    local acc = sharedAccount(jobName)
    if acc and tonumber(acc.money) then return math.floor(tonumber(acc.money)) end
    return sqlBalance(JB.societyAccount(jobName))
end

-- Pousse le nouveau solde aux employés connectés (l'interface se met à jour sans rien rouvrir)
function JB.pushMoney(jobName)
    local bal = societyBalance(jobName)
    local ok, players = pcall(ESX.GetExtendedPlayers, 'job', jobName)
    if ok and players then
        for _, xp in ipairs(players) do TriggerClientEvent('jobbuilder:client:money', xp.source, jobName, bal) end
    end
    return bal
end

-- Repli SQL : si les lignes du compte manquent (supprimées/jamais créées), on les recrée puis on réessaie une fois
local function sqlMove(jobName, amount, sign)
    local acc = JB.societyAccount(jobName)
    local sql = sign > 0
        and 'UPDATE addon_account_data SET money = money + ? WHERE account_name = ? AND owner IS NULL'
        or 'UPDATE addon_account_data SET money = money - ? WHERE account_name = ? AND owner IS NULL AND money >= ?'
    local params = sign > 0 and { amount, acc } or { amount, acc, amount }
    local n = MySQL.update.await(sql, params) or 0
    if n == 0 and JB.ensureRows then
        local exists = MySQL.scalar.await('SELECT 1 FROM addon_account_data WHERE account_name = ? AND owner IS NULL', { acc })
        if not exists then
            JB.ensureRows(acc, jobName, 0)
            n = MySQL.update.await(sql, params) or 0
        end
    end
    return n > 0
end

local function societyAdd(jobName, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local acc = sharedAccount(jobName)
    if acc then
        local before = tonumber(acc.money) or 0
        if applyMem(jobName, acc, 'addMoney', amount) then JB.pushMoney(jobName) return true end
        badBackend = true      -- l'appel n'a rien changé : API inattendue, on bascule sur SQL
        print('^3[jobbuilder] Le compte partagé ne réagit pas à addMoney : repli sur SQL (les autres scripts ne verront le solde qu\'après un restart pickax_core).^0')
    end
    local ok = sqlMove(jobName, amount, 1)
    if ok then JB.pushMoney(jobName) end
    return ok
end

local function societyRemove(jobName, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local acc = sharedAccount(jobName)
    if acc then
        local before = tonumber(acc.money) or 0
        if before < amount then return false end
        if applyMem(jobName, acc, 'removeMoney', amount) then JB.pushMoney(jobName) return true end
        badBackend = true
        print('^3[jobbuilder] Le compte partagé ne réagit pas à removeMoney : repli sur SQL (les autres scripts ne verront le solde qu\'après un restart pickax_core).^0')
    end
    local ok = sqlMove(jobName, amount, -1)
    if ok then JB.pushMoney(jobName) end
    return ok
end

JB.sharedAccount, JB.sqlBalance, JB.forgetUnknownAccount = sharedAccount, sqlBalance, function(name) unknown[name] = nil end

-- API pour les autres scripts (même esprit que GetGangMoney / AddGangMoney / RemoveGangMoney)
-- Rechargement des jobs après une création faite par un autre script (Pôle emploi du worldbuilder)
exports('Reload', function() JB.loadAll() JB.refreshESX() for _, src in ipairs(GetPlayers()) do pcall(JB.syncPlayer, tonumber(src)) end return true end)
exports('GetJobMoney', function(job) return societyBalance(tostring(job)) end)
exports('AddJobMoney', function(job, amount) return societyAdd(tostring(job), amount) end)
exports('RemoveJobMoney', function(job, amount) return societyRemove(tostring(job), amount) end)
exports('RefreshJob', function(job) return JB.pushMoney(tostring(job)) end)

-- /jobmoney [job] : diagnostic de la synchronisation des soldes (console serveur ou joueur _dev)
RegisterCommand('jobmoney', function(src, args)
    if src ~= 0 and not JB.isDev(src) then return end
    local out = { '^5──────── jobbuilder : trésoreries ────────^0' }
    out[#out + 1] = backendUp() and ('^2esx_addonaccount détecté^0 (%s) — les soldes passent par lui, en mémoire'):format(GetResourceState('esx_addonaccount') == 'started' and 'esx_addonaccount' or 'pickax_core')
        or '^3esx_addonaccount introuvable : repli SQL direct sur addon_account_data^0'
    if badBackend then out[#out + 1] = '^1API du compte partagé inattendue : repli SQL forcé^0' end
    local names = {}
    if args[1] then names[1] = args[1] else for n, j in pairs(JB.Jobs) do if j.society then names[#names + 1] = n end end table.sort(names) end
    for _, n in ipairs(names) do
        unknown[JB.societyAccount(n)] = nil
        local acc = sharedAccount(n)
        local db = sqlBalance(JB.societyAccount(n))
        local reg
        pcall(function() TriggerEvent('esx_society:getSociety', n, function(so) reg = so end) end)
        out[#out + 1] = ('   esx_society : %s'):format(reg and '^2société enregistrée^0' or '^3société NON enregistrée (le menu contextuel / esx_society ne verra pas son coffre)^0')
        if acc then
            local mem = math.floor(tonumber(acc.money) or 0)
            out[#out + 1] = (mem == db and '^2✔^0' or '^3⚠^0') .. (' %s : mémoire $%d | base $%d%s'):format(n, mem, db, mem == db and '' or ' (la base est réécrite par esx_addonaccount, normal juste après une opération)')
        else
            out[#out + 1] = ('^3⚠^0 %s : compte inconnu d\'esx_addonaccount (redémarre-le pour qu\'il le charge) | base $%d — repli SQL'):format(n, db)
        end
    end
    for _, l in ipairs(out) do print(l) end
    if src ~= 0 then JBNotifyClient( src, 'Diagnostic des trésoreries dans la console serveur.') end
end, false)

local function pay(xPlayer, amount)
    if amount <= 0 then return true end
    if xPlayer.getAccount('money').money >= amount then
        xPlayer.removeAccountMoney('money', amount)
        return true
    elseif xPlayer.getAccount('bank').money >= amount then
        xPlayer.removeAccountMoney('bank', amount)
        return true
    end
    return false
end

JB.pay, JB.societyAdd, JB.societyRemove, JB.societyBalance = pay, societyAdd, societyRemove, societyBalance

-- ─────────────────────────────── Données boss ───────────────────────────────
local function bossData(job)
    local employees = {}
    local rows = MySQL.query.await('SELECT identifier, firstname, lastname, job_grade FROM users WHERE job = ? ORDER BY job_grade DESC, lastname LIMIT 200', { job.name }) or {}
    for _, r in ipairs(rows) do
        employees[#employees + 1] = {
            identifier = r.identifier,
            name = ((r.firstname or '') .. ' ' .. (r.lastname or '')):gsub('^%s+', ''),
            grade = r.job_grade,
            online = ESX.GetPlayerFromIdentifier(r.identifier) ~= nil,
        }
    end
    local logs = MySQL.query.await('SELECT action, detail, player_name, UNIX_TIMESTAMP(created_at) AS t FROM jobbuilder_logs WHERE job_name = ? ORDER BY id DESC LIMIT 40', { job.name }) or {}
    return {
        job = job.name,
        money = job.society and societyBalance(job.name) or nil,
        society = job.society,
        grades = job.grades,
        boss_grade = job.boss_grade,
        employees = employees,
        logs = logs,
    }
end

-- ─────────────────────────────── Ouverture d'un point ───────────────────────────────
ESX.RegisterServerCallback('jobbuilder:openPoint', function(src, cb, pointId)
    local point = JB.Points[tonumber(pointId)]
    if not point then return cb(fail('Point introuvable')) end
    local publicShop = point.type == 'shop' or point.type == 'showroom' or point.type == 'display'
    local point2, xPlayer, err = getPoint(src, pointId, nil, publicShop)
    if not point2 then return cb(fail(err)) end
    local job = JB.Jobs[point.job_name]
    local grade = xPlayer.job.grade
    local d = point.data

    if point.type == 'garage' then
        local list = {}
        for i, v in ipairs(d.vehicles) do
            if grade >= v.min_grade then list[#list + 1] = { idx = i, model = v.model, label = v.label } end
        end
        cb({ ok = true, kind = 'garage', garageKind = d.kind or 'car', label = point.label, vehicles = list, hasStore = d.store ~= nil })

    elseif point.type == 'cloakroom' then
        local list = {}
        for i, o in ipairs(d.outfits) do
            if grade >= o.min_grade then list[#list + 1] = { idx = i, label = o.label } end
        end
        cb({ ok = true, kind = 'cloakroom', label = point.label, outfits = list })

    elseif point.type == 'armory' then
        local list = {}
        for i, it in ipairs(d.items) do
            if grade >= it.min_grade then list[#list + 1] = { idx = i, name = it.name, label = it.label, count = it.count, ammo = it.ammo } end
        end
        cb({ ok = true, kind = 'armory', label = point.label, items = list })

    elseif point.type == 'stash' then
        if JB.inventory() ~= 'ox' then return cb(fail('Les coffres nécessitent ox_inventory')) end
        cb({ ok = true, kind = 'stash', stash = ('jobbuilder_%d'):format(point.id) })

    elseif point.type == 'boss' then
        if grade < job.boss_grade then return cb(fail('Réservé aux grades de direction')) end
        local data = bossData(job)
        data.ok, data.kind, data.label, data.myGrade = true, 'boss', point.label, grade
        data.jobLabel = job.label
        cb(data)

    elseif point.type == 'showroom' or point.type == 'display' then
        if not JB.openShowroom then return cb(fail('Module concession non chargé (server/dealer.lua)')) end
        JB.openShowroom(src, xPlayer, point, job, cb)

    elseif point.type == 'missions' then
        if not JB.openMissions then return cb(fail('Module missions non chargé (server/missions.lua)')) end
        JB.openMissions(src, xPlayer, point, job, cb)

    elseif point.type == 'activity' then
        if not JB.openActivity then return cb(fail('Module activités non chargé (server/act_core.lua)')) end
        JB.openActivity(src, xPlayer, point, job, cb)

    elseif point.type == 'actpoint' then
        cb(fail('Ce point sert de repère à ton activité'))

    elseif point.type == 'testdrive' then
        cb(fail('Utilise le showroom pour demander un essai'))

    elseif point.type == 'tuning' then
        if not JB.openTuning then return cb(fail('Module tuning non chargé (server/tuning.lua)')) end
        JB.openTuning(src, xPlayer, point, job, cb)

    elseif point.type == 'harvest' or point.type == 'kitchen' then
        if not JB.openKitchen then return cb(fail('Module cuisine non chargé (server/kitchen.lua)')) end
        JB.openKitchen(src, xPlayer, point, job, cb)

    elseif point.type == 'shop' then
        local list = {}
        for i, it in ipairs(d.items) do
            if xPlayer.job.name ~= point.job_name or grade >= it.min_grade then
                list[#list + 1] = { idx = i, name = it.name, label = it.label, price = it.price }
            end
        end
        cb({ ok = true, kind = 'shop', label = point.label, items = list })
    else
        cb(fail('Type inconnu'))
    end
end)

-- ─────────────────────────────── Garage ───────────────────────────────
ESX.RegisterServerCallback('jobbuilder:garage:spawn', function(src, cb, pointId, idx)
    local point, xPlayer, err = getPoint(src, pointId, 'garage')
    if not point then return cb(fail(err)) end
    local v = point.data.vehicles[tonumber(idx) or 0]
    if not v or xPlayer.job.grade < v.min_grade then return cb(fail('Véhicule indisponible pour ton grade')) end
    local job = JB.Jobs[point.job_name]
    local prefix = job.settings.plate_prefix or ''
    if prefix == '' then prefix = (point.job_name:upper():gsub('[^%w]', '')):sub(1, Config.PlatePrefixLength) end
    prefix = prefix:sub(1, 4)
    local digits = 8 - #prefix
    local plate = prefix .. ('%0' .. digits .. 'd'):format(math.floor(math.random(0, math.floor(10 ^ digits) - 1)))
    JB.log(point.job_name, xPlayer, 'vehicle_out', ('%s (%s)'):format(v.label, plate))
    -- Grades autorisés au volant (lus par CorePickax : sans cela un véhicule de classe « police » du job est refusé à ses propres employés)
    local grades = {}
    for g = math.max(v.min_grade, point.min_grade or 0), #job.grades - 1 do grades[tostring(g)] = true end
    cb({ ok = true, model = v.model, plate = plate, spawn = point.data.spawn, color = v.color, job = point.job_name, grades = grades })
end)

-- Point « Rangement véhicule » : ranger un véhicule du service sans passer par le menu du garage.
-- Sauf option « tous les véhicules », seule une plaque du job (préfixe) est acceptée : on ne supprime jamais la voiture perso d'un joueur.
ESX.RegisterServerCallback('jobbuilder:garage:return', function(src, cb, pointId, plate)
    pointId = tonumber(pointId) or 0
    local xPlayer = ESX.GetPlayerFromId(src)
    local point
    if pointId >= 100000000 then            -- point de rangement intégré à un garage
        local g = JB.Points[pointId - 100000000]
        if g and g.type == 'garage' and g.data.store then
            point = { job_name = g.job_name, min_grade = g.min_grade, coords = g.data.store.coords, data = { radius = g.data.store.radius, any = g.data.store.any } }
        end
    else
        local p = JB.Points[pointId]
        if p and p.type == 'garage_return' then point = p end
    end
    if not point or not xPlayer then return cb(fail('Point introuvable')) end
    if JB.distanceTo(src, point.coords) > Config.ServerDistance + (point.data.radius or 5.0) then return cb(fail('Tu es trop loin')) end
    if xPlayer.job.name ~= point.job_name then return cb(fail('Ce point n\'appartient pas à ton métier')) end
    if xPlayer.job.grade < point.min_grade then return cb(fail('Ton grade est insuffisant')) end
    plate = tostring(plate or ''):gsub('%c', ''):gsub('^%s+', ''):gsub('%s+$', ''):upper()
    if not point.data.any then
        local job = JB.Jobs[point.job_name]
        local prefix = (job.settings.plate_prefix or '')
        if prefix == '' then prefix = (point.job_name:upper():gsub('[^%w]', '')):sub(1, Config.PlatePrefixLength) end
        prefix = prefix:sub(1, 4):upper()
        if plate:sub(1, #prefix) ~= prefix then return cb(fail('Ce véhicule n\'appartient pas au service (plaque ' .. prefix .. '…)')) end
    end
    JB.log(point.job_name, xPlayer, 'vehicle_in', plate)
    cb({ ok = true })
end)

-- ─────────────────────────────── Vestiaire ───────────────────────────────
ESX.RegisterServerCallback('jobbuilder:cloak:wear', function(src, cb, pointId, idx)
    local point, xPlayer, err = getPoint(src, pointId, 'cloakroom')
    if not point then return cb(fail(err)) end
    local o = point.data.outfits[tonumber(idx) or 0]
    if not o or xPlayer.job.grade < o.min_grade then return cb(fail('Tenue indisponible')) end
    local sex = xPlayer.get('sex')
    local clothes = (sex == 'f') and o.female or o.male
    if not clothes then return cb(fail('Cette tenue n\'existe pas pour ton genre')) end
    cb({ ok = true, clothes = clothes })
end)

-- ─────────────────────────────── Armurerie ───────────────────────────────
ESX.RegisterServerCallback('jobbuilder:armory:take', function(src, cb, pointId, idx)
    local point, xPlayer, err = getPoint(src, pointId, 'armory')
    if not point then return cb(fail(err)) end
    local it = point.data.items[tonumber(idx) or 0]
    if not it or xPlayer.job.grade < it.min_grade then return cb(fail('Objet indisponible')) end
    local isWeapon = it.name:upper():find('^WEAPON_') ~= nil

    if JB.inventory() == 'ox' then
        if not exports.ox_inventory:CanCarryItem(src, it.name, it.count) then return cb(fail('Tu ne peux pas porter ça')) end
        local metadata = (isWeapon and it.ammo > 0) and { ammo = it.ammo } or nil
        local ok = exports.ox_inventory:AddItem(src, it.name, isWeapon and 1 or it.count, metadata)
        if not ok then return cb(fail('Impossible de donner l\'objet')) end
    else
        if isWeapon then
            if xPlayer.hasWeapon(it.name:upper()) then return cb(fail('Tu as déjà cette arme')) end
            xPlayer.addWeapon(it.name:upper(), it.ammo)
        else
            if not xPlayer.canCarryItem(it.name, it.count) then return cb(fail('Tu ne peux pas porter ça')) end
            xPlayer.addInventoryItem(it.name, it.count)
        end
    end
    JB.log(point.job_name, xPlayer, 'armory_take', ('%dx %s'):format(isWeapon and 1 or it.count, it.label))
    cb({ ok = true })
end)

-- ─────────────────────────────── Boutique ───────────────────────────────
ESX.RegisterServerCallback('jobbuilder:shop:buy', function(src, cb, pointId, idx, qty)
    local point, xPlayer, err = getPoint(src, pointId, 'shop', true)
    if not point then return cb(fail(err)) end
    local it = point.data.items[tonumber(idx) or 0]
    qty = math.floor(tonumber(qty) or 1)
    if not it or qty < 1 or qty > 100 then return cb(fail('Quantité invalide')) end
    if xPlayer.job.name == point.job_name and xPlayer.job.grade < it.min_grade then return cb(fail('Article indisponible')) end
    local total = it.price * qty

    if JB.inventory() == 'ox' then
        if not exports.ox_inventory:CanCarryItem(src, it.name, qty) then return cb(fail('Tu ne peux pas porter ça')) end
    elseif not xPlayer.canCarryItem(it.name, qty) then return cb(fail('Tu ne peux pas porter ça')) end

    if not pay(xPlayer, total) then return cb(fail('Pas assez d\'argent')) end

    local job = JB.Jobs[point.job_name]
    local tax = (total > 0 and JB.applyTax) and JB.applyTax('shop', total, point.job_name) or 0
    if total > 0 and job.society then societyAdd(point.job_name, total - tax) end
    if JB.inventory() == 'ox' then exports.ox_inventory:AddItem(src, it.name, qty) else xPlayer.addInventoryItem(it.name, qty) end
    JB.log(point.job_name, xPlayer, 'shop_buy', ('%dx %s pour %d$'):format(qty, it.label, total))
    cb({ ok = true })
end)

-- ─────────────────────────────── Boss ───────────────────────────────
local function bossPoint(src, pointId)
    local point, xPlayer, err = getPoint(src, pointId, 'boss')
    if not point then return nil, nil, nil, err end
    local job = JB.Jobs[point.job_name]
    if xPlayer.job.grade < job.boss_grade then return nil, nil, nil, 'Réservé aux grades de direction' end
    return point, xPlayer, job
end

local function bossReply(job, extra)
    local d = bossData(job)
    d.ok = true
    for k, v in pairs(extra or {}) do d[k] = v end
    return d
end

ESX.RegisterServerCallback('jobbuilder:boss:poll', function(src, cb, pointId)
    local point, xPlayer, job, err = bossPoint(src, pointId)
    if not point then return cb(fail(err)) end
    cb({ ok = true, job = job.name, money = job.society and societyBalance(job.name) or nil })
end)

ESX.RegisterServerCallback('jobbuilder:boss:money', function(src, cb, pointId, mode, amount)
    local point, xPlayer, job, err = bossPoint(src, pointId)
    if not point then return cb(fail(err)) end
    if not job.society then return cb(fail('Ce job n\'a pas de compte société')) end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 or amount > 100000000 then return cb(fail('Montant invalide')) end

    if mode == 'deposit' then
        if xPlayer.getAccount('money').money < amount then return cb(fail('Pas assez d\'argent liquide')) end
        xPlayer.removeAccountMoney('money', amount)
        if not societyAdd(job.name, amount) then
            xPlayer.addAccountMoney('money', amount)
            return cb(fail('Dépôt impossible : compte société inaccessible (voir /jobmoney)'))
        end
        JB.log(job.name, xPlayer, 'society_deposit', amount .. '$')
    elseif mode == 'withdraw' then
        if not societyRemove(job.name, amount) then return cb(fail('Fonds insuffisants dans la société')) end
        xPlayer.addAccountMoney('money', amount)
        JB.log(job.name, xPlayer, 'society_withdraw', amount .. '$')
    else
        return cb(fail('Action invalide'))
    end
    cb(bossReply(job))
end)

ESX.RegisterServerCallback('jobbuilder:boss:recruit', function(src, cb, pointId, targetId)
    local point, xPlayer, job, err = bossPoint(src, pointId)
    if not point then return cb(fail(err)) end
    local target = ESX.GetPlayerFromId(tonumber(targetId))
    if not target then return cb(fail('Joueur introuvable')) end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target.source))) > Config.TargetDistance + 2.0 then return cb(fail('Le joueur est trop loin')) end
    if target.job.name == job.name then return cb(fail('Déjà dans ce job')) end
    target.setJob(job.name, 0)
    JBNotifyClient( target.source, ('Tu as été recruté chez ~b~%s'):format(job.label))
    JB.log(job.name, xPlayer, 'recruit', JB.playerName(target))
    cb(bossReply(job))
end)

local function targetGrade(identifier, jobName)
    local x = ESX.GetPlayerFromIdentifier(identifier)
    if x then return x.job.name == jobName and x.job.grade or nil, x end
    local row = MySQL.single.await('SELECT job, job_grade FROM users WHERE identifier = ?', { identifier })
    if row and row.job == jobName then return row.job_grade end
    return nil
end

ESX.RegisterServerCallback('jobbuilder:boss:setGrade', function(src, cb, pointId, identifier, grade)
    local point, xPlayer, job, err = bossPoint(src, pointId)
    if not point then return cb(fail(err)) end
    grade = math.floor(tonumber(grade) or -1)
    if grade < 0 or grade > #job.grades - 1 then return cb(fail('Grade invalide')) end
    if grade > xPlayer.job.grade then return cb(fail('Tu ne peux pas promouvoir au-dessus de ton propre grade')) end
    if identifier == xPlayer.identifier then return cb(fail('Tu ne peux pas modifier ton propre grade')) end
    local current, xTarget = targetGrade(identifier, job.name)
    if not current then return cb(fail('Cet employé n\'est pas dans ton job')) end
    if current >= job.boss_grade then return cb(fail('Tu ne peux pas modifier un autre membre de la direction')) end
    if xTarget then xTarget.setJob(job.name, grade)
    else MySQL.update.await('UPDATE users SET job_grade = ? WHERE identifier = ? AND job = ?', { grade, identifier, job.name }) end
    JB.log(job.name, xPlayer, 'set_grade', ('%s -> %s'):format(identifier:sub(-8), job.grades[grade + 1].label))
    cb(bossReply(job))
end)

ESX.RegisterServerCallback('jobbuilder:boss:fire', function(src, cb, pointId, identifier)
    local point, xPlayer, job, err = bossPoint(src, pointId)
    if not point then return cb(fail(err)) end
    if identifier == xPlayer.identifier then return cb(fail('Tu ne peux pas te virer toi-même')) end
    local current, xTarget = targetGrade(identifier, job.name)
    if not current then return cb(fail('Cet employé n\'est pas dans ton job')) end
    if current >= job.boss_grade then return cb(fail('Tu ne peux pas virer un autre membre de la direction')) end
    if xTarget then
        xTarget.setJob('unemployed', 0)
        JBNotifyClient( xTarget.source, ('Tu as été viré de ~r~%s'):format(job.label))
    else
        MySQL.update.await("UPDATE users SET job = 'unemployed', job_grade = 0 WHERE identifier = ? AND job = ?", { identifier, job.name })
    end
    JB.log(job.name, xPlayer, 'fire', identifier:sub(-8))
    cb(bossReply(job))
end)

ESX.RegisterServerCallback('jobbuilder:boss:salary', function(src, cb, pointId, grade, salary)
    local point, xPlayer, job, err = bossPoint(src, pointId)
    if not point then return cb(fail(err)) end
    grade = math.floor(tonumber(grade) or -1)
    salary = math.floor(tonumber(salary) or -1)
    if grade < 0 or grade > #job.grades - 1 or salary < 0 then return cb(fail('Valeur invalide')) end
    if salary > Config.MaxBossSalary then return cb(fail(('Salaire maximum fixé par un patron : %d $'):format(Config.MaxBossSalary))) end
    MySQL.update.await('UPDATE job_grades SET salary = ? WHERE job_name = ? AND grade = ?', { salary, job.name, grade })
    job.grades[grade + 1].salary = salary
    JB.refreshESX()
    JB.log(job.name, xPlayer, 'set_salary', ('%s : %d$'):format(job.grades[grade + 1].label, salary))
    cb(bossReply(job))
end)

-- ─────────────────────────────── Menu métier : actions & factures ───────────────────────────────
local function jobHasAction(xPlayer, action)
    local job = JB.Jobs[xPlayer.job.name]
    if not job or not Config.Actions[action] or not JBActionAllowed(action, job.type) then return false end
    for _, a in ipairs(job.settings.actions or {}) do
        if a == action then return true end
    end
    return false
end

local function playersClose(a, b)
    return #(GetEntityCoords(GetPlayerPed(a)) - GetEntityCoords(GetPlayerPed(b))) <= Config.TargetDistance + 2.0
end

-- Quitter son métier (bouton « Quitter le métier » du menu F6) : retour au job par défaut
ESX.RegisterServerCallback('jobbuilder:leaveJob', function(src, cb)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return cb(fail('Joueur introuvable')) end
    if Config.AllowLeave == false then return cb(fail('Quitter son métier est désactivé')) end
    local job = JB.Jobs[xPlayer.job.name]
    if not job then return cb(fail('Tu n\'as aucun métier à quitter')) end
    xPlayer.setJob('unemployed', 0)
    if JB.log then pcall(JB.log, job.name, xPlayer, 'leave') end
    cb({ ok = true })
end)

ESX.RegisterServerCallback('jobbuilder:action', function(src, cb, action, targetId)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not jobHasAction(xPlayer, action) then return cb(fail('Action non autorisée')) end
    if not JB.isOnDuty(src) then return cb(fail('Prends ton service (menu F6) pour utiliser cette action')) end
    local cfg = Config.Actions[action]
    local target
    if cfg.target then
        target = ESX.GetPlayerFromId(tonumber(targetId))
        if not target then return cb(fail('Aucun joueur à proximité')) end
        if target.source ~= src and not playersClose(src, target.source) then return cb(fail('Le joueur est trop loin')) end
    end

    if action == 'handcuff' then
        TriggerClientEvent('jobbuilder:client:cuff', target.source, src)
    elseif action == 'escort' then
        if not Player(target.source).state.jbCuffed then return cb(fail('Le joueur doit être menotté')) end
        TriggerClientEvent('jobbuilder:client:drag', target.source, src)
    elseif action == 'search' then
        if JB.inventory() ~= 'ox' then return cb(fail('La fouille nécessite ox_inventory')) end
        TriggerClientEvent('jobbuilder:client:search', src, target.source)
    elseif action == 'revive' then
        if JB.startCpr and JB.deathActive() then
            local ok, err = JB.startCpr(src, target.source)
            if not ok then return cb(fail(err)) end
        else
            TriggerClientEvent(Config.ReviveEvent, target.source)
        end
    elseif action == 'heal' then
        TriggerClientEvent('jobbuilder:client:heal', target.source)
    end
    JB.log(xPlayer.job.name, xPlayer, 'action_' .. action, target and JB.playerName(target) or nil)
    cb({ ok = true })
end)

local invoices, invoiceId = {}, 0

-- Envoie une facture au joueur proche. `item` (optionnel) = { name, label, count } : l'objet est échangé contre le paiement (vente directe)
local function sendInvoice(xPlayer, target, label, amount, item, hooks)
    invoiceId = invoiceId + 1
    local id = invoiceId
    invoices[id] = { from = xPlayer.source, to = target.source, amount = amount, label = label, job = xPlayer.job.name, expires = os.time() + 60, item = item, hooks = hooks }
    local job = JB.Jobs[xPlayer.job.name]
    TriggerClientEvent('jobbuilder:client:invoice', target.source, id, job.label, label, amount, hooks and hooks.offer or nil)
end
JB.sendInvoice = sendInvoice

ESX.RegisterServerCallback('jobbuilder:invoice:send', function(src, cb, targetId, label, amount)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not jobHasAction(xPlayer, 'invoice') then return cb(fail('Facturation non autorisée')) end
    local target = ESX.GetPlayerFromId(tonumber(targetId))
    amount = math.floor(tonumber(amount) or 0)
    if not target or target.source == src then return cb(fail('Aucun joueur valide à proximité')) end
    if amount < 1 or amount > 1000000 then return cb(fail('Montant invalide (1 à 1 000 000)')) end
    if not playersClose(src, target.source) then return cb(fail('Le joueur est trop loin')) end
    label = tostring(label or 'Facture'):gsub('%c', ''):sub(1, 60)
    sendInvoice(xPlayer, target, label, amount)
    cb({ ok = true })
end)

JB.jobHasAction, JB.playersClose = jobHasAction, playersClose

RegisterNetEvent('jobbuilder:server:invoiceAnswer', function(id, accepted)
    local src = source
    local inv = invoices[id]
    if not inv or inv.to ~= src then return end
    invoices[id] = nil
    if inv.expires < os.time() then return end
    local issuer = ESX.GetPlayerFromId(inv.from)
    local payer = ESX.GetPlayerFromId(src)
    if not payer then return end
    local function hook(name, ...)
        if inv.hooks and inv.hooks[name] then pcall(inv.hooks[name], ...) end
    end
    if not accepted then
        if issuer then JBNotifyClient( inv.from, '~r~La facture a été refusée.') end
        return hook('onRefused', 'refused')
    end
    if inv.hooks and inv.hooks.offer then           -- proposition (prêt, dépôt, retrait…) : ni objet ni paiement, le module décide
        if issuer and not playersClose(inv.from, src) then return JBNotifyClient( src, '~r~Le conseiller n\'est plus à côté de toi.') end
        return hook('onAccept', payer, issuer)
    end
    local item = inv.item
    if item then
        if not issuer or not playersClose(inv.from, src) then
            return JBNotifyClient( src, '~r~Le vendeur n\'est plus à côté de toi.')
        end
        if JB.itemCount(inv.from, issuer, item.name) < item.count then
            JBNotifyClient( src, '~r~Le vendeur n\'a plus ce produit.')
            return JBNotifyClient( inv.from, '~r~Tu n\'as plus le produit à vendre.')
        end
        if not JB.canCarry(src, payer, item.name, item.count) then
            JBNotifyClient( inv.from, '~r~Le client ne peut pas porter ça.')
            return JBNotifyClient( src, '~r~Tu ne peux pas porter ça.')
        end
        if not JB.takeItem(inv.from, issuer, item.name, item.count) then
            return JBNotifyClient( src, '~r~Le vendeur n\'a plus ce produit.')
        end
    end
    if not pay(payer, inv.amount) then
        if item then JB.giveItem(inv.from, issuer, item.name, item.count) end
        JBNotifyClient( src, '~r~Tu n\'as pas assez d\'argent.')
        if issuer then JBNotifyClient( inv.from, '~r~Le client n\'a pas assez d\'argent.') end
        return hook('onRefused', 'unpaid')
    end
    if item then JB.giveItem(src, payer, item.name, item.count) end
    hook('onPaid')
    local job = JB.Jobs[inv.job]
    if job and job.society then
        local tax = JB.applyTax and JB.applyTax('invoice', inv.amount, inv.job) or 0
        societyAdd(inv.job, inv.amount - tax)
    elseif issuer then
        issuer.addAccountMoney('bank', inv.amount)
    end
    JBNotifyClient( src, ('Facture payée : ~g~%d$'):format(inv.amount))
    if issuer then
        JBNotifyClient( inv.from, ('Facture payée : ~g~+%d$'):format(inv.amount))
        JB.log(inv.job, issuer, 'invoice_paid', ('%s : %d$ (%s)'):format(JB.playerName(payer), inv.amount, inv.label))
    end
end)

-- Salaire : la société paie (optionnel) -> géré par ESX (paycheck). Rien d'autre à faire ici.
