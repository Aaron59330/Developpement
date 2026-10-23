local ESX
CreateThread(function()
    while GetResourceState('es_extended') ~= 'started' do Wait(200) end
    ESX = exports['es_extended']:getSharedObject()
end)

local open = false

-- type de menu choisi par le joueur : 'new' (ce menu) ou 'classic' (ancien menu RageUI)
local function getMode()
    local m = GetResourceKvpString('pkhub_mode')
    if m == 'new' or m == 'classic' then return m end
    return Config.DefaultMode or 'new'
end
exports('UseNew', function() return getMode() == 'new' end)
exports('SetMode', function(m) if m == 'new' or m == 'classic' then SetResourceKvp('pkhub_mode', m) end end)
local function nui(a, d) d = d or {}; d.action = a; SendNUIMessage(d) end
local function started(r) return GetResourceState(r) == 'started' end
local function call(res, fn, ...) if not started(res) then return nil end local ok, v = pcall(function(...) return exports[res][fn](exports[res], ...) end, ...) return ok and v or nil end

-- états locaux des commandes véhicule (comme dans le menu d'origine)
local doors, windows, limiterIdx = {}, {}, nil
local noCross, noRadar, noHud, crossThread = false, false, false, false

-- ───────── collecte des données ─────────
local function veh() local p = PlayerPedId(); return IsPedInAnyVehicle(p, false) and GetVehiclePedIsIn(p, false) or nil end

local function vehicleInfo()
    local v = veh(); if not v then return { inVehicle = false } end
    return { inVehicle = true, driver = GetPedInVehicleSeat(v, -1) == PlayerPedId(),
        name = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(v))), plate = GetVehicleNumberPlateText(v),
        engine = math.floor(GetVehicleEngineHealth(v) / 10), engineOn = GetIsVehicleEngineRunning(v) }
end

local function prefs()
    local ui = call('pickax_ui', 'GetSettings') or {}
    local hud = call('pickax_hud2', 'GetSettings') or {}
    local comp = call('pickax_compass', 'GetSettings')
    local perf = call('pickax_core', 'HubPerf')
    return { ui = ui, hud = hud, compass = comp and comp.enabled, hasCompass = comp ~= nil, hasHud = next(hud) ~= nil, hasUi = next(ui) ~= nil,
        notifyRadius = call('pickax_notify', 'GetRadius') or -1, perf = perf, game = { cross = noCross, radar = noRadar, hud = noHud } }
end

local function fetch(cb) -- ESX callbacks promisifiés
    local p = promise.new()
    cb(function(...) p:resolve({ ... }) end)
    return Citizen.Await(p)[1]
end

local function collect()
    local pd = ESX.GetPlayerData()
    local ident = fetch(function(done) ESX.TriggerServerCallback('CorePickax:GetIdentity', done) end)
    local bills = fetch(function(done) ESX.TriggerServerCallback('CorePickax:GetBills', done) end) or {}
    local name = (((ident and ident.firstName) or '') .. ' ' .. ((ident and ident.lastName) or '')):gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' then name = GetPlayerName(PlayerId()) end
    local cash, bank, black = 0, 0, 0
    for _, a in ipairs(pd.accounts or {}) do
        if a.name == 'money' then cash = a.money elseif a.name == 'bank' then bank = a.money elseif a.name == 'black_money' then black = a.money end
    end
    local job = pd.job or {}
    local keys = call('pickax_core', 'HubKeys') or {}
    local cmds = call('pickax_core', 'HubCommands') or {}
    return {
        name = name, id = GetPlayerServerId(PlayerId()),
        job = { label = job.label or job.name or '—', grade = job.grade_label },
        money = { cash = cash, bank = bank, black = black }, showDirty = Config.ShowDirty,
        bills = bills, keys = keys, commands = cmds, vehicle = vehicleInfo(), prefs = prefs(),
        lists = { styles = Config.Styles, sizes = Config.Sizes, btn = Config.BtnRadius, card = Config.CardRadius, notify = Config.NotifyRadius, hudRadius = Config.HudRadius, hudScale = Config.HudScale, colors = Config.Colors },
        links = { discord = Config.Links.Discord ~= nil, shop = Config.Links.Boutique ~= nil }, limiter = Config.Limiter,
    }
