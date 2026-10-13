RegisterServerEvent('baseevents:onPlayerDied')
AddEventHandler("baseevents:onPlayerDied", function(info, info2)
    -- print(info, info2)
end)

RegisterServerEvent('baseevents:onPlayerKilled')
AddEventHandler("baseevents:onPlayerKilled", function(info, info2)
    -- print(info, info2.killedPlayer, info2.killertype, info2.weaponhash, info2.killerinveh, info2.killervehseat, info2.killervehname, info2.killerpos, GetPlayerName(info).." à tué "..GetPlayerName(info2.killedPlayer).." ("..NameOfWeapon[tostring(info2.weaponhash)]..")")
end)

RegisterServerEvent('baseevents:onPlayerWasted')
AddEventHandler("baseevents:onPlayerWasted", function(info)
    -- print(info)
end)