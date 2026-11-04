local C = Config
local isOpen, openedAt, lastTab = false, 0, 1
local Cache = {}   -- indice de tenue : état enlevé / remis

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

local function weaponsTab()
    local items = ox():GetPlayerItems() or {}
    local cur = ox():getCurrentWeapon()
    local out = {}
    for i, s in ipairs(C.WeaponSlots) do out[i] = { key = s.id, label = s.label, list = {} } end
    local data = ox():Items()
    for _, it in pairs(items) do
        if it and it.name and it.name:sub(1, 7) == 'WEAPON_' then
            local idx = slotOfWeapon(it.name, GetWeapontypeGroup(joaat(it.name)))
            if idx then
                local def = data and data[it.name] or {}
                local ammoName = def.ammoname
                local ammo = 0
                if it.metadata and it.metadata.ammo then ammo = it.metadata.ammo end
                local reserve = ammoName and (ox():Search('count', ammoName) or 0) or nil
                local list = out[idx].list
                list[#list + 1] = { slot = it.slot, name = it.name, label = def.label or it.label or it.name, ammo = ammo, reserve = reserve, held = cur and cur.slot == it.slot or false }
            end
        end
    end
    for _, o in ipairs(out) do table.sort(o.list, function(a, b) return a.slot < b.slot end) end
    return out
end

-- ───────────── Données : OBJETS ─────────────
local function itemsTab()
    local items = ox():GetPlayerItems() or {}
    local data = ox():Items()
    local hide = {}
    for _, n in ipairs(C.Items.Hide or {}) do hide[n] = true end
    local out = {}
    for _, it in pairs(items) do
        if it and it.name and it.name:sub(1, 7) ~= 'WEAPON_' and not it.name:find('^ammo') and not hide[it.name] then
            local def = data and data[it.name] or {}
            if not C.Items.OnlyUsable or def.client or def.consume ~= nil or def.server then
                out[#out + 1] = { slot = it.slot, name = it.name, label = def.label or it.label or it.name, count = it.count or 1 }
            end
        end
    end
    table.sort(out, function(a, b) return a.slot < b.slot end)
    return out
end

-- ───────────── Données : EMOTES / TENUE / RACCOURCIS ─────────────
local function listTab(src)
    local out = {}
    for i, e in ipairs(src) do out[i] = { label = e.label, idx = i } end
    return out
end

local function outfitTab()
    local out = {}
    for i, o in ipairs(C.Outfit) do
        out[i] = { label = o.label, idx = i, off = Cache[i] ~= nil }
    end
    return out
end

local function buildAll()
    local tabs = {}
    for _, t in ipairs(C.Tabs) do
        if t == 'weapons' then tabs[#tabs + 1] = { id = 'weapons', label = 'Armes', slots = weaponsTab() }
        elseif t == 'items' then tabs[#tabs + 1] = { id = 'items', label = 'Objets', list = itemsTab() }
        elseif t == 'emotes' then tabs[#tabs + 1] = { id = 'emotes', label = 'Emotes', list = listTab(C.Emotes) }
        elseif t == 'outfit' then tabs[#tabs + 1] = { id = 'outfit', label = 'Tenue', list = outfitTab() }
        elseif t == 'shortcuts' then tabs[#tabs + 1] = { id = 'shortcuts', label = 'Raccourcis', list = listTab(C.Shortcuts) } end
    end
    return tabs
end

-- ───────────── Actions ─────────────
local function loadAnim(dict)
    RequestAnimDict(dict)
    local t = GetGameTimer() + 2000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < t do Wait(10) end
    return HasAnimDictLoaded(dict)
end

local function doEmote(e)
    local ped = PlayerPedId()
    if e.stop then ClearPedTasks(ped) return end
    if e.command then ExecuteCommand(e.command) return end
    if e.scenario then TaskStartScenarioInPlace(ped, e.scenario, 0, true) return end
    if e.dict and loadAnim(e.dict) then TaskPlayAnim(ped, e.dict, e.clip, 3.0, 3.0, -1, e.flag or 49, 0, false, false, false) end
end

local function isFemale() return GetEntityModel(PlayerPedId()) == joaat('mp_f_freemode_01') end

local function toggleOutfit(idx)
    local o = C.Outfit[idx]
    if not o then return end
    local ped = PlayerPedId()
    if o.type == 'prop' then
        if Cache[idx] then
            local c = Cache[idx]
            SetPedPropIndex(ped, o.id, c.d, c.t, true)
            Cache[idx] = nil
        else
            local d = GetPedPropIndex(ped, o.id)
            if d == -1 then return end
            Cache[idx] = { d = d, t = GetPedPropTextureIndex(ped, o.id) }
            ClearPedProp(ped, o.id)
        end
        return
    end
    local function cur(id) return { d = GetPedDrawableVariation(ped, id), t = GetPedTextureVariation(ped, id), p = GetPedPaletteVariation(ped, id) } end
    local function put(id, v) SetPedComponentVariation(ped, id, v.d, v.t, v.p or 0) end
    if Cache[idx] then
        for id, v in pairs(Cache[idx]) do put(id, v) end
        Cache[idx] = nil
    else
        local saved = { [o.id] = cur(o.id) }
        local off = o.off and o.off[isFemale() and 2 or 1] or 0
        SetPedComponentVariation(ped, o.id, off, 0, 0)
        for _, a in ipairs(o.also or {}) do
            saved[a.id] = cur(a.id)
            SetPedComponentVariation(ped, a.id, a.off[isFemale() and 2 or 1], 0, 0)
        end
        Cache[idx] = saved
    end
end

local function doShortcut(s)
    if s.type == 'command' then ExecuteCommand(s.value)
    elseif s.type == 'event' then TriggerEvent(s.value)
    elseif s.type == 'export' then pcall(function() exports[s.resource][s.fn](exports[s.resource]) end)
    elseif s.type == 'inventory' then ox():openInventory('player')
    elseif s.type == 'holster' then
        local cur = ox():getCurrentWeapon()
        if cur then ox():useSlot(cur.slot) else SetCurrentPedWeapon(PlayerPedId(), joaat('WEAPON_UNARMED'), true) end
    end
end

-- ───────────── Ouverture / fermeture ─────────────
local function close()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ a = 'close' })
end

local function open()
    if isOpen or IsPauseMenuActive() then return end
    if IsNuiFocused() then return end
    isOpen = true
    openedAt = GetGameTimer()
    SetNuiFocus(true, true)
    SendNUIMessage({ a = 'open', tabs = buildAll(), tab = lastTab, key = C.Key, accent = PickaxTheme and PickaxTheme.hex or nil })
end

RegisterCommand('+pickax_wheel', open, false)
RegisterCommand('-pickax_wheel', function()
    if isOpen then SendNUIMessage({ a = 'release' }) end   -- le NUI renvoie 'select' (élément survolé) ou 'cancel'
end, false)
RegisterKeyMapping('+pickax_wheel', 'Roue d\'actions (maintenir)', 'keyboard', C.Key or 'CAPSLOCK')

RegisterNUICallback('select', function(d, cb)
    cb(1)
    if GetGameTimer() - openedAt < (C.OpenMinMs or 0) then close() return end
    lastTab = tonumber(d.tabIndex) or lastTab
    close()
    local t = d.tab
    if t == 'weapons' or t == 'items' then
        if d.slot then ox():useSlot(tonumber(d.slot)) end
    elseif t == 'emotes' then
        local e = C.Emotes[tonumber(d.idx) or 0]
        if e then doEmote(e) end
    elseif t == 'outfit' then
        toggleOutfit(tonumber(d.idx) or 0)
    elseif t == 'shortcuts' then
        local s = C.Shortcuts[tonumber(d.idx) or 0]
        if s then CreateThread(function() Wait(80) doShortcut(s) end) end
    end
end)
RegisterNUICallback('cancel', function(d, cb) cb(1) if d and d.tabIndex then lastTab = tonumber(d.tabIndex) or lastTab end close() end)
RegisterNUICallback('tab', function(d, cb) cb(1) lastTab = tonumber(d.tabIndex) or lastTab end)

-- Désactive la roue d'armes native pendant que la nôtre est ouverte (et la touche TAB si c'est elle)
CreateThread(function()
    while true do
        if C.HideNativeWheel then
            HudWeaponWheelIgnoreSelection()
            if isOpen then HideHudComponentThisFrame(19) HideHudComponentThisFrame(20) HideHudComponentThisFrame(22) end
            Wait(0)
        else Wait(1000) end
    end
end)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() and isOpen then SetNuiFocus(false, false) end end)
exports('Open', open)
exports('Close', close)
