-- ─────────────────────────────── Mort, appel des EMS, réanimation (client) ───────────────────────────────
for _, n in ipairs({ 'ems:list', 'ems:take', 'ems:close' }) do NuiRemote[n] = true end

local dead, since = false, 0
local restoreNeeds              -- défini plus bas
local lastRevive = 0          -- instant de la dernière réanimation (diagnostic)
local oxygenReset = false     -- demande de remise à plein de la réserve d'air (après une réanimation)
local state = { left = 0, called = false, units = 0, ems = 0, cooldown = 0 }
local hold, deadTick = 0.0, 0

local function active()
    local m = Config.Death.Mode
    if m == 'on' then return true elseif m == 'off' then return false end
    return GetResourceState('esx_ambulancejob') ~= 'started'
end

local function hideUI() SendNUIMessage({ action = 'deathHide' }) end

-- ── Blocage : un autre script (gunfight…) gère la mort → le système du builder reste inactif ──
local blockedByScript = false
AddEventHandler('jobbuilder:death:block', function(on) blockedByScript = on and true or false end)
exports('SetDeathBlocked', function(on) blockedByScript = on and true or false end)

local function blocked()
    if blockedByScript then return true end
    local B = Config.DeathBlock or {}
    for _, e in ipairs(B.Exports or {}) do
        if GetResourceState(e[1]) == 'started' then
            local ok, r = pcall(function() return exports[e[1]][e[2]]() end)
            if ok and r then return true end
        end
    end
    local st = LocalPlayer.state
    for _, k in ipairs(B.StateBags or {}) do if st[k] then return true end end
    if B.Zones and #B.Zones > 0 then
        local p = GetEntityCoords(PlayerPedId())
        for _, z in ipairs(B.Zones) do
            if #(p - vector3(z[1] + 0.0, z[2] + 0.0, z[3] + 0.0)) <= (z[4] or 100.0) then return true end
        end
    end
    return false
end

-- Relève le joueur (sur place ou à des coordonnées) avec un pourcentage de vie.
-- Précautions : si le joueur est mort sous l'eau on le place en SURFACE, on attend que la résurrection soit effective (sinon la détection de mort le
-- considère encore mort), on lui rend de l'air et on le protège plusieurs secondes.
local graceUntil = 0

-- Animation de réveil : le joueur se tord au sol quelques secondes puis se relève (commandes bloquées pendant ce temps)
local function loadDict(d)
    RequestAnimDict(d)
    local t = 0
    while not HasAnimDictLoaded(d) and t < 100 do Wait(20) t = t + 1 end
    return HasAnimDictLoaded(d)
end

local function reviveAnimation()
    CreateThread(function()
        local ped = PlayerPedId()
        if IsEntityInWater(ped) or IsPedSwimming(ped) then return end     -- dans l'eau : pas d'animation (le joueur doit pouvoir nager tout de suite)
        local lie, up = 'combat@damage@writhe', 'get_up@directional@movement@from_knees@action'
        if not (loadDict(lie) and loadDict(up)) then return end
        ShakeGameplayCam('DRUNK_SHAKE', 0.25)
        local untilT = GetGameTimer() + 4300
        TaskPlayAnim(ped, lie, 'writhe_loop', 8.0, -8.0, 2000, 1, 0.0, false, false, false)
        local phase = 1
        while GetGameTimer() < untilT do
            Wait(0)
            DisableControlAction(0, 21, true) DisableControlAction(0, 22, true) DisableControlAction(0, 30, true) DisableControlAction(0, 31, true)
            DisableControlAction(0, 24, true) DisableControlAction(0, 25, true) DisableControlAction(0, 23, true) DisableControlAction(0, 44, true)
            if phase == 1 and GetGameTimer() > untilT - 2300 then
                phase = 2
                ped = PlayerPedId()
                TaskPlayAnim(ped, up, 'getup_r_0', 8.0, -8.0, 2300, 0, 0.0, false, false, false)
            end
            if IsEntityDead(PlayerPedId()) then break end
        end
        StopGameplayCamShaking(true)
        RemoveAnimDict(lie)
        RemoveAnimDict(up)
    end)
