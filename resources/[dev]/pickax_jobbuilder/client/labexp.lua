-- ─────────────────────────────── Laboratoire interactif (client) ──────────────────────────────
-- Caméra au-dessus de la table, interface de jeu à la souris (html/labexp.js). LabExperience(q, session) bloque jusqu'à la fin et renvoie
-- les résultats de chaque étape (nil si annulé). Utilisé par client/lab.lua quand le serveur répond « experience ».
local X = Config.Real.Lab.Experience or {}
local finished, results = false, nil
LabExpActive = false

RegisterNUICallback('labxDone', function(data, cb)
    if LabExpActive then results, finished = data and data.results or nil, true end
    cb({})
end)
RegisterNUICallback('labxAbort', function(_, cb)
    if LabExpActive then results, finished = nil, true end
    cb({})
end)

local function makeCam(q)
    local c = X.Cam or {}
    local h = math.rad(tonumber(q.h) or 0.0)
    local fx, fy = -math.sin(h), math.cos(h)                      -- direction vers laquelle regarde la table
    local dist, height = tonumber(c.distance) or 0.85, tonumber(c.height) or 1.2
    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', q.x - fx * dist, q.y - fy * dist, q.z + height, tonumber(c.pitch) or -64.0, 0.0, 0.0, tonumber(c.fov) or 45.0, false, 0)
    PointCamAtCoord(cam, q.x, q.y, q.z + 0.92)
    SetCamUseShallowDofMode(cam, true)
    SetCamNearDof(cam, 0.15); SetCamFarDof(cam, 2.6); SetCamDofStrength(cam, 0.85)
    return cam
end

function LabExperience(q, session)
    if LabExpActive then return nil end
    LabExpActive, finished, results = true, false, nil
    local ped = PlayerPedId()
    local radarWasOff = IsRadarHidden()
    FreezeEntityPosition(ped, true)
    local cam = makeCam(q)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 700, true, true)
    DisplayRadar(false)
    Wait(750)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'labx', cmd = 'start', session = session })
    while not finished do
        Wait(150)
        local p = PlayerPedId()
        if IsEntityDead(p) or IsPedRagdoll(p) or IsPedInAnyVehicle(p, false) then
            SendNUIMessage({ action = 'labx', cmd = 'abort' }); results, finished = nil, true
        end
    end
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'labx', cmd = 'abort' })
    RenderScriptCams(false, true, 600, true, true)
    Wait(620)
    DestroyCam(cam, false)
    FreezeEntityPosition(PlayerPedId(), false)
    if not radarWasOff then DisplayRadar(true) end
    LabExpActive = false
    return results
end
