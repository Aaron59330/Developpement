-- ═════════════════════════════════════════════════════════════════════════════
--  Couche de compatibilité (client) : ESX · QBCore · Qbox · standalone
-- ═════════════════════════════════════════════════════════════════════════════
Bridge = { fw = 'standalone' }

local function started(name) return GetResourceState(name) == 'started' end
local function exists(name) local s = GetResourceState(name); return s ~= 'missing' and s ~= 'unknown' end
local ESX, QBCore

CreateThread(function()
    local f = (Config.Framework or 'auto'):lower()
    if f == 'auto' then
        f = exists('qbx_core') and 'qbox' or exists('es_extended') and 'esx' or exists('qb-core') and 'qb' or 'standalone'
    end
    Bridge.fw = f
    local t = 0
    if f == 'esx' then while not started('es_extended') and t < 300 do Wait(100) t = t + 1 end ESX = exports['es_extended']:getSharedObject()
    elseif f == 'qb' then while not started('qb-core') and t < 300 do Wait(100) t = t + 1 end QBCore = exports['qb-core']:GetCoreObject()
    elseif f == 'qbox' then if started('qb-core') then QBCore = exports['qb-core']:GetCoreObject() end end
    Bridge.ready = true
end)

-- ───────────── notifications ─────────────
function Bridge.Notify(msg)
    local m = (Config.Notify or 'ox_lib'):lower()
    if m == 'custom' and Config.Hooks.notify then return Config.Hooks.notify(msg) end
    if m == 'esx' and ESX then return ESX.ShowNotification(msg) end
    if m == 'qb' and QBCore then return QBCore.Functions.Notify(msg) end
    if m == 'qbox' and started('qbx_core') then return exports.qbx_core:Notify(msg) end
    if m == 'native' or not started('ox_lib') then
        BeginTextCommandThefeedPost('STRING'); AddTextComponentSubstringPlayerName(msg); EndTextCommandThefeedPostTicker(false, false)
        return
    end
    lib.notify({ title = Config.Brand, description = msg, type = 'inform' })
end
RegisterNetEvent('aura:notifyGame', function(msg) Bridge.Notify(msg) end)

-- ───────────── état du joueur ─────────────
local function qbMeta()
    if Bridge.fw == 'qbox' and started('qbx_core') then local ok, d = pcall(function() return exports.qbx_core:GetPlayerData() end); return ok and d and d.metadata end
    if QBCore then local d = QBCore.Functions.GetPlayerData(); return d and d.metadata end
end

function Bridge.IsDead()
    local ped = PlayerPedId()
    if IsPedDeadOrDying(ped, true) then return true end
    local st = LocalPlayer.state
    if st.isDead or st.dead then return true end
    if Bridge.fw == 'esx' and ESX then local d = ESX.GetPlayerData(); return d and d.dead or false end
    if Bridge.fw == 'qb' or Bridge.fw == 'qbox' then local m = qbMeta(); return m and (m.isdead or m.inlaststand) or false end
    return false
end

function Bridge.IsCuffed()
    if IsPedCuffed(PlayerPedId()) then return true end
    local st = LocalPlayer.state
    if st.cuffed or st.isCuffed or st.handcuffed then return true end
    if Bridge.fw == 'qb' or Bridge.fw == 'qbox' then local m = qbMeta(); return m and m.ishandcuffed or false end
    return false
end

-- faim / soif (0-100) pour l'application Santé
function Bridge.Status()
    local mode = (Config.Status or 'auto'):lower()
    if mode == 'custom' and Config.Hooks.status then return Config.Hooks.status() or {} end
    if mode == 'auto' then
        if Bridge.fw == 'qb' or Bridge.fw == 'qbox' then mode = 'qb' elseif started('esx_status') then mode = 'esx_status' else mode = 'none' end
    end
    local out = {}
    if mode == 'qb' then
        local m = qbMeta()
        if m then out.hunger = math.floor(m.hunger or 0); out.thirst = math.floor(m.thirst or 0) end
    elseif mode == 'esx_status' then
        local got = 0
        for _, s in ipairs({ 'hunger', 'thirst' }) do
            pcall(function() TriggerEvent('esx_status:getStatus', s, function(st) if st then out[s] = math.floor(st.getPercent()) end got = got + 1 end) end)
        end
        local t = 0
        while got < 2 and t < 15 do Wait(20); t = t + 1 end
    end
    return out
end

-- possession du téléphone (vérifié côté serveur, mis en cache 2 s)
local hasCache, hasAt = false, 0
function Bridge.HasPhone(force)
    if not Config.RequireItem then return true end
    if not force and GetGameTimer() - hasAt < 2000 then return hasCache end
    hasCache = lib.callback.await('aura:hasPhone', false) and true or false
    hasAt = GetGameTimer()
    return hasCache
end

-- ───────────── voix des appels ─────────────
local voiceMode
local function voice()
    if voiceMode then return voiceMode end
    local m = (Config.Voice or 'auto'):lower()
    if m == 'auto' then
        if started('pma-voice') then m = 'pma-voice' elseif started('mumble-voip') then m = 'mumble-voip' elseif started('saltychat') then m = 'saltychat' else m = 'none' end
    end
    voiceMode = m
    return m
end

local current = { channel = 0, peer = nil }
function Bridge.VoiceStart(channel, peer)
    current = { channel = channel, peer = peer }
    local m = voice()
    if m == 'pma-voice' then pcall(function() exports['pma-voice']:setCallChannel(channel) end)
    elseif m == 'mumble-voip' then pcall(function() exports['mumble-voip']:SetCallChannel(channel) end)
    elseif m == 'saltychat' and peer then pcall(function() exports.saltychat:EstablishCall(peer) end)
    elseif m == 'custom' and Config.Hooks.voiceStart then Config.Hooks.voiceStart(channel, peer)
    elseif Config.Debug then print('^3[pickax_phone] aucune ressource vocale détectée : appels sans voix^7') end
end
function Bridge.VoiceStop()
    local m, c = voice(), current
    if m == 'pma-voice' then pcall(function() exports['pma-voice']:setCallChannel(0) end)
    elseif m == 'mumble-voip' then pcall(function() exports['mumble-voip']:SetCallChannel(0) end)
    elseif m == 'saltychat' and c.peer then pcall(function() exports.saltychat:EndCall(c.peer) end)
    elseif m == 'custom' and Config.Hooks.voiceStop then Config.Hooks.voiceStop(c.channel, c.peer) end
    current = { channel = 0, peer = nil }
end

-- ───────────── déconnexion du personnage ─────────────
function Bridge.OnLogout(cb)
    RegisterNetEvent('esx:onPlayerLogout', cb)
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', cb)
end
