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

local function toneOf(t)
    if t == 'success' or t == 'error' or t == 'warning' then return t end
end

-- Même signature que ESX.ShowNotification(msg, type, length) ; `type` peut aussi être l'ancien hudColorIndex (ignoré)
local function ShowNotification(msg, typeOrColor, length)
    local tone = toneOf(typeOrColor)
    sendNotification({
        kind = 'info',
        title = (tone == 'success' and 'Succès') or (tone == 'error' and 'Erreur') or (tone == 'warning' and 'Attention') or 'Information',
        message = msg,
        tone = tone,
        hudColorIndex = (type(typeOrColor) == 'number') and typeOrColor or nil,
        duration = getNumber(length, getNumber(Config.NotificationDuration, 4500))
    })
end

-- Notification riche (ox_lib / scripts modernes) : { title, description, type, duration }
local function Notify(data)
    data = type(data) == 'table' and data or { description = tostring(data) }
    local tone = toneOf(data.type)
    sendNotification({
        kind = 'info',
        title = data.title or ((tone == 'success' and 'Succès') or (tone == 'error' and 'Erreur') or (tone == 'warning' and 'Attention') or 'Information'),
        message = data.description or data.message or '',
        tone = tone,
        duration = getNumber(data.duration, getNumber(Config.NotificationDuration, 4500))
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

-- Aide contextuelle (« Appuie sur E… ») : souvent appelée à chaque frame par les scripts.
-- Même texte = on rafraîchit seulement (aucun compteur, aucune pile) ; l'aide disparaît dès que le script cesse de l'appeler.
local lastHelp, lastHelpAt = nil, 0
local function ShowHelpNotification(msg)
    msg = normalizeText(msg)
    local now = GetGameTimer()
    if msg == lastHelp and now - lastHelpAt < 250 then return end
    lastHelp, lastHelpAt = msg, now
    sendNotification({
        kind = 'help',
        title = 'Aide',
        message = msg,
        noCounter = true,
        duration = getNumber(Config.HelpNotificationDuration, 1200)
    })
end

exports('ShowNotification', ShowNotification)
exports('Notify', Notify)
exports('ShowAdvancedNotification', ShowAdvancedNotification)
exports('ShowHelpNotification', ShowHelpNotification)

RegisterNetEvent('pickax_notify:showNotification', ShowNotification)
RegisterNetEvent('pickax_notify:notify', Notify)
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
