local uiFaded = false
local ESX = exports["es_extended"]:getSharedObject()

-- ── Réglages du joueur (menu personnel → Préférences → Affichage du HUD) ──
local KVP = 'pickax_hud2:settings'
local DEFAULTS = { hud = true, server = true, job = true, money = true, radius = 6, scale = 100 }
local Settings = {}
for k, v in pairs(DEFAULTS) do Settings[k] = v end

local function loadSettings()
    local raw = GetResourceKvpString(KVP)
    local ok, saved = pcall(json.decode, raw or '')
    if ok and type(saved) == 'table' then
        for k, def in pairs(DEFAULTS) do
            if type(saved[k]) == type(def) then Settings[k] = saved[k] end
        end
    end
end

local function applySettings()
    SendNUIMessage({ action = 'setConfig', config = Settings })
end

exports('GetSettings', function() return Settings end)

exports('SetSetting', function(key, value)
    if DEFAULTS[key] == nil or type(value) ~= type(DEFAULTS[key]) then return false end
    if key == 'radius' then value = math.max(0, math.min(30, math.floor(value))) end
    if key == 'scale' then value = math.max(60, math.min(150, math.floor(value))) end
    Settings[key] = value
    SetResourceKvp(KVP, json.encode(Settings))
    applySettings()
    return true
end)

exports('ResetSettings', function()
    for k, v in pairs(DEFAULTS) do Settings[k] = v end
    DeleteResourceKvp(KVP)
    applySettings()
    return true
end)

loadSettings()

local function fmtMoney(v)
    return ESX.Math.GroupDigits(v or 0) .. ' $'
end

local function pushAccounts(accounts)
    local infos = {}
    for _, acc in ipairs(accounts or {}) do
        if acc.name == 'money' or acc.name == 'black_money' or acc.name == 'bank' then
            infos[#infos + 1] = { name = acc.name, value = fmtMoney(acc.money) }
        end
    end
    if #infos > 0 then SendNUIMessage({ action = 'setInfos', infos = infos }) end
end

local function jobIcon(job)
    local icon
    if job and GetResourceState('pickax_notify') == 'started' then
        local jtype
        if GetResourceState('jobbuilder') == 'started' then
            local ok, t = pcall(function() return exports['jobbuilder']:GetJobType() end)
            if ok then jtype = t end
        end
        local ok, res = pcall(function() return exports['pickax_notify']:GetJobIcon(job.name, jtype) end)
        if ok then icon = res end
    end
    return icon or 'job'
end

local function pushJob(job)
    if not job then return end
    SendNUIMessage({
        action = 'setJob',
        label = job.label or job.name,
        grade = job.grade_label or '',
        icon = jobIcon(job),
        civil = job.name == 'unemployed'
    })
end

local function pushPlayers()
    SendNUIMessage({ action = 'setId', value = GetPlayerServerId(PlayerId()) })
    SendNUIMessage({ action = 'setPlayers', value = GlobalState.pickaxPlayers or #GetActivePlayers(), max = GlobalState.pickaxMaxPlayers })
end

local function pushAll()
    applySettings()
    local pd = ESX.GetPlayerData()
    if not pd or not pd.job then return end
    pushAccounts(pd.accounts)
    pushJob(pd.job)
    pushPlayers()
end

CreateThread(function()
    while not ESX.IsPlayerLoaded() do Wait(500) end
    Wait(500)
    pushAll()
    while true do
        pushPlayers()
        Wait(5000)
    end
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    Wait(300)
    pushAccounts(xPlayer.accounts)
    pushJob(xPlayer.job)
    pushPlayers()
end)

RegisterNetEvent('esx:setJob', function(job)
    pushJob(job)
end)

RegisterNetEvent('esx:setAccountMoney', function(account)
    pushAccounts({ account })
end)

AddEventHandler('onClientResourceStart', function(res)
    if res == GetCurrentResourceName() then
        Wait(1000)
        pushAll()
    end
end)

AddEventHandler('tempui:toggleUi', function(value)
    uiFaded = value
    SendNUIMessage({ action = 'fadeUi', value = uiFaded })
end)

CreateThread(function()
    local inFrontend = false
    SendNUIMessage({ action = 'hideUi', value = false })

    while true do
        Wait(150)
        if not uiFaded then
            local hide = IsPauseMenuActive() or IsPlayerSwitchInProgress() or LocalPlayer.state.invOpen == true   -- masqué aussi quand l'inventaire est ouvert
            if hide ~= inFrontend then
                inFrontend = hide
                SendNUIMessage({ action = 'hideUi', value = hide })
            end
        end
    end
end)
