local EventStart = false
local CooldownActive = false
local Cooldown = 0
local PlayerConnected = {}

RegisterNetEvent('esx_custom:ReceiveMoney', function(lapose)
    local src = source
    VerifyToken(src, function()
        local xPlayer = ESX.GetPlayerFromId(src)
        ESXCustomServerUtils.GetDistance(src, lapose, 10, "ReceiveMoney", true, function()
            ESXCustom_Function_ServerSide:sendToDiscord('Coffre au trésor', (ConfigChasseAuTresor.Notification["NotifDiscord"]):format(GetPlayerName(src), ConfigChasseAuTresor.WinMoney), ConfigSV.Logs["LogsChasseAuTresor"])
            AddMoney(src, ConfigChasseAuTresor.WinMoney)
            TriggerClientEvent(Config.Trigger.TriggerNotification, src, (ConfigChasseAuTresor.Notification["WinMoney"]):format(ConfigChasseAuTresor.WinMoney))
        end, function()
        end)
    end)
end)

RegisterNetEvent('esx_custom:ReceiveItem', function(lapose)
    local _source = source

    VerifyToken(_source, function()
        local xPlayer = ESX.GetPlayerFromId(_source)
        if #(GetEntityCoords(GetPlayerPed(_source)) - lapose) < 10.0 then
            local random = math.random(1, #ConfigChasseAuTresor.ListItemWin)
            local WinItem = {item = ConfigChasseAuTresor.ListItemWin[random].Item, amount = ConfigChasseAuTresor.ListItemWin[random].Amount, label = ConfigChasseAuTresor.ListItemWin[random].Label}
            ESXCustom_Function_ServerSide:sendToDiscord('Coffre au trésor', (ConfigChasseAuTresor.Notification["NotifDiscord2"]):format(GetPlayerName(_source), ConfigChasseAuTresor.ListItemWin[random].Amount, ConfigChasseAuTresor.ListItemWin[random].Label), ConfigSV.Logs["LogsChasseAuTresor"])
            Wait(2000)
            AddItemOnPlayer(_source, WinItem.item, WinItem.amount)
            TriggerClientEvent(Config.Trigger.TriggerNotification, _source, (ConfigChasseAuTresor.Notification["WinItem"]):format(WinItem.amount, WinItem.label))
        else
            TriggerEvent("esx_custom:PlayerKick", _source, 1)
        end
    end)
end)


RegisterNetEvent('esx_custom:SendServerSideChasse', function()
    if PlayerConnected[source] ~= nil then
        PlayerConnected[source] = nil
    end

    CooldownActive = true
    Cooldown = ConfigChasseAuTresor.Cooldown

    CreateThread(function()
        while CooldownActive do

            if Cooldown == 0 then
                EventStart = false
                CooldownActive = false
                break
            end

            Cooldown = Cooldown - 1000

            if not CooldownActive then
                EventStart = false
            end
            Wait(1000)
        end
    end)
    
    TriggerClientEvent("esx_custom:StopEvent", -1)
end)

function GetPermission(source)
    for k, v in pairs(ConfigChasseAuTresor.GroupAcces) do
        if v == ESX.GetPlayerFromId(source).getGroup() then
            return true
        end
    end

    return false
end

--GetTimer
function formatDuration(milliseconds)
    local totalSeconds = math.floor(milliseconds / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    return string.format("%02d:%02d", minutes, seconds)
end

ESXCustomServerUtils.registerCommand(ConfigChasseAuTresor.CommandeName, function(source)
    if CooldownActive then
        local formattedDuration = formatDuration(Cooldown)
        TriggerClientEvent(Config.Trigger.TriggerNotification, source, (ConfigChasseAuTresor.Notification["EventCantStart"]):format(formattedDuration))
    else
        if PlayerConnected[source] == nil then
            PlayerConnected[source] = {}
            PlayerConnected[source].CountSpam = 0
        else
            PlayerConnected[source].CountSpam = PlayerConnected[source].CountSpam + 1
        end

        if PlayerConnected[source].CountSpam == 3 then
            TriggerEvent("esx_custom:PlayerKick", source, 2)
            PlayerConnected[source] = nil
        end

        if EventStart ~= true then
            if ConfigChasseAuTresor.AcePermActive then
                if IsPlayerAceAllowed(source, ConfigChasseAuTresor.AcePerm) then
                    TriggerClientEvent("esx_custom:StartEventChasse", -1)
                    EventStart = true
                end
            else
                if GetPermission(source) then
                    TriggerClientEvent("esx_custom:StartEventChasse", -1)
                    EventStart = true
                end
            end
            ESXCustom_Function_ServerSide:sendToDiscord('Coffre au trésor', (ConfigChasseAuTresor.Notification["NotifDiscord3"]):format(GetPlayerName(source)), ConfigSV.Logs["LogsChasseAuTresor"])
        else
            TriggerClientEvent(Config.Trigger.TriggerNotification, source, ConfigChasseAuTresor.Notification["DontSpam"])
        end
    end
end)

--KickPlayerCheat
RegisterNetEvent("esx_custom:PlayerKick", function(src, action)
    if action == 1 then
	    DropPlayer(src, ConfigChasseAuTresor.Notification["MaybeCheat"])
    elseif action == 2 then
        DropPlayer(src, ConfigChasseAuTresor.Notification["SpamEvent"])
    else
        DropPlayer(src, ConfigChasseAuTresor.Notification["MaybeCheat"])
    end
end)