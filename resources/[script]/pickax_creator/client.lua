-- pickax_creator : écrans plein format (identité · apparence · apparition · bienvenue · animations)
-- Les écrans sont ouverts par esx_identity (identité, apparition, bienvenue), pickax_core/skinchanger (apparence) et menuemote (animations).
local cam, scene, onSkinDone = nil, false, nil
local camDist, camHeight = Config.Scene.CamDistance or 2.4, Config.Scene.CamHeight or 0.55
local spawnP

-- ───────────── réglages venus du panel web (document « creator ») ─────────────
local live = {}
RegisterNetEvent('pickax_creator:cfg', function(c) live = type(c) == 'table' and c or {} end)
CreateThread(function() while true do TriggerServerEvent('pickax_creator:cfg') Wait(20000) end end)
local function NuiCfg() local bg = {}
    for k, v in pairs(live.bg or {}) do bg[k] = (type(v) == 'string' and v ~= '' and not v:find('^https?://') and not v:find('/')) and ('places/' .. v) or v end
    return { texts = live.texts or {}, bg = bg } end

local function musicCfg()
    if type(live.music) == 'table' and live.music.tracks and #live.music.tracks > 0 then
        local tr = {}
        for _, t in ipairs(live.music.tracks) do if t.file and t.file ~= '' then tr[#tr + 1] = { title = t.title, artist = t.artist, file = t.file, cover = t.cover } end end
        return { enabled = live.music.enabled ~= false, volume = (tonumber(live.music.volume) or 35) / 100, tracks = tr }
    end
    local tracks = {}
    for _, t in ipairs((Config.Music and Config.Music.Tracks) or {}) do tracks[#tracks + 1] = { title = t.title, artist = t.artist, file = t.file, cover = t.cover } end
    return { enabled = Config.Music and Config.Music.Enabled ~= false, volume = Config.Music and Config.Music.Volume or .35, tracks = tracks }
end
local function serverName() return (Config.ServerName ~= '' and Config.ServerName) or (PickaxTheme and PickaxTheme.name) or 'serveur' end
local function openView(msg) msg.cfg = NuiCfg() SetNuiFocus(true, true) SendNUIMessage(msg) end
local function closeView() SetNuiFocus(false, false) SendNUIMessage({ a = 'close' }) end

-- ───────────── scène : caméra face au personnage ─────────────
local camFwd = vector3(0.0, 1.0, 0.0)
local studioActive, origin = false, nil
local function startScene()
    if scene then return end
    scene = true
    local ped = PlayerPedId()
    local S = live.studio or {}
    local st = (S.enabled ~= false and S.x) and vector4((S.x or 0) + 0.0, (S.y or 0) + 0.0, (S.z or 0) + 0.0, (S.h or 0) + 0.0) or Config.Scene.Studio
    if st and not studioActive then
        origin = { c = GetEntityCoords(ped), h = GetEntityHeading(ped) }
        studioActive = true
        DoScreenFadeOut(300) while not IsScreenFadedOut() do Wait(10) end
        -- le décor est entièrement chargé avant d'afficher quoi que ce soit (sinon on voit le vide à travers le menu)
        SetFocusPosAndVel(st.x + 0.0, st.y + 0.0, st.z + 0.0, 0.0, 0.0, 0.0)
        NewLoadSceneStartSphere(st.x + 0.0, st.y + 0.0, st.z + 0.0, 80.0, 0)
        RequestCollisionAtCoord(st.x + 0.0, st.y + 0.0, st.z + 0.0)
        SetEntityCoordsNoOffset(ped, st.x + 0.0, st.y + 0.0, st.z + 0.0, false, false, false) SetEntityHeading(ped, (st.w or 0.0) + 0.0)
        local t = GetGameTimer()
        while not IsNewLoadSceneLoaded() and GetGameTimer() - t < 6000 do Wait(50) end
        NewLoadSceneStop()
        t = GetGameTimer()
        while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() - t < 5000 do Wait(50) end
        -- le sol est trouvé et le personnage posé dessus (jamais dans le vide)
        local ok, gz = GetGroundZFor_3dCoord(st.x + 0.0, st.y + 0.0, st.z + 1.0, false)
        if ok then SetEntityCoordsNoOffset(ped, st.x + 0.0, st.y + 0.0, gz + 0.0, false, false, false) end
        Wait(1200)
    end
    FreezeEntityPosition(ped, true)
    camDist = tonumber(S.camDistance) or Config.Scene.CamDistance or 2.4
    camHeight = tonumber(S.camHeight) or Config.Scene.CamHeight or 0.45
    local p = GetEntityCoords(ped)
    camFwd = GetEntityForwardVector(ped)
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(cam, 45.0)
    SetCamCoord(cam, p.x + camFwd.x * camDist, p.y + camFwd.y * camDist, p.z + camHeight + 0.35)
    PointCamAtCoord(cam, p.x, p.y, p.z + camHeight)
    SetCamActive(cam, true) RenderScriptCams(true, false, 0, true, false)
    if IsScreenFadedOut() then DoScreenFadeIn(500) end
    DisplayRadar(false)
end
-- fin de la scène de création : retour au point de départ (sauf si le joueur est conduit ailleurs : exports.pickax_creator:EndStudio())
local function returnFromStudio()
    if not studioActive then return end
    studioActive = false
    if origin then
        local ped = PlayerPedId()
        DoScreenFadeOut(300) while not IsScreenFadedOut() do Wait(10) end
        ClearFocus()
        RequestCollisionAtCoord(origin.c.x, origin.c.y, origin.c.z)
        SetEntityCoordsNoOffset(ped, origin.c.x, origin.c.y, origin.c.z, false, false, false) SetEntityHeading(ped, origin.h)
        Wait(500) DoScreenFadeIn(500)
        origin = nil
    end
end
exports('EndStudio', function() studioActive = false origin = nil ClearFocus() end)
AddEventHandler('CorePickax:Creator:finished', function() SetTimeout(5000, function() CreateThread(returnFromStudio) end) end)
local function stopScene()
    if not scene then return end
    scene = false
    RenderScriptCams(false, true, 500, true, false)
    if cam then DestroyCam(cam, false) cam = nil end
    FreezeEntityPosition(PlayerPedId(), false)
    DisplayRadar(true)
end
local function moveCam(dx, dy)
    if not cam then return end
    local ped = PlayerPedId()
    if dx then SetEntityHeading(ped, GetEntityHeading(ped) + dx * 0.55) end
    if dy then
        camDist = math.max(0.9, math.min(3.6, camDist + dy * 0.0025))
        local p = GetEntityCoords(ped)
        SetCamCoord(cam, p.x + camFwd.x * camDist, p.y + camFwd.y * camDist, p.z + camHeight + 0.35)
        PointCamAtCoord(cam, p.x, p.y, p.z + camHeight)
    end
end

-- ───────────── identité ─────────────
exports('OpenIdentity', function()
    startScene()
    openView({ a = 'identity', music = musicCfg(), name = serverName() })
end)
exports('Close', function() closeView() stopScene() end)
RegisterNUICallback('idRegister', function(data, cb)
    local reason = exports.esx_identity:SubmitIdentity(data)
    cb({ ok = reason == nil, error = reason })
end)
RegisterNUICallback('idCancel', function(_, cb) cb({}) exports.esx_identity:CancelIdentity() end)
RegisterNUICallback('idSex', function(d, cb) cb({}) exports.esx_identity:SetSex(d and d.sex or 'm') end)

-- ───────────── apparence ─────────────
local CLOTHES = { tshirt = 1, torso = 1, decals = 1, arms = 1, pants = 1, shoes = 1, mask = 1, bproof = 1, chain = 1, helmet = 1, glasses = 1, watches = 1, bracelets = 1, bags = 1, ears = 1 }
exports('OpenSkin', function(opts, cb)
    opts = opts or {}
    onSkinDone = cb
    TriggerEvent('skinchanger:getData', function(comps, max)
        local list = {}
        for _, c in ipairs(comps) do
            local mx = max and max[c.name]
            local base = c.name:match('^(%a+)_?%d*$')
            local isCloth = base and CLOTHES[base]
            if mx and mx >= 0 and c.name ~= 'sex' and not (opts.hideClothes and isCloth) then
                list[#list + 1] = { name = c.name, label = c.label, value = c.value or 0, min = c.min or 0, max = mx }
            end
        end
        startScene()
        openView({ a = 'skin', comps = list, opts = { hideClothes = opts.hideClothes == true }, music = musicCfg() })
    end)
end)
RegisterNUICallback('skinChange', function(d, cb)
    cb({})
    if d and d.name then TriggerEvent('skinchanger:change', d.name, tonumber(d.value) or 0) end
end)
RegisterNUICallback('skinDone', function(_, cb)
    cb({}) closeView() stopScene()
    local f = onSkinDone onSkinDone = nil
    if f then f() end
end)
RegisterNUICallback('camRotate', function(d, cb) cb({}) moveCam(d and d.dx, nil) end)
RegisterNUICallback('camZoom', function(d, cb) cb({}) moveCam(nil, d and d.dy) end)

-- ───────────── point d'apparition ─────────────
-- points d'apparition : ceux du panel web s'ils existent, sinon ceux d'esx_identity (config)
exports('GetSpawnSpots', function(default)
    local out = {}
    for _, s in ipairs(live.spots or {}) do
        if s.label and s.x and s.y then out[#out + 1] = { label = s.label, description = s.description or '', icon = s.icon, image = s.image, coords = vector4(s.x + 0.0, s.y + 0.0, (s.z or 30.0) + 0.0, (s.h or 0.0) + 0.0) } end
    end
    return #out > 0 and out or default
end)
-- spots = { { label, description, coords = vector4, image? } } → renvoie l'index choisi (bloque jusqu'au choix)
exports('ChooseSpawn', function(spots)
    local list = {}
    for i, s in ipairs(spots or {}) do list[i] = { label = s.label, place = s.place or s.description, desc = s.description, x = s.coords.x + 0.0, y = s.coords.y + 0.0, image = s.image and s.image ~= '' and (s.image:find('^https?://') and s.image or ('places/' .. s.image)) or nil } end
    spawnP = promise.new()
    local M = live.map or {}
    local map = { minX = tonumber(M.minX) or Config.Map.MinX, maxX = tonumber(M.maxX) or Config.Map.MaxX, minY = tonumber(M.minY) or Config.Map.MinY, maxY = tonumber(M.maxY) or Config.Map.MaxY }
    openView({ a = 'spawn', spots = list, map = map, mapImage = (M.image and M.image ~= '' and M.image) or (Config.Map and Config.Map.Image) or nil })
    local idx = Citizen.Await(spawnP)
    closeView()
    return idx
end)
RegisterNUICallback('spawnPick', function(d, cb) cb({}) if spawnP then spawnP:resolve(tonumber(d and d.index) or 1) spawnP = nil end end)

-- ───────────── bienvenue ─────────────
exports('ShowWelcome', function()
    local W = {}
    for k, v in pairs(Config.Welcome or {}) do W[k] = v end
    local L = live.welcome or {}
    for _, k in ipairs({ 'Enabled', 'Title', 'Highlight', 'Text', 'Duration' }) do local lv = L[k:sub(1, 1):lower() .. k:sub(2)] if lv ~= nil and lv ~= '' then W[k] = lv end end
    if W.Enabled == false then return end
    local logo = (L.logo and L.logo ~= '' and L.logo) or 'https://cfx-nui-pickax_theme/logo/logo.png'
    SetNuiFocus(W.Duration == 0, W.Duration == 0)
    SendNUIMessage({ cfg = NuiCfg(), a = 'welcome', title = W.Title, highlight = (W.Highlight and W.Highlight ~= '' and W.Highlight .. ' ' or '') .. serverName(), text = W.Text, duration = W.Duration or 9000, logo = logo })
end)
RegisterNUICallback('welcomeDone', function(_, cb) cb({}) SetNuiFocus(false, false) end)

-- ───────────── animations ─────────────
-- items = { { id, label, cmd, type } } (type : emotes · props · shared · expr · walks)
exports('OpenEmotes', function(items, favs, fav)
    openView({ a = 'emotes', items = items, favs = favs or {}, fav = fav })
end)
RegisterNUICallback('emotePlay', function(d, cb) cb({}) TriggerEvent('pickax_creator:emotePlay', d and d.id) end)
RegisterNUICallback('emoteFav', function(d, cb) cb({}) TriggerEvent('pickax_creator:emoteFav', d) end)

RegisterNUICallback('escape', function(d, cb)
    cb({})
    local v = d and d.view
    if v == 'emotes' then closeView() TriggerEvent('pickax_creator:closed', 'emotes')
    elseif v == 'identity' then exports.esx_identity:CancelIdentity()
    elseif v == 'welcome' then SetNuiFocus(false, false) SendNUIMessage({ a = 'close' }) end
end)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then SetNuiFocus(false, false) stopScene() end end)

-- Test (console F8 ou chat) : /creatortest identity | skin | spawn | welcome | emotes | close   — pour vérifier que les nouveaux écrans fonctionnent
RegisterCommand('creatortest', function(_, args)
    local v = args[1] or 'identity'
    if v == 'identity' then exports['pickax_creator']:OpenIdentity()
    elseif v == 'skin' then exports['pickax_creator']:OpenSkin({ hideClothes = true }, function() print('[pickax_creator] apparence terminée') end)
    elseif v == 'spawn' then
        CreateThread(function() local idx = exports['pickax_creator']:ChooseSpawn(GetResourceState('esx_identity') == 'started' and exports.esx_identity:GetSpots() or {}) print('[pickax_creator] point choisi : ' .. tostring(idx)) end)
    elseif v == 'welcome' then exports['pickax_creator']:ShowWelcome()
    elseif v == 'emotes' then TriggerEvent('pickax_creator:test:emotes')
    else closeView() stopScene() end
end, false)
