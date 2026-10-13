ESX.RegisterServerCallback('ArmePermCoffre:ReceiveWeapon', function(source, cb, categorievehi)
    ListArme = {}
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT * FROM coffre_armeperm WHERE identifier = @identifier',{
        ['@identifier'] = xPlayer.identifier
      }, function(result)
        for k,v in pairs(result) do
            table.insert(ListArme, v)
        end

        cb({data1 = ListArme, data2 = xPlayer.loadout})
    end)
end)

RegisterNetEvent("ArmePermCoffre:depositarmesperm", function(data)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local arme, action, Ammo, Label, Name, anticheat = data.arme, data.action, data.Ammo, data.Label, data.Name, data.anticheat

    if anticheat == nil or anticheat ~= true then
        ESXCustomServerUtils.rejectSuspiciousAction(source, 'Désynchronisation avec le serveur ou detection de Cheat [Armes perm]')
        return
    end

    VerifyToken(source, function()
        if action == "deposit" then
            local count = 0
            MySQL.Async.fetchAll('SELECT * FROM coffre_armeperm WHERE identifier = @identifier', {
                ['@identifier'] = xPlayer.identifier
            }, function(resulte)
                if #resulte == 0 then
                    MySQL.Async.execute('INSERT INTO coffre_armeperm (identifier, armes, munitions, label, name) VALUES (@identifier, @armes, @munitions, @label, @name)', {
                        ['@identifier'] = xPlayer.identifier,
                        ['@armes'] = json.encode(arme),
                        ['@munitions'] = Ammo,
                        ['@label'] = Label,
                        ["@name"] = Name
                    })
            
                    xPlayer.removeWeapon(arme.name)
                    TriggerEvent('esx:customDiscordLog', 'Armes perms', 'Armes perms', nil, ConfigSV.Logs["LogsArmesPerm1"], 'ID : '..source..'\nUtilisateur : '..GetPlayerName(source)..'\nLicense : '..ESX.GetPlayerFromId(source).identifier..'\nAction : Déposer x1 '..arme.label..' dans le coffre arme perms')
                else
                    for k, v in pairs(resulte) do
                        if v.name ~= arme.name then
                            count = count + 1
                        end
                    end
    
                    if #resulte > count then
                        TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous avez ~r~déjà cette arme~s~ dans le coffre.")
                    else
                        MySQL.Async.execute('INSERT INTO coffre_armeperm (identifier, armes, munitions, label, name) VALUES (@identifier, @armes, @munitions, @label, @name)', {
                            ['@identifier'] = xPlayer.identifier,
                            ['@armes'] = json.encode(arme),
                            ['@munitions'] = Ammo,
                            ['@label'] = Label,
                            ["@name"] = Name
                        })
                
                        xPlayer.removeWeapon(arme.name)
                        TriggerEvent('esx:customDiscordLog', 'Armes perms', 'Armes perms', nil, ConfigSV.Logs["LogsArmesPerm1"], 'ID : '..source..'\nUtilisateur : '..GetPlayerName(source)..'\nLicense : '..ESX.GetPlayerFromId(source).identifier..'\nAction : Déposer x1 '..arme.label..' dans le coffre arme perms')
                    end
                end
            end)
        elseif action == "remove" then
            if xPlayer.hasWeapon(arme.name) then
                TriggerClientEvent(Config.Trigger.TriggerNotification, source, "Vous possédez ~r~déjà cette arme~s~ sur vous.")
            else
                MySQL.Async.fetchAll('SELECT * FROM coffre_armeperm WHERE identifier = @identifier', {
                    ['@identifier'] = xPlayer.identifier
                }, function(resulte)
                    for k, v in pairs(resulte) do
                        if v.name == arme.name then
                            xPlayer.addWeapon(v.name, tonumber(v.munitions))
    
                            if json.decode(v.armes)["components"] ~= nil then
                                for p, d in pairs(json.decode(v.armes)["components"]) do
                                    xPlayer.addWeaponComponent(v.name, d)
                                end
                            end
    
                            TriggerEvent('esx:customDiscordLog', 'Armes perms', 'Armes perms', nil, ConfigSV.Logs["LogsArmesPerm2"], 'ID : '..source..'\nUtilisateur : '..GetPlayerName(source)..'\nLicense : '..ESX.GetPlayerFromId(source).identifier..'\nAction : Retire x1 **'..arme.label..'** dans le coffre arme perms')
                            MySQL.Async.execute("DELETE FROM coffre_armeperm WHERE identifier = @identifier AND armes = @armes AND id = @id AND name = @name AND munitions = @munitions", {
                                ['@identifier'] = xPlayer.identifier,
                                ['@armes'] = v.armes,
                                ['@id'] = v.id,
                                ['@munitions'] = v.munitions,
                                ['@name'] = v.name,
                            })
                        end
                    end
                end)
            end
        end
    end)
end)

function CheckPermWeapon(armes)
    return Config.ArmesPerm[armes]
end

exports('CheckPermWeapon', CheckPermWeapon)