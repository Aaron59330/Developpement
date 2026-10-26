-- Reçoit les réglages du serveur ; les ressources les lisent via l'export ou l'événement local 'pickax_settings:changed' (valeurs, surcharges).
local values, over = {}, {}
local ready = false

RegisterNetEvent('pickax_settings:sync', function(all, ov)
    values, over, ready = all or {}, ov or {}, true
    TriggerEvent('pickax_settings:changed', values, over)
end)

exports('Get', function(key) return values[key] end)
exports('GetAll', function() return values end)
exports('Overrides', function() return over end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('pickax_settings:request')
    Wait(8000)
    if not ready then TriggerServerEvent('pickax_settings:request') end
end)


-- ───────── Mode performance (FPS) ─────────
-- Coût : un échantillon par seconde (1 native). Mode « auto » : s'active si les FPS restent bas, se désactive quand ils remontent nettement (hystérésis).
local perfOn, fpsEma, lowN, highN = false, 60.0, 0, 0
local function setPerf(v)
    if v == perfOn then return end
    perfOn = v
    TriggerEvent('pickax_perf:changed', perfOn)
end
local function evaluate()
    local mode = (over and over.perf_mode) or 'auto'
    if mode == 'on' then setPerf(true) elseif mode == 'off' then setPerf(false) end
end
AddEventHandler('pickax_settings:changed', function() evaluate() end)

exports('IsPerf', function() return perfOn end)
exports('Fps', function() return math.floor(fpsEma + 0.5) end)
RegisterNUICallback('getPerf', function(_, cb) cb({ perf = perfOn, fps = math.floor(fpsEma + 0.5) }) end)

CreateThread(function()
    Wait(25000)                                   -- laisse finir le chargement
    local sinceReport = 0
    while true do
        Wait(1000)
        if not IsPauseMenuActive() and not IsScreenFadedOut() then
            local ft = GetFrameTime()
            if ft > 0.0 then fpsEma = fpsEma * 0.7 + (1.0 / ft) * 0.3 end
            local mode = (over and over.perf_mode) or 'auto'
            if mode == 'auto' then
                local thr = tonumber(values.perf_threshold) or 40
                if fpsEma < thr then lowN, highN = lowN + 1, 0 elseif fpsEma > thr + 15 then highN, lowN = highN + 1, 0 else lowN, highN = 0, 0 end
                if not perfOn and lowN >= 6 then setPerf(true) elseif perfOn and highN >= 25 then setPerf(false) end
            end
        end
        sinceReport = sinceReport + 1
        if sinceReport >= 60 then
            sinceReport = 0
            TriggerServerEvent('pickax_settings:fps', math.floor(fpsEma + 0.5), perfOn)
        end
    end
end)
