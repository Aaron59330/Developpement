-- Darkchat (salons anonymes), Entreprise (jobs du Job Builder), Clés de véhicules
local DC = Config.Darkchat

-- ═════════════════ DARKCHAT ═════════════════
CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS aura_dc_users (
        identifier VARCHAR(80) NOT NULL PRIMARY KEY, alias VARCHAR(24) NOT NULL, color VARCHAR(8) NOT NULL, changed BIGINT NOT NULL DEFAULT 0, UNIQUE KEY uq_alias (alias))]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS aura_dc_rooms (
        id VARCHAR(32) NOT NULL PRIMARY KEY, name VARCHAR(40) NOT NULL, public TINYINT(1) NOT NULL DEFAULT 1, pass VARCHAR(64) NULL,
        ttl INT NOT NULL DEFAULT 24, creator VARCHAR(80) NULL, created BIGINT NOT NULL, last BIGINT NOT NULL)]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS aura_dc_members (
        room VARCHAR(32) NOT NULL, identifier VARCHAR(80) NOT NULL, PRIMARY KEY (room, identifier), INDEX (identifier))]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS aura_dc_msgs (
        id BIGINT AUTO_INCREMENT PRIMARY KEY, room VARCHAR(32) NOT NULL, alias VARCHAR(24) NOT NULL, color VARCHAR(8) NOT NULL, body TEXT NULL, image TEXT NULL,
        created BIGINT NOT NULL, identifier VARCHAR(80) NOT NULL, INDEX (room, id))]])
    for _, r in ipairs(DC.publicRooms or {}) do
        MySQL.query.await('INSERT IGNORE INTO aura_dc_rooms (id, name, public, ttl, created, last) VALUES (?,?,1,?,?,?)', { r.id, r.name, r.ttl or 24, Aura.Now(), Aura.Now() })
    end
    while true do   -- nettoyage : messages expirés, salons inactifs
        Wait(300000)
        local rooms = MySQL.query.await('SELECT id, ttl FROM aura_dc_rooms WHERE ttl > 0') or {}
        for _, r in ipairs(rooms) do MySQL.query('DELETE FROM aura_dc_msgs WHERE room = ? AND created < ?', { r.id, Aura.Now() - r.ttl * 3600000 }) end
        local idle = Aura.Now() - (DC.idleRoomDays or 7) * 86400000
        local dead = MySQL.query.await('SELECT id FROM aura_dc_rooms WHERE last < ? AND creator IS NOT NULL', { idle }) or {}
        for _, r in ipairs(dead) do
            MySQL.query('DELETE FROM aura_dc_msgs WHERE room = ?', { r.id }); MySQL.query('DELETE FROM aura_dc_members WHERE room = ?', { r.id }); MySQL.query('DELETE FROM aura_dc_rooms WHERE id = ?', { r.id })
        end
    end
end)

local COLORS = { '#ff6b6b', '#f59f00', '#40c057', '#15aabf', '#4c6ef5', '#7950f2', '#e64980', '#12b886', '#fd7e14', '#94d82d' }
local ADJ = { 'Fantôme', 'Ombre', 'Corbeau', 'Spectre', 'Renard', 'Loup', 'Masque', 'Brume', 'Lynx', 'Vipère', 'Faucon', 'Nocturne' }

