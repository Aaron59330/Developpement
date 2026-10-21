-- ─────────────────────────────── Détections côté serveur (OneSync) ───────────────────────────────
local now = AC.now
local hashOf = AC.hashOf
local UNARMED = hashOf('WEAPON_UNARMED')
local PARACHUTE = hashOf('GADGET_PARACHUTE')

local function mod(name) return AC.cfg and AC.cfg.modules[name] end
local function enabled(name) local m = mod(name) return m and m.enabled end

local function weaponName(hash)
    local list = Config.KnownWeapons or {}
    for _, w in ipairs(list) do if hashOf(w) == hash then return w end end
    return ('0x%08X'):format(hash)
end

-- L'arme tenue vient-elle d'une source légitime ? (inventaire ox, loadout ESX, liste blanche, liste blanche du métier)
local function weaponAllowed(src, hash)
    if hash == UNARMED or hash == PARACHUTE or AC.idx.wl[hash] then return true end
    local x = ESX.GetPlayerFromId(src)
    if x then
        local job = x.getJob and x.getJob() or nil
        if job and AC.idx.jobwl[job.name] and AC.idx.jobwl[job.name][hash] then return true end
    end
    if not AC.cfg.weapons.checkInventory then return true end
    if GetResourceState('ox_inventory') == 'started' then
        local ok, w = pcall(function() return exports.ox_inventory:GetCurrentWeapon(src) end)
        if ok and type(w) == 'table' and w.name and hashOf(w.name) == hash then return true end
    end
    if x and x.getLoadout then
        for _, wp in ipairs(x.getLoadout() or {}) do
            if wp.name and hashOf(wp.name) == hash then return true end
        end
    end
    return false
end

local function heightAboveGround(ped)
    local ok, h = pcall(GetEntityHeightAboveGround, ped)
    if ok and type(h) == 'number' then return h end
    return 0.0
end

-- ─────────────────────────────── Boucle d'échantillonnage (1 Hz) ───────────────────────────────
local function sample(src)
    local p = AC.players[src]
    if not p then return end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    local t = now()
    local pos = GetEntityCoords(ped)
    local veh = GetVehiclePedIsIn(ped, false)
    local inVeh = veh and veh ~= 0

    -- Téléportation (saut de position entre deux échantillons)
    local tp = mod('teleport')
    if tp and tp.enabled and p.lastPos and p.lastT and (t - p.lastT) > 700 and (t - p.lastT) < 2200 then
        local d = #(pos - p.lastPos)
        local limit = inVeh and tp.vehicleDistance or tp.distance
        if d > limit then
            AC.flag(src, 'teleport', { distance = math.floor(d), from = { x = math.floor(p.lastPos.x), y = math.floor(p.lastPos.y), z = math.floor(p.lastPos.z) },
                to = { x = math.floor(pos.x), y = math.floor(pos.y), z = math.floor(pos.z) }, vehicle = inVeh and true or false })
        end
    end
    p.lastPos, p.lastT = pos, t

    -- Vitesse à pied soutenue (fly / noclip / speed)
    local mv = mod('movement')
    if mv and mv.enabled and not inVeh then
        local v = GetEntityVelocity(ped)
        local horiz = math.sqrt(v.x * v.x + v.y * v.y)
        if horiz > mv.maxSpeed and heightAboveGround(ped) < 5.0 then
            p.moveHits = (p.moveHits or 0) + 1
            if p.moveHits >= mv.samples then
                p.moveHits = 0
                AC.flag(src, 'movement', { speed = math.floor(horiz * 10) / 10, limit = mv.maxSpeed, samples = mv.samples })
            end
        else p.moveHits = 0 end
    else p.moveHits = 0 end

    -- Invincibilité
    if enabled('godmode') then
        local ok, inv = pcall(GetPlayerInvincible, src)
        if ok and inv then
            p.godHits = (p.godHits or 0) + 1
            if p.godHits >= 3 then p.godHits = 0 AC.flag(src, 'godmode', { invincible = true }) end
        else p.godHits = 0 end
    end

    -- Santé / armure hors limites
    local hm = mod('health')
    if hm and hm.enabled then
        local hp, ar = GetEntityHealth(ped), GetPedArmour(ped)
        if hp > hm.maxHealth or ar > hm.maxArmor then
            p.hpHits = (p.hpHits or 0) + 1
            if p.hpHits >= 2 then p.hpHits = 0 AC.flag(src, 'health', { health = hp, armor = ar, maxHealth = hm.maxHealth, maxArmor = hm.maxArmor }) end
        else p.hpHits = 0 end
    end
end

