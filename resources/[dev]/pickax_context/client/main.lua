local C = Config

-- mode : 'idle' (rien) · 'cursor' (touche maintenue, curseur libre) · 'menu' (un menu est affiché)
local mode = 'idle'
local holdOpen = false          -- ouvert par la touche maintenue (sinon : par /moi)
local aim = { x = 0.5, y = 0.5 }
local armed = true              -- le survol du personnage rouvre le menu seulement après être sorti de lui
local openedAt = 0
local menuSelf = false
local lastAim = 0

local function notify(msg) TriggerEvent('esx:showNotification', msg) end

-- ───────── ce qu'il y a sous le curseur ─────────
local function rayAt(x, y, dist)
    local pos = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(0)
    local fov = GetGameplayCamFov()
    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, fov, 0, 2)
    local right, forward, up, camPos = GetCamMatrix(cam)
    DestroyCam(cam, true)
    local sx, sy = (x - 0.5) * 2.0, (y - 0.5) * 2.0
    local fovRad = (fov * 3.14) / 180.0
    local to = camPos + forward + (right * sx * fovRad * GetAspectRatio(false) * 0.534375) - (up * sy * fovRad * 0.534375)
    local endPoint = camPos + (to - camPos) * dist
    local ray = StartShapeTestRay(camPos.x, camPos.y, camPos.z, endPoint.x, endPoint.y, endPoint.z, -1, 0, 0)
    local _, hit, coords, _, ent = GetShapeTestResult(ray)
    if hit == 1 then return ent, coords end
    return nil, nil
end

local function isSelf(ent)
    local ped = PlayerPedId()
    if ent == ped then return true end
    local veh = GetVehiclePedIsIn(ped, false)
    return veh ~= 0 and ent == veh
end

-- ───────── personnage semi-transparent pendant que le menu « Moi » est ouvert ─────────
local function ghost(on)
    local ped = PlayerPedId()
    if on then SetEntityAlpha(ped, C.GhostAlpha or 140, false) else ResetEntityAlpha(ped) end
end

-- ───────── ouverture / fermeture ─────────
local function hideMenu()
    if mode ~= 'menu' then return end
    mode = holdOpen and 'cursor' or 'idle'
    if menuSelf then ghost(false) menuSelf = false end
    SendNUIMessage({ a = 'hide' })
    if not holdOpen then
        SetNuiFocusKeepInput(false)
        SetNuiFocus(false, false)
        SendNUIMessage({ a = 'close' })
    end
end

local function stopAll()
    if mode == 'idle' then return end
    if menuSelf then ghost(false) menuSelf = false end
    mode, holdOpen = 'idle', false
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    SendNUIMessage({ a = 'close' })
end

local function openFor(ent, coords, self_, atX, atY)
    -- Les actions (moi, véhicule, joueur, passant, objet…) viennent de pickax_core/players/contextMenu : mêmes conditions et sous-menus qu'avant.
    local ok, tree = pcall(function() return exports.pickax_core:ContextBuildTarget(ent, coords) end)
    if not ok or type(tree) ~= 'table' or #tree == 0 then
        local why = (not ok) and tostring(tree) or 'menu vide'
        print(('^1[pickax_context] impossible de construire le menu : %s^0'):format(why))
        if GetResourceState('pickax_core') ~= 'started' then why = 'pickax_core n\'est pas démarré' end
        notify('~r~Menu contextuel indisponible~s~ (' .. why:sub(1, 80) .. ') — voir la console F8')
        return false
    end
    mode = 'menu'
    openedAt = GetGameTimer()
    menuSelf = self_ == true
    if menuSelf then ghost(true) end
    SendNUIMessage({ a = 'open', menu = tree, x = atX, y = atY, offset = 14, hold = holdOpen })
    return true
end

local function startCursor()
    if mode ~= 'idle' or IsPauseMenuActive() or IsNuiFocused() then return end
    if IsEntityDead(PlayerPedId()) then return end
    mode, holdOpen, armed = 'cursor', true, true
    openedAt = GetGameTimer()
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)      -- le clavier reste au jeu : on peut avancer, courir, conduire pendant que le curseur est libre
    SendNUIMessage({ a = 'cursor', hold = true })
