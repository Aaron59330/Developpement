-- ─────────────────────────────── Pôle emploi : quêtes des petits jobs (client) ───────────────────────────────
NuiRemote['jobcenter:info'] = true
NuiRemote['jobcenter:take'] = true
NuiRemote['jobcenter:leave'] = true

local C = Config.JobCenter
local Q = nil     -- { id, label, steps, idx, blip, gz }

local function srv(name, cb, ...) ESX.TriggerServerCallback('jobbuilder:jobcenter:' .. name, cb, ...) end

-- Menu F6 (« Mes quêtes ») : les quêtes du petit job actuel
function OpenQuestPanel()
    srv('info', function(res)
        if not res or not res.ok then return JBNotify('~r~' .. ((res and res.error) or 'Quêtes indisponibles')) end
        if not res.isSmall then return JBNotify('~r~Tu n\'as pas de petit job : passe au Pôle emploi.') end
        res.tab = 'quests'
        OpenUI({ action = 'open', kind = 'jobcenter', data = res })
    end)
end

local function text(x, y, str, scale, r, g, b)
    SetTextFont(4) SetTextScale(0.0, scale) SetTextColour(r or 255, g or 255, b or 255, 235) SetTextCentre(true) SetTextOutline()
    BeginTextCommandDisplayText('STRING') AddTextComponentSubstringPlayerName(str) EndTextCommandDisplayText(x, y)
end

local function setBlip(loc, label)
    if Q.blip and DoesBlipExist(Q.blip) then RemoveBlip(Q.blip) end
    Q.blip = AddBlipForCoord(loc.x + 0.0, loc.y + 0.0, loc.z + 0.0)
    SetBlipSprite(Q.blip, 1) SetBlipColour(Q.blip, 5) SetBlipScale(Q.blip, 0.9)
    SetBlipRoute(Q.blip, true) SetBlipRouteColour(Q.blip, 5)
    BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(label or 'Quête') EndTextCommandSetBlipName(Q.blip)
end

local function endQuest(msg)
    if not Q then return end
    if Q.blip and DoesBlipExist(Q.blip) then RemoveBlip(Q.blip) end
    Q = nil
    if msg then JBNotify(msg) end
end

local function cancelQuest(msg)
    if not Q then return end
    srv('questCancel', function() end)
    endQuest(msg or 'Quête annulée.')
end
RegisterNetEvent('jobbuilder:client:jobcenterCancel', function(msg) endQuest('~r~' .. (msg or 'Quête annulée.')) end)
RegisterCommand('annulerquete', function() cancelQuest() end, false)

local function groundOf(loc)
    local ok, z = GetGroundZFor_3dCoord(loc.x + 0.0, loc.y + 0.0, loc.z + 50.0, false)
    return ok and z or loc.z
end

-- Travail sur place : animation + barre de progression ; true si terminé sans interruption
local function work(step, qid)
    local ped = PlayerPedId()
    local start = GetEntityCoords(ped)
    local a = (C.Anims or {})[step.anim] or C.Anims.clipboard
    if a.scenario then
        TaskStartScenarioInPlace(ped, a.scenario, 0, true)
    else
        RequestAnimDict(a.dict)
        local t = GetGameTimer()
        while not HasAnimDictLoaded(a.dict) and GetGameTimer() - t < 3000 do Wait(10) end
        TaskPlayAnim(ped, a.dict, a.clip, 3.0, -3.0, step.secs * 1000, 1, 0.0, false, false, false)
    end
    local t0, total = GetGameTimer(), step.secs * 1000
    while true do
        local el = GetGameTimer() - t0
        if el >= total then break end
        if not Q or Q.id ~= qid or #(GetEntityCoords(ped) - start) > 3.5 or IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) then
            ClearPedTasks(ped)
            return false
        end
        DisablePlayerFiring(PlayerId(), true)
        DrawRect(0.5, 0.875, 0.18, 0.014, 0, 0, 0, 190)
        DrawRect(0.5 - 0.09 + 0.09 * (el / total), 0.875, 0.18 * (el / total), 0.014, 255, 255, 255, 235)
        text(0.5, 0.845, step.label, 0.4)
        Wait(0)
    end
    ClearPedTasks(ped)
    return true
end

local function stepDone()
    local id, idx = Q.id, Q.idx
    local res
    srv('questStep', function(r) res = r or { ok = false } end, id, idx)
    local t = GetGameTimer()
    while not res and GetGameTimer() - t < 7000 do Wait(30) end
    if not Q or Q.id ~= id then return end
    if not res or not res.ok then return cancelQuest('~r~' .. ((res and res.error) or 'Quête annulée.')) end
    if res.done then
        srv('questFinish', function(f)
            if f and f.ok then
                JBNotify(('Quête terminée ! ~g~+%s$~s~%s'):format(f.reward, f.bonus and f.bonus > 0 and (' (bonus de grade +%d%%)'):format(f.bonus) or ''))
                if f.promoted then JBNotify(('Promotion : tu es maintenant ~b~%s~s~ !'):format(f.promoted)) end
            else JBNotify('~r~' .. ((f and f.error) or 'Quête non validée')) end
            endQuest()
        end, id)
        return
    end
    Q.idx = idx + 1
    Q.gz = nil
    local nx = Q.steps[Q.idx]
    if nx.t == 'goto' then setBlip(nx.loc, nx.loc.label) end
end

local function begin(m)
    Q = { id = m.id, label = m.label, steps = m.steps, idx = 1 }
    JBNotify(('Quête : ~b~%s~s~ — suis le GPS.'):format(m.label))
    setBlip(m.steps[1].loc, m.steps[1].loc.label)
    CreateThread(function()
        local id = Q.id
        local busy = false
        while Q and Q.id == id do
            Wait(0)
            local st = Q.steps[Q.idx]
            if st and not busy then
                local ped = PlayerPedId()
                local c = GetEntityCoords(ped)
                local d = #(c - vector3(st.loc.x, st.loc.y, c.z))
                if d < 120.0 then Q.gz = Q.gz or groundOf(st.loc) end
                local z = Q.gz or st.loc.z
                text(0.5, 0.045, ('~b~%s~s~ · étape %d/%d'):format(Q.label, Q.idx, #Q.steps), 0.45)
                text(0.5, 0.075, st.label, 0.4, 230, 230, 230)
                if d < 60.0 then DrawMarker(1, st.loc.x + 0.0, st.loc.y + 0.0, z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 1.2, 0, 164, 255, 120, false, false, 2, false, nil, nil, false) end
                if st.t == 'goto' then
                    if d < 3.5 and not IsPedInAnyVehicle(ped, false) then busy = true stepDone() busy = false end
                elseif d < 3.0 then
                    ESX.ShowHelpNotification(('Appuie sur ~INPUT_CONTEXT~ : %s'):format(st.label))
                    if IsControlJustReleased(0, 38) then
                        busy = true
                        local ok = work(st, id)
                        if ok then stepDone() elseif Q and Q.id == id then JBNotify('~r~Action interrompue : reste sur place jusqu\'à la fin.') end
                        busy = false
                    end
                end
            end
        end
    end)
end

-- Lancement depuis le panneau (NUI → client) : le serveur construit la quête, le panneau se ferme
NuiLocal.jcStart = function(args, cb)
    srv('questStart', function(res)
        if res and res.ok then
            CloseUI()
            SetTimeout(200, function() begin(res.mission) end)
        end
        cb(res or { ok = false, error = 'Aucune réponse' })
    end, args[1])
end
NuiLocal.jcCancel = function(_, cb)
    cancelQuest()
    cb({ ok = true })
end
