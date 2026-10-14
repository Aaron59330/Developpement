-- ─────────────────────────────── Zones PVP (intégration de pickax_pvp) ───────────────────────────────
-- Dans une zone : armes données à l'entrée (retirées à la sortie), revive automatique, kill-feed, récompense par kill, classement.
local playerZone, streaks, deathCd, respawnCd, rewardCd = {}, {}, {}, {}, {}   -- playerZone[src] = { eid, pi }
local statsCache = {}
local lb = { at = -999999, rows = {} }

local weaponSet = {}
for _, w in ipairs(Config.PvpWeapons) do weaponSet[w.name] = true end
WB.pvpWeaponSet = weaponSet

local function useOx() return WB.inventory() == 'ox' end

local function zoneOf(eid, pi)
    local e = WB.Entities[tonumber(eid) or 0]
    local p = e and e.points[tonumber(pi) or 0]
    if not e or e.type ~= 'pvp' or not e.enabled or not p or p.kind ~= 'zone' or not p.coords then return nil end
    return e, p
end

local function zoneName(p) return p.label ~= '' and p.label or 'Zone' end

-- ─────────────────────────────── ox_inventory : armes de zone marquées { pvpzone = clé } ───────────────────────────────
local function oxClear(src)
    if not useOx() then return end
    for _, w in ipairs(Config.PvpWeapons) do
        local ok, slots = pcall(function() return exports.ox_inventory:Search(src, 'slots', w.name) end)
        if ok and type(slots) == 'table' then
            for _, s in ipairs(slots) do
                if s.metadata and s.metadata.pvpzone then pcall(function() exports.ox_inventory:RemoveItem(src, w.name, 1, nil, s.slot) end) end
            end
        end
    end
end

local function oxGive(src, key, p)
    if not useOx() or not p.giveWeapons then return end
    if p.removeOnExit then oxClear(src) end
    local failed = false
    for _, w in ipairs(p.weapons or {}) do
        local ok, exists = pcall(function() return exports.ox_inventory:Items(w.name) end)
        if ok and exists then
            local owned = not p.removeOnExit and (exports.ox_inventory:GetItemCount(src, w.name) or 0) > 0
            if not owned then
                local meta = { ammo = w.ammo }
                if p.removeOnExit then meta.pvpzone = key end
                if not exports.ox_inventory:AddItem(src, w.name, 1, meta) then failed = true end
            end
        else
            print(('[worldbuilder] Arme inconnue dans ox_inventory : %s'):format(w.name))
        end
    end
    if failed then WB.notify(src, 'Inventaire plein : certaines armes de la zone n\'ont pas pu être données.', 'error') end
end

-- ─────────────────────────────── Statistiques ───────────────────────────────
local function nameOf(src)
    local x = ESX.GetPlayerFromId(src)
    return x and WB.playerName(x) or GetPlayerName(src) or ('ID ' .. src)
end

local function getStats(src)
    local x = ESX.GetPlayerFromId(src)
    if not x then return nil end
    local ident = x.identifier
    local s = statsCache[ident]
    if not s then
        local row = MySQL.single.await('SELECT kills, deaths, best_streak FROM worldbuilder_pvp_stats WHERE identifier = ?', { ident })
        s = statsCache[ident]
        if not s then s = row and { kills = row.kills, deaths = row.deaths, best = row.best_streak } or { kills = 0, deaths = 0, best = 0 } statsCache[ident] = s end
    end
    s.name = nameOf(src)
    return s, ident
end