local function userOf(id)
    local u = MySQL.single.await('SELECT alias, color, changed FROM aura_dc_users WHERE identifier = ?', { id })
    if u then return u end
    for _ = 1, 20 do
        local alias = ADJ[math.random(#ADJ)] .. '-' .. math.random(1000, 9999)
        local ok = MySQL.insert.await('INSERT IGNORE INTO aura_dc_users (identifier, alias, color, changed) VALUES (?,?,?,0)', { id, alias, COLORS[math.random(#COLORS)] })
        if ok and ok ~= 0 then return MySQL.single.await('SELECT alias, color, changed FROM aura_dc_users WHERE identifier = ?', { id }) end
    end
end

local function hasItem(src)
    if not DC.item or DC.item == '' then return true end
    return Bridge.HasItem(src, DC.item)
end

local function inRoom(id, room) return MySQL.scalar.await('SELECT 1 FROM aura_dc_members WHERE room = ? AND identifier = ?', { room, id }) ~= nil end

lib.callback.register('aura:dcAccess', function(src)
    if not DC.enabled then return false, 'Application indisponible' end
    if not hasItem(src) then return false, 'Il faut un appareil spécial pour accéder à ce réseau' end
    local id = Aura.ident[src]; if not id then return false end
    local u = userOf(id)
    return { alias = u.alias, color = u.color, ttl = DC.ttlOptions, max = DC.messageMax }
end)

lib.callback.register('aura:dcAlias', function(src, alias)
    local id = Aura.ident[src]; if not id or not DC.enabled or not hasItem(src) then return false end
    local u = userOf(id)
    if os.time() * 1000 - (u.changed or 0) < DC.aliasCooldown * 1000 and (u.changed or 0) ~= 0 then return false, 'Patientez avant de changer de pseudo' end
    alias = tostring(alias or ''):gsub('%s', ''):sub(1, 20)
    if alias == '' then alias = ADJ[math.random(#ADJ)] .. '-' .. math.random(1000, 9999) end
    if #alias < 3 or alias:find('[^%w_%-éèàùûôîç]') then return false, 'Pseudo : 3 à 20 caractères (lettres, chiffres, - _)' end
    local taken = MySQL.scalar.await('SELECT 1 FROM aura_dc_users WHERE LOWER(alias) = LOWER(?) AND identifier <> ?', { alias, id })
    if taken then return false, 'Pseudo déjà pris' end
    MySQL.update.await('UPDATE aura_dc_users SET alias = ?, changed = ? WHERE identifier = ?', { alias, Aura.Now(), id })
    return alias
end)

lib.callback.register('aura:dcRooms', function(src)
    local id = Aura.ident[src]; if not id or not DC.enabled or not hasItem(src) then return {} end
    local rows = MySQL.query.await([[SELECT r.id, r.name, r.public, r.ttl, r.last, (r.pass IS NOT NULL) AS locked, (r.creator = ?) AS mine,
        EXISTS(SELECT 1 FROM aura_dc_members m WHERE m.room = r.id AND m.identifier = ?) AS joined,
        (SELECT COUNT(*) FROM aura_dc_members m2 WHERE m2.room = r.id) AS members,
        (SELECT body FROM aura_dc_msgs g WHERE g.room = r.id ORDER BY g.id DESC LIMIT 1) AS preview
        FROM aura_dc_rooms r WHERE r.public = 1 OR EXISTS(SELECT 1 FROM aura_dc_members m3 WHERE m3.room = r.id AND m3.identifier = ?) ORDER BY r.last DESC]], { id, id, id }) or {}
    for _, r in ipairs(rows) do r.joined = r.joined == 1 or r.joined == true; r.locked = r.locked == 1 or r.locked == true; r.mine = r.mine == 1 or r.mine == true; r.public = r.public == 1 or r.public == true end
    return rows
end)

lib.callback.register('aura:dcCreate', function(src, name, public, pass, ttl)
    local id = Aura.ident[src]; if not id or not DC.enabled or not hasItem(src) then return false end
    name = Aura.Clamp(Aura.Trim(name), 40); if #name < 3 then return false, 'Nom trop court' end
    local n = MySQL.scalar.await('SELECT COUNT(*) FROM aura_dc_rooms WHERE creator = ?', { id }) or 0
    if n >= DC.maxRoomsOwn then return false, 'Limite de salons atteinte' end
    ttl = tonumber(ttl) or 24
    local okTtl = false
    for _, t in ipairs(DC.ttlOptions) do if t == ttl then okTtl = true end end
    if not okTtl then ttl = 24 end
    local rid = ('r%d%d'):format(os.time() % 100000, math.random(100, 999))
    pass = Aura.Trim(pass)
    if pass ~= '' then
        MySQL.insert.await('INSERT INTO aura_dc_rooms (id, name, public, pass, ttl, creator, created, last) VALUES (?,?,?,SHA2(?,256),?,?,?,?)', { rid, name, public and 1 or 0, pass, ttl, id, Aura.Now(), Aura.Now() })
    else
        MySQL.insert.await('INSERT INTO aura_dc_rooms (id, name, public, ttl, creator, created, last) VALUES (?,?,?,?,?,?,?)', { rid, name, public and 1 or 0, ttl, id, Aura.Now(), Aura.Now() })
    end
    MySQL.insert.await('INSERT IGNORE INTO aura_dc_members (room, identifier) VALUES (?,?)', { rid, id })
    return rid
end)

lib.callback.register('aura:dcJoin', function(src, room, pass)
    local id = Aura.ident[src]; if not id or not DC.enabled or not hasItem(src) then return false end
    local r = MySQL.single.await('SELECT id, public, pass FROM aura_dc_rooms WHERE id = ?', { tostring(room) })
    if not r then return false, 'Salon introuvable' end
    if r.pass then
        local ok = MySQL.scalar.await('SELECT 1 FROM aura_dc_rooms WHERE id = ? AND pass = SHA2(?,256)', { r.id, tostring(pass or '') })
        if not ok then return false, 'Mot de passe incorrect' end
    elseif r.public == 0 then return false, 'Salon privé : un code est nécessaire' end
    MySQL.insert.await('INSERT IGNORE INTO aura_dc_members (room, identifier) VALUES (?,?)', { r.id, id })
    return true
end)

-- rejoindre un salon privé avec son identifiant + mot de passe (salons non listés)
lib.callback.register('aura:dcLeave', function(src, room)
    local id = Aura.ident[src]; if not id then return false end
    MySQL.update.await('DELETE FROM aura_dc_members WHERE room = ? AND identifier = ?', { tostring(room), id })
    return true
end)

lib.callback.register('aura:dcMessages', function(src, room, before)
    local id = Aura.ident[src]; if not id or not DC.enabled or not hasItem(src) or not inRoom(id, room) then return {} end
    local rows
    if before and tonumber(before) then
        rows = MySQL.query.await('SELECT id, alias, color, body, image, created, (identifier = ?) AS mine FROM aura_dc_msgs WHERE room = ? AND id < ? ORDER BY id DESC LIMIT 50', { id, room, tonumber(before) })
    else
        rows = MySQL.query.await('SELECT id, alias, color, body, image, created, (identifier = ?) AS mine FROM aura_dc_msgs WHERE room = ? ORDER BY id DESC LIMIT 50', { id, room })
    end
    rows = rows or {}
    local out = {}
    for i = #rows, 1, -1 do rows[i].mine = rows[i].mine == 1 or rows[i].mine == true; out[#out + 1] = rows[i] end
    return out
end)

local lastDc = {}
lib.callback.register('aura:dcSend', function(src, room, body, image)
    local id = Aura.ident[src]; if not id or not DC.enabled or not hasItem(src) or not inRoom(id, room) then return false end
    if lastDc[src] and GetGameTimer() - lastDc[src] < 600 then return false, 'Trop rapide' end
    lastDc[src] = GetGameTimer()
    body = Aura.Clamp(Aura.Trim(body), DC.messageMax)
    if type(image) ~= 'string' or not image:match('^https?://') then image = nil else image = Aura.Clamp(image, 500) end
    if body == '' and not image then return false, 'Message vide' end
    local u = userOf(id)
    local created = Aura.Now()
    local mid = MySQL.insert.await('INSERT INTO aura_dc_msgs (room, alias, color, body, image, created, identifier) VALUES (?,?,?,?,?,?,?)', { room, u.alias, u.color, body, image, created, id })
    MySQL.update('UPDATE aura_dc_rooms SET last = ? WHERE id = ?', { created, room })
    local msg = { id = mid, alias = u.alias, color = u.color, body = body, image = image, created = created }
    for _, m in ipairs(MySQL.query.await('SELECT identifier FROM aura_dc_members WHERE room = ?', { room }) or {}) do
        if Aura.src[m.identifier] then
            local out = {}
            for k, v in pairs(msg) do out[k] = v end
            out.mine = m.identifier == id
            Aura.Push(m.identifier, 'dcMessage', { room = room, msg = out, silent = Aura.phones[m.identifier] and Aura.phones[m.identifier].settings.dnd })
        end
    end
    return mid
end)

lib.callback.register('aura:dcDelete', function(src, mid)
    local id = Aura.ident[src]; if not id then return false end
    if Aura.IsAdmin(src) then MySQL.update.await('DELETE FROM aura_dc_msgs WHERE id = ?', { tonumber(mid) or 0 })
    else MySQL.update.await('DELETE FROM aura_dc_msgs WHERE id = ? AND identifier = ?', { tonumber(mid) or 0, id }) end
    return true
end)

-- Modération (console ou admin) : /phone_dclog <salon> [nombre]  ·  /phone_dcclose <salon>
local function say(src, msg) if src == 0 then print(msg) else TriggerClientEvent('chat:addMessage', src, { args = { 'Darkchat', msg } }) end end
RegisterCommand('phone_dclog', function(src, args)
    if src ~= 0 and not Aura.IsAdmin(src) then return end
    local rows = MySQL.query.await('SELECT alias, identifier, body, image, created FROM aura_dc_msgs WHERE room = ? ORDER BY id DESC LIMIT ?', { tostring(args[1] or ''), tonumber(args[2]) or 20 }) or {}
    if #rows == 0 then say(src, 'Aucun message (ou salon inconnu).') end
    for i = #rows, 1, -1 do local r = rows[i]; say(src, ('[%s] %s (%s) : %s %s'):format(os.date('%H:%M', r.created // 1000), r.alias, r.identifier, r.body or '', r.image or '')) end
end, false)
RegisterCommand('phone_dcclose', function(src, args)
    if src ~= 0 and not Aura.IsAdmin(src) then return end
    local room = tostring(args[1] or '')
    MySQL.update.await('DELETE FROM aura_dc_msgs WHERE room = ?', { room }); MySQL.update.await('DELETE FROM aura_dc_members WHERE room = ?', { room }); MySQL.update.await('DELETE FROM aura_dc_rooms WHERE id = ?', { room })
    say(src, 'Salon supprimé : ' .. room)
end, false)

-- ═════════════════ ENTREPRISE ═════════════════
local function ignored(jobName)
    for _, n in ipairs(Config.JobLines.ignore or {}) do if n == jobName then return true end end
    return false
end

-- Infos d'un métier : Job Builder si disponible, sinon framework (ESX / QBCore / Qbox)
local function jobInfo(jobName)
    if not jobName or ignored(jobName) then return nil end
    local mode = (Config.Business.source or 'auto'):lower()
    if (mode == 'auto' or mode == 'jobbuilder') and GetResourceState('pickax_jobbuilder') == 'started' then
        local ok, info = pcall(function() return exports.pickax_jobbuilder:GetJobInfo(jobName) end)
        if ok and info then return info end
    end
    if mode == 'jobbuilder' then return nil end
    local j = Bridge.Jobs()[jobName]
    if not j then return nil end
    return { name = jobName, label = j.label, society = Bridge.HasSociety(jobName), bossGrade = j.bossGrade, grades = j.grades }
end
local function gradeLabel(info, g) for _, x in ipairs(info.grades) do if x.grade == g then return x.label end end return tostring(g) end
local function isBossOf(job, info) return job and ((job.grade or 0) >= info.bossGrade or job.isBoss == true) end

lib.callback.register('aura:biz', function(src)
    if not Config.Business.enabled then return nil end
    local job = Bridge.Job(src); if not job then return nil end
    local info = jobInfo(job.name)
    if not info then return { none = true } end
    local grade = job.grade or 0
    local isBoss = isBossOf(job, info)
    local out = { job = info.name, label = info.label, grade = grade, gradeLabel = gradeLabel(info, grade), isBoss = isBoss, grades = info.grades, society = info.society, canBill = grade >= Config.Business.billGrade, maxBill = Config.Business.maxBill, canManage = Config.Business.allowFire }
    if info.society and isBoss then out.money = Bridge.SocietyBalance(info.name) end
    local team = {}
    for _, m in ipairs(Bridge.PlayersByJob(info.name)) do
        team[#team + 1] = { src = m.source, name = Bridge.Name(m.source) or '?', grade = m.grade, gradeLabel = gradeLabel(info, m.grade), me = m.source == src }
    end
    table.sort(team, function(a, b) return a.grade > b.grade end)
    out.team = team
    return out
end)

local function nearTo(src, target, dist)
    if not target or target == src or not GetPlayerName(target) then return false end
    return #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target))) <= dist
end

lib.callback.register('aura:bizNearby', function(src)
    local out = {}
    for tid, tsrc in pairs(Aura.src) do
        if tsrc ~= src and nearTo(src, tsrc, math.max(Config.Business.billDistance, Config.Business.hireDistance)) then
            local j = Bridge.Job(tsrc)
            out[#out + 1] = { src = tsrc, name = Bridge.Name(tsrc) or Aura.Name(tid), job = j and j.label or '' }
        end
    end
    return out
end)

lib.callback.register('aura:bizBill', function(src, target, amount, reason)
    if not Config.Business.enabled then return false end
    local job = Bridge.Job(src); if not job then return false end
    local info = jobInfo(job.name)
    if not info then return false, 'Votre métier ne peut pas facturer' end
    if (job.grade or 0) < Config.Business.billGrade then return false, 'Votre grade ne permet pas de facturer' end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 or amount > Config.Business.maxBill then return false, 'Montant invalide' end
    if not nearTo(src, target, Config.Business.billDistance) then return false, 'Le client est trop loin' end
    local tid = Aura.ident[target]; if not tid then return false end
    reason = Aura.Clamp(Aura.Trim(reason), 120); if reason == '' then reason = 'Prestation' end
    local bid = Aura.CreateBill(tid, info.label, amount, reason, info.society and info.name or nil)
    return bid and true or false
end)

local function bossCtx(src, target)
    if not Config.Business.allowFire then return nil, 'Gestion désactivée' end
    local job = Bridge.Job(src); if not job then return nil, 'Indisponible' end
    local info = jobInfo(job.name); if not info then return nil, 'Aucune entreprise' end
    if not isBossOf(job, info) then return nil, 'Réservé à la direction' end
    return job, info, target and Bridge.Job(target)
end

lib.callback.register('aura:bizGrade', function(src, target, grade)
    target = tonumber(target)
    local job, info, tj = bossCtx(src, target)
    if not job then return false, info end
    if not tj or tj.name ~= info.name then return false, 'Employé introuvable' end
    grade = math.floor(tonumber(grade) or -1)
    local ok = false
    for _, g in ipairs(info.grades) do if g.grade == grade then ok = true end end
    if not ok then return false, 'Grade invalide' end
    if target == src then return false, 'Impossible de modifier votre propre grade' end
    if not Bridge.SetJob(target, info.name, grade) then return false, 'Modification impossible' end
    TriggerClientEvent('aura:push', target, 'notify', { app = 'business', title = info.label, body = 'Votre grade est désormais : ' .. gradeLabel(info, grade) })
    return true
end)

lib.callback.register('aura:bizFire', function(src, target)
    target = tonumber(target)
    local job, info, tj = bossCtx(src, target)
    if not job then return false, info end
    if not tj or tj.name ~= info.name or target == src then return false, 'Employé introuvable' end
    if not Bridge.SetJob(target, 'unemployed', 0) then return false, 'Licenciement impossible' end
    TriggerClientEvent('aura:push', target, 'notify', { app = 'business', title = info.label, body = 'Vous ne faites plus partie de l\'entreprise' })
    return true
end)

lib.callback.register('aura:bizHire', function(src, target, grade)
    target = tonumber(target)
    local job, info, tj = bossCtx(src, target)
    if not job then return false, info end
    if not tj or not nearTo(src, target, Config.Business.hireDistance) then return false, 'La personne est trop loin' end
    if tj.name == info.name then return false, 'Déjà employé(e) ici' end
    grade = math.floor(tonumber(grade) or 0)
    if not Bridge.SetJob(target, info.name, grade) then return false, 'Recrutement impossible' end
    TriggerClientEvent('aura:push', target, 'notify', { app = 'business', title = info.label, body = 'Bienvenue ! Vous avez été recruté(e) : ' .. gradeLabel(info, grade) })
    return true
end)

-- ═════════════════ CLÉS DE VÉHICULES ═════════════════
lib.callback.register('aura:vehOwns', function(src, plate)
    local id = Aura.ident[src]; if not id then return false end
    return Bridge.OwnsPlate(id, plate)
end)
