-- ─────────────────────────────── Zones PVP (client) ───────────────────────────────
local zones = {}               -- [clé "eid:pi"] = zone
local current = nil            -- clé de la zone où l'on se trouve
local savedWeapons = nil
local respawning = false
local pvpBlips = {}
local stats = { kills = 0, deaths = 0, streak = 0 }

local function useOx()
    if Config.Inventory == 'ox' then return true end
    if Config.Inventory == 'esx' then return false end
    return GetResourceState('ox_inventory') == 'started'
end

local function send(action, data) data = data or {} data.action = action SendNUIMessage(data) end

local PALETTE = { { 34, 197, 94, 2 }, { 239, 68, 68, 1 }, { 59, 130, 246, 3 }, { 251, 191, 36, 5 }, { 251, 146, 60, 17 }, { 168, 85, 247, 27 } }
local function blipColour(c)
    local best, bd = 2, 1e9
    for _, p in ipairs(PALETTE) do
        local d = (p[1] - c[1]) ^ 2 + (p[2] - c[2]) ^ 2 + (p[3] - c[3]) ^ 2
        if d < bd then best, bd = p[4], d end
    end
    return best
end

-- ─────────────────────────────── Zones (depuis la synchronisation) ───────────────────────────────
local function clearBlips()
    for _, b in pairs(pvpBlips) do if DoesBlipExist(b) then RemoveBlip(b) end end
    pvpBlips = {}
end

local prevSynced = OnSynced
function OnSynced()
    if prevSynced then prevSynced() end
    zones = {}
    clearBlips()
    for _, e in ipairs(State.entities) do
        if e.type == 'pvp' then
            for _, p in ipairs(e.points) do
                if p.kind == 'zone' and p.zone then
                    local z = p.zone
                    local key = ('%d:%d'):format(e.id, p.i)
                    local col = p.color or e.color or { 34, 197, 94 }
                    zones[key] = { key = key, eid = e.id, pi = p.i, name = p.label ~= '' and p.label or 'Zone', center = vector3(p.coords.x, p.coords.y, p.coords.z), radius = (z.radius or 60) + 0.0, color = col, z = z }
                    local r = AddBlipForRadius(p.coords.x, p.coords.y, p.coords.z, (z.radius or 60) + 0.0)
                    SetBlipColour(r, blipColour(col)) SetBlipAlpha(r, 90)
                    pvpBlips[#pvpBlips + 1] = r
                end
            end
        end
    end
end

-- ─────────────────────────────── Armes (mode natif) ───────────────────────────────
local function saveWeapons()
    local ped, list = PlayerPedId(), {}
    for _, w in ipairs(Config.PvpWeapons) do
        local hash = joaat(w.name)
        if HasPedGotWeapon(ped, hash, false) then list[#list + 1] = { hash = hash, ammo = GetAmmoInPedWeapon(ped, hash) } end
    end
    return list
end

local function giveLoadout(z)
    local ped = PlayerPedId()
    for i, w in ipairs(z.z.weapons or {}) do GiveWeaponToPed(ped, joaat(w.name), w.ammo, false, i == 1) end
    SetPedInfiniteAmmoClip(ped, z.z.infiniteAmmo == true)
end

local function restoreWeapons()
    if not savedWeapons then return end
    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped, true)
    for _, w in ipairs(savedWeapons) do GiveWeaponToPed(ped, w.hash, w.ammo, false, false) end
    savedWeapons = nil
end

-- ─────────────────────────────── Entrée / sortie ───────────────────────────────
local function setState(v)
    LocalPlayer.state:set('inPvpZone', v, true)
    TriggerEvent(v and 'worldbuilder:pvp:entered' or 'worldbuilder:pvp:left')     -- pour les scripts de mort / ambulance qui écoutent
end

-- Export : exports.worldbuilder:IsInPvpZone() → true dans une zone PVP (à tester dans ton script de mort / ambulance)
exports('IsInPvpZone', function() return current ~= nil end)

local function enterZone(z)
    current = z.key
    setState(true)
    TriggerServerEvent('worldbuilder:pvp:enter', z.eid, z.pi)
    if z.z.giveWeapons and not useOx() then
        if z.z.removeOnExit then savedWeapons = saveWeapons() RemoveAllPedWeapons(PlayerPedId(), true) end
        giveLoadout(z)
    end
    local c = z.color
    send('pvpHud', { show = true, zone = z.name, color = ('rgb(%d,%d,%d)'):format(c[1], c[2], c[3]), stats = stats })
    Notify(('Tu entres dans la zone PVP « %s »'):format(z.name), 'success')
end

local function leaveZone(silent)
    if not current then return end
    current = nil
    setState(false)
    TriggerServerEvent('worldbuilder:pvp:exit')
    SetPedInfiniteAmmoClip(PlayerPedId(), false)
    restoreWeapons()
    send('pvpRespawn', { show = false })
    send('pvpHud', { show = false })
    if not silent then Notify('Tu as quitté la zone PVP', 'info') end
end

CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        if current then
            sleep = 250
            if LocalPlayer.state.inPvpZone ~= true then setState(true) end
            local z = zones[current]
            if not z then leaveZone()
            elseif not respawning and not IsEntityDead(ped) and #(pos - z.center) > z.radius + 1.0 then leaveZone() end
            if z and z.z.infiniteAmmo then SetPedInfiniteAmmoClip(ped, true) end
        elseif not IsEntityDead(ped) and not Busy then
            for _, z in pairs(zones) do
                if #(pos - z.center) <= z.radius then enterZone(z) break end
            end
        end
        Wait(sleep)
    end
end)

