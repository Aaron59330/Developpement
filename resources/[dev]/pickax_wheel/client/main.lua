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

local function buildSlots()
    local items = ox():GetPlayerItems() or {}
    local cur = ox():getCurrentWeapon()
    local data = ox():Items()
    local out = {}
    for i, s in ipairs(C.WeaponSlots) do
        out[i] = { id = s.id, label = s.label, unarmed = s.unarmed or nil, list = {} }
        if s.unarmed then
            out[i].label = C.Unarmed.label
            out[i].sub = C.Unarmed.sub
            out[i].icon = C.Unarmed.icon
            out[i].held = cur == nil
        end
    end
    for _, it in pairs(items) do
        if it and it.name and it.name:sub(1, 7) == 'WEAPON_' then
            local idx = slotOfWeapon(it.name, GetWeapontypeGroup(joaat(it.name)))
            if idx and not C.WeaponSlots[idx].unarmed then
                local def = data and data[it.name] or {}
                local ammo = it.metadata and it.metadata.ammo or 0
                local reserve = def.ammoname and (ox():Search('count', def.ammoname) or 0) or nil
                local list = out[idx].list
                local held = cur and cur.slot == it.slot or false
                list[#list + 1] = { slot = it.slot, name = it.name, label = def.label or it.label or it.name, ammo = ammo, reserve = reserve, held = held }
                if held then out[idx].held = true end
            end
        end
    end
    for _, o in ipairs(out) do table.sort(o.list, function(a, b) return a.slot < b.slot end) end
    return out
end

-- ───────────── Ouverture / fermeture ─────────────
local function close()
    if not isOpen then return end
    isOpen = false
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    SendNUIMessage({ a = 'close' })
end

local function open()
    if isOpen or IsPauseMenuActive() then return end
    if IsNuiFocused() then return end
    isOpen = true
    openedAt = GetGameTimer()
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)   -- le jeu continue de recevoir la touche : le relâchement est détecté
    SendNUIMessage({ a = 'open', slots = buildSlots(), colors = C.Colors })
end

RegisterCommand('+pickax_wheel', function() if not isOpen then open() end end, false)
RegisterCommand('-pickax_wheel', function()
    -- ignore le « relâchement » parasite émis quand l'interface prend le focus
    if isOpen and GetGameTimer() - openedAt > 250 then SendNUIMessage({ a = 'release' }) end
end, false)
RegisterKeyMapping('+pickax_wheel', 'Roue d\'armes (maintenir)', 'keyboard', C.Key or 'CAPSLOCK')

RegisterNUICallback('select', function(d, cb)
    cb(1)
    if GetGameTimer() - openedAt < (C.OpenMinMs or 0) then close() return end
    close()
    if d.unarmed then
        local cur = ox():getCurrentWeapon()
        if cur then ox():useSlot(cur.slot) end            -- range l'arme en main
        SetCurrentPedWeapon(PlayerPedId(), joaat('WEAPON_UNARMED'), true)
    elseif d.slot then
        ox():useSlot(tonumber(d.slot))
    end
end)
RegisterNUICallback('cancel', function(_, cb) cb(1) close() end)

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
