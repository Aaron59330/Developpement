-- ─────────────────────────────── Pôle emploi (client) ───────────────────────────────
Handlers.jobcenter = function(node)
    if node.kind ~= 'desk' then return end
    ServerCall('worldbuilder:jobcenter:info', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Pôle emploi indisponible', 'error') end
        res.eid, res.pi, res.mode = node.eid, node.pi, 'desk'
        OpenPanel('jobcenter', res, { type = 'jobcenter', eid = node.eid, pi = node.pi })
    end, node.eid, node.pi)
end

-- Menu F6 (jobbuilder → « Mes quêtes ») : mêmes quêtes sans passer par le guichet
function OpenQuests()
    ServerCall('worldbuilder:jobcenter:info', function(res)
        if not res or not res.ok then return Notify((res and res.error) or 'Quêtes indisponibles', 'error') end
        if not res.isSmall then return Notify('Tu n\'as pas de petit job : passe au pôle emploi.', 'error') end
        res.mode = 'quests'
        OpenPanel('jobcenter', res, { type = 'jobcenter' })
    end)
end
exports('OpenQuests', OpenQuests)

-- ─────────────────────────────── Déroulement d'une quête ───────────────────────────────
local Q = nil   -- { id, label, steps, idx, blip, gz }

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

local function endQuest(msg, kind)
    if not Q then return end
    if Q.blip and DoesBlipExist(Q.blip) then RemoveBlip(Q.blip) end
    Q = nil
    if msg then Notify(msg, kind or 'info') end
end

local function cancelQuest(msg)
    if not Q then return end
    ServerCall('worldbuilder:jobcenter:questCancel', function() end)
    endQuest(msg or 'Quête annulée.', 'info')
end
RegisterNetEvent('worldbuilder:client:jobcenterCancel', function(msg) endQuest(msg, 'error') end)
RegisterCommand('annulerquete', function() cancelQuest() end, false)

local function groundOf(loc)
    local ok, z = GetGroundZFor_3dCoord(loc.x + 0.0, loc.y + 0.0, loc.z + 50.0, false)
    return ok and z or loc.z
end

local function stepDone()
    local st = Q.steps[Q.idx]
    local id, idx = Q.id, Q.idx
    local res
    ServerCall('worldbuilder:jobcenter:questStep', function(r) res = r or { ok = false } end, id, idx)
    local t = GetGameTimer()
    while not res and GetGameTimer() - t < 7000 do Wait(30) end
    if not Q or Q.id ~= id then return end
    if not res or not res.ok then return cancelQuest((res and res.error) or 'Quête annulée.') end
    if res.done then
        ServerCall('worldbuilder:jobcenter:questFinish', function(f)
            if f and f.ok then
                Notify(('Quête terminée ! ~g~+%s%s~s~%s'):format(f.reward, Config.Currency or '$', f.bonus and f.bonus > 0 and (' (bonus de grade +%d%%)'):format(f.bonus) or ''), 'success')
                if f.promoted then Notify(('Promotion : tu es maintenant ~b~%s~s~ !'):format(f.promoted), 'success') end
            else Notify((f and f.error) or 'Quête non validée', 'error') end
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
    Notify(('Quête : ~b~%s~s~ — suis le GPS.'):format(m.label), 'info')
    setBlip(m.steps[1].loc, m.steps[1].loc.label)
    CreateThread(function()
        local id = Q.id
        while Q and Q.id == id do
            Wait(0)
            local st = Q.steps[Q.idx]
            if st then
                local ped = PlayerPedId()
                local c = GetEntityCoords(ped)
                local d = #(c - vector3(st.loc.x, st.loc.y, c.z))
                if d < 120.0 then Q.gz = Q.gz or groundOf(st.loc) end
                local z = Q.gz or st.loc.z
                text(0.5, 0.045, ('~b~%s~s~ · étape %d/%d'):format(Q.label, Q.idx, #Q.steps), 0.45)
                text(0.5, 0.075, st.label, 0.4, 230, 230, 230)
                if d < 60.0 then DrawMarker(1, st.loc.x + 0.0, st.loc.y + 0.0, z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 1.2, 0, 164, 255, 120, false, false, 2, false, nil, nil, false) end
                if st.t == 'goto' then
                    if d < 3.5 and not IsPedInAnyVehicle(ped, false) then stepDone() end
                elseif d < 3.0 and not Busy then
                    BB.ShowHelp(('Appuie sur ~INPUT_CONTEXT~ : %s'):format(st.label))
                    if IsControlJustReleased(0, Config.InteractKey or 38) then
                        if RunAction({ seconds = st.secs, label = st.label, anim = st.anim, radius = 3.5 }) then stepDone() end
                    end
                end
            end
        end
    end)
end

-- Lancement depuis le panneau (NUI → client) : le serveur construit la quête, le panneau se ferme
NuiLocal.jcStart = function(args, cb)
    ServerCall('worldbuilder:jobcenter:questStart', function(res)
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