-- ─────────────────────────────── Murs de zone ───────────────────────────────
local W = Config.Pvp.Wall
W.segments = math.max(8, math.min(36, math.floor(W.segments or 24)))      -- plafond : trop d'appels de dessin par image fait planter GTA (Pool Full 256)
local cosT, sinT = {}, {}
for i = 0, W.segments do local a = (i / W.segments) * math.pi * 2.0 cosT[i], sinT[i] = math.cos(a), math.sin(a) end

local function drawWall(p, radius, col, alpha)
    local r, g, b = col[1], col[2], col[3]
    local z0, z1 = p.z - 1.5, p.z + W.height
    for i = 0, W.segments - 1 do
        local x1, y1 = p.x + cosT[i] * radius, p.y + sinT[i] * radius
        local x2, y2 = p.x + cosT[i + 1] * radius, p.y + sinT[i + 1] * radius
        DrawPoly(x1, y1, z0, x2, y2, z0, x2, y2, z1, r, g, b, alpha)
        DrawPoly(x2, y2, z1, x2, y2, z0, x1, y1, z0, r, g, b, alpha)
        DrawPoly(x2, y2, z1, x1, y1, z1, x1, y1, z0, r, g, b, alpha)
        DrawPoly(x1, y1, z0, x1, y1, z1, x2, y2, z1, r, g, b, alpha)
        DrawLine(x1, y1, z0 + 0.1, x2, y2, z0 + 0.1, r, g, b, 255)
    end
end

