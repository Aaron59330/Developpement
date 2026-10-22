local fail = S.fail
local function ox() return GetResourceState('ox_inventory') == 'started' end

local function groupLabel(group)
    for _, g in ipairs(exports.pickax_core:StaffGrades() or {}) do if g.name == group then return g.label end end
    return group
end

local function warnCounts()
    local out = {}
    local sql = 'SELECT license, COUNT(*) AS n FROM staff_warns'
    if (Config.Warn.ExpireDays or 0) > 0 then sql = sql .. (' WHERE created > (NOW() - INTERVAL %d DAY)'):format(Config.Warn.ExpireDays) end
    for _, r in ipairs(MySQL.query.await(sql .. ' GROUP BY license') or {}) do out[r.license] = r.n end
    return out
end
S.warnCounts = warnCounts

local function accounts(target, xT)
    local cash, black = 0, 0
    if ox() then
        cash = exports.ox_inventory:GetItemCount(target, 'money') or 0
        black = exports.ox_inventory:GetItemCount(target, 'black_money') or 0
    else
        local a, b = xT.getAccount('money'), xT.getAccount('black_money')
        cash, black = a and a.money or 0, b and b.money or 0
    end
    local bank = xT.getAccount('bank')
    return { cash = cash, bank = bank and bank.money or 0, black = black }
end

