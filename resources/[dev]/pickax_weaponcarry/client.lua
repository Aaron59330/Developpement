local ESX = exports['es_extended']:getSharedObject()
local props = {}
local lastPlace = {}      -- cache KVP

local function classOf(name)
    if Config.Override[name] then return Config.Override[name] end
    return Config.Groups[GetWeapontypeGroup(joaat(name))] or 'long'
end

local function placeOf(name)
    local p = lastPlace[name]
    if p == nil then p = GetResourceKvpString('wc:' .. name) or Config.DefaultPlace lastPlace[name] = p end
    local allowed = Config.Allowed[classOf(name)] or {}
    return allowed[p] and p or 'hidden'
end

-- props[clé] = { [arme] = { ent, place, idx } } : clé 'me' pour soi, id serveur pour les autres joueurs proches
local function clearProp(key, name)
    local set = props[key]
    local p = set and set[name]
    if p and DoesEntityExist(p.ent) then DeleteEntity(p.ent) end
    if set then set[name] = nil end
end
local function clearSet(key) if props[key] then for n in pairs(props[key]) do clearProp(key, n) end props[key] = nil end end
local function clearAll() for k in pairs(props) do clearSet(k) end end

local function spawn(ped, key, name, place, idx)
    local def = Config.Attach[place] and Config.Attach[place][classOf(name)]
    if not def then return end
    local hash = joaat(name)
    RequestWeaponAsset(hash, 31, 0)
    local t = GetGameTimer() + 2000
    while not HasWeaponAssetLoaded(hash) and GetGameTimer() < t do Wait(10) end
    if not HasWeaponAssetLoaded(hash) then return end
    local c = GetEntityCoords(ped)
    local ent = CreateWeaponObject(hash, 0, c.x, c.y, c.z, true, 1.0, 0)      -- objet local à ce client (chaque joueur affiche les armes des autres via leur état partagé)
    if not ent or ent == 0 then return end
    SetEntityCollision(ent, false, false)
    SetEntityAsMissionEntity(ent, true, true)
    local shift = (idx - 1) * 0.045      -- plusieurs armes au même endroit : légèrement décalées
    AttachEntityToEntity(ent, ped, GetPedBoneIndex(ped, def[1]), def[2], def[3] + shift, def[4], def[5], def[6], def[7], true, true, false, false, 2, true)
    props[key] = props[key] or {}
    props[key][name] = { ent = ent, place = place, idx = idx }
end

-- Affiche sur `ped` les armes de `list` ({ name, place, idx }), sauf celle tenue en main
local function sync(ped, key, list)
    local selected = GetSelectedPedWeapon(ped)
    local want = {}
    for _, w in ipairs(list or {}) do if joaat(w.name) ~= selected then want[w.name] = w end end
    for name, p in pairs(props[key] or {}) do
        local w = want[name]
        if not w or w.place ~= p.place or w.idx ~= p.idx or not DoesEntityExist(p.ent) or not IsEntityAttachedToEntity(p.ent, ped) then clearProp(key, name) end
    end
    for name, w in pairs(want) do if not (props[key] and props[key][name]) then spawn(ped, key, name, w.place, w.idx) end end
end

local mine, mineJson = {}, ''