end

-- Surveille ce qui est sous le curseur : le personnage -> ouvre « Moi »
CreateThread(function()
    while true do
        if mode == 'cursor' then
            local ent, coords = rayAt(aim.x, aim.y, 25.0)
            if ent and isSelf(ent) then
                if armed then
                    if openFor(PlayerPedId(), GetEntityCoords(PlayerPedId()), true, aim.x, aim.y) then armed = false end
                end
            else
                armed = true
            end
            Wait(50)
        else Wait(200) end
    end
end)

-- touche maintenue : curseur libre ; relâcher : tout se ferme
if C.HoldToShow then
    RegisterCommand('+pickax_context', function() startCursor() end, false)
    RegisterCommand('-pickax_context', function()
        -- ignore le « relâchement » parasite émis quand l'interface prend le focus
        if mode ~= 'idle' and GetGameTimer() - openedAt > 250 then stopAll() end
    end, false)
    if C.Key and C.Key ~= '' then RegisterKeyMapping('+pickax_context', 'Menu contextuel (maintenir)', 'keyboard', C.Key) end
else
    RegisterCommand('pickax_context_toggle', function() if mode == 'idle' then startCursor() else stopAll() end end, false)
    if C.Key and C.Key ~= '' then RegisterKeyMapping('pickax_context_toggle', 'Menu contextuel', 'keyboard', C.Key) end
end

-- /moi : ouvre directement le menu « Moi » (sans curseur à viser) ; Échap / clic à côté pour fermer
RegisterCommand(C.Command, function()
    if mode ~= 'idle' then stopAll() return end
    if IsPauseMenuActive() or IsNuiFocused() or IsEntityDead(PlayerPedId()) then return end
    holdOpen = false
    SetNuiFocus(true, true)
    local c = GetEntityCoords(PlayerPedId())
    local on, x, y = GetScreenCoordFromWorldCoord(c.x, c.y, c.z + 0.3)
    if not openFor(PlayerPedId(), c, true, on and x + 0.04 or 0.5, on and y or 0.5) then SetNuiFocus(false, false) end
end, false)

exports('Close', stopAll)
AddEventHandler('pickax_context:closeRequest', function() if mode == 'menu' then hideMenu() end end)   -- envoyé par les actions qui ferment le menu

-- ───────── retours de l'interface ─────────
RegisterNUICallback('close', function(_, cb) cb(1) stopAll() end)
RegisterNUICallback('aim', function(d, cb)
    cb(1)
    aim.x, aim.y = tonumber(d and d.x) or 0.5, tonumber(d and d.y) or 0.5
end)
-- clic sur le décor : menu de l'élément cliqué (véhicule, joueur, passant, objet…) ; rien : environnement
RegisterNUICallback('click', function(d, cb)
    cb(1)
    if mode == 'menu' and holdOpen then hideMenu() end   -- un clic hors du menu le referme (comme avant)
    if mode ~= 'cursor' then return end
    local x, y = tonumber(d and d.x) or 0.5, tonumber(d and d.y) or 0.5
    local ent, coords = rayAt(x, y, 25.0)
    if ent and isSelf(ent) then return end
    if ent and ent ~= 0 and DoesEntityExist(ent) then openFor(ent, coords, false, x, y)
    elseif coords then openFor(nil, coords, false, x, y) end
end)
RegisterNUICallback('run', function(d, cb)
    local ok, r = pcall(function() return exports.pickax_core:ContextRun(d and d.k) end)
    r = ok and type(r) == 'table' and r or {}
    cb({ checked = r.checked })
    if r.close then hideMenu() end
end)

-- La souris sert à viser : pas de caméra, de tir ni de changement d'arme. Les déplacements (ZQSD, course, saut, conduite) restent actifs.
CreateThread(function()
    while true do
        if mode ~= 'idle' then
            for _, c in ipairs({ 1, 2, 14, 15, 16, 17, 24, 25, 37, 44, 45, 68, 69, 70, 91, 92, 140, 141, 142, 257, 263, 264 }) do DisableControlAction(0, c, true) end
            Wait(0)
        else Wait(400) end
    end
end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then stopAll() ResetEntityAlpha(PlayerPedId()) end end)