end

-- Hauteur de la surface de l'eau au-dessus d'un point (nil si pas d'eau)
local function surfaceZ(x, y, z)
    local ok, h = GetWaterHeight(x, y, z)
    if ok then return h end
    ok, h = GetWaterHeightNoWaves(x, y, z)
    if ok then return h end
    ok, h = TestVerticalProbeAgainstAllWater(x, y, z + 30.0, 0)
    if ok then return h end
end

-- Résurrection avec protections APPLIQUÉES TOUT DE SUITE (invincibilité + air) : sous l'eau, le joueur mourait de nouveau dès la résurrection,
-- avant même que les protections ne soient posées. Plusieurs essais, puis repli à l'hôpital le plus proche.
local function resurrect(c, hp)
    for attempt = 1, 3 do
        NetworkResurrectLocalPlayer(c.x + 0.0, c.y + 0.0, c.z + (attempt - 1) * 1.5 + 0.0, (c.h or 0.0) + 0.0, true, false)
        for _ = 1, 40 do
            local ped = PlayerPedId()
            SetPlayerInvincible(PlayerId(), true)
            SetEntityInvincible(ped, true)
            SetPlayerUnderwaterTimeRemaining(PlayerId(), 40.0)
            if not IsEntityDead(ped) then
                SetEntityHealth(ped, hp)
                return true
            end
            SetEntityHealth(ped, hp)
            Wait(0)
        end
    end
    return false
end

-- Point sec le plus proche (rivage) autour d'un point en pleine eau : recherche en anneaux croissants (jusqu'à ~300 m), collisions chargées à chaque anneau
local function nearestShore(x, y, z)
    for r = 10.0, 300.0, 10.0 do
        local steps = math.max(8, math.floor(r / 4))
        for i = 0, steps - 1 do
            local a = (i / steps) * math.pi * 2
            RequestCollisionAtCoord(x + math.cos(a) * r, y + math.sin(a) * r, z)
        end
        Wait(60)
        for i = 0, steps - 1 do
            local a = (i / steps) * math.pi * 2
            local px, py = x + math.cos(a) * r, y + math.sin(a) * r
            local found, gz = GetGroundZFor_3dCoord(px, py, z + 80.0, false)
            if found and gz > -5.0 and not surfaceZ(px, py, gz + 0.3) then return { x = px, y = py, z = gz + 1.0 } end
        end
    end
end

local function nearestHospital(c)
    local best, bd
    for _, h in ipairs(Config.Death.Hospitals) do
        local d = (h[2] - c.x) ^ 2 + (h[3] - c.y) ^ 2
        if not bd or d < bd then best, bd = h, d end
    end
    return best
end

