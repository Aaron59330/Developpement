local C = Config
local open = false
local openedAt = 0

-- ───────── ouverture / fermeture ─────────
local function close()
    if not open then return end
    open = false
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    SendNUIMessage({ a = 'close' })
end

local function openMenu()
    if open or IsPauseMenuActive() or IsNuiFocused() then return end
    local ped = PlayerPedId()
    -- Les actions (moi, véhicule, joueur, passant, objet…) viennent de pickax_core/players/contextMenu : même logique, conditions et sous-menus qu'avant.
    local ok, tree = pcall(function() return exports.pickax_core:ContextBuild() end)
    if not ok or type(tree) ~= 'table' or #tree == 0 then
        local why = (not ok) and tostring(tree) or 'menu vide'
        print(('^1[pickax_context] impossible de construire le menu : %s^0'):format(why))
        if GetResourceState('pickax_core') ~= 'started' then why = 'pickax_core n\'est pas démarré' end
        TriggerEvent('esx:showNotification', '~r~Menu contextuel indisponible~s~ (' .. why:sub(1, 80) .. ') — voir la console F8')
        return
    end
    local c = GetEntityCoords(ped)
    local on, x, y = GetScreenCoordFromWorldCoord(c.x, c.y, c.z + 0.3)
    open = true
    openedAt = GetGameTimer()
    SetNuiFocus(true, true)
    -- le jeu continue de recevoir le clavier : on peut avancer, courir, conduire… pendant que le menu est ouvert
    SetNuiFocusKeepInput(true)
    SendNUIMessage({ a = 'open', menu = tree, x = on and x or 0.5, y = on and y or 0.5, offset = C.OffsetPx, hold = C.HoldToShow == true })
end

if C.HoldToShow then
    -- maintenir la touche : le menu reste affiché ; relâcher la ferme
    RegisterCommand('+pickax_context', function() if not open then openMenu() end end, false)
    RegisterCommand('-pickax_context', function()
        -- ignore le « relâchement » parasite émis quand l'interface prend le focus
        if open and GetGameTimer() - openedAt > 250 then close() end
    end, false)
    if C.Key and C.Key ~= '' then RegisterKeyMapping('+pickax_context', 'Menu contextuel (maintenir)', 'keyboard', C.Key) end
    RegisterCommand(C.Command, function() if open then close() else openMenu() end end, false)   -- /moi : ouvre / ferme (sans maintenir)
else
    RegisterCommand(C.Command, function() if open then close() else openMenu() end end, false)
    if C.Key and C.Key ~= '' then RegisterKeyMapping(C.Command, 'Menu contextuel', 'keyboard', C.Key) end
end
exports('Open', openMenu)
exports('Close', close)
AddEventHandler('pickax_context:closeRequest', close)   -- envoyé par les actions qui ferment le menu

RegisterNUICallback('close', function(_, cb) cb(1) close() end)
RegisterNUICallback('run', function(d, cb)
    local ok, r = pcall(function() return exports.pickax_core:ContextRun(d and d.k) end)
    r = ok and type(r) == 'table' and r or {}
    cb({ checked = r.checked })
    if r.close then close() end
end)

-- La souris sert à viser le menu : pas de caméra, de tir ni de changement d'arme. Les déplacements (ZQSD, course, saut, conduite) restent actifs.
CreateThread(function()
    while true do
        if open then
            for _, c in ipairs({ 1, 2, 14, 15, 16, 17, 24, 25, 37, 44, 45, 68, 69, 70, 91, 92, 140, 141, 142, 257, 263, 264 }) do DisableControlAction(0, c, true) end
            Wait(0)
        else Wait(400) end
    end
end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() and open then SetNuiFocusKeepInput(false) SetNuiFocus(false, false) end end)
