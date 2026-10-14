-- ─────────────────────────────── Atelier tuning (client) : aperçu en direct, caméra orbitale, facturation ───────────────────────────────
NuiRemote['tuning:validate'] = true

local MODS, TOG = Config.Tuning.Mods, Config.Tuning.Toggles
local LEVEL_TYPES = { [11] = true, [12] = true, [13] = true, [15] = true, [16] = true }   -- moteur, freins, transmission, suspension, blindage : niveaux, pas de libellés
local active = nil

local function txt(l)
    if not l or l == '' then return nil end
    local t = GetLabelText(l)
    if t and t ~= '' and t ~= 'NULL' then return t end
end

local function copy(t)
    if type(t) ~= 'table' then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = copy(v) end
    return o
end

-- ── Lecture / application des propriétés (noms ESX) ──
local function readState(veh)
    SetVehicleModKit(veh, 0)
    local st = {}
    for k, t in pairs(MODS) do st[k] = GetVehicleMod(veh, t) end
    for k, t in pairs(TOG) do st[k] = IsToggleModOn(veh, t) and true or false end
    st.plateIndex = GetVehicleNumberPlateTextIndex(veh)
    local c1, c2 = GetVehicleColours(veh)
    st.color1, st.color2 = c1, c2
    local pearl, wheel = GetVehicleExtraColours(veh)
    st.pearlescentColor, st.wheelColor = pearl, wheel
    st.wheels = GetVehicleWheelType(veh)
    st.windowTint = GetVehicleWindowTint(veh)
    st.neonEnabled = { IsVehicleNeonLightEnabled(veh, 0) and true or false, IsVehicleNeonLightEnabled(veh, 1) and true or false, IsVehicleNeonLightEnabled(veh, 2) and true or false, IsVehicleNeonLightEnabled(veh, 3) and true or false }
    local r, g, b = GetVehicleNeonLightsColour(veh)
    st.neonColor = { r, g, b }
    local sr, sg, sb = GetVehicleTyreSmokeColor(veh)
    st.tyreSmokeColor = { sr, sg, sb }
    st.xenonColor = GetVehicleXenonLightsColor(veh)
    st.livery = GetVehicleLivery(veh)
    return st
end

local function applyKey(veh, key, value, st)
    SetVehicleModKit(veh, 0)
    if MODS[key] then
        local t = MODS[key]
        SetVehicleMod(veh, t, value, (t == 23 or t == 24) and GetVehicleModVariation(veh, t) or false)
    elseif TOG[key] then ToggleVehicleMod(veh, TOG[key], value)
    elseif key == 'plateIndex' then SetVehicleNumberPlateTextIndex(veh, value)
    elseif key == 'color1' or key == 'color2' then SetVehicleColours(veh, st.color1, st.color2)
    elseif key == 'pearlescentColor' or key == 'wheelColor' then SetVehicleExtraColours(veh, st.pearlescentColor, st.wheelColor)
    elseif key == 'wheels' then SetVehicleWheelType(veh, value)
    elseif key == 'windowTint' then SetVehicleWindowTint(veh, value)
    elseif key == 'neonEnabled' then for i = 0, 3 do SetVehicleNeonLightEnabled(veh, i, value[i + 1] and true or false) end
    elseif key == 'neonColor' then SetVehicleNeonLightsColour(veh, value[1], value[2], value[3])
    elseif key == 'tyreSmokeColor' then SetVehicleTyreSmokeColor(veh, value[1], value[2], value[3])
    elseif key == 'xenonColor' then SetVehicleXenonLightsColor(veh, value)
    elseif key == 'livery' then if value >= 0 then SetVehicleLivery(veh, value) end end
end

local function modOptions(veh, key)
    SetVehicleModKit(veh, 0)
    local t = MODS[key]
    local n = t and GetNumVehicleMods(veh, t) or 0
    local labels = {}
    if n > 0 and not LEVEL_TYPES[t] then
        for i = 0, n - 1 do labels[i + 1] = txt(GetModTextLabel(veh, t, i)) or ('Option ' .. (i + 1)) end
    end
    return { n = n, labels = labels }
end

local function buildMods(veh)
    local mods = {}
    for key in pairs(MODS) do
        local o = modOptions(veh, key)
        if o.n > 0 then mods[key] = o end
    end
    mods.livery = { n = math.max(0, GetVehicleLiveryCount(veh)), labels = {} }
    return mods
end

local function findVehicle(coords, radius)
    local cur = GetVehiclePedIsIn(PlayerPedId(), false)
    if cur ~= 0 then return cur end
    local best, bd = nil, (radius or 6.0) + 0.0
    local c = vector3(coords.x, coords.y, coords.z)
    for _, v in ipairs(GetGamePool('CVehicle')) do
        local d = #(GetEntityCoords(v) - c)
        if d <= bd then best, bd = v, d end
    end
    return best
end

-- ── Caméra orbitale autour du véhicule ──
local function startCam(a)
    local model = GetEntityModel(a.veh)
    local mn, mx = GetModelDimensions(model)
    a.dist = math.max(4.5, (mx.y - mn.y) * 1.5 + 1.5)
    a.minDist, a.maxDist = a.dist * 0.55, a.dist * 1.8
    a.angle, a.pitch = GetEntityHeading(a.veh) + 145.0, 14.0
    a.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(a.cam, 55.0)
    RenderScriptCams(true, true, 700, true, false)
    CreateThread(function()
        local cx, cy, cz
        while active == a do
            local c = GetEntityCoords(a.veh)
            local pr, ar = math.rad(a.pitch), math.rad(a.angle)
            local tx, ty, tz = c.x + math.sin(ar) * a.dist * math.cos(pr), c.y + math.cos(ar) * a.dist * math.cos(pr), c.z + 0.6 + math.sin(pr) * a.dist
            cx, cy, cz = (cx or tx) + (tx - (cx or tx)) * 0.2, (cy or ty) + (ty - (cy or ty)) * 0.2, (cz or tz) + (tz - (cz or tz)) * 0.2
            SetCamCoord(a.cam, cx, cy, cz)
            PointCamAtCoord(a.cam, c.x, c.y, c.z + 0.35)
            DisableAllControlActions(0)
            Wait(0)
        end
    end)