local function reviveLocal(coords, pct, fade)
    local ped = PlayerPedId()
    if fade then DoScreenFadeOut(800) while not IsScreenFadedOut() do Wait(10) end end
    local pc = GetEntityCoords(ped)
    local c = coords or { x = pc.x, y = pc.y, z = pc.z, h = GetEntityHeading(ped) }
    local wz = surfaceZ(c.x + 0.0, c.y + 0.0, c.z + 0.0)
    if wz and c.z <= wz + 0.5 then
        -- mort dans l'eau : JAMAIS de réanimation dans l'eau (le joueur y re-mourait). Rive la plus proche, sinon hôpital le plus proche.
        local shore = nearestShore(c.x, c.y, c.z)
        if shore then
            c = { x = shore.x, y = shore.y, z = shore.z, h = c.h }
            ESX.ShowNotification('~b~Tu as été ramené sur la rive.')
        else
            local h = nearestHospital(c)
            if h then c = { x = h[2], y = h[3], z = h[4], h = h[5] } ESX.ShowNotification('~b~Tu as été transporté à l\'hôpital.') end
        end
    end
    graceUntil = GetGameTimer() + 8000
    lastRevive = GetGameTimer()
    RequestCollisionAtCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
    local hp = math.max(110, math.floor(GetEntityMaxHealth(ped) * (pct or 40) / 100))
    if not resurrect(c, hp) then
        -- impossible de relever le joueur ici (eau profonde…) : hôpital le plus proche
        local best, bd
        for _, h in ipairs(Config.Death.Hospitals) do
            local d = (h[2] - c.x) ^ 2 + (h[3] - c.y) ^ 2
            if not bd or d < bd then best, bd = h, d end
        end
        if best then
            print('^1[jobbuilder] résurrection impossible à cet endroit : repli à ' .. best[1] .. '^0')
            resurrect({ x = best[2], y = best[3], z = best[4], h = best[5] }, hp)
            ESX.ShowNotification('~r~Tu as été transporté à l\'hôpital.')
        end
    end
    -- Vérification : si le joueur est de nouveau mort dans les 2 s qui suivent, on recommence à l'hôpital le plus proche
    for _ = 1, 40 do
        Wait(50)
        if IsEntityDead(PlayerPedId()) then
            local h = nearestHospital(c)
            if h then
                print('^1[jobbuilder] mort juste après la réanimation : nouvel essai à ' .. h[1] .. '^0')
                resurrect({ x = h[2], y = h[3], z = h[4], h = h[5] }, hp)
            end
            break
        end
    end
    ped = PlayerPedId()
    ClearPedBloodDamage(ped)
    ClearPedTasksImmediately(ped)
    StopEntityFire(ped)
    SetEntityHealth(ped, math.max(110, math.floor(GetEntityMaxHealth(ped) * (pct or 40) / 100)))
    oxygenReset = true
    CreateThread(function()
        for _ = 1, (IsEntityInWater(ped) and 24 or 12) do
            Wait(500)
            SetPlayerUnderwaterTimeRemaining(PlayerId(), 40.0)
            SetEntityInvincible(PlayerPedId(), true)
            SetPlayerInvincible(PlayerId(), true)
        end
        -- Fin de la protection : retour au comportement normal (noyade possible, invincibilité retirée)
        SetEntityInvincible(PlayerPedId(), false)
        SetPlayerInvincible(PlayerId(), false)
        SetPedDiesInWater(PlayerPedId(), true)
        if IsPedSwimmingUnderWater(PlayerPedId()) then SetPlayerUnderwaterTimeRemaining(PlayerId(), 10.0) end
    end)
    AnimpostfxStopAll()
    dead, hold = false, 0.0
    hideUI()
    TriggerServerEvent('jobbuilder:server:revived')
    TriggerEvent('jobbuilder:client:revived')
    if fade then Wait(300) DoScreenFadeIn(900) end
    if Config.Death.ReviveAnim ~= false then reviveAnimation() end
end

RegisterNetEvent('jobbuilder:client:revive', function(pct, force)
    local ped = PlayerPedId()
    if not IsEntityDead(ped) and not dead then
        if force then                       -- /revive sur un joueur en vie : simple soin
            SetEntityHealth(ped, GetEntityMaxHealth(ped))
            ClearPedBloodDamage(ped)
            restoreNeeds(true)
            ESX.ShowNotification('~g~Tu as été soigné (vie, faim, soif).')
        end
        return
    end
    local ok, err = pcall(reviveLocal, nil, pct, false)
    if not ok then print('^1[jobbuilder] erreur pendant la réanimation : ' .. tostring(err) .. '^0') end
    dead, hold = false, 0.0
    hideUI()
    if force then restoreNeeds(true) end                -- /revive : vie, faim et soif à 100 %
    ESX.ShowNotification(force and '~g~Tu as été réanimé et soigné (vie, faim, soif).' or '~g~Tu as été réanimé.')
end)

local CAUSES = { 'WEAPON_DROWNING', 'WEAPON_DROWNING_IN_VEHICLE', 'WEAPON_FALL', 'WEAPON_EXPLOSION', 'WEAPON_FIRE', 'WEAPON_RUN_OVER_BY_CAR', 'WEAPON_BLEEDING', 'WEAPON_EXHAUSTION', 'WEAPON_ELECTRIC_FENCE' }