-- Armes : une vérification toutes les 3 s, il faut deux échantillons consécutifs pour déclencher (évite les décalages d'équipement)
local function sampleWeapon(src)
    local p = AC.players[src]
    if not p then return end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    local veh = GetVehiclePedIsIn(ped, false)
    if veh and veh ~= 0 then p.wHits, p.bHits = 0, 0 return end
    local w = GetSelectedPedWeapon(ped) & 0xFFFFFFFF
    if w == UNARMED or w == PARACHUTE then p.wHits, p.bHits = 0, 0 return end

    if enabled('weaponBlacklist') and AC.idx.bl[w] then
        p.bHits = (p.bHits or 0) + 1
        if p.bHits >= 2 then p.bHits = 0 AC.flag(src, 'weaponBlacklist', { weapon = AC.idx.bl[w] }) end
        return
    end
    p.bHits = 0
    if enabled('weapon') then
        if not weaponAllowed(src, w) then
            p.wHits = (p.wHits or 0) + 1
            if p.wHits >= 2 then p.wHits = 0 AC.flag(src, 'weapon', { weapon = weaponName(w), hash = w }) end
        else p.wHits = 0 end
    end
end

CreateThread(function()
    while not AC.ready do Wait(500) end
    local tick = 0
    while true do
        Wait(1000)
        tick = tick + 1
        for _, id in ipairs(GetPlayers()) do
            local src = tonumber(id)
            local ok, err = pcall(sample, src)
            if not ok then AC.debug('sample', err) end
            if tick % 3 == 0 then
                local ok2, err2 = pcall(sampleWeapon, src)
                if not ok2 then AC.debug('weapon', err2) end
            end
        end
    end
end)

-- ─────────────────────────────── Battement de cœur du client ───────────────────────────────
RegisterNetEvent('pickax_anticheat:hb', function(token)
    local src = source
    local p = AC.players[src]
    if not p then return end
    if p.token and token ~= p.token then
        p.badToken = (p.badToken or 0) + 1
        if p.badToken >= 3 then p.badToken = 0 AC.flag(src, 'heartbeat', { reason = 'jeton invalide' }) end
        return
    end
    p.hb = now()
end)

CreateThread(function()
    while not AC.ready do Wait(500) end
    while true do
        Wait(15000)
        local hbm = mod('heartbeat')
        if hbm and hbm.enabled then
            for _, id in ipairs(GetPlayers()) do
                local src = tonumber(id)
                local p = AC.players[src]
                if p and p.token and p.hb and (now() - p.hb) > hbm.timeout * 1000 and (now() - (p.joinedAt or 0)) > (AC.cfg.grace.join * 1000 + 60000) then
                    AC.flag(src, 'heartbeat', { silenceSeconds = math.floor((now() - p.hb) / 1000), timeout = hbm.timeout })
                    p.hb = now() - math.floor(hbm.timeout * 500)   -- laisse une nouvelle chance avant le prochain point
                end
            end
        end
    end
end)

-- ─────────────────────────────── Signalements du client ───────────────────────────────
local CLIENT_KINDS = { damageMod = true, meleeMod = true, invisible = true, spectate = true, vehicleMod = true }
RegisterNetEvent('pickax_anticheat:report', function(kind, value)
    local src = source
    if type(kind) ~= 'string' or not CLIENT_KINDS[kind] then return end
    AC.flag(src, 'clientFlags', { kind = kind, value = type(value) == 'number' and value or tostring(value):sub(1, 40) })
end)

-- ─────────────────────────────── Création d'entités ───────────────────────────────
local function entityCounter(p, kind, windowMs)
    p.ent = p.ent or {}
    local c = p.ent[kind]
    local t = now()
    if not c or t - c.t0 > windowMs then c = { n = 0, t0 = t } p.ent[kind] = c end
    c.n = c.n + 1
    return c.n
end

AddEventHandler('entityCreating', function(entity)
    if not AC.ready or not entity or not DoesEntityExist(entity) then return end
    local owner = NetworkGetEntityOwner(entity)
    if not owner or owner <= 0 or not GetPlayerName(owner) then return end      -- entités créées par le serveur : toujours autorisées
    local etype = GetEntityType(entity)       -- 1 = PNJ, 2 = véhicule, 3 = objet
    if etype ~= 1 and etype ~= 2 and etype ~= 3 then return end
    local model = GetEntityModel(entity) & 0xFFFFFFFF
    local kind = etype == 1 and 'peds' or (etype == 2 and 'vehicles' or 'objects')
    local set = etype == 1 and AC.idx.mped or (etype == 2 and AC.idx.mveh or AC.idx.mobj)

    if enabled('blacklistModels') and set[model] then
        local exempt = AC.isExempt(owner, 'blacklistModels')
        if not exempt then
            CancelEvent()
            AC.flag(owner, 'blacklistModels', { model = set[model], type = kind })
            return
        end
    end
    local em = mod('entities')
    if em and em.enabled and (em[kind] or 0) > 0 then
        local p = AC.players[owner]
        if p and not AC.isExempt(owner, 'entities') then
            local n = entityCounter(p, kind, (em.window or 60) * 1000)
            if n > em[kind] then
                CancelEvent()
                AC.flag(owner, 'entities', { type = kind, count = n, limit = em[kind], windowSeconds = em.window })
            end
        end
    end
end)

-- ─────────────────────────────── Explosions ───────────────────────────────
AddEventHandler('explosionEvent', function(sender, ev)
    if not AC.ready or not enabled('explosions') then return end
    sender = tonumber(sender)
    if not sender or sender <= 0 or not GetPlayerName(sender) then return end
    if AC.isExempt(sender, 'explosions') then return end
    local m = mod('explosions')
    local p = AC.players[sender]
    if not p then return end
    if m.blockInvisible and ev and ev.isInvisible and ev.isAudible == false then
        CancelEvent()
        AC.flag(sender, 'explosions', { type = ev.explosionType, invisible = true, silent = true }, m.weight * 2)
        return
    end
    p.expl = p.expl or { n = 0, t0 = now() }
    if now() - p.expl.t0 > m.window * 1000 then p.expl = { n = 0, t0 = now() } end
    p.expl.n = p.expl.n + 1
    if p.expl.n > m.max then
        CancelEvent()
        AC.flag(sender, 'explosions', { type = ev and ev.explosionType, count = p.expl.n, limit = m.max, windowSeconds = m.window })
    end
end)

-- ─────────────────────────────── Dégâts avec une arme interdite ───────────────────────────────
AddEventHandler('weaponDamageEvent', function(sender, data)
    if not AC.ready or not enabled('weaponBlacklist') then return end
    sender = tonumber(sender)
    if not sender or sender <= 0 or not data or not data.weaponType then return end
    local w = tonumber(data.weaponType) and (tonumber(data.weaponType) & 0xFFFFFFFF)
    if w and AC.idx.bl[w] and not AC.isExempt(sender, 'weaponBlacklist') then
        CancelEvent()
        AC.flag(sender, 'weaponBlacklist', { weapon = AC.idx.bl[w], damageEvent = true })
    end
end)

-- ─────────────────────────────── Événements : honeypots et limites de fréquence ───────────────────────────────
local counters = {}   -- [src..event] = { n, t0 }

local function onHoneypot(name)
    local src = source
    if not src or src <= 0 or not AC.idx.hp[name] or not enabled('honeypots') then return end
    CancelEvent()
    AC.flag(src, 'honeypots', { event = name })
end

local function onLimited(name)
    local src = source
    local l = AC.idx.lim[name]
    if not src or src <= 0 or not l or not enabled('events') then return end
    local key = src .. ':' .. name
    local c = counters[key]
    local t = now()
    if not c or t - c.t0 > l.window * 1000 then c = { n = 0, t0 = t } counters[key] = c end
    c.n = c.n + 1
    if c.n > l.max then
        c.n = 0
        AC.flag(src, 'events', { event = name, limit = l.max, windowSeconds = l.window }, l.weight)
    end
end

function AC.listen()
    for name in pairs(AC.idx.hp) do
        if not AC.handlers['hp:' .. name] then
            AC.handlers['hp:' .. name] = true
            RegisterNetEvent(name)
            AddEventHandler(name, function() onHoneypot(name) end)
        end
    end
    for name in pairs(AC.idx.lim) do
        if not AC.handlers['lim:' .. name] then
            AC.handlers['lim:' .. name] = true
            RegisterNetEvent(name)
            AddEventHandler(name, function() onLimited(name) end)
        end
    end
end

AddEventHandler('playerDropped', function()
    local prefix = tostring(source) .. ':'
    for k in pairs(counters) do if k:sub(1, #prefix) == prefix then counters[k] = nil end end
end)

-- ─────────────────────────────── Contournement de ban (compte lié à un joueur banni) ───────────────────────────────
function AC.checkEvasion(src)
    local ev = AC.cfg.evasion
    if not ev or not ev.enabled then return end
    local ids = AC.identifiers(src)
    local conds, args = {}, {}
    for _, key in ipairs({ 'discord', 'steam', 'fivem', 'live', 'xbl' }) do
        if ev[key] and ids[key] then conds[#conds + 1] = ('a.%s = ?'):format(key) args[#args + 1] = ids[key] end
    end
    if ev.ip and ids.ip then conds[#conds + 1] = 'a.ip = ?' args[#args + 1] = ids.ip end
    if #conds == 0 then return end
    local lic = AC.license(src)
    args[#args + 1] = lic
    args[#args + 1] = os.time()
    local row = MySQL.single.await(('SELECT b.banid, b.reason, b.licenseid FROM banlist b JOIN account_info a ON a.license = b.licenseid WHERE (%s) AND b.licenseid <> ? AND (b.permanent = 1 OR b.expiration > ?) LIMIT 1'):format(table.concat(conds, ' OR ')), args)
    if not row then return end
    local name = AC.name(src)
    local observe = AC.cfg.mode == 'observe'
    AC.log(src, lic, name, 'evasion', observe and 'simulé : kick' or 'kick', 0, { linkedBan = row.banid, linkedLicense = row.licenseid, reason = row.reason })
    AC.webhook('Contournement de ban détecté', ('**%s** (%s)\nCompte lié au ban %s (%s)'):format(name, lic or '?', row.banid, row.licenseid), 15158332)
    if observe then return end
    if ev.autoBan then AC.ban(src, 'Contournement de ban (' .. tostring(row.banid) .. ')', 0, 'Anti-Cheat')
    else AC.kick(src, 'Compte lié à un joueur banni (ban ' .. tostring(row.banid) .. ')') end
end