end

local function closeTuning(revert)
    local a = active
    if not a then return end
    if revert then
        for k, v in pairs(a.snapshot) do applyKey(a.veh, k, v, a.snapshot) end
    end
    active = nil
    if a.cam then
        RenderScriptCams(false, true, 500, true, false)
        DestroyCam(a.cam, false)
    end
    if DoesEntityExist(a.veh) then
        FreezeEntityPosition(a.veh, a.wasFrozen or false)
        SetVehicleLights(a.veh, 0)
    end
end

function OpenTuning(point, res)
    local veh = findVehicle(point.coords, res.radius)
    if not veh or veh == 0 then return JBNotify('~r~Aucun véhicule à customiser dans l\'atelier : gare-le sur le marker.') end
    local tries = 0
    while not NetworkHasControlOfEntity(veh) and tries < 30 do NetworkRequestControlOfEntity(veh) tries = tries + 1 Wait(30) end
    local state = readState(veh)
    active = { veh = veh, point = point.id, snapshot = copy(state), state = state, waiting = false, wasFrozen = IsEntityPositionFrozen(veh) }
    FreezeEntityPosition(veh, true)
    SetVehicleLights(veh, 2)
    startCam(active)
    local model = GetEntityModel(veh)
    local name = txt(GetDisplayNameFromVehicleModel(model)) or GetDisplayNameFromVehicleModel(model)
    OpenUI({ action = 'open', kind = 'tuning', pointId = point.id, data = {
        ok = true, label = res.label, jobLabel = res.jobLabel, prices = res.prices, markup = res.markup, billing = res.billing,
        vehicle = { name = name, plate = GetVehicleNumberPlateText(veh), bike = IsThisModelABike(model) and true or false },
        state = copy(state), mods = buildMods(veh),
    } })
end

-- ── Appels depuis le NUI ──
NuiLocal['tuning:preview'] = function(args, cb)
    local a = active
    if not a or not DoesEntityExist(a.veh) then return cb({ ok = false }) end
    local key, value = args[1], args[2]
    a.state[key] = value
    applyKey(a.veh, key, value, a.state)
    cb({ ok = true })
end

NuiLocal['tuning:mods'] = function(args, cb)
    local a = active
    if not a then return cb({ n = 0, labels = {} }) end
    cb(modOptions(a.veh, args[1]))
end

NuiLocal['tuning:cam'] = function(args, cb)
    local a = active
    if a then
        a.angle = a.angle - (tonumber(args[1]) or 0) * 0.45
        a.pitch = math.max(2.0, math.min(65.0, a.pitch + (tonumber(args[2]) or 0) * 0.3))
        a.dist = math.max(a.minDist, math.min(a.maxDist, a.dist + (tonumber(args[3]) or 0) * 0.01 * a.dist))
    end
    cb({ ok = true })
end

NuiLocal['tuning:revert'] = function(_, cb)
    local a = active
    if not a then return cb({ ok = false }) end
    for k, v in pairs(a.snapshot) do applyKey(a.veh, k, v, a.snapshot) end
    a.state = copy(a.snapshot)
    cb({ ok = true, state = copy(a.state), mods = buildMods(a.veh) })
end

NuiLocal['tuning:waiting'] = function(args, cb)
    if active then
        active.waiting = args[1] == true
        if active.waiting then SetTimeout(85000, function() if active and active.waiting then active.waiting = false end end) end
    end
    cb({ ok = true })
end

-- Validation acceptée (société / gratuit) : le véhicule garde ses modifications
NuiLocal['tuning:finish'] = function(_, cb)
    closeTuning(false)
    CloseUI()
    JBNotify('~g~Customisation terminée.')
    cb({ ok = true })
end

-- Fermeture : on annule l'aperçu (sauf attente du paiement du client)
local baseClose = NuiLocal.close
NuiLocal.close = function(a, cb)
    if active then
        if active.waiting then
            JBNotify('Attends la réponse du client avant de fermer la tablette.')
            return cb({ ok = false })
        end
        closeTuning(true)
    end
    baseClose(a, cb)
end

RegisterNetEvent('jobbuilder:client:tuningResult', function(r)
    local a = active
    JBNotify((r.ok and '~g~' or '~r~') .. (r.msg or ''))
    if not a then return end
    a.waiting = false
    if r.ok then
        a.snapshot = copy(a.state)
        SendNUIMessage({ action = 'tuningResult', ok = true, msg = r.msg })
    else
        for k, v in pairs(a.snapshot) do applyKey(a.veh, k, v, a.snapshot) end
        a.state = copy(a.snapshot)
        SendNUIMessage({ action = 'tuningResult', ok = false, msg = r.msg, state = copy(a.state) })
    end
end)

-- Sécurité : le mécano meurt ou le véhicule disparaît
CreateThread(function()
    while true do
        Wait(700)
        if active and (IsEntityDead(PlayerPedId()) or not DoesEntityExist(active.veh)) then
            closeTuning(true)
            CloseUI()
        end
    end
end)