end

-- ───────── ouverture / fermeture ─────────
function OpenHub()
    if open or not ESX then return end
    local data = collect()
    local theme = PickaxTheme or {}
    data.mode = getMode()
    open = true; SetNuiFocus(true, true)
    nui('open', { accent = Config.Accent, data = data, server = { name = theme.name, short = theme.short, logo = theme.logo } })
end
exports('Open', OpenHub)

local function closeHub() open = false; SetNuiFocus(false, false); nui('close') end
RegisterCommand(Config.Command, function() if open then closeHub() else OpenHub() end end, false)
if Config.Key then RegisterKeyMapping(Config.Command, 'Menu personnel', 'keyboard', Config.Key) end
RegisterNUICallback('close', function(_, cb) closeHub(); cb(1) end)

-- ───────── actions ─────────
local A = {}

local function closestPlayer()
    local p, dist = ESX.Game.GetClosestPlayer()
    if p ~= -1 and dist ~= -1 and dist <= 3.0 then return GetPlayerServerId(p) end
end

function A.doc(d)                                    -- kind: id | driver | weapon ; mode: show | look
    local me = GetPlayerServerId(PlayerId())
    local kind = d.kind ~= 'id' and d.kind or nil
    if d.mode == 'look' then TriggerServerEvent('jsfour-idcard:open', me, me, kind)
    else
        local t = closestPlayer()
        if t then TriggerServerEvent('jsfour-idcard:open', me, t, kind) else ESX.ShowNotification('Aucun joueur à proximité') end
    end
    closeHub()
end

function A.payBill(d)
    local p = promise.new()
    ESX.TriggerServerCallback('esx_billing:payBill', function() p:resolve(true) end, d.id)
    Citizen.Await(p)
    return { bills = fetch(function(done) ESX.TriggerServerCallback('CorePickax:GetBills', done) end) or {} }
end

function A.carplay() closeHub(); SetTimeout(300, function() TriggerEvent('carplay:client:open') end) end

local function toggleDoor(v, i) if doors[i] then SetVehicleDoorShut(v, i, false, false) else SetVehicleDoorOpen(v, i, false, false) end doors[i] = not doors[i] end

function A.vehicle(d)
    local v = veh(); if not v then return { vehicle = vehicleInfo() } end
    local what = d.what
    if what == 'engine' then
        if GetIsVehicleEngineRunning(v) then SetVehicleEngineOn(v, false, false, true); SetVehicleUndriveable(v, true)
        else SetVehicleEngineOn(v, true, false, true); SetVehicleUndriveable(v, false) end
    elseif what == 'hood' then if GetVehicleDoorAngleRatio(v, 4) == 0 then SetVehicleDoorOpen(v, 4, false, false) else SetVehicleDoorShut(v, 4, false) end
    elseif what == 'trunk' then if GetVehicleDoorAngleRatio(v, 5) == 0 then SetVehicleDoorOpen(v, 5, false, false) else SetVehicleDoorShut(v, 5, false) end
    elseif what == 'closeall' then for i = 0, 5 do SetVehicleDoorShut(v, i, false); doors[i] = false end
    elseif what == 'door' then toggleDoor(v, tonumber(d.index))
    elseif what == 'window' then
        local i = tonumber(d.index)
        if windows[i] then RollUpWindow(v, i) else RollDownWindow(v, i) end windows[i] = not windows[i]
    elseif what == 'limit' then
        local kmh = tonumber(d.value)
        if kmh and kmh > 0 then SetVehicleMaxSpeed(v, (kmh - 1) / 3.6); ESX.ShowNotification(('Le ~b~limitateur~s~ est ~g~activé~s~ à ~o~%d km/h.'):format(kmh))
        else SetVehicleMaxSpeed(v, 1000 / 3.6); ESX.ShowNotification('Le ~b~limitateur~s~ est ~r~désactivé') end
    end
    return { vehicle = vehicleInfo() }