-- Diagnostic (console F8) : pourquoi le joueur vient de mourir ?
local function logDeath()
    local ped = PlayerPedId()
    local cause = GetPedCauseOfDeath(ped)
    local name = 'inconnue (' .. tostring(cause) .. ')'
    for _, w in ipairs(CAUSES) do if joaat(w) == cause then name = w end end
    print(('^3[jobbuilder] mort détectée : cause=%s | vie=%d | sous l\'eau=%s | dans l\'eau=%s | invincible=%s | %.1f s après la dernière réanimation^0'):format(
        name, GetEntityHealth(ped), tostring(IsPedSwimmingUnderWater(ped)), tostring(IsEntityInWater(ped)), tostring(GetPlayerInvincible(PlayerId())), (GetGameTimer() - lastRevive) / 1000))
end

local function onDeath()
    logDeath()
    dead, since, hold = true, GetGameTimer(), 0.0
    state = { left = Config.Death.RespawnTime, called = false, units = 0, ems = 0, cooldown = 0 }
    AnimpostfxPlay('DeathFailOut', 0, true)
    TriggerServerEvent('jobbuilder:server:died')
end

local function refreshState()
    ESX.TriggerServerCallback('jobbuilder:death:state', function(r)
        if r and r.ok then state = { left = r.left, called = r.called, units = r.units, ems = r.ems, cooldown = r.cooldown, at = GetGameTimer() } end
    end)
end

local function callEms()
    ESX.TriggerServerCallback('jobbuilder:death:call', function(r)
        if r and r.ok then
            ESX.ShowNotification(('~g~Les EMS ont été prévenus (%d en service).'):format(r.ems))
            refreshState()
        else
            ESX.ShowNotification('~r~' .. ((r and r.error) or 'Appel impossible'))
        end
    end)
end

-- Remet faim et soif à 100 % (esx_status). Plusieurs méthodes + ré-application : esx_basicneeds remet la faim/soif à 50 % quand le joueur « réapparaît »,
-- ce qui écrasait notre valeur si on la posait trop tôt.
restoreNeeds = function(healToo)
    local function apply()
        for _, name in ipairs({ 'hunger', 'thirst' }) do
            TriggerEvent('esx_status:set', name, 1000000)
            TriggerEvent('esx_status:add', name, 1000000)
        end
        if healToo then TriggerEvent('esx_basicneeds:healPlayer') end      -- soin complet d'esx_basicneeds s'il est présent
    end
    apply()
    CreateThread(function()
        Wait(1500) apply()
        Wait(2500) apply()
        local answered = false
        TriggerEvent('esx_status:getStatus', 'hunger', function(st)
            answered = true
            print(('^3[jobbuilder] faim après soins : %s / 1000000^0'):format(st and tostring(st.val) or '?'))
        end)
        Wait(1500)
        if not answered then print('^1[jobbuilder] esx_status ne répond pas : faim/soif non remises (événements esx_status:set / getStatus absents ?)^0') end
    end)
end

local function finishUi()
    dead, hold = false, 0.0
    AnimpostfxStopAll()
    hideUI()
    CreateThread(function() Wait(400) hideUI() end)       -- au cas où un dernier message d'affichage serait encore en route
end

local function respawn()
    ESX.TriggerServerCallback('jobbuilder:death:respawn', function(r)
        if not r or not r.ok then hold = 0.0 return ESX.ShowNotification('~r~' .. ((r and r.error) or 'Impossible')) end
        local ok, err = pcall(reviveLocal, { x = r.x, y = r.y, z = r.z, h = r.h }, r.health, true)
        if not ok then print('^1[jobbuilder] erreur pendant la réanimation : ' .. tostring(err) .. '^0') end
        finishUi()                                        -- l'écran de mort disparaît quoi qu'il arrive
        if r.restore then restoreNeeds((r.health or 0) >= 100) end
        ESX.ShowNotification(('Soins complets à l\'%s%s.%s'):format(r.label or 'hôpital', r.restore and ' (vie, faim, soif)' or '', (r.paid or 0) > 0 and (' Facture : ~r~' .. r.paid .. ' $') or ''))
    end)
end

