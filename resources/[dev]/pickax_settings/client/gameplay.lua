-- Réglages « Joueurs & combat » appliqués chez chaque joueur. Optimisation : aucune boucle ne tourne tant qu'aucun de ces réglages n'est
-- modifié depuis le panel ; la boucle (1 par seconde) s'arrête toute seule dès qu'il n'y a plus rien à maintenir.
local values, over, applied = {}, {}, {}
local WATCHED = { 'critical_hits', 'drive_by', 'health_regen', 'weapon_damage', 'melee_damage', 'idle_cam', 'stamina_infinite', 'wanted_enabled' }
local running = false

local function active(key) return over[key] ~= nil end
-- appliqué si le réglage est modifié, ou s'il vient d'être remis à sa valeur par défaut (pour annuler l'effet précédent)
local function should(key)
    local on = over[key] ~= nil
    local was = applied[key]
    applied[key] = on or nil
    return on or was
end

local function applyStatic()
    local pid = PlayerId()
    if should('friendly_fire') then NetworkSetFriendlyFireOption(values.friendly_fire ~= false) end
    if should('health_regen') then SetPlayerHealthRechargeMultiplier(pid, (tonumber(values.health_regen) or 1.0) + 0.0) end
    if should('weapon_damage') then SetPlayerWeaponDamageModifier(pid, (tonumber(values.weapon_damage) or 1.0) + 0.0) end
    if should('melee_damage') then SetPlayerMeleeWeaponDamageModifier(pid, (tonumber(values.melee_damage) or 1.0) + 0.0) end
    if should('critical_hits') then SetPedSuffersCriticalHits(PlayerPedId(), values.critical_hits ~= false) end
    if should('drive_by') then SetPlayerCanDoDriveBy(pid, values.drive_by ~= false) end
end

-- ce qui doit être ré-appliqué régulièrement (réapparition, nouveau ped, endurance, caméra d'inactivité, recherche)
local function maintain()
    local ped, pid = PlayerPedId(), PlayerId()
    local any, fast = false, false
    if active('critical_hits') then any = true SetPedSuffersCriticalHits(ped, values.critical_hits ~= false) end
    if active('drive_by') then any = true SetPlayerCanDoDriveBy(pid, values.drive_by ~= false) end
    if active('health_regen') then any = true SetPlayerHealthRechargeMultiplier(pid, (tonumber(values.health_regen) or 1.0) + 0.0) end
    if active('weapon_damage') then any = true SetPlayerWeaponDamageModifier(pid, (tonumber(values.weapon_damage) or 1.0) + 0.0) end
    if active('melee_damage') then any = true SetPlayerMeleeWeaponDamageModifier(pid, (tonumber(values.melee_damage) or 1.0) + 0.0) end
    if active('idle_cam') and values.idle_cam == false then any = true InvalidateIdleCam() InvalidateVehicleIdleCam() end
    if active('stamina_infinite') and values.stamina_infinite == true then any, fast = true, true RestorePlayerStamina(pid, 1.0) end
    if active('wanted_enabled') and values.wanted_enabled == false then
        any = true
        SetMaxWantedLevel(0)
        if GetPlayerWantedLevel(pid) > 0 then ClearPlayerWantedLevel(pid) SetPlayerWantedLevel(pid, 0, false) SetPlayerWantedLevelNow(pid, false) end
    end
    return any, fast
end

local function startLoop()
    if running then return end
    running = true
    CreateThread(function()
        while true do
            local ok, any, fast = pcall(maintain)
            if not ok or not any then running = false return end
            Wait(fast and 300 or 1000)
        end
    end)
end

AddEventHandler('pickax_settings:changed', function(all, ov)
    values, over = all or {}, ov or {}
    if active('wanted_enabled') == false and applied.wanted_enabled then SetMaxWantedLevel(5) end   -- réglage remis par défaut : les étoiles reviennent
    applied.wanted_enabled = active('wanted_enabled') or nil
    applyStatic()
    for _, k in ipairs(WATCHED) do if over[k] ~= nil then startLoop() break end end   -- aucune boucle tant qu'aucun de ces réglages n'est modifié
end)