local function refresh()
    local ped = PlayerPedId()
    local hidden = IsEntityDead(ped) or (Config.HideInVehicle and IsPedInAnyVehicle(ped, false)) or IsPlayerSwitchInProgress()

    -- mes armes : liste calculée depuis l'inventaire, partagée aux autres joueurs par état (statebag)
    local ok, items = pcall(function() return exports.ox_inventory:GetPlayerItems() end)
    if ok and type(items) == 'table' then
        local list, count, seen = {}, {}, {}
        for _, it in pairs(items) do
            local name = it.name and tostring(it.name):upper()
            if name and name:find('^WEAPON_') and not seen[name] then
                seen[name] = true
                local place = placeOf(name)
                if place ~= 'hidden' then
                    count[place] = (count[place] or 0) + 1
                    list[#list + 1] = { name = name, place = place, idx = count[place] }
                end
            end
        end
        table.sort(list, function(a, b) return a.name < b.name end)
        local j = json.encode(list)
        if j ~= mineJson then mineJson = j mine = list LocalPlayer.state:set('wcarry', list, true) end
    end
    if hidden then clearSet('me') else sync(ped, 'me', mine) end

    -- armes des autres joueurs proches
    if Config.ShowToOthers then
        local me, near = GetEntityCoords(ped), {}
        for _, pid in ipairs(GetActivePlayers()) do
            if pid ~= PlayerId() then
                local other = GetPlayerPed(pid)
                if other ~= 0 and #(GetEntityCoords(other) - me) < Config.OthersDistance then
                    local key = GetPlayerServerId(pid)
                    near[key] = true
                    local st = Player(key).state.wcarry
                    if st and not (Config.HideInVehicle and IsPedInAnyVehicle(other, false)) and not IsEntityDead(other) then sync(other, key, st) else clearSet(key) end
                end
            end
        end
        for key in pairs(props) do if key ~= 'me' and not near[key] then clearSet(key) end end
    end
end

CreateThread(function()
    while true do
        Wait(Config.Refresh)
        local ok, err = pcall(refresh)
        if not ok then print('^1[pickax_weaponcarry] ' .. tostring(err) .. '^0') end
    end
end)

-- ───────── Menu contextuel (pickax_core → Moi → Armes) ─────────
-- Liste des armes de l'inventaire avec leur placement actuel
exports('GetEntries', function()
    local out = {}
    local ok, items = pcall(function() return exports.ox_inventory:GetPlayerItems() end)
    if not ok or type(items) ~= 'table' then return out end
    local seen = {}
    for _, it in pairs(items) do
        local name = it.name and tostring(it.name):upper()
        if name and name:find('^WEAPON_') and not seen[name] then
            seen[name] = true
            local allowed, list = Config.Allowed[classOf(name)] or {}, {}
            for _, id in ipairs(Config.PlaceOrder) do if allowed[id] then list[#list + 1] = { id = id, label = Config.Places[id] } end end
            out[#out + 1] = { name = name, label = it.label or name, current = placeOf(name), places = list }
        end
    end
    table.sort(out, function(a, b) return a.label < b.label end)
    return out
end)

exports('SetPlacement', function(name, place)
    name = tostring(name or ''):upper()
    local allowed = Config.Allowed[classOf(name)] or {}
    if not name:find('^WEAPON_') or not allowed[place] then return false end
    lastPlace[name] = place
    SetResourceKvp('wc:' .. name, place)
    ESX.ShowNotification(place == 'hidden' and 'Arme rangée : ~o~invisible' or ('Arme placée : ~b~' .. Config.Places[place]))
    CreateThread(function() pcall(refresh) end)
    return true
end)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then clearAll() end end)
AddEventHandler('esx:onPlayerDeath', clearAll)

-- ───────── Réglage en jeu (réservé _dev) : /wctune <placement> <type> <x> <y> <z> <rotX> <rotY> <rotZ> ─────────
if Config.TuneCommand then
    RegisterCommand(Config.TuneCommand, function(_, a)
        ESX.TriggerServerCallback('pickax_weaponcarry:isDev', function(ok)
            if not ok then return ESX.ShowNotification('~r~Réservé aux administrateurs') end
            local place, cls = a[1], a[2]
            if not (place and cls and Config.Attach[place] and Config.Attach[place][cls]) then
                return ESX.ShowNotification('Usage : /' .. Config.TuneCommand .. ' back|front|pocket pistol|smg|long|melee x y z rx ry rz')
            end
            local d = Config.Attach[place][cls]
            for i = 1, 6 do d[i + 1] = tonumber(a[i + 2]) or d[i + 1] end
            clearAll() pcall(refresh)
            local line = ('%s.%s = { %d, %.3f, %.3f, %.3f, %.1f, %.1f, %.1f },'):format(place, cls, d[1], d[2], d[3], d[4], d[5], d[6], d[7])
            print('^2[pickax_weaponcarry] à copier dans config.lua :^0 ' .. line)
            ESX.ShowNotification('Position appliquée (ligne à copier dans la console F8)')
        end)
    end, false)
end
