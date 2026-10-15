-- ─────────────────────────────── Runtime : utilisation des points par les joueurs ───────────────────────────────
-- Chaque appel re-vérifie : le point existe, le joueur est dans CE gang (job2), grade suffisant, et il est à proximité.
-- Les gangs ne sont jamais mélangés : un point n'est utilisable que par le gang auquel il appartient.

local J = Config.Job2

local function fail(msg) return { ok = false, error = msg } end

-- point, xPlayer, grade — ou nil, nil, nil, erreur
local function getPoint(src, pointId, ptype, publicOk)
    local xPlayer = ESX.GetPlayerFromId(src)
    local point = GB.Points[tonumber(pointId)]
    if not xPlayer or not point then return nil, nil, nil, 'Point introuvable' end
    if ptype and point.type ~= ptype then return nil, nil, nil, 'Point invalide' end
    if GB.distanceTo(src, point.coords) > Config.ServerDistance then return nil, nil, nil, 'Tu es trop loin' end
    local name, grade = GB.job2Of(xPlayer)
    if not (publicOk and point.type == 'shop' and point.data and point.data.public) then
        if name ~= point.gang_name then return nil, nil, nil, 'Ce point n\'appartient pas à ton gang' end
        if grade < point.min_grade then return nil, nil, nil, 'Ton grade est insuffisant' end
    end
    return point, xPlayer, grade
end
GB.getPoint = getPoint

-- ─────────────────────────────── Données boss ───────────────────────────────
local function maxMembers(gang)
    local m = gang.settings.max_members
    if m == nil or m < 0 then m = Config.Gang.MaxMembers end
    return m
end

local function bossData(gang, grade)
    local money, dirty, rep = GB.treasury(gang.name)
    local logs = MySQL.query.await('SELECT action, detail, player_name, UNIX_TIMESTAMP(created_at) AS t FROM gangbuilder_logs WHERE gang_name = ? ORDER BY id DESC LIMIT 40', { gang.name }) or {}
    return {
        gang = gang.name, label = gang.label, color = gang.color, money = money, dirty = dirty, rep = rep,
        grades = gang.grades, boss_grade = gang.boss_grade, myGrade = grade,
        withdraw_grade = gang.settings.withdraw_grade or gang.boss_grade,
        treasury = { enabled = Config.Treasury.Enabled, deposit = Config.Treasury.AllowDeposit, withdraw = Config.Treasury.AllowWithdraw, dirty = Config.Treasury.DepositDirty, max = Config.Treasury.MaxTransaction },
        members = GB.members(gang.name), maxMembers = maxMembers(gang), logs = logs,
    }
end