local function flushStats(only)
    for ident, s in pairs(statsCache) do
        if s.dirty and (not only or only == ident) then
            s.dirty = false
            MySQL.query([[INSERT INTO worldbuilder_pvp_stats (identifier, name, kills, deaths, best_streak) VALUES (?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE name = VALUES(name), kills = VALUES(kills), deaths = VALUES(deaths), best_streak = VALUES(best_streak)]], { ident, s.name or '', s.kills, s.deaths, s.best })
        end
    end
end

CreateThread(function() while true do Wait(60000) flushStats() end end)

local function leaderboard()
    if GetGameTimer() - lb.at > 15000 then
        flushStats()
        lb.rows = MySQL.query.await('SELECT name, kills, deaths, best_streak FROM worldbuilder_pvp_stats ORDER BY kills DESC, deaths ASC LIMIT 20') or {}
        lb.at = GetGameTimer()
    end
    return lb.rows
end

local function sendStats(src, s) TriggerClientEvent('worldbuilder:client:pvpStats', src, { kills = s.kills, deaths = s.deaths, streak = streaks[src] or 0 }) end

-- ─────────────────────────────── Menu ───────────────────────────────
ESX.RegisterServerCallback('worldbuilder:pvp:info', function(src, cb, eid, pi)
    local e = WB.Entities[tonumber(eid) or 0]
    local x = ESX.GetPlayerFromId(src)
    local p = e and e.points[tonumber(pi) or 0]
    if not e or e.type ~= 'pvp' or not e.enabled or not x or not p or p.kind ~= 'lobby' or not p.coords or not WB.near(src, p.coords, 6.0) then return cb({ ok = false, error = 'Introuvable' }) end
    local ok, err = WB.hasAccess(x, e.settings.access)
    if not ok then return cb({ ok = false, error = err }) end
    local counts = {}
    for _, z in pairs(playerZone) do if z.eid == e.id then counts[z.pi] = (counts[z.pi] or 0) + 1 end end
    local zones = {}
    for i, z in ipairs(e.points) do
        if z.kind == 'zone' and z.coords then
            local names = {}
            for _, w in ipairs(z.weapons or {}) do names[#names + 1] = w.name:gsub('^WEAPON_', '') end
            zones[#zones + 1] = { pi = i, label = zoneName(z), radius = z.radius, players = counts[i] or 0, reward = z.killReward or 0, weapons = names, revive = z.reviveEnabled, giveWeapons = z.giveWeapons }
        end
    end
    local s = getStats(src)
    cb({ ok = true, eid = e.id, pi = tonumber(pi), label = p.label ~= '' and p.label or e.label, zones = zones,
        stats = s and { kills = s.kills, deaths = s.deaths, best = s.best, streak = streaks[src] or 0 } or { kills = 0, deaths = 0, best = 0, streak = 0 }, leaderboard = leaderboard() })
end)

-- ─────────────────────────────── Entrée / sortie ───────────────────────────────
RegisterNetEvent('worldbuilder:pvp:enter', function(eid, pi)
    local src = source
    local e, p = zoneOf(eid, pi)
    if not e then return end
    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 then
        local c = GetEntityCoords(ped)
        if #(vector3(c.x, c.y, c.z) - vector3(p.coords.x, p.coords.y, p.coords.z)) > (p.radius or 60) + 30.0 then return end
    end
    playerZone[src] = { eid = e.id, pi = tonumber(pi) }
    streaks[src] = 0
    oxGive(src, ('%d:%d'):format(e.id, tonumber(pi)), p)
end)

RegisterNetEvent('worldbuilder:pvp:respawned', function()
    local src = source
    local z = playerZone[src]
    local e, p = zoneOf(z and z.eid, z and z.pi)
    if not e then return end
    local now = GetGameTimer()
    if respawnCd[src] and now - respawnCd[src] < 3000 then return end
    respawnCd[src] = now
    oxGive(src, ('%d:%d'):format(z.eid, z.pi), p)
end)

RegisterNetEvent('worldbuilder:pvp:exit', function()
    local src = source
    local z = playerZone[src]
    local e, p = zoneOf(z and z.eid, z and z.pi)
    playerZone[src], streaks[src] = nil, nil
    if not e or p.removeOnExit then oxClear(src) end
end)

local function zoneBroadcast(z, event, ...)
    for src, o in pairs(playerZone) do
        if o.eid == z.eid and o.pi == z.pi then TriggerClientEvent(event, src, ...) end
    end
end

RegisterNetEvent('worldbuilder:pvp:died', function(killerSrc)
    local src = source
    local z = playerZone[src]
    local e, p = zoneOf(z and z.eid, z and z.pi)
    if not e then return end
    local now = GetGameTimer()
    if deathCd[src] and now - deathCd[src] < 2000 then return end
    deathCd[src] = now
    local victim = getStats(src)
    if victim then victim.deaths = victim.deaths + 1 victim.dirty = true end
    streaks[src] = 0
    killerSrc = tonumber(killerSrc)
    local victimName = nameOf(src)
    local ko = killerSrc and playerZone[killerSrc]
    if killerSrc and killerSrc ~= src and ko and ko.eid == z.eid and ko.pi == z.pi and GetPlayerName(killerSrc) then
        local killer = getStats(killerSrc)
        streaks[killerSrc] = (streaks[killerSrc] or 0) + 1
        if killer then
            killer.kills = killer.kills + 1
            if streaks[killerSrc] > killer.best then killer.best = streaks[killerSrc] end
            killer.dirty = true
        end
        -- anti-abus (kill déclaré par le client) : récompense seulement si le tueur est près de la victime et pas plus d'une fois / 6 s par victime
        local vp, kp = GetPlayerPed(src), GetPlayerPed(killerSrc)
        local near = vp and kp and vp ~= 0 and kp ~= 0 and #(GetEntityCoords(vp) - GetEntityCoords(kp)) <= 300.0
        if (p.killReward or 0) > 0 and near and (not rewardCd[src] or now - rewardCd[src] >= 6000) then
            rewardCd[src] = now
            local xk = ESX.GetPlayerFromId(killerSrc)
            if xk then xk.addAccountMoney((Config.Payments[e.settings.rewardAccount] or Config.Payments.bank).account, p.killReward) end
        end
        TriggerClientEvent('worldbuilder:client:pvpKilled', killerSrc, { heal = p.healOnKill, reward = p.killReward, streak = streaks[killerSrc] })
        zoneBroadcast(z, 'worldbuilder:client:pvpFeed', { killer = nameOf(killerSrc), victim = victimName })
        if killer then sendStats(killerSrc, killer) end
        WB.stat(e, 'kills', 1)
    else
        zoneBroadcast(z, 'worldbuilder:client:pvpFeed', { victim = victimName })
    end
    if victim then sendStats(src, victim) end
end)

-- ─────────────────────────────── Nettoyage ───────────────────────────────
AddEventHandler('playerDropped', function()
    local src = source
    local x = ESX.GetPlayerFromId(src)
    if playerZone[src] then oxClear(src) end
    playerZone[src], streaks[src], deathCd[src], respawnCd[src], rewardCd[src] = nil, nil, nil, nil, nil
    if x then flushStats(x.identifier) end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    flushStats()
    for src in pairs(playerZone) do oxClear(src) end
end)

AddEventHandler('esx:playerLoaded', function(src) SetTimeout(5000, function() oxClear(src) end) end)

-- Zone supprimée / désactivée : on libère les joueurs qui s'y trouvaient
local prevChanged = WB.onEntityChanged
function WB.onEntityChanged(e, deleted)
    if prevChanged then prevChanged(e, deleted) end
    if e.type ~= 'pvp' then return end
    for src, z in pairs(playerZone) do
        if z.eid == e.id then
            local _, p = zoneOf(z.eid, z.pi)
            if deleted or not e.enabled or not p then playerZone[src], streaks[src] = nil, nil oxClear(src) end
        end
    end
end
