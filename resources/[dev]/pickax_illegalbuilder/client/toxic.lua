-- ─────────────────────────────── Intoxication des laboratoires (client) ───────────────────────────────
local T = Config.Toxic
local level = 0
local warnedZone = false

-- Détection : dans le rayon d'un laboratoire avec tenue exigée, sans la tenue → on signale au serveur (une fois par tick)
CreateThread(function()
    while true do
        local sleep = 1500
        if T.Enabled and LabOutfitOK then
            local ped = PlayerPedId()
            if not IsEntityDead(ped) then
                local pos = GetEntityCoords(ped)
                local exposed = false
                for _, e in ipairs((State and State.entities) or {}) do
                    if e.type == 'drug' then
                        for _, p in ipairs(e.points) do
                            if p.kind == 'process' and p.outfit and p.coords then
                                local r = (p.outfit.radius or 15) + 0.0
                                if #(pos - vector3(p.coords.x, p.coords.y, p.coords.z)) <= r and not LabOutfitOK(p.outfit) then exposed = true end
                            end
                        end
                    end
                end
                if exposed then
                    sleep = T.Tick * 1000
                    TriggerServerEvent('illegalbuilder:server:labExposure')
                    if not warnedZone then warnedZone = true Notify('Zone contaminée : porte la tenue de protection, sinon tu t\'intoxiques !', 'error') end
                else
                    warnedZone = false
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('illegalbuilder:client:toxic', function(l) level = tonumber(l) or 0 end)
RegisterNetEvent('illegalbuilder:client:toxicCured', function()
    level = 0
    ClearTimecycleModifier()
    StopGameplayCamShaking(true)
    ClearPedTasks(PlayerPedId())
end)

-- Symptômes : vision trouble et caméra qui tremble, toux, vomissements, chutes ; petit indicateur à l'écran
local lastCough, lastFall, shaking = 0, 0, false
CreateThread(function()
    while true do
        if level > 0 then
            local ped = PlayerPedId()
            local k = level / 100.0
            if level >= 15 then
                SetTimecycleModifier('drug_wobbly')
                SetTimecycleModifierStrength(math.min(1.0, k * 1.1))
                if not shaking then ShakeGameplayCam('DRUNK_SHAKE', 0.3 + k) shaking = true end
                SetGameplayCamShakeAmplitude(0.3 + k)
            end
            local now = GetGameTimer()
            if level >= 40 and now - lastCough > 22000 and not IsPedInAnyVehicle(ped, false) and not IsEntityDead(ped) then
                lastCough = now
                RequestAnimDict('timetable@gardener@smoking_joint')
                local t = GetGameTimer() + 1500
                while not HasAnimDictLoaded('timetable@gardener@smoking_joint') and GetGameTimer() < t do Wait(10) end
                TaskPlayAnim(ped, 'timetable@gardener@smoking_joint', 'idle_cough', 8.0, 8.0, 3500, 49, 0, false, false, false)
            end
            if level >= 65 and now - lastFall > 45000 and not IsPedInAnyVehicle(ped, false) and not IsEntityDead(ped) then
                lastFall = now
                SetPedToRagdoll(ped, 2500, 2500, 0, false, false, false)
            end
            -- indicateur discret
            SetTextScale(0.0, 0.34) SetTextFont(4) SetTextOutline() SetTextColour(255, 120, 120, 230)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(('Intoxication : %d %%'):format(level))
            EndTextCommandDisplayText(0.012, 0.62)
            Wait(0)
        else
            if shaking then
                shaking = false
                ClearTimecycleModifier()
                StopGameplayCamShaking(true)
            end
            Wait(1000)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then ClearTimecycleModifier() StopGameplayCamShaking(true) end
end)
