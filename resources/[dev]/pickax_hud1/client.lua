-- Détection fiable : inventaire (signal direct + état du joueur) et menu pause / carte (plusieurs méthodes)
local invFlag = false
AddEventHandler('pickax:inventory', function(open) invFlag = open == true end)

local function inventoryOpen()
    return invFlag or LocalPlayer.state.invOpen == true
end

local function pauseOpen()
    if IsPauseMenuActive() then return true end
    local state = Citizen.InvokeNative(0x272ACD84970869C5, Citizen.ResultAsInteger())   -- état du menu pause (0 = fermé)
    return state ~= nil and state ~= 0
end

local perfLow = false   -- mode performance (pickax_settings)
AddEventHandler('pickax_perf:changed', function(on) perfLow = on == true end)

local ESX = nil
local STATUS_RESOURCE = 'esx_status'
local STATUS_MAX = 1000000
local STATUS_UPDATE_INTERVAL = 500
local HIDE_DEFAULT_HUD = true
local FRAMEWORK_RESOURCE = 'es_extended'
local uiFaded = false
local lastHudSend = 0
local isShowingHiding = false
local hunger = 0
local thirst = 0

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or 0

    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function statusToPercent(status)
    if type(status) ~= 'table' then
        return 0
    end

    if status.percent ~= nil then
        return clamp(status.percent, 0, 100)
    end

    if status.val ~= nil then
        local maxValue = tonumber(STATUS_MAX) or 1000000
        if maxValue <= 0 then
            maxValue = 1000000
        end

        return clamp((tonumber(status.val) or 0) / maxValue * 100, 0, 100)
    end

    return 0
end

local function setHudVisible(visible)
    SendNUIMessage({
        action = 'hideUi',
        value = not visible
    })
end

local function pushStatuses()
    SendNUIMessage({
        action = 'updateHud',
        hunger = clamp(hunger, 0, 100),
        thirst = clamp(thirst, 0, 100)
    })
end

CreateThread(function()
    while ESX == nil do
        local success, object = pcall(function()
            return exports[FRAMEWORK_RESOURCE]:getSharedObject()
        end)

        if success and object then
            ESX = object
            break
        end

        Wait(500)
    end
end)

-- Compatibilite avec l'ancien event utilise par certains HUD ESX.
RegisterNetEvent('esx_newui:updateBasics', function(basics)
    if type(basics) ~= 'table' then
        return
    end

    for i = 1, #basics do
        local status = basics[i]

        if status.name == 'hunger' then
            hunger = clamp(status.percent or status.value, 0, 100)
        elseif status.name == 'thirst' then
            thirst = clamp(status.percent or status.value, 0, 100)
        end
    end
end)

-- Compatibilite supplementaire avec esx_status:onTick.
AddEventHandler('esx_status:onTick', function(statuses)
    if type(statuses) ~= 'table' then
        return
    end

    for i = 1, #statuses do
        local status = statuses[i]
        if status.name == 'hunger' then
            hunger = statusToPercent(status)
        elseif status.name == 'thirst' then
            thirst = statusToPercent(status)
        end
    end
end)

AddEventHandler('tempui:toggleUi', function(value)
    uiFaded = value == true

    SendNUIMessage({
        action = 'fadeUi',
        value = uiFaded
    })
end)

RegisterNetEvent('CorePickax:HUD:Reload:ClientSide', function(stats)
    isShowingHiding = stats == true
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    Wait(500)
    setHudVisible(true)
    pushStatuses()
end)

AddEventHandler('switchFinished', function()
    setHudVisible(true)
end)

-- Methode fiable reprise du HUD fonctionnel : lecture directe de esx_status.
CreateThread(function()
    while true do
        local interval = tonumber(STATUS_UPDATE_INTERVAL) or 500
        if interval < 200 then
            interval = 200
        end
        if perfLow then interval = interval * 2 end

        if GetResourceState(STATUS_RESOURCE) == 'started' then
            TriggerEvent('esx_status:getStatus', 'hunger', function(status)
                hunger = statusToPercent(status)
            end)

            TriggerEvent('esx_status:getStatus', 'thirst', function(status)
                thirst = statusToPercent(status)
            end)
        end

        pushStatuses()
        Wait(interval)
    end
end)

