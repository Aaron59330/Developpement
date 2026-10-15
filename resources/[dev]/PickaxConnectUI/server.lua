local connectingPlayers = {}
local refreshLoopRunning = false


-- Réglages du panel web (ressource pickax_panel, facultative) : surchargent Config en direct ; retirer le réglage rend la valeur du fichier
local PANEL_KEYS = { name = 'ServerName', sec = 'SecondsPerPlayer', none = 'NoPlayerText', discord = 'DiscordURL', shop = 'ShopURL' }
local panelBase = {}
local function applyPanel()
    if GetResourceState('pickax_panel') ~= 'started' then return end
    local ok, o = pcall(function() return exports.pickax_panel:Get('connect') end)
    if not ok or type(o) ~= 'table' then return end
    for pk, key in pairs(PANEL_KEYS) do
        if o[pk] ~= nil then
            if panelBase[key] == nil then panelBase[key] = { Config[key] } end
            Config[key] = o[pk]
        elseif panelBase[key] ~= nil then
            Config[key] = panelBase[key][1]
            panelBase[key] = nil
        end
    end
    Config.Buttons.discord.url = Config.DiscordURL
    Config.Buttons.shop.url = Config.ShopURL
end

local function buildCard()
    applyPanel()
    local maxClients = GetConvarInt(Config.MaxClientsConvar, 48)
    local playerNames = {}
    local count = 0

    for _, player in pairs(connectingPlayers) do
        if not player.finished then
            count = count + 1
            playerNames[#playerNames + 1] = player.name
        end
    end

    table.sort(playerNames, function(a, b)
        return a:lower() < b:lower()
    end)

    local listText = ""
    for _, playerName in ipairs(playerNames) do
        listText = listText .. "• " .. playerName .. "\n"
    end

    if listText == "" then
        listText = Config.NoPlayerText
    end

    local estimatedTime = count * Config.SecondsPerPlayer

    return {
        ["$schema"] = "http://adaptivecards.io/schemas/adaptive-card.json",
        version = "1.0",
        type = "AdaptiveCard",
        body = {
            {
                type = "TextBlock",
                text = Config.ServerName,
                size = "Large",
                weight = "Bolder",
                horizontalAlignment = "Center"
            },
            {
                type = "TextBlock",
                text = string.format(Config.Texts.playersConnecting, count, maxClients),
                weight = "Bolder",
                horizontalAlignment = "Center",
                spacing = "Small"
            },
            {
                type = "TextBlock",
                text = string.format(Config.Texts.estimatedTime, estimatedTime),
                horizontalAlignment = "Center",
                spacing = "Small"
            },
            {
                type = "TextBlock",
                text = " ",
                spacing = "Medium"
            },
            {
                type = "TextBlock",
                text = Config.Texts.waitingListTitle,
                weight = "Bolder"
            },
            {
                type = "TextBlock",
                text = listText,
                wrap = true
            },
            {
                type = "TextBlock",
                text = " ",
                spacing = "Medium"
            },
            {
                type = "TextBlock",
                text = Config.Texts.playHint,
                horizontalAlignment = "Center"
            }
        },
        actions = {
            {
                type = "Action.Submit",
                title = Config.Buttons.play.title,
                data = { action = Config.Buttons.play.action }
            },
            {
                type = "Action.OpenUrl",
                title = Config.Buttons.discord.title,
                url = Config.Buttons.discord.url
            },
            {
                type = "Action.OpenUrl",
                title = Config.Buttons.shop.title,
                url = Config.Buttons.shop.url
            }
        }
    }
end

local function refreshCards()
    local card = buildCard()

    for src, player in pairs(connectingPlayers) do
        if player.ready and not player.finished then
            local activePlayer = player
            activePlayer.deferrals.presentCard(card, function(data)
                if data and data.action == Config.Buttons.play.action then
                    activePlayer.finish()
                end
            end)
        end
    end
end

local function startRefreshLoop()
    if refreshLoopRunning then
        return
    end

    refreshLoopRunning = true
    CreateThread(function()
        while next(connectingPlayers) do
            Wait(3000)
            if next(connectingPlayers) then
                refreshCards()
            end
        end
        refreshLoopRunning = false
    end)
end

AddEventHandler('playerConnecting', function(name, setReason, deferrals)
    local src = source
    local player = {
        name = name,
        deferrals = deferrals,
        ready = false,
        finished = false
    }

    player.finish = function()
        if player.finished then
            return
        end

        player.finished = true
        connectingPlayers[src] = nil
        refreshCards()

        -- Une attente d'un tick est nécessaire après presentCard avant done.
        Wait(0)
        deferrals.done()
    end

    connectingPlayers[src] = player

    deferrals.defer()
    Wait(0)

    -- Laisser hardcap terminer ses messages avant d'afficher la carte.
    Wait(3500)

    if player.finished or connectingPlayers[src] ~= player then
        return
    end

    player.ready = true
    refreshCards()
    startRefreshLoop()

    local elapsed = 0
    while not player.finished and elapsed < 30000 do
        Wait(1000)
        elapsed = elapsed + 1000
    end

    if not player.finished then
        print(('[connect_ui] Carte sans réponse pour %s : connexion poursuivie.'):format(name))
        player.finish()
    end
end)
