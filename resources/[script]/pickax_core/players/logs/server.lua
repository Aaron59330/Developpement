--Function
function getPlayerDiscord(source)
    for k, v in pairs(GetPlayerIdentifiers(source)) do
        if string.sub(v, 1, string.len("discord:")) == "discord:" then
            return v
        end
    end

    return nil
end

RegisterServerEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(source)
    TriggerEvent('esx:customDiscordLog', 'Nouvelle connexion', "Joueur : "..GetPlayerName(source).." ["..source.."]\n("..ESX.GetPlayerFromId(source).identifier..") s'est connecté.", 9936031, ConfigSV.Logs["LogsConnexion"], nil)
end)

AddEventHandler('esx:playerDropped', function(source, xPlayer, reason)
    TriggerEvent('esx:customDiscordLog', 'Nouvelle déconnexion', "Joueur : "..GetPlayerName(source).." ["..source.."]\n("..ESX.GetPlayerFromId(source).identifier..") s'est déconnecté. ("..reason..")", 9936031, ConfigSV.Logs["LogsDeconnexion"], nil)
end)

RegisterServerEvent('baseevents:onPlayerDied')
AddEventHandler("baseevents:onPlayerDied", function(info, info2)
    TriggerEvent('esx:customDiscordLog', 'Nouvelle mort', "💀 Morts", 9936031, ConfigSV.Logs["LogsMessageMort"], GetPlayerName(source).." `died`\n\nDétails du joueur : "..GetPlayerName(source).."\nID du joueur : "..source.."\nLicense : "..ESX.GetPlayerFromId(source).identifier)
end)

RegisterServerEvent('baseevents:onPlayerKilled')
AddEventHandler("baseevents:onPlayerKilled", function(info, info2)
    local CheckDiscord2 = getPlayerDiscord(info2.killedPlayer)
    local discord2
    if CheckDiscord2 == nil then
        discord2 = "**Aucun discord trouvé.**"
    else
        discord2 = "<@"..string.sub(CheckDiscord2, 9)..">"
    end
    if info == 0 then
        TriggerEvent('esx:customDiscordLog', 'Nouvelle mort', "💀 Morts", 9936031, ConfigSV.Logs["LogsMessageMort2"], "Nom : **"..GetPlayerName(info2.killedPlayer).."**\nID : **"..info2.killedPlayer.."**\nDiscord : "..discord2.."\nLicense : **"..ESX.GetPlayerFromId(info2.killedPlayer).identifier.."**")
        return 
    end
    
    local CheckDiscord = getPlayerDiscord(info)
    local discord
    if CheckDiscord == nil then
        discord = "**Aucun discord trouvé.**"
    else
        discord = "<@"..string.sub(CheckDiscord, 9)..">"
    end
    -- local discord = string.sub(GetPlayerIdentifiers(info)[5], 9)
    -- local discord2 = string.sub(GetPlayerIdentifiers(info2.killedPlayer)[5], 9)
    TriggerEvent('esx:customDiscordLog', 'Nouvelle mort', "💀 Morts", 9936031, ConfigSV.Logs["LogsMessageMort2"], "**"..GetPlayerName(info).."** à tué "..GetPlayerName(info2.killedPlayer).." (`"..ConfigLogs.NameOfWeapon[tostring(info2.weaponhash)].."`)\n\nDétails du joueur : **"..GetPlayerName(info).."**\nID du tueur : **"..info.."**\nDiscord : "..discord.."\nLicense : **"..ESX.GetPlayerFromId(info).identifier.."**\n\nNom du joueur tué : **"..GetPlayerName(info2.killedPlayer).."**\nID du joueur : **"..info2.killedPlayer.."**\nDiscord : "..discord2.."\nLicense : **"..ESX.GetPlayerFromId(info2.killedPlayer).identifier.."**")
end)