-- /clothshots <pièce> [de] [à] : photographie chaque vêtement (numéro par numéro) sur ton personnage devant la caméra. Admin + « screenshot-basic ».
local running, acked, goOk, goMsg = false, false, nil, ''
local CAM = { tshirt = 0.55, torso = 0.55, arms = 0.6, bproof = 0.55, decals = 0.6, pants = 0.45, shoes = 0.35, helmet = 0.4, glasses = 0.35, ears = 0.35, mask = 0.35, chain = 0.45, bags = 0.6, watches = 0.35, bracelets = 0.35 }
local ZOFF = { tshirt = 0.3, torso = 0.3, arms = 0.25, bproof = 0.3, decals = 0.3, pants = -0.45, shoes = -0.85, helmet = 0.7, glasses = 0.68, ears = 0.65, mask = 0.68, chain = 0.45, bags = 0.25, watches = 0.0, bracelets = 0.0 }

RegisterNetEvent('pickax_shopbuilder:clothshotGo', function(ok, msg) goOk, goMsg = ok, msg end)
RegisterNetEvent('pickax_shopbuilder:clothshotAck', function() acked = true end)

-- Message visible en jeu (chat + notification) et dans la console F8 : sans ça, une erreur passait inaperçue
local function say(msg, bad)
    print((bad and '^1' or '^2') .. '[clothshots] ' .. msg .. '^0')
    pcall(function() TriggerEvent('chat:addMessage', { color = bad and { 239, 68, 68 } or { 74, 222, 128 }, args = { 'clothshots', msg } }) end)
    pcall(function() BeginTextCommandThefeedPost('STRING'); AddTextComponentSubstringPlayerName(msg); EndTextCommandThefeedPostTicker(false, false) end)
end

local function getSkin() local s; TriggerEvent('skinchanger:getSkin', function(x) s = x end); local t = GetGameTimer() + 2000; while not s and GetGameTimer() < t do Wait(10) end; return s end

RegisterCommand('clothshots', function(_, args)
    if running then return end
    local piece = args[1]
    if not piece or not CAM[piece] then return say('Usage : /clothshots <' .. table.concat((function() local t = {} for k in pairs(CAM) do t[#t + 1] = k end table.sort(t) return t end)(), '|') .. '> [de] [à]', true) end
    say('Vérification en cours…')
    goOk = nil; TriggerServerEvent('pickax_shopbuilder:clothshotCheck')
    local w = GetGameTimer() + 3000; while goOk == nil and GetGameTimer() < w do Wait(20) end
    if not goOk then return say(tostring(goMsg ~= '' and goMsg or 'Pas de réponse du serveur : la ressource pickax_shopbuilder est-elle à jour et redémarrée ?'), true) end
    local skin = getSkin(); if not skin then return say('skinchanger indisponible.', true) end
    local snap = json.decode(json.encode(skin)); local sex = (tonumber(skin.sex) == 1) and 'f' or 'm'
    local maxv
    TriggerEvent('skinchanger:getData', function(_, mv) maxv = mv end); local t0 = GetGameTimer() + 2000; while not maxv and GetGameTimer() < t0 do Wait(10) end
    local key = piece == 'arms' and 'arms' or (piece .. '_1')
    local top = tonumber(maxv and maxv[key]) or 0
    local from, to = tonumber(args[2]) or 0, tonumber(args[3]) or top
    running = true
    local ped = PlayerPedId(); FreezeEntityPosition(ped, true)
    local pos, fwd = GetEntityCoords(ped), GetEntityForwardVector(ped)
    local target = vector3(pos.x, pos.y, pos.z + ZOFF[piece])
    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', pos.x + fwd.x * CAM[piece] * 2.2, pos.y + fwd.y * CAM[piece] * 2.2, target.z, 0.0, 0.0, 0.0, 35.0, false, 0)
    PointCamAtCoord(cam, target.x, target.y, target.z); SetCamActive(cam, true); RenderScriptCams(true, false, 0, true, true)
    say(('%s : %d → %d (%s) — /clothshotsstop pour arrêter'):format(piece, from, to, sex))
    for v = from, to do
        TriggerEvent('skinchanger:change', key, v); if piece ~= 'arms' then TriggerEvent('skinchanger:change', piece .. '_2', 0) end
        Wait(350); acked = false
        TriggerServerEvent('pickax_shopbuilder:clothshot', sex, piece, v)
        local t1 = GetGameTimer() + 8000; while not acked and GetGameTimer() < t1 do Wait(20) end
        if not running then break end
    end
    RenderScriptCams(false, false, 0, true, true); DestroyCam(cam, false); FreezeEntityPosition(ped, false)
    TriggerEvent('skinchanger:loadSkin', snap); running = false
    say('terminé.')
end, false)
RegisterCommand('clothshotsstop', function() running = false end, false)
