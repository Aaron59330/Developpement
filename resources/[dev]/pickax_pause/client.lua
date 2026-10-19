local ESX = exports['es_extended']:getSharedObject()
local open, suppress, lastClose, pauseSeen, suppressAt = false, false, 0, false, 0

local function playerData()
    local pd = ESX.GetPlayerData() or {}
    local acc = {}
    for _, a in ipairs(pd.accounts or {}) do acc[a.name] = a.money end
    local name = ((pd.firstName or '') .. ' ' .. (pd.lastName or '')):gsub('^%s+', '')
    if name == '' then name = pd.name or GetPlayerName(PlayerId()) end
    return {
        name = name, id = GetPlayerServerId(PlayerId()),
        job = pd.job and pd.job.label or '', grade = pd.job and pd.job.grade_label or '',
        job2 = pd.job2 and pd.job2.name ~= 'unemployed2' and pd.job2.label or '', grade2 = pd.job2 and pd.job2.grade_label or '',
        money = acc.money or 0, bank = acc.bank or 0, dirty = acc.black_money or 0,
    }
end

local function openMenu()
    if open then return end
    open = true
    TriggerEvent('pickax:inventory', true)   -- les HUD (hud1/2, minimap, compteur, voix, notifs) se masquent comme avec l'inventaire
    ESX.TriggerServerCallback('pickax_pause:info', function(srv)
        SendNUIMessage({
            action = 'open', player = playerData(), server = srv or {},
            cfg = { name = Config.ServerName, tagline = Config.Tagline, links = Config.Links, buttons = Config.Buttons, sounds = Config.Sounds ~= false, volume = Config.SoundVolume or 0.5 },
        })
    end)
    SetNuiFocus(true, true)
    if Config.BlurScreen then TriggerScreenblurFadeIn(300) end
end

local function closeMenu()
    if not open then return end
    open = false
    TriggerEvent('pickax:inventory', false)
    lastClose = GetGameTimer()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    if Config.BlurScreen then TriggerScreenblurFadeOut(300) end
end

-- Ouvre le vrai menu pause GTA (carte / paramètres) sans le re-bloquer
local function frontend(tab)
    closeMenu()
    suppress, pauseSeen, suppressAt = true, false, GetGameTimer()
    CreateThread(function()
        Wait(150)
        ActivateFrontendMenu(joaat('FE_MENU_VERSION_MP_PAUSE'), false, -1)
        Wait(250)
        PauseMenuceptionGoDeeper(tab or 0)
    end)
end

RegisterNUICallback('close', function(_, cb) closeMenu() cb({}) end)
RegisterNUICallback('map', function(_, cb) frontend(Config.FrontendTabs.map) cb({}) end)
RegisterNUICallback('settings', function(_, cb) frontend(Config.FrontendTabs.settings) cb({}) end)
RegisterNUICallback('disconnect', function(_, cb) cb({}) closeMenu() ExecuteCommand('disconnect') end)
RegisterNUICallback('quit', function(_, cb) cb({}) closeMenu() ExecuteCommand('quit') end)

CreateThread(function()
    while true do
        Wait(0)
        if suppress then
            -- le menu GTA est ouvert volontairement : on laisse ÉCHAP le fermer, puis on reprend la main
            if IsPauseMenuActive() then pauseSeen = true
            elseif pauseSeen or GetGameTimer() > suppressAt + 3000 then suppress, lastClose = false, GetGameTimer() end
        else
            for _, k in ipairs(Config.OpenKeys) do DisableControlAction(0, k, true) end
            if IsPauseMenuActive() then SetPauseMenuActive(false) end
            if not open and GetGameTimer() > lastClose + Config.Cooldown and not IsNuiFocused() then
                for _, k in ipairs(Config.OpenKeys) do
                    if IsDisabledControlJustPressed(0, k) then openMenu() break end
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and open then SetNuiFocus(false, false) TriggerScreenblurFadeOut(0) TriggerEvent('pickax:inventory', false) end
end)

exports('IsOpen', function() return open end)
exports('Open', openMenu)
exports('Close', closeMenu)
