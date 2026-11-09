ESX = exports['es_extended']:getSharedObject()
local C = Config
local open = false
local allowed = {}   -- commandes que le tableau de bord peut lancer (celles de la config)

-- ───────── préférences du joueur (mémorisées sur son PC, appliquées en direct) ─────────
local KVP = 'pickax_dashboard:prefs'
Prefs = { data = {} }
do local raw = GetResourceKvpString(KVP) if raw then local ok, t = pcall(json.decode, raw) if ok and type(t) == 'table' then Prefs.data = t end end end
local APPLY = {}
function Prefs.all() return Prefs.data end
function Prefs.get(k) return Prefs.data[k] == true end
function Prefs.set(k, v)
    Prefs.data[k] = v and true or nil
    SetResourceKvp(KVP, json.encode(Prefs.data))
    if APPLY[k] then pcall(APPLY[k], v and true or false) end
    TriggerEvent('pickax_dashboard:pref', k, v and true or false)     -- les autres ressources peuvent réagir
end
function Prefs.reset()
    for k in pairs(Prefs.data) do if APPLY[k] then pcall(APPLY[k], false) end end
    Prefs.data = {}
    SetResourceKvp(KVP, '{}')
end
exports('GetPref', function(k) return Prefs.get(k) end)

-- boussole directionnelle
APPLY.compass = function(on) exports.pickax_compass:SetEnabled(on) end
-- armes sur le corps
APPLY.hidecarry = function(on) exports.pickax_weaponcarry:SetHideAll(on) end
-- minimap agrandie
local function applyMap()
    local k = Prefs.get('bigmap') and 1.3 or 1.0
    SetMinimapComponentPosition('minimap', 'L', 'B', -0.0045, 0.002, 0.15 * k, 0.188888 * k)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.0, -0.01, 0.12 * k, 0.2 * k)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.0305, 0.04, 0.267 * k, 0.272 * k)
    SetRadarBigmapEnabled(true, false) Wait(0) SetRadarBigmapEnabled(false, false)
end
APPLY.bigmap = function() CreateThread(applyMap) end
-- sons : sirènes / klaxons des autres, radio des véhicules
CreateThread(function()
    while true do
        if Prefs.get('mutesiren') or Prefs.get('mutehorn') or Prefs.get('noradio') then
            local me = PlayerPedId()
            local mine = GetVehiclePedIsIn(me, false)
            for _, v in ipairs(GetGamePool('CVehicle')) do
                if v ~= mine and #(GetEntityCoords(v) - GetEntityCoords(me)) < 80.0 then
                    if Prefs.get('mutesiren') then SetVehicleHasMutedSirens(v, true) end
                    if Prefs.get('mutehorn') then SetHornEnabled(v, false) end
                end
            end
            if mine ~= 0 and Prefs.get('noradio') and GetPlayerRadioStationIndex() ~= 255 then SetVehRadioStation(mine, 'OFF') end
            Wait(500)
        else Wait(2000) end
    end
end)
CreateThread(function()    -- au démarrage : réapplique les préférences enregistrées
    Wait(6000)
    for k, v in pairs(Prefs.data) do if APPLY[k] and v then pcall(APPLY[k], true) end end
end)

local function close()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ a = 'close' })
end

-- ───────── localiser un véhicule ─────────
local locBlip
function locate(plate)
    plate = tostring(plate or ''):gsub('%s+$', ''):upper()
    if plate == '' then return end
    local found
    for _, v in ipairs(GetGamePool('CVehicle')) do
        if (GetVehicleNumberPlateText(v) or ''):gsub('%s+$', ''):upper() == plate then found = v break end
    end
    if not found then
        TriggerEvent('esx:showNotification', '~y~Véhicule introuvable~s~ : il n\'est pas à proximité (il est peut-être au garage).')
        return
    end
    local c = GetEntityCoords(found)
    if locBlip and DoesBlipExist(locBlip) then RemoveBlip(locBlip) end
    locBlip = AddBlipForEntity(found)
    SetBlipSprite(locBlip, 225) SetBlipColour(locBlip, 5) SetBlipScale(locBlip, 0.9) SetBlipFlashes(locBlip, true)
    BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('Mon véhicule ' .. plate) EndTextCommandSetBlipName(locBlip)
    SetNewWaypoint(c.x, c.y)
    TriggerEvent('esx:showNotification', '~g~Véhicule repéré~s~ : itinéraire GPS posé.')
    SetTimeout(60000, function() if locBlip and DoesBlipExist(locBlip) then RemoveBlip(locBlip) end end)
end

