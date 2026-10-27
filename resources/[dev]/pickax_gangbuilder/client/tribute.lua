-- ─────────────────────────────── Zones de tribut (client) ───────────────────────────────
-- Affiche la zone disputée (carte + cercle au sol), le décompte et le nombre de survivants par gang ; le gang vainqueur voit le point de collecte (touche E).
local state, blips, state_at = nil, {}, 0
local lastCollect = 0

local function clearBlips()
    for _, h in ipairs(blips) do if DoesBlipExist(h) then RemoveBlip(h) end end
    blips = {}
end

local function makeBlips(s)
    clearBlips()
    local c = s.phase == 'collect' and (s.collect or s.coords) or s.coords
    if s.phase == 'fight' then
        local r = AddBlipForRadius(s.coords.x + 0.0, s.coords.y + 0.0, s.coords.z + 0.0, (s.radius or 50.0) + 0.0)
        SetBlipColour(r, 5); SetBlipAlpha(r, 120); SetBlipFlashes(r, true)
        blips[#blips + 1] = r
    end
    local i = AddBlipForCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
    SetBlipSprite(i, s.phase == 'collect' and 500 or 436); SetBlipColour(i, 5); SetBlipScale(i, 0.9)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(('%s — %s'):format(s.phase == 'collect' and 'Tribut à collecter' or 'Zone de tribut', s.label or ''))
    EndTextCommandSetBlipName(i)
    blips[#blips + 1] = i
end

RegisterNetEvent('gangbuilder:client:tribute', function(s)
    local before = state and state.phase
    state = type(s) == 'table' and s or nil
    state_at = GetGameTimer()
    if not state then clearBlips() return end
    if state.phase ~= before then
        PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
        makeBlips(state)
    end
end)

local function text(x, y, scale, str, r, g, b, centre)
    SetTextFont(4); SetTextScale(0.0, scale); SetTextColour(r or 255, g or 255, b or 255, 235); SetTextOutline()
    SetTextCentre(centre ~= false)
    BeginTextCommandDisplayText('STRING'); AddTextComponentSubstringPlayerName(str); EndTextCommandDisplayText(x, y)
end

CreateThread(function()
    while true do
        if not state then Wait(800) else
            Wait(0)
            local left = math.max(0, (state.left or 0) - math.floor((GetGameTimer() - (state_at or GetGameTimer())) / 1000))
            local mm, ss = math.floor(left / 60), left % 60
            if state.phase == 'fight' then
                text(0.5, 0.045, 0.45, ('TRIBUT · %s'):format(state.label or ''), 253, 194, 125)
                text(0.5, 0.075, 0.38, ('Temps restant %d:%02d — le plus de survivants dans la zone gagne'):format(mm, ss))
                for i, g in ipairs(state.counts or {}) do
                    if i <= 4 then text(0.5, 0.098 + (i - 1) * 0.024, 0.34, ('%s : %d'):format(g.label, g.count), 220, 220, 225) end
                end
                local c = state.coords
                DrawMarker(1, c.x + 0.0, c.y + 0.0, c.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, (state.radius or 50.0) * 2.0, (state.radius or 50.0) * 2.0, 6.0, 253, 194, 125, 35, false, false, 2, false, nil, nil, false)
            elseif state.phase == 'collect' then
                local c = state.collect or state.coords
                local ped = PlayerPedId()
                local p = GetEntityCoords(ped)
                local d = #(p - vector3(c.x + 0.0, c.y + 0.0, c.z + 0.0))
                text(0.5, 0.045, 0.42, ('TRIBUT · %s remporte %s'):format(state.winnerLabel or '?', state.label or ''), 253, 194, 125)
                text(0.5, 0.074, 0.36, ('À collecter : %d:%02d'):format(mm, ss))
                if d < 25.0 then
                    DrawMarker(1, c.x + 0.0, c.y + 0.0, c.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.2, 1.2, 0.8, 253, 194, 125, 140, false, false, 2, false, nil, nil, false)
                    if d < 3.0 then
                        BeginTextCommandDisplayHelp('STRING'); AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Collecter le tribut'); EndTextCommandDisplayHelp(0, false, false, -1)
                        if IsControlJustPressed(0, 38) and GetGameTimer() - lastCollect > 1500 then
                            lastCollect = GetGameTimer()
                            TriggerServerEvent('gangbuilder:tribute:collect')
                        end
                    end
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then clearBlips() end end)
