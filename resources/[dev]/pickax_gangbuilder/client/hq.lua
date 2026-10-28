-- ─────────────────────────────── Raids de QG (client) ───────────────────────────────
-- Zone du QG sur la carte et au sol, progression du raid pour les deux camps.
local state, role, blips, stateAt = nil, nil, {}, 0

local function clearBlips()
    for _, h in ipairs(blips) do if DoesBlipExist(h) then RemoveBlip(h) end end
    blips = {}
end

RegisterNetEvent('gangbuilder:client:hqRaid', function(s, r)
    local was = state ~= nil
    state, role, stateAt = type(s) == 'table' and s or nil, r, GetGameTimer()
    if not state then clearBlips() return end
    if not was then
        PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
        clearBlips()
        local c = state.coords
        local rb = AddBlipForRadius(c.x + 0.0, c.y + 0.0, c.z + 0.0, (state.radius or 12.0) + 0.0)
        SetBlipColour(rb, 1); SetBlipAlpha(rb, 140); SetBlipFlashes(rb, true)
        local ib = AddBlipForCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
        SetBlipSprite(ib, 543); SetBlipColour(ib, 1); SetBlipScale(ib, 0.9); SetBlipFlashes(ib, true)
        BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName(('Raid du QG — %s'):format(state.targetLabel or '')); EndTextCommandSetBlipName(ib)
        blips = { rb, ib }
        if role == 'defender' then SetNewWaypoint(c.x + 0.0, c.y + 0.0) end
    end
end)

local function text(y, scale, str, r, g, b)
    SetTextFont(4); SetTextScale(0.0, scale); SetTextColour(r or 255, g or 255, b or 255, 235); SetTextOutline(); SetTextCentre(true)
    BeginTextCommandDisplayText('STRING'); AddTextComponentSubstringPlayerName(str); EndTextCommandDisplayText(0.5, y)
end

CreateThread(function()
    while true do
        if not state then Wait(1000) else
            Wait(0)
            local c = state.coords
            DrawMarker(1, c.x + 0.0, c.y + 0.0, c.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, (state.radius or 12.0) * 2.0, (state.radius or 12.0) * 2.0, 4.0, 239, 68, 68, 40, false, false, 2, false, nil, nil, false)
            local pct = math.min(100, math.floor((state.progress or 0) / math.max(1, state.hold or 90) * 100))
            text(0.045, 0.45, role == 'attacker' and ('RAID · QG de %s'):format(state.targetLabel or '?') or ('QG ATTAQUÉ par %s'):format(state.attackerLabel or '?'), 239, 68, 68)
            text(0.074, 0.38, role == 'attacker' and ('Tenez la zone sans défenseur : %d %%'):format(pct) or ('Entrez dans la zone pour stopper le raid ! Prise : %d %%'):format(pct))
        end
    end
end)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then clearBlips() end end)