-- ─────────────── Liste des joueurs ───────────────
S.reg('players', 'players', function(src)
    local sp = GetEntityCoords(GetPlayerPed(src))
    local wc = warnCounts()
    local list = {}
    for _, id in ipairs(GetPlayers()) do
        local t = tonumber(id)
        local x = ESX.GetPlayerFromId(t)
        if x then
            local job, job2 = x.getJob(), x.getJob2 and x.getJob2() or nil
            local c = GetEntityCoords(GetPlayerPed(t))
            list[#list + 1] = { id = t, name = GetPlayerName(t), rp = x.getName and x.getName() or nil, group = x.getGroup(), rank = S.rank(t),
                job = job and (job.label or job.name) or '', grade = job and job.grade_label or '', job2 = job2 and job2.name ~= 'unemployed2' and (job2.label or job2.name) or '',
                ping = GetPlayerPing(t), dist = math.floor(#(sp - c)), warns = wc[S.license(t) or ''] or 0, frozen = S.frozen[t] == true,
                service = exports.pickax_core:StaffInService(t) == true }
        end
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return { ok = true, players = list, me = src }
end)

-- ─────────────── Fiche joueur ───────────────
S.reg('player', 'players', function(src, target)
    target = tonumber(target)
    local x = target and ESX.GetPlayerFromId(target)
    if not x then return fail('Joueur hors ligne') end
    local lic = S.license(target) or ''
    local ped = GetPlayerPed(target)
    local c = GetEntityCoords(ped)
    local ids = {}
    for _, k in ipairs({ 'license', 'discord', 'steam', 'fivem' }) do local v = GetPlayerIdentifierByType(target, k) if v then ids[k] = v end end
    local job, job2 = x.getJob(), x.getJob2 and x.getJob2() or nil
    local warns = MySQL.query.await('SELECT id, UNIX_TIMESTAMP(created) AS t, staff_name, reason FROM staff_warns WHERE license = ? ORDER BY id DESC LIMIT 20', { lic }) or {}
    local notes = MySQL.query.await('SELECT id, UNIX_TIMESTAMP(created) AS t, staff_name, note FROM staff_notes WHERE license = ? ORDER BY id DESC LIMIT 20', { lic }) or {}
    local hist = MySQL.query.await('SELECT UNIX_TIMESTAMP(created) AS t, staff_name, action, details FROM staff_logs WHERE target_license = ? ORDER BY id DESC LIMIT 15', { lic }) or {}
    local bans = MySQL.query.await('SELECT reason, sourceName, timeat, permanent FROM banlisthistory WHERE licenseid = ? ORDER BY timeat DESC LIMIT 5', { lic }) or {}
    return { ok = true, id = target, name = GetPlayerName(target), rp = x.getName and x.getName() or nil, group = x.getGroup(), groupLabel = groupLabel(x.getGroup()), rank = S.rank(target),
        job = job and { name = job.name, label = job.label, grade = job.grade, gradeLabel = job.grade_label } or nil,
        job2 = job2 and { name = job2.name, label = job2.label, grade = job2.grade, gradeLabel = job2.grade_label } or nil,
        accounts = accounts(target, x), ping = GetPlayerPing(target), health = GetEntityHealth(ped), armor = GetPedArmour(ped),
        coords = { x = math.floor(c.x * 100) / 100, y = math.floor(c.y * 100) / 100, z = math.floor(c.z * 100) / 100 }, inVehicle = GetVehiclePedIsIn(ped, false) ~= 0,
        identifiers = ids, warns = warns, notes = notes, history = hist, bans = bans, frozen = S.frozen[target] == true, canPunish = S.outranks(src, target) }
end)

-- Inventaire en lecture seule
S.reg('inventory', 'viewinv', function(src, target)
    target = tonumber(target)
    if not target or not GetPlayerName(target) then return fail('Joueur hors ligne') end
    if not ox() then return fail('ox_inventory n\'est pas démarré') end
    local out = {}
    local items = exports.ox_inventory:GetInventoryItems(target) or {}
    for _, it in pairs(items) do
        if it and it.name and (it.count or 0) > 0 then out[#out + 1] = { name = it.name, label = it.label or it.name, count = it.count } end
    end
    table.sort(out, function(a, b) return a.label:lower() < b.label:lower() end)
    S.log(src, 'viewinv', target)
    return { ok = true, items = out }
end)

-- Catalogue d'objets pour les listes de choix
S.reg('items', 'giveItem', function()
    if not ox() then return fail('ox_inventory n\'est pas démarré') end
    local out = {}
    for name, it in pairs(exports.ox_inventory:Items() or {}) do
        if type(it) == 'table' then out[#out + 1] = { name = name, label = it.label or name, weapon = it.weapon == true or name:sub(1, 7) == 'WEAPON_' } end
    end
    table.sort(out, function(a, b) return a.label:lower() < b.label:lower() end)
    return { ok = true, items = out }
end)

-- Métiers / gangs (listes SQL)
S.reg('jobs', 'setJob', function()
    local function load(jobsT, gradesT)
        local rows = MySQL.query.await(('SELECT j.name AS jn, j.label AS jl, g.grade, g.label AS gl FROM %s j LEFT JOIN %s g ON g.job_name = j.name ORDER BY j.label, g.grade'):format(jobsT, gradesT)) or {}
        local by, list = {}, {}
        for _, r in ipairs(rows) do
            local j = by[r.jn]
            if not j then j = { name = r.jn, label = r.jl or r.jn, grades = {} } by[r.jn] = j list[#list + 1] = j end
            if r.grade ~= nil then j.grades[#j.grades + 1] = { grade = tonumber(r.grade), label = r.gl or ('Grade ' .. r.grade) } end
        end
        return list
    end
    local out = { ok = true, jobs = load('jobs', 'job_grades') }
    local ok, j2 = pcall(load, 'jobs2', 'job2_grades')
    out.jobs2 = ok and j2 or {}
    return out
end)

S.reg('grades', 'setGrade', function()
    return { ok = true, grades = exports.pickax_core:StaffGrades() }
end)

-- ─────────────── Actions sur un joueur ───────────────
local A = {}

local function notify(target, msg) TriggerClientEvent('esx:showNotification', target, msg) end
local function done(msg, extra) local r = { ok = true, msg = msg } if extra then for k, v in pairs(extra) do r[k] = v end end return r end

A.gotoPlayer = { target = true, fn = function(src, t)
    S.lastPos[src] = GetEntityCoords(GetPlayerPed(src))
    SetEntityCoords(GetPlayerPed(src), GetEntityCoords(GetPlayerPed(t)))
    return done('Téléporté sur le joueur')
end }
A.bringPlayer = { target = true, fn = function(src, t)
    S.lastPos[t] = GetEntityCoords(GetPlayerPed(t))
    SetEntityCoords(GetPlayerPed(t), GetEntityCoords(GetPlayerPed(src)))
    return done('Joueur amené sur toi')
end }
A.sendback = { target = true, fn = function(src, t)
    local p = S.lastPos[t]
    if not p then return fail('Aucune position précédente pour ce joueur') end
    SetEntityCoords(GetPlayerPed(t), p.x, p.y, p.z)
    S.lastPos[t] = nil
    return done('Joueur renvoyé à sa position précédente')
end }
A.tpcoords = { target = true, fn = function(src, t, _, a)
    local x, y, z = tonumber(a.x), tonumber(a.y), tonumber(a.z)
    if not x or not y or not z then return fail('Coordonnées invalides') end
    S.lastPos[t] = GetEntityCoords(GetPlayerPed(t))
    SetEntityCoords(GetPlayerPed(t), x + 0.0, y + 0.0, z + 0.0)
    return done('Joueur téléporté')
end }

A.heal = { target = true, fn = function(src, t)
    TriggerClientEvent('esx_status:healPlayer', t)
    SetEntityHealth(GetPlayerPed(t), 200)
    return done('Joueur soigné')
end }
A.revive = { target = true, fn = function(src, t)
    ExecuteCommand('revive ' .. t)
    return done('Joueur réanimé')
end }
A.armor = { target = true, fn = function(src, t)
    SetPedArmour(GetPlayerPed(t), 100)
    notify(t, 'Vous avez reçu un gilet pare-balles du staff.')
    return done('Armure donnée')
end }
A.freeze = { target = true, fn = function(src, t, _, a)
    local on = a.state == true
    S.frozen[t] = on or nil
    TriggerClientEvent('ESXCustomAdmin:freezePlayer', t, on and 'freeze' or 'unfreeze')
    notify(t, on and 'Vous avez été ~r~immobilisé~s~ par le staff.' or 'Vous pouvez de nouveau bouger.')
    return done(on and 'Joueur gelé' or 'Joueur libéré')
end }
A.kill = { target = true, fn = function(src, t)
    TriggerClientEvent('CorePickax:kill', t)
    return done('Joueur tué')
end }

A.message = { target = true, fn = function(src, t, _, a)
    local m = tostring(a.text or ''):gsub('[%c]', ' '):sub(1, 200)
    if m == '' then return fail('Message vide') end
    notify(t, '~r~Message du staff : ~s~' .. m)
    return done('Message envoyé')
end }

A.warn = { target = true, fn = function(src, t, x, a)
    local reason = tostring(a.reason or ''):gsub('[%c]', ' '):sub(1, 300)
    if #reason < 2 then return fail('Indique une raison') end
    local lic = S.license(t)
    MySQL.insert.await('INSERT INTO staff_warns (license, name, staff_name, reason) VALUES (?, ?, ?, ?)', { lic, GetPlayerName(t):sub(1, 80), S.name(src):sub(1, 80), reason })
    local n = S.warnCounts()[lic] or 1
    notify(t, ('~o~Avertissement n°%d~s~ : %s'):format(n, reason))
    if (Config.Warn.KickAt or 0) > 0 and n >= Config.Warn.KickAt then
        DropPlayer(t, ('Expulsé automatiquement : %d avertissements.\nDernier motif : %s'):format(n, reason))
        return done(('Avertissement n°%d : joueur expulsé (seuil atteint)'):format(n))
    end
    return done(('Avertissement n°%d enregistré'):format(n))
end }

A.spectate = { target = true, fn = function(src, t)
    if t == src then return fail('Tu ne peux pas te spectate toi-même') end
    return done('Mode spectateur', { client = { kind = 'spect', id = t } })
end }
A.jail = { target = true, fn = function(src, t, _, a)
    local m = math.floor(tonumber(a.minutes) or 0)
    if m < 1 or m > 1440 then return fail('Durée invalide (1 à 1440 min)') end
    return done('Joueur envoyé en prison', { client = { kind = 'cmd', cmd = ('jail %d %d'):format(t, m) } })
end }
A.unjail = { target = true, fn = function(src, t)
    return done('Joueur sorti de prison', { client = { kind = 'cmd', cmd = ('unjail %d'):format(t) } })
end }
A.kick = { target = true, fn = function(src, t, _, a)
    local r = tostring(a.reason or ''):gsub('[%c]', ' '):sub(1, 200)
    if r == '' then r = 'Expulsé par le staff' end
    DropPlayer(t, ('Vous avez été expulsé : %s (par %s)'):format(r, S.name(src)))
    return done('Joueur expulsé')
end }
A.ban = { target = true, fn = function(src, t, _, a)
    local dur = tostring(a.duration or '')
    local okDur = dur == 'perm' or dur:match('^%d+[mhd]$')
    if not okDur then return fail('Durée invalide') end
    local ok, err = exports.pickax_core:StaffBan(src, t, tostring(a.reason or ''):gsub('[%c]', ' '):sub(1, 200), dur)
    if not ok then return fail(err or 'Bannissement impossible') end
    return done('Joueur banni')
end }

local function accountName(a) return (a == 'cash' and 'money') or (a == 'black' and 'black_money') or (a == 'bank' and 'bank') or nil end
A.giveMoney = { target = true, fn = function(src, t, _, a)
    local acc, amt = accountName(a.account), math.floor(tonumber(a.amount) or 0)
    if not acc or amt < 1 or amt > 100000000 then return fail('Montant ou compte invalide') end
    local ok, err = exports.pickax_core:StaffGiveMoney(t, acc, amt)
    if not ok then return fail(err or 'Impossible') end
    notify(t, ('~g~Vous avez reçu %d$ (%s) du staff.'):format(amt, a.account))
    return done(('%d$ donnés'):format(amt))
end }
A.takeMoney = { target = true, fn = function(src, t, x, a)
    local acc, amt = accountName(a.account), math.floor(tonumber(a.amount) or 0)
    if not acc or amt < 1 then return fail('Montant ou compte invalide') end
    if acc == 'bank' then
        if (x.getAccount('bank').money or 0) < amt then return fail('Solde insuffisant') end
        x.removeAccountMoney('bank', amt)
    else
        if not ox() then return fail('ox_inventory n\'est pas démarré') end
        if (exports.ox_inventory:GetItemCount(t, acc) or 0) < amt then return fail('Le joueur n\'a pas autant') end
        exports.ox_inventory:RemoveItem(t, acc, amt)
    end
    notify(t, ('~r~%d$ (%s) ont été retirés par le staff.'):format(amt, a.account))
    return done(('%d$ retirés'):format(amt))
end }

A.giveItem = { target = true, fn = function(src, t, x, a)
    local item, n = tostring(a.item or ''), math.floor(tonumber(a.count) or 1)
    if not item:match('^[%w_%-%.]+$') or n < 1 or n > 100000 then return fail('Objet ou quantité invalide') end
    if not ox() then return fail('ox_inventory n\'est pas démarré') end
    if not exports.ox_inventory:Items(item) then return fail('Cet objet n\'existe pas') end
    local ok, resp = exports.ox_inventory:AddItem(t, item, n)
    if not ok then return fail(tostring(resp or 'Impossible de donner l\'objet')) end
    return done(('%dx %s donné(s)'):format(n, item))
end }
A.takeItem = { target = true, fn = function(src, t, _, a)
    local item, n = tostring(a.item or ''), math.floor(tonumber(a.count) or 1)
    if not item:match('^[%w_%-%.]+$') or n < 1 then return fail('Objet ou quantité invalide') end
    if not ox() then return fail('ox_inventory n\'est pas démarré') end
    local ok = exports.ox_inventory:RemoveItem(t, item, n)
    if not ok then return fail('Le joueur n\'a pas cet objet en quantité suffisante') end
    return done(('%dx %s retiré(s)'):format(n, item))
end }
A.giveWeapon = { target = true, fn = function(src, t, _, a)
    local w = tostring(a.weapon or ''):upper()
    if not w:match('^WEAPON_[%w_]+$') then return fail('Arme invalide') end
    if not ox() then return fail('ox_inventory n\'est pas démarré') end
    if not exports.ox_inventory:Items(w) then return fail('Cette arme n\'existe pas dans ox_inventory') end
    local ok, resp = exports.ox_inventory:AddItem(t, w, 1)
    if not ok then return fail(tostring(resp or 'Impossible de donner l\'arme')) end
    return done('Arme donnée')
end }
A.clearInventory = { target = true, fn = function(src, t)
    if not ox() then return fail('ox_inventory n\'est pas démarré') end
    exports.ox_inventory:ClearInventory(t)
    notify(t, '~r~Votre inventaire a été vidé par le staff.')
    return done('Inventaire vidé')
end }

A.setJob = { target = true, fn = function(src, t, x, a)
    local job, grade = tostring(a.job or ''), math.floor(tonumber(a.grade) or -1)
    if not ESX.DoesJobExist(job, grade) then return fail('Métier ou grade invalide') end
    x.setJob(job, grade)
    notify(t, 'Votre métier a été modifié par le staff.')
    return done('Métier modifié')
end }
A.setJob2 = { target = true, fn = function(src, t, x, a)
    local job, grade = tostring(a.job or ''), math.floor(tonumber(a.grade) or -1)
    local ok = MySQL.scalar.await('SELECT COUNT(*) FROM job2_grades WHERE job_name = ? AND grade = ?', { job, grade })
    if not ok or ok < 1 then return fail('Gang / orga ou grade invalide') end
    if type(x.setJob2) ~= 'function' then return fail('Ton ESX ne fournit pas setJob2') end
    x.setJob2(job, grade)
    notify(t, 'Votre gang / organisation a été modifié par le staff.')
    return done('Gang / orga modifié')
end }
A.resetIdentity = { target = true, fn = function(src, t)
    TriggerClientEvent('CorePickax:ridentityj', t)
    return done('Demande de réinitialisation envoyée au joueur')
end }
A.setGrade = { target = true, fn = function(src, t, _, a)
    local ok, err = exports.pickax_core:StaffSetGrade(src, t, tostring(a.group or ''))
    if not ok then return fail(err or 'Grade invalide') end
    return done('Grade staff modifié')
end }

A.notes = { target = true, fn = function(src, t, _, a)
    local text = tostring(a.text or ''):gsub('[%c]', ' '):sub(1, 500)
    if #text < 2 then return fail('Note vide') end
    MySQL.insert.await('INSERT INTO staff_notes (license, staff_name, note) VALUES (?, ?, ?)', { S.license(t), S.name(src):sub(1, 80), text })
    return done('Note ajoutée')
end }

ESX.RegisterServerCallback('pickax_staff:act', function(src, cb, action, target, args)
    local def = type(action) == 'string' and A[action]
    if not def then return cb(fail('Action inconnue')) end
    if not S.can(src, action) then return cb(fail('Accès refusé')) end
    args = type(args) == 'table' and args or {}
    local t, x = nil, nil
    if def.target then
        t = tonumber(target)
        x = t and ESX.GetPlayerFromId(t)
        if not x then return cb(fail('Joueur hors ligne')) end
        if Config.Punitive[action] and t ~= src and not S.outranks(src, t) then return cb(fail('Ce membre du staff a un rang égal ou supérieur au tien')) end
    end
    local ok, res = pcall(def.fn, src, t, x, args)
    if not ok then print('^1[pickax_staff]^7 act ' .. action .. ' : ' .. tostring(res)) return cb(fail('Erreur serveur')) end
    if res and res.ok then
        local d = {}
        for k, v in pairs(args) do d[k] = (type(v) == 'string') and v:sub(1, 80) or v end
        S.log(src, action, t, d)
    end
    cb(res)
end)

-- suppression d'un avertissement / d'une note
S.reg('deleteEntry', 'warnDelete', function(src, kind, id)
    id = math.floor(tonumber(id) or 0)
    if kind == 'warn' then MySQL.update.await('DELETE FROM staff_warns WHERE id = ?', { id })
    elseif kind == 'note' then MySQL.update.await('DELETE FROM staff_notes WHERE id = ?', { id })
    else return fail('Type inconnu') end
    S.log(src, 'delete_' .. kind, nil, { id = id })
    return { ok = true }
end)

AddEventHandler('playerDropped', function() local s = source S.frozen[s] = nil S.lastPos[s] = nil end)
