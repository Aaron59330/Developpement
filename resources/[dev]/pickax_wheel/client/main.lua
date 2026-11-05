local C = Config
local isOpen, openedAt = false, 0

local function ox() return exports.ox_inventory end

-- ───────────── Données : ARMES ─────────────
local function slotOfWeapon(name, group)
    for i, s in ipairs(C.WeaponSlots) do
        if s.names then for _, n in ipairs(s.names) do if n == name then return i end end end
    end
    for i, s in ipairs(C.WeaponSlots) do
        if s.groups then for _, g in ipairs(s.groups) do if g == group then return i end end end
    end
end

local refs = {}   -- numéro de case (1-5) -> emplacement ox_inventory

local function buildSlots()
    local items = ox():GetPlayerItems() or {}
    local cur = ox():getCurrentWeapon()
    local data = ox():Items()
    local per = {}
    for _, it in pairs(items) do
        if it and it.name and it.name:sub(1, 7) == 'WEAPON_' then
            local idx = slotOfWeapon(it.name, GetWeapontypeGroup(joaat(it.name)))
            if idx then
                per[idx] = per[idx] or {}
                per[idx][#per[idx] + 1] = it
            end
        end
    end
    local out, equipped = {}, nil
    refs = {}
    for i, s in ipairs(C.WeaponSlots) do
        local list = per[i]
        if list then
            table.sort(list, function(a, b) return a.slot < b.slot end)
            local pick = list[1]
            for _, it in ipairs(list) do if cur and cur.slot == it.slot then pick = it end end
            local def = data and data[pick.name] or {}
            local e = { nom = pick.name, libelle = def.label or pick.label or pick.name, categorie = s.category, image = C.ImageUrl:format(pick.name) }
            if def.ammoname then
                e.munitions = { chargeur = pick.metadata and pick.metadata.ammo or 0, reserve = ox():Search('count', def.ammoname) or 0 }
            end
            out[i] = e
            refs[i] = pick.slot
            if cur and cur.slot == pick.slot then equipped = i end
        else
            out[i] = false
        end
    end
    return out, equipped
end

-- ───────────── Ouverture / fermeture ─────────────
local function close()
    if not isOpen then return end
    isOpen = false
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'fermer' })
end

local function open()
    if isOpen or IsPauseMenuActive() then return end
    if IsNuiFocused() then return end
    isOpen = true
    openedAt = GetGameTimer()
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)   -- le jeu continue de recevoir la touche : le relâchement est détecté
    local slots, equipped = buildSlots()
    SendNUIMessage({ action = 'ouvrir', emplacements = slots, equipee = equipped or false, couleurs = { vise = C.Colors.aimed, equipee = C.Colors.equipped } })
end

RegisterCommand('+pickax_wheel', function() if not isOpen then open() end end, false)
RegisterCommand('-pickax_wheel', function()
    -- ignore le « relâchement » parasite émis quand l'interface prend le focus
    if isOpen and GetGameTimer() - openedAt > 250 then SendNUIMessage({ action = 'valider' }) end
end, false)
RegisterKeyMapping('+pickax_wheel', 'Roue d\'armes (maintenir)', 'keyboard', C.Key or 'C')

RegisterNUICallback('choisir', function(d, cb)
    cb(1)
    if GetGameTimer() - openedAt < (C.OpenMinMs or 0) then close() return end
    close()
    local k = tonumber(d.emplacement)
    if not k then   -- mains nues
        local cur = ox():getCurrentWeapon()
        if cur then ox():useSlot(cur.slot) end            -- range l'arme en main
        SetCurrentPedWeapon(PlayerPedId(), joaat('WEAPON_UNARMED'), true)
    elseif refs[k] then
        ox():useSlot(refs[k])
    end
end)
RegisterNUICallback('fermer', function(_, cb) cb(1) close() end)

-- Désactive la roue d'armes native pendant que la nôtre est ouverte
CreateThread(function()
    while true do
        if C.HideNativeWheel then
            HudWeaponWheelIgnoreSelection()
            if isOpen then
                HideHudComponentThisFrame(19) HideHudComponentThisFrame(20) HideHudComponentThisFrame(22)
                for _, c in ipairs({ 1, 2, 14, 15, 16, 17, 24, 25, 37, 44, 45, 140, 141, 142, 257, 263, 264 }) do DisableControlAction(0, c, true) end
            end
            Wait(0)
        else Wait(1000) end
    end
end)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() and isOpen then SetNuiFocus(false, false) end end)
exports('Open', open)
exports('Close', close)