-- Détection mort / réanimation externe
CreateThread(function()
    while true do
        Wait(250)
        if blocked() then
            if dead then            -- on vient d'entrer dans une zone gérée par un autre script : on efface notre écran de mort
                dead = false
                hideUI()
                AnimpostfxStopAll()
                TriggerServerEvent('jobbuilder:server:revived')
            end
        elseif active() then
            local isDead = IsEntityDead(PlayerPedId())
            if isDead and not dead and GetGameTimer() > graceUntil then onDeath()
            elseif not isDead and dead then
                dead = false
                hideUI()
                AnimpostfxStopAll()
                TriggerServerEvent('jobbuilder:server:revived')
            end
        end
    end
end)

-- Écran de mort : touches E (appeler) et G maintenu (réapparaître)
CreateThread(function()
    local lastPoll, lastUi = 0, 0
    while true do
        if dead then
            Wait(0)
            local now = GetGameTimer()
            if now - lastPoll > 2000 then lastPoll = now refreshState() end
            local left = math.max(0, math.floor(state.left - (now - (state.at or since)) / 1000))
            if IsControlJustReleased(0, 38) then callEms() end
            if left <= 0 and IsControlPressed(0, 47) then
                hold = hold + GetFrameTime() / 1.6
                if hold >= 1.0 then hold = 0.0 respawn() Wait(1500) end
            else
                hold = math.max(0.0, hold - GetFrameTime() * 2)
            end
            if now - lastUi > 120 then
                lastUi = now
                SendNUIMessage({ action = 'death', left = left, called = state.called, units = state.units, ems = state.ems, cooldown = state.cooldown, hold = hold, fee = Config.Death.RespawnFee })
            end
        else
            Wait(500)
        end
    end
end)

-- ── Côté EMS : alertes, blips, touche Y pour prendre l'appel ──
local emsBlips = {}

local function removeBlip(id)
    local b = emsBlips[id]
    if b and DoesBlipExist(b) then RemoveBlip(b) end
    emsBlips[id] = nil
end

RegisterNetEvent('jobbuilder:client:emsCall', function(c)
    ESX.ShowNotification(('~r~[URGENCE]~s~ %s est inconscient.\nAppuie sur ~INPUT_REPLAY_SHOWHOTKEY~ (Y) pour prendre l\'appel.'):format(c.name or 'Un patient'))
    PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
    removeBlip(c.id)
    local b = AddBlipForCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
    SetBlipSprite(b, 153)
    SetBlipColour(b, 1)
    SetBlipScale(b, 1.1)
    SetBlipFlashes(b, true)
    SetBlipAsShortRange(b, false)
    BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('Urgence : ' .. (c.name or 'patient')) EndTextCommandSetBlipName(b)
    emsBlips[c.id] = b
    SetTimeout(900000, function() removeBlip(c.id) end)
end)

RegisterNetEvent('jobbuilder:client:emsCallEnd', function(id) removeBlip(id) end)

RegisterCommand('jbems_accept', function()
    if dead then return end
    ESX.TriggerServerCallback('jobbuilder:ems:take', function(r)
        if not r or not r.ok then return ESX.ShowNotification('~r~' .. ((r and r.error) or 'Aucun appel en cours')) end
        if r.joined then
            SetNewWaypoint(r.x + 0.0, r.y + 0.0)
            ESX.ShowNotification(('~g~Appel pris : %s. GPS défini.'):format(r.name or 'patient'))
        else
            ESX.ShowNotification('Tu as quitté cet appel.')
        end
    end, 0)
end, false)
RegisterKeyMapping('jbems_accept', 'EMS : prendre le dernier appel', 'keyboard', 'Y')