-- catalogue réel de la boutique (pickax_core) : onglets du tableau de bord <- catégories de la boutique
local SHOP_TABS = {
    { 'vehicle',  'Véhicules',   'car',       { 'vehicle', 'moto', 'other' } },
    { 'bundles',  'Packs',       'grid',      { 'pack', 'vip' } },
    { 'crate',    'Caisses',     'layers',    { 'crate' } },
    { 'weapons',  'Armes',       'crosshair', { 'weapon' } },
    { 'business', 'Entreprises', 'building',  { 'business' } },
}
local CAT_LABEL = { vehicle = 'VÉHICULE', moto = 'MOTO', other = 'VÉHICULE', pack = 'PACK', vip = 'VIP', crate = 'CAISSE', weapon = 'ARME', business = 'ENTREPRISE' }
local function shopData()
    local ok, cat = pcall(function() return exports.pickax_core:BoutiqueCatalog() end)
    if not ok or type(cat) ~= 'table' then return nil end
    local tabs, items = {}, {}
    for _, t in ipairs(SHOP_TABS) do
        local n = 0
        for _, c in ipairs(t[4]) do
            for _, it in ipairs(cat[c] or {}) do
                n = n + 1
                items[#items + 1] = { id = c .. ':' .. it.idx, tab = t[1], cat = CAT_LABEL[c], title = it.name or '?', desc = it.desc or '', price = it.price or 0 }
            end
        end
        if n > 0 then tabs[#tabs + 1] = { t[1], t[2], t[3] } end
    end
    return { coins = tonumber(cat.points) or 0, tabs = tabs, items = items }
end

local function openDash()
    if open or IsPauseMenuActive() or IsNuiFocused() then return end
    ESX.TriggerServerCallback('pickax_dashboard:data', function(d)
        if not d then return end
        -- noms de véhicules : résolus côté client à partir du modèle
        for _, v in ipairs(d.vehicles.items or {}) do
            if v.model then
                local label = GetLabelText(GetDisplayNameFromVehicleModel(v.model))
                v.name = (label and label ~= 'NULL') and label or tostring(GetDisplayNameFromVehicleModel(v.model))
                v.sub = v.plate
            else v.name, v.sub = v.plate or '?', '' end
        end
        d.prefs = Prefs.all()
        local sd = shopData()
        if sd then d.shop.coins, d.shop.tabs, d.shop.items = sd.coins, sd.tabs, sd.items end
        d.shop.hasBoutique = d.shop.hasBoutique ~= false
        allowed = {}
        for _, s in ipairs(d.services or {}) do allowed[s.command] = true end
        for _, grp in pairs(d.actions or {}) do for _, a in ipairs(grp) do allowed[a.command] = true end end
        open = true
        SetNuiFocus(true, true)
        SendNUIMessage({ a = 'open', data = d })
    end)
end

RegisterCommand(C.Command, openDash, false)
if C.Key and C.Key ~= '' then RegisterKeyMapping(C.Command, 'Tableau de bord', 'keyboard', C.Key) end
exports('Open', openDash)
exports('Close', close)

RegisterNUICallback('close', function(_, cb) cb(1) close() end)
RegisterNUICallback('buy', function(d, cb)
    cb(1)
    local c, i = tostring(d and d.id or ''):match('^(%a+):(%d+)$')
    if not c then return end
    local ok, r = pcall(function() return exports.pickax_core:BoutiqueBuy(c, tonumber(i)) end)
    if ok and type(r) == 'table' and r.ok == false then TriggerEvent('esx:showNotification', '~r~' .. tostring(r.error or 'Achat impossible')) return end
    SetTimeout(1500, function()      -- coins à jour après l'achat
        local sd = open and shopData()
        if sd then SendNUIMessage({ a = 'coins', coins = sd.coins }) end
    end)
end)
RegisterNUICallback('setting', function(d, cb) cb(1) if d and d.key then Prefs.set(tostring(d.key), d.value) end end)
RegisterNUICallback('reset', function(_, cb) cb(1) Prefs.reset() SendNUIMessage({ a = 'prefs', prefs = Prefs.all() }) end)
RegisterNUICallback('cmd', function(d, cb)
    cb(1)
    local name = d and d.command
    if type(name) == 'string' and allowed[name] then
        close()
        SetTimeout(150, function() ExecuteCommand(name) end)
    end
end)
local function boutique() close() SetTimeout(150, function() pcall(function() exports.pickax_boutique:Open() end) end) end
RegisterNUICallback('act', function(d, cb)
    cb(1)
    local a = d and d.a
    if a == 'coins' or a == 'history' or a == 'boutique' then boutique()
    elseif a == 'inventory' then
        close()
        SetTimeout(150, function() pcall(function() exports.ox_inventory:openInventory() end) end)
    elseif a == 'locate' then locate(d.plate) end
end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() and open then SetNuiFocus(false, false) end end)
