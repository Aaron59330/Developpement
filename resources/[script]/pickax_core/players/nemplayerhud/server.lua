local ESX = exports['es_extended']:getSharedObject()

local Players = {}
local ProtectedPlayers = {}

local function isProtected(seconds)
    return (seconds or 0) < ConfigNewPlayer.RequiredPlayTime
end

local function broadcastProtection(source, protected)
    ProtectedPlayers[source] = protected or nil
    TriggerClientEvent('newplayer:setProtection', -1, source, protected)
end

local function sendProtectionList(target)
    local list = {}

    for source, protected in pairs(ProtectedPlayers) do
        if protected then
            list[source] = true
        end
    end

    TriggerClientEvent('newplayer:syncProtection', target, list)
end

local function loadPlayer(source, xPlayer)
    if not source or source <= 0 or not xPlayer then
        return
    end

    local identifier = xPlayer.identifier
    if not identifier then
        return
    end

    local playedSeconds = MySQL.scalar.await(
        'SELECT played_seconds FROM newplayer_playtime WHERE identifier = ?',
        { identifier }
    )

    if playedSeconds == nil then
        MySQL.insert.await(
            'INSERT INTO newplayer_playtime (identifier, played_seconds) VALUES (?, 0)',
            { identifier }
        )
        playedSeconds = 0
    end

    playedSeconds = tonumber(playedSeconds) or 0

    Players[source] = {
        identifier = identifier,
        playedSeconds = playedSeconds,
        lastUpdate = os.time()
    }

    broadcastProtection(source, isProtected(playedSeconds))
    sendProtectionList(source)
end

local function updatePlaytime(source, saveToDatabase)
    local data = Players[source]
    if not data then
        return
    end

    local now = os.time()
    local elapsed = math.max(0, now - data.lastUpdate)

    if elapsed > 0 then
        data.playedSeconds = data.playedSeconds + elapsed
        data.lastUpdate = now
    end

    if saveToDatabase then
        MySQL.update.await(
            'UPDATE newplayer_playtime SET played_seconds = ? WHERE identifier = ?',
            { data.playedSeconds, data.identifier }
        )
    end

    local protected = isProtected(data.playedSeconds)

    if protected then
        if not ProtectedPlayers[source] then
            broadcastProtection(source, true)
        end
    elseif ProtectedPlayers[source] then
        broadcastProtection(source, false)
    end
end

RegisterNetEvent('newplayer:requestSync', function()
    sendProtectionList(source)
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    loadPlayer(playerId, xPlayer)
end)

AddEventHandler('playerDropped', function()
    local source = source

    if Players[source] then
        updatePlaytime(source, true)
        Players[source] = nil
    end

    if ProtectedPlayers[source] then
        ProtectedPlayers[source] = nil
        TriggerClientEvent('newplayer:setProtection', -1, source, false)
    end
end)

AddEventHandler('weaponDamageEvent', function(sender, data)
    local player = Players[sender]

    if player then
        updatePlaytime(sender, false)

        if ConfigNewPlayer.BlockWeapons and isProtected(player.playedSeconds) then
            CancelEvent()
        end
    end
end)

CreateThread(function()
    Wait(1500)

    for _, xPlayer in pairs(ESX.GetExtendedPlayers()) do
        if xPlayer and xPlayer.source then
            loadPlayer(xPlayer.source, xPlayer)
        end
    end

    while true do
        Wait(ConfigNewPlayer.SaveInterval * 1000)

        local sources = {}

        for source in pairs(Players) do
            sources[#sources + 1] = source
        end

        for i = 1, #sources do
            local source = sources[i]

            if GetPlayerName(source) then
                updatePlaytime(source, true)
            else
                Players[source] = nil

                if ProtectedPlayers[source] then
                    ProtectedPlayers[source] = nil
                    TriggerClientEvent('newplayer:setProtection', -1, source, false)
                end
            end
        end
    end
end)
