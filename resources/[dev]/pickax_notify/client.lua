Config = Config or {}

local function getNumber(value, fallback)
    value = tonumber(value)
    if value == nil then return fallback end
    return value
end

local function getBool(value, fallback)
    if value == nil then return fallback end
    return value == true
end

local function getUiConfig()
    return {
        mainColor = Config.MainColor or '#00a4ff',
        backgroundColor = Config.BackgroundColor or '#070c12',
        backgroundTransparency = getNumber(Config.BackgroundTransparency, 0.68),

        textColor = Config.TextColor or '#f7f7fb',
        smallTextColor = Config.SmallTextColor or '#b7b6c1',
        successColor = Config.SuccessColor or '#5be39a',
        errorColor = Config.ErrorColor or '#ff7373',
        warningColor = Config.WarningColor or '#ffd86a',
        blueTextColor = Config.BlueTextColor or '#74b7ff',

        width = Config.Width or 'clamp(270px, 14.2vw, 315px)',
        minHeight = getNumber(Config.MinHeight, 65),
        borderRadius = getNumber(Config.BorderRadius, 11),

        paddingTop = getNumber(Config.PaddingTop, 11),
        paddingRight = getNumber(Config.PaddingRight, 13),
        paddingBottom = getNumber(Config.PaddingBottom, 12),
        paddingLeft = getNumber(Config.PaddingLeft, 16),

        sideLineWidth = getNumber(Config.SideLineWidth, 4),
        sideLineEnabled = getBool(Config.SideLineEnabled, true),

        progressLineEnabled = getBool(Config.ProgressLineEnabled, true),
        progressLineHeight = getNumber(Config.ProgressLineHeight, 2),
        progressLineOpacity = getNumber(Config.ProgressLineOpacity, 0.85),

        positionLeft = tostring(Config.PositionLeft or '1.35vw'),
        positionBottom = tostring(Config.PositionBottom or '22.5vh'),
        notificationGap = getNumber(Config.NotificationGap, 8),

        titleFontSize = getNumber(Config.TitleFontSize, 12.5),
        titleFontWeight = getNumber(Config.TitleFontWeight, 750),
        messageFontSize = getNumber(Config.MessageFontSize, 12),
        messageFontWeight = getNumber(Config.MessageFontWeight, 600),
        messageLineHeight = getNumber(Config.MessageLineHeight, 1.45),
        smallTextFontSize = getNumber(Config.SmallTextFontSize, 10.5),
        smallTextFontWeight = getNumber(Config.SmallTextFontWeight, 600),
        headerGap = getNumber(Config.HeaderGap, 7),
        headerBottomSpacing = getNumber(Config.HeaderBottomSpacing, 6),

        iconEnabled = getBool(Config.IconEnabled, true),
        iconBoxSize = getNumber(Config.IconBoxSize, 22),
        iconSize = getNumber(Config.IconSize, 13),
        iconRadius = getNumber(Config.IconRadius, 7),
        iconStrokeWidth = getNumber(Config.IconStrokeWidth, 1.9),
        iconBackgroundOpacity = getNumber(Config.IconBackgroundOpacity, 0.12),
        iconBorderOpacity = getNumber(Config.IconBorderOpacity, 0.34),

        stackWindow = getNumber(Config.StackWindow, 3000),
        counterEnabled = getBool(Config.CounterEnabled, true),
        counterSize = getNumber(Config.CounterSize, 16),
        counterFontSize = getNumber(Config.CounterFontSize, 9),
        counterRadius = getNumber(Config.CounterRadius, 6),
        counterTop = getNumber(Config.CounterTop, 6),
        counterRight = getNumber(Config.CounterRight, 6),
        counterBackgroundOpacity = getNumber(Config.CounterBackgroundOpacity, 0.92),

        maxVisibleNotifications = math.max(1, math.floor(getNumber(Config.MaxVisibleNotifications, 4)))
    }
end

RegisterNUICallback('getConfig', function(_, cb)
    cb(getUiConfig())
end)

local function sendUiConfig()
    SendNUIMessage({
        action = 'config',
        config = getUiConfig()
    })
end

CreateThread(function()
    Wait(500)
    sendUiConfig()
end)

RegisterNetEvent('pickax_notify:refreshConfig', function()
    sendUiConfig()
end)

local function normalizeText(text)
    if text == nil then return '' end
    return tostring(text)
end

local function sendNotification(data)
    data = data or {}
    data.action = 'notify'
    data.message = normalizeText(data.message)
    data.config = getUiConfig()
    SendNUIMessage(data)
end

-- Même signature que ESX.ShowNotification(msg, hudColorIndex)
local function ShowNotification(msg, hudColorIndex)
    sendNotification({
        kind = 'info',
        title = 'Information',
        message = msg,
        hudColorIndex = hudColorIndex,
        duration = getNumber(Config.NotificationDuration, 4500)
    })
end

-- Même signature que ESX.ShowAdvancedNotification(...)
local function ShowAdvancedNotification(title, subject, msg, icon, iconType, hudColorIndex)
    sendNotification({
        kind = 'advanced',
        title = title or 'Information',
        subject = subject or '',
        message = msg,
        icon = icon,
        iconType = iconType,
        hudColorIndex = hudColorIndex,
        duration = getNumber(Config.AdvancedNotificationDuration, 5500)
    })
end

-- Même signature que ESX.ShowHelpNotification(msg)
local function ShowHelpNotification(msg)
    sendNotification({
        kind = 'help',
        title = 'Aide',
        message = msg,
        duration = getNumber(Config.HelpNotificationDuration, 5000)
    })
end

exports('ShowNotification', ShowNotification)
exports('ShowAdvancedNotification', ShowAdvancedNotification)
exports('ShowHelpNotification', ShowHelpNotification)

RegisterNetEvent('pickax_notify:showNotification', ShowNotification)
RegisterNetEvent('pickax_notify:showAdvancedNotification', ShowAdvancedNotification)
RegisterNetEvent('pickax_notify:showHelpNotification', ShowHelpNotification)

RegisterCommand('testnotif', function()
    ShowNotification('Vous avez désormais accès au ~g~mode administration~s~.')
end, false)

RegisterCommand('testadvancednotif', function()
    ShowAdvancedNotification('Administration', 'Information', 'Votre mode administration est maintenant ~g~activé~s~.', 'CHAR_DEFAULT', 1)
end, false)

RegisterCommand('testhelpnotif', function()
    ShowHelpNotification('Appuyez sur ~INPUT_CONTEXT~ pour interagir.')
end, false)
