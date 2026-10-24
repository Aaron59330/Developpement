ESX = ESX or exports["es_extended"]:getSharedObject()

ESXCustomServerUtils = {}

ESXCustomServerUtils.toClient = function(eventName, targetId, ...)
    if eventName == Config.Trigger.TriggerNotification or eventName == Config.Trigger.TriggerAdvancedNotification then
        TriggerClientEvent(eventName, targetId, ...)
    else
        TriggerClientEvent("CorePickax:".. GetHashKey(eventName), targetId, ...)
    end

    if Config.Debug then
        print("event : "..eventName.." was used")
    end
end

ESXCustomServerUtils.kickPlayer = function(source, reason)
    if reason == nil then reason = "Non défini" end
    DropPlayer(source, reason)

    if Config.Debug then
        print("event kick for "..source.." was used")
    end
end

-- Rejet anti-faux-positif : bloque l'action suspecte sans expulser le joueur.
ESXCustomServerUtils.rejectSuspiciousAction = function(source, reason)
    local playerName = GetPlayerName(source) or "inconnu"
    local message = reason or "Action refusée par la sécurité"
    print(("[^3SECURITY^0] Action refusée sans kick | ID: %s | Joueur: %s | Raison: %s"):format(tostring(source), playerName, tostring(message)))
    return false
end

ESXCustomServerUtils.registerServerCallback = ESX.RegisterServerCallback

ESXCustomServerUtils.registerConsoleCommand = function(command, func)
    RegisterCommand(command, function(source,args)
        if source ~= 0 then return end
        func(source, args)
    end, false)
    if Config.Debug then
        print(command.." was registered")
    end
end

ESXCustomServerUtils.registerCommand = function(command, func)
    RegisterCommand(command, function(source,args)
        if source == 0 then return end
        VerifyToken(source, function()
            func(source, args)
        end)
    end, false)
    if Config.Debug then
        print("Command /"..command.." was registered")
    end
end

ESXCustomServerUtils.trace = function(message, prefix)
    print("[^6ESXCustom^0] (^6" .. prefix .. "^0) ^6" .. message .. "^0")
end

ESXCustomServerUtils.GetDistance = function(source, position, distance, eventName, security, onAccepted, onRefused)
    VerifyToken(source, function()
        if #(GetEntityCoords(GetPlayerPed(source)) - position) < distance then
            onAccepted();
        else
            onRefused();
            if security then
                local xPlayer = ESX.GetPlayerFromId(source)
                return ESXCustomServerUtils.rejectSuspiciousAction(source, 'Désynchronisation avec le serveur ou detection de Cheat [' ..eventName..']')
            end
        end
    end)
end

function ESXCustomServerUtils.sendToDiscord(name, message, color, WebhookLink, desc)
	if message == nil or message == '' then
		return false
	end
	if WebhookLink == nil or WebhookLink == '' then
		return false
	end

    local date = os.date("*t")
    if date.day < 10 then date.day = '0' .. tostring(date.day) end
    if date.month < 10 then date.month = '0' .. tostring(date.month) end
    if date.hour < 10 then date.hour = '0' .. tostring(date.hour) end
    if date.min < 10 then date.min = '0' .. tostring(date.min) end
    if date.sec < 10 then date.sec = '0' .. tostring(date.sec) end

	local embeds = {
		{
			['title'] = message,
            ["description"] = desc,
			['type'] = 'rich',
			['color'] = color,
			['footer'] = {
                ["text"] = ("%s/%s/%s à %sh%sm %ss"):format(date.day, date.month, date.year, date.hour, date.min, date.sec),
			}
		}
	}

	PerformHttpRequest(WebhookLink, function() end, 'POST', json.encode({username = name, embeds = embeds}), {['Content-Type'] = 'application/json'})
end

RegisterNetEvent('esx:customDiscordLog', function(botName, embedContent, embedColor, WebhookLink, Desc)
    ESXCustomServerUtils.sendToDiscord(botName or 'Nom du bot vide', embedContent or 'Message Vide', embedColor or 16711680, WebhookLink, Desc)
end)

exports('LogsESX', ESXCustomServerUtils.sendToDiscord)

function CheckLogs(QQ)
    return ConfigSV.Logs[QQ]
end

exports('ConfigLogs', CheckLogs)

PlayerLoadedEvent = {}
AddEventHandler('esx:playerLoaded', function(eventSrc, xPlayer)
    Wait(5000)
    PlayerLoadedEvent[eventSrc] = true
end)

AddEventHandler('esx:playerDropped', function(eventSrc, xPlayer)
    PlayerLoadedEvent[eventSrc] = nil
end)

-- Players updaters task
local TablePlayerAllowFDP = {}
Citizen.CreateThread(function()
    while true do
        Wait(10000)
        local xPlayers = GetPlayers()
        for source, player in pairs(xPlayers) do
            if ESX.GetPlayerFromId(player) ~= nil then
                player = tonumber(player)
                if not TablePlayerAllowFDP[player] then
                    TablePlayerAllowFDP[player] = {}
                    TablePlayerAllowFDP[player].name = GetPlayerName(player)
                    TablePlayerAllowFDP[player].id = player
                    TablePlayerAllowFDP[player].group = ESX.GetPlayerFromId(player).getGroup()
                else
                    TablePlayerAllowFDP[player].group = ESX.GetPlayerFromId(player).getGroup()
                end

                -- infos RP pour la balise de nom du staff : nom/prénom RP, métier et gang/orga
                local xp = ESX.GetPlayerFromId(player)
                local info = TablePlayerAllowFDP[player]
                info.rpname = xp.getName and xp.getName() or nil
                local function lbl(j, bad)
                    if not j or not j.name or j.name == '' or j.name:find(bad) then return nil end
                    local l = tostring(j.label or j.name)
                    if j.grade_label and j.grade_label ~= '' and j.grade_label ~= l then l = l .. ' - ' .. j.grade_label end
                    return l
                end
                info.job = lbl(xp.job, '^unemployed')
                info.gang = lbl(xp.job2, '^unemployed')

                local KK = ESX.GetPlayerFromId(player).getGroup()
                if KK ~= "user" then
                    TriggerClientEvent("CorePickax:updatePlayers", player, TablePlayerAllowFDP)
                end
            end
        end
    end
end)

PlayerLoadedEvent = {}
AddEventHandler('esx:playerLoaded', function(eventSrc, xPlayer)
    Wait(5000)
    PlayerLoadedEvent[eventSrc] = true

    if ESX.GetPlayerFromId(eventSrc) ~= nil then
        if not TablePlayerAllowFDP[eventSrc] then
            TablePlayerAllowFDP[eventSrc] = {}
            TablePlayerAllowFDP[eventSrc].name = GetPlayerName(eventSrc)
            TablePlayerAllowFDP[eventSrc].id = eventSrc
            TablePlayerAllowFDP[eventSrc].group = ESX.GetPlayerFromId(eventSrc).getGroup()
        end
    end
end)

AddEventHandler('esx:playerDropped', function(eventSrc, xPlayer)
    PlayerLoadedEvent[eventSrc] = nil

    if TablePlayerAllowFDP[eventSrc] ~= nil then
        TablePlayerAllowFDP[eventSrc] = nil
    end
end)