CreateThread(function()
    while true do
        local sleep = 500
        local pos = GetEntityCoords(PlayerPedId())
        -- une seule zone dessinée à la fois (la plus proche) : limite le nombre d'appels de dessin par image
        local best, bd = nil, W.drawDistance
        for _, z in pairs(zones) do
            local d = math.abs(#(pos - z.center) - z.radius)
            if d <= bd then best, bd = z, d end
        end
        if best then sleep = 0 drawWall(best.center, best.radius, best.color, W.alpha) end
        Wait(sleep)
    end
end)

-- ─────────────────────────────── Mort & revive ───────────────────────────────
-- Cherche le sol sous un point (le temps que la collision se charge) ; nil si introuvable
local function findGround(x, y, z)
    RequestCollisionAtCoord(x, y, z)
    local t = GetGameTimer()
    while GetGameTimer() - t < 3000 do
        local found, gz = GetGroundZFor_3dCoord(x, y, z + 50.0, false)
        if found then return gz end
        Wait(50)
    end
    return nil
end

-- Sans point de réapparition défini : près du CENTRE de la zone (là où elle a été placée, donc au sol), au même niveau que le centre.
-- On évite les toits / sous-sols : le sol trouvé doit être à moins de 4 m en hauteur du centre ; sinon on réapparaît exactement au centre.
local function pickSpawn(z)
    local sp = z.z.spawns
    if sp and #sp > 0 then local s = sp[math.random(#sp)] return s.x, s.y, s.z, s.h or 0.0 end
    local c = z.center
    local reach = math.min(z.radius * 0.5, 25.0)
    for _ = 1, 6 do
        local angle = math.random() * math.pi * 2.0
        local dist = reach * (0.2 + 0.8 * math.sqrt(math.random()))
        local x, y = c.x + math.cos(angle) * dist, c.y + math.sin(angle) * dist
        RequestCollisionAtCoord(x, y, c.z)
        local t = GetGameTimer()
        while GetGameTimer() - t < 600 do
            local found, gz = GetGroundZFor_3dCoord(x, y, c.z + 3.0, false)
            if found then
                if math.abs(gz - c.z) <= 4.0 then return x, y, gz + 0.3, math.random() * 360.0 end
                break
            end
            Wait(50)
        end
    end
    return c.x, c.y, c.z + 0.3, math.random() * 360.0
end

local function respawn(z)
    local x, y, zz, h = pickSpawn(z)
    DoScreenFadeOut(300)
    while not IsScreenFadedOut() do Wait(10) end
    RequestCollisionAtCoord(x, y, zz)
    NetworkResurrectLocalPlayer(x, y, zz, h, true, false)
    local ped = PlayerPedId()
    -- on retient le joueur tant que le sol n'est pas chargé : sinon il tombe sous la carte
    FreezeEntityPosition(ped, true)
    local t = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() - t < 4000 do
        RequestCollisionAtCoord(x, y, zz)
        Wait(50)
    end
    local gz = findGround(x, y, zz)
    if gz and zz < gz - 0.5 then zz = gz + 0.3 end            -- point enterré sous le sol : on remonte
    if not gz and zz < z.center.z - 30.0 then zz = z.center.z end
    SetEntityCoordsNoOffset(ped, x, y, zz, false, false, false)
    SetEntityHeading(ped, h)
    FreezeEntityPosition(ped, false)
    ClearPedTasksImmediately(ped) ClearPedBloodDamage(ped)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    if z.z.armorOnRespawn then SetPedArmour(ped, 100) end
    if z.z.giveWeapons and not useOx() then
        if z.z.removeOnExit then RemoveAllPedWeapons(ped, true) end
        giveLoadout(z)
    end
    if useOx() then TriggerServerEvent('worldbuilder:pvp:respawned') end
    if (z.z.spawnProtection or 0) > 0 then
        SetEntityInvincible(ped, true)
        CreateThread(function() Wait(z.z.spawnProtection * 1000) SetEntityInvincible(PlayerPedId(), false) end)
    end
    for _, ev in ipairs(Config.Pvp.ReviveEvents) do TriggerEvent(ev) end
    DoScreenFadeIn(400)
end

local function handleDeath()
    respawning = true
    local ped = PlayerPedId()
    local z = zones[current]
    local killerSrc
    local killer = GetPedSourceOfDeath(ped)
    if killer and killer ~= 0 and killer ~= ped then
        if IsEntityAVehicle(killer) then killer = GetPedInVehicleSeat(killer, -1) end
        if killer ~= 0 and IsPedAPlayer(killer) then
            local idx = NetworkGetPlayerIndexFromPed(killer)
            if idx and idx ~= -1 then killerSrc = GetPlayerServerId(idx) end
        end
    end
    TriggerServerEvent('worldbuilder:pvp:died', killerSrc)
    if not z or not z.z.reviveEnabled then
        while IsEntityDead(PlayerPedId()) do Wait(500) end
        respawning = false
        return
    end
    for s = (z.z.reviveDelay or 5), 1, -1 do
        send('pvpRespawn', { show = true, seconds = s })
        Wait(1000)
        if not current then break end
    end
    send('pvpRespawn', { show = false })
    z = zones[current] or z
    if current then respawn(z)
    else
        local p = GetEntityCoords(PlayerPedId())
        NetworkResurrectLocalPlayer(p.x, p.y, p.z, GetEntityHeading(PlayerPedId()), true, false)
        SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))
        for _, ev in ipairs(Config.Pvp.ReviveEvents) do TriggerEvent(ev) end
    end
    respawning = false
