-- ─────────────────────────────── Laboratoires (client) ───────────────────────────────
-- Équipement du laboratoire (serres, tables de traitement, zones de tenue) : objets locaux, interaction E, intoxication sans la tenue.
local L = Config.Real.Lab
local T = L.Toxic
local Equip = {}        -- liste reçue du serveur
local Objs = {}         -- [id] = { ent, model }
local busy = false

for _, n in ipairs({ 'lab:list', 'lab:remove' }) do NuiRemote[n] = true end

-- ─────────────────────────────── Tenue ───────────────────────────────
local COMP_NAME = { [1] = 'masque', [3] = 'torse', [4] = 'pantalon', [6] = 'chaussures', [7] = 'accessoire', [8] = 'haut', [9] = 'gilet', [11] = 'veste' }
local PROP_NAME = { [0] = 'chapeau', [1] = 'lunettes' }

local function pedSex()
    local m = GetEntityModel(PlayerPedId())
    if m == joaat('mp_m_freemode_01') then return 'male' end
    if m == joaat('mp_f_freemode_01') then return 'female' end
end

-- true si le joueur porte la tenue exigée (def = { male = {...}, female = {...} }) ; sinon false + pièces manquantes
local function outfitOK(def)
    if not def then return true end
    local sex = pedSex()
    if not sex then return false, { 'tenue compatible' } end
    local list = def[sex]
    if not list or #list == 0 then return true end
    local ped, missing = PlayerPedId(), {}
    for _, r in ipairs(list) do
        if r.k == 'p' then
            if GetPedPropIndex(ped, r.id) ~= r.d then missing[#missing + 1] = PROP_NAME[r.id] or ('accessoire ' .. r.id) end
        else
            if GetPedDrawableVariation(ped, r.id) ~= r.d then missing[#missing + 1] = COMP_NAME[r.id] or ('pièce ' .. r.id) end
        end
    end
    return #missing == 0, missing
end

-- Capture de la tenue portée : { male = {...} } ou { female = {...} }
local function captureOutfit()
    local sex = pedSex()
    if not sex then return nil end
    local ped, list = PlayerPedId(), {}
    for _, id in ipairs({ 1, 3, 4, 6, 7, 8, 9, 11 }) do
        local d = GetPedDrawableVariation(ped, id)
        if d ~= 0 then list[#list + 1] = { k = 'c', id = id, d = d } end
    end
    for _, id in ipairs({ 0, 1 }) do
        local d = GetPedPropIndex(ped, id)
        if d >= 0 then list[#list + 1] = { k = 'p', id = id, d = d } end
    end
    return { [sex] = list }, sex, #list
end

-- Zone de tenue qui couvre une position (nil si aucune)
local function zoneAt(pos)
    for _, q in ipairs(Equip) do
        if q.kind == 'outfit' and #(pos - vector3(q.x, q.y, q.z)) <= (q.radius or 10.0) then return q end
    end
end

-- ─────────────────────────────── Objets ───────────────────────────────
local function modelFor(q)
    if q.kind == 'table' then return L.Models.table end
    if q.kind == 'greenhouse' then
        if q.state == 'growing' or q.state == 'ready' then
            local i = q.state == 'ready' and 3 or ((q.pct or 0) >= 50 and 2 or 1)
            local m = L.Models.stages[i]
            if m and IsModelInCdimage(joaat(m)) then return m end
            return L.Models.stageFallback[i]
        end
        return L.Models.greenhouse
    end
end

local function clearObjs()
    for id, o in pairs(Objs) do if DoesEntityExist(o.ent) then DeleteEntity(o.ent) end Objs[id] = nil end
end

local function syncObjs()
    local keep = {}
    for _, q in ipairs(Equip) do
        local m = modelFor(q)
        if m then
            keep[q.id] = true
            local o = Objs[q.id]
            if o and o.model ~= m then if DoesEntityExist(o.ent) then DeleteEntity(o.ent) end Objs[q.id] = nil o = nil end
            if not o then
                local hash = LoadModelJB and LoadModelJB(m) or nil
                if not hash and q.kind == 'table' then hash = LoadModelJB('prop_table_03') end
                if hash then
                    local e = CreateObjectNoOffset(hash, q.x + 0.0, q.y + 0.0, q.z + 0.0, false, false, false)
                    SetEntityHeading(e, (q.h or 0.0) + 0.0)
                    FreezeEntityPosition(e, true)
                    SetModelAsNoLongerNeeded(hash)
                    Objs[q.id] = { ent = e, model = m }
                end
            end
        end
    end
    for id, o in pairs(Objs) do
        if not keep[id] then if DoesEntityExist(o.ent) then DeleteEntity(o.ent) end Objs[id] = nil end
    end
end

function LabSet(list)
    Equip = list or {}
    if JBInside and JBInside() then syncObjs() else clearObjs() end
end

function LabClear()
    Equip = {}
    clearObjs()
end

RegisterNetEvent('jobbuilder:client:lab', function(list) LabSet(list) end)
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then clearObjs() ClearTimecycleModifier() StopGameplayCamShaking(true) end
end)

-- ─────────────────────────────── Interaction ───────────────────────────────
local function text3D(x, y, z, text)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.0, 0.32) SetTextFont(4) SetTextCentre(true) SetTextOutline() SetTextColour(255, 255, 255, 235)
    BeginTextCommandDisplayText('STRING') AddTextComponentSubstringPlayerName(text) EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function help(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

local function progress(label, seconds, scenario)
    local ped = PlayerPedId()
    local origin = GetEntityCoords(ped)
    TaskStartScenarioInPlace(ped, scenario, 0, true)
    local start, total, ok = GetGameTimer(), math.floor(seconds * 1000), true
    while GetGameTimer() - start < total do
        Wait(0)
        ped = PlayerPedId()
        for _, k in ipairs({ 24, 25, 140, 141, 142 }) do DisableControlAction(0, k, true) end
        local f = (GetGameTimer() - start) / total
        DrawRect(0.5, 0.88, 0.2, 0.026, 0, 0, 0, 170)
        DrawRect(0.5 - 0.1 * (1 - f), 0.88, 0.2 * f, 0.02, 253, 194, 125, 230)
        SetTextScale(0.0, 0.34) SetTextFont(4) SetTextCentre(true) SetTextOutline()
        BeginTextCommandDisplayText('STRING') AddTextComponentSubstringPlayerName(label .. '  ·  X pour annuler') EndTextCommandDisplayText(0.5, 0.845)
        if IsControlJustPressed(0, 73) or IsEntityDead(ped) or IsPedRagdoll(ped) or #(GetEntityCoords(ped) - origin) > 3.5 then ok = false break end
    end
    ClearPedTasks(PlayerPedId())
    return ok
end

local SCEN = { plant = 'WORLD_HUMAN_GARDENER_PLANT', harvest = 'WORLD_HUMAN_GARDENER_PLANT', process = 'WORLD_HUMAN_CLIPBOARD' }

local function use(q)
    if busy then return end
    local pos = GetEntityCoords(PlayerPedId())
    -- dans une zone de tenue : la tenue est obligatoire pour travailler
    local z = zoneAt(pos)
    if z then
        local ok, missing = outfitOK(z.outfit)
        if not ok then return JBNotify('~r~Tenue obligatoire dans cette zone : ' .. table.concat(missing, ', ') .. '.') end
    end
    busy = true
    ESX.TriggerServerCallback('jobbuilder:lab:begin', function(res)
        if not res or not res.ok then busy = false return JBNotify('~r~' .. ((res and res.error) or 'Impossible')) end
        CreateThread(function()
            local done = progress(res.label, res.seconds, SCEN[res.sub] or 'WORLD_HUMAN_CLIPBOARD')
            if done and z and not outfitOK(z.outfit) then done = false JBNotify('~r~Tenue retirée : action annulée.') end
            if not done then TriggerServerEvent('jobbuilder:lab:cancel') busy = false return end
            ESX.TriggerServerCallback('jobbuilder:lab:finish', function(r)
                busy = false
                if r and r.ok then JBNotify(r.message or 'Terminé.') else JBNotify('~r~' .. ((r and r.error) or 'Erreur')) end
            end)
        end)
    end, q.id)
end

CreateThread(function()
    while true do
        local sleep = 1000
        if JBInside and JBInside() and #Equip > 0 and not IsUIOpen() and not IsPlacing() then
            local pos = GetEntityCoords(PlayerPedId())
            local nearest, nd
            for _, q in ipairs(Equip) do
                local d = #(pos - vector3(q.x, q.y, q.z))
                if d < 25.0 then
                    sleep = 0
                    if q.kind == 'outfit' then
                        DrawMarker(1, q.x, q.y, q.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, (q.radius or 10.0) * 2.0, (q.radius or 10.0) * 2.0, 0.6, 255, 140, 60, 35, false, false, 2, false, nil, nil, false)
                        if d < (q.radius or 10.0) then text3D(q.x, q.y, q.z + 1.2, 'Zone contaminée : tenue obligatoire') end
                    else
                        BB.DrawMarker(nil, { x = q.x, y = q.y, z = q.z })
                        local what = q.kind == 'greenhouse' and ('Serre — ' .. (q.drugLabel or '')) or ('Table — ' .. (q.drugLabel or ''))
                        if q.kind == 'greenhouse' then
                            what = what .. (q.state == 'growing' and (' · pousse : %d %%'):format(q.pct or 0) or q.state == 'ready' and ' · prête à récolter' or ' · vide')
                        end
                        if d < 8.0 then text3D(q.x, q.y, q.z + 1.1, what) end
                        if d < 1.8 and (not nd or d < nd) then nearest, nd = q, d end
                    end
                end
            end
            if nearest then
                local msg = nearest.kind == 'table' and 'Appuie sur ~INPUT_CONTEXT~ : traiter le produit'
                    or nearest.state == 'empty' and 'Appuie sur ~INPUT_CONTEXT~ : planter une graine'
                    or nearest.state == 'ready' and 'Appuie sur ~INPUT_CONTEXT~ : récolter'
                    or nil
                if msg then
                    help(msg)
                    if IsControlJustReleased(0, 38) then use(nearest) end
                end
            end
        end
        Wait(sleep)
    end
end)

-- ─────────────────────────────── Installation (menu Décoration → Laboratoire) ───────────────────────────────
local function reopen() if OpenFurnitureMenu then OpenFurnitureMenu() end end

NuiLocal['lab:place'] = function(args, cb)
    cb({ ok = true })
    CloseUI()
    local kind, drug, radius = args[1], args[2], tonumber(args[3])
    CreateThread(function()
        local model = kind == 'table' and L.Models.table or kind == 'greenhouse' and L.Models.greenhouse or 'prop_roadcone02a'
        local outfit
        if kind == 'outfit' then
            local o, sex, n = captureOutfit()
            if not o then JBNotify('~r~Il faut un personnage homme ou femme pour enregistrer la tenue.') return reopen() end
            outfit = o
            JBNotify(('Tenue %s enregistrée pour cette zone (%d pièce%s).'):format(sex == 'male' and 'homme' or 'femme', n, n > 1 and 's' or ''))
        end
        local r = GhostPlace(model, kind == 'outfit' and 'Zone de tenue obligatoire' or (kind == 'table' and 'Table de traitement' or 'Serre'), nil, kind == 'outfit' and (radius or L.OutfitRadius.default) or nil)
        if not r then return reopen() end
        ESX.TriggerServerCallback('jobbuilder:lab:place', function(res)
            if res and res.ok then JBNotify('Équipement installé.') else JBNotify('~r~' .. ((res and res.error) or 'Erreur')) end
            reopen()
        end, kind, drug, r, radius, outfit)
    end)
end

NuiLocal['lab:outfit'] = function(args, cb)
    local o, sex, n = captureOutfit()
    if not o then return cb({ ok = false, error = 'Il faut un personnage homme ou femme' }) end
    ESX.TriggerServerCallback('jobbuilder:lab:setOutfit', function(res)
        if res and res.ok then JBNotify(('Tenue %s mise à jour (%d pièce%s).'):format(sex == 'male' and 'homme' or 'femme', n, n > 1 and 's' or '')) end
        cb(res or { ok = false, error = 'Erreur' })
    end, args[1], o)
end

-- ─────────────────────────────── Intoxication ───────────────────────────────
local level, warnedZone = 0, false

CreateThread(function()
    while true do
        local sleep = 1500
        if T.Enabled and JBInside and JBInside() and #Equip > 0 then
            local ped = PlayerPedId()
            if not IsEntityDead(ped) then
                local z = zoneAt(GetEntityCoords(ped))
                if z and not outfitOK(z.outfit) then
                    sleep = T.Tick * 1000
                    TriggerServerEvent('jobbuilder:server:labExposure')
                    if not warnedZone then warnedZone = true JBNotify('~r~Zone contaminée : porte la tenue de protection, sinon tu t\'intoxiques !') end
                else
                    warnedZone = false
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('jobbuilder:client:toxic', function(l) level = tonumber(l) or 0 end)
RegisterNetEvent('jobbuilder:client:toxicCured', function()
    level = 0
    ClearTimecycleModifier()
    StopGameplayCamShaking(true)
    ClearPedTasks(PlayerPedId())
end)

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
            SetTextScale(0.0, 0.34) SetTextFont(4) SetTextOutline() SetTextColour(255, 120, 120, 230)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(('Intoxication : %d %%'):format(level))
            EndTextCommandDisplayText(0.012, 0.62)
            Wait(0)
        else
            if shaking then shaking = false ClearTimecycleModifier() StopGameplayCamShaking(true) end
            Wait(1000)
        end
    end
end)