local nextStateCheck = 0
local hideCrosshair = false
CreateThread(function()
    local inFrontend = false

    while true do
        Wait(0)

        if HIDE_DEFAULT_HUD then
            HideHudComponentThisFrame(1)
            HideHudComponentThisFrame(2)
            HideHudComponentThisFrame(6)
            HideHudComponentThisFrame(7)
            HideHudComponentThisFrame(8)
            HideHudComponentThisFrame(9)
            HideHudComponentThisFrame(17)
            HideHudComponentThisFrame(20)

            if hideCrosshair then HideHudComponentThisFrame(14) end   -- viseur masqué depuis le panel web
            if not isShowingHiding then
                HideHudComponentThisFrame(13)
                HideHudComponentThisFrame(3)
                HideHudComponentThisFrame(4)
            end
        end

        -- Optimisation : l'état « menu pause / inventaire / changement de joueur » n'est évalué que toutes les 120 ms (au lieu de 4 natives à chaque image)
        if not uiFaded then
            local now = GetGameTimer()
            if now >= (nextStateCheck or 0) then
                nextStateCheck = now + 120
                local shouldHide = pauseOpen() or IsPlayerSwitchInProgress() or inventoryOpen()   -- masqué aussi quand l'inventaire est ouvert

                -- ordre ré-envoyé toutes les secondes : un message perdu ne laisse jamais le HUD affiché derrière la carte
                if shouldHide ~= inFrontend or now - (lastHudSend or 0) > 1000 then
                    inFrontend = shouldHide
                    lastHudSend = now
                    SendNUIMessage({ action = 'hideUi', value = shouldHide })
                end
            end
        end
    end
end)

-- ── Barre de vie (et armure) sous la minimap : réglages dans config.lua → Config.Health ──
local function sendHealthConfig()
    SendNUIMessage({ action = 'setHealthConfig', config = Config.Health or {} })
end

CreateThread(function()
    Wait(1500)
    sendHealthConfig()
    Wait(4000)
    sendHealthConfig()        -- renvoi : le NUI peut ne pas être prêt au premier envoi
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(800)
        sendHealthConfig()
    end
end)

CreateThread(function()
    local lastHealth, lastArmor, lastSend = -1, -1, 0
    while true do
        Wait(perfLow and 400 or 200)
        local ped = PlayerPedId()
        local health, armor = 0, 0
        if not IsEntityDead(ped) then
            local maxHealth = math.max(1, GetEntityMaxHealth(ped) - 100)
            health = clamp(math.floor((GetEntityHealth(ped) - 100) / maxHealth * 100 + 0.5), 0, 100)
            armor = clamp(GetPedArmour(ped), 0, 100)
        end
        -- envoi seulement si la valeur change (et un rappel toutes les 3 s au cas où un message se perdrait)
        if health ~= lastHealth or armor ~= lastArmor or GetGameTimer() - lastSend > 3000 then
            lastHealth, lastArmor, lastSend = health, armor, GetGameTimer()
            SendNUIMessage({ action = 'updateHealth', health = health, armor = armor })
        end
    end
end)

-- Bandeau du HUD staff (appelé par le menu admin) : exports.pickax_hud1:StaffBar({ tag, items = { { n, u, x } }, flags = { { t, c } } }) ou { hidden = true }
exports('StaffBar', function(data)
    SendNUIMessage({ action = 'staffBar', data = data })
end)


-- Bandeau « zone safe » : évènement envoyé par pickax_core (players/safezone) quand le joueur entre / sort de la zone
AddEventHandler('pickax:safezone', function(on)
    SendNUIMessage({ action = 'safeZone', value = on == true })
end)


-- Réglages du serveur (panel web > Réglages) : affichage des jauges.
AddEventHandler('pickax_settings:changed', function(all, ov)
    if not ov then return end
    if ov.hud_health ~= nil then Config.Health = Config.Health or {} Config.Health.Enabled = all.hud_health end
    if ov.hud_armor ~= nil then Config.Health = Config.Health or {} Config.Health.ShowArmor = all.hud_armor end
    if ov.hud_health ~= nil or ov.hud_armor ~= nil then sendHealthConfig() end
    if ov.hud_needs ~= nil then SendNUIMessage({ action = 'setNeeds', value = all.hud_needs }) end
    if ov.hud_crosshair ~= nil then hideCrosshair = all.hud_crosshair == false end
end)
