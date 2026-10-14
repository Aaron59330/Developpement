-- ─────────────────────────────── Affrontements de territoire (client) ───────────────────────────────
-- Alerte du propriétaire / de l'intrus : son + zone qui clignote sur la carte pendant Conflicts.AlertBlipSeconds.

local conflictBlips = {}   -- [territoire] = { radius, icon }

local function clearConflict(id)
    local b = conflictBlips[id]
    if not b then return end
    for _, h in ipairs(b) do if DoesBlipExist(h) then RemoveBlip(h) end end
    conflictBlips[id] = nil
end

RegisterNetEvent('gangbuilder:client:conflict', function(d)
    if type(d) ~= 'table' or not d.coords then return end
    clearConflict(d.id)
    PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
    local c = d.coords
    local radius = AddBlipForRadius(c.x + 0.0, c.y + 0.0, c.z + 0.0, (d.radius or 40.0) + 0.0)
    SetBlipColour(radius, 1)
    SetBlipAlpha(radius, 150)
    SetBlipFlashes(radius, true)
    local icon = AddBlipForCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
    SetBlipSprite(icon, 310)
    SetBlipColour(icon, 1)
    SetBlipScale(icon, 1.0)
    SetBlipFlashes(icon, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(('Affrontement — %s'):format(d.label or 'Territoire'))
    EndTextCommandSetBlipName(icon)
    conflictBlips[d.id] = { radius, icon }
    if d.role == 'owner' then SetNewWaypoint(c.x + 0.0, c.y + 0.0) end
    local seconds = tonumber(d.blip) or 90
    SetTimeout(seconds * 1000, function()
        local b = conflictBlips[d.id]
        if b then for _, h in ipairs(b) do if DoesBlipExist(h) then SetBlipFlashes(h, false) end end end
    end)
end)

RegisterNetEvent('gangbuilder:client:conflictScore', function(s)
    if type(s) ~= 'table' then return end
    PlaySoundFrontend(-1, 'CONFIRM_BEEP', 'HUD_MINI_GAME_SOUNDSET', true)
    GBNotify(('Affrontement : ~b~%s~s~ %d - %d ~r~%s~s~'):format(s.ownerLabel or '?', s.owner or 0, s.intruder or 0, s.intruderLabel or '?'))
end)

RegisterNetEvent('gangbuilder:client:conflictEnd', function(id)
    clearConflict(id)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for id in pairs(conflictBlips) do clearConflict(id) end
end)
