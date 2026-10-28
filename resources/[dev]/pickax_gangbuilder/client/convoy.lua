-- ─────────────────────────────── Convois de gang (client) : destination ou zone approximative du convoi ───────────────────────────────
local state, role, blips = nil, nil, {}

local function clear()
    for _, h in ipairs(blips) do if DoesBlipExist(h) then RemoveBlip(h) end end
    blips = {}
end

local function name(h, text)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName(text); EndTextCommandSetBlipName(h)
end

RegisterNetEvent('gangbuilder:client:convoy', function(s, r)
    local fresh = state == nil
    state, role = type(s) == 'table' and s or nil, r
    clear()
    if not state then
        if r == 'win' and Notify then Notify('Convoi terminé : livraison réussie.') end
        return
    end
    local c = state.coords
    if role == 'owner' then
        local d = state.to
        local b = AddBlipForCoord(d.x + 0.0, d.y + 0.0, d.z + 0.0)
        SetBlipSprite(b, 478); SetBlipColour(b, 2); SetBlipRoute(b, true); name(b, 'Destination du convoi')
        blips[#blips + 1] = b
        if fresh then SetNewWaypoint(d.x + 0.0, d.y + 0.0) end
    else
        local rb = AddBlipForRadius(c.x + 0.0, c.y + 0.0, c.z + 0.0, (state.radius or 150.0) + 0.0)
        SetBlipColour(rb, 1); SetBlipAlpha(rb, 120)
        local ib = AddBlipForCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
        SetBlipSprite(ib, 477); SetBlipColour(ib, 1); name(ib, ('Convoi de %s'):format(state.label or '?'))
        blips[#blips + 1] = rb blips[#blips + 1] = ib
        if fresh then PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true) end
    end
end)

local function text(y, str, r, g, b)
    SetTextFont(4); SetTextScale(0.0, 0.4); SetTextColour(r, g, b, 235); SetTextOutline(); SetTextCentre(true)
    BeginTextCommandDisplayText('STRING'); AddTextComponentSubstringPlayerName(str); EndTextCommandDisplayText(0.5, y)
end

CreateThread(function()
    while true do
        if not state or role ~= 'owner' then Wait(1000) else
            Wait(0)
            local left = math.max(0, (state.endsAt or 0) - GetCloudTimeAsInt())
            text(0.045, ('CONVOI · %d:%02d'):format(left // 60, left % 60), 255, 255, 255)
            if (state.progress or 0) > 0 then text(0.072, ('Des rivaux sont sur vous ! %d / %d'):format(state.progress, state.need or 30), 239, 68, 68) end
        end
    end
end)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then clear() end end)