end

function A.pref(d)                                   -- réglage pickax_ui
    call('pickax_ui', 'SetSetting', d.key, d.value)
    if d.key == 'volume' then call('pickax_ui', 'Sound', 'click') end
    return { prefs = prefs() }
end
function A.prefReset() call('pickax_ui', 'ResetSettings'); return { prefs = prefs() } end
function A.prefHex(d)
    closeHub()
    CreateThread(function()
        local typed = call('pickax_ui', 'Input', { title = 'Couleur personnalisée', hint = 'Format #RRGGBB', placeholder = '#00a4ff', default = '#', max = 7 })
        if typed then
            local r = typed:gsub('%s', ''); if r:match('^%x%x%x%x%x%x$') then r = '#' .. r end
            if r:match('^#%x%x%x%x%x%x$') then call('pickax_ui', 'SetSetting', d.key, r:lower()) else ESX.ShowNotification('~r~Couleur invalide~s~ (format #RRGGBB)') end
        end
        OpenHub()
    end)
end
function A.notifyRadius(d)
    if started('pickax_notify') then exports['pickax_notify']:SetRadius(d.value >= 0 and d.value or nil); exports['pickax_notify']:ShowNotification('Aperçu : voici le nouvel arrondi des notifications.', 'success') end
    return { prefs = prefs() }
end
function A.hud(d) call('pickax_hud2', 'SetSetting', d.key, d.value); return { prefs = prefs() } end
function A.hudReset() call('pickax_hud2', 'ResetSettings'); return { prefs = prefs() } end
function A.compass(d) call('pickax_compass', 'SetEnabled', d.value == true); return { prefs = prefs() } end
function A.perf(d) call('pickax_core', 'HubPerfSet', d.key, d.value); return { prefs = prefs() } end

function A.game(d)
    if d.key == 'cross' then
        noCross = d.value == true
        if noCross and not crossThread then
            crossThread = true
            CreateThread(function()
                while noCross do
                    if IsPedArmed(PlayerPedId(), 6) then DisableControlAction(1, 140, true); DisableControlAction(1, 141, true); DisableControlAction(1, 142, true); Wait(0) else Wait(200) end
                end
                crossThread = false
            end)
        end
    elseif d.key == 'radar' then noRadar = d.value == true; DisplayRadar(not noRadar)
    elseif d.key == 'hud' then noHud = d.value == true; TriggerEvent('tempui:toggleUi', not noHud) end
    return { prefs = prefs() }
end

function A.editor(d)
    if d.what == 'start' then
        if IsRecording() then ESX.ShowNotification("Vous êtes déjà en train d'enregistrer un clip.") else StartRecording(1) end
    else
        if not IsRecording() then ESX.ShowNotification("Vous n'êtes pas en train d'enregistrer un clip.") else StopRecordingAndSaveClip() end
    end
end

function A.mode(d)
    if d.value ~= 'new' and d.value ~= 'classic' then return end
    SetResourceKvp('pkhub_mode', d.value)
    if d.value == 'classic' then closeHub(); SetTimeout(250, function() ExecuteCommand(Config.ClassicCommand) end) end
    return { mode = d.value }
end

function A.link(d)
    local url = d.which == 'discord' and Config.Links.Discord or Config.Links.Boutique
    call('pickax_ui', 'OpenUrl', url)
end

RegisterNUICallback('act', function(d, cb)
    local fn = A[d.name]
    local ok, res = pcall(function() return fn and fn(d) end)
    cb(ok and res or {})
end)