-- ── Massage cardiaque ──
RegisterNetEvent('jobbuilder:client:cpr', function(target, secs)
    CreateThread(function()
        local ped = PlayerPedId()
        local tp = GetPlayerPed(GetPlayerFromServerId(target))
        if tp == 0 then return TriggerServerEvent('jobbuilder:server:cprCancel') end
        local dict = 'mini@cpr@char_a@cpr_str'
        RequestAnimDict(dict)
        local t = 0
        while not HasAnimDictLoaded(dict) and t < 100 do Wait(20) t = t + 1 end
        local start = GetEntityCoords(ped)
        TaskTurnPedToFaceEntity(ped, tp, 600)
        Wait(600)
        TaskPlayAnim(ped, dict, 'cpr_pumpchest', 8.0, -8.0, -1, 1, 0.0, false, false, false)
        local t0, total, cancelled = GetGameTimer(), secs * 1000, false
        while GetGameTimer() - t0 < total do
            Wait(0)
            local pct = (GetGameTimer() - t0) / total
            DrawRect(0.5, 0.9, 0.186, 0.026, 0, 0, 0, 170)
            DrawRect(0.5 - 0.09 + 0.18 * pct / 2, 0.9, math.max(0.18 * pct, 0.0001), 0.018, 239, 68, 68, 235)
            SetTextFont(4) SetTextScale(0.0, 0.38) SetTextColour(255, 255, 255, 235) SetTextCentre(true) SetTextOutline()
            BeginTextCommandDisplayText('STRING') AddTextComponentSubstringPlayerName('Massage cardiaque…') EndTextCommandDisplayText(0.5, 0.845)
            ped = PlayerPedId()
            if IsEntityDead(ped) or #(GetEntityCoords(ped) - start) > 1.5 or IsControlJustPressed(0, 73) then cancelled = true break end
        end
        ClearPedTasks(ped)
        if cancelled then
            TriggerServerEvent('jobbuilder:server:cprCancel')
            ESX.ShowNotification('~r~Réanimation interrompue.')
        else
            TriggerServerEvent('jobbuilder:server:cprDone')
        end
    end)
end)

TriggerEvent('chat:addSuggestion', '/' .. (Config.Death.ReviveCommand or 'revive'), 'Réanimer et soigner à 100 % (vie, faim, soif)', { { name = 'id', help = 'ID du joueur (vide = toi)' } })

-- ── Oxygène : réserve d'air gérée par le script (compte à rebours fiable) + HUD ──
-- Mode « script » (par défaut) : on neutralise la noyade native du jeu et on gère nous-mêmes l'air (durée réglable), le HUD et les dégâts de noyade.
-- Mode « jeu » : on lit simplement la réserve native.
CreateThread(function()
    local shown, o2, maxNative, drown, last = false, nil, 10.0, 0.0, GetGameTimer()
    while true do
        local cfg = Config.Death
        local now = GetGameTimer()
        local dt = math.min(0.5, (now - last) / 1000)
        last = now
        local ped = PlayerPedId()
        if oxygenReset then o2, drown, oxygenReset = nil, 0.0, false end
        local under = IsPedSwimmingUnderWater(ped) and not IsEntityDead(ped)
        local t, maxO

        if cfg.OxygenCustom ~= false then
            maxO = cfg.OxygenSeconds or 30
            o2 = o2 and math.min(o2, maxO) or maxO
            if under then
                if not GetPlayerInvincible(PlayerId()) then o2 = math.max(0.0, o2 - dt) end
                SetPlayerUnderwaterTimeRemaining(PlayerId(), 100.0)     -- le jeu ne noie plus : c'est ce script qui s'en charge
                if o2 <= 0.0 and not GetPlayerInvincible(PlayerId()) then
                    drown = drown + dt
                    if drown >= 1.0 then drown = 0.0 ApplyDamageToPed(ped, cfg.OxygenDamage or 10, true) end
                end
            else
                drown = 0.0
                o2 = math.min(maxO, o2 + dt * maxO / 3.0)               -- on reprend son souffle en ~3 s
            end
            t = o2
        else
            t = GetPlayerUnderwaterTimeRemaining(PlayerId())
            if under then if t > maxNative then maxNative = t end else if t and t > 0 then maxNative = t end end
            maxO = maxNative
        end

        local show = cfg.OxygenHud ~= false and not IsEntityDead(ped) and (under or (t and maxO and t < maxO - 0.05))
        if show then
            SendNUIMessage({ action = 'oxygen', pct = maxO > 0 and t / maxO or 0, left = t, warn = t <= (cfg.OxygenWarn or 3) })
            shown = true
        elseif shown then
            SendNUIMessage({ action = 'oxygenHide' })
            shown = false
        end
        Wait((under or shown) and 100 or 400)
    end
end)