end

CreateThread(function()
    while true do
        Wait(current and 100 or 500)
        if current and not respawning and IsEntityDead(PlayerPedId()) then handleDeath() end
    end
end)

-- ─────────────────────────────── Évènements serveur ───────────────────────────────
RegisterNetEvent('worldbuilder:client:pvpFeed', function(entry) send('pvpFeed', { entry = entry }) end)
RegisterNetEvent('worldbuilder:client:pvpStats', function(s) stats = s send('pvpStats', { stats = s }) end)
RegisterNetEvent('worldbuilder:client:pvpKilled', function(info)
    if info.heal then local ped = PlayerPedId() SetEntityHealth(ped, GetEntityMaxHealth(ped)) end
    local msg = ('Kill ! Série : %d'):format(info.streak or 1)
    if info.reward and info.reward > 0 then msg = msg .. (' (+%d%s)'):format(info.reward, Config.Currency) end
    Notify(msg, 'success')
end)

-- ox_inventory : seules les armes de la zone sont utilisables (si « retrait à la sortie » est actif)
CreateThread(function()
    while true do
        Wait(500)
        local z = current and zones[current]
        if z and z.z.giveWeapons and z.z.removeOnExit and not respawning and useOx() then
            local ok, cw = pcall(function() return exports.ox_inventory:getCurrentWeapon() end)
            if ok and cw and not (cw.metadata and cw.metadata.pvpzone) then
                TriggerEvent('ox_inventory:disarm', true)
                Notify('Seules les armes de la zone sont autorisées', 'error')
            end
        end
    end
end)

-- ─────────────────────────────── Menu (PNJ) ───────────────────────────────
Handlers.pvp = function(node)
    if node.kind ~= 'lobby' then return end
    ServerCall('worldbuilder:pvp:info', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Indisponible', 'error') end
        stats = { kills = res.stats.kills, deaths = res.stats.deaths, streak = res.stats.streak }
        OpenPanel('pvp', res, { type = 'pvp', eid = node.eid, pi = node.pi })
    end, node.eid, node.pi)
end

NuiLocal['pvp:waypoint'] = function(args, cb)
    local ctx = Ctx
    local p = ctx and PointOf(ctx.eid, tonumber(args[1]) or 0)
    if p then SetNewWaypoint(p.coords.x + 0.0, p.coords.y + 0.0) Notify('Point GPS placé sur la zone.', 'success') end
    cb({ ok = p ~= nil })
end

local prevStop = OnStop
function OnStop()
    if prevStop then prevStop() end
    clearBlips()
    if current then setState(false) SetPedInfiniteAmmoClip(PlayerPedId(), false) SetEntityInvincible(PlayerPedId(), false) restoreWeapons() end
end

-- Diagnostic : /wbpvp affiche l'état et les systèmes de mort détectés (console F8)
RegisterCommand('wbpvp', function()
    local found = {}
    for _, r in ipairs({ 'esx_ambulancejob', 'jobbuilder', 'wasabi_ambulance', 'ars_ambulancejob', 'osp_ambulance', 'qb-ambulancejob', 'visn_are', 'p_ambulancejob' }) do
        if GetResourceState(r) == 'started' then found[#found + 1] = r end
    end
    print(('[worldbuilder] zone=%s inPvpZone=%s mort=%s réapparition=%s | systèmes de mort actifs : %s'):format(tostring(current), tostring(LocalPlayer.state.inPvpZone), tostring(IsEntityDead(PlayerPedId())), tostring(respawning), #found > 0 and table.concat(found, ', ') or 'aucun détecté'))
    Notify(('PVP : zone=%s — systèmes de mort : %s (détails en F8)'):format(tostring(current), #found > 0 and table.concat(found, ', ') or 'aucun'), 'info')
end, false)
