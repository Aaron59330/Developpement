local R = { run = nil, ents = {}, blips = {}, vehicle = nil }

local function nui(a, d) d = d or {}; d.action = a; SendNUIMessage(d) end
local function toast(t, typ) lib.notify({ title = 'Braquage', description = t, type = typ or 'inform' }) end

local function loadModel(m)
    if not IsModelInCdimage(m) then return false end
    RequestModel(m); local t = GetGameTimer() + 8000
    while not HasModelLoaded(m) and GetGameTimer() < t do Wait(20) end
    return HasModelLoaded(m)
end

local function track(e) R.ents[#R.ents + 1] = e; return e end
local function blipFor(coords, sprite, color, label, route)
    local b = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(b, sprite or 1); SetBlipColour(b, color or 5); SetBlipScale(b, 0.9)
    if route then SetBlipRoute(b, true); SetBlipRouteColour(b, color or 5) end
    BeginTextCommandSetBlipName('STRING'); AddTextComponentString(label or 'Objectif'); EndTextCommandSetBlipName(b)
    R.blips[#R.blips + 1] = b; return b
end
local function clearBlips() for _, b in ipairs(R.blips) do if DoesBlipExist(b) then RemoveBlip(b) end end; R.blips = {} end

local function cleanup(deleteVeh)
    clearBlips()
    for _, e in ipairs(R.ents) do
        if DoesEntityExist(e) then
            if IsEntityAVehicle(e) and not deleteVeh then SetEntityAsNoLongerNeeded(e) else DeleteEntity(e) end
        end
    end
    R.ents = {}; R.vehicle = nil
end

local function marker(c, r, col)
    DrawMarker(1, c.x, c.y, c.z - 0.95, 0, 0, 0, 0, 0, 0, r * 2.0, r * 2.0, 1.0, 10, 132, 255, 90, false, false, 2, false)
end

local function dist(c, flat)
    local p = GetEntityCoords(PlayerPedId())
    if flat then return #(vec2(p.x, p.y) - vec2(c.x, c.y)) end
    return #(p - c)
end

local function enemyGroup()
    local _, g = AddRelationshipGroup(Config.Enemy.relationGroup)
    SetRelationshipBetweenGroups(5, g, `PLAYER`); SetRelationshipBetweenGroups(5, `PLAYER`, g)
    return g
end

local function spawnEnemy(c, radius, diff, ground)
    local model = `s_m_y_blackops_01`
    if not loadModel(model) then return end
    local a, r = math.random() * 6.283, math.random() * radius
    local x, y, z = c.x + math.cos(a) * r, c.y + math.sin(a) * r, c.z
    if ground ~= false then
        local ok, gz = GetGroundZFor_3dCoord(x, y, c.z + 30.0, false)
        if ok then z = gz end
    end
    local ped = CreatePed(4, model, x, y, z, math.random(0, 359) + 0.0, true, true)
    SetPedRelationshipGroupHash(ped, enemyGroup())
    SetEntityMaxHealth(ped, diff.enemyHealth); SetEntityHealth(ped, diff.enemyHealth)
    SetPedAccuracy(ped, diff.enemyAccuracy); SetPedCombatAttributes(ped, 46, true); SetPedCombatAbility(ped, 2)
    SetPedAlertness(ped, 3); SetBlockingOfNonTemporaryEvents(ped, true)
    local ws = Config.Enemy.weapons; GiveWeaponToPed(ped, ws[math.random(#ws)], 250, false, true)
    TaskCombatPed(ped, PlayerPedId(), 0, 16)
    track(ped); return ped
end

local function stillRunning(id) return R.run and R.run.id == id end

-- ───────────── gestionnaires d'étapes (retournent true quand l'étape est réussie) ─────────────
local H = {}

H['goto'] = function(s, id)
    blipFor(s.coords, 1, 5, s.label, true)
    while stillRunning(id) do
        marker(s.coords, math.min(s.radius, 6.0))
        local air = s.coords.z > 60.0
        if dist(s.coords, not air) <= s.radius then return true end
        Wait(0)
    end
end

function H.kill(s, id)
    local diff = Config.Difficulty[R.run.diff] or Config.Difficulty.normal
    local crew = math.max(R.run.crew, 1)
    local mine = math.max(1, math.ceil(s.count / crew))
    local peds, bl = {}, blipFor(s.coords, 84, 1, s.label, false); SetBlipFlashes(bl, true)
    while stillRunning(id) and #peds < mine do
        if s.air then
            local m = `buzzard`
            if loadModel(m) and loadModel(`s_m_y_blackops_01`) then
                local c = s.coords + vec3(math.random(-250, 250), math.random(-250, 250), math.random(0, 30))
                local v = CreateVehicle(m, c.x, c.y, c.z, 0.0, true, true); track(v)
                local pilot = CreatePedInsideVehicle(v, 4, `s_m_y_blackops_01`, -1, true, true); track(pilot)
                SetPedRelationshipGroupHash(pilot, enemyGroup()); SetEntityHealth(pilot, 200)
                local gun = CreatePedInsideVehicle(v, 4, `s_m_y_blackops_01`, 1, true, true); track(gun)
                SetPedRelationshipGroupHash(gun, enemyGroup()); GiveWeaponToPed(gun, `WEAPON_MICROSMG`, 500, false, true); SetPedAccuracy(gun, diff.enemyAccuracy)
                SetEntityMaxHealth(v, 1500 * 1); SetEntityHealth(v, 1500)
                SetHeliBladesFullSpeed(v); TaskHeliChase(pilot, PlayerPedId(), 0.0, 0.0, 40.0)
                peds[#peds + 1] = v
            else break end
        else
            local p = spawnEnemy(s.coords, s.radius, diff); if p then peds[#peds + 1] = p end
        end
        Wait(150)
    end
    while stillRunning(id) do
        local alive = 0
        for _, e in ipairs(peds) do
            if DoesEntityExist(e) then
                if IsEntityAVehicle(e) then if not IsEntityDead(e) and GetEntityHealth(e) > 0 then alive = alive + 1 end
                elseif not IsPedDeadOrDying(e, true) then alive = alive + 1 end
            end
        end
        nui('hudSub', { text = ('%d / %d restants'):format(alive, #peds) })
        if alive == 0 then nui('hudSub', { text = '' }); return true end
        Wait(500)
    end
end

function H.vehicle(s, id)
    if not loadModel(s.model) then toast('Modèle indisponible : ' .. tostring(s.model), 'error'); return false end
    local v = CreateVehicle(s.model, s.spawn.x, s.spawn.y, s.spawn.z, s.spawn.w, true, true); track(v)
    SetVehicleOnGroundProperly(v); SetVehicleEngineOn(v, false, true, false); SetVehicleDoorsLocked(v, 1)
    R.vehicle = v
    blipFor(s.spawn.xyz, 225, 5, s.label, true)
    if s.guards and s.guards > 0 then
        local diff = Config.Difficulty[R.run.diff] or Config.Difficulty.normal
        for _ = 1, s.guards do spawnEnemy(s.spawn.xyz, 14.0, diff) end
    end
    while stillRunning(id) do
        if IsPedInVehicle(PlayerPedId(), v, false) then clearBlips(); return true end
        if not DoesEntityExist(v) or IsEntityDead(v) then toast('Le véhicule a été détruit.', 'error'); TriggerServerEvent('pkh:abort', 'wiped'); return false end
        Wait(300)
    end
end

function H.deliver(s, id)
    blipFor(s.coords, 1, 2, s.label, true)
    while stillRunning(id) do
        marker(s.coords, math.min(s.radius, 6.0))
        local ok = dist(s.coords, s.coords.z < 60.0) <= s.radius
        if ok and s.vehicle and not (R.vehicle and IsPedInVehicle(PlayerPedId(), R.vehicle, false)) then ok = false end
        if ok then
            if s.vehicle and R.vehicle and not R.run.mission.finale then
                local v = R.vehicle; TaskLeaveVehicle(PlayerPedId(), v, 0); Wait(1500)
                SetEntityAsMissionEntity(v, true, true); DeleteEntity(v); R.vehicle = nil
            end
            return true
        end
        Wait(0)
    end
end

local function holdAction(s, id, anim)
    blipFor(s.coords, 1, 5, s.label, true)
    while stillRunning(id) do
        marker(s.coords, 1.4)
        if dist(s.coords) <= 2.0 then
            lib.showTextUI('[E] ' .. (s.text or 'Interagir'))
            if IsControlJustReleased(0, Config.Keys.interact) then
                lib.hideTextUI()
                local ok = lib.progressBar({ duration = s.duration or 4000, label = s.text or 'Interaction…', useWhileDead = false, canCancel = true, disable = { move = true, car = true, combat = true },
                    anim = anim })
                if ok then return true end
            end
        else lib.hideTextUI() end
        Wait(0)
    end
    lib.hideTextUI()
end

function H.interact(s, id) return holdAction(s, id, { dict = 'anim@heists@prison_heiststation@cop_reactions', clip = 'cop_b_idle' }) end

function H.photo(s, id)
    s.text = s.text or 'Prendre la photo (Snapmatic)'; s.duration = 1800
    blipFor(s.coords, 1, 5, s.label, true)
    while stillRunning(id) do
        if dist(s.coords) <= s.radius then
            lib.showTextUI('[E] ' .. s.text)
            if IsControlJustReleased(0, Config.Keys.interact) then
                lib.hideTextUI()
                local ok = lib.progressBar({ duration = 1800, label = 'Photo en cours…', canCancel = false, anim = { scenario = 'WORLD_HUMAN_TOURIST_MOBILE' } })
                if ok then PlaySoundFrontend(-1, 'Camera_Shoot', 'Phone_SoundSet_Michael', true); return true end
            end
        else lib.hideTextUI() end
        Wait(0)
    end
    lib.hideTextUI()
end

function H.cutscene(s, id)
    DoScreenFadeOut(800); Wait(900)
    nui('hudSub', { text = s.label }); Wait(s.duration or 4000)
    DoScreenFadeIn(800); nui('hudSub', { text = '' }); return true
end

-- ───────────── pilotage d'une mission ─────────────
local function runSteps(def, steps, id)
    for i, s in ipairs(steps) do
        if not stillRunning(id) then return false end
        R.run.step = i
        nui('hud', { show = true, mission = def.label, team = R.run.teamLabel, step = i, total = #steps, label = s.label, t0 = R.run.t0 })
        local fn = H[s.type]
        local ok = fn and fn(s, id)
        clearBlips()
        if not stillRunning(id) then return false end
        if not ok then return false end
        PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
    end
    return true
end

RegisterNetEvent('pkh:begin', function(d)
    if R.run then return end
    local heist = Heists[d.heist]; local def
    for _, m in ipairs(heist.missions) do if m.id == d.mission then def = m end end
    if not def then return end
    local id = GetGameTimer()
    R.run = { id = id, mission = def, diff = d.diff, crew = d.crew, t0 = GetGameTimer(), team = d.team }
    local steps = def.steps
    if def.teams then local t = def.teams[d.team]; steps = t.steps; R.run.teamLabel = t.label end
    toast(def.label .. (R.run.teamLabel and (' — ' .. R.run.teamLabel) or ''), 'inform')
    nui('briefing', { title = def.label, text = def.brief, team = R.run.teamLabel })
    CreateThread(function()
        if runSteps(def, steps, id) then
            R.run.finished = true
            TriggerServerEvent('pkh:teamDone')
            toast('Votre part est terminée.', 'success')
        end
    end)
end)

RegisterNetEvent('pkh:end', function(reason)
    local fin = R.run and R.run.mission and R.run.mission.finale
    R.run = nil; lib.hideTextUI(); cleanup(reason ~= 'finale' and reason ~= 'success')
    nui('hud', { show = false })
    local txt = ({ success = 'Mission réussie', finale = 'Braquage réussi', abort = 'Mission annulée', wiped = 'Équipe éliminée — mission échouée', fail = 'Mission échouée' })[reason] or 'Mission terminée'
    nui('result', { text = txt, ok = reason == 'success' or reason == 'finale' })
end)

AddEventHandler('esx:onPlayerDeath', function() if R.run then TriggerServerEvent('pkh:death') end end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then cleanup(true); lib.hideTextUI() end end)