-- ─────────────────────────────── Ouverture d'un point ───────────────────────────────
ESX.RegisterServerCallback('gangbuilder:openPoint', function(src, cb, pointId)
    local point = GB.Points[tonumber(pointId)]
    if not point then return cb(fail('Point introuvable')) end
    local point2, xPlayer, grade, err = getPoint(src, pointId, nil, true)
    if not point2 then return cb(fail(err)) end
    local gang = GB.Gangs[point.gang_name]
    local d = point.data

    if point.type == 'garage' then
        local list = {}
        for i, v in ipairs(d.vehicles) do
            if grade >= v.min_grade then list[#list + 1] = { idx = i, model = v.model, label = v.label } end
        end
        cb({ ok = true, kind = 'garage', garageKind = d.kind or 'car', label = point.label, vehicles = list })

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
        if GB.inventory() ~= 'ox' then return cb(fail('Les coffres nécessitent ox_inventory')) end
        cb({ ok = true, kind = 'stash', stash = ('gangbuilder_%d'):format(point.id) })

    elseif point.type == 'boss' then
        if grade < gang.boss_grade then return cb(fail('Réservé aux grades de direction')) end
        local data = bossData(gang, grade)
        data.ok, data.kind, data.pointLabel = true, 'boss', point.label
        cb(data)

    elseif point.type == 'shop' then
        local member = GB.job2Of(xPlayer) == point.gang_name
        local list = {}
        for i, it in ipairs(d.items) do
            if not member or grade >= it.min_grade then list[#list + 1] = { idx = i, name = it.name, label = it.label, price = it.price } end
        end
        cb({ ok = true, kind = 'shop', label = point.label, account = d.account or 'money', items = list })

    elseif point.type == 'harvest' or point.type == 'process' or point.type == 'sell' or point.type == 'laundry' then
        if not GB.openActivity then return cb(fail('Module activités non chargé (server/activities.lua)')) end
        GB.openActivity(src, xPlayer, point, gang, grade, cb)

    else
        cb(fail('Type inconnu'))
    end
end)

-- ─────────────────────────────── Garage ───────────────────────────────
ESX.RegisterServerCallback('gangbuilder:garage:spawn', function(src, cb, pointId, idx)
    local point, xPlayer, grade, err = getPoint(src, pointId, 'garage')
    if not point then return cb(fail(err)) end
    local v = point.data.vehicles[tonumber(idx) or 0]
    if not v or grade < v.min_grade then return cb(fail('Véhicule indisponible pour ton grade')) end
    local gang = GB.Gangs[point.gang_name]
    local prefix = gang.settings.plate_prefix or ''
    if prefix == '' then prefix = (point.gang_name:upper():gsub('[^%w]', '')):sub(1, Config.PlatePrefixLength) end
    prefix = prefix:sub(1, 4)
    local digits = 8 - #prefix
    local plate = prefix .. ('%0' .. digits .. 'd'):format(math.floor(math.random(0, math.floor(10 ^ digits) - 1)))
    GB.log(point.gang_name, xPlayer, 'vehicle_out', ('%s (%s)'):format(v.label, plate))
    cb({ ok = true, model = v.model, plate = plate, spawn = point.data.spawn, color = v.color })
end)

ESX.RegisterServerCallback('gangbuilder:garage:store', function(src, cb, pointId, plate)
    local point, xPlayer, _, err = getPoint(src, pointId, 'garage')
    if not point then return cb(fail(err)) end
    GB.log(point.gang_name, xPlayer, 'vehicle_in', tostring(plate))
    cb({ ok = true })
end)

-- ─────────────────────────────── Vestiaire ───────────────────────────────
ESX.RegisterServerCallback('gangbuilder:cloak:wear', function(src, cb, pointId, idx)
    local point, xPlayer, grade, err = getPoint(src, pointId, 'cloakroom')
    if not point then return cb(fail(err)) end
    local o = point.data.outfits[tonumber(idx) or 0]
    if not o or grade < o.min_grade then return cb(fail('Tenue indisponible')) end
    local clothes = (xPlayer.get('sex') == 'f') and o.female or o.male
    if not clothes then return cb(fail('Cette tenue n\'existe pas pour ton genre')) end
    cb({ ok = true, clothes = clothes })
end)

-- ─────────────────────────────── Armurerie ───────────────────────────────
ESX.RegisterServerCallback('gangbuilder:armory:take', function(src, cb, pointId, idx)
    local point, xPlayer, grade, err = getPoint(src, pointId, 'armory')
    if not point then return cb(fail(err)) end
    local it = point.data.items[tonumber(idx) or 0]
    if not it or grade < it.min_grade then return cb(fail('Objet indisponible')) end
    local isWeapon = it.name:upper():find('^WEAPON_') ~= nil
    local count = isWeapon and 1 or it.count
    if not GB.canCarry(src, xPlayer, it.name, count) then return cb(fail('Tu ne peux pas porter ça')) end
    if isWeapon and GB.inventory() ~= 'ox' and xPlayer.hasWeapon(it.name:upper()) then return cb(fail('Tu as déjà cette arme')) end
    if not GB.giveItem(src, xPlayer, it.name, count, (isWeapon and it.ammo > 0) and { ammo = it.ammo } or nil) then return cb(fail('Impossible de donner l\'objet')) end
    GB.log(point.gang_name, xPlayer, 'armory_take', ('%dx %s'):format(count, it.label))
    cb({ ok = true })
end)

-- ─────────────────────────────── Marché noir ───────────────────────────────
ESX.RegisterServerCallback('gangbuilder:shop:buy', function(src, cb, pointId, idx, qty)
    local point, xPlayer, grade, err = getPoint(src, pointId, 'shop', true)
    if not point then return cb(fail(err)) end
    local it = point.data.items[tonumber(idx) or 0]
    qty = math.floor(tonumber(qty) or 1)
    if not it or qty < 1 or qty > 100 then return cb(fail('Quantité invalide')) end
    local member = GB.job2Of(xPlayer) == point.gang_name
    if member and grade < it.min_grade then return cb(fail('Article indisponible')) end
    local total = it.price * qty
    local account = point.data.account or 'money'
    if not GB.canCarry(src, xPlayer, it.name, qty) then return cb(fail('Tu ne peux pas porter ça')) end
    if not GB.debit(src, xPlayer, account, total) then return cb(fail(account == 'dirty' and 'Pas assez d\'argent sale' or 'Pas assez d\'argent')) end
    if not GB.giveItem(src, xPlayer, it.name, qty) then
        GB.credit(src, xPlayer, account, total)
        return cb(fail('Impossible de donner l\'objet'))
    end
    if total > 0 then GB.treasuryAdd(point.gang_name, account == 'dirty' and 'dirty' or 'money', total) end
    GB.log(point.gang_name, xPlayer, 'shop_buy', ('%dx %s pour %d$'):format(qty, it.label, total))
    cb({ ok = true })
end)

-- ─────────────────────────────── Boss ───────────────────────────────
local function bossPoint(src, pointId)
    local point, xPlayer, grade, err = getPoint(src, pointId, 'boss')
    if not point then return nil, nil, nil, nil, err end
    local gang = GB.Gangs[point.gang_name]
    if grade < gang.boss_grade then return nil, nil, nil, nil, 'Réservé aux grades de direction' end
    return point, xPlayer, gang, grade
end

local function bossReply(gang, grade, extra)
    local d = bossData(gang, grade)
    d.ok = true
    for k, v in pairs(extra or {}) do d[k] = v end
    return d
end

ESX.RegisterServerCallback('gangbuilder:boss:poll', function(src, cb, pointId)
    local point, _, gang, _, err = bossPoint(src, pointId)
    if not point then return cb(fail(err)) end
    local money, dirty = GB.treasury(gang.name)
    cb({ ok = true, gang = gang.name, money = money, dirty = dirty })
end)

ESX.RegisterServerCallback('gangbuilder:boss:money', function(src, cb, pointId, mode, kind, amount)
    local point, xPlayer, gang, grade, err = bossPoint(src, pointId)
    if not point then return cb(fail(err)) end
    local T = Config.Treasury
    if not T.Enabled then return cb(fail('La trésorerie est désactivée')) end
    kind = kind == 'dirty' and 'dirty' or 'money'
    if kind == 'dirty' and not T.DepositDirty then return cb(fail('L\'argent sale est désactivé')) end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 or amount > T.MaxTransaction then return cb(fail('Montant invalide')) end

    if mode == 'deposit' then
        if not T.AllowDeposit then return cb(fail('Les dépôts sont désactivés')) end
        if not GB.debit(src, xPlayer, kind == 'dirty' and 'dirty' or 'money', amount) then return cb(fail(kind == 'dirty' and 'Pas assez d\'argent sale' or 'Pas assez d\'argent liquide')) end
        if not GB.treasuryAdd(gang.name, kind, amount) then
            GB.credit(src, xPlayer, kind == 'dirty' and 'dirty' or 'money', amount)
            return cb(fail('Dépôt impossible : trésorerie inaccessible'))
        end
        GB.stat(xPlayer.identifier, gang.name, 'contribution', amount)
        GB.log(gang.name, xPlayer, kind == 'dirty' and 'dirty_deposit' or 'treasury_deposit', amount .. '$')
    elseif mode == 'withdraw' then
        if not T.AllowWithdraw then return cb(fail('Les retraits sont désactivés')) end
        if grade < (gang.settings.withdraw_grade or gang.boss_grade) then return cb(fail('Ton grade ne permet pas de retirer de l\'argent')) end
        if not GB.treasuryRemove(gang.name, kind, amount) then return cb(fail('Fonds insuffisants dans la trésorerie')) end
        GB.credit(src, xPlayer, kind == 'dirty' and 'dirty' or 'money', amount)
        GB.log(gang.name, xPlayer, kind == 'dirty' and 'dirty_withdraw' or 'treasury_withdraw', amount .. '$')
    else
        return cb(fail('Action invalide'))
    end
    cb(bossReply(gang, grade))
end)

ESX.RegisterServerCallback('gangbuilder:boss:recruit', function(src, cb, pointId, targetId)
    local point, xPlayer, gang, grade, err = bossPoint(src, pointId)
    if not point then return cb(fail(err)) end
    local target = ESX.GetPlayerFromId(tonumber(targetId))
    if not target or target.source == src then return cb(fail('Aucun joueur à proximité')) end
    if not GB.playersClose(src, target.source) then return cb(fail('Le joueur est trop loin')) end
    local tName = GB.job2Of(target)
    if tName == gang.name then return cb(fail('Déjà dans ce gang')) end
    if Config.Gang.RecruitOnlyUnassigned and tName and tName ~= J.Default.name then
        return cb(fail(GB.Gangs[tName] and 'Ce joueur est déjà dans un autre gang' or 'Ce joueur a déjà un job2 : il doit d\'abord le quitter'))
    end
    local mm = maxMembers(gang)
    if mm > 0 and GB.memberCount(gang.name) >= mm then return cb(fail(('Le gang est complet (%d membres max)'):format(mm))) end
    local rg = math.min(gang.settings.recruit_grade or Config.Gang.RecruitGrade, #gang.grades - 1)
    if not GB.setJob2(target, gang.name, rg) then return cb(fail('Recrutement impossible')) end
    GB.notify(target.source, ('Tu as rejoint ~r~%s'):format(gang.label))
    GB.log(gang.name, xPlayer, 'recruit', GB.playerName(target))
    cb(bossReply(gang, grade))
end)

-- Grade actuel d'un membre du gang (en ligne ou non) : grade, xPlayer — nil s'il n'est pas dans ce gang
local function memberGrade(identifier, gangName)
    local x = ESX.GetPlayerFromIdentifier(identifier)
    if x then
        local n, g = GB.job2Of(x)
        return n == gangName and g or nil, x
    end
    local row = MySQL.single.await(('SELECT %s AS job, %s AS grade FROM %s WHERE %s = ?'):format(GB.id(J.UserJobColumn), GB.id(J.UserGradeColumn), GB.id(J.UsersTable), GB.id(J.IdentifierColumn)), { identifier })
    if row and row.job == gangName then return tonumber(row.grade) or 0 end
    return nil
end

ESX.RegisterServerCallback('gangbuilder:boss:setGrade', function(src, cb, pointId, identifier, newGrade)
    local point, xPlayer, gang, grade, err = bossPoint(src, pointId)
    if not point then return cb(fail(err)) end
    newGrade = math.floor(tonumber(newGrade) or -1)
    if newGrade < 0 or newGrade > #gang.grades - 1 then return cb(fail('Grade invalide')) end
    if identifier == xPlayer.identifier then return cb(fail('Tu ne peux pas modifier ton propre grade')) end
    local current = memberGrade(identifier, gang.name)
    if not current then return cb(fail('Ce membre n\'est pas dans ton gang')) end
    if Config.Gang.ProtectBoss and current >= gang.boss_grade then return cb(fail('Tu ne peux pas modifier un autre membre de la direction')) end
    if Config.Gang.ProtectBoss and newGrade > grade then return cb(fail('Tu ne peux pas promouvoir au-dessus de ton propre grade')) end
    GB.setMemberJob2(identifier, gang.name, newGrade, gang.name)
    GB.log(gang.name, xPlayer, 'set_grade', ('%s -> %s'):format(identifier:sub(-8), gang.grades[newGrade + 1].label))
    cb(bossReply(gang, grade))
end)

ESX.RegisterServerCallback('gangbuilder:boss:fire', function(src, cb, pointId, identifier)
    local point, xPlayer, gang, grade, err = bossPoint(src, pointId)
    if not point then return cb(fail(err)) end
    if identifier == xPlayer.identifier then return cb(fail('Tu ne peux pas te virer toi-même')) end
    local current = memberGrade(identifier, gang.name)
    if not current then return cb(fail('Ce membre n\'est pas dans ton gang')) end
    if Config.Gang.ProtectBoss and current >= gang.boss_grade then return cb(fail('Tu ne peux pas virer un autre membre de la direction')) end
    local _, xTarget = GB.clearMember(identifier, gang.name)
    if xTarget then GB.notify(xTarget.source, ('Tu as été exclu de ~r~%s'):format(gang.label)) end
    GB.log(gang.name, xPlayer, 'fire', identifier:sub(-8))
    cb(bossReply(gang, grade))
end)

ESX.RegisterServerCallback('gangbuilder:boss:salary', function(src, cb, pointId, g, salary)
    local point, xPlayer, gang, grade, err = bossPoint(src, pointId)
    if not point then return cb(fail(err)) end
    g = math.floor(tonumber(g) or -1)
    salary = math.floor(tonumber(salary) or -1)
    if g < 0 or g > #gang.grades - 1 or salary < 0 or salary > 1000000 then return cb(fail('Valeur invalide')) end
    local C = J.GradeColumns
    MySQL.update.await(('UPDATE %s SET %s = ? WHERE %s = ? AND %s = ?'):format(GB.id(J.GradesTable), GB.id(C.salary), GB.id(C.job), GB.id(C.grade)), { salary, gang.name, g })
    gang.grades[g + 1].salary = salary
    GB.refreshJob2()
    GB.log(gang.name, xPlayer, 'set_salary', ('%s : %d$'):format(gang.grades[g + 1].label, salary))
    cb(bossReply(gang, grade))
end)

-- ─────────────────────────────── Menu gang : actions ───────────────────────────────
ESX.RegisterServerCallback('gangbuilder:action', function(src, cb, action, targetId)
    local gang, _, xPlayer = GB.gangOf(src)
    local cfg = Config.Actions[action]
    if not gang or not cfg or action == 'info' or action == 'leave' then return cb(fail('Action non autorisée')) end
    local allowed = false
    for _, a in ipairs(gang.settings.actions or {}) do if a == action then allowed = true end end
    if not allowed then return cb(fail('Action non autorisée pour ton gang')) end
    local target
    if cfg.target then
        target = ESX.GetPlayerFromId(tonumber(targetId))
        if not target or target.source == src then return cb(fail('Aucun joueur à proximité')) end
        if not GB.playersClose(src, target.source) then return cb(fail('Le joueur est trop loin')) end
    end

    local R = Config.ActionRules
    if action == 'handcuff' then
        TriggerClientEvent('gangbuilder:client:cuff', target.source, src)
    elseif action == 'escort' then
        if R.EscortRequiresCuffed and not Player(target.source).state.gbCuffed then return cb(fail('Le joueur doit être menotté')) end
        TriggerClientEvent('gangbuilder:client:drag', target.source, src)
    elseif action == 'search' then
        if GB.inventory() ~= 'ox' then return cb(fail('La fouille nécessite ox_inventory')) end
        if R.SearchRequiresCuffed and not Player(target.source).state.gbCuffed then return cb(fail('Le joueur doit être menotté')) end
        TriggerClientEvent('gangbuilder:client:search', src, target.source)
    end
    GB.log(gang.name, xPlayer, 'action_' .. action, target and GB.playerName(target) or nil)
    cb({ ok = true })
end)

ESX.RegisterServerCallback('gangbuilder:leave', function(src, cb)
    local gang, _, xPlayer = GB.gangOf(src)
    if not gang then return cb(fail('Tu n\'es dans aucun gang')) end
    if not Config.Gang.AllowLeave then return cb(fail('Quitter son gang est désactivé')) end
    GB.setJob2(xPlayer, J.Default.name, J.Default.grade)
    GB.log(gang.name, xPlayer, 'leave', GB.playerName(xPlayer))
    cb({ ok = true })
end)

-- ─────────────────────────────── Fiche du gang (F7 → Fiche du gang) ───────────────────────────────
ESX.RegisterServerCallback('gangbuilder:info', function(src, cb)
    local gang, grade, xPlayer = GB.gangOf(src)
    if not gang then return cb(fail('Tu n\'es dans aucun gang')) end
    local money, dirty, rep = GB.treasury(gang.name)
    local online = {}
    for _, s in ipairs(GB.onlineMembers(gang.name)) do
        local x = ESX.GetPlayerFromId(s)
        if x then
            local _, g = GB.job2Of(x)
            online[#online + 1] = { name = GB.playerName(x), grade = g, gradeLabel = (gang.grades[g + 1] or {}).label or '' }
        end
    end
    table.sort(online, function(a, b) return a.grade > b.grade end)
    local terr = {}
    for _, t in pairs(GB.Territories) do
        local o = t.owner and GB.Gangs[t.owner]
        terr[#terr + 1] = { id = t.id, label = t.label, owner = t.owner, ownerLabel = o and o.label or nil, mine = t.owner == gang.name, protectedUntil = t.protected_until }
    end
    table.sort(terr, function(a, b) return a.id < b.id end)
    local stats = MySQL.single.await('SELECT harvested, processed, sold, laundered, contribution FROM gangbuilder_stats WHERE identifier = ? AND gang_name = ?', { xPlayer.identifier, gang.name }) or {}
    local seeMoney = grade >= (gang.settings.withdraw_grade or gang.boss_grade)
    cb({
        ok = true, name = gang.name, label = gang.label, color = gang.color, motd = gang.settings.motd or '', grade = grade, gradeLabel = (gang.grades[grade + 1] or {}).label or '',
        rep = rep, money = seeMoney and money or nil, dirty = seeMoney and dirty or nil, members = GB.memberCount(gang.name), maxMembers = maxMembers(gang),
        online = online, territories = terr, now = os.time(),
        stats = { harvested = stats.harvested or 0, processed = stats.processed or 0, sold = stats.sold or 0, laundered = stats.laundered or 0, contribution = stats.contribution or 0 },
    })
end)

-- ─────────────────────────────── Salaires (si Config.Salary.Enabled) ───────────────────────────────
CreateThread(function()
    local last = os.time()
    while true do
        Wait(60 * 1000)
        local S = Config.Salary
        if S.Enabled and GB.ready and os.time() - last >= S.IntervalMinutes * 60 then
            last = os.time()
            for name, gang in pairs(GB.Gangs) do
                local payees, total = {}, 0
                for _, s in ipairs(GB.onlineMembers(name)) do
                    local x = ESX.GetPlayerFromId(s)
                    if x then
                        local _, g = GB.job2Of(x)
                        local salary = (gang.grades[g + 1] or {}).salary or 0
                        if salary > 0 then payees[#payees + 1] = { x = x, salary = salary } total = total + salary end
                    end
                end
                local source = gang.settings.salary_source
                if source == nil or source == 'default' then source = S.Source end
                if #payees > 0 then
                    if source == 'treasury' then
                        local money = GB.treasury(name)
                        if money < total and S.SkipIfBroke then
                            GB.log(name, nil, 'salary_skipped', ('trésorerie insuffisante : $%d / $%d'):format(money, total))
                            for _, p in ipairs(payees) do GB.notify(p.x.source, '~r~La trésorerie du gang est vide : pas de salaire cette fois.') end
                        else
                            for _, p in ipairs(payees) do
                                if GB.treasuryRemove(name, 'money', p.salary) then
                                    p.x.addAccountMoney(S.Account, p.salary)
                                    GB.notify(p.x.source, ('Salaire du gang : ~g~$%d'):format(p.salary))
                                end
                            end
                        end
                    else
                        for _, p in ipairs(payees) do
                            p.x.addAccountMoney(S.Account, p.salary)
                            GB.notify(p.x.source, ('Salaire du gang : ~g~$%d'):format(p.salary))
                        end
                    end
                end
            end
        end
    end
end)
